# Phase 4 Implementation Specification: Automatic Debug Integration for Test Failures

## Metadata
- **Phase Number**: 4
- **Parent Plan**: Reduce Implementation Interruptions Implementation Plan
- **Objective**: Modify test failure handling to automatically invoke /debug and present user choice
- **Complexity**: High (score: 8)
- **Status**: Specification Complete - Ready for Implementation
- **Estimated Lines**: 350-400 lines of implementation
- **Primary File**: `/home/benjamin/.config/.claude/commands/implement.md`

## Implementation Overview

This phase introduces automatic debugging workflow integration into the `/implement` command. When a phase fails tests, the system will:

1. Automatically invoke `/debug` via SlashCommand tool
2. Parse the debug report to extract findings
3. Present a formatted summary with four user choices
4. Handle each choice branch appropriately
5. Update the plan with debugging annotations

The implementation modifies Step 3.3 (Enhanced Error Analysis) in implement.md to add automatic debug invocation and user interaction immediately after test failures are detected.

## Detailed Implementation Steps

### Part 1: Test Failure Detection Point (Lines 591-651 in implement.md)

**Current Location**: Step 3.3 "Enhanced Error Analysis (if tests fail)"

**Existing Code Structure**:
```markdown
### 3.3. Enhanced Error Analysis (if tests fail)

If tests fail, provide enhanced error messages with fix suggestions:

**Step 1: Capture Error Output**
- Capture full test output including error messages
- Identify failed tests and error locations

**Step 2: Run Error Analysis**
```bash
# Analyze error output with enhanced error tool
.claude/lib/analyze-error.sh "$ERROR_OUTPUT"
```

**Step 3: Display Enhanced Error Message**
[Current enhanced error display]

**Step 4: Graceful Degradation**
If tests fail:
- Document what succeeded vs. what failed
- Preserve partial progress
- Suggest next steps:
  - `/debug "<error description>"` for investigation
  - Manual fixes based on suggestions
  - Review recent changes with git diff
```

**Implementation Task 1.1**: Add new Step 5 after Step 4 for automatic debug integration

**New Section Location**: After line 651 (end of Step 4: Graceful Degradation)

### Part 2: Automatic /debug Invocation (New Step 5)

**Insert Location**: After line 651 in implement.md

**New Content**:

```markdown
### 3.3.1. Automatic Debug Integration (if tests fail)

**Step 5: Automatic Debug Analysis and User Choice**

When tests fail, automatically invoke `/debug` to perform root cause analysis:

**Step 5.1: Progress Marker**
Display progress indicator before debug invocation:
```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PROGRESS: Running debug analysis for test failure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Step 5.2: Extract Error Description**
Build error description from test output for debug command:
```bash
# Extract first 3 lines of meaningful error output
ERROR_DESC=$(echo "$ERROR_OUTPUT" | grep -E "Error:|FAILED:|AssertionError" | head -3 | tr '\n' ' ')

# If no structured errors found, use generic description
if [ -z "$ERROR_DESC" ]; then
  ERROR_DESC="Phase $CURRENT_PHASE tests failed with errors"
fi

# Escape quotes and special characters for command invocation
ERROR_DESC_ESCAPED="${ERROR_DESC//\"/\\\"}"
ERROR_DESC_ESCAPED="${ERROR_DESC_ESCAPED//\$/\\\$}"
```

**Error Description Examples**:
- `"Error: Module not found: crypto-utils Expected function, got nil"`
- `"AssertionError: Expected 5, got 3 Test timeout after 30 seconds"`
- `"FAILED: test_authentication.py::test_login - Connection refused"`

**Step 5.3: Invoke /debug via SlashCommand**
Invoke the `/debug` command with error description and plan path:
```bash
# Build debug command with escaped error description
DEBUG_CMD="/debug \"$ERROR_DESC_ESCAPED\" \"$PLAN_PATH\""

# Invoke via SlashCommand tool (timeout: 60 seconds for debug analysis)
# Note: This is pseudocode - actual implementation uses SlashCommand tool
DEBUG_RESULT=$(invoke_slash_command "$DEBUG_CMD" --timeout 60000)

# Capture exit status
DEBUG_STATUS=$?
```

**Invocation Pattern**: The actual invocation uses the SlashCommand tool available in implement.md's allowed-tools. The command will be:
```
/debug "Phase 3 tests failed with errors: Error: Module not found: crypto-utils" "/path/to/plan.md"
```

**Timeout Handling**: Debug analysis can take 30-60 seconds. Set appropriate timeout to avoid premature failure.

**Step 5.4: Parse Debug Response**

The `/debug` command creates a report and annotates the plan. Extract key information:

```bash
# Check if debug command succeeded
if [ "$DEBUG_STATUS" -ne 0 ]; then
  echo "Warning: Debug analysis failed to complete"
  echo "Error: $DEBUG_RESULT"
  echo "Falling back to manual debugging workflow"
  # Continue with existing graceful degradation (Step 4)
  return 1
fi

# Extract debug report path from debug command output
# Expected pattern: "Debug report created: specs/reports/NNN_debug_*.md"
DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -o "specs/reports/[0-9]*_debug_[^[:space:]]*.md" | head -1)

# Validate report was created
if [ -z "$DEBUG_REPORT_PATH" ] || [ ! -f "$DEBUG_REPORT_PATH" ]; then
  echo "Warning: Debug report not found at expected location"
  echo "Expected: specs/reports/NNN_debug_*.md"
  echo "Debug command output: $DEBUG_RESULT"
  return 1
fi

# Read debug report to extract root cause and recommendations
if [ -f "$DEBUG_REPORT_PATH" ]; then
  # Extract root cause from "Root Cause Analysis" section
  ROOT_CAUSE=$(sed -n '/### Root Cause Analysis/,/###/p' "$DEBUG_REPORT_PATH" |
               grep -v "###" |
               head -3 |
               tr '\n' ' ' |
               sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Extract recommended fix from "Recommendations" section
  RECOMMENDED_FIX=$(sed -n '/## Recommendations/,/##/p' "$DEBUG_REPORT_PATH" |
                    grep -E "^- " |
                    head -1 |
                    sed 's/^- //')
else
  ROOT_CAUSE="Unknown - debug report parsing failed"
  RECOMMENDED_FIX="Review debug report manually"
fi
```

