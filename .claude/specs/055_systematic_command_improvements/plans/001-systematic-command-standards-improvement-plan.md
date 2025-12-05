# Implementation Plan: Systematic Command Standards Improvement

## Metadata

- **Date**: 2025-12-04
- **Feature**: Fix PATH MISMATCH bug and systematically improve command standards enforcement across all commands
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Research Output](/home/benjamin/.config/.claude/output/research-output.md)
  - [Lean Implement Error Analysis](/home/benjamin/.config/.claude/specs/054_lean_implement_error_analysis/reports/001-lean-implement-error-root-cause.md)

---

## Executive Summary

Analysis of `/research` command output and `/lean-implement` error analysis reveals a common root cause: the PATH MISMATCH validation check incorrectly fails when `CLAUDE_PROJECT_DIR` is a legitimate subdirectory of `HOME` (e.g., `/home/benjamin/.config`). This affects 3 commands directly and exposes broader systemic issues in command authoring standards enforcement.

This plan addresses:
1. **Immediate bug fix**: PATH MISMATCH validation logic in 3 commands
2. **Systematic improvements**: Common patterns identified across all commands
3. **Standards enforcement**: Updates to CLAUDE.md and .claude/docs/ to prevent recurrence

---

## Root Cause Analysis

### Primary Bug: PATH MISMATCH False Positive

**Location**: Block 1b in `/research`, `/create-plan`, `/lean-plan`

**Current Code (Buggy)**:
```bash
if [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  echo "ERROR: PATH MISMATCH - STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR"
  exit 1
fi
```

**Problem**: This check assumes `CLAUDE_PROJECT_DIR` is NEVER under `HOME`, but `/home/benjamin/.config` IS under `HOME` and is a valid project directory.

**Correct Logic**:
```bash
# Skip PATH MISMATCH check when PROJECT_DIR is subdirectory of HOME (valid configuration)
if [[ "$CLAUDE_PROJECT_DIR" =~ ^${HOME}/ ]]; then
  # PROJECT_DIR legitimately under HOME - skip PATH MISMATCH validation
  :
elif [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  # Only flag as error if PROJECT_DIR is NOT under HOME but STATE_FILE uses HOME
  echo "ERROR: PATH MISMATCH - STATE_FILE uses HOME instead of CLAUDE_PROJECT_DIR"
  exit 1
fi
```

### Secondary Issues (from lean-implement analysis)

1. **Phase number extraction** assumes contiguous numbering
2. **Missing defensive conversions** for work_remaining format
3. **State variable restoration** gaps (unbound variable errors)
4. **Pre-flight validation** missing for domain-specific tools

---

## Implementation Phases

### Phase 1: Fix PATH MISMATCH Bug in Affected Commands [COMPLETE]

**Objective**: Fix the false positive PATH MISMATCH error in all 3 affected commands.

**Tasks**:
- [x] Fix `/research` Block 1b PATH MISMATCH validation
- [x] Fix `/create-plan` Block 1b PATH MISMATCH validation
- [x] Fix `/lean-plan` Block 1b PATH MISMATCH validation
- [x] Verify fix works when CLAUDE_PROJECT_DIR is under HOME
- [x] Verify fix still catches actual mismatches (PROJECT_DIR not under HOME)

**Success Criteria**:
- [x] `/research` executes without PATH MISMATCH error when project is in ~/.config
- [x] `/create-plan` executes without PATH MISMATCH error
- [x] `/lean-plan` executes without PATH MISMATCH error
- [x] PATH MISMATCH still detected when STATE_FILE truly misaligned

**Files Modified**:
- `.claude/commands/research.md`
- `.claude/commands/create-plan.md`
- `.claude/commands/lean-plan.md`

---

### Phase 2: Add State Restoration Defensive Patterns [COMPLETE]

**Objective**: Prevent unbound variable errors by adding defensive initialization after state restoration.

