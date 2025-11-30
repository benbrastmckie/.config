# Cleanup Completed Projects Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Archive 94 cleanup-eligible spec directories to timestamped archive
- **Scope**: Safe archival of completed, abandoned, and superseded projects from specs/ directory
- **Estimated Phases**: 4
- **Estimated Hours**: 2
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 38.0

## Overview

The .claude/specs/ directory contains 94 cleanup-eligible topic directories that have reached terminal states (Completed: 93, Abandoned: 1). This plan implements a safe, reversible archival process that:

1. **Preserves all data** - Uses archival (not deletion) for full recovery capability
2. **Maintains git safety** - Checks for uncommitted changes before moving directories
3. **Provides audit trail** - Creates manifest with timestamps and git references
4. **Enables recovery** - Archives can be restored if needed

**Input Source**: `/home/benjamin/.config/.claude/tmp/cleanup_eligible_todo_1764468799.json` (94 projects)

**Archive Destination**: `/home/benjamin/.config/.claude/archive/cleaned_20251129/`

## Success Criteria

- [ ] All 94 eligible directories archived (or logged if skipped)
- [ ] Archive manifest created with complete directory listing
- [ ] Git commit hash recorded for reference point
- [ ] No directories with uncommitted changes were moved
- [ ] Archive directory structure matches original specs/ structure
- [ ] Recovery instructions documented in manifest
- [ ] TODO.md remains unchanged (no modifications)

## Technical Design

### Archive Strategy

**Safe Archival Pattern**:
```bash
# For each eligible directory:
1. Check git status (skip if uncommitted changes)
2. Move directory to archive/ (preserves structure)
3. Record in manifest (timestamp, git hash, status)
4. Log any skipped directories
```

**Archive Structure**:
```
.claude/archive/cleaned_20251129/
├── manifest.txt                  # Complete listing with metadata
├── recovery-instructions.md      # How to restore directories
├── 111_standards_enforcement_infrastructure/
├── 122_revise_errors_repair/
├── 790_fix_state_machine_transition_error_build_command/
└── ... (93 more directories)
```

### Recovery Mechanism

If archival needs to be reversed:
```bash
# Full recovery (all directories)
mv .claude/archive/cleaned_20251129/* .claude/specs/

# Selective recovery (single directory)
mv .claude/archive/cleaned_20251129/111_standards_enforcement_infrastructure .claude/specs/
```

## Implementation Phases

### Phase 1: Pre-Cleanup Verification [NOT STARTED]
dependencies: []

**Objective**: Validate environment state before making any changes

**Complexity**: Low

Tasks:
- [ ] Load cleanup-eligible projects from JSON file at `/home/benjamin/.config/.claude/tmp/cleanup_eligible_todo_1764468799.json`
- [ ] Verify all 94 directory paths exist (warn if any missing)
- [ ] Check git status for entire specs/ directory
- [ ] Identify any directories with uncommitted changes (will be skipped)
- [ ] Verify archive destination `/home/benjamin/.config/.claude/archive/cleaned_20251129/` does not exist
- [ ] Count total size of directories to be archived (informational)
- [ ] Display pre-flight summary (total dirs, uncommitted count, archive size)

Testing:
```bash
# Validation checks
test -f /home/benjamin/.config/.claude/tmp/cleanup_eligible_todo_1764468799.json
test ! -d /home/benjamin/.config/.claude/archive/cleaned_20251129

# Git status check
cd /home/benjamin/.config
git status --porcelain .claude/specs/ | grep -E "^(M| M)" | wc -l
```

**Expected Duration**: 15 minutes

**Expected Output**:
- Validation report showing ready state
- List of any directories with uncommitted changes
- Archive size estimate

---

### Phase 2: Archive Setup [NOT STARTED]
dependencies: [1]

**Objective**: Create archive infrastructure and initial manifest

**Complexity**: Low

Tasks:
- [ ] Create timestamped archive directory at `/home/benjamin/.config/.claude/archive/cleaned_20251129/`
- [ ] Record git commit hash for reference (use `git rev-parse HEAD`)
- [ ] Create manifest header with metadata (date, git hash, source location)
- [ ] Initialize manifest file at archive root
- [ ] Create recovery instructions document with restore examples
- [ ] Log archive creation event with timestamp

Manifest Header Format:
```
=================================================================
ARCHIVE MANIFEST: Cleanup Eligible Projects (2025-11-29)
=================================================================

Archive Date: 2025-11-29 [timestamp]
Git Reference: [commit hash]
Source Location: /home/benjamin/.config/.claude/specs/
Archive Location: /home/benjamin/.config/.claude/archive/cleaned_20251129/
Total Directories: 94
Status: Archival In Progress

=================================================================
ARCHIVED DIRECTORIES
=================================================================

[Directory listings will be added in Phase 3]
```

