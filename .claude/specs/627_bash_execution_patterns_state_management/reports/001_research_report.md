# Bash Subprocess Execution Patterns and Variable Scoping Research Report

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: Bash subprocess execution patterns and variable scoping issues
- **Report Type**: best practices | pattern recognition
- **Related Issue**: /coordinate command history expansion and argument passing errors

## Executive Summary

This report synthesizes findings from three diagnostic analyses of the /coordinate command failures, combined with industry best practices for bash subprocess execution and variable scoping. The research reveals that bash subprocess execution patterns create fundamental constraints for state management in markdown-based command execution, where each bash block executes as a separate process with isolated memory space.

**Key Findings**:
1. Subprocess isolation prevents variable persistence between bash blocks (export does not work across sibling processes)
2. History expansion is disabled by default in non-interactive shells (the "!: command not found" error is misattributed)
3. Process ID ($$ pattern) changes between bash blocks, breaking file-based state patterns that rely on PID
4. Stateless recalculation provides optimal balance of simplicity and performance (~2ms overhead per block)
5. File-based state requires semantic fixed filenames, not PID-dependent patterns (~30ms overhead)

## Findings

### 1. Subshell and Subprocess Variable Scoping

**Subprocess vs Subshell Architecture**

Claude Code's Bash tool executes each bash block as a **separate subprocess** (sibling processes), not subshells (child processes). This architectural constraint fundamentally affects variable persistence.

**Technical Behavior** (from `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md:36-75`):
```bash
# Block 1 (subprocess PID 1234)
export VAR="value"
export CLAUDE_PROJECT_DIR="/path/to/project"

# Block 2 (subprocess PID 5678 - DIFFERENT PROCESS)
echo "$VAR"  # Empty! Export didn't persist
echo "$CLAUDE_PROJECT_DIR"  # Empty! Export didn't persist
```

**Why This Happens**:
- Each bash block launches a new process (not fork/subshell)
- Separate process spaces have separate environment tables
- Exports only persist within same process and child processes
- Sequential bash blocks are **sibling processes**, not parent-child relationships

**Evidence from Diagnostic Reports**:
- Report 002 (lines 26-66): Process ID ($$ variable) changes between blocks, proving subprocess isolation
- Report 003 (lines 74-98): Global variable declarations in sourced libraries overwrite parent script variables
- State management doc (lines 79-91): Validation test confirms different PIDs in sequential blocks

**Industry Best Practices** (from web research):
- Variables in subshells are not visible outside the block and not accessible to parent process
- Export does NOT make subshell variables visible in parent shell
- "There is no way to put a variable in the parent environment from within a child environment"
- Performance: Minimize subshell usage as each creates new memory space (20%+ performance impact)

### 2. History Expansion Issues with Special Characters

**The History Expansion Myth**

The "/coordinate command history expansion" error naming is **misleading** - history expansion is NOT the root cause of "!: command not found" errors.

**Key Discovery** (from `/home/benjamin/.config/.claude/specs/623_coordinate_orchestration_best_practices/reports/001_coordinate_orchestration_best_practices/001_bash_execution_context_and_subshell_patterns.md:20-34`):

- History expansion (`histexpand`) is **disabled by default** in non-interactive bash shells (scripts)
- Test result: `bash -c 'shopt -o | grep histexpand'` → `histexpand off`
- Implication: The "!: command not found" error is NOT caused by history expansion being active
- History expansion only works when explicitly enabled with `set -o histexpand` AND `HISTFILE` is set

**Actual Root Cause** (from diagnostic reports):
The "!: command not found" errors occur when bash tries to execute a command referencing an **unavailable function**, not from history expansion. Example:
```bash
# Indirect variable reference ${!varname}
if [ ! -f "$FILE" ]; then  # Bash interprets ! as command in certain contexts
  echo "ERROR"
fi
```

**Special Character Escaping Best Practices** (from web research):

