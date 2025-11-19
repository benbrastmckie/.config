# Semantic Slug Integration for All Specs Directory Commands - Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Fix all commands creating specs directories to use LLM-based semantic topic directory slugs
- **Scope**: Update /plan, /research, and /debug commands to use workflow-classifier invocation and initialize_workflow_paths() for semantic directory naming
- **Estimated Phases**: 7
- **Estimated Hours**: 16
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Complexity Score**: 74.5
- **Structure Level**: 0
- **Research Reports**:
  - [Implementation Gap Analysis](/home/benjamin/.config/.claude/specs/777_research_the_plan_homebenjaminconfigclaudespecs771/reports/001_implementation_gap_analysis.md)
  - [All Commands Specs Directory Analysis](/home/benjamin/.config/.claude/specs/777_research_the_plan_homebenjaminconfigclaudespecs771/reports/002_all_commands_specs_directory_analysis.md)

## Overview

Multiple commands in the .claude system create directories in the specs/ directory using inconsistent naming approaches. The research identified that while `/coordinate` correctly uses the LLM-based semantic slug system implemented in Plan 771, three other commands (`/plan`, `/research`, `/debug`) bypass this system entirely.

This results in malformed directory names like `research_the_homebenjaminconfigclaudespecs771_for_the` instead of semantic slugs like `implementation_gap_analysis`.

The fix requires updating all three commands to follow the same pattern as /coordinate:
1. Invoke workflow-classifier agent to get semantic topic_directory_slug
2. Pass classification result to `initialize_workflow_paths()`
3. Use the three-tier fallback system (LLM slug -> extract_significant_words -> sanitize_topic_name)

## Research Summary

Key findings from the research reports:

1. **Five Commands Create Specs Directories**: /plan, /research, /debug, /coordinate, /revise
   - /coordinate: Already correct (reference implementation)
   - /revise: Derives from existing plan, doesn't need semantic slug generation
   - /plan, /research, /debug: Need updates

2. **Inconsistent Sanitization Methods**:
   - /plan and /research: Use `sanitize_topic_name()` directly
   - /debug: Uses inline sed (worst - only 50 char truncation)
   - /coordinate: Uses `validate_topic_directory_slug()` with LLM (best)

3. **Infrastructure Complete**: Plan 771 implemented all required infrastructure:
   - `topic_directory_slug` field in workflow-classifier
   - `validate_topic_directory_slug()` function
   - `extract_significant_words()` function
   - Integration in `initialize_workflow_paths()`

4. **Common Pattern Available**: All three commands can use identical pattern:
   - Invoke workflow-classifier via Task tool
   - Parse CLASSIFICATION_COMPLETE JSON
   - Call `initialize_workflow_paths()` with classification result

## Success Criteria

- [ ] /plan command produces semantic directory names (e.g., `plan_semantic_slug_fix`)
- [ ] /research command produces semantic directory names (e.g., `api_performance_analysis`)
- [ ] /debug command produces semantic directory names (e.g., `jwt_token_expiration_bug`)
- [ ] All three commands invoke workflow-classifier agent
- [ ] All three commands use initialize_workflow_paths() instead of allocate_and_create_topic()
- [ ] All exported variables (SPECS_DIR, RESEARCH_DIR, PLANS_DIR) remain compatible
- [ ] Existing tests pass for all modified commands
- [ ] New integration tests verify semantic slug generation for each command
- [ ] Fallback behavior works when classifier unavailable

## Technical Design

### Architecture Overview

All three commands will be updated to follow this common flow:

```
User Input (description)
       |
State Machine Initialization (existing)
       |
NEW -> Workflow Classification (Task tool invocation)
       |
Directory Creation Phase
  - Remove: sanitize_topic_name() + allocate_and_create_topic()
  - Add: initialize_workflow_paths($desc, $scope, $complexity, $CLASSIFICATION_JSON)
       |
Remaining phases unchanged
```

### Common Integration Pattern

Each command will implement:

1. **Workflow Classifier Invocation**: Task tool call to workflow-classifier.md agent
2. **Response Parsing**: Parse CLASSIFICATION_COMPLETE JSON to extract topic_directory_slug
3. **Library Sourcing**: Add workflow-initialization.sh to sourced libraries
4. **Variable Mapping**: Map initialize_workflow_paths() exports to expected variables

### Files Modified

