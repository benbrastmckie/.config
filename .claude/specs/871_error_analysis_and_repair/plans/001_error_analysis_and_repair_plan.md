# Error Analysis and Repair - Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Error Logging Infrastructure Enhancement and Build Workflow Repair
- **Scope**: Add test mode metadata tagging, fix bash histexpand issues, implement state file persistence, enhance state transition diagnostics, improve build test phase error context, align test compliance expectations
- **Estimated Phases**: 7
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 68.5
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/871_error_analysis_and_repair/reports/001_error_analysis.md)
  - [Build Errors vs Plan 871 Gap Analysis](/home/benjamin/.config/.claude/specs/871_error_analysis_and_repair/reports/002_build_errors_plan_gap_analysis.md)
  - [Plan Revision Compliance Synthesis](/home/benjamin/.config/.claude/specs/871_error_analysis_and_repair/reports/002_plan_revision_compliance_synthesis.md)

## Overview

Analysis of error logs and build-output.md reveals two categories of issues requiring remediation: (1) error logging infrastructure gaps affecting 87% of logged errors, and (2) build workflow execution failures blocking build command completion. This comprehensive plan addresses both categories: test mode metadata tagging to reduce analysis noise by 87%, bash preprocessing safety using exit code capture pattern (compliant with Bash Tool Limitations documentation) to eliminate history expansion errors, state file persistence infrastructure to enable multi-block workflow continuation, enhanced state transition diagnostics with precondition validation, improved build test phase error context, and test compliance expectation alignment. Plan revised to achieve full compliance with .claude/docs/ standards (Phase 0 rewritten using documented preprocessing-safe patterns). Combined impact: production error analysis time reduced by 87%, build workflow completion rate increased from 0% to 100%, and test failure investigation time reduced by 50%.

## Research Summary

**Error Log Analysis** (001_error_analysis.md):
Error analysis of 23 logged errors reveals distinct patterns:
- **Test-Induced Errors**: 87% of errors originate from test commands with synthetic data (`nonexistent_command_xyz123`, `false`, `/nonexistent/state.sh`) but lack metadata tags
- **State Transition Failures**: Build workflow unable to transition to DOCUMENT state with insufficient diagnostic context about blocked preconditions
- **Test Phase Failures**: Build command test execution at line 354 fails with minimal context (only exit code, missing test output/command details)

The report identifies 3 root causes: (1) test errors lack metadata tagging, (2) state transition validation insufficient, and (3) test phase execution lacks error context. Five recommendations range from low to medium effort, with the top 3 providing 95% of value (test metadata, state diagnostics, test context).

**Build Output Gap Analysis** (002_build_errors_plan_gap_analysis.md):
Analysis of build-output.md reveals 5 distinct error categories in build workflow execution that were NOT addressed by original plan:
1. **Bash Histexpand Syntax Errors**: Line 322 histexpand errors (`!: command not found`) break bash block execution despite mitigation attempts
2. **State File Persistence Failures**: State file `.claude/tmp/build_state_id.txt` lost between blocks, preventing workflow continuation (CRITICAL)
3. **Test Script Execution Issues**: Test scripts require explicit `bash` prefix due to missing execute permissions or shebang issues
4. **Test Compliance Misalignment**: Test expects 6 blocks in /build, finds 5 with traps (1 documentation block intentionally excluded)
5. **State Transition Blocks**: Same state file loss issue prevents state management operations

Gap analysis shows original plan addressed only 1/5 error categories (20% coverage), leaving critical build workflow failures unresolved.

**Plan Revision Compliance Synthesis** (002_plan_revision_compliance_synthesis.md):
Compliance review of original plan 871 identified 1 critical blocking issue and 3 optional improvements. The blocking issue was Phase 0's histexpand remediation approach, which contradicted bash-tool-limitations.md by proposing runtime `set +H` directives that cannot prevent preprocessing-stage history expansion errors. The documented exit code capture pattern (lines 329-354) is the only preprocessing-safe approach. Plan revised to replace all `if ! function_call` patterns with explicit exit code capture. Optional improvements address test documentation redundancy, test script validation enforcement, and WHAT/WHY comment clarification.

