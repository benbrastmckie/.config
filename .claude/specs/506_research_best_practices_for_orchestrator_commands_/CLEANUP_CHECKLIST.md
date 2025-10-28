# /coordinate Command Cleanup Checklist

## Code Analysis Summary (Phase 0)

**Baseline Metrics**:
- Total Lines: 2,148
- Echo Statements: 465
- Blank Echo Statements: 109
- Separator Lines (====): 20
- Diagnostic Info Blocks: 7
- Test Status: 11/12 passing (coordinate passes all agent invocation tests)

## Critical Issues

### 1. Recursion Bug (Phase 0.5 - HIGHEST PRIORITY)

**Problem**: coordinate_output.md shows "/coordinate is running..." appearing 3 times

**Analysis**:
- No SlashCommand invocations found in code (verified via grep)
- The recursion appears to be from Claude's response pattern, not from coordinate.md calling itself
- The coordinate.md file correctly uses Task tool only, not SlashCommand

**Root Cause**: LIKELY FALSE ALARM
- The output shows Claude saying "Now let me invoke the /coordinate command"
- This suggests the ORCHESTRATOR (Claude in the outer context) invoked /coordinate
- NOT that coordinate.md recursively called itself

**Verification Needed**:
- Test coordinate.md in isolation
- Confirm no actual self-invocation in the command logic
- May not need fixing if this is an artifact of testing methodology

## Output Reduction Opportunities (Phase 1)

### Workflow Detection Section (Lines 708-744)
**Current**: 36 lines of verbose output explaining scope detection
**Target**: Reduce to 5-10 lines (show scope, phases, nothing else)
**Savings**: ~25 lines of output (~70% reduction)

Example - Current:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Workflow Scope Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Description: "research API patterns"
Detected Scope: research-only

Phase Execution Plan:
  Execute: Phases 0,1
  Skip: Phases 2,3,4,5,6

Scope Behavior:
  - Research topic in parallel (2-4 agents)
  - Create overview document
  - Exit after Phase 1
```

Example - Proposed:
```
Workflow: research-only → Phase

s 0,1
```

### Verification Blocks (Multiple locations)
**Current**: 80-100 lines per verification with extensive diagnostics
**Locations**:
- Line 874: Research verification
- Similar blocks for plan, implementation verification

**Target**: Reduce verbose success messages, keep only failures
**Savings**: ~40 lines per verification block (~50% reduction)

Example - Current:
```
════════════════════════════════════════════════════════
  MANDATORY VERIFICATION - Research Reports
════════════════════════════════════════════════════════

Verifying Report 1: 001_orchestrator_patterns.md
  ✅ PASSED: Report created successfully (15234 bytes)
Verifying Report 2: 002_context_management.md
  ✅ PASSED: Report created successfully (12456 bytes)

Verification Summary:
  Total Reports Expected: 2
  Reports Created: 2
  Verification Failures: 0
