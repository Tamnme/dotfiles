---
name: debate
description: Use when a question has real trade-offs and no single right answer: architecture choices, library selection, design direction. Runs a multi-round debate where Claude subagents and Gemini (via agy) argue assigned positions, rebut each other, and converge. For factual questions, use consensus instead.
---

# Cross-Model Debate

Consensus counts answers. Debate makes them fight. Use it when the value is in the arguments, not the tally.

One model arguing against itself is theater — it knows both scripts and concedes on cue. Give at least one position to a different model and the objections stop being ones you already agreed with.

## Round 1 — positions

The same fully-specified question to three arguers, distinct stances:

- **Claude subagent A**: argue the boldest option.
- **Claude subagent B**: optimize for long-term maintenance.
- **Gemini**, the conservative case:
  ```bash
  agy-delegate --tier pro --mode plan --dir <repo> "<question>. Argue the most conservative option. Return: position, top 3 arguments, and the strongest objection to your own position."
  ```

Each returns: position, top 3 arguments, the strongest objection it can raise against itself.

## Round 2 — rebuttals

Fresh arguers (subagents do not persist; the transcript is the memory). Each gets the question plus ALL Round 1 positions and defends one of them: rebut the other two's best arguments, concede any point that is simply correct, update the position if a rebuttal lands. Keep Gemini on the position it opened with — same `agy-delegate` shape, Round 1 transcript inlined in the prompt.

Forced concessions are the mechanism. A debate where nobody concedes anything is theater.

## Round 3 — convergence (only if Round 2 moved positions)

One Claude subagent gets the full transcript and writes: where positions now agree, where they still differ, and what fact or constraint would settle each remaining difference.

## Synthesis

You, the orchestrator, write the final answer — never a subagent:

- The recommendation, one line.
- The arguments that survived rebuttal — these are the durable reasons.
- The concessions made — these are the recommendation's known costs.
- The conditions under which the losing option wins ("if you expect 10x traffic in year one, flip this").
- **Where the two models split**, if they did. A cross-model disagreement that never resolved is a real open question, not a tie to average away.

Three arguers, two to three rounds. More adds cost faster than insight. If Round 1 comes back unanimous, stop there and say so — the debate was already settled.
