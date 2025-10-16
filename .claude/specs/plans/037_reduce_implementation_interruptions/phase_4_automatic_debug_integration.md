# Phase 4: Automatic Debug Integration for Test Failures

## Metadata
- **Phase Number**: 4
- **Parent Plan**: 037_reduce_implementation_interruptions.md
- **Phase Name**: Automatic Debug Integration for Test Failures
- **Objective**: Modify test failure handling in /implement to automatically invoke /debug and present user with clear choices
- **Complexity Score**: 8/10 (High)
- **Estimated Duration**: 4-5 hours
- **Status**: Not Started
- **Dependencies**: Phase 3 (Agent-Based Complexity Evaluation)

## Phase Overview

This phase enhances the `/implement` command's test failure handling to automatically invoke `/debug` when tests fail, analyze the failure, and present users with four clear action choices. This reduces manual debugging overhead and provides structured paths forward when implementation hits errors.

### Why This Phase is Complex

1. **Architectural Integration**: Changes core test failure handling loop in /implement (Step 3.3)
2. **Cross-Command Integration**: Must invoke /debug via SlashCommand tool and parse results
3. **Context Building**: Construct JSON context for /revise --auto-mode from debug findings
4. **Multiple Decision Branches**: Four user choices each requiring different handling logic
5. **State Management**: Update plan annotations, checkpoints, and logging
6. **Error Handling**: Graceful degradation if /debug fails or returns unexpected output

### Current State Analysis

The test failure handling currently exists at:
- **File**: `/home/benjamin/.config/.claude/commands/implement.md`
- **Location**: Step 3.3 (lines 591-651)
- **Current Behavior**: Enhanced error analysis with suggestions, but no automatic debug invocation

## Detailed Implementation Steps

### Step 1: Analyze Current Test Failure Detection (30 minutes)

**Objective**: Understand the exact location and flow of test failure handling in implement.md

**Actions**:

1.1. **Read Step 3.3 Implementation** (lines 591-651)
   - Tool: Read
   - File: `/home/benjamin/.config/.claude/commands/implement.md`
   - Focus: Lines 591-651 (Step 3.3: Enhanced Error Analysis)
   - Extract:
     - Where test failures are detected (`if tests fail`)
     - How error output is captured (`ERROR_OUTPUT` variable)
     - Current error analysis invocation (`.claude/lib/analyze-error.sh`)
     - Display formatting for error messages

1.2. **Identify Integration Point**
   - Find the exact line where test failure is first detected
   - Currently around line 614: "If tests fail"
   - Note the context variables available:
     - `$ERROR_OUTPUT` - Full test output
     - `$CURRENT_PHASE` - Phase number
     - `$PLAN_PATH` - Path to implementation plan
     - `$PHASE_NAME` - Phase name/description

1.3. **Review Error Analysis Output Format**
   - Examine `.claude/lib/analyze-error.sh` output structure
   - Note fields: error_type, location, context, suggestions, debug_commands
   - Understand how this output is currently displayed (lines 622-650)

**Expected Findings**:
- Exact line number for integration point
- Variables available for /debug invocation
- Current error display format (will be replaced/enhanced)

### Step 2: Design Debug Invocation Strategy (45 minutes)

**Objective**: Plan how to invoke /debug via SlashCommand and parse its response

**Actions**:

2.1. **Study /debug Command Interface**
   - Review `/debug` command specification
   - Arguments: `<issue-description> [report-path1] [report-path2] ...`
   - For test failures: `/debug "<error description>" <plan-path>`
   - Output: Creates debug report, returns path and root cause summary

2.2. **Design Error Description Builder**
   - Extract concise error description from test output
   - Format: "Phase [N]: [Phase Name] - [Error Summary]"
   - Example: "Phase 3: Core Implementation - Test failure: null pointer in auth.login"
   - Truncate to 200 characters max for readability

2.3. **Plan SlashCommand Invocation**
   ```bash
   # Build error description from test output
   ERROR_DESC=$(extract_error_summary "$ERROR_OUTPUT" "$PHASE_NAME" "$CURRENT_PHASE")

   # Invoke /debug via SlashCommand tool
   echo "PROGRESS: Running debug analysis for test failure..."

   # Use SlashCommand tool to invoke /debug
   DEBUG_RESULT=$(invoke_slash_command "/debug \"$ERROR_DESC\" $PLAN_PATH")
   ```

2.4. **Design Response Parsing Logic**
   - /debug output contains:
     - Report creation message with path
     - Root cause summary (1-2 sentences)
     - Recommendations section
   - Extract using regex patterns:
     - Report path: `specs/reports/[0-9]{3}_debug_.*\.md`
     - Root cause: Text after "Root Cause:" header in report
   - Handle edge cases:
     - /debug fails or times out
     - Report path not found in output
     - Empty root cause

**Design Decisions**:
- Use `grep -oP` for regex extraction (PCRE)
- Fallback to generic message if parsing fails
- Timeout: 5 minutes for /debug invocation
- Store debug report path in variable `$DEBUG_REPORT_PATH`

### Step 3: Implement Automatic Debug Invocation (90 minutes)