**Exclamation Mark (!):**
- Only backslash (\) and single quotes can quote the history expansion character
- Disable history expansion: `set +H` (already used in coordinate.md:46)
- In double quotes: Must escape with backslash (`\!`)

**Dollar Sign ($):**
- Double quotes preserve literal value EXCEPT for: `$`, `` ` ``, `\`, and (when history expansion enabled) `!`
- Single quotes treat everything as literal (safest for complex strings)

**General Quoting Strategy:**
1. **Single quotes**: Best for literal strings containing special characters
2. **Backslash escaping**: For individual characters within double quotes
3. **Double quotes**: When variable expansion is needed but want to preserve other special characters

**Evidence from Codebase**:
- `/home/benjamin/.config/.claude/commands/coordinate.md:46`: Uses `set +H` as defensive measure
- `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md:161`: Documents `bash: !: command not found` errors despite `set +H`
- Multiple library files use workarounds: "Avoid ! operator due to Bash tool preprocessing issues" (context-pruning.sh:54, workflow-initialization.sh:328)

### 3. Execution Method Comparison

**Bash Execution Methods and Their Characteristics**

**1. Direct Execution in Current Shell**
```bash
VAR="value"
echo "$VAR"  # Works - same process
```
- **Scope**: Current process only
- **Variable persistence**: Yes (within same process)
- **Use case**: Sequential commands in single bash block

**2. Subshell (parentheses)**
```bash
(
  VAR="value"
  echo "$VAR"  # Works inside subshell
)
echo "$VAR"  # Empty - subshell boundary
```
- **Scope**: Child process of current shell
- **Variable persistence**: No (lost after closing parenthesis)
- **Use case**: Isolated temporary operations

**3. Command Substitution (backticks or $())**
```bash
RESULT=$(echo "value")  # Subshell for command execution
echo "$RESULT"  # Works - captured output
```
- **Scope**: Subshell created for command execution
- **Variable persistence**: No (variables don't escape), but output is captured
- **Use case**: Capturing command output

**4. bash -c (separate process)**
```bash
bash -c 'VAR="value"; echo "$VAR"'  # Works inside -c string
echo "$VAR"  # Empty - separate process
```
- **Scope**: Completely separate bash process
- **Variable persistence**: No (independent process)
- **Pitfalls**: Arguments after -c are positional parameters ($0, $1), not command arguments
- **Use case**: Executing complete command strings in clean environment

**Comparison from Web Research**:
- **Word splitting** happens after variable expansion and command substitution
- **Argument passing in bash -c**: Extra arguments are assigned to positional parameters ($0, $1, etc.), not passed to commands
  - Correct: `bash -c 'echo "$0" "$1"' foo bar`
  - Incorrect: `bash -c 'echo' foo bar` (foo/bar not passed to echo)
- **Quoting critical**: Single quotes prevent parent shell expansion, double quotes allow variable expansion in parent shell

**Evidence from Diagnostic Report 002** (lines 506-517):
```
Block 1 (PID 12345) → State written to file_12345.txt
Block 2 (PID 67890) → Tries to read file_67890.txt (DIFFERENT!)

NOT this (parent-child):
Block 1 (PID 12345) → fork() → Block 2 (inherits $$)
```

**Markdown Bash Block Execution Model** (from coordinate-state-management.md:72-75):
```bash
# Subprocess (how Bash tool actually works)
bash -c 'export VAR="value"'  # Process 1
bash -c 'echo "$VAR"'         # Process 2 (sibling to Process 1)
# Output: (empty - processes don't share environment)
```

### 4. Best Practices for Complex Argument Passing

**Problem Statement**

Passing complex arguments (with special characters, spaces, or variable content) across subprocess boundaries is error-prone due to multiple layers of shell interpretation.

**File-Based State Approach** (Implemented in /coordinate)

**Pattern** (from diagnostic report 002, lines 154-188):
```bash
# Part 1: Write to fixed filename
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
echo "workflow description with special chars !@#$" > "$COORDINATE_DESC_FILE"

