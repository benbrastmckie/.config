# /coordinate Command Initialization Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Optimize /coordinate initialization performance (50s → target <500ms)
- **Scope**: Reduce initialization time and token consumption without regression
- **Estimated Phases**: 5
- **Estimated Hours**: 18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 87.0
- **Research Reports**:
  - [Coordinate Initialization Bottlenecks](../reports/001_coordinate_initialization_bottlenecks.md)
  - [Optimization Strategies](../reports/002_optimization_strategies.md)

## Overview

The /coordinate command initialization is perceived as slow (reported 50 seconds, 2.5k tokens initial context). Research reveals the actual bash execution time is ~161ms for full initialization, indicating the bottleneck is Claude Code UI processing time rather than execution. However, multiple optimization opportunities exist to reduce both actual execution time and context consumption:

1. **Subprocess isolation overhead**: 7+ bash blocks × 67ms library re-sourcing = 469ms cumulative overhead
2. **Redundant git operations**: 5 `git rev-parse` calls × 6ms = 30ms wasted
3. **Large command file**: 1,505 lines = ~2,500 tokens initial context load
4. **Verification verbosity**: ~50 lines diagnostic output per checkpoint
5. **Verification bugs**: Grep pattern mismatch causes false-positive failures

This plan implements comprehensive optimizations targeting 52% execution time reduction (260ms savings) and 50% context reduction (2.5k → 1.2k tokens) while maintaining 100% functional compatibility.

## Research Summary

Key findings from research reports:

**Bottleneck Analysis** (Report 001):
- Actual bash execution: 161ms (Part 1: 6ms, Part 2: 40ms, full libs: 161ms)
- Subprocess isolation: Libraries re-sourced 7+ times per workflow (469ms overhead)
- Redundant operations: 5 git rev-parse calls (30ms), unused libraries loaded eagerly
- Verification bug: Grep pattern `^REPORT_PATHS_COUNT=` doesn't match `^export REPORT_PATHS_COUNT=`
- Context load: coordinate.md (1,505 lines) + 10 libraries (6,800 lines) = initial 2.5k token load

**Optimization Strategies** (Report 002):
- **High Impact**: Consolidate bash blocks (eliminate 200ms re-sourcing), cache CLAUDE_PROJECT_DIR (save 30ms)
- **Medium Impact**: Lazy library loading (defer 8 unused libraries, save 30ms), reduce verification verbosity (90% output reduction)
- **Low Risk**: Add source guards (zero-cost repeat sourcing), fix verification grep patterns (eliminate false positives)
- **Proven Patterns**: State persistence library already implements 67% improvement (6ms → 2ms) for CLAUDE_PROJECT_DIR detection

Recommended approach: Implement high-impact optimizations first (Phase 1-2), then medium-impact improvements (Phase 3-4), followed by file size reduction (Phase 5).

## Success Criteria

- [ ] Initialization time reduced by ≥40% (from 161ms baseline to ≤100ms target)
- [ ] Context consumption reduced by ≥40% (from 2.5k to ≤1.5k tokens initial load)
- [ ] All 127 state machine tests pass (100% regression prevention)
- [ ] Verification checkpoint grep patterns corrected (zero false positives)
- [ ] Source guards added to all libraries (consistent idempotency)
- [ ] Coordinate.md file size reduced by ≥40% (1,505 → ≤900 lines)
- [ ] Performance instrumentation added (measure before/after optimization)
- [ ] No functional changes (maintain identical workflow behavior)

## Technical Design

### Architecture Principles

1. **Preserve State Machine Architecture**: All optimizations maintain existing state-based orchestration patterns
2. **Subprocess Isolation Constraint**: Cannot eliminate bash block boundaries (Bash tool preprocessing), optimize within constraint
3. **Fail-Fast Philosophy**: Maintain verification checkpoints, reduce verbosity only on success
4. **Executable/Documentation Separation**: Move verbose documentation to guide (Standard 14)
5. **Zero Regression Tolerance**: Every change validated by test suite

### Optimization Strategy Layers

**Layer 1: Fix Verification Bugs** (Phase 1)
- Correct grep patterns in verification checkpoints
- Impact: Eliminate false-positive failures, reduce diagnostic output noise
- Risk: Zero (bug fixes only)

