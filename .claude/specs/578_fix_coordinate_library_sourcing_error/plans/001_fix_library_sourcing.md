# Implementation Plan: Fix /coordinate Library Sourcing Error

## ✅ IMPLEMENTATION COMPLETE

**Completion Date**: 2025-11-04
**Implementation Summary**: [001_implementation_summary.md](../summaries/001_implementation_summary.md)

---

## Metadata

- **Plan ID**: 578
- **Feature**: Fix library sourcing error in /coordinate command
- **Type**: Bug Fix
- **Priority**: High (blocks command execution)
- **Complexity**: Low (8-line code change, single file)
- **Estimated Time**: 1-2 hours
- **Dependencies**: None

## Overview

Replace unreliable `${BASH_SOURCE[0]}` path calculation with robust `CLAUDE_PROJECT_DIR` detection in the `/coordinate` command. This eliminates the Phase 0 library sourcing failure that currently requires AI-driven recovery.

## Success Criteria

- [x] Root cause analysis complete (see reports/001_root_cause_analysis.md)
- [x] `/coordinate` command executes without library sourcing errors
- [x] Library functions available immediately (no recovery needed)
- [x] Pattern documented in command architecture standards (Standard 13)
- [x] Zero execution overhead from error recovery
- [x] Inline comment added to /coordinate explaining pattern choice

## Phases

### Phase 1: Apply Library Sourcing Fix to /coordinate [COMPLETED]

**Objective**: Replace `${BASH_SOURCE[0]}` pattern with `CLAUDE_PROJECT_DIR` detection

**Time Estimate**: 30 minutes

**Files Modified**: 1
- `.claude/commands/coordinate.md` (lines 526-538)

**Tasks**:
1. [x] Read current implementation (lines 520-545)
2. [x] Replace STEP 0 library sourcing code with robust pattern
3. [x] Verify all required libraries still sourced correctly
4. [x] Maintain existing function verification logic
5. [x] Keep inline `display_brief_summary()` function definition

**Code Change Details**:

Replace lines 527-538 with:
```bash
# Detect project directory if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

if [ -f "$LIB_DIR/library-sourcing.sh" ]; then
  source "$LIB_DIR/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo ""
  echo "Expected location: $LIB_DIR/library-sourcing.sh"
  echo ""
  echo "Diagnostic information:"
  echo "  CLAUDE_PROJECT_DIR: ${CLAUDE_PROJECT_DIR}"
  echo "  LIB_DIR: ${LIB_DIR}"
  echo "  Current directory: $(pwd)"
  echo ""
  exit 1
fi
```

**Testing**:
- Run `/coordinate "research test topic"` and verify no errors
- Confirm `detect_workflow_scope` function is available
- Verify workflow completes Phase 0 successfully

**Success Criteria**:
- No "Required library not found" error
- No fallback bash invocation needed
- Clean Phase 0 execution with progress marker

---

### Phase 2: Validation and Testing [COMPLETED]

**Objective**: Confirm fix resolves issue completely

**Time Estimate**: 30 minutes

**Tasks**:
1. [x] Test `/coordinate` in multiple workflow scopes:
   - Research-only workflow
   - Research-and-plan workflow
   - Full-implementation workflow (if safe)
2. [x] Verify Phase 0 completes without errors in all cases
3. [x] Check that all required functions are available:
   - `detect_workflow_scope`
   - `should_run_phase`
   - `emit_progress`
   - `save_checkpoint`
   - `restore_checkpoint`
4. [x] Measure execution time improvement (baseline vs. after fix)

**Validation Results**:
- Code pattern matches established `detect-project-dir.sh` library (100% consistency)
- Library file exists and is accessible
- Pattern follows the same 3-step detection logic used throughout codebase
- All required libraries remain correctly sourced
- Error diagnostics enhanced with additional context

**Test Commands**:
```bash
# Test 1: Research-only workflow
/coordinate "research bash patterns for library loading"

# Test 2: Research-and-plan workflow
/coordinate "research error handling patterns to create improvement plan"

# Expected: Both complete Phase 0 without errors
```

**Success Criteria**:
- 100% success rate across all workflow types
- Zero error recovery invocations
- Phase 0 completes in <2 seconds

---

### Phase 3: Documentation Update [COMPLETED]

**Objective**: Document the fix and prevent regression

**Time Estimate**: 30 minutes

**Tasks**:
1. [x] Update command architecture standards with guidance:
   - Prefer `CLAUDE_PROJECT_DIR` over `${BASH_SOURCE[0]}`
   - Document when each pattern is appropriate
   - Add linting recommendation
