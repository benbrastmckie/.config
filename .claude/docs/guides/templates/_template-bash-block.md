# Standardized Bash Block Template

## Purpose

This template provides the standardized pattern for bash blocks in orchestration commands (coordinate, orchestrate, supervise). It ensures compliance with Standard 15 (Library Sourcing Order) and Standard 0 (Execution Enforcement).

## When to Use This Template

Use this template when:
- Creating new bash blocks in orchestration commands
- Adding initialization logic to command phases
- Implementing state management across bash blocks
- Integrating with the state machine and persistence libraries

## Template Structure

### Block 1: Initial Bash Block (State Initialization)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get CLAUDE_PROJECT_DIR (may not be exported from parent)
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export CLAUDE_PROJECT_DIR

# === STEP 1: Source Libraries Using Three-Tier Pattern ===
# Option A: Use source-libraries-inline.sh utility (recommended)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" || exit 1
source_critical_libraries || exit 1
source_workflow_libraries  # Graceful degradation

# Option B: Inline three-tier pattern (if source-libraries-inline.sh unavailable)
# Tier 1: Critical Foundation (fail-fast required)
# source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
#   echo "ERROR: Failed to source state-persistence.sh" >&2
#   exit 1
# }
# source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
#   echo "ERROR: Failed to source workflow-state-machine.sh" >&2
#   exit 1
# }
# source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
#   echo "ERROR: Failed to source error-handling.sh" >&2
#   exit 1
# }
#
# Tier 2: Workflow Support (graceful degradation)
# source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || true

# === STEP 3: Verification Checkpoint (Standard 0) ===
# Verify critical functions are available before proceeding

if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: verify_file_created function not available after library sourcing"
  exit 1
fi

if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

# === STEP 4: Initialize Workflow State ===
# Create new workflow state and save state ID for subsequent blocks

# Generate unique workflow ID (timestamp-based for reproducibility)
WORKFLOW_ID="<command_name>_$(date +%s)"

# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Pattern 1: Fixed Semantic Filename (bash-block-execution-model.md:163-191)
# Save workflow ID to file for subsequent blocks using fixed location
<COMMAND>_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/<command_name>_state_id.txt"
echo "$WORKFLOW_ID" > "$<COMMAND>_STATE_ID_FILE"

# VERIFICATION CHECKPOINT: Verify state ID file created successfully (Standard 0)
verify_file_created "$<COMMAND>_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created at $<COMMAND>_STATE_ID_FILE" 1
}

# Save workflow ID to state for subsequent blocks
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "<COMMAND>_STATE_ID_FILE" "$<COMMAND>_STATE_ID_FILE"

# === STEP 5: Command-Specific Initialization ===
# Add your command-specific initialization logic here
# Example: Parse arguments, validate inputs, set initial variables

# Single summary line (output suppression pattern)
echo "Setup complete: $WORKFLOW_ID"
```

### Block 2+: Subsequent Bash Blocks (State Loading)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get CLAUDE_PROJECT_DIR (may not be exported from parent)
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export CLAUDE_PROJECT_DIR

# === STEP 1: Source Libraries Using Three-Tier Pattern ===
# CRITICAL: Each bash block runs in a NEW subprocess - all libraries must be re-sourced

# Option A: Use source-libraries-inline.sh utility (recommended)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" || exit 1
source_critical_libraries || exit 1
source_workflow_libraries  # Graceful degradation

# === STEP 2: Load Workflow State (AFTER library sourcing) ===
# This prevents other libraries from resetting variables with conditional initialization

# Load workflow ID from fixed semantic filename
<COMMAND>_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/<command_name>_state_id.txt"

if [ ! -f "$<COMMAND>_STATE_ID_FILE" ]; then
  echo "ERROR: State ID file not found: $<COMMAND>_STATE_ID_FILE"
  echo "This indicates Bash Block 1 did not execute successfully"
  exit 1
fi

WORKFLOW_ID=$(cat "$<COMMAND>_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# === STEP 3: Source Error Handling and Verification ===
# Pattern 5 (Conditional Initialization) preserves loaded state

source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# === STEP 4: Source Additional Libraries ===
# Add any command-specific libraries needed for this phase

source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
# Add more as needed

# === STEP 5: Verification Checkpoint (Standard 0) ===

if ! command -v verify_state_variable &>/dev/null; then
  echo "ERROR: verify_state_variable function not available after library sourcing"
  exit 1
fi

if ! command -v handle_state_error &>/dev/null; then
  echo "ERROR: handle_state_error function not available after library sourcing"
  exit 1
fi

# === STEP 6: Verify Critical State Variables Loaded ===
# Add verification for variables that should exist from previous blocks

verify_state_variable "WORKFLOW_ID" || {
  handle_state_error "WORKFLOW_ID not loaded from state" 1
}

# Add more variable verifications as needed for this phase

# === STEP 7: Phase-Specific Logic ===
# Add your phase-specific implementation here

echo "✓ Phase initialization complete. Proceeding with phase execution..."
```