**Debug Report Structure** (from debug.md lines 72-116):
```markdown
# Debug Report: [Issue Title]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Issue**: [Brief description]
- **Severity**: [Critical|High|Medium|Low]

## Problem Statement
[Detailed description]

## Investigation Process
[Methodology]

## Findings

### Root Cause Analysis
[Primary cause identification]     ← EXTRACT THIS

### Contributing Factors
[Secondary issues]

## Proposed Solutions

### Option 1: [Solution Name]
[Description, pros, cons]

## Recommendations
[Prioritized actions]              ← EXTRACT FIRST ITEM

## Next Steps
[Action items]
```

**Step 5.5: Display Formatted Summary with User Choice**

Present a formatted summary box with debugging findings and four action options:

```bash
# Get phase name for display
PHASE_NAME=$(grep "^### Phase $CURRENT_PHASE:" "$PLAN_PATH" | head -1 | sed "s/^### Phase $CURRENT_PHASE: //")

# Display summary box
cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    TEST FAILURE DEBUG SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Failed Phase: Phase $CURRENT_PHASE: $PHASE_NAME

Error Description:
  $(echo "$ERROR_DESC" | fold -w 60 -s | sed '2,$s/^/  /')

Debug Report:
  $DEBUG_REPORT_PATH

Root Cause:
  $(echo "$ROOT_CAUSE" | fold -w 60 -s | sed '2,$s/^/  /')

Recommended Fix:
  $(echo "$RECOMMENDED_FIX" | fold -w 60 -s | sed '2,$s/^/  /')

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                         CHOOSE ACTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(r) Revise - Update plan using debug findings (/revise --auto-mode)
(c) Continue - Proceed to next phase despite failure
(s) Skip - Mark phase as skipped, continue to next phase
(a) Abort - Stop implementation, save checkpoint

Enter choice [r/c/s/a]:
EOF

# Read user input (with timeout in non-interactive environments)
read -r -t 300 USER_CHOICE || USER_CHOICE="a"

# Normalize choice to lowercase
USER_CHOICE=$(echo "$USER_CHOICE" | tr '[:upper:]' '[:lower:]')

# Validate choice
case "$USER_CHOICE" in
  r|c|s|a)
    # Valid choice, proceed
    ;;
  *)
    echo "Invalid choice: $USER_CHOICE"
    echo "Defaulting to (a)bort for safety"
    USER_CHOICE="a"
    ;;
esac
```

**Box Drawing**: Uses Unicode box-drawing characters (━ U+2501) for consistent formatting with other command outputs.

**Timeout Handling**: 300-second (5 minute) timeout for user input. In non-interactive environments (no TTY), defaults to abort for safety.

**Progress Marker**: After user selects choice:
```bash
echo ""
echo "PROGRESS: Processing choice: $USER_CHOICE_DESCRIPTION..."
echo ""
```

**Step 5.6: Route to Choice Handler**

Dispatch to appropriate handler based on user choice:

```bash
# Execute based on user choice
case "$USER_CHOICE" in
  r)
    handle_revise_with_debug_findings
    ;;
  c)
    handle_continue_despite_failure
    ;;
  s)
    handle_skip_phase
    ;;
  a)
    handle_abort_implementation
    ;;
esac
```

The remainder of this specification defines each handler function.
```

**Implementation Notes**:
- Total addition: ~150 lines to implement.md
- Insert after existing Step 4 (Graceful Degradation)
- Maintains backward compatibility - existing error handling still present
- Uses SlashCommand tool (already in allowed-tools for implement.md)

### Part 3: Handler Implementation - (r)evise Branch

**Function Name**: `handle_revise_with_debug_findings`

**Purpose**: Automatically invoke `/revise --auto-mode` with debug context to update the plan based on debug findings.

**Implementation**:

```markdown
**Step 5.7: Handle (r)evise - Invoke /revise --auto-mode**

User chose to revise the plan using debug findings:

```bash
handle_revise_with_debug_findings() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Revising plan with debug findings..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Build revision context JSON for /revise --auto-mode
  REVISION_CONTEXT=$(jq -n \
    --arg trigger_type "test_failure_debug" \
    --argjson phase "$CURRENT_PHASE" \
    --arg phase_name "$PHASE_NAME" \
    --arg reason "Test failure in phase $CURRENT_PHASE: $ERROR_DESC" \
    --arg action "Update phase tasks based on debug findings" \
    --arg debug_report "$DEBUG_REPORT_PATH" \
    --arg root_cause "$ROOT_CAUSE" \
    --arg fix "$RECOMMENDED_FIX" \
    '{
      revision_type: $trigger_type,
      current_phase: $phase,
      phase_name: $phase_name,
      reason: $reason,
      suggested_action: $action,
      debug_context: {
        debug_report: $debug_report,
        root_cause: $root_cause,
        recommended_fix: $fix,
        error_description: $reason
      }
    }')

  # Log revision attempt to adaptive planning log
  log_replan_invocation "test_failure_debug" "initiating" "Phase $CURRENT_PHASE" "$REVISION_CONTEXT"

  # Invoke /revise --auto-mode via SlashCommand
  REVISE_CMD="/revise \"$PLAN_PATH\" --auto-mode --context '$REVISION_CONTEXT'"
  REVISE_RESULT=$(invoke_slash_command "$REVISE_CMD" --timeout 120000)
  REVISE_STATUS=$?

  # Check revision status
  if [ "$REVISE_STATUS" -eq 0 ]; then
    # Parse revision response (JSON format from revise.md auto-mode)
    REVISION_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status // "unknown"')

    if [ "$REVISION_STATUS" = "success" ]; then
      # Revision succeeded
      ACTION_TAKEN=$(echo "$REVISE_RESULT" | jq -r '.action_taken // "unknown"')
      UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file // "$PLAN_PATH"')

      # Log successful revision
      log_replan_invocation "test_failure_debug" "success" "$ACTION_TAKEN" "$REVISION_CONTEXT"

      echo "✓ Plan revised successfully"
      echo "  Action: $ACTION_TAKEN"
      echo "  Updated plan: $UPDATED_PLAN"
      echo ""
      echo "Recommendation: Review revised plan, then retry phase:"
      echo "  /implement \"$UPDATED_PLAN\" $CURRENT_PHASE"
      echo ""

      # Update checkpoint with revision info
      if [ -f "$CHECKPOINT_FILE" ]; then
        checkpoint_set_field "$CHECKPOINT_FILE" ".last_revision_reason" "test_failure_debug"
        checkpoint_set_field "$CHECKPOINT_FILE" ".last_revision_phase" "$CURRENT_PHASE"
      fi

      # Update PLAN_PATH for continued implementation (if user chooses to continue)
      PLAN_PATH="$UPDATED_PLAN"

      # Ask if user wants to retry phase now
      echo "Retry phase $CURRENT_PHASE now? [y/N]: "
      read -r -t 60 RETRY_NOW || RETRY_NOW="n"

      if [ "$RETRY_NOW" = "y" ] || [ "$RETRY_NOW" = "Y" ]; then
        echo "Retrying phase $CURRENT_PHASE with revised plan..."
        return 0  # Continue implementation with current phase
      else
        echo "Phase not retried. Save checkpoint and exit."
        return 2  # Signal to save checkpoint and exit gracefully
      fi

    else
      # Revision failed
      ERROR_MSG=$(echo "$REVISE_RESULT" | jq -r '.error_message // "Unknown error"')

      # Log failed revision
      log_replan_invocation "test_failure_debug" "failure" "$ERROR_MSG" "$REVISION_CONTEXT"

      echo "✗ Plan revision failed"
      echo "  Error: $ERROR_MSG"
      echo ""
      echo "Debug report is still available at:"
      echo "  $DEBUG_REPORT_PATH"
      echo ""
      echo "Next steps:"
      echo "  1. Review debug report for manual fixes"
      echo "  2. Use /revise interactively to adjust plan"
      echo "  3. Fix code issues manually and retry /implement"

      return 1  # Signal failure
    fi
  else
    # /revise command invocation failed
    echo "✗ Failed to invoke /revise command"
    echo "  Status: $REVISE_STATUS"
    echo "  Output: $REVISE_RESULT"

    log_replan_invocation "test_failure_debug" "failure" "Command invocation failed" "$REVISION_CONTEXT"

    return 1
  fi
}
```

