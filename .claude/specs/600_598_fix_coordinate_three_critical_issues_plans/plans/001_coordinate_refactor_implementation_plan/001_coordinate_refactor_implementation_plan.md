# /coordinate Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-05
- **Feature**: High-value refactoring improvements for /coordinate command reliability and maintainability
- **Scope**: High-value phases that improve reliability and maintainability
- **Estimated Phases**: 4 (of 7 original phases)
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 1
- **Expanded Phases**: [4, 7]
- **Complexity Score**: 68.0
- **Related Specifications**:
  - [Spec 598: Fix /coordinate Three Critical Issues](/home/benjamin/.config/.claude/specs/598_fix_coordinate_three_critical_issues/plans/001_fix_coordinate_three_critical_issues.md)
  - [Spec 599: Comprehensive Refactor Plan](/home/benjamin/.config/.claude/specs/599_coordinate_refactor_research/plans/001_coordinate_comprehensive_refactor.md)
- **Research Reports**:
  - [Coordinate Refactor Plan Analysis](/home/benjamin/.config/.claude/specs/600_598_fix_coordinate_three_critical_issues_plans/reports/001_coordinate_refactor_plan_analysis_research.md)
  - [598 Implementation Analysis](/home/benjamin/.config/.claude/specs/600_598_fix_coordinate_three_critical_issues_plans/reports/002_598_implementation_analysis_research.md)
  - [Integration Requirements Analysis](/home/benjamin/.config/.claude/specs/600_598_fix_coordinate_three_critical_issues_plans/reports/003_integration_requirements_research.md)

## Executive Summary

The /coordinate command contains several high-value improvement opportunities that significantly enhance reliability and maintainability:

- **Phase 1**: Extract scope detection to library (eliminates 48-line duplication, highest-risk synchronization point)
- **Phase 3**: Add synchronization validation tests (prevents desynchronization bugs)
- **Phase 4**: Document architectural constraints (provides clear guidance on state management patterns)
- **Phase 7**: Add decision framework to command guide (enables informed pattern selection across all commands)

This plan focuses on four critical phases that provide the highest value while maintaining code quality and architectural coherence. Lower-value optimizations (Phases 2, 5, 6) are deferred as the current implementation meets functional requirements.

### Current State

**Completed Foundation Work**:
- Stateless recalculation pattern established for critical variables
- PHASES_TO_EXECUTE mapping implemented in multiple blocks
- Defensive validation in place for key operations
- overview-synthesis.sh integrated into all REQUIRED_LIBS arrays

**Remaining Opportunities**:
- 48-line scope detection duplication across 2 blocks creates synchronization risk
- No automated synchronization validation tests
- Architecture documentation gap for state management patterns
- No decision framework for state management in command development guide

### Value Proposition

**Reliability Improvements**:
- Eliminates highest-risk code synchronization point (scope detection)
- Automated tests prevent desynchronization regressions
- Clear architectural guidance prevents misguided refactor attempts

**Knowledge Transfer**:
- Decision framework enables all commands to benefit from state management patterns
- Documentation provides troubleshooting guide for common issues
- Case studies illustrate successful pattern application

## Phase Completion Status

### Phase 1: Extract Scope Detection to Library
- **Status**: Planned
- **Estimate**: 2-3 hours
- **Priority**: CRITICAL - Eliminates highest-risk synchronization point

### Phase 2: Consolidate Variable Initialization
- **Status**: Deferred
- **Rationale**: Current variable initialization meets functional requirements; consolidation provides marginal value

### Phase 3: Add Synchronization Validation Tests
- **Status**: Planned
- **Estimate**: 2-3 hours
- **Priority**: CRITICAL - Prevents desynchronization bugs

### Phase 4: Document Architectural Constraints
- **Status**: Planned
- **Estimate**: 2-3 hours
- **Priority**: HIGH - Provides clear guidance on state management patterns

### Phase 5: Enhance Defensive Validation
- **Status**: Deferred
- **Rationale**: Critical defensive validation in place; additional validation sites provide marginal value

### Phase 6: Optimize Phase 0 Block Structure
- **Status**: Deferred
- **Rationale**: Current Phase 0 structure meets performance requirements; optimization provides marginal benefit

### Phase 7: Add Decision Framework to Command Guide
- **Status**: Planned
- **Estimate**: 2-3 hours
- **Priority**: HIGH - Enables informed pattern selection across all commands

## Implementation Phases

### Phase 1: Extract Scope Detection to Library [COMPLETED]
**Dependencies**: []
**Complexity**: Low (2/10)
**Duration**: 2-3 hours
**Priority**: CRITICAL

#### Objective
Eliminate the 48-line scope detection duplication between Block 1 and Block 3 by extracting logic to a shared library function.

