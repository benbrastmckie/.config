# Plan Revision Research Report

## Metadata
- **Date**: 2025-11-21
- **Target Plan**: 001_error_analysis_repair_plan.md
- **Research Type**: Plan Revision Analysis
- **Status**: COMPLETE

## Analysis Summary

The existing plan correctly identifies the root cause of exit code 127 errors (missing library sourcing in bash blocks) and proposes appropriate fixes. However, the plan has significant gaps in:

1. **Standards Conformance**: The plan's sourcing pattern does not match the current documented standard (missing bootstrap phase)
2. **Infrastructure Integration**: The plan does not leverage existing enforcement mechanisms (linters, pre-commit hooks, validate-all-standards.sh)
3. **Command Coverage**: The plan mentions 5 commands but the error analysis shows 7 commands affected
4. **Verification Strategy**: The plan lacks integration with existing test infrastructure

## Standards Compliance Gaps

### Gap 1: Bootstrap Pattern Mismatch

**Current Plan Pattern** (lines 51-67):
```bash
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export CLAUDE_PROJECT_DIR
CLAUDE_LIB="$CLAUDE_PROJECT_DIR/.claude/lib"

source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}
```

**Documented Standard Pattern** (code-standards.md lines 42-67):
```bash
# 1. Bootstrap: Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# 2. Source Critical Libraries (Tier 1 - FAIL-FAST REQUIRED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
```

**Issue**: The plan uses a simplified bootstrap (`${CLAUDE_PROJECT_DIR:-...}`) instead of the full git-first-with-fallback pattern. The simplified pattern fails in non-git contexts.

### Gap 2: Three-Tier Library Classification Not Explicitly Followed

The code-standards.md defines three library tiers (lines 69-76):

| Tier | Libraries | Error Handling |
|------|-----------|----------------|
| Tier 1: Critical | state-persistence.sh, workflow-state-machine.sh, error-handling.sh | Fail-fast required |
| Tier 2: Workflow | workflow-initialization.sh, checkpoint-utils.sh, unified-logger.sh | Graceful degradation |
| Tier 3: Command-Specific | checkbox-utils.sh, summary-formatting.sh | Optional |

**Issue**: The plan only mentions Tier 1 and 2 libraries but doesn't explicitly classify `unified-location-detection.sh` (which provides `get_next_topic_number`). This library should be classified as Tier 2.

### Gap 3: Missing unified-location-detection.sh in Library Dependencies

The plan's Library Dependencies section (lines 79-97) omits `unified-location-detection.sh`:

```
unified-location-detection.sh (Tier 2)
  - detect_project_root()
  - detect_specs_directory()
  - get_next_topic_number()  <-- Used by /errors
```

This is acknowledged in line 96-97 but not included in the Technical Design's sourcing template.

## Infrastructure Integration Opportunities

### Existing Enforcement Tools Not Leveraged

The plan should integrate with these existing tools:

1. **check-library-sourcing.sh** (`/home/benjamin/.config/.claude/scripts/lint/check-library-sourcing.sh`)
   - Already validates three-tier sourcing pattern
   - Checks for bare error suppression on critical libraries
   - Warns when critical functions called without defensive `type` checks
   - **Integration**: Plan Phase 1 tasks should include running this linter after each fix

2. **lint_error_suppression.sh** (`/home/benjamin/.config/.claude/tests/utilities/lint_error_suppression.sh`)
   - Detects `save_completed_states_to_state 2>/dev/null` anti-patterns
   - Flags deprecated state paths
   - **Integration**: Plan should verify zero violations after fixes

3. **validate-all-standards.sh** (`/home/benjamin/.config/.claude/scripts/validate-all-standards.sh`)
   - Unified orchestrator for all validators
   - Provides `--sourcing` flag for targeted validation
   - **Integration**: Add verification step: `bash validate-all-standards.sh --sourcing`

4. **Pre-commit hook** (`/home/benjamin/.config/.claude/hooks/pre-commit`)
   - Runs library-sourcing linter on staged command files
   - Blocks commits with violations
   - **Integration**: Mention that pre-commit will prevent regression

### Test Infrastructure Not Referenced

The plan's Testing Strategy should leverage:

1. **Existing library sourcing tests** (referenced in bash-block-execution-model.md line 871):
   ```bash
   bash .claude/tests/test_library_sourcing_order.sh
   ```

2. **State transition tests**:
   ```bash
   bash .claude/tests/state/test_build_state_transitions.sh
   ```

3. **Linter integration in tests**:
   - Pre-fix: Run linters to baseline violations
   - Post-fix: Run linters to verify zero violations

## Recommended Plan Revisions

### Revision 1: Update Technical Design Sourcing Pattern

Replace lines 49-67 with the full documented bootstrap pattern from code-standards.md.

**Rationale**: The current pattern may fail in non-git contexts or when CLAUDE_PROJECT_DIR is not pre-set.

### Revision 2: Add unified-location-detection.sh to Sourcing Template

Add to Technical Design (after line 67):
```bash
# Tier 2: Location detection (for get_next_topic_number)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2; exit 1
}
```

**Rationale**: The `/errors` command errors are due to missing `get_next_topic_number` which is in this library.

### Revision 3: Expand Affected Commands List

Update Affected Files section to include all 7 affected commands from error analysis:

1. `/revise.md` - save_completed_states_to_state (3 errors)
2. `/research.md` - save_completed_states_to_state (mentioned in plan but not in error analysis - verify actual impact)
3. `/plan.md` - append_workflow_state (3 errors)
4. `/build.md` - save_completed_states_to_state (5 errors)
5. `/errors.md` - get_next_topic_number (5 errors)
6. `/debug.md` - bashrc sourcing (1 error - environment-specific, may not need library fix)
7. `/convert-docs.md` - validation errors only, not library sourcing (exclude from this plan)

**Rationale**: Error analysis shows `/debug` affected but plan doesn't mention it.

### Revision 4: Add Enforcement Integration Phase

Add new Phase 0 (pre-work):
```markdown
### Phase 0: Baseline Validation [NOT STARTED]
dependencies: []

**Objective**: Establish baseline violations and verify enforcement tools work.

Tasks:
- [ ] Run `bash .claude/scripts/lint/check-library-sourcing.sh` and document current violations
- [ ] Run `bash .claude/tests/utilities/lint_error_suppression.sh` and document violations
- [ ] Verify pre-commit hook is installed: `ls -la .git/hooks/pre-commit`
- [ ] Document current error count from `errors.jsonl` for each affected command

**Expected Duration**: 30 minutes
```

### Revision 5: Add Post-Fix Verification Phase

Add Phase 3 after Phase 2:
```markdown
### Phase 3: Verification and Regression Prevention [NOT STARTED]
dependencies: [1, 2]

**Objective**: Verify fixes pass all enforcement tools and document for future reference.

Tasks:
- [ ] Run `bash .claude/scripts/validate-all-standards.sh --sourcing` - expect PASSED
- [ ] Run `bash .claude/tests/utilities/lint_error_suppression.sh` - expect PASS
- [ ] Run affected commands with --complexity 1 and verify no 127 errors in logs
- [ ] Verify pre-commit hook blocks intentional violations
- [ ] Update troubleshooting docs if new patterns discovered

**Expected Duration**: 1 hour
```

### Revision 6: Update Success Criteria

Add measurable verification:
```markdown
## Success Criteria

- [ ] `bash .claude/scripts/lint/check-library-sourcing.sh` returns exit code 0 (no errors)
- [ ] `bash .claude/tests/utilities/lint_error_suppression.sh` returns exit code 0
- [ ] Zero exit code 127 errors for affected functions in last 24 hours of error log
- [ ] All affected commands pass smoke test with --complexity 1
- [ ] Pre-commit hook blocks new sourcing violations
```

## Additional Phases/Tasks Required

### Missing Task: Bashrc Environment Issue (Pattern 3)

The error analysis identifies 6 errors (10%) from `/etc/bashrc` sourcing failures. The current plan does not address this.

**Recommended Addition**:
```markdown
### Phase 2.5: Environment Compatibility Fix [NOT STARTED]
dependencies: [1]

**Objective**: Handle NixOS and similar environments where /etc/bashrc doesn't exist.

Tasks:
- [ ] Identify bash blocks that source /etc/bashrc
- [ ] Replace `. /etc/bashrc` with `[[ -f /etc/bashrc ]] && . /etc/bashrc` or remove entirely
- [ ] Test on NixOS environment

**Pattern**:
```bash
# Before (fails on NixOS)
. /etc/bashrc

# After (graceful handling)
[[ -f /etc/bashrc ]] && . /etc/bashrc || true
```

**Expected Duration**: 30 minutes
```

### Missing Task: Topic Naming Agent Errors (Pattern 4)

The error analysis shows 4 errors (7%) from topic naming agent failures. These are NOT library sourcing issues but should be tracked separately.

**Recommendation**: Create a separate plan or exclude from this plan's scope with explicit note:
```markdown
## Out of Scope

- **Topic Naming Agent Failures** (4 errors): Agent communication issues, not library sourcing. Requires separate investigation of Haiku agent output mechanism.
```

### Missing Task: Error Logging Integration

Per CLAUDE.md error logging standards, fixed commands should integrate error logging:

```markdown
### Task Addition to Phase 1:

- [ ] Ensure each fixed command sources error-handling.sh
- [ ] Add `ensure_error_log_exists` call in initialization
- [ ] Set COMMAND_NAME and WORKFLOW_ID for error tracking
```

## Summary of Recommended Changes

| Change Type | Section | Description |
|-------------|---------|-------------|
| Pattern Update | Technical Design | Use full bootstrap pattern from code-standards.md |
| Library Addition | Technical Design | Add unified-location-detection.sh sourcing |
| Command Addition | Affected Files | Add /debug.md, clarify /research.md |
| New Phase | Phase 0 | Baseline validation with existing linters |
| New Phase | Phase 3 | Post-fix verification with enforcement tools |
| Task Addition | Phase 2.5 | Environment compatibility (bashrc) |
| Success Criteria | Success Criteria | Add measurable linter-based criteria |
| Out of Scope | New Section | Explicitly exclude topic naming issues |

## References

- [Code Standards - Mandatory Bash Block Sourcing Pattern](/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern)
- [Bash Block Execution Model](/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md)
- [Enforcement Mechanisms Reference](/home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md)
- [Error Analysis Report](/home/benjamin/.config/.claude/specs/20251121_error_analysis_repair/reports/001_error_analysis.md)
- [check-library-sourcing.sh](/home/benjamin/.config/.claude/scripts/lint/check-library-sourcing.sh)
- [lint_error_suppression.sh](/home/benjamin/.config/.claude/tests/utilities/lint_error_suppression.sh)
- [validate-all-standards.sh](/home/benjamin/.config/.claude/scripts/validate-all-standards.sh)
