# Plan Command Failure Root Cause Analysis

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Plan Command Failure Root Cause - Library Path Resolution
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The plan command failure was caused by the BASH_SOURCE-based SCRIPT_DIR pattern failing in Claude Code's bash block execution model, where bash blocks run as separate subprocesses without script metadata. The error output in plan_output.md shows the failure occurred BEFORE the fix was applied in spec 732. Standard changes did not cause this issue - they exposed a pre-existing architectural incompatibility between traditional bash script patterns and Claude Code's subprocess execution model. The fix (inline git-based CLAUDE_PROJECT_DIR detection) aligns perfectly with new standards and eliminates the bootstrap paradox.

## Findings

### Finding 1: Exact Failure Mechanism

**Error Location**: `/home/benjamin/.config/.claude/specs/plan_output.md:240-243`

**Error Message**:
```
/run/current-system/sw/bin/bash: line 164:
/home/benjamin/.config/../lib/detect-project-dir.sh: No such file or directory
ERROR: Failed to detect project directory
DIAGNOSTIC: Check that detect-project-dir.sh exists at: /home/benjamin/.config/../lib/
```

**Failed Code** (plan.md:27-28, BEFORE fix b60a03f9):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$SCRIPT_DIR/../lib/detect-project-dir.sh" 2>&1; then
```

**Root Cause Analysis**:
1. `BASH_SOURCE[0]` returns empty string in Claude Code bash blocks
2. `dirname ""` returns `.` (current directory)
3. `cd .` stays in current working directory (/home/benjamin/.config)
4. `$SCRIPT_DIR/../lib/` resolves to `/home/benjamin/.config/../lib/` → `/home/benjamin/lib/`
5. Expected path: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh`
6. Actual path attempted: `/home/benjamin/lib/detect-project-dir.sh` (WRONG)

**Why BASH_SOURCE Fails**:
According to `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:683-736`:
- Claude Code executes bash blocks as separate subprocesses, not script files
- `BASH_SOURCE[0]` requires execution as `bash script.sh` with script metadata
- Bash blocks execute more like `bash -c 'commands'` where BASH_SOURCE is undefined
- This is Anti-Pattern 5 (documented after fix was implemented)

### Finding 2: Timeline - Error Occurred BEFORE Fix Was Applied

**Git History Analysis**:
- Error captured in: plan_output.md (showing BEFORE state)
- Fix committed in: b60a03f9 (2025-11-16) "feat(732): complete Phase 1"
- Current state: plan.md now uses inline git-based detection (AFTER fix)

**Evidence**:
```bash
# BEFORE fix (plan_output.md shows this code):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$SCRIPT_DIR/../lib/detect-project-dir.sh" 2>&1; then

# AFTER fix (current plan.md:27-50):
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
```

### Finding 3: Did Standards Changes Cause This Failure?

**Answer: NO - Standards Changes EXPOSED Pre-Existing Issue**

