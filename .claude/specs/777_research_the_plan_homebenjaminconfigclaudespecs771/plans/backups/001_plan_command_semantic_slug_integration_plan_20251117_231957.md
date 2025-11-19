# /plan Command Semantic Slug Integration Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Fix /plan command to use LLM-based semantic topic directory slugs
- **Scope**: Update /plan command to use workflow-classifier invocation and initialize_workflow_paths() for semantic directory naming
- **Estimated Phases**: 4
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Complexity Score**: 29.5
- **Structure Level**: 0
- **Research Reports**:
  - [Implementation Gap Analysis](/home/benjamin/.config/.claude/specs/777_research_the_plan_homebenjaminconfigclaudespecs771/reports/001_implementation_gap_analysis.md)

## Overview

The /plan command currently bypasses the LLM-based semantic topic directory slug system implemented in Plan 771. It uses `sanitize_topic_name()` directly with `allocate_and_create_topic()` instead of the proper classification flow that uses `initialize_workflow_paths()` with the workflow-classifier's `topic_directory_slug`.

This results in malformed directory names like `research_the_homebenjaminconfigclaudespecs771_for_the` instead of semantic slugs like `plan_semantic_slug_fix`.

The fix requires updating the /plan command to follow the same pattern as /coordinate: invoke workflow-classifier to get classification results (including the semantic topic_directory_slug), then pass that to `initialize_workflow_paths()`.

## Research Summary

Key findings from the gap analysis report:

1. **Root Cause Identified**: The /plan command at lines 223-229 directly calls `sanitize_topic_name()` and `allocate_and_create_topic()` instead of using the LLM classification flow
2. **Working Pattern Available**: The /coordinate command correctly uses `initialize_workflow_paths()` with `classification_result` (line 483)
3. **Infrastructure Complete**: Plan 771 implemented all required infrastructure - `topic_directory_slug` field, `validate_topic_directory_slug()` function, and integration in `initialize_workflow_paths()`
4. **Duplicate Functions**: Two different `sanitize_topic_name()` implementations exist (simple in unified-location-detection.sh, sophisticated in topic-utils.sh)
5. **Three-Tier Fallback**: The `validate_topic_directory_slug()` function provides robust fallback: LLM slug → extract_significant_words → sanitize_topic_name

## Success Criteria

- [ ] /plan command produces semantic directory names (e.g., `plan_semantic_slug_fix`) instead of truncated names
- [ ] /plan command invokes workflow-classifier agent to get topic_directory_slug
- [ ] /plan command uses initialize_workflow_paths() instead of allocate_and_create_topic()
- [ ] All exported variables (SPECS_DIR, RESEARCH_DIR, PLANS_DIR) remain compatible with subsequent bash blocks
- [ ] Existing /plan command tests pass
- [ ] New integration test verifies semantic slug generation
- [ ] Duplicate sanitize_topic_name in unified-location-detection.sh uses extract_significant_words as fallback

## Technical Design

### Architecture Overview

The /plan command will be updated to follow this flow:

```
User Input (feature description)
       ↓
Part 2: Parse and validate feature description (existing)
       ↓
Part 3: State Machine Initialization (existing)
       ↓
NEW → Workflow Classification (Task tool invocation)
       ↓
Part 3: Research Phase Execution
  - Replace: sanitize_topic_name() + allocate_and_create_topic()
  - With: initialize_workflow_paths($desc, "research-and-plan", $complexity, $CLASSIFICATION_JSON)
       ↓
Remaining phases unchanged (Task invocations for research and planning)
```

### Key Integration Points

1. **Workflow Classifier Invocation**: Add a Task tool call to invoke workflow-classifier.md agent, similar to coordinate.md
2. **Response Parsing**: Parse CLASSIFICATION_COMPLETE JSON response to extract topic_directory_slug and other fields
3. **Library Sourcing**: Add workflow-initialization.sh to sourced libraries
4. **Variable Mapping**: Map initialize_workflow_paths() exports to expected variables (SPECS_DIR, RESEARCH_DIR, PLANS_DIR)

### Files Modified

1. `/home/benjamin/.config/.claude/commands/plan.md` - Primary fix
2. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Secondary improvement
3. `/home/benjamin/.config/.claude/tests/test_plan_semantic_slug.sh` - New integration test

## Implementation Phases

### Phase 1: Update /plan Command for Classification Integration
dependencies: []

**Objective**: Modify /plan command to invoke workflow-classifier and use initialize_workflow_paths()

**Complexity**: Medium

Tasks:
- [ ] Add workflow-initialization.sh to sourced libraries in Part 3 (after line 149)
- [ ] Add Task tool invocation for workflow-classifier agent after Part 3 state machine init (new section between Part 3 sections)
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

### Phase 2: Improve Fallback in unified-location-detection.sh
dependencies: [1]

**Objective**: Enhance allocate_and_create_topic to use extract_significant_words as fallback for better non-LLM naming

**Complexity**: Low

