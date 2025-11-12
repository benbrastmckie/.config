# .claude/ Infrastructure Analysis: Workflow Classification Implementation

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: .claude/ infrastructure implementation (libraries, commands, agents)
- **Report Type**: codebase analysis
- **Complexity Level**: 2

## Executive Summary

The .claude/ infrastructure implements workflow classification through two specialized libraries (workflow-scope-detection.sh and workflow-detection.sh) integrated with a state machine architecture. The system uses regex-based pattern matching to classify user inputs into 5 workflow types (research-only, research-and-plan, research-and-revise, full-implementation, debug-only), enabling conditional phase execution across 3 orchestration commands. Current implementation achieves 92% accuracy with 101-206 lines per library, but has identified edge case vulnerabilities (8% false positive rate) that motivate the hybrid classification improvement (Spec 670).

## Findings

### 1. Dual Library Architecture

**Primary Library**: `.claude/lib/workflow-scope-detection.sh` (101 lines)
- Used by: /coordinate command (state machine architecture)
- Features: 5 workflow types, revision pattern support, plan path extraction
- Detection function: `detect_workflow_scope()` (lines 12-99)
- Priority-based regex patterns (5 levels)

**Fallback Library**: `.claude/lib/workflow-detection.sh` (206 lines)
- Used by: /supervise command (phase-based architecture)
- Features: Smart pattern matching, phase union computation
- Detection function: `detect_workflow_scope()` (lines 70-160)
- Helper function: `should_run_phase()` (lines 178-186)

**State Machine Integration**: `.claude/lib/workflow-state-machine.sh` (lines 16-17, 98-110)
- Integrates both libraries with preference order: workflow-scope-detection.sh → workflow-detection.sh → fallback
- Function: `sm_init()` sources detection library and calls `detect_workflow_scope()`
- Maps scope to terminal state (research → STATE_RESEARCH, plan → STATE_PLAN, etc.)

**Key Architectural Difference**:
- workflow-scope-detection.sh: Optimized for /coordinate (handles revision workflows, plan path extraction)
- workflow-detection.sh: Generic implementation for /supervise (phase computation, no revision support)

### 2. Five Workflow Types and Detection Patterns

**Type 1: research-only** (Phases 0-1)
- Detection: `^research` without "plan|implement" keywords (workflow-scope-detection.sh:68-75)
- Detection: Research pattern without action keywords (workflow-detection.sh:90-93)
- Example: "research async patterns"
- Terminal state: STATE_RESEARCH

**Type 2: research-and-plan** (Phases 0-2)
- Detection: "plan|create.*plan|design" keywords (workflow-scope-detection.sh:83-84)
- Detection: "(research|analyze).*(to|and|for).*(plan|planning)" (workflow-detection.sh:98-101)
- Example: "research and plan authentication system"
- Terminal state: STATE_PLAN

**Type 3: research-and-revise** (Phases 0-2, with plan reuse)
- Detection: PRIORITY 1 pattern - `^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)` (workflow-scope-detection.sh:42)
- Detection: Alternative pattern - "(research|analyze).*(and|then|to).*(revise|update.*plan|modify.*plan)" (workflow-scope-detection.sh:54)
- Example: "revise specs/027_auth/plans/001_plan.md based on feedback"
- Terminal state: STATE_PLAN
- Special feature: Extracts EXISTING_PLAN_PATH from description (lines 46-49)

**Type 4: full-implementation** (Phases 0-4, 6, conditional 5)
- Detection: Plan path pattern - `specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md` (workflow-scope-detection.sh:60)
- Detection: Explicit keywords - "implement|execute|build|add.*feature" (workflow-scope-detection.sh:79, 87-88)
- Detection: Build/add feature pattern (workflow-detection.sh:107-109)
- Example: "implement specs/661_auth/plans/001_implementation.md"
- Terminal state: STATE_COMPLETE

**Type 5: debug-only** (Phases 0, 1, 5)
- Detection: "fix|debug|troubleshoot" keywords (workflow-scope-detection.sh:85-86)
- Detection: "^(fix|debug|troubleshoot).*(bug|issue|error|failure)" (workflow-detection.sh:114-116)
- Example: "debug authentication issue"
- Terminal state: STATE_DEBUG