**Recommended approach based on combined research**:
1. CRITICAL: State file persistence infrastructure (blocks build workflow - 0% completion rate currently)
2. CRITICAL: Bash preprocessing safety using exit code capture pattern (documented in bash-tool-limitations.md:329-354)
3. HIGH: Test mode metadata (87% noise reduction in error analysis)
4. HIGH: State transition diagnostics (enables debugging without code inspection)
5. MEDIUM: Build test phase context (50% debugging time reduction)
6. MEDIUM: Test script execution validation (eliminates workaround invocations)
7. LOW: Test compliance alignment (reduces false positives in test suite)

## Success Criteria

**Error Logging Infrastructure**:
- [ ] Error logs include `is_test` metadata field for test-induced errors
- [ ] `/errors` command supports `--exclude-tests` flag to filter test errors
- [ ] State transition failures log detailed precondition validation diagnostics
- [ ] Build command test phase captures test output and logs comprehensive error context

**Build Workflow Repair**:
- [ ] Build command bash blocks execute without histexpand errors
- [ ] State files persist across all multi-block workflow transitions
- [ ] Build workflow completes successfully (0% → 100% completion rate)
- [ ] Test scripts execute directly without requiring explicit `bash` prefix
- [ ] Test compliance checks align with implementation design decisions

**Validation**:
- [ ] All existing tests pass with enhanced error logging
- [ ] Build workflow test phase completes without state file errors
- [ ] Documentation updated for test mode usage, state transition debugging, and state file persistence

## Technical Design

### Architecture Decisions

**Bash Preprocessing Safety**:
- Replace all `if ! function_call` patterns with exit code capture pattern
- Replace all `if [[ ! "$PATH" = /* ]]` patterns with preprocessing-safe alternatives
- Use explicit exit code capture: `function_call; EXIT_CODE=$?; if [ $EXIT_CODE -ne 0 ]; then`
- No functional changes to bash block logic, only preprocessing-safe syntax
- Document exit code capture pattern in Bash Tool Limitations guide
- Cross-reference preprocessing safety in Command Development Guide

**State File Persistence Infrastructure**:
- Implement atomic state file write using temporary file + move pattern
- Add state file path validation function: check existence before read operations
- Implement recovery mechanism: recreate with workflow metadata if lost
- Use environment variable for state file path (persistent across blocks) instead of temp file location
- Add error logging for all state file operations using centralized error logging
- Design: Write → Validate → Read → Cleanup lifecycle with verification at each step

**Error Metadata Schema Enhancement**:
- Add `is_test` boolean field to error log JSON schema
- Maintain backward compatibility (field optional, defaults to false)
- Detection mechanism: check `TEST_MODE` environment variable in error-handling library

**State Transition Validation**:
- Add precondition validation layer before `set_state()` calls
- Log validation failures with state graph context: `{current: "X", target: "Y", blocked_by: ["reasons"]}`
- No changes to state machine transitions, only diagnostic logging enhancement
- Depends on state file persistence for reliable state tracking

**Build Test Phase Context**:
- Capture test output to temporary file before exit code check
- Extract test command name from `$TEST_COMMAND` variable
- Include test output file path, command name, and suite path in error context
- Add pre-test validation for test file existence and dependencies
- Depends on state persistence for workflow continuity

**Test Script Execution Prerequisites**:
- Standardize all test scripts with execute permissions (`chmod +x`)
- Verify shebang line presence: `#!/bin/bash` or `#!/usr/bin/env bash`
- Document as requirement in Testing Protocols
- No changes to test logic, only execution mechanics

**Test Compliance Expectation Alignment**:
- Update test assertions to match actual block counts (not hardcoded expectations)
- Document exclusion of documentation blocks from trap requirements
- Add design rationale to error handling pattern documentation

### Component Interactions

**Build Workflow Flow** (with fixes):
```
Multi-Block Command Execution
    ↓ exit code capture pattern (Phase 0: preprocessing-safe)
Bash Block Execution
    ↓ no preprocessing errors
State File Operations (Phase 1)
    ↓ create_state_file() → atomic write
    ↓ validate_state_file() → existence check
    ↓ persist across blocks
State Orchestration (Phase 4)
    ↓ set_state() with precondition validation
    ↓ diagnostic logging on failure
Test Execution (Phase 5)
    ↓ capture test output
    ↓ log comprehensive context
Build Completion (0% → 100% success rate)
```

**Error Logging Flow** (with metadata):
```
Test Scripts
    ↓ export TEST_MODE=true
Error Handling Library (error-handling.sh)
    ↓ log_command_error() checks TEST_MODE
    ↓ adds is_test: true metadata
Error Log (errors.jsonl)
    ↓
/errors Command
    ↓ --exclude-tests flag filters
Production Error Analysis (noise reduced 87%)
```

