# Fallback Strategies and Improvements Research Report

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist
- **Topic**: Fallback strategies and robustness improvements for /coordinate LLM classification errors
- **Report Type**: codebase analysis and best practices
- **Overview Report**: [OVERVIEW.md](OVERVIEW.md)

## Executive Summary

The /coordinate command currently implements fail-fast error handling for LLM classification failures with minimal automatic fallback mechanisms. The system has an existing regex-only mode that requires manual environment variable configuration (WORKFLOW_CLASSIFICATION_MODE=regex-only) before invocation. User experience during classification failures is characterized by comprehensive error messages but lacks automatic retry logic or graceful degradation. Analysis reveals opportunities for improved robustness through pre-flight network checks, automatic fallback to regex-only mode, enhanced retry mechanisms with backoff, and better user guidance during offline scenarios.

## Findings

### Current Fallback Architecture

#### 1. Two-Mode Classification System (Clean-Break Design)

**Location**: `.claude/lib/workflow-scope-detection.sh:30-99`

The system implements a clean two-mode architecture:

```bash
# Line 31: Default mode
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"

# Line 61-98: Mode routing
case "$WORKFLOW_CLASSIFICATION_MODE" in
  llm-only)
    # LLM only - fail fast on errors (no automatic fallback)
    if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
      echo "ERROR: classify_workflow_comprehensive: LLM classification failed in llm-only mode" >&2
      return 1
    fi
    ;;

  regex-only)
    # Use comprehensive regex-based classifier (offline mode)
    if ! regex_result=$(classify_workflow_regex_comprehensive "$workflow_description"); then
      echo "ERROR: classify_workflow_comprehensive: Regex classification failed" >&2
      return 1
    fi
    ;;

  hybrid)
    # Clean-break: hybrid mode removed (lines 84-90)
    echo "ERROR: hybrid mode removed in clean-break update" >&2
    return 1
    ;;
esac
```

**Key Finding**: Hybrid automatic fallback was intentionally removed in a clean-break refactoring (Spec 688 Phase 3). The current design requires explicit mode selection before invocation - no runtime fallback exists between modes.

#### 2. Network Connectivity Pre-Flight Check

**Location**: `.claude/lib/workflow-llm-classifier.sh:218-240`

A network check was added in Spec 700 Phase 5 for fast-fail in offline scenarios:

```bash
check_network_connectivity() {
  # Fast check for obvious offline scenarios
  if [ "${WORKFLOW_CLASSIFICATION_MODE:-}" = "regex-only" ]; then
    return 0  # Skip check, user explicitly chose offline mode
  fi

  # Check for localhost-only environment
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

**Current Behavior**:
- Called by `invoke_llm_classifier()` before attempting LLM API call (line 254)
- Returns error exit code (1) when network unavailable
- Provides user guidance suggesting regex-only mode
- **No automatic fallback** - just fails fast with helpful message

#### 3. sm_init Error Handling

**Location**: `.claude/lib/workflow-state-machine.sh:337-391`

The state machine initialization in sm_init() handles classification failures with fail-fast approach:

```bash
# Line 353: Capture both stdout and stderr
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>&1); then
  # Success path: Parse and export results
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
else
  # Fail-fast: No automatic fallback (lines 372-383)
  echo "CRITICAL ERROR: Comprehensive classification failed" >&2
  echo "  Workflow Description: $workflow_desc" >&2
  echo "  Classification Mode: ${WORKFLOW_CLASSIFICATION_MODE:-llm-only}" >&2
  echo "" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  1. Check network connection (LLM classification requires API access)" >&2
  echo "  2. Increase timeout: export WORKFLOW_CLASSIFICATION_TIMEOUT=60" >&2
  echo "  3. Use offline mode: export WORKFLOW_CLASSIFICATION_MODE=regex-only" >&2
  echo "  4. Check API credentials if using external classification service" >&2
  echo "" >&2
  return 1
