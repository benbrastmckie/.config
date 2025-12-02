# Task Invocation Pattern Audit Report

## Executive Summary

**Date**: 2025-12-02
**Scope**: All command files in `.claude/commands/`
**Total Commands Audited**: 15
**Total Task Invocations Found**: 35
**Broken Invocations (Missing EXECUTE NOW)**: 22 (63%)
**Fixed Invocations (Has EXECUTE NOW)**: 13 (37%)

## Critical Findings

### 1. Widespread Pattern Violation

22 out of 35 Task invocations (63%) lack the imperative "EXECUTE NOW" directive required for Claude to recognize them as actual tool calls rather than pseudo-code documentation.

### 2. Inconsistent Application of Fix

The fix from commit 0b710aff (supervise.md) was partially applied:
- 8 commands have SOME Task blocks fixed (mixed state)
- 7 commands have NO Task blocks fixed (completely broken)
- Only 1 command is fully fixed (convert-docs.md with 1/1 fixed)

### 3. Edge Case Patterns Identified

- **Iteration Loop Pattern**: `/implement` (line 944) - second invocation missing EXECUTE NOW
- **Instructional Text Pattern**: `/test` (2 occurrences) - comments instead of Task blocks
- **Conditional Invocations**: `/build` test-executor only invoked on test failures

## Command-by-Command Analysis

### High-Priority Workflow Commands (7 commands, 19 Task blocks)

#### /plan (3 Task blocks: 2 fixed, 1 broken)
**Status**: PARTIALLY FIXED
**Priority**: CRITICAL
**Invocations**:
- Line 397: topic-naming-agent (MISSING EXECUTE NOW) ✗
- Line 848: research-specialist (HAS EXECUTE NOW) ✓
- Line 1198: plan-architect (HAS EXECUTE NOW) ✓

**Pattern**: Topic naming agent was missed in original fix

---

#### /research (2 Task blocks: 1 fixed, 1 broken)
**Status**: PARTIALLY FIXED
**Priority**: MEDIUM-HIGH
**Invocations**:
- Line 368: topic-naming-agent (MISSING EXECUTE NOW) ✗
- Line 841: research-specialist (HAS EXECUTE NOW) ✓

**Pattern**: Topic naming agent was missed in original fix

---

#### /build (4 Task blocks: 3 fixed, 1 broken)
**Status**: PARTIALLY FIXED
**Priority**: CRITICAL
**Invocations**:
- Line 515: implementer-coordinator (HAS EXECUTE NOW) ✓
- Line 1083: spec-updater (HAS EXECUTE NOW) ✓
- Line 1245: test-executor (MISSING EXECUTE NOW) ✗
- Line 1605: debug-analyst (HAS EXECUTE NOW) ✓

**Pattern**: Test executor invocation (conditional, only on failures) missing EXECUTE NOW

---

#### /debug (4 Task blocks: 4 fixed, 0 broken)
**Status**: FULLY FIXED
**Priority**: HIGH
**Invocations**:
- Line 323: topic-naming-agent (HAS EXECUTE NOW) ✓
- Line 659: research-specialist (HAS EXECUTE NOW) ✓
- Line 946: plan-architect (HAS EXECUTE NOW) ✓
- Line 1203: debug-analyst (HAS EXECUTE NOW) ✓

**Pattern**: All invocations properly fixed

---

#### /repair (2 Task blocks: 2 fixed, 0 broken)
**Status**: FULLY FIXED
**Priority**: HIGH
**Invocations**:
- Line 503: repair-analyst (HAS EXECUTE NOW) ✓
- Line 1159: plan-architect (HAS EXECUTE NOW) ✓

**Pattern**: All invocations properly fixed

---

#### /revise (2 Task blocks: 2 fixed, 0 broken)
**Status**: FULLY FIXED
**Priority**: HIGH
**Invocations**:
- Line 623: research-specialist (HAS EXECUTE NOW) ✓
- Line 1053: plan-architect (HAS EXECUTE NOW) ✓

**Pattern**: All invocations properly fixed

---

#### /implement (2 Task blocks: 1 fixed, 1 broken)
**Status**: PARTIALLY FIXED
**Priority**: CRITICAL
**Invocations**:
- Line 514: implementer-coordinator (HAS EXECUTE NOW) ✓
- Line 944: implementer-coordinator (MISSING EXECUTE NOW) ✗

**Pattern**: **ITERATION LOOP** - Same agent invoked twice (initial + loop re-invocation), second instance missing EXECUTE NOW

