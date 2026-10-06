---
name: prd-and-plan
description: Writes a lean local prd.md (problem, solution, decisions-with-why, out of scope, done-means) and turns it into a phase plan.md where phase 1 is a tracer bullet and every phase fits one session. Use this after a requirements interview or design discussion when the user says "write the PRD", "spec this out", "turn that into a plan", "break this into phases", or asks what to build first — and use it whenever a discussion has produced decisions that will be lost if nobody writes them down. Produces files in docs/specs/<feature>/, not tracker issues; for a tracker issue with a full user-story list use to-prd instead, and for step-by-step bite-sized tasks use superpowers:writing-plans.
---

# PRD and Plan

Two artifacts, one pipeline: `prd.md` fixes *what and why*, `plan.md` fixes *in what order*. Run either half alone — write the PRD when the decisions exist but aren't recorded, write the plan when a PRD exists but nobody knows where to start.

Files go in `docs/specs/<feature-slug>/`, both side by side. If the repo already has a spec convention, follow that instead of imposing this one.

**You do not interview here.** The `grill-me` skill exists for that. Your job is synthesis: capture decisions that already got made. If you find yourself inventing an answer the conversation never gave you, stop — that is a missing grill, not a gap for you to fill.

## Phase A — write prd.md

Skip to Phase B if `prd.md` already exists and the user asked for a plan.

```markdown
# PRD: [feature]

## Problem
Who hurts, how badly.

## Solution
What we're building, in 3 sentences.

## Decisions
Every choice made during the grill, with the why.

## Out of scope
Explicitly deferred items.

## Done means
The checkable end state.
```

What each section has to earn:

- **Problem** — name a real actor and a real cost. "Users want notifications" is a feature request wearing a problem's clothes; "on-call engineers miss overnight failures because alerts only reach Slack, and last month two went unnoticed for 9 hours" is a problem. If you can't name who hurts, the feature may not need to exist.

- **Solution** — three sentences, and the limit is the point. If it takes more, the scope spans two features; propose splitting into two PRDs rather than writing a fourth sentence.

- **Decisions** — *the why is the load-bearing half.* A decision recorded without its reasoning gets re-litigated next session, or silently reversed by a future agent who sees no reason not to. Write each as the choice plus what it was chosen over and why: "Accepting a proposal needs no account — friction kills acceptance rates, and we'd rather have spam to moderate than no responses." If this section comes out thin, say so plainly; a PRD whose decisions are vague is a PRD that will be argued about during implementation.

- **Out of scope** — deferral is a decision too, so each item carries what would bring it back. This section exists to stop a future agent from helpfully building something you rejected on purpose.

- **Done means** — every line must be checkable by running a command or making an observation, not by feeling satisfied. This section is not a summary; it's the source the plan's phase gates get built from, so vagueness here propagates into an unverifiable plan.

## Phase B — write plan.md

Read `prd.md` first, even if you wrote it a moment ago — plan against what's on disk, since that's what the implementing session will read.

```markdown
# Plan: [feature]
> PRD: ./prd.md

## Phase 1 — [name] (tracer bullet)
**Slice:** one sentence, end to end.
**Layers:** every layer it touches.
**Faking:** what's deliberately hardcoded or stubbed, and which phase removes it.
**Verify:** the command or observation that proves it works.

## Phase 2 — [name]
**Thickens:** which Phase-1 simplification this removes.
**Verify:** ...
```

The rules, and why they hold:

- **Phase 1 is a tracer bullet**: the thinnest slice that crosses every layer the feature touches, on the simplest data that exercises the path. Not the best version of any layer — the crudest version of all of them, wired together and working. The riskiest unknown in most features is whether the layers connect, and a tracer bullet answers that in phase 1 instead of phase 4.

- **Reject horizontal phases.** "Set up the database" is not a phase; it is the first twenty minutes of a real phase. If a phase's deliverable is a layer rather than a working slice, re-slice it.

- **Name what you're faking.** A tracer bullet is *defined* by its shortcuts, and each shortcut needs the phase that removes it. Fakes with no owning phase are how a prototype quietly becomes production.

- **Each later phase thickens one slice** and ends with something verifiable. One slice, not three — a phase that thickens several is really several phases sharing a heading.

- **Prefer 3 meaty phases over 6 thin ones.** Every boundary costs a session's worth of re-establishing context, and thin phases tempt you back into shipping layers instead of slices.

- **Each phase fits comfortably in one session**, meaning it can be implemented, verified, and committed without a mid-phase handoff. A useful smell: more than about three independent deliverables in one phase and it's two phases.

- **The last phase's Verify should match the PRD's "Done means."** If it doesn't, one of the two documents is wrong — surface the mismatch rather than quietly picking a winner. This check is the cheapest way to catch a plan that drifted from its spec.

## Stopping and reporting

State plainly, rather than papering over:

- Decisions in the PRD are thin or absent → the grill didn't happen. Offer `grill-me`; don't invent decisions to fill the section.
- The solution won't fit in three sentences → propose two PRDs.
- The plan lands at 6+ phases → you're slicing horizontally. Re-slice before showing it.
- "Done means" has a line nobody can check → say which line and ask what would count as proof.

Finish by reporting the file paths, the phase count, and Phase 1's one-sentence slice — that slice is what the user is really approving. Then point at `implement` for execution.
