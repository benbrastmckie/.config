# /coordinate Command Diagnostic Report

**Date**: 2025-11-04
**Issue**: Bash syntax errors preventing /coordinate command execution
**Status**: Root cause identified, solution requires architectural changes

---

## Executive Summary

The /coordinate command fails during Phase 0 initialization due to bash history expansion being triggered by indirect variable references (`${!varname}`) in sourced library files. The issue occurs when bash parses the script text before executing it, making inline `set +H` commands ineffective.

**Impact**: Command completely non-functional - fails before any agent invocations can occur.

**Root Cause**: Architectural mismatch between how Claude Code executes bash blocks from markdown files and bash's history expansion parsing behavior.

---

## Error Analysis

### Before Changes

```
● Bash(bash -c '...')
  ⎿  Error: Exit code 1
     bash: line 46: !: command not found
     bash: line 133: !: command not found
     environment: line 315: ${\!varname}: bad substitution
```

**Observations**:
- Error occurs on line 46, 133, and 315 of the parsed bash script
- Third error explicitly shows the problematic pattern: `${\!varname}`
- Script manages to partially execute: Phase 0 initialization starts and reports success
- Libraries are loaded (5 for research-and-plan scope)
- Workflow scope is detected correctly

### After Adding `set +H`

```
● Bash(set +H  # Disable history expansion...)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 391: !: command not found
     /run/current-system/sw/bin/bash: line 481: !: command not found
     /run/current-system/sw/bin/bash: line 642: !: command not found
     /run/current-system/sw/bin/bash: line 651: TOPIC_PATH: unbound variable
```

**Observations**:
- `set +H` is present but errors still occur
- Line numbers have changed (391, 481, 642 vs 46, 133, 315)
- New error appears: `TOPIC_PATH: unbound variable` on line 651
- Exit code changed from 1 to 127 (command not found)
- Script still manages to initialize partially

**Key Insight**: The `set +H` command is being executed, but the errors are still occurring at different line numbers. This suggests the problem is not with the execution of `set +H`, but with how bash parses the script before execution begins.

---

## Root Cause Analysis

### Issue 1: History Expansion During Script Parsing

**Problem**: Bash parses script text for history expansion BEFORE executing any commands, including `set +H`.

**Evidence**:
1. Indirect variable references in library files:
   - `/home/benjamin/.config/.claude/lib/context-pruning.sh:55`: `local full_output="${!output_var_name}"`
   - `/home/benjamin/.config/.claude/lib/context-pruning.sh:150-326`: Multiple `for key in "${!CACHE[@]}"` patterns (7 occurrences)
   - `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:289`: `for i in "${!report_paths[@]}"`
   - `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:317`: `REPORT_PATHS+=("${!var_name}")`

2. These patterns are valid bash syntax for:
   - Indirect variable expansion: `${!varname}` dereferences the variable name stored in `varname`
   - Array key iteration: `${!array[@]}` gets all keys of associative array

3. History expansion interprets `!` as a special character when enabled

**Why `set +H` Doesn't Work**:
```bash
bash -c 'set +H; echo ${!var}'  # Still fails!
```
The script text is parsed for history expansion BEFORE the `set +H` command executes. By the time `set +H` runs, bash has already tried to expand the `!` characters and failed.

### Issue 2: Claude Code Execution Context

**Observation**: The bash blocks in coordinate.md are being executed via `bash -c '...'` by Claude Code's SlashCommand execution engine.

**Problem**: When bash is invoked with `-c`, it parses the entire command string before executing it. If history expansion is enabled in the parent shell or bash configuration, it will attempt to expand `!` patterns during parsing.

**Complication**: History expansion is typically disabled in non-interactive shells, but the error messages suggest it's somehow enabled in this execution context.

### Issue 3: TOPIC_PATH Unbound Variable

**Error**: `/run/current-system/sw/bin/bash: line 651: TOPIC_PATH: unbound variable`

**Analysis**:
- `TOPIC_PATH` is exported by `workflow-initialization.sh` (line 277)
- Error occurs at line 651, which is after library sourcing should have completed
- This suggests the script is failing partway through, possibly due to the history expansion errors
- The variable isn't actually "unbound" - the script is just failing to reach the point where it would be set

