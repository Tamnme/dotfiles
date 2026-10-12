#!/usr/bin/env bash
# Link Claude Code config from this repo into $HOME, then install plugins.
# Idempotent. First run on a machine with existing real config adopts it into
# the repo if the repo has no copy, otherwise moves it aside to *.pre-dotfiles.
set -euo pipefail
AI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$AI")"

link() { # link <src> <dst>
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ -e "$src" ]; then mv "$dst" "$dst.pre-dotfiles.$(date +%s)"
    else mv "$dst" "$src"; fi
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
}

mkdir -p "$HOME/.claude"
for f in CLAUDE.md RTK.md settings.json agents rules tools skills commands hooks; do
  link "$AI/$f" "$HOME/.claude/$f"
done
link "$REPO/.agents" "$HOME/.agents" # skills CLI installs; ~/.claude/skills/* link here relatively

command -v claude >/dev/null || { echo "claude not on PATH; skipping plugins"; exit 0; }
# Anthropic's sample mods (blast-radius) sit in a repo subfolder, so settings.json
# registers that marketplace as a local directory source pointing into this clone.
pg="$HOME/.claude/plugins/local/claude-code-playground"
[ -d "$pg" ] || git clone -q --depth 1 https://github.com/anthropics/claude-code-playground.git "$pg"
# Directory sources carry an absolute path; rebase /Users/<name> onto this $HOME.
{ echo anthropics/claude-plugins-official
  jq -r '.extraKnownMarketplaces[].source | .repo // (.path | sub("^/Users/[^/]+"; env.HOME))' "$AI/settings.json"; } |
  while read -r repo; do claude plugin marketplace add "$repo" || true; done
jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' "$AI/settings.json" |
  while read -r p; do claude plugin install "$p" || true; done
