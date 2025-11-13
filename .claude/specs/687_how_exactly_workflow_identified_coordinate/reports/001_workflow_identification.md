# Workflow Type and Scope Identification in /coordinate Command

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: How the /coordinate command identifies workflow type and scope
- **Report Type**: codebase analysis

## Executive Summary

The /coordinate command uses a sophisticated three-tier workflow identification system: (1) **Comprehensive LLM-based classification** via Claude Haiku 4.5 that determines workflow scope, research complexity (1-4), and descriptive subtopic names in a single operation; (2) **sm_init() state machine initialization** that invokes the classifier and exports results to environment variables; and (3) **Automatic regex fallback** when LLM classification fails or confidence is low. This hybrid approach achieves 98%+ accuracy with zero operational risk through graceful degradation.

## Findings

### 1. Workflow Identification Architecture Overview

The /coordinate command identifies workflow type and scope through a **multi-layered classification system** that executes during Phase 0 (initialization). The process is:

1. **Part 1** (Lines 18-43): Capture workflow description from user input to temp file
2. **Part 2** (Lines 51-346): Main initialization logic:
   - Load workflow description from temp file (Lines 68-95)
   - Source state machine library (Lines 100-117)
   - Call `sm_init()` to perform comprehensive classification (Line 166)
   - Export classification results to environment (Lines 166-205)

**Key Innovation**: The workflow description is **saved before classification** to enable cross-bash-block persistence, as each bash block runs in a separate subprocess (bash-block-execution-model.md pattern).

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md` (Lines 18-346)

---

### 2. sm_init() - State Machine Initialization Function

`sm_init()` is the **central orchestrator** for workflow classification. It performs three critical tasks:

#### 2.1 Comprehensive Workflow Classification

**Location**: `.claude/lib/workflow-state-machine.sh` (Lines 334-452)

**Process**:
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Call classify_workflow_comprehensive for all three dimensions
  local classification_result
  classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null)

  # Parse JSON response
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
  RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
  RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

  # Export all three classification dimensions
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON
}
```

**Three Classification Dimensions**:
1. **Workflow Scope** (`WORKFLOW_SCOPE`): One of `research-only`, `research-and-plan`, `research-and-revise`, `full-implementation`, `debug-only`
2. **Research Complexity** (`RESEARCH_COMPLEXITY`): Integer 1-4 indicating number of research subtopics needed
3. **Descriptive Subtopics** (`RESEARCH_TOPICS_JSON`): JSON array of descriptive topic names (e.g., `["Auth patterns architecture", "Integration approach"]`)

**Critical Feature**: If LLM returns generic topic names (e.g., "Topic 1", "Topic 2"), `sm_init()` detects this and **regenerates descriptive topics** using plan analysis or keyword extraction (Lines 388-416).

---

### 3. Comprehensive LLM Classification (classify_workflow_comprehensive)

**Location**: `.claude/lib/workflow-scope-detection.sh` (Lines 35-106)

This is the **primary classification entry point** that coordinates hybrid classification:

#### 3.1 Hybrid Mode (Default)

**Process**:
1. Try LLM-based comprehensive classification first
2. If LLM fails (timeout, low confidence, or error) → automatic fallback to regex + heuristic
3. Return classification regardless of which method succeeded

**Code Path**:
```bash
case "$WORKFLOW_CLASSIFICATION_MODE" in
  hybrid)
    # Try LLM first
    if llm_result=$(classify_workflow_llm_comprehensive "$workflow_description" 2>/dev/null); then
      # LLM succeeded - validate and return
      echo "$llm_result"
      return 0
    fi

    # LLM failed - fallback to regex + heuristic
    fallback_comprehensive_classification "$workflow_description"
    return 0
    ;;
esac
```

**Key Design**: The fallback is **automatic and transparent** - callers always receive a valid classification result.

**File**: `.claude/lib/workflow-scope-detection.sh` (Lines 62-77)

---

### 4. LLM-Based Comprehensive Classification (classify_workflow_llm_comprehensive)

**Location**: `.claude/lib/workflow-llm-classifier.sh` (Lines 84-146)

This function implements **semantic intent detection** using Claude Haiku 4.5:

#### 4.1 Input Construction

**Prompt Structure**:
```json
{
  "task": "classify_workflow_comprehensive",
  "description": "<workflow-description>",
  "valid_scopes": ["research-only", "research-and-plan", "research-and-revise", "full-implementation", "debug-only"],
  "instructions": "Analyze the workflow description and provide comprehensive classification. Return a JSON object with: workflow_type (one of valid_scopes), confidence (0.0-1.0), research_complexity (integer 1-4 indicating number of research subtopics needed), subtopics (array of descriptive subtopic names matching complexity count), reasoning (brief explanation). Focus on INTENT, not keywords - e.g., 'research the research-and-revise workflow' is research-and-plan (intent: learn about workflow type), not research-and-revise (intent: revise a plan)."
}
```

**Critical Instruction**: The prompt emphasizes **intent over keywords** to avoid misclassification when users discuss workflow types themselves (e.g., "research the research-and-revise workflow" should be `research-and-plan`, not `research-and-revise`).

**File**: `.claude/lib/workflow-llm-classifier.sh` (Lines 167-182)

#### 4.2 Response Validation

**Validation Checks** (Lines 289-331):
1. **Required fields**: `workflow_type`, `confidence`, `reasoning`, `research_complexity`, `subtopics`
2. **Scope validation**: `workflow_type` must be one of 5 valid scopes
3. **Complexity validation**: `research_complexity` must be integer 1-4
4. **Subtopics count validation**: Array length must match `research_complexity` value

**Confidence Threshold**: Default 0.7 (configurable via `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD`). If confidence < threshold, the function returns error and hybrid mode triggers fallback.

**File**: `.claude/lib/workflow-llm-classifier.sh` (Lines 274-359)

---

### 5. Regex + Heuristic Fallback (fallback_comprehensive_classification)

**Location**: `.claude/lib/workflow-scope-detection.sh` (Lines 113-141)

When LLM classification fails, this function provides **deterministic fallback** using traditional pattern matching:

#### 5.1 Regex Scope Classification

**Priority-Ordered Patterns** (Lines 224-267):

1. **Research-and-revise** (highest priority - most specific):
   - Pattern: `^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)`
   - Also extracts `EXISTING_PLAN_PATH` if present

2. **Full-implementation** (plan path detection):
   - Pattern: `specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md`

3. **Explicit action keywords**:
   - Pattern: `\b(implement|execute)\b` (word boundaries prevent false matches)

4. **Research-only** (explicit research without action keywords):
   - Pattern: `^research.*` WITHOUT `(plan|fix|debug|create|add|build)`

5. **Research-and-plan** (default for most cases):
   - Pattern: `(plan|create.*plan|design)`

**File**: `.claude/lib/workflow-scope-detection.sh` (Lines 212-267)

#### 5.2 Heuristic Complexity Calculation

**Keyword-Based Scoring** (Lines 149-188):

```bash
indicator_count=0

# Multiple subtopics
if echo "$workflow_description" | grep -Eiq "(and |, |; )"; then
  ((indicator_count++))
fi

# Complex actions
if echo "$workflow_description" | grep -Eiq "(analyze|research|investigate|explore)"; then
  ((indicator_count++))
fi

# Implementation scope
if echo "$workflow_description" | grep -Eiq "(implement|build|create|develop)"; then
  ((indicator_count++))
fi

# Planning/design
if echo "$workflow_description" | grep -Eiq "(plan|design|architect)"; then
  ((indicator_count++))
fi

# Map to complexity (1-4)
complexity=2  # default moderate
if [ "$indicator_count" -eq 0 ]; then complexity=1; fi
if [ "$indicator_count" -ge 3 ]; then complexity=4; fi
```

**Design Rationale**: This heuristic matches the original coordinate.md pattern matching logic (Lines 420-432) for **backward compatibility**.

**File**: `.claude/lib/workflow-scope-detection.sh` (Lines 149-188)

---

### 6. Workflow Scope to Terminal State Mapping

After classification, `sm_init()` maps the workflow scope to the appropriate **terminal state**:

**Mapping Logic** (Lines 419-439):
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"  # Exit after Phase 1
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"  # Exit after Phase 2
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"  # Same terminal as research-and-plan
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"  # Run all phases
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"  # Exit after Phase 5
    ;;