#### Current State Analysis

**Duplication Locations**:
1. Block 1 (coordinate.md:573-597) - 24 lines of scope detection logic
2. Block 3 (coordinate.md:923-944) - 24 lines of identical scope detection logic

**Total Duplication**: 48 lines (2.1% of command file)

**Scope Detection Logic**:
```bash
if echo "$WORKFLOW_DESCRIPTION" | grep -qiE 'research.*\(report|investigate|analyze'; then
  if echo "$WORKFLOW_DESCRIPTION" | grep -qiE '\(plan|implement|design\)'; then
    WORKFLOW_SCOPE="full-implementation"
  elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE 'create.*plan'; then
    WORKFLOW_SCOPE="research-and-plan"
  else
    WORKFLOW_SCOPE="research-only"
  fi
elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE '\(debug|fix|troubleshoot\)'; then
  WORKFLOW_SCOPE="debug-only"
else
  WORKFLOW_SCOPE="full-implementation"
fi
```

**Risk Level**: HIGH - Scope detection changes require synchronization across 2 locations

#### Implementation Tasks

- [x] **Task 1.1**: Create library file `.claude/lib/workflow-scope-detection.sh`
  - File structure:
    ```bash
    #!/bin/bash
    # Scope Detection Library for /coordinate Command
    # Provides centralized workflow scope detection logic

    detect_workflow_scope() {
      local workflow_description="$1"
      local scope=""

      # [Insert 24-line scope detection logic here]

      echo "$scope"
    }

    export -f detect_workflow_scope
    ```
  - Add header comments explaining purpose and usage
  - Add validation for empty workflow_description parameter

- [x] **Task 1.2**: Update Block 1 to use library function (coordinate.md:573-597)
  - Replace inline scope detection with library call:
    ```bash
    WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
    ```
  - Verify library sourced in REQUIRED_LIBS arrays (should be in all 4)
  - Add defensive validation after library call

- [x] **Task 1.3**: Update Block 3 to use library function (coordinate.md:923-944)
  - Replace inline scope detection with library call (same as Block 1)
  - Remove synchronization warning comment (library eliminates need)
  - Add defensive validation after library call

- [x] **Task 1.4**: Add library to REQUIRED_LIBS arrays
  - research-only array (line 656)
  - research-and-plan array (line 665)
  - full-implementation array (line 676)
  - debug-only array (line 690)
  - Update count comments (4→5, 6→7, 9→10, 7→8)

- [x] **Task 1.5**: Create unit tests for scope detection function
  - Test 1: research-only scope detection
  - Test 2: research-and-plan scope detection
  - Test 3: full-implementation scope detection
  - Test 4: debug-only scope detection
  - Test 5: Edge case - empty workflow description

- [x] **Task 1.6**: Run integration tests
  - Execute `.claude/tests/test_coordinate_integration.sh`
  - Verify all 16 existing tests pass
  - Verify all 4 workflow scopes execute correctly

#### Success Criteria

- ✅ Library file created: `.claude/lib/workflow-scope-detection.sh`
- ✅ Block 1 uses library function (24 lines removed)
- ✅ Block 3 uses library function (24 lines removed)
- ✅ Library added to all 4 REQUIRED_LIBS arrays
- ✅ 5 unit tests created and passing
- ✅ All 16 integration tests passing
- ✅ Code duplication reduced by 48 lines (44% of 108-line total)

#### Testing

**Unit Tests** (new file: `.claude/tests/test_scope_detection.sh`):
```bash
# Test 1: research-only
result=$(detect_workflow_scope "research authentication patterns")
[ "$result" = "research-only" ] || fail

# Test 2: research-and-plan
result=$(detect_workflow_scope "research auth and create plan")
[ "$result" = "research-and-plan" ] || fail

# Test 3: full-implementation
result=$(detect_workflow_scope "research auth and implement")
[ "$result" = "full-implementation" ] || fail

# Test 4: debug-only
result=$(detect_workflow_scope "debug authentication failure")
[ "$result" = "debug-only" ] || fail

# Test 5: Edge case
result=$(detect_workflow_scope "implement feature X")
[ "$result" = "full-implementation" ] || fail
```

**Integration Tests**: All existing 16 tests in `test_coordinate_integration.sh` must pass.

#### Rollback Plan
If tests fail, revert commit with:
```bash
git revert HEAD
```

Library extraction is low-risk (pure refactor), but if issues arise, inline logic can be restored immediately.

---

### Phase 2: DEFERRED - Consolidate Variable Initialization
**Rationale**: Current variable initialization meets functional requirements. Remaining consolidation work (creating `validate_workflow_state()` function and grouping variables) provides marginal value compared to other phases.

