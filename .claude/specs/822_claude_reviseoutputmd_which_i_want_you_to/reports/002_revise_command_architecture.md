# /revise Command Architecture Analysis

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: /revise command architecture and dependencies
- **Report Type**: codebase analysis

## Executive Summary

The /revise command is a research-and-revise workflow that creates research reports based on revision insights and then modifies an existing implementation plan. It uses a 5-part structure with state machine orchestration, but exhibits critical issues in subprocess isolation patterns where library functions fail to load due to `CLAUDE_PROJECT_DIR` not being properly bootstrapped in subsequent bash blocks. The command has dependencies on state-persistence.sh, workflow-state-machine.sh, and library-version-check.sh, and invokes research-specialist and plan-architect agents.

## Findings

### Command Structure Overview

The /revise command (file: `/home/benjamin/.config/.claude/commands/revise.md`) consists of 5 parts:

| Part | Lines | Purpose | Dependencies |
|------|-------|---------|--------------|
| Part 1 | 24-47 | Capture revision description | None (bootstrap) |
| Part 2 | 49-189 | Read and validate revision description | None (parsing only) |
| Part 3 (Init) | 191-279 | State machine initialization | state-persistence.sh, workflow-state-machine.sh, library-version-check.sh, error-handling.sh |
| Part 3 (Research) | 281-407 | Research phase execution | state-persistence.sh, workflow-state-machine.sh, research-specialist agent |
| Part 4 | 409-547 | Plan revision phase | state-persistence.sh, workflow-state-machine.sh, plan-architect agent |
| Part 5 | 549-606 | Completion and cleanup | state-persistence.sh, workflow-state-machine.sh |

### Library Dependencies

**Required Libraries** (from YAML frontmatter, lines 11-12):
```yaml
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - state-persistence.sh: ">=1.5.0"
```

**Actual Sourced Libraries** (Part 3 Init, lines 221-227):
1. `state-persistence.sh` - State file management, append_workflow_state
2. `workflow-state-machine.sh` - sm_init, sm_transition, sm_current_state
3. `library-version-check.sh` - check_library_requirements
4. `error-handling.sh` - Error handling utilities

### Root Cause: Subprocess Isolation Pattern Violation

**The Critical Error Pattern** (from revise-output.md lines 137-141):
```
load_workflow_state: command not found
sm_transition: command not found
append_workflow_state: command not found
```

**Root Cause Analysis**:

The issue occurs in Part 3 (Research Phase Execution) at lines 285-336. Examining the code:

```bash
# Lines 288-290 (Part 3 Research Phase)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
```

The problem is that `CLAUDE_PROJECT_DIR` must be set BEFORE these source statements execute. The code assumes `CLAUDE_PROJECT_DIR` was exported from the previous bash block, but:

1. Each bash block runs in a new subprocess (Claude Code subprocess isolation)
2. Environment variables from previous blocks are NOT automatically available
3. The command relies on `WORKFLOW_ID` persisted to a file, but `CLAUDE_PROJECT_DIR` is NOT persisted

**Evidence** (revise-output.md lines 145-146):
```
Specs Directory: .
Research Directory: ./reports
```

These relative paths prove `CLAUDE_PROJECT_DIR` was not set, causing the SPECS_DIR derivation at line 326-327 to produce invalid paths.

### Comparison with Similar Commands

**Examining plan.md** (file: `/home/benjamin/.config/.claude/commands/plan.md`):

The plan command has the same structure but includes explicit `CLAUDE_PROJECT_DIR` bootstrap before sourcing libraries:

```bash
# Bootstrap pattern (should be in every subsequent block)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    # Fallback: search upward for .claude/ directory
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
  fi
fi
export CLAUDE_PROJECT_DIR
```

**The /revise command has this bootstrap pattern in Part 3 (Init) at lines 197-218, but it's missing from Part 3 (Research) at lines 285-336.**

### Bash History Expansion Error Analysis

