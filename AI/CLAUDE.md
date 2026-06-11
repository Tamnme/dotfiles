@~/.claude/RTK.md
## graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

## Subagents

- **Don't spawn for**: judgment calls, design decisions, fixes where you need the file open after.
- **Do spawn for**: bulk reads, parallel greps, scoped research with clear "return X" contract.

Pick the cheapest model that can do the subtask well:
- Haiku: bulk mechanical work, no judgment
- Sonnet: scoped research, code exploration, in-scope synthesis
- Opus: subtasks needing real planning or tradeoffs

If a subagent finds the task needs a higher tier, surface that in its return message; parent re-spawns at the right tier.

Parent owns final output and cross-spawn synthesis. User instructions override.

## Preferred Tools

### Data Fetching

1. **WebFetch**: free, text-only, works on public pages that don't block bots.
2. **agent-browser CLI**: free, local Rust CLI + Chrome via CDP. For dynamic pages or auth walls that WebFetch can't handle. Returns the accessibility tree with element refs (@e1, @e2). Far fewer tokens than screenshot-based tools. Install: `npm i -g agent-browser && agent-browser install`. Use `snapshot` for AI-friendly DOM state, element refs for interaction.
3. **Wrap repeated fetch/parse logic as a dedicated tool.** If you write the same fetch/parse logic twice in a session, stop and propose wrapping it as a named tool (a skill file or a `.py` script that calls `agent-browser` with the snapshot and extraction steps baked in for that source). Put new scripts in `~/.claude/tools/`, add the entry to `## Dedicated Tools` below, and reference it by name on future calls.

### PDF Files

Default path is `~/.claude/tools/pdf_extract.py`, which auto-selects pdftotext vs OCR — don't call `pdftotext` directly. Run `~/.claude/tools/pdf_triage.py` first if you're unsure how a file should be read. Use the `Read` tool only when the user directly asks to analyze images or charts inside the document, or when extraction returns empty/garbled text. Read loads PDFs as images.

Deps (install on first use): `pip install pypdf pdf2image pytesseract pdfplumber` and `brew install poppler tesseract` (+ `ghostscript` if using camelot for tables).

## Dedicated Tools

- `~/.claude/tools/pdf_triage.py <file> [--sample N]` — classify TEXT/SCANNED/MIXED before reading. Run first when read strategy is unclear.
- `~/.claude/tools/pdf_extract.py <file> [--pages A-B] [--force-ocr] [--no-ocr]` — auto-selects pdftotext vs OCR. Default extraction path.
- `~/.claude/tools/pdf_tables.py <file> [--pages A-B] [--out DIR]` — structured table extraction (camelot→pdfplumber fallback).
- `~/.claude/tools/pdf_split.py <file> --pages A-B [--out FILE]` — slice large PDFs before reading.
