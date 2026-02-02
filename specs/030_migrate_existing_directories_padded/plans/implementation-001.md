# Implementation Plan: Task #30

**Task**: Migrate existing unpadded directories to padded format
**Version**: 001
**Created**: 2026-02-02
**Language**: meta

## Overview

Create and execute a migration script to rename existing unpadded task directories (e.g., `19_task_name`) to the new padded format (e.g., `019_task_name`).

## Phases

### Phase 1: Create migration script

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Create a bash script to identify and rename unpadded directories
2. Include dry-run mode for safety
3. Handle edge cases (already padded, archives)

**Files to create**:
- `.claude/scripts/migrate-directory-padding.sh`

**Steps**:
1. Create script with the following logic:
   ```bash
   #!/bin/bash
   # Migrate unpadded task directories to 3-digit padded format

   DRY_RUN=false
   SPECS_DIR=".claude/specs"

   if [[ "$1" == "--dry-run" ]]; then
     DRY_RUN=true
     echo "DRY RUN MODE - no changes will be made"
   fi

   # Find directories matching unpadded pattern (1-999 without leading zeros)
   for dir in "$SPECS_DIR"/[0-9]*_*/; do
     if [ -d "$dir" ]; then
       basename=$(basename "$dir")
       # Extract number and slug
       num=$(echo "$basename" | grep -oE '^[0-9]+')
       slug=$(echo "$basename" | sed 's/^[0-9]*_//')

       # Skip if already 3-digit padded
       if [[ ${#num} -eq 3 ]]; then
         continue
       fi

       # Create padded name
       padded_num=$(printf "%03d" "$num")
       new_name="${padded_num}_${slug}"

       echo "Rename: $basename -> $new_name"

       if [ "$DRY_RUN" = false ]; then
         mv "$SPECS_DIR/$basename" "$SPECS_DIR/$new_name"
       fi
     fi
   done
   ```

2. Add archive directory handling
3. Add error handling and logging
4. Make script executable

**Verification**:
- Script runs without errors in dry-run mode
- Correctly identifies unpadded directories

---

### Phase 2: Execute migration on nvim/.claude/specs

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Run migration on nvim/.claude/specs directory
2. Verify all directories renamed correctly

**Steps**:
1. Run dry-run first:
   ```bash
   cd /home/benjamin/.config/nvim
   bash .claude/scripts/migrate-directory-padding.sh --dry-run
   ```

2. Review output for correctness

3. Execute migration:
   ```bash
   bash .claude/scripts/migrate-directory-padding.sh
   ```

4. Verify results:
   ```bash
   ls -d .claude/specs/[0-9]*/
   ```

**Verification**:
- All directories now have 3-digit padding
- No data loss
- Artifacts still accessible

---

### Phase 3: Execute migration on nvim/specs (if applicable)

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Run migration on nvim/specs directory if it exists and is used

**Steps**:
1. Check if nvim/specs has task directories
2. Run dry-run
3. Execute migration if needed

**Verification**:
- nvim/specs directories migrated if applicable

---

### Phase 4: Update TODO.md artifact links

**Estimated effort**: 15 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Update artifact links in TODO.md to use new padded paths

**Files to modify**:
- `.claude/specs/TODO.md`
- `specs/TODO.md` (if applicable)

**Steps**:
1. Search for artifact links with unpadded paths
2. Update to padded format:
   - `[research-001.md](.claude/specs/10_slug/...)`
   - becomes `[research-001.md](.claude/specs/010_slug/...)`
3. Verify all links resolve correctly

**Verification**:
- All artifact links work
- No broken references

---

### Phase 5: Git commit migration

**Estimated effort**: 5 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Commit the directory renames and link updates

**Steps**:
1. Stage all changes:
   ```bash
   git add .claude/specs/ specs/
   ```

2. Commit:
   ```bash
   git commit -m "meta: migrate task directories to 3-digit padded format

   Renamed directories from unpadded (e.g., 10_slug) to padded (e.g., 010_slug)
   format for consistent lexicographic sorting.

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```

**Verification**:
- Clean git status after commit
- History preserved for renamed directories

---

## Dependencies

- Tasks #14-19 should ideally be completed first (but migration can run independently)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss during rename | Critical | Dry-run mode, git backup |
| Broken links | High | Systematic link update phase |
| Archive inconsistency | Medium | Handle archives separately |

## Success Criteria

- [ ] Migration script created and tested
- [ ] All task directories use 3-digit padding
- [ ] All TODO.md links updated
- [ ] No broken artifact references
- [ ] Changes committed to git
- [ ] `ls` shows directories in correct numeric order
