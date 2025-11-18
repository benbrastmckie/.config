# Fix Build Subprocess Isolation Errors Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Fix CLAUDE_PROJECT_DIR detection in build.md subprocess isolation
- **Scope**: Add missing CLAUDE_PROJECT_DIR detection to bash blocks in /build command
- **Estimated Phases**: 3
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 21.5
- **Research Reports**:
  - [Build Errors Analysis](../reports/001_build_errors_analysis.md)

## Overview

The `/build` command in `/home/benjamin/.config/.claude/commands/build.md` has critical subprocess isolation violations causing build failures. Each bash block in a command executes in a separate subprocess, meaning environment variables exported in one block are not available in subsequent blocks.

The primary error occurs in Part 3 where library source commands fail because `CLAUDE_PROJECT_DIR` is not detected before use:
```
/.claude/lib/state-persistence.sh: No such file or directory
```

This causes cascade failures including state machine initialization failure and invalid state transitions.

## Research Summary

Key findings from build errors analysis:
- **Root Cause**: Part 3 (lines 210-214) sources libraries using `${CLAUDE_PROJECT_DIR}` without detecting it first
- **Impact**: State machine never initializes, causing all subsequent phases to fail
- **Scope**: Parts 3, 4, 5, 6, and 7 all have the same vulnerability
- **Pattern**: The correct detection pattern exists in Part 2 (lines 75-92) and must be replicated

Recommended approach: Add CLAUDE_PROJECT_DIR detection to each affected bash block before any source statements.