**Current Implementation**:
- PHASES_TO_EXECUTE recalculation in place across blocks
- Defensive validation checks PHASES_TO_EXECUTE is set
- Comments explain variable dependencies
- Synchronization requirements documented

**Potential Future Work**:
- Create `validate_workflow_state()` function for centralized validation
- Group related variables together for improved readability
- Add validation tests for variable state consistency

**Time Allocation**: Deferred to focus on higher-value phases

---

### Phase 3: Add Automated Synchronization Validation Tests [COMPLETED]
**Dependencies**: [1]
**Complexity**: Low (2/10)
**Duration**: 2-3 hours
**Priority**: CRITICAL

#### Objective
Create automated tests that verify synchronization requirements are maintained across duplicate code locations, preventing desynchronization bugs.

#### Current State Analysis

**Synchronization Points** (after Phase 1 completes):
1. **CLAUDE_PROJECT_DIR Detection**: 6 locations (24+ duplicate lines)
   - Block 1, Block 2, Block 3, Block 4, Block 5, Block 6
2. **Library Sourcing Pattern**: 6 locations (36+ duplicate lines)
   - Same blocks as CLAUDE_PROJECT_DIR
3. **PHASES_TO_EXECUTE Mapping**: 2 locations (25 duplicate lines each)
   - Block 1 lines 607-626
   - Block 3 lines 957-976
4. **REQUIRED_LIBS Arrays**: 4 locations (conditional on workflow scope)
   - research-only, research-and-plan, full-implementation, debug-only

**Risk Level**: MEDIUM - With Phase 1 completed, scope detection uses library (no synchronization needed); other patterns require synchronization

#### Implementation Tasks

- [x] **Task 3.1**: Create test file `.claude/tests/test_coordinate_synchronization.sh`
  - Add standard test header (shebang, path setup)
  - Source test utilities if available
  - Add test counter and failure tracking

- [x] **Task 3.2**: Implement Test 1 - CLAUDE_PROJECT_DIR Pattern Consistency
  - Extract CLAUDE_PROJECT_DIR detection logic from all 7 blocks
  - Compare extracted patterns for exact match
  - Fail if any divergence detected
  - Implementation approach:
    ```bash
    # Extract pattern from each block (sed/awk)
    pattern1=$(sed -n '/Block 1 start/,/Block 1 end/p' coordinate.md | grep -A5 "CLAUDE_PROJECT_DIR")
    pattern2=$(sed -n '/Block 2 start/,/Block 2 end/p' coordinate.md | grep -A5 "CLAUDE_PROJECT_DIR")
    # ... for all 7 blocks

    # Compare patterns
    if [ "$pattern1" != "$pattern2" ]; then
      echo "FAIL: CLAUDE_PROJECT_DIR pattern mismatch between Block 1 and Block 2"
      exit 1
    fi
    ```

- [x] **Task 3.3**: Implement Test 2 - Library Sourcing Pattern Consistency
  - Extract library sourcing logic from all 7 blocks
  - Verify all blocks use identical sourcing pattern
  - Check for consistent error handling
  - Verify all blocks source from `${CLAUDE_PROJECT_DIR}/.claude/lib/` or `${LIB_DIR}/`

- [x] **Task 3.4**: Implement Test 3 - Scope Detection Uses Library
  - Verify Block 1 calls `detect_workflow_scope()` function
  - Verify Block 3 calls `detect_workflow_scope()` function
  - Fail if inline scope detection logic found (grep for detection patterns)
  - This test validates Phase 1 extraction

- [x] **Task 3.5**: Implement Test 4 - Required Libraries Complete
  - Verify all 4 REQUIRED_LIBS arrays include necessary libraries
  - Check research-only includes: workflow-scope-detection.sh, overview-synthesis.sh
  - Check research-and-plan adds: unified-logger.sh
  - Check full-implementation adds: checkpoint-utils.sh, error-handling.sh
  - Check debug-only includes appropriate subset

- [x] **Task 3.6**: Implement Test 5 - PHASES_TO_EXECUTE Mapping Consistency
  - Extract PHASES_TO_EXECUTE case statement from Block 1
  - Extract PHASES_TO_EXECUTE case statement from Block 3
  - Compare for exact match (excluding comments)
  - This synchronization point requires validation

- [x] **Task 3.7**: Implement Test 6 - Defensive Validation Present
  - Verify WORKFLOW_SCOPE validation exists after library call (Block 1)
  - Verify WORKFLOW_DESCRIPTION validation exists in Block 3
  - Verify PHASES_TO_EXECUTE validation exists
  - Check validation includes diagnostic error messages

- [x] **Task 3.8**: Add test to test suite runner
  - Test can be run standalone: `bash .claude/tests/test_coordinate_synchronization.sh`
  - Integrated with existing test runner

