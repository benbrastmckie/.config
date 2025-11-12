# /coordinate Command Refactoring Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Systematic refactoring of /coordinate command to improve performance, fix verification bugs, reduce redundancy, and optimize context usage
- **Scope**: /coordinate command (coordinate.md), supporting libraries, verification checkpoints, state machine patterns
- **Estimated Phases**: 8
- **Estimated Hours**: 22-28 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [001_coordinate_command_architecture_analysis.md](../reports/001_current_command_implementation_identify/001_coordinate_command_architecture_analysis.md)
  - [002_verification_checkpoint_bug_patterns.md](../reports/001_current_command_implementation_identify/002_verification_checkpoint_bug_patterns.md)
  - [003_performance_bottlenecks_and_optimization.md](../reports/001_current_command_implementation_identify/003_performance_bottlenecks_and_optimization.md)
  - [004_state_machine_redundancy_analysis.md](../reports/001_current_command_implementation_identify/004_state_machine_redundancy_analysis.md)
  - [OVERVIEW.md](../reports/001_current_command_implementation_identify/OVERVIEW.md)
- **Structure Level**: 0
- **Complexity Score**: 42.5

## Overview

The /coordinate command represents a production-ready state-machine-based orchestrator with 100% file creation reliability and validated subprocess isolation patterns. However, systematic issues exist across four critical areas requiring systematic refactoring:

1. **P0 Verification Bug**: Grep pattern mismatch causing 100% false negative rate on state persistence checks
2. **Code Redundancy**: 55.4% boilerplate (832/1,503 lines) requiring consolidation
3. **Performance Bottlenecks**: 1.3s overhead from library re-sourcing and path detection
4. **Context Consumption**: 62% context budget consumed by agent behavioral injection

This refactoring achieves 51% code reduction (1,503 → 736 lines), 44-58% performance improvement (694-900ms savings), 50% context reduction (7,800 tokens freed), and 91% maintainability gain through library consolidation while preserving fail-fast reliability and all existing functionality.

## Research Summary

Research revealed comprehensive analysis across architecture, bugs, performance, and redundancy:

**Architecture Strengths** (Report 001):
- Production-ready with 8-state state machine (127 tests passing, 100% pass rate)
- Validated subprocess isolation patterns (fixed filenames, save-before-source, array serialization)
- Wave-based parallel execution (40-60% time savings)
- Hierarchical coordination (95.6% context reduction for ≥4 topics)
- Comprehensive documentation (1,380-line architecture guide)

**Critical P0 Bug** (Report 002):
- Grep verification pattern `^REPORT_PATHS_COUNT=` fails to match actual format `export REPORT_PATHS_COUNT="4"`
- 100% false negative rate blocks workflow execution despite successful state persistence
- Root cause: Format mismatch between `append_workflow_state()` output and verification expectations
- Immediate fix: Change pattern to `^export REPORT_PATHS_COUNT=`

**Performance Bottlenecks** (Report 003):
- Library re-sourcing: 450-720ms per workflow (7-11 libraries × 9 blocks)
- CLAUDE_PROJECT_DIR detection: 600ms total (50ms × 12 blocks), optimizable to 215ms via caching
- Agent invocation overhead: 15,600 tokens per workflow (62% of context budget)
- Metadata extraction: 12-20ms per workflow (4 grep operations on same file)

**Code Redundancy** (Report 004):
- 55.4% boilerplate: 832 duplicate lines out of 1,503 total
- Root cause: Subprocess isolation requires environment restoration in each bash block
- Consolidation potential: 767 lines reducible to ~170 library lines (52% reduction)
- Primary patterns: Bootstrap (341 lines), verification (300 lines), checkpoints (150 lines)

**Three-Phase Optimization Approach** (OVERVIEW.md):
- Sprint 1 (3-4 hours): P0 bug fix + bootstrap extraction + caching = 23% reduction + 385ms improvement
- Sprint 2 (8-11 hours): Unified verification + lazy loading = 21% reduction + 300-500ms improvement
- Sprint 3 (9-11 hours): Checkpoint pattern + metadata optimization + agent splitting = 7% reduction + context freed

## Success Criteria

- [ ] Fix P0 verification checkpoint bug (100% false negative → 0%)
- [ ] Reduce coordinate.md from 1,503 lines to ~736 lines (51% reduction)
- [ ] Reduce boilerplate from 55.4% to ~20% of file
- [ ] Improve workflow execution time by 694-900ms (44-58% overhead reduction)
- [ ] Free 7,800 tokens via agent behavioral file splitting (50% agent overhead reduction)
- [ ] Maintain 100% file creation reliability (zero regression)
- [ ] Achieve 100% unit test coverage for new library functions
- [ ] Reduce bug fix effort by 91% (11 edits → 1 edit)
- [ ] Reduce code review burden by 94% (363 → 72 lines)
- [ ] Reduce onboarding time by 47% (85-115 min → 45-75 min)
- [ ] All 127 core state machine tests passing (100% pass rate)
- [ ] Integration tests confirm 100% file creation reliability maintained

## Technical Design

### Architecture Principles

**Preserve Core Strengths**:
1. State machine architecture (8 explicit states, transition validation)
2. Subprocess isolation patterns (validated in Specs 620/630/637)
3. Fail-fast error handling (mandatory verification checkpoints)
4. Wave-based parallel execution (40-60% time savings)
5. Hierarchical coordination (95% context reduction)