**Objective**: Modify implement.md Step 3.3 to automatically invoke /debug on test failure

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Location**: After line 614 (within "If tests fail" block)

**Implementation**:

3.1. **Add Progress Marker**
   - Insert after detecting test failure
   - Before existing error analysis
   - Line: ~615

   ```markdown
   **Step 3.3.1: Automatic Debug Analysis**

   When tests fail, automatically invoke /debug for root cause analysis:

   ```bash
   # Display progress
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "PROGRESS: Running debug analysis for test failure..."
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   ```

3.2. **Build Error Description**
   ```bash
   # Extract concise error summary from test output
   # Take first error line or first 200 chars
   ERROR_SUMMARY=$(echo "$ERROR_OUTPUT" | grep -i "error\|fail\|exception" | head -1 | cut -c1-200)

   # Build debug invocation description
   ERROR_DESC="Phase ${CURRENT_PHASE}: ${PHASE_NAME} - ${ERROR_SUMMARY}"
   ```

3.3. **Invoke /debug via SlashCommand Tool**
   ```bash
   # Invoke /debug command with error description and plan path
   # Note: This uses the SlashCommand tool, not bash execution
   DEBUG_INVOCATION="/debug \"${ERROR_DESC}\" ${PLAN_PATH}"

   # Display invocation for transparency
   echo "Invoking: $DEBUG_INVOCATION"
   echo ""

   # The actual invocation happens via SlashCommand tool in agent context
   # Agent will use: SlashCommand { command: "/debug \"${ERROR_DESC}\" ${PLAN_PATH}" }
   # This is a placeholder for documentation - actual invocation is in agent execution
   ```

3.4. **Parse Debug Response**
   ```bash
   # After SlashCommand completes, parse response
   # Extract debug report path from output
   DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -oP 'specs/reports/[0-9]{3}_debug_[^)]+\.md' | head -1)

   # Extract root cause from debug report
   if [ -f "$DEBUG_REPORT_PATH" ]; then
     # Read root cause section from report
     ROOT_CAUSE=$(grep -A 5 "^### Root Cause Analysis" "$DEBUG_REPORT_PATH" | tail -n +2 | head -3 | tr '\n' ' ')

     # Truncate if too long
     ROOT_CAUSE=$(echo "$ROOT_CAUSE" | cut -c1-200)
   else
     # Fallback if report not found
     ROOT_CAUSE="Debug report creation failed or path not detected"
   fi
   ```

3.5. **Error Handling for Debug Invocation**
   ```bash
   # Handle /debug invocation failures
   if [ -z "$DEBUG_REPORT_PATH" ]; then
     echo "Warning: Debug analysis failed to produce a report"
     echo "Continuing with basic error analysis..."

     # Fall back to existing error analysis
     .claude/lib/analyze-error.sh "$ERROR_OUTPUT"

     # Set fallback values
     DEBUG_REPORT_PATH="(debug failed)"
     ROOT_CAUSE="Debug analysis unavailable - see error output above"
   fi
   ```

**Expected Outcome**:
- Test failure triggers automatic /debug invocation
- Debug report created in specs/reports/
- Report path and root cause extracted
- Graceful fallback if debug fails

### Step 4: Design and Display Debug Summary Box (60 minutes)

**Objective**: Create formatted Unicode box displaying debug findings and user options

**Location**: Immediately after debug invocation completes (after Step 3.3.1)

**Implementation**:

4.1. **Design Unicode Box Layout**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   TEST FAILURE ANALYSIS
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Phase: [N] - [Phase Name]

   Issue:
     [Error description - first 200 chars of test failure]

   Debug Report:
     [Relative path to debug report]

   Root Cause:
     [1-2 sentence summary from debug report]

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ACTIONS AVAILABLE
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   (r) Revise plan based on debug findings
       Automatically updates plan with /revise --auto-mode
       Incorporates debug context and suggestions

   (c) Continue anyway
       Skip this phase and continue to next phase
       Phase will remain marked incomplete

   (s) Skip phase
       Mark phase as skipped in plan
       Document skip reason and continue

   (a) Abort implementation
       Save checkpoint and exit
       Resume later with /implement [plan] [phase]

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Choose action [r/c/s/a]:
   ```

4.2. **Implement Display Code**
   ```bash
   # Display debug summary box
   cat <<'EOF'
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   TEST FAILURE ANALYSIS
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   EOF

   echo ""
   echo "Phase: ${CURRENT_PHASE} - ${PHASE_NAME}"
   echo ""
   echo "Issue:"
   echo "  ${ERROR_SUMMARY}"
   echo ""
   echo "Debug Report:"
   echo "  ${DEBUG_REPORT_PATH}"
   echo ""
   echo "Root Cause:"
   echo "  ${ROOT_CAUSE}"
   echo ""

   cat <<'EOF'
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ACTIONS AVAILABLE
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   (r) Revise plan based on debug findings
       Automatically updates plan with /revise --auto-mode
       Incorporates debug context and suggestions

   (c) Continue anyway
       Skip this phase and continue to next phase
       Phase will remain marked incomplete

   (s) Skip phase
       Mark phase as skipped in plan
       Document skip reason and continue

   (a) Abort implementation
       Save checkpoint and exit
       Resume later with /implement [plan] [phase]

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   EOF

   # Read user choice
   read -p "Choose action [r/c/s/a]: " USER_CHOICE
   ```

