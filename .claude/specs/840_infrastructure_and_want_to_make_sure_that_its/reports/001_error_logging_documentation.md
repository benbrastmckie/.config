# Error Logging Documentation Integration Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Error logging documentation integration and standards compliance
- **Report Type**: codebase analysis

## Executive Summary

The error logging infrastructure has been successfully refactored with comprehensive documentation across multiple files in `.claude/docs/`, but critical integration gaps remain. While the system includes a pattern document, API reference, command guide, flowchart, and shared guidelines, there is no CLAUDE.md section to enable standards discovery, and no standard requiring commands to integrate error logging. Five commands currently use `log_command_error()`, but most commands lack integration, creating inconsistent error tracking across the codebase.

## Findings

### 1. Comprehensive Documentation Structure (COMPLIANT)

The error logging documentation is well-organized across the `.claude/docs/` hierarchy following Diataxis framework standards:

**Concepts Layer** - Pattern documentation:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (Lines 1-630)
  - Complete pattern definition with rationale, implementation, and anti-patterns
  - JSONL schema documentation with all error types
  - Integration patterns for commands, state machine, and hierarchical agents
  - Performance characteristics and recovery patterns
  - Proper metadata: `[Used by: all commands, all orchestrators, hierarchical agents, workflow state machine]`

**Reference Layer** - API and architecture:
- `/home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md` (Lines 1-680)
  - Complete function signatures for all 15+ error handling functions
  - Usage examples for `log_command_error()`, `parse_subagent_error()`, `query_errors()`, etc.
  - Error type constants and classification taxonomy
  - Integration patterns with proper code examples

- `/home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md` (Lines 1-341)
  - Standard 15: Library sourcing order requirements
  - Standard 16: Critical function return code verification
  - Source guard patterns and dependency justification

- `/home/benjamin/.config/.claude/docs/reference/decision-trees/error-handling-flowchart.md` (Lines 1-523)
  - Quick decision tree for diagnosing errors
  - Four categories: Agent delegation, File errors, Test failures, Command syntax/config
  - Solutions with before/after examples

**Guides Layer** - Task-focused documentation:
- `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` (Lines 1-306)
  - Complete user guide for `/errors` command
  - Query examples, filtering patterns, troubleshooting
  - Architecture, data flow, and integration points

**Shared Guidelines** - Agent standards:
- `/home/benjamin/.config/.claude/agents/shared/error-handling-guidelines.md` (Lines 1-414)
  - Error classification (transient, permanent, fatal)
  - Retry strategies with exponential backoff
  - Fallback strategies and graceful degradation
  - Agent-specific patterns (code-writer, test-specialist, etc.)

### 2. Documentation Linking and Discoverability (MOSTLY COMPLIANT)

**Main README Integration** (Lines 79-84 of `/home/benjamin/.config/.claude/docs/README.md`):
```markdown
16. **Query and analyze error logs**
    → [/errors Command Guide](guides/commands/errors-command-guide.md)
    → [Error Handling Pattern](concepts/patterns/error-handling.md)
    → [Error Handling API Reference](reference/library-api/error-handling.md)
```

This provides excellent discoverability through the "I Want To..." section.

**Cross-References**:
- Pattern document links to API reference, command guide, architecture docs, and hierarchical agents
- API reference links back to pattern document and command guide
- Command guide links to pattern, API reference, and related commands
- All links use relative paths correctly

**Code Standards Integration** (Line 8 of `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md`):
```markdown
- **Error Handling**: Use defensive programming patterns with structured error messages (WHICH/WHAT/WHERE)
  - See [Defensive Programming Patterns](.claude/docs/concepts/patterns/defensive-programming.md)
  - See [Error Enhancement Guide](.claude/docs/guides/patterns/error-enhancement-guide.md)
```

This establishes error handling as a general principle but doesn't specifically reference the centralized error logging system.

### 3. Implementation Library (COMPLIANT)

**Location**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (Lines 1-150+)

