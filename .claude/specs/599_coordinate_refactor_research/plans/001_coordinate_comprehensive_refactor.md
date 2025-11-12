# /coordinate Comprehensive Refactor Plan

## Metadata
- **Date**: 2025-11-05
- **Feature**: Comprehensive refactor of /coordinate command for improved reliability and simplicity
- **Scope**: Code organization, architectural alignment, and maintainability improvements
- **Estimated Phases**: 7
- **Estimated Hours**: 18-24 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Research Reports**:
  - [/coordinate Stateless Design Analysis](/home/benjamin/.config/.claude/specs/599_coordinate_refactor_research/reports/001_coordinate_stateless_design_analysis.md)
  - [Past Refactor Failures Analysis](/home/benjamin/.config/.claude/specs/599_coordinate_refactor_research/reports/002_past_refactor_failures_analysis.md)
  - [Project State Management Standards](/home/benjamin/.config/.claude/specs/599_coordinate_refactor_research/reports/003_project_state_management_standards.md)
  - [Stateful Workflow Best Practices](/home/benjamin/.config/.claude/specs/599_coordinate_refactor_research/reports/004_stateful_workflow_best_practices.md)

## Executive Summary

After systematic research of current implementation, past failures, project standards, and industry best practices, this refactor plan aims to **improve the existing stateless recalculation pattern** rather than replace it with state-based design. The core architectural decision is to **evolve, not revolutionize**.

### Key Findings from Research

