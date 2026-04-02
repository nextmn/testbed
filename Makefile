# Copyright Louis Royer and the NextMN contributors. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

BUILD_DIR = build
BCOMPOSE = $(BUILD_DIR)/compose.yaml
BCONFIG = $(BUILD_DIR)/config.yaml

PROFILES = --profile debug
PROJECT_DIRECTORY = --project-directory $(BUILD_DIR)
MAKE = make --no-print-directory

DATE := $(shell date --iso-8601=seconds)


$(BCOMPOSE): templates/compose.yaml.j2 templates/images-list.yaml scripts/jinja/customize.py $(BCONFIG)
	@if [ $(BCONFIG) -ot default-config.yaml ]; then \
		echo "Warning: default-config.yaml has been updated recently, consider updating $(BCONFIG)"; \
	fi
	@echo Building $(BCOMPOSE) from jinja template.
	@mkdir -p $$(dirname $(BCOMPOSE))
	@j2 --customize scripts/jinja/customize.py -o $(BCOMPOSE) templates/compose.yaml.j2 $(BCONFIG)

$(BCONFIG):
	@# Note: "default-config.yaml" is not a dependency of this target
	@# to avoid overriding local config.
	@# You may want to do a "make clean" when updating the template.
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
	@find -type f -iname '*.py' -print | parallel '(echo -n Running pylint on {} ; pylint --disable=fixme --persistent=false -v -j 0 {})' :::

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
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) test/lint/yaml
.PHONY: test/nextmn-upf
test/nextmn-upf:
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-upf
	@$(MAKE) test/lint/yaml
.PHONY: test/nextmn-free5gc
test/free5gc:
	@$(MAKE) set/controlplane/free5gc
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

.PHONY: set/nb-gnb
set/nb-gnb/%: $(BCONFIG)
	@echo Set number of gnb to $(@F)
	@./scripts/config_edit.py $(BCONFIG) --nb-gnb=$(@F)

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

.PHONY: set/handover-ueransim-f5gc
set/handover-ueransim-f5gc: $(BCONFIG)
	@echo Set handover to true
	@./scripts/config_edit.py $(BCONFIG) --handover=true
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/free5gc
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/1
	@$(MAKE) set/nb-gnb/2
	@$(MAKE) set/log-level/debug
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/ran/dev

.PHONY: set/handover-ueransim-nextmn
set/handover-ueransim-nextmn: $(BCONFIG)
	@echo Set handover to true
	@./scripts/config_edit.py $(BCONFIG) --handover=true
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-upf
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/1
	@$(MAKE) set/nb-gnb/2
	@$(MAKE) set/log-level/debug
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/ran/dev

.PHONY: set/handover-nextmn
set/handover-nextmn: $(BCONFIG)
	@echo Set handover to true
	@./scripts/config_edit.py $(BCONFIG) --handover=true
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/2
	@$(MAKE) set/nb-gnb/2
	@$(MAKE) set/controlplane/nextmn-lite

.PHONY: set/handover-nextmn-extra
set/handover-nextmn-extra: $(BCONFIG)
	@echo Set handover to true
	@./scripts/config_edit.py $(BCONFIG) --handover=true
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3
	@$(MAKE) set/controlplane/nextmn-lite

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

.PHONY: docker-build
docker-build:
	@echo Building Docker images
	@docker compose $(PROFILES) $(PROJECT_DIRECTORY) build

.PHONY: docker-build/all
docker-build/all:
	@echo Building **all** Docker images
	@docker compose -f templates/images-list.yaml build

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
	docker exec -it $(@F) sh

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
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/nb-edges/2
	@$(MAKE) set/nb-gnb/2
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
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-srv6+free5gc
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/2
	@$(MAKE) set/nb-gnb/2
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
	@bash -c 'sleep 30 && $(MAKE) ue/switch-edge/1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Switching UE1 from edge 0 to edge 1"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 60s + 5s margin"
	@bash -c 'docker exec ue3-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-ulcl.txt"' &
	@bash -c 'docker exec ue1-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-sr4mec.txt"' &
	@sleep 65
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@scripts/plots/latency_switch.py $(BUILD_DIR)/volumes/ue1/ping-sr4mec.txt $(BUILD_DIR)/volumes/ue3/ping-ulcl.txt $(BUILD_DIR)/volumes/ue1/plot-latency-switch.pdf


