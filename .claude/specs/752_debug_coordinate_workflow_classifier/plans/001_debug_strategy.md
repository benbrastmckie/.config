# Debug Strategy Plan: Coordinate Command Workflow Classifier State Persistence

## Metadata
- **Date**: 2025-11-17
- **Feature**: Fix workflow classifier state persistence in coordinate command
- **Scope**: Resolve state persistence failures, enhance diagnostics, improve architecture
- **Estimated Phases**: 12
- **Estimated Hours**: 3.3 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001_root_cause_analysis.md)
  - [Standards Compliance Analysis](../reports/001_standards_compliance.md)

## Plan Metadata

**Complexity Analysis**:
- Tasks: 22 (across all phases)
- Phases: 12 (structured below)
- Estimated Hours: 3.3 hours
- Dependencies: 8
- Complexity Score: (22 × 1.0) + (12 × 5.0) + (3.3 × 0.5) + (8 × 2.0) = 100.65
- Tier: Tier 2 (50 ≤ score < 200)
- Structure Level: L0 (single file)

**Structure Decision**:
- Tier 2 complexity (score 100.65) suggests L1 structure
- However, using L0 (single file) because:
  - Short implementation duration (3.3 hours)
  - Tight coupling between phases (sequential dependencies)
  - Debugging context benefits from seeing full strategy
  - No phases exceed expansion threshold
- L0 structure appropriate for this debug fix despite Tier 2 score

## Executive Summary

This debug strategy addresses critical failures in the `/coordinate` command's Phase 0.1 (Workflow Classification) where the workflow-classifier agent fails to persist the `CLASSIFICATION_JSON` variable to workflow state. The root cause is an architectural mismatch: the agent is configured with `allowed-tools: None` but instructed to execute bash commands for state persistence, which is impossible.

**Strategy Overview**: Implement 12 phases starting with critical fixes (P0 priority) to restore functionality, followed by enhanced diagnostics (P1), architectural improvements (P2), and testing/workflow integration.

**Expected Outcome**: Complete resolution of state persistence failures with improved error diagnostics, long-term maintainability, and full standards compliance.

## Research Summary

Based on the root cause analysis and standards compliance research:

**Root Cause**: The workflow-classifier agent is configured with `allowed-tools: None` but instructed to execute bash commands for state persistence. Task tool execution isolation prevents environment variable transfer, so the agent cannot save CLASSIFICATION_JSON to the parent workflow state.

**Standards Compliance Gaps**: The original plan structure used nested priority levels (P0/P1/P2) instead of flat numbered phases, missing phase dependencies for wave-based execution, lacking adaptive planning metadata, and incomplete testing protocol integration.

**Recommended Approach**: Restructure to flat phases with dependencies, move state persistence from agent to coordinate command, enhance diagnostics with variable validation, and integrate long-term improvements for maintainability.

## Success Criteria

- [ ] Coordinate command completes Phase 0.1 without state persistence errors
- [ ] CLASSIFICATION_JSON successfully saved to workflow state
- [ ] State loading validation provides clear diagnostics on failures
- [ ] Agent behavioral file no longer contains contradictory instructions
- [ ] All test suites pass (unit, integration, regression)
- [ ] Documentation updated with Task tool isolation patterns
- [ ] Agent validator detects behavioral file contradictions
- [ ] State file locations standardized across codebase
- [ ] Full compliance with directory protocols and testing standards

## Technical Design

**Architecture Changes**:
1. **Agent Simplification**: workflow-classifier.md becomes pure classification (no state persistence)
2. **Command Responsibility**: coordinate.md extracts classification from Task output and saves to state
3. **Enhanced Diagnostics**: load_workflow_state() validates required variables exist
4. **Structured Persistence**: Migrate from bash exports to JSON checkpoints for classification data
5. **Validation Tooling**: Agent behavioral file validator prevents future contradictions

**Execution Flow** (Post-Fix):
```
Phase 0.1: Workflow Classification
├─ coordinate.md invokes workflow-classifier via Task tool
├─ Agent returns: CLASSIFICATION_COMPLETE: {JSON}
├─ coordinate.md bash block extracts JSON from Task output
├─ Validates JSON with jq
├─ Saves to state: append_workflow_state "CLASSIFICATION_JSON" "$JSON"
└─ Verifies saved: load_workflow_state with validation
```

## Implementation Phases

### Phase 1: Remove State Persistence from Workflow Classifier Agent

**Dependencies**: []
**Priority**: P0 (Critical)
**Risk**: Low
**Estimated Time**: 15 minutes

**Objective**: Remove contradictory bash execution instructions from agent behavioral file

**Tasks**:
- [x] Delete lines 530-587 from `/home/benjamin/.config/.claude/agents/workflow-classifier.md`
- [x] Update agent description to clarify classification-only role
- [x] Remove all bash code blocks from agent file
- [x] Verify agent file no longer contains "USE the Bash tool" instructions

