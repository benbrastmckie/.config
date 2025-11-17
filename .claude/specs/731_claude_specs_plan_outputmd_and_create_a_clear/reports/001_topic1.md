# Root Cause Analysis: Plan Command Failures

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Root cause analysis of plan command failures
- **Report Type**: codebase analysis

## Executive Summary

The plan command failures in `/home/benjamin/.config/.claude/specs/plan_output.md` are caused by bash shell context isolation issues where sourced library functions become unavailable across separate Bash tool invocations. The root cause is that each Bash tool call creates a fresh shell session, losing all sourced functions. The command succeeded on retry only after combining all library sourcing and execution into a single bash invocation with `set +H` to prevent history expansion errors.

## Findings

### Finding 1: Shell Context Isolation Between Bash Tool Calls

**Location**: `/home/benjamin/.config/.claude/specs/plan_output.md:162-174`

**Error Pattern**:
```
Error: Exit code 1
/run/current-system/sw/bin/bash: line 49: detect_project_root: command not found
/run/current-system/sw/bin/bash: line 50: detect_specs_directory: command not found
/run/current-system/sw/bin/bash: line 57: allocate_and_create_topic: command not found
```

**Root Cause**: The first Bash invocation (lines 38-104) sources all required libraries:
- `detect-project-dir.sh`
- `workflow-state-machine.sh`
- `state-persistence.sh`
- `error-handling.sh`
- `verification-helpers.sh`
- `unified-location-detection.sh`
- `complexity-utils.sh`
- `metadata-extraction.sh`

However, the second Bash invocation (lines 108-161) attempts to use functions from `unified-location-detection.sh` without re-sourcing:

```bash
PROJECT_ROOT=$(detect_project_root)          # Line 120 - function not found
SPECS_DIR=$(detect_specs_directory "$PROJECT_ROOT")  # Line 121 - function not found
TOPIC_DIR=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")  # Line 128 - function not found
```

These functions are defined in `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`:
- `detect_project_root()` at line 88
- `detect_specs_directory()` at line 125
- `allocate_and_create_topic()` at line 235

**Why This Happens**: Each Bash tool invocation creates a completely fresh shell environment. Functions sourced in one invocation do NOT persist to subsequent invocations.

### Finding 2: Successful Pattern - Combined Library Sourcing and Execution

**Location**: `/home/benjamin/.config/.claude/specs/plan_output.md:178-183`

The command succeeded on the second attempt using this pattern:

```bash
● Bash(set +H…)
  ⎿ ✓ Phase 0: Orchestrator initialized
      Project: /home/benjamin/.config
      Topic: 729|/home/benjamin/.config/.claude/specs/729_research_the
```

This indicates that the agent combined library sourcing AND function usage into a single Bash invocation, preventing the context isolation issue.

### Finding 3: History Expansion Syntax Error

**Location**: `/home/benjamin/.config/.claude/specs/plan_output.md:269-275`

```
Error: Exit code 1
/run/current-system/sw/bin/bash: line 58: ${!RESEARCH_TOPICS[@]}: bad substitution
/run/current-system/sw/bin/bash: line 61: ${!RESEARCH_TOPICS[@]}: bad substitution
```

**Root Cause**: Bash history expansion interprets `!` character in array iteration syntax `"${!ARRAY[@]}"` as a history expansion command when history mode is enabled.

**Solution**: The `set +H` command at line 38 disables history expansion, which is required for the plan command's bash code that uses array iteration patterns like:

```bash
for i in "${!RESEARCH_TOPICS[@]}"; do
  # Array index iteration
done
```

This syntax is used in `/home/benjamin/.config/.claude/commands/plan.md` at:
- Line 364: `for i in "${!RESEARCH_TOPICS[@]}"; do`
- Line 387: `for i in "${!RESEARCH_TOPICS[@]}"; do`

### Finding 4: Plan Command Design vs Execution Reality

**Location**: `/home/benjamin/.config/.claude/commands/plan.md:18-186`

The plan command is structured as a multi-phase workflow with separate bash blocks:

**Phase 0 (lines 23-186)**: Sources all libraries
**Phase 1 (lines 189-298)**: Uses complexity analysis functions
**Phase 1.5 (lines 300-524)**: Uses location detection functions

This design assumes functions sourced in Phase 0 will be available in subsequent phases. However, if each phase is executed as a separate Bash tool call, this assumption breaks.

**Comparison with Working Implementation**:
At line 178 of plan_output.md, the successful execution uses `Bash(set +H…)` where the ellipsis indicates a combined script that includes both sourcing and execution in one call.

### Finding 5: Library Dependency Chain

