@~/.claude/RTK.md
## graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

## Subagents

- **Don't spawn for**: judgment calls, design decisions, fixes where you need the file open after.
- **Do spawn for**: bulk reads, parallel greps, scoped research with clear "return X" contract.

**Pre-authorised without asking — parallel read-only triage.** When triaging **3 or more
unrelated symptoms**, spawn one read-only investigator per symptom instead of working through
them serially. Each is strictly read-only (no mutations, no `kubectl apply/delete`, no edits)
and returns: symptom · evidence gathered (exact commands + key output) · root cause ·
confidence · proposed minimal fix · blast radius. Each must state explicitly when a hypothesis
is REFUTED rather than moving on silently. The main thread only synthesises into one
prioritised table and asks which fix to ship first — it does not remediate.

This is the fix for serial context burn: multi-symptom sessions have repeatedly run out of
context mid-investigation with most tasks unfinished. Anything outside this carve-out —
mutations, single-symptom work, implementation — still needs an explicit request.

> Note: a stricter "do not call the AgentTool unless the user requested it" is injected by
> Orca (`~/.orca/agent-hooks/claude-hook.sh`) inside Orca worktrees, not by this file. The
> carve-out above is deliberate and user-approved; if the two conflict in an Orca session,
> that is Orca's rule to relax, not a reason to re-litigate this one each time.

Pick the cheapest model that can do the subtask well:
- Haiku: bulk mechanical work, no judgment
- Sonnet: scoped research, code exploration, in-scope synthesis
- Opus: subtasks needing real planning or tradeoffs

If a subagent finds the task needs a higher tier, surface that in its return message; parent re-spawns at the right tier.

**Effort is set per agent type, not per call** — route by kind of work:
- **Code from a plan or explicit instructions → `subagent_type: implementer`** (Opus, low effort). This overrides skills that dispatch a `general-purpose` implementer (superpowers subagent-driven-development). Implementer's "tests pass" is a claim: re-run the gate yourself in a clean state. On a plan gap it stops and reports; resolve the gap, then retry `implementer` with a sharper brief. Fix round 4+ goes to `general-purpose` (inherits medium), not `architect`.
- **Delegated architecture design → `subagent_type: architect`** (Opus, high, read-only). It returns a design; the parent writes the spec and runs the approval gate. Design dialogue with the user stays in the main thread — raise it with `/effort high` (or `xhigh` for one-way doors) rather than delegating.
- Everything else (review, diagnosis, research, Explore) inherits the session effort; pick the model per call as above.

**A subagent told to re-score from existing notes launders their errors into fresh
authority.** When the output carries a recommendation, brief it to re-verify the
load-bearing cells at source and cite the sha; the token saving is not worth shipping a
wrong cell under a new title. Precedent: `llm-gateway-vs-custom.md` recorded that LiteLLM
has no pre-call budget reservation, four months after `budget_reservation.py` landed. The
brief said "do not re-research", so three cells of a fifteen-candidate matrix shipped
wrong and needed a correction banner the next day.

**A handoff doc names files on the branch its author was on, not on your checkout. Verify
they exist before dispatching readers at them.** Run `git ls-files <paths>` and check the
branch first — a doc's file list is a claim about someone else's working tree. Precedent: two
Explore agents were dispatched at `poc/` and `docs/` on the strength of a plan document and
both returned "no such files"; the entire POC lived on an unmerged branch while the tree was
on `main`. The corrections sent mid-flight were then flagged by both agents as suspected
prompt injection and partly ignored, so the wasted runs could not even be salvaged. The same
wrong-checkout read also produced a shipped-then-retracted finding that
`.planning/.active_plan` was dangling: an **untracked** pointer to a **tracked** target reads
as broken from every branch that does not carry the target.

**Run baselines in their own clean worktree at BASE, never in the worktree implementers are
editing.** A long gate (Docker build, integration suite) that overlaps an edit measures a
half-applied tree, and its result cannot be attributed to either side. Precedent: an 11-minute
regression-gate baseline, run while Task 1 was editing `app/`, reported one failure that could
be a flake or a half-applied edit; the clean `git worktree add --detach … <BASE>` rerun was 0
failures, and the first run's time was wasted. The same clean tree then served every
base-vs-branch comparison.

Parent owns final output and cross-spawn synthesis. User instructions override.

## Preferred Tools

### Data Fetching

