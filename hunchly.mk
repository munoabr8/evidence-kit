TTYD_PORT ?= 8020
HTTP_PORT ?= 8009


BASIC_AUTH ?= wf:pass
SHELL := /bin/bash



 setup:
	@command -v ttyd >/dev/null || (sudo apt-get update -y && sudo apt-get install -y ttyd)
	@command -v asciinema >/dev/null || echo "asciinema not found; run 'make -f asciinema.mk asciinema-record' after installing asciinema to capture terminal sessions."


live: setup
	@ttyd -p $(TTYD_PORT) -c $(BASIC_AUTH) bash >/tmp/ttyd.log 2>&1 & echo $$! > artifacts/ttyd.pid
	@echo "Forward port $(TTYD_PORT) → open in Chrome"

live-stop:
	@[ -f artifacts/ttyd.pid ] && kill $$(cat artifacts/ttyd.pid) && rm -f artifacts/ttyd.pid || echo "not running"

MKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROBE := $(MKDIR)bin/probes/env_probe

.env.probe:
	@'$(PROBE)' --print-env > $@ || { rm -f $@; exit 1; }

# Don’t fail if missing; targets that need it will depend on it
-include .env.probe


capture: setup .env.probe
	ROOT=$(ROOT) ART_DIR=$(ART_DIR) '$(PROBE)' --ensure-artifacts
	ROOT=$(ROOT) ART_DIR=$(ART_DIR) ./bin/run_and_capture.sh

artifacts-index:
	@python3 bin/gen-index.py

 
all:
	@$(MAKE) -f hunchly.mk capture
	@$(MAKE) -f hunchly.mk artifacts-index
	@$(MAKE) -f hunchly.mk serve
 
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


serve:
	@pids="$$(lsof -t -i :$(HTTP_PORT) 2>/dev/null)"; \
	if [ -n "$$pids" ]; then \
	  echo "killing $$pids on :$(HTTP_PORT)"; \
	  kill $$pids || true; \
	else \
	  echo "no process on :$(HTTP_PORT)"; \
	fi; \
	mkdir -p artifacts; \
	cd artifacts && python3 -m http.server $(HTTP_PORT)

help:
	@echo "Usage: make [target]"
	@grep '^[a-zA-Z0-9_-]\+:' hunchly.mk || true

.PHONY: smoke-test


.ONESHELL:
SHELL := /usr/bin/bash
.SHELLFLAGS := -Eeuo pipefail -c

smoke-test:
	test -f bin/gen-index.py || { echo "missing bin/gen-index.py"; exit 90; }
	mkdir -p artifacts
	# Prepare artifacts (create a minimal cast, wrappers and glue)
	./bin/smoke_test.sh
	test -f artifacts/index.html || { echo "missing artifacts/index.html"; exit 91; }
	# If glue isn't present (CI fresh checkout), generate it from the template.
	if [ ! -f artifacts/asciinema-glue.js ]; then \
		echo "asciinema-glue.js not found — generating from templates/cast_glue.js.tpl"; \
		if [ -f artifacts/asciinema-player.min.js ]; then js=./asciinema-player.min.js; else js=https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.js; fi; \
		mkdir -p artifacts; \
		if [ -f templates/cast_glue.js.tpl ]; then \
			cp templates/cast_glue.js.tpl artifacts/asciinema-glue.js; \
			sed -i "s|%%JS%%|$$js|g" artifacts/asciinema-glue.js; \
			echo "wrote artifacts/asciinema-glue.js"; \
		else \
			echo "template templates/cast_glue.js.tpl not found"; exit 92; \
		fi; \
	fi; \
	test -f artifacts/asciinema-glue.js || { echo "missing glue.js"; exit 92; }
	test -f artifacts/asciinema-player.min.js || { echo "missing player.js"; exit 93; }
	[ $$(wc -c < artifacts/asciinema-player.min.js) -ge $${MIN_JS_BYTES:-10240} ] || { echo "player.js too small"; exit 94; }

	python3 -m http.server 8009 --directory artifacts >/tmp/http.8009.log 2>&1 & SRV_PID=$$!; sleep 0.2
	kill -0 $$SRV_PID || { echo "server pid died"; sed -n '1,120p' /tmp/http.8009.log; exit 95; }
	python3 - <<'PY' || { echo "port not listening"; exit 96; }
	import socket
	socket.create_connection(("127.0.0.1",8009),timeout=1.5).close()
	PY
	for i in $$(seq 1 50); do curl -fsS http://127.0.0.1:8009/ >/dev/null && break || sleep 0.2; done
	curl -fS http://127.0.0.1:8009/index.html >/dev/null || { echo "index 404"; exit 98; }
	hdr=$$(curl -sI http://127.0.0.1:8009/asciinema-player.min.js | tr -d '\r'); \
	 echo "$$hdr" | grep -iqE '^Content-Type:\s*(application|text)/javascript' || { echo "$$hdr"; exit 99; }
	kill $$SRV_PID || true
	wait $$SRV_PID 2>/dev/null || true

.PHONY: asciinema-record
asciinema-record:
	@mkdir -p artifacts
	@TARGET=$$TARGET; \
	if [ -z "$$TARGET" ]; then \
		echo "Usage: make -f hunchly.mk asciinema-record TARGET=<target>"; exit 1; \
	fi; \
	command -v asciinema >/dev/null || (echo "asciinema not found; install it first"; exit 1); \
	# record the full terminal session of the requested target
	ASCIICAST=artifacts/$$TARGET.cast; \
	(asciinema rec --overwrite -q -c "make -f hunchly.mk $$TARGET" "$$ASCIICAST") || { echo "asciinema rec failed"; exit 1; }; \
	# regenerate wrappers so the new cast gets a playable HTML
	python3 bin/gen-index.py; \
	echo "Wrote $$ASCIICAST and updated wrappers"

.PHONY: vendor-player
vendor-player:
	@echo "Invoking asciinema.mk:vendor-player";
	@$(MAKE) -f asciinema.mk vendor-player