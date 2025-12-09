# TODO.md Standards Multi-File Tracking Implementation Plan

## Metadata

- **Date**: 2025-12-08
- **Feature**: Extend /todo command to support multi-file TODO.md tracking via CLAUDE.md standards discovery
- **Status**: [NOT STARTED]
- **Estimated Hours**: 10-14 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [TODO.md Standards Multi-File Tracking Analysis](../reports/001-todo-standards-multifile-analysis.md)

## Overview

The /todo command currently updates only `.claude/TODO.md` by scanning `.claude/specs/` directories. This plan extends the command to discover and update additional TODO.md files declared in subdirectory CLAUDE.md files, enabling multi-file task tracking across the project while maintaining backward compatibility.

## Research Summary

Key findings from research analysis:

- **Current Architecture**: Single-file workflow hard-coded to `.claude/TODO.md` with 7-section hierarchy
- **Discovery Pattern**: Project already implements standards discovery via upward CLAUDE.md search for commands
- **Use Cases**: Subdirectories like `nvim/` have their own TODO.md files that need tracking (e.g., `nvim/lua/neotex/plugins/tools/himalaya/TODO.md`)
- **Standards Section**: CLAUDE.md contains 'TODO.md Standards' section (lines 361-370) that can be extended for multi-file declarations
- **Backward Compatibility**: Zero-impact design - existing single-file workflow unchanged if no subdirectory declarations exist

Recommended approach: Extend existing standards discovery pattern to parse 'TODO.md Standards' sections in subdirectory CLAUDE.md files, discovering TODO.md file locations, update methods (auto/script/manual), and scan scopes.

## Success Criteria

- [ ] /todo command discovers all TODO.md files declared in subdirectory CLAUDE.md files
- [ ] Primary .claude/TODO.md update behavior unchanged (existing tests pass)
- [ ] Subdirectory TODO.md files updated based on declared update method (auto/script)
- [ ] Manual TODO.md files (marked "manual") are skipped during auto-updates
- [ ] Backlog and Saved sections preserved in all TODO.md files
- [ ] Update script failures handled gracefully (log error, skip file, continue with others)
- [ ] Git snapshot created for all modified TODO.md files
- [ ] Integration tests verify multi-file discovery and update workflow
- [ ] Documentation updated with multi-file usage examples and subdirectory CLAUDE.md syntax

## Technical Design

### Architecture Extension

The implementation extends the existing /todo command with a multi-file discovery layer:

**Current Flow**:
```
Block 1: Scan .claude/specs/ → Block 2a-2c: Classify (agent) → Block 3: Write .claude/TODO.md
```

**Extended Flow**:
```
Block 1: Multi-File Discovery + Scan specs → Block 2a-2c: Classify (agent) → Block 3a: Write .claude/TODO.md → Block 3b: Write Subdirectory TODO.md Files
```

### Multi-File Discovery Algorithm

Discovery function (`discover_todo_files()`) parses CLAUDE.md files:

1. Start with primary `.claude/TODO.md:auto:specs/:.claude/lib/todo/generate-main-todo.sh`
2. Find all subdirectory CLAUDE.md files (excluding `.claude/` itself)
3. For each CLAUDE.md, check for `### TODO.md Standards` section
4. Extract metadata fields:
   - **File Location**: Relative path to TODO.md file from project root
   - **Update Method**: `auto`, `script`, or `manual`
   - **Scan Scope**: Directories to scan for tasks
   - **Script** (if method=script): Path to custom update script
5. Validate paths (must be relative, under project root, no `..` escapes)
6. Skip files marked "manual"
7. Return array of entries: `file:method:scope:script`

### Subdirectory CLAUDE.md Format

Subdirectory CLAUDE.md files declare TODO.md tracking in the 'TODO.md Standards' section:

```markdown
### TODO.md Standards
[Used by: /todo]

**File Location**: nvim/TODO.md
**Update Method**: auto
**Scan Scope**: nvim/lua/neotex/plugins/
**Format**: inherit

This TODO.md tracks Neovim plugin tasks. The /todo command auto-updates this file by scanning nvim/lua/neotex/plugins/ and generating entries in the standard 7-section hierarchy.

**Preservation**:
- Backlog section manually curated (preserved across updates)
- Completed section uses date grouping (newest first)
```

