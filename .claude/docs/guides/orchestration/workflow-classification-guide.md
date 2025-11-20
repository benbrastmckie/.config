# Workflow Classification Guide (LLM-Only)

**Path**: docs → guides → workflow-classification-guide.md

**IMPORTANT**: This document describes the historical 2-mode system. **regex-only mode has been removed** (Spec 704 Phase 4). The system now uses **LLM-only classification** with fail-fast error handling.

Complete guide to LLM-based workflow classification with fail-fast error handling.

## Overview

The workflow classification system determines the appropriate phases and research complexity for user workflows by analyzing workflow descriptions using LLM-based semantic understanding.

**BREAKING CHANGES**:
- Spec 688: Hybrid mode with automatic regex fallback was removed
- Spec 704 Phase 4: regex-only mode was removed

The system now uses **llm-only mode exclusively** with fail-fast error handling providing clear error messages when classification fails.

## 2-Mode System Architecture

### llm-only Mode (Default)

**Purpose**: High-accuracy semantic classification for online development

**How It Works**:
1. Sends workflow description to LLM (Claude Haiku 4.5)
2. LLM returns structured classification with enhanced topics
3. On success: Returns classification result
4. On failure: **Fails fast with actionable error message** (no automatic fallback)

**Use When**:
- Online development with network connectivity
- Semantic edge cases need accurate classification
- Enhanced topic generation is needed
- You want 98%+ classification accuracy

**Error Handling**:
```bash
# LLM-only mode fails fast on errors
if ! result=$(classify_workflow_comprehensive "$description" 2>&1); then
  # Error message includes:
  # - What failed (timeout, API error, low confidence)
  # - Context (workflow description)
  # - Actionable suggestion (increase timeout, use regex-only, etc.)
  echo "ERROR: LLM classification failed"
  echo "  Suggestion: Use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline work"
  exit 1
fi
```

### regex-only Mode (Offline)

**Purpose**: Deterministic classification for offline/testing environments

**How It Works**:
1. Analyzes workflow description with regex patterns
2. Detects keywords and patterns (plan, implement, debug, etc.)
3. Returns classification based on keyword priority
4. Always succeeds (100% availability)

**Use When**:
- Offline/air-gapped development
- Testing and CI/CD environments
- LLM API unavailable or unreliable
- Deterministic behavior required

**Characteristics**:
- Fast (<10ms latency)
- No external dependencies
- 92% accuracy (vs 98%+ for LLM)
- Struggles with semantic edge cases

## Mode Selection

### Default Behavior

```bash
# Default mode is llm-only (set in workflow-scope-detection.sh)
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-llm-only}"

# Classification uses default if not explicitly set
result=$(classify_workflow_comprehensive "$description")
```

### Explicit Mode Selection

**Environment Variable**:
```bash
# Set globally for session
export WORKFLOW_CLASSIFICATION_MODE=llm-only     # Default
export WORKFLOW_CLASSIFICATION_MODE=regex-only   # Offline

# Use in script
WORKFLOW_CLASSIFICATION_MODE=regex-only /coordinate "implement feature"
```

**Per-Command Override**:
```bash
# Override for single invocation
WORKFLOW_CLASSIFICATION_MODE=regex-only \
  classify_workflow_comprehensive "research authentication"
```

### Mode Selection Decision Tree

```
Are you online with network connectivity?
│
├─ YES → LLM-only mode (default)
│         ├─ Best accuracy (98%+)
│         ├─ Enhanced topic generation
│         └─ Semantic edge case handling
│
└─ NO → regex-only mode
          ├─ Air-gapped environments
          ├─ Unreliable network
          └─ Offline development
```

## Configuration

### Environment Variables

```bash
# Classification mode (default: llm-only)
WORKFLOW_CLASSIFICATION_MODE="llm-only"  # llm-only | regex-only

# LLM timeout in seconds (default: 10)
WORKFLOW_CLASSIFICATION_TIMEOUT="10"

# Debug logging (default: 0)
WORKFLOW_CLASSIFICATION_DEBUG="0"  # 0=disabled, 1=enabled
```

