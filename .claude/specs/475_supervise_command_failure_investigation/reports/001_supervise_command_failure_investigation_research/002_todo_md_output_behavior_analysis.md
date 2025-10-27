# TODO.md Output Behavior Analysis

## Metadata
- **Created**: 2025-10-25
- **Research Topic**: TODO.md Output Behavior in /supervise Command
- **Status**: Complete
- **Severity**: CRITICAL - Undefined function causing command failure

## Executive Summary

The /supervise command calls a function `display_completion_summary` at workflow completion (lines 693, 967, 1764, 1846), but this function is **NEVER DEFINED** in the command file or any of its sourced library files. This causes the command to fail silently or output unexpected results.

The file `.claude/specs/TODO.md` is NOT a placeholder file—it contains a full conversation transcript from a previous /supervise execution, suggesting it may be an artifact from a failed or incomplete workflow that was never cleaned up.

## Research Scope
Investigate why and when the /supervise command outputs "TODO.md" as its result, including:
- References to TODO.md in supervise.md
- Conditions triggering TODO.md output
- Fallback behaviors
- Actual content of .claude/specs/TODO.md

## Findings

### Finding 1: CRITICAL - Undefined Function `display_completion_summary`

**Location**: `/home/benjamin/.config/.claude/commands/supervise.md`

The command calls `display_completion_summary` in four critical locations:

1. **Line 693**: After skipping Phase 2 (Planning) in research-only workflows
   ```bash
   display_completion_summary
   exit 0
   ```

2. **Line 967**: After skipping Phase 2 (Planning) in research-only workflows (duplicate pattern)
   ```bash
   display_completion_summary
   exit 0
   ```

3. **Line 1764**: After skipping Phase 6 (Documentation) when no implementation occurred
   ```bash
   display_completion_summary
   exit 0
   ```

4. **Line 1846**: Final workflow completion (all workflows)
   ```bash
   display_completion_summary
   exit 0
   ```

**CRITICAL FINDING**: The function `display_completion_summary` is **NOT DEFINED ANYWHERE**.

**Evidence**:
- Not defined in `/home/benjamin/.config/.claude/commands/supervise.md`
- Not found in any sourced library files:
  - `.claude/lib/workflow-detection.sh` (sourced line 223)
  - `.claude/lib/error-handling.sh` (sourced line 231)
  - `.claude/lib/checkpoint-utils.sh` (sourced line 239)
  - `.claude/lib/unified-logger.sh` (sourced line 247)
  - `.claude/lib/topic-utils.sh` (sourced line 518)
  - `.claude/lib/detect-project-dir.sh` (sourced line 528)
- Grep search confirms: 0 matches for `display_completion_summary` in `.claude/lib/` directory

**Impact**: Every workflow execution that reaches completion will fail when attempting to call this undefined function, causing bash error: `command not found: display_completion_summary`

### Finding 2: TODO.md Is NOT a Placeholder File

**Location**: `/home/benjamin/.config/.claude/specs/TODO.md`

**Content Analysis**: The file contains 392 lines of a complete conversation transcript from a /supervise command execution about ".claude/ directory cleanup". This is NOT a template or placeholder—it's an actual workflow output.

**Key characteristics**:
- Contains full conversation including user prompt (line 1-4)
- Shows command execution with allowed tools notation (line 4)
- Includes multiple agent actions: Bash tool invocations, Read operations, file searches
- Contains a complete cleanup plan with phases and execution steps
- No TODO markers or placeholder text
- Appears to be a saved conversation log or debugging artifact

**Implications**:
1. This file should likely be in `.claude/specs/474_investigate_empty_directory_creation_and_design_la/` or similar numbered directory
2. It's tracked by git (appears in git status as deleted on current branch)
3. May be leftover from incomplete/failed workflow that didn't create proper topic directory

### Finding 3: No TODO.md References in supervise.md

**Evidence**:
- Grep search for `TODO.md` in supervise.md: 0 matches
- Grep search for `echo.*TODO` in `.claude/commands/`: 0 matches
- No fallback behavior that would output "TODO.md" as a response

**Conclusion**: The command does NOT intentionally output "TODO.md" as a result. If users are seeing "TODO.md" as output, it must be:
1. An error message from bash when undefined function fails
2. A side effect of command failure leaving partial state
3. Or unrelated to this command's design

### Finding 4: Expected Completion Behavior (If Function Existed)

Based on code analysis, the `display_completion_summary` function SHOULD:

1. Display final workflow status and artifact locations (per comment at line 1835)
2. Be called after checkpoint cleanup (lines 1838-1845):
   ```bash
   # Clean up checkpoint on successful completion
   CHECKPOINT_FILE=".claude/data/checkpoints/supervise_latest.json"
   if [ -f "$CHECKPOINT_FILE" ]; then
     rm -f "$CHECKPOINT_FILE"
     echo "Checkpoint cleaned up"
     echo ""
   fi
   ```

