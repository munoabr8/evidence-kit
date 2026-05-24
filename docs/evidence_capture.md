
Purpose
Decide when to use asciinema, screen recording, full-blown evidence capability capture ,or no recording.


Before recording, check:

- Use standalone asciinema for quick CLI replay.
- Use full Evidence Kit capture when provenance, structure, indexing, and later review matter.
- Use screen recording when GUI/browser/editor context matters.
- Use no recording when recording would increase debugging friction.

Rule of thumb:

Record only when replay value exceeds capture friction.




Acceptance criteria:

- Define when asciinema is useful.
	1.) When you want an increase confidence that you can execute a workflow/command.
	2.) Quick terminal recording.
- Define when full-blown evidence capability capture is useful.
	0.) Increase confidence of end-to-end workflow
	1.) When you want to preserve terminal recording with provenance, structure, and later review.

- Define when screen recording is useful.
	1.) When you want an increase  confidence that you can execute a workflow/command but also have GUI/or other
		interface interaction. 
- Define when no recording is preferred.
	1.) When it increases friction during debugging from an inside view(vs outside view). there will be exceptions
	    to this.
	2.) When simpler(or more technical) evidence is yet or can be collected. 




 

- Add optional recording guidance to docs/jira_issue_workflow.md or docs/debugging.md.

Assumption:
Evidence capture from simplest to most complex:
0.) None
1.) Screen capture recording
2.) asciinema stand-alone
3.) Evidence kit full capabilities.

- Test one small recording only if it adds value.
