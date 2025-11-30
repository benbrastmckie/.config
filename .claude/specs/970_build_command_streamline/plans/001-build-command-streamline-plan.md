# Build Command Streamlining Implementation Plan

## Metadata
- **Date**: 2025-11-29 (Revised)
- **Feature**: /build command streamlining and standards compliance
- **Scope**: Consolidate bash blocks, inline verifications, improve code quality—preserve ALL functionality
- **Estimated Phases**: 4
- **Estimated Hours**: 10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 78.0
- **Research Reports**:
  - [Build Command Analysis](/home/benjamin/.config/.claude/specs/970_build_command_streamline/reports/001-build-command-analysis.md)
  - [Build Streamline Revision](/home/benjamin/.config/.claude/specs/970_build_command_streamline/reports/002-build-streamline-revision.md)

## Overview

The /build command currently uses 8 bash blocks (2,088 lines total) with verification checkpoints that can be inlined. This plan focuses on streamlining WITHOUT limiting functionality: consolidate blocks through inline verification (8→4-5 blocks), fix standards compliance gaps (linter warnings), and improve code quality (verbosity reduction, comment cleanup). ALL existing functionality preserved—no iteration loop removal, no state machine changes, no architecture modifications.

**Key Streamlining Targets**:
- Reduce bash blocks: 8 → 4-5 (37-50% reduction in subprocess overhead)
- Inline verification blocks (eliminate subprocess boundaries)
- Fix standards compliance gaps (linter warnings for defensive checks)
- Improve code quality (WHAT not WHY comments, verbosity reduction)
- Preserve 100% functionality (iteration support, error handling, state machine)

## Research Summary

Analysis of build.md (2,088 lines, 8 bash blocks) from research report 002-build-streamline-revision.md:

**Functionality-Preserving Opportunities**:
- **Block Consolidation (8→4-5)**: Inline verification blocks to eliminate subprocess boundaries. Block 1c (381 lines) verification can merge into Block 1b. Test parsing (Block 2) + conditional branching (Block 3) can merge. Result: 37-50% block reduction WITHOUT functionality loss.

- **Standards Compliance Gaps**: Linter warnings for missing defensive checks before append_workflow_state calls (lines 391-409). Fix: Add single type-check before each block of state persistence calls.

- **Code Quality Improvements**: Remove WHY comments (move to guides), keep WHAT comments per output-formatting.md:277-320. Consolidate related operations. Reduce verbosity without changing behavior.

**Functionality-Limiting Changes to AVOID** (per user constraint):
- ❌ Iteration loop removal: Necessary for large plans (10+ phases), context exhaustion handling, checkpoint resumption (real-world evidence from spec 965)
- ❌ State machine simplification: /build HAS branching (TEST → DEBUG/DOCUMENT), state machine appropriate
- ❌ Boilerplate reduction: Required by bash subprocess isolation model, CANNOT be removed

**Recommended Approach**: Focus on block consolidation, standards compliance fixes, and code quality improvements—preserve ALL infrastructure (iteration, state machine, error handling).

## Success Criteria

- [ ] Bash block count reduced from 8 to 4-5 blocks (37-50% reduction)
- [ ] Block 1c verification logic (381 lines) successfully inlined into Block 1b
- [ ] Test parsing (Block 2) + conditional branching (Block 3) merged into single block
- [ ] Standards compliance gaps fixed (linter warnings for defensive checks)
- [ ] Code quality improved (WHAT not WHY comments, verbosity reduction)
- [ ] ALL existing functionality preserved (iteration loop, state machine, error handling)
- [ ] All tests pass (integration, state transitions, task delegation)
- [ ] Performance improvement measurable (subprocess spawn reduction)
- [ ] No functionality regressions (large plans, checkpoint resumption, test branching)
- [ ] Documentation updated with streamlining rationale

## Technical Design

### Block Consolidation Architecture

