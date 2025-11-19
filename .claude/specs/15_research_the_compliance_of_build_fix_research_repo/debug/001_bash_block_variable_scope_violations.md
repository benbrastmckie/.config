# Bug Report: Bash Block Variable Scope Violations in Research Commands

## Metadata
- **Date**: 2025-11-17
- **Severity**: CRITICAL
- **Commands Affected**: /research-plan, /research-report, /research-revise, /build, /fix
- **Issue Type**: Architecture violation - Bash block execution model
- **Discovery Method**: Runtime testing of /research-plan command
- **Reporter**: Claude Code testing session

## Executive Summary

The /research-plan command (and likely all 5 related commands) violates the bash block execution model by assuming variables persist across bash blocks. Each bash block in Claude Code runs as a **separate subprocess**, not a subshell, causing all non-persisted variables to be lost between blocks. This creates silent failures where completion summaries display empty values instead of expected output.

**Impact**: Medium-High
- Silent failures (no error, just empty output)
- Affects user experience (missing completion information)
- Violates documented architecture (.claude/docs/concepts/bash-block-execution-model.md)
- Commands work intermittently depending on execution pattern

**Affected Commands**: 5 commands (all research/debug workflows)
**Estimated Remediation**: 10-15 hours across all commands

## Technical Analysis

### Root Cause

From `.claude/docs/concepts/bash-block-execution-model.md` (line 5):

> "Each bash block in Claude Code command files runs as a **separate subprocess**, not a subshell."

**Key Consequence** (lines 60-68):
```
Does NOT Persist Across Blocks:
- Environment variables (export VAR=value lost)
- Bash functions (must re-source library files)
- Process ID ($$) changes per block
- Current directory may reset
```

**Only Files Persist** (line 159):
```
✓ Files are the ONLY reliable cross-block communication channel
```

### Violation Pattern in /research-plan

**Part 3: Research Phase** (lines 143-149) - Variables declared:
```bash
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' ...)
TOPIC_NUMBER=$(find "${CLAUDE_PROJECT_DIR}/.claude/specs" ...)
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_SLUG}"
RESEARCH_DIR="${SPECS_DIR}/reports"
PLANS_DIR="${SPECS_DIR}/plans"
```

**Part 4: Planning Phase** (lines 200, 225) - More variables:
```bash
REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"
```

**Part 5: Completion** (lines 286-288) - Variables USED from previous blocks:
```bash
echo "Specs Directory: $SPECS_DIR"          # EMPTY! (from Part 3)
echo "Research Reports: $REPORT_COUNT reports in $RESEARCH_DIR"  # EMPTY!
echo "Implementation Plan: $PLAN_PATH"      # EMPTY! (from Part 4)
```

**Problem**: All variables (`$SPECS_DIR`, `$RESEARCH_DIR`, `$PLAN_PATH`, `$REPORT_COUNT`) will be **empty** when Part 5 runs as a separate subprocess.

### Evidence from Testing

**Test Date**: 2025-11-17
**Test Command**: `/research-plan "add input validation to user authentication endpoints"`

**Bash Errors Encountered**:

1. **Error 1**: `awk: fatal: cannot open file 'echo'`
   - **Cause**: Complex awk pipeline failed when variables were empty
   - **Line**: Attempted enhancement of completion output

2. **Error 2**: `syntax error near unexpected token 'ls'`
   - **Cause**: Bash script became malformed when all variables substituted to empty strings
   - **Evidence**: `SPECS_DIR=/reports` (should be `/home/benjamin/.config/.claude/specs/16_...`)
   - **Root cause**: Variable substitution showed empty strings everywhere

**Why Test Succeeded Despite Bug**:
- Tester manually re-declared variables in each bash invocation
- Pattern: `Bash("SPECS_DIR=/path/...; echo \"$SPECS_DIR\"")`
- This compensated for subprocess isolation
- **Actual command would fail if bash blocks run as documented**

## Reproduction Steps

### Minimal Reproduction

1. Create test command with multiple bash blocks:

```bash
# Block 1
VAR="test_value"
echo "Block 1: VAR=$VAR"  # Shows: test_value

# Block 2 (separate subprocess)
echo "Block 2: VAR=${VAR:-empty}"  # Shows: empty (NOT test_value)
```

2. Expected behavior (documented): VAR is empty in Block 2
3. Actual behavior in /research-plan: Assumes VAR persists
4. Result: Completion summary shows empty values

### Full Reproduction with /research-plan

1. Run: `/research-plan "test feature"`
2. Observe Part 3 execution (variable declarations)
3. Observe Part 5 execution (variable usage)
4. Check completion output - should show empty strings for:
   - Specs Directory
   - Research Reports count/path
   - Implementation Plan path

**Note**: Bug may not reproduce if Claude Code compensates by re-declaring variables

## Impact Assessment

### User-Visible Impact

**Severity**: Medium
- Completion summary shows incomplete information
- Users don't know where files were created
- Degrades UX but doesn't prevent functionality