**State Transition Flow** (with diagnostics):
```
State Orchestration
    ↓ state file validated (Phase 1)
    ↓ set_state() called
Precondition Validation (Phase 4)
    ↓ checks prerequisites
    ↓ logs failure diagnostics if blocked
    ↓ includes state graph context
Error Log (with state graph context)
    ↓
Developer Debugging (state transition clear)
```

**Test Execution Flow** (with prerequisites):
```
Test Scripts (Phase 6)
    ↓ execute permissions verified
    ↓ shebang present
Direct Invocation (./.claude/tests/test_*.sh)
    ↓ no explicit bash prefix needed
Test Compliance Validation (Phase 7)
    ↓ expectations aligned with design
    ↓ documentation blocks excluded
Compliance Tests Pass (no false positives)
```

### File Modifications

**Phase 0 (Preprocessing Safety)**:
1. `.claude/commands/build.md`: Replace `if ! ` patterns with exit code capture
2. `.claude/commands/plan.md`: Replace `if ! ` patterns with exit code capture
3. `.claude/commands/debug.md`: Replace `if ! ` patterns with exit code capture
4. `.claude/commands/repair.md`: Replace `if ! ` patterns with exit code capture
5. `.claude/commands/revise.md`: Replace `if ! ` patterns with exit code capture
6. `.claude/docs/troubleshooting/bash-tool-limitations.md`: Add exit code capture pattern examples
7. `.claude/docs/guides/development/command-development/command-development-fundamentals.md`: Cross-reference preprocessing safety

**Phase 1 (State Persistence)**:
8. `.claude/lib/workflow/state-orchestration.sh` (or similar): Add state file functions
9. `.claude/commands/build.md`: Update to use persistent state file infrastructure

**Phase 2 (Test Metadata)**:
10. `.claude/lib/core/error-handling.sh`: Add `is_test` detection and logging
11. Test scripts (`.claude/tests/*.sh`): Export `TEST_MODE=true` in test setup
12. `.claude/docs/reference/standards/testing-protocols.md`: Add test mode code examples
13. `.claude/docs/concepts/patterns/error-handling.md`: Document `is_test` field usage

**Phase 3 (Errors Filtering)**:
14. `.claude/commands/errors.md` or `.claude/scripts/errors.sh`: Add `--exclude-tests` flag
15. `.claude/docs/guides/commands/errors-command-guide.md`: Document filtering usage

**Phase 4 (State Diagnostics)**:
16. State-based orchestration files: Add precondition validation logging
17. `.claude/docs/architecture/state-based-orchestration-overview.md`: Add prerequisites and diagnostics

**Phase 5 (Test Context)**:
18. `.claude/commands/build.md`: Enhance test phase error context capture
19. `.claude/docs/guides/commands/build-command-guide.md`: Document test phase error handling

**Phase 6 (Test Scripts)**:
20. All test scripts (`.claude/tests/*.sh`): Add execute permissions and verify shebangs
21. `.claude/tests/run_all_tests.sh`: Add validation for execute permissions and shebangs (if runner exists)
22. `.claude/docs/reference/standards/testing-protocols.md`: Document script requirements in "Test Script Requirements" section

**Phase 7 (Compliance)**:
23. `.claude/tests/test_bash_error_compliance.sh`: Update block count expectations
24. `.claude/docs/concepts/patterns/error-handling.md`: Document block exclusion rationale

## Implementation Phases

### Phase 0: Bash History Expansion Preprocessing Safety [NOT STARTED]
dependencies: []

**Objective**: Eliminate bash history expansion preprocessing errors using exit code capture pattern

**Complexity**: Medium

**Tasks**:
- [ ] Audit all bash blocks in `.claude/commands/build.md` for `if ! ` patterns (grep: `grep -n "if ! " .claude/commands/build.md`)
- [ ] Replace `if ! function_call` patterns with exit code capture pattern (file: `.claude/commands/build.md`):
  ```bash
  function_call
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    # error handling
  fi
  ```
- [ ] Audit path validation blocks for `if [[ ! "$PATH" = /* ]]` patterns
- [ ] Replace with preprocessing-safe pattern (file: `.claude/commands/build.md`):
  ```bash
  [[ "$PATH" = /* ]]
  IS_ABSOLUTE=$?
  if [ $IS_ABSOLUTE -ne 0 ]; then
    PATH="$(pwd)/$PATH"
  fi
  ```
