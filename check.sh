#!/usr/bin/env sh
set -eu
repo=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
export AGENT_SETUP_BASE="file://$repo"
install() { sh "$repo/install.sh" "$@" > "$stage/output" 2>&1; }
fail() { echo "FAIL: $*" >&2; cat "$stage/output"; exit 1; }
reject() { if install "$@"; then fail "unexpected success: $*"; fi; }
mkdir "$stage/project"
git init -q "$stage/project"
install "$stage/project"
for file in AGENTS.md CLAUDE.md .agent/DISCUSSION_RULES.md; do
  cmp "$repo/$file" "$stage/project/$file"
done
count=$(find "$stage/project" -path '*/.git' -prune -o -type f -print | wc -l | tr -d ' ')
[ "$count" = 3 ] || fail "unexpected project files"
install "$stage/project"
echo "ok: three-file installation and repeat"
printf 'local rule\n' > "$stage/project/AGENTS.md"
reject "$stage/project"
grep -q 'local rule' "$stage/project/AGENTS.md" || fail "conflict overwritten"
grep -q '^@@' "$stage/output" || fail "missing diff"
install --update "$stage/project"
cmp "$repo/AGENTS.md" "$stage/project/AGENTS.md"
echo "ok: conflict diff and explicit update"
mkdir "$stage/conflict"
printf 'custom\n' > "$stage/conflict/CLAUDE.md"
reject "$stage/conflict"
[ ! -e "$stage/conflict/AGENTS.md" ] || fail "partial conflict install"
mkdir "$stage/missing" "$stage/incomplete"
cp "$repo/AGENTS.md" "$stage/incomplete/AGENTS.md"
if (AGENT_SETUP_BASE="file://$stage/incomplete" install "$stage/missing"); then fail "missing download accepted"; fi
[ ! -e "$stage/missing/AGENTS.md" ] || fail "partial download install"
echo "ok: no writes after conflict or download failure"
mkdir "$stage/links" "$stage/outside"
ln -s "$stage/outside" "$stage/links/.agent"
reject --update "$stage/links"
[ ! -e "$stage/outside/DISCUSSION_RULES.md" ] || fail "directory symlink followed"
mkdir "$stage/filelink"
ln -s "$repo/AGENTS.md" "$stage/filelink/AGENTS.md"
reject --update "$stage/filelink"
echo "ok: symlink destinations refused"
mkdir "$stage/project/nested"
reject "$stage/project/nested"
git -C "$stage/project" -c user.name=Test -c user.email=test@example.invalid commit -qm initial --allow-empty
git -C "$stage/project" worktree add -qb fixture "$stage/worktree"
install "$stage/worktree"
cmp "$repo/.agent/DISCUSSION_RULES.md" "$stage/worktree/.agent/DISCUSSION_RULES.md"
echo "ok: nested root refusal and linked worktree"
grep -qx '@AGENTS.md' "$repo/CLAUDE.md"
grep -q '\.agent/DISCUSSION_RULES.md' "$repo/AGENTS.md"
sh -n "$repo/install.sh" "$repo/check.sh"
git -C "$repo" diff --check
echo "All checks passed."