.PHONY: thesis/plot/binding
thesis/plot/binding:
	@echo "[1/2] [1/7] Configuring testbed with NextMN-SRv6"
	@./scripts/config_edit.py $(BCONFIG) --handover=false
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2 # TODO: configure different slices
	@$(MAKE) set/nb-edges/2 # XXX: this currently means central DN + 1 edge
	@$(MAKE) set/nb-gnb/1
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[1/2] [2/7] Starting containers"
	@$(MAKE) up
	@echo "[1/2] [3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# radio latency
	@docker exec ue1-debug       bash -c "tc qdisc add dev ran-0     root netem delay 23ms" # uplink UE1
	@docker exec ue2-debug       bash -c "tc qdisc add dev ran-0     root netem delay 23ms" # uplink UE2
	@docker exec gnb1-debug      bash -c "tc qdisc add dev ran-0     root netem delay  7ms" # downlink gNB1
	@echo "[1/2] [4/7] Checking if instance is reachable"
	@sleep 2
	@docker exec ue1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec ue2-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@echo "[1/2] [5/7] Setting UE2 on edge 1"
	@docker exec ue2-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is still reachable
	@$(MAKE) ue/switch-edge/2
	@echo "[1/2] [6/7] [$$(date --rfc-3339=seconds)] Starting ping from ue1 and ue2 (60s + 5s margin)"
	@bash -c 'docker exec ue1-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-binding-slice-s1.txt"' &
	@bash -c 'docker exec ue2-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-binding-slice-s2.txt"' &
	@sleep 65
	@echo "[1/2] [6/6] Stopping containers"
	@$(MAKE) down
	@echo "[2/2] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/binding/$(DATE)/
	@cp $(BUILD_DIR)/volumes/ue1/ping-binding-slice-s1.txt $(BUILD_DIR)/thesis-plots/binding/$(DATE)/slice-s1.txt
	@cp $(BUILD_DIR)/volumes/ue2/ping-binding-slice-s2.txt $(BUILD_DIR)/thesis-plots/binding/$(DATE)/slice-s2.txt
	@scripts/thesis/binding.py $(BUILD_DIR)/thesis-plots/binding/$(DATE)/slice-s1.txt $(BUILD_DIR)/thesis-plots/binding/$(DATE)/slice-s2.txt $(BUILD_DIR)/thesis-plots/binding/$(DATE)/01_10_evaluation-plot-binding.pdf

.PHONY: thesis/plot/rebinding
thesis/plot/rebinding:
	@echo "[1/7] Configuring testbed with NextMN-SRv6 + NextMN-UPF"
	@./scripts/config_edit.py $(BCONFIG) --handover=false
	@$(MAKE) set/controlplane/free5gc
	@$(MAKE) set/dataplane/nextmn-srv6+nextmn-upf
	@$(MAKE) set/nb-ue/1 # 1 UE in each DN
	@$(MAKE) set/nb-edges/2 # central DN + 1 edge
	@$(MAKE) set/nb-gnb/1
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec upfa1-nmn       bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# radio latency
	@docker exec ue1-debug       bash -c "tc qdisc add dev ran-0     root netem delay 23ms" # uplink UE1
	@docker exec ue5-debug       bash -c "tc qdisc add dev ran-0     root netem delay 23ms" # uplink UE5
	@docker exec gnb1-debug      bash -c "tc qdisc add dev ran-0     root netem delay  7ms" # downlink gNB1
	@sleep 2
	@docker exec ue1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec ue5-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 30s"
	@bash -c 'sleep 30 && $(MAKE) ue/switch-edge/1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Switching UE1 from edge 0 to edge 1"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 60s + 5s margin"
	@bash -c 'docker exec ue5-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-rebinding-ulcl.txt"' &
	@bash -c 'docker exec ue1-debug bash -c "ping -D -w 60 10.4.0.1 -i 0.1 > /volume/ping-rebinding-sr4mec.txt"' &
	@sleep 65
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/rebinding/$(DATE)/
	@cp $(BUILD_DIR)/volumes/ue5/ping-rebinding-ulcl.txt $(BUILD_DIR)/thesis-plots/rebinding/$(DATE)/ulcl.txt
	@cp $(BUILD_DIR)/volumes/ue1/ping-rebinding-sr4mec.txt $(BUILD_DIR)/thesis-plots/rebinding/$(DATE)/sr4mec.txt
	@scripts/thesis/rebinding.py $(BUILD_DIR)/thesis-plots/rebinding/$(DATE)/sr4mec.txt $(BUILD_DIR)/thesis-plots/rebinding/$(DATE)/ulcl.txt $(BUILD_DIR)/thesis-plots/rebinding/$(DATE)/02_10_evaluation-plot-rebinding.pdf