**Current Structure (8 Blocks)**:
1. Block 1a: Setup (sourcing, argument parsing, state init)
2. Block 1b: Execute (implementer-coordinator Task invocation)
3. Block 1c: Verify (381 lines of verification after agent completes)
4. Task: spec-updater invocation
5. Task: test-executor invocation
6. Block 2: Parse (test result parsing, 254 lines)
7. Block 3: Branch (conditional debug/document decision, 174 lines)
8. Block 4: Complete (final summary, state transition)

**Target Structure (4-5 Blocks)** - Task blocks don't count as bash blocks:

1. **Block 1: Setup + Execute + Verify** (merge 1a + 1b + inline 1c)
   - Bootstrap, library sourcing (preserve three-tier pattern)
   - Argument parsing, auto-resume (preserve iteration support)
   - State machine initialization (preserve)
   - implementer-coordinator Task invocation (preserve)
   - **INLINE verification** (NEW—merge Block 1c immediately after Task)
   - State persistence for next block

2. **Task: spec-updater** (keep separate—Task blocks distinct)

3. **Task: test-executor** (keep separate—Task blocks distinct)

4. **Block 2: Parse + Branch** (merge current Block 2 + Block 3)
   - State loading (preserve)
   - **INLINE test result parsing** (merge 254 lines from Block 2)
   - **INLINE conditional branching** (merge 174 lines from Block 3)
   - Conditional debug-analyst Task OR document marker
   - State persistence for next block

5. **Block 3: Completion** (Block 4 unchanged)
   - State loading, final summary, artifacts, state transition

**Result**: 8 blocks → 4-5 blocks (37-50% reduction), ALL functionality preserved

### Inline Verification Pattern

**Current Anti-Pattern**:
```bash
# Block 1b: Invoke agent
Task { ... }

# === BASH BLOCK BOUNDARY (subprocess spawn) ===

# Block 1c: Verify agent output (381 lines)
if [ ! -d "$SUMMARIES_DIR" ]; then
  echo "ERROR: VERIFICATION FAILED"
  exit 1
fi
```

**Optimized Pattern**:
```bash
# Block 1: Setup + Execute + Verify (consolidated)
Task { ... }

# IMMEDIATE verification (no subprocess boundary)
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)
if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
  log_command_error "verification_error" \
    "Implementer-coordinator failed to create summary" \
    "Expected summary in $SUMMARIES_DIR"
  exit 1
fi

# Continue with state persistence
append_workflow_state "LATEST_SUMMARY" "$LATEST_SUMMARY"
```

**Benefit**: Eliminates subprocess overhead, aligns with Verification and Fallback Pattern standards

### Standards Compliance Fixes

**Current Linter Warnings**: Missing defensive type-checks before append_workflow_state calls

**Fix Pattern**:
```bash
# Add before first append_workflow_state in each block:
type append_workflow_state &>/dev/null || {
  echo "ERROR: append_workflow_state function not found" >&2
  exit 1
}
# ... then all append_workflow_state calls
```

**Locations**:
- build.md:391 (Block 1a state persistence)
- build.md:1474 (Block 2 state persistence)
- build.md:1656 (Block 3 state persistence)

**Benefit**: Fixes linter warnings, improves error diagnostics, NO functional change

### Code Quality Improvements

**WHAT not WHY Comment Standard** (output-formatting.md:277-320):
- Remove: "# We source this here because subprocess isolation requires..."
- Keep: "# Load state management functions"
- Move design rationale to build-command-guide.md

**Verbosity Reduction**:
- Consolidate related error handling operations
- Batch related append_workflow_state calls
- Remove redundant validation where function availability confirmed

**Benefit**: Cleaner code, reduced line count, no functionality loss

### Infrastructure Preservation (NON-NEGOTIABLE)

**MUST Preserve ALL of**:
- **Iteration loop infrastructure**: 5 state variables (MAX_ITERATIONS, ITERATION, CONTINUATION_CONTEXT, LAST_WORK_REMAINING, STUCK_COUNT), checkpoint v2.1 schema, context estimation function (234 lines), stuck detection—necessary for large plans (10+ phases)
- **State machine**: Full state machine appropriate for /build's branching workflow (TEST → DEBUG/DOCUMENT conditional)
- **Error handling patterns**: Three-tier sourcing, early error buffer, bash error traps, log_command_error integration, fail-fast handlers
- **Boilerplate per block**: Project detection, library sourcing, state loading, trap setup—REQUIRED by bash subprocess isolation model

