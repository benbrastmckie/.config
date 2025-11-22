# /errors Command Directory Protocol Compliance Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Refactor /errors command to comply with directory protocol standards
- **Scope**: Single command file modification with library integration
- **Estimated Phases**: 4
- **Estimated Hours**: 3-4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Complexity Score**: 17 (Tier 1: Single File)
- **Structure Level**: 0
- **Research Reports**:
  - [/errors Command Directory Protocol Refactor Research](/home/benjamin/.config/.claude/specs/906_errors_command_directory_protocols/reports/001_errors_command_refactor_research.md)
  - [/errors Command Directory Protocols Non-Compliance Research](/home/benjamin/.config/.claude/specs/905_error_command_directory_protocols/reports/001_error_command_directory_protocols.md)

## Overview

Refactor the `/errors` command to comply with the project's directory protocol standards. The current implementation uses undefined functions (`get_next_topic_number`, `generate_topic_name`) and manual `mkdir -p` calls instead of the standard `workflow-initialization.sh` library with `initialize_workflow_paths()`.

### Goals
1. Source `workflow-initialization.sh` library alongside existing libraries
2. Replace manual directory creation code with `initialize_workflow_paths()` call
3. Remove eager `mkdir -p` call to comply with lazy directory creation standard
4. Ensure topic directories use standard `NNN_topic_name` format via atomic allocation
5. Add proper error logging for initialization failures

## Research Summary

Key findings from the research reports:

**Finding 1: Undefined Functions** (from 906 report)
- Lines 266-268 use `get_next_topic_number()` and `generate_topic_name()` which do not exist in any sourced library
- These appear to be placeholder stubs that were never implemented
- Results in exit code 127 errors when functions are called but not found

**Finding 2: Missing workflow-initialization.sh** (from both reports)
- The `/errors` command only sources `error-handling.sh`, `workflow-state-machine.sh`, and `unified-location-detection.sh`
- Missing `workflow-initialization.sh` which provides `initialize_workflow_paths()`
- The `/repair` command (lines 139-142) correctly sources this library

**Finding 3: Eager mkdir Violation** (from 905 report)
- Line 271 uses `mkdir -p "${TOPIC_DIR}/reports"` during setup
- Violates lazy directory creation standard documented in directory-protocols.md lines 245-365
- Creates empty directories that persist when workflows fail

**Finding 4: Missing NNN_ Prefix** (from both reports)
- Output shows directories created as `errors_plan_analysis` instead of `905_errors_plan_analysis`
- Standard format requires `NNN_topic_name/` with three-digit sequential numbers

**Reference Implementation**: The `/repair` command (lines 122-142, 223-242) correctly implements all patterns.

## Success Criteria
- [ ] /errors command sources workflow-initialization.sh library
- [ ] /errors command uses initialize_workflow_paths() for topic directory setup
- [ ] No eager mkdir calls in command setup (lazy creation by agents)
- [ ] Topic directories created with NNN_topic_name format
- [ ] Proper error logging when initialization fails
- [ ] Command metadata updated to list workflow-initialization.sh dependency
- [ ] /errors command produces identical functional behavior (report generation)
- [ ] All existing tests pass (if any)

## Technical Design

### Architecture Overview

The refactor aligns `/errors` with the standard workflow command pattern:

```
Current Flow (Non-Compliant):
  1. Source error-handling.sh, workflow-state-machine.sh, unified-location-detection.sh
  2. Call undefined functions (get_next_topic_number, generate_topic_name)
  3. Manually create directories with mkdir -p
  4. Pass incorrect paths to agent

Refactored Flow (Compliant):
  1. Source all four required libraries including workflow-initialization.sh
  2. Call initialize_workflow_paths() which:
     - Uses atomic topic allocation (prevents race conditions)
     - Generates proper NNN_topic_name format via LLM or fallback
     - Creates only topic root directory (no subdirectories)
     - Exports all path variables (TOPIC_PATH, RESEARCH_DIR, etc.)
  3. Pass correct paths to agent (agent handles lazy creation)
```

