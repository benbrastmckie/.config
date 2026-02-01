# Report Artifact Standard

**Scope:** Research, analysis, verification, and review reports produced by /research, /review, /analyze, and related agents.

## Metadata (required)
- **Task**: `{id} - {title}`
- **Started**: `{ISO8601}` when work begins
- **Completed**: `{ISO8601}` when work completes
- **Effort**: `{estimate}`
- **Dependencies**: `{list or None}`
- **Sources/Inputs**: bullet list of inputs consulted
- **Artifacts**: list of produced artifacts (paths)
- **Standards**: status-markers.md, artifact-management.md, tasks.md, this file

**Note**: Status metadata (e.g., `[RESEARCHING]`, `[COMPLETED]`) belongs in TODO.md and state.json only, NOT in research reports. Reports are artifacts that document findings, not workflow state.

## Structure
1. **Project Context (Lean only)** – proof dependency relationships (see below).
2. **Executive Summary** – 4-6 bullets.
3. **Context & Scope** – what is being evaluated, constraints.
4. **Findings** – ordered or bulleted list with evidence; include status markers for subsections if phases are tracked.
5. **Decisions** – explicit decisions made.
6. **Recommendations** – prioritized list with owners/next steps.
7. **Risks & Mitigations** – optional but recommended.
8. **Appendix** – references, data, links.

## Project Context (Lean reports only)

**Applicability**: Include this section only for Lean research reports where understanding proof dependencies is essential. For non-Lean reports (general, meta, latex, typst), this section may be omitted.

**Purpose**: Provides early orientation on how the research topic fits into the Lean codebase by documenting proof dependency relationships.

**Fields**:
- **Upstream Dependencies**: Existing or planned theorems/definitions this result builds upon. Example: "Depends on `Soundness`, `Kripke.eval`, `Formula.subst`"
- **Downstream Dependents**: Existing or planned results that will use this. Example: "Enables `Completeness`, `DecidabilityTheorem`"
- **Alternative Paths**: Where this provides redundancy or different approaches. Example: "Alternative to the algebraic completeness approach in `Theories/Algebraic/`"
- **Potential Extensions**: New directions this enables or suggests. Example: "Could extend to multi-modal logics, temporal operators"

## Timestamps
- Include **Started** timestamp when research/analysis begins
- Include **Completed** timestamp when report is finalized
- Do not use emojis
- Do not include status markers (status tracked in TODO.md and state.json only)

## Writing Guidance
- Be objective, cite sources/paths.
- Keep headings at most level 3 inside the report.
- Prefer bullet lists over prose for findings/recommendations.
- Ensure lazy directory creation: create `reports/` only when writing the first report file.

## Example Skeleton
```
# Research Report: {title}
- **Task**: {id} - {title}
- **Started**: 2025-12-22T10:00:00Z
- **Completed**: 2025-12-22T13:00:00Z
- **Effort**: 3 hours
- **Dependencies**: None
- **Sources/Inputs**: ...
- **Artifacts**: ...
- **Standards**: status-markers.md, artifact-management.md, tasks.md, report.md

## Project Context (Lean only)
- **Upstream Dependencies**: `Soundness`, `Kripke.eval`, `Formula.subst`
- **Downstream Dependents**: `Completeness`, `DecidabilityTheorem`
- **Alternative Paths**: None identified
- **Potential Extensions**: Multi-modal logics, temporal operators

## Executive Summary
- ...

## Context & Scope
...

## Findings
- ...

## Decisions
- ...

## Recommendations
- ...

## Risks & Mitigations
- ...

## Appendix
- References: ...
```