**Default Fallback**: research-and-plan (conservative choice when no patterns match)

### 3. Priority-Based Classification Logic

**workflow-scope-detection.sh** uses 5-tier priority system:

**PRIORITY 1** (Lines 25-50): Research-and-revise patterns (most specific)
- Revision-first: `^(revise|update|modify).*(plan|implementation).*(accommodate|based on|using|to|for)`
- Handles both simple ("Revise path.md to accommodate...") and complex ("Revise the plan path.md to accommodate...") cases
- Greedy .* allows flexible matching while finding required keywords
- Fixed in commit 1984391a after Issue #661

**PRIORITY 2** (Lines 57-65): Plan path detection (implementation intent)
- Pattern: `specs/[0-9]+_[^/]+/plans/[^[:space:]]+\.md`
- Debug logging available via DEBUG_SCOPE_DETECTION=1
- Only triggers if NOT a revision workflow

**PRIORITY 3** (Lines 67-75): Research-only (explicit research without action)
- Pattern: `^research.*` without "plan|implement|fix|debug|create|add|build"
- Distinguishes pure research from research-with-action

**PRIORITY 4** (Lines 78-80): Explicit implementation keywords
- Pattern: `(^|[[:space:]])(implement|execute)`
- Anchored to word boundaries to avoid false positives

**PRIORITY 5** (Lines 83-88): Other specific patterns
- Plan keywords, debug keywords, feature creation patterns
- Fallback defaults to research-and-plan (line 14)

**Rationale**: Higher priority patterns are more specific and indicative of intent. Order prevents ambiguous inputs from matching wrong patterns.

### 4. State Machine Integration Points

**Location**: `.claude/lib/workflow-state-machine.sh`

**Integration Flow**:
1. `sm_init()` called by orchestration command (line 89)
2. Detects and sources appropriate detection library (lines 100-110)
3. Calls `detect_workflow_scope()` to classify workflow (line 102, 106)
4. Maps scope to terminal state via switch statement (lines 113-133)
5. Initializes state machine with current=STATE_INITIALIZE, terminal=<mapped state>

**Scope → Terminal State Mapping**:
```bash
research-only        → STATE_RESEARCH   (line 115)
research-and-plan    → STATE_PLAN       (line 118)
research-and-revise  → STATE_PLAN       (line 121)
full-implementation  → STATE_COMPLETE   (line 124)
debug-only           → STATE_DEBUG      (line 128)
```

**Checkpoint Integration** (lines 147-198):
- State machine loads workflow scope from checkpoint files
- Supports v2.0 checkpoints (.state_machine wrapper) and v1.3 checkpoints (direct format)
- Migrates phase-based checkpoints to state-based on load

**Export to Environment**: WORKFLOW_SCOPE exported globally (line 78) for use in:
- Error handling diagnostics (error-handling.sh:807)
- Logging and display (unified-logger.sh:720-724)
- Library selection (coordinate.md:158-170)

### 5. Command Integration Patterns

**Pattern A: /coordinate (State Machine Architecture)**

Location: `.claude/commands/coordinate.md`

Integration steps:
1. Initialize state machine via `sm_init()` (line 125)
2. State machine internally calls workflow-scope-detection.sh (via workflow-state-machine.sh)
3. Scope stored in WORKFLOW_SCOPE global variable
4. Save scope to workflow state file for bash block persistence (line 146)
5. Conditional library sourcing based on scope (lines 158-171)
6. Extract EXISTING_PLAN_PATH for research-and-revise workflows (lines 128-143)

Library requirements by scope:
- research-only: 6 libraries (workflow-detection, scope-detection, logger, location, synthesis, error-handling)
- research-and-plan/revise: +2 libraries (metadata-extraction, checkpoint-utils)
- full-implementation: +2 libraries (dependency-analyzer, context-pruning)
- debug-only: Same as research-and-plan

**Pattern B: /supervise (Phase-Based Architecture)**

