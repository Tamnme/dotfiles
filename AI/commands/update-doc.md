Bring this project's docs back in sync with its code, then update the project CLAUDE.md.

1. **Scan what changed.** `git log --oneline -15` and `git diff HEAD~5 --stat`. Adjust the range to cover the stretch of work being documented; if `$ARGUMENTS` names a range or a path, use that instead.

2. **Find where the docs now lie.** For each changed area, read the docs that describe it: README, `docs/`, inline usage examples, API references, config samples, `--help` text. List every specific untruth — renamed commands, changed flags, moved paths, new or removed env vars, dropped features, stale version numbers. A doc that is merely incomplete is not a lie; only list things that would actively mislead.

3. **Fix them surgically.** Match the existing doc style. Do not rewrite sections that are still accurate — a diff that touches only what changed is reviewable, and a wholesale rewrite hides the real corrections.

4. **Project CLAUDE.md pass.**
   - Update any project facts the changes invalidated: commands, paths, stack, ports, test invocation.
   - If this stretch of work involved a correction or a repeated mistake *specific to this repo*, add one dated line for it. If a rule that's in there is now obsolete, remove it — a stale rule is worse than no rule, because it gets followed.
   - Cross-repo lessons (shell friction, infra facts, debugging process, tool routing) belong to `/retro`, which routes them to `~/dotfiles/AI/rules/` and `~/.claude/CLAUDE.md`. Note them for `/retro` here rather than writing them into a project file where only this repo will see them.

5. **Report:** files touched, each lie fixed in one line, and CLAUDE.md lines added or removed. If everything was already in sync, say so in one line and stop — that is the expected outcome most of the time, and inventing edits to look thorough makes the docs worse.

Scope or range if provided: $ARGUMENTS
