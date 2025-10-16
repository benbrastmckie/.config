# Smart Implementation Workflow Enhancements

## Metadata
- **Date**: 2025-10-12
- **Plan Number**: 044
- **Feature**: Reduce implementation interruptions through smart auto-resume and automatic debug integration
- **Scope**: /implement command workflow enhancements (focused on implement.md only)
- **Estimated Phases**: 4
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/reports/plan_037_adaptation/001_comprehensive_adaptation_analysis.md
  - /home/benjamin/.config/.claude/specs/reports/031_reducing_implementation_interruptions.md (referenced by 037)
- **Specs Directory**: /home/benjamin/.config/.claude/specs/

## Overview

This plan implements targeted workflow improvements for the `/implement` command to reduce unnecessary user interruptions while maintaining appropriate control points. It is a focused, pragmatic rewrite of Plan 037 that respects the current codebase state discovered through comprehensive analysis.

### Key Changes from Plan 037

**Scope Reduction**:
- **Focus on /implement only**: Defers /orchestrate enhancements (Phase 6 of original plan) due to massive structural changes (5405 lines vs expected 1953)
- **Preserves thresholds**: Keeps existing complexity thresholds (they work and are documented), adds agent-based evaluation as enhancement
- **Skips proactive expansion removal**: Retains Step 1.55 after analysis showed it's already implemented and may be valuable
- **Defers careful_mode**: Requires deeper design discussion and integration work

**Focused Objectives**:
1. **Smart Checkpoint Auto-Resume**: Eliminate unnecessary resume prompts when safe conditions met
2. **Automatic Debug Integration**: Test failures automatically invoke `/debug` with user choice prompt
3. **Hybrid Complexity Evaluation**: Add agent-based evaluation alongside thresholds (not replacing them)

### Philosophy

**Pragmatic Enhancement over Radical Refactor**:
- Work WITH the current system, not against it
- Add intelligence layers, don't remove working mechanisms
- Verify before every change
- Measure impact of improvements

## Success Criteria

- [ ] Checkpoint auto-resume works for 90%+ of safe resume scenarios
- [ ] Test failures automatically invoke `/debug` without user prompt
- [ ] User presented with clear choices after debug completes
- [ ] Agent-based complexity evaluation available as enhancement
- [ ] All existing tests pass after each phase
- [ ] Zero regressions in /implement workflow
- [ ] Documentation accurately reflects new behavior

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  /implement Workflow (Enhanced)              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Load Plan → Checkpoint Detection                        │
│     ├─ No checkpoint? → Start fresh                         │
│     └─ Checkpoint exists? → Smart Auto-Resume Check (NEW)  │
│         ├─ Safe conditions met? → Auto-resume silently     │
│         └─ Unsafe conditions? → Interactive prompt         │
│                                                             │
│  2. Implementation Loop (per phase)                         │
│     ├─ Display phase info                                   │
│     ├─ Complexity analysis (hybrid: thresholds + agent)    │
│     ├─ Implement phase                                      │
│     ├─ Run tests                                            │
│     │   ├─ Pass? → Commit and continue                     │
│     │   └─ Fail? → Auto /debug + Choice Prompt (NEW)      │
│     │       ├─ (r)evise with debug findings               │
│     │       ├─ (c)ontinue anyway                          │
│     │       ├─ (s)kip phase                               │
│     │       └─ (a)bort implementation                     │
│     └─ Update plan and save checkpoint                     │
│                                                             │
│  3. Completion                                              │
│     └─ Generate summary, cleanup checkpoint                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Smart Auto-Resume Logic

**Safe Resume Conditions** (ALL must be true):
```yaml
checkpoint_safe_for_resume:
  - tests_passing: true          # Last completed phase passed tests
  - last_error: null             # No errors in checkpoint state
  - checkpoint_age: < 7 days     # Checkpoint created within last week
  - plan_unmodified: true        # Plan file not modified since checkpoint
  - status: "in_progress"        # Not in error/escalated state
```

**Decision Flow**:
```
IF all_safe_conditions_met:
  → Log: "Auto-resuming from Phase N (all safety conditions met)"
  → Resume implementation silently
  → No user prompt
ELSE:
  → Show interactive resume prompt (current behavior)
  → Include reason why auto-resume skipped
  → Options: (r)esume, (s)tart fresh, (v)iew checkpoint, (d)elete
```

### Automatic Debug Integration

**Current Behavior** (Step 3.3 at lines 314-321 in implement.md):
```markdown
### 3.3. Enhanced Error Analysis (if tests fail)

**Workflow**: Capture error output → Run `.claude/lib/analyze-error.sh` →
Display categorized error with location, context, suggestions, debug commands

**Graceful degradation**: Document partial progress, suggest `/debug` or manual fixes
```

