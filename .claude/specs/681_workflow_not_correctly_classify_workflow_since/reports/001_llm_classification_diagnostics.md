# LLM-Based Workflow Classification Diagnostic Methods

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Diagnostic Methods for LLM-Based Workflow Classification
- **Report Type**: Codebase analysis

## Executive Summary

The hybrid LLM-based workflow classification system in `workflow-scope-detection.sh` and `workflow-llm-classifier.sh` currently has limited visibility into whether the Haiku LLM model is actually being invoked. The primary issue is that stderr redirection (`2>/dev/null`) at line 58 of `workflow-scope-detection.sh` silences the `[LLM_CLASSIFICATION_REQUEST]` signal that would indicate LLM invocation. Two debug environment variables exist (`WORKFLOW_CLASSIFICATION_DEBUG` and `DEBUG_SCOPE_DETECTION`) but no logging infrastructure integration is implemented. Diagnostic methods include examining temp file artifacts, checking debug output when enabled, and analyzing the absence of error messages, but these require manual intervention and are not suitable for automated monitoring.

## Findings

### 1. Current Classification Architecture

**File**: `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`

The hybrid classification system operates in three modes (lines 31-33, 55-114):

```bash
# Configuration
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"
DEBUG_SCOPE_DETECTION="${DEBUG_SCOPE_DETECTION:-0}"

# detect_workflow_scope: Unified hybrid workflow classification
case "$WORKFLOW_CLASSIFICATION_MODE" in
  hybrid)
    # Try LLM first, fallback to regex on error/timeout/low-confidence
    if scope=$(classify_workflow_llm "$workflow_description" 2>/dev/null); then
      # LLM classification succeeded
      local llm_scope
      llm_scope=$(echo "$scope" | jq -r '.scope // empty')

      if [ -n "$llm_scope" ]; then
        log_scope_detection "hybrid" "llm" "$llm_scope"
        echo "$llm_scope"
        return 0
      fi
    fi

    # LLM failed - fallback to regex
    log_scope_detection "hybrid" "regex-fallback" ""
    scope=$(classify_workflow_regex "$workflow_description")
    log_scope_detection "hybrid" "regex" "$scope"
    echo "$scope"
    return 0
    ;;
```

**Key Observation**: Line 58 uses `2>/dev/null` to silence stderr, which prevents visibility into LLM invocation errors, timeouts, and the critical `[LLM_CLASSIFICATION_REQUEST]` signal.

### 2. Stderr Redirection Problem

**File**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (lines 125-180)

The `invoke_llm_classifier()` function emits a signal to stderr:

```bash
invoke_llm_classifier() {
  local llm_input="$1"
  local request_file="/tmp/llm_classification_request_$$.json"
  local response_file="/tmp/llm_classification_response_$$.json"

  # Write request file
  echo "$llm_input" > "$request_file"

  # Signal to AI assistant
  echo "[LLM_CLASSIFICATION_REQUEST] Please process request at: $request_file → $response_file" >&2

  # Wait for response with timeout
  local iterations=$((WORKFLOW_CLASSIFICATION_TIMEOUT * 2))  # Check every 0.5s
  local count=0
  while [ $count -lt $iterations ]; do
    if [ -f "$response_file" ]; then
      # Response received - read and return
      local response
      response=$(cat "$response_file")

      if [ -z "$response" ]; then
        log_classification_debug "invoke_llm_classifier" "response file empty"
        cleanup_temp_files
        return 1
      fi

      local elapsed=$(echo "$count * 0.5" | awk '{print $1}')
      log_classification_debug "invoke_llm_classifier" "response received after ${elapsed}s"
      echo "$response"
      cleanup_temp_files
      return 0
    fi

    sleep 0.5
    count=$((count + 1))
  done

  # Timeout
  log_classification_error "invoke_llm_classifier" "timeout after ${WORKFLOW_CLASSIFICATION_TIMEOUT}s"
  cleanup_temp_files
  return 1
}
```