# Part 2: Read from same filename (different process)
COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
if [ -f "$COORDINATE_DESC_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE")
else
  echo "ERROR: File not found" >&2
  exit 1
fi
```

**Why This Works**:
- ✅ No shell interpretation of content (raw bytes in file)
- ✅ Same filename in both processes (no PID dependency)
- ✅ Handles arbitrary special characters safely
- ✅ Comprehensive error handling with diagnostics

**Anti-Pattern: $$ (Process ID) in Filenames** (from diagnostic report 002, lines 26-66):
```bash
# BROKEN - Process ID changes between blocks
# Block 1 (PID 12345)
echo "data" > /tmp/file_$$.txt  # Creates file_12345.txt

# Block 2 (PID 67890)
cat /tmp/file_$$.txt  # Tries to read file_67890.txt - DOESN'T EXIST!
```

**State Persistence Library Approach** (GitHub Actions pattern)

From coordinate-state-management.md and state-persistence.sh:
```bash
# Initialize state file (returns path)
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Save state (append to file)
append_workflow_state "KEY" "value with spaces and !@#$"

# Load state (read all keys/values)
load_workflow_state "$WORKFLOW_ID"
# Now KEY="value with spaces and !@#$" is available
```

**Quoting Best Practices** (from web research):

**Single Quotes for Literal Strings**:
```bash
bash -c 'echo "literal $VAR with !@#$"'  # No expansion, all literal
```

**Double Quotes for Variable Expansion**:
```bash
bash -c "echo \"expanded $VAR with content\""  # $VAR expanded by parent shell
```

**Positional Parameters in bash -c**:
```bash
# Correct way to pass arguments
bash -c 'echo "arg0=$0 arg1=$1"' "zero" "one"
# Output: arg0=zero arg1=one

# Common mistake
bash -c 'echo "data"' "arg1" "arg2"
# "arg1" and "arg2" are $0 and $1, NOT passed to echo command
```

**Evidence from Codebase**:
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`: Implements GitHub Actions-style state file pattern
- `/home/benjamin/.config/.claude/commands/coordinate.md:34-36`: Fixed filename pattern for workflow description
- `/home/benjamin/.config/.claude/commands/coordinate.md:60-76`: Comprehensive file existence and content validation

### 5. Common Pitfalls with Positional Parameters

**Pitfall #1: Positional Parameters Lost Across Subprocess Boundaries**

When invoking a subprocess with `bash -c`, positional parameters ($1, $2, etc.) from the parent process are NOT automatically passed to the subprocess.

**Example** (from diagnostic report 002, lines 102-128):
```bash
# Coordinate command receives workflow description as argument
/coordinate "Research bash patterns"

# Inside coordinate.md (conceptually):
# $1 = "Research bash patterns"  ← Available in first bash block

# Subsequent bash blocks (different processes):
# $1 = ???  ← NOT available! Process isolation!
```

**Solution**: Capture to file in first block, read in subsequent blocks (implemented fix in coordinate.md).

**Pitfall #2: bash -c Arguments Are Positional Parameters, Not Command Arguments**

**Common mistake** (from web research):
```bash
# Trying to pass arguments to the command inside -c
bash -c 'echo' "hello" "world"
# Result: echo runs with NO arguments
# "hello" becomes $0, "world" becomes $1 (for the bash process, not echo)
```

**Correct approach**:
```bash
# Reference positional parameters explicitly
bash -c 'echo "$@"' bash "hello" "world"
# Or: bash -c 'echo "$0" "$1"' "hello" "world"
```

**Pitfall #3: Library Sourcing Overwrites Variables**

**Problem** (from diagnostic report 003, lines 59-98):
```bash
# Parent script
WORKFLOW_DESCRIPTION="Research patterns"

# Source library that declares WORKFLOW_DESCRIPTION=""
source library.sh

# Now WORKFLOW_DESCRIPTION is EMPTY!
```

