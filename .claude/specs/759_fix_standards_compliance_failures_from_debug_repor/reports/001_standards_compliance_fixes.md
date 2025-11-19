# Standards Compliance Fixes Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Fix standards compliance failures from debug report
- **Report Type**: codebase analysis

## Executive Summary

Research into the debug report at `/home/benjamin/.config/.claude/specs/758_research_all_commands_and_their_supporting_infrast/debug/001_standards_compliance_failures.md` identified 4 distinct issues: a test script bug causing false failures with grep integer expressions, and 3 command files missing required standards compliance markers. The test script bug (Priority 1) causes multiline output from `grep -c` with alternation patterns, resulting in "integer expression expected" errors. Three command files require updates: optimize-claude.md and setup.md need imperative language patterns (Standard 0), while revise.md needs project directory detection (Standard 13). Total estimated fix time is approximately 40 minutes with low implementation risk.

## Findings

### 1. Test Script Bug Analysis (Priority 1)

**File**: `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`

**Root Cause**: The test script uses `grep -c` with alternation patterns (`\|`) which can produce multiline output instead of a single count. This causes bash integer comparison failures.

**Evidence (lines 81-83)**:
```bash
local must_count=$(grep -c "YOU MUST\|MUST\|WILL\|SHALL" "$cmd_file" 2>/dev/null || echo "0")
local execute_now=$(grep -c "EXECUTE NOW" "$cmd_file" 2>/dev/null || echo "0")
local role_statement=$(grep -c "YOU ARE EXECUTING\|YOUR ROLE" "$cmd_file" 2>/dev/null || echo "0")
```

When `grep -c` with alternation (`\|`) produces output like:
```
0
0
```
The comparison `[ "$must_count" -gt 5 ]` fails with "integer expression expected".

**Additional Affected Locations**:
- Lines 110-111 (test_standard_13): `grep -c "CLAUDE_PROJECT_DIR"` and `grep -c "git rev-parse\|\.claude"`
- Line 161 (test_standard_15): `grep -c "^source\|source \"\|source '"`
- Lines 205-206 (test_standard_16): `grep -c "if ! \|if !"` and `grep -c " || \|exit 1"`

**Fix Pattern**: Replace `grep -c "pattern1\|pattern2"` with `grep -E "pattern1|pattern2" | wc -l`

### 2. optimize-claude.md Analysis (Standard 0 Failure)

**File**: `/home/benjamin/.config/.claude/commands/optimize-claude.md`

**Root Cause**: Missing imperative language patterns required by Standard 0. The test requires EITHER:
- Both a role statement AND "EXECUTE NOW" directives, OR
- More than 5 imperative markers (MUST, WILL, SHALL)

**Current State Analysis**:
- Line 1-16: Header and workflow description with no imperative language
- Line 71: "**EXECUTE NOW**: USE the Task tool..." - has EXECUTE NOW but lacks role statement
- Line 147: "**EXECUTE NOW**: USE the Task tool..."
- Line 235: "**EXECUTE NOW**: USE the Task tool..."
- **Missing**: "YOU ARE EXECUTING" or "YOUR ROLE" statement at the start

**Grep Results**:
- Role statements (YOU ARE EXECUTING|YOUR ROLE): 0 matches
- EXECUTE NOW: 3 matches (lines 71, 147, 235)
- Imperative markers (MUST|WILL|SHALL): Minimal matches

**Comparison with Compliant Commands**:
- implement.md (line 10): "**YOU ARE EXECUTING** as the implementation manager."
- debug.md (line 10): "**YOU ARE EXECUTING** as the debug investigator."
- research.md (line 13): "**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher."

### 3. revise.md Analysis (Standard 13 Failure)

**File**: `/home/benjamin/.config/.claude/commands/revise.md`

**Root Cause**: Has bash blocks but lacks project directory detection pattern. Standard 13 requires CLAUDE_PROJECT_DIR detection with git fallback for any command with bash blocks.