- [x] **Task 3.9**: Run all tests and verify passing
  - Execute new synchronization test suite
  - Verify all 6 tests pass
  - Run existing integration tests (109 total tests)
  - Verify no regressions

#### Success Criteria

- ✅ Test file created: `.claude/tests/test_coordinate_synchronization.sh`
- ✅ 6 synchronization tests implemented and passing
- ✅ Tests detect CLAUDE_PROJECT_DIR divergence
- ✅ Tests detect library sourcing divergence
- ✅ Tests validate scope detection uses library (Phase 1 verification)
- ✅ Tests validate REQUIRED_LIBS completeness
- ✅ Tests validate PHASES_TO_EXECUTE mapping consistency
- ✅ Tests validate defensive validation presence
- ✅ All existing tests still passing (16/16)

#### Testing

**Test Execution**:
```bash
# Run new synchronization tests
.claude/tests/test_coordinate_synchronization.sh

# Expected output:
# PASS: CLAUDE_PROJECT_DIR pattern consistent across 6 blocks
# PASS: Library sourcing pattern consistent across 6 blocks
# PASS: Scope detection uses library function
# PASS: All required libraries present in REQUIRED_LIBS arrays
# PASS: PHASES_TO_EXECUTE mapping consistent between Block 1 and Block 3
# PASS: Defensive validation present after critical recalculations
#
# 6/6 tests passing
```

**Integration Validation**:
```bash
# Run full test suite
.claude/tests/test_orchestration_commands.sh

# Expected: 12/12 tests passing (no regression)
```

#### Rollback Plan
Synchronization tests are non-invasive (read-only validation). If tests fail unexpectedly, they can be disabled while investigation proceeds. No rollback needed.

---

### Phase 4: Document Architectural Constraints (High Complexity)
**Objective**: Create comprehensive architectural documentation explaining stateless recalculation pattern and state management decisions.

**Status**: PENDING

**Summary**: This phase creates centralized architecture documentation covering subprocess isolation constraints, the stateless recalculation pattern, rejected alternatives with trade-off analysis, a decision matrix for pattern selection, troubleshooting guides, and FAQ. Documentation addresses the gap between inline comments and comprehensive architectural guidance, preventing future refactor attempts based on misunderstanding.

**Key Deliverables**:
- Architecture documentation file (`.claude/docs/architecture/coordinate-state-management.md`)
- 9 major sections: subprocess isolation, pattern description, rejected alternatives, decision matrix, troubleshooting, FAQ, historical context, CLAUDE.md integration, inline cross-references
- Decision matrix comparing 4 state management patterns with performance characteristics
- Troubleshooting guide covering 5+ common issues with diagnostic procedures
- FAQ section answering 10+ developer questions

For detailed tasks and implementation, see [Phase 4 Details](phase_4_document_architectural_constraints.md)

---

### Phase 5: DEFERRED - Enhance Defensive Validation
**Rationale**: Critical defensive validation exists for PHASES_TO_EXECUTE with diagnostic error messaging. Remaining work (auditing other sites, creating `validate_required_functions()`) provides marginal value compared to other phases.

**Current Implementation**:
- Defensive validation after PHASES_TO_EXECUTE recalculation
- Enhanced error messages with diagnostic info (shows WORKFLOW_SCOPE)
- Pattern established for additional validation sites

**Potential Future Work**:
- Audit CLAUDE_PROJECT_DIR recalculation sites (6 locations)
- Add validation after WORKFLOW_SCOPE detection
- Create `validate_required_functions()` function for comprehensive validation
- Add validation tests for additional sites

**Time Allocation**: Deferred to focus on higher-value phases

---

### Phase 6: DEFERRED - Optimize Phase 0 Block Structure
**Rationale**: Current Phase 0 structure meets performance requirements (<500ms). Optimization provides marginal benefit and carries risk of introducing code transformation bugs.

**Current State**:
- Block 1: 176 lines (within 300-line threshold)
- Block 2: 168 lines (within 300-line threshold)
- Block 3: 77 lines (within 300-line threshold)
- Total Phase 0: 421 lines

**Trade-off**: Fewer blocks (less recalculation) vs transformation risk (>400 lines per block)

**Analysis**: Current structure balances performance and transformation risk appropriately. Block consolidation deferred.

**Time Allocation**: Deferred to focus on higher-value phases

---

### Phase 7: Add State Management Decision Framework (Very High Complexity)
**Objective**: Update command development guide with comprehensive state management decision framework for all commands.

**Status**: PENDING

**Summary**: This phase adds a complete state management patterns section to the command development guide, documenting 4 state management patterns (stateless recalculation, checkpoint files, file-based state, single large block) with decision criteria, anti-patterns, and case studies. The framework enables all future command development to benefit from established patterns with clear guidance on pattern selection based on computation cost, workflow complexity, and state persistence requirements.

