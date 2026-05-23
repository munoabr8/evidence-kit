# Debug Case

- debug_case_id: debug_case_001
- date: 2026-05-23
- issue_key: KAN-1
- project: Evidence Kit

Assumption:
If JIRA_API_TOKEN is exported before jira init, jira-cli can authenticate against Jira Cloud.

## Test
 
Run jira init and create/move KAN-1 from CLI.

- command: export JIRA_API_TOKEN='[redacted]' && jira init
- command: jira issue create
- command: jira issue move KAN-1 "In Progress"
- command: jira issue comment add KAN-1 "Created first debug case: cases/debug_case_001.md"
- cwd: /Users/abrahammunoz/evidenceKit/evidence-kit
- git_branch: main 
- git_commit:

## Expected

CLI authenticates, creates issue, and moves issue to In Progress.

## Actual

- result: Confirmed. Jira CLI authenticated, created KAN-1, linked the debug case, and moved the issue to In Review.
- exit_code: not captured

 

## Evidence

- artifact_paths: none
 
- case_record: cases/debug_case_001.md
 
- issue_key:KAN-1
 

## Resolution

Exporting JIRA_API_TOKEN before running jira init fixed the authentication flow.

## Lesson

- future_first_check: Before running jira init, verify that JIRA_API_TOKEN is set with `test -n "$JIRA_API_TOKEN" && echo "token is set"`.