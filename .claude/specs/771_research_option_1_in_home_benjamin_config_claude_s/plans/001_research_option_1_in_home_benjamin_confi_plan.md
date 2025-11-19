# Semantic Topic Directory Slug Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: LLM-based semantic topic directory slug generation using Haiku
- **Scope**: Extend workflow-classifier agent to generate topic_directory_slug and integrate with all commands that create named directories
- **Structure Level**: 0
- **Complexity Score**: 47.5
- **Estimated Phases**: 6
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Existing Infrastructure Analysis](/home/benjamin/.config/.claude/specs/771_research_option_1_in_home_benjamin_config_claude_s/reports/001_existing_infrastructure_analysis.md)
  - [Standards Compliance Research](/home/benjamin/.config/.claude/specs/771_research_option_1_in_home_benjamin_config_claude_s/reports/002_standards_compliance_research.md)
  - [Haiku Integration Design](/home/benjamin/.config/.claude/specs/771_research_option_1_in_home_benjamin_config_claude_s/reports/003_haiku_integration_design.md)

## Overview

This plan implements an elegant LLM-based solution using Haiku for fast, cost-effective semantic topic directory slug generation. The solution extends the existing workflow-classifier agent to produce a `topic_directory_slug` field alongside `filename_slug` fields, then integrates this capability uniformly across all commands that create named directories.

**Core Goals**:
1. Replace truncation-based directory naming with semantic, readable slugs
2. Leverage existing Haiku infrastructure for <5 second classification
3. Implement three-tier fallback for graceful degradation
4. Ensure backward compatibility with existing workflows
5. Conform to all standards in .claude/docs/

## Research Summary

### Key Findings from Research

**Existing Infrastructure** (Report 1):
- Workflow-classifier agent already generates semantic `filename_slug` using Haiku
- Three-tier validation system exists in `validate_and_generate_filename_slugs()`
- `sanitize_topic_name()` currently truncates at 50 characters without semantic awareness
- Classification result JSON is already passed to `initialize_workflow_paths()` as fourth argument

**Standards Compliance** (Report 2):
- Haiku model is correct tier for deterministic classification tasks
- Must follow behavioral injection pattern for agent invocations
- Error handling requires WHICH/WHAT/WHERE structured messages
- Logging via `log_slug_generation()` pattern already established

**Haiku Integration Design** (Report 3):
- Add `topic_directory_slug` field to JSON output schema
- Format: `^[a-z0-9_]{1,40}$` (40 chars for directory readability)
- Cost: ~$0.0024 per workflow (minimal)
- Three-tier fallback: LLM -> extract_significant_words -> sanitize

**Recommended Approach**: Extend workflow-classifier agent with minimal changes, reuse existing validation patterns, ensure backward compatibility for commands not using classification.

## Success Criteria

- [ ] Workflow-classifier agent generates semantic `topic_directory_slug` field
- [ ] All topic directories use semantic slugs when classification result available
- [ ] Three-tier fallback handles LLM unavailability gracefully
- [ ] Existing commands (coordinate, research) automatically benefit
- [ ] Commands without classification (plan) continue working unchanged
- [ ] No breaking changes to existing workflows or directory structures
- [ ] All tests pass including new unit tests for slug validation
- [ ] Documentation updated with new field descriptions

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ Command Layer (coordinate.md, research.md, etc.)                │
│   - Invokes workflow-classifier agent                           │
│   - Passes classification_result to initialize_workflow_paths() │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ Workflow Classifier Agent (Haiku)                               │
│   - Analyzes workflow description                               │
│   - Generates topic_directory_slug (NEW)                        │
│   - Generates filename_slug per research topic (existing)       │
│   - Returns structured JSON                                     │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ Validation Layer (workflow-initialization.sh)                   │
│   - validate_topic_directory_slug() (NEW)                       │
│   - Three-tier fallback: LLM -> extract -> sanitize             │
│   - Security checks (path separators, length limits)            │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ Path Construction (initialize_workflow_paths())                 │
│   - Uses validated slug for topic_name                          │
│   - Idempotent via get_or_create_topic_number()                 │
│   - Creates directory: specs/{NNN}_{topic_directory_slug}/      │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Command invokes classifier**: `claude --print --output-format json ... workflow-classifier`
2. **Classifier returns JSON**: Includes `topic_directory_slug` + research topics
3. **Command calls initialize_workflow_paths()**: Passes classification_result as arg 4
4. **Validation extracts slug**: `validate_topic_directory_slug()` applies three-tier fallback
5. **Path construction uses slug**: `${specs_root}/${topic_num}_${topic_name}`