**New Behavior**:
```markdown
### 3.3. Automatic Debug Integration (if tests fail)

**Workflow**:
1. Capture test failure output
2. Automatically invoke: SlashCommand("/debug \"Phase N test failure\" [plan-path]")
3. Parse debug report for root cause summary
4. Display formatted debug summary with Unicode box
5. Present user with 4 choices:
   ┌─────────────────────────────────────────────┐
   │ Debug Report: Phase N Test Failure          │
   ├─────────────────────────────────────────────┤
   │ Root Cause: [Brief summary from debug]      │
   │ Debug Report: [path-to-report]              │
   └─────────────────────────────────────────────┘

   Options:
   (r) Revise plan with debug findings via /revise --auto-mode
   (c) Continue to next phase anyway (skip failed tests)
   (s) Skip current phase, mark incomplete, move to next
   (a) Abort implementation (save checkpoint)

6. Execute chosen action
```

**Error Handling**:
- If `/debug` invocation fails: Fall back to current error analysis behavior
- If debug report parsing fails: Display raw report path, present choices
- Log all debug invocations to adaptive-planning.log

### Hybrid Complexity Evaluation

**Current**: Threshold-based (CLAUDE.md lines 245-283)
```yaml
thresholds:
  expansion_threshold: 8.0
  task_count_threshold: 10
  file_reference_threshold: 10
```

**Enhanced**: Thresholds + Agent Override
```yaml
complexity_evaluation:
  step: "1.5 Phase Complexity Analysis"  # Before Step 1.55

  logic:
    1. Calculate threshold-based score (current method)
    2. IF score >= 7.0 OR tasks >= 8:
         → Invoke complexity_estimator agent for second opinion
         → Agent analyzes: task complexity, scope, interrelationships
         → Agent returns: score (1-10), recommendation, confidence
    3. IF agent score significantly differs (+/- 2 points):
         → Log discrepancy to adaptive-planning.log
         → Use agent score (more contextual)
    4. ELSE:
         → Use threshold score (faster, proven)

  benefits:
    - Preserves fast threshold checks for simple cases
    - Adds intelligent analysis for borderline cases
    - Learns from discrepancies over time
    - No breaking changes to current system
```

## Implementation Phases

### Phase 1: Smart Checkpoint Auto-Resume

**Objective**: Implement intelligent auto-resume logic to eliminate unnecessary checkpoint prompts
**Complexity**: Low-Medium
**Files Modified**:
- .claude/commands/implement.md (lines 851-868: checkpoint section)
- .claude/lib/checkpoint-utils.sh (schema updates)

#### Current State Analysis

**Checkpoint Section** (implement.md lines 851-868):
```markdown
## Checkpoint Detection and Resume

1. **Check for existing checkpoint**: Load most recent `implement` checkpoint
2. **Interactive resume prompt**: If found, present options (resume/start fresh/view/delete)
3. **Resume state**: Restore plan_path, current_phase, completed_phases
4. **Save after each phase**: After git commit, save checkpoint with progress state
5. **Cleanup on completion**: Delete checkpoint (success) or archive to failed/ (failure)

**Checkpoint state fields**:
- workflow_description, plan_path, current_phase, total_phases
- completed_phases, status, tests_passing
- replan_count, phase_replan_count, replan_history
```

#### Tasks

- [ ] **Read current checkpoint section** (implement.md lines 851-868)
  - Verify section location (expected: lines 851-868)
  - Understand current checkpoint detection flow
  - Identify where interactive prompt occurs

- [ ] **Read checkpoint-utils.sh schema**
  - Location: .claude/lib/checkpoint-utils.sh
  - Identify checkpoint data structure
  - Verify available fields: tests_passing, status, created_at, plan_path

- [ ] **Add plan_modification_time to checkpoint schema**
  - Update checkpoint save function in checkpoint-utils.sh
  - Capture plan file mtime when creating checkpoint
  - Store as: plan_modification_time: "$(stat -c %Y "$PLAN_PATH")"

- [ ] **Implement safe_resume_conditions check**
  - Add new function to checkpoint-utils.sh: check_safe_resume_conditions()
  - Inputs: checkpoint_data, plan_path
  - Logic:
    ```bash
    check_safe_resume_conditions() {
      local checkpoint_file="$1"
      local plan_path="$2"

      # Extract checkpoint data
      tests_passing=$(jq -r '.tests_passing' "$checkpoint_file")
      last_error=$(jq -r '.last_error // "null"' "$checkpoint_file")
      created_at=$(jq -r '.created_at' "$checkpoint_file")
      checkpoint_plan_mtime=$(jq -r '.plan_modification_time' "$checkpoint_file")
      status=$(jq -r '.status' "$checkpoint_file")

      # Check all conditions
      [ "$tests_passing" = "true" ] || return 1
      [ "$last_error" = "null" ] || return 1
      [ "$status" = "in_progress" ] || return 1

      # Check age (7 days = 604800 seconds)
      current_time=$(date +%s)
      checkpoint_age=$((current_time - created_at))
      [ $checkpoint_age -lt 604800 ] || return 1

      # Check plan not modified
      current_plan_mtime=$(stat -c %Y "$plan_path")
      [ "$checkpoint_plan_mtime" -ge "$current_plan_mtime" ] || return 1

      return 0  # All conditions met
    }
    ```