**Root cause**: Libraries with global variable declarations overwrite parent script variables when sourced.

**Solution** (implemented in coordinate.md, lines 78-82):
```bash
# SAVE before sourcing
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC

# Source library (will overwrite WORKFLOW_DESCRIPTION)
source library.sh

# Use saved value
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
```

**Pitfall #4: Empty Parameter Detection Edge Cases**

**Weak validation**:
```bash
if [ -z "$PARAM" ]; then
  echo "ERROR"
fi
```

**Problem**: Only checks if empty, not if file exists or is readable.

**Strong validation** (from coordinate.md:60-76):
```bash
if [ -f "$FILE_PATH" ]; then
  PARAM=$(cat "$FILE_PATH")
else
  echo "ERROR: File not found: $FILE_PATH"
  echo "This usually means Part 1 didn't execute."
  exit 1
fi

if [ -z "$PARAM" ]; then
  echo "ERROR: Parameter is empty"
  echo "File exists but contains no content: $FILE_PATH"
  exit 1
fi
```

**Benefits**: Distinguishes between "file missing" vs "file empty" vs "read failure".

**Pitfall #5: Array Iteration with Indirect References**

**Problem** (from coordinate.md comments and library files):
```bash
# Syntax ${!ARRAY[@]} triggers history expansion errors in some contexts
for i in ${!REPORT_PATHS[@]}; do
  echo "${REPORT_PATHS[$i]}"
done
```

**Workaround patterns found in codebase**:
```bash
# C-style for loop (workflow-initialization.sh:297)
for ((i=0; i<${#ARRAY[@]}; i++)); do
  echo "${ARRAY[$i]}"
done

# Nameref pattern (bash 4.3+, context-pruning.sh:54)
local -n array_ref="$array_name"
for item in "${array_ref[@]}"; do
  echo "$item"
done
```

## Recommendations

### 1. State Management Pattern Selection

**For Markdown Bash Block Commands (like /coordinate):**

**Primary Pattern: Stateless Recalculation** (recommended for most cases)
- **When to use**: Variables can be recalculated quickly (<5ms per block)
- **Performance**: ~2ms overhead per block (12ms total for 6 blocks)
- **Implementation**: Each block independently recalculates all needed variables
- **Example**: CLAUDE_PROJECT_DIR detection (Standard 13), scope detection, phase mapping

**Secondary Pattern: File-Based State** (for expensive or user-provided data)
- **When to use**: Variable calculation is expensive (>30ms) OR data comes from user input
- **Performance**: ~30ms overhead per file read/write operation
- **Implementation**: Fixed semantic filenames (NOT $$ based), comprehensive error handling
- **Example**: Workflow description capture, workflow state ID persistence

