# LLM Classification Reliability Analysis

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: LLM-based workflow classification failures and fallback mechanisms
- **Report Type**: codebase analysis
- **Complexity Level**: 4

## Executive Summary

The LLM-based workflow classification system exhibits two critical failure modes: (1) file-based signaling timeouts when no AI assistant responds, and (2) stderr suppression in sm_init() masks error messages while still propagating correct exit codes. The "silent failure" observed in coordinage_plan.md is not actually silent - sm_init() correctly returns exit code 1, but error messages are hidden by `2>/dev/null` redirection. The real issue is that users must manually diagnose and switch to regex-only mode because error context is suppressed. The system has proper fail-fast error handling but poor error visibility, making offline development difficult without prior knowledge of WORKFLOW_CLASSIFICATION_MODE=regex-only.

## Findings

### 1. Root Cause Analysis - LLM Classification Architecture

**File-Based Signaling Pattern** (.claude/lib/workflow-llm-classifier.sh:218-273):

The `invoke_llm_classifier()` function uses a file-based request/response pattern:
1. Writes request JSON to `/tmp/llm_classification_request_$$.json` (line 238)
2. Emits signal message to stderr: `[LLM_CLASSIFICATION_REQUEST]` (line 241)
3. Polls for response file `/tmp/llm_classification_response_$$.json` every 0.5s (lines 244-267)
4. Times out after WORKFLOW_CLASSIFICATION_TIMEOUT seconds (default 10s) and returns exit code 1 (lines 270-272)

**Critical Dependency**: This pattern requires an external AI assistant (Claude Code CLI) to monitor stderr for `[LLM_CLASSIFICATION_REQUEST]` signals, process the request, and write the response file. If no assistant is listening (offline mode, different terminal session, CI/CD environment), the function will ALWAYS timeout after 10 seconds.

**Evidence from coordinage_plan.md:62-67**:
```
The issue is clear now - the LLM-based workflow classification is
failing (likely a network or API issue), but it's returning exit code
0 despite the critical error.
```

**Analysis**: The user observation "returning exit code 0" is INCORRECT based on code analysis. The actual behavior is:
- `invoke_llm_classifier()` returns 1 on timeout (line 272)
- `classify_workflow_llm_comprehensive()` returns 1 when invoke fails (line 127)
- `classify_workflow_comprehensive()` returns 1 in llm-only mode (line 69)
- `sm_init()` returns 1 when classification fails (line 382)

The confusion arises because error messages are suppressed by `2>/dev/null`, making the failure appear "silent."

### 2. Silent Failure Mechanism - Stderr Suppression

**Primary Suppression Point** (.claude/lib/workflow-state-machine.sh:352):

```bash
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
```

This line redirects ALL stderr output from the classification function to /dev/null, which includes:
- LLM timeout error messages (workflow-llm-classifier.sh:270)
- LLM invocation failure messages (workflow-llm-classifier.sh:126)
- Comprehensive classification failure messages (workflow-scope-detection.sh:66)

**Why This Matters**:
- Exit codes are still propagated correctly (verified via test_sm_init_failure.sh)
- Error messages with actionable guidance are hidden from users
- Users see "WORKFLOW_SCOPE not exported" (coordinate.md:174) without knowing WHY

**Error Message Chain (All Suppressed)**:

1. invoke_llm_classifier (line 270):
   ```
   ERROR: invoke_llm_classifier: timeout after 10s
   ```

2. classify_workflow_llm_comprehensive (line 126):
   ```
   ERROR: classify_workflow_llm_comprehensive: LLM invocation failed or timed out
   ```

3. classify_workflow_comprehensive (line 66):
   ```
   ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode
   Context: Workflow description: [description]
   Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode for offline development
   ```

**Result**: The helpful suggestion to use `WORKFLOW_CLASSIFICATION_MODE=regex-only` is hidden from users who need it most.

### 3. Error Detection Gaps - Verification vs. Diagnostics

**Verification Checkpoint Works Correctly** (.claude/commands/coordinate.md:166-185):