Testing:
```bash
# Verify archive structure created
test -d /home/benjamin/.config/.claude/archive/cleaned_20251129
test -f /home/benjamin/.config/.claude/archive/cleaned_20251129/manifest.txt
test -f /home/benjamin/.config/.claude/archive/cleaned_20251129/recovery-instructions.md

# Verify manifest contains git hash
grep -q "Git Reference:" /home/benjamin/.config/.claude/archive/cleaned_20251129/manifest.txt
```

**Expected Duration**: 15 minutes

**Expected Output**:
- Archive directory created
- Manifest file initialized with header
- Recovery instructions documented

---

### Phase 3: Directory Archival [NOT STARTED]
dependencies: [2]

**Objective**: Move all eligible directories to archive with safety checks

**Complexity**: Medium

Tasks:
- [ ] Iterate through 94 cleanup-eligible projects from JSON file
- [ ] For each directory: check git status before moving
- [ ] Skip directories with uncommitted changes (log to skipped list)
- [ ] Move clean directories to archive using `mv` command
- [ ] Record each successful move in manifest (name, status, timestamp)
- [ ] Log any errors or failures during archival
- [ ] Maintain running count (archived vs skipped)
- [ ] Verify each directory exists in archive after move
- [ ] Create summary report (total archived, total skipped, errors)

Archival Safety Pattern:
```bash
for dir in "${ELIGIBLE_DIRS[@]}"; do
  topic_name=$(basename "$dir")

  # Safety check: git status
  if git status --porcelain "$dir" | grep -qE "^(M| M)"; then
    echo "SKIPPED: $topic_name (uncommitted changes)" >> skipped.log
    ((skipped_count++))
    continue
  fi

  # Move to archive
  if mv "$dir" "$ARCHIVE_DIR/$topic_name"; then
    echo "✓ ARCHIVED: $topic_name [$(date +%Y-%m-%d_%H:%M:%S)]" >> manifest.txt
    ((archived_count++))
  else
    echo "✗ FAILED: $topic_name" >> errors.log
    ((error_count++))
  fi
done
```

Manifest Entry Format:
```
✓ ARCHIVED: 111_standards_enforcement_infrastructure [2025-11-29_18:30:15] [Completed]
✓ ARCHIVED: 122_revise_errors_repair [2025-11-29_18:30:16] [Completed]
✓ ARCHIVED: 790_fix_state_machine_transition_error_build_command [2025-11-29_18:30:17] [Completed]
...
```

Testing:
```bash
# Verify archival counts match
EXPECTED_COUNT=94
ARCHIVED_COUNT=$(grep -c "✓ ARCHIVED:" /home/benjamin/.config/.claude/archive/cleaned_20251129/manifest.txt)
SKIPPED_COUNT=$(wc -l < /home/benjamin/.config/.claude/archive/cleaned_20251129/skipped.log 2>/dev/null || echo 0)
TOTAL=$((ARCHIVED_COUNT + SKIPPED_COUNT))

test "$TOTAL" -eq "$EXPECTED_COUNT"

# Verify no uncommitted changes moved
cd /home/benjamin/.config/.claude/archive/cleaned_20251129
for dir in */; do
  cd "/home/benjamin/.config"
  git status --porcelain ".claude/archive/cleaned_20251129/$dir" | grep -qE "^(M| M)" && echo "WARNING: Uncommitted changes in archived dir: $dir"
done
```

**Expected Duration**: 45 minutes

**Expected Output**:
- 94 directories archived (or logged as skipped)
- Manifest updated with all archived directories
- Skipped directories logged with reasons
- Summary report (archived count, skipped count, errors)

---

### Phase 4: Post-Cleanup Verification [NOT STARTED]
dependencies: [3]

**Objective**: Verify archival success and provide completion report

**Complexity**: Low

Tasks:
- [ ] Count total directories in archive (should match archived_count from Phase 3)
- [ ] Verify each archived directory exists in archive location
- [ ] Check specs/ directory for any remaining eligible directories (should be 0 or only skipped ones)
- [ ] Update manifest footer with completion metadata
- [ ] Generate final summary report (total archived, total skipped, total errors)
- [ ] Log archive completion event with stats
- [ ] Display recovery instructions reminder
- [ ] Verify TODO.md was not modified during archival

Manifest Footer Format:
```
=================================================================
ARCHIVAL SUMMARY
=================================================================

Total Eligible:     94
Successfully Archived: [archived_count]
Skipped (uncommitted): [skipped_count]
Errors:             [error_count]

Completion Date: 2025-11-29 [timestamp]
Status: Complete

Recovery: See recovery-instructions.md for restore procedures
```