**Update Methods**:
- `auto`: Use default 7-section generation (reuse existing todo-analyzer logic)
- `script`: Invoke custom update script with signature: `bash script.sh <file> <scope>`
- `manual`: Skip during /todo execution (user updates manually)

### Update Delegation Logic

Function `update_subdirectory_todo()` processes each discovered TODO.md:

1. If `method=auto`: Invoke todo-analyzer agent with subdirectory scope
2. If `method=script`: Execute script with file path and scope arguments
3. If `method=manual`: Skip (logged but not updated)
4. Preserve Backlog/Saved sections from current TODO.md (if exists)
5. Write generated content to file
6. On error: Log to error log, skip file, continue with remaining files

### Error Handling

- **Script Validation**: Verify script paths are relative, under project root, executable, and end in `.sh`
- **Circular References**: Track visited TODO.md paths to detect circular references
- **Path Escapes**: Reject paths containing `..` or absolute paths outside project
- **Update Failures**: Log to centralized error log, skip failed file, report in completion summary
- **Git Snapshot**: Extend existing git snapshot mechanism to cover all TODO.md files

### Backward Compatibility

Zero-impact design ensures existing workflows continue unchanged:

- If no subdirectory CLAUDE.md files declare TODO.md standards, behavior identical to current
- Primary `.claude/TODO.md` update uses existing logic (7-section generation via todo-analyzer)
- Existing command interface unchanged (no new required arguments)
- All current tests pass without modification

## Implementation Phases

### Phase 1: Discovery Infrastructure [NOT STARTED]
dependencies: []

**Objective**: Add multi-file discovery function without changing update logic

**Complexity**: Low

**Tasks**:
- [ ] Create `discover_todo_files()` function in `.claude/lib/todo/todo-functions.sh`
  - Parse subdirectory CLAUDE.md files for 'TODO.md Standards' sections
  - Extract metadata fields (File Location, Update Method, Scan Scope, Script)
  - Validate paths (relative, under project root, no escapes)
  - Return array of `file:method:scope:script` entries
- [ ] Add `validate_todo_path()` function for security checks
  - Reject absolute paths outside project root
  - Reject paths with `..` components
  - Verify file locations are under `CLAUDE_PROJECT_DIR`
- [ ] Add `validate_update_script()` function for script validation
  - Verify script paths are relative and under project root
  - Verify scripts have `.sh` extension
  - Verify scripts are executable
  - Reject paths with `..` components
- [ ] Update Block 1 in `/todo` command to call discovery function
  - Call `discover_todo_files()` after existing specs scan
  - Store discovered TODO.md files in state machine
  - Log count of discovered TODO.md files (primary + subdirectories)
- [ ] Pass discovered files to existing classification logic (no changes to Block 2)

**Testing**:
```bash
# Test discovery with no subdirectory CLAUDE.md files (backward compatibility)
bash .claude/tests/unit/test_todo_discovery.sh test_single_file_discovery

# Test discovery with mock subdirectory CLAUDE.md
bash .claude/tests/unit/test_todo_discovery.sh test_multi_file_discovery

# Test manual file skipping
bash .claude/tests/unit/test_todo_discovery.sh test_skip_manual_files

# Test path validation security
bash .claude/tests/unit/test_todo_discovery.sh test_path_validation
```

**Expected Duration**: 3-4 hours

---

### Phase 2: Update Delegation [NOT STARTED]
dependencies: [1]

**Objective**: Implement subdirectory TODO.md update logic with error handling

**Complexity**: Medium

**Tasks**:
- [ ] Create `update_subdirectory_todo()` function in todo-functions.sh
  - Implement `auto` method: reuse existing todo-analyzer logic with subdirectory scope
  - Implement `script` method: execute custom script with file path and scope arguments
  - Skip `manual` method with log message
  - Preserve Backlog/Saved sections from current TODO.md (if exists)
  - Write generated content to file atomically
- [ ] Add Block 3b to /todo command for subdirectory updates
  - Call `update_subdirectory_todo()` for each non-manual TODO.md file
  - Capture update results (success/skip/failure counts)
  - Continue processing on individual file failures
- [ ] Implement error handling for update failures
  - Log errors to centralized error log via `log_command_error()`
  - Skip failed file and continue with remaining files
  - Report skipped files in completion summary
- [ ] Add `SKIPPED_FILES` array to state persistence
  - Track files that failed to update
  - Include in completion summary and next steps

