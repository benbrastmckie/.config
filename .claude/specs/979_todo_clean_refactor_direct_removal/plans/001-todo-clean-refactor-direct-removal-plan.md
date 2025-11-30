# /todo --clean Direct Removal Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Refactor /todo --clean to directly remove projects after git commit
- **Scope**: Replace plan-generation workflow with direct-execution workflow
- **Estimated Phases**: 5
- **Estimated Hours**: 6 hours
- **Complexity**: Medium
- **Structure Level**: 0
- **Complexity Score**: 26.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Research Reports**:
  - [/todo --clean Direct Removal Research](/home/benjamin/.config/.claude/specs/979_todo_clean_refactor_direct_removal/reports/001-todo-clean-direct-removal-research.md)

## Overview

The current `/todo --clean` implementation generates a cleanup plan via plan-architect agent that requires manual execution with `/build`. This refactoring eliminates the intermediate plan-generation step and directly removes completed/abandoned/superseded projects after committing them to git history.

**Goals**:
1. Replace 2-step workflow (generate plan → execute) with 1-step direct execution
2. Remove plan-architect agent invocation from cleanup flow
3. Eliminate archive directory creation (git history provides recovery)
4. Maintain safety through mandatory pre-cleanup git commit
5. Preserve --dry-run preview functionality

## Research Summary

Research findings from direct removal analysis report:

**Current Architecture** (from research report):
- Block 4b invokes plan-architect agent to generate cleanup plan
- Block 5 displays plan path and instructs user to run /build
- Creates archive/ directory for removed projects
- 2-step workflow with plan review

**Proposed Architecture**:
- Block 4b directly executes cleanup after git commit
- Block 5 displays completion summary with git commit hash
- No archive directory (git history only)
- 1-step workflow with optional --dry-run preview

**Key Insights**:
- Git commit recovery provides equivalent safety to archive directory
- Direct execution reduces workflow complexity and execution time (5-10s faster)
- Follows clean-break development standard (no legacy artifacts)
- Uncommitted changes protection prevents data loss
- Dry-run preview replaces plan review for safety

**Recommended Approach**: Direct removal with git commit recovery (complexity score: 26.5, 5 phases, 6 hours)

## Success Criteria

- [ ] `/todo --clean` directly removes eligible projects without generating plan
- [ ] Mandatory git commit created before directory removal with recovery instructions
- [ ] Directories with uncommitted changes are skipped with warnings
- [ ] `--dry-run` flag shows preview without execution
- [ ] Block 5 displays 4-section console summary with git commit hash
- [ ] Completion signal changed from CLEANUP_PLAN_CREATED to CLEANUP_COMPLETED
- [ ] All library functions follow three-tier sourcing pattern
- [ ] All operations include proper error handling and logging
- [ ] Documentation updated to reflect direct-removal workflow
- [ ] Integration tests verify full cleanup workflow
- [ ] Git recovery tested and documented

## Technical Design

### Architecture Changes

**Remove**: plan-architect agent invocation in Block 4b
**Add**: Direct execution bash logic in Block 4b
**Modify**: Block 5 completion output format
**Add**: Three new library functions in todo-functions.sh

### New Library Functions

**execute_cleanup_removal()**:
- Purpose: Directly remove eligible project directories after git commit
- Arguments: projects_json (JSON array), specs_root (path)
- Returns: 0 on success, 1 on failure
- Operations: Create git commit, verify status, remove directories, log results

**create_cleanup_git_commit()**:
- Purpose: Create pre-cleanup git commit for recovery
- Arguments: None (uses global state)
- Returns: 0 on success, 1 on failure
- Side Effects: Creates git commit with standardized message

**has_uncommitted_changes()**:
- Purpose: Check if directory has uncommitted git-tracked changes
- Arguments: directory path
- Returns: 0 if changes exist, 1 if clean
- Uses: git status --porcelain

### Block Restructuring

