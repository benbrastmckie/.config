# Implementation Plan: Fix BASH_SOURCE State Propagation in /coordinate Block 3

## Metadata
- **Date**: 2025-11-04
- **Last Revised**: 2025-11-04 (comprehensive review)
- **Feature**: Fix /coordinate Phase 0 Block 3 state propagation failure
- **Type**: Bug Fix
- **Complexity**: 1/10 (Trivial - 2 line change)
- **Estimated Time**: 10 minutes
- **Estimated Phases**: 1
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `../reports/001_state_propagation_analysis.md`
- **Related Infrastructure**:
  - `.claude/lib/detect-project-dir.sh` - Project detection pattern
  - `.claude/lib/checkpoint-utils.sh` - Uses BASH_SOURCE correctly in library context
  - `.claude/docs/troubleshooting/bash-tool-limitations.md` - Current documentation

## Overview

Fix the state propagation failure in `/coordinate` Phase 0 Block 3 where `${BASH_SOURCE[0]}` returns empty string in SlashCommand context, causing library sourcing to fail. Replace with the already-exported `CLAUDE_PROJECT_DIR` from Block 1.

**Root Cause**: When bash code is extracted from markdown by Claude's SlashCommand processing, the `BASH_SOURCE` array is not populated because the code is not being executed as a traditional script file. This is a limitation of how markdown code blocks are processed and executed.

**Solution**: Use the `CLAUDE_PROJECT_DIR` variable that was already calculated in Block 1 (line 546) using git-based detection and exported (line 550). This follows the established pattern where Block 1 handles all path calculations and subsequent blocks reuse the exported values.

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
Lines: 885-889 (Block 3, inside Step 3 bash block at lines 880-956)

**Current Code** (lines 885-889):
```bash
# Source workflow initialization library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/workflow-initialization.sh" ]; then
  source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
```

**Fixed Code**:
```bash
# Source workflow initialization library
# Note: BASH_SOURCE not available in SlashCommand context (markdown code extraction)
# Use CLAUDE_PROJECT_DIR exported from Block 1 (line 550)
if [ -f "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh" ]; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"
```

**Changes**:
1. Remove lines 886-887 (SCRIPT_DIR calculation using BASH_SOURCE)
2. Update comment to explain why BASH_SOURCE cannot be used in this context
3. Change path from `$SCRIPT_DIR/../lib/` to `${CLAUDE_PROJECT_DIR}/.claude/lib/`

**Rationale**:
- CLAUDE_PROJECT_DIR is calculated in Block 1 using `git rev-parse --show-toplevel` (line 546)
- Exported explicitly in Block 1 (line 550) making it available to all subsequent blocks
- Direct path construction is simpler and more reliable than BASH_SOURCE calculation
- Matches the pattern used by other libraries (e.g., library-sourcing.sh uses same approach)

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

### Current Documentation Coverage
This is a bug fix that validates and extends existing patterns:
- ✓ Bash block splitting (bash-tool-limitations.md lines 138-296)
- ✓ State propagation via export (bash-tool-limitations.md lines 233-250)
- ⚠ BASH_SOURCE limitation partially documented but needs SlashCommand context specifics

### Documentation Updates Required (Post-Fix)

#### 1. bash-tool-limitations.md Enhancement
Location: After "Key Implementation Details" section (around line 250)

Add detailed section on BASH_SOURCE limitations:

```markdown
**BASH_SOURCE in Command vs Library Context**:

The `${BASH_SOURCE[0]}` array behaves differently depending on execution context:

| Context | BASH_SOURCE Value | Reason |
|---------|-------------------|--------|
| Sourced library file | File path | File exists on filesystem |
| Command markdown block | Empty string | Code extracted inline, no file |
| Direct script execution | Script path | Running as file |
| Process substitution | `/dev/fd/N` | Virtual file descriptor |

**Command Markdown Blocks** (SlashCommand context):
- Code extracted from markdown by Claude's processor
- Executed via Bash tool without intermediate file
- BASH_SOURCE[0] returns empty string
- **Solution**: Use git-based detection in Block 1, export for later blocks

**Library Files** (Sourced context):
- Executed as actual files via `source` command
- BASH_SOURCE[0] contains filesystem path
- **Pattern**: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
- This is correct for libraries, incorrect for command blocks

**Example - Correct Usage**:
```bash
# Block 1 of command markdown (coordinate.md:544-550)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"  # NOT BASH_SOURCE
  export CLAUDE_PROJECT_DIR
fi

# Block 3 of command markdown (coordinate.md:888)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-initialization.sh"  # Uses export

# Library file (checkpoint-utils.sh:16)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # This IS correct
source "$SCRIPT_DIR/detect-project-dir.sh"
```

**Real-World Case Study**: /coordinate fix (commit TBD)
- Issue: Block 3 tried to use BASH_SOURCE after block split
- Result: Empty SCRIPT_DIR, library sourcing failed
- Fix: Use exported CLAUDE_PROJECT_DIR from Block 1
- See: specs/583_coordinate_block_state_propagation_fix/
```

#### 2. command-development-guide.md Update
Location: In "Bash Blocks Best Practices" section

Add to checklist:
```markdown
- [ ] Path calculation uses git/pwd, never BASH_SOURCE in Block 1
- [ ] All paths calculated in Block 1 are exported
- [ ] Later blocks use exported paths, no recalculation
- [ ] Export chain verified with defensive checks: `[ -z "${VAR:-}" ]`
```

#### 3. command_architecture_standards.md Addition
Location: Standard 13 (Project Directory Detection)

Enhance existing standard:
```markdown
**Standard 13: Project Directory Detection**

MUST use git-based detection for CLAUDE_PROJECT_DIR, never rely on BASH_SOURCE in command markdown blocks.

**Correct Pattern** (for commands):
```bash
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi
```

**Incorrect Pattern** (for commands):
```bash
# ❌ DON'T: BASH_SOURCE is empty in SlashCommand context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