- [ ] Test updated bash blocks for absence of `!: command not found` errors
- [ ] Apply same exit code capture pattern to plan.md, debug.md, repair.md, revise.md (files: `.claude/commands/plan.md`, `.claude/commands/debug.md`, `.claude/commands/repair.md`, `.claude/commands/revise.md`)
- [ ] Add exit code capture pattern examples to existing Bash Tool Limitations documentation section "Bash History Expansion Preprocessing Errors" (file: `.claude/docs/troubleshooting/bash-tool-limitations.md`, lines 290-458)
- [ ] Cross-reference preprocessing safety pattern in Command Development Guide (file: `.claude/docs/guides/development/command-development/command-development-fundamentals.md`)

**Testing**:
```bash
# Test build command with complex plan requiring state transitions
/build /tmp/test_plan.md 1

# Verify no preprocessing errors
grep -i "!: command not found" <(build output) && echo "FAIL: Preprocessing errors remain" || echo "PASS: No preprocessing errors"

# Test across all commands with negated conditionals
for cmd in build plan debug repair revise; do
  echo "Testing /$cmd for preprocessing safety..."
  # Invoke with test inputs
done
```

**Expected Duration**: 2 hours

### Phase 1: State File Persistence Infrastructure [COMPLETE]
dependencies: []

**Objective**: Implement robust state file persistence for multi-block workflows to prevent state loss between blocks

**Complexity**: Medium

**Tasks**:
- [x] Identify where state file is created in build workflow (grep for `build_state_id.txt` in `.claude/commands/build.md`)
- [x] Add atomic state file write function to state orchestration library (file: `.claude/lib/workflow/state-orchestration.sh` or similar)
- [x] Implement state file path validation function: check file exists before reading (file: state orchestration library)
- [x] Add state file recovery mechanism: recreate with appropriate metadata if lost (file: state orchestration library)
- [x] Update build command to use persistent state file location (environment variable instead of tmp file) (file: `.claude/commands/build.md`)
- [x] Add state file verification after each block that creates state file (file: `.claude/commands/build.md`)
- [x] Create state file cleanup function for workflow completion (file: state orchestration library)
- [x] Add error logging for state file operations using centralized error logging (file: state orchestration library)

**Testing**:
```bash
# Test state file persistence across multiple bash blocks
source .claude/lib/workflow/state-orchestration.sh
source .claude/lib/core/error-handling.sh

ensure_error_log_exists
COMMAND_NAME="/test-state-persistence"
WORKFLOW_ID="test_state_$(date +%s)"

# Block 1: Create state file
create_state_file "$WORKFLOW_ID"
STATE_FILE_PATH=$(get_state_file_path "$WORKFLOW_ID")
[ -f "$STATE_FILE_PATH" ] && echo "✓ State file created" || echo "✗ State file creation failed"

# Block 2: Verify state file persists
STATE_FILE_PATH=$(get_state_file_path "$WORKFLOW_ID")
[ -f "$STATE_FILE_PATH" ] && echo "✓ State file persisted" || echo "✗ State file lost between blocks"

# Block 3: Cleanup
cleanup_state_file "$WORKFLOW_ID"
[ ! -f "$STATE_FILE_PATH" ] && echo "✓ State file cleaned up" || echo "✗ State file cleanup failed"
```

**Expected Duration**: 3 hours

### Phase 2: Test Mode Metadata Infrastructure [NOT STARTED]
dependencies: []

**Objective**: Add test mode detection and metadata tagging to error logging infrastructure

**Complexity**: Low

**Tasks**:
- [ ] Update error log JSON schema documentation to include `is_test` boolean field (file: `.claude/docs/concepts/patterns/error-handling.md`)
- [ ] Modify `log_command_error()` function in error-handling.sh to check `TEST_MODE` environment variable (file: `.claude/lib/core/error-handling.sh`)
- [ ] Add `is_test` field to error log output when `TEST_MODE=true` (file: `.claude/lib/core/error-handling.sh`)
- [ ] Add test case validating `is_test` metadata appears in error logs (file: `.claude/tests/test_error_logging_metadata.sh`)
- [ ] Verify Testing Protocols documentation includes `TEST_MODE=true` requirement (existing at lines 195-198)
- [ ] Add code examples to Testing Protocols showing `TEST_MODE` integration in test setup (file: `.claude/docs/reference/standards/testing-protocols.md`)
- [ ] Document `is_test` field usage in Error Handling Pattern examples (file: `.claude/docs/concepts/patterns/error-handling.md`)

