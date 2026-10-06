import json
import os
import sys
from datetime import datetime, timezone
from urllib.parse import quote

import requests

from contexts import WorkflowContext

#bin/probes/external/jira_context.py

def read_workflow_context(ticket_id: str) -> WorkflowContext:
    base_url = os.environ["JIRA_BASE_URL"].rstrip("/")

    response = requests.get(
            f"{base_url}/rest/api/3/issue/{quote(ticket_id, safe='')}",
            params={"fields": "status"},
            auth=(
                os.environ["JIRA_EMAIL"],
                os.environ["JIRA_API_TOKEN"],
            ),
            headers={"Accept": "application/json"},
            timeout=15,
        )

    if not response.ok:
            raise RuntimeError(
                f"Jira request failed: "
                f"status={response.status_code}, "
                f"ticket={ticket_id}, "
                f"response={response.text}"
            )

    issue = response.json()

    return WorkflowContext(
        ticket_id=issue["key"],
        observed_state=issue["fields"]["status"]["name"],
        observed_at=datetime.now(timezone.utc),
    )


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: jira_context.py <ticket-id>")

    ticket_id = sys.argv[1]

    context = read_workflow_context(ticket_id)

    print(
        json.dumps(
            {
                "ticket_id": context.ticket_id,
                "observed_state": context.observed_state,
                "observed_at": context.observed_at.isoformat(),
            }
        )
    )


if __name__ == "__main__":
    main()