**Error Pattern** (revise-output.md lines 19-25):
```
/run/current-system/sw/bin/bash: eval: line 196: `  if [[ \! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then'
```

The key insight is `eval: line 196`. Claude Code appears to execute bash blocks via `eval`, which causes special character escaping issues. The `!` character is being escaped as `\!` when passed through eval.

**Current Code** (revise.md line 115):
```bash
if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
```

This is correct bash syntax, but when passed through eval, the `!` is escaped. The `set +H` at the start of each block should prevent history expansion, but eval may process the string before `set +H` takes effect.

### Agent Invocation Patterns

**Research Specialist Agent** (Part 3, lines 339-359):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
    ...
  "
}
```

**Plan Architect Agent** (Part 4, lines 477-499):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md
    ...
  "
}
```

These Task invocations depend on `CLAUDE_PROJECT_DIR` being correctly set, which relates to the library sourcing issue.

### State Management Flow

1. **Part 1**: Captures revision description to temp file
2. **Part 2**: Reads and validates description, extracts plan path
3. **Part 3 Init**: Generates `WORKFLOW_ID`, creates state file via `init_workflow_state`
4. **Part 3 Research**: Should load state via `load_workflow_state`, but fails
5. **Part 4**: Should load state and create backup
6. **Part 5**: Should complete workflow and display summary

The state file location is: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`

But when `CLAUDE_PROJECT_DIR` is not set, this resolves to `/.claude/tmp/...` which doesn't exist.

## Recommendations

### Recommendation 1: Add CLAUDE_PROJECT_DIR Bootstrap to All Subsequent Blocks

Every bash block after Part 3 (Init) must include the project directory bootstrap pattern before sourcing libraries:

```bash
# Bootstrap CLAUDE_PROJECT_DIR (required in every bash block due to subprocess isolation)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
  fi
fi
export CLAUDE_PROJECT_DIR

# NOW source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
```

Add this to:
- Part 3 (Research Phase) before lines 288-290
- Part 4 before lines 426 (already has it but should be before any library access)
- Part 5 before lines 567-568

### Recommendation 2: Use Consistent Library Sourcing Pattern

Create a standard pattern for all bash blocks:

```bash
set +H  # Disable history expansion

# 1. Bootstrap project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
export CLAUDE_PROJECT_DIR

# 2. Load workflow state from file
STATE_ID_FILE="${HOME}/.claude/tmp/revise_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null) || {
  echo "ERROR: Cannot read workflow ID" >&2
  exit 1
}
export WORKFLOW_ID

# 3. Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# 4. Load state
load_workflow_state "$WORKFLOW_ID" false
```

### Recommendation 3: Add Library Sourcing Validation

After sourcing each library, validate the expected functions are available:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
if ! declare -f load_workflow_state >/dev/null; then
  echo "ERROR: state-persistence.sh not properly sourced" >&2
  echo "CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR:-NOT SET}" >&2
  exit 1
fi
```

### Recommendation 4: Document the Eval Escaping Behavior

The bash history expansion error (`\!`) appears to be caused by Claude Code's eval mechanism. Document this in the command and use alternative patterns:

Instead of:
```bash
if [[ ! "$VAR" = /* ]]; then
```

Use:
```bash
if [[ "$VAR" != /* ]]; then
```

This avoids the `!` operator entirely.

## References

- `/home/benjamin/.config/.claude/commands/revise.md:1-620` - Complete revise command
- `/home/benjamin/.config/.claude/commands/revise.md:197-218` - Project directory bootstrap (Part 3 Init)
- `/home/benjamin/.config/.claude/commands/revise.md:285-336` - Research phase (missing bootstrap)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:130-169` - init_workflow_state function
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:212-296` - load_workflow_state function
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:321-336` - append_workflow_state function
- `/home/benjamin/.config/.claude/agents/research-specialist.md` - Research specialist agent
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Plan architect agent
- `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md` - Output formatting standards

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_claude_reviseoutputmd_which_i_want_you_t_plan.md](../plans/001_claude_reviseoutputmd_which_i_want_you_t_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-19