.PHONY: thesis/plot/mobility/ulcl
thesis/plot/mobility/ulcl:
	@echo "[1/7] Configuring testbed with NextMN-UPF"
	@./scripts/config_edit.py $(BCONFIG) --handover=true
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-upf
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/2
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# CP latency
	@docker exec cp-lite-debug    bash -c "tc qdisc add dev control-0 root netem delay  9ms" # uplink
	@docker exec upfi1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfi2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug  bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# upfi1-nmn (edge 1) - upfi2-nmn (edge 2)
	@docker exec upfi1-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfi1-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.135/32 via 10.1.4.146" # from upfi2-nmn to upfi1-nmn via inter-areas
	@# upfi2-nmn (edge 2) - upfa2-nmn (edge 1)
	@docker exec upfa2-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfa2-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.137/32 via 10.1.4.146" # from upfi2-nmn to upfa2-nmn via inter-areas
	@####
	@docker exec uel5-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec upfi1-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.135 > /dev/null"
	@docker exec upfa2-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.137 > /dev/null"
	@docker exec uel5-debug bash -c "ping -c 1 fd00:0:0:0:1:8000:0:c > /dev/null" # to gNBl3
	@docker exec gnbl3-debug bash -c "ping -c 1 10.1.4.144 > /dev/null" # to upfi2
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel5 nmn-upf-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel5-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-ulcl.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel5/ping-mobility-ulcl.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/ulcl.txt
	@scripts/thesis/mobility.py $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/ulcl.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/03_10_evaluation-plot-mobility-ulcl.pdf

.PHONY: thesis/plot/mobility/posteriori/central
thesis/plot/mobility/posteriori/central:
	@echo "[1/7] Configuring testbed with NextMN-SRv6"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=true
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# CP latency
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel1 sr4mec-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel1-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-posteriori-central.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel1/ping-mobility-posteriori-central.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/posteriori-central.txt
	@scripts/thesis/mobility.py $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/posteriori-central.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/03_20_evaluation-plot-mobility-changement-a-posteriori-central.pdf

.PHONY: thesis/plot/mobility/posteriori/edge
thesis/plot/mobility/posteriori/edge:
	@echo "[1/7] Configuring testbed with NextMN-SRv6"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=true
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# CP latency
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel2-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel2 sr4mec-1 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel2-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-posteriori-edge.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel2/ping-mobility-posteriori-edge.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/posteriori-edge.txt
	@scripts/thesis/mobility.py $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/posteriori-edge.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/03_21_evaluation-plot-mobility-changement-a-posteriori-edge.pdf

.PHONY: thesis/plot/mobility/immediate/central
thesis/plot/mobility/immediate/central:
	@echo "[1/7] Configuring testbed with NextMN-SRv6"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=false
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# CP latency
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel1 sr4mec-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel1-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-immediat-central.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel1/ping-mobility-immediat-central.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/immediat-central.txt
	@scripts/thesis/mobility.py $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/immediat-central.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/03_30_evaluation-plot-mobility-changement-immediat-central.pdf

.PHONY: thesis/plot/mobility/immediate/edge
thesis/plot/mobility/immediate/edge:
	@echo "[1/7] Configuring testbed with NextMN-SRv6"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=false
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6
	@$(MAKE) set/nb-ue/2
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# CP latency
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel2-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel2 sr4mec-1 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel2-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-immediat-edge.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel2/ping-mobility-immediat-edge.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/immediat-edge.txt
	@scripts/thesis/mobility.py $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/immediat-edge.txt $(BUILD_DIR)/thesis-plots/mobility/$(DATE)/03_31_evaluation-plot-mobility-changement-immediat-edge.pdf

