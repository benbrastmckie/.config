# Command Authoring Standards

Mandatory standards for creating and maintaining executable command files in `.claude/commands/`.

## Table of Contents

1. [Execution Directive Requirements](#execution-directive-requirements)
2. [Task Tool Invocation Patterns](#task-tool-invocation-patterns)
3. [Subprocess Isolation Requirements](#subprocess-isolation-requirements)
4. [State Persistence Patterns](#state-persistence-patterns)
5. [Validation and Testing](#validation-and-testing)
6. [Argument Capture Patterns](#argument-capture-patterns)
7. [Output Suppression Requirements](#output-suppression-requirements)
8. [Command Integration Patterns](#command-integration-patterns)
9. [Prohibited Patterns](#prohibited-patterns)

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
- File paths (e.g., `/implement`, `/build`)
- Simple identifiers without flags
- Arguments that don't need shell expansion

**Pros**: Simple, automatic, no user intervention
**Cons**: May fail with complex characters (quotes, `!`, `$`), no flag parsing support

**Migration Path**: New commands should use 2-block pattern. Existing commands using direct capture may remain unless flag support is needed.

### Recommendation Summary

| Argument Type | Recommended Pattern | Example Commands |
|--------------|---------------------|------------------|
| File paths (no flags) | Direct $1 (legacy) | `/implement`, `/build` |
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
- Commands that operate on existing specs (e.g., `/build`)
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

**Reference Commands**: `/build`, `/revise`, `/expand`, `/collapse`

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
| C: Path Derivation | No | Existing topics/artifacts | `/build`, `/revise`, `/expand` |

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
