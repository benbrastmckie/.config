# Refactor /todo --clean Command Implementation Plan

## Metadata
- **Date**: 2025-11-29 (Revised)
- **Feature**: Refactor /todo --clean filtering and add git verification to cleanup plan generation
- **Scope**: Keep plan-generation approach; remove age threshold; include superseded status; add Phase 0 git verification
- **Estimated Phases**: 5 (Phase 0-4)
- **Estimated Hours**: 8 (increased from 6 due to git verification)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 38.0 (refactor=5, tasks=15, files=3*3=9, integrations=3*5=15, hours=8*0.5=4)
- **Research Reports**:
  - [Refactor /todo --clean Command Research](/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/reports/001-refactor-todo-clean-command-research.md)
  - [Plan Revision Insights](/home/benjamin/.config/.claude/specs/971_refactor_todo_clean_command/reports/002-plan-revision-insights.md)

## Overview

The current `/todo --clean` implementation generates a cleanup **plan** via the plan-architect agent, requiring subsequent execution with `/build`. This refactoring **keeps the plan-generation approach** but improves the filtering logic and adds safety checks. The plan will target completed, abandoned, AND superseded entries (removing the 30-day age threshold), and verify git commit status before cleanup.

**Goals**:
1. `/todo --clean` generates a cleanup plan (via plan-architect agent)
2. Plan targets completed, abandoned, AND superseded projects (all eligible, no age filtering)
3. Add Phase 0: Git commit verification (blocks cleanup if uncommitted changes exist)
4. Plan execution via `/build` removes directories and updates TODO.md
5. Support --dry-run preview mode
6. Archive removed directories (safer than deletion)

## Research Summary

Key findings from research reports:

**Current Implementation**:
- Lines 618-652 in todo.md invoke plan-architect agent to generate cleanup plan
- Plan includes 4 phases: archive creation, directory moves, TODO.md update, verification
- Requires manual execution via `/build <cleanup-plan-path>` (two-step process)
- Only targets "completed" status with 30-day age threshold

**Revision Requirements**:
- KEEP plan-generation approach (do NOT switch to direct execution)
- REMOVE 30-day age threshold (clean ALL eligible projects regardless of age)
- ADD "superseded" status to cleanup targets (in addition to completed and abandoned)
- ADD Phase 0: Git commit verification (ensure no uncommitted changes before cleanup)

**Library Support**:
- `filter_completed_projects()` exists but needs updating (remove age threshold, add statuses)
- `generate_cleanup_plan()` generates plan content (keep this approach)
- Directory scanning and status classification already working

**TODO.md Mapping**:
- Entries map 1:1 to specs/ directories via topic naming: `{NNN_topic_name}/`
- Completed, Abandoned, and Superseded sections auto-updated by /todo command
- ~200 directories eligible for cleanup (completed + abandoned + superseded)
- Current TODO.md has ~170 completed, ~20 abandoned, ~10 superseded entries

**Recommended Approach**:
- Extend filtering to include "completed", "abandoned", AND "superseded" status
- Remove age-based filtering entirely (all eligible projects)
- Add git verification before cleanup (check for uncommitted changes)
- Archive to timestamped directory: `archive/cleaned_YYYYMMDD_HHMMSS/`
- Keep plan generation workflow (generates plan → user executes with /build)
- Plan DOES modify TODO.md (removes archived entries)

## Success Criteria

- [ ] `/todo` (no flags) updates TODO.md only (existing behavior preserved)
- [ ] `/todo --clean` generates cleanup plan for completed, abandoned, AND superseded projects
- [ ] `/todo --clean --dry-run` previews plan generation without executing
- [ ] Plan includes Phase 0: Git commit verification (checks for uncommitted changes)
- [ ] Git verification blocks cleanup of directories with uncommitted changes
- [ ] Filter targets ALL eligible projects (no age threshold)
- [ ] Removed directories are archived (not permanently deleted)
- [ ] Generated plan modifies TODO.md (removes archived entries) when executed
- [ ] Archive path is timestamped and documented in plan
- [ ] Error log captures all operations (file_error, validation_error, execution_error)
- [ ] Summary shows: removed count, skipped count (uncommitted), archive path
- [ ] Recovery instructions provided if cleanup fails

## Technical Design

### Architecture Changes

**Before (Current with Age Threshold)**:
```
/todo --clean
  → Invoke plan-architect agent
  → Filter completed projects (30-day age threshold)
  → Generate 4-phase cleanup plan
  → User executes /build <plan>
  → Plan modifies TODO.md (Phase 3)
```