**Key Deliverables**:
- "State Management Patterns" section in command-development-guide.md (1,500-2,000 lines)
- 4 comprehensive pattern documentation blocks with code examples and trade-offs
- Decision framework with tree diagram and 11-criteria comparison table
- 4 anti-patterns with technical explanations and references to specs 582-594
- 2 case studies (/coordinate, /implement) with timelines and lessons learned
- Cross-references to architecture documentation and CLAUDE.md

For detailed tasks and implementation, see [Phase 7 Details](phase_7_add_decision_framework.md)

---

## Testing Strategy

### Unit Tests
**Location**: `.claude/tests/test_scope_detection.sh`

**Coverage**:
- Scope detection function with all 4 workflow types
- Edge cases (empty input, malformed descriptions)

**Test Count**: 5 tests

### Synchronization Tests
**Location**: `.claude/tests/test_coordinate_synchronization.sh`

**Coverage**:
- CLAUDE_PROJECT_DIR pattern consistency (6 locations)
- Library sourcing pattern consistency (6 locations)
- Scope detection uses library function (validation of Phase 1)
- REQUIRED_LIBS completeness (4 arrays)
- PHASES_TO_EXECUTE mapping consistency
- Defensive validation presence

**Test Count**: 6 tests

### Integration Tests
**Location**: `.claude/tests/test_coordinate_integration.sh` (existing)

**Coverage**:
- 4 scope detection workflow tests
- 12 full workflow integration tests

**Test Count**: 16 tests (all must continue passing)

### Total Test Coverage

**Existing Tests**: 16 (preserved)
**New Tests**: 11 (5 unit + 6 synchronization)
**Total Tests**: 27 tests

**Coverage Target**: ≥80% for modified code

### Test Execution Order

1. **Phase 1 completion**: Run unit tests (5) and integration tests (16)
2. **Phase 3 completion**: Run synchronization tests (6) and integration tests (16)
3. **Phase 4 completion**: Documentation review (no automated tests)
4. **Phase 7 completion**: Documentation review (no automated tests)
5. **Final validation**: Run all tests (27) to verify no regressions

## Success Criteria

### Reliability Improvements
- ✅ Scope detection synchronization eliminated (48-line duplication → 0)
- ✅ Automated synchronization tests prevent future desynchronization
- ✅ All existing tests passing (16/16) after refactor
- ✅ New validation tests added and passing (11 tests)

### Simplicity Improvements
- ✅ Code duplication reduced (108 lines → 60 lines, 44% reduction)
- ✅ Single source of truth for scope detection (library function)
- ✅ Clear documentation explaining design decisions

### Maintainability Improvements
- ✅ Architecture documentation complete (design decisions documented)
- ✅ Synchronization validation tests prevent regression
- ✅ Decision framework in command development guide
- ✅ Future developers can apply patterns to other commands

### Performance Criteria
- ✅ Library function call overhead <1ms (measured)
- ✅ No performance regression vs current implementation
- ✅ All workflow scopes execute in expected time

### Documentation Criteria
- ✅ Architecture documentation created and complete
- ✅ Command development guide updated with decision framework
- ✅ CLAUDE.md updated with links to architecture documentation
- ✅ All cross-references resolve correctly

## Risk Mitigation

### Risk 1: Breaking Existing Workflows
**Likelihood**: Low
**Impact**: High

**Mitigation**:
- Phase 1 is pure refactor (extract to library, no logic changes)
- 100% backward compatibility maintained
- Phase-by-phase validation (run tests after each phase)
- Git commits enable immediate rollback

**Detection**: Run 16 integration tests after Phase 1 completion

### Risk 2: Synchronization Tests False Positives
**Likelihood**: Low
**Impact**: Medium

**Mitigation**:
- Test logic carefully reviewed before implementation
- Manual verification of test output
- Tests focus on semantic patterns, not exact string matching (where appropriate)

**Detection**: Run tests on known-good coordinate.md before making changes

### Risk 3: Documentation Becomes Outdated
**Likelihood**: Medium
**Impact**: Low

**Mitigation**:
- Cross-reference inline comments to architecture documentation
- Synchronization tests validate code matches documented patterns
- Architecture documentation lives in version control (tracks with code)

**Detection**: Periodic review of architecture documentation (quarterly)

### Risk 4: Time Overrun
**Likelihood**: Low
**Impact**: Low

**Mitigation**:
- Focused scope (4 of 7 phases, skipping lower-value work)
- Clear phase boundaries (can stop after any phase)
- Realistic time estimates (2-3 hours per phase)

**Detection**: Track actual time per phase, adjust scope if needed

