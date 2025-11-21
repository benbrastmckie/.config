# Error Analysis and Repair Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Error Analysis and Repair Workflow
- **Scope**: Comprehensive error remediation addressing infrastructure failures, build workflow issues, and standards compliance
- **Estimated Phases**: 8
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 95.5
- **Research Reports**:
  - [Error Analysis Report](../reports/001_error_analysis.md)
  - [Build Errors Plan Gap Analysis](../reports/002_build_errors_plan_gap_analysis.md)
  - [Plan Revision Compliance Synthesis](../reports/002_plan_revision_compliance_synthesis.md)

## Overview

This plan addresses critical production failures identified across error logging, build workflow execution, and bash preprocessing. Analysis of 10 production errors reveals 5 distinct root causes: library sourcing inconsistency (40%), platform-specific path assumptions (20%), agent output contract violations (20%), error trap initialization failures (10%), and bash history expansion preprocessing errors affecting build workflows. The plan implements comprehensive fixes across 8 phases targeting immediate workflow unblocking and long-term infrastructure reliability.

## Research Summary

Key findings from research reports inform this implementation:

**Error Pattern Analysis** (001_error_analysis.md):
- 60% execution errors (all exit code 127 "command not found")
- Library functions not available: save_completed_states_to_state, append_workflow_state, initialize_workflow_paths
- Platform incompatibility: /etc/bashrc sourcing fails on Linux
- Agent failures: topic naming agent not creating output files
- Parse errors: trap command quote escaping issues

**Build Workflow Failures** (002_build_errors_plan_gap_analysis.md):
- 5 error categories in build execution (histexpand syntax, state file persistence, test script execution, test compliance, state transitions)
- Bash history expansion preprocessing errors cannot be fixed with runtime set +H
- State file loss between workflow blocks prevents completion
- Test scripts lack execute permissions and proper shebangs

**Standards Compliance Requirements** (002_plan_revision_compliance_synthesis.md):
- Exit code capture pattern required for preprocessing safety (bash-tool-limitations.md:328-377)
- WHAT/WHY comment distinction: code comments describe WHAT, docs explain WHY
- Test validation enforcement needed beyond one-time chmod
- Documentation should enhance existing requirements rather than duplicate

**Recommended Approach**: Implement standardized command initialization, platform-aware resource sourcing, preprocessing-safe bash patterns, robust state file persistence, and comprehensive test script validation with enforcement mechanisms.

## Success Criteria

- [ ] All library sourcing errors eliminated (0 exit code 127 for library functions)
- [ ] Cross-platform bashrc sourcing working on Linux and macOS
- [ ] Topic naming agent failures reduced to <5% (with diagnostic logging)
- [ ] Build workflow completes without state file errors
- [ ] Bash preprocessing errors eliminated (0 "!: command not found" errors)
- [ ] Test scripts executable with proper shebangs (100% compliance)
- [ ] Test mode detection working in error logs (is_test field populated)
- [ ] Error filtering functional (/errors --exclude-tests removes test errors)
- [ ] State transition diagnostics provide actionable error messages
- [ ] Build test phase captures comprehensive error context

## Technical Design

### Architecture Overview

The implementation spans three architectural layers:

**Layer 1: Command Initialization Infrastructure**
- Centralized library loader (command-init.sh) sourcing core libraries
- Function existence validation with helpful error messages
- Platform-aware resource sourcing (bashrc, environment setup)
- Pre-flight checks for command prerequisites

**Layer 2: Bash Execution Safety**
- Exit code capture pattern replacing negated conditionals (if ! pattern)
- Preprocessing-safe path validation
- History expansion error elimination
- Atomic state file operations with validation

**Layer 3: Error Context and Diagnostics**
- Test mode detection (TEST_MODE environment variable)
- Error log filtering (--exclude-tests flag)
- State transition precondition validation
- Enhanced error context capture in build workflows

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│ Command Invocation (/build, /plan, /debug, etc.)           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ command-init.sh (Standardized Initialization)              │
│ - Source error-handling.sh                                  │
│ - Source state-management.sh                                │
│ - Source workflow-initialization.sh                         │
│ - Platform detection and bashrc sourcing                    │
│ - Function existence validation                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Workflow Execution (Bash Blocks)                            │
│ - Exit code capture pattern (preprocessing safe)            │
│ - Atomic state file operations                              │
│ - Error context logging with test mode detection            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ Error Logging and Analysis                                  │
│ - is_test metadata field                                    │
│ - Filtering capabilities (--exclude-tests)                  │
│ - Enhanced diagnostics (state transitions, build phase)     │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Centralized Initialization**: Single command-init.sh prevents library sourcing inconsistency (addresses 40% of errors)
2. **Exit Code Capture**: Only preprocessing-safe pattern per bash-tool-limitations.md:329-354 (runtime set +H ineffective)
3. **Platform Detection**: Multi-location bashrc sourcing handles Linux/macOS differences gracefully
4. **Atomic State Operations**: State file writes with fsync and validation prevent loss between blocks
5. **Test Runner Validation**: Ongoing enforcement prevents permission degradation (beyond one-time chmod)

## Implementation Phases

### Phase 0: Bash History Expansion Preprocessing Safety [NOT STARTED]
dependencies: []

**Objective**: Eliminate bash history expansion preprocessing errors using exit code capture pattern

**Complexity**: Medium

