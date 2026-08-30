# Multi-Model Discussion Rules

Scope: multi-model review only. Not ordinary coding work.
Be brief everywhere below — in payloads, in reviews, in rebuttals.

## Payload
- Send: `Goal` (one decision), `Constraints`, `Current Design`, `Criteria`,
  `Open Questions`. One or two lines each.
- Send paths. Send an excerpt only when the reviewer cannot read the path.
- Never send: transcripts, raw logs, discarded designs, another reviewer's
  reasoning.
- Truncate logs before they enter a payload.
- Never send a plan or design document inline. Send its path.
- Keep any single payload under 50 lines. If it will not fit, the `Goal` is
  more than one decision — split the discussion instead.

## Reviewer
- One fresh session per reviewer, run in parallel. No reviewer sees another's
  output.
- Read only what the payload names.
- No clarifying questions. State the assumption you used.
- Output the template and nothing else. Max 5 issues, one sentence each,
  300 words total.

```
# Review
## Verdict: ACCEPT | ACCEPT_WITH_CHANGES | REJECT
## Critical Issues (Max 5): 1. ... 2. ...
## Recommended Changes: 1. ...
## Evidence / Rationale: - ...
## Risks If Ignored: - ...
## Confidence: High | Medium | Low
```

## Rounds
- Review (parallel) → disagreement extraction → rebuttal (max 2) → synthesis →
  decision.
- Rebuttal payload: `Claim`, `Evidence`, `Challenge`, `Decision Needed`.
  One line each.
- Stop when a rebuttal adds no new evidence, or when the disagreement needs a
  measurement. Name `Next Validation` and stop.

## Session
*(operator, orchestrator session only — one-shot reviewers exit before this
applies)*

- Same problem, after each synthesis round: compact. Required.
- Synthesis persisted and moving on: discard the session, reseed with the
  artifact path. Required.
- Do not open the next round until one of the two is done.
- Claude Code: `/compact`, `/clear`. Use the equivalent elsewhere.

## Synthesis
- Deliver: `Accepted`, `Rejected`, `Open Disagreements`, `Required Changes`,
  `Validation Needed`.
- Write it to a file and report the path. It is not delivered while it exists
  only in the conversation.
- A resulting plan over 200 lines is split by milestone, one file each. Length
  belongs here, never in a discussion payload.
- Hand off with paths only.

## Golden Rule
- `Problem → Constraint → Capability → Trade-off → Validation`. No technology
  for its own sake.
