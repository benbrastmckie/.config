# Standards Compliance Analysis for Plan 001

## Overview

This report analyzes the implementation plan at `/home/benjamin/.config/.claude/specs/822_claude_reviseoutputmd_which_i_want_you_to/plans/001_claude_reviseoutputmd_which_i_want_you_t_plan.md` against current `.claude/docs/` standards to identify discrepancies requiring revision.

## Critical Finding: Library Path Reorganization

### Issue

The plan references library paths that no longer exist. The `.claude/lib/` directory was reorganized into functional subdirectories during the November 2025 refactor.

### Evidence

**Plan references old paths** (lines 148, 177-178, 191-194, etc.):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
```

**Current library structure** (from `lib/README.md`):
```
.claude/lib/
  core/               # state-persistence.sh, error-handling.sh, library-version-check.sh
  workflow/           # workflow-state-machine.sh, checkpoint-utils.sh
  plan/               # plan-core-bundle.sh, complexity-utils.sh
  artifact/           # artifact-creation.sh
  convert/            # convert-core.sh
  util/               # git-commit-utils.sh
```

### Correct Paths

| Old Path (In Plan) | New Path (Standard) |
|--------------------|---------------------|
| `.claude/lib/state-persistence.sh` | `.claude/lib/core/state-persistence.sh` |
| `.claude/lib/workflow-state-machine.sh` | `.claude/lib/workflow/workflow-state-machine.sh` |
| `.claude/lib/library-version-check.sh` | `.claude/lib/core/library-version-check.sh` |
| `.claude/lib/error-handling.sh` | `.claude/lib/core/error-handling.sh` |

## Standards Compliance Checklist

### Compliant Aspects

- [x] **Subprocess Isolation Pattern**: Plan correctly identifies the need for CLAUDE_PROJECT_DIR bootstrap in each bash block
- [x] **Fail-Fast Error Handling**: Plan includes proper return code verification patterns
- [x] **Two-Step Argument Capture**: Not directly addressed but plan follows established command patterns
- [x] **State Persistence Pattern**: Plan correctly uses `append_workflow_state()` and `load_workflow_state()`
- [x] **Testing Strategy**: Plan includes appropriate testing steps with bash syntax validation

### Non-Compliant Aspects

- [ ] **Library Paths**: All library source statements use old flat structure paths
- [ ] **Library Version Check**: Plan references `check_library_requirements` but with old path
- [ ] **Sourcing Example Code**: Code examples in plan tasks show incorrect paths

## Specific Revisions Required

### Phase 2 Task Revision

**Current** (line 125-148):
```bash
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
# ...
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
```

**Required**:
```bash
CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
# ...
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
```

### Phase 3 Task Revision

**Current** (lines 176-194):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh" 2>/dev/null
```

**Required**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
```

### Testing Command Revision

**Current** (line 206):
```bash
grep "source.*state-persistence.sh.*2>/dev/null" /home/benjamin/.config/.claude/commands/revise.md
```

**Required**:
```bash
grep "source.*lib/core/state-persistence.sh.*2>/dev/null" /home/benjamin/.config/.claude/commands/revise.md
```

## Additional Considerations

### 1. The revise.md Command Also Needs Update

The plan is designed to fix `revise.md`, but the plan's code examples should use the new library paths that `revise.md` should be updated to use. This creates consistency between the plan and the expected final state.

### 2. Verification Commands Need Update

The grep patterns in testing tasks should verify the new paths, not the old ones.

### 3. Documentation Reference

The plan correctly references `bash-block-execution-model.md` which has been updated to show the new library structure patterns.

## Recommendation

Revise the plan to:

1. Update all library source paths from flat structure to subdirectory structure
2. Update grep verification patterns to check for new paths
3. Add a note that the library reorganization occurred in November 2025

## Impact Assessment

- **Severity**: High (plan would produce non-functional code)
- **Scope**: Phases 2, 3, and 4 affected
- **Effort**: Low (straightforward path replacements)

## Related Standards Documents

- `.claude/lib/README.md` - Current library structure
- `.claude/docs/concepts/directory-organization.md` - Directory standards
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation patterns