**Tasks**:
- [ ] Audit all bash blocks in .claude/commands/build.md for `if ! ` patterns
  - Use grep: `grep -n "if ! " /home/benjamin/.config/.claude/commands/build.md`
  - Document each occurrence with line number and context
- [ ] Replace `if ! function_call` patterns with exit code capture:
  ```bash
  function_call
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    # error handling
  fi
  ```
  - File: /home/benjamin/.config/.claude/commands/build.md
- [ ] Audit path validation blocks for `if [[ ! "$PATH" = /* ]]` patterns in build.md
- [ ] Replace with preprocessing-safe pattern:
  ```bash
  [[ "$PATH" = /* ]]
  IS_ABSOLUTE=$?
  if [ $IS_ABSOLUTE -ne 0 ]; then
    PATH="$(pwd)/$PATH"
  fi
  ```
- [ ] Test updated bash blocks for absence of `!: command not found` errors
  - Test command: `/build [test-plan] --dry-run`
- [ ] Apply same exit code capture pattern to /home/benjamin/.config/.claude/commands/plan.md
- [ ] Apply pattern to /home/benjamin/.config/.claude/commands/debug.md
- [ ] Apply pattern to /home/benjamin/.config/.claude/commands/repair.md
- [ ] Apply pattern to /home/benjamin/.config/.claude/commands/revise.md
- [ ] Add pattern examples to bash-tool-limitations.md section "Bash History Expansion Preprocessing Errors"
  - File: /home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md
  - Section exists at lines 290-458
- [ ] Cross-reference preprocessing safety pattern in Command Development Guide
  - File: /home/benjamin/.config/.claude/docs/guides/development/command-development-guide.md

**Testing**:
```bash
# Test build command with complex plan requiring state transitions
cd /home/benjamin/.config
/build /tmp/test_plan.md 1

# Verify no preprocessing errors
grep -i "!: command not found" <(cat build-output.md) && echo "FAIL: Preprocessing errors remain" || echo "PASS: No preprocessing errors"

# Test across all commands with negated conditionals
for cmd in build plan debug repair revise; do
  echo "Testing /$cmd for preprocessing safety..."
  grep -n "if ! " .claude/commands/${cmd}.md || echo "  ✓ No vulnerable patterns in /$cmd"
done
```

**Expected Duration**: 2 hours

### Phase 1: Standardized Command Library Initialization [NOT STARTED]
dependencies: []

**Objective**: Create centralized library loader eliminating library sourcing inconsistencies

**Complexity**: Medium

**Tasks**:
- [ ] Create /home/benjamin/.config/.claude/lib/core/command-init.sh with library sourcing logic
  - Source error-handling.sh with existence validation
  - Source state-management.sh with existence validation
  - Source workflow-initialization.sh with existence validation
  - Export common environment variables (CLAUDE_ROOT, CLAUDE_LIB, CLAUDE_COMMANDS)
- [ ] Add function existence validation with helpful error messages:
  ```bash
  if ! declare -f save_completed_states_to_state >/dev/null; then
    echo "ERROR: State management functions not loaded. Library: state-management.sh" >&2
    exit 1
  fi
  ```
- [ ] Create validation for each critical function:
  - save_completed_states_to_state (state-management.sh)
  - append_workflow_state (state-management.sh)
  - initialize_workflow_paths (workflow-initialization.sh)
  - log_command_error (error-handling.sh)
  - ensure_error_log_exists (error-handling.sh)
- [ ] Update /home/benjamin/.config/.claude/commands/build.md to source command-init.sh first
  - Add at top of script: `source "$CLAUDE_LIB/core/command-init.sh" 2>/dev/null || { echo "CRITICAL: Cannot load command-init.sh"; exit 1; }`
- [ ] Update /home/benjamin/.config/.claude/commands/plan.md to source command-init.sh
- [ ] Update /home/benjamin/.config/.claude/commands/debug.md to source command-init.sh
- [ ] Update /home/benjamin/.config/.claude/commands/implement.md to source command-init.sh
- [ ] Update /home/benjamin/.config/.claude/commands/repair.md to source command-init.sh
- [ ] Document library initialization requirements in Command Development Guide
  - File: /home/benjamin/.config/.claude/docs/guides/development/command-development-guide.md
  - Section: "Command Initialization Requirements"

**Testing**:
```bash
# Test command initialization across all workflow commands
for cmd in build plan debug implement repair; do
  echo "Testing /$cmd initialization..."
  # Invoke with minimal args to trigger initialization
  /$cmd --help 2>&1 | grep -i "cannot load" && echo "  FAIL: Init failed" || echo "  ✓ Init successful"
done

# Test function availability after initialization
bash -c "source /home/benjamin/.config/.claude/lib/core/command-init.sh && declare -f save_completed_states_to_state >/dev/null && echo 'PASS: Function loaded'"
```

**Expected Duration**: 1.5 hours

### Phase 2: Platform-Aware Resource Sourcing [NOT STARTED]
dependencies: []

**Objective**: Replace hard-coded /etc/bashrc with platform-aware conditional sourcing

**Complexity**: Low

**Tasks**:
- [ ] Locate bashrc sourcing in command initialization (likely in command templates or build.md)
  - Search: `grep -n "/etc/bashrc" /home/benjamin/.config/.claude/commands/*.md`
