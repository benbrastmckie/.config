# Library Sourcing Issue: Function Availability Across Bash Block Boundaries

## Executive Summary

The root cause is **bash execution context isolation across separate code blocks**. In Claude Code's SlashCommand execution model, each ````bash` code block runs in an **isolated bash subprocess**. When the `/coordinate` command sources libraries and verifies functions in STEP 0's bash block, those functions are **not inherited by subsequent bash blocks** (STEP 1, STEP 2, etc.). The "✓ All libraries loaded successfully" message reflects accurate verification within STEP 0's context, but the `detect_workflow_scope` function becomes unavailable when STEP 2 executes in its own fresh bash subprocess.

## Detailed Analysis

### Execution Context Architecture

The `/coordinate` command is structured as a markdown file with 38 separate ````bash` code blocks (verified by `grep -c '```bash' coordinate.md`). Claude Code's execution model treats each bash code block as an **independent subprocess invocation**, similar to running:

```bash
# STEP 0 (lines 526-624)
bash -c "source library-sourcing.sh; verify functions; emit_progress"

# STEP 1 (lines 628-665)
bash -c "WORKFLOW_DESCRIPTION='...'; check for checkpoint; ..."

# STEP 2 (lines 669-695)
bash -c "WORKFLOW_SCOPE=\$(detect_workflow_scope \"...\"); ..."
```

Each subprocess starts with a clean environment, inheriting only:
- **Exported environment variables** (e.g., `CLAUDE_PROJECT_DIR`)
- **No bash functions** (even if exported with `export -f`)
- **No sourced libraries** from previous blocks

### Evidence from Console Output

From `/home/benjamin/.config/.claude/specs/coordinate_output.md`:

**Line 17 (STEP 0):**
```
✓ All libraries loaded successfully
PROGRESS: [Phase 0] - Libraries loaded and verified
```

This verification ran successfully because the check occurred **within the same bash block** where libraries were sourced:

```bash
# Lines 560-562: Source libraries
if ! source_required_libraries "dependency-analyzer.sh" ...; then
  exit 1
fi

# Lines 564: Success message
echo "✓ All libraries loaded successfully"

# Lines 576-588: Verification (same subprocess)
for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! command -v "$func" >/dev/null 2>&1; then
    MISSING_FUNCTIONS+=("$func")
  fi
done
```

**Line 26-27 (STEP 2):**
```
/run/current-system/sw/bin/bash: line 82: detect_workflow_scope: command not found
```

This error occurred because STEP 2 executed in a **new bash subprocess** that never sourced the libraries:

```bash
# Line 670: Attempt to call function (new subprocess, no libraries loaded)
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Line 42 (After Manual Fix):**
```
Workflow: research-and-plan → Phases 0,1,2
```

The manual fix worked because explicit sourcing was added to STEP 2's bash block, making the function available within that specific subprocess.

### Library-Sourcing.sh Analysis

File: `/home/benjamin/.config/.claude/lib/library-sourcing.sh`

**Key observations:**

1. **Lines 42-109**: The `source_required_libraries()` function correctly sources all libraries
2. **Lines 85-96**: Each library is sourced with error checking
3. **Line 94**: Uses `source "$lib_path"` (correct bash syntax)
4. **Returns 0** if all libraries source successfully

The library-sourcing implementation is **correct and functioning as designed**. The issue is not with how libraries are sourced, but with **when and where** they remain available.

### Workflow-Detection.sh Analysis

File: `/home/benjamin/.config/.claude/lib/workflow-detection.sh`

**Critical section (lines 127-130):**

```bash
# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f detect_workflow_scope
  export -f should_run_phase
fi
```

**Analysis:**

1. **Line 127**: Conditional check - only exports if library is sourced (not executed directly)
2. **Lines 128-129**: Uses `export -f` to export bash functions
3. **Purpose**: Makes functions available to **child processes of the current shell**

**Why this doesn't solve the issue:**

Bash's `export -f` mechanism makes functions available to **child processes** launched from the current shell (e.g., via `bash -c` or executing scripts). However, it does **NOT** make functions available to:
- **Sibling processes** (parallel bash invocations)
- **Subsequent independent bash invocations** by Claude Code's execution model
- **New shells started by the parent process** (Claude Code) that didn't inherit from the sourcing shell

The `export -f` is effective for traditional bash script execution (parent script sources library, then spawns child scripts), but **ineffective** for Claude Code's markdown-based multi-block execution model.

### Bash Scoping Analysis

**Line 10 of workflow-detection.sh:**
```bash
set -euo pipefail
```

**Impact:**
- `set -e`: Exit on error (good for fail-fast)
- `set -u`: Exit on undefined variable (prevents silent failures)
- `set -o pipefail`: Pipeline fails if any command fails

**Not a contributing factor**: These settings affect error handling within the library, but don't impact function availability across process boundaries.

## Root Cause

The root cause is a **architectural mismatch** between:

1. **Claude Code's execution model**: Each bash code block runs in an isolated subprocess
2. **Bash function availability**: Functions sourced in one subprocess are not available in subsequent subprocesses
3. **Verification assumption**: STEP 0 verification confirms functions exist in its context, but doesn't guarantee availability in future contexts

The verification logic is **accurate but insufficient**:
- ✅ Correctly verifies functions are defined after sourcing
- ❌ Cannot verify functions will be available in subsequent bash blocks
- ❌ No mechanism to persist bash functions across execution boundaries

## Proposed Solutions

### Solution 1: Re-source Libraries in Each Bash Block (Recommended)

**Approach**: Add library sourcing to every bash block that needs library functions.