**Impact**: The `2>/dev/null` redirection at the caller site (workflow-scope-detection.sh:58) suppresses:
- The `[LLM_CLASSIFICATION_REQUEST]` signal (line 148)
- Timeout errors from `log_classification_error()` (line 177)
- Empty response warnings from `log_classification_debug()` (line 159)

### 3. Debug Environment Variables

**Primary Variables**:

1. **`DEBUG_SCOPE_DETECTION`** (workflow-scope-detection.sh:33, 190-192)
   ```bash
   DEBUG_SCOPE_DETECTION="${DEBUG_SCOPE_DETECTION:-0}"

   log_scope_detection() {
     local mode="$1"
     local method="$2"
     local scope="${3:-}"

     if [ "$DEBUG_SCOPE_DETECTION" = "1" ]; then
       echo "[DEBUG] Scope Detection: mode=$mode, method=$method${scope:+, scope=$scope}" >&2
     fi
   }
   ```
   - **Purpose**: Logs which classification method was used (llm, regex, regex-fallback)
   - **Output**: Stderr only (can still be lost if command redirects stderr)
   - **Example**: `[DEBUG] Scope Detection: mode=hybrid, method=llm, scope=research-and-plan`

2. **`WORKFLOW_CLASSIFICATION_DEBUG`** (workflow-llm-classifier.sh:25, 250-288)
   ```bash
   WORKFLOW_CLASSIFICATION_DEBUG="${WORKFLOW_CLASSIFICATION_DEBUG:-0}"

   log_classification_debug() {
     local function_name="$1"
     local debug_message="$2"

     if [ "$WORKFLOW_CLASSIFICATION_DEBUG" = "1" ]; then
       echo "[DEBUG] LLM Classifier: $function_name: $debug_message" >&2
     fi
   }

   log_classification_error() {
     local function_name="$1"
     local error_message="$2"

     echo "[ERROR] LLM Classifier: $function_name: $error_message" >&2

     if [ "$WORKFLOW_CLASSIFICATION_DEBUG" = "1" ]; then
       # In debug mode, print stack trace context
       echo "[DEBUG] Call stack: ${FUNCNAME[*]}" >&2
     fi
   }
   ```
   - **Purpose**: Logs detailed LLM classifier operations (input building, response parsing, timeout)
   - **Output**: Stderr only
   - **Examples**:
     - `[DEBUG] LLM Classifier: invoke_llm_classifier: response received after 2.5s`
     - `[ERROR] LLM Classifier: invoke_llm_classifier: timeout after 10s`

**Configuration Variables**:

3. **`WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD`** (default: 0.7)
4. **`WORKFLOW_CLASSIFICATION_TIMEOUT`** (default: 10 seconds)
5. **`WORKFLOW_CLASSIFICATION_MODE`** (default: hybrid, options: llm-only, regex-only)

### 4. Logging Infrastructure

**File**: `/home/benjamin/.config/.claude/lib/unified-logger.sh`

The unified logger library exists (774 lines) but **does not currently integrate with workflow classification**. The library provides:

- Structured logging to `.claude/data/logs/adaptive-planning.log`
- Log rotation (10MB max, 5 files)
- Query functions (`query_adaptive_log()`, `get_adaptive_stats()`)
- Event types: trigger_eval, replan, loop_prevention, collapse_check

**Current Gap**: Lines 194 in workflow-scope-detection.sh shows a TODO comment:

```bash
log_scope_detection() {
  # ... existing stderr logging ...

  # TODO: Integrate with unified-logger.sh for structured logging
}
```

**Available Log Files** (from `.claude/data/logs/`):
- `adaptive-planning.log` - Adaptive planning events (complexity checks, replanning)
- `approval-decisions.log` - User approval tracking
- `complexity-debug.log` - Complexity scoring details
- `hook-debug.log` - Pre-commit hook debugging
- `phase-handoffs.log` - Phase transition tracking
- `subagent-outputs.log` - Subagent delegation results
- `supervision-tree.log` - Hierarchical supervisor coordination
- `tts.log` - Text-to-speech output log

