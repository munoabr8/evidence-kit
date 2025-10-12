TTYD_PORT ?= 8020
HTTP_PORT ?= 8009


BASIC_AUTH ?= wf:pass
SHELL := /bin/bash

ROOT := $(shell git rev-parse --show-toplevel)
ART ?= $(ROOT)/artifacts

.PHONY: setup live live-stop
setup:
	@command -v ttyd >/dev/null || (sudo apt-get update -y && sudo apt-get install -y ttyd)

live: setup
	@ttyd -p $(TTYD_PORT) -c $(BASIC_AUTH) bash >/tmp/ttyd.log 2>&1 & echo $$! > artifacts/ttyd.pid
	@echo "Forward port $(TTYD_PORT) → open in Chrome"

live-stop:
	@[ -f artifacts/ttyd.pid ] && kill $$(cat artifacts/ttyd.pid) && rm -f artifacts/ttyd.pid || echo "not running"


status: ## show ttyd status
	@[ -f $(ART)/ttyd.pid ] && ps -o pid,cmd -p $$(cat $(ART)/ttyd.pid) || echo "[live] not running"


serve:
	@pid=$$(lsof -t -i :$(HTTP_PORT)); \
	if [ -n "$$pid" ]; then \
		echo "[serve] killing existing process on port $(HTTP_PORT) (PID=$$pid)"; \
		kill -9 $$pid; \
	fi; \
	mkdir -p artifacts; \
	cd artifacts && python3 -m http.server $(HTTP_PORT)


capture: setup ## run workflow, redact, convert to HTML for Hunchly
	@mkdir -p $(ART)
	@echo "[capture] running workflow"
	@env -i PATH="/usr/bin:/bin:/usr/local/bin" bash -lc './bin/run-wf' 2>&1 | tee $(ART)/wf.raw.log
	@sed -E 's/(ghp_[A-Za-z0-9]{36})/[REDACTED]/g;s/(GITHUB_TOKEN=)[^ ]+/\1[REDACTED]/g' $(ART)/wf.raw.log > $(ART)/wf.log
	@if command -v ansi2html >/dev/null; then ansi2html < $(ART)/wf.log > $(ART)/wf.html; \
	else printf '<!doctype html><meta charset="utf-8"><title>wf</title><pre>' > $(ART)/wf.html; \
	     sed -e 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' $(ART)/wf.log >> $(ART)/wf.html; printf '</pre>' >> $(ART)/wf.html; fi
	@echo "http://localhost:$(HTTP_PORT)/wf.html" > $(ART)/capture_plan.txt
	@echo "[capture] open in Chrome: http(s) Codespaces → forwarded $(HTTP_PORT) → /wf.html"


artifacts-index:
	@python3 bin/gen-index.py


capture-and-index-and-serve:
	@$(MAKE) capture
	@python3 bin/gen-index.py
	@$(MAKE) serve



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