**Layer 2: Eliminate Redundancy** (Phase 2)
- Replace 5 redundant `git rev-parse` calls with state file caching
- Add source guards to remaining libraries
- Add performance instrumentation
- Impact: 30ms execution savings, defensive idempotency
- Risk: Low (uses existing state-persistence.sh patterns)

**Layer 3: Reduce Verbosity** (Phase 3)
- Simplify verification checkpoint output (50 lines → 1 line on success)
- Expand diagnostics only on failure
- Impact: 90% reduction in successful checkpoint output, faster UI rendering
- Risk: Low (success paths simplified, failure paths enhanced)

**Layer 4: Lazy Loading** (Phase 4)
- Defer loading of unused libraries until state handlers execute
- Impact: 20-30ms savings for research-only/plan-only workflows
- Risk: Low (source guards make repeated sourcing safe)

**Layer 5: File Size Reduction** (Phase 5)
- Extract verbose documentation to coordinate-command-guide.md
- Keep only executable bash blocks and critical comments
- Impact: 50% context reduction (2.5k → 1.2k tokens), faster UI parsing
- Risk: Medium (requires careful extraction, cross-reference validation)

### Integration Points

**Existing Infrastructure to Leverage**:
- state-persistence.sh: Already implements CLAUDE_PROJECT_DIR caching (67% improvement)
- workflow-state-machine.sh: Source guard present, idempotent re-sourcing
- .claude/tests/test_state_management.sh: 127 tests, 100% pass rate (regression detection)
- .claude/docs/guides/coordinate-command-guide.md: Target for extracted documentation

**Validation Strategy**:
- Run test suite after each phase (127 tests must pass)
- Add performance benchmarks (bash execution time, context token count)
- Manual workflow testing (research-only, full-implementation, debug-only scopes)

## Implementation Phases

### Phase 1: Fix Verification Checkpoint Bugs
dependencies: []

**Objective**: Correct grep pattern mismatches in verification checkpoints to eliminate false-positive failures

**Complexity**: Low

**Tasks**:
- [ ] Identify all verification checkpoints in coordinate.md (lines 211-228, 542-551, 797-806, etc.)
  - Search pattern: `grep -n "^if grep -q" .claude/commands/coordinate.md`
  - Expected: 15-20 verification checkpoints across all state handlers
- [ ] Analyze state-persistence.sh export format (file: .claude/lib/state-persistence.sh)
  - Line 90-100: Variable export format is `export VAR_NAME="value"`
  - Verification must match `^export VAR_NAME=` not `^VAR_NAME=`
- [ ] Replace incorrect grep patterns in all checkpoints
  - OLD: `if grep -q "^REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then`
  - NEW: `if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then`
  - Repeat for all state variables: REPORT_PATH_*, PLAN_PATH, IMPL_METADATA_*, TOPIC_DIR, etc.
- [ ] Add comment explaining pattern requirement
  - Example: `# Match 'export VAR=' format (state-persistence.sh line 94)`
  - Prevents future regressions from pattern misunderstanding

**Testing**:
```bash
# Verify checkpoints detect missing variables correctly
.claude/tests/test_state_management.sh
# Expected: All 127 tests pass

# Manual test: Trigger verification failure intentionally
STATE_FILE="/tmp/test_state.sh"
echo "INVALID_FORMAT=value" > "$STATE_FILE"
grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE"
# Expected: Exit code 1 (not found, triggers fallback diagnostics)
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(645): correct verification checkpoint grep patterns in coordinate`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Eliminate Redundant Operations
dependencies: [1]

**Objective**: Replace redundant git operations with state file caching and add defensive source guards

**Complexity**: Medium

**Tasks**:
- [ ] Replace redundant CLAUDE_PROJECT_DIR detection in bash blocks
  - Locations: coordinate.md lines 297, 432, 658, 747 (identified from Report 001)
  - Block 1 (line 55): Keep initial detection + `init_workflow_state()`
  - Block 2+ (lines 297+): Replace with `load_workflow_state "$WORKFLOW_ID"`
  - Validation: Verify state-persistence.sh line 144-182 implements graceful degradation