3. Show summary of created artifacts:
   - Research reports (OVERVIEW_PATH, REPORT_PATHS array)
   - Implementation plan (PLAN_PATH)
   - Implementation artifacts (IMPL_ARTIFACTS)
   - Debug reports (DEBUG_REPORT)
   - Summary document (SUMMARY_PATH)

4. Display appropriate subset based on WORKFLOW_SCOPE:
   - `research-only`: reports only
   - `research-and-plan`: reports + plan
   - `full-implementation`: all artifacts
   - `debug-only`: reports + debug

**Variables available at completion time**:
- `WORKFLOW_SCOPE` - workflow type
- `TOPIC_PATH` - topic directory path
- `PLAN_PATH` - line 635
- `SUMMARY_PATH` - line 644
- `OVERVIEW_PATH` - line 629
- `REPORT_PATHS[@]` - array of report paths (lines 631-634)
- `IMPL_ARTIFACTS` - implementation directory
- `DEBUG_REPORT` - debug report path

## Detailed Analysis

### Root Cause Analysis

The undefined function issue likely arose from:

1. **Refactoring Error**: Function definition removed or moved during library extraction
2. **Incomplete Implementation**: Command file written with function call but never implemented
3. **Missing Merge**: Function existed in another branch/version but wasn't merged

### Why This Causes Silent Failure

When bash encounters `display_completion_summary` without definition:
1. Bash attempts to execute as external command
2. Returns "command not found" error (exit code 127)
3. Error may not surface to user depending on error handling
4. Workflow appears complete but produces no final summary
5. User sees last output before function call, which might be partial state

### Workflow Types Affected

**ALL workflows are affected** since every completion path calls this function:

1. **Research-only** (exits at line 693 or 967)
2. **Research-and-plan** (exits at line 967 or 1764)
3. **Full-implementation** (exits at line 1846)
4. **Debug-only** (exits at line 1846)

## Recommendations

### Immediate Fix (High Priority)

1. **Create `display_completion_summary` function** in supervise.md or appropriate library file
2. **Implement proper output formatting** based on WORKFLOW_SCOPE
3. **Test all four workflow types** to ensure proper completion output
4. **Add error handling** for undefined functions (set -u or function existence checks)

### Function Implementation Specification

The function should:
```bash
display_completion_summary() {
  echo "════════════════════════════════════════════════════════"
  echo "  WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: $WORKFLOW_SCOPE"
  echo "Topic Directory: $TOPIC_PATH"
  echo ""

  case "$WORKFLOW_SCOPE" in
    research-only)
      echo "Research Reports Created:"
      for report in "${REPORT_PATHS[@]}"; do
        [ -f "$report" ] && echo "  - $report"
      done
      ;;
    research-and-plan)
      echo "Research Reports:"
      for report in "${REPORT_PATHS[@]}"; do
        [ -f "$report" ] && echo "  - $report"
      done
      echo ""
      echo "Implementation Plan:"
      echo "  - $PLAN_PATH"
      ;;
    full-implementation)
      echo "Complete Workflow Artifacts:"
      echo "  Research: ${#REPORT_PATHS[@]} reports"
      echo "  Plan: $PLAN_PATH"
      echo "  Implementation: $IMPL_ARTIFACTS"
      [ -f "$SUMMARY_PATH" ] && echo "  Summary: $SUMMARY_PATH"
      ;;
    debug-only)
      echo "Debug Workflow Artifacts:"
      echo "  Research: ${#REPORT_PATHS[@]} reports"
      echo "  Debug Report: $DEBUG_REPORT"
      ;;
  esac
  echo ""
  echo "Next Steps: Review artifacts in $TOPIC_PATH"
  echo ""
}
```

### Preventive Measures

1. **Add shellcheck/bash linting** to catch undefined function references
2. **Add integration tests** that verify completion output for each workflow type
3. **Document all required functions** in command file header
4. **Use set -u** to fail on undefined variables/functions earlier

### TODO.md Cleanup

1. **Move TODO.md** to appropriate numbered topic directory or delete if obsolete
2. **Update .gitignore** to prevent future TODO.md files in specs root
3. **Review git history** to understand why it exists in specs root

## References

### Primary Sources
- `/home/benjamin/.config/.claude/commands/supervise.md` (lines 693, 967, 1764, 1846)
- `/home/benjamin/.config/.claude/specs/TODO.md` (392-line conversation transcript)

### Related Files
- `.claude/lib/workflow-detection.sh` - Sourced but doesn't define function
- `.claude/lib/error-handling.sh` - Sourced but doesn't define function
- `.claude/lib/checkpoint-utils.sh` - Sourced but doesn't define function

### Key Code Locations
- **Function calls**: Lines 693, 967, 1764, 1846 in supervise.md
- **Path definitions**: Lines 629-649 (OVERVIEW_PATH, REPORT_PATHS, PLAN_PATH, SUMMARY_PATH)
- **Workflow scope detection**: Lines 440-507 in supervise.md

---
*Report generated by Research Specialist Agent*
*Research completed: 2025-10-25*