- [ ] **Update implement.md checkpoint detection** (around line 851)
  - Add Step 1a: "Check Safe Resume Conditions" before interactive prompt
  - Insert logic:
    ```markdown
    ### Step 1a: Safe Resume Evaluation

    Before showing interactive prompt, check if auto-resume is safe:

    ```bash
    if check_safe_resume_conditions "$CHECKPOINT_FILE" "$PLAN_PATH"; then
      # Auto-resume silently
      RESUME_PHASE=$(jq -r '.current_phase + 1' "$CHECKPOINT_FILE")
      log_info "Auto-resuming from Phase $RESUME_PHASE (all safety conditions met)"
      # Skip to Step 3: Resume State
    else
      # Show interactive prompt (current Step 2)
      SKIP_REASON=$(get_skip_reason "$CHECKPOINT_FILE" "$PLAN_PATH")
      log_info "Auto-resume skipped: $SKIP_REASON"
      # Proceed to Step 2: Interactive Resume Prompt
    fi
    ```
    ```

- [ ] **Add get_skip_reason helper function**
  - Location: checkpoint-utils.sh
  - Returns human-readable reason why auto-resume was skipped
  - Examples: "Tests failing in last phase", "Checkpoint is 10 days old", "Plan modified since checkpoint"

- [ ] **Update interactive prompt** (current Step 2)
  - Add skip reason to prompt display:
    ```markdown
    Checkpoint found for implementation.
    Auto-resume skipped: [Reason]

    Options:
    (r) Resume from Phase N
    (s) Start fresh implementation
    (v) View checkpoint details
    (d) Delete checkpoint
    ```

- [ ] **Add logging for auto-resume decisions**
  - Log to: .claude/logs/adaptive-planning.log
  - Log auto-resume: "Auto-resumed Phase N (age: X days, tests: passing, plan: unchanged)"
  - Log skip: "Auto-resume skipped for Phase N (reason: tests failing)"

#### Testing

```bash
# Test 1: Auto-resume with safe checkpoint
# Create checkpoint with tests_passing=true, recent, plan unchanged
# Run /implement [plan] → Should auto-resume silently with log message

# Test 2: Interactive prompt with stale checkpoint
# Create checkpoint 8 days old
# Run /implement [plan] → Should show prompt with reason "Checkpoint is 8 days old"

# Test 3: Interactive prompt with failed tests
# Create checkpoint with tests_passing=false
# Run /implement [plan] → Should show prompt with reason "Tests failing in last phase"

# Test 4: Interactive prompt with modified plan
# Create checkpoint, then touch plan file
# Run /implement [plan] → Should show prompt with reason "Plan modified since checkpoint"

# Test 5: Verify checkpoint schema includes plan_modification_time
# Create new checkpoint → jq '.plan_modification_time' checkpoint.json should return timestamp
```

**Expected Outcome**: Zero interruptions for safe resumes (estimated 90% of cases), clear reasoning for remaining 10%

### Phase 2: Automatic Debug Integration

**Objective**: Streamline test failure workflow by automatically invoking /debug and presenting clear choices
**Complexity**: Medium
**Files Modified**:
- .claude/commands/implement.md (lines 314-321: Step 3.3 Enhanced Error Analysis)

#### Current State Analysis

**Step 3.3 Location** (implement.md lines 314-321):
```markdown
### 3.3. Enhanced Error Analysis (if tests fail)

**Workflow**: Capture error output → Run `.claude/lib/analyze-error.sh` →
Display categorized error with location, context, suggestions, debug commands

**Error categories**: syntax, test_failure, file_not_found, import_error,
null_error, timeout, permission

**Graceful degradation**: Document partial progress, suggest `/debug` or manual fixes
```

#### Tasks

- [ ] **Verify Step 3.3 location and content**
  - Read implement.md lines 314-321
  - Confirm this is test failure handling
  - Identify where error analysis happens

- [ ] **Verify /debug command exists and is functional**
  - Check: .claude/commands/debug.md exists
  - Test invocation: SlashCommand("/debug \"test description\" [plan-path]")
  - Verify output format: Debug report path + summary