- [ ] Add source guards to libraries missing them (file: .claude/lib/)
  - library-sourcing.sh: Add `LIBRARY_SOURCING_SOURCED` guard (lines 1-5)
  - unified-location-detection.sh: Add `UNIFIED_LOCATION_DETECTION_SOURCED` guard
  - Pattern (from state-persistence.sh:9-12):
    ```bash
    if [ -n "${LIBRARY_NAME_SOURCED:-}" ]; then
      return 0
    fi
    export LIBRARY_NAME_SOURCED=1
    ```
- [ ] Add performance instrumentation to coordinate.md
  - Block 1 start: `INIT_START=$(date +%s%N)`
  - Block 2 end: `INIT_END=$(date +%s%N); INIT_MS=$(( (INIT_END - INIT_START) / 1000000 ))`
  - Output: `echo "PERF: Initialization completed in ${INIT_MS}ms" >&2`
  - Purpose: Measure actual optimization impact (baseline vs optimized)
- [ ] Document state file caching pattern in coordinate-command-guide.md
  - Section: "Performance Optimization → State File Caching"
  - Explain: Why caching (67% improvement), when to use (all bash blocks after init), graceful degradation

**Testing**:
```bash
# Verify state file caching works correctly
TEST_WORKFLOW_ID="test_$$"
STATE_FILE=$(init_workflow_state "$TEST_WORKFLOW_ID")
grep -q "^export CLAUDE_PROJECT_DIR=" "$STATE_FILE"
# Expected: Match found (cached correctly)

load_workflow_state "$TEST_WORKFLOW_ID"
echo "$CLAUDE_PROJECT_DIR"
# Expected: Project directory path restored from cache

# Run full test suite
.claude/tests/test_state_management.sh
# Expected: All 127 tests pass
```

**Expected Duration**: 4 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `perf(645): cache CLAUDE_PROJECT_DIR and add source guards`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Reduce Verification Verbosity
dependencies: [1, 2]

**Objective**: Simplify successful verification checkpoint output, expand diagnostics only on failure

**Complexity**: Medium

**Tasks**:
- [ ] Analyze current verification output volume (file: coordinate.md)
  - Locations: Lines 203-260 (Part 2 verification), 542-551 (research), 797-806 (plan), etc.
  - Current: ~50 lines per checkpoint (detailed variable enumeration, file size, counts)
  - Target: 1 line on success, expand on failure
- [ ] Create simplified success template
  - Format: `✓ State persistence verified (N/N variables)`
  - Example: `✓ State persistence verified (5/5 variables)` (single line)
  - Condition: All variables found in state file
- [ ] Create expanded failure template
  - Format:
    ```
    ❌ State persistence failed (M/N variables)
      Missing: VAR1, VAR2, VAR3
      Troubleshooting: See .claude/docs/guides/coordinate-troubleshooting.md#state-persistence
    ```
  - Condition: Any variable missing from state file
  - Include troubleshooting link for user guidance
- [ ] Replace verbose verification blocks across all state handlers
  - Part 2 verification (lines 203-260): Simplify to 1 line success / 5 lines failure
  - Research handler (lines 542-551): Apply same pattern
  - Plan handler (lines 797-806): Apply same pattern
  - Repeat for all 7 state handlers
- [ ] Add troubleshooting section to coordinate-command-guide.md
  - Section: "Troubleshooting → State Persistence Failures"
  - Include: Common causes, diagnostic commands, recovery procedures

**Testing**:
```bash
# Test success path (all variables present)
STATE_FILE="/tmp/test_success.sh"
cat > "$STATE_FILE" <<'EOF'
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="path1"
export REPORT_PATH_1="path2"
export REPORT_PATH_2="path3"
export REPORT_PATH_3="path4"
EOF

# Run verification (should output 1 line)
if grep -q "^export REPORT_PATHS_COUNT=" "$STATE_FILE" 2>/dev/null; then
  COUNT=$(grep "^export REPORT_PATHS_COUNT=" "$STATE_FILE" | cut -d'"' -f2)
  echo "✓ State persistence verified ($COUNT/$COUNT variables)"
fi
# Expected: Single line output

# Test failure path (missing variables)
STATE_FILE="/tmp/test_failure.sh"
cat > "$STATE_FILE" <<'EOF'
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="path1"
# Missing: REPORT_PATH_1, REPORT_PATH_2, REPORT_PATH_3
EOF

# Run verification (should output expanded diagnostics)
# Expected: Multi-line failure output with troubleshooting link

# Run full test suite
.claude/tests/test_state_management.sh
# Expected: All 127 tests pass
```