**Context JSON Structure**:
```json
{
  "revision_type": "test_failure_debug",
  "current_phase": 3,
  "phase_name": "Core Implementation",
  "reason": "Test failure in phase 3: Error: Module not found: crypto-utils",
  "suggested_action": "Update phase tasks based on debug findings",
  "debug_context": {
    "debug_report": "specs/reports/026_debug_phase3.md",
    "root_cause": "Missing dependency declaration in module imports",
    "recommended_fix": "Add crypto-utils to project dependencies and import statements",
    "error_description": "Test failure in phase 3: Error: Module not found: crypto-utils"
  }
}
```

**Integration with /revise**:
- `/revise` command receives `--auto-mode` flag
- Context type `test_failure_debug` is not a standard revision_type in revise.md
- `/revise` auto-mode will need to handle this custom type OR
- We use `update_tasks` revision_type and include debug context as additional field

**Recommended Approach**: Use `revision_type: "update_tasks"` with debug_context as metadata:
```json
{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Test failure debug analysis suggests missing prerequisite tasks",
  "suggested_action": "Add tasks for crypto-utils dependency setup",
  "task_operations": [
    {
      "action": "insert",
      "position": 1,
      "task": "Install crypto-utils dependency (npm install crypto-utils)"
    },
    {
      "action": "insert",
      "position": 2,
      "task": "Add crypto-utils import to module header"
    }
  ],
  "debug_metadata": {
    "debug_report": "specs/reports/026_debug_phase3.md",
    "root_cause": "Missing dependency declaration",
    "triggered_by": "automatic_debug_integration"
  }
}
```

**Return Codes**:
- `0`: Success, continue with implementation (user chose to retry)
- `1`: Failure, abort implementation
- `2`: Success but exit (user chose not to retry now)
```

**Implementation Size**: ~120 lines

### Part 4: Handler Implementation - (c)ontinue Branch

**Function Name**: `handle_continue_despite_failure`

**Purpose**: Log the decision to continue despite test failure, mark phase with warning, proceed to next phase.

**Implementation**:

```markdown
**Step 5.8: Handle (c)ontinue - Proceed Despite Failure**

User chose to continue to next phase despite test failure:

```bash
handle_continue_despite_failure() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Continuing to next phase despite test failure"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Ask user for rationale (optional)
  echo "Rationale for continuing (optional, press Enter to skip): "
  read -r -t 120 CONTINUE_RATIONALE || CONTINUE_RATIONALE=""

  # Log decision to adaptive planning log
  log_loop_prevention "$CURRENT_PHASE" "0" "continue_despite_failure"

  # Build decision record
  DECISION_RECORD=$(jq -n \
    --argjson phase "$CURRENT_PHASE" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg rationale "$CONTINUE_RATIONALE" \
    --arg debug_report "$DEBUG_REPORT_PATH" \
    '{
      decision: "continue_despite_failure",
      phase: $phase,
      timestamp: $timestamp,
      rationale: $rationale,
      debug_report: $debug_report
    }')

  # Update checkpoint with warning flag
  if [ -f "$CHECKPOINT_FILE" ]; then
    # Add to warning_phases array
    jq --argjson phase "$CURRENT_PHASE" \
       --argjson record "$DECISION_RECORD" \
       '.warning_phases = (.warning_phases // []) + [$phase] |
        .phase_decisions = (.phase_decisions // []) + [$record]' \
       "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
    mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
  fi

  # Mark phase in plan file with warning status
  # Find phase heading line
  PHASE_HEADING_LINE=$(grep -n "^### Phase $CURRENT_PHASE:" "$PLAN_PATH" | cut -d: -f1 | head -1)

  if [ -n "$PHASE_HEADING_LINE" ]; then
    # Use Edit tool to add [COMPLETED WITH ERRORS] marker
    ORIGINAL_HEADING=$(sed -n "${PHASE_HEADING_LINE}p" "$PLAN_PATH")
    UPDATED_HEADING=$(echo "$ORIGINAL_HEADING" | sed 's/$/ [COMPLETED WITH ERRORS]/')

    # Edit plan file
    sed -i.bak "${PHASE_HEADING_LINE}s|.*|$UPDATED_HEADING|" "$PLAN_PATH"

    # Add warning note after phase heading
    WARNING_NOTE=$(cat <<'EOFNOTE'

**⚠ WARNING**: This phase completed with test failures. Proceeding at user discretion.
- **Debug Report**: [DEBUG_REPORT_PATH_PLACEHOLDER](DEBUG_REPORT_PATH_PLACEHOLDER)
- **Decision**: Continue to next phase
- **Rationale**: RATIONALE_PLACEHOLDER
- **Date**: TIMESTAMP_PLACEHOLDER

EOFNOTE
)

    # Replace placeholders
    WARNING_NOTE="${WARNING_NOTE//DEBUG_REPORT_PATH_PLACEHOLDER/$DEBUG_REPORT_PATH}"
    WARNING_NOTE="${WARNING_NOTE//RATIONALE_PLACEHOLDER/${CONTINUE_RATIONALE:-User chose to continue}}"
    WARNING_NOTE="${WARNING_NOTE//TIMESTAMP_PLACEHOLDER/$(date -u +%Y-%m-%d)}"

    # Insert warning note after heading line
    sed -i.bak "$((PHASE_HEADING_LINE + 1))i\\
$WARNING_NOTE
" "$PLAN_PATH"
  fi

  echo "✓ Phase $CURRENT_PHASE marked as [COMPLETED WITH ERRORS]"
  echo "  Warning note added to plan file"
  echo "  Debug report linked: $DEBUG_REPORT_PATH"
  echo ""

  # Increment phase counter to move to next phase
  CURRENT_PHASE=$((CURRENT_PHASE + 1))

  echo "Proceeding to Phase $CURRENT_PHASE..."
  echo ""

  return 0  # Continue implementation with next phase
}
```