**Files Modified**:
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

**Testing**:
```bash
# Verify agent file has no bash execution instructions
grep -c "USE the Bash tool" /home/benjamin/.config/.claude/agents/workflow-classifier.md
# Expected: 0

grep -c '```bash' /home/benjamin/.config/.claude/agents/workflow-classifier.md
# Expected: 0
```

**Success Criteria**:
- Agent file no longer contains bash execution instructions
- Agent description updated to reflect classification-only role
- frontmatter `allowed-tools: None` consistent with file contents

### Phase 2: Update Coordinate Command to Extract and Save Classification

**Dependencies**: [1]
**Priority**: P0 (Critical)
**Risk**: Low
**Estimated Time**: 30 minutes

**Objective**: Move state persistence to coordinate.md where it can execute in parent context

**Tasks**:
- [ ] Add bash block in coordinate.md immediately after Task tool invocation (after line 213)
- [ ] Extract CLASSIFICATION_JSON from agent response signal `CLASSIFICATION_COMPLETE: {JSON}`
- [ ] Validate extracted JSON with jq
- [ ] Save to state using append_workflow_state()
- [ ] Verify successful save by reloading state
- [ ] Add error handling for invalid JSON or missing signal

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/coordinate.md`

**Implementation Details for Step 2**:

```markdown
## Phase 0.1: Workflow Classification

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  model: "haiku"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

**IMMEDIATELY AFTER Task completes**, extract and save classification:

```bash
#!/usr/bin/env bash
set +H
set -euo pipefail

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

# Load state persistence library
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/state-persistence.sh"

# Re-load workflow state
COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# CRITICAL: Extract classification JSON from agent response above
# The agent returns: CLASSIFICATION_COMPLETE: {JSON object}
# Extract the JSON portion after the signal

# NOTE: This extraction step requires the coordinator (Claude) to parse
# the Task tool output and substitute the actual JSON here.
# The agent's response signal format is: CLASSIFICATION_COMPLETE: {...}

# COORDINATOR: Replace <EXTRACT_FROM_TASK_OUTPUT> with actual JSON from agent response
CLASSIFICATION_JSON='<EXTRACT_FROM_TASK_OUTPUT>'

# Validate JSON before saving
if ! echo "$CLASSIFICATION_JSON" | jq empty 2>/dev/null; then
  echo "ERROR: Invalid JSON in classification result" >&2
  echo "Received: $CLASSIFICATION_JSON" >&2
  exit 1
fi

# Save to state
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"

# Verify saved successfully
load_workflow_state "$WORKFLOW_ID"
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  echo "ERROR: Failed to save CLASSIFICATION_JSON to state" >&2
  exit 1
fi

echo "✓ Classification saved to state successfully"
echo "  Workflow type: $(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')"
echo "  Research complexity: $(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity')"
```
```
```

**Testing Verification**:

```bash
# Test 1: Simple research workflow
/coordinate "research authentication patterns"
# Expected:
# - Classification completes successfully
# - CLASSIFICATION_JSON saved to state
# - workflow_type = "research-only"
# - No errors in Phase 0.1

# Test 2: Full implementation workflow
/coordinate "implement user registration feature"
# Expected:
# - workflow_type = "full-implementation"
# - research_complexity >= 2
# - State persists correctly

# Test 3: Debug workflow
/coordinate "debug the login form validation"
# Expected:
# - workflow_type = "debug-only"
# - State machine initialized for debug scope
```

**Testing**:
```bash
# Test 1: Simple research workflow
/coordinate "research authentication patterns"
# Expected:
# - Classification completes successfully
# - CLASSIFICATION_JSON saved to state
# - workflow_type = "research-only"
# - No errors in Phase 0.1

# Test 2: Full implementation workflow
/coordinate "implement user registration feature"
# Expected:
# - workflow_type = "full-implementation"
# - research_complexity >= 2
# - State persists correctly

# Test 3: Debug workflow
/coordinate "debug the login form validation"
# Expected:
# - workflow_type = "debug-only"
# - State machine initialized for debug scope
```

**Success Criteria**:
- [ ] Coordinate command completes Phase 0.1 without errors
- [ ] CLASSIFICATION_JSON successfully saved to state file
- [ ] State file located at correct path (`.claude/tmp/workflow_coordinate_*.sh`)
- [ ] JSON validation passes
- [ ] Workflow proceeds to Phase 0.2 (State Machine Initialization)

### Phase 3: Add Variable Validation to State Persistence Library

**Dependencies**: []
**Priority**: P1 (High)
**Risk**: Low
**Estimated Time**: 20 minutes

**Objective**: Enhance load_workflow_state() with fail-fast variable validation

**Tasks**:
- [ ] Update function signature to accept optional required variables: `load_workflow_state "$id" "$is_first" "VAR1" "VAR2"`
- [ ] Add validation loop to check each required variable exists after sourcing
- [ ] Generate detailed error with missing variables list
- [ ] Add state file content dump to error output
- [ ] Return exit code 3 for validation failures (distinct from exit code 2)
- [ ] Ensure backward compatibility (validation optional)

**Files Modified**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 191-233)

**Testing**:
```bash
# Create test suite for validation
bash /home/benjamin/.config/.claude/tests/test-state-persistence-validation.sh

