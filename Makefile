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


$(BCOMPOSE): templates/compose.yaml.j2 scripts/jinja/customize.py $(BCONFIG)
	@echo Building $(BCOMPOSE) from jinja template
	@mkdir -p $$(dirname $(BCOMPOSE))
	@j2 --customize scripts/jinja/customize.py -o $(BCOMPOSE) templates/compose.yaml.j2 $(BCONFIG)

$(BCONFIG): default-config.yaml
	@echo Copying default-config.yaml into $(BCONFIG)
	@mkdir -p $$(dirname $(BCONFIG))
	@cp default-config.yaml $(BCONFIG)

.PHONY: test
test:
	@$(MAKE) clean
	@echo [1/5] Running linter on python scripts
	@$(MAKE) test/lint/python
	@echo [2/5] Running tests for Free5GC config
	@$(MAKE) test/free5gc
	@echo [3/5] Running tests for NextMN/UPF config
	@$(MAKE) test/nextmn-upf
	@echo [4/5] Running tests for NextMN/SRv6 config
	@$(MAKE) test/nextmn-srv6
	@echo [5/5] Running tests for NextMN-Lite config
	@$(MAKE) test/nextmn-lite

.PHONY: test/lint/python
test/lint/python:
	@find -type f -iname '*.py' -print | parallel '(echo -n Running pylint on {} ; pylint --persistent=false -v -j 0 {})' :::

.PHONY: test/lint/yaml
test/lint/yaml:
	@echo "disable_openssl_generation: true" >> $(BCONFIG)
	@$(MAKE) build
	@echo Running yamllint
	@yamllint $(BUILD_DIR) default-config.yaml
	@echo Running docker compose config
	@docker compose $(PROJECT_DIRECTORY) config >/dev/null
	@$(MAKE) clean

.PHONY: test/nextmn-srv6
test/nextmn-srv6:
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) test/lint/yaml
.PHONY: test/nextmn-upf
test/nextmn-upf:
	@$(MAKE) set/dataplane/nextmn-upf
	@$(MAKE) test/lint/yaml
.PHONY: test/nextmn-free5gc
test/free5gc:
	@$(MAKE) set/dataplane/free5gc
	@$(MAKE) test/lint/yaml

.PHONY: test/nextmn-lite
test/nextmn-lite:
	@$(MAKE) set/dataplane/nextmn-srv6+free5gc+nextmn-upf
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) test/lint/yaml

.PHONY: set/dataplane
set/dataplane/%: $(BCONFIG)
	@echo Set dataplane to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --dataplane=$(@F)

.PHONY: set/controlplane
set/controlplane/%: $(BCONFIG)
	@echo Set controlplane to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --controlplane=$(@F)

.PHONY: set/nb-edges
set/nb-edges/%: $(BCONFIG)
	@echo Set number of edges to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --nb-edges=$(@F)

.PHONY: set/nb-ue
set/nb-ue/%: $(BCONFIG)
	@echo Set number of ue to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --nb-ue=$(@F)

.PHONY: set/log-level
set/log-level/%: $(BCONFIG)
	@echo Set log level to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --log-level=$(@F)

.PHONY: set/full-debug
set/full-debug/%: $(BCONFIG)
	@echo Set full-debug to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --full-debug=$(@F)

.PHONY: set/ran
set/ran/%: $(BCONFIG)
	@echo Set ran to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --ran=$(@F)

.PHONY: set/handover-ueransim
set/handover-ueransim: $(BCONFIG)
	@echo Set handover to true
	@./scripts/config_edit.py $(BCONFIG) --handover=true
	@$(MAKE) set/dataplane/free5gc
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/1
	@$(MAKE) set/log-level/debug
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/ran/dev

.PHONY: set/handover-nextmn
set/handover-nextmn: $(BCONFIG)
	@echo Set handover to true
	@./scripts/config_edit.py $(BCONFIG) --handover=true

.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

.PHONY: build
build:
	@$(MAKE) $(BCOMPOSE)

.PHONY: pull
pull: $(BCOMPOSE)
	@echo Pulling Docker images
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) pull

.PHONY: pull/all
pull/all:
	@echo Pull **all** Docker images
	@docker compose -f templates/images-list.yaml pull

.PHONY: u
u:
	@$(MAKE) up

.PHONY: d
d:
	@$(MAKE) down

.PHONY: r
r:
	@$(MAKE) restart

.PHONY: up
up: $(BCOMPOSE)
	@# set containers up
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) up -d

.PHONY: up-fg
up-fg: $(BCOMPOSE)
	@# set containers up in foreground
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY)  up

.PHONY: ctrl
ctrl: $(BCONFIG)
	@# show control plane REST API in firefox
	@scripts/show_ctrl.py $(BCONFIG)