**Plan Annotation Example**:
```markdown
### Phase 3: Core Implementation [COMPLETED WITH ERRORS]

**⚠ WARNING**: This phase completed with test failures. Proceeding at user discretion.
- **Debug Report**: [specs/reports/026_debug_phase3.md](specs/reports/026_debug_phase3.md)
- **Decision**: Continue to next phase
- **Rationale**: Tests will be fixed in Phase 5 refactoring
- **Date**: 2025-10-10

Tasks:
- [x] Implement main feature
- [x] Add error handling
- [x] Write tests
```

**Checkpoint Update**: Adds phase to `warning_phases` array for tracking phases with unresolved failures.

**Return Code**: `0` (continue to next phase)
```

**Implementation Size**: ~90 lines

### Part 5: Handler Implementation - (s)kip Branch

**Function Name**: `handle_skip_phase`

**Purpose**: Mark phase as skipped in plan metadata, update checkpoint, proceed to next phase without marking current phase as complete.

**Implementation**:

```markdown
**Step 5.9: Handle (s)kip - Skip Phase and Continue**

User chose to skip the failing phase:

```bash
handle_skip_phase() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Skipping phase $CURRENT_PHASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Ask user for skip reason
  echo "Reason for skipping (required): "
  read -r -t 120 SKIP_REASON || SKIP_REASON="Test failures - will address later"

  # Log skip decision
  log_loop_prevention "$CURRENT_PHASE" "0" "phase_skipped"

  # Build skip record
  SKIP_RECORD=$(jq -n \
    --argjson phase "$CURRENT_PHASE" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg reason "$SKIP_REASON" \
    --arg debug_report "$DEBUG_REPORT_PATH" \
    '{
      decision: "skip_phase",
      phase: $phase,
      timestamp: $timestamp,
      reason: $reason,
      debug_report: $debug_report
    }')

  # Update checkpoint with skip info
  if [ -f "$CHECKPOINT_FILE" ]; then
    jq --argjson phase "$CURRENT_PHASE" \
       --argjson record "$SKIP_RECORD" \
       '.skipped_phases = (.skipped_phases // []) + [$phase] |
        .phase_decisions = (.phase_decisions // []) + [$record]' \
       "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
    mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"
  fi

  # Mark phase in plan file with SKIPPED status
  PHASE_HEADING_LINE=$(grep -n "^### Phase $CURRENT_PHASE:" "$PLAN_PATH" | cut -d: -f1 | head -1)

  if [ -n "$PHASE_HEADING_LINE" ]; then
    # Add [SKIPPED] marker to heading
    ORIGINAL_HEADING=$(sed -n "${PHASE_HEADING_LINE}p" "$PLAN_PATH")
    UPDATED_HEADING=$(echo "$ORIGINAL_HEADING" | sed 's/$/ [SKIPPED]/')

    sed -i.bak "${PHASE_HEADING_LINE}s|.*|$UPDATED_HEADING|" "$PLAN_PATH"

    # Add skip note after heading
    SKIP_NOTE=$(cat <<'EOFNOTE'

**Status**: SKIPPED
- **Reason**: REASON_PLACEHOLDER
- **Debug Report**: [DEBUG_REPORT_PATH_PLACEHOLDER](DEBUG_REPORT_PATH_PLACEHOLDER)
- **Date Skipped**: TIMESTAMP_PLACEHOLDER
- **Resume Instructions**: To implement this phase later, use `/implement "PLAN_PATH_PLACEHOLDER" PHASE_NUM_PLACEHOLDER`

EOFNOTE
)

    # Replace placeholders
    SKIP_NOTE="${SKIP_NOTE//REASON_PLACEHOLDER/$SKIP_REASON}"
    SKIP_NOTE="${SKIP_NOTE//DEBUG_REPORT_PATH_PLACEHOLDER/$DEBUG_REPORT_PATH}"
    SKIP_NOTE="${SKIP_NOTE//TIMESTAMP_PLACEHOLDER/$(date -u +%Y-%m-%d)}"
    SKIP_NOTE="${SKIP_NOTE//PLAN_PATH_PLACEHOLDER/$PLAN_PATH}"
    SKIP_NOTE="${SKIP_NOTE//PHASE_NUM_PLACEHOLDER/$CURRENT_PHASE}"

    # Insert skip note
    sed -i.bak "$((PHASE_HEADING_LINE + 1))i\\
$SKIP_NOTE
" "$PLAN_PATH"
  fi

  echo "✓ Phase $CURRENT_PHASE marked as [SKIPPED]"
  echo "  Reason: $SKIP_REASON"
  echo "  Debug report linked: $DEBUG_REPORT_PATH"
  echo ""

  # Increment phase counter
  CURRENT_PHASE=$((CURRENT_PHASE + 1))

  echo "Proceeding to Phase $CURRENT_PHASE..."
  echo ""

  return 0  # Continue to next phase
}
```

**Plan Annotation Example**:
```markdown
### Phase 3: Core Implementation [SKIPPED]

**Status**: SKIPPED
- **Reason**: Complex database migration required - will implement in separate phase
- **Debug Report**: [specs/reports/026_debug_phase3.md](specs/reports/026_debug_phase3.md)
- **Date Skipped**: 2025-10-10
- **Resume Instructions**: To implement this phase later, use `/implement "specs/plans/025_plan.md" 3`

Tasks:
- [ ] Implement main feature
- [ ] Add error handling
- [ ] Write tests
```

**Key Differences from Continue**:
- **Continue**: Marks phase as [COMPLETED WITH ERRORS], tasks checked [x]
- **Skip**: Marks phase as [SKIPPED], tasks remain unchecked [ ]
- **Resume**: Skip provides explicit resume instructions

