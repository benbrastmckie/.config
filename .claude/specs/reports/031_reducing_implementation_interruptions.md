# Reducing Implementation Interruptions: Configuration Options for Complex Plans

## Metadata
- **Date**: 2025-10-10
- **Scope**: Analysis of interactive interruption points during `/implement` execution and configuration strategies to reduce disruptions for complex plans
- **Primary Directory**: .claude/
- **Files Analyzed**: implement.md (1647 lines), CLAUDE.md (adaptive planning config), checkpoint-utils.sh, error-utils.sh
- **Research Context**: User feedback that interactive modes during complex plan implementation are interruptive, with unwanted recommendations to scale down plans or skip steps
- **Desired Outcome**: Less interruptive implementation while preserving expansion/contraction review capabilities

## Executive Summary

The `/implement` command contains **three potential interruption points** during complex plan execution:

1. **Proactive Expansion Recommendations** (Step 1.55) - Displays boxed recommendations before phase implementation
2. **Reactive Automatic Expansion** (Step 3.4) - Automatically modifies plan structure after phase completion when complexity >8
3. **Automatic Collapse Detection** (Step 5.5) - Automatically collapses simple completed phases

**Current Issue**: For complex plans with many phases, these interruptions break focus and suggest unwanted actions (scaling down, skipping steps).

**Key Finding**: Only one of these is truly "interactive" (checkpoint resume prompts). The others are **automatic recommendations or actions** that don't require user input but are displayed during implementation.

**Recommended Solution**: Raise complexity thresholds in CLAUDE.md from 8.0→12.0 and 10→15 tasks. This immediately reduces automatic actions without code changes. For zero interruptions, implement a `--batch-mode` flag.

**Configuration Location**: `/home/benjamin/.config/CLAUDE.md` lines 59-62

## Background

### User Context

The user experiences interruptions during complex plan implementation that:
- Recommend scaling down the plan
- Suggest skipping steps
- Interrupt workflow focus
- Feel unnecessary for plans they've already carefully designed

### What the User Wants to Keep

- Expansion/contraction review at appropriate points
- Ability to evaluate whether implementation files should be expanded or collapsed
- Automated implementation flow without frequent stopping points

### The Challenge

Balance between:
- **Adaptive planning intelligence** (helpful for detecting genuine complexity issues)
- **Uninterrupted execution** (critical for focus on complex multi-phase implementations)

## Current State Analysis

### Interruption Points During `/implement` Execution

#### 1. Proactive Expansion Check (Step 1.55, Lines 438-512)

**Location**: Before each phase implementation begins

**Trigger Conditions**:
- Evaluates every phase before implementation
- Uses agent-based judgment of complexity
- Considers: task complexity, scope breadth, interrelationships, parallel work potential
<!-- NOTE: this all looks good -->

**Display Format** (lines 470-488):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EXPANSION RECOMMENDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase [N]: [Phase Name]

