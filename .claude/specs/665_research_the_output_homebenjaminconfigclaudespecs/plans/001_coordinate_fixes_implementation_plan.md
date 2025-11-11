# Implementation Plan: Fix /coordinate Research-and-Revise Workflow Errors

## Plan Metadata

**Plan ID**: 001_coordinate_fixes_implementation_plan
**Topic Directory**: 665_research_the_output_homebenjaminconfigclaudespecs
**Created**: 2025-11-11
**Status**: Not Started
**Complexity**: Medium (4 phases, subprocess isolation + architecture compliance)
**Research Reports**: 001_coordinate_error_analysis.md
**Estimated Duration**: 4-6 hours

---

## Executive Summary

This plan addresses two critical errors in the `/coordinate` command's research-and-revise workflow:

1. **Primary Error (Architecture Violation)**: Lines 801-828 of `coordinate.md` contain template for revision-specialist agent invocation, but actual execution (lines 81-94 of `coordinate_output.md`) uses `/revise` SlashCommand instead of Task tool, violating Standard 11 (Imperative Agent Invocation Pattern)

2. **Secondary Error (Subprocess Persistence Bug)**: `EXISTING_PLAN_PATH` variable exported in `workflow-scope-detection.sh` does not persist to `workflow-initialization.sh` validation check due to subprocess isolation. Variable must be saved to workflow state file immediately after extraction.

**Root Causes**:
- Primary: Disconnect between template instructions and actual execution behavior
- Secondary: Bash block execution model (subprocess isolation) prevents export from persisting

**Solution Approach**:
- Phase 1: Fix `EXISTING_PLAN_PATH` persistence via workflow state integration (Lines 125-131 of coordinate.md)
- Phase 2: Replace actual `/revise` invocation with revision-specialist agent delegation (Planning phase handler)
- Phase 3: Add comprehensive regression tests (prevent future breakage)
- Phase 4: Update documentation and verify standards compliance

---

## Technical Design

### Architecture Overview

The fix integrates with existing `/coordinate` command infrastructure:

```
coordinate.md (State Machine Orchestrator)
├── Bash Block 1: State Initialization
│   ├── sm_init() calls detect_workflow_scope()
│   │   └── Extracts EXISTING_PLAN_PATH (subprocess, doesn't persist)
│   ├── FIX: Re-extract path in coordinate.md after sm_init
│   └── append_workflow_state("EXISTING_PLAN_PATH", path) → persists
│
└── Bash Block 2+: Planning Phase Handler
    ├── CURRENT: Lines 788-828 show template for agent invocation
    │   └── BUT: Actual execution uses /revise SlashCommand (violation)
    ├── FIX: Replace with actual Task tool invocation
    │   └── Task { prompt: revision-specialist.md, context injection }
    └── VERIFICATION: Check REVISION_COMPLETED signal
```

### Key Components

**1. Workflow State Persistence** (`.claude/lib/state-persistence.sh`):
- `append_workflow_state()`: Saves key-value pairs to state file
- State file persists across bash block boundaries (filesystem-based)
- Pattern: `append_workflow_state "KEY" "$value"` in early blocks

**2. Subprocess Isolation Pattern** (Bash Block Execution Model):
- Each bash block runs as separate process (PID changes)
- `export` within function creates subprocess variable (lost after block exits)
- **Solution**: File-based persistence via state file (fixed semantic filename)

**3. Agent Delegation Pattern** (Standard 11):
- Commands invoke agents via Task tool (NOT SlashCommand)
- Context injection via prompt: paths, standards, completion signals
- Verification: Parse completion signal from agent output
- Fallback: Handle missing signals with diagnostics

### Implementation Strategy

**Phase 1 (EXISTING_PLAN_PATH Persistence)**:
- **Location**: `coordinate.md` lines 125-131 (after `sm_init`, before state save)
- **Pattern**: Extract → Validate → Export → Persist
- **Timing**: Must occur in bash block where `sm_init()` is called

**Phase 2 (Agent Delegation Fix)**:
- **Location**: `coordinate.md` lines 788-828 (Planning Phase Handler)
- **Current Template**: Already contains correct Task invocation structure
- **Problem**: Actual execution doesn't follow template (uses `/revise` instead)
- **Fix**: Ensure Task tool is actually invoked (not just documented)
- **Verification**: Add mandatory checkpoint for `REVISION_COMPLETED` signal

**Phase 3 (Regression Tests)**:
- **Test Coverage**: Scope detection, path extraction, state persistence, agent delegation, end-to-end workflow
- **Test Location**: `.claude/tests/test_coordinate_error_fixes.sh` (new file)
- **Integration**: Add to `run_all_tests.sh` test suite