- [ ] Replace `. /etc/bashrc` with conditional multi-location sourcing:
  ```bash
  # Try multiple standard bashrc locations
  for bashrc_path in /etc/bashrc /etc/bash.bashrc ~/.bashrc; do
    if [ -f "$bashrc_path" ]; then
      . "$bashrc_path" 2>/dev/null || true
      break
    fi
  done
  ```
- [ ] Add platform detection if needed:
  ```bash
  case "$(uname -s)" in
    Linux)   BASHRC_LOCATIONS="/etc/bash.bashrc ~/.bashrc" ;;
    Darwin)  BASHRC_LOCATIONS="/etc/bashrc ~/.bash_profile ~/.bashrc" ;;
    *)       BASHRC_LOCATIONS="~/.bashrc" ;;
  esac
  ```
- [ ] Update command-init.sh to include platform-aware bashrc sourcing
  - File: /home/benjamin/.config/.claude/lib/core/command-init.sh (created in Phase 1)
- [ ] Document platform-specific initialization in deployment guide
  - File: /home/benjamin/.config/.claude/docs/guides/deployment/platform-compatibility.md (create if missing)
  - Section: "Shell Initialization Across Platforms"
- [ ] Test on Linux system (current environment)
- [ ] Add test coverage for macOS bashrc paths (document expected behavior)

**Testing**:
```bash
# Test bashrc sourcing on current Linux system
bash -c "source /home/benjamin/.config/.claude/lib/core/command-init.sh && echo 'Bashrc sourcing completed without errors'"

# Verify no errors for missing /etc/bashrc
grep -i "bashrc: no such file" <(bash -c "source /home/benjamin/.config/.claude/lib/core/command-init.sh 2>&1") && echo "FAIL: Bashrc error" || echo "PASS: No bashrc errors"

# Test platform detection
uname -s | grep -q "Linux" && echo "Platform: Linux detected correctly"
```

**Expected Duration**: 0.5 hours

### Phase 3: Topic Naming Agent Diagnostics and Validation [NOT STARTED]
dependencies: []

**Objective**: Add comprehensive diagnostic logging and output validation to topic naming agent invocation

**Complexity**: Medium

**Tasks**:
- [ ] Locate topic naming agent invocation in /home/benjamin/.config/.claude/commands/plan.md
  - Search for topic-namer.md or create_topic_artifact references
- [ ] Add pre-invocation logging before agent call:
  ```bash
  echo "DEBUG: Topic naming agent input file: $AGENT_INPUT_FILE" >&2
  echo "DEBUG: Expected output file: $AGENT_OUTPUT_FILE" >&2
  test -f "$AGENT_INPUT_FILE" || { echo "ERROR: Agent input file missing"; exit 1; }
  ```
- [ ] Add timeout with explicit error message:
  ```bash
  timeout 30s claude-agent topic-namer.md < "$AGENT_INPUT_FILE" > "$AGENT_OUTPUT_FILE" 2>"$AGENT_STDERR_FILE" || {
    AGENT_EXIT_CODE=$?
    echo "ERROR: Topic naming agent failed (exit $AGENT_EXIT_CODE)" >&2
  }
  ```
- [ ] Add post-invocation validation:
  ```bash
  if [ ! -f "$AGENT_OUTPUT_FILE" ]; then
    echo "ERROR: Topic naming agent did not create output file: $AGENT_OUTPUT_FILE" >&2
    echo "Agent exit code: $AGENT_EXIT_CODE" >&2
    echo "Checking for partial output in agent directory..." >&2
    ls -la "$(dirname "$AGENT_OUTPUT_FILE")" || true
    echo "Agent stderr (last 20 lines):" >&2
    tail -n 20 "$AGENT_STDERR_FILE" || true
  fi
  ```
- [ ] Capture agent stderr/stdout to separate files for debugging:
  - stderr: /tmp/topic-namer-stderr-${TIMESTAMP}.log
  - stdout: captured to $AGENT_OUTPUT_FILE
- [ ] Review topic naming agent behavioral guidelines
  - File: /home/benjamin/.config/.claude/agents/topic-namer.md
  - Verify output contract requirements (expected output format, file location)
- [ ] Enhance fallback logic to log reason and provide alternative topic generation:
  ```bash
  if [ ! -f "$AGENT_OUTPUT_FILE" ]; then
    log_command_error "agent_error" "Topic naming agent failed" "reason=agent_no_output_file"
    TOPIC_NAME="${FALLBACK_TOPIC_PREFIX}_$(date +%s)"
    echo "Fallback topic name: $TOPIC_NAME"
  fi
  ```

**Testing**:
```bash
# Test topic naming agent with valid input
echo "Test feature description" > /tmp/agent_test_input.txt
AGENT_OUTPUT_FILE=/tmp/agent_test_output.txt
# Run agent invocation block from plan.md
test -f "$AGENT_OUTPUT_FILE" && echo "PASS: Agent created output" || echo "FAIL: Agent no output"

# Test agent timeout handling
timeout 1s sleep 10 || echo "Timeout mechanism working"

# Test diagnostic output capture
grep -q "DEBUG: Topic naming agent input file" <(test stderr output) && echo "PASS: Diagnostics logged"
```

**Expected Duration**: 1.5 hours

### Phase 4: Atomic State File Persistence [NOT STARTED]
dependencies: [2]

**Objective**: Implement robust state file operations preventing loss between workflow blocks