- [ ] **Replace Step 3.3 with Automatic Debug Integration**
  - Use Edit tool to replace lines 314-321
  - New content:
    ```markdown
    ### 3.3. Automatic Debug Integration (if tests fail)

    **Workflow**:

    **Step 1: Capture Test Failure**
    - Save complete test output to temporary file
    - Extract phase number and test command that failed

    **Step 2: Automatically Invoke /debug**
    - No user prompt required (automatic invocation)
    - Command: `SlashCommand("/debug \"Phase $PHASE_NUM test failure: $TEST_CMD\" $PLAN_PATH")`
    - Timeout: 300 seconds (5 minutes for debug analysis)

    **Step 3: Parse Debug Report**
    - Extract debug report path from SlashCommand output
    - Read report to extract root cause (first ## Root Cause section)
    - Truncate root cause summary to 80 characters for display

    **Step 4: Display Debug Summary**
    - Render Unicode box with debug info:
      ```
      ┌─────────────────────────────────────────────┐
      │ Debug Report: Phase N Test Failure          │
      ├─────────────────────────────────────────────┤
      │ Root Cause: [Truncated summary]             │
      │ Debug Report: [path-to-report]              │
      └─────────────────────────────────────────────┘
      ```

    **Step 5: Present User Choices**
    - Display 4 clear options:
      ```
      How would you like to proceed?

      (r) Revise plan with debug findings
          Invokes: /revise --auto-mode with debug report context
          Result: Plan updated with fixes, continues to next phase

      (c) Continue to next phase anyway
          Marks current phase incomplete, moves to Phase N+1
          Warning: Skipping failed tests may cause downstream issues

      (s) Skip current phase
          Same as (c) but explicitly marks phase as "skipped"
          Phase won't be re-attempted on resume

      (a) Abort implementation
          Saves checkpoint at current phase
          Can resume later with /implement [plan] N

      Choice [r/c/s/a]:
      ```

    **Step 6: Execute Chosen Action**

    **(r) Revise Plan**:
    - Build revision context JSON:
      ```json
      {
        "revision_type": "fix_test_failures",
        "current_phase": N,
        "test_failures": "[error summary]",
        "debug_report": "[report-path]",
        "suggested_action": "Add prerequisite tasks or fix implementation"
      }
      ```
    - Invoke: `SlashCommand("/revise $PLAN_PATH --auto-mode --context '$CONTEXT'")`
    - Parse response: updated plan structure
    - Continue implementation with revised plan

    **(c) Continue Anyway**:
    - Log warning: "Phase N completed with test failures (user choice)"
    - Add warning note to phase in plan: "⚠ Tests failed, continued anyway"
    - Do NOT mark phase as [COMPLETED], mark as [INCOMPLETE]
    - Continue to Phase N+1

    **(s) Skip Phase**:
    - Mark phase as [SKIPPED] in plan
    - Log: "Phase N skipped due to test failures (user choice)"
    - Continue to Phase N+1

    **(a) Abort**:
    - Save checkpoint with current state
    - Status: "aborted_after_test_failure"
    - Include debug report path in checkpoint
    - Exit with message: "Implementation paused. Resume with: /implement [plan] N"

    **Error Handling**:
    - If `/debug` invocation fails: Fall back to current error analysis (analyze-error.sh)
    - If debug report parsing fails: Display raw report path, still present choices
    - If SlashCommand times out: Retry once with extended timeout (600s)
    - All failures logged to .claude/logs/adaptive-planning.log

    **Logging**:
    - Log debug invocation: "Auto-debug triggered for Phase N (test: $TEST_CMD)"
    - Log user choice: "Phase N test failure: user chose [r/c/s/a]"
    - Log revise result: "Plan revised after test failure (trigger: auto_debug)"
    ```

- [ ] **Update error handling to use auto-debug**
  - Find where test failures are detected (after Step 3: Testing)
  - Replace "suggest /debug" with "invoke auto-debug workflow"
  - Ensure existing error categories still captured

- [ ] **Add debug invocation logging**
  - Use: log_debug_invocation() from adaptive-planning-logger.sh
  - Log: trigger="auto", phase=N, reason="test_failure", report_path

- [ ] **Update "Graceful degradation" fallback**
  - Keep analyze-error.sh as backup
  - Use if /debug command not available or fails
  - Document fallback in error message

#### Testing

```bash
# Test 1: Auto-debug on test failure
# Create plan with intentionally failing test
# Run /implement [plan] → Phase fails → /debug invokes automatically → Choices displayed

# Test 2: User chooses (r)evise
# Trigger test failure → Choose (r) → Verify /revise invoked → Plan updated → Implementation continues

# Test 3: User chooses (c)ontinue
# Trigger test failure → Choose (c) → Phase marked [INCOMPLETE] → Next phase starts

# Test 4: User chooses (s)kip
# Trigger test failure → Choose (s) → Phase marked [SKIPPED] → Next phase starts

# Test 5: User chooses (a)bort
# Trigger test failure → Choose (a) → Checkpoint saved → Implementation exits

# Test 6: /debug command fails
# Mock /debug failure → Verify fallback to analyze-error.sh → Choices still presented

# Test 7: Debug report parsing fails
# Mock unparseable debug output → Verify raw path displayed → Choices still work

# Test 8: Verify logging
# Trigger auto-debug → Check adaptive-planning.log contains invocation and choice
```

**Expected Outcome**: Test failures automatically invoke /debug, user presented with clear choices, no "should I run debug?" prompts

### Phase 3: Hybrid Complexity Evaluation

**Objective**: Add agent-based complexity evaluation as enhancement to threshold-based scoring
**Complexity**: Medium
**Files Modified**:
- .claude/commands/implement.md (new Step 1.5 before 1.55)
- .claude/lib/complexity-utils.sh (add agent invocation logic)

#### Current State Analysis

**Existing Complexity Scoring** (.claude/lib/complexity-utils.sh):
- Function: calculate_phase_complexity()
- Uses: task count, file references, keyword detection
- Returns: score 0-10

**Existing Thresholds** (CLAUDE.md lines 245-283):
- Expansion Threshold: 8.0
- Task Count Threshold: 10
- File Reference Threshold: 10

**Agent Integration Point**:
- Step 1.55 "Proactive Expansion Check" (lines 274-287) already evaluates complexity
- New Step 1.5 should run BEFORE 1.55 to enhance scoring

#### Tasks

