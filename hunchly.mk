.ONESHELL:

TTYD_PORT ?= 8020
HTTP_PORT ?= 8009


BASIC_AUTH ?= wf:pass
SHELL := /bin/bash



.PHONY: setup live live-stop
setup:
	@command -v ttyd >/dev/null || (sudo apt-get update -y && sudo apt-get install -y ttyd)



live: setup
	@ttyd -p $(TTYD_PORT) -c $(BASIC_AUTH) bash >/tmp/ttyd.log 2>&1 & echo $$! > artifacts/ttyd.pid
	@echo "Forward port $(TTYD_PORT) → open in Chrome"

live-stop:
	@[ -f artifacts/ttyd.pid ] && kill $$(cat artifacts/ttyd.pid) && rm -f artifacts/ttyd.pid || echo "not running"

MKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROBE := $(MKDIR)bin/env_probe

.env.probe:
	@'$(PROBE)' --print-env > $@ || { rm -f $@; exit 1; }

# Don’t fail if missing; targets that need it will depend on it
-include .env.probe




all:
	@$(MAKE) capture
	@$(MAKE) artifacts-index
	@$(MAKE) serve

capture: setup .env.probe
	ROOT=$(ROOT) ART_DIR=$(ART_DIR) '$(PROBE)' --ensure-artifacts
	ROOT=$(ROOT) ART_DIR=$(ART_DIR) ./tools/evidence-kit/bin/run_and_capture.sh



artifacts-index:
	@python3 ./tools/evidence-kit/bin/gen-index.py



serve:
	@pids="$$(lsof -t -i :$(HTTP_PORT) 2>/dev/null || true)"; [ -n "$$pids" ] && kill $$pids || true
	@mkdir -p '$(ART_DIR)'
	@( cd '$(ART_DIR)' && python3 -m http.server '$(HTTP_PORT)' >/dev/null 2>&1 & echo $$! > .http.pid )
	@echo "serving http://localhost:$(HTTP_PORT) (cwd=$(ART_DIR), pid $$(cat $(ART_DIR)/.http.pid))"


stop-serve:
	@[ -f '$(ART_DIR)/.http.pid' ] && kill "$$(cat '$(ART_DIR)/.http.pid')" || true
 
check-probe:
	@$(PROBE) --version >/dev/null || { echo "bad env_probe_proto" >&2; exit 1; }

 
ports:
	@for p in 8009 8020; do \
		echo "Port $$p:"; \
		lsof -i :$$p || echo "  (none)"; \
		echo ""; \
	done

kill-ports:
	@for p in 8009 8020; do \
		pid=$$(lsof -t -i :$$p); \
		if [ -n "$$pid" ]; then \
			echo "[kill] Killing process on port $$p (PID=$$pid)"; \
			kill -9 $$pid; \
		else \
			echo "[kill] No process on port $$p"; \
		fi; \
	done


status: ## show ttyd status
	@[ -f $(ART_DIR)/ttyd.pid ] && ps -o pid,cmd -p $$(cat $(ART_DIR)/ttyd.pid) || echo "[live] not running"