**Current State Analysis**:
- Lines 27-41: Bash block for argument parsing without CLAUDE_PROJECT_DIR
- Lines 142-160: Uses relative paths like `find . -path "*/specs/plans/*.md"`
- Lines 79-80: References `${CLAUDE_PROJECT_DIR}` in Task prompts but never sets it

**Grep Results**:
- `grep -c "CLAUDE_PROJECT_DIR"`: 0 matches in bash blocks (only in Task prompts)
- `grep -c "git rev-parse\|\.claude"`: Only matches `.claude` in agent paths

**Standard 13 Reference Pattern** (from implement.md lines 26-46):
```bash
# Standard 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR
```

### 4. setup.md Analysis (Standard 0 Failure)

**File**: `/home/benjamin/.config/.claude/commands/setup.md`

**Root Cause**: Has role statement but uses non-standard execution markers.

**Current State Analysis**:
- Line 11: "YOU ARE EXECUTING AS the /setup command" - has role statement
- Line 19: "[EXECUTION-CRITICAL: Execute this bash block immediately]" - non-standard marker
- Additional phases use "[EXECUTION-CRITICAL: Execute when MODE=...]"

**The Test Expectation**:
```bash
if [ "$role_statement" -gt 0 ] && [ "$execute_now" -gt 0 ]; then
  log_result "PASS" ...
```

**Issue**: The test requires BOTH role statement AND "EXECUTE NOW", but setup.md uses "[EXECUTION-CRITICAL: ...]" instead of "EXECUTE NOW".

**Options**:
1. Change markers in setup.md from "[EXECUTION-CRITICAL: ...]" to "**EXECUTE NOW**: ..."
2. Update test to recognize "[EXECUTION-CRITICAL" as equivalent to "EXECUTE NOW"

Option 1 is recommended for consistency with other commands.

## Recommendations

### 1. Fix Test Script grep Bug (CRITICAL - Do First)

**File**: `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`

**Changes Required**:

**Lines 81-83 (test_standard_0)**:
```bash
# BEFORE:
local must_count=$(grep -c "YOU MUST\|MUST\|WILL\|SHALL" "$cmd_file" 2>/dev/null || echo "0")
local execute_now=$(grep -c "EXECUTE NOW" "$cmd_file" 2>/dev/null || echo "0")
local role_statement=$(grep -c "YOU ARE EXECUTING\|YOUR ROLE" "$cmd_file" 2>/dev/null || echo "0")

# AFTER:
local must_count=$(grep -E "YOU MUST|MUST|WILL|SHALL" "$cmd_file" 2>/dev/null | wc -l)
local execute_now=$(grep -c "EXECUTE NOW" "$cmd_file" 2>/dev/null || echo "0")
local role_statement=$(grep -E "YOU ARE EXECUTING|YOUR ROLE" "$cmd_file" 2>/dev/null | wc -l)
```

**Lines 110-111 (test_standard_13)**:
```bash
# BEFORE:
local has_detection=$(grep -c "CLAUDE_PROJECT_DIR" "$cmd_file" 2>/dev/null || echo "0")
local has_git_detect=$(grep -c "git rev-parse\|\.claude" "$cmd_file" 2>/dev/null || echo "0")

# AFTER:
local has_detection=$(grep -c "CLAUDE_PROJECT_DIR" "$cmd_file" 2>/dev/null || echo "0")
local has_git_detect=$(grep -E "git rev-parse|\.claude" "$cmd_file" 2>/dev/null | wc -l)
```

**Line 161 (test_standard_15)**:
```bash
# BEFORE:
local has_source=$(grep -c "^source\|source \"\|source '" "$cmd_file" 2>/dev/null || echo "0")

# AFTER:
local has_source=$(grep -E "^source|source \"|source '" "$cmd_file" 2>/dev/null | wc -l)
```

