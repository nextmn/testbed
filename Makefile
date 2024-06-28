# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

PROFILES = --profile debug
PROJECT_DIRECTORY = --project-directory build

.PHONY: default u d t j e t l lf test clean build
build: build/compose.yaml

clean:
	@rm -rf build

build/compose.yaml: templates/compose.yaml.j2 scripts/jinja/customize.py config.yaml
	@echo Building compose.yaml from jinja template
	@mkdir -p build
	@j2 --customize scripts/jinja/customize.py -o build/compose.yaml templates/compose.yaml.j2 config.yaml

test: build
	@echo Running yamllint
	@yamllint build config.yaml
	@docker compose $(PROJECT_DIRECTORY) config >/dev/null

j: build

pull: build/*
	@echo Pulling Docker images
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) pull

u: build/*
	@# set containers up
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) up -d

u-fg: build/*
	@# set containers up in foreground
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY)  up

ctrl:
	@# show control plane REST API in firefox
	@scripts/show-ctrl.py config.yaml
d:
	@# shutdown containers
	@#> don't depends on build-all because we need the old version to delete all
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) down -v

r:
	@# restart all containers
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) restart

e/%:
	@# enter container
	docker exec -it $(@F) bash
t/%:
	@# enter container in debug mode
	docker exec -it $(@F)-debug bash
l:
	@# show all logs
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs
l/%:
	@# show container's logs
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs $(@F)
lf:
	@# show all logs (continuous)
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs -f
lf/%:
	@# show container's logs (continuous)
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs $(@F) -f
ps:
	@# show container's status
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) ps
