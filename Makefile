# Makefile for Sovereign Evidence Workflow

.PHONY: verify review complete


# Helper to ensure the dynamic entry is cleanly added exactly once
prep-manifest:
	@grep -qxF "artifacts/test_session.cast" evidence-manifest.txt || echo "artifacts/test_session.cast" >> evidence-manifest.txt


# Gatekeeper: Forces active runtime capture and invariant verification
verify: prep-manifest
	@echo "====== Generating Active Workspace Evidence ======"
	@mkdir -p artifacts
	# Record actual bash syntax validation 
	asciinema rec --overwrite --command="bash -n scripts/*.sh" artifacts/test_session.cast
	
	@chmod +x scripts/verify-state.sh
	asciinema rec --overwrite --command="./scripts/verify-state.sh --check-invariants" artifacts/test_session2.cast



# Transition: Move to In-Review (Only if verification passes)
# Exxample make review TICKET=KAN-16

review: verify
	@echo "Invariant check passed. Moving to In-Review..."
	jira issue move $(TICKET) "In Review"

# Exxample make complete TICKET=KAN-16
# Transition: Move to Done (Anchors evidence)
complete:
	@chmod +x scripts/anchor.sh
	./scripts/anchor.sh $(TICKET)
	jira issue move $(TICKET) "Done"