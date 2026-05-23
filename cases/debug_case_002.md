# Debug Case

- debug_case_id:debug_case_002 
- date:  2026-05-23
- issue_key:  KAN-2
- project:  Evidence Kit

## Assumption
 
I can use minimal CLI debugger commands with low enough friction to observe script execution and record the result in a debug case.
 
## Test

- command: PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x ./script.sh # Lets you see the trace of actually executed code. trace with file/line context
- debugger: python pdb
- command: python3 -m pdb bin/gen-index.py
- debugger_commands_used: n, l, q

- cwd: /Users/abrahammunoz/evidenceKit/evidence-kit/bin
- git_branch: main
- git_commit: 22eed0a

 
## Expected
(Expected result should be measurable.)

	I should be able to use the debugging tools(PS4, -x, python pdb)
	to observe the code execution. 

## Actual
	
	I did observe code execution(although I still need help with the commands to run the debuggers)
	and run the debuggers to completion(end of file)--with the assitance of the commands.
	The debugger was executed on scripts that have been known to work.

- result: debugger started to stopped 
- exit_code:none captured.   

 

## Evidence

- artifact_paths:
 
- case_record: debug_002.md

- CLI output:  observable execution tracing(of code that actually executed).

- issue_key: KAN-2
 

## Resolution

	Observed and better understand the 3 different debugging tools.
 
## Lesson

- future_first_check: Before debugging, choose the runtime first: Bash trace for shell scripts, pdb for Python scripts.