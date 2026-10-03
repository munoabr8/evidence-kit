TTYD_PORT ?= 8020
HTTP_PORT ?= 8009


BASIC_AUTH ?= wf:pass

.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS := -Eeuo pipefail -c

ART_DIR ?= artifacts
ASSET_DIR := $(ART_DIR)/assets
CAST_DIR  := $(ART_DIR)/casts
LOG_DIR   := $(ART_DIR)/logs
ASSET_SRC_DIR ?= media-pack/player





 setup:
	@command -v ttyd >/dev/null || { \
		if command -v apk >/dev/null 2>&1; then \
			sudo apk add --no-cache ttyd; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update -y && sudo apt-get install -y ttyd; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install ttyd; \
		else \
			echo "⚠️  ttyd not found. Install it for live terminal sharing:" >&2; \
			echo "  macOS:   brew install ttyd" >&2; \
			echo "  Alpine:  sudo apk add ttyd" >&2; \
			echo "  Debian:  sudo apt-get install ttyd" >&2; \
			echo "  Or skip 'make live' if not needed." >&2; \
		fi; \
	}
	@command -v asciinema >/dev/null || { \
		if command -v apk >/dev/null 2>&1; then \
			sudo apk add --no-cache asciinema; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update -y && sudo apt-get install -y asciinema; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install asciinema; \
		else \
			echo "⚠️  asciinema not found. Install it for terminal recording:" >&2; \
			echo "  macOS:   brew install asciinema" >&2; \
			echo "  Alpine:  sudo apk add asciinema" >&2; \
			echo "  Debian:  sudo apt-get install asciinema" >&2; \
			echo "  Visit:   https://asciinema.org/docs/installation" >&2; \
		fi; \
	}


live: setup
	@ttyd -p $(TTYD_PORT) -c $(BASIC_AUTH) bash >/tmp/ttyd.log 2>&1 & echo $$! > artifacts/ttyd.pid
	@echo "Forward port $(TTYD_PORT) → open in Chrome"

live-stop:
	@[ -f artifacts/ttyd.pid ] && kill $$(cat artifacts/ttyd.pid) && rm -f artifacts/ttyd.pid || echo "not running"

MKDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROBE := $(MKDIR)bin/probes/internal/env_probe

.env.probe:
	@'$(PROBE)' --print-env > $@ || { rm -f $@; exit 1; }

# Don’t fail if missing; targets that need it will depend on it
-include .env.probe


capture: setup .env.probe
	ROOT=$(ROOT) ART_DIR=$(ART_DIR) '$(PROBE)' --ensure-artifacts
	ROOT=$(ROOT) ART_DIR=$(ART_DIR) ./bin/run_and_capture.sh

artifacts-index:
	@python3 bin/gen-index.py

 
fresh-run:
	@$(MAKE) -f hunchly.mk clean-artifacts
	@$(MAKE) -f hunchly.mk capture
	@$(MAKE) -f hunchly.mk artifacts-index
	@$(MAKE) -f hunchly.mk smoke-playback
	@$(MAKE) -f hunchly.mk serve


.PHONY: all demo serve

all:
	@$(MAKE) -f hunchly.mk capture
	@$(MAKE) -f hunchly.mk artifacts-index
	@$(MAKE) -f hunchly.mk smoke-playback

demo: all
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
	@pids="$$(lsof -t -i :$(HTTP_PORT) 2>/dev/null || true)"; \
	if [ -z "$$pids" ]; then \
		echo "no process on :$(HTTP_PORT)"; \
	else \
		echo "killing $$pids on :$(HTTP_PORT)"; \
		printf '%s\n' $$pids | xargs kill || true; \
	fi; \
	mkdir -p artifacts; \
	cd artifacts; \
	exec python3 -m http.server $(HTTP_PORT)

clean-artifacts:
	@echo "WARNING: deleting artifacts/"
	rm -rf artifacts
	mkdir -p artifacts/assets