**Testing**:
```bash
# Test auto method (inherit format)
bash .claude/tests/integration/test_todo_multifile.sh test_auto_update

# Test script method (custom update script)
bash .claude/tests/integration/test_todo_multifile.sh test_script_update

# Test manual method skipping
bash .claude/tests/integration/test_todo_multifile.sh test_manual_skip

# Test error handling (broken script)
bash .claude/tests/integration/test_todo_multifile.sh test_update_failure

# Test Backlog preservation in subdirectory
bash .claude/tests/integration/test_todo_multifile.sh test_backlog_preservation
```

**Expected Duration**: 4-5 hours

---

### Phase 3: Git Snapshot Extension [NOT STARTED]
dependencies: [2]

**Objective**: Extend git snapshot mechanism to cover all TODO.md files

**Complexity**: Low

**Tasks**:
- [ ] Create `snapshot_all_todo_files()` function in todo-functions.sh
  - Collect all TODO.md files (primary + subdirectories)
  - Filter to files with uncommitted changes
  - Stage all modified files together
  - Create single commit with workflow context
- [ ] Update Block 3 in /todo command to use new snapshot function
  - Replace existing `.claude/TODO.md` snapshot with multi-file snapshot
  - Include all TODO.md files in git add command
  - Update commit message to list all files
- [ ] Add recovery instructions to completion summary
  - Show commit hash for rollback
  - List all TODO.md files included in snapshot

**Testing**:
```bash
# Test snapshot with multiple TODO.md files
bash .claude/tests/integration/test_todo_multifile.sh test_multi_file_snapshot

# Test snapshot skips committed files
bash .claude/tests/integration/test_todo_multifile.sh test_skip_committed

# Test recovery instructions in output
bash .claude/tests/integration/test_todo_multifile.sh test_recovery_instructions
```

**Expected Duration**: 2-3 hours

---

### Phase 4: Standards Documentation [NOT STARTED]
dependencies: [3]

**Objective**: Document multi-file tracking in CLAUDE.md and standards files

**Complexity**: Low

**Tasks**:
- [ ] Update root CLAUDE.md 'TODO.md Standards' section (lines 361-370)
  - Add **Multi-File Tracking** subsection
  - Document subdirectory CLAUDE.md declaration syntax
  - List standard metadata fields (File Location, Update Method, Scan Scope, Script)
  - Provide update method descriptions (auto/script/manual)
- [ ] Update `.claude/docs/reference/standards/todo-organization-standards.md`
  - Add **Multi-File Discovery** section
  - Document discovery algorithm and subdirectory CLAUDE.md format
  - Include security considerations (path validation, script execution)
  - Provide example subdirectory CLAUDE.md files
- [ ] Update `.claude/docs/guides/commands/todo-command-guide.md`
  - Add **Multi-File Usage** section with workflow examples
  - Document Use Case 1: Himalaya Plugin Development
  - Document Use Case 2: Documentation Task Tracking
  - Show before/after command outputs
- [ ] Create validation script: `.claude/scripts/validate-todo-declarations.sh`
  - Verify subdirectory CLAUDE.md files have valid TODO.md Standards sections
  - Check required metadata fields are present
  - Validate paths are relative and under project root
  - Check update scripts exist and are executable
- [ ] Add validation to pre-commit hook (optional)
  - Run `validate-todo-declarations.sh` on staged CLAUDE.md files
  - Warn (not error) on invalid TODO.md declarations

**Testing**:
```bash
# Validate documentation examples match implementation
bash .claude/scripts/validate-todo-declarations.sh --check-examples

# Test validation script on example subdirectory CLAUDE.md files
bash .claude/tests/integration/test_todo_validation.sh test_valid_declaration
bash .claude/tests/integration/test_todo_validation.sh test_invalid_path
bash .claude/tests/integration/test_todo_validation.sh test_missing_script

# Check link validity in updated documentation
bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/todo-organization-standards.md
bash .claude/scripts/validate-links-quick.sh .claude/docs/guides/commands/todo-command-guide.md
```

**Expected Duration**: 2-3 hours

---

### Phase 5: Integration Testing and Validation [NOT STARTED]
dependencies: [4]

**Objective**: Comprehensive end-to-end testing and validation of multi-file workflow

**Complexity**: Medium

