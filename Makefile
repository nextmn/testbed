# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

BUILD_DIR = build
BCOMPOSE = $(BUILD_DIR)/compose.yaml
BCONFIG = $(BUILD_DIR)/config.yaml

PROFILES = --profile debug
PROJECT_DIRECTORY = --project-directory $(BUILD_DIR)
MAKE = make --no-print-directory


.PHONY: default u d t e t l lf clean build test set

$(BCONFIG): default-config.yaml
	@echo Copying default-config.yaml into $(BCONFIG)
	@mkdir -p $$(dirname $(BCONFIG))
	@cp default-config.yaml $(BCONFIG)

$(BCOMPOSE): templates/compose.yaml.j2 scripts/jinja/customize.py $(BCONFIG)
	@echo Building $(BCOMPOSE) from jinja template
	@mkdir -p $$(dirname $(BCOMPOSE))
	@j2 --customize scripts/jinja/customize.py -o $(BCOMPOSE) templates/compose.yaml.j2 $(BCONFIG)

test:
	@$(MAKE) clean
	@echo [1/4] Running linter on python scripts
	@$(MAKE) test/lint/python
	@echo [2/3] Running tests for Free5GC config
	@$(MAKE) test/free5gc
	@echo [3/4] Running tests for NextMN/UPF config
	@$(MAKE) test/nextmn-upf
	@echo [4/4] Running tests for NextMN/SRv6 config
	@$(MAKE) test/nextmn-srv6

test/lint/python:
	@find -type f -iname '*.py' -print | parallel '(echo -n Running pylint on {} ; pylint --persistent=false -v -j 0 {})' :::

test/lint/yaml:
	@echo "disable_openssl_generation: true" >> $(BCONFIG)
	@$(MAKE) build
	@echo Running yamllint
	@yamllint $(BUILD_DIR) default-config.yaml
	@echo Running docker compose config
	@docker compose $(PROJECT_DIRECTORY) config >/dev/null
	@$(MAKE) clean

test/nextmn-srv6:
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) test/lint/yaml
test/nextmn-upf:
	@$(MAKE) set/dataplane/nextmn-upf
	@$(MAKE) test/lint/yaml
test/free5gc:
	@$(MAKE) set/dataplane/free5gc
	@$(MAKE) test/lint/yaml

set/dataplane/%: $(BCONFIG)
	@echo Set dataplane to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --dataplane=$(@F)

set/nb-edges/%: $(BCONFIG)
	@echo Set number of edges to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --nb-edges=$(@F)

set/nb-ue/%: $(BCONFIG)
	@echo Set number of ue to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --nb-ue=$(@F)

clean:
	@rm -rf $(BUILD_DIR)
build:
	@$(MAKE) $(BCOMPOSE)

pull: $(BCOMPOSE)
	@echo Pulling Docker images
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) pull

u: $(BCOMPOSE)
	@# set containers up
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) up -d

u-fg: $(BCOMPOSE)
	@# set containers up in foreground
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY)  up

ctrl: $(BCONFIG)
	@# show control plane REST API in firefox
	@scripts/show_ctrl.py $(BCONFIG)
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
db/%:
	@# enter database of a container
	docker exec -it $(@F)-db psql postgres -U postgres
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
