import os
from datetime import datetime, timezone
from urllib.parse import quote


import requests

from contexts import WorkflowContext


#bin/jira_context.py

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
    response.raise_for_status()
    issue = response.json()

    return WorkflowContext(
        ticket_id=issue["key"],
        observed_state=issue["fields"]["status"]["name"],
        observed_at=datetime.now(timezone.utc),
    )