Final Summary Report Format:
```
╔══════════════════════════════════════════════════════════════╗
║           CLEANUP ARCHIVAL COMPLETE                          ║
╚══════════════════════════════════════════════════════════════╝

Archive Location: /home/benjamin/.config/.claude/archive/cleaned_20251129/

Results:
  ✓ Archived:  93 directories
  ⊘ Skipped:    1 directory (uncommitted changes)
  ✗ Errors:     0

Git Reference: [commit hash]

Recovery: All archived directories can be restored using:
  mv .claude/archive/cleaned_20251129/[DIR_NAME] .claude/specs/

Manifest: See archive/cleaned_20251129/manifest.txt for complete listing
```

Testing:
```bash
# Verify archive completeness
EXPECTED_ARCHIVED=94  # Adjust based on skipped count
ACTUAL_ARCHIVED=$(ls -1d /home/benjamin/.config/.claude/archive/cleaned_20251129/*/ 2>/dev/null | wc -l)
test "$ACTUAL_ARCHIVED" -le "$EXPECTED_ARCHIVED"

# Verify specs/ cleanup (only skipped dirs should remain)
REMAINING_ELIGIBLE=$(cd /home/benjamin/.config/.claude/specs && ls -1d */ 2>/dev/null | wc -l)
echo "Remaining directories in specs/: $REMAINING_ELIGIBLE"

# Verify TODO.md unchanged
git diff /home/benjamin/.config/.claude/TODO.md | grep -q . && echo "WARNING: TODO.md was modified" || echo "✓ TODO.md unchanged"

# Verify manifest footer present
grep -q "ARCHIVAL SUMMARY" /home/benjamin/.config/.claude/archive/cleaned_20251129/manifest.txt
```

**Expected Duration**: 15 minutes

**Expected Output**:
- Verification report showing all directories archived
- Final summary with counts (archived/skipped/errors)
- Recovery instructions displayed
- Manifest complete with footer

---

## Testing Strategy

### Pre-Archival Testing
- Validate JSON input file structure
- Verify git status detection works correctly
- Test archive directory creation (dry-run mode)

### During Archival Testing
- Verify each move operation succeeds
- Check manifest updates after each directory
- Monitor for uncommitted changes detection

### Post-Archival Testing
- Verify all archived directories accessible
- Test recovery procedure (restore 1 dir as proof)
- Validate manifest completeness

### Safety Testing
- Confirm uncommitted changes detected and skipped
- Verify no data loss (all dirs in archive or specs/)
- Test rollback scenario (full archive restoration)

## Documentation Requirements

### Manifest Documentation
- Complete listing of all archived directories
- Git commit hash for reference
- Timestamp for each directory move
- Recovery instructions with examples

### Recovery Instructions
Create `/home/benjamin/.config/.claude/archive/cleaned_20251129/recovery-instructions.md`:
```markdown
# Recovery Instructions

## Full Recovery (All Directories)
```bash
cd /home/benjamin/.config
mv .claude/archive/cleaned_20251129/* .claude/specs/
```

## Selective Recovery (Single Directory)
```bash
cd /home/benjamin/.config
mv .claude/archive/cleaned_20251129/[DIR_NAME] .claude/specs/
```

## Verify Recovery
```bash
ls .claude/specs/[DIR_NAME]
git status .claude/specs/[DIR_NAME]
```

## Archive Metadata
- Archive Date: 2025-11-29
- Git Reference: [commit hash]
- Total Archived: 94 directories
```

## Dependencies

### External Dependencies
- `git` - For status checks and commit hash
- `jq` - For parsing JSON input file
- Standard bash utilities (`mv`, `grep`, `wc`)

### Internal Dependencies
- Cleanup-eligible JSON file must exist before Phase 1
- specs/ directory must be accessible
- Git repository must be initialized

### Constraints
- Must preserve TODO.md (no modifications)
- Must skip directories with uncommitted changes
- Must use archive (not delete) for safety
- Must create audit trail (manifest)

## Rollback Procedures

### Phase 1 Rollback
No changes made - no rollback needed

### Phase 2 Rollback
Remove empty archive directory:
```bash
rm -rf /home/benjamin/.config/.claude/archive/cleaned_20251129
```

### Phase 3 Rollback
Restore all archived directories:
```bash
cd /home/benjamin/.config
mv .claude/archive/cleaned_20251129/* .claude/specs/
rm -rf .claude/archive/cleaned_20251129
```

### Phase 4 Rollback
Same as Phase 3 - full restoration

## Safety Guarantees

1. **No Data Loss**: All directories moved to archive (not deleted)
2. **Git Safety**: Uncommitted changes never moved
3. **Audit Trail**: Complete manifest with timestamps
4. **Reversibility**: Full recovery capability maintained
5. **TODO.md Preservation**: No modifications to TODO.md file
6. **Selective Recovery**: Can restore individual directories

## Notes

- Archive uses timestamped directory name for uniqueness
- Manifest provides complete audit trail
- Recovery is simple directory move operation
- Git history preserved in archive location
- This plan does NOT modify TODO.md (that's a separate cleanup task)
