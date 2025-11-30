# Refactor /todo --clean Command Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Refactor /todo --clean to remove completed/abandoned project directories from specs/ based on TODO.md entries without modifying TODO.md
- **Scope**: Direct execution of directory cleanup instead of plan generation; preserve default /todo behavior
- **Estimated Phases**: 5
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 28.0 (refactor=5, tasks=12, files=3*3=9, integrations=2*5=10, hours=6*0.5=3)
- **Research Reports**:
  - [Refactor /todo --clean Command Research](/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/reports/001-refactor-todo-clean-command-research.md)

## Overview

The current `/todo --clean` implementation generates a cleanup **plan** via the plan-architect agent, requiring subsequent execution with `/build`. This refactoring changes `--clean` to **directly execute** directory removal based on TODO.md status classification (completed and abandoned entries), while preserving the default behavior where `/todo` (without flags) only updates TODO.md.

**Goals**:
1. `/todo --clean` removes completed/abandoned directories from specs/ immediately
2. `/todo --clean` does NOT modify TODO.md
3. `/todo` (without flags) continues to only revise TODO.md
4. Archive removed directories (safer than deletion)
5. Support --dry-run preview mode

## Research Summary

Key findings from research report:

**Current Implementation**:
- Lines 618-652 in todo.md invoke plan-architect agent to generate cleanup plan
- Plan includes 4 phases: archive creation, directory moves, TODO.md update, verification
- Requires manual execution via `/build <cleanup-plan-path>` (two-step process)
- Only targets "completed" status, not "abandoned"

**Library Support**:
- `filter_completed_projects()` exists but only filters "completed" (not abandoned)
- `generate_cleanup_plan()` generates plan content (not needed for direct execution)
- Directory scanning and status classification already working

**TODO.md Mapping**:
- Entries map 1:1 to specs/ directories via topic naming: `{NNN_topic_name}/`
- Completed and Abandoned sections auto-updated by /todo command
- ~190 directories eligible for cleanup (completed + abandoned)
- Current TODO.md has ~170 completed, ~20 abandoned entries

**Recommended Approach**:
- Extend filtering to include both "completed" and "abandoned" status
- Archive to timestamped directory: `archive/cleaned_YYYYMMDD_HHMMSS/`
- Direct removal execution (no plan generation)
- DO NOT modify TODO.md (user runs `/todo` afterward to sync)

## Success Criteria

- [ ] `/todo` (no flags) updates TODO.md only (existing behavior preserved)
- [ ] `/todo --clean` removes completed AND abandoned directories from specs/
- [ ] `/todo --clean --dry-run` previews removal without executing
- [ ] Removed directories are archived (not permanently deleted)
- [ ] TODO.md is NOT modified by --clean flag
- [ ] Archive path is timestamped and documented in summary
- [ ] Error log captures all operations (file_error, execution_error)
- [ ] Summary shows: removed count, preserved count, archive path
- [ ] Recovery instructions provided if cleanup fails

## Technical Design

### Architecture Changes

**Before (Plan Generation)**:
```
/todo --clean
  → Invoke plan-architect agent
  → Generate 4-phase cleanup plan
  → User executes /build <plan>
  → Plan modifies TODO.md (Phase 3)
```

**After (Direct Execution)**:
```
/todo --clean
  → Scan and classify plans (existing logic)
  → Filter completed + abandoned (new)
  → Archive directories (new)
  → Generate summary (new)
  → TODO.md NOT modified
```

### Component Design

**1. Library Functions** (todo-functions.sh):

New function: `filter_cleanup_candidates()`
- Extends `filter_completed_projects()` logic
- Filters for `status == "completed" OR status == "abandoned"`
- No age threshold (remove all regardless of age)
- Returns JSON array of cleanup candidates

New function: `remove_project_directories()`
- Validates each directory path (must be within specs/)
- Creates timestamped archive directory
- Moves (not deletes) directories to archive
- Logs each operation to error log
- Supports dry-run mode (preview only)
- Returns removed count and errors

New function: `generate_cleanup_summary()`
- Formats summary output with emoji markers
- Shows: removed count, preserved count, archive path
- Includes recovery instructions
- Follows output formatting standards (4-section format)

**2. Command Changes** (todo.md):

Replace Block 5 (Clean Mode section, lines 618-652):
- Remove plan-architect agent invocation
- Add direct cleanup execution using new library functions
- Preserve --dry-run flag handling
- Add cleanup summary output
- Ensure error logging integration

**3. Documentation Updates**:

- Update todo-command-guide.md "Clean Mode" section (lines 276-284)
- Add examples: `/todo --clean`, `/todo --clean --dry-run`
- Document two-step workflow: `/todo --clean` → `/todo` (to sync TODO.md)

### Data Flow

