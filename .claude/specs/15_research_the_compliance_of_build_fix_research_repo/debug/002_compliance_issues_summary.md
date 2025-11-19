# Compliance Issues Summary: Research and Debug Commands

## Metadata
- **Date**: 2025-11-17
- **Commands Analyzed**: /build, /fix, /research-report, /research-plan, /research-revise
- **Analysis Method**: Automated compliance research + runtime testing
- **Reports Referenced**: 5 compliance analysis reports in ../reports/
- **Critical Bugs Discovered**: 2 (agent invocation, bash block variable scope)

## Overview

Comprehensive analysis of 5 research-focused and debug-focused workflow commands reveals consistent compliance patterns: **excellent state-based orchestration architecture** combined with **critical gaps in agent invocation patterns, bash block variable scope, and execution enforcement**.

**Average Compliance Score**: 60/100 (updated from 72.6 to include bash block violations)

## Critical Issues Summary

### Issue 1: Agent Invocation Pattern Violations (CRITICAL)

**Severity**: CRITICAL
**Prevalence**: 100% of commands (13 agent invocations total)
**Compliance**: 25%

**Problem**: Commands use echo statements to document what should happen, rather than executable Task tool invocations.

**Pattern Found** (all 13 instances):
```bash
echo "EXECUTE NOW: USE the Task tool to invoke [agent-name] agent"
echo ""
echo "YOU MUST:"
echo "1. Read and follow ALL behavioral guidelines from: [path]"
echo "2. Return completion signal: [SIGNAL]"
```

**Expected Pattern** (from execution-enforcement-guide.md):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "[Agent] - [Purpose]"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-name].md

    **ABSOLUTE REQUIREMENT**: [Primary task]
    **CONTEXT**: [Parameters]

    Return completion signal: [SIGNAL]: [VALUE]
  "
}
```

**Impact**:
- File creation reliability: 60-80% (vs 100% with proper invocation)
- Behavioral guideline enforcement: 0% (guidelines not followed)
- Hierarchical pattern compliance: 0% (direct execution instead of delegation)

**Affected Invocations**:
- /build: 2 invocations (implementer-coordinator, debug-analyst)
- /fix: 3 invocations (research-specialist, plan-architect, debug-analyst)
- /research-report: 1 invocation (research-specialist)
- /research-plan: 2 invocations (research-specialist, plan-architect)
- /research-revise: 2 invocations (research-specialist, plan-architect)

**Remediation**: 15 hours (1-1.5 hours × 13 invocations)

---

### Issue 2: Bash Block Variable Scope Violations (CRITICAL - NEW)

**Severity**: CRITICAL
**Prevalence**: 100% of commands (estimated)
**Compliance**: 0%
**Discovery**: Runtime testing of /research-plan (2025-11-17)

**Problem**: Commands assume variables persist across bash blocks, violating subprocess isolation architecture.

**Root Cause**: Each bash block runs as separate subprocess, NOT subshell (per bash-block-execution-model.md:5)

**Example from /research-plan**:

```bash
# Part 3: Research Phase (one subprocess)
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Part 5: Completion (DIFFERENT subprocess)
echo "Specs Directory: $SPECS_DIR"          # EMPTY!
echo "Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"  # EMPTY!
echo "Implementation Plan: $PLAN_PATH"      # EMPTY!
```

**Evidence from Testing**:
- Error: `awk: fatal: cannot open file 'echo'` (awk failed with empty variables)
- Error: `syntax error near unexpected token 'ls'` (malformed bash due to empty substitution)
- Variable values: `SPECS_DIR=/reports` (should be `/home/.../specs/16_topic/reports`)

**Expected Pattern** (bash-block-execution-model.md:226-248):
```bash
# Part 3: After variable declarations
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Part 5: Before variable usage
load_workflow_state "$WORKFLOW_ID"
# Now variables restored: $SPECS_DIR, $PLAN_PATH available
echo "Specs Directory: $SPECS_DIR"  # Works!
```

**Impact**:
- User-visible: Completion summaries show empty values
- Architectural: Violates documented subprocess isolation model
- Testing gap: Works when Claude compensates, fails with documented behavior

**Remediation**: 20 hours (4 hours × 5 commands)

---

### Issue 3: Missing Execution Enforcement Markers (HIGH)

**Severity**: HIGH
**Prevalence**: 100% of commands (26 missing instances)
**Compliance**: 35%

**Problem**: Commands use echo-based documentation instead of enforcement markers

**Missing Markers**:
- "EXECUTE NOW" - 13 instances (agent invocations)
- "MANDATORY VERIFICATION" - 13 instances (verification checkpoints)

**Current Pattern**:
```bash
# Some comment
<bash code block>
```

**Expected Pattern** (execution-enforcement-guide.md):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke agent

**MANDATORY VERIFICATION**: Verify file created at $PATH
```

**Impact**:
- Relies on Claude interpretation rather than enforcement
- Inconsistent execution across different Claude instances
- No formal contract for required operations

**Remediation**: 14 hours across all commands

---

### Issue 4: No Checkpoint Reporting (MEDIUM)

**Severity**: MEDIUM
**Prevalence**: 100% of commands
**Compliance**: 0%

**Problem**: No progress reporting between workflow phases

**Example**:
```bash
# Research phase completes
echo "✓ Research phase complete ($REPORT_COUNT reports created)"

# Planning phase starts IMMEDIATELY (no checkpoint report)
echo "=== Phase 2: Planning ==="
```

