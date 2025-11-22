# Bash Block Execution Model

## Overview

Each bash block in Claude Code command files (`.claude/commands/*.md`) runs as a **separate subprocess**, not a subshell. This architectural constraint has significant implications for state management and variable persistence across bash blocks.

This document provides comprehensive documentation of subprocess isolation patterns discovered through Specs 620 and 630, validated patterns for cross-block state management, and anti-patterns to avoid.

## Subprocess vs Subshell: Technical Details

### Process Architecture

```
Claude Code Session
    ↓
Command Execution (coordinate.md)
    ↓
┌────────── Bash Block 1 ──────────┐
│ PID: 12345                       │
│ - Source libraries               │
│ - Initialize state               │
│ - Save to files                  │
│ - Exit subprocess                │
└──────────────────────────────────┘
    ↓ (subprocess terminates)
┌────────── Bash Block 2 ──────────┐
│ PID: 12346 (NEW PROCESS)        │
│ - Re-source libraries            │
│ - Load state from files          │
│ - Process data                   │
│ - Exit subprocess                │
└──────────────────────────────────┘
```

### Key Characteristics

**Subprocess Isolation**:
- Each bash block runs in a completely separate process
- Process ID (`$$`) changes between blocks
- All environment variables reset (exports lost)
- All bash functions lost (must re-source libraries)
- Trap handlers fire at block exit, not workflow exit

**File System as Communication Channel**:
- Only files written to disk persist across blocks
- State persistence requires explicit file writes
- Libraries must be re-sourced in each block

## Mandatory Re-Sourcing Requirements

**REQUIREMENT**: Every bash block MUST re-source all required libraries.

This is NOT a recommendation - it is a mandatory requirement enforced by automated tooling.

### Enforcement Mechanisms

1. **Linter**: `.claude/scripts/lint/check-library-sourcing.sh` detects violations
2. **Pre-commit hooks**: Block commits with violations (bypass with `--no-verify` and documented justification)
3. **CI validation**: Linter runs before tests in validation pipeline

### Function Availability Check

Before calling any library function, add a defensive check:

```bash
if ! type save_completed_states_to_state &>/dev/null; then
  echo "ERROR: save_completed_states_to_state not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh not sourced in this block" >&2
  exit 1
fi
```

This check should appear within 10 lines before any critical function call.

### Critical Functions Requiring Checks

| Function | Library | Impact if Missing |
|----------|---------|-------------------|
| `save_completed_states_to_state` | workflow-state-machine.sh | Exit 127, state loss |
| `append_workflow_state` | state-persistence.sh | Exit 127, state loss |
| `load_workflow_state` | state-persistence.sh | Exit 127, state inaccessible |
| `log_command_error` | error-handling.sh | Exit 127, errors not logged |
| `ensure_error_log_exists` | error-handling.sh | Exit 127, log initialization fails |

### Detection Methods

1. **Error message**: `bash: FUNCTION_NAME: command not found` (exit code 127)
2. **Linter**: `bash .claude/scripts/lint/check-library-sourcing.sh` detects this pattern
3. **Defensive check**: Add `type FUNCTION_NAME &>/dev/null` before calls

### Related Standards

