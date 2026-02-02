# Implementation Plan: Task #19

**Task**: Update documentation to reflect padded directory paths
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update CLAUDE.md, ARCHITECTURE.md, user guides, templates, and context files to document the 3-digit padded directory naming convention.

## Phases

### Phase 1: Update CLAUDE.md files

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update nvim/.claude/CLAUDE.md artifact paths section
2. Update root .claude/CLAUDE.md if applicable

**Files to modify**:
- `.claude/CLAUDE.md`
- Root-level CLAUDE.md (if it references specs paths)

**Steps**:
1. Update "Task Artifact Paths" section:
   ```
   .claude/specs/{NNN}_{SLUG}/
   ├── reports/
   │   └── research-{NNN}.md
   ├── plans/
   │   └── implementation-{NNN}.md
   └── summaries/
       └── implementation-summary-{DATE}.md
   ```
2. Add note: "`{NNN}` = 3-digit zero-padded task number (e.g., `014`)"
3. Update any example paths in the document

**Verification**:
- Artifact paths section shows padded format
- Clear explanation of padding convention

---

### Phase 2: Update ARCHITECTURE.md

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update any directory structure diagrams
2. Update path examples

**Files to modify**:
- `.claude/ARCHITECTURE.md`

**Steps**:
1. Search for specs directory references
2. Update to padded format
3. Update any diagrams showing directory structure

**Verification**:
- Architecture diagrams show padded directories

---

### Phase 3: Update user guide

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update command examples with correct paths
2. Update troubleshooting section

**Files to modify**:
- `.claude/docs/guides/user-guide.md`

**Steps**:
1. Update all `specs/{N}_{SLUG}` references to `specs/{NNN}_{SLUG}`
2. Update troubleshooting examples
3. Add note about directory naming convention

**Verification**:
- User guide shows correct padded paths

---

### Phase 4: Update templates

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update command-template.md
2. Update skill-template.md
3. Update any other documentation templates

**Files to modify**:
- `.claude/docs/templates/command-template.md`
- `.claude/docs/templates/skill-template.md`

**Steps**:
1. Update example artifact locations to use padded format
2. Update path pattern documentation
3. Add padding instructions to templates

**Verification**:
- Templates show padded path patterns

---

### Phase 5: Update context files

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update context files that reference specs paths

**Files to modify**:
- `.claude/context/core/formats/subagent-return.md`
- `.claude/context/core/formats/return-metadata-file.md`
- `.claude/context/core/patterns/early-metadata-pattern.md`
- Other context files with path references

**Steps**:
1. Grep for `specs/` references in context files
2. Update directory patterns to padded format
3. Update example JSON and paths

**Verification**:
- All context files use padded directory format

---

## Dependencies

- Task #14 (rules update) - establishes the standard

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Missing documentation files | Low | Comprehensive grep search |
| Outdated cross-references | Medium | Verify links after updates |

## Success Criteria

- [ ] CLAUDE.md shows padded artifact paths
- [ ] User guide examples use padded format
- [ ] Templates include padding instructions
- [ ] Context files use consistent path format
- [ ] Clear documentation of `{NNN}` convention