### Key Files Modified

| File | Purpose | Changes |
|------|---------|---------|
| `.claude/agents/workflow-classifier.md` | Agent definition | Add topic_directory_slug output specification |
| `.claude/lib/workflow-initialization.sh` | Path initialization | Add validate_topic_directory_slug(), update initialize_workflow_paths() |
| `.claude/lib/topic-utils.sh` | Topic utilities | Add extract_significant_words() function |

## Implementation Phases

### Phase 1: Extend Workflow Classifier Agent
dependencies: []

**Objective**: Add topic_directory_slug field to workflow-classifier agent output schema

**Complexity**: Medium

**Tasks**:
- [ ] Add topic_directory_slug specification to Step 2 output requirements (file: /home/benjamin/.config/.claude/agents/workflow-classifier.md, after line 134)
- [ ] Define format constraints: `^[a-z0-9_]{1,40}$`
- [ ] Add semantic requirements: captures core concept, readable, stable
- [ ] Add examples table with 4+ workflow descriptions and expected slugs
- [ ] Add anti-pattern examples (truncation, numeric prefix, hyphens)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Add validation checkpoint to Step 3 (file: /home/benjamin/.config/.claude/agents/workflow-classifier.md, around line 177)
- [ ] Add topic_directory_slug validation criteria (regex, semantic, length, path separators)
- [ ] Update output format example in Step 4 to include topic_directory_slug
- [ ] Add edge case examples section for topic slugs
- [ ] Add edge case: long verbose description
- [ ] Add edge case: path-heavy description
- [ ] Add edge case: multiple topics
- [ ] Add edge case: action-focused description

**Testing**:
```bash
# Manual test: Invoke classifier with test description
echo "Research the specs directory naming conventions and create implementation plan" | \
  claude --print --output-format json \
    --allowedTools "[]" \
    --appendSystemPrompt "$(cat /home/benjamin/.config/.claude/agents/workflow-classifier.md)"

# Verify output includes topic_directory_slug field matching regex
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(771): complete Phase 1 - Extend workflow-classifier agent`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Implement Validation Functions
dependencies: []

**Objective**: Create validate_topic_directory_slug() and extract_significant_words() functions

**Complexity**: Medium

**Tasks**:
- [ ] Add extract_significant_words() function to topic-utils.sh (file: /home/benjamin/.config/.claude/lib/topic-utils.sh)
- [ ] Implement stopword list (the, a, an, and, or, but, to, for, of, in, on, at, by, with, from, etc.)
- [ ] Extract first 4 significant words >2 characters
- [ ] Format as snake_case and limit to 40 characters
- [ ] Add validate_topic_directory_slug() function to workflow-initialization.sh (file: /home/benjamin/.config/.claude/lib/workflow-initialization.sh, before initialize_workflow_paths)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement Tier 1: Extract and validate LLM slug from classification_result
- [ ] Add security check for path separators
- [ ] Implement Tier 2: Call extract_significant_words() as first fallback
- [ ] Implement Tier 3: Call sanitize_topic_name() as ultimate fallback
- [ ] Add strategy variable for logging (llm|extract|sanitize)
- [ ] Add log_topic_slug_generation() call if function exists
- [ ] Add function documentation comment following existing patterns
- [ ] Use structured error handling (WHICH/WHAT/WHERE pattern)

**Testing**:
```bash
# Source and test functions
source /home/benjamin/.config/.claude/lib/topic-utils.sh
source /home/benjamin/.config/.claude/lib/workflow-initialization.sh

# Test extract_significant_words
result=$(extract_significant_words "I see that in the project directories the names are odd")
[[ "$result" == "see_project_directories_names" ]] || echo "FAIL: got $result"

# Test validate_topic_directory_slug with mock classification
json='{"topic_directory_slug": "specs_directory_naming"}'
result=$(validate_topic_directory_slug "$json" "test workflow")
[[ "$result" == "specs_directory_naming" ]] || echo "FAIL: got $result"

# Test fallback to extract when slug invalid
json='{"topic_directory_slug": "invalid-with-hyphens"}'
result=$(validate_topic_directory_slug "$json" "research authentication patterns")
echo "Fallback result: $result"

echo "Phase 2 validation tests complete"
```

