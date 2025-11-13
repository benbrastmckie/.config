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
  - [Workflow Identification Architecture](../../687_how_exactly_workflow_identified_coordinate/reports/001_workflow_identification.md)
  - [Research Topic Handling](../../687_how_exactly_workflow_identified_coordinate/reports/002_research_topic_handling.md)

## Overview

This plan implements two major architectural changes to the workflow classification system:

1. **Objective 1: Remove Regex Fallback** - Eliminate all regex fallback code and implement fail-fast error handling for LLM classification failures, enforcing LLM-only mode with clear user feedback
2. **Objective 2: LLM Filename Generation** - Enhance LLM classifier to return both semantic topic names AND filesystem-safe filename slugs, with validation fallback to ensure zero operational risk

The hybrid approach (Strategy 3 from report 002) provides LLM-generated filenames with sanitization fallback, ensuring high-quality descriptive filenames while maintaining filesystem safety.

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

**Design Decisions**:
- Use hybrid filename generation (LLM suggestions with validation fallback) for zero operational risk
- Enforce LLM-only mode by changing default `WORKFLOW_CLASSIFICATION_MODE` from `hybrid` to `llm-only`
- Preserve `regex-only` mode for offline development (don't remove regex classifier entirely)
- Implement comprehensive error handling with actionable user messages at all 6 failure points
- Add structured logging for slug generation strategy tracking and LLM performance monitoring

## Success Criteria

- [ ] All regex fallback code removed from hybrid/llm-only modes (6 invocation points)
- [ ] LLM classifier returns `filename_slugs` field matching `subtopics` array length
- [ ] Validation logic ensures filesystem-safe filenames in all scenarios (regex `^[a-z0-9_]{1,50}$`)
- [ ] Fail-fast error handling implemented at all 6 classification failure points
- [ ] Discovery reconciliation code removed from /coordinate (lines 685-714)
- [ ] Error messages provide clear context and actionable suggestions
- [ ] LLM slug acceptance rate >90% measured via structured logging
- [ ] Zero file creation failures due to invalid filenames
- [ ] Test suite updated: remove hybrid/regex tests, add LLM-only failure scenarios
- [ ] Documentation updated: migration guide, error handling patterns, configuration changes
- [ ] Backward compatibility: `regex-only` mode preserved for offline development
- [ ] 100% of existing classification tests pass with new implementation

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

New schema:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": ["Implementation architecture", "Integration patterns"],
  "filename_slugs": ["implementation_architecture", "integration_patterns"],
  "reasoning": "..."
}
```

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

**Objective**: Enhance LLM classifier to generate and validate filename slugs

**Complexity**: Medium

**Files Modified**:
- `.claude/lib/workflow-llm-classifier.sh` (lines 148-208, 267-379)

**Tasks**:
- [ ] Update `build_llm_classifier_input()` to add `filename_slugs` field to instructions (file: .claude/lib/workflow-llm-classifier.sh, lines 181-182)
- [ ] Add prompt guidance: "filename_slugs (array of filesystem-safe slug versions matching subtopics count, using lowercase alphanumeric and underscores only, max 50 chars each, e.g., 'implementation_architecture')"
- [ ] Update `parse_llm_classifier_response()` to validate new field (file: .claude/lib/workflow-llm-classifier.sh, lines 290-332)
- [ ] Add validation: filename_slugs field exists and is non-empty
- [ ] Add validation: filename_slugs count matches research_complexity
- [ ] Add validation: each slug matches regex `^[a-z0-9_]+$`
- [ ] Add validation: each slug length <=50 characters
- [ ] Return descriptive error for validation failures (include which slug failed and why)

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
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(688): complete Phase 1 - LLM Prompt and Response Enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

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

### Phase 3: Remove Regex Fallback Functions and Enforce LLM-Only Mode
dependencies: [1, 2]

**Objective**: Remove regex fallback code and change default classification mode to llm-only

**Complexity**: Medium

**Files Modified**:
- `.claude/lib/workflow-scope-detection.sh` (lines 54-57, 74-77, 82-85, 114-141, 212-268, 149-188, 195-205, 289-292)

**Tasks**:
- [ ] Change `WORKFLOW_CLASSIFICATION_MODE` default from `hybrid` to `llm-only` (line 32)
- [ ] Remove fallback call at empty description validation (lines 54-57) - replace with fail-fast error
- [ ] Remove fallback call in llm-only mode failure (lines 82-85) - already returns error, verify no fallback
- [ ] Delete `fallback_comprehensive_classification()` function (lines 114-141)
- [ ] Delete `classify_workflow_regex()` function (lines 212-268) - EXCEPT preserve for regex-only mode
- [ ] Delete `infer_complexity_from_keywords()` function (lines 149-188)
- [ ] Delete `generate_generic_topics()` function (lines 195-205)
- [ ] Remove function exports for deleted functions (lines 289-292)
- [ ] Update `classify_workflow_comprehensive()` hybrid mode case to fail-fast instead of fallback (lines 74-77)
- [ ] Preserve `regex-only` mode case (lines 93-97) for offline development
- [ ] Add clear error messages with context and suggestions at all removal points

**Testing**:
```bash
# Test llm-only mode is now default
source .claude/lib/workflow-scope-detection.sh
[ "$WORKFLOW_CLASSIFICATION_MODE" = "llm-only" ] || echo "FAIL: Default mode not llm-only"