**Block 4b** (lines 700-741 in todo.md):
- Replace: Task tool invocation for plan-architect
- Add: Bash block with git commit, verification, removal, state persistence
- State Variables: COMMIT_HASH, REMOVED_COUNT, SKIPPED_COUNT, FAILED_COUNT

**Block 5** (lines 743-819 in todo.md):
- Replace: Plan-based output with execution-based output
- Update: 4-section console summary format
- Change: Completion signal from CLEANUP_PLAN_CREATED to CLEANUP_COMPLETED
- Add: Git commit hash and recovery instructions

### Safety Mechanisms

**Pre-Cleanup Git Commit**:
- Mandatory commit before any directory removal
- Message format: "chore: pre-cleanup snapshot before /todo --clean (N projects)"
- Commit hash logged for recovery reference
- Enables full recovery: git revert <commit-hash>

**Uncommitted Changes Protection**:
- Directory-level checks before removal: git status --porcelain <dir>
- Skip directories with uncommitted changes
- Log warnings for skipped directories
- Allow user to commit and re-run

**Dry-Run Preview** (unchanged):
- --dry-run flag shows eligible projects without execution
- No git commit, no directory removal
- Exit before Block 4b execution

## Implementation Phases

### Phase 1: Library Functions [COMPLETE]
dependencies: []

**Objective**: Create three new library functions for direct cleanup execution

**Complexity**: Low

Tasks:
- [x] Add execute_cleanup_removal() function to todo-functions.sh (lines ~740-800)
  - Accept projects_json and specs_root parameters
  - Implement git commit creation via create_cleanup_git_commit()
  - Iterate over eligible projects from JSON
  - Check uncommitted changes per directory via has_uncommitted_changes()
  - Remove directories with rm -rf (skip if uncommitted changes)
  - Track removal/failure/skip counts
  - Return summary counts
- [x] Add create_cleanup_git_commit() function to todo-functions.sh (lines ~800-830)
  - Stage all changes: git add .
  - Create commit with standardized message
  - Get commit hash: git rev-parse HEAD
  - Log commit hash and recovery command
  - Error handling for git failures
- [x] Add has_uncommitted_changes() function to todo-functions.sh (lines ~830-850)
  - Accept directory path parameter
  - Check directory exists
  - Run git status --porcelain on directory
  - Return 0 if changes exist, 1 if clean
- [x] Update function exports in todo-functions.sh (lines ~884-885)
  - Export execute_cleanup_removal
  - Export create_cleanup_git_commit
  - Export has_uncommitted_changes
- [x] Update SECTION 7 comment block in todo-functions.sh (lines ~713-720)
  - Change description from "Cleanup Plan Generation" to "Cleanup Direct Execution"
  - Remove reference to generate_cleanup_plan()
  - Add references to new functions
- [x] Remove deprecated generate_cleanup_plan() function (lines ~740-863)
  - Delete entire function implementation
  - Clean up any related helper functions

Testing:
```bash
# Unit test new functions
bash /.claude/tests/lib/test_todo_functions_cleanup.sh

# Expected: All 3 new functions pass tests
# - execute_cleanup_removal: removal, skip, failure scenarios
# - create_cleanup_git_commit: commit creation, error handling
# - has_uncommitted_changes: detection, clean directory
```

**Expected Duration**: 1.5 hours

### Phase 2: Block 4b Replacement [COMPLETE]
dependencies: [1]

**Objective**: Replace plan-architect invocation with direct execution bash block

**Complexity**: Medium

Tasks:
- [x] Read current Block 4b implementation in /.claude/commands/todo.md (lines 700-741)
  - Understand plan-architect Task invocation pattern
  - Identify state variables used
  - Note completion signal format