**Missing**: No dedicated workflow classification log file exists.

### 5. Temporary File Artifacts

**File-Based Signaling Pattern** (workflow-llm-classifier.sh:131-179)

The LLM classifier uses temporary files in `/tmp/`:

```bash
local request_file="/tmp/llm_classification_request_$$.json"
local response_file="/tmp/llm_classification_response_$$.json"
```

**Evidence of LLM Invocation**: Presence of these files indicates LLM was attempted:

```bash
$ ls -la /tmp/llm_classification_*
-rw-r--r-- 1 benjamin users 617 Nov 12 09:26 /tmp/llm_classification_request_228021.json
-rw-r--r-- 1 benjamin users 617 Nov 12 09:30 /tmp/llm_classification_request_257597.json
-rw-r--r-- 1 benjamin users 617 Nov 12 09:49 /tmp/llm_classification_request_317709.json
```

**Request File Format** (JSON):
```json
{
  "task": "classify_workflow_scope",
  "description": "Implement authentication system",
  "valid_scopes": [
    "research-only",
    "research-and-plan",
    "research-and-revise",
    "full-implementation",
    "debug-only"
  ],
  "instructions": "Analyze the workflow description and determine the user intent. Return a JSON object with: scope (one of valid_scopes), confidence (0.0-1.0), reasoning (brief explanation). Focus on INTENT, not keywords - e.g., 'research the research-and-revise workflow' is research-and-plan (intent: learn about workflow type), not research-and-revise (intent: revise a plan)."
}
```

**Diagnostic Value**:
- **Request file exists, no response file**: LLM invoked but timed out (no response received within 10s)
- **Both files exist**: LLM successfully processed request
- **Neither file exists**: LLM was never invoked (regex fallback used immediately)
- **Cleanup behavior**: Files are removed after successful processing (line 168: `cleanup_temp_files`)

**Limitation**: Temporary files are ephemeral and require manual inspection immediately after classification.

### 6. State Machine Debug Output

**File**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

The state machine library (Line 1-100+ analyzed) manages workflow states but **does not have direct classification visibility**. It receives the classification result as input:

```bash
# State machine receives WORKFLOW_SCOPE (already determined)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
```

The state machine transitions based on the **result** of classification, not the **method** of classification.

### 7. Distinguishing LLM from Regex Fallback

**Methods to Distinguish**:

1. **Debug Environment Variable** (Most Reliable):
   ```bash
   export DEBUG_SCOPE_DETECTION=1
   /coordinate "your workflow description"
   # Look for: [DEBUG] Scope Detection: mode=hybrid, method=llm
   # vs:       [DEBUG] Scope Detection: mode=hybrid, method=regex-fallback
   ```

2. **Temporary File Existence** (Immediate Post-Classification):
   ```bash
   ls /tmp/llm_classification_request_*.json
   # If files exist: LLM was invoked
   # If no files: regex-only classification
   ```

3. **Timing Analysis** (Indirect):
   - LLM classification: 0.5-10 seconds (waiting for response)
   - Regex classification: <50ms (immediate pattern matching)
   - **Limitation**: Other operations may dominate timing

4. **Error Pattern Analysis** (Negative Signal):
   ```bash
   export WORKFLOW_CLASSIFICATION_DEBUG=1
   /coordinate "workflow" 2>&1 | grep "ERROR.*LLM Classifier"
   # If errors present: LLM attempted but failed
   # If no errors AND no debug output: Either succeeded or never invoked
   ```

5. **Confidence Score** (LLM-Only Feature):
   - LLM returns: `{"scope":"X","confidence":0.95,"reasoning":"..."}`
   - Regex returns: Only scope string (no confidence or reasoning)
   - **Limitation**: Not exposed in current interface (internal only)

