# Bash Execution Context and Subshell Patterns Research Report

## Metadata
- **Date**: 2025-11-09
- **Agent**: research-specialist
- **Topic**: Bash Execution Context and Subshell Patterns
- **Report Type**: Best practices and pattern recognition
- **Context**: Investigating "!: command not found" errors in coordinate.md execution
- **Overview Report**: [Coordinate Orchestration Best Practices Overview](OVERVIEW.md)
- **Related Implementation Plan**: [Fix coordinate.md Bash History Expansion Errors](../../../620_fix_coordinate_bash_history_expansion_errors/plans/001_coordinate_history_expansion_fix.md)

## Executive Summary

This research investigates bash execution context issues causing "!: command not found" errors in coordinate.md. The investigation reveals that these errors are NOT caused by history expansion (which is disabled by default in non-interactive shells), but rather by how Claude's Bash tool handles markdown code blocks and maintains context between sequential bash block executions. Each bash code block in markdown may execute in an isolated context, causing sourced library functions and exported variables to be unavailable in subsequent blocks. The nameref pattern in `reconstruct_report_paths_array()` works correctly in isolation, suggesting the issue lies in context preservation between bash blocks rather than syntax errors.

## Findings

### 1. History Expansion Behavior in Non-Interactive Shells

**Key Discovery**: History expansion (`histexpand`) is **disabled by default** in non-interactive bash shells (scripts).

**Evidence**:
- Test result: `bash -c 'shopt -o | grep histexpand'` → `histexpand off`
- Location: Bash 5.2.37(1)-release running on Linux
- Implication: The "!: command not found" error is NOT caused by history expansion being active

**Source References**:
- Red Hat Sysadmin article on bash history modifiers
- Unix StackExchange discussions on history expansion
- Direct testing in /tmp/test_bash_context.sh (lines 1-20)

**Important Context**:
- History expansion only works when explicitly enabled with `set -o histexpand` AND `HISTFILE` is set
- In non-interactive shells, exclamation marks are treated literally unless history expansion is explicitly enabled
- The error message "!: command not found" suggests bash is trying to execute "!" as a command, not expand it as history

### 2. Bash Code Block Execution Context in Claude's Bash Tool

**Key Discovery**: Markdown code blocks executed via Claude's Bash tool may run in **separate shell instances**, causing context isolation between blocks.

**Evidence**:
- Each bash code block in coordinate.md (lines 23-267) appears to run independently
- Error occurs at lines 248/260 during execution of code that references functions defined in earlier blocks
- Web search results confirm: "Bash markdown cells are executed in separate shell instances"

**Context Isolation Implications**:
1. Variables defined in first bash block may not persist to second block
2. Functions sourced in first bash block may not be available in second block
3. Exported environment variables should persist, but local variables and functions do not

**Coordinate.md Structure** (/home/benjamin/.config/.claude/commands/coordinate.md):
- Lines 23-140: First bash block (initialization, library sourcing, path setup)
- Lines 248-260: Code referencing `reconstruct_report_paths_array()` function
- Function defined in: /home/benjamin/.config/.claude/lib/workflow-initialization.sh:318

**Problem Pattern**:
```bash
# Block 1 (lines 23-140)
source "${LIB_DIR}/workflow-initialization.sh"  # Defines reconstruct_report_paths_array()

# Block 2 (lines 248-260) - POTENTIALLY NEW SHELL CONTEXT
reconstruct_report_paths_array  # Function not found if context lost
```

### 3. Function Export and Subshell Inheritance Patterns

**Key Concept**: Functions must be explicitly exported to be available in child processes/subprocesses.

**Export Mechanisms**:
- `export -f function_name` - Exports function to child bash processes
- Functions sourced in parent shell are NOT automatically available in child shells
- Subshells created with `()` inherit parent shell functions WITHOUT export
- Subprocesses created with separate bash invocations require `export -f`

**Distinction Between Subshells and Subprocesses**:
- **Subshell** `( commands )`: Inherits variables and functions from parent automatically
- **Subprocess** `bash -c "commands"` or new bash invocation: Requires explicit export of functions
- **Context**: Claude's Bash tool executing markdown blocks may create new bash processes, not subshells

