# Agent Behavioral Guidelines

## Purpose

This document defines policies that apply specifically to AI agents (subagents invoked via Task tool). These guidelines complement [code-standards.md](code-standards.md) with agent-specific constraints that arise from Task tool subprocess isolation.

## Directory Creation Policy

### Requirement

Agents MUST use lazy directory creation - creating directories only immediately before writing files.

### Timing Requirement

Call `ensure_artifact_directory()` immediately before the Write tool invocation, not at agent startup.

```bash
# CORRECT: Lazy creation immediately before write
REPORT_PATH="${REPORTS_DIR}/001_research_report.md"

# Immediately before Write tool
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}

# Write tool creates file - directory guaranteed to exist
```

### Anti-Pattern: Eager Directory Creation

**NEVER** create artifact directories at agent startup:

```bash
# WRONG: Eager creation at agent initialization
source .claude/lib/core/unified-location-detection.sh

# Creating directories before knowing if files will be written
mkdir -p "$REPORTS_DIR"
mkdir -p "$DEBUG_DIR"
mkdir -p "$SUMMARIES_DIR"

# If agent fails before writing files, empty directories persist
```

**Impact**: Each failed workflow creates 1-3 empty subdirectories. Over 400-500 empty directories accumulated in production before this pattern was identified and remediated.

### Cleanup Consideration

Agents cannot guarantee cleanup on failure due to subprocess isolation:
- EXIT traps fire at task completion, not failure
- Parent command cannot reliably know which directories agent created
- Empty directories persist when workflows fail or are interrupted

**Solution**: Lazy creation ensures directories only exist when files exist.

### Exception: Atomic Operations

Eager creation is acceptable when directory creation is immediately followed by file creation in the same bash block:

```bash
# ACCEPTABLE: Atomic directory+file (same block)
mkdir -p "$BACKUP_DIR"
cp "$FILE" "$BACKUP_DIR/$(basename "$FILE").backup"
# File written immediately - no empty directory risk
```

## State Persistence Policy

### Requirement

Agents with `allowed-tools: None` MUST NOT attempt to persist state directly. They MUST use output-based patterns.

### Output-Based Pattern

```yaml
# Agent frontmatter
allowed-tools: None
```

```markdown
## Output Format

Return structured data for parent command to persist:

CLASSIFICATION_COMPLETE: {"type": "feature", "complexity": 3}

The parent command extracts and saves this to workflow state.
```

### Why Direct Persistence Fails

1. **No bash execution**: `allowed-tools: None` agents cannot execute bash commands
2. **Subprocess isolation**: Even with Bash tool, agents cannot access parent's STATE_FILE variable
3. **No shared memory**: Task tool creates isolated subprocess with no parent context

### Anti-Pattern: Bash Instructions in No-Tool Agents

```yaml
# WRONG: Contradiction between frontmatter and instructions
allowed-tools: None

## Instructions
After analysis, save results:
```bash
source .claude/lib/core/state-persistence.sh
append_workflow_state "RESULT" "$RESULT"
```
```

**Problem**: Agent cannot execute bash - instruction is impossible to follow.

**Fix**: Use output-based pattern - agent returns structured text, parent persists.

### Validation

Run `validate-agent-behavioral-file.sh` to detect contradictions:

```bash
bash .claude/scripts/validate-agent-behavioral-file.sh .claude/agents/my-agent.md
```

## Error Return Protocol

### Requirement

Agents MUST return structured error signals for parent command parsing and centralized logging.

### Error Signal Format

When an unrecoverable error occurs:

```markdown
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Required file not found",
  "details": {"expected": "/path/to/file.md"}
}

TASK_ERROR: validation_error - Required file not found: /path/to/file.md
```

### Standardized Error Types

Use these error types for consistency:

| Error Type | Description |
|------------|-------------|
| `state_error` | Workflow state persistence issues |
| `validation_error` | Input validation failures |
| `agent_error` | Subagent execution failures |
| `parse_error` | Output parsing failures |
| `file_error` | File system operations failures |
| `timeout_error` | Operation timeout errors |
| `execution_error` | General execution failures |
| `dependency_error` | Missing or invalid dependencies |

### Parent Command Integration

Parent commands parse agent errors using `parse_subagent_error()`:

```bash
AGENT_OUTPUT="$(...)"  # Capture task output

# Parse and log any errors
parse_subagent_error "$AGENT_OUTPUT" "research-specialist"
```

## Tool Access Guidelines

### Classification Agents

```yaml
allowed-tools: None
model: haiku-4.5
timeout: 30000ms
```

**Characteristics**:
- Fast, cheap classification/routing
- Return structured JSON or signals
- No file access, no execution
- Short timeouts (<30s)

### Analysis Agents

```yaml
allowed-tools: Read, Grep, Glob
model: sonnet-4.5
timeout: 120000ms
```

**Characteristics**:
- Read codebase, search patterns
- Return analysis results
- No file modification
- Medium timeouts (1-2min)

### Implementation Agents

```yaml
allowed-tools: Read, Write, Edit, Bash
model: sonnet-4.5
timeout: 300000ms
```

**Characteristics**:
- Full file modification capabilities
- Can execute bash commands
- Can create commits
- Long timeouts (5min)

### Model-Tool Alignment

**Warning**: Haiku model with Write/Edit tools is a code smell:

```yaml
# WARNING: Misaligned configuration
model: haiku-4.5
allowed-tools: Write, Edit  # Haiku not optimal for code generation
```

Haiku is optimized for classification, not code generation. Use Sonnet for implementation tasks.

## Task Tool Subprocess Isolation

### Critical Constraints

Task tool creates completely isolated subprocesses:

**Agent subprocess CANNOT**:
- Access parent bash block environment variables
- Access parent's STATE_FILE variable
- Execute bash if `allowed-tools: None`
- Modify parent state directly

**Agent subprocess CAN**:
- Read files (if `allowed-tools: Read`)
- Return structured text output
- Perform analysis and classification

### Communication Pattern

```
Parent Command
    ↓
Bash Block (STATE_FILE accessible)
│   ↓
│   Task Tool Invocation
│       ↓
│   ┌─────── Agent Subprocess ──────┐
│   │ - NO access to STATE_FILE     │
│   │ - Returns text output only    │
│   └───────────────────────────────┘
│       ↓
│   Extract result from agent output
│   Save to STATE_FILE (parent context)
└────────────────────────────────────
```

See [Bash Block Execution Model](../../concepts/bash-block-execution-model.md#task-tool-subprocess-isolation) for complete technical details.

## Validation Checklist

Before deploying a new agent:

- [ ] `allowed-tools` frontmatter matches actual tool usage in instructions
- [ ] No bash execution instructions if `allowed-tools: None`
- [ ] Uses `ensure_artifact_directory()` immediately before Write (not at startup)
- [ ] Returns structured error signals (not unstructured error text)
- [ ] Model selection appropriate for tool configuration
- [ ] Timeout appropriate for expected workload

### Automated Validation

```bash
# Validate single agent
bash .claude/scripts/validate-agent-behavioral-file.sh .claude/agents/my-agent.md

# Validate all agents
for agent in .claude/agents/*.md; do
  bash .claude/scripts/validate-agent-behavioral-file.sh "$agent"
done
```

## Navigation

- Parent: [Standards Reference](README.md)
- Related: [Code Standards](code-standards.md), [Bash Block Execution Model](../../concepts/bash-block-execution-model.md)
- Enforcement: [Enforcement Mechanisms](enforcement-mechanisms.md)