**Expected Duration**: 2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(771): complete Phase 2 - Implement validation functions`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Integrate with initialize_workflow_paths()
dependencies: [1, 2]

**Objective**: Update initialize_workflow_paths() to use LLM-generated topic slug when available

**Complexity**: Low

**Tasks**:
- [ ] Modify initialize_workflow_paths() to extract and use topic_directory_slug (file: /home/benjamin/.config/.claude/lib/workflow-initialization.sh, around line 358-360)
- [ ] Call validate_topic_directory_slug() when classification_result is provided
- [ ] Fall back to sanitize_topic_name() when classification_result is empty
- [ ] Ensure backward compatibility: commands without classification work unchanged
- [ ] Verify idempotency: same slug produces same topic_num via get_or_create_topic_number()
- [ ] Add logging for slug strategy used

**Testing**:
```bash
# Source functions
source /home/benjamin/.config/.claude/lib/topic-utils.sh
source /home/benjamin/.config/.claude/lib/workflow-initialization.sh
source /home/benjamin/.config/.claude/lib/unified-location-detection.sh

# Set required environment
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"

# Test with classification result (LLM slug)
json='{"topic_directory_slug": "auth_patterns_implementation", "research_complexity": 2}'
result=$(initialize_workflow_paths "Research auth patterns" "research-only" "2" "$json")
echo "$result" | grep -q "auth_patterns_implementation" && echo "PASS: LLM slug used" || echo "FAIL"

# Test without classification result (fallback to sanitize)
result=$(initialize_workflow_paths "Research auth patterns" "research-only" "2" "")
echo "$result" | grep -q "research_auth_patterns" && echo "PASS: Fallback worked" || echo "FAIL"

# Test idempotency
result1=$(initialize_workflow_paths "Test workflow" "research-only" "2" '{"topic_directory_slug": "test_slug"}')
result2=$(initialize_workflow_paths "Test workflow" "research-only" "2" '{"topic_directory_slug": "test_slug"}')
[[ "$result1" == "$result2" ]] && echo "PASS: Idempotent" || echo "FAIL: Not idempotent"

echo "Phase 3 integration tests complete"
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(771): complete Phase 3 - Integrate with initialize_workflow_paths`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Update Commands for Uniform Integration
dependencies: [3]

**Objective**: Ensure all commands that create named directories use the new semantic slug system

**Complexity**: Low

**Tasks**:
- [ ] Verify coordinate.md passes classification_result correctly (file: /home/benjamin/.config/.claude/commands/coordinate.md, line ~483)
- [ ] Coordinate already passes classification_result as arg 4 - verify integration works
- [ ] Update plan.md to use consistent slug generation (file: /home/benjamin/.config/.claude/commands/plan.md, line ~224)
- [ ] Replace inline `cut -c1-50` with sanitize_topic_name() call for consistency
- [ ] Or add workflow-classifier invocation for plan command to get semantic slugs
- [ ] Verify research.md works correctly through orchestration flow
- [ ] Test end-to-end with each command type

**Testing**:
```bash
# Test coordinate command flow (creates topic directory with semantic slug)
cd /home/benjamin/.config
echo "Research the authentication patterns and create implementation plan" | \
  /home/benjamin/.config/.claude/commands/coordinate.md --dry-run

# Verify directory name is semantic (e.g., "772_auth_patterns_implementation")
# not truncated (e.g., "772_research_the_authentication_patterns_and_cr")

# Test plan command flow
echo "Create plan for dark mode toggle" | \
  /home/benjamin/.config/.claude/commands/plan.md --dry-run

echo "Phase 4 command integration tests complete"
```

**Expected Duration**: 2 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(771): complete Phase 4 - Update commands for uniform integration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Add Unit Tests
dependencies: [2]

**Objective**: Create comprehensive unit tests for new validation functions

**Complexity**: Medium

**Tasks**:
- [ ] Create test file for topic slug validation (file: /home/benjamin/.config/.claude/tests/test-topic-slug-validation.sh)
- [ ] Test extract_significant_words() with various inputs
- [ ] Test: long verbose descriptions
- [ ] Test: path-heavy descriptions
- [ ] Test: single word inputs
- [ ] Test: stopword-only inputs
- [ ] Test: special characters
- [ ] Test validate_topic_directory_slug() three-tier fallback

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Test: valid LLM slug passthrough (Tier 1)
- [ ] Test: invalid LLM slug triggers extract fallback (Tier 2)
- [ ] Test: empty classification triggers sanitize fallback (Tier 3)
- [ ] Test: path separator injection blocked
- [ ] Test: length limits enforced
- [ ] Add edge case tests based on Haiku integration design report
- [ ] Integrate with existing test runner

**Testing**:
```bash
# Run new test suite
bash /home/benjamin/.config/.claude/tests/test-topic-slug-validation.sh