**Anti-Pattern: Export/Environment Variables**
- **Why avoid**: Does not persist across subprocess boundaries
- **Performance impact**: Zero benefit (doesn't work)
- **Only valid use**: Within single bash block for child processes

### 2. Variable Persistence Across Bash Blocks

**DO:**
- ✅ Use fixed semantic filenames: `${HOME}/.claude/tmp/command_variable.txt`
- ✅ Validate file exists AND has content (separate error messages)
- ✅ Use timestamp-based IDs: `workflow_$(date +%s)` for uniqueness
- ✅ Clean up temp files: `trap "rm -f '$FILE'" EXIT`
- ✅ Save critical variables before sourcing libraries that may overwrite them

**DON'T:**
- ❌ Use $$ in filenames (changes between bash blocks)
- ❌ Rely on export to persist variables across blocks
- ❌ Assume positional parameters ($1, $2) persist across blocks
- ❌ Use /tmp for workflow files (use project-specific tmp directory)
- ❌ Weak validation (check file exists separately from content check)

### 3. Library Sourcing Safety

**Pattern: Save-Source-Restore**
```bash
# 1. Save critical variables BEFORE sourcing
SAVED_VAR="$IMPORTANT_VAR"
export SAVED_VAR

# 2. Source library (may overwrite IMPORTANT_VAR)
source library.sh

# 3. Use saved value where needed
initialize_function "$SAVED_VAR" "$OTHER_ARGS"
```

**Library Design Recommendations** (for future improvements):
- Remove global variable pre-initialization (declare locally in functions instead)
- Use namespace prefixes for library variables (e.g., `WSM_WORKFLOW_SCOPE`)
- Provide explicit initialization functions instead of relying on sourcing side effects
- Document which variables are modified by sourcing

### 4. Special Character Handling

**Quoting Strategy:**
1. **User input with special characters**: Store in files (no escaping needed)
2. **Literal strings in scripts**: Use single quotes `'literal !@#$ text'`
3. **Variable expansion needed**: Use double quotes `"expanded $VAR text"`
4. **bash -c commands**: Single quotes for command string, double quotes for expanded variables

**Defensive Measures:**
- Include `set +H` at start of bash blocks (disable history expansion)
- Avoid `!` operator in compound conditions (use separate if statements instead)
- Use `${var:-default}` pattern for safe parameter expansion
- Prefer C-style for loops over `${!array[@]}` syntax

### 5. Error Handling and Diagnostics

**Comprehensive Error Messages Pattern:**
```bash
if [ ! -f "$FILE" ]; then
  echo "ERROR: File not found: $FILE" >&2
  echo "Expected location: $(dirname "$FILE")" >&2
  echo "This usually means: [explain likely root cause]" >&2
  echo "To fix: [provide actionable next step]" >&2
  exit 1
fi
```

**Benefits:**
- Distinguishes between different failure modes
- Provides context about what was expected
- Explains likely cause
- Suggests remediation

**Use fail-fast with set -euo pipefail:**
```bash
set -euo pipefail  # Fail fast on errors, undefined variables, pipe failures
set +H             # Disable history expansion
```

### 6. Testing and Validation Requirements

**For State Management Changes:**
- ✅ Test with multiple bash blocks (minimum 3 blocks)
- ✅ Verify state persists across block boundaries
- ✅ Test with special characters in data (!@#$%^&*)
- ✅ Test error paths (missing files, empty content, permission errors)
- ✅ Validate cleanup (temp files removed on success and failure)

**For Library Modifications:**
- ✅ Test sourcing behavior (verify no variable overwrites)
- ✅ Test in isolation and with command integration
- ✅ Document which variables are modified
- ✅ Check impact on existing commands (/coordinate, /orchestrate, /supervise)

### 7. Performance Optimization

**Measurement First:**
- Don't optimize based on assumptions
- Measure actual performance: `time { operations; }`
- Compare alternatives with real data

**Stateless Recalculation vs File I/O:**
- Git command (CLAUDE_PROJECT_DIR): <1ms (worth recalculating)
- String pattern matching: <1ms (worth recalculating)
- File read/write: 30ms (amortize with fixed filenames)
- Complex computation: >100ms (cache in file or state-persistence.sh)

**Optimization Guidelines from Research:**
- Minimize subshell usage (20%+ performance impact)
- Use process substitution over pipelines where possible
- Avoid unnecessary file I/O (recalculate when <5ms)
- Use redirection instead of pipelines to preserve scope

## References

### Codebase Files Analyzed

**Diagnostic Reports:**
- `/home/benjamin/.config/.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/002_diagnostic_analysis.md` (lines 1-646)
  - Process ID ($$ pattern) issues and fixes
  - File-based state implementation
  - Testing plan and validation requirements
- `/home/benjamin/.config/.claude/specs/620_fix_coordinate_bash_history_expansion_errors/reports/003_bash_variable_scoping_diagnostic.md` (lines 1-432)
  - Library sourcing overwrites parent variables
  - Save-source-restore pattern
  - Bash variable scoping reference
- `/home/benjamin/.config/.claude/docs/architecture/coordinate-state-management.md` (lines 1-199)
  - Subprocess isolation constraint
  - Stateless recalculation pattern
  - Performance measurements

**Command Files:**
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-1082)
  - Two-step execution pattern (lines 17-39)
  - State machine initialization (lines 44-221)
  - Fixed filename pattern implementation (lines 34-36, 60-76)
  - Save-restore pattern for library sourcing (lines 78-82)

**Library Files:**
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 74-77)
  - Global variable pre-initialization issue
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (lines 297, 328)
  - C-style for loop workaround
  - Nameref pattern for array iteration
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` (lines 54, 152, 249, 258, 322, 330, 338)
  - Array iteration patterns avoiding history expansion
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`
  - GitHub Actions-style state file pattern