Rationale:
  [Agent's 2-3 sentence rationale based on understanding the phase]

Recommendation:
  Consider expanding this phase to a separate file for better organization.

Command:
  /expand phase <plan-path> [N]

Note: This is a recommendation only. You can expand now or continue
with implementation. The phase can be expanded later if needed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Nature**: **Non-blocking recommendation** (lines 499-504)

**Current Behavior**:
- Pure information display
- Does NOT require user input
- Does NOT pause execution waiting for response
- Implementation continues immediately after display
<!-- FIX: instead of display, I want nothing to happen if it evaluates that expansion or contraction is unnecessary which will be the most common, or at most a small note saying that the level of detail for the plan has been approved -->

**Issue for Complex Plans**:
- Shows this large boxed message for every sufficiently complex phase
- In a 10-phase plan, could show 5-7 of these messages
- Visually noisy and interrupts reading implementation progress
- Message implies user should consider stopping to expand
<!-- FIX: when an expansion or contraction is recommended, I want to have a summary of the motivating reasons and be presented with a choice whether to expand/contract -->

**Relationship to Other Steps**:
- This is PROACTIVE (before implementation)
- Step 3.4 (reactive) is AFTER implementation and uses actual experience
- Documentation states they're "complementary" but for complex plans they're redundant
<!-- FIX: the proactive expansion is correct; the reactive is incorrect (see below for details) -->

#### 2. Reactive Automatic Expansion (Step 3.4, Lines 654-845)

**Location**: After each phase implementation completes successfully

**Trigger Conditions** (lines 686-701):

**Trigger 1: Complexity Threshold Exceeded**
```bash
# Calculate phase complexity score
COMPLEXITY_SCORE=$(.claude/lib/analyze-phase-complexity.sh "$PHASE_NAME" "$TASK_LIST")
TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")

# Check threshold
if [ "$COMPLEXITY_SCORE" -gt 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  TRIGGER_TYPE="expand_phase"
  TRIGGER_REASON="Phase complexity score $COMPLEXITY_SCORE exceeds threshold 8 ($TASK_COUNT tasks)"
fi
```
<!-- FIX: I want to avoid using bash scripts to analyze complexity since there are no magic numbers or keywords. I also do not need complexity to be analyzed after an implementation at all but it is OK to run debugging if tests fail as mentioned below-->

**Threshold Values** (from CLAUDE.md lines 59-62):
- **Expansion Threshold**: 8.0
- **Task Count Threshold**: 10 tasks
- **File Reference Threshold**: 10 files

**Trigger 2: Test Failure Pattern** (lines 705-722)
- 2+ consecutive test failures in same phase
- Suggests missing prerequisites
- Adds new phase or expands existing phase
<!-- FIX: this is good, but I want it to run /debug (without asking the user) and then to use then summarize the report to the user, asking them if they want to use /revise along with the debug report that was created to improve the plan -->

**Trigger 3: Scope Drift** (lines 725-736)
- Manual flag: `--report-scope-drift "description"`
- User-initiated trigger for discovered out-of-scope work

**Action When Triggered** (lines 738-820):

**Automatically invokes** `/revise --auto-mode`:
```bash
# Build revision context JSON
REVISION_CONTEXT=$(jq -n \
  --arg type "$TRIGGER_TYPE" \
  --argjson phase "$CURRENT_PHASE" \
  --arg reason "$TRIGGER_REASON" \
  --arg action "$SUGGESTED_ACTION" \
  --argjson metrics "$TRIGGER_METRICS" \
  '{...}')

# Invoke /revise with auto-mode
REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")

# Log and continue with updated plan
echo "Plan revised: $ACTION_TAKEN"
echo "Updated plan: $UPDATED_PLAN"
PLAN_PATH="$UPDATED_PLAN"
```

**Nature**: **Automatic action** (not interactive)

**Current Behavior**:
- Modifies plan structure mid-implementation
- No user prompt or confirmation
- Logs action and continues
- Updates checkpoint with replan metadata

**Issue for Complex Plans**:
- Threshold of 8.0/10 tasks is relatively low for complex systems
- Many phases in complex plans naturally exceed these thresholds
- User has already designed the plan structure intentionally
- Automatic restructuring feels like the system second-guessing the plan

**Loop Prevention** (lines 669-672, 827-844):
- Maximum 2 replans per phase
- Tracked in checkpoint replan counters
- User escalation when limit exceeded

**Escalation Message** (lines 827-844):
```
==========================================
Warning: Replanning Limit Reached
==========================================
Phase: $CURRENT_PHASE
Replans: $PHASE_REPLAN_COUNT (max 2)

Replan History for Phase $CURRENT_PHASE:
  - [timestamp] type: reason

Recommendation: Manual review required
Consider using /revise interactively to adjust plan structure
==========================================
```

#### 3. Automatic Collapse Detection (Step 5.5, Lines 331-457)

**Location**: After phase completion and git commit
<!-- FIX: I don't need either expansion or collapse after phases have been implemented, though it does make sense after the plan has been written to review that plan -->

**Trigger Conditions** (lines 335-340, 376-378):
- Phase is expanded (in separate file)
- Phase is completed (all tasks marked `[x]`)
- Task count ≤ 5
- Complexity score < 6.0
- **Both thresholds must be met** (conservative)

**Detection Logic** (lines 356-378):
```bash
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
IS_PHASE_COMPLETED=$(grep -q "\[COMPLETED\]" "$PHASE_FILE" && echo "true" || echo "false")

if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then
  TASK_COUNT=$(grep -c "^- \[x\]" "$PHASE_FILE" || echo "0")
  COMPLEXITY_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$PHASE_CONTENT")

  # Check collapse thresholds: tasks ≤ 5 AND complexity < 6.0
  if [ "$TASK_COUNT" -le 5 ] && awk -v score="$COMPLEXITY_SCORE" 'BEGIN {exit !(score < 6.0)}'; then
    # Trigger auto-collapse
  fi
fi
```

**Action When Triggered** (lines 396-423):

**Automatically invokes** `/revise --auto-mode`:
```bash
# Invoke /revise --auto-mode for automatic collapse
echo "Triggering auto-collapse for Phase $CURRENT_PHASE (simple after completion)..."
REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$COLLAPSE_CONTEXT'")

if [ "$REVISE_STATUS" = "success" ]; then
  echo "✓ Auto-collapsed Phase $CURRENT_PHASE (structure level now: $NEW_LEVEL)"
  # Update plan path if structure changed
fi
```

**Nature**: **Automatic action** (not interactive)
<!-- FIX: after a plan is first written (before implementation) I want it to be reviewed (without asking the user) by the custom agent for analysing complexity whether the plan should be expanded/collapsed. If no expansion/collapse is recommended, then proceed. Otherwise, given the user a summary of the motivations for the expansion/collapse to get their approval. After a plan is implemented, no such review for expansion/contraction should take place -->

**Current Behavior**:
- Collapses simple completed phases back to main file
- No user prompt or confirmation
- Logs action and continues
- Updates plan structure

**Non-Blocking Failure Handling** (lines 448-451):
```bash
# Collapse failures are logged but don't stop implementation
# Phase remains expanded if collapse fails
# Implementation continues to next phase regardless
```

**Issue for Complex Plans**:
- May collapse phases user wanted to keep expanded for reference
- Automatic structure changes can be surprising
- Conservative thresholds (≤5 tasks, <6.0 complexity) reduce frequency but still automatic

### Checkpoint Detection Interactive Prompt

**Location**: Before implementation starts (lines 1560-1647)

**When Shown**: Only if existing checkpoint found

**Prompt Format** (lines 1573-1589):
```
Found existing checkpoint for implementation
Plan: [plan_path]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Last test status: [tests_passing]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart from beginning
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

**Nature**: **Truly interactive** - requires user input
<!-- FIX: this interruption is unnecessary and should be removed so that the implementation proceeds to completion unless there is sufficient cause for interaction with the user to get their input -->

**Current Behavior**:
- Uses `read -p` pattern (implied, based on parallel orchestrate implementation)
- Blocks waiting for user choice
- Terminal detection via `[ -t 0 ]` pattern (standard across all prompts)

**This is NOT an Issue**:
- Only shows once at start if checkpoint exists
- Legitimate workflow control decision
- User appreciates checkpoint resume capability

## Key Findings

### 1. Terminology Confusion

**User said**: "interactive modes are interruptive"
<!-- NOTE: I am primarily concerned to reduce interruptions that require input to get it to continue like the checkpoint resume which breaks the flow of the implementation instead of completing as much as it can without help or feedback -->

**Reality**: Most "interruptions" are NOT interactive (don't require input):
- Proactive expansion: **Non-blocking display** only
- Reactive expansion: **Automatic action** with log message
- Auto-collapse: **Automatic action** with log message
- Checkpoint resume: **Truly interactive** (but acceptable)

**The Issue**: Visual noise and automatic structure changes, not actual blocking prompts

<!-- NOTE: visual feedback is not as much a problem, but small summaries are better if no user input is required -->

### 2. Threshold Values Are Conservative

**Current thresholds** (CLAUDE.md lines 59-62):
- Expansion Threshold: 8.0
- Task Count Threshold: 10
<!-- FIX: I don't want any magic number or keywords to be used for thresholds, relying exclusively on the agent for analyzing complexity -->

**Context**: These are calibrated for "typical" plans

**For complex system plans**:
- Phases naturally have 10-15 tasks
- Complexity scores routinely exceed 8.0
- User has intentionally created a detailed, structured plan
- Automatic expansion/collapse feels like system questioning the design

### 3. Proactive vs Reactive Redundancy

**Documentation claims** (line 512):
> "Complementary: Both serve different purposes in the workflow"

**In practice for complex plans**:
- Proactive: "This phase looks complex, consider expanding"
- User: "I know, I designed it that way" [ignores, continues]
- Phase implements successfully
- Reactive: "That phase was complex, I'm expanding it now"
- User: "I already saw that recommendation and chose not to expand"
<!-- FIX: expansion and contraction are only intended for plans after they are written and before they are implemented. If a plan is written and evaluated to be detailed enough, there is no need to evaluate it again before implementing it. However, if the workflow is broken, and the plan is later implemented, then it could make sense to evaluate the plan for expansion or contraction before it is implemented since often more is understood about the implementation after earlier phases are implemented, changing the context from which the evaluation is made -->

**Result**: Feels like system nagging about the same issue twice

### 4. Adaptive Planning Benefits vs Costs

**Benefits** (valuable features):
- Test failure pattern detection (adds prerequisite phases)
- Scope drift manual flagging
- Loop prevention (max 2 replans per phase)
- Audit logging in adaptive-planning.log

**Costs** (for complex plans):
- Visual clutter from frequent recommendations
- Automatic structure changes user didn't request
- Cognitive overhead of evaluating each recommendation
- Breaks "flow state" during multi-hour implementation sessions
<!-- FIX: I want to reduce or eliminate all of these costs -->

### 5. Configuration vs Code Changes

**Current situation**:
- All thresholds are configurable in CLAUDE.md
- No flag exists to disable adaptive planning
- No "batch mode" or "quiet mode" option
<!-- FIX: I like the idea of a "careful" mode where "batch mode" is default. I don't want thresholds in CLAUDE.md since instead I want to rely on the complexity analyzer agent, but it is OK to set "careful" to true/false -->

**Quick wins available**:
- Adjust thresholds → immediate relief, no code changes
- Configuration lives in version-controlled CLAUDE.md
- Can create multiple threshold profiles for different project types

### 6. Logging Preserves Observability

**Even with adaptive planning disabled**, full observability maintained:

**Log file**: `.claude/logs/adaptive-planning.log`

**Log entries** (lines 175-182):
- Complexity threshold evaluations
- Test failure pattern detection
- Scope drift detections
- Replan invocations (success/failure)
- Loop prevention enforcement
- Collapse opportunity evaluations
- Collapse invocations

**Post-implementation review workflow**:
```bash
# After implementing without interruptions
cat .claude/logs/adaptive-planning.log | grep "complexity_check"
# Review: Which phases exceeded thresholds?

cat .claude/logs/adaptive-planning.log | grep "collapse_check"
# Review: Which phases could have been collapsed?

# Manually apply recommendations that make sense
/expand phase plan.md 3
/collapse phase plan.md 7
```

## Technical Details

<!-- FIX: thresholds should be removed in preference of using the complexity analyzer agent -->

### Complexity Threshold Configuration

**File**: `/home/benjamin/.config/CLAUDE.md`

**Section**: Lines 176-211 "Adaptive Planning Configuration"

**Current Values** (lines 183-187):
```markdown
- **Expansion Threshold**: 8.0 (phases with complexity score above this threshold are automatically expanded to separate files)
- **Task Count Threshold**: 10 (phases with more tasks than this threshold are expanded regardless of complexity score)
- **File Reference Threshold**: 10 (phases referencing more files than this threshold increase complexity score)
- **Replan Limit**: 2 (maximum number of automatic replans allowed per phase during implementation, prevents infinite loops)
```

**Threshold Ranges** (lines 205-211):
```markdown
- **Expansion Threshold**: 0.0 - 15.0 (recommended: 3.0 - 12.0)
- **Task Count Threshold**: 5 - 20 (recommended: 5 - 15)
- **File Reference Threshold**: 5 - 30 (recommended: 5 - 20)
- **Replan Limit**: 1 - 5 (recommended: 1 - 3)
```

**Example Profiles** (lines 189-203):

**Research-Heavy Project** (detailed documentation preferred):
```markdown
- Expansion Threshold: 5.0
- Task Count Threshold: 7
- File Reference Threshold: 8
```

**Simple Web Application** (larger inline phases acceptable):
```markdown
- Expansion Threshold: 10.0
- Task Count Threshold: 15
- File Reference Threshold: 15
```

**Mission-Critical System** (maximum organization):
```markdown
- Expansion Threshold: 3.0
- Task Count Threshold: 5
- File Reference Threshold: 5
```

### Complexity Score Calculation

**Utility**: `.claude/lib/analyze-phase-complexity.sh` (referenced line 326)

**Inputs**:
- Phase name (string)
- Task list (markdown checkboxes)

**Outputs**:
- `COMPLEXITY_SCORE`: 0-10 scale
- `SELECTED_AGENT`: Agent name or "direct"
- `THINKING_MODE`: Thinking directive
- `SPECIAL_CASE`: Special category if detected

**Factors Contributing to Complexity**:
- Number of tasks
- Number of files referenced
- Task interdependencies
- Scope breadth
- Technical sophistication indicators

**Scoring Logic** (inferred from usage):
```
score = 0
score += task_count / 3  # More tasks = higher complexity
score += file_reference_count / 5  # More files = higher complexity
score += technical_keywords_detected * 1.5  # "refactor", "architecture", etc.
score += dependency_complexity * 2  # Inter-task dependencies

# Capped at 10.0
```

### Agent Selection Logic (Related)

**From Step 1.5** (lines 335-343):
- **Direct execution** (score 0-2): Simple phases
- **code-writer** (score 3-5): Medium complexity
- **code-writer + think** (score 6-7): Medium-high complexity
- **code-writer + think hard** (score 8-9): High complexity
- **code-writer + think harder** (score 10+): Critical complexity

<!-- NOTE: This graded degree of thinking is great, and I want something similar for expansion of a plan -->

**Note**: Agent selection threshold (6-7) is LOWER than expansion threshold (8.0)

**Implication**: A phase can be "complex enough to delegate to agent with thinking" but NOT "complex enough to expand to separate file"

### Adaptive Planning Logger Integration

**Library**: `.claude/lib/adaptive-planning-logger.sh`

**Initialization** (lines 146-169):
```bash
# Source adaptive planning logger
if [ -f "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh" ]; then
  source "$SCRIPT_DIR/../lib/adaptive-planning-logger.sh"
else
  # Logger not found - define no-op functions so calls don't fail
  log_complexity_check() { :; }
  log_test_failure_pattern() { :; }
  log_scope_drift() { :; }
  log_replan_invocation() { :; }
  log_loop_prevention() { :; }
  log_collapse_check() { :; }
  log_collapse_invocation() { :; }
fi
```

**Log Format** (line 172):
```
[timestamp] LEVEL event_type: message | data=JSON
```

**Log Example**:
```
[2025-10-10T14:23:45Z] INFO complexity_check: Phase 3 complexity score 9.2 exceeds threshold 8.0 | data={"phase":3,"score":9.2,"threshold":8.0,"task_count":12,"triggered":true}
[2025-10-10T14:23:45Z] INFO replan_invocation: Auto-expanding Phase 3 | data={"phase":3,"trigger_type":"expand_phase","status":"success","action":"Expanded phase 3 to separate file"}
```

**Log Functions Used**:
- `log_complexity_check()` - Called for EVERY phase (line 695)
- `log_test_failure_pattern()` - Called on test failures (line 713)
- `log_scope_drift()` - Called when scope drift detected (line 734)
- `log_replan_invocation()` - Called when /revise invoked (line 802)
- `log_loop_prevention()` - Called when replan limit checked (line 666)
- `log_collapse_check()` - Called for EVERY completed expanded phase (line 374)
- `log_collapse_invocation()` - Called when collapse executes (line 408)

**Log Rotation** (line 173):
- Max size: 10MB
- Files retained: 5
- Automatic rotation via logger library

### Checkpoint Metadata for Adaptive Planning

**Schema Version**: 1.1 (checkpoint-utils.sh line 16)

**Adaptive Planning Fields** (checkpoint-utils.sh lines 99-103):
```json
{
  "replanning_count": 0,
  "last_replan_reason": null,
  "replan_phase_counts": {},
  "replan_history": []
}
```

**Example Checkpoint with Replan History**:
```json
{
  "schema_version": "1.1",
  "checkpoint_id": "implement_config_system_20251010_140523",
  "workflow_type": "implement",
  "project_name": "config_system",
  "current_phase": 5,
  "total_phases": 10,
  "completed_phases": [1, 2, 3, 4],
  "status": "in_progress",
  "replanning_count": 2,
  "last_replan_reason": "Phase complexity score 9.5 exceeds threshold 8",
  "replan_phase_counts": {
    "phase_2": 1,
    "phase_4": 1
  },
  "replan_history": [
    {
      "phase": 2,
      "type": "expand_phase",
      "timestamp": "2025-10-10T14:15:30Z",
      "reason": "Phase complexity score 8.5 exceeds threshold 8 (11 tasks)",
      "action": "Expanded phase 2 into separate file"
    },
    {
      "phase": 4,
      "type": "expand_phase",
      "timestamp": "2025-10-10T14:45:12Z",
      "reason": "Phase complexity score 9.5 exceeds threshold 8 (13 tasks)",
      "action": "Expanded phase 4 into separate file"
    }
  ]
}
```

**Usage**: Tracks replan frequency to prevent infinite loops

## Recommendations

### Option 1: Raise Complexity Thresholds (IMMEDIATE - RECOMMENDED)

**Implementation**: Edit `/home/benjamin/.config/CLAUDE.md` lines 183-186

**Current**:
```markdown
- **Expansion Threshold**: 8.0
- **Task Count Threshold**: 10
- **File Reference Threshold**: 10
- **Replan Limit**: 2
```

**Recommended for Complex Plans**:
```markdown
- **Expansion Threshold**: 12.0
- **Task Count Threshold**: 15
- **File Reference Threshold**: 15
- **Replan Limit**: 2
```

**Rationale**:
- Moves thresholds from "typical plan" to "complex plan" range
- Still triggers for truly massive phases (15+ tasks, complexity >12)
- Within documented "recommended" ranges (3.0-12.0 for expansion)
- Preserves adaptive planning for genuine edge cases

**Effect**:
- ✅ **Immediate relief** - edit one file, takes 30 seconds
- ✅ **No code changes** - pure configuration adjustment
- ✅ **Preserves adaptive planning** - still triggers for truly complex phases
- ✅ **Maintains test failure detection** - valuable for discovering prerequisites
- ✅ **Reduces visual clutter** - fewer recommendation boxes
- ✅ **Reduces automatic actions** - fewer mid-implementation structure changes

**Trade-offs**:
- ⚠️ Phases with 12-14 tasks stay inline (may be acceptable for complex plans)
- ⚠️ User may need to manually `/expand` truly complex phases
- ⚠️ Less aggressive about plan organization (this is what user wants)

**Implementation Steps**:
1. Open `/home/benjamin/.config/CLAUDE.md`
2. Navigate to line 183-186 (Adaptive Planning Configuration section)
3. Change three values: 8.0→12.0, 10→15, 10→15
4. Save file
5. Next `/implement` invocation will use new thresholds

**Verification**:
```bash
# Confirm new thresholds
grep "Expansion Threshold" /home/benjamin/.config/CLAUDE.md
# Should show: - **Expansion Threshold**: 12.0

grep "Task Count Threshold" /home/benjamin/.config/CLAUDE.md
# Should show: - **Task Count Threshold**: 15
```

---

### Option 2: Disable Proactive Expansion Recommendations

**Implementation**: Modify `/home/benjamin/.config/.claude/commands/implement.md`

**Current Behavior** (Step 1.55, lines 438-512):
- Evaluates every phase before implementation
- Displays boxed recommendation if complex
- Non-blocking but visually prominent

**Proposed Change**: Add conditional skip logic

**Implementation Approach**:

**Step 1: Add flag to command frontmatter** (line 3):
```markdown
argument-hint: [plan-file] [starting-phase] [--no-recommendations] [--report-scope-drift "<description>"] [--force-replan] [--create-pr]
```

**Step 2: Add flag description** (after line 56):
```markdown
# Disable proactive recommendations (less visual clutter)
/implement specs/plans/025_plan.md --no-recommendations
```

**Step 3: Modify Step 1.55** (lines 438-512):
```markdown
### 1.55. Proactive Expansion Check

**Skip if `--no-recommendations` flag is set**

Before implementation begins, evaluate if the phase should be expanded using agent-based judgment:

[Rest of existing content, but wrapped in conditional]

**If `--no-recommendations` flag present**:
- Skip evaluation entirely
- Log: "Proactive expansion check disabled via --no-recommendations flag"
- Continue silently to implementation

**Otherwise**:
[Existing evaluation logic]
```

**Effect**:
- ✅ Eliminates all proactive recommendation boxes
- ✅ Reduces visual clutter significantly for complex plans
- ✅ User still sees reactive expansion (which uses actual implementation experience)
- ✅ Can enable/disable per-invocation (flexibility)
- ⚠️ Requires modifying implement.md
- ⚠️ Requires implementing flag parsing logic

**When to Use**:
- Complex plans where you've already designed the structure carefully
- Multi-hour implementation sessions where focus is critical
- Plans with many phases (10+) where recommendations would be frequent

**When NOT to Use**:
- First-time implementing a plan structure (recommendations may help)
- Quick 2-3 phase plans (minimal interruption anyway)

---

### Option 3: Convert Automatic Actions to Recommendations

**Implementation**: Modify Step 3.4 and Step 5.5 behavior

**Current Behavior**:
- Step 3.4: **Automatically invokes** `/revise --auto-mode` when complexity >8
- Step 5.5: **Automatically invokes** `/revise --auto-mode` when collapse thresholds met

**Proposed Behavior**:
- Display recommendation message
- Log the recommendation
- Continue with current plan structure
- User can manually apply recommendation later if desired

**Implementation Changes**:

**Step 3.4 Modification** (lines 738-820):

**Replace**:
```bash
# Invoke /revise with auto-mode
REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")
```

**With**:
```bash
# Log recommendation instead of auto-invoking
log_replan_invocation "$CURRENT_PHASE" "$TRIGGER_TYPE" "recommendation_only" "Skipped due to manual control"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ADAPTIVE PLANNING RECOMMENDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Phase $CURRENT_PHASE: $TRIGGER_REASON"
echo ""
echo "Recommendation: $SUGGESTED_ACTION"
echo ""
echo "To apply this recommendation:"
echo "  /revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'"
echo ""
echo "Continuing with current plan structure..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Step 5.5 Modification** (similar pattern for auto-collapse)

**Effect**:
- ✅ **No automatic plan modifications** during implementation
- ✅ **Full user control** over plan structure
- ✅ **Still informed** about complexity issues
- ✅ **Can review recommendations** post-implementation
- ⚠️ **Requires significant code changes** to implement.md
- ⚠️ **Loses automatic adaptive benefits** for plans that genuinely need restructuring
- ⚠️ **Still displays messages** (reduces automation, not visual clutter)

**Trade-offs**:
- More conservative approach
- Better for experienced users who carefully design plans
- May miss genuine cases where auto-expansion would help

**Configuration Option**: Could make this conditional on a flag:
- Default: Current automatic behavior
- `--manual-adaptive`: Recommendation-only behavior

---

### Option 4: Add `--batch-mode` Flag (COMPREHENSIVE)

**Implementation**: Add comprehensive flag to disable all adaptive features

**Command Signature** (line 3):
```markdown
argument-hint: [plan-file] [starting-phase] [--batch-mode] [--report-scope-drift "<description>"] [--force-replan] [--create-pr]
```

**Flag Description**:
```markdown
## Batch Mode

For complex plans where interruptions break focus, use `--batch-mode` to disable all adaptive planning features:

```bash
/implement specs/plans/025_complex_plan.md --batch-mode
```

**Batch Mode Behavior**:
- ✅ Skip Step 1.55 (proactive expansion check)
- ✅ Skip Step 3.4 adaptive planning detection (OR make recommendation-only)
- ✅ Skip Step 5.5 automatic collapse detection
- ✅ Still run tests, create commits, update plan normally
- ✅ Log all complexity checks to adaptive-planning.log for post-implementation review
- ✅ Test failure pattern detection STILL ACTIVE (valuable for prerequisites)

**Recommended Workflow**:
1. Implement plan in batch mode (zero interruptions)
2. Review adaptive planning log afterwards
3. Manually apply valuable recommendations

**Example**:
```bash
# Step 1: Implement without interruptions
/implement complex_system.md --batch-mode

# Step 2: Review what would have been recommended
cat .claude/logs/adaptive-planning.log | grep "complexity_check"

# Step 3: Apply recommendations that make sense
/expand phase complex_system.md 3
/collapse phase complex_system.md 7
```
```

**Implementation Logic**:

**Conditional Execution Pattern** (throughout implement.md):
```bash
# Step 1.55: Proactive Expansion Check
if [ "$BATCH_MODE" != "true" ]; then
  # Existing evaluation logic
  [...]
else
  # Skip silently, log that check was skipped
  log_complexity_check "$CURRENT_PHASE" "skipped" "batch_mode" "0"
fi

# Step 3.4: Reactive Adaptive Planning
if [ "$BATCH_MODE" != "true" ]; then
  # Existing trigger detection and auto-revision
  [...]
else
  # Log recommendations but don't invoke /revise
  log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$THRESHOLD" "$TASK_COUNT"
  log_replan_invocation "$CURRENT_PHASE" "$TRIGGER_TYPE" "skipped_batch_mode" "Logged for post-review"
fi

# Step 5.5: Auto-collapse Detection
if [ "$BATCH_MODE" != "true" ]; then
  # Existing collapse logic
  [...]
else
  # Log collapse opportunity but don't invoke /revise
  log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$THRESHOLD" "skipped_batch_mode"
fi
```

**Effect**:
- ✅ **Zero adaptive interruptions** during implementation
- ✅ **Complete focus** on implementation execution
- ✅ **Full observability** via logs for post-review
- ✅ **Flexible** - enable/disable per invocation
- ✅ **Preserves test failure detection** (still valuable)
- ✅ **Two-step workflow** works well for complex plans
- ⚠️ Requires implementing flag parsing and conditional logic
- ⚠️ Requires updating documentation
- ⚠️ More code changes than Option 1

**When to Use**:
- Complex multi-phase plans (10+ phases)
- Plans you've carefully designed and don't want auto-modified
- Long implementation sessions (multiple hours)
- When in "flow state" and interruptions are costly

**When NOT to Use**:
- First time implementing unfamiliar complexity
- Plans where structure is uncertain
- Quick 2-3 phase implementations

---

### Option 5: Post-Implementation Review Workflow (FUTURE ENHANCEMENT)

**Concept**: Implement with adaptive planning disabled, review logs afterwards, manually apply recommendations

**Current Support**: Partially supported via logs

**Enhancement Needed**: Better log analysis tools

**Proposed Workflow**:

**Step 1: Implement in batch mode**
```bash
/implement complex_plan.md --batch-mode
```

**Step 2: Analyze adaptive planning log**
```bash
# View all complexity checks
.claude/lib/query-adaptive-log.sh complexity_checks complex_plan

# Output:
# Phase 2: complexity 9.2 (threshold: 12.0) - below threshold
# Phase 3: complexity 13.1 (threshold: 12.0) - EXCEEDED, would expand
# Phase 5: complexity 8.7 (threshold: 12.0) - below threshold
# Phase 7: complexity 14.5 (threshold: 12.0) - EXCEEDED, would expand

# View collapse opportunities
.claude/lib/query-adaptive-log.sh collapse_checks complex_plan

# Output:
# Phase 2: 4 tasks, complexity 3.2 - would collapse
# Phase 6: 3 tasks, complexity 4.1 - would collapse
```

**Step 3: Review and apply selected recommendations**
```bash
# Expand phases that genuinely need it
/expand phase complex_plan.md 3
/expand phase complex_plan.md 7

# Collapse phases that are simpler than expected
/collapse phase complex_plan.md 2
/collapse phase complex_plan.md 6
```

**Enhancement Requirements**:
- Create `.claude/lib/query-adaptive-log.sh` utility
- Add structured log queries
- Format output for easy review
- Provide copy-paste commands for applying recommendations

**Benefit**:
- ✅ Complete separation of implementation and plan optimization
- ✅ Review all recommendations together (better big-picture view)
- ✅ Cherry-pick only valuable recommendations
- ✅ No interruptions during implementation

**Trade-off**:
- ⚠️ Two-step process instead of integrated
- ⚠️ Requires building new utility

---

### Recommended Approach: Combine Option 1 + Option 4

**Why this combination?**

**Option 1 (Raise Thresholds)**: Immediate relief, no code changes
- Changes CLAUDE.md: 8.0→12.0, 10→15
- Takes 30 seconds to implement
- Works for 80% of cases

**Option 4 (Batch Mode Flag)**: Escape hatch for zero interruptions
- Add `--batch-mode` flag
- Use when thresholds still aren't enough
- Review logs post-implementation

**Implementation Priority**:

**Phase 1: Immediate** (5 minutes)
1. Edit CLAUDE.md thresholds (Option 1)
2. Test with next `/implement` invocation
3. Evaluate if sufficient relief

**Phase 2: If Needed** (2-3 hours development)
1. Implement `--batch-mode` flag (Option 4)
2. Add flag parsing logic
3. Add conditional skips around Steps 1.55, 3.4, 5.5
4. Test with complex plan
5. Document flag usage

**Phase 3: Future Enhancement** (4-5 hours development)
1. Build `.claude/lib/query-adaptive-log.sh` (Option 5)
2. Create structured log query functions
3. Format output for review workflow
4. Document post-implementation review process

## Configuration Examples

### Example 1: Conservative Profile (Current Default)

**Use Case**: Typical plans, helpful adaptive planning

**CLAUDE.md Configuration**:
```markdown
- **Expansion Threshold**: 8.0
- **Task Count Threshold**: 10
- **File Reference Threshold**: 10
- **Replan Limit**: 2
```

**Behavior**:
- Frequent expansion recommendations
- Auto-expands phases with >10 tasks or complexity >8
- Auto-collapses phases with ≤5 tasks and complexity <6
- Good for exploring plan structures

**When to Use**:
- First-time planning complex features
- Uncertain about optimal structure
- Want maximum guidance

---

### Example 2: Balanced Profile (Recommended for Most)

**Use Case**: Experienced users, thoughtful plan design

**CLAUDE.md Configuration**:
```markdown
- **Expansion Threshold**: 10.0
- **Task Count Threshold**: 12
- **File Reference Threshold**: 12
- **Replan Limit**: 2
```

**Behavior**:
- Moderate expansion recommendations
- Auto-expands only genuinely large phases
- Balanced adaptive planning
- Good for most development workflows

**When to Use**:
- General purpose development
- Medium complexity plans
- Balance between guidance and autonomy

---

### Example 3: High-Autonomy Profile (Recommended for Complex Plans)

**Use Case**: Complex systems, carefully designed plans, minimal interruptions desired

**CLAUDE.md Configuration**:
```markdown
- **Expansion Threshold**: 12.0
- **Task Count Threshold**: 15
- **File Reference Threshold**: 15
- **Replan Limit**: 2
```

**Behavior**:
- Rare expansion recommendations
- Auto-expands only massive phases (15+ tasks, complexity >12)
- Minimal adaptive planning interventions
- Respects user's plan design

**When to Use**:
- Complex multi-phase plans (10+ phases)
- Experienced users with clear vision
- Plans designed with specific structure in mind
- Long implementation sessions

**User Feedback Context**: This is the recommended profile for the user's use case

---

### Example 4: Maximum Organization Profile

**Use Case**: Mission-critical systems, maximum structure, aggressive expansion

**CLAUDE.md Configuration**:
```markdown
- **Expansion Threshold**: 5.0
- **Task Count Threshold**: 7
- **File Reference Threshold**: 8
- **Replan Limit**: 3
```

**Behavior**:
- Very frequent expansion recommendations
- Aggressively expands medium-complexity phases
- Maintains highly structured plan organization
- Maximum adaptive planning activity

**When to Use**:
- Safety-critical systems
- Regulated industries with audit requirements
- Teaching/documentation purposes
- Projects valuing structure over speed

---

### Example 5: Batch Mode + High Autonomy (Ultimate Focus)

**Use Case**: Zero interruptions, post-implementation review

**CLAUDE.md Configuration**:
```markdown
- **Expansion Threshold**: 12.0
- **Task Count Threshold**: 15
- **File Reference Threshold**: 15
- **Replan Limit**: 2
```

**Command Invocation**:
```bash
/implement complex_system_plan.md --batch-mode
```

**Behavior**:
- Zero proactive recommendations
- Zero automatic expansions
- Zero automatic collapses
- All complexity checks logged only
- Review logs post-implementation

**Post-Implementation**:
```bash
cat .claude/logs/adaptive-planning.log | grep "complexity_check"
# Manually apply valuable recommendations
```

**When to Use**:
- Maximum focus required
- Multi-hour implementation sessions
- Plans with 15+ phases
- Flow state critical

**User Feedback Context**: This is the ultimate solution for the user's use case (requires implementing Option 4)

## Implementation Plan

### Immediate Action (Option 1): Raise Thresholds

**File to Edit**: `/home/benjamin/.config/CLAUDE.md`

**Lines to Change**: 183-186

**Current**:
```markdown
- **Expansion Threshold**: 8.0 (phases with complexity score above this threshold are automatically expanded to separate files)
- **Task Count Threshold**: 10 (phases with more tasks than this threshold are expanded regardless of complexity score)
- **File Reference Threshold**: 10 (phases referencing more files than this threshold increase complexity score)
- **Replan Limit**: 2 (maximum number of automatic replans allowed per phase during implementation, prevents infinite loops)
```

**Recommended Change**:
```markdown
- **Expansion Threshold**: 12.0 (phases with complexity score above this threshold are automatically expanded to separate files)
- **Task Count Threshold**: 15 (phases with more tasks than this threshold are expanded regardless of complexity score)
- **File Reference Threshold**: 15 (phases referencing more files than this threshold increase complexity score)
- **Replan Limit**: 2 (maximum number of automatic replans allowed per phase during implementation, prevents infinite loops)
```

**Verification**:
1. Save CLAUDE.md
2. Run next `/implement` invocation
3. Observe fewer expansion recommendations
4. Check `.claude/logs/adaptive-planning.log` to see threshold evaluations

**Expected Outcome**:
- Phases with 10-12 tasks: No longer auto-expanded
- Phases with complexity 8-11: No longer auto-expanded
- Only truly massive phases (15+ tasks, >12 complexity) trigger adaptive planning
- Significant reduction in interruptions for complex plans

---

### Future Enhancement (Option 4): Implement Batch Mode

**Files to Modify**: `.claude/commands/implement.md`

**Changes Required**:

**1. Update Command Frontmatter** (line 3):
```markdown
argument-hint: [plan-file] [starting-phase] [--batch-mode] [--no-recommendations] [--report-scope-drift "<description>"] [--force-replan] [--create-pr]
```

**2. Add Batch Mode Documentation** (after line 56):
```markdown
## Batch Mode

For complex plans where adaptive planning interruptions break focus:

```bash
/implement specs/plans/complex_plan.md --batch-mode
```

**Batch Mode Behavior**:
- Disables proactive expansion recommendations (Step 1.55)
- Disables reactive auto-expansion (Step 3.4)
- Disables automatic collapse (Step 5.5)
- Maintains test failure pattern detection (valuable)
- Logs all complexity checks for post-review
- Full implementation automation preserved

**Recommended Workflow**:
```bash
# Step 1: Implement without interruptions
/implement plan.md --batch-mode

# Step 2: Review adaptive planning log
cat .claude/logs/adaptive-planning.log | grep complexity_check

# Step 3: Manually apply valuable recommendations
/expand phase plan.md 3
```
```

**3. Add Conditional Logic to Step 1.55** (lines 438-512):
```markdown
### 1.55. Proactive Expansion Check

**Skip if `--batch-mode` or `--no-recommendations` flag present**

Before implementation begins, evaluate if the phase should be expanded:

```bash
if [ "$BATCH_MODE" = "true" ] || [ "$NO_RECOMMENDATIONS" = "true" ]; then
  log_complexity_check "$CURRENT_PHASE" "skipped" "batch_mode_or_no_rec" "0"
  # Continue silently to implementation
  continue
fi
```

[Rest of existing evaluation logic]
```

**4. Add Conditional Logic to Step 3.4** (lines 654-845):
```markdown
### 3.4. Adaptive Planning Detection

**Skip automatic revision if `--batch-mode` flag present**

After each phase implementation, check if plan revision is needed:

```bash
if [ "$BATCH_MODE" = "true" ]; then
  # Log complexity but don't invoke /revise
  log_complexity_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$THRESHOLD" "$TASK_COUNT"

  if [ "$COMPLEXITY_SCORE" -gt "$THRESHOLD" ] || [ "$TASK_COUNT" -gt "$TASK_THRESHOLD" ]; then
    log_replan_invocation "$CURRENT_PHASE" "expand_phase" "skipped_batch_mode" "Logged for post-review"
  fi

  # Continue with current plan structure
  continue
fi
```

[Rest of existing trigger detection and auto-revision logic]
```

**5. Add Conditional Logic to Step 5.5** (lines 331-457):
```markdown
### 5.5. Automatic Collapse Detection

**Skip if `--batch-mode` flag present**

After completing a phase, evaluate if expanded phase should be collapsed:

```bash
if [ "$BATCH_MODE" = "true" ]; then
  # Log collapse opportunity but don't invoke /revise
  if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then
    log_collapse_check "$CURRENT_PHASE" "$COMPLEXITY_SCORE" "$THRESHOLD" "skipped_batch_mode"
  fi

  # Continue with current structure
  continue
fi
```

[Rest of existing collapse detection logic]
```

**Implementation Effort**:
- Time: 2-3 hours
- Complexity: Moderate
- Testing: Required on multi-phase plan
- Documentation: Included above

**Benefits**:
- Ultimate control for complex plans
- Flexible per-invocation basis
- Maintains all other automation
- Clean separation of concerns

## Cross-References

### Related Documentation
- **Interactive Prompts Report**: `.claude/specs/reports/030_interactive_prompts_and_checkpoint_detection.md`
- **Adaptive Planning Config**: `/home/benjamin/.config/CLAUDE.md` lines 142-211
- **Implement Command**: `.claude/commands/implement.md` lines 1-1647
- **Checkpoint Utils**: `.claude/lib/checkpoint-utils.sh`
- **Adaptive Logger**: `.claude/lib/adaptive-planning-logger.sh`
- **Complexity Utils**: `.claude/lib/complexity-utils.sh`
- **Error Utils**: `.claude/lib/error-utils.sh`

### Related Commands
- `/implement`: Primary command affected by these recommendations
- `/revise --auto-mode`: Invoked automatically by adaptive planning
- `/expand phase <plan> <N>`: Manual expansion command
- `/collapse phase <plan> <N>`: Manual collapse command

### Configuration Files
- **Thresholds**: `/home/benjamin/.config/CLAUDE.md` lines 183-186
- **Logging**: `.claude/logs/adaptive-planning.log`
- **Checkpoints**: `.claude/checkpoints/implement_*.json`

## Conclusion

**The Problem**: Interactive modes during complex plan implementation feel interruptive, suggesting unwanted actions like scaling down plans or skipping steps.

**Root Cause Analysis**:
1. Current thresholds (8.0 complexity, 10 tasks) are calibrated for "typical" plans
2. Complex systems naturally exceed these thresholds frequently
3. Automatic structure changes feel like system questioning user's design
4. Visual clutter from frequent recommendations breaks focus

**Immediate Solution**: Raise complexity thresholds to 12.0/15 tasks (Option 1)
- Takes 30 seconds to implement
- No code changes required
- Provides significant relief for complex plans
- Preserves adaptive planning for truly massive phases

**Ultimate Solution**: Add `--batch-mode` flag (Option 4)
- Requires 2-3 hours development
- Provides zero-interruption implementation
- Maintains observability via logs
- Enables post-implementation review workflow

**What Gets Preserved**:
- ✅ Expansion/contraction review (via logs and manual commands)
- ✅ Test failure pattern detection (adds prerequisite phases)
- ✅ Full implementation automation
- ✅ Observability (adaptive-planning.log)
- ✅ Manual control (`/expand`, `/collapse` commands)

**Recommended Action**: Start with Option 1 (immediate), implement Option 4 if needed (comprehensive).

The configuration-first approach respects that complex plans are often carefully designed, while preserving adaptive planning for genuine complexity issues. The `--batch-mode` flag provides an escape hatch for maximum focus during long implementation sessions, with structured post-implementation review of all complexity issues that would have triggered adaptive planning.