# Verify all tests pass
# Expected: "All tests passed" or specific test results

# Run full test suite to check for regressions
bash /home/benjamin/.config/.claude/tests/run-all-tests.sh

echo "Phase 5 unit tests complete"
```

**Expected Duration**: 2.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(771): complete Phase 5 - Add unit tests`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Documentation and Cleanup
dependencies: [1, 3, 4, 5]

**Objective**: Update documentation and perform final cleanup

**Complexity**: Low

**Tasks**:
- [ ] Update workflow-classifier agent description if needed
- [ ] Document topic_directory_slug in any relevant guides
- [ ] Update .claude/docs/concepts/directory-protocols.md with semantic slug information
- [ ] Add note about automatic semantic naming when using coordinate command
- [ ] Review and remove any debug logging
- [ ] Ensure all functions have proper documentation comments
- [ ] Verify no TODOs or FIXMEs left in implementation
- [ ] Final code review for style compliance

**Testing**:
```bash
# Final validation
cd /home/benjamin/.config

# Check for leftover TODOs
grep -r "TODO\|FIXME" .claude/lib/workflow-initialization.sh .claude/lib/topic-utils.sh .claude/agents/workflow-classifier.md

# Verify documentation builds/renders correctly
# Run linting if available

# End-to-end test with real workflow
echo "Research the JWT token expiration bug causing authentication failures" | \
  /home/benjamin/.config/.claude/commands/coordinate.md --dry-run

# Expected: Directory named something like "773_jwt_token_expiration_bug"
# NOT: "773_research_the_jwt_token_expiration_bug_causing_"

echo "Phase 6 documentation and cleanup complete"
```

**Expected Duration**: 2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(771): complete Phase 6 - Documentation and cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Test Types

1. **Unit Tests**: Individual function testing for extract_significant_words() and validate_topic_directory_slug()
2. **Integration Tests**: End-to-end testing with initialize_workflow_paths() and classification flow
3. **Regression Tests**: Ensure existing workflows continue to work without classification_result
4. **Edge Case Tests**: Based on research report edge cases (verbose, path-heavy, multi-topic, action-focused)

### Test Commands

```bash
# Run all unit tests
bash /home/benjamin/.config/.claude/tests/test-topic-slug-validation.sh

# Run integration tests
bash /home/benjamin/.config/.claude/tests/test-workflow-initialization.sh

# Run full test suite
bash /home/benjamin/.config/.claude/tests/run-all-tests.sh
```

### Success Metrics

- All unit tests pass (100% pass rate)
- No regressions in existing workflow tests
- Semantic slugs generated for 90%+ of test cases
- Fallback mechanisms activate correctly when LLM unavailable

## Documentation Requirements

### Files to Update

1. **workflow-classifier.md**: Add topic_directory_slug field documentation (Phase 1)
2. **directory-protocols.md**: Document semantic directory naming (Phase 6)
3. **Function comments**: Add JSDoc-style comments to new functions (Phase 2)

### Documentation Standards

- Follow .claude/docs/DOCUMENTATION_STANDARDS.md
- Use clear, concise language
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams
- No emojis in file content

## Dependencies

### Prerequisites

- Haiku model available via Claude API
- Existing workflow-classifier agent functional
- validate_and_generate_filename_slugs() pattern to follow
- jq available for JSON parsing in bash

### External Dependencies

- Claude CLI with `--print --output-format json` support
- jq for JSON extraction in validation functions

### Internal Dependencies

- `/home/benjamin/.config/.claude/lib/topic-utils.sh` - sanitize_topic_name()
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` - initialize_workflow_paths()
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md` - Agent definition

## Risk Mitigation

### Identified Risks

1. **Haiku unavailable**: Mitigated by three-tier fallback to extract_significant_words() then sanitize_topic_name()
2. **Breaking existing workflows**: Mitigated by maintaining backward compatibility when classification_result is empty
3. **Inconsistent slugs**: Mitigated by deterministic Haiku behavior and validation constraints
4. **Security (path injection)**: Mitigated by path separator check in validation

### Rollback Plan

If issues arise:
1. Revert workflow-classifier.md changes (removes topic_directory_slug generation)
2. validate_topic_directory_slug() will automatically fall back to Tier 2/3
3. Existing sanitize_topic_name() continues to work as before

## Notes

- Phase dependencies enable parallel execution: Phases 1 and 2 can run concurrently (no dependencies)
- Phase 5 only depends on Phase 2 (validation functions), can start before Phase 3/4 complete
- Estimated time savings from parallelization: ~40%