- [ ] **Verify complexity_estimator agent exists**
  - Check: .claude/agents/complexity_estimator.md
  - If missing: Create basic agent definition
  - Test invocation with sample phase content

- [ ] **Add agent_based_complexity_score function**
  - Location: .claude/lib/complexity-utils.sh
  - Function signature: agent_based_complexity_score(phase_name, phase_content, plan_context)
  - Implementation:
    ```bash
    agent_based_complexity_score() {
      local phase_name="$1"
      local phase_content="$2"
      local plan_context="$3"

      # Build context JSON for agent
      local context=$(cat <<EOF
    {
      "parent_plan_context": $plan_context,
      "items_to_analyze": [
        {
          "item_id": "current_phase",
          "item_name": "$phase_name",
          "content": $(echo "$phase_content" | jq -Rs .)
        }
      ]
    }
    EOF
    )

      # Invoke complexity_estimator agent via Task tool
      # (This is pseudocode - actual invocation via Claude)
      local agent_response=$(invoke_agent "complexity_estimator" "$context")

      # Parse response for score
      local score=$(echo "$agent_response" | jq -r '.[0].complexity_level')
      local reasoning=$(echo "$agent_response" | jq -r '.[0].reasoning')
      local confidence=$(echo "$agent_response" | jq -r '.[0].confidence')

      # Return as JSON
      cat <<EOF
    {
      "score": $score,
      "reasoning": "$reasoning",
      "confidence": "$confidence"
    }
    EOF
    }
    ```

- [ ] **Add hybrid_complexity_evaluation function**
  - Location: .claude/lib/complexity-utils.sh
  - Combines threshold-based and agent-based scores
  - Implementation:
    ```bash
    hybrid_complexity_evaluation() {
      local phase_name="$1"
      local phase_content="$2"
      local plan_context="$3"

      # Calculate threshold-based score (existing function)
      local threshold_score=$(calculate_phase_complexity "$phase_name" "$phase_content")

      # Decide if agent evaluation needed
      local use_agent=false
      if awk -v s="$threshold_score" 'BEGIN {exit !(s >= 7.0)}'; then
        use_agent=true
      fi

      local task_count=$(echo "$phase_content" | grep -c "^- \[ \]")
      if [ "$task_count" -ge 8 ]; then
        use_agent=true
      fi

      # If borderline complexity, use agent for second opinion
      if [ "$use_agent" = "true" ]; then
        log_info "Invoking complexity_estimator agent (threshold_score: $threshold_score)"

        local agent_result=$(agent_based_complexity_score "$phase_name" "$phase_content" "$plan_context")
        local agent_score=$(echo "$agent_result" | jq -r '.score')
        local agent_confidence=$(echo "$agent_result" | jq -r '.confidence')

        # Compare scores
        local score_diff=$(echo "$threshold_score $agent_score" | awk '{print ($1>$2)?$1-$2:$2-$1}')

        if awk -v d="$score_diff" 'BEGIN {exit !(d >= 2.0)}'; then
          # Significant difference - log discrepancy
          log_complexity_discrepancy "$phase_name" "$threshold_score" "$agent_score"

          # Use agent score (more contextual) if high confidence
          if [ "$agent_confidence" = "high" ]; then
            echo "$agent_score|agent|high"
          else
            # Average the scores for medium/low confidence
            local avg_score=$(echo "$threshold_score $agent_score" | awk '{print ($1+$2)/2}')
            echo "$avg_score|hybrid|medium"
          fi
        else
          # Scores agree - use threshold score (faster)
          echo "$threshold_score|threshold|high"
        fi
      else
        # Low complexity, no agent needed
        echo "$threshold_score|threshold|high"
      fi
    }
    ```

- [ ] **Add Step 1.5 to implement.md** (before line 274)
  - Insert new section between Step 1.4 and Step 1.55
  - Content:
    ```markdown
    ### 1.5. Hybrid Complexity Evaluation

    Before displaying phase information, evaluate phase complexity using hybrid approach:

    **Step 1: Calculate Threshold-Based Score**
    - Use existing calculate_phase_complexity() function
    - Factors: task count, file references, keywords
    - Returns: score 0-10

    **Step 2: Determine if Agent Evaluation Needed**
    - Threshold score >= 7.0: Use agent
    - Task count >= 8: Use agent
    - Otherwise: Skip agent (threshold score sufficient)

    **Step 3: Invoke complexity_estimator Agent** (if needed)
    - Build context JSON with phase content and plan overview
    - Invoke agent via Task tool
    - Parse response: agent_score, reasoning, confidence

    **Step 4: Reconcile Scores**
    - If scores differ by >= 2 points: Log discrepancy
    - If agent confidence is high: Use agent score
    - If agent confidence is medium/low: Average scores
    - If no agent invoked: Use threshold score

    **Step 5: Use Score for Downstream Decisions**
    - Pass final score to Step 1.55 (Proactive Expansion Check)
    - Pass final score to Step 1.6 (Agent Selection)
    - Log evaluation method (threshold/agent/hybrid) for analysis

    **Benefits**:
    - Fast threshold checks for simple phases (90% of cases)
    - Intelligent agent analysis for borderline complexity
    - Learning opportunity from score discrepancies
    - No breaking changes to existing system

    **Error Handling**:
    - If agent invocation fails: Fall back to threshold score
    - If agent response invalid: Fall back to threshold score
    - All agent attempts logged for debugging
    ```

