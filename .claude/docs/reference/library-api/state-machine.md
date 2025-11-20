# Library API Reference - State Machine

Workflow classification and scope detection libraries.

## Navigation

This document is part of a multi-part reference:
- [Overview](overview.md) - Purpose, quick index, core utilities
- **State Machine** (this file) - Workflow classification and scope detection
- [Persistence](library-api-persistence.md) - State persistence and checkpoint utilities
- [Utilities](library-api-utilities.md) - Agent support, workflow support, analysis, and complete library list

---

## Workflow Classification

### workflow-llm-classifier.sh

LLM-based semantic workflow classification using Claude Haiku 4.5 for high-accuracy intent detection. Returns enhanced topics with detailed descriptions, filename slugs, and research focus areas.

**Pattern**: Semantic understanding with confidence thresholds
**Accuracy**: 98%+ (vs 92% regex-only)
**Cost**: $0.03/month for typical usage (100 classifications/day)
**Test Coverage**: 37 tests, 100% pass rate (35 passing, 2 skipped for manual integration)
**Dependencies**: `jq` (JSON parsing), AI assistant file-based signaling

**When to Use**:
- Semantic ambiguity in user input (e.g., "research the implement command" vs "implement feature")
- Keyword context confusion (discussing vs requesting workflow types)
- Negation handling (e.g., "don't revise the plan")
- Edge cases expensive to handle with regex patterns

**When NOT to Use**:
- Structured data parsing (file paths, explicit flags)
- Performance-critical hot paths (<1ms required)
- Deterministic classification sufficient
- Offline/air-gapped environments

#### Core Functions

##### `classify_workflow_llm(workflow_description)`

Invoke LLM classifier with timeout and confidence validation.

**Parameters**:
- `workflow_description` (string): User workflow description to classify

**Returns**: JSON object with `scope`, `confidence`, `reasoning` fields (or exits with code 1 for fallback)

**Exit Codes**:
- `0`: Classification successful (confidence >= threshold)
- `1`: Classification failed or low confidence (triggers fallback)

**Example**:
```bash
source .claude/lib/workflow/workflow-llm-classifier.sh

# Semantic edge case (LLM handles better than regex)
result=$(classify_workflow_llm "research the research-and-revise workflow")
scope=$(echo "$result" | jq -r '.scope')  # Expected: "research-only"
confidence=$(echo "$result" | jq -r '.confidence')  # e.g., 0.95
```

##### `build_llm_classifier_input(workflow_description)`

Build JSON prompt for LLM classification request.

**Parameters**:
- `workflow_description` (string): Workflow description

**Returns**: JSON string for LLM request

##### `invoke_llm_classifier(llm_input)`

Invoke AI assistant via file-based signaling with timeout.

**Parameters**:
- `llm_input` (string): JSON classification request

**Returns**: LLM response JSON (or exits with code 1 on timeout)

**Timeout**: Configurable via `WORKFLOW_CLASSIFICATION_TIMEOUT` (default: 10 seconds)

##### `parse_llm_classifier_response(response)`

Validate LLM response and check confidence threshold.

**Parameters**:
- `response` (string): LLM response JSON

**Returns**: Validated response (or exits with code 1 if confidence < threshold)

**Confidence Threshold**: Configurable via `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` (default: 0.7)

---

### workflow-scope-detection.sh

Unified workflow classification with 2-mode system: llm-only (default, online) and regex-only (offline). LLM-only mode uses fail-fast error handling, no automatic fallback.

**Pattern**: 2-mode classification with fail-fast error handling
**Modes**: llm-only (default, online), regex-only (offline)
**Accuracy**: 98%+ (llm-only), 92% (regex-only)
**Reliability**: 95-98% (llm-only), 100% (regex-only)
**Test Coverage**: 33 tests, 90.9% pass rate (30 passing, 1 failure, 2 skipped)
**Dependencies**: `workflow-llm-classifier.sh` (llm-only mode), `jq` (JSON parsing)

**BREAKING CHANGE**: Hybrid mode removed in Spec 688 clean-break update. Use `llm-only` (default) or `regex-only` (offline) explicitly.

**Backward Compatibility**: 100% compatible with existing code (function signature unchanged)

#### Core Functions

##### `detect_workflow_scope(workflow_description)`

Unified workflow classification with automatic mode detection and fallback.

**Parameters**:
- `workflow_description` (string): Workflow description to classify

**Returns**: Scope string (`research-only`, `research-and-plan`, `research-and-revise`, `full-implementation`, `debug-only`)

**Exit Codes**: `0` (always succeeds - fallback ensures reliability)

**Modes** (controlled by `WORKFLOW_CLASSIFICATION_MODE` environment variable):
- `llm-only` (default): LLM classification with fail-fast on errors
- `regex-only`: Traditional regex patterns for offline/testing

**BREAKING**: `hybrid` mode removed - no automatic fallback

**Example**:
```bash
source .claude/lib/workflow/workflow-scope-detection.sh

# llm-only mode (default) - Use classify_workflow_comprehensive
result=$(classify_workflow_comprehensive "research auth patterns and create plan")
scope=$(echo "$result" | jq -r '.workflow_type')
echo "$scope"  # Output: "research-and-plan"

# Backward compatibility wrapper
scope=$(detect_workflow_scope "research auth patterns")
echo "$scope"  # Output: "research-and-plan"

# Regex-only mode for offline
WORKFLOW_CLASSIFICATION_MODE=regex-only \
  scope=$(detect_workflow_scope "implement feature X")
echo "$scope"  # Output: "full-implementation"

# Error handling for LLM failures
if ! result=$(classify_workflow_comprehensive "task" 2>&1); then
  echo "LLM failed, using regex-only..." >&2
  WORKFLOW_CLASSIFICATION_MODE=regex-only \
    result=$(classify_workflow_comprehensive "task")
fi
```

##### `classify_workflow_regex(workflow_description)`

Traditional regex-based classification (embedded fallback logic).

**Parameters**:
- `workflow_description` (string): Workflow description

**Returns**: Scope string (same as `detect_workflow_scope`)

**Pattern Priorities** (ordered by specificity):
1. Research-and-revise patterns (revision-first, explicit revise keywords)
2. Plan path detection (specs/NNN_topic/plans/*.md)
3. Explicit keyword patterns (implement, execute)
4. Research-only pattern (pure research, no action keywords)
5. Other patterns (plan, debug, build)

---

## Related Documentation

- [Overview](overview.md) - Purpose, quick index, core utilities
- [Persistence](library-api-persistence.md) - State persistence and checkpoint utilities
- [Utilities](library-api-utilities.md) - Agent support, workflow support, analysis, and complete library list
- [Coordinate State Management](../architecture/coordinate-state-management-overview.md) - State management architecture