## Rollback Strategy

**Per-Phase Rollback**:
- Create atomic git commit after each phase completes
- If tests fail, run: `git revert HEAD`
- Re-evaluate approach before retrying

**Full Rollback**:
- If multiple phases need rollback: `git revert <commit-range>`
- Worst case: Revert to pre-refactor state (functional baseline maintained)

**Rollback Safety**:
- Phase 1: Low risk (pure refactor, easily reverted)
- Phase 3: No risk (tests are non-invasive)
- Phase 4: No risk (documentation only)
- Phase 7: No risk (documentation only)

## Dependencies and Standards Alignment

### External Dependencies
**None** - All changes internal to /coordinate and supporting libraries/documentation

### Library Dependencies

**New Libraries Created**:
- `.claude/lib/workflow-scope-detection.sh` (Phase 1)

**Existing Libraries Used** (unchanged):
- `.claude/lib/library-sourcing.sh`
- `.claude/lib/workflow-initialization.sh`
- `.claude/lib/workflow-detection.sh`
- `.claude/lib/verification-helpers.sh`
- `.claude/lib/unified-logger.sh`
- `.claude/lib/overview-synthesis.sh`

### Project Standards Alignment

**Standard 13 - CLAUDE_PROJECT_DIR Detection**:
- Pattern maintained in all bash blocks
- No changes to detection logic

**Phase 0 Optimization**:
- Pre-calculation pattern maintained
- No changes to Phase 0 structure

**Fail-Fast Principle**:
- Defensive validation maintained for critical operations
- Synchronization tests enforce pattern compliance

**Documentation Policy**:
- Architecture documentation follows standards (clear, concise, present-focused)
- Command guide update follows standards (code examples, navigation links)
- All directories maintain README.md files

## Documentation Requirements

### Files to Create

1. `.claude/lib/workflow-scope-detection.sh` - Scope detection library (Phase 1)
2. `.claude/tests/test_scope_detection.sh` - Unit tests for scope detection (Phase 1)
3. `.claude/tests/test_coordinate_synchronization.sh` - Synchronization validation tests (Phase 3)
4. `.claude/docs/architecture/coordinate-state-management.md` - Architecture documentation (Phase 4)

### Files to Update

1. `.claude/commands/coordinate.md` - Use library function for scope detection (Phase 1), add inline cross-references (Phase 4)
2. `CLAUDE.md` - Link to architecture documentation (Phase 4)
3. `.claude/docs/guides/command-development-guide.md` - Add state management decision framework (Phase 7)

### Documentation Standards

Per CLAUDE.md documentation policy, all documentation must:
- Use clear, concise language
- Include code examples with syntax highlighting
- Use Unicode box-drawing for diagrams
- Avoid emojis (UTF-8 encoding issues)
- Focus on present state (no historical commentary)
- Include navigation links to parent and related documents

## Time Estimates and Schedule

### Phase Duration Summary

| Phase | Description | Duration | Priority | Dependencies |
|-------|-------------|----------|----------|--------------|
| 1 | Extract scope detection to library | 2-3 hours | CRITICAL | None |
| 2 | SKIPPED (70% done by 598) | - | - | - |
| 3 | Add synchronization validation tests | 2-3 hours | CRITICAL | Phase 1 |
| 4 | Document architectural constraints | 2-3 hours | HIGH | Phase 1, 3 |
| 5 | SKIPPED (60% done by 598) | - | - | - |
| 6 | SKIPPED (optimization not critical) | - | - | - |
| 7 | Add decision framework to guide | 2-3 hours | HIGH | Phase 4 |

**Total Duration**: 8-12 hours (vs 18-24 hours original estimate)

### Execution Schedule

**Week 1**:
- Day 1: Phase 1 (scope detection library) - 2-3 hours
- Day 2: Phase 3 (synchronization tests) - 2-3 hours

**Week 2**:
- Day 3: Phase 4 (architecture documentation) - 2-3 hours
- Day 4: Phase 7 (command guide update) - 2-3 hours
- Day 5: Final validation and testing - 1 hour

**Total Calendar Time**: 5 working days (with buffer)

### Critical Path

**Phase 1** → **Phase 3** → **Phase 4** → **Phase 7**

All phases are sequential (each depends on previous completion).

## Final Verification Checklist

Before considering refactor complete, verify:

- [ ] **Phase 1 Complete**
  - [ ] Library file created: `.claude/lib/workflow-scope-detection.sh`
  - [ ] Block 1 uses library function (24 lines removed)
  - [ ] Block 3 uses library function (24 lines removed)
  - [ ] Library added to all 4 REQUIRED_LIBS arrays
  - [ ] 5 unit tests created and passing
  - [ ] All 16 integration tests passing

