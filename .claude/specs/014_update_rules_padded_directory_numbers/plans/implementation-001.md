# Implementation Plan: Task #14

**Task**: Update rules to define 3-digit padded directory numbering standard
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update `artifact-formats.md` and `state-management.md` rules to define the standard for 3-digit zero-padded directory names (`{NNN}_{SLUG}`) while keeping task numbers unpadded in TODO.md, state.json, and commit messages.

## Phases

### Phase 1: Update artifact-formats.md

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Add `{NNN}` placeholder definition for directory names
2. Update all directory path patterns from `{N}_{SLUG}` to `{NNN}_{SLUG}`
3. Keep `{N}` for text references (commit messages, TODO entries)

**Files to modify**:
- `.claude/rules/artifact-formats.md` - Update placeholder conventions table and all path patterns

**Steps**:
1. Add row to Placeholder Conventions table: `{NNN}` for directory numbers (3-digit padded)
2. Clarify `{N}` is for text/numeric contexts, `{NNN}` is for directory names
3. Update Research Reports location: `specs/{NNN}_{SLUG}/reports/research-{NNN}.md`
4. Update Implementation Plans location: `specs/{NNN}_{SLUG}/plans/implementation-{NNN}.md`
5. Update Implementation Summaries location: `specs/{NNN}_{SLUG}/summaries/implementation-summary-{DATE}.md`
6. Update Error Reports location: `specs/{NNN}_{SLUG}/reports/error-report-{DATE}.md`

**Verification**:
- All directory paths use `{NNN}_{SLUG}` pattern
- Placeholder table clearly distinguishes directory vs text usage

---

### Phase 2: Update state-management.md

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update directory creation pattern to use 3-digit padding
2. Update artifact linking examples

**Files to modify**:
- `.claude/rules/state-management.md` - Update directory creation and artifact linking sections

**Steps**:
1. Update "Directory Creation" section pattern to `{NNN}_{SLUG}`
2. Add note about padding: "Directory numbers are 3-digit zero-padded (e.g., `014_task_name`)"
3. Update all artifact linking examples to use padded paths
4. Ensure state.json examples still use unpadded `project_number`

**Verification**:
- Directory creation shows padded format
- Artifact links use padded directory names
- state.json structure unchanged (unpadded project_number)

---

## Dependencies

None - this is the foundational standards update.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Inconsistent terminology | Medium | Clear distinction between `{N}` (text) and `{NNN}` (directory) |

## Success Criteria

- [ ] artifact-formats.md defines `{NNN}` placeholder for directories
- [ ] state-management.md shows padded directory creation
- [ ] All example paths in both files use `{NNN}_{SLUG}` for directories
- [ ] `{N}` remains unpadded for TODO.md entries and state.json values
