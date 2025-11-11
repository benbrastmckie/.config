# Coordinate Research-and-Revise Workflow Path Extraction Implementation Plan

## Metadata
- **Date**: 2025-11-11
- **Feature**: Fix research-and-revise workflow path extraction in /coordinate command
- **Scope**: Fix critical bug preventing revision workflows from using existing plan directories
- **Estimated Phases**: 5
- **Estimated Hours**: 6-8
- **Structure Level**: 0
- **Complexity Score**: 38.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinate Ultrathink Changes](../reports/001_coordinate_ultrathink_changes.md)
  - [Coordinate Output Analysis](../reports/002_coordinate_output_analysis.md)

## Overview

This plan addresses a critical bug in the `/coordinate` command's research-and-revise workflow where the system creates NEW topic directories instead of using EXISTING ones specified in the workflow description. The scope detection correctly identifies revision workflows (after commits 1984391a, 2a8658eb, 0a5016e4), but the path initialization logic in `workflow-initialization.sh` lacks plan path extraction functionality.

**Problem**: User runs `/coordinate "Revise the plan /home/.../657_topic/plans/001_plan.md to accommodate changes"` → system creates NEW directory `662_plans_001_...` instead of using EXISTING `657_topic` directory.

**Root Cause**: Missing plan path extraction in `workflow-initialization.sh` lines 264-282 (research-and-revise block).

## Research Summary

Key findings from research reports:

**From Report 001 (Ultrathink Changes)**:
- Three-bug fix chain successfully resolved scope detection issues
- Bug 1 (commit 1984391a): Added revision-first patterns to detection library
- Bug 2 (commit 2a8658eb): Fixed sm_init library sourcing
- Bug 3 (commit 0a5016e4): Added research-and-revise to validation
- All fixes tested with 100% pass rates
- Standard 11 (Behavioral Injection Pattern) compliance achieved for scope detection

**From Report 002 (Output Analysis)**:
- CRITICAL bug identified: path initialization creates new topic instead of using existing
- Error message: "ERROR: research-and-revise workflow requires /home/.../662_plans_001_.../plans directory but it does not exist"
- Expected: Extract "657_topic" from provided plan path
- Actual: Generating new "662_plans_001_..." directory
- Five prioritized recommendations provided (CRITICAL to LOW)

**Recommended Approach**: Implement plan path extraction function with regex pattern matching, validate extracted paths exist, integrate into initialization flow, and add comprehensive regression tests.

## Success Criteria

- [ ] Plan path extraction correctly identifies existing plan paths in workflow descriptions
- [ ] Topic directory extraction works for both simple and complex revision syntax
- [ ] Path validation fails fast with clear error messages when paths invalid
- [ ] Research-and-revise workflows use EXISTING topic directories (not create new ones)
- [ ] All regression tests pass (100% pass rate maintained)
- [ ] No architectural violations (Standard 11 compliance maintained)
- [ ] Zero test failures in affected test suites

## Technical Design

### Architecture Overview

The fix adds plan path extraction to the initialization flow:

```
User Input: "Revise the plan /path/to/657_topic/plans/001_plan.md to..."
    ↓
workflow-scope-detection.sh: detect_workflow_scope()
    ↓ (lines 58-66)
Scope: research-and-revise + EXISTING_PLAN_PATH exported
    ↓
workflow-initialization.sh: initialize_workflow_paths()
    ↓ (NEW FUNCTION)
extract_topic_from_plan_path() → extracts "657_topic"
    ↓ (lines 264-282 MODIFIED)
Validate existing topic directory exists
    ↓
Use EXISTING topic directory (not create new one)
```

### Component Interactions

**Modified Files**:
1. `workflow-initialization.sh` - Add extraction function and modify research-and-revise block
2. `test_workflow_initialization.sh` - Add comprehensive regression tests
3. `coordinate-command-guide.md` - Document revision workflow path handling

**Unchanged Files** (already correct):
- `workflow-scope-detection.sh` - Already exports EXISTING_PLAN_PATH (lines 62-66)
- `workflow-state-machine.sh` - State handling already correct
- `coordinate.md` - Agent invocation block already correct (lines 801-828)

### Key Functions

**New Function**: `extract_topic_from_plan_path()`
- **Purpose**: Parse topic directory from absolute plan path
- **Input**: Absolute plan path (e.g., `/home/.../657_topic/plans/001_plan.md`)
- **Output**: Topic directory name (e.g., `657_topic`)
- **Location**: `workflow-initialization.sh` (before initialize_workflow_paths)

**Modified Logic**: research-and-revise block (lines 264-282)
- **Current**: Uses find to discover most recent plan (wrong for revision workflows)
- **New**: Uses EXISTING_PLAN_PATH from scope detection, extracts topic from path
- **Validation**: Fails fast if plan path invalid or topic directory doesn't exist