**Relevance to coordinate.md**:
- If bash blocks execute as separate processes, functions from workflow-initialization.sh need explicit export
- Currently no `export -f` statements found in coordinate.md:1-140
- Libraries assume functions remain available throughout script execution

### 4. Nameref Variable Pattern Analysis

**Function Under Investigation**: `reconstruct_report_paths_array()` in workflow-initialization.sh:318-326

**Code Analysis**:
```bash
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"
    local -n path_ref="$var_name"  # Nameref declaration
    REPORT_PATHS+=("$path_ref")
  done
}
```

**Testing Results**:
- Test script: /tmp/test_nameref.sh
- Result: **SUCCESS** - Pattern works correctly in isolation
- Bash version compatibility: Works on Bash 5.2.37 (requires Bash 4.3+)

**Key Findings**:
- The nameref pattern itself is syntactically correct
- No history expansion issues in the function (no bare `!` characters)
- Function executes successfully when called in same shell context
- The comment on line 322 explicitly mentions "bash 4.3+ pattern to avoid history expansion"

**Implications**:
- The error is NOT in the function implementation
- The error is caused by the function being unavailable in the calling context
- This confirms the context isolation hypothesis

### 5. Character Encoding and Hidden Character Analysis

**Investigation**: Checked for non-printable characters that might cause parsing issues.

**Method**: `sed -n '248,260p' coordinate.md | od -c`

**Results**:
- No hidden/non-printable characters found at lines 248-260
- All characters are standard ASCII
- No Unicode issues, BOM markers, or control characters
- Output shows clean newlines (`\n`) and standard bash syntax

**Conclusion**: Character encoding is not the cause of the error.

### 6. Library Sourcing Patterns and Dependencies

**Coordinate.md Library Loading** (lines 44-95):
```bash
source "${LIB_DIR}/workflow-state-machine.sh"      # Line 51
source "${LIB_DIR}/state-persistence.sh"           # Line 57
source "${LIB_DIR}/library-sourcing.sh"            # Line 75
source_required_libraries "${REQUIRED_LIBS[@]}"    # Line 92
source "${LIB_DIR}/workflow-initialization.sh"     # Line 98
```

**Workflow-initialization.sh Dependencies** (lines 20-35):
```bash
source "$SCRIPT_DIR/topic-utils.sh"        # Line 22
source "$SCRIPT_DIR/detect-project-dir.sh" # Line 30
```

**Critical Functions Defined in workflow-initialization.sh**:
- `initialize_workflow_paths()` (line 79) - Main initialization function
- `reconstruct_report_paths_array()` (line 318) - Array reconstruction
- Both are called from coordinate.md second bash block

**Sourcing Strategy**:
- All libraries use relative path resolution via `$SCRIPT_DIR`
- No explicit function exports (`export -f`) after sourcing
- Assumes single continuous bash execution context

**Risk**: If bash blocks execute in separate processes, all these functions become unavailable.

### 7. Error Line Number Discrepancy Analysis

**Reported Error**:
```
/run/current-system/sw/bin/bash: line 248: !: command not found
/run/current-system/sw/bin/bash: line 260: !: command not found
```

**Actual Content at Lines 248-260** (coordinate.md):
```bash
248: if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
249:   RESEARCH_COMPLEXITY=1
250: fi
252: echo "Research Complexity Score: $RESEARCH_COMPLEXITY topics"
254: # Reconstruct REPORT_PATHS array
255: reconstruct_report_paths_array
258: USE_HIERARCHICAL_RESEARCH=$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")
260: if [ "$USE_HIERARCHICAL_RESEARCH" = "true" ]; then
```

**Analysis**:
- No bare exclamation marks at these lines
- Line 248: Exclamation in regex pattern (properly quoted)
- Line 255: Function call to `reconstruct_report_paths_array`
- Line 260: Standard if statement

**Hypothesis**: The error line numbers may be **cumulative** across all bash blocks, not per-block. If coordinate.md first bash block is ~140 lines, and the error occurs at line 248 of the combined execution, that would place it at approximately line 108 of the second bash block (248-140=108).