# Test deleted functions are gone
declare -f fallback_comprehensive_classification >/dev/null 2>&1 && echo "FAIL: fallback_comprehensive_classification still exists"
declare -f infer_complexity_from_keywords >/dev/null 2>&1 && echo "FAIL: infer_complexity_from_keywords still exists"
declare -f generate_generic_topics >/dev/null 2>&1 && echo "FAIL: generate_generic_topics still exists"

# Test regex-only mode still works (preserved for offline development)
export WORKFLOW_CLASSIFICATION_MODE="regex-only"
classify_workflow_comprehensive "research authentication patterns" >/dev/null || echo "FAIL: regex-only mode broken"

# Test llm-only mode fails fast on LLM error (mock LLM failure)
export WORKFLOW_CLASSIFICATION_MODE="llm-only"
export WORKFLOW_CLASSIFICATION_TIMEOUT=0.001  # Force timeout
classify_workflow_comprehensive "research authentication patterns" 2>&1 | grep -q "ERROR" || echo "FAIL: No fail-fast error on LLM timeout"
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

### Phase 4: Fail-Fast Error Handling at All Invocation Points
dependencies: [3]

**Objective**: Implement comprehensive error handling at all 6 classification failure points

**Complexity**: Medium

**Files Modified**:
- `.claude/lib/error-handling.sh` (add new error types and handler function)
- `.claude/lib/workflow-state-machine.sh` (lines 367-376)
- `.claude/lib/workflow-scope-detection.sh` (update error handling at failure points)

**Tasks**:
- [ ] Add LLM error types to error-handling.sh: `ERROR_TYPE_LLM_TIMEOUT`, `ERROR_TYPE_LLM_API_ERROR`, `ERROR_TYPE_LLM_LOW_CONFIDENCE`, `ERROR_TYPE_LLM_PARSE_ERROR`
- [ ] Implement `handle_llm_classification_failure()` function in workflow-llm-classifier.sh
- [ ] Add error context: error type, error message, workflow description
- [ ] Add actionable suggestions for each error type (simplify description, check network, increase timeout)
- [ ] Update state machine initialization (workflow-state-machine.sh:367-376): remove fallback, add fail-fast with critical error
- [ ] Update empty description validation (workflow-scope-detection.sh:54-57): fail-fast with input validation error
- [ ] Update invalid mode handling (workflow-scope-detection.sh:100-104): fail-fast with configuration error
- [ ] Ensure all error messages follow pattern: "ERROR: [what] | Context: [workflow] | Suggestion: [action]"
- [ ] Test all 6 failure scenarios return non-zero exit codes
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