**Testing**:
```bash
# Create test script that exports TEST_MODE=true and logs error
cat > /tmp/test_metadata.sh <<'EOF'
#!/bin/bash
source .claude/lib/core/error-handling.sh
ensure_error_log_exists
export TEST_MODE=true
COMMAND_NAME="/test-metadata"
WORKFLOW_ID="test_metadata_$(date +%s)"
log_command_error "execution_error" "Test error message" '{"test_key": "test_value"}'
EOF

bash /tmp/test_metadata.sh

# Verify is_test field appears in error log
grep -q '"is_test":true' .claude/data/logs/errors.jsonl && echo "✓ Test metadata logged" || echo "✗ Test metadata missing"
```

**Expected Duration**: 1.5 hours

### Phase 3: Errors Command Test Filtering [NOT STARTED]
dependencies: [2]

**Objective**: Add `--exclude-tests` flag to /errors command for filtering test-induced errors

**Complexity**: Low

**Tasks**:
- [ ] Locate /errors command implementation (search for errors command file in .claude/commands/ or .claude/scripts/)
- [ ] Add `--exclude-tests` flag to argument parser (default: false for backward compatibility)
- [ ] Implement filter logic to skip errors where `is_test: true` when flag enabled
- [ ] Update /errors command help text to document `--exclude-tests` flag
- [ ] Add test case validating test errors are filtered when flag used (file: `.claude/tests/test_errors_command_filter.sh`)
- [ ] Update Errors Command Guide documentation with filter usage examples (file: `.claude/docs/guides/commands/errors-command-guide.md`)

**Testing**:
```bash
# Create test and production errors
export TEST_MODE=true
.claude/scripts/log_test_error.sh  # Logs test error

unset TEST_MODE
.claude/scripts/log_production_error.sh  # Logs production error

# Verify filtering works
ERROR_COUNT_ALL=$(/errors --limit 100 | wc -l)
ERROR_COUNT_FILTERED=$(/errors --exclude-tests --limit 100 | wc -l)

[ "$ERROR_COUNT_FILTERED" -lt "$ERROR_COUNT_ALL" ] && echo "✓ Test filter working" || echo "✗ Filter not working"
```

**Expected Duration**: 2 hours

### Phase 4: State Transition Diagnostics [NOT STARTED]
dependencies: [1, 2]

**Objective**: Enhance state transition validation with precondition checking and detailed diagnostic logging

**Complexity**: Medium

**Tasks**:
- [ ] Search for state transition functions (grep for "set_state" or "transition" in .claude/lib/ or state orchestration files)
- [ ] Identify state-based orchestration implementation file (likely in .claude/lib/workflow/ or commands/build.md)
- [ ] Add precondition validation function before each `set_state()` call (validate prerequisites for target state)
- [ ] Log validation failures with state graph context: current state, target state, blocked prerequisites
- [ ] Update error context to include `{current: "STATE", target: "STATE", blocked_by: ["reason1", "reason2"]}`
- [ ] Add state transition validation test case (file: `.claude/tests/test_state_transition_validation.sh`)
- [ ] Document state transition prerequisites in State-Based Orchestration docs (file: `.claude/docs/architecture/state-based-orchestration-overview.md`)
- [ ] Add state transition diagram showing valid transitions and prerequisites (file: `.claude/docs/architecture/state-based-orchestration-overview.md`)

**Testing**:
```bash
# Create test workflow that attempts invalid state transition
cat > /tmp/test_state_validation.sh <<'EOF'
#!/bin/bash
source .claude/lib/core/error-handling.sh
source .claude/lib/workflow/state-orchestration.sh  # Adjust path if different

ensure_error_log_exists
COMMAND_NAME="/test-state"
WORKFLOW_ID="test_state_$(date +%s)"

# Attempt transition to DOCUMENT without completing TEST
set_state "TEST"
set_state "DOCUMENT"  # Should fail and log diagnostics
EOF

bash /tmp/test_state_validation.sh

# Verify diagnostic context logged
grep -q '"blocked_by"' .claude/data/logs/errors.jsonl && echo "✓ State diagnostics logged" || echo "✗ State diagnostics missing"
```

**Expected Duration**: 3 hours

### Phase 5: Build Test Phase Error Context [NOT STARTED]
dependencies: [1, 2]