**Implication**: The actual error may not be at coordinate.md:248, but rather at a different location when all bash blocks are concatenated for execution.

### 8. Bash Execution via Claude Bash Tool - Architectural Analysis

**How Markdown Bash Blocks are Executed**:
Based on web search results and testing:

1. **Possible Architecture A**: Each `\`\`\`bash` block executed as separate bash invocation
   - `bash -c "content_of_block_1"`
   - `bash -c "content_of_block_2"`
   - Result: Complete context isolation, functions/variables lost between blocks

2. **Possible Architecture B**: All bash blocks concatenated and executed together
   - Content of all blocks merged into single script
   - Executed as one continuous bash process
   - Result: Context preserved, but line numbers become cumulative

3. **Possible Architecture C**: Persistent bash session with block-by-block execution
   - Single bash process receives commands incrementally
   - Context preserved between blocks
   - Result: Functions and variables available throughout

**Evidence Suggests**: Architecture A or B with context isolation issues

**Supporting Evidence**:
- Error occurs when calling function defined in earlier block
- Error message format suggests separate bash invocation
- No state persistence mechanism visible in coordinate.md structure
- Web search confirms markdown bash blocks often run in separate instances

### 9. Heredoc and Command Substitution Patterns

**Relevance**: Understanding how special characters are parsed in different bash contexts.

**Key Findings from Web Search**:
- **Quoted heredocs** (`<<'EOF'`) disable all expansion (variables, commands, history)
- **Unquoted heredocs** (`<<EOF`) enable expansion
- **Command substitution** `$()` can interact with heredoc parsing
- Bash 4.1+ fixed issues with unbalanced quotes in heredocs within command substitution

**Application to coordinate.md**:
- No heredocs found in problematic sections (lines 248-260)
- Command substitution used at line 258: `$([ $RESEARCH_COMPLEXITY -ge 4 ] && echo "true" || echo "false")`
- This is standard syntax, should not cause issues

**Conclusion**: Heredoc/command substitution not the root cause.

### 10. State Persistence Mechanisms in coordinate.md

**Coordinate.md State Management** (lines 59-73):
```bash
# Initialize workflow state (GitHub Actions pattern)
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT

# Save workflow ID for subsequent blocks
append_workflow_state "WORKFLOW_ID" "coordinate_$$"
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
```

**Purpose**: File-based state persistence for workflow variables

**Observation**: State persistence implemented for **variables** but not for **functions**

**Gap**: If bash blocks run in separate processes:
- Variables can be restored from STATE_FILE
- Functions sourced in block 1 are NOT persisted to block 2
- No mechanism to re-source libraries in subsequent blocks

**This is likely the root cause of the error.**

### 11. Spec 617 Context - Previous Fix Validation

**Reference**: Plan states "Spec 617 fixed all `${!...}` patterns in library files (verified working)"

**Pattern Fixed in Spec 617**:
- Indirect variable expansion: `${!var_name}`
- This pattern can trigger history expansion in some contexts
- Libraries were updated to avoid this pattern

**Validation**:
- grep search for `${!` patterns in workflow-initialization.sh: No matches found
- Function `reconstruct_report_paths_array` uses nameref (`local -n`) instead of indirect expansion
- This is the correct modern pattern (Bash 4.3+)

**Conclusion**: Spec 617 fix was implemented correctly. The current issue is different (context isolation, not indirect expansion).

## Recommendations

### 1. Re-source Required Libraries in Each Bash Block (RECOMMENDED)

**Problem**: Functions sourced in first bash block may not be available in subsequent blocks if they execute in separate bash processes.

**Solution**: Add library sourcing at the beginning of each bash block that needs those functions.

**Implementation** (coordinate.md second bash block):
```bash
# At the start of EVERY bash block that uses library functions:
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source critical libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/state-persistence.sh"
# Add other required libraries as needed
```

**Benefits**:
- Ensures functions are always available regardless of execution context
- Handles both separate-process and single-process execution models
- Minimal performance overhead (library sourcing is fast)
- Defensive programming - works in all scenarios

