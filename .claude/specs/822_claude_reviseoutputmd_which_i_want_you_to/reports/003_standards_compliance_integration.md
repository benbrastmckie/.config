# Standards Compliance and Integration Patterns

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Standards compliance analysis for /revise command fixes
- **Report Type**: pattern recognition

## Executive Summary

The /revise command errors violate two key infrastructure standards: (1) the bash block execution model's subprocess isolation patterns documented in `.claude/docs/concepts/bash-block-execution-model.md`, and (2) output formatting standards that require library sourcing validation. Fixes must integrate naturally with existing patterns used by similar commands (/plan, /debug, /research) and follow the established library re-sourcing pattern with `CLAUDE_PROJECT_DIR` bootstrap. The fix should also address potential eval-related escaping by avoiding the `!` operator in conditional expressions.

## Findings

### Standard 1: Bash Block Execution Model Compliance

**Reference**: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`

The /revise command violates Pattern 4 (Library Re-sourcing with Source Guards):

**Required Pattern** (from bash-block-execution-model.md lines 435-458):
```bash
# At start of EVERY bash block:
set +H  # CRITICAL: Disable history expansion

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
```

**Current /revise Implementation** (Part 3 Research Phase, lines 285-290):
```bash
set +H  # CRITICAL: Disable history expansion

# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
```

**Violation**: The code assumes `CLAUDE_PROJECT_DIR` is already set, but it must be re-detected in every bash block due to subprocess isolation.

### Standard 2: Output Formatting Standards Compliance

**Reference**: `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md`

**Library Sourcing Suppression Pattern** (lines 46-51):
```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Current /revise Implementation**: No validation after sourcing; errors appear as "command not found" instead of clear failure messages.

### Standard 3: Similar Command Patterns Analysis

Examined how other commands handle the bootstrap pattern:

**plan.md** (lines 58-80):
```bash
# Detect project directory (bootstrap pattern)
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
```

**debug.md** (lines 37-59):
Same pattern as plan.md - includes explicit bootstrap before any library sourcing.

**research.md** (lines 56-78):
Same pattern - consistent across all commands.

**Conclusion**: All similar commands include the `CLAUDE_PROJECT_DIR` bootstrap in their Part 2 bash blocks, but /revise is missing it in Part 3 (Research Phase).

### Standard 4: Anti-Pattern Avoidance

**Reference**: bash-block-execution-model.md lines 925-978 (Anti-Pattern 5: Using BASH_SOURCE)

The errors show that the library sourcing pattern fails when `CLAUDE_PROJECT_DIR` is not set:

**Evidence** from revise-output.md:
```
Specs Directory: .
Research Directory: ./reports
```

These relative paths indicate `CLAUDE_PROJECT_DIR` resolved to empty string, causing all subsequent path operations to use relative paths incorrectly.

### Standard 5: Task Tool Subprocess Isolation

**Reference**: bash-block-execution-model.md lines 49-196

The /revise command invokes agents via Task tool:
- Line 339-359: Research Specialist agent
- Line 477-499: Plan Architect agent

Both Task invocations use `${CLAUDE_PROJECT_DIR}` in their prompt, which requires this variable to be correctly set in the parent bash block context.

### Standard 6: Eval Escaping Behavior

**Issue**: The error messages show `eval: line 196` which indicates Claude Code's execution mechanism uses eval.

