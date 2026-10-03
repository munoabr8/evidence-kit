# Makefile for Sovereign Evidence Workflow

.PHONY: verify-artifact verify review complete prep-manifest 

 .PHONY: verify-artifact

verify-artifact:
	@test -n "$(ARTIFACT)" || (echo "ARTIFACT is required"; exit 1)
	@test -n "$(TICKET)" || (echo "TICKET is required"; exit 1)
	@HASH=$$(./scripts/hash-artifact.sh "$(ARTIFACT)"); \
	echo "Computed Canonical Hash: $$HASH"; \
	./scripts/verify-contract.sh "$(ARTIFACT)" "$(TICKET)" "$$HASH"


# Ensure runtime artifact target is cleanly registered exactly once
prep-manifest:
	@grep -qxF "artifacts/main_refactor.tex" evidence-manifest.txt || echo "artifacts/main_refactor.tex" >> evidence-manifest.txt


verify-state: prep-manifest
	./scripts/verify-state.sh --check-invariants


# Step 1: Pre-flight Verification (Active workspace checks out)
verify:
	@echo "====== Generating Active Workspace Evidence ======"
	@mkdir -p artifacts
	asciinema rec --overwrite \
	  --command="$(MAKE) verify-state TICKET=$(TICKET)" \
	  artifacts/verification_state.cast



verify-contract:
	#./scripts/verify-contract.sh artifacts/$(TICKET)-analysis.tex $(TICKET)
	./scripts/verify-contract.sh artifacts/main_refactor.tex $(TICKET)

 
# Step 2: Push to Tracking Authority for Auditing
review: verify
	@echo "Local invariants look good. Progressing issue to Review phase..."
	jira issue move $(TICKET) "In Review"

# In complete target, add a call to a new script: ./scripts/verify-finality.sh
verify-finality:
    # This script should check: 
    # 1. Does a signed tag exist? 
    # 2. Is it pointing to the right commit?
    # 3. Does it match the manifest?


# Usage: make register-all
register-all:
	@for f in artifacts/*.cast artifacts/*.tex; do \
		grep -qxF "$$f" evidence-manifest.txt || echo "$$f" >> evidence-manifest.txt; \
	done
	@echo "All .cast and .tex files registered in evidence-manifest.txt"

.PHONY: refresh-analysis
 
require-ticket:
	@test -n "$(TICKET)" || (echo "[FAIL] TICKET is required. Usage: make refresh-analysis TICKET=KAN-20"; exit 1)

verify-manifest: require-ticket
	TICKET=$(TICKET) ./scripts/verify-state.sh --check-invariants
	
# useage: make refresh-analysis TICKET=KAN-20
refresh-analysis: require-ticket verify-manifest
	rm -f .manifest.lock; \
	jira issue move "$(TICKET)" "refresh-analysis"

.PHONY: transition-to-verification

#Structural Analysis to Formal Verification
PHASE_FORMAL_VERIFICATION := start constraining/increase precision

transition-to-verification:
	@test -n "$(TICKET)" || \
		(echo "TICKET is required. Usage: make transition-to-verification TICKET=KAN-20"; exit 1)

	@echo "--- Initiating Transition: Structured Analysis -> Formal Verification ---"

	@echo "--- Final sync of the manifest ---"
	$(MAKE) register-all

	@echo "--- Bulk verification of analysis carriers in manifest ---"
	@while IFS= read -r f; do \
		[ -z "$$f" ] && continue; \
		case "$$f" in \
			*.tex) \
				echo "Verifying analysis carrier: $$f"; \
				$(MAKE) verify-artifact \
					ARTIFACT="$$f" \
					TICKET="$(TICKET)" || exit 1 ;; \
		esac; \
	done < evidence-manifest.txt

	@echo "--- Anchor dry run ---"
	./scripts/anchor.sh --dry-run "$(TICKET)"

	@if [ "$(DRY_RUN)" = "1" ]; then \
		echo "--- DRY RUN: Jira transition skipped ---"; \
		echo "Would execute:"; \
		echo "jira issue move \"$(TICKET)\" \"$(PHASE_FORMAL_VERIFICATION)\""; \
	else \
		echo "--- Locking manifest ---"; \
		touch .manifest.lock; \
		echo "--- Transitioning to Formal Verification ---"; \
		if ! jira issue move "$(TICKET)" "$(PHASE_FORMAL_VERIFICATION)"; then \
			echo "!!! Transition failed. Rolling back..."; \
			rm -f .manifest.lock; \
			exit 1; \
		fi; \
	fi

.PHONY: verify-transition-state



OP_TABLE ?= ../../downloads/op_table_v8.tex

verify-transition-state: verify-manifest
	./scripts/check_structured_to_formal_transition.sh $(OP_TABLE)


# Step 3: Freeze, Mint Anchor, and Close Lifecycle Gap
complete:
	@echo "Executing Anchor Contract..."
	./scripts/anchor.sh $(TICKET)
	@echo "Minting Cryptographic Seal..."
	git tag -s "$(TICKET)-FINAL" -m "Final evidence seal for $(TICKET)"
	@echo "Transitioning tracking ref to Done."
	jira issue move $(TICKET) "Done"git tag -s "KAN-19-FINAL" -m "Final evidence seal for KAN-19"