.PHONY: thesis/plot/mobility
thesis/plot/mobility:
	$(MAKE) thesis/plot/mobility/posteriori/central
	$(MAKE) thesis/plot/mobility/posteriori/edge
	$(MAKE) thesis/plot/mobility/immediate/central
	$(MAKE) thesis/plot/mobility/immediate/edge

.PHONY: plot/mobility/posteriori/central
plot/mobility/posteriori/central:
	@echo "[1/7] Configuring testbed with NextMN-SRv6 + NextMN-UPF"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=true --initial-ue-dn=central
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6+nextmn-upf
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec upfa1-nmn-debug bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink ULCL
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink SR4MEC
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink SR4MEC/ULCL
	@# CP latency SR4MEC
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# CP latency ULCL
	@docker exec cp-lite-debug    bash -c "tc qdisc add dev control-0 root netem delay  9ms" # uplink
	@docker exec upfi1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfi2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# upfi1-nmn (edge 1) - upfi2-nmn (edge 2) ULCL
	@docker exec upfi1-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfi1-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.135/32 via 10.1.4.146" # from upfi2-nmn to upfi1-nmn via inter-areas
	@# upfi2-nmn (edge 2) - upfa2-nmn (edge 1) ULCL
	@docker exec upfa2-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfa2-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.137/32 via 10.1.4.146" # from upfi2-nmn to upfa2-nmn via inter-areas
	@# srgw0 (edge 1) - srgw1 (edge 2) SR4MEC
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2) SR4MEC
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable (SR4MEC)
	@docker exec uel5-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable (ULCL)
	@docker exec upfi1-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.135 > /dev/null"
	@docker exec upfa2-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.137 > /dev/null"
	@docker exec uel5-debug bash -c "ping -c 1 fd00:0:0:0:1:8000:0:c > /dev/null" # to gNBl3
	@docker exec gnbl3-debug bash -c "ping -c 1 10.1.4.144 > /dev/null" # to upfi2
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel1 sr4mec-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (SR4MEC)"' &
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel5 nmn-upf-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (ULCL)"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel1-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-posteriori-central.txt"' &
	@bash -c 'docker exec uel5-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-ulcl.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel1/ping-mobility-posteriori-central.txt $(BUILD_DIR)/plots/mobility/$(DATE)/posteriori-central.txt
	@cp $(BUILD_DIR)/volumes/uel5/ping-mobility-ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt
	@scripts/plots/mobility.py $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/posteriori-central.txt $(BUILD_DIR)/plots/mobility/$(DATE)/evaluation-plot-mobility-changement-a-posteriori-central.pdf

.PHONY: plot/mobility/posteriori/edge
plot/mobility/posteriori/edge:
	@echo "[1/7] Configuring testbed with NextMN-SRv6 + NextMN-UPF"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=true --initial-ue-dn=edge
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6+nextmn-upf
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# CP latency SR4MEC
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies SR4MEC + ULCL
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# CP latency ULCL
	@docker exec cp-lite-debug    bash -c "tc qdisc add dev control-0 root netem delay  9ms" # uplink
	@docker exec upfi1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfi2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@# upfi1-nmn (edge 1) - upfi2-nmn (edge 2) ULCL
	@docker exec upfi1-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfi1-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.135/32 via 10.1.4.146" # from upfi2-nmn to upfi1-nmn via inter-areas
	@# upfi2-nmn (edge 2) - upfa2-nmn (edge 1) ULCL
	@docker exec upfa2-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfa2-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.137/32 via 10.1.4.146" # from upfi2-nmn to upfa2-nmn via inter-areas
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec uel5-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable (ULCL)
	@docker exec upfi1-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.135 > /dev/null"
	@docker exec upfa2-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.137 > /dev/null"
	@docker exec uel5-debug bash -c "ping -c 1 fd00:0:0:0:1:8000:0:c > /dev/null" # to gNBl3
	@docker exec gnbl3-debug bash -c "ping -c 1 10.1.4.144 > /dev/null" # to upfi2
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel1 sr4mec-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (SR4MEC)"' &
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel5 nmn-upf-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (ULCL)"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel1-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-posteriori-edge.txt"' &
	@bash -c 'docker exec uel5-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-ulcl.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel1/ping-mobility-posteriori-edge.txt $(BUILD_DIR)/plots/mobility/$(DATE)/posteriori-edge.txt
	@cp $(BUILD_DIR)/volumes/uel5/ping-mobility-ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt
	@scripts/plots/mobility.py --rebinding $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/posteriori-edge.txt $(BUILD_DIR)/plots/mobility/$(DATE)/evaluation-plot-mobility-changement-a-posteriori-edge.pdf