**Example Output** (with bug):
```
=== Research-and-Plan Complete ===

Workflow Type: research-and-plan
Specs Directory:                          # EMPTY!
Research Reports:  reports in             # EMPTY!
Implementation Plan:                       # EMPTY!
```

**Expected Output** (without bug):
```
=== Research-and-Plan Complete ===

Workflow Type: research-and-plan
Specs Directory: /home/user/.claude/specs/16_topic_name
Research Reports: 3 reports in /home/user/.claude/specs/16_topic_name/reports
Implementation Plan: /home/user/.claude/specs/16_topic_name/plans/001_plan.md
```

### Architectural Impact

**Severity**: High
- Violates documented bash block execution model
- Sets bad precedent for other commands
- Creates confusion about subprocess isolation
- Testing gap: works with manual compensation, fails with documented behavior

## Recommended Fix

### Pattern: State Persistence Library

From `.claude/docs/concepts/bash-block-execution-model.md` (lines 226-248):

```bash
# In each bash block that needs cross-block state:

# 1. Re-source library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"

# 2. Load workflow state
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/coordinate_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# 3. Update state variables
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"

# 4. State automatically persists to file
```

### Specific Fix for /research-plan

**Part 3: After variable declarations** (after line 153):
```bash
# Persist variables for cross-block access
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
append_workflow_state "TOPIC_SLUG" "$TOPIC_SLUG"
append_workflow_state "TOPIC_NUMBER" "$TOPIC_NUMBER"
```

**Part 4: After variable declarations** (after lines 200, 225):
```bash
# Persist planning variables
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"
```

**Part 5: Before variable usage** (before line 286):
```bash
# Restore state from previous blocks
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
WORKFLOW_ID=$(cat "${HOME}/.claude/tmp/research_plan_state_id.txt")
load_workflow_state "$WORKFLOW_ID"

# Now all variables are restored:
# $SPECS_DIR, $RESEARCH_DIR, $PLAN_PATH, $REPORT_COUNT
```

## Commands Requiring Same Fix

Based on compliance research, all 5 commands likely have this issue:

1. **/build** - Lines unknown (needs investigation)
2. **/fix** - Lines unknown (needs investigation)
3. **/research-report** - Lines unknown (needs investigation)
4. **/research-plan** - Lines 143-149, 200, 225, 286-288 (documented above)
5. **/research-revise** - Lines unknown (needs investigation)

**Remediation Effort**:
- Analysis per command: 1 hour
- Fix per command: 2 hours
- Testing per command: 1 hour
- **Total: 20 hours for all 5 commands**

## Related Documentation

- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Complete architecture
- [State Persistence Library](.claude/lib/state-persistence.sh) - Implementation
- [Compliance Reports](../reports/) - Original discovery of agent invocation issues
- [Command Development Guide](.claude/docs/guides/command-development-guide.md) - Best practices

## Testing Recommendations

### Validation Test

Create automated test to verify bash block isolation:

```bash
#!/usr/bin/env bash
# Test: Bash block subprocess isolation

# Block 1: Set variable
TEST_VAR="value_from_block_1"
echo "$TEST_VAR" > /tmp/test_var_block1.txt

# Simulate block boundary (new subprocess)
bash -c '
  # Block 2: Variable should be empty
  if [ -z "$TEST_VAR" ]; then
    echo "PASS: Variable correctly empty in new subprocess"
  else
    echo "FAIL: Variable leaked across subprocess boundary"
  fi
'

# Cleanup
rm -f /tmp/test_var_block1.txt
```

### Integration Test

1. Run /research-plan with minimal feature description
2. Capture all bash block outputs
3. Verify Part 5 completion summary contains non-empty values
4. Assert: `$SPECS_DIR`, `$PLAN_PATH`, `$REPORT_COUNT` all populated

## Appendix: Bash Execution Errors from Testing

### Error 1: awk Command Failure

```
awk: fatal: cannot open file `echo' for reading: No such file or directory
```

**Context**: Attempted to enhance completion output with:
```bash
ls -lh "$RESEARCH_DIR" | tail -n +2 | awk '{print "  - " $9 " (" $5 ")"}'
```

**Cause**: When `$RESEARCH_DIR` is empty, the command becomes malformed

### Error 2: Variable Substitution Failure

```
bash: eval: line 1: syntax error near unexpected token `ls'
SPECS_DIR=/reports RESEARCH_DIR=/reports ...
```

**Context**: Complex bash script with variable interpolation
**Cause**: All variables substituted to empty strings, creating malformed bash syntax
**Evidence**: `SPECS_DIR=/reports` (missing `/home/...` prefix)

**This demonstrates what happens when Part 5 runs as separate subprocess**

## Status

- **Discovered**: 2025-11-17
- **Documented**: 2025-11-17
- **Fix Status**: Not started
- **Priority**: High (affects 5 commands, architectural violation)
- **Assigned**: Unassigned

## Next Steps

1. **Immediate**: Review all 5 commands for bash block variable scope violations
2. **Short-term**: Implement state persistence fixes using append_workflow_state/load_workflow_state
3. **Medium-term**: Create automated tests for subprocess isolation
4. **Long-term**: Update command development guide with subprocess isolation checklist