- [x] Replace Block 4b (lines 700-741) with new bash block
  - Add three-tier library sourcing pattern (error-handling.sh, state-persistence.sh, todo-functions.sh)
  - Restore state from latest todo_*.state file
  - Filter eligible projects from CLASSIFIED_RESULTS
  - Display eligible project count
  - Exit early if ELIGIBLE_COUNT = 0
  - Create pre-cleanup git commit with message format
  - Verify git status after commit (warn if uncommitted changes)
  - Iterate over eligible projects for removal
  - Check uncommitted changes per directory (skip if detected)
  - Remove directories with rm -rf
  - Track REMOVED_COUNT, SKIPPED_COUNT, FAILED_COUNT
  - Display removal summary
  - Persist state variables for Block 5: COMMIT_HASH, REMOVED_COUNT, SKIPPED_COUNT, FAILED_COUNT, ELIGIBLE_COUNT
  - Emit checkpoint marker
- [x] Verify bash block structure follows code standards
  - set +H (disable history expansion)
  - set -e (fail-fast)
  - CLAUDE_PROJECT_DIR detection
  - Three-tier library sourcing with fail-fast handlers
  - Error logging for all failures
  - State persistence for cross-block variables
- [x] Test Block 4b in isolation
  - Create mock classified results file
  - Run block with test data
  - Verify git commit created
  - Verify directories removed
  - Verify state persisted

Testing:
```bash
# Integration test Block 4b replacement
bash /.claude/tests/integration/test_todo_clean_block4b.sh

# Expected: Block 4b executes directly without agent invocation
# - Git commit created with correct message
# - Eligible projects removed
# - Uncommitted changes skipped
# - State variables persisted
```

**Expected Duration**: 1.5 hours

### Phase 3: Block 5 Update [COMPLETE]
dependencies: [2]

**Objective**: Update completion output to reflect direct execution workflow

**Complexity**: Low

Tasks:
- [x] Read current Block 5 implementation in /.claude/commands/todo.md (lines 743-819)
  - Understand plan-based output format
  - Identify state variables used
  - Note CLEANUP_PLAN_CREATED signal format
- [x] Replace Block 5 (lines 743-819) with execution-based output
  - Add three-tier library sourcing (error-handling.sh, state-persistence.sh)
  - Restore state from latest todo_*.state file
  - Generate 4-section console summary
    - Summary: "Removed N eligible projects after git commit HASH"
    - Artifacts: Git commit hash, removed/skipped/failed counts
    - Next Steps: Rescan with /todo, git revert recovery, git log review
  - Print standardized summary with cat << EOF
  - Emit CLEANUP_COMPLETED signal with metadata
  - Format: "CLEANUP_COMPLETED: removed=N skipped=N failed=N commit=HASH"
- [x] Update completion signal format
  - Change from CLEANUP_PLAN_CREATED to CLEANUP_COMPLETED
  - Include removal statistics in signal
  - Include git commit hash in signal
- [x] Verify 4-section console summary format
  - Check emoji vocabulary (approved emojis only)
  - Verify artifact section includes git commit hash
  - Verify next steps include recovery instructions
- [x] Test Block 5 with mock state variables
  - Set COMMIT_HASH, REMOVED_COUNT, SKIPPED_COUNT, FAILED_COUNT
  - Run block
  - Verify output format
  - Verify completion signal

Testing:
```bash
# Integration test Block 5 update
bash /.claude/tests/integration/test_todo_clean_block5.sh

# Expected: Block 5 displays execution summary
# - 4-section console summary format
# - Git commit hash in artifacts
# - Recovery instructions in next steps
# - CLEANUP_COMPLETED signal emitted
```

**Expected Duration**: 1 hour

### Phase 4: Documentation Updates [COMPLETE]
dependencies: [3]

**Objective**: Update documentation to reflect direct-removal workflow

**Complexity**: Low

Tasks:
- [x] Update /.claude/commands/todo.md command documentation
  - Line 21: Change Clean Mode description from "generate cleanup plan" to "directly remove projects"
  - Line 35: Remove reference to plan-generation workflow
  - Lines 618-620: Update Clean Mode overview section
  - Add note about git commit recovery mechanism
  - Add note about --dry-run preview as alternative to plan review
