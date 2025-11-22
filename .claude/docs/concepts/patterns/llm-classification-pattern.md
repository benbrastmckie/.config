# LLM-Based Classification Pattern (LLM-Only)

**Path**: docs → concepts → patterns → llm-classification-pattern.md

[Used by: /coordinate, /supervise, workflow-scope-detection.sh, workflow-detection.sh]

**IMPORTANT**: This document describes the historical 2-mode system. **regex-only mode has been removed** (Spec 704 Phase 4). The system now uses **LLM-only classification** with fail-fast error handling.

LLM-based classification with fail-fast error handling for 98%+ accuracy semantic understanding.

**Note**: Hybrid mode was removed in Spec 688. regex-only mode was removed in Spec 704 Phase 4. LLM-only mode now fails fast with clear error messages when classification fails.

## Definition

LLM-Based Classification is a pattern where semantic understanding is provided by an LLM (Claude Haiku 4.5) in llm-only mode, with an explicit regex-only mode available for offline development and testing. The system uses fail-fast error handling instead of automatic fallback, providing clear error messages when LLM classification fails.

The pattern transforms classification from:
- **Before**: Regex-only pattern matching (92% accuracy, 8% false positive rate on edge cases)
- **After**: LLM semantic understanding with fail-fast errors (98%+ accuracy, clear failure handling)

## Rationale

### Why This Pattern Matters

Regex-based classification fails on semantic edge cases:

1. **Context Confusion**: "research the research-and-revise workflow" incorrectly classified as `research-and-revise` instead of `research-and-plan` (discussing vs. requesting)

2. **Keyword Ambiguity**: "research the 'implement' command" incorrectly classified as `full-implementation` instead of `research-only` (quoted keywords)

3. **Negation Handling**: "don't revise the plan, create a new one" incorrectly classified as `research-and-revise` (negation not understood)

4. **Maintenance Burden**: Adding more regex patterns increases complexity exponentially and creates more edge cases

### Problems Solved

- **Semantic Understanding**: LLM distinguishes intent from keyword presence
- **Edge Case Handling**: 8% false positive rate reduced to <2%
- **Fail-Fast Errors**: Clear error messages with actionable suggestions
- **Cost Efficiency**: Negligible cost ($0.03/month for typical usage)
- **Offline Support**: Regex-only mode for offline/air-gapped development

## Implementation

### Core Mechanism

**Architecture** (2-Mode System):

```
User Input → classify_workflow_comprehensive()
                │
                ├─→ [llm-only mode] (DEFAULT)
                │       LLM Classifier (Haiku 4.5)
                │       │
                │       ├─→ [success] Return LLM result (JSON)
                │       └─→ [failure] Fail-fast with error message
                │               ├─→ Timeout: "Increase WORKFLOW_CLASSIFICATION_TIMEOUT"
                │               ├─→ API error: "Check network or use regex-only"
                │               └─→ Low confidence: "Rephrase description"
                │
                └─→ [regex-only mode] (OFFLINE)
                        Regex Classifier (traditional)
                        └─→ Return regex result (JSON)

Note: Hybrid mode removed - no automatic fallback
```

**Step 1: Primary LLM Classification**

The system first attempts LLM-based classification:

```bash
# From .claude/lib/workflow/workflow-scope-detection.sh (simplified for 2-mode system)
classify_workflow_comprehensive() {
  local workflow_description="$1"

  case "$WORKFLOW_CLASSIFICATION_MODE" in
    llm-only)
      # LLM classification with fail-fast error handling
      if ! result=$(classify_workflow_llm "$workflow_description" 2>&1); then
        # Fail fast with clear error message
        echo "ERROR: LLM classification failed" >&2
        echo "  Workflow: $workflow_description" >&2
        echo "  Suggestion: Use regex-only mode for offline development" >&2
        return 1
      fi
      echo "$result"
      return 0
      ;;
    regex-only)
      # Traditional regex classification (offline/testing)
      classify_workflow_regex_comprehensive "$workflow_description"
      return 0
      ;;
    *)
      echo "ERROR: Invalid WORKFLOW_CLASSIFICATION_MODE='$WORKFLOW_CLASSIFICATION_MODE'" >&2
      echo "  Valid modes: llm-only (default), regex-only" >&2
      return 1
      ;;
  esac
}
```

