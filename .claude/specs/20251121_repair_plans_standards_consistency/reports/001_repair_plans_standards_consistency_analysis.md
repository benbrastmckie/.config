# Repair Plans Standards Consistency Analysis

## Overview

This report analyzes three implementation plans for consistency with `.claude/docs/` standards and with each other, providing implementation order recommendations.

**Plans Analyzed**:
1. `20251121_error_analysis_repair/plans/001_error_analysis_repair_plan.md` - Exit code 127 and library sourcing fixes
2. `896_error_logging_infrastructure_migration/plans/001_error_logging_infrastructure_plan.md` - Error logging infrastructure enhancements
3. `899_repair_plans_missing_elements_impl/plans/001_repair_plans_missing_elements_impl_plan.md` - Build iteration infrastructure

## Executive Summary

### Standards Compliance Assessment

| Plan | Overall Compliance | Critical Issues | Minor Issues |
|------|-------------------|-----------------|--------------|
| 001_error_analysis_repair | HIGH | 0 | 2 |
| 001_error_logging_infrastructure | HIGH | 0 | 1 |
| 001_repair_plans_missing_elements_impl | MEDIUM | 1 | 3 |

### Implementation Order Recommendation

**CANNOT implement in parallel** - Plans have implicit dependencies.

**Recommended Order**:
1. **First**: `001_error_analysis_repair_plan.md` (library sourcing fixes)
2. **Second**: `001_error_logging_infrastructure_plan.md` (error logging enhancements)
3. **Third**: `001_repair_plans_missing_elements_impl_plan.md` (build iteration)

**Rationale**: Plan 1 fixes the foundation (library sourcing); Plan 2 builds on that foundation (error logging); Plan 3 depends on both working correctly (iteration infrastructure uses both state management and error logging).

---

## Detailed Plan Analysis

### Plan 1: Error Analysis and Repair (001_error_analysis_repair_plan.md)

**Purpose**: Fix exit code 127 errors caused by missing library sourcing in bash blocks

**Standards Compliance**:

| Standard | Compliance | Notes |
|----------|------------|-------|
| Three-tier sourcing pattern | COMPLIANT | Correctly documents mandatory pattern |
| Fail-fast handlers | COMPLIANT | Explicitly requires `\|\| { exit 1 }` |
| Test isolation | COMPLIANT | Uses CLAUDE_TEST_MODE guidance |
| Error logging integration | COMPLIANT | Includes log_command_error examples |
| Output suppression | COMPLIANT | Uses `2>/dev/null` with fail-fast |
| Pre-commit validation | COMPLIANT | References check-library-sourcing.sh |

**Minor Issues**:
1. **Line 161-164**: Loop uses `for cmd in /build /errors...` - should escape forward slashes in grep pattern (`\/build`)
2. **Line 325**: References `validate-all-standards.sh --sourcing` but actual flag may be different

**Consistency with Other Plans**:
- **With Plan 2**: CONSISTENT - Plan 2 depends on Tier 1 library sourcing being fixed
- **With Plan 3**: CONSISTENT - Plan 3 assumes library sourcing works correctly

**Risk Assessment**: LOW - This is foundational work with minimal risk

---

### Plan 2: Error Logging Infrastructure Migration (001_error_logging_infrastructure_plan.md)

**Purpose**: Enhance source-libraries-inline.sh with error logging, add logging to expand.md/collapse.md

**Standards Compliance**:

| Standard | Compliance | Notes |
|----------|------------|-------|
| Three-tier sourcing pattern | COMPLIANT | Documents mandatory pattern in Technical Design |
| Fail-fast handlers | COMPLIANT | Explicitly notes requirement in Phase 1 and 2 |
| Test isolation | COMPLIANT | Includes CLAUDE_TEST_MODE and CLAUDE_SPECS_ROOT |
| Error logging integration | COMPLIANT | Primary focus of plan |
| Agent error protocol | COMPLIANT | Includes parse_subagent_error examples |
| Pre-commit validation | COMPLIANT | References linter validation |
| Output suppression | COMPLIANT | Documents WHICH/WHAT/WHERE structure |

**Minor Issues**:
1. **Line 183-189**: References line numbers in source-libraries-inline.sh that may shift if Plan 1 modifies the file first

**Consistency with Other Plans**:
- **With Plan 1**: CONSISTENT - Plan 2 builds on Plan 1's library sourcing fixes
- **With Plan 3**: CONSISTENT - Plan 3 will use the error logging infrastructure

**Risk Assessment**: LOW - Well-isolated changes to specific files

**Implicit Dependency on Plan 1**: Plan 2's Phase 1 modifies `source-libraries-inline.sh` to add error logging to function validation. If Plan 1 hasn't fixed library sourcing issues first, the error logging additions may not work correctly.

---

### Plan 3: Build Iteration Infrastructure (001_repair_plans_missing_elements_impl_plan.md)

**Purpose**: Add iteration loop, context monitoring, and checkpoint integration to /build

**Standards Compliance**:

| Standard | Compliance | Notes |
|----------|------------|-------|
| Three-tier sourcing pattern | PARTIAL | Not explicitly mentioned in implementation |
| Fail-fast handlers | NOT ADDRESSED | Implementation snippets lack sourcing |
| Test isolation | PARTIAL | Test examples don't use CLAUDE_TEST_MODE |
| Error logging integration | COMPLIANT | Uses log_command_error in examples |
| Output suppression | PARTIAL | Some echo statements to stderr not suppressed |
| Pre-commit validation | NOT ADDRESSED | No linter validation steps in testing |