Tasks:
- [ ] Source topic-utils.sh in unified-location-detection.sh if not already sourced (add to SECTION 1 or top of file)
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
# Should produce something like "research_option" or "specs_research_option" instead of truncated path
```

**Expected Duration**: 1.5 hours

### Phase 3: Add Integration Tests
dependencies: [1, 2]

**Objective**: Create integration tests to verify semantic slug generation for /plan command

**Complexity**: Low

Tasks:
- [ ] Create test file: /home/benjamin/.config/.claude/tests/test_plan_semantic_slug.sh
- [ ] Test Case 1: Basic semantic slug generation
  - Input: "Implement user authentication"
  - Expected: Directory name contains "user_authentication" or similar semantic slug
  - Verify not truncated gibberish
- [ ] Test Case 2: Long description with path references
  - Input: "Research the /home/benjamin/.config/.claude/specs/771 implementation gaps"
  - Expected: Directory name like "implementation_gaps" not "research_the_homebenjamin"
- [ ] Test Case 3: Description with special characters
  - Input: "Fix bug #123: JWT token expiration"
  - Expected: Directory name like "jwt_token_expiration_bug"
- [ ] Test Case 4: Verify all exported variables set correctly
  - SPECS_DIR, RESEARCH_DIR, PLANS_DIR, TOPIC_SLUG should all be non-empty
- [ ] Add test runner integration (follow existing test patterns)
- [ ] Document test cases in test file header

Testing:
```bash
# Run new integration tests
bash /home/benjamin/.config/.claude/tests/test_plan_semantic_slug.sh
# All tests should pass
```

**Expected Duration**: 2 hours

### Phase 4: Documentation and Verification
dependencies: [1, 2, 3]

**Objective**: Update documentation and perform final verification

**Complexity**: Low

Tasks:
- [ ] Run existing topic naming tests to ensure no regressions
  - test_topic_naming.sh
  - test_topic_slug_validation.sh
  - test_atomic_topic_allocation.sh
- [ ] Verify /plan command help text is still accurate
- [ ] Test end-to-end workflow: /plan → research → plan creation
- [ ] Verify research-specialist and plan-architect agents work correctly with new path structure
- [ ] Update any stale comments in plan.md that reference the old allocation method
- [ ] Document the change in plan.md file header (update the comment about semantic slug generation)
- [ ] Perform manual test with real-world description to verify improvement

Testing:
```bash
# Run all related tests
bash /home/benjamin/.config/.claude/tests/test_topic_naming.sh
bash /home/benjamin/.config/.claude/tests/test_topic_slug_validation.sh
bash /home/benjamin/.config/.claude/tests/test_atomic_topic_allocation.sh
bash /home/benjamin/.config/.claude/tests/test_plan_semantic_slug.sh

# Manual end-to-end verification
# 1. Run /plan with a descriptive feature
# 2. Verify semantic directory name created
# 3. Verify research phase completes
# 4. Verify plan file created in correct location
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Testing
- Test improved sanitize_topic_name function with various inputs
- Test allocate_and_create_topic with pre-validated slug parameter
- Verify validate_topic_directory_slug three-tier fallback

### Integration Testing
- Test /plan command produces semantic directory names
- Test classification flow with mock LLM responses
- Test fallback behavior when classifier unavailable

### Regression Testing
- Run existing test suite for topic naming
- Verify /coordinate command still works correctly
- Verify all workflow types still function

### End-to-End Testing
- Full /plan workflow execution
- Verify artifacts created in correct locations
- Verify downstream commands (/implement) can read plans

## Documentation Requirements

- Update comments in plan.md explaining classification integration
- Document the integration pattern for future command authors
- Update any references to the old allocation method
- No new documentation files needed (just inline updates)

## Dependencies

### Required Libraries
- workflow-initialization.sh (already exists, needs to be sourced)
- topic-utils.sh (already sourced by workflow-initialization.sh)
- workflow-state-machine.sh (already sourced)
- state-persistence.sh (already sourced)

### Agent Dependencies
- workflow-classifier.md (existing agent, will be invoked via Task)

### External Dependencies
- None (all infrastructure exists from Plan 771)

## Risk Analysis

### Risks and Mitigations

1. **Risk**: Classification adds latency to /plan command
   - **Mitigation**: Classification is fast (Haiku model), typically <2 seconds
   - **Mitigation**: Parallel execution with state machine init if possible

2. **Risk**: Classifier unavailable or errors
   - **Mitigation**: validate_topic_directory_slug has three-tier fallback
   - **Mitigation**: Error handling with clear diagnostic messages

3. **Risk**: Breaking existing /plan workflows
   - **Mitigation**: All exported variables mapped to same names
   - **Mitigation**: Comprehensive test coverage before deployment

4. **Risk**: Incompatibility with downstream agents
   - **Mitigation**: Variables SPECS_DIR, RESEARCH_DIR, PLANS_DIR unchanged
   - **Mitigation**: Test research-specialist and plan-architect integration

## Notes

- This plan addresses the incomplete Phase 4 from Plan 771
- The primary fix is in plan.md; secondary improvements are optional optimizations
- Phase dependencies enable parallel execution of independent phases
- Total estimated time: 8 hours