**Step 2: LLM Invocation with File-Based Signaling**

The LLM classifier uses file-based signaling for AI assistant interaction:

```bash
# From .claude/lib/workflow/workflow-llm-classifier.sh
classify_workflow_llm() {
  local workflow_description="$1"

  # Build LLM classifier input (JSON prompt)
  local llm_input
  llm_input=$(build_llm_classifier_input "$workflow_description")

  # Invoke LLM via file-based signaling
  local llm_response
  llm_response=$(invoke_llm_classifier "$llm_input")

  # Parse and validate response
  parse_llm_classifier_response "$llm_response"
}

invoke_llm_classifier() {
  local llm_input="$1"
  local request_file="/tmp/llm_classification_request_$$.json"
  local response_file="/tmp/llm_classification_response_$$.json"

  # Write request
  echo "$llm_input" > "$request_file"

  # Signal to AI assistant via stderr
  echo "[LLM_CLASSIFICATION_REQUEST]: $request_file" >&2

  # Wait for response with timeout (default: 10 seconds)
  local timeout="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    if [ -f "$response_file" ]; then
      cat "$response_file"
      return 0
    fi
    sleep 0.5
    elapsed=$((elapsed + 1))
  done

  return 1  # Timeout - triggers regex fallback
}
```

**Step 3: Confidence Threshold and Fallback**

The system validates LLM confidence and falls back when uncertain:

```bash
parse_llm_classifier_response() {
  local response="$1"

  # Extract confidence score
  local confidence
  confidence=$(echo "$response" | jq -r '.confidence // 0')

  # Check threshold (default: 0.7)
  local threshold="${WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD:-0.7}"

  if (( $(echo "$confidence >= $threshold" | bc -l) )); then
    echo "$response"
    return 0
  else
    log_classification_debug "Low confidence ($confidence < $threshold), triggering fallback"
    return 1  # Triggers regex fallback
  fi
}
```

### Configuration

**Environment Variables** (2-Mode System):

```bash
# Classification mode (default: llm-only)
WORKFLOW_CLASSIFICATION_MODE="llm-only"  # llm-only (default), regex-only

# Timeout in seconds (default: 10)
WORKFLOW_CLASSIFICATION_TIMEOUT="10"

# Debug logging (default: 0)
WORKFLOW_CLASSIFICATION_DEBUG="0"  # 0 = disabled, 1 = enabled

# Note: WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD removed (clean-break)
# LLM now returns enhanced topics with confidence validation in parse step
```

**Mode Selection**:

```bash
# Online development (default): LLM classification
export WORKFLOW_CLASSIFICATION_MODE=llm-only

# Offline/air-gapped development: Regex classification
export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Per-command override:
WORKFLOW_CLASSIFICATION_MODE=regex-only /coordinate "description"
```

### Usage Context

**When to Use This Pattern**:

- Classification decisions with semantic ambiguity
- User input interpretation (vs structured data)
- Intent detection where keywords can be misleading
- Edge cases that are expensive to handle with regex

**When NOT to Use This Pattern**:

- Structured data parsing (file paths, JSON, etc.)
- Performance-critical hot paths (< 1ms required)
- Deterministic classification where regex suffices
- Offline/air-gapped environments

### Code Example

**Full Example**: Detecting workflow scope with 2-mode system

