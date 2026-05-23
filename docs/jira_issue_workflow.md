Goal:
Create docs/jira_issue_workflow.md as the reusable reference for managing Evidence Kit Jira issues from the CLI.

Why:
The Jira issue workflow is not yet proceduralized. I need a repeatable command sequence that makes issue creation, state transitions, debug-case linking, commits, and completion comments easy to execute with low friction.

Preconditions:
- Jira CLI has already been initialized with jira init.
- JIRA_API_TOKEN has already been exported.
- The default Jira project is configured as KAN.
- The Evidence Kit repo is available locally.

Jira site:
https://evidencekit.atlassian.net/

Workflow:
1. Verify Jira CLI access
   jira me
   jira issue list

2. Create issue
   jira issue create

3. View/list issue
   jira issue list
   jira issue view KAN-X

4. Move issue to In Progress
   jira issue move KAN-X "In Progress"
 
Optional:
   5. Add comment linking the case

      jira issue comment add KAN-X "Created debug case: cases/debug_case_<caseNumber>.md"


6. Move issue to In Review
   jira issue move KAN-X "In Review"

7. Commit implementation
   git add <files>
   git commit -m "<atomic commit message>"

Required:
8. Add completion comment with commit hash
   jira issue comment add KAN-X "Completed. Commit: $(git rev-parse --short HEAD)"
 
9. Move issue to Done
   jira issue move KAN-X "Done"
 
Acceptance criteria:
- docs/jira_issue_workflow.md exists.
- It includes Jira CLI preconditions.
- It includes the issue lifecycle commands.
- It uses KAN-X as a placeholder, not KAN-1.
- It explains that JIRA_API_TOKEN must be exported but does not include the real token.
- It includes the commit-hash comment step.
- It can be followed manually in under 10 minutes.