1. **WebFetch is blocked by the context-mode hook — go straight to `ctx_fetch_and_index`.** The call fails with a message telling you to switch, so reaching for it first is a wasted round every time. Use the batch shape `requests:[{url,source},...]` with `concurrency:4-8` (3-5x faster than sequential on a multi-URL sweep), then `ctx_search(queries:[...])` to read what landed. Docs pages that render their tables in JS come back as a title and nothing else — when a live account or CLI can answer the same question, query that instead of fighting the page. Precedent: AWS's Bedrock CloudWatch-metrics pages returned empty twice; `aws cloudwatch list-metrics` answered in one call.
2. **agent-browser CLI**: free, local Rust CLI + Chrome via CDP. For dynamic pages or auth walls that WebFetch can't handle. Returns the accessibility tree with element refs (@e1, @e2). Far fewer tokens than screenshot-based tools. Install: `npm i -g agent-browser && agent-browser install`. Use `snapshot` for AI-friendly DOM state, element refs for interaction.
3. **Wrap repeated fetch/parse logic as a dedicated tool.** If you write the same fetch/parse logic twice in a session, stop and propose wrapping it as a named tool (a skill file or a `.py` script that calls `agent-browser` with the snapshot and extraction steps baked in for that source). Put new scripts in `~/.claude/tools/`, add the entry to `## Dedicated Tools` below, and reference it by name on future calls.
4. **Smoke-test a delegated search worker before fanning out — across FLAGS, not just one prompt.** One cheap call first — it validates the model name AND that output is non-empty. `agy-delegate --tier <t>` remaps to a model that may not be on the plan, and agy print-mode web search can return **empty with exit 0**, which reads as success. Precedent: 13 agy research calls, 3 usable; ~6 rounds lost across three waves before a single-call smoke test found both failure modes. Use `--print-command` to check flag mapping. **agy's empty-output-with-exit-0 has at least three INDEPENDENT causes — a search-flavoured prompt, `--dir`, and `--mode plan` each return empty while plain `-p` generation on the same model works fine.** Testing one dimension and assuming you have found the failure surface cost a rediscovery mid-debate: the search cause was established early, then `--dir` and `--mode plan` failed again two hours later. Matrix it once — plain / `--dir` / `--mode` / search-prompt — and note that a `say OK` probe passes while search is dead, so the smoke test must itself be search-flavoured. (Both flash tiers are now pinned to real models via `CLAUDE_PLUGIN_OPTION_TIER_FLASH` / `_TIER_FLASH_LO` in `settings.json` `env` — the built-in defaults point at Gemini 3.5, which does not exist on this plan. `pro` → 3.1 Pro (High) is fine. Re-check all three after an agy or plugin upgrade.)
5. **Two domains is not two sources — check the byline before calling a claim corroborated.** Precedent: the "VictoriaLogs is 94% faster / 40% less storage than Loki" figures appear on `harshit.cloud` and `truefoundry.com` with near-identical methodology tables. Same author (Harshit Luthra) — one experiment, two URLs. Cross-domain agreement was zero evidence.

### PDF Files

Default path is `~/.claude/tools/pdf_extract.py`, which auto-selects pdftotext vs OCR — don't call `pdftotext` directly. Run `~/.claude/tools/pdf_triage.py` first if you're unsure how a file should be read. Use the `Read` tool only when the user directly asks to analyze images or charts inside the document, or when extraction returns empty/garbled text. Read loads PDFs as images.

Deps (install on first use): `pip install pypdf pdf2image pytesseract pdfplumber` and `brew install poppler tesseract` (+ `ghostscript` if using camelot for tables).

## Dedicated Tools

- `~/.claude/tools/pdf_triage.py <file> [--sample N]` — classify TEXT/SCANNED/MIXED before reading. Run first when read strategy is unclear.
- `~/.claude/tools/pdf_extract.py <file> [--pages A-B] [--force-ocr] [--no-ocr]` — auto-selects pdftotext vs OCR. Default extraction path.
- `~/.claude/tools/pdf_tables.py <file> [--pages A-B] [--out DIR]` — structured table extraction (camelot→pdfplumber fallback).
- `~/.claude/tools/pdf_split.py <file> --pages A-B [--out FILE]` — slice large PDFs before reading.
- `~/.claude/tools/gl_job.sh <job-url|job-id> [max_lines]` — GitLab CI job digest: metadata, **truncation warning first**, script phase lines, deduped errors (incl. bash `line N:` errors), last lines. Cleaned trace saved to `$TMPDIR/gl_job/job-<id>.txt`. URL form works from any dir (sets `GITLAB_HOST`); bare id uses the cwd repo. Use this instead of hand-building glab + tr + sed pipelines.