**Tasks**:
- [ ] Create comprehensive integration test suite in `.claude/tests/integration/test_todo_command_multifile.sh`
  - Test backward compatibility (no subdirectory declarations)
  - Test single subdirectory TODO.md (auto method)
  - Test multiple subdirectory TODO.md files
  - Test mixed update methods (auto/script/manual)
  - Test error recovery (script failure, invalid paths)
  - Test git snapshot with multiple files
  - Test Backlog/Saved preservation across all files
- [ ] Run existing /todo test suite to verify backward compatibility
  - All existing tests must pass unchanged
  - No regressions in primary .claude/TODO.md workflow
- [ ] Manual testing with real subdirectory (nvim/)
  - Create nvim/CLAUDE.md with TODO.md Standards section
  - Run /todo and verify nvim/TODO.md created/updated
  - Manually edit nvim/TODO.md Backlog section
  - Run /todo again and verify Backlog preserved
  - Change to manual method and verify no updates
- [ ] Dry-run mode testing
  - Test /todo --dry-run with subdirectory declarations
  - Verify preview shows all TODO.md files to be updated
  - Verify no files modified during dry-run
- [ ] Performance testing
  - Measure overhead of multi-file discovery (should be <100ms)
  - Verify no impact on single-file workflow performance

**Testing**:
```bash
# Run comprehensive integration test suite
bash .claude/tests/integration/test_todo_command_multifile.sh

# Run existing test suite (backward compatibility)
bash .claude/tests/integration/test_todo_command.sh

# Manual test checklist (see manual testing checklist below)
bash .claude/tests/manual/test_todo_multifile_manual.sh
```

**Manual Testing Checklist**:
```markdown
- [ ] Run /todo with no subdirectory CLAUDE.md files (backward compatibility)
- [ ] Add nvim/CLAUDE.md with TODO.md Standards (File Location: nvim/TODO.md, Update Method: auto)
- [ ] Run /todo, verify nvim/TODO.md created with 7-section hierarchy
- [ ] Manually edit nvim/TODO.md Backlog section
- [ ] Run /todo again, verify Backlog preserved
- [ ] Change Update Method to "manual" in nvim/CLAUDE.md
- [ ] Run /todo, verify nvim/TODO.md not modified
- [ ] Create custom update script, configure "script" method
- [ ] Run /todo, verify script invoked and nvim/TODO.md updated
- [ ] Introduce script error (exit 1)
- [ ] Run /todo, verify error logged and nvim/TODO.md skipped
- [ ] Run /todo --dry-run, verify preview shows all TODO.md files to be updated
```

**Expected Duration**: 3-4 hours

---

## Testing Strategy

### Unit Tests

**File**: `.claude/tests/unit/test_todo_multifile.sh`

Focus: Discovery algorithm, path validation, security checks

```bash
# Discovery tests
test_discover_single_todo_file()
test_discover_multiple_todo_files()
test_skip_manual_todo_files()
test_parse_metadata_fields()

# Validation tests
test_validate_script_path_security()
test_validate_todo_path_relative()
test_validate_todo_path_escape_attempt()
test_circular_reference_detection()
```

### Integration Tests

**File**: `.claude/tests/integration/test_todo_command_multifile.sh`

Focus: End-to-end multi-file workflow, error handling, preservation

```bash
# Multi-file workflow tests
test_todo_updates_all_declared_files()
test_todo_preserves_backlog_in_subdirectory()
test_todo_skips_manual_files()
test_todo_skips_failed_updates()

# Error handling tests
test_broken_script_handling()
test_invalid_path_handling()
test_missing_metadata_handling()

# Git snapshot tests
test_multi_file_git_snapshot()
test_snapshot_includes_all_files()
test_recovery_instructions()
```

### Manual Testing

Pilot implementation with `nvim/` subdirectory TODO.md to validate real-world usage:

1. Create `nvim/CLAUDE.md` with TODO.md Standards section
2. Run /todo and verify nvim/TODO.md generated
3. Test Backlog preservation across updates
4. Switch to manual method and verify skipping
5. Test custom script method (if needed)

### Test Coverage Requirements

- Unit test coverage: >90% of new functions (discover_todo_files, validate_*, update_subdirectory_todo)
- Integration test coverage: 100% of user-facing workflows (auto/script/manual update methods)
- Backward compatibility: 100% of existing /todo tests pass unchanged

## Documentation Requirements

### Files to Update