## Success Criteria
- [ ] Part 3 bash block successfully detects CLAUDE_PROJECT_DIR before sourcing libraries
- [ ] Part 4 bash block successfully detects CLAUDE_PROJECT_DIR before sourcing libraries
- [ ] Part 5 bash block successfully detects CLAUDE_PROJECT_DIR before sourcing libraries
- [ ] Part 6 bash blocks successfully detect CLAUDE_PROJECT_DIR before sourcing libraries
- [ ] Part 7 bash block successfully detects CLAUDE_PROJECT_DIR before sourcing libraries
- [ ] All state machine transitions complete without errors
- [ ] /build command executes from start to completion without path errors
- [ ] No "No such file or directory" errors for /.claude/lib/*.sh files

## Technical Design

### Architecture Overview

The `/build` command uses multi-part bash execution where each ```` ```bash ```` block runs as an independent subprocess. Per the bash-block-execution-model, environment variables exported in one block do not persist to subsequent blocks.

### Solution Pattern

Each bash block that sources libraries must detect `CLAUDE_PROJECT_DIR` before the source statements. The canonical detection pattern:

```bash
# Bootstrap CLAUDE_PROJECT_DIR detection (subprocess isolation - cannot rely on previous block export)
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
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
  fi
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi
```

### Affected Locations

| Part | Lines | Issue |
|------|-------|-------|
| Part 3 | 210-214 | Sources state-persistence.sh and workflow-state-machine.sh without detection |
| Part 4 | 259-263 | Sources state-persistence.sh and workflow-state-machine.sh without detection |
| Part 5 | 389-393 | Sources state-persistence.sh and workflow-state-machine.sh without detection |
| Part 6a | 496-500 | Sources state-persistence.sh and workflow-state-machine.sh without detection |
| Part 6b | 613-617 | Sources state-persistence.sh and workflow-state-machine.sh without detection |
| Part 7 | 675-680 | Sources multiple libraries without detection |

## Implementation Phases

### Phase 1: Fix Part 3 - State Machine Initialization
dependencies: []

**Objective**: Add CLAUDE_PROJECT_DIR detection to Part 3 where state machine initialization occurs - this is the critical fix that resolves the primary error.

**Complexity**: Low

**Tasks**:
- [ ] Open `/home/benjamin/.config/.claude/commands/build.md`
- [ ] Locate Part 3 bash block (lines 210-253)
- [ ] Insert CLAUDE_PROJECT_DIR detection pattern after `set +H` comment and before source statements (after line 212, before line 213)
- [ ] Verify the detection pattern matches the canonical pattern from Part 2
- [ ] Ensure proper error handling with informative messages

**Testing**:
```bash
# Validate syntax
bash -n /home/benjamin/.config/.claude/commands/build.md 2>&1 || echo "Note: bash -n on markdown files may show false positives"

# Extract and test Part 3 bash block isolation
grep -A 50 "## Part 3:" /home/benjamin/.config/.claude/commands/build.md | head -60
```

**Expected Duration**: 15 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(768): complete Phase 1 - Part 3 CLAUDE_PROJECT_DIR detection`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Fix Parts 4, 5, 6, and 7
dependencies: [1]

**Objective**: Apply the same CLAUDE_PROJECT_DIR detection pattern to all remaining bash blocks that source libraries.

**Complexity**: Medium

**Tasks**:
- [ ] Part 4 (lines 259-263): Add detection pattern after `set +H` (line 260) and before source statements
- [ ] Part 5 (lines 389-393): Add detection pattern after `set +H` (line 390) and before source statements
- [ ] Part 6a (lines 496-500): Add detection pattern after `set +H` (line 497) and before source statements
- [ ] Part 6b (lines 613-617): Add detection pattern after `set +H` (line 614) and before source statements
- [ ] Part 7 (lines 675-680): Add detection pattern after `set +H` (line 676) and before source statements

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Verify all bash blocks now have detection before source statements
- [ ] Ensure consistent formatting across all parts
- [ ] Test that each block independently handles missing CLAUDE_PROJECT_DIR

**Testing**:
```bash
# Count how many bash blocks now have detection pattern
grep -c "Bootstrap CLAUDE_PROJECT_DIR detection" /home/benjamin/.config/.claude/commands/build.md
# Expected: 6 (Parts 3, 4, 5, 6a, 6b, 7)

# Verify no bare source statements remain without detection
grep -B 5 'source "${CLAUDE_PROJECT_DIR}' /home/benjamin/.config/.claude/commands/build.md | grep -c "Bootstrap CLAUDE_PROJECT_DIR"
```

**Expected Duration**: 45 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(768): complete Phase 2 - Apply detection to Parts 4-7`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Verification and Documentation
dependencies: [2]

**Objective**: Verify the complete fix by running /build command and update documentation if needed.

**Complexity**: Low

**Tasks**:
- [ ] Review all changes with `git diff` to ensure consistency
- [ ] Verify file has no syntax errors (check markdown structure)
- [ ] Clear any previous workflow state files: `rm -f ~/.claude/tmp/build_state_*.txt ~/.claude/tmp/build_arg*.txt`
- [ ] Test /build command execution with a simple plan (or dry-run mode)
- [ ] Verify no "No such file or directory" errors appear
- [ ] Verify state machine initializes successfully
- [ ] If run_all_tests.sh exists, execute test suite
- [ ] Create final commit with all changes

**Testing**:
```bash
# Full verification - dry run mode
/build --dry-run

# Or manually verify bash block structure
grep -n "## Part [0-9]:" /home/benjamin/.config/.claude/commands/build.md
grep -n "Bootstrap CLAUDE_PROJECT_DIR detection" /home/benjamin/.config/.claude/commands/build.md

# Verify line counts are reasonable (file should grow by ~100-150 lines)
wc -l /home/benjamin/.config/.claude/commands/build.md
```

**Expected Duration**: 30 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(768): complete Phase 3 - Verification and final cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Per-Phase Testing
- **Phase 1**: Verify Part 3 bash block contains detection pattern before source statements
- **Phase 2**: Count detection patterns (expect 6), verify no orphaned source statements
- **Phase 3**: End-to-end test with /build --dry-run

### Success Indicators
1. No "No such file or directory" errors for `/.claude/lib/*.sh` paths
2. State machine initializes successfully (no "command not found" for init_workflow_state)
3. State transitions succeed (no "Invalid transition: initialize -> X" errors)
4. /build command completes all phases

### Validation Commands
```bash
# Check for detection pattern presence
grep -c "Bootstrap CLAUDE_PROJECT_DIR detection" build.md  # Expect: 6

# Check no bare source statements without prior detection
# Each source block should have detection above it
```

## Documentation Requirements

- No documentation updates required for this fix
- The change is internal to the /build command implementation
- The fix follows existing patterns from Part 2 (already documented implicitly)

## Dependencies

### Prerequisites
- `/home/benjamin/.config/.claude/commands/build.md` file exists
- Git repository is accessible for version control
- No other processes actively modifying build.md

### External Dependencies
- None (internal fix to existing command)

### Integration Points
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - must be loadable
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - must be loadable
- `/home/benjamin/.config/.claude/lib/library-version-check.sh` - must be loadable
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - must be loadable
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - must be loadable

## Risk Mitigation

### Potential Risks
1. **Inconsistent detection logic**: Mitigated by using exact same pattern from Part 2
2. **Line number drift**: File edits may shift line numbers; use contextual matching
3. **Bash syntax errors**: Each edit is simple insertion; verify with bash -n if possible

### Rollback Plan
If issues arise after implementation:
```bash
git checkout HEAD -- .claude/commands/build.md
```

## Notes

- This fix applies the principle of defensive programming: each subprocess should be self-sufficient
- The detection pattern is intentionally duplicated rather than extracted to a function to maintain subprocess isolation clarity
- Future enhancement: Consider extracting detection to a sourceable preamble function for DRY compliance
