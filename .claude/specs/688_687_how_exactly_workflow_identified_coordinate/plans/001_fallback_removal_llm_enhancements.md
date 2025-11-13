# Fallback Removal and LLM Filename Generation Enhancement Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Remove regex fallback mechanism and enhance LLM classification with filename generation
- **Scope**: Modify workflow classification system to enforce fail-fast LLM-only mode with descriptive filename generation
- **Estimated Phases**: 7
- **Estimated Hours**: 22
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 148.0
- **Research Reports**:
  - [Fallback Removal Analysis](../reports/001_fallback_removal_analysis.md)
  - [LLM Topic and Filename Generation](../reports/002_llm_topic_filename_generation.md)
  - [Implemented Plan Review](../reports/003_implemented_plan_review.md)
  - [Clean-Break Requirements](../reports/004_clean_break_requirements.md)
  - [Workflow Identification Architecture](../../687_how_exactly_workflow_identified_coordinate/reports/001_workflow_identification.md)
  - [Research Topic Handling](../../687_how_exactly_workflow_identified_coordinate/reports/002_research_topic_handling.md)

## Overview

This plan implements two major architectural changes to the workflow classification system using a **clean-break approach** (no backwards compatibility for hybrid mode):

1. **Objective 1: Remove Regex Fallback Mechanism** - Eliminate automatic regex fallback from hybrid/llm-only modes and delete hybrid mode entirely, enforcing fail-fast error handling for LLM classification failures. Preserve regex-only mode as intentional configuration option for offline development.
2. **Objective 2: Enhanced LLM Response Structure** - Enhance LLM classifier to return detailed research topic descriptions (for streamlined agent prompts) AND filesystem-safe filename slugs, with three-tier validation fallback to ensure zero operational risk.

The hybrid filename validation approach (Strategy 3 from report 002) provides LLM-generated slugs with sanitization fallback, ensuring high-quality descriptive filenames while maintaining filesystem safety. Clean-break approach deletes hybrid classification mode entirely (not preserved for backwards compatibility).

## Research Summary

Key findings from research reports:

**Fallback Mechanism Architecture** (Report 001):
- Regex fallback invoked at 6 distinct code paths when LLM fails
- Functions to remove: `fallback_comprehensive_classification()`, `classify_workflow_regex()`, `infer_complexity_from_keywords()`, `generate_generic_topics()` (~180 lines)
- Current hybrid mode provides zero operational risk through automatic fallback
- Removing fallback introduces failure scenarios: LLM timeout (2-5%), API errors (1%), low confidence (3-8%)

**LLM Filename Generation Design** (Report 002):
- Current system: Generic placeholders (`001_topic1.md`) with post-research discovery reconciliation
- Proposed hybrid approach: LLM suggests `filename_slugs`, validation fallback to `sanitize_topic_name()`
- Three-stage validation: LLM slug (preferred) → sanitized subtopic (fallback) → generic topicN (ultimate fallback)
- Benefits: Zero operational risk, semantic filenames from start, eliminates 30 lines of discovery code

**Current Architecture** (Reports 687/001, 687/002):
- `sm_init()` invokes `classify_workflow_comprehensive()` during Phase 0 initialization
- Returns three dimensions: `workflow_type`, `research_complexity`, `subtopics[]`
- State machine initialization has fallback at lines 367-376 (must be removed)
- Topic names flow through `RESEARCH_TOPICS_JSON` → agent prompt variables
- Report paths dynamically allocated in `initialize_workflow_paths()` (lines 394-408)

**Design Decisions** (Clean-Break Approach):
- **Remove hybrid mode entirely** - Delete classification mode (not just change default), no backwards compatibility
- **Rename fallback function** - `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()` for clarity
- **Preserve regex-only mode** - Intentional primary classifier for offline development (not a fallback)
- Use hybrid filename generation (LLM suggestions with validation fallback) for zero operational risk
- Implement fail-fast error handling with actionable user messages (no automatic fallback to regex)
- Add structured logging for slug generation strategy tracking and LLM performance monitoring
- Enhanced LLM response: detailed topic descriptions + filename slugs (streamlines agent prompt creation)

## Success Criteria

- [ ] Hybrid mode deleted entirely from all code and documentation (clean-break approach)
- [ ] Automatic regex fallback removed from llm-only mode (5 invocation points)
- [ ] `fallback_comprehensive_classification()` renamed to `classify_workflow_regex_comprehensive()`
- [ ] Regex-only mode preserved as intentional primary classifier (not fallback)
- [ ] LLM classifier returns enhanced response: detailed topic descriptions + `filename_slugs` field
- [ ] `filename_slugs` field matches `subtopics` array length exactly
- [ ] Three-tier validation ensures filesystem-safe filenames (LLM → sanitize → generic)
- [ ] Fail-fast error handling implemented with clear error messages (no automatic fallback)
- [ ] Discovery reconciliation code removed from /coordinate (lines 685-714)
- [ ] LLM slug acceptance rate >90% measured via structured logging
- [ ] Zero file creation failures due to invalid filenames
- [ ] Test suite updated: remove hybrid mode tests, add fail-fast verification tests
- [ ] Documentation simplified: 2 modes only (llm-only default, regex-only offline)
- [ ] Configuration validation rejects hybrid mode (error: "hybrid mode removed")
- [ ] 100% of existing llm-only and regex-only tests pass with new implementation

## Technical Design