- [x] Update /.claude/docs/guides/commands/todo-command-guide.md
  - Lines 98-99: Update Clean Mode workflow description
  - Lines 276-294: Replace "Cleanup Plan Generation" section with "Direct Removal Execution" section
  - Document git commit message format
  - Document uncommitted changes skip behavior
  - Lines 297-337: Update Clean Mode Output Format
  - Change artifacts from plan path to git commit hash
  - Change next steps from /build to /todo rescan
  - Add new "Git Recovery" section with instructions
  - Add examples of git revert recovery workflow
  - Update troubleshooting section
  - Add FAQ: "What if I want to review before cleanup?" → Use --dry-run
  - Add FAQ: "How do I recover removed projects?" → Use git revert
- [x] Update /.claude/lib/todo/README.md (if exists)
  - Update function reference for new functions
  - Remove generate_cleanup_plan() reference
  - Add execute_cleanup_removal() reference
  - Add create_cleanup_git_commit() reference
  - Add has_uncommitted_changes() reference
- [x] Verify all cross-references updated
  - Search for "cleanup plan" references in docs
  - Search for "generate_cleanup_plan" references
  - Update to "direct removal" or "cleanup execution"
- [x] Add git recovery documentation
  - Document git revert workflow
  - Document commit hash location (cleanup output)
  - Provide recovery examples
  - Document edge cases (merge conflicts)

Testing:
```bash
# Validate documentation links and structure
bash /.claude/scripts/validate-readmes.sh
bash /.claude/scripts/validate-links-quick.sh

# Expected: All docs updated, no broken links
```

**Expected Duration**: 1 hour

### Phase 5: Testing and Validation [COMPLETE]
dependencies: [4]

**Objective**: Comprehensive testing of direct-removal workflow

**Complexity**: Medium

Tasks:
- [x] Create unit tests for new library functions
  - test_execute_cleanup_removal() in test_todo_functions_cleanup.sh
    - Test removal of eligible projects
    - Test skip on uncommitted changes
    - Test failure handling
    - Test count tracking
  - test_create_cleanup_git_commit() in test_todo_functions_cleanup.sh
    - Test git commit creation
    - Test commit message format
    - Test commit hash return
    - Test error handling on git failure
  - test_has_uncommitted_changes() in test_todo_functions_cleanup.sh
    - Test detection of modified files
    - Test clean directory returns false
    - Test non-existent directory handling
- [x] Create integration test for full workflow
  - test_todo_clean_workflow() in test_todo_clean_integration.sh
    - Create test project directories (completed, abandoned, superseded, in-progress)
    - Run /todo --clean
    - Verify git commit created with correct message
    - Verify eligible projects removed (completed, abandoned, superseded)
    - Verify in-progress projects NOT removed
    - Verify TODO.md unchanged
    - Verify completion output format
    - Verify CLEANUP_COMPLETED signal
- [x] Create dry-run test
  - test_todo_clean_dry_run() in test_todo_clean_integration.sh
    - Create test project directories
    - Run /todo --clean --dry-run
    - Verify preview displayed with project list
    - Verify no git commit created
    - Verify no directories removed
    - Verify exit before execution
- [x] Create uncommitted changes test
  - test_todo_clean_uncommitted_changes() in test_todo_clean_integration.sh
    - Create test project with uncommitted git-tracked changes
    - Run /todo --clean
    - Verify project skipped with warning
    - Verify warning logged in output
    - Verify other eligible projects removed
    - Verify SKIPPED_COUNT incremented
- [x] Create git recovery test
  - test_git_recovery() in test_todo_clean_integration.sh
    - Run /todo --clean to remove projects
    - Verify projects removed from filesystem
    - Get commit hash from output
    - Run git revert <commit-hash>
    - Verify projects restored to filesystem
    - Verify TODO.md state (unchanged by revert)
- [x] Run full test suite
  - Execute all todo-related tests
  - Verify no regressions in other todo modes (scan, list)
  - Verify compliance with code standards
- [x] Validate error handling
  - Test git commit failure (no git repo)
  - Test directory removal failure (permissions)
  - Test state persistence failure
  - Verify error logging for all failures