**Consolidation Strategy**:
1. Extract boilerplate to shared library functions (not replace subprocess model)
2. Maintain human-readable command file (no code generation)
3. Enable incremental adoption (one pattern at a time)
4. Preserve backward compatibility (existing checkpoints work)
5. Unit test all library functions (100% coverage)

**Non-Goals**:
- Change subprocess isolation model (validated, required for progress visibility)
- Migrate to monolithic bash block (loses checkpoint resume)
- Generate command file dynamically (debugging complexity)
- Modify external agent behavioral files (out of scope for this refactoring)

### Key Components

**Component 1: State Machine Bootstrap Library**
- File: `.claude/lib/state-machine-bootstrap.sh`
- Function: `bootstrap_state_handler(expected_state, workflow_id_file)`
- Purpose: Consolidate 33 lines × 11 blocks = 363 lines into single function
- Components: CLAUDE_PROJECT_DIR detection, library sourcing, state loading, validation
- Savings: 341 lines (93.9% reduction)

**Component 2: Unified Verification Pattern**
- File: `.claude/lib/verification-helpers.sh` (extend existing)
- Function: `verify_phase_artifacts(phase_name, phase_abbrev, files...)`
- Purpose: Consolidate 30-40 lines × 10 blocks = 300-400 lines into generic function
- Handles: Loop vs single file, hierarchical vs flat, Standard 0 compliance
- Savings: 310 lines (88.6% reduction)

**Component 3: Checkpoint Emission Pattern**
- File: `.claude/lib/checkpoint-helpers.sh` (new)
- Function: `emit_phase_checkpoint(phase_name, checkpoint_data)`
- Purpose: Consolidate 20-30 lines × 6 blocks = 120-180 lines into generic function
- Handles: Associative array parameters, workflow scope branching
- Savings: 105 lines (70% reduction)

**Component 4: State Transition Wrapper**
- File: `.claude/lib/workflow-state-machine.sh` (extend existing)
- Function: `sm_transition_and_save(next_state)`
- Purpose: Consolidate 2 lines × 11 transitions = 22 lines into wrapper
- Combines: State machine transition + workflow state persistence
- Savings: 11 lines (50% reduction)

**Component 5: Lazy Library Loading**
- Files: `research-bundle.sh`, `planning-bundle.sh`, `implementation-bundle.sh`
- Purpose: Phase-specific library bundles instead of loading all libraries in every block
- Reduces: 63-99 sourcing operations → 18-27 operations
- Savings: 300-500ms per workflow (60-70% reduction)

**Component 6: CLAUDE_PROJECT_DIR Caching**
- Pattern: Save in block 1, load from state in blocks 2-11
- Current: 50ms × 12 blocks = 600ms
- Optimized: 50ms + (15ms × 11 blocks) = 215ms
- Savings: 385ms (64% reduction)

## Implementation Phases

### Phase 0: Preparation and Analysis
dependencies: []

**Objective**: Set up testing infrastructure and validate current baseline

**Complexity**: Low

**Tasks**:
- [ ] Create test directory: `.claude/tests/coordinate-refactoring/` (file: new directory)
- [ ] Document current baseline metrics (file: `.claude/tests/coordinate-refactoring/baseline-metrics.md`)
  - Current line count: 1,503 lines
  - Current boilerplate: 832 lines (55.4%)
  - Current overhead: 1,298ms (measured via benchmark)
  - Current context usage: 15,600 tokens for 4 research agents
- [ ] Create rollback checkpoint (file: backup copy of coordinate.md with timestamp)
- [ ] Run comprehensive test suite baseline (command: `.claude/tests/run_all_tests.sh`)
  - Verify 127 state machine tests passing (100%)
  - Verify subprocess isolation tests passing (100%)
  - Document baseline test results
- [ ] Create integration test for 100% file creation reliability (file: `.claude/tests/coordinate-refactoring/test_file_creation_reliability.sh`)

**Testing**:
```bash
# Verify baseline test suite passes
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh | tee coordinate-refactoring/baseline-test-results.txt

# Extract passing test count
grep -c "PASS" coordinate-refactoring/baseline-test-results.txt
```

**Expected Duration**: 1-2 hours

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Baseline metrics documented (line count, boilerplate %, overhead, context usage)
- [ ] Baseline test results captured (127 state machine tests passing)
- [ ] Rollback checkpoint created (coordinate.md backup with timestamp)
- [ ] Integration test created (file creation reliability verification)
- [ ] Git commit created: `chore(644): establish refactoring baseline for /coordinate`

---

### Phase 1: Fix P0 Verification Checkpoint Bug
dependencies: []

**Objective**: Fix grep pattern mismatch causing 100% false negative rate on state persistence verification

**Complexity**: Low

**Tasks**:
- [ ] Review current grep patterns in coordinate.md:210-226 (file: `.claude/commands/coordinate.md`)
- [ ] Create unit test demonstrating bug (file: `.claude/tests/coordinate-refactoring/test_verification_bug.sh`)
  - Test 1: Verify `append_workflow_state()` output format includes `export` prefix
  - Test 2: Verify current pattern `^REPORT_PATHS_COUNT=` fails to match
  - Test 3: Verify corrected pattern `^export REPORT_PATHS_COUNT=` matches
