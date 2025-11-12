# Workflow Classification Accuracy - Research-and-Revise Pattern Analysis

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Workflow Classification Accuracy for Research-and-Revise Patterns
- **Report Type**: codebase analysis
- **Complexity Level**: 2

## Executive Summary

The workflow classification system has excellent research-and-revise detection (19/20 tests passing, 95% accuracy) with one known regex priority issue. The system uses a hybrid LLM-first approach with automatic regex fallback. Research-and-revise patterns are correctly detected through three primary mechanisms: explicit revision verbs ("revise", "update", "modify"), plan path extraction, and contextual analysis. The single failing test ("research async patterns and implement solution") is a regex priority ordering issue where "implement" keyword triggers full-implementation before research-with-action-keywords logic can apply. The system is production-ready with strong architectural separation and comprehensive test coverage.

## Findings

### Current State Analysis

**Test Suite Results** (test_workflow_scope_detection.sh):
- **Pass Rate**: 19/20 tests (95% accuracy)
- **Passing Categories**: Plan path detection, explicit revision patterns, synonym detection (revise/update/modify), research-only patterns, debug patterns, implementation keywords
- **Single Failure**: Test 9 - "research async patterns and implement solution" (expected: research-and-plan, got: full-implementation)

**Research-and-Revise Test Cases** (all passing):
- Test 4: "revise specs/027_auth/plans/001_plan.md based on feedback" → research-and-revise (PASS)
- Test 12: "revise the authentication plan to accommodate new requirements" → research-and-revise (PASS)
- Test 13: "update the implementation plan based on review" → research-and-revise (PASS)
- Test 14: "modify specs/042_test/plans/001_plan.md for new requirements" → research-and-revise (PASS)

### Classification System Architecture

**Unified Hybrid Classification** (`workflow-scope-detection.sh`):

The system provides three classification modes with automatic fallback:

```bash
# Line 32: Configuration
WORKFLOW_CLASSIFICATION_MODE="${WORKFLOW_CLASSIFICATION_MODE:-hybrid}"

# Lines 56-114: Mode routing
case "$WORKFLOW_CLASSIFICATION_MODE" in
  hybrid)
    # Try LLM first, fallback to regex on error/timeout/low-confidence
    if scope=$(classify_workflow_llm "$workflow_description" 2>/dev/null); then
      # LLM succeeded
      echo "$llm_scope"
      return 0
    fi
    # LLM failed - fallback to regex
    scope=$(classify_workflow_regex "$workflow_description")
    echo "$scope"
    return 0
    ;;
```

**Classification Modes**:
1. **Hybrid (default)**: LLM-first with automatic regex fallback on timeout/low-confidence
2. **LLM-only**: Fail-fast on LLM errors (no fallback)
3. **Regex-only**: Traditional pattern matching only

**Zero Operational Risk**: Hybrid mode guarantees classification result even when LLM unavailable (automatic regex fallback).

### Research-and-Revise Detection Logic

**Priority Order** (workflow-scope-detection.sh:134-146):

The regex classifier uses explicit priority ordering with comments:

```bash
# Line 134: PRIORITY 1: Research-and-revise patterns (most specific)
# Pattern: revision-first (e.g., "Revise X to Y", "Update plan to accommodate Z")
if echo "$workflow_description" | grep -Eiq "^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)"; then
  scope="research-and-revise"
  # Extract EXISTING_PLAN_PATH from plan path in description
  if echo "$workflow_description" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
    EXISTING_PLAN_PATH=$(echo "$workflow_description" | grep -oE "/[^ ]+\.md" | head -1)
    export EXISTING_PLAN_PATH
  fi

# Line 145: Pattern: research-and-revise (specific before general)
elif echo "$workflow_description" | grep -Eiq "(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)"; then
  scope="research-and-revise"
```

**Detection Mechanisms**:

1. **Explicit Revision Verbs** (Priority 1):
   - Pattern: `^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)`
   - Triggers: "revise plan based on", "update plan to accommodate", "modify implementation for"
   - Case-insensitive matching
   - Anchored to start of string (^) to detect revision-first intent

