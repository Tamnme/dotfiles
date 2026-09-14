# Shell and environment notes (macOS)

Verified friction points. Each one has cost retries in a real session.

- **Create files with the Write tool, not Bash heredocs.** Bash-based file writes get
  blocked; Write does not.
- **The host is macOS — GNU-only flags fail.** No `mv -T`, no bare `sed -i` (BSD `sed`
  requires an extension argument, e.g. `sed -i ''`). Prefer the dedicated file tools over
  in-place stream editing.
- **WiFi SSID**: `system_profiler SPAirPortDataType`. The old `getairportnetwork` /
  `airport` interfaces are gone.
- **The Bash tool runs zsh, not fish.** The interactive shell is fish, so fish quoting and
  word-splitting rules apply to `!`-prefixed input-box commands — but not to Bash tool
  calls. Do not translate one into the other.
- **zsh does not word-split unquoted expansions.** `for f in $FILES` (where
  `FILES=$(git ls-files ...)`) passes the whole multi-line string as ONE argument; bash
  would have split it. Use `cmd | while read -r f` instead. This fails *silently loud*: a
  bulk `sed` loop printed a plausible-looking file list, modified nothing, and only a stray
  "File name too long" gave it away. Verify a bulk edit actually changed files — never
  trust the loop's own output as evidence.
- **`git add -A` after a bulk refactor sweeps in scratch.** Stage explicit paths when the
  repo has known-untracked scratch directories; `-A` ignores the rule you just read.
- **`cd` explicitly.** The working directory persists between Bash calls, but shell state
  (env vars, functions) does not, and a compound `cd` can trip a permission prompt.
- **rtk rewrites `git`/`grep` and its compact output cannot be trusted for exact values.**
  Use `/usr/bin/env git` for hashes, counts, and ref comparisons, and plain `grep` when you
  need file:line structure. Precedent: `git rev-parse --short HEAD origin/main` died with
  "Needed a single revision" while `git log --oneline origin/main -1` printed a hash that
  contradicted `git status -sb` in the same call — four wasted turns and a near-wrong
  conclusion about whether `main` was pushed. `rtk proxy "<cmd>"` did not help.
- **Invoke `aws-vault exec <profile> -- bash -c '<whole script>'` once, not per loop
  iteration.** A `for` loop calling `aws-vault` on each pass returns silent empty output.
- **GitHub facts come from `gh api`, never `curl` or `fetch`.** `curl`/`wget` are blocked by
  the context-mode hook, and unauthenticated `api.github.com` returns 403 on the first burst.
  Precedent: checking latest release tags for 8 observability repos took three attempts —
  curl blocked, then `fetch()` 403 on all 8, then
  `gh api repos/<r>/releases/latest --jq` answered every one in a single call. The
  authenticated CLI was available the whole time.
- **Do not background inside a backgrounded Bash call.** A `run(){ cmd & }` loop plus `wait`
  in a `run_in_background` call is killed silently — the children die and leave zero-byte
  output files with no error and no non-zero exit. Precedent: six agy searches launched that
  way all produced 0 bytes; relaunching them as six separate harness background tasks worked.
  One background task per command.

- **Backticks inside a double-quoted zsh argument are command-substituted.** A commit
  message written as ``-m "… `on` over slaves that are `[fixed]` …"`` silently lost both
  backticked words and printed "command not found: on". Use SINGLE quotes for any message
  or argument containing code spans — commit bodies citing flags and identifiers are the
  usual victim, and the damage is only visible afterwards in `git log`.
- **The `/usr/bin/` prefix habit does not generalise.** It is right for `git` and `grep`
  (rtk rewrites those), but `/usr/bin/cat` does not exist here — it exits 127 and takes the
  rest of a compound command with it. Prefix only what rtk actually intercepts.
- **Short command names are probably aliases.** `k()` fails to define with "defining
  function based on alias". Pick an unambiguous name for a throwaway wrapper function.

## Long output

Bash output is not capped as tightly as older notes claimed — treat long output as a
context-cost problem, not a truncation problem. For genuinely bulk output, use the
context-mode tools (`ctx_execute`, `ctx_batch_execute`) so only the summary enters
context, rather than piping through `tail` and losing the rest.