# Expected:
# - Variables present: validation passes (exit 0)
# - Variables missing: validation fails (exit 3)
# - Error message shows missing variable names
# - State file contents displayed in error output
```

**Success Criteria**:
- [ ] load_workflow_state() supports optional variable validation
- [ ] Missing variables trigger exit code 3
- [ ] Error message lists all missing variables
- [ ] State file contents displayed in error output
- [ ] Backward compatible (validation optional)

### Phase 4: Update Coordinate Command to Use Variable Validation

**Dependencies**: [3]
**Priority**: P1 (High)
**Risk**: Low
**Estimated Time**: 10 minutes

**Objective**: Apply validation to all critical state loading points in coordinate.md

**Tasks**:
- [ ] Update load_workflow_state call after Phase 0.1 to validate CLASSIFICATION_JSON
- [ ] Update load_workflow_state calls to validate STATE_MACHINE_CONFIG where needed
- [ ] Update load_workflow_state calls to validate other critical variables
- [ ] Verify error messages are actionable and include state file contents

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/coordinate.md`

**Testing**:
```bash
# Simulate missing CLASSIFICATION_JSON by creating incomplete state
# Run coordinate command and verify error quality
# Expected: Clear error with variable name and state file dump
```

**Success Criteria**:
- [ ] Missing CLASSIFICATION_JSON triggers enhanced error
- [ ] Error message shows exact missing variables
- [ ] State file contents displayed
- [ ] Workflow fails fast with actionable diagnostics

### Phase 5: Add State File Content Dump to Diagnostics

**Dependencies**: [3]
**Priority**: P1 (High)
**Risk**: Low
**Estimated Time**: 5 minutes

**Objective**: Enhance error messages to show state file contents for debugging

**Tasks**:
- [ ] Verify Phase 3 implementation already includes state file dump (lines 384-386 in enhanced function)
- [ ] Test error messages show file contents
- [ ] Confirm state file dump appears only in validation errors, not regular errors

**Files Modified**:
- None (verification only - already implemented in Phase 3)

**Testing**:
```bash
# Create test state file with incomplete data
# Trigger validation error
# Verify error output includes state file contents dump
```

**Success Criteria**:
- [ ] Error messages include full state file contents
- [ ] File contents clearly delimited with visual separators
- [ ] Diagnostic text explains what to check

### Phase 6: Migrate to JSON Checkpoints for Classification Data

**Dependencies**: []
**Priority**: P2 (Medium)
**Risk**: Low
**Estimated Time**: 45 minutes

**Objective**: Use atomic JSON checkpoints instead of bash exports for structured data

**Tasks**:
- [ ] Create save_classification_checkpoint() helper function in state-persistence.sh
- [ ] Create load_classification_checkpoint() helper function
- [ ] Update coordinate.md to use classification checkpoint after Phase 0.1
- [ ] Maintain backward compatibility with bash state variables
- [ ] Add checkpoint cleanup to workflow completion handlers

**Files Modified**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`
- `/home/benjamin/.config/.claude/commands/coordinate.md`

**Testing**:
```bash
# Test checkpoint save/load round-trip
# Verify JSON integrity preserved
# Test fallback to bash state variables
```

**Success Criteria**:
- [ ] Classification stored as atomic JSON checkpoint
- [ ] No escaping issues with multi-line JSON
- [ ] Backward compatible with existing bash variable approach
- [ ] Checkpoint cleanup occurs on workflow completion

### Phase 7: Document Task Tool Execution Isolation Patterns

**Dependencies**: []
**Priority**: P2 (Medium)
**Risk**: Low
**Estimated Time**: 30 minutes

**Objective**: Prevent future architectural mismatches through documentation

**Tasks**:
- [ ] Create or update `.claude/docs/concepts/bash-block-execution-model.md`
- [ ] Add section on Task tool subprocess isolation
- [ ] Provide examples of correct state persistence patterns
- [ ] Document anti-patterns (agent bash in isolated context)
- [ ] Add cross-references from agent development guide

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`

**Testing**:
```bash
# Review documentation for completeness
# Verify examples are executable
# Check cross-references valid
```

**Success Criteria**:
- [ ] Documentation covers Task tool isolation clearly
- [ ] Includes working examples
- [ ] Anti-patterns documented with explanations
- [ ] Cross-referenced from relevant guides

### Phase 8: Create Agent Behavioral File Validator

**Dependencies**: []
**Priority**: P2 (Medium)
**Risk**: Low
**Estimated Time**: 60 minutes

