# Implementation Plan: Task #16

**Task**: Update workflow commands to use padded directory paths
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update `/research`, `/plan`, `/implement`, `/revise`, and `/todo` commands to construct and reference task directories using 3-digit padded numbers.

## Phases

### Phase 1: Update research.md command

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update directory path construction to use padded format
2. Update artifact path references

**Files to modify**:
- `.claude/commands/research.md` - Update path patterns

**Steps**:
1. Add padding logic where task number is used for directory:
   ```bash
   PADDED_NUM=$(printf "%03d" "$task_number")
   ```
2. Update directory creation: `mkdir -p .claude/specs/${PADDED_NUM}_{SLUG}/reports/`
3. Update report path: `.claude/specs/${PADDED_NUM}_{SLUG}/reports/research-{NNN}.md`
4. Update all path references in documentation sections

**Verification**:
- Research reports created in padded directories
- Path references use `{NNN}_{SLUG}` pattern

---

### Phase 2: Update plan.md command

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update directory path construction
2. Update plan file path references

**Files to modify**:
- `.claude/commands/plan.md` - Update path patterns

**Steps**:
1. Add padding logic for directory construction
2. Update directory creation: `mkdir -p .claude/specs/${PADDED_NUM}_{SLUG}/plans/`
3. Update plan path: `.claude/specs/${PADDED_NUM}_{SLUG}/plans/implementation-{NNN}.md`
4. Update research report lookups to check both padded and unpadded paths (backward compatibility)

**Verification**:
- Plans created in padded directories
- Research reports found regardless of original directory format

---

### Phase 3: Update implement.md command

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update all directory path references
2. Handle plan file lookup with both formats
3. Update summary creation path

**Files to modify**:
- `.claude/commands/implement.md` - Update path patterns

**Steps**:
1. Add padding logic for directory construction
2. Update plan lookup to check both formats:
   ```bash
   PADDED_NUM=$(printf "%03d" "$task_number")
   # Check padded first, then unpadded for legacy
   plan_dir=".claude/specs/${PADDED_NUM}_${slug}/plans"
   if [ ! -d "$plan_dir" ]; then
     plan_dir=".claude/specs/${task_number}_${slug}/plans"
   fi
   ```
3. Update summary path: `.claude/specs/${PADDED_NUM}_{SLUG}/summaries/`
4. Ensure new artifacts always go to padded directories

**Verification**:
- Implementation works with both legacy and new directories
- New summaries created in padded directories

---

### Phase 4: Update revise.md command

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update plan path references
2. Handle both directory formats

**Files to modify**:
- `.claude/commands/revise.md` - Update path patterns

**Steps**:
1. Add padding logic for directory construction
2. Update plan path lookups to check both formats
3. New plan versions always written to padded directory

**Verification**:
- Revised plans work with legacy directories
- New plan versions use padded paths

---

### Phase 5: Update todo.md command

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update archive directory handling
2. Handle both formats during archival

**Files to modify**:
- `.claude/commands/todo.md` - Update path patterns

**Steps**:
1. Add padding logic for archive operations
2. Update archival to check both formats:
   ```bash
   PADDED_NUM=$(printf "%03d" "$task_number")
   # Find source directory (padded or unpadded)
   if [ -d ".claude/specs/${PADDED_NUM}_${slug}" ]; then
     src_dir=".claude/specs/${PADDED_NUM}_${slug}"
   else
     src_dir=".claude/specs/${task_number}_${slug}"
   fi
   # Always archive to padded format
   mv "$src_dir" ".claude/specs/archive/${PADDED_NUM}_${slug}"
   ```

**Verification**:
- Archival handles both directory formats
- Archived directories use padded naming

---

## Dependencies

- Task #14 (rules update) - establishes the standard
- Task #15 (task.md update) - core directory creation

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing workflows | High | Always check both formats for reads |
| Inconsistent state during migration | Medium | Write to padded, read from both |

## Success Criteria

- [ ] All workflow commands construct padded directory paths
- [ ] Legacy unpadded directories still accessible
- [ ] New artifacts always written to padded directories
- [ ] Archive operations preserve padded naming
