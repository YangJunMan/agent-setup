# agent-setup

Standing rules for Claude Code, Codex, and Antigravity. One command, no clone,
no symlinks, nothing left in your home directory.

```bash
curl -fsSL https://raw.githubusercontent.com/YangJunMan/agent-setup/main/install.sh | sh
```

Re-run it to update.

## What it installs

| File | Read by |
|---|---|
| `~/.claude/CLAUDE.md` | Claude Code, in every directory |
| `~/.codex/AGENTS.md` | Codex, in every directory |
| `~/.config/agent-setup/DISCUSSION_RULES.md` | Loaded on demand for multi-agent reviews |
| `~/.claude/commands/discuss.md` | `/discuss` |

Codex reads only `$CODEX_HOME/AGENTS.md` and has no include mechanism, so the
rules are copied there as well — one download, two destinations, verified
identical afterwards. The shared discussion rules sit outside any vendor's
directory. Existing files are copied to `*.bak` first, everything is staged
before anything is written, and a failed download leaves what was there
untouched.

## Antigravity

Antigravity has no user-level rules file — it only reads `AGENTS.md` from the
project directory. In a project it should follow:

```bash
curl -fsSL https://raw.githubusercontent.com/YangJunMan/agent-setup/main/AGENTS.md -o AGENTS.md
```

Claude Code does not read `AGENTS.md` at all, so this file is for Codex and
Antigravity only. Measured: a project holding just `AGENTS.md` costs 13,941
input tokens against 13,933 with no rules; the rules reach Claude Code through
`CLAUDE.md`.

## Cost

About 1,350 input tokens per session, counted once. Measured by running one
identical turn with and without the rules installed (13,933 → 15,285).

## Contents

- `AGENTS.md` — brevity, response language, a pointer to the discussion rules,
  and the [Karpathy Guidelines](https://x.com/karpathy/status/2015883857489522876)
  for reducing common LLM coding mistakes.
- `DISCUSSION_RULES.md` — payload caps, reviewer output contract, round limits,
  and session lifecycle for reviews involving more than one agent. Loaded only
  when such a review starts.

## Optional: per-project install

`init.sh` symlinks the rules into a project and registers them in
`.git/info/exclude`, for a project that needs `AGENTS.md` present or its own
`CLAUDE.md` stub. Not needed if you only use the one-line install above.

```bash
git clone https://github.com/YangJunMan/agent-setup.git
./agent-setup/init.sh ~/some-project
```

## Development

`./check.sh` before committing. It verifies the rule files are English-only and
name no repository path, that every `init.sh` flag the README documents exists,
that referenced files exist, and that installation works in a plain repository,
a linked worktree, and without `~/.codex`.