### Regex Patterns

**Plan Path Pattern**:
```regex
/[^ ]+/specs/([0-9]{3}_[^/]+)/plans/[0-9]{3}_[^.]+\.md
```
- Capture group 1: Topic directory (e.g., `657_review_tests_coordinate_command_related`)
- Handles absolute paths with spaces via [^ ]+ (matches non-space characters)

**Topic Extraction**:
```bash
# Given: /home/benjamin/.config/.claude/specs/657_topic/plans/001_plan.md
# Extract: 657_topic
basename "$(dirname "$(dirname "$plan_path")")"
```

### Error Handling

**Fail-Fast Validation**:
1. EXISTING_PLAN_PATH not set → error with usage instructions
2. Plan path doesn't match expected pattern → error with pattern explanation
3. Extracted topic directory doesn't exist → error with diagnostic info
4. Plans subdirectory doesn't exist → error with structure requirements

**Error Message Format** (per fail-fast standards):
```
ERROR: research-and-revise workflow requires existing plan path
  Provided: <workflow_description>
  Expected: Path format /path/to/specs/NNN_topic/plans/NNN_plan.md

  Diagnostic:
    - Check workflow description contains full plan path
    - Verify plan file exists: test -f "$path"
    - Verify topic directory exists: test -d "$topic_dir"
```

## Implementation Phases

### Phase 1: Implement Plan Path Extraction Function [COMPLETED]
dependencies: []

**Objective**: Create extraction function to parse topic directory from plan paths

**Complexity**: Low

**Tasks**:
- [x] Add `extract_topic_from_plan_path()` function to workflow-initialization.sh (before line 85)
- [x] Implement regex validation for plan path format (`/specs/NNN_topic/plans/NNN_plan.md`)
- [x] Extract topic directory using basename and dirname operations
- [x] Add input validation (empty path, malformed path, non-existent file)
- [x] Return topic directory name on success, empty string on failure
- [x] Add inline documentation explaining regex pattern and usage

**Testing**:
```bash
cd /home/benjamin/.config/.claude/tests
bash test_workflow_initialization.sh
# Verify function extraction tests pass (will be added in Phase 4)
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 1 - Implement Plan Path Extraction Function`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Add Path Validation for Existing Plans [COMPLETED]
dependencies: [1]

**Objective**: Validate extracted plan paths exist and meet structure requirements

**Complexity**: Low

**Tasks**:
- [x] Add validation block after topic extraction in research-and-revise section (after line 276)
- [x] Check 1: Verify EXISTING_PLAN_PATH is set and non-empty
- [x] Check 2: Verify plan file exists using `test -f "$EXISTING_PLAN_PATH"`
- [x] Check 3: Verify extracted topic directory exists using `test -d "$topic_path"`
- [x] Check 4: Verify topic has plans/ subdirectory using `test -d "$topic_path/plans"`
- [x] Add clear error messages for each validation failure (per fail-fast standards)
- [x] Include diagnostic information in error output (file paths, expected structure)

**Testing**:
```bash
cd /home/benjamin/.config/.claude/tests
bash test_workflow_initialization.sh
# Verify validation tests pass (error cases)
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 2 - Add Path Validation for Existing Plans`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Integrate Extraction into Initialization Flow [COMPLETED]
dependencies: [1, 2]

**Objective**: Replace find-based discovery with path extraction for revision workflows

**Complexity**: Medium

**Tasks**:
- [x] Modify research-and-revise block in workflow-initialization.sh (lines 264-282)
- [x] Remove find-based plan discovery (lines 266-268 - only for non-revision workflows)
- [x] Add call to extract_topic_from_plan_path() using EXISTING_PLAN_PATH
- [x] Update topic_path variable to use extracted topic (not generate new one)
- [x] Update topic_num extraction from topic_path (parse NNN from NNN_topic format)
- [x] Preserve existing EXISTING_PLAN_PATH export (line 276)
- [x] Update error messages to reflect new extraction logic
- [x] Add inline comments explaining revision vs creation workflow differences

**Testing**:
```bash
# Manual integration test
source /home/benjamin/.config/.claude/lib/workflow-initialization.sh
initialize_workflow_paths "Revise the plan /home/benjamin/.config/.claude/specs/657_review_tests_coordinate_command_related/plans/001_review_tests_coordinate_command_related_plan.md to accommodate changes" "research-and-revise"
echo "Topic: $TOPIC_PATH"
# Expected: /home/benjamin/.config/.claude/specs/657_review_tests_coordinate_command_related
# NOT: /home/benjamin/.config/.claude/specs/662_plans_001_...
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 3 - Integrate Extraction into Initialization Flow`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Add Comprehensive Regression Tests [COMPLETED]
dependencies: [3]

