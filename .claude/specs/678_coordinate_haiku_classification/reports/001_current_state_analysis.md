# Current State Analysis: /coordinate Command Workflow Classification Issues

**Report ID**: 678-001
**Date**: 2025-11-12
**Type**: Root Cause Analysis + Gap Analysis
**Related Specs**:
- Spec 676: `/coordinate` Agent Invocation Loop Fix
- Spec 670: Hybrid Workflow Classification Implementation

---

## Executive Summary

This report investigates two interrelated issues in the `/coordinate` command:

1. **Issue 676**: Why are 4 report paths being saved when `RESEARCH_COMPLEXITY=2`?
2. **Issue 670**: Where is haiku model integration incomplete and why isn't it fully replacing pattern matching?

**Key Findings**:
- Spec 676 fix is **architecturally correct** but has **misleading diagnostics** (says "4 report paths saved" but only 2 are used)
- Spec 670 implementation is **complete for scope detection** but **not integrated for research complexity calculation**
- Pattern matching still used for `RESEARCH_COMPLEXITY` determination (lines 402-414 of coordinate.md)
- Haiku model integration exists for `WORKFLOW_SCOPE` but not for research topic decomposition

**Impact**: The 4 vs 2 discrepancy causes user confusion but doesn't affect functionality. Haiku integration is incomplete for research complexity.

---

## Table of Contents