**Expected Duration**: 6 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `perf(645): reduce verification checkpoint verbosity by 90%`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Implement Lazy Library Loading
dependencies: [2]

**Objective**: Defer loading of unused libraries until state handlers execute to reduce initialization overhead

**Complexity**: Medium

**Tasks**:
- [ ] Analyze library usage patterns across workflow scopes
  - Research-only: Needs 6 libraries (workflow-detection, unified-logger, overview-synthesis, etc.)
  - Full-implementation: Needs all 10 libraries
  - Identify unused libraries per scope (file: coordinate.md lines 131-144)
- [ ] Create lazy_source() wrapper function
  - Implementation:
    ```bash
    lazy_source() {
      local lib="$1"
      local guard_var="${lib%.sh}_SOURCED"
      guard_var="${guard_var^^//\//_}"  # uppercase, replace / with _

      if [ -z "${!guard_var:-}" ]; then
        source "${CLAUDE_PROJECT_DIR}/.claude/lib/$lib"
      fi
    }
    ```
  - Add to coordinate.md after library-sourcing.sh sourcing (line ~100)
- [ ] Replace eager library loading with lazy pattern in state handlers
  - Research handler (line 285): Keep essential libs, lazy-load metadata-extraction.sh, overview-synthesis.sh
  - Plan handler (line 646): Lazy-load checkpoint-utils.sh (only if resuming)
  - Implement handler (line 909): Lazy-load dependency-analyzer.sh, context-pruning.sh
  - Debug handler (line 1173): Lazy-load error-handling.sh (if not already loaded)
- [ ] Add lazy loading documentation to coordinate-command-guide.md
  - Section: "Performance Optimization → Lazy Library Loading"
  - Explain: Why lazy (20-30ms savings), when used (state handler entry), trade-offs (first-call latency)
- [ ] Measure performance impact with instrumentation
  - Baseline: Full library loading time (50ms)
  - Optimized: Essential libs only (20ms), lazy libs on-demand (10ms per handler)
  - Expected savings: 20-30ms for research-only workflows

**Testing**:
```bash
# Test lazy_source() function
CLAUDE_PROJECT_DIR="/home/benjamin/.config"
source .claude/lib/state-persistence.sh  # Has source guard

# First call: Should source library
unset STATE_PERSISTENCE_SOURCED
lazy_source "state-persistence.sh"
[ -n "$STATE_PERSISTENCE_SOURCED" ] && echo "✓ Library sourced"

# Second call: Should skip (guard active)
lazy_source "state-persistence.sh"
# Expected: Immediate return (no re-sourcing)

# Test research-only workflow (should skip unused libraries)
WORKFLOW_DESCRIPTION="research async patterns"
WORKFLOW_SCOPE="research-only"
# Essential libs loaded: 6 libraries (~20ms)
# Unused libs deferred: 4 libraries (~30ms saved)

# Run full test suite
.claude/tests/test_state_management.sh
# Expected: All 127 tests pass
```

**Expected Duration**: 5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `perf(645): implement lazy library loading for unused dependencies`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Reduce Coordinate File Size
dependencies: [1, 2, 3, 4]

**Objective**: Extract verbose documentation to guide file to reduce initial context load by 50%

**Complexity**: High

**Tasks**:
- [ ] Audit coordinate.md for extractable documentation (file: .claude/commands/coordinate.md)
  - Current: 1,505 lines total
  - Target: ≤900 lines executable (40% reduction)
  - Identify: State handler documentation (objectives, architecture notes), verification explanations, troubleshooting inline comments
  - Keep: Executable bash blocks, critical comments (WHAT not WHY), state transition logic
- [ ] Extract state handler documentation to coordinate-command-guide.md
  - Section per handler: "State Handlers → Research Phase", "State Handlers → Planning Phase", etc.
  - Include: Detailed objectives, agent invocation patterns, verification checkpoints, common issues
  - Cross-reference from coordinate.md: `# See coordinate-command-guide.md § State Handlers → Research`