Integration: Uses workflow-detection.sh directly for phase computation
- Smart pattern matching algorithm (lines 70-160)
- Computes union of required phases from all matching patterns
- Selects minimal workflow type containing all phases
- Uses `should_run_phase()` to conditionally execute phases

**Pattern C: /orchestrate (Hybrid Architecture)**

Integration: Uses workflow-detection.sh (based on grep results)
- 2 occurrences of scope types in orchestrate.md
- Scope detection happens during Phase 0 initialization

### 6. Test Coverage Analysis

**Primary Test Suite**: `.claude/tests/test_workflow_scope_detection.sh`

Test breakdown (line references):
- Test 1 (lines 57-63): Plan path detection with explicit implement keyword
- Test 2 (lines 68-74): Plan keyword detection
- Test 3 (lines 79-85): Research-only without action keywords
- Test 4 (lines 90-96): Revise pattern with plan path and trigger keyword (PRIORITY 1)
- Test 5 (lines 100-107): Explicit implement keyword (PRIORITY 4)
- Test 6 (lines 112-118): Debug pattern detection
- Test 7 (lines 123-129): Execute keyword with plan path
- Test 8 (lines 134-140): Ambiguous input defaults to research-and-plan
- Test 9 (lines 145-150): Research with action keywords (should be research-and-plan)

Additional tests (Tests 10+): Not shown in limit, but file continues with more tests

**Test Framework**: Custom bash testing (lines 1-40)
- PASS_COUNT, FAIL_COUNT, SKIP_COUNT tracking
- Colored output (GREEN, RED, YELLOW, BLUE)
- Helper functions: pass(), fail(), skip(), info()

**Secondary Test Suite**: `.claude/tests/test_workflow_detection.sh`
- Tests workflow-detection.sh library (fallback implementation)
- Independent test coverage for /supervise integration

**Test Results**: Per Spec 670 README (line 101)
- Total: 58 tests
- Passing: 56 tests (96.6% pass rate)
- Failing: 2 tests (3.4% failure rate)
- 10+ edge cases not covered by tests

**Known Test Gaps** (from Spec 670 analysis):
- Edge case: "research the research-and-revise workflow" → false positive (8% error rate)
- Revision patterns with complex descriptions
- Nested keyword scenarios
- Case sensitivity variations

### 7. Path Initialization and Topic Extraction

**Library**: `.claude/lib/workflow-initialization.sh` (200+ lines)

**Core Function**: `initialize_workflow_paths()` (lines 167-200+)

Arguments:
1. WORKFLOW_DESCRIPTION (string): User's workflow description
2. WORKFLOW_SCOPE (string): Already-detected workflow type

3-Step Initialization Pattern:
1. **STEP 1: Scope Validation** (lines 183-196)
   - Validates scope is one of 5 valid types
   - Case statement validation (line 187)
   - Error to stderr on invalid scope

2. **STEP 2: Path Pre-Calculation** (lines 199-200+)
   - Calculates all artifact paths upfront
   - Exports 15+ path variables (LOCATION, SPECS_ROOT, TOPIC_PATH, REPORT_PATHS, etc.)
   - See full list in function documentation (lines 140-157)

3. **STEP 3: Directory Structure Creation**
   - Lazy creation: Only topic root created initially
   - Subdirectories created on-demand by artifact-generating commands

**Special Feature**: Plan Path Extraction (lines 44-123)

Function: `extract_topic_from_plan_path()` (lines 78-123)
- Used by research-and-revise workflows
- Extracts topic directory from existing plan path
- Expected format: `/path/to/specs/NNN_topic/plans/NNN_plan.md`
- Regex validation: `/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}_[^.]+\.md$` (line 95)
- Extraction: dirname → dirname → basename (lines 108-111)
- Validation: Topic name matches `^[0-9]{3}_[^/]+$` (line 114)

Returns: Topic directory name (e.g., "657_topic") for reuse

**Performance**: Part of Phase 0 optimization (85% token reduction vs agent-based detection)

### 8. Logging and Observability Integration

**Error Handling Integration**: `.claude/lib/error-handling.sh`

