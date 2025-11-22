# /errors Command Directory Protocol Compliance Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Fix /errors command directory protocol violations
- **Scope**: /errors command directory creation and workflow integration
- **Estimated Phases**: 3
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 29.5
- **Research Reports**:
  - [Directory Protocol Violations Report](/home/benjamin/.config/.claude/specs/905_error_command_directory_protocols/reports/001_error_command_directory_protocols.md)
  - [Plan Revision Analysis](/home/benjamin/.config/.claude/specs/907_001_error_report_repair/reports/002_plan_revision_analysis.md)
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/907_001_error_report_repair/reports/001_error_report.md)

## Overview

This plan addresses directory protocol violations in the `/errors` command identified in the research reports. The `/errors` command currently creates directories manually using `mkdir -p` and undefined placeholder functions (`get_next_topic_number()`, `generate_topic_name()`) instead of following the standard `workflow-initialization.sh` library pattern used by `/repair` and other workflow commands.

**Root Cause**: The `/errors` command was developed before or independently of the `workflow-initialization.sh` library standardization, resulting in:
1. Missing `workflow-initialization.sh` library sourcing
2. Manual directory creation violating lazy creation standard
3. Missing `NNN_` prefix on topic directories
4. Use of undefined functions for topic allocation

## Research Summary

Key findings from directory protocol violations research:

- **Finding 1**: `/errors` command uses undefined `get_next_topic_number()` and `generate_topic_name()` functions (lines 266-268 of errors.md)
- **Finding 2**: Eager `mkdir -p "${TOPIC_DIR}/reports"` violates lazy directory creation standard (line 271)
- **Finding 3**: Missing `workflow-initialization.sh` sourcing - only sources `workflow-state-machine.sh` and `unified-location-detection.sh`
- **Finding 4**: Output shows incorrect directory format `errors_plan_analysis` instead of `NNN_errors_plan_analysis`
- **Finding 5**: Reference implementation in `/repair` command shows correct pattern using `initialize_workflow_paths()`

Recommended approach: Integrate `workflow-initialization.sh` and replace manual directory creation with `initialize_workflow_paths()` function call, following the `/repair` command as reference implementation.

## Success Criteria

- [ ] `/errors` command sources `workflow-initialization.sh` library
- [ ] `initialize_workflow_paths()` replaces undefined `get_next_topic_number()` and `generate_topic_name()` functions
- [ ] No eager `mkdir -p` calls for artifact subdirectories in `/errors` command
- [ ] Topic directories created with proper `NNN_` prefix format (e.g., `907_error_analysis`)
- [ ] `errors-analyst` agent uses `ensure_artifact_directory()` for lazy directory creation
- [ ] `/errors` command runs successfully and creates properly-formatted directories
- [ ] All existing tests pass after changes

## Technical Design

### Architecture Overview

The `/errors` command needs to integrate with the workflow initialization infrastructure:

```
┌─────────────────────────────────────────────────────────────────┐
│                    /errors Command                               │
├─────────────────────────────────────────────────────────────────┤
│  Current (Broken)              │  Target (Fixed)                │
│  ─────────────────             │  ─────────────────             │
│  source workflow-state-machine │  source workflow-state-machine │
│  source unified-location       │  source unified-location       │
│  [missing]                     │  source workflow-initialization│
│                                │                                 │
│  get_next_topic_number()       │  initialize_workflow_paths()   │
│    [undefined function]        │    [standard library function] │
│                                │                                 │
│  generate_topic_name()         │  (handled internally)          │
│    [undefined function]        │                                 │
│                                │                                 │
│  mkdir -p "${TOPIC_DIR}"       │  (lazy creation by agent)      │
│    [eager creation - BAD]      │                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Files to Modify

| File | Change Type | Description |
|------|-------------|-------------|
| `.claude/commands/errors.md` | Modify | Add workflow-initialization.sh sourcing, replace manual directory creation with initialize_workflow_paths() |
| `.claude/agents/errors-analyst.md` | Verify | Confirm agent uses ensure_artifact_directory() for lazy creation (already correct) |

### Solution Approach

1. **Add workflow-initialization.sh sourcing** after existing library sources (lines 234-241)
2. **Replace manual topic creation** (lines 266-271) with `initialize_workflow_paths()` call
3. **Remove eager mkdir** - let agent handle directory creation lazily
4. **Update path variable names** to match exported variables from `initialize_workflow_paths()`

## Implementation Phases

### Phase 1: Integrate workflow-initialization.sh Library [COMPLETE]
dependencies: []

**Objective**: Source the workflow-initialization.sh library in the /errors command to enable proper directory management

**Complexity**: Low

Tasks:
- [x] Read current library sourcing section in `.claude/commands/errors.md` (lines 234-241)
- [x] Add `workflow-initialization.sh` sourcing after `unified-location-detection.sh`:
  ```bash
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-initialization.sh" >&2
    exit 1
  }
  ```
- [x] Verify sourcing follows three-tier pattern from code standards

Testing:
```bash
# Verify library sources successfully
source /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh
echo "Library loaded: $?"
type initialize_workflow_paths >/dev/null 2>&1 && echo "PASS: Function available" || echo "FAIL: Function not found"
```

**Expected Duration**: 0.5 hours

### Phase 2: Replace Manual Directory Creation with initialize_workflow_paths() [COMPLETE]
dependencies: [1]

**Objective**: Replace undefined functions and eager mkdir with standard workflow initialization

**Complexity**: Medium

Tasks:
- [x] Read current topic directory creation code (lines 265-274 in errors.md)
- [x] Remove undefined function calls: `get_next_topic_number()`, `generate_topic_name()`
- [x] Remove eager `mkdir -p "${TOPIC_DIR}/reports"` call
- [x] Add `initialize_workflow_paths()` call with appropriate arguments:
  ```bash
  # Initialize workflow paths (uses fallback slug generation)
  initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "2" ""
  INIT_EXIT=$?
  if [ $INIT_EXIT -ne 0 ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "file_error" \
      "Failed to initialize workflow paths" \
      "bash_block_1" \
      "$(jq -n --arg desc "$ERROR_DESCRIPTION" '{description: $desc}')"
    echo "ERROR: Failed to initialize workflow paths" >&2
    exit 1
  fi
  ```
- [x] Update path variable references to use exported `TOPIC_PATH` variable:
  ```bash
  # Use exported path variables (no mkdir needed here)
  RESEARCH_DIR="${TOPIC_PATH}/reports"
  REPORT_PATH="${RESEARCH_DIR}/001_error_report.md"
  ```
- [x] Update state file to persist correct path variables

Testing:
```bash
# Test initialize_workflow_paths() function with test description
cd /home/benjamin/.config
source .claude/lib/workflow/workflow-initialization.sh
ERROR_DESCRIPTION="test error analysis"
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "2" ""
echo "TOPIC_PATH: ${TOPIC_PATH:-<not set>}"
echo "TOPIC_NUMBER: ${TOPIC_NUMBER:-<not set>}"
# Verify path has NNN_ prefix
echo "$TOPIC_PATH" | grep -q '/specs/[0-9][0-9][0-9]_' && echo "PASS: NNN_ prefix present" || echo "FAIL: Missing NNN_ prefix"
```

**Expected Duration**: 1 hour

### Phase 3: Verification and Validation [COMPLETE]
dependencies: [1, 2]

**Objective**: Verify changes work correctly and do not break existing functionality

**Complexity**: Low

Tasks:
- [x] Verify errors-analyst agent already uses `ensure_artifact_directory()` pattern (check lines 60-72 in errors-analyst.md)
- [x] Run /errors command in query mode to verify no regressions: `/errors --query --since 1h`
- [x] Run /errors command in report mode to verify directory creation follows standard
- [x] Check created topic directory has proper `NNN_` prefix format
- [x] Verify no empty directories created (lazy creation working)
- [x] Check error log for any new errors from the /errors command itself
- [x] Document any edge cases discovered during testing

Testing:
```bash
# Full validation sequence
cd /home/benjamin/.config

# 1. Check for empty directories before test
find .claude/specs -type d -empty 2>/dev/null | head -5

# 2. Verify agent has ensure_artifact_directory (already correct per reading)
grep -n "ensure_artifact_directory" .claude/agents/errors-analyst.md || echo "Need to verify agent pattern"

# 3. After running /errors command, verify:
# - Topic directory exists with NNN_ prefix
# - No eager-created empty directories
# - Report file created at correct path
ls -la .claude/specs/ | tail -5

# 4. Check no new errors logged
tail -5 .claude/data/logs/errors.jsonl | grep '/errors' || echo "No /errors command errors"
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
- Test `initialize_workflow_paths()` function with various error descriptions
- Verify function returns expected path variables (TOPIC_PATH, TOPIC_NUMBER)
- Confirm path format includes `NNN_` prefix

### Integration Testing
- Run `/errors --query` to verify query mode still works
- Run `/errors` report generation and verify:
  - Topic directory created with proper `NNN_` prefix
  - No empty subdirectories created during setup
  - Report file created at correct location by agent

### Regression Testing
- Ensure `/errors` command output matches expected format
- Verify error analyst agent still receives correct paths
- Check state file persistence works correctly

## Documentation Requirements

- No documentation updates required (internal implementation fix)
- Update inline comments in errors.md to document the workflow-initialization.sh integration
- Comments should explain WHAT the code does (per output-formatting standards)

## Dependencies

### Prerequisites
- `workflow-initialization.sh` library must exist and export `initialize_workflow_paths()` function
- `unified-location-detection.sh` library must provide `ensure_artifact_directory()` function
- CLAUDE_PROJECT_DIR environment variable must be set

### External Dependencies
- None (internal library integration)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| initialize_workflow_paths() function signature incompatible | Low | Medium | Check function signature in library before integration |
| Breaking existing /errors query mode | Low | High | Test query mode separately after changes |
| Agent path variable mismatch | Medium | Medium | Verify state file variables match agent expectations |
| Empty directory cleanup needed | Low | Low | Run find command to locate and remove any empty dirs |

## Rollback Plan

If issues are discovered:
1. Revert changes to errors.md using git
2. Command returns to previous behavior
3. Directory creation returns to manual pattern
4. No data loss (only affects new directory creation)
