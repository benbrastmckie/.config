# Two-Step Argument Pattern: Systematic Implementation Guide

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Systematic two-step argument capture pattern implementation across all commands
- **Report Type**: codebase analysis and implementation planning

## Executive Summary

This report provides a comprehensive analysis for systematically implementing the two-step argument capture pattern across all slash commands. Analysis of 15 command files reveals 13 commands using direct $1 capture that need conversion, plus 2 commands that do not use arguments. The coordinate.md implementation serves as the canonical reference (lines 18-92). A reusable library function in `.claude/lib/argument-capture.sh` can reduce per-command code from 15-25 lines to 3-5 lines while integrating with existing state-persistence.sh and workflow-state-machine.sh libraries. Key migration considerations include maintaining backward compatibility during transition and updating documentation standards.

## Findings

### 1. Current Two-Step Pattern Implementation (Canonical Reference)

The `/coordinate` command provides the canonical implementation at `/home/benjamin/.config/.claude/commands/coordinate.md:18-92`.

#### Part 1: Capture Workflow Description (Lines 18-43)

```bash
set +H  # Disable history expansion to prevent bad substitution errors
# SUBSTITUTE THE WORKFLOW DESCRIPTION IN THE LINE BELOW
# CRITICAL: Replace YOUR_WORKFLOW_DESCRIPTION_HERE with the actual workflow description from the user
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
# Use timestamp-based filename for concurrent execution safety (Spec 678 Phase 5)
WORKFLOW_TEMP_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_$(date +%s%N).txt"
echo "YOUR_WORKFLOW_DESCRIPTION_HERE" > "$WORKFLOW_TEMP_FILE"
# Save temp file path for Part 2 to read
echo "$WORKFLOW_TEMP_FILE" > "${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"
echo "Checkmark Workflow description captured to $WORKFLOW_TEMP_FILE"
```

Key characteristics:
- Uses `set +H` to disable history expansion
- Timestamp-based filename (`date +%s%N`) for concurrent execution safety
- Two-file system: content file + path file
- Requires user substitution of placeholder text

#### Part 2: Read from File (Lines 67-92)

```bash
# Read temp file path from path file (Spec 678 Phase 5: concurrent execution safety)
COORDINATE_DESC_PATH_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc_path.txt"

if [ -f "$COORDINATE_DESC_PATH_FILE" ]; then
  COORDINATE_DESC_FILE=$(cat "$COORDINATE_DESC_PATH_FILE")
else
  # Fallback to legacy fixed filename for backward compatibility
  COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
fi

if [ -f "$COORDINATE_DESC_FILE" ]; then
  WORKFLOW_DESCRIPTION=$(cat "$COORDINATE_DESC_FILE" 2>/dev/null || echo "")
else
  echo "ERROR: Workflow description file not found: $COORDINATE_DESC_FILE"
  exit 1
fi

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description is empty"
  exit 1
fi
```

Key characteristics:
- Reads path file first, then content file
- Backward compatibility fallback to legacy fixed filename
- Comprehensive error handling with diagnostics
- Empty string validation

### 2. Commands Requiring Two-Step Pattern Conversion

#### Commands with Direct $1 Argument Capture (13 commands)

| Command | Current Pattern Location | Argument Type | Migration Complexity |
|---------|--------------------------|---------------|---------------------|
| `/plan` | plan.md:128 | Feature description + report paths | Medium (multiple args) |
| `/debug` | debug.md:68 | Issue description + context reports | Medium (multiple args) |
| `/fix` | fix.md:30 | Issue description | Low |
| `/implement` | implement.md:60 | Plan file + starting phase + flags | High (complex parsing) |
| `/build` | build.md:70 | Plan file + starting phase + flags | High (complex parsing) |
| `/research-report` | research-report.md:29 | Workflow description | Low |
| `/research-plan` | research-plan.md:30 | Feature description | Low |
| `/research-revise` | research-revise.md:30 | Revision description with path | Medium (path extraction) |
| `/revise` | revise.md:29 | Revision details + flags | High (mode detection) |
| `/expand` | expand.md (implicit) | Path or phase/stage number | Medium (mode detection) |
| `/collapse` | collapse.md (implicit) | Path or phase/stage number | Medium (mode detection) |
| `/setup` | setup.md:31 | Flags + optional project dir | Medium (complex flags) |
| `/convert-docs` | convert-docs.md (implicit) | Directories + optional flags | Medium |

