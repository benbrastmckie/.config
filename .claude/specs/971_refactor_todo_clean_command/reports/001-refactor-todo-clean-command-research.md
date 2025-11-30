# Research Report: Refactor /todo --clean Command

## Metadata
- **Date**: 2025-11-29
- **Research Topic**: Refactor /todo --clean to remove completed/abandoned project directories from specs/ based on TODO.md entries without modifying TODO.md, while /todo without flags continues to just revise TODO.md
- **Complexity**: 2
- **Status**: Complete

## Executive Summary

The current `/todo --clean` implementation generates a cleanup **plan** for completed projects older than 30 days, requiring subsequent execution via `/build`. The refactoring goal is to make `--clean` **directly execute** directory removal based on TODO.md status classification, while preserving the default behavior of only updating TODO.md.

**Key Findings**:
1. Current --clean behavior creates a plan via plan-architect agent (lines 618-652 in todo.md)
2. Library already has `filter_completed_projects()` and `generate_cleanup_plan()` functions
3. TODO.md entries map 1:1 to specs/ directories via topic naming convention
4. Completed and Abandoned sections in TODO.md are auto-updated by /todo command
5. No archive directory currently exists in the project
6. Directory removal should target both "completed" and "abandoned" status classifications

## Research Findings

### 1. Current /todo Command Implementation

**File**: `/home/benjamin/.config/.claude/commands/todo.md`

**Command Structure**:
- **Block 1**: Setup and Discovery (lines 58-217)
  - Parses `--clean` and `--dry-run` flags
  - Scans specs/ directories for topic folders (3-digit prefix pattern: `[0-9][0-9][0-9]_*`)
  - Collects plan file paths into JSON array

- **Block 2a-2c**: Status Classification (lines 220-439)
  - Uses hard barrier pattern with todo-analyzer subagent
  - Batch classification of all discovered plans
  - Verification ensures classified results exist before proceeding

- **Block 3-4**: Generate and Write TODO.md (lines 441-616)
  - Generates TODO.md content from classified plans
  - Preserves Backlog section content
  - Applies checkbox conventions and date grouping

