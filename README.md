# agent-setup

Shared project instructions. One copy installer; no clone, symlinks,
global configuration, or background synchronization.

## Install

Run from the target project root:

```sh
curl -fsSL https://raw.githubusercontent.com/YangJunMan/agent-setup/main/install.sh | sh
```

Only these three files are installed:

```text
project/
├── AGENTS.md
├── CLAUDE.md
└── .agent/
    └── DISCUSSION_RULES.md
```

- `AGENTS.md`: shared working rules and conditional discussion-rule loading.
- `CLAUDE.md`: imports `@AGENTS.md`.
- `.agent/DISCUSSION_RULES.md`: discussion, architecture decisions, and
  trade-off analysis. Multi-reviewer steps apply only when multiple reviewers
  participate.

The working rules retain the
[Karpathy Guidelines](https://x.com/karpathy/status/2015883857489522876)
reference used by this repository. Installation distributes instructions;
agent-specific loading and adherence must be verified in a new session.
Antigravity compatibility has not been runtime-verified here.

## Update

Re-running installation keeps identical files. If existing files differ,
it shows a diff and exits without writing anything. After reviewing:

```sh
curl -fsSL https://raw.githubusercontent.com/YangJunMan/agent-setup/main/install.sh | sh -s -- --update
```

`--update` replaces all differing managed files, including local edits.
Commit or otherwise preserve project-specific changes first; no backups
are created. Symlink and non-file destinations are refused even with
`--update`. All downloads and destination checks finish before copying.
A later filesystem write failure is not automatically rolled back.

Existing global installations and legacy project files are not migrated or
removed. Review them separately to avoid duplicate instructions.
Changes to this repository are presented for user review before pushing.

## Local development

```sh
AGENT_SETUP_BASE="file://$PWD" sh install.sh /path/to/project
sh check.sh
```

`install.sh`, `check.sh`, and this README stay in this source repository;
they are not copied to projects. Checks cover file layout, repeat installs,
conflicts, explicit updates, failed downloads, symlinks, and linked worktrees.