**Rationale**: These are NOT streamlining opportunities—they are required infrastructure. Removing them would limit functionality (violates user constraint "improve WITHOUT limiting functionality").

## Implementation Phases

### Phase 1: Consolidate Implementation Blocks (Setup + Execute + Verify) [NOT STARTED]
dependencies: []

**Objective**: Merge Block 1a (setup), Block 1b (execute), and Block 1c (verify) into single bash block with inline verification—reduce 3 blocks to 1

**Complexity**: Medium

**Tasks**:
- [ ] Create backup: `cp .claude/commands/build.md .claude/commands/build.md.backup.$(date +%Y%m%d_%H%M%S)`
- [ ] Identify Block 1c verification logic (lines 494-875, 381 lines)
- [ ] Merge Block 1a + 1b (setup + execute already sequential)
- [ ] Inline Block 1c verification immediately after implementer-coordinator Task invocation
- [ ] Preserve ALL error handling (three-tier sourcing, error traps, logging)
- [ ] Preserve ALL iteration infrastructure (MAX_ITERATIONS, checkpoint logic, context estimation)
- [ ] Preserve state persistence at end of consolidated block
- [ ] Remove standalone Block 1c (eliminate subprocess boundary)
- [ ] Syntax validation: `bash -n .claude/commands/build.md`
- [ ] Test basic execution with sample plan

**Testing**:
```bash
# Syntax check
bash -n .claude/commands/build.md

# Execution test (preserve iteration support)
/build .claude/specs/970_build_command_streamline/plans/001-build-command-streamline-plan.md 1

# Verify verification logic runs (should catch missing summary)
/build /tmp/fake-plan.md 2>&1 | grep "VERIFICATION FAILED"

# Verify iteration variables still tracked
cat ~/.claude/tmp/workflow_state_*.txt | grep "ITERATION"
```

**Expected Duration**: 3 hours

### Phase 2: Consolidate Test Blocks (Parse + Branch) [NOT STARTED]
dependencies: [1]

**Objective**: Merge test result parsing (Block 2) + conditional branching (Block 3) into single bash block—reduce 2 blocks to 1

**Complexity**: Medium

**Tasks**:
- [ ] Identify test parsing logic (Block 2, lines 1249-1503, 254 lines)
- [ ] Identify conditional branching logic (Block 3, lines 1506-1680, 174 lines)
- [ ] Inline parsing immediately after test-executor Task completes
- [ ] Inline conditional logic (if tests failed: debug-analyst Task; else: document marker)
- [ ] Preserve state machine transitions (TEST → DEBUG/DOCUMENT)
- [ ] Preserve ALL error logging for test failures
- [ ] Preserve state persistence before completion block
- [ ] Remove standalone Block 2 and Block 3 (eliminate subprocess boundary)
- [ ] Syntax validation: `bash -n .claude/commands/build.md`
- [ ] Test both branches (failing tests, passing tests)

**Testing**:
```bash
# Syntax check
bash -n .claude/commands/build.md

# Test failing tests path (should invoke debug-analyst)
# Create plan with intentionally failing tests, run /build

# Test passing tests path (should skip to document)
# Create plan with passing tests, run /build

# Verify state transitions preserved
cat ~/.claude/tmp/workflow_state_*.txt | grep "CURRENT_STATE" | grep -E "TEST|DEBUG|DOCUMENT"

# Verify state machine still tracks completed states
cat ~/.claude/tmp/workflow_state_*.txt | grep "COMPLETED_STATES"
```

**Expected Duration**: 3 hours

### Phase 3: Fix Standards Compliance Gaps [NOT STARTED]
dependencies: [1, 2]

**Objective**: Add defensive type-checks before append_workflow_state blocks to fix linter warnings

**Complexity**: Low