**Complexity**: High

**Tasks**:
- [ ] Create atomic state file write function in state-management.sh:
  ```bash
  atomic_write_state_file() {
    local state_file="$1"
    local state_content="$2"
    local temp_file="${state_file}.tmp.$$"

    echo "$state_content" > "$temp_file"
    sync "$temp_file"  # Force write to disk
    mv "$temp_file" "$state_file" || {
      echo "ERROR: Failed to atomically write state file: $state_file" >&2
      rm -f "$temp_file"
      return 1
    }

    # Verify state file exists and has content
    test -s "$state_file"
    VERIFY_EXIT_CODE=$?
    if [ $VERIFY_EXIT_CODE -ne 0 ]; then
      echo "ERROR: State file verification failed: $state_file" >&2
      return 1
    fi
  }
  ```
  - File: /home/benjamin/.config/.claude/lib/core/state-management.sh
- [ ] Add state file validation before reads:
  ```bash
  validate_state_file() {
    local state_file="$1"

    test -f "$state_file"
    FILE_EXISTS=$?
    if [ $FILE_EXISTS -ne 0 ]; then
      echo "ERROR: State file does not exist: $state_file" >&2
      return 1
    fi

    test -s "$state_file"
    FILE_HAS_CONTENT=$?
    if [ $FILE_HAS_CONTENT -ne 0 ]; then
      echo "ERROR: State file is empty: $state_file" >&2
      return 1
    fi

    return 0
  }
  ```
- [ ] Implement state file recovery mechanism:
  ```bash
  recover_state_file() {
    local state_file="$1"
    local backup_dir="$2"

    # Look for recent backup
    find "$backup_dir" -name "$(basename "$state_file").backup.*" -mmin -30 | head -n 1
    LATEST_BACKUP_EXIT_CODE=$?

    if [ $LATEST_BACKUP_EXIT_CODE -eq 0 ]; then
      LATEST_BACKUP=$(find "$backup_dir" -name "$(basename "$state_file").backup.*" -mmin -30 | head -n 1)
      echo "INFO: Recovering state file from backup: $LATEST_BACKUP" >&2
      cp "$LATEST_BACKUP" "$state_file"
      return $?
    fi

    return 1
  }
  ```
- [ ] Update build.md to use atomic state file operations
  - File: /home/benjamin/.config/.claude/commands/build.md
  - Replace direct state file writes with atomic_write_state_file calls
- [ ] Add state file backup before modifications:
  ```bash
  BACKUP_FILE="${STATE_FILE}.backup.$(date +%s)"
  test -f "$STATE_FILE" && cp "$STATE_FILE" "$BACKUP_FILE"
  ```
- [ ] Update state file location to persistent directory (not /tmp)
  - Use: /home/benjamin/.config/.claude/data/state/build_state_${WORKFLOW_ID}.txt
  - Ensure data/state directory exists in command-init.sh
- [ ] Test state file persistence across multi-block workflows
- [ ] Add state file cleanup mechanism (remove files older than 7 days)

**Testing**:
```bash
# Test atomic state file write
source /home/benjamin/.config/.claude/lib/core/state-management.sh
atomic_write_state_file "/tmp/test_state.txt" "test_workflow_id_123" && echo "PASS: Atomic write" || echo "FAIL: Atomic write"

# Test state file validation
validate_state_file "/tmp/test_state.txt" && echo "PASS: Validation" || echo "FAIL: Validation"

# Test recovery mechanism
rm /tmp/test_state.txt
recover_state_file "/tmp/test_state.txt" "/tmp" && echo "PASS: Recovery" || echo "INFO: No backup available"

# Test build workflow state persistence
/build [test-plan] 1
grep -q "ERROR: State file" <(cat build-output.md) && echo "FAIL: State file errors" || echo "PASS: State persistence working"
```

**Expected Duration**: 2 hours

### Phase 5: Test Script Execution Validation and Enforcement [NOT STARTED]
dependencies: []

**Objective**: Ensure test scripts have proper permissions, shebangs, and TEST_MODE integration

**Complexity**: Low

**Tasks**:
- [ ] Audit all test scripts for execute permissions:
  ```bash
  find /home/benjamin/.config/.claude/tests -name "*.sh" -type f ! -executable
  ```
- [ ] Add execute permissions to all test scripts:
  ```bash
  chmod +x /home/benjamin/.config/.claude/tests/*.sh
  ```
- [ ] Verify shebang line exists in all test scripts:
  ```bash
  for script in /home/benjamin/.config/.claude/tests/*.sh; do
    head -n 1 "$script" | grep -q "^#!/" || echo "Missing shebang: $script"
  done
  ```
- [ ] Add shebang to scripts missing it:
  ```bash
  #!/usr/bin/env bash
  ```
- [ ] Add TEST_MODE export to all test scripts (at top after shebang):
  ```bash
  export TEST_MODE=true
  ```
- [ ] Update test runner to validate permissions before execution:
  - File: /home/benjamin/.config/.claude/tests/run_all_tests.sh
  - Add pre-test validation:
  ```bash
  validate_test_script() {
    local script="$1"

    # Check shebang
    head -n 1 "$script" | grep -q "^#!/"
    SHEBANG_CHECK=$?
    if [ $SHEBANG_CHECK -ne 0 ]; then
      echo "ERROR: Missing shebang in test script: $script" >&2
      return 1
    fi

    # Check execute permission
    test -x "$script"
    EXEC_CHECK=$?
    if [ $EXEC_CHECK -ne 0 ]; then
      echo "ERROR: Test script not executable: $script" >&2
      echo "  Fix: chmod +x $script" >&2
      return 1
    fi

    return 0
  }
  ```