### 8. Signals Indicating LLM Is/Isn't Working

**LLM IS Working (Positive Signals)**:

1. **Debug output shows LLM method**:
   ```
   [DEBUG] Scope Detection: mode=hybrid, method=llm, scope=research-and-plan
   ```

2. **Response file created in /tmp/**:
   ```
   /tmp/llm_classification_response_<PID>.json
   ```

3. **Classification completes quickly** (1-5 seconds, not immediate)

4. **Edge cases classified correctly**:
   - "research the research-and-revise workflow" → research-and-plan (LLM correct)
   - "research the research-and-revise workflow" → research-and-revise (regex incorrect)

**LLM IS NOT Working (Negative Signals)**:

1. **Debug output shows regex fallback**:
   ```
   [DEBUG] Scope Detection: mode=hybrid, method=regex-fallback
   ```

2. **No temp files in /tmp/** (or only request file without response)

3. **Classification completes instantly** (<100ms)

4. **Timeout errors in debug output**:
   ```
   [ERROR] LLM Classifier: invoke_llm_classifier: timeout after 10s
   ```

5. **Edge cases classified incorrectly** (matches regex patterns, not intent)

### 9. Current Logging Gaps

**Critical Gaps**:

1. **No Persistent Classification Logs**: Classification decisions are not logged to files
   - Impact: Cannot audit classification decisions retroactively
   - Root Cause: TODO at workflow-scope-detection.sh:194 never implemented

2. **Stderr-Only Debug Output**: All debug information goes to stderr
   - Impact: Lost if commands redirect stderr (common in orchestration)
   - Root Cause: `2>/dev/null` at workflow-scope-detection.sh:58

3. **No Classification Metrics**: No tracking of LLM vs regex usage ratios
   - Impact: Cannot measure LLM adoption or fallback frequency
   - Root Cause: No metrics collection infrastructure

4. **No Confidence Score Exposure**: LLM confidence scores not logged or returned
   - Impact: Cannot tune confidence threshold based on real-world data
   - Root Cause: Internal-only field, not surfaced to callers

5. **No Response Time Logging**: LLM invocation duration not tracked
   - Impact: Cannot identify timeout issues or optimize timeout threshold
   - Root Cause: No timing instrumentation in invoke_llm_classifier()

6. **Temporary File Cleanup**: Evidence destroyed after successful classification
   - Impact: Cannot verify LLM usage post-execution
   - Root Cause: Cleanup function at workflow-llm-classifier.sh:137-139

### 10. Test Infrastructure for Diagnostics

**File**: `/home/benjamin/.config/.claude/tests/test_llm_classifier.sh`

Comprehensive unit tests exist (442 lines, 7 sections):
- Section 1: Input validation (5 tests)
- Section 2: JSON building (3 tests)
- Section 3: Response parsing (10 tests)
- Section 4: Confidence threshold (3 tests)
- Section 5: Logging functions (5 tests)
- Section 6: Configuration (4 tests)
- Section 7: Error handling (3 tests)

**File**: `/home/benjamin/.config/.claude/tests/manual_e2e_hybrid_classification.sh`

Manual integration tests document expected behavior (197 lines, 6 test cases):
- Test 1: Problematic edge case (research-and-revise false positive)
- Test 2: Normal classification case
- Test 3: Revision case
- Test 4: Fallback behavior (forced timeout)
- Test 5: LLM-only mode (fail-fast)
- Test 6: Mode switching

**Key Testing Gap**: No automated integration test that verifies LLM is actually invoked in production workflows. Manual tests require real LLM assistance.

## Recommendations

### 1. Implement Structured Workflow Classification Logging

**Priority**: High
**Effort**: Medium (2-4 hours)

Integrate workflow classification with unified-logger.sh:

```bash
# Add to unified-logger.sh
log_workflow_classification() {
  local mode="$1"           # hybrid, llm-only, regex-only
  local method="$2"         # llm, regex, regex-fallback
  local scope="$3"          # detected scope
  local confidence="${4:-}" # LLM confidence (optional)
  local duration_ms="${5:-0}" # Classification time (optional)

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local log_file="${CLAUDE_LOGS_DIR:-.claude/data/logs}/workflow-classification.log"
  rotate_log_file "$log_file"

  local entry
  entry=$(printf '[%s] INFO workflow_classification: mode=%s, method=%s, scope=%s, confidence=%s, duration_ms=%d\n' \
    "$timestamp" "$mode" "$method" "$scope" "${confidence:-N/A}" "$duration_ms")

  echo "$entry" >> "$log_file"
}
```

**Benefits**:
- Persistent audit trail of all classification decisions
- Metrics collection (LLM vs regex usage, confidence distribution)
- Debugging support (correlation with workflow failures)
- Performance monitoring (classification latency)

### 2. Remove Stderr Redirection in Hybrid Mode

**Priority**: High
**Effort**: Low (30 minutes)

Change workflow-scope-detection.sh:58 to preserve stderr:

```bash
# Before (line 58):
if scope=$(classify_workflow_llm "$workflow_description" 2>/dev/null); then

# After:
if scope=$(classify_workflow_llm "$workflow_description"); then
```

**Alternative**: Redirect stderr to log file instead of /dev/null:

```bash
LOG_FILE="${CLAUDE_LOGS_DIR:-.claude/data/logs}/workflow-classification-debug.log"
if scope=$(classify_workflow_llm "$workflow_description" 2>>"$LOG_FILE"); then
```

**Benefits**:
- `[LLM_CLASSIFICATION_REQUEST]` signal visible
- Timeout errors captured
- Debug output preserved
- No silent failures

**Risk**: May expose internal errors to user stderr (mitigated by log file redirection)

### 3. Add Classification Instrumentation

**Priority**: Medium
**Effort**: Medium (2-3 hours)

Instrument classify_workflow_llm() with timing and metrics:

```bash
classify_workflow_llm() {
  local workflow_description="$1"
  local start_time
  start_time=$(date +%s%3N) # Milliseconds since epoch

  # ... existing classification logic ...

  local end_time
  end_time=$(date +%s%3N)
  local duration_ms=$((end_time - start_time))

  # Log classification with timing
  if [ -n "$llm_scope" ]; then
    log_workflow_classification "$WORKFLOW_CLASSIFICATION_MODE" "llm" "$llm_scope" "$confidence" "$duration_ms"
  fi

  # ... return result ...
}
```

**Benefits**:
- Performance monitoring (detect timeout issues)
- Usage metrics (LLM invocation frequency)
- Confidence tracking (tune threshold)

### 4. Create Diagnostic Subcommand

**Priority**: Low
**Effort**: High (4-6 hours)

Add `/diagnose-classification` command:

```bash
# Query recent classifications
/diagnose-classification --recent 10

# Analyze classification patterns
/diagnose-classification --analyze

# Test classification without running workflow
/diagnose-classification --test "research auth patterns"
```

**Features**:
- Display recent classification decisions from log
- Calculate LLM vs regex usage ratio
- Show average confidence scores
- Test classification without side effects
- Verify LLM connectivity

**Benefits**:
- Self-service diagnostics for users
- No need for manual log inspection
- Proactive health monitoring

### 5. Expose Classification Metadata

**Priority**: Medium
**Effort**: Medium (3-4 hours)

Return classification metadata alongside scope:

```bash
# Current interface (scope only):
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Enhanced interface (scope + metadata):
CLASSIFICATION_RESULT=$(detect_workflow_scope_with_metadata "$WORKFLOW_DESCRIPTION")
WORKFLOW_SCOPE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.scope')
CLASSIFICATION_METHOD=$(echo "$CLASSIFICATION_RESULT" | jq -r '.method')
CLASSIFICATION_CONFIDENCE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.confidence // "N/A"')

# Example output:
# {
#   "scope": "research-and-plan",
#   "method": "llm",
#   "confidence": 0.95,
#   "reasoning": "Intent is to research topic and create implementation plan"
# }
```

**Benefits**:
- Orchestrators can log classification metadata
- Users can see why scope was chosen
- Debugging information available at runtime

### 6. Preserve Temporary Files in Debug Mode

**Priority**: Low
**Effort**: Low (1 hour)

Conditionally preserve temp files when debugging:

```bash
cleanup_temp_files() {
  if [ "${WORKFLOW_CLASSIFICATION_DEBUG}" != "1" ]; then
    rm -f "$request_file" "$response_file"
  else
    echo "[DEBUG] Temp files preserved: $request_file, $response_file" >&2
  fi
}
```

**Benefits**:
- Post-execution inspection of LLM requests/responses
- Debugging support for misclassifications
- Evidence preservation for issue reports

**Trade-off**: Accumulates temp files in debug mode (requires manual cleanup)

### 7. Add Health Check Endpoint

**Priority**: Low
**Effort**: Medium (2-3 hours)

Create function to verify LLM connectivity:

```bash
test_llm_classifier_health() {
  local test_description="test health check"
  local timeout_backup="${WORKFLOW_CLASSIFICATION_TIMEOUT}"

  # Use short timeout for health check
  export WORKFLOW_CLASSIFICATION_TIMEOUT=5

  if classify_workflow_llm "$test_description" >/dev/null 2>&1; then
    echo "✓ LLM classifier healthy"
    export WORKFLOW_CLASSIFICATION_TIMEOUT="$timeout_backup"
    return 0
  else
    echo "✗ LLM classifier unavailable (fallback to regex)"
    export WORKFLOW_CLASSIFICATION_TIMEOUT="$timeout_backup"
    return 1
  fi
}
```

**Benefits**:
- Startup validation of LLM connectivity
- Proactive warning when LLM unavailable
- Automated health monitoring

## References

### Primary Source Files

- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (lines 1-199)
  - Line 33: DEBUG_SCOPE_DETECTION configuration
  - Line 58: Problematic 2>/dev/null redirection
  - Lines 185-195: log_scope_detection() function with TODO comment

- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (lines 1-298)
  - Line 25: WORKFLOW_CLASSIFICATION_DEBUG configuration
  - Lines 125-180: invoke_llm_classifier() with file-based signaling
  - Line 148: [LLM_CLASSIFICATION_REQUEST] stderr signal
  - Lines 261-288: Logging functions (debug, error, result)

- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (lines 1-775)
  - Lines 1-136: Core logging infrastructure
  - Lines 104-136: Adaptive planning logging (reference implementation)
  - Line 194: Missing workflow classification integration

### Test Files

- `/home/benjamin/.config/.claude/tests/test_llm_classifier.sh` (442 lines)
  - Unit tests for LLM classifier library
  - 7 sections covering all major functionality

- `/home/benjamin/.config/.claude/tests/manual_e2e_hybrid_classification.sh` (197 lines)
  - Manual integration tests for hybrid mode
  - 6 test cases with expected behavior documentation

### Log Files

- `/home/benjamin/.config/.claude/data/logs/` (directory)
  - adaptive-planning.log (structured events)
  - complexity-debug.log (complexity scoring)
  - hook-debug.log (git hooks)
  - tts.log (text-to-speech)
  - **Missing**: workflow-classification.log

### Temporary Artifacts

- `/tmp/llm_classification_request_<PID>.json` (ephemeral)
  - Created by invoke_llm_classifier()
  - Contains workflow description and classification task
  - Removed after successful processing

- `/tmp/llm_classification_response_<PID>.json` (ephemeral)
  - Created by AI assistant in response to request
  - Contains scope, confidence, reasoning
  - Removed after successful processing