### Key Components

1. **Library Sourcing Section** (lines 233-241):
   - Add `workflow-initialization.sh` after existing library sources
   - Include proper error handling with exit on failure

2. **Directory Creation Section** (lines 265-274):
   - Replace 10 lines of manual code with ~20 lines using `initialize_workflow_paths()`
   - Include proper error logging via `log_command_error()`
   - Remove `mkdir -p` call entirely

3. **Path Variable Assignment**:
   - Use exported variables from `initialize_workflow_paths()`: `TOPIC_PATH`, etc.
   - Assign `RESEARCH_DIR` and `REPORT_PATH` from exported variables

### Reference Pattern from /repair Command

```bash
# From /repair.md lines 139-142 (library sourcing)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}

# From /repair.md lines 223-238 (initialization)
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "$RESEARCH_COMPLEXITY" ""
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

# Path assignment (no mkdir)
RESEARCH_DIR="${TOPIC_PATH}/reports"
```

## Implementation Phases

### Phase 1: Add workflow-initialization.sh Library Sourcing [NOT STARTED]
dependencies: []

**Objective**: Add workflow-initialization.sh library to command's sourcing section to enable initialize_workflow_paths() function.

**Complexity**: Low

Tasks:
- [ ] Read /home/benjamin/.config/.claude/commands/errors.md to verify current state
- [ ] Locate library sourcing section (approximately lines 233-241)
- [ ] Add workflow-initialization.sh sourcing after line 241 (after unified-location-detection.sh)
- [ ] Include proper error handling with exit on failure
- [ ] Verify the library path uses ${CLAUDE_PROJECT_DIR} variable consistently

**Code Change** (insert after line 241):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}
```

Testing:
```bash
# Verify library sourcing syntax
bash -n /home/benjamin/.config/.claude/commands/errors.md 2>&1 | head -20

# Verify library file exists
test -f /home/benjamin/.config/.claude/lib/workflow/workflow-initialization.sh && echo "OK"
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Replace Manual Directory Creation with initialize_workflow_paths() [NOT STARTED]
dependencies: [1]

**Objective**: Replace manual topic directory creation code (lines 265-274) with standard initialize_workflow_paths() call.

**Complexity**: Medium

Tasks:
- [ ] Identify the exact lines to replace (265-274 in current errors.md)
- [ ] Remove the undefined function calls (get_next_topic_number, generate_topic_name)
- [ ] Remove the manual TOPIC_DIR construction
- [ ] Remove the mkdir -p call (line 271)
- [ ] Add initialize_workflow_paths() call with proper arguments
- [ ] Add error handling with log_command_error() on failure
- [ ] Use exported TOPIC_PATH variable from initialize_workflow_paths()
- [ ] Update RESEARCH_DIR assignment to use exported variable
- [ ] Update REPORT_PATH assignment to use new path structure

**Code to Remove** (lines 265-274):
```bash
# Get topic number and directory using LLM agent
TOPIC_NUMBER=$(get_next_topic_number)
TOPIC_NAME=$(generate_topic_name "$ERROR_DESCRIPTION")
TOPIC_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs/${TOPIC_NUMBER}_${TOPIC_NAME}"

# Create topic directory structure
mkdir -p "${TOPIC_DIR}/reports" 2>/dev/null

# Determine report path
REPORT_PATH="${TOPIC_DIR}/reports/001_error_report.md"
```

**Code to Add** (replacement):
```bash
# Initialize workflow paths using standard library function
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "1" ""
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

# Use exported path variables (no mkdir needed - agents handle lazy creation)
RESEARCH_DIR="${TOPIC_PATH}/reports"
REPORT_PATH="${RESEARCH_DIR}/001_error_report.md"
```

