# Parked MCP servers

Turned off 2026-07-29 because they were unused, not because they were broken. Each line is a
working re-enable command — paste it and the server is back with its original config.

Evidence: `mcp__` tool-call counts across all 262 transcripts in `~/.claude/projects/`.

| Server | Calls | Tools it added | Status |
|---|---|---|---|
| `plugin_context-mode` | 525 | ~11 | **kept** — the workhorse |
| `context7` | 120 | 2 | **kept** |
| `semble` | 6 | 2 | parked |
| `plan` | 0 | ~45 | parked |
| 11 claude.ai connectors | 0 (none ever authenticated) | 22 | parked |

## Re-enable

```bash
# plan — backs the /visual-plan and /visual-recap skills (both also unused)
claude mcp add --transport http plan https://plan.agent-native.com/_agent-native/mcp

# semble — code search over local/remote git repos
claude mcp add semble -- uvx --from 'semble[mcp]' semble
```

For the claude.ai cloud connectors (Asana, Atlassian, Box, Canva, Figma, Google Drive, HubSpot,
Intercom, Linear, Notion, monday.com), flip the flag in `~/.claude/settings.json`:

```jsonc
"disableClaudeAiConnectors": false   // true = auto-fetched connectors are not loaded
```

Two notes on that flag:

- It only gates **auto-fetched** connectors. A `claudeai-proxy` server passed explicitly (via
  `--mcp-config` or the SDK) still follows the normal MCP trust flow, so an intentional
  one-off is unaffected.
- **Any-source-true wins.** A project setting cannot re-enable connectors that a user-level
  `true` has switched off — change it here, not in a project file.

## Untouched

Project-scoped servers are separate and were left alone: `cocoindex-code` (ECQ/devops),
`agentmemory` (Devyt, ECQ/Mine/iac). They only load in those directories.

## Unrelated finding worth fixing

`~/.claude.json` stores the context7 API key in plaintext under `mcpServers.context7.args`.
That file is not in this repo, so it is not committed — but it is world-readable at rest and
gets printed by anything that dumps the config. Consider moving it to an env var
(`--api-key "$CONTEXT7_API_KEY"`) and rotating the current value.