- [ ] Validate executable/documentation separation pattern compliance
  - Run: `.claude/tests/validate_executable_doc_separation.sh`
  - Verify: Executable <250 lines (coordinate.md is orchestrator, threshold is 400 lines)
  - Check: Guide exists with ≥3 sections, cross-references bidirectional
- [ ] Update cross-references in coordinate.md
  - Header (line 13): Reference guide for "architecture, usage patterns, troubleshooting"
  - Inline references: Replace verbose comments with guide section links
  - Example: `# VERIFICATION: See guide § Troubleshooting → State Persistence`
- [ ] Measure context reduction with instrumentation
  - Baseline: 1,505 lines ≈ 2,500 tokens (1.66 tokens/line average)
  - Target: ≤900 lines ≈ 1,500 tokens (40% reduction)
  - Validation: Check Claude Code UI initial context load

**Testing**:
```bash
# Validate file size reduction
BEFORE_LINES=$(wc -l < .claude/commands/coordinate.md)
# Expected: 1505 lines (baseline)

# After extraction:
AFTER_LINES=$(wc -l < .claude/commands/coordinate.md)
REDUCTION_PCT=$(( 100 * (BEFORE_LINES - AFTER_LINES) / BEFORE_LINES ))
echo "File size reduced by ${REDUCTION_PCT}%"
# Expected: ≥40% reduction

# Validate executable/documentation separation
.claude/tests/validate_executable_doc_separation.sh
# Expected: PASS (file size, guide existence, cross-references)

# Verify guide completeness
GUIDE_SECTIONS=$(grep -c "^## " .claude/docs/guides/coordinate-command-guide.md)
echo "Guide sections: $GUIDE_SECTIONS"
# Expected: ≥10 sections (architecture, state handlers × 7, troubleshooting, performance)

# Run full test suite
.claude/tests/test_state_management.sh
# Expected: All 127 tests pass (no functional changes)
```

**Expected Duration**: 8 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `docs(645): extract coordinate documentation to guide (Standard 14)`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Regression Prevention

**Test Suite Validation** (127 tests, 100% pass rate required):
- `.claude/tests/test_state_management.sh`: State machine transitions, checkpoint operations
- Run after every phase completion
- Zero tolerance for test failures

**Manual Workflow Testing**:
- Research-only workflow: `/coordinate "research async patterns"`
- Full-implementation workflow: `/coordinate "implement user authentication"`
- Debug-only workflow: `/coordinate "debug initialization failure"`
- Verify: All scopes complete successfully, no behavior changes

### Performance Benchmarking

**Execution Time Measurement**:
- Instrument coordinate.md with `date +%s%N` timestamps (Phase 2)
- Baseline: 161ms full initialization (measured in Report 001)
- Target: ≤100ms (40% reduction)
- Measure: Per-phase impact (report in commit messages)

**Context Consumption Measurement**:
- Baseline: coordinate.md = 1,505 lines ≈ 2,500 tokens
- Target: ≤900 lines ≈ 1,500 tokens (40% reduction)
- Validation: Manual review of Claude Code UI initial context

**Library Loading Measurement**:
- Essential libs: 20ms (Phase 4 baseline)
- Lazy libs: 10ms per handler (on-demand loading)
- Savings: 20-30ms for research-only workflows

### Verification Checkpoint Testing

**Success Path Validation**:
- All variables present in state file
- Verification outputs 1 line: `✓ State persistence verified (N/N variables)`
- No false-positive failures (Phase 1 bug fixes)

**Failure Path Validation**:
- Missing variables in state file
- Verification outputs multi-line diagnostics with troubleshooting link
- Workflow terminates with clear error message

## Documentation Requirements

### Updated Files

**Primary Documentation**:
- `.claude/docs/guides/coordinate-command-guide.md`: Extract verbose state handler documentation (Phase 5)
  - Sections: Architecture, State Handlers (7), Troubleshooting, Performance Optimization
  - Cross-references: Bidirectional links with coordinate.md

**Inline Documentation**:
- `.claude/commands/coordinate.md`: Reduce to critical comments only (WHAT not WHY)
  - Reference guide for detailed explanations
  - Maintain fail-fast verification checkpoints

