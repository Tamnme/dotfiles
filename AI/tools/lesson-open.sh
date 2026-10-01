#!/bin/sh
# Opens the day's Rust+DSA lesson in an Orca terminal: fish starts normally
# (greeting and all), then -C prints the lesson last so it sits right above
# the prompt, in the right directory, ready to run the exercise.
# ponytail: newest-file fallback instead of date math for a missed day.
set -e

LESSONS="/Users/tamnm/code/personal/loopany/daily-lesson/lessons"
f="$LESSONS/$(date +%F).md"
[ -f "$f" ] || f=$(ls -t "$LESSONS"/*.md 2>/dev/null | head -1)

[ -n "$f" ] || { echo "no lesson found in $LESSONS"; exec /opt/homebrew/bin/fish; }

# A terminal can't collapse <details>, so cut the worked answer — printing it
# under the questions would hand over the answers before you've tried them.
exec /opt/homebrew/bin/fish -C "sed -e '/summary>Worked answer/,\$d' -e '/^<details>\$/d' -e '/^<\/details>\$/d' -e 's|<summary>\(.*\)</summary>|— \1 —|' '$f' | bat --style=plain --paging=never -l md; echo '  ↳ write your Track B answer in: $f'"