4.3. **Input Validation**
   ```bash
   # Normalize input to lowercase
   USER_CHOICE=$(echo "$USER_CHOICE" | tr '[:upper:]' '[:lower:]')

   # Validate input
   case "$USER_CHOICE" in
     r|c|s|a)
       # Valid choice
       ;;
     *)
       echo "Invalid choice: $USER_CHOICE"
       echo "Please enter r, c, s, or a"
       exit 1
       ;;
   esac
   ```

**Expected Outcome**:
- Clean, readable summary box displayed
- All four action choices clearly explained
- User input captured and validated

### Step 5: Implement Choice Handlers (120 minutes)

**Objective**: Implement logic for all four user choices

**Location**: After user choice captured (continuation of Step 3.3)

**Implementation**:

5.1. **Handler Dispatcher**
   ```bash
   # Dispatch to appropriate handler based on user choice
   case "$USER_CHOICE" in
     r)
       handle_revise_with_debug
       ;;
     c)
       handle_continue_anyway
       ;;
     s)
       handle_skip_phase
       ;;
     a)
       handle_abort_implementation
       ;;
   esac
   ```

5.2. **Handler: (r) Revise with Debug Findings**
   ```bash
   handle_revise_with_debug() {
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo "PROGRESS: Invoking /revise with debug findings..."
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo ""

     # Build context JSON for /revise --auto-mode
     # revision_type: "update_tasks" - add debugging tasks
     # Include debug report path and root cause
     REVISION_CONTEXT=$(jq -n \
       --arg type "update_tasks" \
       --argjson phase "$CURRENT_PHASE" \
       --arg reason "Test failure requires debugging: $ROOT_CAUSE" \
       --arg action "Add debugging tasks and update phase based on debug findings" \
       --arg debug_report "$DEBUG_REPORT_PATH" \
       --arg root_cause "$ROOT_CAUSE" \
       '{
         revision_type: $type,
         current_phase: $phase,
         reason: $reason,
         suggested_action: $action,
         debug_context: {
           report_path: $debug_report,
           root_cause: $root_cause,
           error_output: "See debug report for details"
         },
         task_operations: [
           {
             action: "insert",
             position: 1,
             task: ("Fix: " + $root_cause)
           }
         ]
       }')

     # Invoke /revise --auto-mode
     echo "Invoking: /revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'"

     # SlashCommand invocation (in agent context)
     REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")

     # Parse revise response
     REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

     if [ "$REVISE_STATUS" = "success" ]; then
       echo "✓ Plan revised successfully with debug findings"
       UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file')

       # Update plan path if changed
       PLAN_PATH="$UPDATED_PLAN"

       # Log revision
       log_replan_invocation "$CURRENT_PHASE" "update_tasks_debug" "success" "Added debugging tasks"

       # Re-attempt phase implementation
       echo ""
       echo "Retrying phase $CURRENT_PHASE with updated plan..."
       # Return to phase start (implementation will retry)
       return 0
     else
       # Revision failed
       ERROR_MSG=$(echo "$REVISE_RESULT" | jq -r '.error_message')
       echo "✗ Plan revision failed: $ERROR_MSG"
       echo ""
       echo "Falling back to abort (save checkpoint and exit)"
       handle_abort_implementation
     fi
   }
   ```

5.3. **Handler: (c) Continue Anyway**
   ```bash
   handle_continue_anyway() {
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo "Continuing to next phase (current phase incomplete)..."
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo ""

     # Log decision
     echo "User chose to continue despite test failure in phase $CURRENT_PHASE"

     # Update checkpoint with incomplete phase
     .claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" \
       --phase-status "phase_${CURRENT_PHASE}=incomplete" \
       --last-error "Tests failed, user continued anyway"

     # Do NOT mark phase complete
     # Do NOT create git commit
     # Do NOT update plan with completion markers

     # Move to next phase
     CURRENT_PHASE=$((CURRENT_PHASE + 1))

     echo "Moving to Phase $CURRENT_PHASE"
     echo ""

     # Continue implementation loop
     return 0
   }
   ```