```
1. Command receives --clean flag
2. Scan specs/ directories (existing: lines 58-217)
3. Classify plan status via todo-analyzer (existing: lines 220-439)
4. [NEW] Filter for completed + abandoned status
5. [NEW] Validate directories (within specs/, exist)
6. [NEW] Create archive directory with timestamp
7. [NEW] Move directories to archive (or preview in dry-run)
8. [NEW] Log operations to error log
9. [NEW] Generate cleanup summary
10. Exit (TODO.md NOT modified)
```

### Error Handling

**Error Types**:
- `file_error`: Directory not found, permission denied
- `validation_error`: Directory outside specs/, invalid path
- `execution_error`: Archive creation failed, move failed

**Error Logging**:
```bash
log_command_error "$error_type" "$error_message" "$error_details"
```

**Recovery**:
- Archive approach allows full recovery (directories not deleted)
- Error log provides audit trail
- Dry-run preview prevents accidental cleanup

## Implementation Phases

### Phase 1: Add Cleanup Filter Function [NOT STARTED]
dependencies: []

**Objective**: Create library function to filter completed AND abandoned projects for cleanup

**Complexity**: Low

Tasks:
- [ ] Add `filter_cleanup_candidates()` to todo-functions.sh (after line 768)
- [ ] Filter for `status == "completed" OR status == "abandoned"`
- [ ] Remove age threshold logic (clean all regardless of age)
- [ ] Return JSON array compatible with existing data structures
- [ ] Export function at end of file (Section 8, line 896+)

Testing:
```bash
# Test with sample JSON
classified_json='[{"status":"completed","topic_name":"961_test"},{"status":"abandoned","topic_name":"902_test"},{"status":"in_progress","topic_name":"965_test"}]'
result=$(filter_cleanup_candidates "$classified_json")
# Expect: 2 entries (completed + abandoned), not in_progress
echo "$result" | jq 'length'  # Should be 2
```

**Expected Duration**: 1 hour

---

### Phase 2: Add Directory Removal Function [NOT STARTED]
dependencies: [1]

**Objective**: Create library function to safely remove/archive project directories

**Complexity**: Medium

Tasks:
- [ ] Add `remove_project_directories()` to todo-functions.sh (after filter_cleanup_candidates)
- [ ] Validate each directory path (exists, within specs/ root)
- [ ] Create timestamped archive directory: `archive/cleaned_YYYYMMDD_HHMMSS/`
- [ ] Move directories to archive (not delete): `mv specs/{topic}/ archive/cleaned_{timestamp}/`
- [ ] Support dry-run mode: preview only, no actual moves
- [ ] Log each operation using error-handling.sh
- [ ] Return JSON with: removed_count, failed_count, archive_path, errors[]
- [ ] Export function at end of file

Testing:
```bash
# Test dry-run mode
result=$(remove_project_directories "$candidates_json" "true")
echo "$result" | jq '.removed_count'  # Should be 0 (dry-run)

# Test actual removal (with test directories)
mkdir -p .claude/specs/999_test_cleanup/plans
result=$(remove_project_directories "$test_json" "false")
echo "$result" | jq '.removed_count'  # Should be 1
ls .claude/archive/cleaned_*/999_test_cleanup  # Should exist
```

**Expected Duration**: 2 hours

---

### Phase 3: Add Cleanup Summary Function [NOT STARTED]
dependencies: [2]

**Objective**: Create library function to format cleanup summary output

**Complexity**: Low

Tasks:
- [ ] Add `generate_cleanup_summary()` to todo-functions.sh (after remove_project_directories)
- [ ] Accept arguments: removed_count, preserved_count, archive_path, dry_run
- [ ] Format output using 4-section emoji format (Summary, Operations, Archive, Next Steps)
- [ ] Include recovery instructions for archive location
- [ ] Follow output formatting standards (no WHY comments, WHAT only)
- [ ] Export function at end of file

Testing:
```bash
# Test summary output
summary=$(generate_cleanup_summary 87 108 "/path/to/archive/cleaned_20251129_160000" "false")
echo "$summary"
# Verify: Contains removed count, preserved count, archive path, next steps
```

**Expected Duration**: 0.5 hours

---

### Phase 4: Refactor Command Clean Mode Section [NOT STARTED]
dependencies: [3]

**Objective**: Replace plan generation with direct cleanup execution in todo.md

**Complexity**: Medium

Tasks:
- [ ] Read current todo.md Clean Mode section (lines 618-652)
- [ ] Replace plan-architect agent invocation with direct cleanup execution
- [ ] Source error-handling library for log_command_error
- [ ] Call filter_cleanup_candidates() with classified plans
- [ ] Call remove_project_directories() with filtered candidates
- [ ] Call generate_cleanup_summary() for output
- [ ] Preserve --dry-run flag handling
- [ ] Ensure TODO.md is NOT modified (remove any update logic)
- [ ] Update completion summary (lines 654-667) to show cleanup stats

Testing:
```bash
# Test dry-run mode
/todo --clean --dry-run
# Expected: Preview output, no directories removed, no TODO.md changes

# Test actual cleanup (in test environment)
cp .claude/TODO.md .claude/TODO.md.backup
/todo --clean
# Expected: Directories archived, TODO.md unchanged
diff .claude/TODO.md .claude/TODO.md.backup  # Should be identical
```