**Critical Issue**:
1. **Lines 172-217**: Implementation pattern for iteration loop does NOT include library sourcing. When implemented, this code will run in bash blocks that need the three-tier sourcing pattern. The plan assumes libraries are already sourced but doesn't enforce this.

**Minor Issues**:
1. **Lines 225-232**: Test descriptions don't include test isolation patterns (CLAUDE_TEST_MODE, temp directories)
2. **Lines 264-279**: Context estimation function doesn't address library dependencies
3. **Phase 4 Documentation**: Plan estimates ~280 lines of new documentation but doesn't reference executable/documentation separation pattern

**Consistency with Other Plans**:
- **With Plan 1**: DEPENDENT - Plan 3's implementation will fail without Plan 1's library sourcing fixes
- **With Plan 2**: DEPENDENT - Plan 3's error logging assumes the infrastructure from Plan 2 works

**Risk Assessment**: MEDIUM - Large scope, multiple integration points

---

## Cross-Plan Dependency Analysis

### Dependency Graph

```
Plan 1 (Library Sourcing)
    |
    v
Plan 2 (Error Logging)
    |
    v
Plan 3 (Build Iteration)
```

### Why Parallel Implementation is NOT Recommended

1. **Plan 1 -> Plan 2**: Plan 2's Phase 1 adds error logging to `source-libraries-inline.sh` function validation. This requires the fail-fast handlers from Plan 1 to be in place, otherwise the error logging itself may fail silently.

2. **Plan 1 -> Plan 3**: Plan 3's iteration loop code (lines 172-217) runs in bash blocks. Without Plan 1's library sourcing fixes, this code will produce exit code 127 errors when calling `log_command_error`, `save_completed_states_to_state`, etc.

3. **Plan 2 -> Plan 3**: Plan 3's Phase 5 testing assumes error logging works correctly. If Plan 2 hasn't completed the expand.md/collapse.md integration, tests that verify error logging may produce incomplete results.

### Shared File Conflicts

| File | Plan 1 | Plan 2 | Plan 3 |
|------|--------|--------|--------|
| /build.md | Modifies sourcing | - | Major modifications |
| /research.md | Modifies sourcing | Optional migration | - |
| /errors.md | Modifies sourcing | - | - |
| /expand.md | - | Adds error logging | - |
| /collapse.md | - | Adds error logging | - |
| source-libraries-inline.sh | - | Adds error logging | - |

**Conflict Risk**: LOW if implemented sequentially, MEDIUM if attempted in parallel.

---

## Recommendations

### Implementation Order

**Phase A: Foundation (Plan 1)**
- Duration: ~5.5 hours (as estimated in plan)
- Complete ALL phases before moving to Phase B
- Validation: `bash .claude/scripts/lint/check-library-sourcing.sh` returns 0

**Phase B: Infrastructure (Plan 2)**
- Duration: ~6 hours (as estimated in plan)
- Complete Phases 1-2 before Phase C
- Phase 3 (research.md migration) can be deferred
- Validation: Error logging coverage reaches 100%

**Phase C: Iteration Support (Plan 3)**
- Duration: ~17 hours (as estimated in plan)
- Can proceed once Phase A and Phase B (Phases 1-2) are complete
- Validation: /build handles multi-phase plans

### Plan Improvements Needed

**Plan 3 Improvements (Before Implementation)**:
1. Add three-tier sourcing pattern to iteration loop implementation section
2. Add test isolation patterns (CLAUDE_TEST_MODE) to test examples
3. Add pre-commit validation step to Phase 5
4. Reference code-standards.md for bash block requirements

### Estimated Total Duration

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase A (Plan 1) | 5.5 hours | 5.5 hours |
| Phase B (Plan 2, Phases 1-2) | 4 hours | 9.5 hours |
| Phase C (Plan 3) | 17 hours | 26.5 hours |
| Phase B (Plan 2, Phase 3 - optional) | 2 hours | 28.5 hours |

**Note**: These estimates assume focused implementation time. Actual wall-clock time will be longer due to context switches, reviews, and unexpected issues.

---

## Appendix: Standards Reference

### Key Standards That Apply to All Plans

1. **Mandatory Bash Block Sourcing Pattern** ([code-standards.md#mandatory-bash-block-sourcing-pattern](../../docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern))
   - All bash blocks MUST follow three-tier sourcing
   - Tier 1 libraries require fail-fast handlers

2. **Test Isolation Standards** ([testing-protocols.md#test-isolation-standards](../../docs/reference/standards/testing-protocols.md#test-isolation-standards))
   - CLAUDE_TEST_MODE=1 for test suites
   - CLAUDE_SPECS_ROOT and CLAUDE_PROJECT_DIR must both point to temp directories

3. **Error Logging Standards** ([error-handling.md](../../docs/concepts/patterns/error-handling.md))
   - All commands must integrate log_command_error
   - Subagent errors must use parse_subagent_error

4. **Output Suppression Patterns** ([code-standards.md#output-suppression-patterns](../../docs/reference/standards/code-standards.md#output-suppression-patterns))
   - Library sourcing uses `2>/dev/null || { exit 1 }`
   - Comments describe WHAT not WHY

### Enforcement Tools

- `check-library-sourcing.sh` - Validates three-tier sourcing
- `lint_error_suppression.sh` - Validates error suppression patterns
- `lint_bash_conditionals.sh` - Validates preprocessing-safe conditionals
- `validate-all-standards.sh --all` - Runs all validators