Testing:
```bash
# Verify no syntax errors after change
bash -n /home/benjamin/.config/.claude/commands/errors.md 2>&1 | head -20

# Verify no mkdir -p calls remain in the command (except for legitimate uses)
grep -n "mkdir -p" /home/benjamin/.config/.claude/commands/errors.md

# Manual test: Run /errors and verify topic directory format
# Expected: .claude/specs/NNN_error_analysis/reports/ format
```

**Expected Duration**: 1.5 hours

---

### Phase 3: Update State Persistence and Agent Invocation [NOT STARTED]
dependencies: [2]

**Objective**: Ensure state file persistence and agent invocation use the new path variables correctly.

**Complexity**: Low

Tasks:
- [ ] Verify STATE_FILE creation section uses TOPIC_PATH correctly
- [ ] Update any references to TOPIC_DIR to use TOPIC_PATH
- [ ] Verify REPORT_PATH in state file uses new variable
- [ ] Ensure agent prompt receives correct REPORT_PATH
- [ ] Update Block 2 if needed to match new variable names

**Verification Points**:
- Line 285-296: State file creation should use TOPIC_PATH not TOPIC_DIR
- Line 288: REPORT_PATH should reference new path structure
- Line 289: Replace TOPIC_DIR with TOPIC_PATH in state persistence
- Agent invocation prompt should receive correct REPORT_PATH

**Code Change** (in state file creation, around line 287-296):
```bash
# Update state file to use TOPIC_PATH instead of TOPIC_DIR
STATE_FILE="${HOME}/.claude/tmp/errors_state_${WORKFLOW_ID}.sh"
mkdir -p "$(dirname "$STATE_FILE")"
cat > "$STATE_FILE" << EOF
REPORT_PATH="${REPORT_PATH}"
TOPIC_PATH="${TOPIC_PATH}"
FILTER_ARGS="${FILTER_ARGS}"
COMMAND_FILTER="${COMMAND_FILTER}"
SINCE_FILTER="${SINCE_FILTER}"
TYPE_FILTER="${TYPE_FILTER}"
WORKFLOW_ID="${WORKFLOW_ID}"
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR}"
EOF
```

Testing:
```bash
# Verify state file variable names match expected format
grep -E "(TOPIC_DIR|TOPIC_PATH)" /home/benjamin/.config/.claude/commands/errors.md

# Check Block 2 for variable consistency
grep -A 20 "Block 2" /home/benjamin/.config/.claude/commands/errors.md | grep -E "(TOPIC|REPORT)"
```

**Expected Duration**: 0.5 hours

---

### Phase 4: Update Command Metadata and Documentation [NOT STARTED]
dependencies: [3]

**Objective**: Update command frontmatter to document the new library dependency and verify compliance.

**Complexity**: Low

Tasks:
- [ ] Update library-requirements in frontmatter (lines 8-12)
- [ ] Add workflow-initialization.sh to the requirements list
- [ ] Verify all tests pass after changes
- [ ] Run directory protocol compliance check
- [ ] Document the change in any relevant changelogs

**Code Change** (in frontmatter, around line 8-12):
```yaml
library-requirements:
  - workflow-state-machine.sh: ">=2.0.0"
  - error-handling.sh: ">=1.0.0"
  - unified-location-detection.sh: ">=1.0.0"
  - workflow-initialization.sh: ">=1.0.0"
```

Testing:
```bash
# Verify frontmatter is valid YAML
head -20 /home/benjamin/.config/.claude/commands/errors.md

# Verify no eager mkdir calls remain
grep "mkdir -p.*reports" /home/benjamin/.config/.claude/commands/errors.md || echo "PASS: No eager mkdir"

# Integration test: Run /errors and verify output
# Expected: Report created at .claude/specs/NNN_topic/reports/001_error_report.md
```

