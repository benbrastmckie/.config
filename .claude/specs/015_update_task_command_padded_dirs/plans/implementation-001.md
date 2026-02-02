# Implementation Plan: Task #15

**Task**: Update /task command to create directories with 3-digit padded numbers
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Update the `/task` command to create task directories with 3-digit zero-padded numbers (e.g., `014_task_name` instead of `14_task_name`). This is the core implementation that affects directory creation.

## Phases

### Phase 1: Update task.md command - Create Mode

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Add padding logic for directory creation
2. Update output to show padded path
3. Keep task number unpadded in TODO.md and state.json

**Files to modify**:
- `.claude/commands/task.md` - Update Create Task Mode section

**Steps**:
1. In Step 5 "Create task directory", change from:
   ```
   mkdir -p .claude/specs/{NUMBER}_{SLUG}
   ```
   To:
   ```
   # Pad task number to 3 digits for directory name
   PADDED_NUM=$(printf "%03d" {NUMBER})
   mkdir -p .claude/specs/${PADDED_NUM}_{SLUG}
   ```

2. Update Step 9 "Output" to show padded path:
   ```
   Path: .claude/specs/{NNN}_{SLUG}/
   ```

3. Add comment clarifying: "Directory names use 3-digit padding; TODO.md and state.json use unpadded numbers"

**Verification**:
- New task directories created with 3-digit padding
- TODO.md shows unpadded task number in heading
- state.json uses unpadded project_number

---

### Phase 2: Update task.md command - Recover Mode

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update directory move operations to handle both padded and unpadded source directories
2. Ensure recovered directories use padded format

**Files to modify**:
- `.claude/commands/task.md` - Update Recover Mode section

**Steps**:
1. Update directory recovery logic to:
   - Check for both padded and unpadded source directories
   - Always create target with padded format
   ```bash
   PADDED_NUM=$(printf "%03d" "$task_number")
   # Check both formats (legacy unpadded and new padded)
   if [ -d ".claude/specs/archive/${task_number}_${slug}" ]; then
     mv ".claude/specs/archive/${task_number}_${slug}" ".claude/specs/${PADDED_NUM}_${slug}"
   elif [ -d ".claude/specs/archive/${PADDED_NUM}_${slug}" ]; then
     mv ".claude/specs/archive/${PADDED_NUM}_${slug}" ".claude/specs/${PADDED_NUM}_${slug}"
   fi
   ```

**Verification**:
- Recovered tasks get padded directory names
- Both legacy unpadded and new padded archive directories handled

---

### Phase 3: Update task.md command - Abandon Mode

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update directory archival to handle both formats
2. Archive with consistent (padded) naming

**Files to modify**:
- `.claude/commands/task.md` - Update Abandon Mode section

**Steps**:
1. Update directory archival logic:
   ```bash
   PADDED_NUM=$(printf "%03d" "$task_number")
   # Check both formats
   if [ -d ".claude/specs/${task_number}_${slug}" ]; then
     mv ".claude/specs/${task_number}_${slug}" ".claude/specs/archive/${PADDED_NUM}_${slug}"
   elif [ -d ".claude/specs/${PADDED_NUM}_${slug}" ]; then
     mv ".claude/specs/${PADDED_NUM}_${slug}" ".claude/specs/archive/${PADDED_NUM}_${slug}"
   fi
   ```

**Verification**:
- Abandoned tasks archived with padded directory names
- Both legacy and new format source directories handled

---

## Dependencies

- Task #14 (rules update) should be completed first to establish the standard

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing unpadded directories | High | Handle both formats in recover/abandon |
| Printf not available | Low | Standard bash built-in, universally available |

## Success Criteria

- [ ] New tasks create directories with 3-digit padding (e.g., `014_slug`)
- [ ] Recover mode handles both padded and unpadded archives
- [ ] Abandon mode creates padded archive directories
- [ ] TODO.md task headings remain unpadded (e.g., `### 14. Title`)
- [ ] state.json project_number remains unpadded integer