**Removed Variables** (clean-break):
- `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` - LLM validation now handled internally
- Hybrid mode support - No longer valid

### Configuration Validation

```bash
# Invalid mode detection
WORKFLOW_CLASSIFICATION_MODE="hybrid"
result=$(classify_workflow_comprehensive "test" 2>&1)
# ERROR: Invalid WORKFLOW_CLASSIFICATION_MODE='hybrid'
#   Valid modes: llm-only (default), regex-only
#   Note: hybrid mode removed in clean-break update

# Valid modes
WORKFLOW_CLASSIFICATION_MODE="llm-only"    # ✓ Valid
WORKFLOW_CLASSIFICATION_MODE="regex-only"  # ✓ Valid
WORKFLOW_CLASSIFICATION_MODE="hybrid"      # ✗ Rejected
```

## Classification Results

### Workflow Types

Both modes return the same workflow types:

1. **research-only**: Pure research, no action (Phases 0, 1)
2. **research-and-plan**: Research + planning (Phases 0, 1, 2)
3. **research-and-revise**: Research + plan revision (Phases 0, 1, 2)
4. **full-implementation**: Complete workflow (Phases 0, 1, 2, 3, 4, 6)
5. **debug-only**: Debugging workflow (Phases 0, 1, 5)

### Response Format

**llm-only mode**:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Implementation architecture",
      "detailed_description": "Analyze current implementation...",
      "filename_slug": "implementation_architecture",
      "research_focus": "Key questions: How is..."
    }
  ],
  "reasoning": "Workflow requires research and planning..."
}
```

**regex-only mode**:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 1.0,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Topic 1",
      "detailed_description": "Research topic based on workflow description",
      "filename_slug": "topic_1",
      "research_focus": "Investigate key aspects of the workflow"
    }
  ],
  "reasoning": "Detected 'plan' keyword in description"
}
```

**Key Differences**:
- **llm-only**: Rich, semantic topics with detailed descriptions and specific focus areas
- **regex-only**: Generic topics with basic descriptions, sequential filenames

## Error Handling (Fail-Fast)

### llm-only Mode Errors

**Timeout Error**:
```bash
ERROR: LLM classification timed out after 10s
  Workflow: research authentication patterns
  Suggestion: Increase WORKFLOW_CLASSIFICATION_TIMEOUT or use regex-only mode
```

**API Error**:
```bash
ERROR: LLM API unavailable
  Workflow: implement feature
  Suggestion: Check network connection or use regex-only mode for offline work
```

**Empty Input**:
```bash
ERROR: Empty workflow description provided
  Suggestion: Provide a non-empty description of the workflow
```

**Invalid Mode**:
```bash
ERROR: Invalid WORKFLOW_CLASSIFICATION_MODE='hybrid'
  Valid modes: llm-only (default), regex-only
  Note: hybrid mode removed in clean-break update
```

### Error Recovery Strategies

**Strategy 1: Retry with Timeout Increase**:
```bash
# First attempt with default timeout
if ! result=$(classify_workflow_comprehensive "$description" 2>/dev/null); then
  echo "LLM timeout, retrying with increased timeout..." >&2
  WORKFLOW_CLASSIFICATION_TIMEOUT=20 \
    result=$(classify_workflow_comprehensive "$description")
fi
```

**Strategy 2: Fallback to regex-only**:
```bash
# Try LLM first, fallback to regex on failure
if ! result=$(classify_workflow_comprehensive "$description" 2>/dev/null); then
  echo "LLM failed, using regex-only mode..." >&2
  WORKFLOW_CLASSIFICATION_MODE=regex-only \
    result=$(classify_workflow_comprehensive "$description")
fi
```

**Strategy 3: Prompt User**:
```bash
# Let user choose on LLM failure
if ! result=$(classify_workflow_comprehensive "$description" 2>&1); then
  echo "LLM classification failed. Options:"
  echo "  1. Retry with increased timeout"
  echo "  2. Use regex-only mode"
  echo "  3. Exit"
  read -p "Choose (1-3): " choice
  # Handle user choice...
fi
```

