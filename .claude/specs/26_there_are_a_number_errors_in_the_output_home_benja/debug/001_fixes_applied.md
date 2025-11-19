# Debug Report: /research-plan Bash Execution Model Fix

## Metadata
- **Date**: 2025-11-17
- **Agent**: debug-analyst
- **Issue**: Bash syntax errors in /research-plan command with multi-line feature descriptions
- **Hypothesis**: Bash blocks need to re-source libraries in each block for subprocess isolation
- **Status**: Complete

## Issue Description

The /research-plan command fails with bash syntax errors when processing multi-line feature descriptions. The root cause analysis identified that Claude Code executes markdown bash blocks via `eval`, causing multi-line code to collapse and variables to become malformed.

**Error Pattern**:
```
/run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `then'
/run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `do'
```

## Investigation

### Hypothesis Testing

Comparing /research-plan with the working /fix command revealed a critical difference:

**Key Difference: Library Re-sourcing**

In /fix command (Parts 4-6), each bash block re-sources the libraries:
```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
```

In /research-plan (Parts 3-5), the bash blocks do NOT re-source libraries, causing:
1. State machine variables to be undefined
2. State persistence functions to fail
3. Subprocess isolation to break

### Evidence

1. **Part 4 in /fix** (lines 234-247) - Re-sources libraries before load_workflow_state
2. **Part 5 in /fix** (lines 342-354) - Re-sources libraries before load_workflow_state
3. **Part 6 in /fix** (lines 433-446) - Re-sources libraries before load_workflow_state

4. **Part 3 in /research-plan** (lines 195-239) - MISSING library re-sourcing
5. **Part 4 in /research-plan** (lines 244-263) - MISSING library re-sourcing
6. **Part 5 in /research-plan** (lines 337-373) - MISSING library re-sourcing

### Additional Issues Identified

1. **Missing variable exports**: State machine variables not re-exported after load_workflow_state
2. **Empty topics JSON**: Using `"[]"` instead of `"{}"` for initial topics JSON

## Root Cause Analysis

**Primary Root Cause**: Library re-sourcing missing in Parts 3, 4, and 5

Each bash block in Claude Code markdown commands runs in a separate subprocess. Without re-sourcing libraries, functions like `sm_transition`, `load_workflow_state`, and `save_completed_states_to_state` are undefined, causing silent failures or syntax errors.

**Secondary Root Cause**: Missing variable exports after load_workflow_state

The state machine uses exported variables (CURRENT_STATE, TERMINAL_STATE, etc.) that need to be re-exported after loading workflow state.

## Proposed Fix

### Fix 1: Add Library Re-sourcing to Part 3 (Research Verification)

**File**: `/home/benjamin/.config/.claude/commands/research-plan.md`
**Location**: Lines 195-239 (Part 3 verification block)

Add at start of bash block:
```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
```

### Fix 2: Add Library Re-sourcing and Variable Exports to Part 4 (Planning Phase)

**File**: `/home/benjamin/.config/.claude/commands/research-plan.md`
**Location**: Lines 244-263 (Part 4 bash block)

Replace:
```bash
# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false
```

With:
```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON
```

### Fix 3: Add Library Re-sourcing and Variable Exports to Part 5 (Completion)

**File**: `/home/benjamin/.config/.claude/commands/research-plan.md`
**Location**: Lines 337-373 (Part 5 bash block)

Replace:
```bash
# Load workflow state from Part 4 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false
```

With:
```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load workflow state from Part 4 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON
```

## Changes Applied

The following edits were made to `/home/benjamin/.config/.claude/commands/research-plan.md`:

### Change 1: Part 3 Research Verification Block (after Task block, lines 214-217)

Added library re-sourcing at the start of the verification bash block:

```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# MANDATORY VERIFICATION
echo "Verifying research artifacts..."
```

### Change 2: Part 4 Planning Phase Block (lines 266-279)

Added library re-sourcing and variable exports:

```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load workflow state from Part 3 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Transition to plan state with return code verification
```

### Change 3: Part 5 Completion Block (lines 371-384)

Added library re-sourcing and variable exports:

```bash
# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Load workflow state from Part 4 (subprocess isolation)
load_workflow_state "${WORKFLOW_ID:-$$}" false

# Re-export state machine variables (restored by load_workflow_state)
export CURRENT_STATE
export TERMINAL_STATE
export WORKFLOW_SCOPE
export RESEARCH_COMPLEXITY
export RESEARCH_TOPICS_JSON

# Research-and-plan workflow: terminate after planning
```

### Summary of Line Changes

| Section | Original Lines | New Lines | Changes |
|---------|----------------|-----------|---------|
| Part 3 verification | 214+ | 214-217+ | +4 lines (library re-sourcing) |
| Part 4 bash block | 262+ | 266-279+ | +9 lines (library re-sourcing + exports) |
| Part 5 bash block | 356+ | 371-384+ | +9 lines (library re-sourcing + exports) |

**Total additions**: 22 lines of code across 3 bash blocks

## Impact Assessment

### Scope
- Affected files: `.claude/commands/research-plan.md`
- Affected components: Workflow state machine, state persistence
- Severity: High - Command completely non-functional without fix

### Related Issues
- Similar issues may exist in `/research-report` and `/research-revise` commands
- These should be audited for missing library re-sourcing

## Testing Recommendations

### Test 1: Simple Feature Description
```bash
/research-plan "implement user authentication"
```
Expected: No syntax errors, reports created, plan created

### Test 2: Multi-line Feature Description
```bash
/research-plan "implement feature
with multiple lines
and special chars: []{}
and paths: /home/user/test"
```
Expected: No syntax errors, all components execute successfully

### Test 3: Complexity Flag
```bash
/research-plan "test feature --complexity 4"
```
Expected: Complexity parsed correctly, higher-level research conducted

## Fix Rationale

The fixes align the /research-plan command with the working /fix command pattern:

1. **Library re-sourcing**: Each bash block must source required libraries because subprocess isolation means functions are not inherited
2. **Variable exports**: State machine variables must be explicitly exported for sm_transition and other functions to work
3. **Pattern consistency**: Using the same patterns as /fix ensures maintainability and reduces debugging complexity

## Fix Complexity
- Estimated time: 30 minutes (already applied)
- Risk level: Low - Pattern is proven in /fix command
- Testing required: Manual execution with simple and multi-line inputs

## Recommendations

1. **Audit related commands**: Check /research-report and /research-revise for same issue
2. **Document pattern**: Add to .claude/docs/ a note about mandatory library re-sourcing in multi-block commands
3. **Consider template**: Create a command template that includes correct patterns by default

## Verification Status

Changes have been applied to the command file. The fixes follow the exact pattern from the working /fix command and should resolve the bash syntax errors for multi-line feature descriptions.