.PHONY: smoke-test

 
.PHONY: smoke-playback
smoke-playback:
	@test -x ./smoke-playback.sh || { echo "missing or not executable: ./smoke-playback.sh"; exit 80; }
	@./smoke-playback.sh

# to run: ALLOW_GENERATE_SHA=true make -f hunchly.mk smoke-test

smoke-test:
	test -f bin/gen-index.py || { echo "missing bin/gen-index.py"; exit 90; }

	mkdir -p artifacts
	./bin/smoke_test.sh
	test -f artifacts/index.html || { echo "missing artifacts/index.html"; exit 91; }

	# Current assumption under testing/investigation: 
		# In order for asciinema playback to work properly  in my current workflow, 
		# 3 files are needed: asciinema-glue.js, asciinema-player.min.js, asciinema-player.min.css.

		# Follow-up assumption under testing:
			# The location of those 3 files is artifacts/assets/
			#  

	# Should this glue regeneration be moved to its own script to reduce cognitive load?(NO IMPLIEMENTATION YET.)
	# Generate glue if absent
	########
	#
	#
	#
# 	if [ ! -f artifacts/asciinema-glue.js ]; then
# 	  echo "asciinema-glue.js not found — generating from template"
# 	  js=$([ -f artifacts/asciinema-player.min.js ] && echo ./asciinema-player.min.js || \
# 	       echo https://cdn.jsdelivr.net/npm/asciinema-player@3.11.1/dist/asciinema-player.min.js)
# 	  test -f templates/cast_glue.js.tpl || { echo "missing templates/cast_glue.js.tpl"; exit 92; }
# 	  sed "s|%%JS%%|$${js}|g" templates/cast_glue.js.tpl > artifacts/asciinema-glue.js
# 	  echo "wrote artifacts/asciinema-glue.js"
# 	fi
	#
	#
	#########

	test -f artifacts/assets/asciinema-glue.js || { echo "missing glue.js"; exit 45;}
.PHONY: vendor-player
vendor-player:
	@echo "[vendor-player] ART_DIR=$(ART_DIR)"
	@echo "[vendor-player] ASSET_DIR=$(ASSET_DIR)"
	@mkdir -p "$(ASSET_DIR)"
	@test -f "$(ASSET_SRC_DIR)/asciinema-player.min.js" || { echo "missing $(ASSET_SRC_DIR)/asciinema-player.min.js"; exit 1; }
	@test -f "$(ASSET_SRC_DIR)/asciinema-player.min.css" || { echo "missing $(ASSET_SRC_DIR)/asciinema-player.min.css"; exit 1; }
	@cp -f "$(ASSET_SRC_DIR)/asciinema-player.min.js" "$(ASSET_DIR)/"
	@cp -f "$(ASSET_SRC_DIR)/asciinema-player.min.css" "$(ASSET_DIR)/"
	@if [ -f "$(ASSET_SRC_DIR)/asciinema-glue.js" ]; then \
		cp -f "$(ASSET_SRC_DIR)/asciinema-glue.js" "$(ASSET_DIR)/"; \
	elif [ -f "templates/cast_glue.js.tpl" ]; then \
		sed "s|%%JS%%|./assets/asciinema-player.min.js|g" templates/cast_glue.js.tpl > "$(ASSET_DIR)/asciinema-glue.js"; \
	else \
		echo "missing glue source"; exit 1; \
	fi
	@test -f "$(ASSET_DIR)/asciinema-player.min.js" || { echo "missing asset js"; exit 2; }
	@test -f "$(ASSET_DIR)/asciinema-player.min.css" || { echo "missing asset css"; exit 3; }
	@test -f "$(ASSET_DIR)/asciinema-glue.js" || { echo "missing asset glue"; exit 4; }
	@echo "[vendor-player] wrote common assets into $(ASSET_DIR)"