# Makefile for Sovereign Evidence Workflow

.PHONY: verify review complete prep-manifest

# Ensure runtime artifact target is cleanly registered exactly once
prep-manifest:
	@grep -qxF "artifacts/test_session.cast" evidence-manifest.txt || echo "artifacts/test_session.cast" >> evidence-manifest.txt

# Step 1: Pre-flight Verification (Active workspace checks out)
verify: prep-manifest
	@echo "====== Generating Active Workspace Evidence ======"
	@mkdir -p artifacts
	asciinema rec --overwrite --command="./scripts/verify-state.sh --check-invariants" artifacts/test_session.cast

# Step 2: Push to Tracking Authority for Auditing
review: verify
	@echo "Local invariants look good. Progressing issue to Review phase..."
	jira issue move $(TICKET) "In Review"

# Step 3: Freeze, Mint Anchor, and Close Lifecycle Gap
complete:
	@echo "Executing Anchor Contract..."
	./scripts/anchor.sh $(TICKET)
	@echo "Minting Cryptographic Seal..."
	git tag -s "$(TICKET)-FINAL" -m "Final evidence seal for $(TICKET)"
	@echo "Transitioning tracking ref to Done."
	jira issue move $(TICKET) "Done"git tag -s "KAN-19-FINAL" -m "Final evidence seal for KAN-19"