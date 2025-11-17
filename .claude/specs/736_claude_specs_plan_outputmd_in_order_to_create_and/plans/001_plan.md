# Implementation Plan: Fix Remaining Commands with BASH_SOURCE Bootstrap Issues

## Metadata
- **Date**: 2025-11-16
- **Feature**: Fix BASH_SOURCE bootstrap errors in implement, expand, and collapse commands
- **Scope**: Apply inline CLAUDE_PROJECT_DIR bootstrap pattern to remaining affected commands
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Structure Level**: 0
- **Complexity Score**: 62.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Error Analysis](../reports/001_topic1.md)
  - [Path Detection Infrastructure](../reports/002_topic2.md)
  - [Resolution Strategy](../reports/003_topic3.md)

## Overview

The plan_output.md error log documents a BASH_SOURCE-based bootstrap failure that was fixed for the /plan command in Spec 732. However, three additional commands (implement, expand, collapse) still use the broken pattern and are completely non-functional. This plan applies the proven inline CLAUDE_PROJECT_DIR bootstrap pattern from Spec 732 to fix the remaining commands.

## Research Summary

Key findings from research reports:

**Error Analysis (Report 001)**:
- The errors in plan_output.md are historical artifacts from BEFORE Spec 732 fix
- Root cause: BASH_SOURCE[0] returns empty in Claude Code's bash block execution context
- Bootstrap paradox: Need detect-project-dir.sh to find project directory, but need project directory to source detect-project-dir.sh
- Spec 732 resolved this for /plan command (commit b60a03f9)

**Path Detection Infrastructure (Report 002)**:
- Inline bootstrap pattern eliminates bootstrap paradox
- Uses git-based detection (2ms, 100% reliability in git repos)
- Directory traversal fallback for non-git environments
- /plan command working implementation at lines 22-52
- 3 commands still need fixes: implement.md, expand.md, collapse.md

**Resolution Strategy (Report 003)**:
- Inline bootstrap pattern proven working in /plan command
- Pattern documented in plan.md:26-53
- Same fix applies to all affected commands
- No restructuring needed, only pattern replacement

Recommended approach: Apply identical inline bootstrap pattern from /plan command to implement, expand, and collapse commands.

## Success Criteria

- [ ] /implement command Phase 0 bootstrap completes successfully
- [ ] /expand command Phase 0 bootstrap completes successfully
- [ ] /collapse command Phase 0 bootstrap completes successfully
- [ ] All commands detect CLAUDE_PROJECT_DIR from project root
- [ ] All commands detect CLAUDE_PROJECT_DIR from subdirectories
- [ ] All commands fail gracefully when run outside project
- [ ] All libraries source successfully with absolute paths
- [ ] Zero "No such file or directory" errors
- [ ] Standards 0, 11, 13, 15 compliance verified
- [ ] Documentation updated for all three commands
- [ ] Integration tests pass for all commands
- [ ] Git commits created for each phase

## Technical Design

### Architecture Overview

Apply the inline CLAUDE_PROJECT_DIR bootstrap pattern that successfully fixed /plan in Spec 732:

```bash
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

# Validate CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree"
  echo "SOLUTION: Run command from within a directory containing .claude/ subdirectory"
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Now safe to source libraries
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
source "$UTILS_DIR/workflow-state-machine.sh" || exit 1
```

### Component Changes

**Files to Modify**:
1. `/home/benjamin/.config/.claude/commands/implement.md` - 1 occurrence at line ~21
2. `/home/benjamin/.config/.claude/commands/expand.md` - 2 occurrences at lines ~80, ~563
3. `/home/benjamin/.config/.claude/commands/collapse.md` - 2 occurrences at lines ~82, ~431

**Pattern to Replace**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"
```

**Replacement Pattern**: See Architecture Overview section above

### Standards Compliance

- **Standard 0 (Absolute Paths)**: All library sourcing uses `$UTILS_DIR` absolute paths
- **Standard 11 (Imperative Invocation)**: Bash blocks remain imperative, no sourcing of commands
- **Standard 13 (CLAUDE_PROJECT_DIR Detection)**: Inline git-based detection with fallback
- **Standard 15 (Library Sourcing Order)**: State machine → persistence → error handling → others

## Implementation Phases

### Phase 1: Fix /implement Command Bootstrap
dependencies: []

**Objective**: Replace BASH_SOURCE pattern in implement.md with inline CLAUDE_PROJECT_DIR bootstrap

**Complexity**: Low

**Tasks**:
- [x] Read implement.md to identify BASH_SOURCE pattern location (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Replace BASH_SOURCE-based SCRIPT_DIR calculation with inline git-based bootstrap (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Add directory traversal fallback for non-git environments (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Add fail-fast validation with diagnostic messages (file: /home/benjamin/.config/.claude/commands/implement.md)
- [x] Verify all library sourcing uses absolute paths via UTILS_DIR (file: /home/benjamin/.config/.claude/commands/implement.md)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test from project root
cd /home/benjamin/.config && /implement --help

# Test from subdirectory
cd /home/benjamin/.config/nvim && /implement --help

# Test outside project (should fail gracefully)
cd /tmp && /implement --help 2>&1 | grep "Failed to detect project"

# Verify no library sourcing errors
cd /home/benjamin/.config && /implement --help 2>&1 | grep -v "No such file"
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(736): complete Phase 1 - Fix /implement command bootstrap`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Fix /expand Command Bootstrap
dependencies: [1]