```bash
#!/usr/bin/env bash
# Example: Classify workflow descriptions (2-mode system)

source .claude/lib/workflow/workflow-scope-detection.sh

# Test Case 1: Semantic edge case (LLM handles better)
description="research the research-and-revise workflow to understand misclassification"
if result=$(classify_workflow_comprehensive "$description"); then
  scope=$(echo "$result" | jq -r '.workflow_type')
  echo "Case 1: $scope"  # Expected: research-only (not research-and-revise)
else
  echo "Case 1: LLM classification failed (use regex-only for offline)"
fi

# Test Case 2: Clear intent (LLM mode)
description="research authentication patterns and create implementation plan"
result=$(classify_workflow_comprehensive "$description")
scope=$(echo "$result" | jq -r '.workflow_type')
echo "Case 2: $scope"  # Expected: research-and-plan

# Test Case 3: Regex-only mode (offline development)
WORKFLOW_CLASSIFICATION_MODE=regex-only
result=$(classify_workflow_comprehensive "$description")
scope=$(echo "$result" | jq -r '.workflow_type')
echo "Case 3: $scope (regex-only mode)"  # Expected: research-and-plan

# Test Case 4: Error handling (fail-fast)
WORKFLOW_CLASSIFICATION_TIMEOUT=0.001
if ! result=$(classify_workflow_comprehensive "$description" 2>&1); then
  echo "Case 4: LLM timeout - fail-fast error shown"
fi
```

## Performance Impact

### Real-World Metrics

**Accuracy Improvements** (from A/B testing on 42 real workflow descriptions):

| Metric | Regex-Only | LLM-Only | Improvement |
|--------|------------|----------|-------------|
| Overall Accuracy | 92% | 98%+ | +6% |
| Edge Case Accuracy | 60% | 95%+ | +35% |
| False Positive Rate | 8% | <2% | -6% |
| A/B Agreement Rate | N/A | 90%+ | Baseline |

**Performance Characteristics**:

| Metric | Value | Notes |
|--------|-------|-------|
| LLM Latency (p50) | <300ms | Target from testing |
| LLM Latency (p95) | <600ms | Target from testing |
| LLM Latency (p99) | <1000ms | Target from testing |
| Regex Latency | <10ms | Fallback is fast |
| Timeout | 10s | Configurable |
| Cost per Classification | ~$0.00003 | Haiku 4.5 |
| Monthly Cost (100/day) | ~$0.03 | Negligible |

**Context Reduction** (vs full document parsing):
- Classification request: ~200 tokens
- Classification response: ~50 tokens
- Total: ~250 tokens per classification

**Reliability Metrics** (2-Mode System):

| Metric | Value | Notes |
|--------|-------|-------|
| LLM Success Rate | 95-98% | When API available |
| Regex Availability | 100% | No external dependencies |
| Timeout Handling | Fail-Fast | Clear error messages |
| Error Recovery | Manual | User switches to regex-only mode |

### Optimization Techniques (2-Mode System)

**1. Timeout Optimization**

Adjust timeout based on network conditions:

```bash
# Fast fail-fast (5 seconds) - for good network connections
WORKFLOW_CLASSIFICATION_TIMEOUT=5

# Balanced (default: 10 seconds)
WORKFLOW_CLASSIFICATION_TIMEOUT=10

# Patient (15 seconds) - for slow/high-latency networks
WORKFLOW_CLASSIFICATION_TIMEOUT=15
```

**2. Mode Selection**

Choose mode based on environment and requirements:

```bash
# Online development (default): LLM classification with fail-fast
WORKFLOW_CLASSIFICATION_MODE=llm-only

# Offline/air-gapped: Regex classification (no LLM dependency)
WORKFLOW_CLASSIFICATION_MODE=regex-only

# Testing/CI: Test both modes for consistency
for mode in llm-only regex-only; do
  WORKFLOW_CLASSIFICATION_MODE=$mode classify_workflow_comprehensive "test"
done
```

**3. Error Handling Best Practices**

Handle LLM failures gracefully in scripts:

```bash
# Retry with regex-only on LLM failure
if ! result=$(classify_workflow_comprehensive "$description" 2>/dev/null); then
  echo "LLM failed, retrying with regex-only..." >&2
  WORKFLOW_CLASSIFICATION_MODE=regex-only \
    result=$(classify_workflow_comprehensive "$description")
fi
```