5.4. **Handler: (s) Skip Phase**
   ```bash
   handle_skip_phase() {
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo "Skipping Phase $CURRENT_PHASE..."
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo ""

     # Prompt for skip reason
     read -p "Enter reason for skipping (optional): " SKIP_REASON
     SKIP_REASON="${SKIP_REASON:-Test failure, manual intervention needed}"

     # Mark phase as skipped in plan
     # Use Edit tool to update phase heading
     # Change: "### Phase N: Phase Name" → "### Phase N: Phase Name [SKIPPED]"

     # Add skip annotation to plan
     SKIP_ANNOTATION="#### Skip Annotation
   - **Date**: $(date +%Y-%m-%d)
   - **Reason**: $SKIP_REASON
   - **Debug Report**: [$DEBUG_REPORT_PATH]($DEBUG_REPORT_PATH)
   - **Status**: Manual intervention required"

     # Use Edit tool (in agent context) to add annotation after phase tasks

     # Update checkpoint
     .claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" \
       --phase-status "phase_${CURRENT_PHASE}=skipped" \
       --skip-reason "$SKIP_REASON"

     # Log skip
     echo "Phase $CURRENT_PHASE marked as SKIPPED"
     echo "Reason: $SKIP_REASON"
     echo ""

     # Move to next phase
     CURRENT_PHASE=$((CURRENT_PHASE + 1))

     echo "Moving to Phase $CURRENT_PHASE"
     echo ""

     # Continue implementation loop
     return 0
   }
   ```

5.5. **Handler: (a) Abort Implementation**
   ```bash
   handle_abort_implementation() {
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo "Aborting implementation..."
     echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
     echo ""

     # Update checkpoint with error state
     STATE_JSON=$(cat <<EOF
   {
     "workflow_description": "Implement $PLAN_PATH",
     "plan_path": "$PLAN_PATH",
     "current_phase": $CURRENT_PHASE,
     "total_phases": $TOTAL_PHASES,
     "completed_phases": [$COMPLETED_PHASES_ARRAY],
     "status": "failed",
     "tests_passing": false,
     "last_error": "Test failure in phase $CURRENT_PHASE",
     "debug_report": "$DEBUG_REPORT_PATH",
     "failure_reason": "$ROOT_CAUSE"
   }
   EOF
   )

     # Save checkpoint
     PROJECT_NAME=$(basename "$PLAN_PATH" .md | sed 's/^[0-9]*_//')
     CHECKPOINT_FILE=$(.claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON")

     echo "Checkpoint saved: $CHECKPOINT_FILE"
     echo ""
     echo "Resume with:"
     echo "  /implement $PLAN_PATH $CURRENT_PHASE"
     echo ""
     echo "Review debug report:"
     echo "  $DEBUG_REPORT_PATH"
     echo ""

     # Exit gracefully
     exit 0
   }
   ```

**Expected Outcome**:
- All four handlers fully implemented
- Each handler performs appropriate actions
- State properly managed (checkpoints, plan updates, logging)

### Step 6: Implement Plan Annotation for Debug Reports (45 minutes)

**Objective**: Link debug report to plan file for future reference

**Note**: /debug command already handles plan annotation (see debug.md lines 180-244), but /implement should verify and enhance this annotation after test failure resolution.

**Location**: After user chooses action and handler completes

**Implementation**:

6.1. **Verify Debug Annotation Exists**
   ```bash
   # After /debug completes, check if plan was annotated
   # /debug adds "#### Debugging Notes" section after failed phase

   # Read current phase section from plan
   PHASE_SECTION=$(grep -A 50 "^### Phase $CURRENT_PHASE:" "$PLAN_PATH")

   # Check if debugging notes exist
   if echo "$PHASE_SECTION" | grep -q "#### Debugging Notes"; then
     echo "✓ Debug annotation already added by /debug command"
   else
     echo "⚠ Debug annotation missing, adding now..."
     # Add annotation (fallback)
     add_debug_annotation_to_plan
   fi
   ```

6.2. **Add/Update Debug Annotation (Fallback)**
   ```bash
   add_debug_annotation_to_plan() {
     # This is a fallback if /debug didn't annotate the plan
     # Use Edit tool to add debugging notes after phase tasks

     ANNOTATION="#### Debugging Notes
   - **Date**: $(date +%Y-%m-%d)
   - **Issue**: Test failure in phase $CURRENT_PHASE
   - **Debug Report**: [$DEBUG_REPORT_PATH]($DEBUG_REPORT_PATH)
   - **Root Cause**: $ROOT_CAUSE
   - **Resolution**: Pending"

     # Use Edit tool (in agent context) to insert after phase tasks
     # Find: "Last task in phase"
     # Insert after: Debugging Notes section
   }
   ```

6.3. **Update Resolution Status (If Tests Pass After Retry)**
   ```bash
   # This code runs in Step 3.5 (Update Debug Resolution)
   # Already exists in implement.md (lines 890-920)
   # Ensures proper integration with existing resolution tracking

   # If phase was previously debugged and now passes:
   # - Update "Resolution: Pending" → "Resolution: Applied"
   # - Add commit hash after git commit succeeds
   ```

**Expected Outcome**:
- Debug report linked in plan file
- Debugging notes section created or verified
- Resolution status updated when tests pass

### Step 7: Logging Integration (30 minutes)

**Objective**: Log debug integration events to adaptive-planning.log

**Location**: Throughout debug integration flow

**Implementation**:

7.1. **Log Debug Invocation**
   ```bash
   # Source logger if not already loaded
   if ! type log_replan_invocation &>/dev/null; then
     source .claude/lib/adaptive-planning-logger.sh
   fi

   # Log debug analysis trigger
   log_test_failure_pattern "$CURRENT_PHASE" "1" "$ERROR_SUMMARY"

   # Note: We log single failure because debug is invoked on first failure
   # Adaptive replanning (test_failure trigger) requires 2+ consecutive failures
   ```