```

Example - Proposed:
```
✓ Verification: 2/2 research reports created
```

### Blank Echo Statements (109 instances)
**Current**: echo "" used extensively for spacing
**Target**: Remove ~50% where spacing is unnecessary
**Savings**: ~55 lines of output

**Pattern to Remove**:
```bash
echo ""
echo "Some message"
echo ""
```

**Replace With**:
```bash
echo "Some message"
```

### Progress Markers
**Current**: emit_progress used throughout but also has echo statements
**Issue**: Duplicate output (emit_progress + echo describing same thing)
**Target**: Remove echo statements where emit_progress already provides marker

### Separator Lines (20 instances)
**Current**: Heavy use of ═══ and ━━━ separators
**Target**: Reduce to only critical section breaks (phases, errors)
**Savings**: ~15 separator lines

## Error Message Enhancement (Phase 2)

### Diagnostic Information Blocks (7 instances)
**Status**: Generally well-structured
**Enhancement Opportunities**:
1. Add file/line context where helpful (e.g., "Error in Phase 1, line 890")
2. Ensure diagnostic commands are always present
3. Improve "what to do next" guidance
4. Keep fail-fast behavior (no new retry logic)

**Example Locations**:
- Line 916: DIAGNOSTIC INFORMATION block in research verification
- Similar blocks in plan verification, implementation verification

**Changes**: Primarily clarification, not removal

## Code Consolidation Opportunities (Phase 3)

### Duplicate Verification Patterns
**Observation**: Research, Plan, Implementation verification blocks are very similar
**Opportunity**: Extract common verification logic to a function
**Estimated Savings**: ~100-150 lines

**Pattern**:
```bash
# Repeated in multiple places
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - [Artifact Type]"
echo "════════════════════════════════════════════════════════"
# ... verification logic ...
```

**Could become**:
```bash
verify_artifacts "Research Reports" "${REPORT_PATHS[@]}"
```

### Redundant Library Sourcing Checks
**Observation**: Multiple checks for library existence with similar error messages
**Current**: ~5-7 separate blocks checking different libraries
**Opportunity**: Consolidate into single library loading function

### Dead Code Paths
**Status**: No obvious dead code found
**Check**: grep for unused variables in Phase 3

### Unnecessary Sleeps/Delays
**Status**: No sleep commands found in initial analysis
**Verify**: Confirm no artificial delays in Phase 3

## Baseline Test Results

```
Test Suite: Orchestration Commands
- Agent invocation pattern: ✅ coordinate.md PASSED
- Agent invocation pattern: ✅ research.md PASSED
- Agent invocation pattern: ❌ supervise.md FAILED (not in scope)
- Bootstrap sequence: ✅ coordinate PASSED
- Delegation rate check: ✅ coordinate.md PASSED
Total: 11/12 passing (coordinate-specific: 5/5)
```

## Estimated Impact

### Output Reduction (Phase 1)
- Workflow detection: 70% reduction (36 → ~10 lines)
- Verification blocks: 50% reduction per block (~40 lines each)
- Blank echoes: 50% reduction (109 → ~55 lines)
- Separators: 75% reduction (20 → ~5 lines)
- **Total Estimated Output Reduction**: 50-60% (matches aggressive target)

### Code Size Reduction (Phase 3)
- Verification consolidation: ~150 lines
- Library loading consolidation: ~30 lines
- Dead code removal: TBD (need Phase 3 analysis)
- **Total Estimated Code Reduction**: ~200-250 lines (9-12%)

### Speed Improvements (Phase 3)
- Remove redundant file reads: TBD (measure in Phase 3)
- Optimize loops: TBD
- Consolidate library calls: Minor improvement
- **Target**: Measurable execution time reduction

## Dependencies

All libraries already exist:
- `.claude/lib/workflow-detection.sh` - Used
- `.claude/lib/error-handling.sh` - Used
- `.claude/lib/checkpoint-utils.sh` - Used
- `.claude/lib/dependency-analyzer.sh` - Used (wave execution)
- `.claude/lib/workflow-initialization.sh` - Used (Phase 0)

No new libraries needed.

## Risk Assessment

### Low Risk
- Output reduction (Phase 1): Very safe, only affects user display
- Separator removal: Safe, cosmetic only
- Blank echo removal: Safe

### Medium Risk
- Verification consolidation (Phase 3): Need careful testing
- Error message changes (Phase 2): Must preserve diagnostic capability

### High Risk
- **Wave execution code (Phase 3)**: DO NOT TOUCH
- Library loading sequence: Test extensively if changed

## Next Steps

1. **Phase 0.5**: Investigate recursion bug (may be false alarm)
2. **Phase 1**: Implement output reductions (50-60% target)
3. **Phase 2**: Enhance error messages (clarity, not removal)
4. **Phase 3**: Consolidate code (verification functions, library loading)
5. **Phase 4**: Validate 100% reliability (10-run test suite)

## Success Criteria

- [ ] No recursive /coordinate calls (verify in Phase 0.5)
- [ ] Console output reduced ~50-60%
- [ ] All tests still passing (11/11 for coordinate)
- [ ] File creation reliability: 100% maintained
- [ ] Wave-based execution: Untouched and working
- [ ] Code size: Reduced by ~200-250 lines
- [ ] Execution time: Measurably improved
