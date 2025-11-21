# /convert-docs Error Logging Root Cause Analysis

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: /convert-docs error logging integration and conversion errors
- **Report Type**: Root cause analysis for debug workflow

## Executive Summary

The /convert-docs command completely lacks error logging integration despite .claude/docs/reference/standards documentation mandating centralized error logging for all commands. The conversion output shows actual bash execution errors (exit code 127 for missing CLAUDE_PROJECT_DIR, exit code 2 for conditional operator syntax error) that were not captured in the centralized error log, preventing the /errors command from detecting them. This represents a systematic gap where infrastructure assumes commands source error-handling.sh and call log_command_error, but /convert-docs uses a script delegation model without error logging hooks.

## Findings

### Finding 1: Complete Absence of Error Logging Integration

**Location**: /home/benjamin/.config/.claude/commands/convert-docs.md:1-502

**Evidence**:
- No `source` statement for error-handling.sh library anywhere in command
- No `ensure_error_log_exists` initialization call
- No `log_command_error` calls for any failure conditions
- Grep search for error logging patterns returned zero matches

**Code Analysis**:
```bash
# From convert-docs.md - No error handling library sourcing
# Expected pattern (from docs):
# source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }

# Actual pattern: No sourcing, direct delegation to script or agent
```

**Impact**:
- Command failures invisible to /errors command
- No centralized error tracking for debugging
- Cannot query conversion errors via /errors --command /convert-docs
- Breaks error analysis workflow described in documentation

### Finding 2: Script Delegation Model Bypasses Error Logging

**Location**: /home/benjamin/.config/.claude/commands/convert-docs.md:304-356

**Architecture Analysis**:
The command uses a coordinator pattern where Claude delegates to either:
1. **Script Mode**: Sources convert-core.sh and calls main_conversion function
2. **Agent Mode**: Invokes doc-converter agent via Task tool
3. **Skill Mode**: Natural language delegation to document-converter skill

**Code Pattern**:
```bash
# STEP 4 - Script Mode Execution (lines 304-356)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" || {
  echo "❌ CRITICAL ERROR: Cannot source convert-core.sh"
  exit 1
}

main_conversion "$input_dir" "$OUTPUT_DIR_ABS"
CONVERSION_EXIT=$?
if [ $CONVERSION_EXIT -ne 0 ]; then
  echo "❌ ERROR: Script mode conversion failed"
  exit 1
fi
```

**Root Cause**:
- Error logging responsibility unclear in delegation model
- convert-core.sh (1314 lines) has no error-handling.sh integration
- Agent mode and skill mode rely on subagent error protocols, not command-level logging
- Command coordinator assumes delegated components handle errors, but they don't log to centralized system

### Finding 3: convert-core.sh Library Has No Error Logging

**Location**: /home/benjamin/.config/.claude/lib/convert/convert-core.sh:1-1314

**Evidence**:
- Grep search for error logging patterns: 0 matches found
- Script uses `set -eu` for error handling (line 18) but no centralized logging
- Errors printed to stdout/stderr with echo statements only
- No integration with error-handling.sh library

**Error Handling Patterns Found**:
```bash
# Line 324-327: Source failure
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" || {
  echo "❌ CRITICAL ERROR: Cannot source convert-core.sh"
  exit 1
}

# Line 1241-1244: Input validation
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

# Line 975-984: Conversion failure logging (to conversion.log only)
if [[ "$conversion_success" == "false" ]]; then
  echo "    ✗ Failed to convert $basename"
  docx_failed=$((docx_failed + 1))
else
  echo "    ✓ Converted to $(basename "$output_file") (using $tool_used)"
fi

# Line 981-984: Internal logging to conversion.log
log_conversion "$LOG_FILE" "[SUCCESS] $basename → $(basename "$output_file") (tool: $tool_used)"
```

**Impact**:
- Conversion errors logged only to output-specific conversion.log file
- No structured JSONL error entries for querying
- /errors command cannot discover conversion failures
- Error patterns not aggregated for analysis

### Finding 4: Actual Conversion Errors from Test Run

**Location**: /home/benjamin/.config/.claude/convert-docs-output.md:1-166

**Error 1 - Missing CLAUDE_PROJECT_DIR** (lines 31-39):
```bash
● Bash(input_dir="/home/benjamin/.config/.claude/tmp"
      output_dir="./converted_output"…)
  ⎿  Error: Exit code 1
     /run/current-system/sw/bin/bash: line 61: /.claude/lib/convert/convert-core.sh: No such
     file or directory

     PROGRESS: Output directory: /home/benjamin/.config/converted_output
     ❌ CRITICAL ERROR: Cannot source convert-core.sh
```