**Return Code**: `0` (continue to next phase)
```

**Implementation Size**: ~85 lines

### Part 6: Handler Implementation - (a)bort Branch

**Function Name**: `handle_abort_implementation`

**Purpose**: Save checkpoint with current state and error info, preserve completed work, exit gracefully with non-zero status.

**Implementation**:

```markdown
**Step 5.10: Handle (a)bort - Save State and Exit**

User chose to abort implementation:

```bash
handle_abort_implementation() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Aborting implementation"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Ask for abort reason (optional)
  echo "Reason for aborting (optional): "
  read -r -t 60 ABORT_REASON || ABORT_REASON="Test failures require investigation"

  # Log abort decision
  log_loop_prevention "$CURRENT_PHASE" "0" "implementation_aborted"

  # Build abort record
  ABORT_RECORD=$(jq -n \
    --argjson phase "$CURRENT_PHASE" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg reason "$ABORT_REASON" \
    --arg debug_report "$DEBUG_REPORT_PATH" \
    --arg error_desc "$ERROR_DESC" \
    '{
      decision: "abort_implementation",
      failed_phase: $phase,
      timestamp: $timestamp,
      reason: $reason,
      debug_report: $debug_report,
      error_description: $error_desc
    }')

  # Save checkpoint with error state
  if [ -f "$CHECKPOINT_FILE" ]; then
    # Update checkpoint status and error info
    jq --argjson record "$ABORT_RECORD" \
       --arg error "$ERROR_DESC" \
       '.status = "aborted" |
        .last_error = $error |
        .abort_info = $record' \
       "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp"
    mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE"

    CHECKPOINT_LOCATION="$CHECKPOINT_FILE"
  else
    # Create new checkpoint with abort info
    PROJECT_NAME=$(basename "$PLAN_PATH" .md | sed 's/^[0-9]*_//')

    CHECKPOINT_STATE=$(jq -n \
      --arg plan "$PLAN_PATH" \
      --argjson phase "$CURRENT_PHASE" \
      --argjson total "$TOTAL_PHASES" \
      --argjson completed "$(printf '%s\n' "${COMPLETED_PHASES[@]}" | jq -R . | jq -s 'map(tonumber)')" \
      --arg error "$ERROR_DESC" \
      --argjson abort "$ABORT_RECORD" \
      '{
        workflow_description: "Implement plan (aborted)",
        plan_path: $plan,
        current_phase: $phase,
        total_phases: $total,
        completed_phases: $completed,
        status: "aborted",
        last_error: $error,
        abort_info: $abort
      }')

    CHECKPOINT_LOCATION=$(save_checkpoint "implement" "$PROJECT_NAME" "$CHECKPOINT_STATE")
  fi

  echo "✓ Checkpoint saved with abort information"
  echo "  Location: $CHECKPOINT_LOCATION"
  echo "  Failed phase: $CURRENT_PHASE"
  echo "  Debug report: $DEBUG_REPORT_PATH"
  echo ""
  echo "Work Preserved:"
  echo "  - Completed phases: ${COMPLETED_PHASES[@]}"
  echo "  - Git commits: Preserved (no rollback)"
  echo "  - Partial code changes: Preserved in working directory"
  echo ""
  echo "Resume Instructions:"
  echo "  1. Review debug report: $DEBUG_REPORT_PATH"
  echo "  2. Fix identified issues"
  echo "  3. Resume implementation:"
  echo "     /implement \"$PLAN_PATH\" $CURRENT_PHASE"
  echo ""
  echo "Or use checkpoint auto-resume:"
  echo "  /implement"
  echo ""

  # Exit with non-zero status for CI detection
  exit 1
}
```

**Checkpoint Structure After Abort**:
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_auth_system_20251010_143022",
  "workflow_type": "implement",
  "project_name": "auth_system",
  "workflow_description": "Implement plan (aborted)",
  "created_at": "2025-10-10T14:30:22Z",
  "updated_at": "2025-10-10T14:35:18Z",
  "status": "aborted",
  "current_phase": 3,
  "total_phases": 5,
  "completed_phases": [1, 2],
  "workflow_state": {
    "plan_path": "specs/plans/025_plan.md",
    "current_phase": 3,
    "total_phases": 5,
    "completed_phases": [1, 2]
  },
  "last_error": "Error: Module not found: crypto-utils",
  "abort_info": {
    "decision": "abort_implementation",
    "failed_phase": 3,
    "timestamp": "2025-10-10T14:35:18Z",
    "reason": "Need to investigate dependency issues",
    "debug_report": "specs/reports/026_debug_phase3.md",
    "error_description": "Error: Module not found: crypto-utils"
  }
}
```

**No Rollback**: Completed work is preserved:
- Git commits for phases 1-2 remain
- Code changes in working directory preserved
- User can fix issues and resume from phase 3

**Exit Status**: `exit 1` (non-zero for CI/automation detection)

**Return Code**: Does not return (exits process)
```

**Implementation Size**: ~95 lines

### Part 7: Plan Annotation Integration

**Location**: Debug command integration (already implemented in debug.md lines 182-244)

**What /debug Does** (from debug.md):
When a plan path is provided to `/debug`, it automatically annotates the plan with debugging notes:

```markdown
#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase 3 tests failing with null pointer exception
- **Debug Report**: [../reports/026_debug_phase3.md](../reports/026_debug_phase3.md)
- **Root Cause**: Missing null check in error handler
- **Resolution**: Pending
```

**Our Integration**:
1. We invoke: `/debug "$ERROR_DESC" "$PLAN_PATH"`
2. Debug command creates report AND annotates plan automatically
3. We don't need to add annotation - debug.md already does this
4. We DO update resolution when tests pass (Step 3.5 in implement.md, lines 890-919)

**Resolution Update** (already in implement.md):
When a previously-failed phase with debugging notes passes tests:
```markdown
### 3.5. Update Debug Resolution (if tests pass for previously-failed phase)

**Step 1: Check for Debugging Notes**
- Read current phase section in plan
- Look for "#### Debugging Notes" subsection
- Check if it contains "Resolution: Pending"

**Step 2: Update Resolution**
- If debugging notes exist and tests now pass:
  - Use Edit tool to update: `Resolution: Pending` → `Resolution: Applied`
  - Add git commit hash line (will be added after commit)

**Step 3: Add Fix Commit Hash (after git commit)**
- After git commit succeeds
- If resolution was updated: Add commit hash to debugging notes
- Format: `Fix Applied In: [commit-hash]`
```

**Our Task**: None needed here - debug.md and implement.md Step 3.5 already handle this.

### Part 8: Error Handling Specifications

**Error Scenarios and Handling**:

**8.1: /debug Command Fails**
```bash
# In Step 5.3: Invoke /debug via SlashCommand
if [ "$DEBUG_STATUS" -ne 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "WARNING: Automatic debug analysis failed"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Debug command error: $DEBUG_RESULT"
  echo ""
  echo "Falling back to manual debugging workflow:"
  echo "  1. Review test errors above"
  echo "  2. Run debug manually: /debug \"$ERROR_DESC\" \"$PLAN_PATH\""
  echo "  3. Fix issues based on error analysis"
  echo "  4. Retry implementation: /implement \"$PLAN_PATH\" $CURRENT_PHASE"
  echo ""

  # Log debug failure
  log_replan_invocation "test_failure_debug" "failure" "Debug command failed: $DEBUG_RESULT" ""

  # Fall back to existing Step 4 graceful degradation
  # Do NOT present user choice - exit and let user debug manually
  return 1
fi
```

**Fallback**: Reverts to existing Step 4 (Graceful Degradation) behavior - suggest manual `/debug` invocation.

**8.2: Debug Report Not Created**
```bash
# In Step 5.4: Parse Debug Response
if [ -z "$DEBUG_REPORT_PATH" ] || [ ! -f "$DEBUG_REPORT_PATH" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "WARNING: Debug report not found"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Expected debug report at: specs/reports/NNN_debug_*.md"
  echo "Debug command output:"
  echo "$DEBUG_RESULT"
  echo ""
  echo "Manual debugging required:"
  echo "  /debug \"$ERROR_DESC\" \"$PLAN_PATH\""
  echo ""

  return 1
fi
```

**Fallback**: Exit without user choice, suggest manual debug invocation.

**8.3: Cannot Parse Root Cause from Report**
```bash
# In Step 5.4: Parse Debug Response
if [ -z "$ROOT_CAUSE" ]; then
  ROOT_CAUSE="See debug report for details (parsing failed)"
fi

if [ -z "$RECOMMENDED_FIX" ]; then
  RECOMMENDED_FIX="Review debug report manually"
fi

# Continue with user choice presentation
# Even if parsing fails, we have the report path and can proceed
```

**Fallback**: Use placeholder text, still present user choices since report exists.

**8.4: /revise Command Fails (from (r)evise branch)**
```bash
# In handle_revise_with_debug_findings
if [ "$REVISE_STATUS" -ne 0 ]; then
  echo "✗ Failed to invoke /revise command"
  echo "  Status: $REVISE_STATUS"
  echo "  Output: $REVISE_RESULT"
  echo ""
  echo "Automatic revision failed. Manual revision required:"
  echo "  /revise \"Update phase $CURRENT_PHASE based on debug findings\" \"$DEBUG_REPORT_PATH\""
  echo ""

  log_replan_invocation "test_failure_debug" "failure" "Command invocation failed" "$REVISION_CONTEXT"

  return 1  # Abort implementation
fi
```

**Fallback**: Suggest manual `/revise` invocation, abort implementation.

**8.5: Invalid User Input**
```bash
# In Step 5.5: Display Formatted Summary
# Validate choice
case "$USER_CHOICE" in
  r|c|s|a)
    # Valid choice, proceed
    ;;
  *)
    echo "Invalid choice: $USER_CHOICE"
    echo "Valid choices: r (revise), c (continue), s (skip), a (abort)"
    echo "Defaulting to (a)bort for safety"
    USER_CHOICE="a"
    ;;
esac
```

**Fallback**: Default to abort for safety, prevents unintended actions.

**8.6: Non-Interactive Environment (No TTY)**
```bash
# In Step 5.5: Display Formatted Summary
# Check if running in non-interactive environment
if [ ! -t 0 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "NON-INTERACTIVE ENVIRONMENT DETECTED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Cannot prompt for user choice in non-interactive mode."
  echo "Defaulting to (a)bort for safety."
  echo ""
  echo "Debug report created: $DEBUG_REPORT_PATH"
  echo ""
  echo "To resume manually:"
  echo "  1. Review debug report"
  echo "  2. Fix issues"
  echo "  3. Run: /implement \"$PLAN_PATH\" $CURRENT_PHASE"
  echo ""

  USER_CHOICE="a"
fi

# Then read with timeout...
read -r -t 300 USER_CHOICE || USER_CHOICE="a"
```

**Fallback**: Auto-abort in CI/batch environments, preserve state for manual resume.

**8.7: Timeout on User Input**
```bash
# In Step 5.5: read command with timeout
read -r -t 300 USER_CHOICE || USER_CHOICE="a"

# If timeout occurs, USER_CHOICE is set to "a" (abort)
# User has 5 minutes to make a choice
```

**Fallback**: Default to abort after 5-minute timeout.

### Part 9: Testing Specifications

**Test Cases for Phase 4**:

**9.1: Test Case 1 - Happy Path: (r)evise → Retry → Success**

**Setup**:
- Plan: `specs/plans/test_001_plan.md` with Phase 2 containing intentional bug
- Phase 2 tasks include test that will fail due to missing import

**Execution**:
1. Run `/implement specs/plans/test_001_plan.md 2`
2. Phase 2 tests fail with "ModuleNotFoundError: No module named 'crypto'"
3. Automatic debug invocation creates `specs/reports/NNN_debug_phase2.md`
4. User choice presented with (r/c/s/a)
5. User enters "r"
6. `/revise --auto-mode` invoked with debug context
7. Plan updated with task: "Install crypto dependency"
8. User chooses to retry phase 2
9. Tests pass
10. Phase 2 marked [COMPLETED]

**Expected Results**:
- Debug report created at `specs/reports/NNN_debug_phase2.md`
- Plan annotated with debugging notes (Resolution: Pending)
- Plan revised with new task
- After retry and success: Resolution updated to "Applied"
- Commit created for Phase 2 with fix
- Adaptive planning log contains:
  - `trigger_eval: test_failure_debug -> triggered`
  - `replan: test_failure_debug -> success`

**9.2: Test Case 2 - (c)ontinue → Next Phase**

**Setup**:
- Plan with Phase 3 that will fail tests
- Phase 4 exists and is independent

**Execution**:
1. Run `/implement specs/plans/test_002_plan.md 3`
2. Phase 3 tests fail
3. Debug report created
4. User choice presented
5. User enters "c" with rationale "Will fix in Phase 6 refactoring"
6. Phase 3 marked [COMPLETED WITH ERRORS]
7. Warning note added to plan
8. Checkpoint updated with warning_phases: [3]
9. Implementation continues to Phase 4

**Expected Results**:
- Plan shows: `### Phase 3: ... [COMPLETED WITH ERRORS]`
- Warning note includes rationale and debug report link
- Checkpoint contains: `"warning_phases": [3]`
- Phase 4 proceeds normally
- No commit created for Phase 3