**Objective**: Catch contradictions between allowed-tools and instructions

**Tasks**:
- [ ] Create `/home/benjamin/.config/.claude/scripts/validate-agent-behavioral-file.sh`
- [ ] Check allowed-tools matches bash execution instructions
- [ ] Validate model appropriate for allowed tools
- [ ] Check timeout aligns with expected tool usage
- [ ] Make executable and test on all existing agents
- [ ] Add to development workflow documentation

**Files Modified**:
- `/home/benjamin/.config/.claude/scripts/validate-agent-behavioral-file.sh` (new)

**Testing**:
```bash
# Test validator on workflow-classifier.md (should fail before fix, pass after)
# Test on other agents (should pass)
# Test with intentionally contradictory agent file
```

**Success Criteria**:
- [ ] Validator detects workflow-classifier contradiction (pre-fix)
- [ ] Validator passes workflow-classifier after Phase 1
- [ ] All other agents pass validation
- [ ] Clear error messages for detected issues

### Phase 9: Standardize State File Location Patterns

**Dependencies**: []
**Priority**: P2 (Medium)
**Risk**: Low
**Estimated Time**: 30 minutes

**Objective**: Eliminate confusion between temporary and persistent state locations

**Tasks**:
- [ ] Add deprecation warning if `.claude/data/workflows/*.state` detected
- [ ] Search codebase for legacy location references
- [ ] Update any references to use `.claude/tmp/workflow_*.sh` pattern
- [ ] Document standard in state-persistence.sh header comment
- [ ] Add cleanup of legacy location to state initialization

**Files Modified**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`
- Any files referencing legacy locations

**Testing**:
```bash
# Search for references to old location pattern
grep -r "\.claude/data/workflows" .claude/
# Expected: No results after fix