**After (Revised with Git Verification)**:
```
/todo --clean
  → Scan and classify plans (existing logic)
  → Filter completed + abandoned + superseded (NO age threshold)
  → Verify git commit status (NEW Phase 0)
  → Invoke plan-architect agent
  → Generate 5-phase cleanup plan (Phase 0 + existing 4 phases)
  → User executes /build <plan>
  → Plan modifies TODO.md (Phase 4, was Phase 3)
```

### Component Design

**1. Library Functions** (todo-functions.sh):

New function: `filter_cleanup_candidates()`
- Replaces `filter_completed_projects()` with simpler implementation
- Filters for `status == "completed" OR status == "abandoned" OR status == "superseded"`
- NO age threshold (all eligible projects regardless of age)
- Returns JSON array of cleanup candidates

New function: `verify_git_status()`
- Checks if a directory has uncommitted changes
- Uses `git status --porcelain` to detect changes
- Arguments: directory path, project root
- Returns: exit code 0 (clean) or 1 (uncommitted changes)
- Logs warnings for directories with uncommitted changes

Updated function: `generate_cleanup_plan()`
- Adds Phase 0: Git Commit Verification
- Updates eligible statuses in plan documentation
- Updates phase dependencies (Phase 1 now depends on Phase 0)
- Renumbers existing phases (archive = Phase 1, moves = Phase 2, TODO.md = Phase 3, verify = Phase 4)

**2. Command Changes** (todo.md):

Update Block 5 (Clean Mode section, lines 618-652):
- Keep plan-architect agent invocation (do NOT remove)
- Update filtering to use `filter_cleanup_candidates()` (includes superseded)
- Add git verification before plan generation
- Filter out directories with uncommitted changes
- Pass only safe directories to plan-architect
- Preserve --dry-run flag handling
- Ensure error logging integration

**3. Documentation Updates**:

- Update todo-command-guide.md "Clean Mode" section (lines 276-284)
- Add examples: `/todo --clean`, `/todo --clean --dry-run`
- Document workflow: `/todo --clean` (generates plan) → `/build <plan>` (executes cleanup)
- Document git verification requirement
- Document eligible statuses: completed, abandoned, superseded

### Data Flow

```
1. Command receives --clean flag
2. Scan specs/ directories (existing: lines 58-217)
3. Classify plan status via todo-analyzer (existing: lines 220-439)
4. [NEW] Filter for completed + abandoned + superseded status (NO age threshold)
5. [NEW] Verify git status for each candidate directory
6. [NEW] Filter to only safe directories (no uncommitted changes)
7. [NEW] Warn about skipped directories (uncommitted changes)
8. [KEEP] Invoke plan-architect agent with safe candidates
9. [KEEP] Generate 5-phase cleanup plan (with Phase 0: Git Verification)
10. [KEEP] User executes plan with /build
11. [KEEP] Plan modifies TODO.md (removes archived entries)
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

### Phase 0: Add Git Verification Function [NOT STARTED]
dependencies: []

**Objective**: Create library function to verify git commit status before cleanup

**Complexity**: Low

Tasks:
- [ ] Add `verify_git_status()` to todo-functions.sh (after line 768)
- [ ] Check if directory has uncommitted changes using `git status --porcelain`
- [ ] Arguments: directory path, project root
- [ ] Return exit code 0 (clean) or 1 (uncommitted changes)
- [ ] Handle edge cases (not in git repo, git not installed, invalid path)
- [ ] Log warnings for directories with uncommitted changes
- [ ] Export function at end of file (Section 8, line 896+)

Testing:
```bash
# Test with clean directory
verify_git_status "$CLAUDE_PROJECT_DIR/.claude/specs/961_repair/" "$CLAUDE_PROJECT_DIR"
echo $?  # Should be 0 (clean)

