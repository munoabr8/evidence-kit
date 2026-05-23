# Evidence Metrics

## Purpose

Define metrics for evaluating evidence quality inside Evidence Kit.


Candidate metrics:

1. MTAD — Mean Time to Assumption Disconfirmation

	- why_it_matters: Operationalizes "How can I disconfirm my assumption?/What would make me not believe this?
	What test can I run to disprove this hypothesis?"
	- example: Assumption--I can use the JIRA issue tracking workflow with no memory aids(for the commands used)
	- failure_mode: only looking at disconfirming data/info.


2. MTAC — Mean Time to Assumption Confirmation
	- why_it_matters: helps sharpen perception of problem/issue. The positive version of #1. 
	- example: implementing JIRA for tracking issues will build up a better picture of a bug or problem 
	- failure_mode: Only looking at confirming data/info.


3. Confidence Delta — confidence_before vs confidence_after
	- why_it_matters: assuming that you are calibrated in the domain/environment(BIG assumption), this metric can help guide where time and effort may yield the highest value.
	- example: spending the time defining these metrics. 
	- failure_mode: if you are NOT calibrated in the domain then over-confidence will be a burden. 


4. Evidence Weight — how diagnostic the artifact is
	- why_it_matters: helps to counter-balance when stuck looking at only one artifact/tunnel vision.
	- example: metrics document can help nudge someone in the right direction if they are stuck. 
	- failure_mode: quantative metrics can be gamed/manipulated.


5. Contradiction Count — number of artifacts conflicting with the assumption

6. Collection Gap — missing evidence needed to update belief
	- why_it_matters: evidence must change the probability of a hypothesis. 
					  updating belief -> updating the model
	- example: tracking issues helped sharpen distinctions between issues I am in the midst of.
	- failure_mode: looking for evidence that already exists, tunnel vision(looking at the evidence)

7. Actionability — whether evidence changed behavior
	- why_it_matters: 
	- example: 
	- failure_mode: 

8. Evidence availability
   Do I already capture the data needed to evaluate this metric?


Criteria:
1.) Easiest to implement, 
2.) Those whose calculation/evaulation  overlap with other metrics(within the set).
3.) Those that will have the highest probability of changing action/behavior/decisions.
4.) Those that will counter-balance my perceptual weaknesses.


- docs/metrics.md exists
- at least 5 metrics are defined
- each metric has: definition, why it matters, example, failure mode
- one metric is applied to an existing debug case





## Applied Example

- case:
- metric_applied:
- observation:
- lesson:
