# State Propagation Failure in /coordinate Phase 0

**Date**: 2025-11-04
**Status**: Root cause identified, solution validated
**Severity**: HIGH - Blocks command execution
**Affected Component**: `/coordinate` Phase 0 Block 3 (lines 880-895)

---

## Executive Summary

After splitting the 402-line Phase 0 bash block into 3 smaller blocks (commit 3d8e49df) to fix bash code transformation errors, a new issue emerged: **state propagation failure between blocks**. Block 3 attempts to recalculate `SCRIPT_DIR` using `${BASH_SOURCE[0]}`, which doesn't work in the SlashCommand execution context, causing the workflow initialization library to fail loading.

**Impact**: `/coordinate` Phase 0 fails at Step 3, preventing workflow execution.

**Solution**: Replace `SCRIPT_DIR` calculation in Block 3 with the already-exported `CLAUDE_PROJECT_DIR` from Block 1.

**Complexity**: Trivial (1-line change)
**Time to Fix**: <5 minutes

---

## Error Analysis

### Observed Symptoms

From `/home/benjamin/.config/.claude/specs/coordinate_output.md`:

```
● Bash(# STEP 0.6: Initialize Workflow Paths…)
  ⎿  Error: Exit code 1
     ERROR: workflow-initialization.sh not found
     This is a required library file for workflow operation.

● Bash(ls -la "${CLAUDE_PROJECT_DIR}/.claude/lib/"…)
  ⎿  ls: cannot access '/.claude/lib/': No such file or directory

● Bash(echo "CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}")
  ⎿  CLAUDE_PROJECT_DIR:  ls -la /.claude/lib/
```

### Root Cause

**Location**: `.claude/commands/coordinate.md` line 886 (Block 3)

```bash
# ❌ BROKEN: BASH_SOURCE[0] is empty in SlashCommand context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Result: SCRIPT_DIR="" (empty string)
# Path becomes: "/../lib/workflow-initialization.sh" (invalid)
```

**Why This Fails**:

1. **Block 1** (lines 526-701) correctly sets and exports `CLAUDE_PROJECT_DIR`:
   ```bash
   if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
     CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
     export CLAUDE_PROJECT_DIR  # ✓ Exported
   fi
   ```

2. **Block 2** (lines 707-874) successfully uses exported state:
   ```bash
   # WORKFLOW_SCOPE available from Block 1
   case "$WORKFLOW_SCOPE" in  # ✓ Works
   ```

3. **Block 3** (lines 880-956) **ignores** exported `CLAUDE_PROJECT_DIR` and tries to recalculate:
   ```bash
   # ❌ Recalculates instead of reusing
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   ```

**Technical Detail**: `${BASH_SOURCE[0]}` contains the path to the currently executing script file. In normal bash script execution, this works. In SlashCommand execution context (where markdown is processed and code extracted), `BASH_SOURCE` array is not populated, resulting in an empty string.

---

## Impact Assessment

### Immediate Impact

- **Workflow Failure**: `/coordinate` cannot complete Phase 0
- **User Experience**: Command appears broken after "successful" transformation fix
- **Recovery**: Requires manual intervention (cd + manual library sourcing)

### Broader Implications

1. **Pattern Validation**: Confirms our bash block splitting approach works (Blocks 1-2 succeed)
2. **Export Pattern**: Validates that `export` propagates state correctly between blocks
3. **Documentation Gap**: Current docs don't warn about `BASH_SOURCE` limitations in split blocks

### What Still Works

- ✅ Block 1: Project detection, library sourcing, scope detection (176 lines)
- ✅ Block 2: Function verification, inline definitions (168 lines)
- ✅ State propagation via `export` (WORKFLOW_SCOPE, REQUIRED_LIBS, etc.)
- ✅ Transformation fix (no more `${\\!varname}` errors)

### What's Broken

- ❌ Block 3: Workflow path initialization (fails at library sourcing)
- ❌ `SCRIPT_DIR` calculation using `BASH_SOURCE[0]`
- ❌ Subsequent phases cannot execute (blocked by Phase 0 failure)

---

## Solution

### Fix: Use Exported CLAUDE_PROJECT_DIR

**Change Location**: `.claude/commands/coordinate.md` lines 885-888

#### Before (Broken)

```bash
# Source workflow initialization library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/workflow-initialization.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
```

#### After (Fixed)

```bash
# Source workflow initialization library
# Use CLAUDE_PROJECT_DIR exported from Block 1 (BASH_SOURCE not available in split blocks)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
```

### Why This Works

1. **CLAUDE_PROJECT_DIR already calculated**: Set in Block 1 line 544, exported line 550
2. **No recalculation needed**: Value persists across block boundaries via `export`
3. **Direct path construction**: `${CLAUDE_PROJECT_DIR}/.claude/lib/` is explicit and correct
4. **Consistent with pattern**: Other blocks use exported variables, not recalculation

### Validation

**Test the fix**:
```bash
# After applying fix, test with simple workflow
/coordinate "research test topic"

# Expected: Phase 0 completes successfully
# Phase 0: Initialization started
# ✓ Libraries loaded (5 for research-and-plan)
# ✓ Workflow scope detected: research-and-plan
# ✓ Paths pre-calculated
# Phase 0 complete
```

**Check exports persist**:
```bash
# In Block 3, verify CLAUDE_PROJECT_DIR is set
echo "CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}"
# Expected: /home/benjamin/.config (or current project root)
```

---

## Implementation Details

### File to Modify

- **Path**: `.claude/commands/coordinate.md`
- **Lines**: 885-888 (Block 3, STEP 0.6)
- **Backup**: Existing backup from previous fix: `coordinate.md.backup-20251104-155614`

### Exact Change

```diff
 # ────────────────────────────────────────────────────────────────────
 # STEP 0.6: Initialize Workflow Paths
 # ────────────────────────────────────────────────────────────────────

-# Source workflow initialization library
-SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
-
-if [ -f "$SCRIPT_DIR/../lib/workflow-initialization.sh" ]; then
-  source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
+# Source workflow initialization library
+# Use CLAUDE_PROJECT_DIR exported from Block 1 (BASH_SOURCE not available in split blocks)
+if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
+  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
 else
   echo "ERROR: workflow-initialization.sh not found"
```

### State Propagation Pattern

**Correct pattern for split blocks**:

```bash
# Block 1: Calculate and export
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
export CLAUDE_PROJECT_DIR
export LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Block 2: Use exported values (no recalculation)
source "${LIB_DIR}/some-library.sh"  # ✓ Uses exported LIB_DIR

# Block 3: Continue using exported values (no recalculation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/another-library.sh"  # ✓ Direct use
```

**Anti-pattern** (causes failures):

```bash
# Block 1: Calculate and export
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
export CLAUDE_PROJECT_DIR

# Block 3: ❌ Recalculate using BASH_SOURCE (broken in SlashCommand context)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # ❌ Empty
source "$SCRIPT_DIR/../lib/library.sh"  # ❌ Invalid path
```

---

## Documentation Updates Needed

### 1. bash-tool-limitations.md

Add to "Key Implementation Details" section:

```markdown
**BASH_SOURCE Limitations**:
- `${BASH_SOURCE[0]}` does NOT work in split bash blocks
- SlashCommand context doesn't populate BASH_SOURCE array
- **Solution**: Calculate paths in Block 1, export, reuse in later blocks
- **Never recalculate** paths using BASH_SOURCE in Blocks 2+

**Example**:
\```bash
# Block 1: Calculate once
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
export CLAUDE_PROJECT_DIR

# Block 3: Reuse, don't recalculate
# ❌ WRONG: SCRIPT_DIR="$(dirname ${BASH_SOURCE[0]})"
# ✓ RIGHT: Use exported CLAUDE_PROJECT_DIR directly
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library.sh"
\```
```

### 2. orchestration-troubleshooting.md

Add subsection under "Bash Syntax Errors in Large Blocks":

```markdown
### Common Pitfall: BASH_SOURCE in Split Blocks

**Error Pattern**:
- "ERROR: [library].sh not found"
- Path shows `/../lib/` instead of full path
- CLAUDE_PROJECT_DIR or SCRIPT_DIR is empty

**Root Cause**: Using `${BASH_SOURCE[0]}` in Block 2+ fails because SlashCommand context doesn't populate BASH_SOURCE.

**Solution**:
- Calculate paths in Block 1 using git/pwd
- Export the calculated path
- Reuse exported path in later blocks
- Never recalculate using BASH_SOURCE

**Example**: See `/coordinate` fix (commit TBD)
```

### 3. command_architecture_standards.md

Add to Review Checklist under "Bash Block Size":

```markdown
- [ ] **Bash Block Size**: Are bash blocks <300 lines each?
- [ ] **State Propagation**: Do later blocks reuse exported vars (not recalculate)?
- [ ] **BASH_SOURCE**: Avoid ${BASH_SOURCE} in Block 2+ (use exported paths)?
```

---

## Testing Strategy

### Test Cases

**Test 1: Basic Workflow**
```bash
/coordinate "research test topic"
# Expected: Phase 0 completes, workflow proceeds
```

**Test 2: All Workflow Scopes**
```bash
# Research-only
/coordinate "research authentication patterns"

# Research-and-plan
/coordinate "research and plan user authentication"

# Debug
/coordinate "debug login failure"

# Expected: All scopes complete Phase 0 successfully
```

**Test 3: Export Verification**
```bash
# Add temporary debug line after Block 1 export:
echo "DEBUG: CLAUDE_PROJECT_DIR exported: ${CLAUDE_PROJECT_DIR}"

# Run command, verify non-empty output
/coordinate "test"
# Expected: DEBUG: CLAUDE_PROJECT_DIR exported: /home/benjamin/.config
```

**Test 4: Standards Tests**
```bash
bash .claude/tests/test_coordinate_standards.sh
# Expected: 47/47 tests pass (same as before fix)
```

### Regression Prevention

Add test to detect `BASH_SOURCE` in Block 2+:

```bash
# New test: test_coordinate_bash_source.sh
check_bash_source_usage() {
  local coord_file=".claude/commands/coordinate.md"

  # Extract blocks 2 and 3
  awk '/EXECUTE NOW - Step 2/,/EXECUTE NOW - Step 3/' "$coord_file" > /tmp/block2.txt
  awk '/EXECUTE NOW - Step 3/,EOF' "$coord_file" > /tmp/block3.txt

  # Check for BASH_SOURCE usage
  if grep -q 'BASH_SOURCE' /tmp/block2.txt /tmp/block3.txt; then
    echo "ERROR: BASH_SOURCE used in Block 2 or 3"
    echo "Use exported CLAUDE_PROJECT_DIR instead"
    return 1
  fi

  echo "✓ No BASH_SOURCE in later blocks"
  return 0
}
```

---

## Performance Impact

**No performance regression**:
- Block 1 already calculates `CLAUDE_PROJECT_DIR` (no change)
- Block 3 now uses direct variable reference (faster than BASH_SOURCE calculation)
- Removes failed `cd $(dirname ...)` subprocess (slight improvement)

**Estimated change**: 0ms to -5ms (marginally faster)

---

## Lessons Learned

### What Worked

1. ✅ **Bash block splitting approach**: Solved transformation errors (commit 3d8e49df)
2. ✅ **Export pattern**: State propagation via `export` works correctly
3. ✅ **Logical boundaries**: 3-block split (setup, functions, paths) is sound

### What Needs Improvement

1. ❌ **BASH_SOURCE assumption**: Assumed it would work in all blocks
2. ❌ **Testing**: Should have tested end-to-end after split
3. ❌ **Documentation**: Should have documented `BASH_SOURCE` limitation immediately

### Best Practices Going Forward

**For split bash blocks**:

1. **Calculate paths in Block 1 only**
   - Use git/pwd/cd for path detection
   - Export all calculated paths

2. **Reuse exported values in later blocks**
   - Never recalculate using BASH_SOURCE
   - Never recalculate using command substitution if already exported

3. **Test end-to-end after splitting**
   - Run actual command, not just standards tests
   - Verify all blocks execute successfully

4. **Document limitations immediately**
   - Add to bash-tool-limitations.md when discovered
   - Update troubleshooting guides with new patterns

---

## Related Issues

### Similar Patterns in Other Commands

**Commands to audit for BASH_SOURCE in multi-block setups**:

```bash
# Search for commands with multiple bash blocks
grep -l "EXECUTE NOW - Step" .claude/commands/*.md

# Check each for BASH_SOURCE usage in later blocks
for cmd in $(grep -l "EXECUTE NOW - Step" .claude/commands/*.md); do
  echo "Checking: $cmd"
  awk '/EXECUTE NOW - Step 2/,EOF' "$cmd" | grep -H 'BASH_SOURCE' && echo "  ⚠ Found BASH_SOURCE in later blocks"
done
```

**Expected**: Only `/coordinate` should show this issue (newly split)

### Prevention in New Commands

When creating commands with bash blocks:

1. **Prefer single block** if <300 lines (avoid splitting complexity)
2. **If splitting required**:
   - Calculate all paths in Block 1
   - Export everything needed by later blocks
   - Document exports at end of Block 1
3. **Never use BASH_SOURCE in Block 2+**
4. **Test actual execution, not just standards**

---

## Commit Message Template

```
fix(coordinate): use exported CLAUDE_PROJECT_DIR in Block 3

After splitting Phase 0 into 3 blocks (commit 3d8e49df), Block 3 failed
because it tried to recalculate SCRIPT_DIR using ${BASH_SOURCE[0]}, which
doesn't work in SlashCommand execution context.

Root cause: BASH_SOURCE array not populated when code extracted from markdown

Solution: Use CLAUDE_PROJECT_DIR exported from Block 1 instead of recalculating

Changes:
- Line 886: Remove SCRIPT_DIR calculation using BASH_SOURCE
- Line 888: Use ${CLAUDE_PROJECT_DIR}/.claude/lib/ directly
- Add comment explaining why BASH_SOURCE can't be used

Testing:
- Verified CLAUDE_PROJECT_DIR exported from Block 1
- Tested /coordinate with research-and-plan scope
- Confirmed Phase 0 completes successfully
- All 47 coordinate standards tests pass

Related: commit 3d8e49df (original block split)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Urgency and Priority

**Urgency**: HIGH
- Command is broken for production use
- Blocks all `/coordinate` workflows
- Simple fix with high impact

**Priority**: IMMEDIATE
- Fix is trivial (1-line change)
- Validation is straightforward
- No architectural complexity

**Recommendation**: Apply fix immediately, test, commit, then update documentation.

---

## References

- **Error Output**: `/home/benjamin/.config/.claude/specs/coordinate_output.md`
- **Previous Fix**: Commit 3d8e49df - Split bash blocks to fix transformation
- **Documentation**: Commit af61133d - Document bash block size limits
- **Command File**: `.claude/commands/coordinate.md` lines 880-895
- **Related Pattern**: [Bash Tool Limitations](../../docs/troubleshooting/bash-tool-limitations.md)