**Phase 4 (Documentation Updates)**:
- **Command Guide**: Add research-and-revise workflow examples
- **Troubleshooting**: Document `EXISTING_PLAN_PATH` failure scenarios
- **Standards**: Verify Standard 11 compliance throughout

---

## Implementation Phases

### Phase 1: Fix EXISTING_PLAN_PATH Subprocess Persistence

**Objective**: Ensure `EXISTING_PLAN_PATH` persists across bash blocks by saving to workflow state immediately after scope detection

**Complexity**: Low (single bash block modification, 10-15 lines)

**Dependencies**: None

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 125-131)

**Tasks**:

- [x] **Task 1.1**: Add path extraction and validation after `sm_init()`
  - **Location**: `coordinate.md` lines 125-131 (between `sm_init` and state save)
  - **Implementation**:
    ```bash
    # After sm_init call (line 125), before saving state (line 127)
    sm_init "$SAVED_WORKFLOW_DESC" "coordinate"

    # ADDED: Extract and save EXISTING_PLAN_PATH for research-and-revise workflows
    if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
      # Extract plan path from workflow description
      if echo "$SAVED_WORKFLOW_DESC" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
        EXISTING_PLAN_PATH=$(echo "$SAVED_WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
        export EXISTING_PLAN_PATH

        # CRITICAL: Verify file exists before proceeding
        if [ ! -f "$EXISTING_PLAN_PATH" ]; then
          handle_state_error "Extracted plan path does not exist: $EXISTING_PLAN_PATH" 1
        fi

        echo "✓ Extracted existing plan path: $EXISTING_PLAN_PATH"
      else
        handle_state_error "research-and-revise workflow requires plan path in description" 1
      fi
    fi

    # Save state machine configuration to workflow state
    append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
    append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
    append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

    # ADDED: Save EXISTING_PLAN_PATH to state for bash block persistence
    if [ -n "${EXISTING_PLAN_PATH:-}" ]; then
      append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"
    fi
    ```
  - **Verification**: Check state file contains `EXISTING_PLAN_PATH=/path/to/plan.md`
  - **Error Handling**: Fail-fast if path doesn't exist or isn't in workflow description

- [x] **Task 1.2**: Update workflow-initialization.sh validation logic
  - **Location**: `.claude/lib/workflow-initialization.sh` lines 346-356
  - **Current Code**: Checks `${EXISTING_PLAN_PATH:-}` immediately after scope detection
  - **Problem**: Variable not yet in state when validation runs
  - **Fix**: Validation now occurs AFTER state persistence in coordinate.md
  - **Change**: Move validation from library to coordinate.md (after append_workflow_state)
  - **Rationale**: Timing issue - library validates before coordinate.md saves to state

- [x] **Task 1.3**: Test path extraction with various workflow descriptions
  - **Test Cases**:
    - Full path: `"Revise the plan /home/benjamin/.config/.claude/specs/657_topic/plans/001_plan.md to accommodate changes"`
    - Relative reference: `"Revise plan 001_plan.md based on research"` (should fail with diagnostic)
    - Multiple paths: `"Revise /path/to/plan1.md and /path/to/plan2.md"` (extracts first)
  - **Verification**: Run test workflow and check workflow state file
  - **Expected**: State file contains correct `EXISTING_PLAN_PATH` entry

**Verification Checkpoint**:
```bash
# After Phase 1 completion
# 1. Run test workflow with research-and-revise scope
/coordinate "Revise the plan /home/benjamin/.config/.claude/specs/657_topic/plans/001_test.md to accommodate research"

# 2. Check state file contains EXISTING_PLAN_PATH
STATE_FILE="${HOME}/.claude/tmp/workflow_coordinate_*.sh"
grep "EXISTING_PLAN_PATH" "$STATE_FILE"

# Expected: EXISTING_PLAN_PATH=/home/benjamin/.config/.claude/specs/657_topic/plans/001_test.md
```

**Success Criteria**:
- ✓ `EXISTING_PLAN_PATH` saved to workflow state in bash block 1
- ✓ Variable persists across bash blocks (accessible in planning phase)
- ✓ Validation passes in workflow-initialization.sh
- ✓ Error diagnostics appear if path missing or invalid

---

### Phase 2: Replace /revise SlashCommand with Revision-Specialist Agent

**Objective**: Fix architecture violation by replacing `/revise` SlashCommand invocation with proper Task tool + revision-specialist agent delegation