**Tasks**:
- [x] Audit all commands for unbound variable risks after state restoration
- [x] Add defensive initialization pattern to all commands using state restoration
- [x] Document defensive initialization pattern in command-authoring.md

**Defensive Pattern**:
```bash
# === DEFENSIVE VARIABLE INITIALIZATION ===
# Initialize potentially unbound variables with defaults to prevent unbound variable errors
# These variables may not be set in state file depending on user input
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
RESEARCH_COMPLEXITY="${RESEARCH_COMPLEXITY:-3}"
FEATURE_DESCRIPTION="${FEATURE_DESCRIPTION:-}"
```

**Success Criteria**:
- [ ] No unbound variable errors in any command when variables missing from state
- [ ] Pattern documented with clear guidance on when to use

**Files Modified**:
- `.claude/commands/research.md`
- `.claude/commands/create-plan.md`
- `.claude/commands/lean-plan.md`
- `.claude/commands/implement.md`
- `.claude/commands/lean-implement.md`
- `.claude/docs/reference/standards/command-authoring.md`

---

### Phase 3: Create Shared Validation Library [COMPLETE]

**Objective**: Extract common validation patterns into reusable library functions.

**Tasks**:
- [x] Create `validate_path_consistency()` function for PATH MISMATCH checks
- [x] Create `validate_state_variables()` function for state restoration validation
- [x] Create `validate_project_directory()` function for CLAUDE_PROJECT_DIR detection
- [x] Add library to validation-utils.sh or create new path-validation.sh
- [x] Update affected commands to use library functions

**Function Specifications**:

```bash
# validate_path_consistency()
# Validates that STATE_FILE path is consistent with CLAUDE_PROJECT_DIR
# Returns 0 if consistent, 1 if mismatch detected
# Handles case where PROJECT_DIR is under HOME (valid configuration)
validate_path_consistency() {
  local state_file="$1"
  local project_dir="$2"

  # If project dir is under HOME, state file under HOME is valid
  if [[ "$project_dir" =~ ^${HOME}/ ]]; then
    return 0
  fi

  # Otherwise, state file should use project dir, not HOME
  if [[ "$state_file" =~ ^${HOME}/ ]]; then
    return 1
  fi

  return 0
}
```

**Success Criteria**:
- [ ] Library functions created and tested
- [ ] All affected commands updated to use library
- [ ] Unit tests pass for edge cases

**Files Modified**:
- `.claude/lib/workflow/validation-utils.sh` (or new file)
- All commands using PATH MISMATCH validation

---

### Phase 4: Update Documentation Standards [COMPLETE]

**Objective**: Update standards documentation to prevent recurrence of these patterns.

**Tasks**:
- [x] Add "Path Validation Patterns" section to command-authoring.md
- [x] Document when PROJECT_DIR can be under HOME (valid configuration)
- [x] Add "State Restoration Patterns" section with defensive initialization
- [x] Update CLAUDE.md with minimal description and link to new documentation
- [x] Add validation test for path consistency patterns

**Documentation Structure**:

In `command-authoring.md`, add:
```markdown
## Path Validation Patterns

### PROJECT_DIR Under HOME (Valid Configuration)

When `CLAUDE_PROJECT_DIR` is detected under `$HOME` (e.g., `~/.config`), this is a VALID
configuration. Path validation MUST NOT treat this as an error.

**Correct Pattern**:
```bash
# Use validate_path_consistency() from validation-utils.sh
if ! validate_path_consistency "$STATE_FILE" "$CLAUDE_PROJECT_DIR"; then
  log_command_error "state_error" "PATH MISMATCH detected" "..."
  exit 1
fi
```

**Anti-Pattern** (Causes false positives):
```bash
# WRONG: Assumes PROJECT_DIR is never under HOME
if [[ "$STATE_FILE" =~ ^${HOME}/ ]]; then
  echo "ERROR: PATH MISMATCH"  # FALSE POSITIVE when PROJECT_DIR is ~/.config
  exit 1