### Architecture Changes

**1. LLM Response Schema Enhancement**

Current schema:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": ["Implementation architecture", "Integration patterns"],
  "reasoning": "..."
}
```

Enhanced schema (detailed topics + filename slugs):
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Implementation architecture",
      "detailed_description": "Analyze current implementation patterns, identify architectural decisions, evaluate scalability approaches, and document integration points with existing systems.",
      "filename_slug": "implementation_architecture",
      "research_focus": "Key questions: How is the current system architected? What patterns are used? Areas to investigate: module structure, dependency management, state handling."
    },
    {
      "short_name": "Integration patterns",
      "detailed_description": "Research best practices for integrating new features with existing codebase, identify common integration patterns, and analyze potential conflicts or compatibility issues.",
      "filename_slug": "integration_patterns",
      "research_focus": "Key questions: How should new features integrate? What are the extension points? Areas to investigate: API design, event handling, plugin architecture."
    }
  ],
  "reasoning": "..."
}
```

**Key Enhancements**:
1. `research_topics` array replaces flat `subtopics` array (richer structure)
2. `detailed_description` provides comprehensive context for research agents (150-250 words)
3. `research_focus` gives specific questions and investigation areas (streamlines agent prompts)
4. `filename_slug` provides filesystem-safe filename (validated separately)

**2. Validation and Fallback Flow**

```
┌─────────────────────────────────────┐
│ LLM Classification                  │
│ Returns filename_slugs[]            │
└─────────────┬───────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │ Validate Each Slug  │
    │ ^[a-z0-9_]{1,50}$  │
    └─────────┬───────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼ VALID             ▼ INVALID
┌─────────┐      ┌──────────────────┐
│ Use LLM │      │ Sanitize Subtopic│
│ Slug    │      │ (fallback)       │
└─────┬───┘      └──────┬───────────┘
      │                 │
      └────────┬────────┘
               ▼
    ┌──────────────────────┐
    │ NNN_validated_slug.md│
    └──────────────────────┘
```

**3. Error Handling Pattern**

At each of 6 failure points:
1. Clear error message (what failed)
2. Workflow context (description that failed)
3. Actionable suggestion (how to fix)
4. Non-zero exit code (fail-fast)

Example:
```bash
echo "ERROR: LLM classification timed out after 10s" >&2
echo "  Workflow: $workflow_description" >&2
echo "  Suggestion: Simplify description or increase WORKFLOW_CLASSIFICATION_TIMEOUT" >&2
return 1
```

### Modified Files

**Core Classification Libraries**:
- `.claude/lib/workflow-llm-classifier.sh` - Add filename_slugs field to prompt and validation
- `.claude/lib/workflow-scope-detection.sh` - Remove fallback functions, add fail-fast handlers
- `.claude/lib/workflow-state-machine.sh` - Remove fallback at sm_init (lines 367-376)
- `.claude/lib/workflow-initialization.sh` - Implement hybrid filename generation (lines 394-408)
- `.claude/lib/error-handling.sh` - Add LLM-specific error types and handlers

**Commands**:
- `.claude/commands/coordinate.md` - Remove discovery reconciliation (lines 685-714)
- `.claude/commands/orchestrate.md` - Remove similar discovery patterns (if present)

**Tests**:
- `.claude/tests/test_scope_detection.sh` - Remove hybrid/regex tests, add LLM failure scenarios
- `.claude/tests/test_topic_filename_generation.sh` - New test suite for slug validation
- `.claude/tests/test_scope_detection_ab.sh` - Update A/B comparison tests
- `.claude/tests/bench_workflow_classification.sh` - Update benchmarks for LLM-only mode

**Documentation**:
- `.claude/docs/concepts/patterns/llm-classification-pattern.md` - Update configuration table
- `.claude/docs/guides/filename-generation-guide.md` - New comprehensive guide
- `.claude/docs/guides/migration/fallback-removal-migration.md` - New migration guide

## Implementation Phases

### Phase 1: LLM Prompt and Response Enhancement
dependencies: []

**Objective**: Enhance LLM classifier to generate detailed research topics with filename slugs

**Complexity**: Medium

**Files Modified**:
- `.claude/lib/workflow-llm-classifier.sh` (lines 148-208, 267-379)

**Tasks**:
- [x] Update `build_llm_classifier_input()` to request enhanced `research_topics` structure (file: .claude/lib/workflow-llm-classifier.sh, lines 181-182)
- [x] Add prompt guidance: "research_topics (array of objects, one per subtopic, each containing: {short_name: string, detailed_description: string (150-250 words providing comprehensive research context), filename_slug: string (filesystem-safe lowercase alphanumeric + underscores, max 50 chars), research_focus: string (specific questions and investigation areas)})"
- [x] Specify that `research_topics` array length must match `research_complexity` exactly
- [x] Update `parse_llm_classifier_response()` to validate enhanced structure (file: .claude/lib/workflow-llm-classifier.sh, lines 290-332)
- [x] Add validation: research_topics field exists and is array
- [x] Add validation: research_topics count matches research_complexity
- [x] Add validation: each topic has required fields (short_name, detailed_description, filename_slug, research_focus)
- [x] Add validation: each filename_slug matches regex `^[a-z0-9_]{1,50}$`
- [x] Add validation: detailed_description length 50-500 characters (ensure comprehensive but not excessive)
- [x] Return descriptive error for validation failures (include which topic/field failed and why)
- [x] Extract and export topics in backwards-compatible format for existing code (RESEARCH_TOPICS_JSON with short_name values)