**Complexity**: Medium (agent invocation pattern, context injection, verification)

**Dependencies**: Phase 1 (requires `EXISTING_PLAN_PATH` in state)

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 788-828 Planning Phase Handler)

**Tasks**:

- [x] **Task 2.1**: Verify template structure is correct (lines 801-828)
  - **Current State**: Template shows Task tool invocation with revision-specialist.md
  - **Check**: Confirm template includes all required context injection:
    - `EXISTING_PLAN_PATH` from workflow state
    - `REPORT_PATHS` array from research phase
    - `WORKFLOW_DESCRIPTION` as revision scope
    - `CLAUDE_PROJECT_DIR/CLAUDE.md` as project standards
    - Backup requirement: `true`
    - Completion signal: `REVISION_COMPLETED: $EXISTING_PLAN_PATH`
  - **Verification**: Read template and compare against behavioral file requirements

- [x] **Task 2.2**: Add enforcement pattern to ensure Task tool actually invoked
  - **Problem**: Template exists but execution may skip to `/revise` SlashCommand
  - **Solution**: Add Standard 0 enforcement pattern (Imperative Language)
  - **Location**: Before Task invocation block
  - **Implementation**:
    ```markdown
    **EXECUTE NOW**: USE the Task tool to invoke revision-specialist agent.

    **CRITICAL**: You MUST use Task tool (NOT SlashCommand /revise).

    **IF WORKFLOW_SCOPE = research-and-revise**:
    ```
  - **Pattern Reference**: Standard 0 in command_architecture_standards.md

- [x] **Task 2.3**: Load EXISTING_PLAN_PATH from workflow state
  - **Location**: Planning phase bash block (before agent invocation)
  - **Implementation**:
    ```bash
    # Load workflow state
    load_workflow_state "$WORKFLOW_ID"

    # Verify EXISTING_PLAN_PATH loaded for research-and-revise workflows
    if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
      if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
        echo "ERROR: EXISTING_PLAN_PATH not restored from workflow state"
        handle_state_error "EXISTING_PLAN_PATH missing from workflow state" 1
      fi
      echo "DEBUG: EXISTING_PLAN_PATH from state: $EXISTING_PLAN_PATH"
    fi
    ```
  - **Timing**: Must occur before Task invocation

- [x] **Task 2.4**: Inject context into revision-specialist agent prompt
  - **Required Context Variables**:
    - `EXISTING_PLAN_PATH`: Absolute path to plan being revised
    - `REPORT_PATHS[@]`: Array of research report paths
    - `WORKFLOW_DESCRIPTION`: Original workflow description (revision scope)
    - `CLAUDE_PROJECT_DIR/CLAUDE.md`: Project standards path
  - **Template**:
    ```yaml
    Task {
      subagent_type: "general-purpose"
      description: "Revise existing plan based on research findings"
      timeout: 180000
      prompt: "
        Read and follow ALL behavioral guidelines from:
        ${CLAUDE_PROJECT_DIR}/.claude/agents/revision-specialist.md

        **Workflow-Specific Context**:
        - Existing Plan Path: $EXISTING_PLAN_PATH (absolute)
        - Research Reports: ${REPORT_PATHS[@]}
        - Revision Scope: $WORKFLOW_DESCRIPTION
        - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
        - Backup Required: true

        **Key Requirements**:
        1. Create backup FIRST before any modifications
        2. Analyze research findings in provided reports
        3. Apply revisions to existing plan preserving completed phases
        4. Update revision history section with changes
        5. Return completion signal with plan path

        Execute revision following all guidelines in behavioral file.
        Return: REVISION_COMPLETED: $EXISTING_PLAN_PATH
      "
    }
    ```

- [x] **Task 2.5**: Add mandatory verification checkpoint for completion signal
  - **Location**: Immediately after Task invocation returns
  - **Implementation**:
    ```bash
    # MANDATORY VERIFICATION: Check for completion signal
    if grep -q "REVISION_COMPLETED:" <<< "$AGENT_OUTPUT"; then
      REVISED_PLAN_PATH=$(echo "$AGENT_OUTPUT" | grep -oP "REVISION_COMPLETED: \K.*")
      echo "✓ Revision completed: $REVISED_PLAN_PATH"

      # Verify revised plan path matches expected path
      if [ "$REVISED_PLAN_PATH" != "$EXISTING_PLAN_PATH" ]; then
        echo "WARNING: Revised plan path differs from expected"
        echo "  Expected: $EXISTING_PLAN_PATH"
        echo "  Actual: $REVISED_PLAN_PATH"
      fi
    else
      handle_state_error "Revision specialist did not return completion signal" 1
    fi
    ```
  - **Pattern Reference**: Verification Fallback Pattern (verification-fallback.md)