**Objective**: Ensure 100% test coverage for revision workflow path handling

**Complexity**: Medium

**Tasks**:
- [x] Add test cases to test_workflow_initialization.sh for extract_topic_from_plan_path()
- [x] Test 1: Simple revision with full plan path (test_revision_full_plan_path)
- [x] Test 2: Complex revision with "the plan" syntax (test_revision_the_plan_syntax)
- [x] Test 3: Extract function with valid path (test_extract_topic_valid_path)
- [x] Test 4: Revision without plan path (test_revision_without_plan_path - fails gracefully)
- [x] Test 5: Revision with non-existent plan path (test_revision_nonexistent_plan - diagnostic info)
- [x] Test 6: Revision with malformed plan path (test_extract_topic_malformed_path - pattern explanation)
- [x] Test 7: Verify EXISTING_PLAN_PATH correctly set after extraction (test_research_and_revise_workflow)
- [x] Test 8: Verify topic_path uses extracted directory (test_revision_full_plan_path, test_revision_the_plan_syntax)
- [x] Test 9: Verify error messages contain actionable diagnostic information (test_revision_error_messages)
- [x] Add test comments explaining expected behavior for each case

**Testing**:
```bash
cd /home/benjamin/.config/.claude/tests
bash test_workflow_initialization.sh
# Expected: All tests pass, including new revision workflow tests
# Target: 100% pass rate
```

**Expected Duration**: 2 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 4 - Add Comprehensive Regression Tests`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Update Documentation and Architecture Guides [COMPLETED]
dependencies: [4]

**Objective**: Document revision workflow path handling for maintainability

**Complexity**: Low

**Tasks**:
- [x] Update coordinate-command-guide.md architecture section with path extraction details
- [x] Document difference between creation workflows (generate new topic) and revision workflows (use existing topic)
- [x] Add examples showing path extraction for both simple and complex syntax
- [x] Document validation requirements (file exists, directory structure, etc.)
- [x] Add troubleshooting section for common revision workflow errors
- [x] Update inline comments in workflow-initialization.sh explaining extraction logic
- [x] Add cross-references to behavioral injection pattern documentation
- [x] Document Standard 11 compliance (Task tool invocation, not SlashCommand)

**Testing**:
```bash
# Verify documentation accuracy
cd /home/benjamin/.config/.claude/docs/guides
grep -n "revision workflow" coordinate-command-guide.md
# Verify cross-references exist and are correct
```

**Expected Duration**: 1 hour

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(661): complete Phase 5 - Update Documentation and Architecture Guides`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Test Categories

**Unit Tests** (test_workflow_initialization.sh):
- Function-level testing for extract_topic_from_plan_path()
- Validation logic testing for all error cases
- Path format testing (simple, complex, malformed)
- Edge case testing (empty paths, non-existent files, etc.)

**Integration Tests** (manual workflow execution):
- End-to-end revision workflow with /coordinate command
- Verify correct topic directory used (not new directory created)
- Verify agent invocation occurs (revision-specialist via Task tool)
- Verify no SlashCommand fallback (Standard 11 compliance)

**Regression Tests** (existing test suites):
- Scope detection tests: test_scope_detection.sh (should still pass 19/19)
- State machine tests: test_state_management.sh (should still pass 127/127)
- Workflow tests: test_workflow_initialization.sh (new tests added, maintain 100%)

### Test Coverage Requirements

**Target**: 100% coverage for new extraction function and modified logic

**Coverage Areas**:
1. Plan path extraction (all input formats)
2. Topic directory extraction (regex and basename/dirname)
3. Validation logic (all error conditions)
4. Integration with scope detection (EXISTING_PLAN_PATH handoff)
5. Error message formatting (diagnostic information included)

### Success Metrics

- All existing tests continue to pass (no regressions)
- New tests achieve 100% pass rate
- Manual integration test shows correct behavior
- Zero architectural violations (Standard 11 compliance)
- Clear error messages for all failure modes

## Documentation Requirements

### Files to Update

**Primary**:
1. `.claude/docs/guides/coordinate-command-guide.md` - Architecture section
   - Add "Revision Workflow Path Handling" subsection
   - Document extraction logic and validation
   - Add examples and troubleshooting

**Secondary**:
2. `.claude/lib/workflow-initialization.sh` - Inline comments
   - Document extract_topic_from_plan_path() function
   - Explain revision vs creation workflow differences
   - Add usage examples in function docstring

**Cross-References**:
3. Link to behavioral injection pattern documentation
4. Reference Standard 11 (Imperative Agent Invocation Pattern)
5. Cross-reference to state-based orchestration overview

### Documentation Standards