- [ ] **Update Step 1.55 to use hybrid score**
  - Read current Step 1.55 (lines 274-287)
  - Modify to receive score from Step 1.5
  - Document: "Uses hybrid complexity score from Step 1.5"

- [ ] **Update Step 1.6 (Agent Selection) to use hybrid score**
  - Located after Step 1.55 (around line 290)
  - Agent selection thresholds use hybrid score
  - Document score source

- [ ] **Add complexity discrepancy logging**
  - Function: log_complexity_discrepancy() in adaptive-planning-logger.sh
  - Log: phase, threshold_score, agent_score, difference, agent_reasoning
  - Purpose: Analyze threshold accuracy over time

#### Testing

```bash
# Test 1: Low complexity phase (threshold only)
# Phase with 3 tasks, score 4.5 → Agent NOT invoked → Threshold score used

# Test 2: Borderline complexity (agent invoked)
# Phase with 8 tasks, score 7.5 → Agent invoked → Scores compared

# Test 3: Agent agrees with threshold
# Threshold: 8.0, Agent: 8.5 (diff < 2) → Threshold score used (faster)

# Test 4: Agent disagrees significantly
# Threshold: 8.0, Agent: 5.0 (diff >= 2) → Agent score used (more contextual)

# Test 5: Agent invocation fails
# Mock agent failure → Threshold score used as fallback → Implementation continues

# Test 6: Verify logging
# Trigger agent evaluation → Check log contains: threshold_score, agent_score, method used

# Test 7: Verify Step 1.55 receives hybrid score
# Check expansion recommendation uses enhanced score

# Test 8: Verify Step 1.6 agent selection uses hybrid score
# High complexity phase → Verify correct agent selected based on hybrid score
```

**Expected Outcome**: Enhanced complexity evaluation with no regressions, fast for simple cases, intelligent for complex cases

### Phase 4: Documentation and Integration Testing

**Objective**: Update all documentation to reflect new features and verify comprehensive testing
**Complexity**: Medium
**Files Modified**:
- .claude/commands/implement.md (documentation sections)
- README.md updates (if needed)
- Test suite additions

#### Tasks

**Documentation Updates**:

- [ ] **Update implement.md "Adaptive Planning Features" section**
  - Location: Lines 17-56
  - Add subsection: "Smart Checkpoint Auto-Resume"
  - Add subsection: "Automatic Debug Integration"
  - Add subsection: "Hybrid Complexity Evaluation"
  - Include examples of new behaviors

- [ ] **Update implement.md "Process" section**
  - Location: Around line 80
  - Reflect new workflow steps (1.5, modified 3.3)
  - Clarify when user prompts occur vs automatic actions

- [ ] **Update "Checkpoint Detection and Resume" documentation**
  - Location: Lines 851-868
  - Document safe resume conditions
  - Document when interactive prompts still appear
  - Add examples of auto-resume vs manual resume

- [ ] **Update "Error Handling and Rollback" section**
  - Location: Around lines 644-686
  - Document new test failure workflow
  - Clarify user choices (r/c/s/a) and their implications
  - Add examples of each choice outcome

- [ ] **Add "Hybrid Complexity Evaluation" section**
  - Location: After "Adaptive Planning Features"
  - Document threshold + agent approach
  - Explain when agent is invoked
  - Provide examples of score reconciliation

**Test Suite Updates**:

- [ ] **Create test_smart_checkpoint_resume.sh**
  - Test all safe resume conditions
  - Test all unsafe conditions (interactive prompts)
  - Test plan modification detection
  - Test checkpoint age calculation
  - Test auto-resume logging

- [ ] **Create test_auto_debug_integration.sh**
  - Test automatic /debug invocation on test failure
  - Test all 4 user choices (r/c/s/a)
  - Test debug invocation failure fallback
  - Test report parsing
  - Test Unicode rendering

- [ ] **Create test_hybrid_complexity.sh**
  - Test threshold-only evaluation (simple phases)
  - Test agent invocation (complex phases)
  - Test score reconciliation
  - Test agent failure fallback
  - Test discrepancy logging

- [ ] **Update test_adaptive_planning.sh**
  - Add tests for new Step 1.5
  - Verify hybrid scoring integration
  - Test new logging events

- [ ] **Run full test suite**
  - Execute: cd .claude/tests && ./run_all_tests.sh
  - Verify: All existing tests still pass
  - Verify: New tests pass
  - Check: No regressions in command workflows

**Integration Testing**:

- [ ] **End-to-end test: Simple plan with auto-resume**
  - Create simple plan, implement Phase 1, interrupt
  - Resume → Verify auto-resume occurs silently
  - Check log: "Auto-resuming from Phase 2"

- [ ] **End-to-end test: Plan with test failure**
  - Create plan with failing test in Phase 2
  - Implement → Phase 2 fails → /debug auto-invokes
  - Choose (r)evise → Plan updated → Implementation continues
  - Verify final implementation successful