- [x] **Task 2.6**: Add backup verification logic
  - **Location**: After revision completion, before state transition
  - **Implementation**:
    ```bash
    # Verify backup was created by revision-specialist agent
    PLAN_DIR=$(dirname "$EXISTING_PLAN_PATH")
    BACKUP_PATH=$(find "$PLAN_DIR/backups" -maxdepth 1 -name "$(basename "$EXISTING_PLAN_PATH" .md)_*.md" -type f | sort -r | head -1)

    if [ -n "$BACKUP_PATH" ] && [ -f "$BACKUP_PATH" ]; then
      echo "✓ Backup verified: $(basename "$BACKUP_PATH")"
      append_workflow_state "BACKUP_PATH" "$BACKUP_PATH"

      # Simple diff check
      if diff -q "$EXISTING_PLAN_PATH" "$BACKUP_PATH" > /dev/null 2>&1; then
        echo "  Note: Plan unchanged (files identical)"
      else
        echo "  Plan modified: revision applied changes"
      fi
    else
      echo "⚠ WARNING: No backup file found for revised plan"
    fi
    ```

**Verification Checkpoint**:
```bash
# After Phase 2 completion
# 1. Create test plan
mkdir -p /tmp/specs/042_test/plans
cat > /tmp/specs/042_test/plans/001_test.md <<'EOF'
# Test Plan
## Phase 1: Initial Implementation
- [ ] Task 1
EOF

# 2. Run coordinate with research-and-revise workflow
/coordinate "Revise the plan /tmp/specs/042_test/plans/001_test.md based on new research findings"

# 3. Verify backup created
ls -la /tmp/specs/042_test/plans/backups/

# Expected: Backup file exists with timestamp (001_test_YYYYMMDD_HHMMSS.md)

# 4. Verify plan modified
diff /tmp/specs/042_test/plans/001_test.md /tmp/specs/042_test/plans/backups/001_test_*.md

# Expected: Differences shown if revision applied changes

# 5. Check for SlashCommand invocation (should be absent)
grep -n "/revise is running" coordinate_output.log

# Expected: No matches (uses Task tool instead)
```

**Success Criteria**:
- ✓ Task tool invoked (NOT `/revise` SlashCommand)
- ✓ revision-specialist.md behavioral file referenced
- ✓ All required context injected (paths, reports, standards)
- ✓ Completion signal verified (`REVISION_COMPLETED:`)
- ✓ Backup created and verified
- ✓ Standard 11 compliance achieved

---

### Phase 3: Add Comprehensive Regression Tests

**Objective**: Prevent future regressions by adding comprehensive test coverage for research-and-revise workflows

**Complexity**: Medium (test infrastructure, mocking, end-to-end scenarios)

**Dependencies**: Phases 1-2 (fixes must be implemented to validate tests)

**Files Created**:
- `/home/benjamin/.config/.claude/tests/test_coordinate_error_fixes.sh` (new file)

**Tasks**:

- [ ] **Task 3.1**: Create test file structure with setup/teardown
  - **Template**:
    ```bash
    #!/usr/bin/env bash
    # Test: /coordinate research-and-revise workflow fixes
    # Validates: EXISTING_PLAN_PATH persistence and agent delegation

    set -euo pipefail

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/test_helpers.sh"

    TEST_NAME="coordinate_error_fixes"
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0

    # Test fixtures
    TEST_SPECS_DIR="/tmp/test_specs_$$"
    TEST_TOPIC_DIR="${TEST_SPECS_DIR}/042_test"
    TEST_PLAN_PATH="${TEST_TOPIC_DIR}/plans/001_test_plan.md"

    setup() {
      echo "Setting up test environment..."
      mkdir -p "${TEST_TOPIC_DIR}/plans"
      mkdir -p "${TEST_TOPIC_DIR}/reports"

      # Create minimal test plan
      cat > "$TEST_PLAN_PATH" <<'EOF'
    # Test Plan
    ## Phase 1: Initial Implementation
    - [ ] Task 1
    EOF
    }

    teardown() {
      echo "Cleaning up test environment..."
      rm -rf "$TEST_SPECS_DIR"
    }

    # Run tests
    trap teardown EXIT
    setup
    ```