# Test with uncommitted changes (create test directory with changes)
mkdir -p test_specs/999_test/plans
echo "test" > test_specs/999_test/plans/test.md
verify_git_status "$PWD/test_specs/999_test/" "$PWD"
echo $?  # Should be 1 (uncommitted changes)
```

**Expected Duration**: 1.5 hours

---

### Phase 1: Add Cleanup Filter Function [NOT STARTED]
dependencies: [0]

**Objective**: Create library function to filter completed, abandoned, AND superseded projects for cleanup

**Complexity**: Low

Tasks:
- [ ] Add `filter_cleanup_candidates()` to todo-functions.sh (after verify_git_status)
- [ ] Filter for `status == "completed" OR status == "abandoned" OR status == "superseded"`
- [ ] NO age threshold logic (clean all regardless of age)
- [ ] Return JSON array compatible with existing data structures
- [ ] Export function at end of file (Section 8, line 896+)

Testing:
```bash
# Test with sample JSON
classified_json='[{"status":"completed","topic_name":"961_test"},{"status":"abandoned","topic_name":"902_test"},{"status":"superseded","topic_name":"903_test"},{"status":"in_progress","topic_name":"965_test"}]'
result=$(filter_cleanup_candidates "$classified_json")
# Expect: 3 entries (completed + abandoned + superseded), not in_progress
echo "$result" | jq 'length'  # Should be 3
```

**Expected Duration**: 1 hour

---

### Phase 2: Update Cleanup Plan Generator [NOT STARTED]
dependencies: [1]

**Objective**: Update generate_cleanup_plan() to include Phase 0 (Git Verification) and new eligible statuses

**Complexity**: Medium

Tasks:
- [ ] Read current generate_cleanup_plan() function (lines 770-893 in todo-functions.sh)
- [ ] Add Phase 0: Git Commit Verification to plan template
- [ ] Update Phase 0 to check all candidate directories for uncommitted changes
- [ ] Update phase dependencies (Phase 1 depends on Phase 0)
- [ ] Renumber existing phases (archive=1, moves=2, TODO.md=3, verify=4)
- [ ] Update plan metadata to document eligible statuses (completed, abandoned, superseded)
- [ ] Update "Safety Measures" section to mention git verification
- [ ] Export updated function

Testing:
```bash
# Test plan generation with git verification phase
candidates_json='[{"topic_name":"961_test","status":"completed"},{"topic_name":"902_test","status":"abandoned"}]'
plan_content=$(generate_cleanup_plan "$candidates_json" "/path/to/archive" "$CLAUDE_PROJECT_DIR/.claude/specs")
echo "$plan_content" | grep "Phase 0: Git Commit Verification"  # Should exist
echo "$plan_content" | grep "dependencies: \[0\]"  # Phase 1 should depend on Phase 0
```

**Expected Duration**: 2 hours

---

### Phase 3: Update Command Clean Mode Section [NOT STARTED]
dependencies: [2]

**Objective**: Update todo.md Clean Mode to use new filtering and git verification

**Complexity**: Medium

Tasks:
- [ ] Read current todo.md Clean Mode section (lines 618-652)
- [ ] KEEP plan-architect agent invocation (do NOT remove)
- [ ] Update filtering to call filter_cleanup_candidates() (includes superseded)
- [ ] Add git verification loop before plan generation
- [ ] For each candidate: call verify_git_status()
- [ ] Filter to only safe directories (no uncommitted changes)
- [ ] Warn about skipped directories with uncommitted changes
- [ ] Pass only safe candidates to plan-architect agent
- [ ] Preserve --dry-run flag handling
- [ ] Source error-handling library for log_command_error
- [ ] Update completion summary to show safe vs unsafe counts

Testing:
```bash
# Test dry-run mode
/todo --clean --dry-run
# Expected: Plan generation preview, shows git verification results