- [ ] Fix grep pattern at line 210: `^REPORT_PATHS_COUNT=` → `^export REPORT_PATHS_COUNT=`
- [ ] Fix grep patterns in loop at lines 220-226 (10 total patterns for REPORT_PATH_N variables)
- [ ] Add fallback verification pattern (format-agnostic check for robustness)
- [ ] Update error messages to show expected vs actual format on failure
- [ ] Run unit test to verify fix (command: `bash .claude/tests/coordinate-refactoring/test_verification_bug.sh`)
- [ ] Integration test: Run coordinate command with state persistence verification (verify no false negatives)

**Testing**:
```bash
# Unit test for grep pattern fix
bash .claude/tests/coordinate-refactoring/test_verification_bug.sh

# Expected output:
# ✓ append_workflow_state format includes export prefix
# ✓ Corrected pattern matches state file format
# ✓ Fallback pattern handles format variations
# PASS: All verification pattern tests passed
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Unit test created and passing (test_verification_bug.sh)
- [ ] 10 grep patterns fixed in coordinate.md (lines 210, 220-226)
- [ ] Fallback verification pattern added (format-agnostic check)
- [ ] Integration test passes (no false negatives on state verification)
- [ ] Git commit created: `fix(644): correct verification checkpoint grep patterns for state persistence`

---

### Phase 2: Extract State Handler Bootstrap Function
dependencies: [1]

**Objective**: Create unified bootstrap function consolidating 33 lines × 11 blocks = 363 lines of boilerplate

**Complexity**: Medium

**Tasks**:
- [ ] Create new library file: `.claude/lib/state-machine-bootstrap.sh`
- [ ] Implement `bootstrap_state_handler(expected_state, workflow_id_file)` function (~50 lines)
  - Step 1: CLAUDE_PROJECT_DIR detection (with caching support)
  - Step 2: Library re-sourcing (6 critical libraries)
  - Step 3: Workflow state loading (from fixed file location)
  - Step 4: Terminal state check (early exit if complete)
  - Step 5: Current state validation (fail-fast on mismatch)
- [ ] Add source guard pattern (prevent re-initialization)
- [ ] Export bootstrap function for use in command file
- [ ] Create comprehensive unit tests (file: `.claude/tests/test_state_machine_bootstrap.sh`)
  - Test 1: Bootstrap with missing state file (should error)
  - Test 2: Bootstrap with incorrect state (should error)
  - Test 3: Bootstrap at terminal state (should exit 0)
  - Test 4: Bootstrap with correct state (should succeed)
  - Test 5: Library functions available after bootstrap
- [ ] Update coordinate.md block 3 (research handler) to use bootstrap function
  - Replace 33 lines with 2-line pattern: source library + call function
- [ ] Test block 3 in isolation (verify research phase works)
- [ ] Update remaining 10 blocks (planning, implementation, testing, debug, documentation, verification blocks)
- [ ] Integration test: Run full coordinate workflow (verify all phases work)

**Testing**:
```bash
# Unit tests for bootstrap function
bash .claude/tests/test_state_machine_bootstrap.sh

# Integration test: Full workflow
# (Simulate coordinate workflow from research to completion)
```

**Expected Duration**: 2-3 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Library file created (state-machine-bootstrap.sh, ~50 lines)
- [ ] Bootstrap function implemented with all 5 steps
- [ ] Unit tests passing (5 test cases, 100% coverage)
- [ ] All 11 bash blocks updated to use bootstrap function
- [ ] 341 lines removed from coordinate.md (33 lines × 11 blocks)
- [ ] Integration test passes (full workflow executes)
- [ ] Git commit created: `refactor(644): extract state handler bootstrap to library function`

---

### Phase 3: Extract State Transition Wrapper
dependencies: [2]

**Objective**: Create wrapper function consolidating state transition + save pattern (2 lines × 11 transitions)

**Complexity**: Low

**Tasks**:
- [ ] Open `.claude/lib/workflow-state-machine.sh` for editing
- [ ] Implement `sm_transition_and_save(next_state)` function (~10 lines)
  - Call `sm_transition()` for validation
  - Call `append_workflow_state()` to persist state
  - Return 0 on success
- [ ] Export wrapper function
- [ ] Create unit test (file: `.claude/tests/test_state_machine_bootstrap.sh` - add test case)
  - Test 1: Wrapper calls both sm_transition and append_workflow_state
  - Test 2: Invalid transition fails as expected
  - Test 3: Valid transition persists state correctly
- [ ] Update coordinate.md: Replace all 11 occurrences of 2-line pattern with 1-line wrapper call
  - Pattern: `sm_transition "$STATE_X"\nappend_workflow_state "CURRENT_STATE" "$STATE_X"`
  - Replacement: `sm_transition_and_save "$STATE_X"`
- [ ] Run unit tests (verify wrapper function works)
- [ ] Integration test: Verify state transitions persist across bash blocks

**Testing**:
```bash
# Unit tests for wrapper function
bash .claude/tests/test_state_machine_bootstrap.sh