- [ ] **Task 3.2**: Test scope detection identifies research-and-revise pattern
  - **Test Function**:
    ```bash
    test_scope_detection_revision_first() {
      TESTS_RUN=$((TESTS_RUN + 1))

      source "${SCRIPT_DIR}/../lib/workflow-scope-detection.sh"

      workflow_desc="Revise the plan /path/to/specs/042_auth/plans/001_plan.md to accommodate research findings"
      scope=$(detect_workflow_scope "$workflow_desc")

      if [ "$scope" = "research-and-revise" ]; then
        echo "✓ Test passed: Scope detection identifies research-and-revise"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: Expected 'research-and-revise', got '$scope'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    }
    ```

- [ ] **Task 3.3**: Test path extraction from workflow description
  - **Test Function**:
    ```bash
    test_path_extraction_from_description() {
      TESTS_RUN=$((TESTS_RUN + 1))

      workflow_desc="Revise the plan ${TEST_PLAN_PATH} to accommodate changes"
      extracted_path=$(echo "$workflow_desc" | grep -oE "/[^ ]+\.md" | head -1)

      if [ "$extracted_path" = "$TEST_PLAN_PATH" ]; then
        echo "✓ Test passed: Path extraction works correctly"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: Expected '$TEST_PLAN_PATH', got '$extracted_path'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    }
    ```

- [ ] **Task 3.4**: Test EXISTING_PLAN_PATH persists to workflow state
  - **Test Function**:
    ```bash
    test_existing_plan_path_in_state() {
      TESTS_RUN=$((TESTS_RUN + 1))

      source "${SCRIPT_DIR}/../lib/state-persistence.sh"
      source "${SCRIPT_DIR}/../lib/workflow-state-machine.sh"

      # Simulate coordinate workflow initialization
      WORKFLOW_DESC="Revise the plan ${TEST_PLAN_PATH} to accommodate changes"
      WORKFLOW_ID="test_coordinate_$$"
      STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

      # Simulate extraction and persistence
      EXISTING_PLAN_PATH=$(echo "$WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
      append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"

      # Verify state file contains variable
      if grep -q "EXISTING_PLAN_PATH=${TEST_PLAN_PATH}" "$STATE_FILE"; then
        echo "✓ Test passed: EXISTING_PLAN_PATH saved to state"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: EXISTING_PLAN_PATH not in state file"
        cat "$STATE_FILE" >&2
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi

      rm -f "$STATE_FILE"
    }
    ```

- [ ] **Task 3.5**: Test planning phase uses agent delegation (not SlashCommand)
  - **Test Approach**: Mock coordinate planning phase, verify Task tool invocation
  - **Test Function**:
    ```bash
    test_planning_phase_uses_agent_delegation() {
      TESTS_RUN=$((TESTS_RUN + 1))

      # Read planning phase section from coordinate.md
      PLANNING_SECTION=$(sed -n '/## State Handler: Planning Phase/,/## State Handler: Implementation Phase/p' \
        "${SCRIPT_DIR}/../commands/coordinate.md")

      # Verify Task invocation exists
      if echo "$PLANNING_SECTION" | grep -q "Task {"; then
        echo "✓ Test passed: Planning phase contains Task invocation"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: Task invocation not found in planning phase"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi

      # Verify references revision-specialist.md
      if echo "$PLANNING_SECTION" | grep -q "revision-specialist.md"; then
        echo "✓ Test passed: Planning phase references revision-specialist.md"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: revision-specialist.md reference missing"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi

      # Verify does NOT invoke /revise SlashCommand
      if ! echo "$PLANNING_SECTION" | grep -q "/revise"; then
        echo "✓ Test passed: No /revise SlashCommand invocation"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: Found /revise SlashCommand (should use Task tool)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    }
    ```

- [ ] **Task 3.6**: Test end-to-end research-and-revise workflow
  - **Scope**: Full workflow execution (research → revise plan → verify artifacts)
  - **Test Function**:
    ```bash
    test_e2e_research_and_revise_workflow() {
      TESTS_RUN=$((TESTS_RUN + 1))

      # Note: This is an integration test that requires full command execution
      # For now, verify command file structure is correct

      # Check coordinate.md has research-and-revise scope handling
      if grep -q "research-and-revise" "${SCRIPT_DIR}/../commands/coordinate.md"; then
        echo "✓ Test passed: coordinate.md handles research-and-revise scope"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "✗ Test failed: research-and-revise scope handling missing"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    }
    ```

