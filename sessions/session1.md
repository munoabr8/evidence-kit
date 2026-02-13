session:  Narrowing 

invariants:
    - When codespace instance is closed, tmux uninstalled.
    - Dockerfile(default) contains commands that Dockerfile.alpine
      does not execute.
    - Codespace is running Alpine Linux
    - One dockerfile(Docker.alpine) is being used to deploy codespace.
state:
    - Docker/codespace  setup is successfully
    - Work has been comitted.

next:
    
    - 