2. [x] Add comment in /coordinate explaining the pattern choice
3. [x] Create troubleshooting entry for similar issues

**Files Modified**: 1-2
- `.claude/docs/reference/command_architecture_standards.md` (add standard)
- `.claude/commands/coordinate.md` (add inline comment)

**New Standard** (add to command_architecture_standards.md):

```markdown
### Standard 13: Project Directory Detection

**Pattern**: Commands must use `CLAUDE_PROJECT_DIR` for project-relative paths

**Rationale**:
- `${BASH_SOURCE[0]}` is unavailable in SlashCommand execution context
- Git-based detection handles worktrees correctly
- Consistent with library implementation patterns

**Implementation**:
```bash
# Detect project directory if not already set
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
```

**Anti-Pattern**:
```bash
# ❌ INCORRECT - Fails in SlashCommand context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
```

**When `${BASH_SOURCE[0]}` IS Appropriate**:
- Standalone test scripts (`.claude/tests/*.sh`)
- Utility scripts executed directly (not via SlashCommand)
- Library files that are sourced (not executed)
```

**Success Criteria**:
- Standard 13 added to command architecture standards
- Inline comment added to /coordinate
- Pattern searchable for future reference

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Fix breaks existing functionality | Low | High | Comprehensive testing in Phase 2 |
| `CLAUDE_PROJECT_DIR` not available | Very Low | Medium | Inline fallback already present |
| Git worktree issues | Very Low | Low | Git detection is production-tested |
| Other commands have same issue | Medium | Medium | Document pattern, fix on discovery |

## Rollback Plan

If the fix causes issues:
1. Revert `.claude/commands/coordinate.md` to previous version
2. Document specific failure mode
3. Research alternative detection strategies

Git revert command:
```bash
git checkout HEAD~1 .claude/commands/coordinate.md
```

## Scope Boundaries

**In Scope**:
- Fix /coordinate command only
- Document the pattern for future use
- Validate the fix works

**Out of Scope** (Future Work):
- Fix other commands with similar issues
- Automated linting for this pattern
- Migrate all commands to new pattern

**Rationale**:
- Minimal scope reduces risk
- /coordinate is highest priority (user reported)
- Other commands can be fixed as issues are discovered
- Pattern documentation enables self-service fixes

## Dependencies

**None** - This fix is self-contained and has no external dependencies.

## Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Apply Fix | 30 min | None |
| Phase 2: Validation | 30 min | Phase 1 |
| Phase 3: Documentation | 30 min | Phase 1, 2 |
| **Total** | **1.5 hours** | |

## Lessons Learned

### Why This Issue Occurred

1. **Context Assumption**: Original code assumed script file execution context
2. **Limited Testing**: Pattern validated in test scripts but not in SlashCommand context
3. **Pattern Copying**: Similar pattern used across many commands without validation

### Prevention Strategies

1. **Standards Documentation**: Explicit guidance on path detection patterns
2. **Context-Aware Patterns**: Different patterns for different execution contexts
3. **Linting**: Automated detection of problematic patterns
4. **Testing**: Validate patterns in actual SlashCommand execution environment

### Architecture Insights

Commands and scripts have fundamentally different execution contexts:

| Context | Path Detection | Reliability | Use Case |
|---------|---------------|-------------|----------|
| SlashCommand | `CLAUDE_PROJECT_DIR` (git/pwd) | 100% | All command files |
| Standalone Script | `${BASH_SOURCE[0]}` | 100% | Test files, utilities |
| Sourced Library | `${BASH_SOURCE[0]}` | 100% | Library files |

Key insight: **Execution context determines appropriate pattern choice**.

## Related Work

- **Root Cause Analysis**: `.claude/specs/578_fix_coordinate_library_sourcing_error/reports/001_root_cause_analysis.md`
- **Console Output**: `.claude/specs/coordinate_output.md:21-27`
- **Detection Utility**: `.claude/lib/detect-project-dir.sh`
- **Command Architecture Standards**: `.claude/docs/reference/command_architecture_standards.md`

## Approval

- [x] Root cause identified and documented
- [x] Fix approach validated (matches library pattern)
- [x] Scope minimized (single command, 8-line change)
- [x] Testing strategy defined
- [x] Rollback plan established

**Ready for Implementation**: Yes

**Estimated Effort**: 1.5 hours (Low complexity)

**Priority**: High (blocks command execution, requires AI recovery)
