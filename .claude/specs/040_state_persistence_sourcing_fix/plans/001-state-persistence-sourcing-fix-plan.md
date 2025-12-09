# State Persistence Sourcing Violations Fix Implementation Plan

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix state-persistence sourcing violations in repair.md and todo.md
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours
- **Complexity Score**: 16.5
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [State Persistence Sourcing Violations Analysis](../reports/001-state-persistence-sourcing-fix-analysis.md)

## Overview

This plan addresses mandatory three-tier sourcing pattern violations in two command files (repair.md and todo.md) where bash blocks are missing required Tier 1 library sourcing. The violations cause exit code 127 failures due to subprocess isolation when state persistence functions are called without proper library re-sourcing.

## Research Summary

The research analysis identified critical sourcing violations across 8 bash blocks:

**repair.md violations** (5 blocks):
- Block 1b (lines 387-538): Missing validation-utils.sh and workflow-state-machine.sh
- Block 1c (lines 578-699): Missing state-persistence.sh, workflow-state-machine.sh, and validation-utils.sh (HIGH priority)
- Block 2a-standards (lines 929-1037): Missing workflow-state-machine.sh and validation-utils.sh
- Block 2b (lines 1039-1203): Missing workflow-state-machine.sh and validation-utils.sh
- Block 2c (lines 1264-1386): Missing state-persistence.sh, workflow-state-machine.sh, and validation-utils.sh (HIGH priority)

**todo.md violations** (3 blocks):
- Block 2c (lines 466-621): Missing validation-utils.sh (workflow-state-machine.sh not required for utility commands)
- Block 3 (lines 623-756): Missing validation-utils.sh
- Completion block (lines 1272-1323): Missing error-handling.sh, state-persistence.sh, and validation-utils.sh

All violations stem from subprocess isolation in Claude Code bash execution, where libraries sourced in one block are NOT available in subsequent blocks. The three-tier sourcing pattern with fail-fast handlers is mandatory per code-standards.md lines 34-89.

## Success Criteria

- [x] All 8 bash blocks include complete Tier 1 sourcing pattern (state-persistence.sh, workflow-state-machine.sh, error-handling.sh, validation-utils.sh)
- [x] Pre-commit linter (check-library-sourcing.sh) reports zero violations
- [x] repair.md executes successfully without exit code 127 errors
- [x] todo.md executes successfully without exit code 127 errors
- [x] All state persistence function calls succeed with proper library context

## Technical Design

### Architecture Overview

The fix follows the mandatory three-tier sourcing pattern defined in code-standards.md:

**Tier 1 Libraries (fail-fast required)**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2
  exit 1
}
```

**Special Case: todo.md (Utility Command)**

todo.md is classified as a utility command (not workflow orchestration), so workflow-state-machine.sh is NOT required per research finding line 199. The pattern for todo.md blocks:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2
  exit 1
}
```

### Block-Specific Fix Strategy

**repair.md fixes** (Priority: HIGH for blocks 1c and 2c):
1. Block 1b: Add workflow-state-machine.sh and validation-utils.sh to existing sourcing section
2. Block 1c: Add complete Tier 1 sourcing pattern (currently only has error-handling.sh)
3. Block 2a-standards: Add workflow-state-machine.sh and validation-utils.sh to existing sourcing section
4. Block 2b: Add workflow-state-machine.sh and validation-utils.sh to existing sourcing section
5. Block 2c: Add complete Tier 1 sourcing pattern (currently only has error-handling.sh)

**todo.md fixes** (Priority: MEDIUM - utility command pattern):
1. Block 2c: Add validation-utils.sh to existing sourcing section
2. Block 3: Add validation-utils.sh to existing sourcing section
3. Completion block: Add complete Tier 1 sourcing pattern (utility variant - no workflow-state-machine.sh)

### Validation Strategy

1. **Pre-commit linter validation**: Run check-library-sourcing.sh to verify zero violations
2. **Runtime testing**: Execute both commands with typical workflows to ensure no exit code 127 errors
3. **Function call verification**: Confirm all state persistence function calls succeed

## Implementation Phases