7.2. **Log User Choice**
   ```bash
   # Log user's choice for audit trail
   write_log_entry "INFO" "debug_user_choice" \
     "User chose '$USER_CHOICE' for phase $CURRENT_PHASE test failure" \
     "{\"phase\": $CURRENT_PHASE, \"choice\": \"$USER_CHOICE\", \"debug_report\": \"$DEBUG_REPORT_PATH\"}"
   ```

7.3. **Log Handler Outcomes**
   ```bash
   # In each handler, log the outcome

   # Revise handler:
   log_replan_invocation "$CURRENT_PHASE" "update_tasks_debug" "$REVISE_STATUS" "$ACTION_TAKEN"

   # Continue handler:
   write_log_entry "WARN" "phase_incomplete" \
     "Phase $CURRENT_PHASE continued despite test failure" \
     "{\"phase\": $CURRENT_PHASE, \"reason\": \"user_continue\"}"

   # Skip handler:
   write_log_entry "WARN" "phase_skipped" \
     "Phase $CURRENT_PHASE skipped due to test failure" \
     "{\"phase\": $CURRENT_PHASE, \"reason\": \"$SKIP_REASON\"}"

   # Abort handler:
   write_log_entry "ERROR" "implementation_aborted" \
     "Implementation aborted at phase $CURRENT_PHASE" \
     "{\"phase\": $CURRENT_PHASE, \"debug_report\": \"$DEBUG_REPORT_PATH\"}"
   ```

**Expected Outcome**:
- All debug integration events logged
- Audit trail for debugging workflow
- Integration with existing adaptive planning logs

### Step 8: Update Documentation (30 minutes)

**Objective**: Update implement.md documentation to describe debug integration

**Location**: Multiple sections of implement.md

**Implementation**:

8.1. **Update Command Description** (lines 1-50)
   - Add "automatic debug integration" to features list
   - Update dependent-commands to include "debug"

8.2. **Update Step 3.3 Documentation** (lines 591-651)
   - Replace "Enhanced Error Analysis" section
   - Add new subsection "Step 3.3.1: Automatic Debug Integration"
   - Document the four user choices
   - Explain context building for /revise --auto-mode

8.3. **Add Debug Integration Examples** (new section)
   ```markdown
   ### Debug Integration Example

   When test fails in Phase 3:
   1. /implement automatically invokes /debug
   2. Debug report created: specs/reports/026_debug_phase3.md
   3. Summary box displayed with root cause
   4. User chooses action (r/c/s/a)
   5. Handler executes appropriate logic
   6. Plan annotated with debug notes
   7. Implementation continues or exits based on choice
   ```

8.4. **Update Error Handling Section** (lines 499-545)
   - Add subsection about debug integration
   - Document graceful degradation if /debug fails
   - Explain fallback to basic error analysis

**Expected Outcome**:
- Documentation accurately reflects new behavior
- Examples provided for users
- Error handling clearly documented

## Code Examples

### Example 1: SlashCommand Invocation for /debug

```bash
# Build error description
ERROR_SUMMARY=$(echo "$ERROR_OUTPUT" | grep -i "error\|fail" | head -1 | cut -c1-200)
ERROR_DESC="Phase ${CURRENT_PHASE}: ${PHASE_NAME} - ${ERROR_SUMMARY}"

# Invoke /debug via SlashCommand tool
echo "PROGRESS: Running debug analysis for test failure..."

# In agent context, use SlashCommand tool:
# SlashCommand {
#   command: "/debug \"${ERROR_DESC}\" ${PLAN_PATH}"
# }

# Parse response
DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -oP 'specs/reports/[0-9]{3}_debug_[^)]+\.md' | head -1)
```

### Example 2: Context JSON for /revise --auto-mode

```json
{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Test failure requires debugging: Missing null check in auth handler",
  "suggested_action": "Add debugging tasks based on debug report findings",
  "debug_context": {
    "report_path": "specs/reports/026_debug_phase3.md",
    "root_cause": "Missing null check in auth handler",
    "error_output": "See debug report for full details"
  },
  "task_operations": [
    {
      "action": "insert",
      "position": 1,
      "task": "Fix: Add null check in auth handler before accessing user object"
    }
  ]
}
```

### Example 3: Unicode Summary Box Template

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST FAILURE ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase: 3 - Core Implementation

Issue:
  Test failure: null pointer exception in auth.login()

Debug Report:
  specs/reports/026_debug_phase3.md

Root Cause:
  Missing null check in auth handler before accessing user.email property

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACTIONS AVAILABLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(r) Revise plan based on debug findings
    Automatically updates plan with /revise --auto-mode
    Incorporates debug context and suggestions

(c) Continue anyway
    Skip this phase and continue to next phase
    Phase will remain marked incomplete

(s) Skip phase
    Mark phase as skipped in plan
    Document skip reason and continue

(a) Abort implementation
    Save checkpoint and exit
    Resume later with /implement [plan] [phase]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Choose action [r/c/s/a]:
```

### Example 4: Plan Annotation Update

```markdown
### Phase 3: Core Implementation [COMPLETED]

Tasks:
- [x] Implement authentication handler
- [x] Add error handling
- [x] Write unit tests

#### Debugging Notes
- **Date**: 2025-10-10
- **Issue**: Test failure: null pointer exception in auth.login()
- **Debug Report**: [../reports/026_debug_phase3.md](../reports/026_debug_phase3.md)
- **Root Cause**: Missing null check in auth handler
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

### Example 5: Handler Response Flow

```bash
# User chooses (r) - Revise with debug findings

handle_revise_with_debug() {
  # 1. Build context JSON
  REVISION_CONTEXT=$(jq -n \
    --arg type "update_tasks" \
    --argjson phase "$CURRENT_PHASE" \
    --arg reason "Test failure: $ROOT_CAUSE" \
    --arg debug_report "$DEBUG_REPORT_PATH" \
    '{
      revision_type: $type,
      current_phase: $phase,
      reason: $reason,
      debug_context: {report_path: $debug_report}
    }')

  # 2. Invoke /revise --auto-mode
  REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")

  # 3. Parse response
  REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

  # 4. Handle success/failure
  if [ "$REVISE_STATUS" = "success" ]; then
    echo "✓ Plan revised with debug findings"
    # Retry phase
    return 0
  else
    echo "✗ Revision failed, falling back to abort"
    handle_abort_implementation
  fi
}
```

## Testing Specifications

### Test 1: Basic Debug Integration Flow
**Objective**: Verify /debug is invoked automatically on test failure

**Setup**:
1. Create test plan: `specs/plans/test_debug_integration.md`
2. Create Phase 1 with intentional failing test
3. Run: `/implement specs/plans/test_debug_integration.md 1`

**Expected Outcome**:
- Test fails in Phase 1
- /debug invoked automatically
- Debug report created: `specs/reports/NNN_debug_*.md`
- Summary box displayed with report path and root cause
- User prompted for action choice

**Verification**:
- Debug report exists and contains root cause analysis
- Plan path passed to /debug correctly
- Error description accurately reflects test failure

### Test 2: Revise Handler Integration
**Objective**: Verify (r)evise choice invokes /revise --auto-mode correctly

**Setup**:
1. Use test plan from Test 1
2. When prompted, choose: `r`

**Expected Outcome**:
- /revise invoked with --auto-mode flag
- Context JSON includes debug_context with report path
- Plan updated with debugging tasks
- Phase implementation retried

**Verification**:
- Context JSON structure matches specification
- /revise response parsed correctly
- Plan file shows updated tasks
- Adaptive planning log shows replan invocation

### Test 3: Continue Handler
**Objective**: Verify (c)ontinue choice skips phase without marking complete

**Setup**:
1. Use test plan from Test 1
2. When prompted, choose: `c`

**Expected Outcome**:
- Phase NOT marked as complete in plan
- No git commit created for failed phase
- Checkpoint updated with "incomplete" status
- Implementation moves to next phase

**Verification**:
- Phase heading does NOT have [COMPLETED] marker
- Tasks remain unchecked in plan
- Checkpoint shows phase_N=incomplete
- Next phase begins execution

### Test 4: Skip Handler
**Objective**: Verify (s)kip choice marks phase as skipped with annotation

**Setup**:
1. Use test plan from Test 1
2. When prompted, choose: `s`
3. Enter skip reason: "Requires manual investigation"

**Expected Outcome**:
- Phase marked [SKIPPED] in plan
- Skip annotation added with reason and debug report link
- Checkpoint updated with skip status
- Implementation moves to next phase

**Verification**:
- Phase heading shows [SKIPPED] marker
- Skip annotation section present with all fields
- Debug report linked correctly
- Checkpoint contains skip_reason

### Test 5: Abort Handler
**Objective**: Verify (a)bort choice saves checkpoint and exits gracefully

**Setup**:
1. Use test plan from Test 1
2. When prompted, choose: `a`

**Expected Outcome**:
- Checkpoint saved with "failed" status
- Error details and debug report path in checkpoint
- Implementation exits with status 0
- Resume instructions displayed

**Verification**:
- Checkpoint file created in `.claude/checkpoints/`
- Checkpoint contains: status=failed, debug_report path, last_error
- No unhandled errors or exceptions
- Can resume with `/implement [plan] [phase]`

### Test 6: Debug Invocation Failure Handling
**Objective**: Verify graceful fallback when /debug fails

**Setup**:
1. Mock /debug to return error or timeout
2. Trigger test failure in test plan

**Expected Outcome**:
- /debug invocation failure detected
- Fallback to basic error analysis
- Summary box shows "(debug failed)" for report path
- Root cause shows fallback message
- User still presented with action choices

**Verification**:
- No crash or unhandled error
- Error logged to adaptive-planning.log
- User can still choose actions (all handlers work without debug report)
- Basic error analysis output displayed

## Error Handling

### Error 1: SlashCommand Invocation Fails
**Scenario**: /debug command times out or returns error

