# Implementation Plan: Fix BASH_SOURCE State Propagation in /coordinate Block 3

## Metadata
- **Date**: 2025-11-04
- **Feature**: Fix /coordinate Phase 0 Block 3 state propagation failure
- **Type**: Bug Fix
- **Complexity**: 1/10 (Trivial - 1 line change)
- **Estimated Time**: 15 minutes
- **Estimated Phases**: 1
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `../reports/001_state_propagation_analysis.md`

## Overview

Fix the state propagation failure in `/coordinate` Phase 0 Block 3 where `${BASH_SOURCE[0]}` returns empty string in SlashCommand context, causing library sourcing to fail. Replace with the already-exported `CLAUDE_PROJECT_DIR` from Block 1.

## Success Criteria
- [x] Root cause identified (BASH_SOURCE doesn't work in split blocks)
- [ ] Fix applied to coordinate.md Block 3
- [ ] /coordinate executes successfully through Phase 0
- [ ] All workflow scopes work (research-only, research-and-plan, etc.)
- [ ] All 47 coordinate standards tests still pass
- [ ] No performance regression

## Implementation Phases

### Phase 1: Apply Minimal Fix to coordinate.md
**Objective**: Replace BASH_SOURCE calculation with exported CLAUDE_PROJECT_DIR
**Complexity**: Trivial
**Estimated Time**: 5 minutes

**Tasks**:
- [ ] Read current coordinate.md Block 3 section: `coordinate.md:880-895`
- [ ] Replace SCRIPT_DIR calculation with direct CLAUDE_PROJECT_DIR usage
- [ ] Add comment explaining why BASH_SOURCE cannot be used
- [ ] Test /coordinate Phase 0 completion
- [ ] Run coordinate standards tests
- [ ] Commit fix with detailed message

**Implementation**:

File: `.claude/commands/coordinate.md`
Lines: 885-888

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
   echo "This is a required library file for workflow operation."
   echo "Please ensure .claude/lib/workflow-initialization.sh exists."
   exit 1
 fi
```

**Testing**:
```bash
# Test 1: Basic workflow (research-and-plan scope)
/coordinate "research test topic"
# Expected: Phase 0 completes, proceeds to Phase 1

# Test 2: Verify CLAUDE_PROJECT_DIR is set
# Add temporary debug line before library sourcing:
echo "DEBUG: CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR}"
# Expected: /home/benjamin/.config (non-empty)

# Test 3: Standards tests
bash .claude/tests/test_coordinate_standards.sh
# Expected: 47/47 tests pass

# Test 4: Research-only scope
/coordinate "research authentication patterns"
# Expected: Phase 0 completes successfully

# Test 5: Full workflow (if time permits)
/coordinate "research and plan user authentication feature"
# Expected: Completes research and planning phases
```

**Verification Checklist**:
- [ ] CLAUDE_PROJECT_DIR contains valid path (not empty)
- [ ] workflow-initialization.sh sources successfully
- [ ] Phase 0 completes with "✓ Paths pre-calculated" message
- [ ] No "ERROR: workflow-initialization.sh not found" messages
- [ ] WORKFLOW_SCOPE correctly detected
- [ ] Topic directory created in .claude/specs/

**Expected Output**:
```
Phase 0: Initialization started
  ✓ Libraries loaded (5 for research-and-plan)
  ✓ Workflow scope detected: research-and-plan
  ✓ Paths pre-calculated

Workflow Scope: research-and-plan
Topic: /home/benjamin/.config/.claude/specs/584_test_topic

Phases to Execute:
  ✓ Phase 0: Initialization
  ✓ Phase 1: Research (parallel agents)
  ✓ Phase 2: Planning
  ✗ Phase 3: Implementation (skipped)

Phase 0 complete (topic: /home/benjamin/.config/.claude/specs/584_test_topic)
```

---

## Testing Strategy

### Unit Testing
Not applicable - single line change, no new functions.

### Integration Testing
- Phase 0 initialization completes
- Library sourcing succeeds
- Exported variables persist across blocks

### Regression Testing
```bash
# Run full coordinate test suite
bash .claude/tests/test_coordinate_standards.sh

# Test all workflow scopes
/coordinate "research topic"           # research-only
/coordinate "research and plan topic"  # research-and-plan
/coordinate "debug issue"              # debug-only

# Verify no performance regression
time /coordinate "research test"
# Expected: Phase 0 <500ms (same as before)
```

### Critical Path Testing
1. ✓ Block 1 exports CLAUDE_PROJECT_DIR
2. ✓ Block 2 uses exported state
3. ✓ Block 3 uses exported CLAUDE_PROJECT_DIR (this fix)
4. ✓ Library sources successfully
5. ✓ Phase 0 completes

---

## Standards Compliance

### Command Architecture Standards
From `.claude/docs/reference/command_architecture_standards.md`:

✅ **Bash Block Size**: Block 3 remains 77 lines (well under 300)
✅ **State Propagation**: Uses exported variables (not recalculation)
✅ **BASH_SOURCE Limitation**: Documented and avoided

### Bash Tool Limitations
From `.claude/docs/troubleshooting/bash-tool-limitations.md`:

✅ **Command Substitution**: Not used (direct variable reference)
✅ **Export Pattern**: Follows correct pattern (reuse, not recalculate)
✅ **BASH_SOURCE**: Avoided in Block 2+ (new best practice)

### Phase 0 Optimization
From `.claude/docs/guides/phase-0-optimization.md`:

✅ **Library-based detection**: Preserved (unified-location-detection.sh)
✅ **Performance**: No regression (removes failed BASH_SOURCE calculation)
✅ **Lazy directory creation**: Maintained

---

## Rollback Plan

If fix fails:

1. **Restore from backup**:
   ```bash
   cp .claude/commands/coordinate.md.backup-20251104-155614 \
      .claude/commands/coordinate.md
   ```

2. **Verify restoration**:
   ```bash
   git diff .claude/commands/coordinate.md
   ```

3. **Alternative approach** (if needed):
   - Calculate SCRIPT_DIR in Block 1
   - Export it along with CLAUDE_PROJECT_DIR
   - Use exported SCRIPT_DIR in Block 3

---

## Documentation Requirements

### No Documentation Files to Update
This is a bug fix, not a new pattern. Documentation already covers:
- ✓ Bash block splitting (bash-tool-limitations.md)
- ✓ State propagation via export (bash-tool-limitations.md)
- ✓ BASH_SOURCE limitation (will add after this fix validates approach)

### Documentation Updates (Post-Fix)
After fix is validated, add to bash-tool-limitations.md:

**New Section**: "BASH_SOURCE Limitations in Split Blocks"
```markdown
**Problem**: ${BASH_SOURCE[0]} returns empty in SlashCommand context

**Solution**: Calculate paths in Block 1, export, reuse in later blocks

**Example**: /coordinate fix (commit TBD)
```

Location: After "Key Implementation Details" section

---

## Git Commit Message

```
fix(coordinate): use exported CLAUDE_PROJECT_DIR in Block 3

After splitting Phase 0 into 3 blocks (commit 3d8e49df), Block 3 failed
because it tried to recalculate SCRIPT_DIR using ${BASH_SOURCE[0]}, which
doesn't work in SlashCommand execution context where markdown is processed
and code extracted.

Root cause: BASH_SOURCE array not populated in SlashCommand context
Solution: Use CLAUDE_PROJECT_DIR exported from Block 1 (line 550)

Changes:
- Line 886: Remove SCRIPT_DIR calculation using BASH_SOURCE
- Line 887: Add comment explaining BASH_SOURCE limitation
- Line 888: Use ${CLAUDE_PROJECT_DIR}/.claude/lib/ directly

Testing:
- Verified /coordinate Phase 0 completes successfully
- All 47 coordinate standards tests pass
- Tested research-only and research-and-plan scopes
- No performance regression

Related:
- commit 3d8e49df (original block split to fix transformation)
- commit 78901908 (research report on this issue)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Dependencies

### Prerequisites
- ✓ CLAUDE_PROJECT_DIR exported from Block 1 (line 550)
- ✓ Block 1 completes successfully (sets up all exports)
- ✓ workflow-initialization.sh exists at expected path

### No New Dependencies
This fix uses existing infrastructure.

---

## Risk Assessment

### Low Risk ✅
- **Single line change**: Minimal surface area for bugs
- **Uses existing export**: CLAUDE_PROJECT_DIR already validated
- **Removes complexity**: Eliminates failed BASH_SOURCE calculation
- **Backup available**: coordinate.md.backup-20251104-155614

### Validation
- ✓ Simple fix (1 line)
- ✓ Direct path reference (no calculation)
- ✓ Export already tested (Blocks 1-2 work)
- ✓ Standards tests catch regressions

---

## Success Metrics

Implementation successful when:
1. ✓ /coordinate Phase 0 completes without errors
2. ✓ All 47 coordinate standards tests pass
3. ✓ All workflow scopes execute (research-only, research-and-plan, debug-only)
4. ✓ Performance maintained (Phase 0 <500ms)
5. ✓ No new errors introduced

---

## Notes

### Why This Fix Works

1. **CLAUDE_PROJECT_DIR already available**: Set in Block 1, exported at line 550
2. **No recalculation needed**: Value persists across blocks via export
3. **More reliable**: Direct variable reference vs BASH_SOURCE calculation
4. **Simpler**: Removes subprocess execution for dirname/cd
5. **Faster**: No calculation overhead (~5ms saved)

### Alternative Approaches Considered

**Alternative 1: Calculate SCRIPT_DIR in Block 1**
- Pro: Would work
- Con: Adds unnecessary variable to Block 1
- Con: SCRIPT_DIR is only used in Block 3
- **Verdict**: Rejected - unnecessary complexity

**Alternative 2: Merge Blocks 2 and 3**
- Pro: Would work (single 245-line block)
- Con: Still under 300 lines but loses logical separation
- Con: Doesn't address root cause
- **Verdict**: Rejected - preserves problem

**Alternative 3: Use $PWD instead of BASH_SOURCE**
- Pro: $PWD works in all contexts
- Con: Assumes current directory is project root
- Con: Less reliable than git-based detection
- **Verdict**: Rejected - less robust

### Lessons for Future Split Blocks

When splitting bash blocks:
1. **Calculate ALL paths in Block 1** using git/pwd
2. **Export ALL calculated values** for later blocks
3. **Never use BASH_SOURCE in Block 2+**
4. **Document exports** at end of Block 1
5. **Test end-to-end** after splitting

---

## References

- **Error Output**: `/home/benjamin/.config/.claude/specs/coordinate_output.md`
- **Research Report**: `../reports/001_state_propagation_analysis.md`
- **Original Split**: Commit 3d8e49df - Split bash blocks to fix transformation
- **Documentation**: Commit af61133d - Document bash block size limits
- **Command File**: `.claude/commands/coordinate.md` lines 880-895
- **Standards**: `.claude/docs/troubleshooting/bash-tool-limitations.md`
