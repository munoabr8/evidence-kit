# Debug Case

- debug_case_id:  
- date:  
- issue_key:  
- project:  


## Assumption 
- **Situation:** [Undisputed baseline state of the system/code]
- **Complication:** [The trigger or friction point that failed]
- **Core Question:** [The explicit diagnostic puzzle to solve]

## Test
- command: 
- cwd:  
- git_branch:
- git_commit:

## Expected

## Actual
- result:  
- exit_code:  

## Evidence
- artifact_paths:
- case_record:
- issue_key:

## Resolution  
> **The Answer:** [The ultimate conclusion or fix that answers the Core Question]

- **Supporting Argument 1 (MECE):** [First distinct logical proof from your Test/Evidence]
- **Supporting Argument 2 (MECE):** [Second distinct logical proof from your Test/Evidence]

## Note: The symptom of the bug
## may be observed in one of the layers only but the final answer can possibly sprawl one layer
## or more.

## Lesson
- future_first_check:



The best practice is triaging sequentially from the bottom up (Level 0 $\rightarrow$ Level 1 $\rightarrow$ Level 2), while documenting your final resolution from the top down.


▲  [ LEVEL 2: SEMANTIC ]  --> Truth & Meaning (Is the data logically correct?)
│  
│  [ LEVEL 1: FUNCTIONAL ] --> Action & Pipeline (Did the program execute its mechanics?)
│  
│  [ LEVEL 0: ENVIRONMENTAL ] -> Existence & Ground (Are the tools physically present?)


## Understanding different levels of abstraction
If your cursor is in debug_case.md, you are a Judge manipulating the Map. You are acting with intent, logic, and structure.

If your cursor is in the live Terminal emulator, you are a Detective traversing the Territory. You are exploring, capturing, and generating raw evidence blocks.

