# CLI Debugging Workflow

## Purpose

Use minimal CLI debugger commands to observe execution flow, reduce guessing, and create better debug cases.



## Runtime Selection Rule

Choose the debugger based on the file being executed.

- Bash script failure → Bash tracing
- Python script failure → Python pdb

If a Bash script calls a Python script:

1. Trace the Bash wrapper first.
2. If Bash reaches Python correctly, debug the Python script next.

## Bash Debugging

### Basic trace

```bash
bash -x ./script.sh


PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x ./script.sh


python3 -m pdb path/to/script.py


n = next line
s = step into function
c = continue
l = list nearby source lines
p variable_name = print variable
q = quit
h = help