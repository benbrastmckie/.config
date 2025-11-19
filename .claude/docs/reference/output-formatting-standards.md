# Output Formatting Standards

Comprehensive standards for command output formatting to ensure clean, readable Claude Code display with minimal visual noise.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Output Suppression Patterns](#output-suppression-patterns)
3. [Block Consolidation Patterns](#block-consolidation-patterns)
4. [Comment Standards](#comment-standards)
5. [Output vs Error Distinction](#output-vs-error-distinction)
6. [Related Documentation](#related-documentation)

---

## Core Principles

### Principle 1: Suppress Success Output

Success messages, progress indicators, and intermediate state updates create display noise without adding value. Suppress all non-essential output.

### Principle 2: Preserve Error Visibility

Errors, warnings, and final summaries MUST remain visible. The goal is noise reduction, not silence.

### Principle 3: Minimize Bash Block Count

Each bash block creates a separate display element. Consolidate related operations into fewer blocks.

### Principle 4: Single Summary Line per Block

Each block should output a single summary line showing the net result, not individual operation results.

### Principle 5: WHAT Not WHY in Comments

Comments in executable files describe what the code does, not why it was designed that way. Design rationale belongs in guides.

---

## Output Suppression Patterns

### Library Sourcing Suppression

**Problem**: Library sourcing produces verbose output (function definitions, initialization messages).

**Pattern**:
```bash
source "${LIB_DIR}/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Why**: Redirects all library output to /dev/null while preserving error handling. Errors go to stderr for visibility.

### Directory Operations Suppression

**Problem**: mkdir, cp, mv operations produce unnecessary output.

**Pattern**:
```bash
mkdir -p "$OUTPUT_DIR" 2>/dev/null || true
```

**Why**: Directory operations either succeed silently or are handled elsewhere. The `|| true` prevents script exit on non-critical failures.

### Single Summary Line Pattern

**Problem**: Multiple echo statements create visual noise.

**Anti-Pattern** (incorrect):
```bash
echo "Starting workflow initialization..."
echo "Loading state machine..."
echo "Validating configuration..."
echo "Setting up directories..."
echo "Initialization complete"
```

**Pattern** (correct):
```bash
# Perform all operations silently
source "$LIB" 2>/dev/null || exit 1
validate_config || exit 1
mkdir -p "$DIR" 2>/dev/null

# Single summary line
echo "Setup complete: $WORKFLOW_ID"
```

### Debug Log Pattern

**Problem**: Debug output clutters production display.

**Pattern**:
```bash
if [ "${DEBUG:-false}" = "true" ]; then
  echo "DEBUG: Variable value: $VAR" >&2
fi
```

**Why**: Debug output controlled by environment variable and sent to stderr.

### Command Output Suppression

**Problem**: Sub-command output adds noise when only status matters.

**Pattern**:
```bash
if git add -A >/dev/null 2>&1; then
  echo "Changes staged"
else
  echo "ERROR: Git staging failed" >&2
  exit 1
fi
```

---

## Block Consolidation Patterns

### Target Block Count

Commands SHOULD use 2-3 bash blocks maximum:

| Block Type | Purpose | Examples |
|-----------|---------|----------|
| **Setup** | Capture, validate, source, init, allocate | Argument capture, library sourcing, workflow ID allocation |
| **Execute** | Main workflow logic | Core processing, agent invocations, state transitions |
| **Cleanup** | Verify, complete, summary | Final validation, completion signal, summary output |

### Block Consolidation Rules

1. **Combine consecutive operations** that don't require intermediate verification
2. **Separate operations** that need explicit checkpoints or error handling
3. **Keep Task invocations** in their own block (for response visibility)
4. **Consolidate library sourcing** into single setup block

### Before/After Example

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
- mkdir output dir
- source libraries
- validate config
- init state machine
- allocate workflow ID
- persist state

Block 2 (Execute):
- main workflow logic
```

### Consolidation Benefits

- **50-67% reduction** in display noise (6 blocks to 2-3)
- **Faster execution** (fewer subprocess spawns)
- **Cleaner output** (single summary per block)
- **Easier debugging** (logical groupings)

### Block Structure Template

```bash
# Block 1: Setup
set +H
mkdir -p "$DIR" 2>/dev/null
source "${LIB}/state-machine.sh" 2>/dev/null || exit 1
source "${LIB}/persistence.sh" 2>/dev/null || exit 1
sm_init "$DESC" "$CMD" "$TYPE" || exit 1
WORKFLOW_ID=$(allocate_workflow_id) || exit 1
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID" || exit 1
echo "Setup complete: $WORKFLOW_ID"
```

---

## Comment Standards

### WHAT Not WHY Enforcement

Comments in executable files (commands, agents) describe WHAT the code does. Design rationale (WHY) belongs in guide files.

### Correct Patterns

```bash
# Load state management functions
source lib.sh

# Validate required variables
[ -z "$VAR" ] && exit 1

# Initialize workflow with captured description
sm_init "$DESC" "$CMD"
```

### Incorrect Patterns

```bash
# We source this here because subprocess isolation requires re-sourcing
# in every bash block since functions don't persist across boundaries
source lib.sh  # WRONG: explains WHY, not WHAT

# We need this check because the state machine won't initialize
# correctly without these values and will cause silent failures
[ -z "$VAR" ] && exit 1  # WRONG: justification belongs in guide
```

### Where WHY Content Belongs

- **Guides** (`.claude/docs/guides/`): Explain design decisions, patterns, trade-offs
- **Concepts** (`.claude/docs/concepts/`): Document architectural principles
- **Reference** (`.claude/docs/reference/`): Specify standards and requirements

### Comment Density Guidelines

- **Commands**: Minimal comments (WHAT only), <250 lines total
- **Agents**: Brief section comments, <400 lines total
- **Libraries**: Function documentation (what, parameters, returns)

---

## Output vs Error Distinction

### What to Suppress

| Category | Examples | Action |
|----------|----------|--------|
| Success messages | "File created", "Operation complete" | Suppress with >/dev/null |
| Progress indicators | "Processing...", "Loading..." | Remove entirely |
| Intermediate state | "Setting X to Y", "Validated Z" | Suppress |
| Library initialization | Function definitions, module loads | Suppress with 2>/dev/null |

### What to Preserve

| Category | Examples | Action |
|----------|----------|--------|
| Errors | "ERROR: File not found" | Print to stderr |
| Warnings | "WARN: Deprecated pattern" | Print to stderr |
| Final summaries | "Setup complete: workflow_123" | Single line per block |
| User-needed data | File paths, URLs, identifiers | Print explicitly |

### Stderr vs Stdout

```bash
# Errors to stderr
echo "ERROR: Configuration invalid" >&2

# Warnings to stderr
echo "WARN: Using deprecated pattern" >&2

# Success summaries to stdout
echo "Setup complete: $WORKFLOW_ID"
```

### Relationship to Error Enhancement

Output suppression applies to **success and progress output only**. Errors remain verbose per [Error Enhancement Guide](../guides/error-enhancement-guide.md) standards:

- Errors use WHICH/WHAT/WHERE structure
- Errors include resolution guidance
- Errors are not suppressed

---

## Related Documentation

### Core References
- [Code Standards](code-standards.md) - Overall code standards including output patterns
- [Command Authoring Standards](command-authoring-standards.md) - Execution directive and task patterns
- [Command Architecture Standards](command_architecture_standards.md) - Command file design requirements

### Patterns and Concepts
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md) - Subprocess isolation patterns
- [Executable/Documentation Separation](../concepts/patterns/executable-documentation-separation.md) - WHAT vs WHY separation

### Guides
- [Logging Patterns](../guides/logging-patterns.md) - Complete logging and output guidance
- [Error Enhancement Guide](../guides/error-enhancement-guide.md) - Structured error messages
- [Command Development Guide](../guides/command-development-guide.md) - Complete command development

### Templates
- [Bash Block Template](../guides/_template-bash-block.md) - Standard bash block structure

---

**Last Updated**: 2025-11-18
**Spec Reference**: 794_001_comprehensive_output_formatting_refactormd_to
