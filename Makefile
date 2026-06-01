# Makefile for Sovereign Evidence Workflow

.PHONY: verify review complete

# Gatekeeper: Forces invariant verification
verify:
	@chmod +x scripts/verify-state.sh
	./scripts/verify-state.sh --check-invariants

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