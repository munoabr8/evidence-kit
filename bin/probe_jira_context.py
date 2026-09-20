import sys

from jira_context import read_workflow_context
from workflow_mapping import phase_from_jira


def main():
    ticket_id = sys.argv[1] if len(sys.argv) > 1 else "KAN-20"
    ctx = read_workflow_context(ticket_id)

    assert ctx.ticket_id == ticket_id, "Unexpected ticket"
    assert ctx.observed_state, "Missing Jira state"
    assert ctx.observed_at is not None, "Missing observation time"

    phase = phase_from_jira(ctx.observed_state)

    print(ctx)
    print("Workflow phase:", phase)
    print("Jira observation and mapping checks passed")


if __name__ == "__main__":
    main()