- [ ] **End-to-end test: Complex plan with hybrid complexity**
  - Create plan with 1 simple phase + 1 complex phase
  - Implement → Verify simple uses threshold only
  - Complex phase → Verify agent invoked
  - Check log: Both evaluation methods used

- [ ] **Regression test: Existing /implement workflows**
  - Test with Level 0 plan (single file)
  - Test with Level 1 plan (phase expansion)
  - Test with Level 2 plan (stage expansion)
  - Verify: All work as before, new features optional

**Example Documentation Updates**:

- [ ] **Add workflow examples to implement.md**
  - Example 1: Auto-resume workflow
    ```
    User: /implement plan_025.md
    → Checkpoint found (tests passing, 2 days old, plan unchanged)
    → Auto-resuming from Phase 3 (all safety conditions met)
    → Phase 3: Core Implementation...
    ```

  - Example 2: Auto-debug workflow
    ```
    → Phase 2: Database Integration
    → Tests: ✗ Failed
    → Invoking /debug automatically...
    → Debug Report: Missing database migration

    Options:
    (r) Revise plan with debug findings
    (c) Continue anyway
    (s) Skip phase
    (a) Abort

    Choice: r
    → Plan revised: Added Phase 1.5 - Database Migration
    → Continuing implementation...
    ```

- [ ] **Update CHANGELOG or implementation notes**
  - Document breaking changes (none expected)
  - Document new features and usage
  - Provide migration guidance (none needed - backward compatible)

#### Testing

```bash
# Run comprehensive test suite
cd /home/benjamin/.config/.claude/tests

# Run all new tests
./test_smart_checkpoint_resume.sh
./test_auto_debug_integration.sh
./test_hybrid_complexity.sh

# Run existing tests (regression check)
./test_adaptive_planning.sh
./test_command_integration.sh
./test_revise_automode.sh

# Run full suite
./run_all_tests.sh

# Verify no failures
echo $?  # Should be 0
```

**Expected Outcome**: Complete, accurate documentation; all tests passing; verified workflows; no regressions

## Testing Strategy

### Unit Testing

**Component Tests**:
- [ ] checkpoint-utils.sh: check_safe_resume_conditions()
- [ ] checkpoint-utils.sh: get_skip_reason()
- [ ] complexity-utils.sh: agent_based_complexity_score()
- [ ] complexity-utils.sh: hybrid_complexity_evaluation()
- [ ] adaptive-planning-logger.sh: log_complexity_discrepancy()

### Integration Testing

**Workflow Tests**:
- [ ] Auto-resume with safe checkpoint (end-to-end)
- [ ] Interactive resume with unsafe checkpoint
- [ ] Auto-debug with test failure → revise choice
- [ ] Auto-debug with test failure → abort choice
- [ ] Hybrid complexity for simple phase (threshold only)
- [ ] Hybrid complexity for complex phase (agent invoked)

### Regression Testing

**Backward Compatibility**:
- [ ] Level 0 plans work as before
- [ ] Level 1 plans work as before
- [ ] Level 2 plans work as before
- [ ] Existing checkpoints still resume
- [ ] Adaptive planning triggers still work
- [ ] All existing tests pass

### Coverage Requirements

- All new code paths tested
- All user interaction branches tested
- Error handling tested (agent failures, command failures)
- Edge cases: empty checkpoints, missing fields, corrupt data
- Logging verified for all new features

## Dependencies

### Required Components

**Existing** (already present):
- checkpoint-utils.sh (will be enhanced)
- complexity-utils.sh (will be enhanced)
- adaptive-planning-logger.sh (will be enhanced)
- analyze-error.sh (used as fallback)
- /debug command (must exist and be functional)
- /revise --auto-mode (must exist and be functional)

**New** (to be created if missing):
- complexity_estimator agent (.claude/agents/complexity_estimator.md)

**Configuration**:
- CLAUDE.md (no changes required - thresholds preserved)

### External Dependencies

None - all components are internal to .claude/ system

## Risk Assessment

### High Risk

❌ **NONE** - This plan avoids high-risk changes identified in original Plan 037:
- Does NOT remove thresholds (they stay as fallback)
- Does NOT remove existing expansion logic (Step 1.55 preserved)
- Does NOT touch orchestrate.md (deferred due to extensive changes)

### Medium Risk

⚠️ **Auto-debug workflow changes user experience**
- **Mitigation**: /debug invocation is optional - falls back on failure
- **Mitigation**: User still controls all decisions (r/c/s/a choices)
- **Mitigation**: Comprehensive testing before deployment

⚠️ **Agent invocation adds latency**
- **Mitigation**: Only for borderline complexity (10-20% of phases)
- **Mitigation**: Threshold-based fallback always available
- **Mitigation**: Acceptable overhead for improved accuracy

### Low Risk

✅ **Checkpoint schema changes**
- **Mitigation**: Backward compatible - new field optional
- **Mitigation**: Old checkpoints still work (interactive prompt shows)
- **Mitigation**: Graceful degradation if field missing

✅ **Additional logging**
- **Mitigation**: Log rotation already configured (10MB, 5 files)
- **Mitigation**: Logging failures don't affect workflow
- **Mitigation**: Performance impact negligible

