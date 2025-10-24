# Bash Tool Limitations in AI Agent Context

## Overview

The Bash tool used by AI agents has security-driven limitations that affect how shell commands can be constructed. This document explains these limitations and provides recommended patterns for working within them.

## Root Cause

The Bash tool escapes command substitution `$(...)` for security purposes, preventing code injection attacks. This is an intentional design decision, not a bug.

**Error Pattern**:
```bash
# Input to Bash tool:
LOCATION_JSON=$(perform_location_detection "topic" "false")

# After escaping:
LOCATION_JSON\=\$(perform_location_detection 'topic' false)

# Result:
syntax error near unexpected token 'perform_location_detection'
```

## Broken Constructs (NEVER use in agent prompts)

These constructs will fail when used in agent contexts:

- **Command substitution**: `VAR=$(command)` - Always broken
- **Backticks**: `` VAR=`command` `` - Presumed broken (deprecated anyway)
- **Nested quotes in `$(...)` context** - Double escaping issues

## Working Constructs

These constructs work reliably in agent contexts:

- **Arithmetic expansion**: `VAR=$((expr))` ✓ (e.g., `COUNT=$((COUNT + 1))`)
- **Sequential commands**: `cmd1 && cmd2` ✓
- **Pipes**: `cmd1 | cmd2` ✓
- **Sourcing**: `source file.sh` ✓
- **Conditionals**: `[[ test ]] && action` ✓
- **Direct assignment**: `VAR="value"` ✓
- **For loops**: `for x in arr; do ...; done` ✓
- **Arrays**: `declare -a ARRAY` ✓

### Key Distinction

```bash
# WORKS: Arithmetic expansion (variable assignment context)
COUNT=$((COUNT + 1))

# BROKEN: Command substitution (capturing command output)
RESULT=$(perform_function)
```

## Recommended Pattern

**Pre-calculate paths in parent command scope, then pass absolute paths to agents.**

### Parent Command (Works Correctly)

```bash
# Source library and perform location detection
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"
LOCATION_JSON=$(perform_location_detection "$TOPIC" "false")

# Extract all needed paths
TOPIC_DIR=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')

# Calculate artifact paths upfront
REPORT_PATH="${REPORTS_DIR}/001_report_name.md"
mkdir -p "$(dirname "$REPORT_PATH")"

# Pass absolute path to agent (no calculation needed)
Task {
  subagent_type: "general-purpose"
  prompt: "
    **Report Path**: $REPORT_PATH

    Create report at the path above (no path calculation required).
  "
}
```

### Agent Prompt (Receives Absolute Path)

```yaml
Task {
  prompt: "
    **Report Path**: /home/user/.config/.claude/specs/042_topic/reports/001_report.md

    Write the report to the exact path specified above.
  "
}
```

## Architectural Principle

**Clear separation: parent orchestrates, agent executes**

- **Parent responsibility**:
  - Path calculation
  - Library sourcing
  - Orchestration
  - Complex bash operations

- **Agent responsibility**:
  - Execution with provided context
  - File operations using absolute paths
  - No path calculation
  - No bash complexity

## Performance

This pattern maintains optimal performance:

- **Token usage**: <11k per detection (85% reduction vs baseline)
- **Execution time**: <1s for path calculation
- **Reliability**: 100% (no escaping issues)

## Why This Pattern Works

1. **Eliminates bash complexity in agent context** - Agents receive simple string parameters
2. **Consistent with all successful commands** - Pattern proven across `/plan`, `/report`, `/orchestrate`
3. **No escaping issues** - Absolute paths are simple strings, no special characters
4. **Leverages existing libraries** - Uses unified-location-detection.sh without modifications
5. **Clear separation of concerns** - Parent handles complexity, agent handles execution

## Commands Using This Pattern

All successful workflow commands follow this pattern:

- `/research` - Pre-calculates all subtopic report paths before invoking research agents
- `/report` - Pre-calculates report path in parent scope
- `/plan` - Pre-calculates plan path before creating implementation plan
- `/orchestrate` - Pre-calculates all artifact paths before delegating to agents

## Related Documentation

- [Command Development Guide](../guides/command-development-guide.md) - Best practices for command development
- [Agent Development Guide](../guides/agent-development-guide.md) - Guidelines for creating specialized agents
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - How to invoke agents with context
- [Library API Reference](../reference/library-api.md) - API documentation for .claude/lib/ utilities