- [ ] **Task 3.7**: Add test summary and exit code reporting
  - **Implementation**:
    ```bash
    # Print test summary
    echo ""
    echo "=========================================="
    echo "Test Summary: $TEST_NAME"
    echo "=========================================="
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
      echo "✓ All tests passed"
      exit 0
    else
      echo "✗ $TESTS_FAILED test(s) failed"
      exit 1
    fi
    ```

- [ ] **Task 3.8**: Integrate new test file into test suite
  - **Location**: `.claude/tests/run_all_tests.sh`
  - **Add Line**:
    ```bash
    run_test_file "test_coordinate_error_fixes.sh" "Coordinate Error Fixes"
    ```
  - **Position**: After existing coordinate tests

**Verification Checkpoint**:
```bash
# After Phase 3 completion
# Run new test suite
bash /home/benjamin/.config/.claude/tests/test_coordinate_error_fixes.sh

# Expected output:
# ✓ Test passed: Scope detection identifies research-and-revise
# ✓ Test passed: Path extraction works correctly
# ✓ Test passed: EXISTING_PLAN_PATH saved to state
# ✓ Test passed: Planning phase contains Task invocation
# ✓ Test passed: Planning phase references revision-specialist.md
# ✓ Test passed: No /revise SlashCommand invocation
# ✓ Test passed: coordinate.md handles research-and-revise scope
# ==========================================
# Test Summary: coordinate_error_fixes
# ==========================================
# Tests run: 7
# Tests passed: 7
# Tests failed: 0
# ✓ All tests passed

# Run full test suite
bash /home/benjamin/.config/.claude/tests/run_all_tests.sh

# Expected: All tests pass including new test file
```

**Success Criteria**:
- ✓ 7 tests created covering all error scenarios
- ✓ All tests pass after fixes applied
- ✓ Test file integrated into `run_all_tests.sh`
- ✓ Test coverage prevents regression of both errors

---

### Phase 4: Update Documentation and Verify Standards Compliance

**Objective**: Document research-and-revise workflow patterns and verify architectural compliance

**Complexity**: Low (documentation updates, standards verification)

**Dependencies**: Phases 1-3 (implementation and testing complete)