- [ ] Document test script requirements in Testing Protocols:
  - File: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md
  - Create section: "Test Script Requirements"
  - Content: Shebang requirement, execute permissions, TEST_MODE export

**Testing**:
```bash
# Verify all test scripts have shebangs
for script in /home/benjamin/.config/.claude/tests/*.sh; do
  head -n 1 "$script" | grep -q "^#!/" && echo "✓ $script" || echo "✗ $script (missing shebang)"
done

# Verify all test scripts are executable
find /home/benjamin/.config/.claude/tests -name "*.sh" -type f ! -executable | wc -l | grep -q "^0$" && echo "PASS: All scripts executable" || echo "FAIL: Some scripts not executable"

# Test script validation in test runner
bash /home/benjamin/.config/.claude/tests/run_all_tests.sh 2>&1 | grep -i "missing shebang\|not executable" && echo "FAIL: Validation errors" || echo "PASS: All tests valid"
```

**Expected Duration**: 1 hour

### Phase 6: Error Trap Quote Escaping Fix [NOT STARTED]
dependencies: []

**Objective**: Fix complex quote escaping in bash trap commands eliminating parse errors

**Complexity**: Medium

**Tasks**:
- [ ] Locate trap installation in error-handling library
  - File: /home/benjamin/.config/.claude/lib/core/error-handling.sh
  - Search for trap command with _log_bash_exit
- [ ] Review current trap command causing parse errors:
  ```bash
  trap '_log_bash_exit $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' EXIT
  ```
- [ ] Simplify variable passing using global variables instead of embedded string interpolation:
  ```bash
  # Set globals before trap installation
  export ERROR_CONTEXT_CMD_NAME="$cmd_name"
  export ERROR_CONTEXT_WORKFLOW_ID="$workflow_id"
  export ERROR_CONTEXT_USER_ARGS="$user_args"

  # Simplified trap without complex escaping
  trap '_log_bash_exit $LINENO "$BASH_COMMAND"' EXIT
  ```
- [ ] Update _log_bash_exit function to read from global variables:
  ```bash
  _log_bash_exit() {
    local line_number="$1"
    local command="$2"
    local cmd_name="${ERROR_CONTEXT_CMD_NAME:-unknown}"
    local workflow_id="${ERROR_CONTEXT_WORKFLOW_ID:-unknown}"
    local user_args="${ERROR_CONTEXT_USER_ARGS:-}"

    # Existing error logging logic
  }
  ```
  - File: /home/benjamin/.config/.claude/lib/core/error-handling.sh
- [ ] Add trap syntax validation before installation:
  ```bash
  validate_trap_syntax() {
    local trap_command="$1"

    # Test trap syntax by installing in subshell
    (trap "$trap_command" EXIT 2>/dev/null)
    SYNTAX_CHECK=$?
    if [ $SYNTAX_CHECK -ne 0 ]; then
      echo "ERROR: Invalid trap syntax: $trap_command" >&2
      return 1
    fi

    return 0
  }
  ```