**Location**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:1-10`

The unified-location-detection.sh library header states:
```bash
# Dependencies: None (pure bash, no external utilities except jq for JSON output)
```

However, the plan command sources it as part of a dependency chain at `/home/benjamin/.config/.claude/commands/plan.md:65-84`:

1. workflow-state-machine.sh (FIRST)
2. state-persistence.sh (SECOND)
3. error-handling.sh (THIRD)
4. verification-helpers.sh (FOURTH)
5. unified-location-detection.sh (FIFTH)
6. complexity-utils.sh (SIXTH)
7. metadata-extraction.sh (SEVENTH)

The ordering suggests potential dependencies between these libraries that aren't documented in the unified-location-detection.sh header.

## Recommendations

### Recommendation 1: Combine Library Sourcing with Execution in Single Bash Calls

**Priority**: CRITICAL

Modify the plan command to combine all library sourcing and dependent code execution into single Bash tool invocations. This prevents shell context loss between tool calls.

**Implementation Pattern**:
```bash
Bash(
  set +H  # Disable history expansion

  # Source all required libraries
  source /path/to/lib1.sh
  source /path/to/lib2.sh

  # Execute code that uses sourced functions
  RESULT=$(function_from_lib1)
  echo "Result: $RESULT"
)
```

**Files to Modify**:
- `/home/benjamin/.config/.claude/commands/plan.md` - Restructure phases into consolidated bash blocks

### Recommendation 2: Add Explicit set +H to All Bash Blocks Using Array Syntax

**Priority**: HIGH

Ensure every Bash invocation that uses `"${!ARRAY[@]}"` syntax begins with `set +H` to prevent history expansion errors.

**Affected Code Locations**:
- `/home/benjamin/.config/.claude/commands/plan.md:364` - Array iteration in research delegation
- `/home/benjamin/.config/.claude/commands/plan.md:387` - Array iteration in agent invocation loop

### Recommendation 3: Document Shell Context Isolation in Plan Command Guide

**Priority**: MEDIUM

Add explicit warnings to `.claude/docs/guides/plan-command-guide.md` about shell context isolation between Bash tool calls and the requirement to combine sourcing with execution.

**Documentation Structure**:
```markdown
## Critical Implementation Notes

### Shell Context Isolation
Each Bash tool invocation creates a fresh shell environment. Functions sourced
in one invocation are NOT available in subsequent invocations.

**WRONG Pattern**:
Bash(source lib.sh)        # Sources function
Bash(my_function)          # ERROR: function not found

**CORRECT Pattern**:
Bash(
  source lib.sh
  my_function              # Works - same shell session
)
```

### Recommendation 4: Create Bash Invocation Standards Document

**Priority**: MEDIUM

Create `.claude/docs/reference/bash-invocation-standards.md` documenting:
- Shell context isolation behavior
- Library sourcing patterns
- Array syntax requirements (`set +H`)
- Multi-command bash block patterns
- Common pitfalls and solutions

### Recommendation 5: Add Verification Check for Library Function Availability

**Priority**: LOW

Add defensive checks after library sourcing to verify critical functions are available:

```bash
# After sourcing libraries
if ! type -t detect_project_root >/dev/null 2>&1; then
  echo "ERROR: detect_project_root function not available"
  echo "DIAGNOSTIC: unified-location-detection.sh may not have been sourced"
  exit 1
fi
```

This provides clearer error messages when library sourcing fails silently.

## References

### Primary Error Source
- `/home/benjamin/.config/.claude/specs/plan_output.md:162-174` - Initial failure with "command not found"
- `/home/benjamin/.config/.claude/specs/plan_output.md:269-275` - History expansion syntax error
- `/home/benjamin/.config/.claude/specs/plan_output.md:178-183` - Successful retry with combined execution

### Plan Command Implementation
- `/home/benjamin/.config/.claude/commands/plan.md:1-947` - Complete command specification
- `/home/benjamin/.config/.claude/commands/plan.md:18-186` - Phase 0: Library sourcing block
- `/home/benjamin/.config/.claude/commands/plan.md:134-147` - Function calls requiring sourced libraries
- `/home/benjamin/.config/.claude/commands/plan.md:364` - Array iteration syntax requiring `set +H`
- `/home/benjamin/.config/.claude/commands/plan.md:387` - Second array iteration location

### Library Files
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:88-106` - `detect_project_root()` function
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:125-149` - `detect_specs_directory()` function
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:235-240` - `allocate_and_create_topic()` function
- `/home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-50` - Project directory detection utility

### Supporting Context
- `/home/benjamin/.config/CLAUDE.md` - Project standards and configuration
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md` - Plan command documentation (referenced in plan.md:11)