# Verify standard location documented
head -50 .claude/lib/state-persistence.sh | grep -A5 "State file location"
```

**Success Criteria**:
- [ ] No references to `.claude/data/workflows/*.state` pattern remain
- [ ] Standard location documented in library header
- [ ] Deprecation warning added for legacy pattern
- [ ] State initialization cleans up legacy files

### Phase 10: Create Testing Protocol Compliance Suite

**Dependencies**: [1, 2, 3, 4]
**Priority**: P2 (Medium)
**Risk**: Low
**Estimated Time**: 30 minutes

**Objective**: Ensure test quality and agent behavioral compliance

**Tasks**:
- [ ] Create test_workflow_classifier_compliance.sh for agent behavioral validation
- [ ] Add CLAUDE_SPECS_ROOT override to all test scripts
- [ ] Validate imperative language usage in workflow-classifier.md
- [ ] Verify STEP structure in agent behavioral file
- [ ] Add coverage requirement validation (≥80% for modified code)

**Files Modified**:
- `/home/benjamin/.config/.claude/tests/test_workflow_classifier_compliance.sh` (new)
- Existing test scripts (add isolation)

**Testing**:
```bash
# Run behavioral compliance tests
bash .claude/tests/test_workflow_classifier_compliance.sh

# Verify test isolation (no production directory pollution)
# Run coverage analysis on modified files
```

**Success Criteria**:
- [ ] Agent behavioral compliance tests pass
- [ ] All tests use CLAUDE_SPECS_ROOT isolation
- [ ] No production directory pollution during test runs
- [ ] Coverage ≥80% for modified code

### Phase 11: Spec Updater and Artifact Management

**Dependencies**: [1, 2, 3, 4, 6, 7, 8, 9, 10]
**Priority**: P2 (Low)
**Risk**: Low
**Estimated Time**: 15 minutes

**Objective**: Ensure proper artifact management and cross-referencing

**Tasks**:
- [ ] Verify debug reports in `specs/752_topic/debug/` (not gitignored)
- [ ] Create implementation summary in `specs/752_topic/summaries/001_fix_summary.md`
- [ ] Add cross-references between debug reports and modified files
- [ ] Update plan hierarchy checkboxes if expanded to L1/L2
- [ ] Commit debug reports to git

**Files Modified**:
- `specs/752_debug_coordinate_workflow_classifier/summaries/001_fix_summary.md` (new)

**Testing**:
```bash
# Verify debug reports committed
git status specs/752_debug_coordinate_workflow_classifier/debug/

# Verify cross-references valid
# Check summary file creation
```

**Success Criteria**:
- [ ] Debug reports committed to git
- [ ] Implementation summary created
- [ ] Cross-references between reports and code valid
- [ ] Artifact lifecycle compliant with standards

### Phase 12: Final Integration Testing and Documentation Update

**Dependencies**: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
**Priority**: P2 (Low)
**Risk**: Low
**Estimated Time**: 30 minutes

**Objective**: Verify all changes work together and documentation is complete

**Tasks**:
- [ ] Run full test suite (unit + integration + regression)
- [ ] Test coordinate command with multiple workflow types
- [ ] Verify all documentation updates committed
- [ ] Update CLAUDE.md if needed
- [ ] Create final commit with all changes
- [ ] Close debug spec 752

**Files Modified**:
- Various (final verification and commits)

**Testing**:
```bash
# Run full integration test suite
bash .claude/tests/test-state-persistence-validation.sh
bash .claude/tests/test-classification-json-escaping.sh
bash .claude/tests/test-coordinate-classification-e2e.sh
bash .claude/tests/test-state-file-locations.sh
bash .claude/tests/test_workflow_classifier_compliance.sh

# Test coordinate with different workflow types
/coordinate "research authentication patterns"
/coordinate "implement user registration"
/coordinate "debug login validation"

# Verify all pass without errors
```

**Success Criteria**:
- [ ] All test suites pass
- [ ] Coordinate command works with all workflow types
- [ ] No state persistence errors
- [ ] Documentation complete and committed
- [ ] Debug spec 752 can be closed

## Documentation Requirements

**Files to Update**:
- `.claude/docs/concepts/bash-block-execution-model.md` - Add Task tool isolation patterns (Phase 7)
- `.claude/lib/state-persistence.sh` - Document state file location standard in header
- `.claude/agents/workflow-classifier.md` - Update description to clarify classification-only role
- `specs/752_debug_coordinate_workflow_classifier/summaries/001_fix_summary.md` - Create implementation summary

**Documentation Standards**:
- Follow writing standards (timeless, no temporal markers)
- Use present tense, describe current state
- Include code examples with syntax highlighting
- Cross-reference related documentation
- Update navigation links in parent READMEs

## Dependencies

**External Dependencies**:
- jq (JSON processing) - Required for classification validation
- bash 4.0+ (for indirect variable references in validation)
- git (for repository operations)

**Internal Dependencies**:
- `.claude/lib/state-persistence.sh` - Core state management library
- `.claude/agents/workflow-classifier.md` - Classification agent behavioral file
- `.claude/commands/coordinate.md` - Orchestration command

**Phase Dependencies** (for wave-based execution):
- Wave 1: Phases 1, 3, 6, 7, 8, 9 (independent, can run in parallel)
- Wave 2: Phases 2, 4 (depend on Wave 1 phases)
- Wave 3: Phase 5 (depends on Phase 3)
- Wave 4: Phase 10 (depends on Phases 1-4)
- Wave 5: Phase 11 (depends on Phases 1-10)
- Wave 6: Phase 12 (depends on all prior phases)

**Note**: Wave-based execution can achieve 40-60% time savings through parallelization

## Testing Strategy

### Unit Tests

**Test Suite 1: State Persistence Library**

```bash
#!/usr/bin/env bash
# /home/benjamin/.config/.claude/tests/test-state-persistence-validation.sh

source /home/benjamin/.config/.claude/lib/state-persistence.sh

echo "Testing load_workflow_state() variable validation..."

# Test 1: Load with validation should succeed when variable exists
TEST_ID="test_pass_$$"
STATE_FILE=$(init_workflow_state "$TEST_ID")
append_workflow_state "TEST_VAR" "test_value"

if load_workflow_state "$TEST_ID" false "TEST_VAR"; then
  echo "✓ Test 1 passed: Variable validation succeeded"
else
  echo "✗ Test 1 failed: Variable validation failed unexpectedly"
  exit 1
fi

# Test 2: Load with missing variable should fail with exit code 3
TEST_ID2="test_fail_$$"
STATE_FILE2=$(init_workflow_state "$TEST_ID2")
append_workflow_state "OTHER_VAR" "other_value"

load_workflow_state "$TEST_ID2" false "MISSING_VAR" 2>/dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -eq 3 ]; then
  echo "✓ Test 2 passed: Missing variable detected with correct exit code"
else
  echo "✗ Test 2 failed: Expected exit code 3, got $EXIT_CODE"
  exit 1
fi

# Test 3: Multiple variables validation
TEST_ID3="test_multi_$$"
STATE_FILE3=$(init_workflow_state "$TEST_ID3")
append_workflow_state "VAR1" "value1"
append_workflow_state "VAR2" "value2"

if load_workflow_state "$TEST_ID3" false "VAR1" "VAR2"; then
  echo "✓ Test 3 passed: Multiple variable validation succeeded"
else
  echo "✗ Test 3 failed: Multiple variable validation failed"
  exit 1
fi

# Cleanup
rm -f "$STATE_FILE" "$STATE_FILE2" "$STATE_FILE3"

echo "✓ All state persistence validation tests passed"
```

**Test Suite 2: Classification JSON Handling**

```bash
#!/usr/bin/env bash
# /home/benjamin/.config/.claude/tests/test-classification-json-escaping.sh

source /home/benjamin/.config/.claude/lib/state-persistence.sh

echo "Testing classification JSON escaping..."

TEST_ID="test_json_$$"
STATE_FILE=$(init_workflow_state "$TEST_ID")

# Complex JSON with quotes, nested objects, arrays
TEST_JSON='{"workflow_type":"research-and-plan","confidence":0.92,"research_topics":[{"name":"Topic 1","description":"Description with \"quotes\""}],"nested":{"deep":{"value":"test"}}}'

append_workflow_state "CLASSIFICATION_JSON" "$TEST_JSON"
load_workflow_state "$TEST_ID"

# Verify JSON round-trips correctly and is valid
if echo "$CLASSIFICATION_JSON" | jq empty 2>/dev/null; then
  echo "✓ JSON escaping test passed - valid JSON after round-trip"
else
  echo "✗ JSON escaping test failed - invalid JSON after round-trip"
  echo "Original: $TEST_JSON"
  echo "Loaded: ${CLASSIFICATION_JSON:-<not set>}"
  exit 1
fi

# Verify content matches
ORIGINAL_TYPE=$(echo "$TEST_JSON" | jq -r '.workflow_type')
LOADED_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')

if [ "$ORIGINAL_TYPE" = "$LOADED_TYPE" ]; then
  echo "✓ JSON content preservation test passed"
else
  echo "✗ JSON content changed during round-trip"
  exit 1
fi

rm -f "$STATE_FILE"

echo "✓ All JSON escaping tests passed"
```

### Integration Tests

**Test Suite 3: End-to-End Workflow Classification**

```bash
#!/usr/bin/env bash
# /home/benjamin/.config/.claude/tests/test-coordinate-classification-e2e.sh

echo "Testing end-to-end workflow classification..."

# Test 1: Research workflow
echo "Test 1: Research workflow classification"
# Note: This requires manual execution or Claude invocation
# /coordinate "research authentication patterns"
# Verify:
# - CLASSIFICATION_JSON saved to state
# - workflow_type = "research-only"
# - State file exists at .claude/tmp/workflow_coordinate_*.sh

# Test 2: Implementation workflow
echo "Test 2: Implementation workflow classification"
# /coordinate "implement user registration feature"
# Verify:
# - workflow_type = "full-implementation"
# - research_complexity >= 2

# Test 3: Debug workflow
echo "Test 3: Debug workflow classification"
# /coordinate "debug the login validation bug"
# Verify:
# - workflow_type = "debug-only"

echo "✓ Manual verification required for integration tests"
echo "  Run /coordinate with different workflow descriptions"
echo "  Verify CLASSIFICATION_JSON persists correctly"
```

### Regression Tests

**Test Suite 4: State File Location Verification**

```bash
#!/usr/bin/env bash
# /home/benjamin/.config/.claude/tests/test-state-file-locations.sh

echo "Testing state file location standards..."

# Verify correct location pattern
CORRECT_PATTERN="/home/benjamin/.config/.claude/tmp/workflow_*.sh"
INCORRECT_PATTERN="/home/benjamin/.config/.claude/data/workflows/*.state"

# Check for files in correct location (expected after workflow runs)
if ls ${CORRECT_PATTERN} 2>/dev/null | head -1 >/dev/null; then
  echo "✓ State files found in correct location: .claude/tmp/"
else
  echo "ℹ️  No active state files (expected if no workflows running)"
fi

# Check for files in incorrect location (should not exist)
if ls ${INCORRECT_PATTERN} 2>/dev/null | head -1 >/dev/null; then
  echo "⚠️  WARNING: Legacy state files found in .claude/data/workflows/"
  echo "   These should be migrated or cleaned up"
else
  echo "✓ No legacy state files in incorrect location"
fi

echo "✓ State file location tests complete"
```

### Verification Checklist

After implementing each phase, verify:

**Phase 1 Verification**:
- [ ] workflow-classifier.md has no bash execution instructions
- [ ] coordinate.md extracts classification from Task output
- [ ] CLASSIFICATION_JSON saved to state successfully
- [ ] State file contains proper export statement
- [ ] Workflow proceeds past Phase 0.1 without errors
- [ ] Test workflows: research, implement, debug all work

**Phase 2 Verification**:
- [ ] load_workflow_state() accepts variable validation parameters
- [ ] Missing variables trigger exit code 3
- [ ] Error messages show state file contents
- [ ] coordinate.md uses validation for CLASSIFICATION_JSON
- [ ] Test with intentionally missing variable shows clear error

**Phase 3 Verification**:
- [ ] Classification checkpoint functions implemented
- [ ] Documentation covers Task tool isolation patterns
- [ ] Agent validator script detects contradictions
- [ ] No legacy state file location references remain
- [ ] All tests pass

## Rollback Plan

### Phase 1 Rollback

If critical fixes cause issues:

1. **Identify failure point**:
   - Review coordinate_output.md for new error messages
   - Check state file location and contents
   - Verify Task tool output format

2. **Revert changes**:
   ```bash
   cd /home/benjamin/.config
   git checkout HEAD -- .claude/agents/workflow-classifier.md
   git checkout HEAD -- .claude/commands/coordinate.md
   ```

3. **Alternative approach**:
   - Consider Fix 2 (allowed-tools: Bash) instead
   - Update workflow-classifier.md frontmatter only
   - Keep state persistence in agent

4. **Document decision**:
   - Record why Fix 1 failed
   - Note any Task tool output parsing issues
   - Update debug report with findings

### Phase 2 Rollback

If validation enhancements cause issues:

1. **Check for false positives**:
   - Review if validation too strict
   - Verify variable existence check logic
   - Test with various state file formats

2. **Revert if needed**:
   ```bash
   git checkout HEAD -- .claude/lib/state-persistence.sh
   git checkout HEAD -- .claude/commands/coordinate.md
   ```

3. **Partial rollback option**:
   - Keep validation code but disable by default
   - Remove validation parameters from coordinate.md
   - Make validation opt-in only

### Phase 3 Rollback

If long-term improvements cause issues:

1. **Assess impact**:
   - JSON checkpoints: Check file permissions, disk space
   - Documentation: No rollback needed (harmless)
   - Validator: Check for false positives
   - Location standardization: Verify no broken references

2. **Selective rollback**:
   - Can rollback individual improvements independently
   - Keep documentation even if code reverted
   - Disable validator if too strict

3. **Recovery steps**:
   ```bash
   # Revert specific file
   git checkout HEAD -- <problematic-file>

   # Or revert entire phase
   git revert <phase-3-commit>
   ```

## Success Metrics

### Immediate Success (Phases 1-2: P0 Critical Fixes)

- **Primary**: Coordinate command completes Phase 0.1 without state persistence errors
- **Quantitative**: 100% success rate for test workflows (research, implement, debug)
- **Time**: Workflow classification completes in <20 seconds (includes Haiku inference)
- **Error Rate**: Zero CLASSIFICATION_JSON unbound variable errors

### Medium-term Success (Phases 3-5: P1 Diagnostic Enhancements)

- **Diagnostic Quality**: Error messages include state file contents
- **Detection Speed**: Missing variables detected immediately (fail-fast)
- **Developer Experience**: Clear, actionable error messages
- **False Positive Rate**: Zero false positives from validation

### Long-term Success (Phases 6-11: P2 Architectural Improvements)

- **Maintainability**: New agents avoid state persistence contradictions
- **Documentation Coverage**: Task tool isolation patterns documented with examples
- **Code Quality**: Agent validator integrated into development workflow
- **Architecture Consistency**: Single state file location pattern across codebase

## Risk Assessment

### P0 Critical Phases (1-2) Risks

**Risk**: Task tool output format changes
- **Probability**: Low
- **Impact**: High (breaks classification extraction in Phase 2)
- **Mitigation**: Add robust parsing with error handling; test multiple workflow types
- **Contingency**: Revert and use alternative approach (allowed-tools: Bash)

**Risk**: JSON extraction from Task output fails
- **Probability**: Medium
- **Impact**: High (Phase 2 cannot save classification)
- **Mitigation**: Add validation and clear error messages
- **Contingency**: Implement inline classification fallback

### P1 Diagnostic Phases (3-5) Risks

**Risk**: Variable validation too strict
- **Probability**: Low
- **Impact**: Medium (false positive errors in Phase 3-4)
- **Mitigation**: Test thoroughly with edge cases
- **Contingency**: Make validation opt-in only

**Risk**: Performance degradation from validation
- **Probability**: Very Low
- **Impact**: Low (1-2ms per validation in Phase 3)
- **Mitigation**: Benchmark before/after
- **Contingency**: Optimize validation loop

### P2 Improvement Phases (6-11) Risks

**Risk**: JSON checkpoint migration breaks backward compatibility
- **Probability**: Low
- **Impact**: Medium (Phase 6 may break existing code)
- **Mitigation**: Implement fallback to bash state variables
- **Contingency**: Keep dual persistence during transition

**Risk**: Agent validator false positives
- **Probability**: Medium
- **Impact**: Low (Phase 8 developer annoyance)
- **Mitigation**: Make validator advisory only (warnings, not errors)
- **Contingency**: Add exceptions list for known valid cases

## Timeline

**Total Estimated Time**: 3.3 hours (with wave-based parallelization)
**Sequential Time**: ~5.5 hours (without parallelization)
**Time Savings**: ~40% through parallel execution

### Wave 1: Independent Phases (Parallel Execution)
**Duration**: ~2.5 hours (longest phase in wave)
**Phases**: 1, 3, 6, 7, 8, 9

- Phase 1: Remove agent state persistence (15 min)
- Phase 3: Add state validation (20 min) - can run parallel with Phase 1
- Phase 6: JSON checkpoints (45 min) - can run parallel
- Phase 7: Documentation (30 min) - can run parallel
- Phase 8: Agent validator (60 min) - can run parallel
- Phase 9: Location standardization (30 min) - can run parallel

### Wave 2: Dependent Phases (Sequential after Wave 1)
**Duration**: ~40 minutes
**Phases**: 2, 4

- Phase 2: Update coordinate command (30 min) - depends on Phase 1
- Phase 4: Apply validation to coordinate (10 min) - depends on Phase 3

### Wave 3: Diagnostic Verification
**Duration**: ~5 minutes
**Phases**: 5

- Phase 5: Verify diagnostics (5 min) - depends on Phase 3

### Wave 4: Testing Integration
**Duration**: ~30 minutes
**Phases**: 10

- Phase 10: Testing protocol compliance (30 min) - depends on Phases 1-4

### Wave 5: Artifact Management
**Duration**: ~15 minutes
**Phases**: 11

- Phase 11: Spec updater and artifacts (15 min) - depends on all implementation phases

### Wave 6: Final Verification
**Duration**: ~30 minutes
**Phases**: 12

- Phase 12: Final integration testing (30 min) - depends on all phases

**Implementation Strategy**:
- Execute Wave 1 phases in parallel (use multiple terminals or async execution)
- Sequential waves execute after all phases in previous wave complete
- Use `/implement` with phase dependencies for automated wave calculation

## Appendix A: Implementation Quick Reference

### P0 Critical Fixes (Phases 1-2)

```bash
# Phase 1: Remove state persistence from agent
cd /home/benjamin/.config
sed -i '530,587d' .claude/agents/workflow-classifier.md

# Phase 2: Edit coordinate.md (manual - add extraction bash block after line 213)
# See Phase 2 implementation details in plan

# Test critical fixes
/coordinate "research authentication patterns"
```

### P1 Diagnostic Enhancements (Phases 3-5)

```bash
# Phase 3: Backup before editing state persistence library
cp .claude/lib/state-persistence.sh .claude/lib/state-persistence.sh.backup

# Phase 3: Edit state-persistence.sh to add validation
# See Phase 3 tasks in plan for specific changes

# Phase 4: Update coordinate.md to use validation
# Add required variables to load_workflow_state calls

# Phase 5: Test enhanced diagnostics
bash .claude/tests/test-state-persistence-validation.sh
```

### P2 Improvements (Phases 6-11)

```bash
# Phase 8: Create and test agent validator
touch .claude/scripts/validate-agent-behavioral-file.sh
chmod +x .claude/scripts/validate-agent-behavioral-file.sh
# Add script content per Phase 8 specifications

# Run validator on all agents
for agent in .claude/agents/*.md; do
  .claude/scripts/validate-agent-behavioral-file.sh "$agent"
done

# Phase 12: Final integration testing
bash .claude/tests/test-coordinate-classification-e2e.sh
```

## Appendix B: Root Cause Summary

**Primary Root Cause**: Architectural mismatch between Task tool execution isolation and bash-based state persistence expectations.

**Contributing Factors**:
1. Agent configured with `allowed-tools: None` but instructed to execute bash commands
2. State persistence library assumes single execution context
3. No variable-level validation in load_workflow_state()
4. Unclear state file location standards (two patterns exist)

**Key Insight**: Task tool creates subprocess boundaries that prevent environment variable transfer. State persistence must occur in the parent command context, not in isolated agent contexts.

**Long-term Solution**: Document execution isolation patterns and prevent similar architectural mismatches through validation and better agent behavioral file guidelines.

## Appendix C: Alternative Solutions Not Pursued

### Alternative 1: Inline Classification (Not Recommended)

Moving classification logic entirely into coordinate.md bash blocks would eliminate agent dependency but loses semantic analysis capabilities from LLM. Keyword matching is less accurate for edge cases (quotes, negations, complex intent).

**Decision**: Keep LLM classification for quality, fix state persistence architecture instead.

### Alternative 2: Agent with Bash Tool (Higher Risk)

Changing workflow-classifier to `allowed-tools: Bash` would allow agent to execute state persistence, but Task tool isolation may still prevent access to parent STATE_FILE variable. Higher risk of same failure in different form.

**Decision**: Move state persistence to parent context (lower risk, clearer architecture).

### Alternative 3: Shared Memory or IPC (Over-Engineering)

Using shared memory, named pipes, or other IPC mechanisms for agent-parent communication would add significant complexity for minimal benefit. File-based state persistence is sufficient and follows established patterns.

**Decision**: Keep file-based approach, fix the architectural mismatch.

---

**Plan Status**: READY FOR IMPLEMENTATION
**Created**: 2025-11-17
**Updated**: 2025-11-17 (Revised for standards compliance)
**Spec**: 752_debug_coordinate_workflow_classifier
**Plan**: 001_debug_strategy.md
**Total Estimated Time**: 3.3 hours across 12 phases
**With Parallelization**: ~40% time savings via wave-based execution
**Structure Level**: L0 (single file, Tier 2 complexity)
