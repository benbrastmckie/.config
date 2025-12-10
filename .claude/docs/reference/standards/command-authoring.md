# Command Authoring Standards

Mandatory standards for creating and maintaining executable command files in `.claude/commands/`.

## Table of Contents

1. [Execution Directive Requirements](#execution-directive-requirements)
2. [Task Tool Invocation Patterns](#task-tool-invocation-patterns)
3. [Subprocess Isolation Requirements](#subprocess-isolation-requirements)
4. [State Persistence Patterns](#state-persistence-patterns)
   - [Pre-Flight Library Function Validation](#pre-flight-library-function-validation)
5. [Validation and Testing](#validation-and-testing)
6. [Argument Capture Patterns](#argument-capture-patterns)
7. [Path Validation Patterns](#path-validation-patterns)
8. [Output Suppression Requirements](#output-suppression-requirements)
9. [Plan Metadata Standard Integration](#plan-metadata-standard-integration)
10. [Command Integration Patterns](#command-integration-patterns)
   - [Summary-Based Handoff Pattern](#summary-based-handoff-pattern)
   - [Research Coordinator Delegation Pattern](#research-coordinator-delegation-pattern)
11. [Prohibited Patterns](#prohibited-patterns)

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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
# ... execution code
```
```

### Anti-Pattern (Causes Silent Failure)

```markdown
## Part 1: Initialize State Machine

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
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
source .claude/lib/plan/topic-decomposition.sh
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

### Edge Case Patterns

#### Iteration Loop Invocations

When Task invocations occur inside iteration loops, each invocation point requires its own imperative directive:

```markdown
## Block 5: Initial Invocation

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Implement phase ${STARTING_PHASE}"
  prompt: "..."
}

## Block 7: Iteration Loop Re-Invocation

```bash
if [ "$WORK_REMAINING" != "0" ]; then
  ITERATION=$((ITERATION + 1))
fi
```

**EXECUTE NOW**: USE the Task tool to re-invoke implementer-coordinator for iteration ${ITERATION}.

Task {
  subagent_type: "general-purpose"
  description: "Continue implementation (iteration ${ITERATION})"
  prompt: "..."
}
```

**Key Point**: Both invocation points (initial and loop) require separate imperative directives.

#### Conditional Invocations

When Task invocations depend on runtime conditions, use conditional imperative directives:

```markdown
**EXECUTE IF** coverage below threshold: USE the Task tool to invoke test-executor.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite"
  prompt: "..."
}
```

**Alternative** (explicit bash conditional):
```bash
if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "Coverage insufficient - invoking test-executor"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke test-executor.

Task { ... }
```

#### Model Specification

When invoking subagents via Task tool, you can specify the model tier explicitly using the `model:` field. This enables orchestrator-level control over which model tier handles specific delegation logic.

**Syntax**:

```markdown
Task {
  subagent_type: "general-purpose"
  model: "opus" | "sonnet" | "haiku"
  description: "..."
  prompt: "..."
}
```

**Model Selection Guidelines**:
- `"opus"`: Complex reasoning, proof search, sophisticated delegation logic
- `"sonnet"`: Balanced orchestration, standard implementation tasks
- `"haiku"`: Deterministic coordination, mechanical processing

**Precedence Order**:
1. Task invocation `model:` field (highest priority)
2. Agent frontmatter `model:` field (fallback)
3. System default model (last resort)

**Example** (from todo.md):

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the todo-analyzer agent.

Task {
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Generate TODO.md file"
  prompt: |
    Read and follow ALL instructions in: .claude/agents/todo-analyzer.md
}
```

**Orchestration Example** (from lean-implement.md):

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-coordinator.md
  "
}
```

**When to Specify Model**:
- **Required**: When orchestrator needs different tier than subagent (e.g., Sonnet for coordination, Opus for subagents)
- **Optional**: When agent frontmatter already specifies correct tier
- **Recommended**: For clear separation of orchestration vs. implementation model requirements

#### Agent Behavioral File Task Patterns

When agent behavioral files (e.g., research-coordinator.md) contain Task invocations that the agent should execute, use the same standards-compliant pattern as commands:

**CRITICAL REQUIREMENTS**:
1. **No code block wrappers**: Task invocations must NOT be wrapped in ``` fences
2. **Imperative directives**: Each Task invocation requires "**EXECUTE NOW**: USE the Task tool..." prefix
3. **Concrete values**: Use actual topic strings and paths, not bash variable placeholders like `${TOPICS[0]}`
4. **Checkpoint verification**: Add explicit "Did you just USE the Task tool?" checkpoints after invocations

**Example** (from research-coordinator.md STEP 3):

```markdown
**CHECKPOINT AFTER TOPIC 0**: Did you just USE the Task tool for topic at index 0?

**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic at index 0.

Task {
  subagent_type: "general-purpose"
  description: "Research topic at index 0 with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    (use CLAUDE_PROJECT_DIR)/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=(use REPORT_PATHS[0] - exact absolute path from array)

    **Research Topic**: (use TOPICS[0] - exact topic string from array)

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: (REPORT_PATHS[0])
  "
}
```

**Anti-Patterns** (DO NOT USE):
- ❌ Wrapping Task invocations in code blocks: ` ```Task { }``` `
- ❌ Using bash variable syntax: `${TOPICS[0]}` (looks like documentation)
- ❌ Separate logging code blocks: ` ```bash echo "..."``` ` before Task invocation
- ❌ Pseudo-code notation without imperative directive

**Why This Matters**:
- Agents interpret code-fenced Task blocks as documentation examples
- Bash variable syntax suggests shell interpolation, not actual execution
- Missing imperative directives = agent skips invocation = empty output directories
- Result: Coordinator completes with 0 Task invocations, workflow fails

**Reference**: See [Hierarchical Agents Examples](../../concepts/hierarchical-agents-examples.md#example-7-research-coordinator) for complete research-coordinator implementation.

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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-logger.sh"
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

## Bash Block Size Limits and Prevention

### Size Thresholds

Bash blocks in command files have strict size limits to prevent preprocessing transformation bugs:

| Zone | Line Count | Status | Action Required |
|------|-----------|--------|----------------|
| **Safe Zone** | <300 lines | ✅ Recommended | None - ideal for complex logic |
| **Caution Zone** | 300-400 lines | ⚠️ Monitor | Review for split opportunities |
| **Prohibited** | >400 lines | ❌ Error | **MUST SPLIT** - causes preprocessing bugs |

### Technical Root Cause

Claude's bash preprocessing applies transformations before execution:
- Variable interpolation (`${VAR}` → actual values)
- Command substitution (`$(cmd)` → command output)
- Array expansion (`${arr[@]}` → element list)

**Critical Issue**: These transformations are lossy and introduce subtle bugs when blocks exceed ~400 lines.

**Common Symptoms** (>400 line threshold):
- "bad substitution" errors during array operations
- Conditional expression failures (`if [[ ... ]]` breaks)
- Array expansion issues (unbound variable errors)
- Variable interpolation corruption

**Why 400 Lines?**: Empirical threshold where preprocessing complexity overwhelms transformation accuracy. Exact mechanism is opaque (Claude internal implementation), but symptoms are consistent across multiple commands.

### Detection Methods

**Manual Line Counting**:
```bash
# Count lines in specific bash block
sed -n '/^```bash/,/^```/p' command.md | wc -l

# Count all blocks in command file
awk '/^```bash$/,/^```$/ {if (!/^```/) print}' command.md | wc -l
```

**Automated Validation**:
```bash
# Run block size validator (future tool)
bash .claude/scripts/check-bash-block-size.sh command.md

# Expected output: All blocks <400 lines
```

### Prevention Patterns

#### Pattern 1: Split at Logical Boundaries

Organize commands into 2-3 consolidated blocks based on workflow phases:

```markdown
## Block 1: Setup and Initialization (Target: <300 lines)
**EXECUTE NOW**: Capture arguments, initialize state machine, persist state

```bash
# Argument capture
# Library sourcing
# State machine init
# State persistence
```

## Block 2: Agent Invocation (Task tool - no bash block)
**EXECUTE NOW**: USE the Task tool to invoke subagent

Task { ... }

## Block 3: Validation and Completion (Target: <250 lines)
**EXECUTE NOW**: Validate outputs, transition state, generate summary

```bash
# Hard barrier validation
# State transition
# Console summary
```
```

**Rationale**: Natural split points align with command workflow phases (setup → execution → validation).

#### Pattern 2: Use State Persistence for Cross-Block Communication

When splitting oversized blocks, use state persistence library for data flow:

```bash
# Block 1: Calculate and persist
REPORT_PATHS_ARRAY=("path1" "path2" "path3")
REPORT_PATHS_LIST=$(printf "%s|" "${REPORT_PATHS_ARRAY[@]}")
append_workflow_state "REPORT_PATHS_LIST" "${REPORT_PATHS_LIST%|}"

# Block 2: Restore and use
IFS='|' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_LIST"
echo "Restored ${#REPORT_PATHS_ARRAY[@]} paths"
```

**Why**: State files survive subprocess boundaries, enabling seamless data flow between split blocks.

#### Pattern 3: Task Tool Invocations as Natural Split Points

Task invocations don't require bash blocks, making them ideal split boundaries:

```markdown
## Block 1a: Setup (239 lines)
```bash
# Setup logic
```

## Block 1b: Agent Invocation (0 bash lines - just Task)
**EXECUTE NOW**: USE the Task tool...

Task { ... }

## Block 1c: Post-Agent Processing (225 lines)
```bash
# Validation and continuation
```
```

**Result**: Each segment stays well under 400-line limit, zero preprocessing issues.

### Real-World Example: /research Command Refactor

**Before** (BROKEN):
```
Block 1: 501 lines
  → Symptoms: "bad substitution" errors in array operations
  → Failure: Conditional expressions corrupt after preprocessing
  → Impact: Command unusable for complexity ≥ 3
```

**After** (FIXED):
```
Block 1:  239 lines - Argument capture, state init
Block 1b: Task invocation - Topic naming agent
Block 1c: 225 lines - Decomposition, path pre-calculation
Block 2:  Task invocation - Research coordination
Block 2b: 172 lines - Hard barrier validation
Block 3:  140 lines - Completion and summary
```

**Results**:
- ✅ All blocks <400 lines (largest: 239)
- ✅ Zero "bad substitution" errors
- ✅ Array operations work correctly
- ✅ Conditional expressions stable
- ✅ Command fully functional for all complexity levels

**Reference**: See `.claude/specs/010_research_conform_standards/reports/001-research-conform-standards-analysis.md` for complete refactoring details.

### Cross-References

- **Block Consolidation Guidelines**: See [Output Formatting Standards](./output-formatting.md#block-consolidation) for balancing readability with size limits
- **Subprocess Isolation Patterns**: See [Bash Block Execution Model](../../concepts/bash-block-execution-model.md) for why state doesn't persist across blocks
- **Troubleshooting Preprocessing Bugs**: See [Bash Tool Limitations](../../troubleshooting/bash-tool-limitations.md) for symptom diagnosis and mitigation

---

## State Persistence Patterns

### File-Based Communication

Variables MUST be persisted to files using the state persistence library:

```bash
# In Block 1: Save state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
append_workflow_state "VARIABLE_NAME" "$VARIABLE_VALUE"

# In Block 2: Load state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
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

### Defensive Variable Initialization After State Restoration

After sourcing a state file, initialize potentially unbound variables with defensive defaults to prevent unbound variable errors:

```bash
# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults to prevent unbound variable errors
# These variables may not be set in state file depending on user input
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-3}"
FEATURE_DESCRIPTION="${FEATURE_DESCRIPTION:-}"
```

**When to Use**:
- After any `source "$STATE_FILE"` operation
- For variables that depend on optional user input (flags like `--file`, `--complexity`)
- For variables used in conditional logic that may not exist in all execution paths

**Pattern Benefits**:
- Prevents `unbound variable` errors when `set -u` is enabled
- Documents which variables are expected from state file
- Provides sensible defaults for optional parameters
- Makes state dependencies explicit

### Pre-Flight Library Function Validation

**MANDATORY**: All bash blocks that call library functions MUST validate function availability immediately after sourcing. This prevents exit 127 "command not found" errors.

**Root Cause**: The `source` command can succeed (return 0) even when a library file exists but the target function is not defined (e.g., file contains syntax errors, or function has a different name). This causes exit 127 when the function is called later.

**Required Pattern**:

```bash
# After sourcing state-persistence.sh
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# === PRE-FLIGHT FUNCTION VALIDATION ===
# Verify required functions are available before using them
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_name" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi
```

**Anti-Pattern (PROHIBITED)**:

```bash
# WRONG: Direct source without function validation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
append_workflow_state "KEY" "value"  # May fail with exit 127!
```

**When to Apply**:
- Every bash block that calls `append_workflow_state` or `append_workflow_state_bulk`
- Every bash block that calls `save_completed_states_to_state`
- Every bash block that calls any library function immediately after sourcing

**Alternative Pattern Using validate_library_functions**:

For blocks that source multiple libraries, use the bulk validation helper:

```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1

# Validate all required functions at once
validate_library_functions "state-persistence" || exit 1
validate_library_functions "workflow-state-machine" || exit 1
```

**Enforcement**: This pattern is verified by pre-commit hooks (planned) and manual code review. Exit 127 errors in error logs indicate missing validation.

---

## Concurrent Execution Safety

### Overview

Commands MUST support concurrent execution of multiple instances without state interference. This enables users to run multiple command invocations simultaneously (e.g., two `/create-plan` commands in different terminals) without "Failed to restore WORKFLOW_ID" errors.

### Required Pattern

Commands MUST use the three-part concurrent-safe pattern:

1. **Nanosecond-Precision WORKFLOW_ID**: Use `generate_unique_workflow_id()` for unique timestamps
2. **No Shared State ID Files**: WORKFLOW_ID embedded in state file, no coordination file needed
3. **State File Discovery**: Use `discover_latest_state_file()` for state restoration

### Block 1: Initialization

```bash
# Source state persistence library
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

# Generate unique WORKFLOW_ID (nanosecond precision)
WORKFLOW_ID=$(generate_unique_workflow_id "command_name")

# Initialize workflow state (WORKFLOW_ID embedded in file)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
```

### Block 2+: State Restoration

```bash
# Source state persistence library
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

# Discover latest state file by pattern matching
STATE_FILE=$(discover_latest_state_file "command_name")

if [ -z "$STATE_FILE" ]; then
  echo "Error: Failed to discover state file for command_name"
  exit 1
fi

# Source state file to restore WORKFLOW_ID and other variables
source "$STATE_FILE"
```

### Anti-Pattern: Shared State ID Files

**NEVER** use shared state ID files:

```bash
# ❌ WRONG: Shared state ID file (race condition)
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Block 2+
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)  # May read wrong ID
```

**Why This Fails**: Multiple concurrent instances overwrite the same file, causing the second instance to corrupt the first instance's WORKFLOW_ID.

### Testing Requirements

Commands MUST pass concurrent execution tests:

- 2 instances: Basic race condition test
- 3 instances: Multi-instance interference test
- 5 instances: Standard concurrent workload test

**Validation Criteria**:
- No "Failed to restore WORKFLOW_ID" errors
- All instances complete successfully
- No orphaned state files
- WORKFLOW_IDs unique across all instances

### Validation

The `lint-shared-state-files.sh` validator detects shared state ID file anti-pattern:

```bash
# Run validator
bash .claude/scripts/lint/lint-shared-state-files.sh .claude/commands/*.md

# Integrated validation
bash .claude/scripts/validate-all-standards.sh --concurrency
```

### Documentation

Commands using concurrent-safe pattern SHOULD document:

- Behavior when multiple instances run
- Troubleshooting for state discovery failures
- "Concurrent Execution Safety" note in command documentation

### Reference

See [Concurrent Execution Safety Standard](./concurrent-execution-safety.md) for complete details, collision probability analysis, and troubleshooting guide.

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

### Standardized 2-Block Argument Capture Pattern (Recommended)

The standardized 2-block pattern separates mechanical capture (Block 1) from parsing/validation logic (Block 2), improving debuggability and maintainability.

**Block 1: Mechanical Capture** (with explicit substitution by Claude):

```markdown
## Block 1: Capture User Argument

**EXECUTE NOW**: Capture the user-provided argument.

Replace `YOUR_DESCRIPTION_HERE` with the actual argument value:

```bash
set +H
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/mycommand_arg_$(date +%s%N).txt"
echo "YOUR_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/mycommand_arg_path.txt"
echo "Argument captured to $TEMP_FILE"
```
```

**Block 2: Validation and Parsing** (reads and validates captured argument):

```markdown
## Block 2: Validate and Parse Argument

**EXECUTE NOW**: Read the captured argument and validate:

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
  echo "ERROR: Argument file not found" >&2
  echo "Usage: /mycommand \"<description>\"" >&2
  exit 1
fi

if [ -z "$DESCRIPTION" ]; then
  echo "ERROR: Argument is empty" >&2
  exit 1
fi

# Parse flags if applicable
DRY_RUN=false
COMPLEXITY=2
if echo "$DESCRIPTION" | grep -q '\--dry-run'; then
  DRY_RUN=true
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--dry-run//g')
fi
if echo "$DESCRIPTION" | grep -Eq '\--complexity [0-9]'; then
  COMPLEXITY=$(echo "$DESCRIPTION" | grep -oE '\--complexity [0-9]' | awk '{print $2}')
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--complexity [0-9]//g')
fi

# Clean whitespace
DESCRIPTION=$(echo "$DESCRIPTION" | xargs)

echo "Description: $DESCRIPTION"
[ "$DRY_RUN" = true ] && echo "Dry run: enabled"
echo "Complexity: $COMPLEXITY"
```
```

**Benefits of 2-Block Pattern**:
- **Separation of Concerns**: Capture mechanics isolated from validation logic
- **Debuggability**: Can inspect capture step independently of validation
- **Maintainability**: Flag parsing logic consolidated in single location
- **Visibility**: User sees intermediate capture confirmation before validation

**When to Use**:
- Commands with complex argument parsing (multiple flags)
- Commands requiring user verification of captured value
- Commands with special character handling needs
- All new command development (standardized approach)

**Reference Commands**: See `/coordinate`, `/research`, `/plan`, `/revise`, `/repair` for working examples.

### Pattern 1: Direct $1 Capture (Legacy)

Use for file paths, numeric IDs, or short strings without special characters:

```bash
PLAN_FILE="$1"
STARTING_PHASE="${2:-1}"  # With default

if [ -z "$PLAN_FILE" ]; then
  echo "ERROR: Plan file required" >&2
  exit 1
fi
```

**When to use**:
- File paths (e.g., `/implement`, `/implement`)
- Simple identifiers without flags
- Arguments that don't need shell expansion

**Pros**: Simple, automatic, no user intervention
**Cons**: May fail with complex characters (quotes, `!`, `$`), no flag parsing support

**Migration Path**: New commands should use 2-block pattern. Existing commands using direct capture may remain unless flag support is needed.

### Recommendation Summary

| Argument Type | Recommended Pattern | Example Commands |
|--------------|---------------------|------------------|
| File paths (no flags) | Direct $1 (legacy) | `/implement`, `/implement` |
| Complex descriptions | 2-block (standard) | `/research`, `/plan` |
| Commands with flags | 2-block (standard) | `/repair`, `/debug` |
| New command development | 2-block (standard) | All new commands |

### Concurrent Execution Safety

When using temp files, always use timestamp-based filenames:

```bash
TEMP_FILE="${HOME}/.claude/tmp/command_$(date +%s%N).txt"
```

This prevents conflicts when multiple commands run simultaneously.

---

## Path Initialization Patterns

Commands must initialize directory paths for topic organization and artifact storage. Three distinct patterns exist based on workflow requirements.

### Pattern A: Topic Naming Agent (For New Topics with Semantic Naming)

Use when creating new topic directories with LLM-generated semantic names.

**When to Use**:
- Commands that create new specs (e.g., `/research`, `/plan`, `/debug`)
- Workflows requiring human-readable directory names
- Features where topic name isn't predetermined

**Implementation**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}

# Invoke topic naming agent with user description
TOPIC_DIR=$(create_topic_structure "$DESCRIPTION") || {
  echo "ERROR: Topic directory creation failed" >&2
  exit 1
}

# Parse topic number and name from returned path
TOPIC_NUMBER=$(basename "$TOPIC_DIR" | grep -oE '^[0-9]+')
TOPIC_NAME=$(basename "$TOPIC_DIR" | sed 's/^[0-9]*_//')

echo "Topic allocated: $TOPIC_NUMBER ($TOPIC_NAME)"
echo "Topic directory: $TOPIC_DIR"
```

**Behavior**:
- Invokes Haiku LLM agent via `create_topic_structure()` function
- Agent analyzes user description and generates semantic name
- Returns path like `/home/user/.config/.claude/specs/NNN_semantic_topic_name/`
- Falls back to `no_name` if agent fails (never blocks workflow)

**Reference Commands**: `/research`, `/plan`, `/debug`

### Pattern B: Direct Naming (For Timestamp-Based Allocation)

Use when topic directories need timestamp-based or explicit naming without LLM involvement.

**When to Use**:
- Commands operating on topics without semantic naming
- Workflows requiring immediate directory allocation
- Testing or debugging scenarios

**Implementation**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}

# Get next topic number
SPECS_ROOT="${CLAUDE_PROJECT_DIR}/.claude/specs"
NEXT_NUMBER=$(get_next_topic_number "$SPECS_ROOT")

# Create topic with explicit or timestamp name
TOPIC_NAME="issue_${TIMESTAMP}"  # Or other naming scheme
TOPIC_DIR="${SPECS_ROOT}/${NEXT_NUMBER}_${TOPIC_NAME}"
mkdir -p "$TOPIC_DIR" || {
  echo "ERROR: Failed to create topic directory" >&2
  exit 1
}

echo "Topic directory: $TOPIC_DIR"
```

**Behavior**:
- No LLM agent invocation (deterministic allocation)
- Uses `get_next_topic_number()` for sequential numbering
- Explicit naming control by command author
- Faster execution (no agent round-trip)

**Reference Commands**: Legacy commands, testing utilities

### Pattern C: Path Derivation (For Operations on Existing Topics)

Use when operating on existing topic directories or artifacts.

**When to Use**:
- Commands that modify existing plans (e.g., `/revise`, `/expand`, `/collapse`)
- Commands that operate on existing specs (e.g., `/implement`)
- Any workflow reading or updating artifacts in known locations

**Implementation**:
```bash
# Validate input path
PLAN_FILE="$1"
if [ -z "$PLAN_FILE" ]; then
  echo "ERROR: Plan file path required" >&2
  exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# Derive topic directory from plan path
TOPIC_DIR=$(dirname "$(dirname "$PLAN_FILE")")  # plans/file.md -> topic/

# Derive artifact paths
REPORTS_DIR="${TOPIC_DIR}/reports"
SUMMARIES_DIR="${TOPIC_DIR}/summaries"
DEBUG_DIR="${TOPIC_DIR}/debug"

echo "Operating on topic: $TOPIC_DIR"
```

**Behavior**:
- Derives paths from input arguments (file or directory)
- No directory creation (operates on existing structure)
- Validates paths exist before operations
- Uses standard artifact subdirectory layout

**Reference Commands**: `/implement`, `/revise`, `/expand`, `/collapse`

### Decision Tree: Which Pattern to Use?

```
Does command create new topic?
├─ YES: Does it need semantic naming?
│   ├─ YES: Use Pattern A (Topic Naming Agent)
│   └─ NO: Use Pattern B (Direct Naming)
└─ NO: Use Pattern C (Path Derivation)
```

### Common Patterns Summary

| Pattern | LLM Agent | When to Use | Example Commands |
|---------|-----------|-------------|------------------|
| A: Topic Naming Agent | Yes | New topics, semantic names | `/research`, `/plan`, `/debug` |
| B: Direct Naming | No | Explicit naming, testing | Legacy commands, utilities |
| C: Path Derivation | No | Existing topics/artifacts | `/implement`, `/revise`, `/expand` |

### Error Handling

All patterns MUST handle path initialization failures:

```bash
# Pattern A
TOPIC_DIR=$(create_topic_structure "$DESCRIPTION") || {
  echo "ERROR: Topic directory creation failed" >&2
  exit 1
}

# Pattern B
mkdir -p "$TOPIC_DIR" || {
  echo "ERROR: Failed to create topic directory" >&2
  exit 1
}

# Pattern C
if [ ! -d "$TOPIC_DIR" ]; then
  echo "ERROR: Topic directory not found: $TOPIC_DIR" >&2
  exit 1
fi
```

### Lazy Subdirectory Creation

All patterns follow lazy directory creation for artifact subdirectories:

- **Commands create**: Only topic root directory (`specs/NNN_topic/`)
- **Agents create**: Artifact subdirectories at write-time via `ensure_artifact_directory()`

See [Directory Creation](#directory-creation) section for complete lazy creation guidance.

---

## Path Validation Patterns

Commands must validate path consistency between CLAUDE_PROJECT_DIR and derived paths (e.g., STATE_FILE) to prevent false positive PATH MISMATCH errors.

### PROJECT_DIR Under HOME (Valid Configuration)

When `CLAUDE_PROJECT_DIR` is detected under `$HOME` (e.g., `~/.config`), this is a **VALID configuration**. Path validation MUST NOT treat this as an error.

**Problem**: Legacy validation incorrectly assumed PROJECT_DIR is never under HOME, causing false positives when:
- CLAUDE_PROJECT_DIR = `/home/user/.config` (valid)
- STATE_FILE = `/home/user/.config/.claude/tmp/workflow_123.sh` (correct)
- Old check flagged this as "PATH MISMATCH" (wrong)

**Correct Pattern** (Using validation library):

```bash
# Source validation library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh" >&2
  exit 1
}

# Use validate_path_consistency() from validation-utils.sh
if ! validate_path_consistency "$STATE_FILE" "$CLAUDE_PROJECT_DIR"; then
  # Error already logged by function
  exit 1
fi
```

**Inline Pattern** (Without library):

```bash
# Skip PATH MISMATCH check when PROJECT_DIR is subdirectory of HOME (valid configuration)
if [[ "$CLAUDE_PROJECT_DIR" =~ ^${HOME}/ ]]; then
  # PROJECT_DIR legitimately under HOME - skip PATH MISMATCH validation
  :
elif [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  # Only flag as error if PROJECT_DIR is NOT under HOME but STATE_FILE uses HOME
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "PATH MISMATCH detected: STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR" \
    "bash_block" \
    "$(jq -n --arg state_file "$STATE_FILE" --arg home "$HOME" --arg project_dir "$CLAUDE_PROJECT_DIR" \
       '{state_file: $state_file, home: $home, project_dir: $project_dir, issue: "STATE_FILE must use CLAUDE_PROJECT_DIR"}')"

  echo "ERROR: PATH MISMATCH - STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR" >&2
  echo "  Current: $STATE_FILE" >&2
  echo "  Expected: ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh" >&2
  exit 1
fi
```

### Anti-Pattern (Causes False Positives)

**WRONG**: This pattern assumes PROJECT_DIR is never under HOME:

```bash
# ❌ ANTI-PATTERN: Causes false positives when PROJECT_DIR is ~/.config
if [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  echo "ERROR: PATH MISMATCH"  # FALSE POSITIVE when PROJECT_DIR is ~/.config
  exit 1
fi
```

### When to Use Path Validation

**Use path validation when**:
- Command uses state files in `.claude/tmp/`
- Command derives paths from CLAUDE_PROJECT_DIR
- Cross-block state persistence is required
- Multiple bash blocks need consistent path roots

**Pattern Benefits**:
- Prevents false positive PATH MISMATCH errors
- Handles valid HOME subdirectory projects
- Catches actual path inconsistencies
- Integrated with centralized error logging

### Related Validation Functions

See `validation-utils.sh` for additional path validation utilities:
- `validate_path_consistency()` - Check STATE_FILE path consistency
- `validate_project_directory()` - Validate CLAUDE_PROJECT_DIR detection
- `validate_absolute_path()` - Check absolute path format and existence

---

## Output Suppression Requirements

Commands MUST suppress verbose output to maintain clean Claude Code display. Each bash block should produce minimal output focused on actionable results.

### Mandatory Suppression Patterns

#### Library Sourcing Suppression

All library sourcing MUST suppress output while preserving error handling:

```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Why**: Library sourcing can produce verbose output (function definitions, initialization messages) that clutters display without adding value.

#### Directory Operations Suppression

Directory operations MUST suppress non-critical output:

```bash
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

**Why**: Directory operations either succeed silently or are handled elsewhere.

#### Single Summary Line per Block

Each block SHOULD output a single summary line instead of multiple progress messages:

```bash
# ❌ ANTI-PATTERN: Multiple verbose messages
echo "Starting initialization..."
echo "Loading libraries..."
echo "Validating configuration..."
echo "Creating directories..."
echo "Initialization complete"

# ✓ CORRECT: Single summary
# Perform all operations silently
source "$LIB" 2>/dev/null || exit 1
validate_config || exit 1
mkdir -p "$DIR" 2>/dev/null

echo "Setup complete: $WORKFLOW_ID"
```

### Output vs Error Distinction

**Suppress**: Success messages, progress indicators, intermediate state
**Preserve**: Errors (to stderr), warnings, final summaries, user-needed data

```bash
# Errors to stderr (always visible)
echo "ERROR: Configuration invalid" >&2

# Summary to stdout (minimal)
echo "Setup complete: $WORKFLOW_ID"
```

### Block Consolidation Strategy

Commands should balance clarity with execution efficiency by consolidating related operations into fewer bash blocks.

#### Target Block Count

Commands SHOULD use 2-3 bash blocks maximum to minimize display noise:

| Block | Purpose |
|-------|---------|
| **Setup** | Capture, validate, source, init, allocate |
| **Execute** | Main workflow logic |
| **Cleanup** | Verify, complete, summary |

#### When to Consolidate vs. Separate

**Consolidate blocks when**:
- Operations are sequential dependencies (A must complete before B)
- No intermediate user visibility needed
- Operations share same error handling strategy
- Workflow is linear (<5 phases)

**Separate blocks when**:
- Operations need explicit checkpoints (user progress visibility)
- Different error handling strategies required
- Agent invocations needed (Task tool requires visible response)
- Complex workflows (>5 phases) benefit from phase boundaries

#### Decision Matrix

| Workflow Type | Phase Count | Block Strategy | Rationale |
|--------------|-------------|----------------|-----------|
| Simple commands | 1-2 phases | 2 blocks (Setup + Execute) | Minimal overhead, clear flow |
| Linear workflows | 3-5 phases | 2-3 blocks with checkpoints | Balance visibility and noise |
| Complex workflows | 6+ phases | 3-4 blocks with phase groups | Logical grouping, clear progress |
| Agent-heavy workflows | Any | Separate blocks per agent | Task tool visibility requirement |

#### Consolidation Examples

**Before** (6 blocks - excessive):
```markdown
Block 1: mkdir output dir
Block 2: source libraries
Block 3: validate config
Block 4: init state machine
Block 5: allocate workflow ID
Block 6: persist state
```

**After** (2 blocks - optimized):
```markdown
Block 1 (Setup):
- mkdir output dir (silent)
- source libraries (with fail-fast)
- validate config (exit on failure)
- init state machine (explicit check)
- allocate workflow ID
- persist state
- echo "Setup complete: $WORKFLOW_ID"

Block 2 (Execute):
- main workflow logic
```

**Benefits**:
- 67% reduction in display noise (6 → 2 blocks)
- Faster execution (fewer subprocess spawns)
- Single summary per logical phase
- Easier debugging (logical groupings)

#### Performance vs. Clarity Trade-offs

| Factor | Fewer Blocks (Consolidated) | More Blocks (Discrete) |
|--------|----------------------------|------------------------|
| **Execution Speed** | Faster (fewer subprocess spawns) | Slower (more overhead) |
| **User Visibility** | Less granular checkpoints | More progress markers |
| **Debugging** | Harder to isolate failures | Easier step-by-step debugging |
| **Code Clarity** | Requires good comments | Self-documenting via separation |

**Recommendation**: Start with consolidation (2-3 blocks), add separation only when debugging issues arise.

#### Block Consolidation Template

```bash
# Block 1: Consolidated Setup
set +H  # CRITICAL: First line
mkdir -p "${OUTPUT_DIR}" 2>/dev/null || true

# Source all required libraries with fail-fast
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${LIB_DIR}/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Initialize state machine with explicit check
sm_init "$DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE"
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: State machine initialization failed" >&2
  exit 1
fi

# Allocate workflow ID and persist
WORKFLOW_ID=$(allocate_workflow_id) || exit 1
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1

# Single summary line
echo "Setup complete: $WORKFLOW_ID"
```

#### Anti-Patterns

**Anti-Pattern 1: Over-Separation**
```markdown
# WRONG: Each line in separate block
Block 1: mkdir dir
Block 2: source lib1
Block 3: source lib2
Block 4: init state
```

**Anti-Pattern 2: Monolithic Block**
```markdown
# WRONG: Everything in one block including agent invocation
Block 1: Setup + validation + agent invocation + cleanup + summary
# Agent response not visible due to subprocess isolation
```

**Anti-Pattern 3: No Checkpoints in Complex Workflows**
```markdown
# WRONG: 10-phase workflow in 2 blocks with no progress visibility
Block 1: Setup
Block 2: Phases 1-10 (user sees nothing for 5+ minutes)
```

#### Integration with Checkpoint Format

Consolidated blocks should include checkpoints at logical boundaries:

```bash
# Block 1: Multi-phase setup
set +H
source_libraries || exit 1
init_state_machine || exit 1
allocate_paths || exit 1

echo "[CHECKPOINT] Setup complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, PATHS_ALLOCATED=true"
echo "Ready for: Agent delegation"
```

See [Checkpoint Reporting Format](output-formatting.md#checkpoint-reporting-format) for complete checkpoint standards.

### Complete Reference

See [Output Formatting Standards](output-formatting.md) for:
- All output suppression patterns
- Detailed block consolidation rules and examples
- Comment standards (WHAT not WHY)
- Output vs error distinction

---

## Directory Creation

Commands MUST follow the lazy directory creation pattern to prevent empty artifact directories.

### Required Pattern

- **DO**: Create only the topic root directory (`specs/NNN_topic/`)
- **DO NOT**: Create artifact subdirectories (`reports/`, `plans/`, `debug/`, `summaries/`, `outputs/`)
- **DELEGATE**: Let agents create subdirectories via `ensure_artifact_directory()` at write-time

```bash
# ✓ CORRECT: Command creates topic root only
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
TOPIC_DIR=$(create_topic_structure "feature_name")  # Creates ONLY topic root

# Agent handles subdirectory creation when writing files:
# ensure_artifact_directory "${TOPIC_DIR}/reports/001_analysis.md"
```

```bash
# ❌ ANTI-PATTERN: Command pre-creates subdirectories
mkdir -p "${TOPIC_DIR}/reports"
mkdir -p "${TOPIC_DIR}/plans"
mkdir -p "${TOPIC_DIR}/debug"
# If agent fails or produces no output, empty directories remain
```

This ensures directories exist only when they contain files. Empty directories indicate a lazy creation violation and are detected by the integration test suite.

See [Directory Creation Anti-Patterns](code-standards.md#directory-creation-anti-patterns) for complete guidance and examples.

---

## Plan Metadata Standard Integration

All plan-generating commands must inject plan metadata standards into agent context to ensure format compliance and reduce validation errors.

### When to Inject Plan Metadata Standards

Plan-generating commands MUST inject standards for:
- `/create-plan` - General implementation planning
- `/lean-plan` - Lean theorem proving plans
- `/repair` - Error repair planning
- `/revise` - Plan revision workflows
- `/debug` - Debug workflow planning

**Rationale**: Proactive compliance via agent context injection prevents format violations detected during post-generation validation.

### How to Use format_standards_for_prompt()

Source the standards extraction library and call the function to extract relevant metadata standard sections:

```bash
source "${CLAUDE_LIB}/plan/standards-extraction.sh" 2>/dev/null || {
  echo "Warning: Cannot load standards-extraction library"
}

# Extract formatted standards for agent injection
FORMATTED_STANDARDS=$(format_standards_for_prompt "$STANDARDS_FILE")

# Graceful degradation: empty string on failure
if [ -z "$FORMATTED_STANDARDS" ]; then
  echo "Warning: Failed to extract plan metadata standards (agent will use defaults)"
fi
```

**Function Behavior**:
- **Source**: `.claude/lib/plan/standards-extraction.sh`
- **Input**: Path to CLAUDE.md standards file
- **Output**: Formatted metadata standard sections as string
- **Failure Mode**: Returns empty string (graceful degradation)
- **Integration Point**: Before Task tool invocation with plan-generating agent

### Example Integration Pattern

Reference implementation from `/create-plan` (lines 1888-1895):

```bash
# Source standards extraction library
source "${CLAUDE_LIB}/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error "dependency_error" \
    "Cannot load standards-extraction library" \
    "Path: ${CLAUDE_LIB}/plan/standards-extraction.sh"
}

# Extract plan metadata standards for agent
FORMATTED_STANDARDS=$(format_standards_for_prompt "$STANDARDS_FILE")

if [ -z "$FORMATTED_STANDARDS" ]; then
  log_command_error "parse_error" \
    "Failed to extract plan metadata standards" \
    "Agent will use default format (may fail validation)"
fi

# Inject standards into agent prompt
**EXECUTE NOW**: USE the Task tool to invoke plan-architect agent:

Task Input:
- Agent: plan-architect
- Context:
  - User request: "${FEATURE_DESCRIPTION}"
  - Plan path: "${PLAN_PATH}"
  - Standards: ${FORMATTED_STANDARDS}
  - Research reports: [list of report paths]
```

### Validation Script Invocation

After the agent returns the plan artifact, invoke the validation script:

```bash
# Validate plan metadata after agent returns
if [ -f "$PLAN_PATH" ]; then
  bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/lint/validate-plan-metadata.sh" "$PLAN_PATH"
  VALIDATION_EXIT=$?

  if [ $VALIDATION_EXIT -ne 0 ]; then
    log_command_error "validation_error" \
      "Plan metadata validation failed" \
      "Plan: $PLAN_PATH | Exit code: $VALIDATION_EXIT"
    echo "WARNING: Plan has metadata format issues (see validation output)"
    # Allow workflow to continue (validation errors logged)
  fi
fi
```

**Exit Code Handling**: Log validation errors but allow workflow continuation (plan is still usable, validation detects quality issues).

### CLAUDE.md Section Metadata Updates

When integrating plan metadata standards into a command, update the `plan_metadata_standard` section's "Used by" metadata:

**Location**: CLAUDE.md line ~218 (in `<!-- SECTION: plan_metadata_standard -->`)

**Before**:
```markdown
[Used by: /create-plan, /repair, /revise, /debug, plan-architect]
```

**After** (example adding /lean-plan):
```markdown
[Used by: /create-plan, /lean-plan, /repair, /revise, /debug, plan-architect]
```

Commands must be listed in alphabetical order for consistency.

---

## Non-Interactive Testing Standard Integration

Plan-generating commands MUST inject non-interactive testing standards into agent context to ensure test phases are executable without manual intervention. This enables automated CI/CD execution, wave-based parallel testing, and consistent validation results.

### When to Inject Non-Interactive Testing Standards

Commands that generate plans with test phases MUST inject testing standards:
- `/create-plan` - General implementation planning (includes testing phases)
- `/lean-plan` - Lean theorem proving plans (includes proof validation phases)
- `/repair` - Error repair planning (includes validation/testing phases)
- `/debug` - Debug workflow planning (includes test reproduction phases)

**Rationale**: Proactive injection prevents interactive anti-patterns (e.g., "manually verify", "skip if needed") that block automated execution.

### Extension to format_standards_for_prompt()

The `format_standards_for_prompt()` function supports optional non-interactive testing standards extraction:

```bash
source "${CLAUDE_LIB}/plan/standards-extraction.sh" 2>/dev/null || {
  echo "Warning: Cannot load standards-extraction library"
}

# Extract both plan metadata AND non-interactive testing standards
FORMATTED_STANDARDS=$(format_standards_for_prompt "$STANDARDS_FILE")
TESTING_STANDARDS=$(extract_testing_standards "$NON_INTERACTIVE_TESTING_STANDARD_FILE")

# Combine standards for agent injection
COMBINED_STANDARDS="${FORMATTED_STANDARDS}

### Non-Interactive Testing Requirements

${TESTING_STANDARDS}"
```

**Function Parameters** (proposed extension):
- **Input**: Path to non-interactive-testing-standard.md
- **Output**: Formatted testing standard sections (Required Automation Fields, Anti-Patterns)
- **Failure Mode**: Returns empty string (graceful degradation)

### Example Integration Pattern from /create-plan

Reference implementation showing standards injection for test phase generation:

```bash
# Source standards extraction library
source "${CLAUDE_LIB}/plan/standards-extraction.sh" 2>/dev/null || {
  log_command_error "dependency_error" \
    "Cannot load standards-extraction library" \
    "Path: ${CLAUDE_LIB}/plan/standards-extraction.sh"
}

# Extract plan metadata standards
FORMATTED_STANDARDS=$(format_standards_for_prompt "$STANDARDS_FILE")

# Extract non-interactive testing standards (if test phases expected)
TESTING_STANDARD_PATH="${CLAUDE_DOCS}/reference/standards/non-interactive-testing-standard.md"
if [ -f "$TESTING_STANDARD_PATH" ]; then
  TESTING_STANDARDS=$(extract_testing_standards "$TESTING_STANDARD_PATH")

  # Combine standards for comprehensive agent context
  COMBINED_STANDARDS="${FORMATTED_STANDARDS}

### Non-Interactive Testing Requirements

All test phases MUST include automation metadata:
- automation_type: automated (not manual)
- validation_method: programmatic (not visual)
- skip_allowed: false (mandatory execution)
- artifact_outputs: [list of test artifacts]

PROHIBITED patterns (ERROR-level violations):
- \"manually verify\", \"skip if needed\", \"verify visually\"
- \"inspect output\", \"optional\", \"check results\"

${TESTING_STANDARDS}"
else
  COMBINED_STANDARDS="$FORMATTED_STANDARDS"
  log_command_error "file_error" \
    "Non-interactive testing standard not found" \
    "Path: $TESTING_STANDARD_PATH | Agent will use defaults"
fi

# Inject combined standards into agent prompt
**EXECUTE NOW**: USE the Task tool to invoke plan-architect agent:

Task Input:
- Agent: plan-architect
- Context:
  - User request: "${FEATURE_DESCRIPTION}"
  - Plan path: "${PLAN_PATH}"
  - Standards: ${COMBINED_STANDARDS}
  - Research reports: [list of report paths]
```

### Validation After Plan Generation

After the agent returns the plan, validate test phases for anti-patterns:

```bash
# Validate non-interactive testing compliance
if [ -f "$PLAN_PATH" ]; then
  bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/validate-non-interactive-tests.sh" \
    --file "$PLAN_PATH"
  VALIDATION_EXIT=$?

  if [ $VALIDATION_EXIT -ne 0 ]; then
    log_command_error "validation_error" \
      "Non-interactive testing validation failed" \
      "Plan: $PLAN_PATH | Interactive anti-patterns detected"
    echo "ERROR: Test phases contain interactive patterns (manual intervention required)"
    echo "Run: bash .claude/scripts/validate-non-interactive-tests.sh --file $PLAN_PATH"
    # Block workflow continuation (ERROR-level violations)
    exit 1
  fi
fi
```

**Exit Code Handling**: Unlike plan metadata validation (WARNING-level), non-interactive testing violations are ERROR-level and MUST block workflow continuation.

### Troubleshooting Standards Injection

**Issue**: Agent generates test phases with interactive patterns despite standards injection
**Diagnosis**:
1. Verify standards extraction succeeded (non-empty TESTING_STANDARDS variable)
2. Check agent behavioral guidelines include non-interactive testing requirements
3. Validate standards context appears in agent prompt (add debug logging)

**Resolution**:
```bash
# Debug standards extraction
echo "DEBUG: Extracted testing standards length: ${#TESTING_STANDARDS}"
echo "DEBUG: Standards content preview:"
echo "$TESTING_STANDARDS" | head -20

# Verify standards file exists and is readable
if [ ! -f "$TESTING_STANDARD_PATH" ]; then
  echo "ERROR: Testing standard file not found: $TESTING_STANDARD_PATH"
  exit 1
fi

if [ ! -r "$TESTING_STANDARD_PATH" ]; then
  echo "ERROR: Testing standard file not readable: $TESTING_STANDARD_PATH"
  exit 1
fi
```

### CLAUDE.md Section Metadata Updates

When integrating non-interactive testing standards into a command, update the `non_interactive_testing` section's "Used by" metadata:

**Location**: CLAUDE.md (in `<!-- SECTION: non_interactive_testing -->`)

**Format**:
```markdown
[Used by: /create-plan, /lean-plan, /implement, /debug, /repair]
```

Commands must be listed in alphabetical order for consistency.

### Cross-References

**Related Standards**:
- [Non-Interactive Testing Standard](./non-interactive-testing-standard.md) - Complete testing automation requirements
- [Plan Metadata Standard](./plan-metadata-standard.md) - Plan metadata standard integration (parallel pattern)
- [Testing Protocols](./testing-protocols.md) - Non-interactive execution requirements section

**Related Documentation**:
- [Plan-Architect Agent Guidelines](./../../agents/plan-architect.md) - Test phase generation behavioral requirements
- [Enforcement Mechanisms](./enforcement-mechanisms.md) - Validator integration and bypass procedures

---

## Command Integration Patterns

Commands often need to integrate with other commands via file-based handoff. The summary-based handoff pattern enables decoupled state passing between commands.

### Summary-Based Handoff Pattern

When Command A produces artifacts that Command B consumes, use summary files as the integration point instead of direct state files.

**Pattern Benefits**:
- Decoupled state (commands don't share state files)
- Human-readable integration (summaries are markdown)
- Auditable workflow (summaries document what was done)
- Flexible timing (Command B can run immediately or later)

### --file Flag Pattern

Commands that consume summaries from other commands should support a `--file` flag for explicit summary path specification.

**Implementation**:

```bash
# In argument parsing block
SUMMARY_FILE=""
if [[ "$COMMAND_ARGS" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  SUMMARY_FILE="${BASH_REMATCH[1]}"
fi

# Validate summary file exists
if [ -n "$SUMMARY_FILE" ] && [ ! -f "$SUMMARY_FILE" ]; then
  log_command_error "validation_error" \
    "Summary file not found" \
    "Path: $SUMMARY_FILE"
  exit 1
fi

# Extract data from summary
if [ -n "$SUMMARY_FILE" ]; then
  # Example: Extract plan path from summary metadata
  PLAN_FILE=$(grep "^- \*\*Plan\*\*:" "$SUMMARY_FILE" | sed 's/.*: //')
  TEST_CONTEXT="summary"
fi
```

**Usage Example**:
```bash
# Command A produces summary
/implement plan.md
# Creates: summaries/001-iteration-1-implementation-summary.md

# Command B consumes summary via --file flag
/test --file summaries/001-iteration-1-implementation-summary.md
```

### Auto-Discovery Pattern

Commands should support auto-discovery of latest summary when --file flag not provided, with graceful fallback.

**Implementation**:

```bash
# Auto-discovery if --file not provided but plan file given
if [ -z "$SUMMARY_FILE" ] && [ -n "$PLAN_FILE" ]; then
  # Derive topic path from plan file
  TOPIC_PATH=$(dirname "$(dirname "$PLAN_FILE")")
  SUMMARIES_DIR="${TOPIC_PATH}/summaries"

  # Find latest summary by modification time
  if [ -d "$SUMMARIES_DIR" ]; then
    LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

    if [ -n "$LATEST_SUMMARY" ]; then
      SUMMARY_FILE="$LATEST_SUMMARY"
      TEST_CONTEXT="auto-discovered"
    else
      # Graceful fallback: no summary found
      echo "WARNING: No summary found in $SUMMARIES_DIR (proceeding without summary context)"
      TEST_CONTEXT="no-summary"
    fi
  fi
fi
```

**Usage Example**:
```bash
# Auto-discovery from plan file
/test plan.md
# Automatically finds latest summary in plan's topic directory
```

### Required Summary Metadata

Commands producing summaries for consumption by other commands must include metadata section for parsing.

**Metadata Format**:
```markdown
## Metadata

- **Date**: 2025-12-01
- **Plan**: /absolute/path/to/plan.md
- **Topic Path**: /absolute/path/to/topic
- **Iteration**: 1
```

This enables downstream commands to extract paths without relying on state files.

### Integration Examples

#### /implement → /test Workflow

```bash
# /implement creates summary with Testing Strategy section
/implement specs/042_auth/plans/001_auth_plan.md
# Creates: specs/042_auth/summaries/001-iteration-1-implementation-summary.md
# Summary includes: Testing Strategy section with test files, commands, coverage target

# /test consumes summary (auto-discovery)
/test specs/042_auth/plans/001_auth_plan.md
# Reads Testing Strategy from auto-discovered summary
# Executes tests with coverage loop
```

#### /research → /plan Workflow

```bash
# /research creates research report
/research "authentication feature"
# Creates: specs/042_auth/reports/001-auth-research.md

# /plan consumes research report via --file flag
/plan --file specs/042_auth/reports/001-auth-research.md
# Reads research findings and creates implementation plan
```

### State File vs Summary File

**State Files** (`.state/*.sh`):
- Bash-sourceable variable assignments
- Machine-readable only
- Temporary (deleted on completion)
- Command-specific (not for cross-command handoff)

**Summary Files** (`summaries/*.md`):
- Human-readable markdown
- Auditable workflow documentation
- Persistent (kept for history)
- Cross-command handoff mechanism

**When to Use Each**:
- Use state files for intra-command state (between blocks in same command)
- Use summary files for inter-command state (between different commands)

See [Implement-Test Workflow Guide](./../../guides/workflows/implement-test-workflow.md) for complete summary-based handoff examples.

### Research Coordinator Delegation Pattern

Commands requiring multi-topic research should use the research-coordinator agent to enable parallel research execution with metadata-only context passing (95% context reduction).

**When to Use**:
- Research complexity ≥ 3 (indicates 2+ distinct topics)
- Feature description contains multiple domains or concerns
- Commands: `/create-plan`, `/research`, `/repair`, `/debug`, `/revise`

**Pattern Benefits**:
- **Context Reduction**: 95% reduction via metadata-only passing (7,500 → 330 tokens for 3 topics)
- **Parallel Execution**: 40-60% time savings (parallel vs sequential research)
- **Hard Barrier Enforcement**: Path pre-calculation prevents coordinator bypass
- **Metadata Aggregation**: Primary agent receives summaries, not full reports

**Pattern Structure** (3-block sequence):

1. **Block 1d-topics**: Topic Decomposition (heuristic or automated)
2. **Block 1e-exec**: Research Coordinator Task Invocation
3. **Block 1f**: Multi-Report Validation (hard barrier)

**Integration Points**:
- **Topic Decomposition** → saves TOPICS_LIST and REPORT_PATHS_LIST to state
- **Coordinator Invocation** → passes topics and paths as contract
- **Multi-Report Validation** → validates all reports with fail-fast policy
- **Metadata Extraction** → aggregates findings count, recommendations for passing to next agent

**Decision Criteria**:

| Scenario | Pattern | Agent | Notes |
|----------|---------|-------|-------|
| Complexity 1-2, single topic | Direct invocation | research-specialist | No coordinator overhead |
| Complexity 3-4, multi-topic | Coordinator pattern | research-coordinator | Enables parallelization |
| Lean/Mathlib domain | Specialized direct | lean-research-specialist | Domain expertise required |

See [Research Invocation Standards](./research-invocation-standards.md) for complete decision matrix and migration guidance.

**Example Implementation**:

See [Command Patterns Quick Reference](../command-patterns-quick-reference.md) for copy-paste templates including:
- Template 6: Topic Decomposition Block (heuristic-based)
- Template 7: Topic Detection Agent Invocation Block (automated)
- Template 8: Research Coordinator Task Invocation Block
- Template 9: Multi-Report Validation Loop
- Template 10: Metadata Extraction and Aggregation

**Troubleshooting**:

**Issue**: Topic decomposition returns empty array
- **Cause**: Ambiguous feature description, unclear topic boundaries
- **Solution**: Fall back to single-topic mode (backward compatibility)
- **Prevention**: Check RESEARCH_COMPLEXITY ≥ 3 before attempting decomposition

**Issue**: topic-detection-agent fails or returns malformed JSON
- **Cause**: Complex nested descriptions, timeout, JSON parsing error
- **Solution**: Gracefully degrade to heuristic decomposition (Phase 1 logic)
- **Prevention**: Validate JSON structure with `jq` before parsing

**Issue**: research-coordinator reports missing (hard barrier failure)
- **Cause**: Coordinator failed, path mismatch, file system error
- **Solution**: Check error logs with `/errors --command /create-plan --type agent_error`
- **Prevention**: Verify REPORT_PATHS_LIST persisted to state before invocation

**Issue**: Metadata extraction parsing errors
- **Cause**: Malformed report structure, missing "## Findings" section
- **Solution**: Use filename as title fallback, log parsing error
- **Prevention**: Validate report structure in multi-report validation loop

**Related Documentation**:
- [Research Invocation Standards](./research-invocation-standards.md) - Decision matrix for coordinator vs specialist
- [Hierarchical Agents Examples](../../concepts/hierarchical-agents-examples.md) - Example 7: Research Coordinator Pattern
- [Command Patterns Quick Reference](../command-patterns-quick-reference.md) - Copy-paste templates

---

## Prohibited Patterns

### Naked Task Blocks Without Imperative Directives

Commands MUST NOT use Task blocks without explicit imperative instructions. Pseudo-code syntax or instructional text patterns are PROHIBITED and will be detected by lint-task-invocation-pattern.sh.

**❌ PROHIBITED Pattern 1: Naked Task Block**

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

**Problem**: No imperative directive tells Claude to USE the Task tool. Claude interprets this as documentation.

**❌ PROHIBITED Pattern 2: Instructional Text Without Task Invocation**

```markdown
## Phase 3: Agent Delegation

Use the Task tool to invoke the research-specialist agent with the calculated paths.
The agent will create the report at ${REPORT_PATH}.
```

**Problem**: Instructional text describes what SHOULD happen but doesn't invoke the Task tool. No action occurs.

**❌ PROHIBITED Pattern 3: Incomplete EXECUTE NOW Directive**

```markdown
**EXECUTE NOW**: Invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

**Problem**: Missing "USE the Task tool" phrase. Directive is not explicit enough.

**❌ PROHIBITED Pattern 4: Conditional Prefix Without EXECUTE Keyword**

```markdown
**If CONDITION**: USE the Task tool to invoke agent.

Task {
  subagent_type: "general-purpose"
  description: "Process data"
  prompt: "..."
}
```

**Problem**: The conditional prefix "**If X**:" reads as descriptive documentation, not an imperative execution directive. Claude interprets this as guidance describing what SHOULD happen under certain conditions, not as a command to execute NOW.

**Other Prohibited Conditional Prefixes**:
- `**When CONDITION**: USE the Task tool...` (descriptive timing)
- `**Based on CONDITION**: USE the Task tool...` (descriptive logic)
- `**For CONDITION**: USE the Task tool...` (descriptive scope)

**Why This Fails**: Conditional prefixes lack the explicit "EXECUTE" keyword that signals mandatory action. Without it, Claude cannot distinguish between:
- Documentation: "When X happens, you should invoke agent" (guidance)
- Imperative: "Execute agent invocation when X" (action)

**✅ CORRECT Pattern (Option 1 - Separate Directive)**:

```markdown
**If CONDITION**:

**EXECUTE NOW**: USE the Task tool to invoke agent.

Task {
  subagent_type: "general-purpose"
  description: "Process data"
  prompt: "..."
}
```

**✅ CORRECT Pattern (Option 2 - Single Line)**:

```markdown
**EXECUTE IF CONDITION**: USE the Task tool to invoke agent.

Task {
  subagent_type: "general-purpose"
  description: "Process data"
  prompt: "..."
}
```

**✅ CORRECT Pattern (Option 3 - Bash Conditional)**:

```bash
if [ "$CONDITION" = "true" ]; then
  echo "Condition met - invoking agent"
fi
```

**EXECUTE NOW**: USE the Task tool to invoke agent.

Task { ... }
```

**Key Principle**: The word "EXECUTE" MUST appear in the directive to signal mandatory action vs. descriptive documentation.

**✅ REQUIRED Pattern: Imperative Task Directive**

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Required Elements**:
1. Imperative instruction: "**EXECUTE NOW**: USE the Task tool..."
2. Agent name specified: "...to invoke the [AGENT_NAME] agent"
3. No code block wrapper around Task block
4. Inline prompt with variable interpolation
5. Completion signal in prompt

**Validation**:

All command files are validated by the automated linter:

```bash
# Run Task invocation pattern linter
bash .claude/scripts/lint-task-invocation-pattern.sh <command-file>

# Linter detects:
# - ERROR: Task { without EXECUTE NOW directive
# - ERROR: Instructional text without actual Task invocation
# - ERROR: Incomplete EXECUTE NOW directive (missing 'Task tool')
```

See [Hard Barrier Subagent Delegation Pattern](../../concepts/patterns/hard-barrier-subagent-delegation.md#task-invocation-requirements) for complete Task invocation requirements and edge case patterns.

### Negation in Conditional Tests (if ! and elif !)

Commands MUST NOT use `if !` or `elif !` patterns due to bash history expansion errors. These patterns trigger preprocessing-stage history expansion BEFORE runtime `set +H` can disable it, causing UI errors in command output files.

**Prohibited Patterns**:

```bash
# ❌ ANTI-PATTERN: Negation in if condition
if ! some_command arg1 arg2; then
  echo "ERROR: Command failed"
  exit 1
fi

# ❌ ANTI-PATTERN: Negation in elif condition
if [ -z "$VAR" ]; then
  VAR="default"
elif ! echo "$VAR" | grep -Eq '^pattern$'; then
  VAR="default"
fi
```

**Root Cause**: The Bash tool performs preprocessing BEFORE script execution. During preprocessing, history expansion is enabled by default and processes the exclamation mark (`!`) before the script runs `set +H` to disable it. This causes errors like:

```
/run/current-system/sw/bin/bash: line 42: !: command not found
```

### Required Alternative: Exit Code Capture

Use exit code capture pattern instead of negation:

**Pattern 1: Simple `if !` Replacement**

```bash
# ✓ CORRECT: Exit code capture
some_command arg1 arg2
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: Command failed"
  exit 1
fi
```

**Pattern 2: `elif !` Replacement**

```bash
# ✓ CORRECT: Nested conditional with exit code capture
if [ -z "$VAR" ]; then
  VAR="default"
else
  echo "$VAR" | grep -Eq '^pattern$'
  IS_VALID=$?
  if [ $IS_VALID -ne 0 ]; then
    VAR="default"
  fi
fi
```

**Pattern 3: Pipeline with Negation**

```bash
# ❌ ANTI-PATTERN: Negated pipeline
if ! echo "$VALUE" | command1 | command2; then
  handle_error
fi

# ✓ CORRECT: Exit code capture for pipeline
echo "$VALUE" | command1 | command2
PIPELINE_STATUS=$?
if [ $PIPELINE_STATUS -ne 0 ]; then
  handle_error
fi
```

### Validation

All command files are validated by the automated test suite:

```bash
# Run detection test
.claude/tests/test_no_if_negation_patterns.sh

# Zero violations expected
# Test will fail if any if ! or elif ! patterns found
```

See [Bash Tool Limitations](../../troubleshooting/bash-tool-limitations.md) for complete technical explanation of preprocessing-stage history expansion timing.

### Historical Context

This prohibition is based on systematic remediation across 52 instances in 8 command files (Spec 876), following similar fixes in Specs 620, 641, 672, 685, 700, 717. The exit code capture pattern has proven reliable with 100% test pass rate across all implementations.

---

## Related Documentation

- [Bash Block Execution Model](../concepts/bash-block-execution-model.md) - Complete subprocess isolation patterns
- [Command Development Fundamentals](../guides/development/command-development/command-development-fundamentals.md) - Section 5.2.1 on Task patterns
- [State Persistence Library](library-api.md#state-persistence) - API reference
- [Output Formatting Standards](output-formatting-standards.md) - Output suppression and formatting patterns

---

**Last Updated**: 2025-11-18
**Spec Reference**: 756_command_bash_execution_directives, 794_001_comprehensive_output_formatting_refactormd_to
