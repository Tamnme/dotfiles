Post-session retro. Extract what this session can teach the next one.

Review this conversation and answer concretely:

1. **What could have been faster?** Find the slowest stretches: repeated exploration a known fact would have skipped, a wrong turn from a missing constraint, tool friction, anything you had to be told twice. Name the cause, not the symptom.

2. **What should the rules learn?** Propose specific one-line additions, each routed to the file it belongs in:

   | Destination | For |
   |---|---|
   | `~/dotfiles/AI/rules/shell-notes.md` | macOS / shell / tooling friction that cost a retry |
   | `~/dotfiles/AI/rules/infra-facts.md` | Infrastructure facts, deployment mechanisms, "don't guess X" |
   | `~/dotfiles/AI/rules/diagnosis-protocol.md` | Debugging-process corrections |
   | `~/.claude/CLAUDE.md` | Cross-project workflow, subagent and tool-routing policy |
   | `<project>/CLAUDE.md` | Facts true only for this repo |
   | memory (`type: feedback`) | A preference about how I should work, with the why |

   Every proposal must be something that would have changed **this** session, not generic advice. 0-4 proposals; quality over volume. If nothing qualifies, say "nothing worth adding" and stop — that is a valid outcome, and the most common one.

3. **Should anything become a skill, command, or hook?** If a prompt pattern appeared 2+ times this session, propose packaging it. If a mistake was procedural rather than a judgment call, propose the hook that would have blocked it.

Then ask before applying anything. Show the diff per file. Do not edit without approval: every line added taxes every future session, so the human curates.

Match each destination file's existing style — those files state a rule, then the precedent that earned it.

Focus area if provided: $ARGUMENTS