### Phase 1: Fix repair.md Sourcing Violations [COMPLETE]
dependencies: []

**Objective**: Add missing Tier 1 libraries to all 5 violated blocks in repair.md

**Complexity**: Medium

**Tasks**:
- [ ] Fix Block 1b (lines 387-538): Add workflow-state-machine.sh and validation-utils.sh sourcing after existing libraries
- [ ] Fix Block 1c (lines 578-699): Add state-persistence.sh, workflow-state-machine.sh, and validation-utils.sh sourcing (HIGH priority - complete Tier 1 pattern missing)
- [ ] Fix Block 2a-standards (lines 929-1037): Add workflow-state-machine.sh and validation-utils.sh sourcing after existing libraries
- [ ] Fix Block 2b (lines 1039-1203): Add workflow-state-machine.sh and validation-utils.sh sourcing after existing libraries
- [ ] Fix Block 2c (lines 1264-1386): Add state-persistence.sh, workflow-state-machine.sh, and validation-utils.sh sourcing (HIGH priority - complete Tier 1 pattern missing)

**Testing**:
```bash
# Verify linter detects no violations in repair.md
bash /home/benjamin/.config/.claude/scripts/lint/check-library-sourcing.sh /home/benjamin/.config/.claude/commands/repair.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Runtime test: Execute repair command with typical workflow
cd /home/benjamin/.config
/repair --type state_error --complexity 2 --dry-run
EXIT_CODE=$?
test $EXIT_CODE -ne 127 || exit 1

echo "✓ repair.md sourcing violations fixed"
```

**Validation**:
- All 5 blocks include complete Tier 1 sourcing pattern
- Linter reports zero violations for repair.md
- No exit code 127 errors during repair.md execution
- All append_workflow_state and save_completed_states_to_state calls succeed

**Expected Duration**: 1.5 hours

### Phase 2: Fix todo.md Sourcing Violations [COMPLETE]
dependencies: [1]

**Objective**: Add missing Tier 1 libraries to all 3 violated blocks in todo.md (utility command pattern - no workflow-state-machine.sh)

**Complexity**: Low

**Tasks**:
- [ ] Fix Block 2c (lines 466-621): Add validation-utils.sh sourcing after existing libraries
- [ ] Fix Block 3 (lines 623-756): Add validation-utils.sh sourcing after existing libraries
- [ ] Fix Completion block (lines 1272-1323): Add complete Tier 1 sourcing pattern for utility commands (error-handling.sh, state-persistence.sh, validation-utils.sh - no workflow-state-machine.sh)

**Testing**:
```bash
# Verify linter detects no violations in todo.md
bash /home/benjamin/.config/.claude/scripts/lint/check-library-sourcing.sh /home/benjamin/.config/.claude/commands/todo.md
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Runtime test: Execute todo command with typical workflows
cd /home/benjamin/.config
/todo
EXIT_CODE=$?
test $EXIT_CODE -ne 127 || exit 1

/todo --clean --dry-run
EXIT_CODE=$?
test $EXIT_CODE -ne 127 || exit 1

echo "✓ todo.md sourcing violations fixed"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["linter-output.txt"]

**Validation**:
- All 3 blocks include appropriate Tier 1 sourcing pattern (utility command variant)
- Linter reports zero violations for todo.md
- No exit code 127 errors during todo.md execution
- All state persistence function calls succeed

**Expected Duration**: 0.5 hours

### Phase 3: Validation and Documentation [COMPLETE]
dependencies: [1, 2]

**Objective**: Verify all fixes with comprehensive linter and runtime testing, update documentation

**Complexity**: Low

**Tasks**:
- [ ] Run unified validation script on both files: `bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --sourcing`
- [ ] Verify zero ERROR-level violations in validation output
- [ ] Execute repair.md with multiple test scenarios (state_error, validation_error, agent_error types)
- [ ] Execute todo.md with multiple test scenarios (default mode, --clean, --dry-run)
- [ ] Update research report Implementation Status section with plan completion
- [ ] Verify pre-commit hook integration blocks future violations

**Testing**:
```bash
# Unified validation across all commands
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --sourcing
EXIT_CODE=$?
test $EXIT_CODE -eq 0 || exit 1