**Testing**:
```bash
# Test LLM prompt includes filename_slugs instruction
grep -q "filename_slugs" .claude/lib/workflow-llm-classifier.sh

# Test validation catches invalid slugs
source .claude/lib/workflow-llm-classifier.sh
export WORKFLOW_CLASSIFICATION_MODE="llm-only"

# Valid slugs
echo '{"workflow_type":"research-only","confidence":0.95,"research_complexity":2,"subtopics":["Auth patterns","Security"],"filename_slugs":["auth_patterns","security"],"reasoning":"test"}' | parse_llm_classifier_response || echo "FAIL: Valid slugs rejected"

# Invalid slugs (uppercase)
echo '{"workflow_type":"research-only","confidence":0.95,"research_complexity":2,"subtopics":["Auth patterns","Security"],"filename_slugs":["Auth_Patterns","Security"],"reasoning":"test"}' | parse_llm_classifier_response && echo "FAIL: Invalid slugs accepted"

# Mismatched count
echo '{"workflow_type":"research-only","confidence":0.95,"research_complexity":2,"subtopics":["Auth patterns","Security"],"filename_slugs":["auth_patterns"],"reasoning":"test"}' | parse_llm_classifier_response && echo "FAIL: Mismatched count accepted"
```

**Expected Duration**: 3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 1 - LLM Prompt and Response Enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

[COMPLETED]

---

### Phase 2: Hybrid Filename Generation with Validation Fallback
dependencies: [1]

**Objective**: Implement three-tier validation (LLM slug → sanitized subtopic → generic fallback)

**Complexity**: High

**Files Modified**:
- `.claude/lib/workflow-initialization.sh` (lines 394-408)
- `.claude/lib/unified-logger.sh` (new function: `log_slug_generation()`)

**Tasks**:
- [ ] Create `validate_and_generate_filename_slugs()` function in workflow-initialization.sh
- [ ] Extract LLM-provided filename_slugs from classification result
- [ ] For each slug: validate against regex `^[a-z0-9_]{1,50}$`
- [ ] If slug valid: use LLM slug (log: "Using LLM-generated slug")
- [ ] If slug invalid or missing: call `sanitize_topic_name()` on subtopic (log: "Invalid LLM slug, sanitizing subtopic")
- [ ] If subtopic empty: use generic fallback `topicN` (log: "Missing subtopic, using generic fallback")
- [ ] Update `initialize_workflow_paths()` to use validated slugs in path allocation (replace `_topic${i}` pattern)
- [ ] Add filesystem constraint validation (path separator injection check, 255-byte filename limit)
- [ ] Implement `log_slug_generation()` in unified-logger.sh with DEBUG/INFO/WARN/ERROR levels
- [ ] Add structured logging for slug generation strategy tracking

**Testing**:
```bash
# Test hybrid validation with valid LLM slugs
export RESEARCH_COMPLEXITY=2
export RESEARCH_TOPICS_JSON='["Implementation architecture","Integration patterns"]'
classification_result='{"workflow_type":"research-and-plan","confidence":0.95,"research_complexity":2,"subtopics":["Implementation architecture","Integration patterns"],"filename_slugs":["implementation_architecture","integration_patterns"],"reasoning":"test"}'

source .claude/lib/workflow-initialization.sh
initialize_workflow_paths "/tmp/test_topic" "$RESEARCH_COMPLEXITY" "$classification_result"

# Verify REPORT_PATH_0 uses LLM slug
echo "$REPORT_PATH_0" | grep -q "001_implementation_architecture.md" || echo "FAIL: LLM slug not used"

# Test fallback to sanitization with invalid slugs
classification_result='{"workflow_type":"research-and-plan","confidence":0.95,"research_complexity":2,"subtopics":["Implementation architecture","Integration patterns"],"filename_slugs":["Implementation-Architecture!","integration patterns"],"reasoning":"test"}'

initialize_workflow_paths "/tmp/test_topic" "$RESEARCH_COMPLEXITY" "$classification_result"

# Verify REPORT_PATH_0 uses sanitized version
echo "$REPORT_PATH_0" | grep -q "001_implementation_architecture.md" || echo "FAIL: Sanitization fallback failed"

# Test ultimate fallback with missing subtopics
classification_result='{"workflow_type":"research-and-plan","confidence":0.95,"research_complexity":1,"subtopics":[""],"filename_slugs":[""],"reasoning":"test"}'

initialize_workflow_paths "/tmp/test_topic" "$RESEARCH_COMPLEXITY" "$classification_result"

# Verify generic fallback
echo "$REPORT_PATH_0" | grep -q "001_topic1.md" || echo "FAIL: Generic fallback failed"
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 2 - Hybrid Filename Generation with Validation Fallback`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Remove Hybrid Mode and Automatic Regex Fallback (Clean-Break)
dependencies: [1, 2]

**Objective**: Delete hybrid mode entirely and remove automatic regex fallback, preserving regex-only mode as intentional classifier

**Complexity**: Medium

**Files Modified**:
- `.claude/lib/workflow-scope-detection.sh` (lines 32, 54-57, 62-78, 82-85, 93-97, 100-104, 114-141, 289-292)

