# Command Substitution Escaping Failure Analysis

**Report ID**: 001_command_substitution_escaping_failure_analysis
**Created**: 2025-10-24
**Status**: Complete

## Executive Summary

The `/research` command (and likely other commands using unified location detection) is experiencing bash command substitution escaping failures when invoking multi-line bash commands containing `$(...)` syntax. The Bash tool is over-escaping the command substitution syntax, converting `$(perform_location_detection ...)` to `\$\(perform_location_detection ...)`, which causes bash to interpret it as a literal string with escaped characters instead of executing the command substitution.

The error manifests as: `syntax error near unexpected token 'perform_location_detection'`

This issue affects **4 slash commands** that use unified location detection: `/research`, `/report`, `/plan`, and `/orchestrate`.

## Problem Statement

### Failing Command Pattern

The following bash command pattern is present in 4 different slash command files:

```bash
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh" && \
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
```

### Actual Error from TODO4.md (lines 34-42)

```
Error: /run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token 'perform_location_detection'
/run/current-system/sw/bin/bash: eval: line 1: `source
/home/benjamin/.config/.claude/lib/unified-location-detection.sh &&
LOCATION_JSON\=\$ ( perform_location_detection 'template usage patterns
 in .claude/docs/' false ) && echo '' < /dev/null | grep -o
'"topic_path": *"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/''
```

### Key Observation

Notice the escaped syntax: `LOCATION_JSON\=\$ ( perform_location_detection ...`
- `\=` - escaped equals sign
- `\$` - escaped dollar sign
- `( ... )` - spaces added around parentheses, breaking the command substitution syntax

This is **invalid bash** because `$(...)` syntax requires no spaces and no backslash escaping when used in command substitution context.

## Root Cause Analysis

### Primary Root Cause: Over-Aggressive Escaping by Bash Tool

The Bash tool is applying shell escaping rules that are **incompatible** with command substitution syntax when commands are passed through the tool's execution pipeline.

**Why this happens:**
1. The Bash tool receives multi-line commands from the LLM
2. The tool attempts to escape special characters for safe shell execution
3. The escaping mechanism treats `$(...)` as special characters that need escaping
4. The result is `\$\(...)` which bash interprets as: "literal dollar sign, literal open paren, function call"
5. Bash then tries to parse `( perform_location_detection ... )` as a command, failing because it expects different syntax

### Secondary Contributing Factor: Multi-line Command Construction

Commands in the markdown files are structured as multi-line bash code blocks:

```bash
source "${CLAUDE_CONFIG:-${HOME}/.config}/.claude/lib/unified-location-detection.sh"

# Perform location detection using unified library
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
```

When the LLM extracts and executes these as single-line commands with `&&` separators, the escaping issue becomes more pronounced.

### Bash Escaping Rules Reference

**Valid bash command substitution syntax:**
```bash
VAR=$(command arg1 arg2)  # Correct - no spaces inside $()
```

**Invalid bash syntax (what tool is producing):**
```bash
VAR\=\$ ( command arg1 arg2 )  # Wrong - escaped chars, spaces in $(...)
```

## Code Examples

### Example 1: /research command (Line 87)
**File**: `/home/benjamin/.config/.claude/commands/research.md:87`

```bash
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
```

**Context**: This line appears immediately after sourcing the unified-location-detection.sh library. The command is designed to be executed as part of a multi-statement bash command.

**Current behavior**: When executed via Bash tool, it becomes:
```bash
LOCATION_JSON\=\$ ( perform_location_detection 'template usage patterns in .claude/docs/' false )
```

### Example 2: /report command (Line 87)
**File**: `/home/benjamin/.config/.claude/commands/report.md:87`

```bash
LOCATION_JSON=$(perform_location_detection "$RESEARCH_TOPIC" "false")
```

**Identical pattern** to /research command, suggesting this is a systematic issue across all commands using the unified library.

### Example 3: /plan command (Line 485)
**File**: `/home/benjamin/.config/.claude/commands/plan.md:485`

```bash
LOCATION_JSON=$(perform_location_detection "$FEATURE_DESCRIPTION" "false")
```

**Same pattern**, different variable name (`$FEATURE_DESCRIPTION` instead of `$RESEARCH_TOPIC`).

### Example 4: /orchestrate command (Line 431)
**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md:431`

```bash
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESCRIPTION" "false")
```

**Same pattern**, different variable name (`$WORKFLOW_DESCRIPTION`).

### Example 5: Unified Location Detection Library (Lines 286-313)
**File**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:313`

The `perform_location_detection()` function itself is correctly implemented and has no issues. The problem occurs when **calling** this function via the Bash tool.

```bash
perform_location_detection() {
  local workflow_description="$1"
  local force_new_topic="${2:-false}"

  # Function implementation...
  # Returns JSON output to stdout
}
```

## Technical Analysis

### Bash Tool Execution Pipeline

The Bash tool's execution flow appears to be:

1. **Receive command string** from LLM
2. **Apply shell escaping** to protect against injection attacks
3. **Execute via eval or similar mechanism**
4. **Return output** to LLM

The issue is in **step 2** - the escaping mechanism doesn't distinguish between:
- Characters that need escaping in the **outer shell** (where eval runs)
- Characters that should remain **unescaped inside command substitution** `$(...)`

### Why Command Substitution Breaks

Command substitution `$(...)` creates a **subshell context** where:
- The inner command runs in its own process
- The output replaces the `$(...)` expression
- Escaping rules **should not apply** to the interior of `$(...)` at the outer shell level

**What's happening:**
```bash
# Original (correct):
LOCATION_JSON=$(perform_location_detection "topic" "false")

# After tool escaping (incorrect):
LOCATION_JSON\=\$ ( perform_location_detection 'topic' false )
#            ↑  ↑ ↑                                       ↑
#            |  | |                                       |
#            |  | +- Space added, breaks $() syntax -----+
#            |  +- Dollar sign escaped (treats as literal)
#            +- Equals sign escaped (unnecessary)
```

### Comparison with Working Commands

Commands that **do work** through the Bash tool use simpler patterns:

```bash
# Simple command (works fine)
cd /home/benjamin/.config/.claude/specs

# Simple variable assignment (works fine)
SUBTOPICS=("topic1" "topic2" "topic3")

# Command substitution WITHOUT chaining (often works)
TOPIC_DIR=$(dirname "$PATH")
```

The failures occur specifically when:
1. Command substitution is used `$(...)`
2. Combined with `&&` chaining
3. Inside multi-line bash code blocks from markdown
4. With complex function calls (multiple arguments, quotes)

## Recommendations

### Recommendation 1: Use Temporary Script Files (Highest Priority)

**Solution**: Write bash code blocks to temporary script files, then execute the script file.

**Implementation**:
```bash
# Instead of:
Bash(source lib.sh && LOCATION_JSON=$(perform_location_detection "topic" "false"))

# Do this:
SCRIPT=$(mktemp)
cat > "$SCRIPT" << 'EOF'
source /path/to/unified-location-detection.sh
LOCATION_JSON=$(perform_location_detection "topic" "false")
echo "$LOCATION_JSON"
EOF
bash "$SCRIPT"
rm "$SCRIPT"
```

**Benefits**:
- Eliminates escaping issues entirely
- Allows complex multi-line bash scripts
- Standard bash execution (no tool interference)
- Easy to debug (can preserve script file for inspection)

**Tradeoffs**:
- Slightly more verbose
- Requires cleanup (rm temporary file)

### Recommendation 2: Split Commands into Multiple Sequential Bash Calls

**Solution**: Execute sourcing and function call as separate Bash tool invocations.

**Implementation**:
```bash
# Step 1: Source library and export function
Bash(source /path/to/unified-location-detection.sh && export -f perform_location_detection)

# Step 2: Call function in separate invocation
Bash(perform_location_detection "topic" "false")
```

**Benefits**:
- Avoids command substitution in chained commands
- Simpler escaping requirements per call
- Easier to debug step-by-step

**Tradeoffs**:
- Exported functions don't always work across Bash tool invocations
- May require persistent shell session (Bash tool architecture dependent)
- Less atomic (separate operations)

### Recommendation 3: Refactor Unified Library to Accept Direct Execution

**Solution**: Modify unified-location-detection.sh to work as a standalone script.

**Implementation**:
```bash
# unified-location-detection.sh (modified)
#!/usr/bin/env bash

# If executed directly (not sourced), run detection
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  perform_location_detection "$1" "$2"
  exit $?
fi

# Otherwise, define functions for sourcing (existing behavior)
perform_location_detection() {
  # ... existing implementation ...
}
```

**Usage**:
```bash
# Instead of sourcing + calling function:
Bash(/path/to/unified-location-detection.sh "topic" "false")
```

**Benefits**:
- Simplest invocation pattern
- No command substitution needed
- Library remains sourceable for other use cases

**Tradeoffs**:
- Requires library modification
- Need to ensure backward compatibility
- May complicate library testing

### Recommendation 4: Create Wrapper Script for Location Detection

**Solution**: Create a simple wrapper script that handles the source + call pattern.

**Implementation**:
Create `/home/benjamin/.config/.claude/lib/detect-location.sh`:
```bash
#!/usr/bin/env bash
# Wrapper script for unified location detection
# Usage: detect-location.sh "workflow description" [force_new_topic]

source "$(dirname "$0")/unified-location-detection.sh"
perform_location_detection "$1" "${2:-false}"
```

**Usage in commands**:
```bash
# Instead of:
source lib.sh && LOCATION_JSON=$(perform_location_detection ...)

# Use:
LOCATION_JSON=$(/path/to/detect-location.sh "topic" "false")
```

**Benefits**:
- Keeps existing library architecture
- Simple wrapper (6 lines of code)
- No changes to existing library
- Easy to invoke from Bash tool

**Tradeoffs**:
- One additional file to maintain
- Need to ensure wrapper is executable

### Recommendation 5: Update All 4 Affected Commands Consistently

**Solution**: Once a fix is chosen, apply it to all 4 affected commands.

**Affected files**:
1. `/home/benjamin/.config/.claude/commands/research.md:87`
2. `/home/benjamin/.config/.claude/commands/report.md:87`
3. `/home/benjamin/.config/.claude/commands/plan.md:485`
4. `/home/benjamin/.config/.claude/commands/orchestrate.md:431`

**Implementation checklist**:
- [ ] Update /research command
- [ ] Update /report command
- [ ] Update /plan command
- [ ] Update /orchestrate command
- [ ] Test each command individually
- [ ] Test commands in sequence (workflow integration)
- [ ] Update documentation with new pattern

**Benefits**:
- Consistent behavior across all commands
- Easier to maintain and debug
- Prevents confusion from mixed patterns

## References

### Source Files
- `/home/benjamin/.config/.claude/commands/research.md` - Failing command implementation
- `/home/benjamin/.config/.claude/commands/report.md` - Same pattern
- `/home/benjamin/.config/.claude/commands/plan.md` - Same pattern
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Same pattern
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Library being called
- `/home/benjamin/.config/.claude/TODO4.md` - Error output and debugging notes

### Bash Documentation
- Command substitution: `help command-substitution` or `man bash` (search for "Command Substitution")
- Escaping rules: `man bash` (search for "QUOTING")
- Function exports: `help export` and `help declare`

### Related Patterns
- **Behavioral Injection Pattern**: Commands should delegate to agents, not execute complex bash directly
- **Verification and Fallback Pattern**: All file operations require verification checkpoints
- **Hierarchical Agent Architecture**: Context passing via metadata extraction

### Error Context
The error in TODO4.md (lines 30-45) shows the exact escaping failure:
```
LOCATION_JSON\=\$ ( perform_location_detection 'template usage patterns in .claude/docs/' false )
```

This escaped syntax is the smoking gun proving the Bash tool's escaping mechanism is the root cause.