# Verify state persistence
# (Check state file contains correct CURRENT_STATE after each transition)
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Wrapper function implemented in workflow-state-machine.sh (~10 lines)
- [ ] Unit tests passing (3 test cases)
- [ ] All 11 state transitions updated to use wrapper
- [ ] 11 lines removed from coordinate.md (2 → 1 per transition)
- [ ] Integration test passes (state persists correctly)
- [ ] Git commit created: `refactor(644): extract state transition wrapper function`

---

### Phase 4: Optimize CLAUDE_PROJECT_DIR Caching
dependencies: [2]

**Objective**: Remove redundant git rev-parse calls in blocks 2-11, rely on state persistence caching

**Complexity**: Low

**Tasks**:
- [ ] Verify state-persistence.sh already caches CLAUDE_PROJECT_DIR (review library code)
- [ ] Verify bootstrap function includes CLAUDE_PROJECT_DIR detection in step 1
- [ ] Update coordinate.md initialization block (block 2) to save CLAUDE_PROJECT_DIR to state
  - Add: `append_workflow_state "CLAUDE_PROJECT_DIR" "$CLAUDE_PROJECT_DIR"` after initial detection
- [ ] Remove redundant git rev-parse checks from bootstrap function (blocks 2-11)
  - Keep defensive check: `[ -z "$CLAUDE_PROJECT_DIR" ] && exit 1` (fail-fast if missing)
  - Remove: `CLAUDE_PROJECT_DIR="$(git rev-parse ...)"` (rely on state loading)
- [ ] Add comment explaining optimization (cached from state, not recalculated)
- [ ] Benchmark performance improvement (file: `.claude/tests/coordinate-refactoring/benchmark-claude-project-dir.sh`)
  - Current: 50ms × 12 blocks = 600ms
  - Expected: 50ms + (15ms × 11 blocks) = 215ms
  - Target: 385ms improvement (64% reduction)
- [ ] Integration test: Verify CLAUDE_PROJECT_DIR available in all blocks

**Testing**:
```bash
# Benchmark CLAUDE_PROJECT_DIR detection
bash .claude/tests/coordinate-refactoring/benchmark-claude-project-dir.sh

# Expected output:
# Baseline: 600ms (12 × git rev-parse)
# Optimized: 215ms (1 × git rev-parse + 11 × state load)
# Improvement: 385ms (64% reduction)
```

**Expected Duration**: 30 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Initialization block saves CLAUDE_PROJECT_DIR to state
- [ ] Bootstrap function removes redundant detection (relies on state load)
- [ ] Defensive validation added (fail-fast if missing)
- [ ] Benchmark shows 385ms improvement (64% reduction)
- [ ] Integration test passes (variable available in all blocks)
- [ ] Git commit created: `perf(644): optimize CLAUDE_PROJECT_DIR caching via state persistence`

---

<!-- PROGRESS CHECKPOINT -->
After completing Phases 0-4:
- [ ] Update this plan file: Mark completed phases with [x]
- [ ] Verify cumulative savings: 352 lines removed + 385ms improvement
- [ ] Run full test suite (verify no regressions)
- [ ] Review git commits (4 commits for phases 1-4)
<!-- END PROGRESS CHECKPOINT -->

---

### Phase 5: Extract Unified Verification Pattern
dependencies: [4]

**Objective**: Create generic verification function consolidating 30-40 lines × 10 blocks = 300-400 lines

**Complexity**: High

**Tasks**:
- [ ] Open `.claude/lib/verification-helpers.sh` for editing
- [ ] Implement `verify_phase_artifacts(phase_name, phase_abbrev, files...)` function (~60 lines)
  - Accept array of expected file paths
  - Loop over files, call `verify_file_created()` for each
  - Track successful/failed paths
  - Calculate file sizes for diagnostics
  - Save verification metrics to workflow state
  - Emit verification summary
  - Fail-fast via `handle_state_error()` on any failure
  - Return successful paths array for caller
- [ ] Handle variant patterns:
  - Multiple files: Loop over array
  - Single file: Single-element array
  - Hierarchical supervision: Special case for supervisor checkpoint parsing
- [ ] Create comprehensive unit tests (file: `.claude/tests/test_verification_helpers.sh`)
  - Test 1: Single file verification (planning phase pattern)
  - Test 2: Multiple files verification (research phase pattern)
  - Test 3: Failed verification (missing file)
  - Test 4: Hierarchical supervision variant
  - Test 5: File size calculation accuracy
  - Test 6: State persistence of verification metrics
- [ ] Update research verification block (lines 527-580) to use generic function
  - Before: 54 lines
  - After: 3-5 lines (function call + result capture)
- [ ] Update planning verification block (lines 790-833) to use generic function
- [ ] Update debug verification block to use generic function
- [ ] Update remaining 7 verification blocks (state persistence, hierarchical research, etc.)
- [ ] Integration test: Run full coordinate workflow (verify all verifications pass)

**Testing**:
```bash
# Unit tests for verification function
bash .claude/tests/test_verification_helpers.sh

# Integration test: Full workflow with verification checkpoints
# (Verify Standard 0 compliance: 100% file creation reliability)
```

**Expected Duration**: 4-6 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Generic verification function implemented (~60 lines)
- [ ] Unit tests passing (6 test cases, handle all variants)
- [ ] All 10 verification blocks updated to use generic function
- [ ] 310 lines removed from coordinate.md (30-40 lines × 10 blocks)
- [ ] Integration test passes (100% file creation reliability maintained)
- [ ] Standard 0 compliance verified (mandatory verification checkpoints)
- [ ] Git commit created: `refactor(644): extract unified verification pattern to library`