**Tasks**:
- [ ] Change `WORKFLOW_CLASSIFICATION_MODE` default from `hybrid` to `llm-only` (line 32)
- [ ] **DELETE entire hybrid mode case block** (lines 62-78) - clean-break approach, no preservation
- [ ] Add configuration validation rejecting hybrid mode with error: "hybrid mode removed in clean-break update"
- [ ] **RENAME** `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()` (lines 114-141) - clarifies it's intentional regex classifier, not fallback
- [ ] Remove automatic fallback call at empty description validation (lines 54-57) - replace with direct `return 1`
- [ ] Remove automatic fallback call in llm-only mode failure (lines 82-85) - replace with direct `return 1`
- [ ] Remove automatic fallback call in invalid mode handler (lines 100-104) - replace with direct `return 1`
- [ ] Update regex-only mode case (lines 93-97) to call renamed function: `classify_workflow_regex_comprehensive()`
- [ ] Preserve `classify_workflow_regex()` function (lines 212-268) - needed by regex-only mode
- [ ] Preserve `infer_complexity_from_keywords()` function (lines 149-188) - needed by regex-only mode
- [ ] Preserve `generate_generic_topics()` function (lines 195-205) - needed by regex-only mode
- [ ] Update function exports: rename fallback function, preserve classifier functions (lines 289-292)
- [ ] Add clear fail-fast error messages with context and suggestions at all removal points

**Testing**:
```bash
# Test llm-only mode is now default
source .claude/lib/workflow-scope-detection.sh
[ "$WORKFLOW_CLASSIFICATION_MODE" = "llm-only" ] || echo "FAIL: Default mode not llm-only"

# Test hybrid mode is rejected (clean-break)
export WORKFLOW_CLASSIFICATION_MODE="hybrid"
classify_workflow_comprehensive "test" 2>&1 | grep -q "hybrid mode removed" || echo "FAIL: Hybrid mode not rejected"

# Test renamed function exists (not deleted)
declare -f classify_workflow_regex_comprehensive >/dev/null 2>&1 || echo "FAIL: classify_workflow_regex_comprehensive not found"

# Test old function name is gone
declare -f fallback_comprehensive_classification >/dev/null 2>&1 && echo "FAIL: fallback_comprehensive_classification still exists (should be renamed)"

# Test regex-only mode still works using renamed function
export WORKFLOW_CLASSIFICATION_MODE="regex-only"
classify_workflow_comprehensive "research authentication patterns" >/dev/null || echo "FAIL: regex-only mode broken"

# Test supporting functions preserved (needed by regex-only mode)
declare -f classify_workflow_regex >/dev/null 2>&1 || echo "FAIL: classify_workflow_regex deleted (should be preserved)"
declare -f infer_complexity_from_keywords >/dev/null 2>&1 || echo "FAIL: infer_complexity_from_keywords deleted (should be preserved)"
declare -f generate_generic_topics >/dev/null 2>&1 || echo "FAIL: generate_generic_topics deleted (should be preserved)"

# Test llm-only mode fails fast on LLM error (no automatic fallback)
export WORKFLOW_CLASSIFICATION_MODE="llm-only"
export WORKFLOW_CLASSIFICATION_TIMEOUT=0.001  # Force timeout
output=$(classify_workflow_comprehensive "research authentication patterns" 2>&1)
echo "$output" | grep -q "ERROR" || echo "FAIL: No fail-fast error on LLM timeout"
echo "$output" | grep -q "fallback" && echo "FAIL: Automatic fallback still occurring (should be removed)"
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 3 - Remove Regex Fallback and Enforce LLM-Only Mode`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Fail-Fast Error Handling (2-Mode System)
dependencies: [3]

**Objective**: Implement comprehensive fail-fast error handling for llm-only and regex-only modes (no automatic fallback)

**Complexity**: Medium

**Files Modified**:
- `.claude/lib/error-handling.sh` (add new error types and handler function)
- `.claude/lib/workflow-state-machine.sh` (lines 367-376)
- `.claude/lib/workflow-scope-detection.sh` (update error handling at failure points)

**Tasks**:
- [ ] Add LLM error types to error-handling.sh: `ERROR_TYPE_LLM_TIMEOUT`, `ERROR_TYPE_LLM_API_ERROR`, `ERROR_TYPE_LLM_LOW_CONFIDENCE`, `ERROR_TYPE_LLM_PARSE_ERROR`, `ERROR_TYPE_INVALID_MODE`
- [ ] Implement `handle_llm_classification_failure()` function in workflow-llm-classifier.sh
- [ ] Add error context: error type, error message, workflow description, suggested mode (for offline: suggest regex-only)
- [ ] Add actionable suggestions for each error type:
  - Timeout: "Increase WORKFLOW_CLASSIFICATION_TIMEOUT or use regex-only mode for offline development"
  - API error: "Check network connection or use regex-only mode for offline development"
  - Low confidence: "Rephrase workflow description with more specific keywords"
  - Invalid mode (hybrid): "hybrid mode removed in clean-break update. Use llm-only (default) or regex-only (offline)"
- [ ] Update state machine initialization (workflow-state-machine.sh:367-376): remove fallback block entirely, replace with fail-fast critical error
- [ ] Update empty description validation (workflow-scope-detection.sh:54-57): direct `return 1` after error message
- [ ] Update invalid mode handling (workflow-scope-detection.sh:100-104): detect hybrid mode specifically, provide clean-break explanation
- [ ] Ensure all error messages follow pattern: "ERROR: [what] | Context: [workflow] | Suggestion: [action]"
- [ ] Test failure scenarios return non-zero exit codes: LLM timeout, API error, low confidence, empty input, hybrid mode
- [ ] Verify checkpoint recovery integration (partial progress preserved on failure)

