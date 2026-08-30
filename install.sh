#!/usr/bin/env sh
# Install the agent rules where Claude Code and Codex already look for them.
# Nothing is cloned and no symlinks are created; re-run to update.
set -eu

BASE="${AGENT_SETUP_BASE:-https://raw.githubusercontent.com/YangJunMan/agent-setup/main}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SHARED="$HOME/.config/agent-setup"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fetch() { curl -fsSL "$BASE/$1" -o "$TMP/$2"; }

put() { # put <staged-file> <destination>
  [ -L "$2" ] && rm "$2"                 # never write through a symlink
  [ -f "$2" ] && cp "$2" "$2.bak"        # keep whatever was there before
  mkdir -p "$(dirname "$2")"
  cp "$TMP/$1" "$2"
  echo "  $2"
}

# Stage every file first: a failed download must not leave a half-installed set.
fetch AGENTS.md                  rules.md
fetch DISCUSSION_RULES.md        discussion.md
fetch claude/commands/discuss.md discuss-cmd.md

echo "Installing agent rules:"
# Codex has no include mechanism and reads only its own path, so the rules are
# copied to both. One download, two destinations, verified identical below.
put rules.md      "$HOME/.claude/CLAUDE.md"
put rules.md      "$CODEX_HOME/AGENTS.md"
put discussion.md "$SHARED/DISCUSSION_RULES.md"
put discuss-cmd.md "$HOME/.claude/commands/discuss.md"

cmp -s "$HOME/.claude/CLAUDE.md" "$CODEX_HOME/AGENTS.md" \
  || { echo "ERROR: the two copies differ" >&2; exit 1; }

echo "Done. Claude Code and Codex pick these up in every directory."
echo "Antigravity reads no user-level file; in a project it should follow, run:"
echo "  curl -fsSL $BASE/AGENTS.md -o AGENTS.md"