**9.3: Test Case 3 - (s)kip → Next Phase**

**Setup**:
- Plan with Phase 2 that will fail tests
- User decides phase is not needed

**Execution**:
1. Run `/implement specs/plans/test_003_plan.md 2`
2. Phase 2 tests fail
3. Debug report created
4. User choice presented
5. User enters "s" with reason "Phase no longer needed due to architecture change"
6. Phase 2 marked [SKIPPED]
7. Tasks remain unchecked [ ]
8. Skip note added with resume instructions
9. Implementation continues to Phase 3

**Expected Results**:
- Plan shows: `### Phase 2: ... [SKIPPED]`
- Skip note includes reason and resume command
- Checkpoint contains: `"skipped_phases": [2]`
- Tasks NOT marked as complete
- Phase 3 proceeds normally

**9.4: Test Case 4 - (a)bort → Checkpoint Saved**

**Setup**:
- Plan with 5 phases
- Phases 1-2 complete successfully
- Phase 3 fails tests

**Execution**:
1. Run `/implement specs/plans/test_004_plan.md`
2. Phases 1-2 complete, commits created
3. Phase 3 tests fail
4. Debug report created
5. User choice presented
6. User enters "a" with reason "Need to investigate database schema issues"
7. Checkpoint saved with abort info
8. Implementation exits with status 1

**Expected Results**:
- Checkpoint file created: `.claude/checkpoints/implement_test_004_*.json`
- Checkpoint status: "aborted"
- Checkpoint contains:
  - `completed_phases: [1, 2]`
  - `current_phase: 3`
  - `abort_info` with reason and debug report
- Phases 1-2 commits preserved in git
- Phase 3 code changes preserved in working directory (no rollback)
- Exit code: 1

**9.5: Test Case 5 - /debug Command Fails**

**Setup**:
- Mock `/debug` command to return non-zero exit status

**Execution**:
1. Run `/implement` on plan with failing phase
2. Tests fail
3. `/debug` invocation fails (mocked)
4. Error message displayed
5. Fallback to manual debugging instructions
6. Implementation does NOT present user choices
7. Implementation aborts

**Expected Results**:
- Warning message about debug failure
- Manual debug command suggestion displayed
- No user choice prompt
- Implementation exits with error
- Log contains: `replan: test_failure_debug -> failure`

**9.6: Test Case 6 - Non-Interactive Mode**

**Setup**:
- Run implementation in CI environment (no TTY)
- Plan with failing phase

**Execution**:
1. Run `/implement` with stdin redirected (simulating CI)
2. Phase tests fail
3. Debug report created
4. Non-interactive environment detected
5. Auto-abort message displayed
6. Checkpoint saved with abort info
7. Exit code 1

**Expected Results**:
- Non-interactive warning displayed
- Choice defaults to "a" (abort)
- Checkpoint saved
- Debug report path shown in output
- Manual resume instructions displayed
- Exit code: 1

**Test Implementation Location**: `.claude/tests/test_automatic_debug_integration.sh`

### Part 10: Integration Pattern Reference

**10.1: SlashCommand Tool Invocation from Bash**

The implement.md command has access to the SlashCommand tool. However, bash scripts cannot directly invoke tools - they must be invoked by the Claude agent executing the command.

**Pattern**: The implement.md file is a markdown document with bash code blocks. When Claude executes `/implement`, it:
1. Reads the implement.md command specification
2. Executes the logic described in bash code blocks using the Bash tool
3. Can invoke other slash commands using the SlashCommand tool when specified

**Pseudocode in Specification**:
```bash
DEBUG_RESULT=$(invoke_slash_command "$DEBUG_CMD" --timeout 60000)
```

**Actual Implementation**: The agent reads this instruction and invokes:
```yaml
SlashCommand {
  command: "/debug \"Phase 3 tests failed...\" \"specs/plans/025_plan.md\""
}
```

**Important**: The bash code in implement.md is illustrative. The actual execution is performed by the Claude agent interpreting the command specification.

**10.2: Checkpoint Integration**

**Functions Used** (from checkpoint-utils.sh):
- `save_checkpoint(workflow_type, project_name, state_json)` - Save checkpoint
- `checkpoint_set_field(file, field_path, value)` - Update checkpoint field
- `restore_checkpoint(workflow_type, project_name)` - Load checkpoint

**Example Usage**:
```bash
# Save checkpoint with abort info
PROJECT_NAME=$(basename "$PLAN_PATH" .md | sed 's/^[0-9]*_//')
CHECKPOINT_STATE='{"status":"aborted","current_phase":3,"last_error":"..."}'
CHECKPOINT_FILE=$(save_checkpoint "implement" "$PROJECT_NAME" "$CHECKPOINT_STATE")

# Update existing checkpoint field
checkpoint_set_field "$CHECKPOINT_FILE" ".status" "aborted"
checkpoint_set_field "$CHECKPOINT_FILE" ".last_error" "$ERROR_DESC"
```

**10.3: Logging Integration**

**Functions Used** (from adaptive-planning-logger.sh):
- `log_replan_invocation(revision_type, status, result, context)` - Log replan events
- `log_loop_prevention(phase, count, action)` - Log loop prevention

**Example Usage**:
```bash
# Log replan attempt
log_replan_invocation "test_failure_debug" "initiating" "Phase $CURRENT_PHASE" "$CONTEXT_JSON"

# Log success
log_replan_invocation "test_failure_debug" "success" "$ACTION_TAKEN" "$CONTEXT_JSON"

# Log abort decision
log_loop_prevention "$CURRENT_PHASE" "0" "implementation_aborted"
```

**Log Location**: `.claude/logs/adaptive-planning.log`

**10.4: Plan File Updates**

**Tools Used**:
- Edit tool: Modify existing plan sections
- sed: In-place editing for simple updates (with .bak backups)

**Example Pattern**:
```bash
# Find phase heading line number
PHASE_HEADING_LINE=$(grep -n "^### Phase $CURRENT_PHASE:" "$PLAN_PATH" | cut -d: -f1 | head -1)

# Update heading with marker
sed -i.bak "${PHASE_HEADING_LINE}s|$| [SKIPPED]|" "$PLAN_PATH"

# Insert note after heading
sed -i.bak "$((PHASE_HEADING_LINE + 1))i\\
**Status**: SKIPPED\\
- **Reason**: $SKIP_REASON
" "$PLAN_PATH"
```

**Always create backup**: `sed -i.bak` creates `.bak` backup before modifying.

### Part 11: Implementation Summary