Testing:
```bash
# Run unit tests
bash /.claude/tests/lib/test_todo_functions_cleanup.sh

# Run integration tests
bash /.claude/tests/integration/test_todo_clean_integration.sh

# Run full todo test suite
bash /.claude/tests/commands/test_todo_command.sh

# Expected: All tests pass, no regressions
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Testing
- Test each new library function independently
- Mock dependencies (git commands, filesystem operations)
- Verify error handling and edge cases
- Validate return codes and state changes

### Integration Testing
- Test full /todo --clean workflow end-to-end
- Create realistic test project structures
- Verify git commit and recovery mechanisms
- Test dry-run and uncommitted changes scenarios
- Validate completion output format

### Regression Testing
- Run existing todo command tests to ensure no breaking changes
- Verify other todo modes (scan, list) unaffected
- Check compliance with code standards (sourcing, error handling, output formatting)

### Recovery Testing
- Test git revert recovery workflow extensively
- Verify projects restored correctly
- Test edge cases (merge conflicts, detached HEAD)
- Document recovery procedures

### Test Coverage Requirements
- All new functions must have unit tests
- Full workflow must have integration test
- Error paths must be tested
- Recovery mechanism must be tested

## Documentation Requirements

### Command Documentation
- Update /todo --clean description in todo.md
- Document direct-removal workflow
- Document git recovery mechanism
- Update examples and usage patterns

### User Guide
- Update todo-command-guide.md with new workflow
- Add git recovery section
- Update troubleshooting section
- Add FAQ for common questions

### Function Documentation
- Document new library functions in todo-functions.sh
- Include purpose, arguments, returns, side effects
- Provide usage examples
- Document error handling

### Standards Compliance
- Follow documentation standards from CLAUDE.md
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in documentation content
- Update cross-references and navigation links

## Dependencies

### Technical Dependencies
- Git must be available and repository initialized
- todo-analyzer agent must be functional (unchanged)
- State persistence mechanism must work (unchanged)
- Error logging infrastructure must be available

### Workflow Dependencies
- Phase 1 must complete before Phase 2 (library functions needed for Block 4b)
- Phase 2 must complete before Phase 3 (Block 4b state variables needed for Block 5)
- Phase 3 must complete before Phase 4 (implementation must be finalized before documentation)
- Phase 4 must complete before Phase 5 (documentation needed for comprehensive testing)

### External Dependencies
- Git version ≥2.0 (for git status --porcelain)
- Bash version ≥4.0 (for array operations)
- jq for JSON parsing (already required by todo command)

## Risk Mitigation

### Technical Risks
1. **Git commit failure**: Fail-fast, don't proceed with removal, log error
2. **Directory removal failure**: Log failure, continue with other projects, report in summary
3. **Uncommitted changes lost**: Directory-level checks, skip if changes detected
4. **Recovery failure**: Extensive testing of git revert, document edge cases

### Operational Risks
1. **User expects archive directory**: Document git-only recovery, emphasize git history preservation
2. **User expects plan review**: Promote --dry-run preview as alternative, update documentation
3. **Breaking change for automation**: Update completion signal documentation, version notes

### Mitigation Strategies
- Comprehensive testing of git recovery workflow
- Clear documentation of workflow changes
- Dry-run preview as safety mechanism
- Error logging and reporting for troubleshooting
- Fail-fast on critical errors (git commit failure)

## Notes

**Breaking Changes**:
- No cleanup plan generated (plan-architect not invoked)
- No archive/ directory created
- Completion signal changed: CLEANUP_PLAN_CREATED → CLEANUP_COMPLETED

**Migration Path**:
- Users needing plan review should use --dry-run preview
- Users needing archival should manually copy directories before cleanup
- Orchestrators parsing completion signals must update to CLEANUP_COMPLETED

**Standards Compliance**:
- Three-tier library sourcing pattern enforced
- Error handling and logging for all operations
- Output formatting follows 4-section console summary standard
- Clean-break development: no deprecated artifacts or compatibility wrappers
