# Command Authoring Standards

Mandatory standards for creating and maintaining executable command files in `.claude/commands/`.

## Table of Contents

1. [Execution Directive Requirements](#execution-directive-requirements)
2. [Task Tool Invocation Patterns](#task-tool-invocation-patterns)
3. [Subprocess Isolation Requirements](#subprocess-isolation-requirements)
4. [State Persistence Patterns](#state-persistence-patterns)
5. [Validation and Testing](#validation-and-testing)

---

## Execution Directive Requirements

### Why Directives Are Necessary

The LLM interprets bare code blocks in markdown files as **documentation or examples**, not executable code. Without explicit execution directives, bash blocks will be read but not executed, causing silent failures where:

- State machines are never initialized
- Variables are never set
- Verification steps are skipped
- Workflows appear to complete but produce no artifacts

### Required Directive Phrases

Every bash code block in a command file MUST be preceded by an explicit execution directive using one of these phrases:

**Primary (Preferred)**:
- `**EXECUTE NOW**:` - Standard imperative directive

**Alternatives**:
- `Execute this bash block:` - Explicit block reference
- `Run the following:` - Clear action instruction
- `**STEP N**:` followed by action verb - Sequential numbering pattern

### Correct Pattern

```markdown
**EXECUTE NOW**: Initialize the state machine and validate configuration:

```bash
set +H  # Disable history expansion
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# ... execution code
```
```

### Anti-Pattern (Causes Silent Failure)

```markdown
## Part 1: Initialize State Machine

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
# ... code that will NOT be executed
```
```

The anti-pattern has a section header but no imperative instruction, causing the LLM to treat the code as an example.

### Working Examples

From `/coordinate.md` (working command):
```markdown
**STEP 1**: The user invoked `/coordinate "<workflow-description>"`. You need to capture that description.

Execute this **small** bash block with your substitution:

```bash
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$WORKFLOW_TEMP_FILE"
```
```

From `/research.md` (working command):
```markdown
**EXECUTE NOW**: USE the Bash tool to source libraries and decompose topic:

```bash
source .claude/lib/topic-decomposition.sh
# ...
```
```

---

## Task Tool Invocation Patterns

### Why Task {} Pseudo-Syntax Fails

Commands using this pattern will NOT invoke agents:

```markdown
Task {
  subagent_type: "research-specialist"
  description: "Research topic"
  prompt: "..."
}
```

**Problems**:
1. This pseudo-syntax is not recognized by Claude Code
2. No execution directive tells the LLM to use the Task tool
3. Variables inside will not be interpolated
4. Code block wrapper makes it documentation, not executable

### Correct Task Invocation Pattern

Per `command-development-fundamentals.md` Section 5.2.1:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Output Directory: ${RESEARCH_DIR}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

### Key Requirements

1. **NO code block wrapper** - Remove ` ```yaml ` fences
2. **Imperative instruction** - "**EXECUTE NOW**: USE the Task tool..."
3. **Inline prompt** - Variables interpolated directly
4. **Completion signal** - Agent must return explicit signal (e.g., `REPORT_CREATED:`)

### Agent Delegation Template

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [AGENT_NAME] agent.

Task {
  subagent_type: "general-purpose"
  description: "[Brief description] with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/[agent-file].md

    **Workflow-Specific Context**:
    - [Context Variable 1]: ${VAR1}
    - [Context Variable 2]: ${VAR2}
    - Output Path: ${OUTPUT_PATH}

    Execute [action] per behavioral guidelines.
    Return: [SIGNAL_NAME]: ${OUTPUT_PATH}
  "
}
```

---

## Subprocess Isolation Requirements

### Core Principle

Each bash code block runs in a **separate subprocess** (not subshell). All environment variables, bash functions, and process state are lost between blocks.

See `bash-block-execution-model.md` for complete documentation.

### Mandatory Patterns

#### Pattern 1: set +H at Start of Every Block

Disable bash history expansion to prevent `!` character issues:

```bash
set +H  # CRITICAL: Disable history expansion
# ... rest of code
```

**Why**: Bash history expansion corrupts indirect variable expansion (`${!var_name}`), causing "bad substitution" errors.

#### Pattern 2: Library Re-sourcing in Every Block

Libraries MUST be re-sourced in every bash block:

```bash
set +H  # CRITICAL: First line
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh"
```

**Why**: Functions from libraries don't persist across subprocess boundaries.

#### Pattern 3: Return Code Verification

Critical functions MUST have explicit return code checks:

```bash
# CORRECT: Explicit check with error handling
if ! sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" 2>&1; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# ALTERNATIVE: Simple check
sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" || exit 1
```

**Why**: `set -euo pipefail` does NOT exit on function failures.

### Anti-Patterns

| Anti-Pattern | Why It Fails |
|-------------|--------------|
| `export VAR=value` | Lost at block exit |
| `$$` for filenames | PID changes per block |
| Trap handlers early | Fire at block exit, not workflow exit |
| Assuming functions exist | Must re-source libraries |

---

## State Persistence Patterns

### File-Based Communication

Variables MUST be persisted to files using the state persistence library:

```bash
# In Block 1: Save state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"

# In Block 2: Load state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "${WORKFLOW_ID:-$$}"
# $VARIABLE_NAME is now available
```

### Workflow ID Persistence

Save workflow ID to fixed location for cross-block access:

```bash
# Block 1: Save ID
WORKFLOW_ID="workflow_$(date +%s)"
echo "$WORKFLOW_ID" > "${HOME}/.claude/tmp/workflow_state_id.txt"

# Block 2: Load ID
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/workflow_state_id.txt")
```

### Conditional Initialization

Use parameter expansion to preserve loaded values:

```bash
# In library files - preserve values if already set
CURRENT_STATE="${CURRENT_STATE:-initialize}"
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
```

---

## Validation and Testing

### Automated Validation Tests

Create tests in `.claude/tests/` to verify compliance:

#### Test 1: Execution Directives Present

```bash
#!/bin/bash
# test_command_execution_directives.sh

FAILED=0
for cmd in .claude/commands/*.md; do
  # Skip README
  [[ "$cmd" == *README* ]] && continue

  # Count execution directives
  COUNT=$(grep -cE "EXECUTE NOW|Execute this|Run the following" "$cmd" || echo 0)

  if [ "$COUNT" -eq 0 ]; then
    echo "FAIL: $cmd has no execution directives"
    FAILED=1
  fi
done

exit $FAILED
```

#### Test 2: No Documentation-Only YAML Blocks

```bash
#!/bin/bash
# test_no_documentation_yaml.sh

FAILED=0
for file in .claude/commands/*.md; do
  # Check for YAML blocks without preceding imperative
  VIOLATIONS=$(awk '/```yaml/{
    found=0
    for(i=NR-5; i<NR; i++) {
      if(lines[i] ~ /EXECUTE NOW|USE the Task tool/) found=1
    }
    if(!found) print NR
  } {lines[NR]=$0}' "$file")

  if [ -n "$VIOLATIONS" ]; then
    echo "FAIL: $file has documentation-only YAML blocks at lines: $VIOLATIONS"
    FAILED=1
  fi
done

exit $FAILED
```

#### Test 3: Subprocess Isolation Compliance

```bash
#!/bin/bash
# test_subprocess_isolation.sh

FAILED=0
for cmd in .claude/commands/*.md; do
  # Count bash blocks
  BASH_BLOCKS=$(grep -c '```bash' "$cmd" || echo 0)

  # Skip single-block commands
  [ "$BASH_BLOCKS" -le 1 ] && continue

  # Check for set +H in each block
  SET_H_COUNT=$(grep -c 'set +H' "$cmd" || echo 0)

  if [ "$SET_H_COUNT" -lt "$BASH_BLOCKS" ]; then
    echo "WARN: $cmd may be missing 'set +H' in some blocks ($SET_H_COUNT/$BASH_BLOCKS)"
  fi
done

exit $FAILED
```

### Implementation Checklist

Before committing command file changes, verify:

- [ ] All bash blocks have `set +H` at start
- [ ] All bash blocks re-source required libraries
- [ ] All critical function calls have return code verification
- [ ] All Task invocations use executable pattern (NO code block wrapper)
- [ ] All Task invocations have imperative instruction
- [ ] All Task invocations require completion signals
- [ ] No documentation-only YAML blocks in executable context

---

## Argument Capture Patterns

Commands receive user arguments that must be captured reliably. Two patterns are available:

### Pattern 1: Direct $1 Capture (Recommended for Simple Arguments)

Use for file paths, numeric IDs, or short strings without special characters:

```bash
PLAN_FILE="$1"
STARTING_PHASE="${2:-1}"  # With default

if [ -z "$PLAN_FILE" ]; then
  echo "ERROR: Plan file required"
  exit 1
fi
```

**When to use**:
- File paths (e.g., `/implement`, `/build`)
- Simple identifiers
- Arguments that don't need shell expansion

**Pros**: Simple, automatic, no user intervention
**Cons**: May fail with complex characters (quotes, `!`, `$`)

### Pattern 2: Two-Step Capture with Library (Recommended for Complex Input)

Use the `argument-capture.sh` library for reliable argument capture with special characters. The library reduces boilerplate from 15-25 lines to 3-5 lines per command.

**Part 1 block** (with explicit substitution by Claude):

```markdown
## Part 1: Capture Workflow Description

**EXECUTE NOW**: Capture the workflow description.

Replace `YOUR_DESCRIPTION_HERE` with the actual description:

```bash
set +H
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/mycommand_arg_$(date +%s%N).txt"
echo "YOUR_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/mycommand_arg_path.txt"
echo "Argument captured to $TEMP_FILE"
```
```

**Part 2 block** (reads captured argument):

```markdown
## Part 2: Read and Validate Argument

**EXECUTE NOW**: Read the captured description and validate:

```bash
set +H
# Read argument from temp file
PATH_FILE="${HOME}/.claude/tmp/mycommand_arg_path.txt"
if [ -f "$PATH_FILE" ]; then
  TEMP_FILE=$(cat "$PATH_FILE")
else
  TEMP_FILE="${HOME}/.claude/tmp/mycommand_arg.txt"  # Legacy fallback
fi

if [ -f "$TEMP_FILE" ]; then
  DESCRIPTION=$(cat "$TEMP_FILE")
else
  echo "ERROR: Argument file not found"
  echo "Usage: /mycommand \"<description>\""
  exit 1
fi

if [ -z "$DESCRIPTION" ]; then
  echo "ERROR: Argument is empty"
  exit 1
fi

echo "Description: $DESCRIPTION"
```
```

**When to use**:
- Complex workflow descriptions (e.g., `/coordinate`, `/plan`)
- Arguments with quotes, special characters, or shell metacharacters
- When user verification of captured value is important

**Pros**: Handles all character types, user sees captured value, concurrent-safe, legacy fallback
**Cons**: Requires manual substitution, two bash blocks instead of one

**Reference Commands**: See `/coordinate`, `/research-report`, `/plan`, `/research-revise` for working examples.

### Recommendation Summary

| Argument Type | Recommended Pattern | Example Commands |
|--------------|---------------------|------------------|
| File paths | Direct $1 | `/implement`, `/build` |
| Issue descriptions | Direct $1 | `/debug`, `/debug` |
| Complex workflows | Two-step | `/coordinate` |
| Feature descriptions | Either (project choice) | `/plan`, `/plan` |

### Concurrent Execution Safety

When using temp files, always use timestamp-based filenames:

```bash
TEMP_FILE="${HOME}/.claude/tmp/command_$(date +%s%N).txt"
```

This prevents conflicts when multiple commands run simultaneously.

---

## Related Documentation

- [Bash Block Execution Model](../concepts/bash-block-execution-model.md) - Complete subprocess isolation patterns
- [Command Development Fundamentals](../guides/command-development-fundamentals.md) - Section 5.2.1 on Task patterns
- [State Persistence Library](library-api.md#state-persistence) - API reference

---

**Last Updated**: 2025-11-17
**Spec Reference**: 756_command_bash_execution_directives