**Error Pattern**:
```
/run/current-system/sw/bin/bash: eval: line 196: `  if [[ \! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then'
```

**Standard Pattern**: Use `!=` operator instead of `!` to avoid escaping issues:

Current (problematic):
```bash
if [[ ! "$VAR" = /* ]]; then
```

Recommended (avoids ! operator):
```bash
if [[ "$VAR" != /* ]]; then
```

This aligns with defensive programming patterns to avoid special characters that may be escaped during eval.

## Integration Patterns

### Pattern A: Bootstrap Block Structure

All subsequent bash blocks (after Part 1/Part 2) should follow this structure:

```bash
set +H  # CRITICAL: Disable history expansion

# 1. Bootstrap CLAUDE_PROJECT_DIR (required in every bash block)
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

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi
export CLAUDE_PROJECT_DIR

# 2. Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# 3. Load workflow state
STATE_ID_FILE="${HOME}/.claude/tmp/revise_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID
load_workflow_state "$WORKFLOW_ID" false
```

### Pattern B: Library Validation Pattern

Add validation after sourcing:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  echo "CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR:-NOT SET}" >&2
  exit 1
}

# Validate function availability
if ! declare -f load_workflow_state >/dev/null; then
  echo "ERROR: state-persistence.sh not properly sourced" >&2
  exit 1
fi
```

### Pattern C: Avoid Eval-Sensitive Operators

Replace all `!` conditionals with equivalent `!=` patterns:

| Current | Replacement |
|---------|-------------|
| `if [[ ! "$VAR" = /* ]]` | `if [[ "$VAR" != /* ]]` |
| `if [[ ! "$VAR" = "" ]]` | `if [[ -n "$VAR" ]]` |
| `if [[ ! -f "$FILE" ]]` | Keep as is (file test, not pattern match) |

The key is avoiding `!` in pattern matching operations which may be affected by eval escaping.

## Recommendations

### Recommendation 1: Apply Bootstrap Pattern to All Subsequent Blocks

**Affected Sections in revise.md**:
- Part 3 (Research Phase Execution): Add bootstrap before lines 288-290
- Part 4: Verify bootstrap exists (currently has it in lines 415-426)
- Part 5: Verify bootstrap exists (currently has it in lines 567-568)

**Template**:
```bash
# Bootstrap CLAUDE_PROJECT_DIR (subprocess isolation)
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

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi
export CLAUDE_PROJECT_DIR
```

### Recommendation 2: Replace Negation Operators

**File**: `/home/benjamin/.config/.claude/commands/revise.md`
**Line 115**: Change from:
```bash
if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
```
To:
```bash
if [[ "$ORIGINAL_PROMPT_FILE_PATH" != /* ]]; then
```

Also apply to other commands:
- debug.md:58
- plan.md:74
- research.md:73

### Recommendation 3: Add Library Sourcing Validation

After each source statement, add function availability check:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
if ! declare -f load_workflow_state >/dev/null 2>&1; then
  echo "ERROR: state-persistence.sh functions not available" >&2
  echo "DIAGNOSTIC: CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR" >&2
  exit 1
fi
```

### Recommendation 4: Document the Fix in Command Comments

Follow WHAT not WHY standard - add brief comments:

```bash
# Bootstrap project directory for subprocess isolation
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  ...
fi

# Source required libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
```

### Recommendation 5: Test Across All Similar Commands

Create a test that validates the bootstrap pattern exists in all orchestration commands:

```bash
# Test all commands have bootstrap pattern
for cmd in plan debug research revise; do
  if ! grep -q "git rev-parse --show-toplevel" ".claude/commands/${cmd}.md"; then
    echo "FAIL: ${cmd}.md missing CLAUDE_PROJECT_DIR bootstrap"
  fi
done
```

## References

- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:435-458` - Pattern 4: Library Re-sourcing
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:925-978` - Anti-Pattern 5: BASH_SOURCE
- `/home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md:46-51` - Library sourcing suppression
- `/home/benjamin/.config/.claude/commands/plan.md:58-80` - Reference bootstrap implementation
- `/home/benjamin/.config/.claude/commands/debug.md:37-59` - Reference bootstrap implementation
- `/home/benjamin/.config/.claude/commands/research.md:56-78` - Reference bootstrap implementation
- `/home/benjamin/.config/.claude/commands/revise.md:115` - Negation operator to replace
- `/home/benjamin/.config/.claude/commands/revise.md:285-290` - Missing bootstrap location

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_claude_reviseoutputmd_which_i_want_you_t_plan.md](../plans/001_claude_reviseoutputmd_which_i_want_you_t_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-19