**Testing**:
```bash
# Test error types defined
source .claude/lib/error-handling.sh
[ -n "$ERROR_TYPE_LLM_TIMEOUT" ] || echo "FAIL: ERROR_TYPE_LLM_TIMEOUT not defined"

# Test handle_llm_classification_failure exists
declare -f handle_llm_classification_failure >/dev/null 2>&1 || echo "FAIL: handle_llm_classification_failure not defined"

# Test timeout error handling
export WORKFLOW_CLASSIFICATION_MODE="llm-only"
export WORKFLOW_CLASSIFICATION_TIMEOUT=0.001
output=$(classify_workflow_comprehensive "test" 2>&1)
echo "$output" | grep -q "ERROR.*timed out" || echo "FAIL: Timeout error not clear"
echo "$output" | grep -q "Suggestion" || echo "FAIL: No actionable suggestion"

# Test empty description error
output=$(classify_workflow_comprehensive "" 2>&1)
echo "$output" | grep -q "ERROR.*empty" || echo "FAIL: Empty description error not clear"

# Test invalid mode error
export WORKFLOW_CLASSIFICATION_MODE="invalid-mode"
output=$(classify_workflow_comprehensive "test" 2>&1)
echo "$output" | grep -q "ERROR.*invalid.*MODE" || echo "FAIL: Invalid mode error not clear"

# Test state machine initialization fail-fast
source .claude/lib/workflow-state-machine.sh
export WORKFLOW_CLASSIFICATION_TIMEOUT=0.001
sm_init "test" "coordinate" 2>&1 | grep -q "CRITICAL ERROR" || echo "FAIL: sm_init doesn't fail-fast"
```

**Expected Duration**: 3 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 4 - Fail-Fast Error Handling at All Invocation Points`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Remove Discovery Reconciliation from Commands
dependencies: [2]

**Objective**: Eliminate post-research filename discovery code (filenames now pre-calculated correctly)

**Complexity**: Low

**Files Modified**:
- `.claude/commands/coordinate.md` (lines 685-714)
- `.claude/commands/orchestrate.md` (similar patterns, if present)

**Tasks**:
- [ ] Locate dynamic discovery code block in coordinate.md (lines 685-714)
- [ ] Replace discovery loop with assertion that files exist at pre-calculated paths
- [ ] Update comment: "Report paths pre-calculated with validated slugs - no discovery needed"
- [ ] Verify REPORT_PATHS array already contains correct paths from Phase 2 initialization
- [ ] Check orchestrate.md for similar discovery patterns
- [ ] Remove discovery patterns from orchestrate.md if present
- [ ] Update any related discovery logic in supervise.md (if exists)
- [ ] Add verification checkpoint after research phase: assert all expected report files exist

**Testing**:
```bash
# Test discovery code removed
grep -q "DISCOVERED_REPORTS" .claude/commands/coordinate.md && echo "FAIL: Discovery code still present"

# Test assertion logic added
grep -q "Report paths pre-calculated" .claude/commands/coordinate.md || echo "FAIL: No assertion comment"

# Integration test: Run coordinate with LLM classification
# Verify report filenames are descriptive (not generic topic1, topic2)
cd /tmp
export WORKFLOW_CLASSIFICATION_MODE="llm-only"
# Mock /coordinate invocation with research-only scope
# Expect files like: 001_implementation_architecture.md, not 001_topic1.md
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 5 - Remove Discovery Reconciliation from Commands`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Update Test Suite for 2-Mode System (Clean-Break)
dependencies: [3, 4]

**Objective**: Remove hybrid mode tests, add fail-fast verification tests, update benchmarks for 2-mode system

**Complexity**: High

**Files Modified**:
- `.claude/tests/test_scope_detection.sh` (remove hybrid mode tests entirely)
- `.claude/tests/test_topic_filename_generation.sh` (new file)
- `.claude/tests/test_scope_detection_ab.sh` (update A/B tests for llm-only vs regex-only)
- `.claude/tests/bench_workflow_classification.sh` (update benchmarks for 2-mode system)

**Tasks**:
- [ ] Remove hybrid mode tests from test_scope_detection.sh entirely (Section 2) - clean-break approach
- [ ] Add test verifying hybrid mode is rejected with appropriate error message
- [ ] Preserve regex-only mode functional tests (ensure mode works as primary classifier)
- [ ] Update llm-only tests to verify fail-fast behavior (no automatic fallback)
- [ ] Create test_topic_filename_generation.sh with enhanced topic structure tests:
  - [ ] Test case: Valid enhanced topics (short_name, detailed_description, filename_slug, research_focus) → all fields extracted
  - [ ] Test case: Valid LLM slugs → use LLM slugs
  - [ ] Test case: Invalid LLM slugs → sanitize short_name
  - [ ] Test case: Missing filename_slug field → sanitize short_name
  - [ ] Test case: Empty/null short_name → generic fallback
  - [ ] Test case: Filesystem constraint violations (path separators, >255 bytes)
  - [ ] Test case: detailed_description validation (50-500 chars)
- [ ] Add fail-fast scenario tests: timeout, API error, low confidence, empty input, hybrid mode rejection
- [ ] Update test_scope_detection_ab.sh to compare llm-only vs regex-only only (remove hybrid)
- [ ] Update bench_workflow_classification.sh to measure LLM-only and regex-only performance (remove hybrid benchmarks)
- [ ] Add test coverage report verification: target >80% coverage for modified code

**Testing**:
```bash
# Run updated test suite
cd .claude/tests
./test_scope_detection.sh
./test_topic_filename_generation.sh
./test_scope_detection_ab.sh