**Root Cause**:
- CLAUDE_PROJECT_DIR environment variable not set when sourcing convert-core.sh
- Command uses `"${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"` path
- When CLAUDE_PROJECT_DIR is empty, expands to `"/.claude/lib/convert/convert-core.sh"` (absolute root path)
- File doesn't exist at root, causing source failure

**Error Classification**: execution_error (missing environment variable)

**Error 2 - Bash Conditional Syntax Error** (lines 67-72):
```bash
● Bash(export CLAUDE_PROJECT_DIR="/home/benjamin/.config"…) timeout: 1m 0s
  ⎿  Error: Exit code 2
     /run/current-system/sw/bin/bash: eval: line 31: conditional binary operator expected
     /run/current-system/sw/bin/bash: eval: line 31: syntax error near `-f'
     /run/current-system/sw/bin/bash: eval: line 31: `  if [[ \! -f
     "/home/benjamin/.config/converted_output/convert-test-original.pdf" ]]; then'
```

**Root Cause**:
- Bash conditional with escaped negation operator: `if [[ \! -f "..." ]]`
- The `\!` escape is incorrect inside `[[ ]]` test operator
- Should be: `if [[ ! -f "..." ]]` or `if [ ! -f "..." ]`
- Likely caused by over-escaping in multi-line bash block construction

**Error Classification**: parse_error (bash syntax error)

**Neither error logged to centralized error log**: /errors command found 0 errors for /convert-docs

### Finding 5: Documentation Mandates Error Logging but Convert-Docs Exempt

**Location**: /home/benjamin/.config/CLAUDE.md:59-83 (Error Logging Standards section)

**Documentation Requirements**:
```markdown
## Error Logging Standards
[Used by: all commands, all agents, /implement, /build, /debug, /errors, /repair]

All commands and agents must integrate centralized error logging for queryable error tracking and cross-workflow debugging.

**Quick Reference**:
1. Source error-handling library: `source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }`
2. Initialize error log: `ensure_error_log_exists`
3. Set workflow metadata: `COMMAND_NAME="/command"`, `WORKFLOW_ID="workflow_$(date +%s)"`, `USER_ARGS="$*"`
4. Log errors: `log_command_error "$error_type" "$error_message" "$error_details"`
5. Parse subagent errors: `parse_subagent_error "$agent_output" "$agent_name"`
```

**Gap Analysis**:
- Documentation claims "all commands" must integrate error logging
- /convert-docs has no integration whatsoever
- No exemption documented for delegation-model commands
- /errors command guide explicitly shows `/errors --command /convert-docs` as valid use case

**Conclusion**: /convert-docs is non-compliant with documented standards

### Finding 6: Environment Variable Management Inconsistency

**Location**: Multiple bash blocks in /convert-docs command execution

**Pattern Analysis**:
```bash
# Block 1 (line 7) - CLAUDE_PROJECT_DIR not set
Bash(SKILL_AVAILABLE=false
     SKILL_PATH="${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md"…)

# Block 2 (line 31-39) - Still not set, causes failure
Bash(input_dir="/home/benjamin/.config/.claude/tmp"
     output_dir="./converted_output"…)
# Result: Error - /.claude/lib/convert/convert-core.sh not found

# Block 3 (line 47-52) - Manually exported
Bash(export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
     ls -la "$CLAUDE_PROJECT_DIR/.claude/lib/convert/" 2>&1)
# Result: Success - directory listing works

# Block 4 (line 56-61) - Works with exported variable
Bash(export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
     input_dir="/home/benjamin/.config/.claude/tmp"…)
# Result: Successful conversion
```

**Root Cause**:
- Commands assume CLAUDE_PROJECT_DIR is set by environment
- Shell session persistence between bash blocks not guaranteed
- Each Bash tool invocation may be fresh shell session
- Command doesn't detect/set CLAUDE_PROJECT_DIR early in workflow

**Required Fix**:
Commands should initialize CLAUDE_PROJECT_DIR defensively:
```bash
# Detect project directory if not already set
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # Use unified-location-detection.sh to find project root
  CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

### Finding 7: Bash Conditional Escaping Issue

**Location**: /home/benjamin/.config/.claude/convert-docs-output.md:67-72

**Problematic Pattern**:
```bash
if [[ \! -f "/home/benjamin/.config/converted_output/convert-test-original.pdf" ]]; then
```

**Error Message**:
```
/run/current-system/sw/bin/bash: eval: line 31: conditional binary operator expected
/run/current-system/sw/bin/bash: eval: line 31: syntax error near `-f'
```

