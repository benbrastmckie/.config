# Root Cause Analysis: Export Persistence Failure in /coordinate

**Date**: 2025-11-04
**Status**: Root cause identified
**Severity**: CRITICAL - Blocks all /coordinate workflows
**Affected Component**: `/coordinate` Phase 0 Blocks 1-3 state propagation

---

## Executive Summary

The fix for BASH_SOURCE (Plan 583) successfully removed the BASH_SOURCE dependency but exposed a more fundamental issue: **bash environment variable exports do not persist between separate Bash tool invocations in Claude Code**. This is a documented limitation (GitHub Issues #334 and #2508).

**Impact**: All state propagation via `export` between coordinate.md's 3 bash blocks fails.

**Solution**: Each bash block must independently calculate CLAUDE_PROJECT_DIR using git-based detection, not rely on exports from previous blocks.

---

## Error Evidence

From `/home/benjamin/.config/.claude/specs/coordinate_output.md`:

### Block 3 Execution Failure (Lines 29-47)

```
● Bash(# STEP 0.6: Initialize Workflow Paths…)
  ⎿  Error: Exit code 1
     ERROR: workflow-initialization.sh not found
     This is a required library file for workflow operation.
     Please ensure .claude/lib/workflow-initialization.sh exists.

● Bash(ls -la "${CLAUDE_PROJECT_DIR}/.claude/lib/" | grep -E "(workflow|location|topic)")
  ⎿  ls: cannot access '/.claude/lib/': No such file or directory

● Bash(echo "CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}" pwd)
  ⎿  CLAUDE_PROJECT_DIR:
     /home/benjamin/.config
```

**Analysis**:
- `CLAUDE_PROJECT_DIR` is empty string in Block 3
- Path becomes `/.claude/lib/` instead of `/home/benjamin/.config/.claude/lib/`
- Export from Block 1 (line 550) did NOT persist to Block 3

### Manual Workaround (Lines 59-62)

```
● Bash(# Fix CLAUDE_PROJECT_DIR export from previous block
      export CLAUDE_PROJECT_DIR="/home/benjamin/.config"…)
  ⎿    ✓ Paths pre-calculated
```

Claude AI manually re-exported CLAUDE_PROJECT_DIR and workflow completed successfully.

---

## Root Cause: Bash Tool Export Limitation

### Known Bug in Claude Code

From web research (GitHub Issues #334 and #2508):

> **Issue #334**: "Environment Variables and Shell Functions Not Persisting"
> **Issue #2508**: "[DOCS] Environment variables don't persist between bash commands - documentation inconsistency"
>
> When sourcing scripts that set environment variables or define shell functions in Claude Code's Bash tool, these changes don't seem to persist between command invocations.

**Reported**: March 2025 (Issue #334), June 2025 (Issue #2508)
**Status**: Known limitation, not fixed as of 2025-11-04

### Technical Explanation

**Expected Behavior** (per documentation):
```bash
# Block 1
export VAR="value"

# Block 2 (separate Bash tool invocation)
echo "$VAR"  # Should print "value"
```

**Actual Behavior**:
```bash
# Block 1
export VAR="value"

# Block 2 (separate Bash tool invocation)
echo "$VAR"  # Prints empty string - export lost!
```

**Why**: Each Bash tool invocation appears to run in a separate shell session, despite documentation claiming "persistent shell session". Exports from one invocation don't reach subsequent invocations.

---

## Impact Assessment

### What's Broken

1. **Block 1 → Block 3 state**: CLAUDE_PROJECT_DIR export doesn't persist
2. **Block 1 → Block 3 state**: LIB_DIR export doesn't persist (line 554)
3. **Block 1 → Block 3 state**: WORKFLOW_SCOPE export doesn't persist (line 622)
4. **Block 2 → Block 3 state**: Function exports don't persist (export -f)

### What Works (By Accident)

- Block 1 internal exports (single bash execution)
- Block 2 internal exports (single bash execution)
- Block 3 internal exports (single bash execution)

### Why Plan 583 Failed

Plan 583 assumed:
- ✅ BASH_SOURCE doesn't work in SlashCommand context (CORRECT)
- ❌ Exports persist across bash blocks (INCORRECT - Bash tool limitation)

The plan's core assumption about export persistence was invalidated by the Bash tool's actual behavior.

---

## Solution Analysis

### Option 1: Merge Blocks Back Together ❌

**Approach**: Combine 3 blocks into 1 to restore export functionality

**Problems**:
- Total: 176 + 168 + 77 = 421 lines
- Exceeds 400-line transformation threshold
- Will restore bash code transformation errors (${\\!var} issues)
- Reverts the fix from commit 3d8e49df

**Verdict**: Not viable - creates worse problems

### Option 2: Recalculate State in Each Block ✅

**Approach**: Each block independently calculates CLAUDE_PROJECT_DIR using git

**Advantages**:
- No dependency on exports between blocks
- Each block is self-sufficient
- Aligns with Bash tool's actual limitations
- Simple to implement (5-10 lines per block)
- No performance penalty (git detection is ~50ms)

**Implementation**:
```bash
# Add to start of Block 2 and Block 3
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
```

**Verdict**: RECOMMENDED - works within Bash tool constraints

### Option 3: Pass State via File ❌

**Approach**: Block 1 writes state to temp file, Block 2/3 read from file

**Problems**:
- Adds file I/O overhead
- Race conditions if multiple workflows run
- Cleanup complexity (when to delete temp file?)
- More complex than Option 2

**Verdict**: Over-engineered for this problem

---

## Implementation Plan

### Changes Required

**File**: `.claude/commands/coordinate.md`

**Block 2** (starts at line 707):
Add CLAUDE_PROJECT_DIR detection after opening ```bash

**Block 3** (starts at line 880):
Replace current fix (lines 885-889) with defensive recalculation

### Detailed Implementation

#### Block 2 Enhancement (After line 707)

```bash
```bash
# ────────────────────────────────────────────────────────────────────
# STEP 0.4.0: Recalculate CLAUDE_PROJECT_DIR (Export doesn't persist)
# ────────────────────────────────────────────────────────────────────
# Due to Bash tool limitation (GitHub Issues #334, #2508), exports from
# Block 1 don't persist to Block 2. Recalculate using same git-based pattern.

if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi

# ────────────────────────────────────────────────────────────────────
# STEP 0.4.1: Verify Critical Functions Based on Scope
# ────────────────────────────────────────────────────────────────────
```

#### Block 3 Enhancement (Replace lines 885-889)

```bash
# ────────────────────────────────────────────────────────────────────
# STEP 0.6: Initialize Workflow Paths
# ────────────────────────────────────────────────────────────────────

# Recalculate CLAUDE_PROJECT_DIR (exports don't persist between Bash invocations)
# Known Bash tool limitation: GitHub Issues #334, #2508
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi

# Source workflow initialization library using recalculated path
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
```

---

## Testing Strategy

### Test Cases

**Test 1: Verify Block 2 state**
```bash
# Add temporary debug line in Block 2 after recalculation
echo "DEBUG Block 2: CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR}"

# Run workflow
/coordinate "research test"

# Expected: DEBUG Block 2: CLAUDE_PROJECT_DIR=/home/benjamin/.config
```

**Test 2: Verify Block 3 state**
```bash
# Add temporary debug line in Block 3 after recalculation
echo "DEBUG Block 3: CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR}"

# Run workflow
/coordinate "research test"

# Expected: DEBUG Block 3: CLAUDE_PROJECT_DIR=/home/benjamin/.config
```

**Test 3: Full workflow**
```bash
/coordinate "research authentication patterns"
# Expected: Phase 0 completes, proceeds to Phase 1
```

**Test 4: All workflow scopes**
```bash
/coordinate "research topic"           # research-only
/coordinate "research and plan topic"  # research-and-plan
/coordinate "debug issue"              # debug-only

# Expected: All complete Phase 0 successfully
```

**Test 5: Standards tests**
```bash
bash .claude/tests/test_coordinate_standards.sh
# Expected: 47/47 tests pass
```

---

## Documentation Updates Needed

### 1. bash-tool-limitations.md

Add new section: "Export Persistence Limitation"

```markdown
### Export Persistence Between Bash Blocks

**Known Limitation** (GitHub Issues #334, #2508):

Environment variables exported in one Bash tool invocation do NOT persist to the next invocation, even though the Bash tool is documented as maintaining a "persistent shell session".

**Broken Pattern**:
```bash
**EXECUTE NOW - Block 1**
\```bash
export VAR="value"
\```

**EXECUTE NOW - Block 2**
\```bash
echo "$VAR"  # Empty! Export lost between blocks
\```
```

**Working Pattern**:
```bash
**EXECUTE NOW - Block 1**
\```bash
VAR="value"  # Calculate once
\```

**EXECUTE NOW - Block 2**
\```bash
# Recalculate, don't rely on export
VAR="value"  # Calculate again
\```
```

**Best Practice for Paths**:

Each block should independently calculate CLAUDE_PROJECT_DIR:
```bash
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
```

**Why This Works**:
- Self-sufficient: doesn't rely on previous blocks
- Fast: git detection is ~50ms
- Reliable: works within Bash tool constraints
- Idempotent: can run multiple times safely (checks `[ -z "${VAR:-}" ]`)

**Real-World Example**: /coordinate Blocks 2 and 3 (commit TBD)
```

### 2. Plan 583 Revision History

Update with finding:

```markdown
## Post-Implementation Finding

**Date**: 2025-11-04
**Issue**: Fix applied but new error emerged

The BASH_SOURCE fix was correct, but revealed a deeper issue: Bash tool doesn't persist exports between separate invocations (GitHub Issues #334, #2508).

**New Plan**: specs/584_fix_coordinate_export_persistence/
**Solution**: Recalculate CLAUDE_PROJECT_DIR in each block independently
```

---

## Performance Impact

**Recalculation overhead per block**:
- Git command: ~50ms
- Pwd fallback: ~1ms
- Total per workflow: 150ms (3 blocks × 50ms)

**Acceptable**: Phase 0 target is <500ms, recalculation adds 150ms = 300ms total (well under target)

---

## Lessons Learned

### Incorrect Assumptions

1. ❌ "Bash tool maintains persistent session with export support"
   - Documentation says this, reality doesn't match
   - Exports don't persist between invocations

2. ❌ "Split blocks can share state via export"
   - This was the core assumption of the block split strategy
   - Invalidated by Bash tool limitation

### Corrected Understanding

1. ✅ Each Bash tool invocation is isolated
2. ✅ Blocks cannot rely on state from previous blocks
3. ✅ Each block must be self-sufficient
4. ✅ Recalculation is better than failed export

### Architecture Principle

**Self-Sufficiency over State Sharing**

When splitting bash blocks in command markdown:
- Don't rely on exports between blocks
- Recalculate essential state in each block
- Use defensive checks: `[ -z "${VAR:-}" ]`
- Keep recalculation idempotent

---

## References

### GitHub Issues
- **Issue #334**: Environment Variables and Shell Functions Not Persisting
- **Issue #2508**: [DOCS] Environment variables don't persist between bash commands

### Related Files
- **Error Log**: `.claude/specs/coordinate_output.md`
- **Command File**: `.claude/commands/coordinate.md`
- **Previous Plan**: `.claude/specs/583_coordinate_block_state_propagation_fix/`
- **Detection Library**: `.claude/lib/detect-project-dir.sh` (shows correct pattern)

### Related Commits
- **Commit 3d8e49df**: Split bash blocks (created block isolation)
- **Commit TBD (Plan 583)**: BASH_SOURCE fix (exposed export issue)
- **Commit TBD (Plan 584)**: Export persistence fix (this plan)