## Migration from Hybrid Mode

### What Changed (Clean-Break)

**Removed**:
- `WORKFLOW_CLASSIFICATION_MODE=hybrid` - Mode deleted entirely
- Automatic regex fallback from llm-only mode
- `fallback_comprehensive_classification()` function (renamed)
- `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` variable

**Added**:
- Fail-fast error handling with actionable messages
- Enhanced topic generation (research_topics array)
- Detailed descriptions and filename slugs
- Clear mode validation and error messages

**Renamed**:
- `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()`
  - Clarifies it's an intentional regex classifier, not a fallback

### Before (Hybrid Mode)

```bash
# Old hybrid mode (REMOVED)
WORKFLOW_CLASSIFICATION_MODE=hybrid
result=$(detect_workflow_scope "$description")
# Automatically fell back to regex on LLM failure
```

### After (2-Mode System)

```bash
# New llm-only mode (DEFAULT)
WORKFLOW_CLASSIFICATION_MODE=llm-only  # or omit (default)
if ! result=$(classify_workflow_comprehensive "$description" 2>&1); then
  # Fails fast with clear error message
  # Manual fallback if desired:
  WORKFLOW_CLASSIFICATION_MODE=regex-only \
    result=$(classify_workflow_comprehensive "$description")
fi
```

### Migration Checklist