Workflow scope in error diagnostics (line 807):
```bash
echo "  - Scope: ${WORKFLOW_SCOPE:-<not set>}"
```

Included in Component 4 (Context) of error reports:
- Workflow description
- Scope type
- Current state
- Terminal state
- Topic path

**Logging Integration**: `.claude/lib/unified-logger.sh`

Display function: `display_brief_summary()` (lines 718-724)
```bash
echo "✓ Workflow complete: $WORKFLOW_SCOPE"
case "$WORKFLOW_SCOPE" in
  research-only)
    echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
  ...
```

Scope-specific completion messages:
- research-only: Report count and location
- research-and-plan: Report count + plan file path
- full-implementation: Summary of all artifacts created
- debug-only: Debug report location

**Debug Logging**: workflow-scope-detection.sh (lines 63-65, 91-96)

Environment variable: `DEBUG_SCOPE_DETECTION=1`

Output format:
```
[DEBUG] Scope Detection: description='<input>'
[DEBUG] Scope Detection: detected scope='<result>'
[DEBUG] Scope Detection: existing_plan='<path>' (if research-and-revise)
[DEBUG] Scope Detection: detected plan path in workflow description
```

Logging locations: stderr (>&2) to avoid interfering with function returns

### 9. Limitations and Extension Points

**Current Limitations** (driving Spec 670 improvements):

1. **Regex Ambiguity** (workflow-scope-detection.sh:54)
   - Pattern: `(research|analyze).*(and |then |to ).*(revise|update.*plan|modify.*plan)`
   - Issue: Greedy matching causes false positives when discussing workflow types
   - Example: "research the research-and-revise workflow" → research-and-revise (WRONG)
   - Expected: research-and-plan
   - Root cause: Cannot distinguish intent from discussion

2. **Case Sensitivity**
   - All patterns use `-i` flag (case-insensitive)
   - Could cause unexpected matches with unusual capitalization
   - No tests for capitalization edge cases

3. **Keyword Collisions**
   - "implement" in "implementation plan" → false positive for full-implementation
   - Mitigated by pattern ordering (plan patterns checked before implement)
   - Still fragile to new keyword combinations

4. **No Confidence Scoring**
   - Regex returns binary classification (match or no match)
   - No indication of classification certainty
   - Makes fallback decisions difficult

5. **Limited Context Understanding**
   - Cannot interpret negations ("don't implement X")
   - Cannot understand compound requests ("research X, then implement Y")
   - Cannot detect sarcasm or hypotheticals

**Extension Points for Hybrid Classification**:

1. **detect_workflow_scope_v2()** function (proposed in Spec 670)
   - Wrapper around detect_workflow_scope() with LLM integration
   - Backward compatible with existing callers
   - Environment variable toggle: WORKFLOW_CLASSIFICATION_MODE

2. **Confidence Scoring Integration**
   - LLM returns confidence score (0.0-1.0)
   - Threshold-based fallback (default: 0.7)
   - Low confidence → fallback to regex

3. **Debug Logging Enhancement**
   - Log LLM classification attempts
   - Log fallback triggers
   - Log confidence scores
   - Structured log format for analysis

4. **A/B Testing Framework**
   - Compare LLM vs regex classifications
   - Track agreement rate
   - Identify systematic differences
   - Inform prompt tuning

5. **Regression Prevention**
   - All 56 existing tests must pass with hybrid system
   - New tests for edge cases that motivated change
   - Fallback ensures no classification failures

**Integration Requirements** (from Spec 670 architecture):

Location for new library: `.claude/lib/workflow-llm-classifier.sh` (200 lines)

Key functions:
- `classify_workflow_llm()` - Invoke Haiku via AI assistant
- `build_llm_classifier_input()` - Build prompt with type definitions
- `invoke_llm_classifier()` - File-based subagent protocol
- `parse_llm_classifier_response()` - Validate JSON response
- `detect_workflow_scope_v2()` - Unified hybrid entry point