---

### Phase 6: Implement Lazy Library Loading
dependencies: [5]

**Objective**: Create phase-specific library bundles reducing sourcing overhead from 63-99 to 18-27 operations

**Complexity**: Medium

**Tasks**:
- [ ] Analyze library dependencies per workflow phase (file: `.claude/tests/coordinate-refactoring/library-dependency-analysis.md`)
  - Research phase: Required libraries (workflow-state-machine, state-persistence, etc.)
  - Planning phase: Required libraries
  - Implementation phase: Required libraries
  - Testing phase: Required libraries
  - Debug phase: Required libraries
  - Documentation phase: Required libraries
- [ ] Create library manifests (file: `.claude/lib/library-manifests/`)
  - `research-manifest.txt`: List of libraries for research phase
  - `planning-manifest.txt`: List for planning phase
  - `implementation-manifest.txt`: List for implementation phase
- [ ] Create phase-specific bundle loader (file: `.claude/lib/library-sourcing.sh` - extend)
  - Function: `source_phase_libraries(phase_name)`
  - Reads manifest for phase
  - Sources only required libraries
  - Skips already-sourced libraries (via source guards)
- [ ] Update bootstrap function to accept optional phase parameter
  - `bootstrap_state_handler(expected_state, workflow_id_file, phase_name)`
  - Calls `source_phase_libraries(phase_name)` instead of sourcing all libraries
- [ ] Update all 11 bash blocks to specify phase in bootstrap call
  - Example: `bootstrap_state_handler "$STATE_RESEARCH" "" "research"`
- [ ] Benchmark performance improvement (file: `.claude/tests/coordinate-refactoring/benchmark-library-loading.sh`)
  - Current: 63-99 sourcing operations (450-720ms)
  - Expected: 18-27 sourcing operations (120-220ms)
  - Target: 300-500ms improvement (60-70% reduction)
- [ ] Integration test: Verify all workflow phases execute successfully

**Testing**:
```bash
# Benchmark library loading performance
bash .claude/tests/coordinate-refactoring/benchmark-library-loading.sh

# Expected output:
# Baseline: 63 sourcing operations (450ms)
# Optimized: 18 sourcing operations (120ms)
# Improvement: 330ms (73% reduction)
```

**Expected Duration**: 4-5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Library dependency analysis documented (6 phase manifests)
- [ ] Phase-specific bundle loader implemented
- [ ] Bootstrap function updated to accept phase parameter
- [ ] All 11 blocks specify phase in bootstrap call
- [ ] Benchmark shows 300-500ms improvement (60-70% reduction)
- [ ] Integration test passes (all phases execute with phase-specific libraries)
- [ ] Git commit created: `perf(644): implement lazy library loading for phase-specific bundles`

---

### Phase 7: Extract Checkpoint Emission Pattern
dependencies: [6]

**Objective**: Create generic checkpoint function consolidating 20-30 lines × 6 blocks = 120-180 lines

**Complexity**: Medium

**Tasks**:
- [ ] Create new library file: `.claude/lib/checkpoint-helpers.sh`
- [ ] Implement `emit_phase_checkpoint(phase_name, checkpoint_data)` function (~50 lines)
  - Accept phase name and associative array of checkpoint data
  - Emit box-drawing header with phase name
  - Display artifacts created section (configurable lines)
  - Display verification status section (configurable lines)
  - Display phase-specific metrics section (configurable lines)
  - Display next action section (workflow scope dependent)
  - Emit box-drawing footer
  - Handle associative array parameter passing via `declare -n`
- [ ] Create unit tests (file: `.claude/tests/test_checkpoint_helpers.sh`)
  - Test 1: Checkpoint with all sections populated
  - Test 2: Checkpoint with minimal sections
  - Test 3: Workflow scope branching (research-only, full-implementation, etc.)
  - Test 4: Associative array parameter passing
- [ ] Update research checkpoint block (lines 585-639) to use generic function
  - Before: 55 lines
  - After: 5-10 lines (declare checkpoint data + function call)
- [ ] Update planning checkpoint block to use generic function
- [ ] Update remaining 4 checkpoint blocks (implementation, testing, debug, documentation)
- [ ] Integration test: Verify checkpoint output matches expected format

**Testing**:
```bash
# Unit tests for checkpoint function
bash .claude/tests/test_checkpoint_helpers.sh

# Integration test: Verify checkpoint output
# (Check terminal output matches expected box-drawing format)
```

**Expected Duration**: 3-4 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Checkpoint helpers library created (~50 lines)
- [ ] Generic checkpoint function implemented
- [ ] Unit tests passing (4 test cases, handle associative arrays)
- [ ] All 6 checkpoint blocks updated to use generic function
- [ ] 105 lines removed from coordinate.md (20-30 lines × 6 blocks)
- [ ] Integration test passes (checkpoint output format correct)
- [ ] Git commit created: `refactor(644): extract checkpoint emission pattern to library`

---