**Why this appears after adding `set +H`**:
- The script runs further before failing
- Previous errors caused early termination before reaching code that uses `TOPIC_PATH`
- With `set +H`, the script executes more lines before encountering the next failure point

---

## Affected Files

### Library Files with Indirect Variable References

1. **`.claude/lib/context-pruning.sh`** (7 occurrences)
   - Line 55: `local full_output="${!output_var_name}"`
   - Line 150: `for key in "${!PRUNED_METADATA_CACHE[@]}"`
   - Line 245: `for phase_id in "${!PHASE_METADATA_CACHE[@]}"`
   - Line 252: `for key in "${!PRUNED_METADATA_CACHE[@]}"`
   - Line 314: `for key in "${!PRUNED_METADATA_CACHE[@]}"`
   - Line 320: `for key in "${!PHASE_METADATA_CACHE[@]}"`
   - Line 326: `for key in "${!WORKFLOW_METADATA_CACHE[@]}"`

2. **`.claude/lib/workflow-initialization.sh`** (2 occurrences)
   - Line 289: `for i in "${!report_paths[@]}"`
   - Line 317: `REPORT_PATHS+=("${!var_name}")`

### Command File

- **`.claude/commands/coordinate.md`**: 2,900+ lines
  - Sources affected libraries via `library-sourcing.sh`
  - Consolidates multiple bash blocks into single execution units
  - Uses `TOPIC_PATH` at lines 746, 747, 751, 763, 881, 925, 1640, 1759, 1831

---

## Why Previous Solution Failed

The attempted solution of adding `set +H` to bash blocks failed because:

1. **Timing Issue**: `set +H` executes after bash has already parsed the script text
2. **Parse vs Execute**: Bash parses the entire script for history expansion before executing any commands
3. **Scope Issue**: `set +H` in a bash block doesn't affect how the parent shell parses the command string passed to `bash -c`

**Analogy**: It's like trying to put on a seatbelt after the car has already crashed. The parsing (crash) happens before the command (seatbelt) can take effect.

---

## Technical Deep Dive

### Bash History Expansion Mechanics

History expansion is a feature where:
- `!` triggers command history substitution (e.g., `!!` = previous command)
- `${!var}` means "indirect variable expansion" in normal bash
- History expansion is processed during lexical analysis (parsing), not execution

### Execution Flow

```
┌─────────────────────────────────────────────────────────┐
│ Claude Code SlashCommand Engine                         │
├─────────────────────────────────────────────────────────┤
│ 1. Reads coordinate.md                                  │
│ 2. Extracts bash blocks                                 │
│ 3. Invokes: bash -c 'set +H; <script>'                 │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Bash Process                                            │
├─────────────────────────────────────────────────────────┤
│ PARSE PHASE (happens first):                           │
│   • Check shell options (history expansion enabled?)    │
│   • Tokenize script text                               │
│   • Expand history (!patterns) ❌ FAILS HERE           │
│                                                         │
│ EXECUTE PHASE (never reached):                         │
│   • Run: set +H                                        │
│   • Execute remaining commands                         │
└─────────────────────────────────────────────────────────┘
```

### Why History Expansion is Enabled

Normally, history expansion is disabled in:
- Non-interactive shells (scripts)
- Shell functions
- Command substitutions

However, it may be enabled due to:
1. User's bash configuration (`.bashrc`, `.bash_profile`)
2. System-wide bash configuration (`/etc/bash.bashrc`)
3. Environment variables (`HISTCONTROL`, `SHELLOPTS`)
4. Claude Code's shell initialization

**Evidence from Error**: The fact that history expansion is triggering suggests the bash invocation is somehow inheriting interactive shell behavior.

---

## Potential Solutions

### Solution 1: Escape Indirect Variable References (Quick Fix)

**Approach**: Modify library files to escape `!` characters

**Implementation**:
```bash
# Current (fails):
local full_output="${!output_var_name}"

# Fixed (escaped):
local full_output="\${!output_var_name}"  # Quote the entire expression
# OR
eval "local full_output=\"\${!output_var_name}\""
```