**Implementation**:
```bash
# At the start of STEP 2 (and every other step)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries "dependency-analyzer.sh" "workflow-detection.sh" "unified-logger.sh" || exit 1

WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
```

**Pros:**
- ✅ Guaranteed function availability in each block
- ✅ No dependency on Claude Code's execution model
- ✅ Explicit and easy to debug
- ✅ Works with bash's `set -euo pipefail` (fails fast if library missing)

**Cons:**
- ❌ Repetitive code (need to source in ~38 bash blocks)
- ❌ Slight performance overhead (re-sourcing same files)
- ❌ Maintenance burden (must remember to add sourcing to new blocks)

**Optimization**: Only re-source in blocks that actually call library functions (not all 38 blocks need it).

### Solution 2: Consolidate Into Single Bash Block

**Approach**: Merge all STEPs into one continuous bash script within a single code block.

**Implementation**:
```bash
# Single mega-block containing STEP 0 through STEP 7
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries ...

# STEP 0: Verify libraries
# STEP 1: Parse arguments
# STEP 2: Detect workflow scope
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")
# ... all remaining steps ...
```

**Pros:**
- ✅ Source libraries once, use everywhere
- ✅ Eliminates subprocess boundary issues
- ✅ More efficient (single bash invocation)
- ✅ Easier to maintain variable state across steps

**Cons:**
- ❌ Loses Claude Code's incremental execution feedback (no progress between steps)
- ❌ Harder to debug (single large block vs. isolated steps)
- ❌ All-or-nothing execution (can't stop/resume between steps as easily)
- ❌ May hit Claude Code limits on single bash block size

**Verdict**: Not recommended for multi-agent orchestration where incremental progress visibility is valuable.

### Solution 3: Create Wrapper Script with Persistent Environment

**Approach**: Generate a temporary bash script that sources libraries once, then executes all commands with persistent environment.

**Implementation**:
```bash
# STEP 0: Generate wrapper script
cat > /tmp/coordinate-wrapper-$$.sh <<'EOF'
#!/usr/bin/env bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries ... || exit 1

# Export all library functions
export -f detect_workflow_scope
export -f should_run_phase
# ... all other functions ...

# Execute command passed as argument
"$@"
EOF

chmod +x /tmp/coordinate-wrapper-$$.sh

# STEP 2: Use wrapper to call function
WORKFLOW_SCOPE=$(/tmp/coordinate-wrapper-$$.sh bash -c "detect_workflow_scope '$WORKFLOW_DESCRIPTION'")
```

**Pros:**
- ✅ Source libraries once in wrapper
- ✅ Maintains separate bash blocks for incremental execution
- ✅ Explicit function export for debugging

**Cons:**
- ❌ Complex indirection (harder to understand)
- ❌ Requires temporary file management (cleanup on error)
- ❌ Still requires `export -f` which may not work across Claude Code's process boundaries
- ❌ Over-engineered for the problem space

**Verdict**: Overly complex; simpler solutions preferred.

## Recommendation

**Adopt Solution 1 (Re-source Libraries in Each Block)** with the following optimizations:

### Implementation Strategy

1. **Create a standardized sourcing snippet**:
```bash
# .claude/lib/source-libraries-snippet.sh (for documentation)
# Copy-paste this at the start of any bash block needing library functions
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library-sourcing.sh"
source_required_libraries "workflow-detection.sh" "unified-logger.sh" || exit 1
```

2. **Identify critical bash blocks** that call library functions:
   - STEP 2 (detect_workflow_scope)
   - Any step calling emit_progress
   - Any step calling checkpoint functions
   - Any step calling metadata extraction

3. **Add sourcing only to those blocks** (not all 38):
   - Estimated ~8-12 blocks need library access
   - Performance impact: ~0.1s per source operation = ~1.2s total overhead

4. **Update STEP 0 verification** to include warning:
```bash
echo "✓ All libraries loaded successfully (within this bash block)"
echo "NOTE: Subsequent bash blocks must re-source libraries as needed"
```

### Long-Term Solution

Consider creating a **Claude Code execution model guideline** document:
- Explain subprocess isolation per bash block
- Provide best practices for library sourcing in multi-block commands
- Create templates for commands with persistent state requirements
- Document when to use single-block vs. multi-block design

This issue likely affects other orchestration commands (`/orchestrate`, `/supervise`) and should be addressed systematically across the `.claude/commands/` directory.

## References

- **Coordinate Command**: `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 526-695)
- **Library Sourcing**: `/home/benjamin/.config/.claude/lib/library-sourcing.sh`
- **Workflow Detection**: `/home/benjamin/.config/.claude/lib/workflow-detection.sh`
- **Console Output**: `/home/benjamin/.config/.claude/specs/coordinate_output.md` (lines 17, 26-27, 42)
- **Bash Function Export**: `man bash` → Section on `export -f`

## Appendix: Bash Subprocess Isolation Test

To verify the subprocess isolation hypothesis, the following test was implied by the console output:

```bash
# Test 1: Source in one bash block
bash -c "
  source /path/to/library-sourcing.sh
  source_required_libraries workflow-detection.sh
  command -v detect_workflow_scope && echo 'Function available in Block 1'
"
# Output: Function available in Block 1

# Test 2: Try to use function in next bash block
bash -c "
  command -v detect_workflow_scope && echo 'Function available in Block 2' || echo 'Function NOT available in Block 2'
"
# Output: Function NOT available in Block 2

# Test 3: Re-source in second bash block
bash -c "
  source /path/to/library-sourcing.sh
  source_required_libraries workflow-detection.sh
  command -v detect_workflow_scope && echo 'Function available in Block 3'
"
# Output: Function available in Block 3
```

This matches the observed behavior in the console output (success after manual re-sourcing).