**Edge Case**: This is the iteration loop pattern where the same Task invocation must be fixed in two places

---

### Edge Case Commands (1 command, 2 instructional patterns)

#### /test (0 Task blocks, 2 instructional patterns)
**Status**: BROKEN (Different Pattern)
**Priority**: MEDIUM-HIGH
**Invocations**: None (instructional text instead)
**Instructional Patterns**: 2 occurrences of "Use the Task tool to invoke..."

**Pattern**: **INSTRUCTIONAL TEXT** - Uses comments to describe Task tool usage instead of actual Task blocks

**Edge Case**: Requires converting instructional text to imperative Task invocations

---

### Utility Commands (7 commands, 14 Task blocks)

#### /errors (2 Task blocks: 0 fixed, 2 broken)
**Status**: COMPLETELY BROKEN
**Priority**: MEDIUM
**Invocations**:
- Line 313: topic-naming-agent (MISSING EXECUTE NOW) ✗
- Line 546: errors-analyst (MISSING EXECUTE NOW) ✗

---

#### /expand (4 Task blocks: 0 fixed, 4 broken)
**Status**: COMPLETELY BROKEN
**Priority**: LOW
**Invocations**:
- Line 247: plan-architect (MISSING EXECUTE NOW) ✗
- Line 565: plan-architect (MISSING EXECUTE NOW) ✗
- Line 895: complexity-estimator (MISSING EXECUTE NOW) ✗
- Line 965: unknown agent (MISSING EXECUTE NOW) ✗

---

#### /collapse (4 Task blocks: 0 fixed, 4 broken)
**Status**: COMPLETELY BROKEN
**Priority**: LOW
**Invocations**:
- Line 261: plan-architect (MISSING EXECUTE NOW) ✗
- Line 509: plan-architect (MISSING EXECUTE NOW) ✗
- Line 744: complexity-estimator (MISSING EXECUTE NOW) ✗
- Line 790: unknown agent (MISSING EXECUTE NOW) ✗

---

#### /setup (1 Task block: 0 fixed, 1 broken)
**Status**: COMPLETELY BROKEN
**Priority**: LOW
**Invocations**:
- Line 246: topic-naming-agent (MISSING EXECUTE NOW) ✗

---

#### /todo (2 Task blocks: 0 fixed, 2 broken)
**Status**: COMPLETELY BROKEN
**Priority**: MEDIUM
**Invocations**:
- Line 423: todo-analyzer (MISSING EXECUTE NOW) ✗
- Line 1058: todo-analyzer (MISSING EXECUTE NOW) ✗

---

#### /optimize-claude (6 Task blocks: 0 fixed, 6 broken)
**Status**: COMPLETELY BROKEN
**Priority**: LOW
**Invocations**:
- Line 273: topic-naming-agent (MISSING EXECUTE NOW) ✗
- Line 463: claude-md-analyzer (MISSING EXECUTE NOW) ✗
- Line 483: docs-structure-analyzer (MISSING EXECUTE NOW) ✗
- Line 546: docs-bloat-analyzer (MISSING EXECUTE NOW) ✗
- Line 572: docs-accuracy-analyzer (MISSING EXECUTE NOW) ✗
- Line 631: cleanup-plan-architect (MISSING EXECUTE NOW) ✗

---

#### /convert-docs (1 Task block: 1 fixed, 0 broken)
**Status**: FULLY FIXED
**Priority**: LOW
**Invocations**:
- Line 250: doc-converter (HAS EXECUTE NOW) ✓

---

## Agent Invocation Breakdown

### By Agent Type

| Agent Type | Total Invocations | Fixed | Broken | Fix Rate |
|------------|-------------------|-------|--------|----------|
| topic-naming-agent | 5 | 1 | 4 | 20% |
| research-specialist | 3 | 3 | 0 | 100% |
| plan-architect | 6 | 5 | 1 | 83% |
| implementer-coordinator | 2 | 1 | 1 | 50% |
| test-executor | 1 | 0 | 1 | 0% |
| debug-analyst | 2 | 2 | 0 | 100% |
| repair-analyst | 1 | 1 | 0 | 100% |
| spec-updater | 1 | 1 | 0 | 100% |
| todo-analyzer | 2 | 0 | 2 | 0% |
| complexity-estimator | 2 | 0 | 2 | 0% |
| errors-analyst | 1 | 0 | 1 | 0% |
| claude-md-analyzer | 1 | 0 | 1 | 0% |
| docs-structure-analyzer | 1 | 0 | 1 | 0% |
| docs-bloat-analyzer | 1 | 0 | 1 | 0% |
| docs-accuracy-analyzer | 1 | 0 | 1 | 0% |
| cleanup-plan-architect | 1 | 0 | 1 | 0% |
| doc-converter | 1 | 1 | 0 | 100% |
| unknown | 3 | 0 | 3 | 0% |