- [ ] **Phase 3 Complete**
  - [ ] Test file created: `.claude/tests/test_coordinate_synchronization.sh`
  - [ ] 6 synchronization tests implemented and passing
  - [ ] All existing tests still passing (16/16)

- [ ] **Phase 4 Complete**
  - [ ] Architecture documentation created: `.claude/docs/architecture/coordinate-state-management.md`
  - [ ] Subprocess isolation documented with examples
  - [ ] Stateless recalculation pattern documented
  - [ ] Rejected alternatives documented with rationale
  - [ ] Decision matrix created
  - [ ] Troubleshooting guide added (3+ issues)
  - [ ] FAQ section added (4+ questions)
  - [ ] CLAUDE.md updated with link
  - [ ] Inline cross-references added in coordinate.md

- [ ] **Phase 7 Complete**
  - [ ] "State Management Patterns" section added to command guide
  - [ ] 4 patterns documented (stateless, checkpoint, file-based, single-block)
  - [ ] Decision tree diagram created
  - [ ] Decision criteria table created
  - [ ] 4+ anti-patterns documented
  - [ ] 2+ case studies added
  - [ ] Cross-references added
  - [ ] Table of contents updated

- [ ] **Overall Quality**
  - [ ] All tests passing (27 total: 16 integration + 5 unit + 6 synchronization)
  - [ ] Code duplication reduced by 44% (108 → 60 lines)
  - [ ] No performance regression (<1ms overhead measured)
  - [ ] All documentation follows CLAUDE.md standards
  - [ ] Git commits created for each phase
  - [ ] Rollback tested (verify git revert works)

## Appendix A: Phase Selection Rationale

### Phases Selected for Implementation

| Phase | Status | Rationale |
|-------|--------|-----------|
| Phase 1: Extract scope detection | ✅ PLANNED | Eliminates highest-risk synchronization point (48-line duplication) |
| Phase 2: Consolidate initialization | ❌ DEFERRED | Current implementation meets functional requirements |
| Phase 3: Add synchronization tests | ✅ PLANNED | Prevents desynchronization regressions through automated validation |
| Phase 4: Document architecture | ✅ PLANNED | Provides clear guidance on state management patterns |
| Phase 5: Enhance validation | ❌ DEFERRED | Critical validation in place; additional sites provide marginal value |
| Phase 6: Optimize block structure | ❌ DEFERRED | Current structure meets performance requirements |
| Phase 7: Add decision framework | ✅ PLANNED | Enables informed pattern selection across all commands |

**Summary**:
- Planned Implementation: 4 of 7 phases (57%)
- Deferred: 3 of 7 phases (43%)
- Focus: Highest-value phases for reliability and knowledge transfer

### Value Delivered

**Critical Value (Phases 1, 3)**:
- Eliminate highest-risk synchronization point (48-line scope detection)
- Prevent future desynchronization bugs via automated tests

**High Value (Phases 4, 7)**:
- Prevent future refactor attempts via architecture documentation
- Transfer knowledge to other commands via decision framework

**Deferred Phases (2, 5, 6)**:
- Phase 2: Current variable initialization meets functional requirements
- Phase 5: Critical validation in place; additional sites provide marginal value
- Phase 6: Current structure meets performance requirements

### Risk Management

**Potential Risks**:
- Breaking workflows during refactor
- Time investment (8-12 hours commitment)
- Over-engineering working code

**Mitigation Strategies**:
- Focus on highest-value, lowest-risk phases
- Defer phases with marginal value
- Focused scope reduces time investment
- Atomic git commits enable immediate rollback

## Appendix B: Related Specifications

### Foundation Work

**Spec 598**: Fixed three critical bugs in /coordinate command
- Added overview-synthesis.sh to all REQUIRED_LIBS arrays
- Extended stateless recalculation pattern to PHASES_TO_EXECUTE
- Corrected full-implementation phase list to include Phase 6

**Spec 599**: Comprehensive refactor analysis
- Identified 7 improvement opportunities
- Analyzed trade-offs and complexity scores
- Provided foundation for this focused implementation plan

### This Plan's Focus

**Phase 1** (Extract scope detection):
- Eliminates remaining high-risk synchronization point (48-line duplication)
- Reduces code duplication by 44% (108 lines → 60 lines)

**Phase 3** (Synchronization tests):
- Validates synchronization requirements across all duplicate code locations
- Prevents desynchronization regressions

**Phase 4** (Architecture documentation):
- Documents stateless recalculation pattern rationale
- Explains when to use this pattern vs alternatives

**Phase 7** (Decision framework):
- Codifies state management patterns for all commands
- Enables informed pattern selection through documented criteria

## Appendix C: Decision Rationale

### Why Execute Phase 1?