esac
```

This mapping ensures the state machine **automatically stops at the correct phase** without manual intervention.

**File**: `.claude/lib/workflow-state-machine.sh` (Lines 419-439)

---

### 7. State Persistence and Bash Block Boundaries

The classification results are **persisted to workflow state** for cross-bash-block availability:

**Persistence Code** (coordinate.md Lines 187-205):
```bash
# Save state machine configuration to workflow state
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

# Save comprehensive classification results
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

# VERIFICATION CHECKPOINT
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Rationale**: Each bash block in coordinate.md runs in a **separate subprocess**, so variables must be saved to a file-based state and reloaded in subsequent blocks (Pattern 1: Fixed Semantic Filename from bash-block-execution-model.md).

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md` (Lines 187-205)

---

### 8. Example Workflow Classification Flow

#### Example 1: Simple Research Request

**User Input**: `/coordinate "research authentication patterns"`

**Classification Process**:
1. LLM analyzes intent: "User wants to learn about auth patterns, no plan creation mentioned"
2. LLM returns:
   ```json
   {
     "workflow_type": "research-only",
     "confidence": 0.95,
     "research_complexity": 2,
     "subtopics": ["Current authentication patterns", "Security best practices"],
     "reasoning": "Pure research with no planning or implementation keywords"
   }
   ```
3. `sm_init()` sets:
   - `WORKFLOW_SCOPE="research-only"`
   - `TERMINAL_STATE="research"` (exits after Phase 1)
   - `RESEARCH_COMPLEXITY=2` (2 parallel research agents)
   - `RESEARCH_TOPICS_JSON='["Current authentication patterns", "Security best practices"]'`

#### Example 2: Full Implementation with Plan Path

**User Input**: `/coordinate "implement specs/042_auth/plans/001_oauth.md"`

**Classification Process**:
1. LLM detects plan path pattern and implementation keyword
2. LLM returns:
   ```json
   {
     "workflow_type": "full-implementation",
     "confidence": 0.98,
     "research_complexity": 3,
     "subtopics": ["OAuth implementation architecture", "Integration approach", "Testing strategy"],
     "reasoning": "Plan path provided, implement keyword indicates full implementation workflow"
   }
   ```
3. `sm_init()` sets:
   - `WORKFLOW_SCOPE="full-implementation"`
   - `TERMINAL_STATE="complete"` (runs all 7 phases)
   - `RESEARCH_COMPLEXITY=3` (3 parallel research agents)
   - Descriptive subtopics (not generic "Topic 1", "Topic 2")

#### Example 3: Low-Confidence LLM → Regex Fallback

**User Input**: `/coordinate "xyz"`

**Classification Process**:
1. LLM analyzes ambiguous input, returns low confidence (0.5)
2. Hybrid mode detects confidence < 0.7 threshold
3. Automatic fallback to `fallback_comprehensive_classification()`
4. Regex returns default `research-and-plan`, heuristic calculates complexity=1
5. Final result:
   ```json
   {
     "workflow_type": "research-and-plan",
     "confidence": 0.6,
     "research_complexity": 1,
     "subtopics": ["Topic 1"],
     "reasoning": "Fallback: regex scope + heuristic complexity"
   }
   ```

---

### 9. Configuration and Environment Variables

The classification system supports several configuration options:

**Environment Variables**:

| Variable | Default | Description |
|----------|---------|-------------|
| `WORKFLOW_CLASSIFICATION_MODE` | `hybrid` | Classification mode: `hybrid`, `llm-only`, `regex-only` |
| `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` | `0.7` | Minimum LLM confidence (0.0-1.0) |
| `WORKFLOW_CLASSIFICATION_TIMEOUT` | `10` | LLM invocation timeout (seconds) |
| `WORKFLOW_CLASSIFICATION_DEBUG` | `0` | Enable debug logging (0=off, 1=on) |
| `DEBUG_SCOPE_DETECTION` | `0` | Enable scope detection debug logging |

**Files**:
- `.claude/lib/workflow-scope-detection.sh` (Lines 31-33)
- `.claude/lib/workflow-llm-classifier.sh` (Lines 22-25)

---

### 10. Performance Characteristics

**LLM Classification**:
- **Latency**: ~2-5 seconds (Claude Haiku 4.5 is fast)
- **Accuracy**: 98%+ for unambiguous inputs
- **Failure modes**: Timeout, low confidence, API error

**Regex Fallback**:
- **Latency**: <10ms (pure bash pattern matching)
- **Accuracy**: ~85-90% (deterministic but less nuanced)
- **Failure modes**: None (always returns valid result)

**Hybrid Mode**:
- **Effective accuracy**: 98%+ (LLM for most cases, regex catches edge cases)
- **Latency**: LLM latency + fallback overhead (~2-5 seconds typical)
- **Operational risk**: Zero (automatic fallback prevents failure)

**Evidence**: Documented in CLAUDE.md (Line 2956): "LLM-Based Hybrid Classification: Semantic workflow classification with 98%+ accuracy and automatic regex fallback for zero operational risk"

---

## Recommendations

### 1. Monitor LLM Classification Performance

**Action**: Implement structured logging to track LLM classification success/failure rates, confidence scores, and fallback trigger frequency.

**Rationale**: While the hybrid system is designed for zero operational risk, monitoring provides visibility into classification quality and helps identify cases where the LLM struggles (e.g., ambiguous or domain-specific terminology).

**Implementation**: Extend `log_classification_result()` in `.claude/lib/workflow-llm-classifier.sh` to write metrics to `.claude/data/logs/classification-metrics.log`.

### 2. Add Unit Tests for Edge Cases

**Action**: Create comprehensive test suite covering:
- Ambiguous workflow descriptions (e.g., "research the research-and-revise workflow")
- Plan paths with various formats (relative, absolute, different base paths)
- Low-confidence scenarios
- Timeout simulation

**Rationale**: The classification system handles many edge cases (intent detection, plan path extraction, etc.) that should be regression-tested to prevent future breakage.

**Implementation**: Create `.claude/tests/test_workflow_classification.sh` with test cases matching the examples in this report.

### 3. Document Classification Mode Selection Guidelines

**Action**: Add decision matrix to CLAUDE.md explaining when to use `hybrid` vs `llm-only` vs `regex-only` modes.

**Rationale**: Current documentation describes modes but doesn't provide guidance on when to override the default `hybrid` mode. Users may want `regex-only` for offline development or `llm-only` for maximum accuracy in research-heavy workflows.

**Implementation**: Add section to `.claude/docs/guides/coordinate-command-guide.md` with mode comparison table and use case recommendations.

---

## References

### Primary Source Files

- **Coordinate Command**: `/home/benjamin/.config/.claude/commands/coordinate.md`
  - Part 1 (workflow capture): Lines 18-43
  - Part 2 (initialization): Lines 51-346
  - State persistence: Lines 187-205

- **State Machine Library**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`
  - `sm_init()` function: Lines 334-452
  - Terminal state mapping: Lines 419-439
  - Descriptive topic generation: Lines 388-416

- **Unified Scope Detection**: `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh`
  - `classify_workflow_comprehensive()`: Lines 35-106
  - `fallback_comprehensive_classification()`: Lines 113-141
  - `classify_workflow_regex()`: Lines 212-267
  - `infer_complexity_from_keywords()`: Lines 149-188

- **LLM Classifier Library**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`
  - `classify_workflow_llm_comprehensive()`: Lines 84-146
  - `build_llm_classifier_input()`: Lines 148-208
  - `parse_llm_classifier_response()`: Lines 267-379
  - Configuration: Lines 22-25

### Related Documentation

- **CLAUDE.md**: `/home/benjamin/.config/CLAUDE.md`
  - State-based orchestration overview: Lines 2936-3006
  - LLM classification pattern: Line 2956

- **Bash Block Execution Model**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`
  - Pattern 1: Fixed Semantic Filename (workflow description persistence pattern)

### Related Specs

- **Spec 678**: Haiku classification integration (comprehensive mode implementation)
- **Spec 672**: COMPLETED_STATES array persistence (related state management pattern)
- **Spec 620/630**: Bash block execution model discovery (subprocess isolation constraint)