```bash
# Line 166: sm_init returns 1 on classification failure
if ! sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed..." 1
fi

# Lines 173-183: Verification checkpoints (SHOULD NEVER TRIGGER if above works)
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)" 1
fi
```

**Gap Analysis**:

The verification checkpoints on lines 173-183 are labeled as detecting a "library bug" because they should be unreachable if sm_init() correctly returns non-zero on failure. However, there are edge cases where they provide value:

1. **Bash Block Isolation**: If sm_init() is called in a different subprocess/subshell, exports won't propagate even with successful execution
2. **Source Guard Failures**: If library sourcing fails mid-execution, variables may not be exported even though function returns 0
3. **Future Refactoring Safety**: Defensive programming against accidental removal of export statements

**Evidence from coordinage_implement.md:32-38**:
```
✗ ERROR in state 'initialize': CRITICAL: WORKFLOW_SCOPE
not exported by sm_init despite successful return code
(library bug)
```

This error message is misleading - it's not a "library bug" but rather the expected behavior when LLM classification times out. The real bug is that the error message from sm_init() was suppressed, making it appear that sm_init() succeeded when it actually failed.

### 4. Fallback Architecture - Manual vs. Automatic

**Current Architecture (Post Spec 688 Clean-Break)**:

- **Mode**: llm-only (default) or regex-only (explicit)
- **Behavior**: Fail-fast with error messages (no automatic fallback)
- **User Action Required**: Manual mode switch via `export WORKFLOW_CLASSIFICATION_MODE=regex-only`

**Removed in Clean-Break** (workflow-scope-detection.sh:84-89):
```bash
hybrid)
  # Clean-break: hybrid mode removed
  echo "ERROR: classify_workflow_comprehensive: hybrid mode removed in clean-break update" >&2
  echo "  Context: WORKFLOW_CLASSIFICATION_MODE='$WORKFLOW_CLASSIFICATION_MODE' no longer valid" >&2
  echo "  Suggestion: Use llm-only (default, online development) or regex-only (offline development)" >&2
  return 1
```

**Why Automatic Fallback Was Removed**:

According to Spec 688 Phase 3 and the Development Philosophy section of CLAUDE.md:
- "Clean-break, fail-fast evolution philosophy"
- "No deprecation warnings, compatibility shims, or transition periods"
- "Breaking changes break loudly with clear error messages"
- "No silent fallbacks or graceful degradation"

**Impact on Offline Development**:

**Before (Hybrid Mode)**:
```bash
# Automatic fallback on LLM failure
WORKFLOW_CLASSIFICATION_MODE=hybrid
result=$(classify_workflow_comprehensive "$desc")
# Would silently fall back to regex if LLM timed out
```

**After (2-Mode System)**:
```bash
# Manual fallback required
if ! result=$(classify_workflow_comprehensive "$desc" 2>&1); then
  echo "LLM failed, use: export WORKFLOW_CLASSIFICATION_MODE=regex-only"
  exit 1
fi
```

**Success Case from coordinage_plan.md:70-74**:
```
export WORKFLOW_CLASSIFICATION_MODE=regex-only
# Testing sm_init with regex-only mode...
Comprehensive classification: scope=research-and-plan, complexity=2, topics=2
✓ VERIFIED: All exports present
```

This demonstrates that regex-only mode works reliably, but users must discover and enable it manually.

### 5. Network Detection and Timeout Mechanisms

**Current State**: No network detection exists. The system relies solely on timeout.

**Timeout Configuration** (.claude/lib/workflow-llm-classifier.sh:24):
```bash
WORKFLOW_CLASSIFICATION_TIMEOUT="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
```

**Timeout Implementation** (lines 244-267):
```bash
local iterations=$((WORKFLOW_CLASSIFICATION_TIMEOUT * 2))  # Check every 0.5s
local count=0
while [ $count -lt $iterations ]; do
  if [ -f "$response_file" ]; then
    # Success path
    return 0
  fi
  sleep 0.5
  count=$((count + 1))
done
# Timeout path
return 1
```

**Problems**:
1. No network connectivity check before waiting 10 seconds
2. No differentiation between "offline" vs. "slow network" vs. "API error"
3. Users in offline mode waste 10 seconds before seeing timeout error
4. Error messages (which suggest regex-only mode) are suppressed

