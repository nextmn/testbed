# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

PROFILES = --profile debug

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

full-test: test
	@docker compose --project-directory build config

j: build

pull: build/*
	@echo Pulling Docker images
	@docker compose $(PROFILES) --project-directory build pull

u: build/*
	@docker compose $(PROFILES) --project-directory build up -d
d:
	@# don't depends on build-all because we need the old version to delete all
	@docker compose $(PROFILES) --project-directory build down

e/%:
	@# enter container
	docker exec -it $(@F) bash
t/%:
	@# enter container in debug mode
	docker exec -it $(@F)-debug bash
l/%:
	@# show container's logs
	docker logs $(@F)
lf/%:
	@# show container's logs (continuous)
	docker logs $(@F) -f
