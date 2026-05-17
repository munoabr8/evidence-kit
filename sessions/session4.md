session: Bug fix


invariants:
	- Artifacts directory is not flat.
	- The default workflow must not delete existing evidence artifacts.

State:
	- Captured output of all the probes
	- Captured output of make targets.
	- Fix:
		- Introduced classification: raw assets vs previewable artifacts
		- Raw assets (.js/.css/.json) link directly
		- Preview artifacts (.cast/.log/.txt) link to wrappers
		- Removed unconditional make_wrapper() call in index loop
	- Identified that the current version of artifacts directory is 
	  contributing to cogntive load.




next:
	- Generate new codespace project(of main branch). Regenerate artifacts in "artifacts" directory.
	- Update the readme for the project.
   	- Refactor files that writes to the artifacts directory.
   	- Define what assumptions I will be testing.
	- Define mean time to assumption disconfirmation.
