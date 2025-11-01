# asciinema.mk - opt-in asciinema targets for evidence-kit
ASCIINEMA ?= asciinema
ASCIINEMA_CMD ?= ./bin/run_and_capture.sh
CAST_OUT ?= artifacts/run.cast
FILE ?= $(CAST_OUT)

.PHONY: asciinema-record asciinema-play asciinema-hash asciinema-upload asciinema-embed asciinema-record-with-env install
 
.PHONY: asciinema-fetch-player

# Prefer reading the canonical vendored version from media-pack/player/vendor-player.json
# If jq is available, use it; otherwise fall back to a safe grep. If the manifest is missing
# or parsing fails, fall back to the Makefile default (2.8.0).
ASCIINEMA_PLAYER_VERSION_FROM_MANIFEST := $(shell \
	MFILE=media-pack/player/vendor-player.json; \
	if [ -f "$$MFILE" ]; then \
		if command -v jq >/dev/null 2>&1; then \
			jq -r '.version // empty' "$$MFILE"; \
		else \
			grep -oP '"version"\s*:\s*"\K[^"]+' "$$MFILE" 2>/dev/null || true; \
		fi; \
	fi)

# Use the manifest-derived version when present, otherwise keep the historical default.
ASCIINEMA_PLAYER_VERSION ?= $(if $(ASCIINEMA_PLAYER_VERSION_FROM_MANIFEST),$(ASCIINEMA_PLAYER_VERSION_FROM_MANIFEST),2.8.0)

ASCIINEMA_PLAYER_JS ?= artifacts/asciinema-player.min.js
ASCIINEMA_PLAYER_CSS ?= artifacts/asciinema-player.min.css

# vendor-player: download asciinema-player assets into artifacts/ atomically
# Environment variables:
#  ASCIINEMA_PLAYER_VERSION (default above)
#  VENDOR_VERIFY=true  -> if set, and EXPECTED_JS_SHA / EXPECTED_CSS_SHA are provided, verify them
#  EXPECTED_JS_SHA / EXPECTED_CSS_SHA -> optional expected sha256 hex strings to verify
VENDOR_MANIFEST ?= artifacts/vendor-player.json

.PHONY: vendor-player
vendor-player:
	@mkdir -p artifacts
	@echo "[asciinema] vendor-player: v$(ASCIINEMA_PLAYER_VERSION) -> artifacts/"
	@chmod +x bin/vendor-player.sh 2>/dev/null || true
	@bin/vendor-player.sh $(ASCIINEMA_PLAYER_VERSION) $(ASCIINEMA_PLAYER_JS) $(ASCIINEMA_PLAYER_CSS) $(VENDOR_MANIFEST)

.PHONY: sync-player
sync-player:
	@# Copy canonical media-pack player assets (if present) into artifacts/ for serving
	@mkdir -p artifacts
	@ROOT=$$(cd $(dir $(abspath $(lastword $(MAKEFILE_LIST)))) && pwd) || ROOT="."; \
	MEDIA_JS="$$ROOT/media-pack/player/asciinema-player.min.js"; \
	MEDIA_CSS="$$ROOT/media-pack/player/asciinema-player.min.css"; \
	MEDIA_MAN="$$ROOT/media-pack/player/vendor-player.json"; \
	if [ -f "$$MEDIA_JS" ]; then cp -f "$$MEDIA_JS" artifacts/asciinema-player.min.js && echo "[asciinema] synced $$MEDIA_JS -> artifacts/"; else echo "[asciinema] no media-pack JS to sync"; fi; \
	if [ -f "$$MEDIA_CSS" ]; then cp -f "$$MEDIA_CSS" artifacts/asciinema-player.min.css && echo "[asciinema] synced $$MEDIA_CSS -> artifacts/"; else echo "[asciinema] no media-pack CSS to sync"; fi; \
	if [ -f "$$MEDIA_MAN" ]; then cp -f "$$MEDIA_MAN" artifacts/vendor-player.json && echo "[asciinema] synced $$MEDIA_MAN -> artifacts/vendor-player.json"; else echo "[asciinema] no media-pack vendor manifest to sync"; fi

.SILENT: asciinema-fetch-player
asciinema-fetch-player:
	@mkdir -p artifacts
	@echo "[asciinema] fetching asciinema-player v$(ASCIINEMA_PLAYER_VERSION) into artifacts/"
	@if [ -f "$(ASCIINEMA_PLAYER_JS)" ] && [ -f "$(ASCIINEMA_PLAYER_CSS)" ]; then \
		echo "[asciinema] player already present: $(ASCIINEMA_PLAYER_JS) $(ASCIINEMA_PLAYER_CSS)"; exit 0; \
	fi
	@chmod +x bin/fetch-asciinema-player.sh 2>/dev/null || true
	@bin/fetch-asciinema-player.sh $(ASCIINEMA_PLAYER_VERSION) $(ASCIINEMA_PLAYER_JS) $(ASCIINEMA_PLAYER_CSS)


install:
	@sudo apt-get update && sudo apt-get install -y asciinema