- [Code Standards - Mandatory Bash Block Sourcing Pattern](../reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern)
- [Output Formatting Standards - MANDATORY Error Suppression](../reference/standards/output-formatting.md#mandatory-error-suppression-on-critical-libraries)
- [Exit Code 127 Troubleshooting Guide](../troubleshooting/exit-code-127-command-not-found.md)

## Task Tool Subprocess Isolation

### Overview

The Task tool creates an additional level of subprocess isolation beyond bash blocks. When agents are invoked via Task tool, they run in **completely isolated subprocesses** with no access to the parent command's environment or state.

### Architecture

```
Parent Command (coordinate.md)
    ↓
Bash Block 1 (PID: 12345)
│ - STATE_FILE=.claude/tmp/workflow_12345.sh
│ - export CLASSIFICATION_JSON='...'
│    ↓
│   Task Tool Invocation
│       ↓
│   ┌─────── Agent Subprocess ──────┐
│   │ PID: 12346 (ISOLATED)        │
│   │ - NO access to STATE_FILE    │
│   │ - NO access to env vars      │
│   │ - Can only return text       │
│   └──────────────────────────────┘
│       ↓ (returns text output)
│
│ - Extract result from agent output
│ - Save to STATE_FILE
└─────────────────────────────────────
```

### Critical Constraints

**Agent subprocess CANNOT**:
- Access parent bash block environment variables
- Execute bash commands if `allowed-tools: None`
- Modify parent STATE_FILE directly
- Use `append_workflow_state()` in parent context

**Agent subprocess CAN**:
- Read files (if `allowed-tools: Read`)
- Return structured text output
- Perform analysis and classification
- Generate JSON results

### Correct State Persistence Pattern

**Anti-Pattern** (causes state persistence failures):
```markdown
## Agent Behavioral File (workflow-classifier.md)

allowed-tools: None  ← Agent has NO bash tool

## Instructions

After classification, save to state:

```bash
source .claude/lib/core/state-persistence.sh
append_workflow_state "CLASSIFICATION_JSON" "$JSON"
```
```

**Problem**: Agent configured with `allowed-tools: None` cannot execute bash commands. Even with `allowed-tools: Bash`, the agent subprocess cannot access parent STATE_FILE variable.

**Correct Pattern** (Spec 752 Fix):
```markdown
## Agent Behavioral File (workflow-classifier.md)

allowed-tools: None  ← Classification-only agent

## Output Format

Return: CLASSIFICATION_COMPLETE: {JSON object}

The parent command will extract and save this JSON to state.
```

```markdown
## Parent Command (coordinate.md)

**Phase 0.1**: Invoke classifier agent

Task {
  prompt: "Classify workflow... Return: CLASSIFICATION_COMPLETE: {JSON}"
}

**IMMEDIATELY AFTER Task completes**, extract and save:

```bash
# Extract JSON from agent response above
CLASSIFICATION_JSON='<EXTRACT_FROM_TASK_OUTPUT>'

# Validate JSON
echo "$CLASSIFICATION_JSON" | jq empty || exit 1

# Save to state (parent context has access to STATE_FILE)
append_workflow_state "CLASSIFICATION_JSON" "$CLASSIFICATION_JSON"
```
```

### Key Principles

1. **Agent Returns Data**: Agents return structured output (JSON, signals)
2. **Parent Persists State**: Parent command extracts output and saves to state
3. **File-Based Communication**: Only method across Task tool boundary
4. **Validate Before Save**: Always validate JSON before persisting

### Agent Configuration Guidelines

**Classification-Only Agents**:
```yaml
allowed-tools: None
description: Classification-only agent - returns JSON, does not persist state
```

**Analysis Agents** (need to read files):
```yaml
allowed-tools: Read, Grep
description: Analysis agent - reads files, returns findings
```

**Execution Agents** (need to modify code):
```yaml
allowed-tools: Read, Write, Edit, Bash
description: Implementation agent - executes tasks, creates commits
```

### Troubleshooting

**Symptom**: Unbound variable error in subsequent bash block
```
bash: CLASSIFICATION_JSON: unbound variable
```

**Root Cause**: Agent tried to persist state but couldn't due to subprocess isolation

**Solution**: Move state persistence to parent command bash block

**Symptom**: Agent behavioral file has conflicting instructions
```
allowed-tools: None
Instructions: "USE the Bash tool to save state"
```

**Root Cause**: Behavioral file contradicts frontmatter configuration

**Solution**: Remove bash execution instructions, use output-based pattern

## What Persists vs What Doesn't

### Persists Across Blocks ✓

| Item | Persistence Method | Example |
|------|-------------------|---------|
| Files | Written to filesystem | `echo "data" > /tmp/state.txt` |
| State files | Via state-persistence.sh | `append_workflow_state "KEY" "value"` |
| Workflow ID | Fixed location file | `${HOME}/.claude/tmp/coordinate_state_id.txt` |
| Directories | Created with `mkdir -p` | `mkdir -p /path/to/dir` |

### Does NOT Persist Across Blocks ✗

| Item | Reason | Consequence |
|------|--------|-------------|
| Environment variables | New process | `export VAR=value` lost |
| Bash functions | Not inherited | Must re-source library files |
| Process ID (`$$`) | New PID per block | Cannot use `$$` for cross-block IDs |
| Trap handlers | Fire at block exit | Cleanup traps fail in early blocks |
| Current directory | May reset | Use absolute paths always |

## Validation Test

This test demonstrates subprocess isolation:

```bash
#!/usr/bin/env bash
# Validation test for subprocess isolation

echo "=== Test 1: Process ID Changes ==="
cat > /tmp/test_subprocess_1.sh <<'EOF'
#!/usr/bin/env bash
echo "Block 1 PID: $$"
echo "$$" > /tmp/pid_block_1.txt
EOF

cat > /tmp/test_subprocess_2.sh <<'EOF'
#!/usr/bin/env bash
echo "Block 2 PID: $$"
echo "$$" > /tmp/pid_block_2.txt
EOF

bash /tmp/test_subprocess_1.sh
bash /tmp/test_subprocess_2.sh

PID1=$(cat /tmp/pid_block_1.txt)
PID2=$(cat /tmp/pid_block_2.txt)

if [ "$PID1" != "$PID2" ]; then
  echo "✓ CONFIRMED: Process IDs differ ($PID1 vs $PID2)"
  echo "  Each bash block runs as separate subprocess"
else
  echo "✗ UNEXPECTED: Process IDs match (same process)"
fi

echo ""
echo "=== Test 2: Environment Variables Lost ==="
cat > /tmp/test_export_1.sh <<'EOF'
#!/usr/bin/env bash
export TEST_VAR="set_in_block_1"
echo "Block 1: TEST_VAR=$TEST_VAR"
EOF

cat > /tmp/test_export_2.sh <<'EOF'
#!/usr/bin/env bash
echo "Block 2: TEST_VAR=${TEST_VAR:-unset}"
EOF

bash /tmp/test_export_1.sh
bash /tmp/test_export_2.sh

echo ""
echo "=== Test 3: Files Persist ==="
cat > /tmp/test_file_1.sh <<'EOF'
#!/usr/bin/env bash
echo "data_from_block_1" > /tmp/test_data.txt
echo "Block 1: Wrote to file"
EOF

cat > /tmp/test_file_2.sh <<'EOF'
#!/usr/bin/env bash
if [ -f /tmp/test_data.txt ]; then
  echo "Block 2: Read from file: $(cat /tmp/test_data.txt)"
else
  echo "Block 2: File not found"
fi
EOF

bash /tmp/test_file_1.sh
bash /tmp/test_file_2.sh

echo ""
echo "✓ Files are the ONLY reliable cross-block communication channel"

# Cleanup
rm -f /tmp/test_subprocess_*.sh /tmp/pid_block_*.txt /tmp/test_export_*.sh /tmp/test_file_*.sh /tmp/test_data.txt
```

Expected output:
```
✓ CONFIRMED: Process IDs differ (12345 vs 12346)
  Each bash block runs as separate subprocess

Block 1: TEST_VAR=set_in_block_1
Block 2: TEST_VAR=unset

Block 1: Wrote to file
Block 2: Read from file: data_from_block_1

✓ Files are the ONLY reliable cross-block communication channel
```

## Recommended Patterns

### Pattern 1: Fixed Semantic Filenames

**Problem**: Using `$$` for temp filenames causes files to be "lost" across blocks.

**Solution**: Use fixed, semantically meaningful filenames based on workflow context.

```bash
# ❌ ANTI-PATTERN: PID-based filename
cat > /tmp/workflow_$$.sh <<'EOF'
# Workflow state
EOF
# File created: /tmp/workflow_12345.sh

# Next bash block (different PID)
# Cannot find file: /tmp/workflow_12346.sh does not exist

# ✓ RECOMMENDED: Fixed semantic filename
WORKFLOW_ID="coordinate_$(date +%s)"
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

cat > "$STATE_FILE" <<'EOF'
# Workflow state
EOF

# Next bash block: Same filename accessible
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE"  # ✓ Success
```

### Pattern 2: Save-Before-Source Pattern

**Problem**: State ID must persist across subprocess boundaries.

**Solution**: Save state ID to fixed location file before sourcing state.

```bash
# Part 1: Initialize and save state ID
WORKFLOW_ID="coordinate_$(date +%s)"
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"

# Save state ID to fixed location (persists across blocks)
echo "$WORKFLOW_ID" > "$COORDINATE_STATE_ID_FILE"

# Create state file
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
cat > "$STATE_FILE" <<'EOF'
# Workflow state variables
export CURRENT_STATE="initialize"
EOF

# Part 2: Load state ID and source state (in next bash block)
COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
if [ -f "$COORDINATE_STATE_ID_FILE" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE")
  STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
  source "$STATE_FILE"
else
  echo "ERROR: State ID file not found"
  exit 1
fi
```

### Pattern 3: Two-Step Argument Capture

**Problem**: Arguments with special characters (quotes, `!`, `$`) fail with direct `$1` capture.

**Solution**: Use two-bash-block pattern where Part 1 captures user input via explicit substitution.

```bash
# Part 1: Capture argument to temp file
# CRITICAL: Claude replaces YOUR_ARGUMENT_HERE with actual argument
set +H
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/mycommand_arg_$(date +%s%N).txt"
echo "YOUR_ARGUMENT_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/mycommand_arg_path.txt"

# Part 2: Read captured argument (in next bash block)
set +H
PATH_FILE="${HOME}/.claude/tmp/mycommand_arg_path.txt"
if [ -f "$PATH_FILE" ]; then
  TEMP_FILE=$(cat "$PATH_FILE")
  ARGUMENT=$(cat "$TEMP_FILE")
else
  echo "ERROR: Argument file not found"
  exit 1
fi
```

**Reference**: See [Command Authoring Standards](../reference/standards/command-authoring.md#pattern-2-two-step-capture-with-library-recommended-for-complex-input) for complete pattern documentation.

**Commands Using This Pattern**: `/coordinate`, `/research`, `/plan`, `/revise`

### Pattern 4: State Persistence Library

**Problem**: Manual state file management is error-prone and verbose.

**Solution**: Use `.claude/lib/core/state-persistence.sh` for standardized state management.

```bash
# In each bash block:

# 1. Re-source library (functions lost across block boundaries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# 2. Load workflow state
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# 3. Update state
append_workflow_state "CURRENT_STATE" "research"
append_workflow_state "REPORT_COUNT" "3"

# 4. State automatically persists to file
# No manual file writes needed
```

### Pattern 4: Library Re-sourcing with Source Guards

**Problem**: Bash functions lost across block boundaries.

**Solution**: Re-source all libraries in each block; use source guards to prevent redundant execution.

```bash
# At start of EVERY bash block:
set +H  # CRITICAL: Disable history expansion to prevent bad substitution errors

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries (source guards make this safe)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/unified-logger.sh"  # Provides emit_progress and logging functions
source "${LIB_DIR}/verification-helpers.sh"

# Library source guards prevent duplicate execution:
# if [ -n "${LIBRARY_NAME_SOURCED:-}" ]; then
#   return 0
# fi
# export LIBRARY_NAME_SOURCED=1
```

**Critical Requirements**:
- MUST include `set +H` at the start of every bash block to prevent history expansion from corrupting indirect variable expansion (`${!var_name}`)
- MUST include unified-logger.sh for emit_progress and display_brief_summary functions
- Source guards in libraries make multiple sourcing safe and efficient

### Pattern 5: Conditional Variable Initialization

**Problem**: Library variables are reset when re-sourced across subprocess boundaries, even when values are loaded from state files.

**Solution**: Use conditional initialization with bash parameter expansion to preserve existing values while allowing default initialization for unset variables.

```bash
# ❌ ANTI-PATTERN: Direct initialization (overwrites loaded values)
# In .claude/lib/workflow/workflow-state-machine.sh:
WORKFLOW_SCOPE=""
WORKFLOW_DESCRIPTION=""
CURRENT_STATE="initialize"

# Problem: These assignments execute EVERY time the library is sourced,
# even when sourced AFTER loading state from persistence layer.
# Loaded values are immediately overwritten with defaults.

# ✓ RECOMMENDED: Conditional initialization (preserves loaded values)
# Use ${VAR:-default} parameter expansion:
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
CURRENT_STATE="${CURRENT_STATE:-initialize}"

# Benefits:
# - If variable is already set: preserves existing value
# - If variable is unset: initializes to default (empty or specified)
# - Safe with set -u: no "unbound variable" errors
# - Idiomatic bash pattern (GNU manual, section 3.5.3)
```

**When to Use**:
- Variables that must persist across bash block boundaries
- Integration with Pattern 3 (State Persistence Library) and Pattern 4 (Library Re-sourcing)
- State variables loaded from persistence layer before library re-sourcing
- Variables that need different values in different workflow contexts

**When NOT to Use**:
- Constants (use `readonly` instead)
- Arrays (parameter expansion syntax not supported: `declare -ga ARRAY=()`)
- One-time initialization inside source guards (already protected from re-execution)
- Variables that should always reset to defaults on library sourcing

**Example from workflow-state-machine.sh**:

```bash
# Lines 66-79 in workflow-state-machine.sh
# State machine variables preserve values across library re-sourcing

# Current state (with default fallback)
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"

# Terminal state (with default fallback)
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"

# Workflow configuration (preserve if set, initialize to empty if unset)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"

# Arrays cannot use conditional initialization
declare -ga COMPLETED_STATES=()  # Array syntax incompatible with ${VAR:-}

# Constants should remain readonly
readonly STATE_INITIALIZE="initialize"  # No conditional initialization needed
```

**Real-World Use Case (from /coordinate)**:

```bash
# Bash Block 1: Initialize workflow
source .claude/lib/workflow/workflow-state-machine.sh  # WORKFLOW_SCOPE="" (or "${WORKFLOW_SCOPE:-}")
sm_init "Research authentication" "coordinate"  # Sets WORKFLOW_SCOPE="research-and-plan"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"  # Save to state file

# Bash Block 2: Research phase (NEW SUBPROCESS)
load_workflow_state "$WORKFLOW_ID"  # Restores WORKFLOW_SCOPE="research-and-plan"
source .claude/lib/workflow/workflow-state-machine.sh  # With conditional init: WORKFLOW_SCOPE preserved!
                                               # Without: WORKFLOW_SCOPE="" (BUG!)

# Conditional initialization fixes the bug where WORKFLOW_SCOPE was reset to ""
# after being loaded from state file, causing workflows to incorrectly proceed
# to unintended phases (Spec 653).
```

**Technical Details**:

The `${VAR:-word}` parameter expansion:
- Tests if VAR is unset OR null (empty string)
- If true: expands to `word`
- If false: expands to current value of VAR
- Assignment form: `VAR="${VAR:-default}"` assigns the expanded value
- Colon semantics: omitting colon (`${VAR-word}`) only tests for unset, not null

See GNU Bash Manual, section 3.5.3 (Shell Parameter Expansion) for complete specification.

### Pattern 6: Cleanup on Completion Only

**Problem**: Trap handlers in early blocks fire at block exit, not workflow exit.

**Solution**: Only set cleanup traps in final completion function.

```bash
# ❌ ANTI-PATTERN: Trap in early block
trap 'rm -f /tmp/workflow_*.sh' EXIT  # Fires at block exit, not workflow exit

# ✓ RECOMMENDED: Trap only in completion function
display_brief_summary() {
  # This function runs in final bash block only
  trap 'rm -f /tmp/workflow_*.sh' EXIT

  echo "Workflow complete"
  # Trap fires when THIS block exits (workflow end)
}
```

### Pattern 7: Return Code Verification for Critical Functions

**Problem**: Bash functions can fail without causing script exit unless explicitly checked.

**Solution**: Always check return codes for critical initialization functions.

**Critical Functions Requiring Checks**:
- `sm_init()` - State machine initialization
- `initialize_workflow_paths()` - Path allocation
- `source_required_libraries()` - Library loading
- `classify_workflow_comprehensive()` - Workflow classification
- Any function that exports state variables

**Pattern**:
```bash
# ❌ ANTI-PATTERN: No return code check
sm_init "$WORKFLOW_DESC" "coordinate" >/dev/null
# Execution continues even if sm_init fails

# ✓ RECOMMENDED: Explicit return code check with error handling
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi

# ✓ ALTERNATIVE: Compound operator (for simple cases)
sm_init "$WORKFLOW_DESC" "coordinate" || exit 1
```

### Pattern 8: Block Count Minimization

**Problem**: Each bash block creates a separate display element in Claude Code output, causing visual noise and degraded user experience.

**Solution**: Consolidate related operations into fewer blocks. Target 2-3 blocks per command.

**Target Block Structure**:

| Block Type | Purpose | Operations |
|-----------|---------|------------|
| **Setup** | Initialization | Argument capture, library sourcing, validation, state machine init, path allocation |
| **Execute** | Main workflow | Core processing, agent invocations, state transitions |
| **Cleanup** | Completion | Final validation, completion signal, summary output |

**Example Consolidation**:
```bash
# ❌ ANTI-PATTERN: 6 separate blocks
Block 1: mkdir output dir
Block 2: source libraries
Block 3: validate config
Block 4: init state machine
Block 5: allocate workflow ID
Block 6: persist state

# ✓ RECOMMENDED: 2 consolidated blocks
Block 1 (Setup):
  mkdir -p "$DIR" 2>/dev/null
  source "${LIB}/state-machine.sh" 2>/dev/null || exit 1
  source "${LIB}/persistence.sh" 2>/dev/null || exit 1
  validate_config || exit 1
  sm_init "$DESC" "$CMD" "$TYPE" || exit 1
  WORKFLOW_ID=$(allocate_workflow_id) || exit 1
  append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1
  echo "Setup complete: $WORKFLOW_ID"

Block 2 (Execute):
  # Main workflow logic
```

**Consolidation Rules**:
1. **Combine consecutive operations** that don't require intermediate verification
2. **Separate operations** that need explicit checkpoints or error handling
3. **Keep Task invocations** in their own conceptual section for response visibility
4. **Suppress verbose output** within consolidated blocks

**Benefits**:
- **50-67% reduction** in display noise (6 blocks to 2-3)
- **Faster execution** (fewer subprocess spawns)
- **Cleaner output** (single summary per block)
- **Easier debugging** (logical groupings)

**When to Use**:
- New command development
- Refactoring commands with excessive block counts
- Commands with noisy display output

**When NOT to Use**:
- Blocks with distinct error recovery requirements
- Operations requiring explicit user confirmation between steps
- Task tool invocations that need visible response boundaries

See [Output Formatting Standards](../reference/standards/output-formatting.md) for complete output suppression and consolidation patterns.

**Rationale**:
- `set -euo pipefail` does NOT exit on function failures (only simple commands)
- Output redirection (`>/dev/null`) hides critical error messages
- Silent failures lead to unbound variable errors later in execution
- Explicit checks enable fail-fast error handling (CLAUDE.md development philosophy)

**Example from Spec 698**:

Without return code check, `sm_init()` classification failure allowed execution to continue with uninitialized `RESEARCH_COMPLEXITY`, causing unbound variable error 78 lines later. Adding explicit check caught error immediately at line 166 instead of line 244.

**When to Use**:
- Any function that initializes critical state variables
- Functions called in orchestration command initialization blocks
- Library functions that export variables to parent scope
- Operations with complex failure modes (network, file I/O, external APIs)

**Related Standards**:
- Standard 0 (Execution Enforcement) - CLAUDE.md:277-283
- Fail-Fast Policy - CLAUDE.md:211-215
- Verification and Fallback Pattern - verification-fallback.md

## Critical Libraries for Re-sourcing

Commands using the bash block execution model MUST re-source these libraries in every bash block to ensure function availability across subprocess boundaries:

### Core State Management Libraries

1. **workflow-state-machine.sh**: State machine operations (sm_init, sm_transition, sm_get_state)
2. **state-persistence.sh**: GitHub Actions-style state file operations (init_workflow_state, append_workflow_state, load_workflow_state)
3. **workflow-initialization.sh**: Path detection and initialization (initialize_workflow_paths, reconstruct_report_paths_array)

### Error Handling and Logging Libraries

4. **error-handling.sh**: Fail-fast error handling (handle_state_error, error recovery functions)
5. **unified-logger.sh**: Progress markers and completion summaries (emit_progress, display_brief_summary, log_* functions)
6. **verification-helpers.sh**: File creation verification (verify_file_created, verification checkpoint helpers)

### Library Requirements by Command Type

**Orchestration Commands** (/coordinate, /orchestrate, /supervise):
- ALL six libraries required
- unified-logger.sh provides critical user feedback functions
- Omitting any library causes "command not found" errors

**Simple Commands** (single bash block):
- Only libraries needed for specific operations
- Example: /setup may only need error-handling.sh

**State-Based Commands** (using state machine pattern):
- workflow-state-machine.sh + state-persistence.sh required
- workflow-initialization.sh for path management
- unified-logger.sh for progress feedback

### Common Errors from Missing Libraries

| Missing Library | Error Symptom | Impact |
|---|---|---|
| unified-logger.sh | `emit_progress: command not found` | Missing progress markers (degraded UX) |
| unified-logger.sh | `display_brief_summary: command not found` | Missing completion summary (degraded UX) |
| error-handling.sh | `handle_state_error: command not found` | Unhandled errors, unclear failure messages |
| verification-helpers.sh | `verify_file_created: command not found` | Missing verification checkpoints, silent failures |
| workflow-state-machine.sh | `sm_transition: command not found` | State transitions fail, workflow halts |
| state-persistence.sh | `load_workflow_state: command not found` | Cannot restore state across blocks |

### Verification Checklist

Before deploying a new command or updating an existing orchestration command, verify:

- [ ] `set +H` appears at start of every bash block
- [ ] All six libraries sourced in correct order (state → error → log → verify)
- [ ] Source statements match Pattern 4 template exactly
- [ ] No `export -f` attempts (ineffective across subprocess boundaries)
- [ ] Functions from libraries work in manual testing across multiple bash blocks

## Function Availability and Sourcing Order

### Critical Principle

Functions must be sourced BEFORE they are called. This is obvious but frequently violated in practice due to:

1. **Subprocess isolation**: Functions don't persist across bash blocks
2. **Implicit assumptions**: Developers assume library loading happens automatically
3. **Code review gaps**: Runtime execution order differs from file order

### Standard Sourcing Order for Orchestration Commands

All orchestration commands (/coordinate, /orchestrate, /supervise) MUST use this sourcing order:

```bash
# 1. Project directory detection (first)
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# 2. State machine core
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 3. Error handling and verification (BEFORE any checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 4. Additional libraries as needed
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
# ... other libraries via source_required_libraries()
```

### Why This Order Matters

**Dependency Chain**:
- `verify_state_variable()` requires `STATE_FILE` variable (from state-persistence.sh)
- `handle_state_error()` requires `append_workflow_state()` function (from state-persistence.sh)
- Both functions called during initialization for verification checkpoints
- **Therefore**: state-persistence → error-handling/verification → checkpoints

**Rationale**:
1. State machine libraries must load first (define state management)
2. Error handling and verification depend on state persistence
3. Verification checkpoints use both error handling and verification functions
4. All other libraries can load after these foundations

### Anti-Pattern: Premature Function Calls

```bash
# ❌ WRONG: Function called before library sourced
verify_state_variable "WORKFLOW_SCOPE" || exit 1

# ... many lines later ...
source "${LIB_DIR}/verification-helpers.sh"
```

**Error Symptom**:
```
bash: verify_state_variable: command not found
```

**Fix**: Source library before calling function

```bash
# ✓ CORRECT: Source library first
source "${LIB_DIR}/verification-helpers.sh"

# ... now functions are available ...
verify_state_variable "WORKFLOW_SCOPE" || exit 1
```

### Detection

Use validation script to catch sourcing order violations:

```bash
bash .claude/tests/test_library_sourcing_order.sh
```

This test validates:
- Functions are sourced before first call
- Libraries have source guards (safe to source multiple times)
- Dependency order is correct (state-persistence before dependent libraries)
- Early sourcing (critical libraries loaded within first 150 lines)

### Source Guards Enable Safe Re-Sourcing

All library files use source guards to prevent duplicate execution:

```bash
# From verification-helpers.sh:11-14
if [ -n "${VERIFICATION_HELPERS_SOURCED:-}" ]; then
  return 0
fi
export VERIFICATION_HELPERS_SOURCED=1
```

This pattern makes it safe to source libraries multiple times:
- First sourcing: Loads functions and sets guard variable
- Subsequent sourcing: Guard returns immediately, no-op
- Zero performance penalty (guard check is instant)

**Implication**: Including a library in both early sourcing AND in REQUIRED_LIBS array is safe and recommended.

### Related Specifications

- **Spec 675**: Library sourcing order fix (this specification)
- **Spec 620**: Bash history expansion fixes (subprocess isolation discovery)
- **Spec 630**: State persistence architecture (cross-block state management)

## Anti-Patterns

### Anti-Pattern 1: Using `$$` for Cross-Block State

**Problem**: Process ID changes per block, making `$$`-based filenames inaccessible.

**Example**:
```bash
# Block 1
STATE_FILE="/tmp/workflow_$$.sh"
echo "export VAR=value" > "$STATE_FILE"
# Creates: /tmp/workflow_12345.sh

# Block 2 (different PID)
STATE_FILE="/tmp/workflow_$$.sh"  # Now /tmp/workflow_12346.sh
source "$STATE_FILE"  # ✗ File not found
```

**Fix**: Use Pattern 1 (Fixed Semantic Filenames).

### Anti-Pattern 2: Assuming Exports Work Across Blocks

**Problem**: Environment variables don't persist across subprocess boundaries.

**Example**:
```bash
# Block 1
export WORKFLOW_ID="coord_123"
export CURRENT_STATE="research"

# Block 2
echo "State: $CURRENT_STATE"  # ✗ Empty (export lost)
```

**Fix**: Use state persistence library or write to files.

### Anti-Pattern 3: Premature Trap Handlers

**Problem**: Traps fire at block exit, not workflow exit, causing premature cleanup.

**Example**:
```bash
# Block 1 (early in workflow)
trap 'cleanup_temp_files' EXIT

# Block 2 needs temp files
# ✗ Files already deleted by Block 1's EXIT trap
```

**Fix**: Use Pattern 5 (Cleanup on Completion Only).

### Anti-Pattern 4: Code Review Without Runtime Testing

**Problem**: Subprocess isolation issues only appear at runtime, not code review.

**Example**:
```bash
# Looks correct in code review:
export REPORT_PATHS=("report1.md" "report2.md")

# Next block attempts to use it
for report in "${REPORT_PATHS[@]}"; do  # ✗ Array empty at runtime
  echo "$report"
done
```

**Fix**: Always test bash block sequences with actual subprocess execution.

### Anti-Pattern 5: Using BASH_SOURCE for Script Directory Detection

**Problem**: `BASH_SOURCE[0]` is empty in Claude Code's bash block execution context, causing SCRIPT_DIR to resolve incorrectly.

**Example**:
```bash
# ❌ ANTI-PATTERN: BASH_SOURCE-based SCRIPT_DIR (fails in Claude Code)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/core/detect-project-dir.sh"
# BASH_SOURCE[0] is empty → SCRIPT_DIR=/current/working/directory
# Path resolves to: /current/working/directory/../lib/ (WRONG)
# Expected path: /project/root/.claude/lib/ (CORRECT)
```

**Why It Fails**:
- Claude Code executes bash blocks as separate subprocesses without preserving script metadata
- `BASH_SOURCE[0]` requires being executed from a script file with `bash script.sh`
- Bash blocks are executed more like `bash -c 'commands'`, where BASH_SOURCE is undefined
- This creates a bootstrap paradox: need `detect-project-dir.sh` to find project directory, but need project directory to source `detect-project-dir.sh`

**Fix**: Use inline CLAUDE_PROJECT_DIR detection with git-based discovery:
```bash
# ✓ CORRECT: Inline git-based CLAUDE_PROJECT_DIR detection
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

# Validate CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Now source libraries using absolute paths
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
source "$UTILS_DIR/workflow-state-machine.sh"
```

**Impact**:
- Affected commands: `/plan`, `/implement`, `/expand`, `/collapse`
- Severity: Critical (commands completely non-functional)
- Fixed in: Spec 732 (plan.md), remaining commands require separate fixes

### Anti-Pattern 6: Missing Library Re-Sourcing

**Problem**: Calling library function without re-sourcing in current block.

**Example** (from /build Block 2 violation):

```bash
# Block 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
save_completed_states_to_state  # Works

# Block 2 (NEW SUBPROCESS)
# Library NOT re-sourced - functions not available!
save_completed_states_to_state  # Exit code 127: command not found
```

**Error Message**:
```
bash: save_completed_states_to_state: command not found
```

**Root Cause**: Each bash block runs in a new subprocess. Functions sourced in Block 1 do not exist in Block 2's process space.

**Fix**: Re-source library in Block 2:

```bash
# Block 2 (NEW SUBPROCESS)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
save_completed_states_to_state  # Now works
```

**Detection Methods**:
1. Error message: `bash: FUNCTION_NAME: command not found` (exit code 127)
2. Linter: `bash .claude/scripts/lint/check-library-sourcing.sh` detects this pattern
3. Defensive check: Add `type FUNCTION_NAME &>/dev/null` before calls

**Real-World Impact**: This anti-pattern caused 57% of /build command failures. The function `save_completed_states_to_state()` was called in Block 2 without sourcing `workflow-state-machine.sh`, despite the library being correctly sourced in Block 1.

**Prevention**: Follow the [Three-Tier Sourcing Pattern](../reference/standards/code-standards.md#three-tier-library-sourcing-pattern) in every bash block.

### Anti-Pattern 7: Bare Error Suppression on Critical Libraries

**Problem**: Using `2>/dev/null` without fail-fast handler hides sourcing failures.

**Example**:

```bash
# ANTI-PATTERN: Bare suppression hides failure
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null
# If file doesn't exist or has syntax error, execution continues silently
# Function calls fail much later with exit code 127, far from root cause

# CORRECT: Fail-fast pattern
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Why Bare Suppression is Dangerous**:
1. Hides file-not-found errors
2. Hides syntax errors in library
3. Hides permission errors
4. Causes exit code 127 much later in execution
5. Makes debugging extremely difficult

**Critical Libraries Requiring Fail-Fast**:
- `state-persistence.sh`
- `workflow-state-machine.sh`
- `error-handling.sh`
- `library-version-check.sh`

**Detection**: Linter flags `source.*2>/dev/null$` without fail-fast handler.

**See Also**: [Exit Code 127 Troubleshooting Guide](../troubleshooting/exit-code-127-command-not-found.md)

---

## Examples

### Example 1: Research Phase State Management

```bash
# === BASH BLOCK 1: Research Invocation ===

# Re-source libraries (subprocess isolation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Load state from fixed location
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Invoke research agents...
# Research creates: /path/to/report1.md, /path/to/report2.md

# Save report paths to state file (not exported variables)
REPORT_PATHS=(
  "/path/to/report1.md"
  "/path/to/report2.md"
)
append_workflow_state "REPORT_PATHS_JSON" "$(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .)"

# === BASH BLOCK 2: Research Verification ===

# Re-source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"

# Load state from fixed location
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Reconstruct array from JSON (subprocess isolation requires this)
if [ -n "${REPORT_PATHS_JSON:-}" ]; then
  mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
fi

# Verify reports exist
for report in "${REPORT_PATHS[@]}"; do
  if [ -f "$report" ]; then
    echo "✓ Report verified: $report"
  else
    echo "✗ Report missing: $report"
  fi
done
```

### Example 2: Two-Step Execution Pattern

```bash
# Part 1: Initialize state and save to file
WORKFLOW_ID="coordinate_$(date +%s)"
echo "$WORKFLOW_ID" > "${HOME}/.claude/tmp/coordinate_state_id.txt"

STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
cat > "$STATE_FILE" <<'EOF'
#!/usr/bin/env bash
export WORKFLOW_DESCRIPTION="Implement authentication"
export CURRENT_STATE="initialize"
export WORKFLOW_SCOPE="full-implementation"
EOF

# Part 2: Source state file (in separate bash block)
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"

if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
  echo "Loaded state: $CURRENT_STATE"
else
  echo "ERROR: State file not found"
  exit 1
fi
```

## Integration with State-Based Orchestration

The bash block execution model is a foundational constraint for the state-based orchestration architecture documented in [State-Based Orchestration Overview](../architecture/state-based-orchestration-overview.md).

### State Machine Coordination

State transitions must be persisted to files because bash blocks cannot share memory:

```bash
# Block 1: Transition from research to plan
sm_transition "$STATE_PLAN"
append_workflow_state "CURRENT_STATE" "$STATE_PLAN"
# State persisted to file: workflow_123.sh

# Block 2: Load current state
load_workflow_state "$WORKFLOW_ID"
if [ "$CURRENT_STATE" = "$STATE_PLAN" ]; then
  echo "Executing planning phase"
fi
```

### Checkpoint Recovery

Checkpoint files enable workflow resume across bash block boundaries:

```bash
# Block N-1: Save checkpoint before complex operation
save_checkpoint "research" "phase_complete" '{
  "reports_created": 3,
  "verification_status": "success"
}'

# Block N: Resume from checkpoint if operation failed
CHECKPOINT=$(load_checkpoint "research" "phase_complete")
if [ -n "$CHECKPOINT" ]; then
  REPORTS_CREATED=$(echo "$CHECKPOINT" | jq -r '.reports_created')
  echo "Resuming: $REPORTS_CREATED reports already created"
fi
```

## Troubleshooting

### Symptom: Variable "Disappears" Between Blocks

**Cause**: Export used instead of file-based persistence.

**Diagnosis**:
```bash
# Block 1
export MY_VAR="value"
echo "Block 1: MY_VAR=$MY_VAR"  # Shows: value

# Block 2
echo "Block 2: MY_VAR=${MY_VAR:-unset}"  # Shows: unset
```

**Fix**: Use state persistence:
```bash
# Block 1
append_workflow_state "MY_VAR" "value"

# Block 2
load_workflow_state "$WORKFLOW_ID"
echo "Block 2: MY_VAR=$MY_VAR"  # Shows: value
```

### Symptom: "File Not Found" for Recently Created File

**Cause**: Using `$$` for filename, process ID changed.

**Diagnosis**:
```bash
# Block 1
echo "data" > /tmp/file_$$.txt
ls /tmp/file_*.txt  # Shows: /tmp/file_12345.txt

# Block 2
cat /tmp/file_$$.txt  # Looks for: /tmp/file_12346.txt (does not exist)
```

**Fix**: Use fixed semantic filename:
```bash
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
FILE_PATH="/tmp/file_${WORKFLOW_ID}.txt"
```

### Symptom: Cleanup Happens Too Early

**Cause**: Trap handler fires at block exit, not workflow exit.

**Diagnosis**:
```bash
# Block 1
trap 'rm -f /tmp/temp_files_*.txt' EXIT
echo "data" > /tmp/temp_files_data.txt
# Block exits → trap fires → files deleted

# Block 2
cat /tmp/temp_files_data.txt  # File not found (already deleted)
```

**Fix**: Only trap in final completion function.

## Related Documentation

- [State-Based Orchestration Overview](../architecture/state-based-orchestration-overview.md) - Complete architecture built on subprocess isolation patterns
- [State Machine Orchestrator Development](../guides/orchestration/state-machine-orchestrator-development.md) - Using these patterns in new orchestrators
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - General command development including bash block patterns
- [Orchestration Best Practices](../guides/orchestration/orchestration-best-practices.md) - High-level orchestration patterns
- [/coordinate Command Guide](../guides/commands/build-command-guide.md) - Real-world usage of these patterns

## Historical Context

These patterns were discovered and validated through:

- **Spec 620**: Six fixes for bash history expansion errors, leading to discovery of subprocess isolation (100% test pass rate achieved)
- **Spec 630**: State persistence architecture, fixing report path loss across blocks (40+ fixes applied)

Key lesson learned: **Code review alone is insufficient for bash block sequences**. Runtime testing with actual subprocess execution is mandatory to catch subprocess isolation issues.

## Anti-Patterns Reference

This section consolidates all anti-patterns for quick reference. Each entry includes an ID, detection method, and link to detailed documentation.

### AP-001: PID-Based Cross-Block Filenames

**ID**: AP-001
**Severity**: ERROR
**Detection**: Manual review, pattern search for `\$\$` in filenames

**Description**: Using `$$` for filenames causes files to be inaccessible across bash blocks because process ID changes.

**Example**:
```bash
# WRONG
STATE_FILE="/tmp/workflow_$$.sh"
# Block 1 creates: /tmp/workflow_12345.sh
# Block 2 looks for: /tmp/workflow_12346.sh (not found)
```

**Correct Pattern**: Use fixed semantic filenames. See [Pattern 1: Fixed Semantic Filenames](#pattern-1-fixed-semantic-filenames).

---

### AP-002: Assuming Exports Persist

**ID**: AP-002
**Severity**: ERROR
**Detection**: Pattern search for `export` followed by cross-block usage

**Description**: Environment variables exported in one bash block do not persist to subsequent blocks due to subprocess isolation.

**Example**:
```bash
# WRONG
# Block 1
export WORKFLOW_ID="coord_123"
# Block 2
echo "$WORKFLOW_ID"  # Empty - export lost
```

**Correct Pattern**: Use state persistence library. See [Pattern 4: State Persistence Library](#pattern-4-state-persistence-library).

---

### AP-003: Premature Trap Handlers

**ID**: AP-003
**Severity**: WARNING
**Detection**: `trap.*EXIT` in early workflow blocks

**Description**: Trap handlers fire at block exit, not workflow exit, causing premature cleanup.

**Example**:
```bash
# WRONG: In Block 1
trap 'rm -f /tmp/temp_*.txt' EXIT
# Files deleted when Block 1 exits, not when workflow completes
```

**Correct Pattern**: Set cleanup traps only in final completion function. See [Pattern 6: Cleanup on Completion Only](#pattern-6-cleanup-on-completion-only).

---

### AP-004: Missing Library Re-Sourcing

**ID**: AP-004
**Severity**: ERROR
**Detection**: `check-library-sourcing.sh` linter

**Description**: Calling library functions without re-sourcing in current block causes exit code 127.

**Example**:
```bash
# Block 1
source lib.sh
my_function  # Works
# Block 2 (no source statement)
my_function  # Exit 127: command not found
```

**Correct Pattern**: Re-source all required libraries at start of every bash block. See [Mandatory Re-Sourcing Requirements](#mandatory-re-sourcing-requirements).

---

### AP-005: BASH_SOURCE Directory Detection

**ID**: AP-005
**Severity**: ERROR
**Detection**: Pattern search for `BASH_SOURCE`

**Description**: `BASH_SOURCE[0]` is empty in Claude Code's bash block execution context.

**Example**:
```bash
# WRONG
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# BASH_SOURCE is empty -> SCRIPT_DIR resolves incorrectly
```

**Correct Pattern**: Use git-based CLAUDE_PROJECT_DIR detection. See [Anti-Pattern 5](#anti-pattern-5-using-bash_source-for-script-directory-detection).

---

### AP-006: Bare Error Suppression on Critical Libraries

**ID**: AP-006
**Severity**: ERROR
**Detection**: `check-library-sourcing.sh` linter

**Description**: Using `2>/dev/null` on critical library sourcing without fail-fast handler hides failures.

**Example**:
```bash
# WRONG: Bare suppression
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null
# Silently fails, causes exit 127 later
```

**Correct Pattern**: Add fail-fast handler after suppression. See [Anti-Pattern 7](#anti-pattern-7-bare-error-suppression-on-critical-libraries).

---

### AP-007: State Persistence Error Suppression

**ID**: AP-007
**Severity**: ERROR
**Detection**: `lint_error_suppression.sh`

**Description**: Suppressing errors on state persistence functions hides critical failures.

**Example**:
```bash
# WRONG
save_completed_states_to_state 2>/dev/null
save_completed_states_to_state || true
```

**Correct Pattern**: Use explicit error handling with logging. See [Code Standards - Error Suppression Policy](../reference/standards/code-standards.md#error-suppression-policy).

---

### AP-008: Deprecated State Paths

**ID**: AP-008
**Severity**: ERROR
**Detection**: `lint_error_suppression.sh`

**Description**: Using deprecated state directory paths causes state management failures.

**Example**:
```bash
# WRONG: Deprecated paths
STATE_FILE=".claude/data/states/workflow.sh"
STATE_FILE=".claude/data/workflows/workflow.sh"
```

**Correct Pattern**: Use standard `.claude/tmp/workflow_*.sh` path.

---

### AP-009: Preprocessing-Unsafe Conditionals

**ID**: AP-009
**Severity**: ERROR
**Detection**: `lint_bash_conditionals.sh`

**Description**: Using `!` in `[[ ]]` conditionals causes preprocessing errors.

**Example**:
```bash
# WRONG: Preprocessing-unsafe
if [[ ! "$VAR" = value ]]; then
```

**Correct Pattern**: Use exit code capture pattern:
```bash
# CORRECT
[[ "$VAR" = value ]]
IS_MATCH=$?
if [ $IS_MATCH -ne 0 ]; then
```

---

### AP-010: Eager Directory Creation

**ID**: AP-010
**Severity**: WARNING
**Detection**: `validate-agent-behavioral-file.sh`, manual review

**Description**: Creating artifact directories at workflow startup leaves empty directories on failure.

**Example**:
```bash
# WRONG: Eager creation in setup
mkdir -p "$REPORTS_DIR"
mkdir -p "$DEBUG_DIR"
# If workflow fails, empty directories persist
```

**Correct Pattern**: Use lazy directory creation with `ensure_artifact_directory()` immediately before writing files. See [Code Standards - Directory Creation Anti-Patterns](../reference/standards/code-standards.md#directory-creation-anti-patterns).

---

### Anti-Pattern Detection Summary

| ID | Anti-Pattern | Detection Tool | Enforcement |
|----|--------------|----------------|-------------|
| AP-001 | PID-based filenames | Manual | Pre-commit review |
| AP-002 | Export persistence assumption | Manual | Pre-commit review |
| AP-003 | Premature trap handlers | Manual | Pre-commit review |
| AP-004 | Missing library re-sourcing | check-library-sourcing.sh | Pre-commit hook |
| AP-005 | BASH_SOURCE detection | Manual | Pre-commit review |
| AP-006 | Bare error suppression | check-library-sourcing.sh | Pre-commit hook |
| AP-007 | State persistence suppression | lint_error_suppression.sh | Pre-commit hook |
| AP-008 | Deprecated state paths | lint_error_suppression.sh | Pre-commit hook |
| AP-009 | Preprocessing-unsafe conditionals | lint_bash_conditionals.sh | Pre-commit hook |
| AP-010 | Eager directory creation | validate-agent-behavioral-file.sh | Manual |

See [Enforcement Mechanisms Reference](../reference/standards/enforcement-mechanisms.md) for complete enforcement tooling documentation.

## Summary

**Core Principle**: Each bash block in Claude Code commands is a separate subprocess. Only files persist.

**Validated Patterns**:
1. Fixed semantic filenames (not `$$`-based)
2. Save-before-source pattern for state ID
3. State persistence library for cross-block state
4. Re-source libraries in every block
5. Cleanup traps only in final completion function

**Critical Anti-Patterns**:
1. Using `$$` for cross-block state
2. Assuming exports work across blocks
3. Premature trap handlers
4. Code review without runtime testing

**Testing Requirement**: Always test bash block sequences with actual subprocess execution to validate cross-block communication.