**Documentation:**
- `/home/benjamin/.config/.claude/docs/troubleshooting/bash-tool-limitations.md` (line 161)
  - "!: command not found" errors despite set +H
- `/home/benjamin/.config/.claude/specs/623_coordinate_orchestration_best_practices/reports/001_coordinate_orchestration_best_practices/001_bash_execution_context_and_subshell_patterns.md` (lines 20-34, 584)
  - History expansion disabled by default in non-interactive shells
  - Bash execution context analysis

### External Resources

**Web Search Results:**

**Bash Variable Scoping:**
- GitHub Gist: "Bash: The Scoping Rules of Bash" - https://gist.github.com/CMCDragonkai/0a66ba5e37c5d1746d8bc814b37d6e1d
- Unix StackExchange: "If processes inherit the parent's environment, why do we need export?" - https://unix.stackexchange.com/questions/130985/
- Unix StackExchange: "bash variable visibility in subshell of command substitution" - https://unix.stackexchange.com/questions/309327/
- TLDP Advanced Bash Scripting Guide: "Subshells" - https://tldp.org/LDP/abs/html/subshells.html
- Key finding: Variables in subshells not visible outside, export doesn't work for parent-to-child variable passing

**History Expansion and Special Characters:**
- Stack Overflow: "How can I escape history expansion exclamation mark inside a double quoted string?" - https://stackoverflow.com/questions/22125658/
- bashcommands.com: "Bash Escape Exclamation: Mastering Special Characters"
- LinuxSimply: "How to Escape Special Characters in Bash String? [5 methods]"
- Baeldung: "Escaping Characters in Bash" - https://www.baeldung.com/linux/bash-escape-characters
- Key finding: Only backslash and single quotes quote history expansion character; set +H disables it

**bash -c and Argument Passing:**
- Stack Overflow: "How to pass all bash arguments to bash -c within command substitution?" - https://stackoverflow.com/questions/70107888/
- Stack Overflow: "I can't seem to use the Bash -c option with arguments" - https://stackoverflow.com/questions/1711970/
- Greg's Wiki: "BashPitfalls" - https://mywiki.wooledge.org/BashPitfalls
- Unix StackExchange: "Add arguments to 'bash -c'" - https://unix.stackexchange.com/questions/144514/
- Key finding: Arguments after -c are positional parameters ($0, $1), not command arguments

**Performance Best Practices:**
- MoldStud: "How to Avoid Common Performance Issues in Bash Scripting"
- Mindful Chase: "Troubleshooting Subshell and Concurrency Issues in Bash Scripts"
- Key finding: Minimize subshell usage (20%+ performance impact), use process substitution

### Related Specifications

- Spec 620: "Fix coordinate bash history expansion errors" - Root cause investigation and fix implementation
- Spec 597, 598: Coordinate command validation and testing
- Specs 582-594: 13 refactor attempts leading to stateless recalculation pattern
- Spec 623: Coordinate orchestration best practices and bash execution patterns

### GitHub Issues

- Issue #334: Export persistence limitation first identified
- Issue #2508: Confirmed subprocess model (not subshell) in Claude Code Bash tool