1. **CLAUDE.md** (root):
   - Update `TODO.md Standards` section (lines 361-370)
   - Add Multi-File Tracking subsection
   - Document subdirectory CLAUDE.md syntax

2. **.claude/docs/reference/standards/todo-organization-standards.md**:
   - Add Multi-File Discovery section
   - Document metadata fields and update methods
   - Include security considerations

3. **.claude/docs/guides/commands/todo-command-guide.md**:
   - Add Multi-File Usage section
   - Provide use case examples (Himalaya plugin, docs tracking)
   - Show before/after command outputs

4. **.claude/docs/guides/development/custom-todo-scripts.md** (new file):
   - Document custom script interface contract
   - Provide script template and examples
   - Describe script input/output format

### Documentation Standards Compliance

- Use clear, concise language per documentation policy
- Include code examples with syntax highlighting
- Follow CommonMark specification
- No emojis in file content (UTF-8 encoding issues)
- Update documentation with code changes (keep examples current)
- Link to related standards documents

## Dependencies

### External Dependencies
- None (uses existing project libraries and tools)

### Internal Dependencies
- `todo-functions.sh`: Existing library extended with new functions
- `todo-analyzer` agent: Reused for auto-update method
- `error-handling.sh`: Used for centralized error logging
- `state-persistence.sh`: Used for state management across blocks

### Integration Points
- `/todo` command: Extended with multi-file discovery and update blocks
- CLAUDE.md standards discovery: Leverages existing upward search pattern
- Git snapshot mechanism: Extended to cover multiple TODO.md files

## Security Considerations

### Path Validation

All TODO.md file paths and update script paths validated to prevent:
- Absolute path escapes outside project root
- Relative path escapes using `..` components
- Symbolic link attacks
- Access to sensitive system files

### Script Execution Safety

Update scripts validated before execution:
- Must be relative path under project root
- Must have `.sh` extension
- Must be marked executable
- Cannot contain `..` path components
- Executed with project root as working directory

### Git Snapshot Coverage

All TODO.md files protected with git snapshot before updates:
- Single commit covers all modified files
- Commit message includes workflow context
- Recovery command provided in completion summary

## Risk Management

### Technical Risks

1. **Backward Compatibility Break**: Existing /todo workflow broken by changes
   - **Mitigation**: Zero-impact design, comprehensive test suite, phased deployment

2. **Performance Degradation**: Multi-file discovery adds latency
   - **Mitigation**: Discovery function optimized (<100ms overhead), lazy evaluation

3. **Update Script Failures**: Custom scripts crash or produce invalid output
   - **Mitigation**: Script validation, error isolation, graceful degradation

### Migration Risks

1. **Existing TODO.md Files**: Users with manual TODO.md files in subdirectories
   - **Mitigation**: Manual update method allows opt-out, migration is optional

2. **Format Divergence**: Different TODO.md formats conflict over time
   - **Mitigation**: Document format specifications, provide validation scripts

## Rollback Plan

If issues arise after deployment:

1. **Immediate Rollback**: Revert commits from Phase 1-5
2. **Git Recovery**: `git revert <commit-hash>` to restore previous /todo command
3. **TODO.md Restoration**: `git checkout <snapshot-commit> -- .claude/TODO.md`
4. **Debug Logs**: Query error log: `/errors --command /todo --since 1h`
5. **User Communication**: Update CLAUDE.md with rollback notice if needed

## Success Metrics

- Zero regressions in existing /todo test suite
- Multi-file discovery completes in <100ms
- Update success rate >99% (excluding intentional manual skips)
- Documentation passes link validation
- Integration test suite passes on all scenarios
- Manual pilot test with nvim/ subdirectory successful

## Alternative Approaches Considered

### Alternative 1: Git Submodule per Subdirectory
**Rejected**: Massive restructuring effort, breaks cross-references, complicates unified management

### Alternative 2: Unified TODO.md Format Enforcement
**Rejected**: Breaks existing formats (e.g., himalaya phase-based tracking), limits flexibility

### Alternative 3: TODO.md Symlinks
**Rejected**: Confusing UX (nvim/TODO.md shows all .claude/specs/ projects), doesn't solve format divergence

### Recommended Approach: Multi-File Discovery (This Plan)
**Selected**: Minimal code changes, backward compatible, flexible update methods, aligns with existing standards discovery pattern