**Detection**:
```bash
if [ -z "$DEBUG_RESULT" ] || echo "$DEBUG_RESULT" | grep -q "error"; then
  # Invocation failed
fi
```

**Handling**:
1. Log error to adaptive-planning.log
2. Set fallback values:
   - `DEBUG_REPORT_PATH="(debug failed)"`
   - `ROOT_CAUSE="Debug analysis unavailable"`
3. Display basic error analysis instead
4. Continue with user choice prompt
5. All handlers work without debug report

**User Message**:
```
Warning: Debug analysis failed to complete
Continuing with basic error analysis...
You can still choose an action based on test output.
```

### Error 2: Debug Report Path Not Found
**Scenario**: /debug completes but report path not detected in output

**Detection**:
```bash
DEBUG_REPORT_PATH=$(echo "$DEBUG_RESULT" | grep -oP 'specs/reports/[0-9]{3}_debug_[^)]+\.md' | head -1)
if [ -z "$DEBUG_REPORT_PATH" ]; then
  # Path extraction failed
fi
```

**Handling**:
1. Search specs/reports/ for most recent debug report
2. If found, use that path
3. If not found, use "(report not found)" as fallback
4. Log warning but continue

**User Message**:
```
Warning: Debug report path not detected in output
Checking for reports manually...
```

### Error 3: Root Cause Extraction Fails
**Scenario**: Debug report exists but root cause section not found

**Detection**:
```bash
ROOT_CAUSE=$(grep -A 5 "^### Root Cause Analysis" "$DEBUG_REPORT_PATH" | tail -n +2 | head -3)
if [ -z "$ROOT_CAUSE" ]; then
  # Extraction failed
fi
```

**Handling**:
1. Use generic message: "See debug report for analysis"
2. Report path still shown (user can read it manually)
3. Continue normally

**User Message**:
```
Root Cause:
  See debug report for detailed analysis
```

### Error 4: /revise --auto-mode Fails
**Scenario**: User chooses (r)evise but /revise returns error

**Detection**:
```bash
REVISE_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')
if [ "$REVISE_STATUS" != "success" ]; then
  # Revision failed
fi
```

**Handling**:
1. Display error message from /revise response
2. Log failure to adaptive-planning.log
3. Fall back to abort handler
4. Save checkpoint for manual intervention

**User Message**:
```
✗ Plan revision failed: [error message]
Falling back to abort (save checkpoint and exit)

You can fix the issue manually and resume with:
  /implement [plan] [phase]
```

### Error 5: User Input Invalid
**Scenario**: User enters invalid choice (not r/c/s/a)

**Detection**:
```bash
case "$USER_CHOICE" in
  r|c|s|a) ;;
  *) # Invalid input ;;
esac
```

**Handling**:
1. Display error message
2. Re-prompt for valid input (up to 3 attempts)
3. After 3 invalid attempts, default to abort

**User Message**:
```
Invalid choice: 'x'
Please enter one of: r, c, s, or a

Attempt 1 of 3. Choose action [r/c/s/a]:
```

### Error 6: Checkpoint Save Fails
**Scenario**: Cannot save checkpoint (disk full, permissions, etc.)

**Detection**:
```bash
CHECKPOINT_FILE=$(.claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON")
if [ -z "$CHECKPOINT_FILE" ]; then
  # Checkpoint save failed
fi
```

**Handling**:
1. Log error to stderr
2. Display warning to user
3. Continue without checkpoint (risky but better than crash)
4. Suggest manual checkpoint creation

**User Message**:
```
Warning: Failed to save checkpoint
Error: [checkpoint error message]

Implementation will continue but state may not be recoverable.
Consider stopping and resolving disk/permission issues.
```

### Error 7: Plan Annotation Fails
**Scenario**: Cannot write debug annotation to plan file

**Detection**:
```bash
# Edit tool returns error
if ! edit_plan_annotation; then
  # Annotation failed
fi
```

**Handling**:
1. Log warning
2. Continue without annotation
3. Debug report still created and linked in logs
4. User informed of manual annotation option

**User Message**:
```
Warning: Could not annotate plan with debug notes
Debug report available at: [path]
You can manually add debugging notes to the plan if needed.
```

## Integration Notes

### Integration with Existing Test Failure Detection

**Current Code** (implement.md lines 591-651):
- Step 3.3: Enhanced Error Analysis
- Uses `.claude/lib/analyze-error.sh` for basic analysis
- Displays suggestions and debug commands

**Integration Point**:
- Insert new Step 3.3.1 BEFORE existing error display
- Keep existing error analysis as fallback if /debug fails
- Replace suggestion to manually run /debug with automatic invocation

**Modified Flow**:
1. Test fails (existing detection)
2. **NEW**: Automatically invoke /debug
3. **NEW**: Display debug summary box with choices
4. **NEW**: Handle user choice
5. Existing: Continue to Step 3.4 (Adaptive Planning Detection) if continuing
6. Existing: Proceed with checkpoint updates and next phase

### Dependencies on /debug Command