## Anti-Patterns

### Example Violation 1: Ignoring LLM Failures (No Error Handling)

**Problem**: Not handling LLM classification failures:

```bash
# WRONG: No error handling - script breaks on LLM failure
WORKFLOW_CLASSIFICATION_MODE=llm-only
result=$(classify_workflow_comprehensive "$description")
scope=$(echo "$result" | jq -r '.workflow_type')
# Fails silently if LLM times out or returns error
```

**Why It Fails**:
- LLM outages cause script to break
- No clear error message for user
- No fallback strategy

**Correct Approach**:

```bash
# CORRECT: Handle errors with clear messages
if ! result=$(classify_workflow_comprehensive "$description" 2>&1); then
  echo "ERROR: LLM classification failed" >&2
  echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work" >&2
  exit 1
fi
scope=$(echo "$result" | jq -r '.workflow_type')
```

### Example Violation 2: Synchronous Blocking Without Timeout

**Problem**: Waiting indefinitely for LLM response:

```bash
# WRONG: No timeout - hangs forever if LLM doesn't respond
while true; do
  if [ -f "$response_file" ]; then
    break
  fi
  sleep 1
done
```

**Why It Fails**:
- Indefinite blocking if LLM never responds
- No user feedback during long waits
- Workflow hangs instead of falling back

**Correct Approach**:

```bash
# CORRECT: Timeout with fallback
timeout="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if [ -f "$response_file" ]; then
    cat "$response_file"
    return 0
  fi
  sleep 0.5
  elapsed=$((elapsed + 1))
done
return 1  # Timeout - triggers regex fallback
```

### Example Violation 3: Re-Parsing After Fallback

**Problem**: Attempting to re-parse classification result:

```bash
# WRONG: Assuming LLM JSON format even after regex fallback
scope=$(detect_workflow_scope "$description")
confidence=$(echo "$scope" | jq -r '.confidence')  # FAILS for regex fallback
```

**Why It Fails**:
- Regex fallback returns plain string, not JSON
- jq parsing fails on non-JSON input
- Error handling becomes complex

**Correct Approach**:

```bash
# CORRECT: detect_workflow_scope returns normalized string in all modes
scope=$(detect_workflow_scope "$description")
echo "Detected scope: $scope"  # Works for LLM and regex results
```

## Related Patterns

### Complementary Patterns

**[Verification and Fallback Pattern](verification-fallback.md)**
- LLM classification uses verification fallback (confidence threshold)
- Immediate error detection triggers regex fallback
- Graceful degradation instead of failure

**[Context Management Pattern](context-management.md)**
- LLM classification minimizes context consumption (250 tokens per request)
- Enables more classifications per workflow without context bloat
- Supports hierarchical workflows with multiple classification points

### Contrasting Patterns

**Regex-Only Classification** (original approach)
- Fast (< 10ms) but less accurate (92%)
- No external dependencies, 100% deterministic
- Struggles with semantic edge cases
- Lower maintenance for simple cases, higher for complex patterns

**LLM-Only Classification** (this pattern - default mode)
- Maximum accuracy (98%+) with fail-fast error handling
- External LLM dependency requires network connectivity
- Clear error messages guide users to regex-only mode when needed
- Minimal cost ($0.03/month typical usage)

**Regex-Only Classification** (offline mode)
- Good accuracy (92%) with zero external dependencies
- 100% offline availability for air-gapped environments
- Fast (<10ms) but struggles with semantic edge cases
- Production-ready for offline scenarios

## References

### Implementation Files

- [workflow-llm-classifier.sh](../../../lib/workflow/workflow-llm-classifier.sh) - LLM classification library
- [workflow-scope-detection.sh](../../../lib/workflow/workflow-scope-detection.sh) - Unified hybrid detection
- [workflow-detection.sh](../../../lib/workflow/workflow-detection.sh) - /supervise integration