**Objective**: Replace BASH_SOURCE pattern in expand.md with inline CLAUDE_PROJECT_DIR bootstrap (2 occurrences)

**Complexity**: Medium

**Tasks**:
- [x] Read expand.md to identify both BASH_SOURCE pattern locations at ~lines 80, 563 (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Replace first BASH_SOURCE pattern (line ~80) with inline bootstrap (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Replace second BASH_SOURCE pattern (line ~563) with inline bootstrap (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Add directory traversal fallback for both locations (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Add fail-fast validation with diagnostic messages (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Verify all library sourcing uses absolute paths via UTILS_DIR (file: /home/benjamin/.config/.claude/commands/expand.md)
- [x] Ensure both bash blocks in expand.md have consistent bootstrap pattern (file: /home/benjamin/.config/.claude/commands/expand.md)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test from project root
cd /home/benjamin/.config && /expand --help

# Test from subdirectory
cd /home/benjamin/.config/.claude/specs && /expand --help

# Test outside project (should fail gracefully)
cd /tmp && /expand --help 2>&1 | grep "Failed to detect project"

# Verify both bash blocks work (test phase and stage expansion)
cd /home/benjamin/.config && /expand phase /path/to/plan.md 1
```

**Expected Duration**: 1.5 hours

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(736): complete Phase 2 - Fix /expand command bootstrap`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 3: Fix /collapse Command Bootstrap
dependencies: [2]

**Objective**: Replace BASH_SOURCE pattern in collapse.md with inline CLAUDE_PROJECT_DIR bootstrap (2 occurrences)

**Complexity**: Medium

**Tasks**:
- [x] Read collapse.md to identify both BASH_SOURCE pattern locations at ~lines 82, 431 (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Replace first BASH_SOURCE pattern (line ~82) with inline bootstrap (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Replace second BASH_SOURCE pattern (line ~431) with inline bootstrap (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Add directory traversal fallback for both locations (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Add fail-fast validation with diagnostic messages (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Verify all library sourcing uses absolute paths via UTILS_DIR (file: /home/benjamin/.config/.claude/commands/collapse.md)
- [x] Ensure both bash blocks in collapse.md have consistent bootstrap pattern (file: /home/benjamin/.config/.claude/commands/collapse.md)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test from project root
cd /home/benjamin/.config && /collapse --help

# Test from subdirectory
cd /home/benjamin/.config/.claude/specs && /collapse --help

# Test outside project (should fail gracefully)
cd /tmp && /collapse --help 2>&1 | grep "Failed to detect project"

# Verify both bash blocks work (test automatic and manual collapse)
cd /home/benjamin/.config && /collapse /path/to/expanded/plan
```

**Expected Duration**: 1.5 hours

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(736): complete Phase 3 - Fix /collapse command bootstrap`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 4: Integration Testing and Validation
dependencies: [1, 2, 3]

**Objective**: Verify all three commands work correctly from various execution contexts

**Complexity**: Medium

**Tasks**:
- [x] Create integration test script testing all commands from project root (file: /home/benjamin/.config/.claude/specs/736_claude_specs_plan_outputmd_in_order_to_create_and/tests/integration_test.sh)
- [x] Test all commands from subdirectories (nvim/, .claude/specs/, .claude/commands/)
- [x] Test all commands from outside project (should fail with clear error messages)
- [x] Verify CLAUDE_PROJECT_DIR detected correctly in all contexts
- [x] Verify all libraries source successfully (workflow-state-machine.sh, state-persistence.sh, etc.)
- [x] Check for "No such file or directory" errors (should be zero)
- [x] Verify Standards 0, 11, 13, 15 compliance for all commands
- [x] Test edge cases (symlinks, git worktrees, non-git projects with .claude/)
- [x] Compare bootstrap performance (should be ~2ms for git detection)
- [x] Verify backward compatibility (existing workflows still work)

**Testing**:
```bash
# Run comprehensive integration tests
bash /home/benjamin/.config/.claude/specs/736_claude_specs_plan_outputmd_in_order_to_create_and/tests/integration_test.sh

# Manual verification for each command
for cmd in implement expand collapse; do
  echo "Testing /$cmd..."
  cd /home/benjamin/.config && /$cmd --help
  cd /home/benjamin/.config/nvim && /$cmd --help
  cd /tmp && /$cmd --help 2>&1 | grep "Failed to detect project"
done

# Performance verification
time (cd /home/benjamin/.config && /implement --help > /dev/null)
```

**Expected Duration**: 2 hours

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(736): complete Phase 4 - Integration testing and validation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 5: Documentation and Spec Completion
dependencies: [4]

**Objective**: Update documentation and create implementation summary

**Complexity**: Low

**Tasks**:
- [ ] Update bash_source_audit.md to mark implement, expand, collapse as FIXED (file: /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md)
- [ ] Create IMPLEMENTATION_SUMMARY.md for Spec 736 (file: /home/benjamin/.config/.claude/specs/736_claude_specs_plan_outputmd_in_order_to_create_and/IMPLEMENTATION_SUMMARY.md)
- [ ] Add Issue 10 to troubleshooting guide for BASH_SOURCE errors (file: /home/benjamin/.config/.claude/docs/troubleshooting/common-issues.md)
- [ ] Update command development guide with bootstrap pattern standard (file: /home/benjamin/.config/.claude/docs/guides/command-development-fundamentals.md)
- [ ] Archive plan_output.md to Spec 732 artifacts directory (file: /home/benjamin/.config/.claude/specs/plan_output.md → /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/artifacts/error_log_before_fix.md)
- [ ] Verify all documentation follows project standards (no emojis, clear examples)
- [ ] Create git status summary showing all changes

**Testing**:
```bash
# Verify documentation accuracy
grep -n "BASH_SOURCE" /home/benjamin/.config/.claude/docs/guides/command-development-fundamentals.md

# Verify archived plan_output.md
test -f /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/artifacts/error_log_before_fix.md

# Verify audit updated
grep "implement.md" /home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/bash_source_audit.md | grep "FIXED"

# Review all changes
git diff --stat
git diff
```

**Expected Duration**: 2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(736): complete Phase 5 - Documentation and spec completion`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Each command tested independently from multiple directories
- Bootstrap detection tested with git and non-git environments
- Library sourcing verified for each command
- Error messages validated for clarity and accuracy

### Integration Testing
- All three commands tested together in realistic workflows
- State persistence verified across multiple bash blocks
- Performance benchmarking for CLAUDE_PROJECT_DIR detection
- Edge case testing (symlinks, worktrees, submodules)

### Regression Testing
- Verify /plan command still works (Spec 732 fix preserved)
- Existing workflows with implement, expand, collapse still function
- Backward compatibility maintained for all commands

### Acceptance Criteria
- Zero "No such file or directory" errors for library sourcing
- 100% success rate for CLAUDE_PROJECT_DIR detection in git repos
- Clear error messages when run outside project
- All standards (0, 11, 13, 15) compliance verified
- Documentation complete and accurate

## Documentation Requirements

### Command Documentation Updates
- Update implement.md with inline bootstrap pattern explanation
- Update expand.md with bootstrap pattern for both bash blocks
- Update collapse.md with bootstrap pattern for both bash blocks
- Add comments explaining why inline bootstrap is necessary

### Architecture Documentation
- Update bash-block-execution-model.md Anti-Pattern 5 with all fixed commands
- Document bootstrap sequence as standard pattern in command development guide
- Add troubleshooting section for BASH_SOURCE errors
- Create reusable bootstrap snippet for future commands

### Spec Documentation
- Create IMPLEMENTATION_SUMMARY.md documenting all changes
- Update bash_source_audit.md with fix status
- Archive historical error logs (plan_output.md)
- Cross-reference Spec 732 and Spec 736

## Dependencies

### External Dependencies
- Git command available (for git-based detection)
- Project directory has .claude/ subdirectory (validation requirement)
- Libraries exist at $CLAUDE_PROJECT_DIR/.claude/lib/ (pre-existing)

### Internal Dependencies
- Spec 732 fix for /plan command (already complete, reference implementation)
- workflow-state-machine.sh library (already exists)
- state-persistence.sh library (already exists)
- unified-location-detection.sh library (already exists)

### Phase Dependencies
```
Phase 1 (implement) ──┐
                       ├─→ Phase 4 (integration testing) ─→ Phase 5 (documentation)
Phase 2 (expand)    ──┤
                       │
Phase 3 (collapse)  ──┘
```

Phases 1-3 can run sequentially but are independent of each other. Phase 4 depends on all three fixes being complete. Phase 5 depends on successful validation.

## Risk Assessment

### Low Risk
- Pattern is proven working in /plan command (Spec 732)
- Changes are localized to command bootstrap sections
- Backward compatibility maintained (same detection logic)

### Mitigation Strategies
- Use exact pattern from working /plan command
- Test each command independently before integration testing
- Maintain git commits per phase for easy rollback
- Validate libraries source successfully before marking phase complete

## Notes

- This spec completes the BASH_SOURCE bootstrap fix started in Spec 732
- All four affected commands (plan, implement, expand, collapse) will use identical inline bootstrap pattern
- The inline pattern eliminates the bootstrap paradox completely
- Performance impact is negligible (2ms for git detection)
- Future commands should use this pattern from the start
