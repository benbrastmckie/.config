# Implementation Plan: Task #28

**Task**: Reconcile duplicate specs data between nvim/specs/ and nvim/.claude/specs/
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

The nvim/ directory currently has two specs directories with different task data:
- `nvim/specs/` - Contains tasks 1, 18-25 (recent work)
- `nvim/.claude/specs/` - Contains tasks 1-13, 14-20 (from cloned .claude/ system)

This task reconciles the data to create a single authoritative source.

## Current State Analysis

### nvim/specs/ (Project Root)
- Tasks: 001, 018, 19, 20, 21, 22, 23, 24, 25
- state.json: next_project_number = 26
- Active work happened here recently

### nvim/.claude/specs/ (Nested)
- Tasks: 001-009, 10-13, 014-020
- state.json: next_project_number = 21
- Contains earlier work + tasks 14-20 just created

### Conflicts
- Task 018/18: Different content possible
- Tasks 19-20: May have different versions in each location

## Phases

### Phase 1: Export complete task inventory

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Create complete inventory of all tasks in both locations
2. Identify overlaps and conflicts

**Files to create**:
- `specs/migration-inventory.md` (temporary)

**Steps**:
1. List all tasks from nvim/specs/:
   ```bash
   ls -d specs/[0-9]*/ | while read dir; do
     num=$(basename "$dir" | grep -oE '^[0-9]+')
     echo "specs: $num - $(basename "$dir")"
   done
   ```

2. List all tasks from nvim/.claude/specs/:
   ```bash
   ls -d .claude/specs/[0-9]*/ | while read dir; do
     num=$(basename "$dir" | grep -oE '^[0-9]+')
     echo ".claude/specs: $num - $(basename "$dir")"
   done
   ```

3. Create inventory document comparing both

**Verification**:
- Complete inventory created

---

### Phase 2: Determine authoritative source for each task

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. For each task, determine which location has authoritative data
2. Document merge decisions

**Decision criteria**:
- Most recent modification date wins
- More complete artifacts win
- If equal, prefer specs/ (project root)

**Steps**:
1. For tasks that exist in both locations:
   - Compare modification times
   - Compare artifact completeness
   - Document decision

2. For tasks only in one location:
   - Mark for direct copy

**Verification**:
- Clear decision for every task

---

### Phase 3: Merge state.json files

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Create merged state.json with all tasks
2. Set correct next_project_number

**Steps**:
1. Read both state.json files
2. Merge active_projects arrays:
   - Include all unique tasks
   - For duplicates, use authoritative version
3. Set next_project_number = max(task_numbers) + 1
4. Update all artifact paths to use `specs/` (not `.claude/specs/`)
5. Write merged state.json to specs/

**Verification**:
- All tasks represented in merged state
- Paths use `specs/` format
- next_project_number is correct

---

### Phase 4: Merge TODO.md files

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Create merged TODO.md with all tasks

**Steps**:
1. Read both TODO.md files
2. Extract task entries from each
3. Merge entries:
   - Include all unique tasks
   - For duplicates, use authoritative version
4. Update artifact links to use `specs/` paths
5. Write merged TODO.md to specs/

**Verification**:
- All tasks represented
- Links use correct paths

---

### Phase 5: Copy unique task directories

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Copy task directories that only exist in .claude/specs/

**Steps**:
1. For each task in .claude/specs/ not in specs/:
   ```bash
   for dir in .claude/specs/[0-9]*/; do
     basename=$(basename "$dir")
     if [ ! -d "specs/$basename" ]; then
       cp -r "$dir" "specs/$basename"
     fi
   done
   ```

2. Update internal paths in copied files:
   ```bash
   find specs/*/plans -name "*.md" -exec sed -i 's|\.claude/specs/|specs/|g' {} \;
   ```

**Verification**:
- All unique tasks copied
- Paths updated

---

### Phase 6: Handle conflicting task directories

**Estimated effort**: 20 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Manually review and merge conflicting task directories

**Steps**:
1. For each conflict identified in Phase 2:
   - Compare directory contents
   - Keep more complete/recent version
   - Archive the other in a conflicts/ directory

2. Document any data that was overwritten

**Verification**:
- All conflicts resolved
- No data loss (archived)

---

### Phase 7: Cleanup and verification

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Remove .claude/specs/ after successful merge
2. Verify all data accessible

**Steps**:
1. Run verification commands:
   ```bash
   jq '.active_projects | length' specs/state.json
   grep -c "^### [0-9]" specs/TODO.md
   ls specs/[0-9]*/ | wc -l
   ```

2. If counts match expected:
   ```bash
   rm -rf .claude/specs/
   ```

3. Commit changes:
   ```bash
   git add specs/
   git add .claude/  # Remove deleted specs
   git commit -m "meta: reconcile specs data, migrate to project root"
   ```

**Verification**:
- specs/ contains all task data
- .claude/specs/ removed
- Git history clean

---

## Dependencies

- Task #26 (path references update) should be done first or concurrently
- Task #27 (migration) incorporated into this plan

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss during merge | Critical | Keep backups of both directories |
| Conflicting task numbers | High | Manual review and merge |
| Broken references | Medium | sed-based path update |

## Success Criteria

- [ ] Single specs/ directory at project root
- [ ] All tasks from both locations preserved
- [ ] state.json has all tasks with correct paths
- [ ] TODO.md has all tasks with correct links
- [ ] .claude/specs/ removed
- [ ] Git commit with clean history