**Files Modified**:
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`
- `/home/benjamin/.config/.claude/specs/665_research_the_output_homebenjaminconfigclaudespecs/reports/001_coordinate_error_analysis.md`

**Tasks**:

- [ ] **Task 4.1**: Add research-and-revise workflow example to command guide
  - **Location**: `coordinate-command-guide.md` (new section after existing examples)
  - **Content**:
    ```markdown
    ### Example 4: Research-and-Revise Workflow

    **Use Case**: Update existing plan based on new research findings

    **Command**:
    ```bash
    /coordinate "Revise the plan /home/benjamin/.config/.claude/specs/042_auth/plans/001_auth_plan.md to accommodate recent security research"
    ```

    **Workflow Execution**:
    1. Scope Detection: Identifies `research-and-revise` scope
    2. Path Extraction: Extracts `/path/to/042_auth/plans/001_auth_plan.md`
    3. State Persistence: Saves `EXISTING_PLAN_PATH` to workflow state
    4. Research Phase: Generates security research reports
    5. Planning Phase: Invokes revision-specialist agent
    6. Backup Creation: Agent creates timestamped backup
    7. Plan Revision: Agent applies research findings to plan
    8. Verification: Confirms backup exists and changes applied

    **Key Differences from Other Workflows**:
    - Uses existing topic directory (doesn't create new)
    - Invokes revision-specialist (not plan-architect)
    - Creates backup before modification
    - Preserves completed phases
    - Updates revision history section

    **Troubleshooting**:
    - **Error: "EXISTING_PLAN_PATH not set"**
      - Cause: Plan path missing from workflow description
      - Fix: Include full absolute path in workflow description
    - **Error: "Plan file does not exist"**
      - Cause: Path typo or incorrect location
      - Fix: Verify file exists: `test -f /path/to/plan.md`
    ```

- [ ] **Task 4.2**: Document subprocess isolation constraints
  - **Location**: `coordinate-command-guide.md` (Troubleshooting section)
  - **Content**:
    ```markdown
    ### Troubleshooting: EXISTING_PLAN_PATH Not Persisting

    **Symptom**: Error "research-and-revise workflow requires existing plan path"

    **Root Cause**: Subprocess isolation - `export` in library function doesn't persist to parent bash block

    **Technical Details**:
    - Each bash block in coordinate.md runs as separate subprocess
    - `export EXISTING_PLAN_PATH` in workflow-scope-detection.sh creates subprocess variable
    - Variable lost when subprocess exits (before next bash block)
    - **Solution**: Save to workflow state file immediately after extraction

    **Verification**:
    ```bash
    # Check workflow state file contains EXISTING_PLAN_PATH
    cat "${HOME}/.claude/tmp/workflow_coordinate_*.sh" | grep EXISTING_PLAN_PATH

    # Expected: EXISTING_PLAN_PATH=/absolute/path/to/plan.md
    ```

    **See Also**:
    - [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md)
    - [State Persistence Pattern](.claude/docs/concepts/patterns/state-persistence.md)
    ```

- [ ] **Task 4.3**: Verify Standard 11 compliance throughout coordinate.md
  - **Standard 11**: Imperative Agent Invocation Pattern
  - **Requirements**:
    - Commands invoke agents via Task tool (NOT SlashCommand)
    - Agent behavioral files referenced (`.claude/agents/*.md`)
    - Context injected via prompt
    - Completion signals verified
  - **Verification Checklist**:
    ```bash
    # Check all agent invocations use Task tool
    grep -n "Task {" /home/benjamin/.config/.claude/commands/coordinate.md

    # Expected: Lines for research, planning, implementation agents

    # Verify no SlashCommand invocations for delegation
    grep -n "SlashCommand" /home/benjamin/.config/.claude/commands/coordinate.md

    # Expected: No matches (or only in comments/documentation)

    # Verify behavioral file references
    grep -n "agents/.*\.md" /home/benjamin/.config/.claude/commands/coordinate.md

    # Expected: research-specialist.md, revision-specialist.md, plan-architect.md, etc.
    ```

- [ ] **Task 4.4**: Update research report with implementation results
  - **Location**: `001_coordinate_error_analysis.md` (add Implementation Results section)
  - **Content**:
    ```markdown
    ## Implementation Results

    **Implementation Date**: 2025-11-11
    **Plan Reference**: 665_research_the_output_homebenjaminconfigclaudespecs/plans/001_coordinate_fixes_implementation_plan.md

    ### Fix 1: EXISTING_PLAN_PATH Persistence

    **Implementation**: Added path extraction and state persistence in coordinate.md (lines 125-145)
    **Result**: Variable now persists across bash blocks via workflow state file
    **Test Coverage**: test_existing_plan_path_in_state() validates persistence
    **Status**: ✓ Complete

    ### Fix 2: Agent Delegation Pattern

    **Implementation**: Replaced /revise SlashCommand with revision-specialist agent invocation
    **Result**: Standard 11 compliance achieved, proper context injection enabled
    **Test Coverage**: test_planning_phase_uses_agent_delegation() validates pattern
    **Status**: ✓ Complete

    ### Fix 3: Regression Tests

    **Implementation**: Created test_coordinate_error_fixes.sh with 7 comprehensive tests
    **Result**: 100% test pass rate, prevents future regressions
    **Integration**: Added to run_all_tests.sh test suite
    **Status**: ✓ Complete

    ### Fix 4: Documentation Updates

    **Implementation**: Updated coordinate-command-guide.md with research-and-revise examples
    **Result**: Clear troubleshooting guidance for EXISTING_PLAN_PATH failures
    **Standards**: Verified Standard 11 compliance throughout coordinate.md
    **Status**: ✓ Complete
    ```

- [ ] **Task 4.5**: Run architecture compliance validation script
  - **Script**: `.claude/lib/validate-agent-invocation-pattern.sh`
  - **Target**: `coordinate.md`
  - **Expected**: No anti-patterns detected
  - **Verification**:
    ```bash
    bash /home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh \
      /home/benjamin/.config/.claude/commands/coordinate.md

    # Expected output:
    # ✓ All agent invocations use Task tool
    # ✓ All behavioral files properly referenced
    # ✓ No SlashCommand delegation detected
    # ✓ Standard 11 compliance verified
    ```

**Verification Checkpoint**:
```bash
# After Phase 4 completion
# 1. Check command guide has research-and-revise example
grep -A 20 "Example 4: Research-and-Revise" \
  /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md

# Expected: Example workflow with troubleshooting section

# 2. Verify Standard 11 compliance
bash /home/benjamin/.config/.claude/lib/validate-agent-invocation-pattern.sh \
  /home/benjamin/.config/.claude/commands/coordinate.md

# Expected: All checks pass

# 3. Check research report updated
grep "Implementation Results" \
  /home/benjamin/.config/.claude/specs/665_research_the_output_homebenjaminconfigclaudespecs/reports/001_coordinate_error_analysis.md

# Expected: Section present with completion status
```

**Success Criteria**:
- ✓ Command guide contains research-and-revise example
- ✓ Troubleshooting section documents subprocess isolation issue
- ✓ Standard 11 compliance verified (no violations)
- ✓ Research report updated with implementation results
- ✓ Architecture validation passes

---

## Testing Strategy

### Unit Tests
- Scope detection regex patterns
- Path extraction from workflow descriptions
- State persistence across bash blocks

### Integration Tests
- Agent delegation pattern (Task tool vs SlashCommand)
- Context injection to revision-specialist
- Completion signal verification

### End-to-End Tests
- Full research-and-revise workflow
- Backup creation and verification
- Plan modification and revision history

### Regression Prevention
- All tests added to `run_all_tests.sh`
- CI/CD integration (if available)
- Pre-commit hook validation (optional)

---

## Rollback Plan

### If Phase 1 Fails
- **Symptom**: State persistence breaks other workflows
- **Rollback**: Remove lines 125-145 from coordinate.md
- **Diagnosis**: Check state file format, verify append_workflow_state() function

### If Phase 2 Fails
- **Symptom**: Agent delegation causes errors or infinite loops
- **Rollback**: Restore original planning phase handler (lines 788-828)
- **Diagnosis**: Check agent behavioral file, verify context injection parameters

### If Tests Fail
- **Symptom**: New tests fail with implementation applied
- **Rollback**: Fix implementation to match test expectations
- **Diagnosis**: Review test logic, verify test fixtures correctly set up

---

## Success Criteria

### Functional Requirements
1. ✓ /coordinate correctly identifies research-and-revise scope from workflow description
2. ✓ EXISTING_PLAN_PATH extracted and persisted to workflow state
3. ✓ Planning phase invokes revision-specialist agent (not /revise slash command)
4. ✓ Revision-specialist receives all required context (paths, reports, standards)
5. ✓ Backup created before plan modification
6. ✓ Revision history updated with changes
7. ✓ Completion signal verified by orchestrator

### Architecture Compliance
8. ✓ Standard 11 (Imperative Agent Invocation) compliance verified
9. ✓ Behavioral Injection Pattern correctly implemented
10. ✓ State persistence pattern followed (append_workflow_state usage)
11. ✓ Verification fallback pattern enabled (fail-fast on missing paths)

### Testing Coverage
12. ✓ Unit tests cover scope detection, path extraction, state persistence
13. ✓ Integration tests cover end-to-end research-and-revise workflow
14. ✓ Regression tests prevent future breakage
15. ✓ All tests pass with 100% success rate

---

## Risk Assessment

### High Risk
- **Subprocess isolation**: Variable persistence fragile, must use state files
- **Mitigation**: Comprehensive testing of state persistence, fallback to filesystem discovery

### Medium Risk
- **Agent non-compliance**: Agent may not follow behavioral file exactly
- **Mitigation**: Verification checkpoints, fallback creation from agent output

### Low Risk
- **Backup failure**: Revision-specialist may skip backup creation
- **Mitigation**: Explicit verification in coordinate.md, warning if backup missing

---

## Dependencies

### External Dependencies
- `.claude/lib/workflow-state-machine.sh` (state machine library)
- `.claude/lib/state-persistence.sh` (state file operations)
- `.claude/lib/workflow-initialization.sh` (path validation)
- `.claude/agents/revision-specialist.md` (agent behavioral file)

### Internal Dependencies
- Phase 2 depends on Phase 1 (EXISTING_PLAN_PATH must be in state)
- Phase 3 depends on Phases 1-2 (tests validate fixes)
- Phase 4 depends on Phases 1-3 (documents completed implementation)

---

## Completion Checklist

**Before marking plan complete**:
- [ ] All 4 phases completed with verification checkpoints passed
- [ ] All tests passing (7 new tests + existing test suite)
- [ ] Documentation updated (command guide + research report)
- [ ] Architecture compliance verified (Standard 11 validation)
- [ ] End-to-end workflow tested with real plan revision
- [ ] Git commit created with descriptive message
- [ ] Implementation summary created in topic directory

---

## Revision History

### Version 1.0 (2025-11-11)
- Initial plan creation based on research report 001_coordinate_error_analysis.md
- 4 phases: EXISTING_PLAN_PATH persistence, agent delegation, tests, documentation
- Comprehensive task breakdown with verification checkpoints
- Integration with existing /coordinate infrastructure

---

PLAN_CREATED: /home/benjamin/.config/.claude/specs/665_research_the_output_homebenjaminconfigclaudespecs/plans/001_coordinate_fixes_implementation_plan.md
