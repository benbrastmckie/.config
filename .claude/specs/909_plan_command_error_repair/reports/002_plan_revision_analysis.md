# Plan Revision Analysis Report

## Metadata

| Field | Value |
|-------|-------|
| Generated | 2025-11-21 |
| Subject | Plan 001_plan_command_error_repair_plan.md |
| Analysis Type | Coverage + Standards Compliance |
| Error Report | 001_plan_error_report.md (908_plan_error_analysis) |

## Executive Summary

The plan at `909_plan_command_error_repair/plans/001_plan_command_error_repair_plan.md` provides good coverage of the core errors identified in the error analysis but has **coverage gaps** for some error patterns and **standards compliance issues** that need correction.

## Coverage Analysis

### Errors Addressed by Plan

| Error Pattern | Count | Plan Coverage | Phase |
|---------------|-------|---------------|-------|
| /etc/bashrc sourcing (exit 127) | 4 | Addressed | Phase 1 |
| append_workflow_state not found (exit 127) | 3 | Addressed | Phase 2 |
| Topic naming agent failures | 6 | Addressed | Phase 3 |
| Classification result parsing | 1 | Addressed | Phase 4 |
| Agent output validation (test) | 3 | Partially addressed | Phase 3 |
| Exit code 1 general failures | 3 | Not explicitly addressed | - |

### Coverage Score: 76% (16/21 errors covered)

### Gap Analysis

**Gap 1: Exit Code 1 General Failures Not Addressed**

The error report identifies 3 errors with exit code 1:
- `return 1` explicit failure
- `REVISION_DETAILS` sed parsing failure
- `research_topics` array validation failure

While Phase 4 addresses the `research_topics` parsing, the `REVISION_DETAILS` sed parsing failure is not covered. This error appears in the `/plan` command output showing:

```
ERROR: State file not found: /home/benjamin/.claude/tmp/state_plan_1763766980.sh
```

This is a state file path inconsistency issue where the code looks for `state_plan_*.sh` but the file is actually named `workflow_plan_*.sh`.

**Gap 2: Test-Related Agent Errors Need Separation**

The plan lumps 3 test-related errors with production agent errors. These test errors are intentional validation tests and should not be counted toward error reduction metrics.

## Standards Compliance Analysis

### Compliant Elements

1. **Metadata section present with required fields**
2. **Research Reports link in metadata** (relative path `../reports/001_plan_error_analysis.md`)
3. **Success Criteria with checkboxes**
4. **Technical Design with architecture diagram**
5. **Phase dependencies declared**
6. **Risk Assessment table**
7. **Rollback Plan section**

### Non-Compliant Elements

**Issue 1: Missing Phase Dependency Syntax**

Per directory-protocols.md, phases should use explicit dependency format:
```markdown
### Phase N: [Phase Name]
**Dependencies**: [] or [1, 2, 3]
```

Current plan uses inline text like `dependencies: [1]` but doesn't follow the standard bold header format.

**Issue 2: Expected Duration Instead of Estimated Time**

Per directory-protocols.md Phase/Wave documentation, the field should be:
```markdown
**Estimated Time**: X-Y hours
```

Plan uses:
```markdown
**Expected Duration**: X hours
```

**Issue 3: Missing Risk Level per Phase**

Per directory-protocols.md, phases should include:
```markdown
**Risk**: Low|Medium|High
```

Current phases don't have individual risk levels.

**Issue 4: Research Report Link Path Incorrect**

The metadata links to `../reports/001_plan_error_analysis.md` but the file is actually named `001_plan_error_report.md` in the 908 spec directory, not in the local reports directory.

The correct link should be:
- Either copy the error report to `909_plan_command_error_repair/reports/` (preferred for co-location)
- Or use the correct cross-spec path

**Issue 5: Structure Level Documentation**

Plan has `Structure Level: 0` which is correct, but should add note that expansion not anticipated (per adaptive planning standards).

## Recommendations

### High Priority Fixes

1. **Add state file path inconsistency fix to Phase 2**
   - The `state_plan_*.sh` vs `workflow_plan_*.sh` naming issue is causing errors
   - Add task to audit and standardize state file naming convention

2. **Update research report link in metadata**
   - Either copy `001_plan_error_report.md` to local `reports/` directory
   - Or fix the relative path to cross-reference correctly

3. **Standardize phase header format**
   - Change `dependencies: [N]` to `**Dependencies**: [N]`
   - Add `**Risk**: Low|Medium|High` to each phase
   - Change `**Expected Duration**` to `**Estimated Time**`

### Medium Priority Fixes

4. **Separate test errors from production errors**
   - Exclude 7 test-related errors from error reduction metrics
   - Adjust success criteria: "Error log noise reduced by >50% for non-test /plan executions"

5. **Add REVISION_DETAILS parsing fix**
   - The sed parsing failure for `REVISION_DETAILS` should be addressed
   - Related to state variable passing between bash blocks

### Low Priority Fixes

6. **Add complexity note**
   - Add "Expansion not anticipated" note per adaptive planning standards

## Conclusion

The plan addresses the core error patterns but needs revision to:
1. Close the state file naming gap (critical issue causing workflow failures)
2. Comply with directory protocols phase format standards
3. Fix research report cross-reference
4. Separate test errors from metrics

After these revisions, the plan will have full coverage of actionable errors (~14 production errors) and comply with .claude/specs/ standards.
