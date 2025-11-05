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

## Large Bash Block Transformation

### Problem: Code Transformation in Large Markdown Bash Blocks

When bash blocks in command markdown files exceed approximately 400 lines, Claude AI transforms bash code during extraction, causing syntax errors.

**Root Cause**: Claude AI's markdown processing pipeline escapes special characters (including `!`) when extracting large bash blocks, transforming valid bash syntax into invalid syntax.

**Error Pattern**:
```bash
# Valid source code in coordinate.md:
result="${!var_name}"                    # Indirect variable reference

# After transformation (400+ line blocks):
result="${\!var_name}"                   # Backslash added, causes error

# Result:
bash: ${\\!varname}: bad substitution
```

### Symptoms

**Direct indicators**:
- `bash: ${\\!varname}: bad substitution` errors
- `bash: !: command not found` errors despite `set +H`
- Errors only occur with large bash blocks (400+ lines)
- Same code works perfectly in small blocks (<200 lines)

**Affected patterns**:
- Indirect variable references: `${!varname}`
- Array key expansion: `${!array[@]}`
- Other bash special characters in large blocks

### Detection Test

To confirm this issue vs other bash problems:

```bash
# Test 1: Small block (50 lines) with indirect reference
bash <<'EOF'
TEST_VAR="hello"
var_name="TEST_VAR"
result="${!var_name}"
echo "$result"
EOF
# Expected: "hello" (works correctly)

# Test 2: Measure your bash block size
awk '/^```bash$/,/^```$/ {count++} END {print count-2, "lines"}' command.md
# If >400 lines and you see transformation errors → size is the issue
```

### Solution: Split Large Bash Blocks

**Split bash blocks into chunks of <200 lines each**, propagating state via `export`:

#### Before (Fails - 402 lines)

```markdown
**EXECUTE NOW**: USE the Bash tool to execute:

\```bash
# 402-line Phase 0 initialization block
# ... lots of setup code ...
WORKFLOW_SCOPE="research-only"
result="${!WORKFLOW_SCOPE}"  # ← Transformed and breaks
# ... more code ...
\```
```

#### After (Works - 3 blocks of 176, 168, 77 lines)

```markdown
**EXECUTE NOW - Step 1: Project Setup**

\```bash
# Block 1: Project detection and library loading (176 lines)
WORKFLOW_SCOPE="research-only"
export WORKFLOW_SCOPE  # ← Export for next block
\```

**EXECUTE NOW - Step 2: Function Definitions**

\```bash
# Block 2: Function verification (168 lines)
# WORKFLOW_SCOPE available from previous block
result="${!WORKFLOW_SCOPE}"  # ← Works correctly in small block
\```

**EXECUTE NOW - Step 3: Completion**

\```bash
# Block 3: Final initialization (77 lines)
echo "Setup complete: $WORKFLOW_SCOPE"
\```
```

### Key Implementation Details

**State Propagation**:
- Export variables at end of each block: `export VAR_NAME`
- Export functions for use in later blocks: `export -f function_name`
- Arrays cannot be exported directly (use helper functions)

**Split Points**:
- Choose logical boundaries (project setup, library loading, path calculation)
- Aim for <200 lines per block (well below 400-line threshold)
- Document what each block does in the header

**Block Headers**:
```markdown
**EXECUTE NOW - Step N: Clear Description**

USE the Bash tool to execute the following (Step N of M):
```

### Real-World Example

**Command**: `/coordinate` (`.claude/commands/coordinate.md`)
**Issue**: 402-line Phase 0 bash block caused transformation errors
**Solution**: Split into 3 blocks (176, 168, 77 lines)
**Result**: All transformation errors eliminated, 47/47 tests pass
**Commit**: `3d8e49df` - fix(coordinate): split Phase 0 into smaller bash blocks

**Before/After Metrics**:
- Errors before: 3-5 transformation errors per run
- Errors after: 0 errors
- Block sizes: 402 lines → 176 + 168 + 77 lines
- Functionality: Unchanged (state propagates via exports)

### Prevention

When writing command files:

1. **Monitor bash block sizes** during development
2. **Split proactively** if approaching 300 lines (buffer below threshold)
3. **Test with indirect references** (`${!var}`) to catch transformation early
4. **Use logical boundaries** for splits (setup, execution, cleanup)

### Why This Works

1. **Avoids transformation threshold** - Smaller blocks processed without escaping
2. **Maintains functionality** - State propagates between blocks via exports
3. **No performance penalty** - Blocks execute sequentially, same total time
4. **Better organization** - Logical splits improve readability

### Related Issues

This is distinct from:
- **Command substitution escaping** - Different root cause (see previous section)
- **Bash history expansion** - Not related to `!` in `${!var}` patterns
- **Agent context limitations** - This affects command files, not agent prompts

## Related Documentation

- [Command Development Guide](../guides/command-development-guide.md) - Best practices for command development
- [Agent Development Guide](../guides/agent-development-guide.md) - Guidelines for creating specialized agents
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - How to invoke agents with context
- [Library API Reference](../reference/library-api.md) - API documentation for .claude/lib/ utilities
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Architecture requirements and best practices