fi
```

**Key Finding**: sm_init returns error immediately on classification failure. The /coordinate command checks this return code (coordinate.md:167-171) and calls `handle_state_error()` with a user-friendly message suggesting regex-only mode for offline development.

#### 4. Coordinate Command Integration

**Location**: `.claude/commands/coordinate.md:167-171`

The /coordinate command handles sm_init failures:

```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi
```

**User Experience Impact**:
- User sees comprehensive five-component error message from `handle_state_error()` (error-handling.sh:748-858)
- Error includes: what failed, expected behavior, diagnostic commands, workflow context, recommended action
- Workflow terminates immediately - user must fix environment and re-run
- No automatic retry, no fallback to regex-only mode

### Existing Error Handling Components

#### 1. Structured Error Types

**Location**: `.claude/lib/error-handling.sh:18-27`

Five LLM-specific error types are defined:

```bash
readonly ERROR_TYPE_LLM_TIMEOUT="llm_timeout"
readonly ERROR_TYPE_LLM_API_ERROR="llm_api_error"
readonly ERROR_TYPE_LLM_LOW_CONFIDENCE="llm_low_confidence"
readonly ERROR_TYPE_LLM_PARSE_ERROR="llm_parse_error"
readonly ERROR_TYPE_INVALID_MODE="invalid_mode"
```

#### 2. handle_llm_classification_failure Function

**Location**: `.claude/lib/workflow-llm-classifier.sh:479-535`

Provides actionable suggestions based on error type:

```bash
handle_llm_classification_failure() {
  local error_type="$1"
  local error_message="$2"
  local workflow_description="$3"

  echo "ERROR: LLM classification failed" >&2
  echo "  Error Type: $error_type" >&2

  case "$error_type" in
    timeout|"$ERROR_TYPE_LLM_TIMEOUT")
      echo "  Suggestion: Increase WORKFLOW_CLASSIFICATION_TIMEOUT" >&2
      echo "  Alternative: Use regex-only mode for offline development" >&2
      ;;
    api_error|"$ERROR_TYPE_LLM_API_ERROR")
      echo "  Suggestion: Check network connection and API availability" >&2
      echo "  Alternative: Use regex-only mode for offline development" >&2
      ;;
    # ... other error types with specific guidance
  esac

  return 1  # Always fail-fast
}
```

**Current Usage**: This function exists in the library but is **not called by any code** in the current implementation. The sm_init error path (workflow-state-machine.sh:372-383) duplicates similar logic inline instead of calling this function.

#### 3. Retry Logic Infrastructure

**Location**: `.claude/lib/error-handling.sh:243-273`

Generic retry with exponential backoff exists:

```bash
retry_with_backoff() {
  local max_attempts="${1:-3}"
  local base_delay_ms="${2:-500}"
  shift 2
  local command=("$@")

  local attempt=1
  local delay_ms=$base_delay_ms

  while [ $attempt -le $max_attempts ]; do
    if "${command[@]}" 2>/dev/null; then
      return 0
    fi

    if [ $attempt -lt $max_attempts ]; then
      echo "Attempt $attempt failed, retrying in ${delay_ms}ms..." >&2
      sleep $(bc <<< "scale=3; $delay_ms / 1000") 2>/dev/null || sleep 1
      delay_ms=$((delay_ms * 2))
      attempt=$((attempt + 1))
    else
      echo "All $max_attempts attempts failed" >&2
      return 1
    fi
  done
}
```

**Current Usage**: Available in library but **not applied to LLM classification** currently. Only used in other contexts (agent invocations, file operations).

### User Experience Analysis

#### Offline Development Scenario

**Current Flow**:
1. Developer works offline (no network)
2. Runs `/coordinate "research authentication patterns"`
3. Network check fails fast (1 second timeout)
4. sm_init returns error (workflow-state-machine.sh:383)
5. /coordinate calls handle_state_error (coordinate.md:170)
6. User sees comprehensive error message with suggestion to use `WORKFLOW_CLASSIFICATION_MODE=regex-only`
7. User must:
   - Export environment variable in shell: `export WORKFLOW_CLASSIFICATION_MODE=regex-only`
   - Re-run entire command: `/coordinate "research authentication patterns"`
8. Second attempt succeeds using regex-only classification

**Pain Points**:
- Two-step manual recovery process
- Environment variable setup required
- No automatic retry or fallback
- User must understand environment variable system
- Error message is comprehensive but user must take external action

#### Transient Network Failure Scenario

**Current Flow**:
1. Network temporarily unavailable (WiFi drops, VPN disconnect)
2. /coordinate fails immediately on first attempt
3. Network recovers 5 seconds later
4. User must manually retry entire command
5. No automatic retry despite transient nature

**Missing Capability**: No distinction between permanent offline (no network hardware) and transient failures (temporary network interruption).

### Comparison with Spec 057 Verification Fallback Pattern

**Location**: `.claude/CHANGELOG.md:14` (recent addition)

A verification fallback pattern was recently added to `reconstruct_report_paths_array()`:

```bash
# workflow-initialization.sh:374-392
reconstruct_report_paths_array() {
  # Primary: Load from state persistence
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
  fi

  # Verification fallback: Filesystem discovery if state missing
  if [ ${#REPORT_PATHS[@]} -eq 0 ] && [ -d "$REPORTS_DIR" ]; then
    echo "WARNING: State persistence failure, using filesystem fallback" >&2
    mapfile -t REPORT_PATHS < <(find "$REPORTS_DIR" -name "*.md" | sort)
  fi
}
```

**Pattern Characteristics**:
- Primary approach: Use persisted state (fast, reliable)
- Verification checkpoint: Check if primary succeeded
- Fallback: Filesystem discovery (slower but functional)
- Immediate detection: Warns user of state persistence failure
- Graceful degradation: Workflow continues with discovered paths

**Applicability to LLM Classification**:
- Primary: LLM-based classification (accurate, semantic)
- Verification checkpoint: Check for network/API errors
- Fallback: Regex-based classification (functional, offline)
- Detection: Warn about fallback usage
- Graceful degradation: Workflow continues with regex results

**Spec 057 Taxonomy**: This is a "verification fallback" (detect tool/agent failures immediately, provide diagnostic fallback) vs "bootstrap fallback" (hide configuration errors silently) - verification fallbacks are REQUIRED per Spec 057.

## Recommendations

### 1. Implement Automatic Fallback to Regex-Only Mode

**Rationale**: Spec 057 verification fallback pattern demonstrates successful graceful degradation. Applying the same pattern to LLM classification would eliminate manual environment variable configuration while maintaining fail-fast detection of actual problems.

**Implementation**:

```bash
# In classify_workflow_comprehensive (workflow-scope-detection.sh)
classify_workflow_comprehensive() {
  local workflow_description="$1"

  case "$WORKFLOW_CLASSIFICATION_MODE" in
    llm-only)
      local llm_result
      if ! llm_result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
        # NEW: Automatic fallback instead of immediate failure
        echo "WARNING: LLM classification failed, falling back to regex-only mode" >&2
        echo "  Reason: $(classify_llm_error_reason)" >&2
        echo "  Fallback: Using regex-based classification" >&2

        # Attempt regex fallback
        if regex_result=$(classify_workflow_regex_comprehensive "$workflow_description"); then
          echo "  Success: Regex classification completed" >&2
          echo "$regex_result"
          return 0
        else
          # Both methods failed - fail fast
          echo "ERROR: Both LLM and regex classification failed" >&2
          return 1
        fi
      fi
      echo "$llm_result"
      return 0
      ;;

    regex-only)
      # Existing regex-only path (unchanged)
      ;;
  esac
}
```

**Benefits**:
- Eliminates two-step manual recovery for offline scenarios
- Maintains fail-fast for genuine errors (both methods fail)
- Provides visibility into fallback usage via warnings
- Preserves user's explicit mode choice (regex-only still works)

**Trade-offs**:
- Adds ~100-200ms latency for offline attempts (network check + regex execution)
- May mask network configuration issues if fallback always succeeds
- Deviates from clean-break philosophy (reintroduces limited automatic fallback)

### 2. Add Retry Logic for Transient LLM Failures

**Rationale**: Network timeouts and temporary API unavailability are transient errors that often resolve within seconds. The existing `retry_with_backoff()` function (error-handling.sh:243-273) provides infrastructure but is not applied to LLM classification.

**Implementation**:

```bash
# In invoke_llm_classifier (workflow-llm-classifier.sh)
invoke_llm_classifier() {
  local llm_input="$1"

  # NEW: Retry wrapper for transient failures
  local max_retries=2
  local retry_count=0

  while [ $retry_count -le $max_retries ]; do
    # Pre-flight check
    if ! check_network_connectivity; then
      if [ $retry_count -lt $max_retries ]; then
        echo "WARNING: Network check failed, retry $((retry_count+1))/$max_retries in 2s" >&2
        sleep 2
        retry_count=$((retry_count+1))
        continue
      else
        # Max retries exhausted - fail or fallback
        echo "ERROR: Network unavailable after $max_retries retries" >&2
        return 1
      fi
    fi

    # Existing LLM invocation logic (timeout, file-based signaling)
    # ...

    # Check if error is transient
    if [ $? -ne 0 ]; then
      local error_type=$(classify_error "$error_message")
      if [ "$error_type" = "transient" ] && [ $retry_count -lt $max_retries ]; then
        echo "WARNING: Transient error detected, retry $((retry_count+1))/$max_retries" >&2
        sleep $((2 ** retry_count))  # Exponential backoff: 1s, 2s, 4s
        retry_count=$((retry_count+1))
        continue
      else
        return 1
      fi
    fi

    # Success
    return 0
  done

  return 1
}
```

**Benefits**:
- Handles transient network interruptions automatically
- Reduces false-positive offline detection
- Provides user feedback during retry attempts
- Uses existing error classification infrastructure

**Trade-offs**:
- Adds latency for genuine offline scenarios (up to 7 seconds: 1s + 2s + 4s)
- Increases complexity of invoke_llm_classifier function
- May delay user awareness of persistent network issues

### 3. Enhance sm_init Error Handling with Structured Error Types

**Rationale**: The existing `handle_llm_classification_failure()` function (workflow-llm-classifier.sh:479-535) provides structured error handling but is unused. sm_init currently duplicates this logic inline (workflow-state-machine.sh:372-383).

**Implementation**:

```bash
# In sm_init (workflow-state-machine.sh)
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Attempt classification
  local classification_result
  if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>&1); then
    # Success path (unchanged)
    WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
    export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  else
    # NEW: Use structured error handling
    local error_type=$(detect_llm_error_type "$classification_result")

    handle_llm_classification_failure \
      "$error_type" \
      "$classification_result" \
      "$workflow_desc"

    return 1
  fi
}
```

**Benefits**:
- Eliminates code duplication
- Provides consistent error messaging across codebase
- Enables error-type-specific guidance
- Leverages existing error handling infrastructure

### 4. Improve Offline Detection with Progressive Checks

**Rationale**: Current network check is binary (online/offline). Progressive checks could distinguish between no network hardware, local network only, and internet connectivity issues.

**Implementation**:

```bash
# Enhanced check_network_connectivity (workflow-llm-classifier.sh)
check_network_connectivity() {
  if [ "${WORKFLOW_CLASSIFICATION_MODE:-}" = "regex-only" ]; then
    return 0
  fi

  # Level 1: Check if network interface exists
  if ! command -v ip >/dev/null 2>&1 || \
     [ -z "$(ip link show up | grep -v LOOPBACK)" ]; then
    echo "ERROR: No active network interfaces detected" >&2
    echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work" >&2
    return 1
  fi

  # Level 2: Check local network (gateway reachable)
  local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
  if [ -n "$gateway" ]; then
    if ! timeout 1 ping -c 1 "$gateway" >/dev/null 2>&1; then
      echo "WARNING: Local network unreachable (gateway: $gateway)" >&2
      echo "  Suggestion: Check WiFi/Ethernet connection" >&2
      return 1
    fi
  fi

  # Level 3: Check internet connectivity (DNS + external)
  if ! timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "WARNING: Internet connectivity unavailable" >&2
    echo "  Suggestion: Check firewall, VPN, or use regex-only mode" >&2
    return 1
  fi

  # Level 4: Check DNS resolution
  if ! timeout 1 ping -c 1 google.com >/dev/null 2>&1; then
    echo "WARNING: DNS resolution failed" >&2
    echo "  Suggestion: Check DNS configuration" >&2
    return 1
  fi

  return 0
}
```

**Benefits**:
- More precise error messages (specific failure point)
- Helps users diagnose network configuration issues
- Distinguishes hardware problems from configuration issues
- Enables smarter retry decisions (skip retries for no hardware)

**Trade-offs**:
- Increases latency for offline scenarios (multiple check attempts)
- Requires additional system utilities (ip command)
- More complex maintenance

### 5. Add User-Friendly Mode Selection Helper

**Rationale**: Users may not know about WORKFLOW_CLASSIFICATION_MODE or how to set it. A helper command could simplify mode selection.

**Implementation**:

```bash
# New function: /coordinate --set-mode <mode>
# In coordinate.md (new bash block before Part 1)