**Value**: Eliminates 48-line duplication (highest-risk synchronization point)

**Rationale**:
- Scope detection logic changes require 2-location updates (Block 1 and Block 3)
- Past specs demonstrate synchronization burden leads to bugs
- Library extraction is low-risk refactoring pattern
- Clear test validation (5 unit tests + 16 integration tests)

**Alternative Considered**: Skip Phase 1, accept 48-line duplication
**Why Rejected**: Scope detection is complex logic (24 lines, 4 workflow types, nested conditionals). Duplication risk > library overhead.

### Why Execute Phase 3?

**Value**: Prevents future desynchronization bugs (validates 598 fixes)

**Rationale**:
- 598 created new synchronization point (PHASES_TO_EXECUTE in 2 locations)
- No current automated detection of synchronization drift
- Tests are non-invasive (read-only validation)
- High ROI (2-3 hours investment prevents multi-hour debugging sessions)

**Alternative Considered**: Skip tests, rely on manual review
**Why Rejected**: Manual review fragile. Past specs (582-594) demonstrate manual synchronization fails.

### Why Execute Phase 4?

**Value**: Prevents future refactor attempts based on misunderstanding

**Rationale**:
- Specs 582-594 represent ~7 refactor attempts over time
- Root cause: Lack of documented rationale for stateless pattern
- Documentation is low-risk (no code changes)
- High value (prevents repeat of 7-spec exploration)

**Alternative Considered**: Skip documentation, rely on inline comments
**Why Rejected**: Inline comments don't provide decision matrix or troubleshooting guide. Centralized documentation more discoverable.

### Why Execute Phase 7?

**Value**: Transfers knowledge to other command development

**Rationale**:
- Other commands may face similar state management questions
- Decision framework enables informed pattern selection
- Case studies (specs 597, 598) provide concrete examples
- Prevents each command from rediscovering patterns independently

**Alternative Considered**: Skip framework, let developers discover patterns organically
**Why Rejected**: Inefficient. Each developer would repeat 7-spec exploration. Framework amortizes learning cost.

### Why Skip Phase 2?

**Completion**: 598 already completed 70% of work

**Remaining Work**:
- Create `validate_workflow_state()` function (marginal value)
- Group related variables together (cosmetic improvement)
- Add 2 validation tests (redundant with Phase 3 tests)

**Rationale**: Low ROI. Current implementation works. Remaining tasks provide minimal value.

### Why Skip Phase 5?

**Completion**: 598 already completed 60% of work

**Remaining Work**:
- Audit other variable recalculation sites (already working)
- Create `validate_required_functions()` (nice-to-have, not critical)
- Add 3 validation tests (redundant with Phase 3 tests)

**Rationale**: Most critical validation (PHASES_TO_EXECUTE) already added by 598. Diminishing returns.

### Why Skip Phase 6?

**Current State**: Phase 0 structure working well (3 blocks, 421 lines total)

**Optimization Goal**: Reduce block count to reduce recalculation overhead

**Rationale**:
- Current overhead <10ms (acceptable)
- Block consolidation carries code transformation risk (>400 lines)
- Trade-off analysis favors current structure (simplicity > optimization)
- Optimization provides marginal performance benefit (<5ms saved)

**Risk**: Over-engineering working code for minimal gain.


---

## Revision History

### 2025-11-05 - Standards Conformance Revision

**Changes**: Updated plan to conform to project standards in `.claude/docs/`

**Modifications**:
1. **Writing Standards**: Removed temporal language and historical references
   - Eliminated "598 already accomplished" phrasing
   - Removed "post-598", "after 598" temporal markers
   - Changed status labels from "SKIPPED" to "DEFERRED" with present-focused rationale
   - Replaced comparative language with current state descriptions

2. **Directory Protocols**: Updated phase dependency format
   - Changed `Dependencies: None (foundation phase)` to `Dependencies: []`
   - Changed `Dependencies: [Phase 1 complete]` to `Dependencies: [1]`
   - Changed `Dependencies: [Phase 4 complete]` to `Dependencies: [4]`

3. **Present-Focused Documentation**: Restructured Executive Summary
   - Removed "What 598 Accomplished" section
   - Added "Current State" section describing implementation status
   - Focused on opportunities rather than historical changes

4. **Appendix Updates**:
   - Renamed "Comparison to Original 599 Plan" to "Phase Selection Rationale"
   - Renamed "Integration with Spec 598" to "Related Specifications"
   - Removed temporal comparisons and historical context
   - Focused on current capabilities and rationale

**Reason**: Ensure plan follows timeless writing standards and directory protocol specifications per CLAUDE.md and `.claude/docs/concepts/`

**Modified Sections**: Executive Summary, Phase Completion Status, all Phase descriptions, all Appendices
