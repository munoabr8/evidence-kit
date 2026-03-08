session: Use of version control



Invariant:
	- Evidence kit is partially working.
	- Local sessions are not commited, only the remote sessions.
	- the local evidence kit directory is excluded from version control.
	  only the git repo is what is under version control.


State:
	- Not all the make targets in hunchly.mk are working.
	


Next Step:
	
	
	- Push changes, delete local repo, re-clone repo(from remote),setup, execute 
		--> This would be only the git repo, not the evidenceKit directory.