**Tasks**:
- [ ] Identify all append_workflow_state call blocks (lines 391-409, 1474, 1656)
- [ ] Add defensive type-check before first call in each block:
  ```bash
  type append_workflow_state &>/dev/null || {
    echo "ERROR: append_workflow_state function not found" >&2
    exit 1
  }
  ```
- [ ] Run linter to verify warnings fixed: `.claude/scripts/check-library-sourcing.sh .claude/commands/build.md`
- [ ] Verify no functional change (error handling improved, behavior same)
- [ ] Test that error message appears if library sourcing fails

**Testing**:
```bash
# Linter check (should pass)
bash .claude/scripts/check-library-sourcing.sh .claude/commands/build.md

# Verify defensive check works (simulate library failure)
# Temporarily comment out state-persistence.sh sourcing, run /build
# Should see "ERROR: append_workflow_state function not found"

# Normal execution still works
/build <sample-plan>
```

**Expected Duration**: 2 hours

### Phase 4: Code Quality Improvements [NOT STARTED]
dependencies: [3]

**Objective**: Remove WHY comments (keep WHAT), reduce verbosity, consolidate operations—no functional changes

**Complexity**: Low

**Tasks**:
- [ ] Identify WHY comments (explain design rationale): grep -n "# We .* because" build.md
- [ ] Remove WHY comments, keep WHAT comments (describe code action)
- [ ] Move design rationale to .claude/docs/guides/commands/build-command-guide.md
- [ ] Consolidate related operations (batch similar checks)
- [ ] Remove redundant validation where function availability already confirmed
- [ ] Verify line count reduction (target: 10-15% reduction)
- [ ] Syntax validation: `bash -n .claude/commands/build.md`