**Trade-offs**:
- Slight code duplication
- Libraries sourced multiple times (usually harmless)

### 2. Export Critical Functions After Sourcing (ALTERNATIVE)

**Problem**: Functions need to be available in child bash processes.

**Solution**: Use `export -f` to export functions to child processes.

**Implementation** (coordinate.md first bash block):
```bash
# After sourcing workflow-initialization.sh
source "${LIB_DIR}/workflow-initialization.sh"

# Export critical functions
export -f initialize_workflow_paths
export -f reconstruct_report_paths_array
export -f display_brief_summary
export -f handle_state_error
# Export other functions as needed
```

**Benefits**:
- Functions available in all child bash processes
- Follows bash best practices for subprocess function availability
- One-time export per session

**Trade-offs**:
- Only works if bash blocks run as child processes (not separate processes)
- Requires maintaining list of exported functions
- May not work if Claude's Bash tool uses complete process isolation

**Risk**: This may not solve the problem if bash blocks are completely independent processes.

### 3. Consolidate Bash Blocks into Single Block (ARCHITECTURAL)

**Problem**: Multiple bash blocks may execute in separate contexts.

**Solution**: Combine all coordinate.md bash code into a single continuous bash block.

**Implementation**:
- Merge all bash blocks in coordinate.md into one large block
- Use comments to separate logical sections
- Maintain readability with clear section markers

**Benefits**:
- Guaranteed single execution context
- No context isolation issues
- Functions and variables always available

**Trade-offs**:
- Reduces modularity and readability
- Harder to maintain separate phases
- Goes against markdown documentation structure conventions

**Assessment**: This is a **last resort** option if recommendations 1 and 2 fail.

### 4. Use State File to Persist Library Paths (ENHANCEMENT)

**Problem**: Each bash block needs to know where libraries are located.

**Solution**: Store library paths and sourcing commands in STATE_FILE.

**Implementation**:
```bash
# First bash block - save library info
append_workflow_state "LIB_DIR" "${LIB_DIR}"
append_workflow_state "SOURCED_LIBS" "workflow-initialization.sh state-persistence.sh"

# Subsequent bash blocks - restore and re-source
source_workflow_state  # Load STATE_FILE
for lib in $SOURCED_LIBS; do
  source "${LIB_DIR}/${lib}"
done
```

**Benefits**:
- Systematic approach to library availability
- Works well with existing state persistence pattern
- Easy to extend to new libraries

**Trade-offs**:
- Requires state-persistence.sh to be available (chicken-and-egg problem)
- More complex than simple re-sourcing

### 5. Create Library Source Guard Pattern (BEST PRACTICE)

**Problem**: Re-sourcing libraries multiple times can cause issues if they're not idempotent.

**Solution**: Add source guards to library files to prevent multiple execution of initialization code.

**Implementation** (in library files like workflow-initialization.sh):
```bash
# At top of library file
if [ -n "${WORKFLOW_INITIALIZATION_SOURCED:-}" ]; then
  return 0  # Already sourced, skip re-initialization
fi
export WORKFLOW_INITIALIZATION_SOURCED=1

# Rest of library code...
```

**Benefits**:
- Safe to source libraries multiple times
- Prevents duplicate initialization
- Standard pattern used in many bash libraries

**Trade-offs**:
- Requires updating all library files
- Must be careful with state that needs to be re-initialized

### 6. Add Diagnostic Logging for Context Debugging (TROUBLESHOOTING)

**Problem**: Difficult to diagnose exactly when and where context is lost.

**Solution**: Add logging at critical points to track execution context.

**Implementation**:
```bash
# At strategic points in coordinate.md
echo "DEBUG: PID=$$, PPID=$PPID, Block=1" >&2
echo "DEBUG: Functions available: $(declare -F | grep -c 'declare -f')" >&2
echo "DEBUG: reconstruct_report_paths_array available: $(declare -F | grep -q 'reconstruct_report_paths_array' && echo YES || echo NO)" >&2
```

**Benefits**:
- Reveals exactly when context isolation occurs
- Helps verify if fix is working
- Useful for future debugging

