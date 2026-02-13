session: setup/issue identification

invariants:

	- Using a docker file.
	- Using a dev container.json file


state:
	- Project is in recovery mode when the codespace instance is instantiated.
	- Observability probes exists but not of specifically for docker setup observation.	
	- I know how to increase observability.


next:
	- Identify what preconditions must be met for a successful docker image          deployment for codespace.
	- Test to see if both the Dockerfile and Dockerfile.alpine are both required.
	- Commit work added.
	- Determine if codespace runs alpine or debian(unsure if this is correct)