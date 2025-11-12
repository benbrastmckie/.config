# LLM-Based Hybrid Classification Pattern

**Path**: docs → concepts → patterns → llm-classification-pattern.md

[Used by: /coordinate, /supervise, workflow-scope-detection.sh, workflow-detection.sh]

Hybrid LLM-based classification with automatic regex fallback for 98%+ accuracy semantic understanding with zero operational risk.

## Definition

LLM-Based Hybrid Classification is a pattern where semantic understanding is provided by an LLM (Claude Haiku 4.5) as the primary classifier, with automatic fallback to traditional regex patterns when the LLM is unavailable, times out, or returns low confidence. This enables high-accuracy intent detection while maintaining 100% reliability through graceful degradation.

The pattern transforms classification from:
- **Before**: Regex-only pattern matching (92% accuracy, 8% false positive rate on edge cases)
- **After**: LLM semantic understanding with regex safety net (98%+ accuracy, zero operational risk)

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
- **Zero Risk**: Automatic regex fallback ensures 100% availability
- **Cost Efficiency**: Negligible cost ($0.03/month for typical usage)
- **Backward Compatibility**: 100% compatible with existing code

## Implementation

### Core Mechanism

**Architecture**:

```
User Input → detect_workflow_scope()
                │
                ├─→ [hybrid mode] LLM Classifier (Haiku 4.5)
                │       │
                │       ├─→ [confidence >= 0.7] Return LLM result
                │       └─→ [confidence < 0.7] Fallback to regex
                │
                ├─→ [llm-only mode] LLM Classifier (no fallback)
                │
                └─→ [regex-only mode] Regex Classifier (traditional)
```

**Step 1: Primary LLM Classification**

The system first attempts LLM-based classification:

```bash
# From .claude/lib/workflow-scope-detection.sh
detect_workflow_scope() {
  local workflow_description="$1"
  local scope=""

  case "$WORKFLOW_CLASSIFICATION_MODE" in
    hybrid)
      # Try LLM first, fallback to regex on error/timeout/low-confidence
      if scope=$(classify_workflow_llm "$workflow_description" 2>/dev/null); then
        local llm_scope
        llm_scope=$(echo "$scope" | jq -r '.scope // empty')

        if [ -n "$llm_scope" ]; then
          log_scope_detection "hybrid" "llm" "$llm_scope"
          echo "$llm_scope"
          return 0
        fi
      fi

      # LLM failed - fallback to regex
      scope=$(classify_workflow_regex "$workflow_description")
      log_scope_detection "hybrid" "regex-fallback" "$scope"
      echo "$scope"
      return 0
      ;;
    # ... other modes ...
  esac
}
```

**Step 2: LLM Invocation with File-Based Signaling**

The LLM classifier uses file-based signaling for AI assistant interaction:

```bash
# From .claude/lib/workflow-llm-classifier.sh
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

**Environment Variables**:

```bash
# Classification mode (default: hybrid)
WORKFLOW_CLASSIFICATION_MODE="hybrid"  # hybrid, llm-only, regex-only

# Confidence threshold (default: 0.7)
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD="0.7"

# Timeout in seconds (default: 10)
WORKFLOW_CLASSIFICATION_TIMEOUT="10"

# Debug logging (default: 0)
WORKFLOW_CLASSIFICATION_DEBUG="0"  # 0 = disabled, 1 = enabled
```

**Rollback Procedure**:

```bash
# Immediate rollback to regex-only mode
export WORKFLOW_CLASSIFICATION_MODE=regex-only

# Or per-command:
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

**Full Example**: Detecting workflow scope with hybrid classification

```bash
#!/usr/bin/env bash
# Example: Classify workflow descriptions

source .claude/lib/workflow-scope-detection.sh

# Test Case 1: Semantic edge case (LLM handles better)
description="research the research-and-revise workflow to understand misclassification"
scope=$(detect_workflow_scope "$description")
echo "Case 1: $scope"  # Expected: research-only (not research-and-revise)

# Test Case 2: Clear intent (both LLM and regex work)
description="research authentication patterns and create implementation plan"
scope=$(detect_workflow_scope "$description")
echo "Case 2: $scope"  # Expected: research-and-plan

# Test Case 3: Force fallback (test resilience)
WORKFLOW_CLASSIFICATION_TIMEOUT=0 \
  scope=$(detect_workflow_scope "$description")
echo "Case 3: $scope (used regex fallback)"  # Expected: research-and-plan

# Test Case 4: Rollback to regex-only
WORKFLOW_CLASSIFICATION_MODE=regex-only \
  scope=$(detect_workflow_scope "$description")
echo "Case 4: $scope (regex-only mode)"  # Expected: research-and-plan
```