**Expected Duration**: 1.5 hours

---

### Phase 5: Update Documentation [NOT STARTED]
dependencies: [4]

**Objective**: Update command guide to document new --clean behavior

**Complexity**: Low

Tasks:
- [ ] Read todo-command-guide.md Clean Mode section (lines 276-284)
- [ ] Update description: "directly removes directories" (not "generates plan")
- [ ] Update examples: show `/todo --clean` and `/todo --clean --dry-run`
- [ ] Document two-step workflow: `--clean` removes dirs, then `/todo` syncs TODO.md
- [ ] Add archive location documentation
- [ ] Add recovery instructions (how to restore from archive)
- [ ] Update "Common Workflows" section with cleanup workflow

Testing:
```bash
# Verify documentation completeness
grep -n "clean" .claude/docs/guides/commands/todo-command-guide.md
# Expected: Clean Mode section describes direct removal, not plan generation
```

**Expected Duration**: 1 hour

---

## Testing Strategy

### Unit Tests (Library Functions)

**Test Coverage**:
1. `filter_cleanup_candidates()`:
   - Filters completed status ✓
   - Filters abandoned status ✓
   - Excludes in_progress, not_started, superseded ✓
   - Handles empty input ✓

2. `remove_project_directories()`:
   - Validates directory exists ✓
   - Validates directory within specs/ ✓
   - Creates archive directory ✓
   - Moves directories (not deletes) ✓
   - Dry-run mode (preview only) ✓
   - Error logging integration ✓

3. `generate_cleanup_summary()`:
   - Formats summary correctly ✓
   - Includes all required sections ✓
   - Shows archive path ✓
   - Includes recovery instructions ✓

### Integration Tests (Command)

**Test Scenarios**:
1. `/todo` without flags: Updates TODO.md only ✓
2. `/todo --clean --dry-run`: Previews removal without execution ✓
3. `/todo --clean`: Removes completed + abandoned directories ✓
4. TODO.md preservation: Verify no modifications by --clean ✓
5. Archive recovery: Restore directory from archive ✓

**Test Environment**:
```bash
# Create test specs directory
mkdir -p test_specs/{961_completed,902_abandoned,965_in_progress}/plans
# Populate with test plans
# Run /todo --clean --dry-run
# Verify output
```

### Error Handling Tests

**Error Scenarios**:
1. Directory not found (already removed)
2. Permission denied (read-only directory)
3. Archive creation fails (disk full, permissions)
4. Directory outside specs/ (validation failure)

**Expected Behavior**:
- Log error via error-handling.sh
- Continue processing remaining directories
- Report errors in summary
- Non-zero exit code if critical errors

## Documentation Requirements

**Files to Update**:

1. `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md`:
   - Clean Mode section (lines 276-284): Update description and examples
   - Add archive management subsection
   - Add recovery procedure subsection
   - Update "Common Workflows" with cleanup workflow

2. `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`:
   - Add function documentation headers for 3 new functions
   - Follow existing doc pattern: Purpose, Arguments, Returns

3. `/home/benjamin/.config/.claude/commands/todo.md` (inline docs):
   - Update Clean Mode section description
   - Document --dry-run flag behavior
   - Add example usage comments

**Documentation Standards**:
- Follow CommonMark specification
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in file content (UTF-8 encoding issues)
- Document WHAT code does, not WHY

## Dependencies

### Internal Dependencies
- `todo-analyzer.md` agent: Status classification (existing)
- `todo-functions.sh`: Scanning, filtering functions (existing)
- `error-handling.sh`: Error logging integration (existing)
- `workflow-initialization.sh`: Path initialization (existing)

### External Dependencies
- `jq`: JSON parsing (required, already used)
- `stat`: File modification time (required, already used)
- `mv`: Directory move operation (required, standard)

### Prerequisite Validation
- Error logging infrastructure complete ✓ (Plan 902 confirmed)
- Three-tier library sourcing in place ✓ (enforced by linter)
- TODO.md organization standards defined ✓ (todo-organization-standards.md)

## Notes

**Backward Compatibility**:
- Default `/todo` behavior unchanged (only updates TODO.md)
- Existing library functions preserved (no breaking changes)
- New functions are additive (no deletions)

**Migration Path**:
- No migration needed (new behavior only affects --clean flag)
- Users can continue using `/todo` as before
- Archive allows rollback if cleanup was accidental

**Future Enhancements** (Out of Scope):
- Age threshold flag: `--age-threshold <days>`
- Selective cleanup: `--completed-only` or `--abandoned-only`
- Archive management: `--list-archives`, `--restore <archive>`
- Interactive mode: `--interactive` (prompt per directory)

**Complexity Justification**:
- Refactoring existing command (not new feature)
- Simple library function additions (3 functions)
- No state machine changes
- No new agents
- Low risk (archive approach allows recovery)
