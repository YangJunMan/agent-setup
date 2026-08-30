# Agent Rules

Be brief. Answer only what matters; no preamble, no restated summary, no CoT.
Respond in Korean, keeping technical terms, commands, config keys, and product
names in English.

For a review or discussion involving more than one agent, read
`DISCUSSION_RULES.md` — from the project root if present, otherwise
`~/.config/agent-setup/DISCUSSION_RULES.md` — and follow it. Not for ordinary coding work.

Facts specific to one project belong in that project's own instruction file.

## Think Before Coding
- State assumptions explicitly. If something is unclear or you are uncertain,
  stop, name what is confusing, and ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.

## Simplicity First
- Minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked, no abstractions for single-use code, no
  unrequested "flexibility," no error handling for scenarios that cannot occur.

## Surgical Changes
- Touch only what you must; clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting; don't refactor what
  isn't broken; match existing style.
- Remove imports/variables/functions your own changes made unused; don't remove
  pre-existing dead code unless asked — mention it instead.
- Every changed line should trace directly to the user's request.

## Goal-Driven Execution
- Define success criteria and loop until verified.
- "Add validation" → write tests for invalid inputs, then make them pass.
- "Fix the bug" → write a test that reproduces it, then make it pass.
- "Refactor X" → ensure tests pass before and after.
- For multi-step tasks, state a brief plan with a verify step per item.