**Evidence**:
1. **Library File Exists**: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh` (1540 bytes, Oct 30 08:44)
2. **Problem is Path Resolution**: Not file absence or standards changes
3. **BASH_SOURCE Pattern Never Worked in Claude Code**: This pattern was architecturally incompatible from the start
4. **Standards Changes Created Visibility**: New standards documentation revealed why the pattern failed

**From Implementation Summary** (`732_plan_outputmd_in_order_to_identify_the_root_cause/IMPLEMENTATION_SUMMARY.md:14`):
> "Root Cause: Claude Code executes bash blocks as separate subprocesses without preserving script metadata, causing BASH_SOURCE[0] to return empty."

This is an **architectural constraint**, not a regression from standards changes.

### Finding 4: How Fix Aligns with New Standards

**Standard 13 Specification** (originally from coordinate-state-management.md:120-126):
```bash
# Standard 13: CLAUDE_PROJECT_DIR detection for SlashCommand context
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
```

**Implemented Fix** (plan.md:27-50 after b60a03f9):
```bash
# STANDARD 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
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
```

**Alignment Analysis**:
- ✓ Uses git-based detection (Standard 13 compliant)
- ✓ Adds robust fallback for non-git environments (enhancement over basic standard)
- ✓ Validates detection succeeded before proceeding (fail-fast pattern)
- ✓ Exports CLAUDE_PROJECT_DIR for use by libraries (standard requirement)
- ✓ Eliminates bootstrap paradox (need library to find library path)

**From bash-block-execution-model.md:703-731**:
The fix is documented as the **correct pattern** (Anti-Pattern 5 fix), showing perfect alignment with architectural standards.

### Finding 5: Scope of Issue - Other Affected Commands

**From bash_source_audit.md** (created in Phase 2):
Commands still using broken BASH_SOURCE pattern:
1. `/implement` - `.claude/commands/implement.md:21-22`
2. `/expand` - `.claude/commands/expand.md:80-81`
3. `/collapse` - `.claude/commands/collapse.md:82-83`

**Status**:
- `/plan` - ✓ FIXED in spec 732
- Other commands - Documented for future fix (spec 733 proposed)

### Finding 6: Bootstrap Paradox Eliminated

**The Problem**:
- Need `detect-project-dir.sh` to get `CLAUDE_PROJECT_DIR`
- Need `CLAUDE_PROJECT_DIR` to source `detect-project-dir.sh`
- BASH_SOURCE can't help because it's empty in bash blocks

**The Solution**:
Inline the git-based detection logic directly in Phase 0, eliminating the circular dependency. This is not just a workaround - it's the architecturally correct approach for Claude Code's execution model.

## Recommendations

### 1. Understanding: This Was Not a Regression

**Recognition**: The error in plan_output.md shows the BEFORE state, not a new failure. The BASH_SOURCE pattern never worked correctly in Claude Code's subprocess execution model.

**Implication**: Standards documentation improvements (like bash-block-execution-model.md Anti-Pattern 5) help prevent this mistake in future commands, not cause existing issues.

### 2. Current Fix is Optimal and Standards-Compliant

**Assessment**: The inline git-based CLAUDE_PROJECT_DIR detection implemented in spec 732 is:
- ✓ Architecturally correct for Claude Code
- ✓ Standard 13 compliant
- ✓ More robust than basic standard (adds fallback)
- ✓ Eliminates bootstrap paradox
- ✓ Provides clear error messages

**Action**: No changes needed to the fix itself.

### 3. Complete Migration of Remaining Commands

**Next Steps**:
1. Apply same inline bootstrap pattern to `/implement`, `/expand`, `/collapse`
2. Follow spec 732 as reference implementation
3. Test each command from various working directories
4. Document in bash-block-execution-model.md examples

**Reference**: Spec 733 (proposed in IMPLEMENTATION_SUMMARY.md:142)

### 4. Documentation Serves as Preventive Measure

**Value of Anti-Pattern 5**:
- Educates future command developers
- Prevents BASH_SOURCE mistakes in new commands
- Explains WHY pattern fails (subprocess model)
- Provides correct alternative (git-based inline detection)

**Current Status**: Documentation complete and accurate.

### 5. Testing Strategy for Subprocess-Based Commands

**Validation Requirements**:
- Test from project root
- Test from subdirectories
- Test from outside project (expect graceful failure)
- Verify library sourcing succeeds
- Confirm state persistence across bash blocks

**Reference**: Testing section in `732_plan_outputmd_in_order_to_identify_the_root_cause/IMPLEMENTATION_SUMMARY.md:88-102`

## References

**Error Source**:
- `/home/benjamin/.config/.claude/specs/plan_output.md:240-247` - Original error output

**Code Analysis**:
- `/home/benjamin/.config/.claude/commands/plan.md:27-50` - Current (fixed) implementation
- Git commit b60a03f9^:27-28 - BEFORE fix (broken BASH_SOURCE pattern)
- Git diff b60a03f9 - Exact changes showing fix

**Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:683-736` - Anti-Pattern 5 documentation
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md:2881` - Bootstrap pattern explanation
- `/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/IMPLEMENTATION_SUMMARY.md:1-173` - Complete fix documentation

**Related Research**:
- `/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/001_topic1.md:1-210` - Initial root cause analysis
- `/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/003_topic3.md:1-590` - Comprehensive refactor design
- `/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md` - Audit of affected commands

**Standards References**:
- Standard 13: CLAUDE_PROJECT_DIR detection (git-based)
- Standard 0: Absolute paths only
- Standard 15: Library sourcing order
