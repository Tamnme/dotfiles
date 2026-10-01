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
- **Quote glob patterns passed as flag values — `--include='*.md'`, not `--include=*.md`.**
  zsh expands the bare pattern against the cwd, finds no match, and aborts the command
  before it runs: `(eval):1: no matches found: --include=*.md`. grep never executes, and the
  error reads like "no results" rather than "your command did not run". Separate failure
  mode from the word-splitting note above, and it cost five retries in one session across
  `*.md`, `*.py`, `*.sh` and `*.yml`.
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
- **`git fetch origin a b c` is all-or-nothing.** One ref that no longer exists (a merged,
  deleted branch) makes git fatal out and update *none* of the others, so every later
  `origin/<x>` comparison runs against stale refs. Fetch the refs you need separately, or check
  `$?` before building on them. Precedent: a fetch naming a just-deleted MR branch left
  `origin/release/v0.1.0` one merge behind; a patch was generated against the stale tip.
- **rtk truncates `ansible-playbook` output too, and writes its marker INTO the stream.** Same
  shape as the documented `helm` case: exit code 0, and `... (N lines truncated)` lands inside
  the file even when you redirect with `> log 2>&1`. Call `/opt/homebrew/bin/ansible-playbook`
  for any run you will grep. Precedent: a fix was declared verified because a warning string was
  absent from a 61-line log; the untruncated run was 184 lines and both the PLAY RECAP and the
  real evidence were in the part that had been cut. **Absence of a string in an rtk-piped log is
  never evidence** — only a positive match is. Check for the marker before trusting a negative.
- **rtk also rewrites `pytest` into a one-line summary, and the exit code survives neither.**
  `python3 -m pytest … > log 2>&1` left a 2-line file reading `Pytest: 36 passed, 1 failed`,
  with no test name, and the wrapper printed exit 0. Pass `--junitxml=<file>` and read the
  failures from the XML; pytest writes it regardless of what rtk does to stdout. Precedent:
  an 11-minute Docker regression gate had to be re-run in full just to learn which test failed.
- **A git worktree does not survive being mounted into a container.** Its `.git` is a file
  (`gitdir: /Users/…/.git/worktrees/<name>`) naming a host path, so git inside the container
  fails and any test reading the sha or dirty flag gets `None`. Installing git does not fix it.
  Mount the main repo's `.git` read-only at the **same host path**, mount the worktree at its
  own host path, `-w` into it, and set `git config --global --add safe.directory '*'`.
- **boto3 in a bare container reads `AWS_DEFAULT_REGION`; `AWS_REGION` alone gives
  `NoRegionError`.** Code that passes `region_name=` explicitly works while an ad-hoc
  `boto3.client(...)` setup step beside it fails. Set both. Precedent: a DynamoDB Local
  table was never created, and every downstream check read like a gateway 503.
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
- **Piping a script to `tail`/`head` reports the PIPE's exit code, not the script's.** A
  gate printed `T3 RED` while the harness reported `exited with code 0`, because the run was
  `bash gate.sh | tail -30`. Three calls went into isolating a bash EXIT-trap bug that does
  not exist — bash preserves the original status through an EXIT trap. Redirect to a file
  and read `$?`, or use `${PIPESTATUS[0]}`, whenever the exit code is itself the finding.

## Long output

Bash output is not capped as tightly as older notes claimed — treat long output as a
context-cost problem, not a truncation problem. For genuinely bulk output, use the
context-mode tools (`ctx_execute`, `ctx_batch_execute`) so only the summary enters
context, rather than piping through `tail` and losing the rest.
