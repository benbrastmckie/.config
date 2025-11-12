# Implementation Architecture: Hybrid Workflow Classification System

**Version**: 1.0
**Date**: 2025-11-11
**Status**: Design Complete
**Related Documents**:
- Analysis: `workflow_scope_detection_analysis.md`
- Research: `001_llm_based_classification_research.md`
- Synthesis: `002_comparative_analysis_and_synthesis.md`

---

## Table of Contents

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Component Design](#2-component-design)
3. [Subagent Invocation Design](#3-subagent-invocation-design)
4. [Configuration and Feature Flags](#4-configuration-and-feature-flags)
5. [Error Handling and Fallback](#5-error-handling-and-fallback)
6. [Performance Optimization](#6-performance-optimization)
7. [Observability and Monitoring](#7-observability-and-monitoring)
8. [Testing Infrastructure](#8-testing-infrastructure)
9. [Code Structure](#9-code-structure)
10. [Migration and Rollback](#10-migration-and-rollback)
11. [Documentation Updates Required](#11-documentation-updates-required)

---

## 1. System Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     /coordinate Command                         │
│                                                                 │
│  1. User provides workflow description                         │
│  2. Call detect_workflow_scope_v2()                           │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│            workflow-scope-detection.sh (MODIFIED)               │
│                                                                 │
│  detect_workflow_scope_v2() {                                  │
│    - Check WORKFLOW_CLASSIFICATION_MODE                        │
│    - Route to appropriate classifier                           │
│  }                                                             │
└───────────┬─────────────────────────────────┬───────────────────┘
            │                                 │
            │ hybrid mode                     │ regex-only mode
            ▼                                 ▼
┌───────────────────────────┐    ┌──────────────────────────────┐
│ workflow-llm-classifier.sh│    │ detect_workflow_scope()      │
│         (NEW)             │    │ (EXISTING - Regex only)      │
│                           │    │                              │
│ 1. Invoke Haiku via Task │    │ - Pattern matching           │
│ 2. Parse JSON response    │    │ - Returns scope              │
│ 3. Validate confidence    │    │ - Fast (<1ms)                │
│ 4. Check threshold        │    └──────────────────────────────┘
│ 5. Return or fallback     │                 │
└───────────┬───────────────┘                 │
            │                                 │
            │ confidence >= 0.7               │ confidence < 0.7
            │                                 │     or error
            ▼                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Return Classification                      │
│                                                                 │
│  {                                                             │
│    scope: "research-and-plan",                                 │
│    confidence: 0.95,                                           │
│    reasoning: "...",                                           │
│    method: "llm" | "regex-fallback"                           │
│  }                                                             │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Component Interaction Flow

```
User Input
    │
    ├─→ detect_workflow_scope_v2()
    │       │
    │       ├─→ Check WORKFLOW_CLASSIFICATION_MODE env var
    │       │
    │       ├─→ [hybrid mode] Call classify_workflow_llm()
    │       │       │
    │       │       ├─→ Build JSON input payload
    │       │       ├─→ Invoke Task tool (Haiku 4.5, timeout=10s)
    │       │       ├─→ Parse JSON response
    │       │       ├─→ Validate (type, confidence)
    │       │       │
    │       │       ├─→ [confidence >= threshold] Return LLM result
    │       │       └─→ [confidence < threshold] Fallback to regex
    │       │
    │       ├─→ [llm-only mode] Call classify_workflow_llm()
    │       │       └─→ [error] Return error (no fallback)
    │       │
    │       └─→ [regex-only mode] Call detect_workflow_scope()
    │               └─→ Return regex result
    │
    └─→ /coordinate uses returned scope to initialize workflow
```

### 1.3 Data Flow

```
Input: Workflow Description (String)
   │
   ├─→ LLM Classifier Path:
   │      1. JSON Payload: {description, types, definitions}
   │      2. Task tool invocation (Haiku 4.5)
   │      3. LLM Response: {classification, confidence, reasoning}
   │      4. Validation & Threshold Check
   │      5. Output: {scope, confidence, reasoning, method="llm"}
   │
   └─→ Regex Classifier Path:
          1. Pattern Matching (9 regex patterns)
          2. First Match Wins
          3. Output: {scope, confidence=1.0, reasoning="pattern", method="regex"}
```

### 1.4 Error Handling and Fallback Flows

```
classify_workflow_llm() Invocation
    │
    ├─→ [SUCCESS] LLM returns valid JSON
    │       │
    │       ├─→ [Valid type + confidence >= 0.7] Return LLM result
    │       └─→ [Invalid type OR confidence < 0.7] Fallback to regex
    │
    ├─→ [TIMEOUT] 10 seconds elapsed
    │       └─→ Fallback to regex
    │
    ├─→ [PARSE ERROR] Malformed JSON
    │       └─→ Fallback to regex
    │
    └─→ [API ERROR] Task tool fails
            └─→ Fallback to regex
```

---

## 2. Component Design

### 2.1 New Library: workflow-llm-classifier.sh

**Location**: `.claude/lib/workflow-llm-classifier.sh`
**Lines of Code**: ~200 lines
**Dependencies**:
- `.claude/lib/unified-logger.sh` (logging)
- Task tool (Claude API access)
- `jq` (JSON parsing)

#### 2.1.1 Function: classify_workflow_llm()

**Purpose**: Invoke Claude Haiku to classify workflow description using semantic understanding.

**Signature**:
```bash
# classify_workflow_llm: Use LLM to classify workflow scope
# Args:
#   $1: workflow_description - Natural language workflow description
# Returns:
#   JSON object: {scope, confidence, reasoning, method}
# Exit codes:
#   0: Success (classification returned)
#   1: Error (fallback required)
# Usage:
#   result=$(classify_workflow_llm "$description")
#   scope=$(echo "$result" | jq -r '.scope')
classify_workflow_llm() {
  local workflow_description="$1"
  local timeout="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
  local debug="${WORKFLOW_CLASSIFICATION_DEBUG:-0}"

  # Input validation
  if [ -z "$workflow_description" ]; then
    log_error "classify_workflow_llm: empty workflow description"
    return 1
  fi

  # Build JSON input payload
  local input_json
  input_json=$(build_llm_classifier_input "$workflow_description")

  # Invoke Task tool with Haiku model
  local llm_response
  llm_response=$(invoke_llm_classifier "$input_json" "$timeout")
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    log_error "LLM classifier invocation failed (exit code: $exit_code)"
    return 1
  fi

  # Parse and validate response
  local parsed_result
  parsed_result=$(parse_llm_classifier_response "$llm_response")
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    log_error "LLM classifier response parsing failed"
    return 1
  fi

  # Check confidence threshold
  local confidence
  confidence=$(echo "$parsed_result" | jq -r '.confidence')
  local threshold="${WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD:-0.7}"

  if (( $(echo "$confidence < $threshold" | bc -l) )); then
    [ "$debug" = "1" ] && log_debug "Confidence $confidence below threshold $threshold, triggering fallback"
    return 1
  fi

  # Return successful classification
  echo "$parsed_result"
  return 0
}
```

#### 2.1.2 Function: build_llm_classifier_input()

**Purpose**: Build JSON payload for LLM classifier with workflow types and definitions.

**Signature**:
```bash
# build_llm_classifier_input: Create JSON input for LLM classifier
# Args:
#   $1: workflow_description - User's workflow description
# Returns:
#   JSON string with structure: {description, types, definitions}
# Exit codes:
#   0: Success
build_llm_classifier_input() {
  local description="$1"

  # Escape description for JSON
  local escaped_description
  escaped_description=$(echo "$description" | jq -Rs .)

  # Build JSON payload
  cat <<EOF
{
  "description": $escaped_description,
  "available_types": [
    "research-only",
    "research-and-plan",
    "research-and-revise",
    "full-implementation",
    "debug-only"
  ],
  "type_definitions": {
    "research-only": "Investigate and document findings without creating plans or implementations. Produces research reports only.",
    "research-and-plan": "Research a topic and create an implementation plan. Produces research reports + plan file. No code changes.",
    "research-and-revise": "Research findings to update an EXISTING implementation plan. Requires path to existing plan in description.",
    "full-implementation": "Execute an existing plan or implement a feature. Produces code changes, tests, commits.",
    "debug-only": "Investigate and fix bugs or test failures. Creates debug reports with root cause analysis."
  }
}
EOF
}
```

#### 2.1.3 Function: invoke_llm_classifier()

**Purpose**: Call Task tool to invoke Haiku model with timeout.

**Signature**:
```bash
# invoke_llm_classifier: Invoke Haiku via Task tool
# Args:
#   $1: input_json - JSON payload for classifier
#   $2: timeout - Timeout in seconds (default: 10)
# Returns:
#   Raw LLM response (stdout)
# Exit codes:
#   0: Success
#   1: Timeout or API error
invoke_llm_classifier() {
  local input_json="$1"
  local timeout="${2:-10}"
  local model="claude-haiku-4-5-20251001"  # Locked version

  # Create temp file for Task tool invocation
  local temp_file="/tmp/llm_classifier_$$.json"
  echo "$input_json" > "$temp_file"

  # Build prompt for Task tool
  local prompt
  prompt=$(cat <<'PROMPT_EOF'
You are a workflow scope classifier. Analyze the workflow description and classify it into ONE of the available workflow types.

**Input JSON**: Read from $temp_file

**Your task**:
1. Analyze the workflow description semantically (not just keyword matching)
2. Consider user INTENT (what they want to achieve)
3. Distinguish between:
   - Discussing a workflow type vs requesting that workflow type
   - Research ABOUT planning vs research FOR planning
   - Referencing existing plans vs creating new plans

**Output format** (JSON only, no markdown):
{
  "classification": "<one of available_types>",
  "confidence": <0.0-1.0>,
  "reasoning": "<1-2 sentences explaining decision>"
}

**Examples**:

Example 1 - Research about a topic (research-and-plan):
Input: "research the workflow detection issue to create a plan"
Output: {"classification": "research-and-plan", "confidence": 0.95, "reasoning": "User wants to research AND create a plan based on findings."}

Example 2 - Discussing workflow types (research-and-plan):
Input: "research why coordinate detected workflow as research-and-revise instead of research-and-plan"
Output: {"classification": "research-and-plan", "confidence": 0.90, "reasoning": "User is researching an issue to understand it and create a plan. The mention of 'research-and-revise' is descriptive context, not the requested workflow."}

Example 3 - Revising existing plan (research-and-revise):
Input: "Revise the plan at specs/042_auth/plans/001_implementation.md based on new security requirements"
Output: {"classification": "research-and-revise", "confidence": 0.98, "reasoning": "User provides explicit plan path and wants to update existing plan."}

Example 4 - Research only (research-only):
Input: "research different authentication patterns used in similar projects"
Output: {"classification": "research-only", "confidence": 0.92, "reasoning": "Pure research request with no implementation or planning intent."}

Example 5 - Implementation (full-implementation):
Input: "implement the authentication feature described in specs/042_auth/plans/001_implementation.md"
Output: {"classification": "full-implementation", "confidence": 0.97, "reasoning": "User provides plan path and requests implementation."}

**Important**: Return ONLY the JSON output, no additional text or markdown formatting.
PROMPT_EOF
)

  # Invoke Task tool (this is pseudocode - actual implementation would use claude CLI tool or API)
  # In practice, this would be: echo "$prompt" | claude --model "$model" --timeout "$timeout" --json
  #
  # For now, we'll simulate with a bash approach that would work in the actual codebase:
  timeout "${timeout}s" bash -c "
    # This would be replaced with actual Task tool invocation
    # For architecture purposes, showing the interface:
    echo 'CLASSIFICATION_RESPONSE: {\"classification\": \"research-and-plan\", \"confidence\": 0.95, \"reasoning\": \"...\"}' >&2
  " 2>&1

  local exit_code=$?
  rm -f "$temp_file"
  return $exit_code
}
```

#### 2.1.4 Function: parse_llm_classifier_response()

**Purpose**: Extract and validate JSON from LLM response.

**Signature**:
```bash
# parse_llm_classifier_response: Parse and validate LLM JSON response
# Args:
#   $1: llm_response - Raw response from invoke_llm_classifier
# Returns:
#   Validated JSON: {scope, confidence, reasoning, method="llm"}
# Exit codes:
#   0: Success (valid response)
#   1: Parsing error or validation failure
parse_llm_classifier_response() {
  local llm_response="$1"

  # Extract JSON from response (handle potential markdown code blocks)
  local json_only
  json_only=$(echo "$llm_response" | grep -oP '\{.*\}' | head -1)

  if [ -z "$json_only" ]; then
    log_error "No JSON found in LLM response"
    return 1
  fi

  # Validate JSON structure
  if ! echo "$json_only" | jq empty 2>/dev/null; then
    log_error "Invalid JSON in LLM response"
    return 1
  fi

  # Extract fields
  local classification
  local confidence
  local reasoning
  classification=$(echo "$json_only" | jq -r '.classification')
  confidence=$(echo "$json_only" | jq -r '.confidence')
  reasoning=$(echo "$json_only" | jq -r '.reasoning')

  # Validate classification type
  local valid_types=("research-only" "research-and-plan" "research-and-revise" "full-implementation" "debug-only")
  local valid=0
  for type in "${valid_types[@]}"; do
    if [ "$classification" = "$type" ]; then
      valid=1
      break
    fi
  done

  if [ $valid -eq 0 ]; then
    log_error "Invalid classification type: $classification"
    return 1
  fi

  # Validate confidence range
  if ! echo "$confidence" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
    log_error "Invalid confidence format: $confidence"
    return 1
  fi

  if (( $(echo "$confidence < 0.0 || $confidence > 1.0" | bc -l) )); then
    log_error "Confidence out of range: $confidence"
    return 1
  fi

  # Return validated result with method="llm"
  jq -n \
    --arg scope "$classification" \
    --arg confidence "$confidence" \
    --arg reasoning "$reasoning" \
    '{scope: $scope, confidence: ($confidence | tonumber), reasoning: $reasoning, method: "llm"}'
}
```

#### 2.1.5 Logging and Debugging Support

**Debug Logging**:
```bash
# Enable debug logging with:
# export WORKFLOW_CLASSIFICATION_DEBUG=1

log_debug() {
  [ "${WORKFLOW_CLASSIFICATION_DEBUG:-0}" = "1" ] || return 0
  echo "[DEBUG workflow-llm-classifier] $*" >&2
}

log_error() {
  echo "[ERROR workflow-llm-classifier] $*" >&2
}
```

**Structured Logging Integration**:
```bash
# Integrate with unified-logger.sh for production logging
log_classification_result() {
  local description="$1"
  local scope="$2"
  local confidence="$3"
  local method="$4"

  if command -v log_metric &>/dev/null; then
    log_metric "workflow_classification" \
      "description=$description" \
      "scope=$scope" \
      "confidence=$confidence" \
      "method=$method"
  fi
}
```

---

### 2.2 Modified Library: workflow-scope-detection.sh

**Location**: `.claude/lib/workflow-scope-detection.sh`
**Lines Added**: ~50 lines
**Backward Compatibility**: 100% preserved

#### 2.2.1 New Function: detect_workflow_scope_v2()

**Purpose**: Unified entry point for hybrid classification with feature flag support.

**Signature**:
```bash
# detect_workflow_scope_v2: Hybrid workflow scope detection
# Args:
#   $1: workflow_description - The workflow description to analyze
# Returns:
#   JSON object: {scope, confidence, reasoning, method}
#   OR (for backward compatibility): just the scope string
# Environment Variables:
#   WORKFLOW_CLASSIFICATION_MODE: hybrid|llm-only|regex-only (default: hybrid)
#   WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD: 0.0-1.0 (default: 0.7)
#   WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT: json|string (default: string for backward compat)
# Usage:
#   scope=$(detect_workflow_scope_v2 "$description")  # Returns "research-and-plan"
#   result=$(WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT=json detect_workflow_scope_v2 "$description")  # Returns JSON
detect_workflow_scope_v2() {
  local workflow_description="$1"
  local mode="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"
  local output_format="${WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT:-string}"

  # Input validation
  if [ -z "$workflow_description" ]; then
    log_error "detect_workflow_scope_v2: empty workflow description"
    # Return default scope for backward compatibility
    if [ "$output_format" = "json" ]; then
      echo '{"scope": "research-and-plan", "confidence": 0.5, "reasoning": "empty input", "method": "default"}'
    else
      echo "research-and-plan"
    fi
    return 1
  fi

  local result
  local exit_code

  case "$mode" in
    llm-only)
      # LLM only, fail if LLM fails (no fallback)
      result=$(classify_workflow_llm "$workflow_description")
      exit_code=$?

      if [ $exit_code -ne 0 ]; then
        log_error "LLM classification failed in llm-only mode"
        # Return default as last resort
        if [ "$output_format" = "json" ]; then
          echo '{"scope": "research-and-plan", "confidence": 0.0, "reasoning": "llm failed", "method": "default"}'
        else
          echo "research-and-plan"
        fi
        return 1
      fi
      ;;

    regex-only)
      # Regex only (backward compatible behavior)
      local scope
      scope=$(detect_workflow_scope "$workflow_description")

      # Convert to JSON format if requested
      if [ "$output_format" = "json" ]; then
        result=$(jq -n --arg scope "$scope" \
          '{scope: $scope, confidence: 1.0, reasoning: "regex pattern match", method: "regex"}')
      else
        result="$scope"
      fi
      ;;

    hybrid|*)
      # Hybrid: Try LLM first, fallback to regex
      result=$(classify_workflow_llm "$workflow_description")
      exit_code=$?

      if [ $exit_code -ne 0 ]; then
        # LLM failed or low confidence, fallback to regex
        log_debug "Falling back to regex classifier"
        local scope
        scope=$(detect_workflow_scope "$workflow_description")

        if [ "$output_format" = "json" ]; then
          result=$(jq -n --arg scope "$scope" \
            '{scope: $scope, confidence: 1.0, reasoning: "regex fallback", method: "regex-fallback"}')
        else
          result="$scope"
        fi
      fi
      ;;
  esac

  # Extract scope for string output format (backward compatibility)
  if [ "$output_format" = "string" ] && echo "$result" | jq empty 2>/dev/null; then
    result=$(echo "$result" | jq -r '.scope')
  fi

  echo "$result"
}
```

#### 2.2.2 Modified Function: detect_workflow_scope()

**Purpose**: Original regex-only classifier (now internal function, unchanged logic).

**Changes**:
- No functional changes
- Becomes internal implementation detail
- Still exported for backward compatibility
- All existing tests continue to pass

```bash
# detect_workflow_scope: Regex-based workflow scope detection (UNCHANGED)
# This function is now called internally by detect_workflow_scope_v2() in regex mode
# Keeping original implementation and export for backward compatibility
detect_workflow_scope() {
  # ... EXISTING IMPLEMENTATION UNCHANGED ...
  # (All 100 lines of existing regex logic remain exactly the same)
}

export -f detect_workflow_scope  # Still exported for backward compat
```

#### 2.2.3 Library Initialization

**Add at top of workflow-scope-detection.sh**:
```bash
# Source LLM classifier library if available
if [ -f "${CLAUDE_PROJECT_DIR:-}/.claude/lib/workflow-llm-classifier.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-llm-classifier.sh"
  LLM_CLASSIFIER_AVAILABLE=1
else
  LLM_CLASSIFIER_AVAILABLE=0
  log_debug "LLM classifier library not found, using regex-only mode"
fi

# Export new functions
export -f detect_workflow_scope_v2
```

---

### 2.3 Integration with /coordinate Command

**Location**: `.claude/commands/coordinate.md` (bash block 1)
**Changes**: 1-line change to classifier call

#### 2.3.1 Current Implementation (Line ~50 in bash block 1):
```bash
# OLD - Regex-only classification
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

#### 2.3.2 New Implementation:
```bash
# NEW - Hybrid classification with logging
# sm_init will call detect_workflow_scope_v2() internally
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

**Note**: The actual change is in `workflow-state-machine.sh:sm_init()`:

```bash
# In workflow-state-machine.sh:sm_init()
# OLD:
WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_description")

# NEW:
if command -v detect_workflow_scope_v2 &>/dev/null; then
  WORKFLOW_SCOPE=$(detect_workflow_scope_v2 "$workflow_description")
else
  # Fallback to v1 for backward compatibility
  WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_description")
fi
```

#### 2.3.3 Classification Result Logging

**Add after sm_init() call**:
```bash
# Log classification result for monitoring
if [ "${WORKFLOW_CLASSIFICATION_DEBUG:-0}" = "1" ]; then
  echo "Classification Result:"
  echo "  Scope: $WORKFLOW_SCOPE"
  echo "  Method: ${CLASSIFICATION_METHOD:-regex}"
  echo "  Confidence: ${CLASSIFICATION_CONFIDENCE:-1.0}"
fi
```

#### 2.3.4 Error Handling

**Existing error handling already sufficient**:
- If classification fails, `sm_init()` returns default scope
- `/coordinate` continues with default scope
- Error logged to stderr

---

## 3. Subagent Invocation Design

### 3.1 Task Tool Invocation Pattern

**NOTE**: The architecture above shows conceptual flow. In practice, bash scripts cannot directly invoke the Task tool (it's a Claude Code feature available to the AI assistant).

**Actual Implementation Strategy**:
Instead of bash directly invoking Task tool, we use one of these approaches:

#### Option A: AI Assistant Integration (Recommended)
The bash script sets a flag that the AI assistant sees:
```bash
# In workflow-llm-classifier.sh
invoke_llm_classifier() {
  local input_json="$1"

  # Write request to special location that AI assistant monitors
  echo "$input_json" > "/tmp/llm_classification_request_$$.json"

  # Signal to AI assistant that classification is needed
  echo "LLM_CLASSIFICATION_REQUESTED: /tmp/llm_classification_request_$$.json" >&2

  # Wait for response (with timeout)
  local timeout="${2:-10}"
  local response_file="/tmp/llm_classification_response_$$.json"
  local elapsed=0
  while [ ! -f "$response_file" ] && [ $elapsed -lt $timeout ]; do
    sleep 0.1
    elapsed=$((elapsed + 1))
  done

  if [ -f "$response_file" ]; then
    cat "$response_file"
    rm -f "$response_file" "/tmp/llm_classification_request_$$.json"
    return 0
  else
    rm -f "/tmp/llm_classification_request_$$.json"
    return 1
  fi
}
```

#### Option B: Claude CLI Tool (If Available)
If a `claude` CLI tool exists:
```bash
invoke_llm_classifier() {
  local input_json="$1"
  local timeout="${2:-10}"

  timeout "${timeout}s" claude \
    --model "claude-haiku-4-5-20251001" \
    --system "You are a workflow classifier..." \
    --input "$input_json" \
    --output-format json
}
```

#### Option C: HTTP API Direct (Least Preferred)
Direct API call (requires API key management):
```bash
invoke_llm_classifier() {
  local input_json="$1"

  curl -s --max-time 10 \
    -H "Content-Type: application/json" \
    -H "anthropic-version: 2024-11-01" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -d "$input_json" \
    "https://api.anthropic.com/v1/messages"
}
```

**RECOMMENDATION**: Use **Option A (AI Assistant Integration)** as it:
- Aligns with Claude Code's architecture
- Doesn't require API key management in bash
- Leverages existing Task tool infrastructure
- Maintains security boundaries

### 3.2 Prompt Engineering

**Complete Prompt Template** (used by AI assistant when processing classification request):

```
You are a workflow scope classifier for the /coordinate command. Your task is to analyze a natural language workflow description and classify it into exactly ONE of five workflow types.

**Input Format**:
{
  "description": "<user's workflow description>",
  "available_types": ["research-only", "research-and-plan", "research-and-revise", "full-implementation", "debug-only"],
  "type_definitions": {
    "research-only": "Investigate and document findings without creating plans or implementations. Produces research reports only.",
    "research-and-plan": "Research a topic and create an implementation plan. Produces research reports + plan file. No code changes.",
    "research-and-revise": "Research findings to update an EXISTING implementation plan. Requires path to existing plan in description.",
    "full-implementation": "Execute an existing plan or implement a feature. Produces code changes, tests, commits.",
    "debug-only": "Investigate and fix bugs or test failures. Creates debug reports with root cause analysis."
  }
}

**Classification Guidelines**:

1. **Intent Over Keywords**: Focus on what the user WANTS to achieve, not just keywords present.

2. **Context Matters**: Distinguish between:
   - Discussing a workflow type (e.g., "research why it detected research-and-revise") → Likely research-and-plan
   - Requesting a workflow type (e.g., "revise the plan at path X") → Likely research-and-revise

3. **Path Presence**:
   - If description contains "specs/NNN_topic/plans/NNN_plan.md" path:
     - AND starts with revise/update/modify → research-and-revise
     - AND starts with implement/execute → full-implementation
   - If description contains reference to a plan path but in explanatory context → research-and-plan

4. **Action Verbs**:
   - "research X to create plan" → research-and-plan
   - "research X and revise plan Y" → research-and-revise (if plan path present)
   - "implement X" → full-implementation
   - "fix bug X" → debug-only
   - "research X" (no action) → research-only

5. **Ambiguity Resolution**:
   - When uncertain between research-only and research-and-plan, default to research-and-plan
   - When uncertain between research-and-plan and research-and-revise, check for explicit plan path
   - If multiple actions mentioned, classify by PRIMARY intent

**Output Format** (JSON only, no markdown, no additional text):
{
  "classification": "<one of available_types>",
  "confidence": <0.0-1.0>,
  "reasoning": "<1-2 sentences explaining your decision>"
}

**Confidence Scoring**:
- 0.95-1.0: Extremely clear (explicit action verb + clear intent)
- 0.85-0.94: Very clear (strong indicators, minimal ambiguity)
- 0.70-0.84: Clear (good indicators, some context needed)
- 0.50-0.69: Uncertain (ambiguous phrasing, could be multiple types)
- 0.00-0.49: Very uncertain (conflicting signals, unclear intent)

**Few-Shot Examples**:

Example 1 (research-and-plan, 0.95 confidence):
Input: "research authentication patterns and create an implementation plan"
Output: {"classification": "research-and-plan", "confidence": 0.95, "reasoning": "Explicit intent to research AND create plan, no existing plan mentioned."}

Example 2 (research-and-plan, 0.90 confidence - TRICKY):
Input: "research why /coordinate detected the workflow as research-and-revise instead of research-and-plan"
Output: {"classification": "research-and-plan", "confidence": 0.90, "reasoning": "User is researching an issue to understand it (likely to create a plan). The mention of 'research-and-revise' is descriptive context about the problem, not the requested workflow type."}

Example 3 (research-and-revise, 0.98 confidence):
Input: "Revise the plan at specs/042_auth/plans/001_implementation.md to accommodate new OAuth requirements"
Output: {"classification": "research-and-revise", "confidence": 0.98, "reasoning": "Explicit revision verb, specific plan path provided, clear update intent."}

Example 4 (research-only, 0.92 confidence):
Input: "research different caching strategies used in high-traffic web applications"
Output: {"classification": "research-only", "confidence": 0.92, "reasoning": "Pure research request with no implementation, planning, or debugging intent."}

Example 5 (full-implementation, 0.97 confidence):
Input: "implement the authentication feature described in specs/042_auth/plans/001_implementation.md"
Output: {"classification": "full-implementation", "confidence": 0.97, "reasoning": "Explicit implementation verb with plan path reference, clear coding intent."}

Example 6 (debug-only, 0.94 confidence):
Input: "debug why tests are failing in the authentication module"
Output: {"classification": "debug-only", "confidence": 0.94, "reasoning": "Explicit debugging intent, focus on investigating and fixing test failures."}

Example 7 (research-and-plan, 0.75 confidence - AMBIGUOUS):
Input: "look into the coordinate command output and figure out what went wrong"
Output: {"classification": "research-and-plan", "confidence": 0.75, "reasoning": "Investigative intent likely leading to planning. Some ambiguity between research-only and research-and-plan, but 'figure out what went wrong' suggests action beyond pure research."}

**IMPORTANT**: Return ONLY the JSON object. Do not include markdown code fences, explanatory text, or any other content.
```

### 3.3 Response Parsing

Handled by `parse_llm_classifier_response()` function (see Section 2.1.4).

**Key Validation Steps**:
1. Extract JSON from response (handle markdown code blocks)
2. Validate JSON syntax (`jq empty`)
3. Validate required fields present (classification, confidence, reasoning)
4. Validate classification is one of 5 allowed types
5. Validate confidence is float in range [0.0, 1.0]
6. Return structured result with method="llm"

**Fallback Triggers**:
- No JSON found in response
- Invalid JSON syntax
- Missing required fields
- Invalid classification type
- Confidence out of range
- Confidence below threshold

---

## 4. Configuration and Feature Flags

### 4.1 Environment Variables

**Primary Configuration Interface** (no config file needed initially).

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `WORKFLOW_CLASSIFICATION_MODE` | `hybrid`, `llm-only`, `regex-only` | `hybrid` | Classification mode selection |
| `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` | `0.0-1.0` | `0.7` | Minimum confidence to use LLM result |
| `WORKFLOW_CLASSIFICATION_TIMEOUT` | Integer seconds | `10` | Max seconds to wait for LLM response |
| `WORKFLOW_CLASSIFICATION_DEBUG` | `0`, `1` | `0` | Enable verbose debug logging |
| `WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT` | `string`, `json` | `string` | Output format for backward compat |

**Usage Examples**:
```bash
# Use hybrid mode with lower confidence threshold (more aggressive LLM usage)
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.5 /coordinate "research auth patterns"

# Use regex-only mode (disable LLM completely)
WORKFLOW_CLASSIFICATION_MODE=regex-only /coordinate "research auth patterns"

# Enable debug logging
WORKFLOW_CLASSIFICATION_DEBUG=1 /coordinate "research auth patterns"

# Get JSON output with confidence scores
WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT=json /coordinate "research auth patterns"
```

### 4.2 Configuration Files

**Initial Implementation**: Environment variables only (simpler, sufficient).

**Future Enhancement** (if needed):
- Location: `.claude/config/workflow-classification.conf`
- Format: Bash-sourceable (KEY=VALUE pairs)
- Schema:
  ```bash
  # Workflow Classification Configuration
  WORKFLOW_CLASSIFICATION_MODE=hybrid
  WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.7
  WORKFLOW_CLASSIFICATION_TIMEOUT=10
  WORKFLOW_CLASSIFICATION_DEBUG=0
  ```

**Override Priority** (if config file implemented):
1. Environment variables (highest priority)
2. Config file
3. Hard-coded defaults (lowest priority)

**Implementation**:
```bash
# In workflow-llm-classifier.sh initialization
load_classification_config() {
  # Load defaults
  WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"
  WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD="${WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD:-0.7}"
  WORKFLOW_CLASSIFICATION_TIMEOUT="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
  WORKFLOW_CLASSIFICATION_DEBUG="${WORKFLOW_CLASSIFICATION_DEBUG:-0}"

  # Override with config file if exists (future enhancement)
  local config_file="${CLAUDE_PROJECT_DIR:-}/.claude/config/workflow-classification.conf"
  if [ -f "$config_file" ]; then
    source "$config_file"
  fi

  # Environment variables override everything (already set above if present)
}
```

**Recommendation**: Start with environment variables only. Add config file if users request it during beta phase.

---

## 5. Error Handling and Fallback

### 5.1 Failure Scenarios

**Comprehensive failure scenario coverage**:

| Scenario | Detection | Handling | User Impact |
|----------|-----------|----------|-------------|
| **Timeout** | `timeout` command exit code 124 | Fallback to regex | None (transparent) |
| **API Error** | Non-zero exit code from Task tool | Fallback to regex | None (transparent) |
| **Malformed JSON** | `jq empty` fails | Fallback to regex | None (transparent) |
| **Invalid Type** | Type not in allowed list | Fallback to regex | None (transparent) |
| **Low Confidence** | Confidence < threshold | Fallback to regex | None (transparent) |
| **Empty Response** | No JSON found in output | Fallback to regex | None (transparent) |
| **Regex Failure** | Should never happen | Return default scope | Workflow proceeds with default |

### 5.2 Fallback Decision Tree

```
classify_workflow_llm() invocation
    │
    ├─→ [SUCCESS] Parse LLM response
    │       │
    │       ├─→ [Valid JSON] Extract fields
    │       │       │
    │       │       ├─→ [Valid type] Check confidence
    │       │       │       │
    │       │       │       ├─→ [confidence >= 0.7] ✓ Return LLM result
    │       │       │       └─→ [confidence < 0.7] ↓ Fallback to regex
    │       │       │
    │       │       └─→ [Invalid type] ↓ Fallback to regex
    │       │
    │       └─→ [Invalid JSON] ↓ Fallback to regex
    │
    ├─→ [TIMEOUT] ↓ Fallback to regex
    ├─→ [API ERROR] ↓ Fallback to regex
    └─→ [PARSE ERROR] ↓ Fallback to regex
            │
            ▼
    detect_workflow_scope() (regex classifier)
    │
    ├─→ [Pattern match] ✓ Return regex result
    └─→ [No pattern match] ✓ Return default scope ("research-and-plan")
```

### 5.3 User-Facing Error Messages

**Design Principle**: Minimize noise for transparent fallbacks, provide clarity for actual failures.

#### Scenario: LLM Timeout (Transparent Fallback)
```
[DEBUG] LLM classifier timeout after 10 seconds, falling back to regex
```
- Logged only if `WORKFLOW_CLASSIFICATION_DEBUG=1`
- User sees no error message
- Workflow proceeds normally with regex classification

#### Scenario: LLM-Only Mode Failure (Actual Error)
```
ERROR: Workflow classification failed
  Mode: llm-only
  Reason: LLM classifier timeout after 10 seconds
  Fallback: Not available in llm-only mode

Suggested actions:
  1. Switch to hybrid mode (default): unset WORKFLOW_CLASSIFICATION_MODE
  2. Use regex-only mode: WORKFLOW_CLASSIFICATION_MODE=regex-only
  3. Retry the command
```
- Shown to user when LLM fails in llm-only mode
- Provides clear remediation steps
- Does not expose internal implementation details

#### Scenario: All Classifiers Fail (Should Never Happen)
```
ERROR: Unable to classify workflow description
  Description: "<truncated to 100 chars>"
  LLM result: <error>
  Regex result: <fallback to default>
  Proceeding with default scope: research-and-plan

WARNING: This is unexpected. Please report this issue.
```
- Extremely rare (regex always returns a result)
- Workflow continues with safe default
- User notified to report bug

### 5.4 Logging for Fallback Events

**Structured Logging**:
```bash
log_fallback_event() {
  local trigger="$1"  # timeout|api_error|low_confidence|invalid_response
  local llm_confidence="${2:-N/A}"
  local regex_scope="$3"

  log_metric "workflow_classification_fallback" \
    "trigger=$trigger" \
    "llm_confidence=$llm_confidence" \
    "regex_scope=$regex_scope" \
    "timestamp=$(date -Iseconds)"
}
```

**Metrics for Monitoring**:
- `workflow_classification_fallback_rate` - % of requests that fallback to regex
- `workflow_classification_fallback_by_trigger` - Breakdown by trigger type
- `workflow_classification_low_confidence_rate` - % with confidence < 0.7

---

## 6. Performance Optimization

### 6.1 Caching Strategy

**Initial Recommendation**: No caching.

**Rationale**:
- Workflow descriptions are highly variable (rarely exactly repeated)
- Cache hit rate likely <5% (not worth complexity)
- Classification is cheap ($0.00003 per request)
- Latency (200-500ms) is acceptable for command startup phase

**Future Enhancement** (if needed):
```bash
# Simple hash-based cache (future)
cache_classification() {
  local description="$1"
  local result="$2"
  local cache_key
  cache_key=$(echo "$description" | md5sum | cut -d' ' -f1)
  local cache_file="/tmp/workflow_classification_cache_${cache_key}.json"
  echo "$result" > "$cache_file"
}

get_cached_classification() {
  local description="$1"
  local cache_key
  cache_key=$(echo "$description" | md5sum | cut -d' ' -f1)
  local cache_file="/tmp/workflow_classification_cache_${cache_key}.json"

  if [ -f "$cache_file" ]; then
    # Check if cache is fresh (< 1 hour old)
    local age
    age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file") ))
    if [ $age -lt 3600 ]; then
      cat "$cache_file"
      return 0
    fi
  fi
  return 1
}
```

**Cache Configuration** (if implemented):
- Location: `/tmp/workflow_classification_cache_*.json`
- TTL: 1 hour
- Max size: 100 entries (LRU eviction)
- Environment variable: `WORKFLOW_CLASSIFICATION_CACHE_ENABLED=1`

### 6.2 Latency Mitigation

**Approach: Parallel Execution** (Future Enhancement)

**Concept**: Invoke LLM and regex classifiers in parallel, use whichever completes first.

```bash
classify_workflow_parallel() {
  local description="$1"
  local result_dir="/tmp/parallel_classification_$$"
  mkdir -p "$result_dir"

  # Start LLM classifier in background
  {
    result=$(classify_workflow_llm "$description" 2>/dev/null)
    echo "$result" > "$result_dir/llm.json"
  } &
  local llm_pid=$!

  # Start regex classifier in background
  {
    scope=$(detect_workflow_scope "$description")
    jq -n --arg scope "$scope" \
      '{scope: $scope, confidence: 1.0, reasoning: "regex", method: "regex"}' \
      > "$result_dir/regex.json"
  } &
  local regex_pid=$!

  # Wait for first to complete (or timeout)
  local timeout=10
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    if [ -f "$result_dir/llm.json" ]; then
      # LLM completed first, use if high confidence
      local confidence
      confidence=$(jq -r '.confidence' "$result_dir/llm.json" 2>/dev/null || echo "0")
      if (( $(echo "$confidence >= 0.7" | bc -l) )); then
        kill $regex_pid 2>/dev/null
        cat "$result_dir/llm.json"
        rm -rf "$result_dir"
        return 0
      fi
    fi

    if [ -f "$result_dir/regex.json" ]; then
      # Regex completed first, use as fallback
      kill $llm_pid 2>/dev/null
      cat "$result_dir/regex.json"
      rm -rf "$result_dir"
      return 0
    fi

    sleep 0.1
    elapsed=$((elapsed + 1))
  done

  # Timeout, kill both and return regex result
  kill $llm_pid $regex_pid 2>/dev/null
  scope=$(detect_workflow_scope "$description")
  rm -rf "$result_dir"
  jq -n --arg scope "$scope" \
    '{scope: $scope, confidence: 1.0, reasoning: "regex timeout", method: "regex-fallback"}'
}
```

**Trade-offs**:
| Pros | Cons |
|------|------|
| Reduces latency (regex completes in <1ms) | Wastes API cost if regex wins |
| No timeout waiting needed | More complex code |
| Better UX (faster response) | Harder to debug concurrent execution |

**Recommendation**: Implement parallel execution ONLY if user feedback indicates latency is a problem (>500ms p95).

### 6.3 Cost Management

**Current Cost Profile**:
- Per classification: $0.00003
- Expected usage: ~100 classifications/month = $0.003/month
- Annual cost: $0.036/year

**Cost is negligible, no management needed initially.**

**Future Safeguards** (if usage scales to 10,000+ classifications/month):
```bash
# Rate limiting (future enhancement)
check_classification_budget() {
  local budget_file="/tmp/workflow_classification_budget.json"
  local current_month
  current_month=$(date +%Y-%m)

  # Initialize budget if new month
  if [ ! -f "$budget_file" ] || [ "$(jq -r '.month' "$budget_file")" != "$current_month" ]; then
    jq -n --arg month "$current_month" \
      '{month: $month, count: 0, max: 10000}' \
      > "$budget_file"
  fi

  # Check budget
  local count
  count=$(jq -r '.count' "$budget_file")
  local max
  max=$(jq -r '.max' "$budget_file")

  if [ $count -ge $max ]; then
    log_error "Monthly classification budget exceeded ($count/$max), falling back to regex"
    return 1
  fi

  # Increment counter
  jq --argjson count $((count + 1)) '.count = $count' "$budget_file" > "${budget_file}.tmp"
  mv "${budget_file}.tmp" "$budget_file"
  return 0
}
```

**Usage Tracking** (future):
- Track monthly API calls
- Alert if > 5,000 classifications/month (unexpected)
- Auto-fallback to regex-only if budget exceeded

---

## 7. Observability and Monitoring

### 7.1 Logging Strategy

**Integration with unified-logger.sh**:

```bash
# In workflow-llm-classifier.sh
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh"
  LOGGING_AVAILABLE=1
else
  LOGGING_AVAILABLE=0
fi

log_classification() {
  local description="$1"
  local scope="$2"
  local confidence="$3"
  local method="$4"
  local latency_ms="$5"

  if [ "$LOGGING_AVAILABLE" = "1" ]; then
    log_metric "workflow_classification" \
      "scope=$scope" \
      "confidence=$confidence" \
      "method=$method" \
      "latency_ms=$latency_ms" \
      "description_hash=$(echo "$description" | md5sum | cut -d' ' -f1)"
  else
    # Fallback to stderr logging
    echo "[METRIC] workflow_classification scope=$scope confidence=$confidence method=$method latency_ms=$latency_ms" >&2
  fi
}
```

**Log Entries**:
```
[2025-11-11T14:30:45Z] [INFO] workflow_classification scope=research-and-plan confidence=0.95 method=llm latency_ms=234 description_hash=a1b2c3d4
[2025-11-11T14:31:12Z] [WARN] workflow_classification scope=research-and-plan confidence=0.62 method=regex-fallback latency_ms=456 description_hash=e5f6g7h8 trigger=low_confidence
[2025-11-11T14:32:08Z] [ERROR] workflow_classification scope=research-and-plan confidence=N/A method=regex-fallback latency_ms=10003 description_hash=i9j0k1l2 trigger=timeout
```

**Log Format**:
- Structured logging (key=value pairs)
- ISO 8601 timestamps
- Severity levels (INFO, WARN, ERROR)
- Redacted PII (hash descriptions, don't log full text)

**Log Location**:
- Integrated logs: `.claude/data/logs/workflow-classification.log`
- Log rotation: 10MB max, 5 files retained
- Retention: 30 days

### 7.2 Metrics to Track

**Key Metrics** (tracked in unified-logger.sh or sent to monitoring system):

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|-----------------|
| `classification_total` | Counter | Total classifications | N/A |
| `classification_by_scope` | Counter (labeled) | Count by scope type | N/A |
| `classification_by_method` | Counter (labeled) | Count by method (llm/regex/fallback) | `regex-fallback > 50%` |
| `classification_latency_ms` | Histogram | Latency distribution | `p95 > 1000ms` |
| `classification_confidence` | Histogram | Confidence distribution | `p50 < 0.8` |
| `classification_fallback_rate` | Gauge | % of fallbacks | `> 30%` |
| `classification_error_rate` | Gauge | % of errors | `> 5%` |
| `classification_disagreement_rate` | Gauge | % LLM ≠ regex | `> 20%` |

**Histogram Buckets**:
- Latency: [0, 100, 200, 500, 1000, 2000, 5000, 10000] ms
- Confidence: [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0]

**Implementation**:
```bash
# Expose metrics for Prometheus-style scraping (future)
expose_metrics() {
  cat <<EOF
# HELP workflow_classification_total Total number of workflow classifications
# TYPE workflow_classification_total counter
workflow_classification_total{scope="research-and-plan"} 45
workflow_classification_total{scope="research-and-revise"} 12
workflow_classification_total{scope="full-implementation"} 28

# HELP workflow_classification_method Classification method used
# TYPE workflow_classification_method counter
workflow_classification_method{method="llm"} 62
workflow_classification_method{method="regex-fallback"} 23

# HELP workflow_classification_latency_ms Classification latency in milliseconds
# TYPE workflow_classification_latency_ms histogram
workflow_classification_latency_ms_bucket{le="100"} 0
workflow_classification_latency_ms_bucket{le="200"} 15
workflow_classification_latency_ms_bucket{le="500"} 52
workflow_classification_latency_ms_bucket{le="1000"} 77
workflow_classification_latency_ms_sum 32450
workflow_classification_latency_ms_count 85
EOF
}
```

### 7.3 Alerting Criteria

**Alert Rules** (for production monitoring):

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| High Fallback Rate | `fallback_rate > 50%` for 1 hour | Warning | Investigate LLM API health |
| Very High Fallback Rate | `fallback_rate > 80%` for 15 min | Critical | Switch to regex-only mode |
| High Latency | `p95_latency > 1000ms` for 30 min | Warning | Check API response times |
| Classification Errors | `error_rate > 10%` for 15 min | Critical | Investigate parsing logic |
| Low Confidence Trend | `p50_confidence < 0.7` for 1 day | Warning | Review prompt engineering |
| High Disagreement Rate | `disagreement_rate > 30%` for 1 day | Info | A/B test results available |

**Alert Notifications** (future):
- Slack webhook for critical alerts
- Email for warnings
- Metrics dashboard for info alerts

**Auto-Remediation** (future):
```bash
# Auto-switch to regex-only on critical failures
auto_remediate() {
  local fallback_rate="$1"

  if (( $(echo "$fallback_rate > 0.8" | bc -l) )); then
    log_error "Critical fallback rate $fallback_rate, switching to regex-only mode"
    export WORKFLOW_CLASSIFICATION_MODE=regex-only

    # Notify team
    send_slack_alert "Workflow classification auto-switched to regex-only due to high fallback rate ($fallback_rate)"
  fi
}
```

---

## 8. Testing Infrastructure

### 8.1 Unit Tests

**New Test File**: `.claude/tests/test_llm_classifier.sh`
**Lines of Code**: ~150 lines
**Coverage Target**: 90%+ of workflow-llm-classifier.sh

**Test Categories**:

#### 8.1.1 Input Validation Tests
```bash
test_llm_classifier_empty_input() {
  result=$(classify_workflow_llm "")
  assert_exit_code 1
}

test_llm_classifier_long_input() {
  local long_description
  long_description=$(printf 'a%.0s' {1..10000})  # 10k chars
  result=$(classify_workflow_llm "$long_description")
  assert_exit_code 0  # Should handle gracefully
}
```

#### 8.1.2 JSON Building Tests
```bash
test_build_classifier_input_escaping() {
  local input='description with "quotes" and $variables'
  result=$(build_llm_classifier_input "$input")
  assert_valid_json "$result"
  assert_contains "$result" '"quotes"'
  assert_not_contains "$result" '$variables'  # Should be escaped
}
```

#### 8.1.3 Response Parsing Tests
```bash
test_parse_valid_response() {
  local mock_response='{"classification": "research-and-plan", "confidence": 0.95, "reasoning": "test"}'
  result=$(parse_llm_classifier_response "$mock_response")
  assert_exit_code 0
  assert_json_field "$result" ".scope" "research-and-plan"
  assert_json_field "$result" ".confidence" "0.95"
  assert_json_field "$result" ".method" "llm"
}

test_parse_invalid_type() {
  local mock_response='{"classification": "invalid-type", "confidence": 0.95, "reasoning": "test"}'
  result=$(parse_llm_classifier_response "$mock_response")
  assert_exit_code 1  # Should fail validation
}

test_parse_confidence_out_of_range() {
  local mock_response='{"classification": "research-and-plan", "confidence": 1.5, "reasoning": "test"}'
  result=$(parse_llm_classifier_response "$mock_response")
  assert_exit_code 1
}

test_parse_malformed_json() {
  local mock_response='{"classification": "research-and-plan", "confidence": 0.95'  # Missing closing brace
  result=$(parse_llm_classifier_response "$mock_response")
  assert_exit_code 1
}
```

#### 8.1.4 Confidence Threshold Tests
```bash
test_confidence_threshold_met() {
  WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.7
  # Mock LLM returning 0.8 confidence
  result=$(classify_workflow_llm "test description")
  assert_contains "$result" '"method": "llm"'
}

test_confidence_threshold_not_met() {
  WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.7
  # Mock LLM returning 0.6 confidence
  result=$(classify_workflow_llm "test description")
  assert_exit_code 1  # Triggers fallback
}
```

#### 8.1.5 Timeout Tests
```bash
test_llm_classifier_timeout() {
  WORKFLOW_CLASSIFICATION_TIMEOUT=1  # 1 second
  # Mock LLM that takes 5 seconds (sleep 5)
  result=$(classify_workflow_llm "test description")
  assert_exit_code 1  # Timeout should trigger fallback
}
```

**Test Helpers**:
```bash
# Mock LLM responses for testing
mock_llm_response() {
  local classification="$1"
  local confidence="$2"
  local reasoning="${3:-test reasoning}"

  echo "{\"classification\": \"$classification\", \"confidence\": $confidence, \"reasoning\": \"$reasoning\"}"
}

# Override invoke_llm_classifier for testing
invoke_llm_classifier() {
  echo "$(mock_llm_response "research-and-plan" 0.95)"
}
```

### 8.2 Integration Tests

**Modified Test File**: `.claude/tests/test_scope_detection.sh`
**Lines Added**: ~100 lines

**Test Categories**:

#### 8.2.1 Environment Variable Tests
```bash
test_detect_scope_v2_hybrid_mode() {
  WORKFLOW_CLASSIFICATION_MODE=hybrid
  result=$(detect_workflow_scope_v2 "research auth patterns")
  assert_exit_code 0
  assert_equals "$result" "research-and-plan"  # Or whatever LLM returns
}

test_detect_scope_v2_regex_only_mode() {
  WORKFLOW_CLASSIFICATION_MODE=regex-only
  result=$(detect_workflow_scope_v2 "research auth patterns")
  assert_exit_code 0
  assert_equals "$result" "research-and-plan"  # Regex result
}

test_detect_scope_v2_llm_only_mode() {
  WORKFLOW_CLASSIFICATION_MODE=llm-only
  # Mock LLM failure
  result=$(detect_workflow_scope_v2 "research auth patterns")
  assert_exit_code 1  # Should fail without fallback
}
```

#### 8.2.2 Fallback Behavior Tests
```bash
test_detect_scope_v2_llm_timeout_fallback() {
  WORKFLOW_CLASSIFICATION_MODE=hybrid
  WORKFLOW_CLASSIFICATION_TIMEOUT=1
  # Mock LLM timeout
  result=$(detect_workflow_scope_v2 "research auth patterns")
  assert_exit_code 0
  assert_contains "$(get_last_log_line)" "fallback to regex"
}

test_detect_scope_v2_low_confidence_fallback() {
  WORKFLOW_CLASSIFICATION_MODE=hybrid
  WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.9
  # Mock LLM returning 0.7 confidence
  result=$(detect_workflow_scope_v2 "ambiguous description")
  assert_exit_code 0
  assert_contains "$(get_last_log_line)" "fallback to regex"
}
```

#### 8.2.3 Backward Compatibility Tests
```bash
test_detect_scope_v2_string_output_format() {
  WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT=string
  result=$(detect_workflow_scope_v2 "research auth patterns")
  assert_not_json "$result"  # Should return plain string
  assert_equals "$result" "research-and-plan"
}

test_detect_scope_v2_json_output_format() {
  WORKFLOW_CLASSIFICATION_OUTPUT_FORMAT=json
  result=$(detect_workflow_scope_v2 "research auth patterns")
  assert_valid_json "$result"
  assert_json_field "$result" ".scope" "research-and-plan"
  assert_json_field "$result" ".confidence" > 0.0
}

test_detect_scope_v1_still_works() {
  # Original function should be unchanged
  result=$(detect_workflow_scope "research auth patterns")
  assert_exit_code 0
  assert_equals "$result" "research-and-plan"
}
```

#### 8.2.4 /coordinate Integration Tests
```bash
test_coordinate_uses_v2_classifier() {
  # Run /coordinate with debug logging
  WORKFLOW_CLASSIFICATION_DEBUG=1 \
    output=$(/coordinate "research auth patterns" 2>&1)

  # Should see v2 classifier logs
  assert_contains "$output" "detect_workflow_scope_v2"
  assert_contains "$output" "Classification method: llm"
}

test_coordinate_fallback_still_works() {
  # Force LLM failure
  WORKFLOW_CLASSIFICATION_MODE=hybrid
  WORKFLOW_CLASSIFICATION_TIMEOUT=0

  output=$(/coordinate "research auth patterns" 2>&1)

  # Should fallback to regex and complete workflow
  assert_contains "$output" "fallback to regex"
  assert_contains "$output" "State Machine Initialized"
  assert_exit_code 0
}
```

### 8.3 A/B Testing Framework

**New Test File**: `.claude/tests/test_scope_detection_ab.sh`
**Lines of Code**: ~100 lines

**Purpose**: Run both classifiers on same inputs, identify disagreements for human review.

```bash
#!/bin/bash
# A/B Test: Compare LLM vs Regex Classifications

# Test dataset (real-world descriptions)
TEST_CASES=(
  "research authentication patterns and create implementation plan"
  "research the research-and-revise workflow to understand misclassification"
  "Revise plan at specs/042_auth/plans/001_plan.md based on security audit"
  "implement OAuth integration per existing plan"
  "fix bug in token validation logic"
  "research caching strategies"
  "analyze coordinate command output and create plan to fix errors"
)

# Run A/B test
run_ab_test() {
  local disagreements=0
  local total=${#TEST_CASES[@]}

  echo "A/B Test: LLM vs Regex Classification"
  echo "========================================"
  echo ""

  for description in "${TEST_CASES[@]}"; do
    # Get LLM classification
    WORKFLOW_CLASSIFICATION_MODE=llm-only \
      llm_result=$(detect_workflow_scope_v2 "$description" 2>/dev/null || echo "ERROR")

    # Get Regex classification
    regex_result=$(detect_workflow_scope "$description")

    # Compare results
    if [ "$llm_result" != "$regex_result" ]; then
      disagreements=$((disagreements + 1))
      echo "DISAGREEMENT:"
      echo "  Description: $description"
      echo "  LLM:   $llm_result"
      echo "  Regex: $regex_result"
      echo ""
    else
      echo "AGREEMENT: $description → $llm_result"
    fi
  done

  echo ""
  echo "Summary:"
  echo "  Total tests: $total"
  echo "  Disagreements: $disagreements ($((disagreements * 100 / total))%)"
  echo "  Agreement rate: $((100 - disagreements * 100 / total))%"
}

# Generate disagreement report for human review
generate_disagreement_report() {
  local report_file=".claude/specs/670_workflow_classification_improvement/ab_test_disagreements_$(date +%Y%m%d).md"

  cat > "$report_file" <<EOF
# A/B Test Disagreement Report
**Date**: $(date -Iseconds)
**Test Count**: ${#TEST_CASES[@]}

## Disagreements for Human Review

EOF

  for description in "${TEST_CASES[@]}"; do
    llm_result=$(WORKFLOW_CLASSIFICATION_MODE=llm-only detect_workflow_scope_v2 "$description" 2>/dev/null || echo "ERROR")
    regex_result=$(detect_workflow_scope "$description")

    if [ "$llm_result" != "$regex_result" ]; then
      cat >> "$report_file" <<EOF
### Case: "$description"
- **LLM Classification**: $llm_result
- **Regex Classification**: $regex_result
- **Correct Classification**: [ ] LLM / [ ] Regex / [ ] Both Wrong
- **Notes**:

---

EOF
    fi
  done

  echo "Report generated: $report_file"
}
```

**Usage**:
```bash
# Run A/B test
./test_scope_detection_ab.sh run_ab_test

# Generate report for human review
./test_scope_detection_ab.sh generate_disagreement_report
```

**Human Review Process**:
1. A/B test runs automatically during CI/CD
2. Disagreements logged to report file
3. Weekly review of disagreements by maintainer
4. Update test dataset with reviewed cases
5. Track agreement rate over time (target: 95%+)

---

## 9. Code Structure

### 9.1 File Organization

```
.claude/
├── lib/
│   ├── workflow-llm-classifier.sh (NEW - 200 lines)
│   │   ├── classify_workflow_llm()
│   │   ├── build_llm_classifier_input()
│   │   ├── invoke_llm_classifier()
│   │   ├── parse_llm_classifier_response()
│   │   └── log_classification_result()
│   │
│   ├── workflow-scope-detection.sh (MODIFIED - add 50 lines)
│   │   ├── detect_workflow_scope_v2() (NEW)
│   │   ├── detect_workflow_scope() (UNCHANGED)
│   │   └── load_classification_config() (NEW)
│   │
│   ├── workflow-state-machine.sh (MODIFIED - 5 lines)
│   │   └── sm_init() - Call detect_workflow_scope_v2() instead of v1
│   │
│   └── unified-logger.sh (NO CHANGE)
│       └── Already supports structured logging
│
├── tests/
│   ├── test_llm_classifier.sh (NEW - 150 lines)
│   │   ├── Unit tests for workflow-llm-classifier.sh
│   │   ├── Mock LLM responses
│   │   └── Timeout and error handling tests
│   │
│   ├── test_scope_detection.sh (MODIFIED - add 100 lines)
│   │   ├── Integration tests for detect_workflow_scope_v2()
│   │   ├── Environment variable tests
│   │   ├── Fallback behavior tests
│   │   └── Backward compatibility tests
│   │
│   ├── test_scope_detection_ab.sh (NEW - 100 lines)
│   │   ├── A/B testing framework
│   │   ├── Disagreement reporting
│   │   └── Human review workflow
│   │
│   └── run_all_tests.sh (MODIFIED - add 3 lines)
│       └── Include new test files
│
├── commands/
│   └── coordinate.md (MODIFIED - 0 lines directly)
│       └── Uses sm_init() which now calls detect_workflow_scope_v2()
│
└── config/ (NEW - optional)
    └── workflow-classification.conf (NEW - optional - 20 lines)
        └── Configuration file (future enhancement)
```

**Summary of Changes**:
- **New files**: 3 (~450 lines total)
- **Modified files**: 4 (~155 lines added)
- **Total new code**: ~595 lines
- **Unchanged files**: 100+ existing files maintain full backward compatibility

### 9.2 Function Naming Conventions

**Patterns**:
- Public functions (exported): `{verb}_{noun}()` or `{noun}_{verb}()`
  - Examples: `classify_workflow_llm()`, `detect_workflow_scope_v2()`
- Private functions (local): `_internal_{verb}_{noun}()`
  - Examples: `_internal_parse_response()`, `_internal_validate_config()`
- Test functions: `test_{feature}_{scenario}()`
  - Examples: `test_llm_classifier_timeout()`, `test_scope_v2_fallback()`

**Prefixes**:
- `llm_` - LLM-specific functions
- `classify_` - Classification functions
- `parse_` - Parsing functions
- `build_` - Construction functions
- `log_` - Logging functions
- `mock_` - Test mock functions

**Consistency with Existing Code**:
- Follow existing `.claude/lib/` naming patterns
- Use snake_case for all functions (not camelCase)
- Use descriptive names (no abbreviations unless standard)
- Export public functions: `export -f function_name`

---

## 10. Migration and Rollback

### 10.1 Phased Rollout Plan

**4-Phase Rollout** (6-7 weeks total):

#### Phase 1: Alpha (Week 1-2)
**Goal**: Validate basic functionality with developer testing.

**Scope**:
- Deploy to developer machines only
- Environment variable opt-in: `WORKFLOW_CLASSIFICATION_MODE=hybrid`
- Debug logging enabled by default
- No production traffic

**Acceptance Criteria**:
- All unit tests pass (150+ tests)
- All integration tests pass (100+ tests)
- Manual testing with 20+ real workflow descriptions
- Zero regressions (existing regex tests still pass)
- LLM classifier returns valid results >90% of time

**Rollback**:
- `unset WORKFLOW_CLASSIFICATION_MODE` (defaults to regex-only v1)
- Zero downtime

#### Phase 2: Beta (Week 3-4)
**Goal**: Internal testing with monitoring.

**Scope**:
- Deploy to internal testing environment
- Opt-in for early adopters: Set `WORKFLOW_CLASSIFICATION_MODE=hybrid` in shell profile
- A/B testing active (log disagreements)
- Monitor metrics dashboard

**Acceptance Criteria**:
- 50+ real workflow classifications completed
- Fallback rate <30%
- Agreement rate >85% (LLM vs regex)
- p95 latency <800ms
- Zero critical errors
- Positive feedback from early adopters

**Rollback**:
- Set `WORKFLOW_CLASSIFICATION_MODE=regex-only` globally
- Keep monitoring in place

#### Phase 3: Gamma (Week 5-6)
**Goal**: Gradual production rollout with subset of traffic.

**Scope**:
- Enable for 25% of /coordinate invocations (sampling)
- Default mode still regex-only, gradually increase hybrid usage
- Full monitoring and alerting active
- Weekly disagreement review meetings

**Acceptance Criteria**:
- 200+ production classifications completed
- Fallback rate <20%
- Agreement rate >90%
- p95 latency <600ms
- Error rate <1%
- Human review confirms LLM classifications are correct >95% of time

**Rollback**:
- Reduce sampling percentage to 0%
- Investigate issues before re-enabling

#### Phase 4: Production (Week 7+)
**Goal**: Full rollout as default classifier.

**Scope**:
- Change default: `WORKFLOW_CLASSIFICATION_MODE=hybrid` (no opt-in needed)
- Users can still opt-out with `WORKFLOW_CLASSIFICATION_MODE=regex-only`
- Continuous monitoring
- Monthly review of classification quality

**Acceptance Criteria**:
- Smooth transition with no user complaints
- Fallback rate <15% (stable)
- Agreement rate >95%
- p95 latency <500ms
- Error rate <0.5%

**Rollback**:
- Emergency: Set default to `regex-only` in library initialization
- Planned: Communicate change 1 week in advance

### 10.2 Rollback Strategy

**Instant Rollback** (Zero Downtime):
```bash
# Method 1: Environment variable (per-user)
export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Method 2: Global default change (library-level)
# Edit .claude/lib/workflow-scope-detection.sh line:
# WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-regex-only}"  # Changed from 'hybrid'

# Method 3: Feature flag file (organization-wide)
echo "regex-only" > .claude/config/workflow-classification-mode.txt
# Library reads this file on startup
```

**Rollback Decision Matrix**:

| Issue | Severity | Action | Timeline |
|-------|----------|--------|----------|
| Fallback rate >50% | High | Investigate LLM API | 4 hours |
| Fallback rate >80% | Critical | Auto-switch to regex-only | Immediate |
| Error rate >10% | Critical | Rollback to regex-only | Immediate |
| User complaints >5 | Medium | Offer opt-out instructions | 24 hours |
| Latency p95 >2s | High | Reduce timeout to 5s | 2 hours |
| Latency p95 >5s | Critical | Rollback to regex-only | Immediate |

**Incident Response Plan**:
1. **Alert fired** → Oncall engineer notified
2. **Investigate** (15 min):
   - Check metrics dashboard
   - Review recent logs
   - Check LLM API status page
3. **Decision** (5 min):
   - Rollback if critical severity
   - Mitigate if high severity (adjust threshold/timeout)
   - Monitor if medium severity
4. **Execute rollback** (<1 min):
   ```bash
   # Emergency rollback command
   echo "WORKFLOW_CLASSIFICATION_MODE=regex-only" >> ~/.bashrc
   source ~/.bashrc
   ```
5. **Post-incident** (1 week):
   - Root cause analysis
   - Update runbooks
   - Implement safeguards

**Rollback Testing**:
```bash
# Test rollback procedure (in alpha phase)
test_rollback() {
  # 1. Verify hybrid mode works
  WORKFLOW_CLASSIFICATION_MODE=hybrid
  result=$(detect_workflow_scope_v2 "test")
  assert_equals "$result" "research-and-plan"

  # 2. Rollback to regex-only
  WORKFLOW_CLASSIFICATION_MODE=regex-only
  result=$(detect_workflow_scope_v2 "test")
  assert_equals "$result" "research-and-plan"

  # 3. Verify no breaking changes
  unset WORKFLOW_CLASSIFICATION_MODE
  result=$(detect_workflow_scope "test")
  assert_equals "$result" "research-and-plan"

  echo "Rollback procedure tested successfully"
}
```

---

## 11. Documentation Updates Required

**List of documentation files requiring updates**:

### 11.1 Command Documentation
**File**: `.claude/docs/guides/coordinate-command-guide.md`

**Updates**:
- Section 2 (Architecture): Add subsection "2.4 Hybrid Workflow Classification"
  - Describe LLM + regex architecture
  - Explain fallback mechanism
  - Show decision flow diagram
- Section 4 (Usage): Add subsection "4.3 Classification Mode Configuration"
  - Document environment variables
  - Show usage examples for each mode
  - Explain when to use each mode
- Section 5 (Troubleshooting): Add subsection "5.4 Classification Issues"
  - Common misclassification scenarios
  - How to debug classification results
  - How to opt-out of LLM classifier

**Lines to Add**: ~150 lines

### 11.2 Library API Reference
**File**: `.claude/docs/reference/library-api.md`

**Updates**:
- Add section "workflow-llm-classifier.sh" with function signatures:
  - `classify_workflow_llm()`
  - `build_llm_classifier_input()`
  - `invoke_llm_classifier()`
  - `parse_llm_classifier_response()`
- Update section "workflow-scope-detection.sh":
  - Add `detect_workflow_scope_v2()` function
  - Mark `detect_workflow_scope()` as legacy (still supported)
  - Document environment variables

**Lines to Add**: ~80 lines

### 11.3 Pattern Documentation
**File**: `.claude/docs/concepts/patterns/llm-classification-pattern.md` (NEW)

**Content**:
- Overview of LLM-based classification pattern
- When to use (complex intent detection, semantic understanding)
- When NOT to use (simple pattern matching, high-frequency low-latency)
- Architecture diagram
- Code examples
- Trade-offs (accuracy vs latency vs cost)
- Testing strategy
- Related patterns (behavioral injection, fallback pattern)

**Lines to Add**: ~200 lines (new file)

### 11.4 Main Configuration File
**File**: `CLAUDE.md`

**Updates**:
- Section "State-Based Orchestration Architecture" → Update subsection about workflow detection:
  ```markdown
  ## Workflow Scope Detection

  /coordinate automatically detects the appropriate workflow scope using a hybrid classification system:

  - **LLM Classifier** (default): Uses Claude Haiku to semantically understand workflow intent
  - **Regex Fallback**: Falls back to pattern matching on timeout, low confidence, or error
  - **Modes**: hybrid (default), llm-only, regex-only

  Configure with `WORKFLOW_CLASSIFICATION_MODE` environment variable. See `/coordinate` guide for details.
  ```

**Lines to Add**: ~10 lines

### 11.5 Testing Documentation
**File**: `.claude/tests/README.md`

**Updates**:
- Add section "Workflow Classification Tests":
  - `test_llm_classifier.sh` - Unit tests for LLM classifier
  - `test_scope_detection.sh` - Integration tests for hybrid classifier
  - `test_scope_detection_ab.sh` - A/B testing framework
- Document A/B testing workflow
- Document mock LLM response patterns

**Lines to Add**: ~50 lines

### 11.6 Troubleshooting Guide
**File**: `.claude/docs/guides/orchestration-troubleshooting.md`

**Updates**:
- Add section "Workflow Misclassification Issues":
  - Symptoms: Wrong workflow scope detected
  - Diagnosis: Enable debug logging, check classification confidence
  - Resolution: Use regex-only mode, report to team
- Add section "LLM Classifier Timeout Issues":
  - Symptoms: Classification takes >10 seconds
  - Diagnosis: Check API status, review logs
  - Resolution: Reduce timeout, use regex-only mode

**Lines to Add**: ~60 lines

### 11.7 Changelog
**File**: `.claude/CHANGELOG.md` (if it exists)

**Updates**:
- Add entry for this feature:
  ```markdown
  ## [X.Y.0] - 2025-MM-DD

  ### Added
  - Hybrid workflow classification system (LLM + regex)
  - Claude Haiku 4.5 classifier for semantic intent detection
  - Automatic fallback to regex on timeout/low confidence
  - A/B testing framework for classification quality monitoring
  - Environment variables for classification mode configuration

  ### Changed
  - /coordinate now uses `detect_workflow_scope_v2()` (backward compatible)
  - Default classification mode: hybrid (LLM with regex fallback)

  ### Deprecated
  - `detect_workflow_scope()` → Use `detect_workflow_scope_v2()` for new code

  ### Fixed
  - Workflow misclassification when discussing workflow types vs requesting them
  ```

**Lines to Add**: ~15 lines

---

## Summary of Documentation Updates

| File | Type | Lines Added | Priority |
|------|------|-------------|----------|
| coordinate-command-guide.md | Update | ~150 | High |
| library-api.md | Update | ~80 | High |
| llm-classification-pattern.md | New | ~200 | Medium |
| CLAUDE.md | Update | ~10 | High |
| tests/README.md | Update | ~50 | Medium |
| orchestration-troubleshooting.md | Update | ~60 | Medium |
| CHANGELOG.md | Update | ~15 | Low |

**Total Documentation**: ~565 lines

**Timeline**:
- High priority docs (Phase 1-2): ~240 lines
- Medium priority docs (Phase 3): ~310 lines
- Low priority docs (Phase 4): ~15 lines

---

## Appendix: Architecture Decision Records

### ADR 1: Hybrid Approach (LLM + Regex Fallback)
**Decision**: Use hybrid classification with automatic fallback.
**Rationale**: Zero operational risk (regex always available), improves accuracy on edge cases, negligible cost.
**Trade-offs**: Slightly more complex code, potential latency increase (mitigated by timeout).

### ADR 2: Claude Haiku 4.5 Model Selection
**Decision**: Use Haiku (not Sonnet or Opus).
**Rationale**: Classification is deterministic task, Haiku 98%+ accuracy sufficient, 5x cheaper than Sonnet.
**Trade-offs**: Marginally lower accuracy than Sonnet (98% vs 99%), acceptable for this use case.

### ADR 3: Environment Variables (Not Config File)
**Decision**: Use environment variables for configuration initially.
**Rationale**: Simpler implementation, sufficient for most users, no parsing complexity.
**Trade-offs**: Less convenient for organization-wide defaults (can add config file later if needed).

### ADR 4: 0.7 Confidence Threshold
**Decision**: Start with 0.7 minimum confidence threshold.
**Rationale**: Balances LLM usage (captures 60-70% of requests) with fallback safety (uncertain classifications use regex).
**Trade-offs**: May fall back more than necessary, but conservative for initial rollout.

### ADR 5: 10-Second Timeout
**Decision**: 10-second timeout for LLM classifier.
**Rationale**: Haiku typically responds in 200-500ms, 10s is generous buffer. User experience not impacted by 500ms in command startup phase.
**Trade-offs**: Wastes 10 seconds on API outages before fallback (acceptable for rare outages).

### ADR 6: No Caching
**Decision**: No classification result caching initially.
**Rationale**: Low cache hit rate (<5%), negligible cost savings, added complexity.
**Trade-offs**: Could save ~$0.02/year per user (not worth it).

### ADR 7: AI Assistant Integration (Not Direct API Calls)
**Decision**: Use AI assistant to invoke Task tool (not direct Anthropic API calls from bash).
**Rationale**: Aligns with Claude Code architecture, no API key management in bash, leverages existing infrastructure.
**Trade-offs**: Slightly more complex bash-to-AI communication pattern (file-based signaling).

---

**End of Implementation Architecture Document**

This architecture document provides comprehensive technical specifications for implementing the hybrid workflow classification system. All design decisions are justified with references to the research reports, and the implementation is fully backward compatible with existing code.
