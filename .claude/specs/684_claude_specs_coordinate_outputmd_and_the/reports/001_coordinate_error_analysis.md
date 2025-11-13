# Coordinate Command Error Analysis

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Coordinate command error output root cause analysis
- **Report Type**: Diagnostic analysis
- **Complexity Level**: 2

## Executive Summary

Analysis of the coordinate command error output reveals two critical failure modes: (1) incomplete workflow scope handling where `research-and-revise` workflow scope causes "Unknown workflow scope" errors in two case statements (lines 869-882 and 1304-1347 in coordinate.md), and (2) Bash tool preprocessing issues that escape command substitutions incorrectly, converting `$(cat "$FILE")` into `\$ ( cat '' )`, making bash blocks unexecutable. The first error caused premature workflow termination after research phase, while the second prevented subsequent attempts to query workflow state.

## Findings

### Error Category 1: Incomplete Workflow Scope Case Statements

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Error Pattern**:
```
ERROR: Unknown workflow scope: research-and-revise
```

**Root Cause Analysis**:

The coordinate command has incomplete case statement coverage for the `research-and-revise` workflow scope. While the scope is:
- Properly detected by LLM classifier (lines 678_coordinate_haiku_classification)
- Recognized in library sourcing (line 214: `research-and-plan|research-and-revise`)
- Configured in state machine terminal state (workflow-state-machine.sh:426-428)

It is **missing** in two critical transition case statements:

1. **Research Phase Transition (lines 869-882)**:
   - Missing `research-and-revise` case in "Next Action" display
   - Missing `research-and-revise` in state transition logic (lines 887-908)
   - Current: `research-and-plan|full-implementation|debug-only` (line 897)
   - Should include: `research-and-plan|research-and-revise|full-implementation|debug-only`

2. **Planning Phase Transition (lines 1304-1347)**:
   - Missing `research-and-revise` case in "Next Action" display (1304-1314)
   - Missing `research-and-revise` in state transition logic (1319-1347)
   - Should have separate handler for revision workflows vs planning workflows

**Impact**:
- Workflow terminates with exit code 1 after successful research phase completion
- User cannot proceed to revision phase despite research reports being created successfully
- All verification checkpoints pass (2/2 reports verified), but workflow aborts before invoking revision-specialist agent

**Evidence**:
```
coordinate_output.md:519-522
ERROR: Unknown workflow scope: research-and-revise
```

This occurred immediately after successful verification:
```
Verification Summary:
  - Success: 2/2 reports
  - Failures: 0 reports
✓ All 2 research reports verified successfully
```

### Error Category 2: Bash Tool Command Substitution Escaping Issues

**Location**: Bash tool preprocessing layer (not in coordinate.md source)

**Error Pattern**:
```
/run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `('
```

**Root Cause Analysis**:

When the LLM attempted to query workflow state after the first error, bash blocks using command substitution were incorrectly preprocessed:

**Original bash code**:
```bash
WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
```

**Bash tool preprocessing transformed it to**:
```bash
WORKFLOW_ID=\$ ( cat '' )
if \[ -z '' \] ; then
  'CLAUDE_PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)'
fi
```

**Specific transformations identified**:
1. Command substitution `$(...)` escaped to `\$ ( ... )`
2. Variable expansions replaced with empty strings: `"$FILE"` → `''`
3. Test operators escaped: `[ -z` → `\[ -z`
4. Entire command strings wrapped in single quotes (preventing execution)

**Impact**:
- Bash blocks become syntactically invalid
- Unable to query workflow state to debug the first error
- User forced to work around by reading files directly and invoking agents manually

**Evidence**:
```
coordinate_output.md:114-124 (first occurrence)
coordinate_output.md:131-140 (retry attempt with set +H, still failed)
```

### Error Category 3: Workflow Recovery - Partially Successful

**Observation**: After encountering both errors, the LLM successfully recovered by:
1. Using Read tool to examine the plan file directly
2. Manually invoking the revision-specialist agent via Task tool
3. Verifying revision completion with simple bash commands

**Success metrics from recovery**:
- Research reports created: 2/2 (41,226 and 22,636 bytes)
- Plan revision completed: 41,923 bytes (Revision 4)
- Backup created: 45,451 bytes

**Implications**:
- Error #1 is recoverable with manual agent invocation
- Error #2 forces workarounds but doesn't prevent task completion
- However, both errors prevent fully automated workflow orchestration

### Workflow Scope Coverage Analysis

**Complete coverage check across coordinate.md**:

✓ **Properly handled** (4 locations):
1. Line 210-223: Library sourcing case statement (includes `research-and-revise`)
2. workflow-state-machine.sh:426-428: Terminal state configuration (includes `research-and-revise`)

✗ **Missing handlers** (4 locations):
1. Line 869-882: Research completion "Next Action" display
2. Line 887-908: Research-to-Planning state transition
3. Line 1304-1314: Planning completion "Next Action" display
4. Line 1319-1347: Planning terminal/continuation state transition

### Code Pattern Analysis

**Pattern 1: Research phase transition** (lines 897-903):
```bash
research-and-plan|full-implementation|debug-only)
  # Continue to planning
  echo "Transitioning from $CURRENT_STATE to $STATE_PLAN"
  sm_transition "$STATE_PLAN"
```

**Should be**:
```bash
research-and-plan|research-and-revise|full-implementation|debug-only)
  # Continue to planning
  echo "Transitioning from $CURRENT_STATE to $STATE_PLAN"
  sm_transition "$STATE_PLAN"
```

**Pattern 2: Planning phase transition** (lines 1320-1327):
```bash
research-and-plan)
  # Terminal state reached
  sm_transition "$STATE_COMPLETE"
