# Documentation Rules

Use when creating a document, changing its structure, or writing an engineering
record. Not for small edits within an existing document.

## Documents
- One authoritative location per fact; link instead of restating.
- State the purpose or decision first. Match the document's existing language.
- Keep the paths, identifiers, versions, preconditions, and expected results
  needed to reproduce a claim. Brevity must not remove evidence.
- Separate requirements, proposals, measured results, and open questions.
- Do not state a number that was not measured, or a quality claim
  ("robust", "optimal") that has no evidence behind it.
- Keep edits within the request. Split only for a distinct audience or
  lifecycle, never to satisfy a line limit.
- Before finishing, check references, contradictions, and duplication.

## Engineering Log
Write to `.agent/ENGINEERING_LOG/{repo}_{YYYY-MM-DD}_LOG.md`, where `{repo}`
is the repository's directory/name. Same date → append to that day's file.
New date → create a new file. AGENTS.md decides when to write.

- Korean, technical identifiers unchanged. Dated heading, at most 12 lines per
  entry, only the applicable fields: Problem; Attempts and evidence; Decision
  and attribution; Validation; Next check.
- Read the relevant entries first. Update the existing incident as evidence
  arrives; keep failed attempts and mark superseded conclusions.
- Record the original assumption, what challenged it, the alternatives actually
  considered, and why the change was chosen. Do not fabricate a journey.
- Attribute a user choice only to an explicit statement. Keep AI suggestions,
  agent implementation choices, observed facts, and interpretations distinct.
- Cite real commands, outputs, paths, or commits. Record unrun checks and
  remaining uncertainty. Never invent a result.
- Exclude credentials, personal data, and raw log or conversation dumps; link
  the evidence instead. Do not stage, commit, or publish automatically.