**Trade-offs**:
- Debug noise in output
- Should be removed after fixing issue

### 7. Document Bash Block Execution Model (DOCUMENTATION)

**Problem**: Future developers may encounter same issue if execution model is not documented.

**Solution**: Add explicit documentation about how bash blocks work in Claude slash commands.

**Location**: `.claude/docs/guides/command-development-guide.md`

**Content**:
```markdown
### Bash Block Execution Model

When using multiple bash blocks in slash command markdown files:

1. **Context Isolation**: Each bash block may execute in a separate bash process
2. **Function Availability**: Functions sourced in one block are not guaranteed to be available in subsequent blocks
3. **Variable Persistence**: Use state-persistence.sh for variables, re-source libraries for functions
4. **Best Practice**: Re-source required libraries at the start of each bash block

**Example Pattern**:
\`\`\`bash
# Every bash block should start with:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/required-library.sh"
\`\`\`
```

**Benefits**:
- Prevents future occurrences of this issue
- Educates developers on correct patterns
- Part of institutional knowledge base

## Priority Recommendation

**IMPLEMENT RECOMMENDATION #1 IMMEDIATELY**: Re-source required libraries in each bash block.

**Reasoning**:
1. Lowest risk - works regardless of underlying execution model
2. Simple to implement - add a few lines to each bash block
3. Defensive coding - handles all scenarios
4. Fast to verify - test coordinate.md immediately after implementation

**Follow-up**:
- Implement Recommendation #5 (source guards) to make re-sourcing safe
- Implement Recommendation #7 (documentation) to prevent future issues
- Consider Recommendation #2 (export functions) as additional safety measure

## References

### Codebase Files Analyzed

1. **/home/benjamin/.config/.claude/commands/coordinate.md**
   - Lines 1-50: Command metadata and first bash block initialization
   - Lines 23-140: First bash block (library sourcing, state initialization)
   - Lines 240-267: Second bash block (research complexity calculation, function calls)
   - Line 248: grep pattern with exclamation mark (properly quoted)
   - Line 255: Call to `reconstruct_report_paths_array()` function
   - Line 260: Conditional statement for hierarchical research

2. **/home/benjamin/.config/.claude/lib/workflow-initialization.sh**
   - Lines 1-14: Library header and documentation
   - Lines 15-35: Library dependencies (topic-utils.sh, detect-project-dir.sh)
   - Lines 79-258: `initialize_workflow_paths()` function definition
   - Lines 318-326: `reconstruct_report_paths_array()` function definition
   - Line 322: Comment mentioning "bash 4.3+ pattern to avoid history expansion"
   - Line 323: Nameref declaration `local -n path_ref="$var_name"`

3. **/home/benjamin/.config/.claude/specs/620_fix_coordinate_bash_history_expansion_errors/plans/001_coordinate_history_expansion_fix.md**
   - Lines 1-19: Plan metadata and problem statement
   - Lines 20-48: Error evidence and research findings
   - Lines 49-66: Root cause hypothesis
   - Lines 67-617: Four-phase diagnostic and resolution plan

4. **/home/benjamin/.config/.claude/lib/state-persistence.sh**
   - Referenced for GitHub Actions-style state management pattern
   - Used in coordinate.md lines 59-73

5. **/home/benjamin/.config/.claude/lib/topic-utils.sh**
   - Sourced by workflow-initialization.sh (line 22)
   - Provides `sanitize_topic_name()` and `get_or_create_topic_number()` functions

6. **/home/benjamin/.config/.claude/lib/detect-project-dir.sh**
   - Sourced by workflow-initialization.sh (line 30)
   - Provides project root detection functionality

### Test Scripts Created

1. **/tmp/test_bash_context.sh** (lines 1-20)
   - Tests: Interactive mode detection, histexpand setting, exclamation mark handling
   - Results: histexpand=off, all exclamation tests passed
   - Verified bash execution context behavior

2. **/tmp/test_nameref.sh** (lines 1-20)
   - Tests: Nameref pattern from `reconstruct_report_paths_array()`
   - Results: SUCCESS - Pattern works correctly in isolation
   - Confirmed nameref syntax is correct