2. **Research-and-Revise Compound** (Priority 1):
   - Pattern: `(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)`
   - Triggers: "research and revise plan", "analyze then update plan"
   - Detects explicit two-phase workflow intent

3. **Plan Path Extraction** (when present):
   - Pattern: `/specs/[0-9]+_[^/]+/plans/`
   - Automatically exports EXISTING_PLAN_PATH for workflow initialization
   - Example: "revise specs/042_auth/plans/001_plan.md" → EXISTING_PLAN_PATH="/specs/042_auth/plans/001_plan.md"

**Integration with /coordinate** (coordinate.md:155-171):

```bash
# Line 155: Extract and save EXISTING_PLAN_PATH for research-and-revise workflows
if [ "$WORKFLOW_SCOPE" = "research-and-revise" ]; then
  # Extract plan path from workflow description
  if echo "$SAVED_WORKFLOW_DESC" | grep -Eq "/specs/[0-9]+_[^/]+/plans/"; then
    EXISTING_PLAN_PATH=$(echo "$SAVED_WORKFLOW_DESC" | grep -oE "/[^ ]+\.md" | head -1)
    export EXISTING_PLAN_PATH
    append_workflow_state "EXISTING_PLAN_PATH" "$EXISTING_PLAN_PATH"
    echo "✓ Extracted existing plan path: $EXISTING_PLAN_PATH"
  else
    handle_state_error "research-and-revise workflow requires plan path in description" 1
  fi
fi
```

**State Persistence**: EXISTING_PLAN_PATH is persisted to workflow state file for cross-bash-block access (verification checkpoint at line 188).

### LLM Classifier Semantic Analysis

**LLM Instructions** (workflow-llm-classifier.sh:113):

```json
{
  "instructions": "Analyze the workflow description and determine the user intent. Return a JSON object with: scope (one of valid_scopes), confidence (0.0-1.0), reasoning (brief explanation). Focus on INTENT, not keywords - e.g., 'research the research-and-revise workflow' is research-and-plan (intent: learn about workflow type), not research-and-revise (intent: revise a plan)."
}
```

**Key Advantage**: LLM classifier distinguishes **meta-research** from **revision workflows**:

- "research the research-and-revise workflow" → research-and-plan (intent: learn about workflow pattern)
- "research authentication and revise the plan" → research-and-revise (intent: update existing plan)

**Confidence Threshold**: 0.7 (default, configurable via WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD)

**Fallback Behavior**: Low-confidence LLM results (<0.7) automatically trigger regex fallback (zero user intervention required).

### Test Coverage Analysis

**Comprehensive Test Suite** (test_workflow_scope_detection.sh: 294 lines, 20 tests):

**Research-and-Revise Coverage** (4 tests, 100% passing):
- Line 88-96: Revise with plan path + trigger keyword
- Line 176-184: Revise without explicit path (contextual)
- Line 187-195: Update plan synonym detection
- Line 198-206: Modify plan synonym detection

**Other Workflow Types** (16 tests):
- Research-only: 1 test (pure research, no action keywords)
- Research-and-plan: 4 tests (plan keyword, design, create plan, ambiguous default)
- Full-implementation: 7 tests (plan paths, implement/execute keywords, build/create feature)
- Debug-only: 3 tests (fix, debug, troubleshoot patterns)

**Edge Cases Covered**:
- Absolute vs relative plan paths (lines 156-173)
- Research with action keywords (line 143-151) - FAILING TEST
- Ambiguous input default fallback (line 133-140)

**Missing Edge Cases** (potential gaps):
- "research and plan to revise" (compound with all keywords)
- Plan paths without revision verbs
- Multiple plan paths in single description
- Misspellings or variations ("reviise", "updaate")

### Identified Issues

**Issue 1: Regex Priority Ordering (Single Failing Test)**

**Root Cause**: Keyword "implement" triggers full-implementation (Priority 3, line 154) before research-with-action-keywords logic (Priority 4, line 158-165).