.PHONY: plot/mobility/immediate/central
plot/mobility/immediate/central:
	@echo "[1/7] Configuring testbed with NextMN-SRv6 + NextMN-UPF"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=false --initial-ue-dn=central
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6+nextmn-upf
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec upfa1-nmn-debug bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink ULCL
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink SR4MEC
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink SR4MEC/ULCL
	@# CP latency SR4MEC
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# CP latency ULCL
	@docker exec cp-lite-debug    bash -c "tc qdisc add dev control-0 root netem delay  9ms" # uplink
	@docker exec upfi1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfi2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# upfi1-nmn (edge 1) - upfi2-nmn (edge 2) ULCL
	@docker exec upfi1-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfi1-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.135/32 via 10.1.4.146" # from upfi2-nmn to upfi1-nmn via inter-areas
	@# upfi2-nmn (edge 2) - upfa2-nmn (edge 1) ULCL
	@docker exec upfa2-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfa2-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.137/32 via 10.1.4.146" # from upfi2-nmn to upfa2-nmn via inter-areas
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec uel5-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable (ULCL)
	@docker exec upfi1-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.135 > /dev/null"
	@docker exec upfa2-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.137 > /dev/null"
	@docker exec uel5-debug bash -c "ping -c 1 fd00:0:0:0:1:8000:0:c > /dev/null" # to gNBl3
	@docker exec gnbl3-debug bash -c "ping -c 1 10.1.4.144 > /dev/null" # to upfi2
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel1 sr4mec-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (SR4MEC)"' &
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel5 nmn-upf-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (ULCL)"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel1-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-immediat-central.txt"' &
	@bash -c 'docker exec uel5-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-ulcl.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel1/ping-mobility-immediat-central.txt $(BUILD_DIR)/plots/mobility/$(DATE)/immediat-central.txt
	@cp $(BUILD_DIR)/volumes/uel5/ping-mobility-ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt
	@scripts/plots/mobility.py $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/immediat-central.txt $(BUILD_DIR)/plots/mobility/$(DATE)/evaluation-plot-mobility-immediat-central.pdf