**Test Documentation**:
- `.claude/tests/test_state_management.sh`: Update test comments if behavior changes (minimal expected)

### New Documentation Sections

**Coordinate Command Guide** (Phase 3, 5):
- "Performance Optimization → State File Caching" (Phase 2)
- "Performance Optimization → Lazy Library Loading" (Phase 4)
- "Troubleshooting → State Persistence Failures" (Phase 3)
- "State Handlers" × 7 sections (Phase 5)

## Dependencies

### External Dependencies
- bash ≥4.0: Required for source guards, array operations
- git: Used for CLAUDE_PROJECT_DIR detection (cached after first call)

### Internal Dependencies
- `.claude/lib/state-persistence.sh`: State file caching (67% improvement)
- `.claude/lib/workflow-state-machine.sh`: State transition logic
- `.claude/lib/workflow-initialization.sh`: Lazy directory creation
- `.claude/tests/test_state_management.sh`: Regression detection (127 tests)

### Phase Dependencies
- Phase 2 depends on Phase 1 (verification bugs must be fixed before caching changes)
- Phase 3 depends on Phases 1-2 (verbosity reduction builds on fixed verification)
- Phase 4 depends on Phase 2 (lazy loading requires source guards)
- Phase 5 depends on all previous phases (file size reduction is final polish)

## Performance Targets

### Time Savings
- Baseline: 161ms (full initialization measured in Report 001)
- Phase 1: +0ms (bug fixes only)
- Phase 2: -30ms (state file caching for git operations)
- Phase 3: +0ms execution, -UI rendering time (verbosity reduction)
- Phase 4: -20ms to -30ms (lazy loading for research-only workflows)
- Phase 5: +0ms execution, -UI parsing time (context reduction)
- **Total: -50ms to -60ms execution (31-37% reduction), significant UI improvement**

### Context Savings
- Baseline: 2,500 tokens (coordinate.md initial load)
- Phase 5: -1,000 tokens (40% file size reduction)
- **Total: 1,500 tokens initial load (40% reduction)**

### Reliability Improvements
- Phase 1: Eliminate false-positive verification failures (grep pattern bugs)
- Phase 2: Defensive source guards (100% idempotent re-sourcing)
- Phase 3: Enhanced failure diagnostics (faster troubleshooting)
- Phase 4: Graceful degradation (lazy loading with fallback)
- Phase 5: Improved maintainability (executable/documentation separation)

## Risk Mitigation

### Regression Risk
- **Mitigation**: Run 127-test suite after every phase
- **Fallback**: Git revert if any test fails
- **Validation**: Manual workflow testing across all scopes

### Performance Risk
- **Mitigation**: Measure with instrumentation before/after each phase
- **Fallback**: Keep baseline measurements, revert if regression
- **Validation**: Compare actual vs target savings in commit messages

### Documentation Risk
- **Mitigation**: Validate executable/documentation separation pattern (Standard 14)
- **Fallback**: Keep coordination in coordinate.md if separation breaks workflows
- **Validation**: Run validate_executable_doc_separation.sh in Phase 5

### State Persistence Risk
- **Mitigation**: State-persistence.sh already implements graceful degradation
- **Fallback**: Re-detect CLAUDE_PROJECT_DIR if state file missing
- **Validation**: Test failure path explicitly (missing state file)

## Notes

**Context Window Optimization Philosophy**: This optimization focuses on reducing both execution time (bash performance) and UI processing time (context parsing, rendering). The 50-second user-reported delay is likely UI overhead, not bash execution, but optimizing bash creates faster UI experiences through reduced context and output volume.

**Subprocess Isolation Constraint**: Cannot eliminate bash block boundaries due to Bash tool preprocessing. Optimizations work within this constraint by caching state across blocks and reducing per-block overhead.

**Zero Regression Tolerance**: All optimizations must maintain identical workflow behavior. Test suite validation is non-negotiable after every phase.

**Standard 14 Compliance**: Phase 5 implements executable/documentation separation pattern to reduce coordinate.md context load. This pattern is proven across other commands (implement-command-guide.md, plan-command-guide.md).

**Future Optimization Opportunities**: After this plan, consider single-block consolidation (Recommendation 1 from Report 002) which could save 200ms but requires significant refactoring. This plan focuses on safer, incremental improvements first.