**Missing Capabilities**:
- Pre-flight network check (ping anthropic.com or check for localhost)
- Fast-fail for known offline environments (check $WORKFLOW_CLASSIFICATION_MODE not set + no network)
- Automatic mode detection based on environment (CI/CD detection, network availability)

### 6. Error Message Quality vs. Visibility

**High-Quality Error Messages Exist** (.claude/lib/workflow-scope-detection.sh:66-68):

```bash
echo "ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode" >&2
echo "  Context: Workflow description: $workflow_description" >&2
echo "  Suggestion: Check network connection, increase WORKFLOW_CLASSIFICATION_TIMEOUT, or use regex-only mode for offline development" >&2
```

**Problem**: These messages are hidden by `2>/dev/null` in workflow-state-machine.sh:352.

**User Experience**:

**What Users See** (coordinate.md:174):
```
CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)
```

**What They Should See**:
```
ERROR: LLM classification failed (timeout after 10s)
  Suggestion: Use regex-only mode for offline development
  Command: export WORKFLOW_CLASSIFICATION_MODE=regex-only
```

**Gap**: 3 layers of detailed error context are discarded before reaching the user.

## Recommendations

### 1. Remove Stderr Suppression in sm_init (High Priority)

**Change** (.claude/lib/workflow-state-machine.sh:352):

```bash
# Current (suppresses errors):
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then

# Recommended (preserves error messages):
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>&1); then
```

**Impact**:
- Users see actionable error messages immediately
- "WORKFLOW_SCOPE not exported" error becomes self-diagnosing
- Reduces support burden and confusion

**Risk**: Low - error messages are already designed for user consumption and include actionable suggestions

### 2. Add Network Pre-Flight Check (Medium Priority)

**Add to workflow-llm-classifier.sh before invoke_llm_classifier()**:

```bash
check_network_connectivity() {
  # Fast check for obvious offline scenarios
  if [ "${WORKFLOW_CLASSIFICATION_MODE:-}" = "regex-only" ]; then
    return 0  # Skip check, user explicitly chose offline mode
  fi

  # Check for localhost-only environment
  if ! timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "WARNING: No network connectivity detected" >&2
    echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work" >&2
    return 1
  fi

  return 0
}

invoke_llm_classifier() {
  # Pre-flight check
  if ! check_network_connectivity; then
    return 1  # Fast-fail instead of 10s timeout
  fi

  # ... existing implementation
}
```

**Impact**:
- Offline scenarios fail in <1s instead of 10s
- Clear network error messages guide users to regex-only mode
- Online scenarios unaffected (1s ping adds minimal overhead)

### 3. Add Smart Mode Auto-Detection (Low Priority, Optional)

**Add to workflow-scope-detection.sh**:

```bash
auto_detect_classification_mode() {
  # Check if explicitly set
  if [ -n "${WORKFLOW_CLASSIFICATION_MODE:-}" ]; then
    echo "${WORKFLOW_CLASSIFICATION_MODE}"
    return 0
  fi

  # Auto-detect based on environment
  # CI/CD environments: Use regex-only for deterministic testing
  if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${GITLAB_CI:-}" ]; then
    echo "regex-only"
    return 0
  fi

  # Quick network check
  if timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "llm-only"
  else
    echo "regex-only"
  fi
}

# Use in classify_workflow_comprehensive:
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-$(auto_detect_classification_mode)}"
```

**Impact**:
- Zero-config offline development
- Automatic CI/CD optimization
- Maintains explicit control when WORKFLOW_CLASSIFICATION_MODE is set

**Risk**: Medium - auto-detection could mask network issues or surprise users. Should be opt-in via environment variable like `WORKFLOW_CLASSIFICATION_AUTO_DETECT=1`.

### 4. Improve Error Message in coordinate.md (Low Priority)

**Change** (.claude/commands/coordinate.md:174):

```bash
# Current:
handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)" 1

# Recommended:
handle_state_error "CRITICAL: State machine initialization failed to export required variables. This indicates sm_init() encountered an error that was not properly caught. Review error messages above." 1
```