## Key Patterns Explained

### 1. Library Sourcing Order (Standard 15)

**Order Matters**: Libraries must be sourced in strict dependency order:

1. **State machine and persistence** - Foundation for all state operations
2. **Error handling and verification** - Required before any checkpoints or error handling
3. **Additional libraries** - Workflow-specific utilities and helpers
4. **Verification checkpoint** - Confirm all functions are available

**Why This Order?**
- State libraries provide `init_workflow_state`, `load_workflow_state`, `append_workflow_state`
- Error libraries provide `handle_state_error` for error handling
- Verification libraries provide `verify_file_created`, `verify_state_variable` for checkpoints
- All subsequent code depends on these functions being available

### 2. State Loading Pattern (Bash Block Execution Model)

**Block 1** (Initial):
- Creates new workflow state
- Saves state ID to fixed semantic filename
- Persists variables via `append_workflow_state`

**Block 2+** (Subsequent):
- Loads state ID from fixed semantic filename
- Loads workflow state via `load_workflow_state`
- Re-sources libraries (bash blocks are separate processes)
- Verifies critical variables are present

**Why Fixed Semantic Filename?**
- Bash blocks run in separate processes
- In-memory variables do NOT persist across blocks
- File-based state ID enables state restoration
- See: `.claude/docs/concepts/bash-block-execution-model.md`

### 3. Verification Checkpoints (Standard 0)

**Function Availability**:
```bash
if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: verify_file_created function not available"
  exit 1
fi
```

**File Creation**:
```bash
verify_file_created "$FILE_PATH" "Description" "Phase Name" || {
  handle_state_error "File verification failed" 1
}
```

**State Variable Presence**:
```bash
verify_state_variable "VARIABLE_NAME" || {
  handle_state_error "Variable not in state" 1
}
```

**Why Checkpoints?**
- Fail-fast error detection at point of failure
- Prevents downstream unbound variable errors
- Provides actionable diagnostics for debugging
- See: `.claude/docs/reference/architecture/overview.md#standard-0`

### 4. Conditional Initialization (Pattern 5)

**Preserve Loaded Values**:
```bash
# ✓ CORRECT (preserves loaded values)
VARIABLE_NAME="${VARIABLE_NAME:-default_value}"

# ❌ WRONG (overwrites loaded values)
VARIABLE_NAME="default_value"
```

**Why This Pattern?**
- Libraries may be re-sourced in subsequent bash blocks
- `load_workflow_state` exports variables to environment
- Conditional initialization preserves these exported values
- Prevents state loss during library re-sourcing
- See: `.claude/docs/concepts/bash-block-execution-model.md#pattern-5`

## Customization Guidelines

### Command-Specific Placeholders

Replace these placeholders in the template:

- `<command_name>` - Command name in lowercase (e.g., `coordinate`, `orchestrate`)
- `<COMMAND>` - Command name in uppercase (e.g., `COORDINATE`, `ORCHESTRATE`)
- Additional libraries in Step 4 - Add command-specific library sourcing
- Phase-specific logic in Step 7 - Add command implementation

