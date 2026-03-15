session: Use of version control



Invariant:
	- Local sessions are not commited, only the remote sessions.
	- The local evidence kit directory is excluded from version control.
	  -> Only the git repo is what is under version control.
	     When the git repo is deleted, this does not change the contents 
	     of the local directory (evidenceKit and its contents)

State:
	- Fundamental make targets are failing.
		-> make -f hunchly.mk capture	

	- Fundamental probes are failing.

	- Single test for gen_index is failing.


Next Step:
	
	
	- Push changes, delete local repo, re-clone repo(from remote),setup, execute 
