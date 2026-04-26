Evidence kit
	Goals:


	Repo is to be used in conjunction with Hunchly. 
	Minimize the fricition between capturing evidence and contextualizing it.


	——


	Smoke test
	 The smoke test script checks key invariants. Verifies:
	 - that wrappers and player assets exist,
	 - that the vendored player file is large enough, 
	 - that the manifest is valid, 
	 - that wrapper HTML contains the expected <asciinema-player> element




	———

	Generates required files to use asciinema 

	Command:
	make -f asciinema.mk vendor-player --debug=b

	 That target creates the artifacts/ directory if needed, announces which version of the asciinema player it’s vendoring, and then calls bin/vendor-player.sh to download asciinema-player.min.js and asciinema-player.min.css into artifacts/, writing a vendor-player.json manifest as well.
	Vendoring is recommended for offline stability, but not a hard requirement.



	———

	Recording a single script

	You can record the output of a single script using the command:
	make -f asciinema.mk asciinema-record ASCIINEMA_CMD="bash ./myscript.sh" CAST_OUT=artifacts/myscript.cast


	where some_script.sh is a bash script name. The cast_out variable can be re-named to whatever you think would be most useful. 

	Does the path for the script need to be absolute? 
	Do I need to be in the directory where the script exists/saved?

	———

	Primary workflow

	make -f hunchly.mk all

	is used to generate the navigable index(artifact directory) where casts and logs are placed so that they can be captured with the Hunchly Chrome extension.

	The “all” target is made up by following targets:

	        @$(MAKE) -f hunchly.mk capture
	        @$(MAKE) -f hunchly.mk artifacts-index
	        @$(MAKE) -f hunchly.mk serve



	———

	Troubleshooting

	In the event that there is any issue with the evidence kit(when being used or when being integrated into another repo/project), what probe(s) or test(s) will yield the most information to help triangulate the error/issue?



	——