### Web Search Sources

1. **Red Hat Sysadmin**: "Using word modifiers with Bash history in Linux"
   - URL: https://www.redhat.com/sysadmin/modifiers-bash-history
   - Topic: History expansion and histexpand option behavior

2. **Super User**: "In bash, how do I escape an exclamation mark?"
   - URL: https://superuser.com/questions/133780/in-bash-how-do-i-escape-an-exclamation-mark
   - Topic: Exclamation mark escaping and history expansion

3. **Unix StackExchange**: "Can I 'export' functions in bash?"
   - URL: https://unix.stackexchange.com/questions/22796/can-i-export-functions-in-bash
   - Topic: Function export mechanisms and subprocess inheritance

4. **Stack Overflow**: "Exporting a function in shell"
   - URL: https://stackoverflow.com/questions/1885871/exporting-a-function-in-shell
   - Topic: `export -f` syntax and behavior

5. **Server Fault**: "How do you escape characters in heredoc?"
   - URL: https://serverfault.com/questions/399428/how-do-you-escape-characters-in-heredoc
   - Topic: Heredoc quoting and special character handling

6. **Baeldung on Linux**: "Here Document and Here String"
   - URL: https://www.baeldung.com/linux/heredoc-herestring
   - Topic: Heredoc syntax variations and expansion rules

7. **GitHub Gist**: "Bash: The Scoping Rules of Bash"
   - URL: https://gist.github.com/CMCDragonkai/0a66ba5e37c5d1746d8bc814b37d6e1d
   - Topic: Variable and function scoping, subshell vs subprocess

8. **R Markdown Forum**: "bash chunk cannot source ~/.bashrc"
   - Topic: Bash code block execution in markdown contexts
   - Key finding: Markdown bash blocks often execute in separate shell instances

9. **Binary Phile Blog**: "Approach Bash Like a Developer - Part 34 - Indirection"
   - URL: https://www.binaryphile.com/bash/2018/10/28/approach-bash-like-a-developer-part-34-indirection.html
   - Topic: Nameref variables and indirection patterns

10. **Linux Journal**: "What's New in Bash Parameter Expansion"
    - URL: https://www.linuxjournal.com/content/whats-new-bash-parameter-expansion
    - Topic: Modern bash parameter expansion features including namerefs

### System Information

- **Bash Version**: GNU bash, version 5.2.37(1)-release (x86_64-pc-linux-gnu)
- **Operating System**: Linux 6.6.94 (NixOS)
- **Shell Mode**: Non-interactive (histexpand disabled by default)
- **Test Date**: 2025-11-09

### Related Specifications

1. **Spec 617**: "Fix ${!...} patterns in library files"
   - Status: Completed and verified working
   - Relevance: Fixed indirect variable expansion patterns
   - Validation: No `${!` patterns found in current library files

2. **Spec 613**: "Fix coordinate.md state machine errors"
   - Status: Completed
   - Relevance: Previous state machine implementation fixes

3. **Spec 602**: "State-based orchestration refactor"
   - Status: Completed
   - Relevance: Introduced state-persistence.sh and workflow-state-machine.sh

### Documentation References

1. **.claude/docs/guides/orchestration-troubleshooting.md**
   - Existing troubleshooting infrastructure for orchestration commands
   - Recommended location for documenting this issue (Section 6)

2. **.claude/docs/guides/command-development-guide.md**
   - Command development best practices
   - Recommended location for bash block execution model documentation

3. **.claude/docs/guides/coordinate-command-guide.md**
   - Coordinate-specific documentation
   - Should reference orchestration-troubleshooting.md Section 6

4. **.claude/docs/concepts/directory-protocols.md**
   - Artifact organization standards
   - Defines debug report structure and gitignore compliance

### Key Bash Manual References

- **bash(1) man page**: History expansion, histexpand option
- **bash(1) man page**: Function export with `export -f`
- **bash(1) man page**: Name references (namerefs) with `local -n`
- **bash(1) man page**: Subshell vs subprocess execution models
