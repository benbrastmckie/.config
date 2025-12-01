# Command Performance Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: Optimize /plan, /build, /debug, and /research commands
- **Scope**: Structural optimizations (hard barriers, block consolidation, bulk I/O)
- **Estimated Phases**: 3
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Command Performance Optimization Strategy](../reports/001-command-performance-optimization-strategy.md)

## Overview

This plan implements **structural optimizations** to improve command performance and reliability. The research shows that the previous repair attempt (spec 983) failed because it addressed symptoms (140 logged errors) rather than root causes (architectural inefficiencies). This focused plan targets the highest-impact optimizations identified in the research.

**Key Optimizations**:
1. **Hard Barrier Pattern** (40-60% context reduction, eliminates timeout errors)
2. **Block Consolidation** (150-200ms saved, simpler code structure)
3. **Bulk State I/O** (84ms saved, single write instead of 15)

**Expected Impact**:
- Performance: 234-284ms improvement (0.4-0.9% faster)
- Reliability: 40-60% context reduction eliminates timeout errors
- Maintainability: Simpler block structure reduces exit code 127 errors

**Scope**: Phase 1 structural optimizations ONLY. Lazy library loading (Phase 2 from research) is deferred to future work.

## Research Summary

The research analyzed the failed repair plan (spec 983) and identified root causes:

1. **Hard Barrier Pattern Missing**: /research command bypasses research-specialist delegation, causing 40-60% context inflation and timeout errors. Primary agent sees "MANDATORY" language as guidance and performs work directly.

2. **Excessive Bash Blocks**: Commands use 3-5 subprocess spawns when 2 would suffice (450ms overhead per command from spawning, library sourcing, state restoration).

3. **Line-by-Line State I/O**: 15 individual file writes instead of 1 bulk write (30ms overhead per block × 3 blocks = 90ms wasted).

4. **Error Logging NOT the Problem**: Research shows error logging is only 0.3-1.5% of runtime. Removing it provides negligible performance gain but eliminates 80% error coverage.

**Recommended Approach**: Implement structural optimizations (hard barriers, block consolidation, bulk I/O) to address root causes rather than symptoms.

## Success Criteria

- [ ] /research command enforces hard barrier pattern (primary agent cannot proceed without subagent completion)
- [ ] /plan command reduced from 3 bash blocks to 2 blocks
- [ ] /build command reduced from 5 bash blocks to 3 blocks
- [ ] All commands use bulk state I/O instead of line-by-line appends
- [ ] Performance improvement: 234-284ms total
- [ ] Context reduction: 40-60% when delegation properly enforced
- [ ] No functional regressions (all existing tests pass)
- [ ] Error logging coverage maintained at 80%

## Technical Design

### Hard Barrier Pattern Architecture

**Problem**: Primary agents bypass subagent delegation when barriers are descriptive ("MANDATORY") rather than structural (pre-calculated paths + validation).

**Solution**: Implement 3-block pattern:
1. **Block 1d: Path Pre-Calculation** - Calculate artifact path BEFORE agent invocation
2. **Block 1d-exec: Agent Invocation** - Pass pre-calculated path in Task prompt
3. **Block 1e: Hard Barrier Validation** - Verify file exists at exact path, exit 1 if missing