**Impact**:
- More accurate error description
- Directs users to review previous error messages
- Removes misleading "library bug" label

### 5. Document Offline Mode in Error Messages (Low Priority)

**Add to all LLM error handlers**:

```bash
echo "" >&2
echo "OFFLINE MODE QUICK START:" >&2
echo "  export WORKFLOW_CLASSIFICATION_MODE=regex-only" >&2
echo "  # Then retry your command" >&2
```

**Impact**:
- Explicit copy-paste solution for offline users
- Reduces time to resolution
- Supplements existing "use regex-only mode" suggestions

### 6. Add Smoke Test for Offline Scenarios (Medium Priority)

**Create .claude/tests/test_offline_classification.sh**:

```bash
#!/usr/bin/env bash
# Test that classification fails gracefully in offline scenarios

test_llm_timeout_without_suppression() {
  export WORKFLOW_CLASSIFICATION_MODE=llm-only
  export WORKFLOW_CLASSIFICATION_TIMEOUT=2

  # Should fail with clear error message (not silently)
  if result=$(classify_workflow_comprehensive "test workflow" 2>&1); then
    echo "FAIL: Should have timed out"
    return 1
  fi

  # Check error message mentions regex-only
  if echo "$result" | grep -q "regex-only"; then
    echo "PASS: Error message suggests offline mode"
    return 0
  else
    echo "FAIL: Error message missing offline guidance"
    return 1
  fi
}
```

**Impact**:
- Prevents regression of error visibility
- Validates error message quality
- Documents expected offline behavior

## References

### Primary Source Files

1. `.claude/lib/workflow-llm-classifier.sh` - LLM classification implementation
   - Lines 218-273: invoke_llm_classifier() file-based signaling pattern
   - Lines 107-154: classify_workflow_llm_comprehensive() error handling
   - Lines 24: WORKFLOW_CLASSIFICATION_TIMEOUT configuration

2. `.claude/lib/workflow-scope-detection.sh` - Unified classification library
   - Lines 49-99: classify_workflow_comprehensive() mode routing
   - Lines 62-75: llm-only mode with fail-fast error handling
   - Lines 77-82: regex-only mode implementation
   - Lines 84-89: Removed hybrid mode with clean-break error

3. `.claude/lib/workflow-state-machine.sh` - State machine initialization
   - Line 352: CRITICAL stderr suppression (`2>/dev/null`)
   - Lines 345-383: sm_init() comprehensive classification logic
   - Lines 364-366: Export statements for WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
   - Lines 370-382: Error handling and troubleshooting messages

4. `.claude/commands/coordinate.md` - Command implementation
   - Lines 165-168: sm_init() invocation with error handling
   - Lines 171-185: Verification checkpoints for exported variables
   - Line 174: "library bug" error message (misleading)

### Evidence Files

5. `.claude/specs/coordinage_plan.md` - User-observed failure
   - Lines 62-67: "returning exit code 0 despite the critical error" (user misconception)
   - Lines 70-74: Successful regex-only mode workaround

6. `.claude/specs/coordinage_implement.md` - Error manifestation
   - Lines 32-38: "WORKFLOW_SCOPE not exported by sm_init despite successful return code (library bug)"

### Documentation Files

7. `.claude/docs/guides/workflow-classification-guide.md` - Complete classification guide
   - Lines 1-660: Comprehensive 2-mode system documentation
   - Lines 206-271: Error handling and fail-fast behavior
   - Lines 272-323: Migration from hybrid mode
   - Lines 453-483: Performance comparison (accuracy, latency, cost, availability)

8. `CLAUDE.md` - Project standards
   - Lines (Development Philosophy section): Clean-break and fail-fast approach
   - "No silent fallbacks or graceful degradation"
   - "Breaking changes break loudly with clear error messages"

### Test and Validation Files

9. `/tmp/test_sm_init_failure.sh` (created during research) - Validated that exit codes propagate correctly even with `2>/dev/null`
10. `/tmp/test_llm_timeout.sh` (created during research) - Validated timeout behavior in different error handling scenarios
