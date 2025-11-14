# LLM Classification Failure Analysis

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: LLM Classification Failure in /coordinate Command
- **Report Type**: codebase analysis
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)

## Executive Summary

The LLM classification failure in /coordinate occurs when the file-based signaling system times out waiting for the Claude Code CLI to process classification requests. Analysis reveals this is an architectural dependency (not a bug) requiring an active AI assistant monitoring stderr. The system correctly returns exit code 1 on failure, but stderr redirection in sm_init() suppresses actionable error messages that guide users to use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development. Three high-priority fixes are recommended: (1) surface suppressed error messages to users, (2) invoke the unused handle_llm_classification_failure() function, and (3) document the regex-only mode more prominently in command headers and error outputs.

## Findings

### 1. Root Cause: File-Based Signaling Dependency

**Location**: `.claude/lib/workflow-llm-classifier.sh:248-303`

The LLM classification system uses a file-based request/response pattern that depends entirely on an external AI assistant monitoring stderr:

1. **Request Creation** (lines 250-268):
   - Writes JSON request to `/tmp/llm_classification_request_$$.json`
   - Emits signal: `[LLM_CLASSIFICATION_REQUEST] Please process request at: $request_file → $response_file`
   - This signal MUST be caught by Claude Code CLI or classification will ALWAYS fail

2. **Polling Loop** (lines 274-297):
   - Polls for response file every 0.5 seconds
   - Maximum iterations: `WORKFLOW_CLASSIFICATION_TIMEOUT * 2` (default: 20 iterations = 10 seconds)
   - Returns success only if response file appears AND contains valid JSON

3. **Timeout Failure** (lines 299-302):
   - After timeout, logs error: `log_classification_error "invoke_llm_classifier" "timeout after ${WORKFLOW_CLASSIFICATION_TIMEOUT}s"`
   - Returns exit code 1
   - Cleans up temp files

**Critical Finding**: If Claude Code CLI is not actively monitoring stderr (offline development, CI/CD pipeline, different terminal), the classification WILL timeout after 10 seconds. This is NOT a bug - it's architectural design that requires active AI assistant participation.

### 2. Error Visibility Problem - Stderr Redirection

**Location**: `.claude/lib/workflow-state-machine.sh:353`

The `sm_init()` function redirects stderr during classification, hiding actionable error messages:

```bash
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>&1); then
```

**Changed in Spec 700 Phase 5**: This was previously `2>/dev/null` (completely suppressing stderr), now uses `2>&1` (preserving stderr in captured output). However, the captured output is only displayed on success, not failure.

**Suppressed Error Messages**:

1. Network connectivity warning (workflow-llm-classifier.sh:233-235):
   ```
   WARNING: No network connectivity detected
     Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work
   ```

2. Timeout error (workflow-llm-classifier.sh:300):
   ```
   [ERROR] LLM Classifier: invoke_llm_classifier: timeout after 10s
   ```

3. Classification failure with suggestions (workflow-scope-detection.sh:66-69):
   ```
   ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode
     Context: Workflow description: [description]
     Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT,
                 or use regex-only mode for offline development
   ```

**Result**: Users see generic "State machine initialization failed" error (coordinate.md:170) without the specific guidance on using `WORKFLOW_CLASSIFICATION_MODE=regex-only`.

### 3. Network Connectivity Check - Incomplete Implementation

**Location**: `.claude/lib/workflow-llm-classifier.sh:223-240`

The `check_network_connectivity()` function was added in Spec 700 Phase 5 to provide fast-fail for offline scenarios:

```bash
check_network_connectivity() {
  if [ "${WORKFLOW_CLASSIFICATION_MODE:-}" = "regex-only" ]; then
    return 0  # Skip check, user explicitly chose offline mode
  fi

  if command -v ping >/dev/null 2>&1; then
    if ! timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      echo "WARNING: No network connectivity detected" >&2
      echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work" >&2
      return 1
    fi
  fi
  return 0
}
```

**Issues Identified**:

1. **Ping-only detection** (line 232): Only checks if Google DNS is reachable, doesn't verify Claude API connectivity
2. **Fallback behavior** (line 237): If `ping` command unavailable, returns 0 (assumes online), missing offline scenarios
3. **Warning suppressed**: The helpful warning message is hidden by `2>&1` redirection in sm_init() (line 353)
4. **Single test point**: Checking 8.8.8.8 doesn't verify actual API endpoint availability (could be firewall-blocked)

### 4. Timeout Configuration - Hardcoded Default