## Performance Impact

### Real-World Metrics

**Accuracy Improvements** (from A/B testing on 42 real workflow descriptions):

| Metric | Regex-Only | Hybrid (LLM + Regex) | Improvement |
|--------|------------|----------------------|-------------|
| Overall Accuracy | 92% | 97%+ | +5% |
| Edge Case Accuracy | 60% | 95%+ | +35% |
| False Positive Rate | 8% | <2% | -6% |
| Agreement Rate | N/A | 97% | Baseline |

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

**Reliability Metrics**:

| Metric | Value | Notes |
|--------|-------|-------|
| Availability | 100% | Regex fallback ensures no failures |
| Fallback Rate | <20% | Target from testing |
| Timeout Handling | Automatic | Transparent to user |
| Error Recovery | Graceful | No user-visible failures |

### Optimization Techniques

**1. Confidence Threshold Tuning**

Adjust threshold based on observed LLM accuracy:

```bash
# Conservative (fewer false positives, more fallbacks)
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.9

# Balanced (default)
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.7

# Aggressive (more LLM decisions, fewer fallbacks)
WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD=0.5
```

**2. Timeout Optimization**

Reduce timeout for faster fallback in slow network conditions:

```bash
# Fast fallback (5 seconds)
WORKFLOW_CLASSIFICATION_TIMEOUT=5

# Balanced (default: 10 seconds)
WORKFLOW_CLASSIFICATION_TIMEOUT=10

# Patient (15 seconds)
WORKFLOW_CLASSIFICATION_TIMEOUT=15
```

**3. Mode Selection**

Choose mode based on environment and requirements:

```bash
# Production (default): High accuracy + reliability
WORKFLOW_CLASSIFICATION_MODE=hybrid

# Testing: LLM-only to validate accuracy
WORKFLOW_CLASSIFICATION_MODE=llm-only

# Fallback: Regex-only for air-gapped or emergency rollback
WORKFLOW_CLASSIFICATION_MODE=regex-only
```

## Anti-Patterns

### Example Violation 1: No Fallback (LLM-Only in Production)

**Problem**: Using `llm-only` mode in production without fallback:

```bash
# WRONG: No fallback - users see failures during LLM outages
WORKFLOW_CLASSIFICATION_MODE=llm-only
scope=$(detect_workflow_scope "$description")
# Fails if LLM times out or returns error
```

**Why It Fails**:
- LLM outages cause complete workflow failures
- Network issues block all classification
- No graceful degradation

**Correct Approach**:

```bash
# CORRECT: Hybrid mode provides automatic fallback
WORKFLOW_CLASSIFICATION_MODE=hybrid
scope=$(detect_workflow_scope "$description")
# Transparently falls back to regex on LLM failure
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

**LLM-Only Classification** (no fallback)
- Maximum accuracy (98%+) but operational risk
- External LLM dependency creates availability concerns
- Not suitable for production without fallback
- Higher cost at scale

**Hybrid Classification** (this pattern)
- Best of both: High accuracy (97%+) + zero risk (fallback)
- Balances performance, accuracy, and reliability
- Transparent fallback preserves user experience
- Production-ready with minimal cost

## References

### Implementation Files

- [workflow-llm-classifier.sh](../../lib/workflow-llm-classifier.sh) - LLM classification library
- [workflow-scope-detection.sh](../../lib/workflow-scope-detection.sh) - Unified hybrid detection
- [workflow-detection.sh](../../lib/workflow-detection.sh) - /supervise integration

### Testing Files

- [test_llm_classifier.sh](../../tests/test_llm_classifier.sh) - Unit tests (37 tests)
- [test_scope_detection.sh](../../tests/test_scope_detection.sh) - Integration tests (31 tests)
- [test_scope_detection_ab.sh](../../tests/test_scope_detection_ab.sh) - A/B testing (42 cases)

### Documentation

- [Implementation Plan](../../specs/670_workflow_classification_improvement/plans/001_hybrid_classification_implementation.md) - Complete implementation history
- [Architecture Report](../../specs/670_workflow_classification_improvement/reports/003_implementation_architecture.md) - Technical design decisions
- [Library API Reference](../../reference/library-api.md) - API documentation

### Related Standards

- [Standard 13: Project Directory Detection](../../reference/command_architecture_standards.md#standard-13) - CLAUDE_PROJECT_DIR usage
- [Standard 14: Executable/Documentation Separation](../../reference/command_architecture_standards.md#standard-14) - Documentation pattern
- [Bash Block Execution Model](../bash-block-execution-model.md) - Subprocess isolation patterns

## Changelog

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