### Testing Files

- [test_workflow_classifier_agent.sh](../../../tests/integration/test_workflow_classifier_agent.sh) - Classifier agent tests
- [test_scope_detection.sh](../../../tests/classification/test_scope_detection.sh) - Scope detection tests
- [test_scope_detection_ab.sh](../../../tests/classification/test_scope_detection_ab.sh) - A/B testing (42 cases)
- [test_workflow_detection.sh](../../../tests/classification/test_workflow_detection.sh) - Workflow detection tests

### Documentation

- [Implementation Plan](../../specs/670_workflow_classification_improvement/plans/001_hybrid_classification_implementation.md) - Complete implementation history
- [Architecture Report](../../specs/670_workflow_classification_improvement/reports/003_implementation_architecture.md) - Technical design decisions
- [Library API Reference](../../reference/library-api/overview.md) - API documentation

### Related Standards

- [Standard 13: Project Directory Detection](../../reference/architecture/overview.md#standard-13) - CLAUDE_PROJECT_DIR usage
- [Standard 14: Executable/Documentation Separation](../../reference/architecture/overview.md#standard-14) - Documentation pattern
- [Bash Block Execution Model](../bash-block-execution-model.md) - Subprocess isolation patterns

## Changelog

### 2025-11-13: Clean-Break Update - Hybrid Mode Removed

**Implementation**: Spec 688, Phases 1-6 complete
- **BREAKING**: Hybrid mode removed entirely (clean-break approach)
- **BREAKING**: Automatic regex fallback removed from llm-only mode
- Enhanced LLM response with detailed topics and filename slugs
- Fail-fast error handling with actionable suggestions
- 2-mode system: llm-only (default), regex-only (offline)

**Changes**:
- Default mode: `hybrid` → `llm-only`
- Valid modes: 3 modes → 2 modes (hybrid deleted)
- Fallback behavior: Automatic → Fail-fast with clear errors
- Function renamed: `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()`

**Test Results**:
- test_scope_detection.sh: 30/33 passing (90.9%)
- Hybrid mode rejection test added
- Fail-fast scenario tests added

**Related Commits**:
- b306a787: Phase 1 - LLM Prompt and Response Enhancement
- d4cdc9b3: Phase 2 - Hybrid Filename Generation with Validation Fallback
- 5e3a9ebe: Phase 3 - Remove Hybrid Mode and Automatic Regex Fallback
- 226e569a: Phase 4 - Fail-Fast Error Handling
- d2f737bb: Phase 5 - Remove Discovery Reconciliation from Commands
- 28c812a2: Phase 6 - Update Test Suite for 2-Mode System

### 2025-11-12: Initial Implementation

**Implementation**: Plan 670, Phases 1-4 complete
- Core LLM classifier library (290 lines)
- Hybrid integration (198 lines, clean-break rewrite)
- Comprehensive testing (97% A/B pass rate)
- Production implementation (hybrid mode default)

**Performance**:
- Accuracy: 97%+ (vs 92% regex-only)
- Cost: $0.03/month for typical usage
- Latency: p50 < 300ms, p95 < 600ms
- Reliability: 100% (automatic fallback)

**Key Design Decisions**:
1. File-based signaling for LLM invocation (extensible)
2. Confidence threshold fallback (0.7 default)
3. Clean-break rewrite (no v1/v2 wrappers)
4. Three modes: hybrid (default), llm-only, regex-only

**Related Commits**:
- cb7e6ab1: Phase 1 - Core LLM Classifier Library
- 6e6c2c89: Phase 2 Tasks 2.1-2.2 - Hybrid Classifier Integration
- 27af135c: Phase 2 Task 2.3 - Integration Test Suite Rewrite
- e75915ba: Phase 2 Task 2.4 - End-to-End Integration Tests
- 35f2fe8a: Phase 3 - Comprehensive Testing & Verification
- 6258a046: Phase 4 - Production Implementation