- [ ] Remove `WORKFLOW_CLASSIFICATION_MODE=hybrid` from scripts
- [ ] Add error handling for LLM failures
- [ ] Update mode to `llm-only` (or remove, it's default)
- [ ] For offline environments, explicitly set `regex-only`
- [ ] Update calls from `detect_workflow_scope()` to `classify_workflow_comprehensive()` (or use backward-compatible wrapper)
- [ ] Remove `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` (no longer used)
- [ ] Update function calls from `fallback_comprehensive_classification()` to `classify_workflow_regex_comprehensive()`

## Usage Examples

### Example 1: Basic Classification (Default llm-only)

```bash
#!/usr/bin/env bash
source .claude/lib/workflow/workflow-scope-detection.sh

# Default llm-only mode
description="research authentication patterns and create implementation plan"
result=$(classify_workflow_comprehensive "$description")

# Extract workflow type
workflow_type=$(echo "$result" | jq -r '.workflow_type')
echo "Workflow type: $workflow_type"  # research-and-plan

# Extract research topics
topics=$(echo "$result" | jq -r '.research_topics[].short_name')
echo "Topics: $topics"
```

### Example 2: Offline Development (regex-only)

```bash
#!/usr/bin/env bash
# Air-gapped environment configuration
export WORKFLOW_CLASSIFICATION_MODE=regex-only

source .claude/lib/workflow/workflow-scope-detection.sh

# Classification works offline
description="implement user authentication"
result=$(classify_workflow_comprehensive "$description")

workflow_type=$(echo "$result" | jq -r '.workflow_type')
echo "Workflow type: $workflow_type"  # full-implementation
```

### Example 3: Error Handling with Manual Fallback

```bash
#!/usr/bin/env bash
source .claude/lib/workflow/workflow-scope-detection.sh

classify_with_fallback() {
  local description="$1"
  local result

  # Try LLM first
  echo "Attempting LLM classification..." >&2
  if result=$(classify_workflow_comprehensive "$description" 2>&1); then
    echo "LLM classification succeeded" >&2
    echo "$result"
    return 0
  fi

  # LLM failed, use regex
  echo "LLM failed, falling back to regex-only..." >&2
  WORKFLOW_CLASSIFICATION_MODE=regex-only \
    result=$(classify_workflow_comprehensive "$description")

  echo "Regex classification succeeded" >&2
  echo "$result"
  return 0
}

# Usage
description="research and plan authentication feature"
result=$(classify_with_fallback "$description")
```

### Example 4: Testing Both Modes (A/B Testing)

```bash
#!/usr/bin/env bash
source .claude/lib/workflow/workflow-scope-detection.sh

description="research the coordinate command implementation"

# Test LLM mode
echo "=== LLM-only Mode ==="
WORKFLOW_CLASSIFICATION_MODE=llm-only
llm_result=$(classify_workflow_comprehensive "$description")
llm_type=$(echo "$llm_result" | jq -r '.workflow_type')
echo "LLM result: $llm_type"

# Test regex mode
echo "=== regex-only Mode ==="
WORKFLOW_CLASSIFICATION_MODE=regex-only
regex_result=$(classify_workflow_comprehensive "$description")
regex_type=$(echo "$regex_result" | jq -r '.workflow_type')
echo "Regex result: $regex_type"

# Compare
if [ "$llm_type" = "$regex_type" ]; then
  echo "Agreement: Both classified as $llm_type"
else
  echo "Disagreement: LLM=$llm_type, Regex=$regex_type"
fi
```

### Example 5: Enhanced Topic Usage

```bash
#!/usr/bin/env bash
source .claude/lib/workflow/workflow-scope-detection.sh

description="implement OAuth2 authentication with JWT tokens"
result=$(classify_workflow_comprehensive "$description")

# Extract enhanced topics
research_topics=$(echo "$result" | jq -r '.research_topics')

# Process each topic
echo "$research_topics" | jq -c '.[]' | while read topic; do
  short_name=$(echo "$topic" | jq -r '.short_name')
  detailed_desc=$(echo "$topic" | jq -r '.detailed_description')
  filename_slug=$(echo "$topic" | jq -r '.filename_slug')
  research_focus=$(echo "$topic" | jq -r '.research_focus')

  echo "=== Topic: $short_name ==="
  echo "Description: $detailed_desc"
  echo "Focus: $research_focus"
  echo "Output: reports/${filename_slug}.md"
  echo ""
done
```

## Performance Comparison

### Accuracy

| Metric | regex-only | llm-only | Improvement |
|--------|------------|----------|-------------|
| Overall Accuracy | 92% | 98%+ | +6% |
| Edge Case Accuracy | 60% | 95%+ | +35% |
| False Positive Rate | 8% | <2% | -6% |

### Latency

| Mode | p50 | p95 | p99 | Notes |
|------|-----|-----|-----|-------|
| regex-only | <10ms | <10ms | <10ms | Deterministic |
| llm-only | <300ms | <600ms | <1000ms | Network dependent |

### Cost

| Mode | Cost per Classification | Monthly Cost (100/day) |
|------|------------------------|------------------------|
| regex-only | $0 | $0 |
| llm-only | ~$0.00003 | ~$0.03 |

### Availability

| Mode | Availability | Dependencies |
|------|--------------|--------------|
| regex-only | 100% | None |
| llm-only | 95-98% | Network, LLM API |

## Best Practices

### 1. Use llm-only by Default

```bash
# GOOD: Use default llm-only for best accuracy
result=$(classify_workflow_comprehensive "$description")

# AVOID: Unnecessary explicit setting
WORKFLOW_CLASSIFICATION_MODE=llm-only
result=$(classify_workflow_comprehensive "$description")
```

### 2. Handle LLM Failures Gracefully

```bash
# GOOD: Handle errors with clear feedback
if ! result=$(classify_workflow_comprehensive "$description" 2>&1); then
  echo "ERROR: Classification failed. Using regex-only mode." >&2
  WORKFLOW_CLASSIFICATION_MODE=regex-only \
    result=$(classify_workflow_comprehensive "$description")
fi

# BAD: Ignore errors
result=$(classify_workflow_comprehensive "$description")  # Breaks on LLM failure
```

### 3. Use regex-only for Offline Environments

```bash
# GOOD: Explicitly set for offline work
export WORKFLOW_CLASSIFICATION_MODE=regex-only  # Air-gapped environment

# GOOD: CI/CD deterministic testing
WORKFLOW_CLASSIFICATION_MODE=regex-only make test
```

### 4. Increase Timeout for Slow Networks

```bash
# GOOD: Adjust timeout for high-latency networks
export WORKFLOW_CLASSIFICATION_TIMEOUT=20

# GOOD: Per-command override
WORKFLOW_CLASSIFICATION_TIMEOUT=15 \
  classify_workflow_comprehensive "$description"
```

### 5. Validate Mode Configuration

```bash
# GOOD: Validate before using
case "${WORKFLOW_CLASSIFICATION_MODE:-llm-only}" in
  llm-only|regex-only)
    # Valid mode
    ;;
  *)
    echo "ERROR: Invalid mode: $WORKFLOW_CLASSIFICATION_MODE" >&2
    exit 1
    ;;
esac
```

## Troubleshooting

### Issue: "hybrid mode removed" Error

**Symptom**:
```
ERROR: Invalid WORKFLOW_CLASSIFICATION_MODE='hybrid'
  Note: hybrid mode removed in clean-break update
```

**Solution**:
```bash
# Remove hybrid mode setting
unset WORKFLOW_CLASSIFICATION_MODE  # Use default llm-only

# Or explicitly set valid mode
export WORKFLOW_CLASSIFICATION_MODE=llm-only
```

### Issue: LLM Timeouts

**Symptom**:
```
ERROR: LLM classification timed out after 10s
```

**Solutions**:
1. Increase timeout:
   ```bash
   export WORKFLOW_CLASSIFICATION_TIMEOUT=20
   ```

2. Check network connectivity:
   ```bash
   ping api.anthropic.com
   ```

3. Use regex-only for offline work:
   ```bash
   export WORKFLOW_CLASSIFICATION_MODE=regex-only
   ```

### Issue: LLM API Unavailable

**Symptom**:
```
ERROR: LLM API unavailable
```

**Solutions**:
1. Check network connection
2. Verify API key (if required)
3. Use regex-only mode:
   ```bash
   WORKFLOW_CLASSIFICATION_MODE=regex-only /coordinate "task"
   ```

### Issue: Disagreement Between Modes

**Symptom**: LLM and regex produce different workflow types

**Diagnosis**:
```bash
# Test both modes
for mode in llm-only regex-only; do
  WORKFLOW_CLASSIFICATION_MODE=$mode \
    result=$(classify_workflow_comprehensive "$description")
  echo "$mode: $(echo "$result" | jq -r '.workflow_type')"
done
```

**Analysis**:
- LLM handles semantic edge cases better
- Regex relies on keyword presence
- Disagreements often on quoted keywords, negations, or context

**Solution**: Trust LLM result for semantic accuracy, use regex for deterministic testing

## References

### Implementation Files
- [workflow-scope-detection.sh](../../lib/workflow/workflow-scope-detection.sh) - Main classification library
- [workflow-llm-classifier.sh](../../lib/workflow/workflow-llm-classifier.sh) - LLM classifier implementation
- [workflow-detection.sh](../../lib/workflow/workflow-detection.sh) - /supervise integration

### Testing Files
- [test_scope_detection.sh](../../../tests/test_scope_detection.sh) - Integration tests
- [test_scope_detection_ab.sh](../../../tests/test_scope_detection_ab.sh) - A/B mode comparison
- [bench_workflow_classification.sh](../../../tests/bench_workflow_classification.sh) - Performance benchmarks

### Related Documentation
- [LLM Classification Pattern](../concepts/patterns/llm-classification-pattern.md) - Overall pattern documentation
- [Enhanced Topic Generation Guide](enhanced-topic-generation-guide.md) - Topic structure details
- [Implementation Plan](../../specs/688_687_how_exactly_workflow_identified_coordinate/plans/001_fallback_removal_llm_enhancements.md) - Complete implementation history

## Changelog

### 2025-11-13: Clean-Break Update

**Created**: Complete guide for 2-mode classification system (Spec 688)

**Coverage**:
- 2-mode architecture (llm-only, regex-only)
- Mode selection and configuration
- Error handling and fail-fast behavior
- Migration from hybrid mode
- Usage examples and best practices
- Performance comparison and troubleshooting

**Breaking Changes Documented**:
- Hybrid mode removal
- Automatic fallback removal
- Function renaming
- Environment variable changes