**Root Cause Analysis**:
1. The `\!` escaping is invalid inside `[[ ]]` extended test command
2. In `[[ ]]`, the `!` operator doesn't need escaping
3. Escaping causes bash to interpret `\!` as literal backslash + exclamation
4. This creates syntax error as bash expects binary operator after `[[`

**Correct Patterns**:
```bash
# Modern bash (recommended)
if [[ ! -f "$file" ]]; then

# POSIX sh (alternative)
if [ ! -f "$file" ]; then

# Wrong (causes error)
if [[ \! -f "$file" ]]; then
```

**Likely Source**:
- Multi-line bash block constructed with excessive quoting/escaping
- Possible Claude Code tool issue with heredoc or string interpolation
- May be workaround for bash injection prevention that went too far

## Recommendations

### 1. Integrate Error Logging Library into /convert-docs Command

**Rationale**: Bring command into compliance with documented error logging standards

**Implementation**:
```bash
# Add after STEP 1 (Parse Arguments) in convert-docs.md

### STEP 1.5 (REQUIRED BEFORE STEP 2) - Initialize Error Logging

**EXECUTE NOW - Error Logging Setup**:

```bash
# Source error handling library
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library" >&2
  exit 1
}

# Initialize error log
ensure_error_log_exists

# Set workflow metadata
COMMAND_NAME="/convert-docs"
WORKFLOW_ID="convert_docs_$(date +%s)"
USER_ARGS="$*"

echo "✓ VERIFIED: Error logging initialized"
```

**MANDATORY VERIFICATION - Error Logging Ready**:
```bash
[[ -z "$COMMAND_NAME" ]] && echo "❌ ERROR: Command name not set" && exit 1
[[ -z "$WORKFLOW_ID" ]] && echo "❌ ERROR: Workflow ID not set" && exit 1
echo "✓ VERIFIED: Error logging configuration complete"
```
```

**Error Logging Points to Add**:
```bash
# STEP 2 - Input path validation failure
if [[ ! -d "$input_dir" ]]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" \
    "Input directory does not exist: $input_dir" \
    "input_validation" \
    "{\"input_dir\": \"$input_dir\"}"
  echo "❌ CRITICAL ERROR: Input directory does not exist: $input_dir"
  exit 1
fi

# STEP 4 - Script mode conversion failure
if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" \
    "Cannot source convert-core.sh library" \
    "script_mode_initialization" \
    "{\"lib_path\": \"${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh\"}"
  echo "❌ CRITICAL ERROR: Cannot source convert-core.sh"
  exit 1
fi

main_conversion "$input_dir" "$OUTPUT_DIR_ABS"
CONVERSION_EXIT=$?
if [ $CONVERSION_EXIT -ne 0 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "execution_error" \
    "Script mode conversion failed with exit code $CONVERSION_EXIT" \
    "script_mode_execution" \
    "{\"exit_code\": $CONVERSION_EXIT, \"input_dir\": \"$input_dir\", \"output_dir\": \"$OUTPUT_DIR_ABS\"}"
  echo "❌ ERROR: Script mode conversion failed"
  exit 1
fi
```

**Files to Modify**:
- /home/benjamin/.config/.claude/commands/convert-docs.md (add error logging integration)

### 2. Add Error Logging to convert-core.sh Library

**Rationale**: Enable error tracking for script-mode conversions at library level

**Implementation**:
```bash
# Add near top of convert-core.sh after sourcing dependencies (line 27)

# Source error handling library for centralized error logging
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "Warning: Error logging library not available" >&2
  }

  # Initialize error log if library loaded successfully
  if type ensure_error_log_exists &>/dev/null; then
    ensure_error_log_exists
  fi
fi

# Function to log conversion errors if error logging available
log_conversion_error() {
  local error_type="$1"
  local message="$2"
  local context_json="${3:-{}}"

  # Only log if error logging is available and metadata is set
  if type log_command_error &>/dev/null && [[ -n "${COMMAND_NAME:-}" ]]; then
    log_command_error "${COMMAND_NAME:-/convert-docs}" \
      "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" \
      "$error_type" \
      "$message" \
      "convert-core.sh" \
      "$context_json"
  fi
}
```