1. **Current Pattern is Correct**: The stateless recalculation pattern (Standard 13) is architecturally sound given Bash tool subprocess isolation (GitHub #334, #2508)
2. **Past Failures Were Incremental**: Specs 582-598 demonstrate that partial fixes missed interconnected issues, leading to repeated refactor attempts
3. **Code Duplication is Acceptable**: 50-line duplication (spec 597) is simpler than alternatives (file-based state adds 30-50 lines synchronization + I/O)
4. **Real Problem**: Brittleness from synchronization burden, not the pattern itself

### Architectural Recommendation: Enhanced Stateless Pattern

**Option Selected**: Improved stateless recalculation (evolution)

**Rationale**:
- Performance: <1ms overhead vs 30ms file-based state
- Simplicity: Fewer failure modes than state persistence
- Validated: Spec 597 implementation passed 16/16 tests
- Industry Alignment: Mirrors Bazel's deterministic build approach

**Trade-offs Accepted**:
- Code duplication remains (50-80 lines)
- Synchronization burden reduced but not eliminated
- No session persistence (acceptable for single-invocation command)

### Expected Impact

**Reliability Improvements**:
- Eliminate 2 critical synchronization points (scope detection, library sourcing)
- Add defensive validation to catch missing state early
- Document architectural constraints to prevent regression

**Simplicity Improvements**:
- Extract inline scope detection to library (eliminates 48-line duplication)
- Consolidate Phase 0 variable initialization (single source of truth)
- Add automated synchronization validation tests

**Maintainability Improvements**:
- Clear documentation of why duplication exists
- Decision matrix for state management in command development guide
- Synchronization checklist for future modifications

## Research Summary

### Report 001: Stateless Design Analysis

**Key Findings**:
- Current pattern: 6+ CLAUDE_PROJECT_DIR recalculations across bash blocks (24+ duplicate lines)
- Scope detection duplicated in 2 locations (48 duplicate lines)
- Total code duplication: ~108 lines (4.7% of file)
- Phase 0 complexity: 520 lines (23% of command file)

**Pain Points**:
- Synchronization burden: Changes to scope detection require 2-location updates
- Brittleness: 6 duplication sites requiring coordination
- Cognitive overhead: Developers must understand stateless pattern rationale

**Validated Design Decision**: "Bash Tool Limitations" section (lines 2176-2256) documents trade-off analysis rejecting file-based state due to I/O overhead, cleanup complexity, and failure modes.

### Report 002: Past Refactor Failures

**Pattern Identified**: Treating symptoms rather than root architectural constraint

**Chronological Evolution**:
1. Specs 582-584: Discovery phase (exports don't persist)
2. Spec 585: Research validation (stateless pattern optimal)
3. Spec 593: Analysis phase (comprehensive problem mapping)
4. Spec 597: Breakthrough (accept duplication, embrace pattern)
5. Spec 598: Completion (extend to derived variables)

**Why Spec 597 Succeeded**:
- Accepted tool constraints (didn't fight subprocess isolation)
- Embraced duplication (50 lines, <1ms cost)
- Systematic analysis (reviewed 7 previous specs)
- Validated performance (150ms overhead acceptable)

**Critical Lesson**: "Sometimes the 'right' solution involves accepting what looks like 'wrong' (code duplication), because the alternatives (fighting the tool, complex abstractions, file-based state) are worse."

### Report 003: Project State Management Standards

**Standard 13 - Project Directory Detection**:
- REQUIRED in every bash block
- 4-line pattern (<5ms overhead)
- Rationale: BASH_SOURCE unavailable in SlashCommand context

**Checkpoint-Based State Management**:
- Used for multi-phase workflows (≥5 phases)
- 35% time savings for resumable workflows
- Schema v1.3 with migration support

**Phase 0 Optimization Pattern**:
- Pre-calculate all artifact paths before subagent invocation
- 85% token reduction (11k vs 75.6k baseline)
- 100% reliability (no command substitution in agents)

**Decision Criteria**:
- Recalculation <100ms → Use stateless pattern
- Workflow ≥5 phases → Use checkpoint-based state
- Reliability critical → Use idempotent operations + checkpoints

### Report 004: Industry Best Practices

**Stateless Recalculation (Bazel)**:
- Content-addressable storage with deterministic builds
- Hash calculation negligible (<1ms) vs rebuild time
- Trade-off: Deterministic correctness over timestamp speed

**Checkpoint-Based State (Temporal)**:
- Automatic checkpointing for long-running workflows
- Exactly-once execution guarantees
- Resume from last checkpoint without lost progress

**Idempotent Operations (Event-Driven Systems)**:
- Three classes: natural, deduplication, event sourcing
- Pre-operation checkpoint → operation → cleanup pattern
- Rollback capability for partial failures

**Hierarchical Configuration (Git, AWS CLI)**:
- Progressive customization (flags > env > config > defaults)
- Clear precedence order
- XDG Base Directory compliance

**Key Insight**: Simplest code is fastest (direct assignments <1ms vs library sourcing 100-200ms vs file I/O 10-20ms)

## Root Cause Analysis

### TRUE Root Causes (Not Symptoms)

**1. Bash Tool Subprocess Isolation** (GitHub #334, #2508)
- **Nature**: Fundamental architectural constraint, not a bug
- **Impact**: Exports don't persist between bash blocks
- **Correct Response**: Accept constraint, design around it (stateless recalculation)
- **Incorrect Response**: Fight constraint with complex workarounds (file-based state, IPC mechanisms)

**2. Synchronization Burden from Code Duplication**
- **Nature**: Maintenance pain from duplicating logic in multiple locations
- **Impact**: 2 critical synchronization points (scope detection, library sourcing)
- **Root Cause**: Lack of library extraction for deterministic operations
- **Solution**: Extract scope detection to library, source in each block

**3. Incomplete Refactorings** (Human Error)
- **Nature**: Specs fixed visible symptoms but missed interconnected issues
- **Impact**: Multiple refactor attempts needed for complete fix (597 → 598)
- **Root Cause**: Lack of systematic dependency analysis
- **Solution**: Comprehensive state mapping before refactors

### Why Past Refactors Had Limited Success

**Category 1: Incremental Symptom Fixes** (Specs 583-584)
- Fixed one variable at a time
- Missed derived variables (PHASES_TO_EXECUTE from WORKFLOW_SCOPE)
- No dependency graph analysis

**Category 2: Incomplete Scope** (Spec 597)
- Fixed input variables (WORKFLOW_DESCRIPTION, WORKFLOW_SCOPE)
- Missed derived variables dependent on inputs
- Didn't verify all required libraries loaded

**Category 3: Optimization Breaking Functionality** (Spec 581 → 598)
- Performance optimization (conditional library loading) removed critical library
- overview-synthesis.sh missing from REQUIRED_LIBS
- Functions undefined despite recalculation working

**Pattern**: Each spec fixed "one thing" without mapping full dependency graph.

## Architectural Options Analysis

### Option A: Enhanced Stateless Recalculation (RECOMMENDED)

**Description**: Improve current pattern without changing fundamental approach

**Changes**:
1. Extract inline scope detection to library function
2. Consolidate Phase 0 variable initialization (single source of truth)
3. Add automated synchronization validation tests
4. Document architectural constraints and design decisions

**Pros**:
- Builds on validated pattern (spec 597: 16/16 tests passing)
- Minimal risk (no architectural changes)
- Performance optimal (<1ms overhead)
- Eliminates 48-line duplication (scope detection)
- Maintains fail-fast behavior

**Cons**:
- CLAUDE_PROJECT_DIR duplication remains (6+ locations, but stable)
- Library sourcing duplication remains (6+ locations, but stable)
- Synchronization still required for new variables

**Complexity**: Low (mostly refactoring, not rewriting)

**Risk**: Low (incremental improvements to working system)

**Implementation Time**: 12-16 hours

### Option B: File-Based State Persistence (NOT RECOMMENDED)

**Description**: Replace stateless recalculation with state file written in Block 1, read in subsequent blocks

**Changes**:
1. Create `.claude/tmp/coordinate-state-{PID}.json`
2. Write workflow variables to state file in Block 1
3. Read state file in Blocks 2-3
4. Add cleanup logic for stale state files

**Pros**:
- Eliminates code duplication (all state in one location)
- Theoretically simpler mental model (state persists)

**Cons**:
- File I/O overhead (~30ms per read/write)
- 30-50 lines synchronization code (create, read, write, cleanup, error handling)
- New failure modes (disk full, permissions, concurrent access, stale files)
- Violates fail-fast principle (silent fallback to stale state possible)
- Rejected in spec 585 analysis (lines 2233-2250 of coordinate.md)
- 10x slower than recalculation for simple variables

**Complexity**: Medium (schema design, error handling, cleanup)

**Risk**: Medium (new failure modes, rejected by previous analysis)

**Implementation Time**: 18-24 hours

### Option C: Hybrid Approach (NOT RECOMMENDED)

**Description**: Stateless recalculation for simple state, checkpoints for complex state

**Changes**:
1. Keep CLAUDE_PROJECT_DIR recalculation (stateless)
2. Use checkpoint for WORKFLOW_SCOPE, PHASES_TO_EXECUTE, REQUIRED_LIBS
3. Add checkpoint save after Block 1
4. Add checkpoint restore at start of Blocks 2-3

**Pros**:
- Leverages existing checkpoint-utils.sh infrastructure
- Checkpoint provides audit trail
- Resume capability for interrupted workflows

**Cons**:
- /coordinate is single-invocation command (resume not needed)
- Checkpoint overhead (~30ms) for no benefit (workflow <5 minutes)
- Mixed patterns increase cognitive load (when to use checkpoint vs recalculation?)
- Checkpoint designed for multi-phase workflows (≥5 phases), not single-command execution
- Violates YAGNI principle (you aren't gonna need it)

**Complexity**: Medium (checkpoint integration, pattern mixing)

**Risk**: Low (checkpoint-utils.sh proven), but unnecessary complexity

**Implementation Time**: 14-18 hours

## Recommended Approach: Enhanced Stateless Pattern

### Architectural Decision

**Selected Option**: Option A - Enhanced Stateless Recalculation

**Rationale**:

1. **Performance**: <1ms overhead vs 30ms file-based state (30x faster)
2. **Simplicity**: Fewer failure modes than state persistence
3. **Validated**: Spec 597 implementation passed 16/16 tests with <1ms overhead
4. **Industry Alignment**: Mirrors Bazel's deterministic build approach (accept hash calculation cost for correctness)
5. **Project Standards**: Aligns with Standard 13 and existing patterns

**Trade-offs Accepted**:

1. **Code Duplication Remains**: 50-80 lines across file
   - CLAUDE_PROJECT_DIR: 24+ lines (6+ locations)
   - Library sourcing: 36+ lines (6+ locations)
   - Scope detection: Reduced from 48 to 0 lines (extracted to library)
   - **Justification**: Duplication simpler than alternatives given subprocess isolation

2. **Synchronization Burden Reduced**: From 2 critical points to 0 critical points
   - Scope detection: Extracted to library (single source of truth)
   - Library sourcing: Stable pattern, no recent changes
   - **Justification**: Eliminates high-risk synchronization (scope detection logic changes)

3. **No Session Persistence**: State doesn't persist across /coordinate invocations
   - **Justification**: /coordinate is single-invocation command, not interactive session

### Key Design Principles

1. **Accept Tool Constraints**: Work with Bash tool subprocess isolation, not against it
2. **Fail-Fast**: Missing state causes immediate errors, not silent failures
3. **Simplicity Over DRY**: Accept duplication when abstraction adds more complexity
4. **Defensive Validation**: Validate all critical state after recalculation
5. **Documentation**: Clear comments explaining architectural decisions and trade-offs

### Implementation Strategy

**Phase-Based Approach**: 7 phases with incremental improvements and continuous validation

**Success Criteria Per Phase**:
- All existing tests continue passing (16/16 tests)
- New validation tests added and passing
- Code complexity reduced (measured by duplication sites)
- Documentation complete (architectural decisions documented)

## Implementation Phases

### Phase 1: Foundation - Extract Scope Detection to Library
dependencies: []

**Objective**: Eliminate 48-line scope detection duplication by extracting to library function

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/lib/workflow-scope-detection.sh` library file (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
- [ ] Extract inline scope detection logic from Block 1 (lines 581-604 in coordinate.md)
- [ ] Design library function signature: `detect_workflow_scope "$WORKFLOW_DESCRIPTION"` returns scope string
- [ ] Implement function with same logic as inline detection (24 lines)
- [ ] Add defensive validation (check for invalid scope values)
- [ ] Export function: `export -f detect_workflow_scope`
- [ ] Add unit tests in `.claude/tests/test_workflow_scope_detection.sh` (4 tests for each scope type)
- [ ] Update Block 1 to use library function (replace inline logic with function call)
- [ ] Update Block 3 to use library function (replace duplicate inline logic with function call)
- [ ] Verify synchronization eliminated (scope logic now in single location)

**Testing**:
```bash
# Unit tests
.claude/tests/test_workflow_scope_detection.sh

# Integration tests
.claude/tests/test_coordinate_integration.sh

# Verify all 16 existing tests still pass
```

**Expected Duration**: 2-3 hours

**Validation Criteria**:
- Scope detection duplication reduced from 48 lines to 0 lines
- All existing tests passing (16/16)
- New unit tests passing (4/4)
- Function works identically to inline logic (verified by integration tests)

### Phase 2: Consolidate Phase 0 Variable Initialization
dependencies: [1]

**Objective**: Create single source of truth for Phase 0 variable initialization

**Complexity**: Medium

**Tasks**:
- [ ] Document current variable recalculation sites (inventory all variables recalculated in Blocks 2-3)
- [ ] Create consolidated initialization section in Block 3 (lines 905-962 in coordinate.md)
- [ ] Group related variables together (project paths, workflow state, derived state)
- [ ] Add section comments explaining variable categories and dependencies
- [ ] Implement defensive validation after initialization (check all required variables set)
- [ ] Add validation function: `validate_workflow_state()` checking all critical variables
- [ ] Update Block 2 to use consolidated pattern (if variables needed, source same pattern)
- [ ] Document variable dependency graph (source → derived order)
- [ ] Add inline comments referencing spec 597 and GitHub issues #334, #2508

**Testing**:
```bash
# Test variable initialization
.claude/tests/test_coordinate_variable_initialization.sh

# Test defensive validation
.claude/tests/test_coordinate_validation.sh

# Integration tests
.claude/tests/test_coordinate_integration.sh
```

**Expected Duration**: 3-4 hours

**Validation Criteria**:
- Single source of truth for variable initialization (consolidated section)
- Defensive validation catches missing variables (tested)
- Variable dependency graph documented (clear order)
- All existing tests passing (16/16)

### Phase 3: Add Automated Synchronization Validation Tests
dependencies: [1, 2]

**Objective**: Prevent future synchronization bugs through automated testing

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/tests/test_coordinate_synchronization.sh` test file (file: /home/benjamin/.config/.claude/lib/workflow-scope-detection.sh)
- [ ] Test 1: Verify CLAUDE_PROJECT_DIR recalculation pattern identical across all blocks
- [ ] Test 2: Verify library sourcing pattern identical across all blocks
- [ ] Test 3: Verify scope detection uses library function (not inline logic)
- [ ] Test 4: Verify all required libraries present in REQUIRED_LIBS arrays
- [ ] Test 5: Verify defensive validation present after variable initialization
- [ ] Implement tests using sed/awk to extract and compare bash code blocks
- [ ] Add tests to CI/CD pipeline (if exists) or pre-commit hook
- [ ] Document test rationale and failure remediation steps

**Testing**:
```bash
# Run synchronization validation tests
.claude/tests/test_coordinate_synchronization.sh

# Should catch:
# - CLAUDE_PROJECT_DIR pattern divergence
# - Missing library sourcing
# - Inline scope detection (should be library function)
# - Missing defensive validation
```

**Expected Duration**: 2-3 hours

**Validation Criteria**:
- 5 synchronization validation tests implemented
- Tests catch known desynchronization patterns (verified by intentional breakage)
- Tests integrated into test suite (run with test_coordinate_integration.sh)
- Documentation explains test purpose and failure remediation

### Phase 4: Document Architectural Constraints and Design Decisions
dependencies: [1, 2, 3]

**Objective**: Prevent future regression by documenting why current pattern exists

**Complexity**: Low

**Tasks**:
- [ ] Create `.claude/docs/architecture/coordinate-state-management.md` documentation file (file: /home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md)
- [ ] Document subprocess isolation constraint (GitHub #334, #2508)
- [ ] Document why stateless recalculation chosen over file-based state
- [ ] Document trade-off analysis from spec 585 (lines 2233-2250 in coordinate.md)
- [ ] Add decision matrix for state management (when to use recalculation vs checkpoints)
- [ ] Document scope detection extraction rationale (eliminate synchronization burden)
- [ ] Add troubleshooting guide for common issues (unbound variables, missing libraries)
- [ ] Cross-reference from coordinate.md comments to architecture documentation
- [ ] Update CLAUDE.md with link to architecture documentation
- [ ] Add "Why is code duplicated?" FAQ section

**Testing**:
N/A (documentation phase)

**Expected Duration**: 2-3 hours

**Validation Criteria**:
- Architecture documentation complete (covers all design decisions)
- Decision matrix clear (when to use each pattern)
- Comments in coordinate.md reference documentation
- FAQ addresses common questions about duplication

### Phase 5: Enhance Defensive Validation and Error Messages
dependencies: [2]

**Objective**: Improve fail-fast behavior with clear error messages

**Complexity**: Low

**Tasks**:
- [ ] Audit all variable recalculation sites for defensive validation
- [ ] Add validation after CLAUDE_PROJECT_DIR recalculation (check directory exists)
- [ ] Add validation after WORKFLOW_SCOPE detection (check valid scope value)
- [ ] Add validation after PHASES_TO_EXECUTE calculation (check format and non-empty)
- [ ] Add validation after library sourcing (check required functions defined)
- [ ] Enhance error messages with diagnostic information (expected vs actual, troubleshooting hints)
- [ ] Add validation function: `validate_required_functions()` checking all library functions available
- [ ] Add "Common Issues" section to error messages (link to troubleshooting guide)
- [ ] Test validation by intentionally breaking each condition (verify clear error messages)

**Testing**:
```bash
# Test defensive validation catches errors
.claude/tests/test_coordinate_validation.sh

# Test error messages provide diagnostic information
.claude/tests/test_coordinate_error_messages.sh
```

**Expected Duration**: 2-3 hours

**Validation Criteria**:
- All critical state has defensive validation (tested)
- Error messages include diagnostic information (expected/actual values)
- Error messages link to troubleshooting guide
- Tests verify validation catches errors early (before cascading failures)

### Phase 6: Optimize Phase 0 Block Structure
dependencies: [1, 2, 5]

**Objective**: Reduce Phase 0 complexity while maintaining block size limits

**Complexity**: Medium

**Tasks**:
- [ ] Audit current Phase 0 structure (3 blocks: 176 + 168 + 77 lines = 421 lines total)
- [ ] Identify opportunities for consolidation without exceeding 300-line threshold
- [ ] Consider merging Block 2 (function verification) into Block 1 if combined <300 lines
- [ ] Consider merging Block 3 (path initialization) into Block 2 if combined <300 lines
- [ ] Analyze trade-off: Fewer blocks (less recalculation) vs transformation risk (>400 lines)
- [ ] Implement optimal block structure based on analysis
- [ ] Update comments to explain block split rationale (reference spec 582 transformation threshold)
- [ ] Add performance measurements (Phase 0 target: <500ms)
- [ ] Verify no code transformation with large blocks (test with indirect references `${!var}`)

**Testing**:
```bash
# Test Phase 0 performance
.claude/tests/test_coordinate_phase0_performance.sh

# Test no code transformation
.claude/tests/test_coordinate_bash_transformation.sh

# Integration tests
.claude/tests/test_coordinate_integration.sh
```

**Expected Duration**: 3-4 hours

**Validation Criteria**:
- Phase 0 block structure optimized (fewest blocks without transformation risk)
- Phase 0 completes in <500ms (performance target)
- No code transformation detected (tested with indirect references)
- All existing tests passing (16/16)

### Phase 7: Add State Management Decision Framework to Command Development Guide
dependencies: [4]

**Objective**: Codify lessons learned into reusable decision framework for future commands

**Complexity**: Low

**Tasks**:
- [ ] Update `.claude/docs/guides/command-development-guide.md` with "State Management Patterns" section
- [ ] Add decision tree diagram (when to use recalculation vs checkpoints vs idempotent operations)
- [ ] Document decision criteria (recalculation cost, workflow phases, reliability requirements)
- [ ] Add code examples for each pattern (recalculation, checkpoints, idempotent operations)
- [ ] Cross-reference project standards (Standard 13, checkpoint-utils.sh, Phase 0 optimization)
- [ ] Add anti-patterns section (don't fight tool constraints, don't use export between blocks)
- [ ] Include spec 597 as case study (successful stateless recalculation implementation)
- [ ] Add troubleshooting checklist for state management issues
- [ ] Link to coordinate architecture documentation as reference implementation

**Testing**:
N/A (documentation phase)

**Expected Duration**: 2-3 hours

**Validation Criteria**:
- Decision tree clear and actionable (can determine pattern from criteria)
- Code examples complete and tested (copy-paste ready)
- Anti-patterns documented with rationale (why they fail)
- Case study demonstrates application of decision framework

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed phases with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(599): complete Phase 7 - State Management Decision Framework`
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Overall Testing Approach

**Test Categories**:
1. **Unit Tests**: Individual functions and patterns
2. **Integration Tests**: Full /coordinate workflow with different scopes
3. **Synchronization Tests**: Validate patterns consistent across blocks
4. **Validation Tests**: Defensive validation catches errors
5. **Performance Tests**: Phase 0 completes within budget (<500ms)

### Existing Tests (Preserve)

**Location**: `.claude/tests/test_coordinate_integration.sh`

**Coverage**:
- 4 scope detection tests (research-only, research-and-plan, full-implementation, debug-only)
- 12 workflow integration tests (end-to-end execution)

**Requirement**: All 16 existing tests must continue passing after each phase

### New Tests (Add)

**Phase 1 Tests** (Scope Detection Library):
- Unit test: `detect_workflow_scope()` returns correct scope for each pattern
- Integration test: Block 1 and Block 3 produce identical scope results

**Phase 2 Tests** (Variable Initialization):
- Unit test: `validate_workflow_state()` catches missing variables
- Integration test: All required variables available in Block 3

**Phase 3 Tests** (Synchronization Validation):
- Synchronization test: CLAUDE_PROJECT_DIR pattern identical across blocks
- Synchronization test: Library sourcing pattern identical across blocks
- Synchronization test: Scope detection uses library function (not inline)

**Phase 5 Tests** (Defensive Validation):
- Validation test: Missing CLAUDE_PROJECT_DIR triggers clear error
- Validation test: Invalid WORKFLOW_SCOPE triggers clear error
- Validation test: Missing library triggers clear error with diagnostic info

**Phase 6 Tests** (Phase 0 Performance):
- Performance test: Phase 0 completes in <500ms
- Transformation test: No bash code transformation with large blocks (test `${!var}`)

### Test Execution

**Per-Phase Testing** (after each phase):
```bash
# Run all tests
.claude/tests/test_coordinate_integration.sh

# Expected result: All existing tests passing + new tests for completed phases
```

**Final Validation** (after Phase 7):
```bash
# Full test suite
.claude/tests/run_all_tests.sh | grep coordinate

# Expected result:
# - 16 existing integration tests passing
# - 4 scope detection unit tests passing
# - 2 variable initialization tests passing
# - 3 synchronization validation tests passing
# - 3 defensive validation tests passing
# - 2 Phase 0 performance tests passing
# Total: 30 tests passing
```

### Coverage Requirements

**Target Coverage**: ≥80% for modified code

**Critical Paths Requiring Tests**:
- Scope detection (all 4 scope types)
- Variable initialization (all critical variables)
- Defensive validation (all validation functions)
- Library sourcing (all required libraries)
- Synchronization patterns (CLAUDE_PROJECT_DIR, library sourcing)

## Documentation Requirements

### Files to Update

1. **`.claude/commands/coordinate.md`** (main command file)
   - Update comments to reference architecture documentation
   - Add inline comments explaining design decisions
   - Reference spec 597 and GitHub issues #334, #2508

2. **`.claude/docs/architecture/coordinate-state-management.md`** (NEW)
   - Document subprocess isolation constraint
   - Document stateless recalculation pattern rationale
   - Add decision matrix for state management
   - Add troubleshooting guide

3. **`.claude/docs/guides/command-development-guide.md`** (UPDATE)
   - Add "State Management Patterns" section
   - Add decision tree for choosing pattern
   - Add code examples and anti-patterns

4. **CLAUDE.md** (UPDATE)
   - Link to coordinate architecture documentation
   - Update state management standards section

### Documentation Standards

**Follows**: `nvim/docs/DOCUMENTATION_STANDARDS.md`

**Key Requirements**:
- Clear, concise language
- Code examples with syntax highlighting
- Unicode box-drawing for diagrams
- No emojis (UTF-8 encoding issues)
- No historical commentary (present-focused)

## Dependencies

### External Dependencies

**None** - All changes internal to /coordinate command and supporting libraries

### Library Dependencies

**New Library Created**:
- `.claude/lib/workflow-scope-detection.sh` (Phase 1)

**Existing Libraries Used**:
- `.claude/lib/library-sourcing.sh` (unchanged)
- `.claude/lib/workflow-initialization.sh` (unchanged)
- `.claude/lib/verification-helpers.sh` (unchanged)
- `.claude/lib/unified-logger.sh` (unchanged)
- `.claude/lib/checkpoint-utils.sh` (reference only, not used)

### Project Standards Alignment

**Standard 13**: CLAUDE_PROJECT_DIR detection in every bash block (maintained)

**Phase 0 Optimization**: Pre-calculate paths before subagent invocation (maintained)

**Fail-Fast Principle**: Defensive validation for immediate error detection (enhanced)

**Documentation Policy**: Every directory has README.md (compliance verified)

## Risk Mitigation

### Risk 1: Breaking Existing Workflows

**Likelihood**: Medium
**Impact**: High
**Mitigation**:
- Maintain 100% backward compatibility (existing tests must pass)
- Phase-by-phase approach with validation after each phase
- No changes to external interface (command arguments, output format)
- Rollback strategy: Git revert to previous commit if tests fail

**Detection**: Run test suite after each phase (16/16 tests must pass)

### Risk 2: Introducing New Synchronization Points

**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
- Extract logic to libraries (single source of truth)
- Add automated synchronization validation tests (Phase 3)
- Document synchronization requirements clearly
- Code review checklist includes synchronization verification

**Detection**: Synchronization tests catch divergence

### Risk 3: Library Function Availability Issues

**Likelihood**: Low
**Impact**: Medium
**Mitigation**:
- Defensive validation after library sourcing (check functions defined)
- Clear error messages with diagnostic information
- Test library function availability in each block
- Document library sourcing pattern in architecture documentation

**Detection**: Defensive validation tests (Phase 5)

### Risk 4: Performance Regression

**Likelihood**: Low
**Impact**: Low
**Mitigation**:
- Library function call overhead negligible (<1ms)
- Phase 0 performance target: <500ms (well within budget)
- Performance tests added in Phase 6
- Benchmark before and after refactor

**Detection**: Performance tests catch regression

**Rollback Strategy**:
- Each phase creates atomic git commit
- If tests fail after phase, `git revert` to previous commit
- If performance regresses, revert specific changes and re-evaluate

## Success Criteria

### Reliability Improvements

- [ ] ✅ Scope detection synchronization eliminated (48-line duplication → 0)
- [ ] ✅ Defensive validation added for all critical variables
- [ ] ✅ All existing tests passing (16/16) after refactor
- [ ] ✅ New validation tests added and passing (≥5 tests)

### Simplicity Improvements

- [ ] ✅ Code duplication reduced (108 lines → 60 lines, 44% reduction)
- [ ] ✅ Single source of truth for scope detection (library function)
- [ ] ✅ Consolidated variable initialization in Phase 0
- [ ] ✅ Clear error messages with diagnostic information

### Maintainability Improvements

- [ ] ✅ Architecture documentation complete (design decisions documented)
- [ ] ✅ Synchronization validation tests prevent regression
- [ ] ✅ Decision framework in command development guide
- [ ] ✅ Inline comments reference architecture documentation

### Performance Criteria

- [ ] ✅ Library function call overhead <1ms (measured)
- [ ] ✅ Phase 0 completes in <500ms (performance test passing)
- [ ] ✅ No performance regression vs current implementation

### Documentation Criteria

- [ ] ✅ Architecture documentation created and complete
- [ ] ✅ Command development guide updated with decision framework
- [ ] ✅ CLAUDE.md updated with links to architecture documentation
- [ ] ✅ Inline comments explain design decisions and trade-offs

## Completion Verification

**Final Checklist** (all must be checked):

- [ ] All 7 phases completed (tasks marked [x])
- [ ] All existing tests passing (16/16)
- [ ] All new tests passing (≥14 new tests)
- [ ] Code duplication reduced by ≥40% (measured)
- [ ] Architecture documentation complete
- [ ] Command development guide updated
- [ ] Performance within budget (<500ms Phase 0)
- [ ] No synchronization points remain for scope detection
- [ ] Git commits created for each phase
- [ ] Rollback tested (verify git revert works)

**Definition of Done**:
1. All phases implemented and tested
2. Test suite passing (≥30 tests total)
3. Documentation complete and reviewed
4. Performance validated (<500ms Phase 0)
5. Code review completed
6. Final integration test successful

**Post-Implementation Review**:
- Measure actual code duplication reduction (target ≥40%)
- Measure actual performance improvement (target <500ms Phase 0)
- Collect feedback on error message clarity
- Evaluate maintenance burden reduction (future refactors easier?)

---

**Plan Version**: 1.0
**Last Updated**: 2025-11-05
**Status**: Ready for Implementation
