---
paths: .claude/specs/**/*
---

# Artifact Format Rules

## Research Reports

**Location**: `.claude/specs/{N}_{SLUG}/reports/research-{NNN}.md`

```markdown
# Research Report: Task #{N}

**Task**: {title}
**Date**: {ISO_DATE}
**Focus**: {optional focus}

## Summary

{2-3 sentence overview}

## Findings

### {Topic}

{Details with evidence}

## Recommendations

1. {Actionable recommendation}

## References

- {Source with link if applicable}

## Next Steps

{What to do next}
```

## Implementation Plans

**Location**: `.claude/specs/{N}_{SLUG}/plans/implementation-{NNN}.md`

```markdown
# Implementation Plan: Task #{N}

**Task**: {title}
**Version**: {NNN}
**Created**: {ISO_DATE}
**Language**: {language}

## Overview

{Approach summary}

## Phases

### Phase 1: {Name}

**Estimated effort**: {hours}
**Status**: [NOT STARTED]

**Objectives**:
1. {Objective}

**Files to modify**:
- `path/to/file` - {changes}

**Steps**:
1. {Step}

**Verification**:
- {How to verify}

---

## Dependencies

- {Dependency}

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|

## Success Criteria

- [ ] {Criterion}
```

## Implementation Summaries

**Location**: `.claude/specs/{N}_{SLUG}/summaries/implementation-summary-{DATE}.md`

```markdown
# Implementation Summary: Task #{N}

**Completed**: {ISO_DATE}
**Duration**: {time}

## Changes Made

{Overview}

## Files Modified

- `path/to/file` - {change}

## Verification

- {What was verified}

## Notes

{Additional notes}
```

## Phase Status Markers

Use in plan files:
- `[NOT STARTED]` - Phase not begun
- `[IN PROGRESS]` - Currently executing
- `[COMPLETED]` - Phase finished
- `[PARTIAL]` - Partially complete (interrupted)
- `[BLOCKED]` - Cannot proceed

## Versioning

### Research Reports
Increment: research-001.md, research-002.md
- Multiple reports for same task allowed
- Later reports supplement earlier ones

### Plans
Increment: implementation-001.md, implementation-002.md
- New version = revised approach
- Previous versions preserved for history

### Summaries
Date-based: implementation-summary-20260109.md
- One per completion
- Includes all phases