# Comprehensive repair.md runtime testing
/repair --type state_error --complexity 2 --dry-run
test $? -ne 127 || exit 1

/repair --since 1h --complexity 2 --dry-run
test $? -ne 127 || exit 1

# Comprehensive todo.md runtime testing
/todo
test $? -ne 127 || exit 1

/todo --clean --dry-run
test $? -ne 127 || exit 1

echo "✓ All sourcing violations fixed and validated"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["validation-report.txt", "test-results.log"]

**Validation**:
- Unified validation script reports zero sourcing violations
- All repair.md test scenarios execute without exit code 127
- All todo.md test scenarios execute without exit code 127
- Pre-commit hook correctly blocks violations in future commits
- Research report updated with implementation status

**Expected Duration**: 1 hour

## Testing Strategy

### Linter Validation

The pre-commit linter (check-library-sourcing.sh) enforces three-tier sourcing pattern compliance. All fixes will be validated using:

```bash
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/repair.md
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/todo.md
bash .claude/scripts/validate-all-standards.sh --sourcing
```

Expected output: Zero ERROR-level violations

### Runtime Testing

Execute both commands with typical workflows to verify no exit code 127 errors:

**repair.md test scenarios**:
- `/repair --type state_error --complexity 2`
- `/repair --since 1h --complexity 2`
- `/repair --command /implement --complexity 3`

**todo.md test scenarios**:
- `/todo` (default mode)
- `/todo --clean` (cleanup mode)
- `/todo --dry-run` (preview mode)

### Success Criteria Verification

- No exit code 127 ("command not found") errors in any test scenario
- All state persistence function calls (append_workflow_state, save_completed_states_to_state) succeed
- Linter validation passes with zero violations
- Pre-commit hooks block future violations

## Documentation Requirements

### Research Report Update

Update the research report Implementation Status section:

File: `/home/benjamin/.config/.claude/specs/040_state_persistence_sourcing_fix/reports/001-state-persistence-sourcing-fix-analysis.md`

Add implementation status section:
```markdown
## Implementation Status
- **Status**: Implementation Complete
- **Plan**: [../plans/001-state-persistence-sourcing-fix-plan.md](../plans/001-state-persistence-sourcing-fix-plan.md)
- **Date**: 2025-12-09
- **Validation**: All 8 bash blocks fixed, linter reports zero violations
```

### No Additional Documentation Needed

No updates to CLAUDE.md required - this fix enforces existing standards rather than changing them. The code-standards.md three-tier sourcing pattern remains unchanged.

## Dependencies

### External Dependencies
- None (internal refactoring only)

### Prerequisites
- Access to .claude/commands/repair.md (exists)
- Access to .claude/commands/todo.md (exists)
- Access to linter: .claude/scripts/lint/check-library-sourcing.sh (exists)
- Access to unified validator: .claude/scripts/validate-all-standards.sh (exists)

### Integration Points
- Pre-commit hook integration (validate-all-standards.sh sourcing validation)
- Error handling library (error-handling.sh)
- State persistence library (state-persistence.sh)
- Workflow state machine library (workflow-state-machine.sh)
- Validation utilities library (validation-utils.sh)

## Risk Management

### Technical Risks

**Risk 1: Breaking existing command functionality**
- Mitigation: Test all command workflows before/after changes
- Rollback: Git reset to pre-fix commit if failures occur

**Risk 2: Linter false positives after fix**
- Mitigation: Verify linter expectations match code-standards.md
- Fallback: Adjust sourcing pattern based on linter feedback

**Risk 3: Utility command pattern ambiguity**
- Mitigation: Document todo.md as utility command (no workflow-state-machine.sh)
- Verification: Confirm with code-standards.md maintainer if unclear

### Rollback Strategy

All changes are additive (adding missing sourcing statements) with no breaking changes to existing logic. Rollback via git revert if unexpected issues occur:

```bash
git diff HEAD -- .claude/commands/repair.md .claude/commands/todo.md
git checkout HEAD -- .claude/commands/repair.md .claude/commands/todo.md
```