# Verify no hybrid/regex tests remain (except regex-only preservation test)
grep -c "hybrid.*mode" test_scope_detection.sh  # Should be 1 (preservation test comment)

# Verify LLM failure tests added
grep -q "test_llm_timeout_failure" test_scope_detection.sh || echo "FAIL: Missing timeout test"
grep -q "test_llm_low_confidence_failure" test_scope_detection.sh || echo "FAIL: Missing confidence test"

# Run benchmarks
./bench_workflow_classification.sh

# Check coverage
./run_all_tests.sh 2>&1 | grep -A5 "Coverage Report"
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 6 - Update Test Suite for LLM-Only Mode`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 7: Documentation Updates (Clean-Break, 2-Mode System)
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Update documentation for 2-mode system (llm-only + regex-only), remove hybrid mode references entirely

**Complexity**: Medium

**Files Created/Modified**:
- `.claude/docs/concepts/patterns/llm-classification-pattern.md` (simplify to 2-mode system)
- `.claude/docs/guides/enhanced-topic-generation-guide.md` (new comprehensive guide for research_topics structure)
- `.claude/docs/guides/workflow-classification-guide.md` (replaces migration guide, focuses on 2-mode system)
- `CLAUDE.md` (update hierarchical agent architecture section)

**Tasks**:
- [ ] **Remove hybrid mode entirely** from llm-classification-pattern.md (clean-break):
  - [ ] Delete hybrid mode from configuration table
  - [ ] Update default mode to `llm-only` (no hybrid option)
  - [ ] Simplify valid modes: llm-only (default), regex-only (offline only)
  - [ ] Add note: "hybrid mode removed in clean-break update"
- [ ] Add fail-fast behavior documentation (no automatic fallback to regex)
- [ ] Create enhanced-topic-generation-guide.md documenting new research_topics structure:
  - [ ] Overview: enhanced response structure (short_name, detailed_description, filename_slug, research_focus)
  - [ ] LLM prompt instructions for generating detailed topics
  - [ ] Three-tier filename validation (LLM slug → sanitize → generic)
  - [ ] Agent prompt streamlining: how detailed_description and research_focus simplify agent context
  - [ ] Examples: before/after agent prompts
- [ ] Create workflow-classification-guide.md (replaces migration guide):
  - [ ] 2-mode system overview (llm-only, regex-only)
  - [ ] When to use llm-only (default, online development)
  - [ ] When to use regex-only (offline, testing, LLM unavailable)
  - [ ] Error handling: what to do when LLM fails
  - [ ] Configuration examples
  - [ ] **Remove**: Hybrid mode migration, rollback to hybrid, backwards compatibility
- [ ] Update CLAUDE.md hierarchical agent architecture section:
  - [ ] Note LLM-only default (no hybrid)
  - [ ] Document enhanced topic generation (detailed descriptions + filename slugs)
  - [ ] Update configuration examples (remove hybrid references)
- [ ] Add CHANGELOG.md entry for breaking changes:
  - [ ] "BREAKING: Hybrid classification mode removed (clean-break)"
  - [ ] "BREAKING: Automatic regex fallback removed from llm-only mode"
  - [ ] "ENHANCEMENT: LLM generates detailed topic descriptions with filename slugs"
- [ ] Remove all hybrid mode references from existing documentation (fail-fast policy docs, troubleshooting guides)

**Testing**:
```bash
# Verify documentation files exist
test -f .claude/docs/guides/filename-generation-guide.md || echo "FAIL: Missing filename generation guide"
test -f .claude/docs/guides/migration/fallback-removal-migration.md || echo "FAIL: Missing migration guide"

# Verify configuration table updated
grep -q "llm-only.*fail-fast" .claude/docs/concepts/patterns/llm-classification-pattern.md || echo "FAIL: Configuration not updated"

# Verify migration guide has required sections
grep -q "What Changed" .claude/docs/guides/migration/fallback-removal-migration.md || echo "FAIL: Missing 'What Changed' section"
grep -q "Rollback" .claude/docs/guides/migration/fallback-removal-migration.md || echo "FAIL: Missing rollback instructions"