**Location**: `.claude/lib/workflow-llm-classifier.sh:24`

```bash
WORKFLOW_CLASSIFICATION_TIMEOUT="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
```

**Analysis**:
- Default 10-second timeout is reasonable for successful classifications (typically <2s)
- For actual failures (network down, API unavailable), users wait full 10 seconds before seeing error
- No adaptive timeout based on failure detection (e.g., could fail faster if network check fails)
- Environment variable override available but not well-documented in error messages

### 5. Failure Mode Detection - Exit Codes vs Error Messages

**Location**: `.claude/commands/coordinate.md:167-171`

```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed (workflow classification error).
                      Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only
                      for offline development." 1
fi
```

**Good Practice Identified**: The coordinate command correctly:
1. Captures sm_init exit code separately
2. Preserves stderr output with `2>&1`
3. Provides actionable guidance in error handler

**Contrast with workflow-state-machine.sh:353**: The library-level call suppresses the detailed error chain, so only the generic message from coordinate.md is shown.

### 6. Leftover Temp Files Indicate Failure Frequency

**Evidence**: `/tmp/llm_classification_request_*.json`

Analysis of 6 leftover request files shows:
- **Pattern**: Request files remain but NO corresponding response files
- **Implication**: These represent 6 failed classification attempts (10-second timeouts each)
- **Most recent**: `/tmp/llm_classification_request_1173983.json` (Nov 13 12:40)
- **Content analysis**: All are valid JSON with proper structure, confirming the request creation works correctly

**Cleanup Gap**: The `cleanup_temp_files()` function (lines 260-262) is registered via trap, but may not execute if classification timeout happens during script termination or interruption.

### 7. Error Handling Function Integration

**Location**: `.claude/lib/workflow-llm-classifier.sh:489-535`

The `handle_llm_classification_failure()` function provides structured error handling with actionable suggestions:

```bash
case "$error_type" in
  timeout|"$ERROR_TYPE_LLM_TIMEOUT")
    echo "  Suggestion: Increase WORKFLOW_CLASSIFICATION_TIMEOUT (current: ${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}s)" >&2
    echo "  Alternative: Use regex-only mode for offline development (export WORKFLOW_CLASSIFICATION_MODE=regex-only)" >&2
    ;;
```

**Critical Gap**: This function is DEFINED but NEVER CALLED in the codebase. The structured error handling with context-specific suggestions exists but is unreachable.

**Evidence**: Search for `handle_llm_classification_failure` calls returns zero results outside the function definition.

## Recommendations

### 1. Surface Error Messages to Users (High Priority)

**Problem**: Actionable error messages are suppressed by stderr redirection in sm_init()

**Solution**: Modify `.claude/lib/workflow-state-machine.sh:353` to capture and display stderr on failure:

```bash
local classification_result
local classification_stderr
classification_stderr=$(mktemp)
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>"$classification_stderr"); then
  # Success path - parse result
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
  # ... existing code ...
else
  # Failure path - display captured stderr for diagnostics
  echo "Classification failed with the following errors:" >&2
  cat "$classification_stderr" >&2
  rm -f "$classification_stderr"
  return 1
fi
rm -f "$classification_stderr"
```

**Impact**: Users will see specific suggestions (use regex-only mode, check network, increase timeout) instead of generic error.

### 2. Integrate handle_llm_classification_failure Function (High Priority)

**Problem**: Structured error handler defined but never invoked

**Solution**: Call `handle_llm_classification_failure()` in classification failure paths:

In `.claude/lib/workflow-llm-classifier.sh:53-56`, replace:
```bash
if ! llm_output=$(invoke_llm_classifier "$llm_input"); then
  log_classification_error "classify_workflow_llm" "LLM invocation failed or timed out"
  return 1
fi
```

With:
```bash
if ! llm_output=$(invoke_llm_classifier "$llm_input"); then
  handle_llm_classification_failure "timeout" "LLM invocation failed or timed out" "$workflow_description"
  return 1
fi
```

**Impact**: Users get error type classification and context-specific recovery suggestions.

### 3. Improve Network Connectivity Check (Medium Priority)

**Problem**: Current check only uses ping to 8.8.8.8, doesn't verify Claude API availability

**Solution**: Enhance `.claude/lib/workflow-llm-classifier.sh:223-240` with multi-level detection:

