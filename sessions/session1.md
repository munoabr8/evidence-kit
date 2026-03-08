session:  Narrowing (Remote)

invariants:
    - When codespace instance is closed, tmux uninstalled.
    - when a bash process is terminated(and tmux is running on it)
      then the tmux sessions will be lost.

    - Dockerfile(default) contains commands that Dockerfile.alpine
      does not execute.
    - Codespace is running Alpine Linux
    - One dockerfile(Docker.alpine) is being used to deploy codespace.
 

state:
    - Docker/codespace  setup is successfully
    - Work has been comitted.
    - Main branch of evidence-kit CI is failing(smoke test)
    - Unknown if my gen index test(only test I have) is working.       

next:    
    - Generate next session template(for local session)