**Testing**:
```bash
# Syntax check
bash -n .claude/commands/build.md

# Line count comparison
wc -l build.md.backup.* build.md

# Functionality unchanged
/build <sample-plan>

# Verify all tests still pass
bash .claude/tests/integration/test_build_iteration.sh
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Verify each consolidated block parses correctly (bash -n)
- Test inline verification logic catches agent failures
- Test inline parsing/branching handles both paths (failing/passing tests)
- Test defensive type-checks trigger on library failure

### Integration Testing
- Run existing build integration test suite (test_build_iteration.sh)
- Run state transition test suite (test_build_state_transitions.sh)
- Run task delegation test suite (test_build_task_delegation.sh)
- ALL tests must pass (no functionality regressions)

### Performance Testing
- Measure subprocess spawn count before/after consolidation
- Measure execution time for sample plans (small, medium, large)
- Verify bash block count reduction (8 → 4-5 blocks)
- No state file size regression (iteration vars preserved)

### Regression Testing
- Test error handling still captures failures (missing plans, invalid args)
- Test test failures trigger debug-analyst correctly
- Test iteration loop still supports large plans (10+ phases)
- Test checkpoint resumption workflow (--resume flag)
- Test all command flags (--dry-run, --resume, --max-iterations)
- Test context exhaustion handling (estimate_context_usage preserved)

### Edge Cases
- Empty plan files
- Plans with no phases
- Plans with failing tests
- Plans requiring multiple iterations (verify auto-iteration preserved)
- Invalid checkpoint paths for --resume
- Library sourcing failures (verify defensive checks work)

## Documentation Requirements

### Updated Documentation
- `.claude/docs/guides/commands/build-command-guide.md` - Update with:
  - Block consolidation approach (8 → 4-5 blocks)
  - Inline verification pattern explanation
  - Performance characteristics (subprocess reduction)
  - Preserved functionality (iteration, state machine, error handling)

### Code Comments
- Add WHAT comments for inline verification logic
- Add WHAT comments for inline parsing/branching logic
- Remove WHY comments (move design rationale to guide)
- Reference build-command-guide.md for architecture rationale

### Rollback Documentation
- Document backup location: `.claude/commands/build.md.backup.YYYYMMDD_HHMMSS`
- Document rollback procedure: `cp build.md.backup.* build.md`
- Document validation after rollback: `bash -n build.md && /build <test-plan>`

## Dependencies

### External Dependencies
- Bash 4.0+ (for associative arrays in state persistence)
- grep, find, wc (standard Unix utilities)
- git (for project directory detection)

### Internal Dependencies
- `.claude/lib/core/state-persistence.sh` v1.5.0+ (cross-block state management)
- `.claude/lib/workflow/workflow-state-machine.sh` v2.0.0+ (state tracking)
- `.claude/lib/core/error-handling.sh` (centralized error logging)
- `.claude/agents/implementer-coordinator.md` (wave orchestration, internal checkpoints)
- `.claude/agents/test-executor.md` (test phase execution)
- `.claude/agents/debug-analyst.md` (conditional debug phase)

### Standards Dependencies
- Output Formatting Standards (2-3 bash block target—guideline, not requirement)
- Code Standards (three-tier sourcing, error handling patterns, WHAT not WHY comments)
- Bash Block Execution Model (subprocess isolation, state persistence)
- Error Handling Pattern (error traps, logging integration, defensive checks)

### Test Dependencies
- `.claude/tests/integration/test_build_iteration.sh` (iteration loop tests—MUST pass)
- `.claude/tests/state/test_build_state_transitions.sh` (state machine tests—MUST pass)
- `.claude/tests/commands/test_build_task_delegation.sh` (task coordination tests—MUST pass)

## Risk Management

### Technical Risks
1. **Block consolidation breaks state persistence**: Mitigated by preserving ALL append_workflow_state calls at block boundaries
2. **Inline verification misses edge cases**: Mitigated by comprehensive testing of agent failure scenarios
3. **Longer blocks harder to debug**: Mitigated by clear WHAT comments and section markers
4. **Defensive checks add verbosity**: Acceptable trade-off for improved error diagnostics

### Rollback Strategy
- Backup created in Phase 1: `build.md.backup.YYYYMMDD_HHMMSS`
- Rollback command: `cp build.md.backup.* build.md`
- All changes in single file (build.md)—no library changes
- Validation: `bash -n build.md && /build <test-plan>`
- Tests validate rollback restored functionality

### Performance Characteristics
- **Block reduction**: 8 → 4-5 blocks (37-50% subprocess reduction)
- **Longer individual blocks**: Still maintainable (<700 lines each)
- **No functionality loss**: ALL iteration, state machine, error handling preserved
- **Code quality improvement**: Linter compliance, verbosity reduction

## Notes

### Complexity Score Calculation

**Revised Plan** (functionality-preserving only):
```
score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
score = (29 × 1.0) + (4 × 5.0) + (10 × 0.5) + (10 × 2.0)
score = 29 + 20 + 5 + 20 = 74.0
```

**Adjusted for testing rigor** (no functionality regressions allowed):
```
score = (29 × 1.0) + (4 × 5.0) + (10 × 0.5) + (12 × 2.0)
score = 29 + 20 + 5 + 24 = 78.0
```

**Score**: 78.0 (Medium complexity, Level 0 structure appropriate)

### Scope Reduction Rationale

**Original Plan** (6 phases, 18 hours, 142.0 complexity):
- Included iteration loop removal (Phase 3) → Would limit functionality
- Included state machine simplification (Phase 4) → Minimal benefit, adds risk
- Included new optimization guide documentation (Phase 6) → Not essential

**Revised Plan** (4 phases, 10 hours, 78.0 complexity):
- Phase 1: Block consolidation (functionality-preserving)
- Phase 2: Test block consolidation (functionality-preserving)
- Phase 3: Standards compliance fixes (code quality)
- Phase 4: Code quality improvements (verbosity reduction)

**Reduction**: Removed 2 phases that would limit functionality, aligns with user constraint "improve WITHOUT limiting functionality"

### Implementation Notes
- All changes confined to `.claude/commands/build.md` (single file)
- NO library changes (state-persistence.sh, workflow-state-machine.sh unchanged)
- NO agent changes (implementer-coordinator.md, test-executor.md unchanged)
- Focus on code organization and quality, not architecture changes
- ALL existing tests MUST pass (zero tolerance for functionality regressions)