- [ ] Add unit tests for trap installation with various argument types:
  - Test with spaces in arguments
  - Test with quotes in arguments
  - Test with special characters (!, $, ", ')
  - File: /home/benjamin/.config/.claude/tests/test_error_trap_escaping.sh

**Testing**:
```bash
# Test trap installation with complex arguments
cmd_name="/test-cmd"
workflow_id="test_workflow_123"
user_args="--arg 'value with spaces' --flag"

source /home/benjamin/.config/.claude/lib/core/error-handling.sh
# Verify no parse errors during trap installation
echo $? | grep -q "^0$" && echo "PASS: Trap installed without errors" || echo "FAIL: Trap installation error"

# Test trap execution with various argument types
bash -c "source /home/benjamin/.config/.claude/lib/core/error-handling.sh && exit 1" 2>&1 | grep -q "parse error\|syntax error" && echo "FAIL: Parse error" || echo "PASS: No parse errors"

# Run unit tests
bash /home/benjamin/.config/.claude/tests/test_error_trap_escaping.sh
```

**Expected Duration**: 1.5 hours

### Phase 7: Test Mode Detection and Error Log Filtering [NOT STARTED]
dependencies: [1, 5]

**Objective**: Add is_test metadata field and --exclude-tests filtering to error logging

**Complexity**: Low

**Tasks**:
- [ ] Add is_test field detection in error-handling library:
  ```bash
  detect_test_mode() {
    # Check TEST_MODE environment variable
    if [ "${TEST_MODE:-false}" = "true" ]; then
      echo "true"
      return 0
    fi

    # Check if invoked from test directory
    pwd | grep -q "/tests/"
    FROM_TESTS_DIR=$?
    if [ $FROM_TESTS_DIR -eq 0 ]; then
      echo "true"
      return 0
    fi

    echo "false"
    return 0
  }
  ```
  - File: /home/benjamin/.config/.claude/lib/core/error-handling.sh
- [ ] Update log_command_error to include is_test field:
  ```bash
  log_command_error() {
    local error_type="$1"
    local error_message="$2"
    local error_details="$3"

    local is_test=$(detect_test_mode)

    # Build JSON log entry with is_test field
    local log_entry=$(jq -n \
      --arg timestamp "$(date -Iseconds)" \
      --arg command "${ERROR_CONTEXT_CMD_NAME:-unknown}" \
      --arg error_type "$error_type" \
      --arg error_message "$error_message" \
      --arg is_test "$is_test" \
      --argjson context "$error_details" \
      '{timestamp: $timestamp, command: $command, error_type: $error_type, error_message: $error_message, is_test: ($is_test == "true"), context: $context}')

    echo "$log_entry" >> "$ERROR_LOG_FILE"
  }
  ```
- [ ] Add --exclude-tests flag to /errors command:
  - File: /home/benjamin/.config/.claude/commands/errors.md
  - Add flag parsing:
  ```bash
  EXCLUDE_TESTS=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --exclude-tests)
        EXCLUDE_TESTS=true
        shift
        ;;
      *)
        # Other flag handling
        ;;
    esac
  done
  ```
- [ ] Implement filtering logic in errors command:
  ```bash
  if [ "$EXCLUDE_TESTS" = "true" ]; then
    jq -c 'select(.is_test == false)' "$ERROR_LOG_FILE"
  else
    cat "$ERROR_LOG_FILE"
  fi
  ```
- [ ] Verify Testing Protocols documentation includes TEST_MODE requirement
  - File: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md
  - Section exists at lines 195-198 (verify and enhance if needed)
- [ ] Add code examples to Testing Protocols showing TEST_MODE integration:
  ```bash
  # Example test script structure
  #!/usr/bin/env bash
  export TEST_MODE=true  # Required for test mode detection

  # Test implementation
  ```
- [ ] Document is_test field usage in Error Handling Pattern examples:
  - File: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
  - Add section showing is_test field in error log entries

**Testing**:
```bash
# Test is_test detection with TEST_MODE set
TEST_MODE=true bash -c "source /home/benjamin/.config/.claude/lib/core/error-handling.sh && detect_test_mode" | grep -q "true" && echo "PASS: TEST_MODE detected" || echo "FAIL"

# Test is_test detection from test directory
cd /home/benjamin/.config/.claude/tests
bash -c "source /home/benjamin/.config/.claude/lib/core/error-handling.sh && detect_test_mode" | grep -q "true" && echo "PASS: Test dir detected" || echo "FAIL"

# Test error log filtering
/errors --exclude-tests --limit 10 | jq -r '.is_test' | grep -q "true" && echo "FAIL: Test errors not filtered" || echo "PASS: Filtering working"

# Verify error log entries have is_test field
/errors --limit 5 | jq -r 'has("is_test")' | grep -q "false" && echo "FAIL: Missing is_test field" || echo "PASS: is_test field present"
```

**Expected Duration**: 1 hour

### Phase 8: State Transition Diagnostics and Build Test Context [NOT STARTED]
dependencies: [4, 7]

**Objective**: Enhance state transition diagnostics with precondition validation and improve build test phase error context capture

**Complexity**: Medium

**Tasks**:
- [ ] Add precondition validation to state transition functions:
  ```bash
  validate_state_transition() {
    local from_state="$1"
    local to_state="$2"
    local workflow_id="$3"

    # Validate workflow_id exists
    test -n "$workflow_id"
    ID_CHECK=$?
    if [ $ID_CHECK -ne 0 ]; then
      echo "ERROR: Workflow ID is empty" >&2
      log_command_error "state_error" "State transition validation failed" '{"reason": "empty_workflow_id"}'
      return 1
    fi

    # Validate state file exists
    local state_file="/home/benjamin/.config/.claude/data/state/workflow_${workflow_id}.txt"
    validate_state_file "$state_file"
    STATE_FILE_CHECK=$?
    if [ $STATE_FILE_CHECK -ne 0 ]; then
      echo "ERROR: State file validation failed for workflow $workflow_id" >&2
      log_command_error "state_error" "State file missing or invalid" "{\"workflow_id\": \"$workflow_id\", \"state_file\": \"$state_file\"}"
      return 1
    fi

    # Validate state transition is allowed
    case "$from_state:$to_state" in
      "INIT:RESEARCH"|"RESEARCH:PLANNING"|"PLANNING:IMPLEMENTATION"|"IMPLEMENTATION:TESTING"|"TESTING:COMPLETE")
        echo "INFO: Valid state transition: $from_state → $to_state" >&2
        return 0
        ;;
      *)
        echo "ERROR: Invalid state transition: $from_state → $to_state" >&2
        log_command_error "state_error" "Invalid state transition" "{\"from\": \"$from_state\", \"to\": \"$to_state\", \"workflow_id\": \"$workflow_id\"}"
        return 1
        ;;
    esac
  }
  ```
  - File: /home/benjamin/.config/.claude/lib/core/state-management.sh
- [ ] Update sm_transition function to call validation before transition:
  ```bash
  sm_transition() {
    local new_state="$1"
    local workflow_id="${2:-$WORKFLOW_ID}"

    # Get current state
    local current_state=$(get_current_state "$workflow_id")

    # Validate transition
    validate_state_transition "$current_state" "$new_state" "$workflow_id"
    VALIDATION_CHECK=$?
    if [ $VALIDATION_CHECK -ne 0 ]; then
      return 1
    fi

    # Perform transition (existing logic)
  }
  ```
- [ ] Add build test phase error context capture in build.md:
  ```bash
  # Before test execution
  TEST_PHASE_START=$(date +%s)
  TEST_PHASE_PLAN_FILE="$PLAN_FILE"
  TEST_PHASE_PHASE_NUMBER="$PHASE_NUMBER"

  # During test execution
  run_phase_tests() {
    local phase_number="$1"
    local test_commands="$2"

    echo "INFO: Running tests for Phase $phase_number" >&2

    eval "$test_commands"
    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -ne 0 ]; then
      TEST_DURATION=$(($(date +%s) - TEST_PHASE_START))
      log_command_error "test_failure" "Phase $phase_number tests failed" \
        "{\"phase\": $phase_number, \"plan_file\": \"$TEST_PHASE_PLAN_FILE\", \"duration_seconds\": $TEST_DURATION, \"exit_code\": $TEST_EXIT_CODE}"
    fi

    return $TEST_EXIT_CODE
  }
  ```
  - File: /home/benjamin/.config/.claude/commands/build.md
- [ ] Add state transition diagnostic output with actionable messages:
  ```bash
  # Example diagnostic message
  echo "State Transition Diagnostics:" >&2
  echo "  Workflow ID: $workflow_id" >&2
  echo "  Current State: $current_state" >&2
  echo "  Target State: $new_state" >&2
  echo "  State File: $state_file" >&2
  echo "  Prerequisites Met: $(validate_prerequisites)" >&2
  ```
- [ ] Update state transition error messages to include resolution steps:
  ```bash
  echo "ERROR: State transition failed: $current_state → $new_state" >&2
  echo "Resolution steps:" >&2
  echo "  1. Verify workflow ID is correct: $workflow_id" >&2
  echo "  2. Check state file exists: $state_file" >&2
  echo "  3. Ensure prerequisites for $new_state are met" >&2
  echo "  4. Check error log: /errors --command /build --since 1h" >&2
  ```
- [ ] Add test phase context to error logs (test framework used, test count, failure patterns)
- [ ] Document state transition validation in State-Based Orchestration docs:
  - File: /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
  - Section: "State Transition Validation and Error Handling"

**Testing**:
```bash
# Test state transition validation with invalid transition
source /home/benjamin/.config/.claude/lib/core/state-management.sh
validate_state_transition "COMPLETE" "INIT" "test_wf_123" 2>&1 | grep -q "Invalid state transition" && echo "PASS: Invalid transition detected" || echo "FAIL"

# Test with missing workflow ID
validate_state_transition "INIT" "RESEARCH" "" 2>&1 | grep -q "empty_workflow_id" && echo "PASS: Empty ID detected" || echo "FAIL"

# Test build phase error context
/build [test-plan] 1 2>&1 | grep -q "Running tests for Phase" && echo "PASS: Test phase context captured" || echo "FAIL"

# Verify error log has test phase context
/errors --type test_failure --limit 5 | jq -r '.context | has("phase", "plan_file", "duration_seconds")' | grep -q "false" && echo "FAIL: Missing context" || echo "PASS: Context complete"
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Library function tests: state-management.sh, error-handling.sh, workflow-initialization.sh functions
- Target coverage: 85% for critical path functions (atomic state writes, state validation, error logging)
- Test isolation: Each test script exports TEST_MODE=true to populate is_test field
- Test framework: Bash unit testing with assertion functions

### Integration Testing
- Multi-block workflow tests: Verify state file persistence across build phases
- Cross-platform tests: bashrc sourcing on Linux and macOS environments
- Agent integration tests: Topic naming agent with various input types
- End-to-end: /build workflow from plan parsing to completion

### Regression Testing
- Historical error patterns: Verify all 10 errors from 001_error_analysis.md are fixed
- Build output verification: Re-run build-output.md scenario and verify 0 errors
- Preprocessing safety: Test commands with history expansion characters (!, $, etc.)
- State transition coverage: Test all valid and invalid state transitions

### Performance Testing
- State file operations: Measure atomic write/read latency (target <50ms)
- Error logging overhead: Verify <5ms overhead per log_command_error call
- Command initialization: Target <100ms for command-init.sh sourcing

### Test Commands
```bash
# Run all unit tests
bash /home/benjamin/.config/.claude/tests/run_all_tests.sh

# Run specific test suites
bash /home/benjamin/.config/.claude/tests/test_state_management.sh
bash /home/benjamin/.config/.claude/tests/test_error_handling.sh
bash /home/benjamin/.config/.claude/tests/test_bash_preprocessing_safety.sh

# Integration test: full build workflow
/build /home/benjamin/.config/.claude/specs/871_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md 1

# Verify error filtering
/errors --exclude-tests --since 1h --summary

# Test cross-platform bashrc sourcing
bash -c "source /home/benjamin/.config/.claude/lib/core/command-init.sh && echo 'Platform init successful'"
```

## Documentation Requirements

### Standards Documentation Updates
- **Output Formatting Standards** (WHAT/WHY clarification):
  - File: /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md
  - Clarify: Code comments describe WHAT, documentation explains WHY
  - Section already exists at lines 227-271 (verify compliance)

- **Testing Protocols** (TEST_MODE requirement and test script standards):
  - File: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md
  - Verify TEST_MODE requirement exists at lines 195-198
  - Add "Test Script Requirements" section (shebangs, permissions, TEST_MODE export)
  - Add code examples showing TEST_MODE integration in test setup

- **Bash Tool Limitations** (preprocessing safety patterns):
  - File: /home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md
  - Enhance section "Bash History Expansion Preprocessing Errors" (lines 290-458)
  - Add exit code capture pattern examples from Phase 0
  - Cross-reference from Command Development Guide

### Guide Documentation Updates
- **Command Development Guide** (initialization requirements):
  - File: /home/benjamin/.config/.claude/docs/guides/development/command-development-guide.md
  - Add "Command Initialization Requirements" section
  - Document command-init.sh sourcing pattern
  - Reference library sourcing validation

- **Error Handling Pattern** (is_test field and filtering):
  - File: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
  - Add examples showing is_test field in error log entries
  - Document --exclude-tests flag usage
  - Show test mode detection patterns

- **State-Based Orchestration Overview** (state validation):
  - File: /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
  - Add "State Transition Validation and Error Handling" section
  - Document precondition validation requirements
  - Include state transition diagnostic output examples

### New Documentation
- **Platform Compatibility Guide** (if not exists):
  - File: /home/benjamin/.config/.claude/docs/guides/deployment/platform-compatibility.md
  - Section: "Shell Initialization Across Platforms"
  - Document bashrc sourcing patterns for Linux/macOS/other platforms
  - Include platform detection examples

### Documentation Standards
- Follow CLAUDE.md documentation policy (no emojis, clear examples, CommonMark)
- **Documentation files** (.claude/docs/) SHOULD include design rationale (WHY this pattern exists)
- **Implementation code comments** MUST describe WHAT code does only (not WHY - see Output Formatting Standards)
- Include code examples for exit code capture pattern (preprocessing safety)
- Document state file persistence lifecycle and recovery mechanisms
- Include code examples for test mode usage and error log filtering
- Add state transition diagrams using Unicode box-drawing (show prerequisites)
- Cross-reference Error Handling Pattern for error context requirements
- Document test script requirements: execute permissions, shebangs, TEST_MODE integration

## Dependencies

### External Dependencies
- jq: Required for JSON error log parsing and construction (already available)
- bash 4.0+: Required for associative arrays in state management
- sync/fsync: Required for atomic state file writes
- find: Required for state file backup discovery

### Internal Dependencies
- Error handling library: /home/benjamin/.config/.claude/lib/core/error-handling.sh
- State management library: /home/benjamin/.config/.claude/lib/core/state-management.sh
- Workflow initialization library: /home/benjamin/.config/.claude/lib/core/workflow-initialization.sh
- Topic naming agent: /home/benjamin/.config/.claude/agents/topic-namer.md

### Phase Dependencies
- Phase 4 depends on Phase 2: Platform-aware sourcing needed before state file location determination
- Phase 7 depends on Phase 1: Test mode detection requires error-handling library initialization
- Phase 7 depends on Phase 5: TEST_MODE integration needs test script validation
- Phase 8 depends on Phase 4: State transition validation requires atomic state operations
- Phase 8 depends on Phase 7: Build test context capture uses error logging with is_test field

**Parallel Execution Waves** (40-60% time savings):
- **Wave 1** (parallel): Phases 0, 1, 2, 6 (independent preprocessing, library, platform, trap fixes)
- **Wave 2** (parallel): Phases 3, 5 (independent agent diagnostics and test validation)
- **Wave 3** (sequential): Phase 4 (depends on Phase 2 for platform-aware paths)
- **Wave 4** (sequential): Phase 7 (depends on Phases 1, 5 for library and TEST_MODE)
- **Wave 5** (sequential): Phase 8 (depends on Phases 4, 7 for state and logging)

## Risk Management

### Technical Risks
1. **Exit Code Capture Adoption**: Risk that existing commands have many `if ! ` patterns requiring replacement
   - Mitigation: Audit all commands first (grep survey), prioritize critical commands (build, plan)
   - Rollback: Pattern can be applied incrementally per command

2. **State File Migration**: Risk that existing workflows have incompatible state file formats
   - Mitigation: Implement backward-compatible state file reader with version detection
   - Recovery: State file recovery mechanism handles missing/corrupt files

3. **Test Mode False Positives**: Risk that TEST_MODE detection incorrectly flags production runs as tests
   - Mitigation: Require explicit TEST_MODE=true export (no automatic detection from paths)
   - Validation: Test filtering with known production error logs

4. **Platform Detection Edge Cases**: Risk that platform detection misidentifies OS type
   - Mitigation: Test on known Linux and macOS systems, use conservative fallback
   - Monitoring: Log platform detection results for troubleshooting

### Process Risks
1. **Documentation Lag**: Risk that documentation updates lag behind implementation
   - Mitigation: Update docs in same phase as implementation (not deferred)
   - Validation: Documentation requirements in phase completion criteria

2. **Breaking Changes**: Risk that library changes break dependent commands
   - Mitigation: Implement backward-compatible wrappers for modified functions
   - Testing: Regression tests cover all workflow commands

3. **Testing Overhead**: Risk that test mode detection adds latency to production runs
   - Mitigation: Benchmark TEST_MODE detection (target <1ms overhead)
   - Optimization: Cache detection result in global variable per command invocation