## Migration Notes

### Breaking Changes

✅ **NONE** - This plan is fully backward compatible:
- Existing checkpoints work (fall back to interactive prompt)
- Thresholds preserved (no CLAUDE.md changes)
- Existing plans work unchanged
- All workflows continue as before

### User Impact

**Positive**:
- Fewer unnecessary interruptions (auto-resume)
- Faster debug workflow (automatic invocation)
- Smarter complexity evaluation (agent enhancement)
- Clearer choices after failures (r/c/s/a options)

**Neutral**:
- Slightly different resume behavior (silent vs prompt)
- New /debug report display (Unicode boxes)
- Hybrid complexity logging (more verbose logs)

**Minimal**:
- No data migration needed
- No configuration changes required
- No user retraining needed

### Rollback Plan

If issues arise:
1. **Revert implement.md changes**: Restore from git
2. **Revert utility changes**: Restore checkpoint-utils.sh, complexity-utils.sh
3. **Old checkpoints continue to work**: No data corruption risk
4. **Document specific issues**: For future refinement

**Rollback is safe and straightforward** - no permanent state changes

## Notes

### Design Rationale

**Why This Approach**:
1. **Pragmatic**: Works WITH current system, not against it
2. **Incremental**: Each phase adds value independently
3. **Safe**: Backward compatible, no breaking changes
4. **Measurable**: Clear metrics for success (auto-resume %, debug time saved)
5. **Focused**: /implement only - proven value before tackling /orchestrate

### Lessons from Plan 037 Analysis

**What We Learned**:
1. Codebase changes rapidly - line numbers become invalid
2. Removing working features is risky - enhance instead
3. Thresholds aren't bad - they're fast and predictable
4. Agent evaluation is valuable - but not a replacement
5. /orchestrate needs separate attention due to extensive refactoring

**Applied Principles**:
- Verify before every change
- Enhance rather than replace
- Keep fallbacks for all enhancements
- Document current reality, not ideal state
- Test extensively, deploy incrementally

### Future Enhancements

**After This Plan Succeeds**:
1. **Careful Mode Configuration**: Add to CLAUDE.md and implement usage
2. **Post-Planning Review (Step 1.6)**: Reference original Phase 2 expansion
3. **Orchestrate Auto-Resume**: Create separate plan after understand current state
4. **Threshold Tuning**: Use logged discrepancies to refine threshold values
5. **Agent-First Mode**: Option to always use agent evaluation (for critical projects)

### Alignment with Project Philosophy

**Clean-Break Refactors**:
- This plan respects existing system (not a clean break)
- Additive enhancements, not destructive changes
- Maintains coherence with current implementation

**Present-Focused Documentation**:
- Documents new behavior as if it always existed
- No "old way" vs "new way" comparisons
- Focuses on what the system does NOW

**System Coherence**:
- All commands work together harmoniously
- /debug, /revise, /implement deeply integrated
- Consistent patterns across workflow

**Maintainability**:
- Clear, testable code
- Comprehensive logging
- Documented decision points
- Easy to understand and modify

## Success Metrics

### Quantitative Metrics

**Auto-Resume Effectiveness**:
- Target: 90% of resumes are automatic (no prompt)
- Measure: Count auto-resume vs interactive prompt in logs
- Success: >= 85% auto-resume rate in production use

**Debug Time Savings**:
- Target: 50% reduction in time from test failure to fix applied
- Measure: Time from failure to next commit
- Baseline: Current average ~15 minutes
- Target: ~7-8 minutes with auto-debug

**Agent Invocation Frequency**:
- Target: 10-20% of phases invoke agent (borderline cases only)
- Measure: Count agent invocations vs total phases
- Success: < 25% agent invocation (efficiency maintained)

### Qualitative Metrics

**User Experience**:
- Fewer "Why am I seeing this prompt?" moments
- Clearer understanding of choices during failures
- Confidence in system's intelligence

**Code Quality**:
- Zero regressions in existing tests
- High coverage for new features (>90%)
- Clear, maintainable implementation

**System Reliability**:
- All enhancements have tested fallbacks
- No single point of failure
- Graceful degradation everywhere

## Implementation Timeline

**Estimated Effort**: 12-16 hours total
- Phase 1: 3-4 hours (smart auto-resume)
- Phase 2: 4-5 hours (auto-debug integration)
- Phase 3: 3-4 hours (hybrid complexity)
- Phase 4: 2-3 hours (documentation + testing)

**Recommended Schedule**:
- Week 1: Phase 1 + Phase 2 (foundation + high-value feature)
- Week 2: Phase 3 + Phase 4 (enhancement + documentation)

**Validation Gates**:
- After Phase 1: Test suite passes, auto-resume works
- After Phase 2: Test suite passes, auto-debug works
- After Phase 3: Test suite passes, hybrid scoring works
- After Phase 4: All docs updated, all tests pass, ready for production

---

**This plan represents a pragmatic, focused approach to reducing implementation interruptions while respecting the current codebase reality and avoiding the pitfalls discovered in the Plan 037 adaptation analysis.**