#### Commands Without Direct Argument Capture (2 commands)

| Command | Notes |
|---------|-------|
| `/research` | Uses `$ARGUMENTS` template variable |

### 3. Direct $1 Pattern Examples for Comparison

#### Simple Pattern (Low Complexity) - `/fix` (fix.md:30)

```bash
set +H  # CRITICAL: Disable history expansion
ISSUE_DESCRIPTION="$1"

if [ -z "$ISSUE_DESCRIPTION" ]; then
  echo "ERROR: Issue description required"
  echo "USAGE: /fix <issue-description>"
  exit 1
fi
```

**Lines of code**: 8
**Conversion effort**: Low - single argument, simple validation

#### Medium Pattern - `/plan` (plan.md:128-170)

```bash
# Parse arguments
FEATURE_DESCRIPTION="$1"
shift

# Validate feature description
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description is required"
  exit 1
fi

# Parse optional report paths
REPORT_PATHS=()
while [[ $# -gt 0 ]]; do
  REPORT_PATH="$1"
  if [[ "$REPORT_PATH" == *.md ]]; then
    if [ ! -f "$REPORT_PATH" ]; then
      echo "WARNING: Report file not found: $REPORT_PATH"
    else
      REPORT_PATHS+=("$REPORT_PATH")
    fi
  fi
  shift
done
```

**Lines of code**: 25+
**Conversion effort**: Medium - primary argument + array of optional paths

#### Complex Pattern - `/implement` (implement.md:60-78)

```bash
# Parse arguments
PLAN_FILE="$1"
STARTING_PHASE="${2:-1}"
DASHBOARD_FLAG="false"
DRY_RUN="false"
CREATE_PR="false"
SCOPE_DRIFT_DESC=""
FORCE_REPLAN="false"

shift 2 2>/dev/null || shift $# 2>/dev/null
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dashboard) DASHBOARD_FLAG="true"; shift ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --create-pr) CREATE_PR="true"; shift ;;
    --report-scope-drift) SCOPE_DRIFT_DESC="$2"; shift 2 ;;
    --force-replan) FORCE_REPLAN="true"; shift ;;
    *) shift ;;
  esac
done
```

**Lines of code**: 20+
**Conversion effort**: High - multiple positional args + flags with values

### 4. Library Integration Points

#### 4.1 state-persistence.sh (Version 1.5.0)

Location: `/home/benjamin/.config/.claude/lib/state-persistence.sh`

Key functions for integration:
- `init_workflow_state()` - Lines 130-150: Creates workflow state file
- `append_workflow_state()` - Appends key-value pairs
- `load_workflow_state()` - Retrieves workflow state in subsequent blocks

The two-step pattern should integrate with state persistence by:
1. Writing captured arguments to state file immediately after capture
2. Using state persistence for cross-bash-block access instead of separate temp files
3. Leveraging existing cleanup mechanisms (EXIT trap)

#### 4.2 workflow-state-machine.sh

Location: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

Integration opportunity:
- Argument capture can be a state machine transition
- STATE: uninitialized -> arguments_captured -> initialized
- Enables validation checkpoints at each transition

#### 4.3 workflow-initialization.sh

Location: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`

This library already provides consolidated Phase 0 initialization patterns. The two-step argument capture should be added as a prerequisite step before workflow initialization:
- Step 0: Two-step argument capture
- Step 1: Scope detection
- Step 2: Path pre-calculation
- Step 3: Directory structure creation

### 5. Reusable Library Function Design

#### Proposed Library: argument-capture.sh

Location: `/home/benjamin/.config/.claude/lib/argument-capture.sh`

```bash
#!/usr/bin/env bash
# argument-capture.sh - Two-step argument capture utilities
#
# Version: 1.0.0
# Purpose: Provide reusable two-step argument capture for reliability