```bash
check_network_connectivity() {
  if [ "${WORKFLOW_CLASSIFICATION_MODE:-}" = "regex-only" ]; then
    return 0  # Skip check
  fi

  # Level 1: Basic network connectivity
  if command -v ping >/dev/null 2>&1; then
    if ! timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      echo "WARNING: No network connectivity detected (ping failed)" >&2
      echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work" >&2
      return 1
    fi
  fi

  # Level 2: Check if Claude Code process is running (indicates AI assistant available)
  if ! pgrep -f "claude" >/dev/null 2>&1; then
    echo "WARNING: Claude Code CLI not detected in process list" >&2
    echo "  LLM classification requires active Claude Code assistant" >&2
    echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only" >&2
    return 1
  fi

  return 0
}
```

**Impact**: Faster failure detection for offline scenarios, more specific diagnostic messages.

### 4. Implement Adaptive Timeout (Medium Priority)

**Problem**: 10-second timeout applies regardless of whether fast-fail is possible

**Solution**: Reduce timeout when network check fails:

```bash
invoke_llm_classifier() {
  local llm_input="$1"

  # Pre-flight check with adaptive timeout
  if ! check_network_connectivity; then
    echo "ERROR: LLM classification requires network connectivity" >&2
    # Fast-fail: don't wait 10 seconds when we know it will fail
    return 1
  fi

  # Proceed with normal timeout for legitimate API calls
  local timeout_seconds="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
  # ... rest of function ...
}
```

**Impact**: Users get immediate feedback in offline scenarios instead of waiting 10 seconds.

### 5. Add Temp File Cleanup Hook (Low Priority)

**Problem**: Failed classification attempts leave orphaned request files in /tmp

**Solution**: Add cleanup on script exit in coordinate.md initialization:

```bash
# Register cleanup for classification temp files
cleanup_classification_files() {
  rm -f /tmp/llm_classification_request_*.json /tmp/llm_classification_response_*.json
}
trap cleanup_classification_files EXIT
```

**Impact**: Reduced /tmp clutter, easier to identify NEW vs OLD failures.

### 6. Document WORKFLOW_CLASSIFICATION_MODE More Prominently (High Priority)

**Problem**: Users encounter LLM classification failures without knowing about regex-only fallback

**Solution**: Add environment variable documentation to CLAUDE.md and error messages:

In `.claude/commands/coordinate.md` header comment:
```markdown
## Environment Variables
- `WORKFLOW_CLASSIFICATION_MODE`: Classification mode (default: llm-only)
  - `llm-only`: Use Claude AI for semantic classification (requires network)
  - `regex-only`: Use regex patterns for offline development
- `WORKFLOW_CLASSIFICATION_TIMEOUT`: Timeout in seconds (default: 10)
```

**Impact**: Users can proactively set regex-only mode for offline development.

## References

### Primary Source Files
- `.claude/lib/workflow-llm-classifier.sh` (595 lines) - Core LLM classification implementation
  - Lines 248-303: `invoke_llm_classifier()` - File-based signaling and polling
  - Lines 223-240: `check_network_connectivity()` - Network pre-flight check
  - Lines 489-535: `handle_llm_classification_failure()` - Structured error handler (unused)
  - Line 24: `WORKFLOW_CLASSIFICATION_TIMEOUT` configuration

- `.claude/lib/workflow-state-machine.sh` (834 lines) - State machine orchestration
  - Lines 334-433: `sm_init()` - State machine initialization with classification
  - Line 353: Stderr redirection that suppresses error messages

- `.claude/lib/workflow-scope-detection.sh` (200 lines) - Unified classification routing
  - Lines 49-99: `classify_workflow_comprehensive()` - Mode routing (llm-only vs regex-only)
  - Lines 61-75: LLM-only mode with fail-fast error handling

- `.claude/commands/coordinate.md` (800 lines) - Multi-agent orchestration command
  - Lines 167-171: `sm_init()` invocation with error handling
  - Line 170: Generic error message shown to users

- `.claude/lib/error-handling.sh` (100 lines) - Error classification utilities
  - Lines 23-27: LLM-specific error type constants

### Supporting Evidence Files
- `.claude/specs/700_itself_conduct_careful_research_to_create_a_plan/reports/004_llm_classification_reliability_analysis.md` - Prior analysis of classification failures (Spec 700 Phase 5)
- `.claude/specs/681_workflow_not_correctly_classify_workflow_since/reports/001_llm_classification_diagnostics.md` - Historical classification debugging (Spec 681)
- `/tmp/llm_classification_request_*.json` - 6 leftover request files indicating failed classification attempts