Primary fixes:
1. `/home/benjamin/.config/.claude/commands/plan.md` - Lines ~200-256
2. `/home/benjamin/.config/.claude/commands/research.md` - Lines ~222-248
3. `/home/benjamin/.config/.claude/commands/debug.md` - Lines ~167-189

Secondary improvements:
4. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Improve fallback

New tests:
5. `/home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh`

## Implementation Phases

### Phase 1: Update /plan Command for Classification Integration
dependencies: []

**Objective**: Modify /plan command to invoke workflow-classifier and use initialize_workflow_paths()

**Complexity**: Medium

Tasks:
- [ ] Add workflow-initialization.sh to sourced libraries in Part 3 (after line 149)
- [ ] Add Task tool invocation for workflow-classifier agent after Part 3 state machine init
  - Include prompt to invoke workflow-classifier.md with FEATURE_DESCRIPTION and "research-and-plan" scope
  - Set RESEARCH_COMPLEXITY from parsed user input
- [ ] Add bash block to parse CLASSIFICATION_COMPLETE response
  - Extract CLASSIFICATION_JSON containing topic_directory_slug, research_topics, etc.
  - Handle error cases (classifier timeout, invalid response)
- [ ] Replace lines 223-256 in Part 3: Research Phase Execution
  - Remove: `TOPIC_SLUG=$(sanitize_topic_name "$FEATURE_DESCRIPTION")`
  - Remove: `RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")`
  - Add: `initialize_workflow_paths "$FEATURE_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"`
- [ ] Map initialize_workflow_paths exports to expected variables
  - SPECS_DIR from TOPIC_PATH
  - RESEARCH_DIR from TOPIC_PATH/reports
  - PLANS_DIR from TOPIC_PATH/plans
  - TOPIC_SLUG from TOPIC_NAME
- [ ] Update append_workflow_state calls to use new variable sources
- [ ] Verify RESEARCH_COMPLEXITY is properly persisted

Testing:
```bash
# Test /plan command produces semantic slugs
cd /home/benjamin/.config
/plan "Implement semantic directory naming for plan command"
# Verify directory name like 777_semantic_directory_naming or similar semantic slug
ls -la .claude/specs/ | tail -5
```

**Expected Duration**: 3 hours

### Phase 2: Update /research Command for Classification Integration
dependencies: []

**Objective**: Modify /research command to invoke workflow-classifier and use initialize_workflow_paths()

**Complexity**: Medium

Tasks:
- [ ] Add workflow-initialization.sh to sourced libraries in research.md
- [ ] Add Task tool invocation for workflow-classifier agent
  - Include prompt to invoke workflow-classifier.md with WORKFLOW_DESCRIPTION and "research-only" scope
  - Set RESEARCH_COMPLEXITY appropriately
- [ ] Add bash block to parse CLASSIFICATION_COMPLETE response
  - Extract CLASSIFICATION_JSON containing topic_directory_slug
  - Handle error cases (classifier timeout, invalid response)
- [ ] Replace lines 222-248 in directory creation section
  - Remove: `TOPIC_SLUG=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")`
  - Remove: `RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")`
  - Add: `initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" "$CLASSIFICATION_JSON"`
- [ ] Map initialize_workflow_paths exports to expected variables
  - SPECS_DIR from TOPIC_PATH
  - RESEARCH_DIR from TOPIC_PATH/reports
  - TOPIC_SLUG from TOPIC_NAME
- [ ] Update any subsequent code that references these variables

Testing:
```bash
# Test /research command produces semantic slugs
cd /home/benjamin/.config
/research "Analyze API performance bottlenecks in authentication flow"
# Verify directory name like XXX_api_performance_bottlenecks or similar
ls -la .claude/specs/ | tail -5
```

**Expected Duration**: 2.5 hours

### Phase 3: Update /debug Command for Classification Integration
dependencies: []

**Objective**: Modify /debug command to invoke workflow-classifier and use initialize_workflow_paths()

**Complexity**: Medium

Tasks:
- [ ] Add workflow-initialization.sh to sourced libraries in debug.md
- [ ] Add Task tool invocation for workflow-classifier agent
  - Include prompt to invoke workflow-classifier.md with ISSUE_DESCRIPTION and "debug" scope
  - Set appropriate complexity for debug workflows
- [ ] Add bash block to parse CLASSIFICATION_COMPLETE response
  - Extract CLASSIFICATION_JSON containing topic_directory_slug
  - Handle error cases (classifier timeout, invalid response)