# Source guard
if [ -n "${ARGUMENT_CAPTURE_SOURCED:-}" ]; then
  return 0
fi
export ARGUMENT_CAPTURE_SOURCED=1
export ARGUMENT_CAPTURE_VERSION="1.0.0"

# capture_argument_part1 - Generate Part 1 capture block
#
# Args:
#   $1 - command_name: Unique identifier for this command (e.g., "plan", "debug")
#   $2 - placeholder_text: Text to display for user substitution
#   $3 - variable_name: Name of variable to store result
#
# Output:
#   Echoes bash code block for Part 1 execution
#   Creates temp file and path file
#
capture_argument_part1() {
  local command_name="${1:-command}"
  local placeholder_text="${2:-YOUR_ARGUMENT_HERE}"
  local variable_name="${3:-CAPTURED_ARG}"

  mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
  local temp_file="${HOME}/.claude/tmp/${command_name}_arg_$(date +%s%N).txt"
  local path_file="${HOME}/.claude/tmp/${command_name}_arg_path.txt"

  echo "$placeholder_text" > "$temp_file"
  echo "$temp_file" > "$path_file"

  echo "Checkmark Argument captured to: $temp_file"
  echo "TEMP_FILE=$temp_file"
  echo "PATH_FILE=$path_file"
}

# capture_argument_part2 - Read captured argument from Part 1
#
# Args:
#   $1 - command_name: Must match Part 1 command_name
#   $2 - variable_name: Variable to export with captured value
#
# Returns:
#   0 on success, 1 on failure
#   Exports variable_name with captured value
#
capture_argument_part2() {
  local command_name="${1:-command}"
  local variable_name="${2:-CAPTURED_ARG}"

  local path_file="${HOME}/.claude/tmp/${command_name}_arg_path.txt"
  local temp_file=""

  # Read path file
  if [ -f "$path_file" ]; then
    temp_file=$(cat "$path_file")
  else
    # Fallback for backward compatibility
    temp_file="${HOME}/.claude/tmp/${command_name}_arg.txt"
  fi

  # Read content file
  if [ ! -f "$temp_file" ]; then
    echo "ERROR: Argument file not found: $temp_file" >&2
    echo "DIAGNOSTIC: Part 1 may not have executed" >&2
    return 1
  fi

  local value=$(cat "$temp_file" 2>/dev/null || echo "")

  if [ -z "$value" ]; then
    echo "ERROR: Captured argument is empty" >&2
    return 1
  fi

  # Export the variable
  export "$variable_name"="$value"
  echo "Checkmark Argument loaded: $variable_name"
  return 0
}

# cleanup_argument_files - Remove temp files after use
#
# Args:
#   $1 - command_name: Command identifier
#
cleanup_argument_files() {
  local command_name="${1:-command}"
  rm -f "${HOME}/.claude/tmp/${command_name}_arg_"*.txt 2>/dev/null
  rm -f "${HOME}/.claude/tmp/${command_name}_arg_path.txt" 2>/dev/null
}
```

#### Usage Pattern in Commands

Before (direct $1):
```bash
set +H
FEATURE_DESCRIPTION="$1"
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description required"
  exit 1
