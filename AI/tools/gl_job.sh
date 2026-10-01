#!/usr/bin/env bash
# gl_job.sh — summarise one GitLab CI job: metadata, truncation, phases, errors.
#
# Usage:  gl_job.sh <job-url | job-id> [max_lines]
#   job-url  https://git.example/group/proj/-/jobs/8738   (works from any directory)
#   job-id   8738                                          (uses the current repo's :id)
#
# Saves the cleaned trace (CR and ANSI stripped) to $GL_JOB_DIR/job-<id>.txt,
# default ${TMPDIR:-/tmp}/gl_job, and prints only a digest. Read the file for more.
#
# Why this exists: the same glab + tr + sed + grep pipeline was hand-built six
# times in one session, and a 4 MB-truncated trace went unnoticed until its
# (missing) ending was needed. Truncation is reported FIRST for that reason.
set -uo pipefail

arg=${1:?"usage: gl_job.sh <job-url|job-id> [max_lines]"}
max=${2:-60}
GREP=/usr/bin/grep   # bypass rtk's rewritten grep: it summarises, and this needs exact lines

if [[ "$arg" =~ ^https?://([^/]+)/(.+)/-/jobs/([0-9]+) ]]; then
  # glab otherwise targets the cwd repo host (or gitlab.com outside a repo).
  export GITLAB_HOST=${BASH_REMATCH[1]}
  proj=$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "${BASH_REMATCH[2]}")
  id=${BASH_REMATCH[3]}
elif [[ "$arg" =~ ^[0-9]+$ ]]; then
  proj=":id"; id=$arg
else
  echo "not a job url or id: $arg" >&2; exit 2
fi

dir=${GL_JOB_DIR:-${TMPDIR:-/tmp}/gl_job}; mkdir -p "$dir"
out="$dir/job-$id.txt"

meta=$(glab api "projects/$proj/jobs/$id" 2>&1) || { echo "glab api failed: $meta" >&2; exit 1; }
python3 - "$meta" <<'PY'
import json, sys
j = json.loads(sys.argv[1]); d = j.get("duration") or 0
print(f"job      {j['id']}  {j['name']}  [{j['stage']}]")
print(f"status   {j['status']}" + (f"  reason={j['failure_reason']}" if j.get("failure_reason") else ""))
print(f"ref/sha  {j['ref']}  {j['commit']['short_id']}  {j['commit']['title'][:60]}")
print(f"pipeline {j['pipeline']['id']} ({j['pipeline']['status']})")
print(f"time     {j.get('started_at') or '-'} -> {j.get('finished_at') or '-'}  ({d/60:.1f} min)")
print(f"runner   {(j.get('runner') or {}).get('description') or '-'}")
PY

# Fetch to a file, never through a pipe into a variable: an empty response is a
# real possibility (seen once, transiently) and must be visible, not silent.
if ! glab api "projects/$proj/jobs/$id/trace" > "$out.raw" 2>"$out.err"; then
  echo "trace fetch failed: $(head -c 300 "$out.err")" >&2; exit 1
fi
tr -d '\r' < "$out.raw" | sed $'s/\x1b\\[[0-9;]*[mK]//g' > "$out"; rm -f "$out.raw" "$out.err"
bytes=$(wc -c < "$out" | tr -d ' '); lines=$(awk 'END{print NR}' "$out")
echo "trace    $out  ($lines lines, $bytes bytes)"
[[ "$bytes" -gt 0 ]] || { echo "!! EMPTY TRACE — refetch before concluding anything"; exit 1; }

if $GREP -q "Job's log exceeded limit" "$out"; then
  echo "!! TRUNCATED — GitLab stopped collecting at the size limit. The ending below is NOT the"
  echo "!! job's ending; trust only the status above for the outcome."
fi

# Strip GitLab's per-line prefix ("2026-...Z 01O ") for readability.
body() { sed -n '/step_script/,$p' "$out" | sed -E 's/^[0-9T:.-]+Z [0-9]+[OE][+ ]?//'; }

echo "--- commands + script phase lines (first $max) ---"
body | $GREP -aE '^\$ |^\[20[0-9-]+T[0-9:]+Z\] ' | head -n "$max"

echo "--- errors / warnings (deduped, first 20) ---"
# bash's own errors carry no "ERROR" keyword (`x.sh: line 44: [options]: invalid
# variable name`) — without the `: line N:` alternatives the real cause of a failed
# job can be absent from this section entirely.
body | $GREP -aE 'ERROR|FAIL|Traceback|WARN(ING)?:|fatal:|Job failed|Job succeeded|: line [0-9]+: |command not found|unbound variable|No such file|Permission denied' \
     | $GREP -avE 'odoo.modules.module: Missing `(author|license)`' \
     | awk '!seen[$0]++' | head -n 20

echo "--- last 8 lines ---"
tail -n 8 "$out" | sed -E 's/^[0-9T:.-]+Z [0-9]+[OE][+ ]?//' | cut -c1-200