**Acceptance Criteria**:
- [ ] Frontmatter lists workflow-initialization.sh as a dependency
- [ ] No grep matches for eager `mkdir -p` on artifact directories
- [ ] Command executes without exit code 127 errors
- [ ] Topic directory created with NNN_ prefix format
- [ ] Report path matches expected pattern

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
- Bash syntax validation: `bash -n errors.md`
- Library sourcing verification: Check all four libraries source successfully
- Variable export verification: Confirm TOPIC_PATH, RESEARCH_DIR exported

### Integration Testing
- Run `/errors` command and verify:
  1. No exit code 127 errors (undefined function calls)
  2. Topic directory uses NNN_topic_name format
  3. Reports directory created by agent (not command)
  4. Report file created at correct path

### Regression Testing
- Query mode (`/errors --query`) still functions correctly
- Summary mode (`/errors --query --summary`) still functions correctly
- Filter options work as expected

### Compliance Testing
```bash
# Verify no eager mkdir on artifact directories
grep -E "mkdir -p.*/(reports|debug|plans|summaries)" .claude/commands/errors.md

# Verify atomic topic allocation used
grep -q "initialize_workflow_paths" .claude/commands/errors.md && echo "PASS"

# Verify proper error logging
grep -q "log_command_error" .claude/commands/errors.md && echo "PASS"
```

## Documentation Requirements

1. **No new documentation required** - This is a refactor to compliance, not a new feature
2. **Update command if behavior changes** - None expected
3. **Changelog entry** (if maintained):
   - "fix(errors): Refactor /errors command to comply with directory protocol standards"
   - "Replaced manual directory creation with initialize_workflow_paths()"
   - "Topic directories now use standard NNN_topic_name format"

## Dependencies

### External Dependencies
- `workflow-initialization.sh` library exists at expected path
- `initialize_workflow_paths()` function works as documented
- `log_command_error()` function available from error-handling.sh
- `jq` available for JSON construction in error logging

### Internal Dependencies
- Phase 1 must complete before Phase 2 (library must be sourced before using)
- Phase 2 must complete before Phase 3 (paths must be set before state persistence)
- Phase 3 must complete before Phase 4 (functionality must work before documentation)

### Prerequisites
- Read access to /home/benjamin/.config/.claude/commands/errors.md
- Write access to same file
- Understanding of workflow-initialization.sh API

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Library API change | Low | Medium | Check workflow-initialization.sh version |
| State file format incompatible | Low | Medium | Update Block 2 variable references |
| Agent expects different path format | Low | Low | Verify errors-analyst.md compatibility |
| Existing workflows broken | Low | Medium | Test with current error log |

## Rollback Plan

If issues arise after deployment:

1. **Immediate Rollback**: Revert changes to errors.md using git:
   ```bash
   git checkout HEAD -- .claude/commands/errors.md
   ```

2. **Diagnostic**: Check error logs for specific failure:
   ```bash
   /errors --query --command /errors --limit 5
   ```

3. **Incremental Fix**: Apply phases one at a time if needed

## Implementation Notes

### Key Differences from /repair Command

The `/errors` command has a simpler workflow than `/repair`:
- Single-phase workflow (research-only, no planning)
- Lower complexity (1 instead of 2-4)
- Single report output (not multiple)

The initialization call should use:
```bash
initialize_workflow_paths "$ERROR_DESCRIPTION" "research-only" "1" ""
```

Where:
- `$ERROR_DESCRIPTION`: User-provided description or "error analysis"
- `"research-only"`: Workflow scope (no planning phase)
- `"1"`: Research complexity (single report)
- `""`: Empty classification result (use fallback naming)

### Lazy Directory Creation Compliance

The key compliance requirement is that the command MUST NOT create `reports/` directory during setup. The errors-analyst agent will create it when writing the report using:

```bash
# In errors-analyst.md agent
source .claude/lib/core/unified-location-detection.sh
ensure_artifact_directory "$REPORT_PATH" || exit 1
```

The agent already has this pattern (lines 60-72 per research report), so no agent changes are needed.
