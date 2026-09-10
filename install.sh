#!/usr/bin/env sh
# Copy shared rules into a project; use --update after reviewing conflicts.
set -eu
base="${AGENT_SETUP_BASE:-https://raw.githubusercontent.com/YangJunMan/agent-setup/main}"
update=0
if [ "${1:-}" = "--update" ]; then update=1; shift; fi
[ "$#" -le 1 ] || { echo "Usage: install.sh [--update] [PROJECT_DIR]" >&2; exit 2; }
target="${1:-.}"
[ -d "$target" ] || { echo "No such directory: $target" >&2; exit 1; }
target=$(cd "$target" && pwd -P)
root=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$root" ] && [ "$target" != "$(cd "$root" && pwd -P)" ]; then
  echo "Run from the repository root: $root" >&2; exit 1
fi
[ ! -L "$target/.agent" ] && { [ ! -e "$target/.agent" ] || [ -d "$target/.agent" ]; } \
  || { echo "Refusing non-directory or symlink: $target/.agent" >&2; exit 1; }
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/.agent"
files="AGENTS.md CLAUDE.md .agent/DISCUSSION_RULES.md"
for file in $files; do
  curl -fsSL "$base/$file" -o "$stage/$file"
  [ -s "$stage/$file" ] || { echo "Empty download: $file" >&2; exit 1; }
done
conflict=0
for file in $files; do
  dst="$target/$file"
  if [ -L "$dst" ] || { [ -e "$dst" ] && [ ! -f "$dst" ]; }; then
    echo "Refusing non-file or symlink: $dst" >&2; exit 1
  fi
  if [ -f "$dst" ] && ! cmp -s "$stage/$file" "$dst"; then
    diff -u "$dst" "$stage/$file" || [ "$?" -eq 1 ]
    conflict=1
  fi
done
if [ "$conflict" = 1 ] && [ "$update" = 0 ]; then
  echo "No files changed. Review the diff, then use --update."
  echo "Preserve project-specific edits before replacing the managed files."
  exit 1
fi
mkdir -p "$target/.agent"
for file in $files; do
  if ! cmp -s "$stage/$file" "$target/$file"; then cp "$stage/$file" "$target/$file"; fi
done
echo "Installed three rule files in $target. Start a new agent session."