<!-- PROGRESS CHECKPOINT -->
After completing Phases 5-7:
- [ ] Update this plan file: Mark completed phases with [x]
- [ ] Verify cumulative savings: 767 lines removed + 685-900ms improvement
- [ ] Run full test suite (verify 127 state machine tests passing)
- [ ] Calculate final metrics:
  - File size: 1,503 → ~736 lines (51% reduction)
  - Boilerplate: 55.4% → ~20%
  - Overhead: 1,298ms → ~398-604ms (44-58% improvement)
- [ ] Review git commits (7 commits total for all phases)
<!-- END PROGRESS CHECKPOINT -->

---

### Phase 8: Final Validation and Documentation
dependencies: [7]

**Objective**: Comprehensive testing, documentation updates, and metric validation

**Complexity**: Medium

**Tasks**:
- [ ] Run comprehensive test suite (command: `.claude/tests/run_all_tests.sh`)
  - Verify 127 state machine tests passing (100%)
  - Verify subprocess isolation tests passing (100%)
  - Verify all new unit tests passing (bootstrap, verification, checkpoint)
  - Verify integration tests passing (full workflow execution)
- [ ] Calculate final metrics (file: `.claude/tests/coordinate-refactoring/final-metrics.md`)
  - File size: Baseline (1,503) → Final (~736 lines)
  - Reduction: Target 51% (767 lines)
  - Boilerplate: Baseline (55.4%) → Final (~20%)
  - Performance: Baseline (1,298ms) → Final (~398-604ms)
  - Improvement: Target 44-58% (694-900ms)
- [ ] Validate all success criteria met (review list from plan header)
  - [ ] P0 bug fixed (verification patterns corrected)
  - [ ] 51% code reduction achieved
  - [ ] 44-58% performance improvement achieved
  - [ ] 100% file creation reliability maintained
  - [ ] 100% unit test coverage for library functions
  - [ ] All 127 state machine tests passing
- [ ] Update coordinate-state-management.md (file: `.claude/docs/architecture/coordinate-state-management.md`)
  - Document new bootstrap function usage
  - Document lazy library loading pattern
  - Document verification pattern consolidation
  - Document checkpoint pattern consolidation
  - Add performance benchmarks (before/after metrics)
- [ ] Update bash-block-execution-model.md (file: `.claude/docs/concepts/bash-block-execution-model.md`)
  - Add consolidated patterns section
  - Document bootstrap function as validated pattern
  - Add best practices for boilerplate consolidation
- [ ] Create migration guide for other orchestrators (file: `.claude/docs/guides/orchestrator-consolidation-guide.md`)
  - How to apply same patterns to /orchestrate and /supervise
  - Before/after code examples
  - Testing checklist
  - Migration sequence
- [ ] Update CLAUDE.md coordinate command section (file: `/home/benjamin/.config/CLAUDE.md`)
  - Update line count metrics (1,503 → ~736)
  - Update performance characteristics
  - Add reference to consolidation patterns
- [ ] Create refactoring summary (file: `.claude/specs/644_current_command_implementation_identify/summaries/001_coordinate_refactoring_summary.md`)
  - Baseline vs final metrics
  - All changes made (7 git commits)
  - Test results (100% pass rate maintained)
  - Performance improvements (detailed breakdown)
  - Lessons learned
  - Recommendations for future refactoring

**Testing**:
```bash
# Final comprehensive test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh | tee coordinate-refactoring/final-test-results.txt

# Compare baseline vs final
diff coordinate-refactoring/baseline-test-results.txt \
     coordinate-refactoring/final-test-results.txt

# Verify no regressions (same tests passing)
```

**Expected Duration**: 3-4 hours

**Phase 8 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Comprehensive test suite passing (127 state machine tests, 100%)
- [ ] Final metrics documented (51% reduction, 44-58% improvement achieved)
- [ ] All success criteria validated (12 criteria met)
- [ ] Documentation updated (4 files: architecture, concepts, guides, CLAUDE.md)
- [ ] Refactoring summary created (comprehensive report)
- [ ] Migration guide created (for other orchestrators)
- [ ] Git commit created: `docs(644): document coordinate refactoring results and patterns`

---

## Testing Strategy

### Unit Testing Approach

**Test Coverage Requirements**:
- 100% coverage for all new library functions
- 100% coverage for all refactored patterns
- Regression tests for all bug fixes
- Integration tests for workflow execution

**Test Files**:
1. `.claude/tests/test_state_machine_bootstrap.sh` - Bootstrap function tests (5 test cases)
2. `.claude/tests/test_verification_helpers.sh` - Verification pattern tests (6 test cases)
3. `.claude/tests/test_checkpoint_helpers.sh` - Checkpoint pattern tests (4 test cases)
4. `.claude/tests/coordinate-refactoring/test_verification_bug.sh` - P0 bug fix verification (3 test cases)
5. `.claude/tests/coordinate-refactoring/test_file_creation_reliability.sh` - Integration test (Standard 0 compliance)

**Test Execution**:
```bash
# Run all unit tests
bash .claude/tests/test_state_machine_bootstrap.sh
bash .claude/tests/test_verification_helpers.sh
bash .claude/tests/test_checkpoint_helpers.sh

# Run refactoring-specific tests
bash .claude/tests/coordinate-refactoring/test_verification_bug.sh
bash .claude/tests/coordinate-refactoring/test_file_creation_reliability.sh

# Run comprehensive test suite
.claude/tests/run_all_tests.sh
```

### Performance Benchmarking