**Objective**: Capture comprehensive test execution context during build workflow test phase

**Complexity**: Medium

**Tasks**:
- [ ] Locate build command test execution block (grep for "TEST_COMMAND" or line ~354 in build command)
- [ ] Add test output capture to temporary file before exit code check (file: `.claude/commands/build.md` or build script)
- [ ] Extract test command name from `$TEST_COMMAND` variable and include in error context
- [ ] Update error logging to include test output file path, command name, and test suite path
- [ ] Add pre-test validation: check test file exists, test dependencies available
- [ ] Log pre-test validation failures separately from test execution failures
- [ ] Add test case for build command test phase error context (file: `.claude/tests/test_build_test_phase_context.sh`)
- [ ] Update build command documentation with test phase error handling (file: `.claude/docs/guides/commands/build-command-guide.md` or create if missing)

**Testing**:
```bash
# Create test plan with intentionally failing test
cat > /tmp/test_plan.md <<'EOF'
# Test Plan

## Phase 1: Test Phase
- [ ] Run failing test

Testing:
```bash
exit 1  # Intentional failure
```
EOF

# Run build command with test plan
/build /tmp/test_plan.md 1

# Verify error context includes test command and output path
ERROR_LOG=$(tail -1 .claude/data/logs/errors.jsonl)
echo "$ERROR_LOG" | grep -q '"test_command"' && echo "✓ Test command logged" || echo "✗ Test command missing"
echo "$ERROR_LOG" | grep -q '"test_output"' && echo "✓ Test output path logged" || echo "✗ Test output path missing"
```

**Expected Duration**: 1.5 hours

### Phase 6: Test Script Execution Prerequisites [NOT STARTED]
dependencies: []

**Objective**: Validate and fix test script execution prerequisites to enable direct script invocation

**Complexity**: Low

**Tasks**:
- [ ] Identify all test scripts in `.claude/tests/` directory (use Glob: `**/*.sh` in tests directory)
- [ ] Check execute permissions for each test script: `test -x script.sh`
- [ ] Add execute permissions to all test scripts: `chmod +x .claude/tests/*.sh` (file: all test scripts)
- [ ] Verify shebang line exists in all test scripts: `#!/bin/bash` or `#!/usr/bin/env bash`
- [ ] Add shebang to any test scripts missing it (file: affected test scripts)
- [ ] Update `.claude/tests/run_all_tests.sh` to validate execute permissions before running tests (if runner exists)
- [ ] Add pre-test validation: check shebang exists, fail-fast if missing
- [ ] Add execute permission check to test discovery logic
- [ ] Test direct invocation of test scripts (without explicit `bash` prefix): `./.claude/tests/test_*.sh`
- [ ] Document test script requirements in Testing Protocols: create "Test Script Requirements" section (file: `.claude/docs/reference/standards/testing-protocols.md`)

**Testing**:
```bash
# Verify all test scripts have execute permissions and shebangs
for test_script in .claude/tests/test_*.sh; do
  if [ ! -x "$test_script" ]; then
    echo "✗ Missing execute permission: $test_script"
  else
    echo "✓ Has execute permission: $test_script"
  fi

  if ! head -1 "$test_script" | grep -q '^#!/'; then
    echo "✗ Missing shebang: $test_script"
  else
    echo "✓ Has shebang: $test_script"
  fi
done

# Test direct invocation
./.claude/tests/test_bash_error_compliance.sh && echo "✓ Direct invocation works" || echo "✗ Direct invocation failed"
```

**Expected Duration**: 1 hour

### Phase 7: Test Compliance Expectation Alignment [NOT STARTED]
dependencies: [0, 1]

**Objective**: Align test compliance checks with implementation design decisions

**Complexity**: Low

**Tasks**:
- [ ] Read test compliance script to understand current expectations (file: `.claude/tests/test_bash_error_compliance.sh`)
- [ ] Identify hardcoded block count expectations in test (grep for block count assertions)
- [ ] Review build command to count actual bash blocks and identify documentation blocks (file: `.claude/commands/build.md`)
- [ ] Update test expectations to match actual block counts (file: `.claude/tests/test_bash_error_compliance.sh`)
- [ ] Document exclusion of documentation blocks from trap requirements in test comments
- [ ] Add design decision documentation: why documentation blocks are excluded from trap requirements (file: `.claude/docs/concepts/patterns/error-handling.md`)
- [ ] Test compliance check with updated expectations: `./.claude/tests/test_bash_error_compliance.sh`
- [ ] Verify test now passes with correct implementation (all phases should show ✓)