fi
```

After (two-step with library):

**Part 1 (user substitution)**:
```bash
set +H
source .claude/lib/argument-capture.sh
capture_argument_part1 "plan" "YOUR_FEATURE_DESCRIPTION_HERE" "FEATURE_DESCRIPTION"
# USER MUST: Replace YOUR_FEATURE_DESCRIPTION_HERE with actual value
```

**Part 2 (read and continue)**:
```bash
set +H
source .claude/lib/argument-capture.sh
capture_argument_part2 "plan" "FEATURE_DESCRIPTION" || exit 1
# Now FEATURE_DESCRIPTION contains the captured value
```

### 6. Documentation Updates Required

#### 6.1 command-authoring-standards.md

Location: `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:365-443`

Updates needed:
- Change "Recommendation Summary" table to mark two-step as required for ALL argument types
- Update "When to use" guidance to be prescriptive rather than optional
- Add section on using argument-capture.sh library
- Update Pattern 1 description to note it's deprecated

#### 6.2 bash-block-execution-model.md

Location: `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:934`

Updates needed:
- Expand "Example 2: Two-Step Execution Pattern" with library usage
- Add section on argument capture as execution model foundation
- Document the two-bash-block requirement

#### 6.3 New Documentation: Two-Step Argument Capture Guide

Create: `/home/benjamin/.config/.claude/docs/guides/two-step-argument-capture-guide.md`

Contents:
- Rationale for universal adoption
- Library API reference
- Migration guide for each command type
- Troubleshooting common issues
- Examples for all command patterns

### 7. Migration Strategy

#### Phase 1: Foundation (Low Risk)
1. Create `argument-capture.sh` library
2. Add unit tests for library functions
3. Update one simple command (/fix) as proof of concept
4. Validate backward compatibility with legacy patterns

#### Phase 2: Simple Commands (Medium Risk)
Commands with single primary argument:
- /research-report
- /research-plan
- /fix

#### Phase 3: Medium Commands (Medium-High Risk)
Commands with multiple arguments or path extraction:
- /plan (primary + report paths array)
- /debug (primary + context reports)
- /research-revise (revision + path extraction)
- /expand (mode detection)
- /collapse (mode detection)
- /convert-docs

#### Phase 4: Complex Commands (High Risk)
Commands with complex flag parsing:
- /implement (multiple positional + 5+ flags)
- /build (multiple positional + flags)
- /revise (mode detection + flags)
- /setup (flags with values)

### 8. Breaking Changes and Compatibility

#### Breaking Changes

1. **User Workflow Change**: All commands will require explicit user substitution in Part 1
   - Impact: Users accustomed to direct argument passing must adapt
   - Mitigation: Clear instructions, consistent placeholder format

2. **Two Bash Blocks Required**: Commands must execute Part 1 then Part 2
   - Impact: Single-block execution will fail
   - Mitigation: Clear error messages if Part 1 skipped

3. **Temp File Dependency**: Commands depend on temp file system
   - Impact: Filesystem issues could cause failures
   - Mitigation: Comprehensive error handling, clear diagnostics

#### Backward Compatibility Measures

1. **Legacy Fallback**: Keep fixed filename fallback for transition period
   ```bash
   # Fallback for backward compatibility
   TEMP_FILE="${HOME}/.claude/tmp/${command_name}_arg.txt"
   ```

2. **Gradual Rollout**: Update commands in phases, not all at once

3. **Version Detection**: Library version check before using new functions
   ```bash
   check_library_requirements "argument-capture.sh: >=1.0.0" || exit 1
   ```

### 9. Potential Issues and Mitigations

#### Issue 1: Increased Command Execution Time
- **Risk**: Two bash blocks = ~50-100ms additional overhead
- **Mitigation**: Minor impact compared to total command runtime (seconds to minutes)

#### Issue 2: Temp File Cleanup
- **Risk**: Orphaned temp files if command fails between Part 1 and Part 2
- **Mitigation**:
  - EXIT trap in Part 1 for cleanup on failure
  - Daily cleanup cron job for ~/.claude/tmp/

#### Issue 3: Concurrent Command Execution Conflicts
- **Risk**: Multiple commands writing to same path file
- **Mitigation**:
  - Timestamp-based content filenames (already in pattern)
  - Command-specific path file names

#### Issue 4: Special Characters in Arguments
- **Risk**: Characters like `$`, backtick, newlines in user input
- **Mitigation**: This is precisely why two-step is more reliable - user types directly into file

## Recommendations

### Recommendation 1: Create Reusable Library First

Create `/home/benjamin/.config/.claude/lib/argument-capture.sh` with the design specified in Section 5. This library should:
- Integrate with state-persistence.sh for state management
- Provide clear error messages with diagnostics
- Support concurrent execution via timestamp-based filenames
- Include cleanup utilities

**Priority**: P0 - Foundation for all other work
**Estimated effort**: 4-6 hours including tests

### Recommendation 2: Implement Phased Migration

Execute migration in 4 phases as specified in Section 7:
1. Foundation (1-2 days)
2. Simple commands (1 day)
3. Medium commands (2-3 days)
4. Complex commands (3-4 days)

**Total estimated effort**: 7-11 days
**Priority**: P1 - Execute sequentially to manage risk

### Recommendation 3: Update Documentation Standards

Update command-authoring-standards.md to:
- Make two-step pattern REQUIRED for all user-facing arguments
- Document the argument-capture.sh library API
- Remove "project choice" flexibility - standardize on two-step
- Add migration checklist for existing commands

**Priority**: P1 - Concurrent with Phase 1 implementation
**Estimated effort**: 2-3 hours

### Recommendation 4: Create Migration Testing Suite

Create test cases that verify:
- Argument capture works with special characters
- Concurrent execution doesn't conflict
- Error messages are clear and actionable
- Backward compatibility fallbacks work

**Location**: `/home/benjamin/.config/.claude/tests/test_argument_capture.sh`
**Priority**: P0 - Required before migration
**Estimated effort**: 3-4 hours

### Recommendation 5: Implement Monitoring for Failures

Add logging to track:
- Two-step capture success/failure rates
- Common failure modes
- User friction points

**Integration**: Use existing unified-logger.sh
**Priority**: P2 - After initial rollout
**Estimated effort**: 1-2 hours

### Recommendation 6: Create Visual Migration Guide

Create a decision matrix diagram showing:
- Which commands need which migration approach
- Dependency order for migration
- Testing checkpoints

**Format**: Mermaid diagram in documentation
**Priority**: P2 - Helpful but not blocking
**Estimated effort**: 1 hour

## References

### Primary Implementation Files
- `/home/benjamin/.config/.claude/commands/coordinate.md:18-92` - Canonical two-step pattern
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:1-150` - State management integration
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - State machine integration
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:1-100` - Initialization patterns

### Commands Analyzed for Direct $1 Usage
- `/home/benjamin/.config/.claude/commands/plan.md:128-170` - Medium complexity migration
- `/home/benjamin/.config/.claude/commands/debug.md:68-74` - Medium complexity migration
- `/home/benjamin/.config/.claude/commands/fix.md:30-56` - Low complexity migration
- `/home/benjamin/.config/.claude/commands/implement.md:60-78` - High complexity migration
- `/home/benjamin/.config/.claude/commands/build.md:70-80` - High complexity migration
- `/home/benjamin/.config/.claude/commands/research-report.md:29-60` - Low complexity migration
- `/home/benjamin/.config/.claude/commands/research-plan.md:30-61` - Low complexity migration
- `/home/benjamin/.config/.claude/commands/research-revise.md:30-74` - Medium complexity migration
- `/home/benjamin/.config/.claude/commands/revise.md:29-41` - High complexity migration
- `/home/benjamin/.config/.claude/commands/expand.md:59-100` - Medium complexity migration
- `/home/benjamin/.config/.claude/commands/collapse.md:80-100` - Medium complexity migration
- `/home/benjamin/.config/.claude/commands/setup.md:31-61` - Medium complexity migration
- `/home/benjamin/.config/.claude/commands/convert-docs.md` - Medium complexity migration

### Documentation References
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:365-443` - Current patterns documentation
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:934` - Two-step execution example
- `/home/benjamin/.config/.claude/specs/757_research_the_two_step_pattern_from_coordinate_as_o/reports/001_two_step_argument_pattern_analysis.md` - Previous research report

### Previous Research Report
- `/home/benjamin/.config/.claude/specs/757_research_the_two_step_pattern_from_coordinate_as_o/reports/001_two_step_argument_pattern_analysis.md` - Original analysis recommending against universal adoption (user has overridden this recommendation)

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001_since_reliability_is_paramount_the_two_s_plan.md](../plans/001_since_reliability_is_paramount_the_two_s_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