# Test with uncommitted changes (create test directory)
mkdir -p .claude/specs/999_test/plans
echo "test" > .claude/specs/999_test/plans/test.md
/todo --clean
# Expected: Warning about 999_test being skipped, plan generated for safe dirs only
```

**Expected Duration**: 2 hours

---

### Phase 4: Update Documentation [NOT STARTED]
dependencies: [3]

**Objective**: Update command guide to document revised --clean behavior

**Complexity**: Low

Tasks:
- [ ] Read todo-command-guide.md Clean Mode section (lines 276-284)
- [ ] Update description: "generates cleanup plan" (keep current approach)
- [ ] Update eligible statuses: completed, abandoned, AND superseded
- [ ] Document git verification requirement (Phase 0 in generated plan)
- [ ] Update examples: show `/todo --clean` → `/build <plan>` workflow
- [ ] Document --dry-run flag behavior
- [ ] Add troubleshooting for uncommitted changes scenario
- [ ] Update "Common Workflows" section with cleanup workflow
- [ ] Add archive location documentation
- [ ] Add recovery instructions (how to restore from archive)

Testing:
```bash
# Verify documentation completeness
grep -n "clean" .claude/docs/guides/commands/todo-command-guide.md
# Expected: Clean Mode section describes plan generation, git verification, eligible statuses
grep -n "superseded" .claude/docs/guides/commands/todo-command-guide.md
# Expected: Mentions superseded as eligible status
```

**Expected Duration**: 1.5 hours

---

## Testing Strategy

### Unit Tests (Library Functions)

**Test Coverage**:
1. `verify_git_status()`:
   - Detects uncommitted changes (modified files) ✓
   - Detects uncommitted changes (untracked files) ✓
   - Returns 0 for clean directories ✓
   - Returns 1 for uncommitted changes ✓
   - Handles not in git repo gracefully ✓
   - Handles git not installed gracefully ✓
   - Error logging integration ✓

2. `filter_cleanup_candidates()`:
   - Filters completed status ✓
   - Filters abandoned status ✓
   - Filters superseded status ✓
   - Excludes in_progress, not_started ✓
   - Handles empty input ✓
   - NO age filtering (all eligible projects) ✓

3. `generate_cleanup_plan()`:
   - Includes Phase 0: Git Commit Verification ✓
   - Phase dependencies correct (Phase 1 depends on Phase 0) ✓
   - Phases renumbered correctly (0-4) ✓
   - Metadata documents eligible statuses ✓
   - Safety measures mention git verification ✓

### Integration Tests (Command)

**Test Scenarios**:
1. `/todo` without flags: Updates TODO.md only ✓
2. `/todo --clean --dry-run`: Previews plan generation without execution ✓
3. `/todo --clean`: Generates cleanup plan for completed + abandoned + superseded ✓
4. Git verification: Skips directories with uncommitted changes ✓
5. Plan execution: `/build <plan>` removes directories and updates TODO.md ✓
6. Archive recovery: Restore directory from archive ✓

**Test Environment**:
```bash
# Create test specs directory with different statuses
mkdir -p test_specs/{961_completed,902_abandoned,903_superseded,965_in_progress}/plans
# Create test plans with appropriate status
# Add uncommitted changes to one directory
echo "test" > test_specs/961_completed/plans/uncommitted.md
# Run /todo --clean
# Verify: Plan generated, 961 skipped (uncommitted), others included
```

### Error Handling Tests

**Error Scenarios**:
1. Directory not found (already removed)
2. Permission denied (read-only directory)
3. Git not installed or repository not initialized
4. Directory outside specs/ (validation failure)
5. Uncommitted changes in candidate directory
6. Archive creation fails (disk full, permissions)

**Expected Behavior**:
- Log error via error-handling.sh
- Skip problematic directories (continue processing)
- Warn user about skipped directories
- Report errors and warnings in summary
- Non-zero exit code if critical errors
- Git verification failures logged as warnings (not errors)

## Documentation Requirements

**Files to Update**:

1. `/home/benjamin/.config/.claude/docs/guides/commands/todo-command-guide.md`:
   - Clean Mode section (lines 276-284): Update description and examples
   - Document plan-generation workflow (not direct execution)
   - Document eligible statuses: completed, abandoned, superseded
   - Document git verification requirement
   - Add troubleshooting subsection (uncommitted changes)
   - Add archive management subsection
   - Add recovery procedure subsection
   - Update "Common Workflows" with cleanup workflow

2. `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`:
   - Add function documentation headers for 2 new functions (verify_git_status, filter_cleanup_candidates)
   - Update generate_cleanup_plan() documentation header
   - Follow existing doc pattern: Purpose, Arguments, Returns

3. `/home/benjamin/.config/.claude/commands/todo.md` (inline docs):
   - Update Clean Mode section description
   - Document git verification step
   - Document --dry-run flag behavior
   - Add example usage comments
   - Update eligible statuses list

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
- Plan-generation workflow maintained (consistent user experience)
- New functions are additive (no deletions)

**Key Revisions from Original Plan**:
1. KEPT plan-generation approach (reverted from direct execution)
2. REMOVED 30-day age threshold (all eligible projects cleaned)
3. ADDED superseded status to cleanup targets
4. ADDED Phase 0: Git commit verification

**Migration Path**:
- No migration needed (refining existing --clean behavior)
- Users continue workflow: `/todo --clean` → `/build <plan>`
- Archive allows rollback if cleanup was accidental

**Future Enhancements** (Out of Scope):
- Age threshold flag: `--age-threshold <days>` (opt-in filtering)
- Selective cleanup: `--completed-only`, `--abandoned-only`, `--superseded-only`
- Archive management: `--list-archives`, `--restore <archive>`
- Interactive mode: `--interactive` (prompt per directory)
- Automatic commit before cleanup: `--auto-commit`

**Complexity Justification**:
- Refactoring existing command (not new feature)
- Simple library function additions (2 new, 1 updated)
- No state machine changes
- No new agents
- Low risk (plan-based approach with git verification)