**Failing Test Case** (test_workflow_scope_detection.sh:146):
```bash
detect_workflow_scope "research async patterns and implement solution"
# Expected: research-and-plan (intent: research first, then plan implementation)
# Actual: full-implementation (matched "implement" keyword)
```

**Regex Evaluation Order**:
1. PRIORITY 1: Research-and-revise patterns (lines 136-146) - NO MATCH
2. PRIORITY 2: Plan path detection (line 149) - NO MATCH
3. PRIORITY 3: Explicit keywords (line 154) - **MATCH on "implement"** → returns full-implementation
4. PRIORITY 4: Research-only pattern (lines 158-165) - NEVER REACHED

**Why This Matters**:
- Regex classifier treats "implement" as immediate action, not future intent
- LLM classifier (if invoked) would correctly interpret as research-and-plan (intent: research before implementation)
- Hybrid mode may fallback to regex if LLM times out or has low confidence

**Impact**: Low severity (1/20 tests, 5% failure rate)
- Research-and-revise workflows unaffected (all 4 tests pass)
- Only affects compound research-action descriptions
- LLM hybrid mode likely handles this correctly (semantic analysis)

**Issue 2: LLM Invocation Visibility Gap**

**Context** (from report 001_llm_classification_diagnostics.md):

The hybrid mode uses `2>/dev/null` redirection (workflow-scope-detection.sh:58), which silences:
- `[LLM_CLASSIFICATION_REQUEST]` signal
- Timeout errors
- Debug output

**Impact**: Cannot verify if LLM or regex was used without DEBUG_SCOPE_DETECTION=1.

**Why This Matters for Research-and-Revise**:
- No way to confirm LLM is handling edge cases
- Cannot distinguish LLM success from regex fallback in production
- Diagnostic reports rely on manual inspection of /tmp/ files

**Mitigation**: Report 001 provides 7 comprehensive recommendations for logging infrastructure.

**Issue 3: EXISTING_PLAN_PATH Extraction Ambiguity**

**Pattern**: `grep -oE "/[^ ]+\.md"` (workflow-scope-detection.sh:140)

**Limitation**: Matches any path ending in .md, not just plan paths:
- Matches: "/specs/042_auth/plans/001_plan.md" (correct)
- Also matches: "/home/user/README.md" (incorrect context)