**Error Logging Points in convert-core.sh**:
```bash
# Line 1241-1244: Input directory validation
if [[ ! -d "$INPUT_DIR" ]]; then
  log_conversion_error "validation_error" \
    "Input directory not found: $INPUT_DIR" \
    "{\"input_dir\": \"$INPUT_DIR\"}"
  echo "Error: Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

# Line 875-877: DOCX conversion failure
if [[ "$conversion_success" == "false" ]]; then
  log_conversion_error "execution_error" \
    "Failed to convert DOCX file: $basename" \
    "{\"file\": \"$input_file\", \"attempted_tools\": [\"markitdown\", \"pandoc\"]}"
  echo "    ✗ Failed to convert $basename"
  docx_failed=$((docx_failed + 1))
fi

# Line 934-936: PDF conversion failure
if [[ "$conversion_success" == "false" ]]; then
  log_conversion_error "execution_error" \
    "Failed to convert PDF file: $basename" \
    "{\"file\": \"$input_file\", \"attempted_tools\": [\"markitdown\", \"pymupdf\"]}"
  echo "    ✗ Failed to convert $basename"
  pdf_failed=$((pdf_failed + 1))
fi
```

**Files to Modify**:
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh (add error logging integration)

### 3. Fix CLAUDE_PROJECT_DIR Initialization

**Rationale**: Prevent environment variable errors by defensive initialization

**Implementation**:
```bash
# Add as STEP 0.5 in convert-docs.md (before STEP 1)

### STEP 0.5 (REQUIRED FIRST) - Initialize Environment

**EXECUTE NOW - Environment Detection**:

```bash
# Detect and set CLAUDE_PROJECT_DIR if not already set
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # Source unified location detection library
  source .claude/lib/core/unified-location-detection.sh 2>/dev/null || {
    # Fallback: detect from command location
    CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  }

  # If still not set, use detect_project_directory function
  if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]] && type detect_project_directory &>/dev/null; then
    CLAUDE_PROJECT_DIR="$(detect_project_directory)"
  fi

  export CLAUDE_PROJECT_DIR
fi

# Verify CLAUDE_PROJECT_DIR is set and valid
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "❌ CRITICAL ERROR: Cannot detect project directory" >&2
  echo "   Please set CLAUDE_PROJECT_DIR environment variable" >&2
  exit 1
fi

if [[ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]]; then
  echo "❌ CRITICAL ERROR: Invalid project directory: $CLAUDE_PROJECT_DIR" >&2
  echo "   .claude/ subdirectory not found" >&2
  exit 1
fi

echo "✓ VERIFIED: CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR"
```

**MANDATORY VERIFICATION - Environment Ready**:
```bash
[[ -z "$CLAUDE_PROJECT_DIR" ]] && echo "❌ ERROR: CLAUDE_PROJECT_DIR not set" && exit 1
[[ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]] && echo "❌ ERROR: Invalid CLAUDE_PROJECT_DIR" && exit 1
echo "✓ VERIFIED: Project environment initialized"
```
```

**Files to Modify**:
- /home/benjamin/.config/.claude/commands/convert-docs.md (add environment initialization)

### 4. Fix Bash Conditional Escaping

**Rationale**: Eliminate parse errors from incorrect negation operator escaping

**Investigation Needed**:
- Determine where the `\!` escaping is introduced
- Check if it's in convert-core.sh source code or bash block generation
- Review Claude Code Bash tool's quoting/escaping behavior

**Likely Location**:
The error occurs during MD→PDF conversion attempt. Need to search convert-core.sh for conditional checks with file existence tests:

```bash
# Search pattern to find problematic code
grep -n '\[\[.*\\!.*-f' /home/benjamin/.config/.claude/lib/convert/convert-core.sh
```

**Fix Pattern**:
Replace all instances of:
```bash
if [[ \! -f "$file" ]]; then
```

With:
```bash
if [[ ! -f "$file" ]]; then
```

**Files to Investigate/Modify**:
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh
- /home/benjamin/.config/.claude/lib/convert/convert-markdown.sh
- /home/benjamin/.config/.claude/lib/convert/convert-pdf.sh

### 5. Create Error Logging Test Suite for /convert-docs

**Rationale**: Ensure error logging integration works correctly and catches all failure modes

