Assumption:
If JIRA_API_TOKEN is exported before jira init, jira-cli can authenticate against Jira Cloud.

Test:
Run jira init and create/move KAN-1 from CLI.

Expected:
CLI authenticates, creates issue, and moves issue to In Progress.

Actual:
Confirmed.