**Pros**:
- Minimal changes (9 lines across 2 files)
- Preserves existing architecture

**Cons**:
- Makes code harder to read
- May break other tools that parse these files
- Fragile - easy to miss instances in future code

### Solution 2: Disable History Expansion in Bash Invocation (Recommended)

**Approach**: Modify how Claude Code invokes bash blocks

**Implementation**:
```bash
# Instead of:
bash -c 'set +H; <script>'

# Use:
bash +H -c '<script>'  # +H disables history expansion at invocation
# OR
bash --norc --noprofile -c 'set +H; <script>'  # Skip config files
```

**Pros**:
- Fixes root cause at invocation point
- No changes to library files needed
- Cleaner, more maintainable

**Cons**:
- Requires changes to Claude Code's SlashCommand execution engine
- May not be accessible to users
- Unclear if Claude Code exposes this level of control

### Solution 3: Rewrite Using Alternative Patterns (Architectural)

**Approach**: Eliminate indirect variable references entirely

**For `${!var}` (indirect expansion)**:
```bash
# Current:
local var_name="REPORT_PATH_1"
local value="${!var_name}"

# Alternative using eval:
local value
eval "value=\$${var_name}"

# Alternative using nameref (bash 4.3+):
declare -n value_ref="$var_name"
local value="$value_ref"
```

**For `${!array[@]}` (array keys)**:
```bash
# Current:
for key in "${!CACHE[@]}"; do

# Alternative - store keys separately:
CACHE_KEYS=("${!CACHE[@]}")  # Do this once when array is created
for key in "${CACHE_KEYS[@]}"; do  # Use cached keys
```

**Pros**:
- Eliminates all `!` characters
- More portable (works with strict shell modes)
- May improve performance (cached keys)

**Cons**:
- Significant code changes (9 locations)
- Requires testing all affected functionality
- More complex array management
- May break backward compatibility

### Solution 4: Source Libraries from Files (Hybrid)

**Approach**: Instead of concatenating library code into coordinate.md's bash blocks, source them dynamically

**Current Pattern in coordinate.md**:
```bash
# Entire library code is embedded in the bash block
source "$LIB_DIR/workflow-initialization.sh"  # This works
```

**Issue**: When the bash block is passed to `bash -c`, the entire multi-hundred-line script is parsed at once with history expansion.

**Alternative**: Split into smaller, independently-sourced blocks:
```bash
# Phase 0 bash block: Only initialization, no library sourcing
bash -c 'WORKFLOW_DESCRIPTION="$1"; export WORKFLOW_SCOPE=...'

# Libraries source themselves in their own bash blocks (already done)
# No changes needed here

# Phase 1 bash block: Only Phase 1 logic, libraries already sourced in environment
bash -c 'emit_progress "1" "Starting Phase 1"'
```

**Pros**:
- Smaller bash blocks = less parsing overhead
- Libraries are sourced in clean environment
- May bypass history expansion issue if each block is small enough

**Cons**:
- State management between bash blocks more complex
- Environment variables must persist across blocks
- May increase subprocess overhead (contradicts Phase 0 optimization goal)

---

## Recommended Implementation Path

### Immediate Fix (Experimental)

Test if Claude Code can control bash invocation:

1. Check if there's a way to configure bash invocation flags in Claude Code
2. Try passing `+H` flag to bash invocation
3. If unsuccessful, proceed to library file modifications

### Short-Term Fix (If Claude Code Not Configurable)

Escape indirect variable references in library files:

```bash
# In context-pruning.sh and workflow-initialization.sh:
# Replace all instances of "${!var}" with "\${!var}" or use eval

# Example for line 55 of context-pruning.sh:
# Before:
local full_output="${!output_var_name}"

# After:
eval "local full_output=\"\${$output_var_name}\""
```

**Testing Protocol**:
1. Modify context-pruning.sh (7 instances)
2. Modify workflow-initialization.sh (2 instances)
3. Run /coordinate with simple research-only workflow
4. Verify Phase 0 completes without errors
5. Verify library functions still work correctly