.PHONY: down
down:
	@# shutdown containers
	@#> don't depends on build-all because we need the old version to delete all
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) down -v

.PHONY: restart
restart:
	@# restart all containers
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) restart

.PHONY: e
e/%:
	@# enter container
	docker exec -it $(@F) bash

.PHONY: ran
ran/%:
	@# exec nr-cli inside container
	docker exec -it $(@F) bash -c 'nr-cli $$(nr-cli --dump)'

.PHONY: db
db/%:
	@# enter database of a container
	docker exec -it $(@F)-db psql postgres -U postgres

.PHONY: t
t/%:
	@# enter container in debug mode
	docker exec -it $(@F)-debug bash

.PHONY: l
l:
	@# show all logs
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs
l/%:
	@# show container's logs
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs $(@F)

.PHONY: lf
lf:
	@# show all logs (continuous)
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs -f
lf/%:
	@# show container's logs (continuous)
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) logs $(@F) -f

.PHONY: ps
ps:
	@# show container's status
	docker compose $(PROFILES) $(PROJECT_DIRECTORY) ps

.PHONY: ping
ping/%:
	@# ping from a container
	@docker exec -it $(*D)-debug bash -c "ping $(@F)"

.PHONY: ue/ip
ue/ip/%:
	@# show ip of ue
	@docker exec -it ue$(@F)-debug bash -c "ip --brief address show uesimtun0|awk '{print \"ue$(@F):\", \$$3; exit}'"

.PHONY: ue/ping
ue/ping/%:
	@# ping between ues
	@# example:
	@#   make ue/ping/1/2
	@# pings from ue1 to ue2
	@TARGET=$(shell docker exec -it ue$(@F)-debug bash -c "ip --brief address show uesimtun0|awk '{print \$$3; exit}'|cut -d"/" -f 1");\
	docker exec -it ue$(*D)-debug bash -c "ping $$TARGET"

.PHONY: ue/switch-edge
ue/switch-edge/%:
	@# swich edge for ue
	@UE_IP=$(shell docker exec ue$(@F)-debug bash -c "ip --brief address show uesimtun0|awk '{print \$$3; exit}'|cut -d"/" -f 1");\
	scripts/switch.py $(BCONFIG) $$UE_IP
.PHONY: plot/policy-diff
plot/policy-diff:
	@echo "[1/2] [1/6] Configuring testbed with NextMN-SRv6"
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/nb-edges/2
	@$(MAKE) set/full-debug/false
	@$(MAKE) set/log-level/info
	@echo "[1/2] [2/6] Starting containers"
	@$(MAKE) up
	@echo "[1/2] [3/6] Adding latency on instance s0"
	@docker exec s0-debug bash -c "tc qdisc add dev edge-0 root netem delay 5ms"
	@sleep 2
	@docker exec ue1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec ue2-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@echo "[1/2] [4/6] Setting UE2 on edge 1"
	@$(MAKE) ue/switch-edge/2
	@echo "[1/2] [5/6] [$$(date --rfc-3339=seconds)] Starting ping from ue1 and ue2 (60s + 5s margin)"
	@bash -c 'docker exec ue1-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-policy-diff-areaA.txt"' &
	@bash -c 'docker exec ue2-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-policy-diff-areaB.txt"' &
	@sleep 65
	@echo "[1/2] [6/6] Stopping containers"
	@$(MAKE) down
	@echo "[2/2] Plotting data"
	@scripts/plots/policy_diff.py $(BUILD_DIR)/volumes/ue1/ping-policy-diff-areaA.txt $(BUILD_DIR)/volumes/ue2/ping-policy-diff-areaB.txt $(BUILD_DIR)/volumes/ue1/plot-policy-diff.pdf


.PHONY: plot/latency-switch
plot/latency-switch:
	@echo "[1/7] Configuring testbed with NextMN-SRv6 + Free5GC"
	@$(MAKE) set/dataplane/nextmn-srv6+free5gc
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/2
	@$(MAKE) set/full-debug/false
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latency on instance s0"
	@docker exec s0-debug bash -c "tc qdisc add dev edge-0 root netem delay 5ms"
	@sleep 2
	@docker exec ue1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec ue3-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 30s"
	@bash -c 'sleep 30 && $(MAKE) ue/switch-edge/1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Switching to edge 1"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 60s + 5s margin"
	@bash -c 'docker exec ue3-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-ulcl.txt"' &
	@bash -c 'docker exec ue1-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-sr4mec.txt"' &
	@sleep 65
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@scripts/plots/latency_switch.py $(BUILD_DIR)/volumes/ue1/ping-sr4mec.txt $(BUILD_DIR)/volumes/ue3/ping-ulcl.txt $(BUILD_DIR)/volumes/ue1/plot-latency-switch.pdf