**Test Cases**:
```bash
# Test 1: Invalid input directory
/convert-docs /nonexistent/directory
# Expected: validation_error logged with context

# Test 2: Missing CLAUDE_PROJECT_DIR
unset CLAUDE_PROJECT_DIR && /convert-docs /tmp
# Expected: execution_error logged or defensive initialization prevents

# Test 3: Conversion tool failures
/convert-docs /dir/with/corrupted/files
# Expected: execution_error logged for each failed file

# Test 4: /errors query integration
/convert-docs /bad/files && /errors --command /convert-docs --limit 5
# Expected: /errors displays logged conversion errors
```

**Test File Location**:
- /home/benjamin/.config/.claude/tests/features/commands/test_convert_docs_error_logging.sh

**Test Structure**:
```bash
#!/usr/bin/env bash
# Test error logging integration for /convert-docs command

test_convert_docs_logs_validation_errors() {
  # Setup: Clear error log, create invalid input
  # Execute: Run /convert-docs with invalid input
  # Assert: Error logged to errors.jsonl with correct type and context
}

test_convert_docs_logs_conversion_failures() {
  # Setup: Create corrupted test files
  # Execute: Run /convert-docs on corrupted files
  # Assert: execution_error logged for each failed conversion
}

test_errors_command_queries_convert_docs() {
  # Setup: Trigger known /convert-docs error
  # Execute: /errors --command /convert-docs
  # Assert: Error appears in /errors output
}
```

### 6. Update Documentation to Clarify Delegation Model Error Logging

**Rationale**: Prevent future commands from having same gap; clarify responsibility

**Documentation Updates**:

**File**: /home/benjamin/.config/.claude/docs/reference/standards/error-logging-standards.md

**New Section**:
```markdown
## Error Logging in Delegation Model Commands

Commands that delegate execution to scripts, agents, or skills must still integrate error logging at the coordinator level.

### Coordinator Responsibilities

The command coordinator (e.g., /convert-docs.md) must:
1. Source error-handling.sh and initialize error logging
2. Set workflow metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS)
3. Log errors at delegation boundaries:
   - Pre-delegation validation errors
   - Delegation failures (script source errors, agent invocation failures)
   - Post-delegation validation errors (missing output files)
4. Export error logging metadata to delegated scripts via environment

### Delegated Component Responsibilities

Scripts and libraries (e.g., convert-core.sh) should:
1. Conditionally source error-handling.sh if available
2. Use exported metadata (COMMAND_NAME, WORKFLOW_ID, USER_ARGS) if present
3. Log errors using log_conversion_error wrapper that checks availability
4. Degrade gracefully if error logging unavailable (backward compatibility)

### Agent and Skill Delegation

Agents invoked via Task tool must:
1. Return structured TASK_ERROR signals for coordinator to log
2. Use parse_subagent_error pattern for error extraction
3. Include context in ERROR_CONTEXT JSON blocks

### Example Implementation

```bash
# Command coordinator (convert-docs.md)
source "$CLAUDE_LIB/core/error-handling.sh"
ensure_error_log_exists
COMMAND_NAME="/convert-docs"
WORKFLOW_ID="convert_$(date +%s)"
USER_ARGS="$*"
export COMMAND_NAME WORKFLOW_ID USER_ARGS

# Delegate to script
if ! source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" "Cannot source convert-core.sh" "delegation"
  exit 1
fi

# Delegated script (convert-core.sh)
# Conditional integration - works with or without error logging
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || true
fi

log_conversion_error() {
  local error_type="$1"
  local message="$2"
  local context_json="${3:-{}}"

  if type log_command_error &>/dev/null && [[ -n "${COMMAND_NAME:-}" ]]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "$error_type" "$message" "convert-core.sh" "$context_json"
  fi
}
```
```

**Files to Create/Modify**:
- /home/benjamin/.config/.claude/docs/reference/standards/error-logging-standards.md (new section)
- /home/benjamin/.config/CLAUDE.md (reference update in error_logging section)

## References

- /home/benjamin/.config/.claude/convert-docs-output.md:1-166 (conversion test output with errors)
- /home/benjamin/.config/.claude/specs/888_errors_command_test_report/reports/001_error_report.md:1-197 (error report showing no /convert-docs errors)
- /home/benjamin/.config/.claude/commands/convert-docs.md:1-502 (command implementation)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:1-1314 (core conversion library)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh:1-599 (error logging library)
- /home/benjamin/.config/CLAUDE.md:59-83 (error logging standards section)
- /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md (error handling pattern documentation)
- /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md (errors command usage guide)