```

**Should include**:
```bash
research-and-plan|research-and-revise)
  # Terminal state reached for planning-only workflows
  sm_transition "$STATE_COMPLETE"
```

## Recommendations

### Critical Fix 1: Add research-and-revise to Research Phase Transition

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 869-908

**Required changes**:

1. Add display case (line ~874):
```bash
research-and-revise)
  echo "    - Proceeding to: Revision phase (revising existing plan)"
  ;;
```

2. Update transition case (line 897):
```bash
# Change FROM:
research-and-plan|full-implementation|debug-only)

# Change TO:
research-and-plan|research-and-revise|full-implementation|debug-only)
```

### Critical Fix 2: Add research-and-revise to Planning Phase Transition

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`
**Lines**: 1304-1347

**Required changes**:

1. Add display case (line ~1306):
```bash
research-and-revise)
  echo "    - Proceeding to: Terminal state (revision complete)"
  ;;
```

2. Update terminal state case (line 1320):
```bash
# Change FROM:
research-and-plan)

# Change TO:
research-and-plan|research-and-revise)
```

### Investigation Required: Bash Tool Preprocessing

**Issue**: Command substitution escaping appears to be Bash tool internal issue

**Evidence of preprocessing layer**:
- Error messages reference `/run/current-system/sw/bin/bash: eval: line 1:`
- Suggests bash code is being passed through `eval` after preprocessing
- Transformation appears systematic (not random corruption)

**Recommended investigation**:
1. Check if Bash tool uses `eval` for execution
2. Review how variable expansions are handled in preprocessing
3. Test if issue is specific to certain bash constructs (command substitution, variable expansion)
4. Verify if `set +H` (history expansion disable) is related to escaping logic

**Workaround for users**:
- Avoid complex command substitutions in workflow state queries
- Use Read tool to access state files directly when bash blocks fail
- Break complex bash blocks into smaller, simpler operations

### Testing Recommendations

**Unit test coverage needed**:
1. Test `research-and-revise` workflow end-to-end
2. Test all workflow scope case statements for completeness
3. Add regression test for workflow scope transition logic

**Test case template**:
```bash
# Test research-and-revise workflow transitions
WORKFLOW_SCOPE="research-and-revise"
# Should NOT produce "Unknown workflow scope" error
# Should transition: initialize → research → plan → complete
```

**Files to update**:
- `.claude/tests/test_coordinate_critical_bugs.sh` (add research-and-revise test)
- `.claude/tests/test_workflow_scope_detection.sh` (verify all scopes handled)

## References

### Source Files Analyzed

- `/home/benjamin/.config/.claude/specs/coordinate_output.md` (lines 1-523)
  - Line 519-522: "Unknown workflow scope" error location
  - Lines 114-124, 131-140: Bash preprocessing errors
- `/home/benjamin/.config/.claude/commands/coordinate.md`
  - Line 214: Correct `research-and-revise` handling in library sourcing
  - Lines 869-908: Missing `research-and-revise` in research phase transition
  - Lines 1304-1347: Missing `research-and-revise` in planning phase transition
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`
  - Lines 426-428: Correct terminal state configuration for `research-and-revise`
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`
  - Lines 195-204: Validation includes `research-and-revise` scope

### Related Specifications

- Spec 678: `coordinate_haiku_classification` - LLM-based workflow classification (correctly detects research-and-revise)
- Spec 683: `coordinate_critical_bug_fixes` - Previous coordinate bug fixes
- Spec 677: `command_agent_optimization` - Plan being revised in test case

### Error Frequency

**Error #1 (Unknown workflow scope)**:
- Occurs 100% of time for `research-and-revise` workflows
- Severity: Critical (blocks workflow completion)
- First failure point: After research phase completion

**Error #2 (Bash preprocessing)**:
- Occurs when using command substitution in workflow state queries
- Severity: High (prevents state inspection, forces workarounds)
- Trigger: Complex bash blocks with `$(...)` syntax