# Verify link validation (relative links work)
.claude/scripts/validate-links-quick.sh .claude/docs/guides/filename-generation-guide.md
.claude/scripts/validate-links-quick.sh .claude/docs/guides/migration/fallback-removal-migration.md
```

**Expected Duration**: 4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `docs(688): complete Phase 7 - Documentation and Migration Guide`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- **LLM prompt validation**: Verify `filename_slugs` field included in prompt instructions
- **Response validation**: Test all validation checks (field existence, count match, regex compliance, length constraints)
- **Hybrid validation**: Test all three validation tiers (LLM slug → sanitize → generic)
- **Error handling**: Test all 6 failure scenarios return correct error messages and exit codes
- **Slug generation logging**: Verify logging captures strategy used for each slug

### Integration Testing
- **End-to-end workflow**: Run `/coordinate` with llm-only mode, verify descriptive filenames created
- **Fallback behavior**: Force invalid LLM slugs, verify sanitization fallback works
- **Discovery removal**: Verify no filesystem discovery occurs, files exist at pre-calculated paths
- **State persistence**: Verify classification results persist across bash blocks correctly

### Regression Testing
- **Existing functionality**: All existing scope detection tests pass (except hybrid/regex removed tests)
- **Backward compatibility**: `regex-only` mode still works for offline development
- **State machine integration**: `sm_init()` correctly exports all three classification dimensions

### Performance Testing
- **LLM latency**: Benchmark LLM classification latency (target: <10s)
- **Slug validation overhead**: Measure validation and sanitization overhead (target: <50ms)
- **LLM slug acceptance rate**: Track percentage of LLM slugs passing validation (target: >90%)

### Failure Scenario Testing
- **LLM timeout**: Simulate timeout, verify fail-fast error with suggestion to increase timeout
- **API error**: Mock API unavailable, verify clear error with suggestion to check network
- **Low confidence**: Force confidence <0.7, verify error with suggestion to rephrase description
- **Empty input**: Test empty workflow description, verify input validation error
- **Invalid mode**: Test invalid `WORKFLOW_CLASSIFICATION_MODE`, verify configuration error

### Test Coverage Target
- **Overall coverage**: >80% for all modified files
- **Critical paths**: 100% coverage for validation logic and error handling
- **Edge cases**: 100% coverage for filesystem constraint checks

## Documentation Requirements

### User-Facing Documentation
- **Workflow classification guide**: 2-mode system overview (llm-only, regex-only), when to use each mode, error handling
- **Enhanced topic generation guide**: Comprehensive guide for research_topics structure, detailed descriptions, filename slugs, agent prompt streamlining
- **Configuration reference**: Document 2-mode system (llm-only default, regex-only offline), environment variables, clean-break changes

### Developer Documentation
- **Architecture diagrams**: Update classification flow diagrams to show fail-fast paths
- **Code comments**: Add inline comments explaining validation tiers and fallback logic
- **Error handling patterns**: Document fail-fast error handling pattern used at all 6 invocation points

### Internal Documentation
- **CHANGELOG.md**: Add breaking changes (hybrid mode removed, automatic fallback removed, enhanced topics)
- **CLAUDE.md**: Update hierarchical agent architecture section (2-mode system, enhanced topics)
- **Link validation**: Run `.claude/scripts/validate-links-quick.sh` on all updated docs
- **Remove**: All hybrid mode references from internal documentation

## Dependencies

### External Dependencies
- Claude Haiku 4.5 API availability (for LLM classification)
- `jq` utility for JSON parsing (already required)
- `sanitize_topic_name()` function from topic-utils.sh (already exists)

### Internal Dependencies
- Phase 2 depends on Phase 1 (LLM response schema must include filename_slugs before validation can use it)
- Phase 3 depends on Phases 1 and 2 (must have working LLM classification before removing fallback)
- Phase 4 depends on Phase 3 (error handling replaces removed fallback code)
- Phase 5 depends on Phase 2 (discovery removal requires working pre-calculation)
- Phase 6 depends on Phases 3 and 4 (tests need LLM-only mode and error handling implemented)
- Phase 7 depends on all previous phases (documentation reflects completed implementation)

### Configuration Dependencies (Clean-Break)
- **BREAKING**: `WORKFLOW_CLASSIFICATION_MODE=hybrid` no longer valid (mode deleted entirely)
- `WORKFLOW_CLASSIFICATION_MODE` default changes from `hybrid` to `llm-only`
- Valid modes reduced to 2: `llm-only` (default), `regex-only` (offline only)
- Configuration validation rejects `hybrid` with error message
- `WORKFLOW_CLASSIFICATION_TIMEOUT` may need adjustment for users with high-latency networks
- Offline development workflows must explicitly set `WORKFLOW_CLASSIFICATION_MODE=regex-only`

## Risk Mitigation

### Operational Risks (Clean-Break Approach)
- **Risk**: LLM API unavailable causes workflow failures (no automatic fallback)
  - **Mitigation**: Preserve `regex-only` mode for offline development, document in error messages ("use regex-only for offline")
- **Risk**: LLM timeout increases user wait time and fails workflow
  - **Mitigation**: Allow timeout configuration via `WORKFLOW_CLASSIFICATION_TIMEOUT`, provide clear error with suggestion, document regex-only alternative
- **Risk**: Low confidence LLM responses cause failures (no fallback to regex)
  - **Mitigation**: Document how to rephrase workflow descriptions, provide examples in error messages, suggest regex-only for problematic descriptions
- **Risk**: Users attempt to use hybrid mode (deleted)
  - **Mitigation**: Configuration validation rejects hybrid with clear error: "hybrid mode removed in clean-break update"

### Implementation Risks
- **Risk**: Validation regex too strict, rejects valid filenames
  - **Mitigation**: Comprehensive test suite with edge cases, monitor LLM slug acceptance rate (target >90%)
- **Risk**: Sanitization fallback produces non-semantic filenames
  - **Mitigation**: Log which strategy used, monitor fallback frequency, tune LLM prompt if acceptance <90%
- **Risk**: Discovery removal breaks existing workflows
  - **Mitigation**: Integration tests verify files exist at pre-calculated paths, staged rollout with monitoring

### Migration Risks (Clean-Break)
- **Risk**: Users unaware hybrid mode deleted
  - **Mitigation**: CHANGELOG.md breaking change entry, configuration validation with clear error, documentation updates
- **Risk**: Scripted workflows using hybrid mode break immediately
  - **Mitigation**: Clear error message explaining clean-break, suggest llm-only (default) or regex-only (offline)
- **Risk**: Workflows that relied on automatic fallback now fail
  - **Mitigation**: Error messages suggest regex-only mode for offline/unreliable network scenarios, document fail-fast philosophy

## Performance Characteristics

### Expected Improvements (Clean-Break Benefits)
- **Code reduction**: Hybrid mode deletion (~20 lines), automatic fallback removal (~25 lines), discovery reconciliation (~30 lines) = ~75 lines total
- **Simplification**: 3 modes → 2 modes (33% reduction in configuration complexity)
- **Filename quality**: Descriptive filenames from start (vs generic placeholders)
- **Agent prompt quality**: Detailed descriptions and research focus streamline agent context
- **Failure clarity**: Clear error messages with actionable suggestions (vs silent fallback)
- **Function clarity**: Renamed function eliminates "fallback" confusion (intentional classifier, not fallback)

### Expected Trade-offs
- **Increased failure rate**: ~5-15% of workflows that previously succeeded via fallback will now fail
- **LLM dependency**: Workflows strictly require LLM API availability (except regex-only mode)
- **Validation overhead**: ~50ms per classification for slug validation and sanitization fallback

### Monitoring Metrics
- **LLM slug acceptance rate**: Percentage of LLM slugs passing validation (target: >90%)
- **Fallback usage rate**: Percentage using sanitization fallback (target: <10%)
- **Generic fallback rate**: Percentage using ultimate generic fallback (target: <1%)
- **Classification failure rate**: Percentage of workflows failing LLM classification (baseline for improvement)

## Rollback Plan (Clean-Break Considerations)

If critical issues arise during implementation:

1. **Immediate rollback**: Revert git commits in reverse order (Phase 7 → Phase 1)
2. **Partial rollback**: Keep Phase 1 (enhanced topic generation) but revert Phase 3 (hybrid mode deletion)
3. **Configuration rollback**: Users set `WORKFLOW_CLASSIFICATION_MODE=regex-only` for offline/problematic workflows (no hybrid to restore)
4. **Code rollback**: Restore hybrid mode from git history if clean-break proves too disruptive
5. **Function rollback**: Restore `fallback_comprehensive_classification()` original name if rename causes issues

**Note**: Clean-break approach means no backwards compatibility preserved. Full rollback requires git revert.

## Notes

This implementation follows **clean-break philosophy**: remove hybrid mode entirely without backwards compatibility, enforcing fail-fast error handling throughout. Errors fail loudly with clear messages suggesting regex-only mode for offline scenarios (no automatic fallback).

**Enhanced LLM Response Structure**: LLM returns detailed research topics (short_name, detailed_description, filename_slug, research_focus) that streamline agent prompt creation by providing comprehensive context and ready-to-use filenames in a single classification call.

**Key architectural principles maintained**:
- Single source of truth (LLM classification for llm-only mode, regex classifier for regex-only mode)
- Progressive disclosure (three-tier filename validation)
- Context window optimization (pre-calculated paths, detailed descriptions reduce agent exploration)
- Fail-fast validation (clear error messages, no silent degradation)
- Intentional configuration (regex-only mode preserved as explicit choice, not fallback)

**Function Renaming Rationale**: `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()` clarifies that regex-only mode is an intentional primary classifier (not a fallback mechanism). This eliminates semantic confusion and accurately represents the 2-mode architecture.

---

## Revision History

### Revision 1 - 2025-11-12
- **Date**: 2025-11-12
- **Type**: clean-break clarification
- **Research Reports Used**:
  - [Implemented Plan Review](../reports/003_implemented_plan_review.md)
  - [Clean-Break Requirements](../reports/004_clean_break_requirements.md)
- **Key Changes**:
  - **Clarified clean-break approach**: Delete hybrid mode entirely (not just change default)
  - **Enhanced LLM response structure**: Changed from simple `filename_slugs` array to rich `research_topics` array with detailed_description, research_focus, filename_slug per topic
  - **Function renaming strategy**: Rename `fallback_comprehensive_classification()` → `classify_workflow_regex_comprehensive()` (preserve function, clarify semantics)
  - **Preserved regex-only mode**: Clarified that regex-only is intentional primary classifier (not fallback mechanism)
  - **Updated all phases**: Reflect clean-break approach (delete hybrid mode case block, remove automatic fallback calls, preserve regex functions)
  - **Simplified documentation**: Focus on 2-mode system (llm-only + regex-only), remove hybrid migration/rollback content
  - **Added research reports**: Incorporated findings from Spec 687 implementation review and clean-break requirements analysis
- **Rationale**: User requested clean-break approach with no backwards compatibility for hybrid mode. Enhanced LLM response structure (detailed topics + filename slugs) streamlines agent prompt creation by providing comprehensive context in single classification call.
- **Backup**: /home/benjamin/.config/.claude/specs/688_687_how_exactly_workflow_identified_coordinate/plans/backups/001_fallback_removal_llm_enhancements_20251112_225736.md