**Key Functions Implemented**:
- `log_command_error()` - Centralized JSONL error logging
- `parse_subagent_error()` - Extract TASK_ERROR signals from subagent output
- `query_errors()` - Filter and query error log with jq
- `recent_errors()` - Human-readable recent error display
- `error_summary()` - Aggregate statistics by command/type
- `classify_error()` - Classify as transient/permanent/fatal
- `suggest_recovery()` - Provide recovery suggestions
- `retry_with_backoff()` - Exponential backoff retry logic
- `rotate_error_log()` - Automatic 10MB rotation with 5 backups
- `ensure_error_log_exists()` - Lazy log creation

**Error Type Constants** (Lines 18-27):
```bash
readonly ERROR_TYPE_TRANSIENT="transient"
readonly ERROR_TYPE_PERMANENT="permanent"
readonly ERROR_TYPE_FATAL="fatal"
readonly ERROR_TYPE_LLM_TIMEOUT="llm_timeout"
readonly ERROR_TYPE_LLM_API_ERROR="llm_api_error"
readonly ERROR_TYPE_LLM_LOW_CONFIDENCE="llm_low_confidence"
readonly ERROR_TYPE_LLM_PARSE_ERROR="llm_parse_error"
readonly ERROR_TYPE_INVALID_MODE="invalid_mode"
```

**Standard Error Types for Centralized Logging** (from pattern doc, lines 46-60):
```bash
ERROR_TYPE_STATE="state_error"          # Workflow state persistence issues
ERROR_TYPE_VALIDATION="validation_error" # Input validation failures
ERROR_TYPE_AGENT="agent_error"          # Subagent execution failures
ERROR_TYPE_PARSE="parse_error"          # Output parsing failures
ERROR_TYPE_FILE="file_error"            # File system operations failures
ERROR_TYPE_TIMEOUT_ERR="timeout_error"  # Operation timeout errors
ERROR_TYPE_EXECUTION="execution_error"  # General execution failures
```

### 4. Command Integration Status (PARTIAL COMPLIANCE)

**Commands Using Error Logging** (5 out of ~12 commands):
- `/home/benjamin/.config/.claude/commands/repair.md`
- `/home/benjamin/.config/.claude/commands/errors.md`
- `/home/benjamin/.config/.claude/commands/revise.md`
- `/home/benjamin/.config/.claude/commands/research.md`
- `/home/benjamin/.config/.claude/commands/build.md`

**Missing Integration**: Most commands (`/plan`, `/debug`, `/coordinate`, `/orchestrate`, `/expand`, `/collapse`, `/convert-docs`) do not source `error-handling.sh` or call `log_command_error()`.

**Gap Identified**: No search results found when grepping all commands for `log_command_error`, suggesting inconsistent adoption across the codebase.

### 5. CRITICAL GAP: Missing CLAUDE.md Section

**Search Results**: No CLAUDE.md section found for error logging standards.

```bash
# Command executed:
grep -n "SECTION.*error\|error.*SECTION" /home/benjamin/.config/CLAUDE.md
# Result: No output (no matching sections)
```

**Impact**: Commands cannot discover error logging requirements through standard CLAUDE.md section discovery pattern used by `/implement`, `/plan`, `/refactor`, etc.

**Expected Section** (not present):
```markdown
<!-- SECTION: error_logging -->
## Error Logging Standards
[Used by: all commands, all agents, /implement, /build, /errors]

All commands MUST integrate centralized error logging for consistent error tracking and analysis.

See [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) for complete implementation requirements.

**Quick Reference**:
1. Source error-handling.sh library
2. Call ensure_error_log_exists() during initialization
3. Log errors with log_command_error() including command name, workflow ID, error type, and context
4. Parse subagent errors with parse_subagent_error()
5. Use standardized error type constants (ERROR_TYPE_STATE, ERROR_TYPE_VALIDATION, etc.)
<!-- END_SECTION: error_logging -->
```