**Total Implementation Size**: ~450 lines added to implement.md

**Files Modified**:
1. `/home/benjamin/.config/.claude/commands/implement.md`
   - Add Step 5 (3.3.1) after line 651
   - Add handler functions (can be inline or referenced)
   - Total addition: ~450 lines

**Files Created**: None (debug.md already handles plan annotation)

**Files Referenced**:
1. `/home/benjamin/.config/.claude/commands/debug.md` - Invoked via SlashCommand
2. `/home/benjamin/.config/.claude/commands/revise.md` - Invoked via SlashCommand for (r)evise
3. `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint management
4. `/home/benjamin/.config/.claude/lib/adaptive-planning-logger.sh` - Logging

**Dependencies**:
- jq (JSON processing)
- SlashCommand tool access (already in implement.md allowed-tools)
- Existing checkpoint and logging infrastructure

**User-Facing Changes**:
- When tests fail, users see automatic debug analysis summary
- Four clear choices presented with context
- Better error recovery workflow
- Automatic plan annotation with debug findings

**Backward Compatibility**:
- Existing graceful degradation (Step 4) remains as fallback
- If automatic debug fails, falls back to manual workflow
- No breaking changes to `/implement` command interface

**Testing Requirements**:
- 6 test cases covering all branches and error scenarios
- Test file: `.claude/tests/test_automatic_debug_integration.sh`
- Integration with existing `/implement` test suite

## Implementation Checklist

**Pre-Implementation**:
- [ ] Review implement.md structure (lines 591-651)
- [ ] Verify SlashCommand tool is in allowed-tools
- [ ] Test `/debug` command manually to understand output format
- [ ] Review checkpoint-utils.sh functions
- [ ] Review adaptive-planning-logger.sh functions

**Implementation Phase**:
- [ ] Add Step 5.1: Progress marker (5 lines)
- [ ] Add Step 5.2: Extract error description (15 lines)
- [ ] Add Step 5.3: Invoke /debug via SlashCommand (25 lines)
- [ ] Add Step 5.4: Parse debug response (45 lines)
- [ ] Add Step 5.5: Display summary and user choice (60 lines)
- [ ] Add Step 5.6: Route to handler (15 lines)
- [ ] Implement handle_revise_with_debug_findings (120 lines)
- [ ] Implement handle_continue_despite_failure (90 lines)
- [ ] Implement handle_skip_phase (85 lines)
- [ ] Implement handle_abort_implementation (95 lines)
- [ ] Add error handling for all scenarios (50 lines)

**Testing Phase**:
- [ ] Test Case 1: Revise → Retry → Success
- [ ] Test Case 2: Continue → Next Phase
- [ ] Test Case 3: Skip → Next Phase
- [ ] Test Case 4: Abort → Checkpoint Saved
- [ ] Test Case 5: /debug failure fallback
- [ ] Test Case 6: Non-interactive mode default

**Verification**:
- [ ] All handlers return correct codes
- [ ] Plan annotations created correctly
- [ ] Checkpoints saved with correct data
- [ ] Logging entries written to adaptive-planning.log
- [ ] Debug reports linked properly
- [ ] Graceful degradation works if debug fails
- [ ] Exit codes correct for all scenarios

## Edge Cases and Considerations

**Edge Case 1: Multiple Debug Reports for Same Phase**
- Scenario: Phase fails, user chooses (c)ontinue, later phases fail, implementation resumed from failed phase again
- Handling: debug.md supports multiple iterations (lines 208-219), adds "Iteration 2" markers
- Our handling: Each invocation creates new debug report, plan annotation tracks all iterations

**Edge Case 2: Debug Report Parsing Fails**
- Scenario: Debug report format changes or report is malformed
- Handling: Use fallback text "See debug report for details" and still present choices
- User can review report manually

**Edge Case 3: Plan File Not Writable**
- Scenario: Permissions prevent editing plan file
- Handling: Handler functions should check sed/edit success and log warnings
- Implementation can continue but annotation may fail

**Edge Case 4: Checkpoint Directory Missing**
- Scenario: `.claude/checkpoints/` directory doesn't exist
- Handling: `save_checkpoint()` creates directory (line 45 in checkpoint-utils.sh)
- No special handling needed

**Edge Case 5: Very Long Error Messages**
- Scenario: Test output is thousands of lines
- Handling: Error description extraction uses `head -3` to limit to first 3 error lines
- Prevents command line length issues

**Edge Case 6: User Closes Terminal During Choice Prompt**
- Scenario: Terminal closed while waiting for user input
- Handling: read timeout triggers default to abort
- Checkpoint saved with partial state
- Resume works correctly

**Edge Case 7: Concurrent Implementation Runs**
- Scenario: Two `/implement` instances running on same plan
- Handling: Checkpoint files use timestamp in filename, no collision
- Both instances maintain separate checkpoints
- User should avoid this scenario (not prevented)

## Performance Considerations

**Debug Invocation Time**: 30-60 seconds
- Acceptable for test failure scenario (user debugging anyway)
- Timeout set to 60 seconds
- Progress marker shown during analysis

**User Input Timeout**: 5 minutes (300 seconds)
- Generous time for user to read summary and decide
- Prevents indefinite hangs in edge cases
- Can be adjusted based on feedback

**Plan File Updates**: < 1 second
- sed operations are fast
- Inline editing with backup
- No performance concerns

**Checkpoint Operations**: < 100ms
- JSON manipulation with jq
- File writes are atomic
- Minimal overhead

**Total Overhead per Test Failure**: ~30-60 seconds for debug analysis + user decision time
- Acceptable tradeoff for improved workflow
- Reduces overall debugging cycle time by providing automatic root cause analysis

## Success Criteria

**Phase 4 is complete when**:
1. Test failures automatically trigger `/debug` invocation
2. Debug report created and parsed successfully
3. Formatted summary presented with all four choices
4. All four choice branches implemented and tested
5. Plan annotations created correctly for all scenarios
6. Checkpoints saved with correct state for resume capability
7. Logging entries written to adaptive-planning.log
8. Error handling covers all failure scenarios
9. All 6 test cases pass
10. Documentation updated (this specification serves as documentation)

**Acceptance Test**:
Run `/implement` on a plan with an intentionally failing phase:
1. Automatic debug analysis runs
2. Summary box displays with clear error, root cause, and fix
3. User can choose (r)evise and plan updates with debug tasks
4. OR user can choose (c)ontinue and next phase proceeds with warning
5. OR user can choose (s)kip and phase marked skipped with resume instructions
6. OR user can choose (a)bort and checkpoint saved for resume

All scenarios should complete successfully without errors.