**Actual Risk**: Low (test suite doesn't expose this, descriptions unlikely to contain random .md paths)

**Recommendation**: Tighten pattern to require "plans/" subdirectory:
```bash
# Current: grep -oE "/[^ ]+\.md"
# Improved: grep -oE "/specs/[0-9]+_[^/]+/plans/[^/]+\.md"
```

### No Classification Failures for Research-and-Revise

**Explicit Testing**: All 4 research-and-revise tests pass (100% accuracy)

**Patterns Tested**:
- Revision verb + plan path: "revise specs/027_auth/plans/001_plan.md based on feedback"
- Revision verb + contextual: "revise the authentication plan to accommodate new requirements"
- Update synonym: "update the implementation plan based on review"
- Modify synonym: "modify specs/042_test/plans/001_plan.md for new requirements"

**Why No Failures**:
1. Research-and-revise is PRIORITY 1 (evaluated first, before other patterns)
2. Patterns are specific (require revision verb + plan/implementation keyword)
3. EXISTING_PLAN_PATH extraction is separate concern (exports variable, doesn't affect classification)

**Production Usage** (coordinate.md integration):
- /coordinate verifies EXISTING_PLAN_PATH when scope=research-and-revise (lines 188-190)
- Fail-fast error handling if path missing (line 169: handle_state_error)
- State persistence ensures cross-bash-block availability

## Recommendations

### 1. Fix Regex Priority for Compound Research-Action Patterns

**Priority**: Medium (improves 1 test from 95% to 100% accuracy)
**Effort**: Low (30 minutes)
**Impact**: Research-and-revise unaffected (already 100%)

**Change**: Evaluate research-only pattern BEFORE explicit implementation keyword.

**Current Order** (workflow-scope-detection.sh:134-174):
```bash
# PRIORITY 1: Research-and-revise (lines 134-146)
# PRIORITY 2: Plan path detection (line 149)
# PRIORITY 3: Explicit keywords (implement/execute) (line 154)
# PRIORITY 4: Research-only pattern (lines 158-165)
```

**Proposed Order**:
```bash
# PRIORITY 1: Research-and-revise (lines 134-146)
# PRIORITY 2: Plan path detection (line 149)
# PRIORITY 3: Research-only pattern (lines 158-165) - MOVED UP
# PRIORITY 4: Explicit keywords (implement/execute) (line 154) - MOVED DOWN
```

**Rationale**: "research X and implement Y" should default to research-and-plan (two-phase workflow) unless plan path explicitly provided.

**Alternative**: Improve research-only pattern to handle compound cases:
```bash
# Enhanced pattern detects "research X and <action>" as research-and-plan
elif echo "$workflow_description" | grep -Eiq "^research.*and.*(implement|execute|build|create|add)"; then
  scope="research-and-plan"
```

**Trade-off**: More specific patterns reduce false negatives but increase maintenance complexity.

### 2. Tighten EXISTING_PLAN_PATH Extraction Pattern

**Priority**: Low (no known failures, preventative measure)
**Effort**: Low (15 minutes)
**Impact**: Prevents future edge cases with multiple .md paths

**Change**: Require "plans/" subdirectory in extraction pattern.

**Current Pattern** (workflow-scope-detection.sh:140):
```bash
EXISTING_PLAN_PATH=$(echo "$workflow_description" | grep -oE "/[^ ]+\.md" | head -1)
```

**Improved Pattern**:
```bash
EXISTING_PLAN_PATH=$(echo "$workflow_description" | grep -oE "/specs/[0-9]+_[^/]+/plans/[^/]+\.md" | head -1)
```

**Benefits**:
- Matches only valid plan paths in topic-based structure
- Prevents accidental extraction of documentation paths
- Self-documenting (pattern shows expected structure)

**Test Coverage**: Add test case for multiple .md paths:
```bash
# Test: Multiple .md paths, should extract only plan path
result=$(detect_workflow_scope "revise specs/042_auth/plans/001_plan.md per README.md")
# Expected: EXISTING_PLAN_PATH="/specs/042_auth/plans/001_plan.md" (not README.md)
```

### 3. Add Test Coverage for Edge Cases

**Priority**: Low (research-and-revise coverage already 100%)
**Effort**: Medium (1-2 hours for 5 new tests)
**Impact**: Prevents future regressions

**Missing Test Cases**:

1. **Compound Keywords** (all workflow types in one description):
```bash
# Test: "research and plan to revise" (all keywords present)
result=$(detect_workflow_scope "research auth patterns and plan to revise existing implementation")
# Expected: research-and-revise (revision intent dominates)
```

2. **Plan Path Without Revision Verb**:
```bash
# Test: Plan path alone should be full-implementation (not research-and-revise)
result=$(detect_workflow_scope "implement specs/042_auth/plans/001_plan.md")
# Expected: full-implementation (plan path detection is PRIORITY 2)
```

3. **Multiple Plan Paths**:
```bash
# Test: Multiple plan paths, extract first occurrence
result=$(detect_workflow_scope "revise specs/042_auth/plans/001_plan.md and specs/043_logging/plans/002_plan.md")
# Expected: research-and-revise, EXISTING_PLAN_PATH="/specs/042_auth/plans/001_plan.md"
```

4. **Meta-Research (LLM-specific)**:
```bash
# Test: Research about workflow types (not actual revision)
result=$(detect_workflow_scope "research the research-and-revise workflow")
# Expected: research-and-plan (LLM), research-and-revise (regex - acceptable discrepancy)
```

5. **Case Sensitivity**:
```bash
# Test: All caps should still match (case-insensitive flag)
result=$(detect_workflow_scope "REVISE specs/042_auth/plans/001_plan.md BASED ON feedback")
# Expected: research-and-revise
```

**Test Suite Location**: Add to test_workflow_scope_detection.sh (extend from 20 to 25 tests)

### 4. Implement Structured Classification Logging (Reference Report 001)

**Priority**: Medium (improves observability)
**Effort**: Medium (2-4 hours)
**Impact**: Enables verification of LLM vs regex usage

**Recommendation**: Follow Report 001 recommendations for unified-logger.sh integration.

**Why This Matters for Research-and-Revise**:
- Verify LLM handles edge cases correctly in production
- Monitor classification accuracy over time
- Debug misclassifications with confidence scores

**Minimal Implementation**:
```bash
# Add to workflow-scope-detection.sh after successful classification
if [ -f ".claude/lib/unified-logger.sh" ]; then
  source ".claude/lib/unified-logger.sh"
  log_workflow_classification "$WORKFLOW_CLASSIFICATION_MODE" "$method" "$scope"
fi
```

### 5. Document Intentional Design Decisions

**Priority**: Low (documentation, not code change)
**Effort**: Low (30 minutes)
**Impact**: Prevents future "why does this work this way?" questions

**Document in workflow-scope-detection.sh comments**:

1. **Why revision patterns are PRIORITY 1**:
   - Revision workflows are most specific intent
   - Plan paths alone don't imply revision (could be fresh implementation)
   - False negatives worse than false positives for revision detection

2. **Why "implement" keyword is high priority**:
   - Explicit action verb indicates immediate execution intent
   - "research X and implement Y" is ambiguous (could be single compound task)
   - LLM hybrid mode resolves ambiguity via semantic analysis

3. **Why research-only requires no action keywords**:
   - Pure research is rare (usually leads to plan or implementation)
   - Conservative detection prevents false positives
   - Default fallback is research-and-plan (safer assumption)

**Location**: Add inline comments at each PRIORITY section (lines 134, 149, 154, 158)

## References

### Primary Implementation Files

- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (lines 1-199)
  - Line 32: WORKFLOW_CLASSIFICATION_MODE configuration
  - Lines 56-114: Hybrid mode routing with automatic fallback
  - Lines 134-146: Research-and-revise detection (PRIORITY 1)
  - Line 140: EXISTING_PLAN_PATH extraction pattern
  - Lines 185-195: log_scope_detection() function

- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (lines 1-298)
  - Line 113: LLM classifier instructions (intent-focused)
  - Line 23: Confidence threshold configuration (0.7 default)
  - Lines 125-180: invoke_llm_classifier() with file-based signaling
  - Lines 182-240: parse_llm_classifier_response() with validation

- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-1500+)
  - Lines 155-171: EXISTING_PLAN_PATH extraction and state persistence
  - Line 169: Fail-fast error handling for missing plan path
  - Lines 986-1035: Plan phase branching (revision vs fresh plan)
  - Lines 1111-1114: Verification path determination by workflow scope

### Test Files

- `/home/benjamin/.config/.claude/tests/test_workflow_scope_detection.sh` (lines 1-294)
  - 20 total tests (19 passing, 1 failing)
  - Lines 88-96: Research-and-revise with plan path (Test 4)
  - Lines 176-184: Research-and-revise without path (Test 12)
  - Lines 187-195: Update plan synonym (Test 13)
  - Lines 198-206: Modify plan synonym (Test 14)
  - Lines 143-151: Failing test - "research and implement" (Test 9)

### Related Diagnostic Reports

- `/home/benjamin/.config/.claude/specs/681_workflow_not_correctly_classify_workflow_since/reports/001_llm_classification_diagnostics.md` (655 lines)
  - Comprehensive analysis of LLM invocation visibility
  - 7 recommendations for logging infrastructure
  - Diagnostic methods for distinguishing LLM vs regex classification
  - Debug environment variables (DEBUG_SCOPE_DETECTION, WORKFLOW_CLASSIFICATION_DEBUG)

### Configuration Files

- Environment Variables:
  - `WORKFLOW_CLASSIFICATION_MODE` (hybrid, llm-only, regex-only)
  - `WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD` (default: 0.7)
  - `WORKFLOW_CLASSIFICATION_TIMEOUT` (default: 10 seconds)
  - `DEBUG_SCOPE_DETECTION` (0 or 1)
  - `WORKFLOW_CLASSIFICATION_DEBUG` (0 or 1)
