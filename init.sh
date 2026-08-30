#!/usr/bin/env bash
# Link this repo's agent rules into a project (default), or install them at user
# level (--global: ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, commands, settings).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=project
LINK=symlink
DRY=0
SETTINGS_ONLY=0

usage() {
  cat <<EOF
Usage:
  init.sh [--copy] [--dry-run] [TARGET_DIR]   link rules into a project (default: cwd)
  init.sh --global [--dry-run]                install user-level config
  init.sh --global --settings-only            merge settings.json only, no rule files

  --copy           copy files instead of symlinking (for repos shared with others)
  --settings-only  with --global: skip the rule files, merge ~/.claude/settings.json
  --dry-run        print what would happen, change nothing
EOF
}

for arg in "$@"; do
  case "$arg" in
    --global) MODE=global ;;
    --copy) LINK=copy ;;
    --settings-only) SETTINGS_ONLY=1; MODE=global ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; usage >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done

say() { echo "  $*"; }
run() { if [ "$DRY" = 1 ]; then say "would: $*"; else "$@"; fi; }

# place SRC at DST; never clobber a real file that is not ours
place() {
  local src=$1 dst=$2
  if [ -L "$dst" ]; then
    local cur; cur=$(readlink "$dst")
    if [ "$cur" = "$src" ]; then say "ok       $dst"; return; fi
    say "relink   $dst (was -> $cur)"
    run rm "$dst"
  elif [ -e "$dst" ]; then
    if [ "$LINK" = copy ] && cmp -s "$src" "$dst"; then say "ok       $dst"; return; fi
    say "SKIP     $dst already exists — remove it first if you want it managed"
    return
  else
    say "create   $dst"
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ "$LINK" = copy ]; then run cp "$src" "$dst"; else run ln -s "$src" "$dst"; fi
}

install_project() {
  local dir="${TARGET:-$PWD}"
  [ -d "$dir" ] || { echo "no such directory: $dir" >&2; exit 1; }
  dir="$(cd "$dir" && pwd)"
  echo "Project setup: $dir"

  place "$REPO/AGENTS.md"           "$dir/AGENTS.md"
  place "$REPO/DISCUSSION_RULES.md" "$dir/DISCUSSION_RULES.md"

  # CLAUDE.md is always a copy: each project appends its own context to it.
  if [ -e "$dir/CLAUDE.md" ]; then
    say "ok       $dir/CLAUDE.md (kept — verify it has the @AGENTS.md import)"
  else
    say "create   $dir/CLAUDE.md (from template)"
    run cp "$REPO/templates/CLAUDE.md" "$dir/CLAUDE.md"
  fi

  # Symlinks must not be committed: they break on other machines. Ignore them
  # locally via .git/info/exclude so the repo's own .gitignore stays untouched.
  # `.git` is a file in a linked worktree, so ask git for the real exclude path.
  local ex=""
  if [ "$LINK" = symlink ]; then
    ex=$(git -C "$dir" rev-parse --git-path info/exclude 2>/dev/null || true)
    case "$ex" in "") : ;; /*) : ;; *) ex="$dir/$ex" ;; esac
  fi
  if [ -n "$ex" ]; then
    for f in AGENTS.md DISCUSSION_RULES.md; do
      if [ -f "$ex" ] && grep -qx "/$f" "$ex" 2>/dev/null; then continue; fi
      say "ignore   /$f (.git/info/exclude)"
      if [ "$DRY" = 0 ]; then mkdir -p "$(dirname "$ex")"; echo "/$f" >> "$ex"; fi
    done
  fi
}

install_global() {
  local cdir="$HOME/.claude"
  echo "Global setup: $cdir"
  run mkdir -p "$cdir"

  if [ "$SETTINGS_ONLY" = 0 ]; then
    # Rules apply in every directory, including projects never run through init.sh.
    place "$REPO/AGENTS.md" "$cdir/CLAUDE.md"
    # Codex reads its user-level rules from ~/.codex/AGENTS.md.
    [ -d "$HOME/.codex" ] && place "$REPO/AGENTS.md" "$HOME/.codex/AGENTS.md"
    # Fixed location for the conditional rules, so no rule file has to name
    # where this repository lives.
    place "$REPO/DISCUSSION_RULES.md" "$HOME/.config/agent-setup/DISCUSSION_RULES.md"
    # Antigravity has no user-level rules file; it reads the project AGENTS.md
    # that install_project links.
  fi

  for sub in commands agents; do
    [ "$SETTINGS_ONLY" = 1 ] && break
    if [ -n "$(ls -A "$REPO/claude/$sub" 2>/dev/null | grep -v '^\.gitkeep$' || true)" ]; then
      run mkdir -p "$cdir/$sub"
      for f in "$REPO/claude/$sub"/*; do
        [ -e "$f" ] || continue
        case "$(basename "$f")" in .gitkeep) continue ;; esac
        place "$f" "$cdir/$sub/$(basename "$f")"
      done
    fi
  done

  # settings.json is machine-specific (hooks, statusLine, paths): merge our keys
  # in rather than overwriting, and keep a backup.
  local dst="$cdir/settings.json"
  if [ "$DRY" = 1 ]; then say "would: merge $REPO/claude/settings.json into $dst"; return; fi
  python3 - "$REPO/claude/settings.json" "$dst" <<'PY'
import json, os, shutil, sys
src_path, dst_path = sys.argv[1], sys.argv[2]
src = json.load(open(src_path))
dst = {}
if os.path.exists(dst_path):
    with open(dst_path) as fh:
        dst = json.load(fh)
    shutil.copy(dst_path, dst_path + ".bak")

changed = []
for key, value in src.items():
    if isinstance(value, dict) and isinstance(dst.get(key), dict):
        merged = {**dst[key], **value}
        if merged != dst[key]:
            dst[key] = merged
            changed.append(key)
    elif dst.get(key) != value:
        dst[key] = value
        changed.append(key)

if changed:
    with open(dst_path, "w") as fh:
        json.dump(dst, fh, indent=2)
        fh.write("\n")
    print("  settings " + ", ".join(changed) + (" (backup: settings.json.bak)" if os.path.exists(dst_path + ".bak") else ""))
else:
    print("  settings unchanged")
PY
}

case "$MODE" in
  global) install_global ;;
  project) install_project ;;
esac
echo "Done."