- [ ] Replace lines 167-189 in directory creation section
  - Remove: inline sed sanitization `$(echo "$ISSUE_DESCRIPTION" | tr ...)`
  - Remove: `RESULT=$(allocate_and_create_topic "$SPECS_ROOT" "$TOPIC_SLUG")`
  - Add: `initialize_workflow_paths "$ISSUE_DESCRIPTION" "debug" "low" "$CLASSIFICATION_JSON"`
- [ ] Map initialize_workflow_paths exports to expected variables
  - SPECS_DIR from TOPIC_PATH
  - DEBUG_DIR from TOPIC_PATH/debug
  - TOPIC_SLUG from TOPIC_NAME
- [ ] Update any subsequent code that references these variables

Testing:
```bash
# Test /debug command produces semantic slugs
cd /home/benjamin/.config
/debug "Fix JWT token expiration causing 401 errors"
# Verify directory name like XXX_jwt_token_expiration or similar
ls -la .claude/specs/ | tail -5
```

**Expected Duration**: 2.5 hours

### Phase 4: Improve Fallback in unified-location-detection.sh
dependencies: [1, 2, 3]

**Objective**: Enhance allocate_and_create_topic to use extract_significant_words as fallback for better non-LLM naming

**Complexity**: Low

Tasks:
- [ ] Source topic-utils.sh in unified-location-detection.sh if not already sourced
- [ ] Update sanitize_topic_name() function (lines 356-368) to use extract_significant_words as intermediate step:
  - First try extract_significant_words() for semantic extraction
  - If that fails or produces empty result, fall back to basic sanitization
- [ ] Update allocate_and_create_topic() to optionally accept pre-validated slug
  - Add optional third parameter for pre-validated slug
  - Skip sanitize_topic_name() if pre-validated slug provided
- [ ] Add documentation comment explaining the improvement
- [ ] Test that basic allocate_and_create_topic still works without pre-validated slug

Testing:
```bash
# Source and test improved sanitize_topic_name
source /home/benjamin/.config/.claude/lib/unified-location-detection.sh
sanitize_topic_name "Research the /home/benjamin/.config/.claude/specs/771_for_the_research option"
# Should produce something like "research_option" instead of truncated path
```

**Expected Duration**: 1.5 hours

### Phase 5: Add Integration Tests for All Commands
dependencies: [1, 2, 3]

**Objective**: Create comprehensive integration tests to verify semantic slug generation for all updated commands

**Complexity**: Medium

Tasks:
- [ ] Create test file: /home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh
- [ ] Test Suite 1: /plan command semantic slugs
  - Test basic semantic slug generation
  - Test long descriptions with path references
  - Test descriptions with special characters
  - Verify all exported variables set correctly
- [ ] Test Suite 2: /research command semantic slugs
  - Test basic semantic slug generation
  - Test complex research descriptions
  - Verify RESEARCH_DIR correctly set
- [ ] Test Suite 3: /debug command semantic slugs
  - Test basic semantic slug generation
  - Test issue descriptions with error codes
  - Verify DEBUG_DIR correctly set
- [ ] Test Suite 4: Cross-command consistency
  - Verify all commands produce consistent slug quality
  - Verify fallback behavior when classifier unavailable
- [ ] Add test runner integration (follow existing test patterns)
- [ ] Document test cases in test file header

Testing:
```bash
# Run new integration tests
bash /home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh
# All tests should pass
```

**Expected Duration**: 3 hours

### Phase 6: Update Existing Tests and Fix Regressions
dependencies: [4, 5]

**Objective**: Run existing test suite and fix any regressions

**Complexity**: Low

Tasks:
- [ ] Run existing topic naming tests to ensure no regressions
  - test_topic_naming.sh
  - test_topic_slug_validation.sh
  - test_atomic_topic_allocation.sh
- [ ] Fix any test failures caused by changes in Phase 4
- [ ] Verify /coordinate command still works correctly (should be unchanged)
- [ ] Test that commands work correctly when classifier times out (fallback)
- [ ] Verify error messages are clear and helpful

Testing:
```bash
# Run all related tests
bash /home/benjamin/.config/.claude/tests/test_topic_naming.sh
bash /home/benjamin/.config/.claude/tests/test_topic_slug_validation.sh
bash /home/benjamin/.config/.claude/tests/test_atomic_topic_allocation.sh
bash /home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh
```

**Expected Duration**: 1.5 hours

### Phase 7: Documentation and Final Verification
dependencies: [6]