**Benchmark Tests**:
1. Library loading performance (baseline vs lazy loading)
2. CLAUDE_PROJECT_DIR detection performance (baseline vs caching)
3. Overall workflow overhead (baseline vs optimized)

**Benchmark Files**:
- `.claude/tests/coordinate-refactoring/benchmark-library-loading.sh`
- `.claude/tests/coordinate-refactoring/benchmark-claude-project-dir.sh`
- `.claude/tests/coordinate-refactoring/benchmark-workflow-overhead.sh`

**Expected Results**:
- Library loading: 450-720ms → 120-220ms (60-70% improvement)
- CLAUDE_PROJECT_DIR: 600ms → 215ms (64% improvement)
- Total overhead: 1,298ms → 398-604ms (44-58% improvement)

### Regression Testing

**Critical Regression Checks**:
1. All 127 state machine tests passing (100% pass rate)
2. All subprocess isolation tests passing (100% pass rate)
3. 100% file creation reliability maintained (Standard 0 compliance)
4. All workflow scopes execute correctly (research-only, research-and-plan, full-implementation, debug-only)
5. Wave-based parallel execution works (40-60% time savings preserved)
6. Hierarchical coordination works (95% context reduction preserved)

**Regression Test Commands**:
```bash
# State machine tests
bash .claude/tests/test_state_machine.sh

# Subprocess isolation tests
bash .claude/tests/test_bash_block_isolation.sh

# File creation reliability
bash .claude/tests/coordinate-refactoring/test_file_creation_reliability.sh

# Full workflow execution
# (Run coordinate command with test workflow, verify all phases complete)
```

### Integration Testing

**Integration Test Scenarios**:
1. Full workflow (research → plan → implement → test → document → complete)
2. Research-only workflow (terminal at STATE_RESEARCH)
3. Research-and-plan workflow (terminal at STATE_PLAN)
4. Debug workflow (test failure → debug → test)
5. Hierarchical research (≥4 topics)
6. Flat research (<4 topics)

**Integration Test Execution**:
```bash
# Full workflow integration test
bash .claude/tests/coordinate-refactoring/test_full_workflow.sh

# Research-only integration test
bash .claude/tests/coordinate-refactoring/test_research_only_workflow.sh

# Hierarchical research integration test
bash .claude/tests/coordinate-refactoring/test_hierarchical_research.sh
```

## Documentation Requirements

### Updated Documentation Files

1. **State Management Architecture** (`.claude/docs/architecture/coordinate-state-management.md`)
   - Add section: "Consolidated Boilerplate Patterns"
   - Document bootstrap function usage pattern
   - Document lazy library loading pattern
   - Add before/after performance metrics
   - Add code examples for new patterns

2. **Bash Block Execution Model** (`.claude/docs/concepts/bash-block-execution-model.md`)
   - Add section: "Boilerplate Consolidation Best Practices"
   - Document bootstrap function as validated pattern
   - Document trade-offs (readability vs indirection)
   - Add anti-pattern: Duplicating boilerplate across blocks

3. **Verification Helpers Documentation** (`.claude/lib/verification-helpers.sh` - inline comments)
   - Add comprehensive function documentation
   - Document all parameters and return values
   - Add usage examples
   - Document Standard 0 compliance

4. **CLAUDE.md Updates** (`/home/benjamin/.config/CLAUDE.md`)
   - Update coordinate command metrics (line count, performance)
   - Add reference to consolidation patterns
   - Update performance characteristics section

### New Documentation Files

1. **Orchestrator Consolidation Guide** (`.claude/docs/guides/orchestrator-consolidation-guide.md`)
   - How to apply same patterns to /orchestrate and /supervise
   - Step-by-step migration instructions
   - Before/after code examples for each pattern
   - Testing checklist for validation
   - Common pitfalls and troubleshooting

2. **Refactoring Summary** (`.claude/specs/644_current_command_implementation_identify/summaries/001_coordinate_refactoring_summary.md`)
   - Executive summary (baseline → final metrics)
   - All changes made (7 git commits with details)
   - Test results summary (100% pass rate maintained)
   - Performance improvements (detailed breakdown)
   - Lessons learned
   - Recommendations for future work

3. **State Handler Patterns Guide** (`.claude/docs/guides/state-handler-patterns.md`)
   - Bootstrap pattern documentation
   - Verification pattern examples
   - Checkpoint emission examples
   - Best practices for state handlers
   - Common mistakes to avoid

## Dependencies

### External Dependencies
- None (all work within existing .claude/ infrastructure)

### Library Dependencies
- `.claude/lib/workflow-state-machine.sh` (existing, extend with wrapper)
- `.claude/lib/state-persistence.sh` (existing, use for caching)
- `.claude/lib/verification-helpers.sh` (existing, extend with generic function)
- `.claude/lib/library-sourcing.sh` (existing, extend with lazy loading)

### Testing Dependencies
- `.claude/tests/run_all_tests.sh` (existing test runner)
- Bash 4.0+ (for associative arrays in checkpoint pattern)
- Standard Unix utilities (grep, sed, awk, stat)

## Risk Assessment

### High-Risk Changes

**Risk 1: Bootstrap Function Breaks State Loading**
- **Likelihood**: Low
- **Impact**: High (workflow fails to execute)
- **Mitigation**: Comprehensive unit tests, integration tests, rollback checkpoint
- **Rollback**: Restore coordinate.md from backup, revert library files