**Expected Pattern**:
```bash
# Research phase completes
emit_progress "research_complete" "Created $REPORT_COUNT reports"

# Checkpoint report
echo "CHECKPOINT: Research → Planning transition"
echo "  Reports verified: $REPORT_COUNT"
echo "  Ready for planning phase"

# Planning phase starts
emit_progress "planning_start" "Creating implementation plan"
```

**Impact**:
- Users don't see workflow progression
- No intermediate state visibility
- Harder to debug failures

**Remediation**: 10 hours across all commands

---

### Issue 5: Limited Error Diagnostics (MEDIUM)

**Severity**: MEDIUM
**Prevalence**: Most commands
**Compliance**: 70%

**Problem**: Generic error messages without diagnostic context

**Example**:
```bash
if ! sm_transition "$STATE_PLAN" 2>&1; then
  echo "ERROR: State transition to PLAN failed" >&2
  exit 1
fi
```

**Expected Pattern**:
```bash
if ! sm_transition "$STATE_PLAN" 2>&1; then
  echo "ERROR: State transition to PLAN failed" >&2
  echo "DIAGNOSTIC: Current state: $CURRENT_STATE" >&2
  echo "DIAGNOSTIC: Attempted transition: $STATE_PLAN" >&2
  echo "DIAGNOSTIC: State file: $STATE_FILE" >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - Invalid state transition sequence" >&2
  echo "  - State file corruption" >&2
  exit 1
fi
```

**Impact**:
- Harder to diagnose failures
- Users lack troubleshooting information
- Increased support burden

**Remediation**: 7 hours across all commands

## Compliance Matrix

| Standard Area | /build | /fix | /report | /plan | /revise | Avg | Priority |
|--------------|--------|------|---------|-------|---------|-----|----------|
| **State Machine** | 100% | 100% | 100% | 100% | 100% | 100% | N/A |
| **Bash Block Model** | 0%* | 0%* | 0%* | 0% | 0%* | 0% | **CRITICAL** |
| **Agent Invocation** | 30% | 25% | 20% | 25% | 25% | 25% | **CRITICAL** |
| **Execution Enforcement** | 40% | 35% | 35% | 35% | 35% | 36% | **HIGH** |
| **Error Handling** | 60% | 65% | 70% | 70% | 70% | 67% | MEDIUM |
| **Directory Protocols** | 85% | 95% | 95% | 95% | 95% | 93% | Low |
| **File Verification** | 80% | 95% | 95% | 95% | 95% | 92% | Low |

*Not tested, estimated based on /research-plan pattern

## Remediation Plan Summary

### Critical Priority (46 hours)
1. **Agent Invocation Pattern** - 15 hours
   - Replace 13 echo-based invocations with Task tool calls
   - Implement behavioral injection pattern
   - Test all agent invocations

2. **Bash Block Variable Scope** - 20 hours
   - Analyze all 5 commands for variable persistence issues
   - Implement state persistence using append_workflow_state/load_workflow_state
   - Add subprocess isolation tests

3. **Execution Enforcement Markers** - 14 hours
   - Add "EXECUTE NOW" markers for all agent invocations
   - Add "MANDATORY VERIFICATION" markers for all checkpoints
   - Update command templates

### High Priority (10 hours)
4. **Checkpoint Reporting** - 10 hours
   - Add emit_progress calls between phases
   - Implement checkpoint verification reports
   - Test progress visibility

### Medium Priority (7 hours)
5. **Error Diagnostics** - 7 hours
   - Enhance error messages with diagnostic context
   - Add "POSSIBLE CAUSES" sections
   - Implement structured error reporting

**Total Remediation Effort**: 77 hours

## Testing Strategy

### Unit Tests
- Bash block subprocess isolation
- State persistence across blocks
- Agent invocation patterns
- Error diagnostic completeness

### Integration Tests
- End-to-end workflow execution
- Multi-phase state persistence
- Completion summary output validation
- Error recovery scenarios

### Regression Tests
- Verify fixes don't break existing functionality
- Test backward compatibility
- Validate performance impact

## References

### Compliance Reports
- [001_build_compliance_analysis.md](../reports/001_build_compliance_analysis.md)
- [002_fix_compliance_analysis.md](../reports/002_fix_compliance_analysis.md)
- [003_research_report_compliance_analysis.md](../reports/003_research_report_compliance_analysis.md)
- [004_research_plan_research_revise_compliance.md](../reports/004_research_plan_research_revise_compliance.md)
- [005_compliance_summary_and_recommendations.md](../reports/005_compliance_summary_and_recommendations.md)

### Bug Reports
- [001_bash_block_variable_scope_violations.md](./001_bash_block_variable_scope_violations.md) - Critical architecture violation

### Documentation
- [Bash Block Execution Model](../../docs/concepts/bash-block-execution-model.md)
- [Execution Enforcement Guide](../../docs/guides/execution-enforcement-guide.md)
- [State-Based Orchestration Overview](../../docs/architecture/state-based-orchestration-overview.md)
- [Command Development Guide](../../docs/guides/command-development-guide.md)

## Conclusion

The 5 commands demonstrate strong foundational architecture (state machine, directory protocols) but have critical gaps in agent invocation patterns and bash block variable scope. The bash block variable scope issue is particularly concerning as it:

1. **Violates documented architecture** - Contradicts bash-block-execution-model.md
2. **Creates silent failures** - No errors, just empty output
3. **Has testing gap** - Works when compensated, fails when run as documented
4. **Affects all commands** - Pattern appears systemic across workflow commands

**Priority**: Address bash block variable scope and agent invocation patterns first (35 hours combined), as these are architectural violations affecting reliability and maintainability.