**Objective**: Update documentation and perform final end-to-end verification

**Complexity**: Low

Tasks:
- [ ] Update comments in plan.md explaining classification integration
- [ ] Update comments in research.md explaining classification integration
- [ ] Update comments in debug.md explaining classification integration
- [ ] Document the common integration pattern for future command authors
- [ ] Test end-to-end workflows:
  - /plan -> research -> plan creation
  - /research -> research report creation
  - /debug -> debug session creation
- [ ] Verify downstream commands (/implement) can read plans from new directories
- [ ] Perform manual tests with real-world descriptions to verify improvement
- [ ] Update any stale comments referencing the old allocation method

Testing:
```bash
# Manual end-to-end verification
# 1. Run /plan with a descriptive feature
# 2. Verify semantic directory name created
# 3. Verify research phase completes
# 4. Verify plan file created in correct location

# 1. Run /research with a research topic
# 2. Verify semantic directory name created
# 3. Verify research report created

# 1. Run /debug with an issue description
# 2. Verify semantic directory name created
# 3. Verify debug artifacts created
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Test improved sanitize_topic_name function with various inputs
- Test allocate_and_create_topic with pre-validated slug parameter
- Verify validate_topic_directory_slug three-tier fallback

### Integration Testing
- Test /plan command produces semantic directory names
- Test /research command produces semantic directory names
- Test /debug command produces semantic directory names
- Test classification flow with mock LLM responses
- Test fallback behavior when classifier unavailable

### Regression Testing
- Run existing test suite for topic naming
- Verify /coordinate command still works correctly
- Verify all workflow types still function

### End-to-End Testing
- Full /plan workflow execution
- Full /research workflow execution
- Full /debug workflow execution
- Verify artifacts created in correct locations
- Verify downstream commands can read artifacts

## Documentation Requirements

- Update comments in plan.md, research.md, and debug.md explaining classification integration
- Document the common integration pattern for future command authors
- Update any references to the old allocation method
- No new documentation files needed (just inline updates)

## Dependencies

### Required Libraries
- workflow-initialization.sh (already exists, needs to be sourced)
- topic-utils.sh (already sourced by workflow-initialization.sh)
- workflow-state-machine.sh (already sourced)
- state-persistence.sh (already sourced)
- unified-location-detection.sh (already sourced, will be improved)

### Agent Dependencies
- workflow-classifier.md (existing agent, will be invoked via Task)

### External Dependencies
- None (all infrastructure exists from Plan 771)

## Risk Analysis

### Risks and Mitigations

1. **Risk**: Classification adds latency to all three commands
   - **Mitigation**: Classification is fast (Haiku model), typically <2 seconds
   - **Mitigation**: Parallel execution of Phases 1, 2, 3 minimizes overall time

2. **Risk**: Classifier unavailable or errors
   - **Mitigation**: validate_topic_directory_slug has three-tier fallback
   - **Mitigation**: Error handling with clear diagnostic messages
   - **Mitigation**: Phase 4 improves fallback quality

3. **Risk**: Breaking existing workflows
   - **Mitigation**: All exported variables mapped to same names
   - **Mitigation**: Comprehensive test coverage before deployment
   - **Mitigation**: Phases 5 and 6 ensure thorough testing

4. **Risk**: Inconsistent implementation across commands
   - **Mitigation**: Same pattern applied to all three commands
   - **Mitigation**: Cross-command consistency tests in Phase 5

5. **Risk**: Incompatibility with downstream agents
   - **Mitigation**: Variables SPECS_DIR, RESEARCH_DIR, PLANS_DIR unchanged
   - **Mitigation**: End-to-end testing in Phase 7

## Parallel Execution Opportunities

This plan enables significant parallel execution:

- **Wave 1**: Phases 1, 2, 3 (all command updates can run in parallel)
- **Wave 2**: Phases 4, 5 (fallback improvement and integration tests)
- **Wave 3**: Phase 6 (regression testing)
- **Wave 4**: Phase 7 (documentation and verification)

Estimated time savings: 40-50% compared to sequential execution

## Notes

- This plan addresses the incomplete Phase 4 from Plan 771 and expands scope to all affected commands
- Primary fixes are in plan.md, research.md, and debug.md
- Secondary improvement in unified-location-detection.sh benefits all commands
- Total estimated time: 16 hours (8 hours with parallel execution)
- Phase dependencies enable parallel execution of independent phases