### Phase 6: Update Test Suite for LLM-Only Mode
dependencies: [3, 4]

**Objective**: Remove hybrid/regex tests, add LLM failure scenario tests, update benchmarks

**Complexity**: High

**Files Modified**:
- `.claude/tests/test_scope_detection.sh` (remove Section 1: regex-only, Section 2: hybrid)
- `.claude/tests/test_topic_filename_generation.sh` (new file)
- `.claude/tests/test_scope_detection_ab.sh` (update A/B tests)
- `.claude/tests/bench_workflow_classification.sh` (update benchmarks)

**Tasks**:
- [ ] Remove hybrid mode tests from test_scope_detection.sh (Section 2)
- [ ] Remove regex-only mode tests from test_scope_detection.sh (Section 1) - except test that regex-only mode still works
- [ ] Keep llm-only tests, update expected failure behavior (fail-fast instead of fallback)
- [ ] Create test_topic_filename_generation.sh with new test cases
- [ ] Test case: Valid LLM slugs → use LLM slugs
- [ ] Test case: Invalid LLM slugs → sanitize subtopics
- [ ] Test case: Missing filename_slugs field → sanitize subtopics
- [ ] Test case: Empty/null subtopics → generic fallback
- [ ] Test case: Filesystem constraint violations (path separators, >255 bytes)
- [ ] Add LLM failure scenario tests: timeout, API error, low confidence, empty input, invalid mode
- [ ] Update test_scope_detection_ab.sh to compare llm-only vs regex-only (remove hybrid comparisons)
- [ ] Update bench_workflow_classification.sh to measure LLM-only performance and slug generation overhead
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

### Phase 7: Documentation and Migration Guide
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Update documentation to reflect architectural changes and provide migration guidance

**Complexity**: Medium

**Files Created/Modified**:
- `.claude/docs/concepts/patterns/llm-classification-pattern.md` (update configuration)
- `.claude/docs/guides/filename-generation-guide.md` (new comprehensive guide)
- `.claude/docs/guides/migration/fallback-removal-migration.md` (new migration guide)
- `CLAUDE.md` (update hierarchical agent architecture section if needed)

**Tasks**:
- [ ] Update llm-classification-pattern.md configuration table: change default mode to `llm-only`, remove hybrid mode references
- [ ] Add note about fail-fast behavior in llm-only mode (timeouts, API errors cause workflow failure)
- [ ] Create filename-generation-guide.md with sections: overview, LLM slug generation rules, sanitization fallback algorithm, validation constraints, examples, troubleshooting
- [ ] Create fallback-removal-migration.md with sections: what changed, impact, detection, resolution, rollback
- [ ] Document breaking change: workflows may fail where they previously succeeded with fallback
- [ ] Document rollback procedure: set `WORKFLOW_CLASSIFICATION_MODE=regex-only` for old behavior
- [ ] Add configuration examples: when to use llm-only vs regex-only modes
- [ ] Update CLAUDE.md hierarchical agent architecture section: note LLM-only default, filename generation enhancement
- [ ] Add CHANGELOG.md entry for breaking changes
- [ ] Document new environment variables and their defaults

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
- **Migration guide**: Explain breaking changes, impact, detection, resolution, rollback
- **Filename generation guide**: Comprehensive guide for LLM slug generation, validation, sanitization fallback
- **Configuration reference**: Document new default mode (llm-only), when to override, environment variables

### Developer Documentation
- **Architecture diagrams**: Update classification flow diagrams to show fail-fast paths
- **Code comments**: Add inline comments explaining validation tiers and fallback logic
- **Error handling patterns**: Document fail-fast error handling pattern used at all 6 invocation points