**Example** (/research command):
```markdown
## Block 1d: Report Path Pre-Calculation
```bash
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))
REPORT_SLUG=$(echo "${WORKFLOW_DESCRIPTION:-research}" | head -c 40 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
echo "Report Path: $REPORT_PATH"
```

## Block 1d-exec: Research Specialist Invocation
Task {
  prompt: "Report Path: ${REPORT_PATH} (MUST create file at exact path)"
}

## Block 1e: Agent Output Validation (Hard Barrier)
```bash
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "agent_error" "research-specialist failed to create report file"
  echo "ERROR: HARD BARRIER FAILED - Report file not found"
  exit 1
fi
```
```

**Why This Works**: Primary agent CANNOT proceed without file existing at pre-calculated path. No guessing, no fallback to manual work.

### Block Consolidation Strategy

**Current Pattern** (3-5 blocks):
```
Block 1a: Setup
Block 1c: Path initialization (separate subprocess)
Block 2: Verification (another subprocess)
```

**Optimized Pattern** (2-3 blocks):
```
Block 1: Setup + Path Pre-Calculation (single subprocess)
[Task invocations]
Block 2: Verification + Completion (single subprocess)
```

**Constraint**: Task invocations remain in their own logical sections (don't merge bash + Task in same block).

**Expected Gain**: Reduce subprocess spawns by 33-40%, saving 150-200ms per command.

### Bulk State I/O Pattern

**Current** (line-by-line):
```bash
append_workflow_state "VAR1" "value1"  # Write 1
append_workflow_state "VAR2" "value2"  # Write 2
append_workflow_state "VAR3" "value3"  # Write 3
# ... (15 individual writes)
```

**Optimized** (bulk write):
```bash
append_workflow_state_bulk <<EOF
VAR1=value1
VAR2=value2
VAR3=value3
EOF
```

**Expected Gain**: 1 file write instead of 15 = 28ms saved per block × 3 blocks = 84ms per command.

## Implementation Phases

### Phase 1: Implement Hard Barrier Pattern in /research Command [NOT STARTED]
dependencies: []

**Objective**: Add structural enforcement to prevent primary agent from bypassing research-specialist delegation.

**Complexity**: Medium

Tasks:
- [ ] Read current /research command implementation (file: .claude/commands/research.md)
- [ ] Add Block 1d: Report Path Pre-Calculation after topic initialization
- [ ] Update Block 1d-exec: Pass REPORT_PATH to research-specialist Task prompt
- [ ] Add Block 1e: Agent Output Validation (hard barrier enforcement)
- [ ] Update research-specialist.md agent to use pre-calculated REPORT_PATH
- [ ] Add error logging for agent_error when hard barrier fails

Testing:
```bash
# Test hard barrier enforcement
/research "test hard barrier pattern"

# Verify report created at pre-calculated path
ls -la .claude/specs/*/reports/001-test-hard-barrier-pattern.md

# Verify no agent_error in logs
grep "agent_error" .claude/data/logs/errors.jsonl | tail -5
```

**Expected Duration**: 2 hours

**Validation**:
- Workflow output shows: Task invocation → Agent execution → Validation → Completion
- Agent creates file at exact pre-calculated path
- Hard barrier validation fails if file missing (exit 1)
- Context reduction: 2,500 tokens (specialist work) → 110 tokens (metadata summary)

### Phase 2: Consolidate Bash Blocks [NOT STARTED]
dependencies: [1]

**Objective**: Reduce bash subprocess spawns from 3-5 blocks to 2-3 blocks per command.

**Complexity**: Medium

Tasks:
- [ ] Audit /plan command blocks (file: .claude/commands/plan.md) - currently 3 blocks
- [ ] Merge Block 1a (Setup) + Block 1c (Path Init) into single Block 1
- [ ] Audit /build command blocks (file: .claude/commands/build.md) - currently 5 blocks
- [ ] Consolidate /build blocks: Block 1 (Setup + Orchestration Init) + Block 2 (Verification) + Block 3 (Completion)
- [ ] Audit /research command blocks (file: .claude/commands/research.md) - currently 2 blocks (plus new hard barrier block)
- [ ] Verify Task invocations remain in separate logical sections
- [ ] Update output-formatting.md standards with consolidation examples

Testing:
```bash
# Test /plan block count
/plan "test block consolidation"
grep -c "```bash" .claude/output/plan-output.md  # Should be 2 (not 3)

# Test /build block count
/build .claude/specs/986_optimize_command_performance/plans/001-optimize-command-performance-plan.md
grep -c "```bash" .claude/output/build-output.md  # Should be 3 (not 5)

# Verify no functional regressions
/plan "authentication feature"  # Should complete successfully
/build [plan-from-above]  # Should execute phases correctly
```

**Expected Duration**: 3 hours

**Validation**:
- /plan: 3 blocks → 2 blocks (33% reduction)
- /build: 5 blocks → 3 blocks (40% reduction)
- /research: 2 blocks → 1 block + hard barrier validation (50% reduction)
- All existing tests pass (no functional changes)
- Performance improvement: 150-200ms per command

### Phase 3: Convert to Bulk State I/O [NOT STARTED]
dependencies: [2]

**Objective**: Replace line-by-line append_workflow_state calls with bulk writes.

**Complexity**: Low

Tasks:
- [ ] Grep all append_workflow_state calls across commands (files: .claude/commands/*.md)
- [ ] Identify blocks with 5+ consecutive append_workflow_state calls
- [ ] Convert /plan command to bulk state I/O (estimated 15 line-by-line writes)
- [ ] Convert /build command to bulk state I/O (estimated 12 line-by-line writes)
- [ ] Convert /research command to bulk state I/O (estimated 8 line-by-line writes)
- [ ] Convert /debug command to bulk state I/O (estimated 10 line-by-line writes)
- [ ] Verify state file format unchanged (key=value lines)

Testing:
```bash
# Test bulk state I/O
/plan "test bulk state write"

# Verify state file format
cat .claude/tmp/workflow_*.sh  # Should contain KEY=VALUE lines

# Verify state restoration succeeds in Block 2
grep "source.*STATE_FILE" .claude/output/plan-output.md

# Run full integration test
/plan "integration test feature"
/build [plan-from-above]  # Should restore state correctly in all phases
```

**Expected Duration**: 3 hours

**Validation**:
- All line-by-line appends converted to bulk writes
- State file format unchanged (KEY=VALUE)
- State restoration succeeds in verification blocks
- Performance improvement: 84ms per command
- No functional regressions

## Testing Strategy

### Integration Tests

**Test Case 1: Hard Barrier Enforcement**
```bash
# Run /research command
/research "hard barrier test workflow"

# Verify research-specialist invoked (not bypassed)
grep "Task {" .claude/output/research-output.md

# Verify report created at pre-calculated path
test -f .claude/specs/*/reports/001-hard-barrier-test-workflow.md

# Verify hard barrier validation passed
grep "Agent output validated" .claude/output/research-output.md

# Verify no agent_error logged
! grep "agent_error" .claude/data/logs/errors.jsonl | tail -1 | grep "research-specialist"
```

**Test Case 2: Block Consolidation**
```bash
# Run /plan command
/plan "block consolidation test"

# Count bash blocks (should be 2)
BLOCK_COUNT=$(grep -c "^## Block" .claude/output/plan-output.md)
[ "$BLOCK_COUNT" -eq 2 ] || echo "FAIL: Expected 2 blocks, got $BLOCK_COUNT"

# Run /build command
/build .claude/specs/986_optimize_command_performance/plans/001-optimize-command-performance-plan.md

# Count bash blocks (should be 3)
BLOCK_COUNT=$(grep -c "^## Block" .claude/output/build-output.md)
[ "$BLOCK_COUNT" -eq 3 ] || echo "FAIL: Expected 3 blocks, got $BLOCK_COUNT"
```

**Test Case 3: Bulk State I/O**
```bash
# Run any command after bulk I/O implementation
/plan "bulk state I/O test"

# Verify state file contains bulk write
STATE_FILE=$(ls -t .claude/tmp/workflow_*.sh | head -1)
LINE_COUNT=$(wc -l < "$STATE_FILE")
[ "$LINE_COUNT" -gt 10 ] || echo "FAIL: State file too small (bulk write not used?)"

# Verify state restoration succeeds
grep "source.*STATE_FILE" .claude/output/plan-output.md
```

### Performance Benchmarks

```bash
# Baseline measurement (before optimization)
time /plan "baseline performance test"
# Expected: 30-60s

# After optimization
time /plan "optimized performance test"
# Expected: 29-59s (0.5-1.0% faster)

# Verify performance gain
# Expected total improvement: 234-284ms
# - Block consolidation: 150-200ms
# - Bulk state I/O: 84ms
```

### Regression Tests

All existing tests must pass:
- /plan creates valid plan files
- /build executes phases correctly
- /research creates research reports
- /debug creates debug reports
- State persistence works across bash blocks
- Error logging coverage maintained (80%)

## Documentation Requirements

### Standards Documentation Updates

- [ ] Update `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` with /research implementation example
- [ ] Update `.claude/docs/reference/standards/output-formatting.md` with block consolidation targets (2-3 blocks per command)
- [ ] Update `.claude/docs/guides/commands/research-command-guide.md` with hard barrier pattern explanation

### Command Documentation Updates

- [ ] Add "Block Structure" section to research.md explaining hard barrier pattern
- [ ] Add "Performance Optimizations" section to plan.md documenting block consolidation
- [ ] Add "State Management" section to build.md documenting bulk I/O usage

### Migration Guide

Create migration guide for:
- Commands implementing hard barrier pattern
- Converting line-by-line state I/O to bulk writes
- Consolidating bash blocks without breaking Task invocations

## Dependencies

### Prerequisites

- `append_workflow_state_bulk` function exists in state-persistence.sh (already implemented)
- `log_command_error` function exists in error-handling.sh (already implemented)
- Hard barrier pattern documented in concepts/patterns/hard-barrier-subagent-delegation.md (already exists)

### External Dependencies

None - all optimizations use existing library functions and patterns.

### Integration Points

- State machine transitions (must work with consolidated blocks)
- Error logging (must maintain 80% coverage)
- Agent invocation protocol (must enforce hard barriers)
- Output formatting standards (must align with 2-3 block target)

## Risk Assessment

### Low Risk Items
- Bulk state I/O (function already tested in production)
- Documentation updates (no functional impact)

### Medium Risk Items
- Block consolidation (requires careful testing to ensure state restoration works)
- Hard barrier validation (must not break existing workflows)

### Mitigation Strategies
- Implement hard barrier pattern first (highest impact, easiest to test)
- Test block consolidation with integration tests before deploying
- Monitor error logs for exit code 127 errors (library function not found)
- Maintain error logging coverage (do NOT remove for negligible performance gain)
- Rollback capability: Keep backup of original command files

## Implementation Notes

### Why This Plan is Focused

The previous repair plan (spec 983) failed because it was too large:
- 7 phases, 56 tasks, 24 hours estimated
- Attempted to fix 140 logged errors through architectural changes
- High risk of breaking changes without clear rollback strategy

This plan is deliberately constrained:
- 3 phases, 18 tasks, 8 hours estimated
- Focuses on highest-impact optimizations (hard barriers, block consolidation, bulk I/O)
- Low-to-medium risk with clear rollback capability
- Addresses root causes (delegation bypass, subprocess overhead) not symptoms (logged errors)

### Future Work (Deferred)

**Lazy Library Loading** (Phase 2 from research):
- Expected gain: 120ms per command
- Risk: Medium (requires careful dependency analysis)
- Effort: 8-10 hours
- Reason for deferral: Lower priority than structural optimizations, higher risk

**Performance Profiling** (Phase 3 from research):
- Expected gain: Data-driven optimization targets
- Risk: Low (observability only)
- Effort: 10-12 hours
- Reason for deferral: Should be done AFTER structural optimizations to measure actual bottlenecks

### Success Metrics

**Performance** (measured via `time` command):
- /plan: 30-60s → 29-59s (0.5-1.0% faster)
- /build: 60-180s → 59-178s (0.5-1.0% faster)
- /research: 20-40s → 19-39s (0.5-1.0% faster)

**Reliability** (measured via error logs):
- Context inflation: 40-60% → 0% (hard barriers enforced)
- Timeout errors: ~15/day → <5/day (67% reduction)
- Exit code 127 errors: ~10/day → <3/day (70% reduction)
- Agent delegation success rate: 50-60% → 95%+ (hard barriers enforced)

**Maintainability** (measured via code structure):
- Bash blocks per command: 3-5 → 2-3 (simpler structure)
- Library sourcing calls: 15-25 → 10-15 (fewer dependencies)
- Error coverage: 80% → 80% (maintained, not reduced)