1. [Problem Verification](#section-1-problem-verification)
2. [Current Architecture Analysis](#section-2-current-architecture-analysis)
3. [Haiku Model Integration Requirements](#section-3-haiku-model-integration-requirements)
4. [Gap Analysis](#section-4-gap-analysis)
5. [Refactor Scope](#section-5-refactor-scope)

---

## Section 1: Problem Verification

### Issue 676: 4 vs 2 Report Paths Discrepancy

**Evidence from coordinate_research.md (actual execution output)**:

```bash
# Line 258 from coordinate_research.md (Spec 676):
echo "Saved $REPORT_PATHS_COUNT report paths to workflow state"
# Output: "Saved 4 report paths to workflow state"

# But then later (lines 416-435):
echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"
# Output: "Research Complexity Score: 2 topics"
echo "Agent Invocations: Conditionally guarded (1-4 based on complexity)"
```

**Root Cause Analysis**:

The discrepancy exists at **two architectural layers**:

1. **Phase 0 (Initialization - lines 318-344 of workflow-initialization.sh)**:
   - Pre-allocates **4 report paths** for performance optimization (85% token reduction)
   - Hardcoded capacity design: `REPORT_PATHS_COUNT=4`
   - Comment at line 320-328 explains: "Fixed capacity (4) vs. dynamic complexity (1-4)"

2. **Phase 1 (Research - lines 402-414 of coordinate.md)**:
   - Calculates **RESEARCH_COMPLEXITY** based on pattern matching
   - Defaults to 2 topics for typical workflows
   - Only invokes agents up to `RESEARCH_COMPLEXITY` (not `REPORT_PATHS_COUNT`)

**Why Spec 676 Fix Didn't Fully Resolve This**:

Spec 676 successfully fixed the **functional bug** (4 agents invoked when only 2 needed) but introduced a **diagnostic inconsistency**:

```bash
# coordinate.md line 258 (after Spec 676):
echo "Saved $REPORT_PATHS_COUNT report paths to workflow state"
# This prints "Saved 4 report paths" (capacity)

# But actual usage is controlled by RESEARCH_COMPLEXITY:
# coordinate.md lines 500-590 (conditional enumeration after Spec 676):
IF RESEARCH_COMPLEXITY >= 1: Invoke agent 1
IF RESEARCH_COMPLEXITY >= 2: Invoke agent 2
IF RESEARCH_COMPLEXITY >= 3: Invoke agent 3 (skipped if complexity=2)
IF RESEARCH_COMPLEXITY >= 4: Invoke agent 4 (skipped if complexity=2)
```

**Impact Assessment**:

- **Functional**: No actual problem - only 2 agents invoked for RESEARCH_COMPLEXITY=2
- **Diagnostic**: Misleading message suggests 4 paths will be used
- **User Experience**: Confusion when users see "4 paths saved" but only 2 reports created
- **Cost**: Negligible - 4 empty path variables consume ~100 bytes of memory

**Is This a Regression?**

No - this is **architectural by design** (Phase 0 optimization pattern). The fix is **working correctly** but the diagnostic output is imprecise. The message should read:

```bash
# Better diagnostic:
echo "Pre-allocated $REPORT_PATHS_COUNT report paths (capacity: 4, usage: $RESEARCH_COMPLEXITY)"
```

---

## Section 2: Current Architecture Analysis

### 2.1 RESEARCH_COMPLEXITY Flow Through coordinate.md

**Current Flow Diagram**:

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 0: Initialization (coordinate.md lines 47-328)       │
├─────────────────────────────────────────────────────────────┤
│ workflow-initialization.sh:318-344                          │
│   ├─ Pre-allocate 4 REPORT_PATH variables (capacity)       │
│   ├─ Export REPORT_PATHS_COUNT=4 (hardcoded)              │
│   └─ Design: Max capacity upfront for 85% token savings    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Research (coordinate.md lines 340-436)            │
├─────────────────────────────────────────────────────────────┤
│ Pattern Matching Section (lines 402-414)                   │
│   ├─ Default: RESEARCH_COMPLEXITY=2                        │
│   ├─ If "integrate|refactor": RESEARCH_COMPLEXITY=3       │
│   ├─ If "multi-.*system|distributed": =4                  │
│   └─ If "fix.*single": =1                                 │
│                                                             │
│ → **THIS IS WHERE HAIKU SHOULD BE USED** ←               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Agent Invocation Section (lines 470-590)                   │
├─────────────────────────────────────────────────────────────┤
│ Bash Block: Prepare variables (lines 472-496)              │
│   └─ for i in $(seq 1 4); do export vars                  │
│                                                             │
│ Markdown: Conditional enumeration (lines 500-590)          │
│   ├─ IF RESEARCH_COMPLEXITY >= 1: Task{agent 1}           │
│   ├─ IF RESEARCH_COMPLEXITY >= 2: Task{agent 2}           │
│   ├─ IF RESEARCH_COMPLEXITY >= 3: Task{agent 3} [skipped] │
│   └─ IF RESEARCH_COMPLEXITY >= 4: Task{agent 4} [skipped] │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Verification Section (lines 592-823)                       │
├─────────────────────────────────────────────────────────────┤
│ for i in $(seq 1 $RESEARCH_COMPLEXITY); do                │
│   verify_file_created "${REPORT_PATHS[$i-1]}"              │
│ done                                                        │
│ → Only verifies $RESEARCH_COMPLEXITY files (2, not 4)     │
└─────────────────────────────────────────────────────────────┘
```

**Line Number References**:

1. **REPORT_PATHS_COUNT set**: `workflow-initialization.sh:344`
   ```bash
   export REPORT_PATHS_COUNT=4
   ```

2. **RESEARCH_COMPLEXITY calculated**: `coordinate.md:402-414`
   ```bash
   # Determine research complexity (1-4 topics)
   RESEARCH_COMPLEXITY=2  # DEFAULT - pattern-based heuristic

   if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
     RESEARCH_COMPLEXITY=3
   fi
   # ... more patterns ...
   ```

3. **Values interact in agent invocation**: `coordinate.md:470-590`
   - Bash prepares 4 sets of variables (uses REPORT_PATHS_COUNT implicitly)
   - Conditionals check RESEARCH_COMPLEXITY to decide execution

### 2.2 Pattern Matching Locations for Workflow Classification

**Complete Pattern Matching Inventory**:

| File | Lines | Purpose | Haiku Status |
|------|-------|---------|--------------|
| `workflow-scope-detection.sh` | 122-178 | WORKFLOW_SCOPE detection | ✅ Haiku integrated (Spec 670) |
| `coordinate.md` | 402-414 | RESEARCH_COMPLEXITY calculation | ❌ Still pattern matching |
| `workflow-detection.sh` | N/A | Sources unified library now | ✅ Uses haiku via sourcing |

**Detail: Pattern Matching in coordinate.md:402-414**

```bash
# This section uses PATTERN MATCHING, not haiku:
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi
```

**Why This Matters**:

This is the **same false-positive vulnerability** that Spec 670 addressed for WORKFLOW_SCOPE. Example failure mode:

```
Input: "research the refactor command to understand how it detects complexity"
Pattern Match: RESEARCH_COMPLEXITY=3 (FALSE POSITIVE - matches "refactor")
Expected: RESEARCH_COMPLEXITY=1 (user wants simple research, not complex refactoring)
```

### 2.3 Haiku Integration Points from Spec 670

**Current Haiku Integration Architecture** (from `workflow-scope-detection.sh:43-115`):

```bash
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
      echo "$scope"
      return 0
      ;;
    # ... other modes ...
  esac
}
```

**What classify_workflow_llm() Does** (from `workflow-llm-classifier.sh`):

1. Builds classification prompt with workflow description
2. Invokes haiku via file-based signaling (`/tmp/llm_classification_request_$$.json`)
3. Waits up to 10 seconds for response
4. Parses JSON response with schema:
   ```json
   {
     "scope": "research-and-plan",
     "confidence": 0.9,
     "reasoning": "User wants to research X and create plan Y"
   }
   ```
5. Returns scope if confidence >= 0.7, else triggers fallback

**State Machine Integration** (from `workflow-state-machine.sh:89-142`):

```bash
sm_init() {
  local workflow_description="$1"

  # Call detect_workflow_scope (which uses haiku in hybrid mode)
  WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_description")

  # Map scope to terminal states
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
    # ... etc ...
  esac
}
```

**Integration Point**: The haiku model is invoked **once** during state machine initialization to determine `WORKFLOW_SCOPE`, but **not used** for `RESEARCH_COMPLEXITY` calculation.

---

## Section 3: Haiku Model Integration Requirements

### 3.1 Required Inputs for Haiku Model

**For Comprehensive Classification** (both WORKFLOW_SCOPE and RESEARCH_COMPLEXITY):

```json
{
  "workflow_description": "research auth patterns and create implementation plan",
  "classification_type": "full",
  "request": {
    "determine_workflow_type": true,
    "determine_research_complexity": true,
    "identify_subtopics": true
  },
  "context": {
    "project_dir": "/home/benjamin/.config",
    "standards_file": "/home/benjamin/.config/CLAUDE.md"
  }
}
```

**Rationale for Each Field**:

- `workflow_description`: The user's input (e.g., "/coordinate \"research X and plan Y\"")
- `classification_type`: "full" (both scope + complexity) vs "scope-only" (backward compat)
- `determine_workflow_type`: Boolean flag to request WORKFLOW_SCOPE
- `determine_research_complexity`: Boolean flag to request RESEARCH_COMPLEXITY
- `identify_subtopics`: Boolean flag to get actual subtopic names (not generic "Topic 1")
- `context`: Optional metadata to improve accuracy

### 3.2 Required Outputs from Haiku Model

**Comprehensive Classification Response**:

```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.92,
  "research_complexity": 2,
  "subtopics": [
    "Authentication patterns in existing codebase",
    "Security best practices for auth implementation"
  ],
  "reasoning": "User wants to research authentication patterns (2 subtopics: existing patterns and security practices) then create an implementation plan. Not implementation yet.",
  "execution_metadata": {
    "model": "claude-haiku-4.5",
    "tokens_used": 150,
    "latency_ms": 450
  }
}
```

**Field Descriptions**:

| Field | Type | Purpose |
|-------|------|---------|
| `workflow_type` | string | One of: research-only, research-and-plan, research-and-revise, full-implementation, debug-only |
| `confidence` | float | 0.0-1.0, triggers fallback if < threshold (0.7) |
| `research_complexity` | int | 1-4, number of research subtopics identified |
| `subtopics` | array[string] | Actual subtopic names (descriptive, not "Topic N") |
| `reasoning` | string | Explanation of classification decision |
| `execution_metadata` | object | Performance metrics for monitoring |

### 3.3 Where Haiku Invocation Should Occur

**Proposed Architecture**:

```
┌─────────────────────────────────────────────────────────────┐
│ coordinate.md: State Machine Initialization (lines 47-153) │
├─────────────────────────────────────────────────────────────┤
│ sm_init("$SAVED_WORKFLOW_DESC", "coordinate")              │
│   ├─ CALLS: detect_workflow_scope_v2() [ENHANCED]         │
│   │   ├─ Invokes haiku with classification_type="full"    │
│   │   ├─ Receives: workflow_type + research_complexity    │
│   │   └─ Stores both in single JSON response              │
│   ├─ EXTRACTS: workflow_type → WORKFLOW_SCOPE             │
│   ├─ EXTRACTS: research_complexity → RESEARCH_COMPLEXITY  │
│   ├─ EXTRACTS: subtopics → RESEARCH_TOPICS array          │
│   └─ EXPORTS: All 3 variables for subsequent phases       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ coordinate.md: Research Phase (lines 340-436)              │
├─────────────────────────────────────────────────────────────┤
│ ❌ DELETE: Pattern matching section (lines 402-414)       │
│ ✅ REPLACE: Use $RESEARCH_COMPLEXITY from sm_init          │
│ ✅ NEW: Use $RESEARCH_TOPICS array for agent prompts      │
└─────────────────────────────────────────────────────────────┘
```

**Rationale**:

1. **Single invocation**: Call haiku once during initialization (not twice for scope + complexity)
2. **Fail-fast**: Detect classification errors early in initialization, not mid-research
3. **State persistence**: Store all outputs in workflow state for bash block recovery
4. **Fallback transparency**: Regex fallback applies to both scope + complexity

**Function Signature Change**:

```bash
# OLD (Spec 670):
detect_workflow_scope "$workflow_description"
# Returns: "research-and-plan"

# NEW (Spec 678):
classify_workflow_comprehensive "$workflow_description"
# Returns JSON: { "workflow_type": "research-and-plan", "research_complexity": 2, "subtopics": [...] }

# Then in sm_init:
CLASSIFICATION_JSON=$(classify_workflow_comprehensive "$workflow_description")
WORKFLOW_SCOPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity')
mapfile -t RESEARCH_TOPICS < <(echo "$CLASSIFICATION_JSON" | jq -r '.subtopics[]')
```

### 3.4 How Outputs Feed into State Machine

**State Variable Additions**:

```bash
# workflow-state-machine.sh: sm_init() function enhancement
sm_init() {
  local workflow_description="$1"
  local command_name="${2:-coordinate}"

  # Comprehensive classification (replaces detect_workflow_scope)
  local classification_json
  classification_json=$(classify_workflow_comprehensive "$workflow_description")

  # Extract and validate all outputs
  WORKFLOW_SCOPE=$(echo "$classification_json" | jq -r '.workflow_type // empty')
  RESEARCH_COMPLEXITY=$(echo "$classification_json" | jq -r '.research_complexity // 2')
  mapfile -t RESEARCH_TOPICS < <(echo "$classification_json" | jq -r '.subtopics[]? // empty')

  # Fallback validation: If haiku failed, use regex for scope + heuristic for complexity
  if [ -z "$WORKFLOW_SCOPE" ]; then
    WORKFLOW_SCOPE=$(classify_workflow_regex "$workflow_description")
    RESEARCH_COMPLEXITY=$(infer_complexity_from_scope "$WORKFLOW_SCOPE")
    RESEARCH_TOPICS=("Topic 1" "Topic 2")  # Generic fallback
  fi

  # Export for state persistence
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON=$(printf '%s\n' "${RESEARCH_TOPICS[@]}" | jq -R . | jq -s .)

  # Map to terminal state (unchanged from current implementation)
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
    # ... etc ...
  esac
}
```

**State Persistence Updates** (workflow-state-machine.sh):

```bash
# Add to state file during initialization:
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
```

**coordinate.md Usage** (Research Phase):

```bash
# Load from state (lines 340-436):
load_workflow_state "$WORKFLOW_ID"

# Reconstruct topics array from JSON
mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')

# Use complexity directly (DELETE pattern matching):
echo "Research Complexity: $RESEARCH_COMPLEXITY topics"

# Use descriptive topics in agent prompts:
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  RESEARCH_TOPIC="${RESEARCH_TOPICS[$i-1]}"  # e.g., "Authentication patterns"

  Task {
    prompt: "
      Research Topic: $RESEARCH_TOPIC
      (not generic 'Topic $i')
    "
  }
done
```

---

## Section 4: Gap Analysis

### 4.1 What's Missing from Spec 670 Implementation?

**Completeness Assessment**:

| Component | Spec 670 Status | Gap for Spec 678 |
|-----------|-----------------|------------------|
| Haiku LLM classifier library | ✅ Complete (290 lines) | None - reuse as-is |
| File-based signaling protocol | ✅ Complete | None - working correctly |
| Hybrid mode (LLM + fallback) | ✅ Complete | None - architecture proven |
| WORKFLOW_SCOPE detection | ✅ Complete | None - production ready |
| RESEARCH_COMPLEXITY detection | ❌ Not implemented | **CRITICAL GAP** |
| Subtopic identification | ❌ Not implemented | **MAJOR GAP** |
| Comprehensive classification | ❌ Not implemented | **MAJOR GAP** |

**Gap 1: RESEARCH_COMPLEXITY Not in Haiku Request**

Current `workflow-llm-classifier.sh` prompt:

```bash
# build_llm_classifier_input() - lines 100-150
PROMPT="
Analyze this workflow description and classify it:

Workflow: $workflow_description

Return JSON with:
{
  \"scope\": \"research-only|research-and-plan|research-and-revise|full-implementation|debug-only\",
  \"confidence\": 0.0-1.0,
  \"reasoning\": \"explanation\"
}
"
```

**Missing**: Request for `research_complexity` and `subtopics` fields.

**Gap 2: State Machine Doesn't Store RESEARCH_COMPLEXITY**

Current `workflow-state-machine.sh:sm_init()` (lines 89-142):

```bash
sm_init() {
  local workflow_description="$1"

  # Only sets WORKFLOW_SCOPE, not RESEARCH_COMPLEXITY
  WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_description")

  # RESEARCH_COMPLEXITY calculation deferred to coordinate.md line 402
}
```

**Missing**: Comprehensive classification call that returns both scope + complexity.

**Gap 3: coordinate.md Still Uses Pattern Matching**

Lines 402-414 are unchanged from pre-Spec-670 implementation:

```bash
# This is the OLD pattern matching code that Spec 670 was supposed to replace:
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi
```

**Missing**: Integration with haiku results from sm_init.

### 4.2 Why Isn't Haiku Fully Replacing Pattern Matching Yet?

**Root Cause Analysis**:

**Reason 1: Scope Creep Limitation**

Spec 670 explicitly scoped to **WORKFLOW_SCOPE detection only**:

> "Problem: Current regex-based workflow classification has 8% false positive rate on edge cases."
> (Line 39 of `001_hybrid_classification_implementation.md`)

The false-positive example was:
```
Input: "research the research-and-revise workflow"
Regex: research-and-revise (FALSE POSITIVE)
Expected: research-and-plan
```

This was a **scope detection problem**, not a complexity problem. The spec didn't address RESEARCH_COMPLEXITY because that wasn't causing user-visible failures.

**Reason 2: Incremental Implementation Philosophy**

Spec 670 followed incremental deployment:

- Phase 1: Core LLM classifier (✅ complete)
- Phase 2: Hybrid integration for scope (✅ complete)
- Phase 3: Testing (✅ complete)
- **Phase 4 (deferred)**: Extend to other dimensions (complexity, subtopics)

**Reason 3: Different Architectural Layers**

- `WORKFLOW_SCOPE`: Determined in **state machine initialization** (workflow-state-machine.sh)
- `RESEARCH_COMPLEXITY`: Calculated in **coordinate.md research phase** (line 402)

These are at different layers, so fixing scope didn't automatically fix complexity.

**Reason 4: Missing Requirements in Original Spec**

Spec 670 requirements (lines 55-163) never mention:
- Research complexity calculation
- Subtopic identification
- Comprehensive classification beyond scope

This wasn't an oversight - the problem statement didn't require it.

### 4.3 What Needs to Change in coordinate.md?

**Required Changes Inventory**:

| Section | Current Behavior | Required Behavior |
|---------|------------------|-------------------|
| **Initialization (lines 152-153)** | `sm_init("$SAVED_WORKFLOW_DESC", "coordinate")` → sets WORKFLOW_SCOPE only | → should set WORKFLOW_SCOPE + RESEARCH_COMPLEXITY + RESEARCH_TOPICS |
| **State save (lines 174-177)** | Saves only WORKFLOW_SCOPE | → should save RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON |
| **Research phase (lines 402-414)** | Pattern matching calculates RESEARCH_COMPLEXITY | → DELETE pattern matching, use $RESEARCH_COMPLEXITY from state |
| **Agent invocation (lines 485-590)** | Generic "Topic 1", "Topic 2" names | → Use descriptive $RESEARCH_TOPICS array elements |

**File-by-File Changes Required**:

1. **workflow-llm-classifier.sh** (lines 100-150):
   - Enhance prompt to request `research_complexity` and `subtopics`
   - Update response parsing to extract new fields
   - Add validation for complexity (1-4 range)

2. **workflow-state-machine.sh** (lines 89-142):
   - Replace `detect_workflow_scope()` call with `classify_workflow_comprehensive()`
   - Parse JSON response to extract scope + complexity + subtopics
   - Export all 3 variables
   - Add fallback logic if haiku fails (infer complexity from scope heuristic)

3. **coordinate.md** (lines 152-177):
   - Save RESEARCH_COMPLEXITY to workflow state
   - Save RESEARCH_TOPICS_JSON to workflow state
   - Add verification checkpoints for new variables

4. **coordinate.md** (lines 402-414):
   - **DELETE** entire pattern matching section
   - Replace with: `# RESEARCH_COMPLEXITY loaded from workflow state (set by sm_init)`

5. **coordinate.md** (lines 485-590):
   - Replace `export "RESEARCH_TOPIC_${i}=Topic ${i}"` with `export "RESEARCH_TOPIC_${i}=${RESEARCH_TOPICS[$i-1]}"`
   - Update Task prompt to use descriptive topic names

---

## Section 5: Refactor Scope

### 5.1 Files Requiring Modification

**Priority 1: Critical Path (Haiku Integration)**

| File | Lines | Modification Type | Estimated LoC Change |
|------|-------|-------------------|----------------------|
| `.claude/lib/workflow-llm-classifier.sh` | 100-150 | Enhance prompt + parsing | +30/-10 (add complexity fields) |
| `.claude/lib/workflow-state-machine.sh` | 89-142 | Replace function call | +50/-20 (comprehensive classification) |
| `.claude/commands/coordinate.md` | 152-177 | Add state persistence | +15/-5 (save new variables) |
| `.claude/commands/coordinate.md` | 402-414 | Delete pattern matching | +5/-13 (replace with state load) |
| `.claude/commands/coordinate.md` | 485-590 | Use descriptive topics | +10/-5 (array indexing change) |

**Priority 2: Supporting Infrastructure**

| File | Lines | Modification Type | Estimated LoC Change |
|------|-------|-------------------|----------------------|
| `.claude/lib/state-persistence.sh` | N/A | Add array serialization | +20 (helper for RESEARCH_TOPICS) |
| `.claude/tests/test_llm_classifier.sh` | All | Add complexity tests | +50 (12 new test cases) |
| `.claude/tests/test_scope_detection.sh` | All | Add comprehensive tests | +40 (10 new integration tests) |

**Priority 3: Documentation**

| File | Modification Type | Estimated LoC |
|------|-------------------|---------------|
| `.claude/docs/guides/coordinate-command-guide.md` | Add section on comprehensive classification | +200 |
| `.claude/docs/concepts/patterns/llm-classification-pattern.md` | Update with complexity examples | +100 |
| `CLAUDE.md` | Update workflow classification description | +20 |

### 5.2 Functions Requiring Replacement

**Function Replacement Matrix**:

| Old Function | File | Lines | New Function | Changes |
|--------------|------|-------|--------------|---------|
| `detect_workflow_scope()` | workflow-scope-detection.sh | 43-115 | `classify_workflow_comprehensive()` | Return JSON instead of string |
| `classify_workflow_llm()` | workflow-llm-classifier.sh | 60-95 | (same name, enhanced) | Add complexity to prompt/response |
| `build_llm_classifier_input()` | workflow-llm-classifier.sh | 100-150 | (same name, enhanced) | Add classification_type parameter |
| `parse_llm_classifier_response()` | workflow-llm-classifier.sh | 160-200 | (same name, enhanced) | Parse complexity + subtopics fields |

**New Functions Required**:

1. **`classify_workflow_comprehensive()`** (workflow-scope-detection.sh):
   ```bash
   # Replaces detect_workflow_scope()
   # Returns: JSON with workflow_type, research_complexity, subtopics
   classify_workflow_comprehensive() {
     local workflow_description="$1"

     case "$WORKFLOW_CLASSIFICATION_MODE" in
       hybrid)
         # Try haiku first
         if result=$(classify_workflow_llm_comprehensive "$workflow_description"); then
           echo "$result"
           return 0
         fi

         # Fallback to regex + heuristic
         fallback_comprehensive_classification "$workflow_description"
         ;;
       # ... other modes ...
     esac
   }
   ```

2. **`fallback_comprehensive_classification()`** (workflow-scope-detection.sh):
   ```bash
   # Combines regex scope + heuristic complexity
   fallback_comprehensive_classification() {
     local workflow_description="$1"

     local scope=$(classify_workflow_regex "$workflow_description")
     local complexity=$(infer_complexity_from_keywords "$workflow_description")
     local topics=$(generate_generic_topics "$complexity")

     # Return JSON compatible with haiku response
     jq -n \
       --arg scope "$scope" \
       --argjson complexity "$complexity" \
       --argjson topics "$topics" \
       '{workflow_type: $scope, research_complexity: $complexity, subtopics: $topics, confidence: 0.5, method: "fallback"}'
   }
   ```

3. **`infer_complexity_from_keywords()`** (workflow-scope-detection.sh):
   ```bash
   # Heuristic fallback for complexity calculation
   infer_complexity_from_keywords() {
     local workflow_description="$1"
     local complexity=2  # Default

     # Same patterns as current coordinate.md:402-414
     if echo "$workflow_description" | grep -Eiq "integrate|refactor|architecture"; then
       complexity=3
     elif echo "$workflow_description" | grep -Eiq "multi-.*system|distributed"; then
       complexity=4
     elif echo "$workflow_description" | grep -Eiq "^(fix|update|modify).*(single|small)"; then
       complexity=1
     fi

     echo "$complexity"
   }
   ```

### 5.3 New Functions/Libraries Needed

**New Library: complexity-utils.sh** (Optional Enhancement)

```bash
# Purpose: Complexity scoring and subtopic generation utilities
# Location: .claude/lib/complexity-utils.sh

# Score workflow complexity on 1-4 scale based on multiple factors
calculate_complexity_score() {
  local workflow_description="$1"
  local score=2  # Default moderate complexity

  # Factor 1: Keywords (weight: 40%)
  # Factor 2: Description length (weight: 20%)
  # Factor 3: Dependency count (weight: 20%)
  # Factor 4: File references (weight: 20%)

  # ... scoring logic ...

  echo "$score"
}

# Generate descriptive subtopic suggestions for fallback mode
generate_subtopics_heuristic() {
  local workflow_description="$1"
  local complexity="$2"

  # Extract key nouns/verbs from description
  # Generate subtopic names based on domain

  # Example output:
  # ["Authentication implementation", "Security best practices"]
}
```

**Rationale**: Separating complexity calculation into a utility library:
- Makes testing easier (unit tests for complexity scoring)
- Enables reuse across commands (/coordinate, /orchestrate, /supervise)
- Allows future enhancement (ML-based scoring) without changing coordinate.md

**Integration Note**: This is **optional** for Spec 678. Could use inline functions in workflow-scope-detection.sh for MVP, then extract to library in future spec.

### 5.4 Backward Compatibility Considerations

**Compatibility Requirements**:

| Aspect | Requirement | Mitigation |
|--------|-------------|------------|
| **Function Signature** | `detect_workflow_scope()` must still work for non-coordinate callers | Keep as wrapper that calls `classify_workflow_comprehensive()` and extracts `.workflow_type` |
| **Environment Variables** | Existing `WORKFLOW_SCOPE` variable must work | ✅ No change - still exported |
| **Fallback Mode** | Regex-only mode must work without haiku | ✅ Already supported via `WORKFLOW_CLASSIFICATION_MODE=regex-only` |
| **State File Format** | Old state files without `RESEARCH_COMPLEXITY` | Add graceful degradation: if not in state, recalculate from scope heuristic |

**Compatibility Wrapper** (workflow-scope-detection.sh):

```bash
# Backward compatibility: Keep old function signature
detect_workflow_scope() {
  local workflow_description="$1"

  # Call comprehensive classification
  local result
  result=$(classify_workflow_comprehensive "$workflow_description")

  # Extract only workflow_type for backward compatibility
  echo "$result" | jq -r '.workflow_type'
}
```

**Migration Path**:

1. **Phase 1 (Spec 678)**: Add `classify_workflow_comprehensive()`, keep `detect_workflow_scope()` as wrapper
2. **Phase 2 (future)**: Update all callers to use comprehensive version
3. **Phase 3 (future)**: Deprecate wrapper (with warning messages)
4. **Phase 4 (future)**: Remove wrapper entirely

**Rationale**: Clean-break philosophy suggests immediate replacement, but comprehensive classification is a new capability (not just a refactor). Wrapper provides smooth transition.

---

## Recommendations

### Immediate Actions (Spec 678 Implementation)

1. **Fix Diagnostic Message** (Low priority, quick win):
   ```bash
   # coordinate.md line 258:
   echo "Pre-allocated $REPORT_PATHS_COUNT report paths (capacity: 4, will use: $RESEARCH_COMPLEXITY)"
   ```
   - **Effort**: 5 minutes
   - **Impact**: Eliminates user confusion

2. **Implement Comprehensive Classification** (High priority, core requirement):
   - Enhance `workflow-llm-classifier.sh` prompt to request complexity + subtopics
   - Add `classify_workflow_comprehensive()` function to workflow-scope-detection.sh
   - Update `sm_init()` to use comprehensive classification
   - **Effort**: 4-6 hours
   - **Impact**: Eliminates pattern matching for complexity

3. **Remove Pattern Matching from coordinate.md** (High priority, delete technical debt):
   - Delete lines 402-414 (pattern matching section)
   - Replace with load from workflow state
   - **Effort**: 30 minutes
   - **Impact**: Reduces false positives, improves consistency

4. **Add Comprehensive Testing** (High priority, quality assurance):
   - Test haiku classification with complexity requests
   - Test fallback mode for complexity calculation
   - Test descriptive topic names in agent prompts
   - **Effort**: 3-4 hours
   - **Impact**: Prevents regressions

### Future Enhancements (Post-Spec-678)

1. **ML-Based Complexity Scoring**: Replace keyword heuristics with learned model
2. **Dynamic Topic Decomposition**: Use haiku to break complex topics into 2-3 subtopics each
3. **User Feedback Loop**: Track classification accuracy, retrain on misclassifications
4. **Cost Optimization**: Cache common workflow patterns to reduce haiku calls

---

## Appendix: Code Examples

### Example 1: Enhanced Haiku Prompt

```bash
# workflow-llm-classifier.sh: build_llm_classifier_input()

build_llm_classifier_input() {
  local workflow_description="$1"
  local classification_type="${2:-full}"  # full | scope-only

  cat <<EOF
{
  "workflow_description": "$workflow_description",
  "classification_type": "$classification_type",
  "request": {
    "determine_workflow_type": true,
    "determine_research_complexity": $([ "$classification_type" = "full" ] && echo "true" || echo "false"),
    "identify_subtopics": $([ "$classification_type" = "full" ] && echo "true" || echo "false")
  },
  "instructions": "Analyze the workflow description and return:

  1. workflow_type: One of: research-only, research-and-plan, research-and-revise, full-implementation, debug-only
  2. research_complexity: Integer 1-4 indicating number of research subtopics needed
  3. subtopics: Array of descriptive subtopic names (not generic 'Topic N')
  4. confidence: Float 0.0-1.0 indicating classification confidence
  5. reasoning: Brief explanation of classification decision

  Use semantic understanding to avoid false positives. Example:
  - 'research the refactor command' → complexity=1 (simple research, not refactoring)
  - 'refactor auth system' → complexity=3 (actual complex refactoring work)

  Return valid JSON matching this schema:
  {
    \"workflow_type\": \"string\",
    \"research_complexity\": 2,
    \"subtopics\": [\"string\"],
    \"confidence\": 0.9,
    \"reasoning\": \"string\"
  }"
}
EOF
}
```

### Example 2: Comprehensive Classification Integration

```bash
# workflow-state-machine.sh: sm_init() enhancement

sm_init() {
  local workflow_description="$1"
  local command_name="${2:-coordinate}"

  echo "Initializing workflow state machine for: $command_name"

  # Comprehensive classification (replaces simple scope detection)
  local classification_json
  if classification_json=$(classify_workflow_comprehensive "$workflow_description"); then
    # Extract all fields from JSON
    WORKFLOW_SCOPE=$(echo "$classification_json" | jq -r '.workflow_type // empty')
    RESEARCH_COMPLEXITY=$(echo "$classification_json" | jq -r '.research_complexity // 2')
    mapfile -t RESEARCH_TOPICS < <(echo "$classification_json" | jq -r '.subtopics[]? // empty')

    # Validation
    if [ -z "$WORKFLOW_SCOPE" ]; then
      echo "WARNING: Haiku returned empty workflow_type, using fallback" >&2
      WORKFLOW_SCOPE="research-and-plan"
    fi

    if [ "$RESEARCH_COMPLEXITY" -lt 1 ] || [ "$RESEARCH_COMPLEXITY" -gt 4 ]; then
      echo "WARNING: Invalid research_complexity=$RESEARCH_COMPLEXITY, clamping to 1-4 range" >&2
      RESEARCH_COMPLEXITY=$(( RESEARCH_COMPLEXITY < 1 ? 1 : (RESEARCH_COMPLEXITY > 4 ? 4 : RESEARCH_COMPLEXITY) ))
    fi

    if [ ${#RESEARCH_TOPICS[@]} -eq 0 ]; then
      echo "WARNING: No subtopics returned, generating generic topics" >&2
      for i in $(seq 1 "$RESEARCH_COMPLEXITY"); do
        RESEARCH_TOPICS+=("Topic $i")
      done
    fi
  else
    # Complete fallback: haiku failed entirely
    echo "WARNING: Haiku classification failed, using regex + heuristic fallback" >&2
    WORKFLOW_SCOPE=$(classify_workflow_regex "$workflow_description")
    RESEARCH_COMPLEXITY=$(infer_complexity_from_keywords "$workflow_description")
    for i in $(seq 1 "$RESEARCH_COMPLEXITY"); do
      RESEARCH_TOPICS+=("Topic $i")
    done
  fi

  # Export all variables
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON=$(printf '%s\n' "${RESEARCH_TOPICS[@]}" | jq -R . | jq -s .)

  # Map to terminal state (unchanged logic)
  case "$WORKFLOW_SCOPE" in
    research-only)
      TERMINAL_STATE="$STATE_RESEARCH"
      ;;
    research-and-plan)
      TERMINAL_STATE="$STATE_PLAN"
      ;;
    research-and-revise)
      TERMINAL_STATE="$STATE_PLAN"
      ;;
    full-implementation)
      TERMINAL_STATE="$STATE_DOCUMENT"
      ;;
    debug-only)
      TERMINAL_STATE="$STATE_DEBUG"
      ;;
    *)
      echo "ERROR: Unknown workflow scope: $WORKFLOW_SCOPE" >&2
      TERMINAL_STATE="$STATE_COMPLETE"
      ;;
  esac

  export CURRENT_STATE="$STATE_INITIALIZE"
  export TERMINAL_STATE

  echo "Workflow configuration:"
  echo "  Scope: $WORKFLOW_SCOPE"
  echo "  Terminal state: $TERMINAL_STATE"
  echo "  Research complexity: $RESEARCH_COMPLEXITY topics"
  echo "  Subtopics: ${RESEARCH_TOPICS[*]}"
}
```

### Example 3: coordinate.md Pattern Matching Removal

```diff
# coordinate.md: Research Phase (lines 402-436)

-# Determine research complexity (1-4 topics)
-RESEARCH_COMPLEXITY=2
-
-if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
-  RESEARCH_COMPLEXITY=3
-fi
-
-if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
-  RESEARCH_COMPLEXITY=4
-fi
-
-if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
-  RESEARCH_COMPLEXITY=1
-fi
+# RESEARCH_COMPLEXITY loaded from workflow state (set by sm_init during initialization)
+# No pattern matching needed - haiku classification already determined complexity
+# Fallback: If not in state, recalculate from scope heuristic

 echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"

+# Reconstruct topics array from state
+mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')
+
 # Reconstruct REPORT_PATHS array
 reconstruct_report_paths_array
```

---

## End of Report

**Status**: Ready for implementation planning
**Next Steps**:
1. Create implementation plan for Spec 678 using this analysis
2. Estimate effort and timeline
3. Identify risks and mitigation strategies
4. Define success criteria and testing approach