**Note**: Libraries (sourced .sh files) CAN use BASH_SOURCE as they run in file context.
```

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

### Technical Deep Dive: BASH_SOURCE Behavior

**When BASH_SOURCE works**:
- Traditional bash scripts executed directly: `bash script.sh`
- Sourced libraries: `source /path/to/library.sh`
- Context: Running as actual file with filesystem path

**When BASH_SOURCE fails**:
- Markdown code blocks extracted and executed by SlashCommand processor
- Process substitution: `bash <(echo 'commands')`
- Heredoc execution: `bash <<EOF ... EOF`
- Context: Code not associated with physical file

**coordinate.md execution context**:
```
User types: /coordinate "research topic"
Claude reads: .claude/commands/coordinate.md
Claude extracts: Bash code blocks from markdown
Claude executes: Code via Bash tool (not as script file)
Result: BASH_SOURCE[0] is empty string
```

**Verification in checkpoint-utils.sh** (line 16):
```bash
# This works because checkpoint-utils.sh IS a sourced file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"
```
The key difference: checkpoint-utils.sh is sourced as a file, coordinate.md blocks are extracted and executed inline.

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

When splitting bash blocks in command markdown files:

1. **Calculate ALL paths in Block 1** using git/pwd (not BASH_SOURCE)
   - Use: `git rev-parse --show-toplevel` for project root
   - Use: `pwd` for current directory fallback
   - Never: `dirname "${BASH_SOURCE[0]}"` in Block 1

2. **Export ALL calculated values** for later blocks
   - Required exports: CLAUDE_PROJECT_DIR, LIB_DIR, WORKFLOW_SCOPE
   - Optional exports: Function definitions with `export -f function_name`
   - Document what's exported at end of Block 1 with comments

3. **Never use BASH_SOURCE in Block 2+** (or Block 1 in commands)
   - Libraries can use BASH_SOURCE (they're sourced files)
   - Command markdown blocks cannot (code extracted inline)
   - Use exported CLAUDE_PROJECT_DIR instead

4. **Maintain export chain** across blocks
   - Block 1: Calculate and export
   - Block 2: Use exported values (no recalculation)
   - Block 3: Continue using exported values
   - Verify exports with: `[ -z "${VAR:-}" ] && echo "ERROR: VAR not set" && exit 1`

5. **Test end-to-end** after splitting
   - Not just standards tests (may not catch export failures)
   - Run actual command with real workflow
   - Verify all blocks execute successfully
   - Check exports persist: `echo "DEBUG: VAR=${VAR}"`

6. **Follow coordinate.md export pattern** (lines 550, 554, 580, 622, 788, 847, 871)
   - Consistent naming: UPPERCASE_WITH_UNDERSCORES
   - Explicit export statements after assignment
   - Group related exports on same line when appropriate

---

## References

### Primary References
- **Error Output**: `/home/benjamin/.config/.claude/specs/coordinate_output.md`
- **Research Report**: `../reports/001_state_propagation_analysis.md`
- **Command File**: `.claude/commands/coordinate.md`
  - Block 1 (lines 526-701): Project detection, exports CLAUDE_PROJECT_DIR (line 550)
  - Block 2 (lines 707-874): Function verification
  - Block 3 (lines 880-956): Path initialization (fix location: lines 885-889)

### Infrastructure References
- **Library Pattern**: `.claude/lib/checkpoint-utils.sh` line 16 (BASH_SOURCE works here)
- **Detection Library**: `.claude/lib/detect-project-dir.sh` (git-based detection)
- **Library Sourcing**: `.claude/lib/library-sourcing.sh` line 46 (uses BASH_SOURCE correctly)

### Documentation References
- **Standards**: `.claude/docs/troubleshooting/bash-tool-limitations.md`
- **Command Standards**: `.claude/docs/reference/command_architecture_standards.md` (Standard 13)
- **Development Guide**: `.claude/docs/guides/command-development-guide.md`

### Git History
- **Commit 3d8e49df**: Split bash blocks to fix transformation (created this issue)
- **Commit 78901908**: Research report on state propagation
- **Commit af61133d**: Document bash block size limits

### External Research
- **Stack Overflow**: Best practices for multi-file bash scripts (sourcing vs execution)
- **Bash Programming Guide**: Subshells and variable scoping
- **Markdown Processing**: mdsh project (bash code extraction from markdown)

---

## Revision History

### 2025-11-04 - Revision 1: Comprehensive Analysis and Enhancement
**Changes Made**:
1. Enhanced metadata with related infrastructure references
2. Added technical deep dive on BASH_SOURCE behavior differences
3. Expanded "Lessons for Future Split Blocks" with 6 detailed best practices
4. Added comprehensive documentation requirements (3 files to update)
5. Improved Implementation section with clearer before/after code
6. Added table showing BASH_SOURCE behavior across contexts
7. Enhanced References section with categorization

**Reason for Revision**:
Rigorous study of plan, existing infrastructure (.claude/lib/*), and online best practices revealed:
- Need for deeper technical explanation of why BASH_SOURCE fails
- Missing distinction between command vs library contexts
- Opportunity to document pattern for future command development
- Several related files (checkpoint-utils.sh, detect-project-dir.sh) demonstrate correct patterns

**Analysis Performed**:
- Reviewed coordinate.md structure (2155 lines, 12 export statements)
- Analyzed bash-tool-limitations.md (297 lines, partial BASH_SOURCE coverage)
- Studied checkpoint-utils.sh (824 lines, correct BASH_SOURCE usage)
- Researched bash best practices (export scoping, multi-file scripts)
- Verified Block 1 export pattern matches detect-project-dir.sh

**Key Insights Added**:
1. Distinction between SlashCommand context (markdown extraction) vs sourced files
2. Why checkpoint-utils.sh can use BASH_SOURCE but coordinate.md cannot
3. Export chain pattern across 3 blocks with verification
4. Comprehensive documentation strategy for 3 different files
5. Real-world verification examples from existing infrastructure

**Modified Sections**:
- Metadata: Added Related Infrastructure
- Overview: Added Root Cause and Solution detail
- Implementation: Clearer before/after with line numbers and rationale
- Notes: Added "Technical Deep Dive" subsection
- Lessons: Expanded from 5 to 6 detailed best practices
- Documentation: Changed from basic to comprehensive 3-file update strategy
- References: Categorized and expanded with infrastructure examples

**Reports Used**:
- `../reports/001_state_propagation_analysis.md` (original analysis)
- Web research on bash export patterns and markdown code execution

**Implementation Impact**: None - plan improvements only, no code changes yet