# Check for --set-mode flag
if [ "${1:-}" = "--set-mode" ]; then
  local requested_mode="${2:-}"

  case "$requested_mode" in
    llm-only|online)
      echo "export WORKFLOW_CLASSIFICATION_MODE=llm-only" >> ~/.bashrc
      echo "✓ Set classification mode to: llm-only (requires network)" >&2
      echo "  Mode will persist across terminal sessions" >&2
      echo "  Reload shell: source ~/.bashrc" >&2
      exit 0
      ;;
    regex-only|offline)
      echo "export WORKFLOW_CLASSIFICATION_MODE=regex-only" >> ~/.bashrc
      echo "✓ Set classification mode to: regex-only (works offline)" >&2
      echo "  Mode will persist across terminal sessions" >&2
      echo "  Reload shell: source ~/.bashrc" >&2
      exit 0
      ;;
    *)
      echo "ERROR: Invalid mode '$requested_mode'" >&2
      echo "  Valid modes: llm-only, online, regex-only, offline" >&2
      echo "  Usage: /coordinate --set-mode <mode>" >&2
      exit 1
      ;;
  esac
fi
```

**Benefits**:
- Simplifies user configuration
- Provides mode persistence across sessions
- Reduces cognitive load (no environment variable knowledge required)
- Discoverable via --help flag

## References

**Codebase Files Analyzed**:
- `.claude/commands/coordinate.md:1-2121` - Main orchestration command with sm_init integration
- `.claude/lib/workflow-state-machine.sh:337-391` - sm_init function with classification error handling
- `.claude/lib/workflow-scope-detection.sh:30-99` - Two-mode routing and clean-break design
- `.claude/lib/workflow-llm-classifier.sh:1-595` - LLM classification implementation and error handling
- `.claude/lib/error-handling.sh:1-882` - Error classification, retry logic, and structured error handling
- `.claude/CHANGELOG.md:14` - Recent verification fallback pattern (Spec 057)

**Relevant Patterns**:
- Verification Fallback Pattern (Spec 057): `.claude/specs/057_*/` - Taxonomy of fallback types
- Fail-Fast Policy Analysis: `.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md`
- Bash Block Execution Model: `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation constraints

**External Resources**:
- Claude Haiku 4.5 API documentation (inference timeout recommendations)
- Bash retry pattern best practices (exponential backoff algorithms)
- Network connectivity detection patterns (progressive check strategies)