**Required from /debug**:
- Accepts: `<issue-description> <plan-path>` arguments
- Creates: Debug report at `specs/reports/NNN_debug_*.md`
- Returns: Output containing report path
- Annotates: Plan file with debugging notes (automatic)

**Assumptions**:
- /debug completes within reasonable time (5 min timeout)
- Debug report contains "### Root Cause Analysis" section
- Report path in output matches pattern: `specs/reports/[0-9]{3}_debug_.*\.md`

**Fallback Plan**:
- If /debug unavailable or fails: Use basic error analysis
- If report not created: Continue with manual debugging
- If annotation fails: User can manually link report

### Dependencies on /revise Command

**Required from /revise --auto-mode**:
- Accepts: `--auto-mode --context '<json>'` flags
- Supports: `revision_type: "update_tasks"` with debug_context
- Returns: JSON response with `.status` field
- Updates: Plan file with new tasks based on debug findings

**Context Structure Used**:
```json
{
  "revision_type": "update_tasks",
  "current_phase": N,
  "reason": "Test failure: [root cause]",
  "debug_context": {
    "report_path": "[path]",
    "root_cause": "[summary]"
  },
  "task_operations": [...]
}
```

**Error Handling**:
- If /revise fails: Fall back to abort handler
- If response malformed: Log error, abort
- If plan not updated: Restore from backup, abort

### Checkpoint State Management

**Existing Fields Used**:
- `current_phase`: Track which phase failed
- `status`: "failed" when aborting
- `last_error`: Error message for debugging
- `completed_phases`: Track successful phases

**New Fields Added**:
- `debug_report`: Path to debug report for this failure
- `failure_reason`: Root cause from debug analysis
- `phase_status`: Map of phase numbers to status (incomplete, skipped)
- `skip_reason`: Reason for skipping phase (if applicable)

**Checkpoint Updates**:
- Save after /debug completes (before user choice)
- Update after user choice handled
- Final save when aborting with error details

### Logging Coordination

**Events to Log** (adaptive-planning.log):
1. Test failure detected: `log_test_failure_pattern()`
2. Debug invocation started: Custom event
3. Debug completion: Success/failure status
4. User choice: Which action selected
5. Handler execution: Outcome of each handler
6. Plan revision (if chosen): `log_replan_invocation()`

**Log Format**:
```
[2025-10-10T15:23:45Z] INFO debug_invocation: Invoking /debug for phase 3 | data={"phase":3,"error":"null pointer"}
[2025-10-10T15:24:12Z] INFO debug_complete: Debug report created | data={"report":"specs/reports/026_debug_phase3.md"}
[2025-10-10T15:24:30Z] INFO debug_user_choice: User chose 'revise' | data={"phase":3,"choice":"r"}
[2025-10-10T15:24:45Z] INFO replan: Replanning invoked: update_tasks_debug -> success | data={"phase":3}
```

**Integration with Existing Logs**:
- Use existing logger functions where applicable
- Add new event types for debug-specific events
- Maintain consistent JSON data format

## Acceptance Criteria

- [ ] Test failure automatically triggers /debug invocation
- [ ] Debug report path and root cause extracted from /debug output
- [ ] Unicode summary box displays all required information
- [ ] All four user choices (r/c/s/a) implemented and working
- [ ] (r) Revise: Invokes /revise --auto-mode with correct context JSON
- [ ] (c) Continue: Skips phase without marking complete, moves to next
- [ ] (s) Skip: Marks phase [SKIPPED] with annotation, continues
- [ ] (a) Abort: Saves checkpoint with error details, exits gracefully
- [ ] Plan annotated with debug notes (verified or added)
- [ ] All events logged to adaptive-planning.log
- [ ] Graceful fallback if /debug fails (basic error analysis)
- [ ] Documentation updated in implement.md
- [ ] All 6 test cases pass successfully

## Files Modified

- `/home/benjamin/.config/.claude/commands/implement.md`
  - Lines 591-651: Replace Step 3.3 with new debug integration flow
  - Lines 1-50: Update command description and dependencies
  - Add new section: Debug Integration Examples

## Dependencies

**Commands**:
- `/debug` - Must be functional and accessible via SlashCommand
- `/revise` - Must support --auto-mode with debug context

**Libraries**:
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore functions
- `.claude/lib/adaptive-planning-logger.sh` - Logging functions
- `.claude/lib/analyze-error.sh` - Fallback error analysis

**Tools**:
- SlashCommand - For invoking /debug and /revise
- Edit - For plan annotation updates
- jq - For JSON parsing and construction

## Success Metrics

1. **Automation**: 100% of test failures trigger automatic debug analysis
2. **Usability**: Clear action choices reduce user decision time by 50%
3. **Traceability**: All debug sessions linked to plans via annotations
4. **Reliability**: Graceful fallback ensures no workflow interruptions
5. **Auditability**: Complete event trail in adaptive-planning.log

## Notes

- This phase builds on existing error analysis (Step 3.3)
- Debug integration is non-blocking - failures degrade gracefully
- User retains full control via four action choices
- All handlers maintain checkpoint consistency
- Plan annotations create permanent debugging history
- Integration with adaptive planning enables automatic plan updates