**Line 167 (test_standard_15)**:
```bash
# BEFORE:
local has_functions=$(grep -c "sm_init\|sm_transition\|verify_file_created\|handle_state_error" "$cmd_file" 2>/dev/null || echo "0")

# AFTER:
local has_functions=$(grep -E "sm_init|sm_transition|verify_file_created|handle_state_error" "$cmd_file" 2>/dev/null | wc -l)
```

**Lines 205-206 (test_standard_16)**:
```bash
# BEFORE:
local has_if_not=$(grep -c "if ! \|if !" "$cmd_file" 2>/dev/null || echo "0")
local has_pipe_or=$(grep -c " || \|exit 1" "$cmd_file" 2>/dev/null || echo "0")

# AFTER:
local has_if_not=$(grep -E "if ! |if !" "$cmd_file" 2>/dev/null | wc -l)
local has_pipe_or=$(grep -E " \|\| |exit 1" "$cmd_file" 2>/dev/null | wc -l)
```

### 2. Fix optimize-claude.md (Standard 0)

**File**: `/home/benjamin/.config/.claude/commands/optimize-claude.md`

Add role statement after line 1:
```markdown
# /optimize-claude - CLAUDE.md Optimization Command

**YOU ARE EXECUTING** as the CLAUDE.md optimization orchestrator.

**YOUR ROLE**: You MUST analyze CLAUDE.md structure and .claude/docs/ organization, then generate an actionable optimization plan. You WILL execute each phase in sequence without deviation.

Analyzes CLAUDE.md and .claude/docs/ structure to generate an optimization plan using multi-stage agent workflow.
```

### 3. Fix revise.md (Standard 13)

**File**: `/home/benjamin/.config/.claude/commands/revise.md`

Insert CLAUDE_PROJECT_DIR detection at the start of the bash block (lines 27-29), before `ARG1="$1"`:
```bash
```bash
# CRITICAL: Detect project directory (Standard 13)
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
    [ -z "$CLAUDE_PROJECT_DIR" ] && CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
export CLAUDE_PROJECT_DIR

# CRITICAL: Parse arguments
ARG1="$1"
```

### 4. Fix setup.md (Standard 0)

**File**: `/home/benjamin/.config/.claude/commands/setup.md`

Replace "[EXECUTION-CRITICAL: ...]" markers with "**EXECUTE NOW**: ..." for consistency.

**Line 19**:
```markdown
# BEFORE:
[EXECUTION-CRITICAL: Execute this bash block immediately]

# AFTER:
**EXECUTE NOW**: Execute this bash block immediately
```

Apply same change to lines 67, 134, 168, 210, 253, 281 (all phase headers).

### 5. Post-Fix Verification

After applying all fixes, run verification:
```bash
# Test individual commands
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh setup.md
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh optimize-claude.md
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh revise.md

# Full test suite
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh
```

Expected result: 80 tests, 0 failures, 100% compliance rate.

## Implementation Complexity

| Fix | File | Estimated Time | Risk | Dependencies |
|-----|------|----------------|------|--------------|
| grep bug | test_command_standards_compliance.sh | 15 min | Low | None |
| Standard 0 | optimize-claude.md | 10 min | Low | None |
| Standard 13 | revise.md | 10 min | Low | None |
| Standard 0 | setup.md | 5 min | Low | None |

**Total**: ~40 minutes implementation time

**Recommended Order**: Fix test script first to eliminate false failures, then address command files.

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001_fix_standards_compliance_failures_from_d_plan.md](../plans/001_fix_standards_compliance_failures_from_d_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17

## References

- `/home/benjamin/.config/.claude/specs/758_research_all_commands_and_their_supporting_infrast/debug/001_standards_compliance_failures.md` (lines 1-256)
- `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh` (lines 1-302)
- `/home/benjamin/.config/.claude/commands/optimize-claude.md` (lines 1-326)
- `/home/benjamin/.config/.claude/commands/revise.md` (lines 1-777)
- `/home/benjamin/.config/.claude/commands/setup.md` (lines 1-312)
- `/home/benjamin/.config/.claude/commands/implement.md` (lines 1-100, reference pattern)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 1-100, reference pattern)