### Long-Term Fix (Architectural)

Investigate moving to nameref pattern (bash 4.3+):

```bash
# Instead of indirect expansion:
local var_name="REPORT_PATH_1"
declare -n var_ref="$var_name"
echo "$var_ref"  # No ! character needed

# For array keys - cache them:
# In array initialization code:
declare -a CACHE_KEYS
CACHE_KEYS=("${!PRUNED_METADATA_CACHE[@]}")  # One-time extraction

# In iteration code:
for key in "${CACHE_KEYS[@]}"; do  # No ! character needed
  echo "${PRUNED_METADATA_CACHE[$key]}"
done
```

---

## Impact Assessment

### Current Impact

- **Severity**: Critical - Command completely non-functional
- **Scope**: Affects /coordinate command only (other commands not analyzed)
- **User Experience**: Complete workflow failure before any research can begin
- **Workaround**: None available - users cannot use /coordinate at all

### Post-Fix Impact

**If Solution 1 (Escaping) Implemented**:
- Risk: Medium - Eval introduces complexity and potential security concerns
- Testing Required: Extensive - All library functions must be verified
- Maintenance: Higher - Less readable code

**If Solution 2 (Invocation Flags) Implemented**:
- Risk: Low - Clean fix at invocation layer
- Testing Required: Minimal - No code changes
- Maintenance: None - Fix is transparent to users

**If Solution 3 (Rewrite) Implemented**:
- Risk: Medium-High - Large code changes
- Testing Required: Comprehensive - All workflows must be tested
- Maintenance: Lower - More readable, more maintainable code

---

## Testing Requirements

### Phase 1: Verify Fix

1. **Simple research-only workflow**:
   ```bash
   /coordinate "research authentication patterns"
   ```
   Expected: Complete without errors, generate 2 research reports

2. **Research-and-plan workflow**:
   ```bash
   /coordinate "research authentication to create implementation plan"
   ```
   Expected: Complete Phase 0-2, generate reports and plan

### Phase 2: Verify Library Functions

1. **Context Pruning** (context-pruning.sh):
   - Test metadata extraction from agent outputs
   - Test cache iteration (all 7 instances)
   - Verify pruned metadata still accessible

2. **Workflow Initialization** (workflow-initialization.sh):
   - Test report paths array reconstruction
   - Test indirect variable access for REPORT_PATH_N variables
   - Verify array iteration works correctly

### Phase 3: Full Integration

1. **Full-implementation workflow**:
   ```bash
   /coordinate "implement user authentication feature"
   ```
   Expected: Complete all phases including testing and documentation

2. **Debug-only workflow**:
   ```bash
   /coordinate "fix login failure bug"
   ```
   Expected: Complete research and debug phases

---

## Questions for Further Investigation

1. **Why is history expansion enabled?**
   - Is this a Claude Code configuration issue?
   - Is this a user's bash configuration?
   - Is this a NixOS-specific behavior? (Note: `/run/current-system/sw/bin/bash`)

2. **Can bash invocation be controlled?**
   - Does Claude Code allow customizing bash flags?
   - Is there a configuration file for SlashCommand execution?
   - Can users override bash invocation behavior?

3. **Are other commands affected?**
   - Does /orchestrate have the same issue?
   - Does /implement source the same libraries?
   - Do any other commands use indirect variable expansion?

4. **What is the bash version?**
   ```bash
   bash --version  # Check if nameref (4.3+) is available
   ```

---

## Conclusion

The /coordinate command failures are caused by bash history expansion being triggered during script parsing, before any `set +H` commands can execute. The root cause is indirect variable reference syntax (`${!varname}`) in 9 locations across 2 library files, combined with history expansion being enabled in the bash invocation context.

**Immediate Action Required**: Test Solution 2 (bash invocation flags) if accessible, otherwise implement Solution 1 (escaping) as a temporary fix while architecting Solution 3 (rewrite) for long-term maintainability.

**Priority**: Critical - This blocks all /coordinate functionality and likely affects other orchestration commands.