asciinema-record2:
	@command -v $(ASCIINEMA) >/dev/null || { echo "Install $(ASCIINEMA) to record (see README)"; exit 1; }
	@mkdir -p artifacts
	@echo "[asciinema] recording: $(ASCIINEMA_CMD) -> $(CAST_OUT)"
	@$(ASCIINEMA) rec -c "$(ASCIINEMA_CMD)" $(CAST_OUT)

asciinema-play:
	@command -v $(ASCIINEMA) >/dev/null || { echo "Install $(ASCIINEMA) to play (see README)"; exit 1; }
	@if [ -f "$(FILE)" ]; then \
		$(ASCIINEMA) play "$(FILE)"; \
	else \
		echo "no file: $(FILE)"; exit 1; \
	fi

asciinema-hash:
	@mkdir -p artifacts
	@if [ -f "$(FILE)" ]; then \
		sha256sum "$(FILE)" > "$(FILE)".sha256 && echo "[asciinema] wrote $(FILE).sha256"; \
	else \
		echo "no file: $(FILE)"; exit 1; \
	fi

# Opt-in upload - disabled unless ASCIINEMA_UPLOAD=true and ASCIINEMA_TOKEN set
asciinema-upload:
	@if [ "$(ASCIINEMA_UPLOAD)" != "true" ]; then \
		echo "Uploads are disabled by default. Set ASCIINEMA_UPLOAD=true and ASCIINEMA_TOKEN to enable (opt-in)."; exit 1; \
	fi
	@command -v $(ASCIINEMA) >/dev/null || { echo "Install $(ASCIINEMA) to upload"; exit 1; }
	@if [ -f "$(FILE)" ]; then \
		$(ASCIINEMA) upload "$(FILE)"; \
	else \
		echo "no file: $(FILE)"; exit 1; \
	fi

asciinema-embed:
	@mkdir -p artifacts
	@if [ -f "$(FILE)" ]; then \
		BASENAME=$$(basename "$(FILE)"); \
		HTML=artifacts/$$BASENAME.html; \
		printf '%s\n' "<!doctype html><html><head><meta charset=\"utf-8\"><title>Asciinema</title></head><body>" > "$$HTML"; \
		printf '%s\n' '<script src="https://asciinema.org/a/player.js"></script>' >> "$$HTML"; \
		printf '<asciinema-player src="./%s" preload></asciinema-player>\n' "$$BASENAME" >> "$$HTML"; \
		printf '%s\n' '</body></html>' >> "$$HTML"; \
		echo "[asciinema] wrote $$HTML"; \
	else \
		echo "no file: $(FILE)"; exit 1; \
	fi

.PHONY: asciinema-embed-selfcontained
asciinema-embed-selfcontained:
	@mkdir -p artifacts
	@if [ -f "$(FILE)" ]; then \
		BASENAME=$$(basename "$(FILE)"); \
		OUT=artifacts/$${BASENAME}.selfcontained.html; \
		command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }; \
		python3 bin/embed_cast.py "$(FILE)" "$$OUT"; \
		echo "[asciinema] wrote $$OUT"; \
	else \
		echo "no file: $(FILE)"; exit 1; \
	fi

.PHONY: scope-check
scope-check:
	@command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
	@python3 bin/scope_check.py

.PHONY: populate-artifacts
populate-artifacts: ## populate artifacts/ with required player files and wrappers
	@mkdir -p artifacts
	@echo "[asciinema] populate-artifacts: syncing local media-pack -> vendor download -> fetch fallback -> gen-index"
	@$(MAKE) -s -f asciinema.mk sync-player || true
	@$(MAKE) -s -f asciinema.mk vendor-player || true
	@$(MAKE) -s -f asciinema.mk asciinema-fetch-player || true
	@command -v python3 >/dev/null || true; \
	python3 bin/gen-index.py || true
	@echo "[asciinema] populate-artifacts: done"

.PHONY: check-artifacts
check-artifacts: ## run scope-check to verify large artifacts are present and checksummed
	@command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
	@python3 bin/scope_check.py

# Record with ROOT and ART_DIR set to absolute paths so scripts that require
# environment variables (like ./bin/run_and_capture.sh) don't fail when run
# from the asciinema target. This is safe and non-breaking; it simply provides
# a convenience wrapper that CI or users can call.
.PHONY: asciinema-record-with-env
asciinema-record-with-env:
	@command -v $(ASCIINEMA) >/dev/null || { echo "Install $(ASCIINEMA) to record (see README)"; exit 1; }
	@mkdir -p artifacts
	@ROOT="$(abspath .)" ART_DIR="$(abspath artifacts)"; \
	echo "[asciinema] recording with env: ROOT=$$ROOT ART_DIR=$$ART_DIR -> $(CAST_OUT)"; \
	ROOT="$$ROOT" ART_DIR="$$ART_DIR" $(ASCIINEMA) rec -c "$(ASCIINEMA_CMD)" $(CAST_OUT)

.PHONY: package-for-hunchly
package-for-hunchly:
	@mkdir -p artifacts
	@command -v python3 >/dev/null || { echo "python3 not found"; exit 1; }
	python3 bin/package_for_hunchly.py $(FILE)