**Risk 2: Verification Pattern Misses Edge Cases**
- **Likelihood**: Medium
- **Impact**: High (silent failures, violates Standard 0)
- **Mitigation**: Test all variants (single file, multiple files, hierarchical), regression tests
- **Rollback**: Restore inline verification blocks from backup

**Risk 3: Performance Regression from Function Call Overhead**
- **Likelihood**: Low
- **Impact**: Medium (workflow slower despite optimizations)
- **Mitigation**: Benchmark before/after, profile hot paths
- **Rollback**: Revert lazy loading, keep other optimizations

### Medium-Risk Changes

**Risk 4: Lazy Loading Breaks Phase-Specific Functionality**
- **Likelihood**: Medium
- **Impact**: Medium (phase fails due to missing library)
- **Mitigation**: Comprehensive dependency analysis, integration tests per phase
- **Rollback**: Revert to loading all libraries in every block

**Risk 5: Checkpoint Pattern Doesn't Handle Associative Arrays**
- **Likelihood**: Medium (Bash array limitations)
- **Impact**: Low (checkpoint output only, doesn't affect execution)
- **Mitigation**: Use `declare -n` for reference passing, test thoroughly
- **Rollback**: Keep inline checkpoint blocks

### Low-Risk Changes

**Risk 6: Documentation Becomes Stale**
- **Likelihood**: Low (comprehensive documentation updates in Phase 8)
- **Impact**: Low (confusion for future developers)
- **Mitigation**: Document all patterns, provide migration guide
- **Rollback**: Update documentation separately

**Risk 7: State Transition Wrapper Validation Fails**
- **Likelihood**: Low (simple wrapper, existing functions validated)
- **Impact**: Low (easy to revert)
- **Mitigation**: Unit tests for wrapper
- **Rollback**: Use 2-line pattern instead of wrapper

## Rollback Plan

### Rollback Checkpoints

**Checkpoint 1: After Phase 0 (Baseline)**
- Full backup of coordinate.md with timestamp
- Baseline test results captured
- Rollback command: `cp coordinate.md.backup-TIMESTAMP coordinate.md`

**Checkpoint 2: After Phase 4 (Quick Wins Complete)**
- Git tag: `refactor-644-phase-4-complete`
- Rollback command: `git reset --hard refactor-644-phase-4-complete`

**Checkpoint 3: After Phase 7 (All Patterns Consolidated)**
- Git tag: `refactor-644-phase-7-complete`
- Rollback command: `git reset --hard refactor-644-phase-7-complete`

### Rollback Criteria

**Trigger rollback if**:
- File creation reliability drops below 100%
- State machine tests pass rate drops below 95%
- Workflow execution fails in integration tests
- Performance regresses (execution time increases >10%)
- User-reported workflow failures

### Rollback Procedure

1. **Identify rollback point** (Phase 4, Phase 7, or full revert)
2. **Execute rollback command** (git reset or file restore)
3. **Re-run test suite** (verify baseline tests pass)
4. **Document failure** (create diagnostic report)
5. **Analyze root cause** (debug before next attempt)
6. **Update plan** (adjust approach based on learnings)

## Success Metrics

### Quantitative Metrics

| Metric | Baseline | Target | Achievement Criteria |
|--------|----------|--------|---------------------|
| File size | 1,503 lines | ~736 lines | 51% reduction (767 lines) |
| Boilerplate % | 55.4% | ~20% | 35% reduction in boilerplate ratio |
| Workflow overhead | 1,298ms | 398-604ms | 694-900ms improvement (44-58%) |
| Library loading | 450-720ms | 120-220ms | 300-500ms improvement (60-70%) |
| CLAUDE_PROJECT_DIR | 600ms | 215ms | 385ms improvement (64%) |
| Context usage | 15,600 tokens | 7,800 tokens | 50% reduction (7,800 tokens freed) |
| Unit test coverage | N/A | 100% | All library functions tested |
| State machine tests | 127 passing | 127 passing | 100% pass rate maintained |
| File creation reliability | 100% | 100% | Zero regression |

### Qualitative Metrics

| Metric | Baseline | Target | Achievement Criteria |
|--------|----------|--------|---------------------|
| Bug fix effort | 11 edits | 1 edit | 91% reduction (single source of truth) |
| Code review burden | 363 lines | 72 lines | 94% reduction (boilerplate → function calls) |
| Onboarding time | 85-115 min | 45-75 min | 47% reduction (40-minute savings) |
| Divergence risk | Medium | Zero | Single library function, no duplication |
| Testability | Low | High | Unit testable library functions |
| Maintainability | Medium | High | Centralized patterns, clear abstractions |

## Lessons Learned (Post-Implementation)

This section will be populated after Phase 8 completion with key learnings from the refactoring process:

- What worked well
- What didn't work as expected
- Unexpected challenges
- Performance surprises
- Testing insights
- Recommendations for future refactoring

---

**Plan Created**: 2025-11-10
**Estimated Completion**: 22-28 hours across 3 sprints
**Target File Size**: 736 lines (51% reduction from 1,503)
**Target Performance**: 398-604ms overhead (44-58% improvement from 1,298ms)
**Target Context**: 7,800 tokens freed (50% reduction in agent overhead)