.PHONY: plot/mobility/immediate/edge
plot/mobility/immediate/edge:
	@echo "[1/7] Configuring testbed with NextMN-SRv6 + NextMN-UPF"
	@./scripts/config_edit.py $(BCONFIG) --handover=true --post-handover-rebinding=false --initial-ue-dn=edge
	@$(MAKE) set/controlplane/nextmn-lite
	@$(MAKE) set/dataplane/nextmn-srv6+nextmn-upf
	@$(MAKE) set/nb-ue/1
	@$(MAKE) set/nb-edges/3
	@$(MAKE) set/nb-gnb/3 # gnbl3 is in a different area
	@$(MAKE) set/full-debug/true
	@$(MAKE) set/log-level/info
	@echo "[2/7] Starting containers"
	@$(MAKE) up
	@echo "[3/7] Adding latencies"
	@# central DN latency
	@docker exec r0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # uplink
	@docker exec s0-debug        bash -c "tc qdisc add dev edge-0    root netem delay  9ms" # downlink
	@# CP latency SR4MEC
	@docker exec srv6-ctrl-debug bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # uplink
	@docker exec srgw0-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec srgw1-debug     bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r0-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r1-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@docker exec r2-debug        bash -c "tc qdisc add dev rest-0 root netem delay  9ms" # downlink
	@# Inter-areas latencies SR4MEC + ULCL
	@docker exec inter-areas-debug bash -c "tc qdisc add dev dataplane-0 root netem delay  2ms"
	@# CP latency ULCL
	@docker exec cp-lite-debug    bash -c "tc qdisc add dev control-0 root netem delay  9ms" # uplink
	@docker exec upfi1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfi2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa1-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@docker exec upfa2-nmn-debug  bash -c "tc qdisc add dev control-0 root netem delay  9ms" # downlink
	@# upfi1-nmn (edge 1) - upfi2-nmn (edge 2) ULCL
	@docker exec upfi1-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfi1-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.135/32 via 10.1.4.146" # from upfi2-nmn to upfi1-nmn via inter-areas
	@# upfi2-nmn (edge 2) - upfa2-nmn (edge 1) ULCL
	@docker exec upfa2-nmn-debug    bash -c "ip route replace 10.1.4.144/32 via 10.1.4.146" # from upfa2-nmn to upfi2-nmn via inter-areas
	@docker exec upfi2-nmn-debug    bash -c "ip route replace 10.1.4.137/32 via 10.1.4.146" # from upfi2-nmn to upfa2-nmn via inter-areas
	@# srgw0 (edge 1) - srgw1 (edge 2)
	@docker exec srgw0-debug    bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from srgw0 to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:1::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to srgw0 via inter-areas
	@# r1 (edge 1) - srgw1 (edge 2)
	@docker exec r1-debug       bash -c "ip route replace fc00:4::/32 via fd00:0:0:0:3:8000:0:7" # from r1    to srgw1 via inter-areas
	@docker exec srgw1-debug    bash -c "ip route replace fc00:3::/32 via fd00:0:0:0:3:8000:0:7" # from srgw1 to r1    via inter-areas
	@####
	@docker exec uel1-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable
	@docker exec uel5-debug bash -c "ping -c 1 10.4.0.1 > /dev/null" # check instance is reachable (ULCL)
	@docker exec upfi1-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.135 > /dev/null"
	@docker exec upfa2-nmn-debug bash -c "ping -c 1 10.1.4.144 > /dev/null"
	@docker exec upfi2-nmn-debug bash -c "ping -c 1 10.1.4.137 > /dev/null"
	@docker exec uel5-debug bash -c "ping -c 1 fd00:0:0:0:1:8000:0:c > /dev/null" # to gNBl3
	@docker exec gnbl3-debug bash -c "ping -c 1 10.1.4.144 > /dev/null" # to upfi2
	@sleep 2
	@####
	@echo "[4/7] [$$(date --rfc-3339=seconds)] Scheduling instance switch in 10s"
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel1 sr4mec-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (SR4MEC)"' &
	@bash -c 'sleep 10 && scripts/handover.py $(BCONFIG) uel5 nmn-upf-0 gnbl3 gnbl1 && echo "[5.5/7] [$$(date --rfc-3339=seconds)] Mobility from Area 1 to Area 2 (ULCL)"' &
	@echo "[5/7] [$$(date --rfc-3339=seconds)] Start ping for 20s + 5s margin"
	@# Note: we cannot do less than 0.1 interval, otherwise our UPF is too slow to process
	@bash -c 'docker exec uel1-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-immediat-edge.txt"' &
	@bash -c 'docker exec uel5-debug bash -c "ping -D -w 20 10.4.0.1 -i 0.1 > /volume/ping-mobility-ulcl.txt"' &
	@sleep 25
	@echo "[6/7] Stopping containers"
	@$(MAKE) down
	@echo "[7/7] Plotting data"
	@mkdir -p $(BUILD_DIR)/plots/mobility/$(DATE)/
	@cp $(BUILD_DIR)/volumes/uel1/ping-mobility-immediat-edge.txt $(BUILD_DIR)/plots/mobility/$(DATE)/immediat-edge.txt
	@cp $(BUILD_DIR)/volumes/uel5/ping-mobility-ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt
	@scripts/plots/mobility.py --rebinding $(BUILD_DIR)/plots/mobility/$(DATE)/ulcl.txt $(BUILD_DIR)/plots/mobility/$(DATE)/immediat-edge.txt $(BUILD_DIR)/plots/mobility/$(DATE)/evaluation-plot-mobility-immediat-edge.pdf

.PHONY: plot/mobility
plot/mobility:
	$(MAKE) plot/mobility/posteriori/central
	$(MAKE) plot/mobility/posteriori/edge
	$(MAKE) plot/mobility/immediate/central
	$(MAKE) plot/mobility/immediate/edge