### Pattern Observations

1. **topic-naming-agent** has the worst fix rate (20%) - consistently missed in partial fixes
2. **research-specialist**, **debug-analyst**, **repair-analyst**, **spec-updater**, **doc-converter** are 100% fixed
3. **plan-architect** is mostly fixed (83%) - only expand/collapse utility commands remain broken
4. Utility commands have 0% fix rate across all specialized agents

## Delegation Pattern Classification

### Hard Barrier Pattern (Research → Plan workflow)
- **/plan**: research-specialist → plan-architect
- **/research**: research-specialist only
- **/revise**: research-specialist → plan-architect
- **/debug**: research-specialist → plan-architect → debug-analyst
- **/repair**: repair-analyst → plan-architect

### Orchestrator Pattern (Wave-based execution)
- **/build**: implementer-coordinator → spec-updater → test-executor → debug-analyst
- **/implement**: implementer-coordinator (with iteration loop)

### Analyzer Pattern (Report generation)
- **/errors**: errors-analyst
- **/todo**: todo-analyzer
- **/optimize-claude**: Multiple analyzer agents

### Utility Pattern (Single agent task)
- **/expand**: plan-architect (phase expansion)
- **/collapse**: plan-architect (phase collapse)
- **/setup**: topic-naming-agent
- **/convert-docs**: doc-converter

## Priority Recommendations

### Phase 2: Fix High-Priority Commands (CRITICAL)
Fix these commands first (19 Task blocks):
1. **/plan** - 1 broken (topic-naming-agent)
2. **/research** - 1 broken (topic-naming-agent)
3. **/build** - 1 broken (test-executor)
4. **/implement** - 1 broken (implementer-coordinator iteration loop)

Total: 4 broken Task blocks to fix

### Phase 3: Fix Edge Cases + Utility Commands (HIGH)
Fix these commands second (18 Task blocks):
1. **/test** - 2 instructional text patterns (different fix approach)
2. **/errors** - 2 broken
3. **/expand** - 4 broken
4. **/collapse** - 4 broken
5. **/setup** - 1 broken
6. **/todo** - 2 broken
7. **/optimize-claude** - 6 broken

Total: 21 broken patterns to fix

## Risk Assessment

### High Risk Commands (Immediate Impact)
- **/plan**: Core workflow, topic naming breaks directory structure
- **/build**: Test executor prevents test failure handling
- **/implement**: Iteration loop breaks multi-iteration workflows

### Medium Risk Commands (Moderate Impact)
- **/research**: Topic naming affects directory structure
- **/test**: Instructional text pattern prevents proper test delegation
- **/errors**: Error analysis delegation broken
- **/todo**: TODO analysis delegation broken

### Low Risk Commands (Limited Impact)
- **/expand**, **/collapse**: Rarely used utility commands
- **/setup**: One-time initialization command
- **/optimize-claude**: Development/maintenance command

## Success Metrics

| Metric | Current | Target | Delta |
|--------|---------|--------|-------|
| Commands with 100% fix rate | 4/15 (27%) | 15/15 (100%) | +11 |
| Task blocks fixed | 13/35 (37%) | 35/35 (100%) | +22 |
| High-priority commands fixed | 3/7 (43%) | 7/7 (100%) | +4 |
| Edge case patterns handled | 0/3 | 3/3 | +3 |

## Next Steps

1. **Phase 2**: Fix 4 broken Task blocks in high-priority commands (plan, research, build, implement)
2. **Phase 3**: Fix 21 broken patterns in edge case + utility commands
3. **Phase 4**: Create validation/enforcement tools (linter, pre-commit hooks)
4. **Phase 5**: Update documentation with Task invocation requirements

## Appendix: Fully Fixed Commands (No Action Required)

The following commands are already 100% compliant and serve as reference examples:
- **/debug** (4/4 fixed)
- **/repair** (2/2 fixed)
- **/revise** (2/2 fixed)
- **/convert-docs** (1/1 fixed)

These can be used as templates for fixing the remaining commands.