Integration points:
- workflow-state-machine.sh: Replace detect_workflow_scope() call with v2
- coordinate.md: Add configuration variables
- Library sourcing: Add workflow-llm-classifier.sh to required libraries
- Tests: Create test_llm_classifier.sh (150 lines) and test_scope_detection_ab.sh (100 lines)

## Recommendations

### 1. Preserve Dual Library Architecture During Hybrid Migration

**Rationale**: workflow-scope-detection.sh and workflow-detection.sh serve different commands with different architectural needs. The hybrid classification improvement should maintain this separation.

**Implementation**:
- Create `detect_workflow_scope_v2()` wrapper in BOTH libraries
- Each library's v2 function wraps its respective v1 implementation for fallback
- Shared LLM logic in `.claude/lib/workflow-llm-classifier.sh` (new)
- Environment variable toggle affects both libraries identically

**Benefit**: /coordinate and /supervise can adopt hybrid classification independently, enabling phased rollout.

### 2. Add Comprehensive Test Coverage for Edge Cases Before Hybrid Rollout

**Rationale**: Current 56/58 tests (96.6% pass rate) don't cover the 10+ edge cases that motivated Spec 670. Hybrid system should fix these gaps.

**Implementation**:
- Add 15+ edge case tests to test_workflow_scope_detection.sh
- Include: nested keywords, discussion vs intent, negations, compound requests
- All tests must pass with BOTH regex-only and hybrid modes
- Document expected vs actual behavior for each edge case

**Benefit**: Clear success criteria for hybrid classification. Prevents regressions. Provides A/B comparison dataset.

### 3. Implement Structured Logging for Classification Decisions

**Rationale**: Current DEBUG_SCOPE_DETECTION provides basic logging but lacks structure for analysis. Hybrid system needs richer observability.

**Implementation**:
- Create `.claude/data/logs/workflow-classification.log` (structured format)
- Log entries: timestamp, input_hash, llm_result, llm_confidence, fallback_triggered, final_classification, method, latency_ms
- Query utilities in unified-logger.sh for filtering and analysis
- Dashboard for tracking fallback rate, confidence distribution, agreement rate

**Benefit**: Enables data-driven tuning of confidence threshold, identifies prompt improvements, monitors production performance.

### 4. Use File-Based Subagent Protocol for LLM Invocation

**Rationale**: AI assistant integration requires coordination between bash library and LLM. File-based signaling is reliable and testable.

**Implementation** (per Spec 670 architecture):
- Request file: `/tmp/llm_classification_request_$$.json` (workflow description + type definitions)
- Response file: `/tmp/llm_classification_response_$$.json` (classification + confidence)
- Timeout: 10 seconds (poll every 100ms)
- Cleanup: Remove files after parsing (trap handlers)

**Benefit**: Avoids bash/LLM coupling. Enables unit testing with mock responses. Timeout prevents hangs.

### 5. Prioritize Phase 1-3 Implementation Before Rollout Phases

**Rationale**: Spec 670 implementation plan has 7-10 week timeline with 4-6 weeks for rollout. Critical path is Phases 1-3 (library + integration + testing).

**Recommendation**:
- Focus on Phase 1 (Core Library): workflow-llm-classifier.sh + 30+ unit tests
- Then Phase 2 (Integration): detect_workflow_scope_v2() + 20+ integration tests
- Then Phase 3 (Testing & QA): A/B framework + 50+ test descriptions
- Defer Phases 4-5 (Alpha/Beta rollout) until core system proven

**Acceptance criteria before rollout**:
- 90%+ test coverage on workflow-llm-classifier.sh
- 100% backward compatibility (all 56 existing tests pass)
- 90%+ agreement rate between LLM and regex on A/B dataset
- <20% fallback rate in testing
- <500ms p95 latency for LLM classifications

**Benefit**: De-risks rollout by validating core functionality first. Enables faster iteration on library design before user impact.

## References

### Primary Source Files

1. **`.claude/lib/workflow-scope-detection.sh`** (101 lines)
   - Lines 12-99: detect_workflow_scope() function
   - Lines 42-50: PRIORITY 1 - Research-and-revise pattern
   - Lines 57-65: PRIORITY 2 - Plan path detection
   - Lines 67-75: PRIORITY 3 - Research-only pattern
   - Lines 78-88: PRIORITY 4-5 - Implementation and other patterns
   - Lines 91-96: Debug logging (DEBUG_SCOPE_DETECTION)