### 6. Related Research from Previous Spec

**Previous Research Report** (Spec 827):
- `/home/benjamin/.config/.claude/specs/827_when_run_commands_such_on_want_able_log_all/reports/001_error_logging_research.md`
- Documents the complete design of the centralized error logging system
- Provides implementation roadmap (Phases 1-4)
- Shows gaps analysis that led to current implementation

This indicates the error logging infrastructure was recently implemented and is likely still undergoing integration across the codebase.

### 7. Standards Compliance Assessment

**What's Working Well**:
- ✅ Diataxis-compliant documentation organization (concepts, reference, guides)
- ✅ Comprehensive pattern documentation with rationale and anti-patterns
- ✅ Complete API reference with function signatures and examples
- ✅ User guide for `/errors` command with troubleshooting
- ✅ Shared agent guidelines for consistent error handling
- ✅ Integration in main docs README "I Want To..." section
- ✅ Proper cross-linking between related documents
- ✅ Implementation library with all required functions
- ✅ JSONL log format with automatic rotation

**What Needs Improvement**:
- ❌ No CLAUDE.md section for standards discovery
- ❌ No architectural standard requiring error logging integration
- ❌ Inconsistent command integration (5/12 commands)
- ❌ Code standards reference defensive programming but not centralized logging
- ❌ No mention in command development guide of error logging requirement
- ❌ Agent behavioral files don't consistently require error return protocol

## Recommendations

### Recommendation 1: Add CLAUDE.md Error Logging Section

**Priority**: HIGH
**Impact**: Enables standards discovery for all commands and agents

Create a new section in `/home/benjamin/.config/CLAUDE.md`:

```markdown
<!-- SECTION: error_logging -->
## Error Logging Standards
[Used by: all commands, all agents, /implement, /build, /debug, /errors]

All commands and agents MUST integrate centralized error logging for consistent error tracking and post-mortem analysis.

### Core Requirements

**Commands Must**:
1. Source error-handling library: `source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null`
2. Initialize error log: `ensure_error_log_exists`
3. Set command metadata: `COMMAND_NAME`, `WORKFLOW_ID`, `USER_ARGS`
4. Log errors with context: `log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "$ERROR_TYPE" "$message" "$source" "$context_json"`
5. Parse subagent errors: `parse_subagent_error "$output"`

**Error Types**:
- `state_error` - Workflow state persistence issues
- `validation_error` - Input validation failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File I/O failures
- `timeout_error` - Operation timeouts
- `execution_error` - General execution failures

**Query Errors**: Use `/errors` command to view and analyze error logs

**Complete Documentation**: [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md)
<!-- END_SECTION: error_logging -->
```

### Recommendation 2: Add Error Logging Requirement to Architecture Standards

**Priority**: HIGH
**Impact**: Establishes architectural requirement for all new commands

Add Standard 17 to `/home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md`:

```markdown
## Standard 17: Centralized Error Logging Integration

### Requirement

All commands MUST integrate centralized error logging via `log_command_error()` function from error-handling.sh library.

### Rationale

Centralized error logging provides:
- Single source of truth for error analysis and debugging
- Full workflow context with command name, workflow ID, and user arguments
- Structured queryable format (JSONL) for post-mortem analysis
- Error trend identification across commands and workflows

Without centralized logging, errors are scattered across workflow-specific debug logs, making cross-workflow analysis impossible.

### Standard Integration Pattern

All commands must follow this pattern:

```bash
#!/usr/bin/env bash
# Source error handling library
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Command metadata for error logging
COMMAND_NAME="/your-command"
WORKFLOW_ID="workflow_$(date +%Y%m%d_%H%M%S)"
USER_ARGS="$*"

# Initialize error log
ensure_error_log_exists

