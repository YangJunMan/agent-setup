#!/usr/bin/env bash
# Invariants that manual review kept missing. Run before committing.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"
FAIL=0
fail() { echo "FAIL  $*"; FAIL=1; }
pass() { echo "ok    $*"; }

# 1. Rule files are English. The Language rule itself is the only place the word
#    "Korean" belongs; a Hangul character anywhere means a line slipped through.
hits=$(python3 - <<'PY'
import pathlib, re
bad = []
for f in ["AGENTS.md", "DISCUSSION_RULES.md", "templates/CLAUDE.md",
          "README.md", "init.sh", "check.sh", "claude/commands/discuss.md"]:
    for n, line in enumerate(pathlib.Path(f).read_text().splitlines(), 1):
        # Ranges by codepoint so this checker does not match itself.
        if any("\uac00" <= ch <= "\ud7a3" or "\u3131" <= ch <= "\u318e" for ch in line):
            bad.append(f"{f}:{n}: {line.strip()[:60]}")
print("\n".join(bad))
PY
)
[ -z "$hits" ] && pass "no Hangul in rule files" || { fail "Hangul found:"; echo "$hits" | sed 's/^/      /'; }

# 2. No rule file may name where this repository lives; the repo must work from
#    any path. README may, since it is instructions for a human.
leak=$(grep -n 'agent-setup' AGENTS.md DISCUSSION_RULES.md templates/CLAUDE.md \
       claude/commands/discuss.md 2>/dev/null | grep -v '\.config/agent-setup' || true)
[ -z "$leak" ] && pass "rule files are location-independent" \
               || { fail "rule file hardcodes the repo path:"; echo "$leak" | sed 's/^/      /'; }

# 3. Every long flag the README shows must exist in init.sh.
missing=""
for flag in $(grep -o -- '--[a-z-]\{3,\}' README.md | sort -u); do
  case "$flag" in --dry-run|--copy|--global|--settings-only) ;; *) continue ;; esac
  grep -q -- "$flag)" init.sh || missing="$missing $flag"
done
[ -z "$missing" ] && pass "README flags all implemented" || fail "README documents missing flags:$missing"

# 3. Paths named in the docs must exist.
for f in AGENTS.md DISCUSSION_RULES.md templates/CLAUDE.md claude/settings.json \
         claude/commands/discuss.md init.sh check.sh install.sh; do
  [ -e "$f" ] || fail "referenced file missing: $f"
done
pass "referenced files exist"

# 4. Install fixtures. The worktree case is why this file exists: `.git` is a
#    file there, so an exclude check keyed on a directory silently does nothing.
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git init -q "$TMP/plain"
git init -q "$TMP/main" && git -C "$TMP/main" -c user.email=c@c -c user.name=c \
  commit -q --allow-empty -m init && git -C "$TMP/main" worktree add -q "$TMP/wt" -b wt

for case in plain wt; do
  ./init.sh "$TMP/$case" >/dev/null 2>&1
  untracked=$(git -C "$TMP/$case" status --short 2>/dev/null | grep -c 'AGENTS.md\|DISCUSSION_RULES.md')
  [ "$untracked" = "0" ] && pass "symlinks excluded ($case)" \
                         || fail "symlinks exposed to git ($case)"
done

mkdir -p "$TMP/home/.claude"   # deliberately no ~/.codex
HOME="$TMP/home" ./init.sh --global >/dev/null 2>&1 \
  && pass "--global survives a missing ~/.codex" \
  || fail "--global fails when ~/.codex is absent"

# 5. install.sh must place every file the README says it does, must not write
#    through a symlink into this repo, and must preserve what was already there.
SENTINEL="sentinel-4c1f-not-in-any-rule-file"
H="$TMP/installhome"; mkdir -p "$H/.claude" "$H/.codex"
echo "$SENTINEL" > "$H/.claude/CLAUDE.md"
ln -s "$REPO/AGENTS.md" "$H/.codex/AGENTS.md"
HOME="$H" AGENT_SETUP_BASE="file://$REPO" sh install.sh >/dev/null 2>&1
for f in .claude/CLAUDE.md .config/agent-setup/DISCUSSION_RULES.md .claude/commands/discuss.md .codex/AGENTS.md; do
  [ -f "$H/$f" ] && [ ! -L "$H/$f" ] || fail "install.sh did not write $f as a real file"
done
grep -q "$SENTINEL" "$H/.claude/CLAUDE.md.bak" 2>/dev/null \
  || fail "install.sh discarded the previous CLAUDE.md instead of backing it up"
grep -q "$SENTINEL" "$REPO/AGENTS.md" && fail "install.sh wrote through a symlink into the repo"
cmp -s "$H/.claude/CLAUDE.md" "$H/.codex/AGENTS.md" \
  || fail "install.sh left the two rule copies different"
pass "install.sh installs cleanly over files and symlinks"

[ "$FAIL" = 0 ] && echo "All checks passed." || echo "Checks failed."
exit $FAIL