**Testing**:
```bash
# Run compliance test and verify no false positives
./.claude/tests/test_bash_error_compliance.sh

# Expected output:
# ✓ /plan: N/N blocks (100% coverage)
# ✓ /build: M/M blocks (100% coverage, documentation blocks excluded by design)
# ✓ /debug: X/X blocks (100% coverage)
# ✓ /repair: Y/Y blocks (100% coverage)
# ✓ /revise: Z/Z blocks (100% coverage)
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Testing
- Test exit code capture pattern with various negated conditional scenarios
- Test state file creation, persistence, and cleanup functions
- Test error-handling library with and without `TEST_MODE` environment variable
- Test /errors command filtering with mixed test/production error logs
- Test state transition validation with various invalid state sequences
- Test build command test phase context capture with failing tests
- Test script execution permissions and shebang validation
- Test compliance check alignment with actual block counts

### Integration Testing
- Execute build workflow end-to-end to verify preprocessing safety (no `!: command not found` errors)
- Run multi-block workflows to verify state file persistence across blocks
- Run full test suite with `TEST_MODE=true` and verify all test errors tagged
- Execute build workflow with intentional test failures and verify error context
- Run /errors command with production workload and verify test noise reduced
- Invoke test scripts directly (without bash prefix) to verify execution prerequisites
- Run compliance tests to verify alignment with design decisions

### Validation Testing
- Build workflow completion rate: verify 0% → 100% improvement
- State file persistence: verify no state loss across all multi-block workflows
- Before/after comparison: count production-relevant errors with and without test filtering
- State transition failure scenario: verify diagnostic context enables debugging without code inspection
- Build test failure scenario: verify test output is captured and accessible
- Test script invocation: verify direct execution works for all test scripts
- Compliance test false positives: verify elimination of design-based failures

### Test Coverage Requirements
- Bash preprocessing safety: Coverage across all multi-block commands with exit code capture pattern
- State file operations: 100% coverage of create/persist/cleanup/recovery paths
- Error-handling library: 100% coverage of `is_test` logic paths
- /errors command: Test filtering enabled/disabled paths
- State validation: All state transition prerequisite checks
- Build test phase: Test output capture and error context paths
- Test script validation: All test scripts in `.claude/tests/`
- Compliance checks: All commands with bash blocks

## Documentation Requirements

### Update Existing Documentation
- `.claude/docs/troubleshooting/bash-tool-limitations.md`: Add exit code capture pattern examples to existing "Bash History Expansion Preprocessing Errors" section (lines 290-458)
- `.claude/docs/guides/development/command-development/command-development-fundamentals.md`: Cross-reference preprocessing safety pattern from Bash Tool Limitations
- `.claude/docs/architecture/state-based-orchestration-overview.md`: Add state file persistence infrastructure and recovery mechanisms
- `.claude/docs/concepts/patterns/error-handling.md`: Add `is_test` field to error log schema and document test mode usage
- `.claude/docs/reference/standards/testing-protocols.md`: Add code examples for `TEST_MODE` integration, document test script execution prerequisites (permissions, shebangs) in "Test Script Requirements" section
- `.claude/docs/guides/commands/errors-command-guide.md`: Document `--exclude-tests` flag usage
- `.claude/docs/architecture/state-based-orchestration-overview.md`: Add state transition prerequisites and diagnostics

### Create New Documentation (if missing)
- `.claude/docs/guides/commands/build-command-guide.md`: Document test phase error handling, context capture, and state file persistence (only if build guide doesn't exist)

### Documentation Standards
- Follow CLAUDE.md documentation policy (no emojis, clear examples, CommonMark)
- **Documentation files** (`.claude/docs/`) SHOULD include design rationale (WHY this pattern exists)
- **Implementation code comments** MUST describe WHAT code does only (not WHY - see Output Formatting Standards)
- Include code examples for exit code capture pattern (preprocessing safety)
- Document state file persistence lifecycle and recovery mechanisms
- Include code examples for test mode usage and error log filtering
- Add state transition diagrams using Unicode box-drawing (show prerequisites)
- Cross-reference Error Handling Pattern for error context requirements
- Document test script requirements: execute permissions, shebangs, TEST_MODE integration (file: `.claude/docs/reference/standards/testing-protocols.md` - "Test Script Requirements" section)

## Dependencies

### Internal Dependencies
- Bash preprocessing safety (Phase 0) - can run in parallel with other phases
- State file persistence infrastructure (Phase 1) - CRITICAL for build workflow, blocks Phase 4 and Phase 5
- Error-handling library (`.claude/lib/core/error-handling.sh`) - must be updated first (Phase 2)
- /errors command implementation - depends on error log schema enhancement (Phase 3 depends on Phase 2)
- State-based orchestration code - depends on state file infrastructure (Phase 4 depends on Phase 1 and Phase 2)
- Build command implementation - depends on state persistence and error logging (Phase 5 depends on Phase 1 and Phase 2)
- Test script validation (Phase 6) - can run in parallel with other phases
- Test compliance alignment (Phase 7) - depends on preprocessing safety and state fixes (Phase 7 depends on Phase 0 and Phase 1)

### External Dependencies
- Bash 4.0+ for associative arrays (existing requirement)
- `jq` for JSON parsing in /errors command (existing requirement)
- Test framework infrastructure (existing)

### Risk Mitigation
- **Preprocessing Safety Impact**: Exit code capture pattern is functionally equivalent to `if ! ` (low risk - semantics preserved)
- **State File Persistence**: Atomic writes and validation prevent data corruption (medium risk - critical for workflow)
- **Backward Compatibility**: `is_test` field optional in error logs (defaults to false if missing)
- **Test Suite Impact**: Gradual rollout of `TEST_MODE=true` across test scripts (no breakage if some tests don't set it)
- **State Machine Risk**: Only adding diagnostic logging, not changing state transitions (no functional impact)
- **Test Script Changes**: Execute permission changes isolated to test directory (low risk)
- **Compliance Test Updates**: Only updating assertions, not test logic (low risk)

## Notes

### Implementation Order Rationale
- **Phase 0 (Preprocessing Safety)**: Can run in parallel - isolated bash block pattern changes
- **Phase 1 (State Persistence)**: CRITICAL - must complete before Phases 4 and 5 (build workflow blocked)
- **Phase 2 (Test Metadata)**: Foundation for Phase 3 (errors filtering)
- **Phase 3 (Errors Filtering)**: Depends on Phase 2 (error log schema)
- **Phase 4 (State Diagnostics)**: Depends on Phases 1 and 2 (state infrastructure + error logging)
- **Phase 5 (Test Context)**: Depends on Phases 1 and 2 (state persistence + error logging)
- **Phase 6 (Test Scripts)**: Can run in parallel - isolated test directory changes
- **Phase 7 (Compliance)**: Depends on Phases 0 and 1 (fixes must be in place before test alignment)

**Parallelization Opportunities**:
- Wave 1: Phases 0, 1, 2, 6 (independent)
- Wave 2: Phases 3, 4 (depend on Phase 2)
- Wave 3: Phase 5 (depends on Phases 1 and 2)
- Wave 4: Phase 7 (depends on Phases 0 and 1)

This ordering enables ~40% time savings through parallel execution while respecting critical dependencies.

### Complexity Justification
Score of 68.5 reflects comprehensive scope combining infrastructure enhancement and workflow repair:
- Well-defined scope from dual research analysis (error logs + build output)
- Clear implementation strategy for each phase (8 distinct objectives)
- Medium-risk changes (state file persistence is critical, other changes are low-risk)
- No architectural changes required (enhancements to existing infrastructure)
- Addresses 100% of identified error categories (vs. 20% in original plan)

### Plan Revision Rationale
Original plan addressed only error logging infrastructure (1/5 error categories from build-output.md). Gap analysis revealed build workflow execution failures were completely unaddressed. Revised plan now covers:
1. **Original scope** (Phases 2-5): Test metadata, errors filtering, state diagnostics, test context
2. **New scope** (Phases 0, 1, 6, 7): Histexpand remediation, state persistence, test script execution, compliance alignment

This revision increases coverage from 20% to 100% of identified errors while maintaining focused, actionable phases.

### Research Recommendations Not Included
From 001_error_analysis.md:
- Recommendation 4 (Standardize Test Error Sources): Deferred to future work (nice-to-have, not critical)
- Recommendation 5 (Error Message Enhancement for State Files): Incorporated into Phase 1 (state file persistence with error context)

From 002_build_errors_plan_gap_analysis.md:
- All 4 recommendations incorporated into revised plan (Phases 0, 1, 6, 7)