# Example: Log validation error
if [ -z "$REQUIRED_ARG" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_VALIDATION" \
    "Required argument missing" \
    "bash_block" \
    "$(jq -n --arg provided "$*" '{provided_args: $provided}')"
  exit 1
fi

# Example: Log subagent error
output=$(invoke_agent "agent-name" "task")
error_json=$(parse_subagent_error "$output")
if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$(echo "$error_json" | jq -r '.error_type')" \
    "$(echo "$error_json" | jq -r '.message')" \
    "subagent_agent-name" \
    "$(echo "$error_json" | jq -c '.context')"
  exit 1
fi
```

### Validation

**Automated Testing**:
```bash
# Check command sources error-handling.sh
grep -q "source.*error-handling.sh" .claude/commands/your-command.md

# Check command uses log_command_error
grep -q "log_command_error" .claude/commands/your-command.md
```

**Manual Verification**:
- Verify command sets COMMAND_NAME, WORKFLOW_ID, USER_ARGS
- Check error logging occurs at all failure points
- Confirm subagent errors are parsed and logged
- Test `/errors --command /your-command` returns logged errors

### References

- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) - Complete pattern
- [Error Handling API](.claude/docs/reference/library-api/error-handling.md) - Function reference
- [/errors Command Guide](.claude/docs/guides/commands/errors-command-guide.md) - Query interface
```

### Recommendation 3: Update Code Standards to Reference Centralized Logging

**Priority**: MEDIUM
**Impact**: Ensures code standards mention both defensive programming AND centralized logging

Update Line 8 in `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md`:

**Current**:
```markdown
- **Error Handling**: Use defensive programming patterns with structured error messages (WHICH/WHAT/WHERE) - See [Defensive Programming Patterns](.claude/docs/concepts/patterns/defensive-programming.md) and [Error Enhancement Guide](.claude/docs/guides/patterns/error-enhancement-guide.md)
```

**Proposed**:
```markdown
- **Error Handling**: Use defensive programming patterns with structured error messages (WHICH/WHAT/WHERE) and centralized error logging via `log_command_error()` - See [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md), [Defensive Programming Patterns](.claude/docs/concepts/patterns/defensive-programming.md), and [Error Enhancement Guide](.claude/docs/guides/patterns/error-enhancement-guide.md)
```

### Recommendation 4: Add Error Logging to Command Development Guide

**Priority**: MEDIUM
**Impact**: Ensures new commands integrate error logging from the start

Add section to `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-fundamentals.md` after the "Library Integration" section:

```markdown
### Error Logging Integration

All commands must integrate centralized error logging for consistent error tracking.

**Required Steps**:

1. **Source Library**:
   ```bash
   source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
     echo "ERROR: Failed to source error-handling.sh" >&2
     exit 1
   }
   ```

2. **Set Metadata**:
   ```bash
   COMMAND_NAME="/your-command"
   WORKFLOW_ID="workflow_$(date +%Y%m%d_%H%M%S)"
   USER_ARGS="$*"
   ```

3. **Initialize Log**:
   ```bash
   ensure_error_log_exists
   ```

4. **Log Errors**:
   ```bash
   log_command_error \
     "$COMMAND_NAME" \
     "$WORKFLOW_ID" \
     "$USER_ARGS" \
     "$ERROR_TYPE_VALIDATION" \
     "Error description" \
     "bash_block" \
     '{"key": "value"}'
   ```

**See**: [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) for complete integration requirements.
```

### Recommendation 5: Standardize Agent Error Return Protocol

**Priority**: MEDIUM
**Impact**: Ensures agents return structured errors for parent command logging

Add error return protocol to all agent behavioral files (research-specialist.md, plan-architect.md, implementer-coordinator.md, etc.):

```markdown
## Error Return Protocol

If task cannot be completed due to error, YOU MUST:

1. **Output Error Context** (for parent command parsing):
   ```
   ERROR_CONTEXT: {
     "error_type": "validation_error",
     "message": "Brief error description",
     "details": {"field": "value"}
   }
   ```

2. **Signal Task Error**:
   ```
   TASK_ERROR: validation_error - Brief error description
   ```

Parent command will parse this signal and log to centralized error log with full workflow context.

**Error Types**:
- `validation_error` - Invalid input or schema mismatch
- `file_error` - File not found or I/O failure
- `parse_error` - Unable to parse input or output
- `execution_error` - General execution failure
- `timeout_error` - Operation exceeded timeout

**Example**:
```
Analysis failed due to missing input file.