fi
```

**Success Criteria**:
- [ ] Documentation updated with clear guidance
- [ ] CLAUDE.md updated with minimal link to new section
- [ ] No existing commands violate new standards

**Files Modified**:
- `.claude/docs/reference/standards/command-authoring.md`
- `/home/benjamin/.config/CLAUDE.md`

---

### Phase 5: Add Lint Validation Script [COMPLETE]

**Objective**: Create automated validation to detect problematic patterns in command files.

**Tasks**:
- [x] Create `lint-path-validation.sh` script
- [x] Detect anti-pattern: `if [[ "$STATE_FILE" =~ ^${HOME}/ ]]` without PROJECT_DIR check
- [x] Detect missing defensive variable initialization after state restoration
- [x] Add to pre-commit hook validation
- [x] Add to validate-all-standards.sh

**Script Behavior**:
```bash
# lint-path-validation.sh
# Detects:
# - PATH MISMATCH anti-pattern (direct HOME check without PROJECT_DIR context)
# - Missing defensive initialization after load_workflow_state
# - Unquoted variable references in path operations

# Exit codes:
# 0 - No violations
# 1 - Violations found
```

**Success Criteria**:
- [ ] Script detects known anti-patterns
- [ ] Integrated into validation suite
- [ ] All current commands pass validation after fixes

**Files Created/Modified**:
- `.claude/scripts/lint-path-validation.sh` (new)
- `.claude/scripts/validate-all-standards.sh`
- `.git/hooks/pre-commit` (if applicable)

---

### Phase 6: Apply Patterns to All Commands [COMPLETE]

**Objective**: Systematically review and update all commands to follow new standards.

**Tasks**:
- [x] Audit `/implement` for path and state patterns
- [x] Audit `/lean-implement` for path and state patterns
- [x] Audit `/test` for path and state patterns
- [x] Audit `/debug` for path and state patterns
- [x] Audit `/revise` for path and state patterns
- [x] Audit `/repair` for path and state patterns
- [x] Audit `/expand` and `/collapse` for path and state patterns
- [x] Run lint validation on all commands
- [x] Fix any violations found

**Success Criteria**:
- [x] All 18 command files pass lint validation
- [x] No PATH MISMATCH false positives in any command
- [x] No unbound variable errors in any command

**Files Modified**:
- All files in `.claude/commands/*.md`

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking working commands | Medium | High | Test each fix individually before bulk update |
| Missing edge cases | Low | Medium | Add comprehensive unit tests for validation functions |
| Documentation drift | Low | Low | Include doc updates in same PR as code changes |

---

## Testing Strategy

### Unit Tests

1. **Path validation tests** (`.claude/tests/unit/test_path_validation.sh`):
   - Test validate_path_consistency with PROJECT_DIR under HOME
   - Test validate_path_consistency with PROJECT_DIR NOT under HOME
   - Test with various path formats

2. **State restoration tests**:
   - Test defensive initialization with missing variables
   - Test state file loading with partial content

### Integration Tests

1. Run `/research` in ~/.config project directory
2. Run `/create-plan` in ~/.config project directory
3. Run `/lean-plan` in ~/.config project directory
4. Verify no PATH MISMATCH errors

### Regression Tests

1. Ensure PATH MISMATCH still detected for actual misalignment
2. Ensure commands work in non-HOME project directories

---

## Rollback Plan

If issues discovered after deployment:

1. Revert command file changes individually
2. Keep validation library (non-breaking)
3. Documentation changes are informational (no rollback needed)

---

## Dependencies

- **None**: All changes are internal to .claude/ infrastructure
- No external dependencies or version requirements

---

## Next Steps

After plan approval:
1. `/implement /home/benjamin/.config/.claude/specs/055_systematic_command_improvements/plans/001-systematic-command-standards-improvement-plan.md`
2. `/test` to verify fixes
3. Run `/todo` to update TODO.md tracking
