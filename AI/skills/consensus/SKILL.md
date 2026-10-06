---
name: consensus
description: Use when a question has a factual or best-practice answer but a single response might hallucinate, or when the user asks to "get consensus", "sanity check this", or "check this with multiple agents". Samples the same question across Claude subagents AND Gemini via agy, then tallies by model.
---

# Cross-Model Consensus

One answer is a sample. Five are a distribution. But five samples from *one* model share its priors: a hallucinated API name appears five times, not once. Persona prompting decorrelates weakly. A second model decorrelates properly.

## Procedure

1. **Fix the question.** Compress it to one self-contained prompt with all context inlined. Every sampler gets the identical question; nothing is shared between them.

2. **Sample Claude — 3 subagents in parallel**, varied personas, one line each: "answer as a skeptical staff engineer", "answer as a maintainer who will own this for 5 years", "answer with no persona". The personas vary; the question never does.

3. **Sample Gemini — in the same message, run both:**
   ```bash
   agy-delegate --tier flash --mode plan --digest "<question>. End with a line: ANSWER: <one line>"
   agy-delegate --tier pro   --mode plan --digest "<question>. End with a line: ANSWER: <one line>"
   ```
   `--mode plan` strategizes only and touches nothing. Add `--dir <repo>` when the question is about code, so agy reads the real files instead of your paraphrase. If `agy` is unavailable or exits nonzero, say so and report a Claude-only tally — never silently degrade to single-model and call it consensus.

4. **Require structured answers.** Every sampler ends with `ANSWER: <one line>` plus brief reasoning. Unparseable answers are discarded, not interpreted.

5. **Tally, grouped by model.** Group equivalent answers; count within-Claude and within-Gemini separately.

## Report

- **Consensus**: the majority answer, split shown per model — `4/5 (Claude 3/3, Gemini 1/2)`.
- **Cross-model disagreement is the headline.** A unanimous Claude answer that Gemini contradicts is a yellow light, not a green one — that is exactly the shape of a shared-prior hallucination. Say so explicitly and name the primary source to verify against.
- **Outliers**: every minority answer verbatim, one line on why it diverged. A 1/5 answer is usually a hallucination but occasionally the only sampler that spotted the real problem. Flag any outlier citing something specific the majority ignored.
- **Confidence**: unanimous across both models = act on it. Split within one model = the question was underspecified; say what is missing. Split across models = verify against a primary source before acting.

Cost: 3 Claude subagents plus 2 agy calls; the agy calls do not spend Claude tokens. Use when being wrong costs more than the sampling.
