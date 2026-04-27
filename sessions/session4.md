session: Bug fix


invariants:
	- 


State:
	- Captured output of all the probes
	- Captured output of make targets.
	- Fix:
		- Introduced classification: raw assets vs previewable artifacts
		- Raw assets (.js/.css/.json) link directly
		- Preview artifacts (.cast/.log/.txt) link to wrappers
		- Removed unconditional make_wrapper() call in index loop


next:
	- Generate new codespace project(of main branch). Regenerate artifacts in "artifacts" directory.
	- Update the readme for the project.
    - 