- **Clean Mode Section** (lines 618-652)
  - **Current behavior**: Invokes plan-architect agent to generate cleanup plan
  - **Plan structure**: 4 phases (archive creation, directory moves, TODO.md update, verification)
  - **Age threshold**: 30 days (hardcoded)
  - **Safety**: Dry-run by default, archive (don't delete), manifest creation

**Key Code Sections**:
```bash
# Line 68-85: Flag parsing
CLEAN_MODE="false"
DRY_RUN="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --clean)
      CLEAN_MODE="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
```

### 2. Current --clean Behavior Analysis

**What It Currently Does**:
1. Filters completed projects older than 30 days using `filter_completed_projects()`
2. Invokes plan-architect agent to generate a cleanup plan
3. Cleanup plan includes:
   - Phase 1: Create archive directory and manifest
   - Phase 2: Move project directories to archive
   - Phase 3: Update TODO.md (remove archived entries)
   - Phase 4: Verification
4. Plan must be manually executed via `/build <cleanup-plan-path>`

**Issues with Current Approach**:
- **Two-step process**: Requires plan generation + /build execution
- **TODO.md modification**: Phase 3 updates TODO.md (removing entries)
- **Archive complexity**: Creates archive manifest and directory structure
- **Manual intervention**: User must execute the generated plan

### 3. TODO.md Entry to Specs/ Directory Mapping

**Directory Naming Convention**:
```
specs/{NNN_topic_name}/
  plans/
    001-plan-name.md
  reports/
    001-report.md
  summaries/
    001-summary.md
  outputs/
  debug/
```

**Pattern**: `{3-digit-number}_{topic_name}`

**Examples from TODO.md**:
```markdown
- [x] **Fix /repair command spec numbering**
  → .claude/specs/961_repair_spec_numbering_allocation/

- [x] **Error logging infrastructure completion**
  → .claude/specs/902_error_logging_infrastructure_completion/

- [x] **State machine persistence bug fix (787)**
  → .claude/specs/787_state_machine_persistence_bug/
```

**Extraction Pattern**:
- TODO.md entries contain path: `[.claude/specs/{NNN_topic}/plans/*.md]`
- Parent directory is: `{NNN_topic}`
- Full path: `$CLAUDE_PROJECT_DIR/.claude/specs/{NNN_topic}/`

### 4. Status Classification and TODO.md Sections

**From `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md`**:

**Section Definitions**:

| Section | Purpose | Auto-Updated | Checkbox | Target for Removal |
|---------|---------|--------------|----------|-------------------|
| In Progress | Plans currently being implemented | Yes | `[x]` | No |
| Not Started | Plans created but not started | Yes | `[ ]` | No |
| Backlog | Manually curated future ideas | No (preserved) | None or `[ ]` | No |
| Superseded | Replaced by newer plans | Yes | `[~]` | No |
| **Abandoned** | Intentionally stopped | Yes | `[x]` | **Yes** |
| **Completed** | Successfully finished | Yes | `[x]` | **Yes** |

**Status Classification Algorithm** (from todo-analyzer.md, lines 99-128):
```
1. IF Status field contains "[COMPLETE]" OR "100%":
     status = "completed"

2. ELSE IF Status field contains "[IN PROGRESS]":
     status = "in_progress"

3. ELSE IF Status field contains "[NOT STARTED]":
     status = "not_started"

4. ELSE IF Status field contains "SUPERSEDED" OR "DEFERRED":
     status = "superseded"

5. ELSE IF Status field contains "ABANDONED":
     status = "abandoned"

6. ELSE IF Status field is missing:
     # Fallback: Count phase markers
     IF all phases have [COMPLETE]:
       status = "completed"
     ELSE IF any phase has [COMPLETE]:
       status = "in_progress"
     ELSE:
       status = "not_started"
```

**Cleanup Target Sections**:
1. **Completed**: Projects that finished successfully
2. **Abandoned**: Projects intentionally stopped with documented reasons

**Examples from Current TODO.md**:

**Abandoned Entry (Line 43-47)**:
```markdown
- [x] **Error logging infrastructure completion** - Helper functions
  (validate_required_functions, execute_with_logging) deemed unnecessary
  [.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md]
  - **Reason**: Error logging infrastructure already 100% complete across all 12 commands
  - **Alternative**: Focus on Plan 883 (Commands Optimize Refactor)
```
→ Directory: `902_error_logging_infrastructure_completion/`

**Completed Entry (Line 125-127)**:
```markdown
- [x] **Fix /repair command spec numbering** - Implement timestamp-based topic naming
  [.claude/specs/961_repair_spec_numbering_allocation/plans/001-repair-spec-numbering-allocation-plan.md]
  - 4 phases complete: Direct timestamp naming replaces LLM-based naming
```
→ Directory: `961_repair_spec_numbering_allocation/`

### 5. Library Functions for Cleanup

**File**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`

**Relevant Functions**:

#### `filter_completed_projects()` (Lines 717-768)
```bash
# Purpose: Filter completed projects older than specified age threshold
# Arguments:
#   $1 - JSON array of classified plans
#   $2 - Age threshold in days (default: 30)
# Returns: JSON array of completed projects meeting age criteria
```

**Current Implementation**:
- Filters for `status == "completed"` only
- Checks plan file modification time against threshold
- Returns JSON array with matching projects

**Limitation**: Only filters "completed" status, not "abandoned"

#### `generate_cleanup_plan()` (Lines 770-893)
```bash
# Purpose: Generate a cleanup plan for completed projects
# Arguments:
#   $1 - JSON array of completed projects to clean up
#   $2 - Archive destination path
#   $3 - Specs root path
# Returns: Plan content as string
```

**Current Implementation**:
- Creates 4-phase cleanup plan
- Includes archive directory creation
- Moves directories to archive
- Updates TODO.md (removes entries from Completed section)

**Limitation**: Generates plan rather than executing cleanup

### 6. Safe Directory Removal Pattern

**Requirements**:
1. **Validation**: Verify directory exists and is within specs/ root
2. **Backup/Archive**: Move to archive rather than delete
3. **Logging**: Log all removal operations for audit trail
4. **Dry-run support**: Preview without actual removal
5. **Error handling**: Graceful failure with recovery information
6. **TODO.md preservation**: Do NOT modify TODO.md (user's requirement)

**Example Safe Removal Function**:
```bash
remove_project_directory() {
  local topic_path="$1"
  local dry_run="${2:-false}"
  local archive_dir="${3:-}"

  # Validation
  if [ ! -d "$topic_path" ]; then
    echo "WARNING: Directory not found: $topic_path" >&2
    return 1
  fi

  # Ensure within specs/ root
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
  if [[ ! "$topic_path" =~ ^${specs_root}/ ]]; then
    echo "ERROR: Directory outside specs root: $topic_path" >&2
    return 1
  fi

  # Extract topic name
  local topic_name=$(basename "$topic_path")

  if [ "$dry_run" = "true" ]; then
    echo "[DRY RUN] Would remove: $topic_path"
    return 0
  fi

  # Archive if destination provided, otherwise delete
  if [ -n "$archive_dir" ]; then
    mkdir -p "$archive_dir"
    mv "$topic_path" "$archive_dir/"
    echo "Archived: $topic_name → $archive_dir/"
  else
    rm -rf "$topic_path"
    echo "Removed: $topic_name"
  fi

  return 0
}
```

### 7. Proposed Refactored --clean Behavior

**New Behavior**:

When `/todo --clean` is invoked:
1. Scan specs/ directories (same as default mode)
2. Classify plan status (same as default mode)
3. **Filter for "completed" AND "abandoned" status** (not just completed)
4. **Optional**: Apply age threshold (30 days) or remove all
5. **Directly remove directories** from specs/ (move to archive or delete)
6. **DO NOT modify TODO.md** (user requirement)
7. Log all operations to error log
8. Generate summary report of removed directories

**Key Differences from Current Behavior**:

| Aspect | Current (Plan Generation) | Proposed (Direct Removal) |
|--------|--------------------------|---------------------------|
| Action | Generate cleanup plan | Execute directory removal |
| Execution | Requires /build command | Immediate execution |
| TODO.md | Modified (Phase 3) | **NOT modified** |
| Archive | Creates manifest | Simple move to archive/ |
| Target Status | Completed only | Completed + Abandoned |
| Age Threshold | 30 days (hardcoded) | Configurable or all |

**Command Flow**:
```bash
/todo --clean              # Remove all completed/abandoned directories
/todo --clean --dry-run    # Preview what would be removed
```

**Expected Output**:
```
=== /todo --clean Command ===

Mode: Clean
Dry Run: false

Scanning projects...
Found 195 topic directories
Found 195 plan files to analyze

=== Status Classification ===
Classified 195 plans

=== Directory Removal ===
Target status: completed, abandoned
Total candidates: 87 directories

Removing directories:
  ✓ Removed: 961_repair_spec_numbering_allocation
  ✓ Removed: 962_fix_failing_tests_compliance
  ✓ Removed: 902_error_logging_infrastructure_completion
  ...
  ✓ Removed: 787_state_machine_persistence_bug

=== Cleanup Summary ===
Removed: 87 directories
Preserved: 108 directories
Archive: /home/user/.claude/archive/completed_20251129/

Next Steps:
- Run /todo to update TODO.md and reflect current projects
- Review archive: ls .claude/archive/completed_20251129/
```

### 8. Implementation Considerations

#### Archive vs Delete
**Options**:
1. **Move to archive/**: Safer, allows recovery
   - Create timestamped archive directory: `archive/cleaned_20251129_160000/`
   - Move directories: `mv specs/{topic}/ archive/cleaned_20251129_160000/`

2. **Delete permanently**: Simpler, but risky
   - Direct removal: `rm -rf specs/{topic}/`
   - Requires confirmation or --force flag

**Recommendation**: Use archive approach for safety

#### Age Threshold
**Options**:
1. **Keep 30-day threshold**: Only remove old completed/abandoned projects
2. **Remove all**: Clean up all completed/abandoned regardless of age
3. **Make configurable**: Add `--age-threshold <days>` flag

**Recommendation**: Remove all by default (simpler), add threshold later if needed

#### TODO.md Handling
**User Requirement**: Do NOT modify TODO.md

**Workflow**:
1. `/todo --clean` removes directories
2. `/todo` (without flags) updates TODO.md to reflect current state
3. Entries for removed directories disappear naturally (no plan files found)

**Advantage**: Separation of concerns (cleanup vs status tracking)

#### Error Handling
**Scenarios**:
1. Directory not found: Log warning, continue
2. Permission denied: Log error, skip directory
3. Directory outside specs/: Log error, abort
4. Archive creation fails: Log error, abort

**Error Log Integration**:
```bash
log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
  "file_error" "Failed to remove directory: $topic_path" \
  "Block:DirectoryRemoval" \
  '{"topic":"'"$topic_name"'","reason":"permission denied"}'
```

### 9. Changes Required

#### 1. Update `/home/benjamin/.config/.claude/commands/todo.md`

**Section to Modify**: "Clean Mode (--clean flag)" (lines 618-652)

**Current**:
```markdown
## Clean Mode (--clean flag)

If CLEAN_MODE is true, instead of updating TODO.md, generate a cleanup plan
for completed projects older than 30 days.

**EXECUTE IF CLEAN_MODE=true**: Generate cleanup plan via plan-architect agent.
```

**Proposed**:
```markdown
## Clean Mode (--clean flag)

If CLEAN_MODE is true, directly remove completed and abandoned project
directories from specs/ without modifying TODO.md.

**EXECUTE IF CLEAN_MODE=true**: Remove directories via cleanup execution block.

Block 5: Directory Removal (Clean Mode Only)
- Filter for completed and abandoned status
- Remove project directories from specs/
- Archive to timestamped directory
- Generate removal summary
- Do NOT modify TODO.md
```

#### 2. Add Cleanup Functions to `todo-functions.sh`

**New Functions Needed**:
```bash
# Filter for completed AND abandoned projects
filter_cleanup_candidates() {
  local plans_json="$1"
  echo "$plans_json" | jq -r '[.[] | select(.status == "completed" or .status == "abandoned")]'
}

# Execute directory removal
remove_project_directories() {
  local projects_json="$1"
  local archive_dir="$2"
  local dry_run="${3:-false}"

  # Implementation: Loop through projects, validate, remove/archive
}

# Generate cleanup summary
generate_cleanup_summary() {
  local removed_count="$1"
  local preserved_count="$2"
  local archive_path="$3"

  # Implementation: Format summary output
}
```

#### 3. Update Documentation

**Files to Update**:
- `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md`
  - Update "Clean Mode" section (lines 276-284)
  - Update examples to show direct removal

- `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md`
  - Update "Usage by Commands" section if needed

#### 4. Update Tests

**Test Coverage Needed**:
- Test cleanup filtering (completed + abandoned)
- Test directory removal (dry-run and actual)
- Test archive directory creation
- Test error handling (missing dirs, permissions)
- Test TODO.md preservation (verify no modifications)

### 10. Edge Cases and Considerations

#### Edge Case 1: Completed Entry Still Has Work
**Scenario**: Plan marked complete in TODO.md but user wants to keep directory for reference

**Solution**: User can manually move entry to "Not Started" or "Backlog" before running --clean

#### Edge Case 2: Abandoned with Valuable Research
**Scenario**: Abandoned plan contains reports user wants to preserve

**Solution**: Archive approach preserves all content; user can extract reports from archive

#### Edge Case 3: TODO.md Out of Sync
**Scenario**: TODO.md shows completed but plan file updated to in_progress

**Solution**: Run `/todo` (without --clean) first to sync, then run `/todo --clean`

#### Edge Case 4: Concurrent Execution
**Scenario**: User runs `/todo` and `/todo --clean` simultaneously

**Solution**: Workflow ID ensures separate state files; directory removal is atomic

#### Edge Case 5: Partial Cleanup Failure
**Scenario**: Some directories removed successfully, others fail

**Solution**: Log each operation individually; continue on error; report summary at end

## Recommendations

### Immediate Actions

1. **Refactor --clean to Direct Removal**
   - Modify Clean Mode section in todo.md
   - Add Block 5 for directory removal execution
   - Filter for "completed" AND "abandoned" status
   - Archive to timestamped directory (safer than delete)

2. **Update Library Functions**
   - Extend `filter_completed_projects()` to include abandoned
   - Add `remove_project_directories()` function
   - Add `generate_cleanup_summary()` function

3. **Preserve TODO.md**
   - Remove TODO.md update logic from cleanup flow
   - Document workflow: `/todo --clean` → `/todo` (two-step)

4. **Enhance Safety**
   - Archive to `archive/cleaned_{timestamp}/`
   - Validate directory paths (must be within specs/)
   - Log all operations to error log
   - Support --dry-run for preview

### Future Enhancements

1. **Age Threshold Flag**
   - Add `--age-threshold <days>` option
   - Default: remove all (current behavior)
   - Example: `/todo --clean --age-threshold 30`

2. **Selective Cleanup**
   - Add `--completed-only` or `--abandoned-only` flags
   - Allow user to target specific status

3. **Archive Management**
   - Add `/todo --list-archives` to show archived directories
   - Add `/todo --restore <archive-path>` to restore from archive
   - Add archive rotation policy (delete archives older than N days)

4. **Interactive Mode**
   - Show list of candidates
   - Prompt for confirmation per directory
   - Example: `/todo --clean --interactive`

## Success Criteria

1. **Functional**:
   - `/todo` (no flags) updates TODO.md only
   - `/todo --clean` removes completed/abandoned directories only
   - `/todo --clean --dry-run` previews without removal
   - TODO.md is NOT modified by --clean

2. **Safety**:
   - All removed directories archived (not deleted)
   - Archive path is timestamped and documented
   - Error log captures all operations
   - Validation prevents removal outside specs/

3. **Usability**:
   - Clear summary output (removed count, preserved count, archive path)
   - Recovery instructions if needed
   - Dry-run preview matches actual execution

4. **Documentation**:
   - Updated command guide
   - Updated standards documentation
   - Examples for typical workflows

## Conclusion

The refactoring of `/todo --clean` from plan generation to direct execution is straightforward and beneficial:

**Benefits**:
- **Simpler workflow**: One-step cleanup vs two-step (generate plan + execute)
- **Clearer separation**: TODO.md updates (default) vs directory cleanup (--clean)
- **Safer approach**: Archive instead of delete, dry-run preview, error logging
- **More comprehensive**: Removes both completed AND abandoned projects

**Risks**:
- **Data loss**: Mitigated by archiving (move, not delete)
- **Accidental cleanup**: Mitigated by dry-run preview and validation
- **TODO.md drift**: Mitigated by running `/todo` after cleanup

**Implementation Effort**: Low (Complexity 2)
- Modify 1 command file (todo.md)
- Add 3 library functions (todo-functions.sh)
- Update 2 documentation files
- Add test coverage

The current library already provides most building blocks (`filter_completed_projects()`, directory scanning). The refactoring primarily involves:
1. Extending filtering to include abandoned status
2. Adding direct removal logic (with archive support)
3. Removing plan generation invocation
4. Updating documentation

**Next Steps**:
1. Create implementation plan with phases
2. Implement Block 5 (Directory Removal) in todo.md
3. Add cleanup functions to todo-functions.sh
4. Update documentation and tests
5. Validate with --dry-run on production specs/

## Appendix A: Current TODO.md Statistics

**Total Sections**: 6 (In Progress, Not Started, Backlog, Superseded, Abandoned, Completed)

**Entry Counts** (from grep output):
- In Progress: 2 entries
- Not Started: 2 entries
- Backlog: ~8-10 items (manually curated)
- Superseded: ~10 entries
- Abandoned: ~20 entries
- Completed: ~170 entries

**Cleanup Target Count**: ~190 entries (abandoned + completed)

**Specs Directory Count**: 195 topic directories (from ls output)

**Expected Cleanup**: ~190 directories eligible for removal

## Appendix B: Related Files

**Commands**:
- `/home/benjamin/.config/.claude/commands/todo.md` (672 lines)

**Libraries**:
- `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh` (916 lines)
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
- `/home/benjamin/.config/.claude/lib/core/unified-location-detection.sh`

**Agents**:
- `/home/benjamin/.config/.claude/agents/todo-analyzer.md` (451 lines)

**Documentation**:
- `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md` (389 lines)
- `/home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md` (285 lines)

**Data Files**:
- `/home/benjamin/.config/.claude/TODO.md` (296 lines)
- `/home/benjamin/.config/.claude/specs/` (195 directories)

## Appendix C: Implementation Checklist

- [ ] Modify todo.md Clean Mode section
- [ ] Add Block 5 for directory removal
- [ ] Extend filter_completed_projects() to filter_cleanup_candidates()
- [ ] Add remove_project_directories() function
- [ ] Add generate_cleanup_summary() function
- [ ] Update todo-command-guide.md
- [ ] Update todo-organization-standards.md (if needed)
- [ ] Add test coverage for cleanup functions
- [ ] Add test for TODO.md preservation
- [ ] Validate with --dry-run on specs/ directory
- [ ] Document archive directory structure
- [ ] Add recovery instructions to guide