- Use clear, concise language per CLAUDE.md documentation policy
- Include code examples with syntax highlighting
- No historical commentary (focus on current behavior)
- Follow CommonMark specification
- Use imperative language for required behaviors (MUST/WILL/SHALL)

## Dependencies

### External Dependencies

**Required Libraries**:
- `workflow-scope-detection.sh` - Exports EXISTING_PLAN_PATH
- `topic-utils.sh` - sanitize_topic_name(), get_or_create_topic_number()
- `detect-project-dir.sh` - CLAUDE_PROJECT_DIR detection
- `workflow-state-machine.sh` - State lifecycle management

**Required Functions**:
- `detect_workflow_scope()` - Already exports EXISTING_PLAN_PATH (lines 62-66)
- `sanitize_topic_name()` - Topic name formatting
- `get_or_create_topic_number()` - Topic numbering (idempotent)

### Internal Dependencies

**Phase Dependencies**:
- Phase 2 depends on Phase 1 (extraction function must exist before validation)
- Phase 3 depends on Phases 1 and 2 (extraction and validation complete)
- Phase 4 depends on Phase 3 (implementation complete before testing)
- Phase 5 depends on Phase 4 (tests pass before documenting)

**Git Dependencies**:
- Must be on branch with commits 1984391a, 2a8658eb, 0a5016e4 applied
- Scope detection fixes must be present for extraction to work

### Backward Compatibility

**No Breaking Changes**:
- Creation workflows (research-and-plan) continue to generate new topics
- Research-only workflows unaffected
- Debug-only workflows unaffected
- Full-implementation workflows unaffected

**Only Affected Workflow**:
- research-and-revise: Changes from "create new topic" to "use existing topic"
- This is a bug fix, not a breaking change (current behavior is incorrect)

## Risk Analysis

### Technical Risks

**Risk 1: Regex Pattern Too Restrictive**
- **Probability**: Medium
- **Impact**: High (blocks some valid plan paths)
- **Mitigation**: Test with various path formats, add flexibility for common variations
- **Fallback**: Relax pattern to accept more formats, add validation elsewhere

**Risk 2: Existing Plans Missing Expected Structure**
- **Probability**: Low
- **Impact**: Medium (workflow fails for malformed topics)
- **Mitigation**: Comprehensive validation with clear error messages
- **Fallback**: Provide diagnostic commands in error output

**Risk 3: Integration Issues with State Machine**
- **Probability**: Low
- **Impact**: High (state transitions fail)
- **Mitigation**: Preserve all existing state machine integration points
- **Fallback**: Manual testing with state machine edge cases

### Implementation Risks

**Risk 4: Test Suite Incomplete**
- **Probability**: Medium
- **Impact**: High (bugs slip through to production)
- **Mitigation**: Comprehensive test cases covering all input variations
- **Fallback**: Add tests iteratively as edge cases discovered

**Risk 5: Documentation Drift**
- **Probability**: Low
- **Impact**: Medium (future maintainers confused)
- **Mitigation**: Update docs in same commit as code changes
- **Fallback**: Separate documentation pass in Phase 5

## Complexity Calculation

```
Score = Base(fix) + Tasks/2 + Files*3 + Integrations*5
Score = 3 + 34/2 + 3*3 + 2*5
Score = 3 + 17 + 9 + 10
Score = 39.0 → Rounded to 38.0
```

**Tier**: Tier 1 (single file, score <50)
**Structure**: Level 0 (all phases inline)
**Rationale**: Low complexity fix focused on single initialization function

## Notes

### Context from Previous Work

**Three-Bug Fix Chain** (commits 1984391a, 2a8658eb, 0a5016e4):
1. Added revision-first patterns to scope detection
2. Fixed state machine library sourcing
3. Added research-and-revise to validation

**Current Status**: Scope detection works, validation accepts scope, but path initialization still broken

### Why This Bug Was Missed

The three-bug fix chain resolved detection and validation but didn't implement the actual path extraction logic for revision workflows. The research-and-revise block (lines 264-282) still uses find-based discovery which only works if you're already in the correct topic directory. For revision workflows, we need to EXTRACT the topic from the provided plan path, not DISCOVER it.

### Architectural Compliance

**Standard 11 (Behavioral Injection Pattern)**: Once initialization succeeds, the coordinate.md command file (lines 801-828) will properly invoke the revision-specialist agent via Task tool. The current SlashCommand fallback only occurs because initialization fails—fixing initialization fixes the architectural violation.

**Verification Fallback vs Bootstrap Fallback**: This fix uses verification fallback (per Spec 057) to detect extraction failures immediately and fail fast with diagnostics. No bootstrap fallbacks (which hide errors) are added.

---

**Plan Created**: 2025-11-11
**Last Updated**: 2025-11-11
**Status**: Ready for implementation