### Adding New Libraries

When adding additional library sourcing:

1. Add after Step 3 (error/verification libraries)
2. Before Step 4 (verification checkpoint)
3. Ensure library has source guard
4. Use conditional initialization in library

Example:
```bash
# Step 4: Source additional libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
# Context pruning not yet implemented
source "${LIB_DIR}/dependency-analyzer.sh"   # New library
```

### Verifying State Variables

Add verification for critical variables:

```bash
# Verify variables loaded from previous blocks
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "WORKFLOW_SCOPE not loaded from state" 1
}

verify_state_variable "RESEARCH_COMPLEXITY" || {
  handle_state_error "RESEARCH_COMPLEXITY not loaded from state" 1
}
```

## Common Mistakes to Avoid

### ❌ Wrong: Library Sourcing Before State Loading

```bash
# BAD: Other libraries sourced before load_workflow_state
source "${LIB_DIR}/workflow-initialization.sh"
load_workflow_state "$WORKFLOW_ID"
# ^ This may cause workflow-initialization.sh to reset WORKFLOW_SCOPE
```

### ✓ Correct: State Loading Before Other Libraries

```bash
# GOOD: Load state first, then source additional libraries
load_workflow_state "$WORKFLOW_ID"
source "${LIB_DIR}/workflow-initialization.sh"
# ^ Conditional initialization in library preserves loaded state
```

### ❌ Wrong: Function Calls Before Library Sourcing

```bash
# BAD: Function called before library sourced
verify_file_created "$FILE"  # ERROR: function not found
source "${LIB_DIR}/verification-helpers.sh"
```

### ✓ Correct: Library Sourcing Before Function Calls

```bash
# GOOD: Source library first, then call functions
source "${LIB_DIR}/verification-helpers.sh"
verify_file_created "$FILE"  # ✓ Function available
```

### ❌ Wrong: No Verification Checkpoint

```bash
# BAD: Assumes functions are available without verification
source "${LIB_DIR}/verification-helpers.sh"
verify_file_created "$FILE"  # May fail silently if sourcing failed
```

### ✓ Correct: Verification Checkpoint After Sourcing

```bash
# GOOD: Verify functions are available before using them
source "${LIB_DIR}/verification-helpers.sh"

if ! command -v verify_file_created &>/dev/null; then
  echo "ERROR: verify_file_created not available"
  exit 1
fi

verify_file_created "$FILE"  # ✓ Verified to exist
```

## Testing Your Bash Block

### Manual Testing

```bash
# Test Block 1 (initialization)
bash << 'EOF'
# Paste your Block 1 code here
# Should create state file and save state ID
EOF

# Test Block 2 (state loading)
bash << 'EOF'
# Paste your Block 2 code here
# Should load state and verify variables
EOF
```

### Verification Checklist

- [ ] Libraries sourced in correct order (state → error/verification → additional)
- [ ] Verification checkpoint after library sourcing
- [ ] State ID saved to fixed semantic filename (Block 1)
- [ ] State ID loaded from fixed semantic filename (Block 2+)
- [ ] `load_workflow_state` called before additional libraries (Block 2+)
- [ ] Critical variables verified after state loading
- [ ] All function calls occur after library sourcing
- [ ] Error handling uses `handle_state_error`
- [ ] File verification uses `verify_file_created`

## Related Documentation

- [Command Architecture Standards](.claude/docs/reference/architecture/overview.md) - Standards 0, 15, 16
- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [State Persistence Library](.claude/lib/core/state-persistence.sh) - State management API
- [Verification Helpers Library](.claude/lib/verification-helpers.sh) - Verification patterns
- [Error Handling Library](.claude/lib/core/error-handling.sh) - Error classification and recovery

## Version History

- 2025-11-14: Initial template created (Spec 716, Phase 1.4)