2. **`.claude/lib/workflow-detection.sh`** (206 lines)
   - Lines 70-160: detect_workflow_scope() function
   - Lines 90-93: Research-only pattern detection
   - Lines 98-101: Research-and-plan pattern detection
   - Lines 107-109: Full-implementation pattern detection
   - Lines 114-116: Debug-only pattern detection
   - Lines 178-186: should_run_phase() helper function

3. **`.claude/lib/workflow-state-machine.sh`** (200+ lines)
   - Lines 16-17: Dependencies comment (scope detection libraries)
   - Lines 89-142: sm_init() function (state machine initialization)
   - Lines 100-110: Library sourcing with fallback logic
   - Lines 113-133: Scope to terminal state mapping
   - Lines 147-198: sm_load() function (checkpoint loading with scope migration)

4. **`.claude/lib/workflow-initialization.sh`** (200+ lines)
   - Lines 78-123: extract_topic_from_plan_path() function
   - Lines 167-200+: initialize_workflow_paths() function (3-step pattern)
   - Lines 183-196: STEP 1 - Scope validation
   - Lines 199-200+: STEP 2 - Path pre-calculation

5. **`.claude/commands/coordinate.md`** (2,500-3,000 lines estimated)
   - Lines 47-290: State Machine Initialization sections (Parts 1-2)
   - Lines 125: sm_init() invocation
   - Lines 128-143: EXISTING_PLAN_PATH extraction for research-and-revise
   - Lines 146: Save scope to workflow state
   - Lines 158-171: Conditional library sourcing based on scope

6. **`.claude/lib/error-handling.sh`** (800+ lines)
   - Line 807: Workflow scope in error diagnostics

7. **`.claude/lib/unified-logger.sh`** (720+ lines)
   - Lines 718-724: display_brief_summary() with scope-specific messages

### Test Files

8. **`.claude/tests/test_workflow_scope_detection.sh`** (150+ lines estimated)
   - Lines 1-40: Test framework (pass/fail/skip helpers)
   - Lines 47: Source workflow-scope-detection.sh
   - Lines 57-150+: 9+ test cases covering all workflow types

9. **`.claude/tests/test_workflow_detection.sh`**
   - Tests for workflow-detection.sh library (fallback implementation)

### Documentation Files

10. **`.claude/docs/concepts/patterns/workflow-scope-detection.md`** (150+ lines read)
    - Lines 1-44: Problem statement and motivation
    - Lines 45-72: Solution overview (4 scope types + keyword detection)
    - Lines 76-108: Implementation details (library functions and examples)
    - Lines 110-150+: Phase name mapping and usage patterns

11. **`.claude/specs/670_workflow_classification_improvement/README.md`** (481 lines)
    - Lines 29-35: Problem statement (8% false positive rate)
    - Lines 97-114: Current implementation analysis (regex patterns, test results)
    - Lines 116-139: LLM-based classification design (Haiku model, prompt engineering)
    - Lines 144-162: Comparative analysis (fallback scenarios, risk profile)
    - Lines 164-191: Implementation architecture (component breakdown, key functions)
    - Lines 195-246: Implementation plan (6 phases, 24 tasks)

### Related Specifications

12. **`.claude/specs/670_workflow_classification_improvement/reports/001_llm_based_classification_research.md`** (32 KB)
    - Haiku model design, cost analysis, prompt engineering

13. **`.claude/specs/670_workflow_classification_improvement/reports/002_comparative_analysis_and_synthesis.md`** (56 KB)
    - LLM vs regex comparison, decision framework

14. **`.claude/specs/670_workflow_classification_improvement/reports/003_implementation_architecture.md`** (82 KB)
    - Complete technical specifications, 11 sections

15. **`.claude/specs/670_workflow_classification_improvement/plans/001_hybrid_classification_implementation.md`** (48 KB)
    - 6-phase plan, 24 tasks, acceptance criteria