### Internal Documentation
- **CHANGELOG.md**: Add breaking change entry for fallback removal
- **CLAUDE.md**: Update hierarchical agent architecture section with new defaults
- **Link validation**: Run `.claude/scripts/validate-links-quick.sh` on all updated docs

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

### Configuration Dependencies
- `WORKFLOW_CLASSIFICATION_MODE` default changes from `hybrid` to `llm-only`
- `WORKFLOW_CLASSIFICATION_TIMEOUT` may need adjustment for users with high-latency networks
- Offline development workflows must explicitly set `WORKFLOW_CLASSIFICATION_MODE=regex-only`

## Risk Mitigation

### Operational Risks
- **Risk**: LLM API unavailable causes workflow failures
  - **Mitigation**: Preserve `regex-only` mode for offline development, document fallback procedure in migration guide
- **Risk**: LLM timeout increases user wait time
  - **Mitigation**: Allow timeout configuration via `WORKFLOW_CLASSIFICATION_TIMEOUT`, provide clear error with suggestion
- **Risk**: Low confidence LLM responses cause failures
  - **Mitigation**: Document how to rephrase workflow descriptions, provide examples of clear descriptions

### Implementation Risks
- **Risk**: Validation regex too strict, rejects valid filenames
  - **Mitigation**: Comprehensive test suite with edge cases, monitor LLM slug acceptance rate (target >90%)
- **Risk**: Sanitization fallback produces non-semantic filenames
  - **Mitigation**: Log which strategy used, monitor fallback frequency, tune LLM prompt if acceptance <90%
- **Risk**: Discovery removal breaks existing workflows
  - **Mitigation**: Integration tests verify files exist at pre-calculated paths, staged rollout with monitoring

### Migration Risks
- **Risk**: Users unaware of breaking changes
  - **Mitigation**: Comprehensive migration guide, CHANGELOG.md entry, clear error messages with suggestions
- **Risk**: Scripted workflows break due to fail-fast behavior
  - **Mitigation**: Document rollback procedure (set regex-only mode), provide clear error context in messages

## Performance Characteristics

### Expected Improvements
- **Code reduction**: ~180 lines removed (fallback functions)
- **Complexity reduction**: Eliminate discovery reconciliation (~30 lines)
- **Filename quality**: Descriptive filenames from start (vs generic placeholders)
- **Failure clarity**: Clear error messages with actionable suggestions (vs silent fallback)

### Expected Trade-offs
- **Increased failure rate**: ~5-15% of workflows that previously succeeded via fallback will now fail
- **LLM dependency**: Workflows strictly require LLM API availability (except regex-only mode)
- **Validation overhead**: ~50ms per classification for slug validation and sanitization fallback

### Monitoring Metrics
- **LLM slug acceptance rate**: Percentage of LLM slugs passing validation (target: >90%)
- **Fallback usage rate**: Percentage using sanitization fallback (target: <10%)
- **Generic fallback rate**: Percentage using ultimate generic fallback (target: <1%)
- **Classification failure rate**: Percentage of workflows failing LLM classification (baseline for improvement)

## Rollback Plan

If critical issues arise during implementation:

1. **Immediate rollback**: Revert git commits in reverse order (Phase 7 → Phase 1)
2. **Partial rollback**: Keep Phase 1 (LLM filename generation) but revert Phase 3 (fallback removal)
3. **Configuration rollback**: Users set `WORKFLOW_CLASSIFICATION_MODE=hybrid` (restore old behavior)
4. **Code rollback**: Restore deleted functions from git history if needed

## Notes

This implementation follows fail-fast philosophy from CLAUDE.md: errors should fail loudly with clear messages, not silently degrade through fallbacks. The hybrid filename generation approach (Strategy 3) ensures zero operational risk while maximizing filename quality through LLM expertise.

Key architectural principles maintained:
- Single source of truth (LLM classification)
- Progressive disclosure (validation tiers)
- Context window optimization (pre-calculated paths)
- Fail-fast validation (clear error messages)
- Backward compatibility (preserve regex-only mode)