ERROR_CONTEXT: {
  "error_type": "file_error",
  "message": "Input file not found",
  "details": {"expected_path": "/path/to/file.md"}
}

TASK_ERROR: file_error - Input file not found at /path/to/file.md
```
```

### Recommendation 6: Create Compliance Audit Script

**Priority**: LOW
**Impact**: Enables automated verification of error logging integration

Create `/home/benjamin/.config/.claude/tests/test_error_logging_compliance.sh`:

```bash
#!/usr/bin/env bash
# Test that all commands integrate error logging

set -euo pipefail

CLAUDE_ROOT="/home/benjamin/.config"
COMMANDS_DIR="$CLAUDE_ROOT/.claude/commands"

echo "Error Logging Compliance Audit"
echo "==============================="
echo ""

compliant=0
non_compliant=0

for cmd_file in "$COMMANDS_DIR"/*.md; do
  cmd_name=$(basename "$cmd_file" .md)

  # Check if command sources error-handling.sh
  if ! grep -q "source.*error-handling.sh" "$cmd_file"; then
    echo "❌ /$cmd_name - Missing error-handling.sh source"
    ((non_compliant++))
    continue
  fi

  # Check if command uses log_command_error
  if ! grep -q "log_command_error" "$cmd_file"; then
    echo "⚠️  /$cmd_name - Sources library but doesn't log errors"
    ((non_compliant++))
    continue
  fi

  echo "✅ /$cmd_name - Compliant"
  ((compliant++))
done

echo ""
echo "Summary: $compliant/$((compliant + non_compliant)) commands compliant"

if [ $non_compliant -gt 0 ]; then
  echo ""
  echo "See: .claude/docs/concepts/patterns/error-handling.md for integration requirements"
  exit 1
fi
```

### Recommendation 7: Backfill Remaining Commands

**Priority**: LOW
**Impact**: Achieves 100% command integration with error logging

Commands requiring integration:
- `/plan`
- `/debug`
- `/coordinate`
- `/orchestrate`
- `/expand`
- `/collapse`
- `/convert-docs`

For each command:
1. Source `error-handling.sh` library
2. Add `COMMAND_NAME`, `WORKFLOW_ID`, `USER_ARGS` metadata
3. Call `ensure_error_log_exists()`
4. Add `log_command_error()` calls at all error points
5. Parse subagent errors with `parse_subagent_error()`
6. Test with `/errors --command /command-name`

## References

### Documentation Files Analyzed

- `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (Lines 1-630)
- `/home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md` (Lines 1-680)
- `/home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md` (Lines 1-341)
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/error-handling-flowchart.md` (Lines 1-523)
- `/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md` (Lines 1-306)
- `/home/benjamin/.config/.claude/agents/shared/error-handling-guidelines.md` (Lines 1-414)
- `/home/benjamin/.config/.claude/docs/README.md` (Lines 79-84)
- `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (Lines 1-100)

### Implementation Files Analyzed

- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (Lines 1-150+)
- `/home/benjamin/.config/.claude/commands/repair.md` (uses error logging)
- `/home/benjamin/.config/.claude/commands/errors.md` (uses error logging)
- `/home/benjamin/.config/.claude/commands/revise.md` (uses error logging)
- `/home/benjamin/.config/.claude/commands/research.md` (uses error logging)
- `/home/benjamin/.config/.claude/commands/build.md` (uses error logging)

### Related Research

- `/home/benjamin/.config/.claude/specs/827_when_run_commands_such_on_want_able_log_all/reports/001_error_logging_research.md` - Original error logging design research
