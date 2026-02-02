# Implementation Plan: Task #27

**Task**: Migrate specs data from .claude/specs/ to specs/ at project root
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Move the task management data from `nvim/.claude/specs/` to `nvim/specs/` (project root). This completes the structural fix after Task #26 updates all path references.

## Phases

### Phase 1: Backup current state

**Estimated effort**: 5 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Create backup of both specs directories before migration

**Steps**:
1. Create timestamped backup:
   ```bash
   cp -r .claude/specs .claude/specs.backup.$(date +%Y%m%d)
   cp -r specs specs.backup.$(date +%Y%m%d)
   ```
2. Verify backups exist

**Verification**:
- Backup directories exist with all content

---

### Phase 2: Analyze current state of both directories

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. List contents of both specs directories
2. Identify overlapping task numbers
3. Determine merge strategy

**Steps**:
1. List .claude/specs/ task directories:
   ```bash
   ls -d .claude/specs/[0-9]*/ 2>/dev/null | sort -V
   ```
2. List specs/ task directories:
   ```bash
   ls -d specs/[0-9]*/ 2>/dev/null | sort -V
   ```
3. Compare TODO.md and state.json from both
4. Document differences

**Verification**:
- Clear understanding of what exists in each location

---

### Phase 3: Migrate core state files

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Merge or replace TODO.md
2. Merge or replace state.json
3. Ensure next_project_number is correct

**Steps**:
1. Determine which state is more current (check last_updated, git blame)
2. If .claude/specs/ is more current:
   ```bash
   cp .claude/specs/TODO.md specs/TODO.md
   cp .claude/specs/state.json specs/state.json
   ```
3. If specs/ is more current, keep existing but merge any new tasks
4. Update next_project_number to be max of both + 1
5. Update all artifact paths in state.json from `.claude/specs/` to `specs/`

**Verification**:
- specs/TODO.md exists and is valid
- specs/state.json exists and has correct paths
- next_project_number accounts for all tasks

---

### Phase 4: Migrate task directories

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Move task directories from .claude/specs/ to specs/
2. Handle any conflicts with existing directories

**Steps**:
1. For each task directory in .claude/specs/:
   ```bash
   for dir in .claude/specs/[0-9]*/; do
     basename=$(basename "$dir")
     if [ -d "specs/$basename" ]; then
       echo "CONFLICT: specs/$basename already exists"
       # Manual merge required
     else
       mv "$dir" "specs/$basename"
     fi
   done
   ```
2. Handle conflicts by comparing content and keeping more complete version
3. Move archive directory:
   ```bash
   if [ -d ".claude/specs/archive" ] && [ ! -d "specs/archive" ]; then
     mv .claude/specs/archive specs/archive
   fi
   ```

**Verification**:
- All task directories moved to specs/
- No data loss

---

### Phase 5: Update artifact paths in migrated files

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update internal path references in migrated task artifacts

**Steps**:
1. Update paths in all plan files:
   ```bash
   find specs/*/plans -name "*.md" -exec sed -i 's|\.claude/specs/|specs/|g' {} \;
   ```
2. Update paths in all summary files:
   ```bash
   find specs/*/summaries -name "*.md" -exec sed -i 's|\.claude/specs/|specs/|g' {} \;
   ```
3. Update paths in research reports if any reference specs paths

**Verification**:
- `grep -r "\.claude/specs/" specs/*/` returns nothing

---

### Phase 6: Remove old .claude/specs directory

**Estimated effort**: 5 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Remove the now-empty .claude/specs/ directory
2. Keep backup for safety period

**Steps**:
1. Verify .claude/specs/ is empty or only contains migrated content:
   ```bash
   ls .claude/specs/
   ```
2. Remove if safe:
   ```bash
   rm -rf .claude/specs/
   ```
3. Keep backup for 1 week, then delete

**Verification**:
- .claude/specs/ no longer exists
- All data accessible from specs/

---

### Phase 7: Verify and test

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Verify all paths work correctly
2. Test commands reference correct location

**Steps**:
1. Run `jq '.active_projects[0]' specs/state.json` - should work
2. Check TODO.md links resolve
3. Try `/task --sync` to verify system works
4. Check git status for any issues

**Verification**:
- Commands can read/write specs/
- No broken paths
- Git shows clean state (after commit)

---

## Dependencies

- Task #26 must be completed first (path references updated)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss | Critical | Full backup before migration |
| Task number conflicts | High | Careful analysis and manual merge |
| Broken links | Medium | sed update of internal paths |

## Success Criteria

- [ ] specs/ at project root contains all task data
- [ ] .claude/specs/ removed (backup retained temporarily)
- [ ] All commands work with new location
- [ ] No broken artifact links
- [ ] Git commit with migration complete
