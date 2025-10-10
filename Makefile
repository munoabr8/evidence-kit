PORT ?= 8020
BASIC_AUTH ?= wf:pass
SHELL := /bin/bash
ART ?= artifacts

.PHONY: setup live live-stop
setup:
	@command -v ttyd >/dev/null || (sudo apt-get update -y && sudo apt-get install -y ttyd)

live: setup
	@ttyd -p $(PORT) -c $(BASIC_AUTH) bash >/tmp/ttyd.log 2>&1 & echo $$! > artifacts/ttyd.pid
	@echo "Forward port $(PORT) → open in Chrome"

live-stop:
	@[ -f artifacts/ttyd.pid ] && kill $$(cat artifacts/ttyd.pid) && rm -f artifacts/ttyd.pid || echo "not running"


status: ## show ttyd status
	@[ -f $(ART)/ttyd.pid ] && ps -o pid,cmd -p $$(cat $(ART)/ttyd.pid) || echo "[live] not running"


serve:
	@pid=$$(lsof -t -i :$(PORT)); \
	if [ -n "$$pid" ]; then \
		echo "[serve] killing existing process on port $(PORT) (PID=$$pid)"; \
		kill -9 $$pid; \
	fi; \
	mkdir -p artifacts; \
	cd artifacts && python3 -m http.server $(PORT)


capture: setup ## run workflow, redact, convert to HTML for Hunchly
	@mkdir -p $(ART)
	@echo "[capture] running workflow"
	@env -i PATH="/usr/bin:/bin:/usr/local/bin" bash -lc './bin/run-wf' 2>&1 | tee $(ART)/wf.raw.log
	@sed -E 's/(ghp_[A-Za-z0-9]{36})/[REDACTED]/g;s/(GITHUB_TOKEN=)[^ ]+/\1[REDACTED]/g' $(ART)/wf.raw.log > $(ART)/wf.log
	@if command -v ansi2html >/dev/null; then ansi2html < $(ART)/wf.log > $(ART)/wf.html; \
	else printf '<!doctype html><meta charset="utf-8"><title>wf</title><pre>' > $(ART)/wf.html; \
	     sed -e 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g' $(ART)/wf.log >> $(ART)/wf.html; printf '</pre>' >> $(ART)/wf.html; fi
	@echo "http://localhost:8009/wf.html" > $(ART)/capture_plan.txt
	@echo "[capture] open in Chrome: http(s) Codespaces → forwarded 8009 → /wf.html"
