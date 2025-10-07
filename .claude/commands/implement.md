---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [plan-file] [starting-phase] [--report-scope-drift "<description>"] [--force-replan]
description: Execute implementation plan with automated testing, adaptive replanning, and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list, update, revise, debug, document, expand
---

# Execute Implementation Plan

I'll help you systematically implement the plan file with automated testing and commits at each phase.

## Plan Information
- **Plan file**: $1 (or I'll find the most recent incomplete plan)
- **Starting phase**: $2 (default: resume from last incomplete phase or 1)

## Adaptive Planning Features

This command includes intelligent plan revision capabilities that detect when replanning is needed during implementation:

**Automatic Triggers:**
1. **Complexity Detection**: Phases with complexity score >8 or >10 tasks trigger phase expansion
2. **Test Failure Patterns**: 2+ consecutive test failures in same phase suggests missing prerequisites
3. **Scope Drift**: Manual flag `--report-scope-drift "description"` for discovered out-of-scope work

**Behavior:**
- Automatically invokes `/revise --auto-mode` when triggers detected
- Updates plan structure (expands phases, adds phases, or updates tasks)
- Continues implementation with revised plan
- Maximum 2 replans per phase prevents infinite loops

**Shared Utilities Integration:**
- **Checkpoint Management**: Uses `.claude/lib/checkpoint-utils.sh` for workflow state persistence
- **Complexity Analysis**: Uses `.claude/lib/complexity-utils.sh` for phase complexity scoring
- **Adaptive Logging**: Uses `.claude/lib/adaptive-planning-logger.sh` for trigger evaluation logging
- **Error Handling**: Uses `.claude/lib/error-utils.sh` for error classification and recovery

These shared utilities provide consistent, tested implementations across all commands.

**Safety:**
- Loop prevention with replan counters tracked in checkpoints
- Replan history logged for audit trail
- User escalation when limits exceeded
- Manual override via `--force-replan` flag

**Example Usage:**
```bash
# Normal implementation (automatic detection enabled)
/implement specs/plans/025_plan.md

# Manual scope drift reporting
/implement specs/plans/025_plan.md 3 --report-scope-drift "Database migration needed before schema changes"

# Force replan despite limit (requires manual approval)
/implement specs/plans/025_plan.md 4 --force-replan
```

## Auto-Resume Feature
If no plan file is provided, I will:
1. Search for the most recently modified implementation plan
2. Check if it has incomplete phases or tasks
3. Resume from the first incomplete phase
4. If all recent plans are complete, show a list to choose from

## Standards Discovery and Application

Before implementing, I'll discover and apply project standards from CLAUDE.md:

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from working directory and target directories
2. **Check Subdirectory Standards**: Look for directory-specific CLAUDE.md files
3. **Parse Relevant Sections**: Extract Code Standards, Testing Protocols
4. **Handle Missing Standards**: Fall back to language-specific defaults

### Standards Sections Used
- **Code Standards**: Indentation, line length, naming conventions, error handling
- **Testing Protocols**: Test commands, patterns, coverage requirements
- **Documentation Policy**: Documentation requirements for new code
- **Standards Discovery**: Discovery method, inheritance rules, fallback behavior

### Application During Implementation
Standards influence implementation as follows:

#### Code Generation
- **Indentation**: Generated code matches CLAUDE.md indentation spec (e.g., 2 spaces)
- **Line Length**: Keep lines within specified limit (e.g., ~100 characters)
- **Naming**: Follow naming conventions (e.g., snake_case vs camelCase)
- **Error Handling**: Use specified error handling patterns (e.g., pcall for Lua)
- **Module Organization**: Follow project structure patterns

#### Testing
- **Test Commands**: Use test commands from Testing Protocols (e.g., `:TestSuite`)
- **Test Patterns**: Create test files matching patterns (e.g., `*_spec.lua`)
- **Coverage**: Aim for coverage requirements from standards

#### Documentation
- **Inline Comments**: Document complex logic
- **Module Headers**: Add purpose and API documentation
- **README Updates**: Follow Documentation Policy requirements

### Compliance Verification
Before marking each phase complete and committing:
- [ ] Code style matches CLAUDE.md specifications (indentation, line length)
- [ ] Naming follows project conventions
- [ ] Error handling matches project patterns
- [ ] Tests follow testing standards and pass
- [ ] Documentation meets policy requirements (if new modules created)

### Fallback Behavior
When CLAUDE.md not found or incomplete:
1. **Use Language Defaults**: Apply sensible language-specific conventions
2. **Suggest Creation**: Recommend running `/setup` to create CLAUDE.md
3. **Graceful Degradation**: Continue with reduced standards enforcement
4. **Document Limitations**: Note in commit message which standards were uncertain

### Example: Standards Application

```lua
-- From CLAUDE.md Code Standards:
-- Indentation: 2 spaces, expandtab
-- Naming: snake_case for variables/functions
-- Error Handling: Use pcall for operations that might fail

local function process_user_data(user_id)  -- snake_case naming
  local status, result = pcall(function()  -- pcall error handling
    local data = database.query({          -- 2-space indentation
      id = user_id,
      fields = {"name", "email"}
    })
    return data
  end)

  if not status then                       -- error handling pattern
    print("Error: " .. result)
    return nil
  end

  return result
end
```

## Process

### Progressive Plan Support

This command supports all three progressive structure levels:

**Step 0: Detect Plan Structure Level**
```bash
# Use adaptive plan parser to detect structure
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
# Returns: 0 (single-file), 1 (phase-expanded), or 2 (stage-expanded)
```

**Level-Aware Processing**:
- **Level 0**: Single-file processing (all phases inline)
- **Level 1**: Process main plan and expanded phase files
- **Level 2**: Navigate hierarchy (main plan → phase directories → stage files)

**Unified Interface**:
All level-specific differences are abstracted by progressive utilities:
- `is_plan_expanded`: Check if plan has directory structure
- `is_phase_expanded`: Check if specific phase is in separate file
- `is_stage_expanded`: Check if specific stage is in separate file
- `list_expanded_phases`: Get numbers of expanded phases
- `list_expanded_stages`: Get numbers of expanded stages

### Implementation Flow

Let me first locate the implementation plan:

1. **Detect and parse the plan** to identify:
   - Plan structure level (0, 1, or 2) using parse-adaptive-plan.sh
   - Expanded phases and stages (via progressive parsing utilities)
   - Referenced research reports (if any)
   - Standards file path (if captured in plan metadata)
2. **Discover and load standards**:
   - Find CLAUDE.md files (working directory and subdirectories)
   - Extract Code Standards, Testing Protocols, Documentation Policy
   - Note standards for application during implementation
3. **Check for research reports**:
   - Extract report paths from plan metadata
   - Note reports for summary generation
4. **For each phase**:
   - Display the phase name and tasks
   - Implement changes following discovered standards
   - Run tests using standards-defined test commands
   - Verify compliance with standards before completing
   - Update the plan file with completion markers
   - Create a git commit with a structured message
   - Move to the next phase
5. **After all phases complete**:
   - Generate implementation summary
   - Update referenced reports if needed
   - Link plan and reports in summary

## Parallel Execution with Dependencies

Before executing phases, I will analyze phase dependencies to enable parallel execution:

### Dependency Analysis

**Step 1: Parse Dependencies**
```bash
# Use dependency parser to generate execution waves
WAVES=$(.claude/lib/parse-phase-dependencies.sh "$PLAN_FILE")
```

**Step 2: Group Phases into Waves**
- Parse wave output: `WAVE_1:1`, `WAVE_2:2 3`, `WAVE_3:4`
- Each wave contains phases that can execute in parallel
- Waves execute sequentially (wait for wave completion before next)

**Step 3: Execute Waves**

For each wave:
1. **Single Phase**: Execute normally (sequential)
2. **Multiple Phases**: Execute in parallel
   - Invoke multiple agents simultaneously using multiple Task tool calls in one message
   - Each phase gets its own agent based on complexity analysis
   - Wait for all phases in wave to complete
   - Collect results from all parallel executions

**Step 4: Error Handling**
- If any phase in a wave fails, stop execution
- Preserve checkpoint with partial completion
- Report which phases succeeded and which failed
- User can resume from failed wave

### Parallel Execution Safety

- **Max Parallelism**: Limit to 3 concurrent phases per wave
- **Fail-Fast**: Stop wave execution if any phase fails
- **Checkpoint Preservation**: Save state after each wave
- **Result Collection**: Aggregate test results and file changes from parallel phases

### Dependency Format

Phases declare dependencies in their header:
```markdown
### Phase N: Phase Name
dependencies: [1, 2]  # Depends on phases 1 and 2
```

- Empty array `[]` or omitted = no dependencies (can run in wave 1)
- Multiple dependencies = wait for all to complete
- Circular dependencies are detected and rejected

## Phase Execution Protocol

### Execution Flow

**Sequential Execution** (no dependencies or dependencies: [] omitted):
- Execute phases one by one in order (Phase 1, 2, 3, ...)
- Traditional workflow, fully backward compatible

**Parallel Execution** (with dependency declarations):
- Parse dependencies into execution waves
- Execute each wave sequentially
- Within each wave, execute phases in parallel if wave contains >1 phase
- Wait for wave completion before next wave

For each wave, I will:

### 0. Wave Initialization
- Identify phases in current wave from dependency analysis
- Log: "Executing Wave N with M phase(s): [phase numbers]"

For each phase in the wave, I will prepare:

### 1. Display Phase Information
Show the phase number, name, and all tasks that need to be completed.

### 1.5. Phase Complexity Analysis and Agent Selection

Before implementing each phase, I will analyze its complexity to determine whether to delegate to a specialized agent or execute directly.

**Complexity Analysis Process:**

1. **Extract phase information** from the current phase:
   - Phase name (e.g., "Phase 2: Refactor Architecture")
   - All tasks in markdown checkbox format

2. **Run complexity analyzer**:
   ```bash
   .claude/lib/analyze-phase-complexity.sh "<phase-name>" "<task-list>"
   ```

3. **Parse analyzer output** to get:
   - `COMPLEXITY_SCORE`: 0-10 scale
   - `SELECTED_AGENT`: Agent name or "direct"
   - `THINKING_MODE`: Thinking directive (if applicable)
   - `SPECIAL_CASE`: Special case category (if detected)

**Agent Selection Logic:**

The analyzer automatically selects the optimal approach:

- **Direct execution** (score 0-2): Simple phases, I implement directly
- **code-writer** (score 3-5): Medium complexity, basic delegation
- **code-writer + think** (score 6-7): Medium-high complexity
- **code-writer + think hard** (score 8-9): High complexity
- **code-writer + think harder** (score 10+): Critical complexity

**Special Case Overrides:**
- **doc-writer**: Documentation/README phases (detected by keywords)
- **test-specialist**: Testing phases (detected by keywords)
- **debug-specialist**: Debug/investigation phases (detected by keywords)

**Delegation Execution:**

If `SELECTED_AGENT != "direct"`, I will:

1. **Announce delegation** with complexity context:
   ```
   Delegating to {agent-name} agent (complexity score: {score}/10)
   Phase: {phase-name}
   Thinking mode: {mode}
   ```

2. **Invoke agent** using Task tool:
   ```yaml
   Task {
     subagent_type: "general-purpose"
     description: "Implement {short-phase-description} using {selected-agent} protocol"
     prompt: "Read and follow the behavioral guidelines from:
             /home/benjamin/.config/.claude/agents/{selected-agent}.md

             You are acting as a {Selected Agent Name} with the tools and constraints
             defined in that file.

             {thinking-mode-directive}

             Implementation Phase: {phase-name}

             Tasks to complete:
             {task-list}

             Standards Compliance:
             - Apply project standards from CLAUDE.md
             - Follow language-specific style guides
             - Maintain documentation requirements

             Testing Requirements:
             - Run tests after implementation (if tests exist)
             - Verify all tasks completed
             - Report any failures

             Expected Output:
             - All phase tasks completed
             - Code following standards
             - Tests passing (if applicable)
             - Summary of changes made
     "
   }
   ```

3. **Monitor progress and process results**:
   - **Progress Monitoring**: Agents emit `PROGRESS: <message>` markers during execution
     - Example: `PROGRESS: Implementing login function in auth.lua...`
     - Display progress markers to user as they arrive (if tool supports streaming)
     - Progress provides real-time visibility into long-running operations
   - **Result Processing**:
     - Verify all tasks were completed
     - Note any test failures or issues
     - Use agent's output for subsequent testing and commit steps
   - **Progress Handling**:
     - Filter PROGRESS: lines from agent output
     - Display them separately or inline with status indicators
     - Do not include progress markers in final output summary

**Direct Execution:**

If `SELECTED_AGENT == "direct"`, I will:
- Skip agent delegation
- Implement the phase tasks directly following standards
- Proceed immediately to implementation step

### 1.4. Check Expansion Status

Before implementing the phase, check if it's already expanded and display current structure:

```bash
# Detect plan structure level
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Check if current phase is expanded
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
```

**Display Structure Information:**
- **Level 0**: "Plan Structure: Level 0 (all phases inline)"
- **Level 1**: "Plan Structure: Level 1 (Phase X expanded, other phases inline)"
- **Level 2**: "Plan Structure: Level 2 (Phase X with stage expansion)"

This is informational only and helps understand the current plan organization.

### 1.55. Proactive Expansion Check

Before implementation begins, evaluate if the phase should be expanded using agent-based judgment:

**Evaluation Approach:**

The primary agent (executing `/implement`) has the current phase in context. Rather than using shell script heuristics, I'll make an informed judgment about whether this phase would benefit from expansion to a separate file.

**Evaluation Criteria:**

I'll consider:
- **Task complexity**: Not just count, but actual complexity of each task
- **Scope breadth**: How many files, modules, or subsystems are touched
- **Interrelationships**: Dependencies and connections between tasks
- **Potential for parallel work**: Could tasks be better organized for parallel execution
- **Clarity vs detail tradeoff**: Would expansion help or create unnecessary fragmentation

**Evaluation Process:**

```
Read /home/benjamin/.config/.claude/prompts/evaluate-phase-expansion.md

Current Phase [N]: [Phase Name]

Tasks:
[task list from phase]

Follow the evaluation criteria and provide recommendation.
```

**If Expansion Recommended:**

Display formatted recommendation:
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

**If No Expansion Needed:**

Continue silently to implementation. No message needed for phases that are appropriately scoped.

**Already Expanded:**

If Step 1.4 detected the phase is already expanded, note that in the evaluation and skip recommendation.

**Non-Blocking:**

This check is purely informative. The user can choose to:
- Expand now using the recommended command
- Continue with implementation as-is
- Expand later if phase proves complex during implementation

**Relationship to Step 3.4 (Reactive Expansion):**

- **Step 1.55 (Proactive)**: Evaluates BEFORE implementation based on plan content
- **Step 3.4 (Reactive)**: Evaluates AFTER implementation based on actual complexity encountered
- **Different contexts**: Proactive = plan preview, Reactive = implementation experience
- **Different actions**: Proactive = recommendation only, Reactive = auto-revision via `/revise --auto-mode`
- **Complementary**: Both serve different purposes in the workflow

### 1.6. Parallel Wave Execution

After all phases in the wave are prepared (Steps 1-1.5 complete for each), execute the wave:

**Single Phase Wave** (most common):
- Execute the phase normally (agent delegation or direct)
- Wait for completion
- Proceed to testing and commit

**Multi-Phase Wave** (parallel execution):
1. **Invoke all phases in parallel**:
   - Create multiple Task tool calls in a single message
   - Each phase gets its own agent invocation
   - Example for Wave 2 with phases 2 and 3:
   ```
   Executing Wave 2 with 2 phases in parallel: Phases 2 and 3

   [Multiple Task tool calls in this single message:]

   Task { (Phase 2)
     subagent_type: "general-purpose"
     description: "Implement Phase 2 using code-writer protocol"
     prompt: "Read and follow the behavioral guidelines from:
             /home/benjamin/.config/.claude/agents/code-writer.md

             You are acting as a Code Writer with the tools and constraints
             defined in that file.

             [Phase 2 tasks and context]"
   }

   Task { (Phase 3)
     subagent_type: "general-purpose"
     description: "Implement Phase 3 using code-writer protocol"
     prompt: "Read and follow the behavioral guidelines from:
             /home/benjamin/.config/.claude/agents/code-writer.md

             You are acting as a Code Writer with the tools and constraints
             defined in that file.

             [Phase 3 tasks and context]"
   }
   ```

2. **Wait for wave completion**:
   - All phases in wave must complete before proceeding
   - Collect results from each phase execution
   - Aggregate any progress markers from parallel agents

3. **Check for failures**:
   - If any phase failed, stop execution
   - Report which phases succeeded and which failed
   - Save checkpoint with partial completion
   - User can fix issues and resume

4. **Proceed to wave testing and commit**:
   - Run tests for all phases in wave
   - Commit all changes from wave together
   - Move to next wave

**Parallelism Limits**:
- Maximum 3 concurrent phases per wave
- If wave has >3 phases, split into sub-waves of 3
- Ensures system stability and manageable error handling

### 2. Implementation
Create or modify the necessary files according to the plan specifications.

**If Agent Delegated**: Use agent's output
**If Direct Execution**: Implement manually following standards

### 3. Testing
Run tests by:
- Looking for test commands in the phase tasks
- Checking for common test patterns (npm test, pytest, make test)
- Running language-specific test commands based on project type

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
The enhanced analysis includes:
- **Error Type**: Categorized (syntax, test_failure, file_not_found, import_error, null_error, timeout, permission)
- **Location**: File and line number where error occurred
- **Context**: 3 lines before and after error location
- **Suggestions**: 2-3 specific, actionable fix suggestions
- **Debug Commands**: Commands to investigate further

**Step 4: Graceful Degradation**
If tests fail:
- Document what succeeded vs. what failed
- Preserve partial progress
- Suggest next steps:
  - `/debug "<error description>"` for investigation
  - Manual fixes based on suggestions
  - Review recent changes with git diff

**Example Enhanced Error Output:**
```
===============================================
Enhanced Error Analysis
===============================================

Error Type: test_failure
Location: tests/auth_spec.lua:42

Context (around line 42):
   39  setup(function()
   40    session = mock_session_factory()
   41  end)
   42  it("should login with valid credentials", function()
   43    local result = auth.login(session, "user", "pass")
   44    assert.is_not_nil(result)
   45  end)

Suggestions:
1. Check test setup - verify mocks and fixtures are initialized correctly
2. Review test data - ensure test inputs match expected types and values
3. Check for race conditions - add delays or synchronization if timing-sensitive
4. Run test in isolation: :TestNearest to isolate the failure

Debug Commands:
- Investigate further: /debug "auth login test failing with nil result"
- View file: nvim tests/auth_spec.lua
- Run tests: :TestNearest or :TestFile
===============================================
```

### 3.4. Adaptive Planning Detection

After each phase implementation (successful or with errors), check if plan revision is needed.

**Step 1: Load Checkpoint and Check Replan Limits**

```bash
# Load current checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement "$PROJECT_NAME")
REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r '.replanning_count // 0')
PHASE_REPLAN_COUNT=$(echo "$CHECKPOINT" | jq -r ".replan_phase_counts.phase_${CURRENT_PHASE} // 0")
```

**Replan Limit Check:**
- If `PHASE_REPLAN_COUNT >= 2`: Skip detection, log warning, escalate to user
- Otherwise: Proceed with trigger detection

**Step 2: Detect Triggers**

Three trigger types are checked in order:

**Trigger 1: Complexity Threshold Exceeded**

Detection after successful phase completion:
```bash
# Calculate phase complexity score
COMPLEXITY_RESULT=$(.claude/lib/analyze-phase-complexity.sh "$PHASE_NAME" "$TASK_LIST")
COMPLEXITY_SCORE=$(echo "$COMPLEXITY_RESULT" | jq -r '.complexity_score')

# Check threshold
if [ "$COMPLEXITY_SCORE" -gt 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  TRIGGER_TYPE="expand_phase"
  TRIGGER_REASON="Phase complexity score $COMPLEXITY_SCORE exceeds threshold 8 ($TASK_COUNT tasks)"
fi
```

**Trigger 2: Test Failure Pattern**

Detection after test failures (2+ consecutive failures in same phase):
```bash
# Track failure count in checkpoint
if [ "$TEST_RESULT" = "failed" ]; then
  PHASE_FAILURE_COUNT=$((PHASE_FAILURE_COUNT + 1))

  if [ "$PHASE_FAILURE_COUNT" -ge 2 ]; then
    TRIGGER_TYPE="add_phase"
    TRIGGER_REASON="Two consecutive test failures in phase $CURRENT_PHASE"
    # Analyze failure logs for missing dependencies
    FAILURE_ANALYSIS=$(.claude/lib/analyze-error.sh "$ERROR_OUTPUT")
  fi
fi
```

**Trigger 3: Scope Drift Detection**

Detection via manual flag or "out of scope" annotations:
```bash
# Manual trigger via flag
if [ "$REPORT_SCOPE_DRIFT" = "true" ]; then
  TRIGGER_TYPE="update_tasks"
  TRIGGER_REASON="$SCOPE_DRIFT_DESCRIPTION"
fi
```

**Step 3: Invoke /revise --auto-mode**

If trigger detected and replan limit not exceeded:

```bash
# Build revision context JSON
REVISION_CONTEXT=$(jq -n \
  --arg type "$TRIGGER_TYPE" \
  --argjson phase "$CURRENT_PHASE" \
  --arg reason "$TRIGGER_REASON" \
  --arg action "$SUGGESTED_ACTION" \
  --argjson metrics "$TRIGGER_METRICS" \
  '{
    revision_type: $type,
    current_phase: $phase,
    reason: $reason,
    suggested_action: $action,
    complexity_metrics: $metrics,
    test_failure_log: $failure_log,
    insert_position: $insert_pos,
    new_phase_name: $new_name
  }')

# Invoke /revise with auto-mode
REVISE_RESULT=$(invoke_slash_command "/revise $PLAN_PATH --auto-mode --context '$REVISION_CONTEXT'")
```

**Step 4: Parse Revision Response**

```bash
# Check revision status
REVISION_STATUS=$(echo "$REVISE_RESULT" | jq -r '.status')

if [ "$REVISION_STATUS" = "success" ]; then
  # Update checkpoint with replan metadata
  UPDATED_PLAN=$(echo "$REVISE_RESULT" | jq -r '.plan_file')
  ACTION_TAKEN=$(echo "$REVISE_RESULT" | jq -r '.action_taken')

  # Increment replan counters
  REPLAN_COUNT=$((REPLAN_COUNT + 1))
  PHASE_REPLAN_COUNT=$((PHASE_REPLAN_COUNT + 1))

  # Add to replan history
  REPLAN_EVENT=$(jq -n \
    --argjson phase "$CURRENT_PHASE" \
    --arg type "$TRIGGER_TYPE" \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg reason "$TRIGGER_REASON" \
    '{
      phase: $phase,
      type: $type,
      timestamp: $timestamp,
      reason: $reason,
      action: $action_taken
    }')

  # Update checkpoint
  .claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" \
    --replan-count "$REPLAN_COUNT" \
    --phase-replan-count "phase_${CURRENT_PHASE}=$PHASE_REPLAN_COUNT" \
    --last-replan-reason "$TRIGGER_REASON" \
    --add-replan-history "$REPLAN_EVENT"

  # Log and continue with updated plan
  echo "Plan revised: $ACTION_TAKEN"
  echo "Updated plan: $UPDATED_PLAN"

  # Reload plan and continue implementation
  PLAN_PATH="$UPDATED_PLAN"
else
  # Revision failed, log error and ask user
  echo "Warning: Adaptive planning revision failed"
  echo "Error: $(echo "$REVISE_RESULT" | jq -r '.error_message')"
  echo "Continuing with original plan"
fi
```

**Step 5: Loop Prevention Safeguards**

Maximum 2 replans per phase enforced:
```bash
if [ "$PHASE_REPLAN_COUNT" -ge 2 ]; then
  echo "=========================================="
  echo "Warning: Replanning Limit Reached"
  echo "=========================================="
  echo "Phase: $CURRENT_PHASE"
  echo "Replans: $PHASE_REPLAN_COUNT (max 2)"
  echo ""
  echo "Replan History for Phase $CURRENT_PHASE:"
  echo "$CHECKPOINT" | jq -r ".replan_history[] | select(.phase == $CURRENT_PHASE) | \
    \"  - [\(.timestamp)] \(.type): \(.reason)\""
  echo ""
  echo "Recommendation: Manual review required"
  echo "Consider using /revise interactively to adjust plan structure"
  echo "=========================================="

  # Skip further replanning for this phase
  SKIP_REPLAN=true
fi
```

**Trigger Details:**

**Complexity Trigger Context:**
```json
{
  "revision_type": "expand_phase",
  "current_phase": 3,
  "reason": "Phase complexity score 9.2 exceeds threshold 8 (12 tasks)",
  "suggested_action": "Expand phase 3 into separate file",
  "complexity_metrics": {
    "tasks": 12,
    "score": 9.2,
    "estimated_duration": "4-5 sessions"
  }
}
```

**Test Failure Trigger Context:**
```json
{
  "revision_type": "add_phase",
  "current_phase": 2,
  "reason": "Two consecutive test failures in authentication module",
  "suggested_action": "Add prerequisite phase for dependency setup",
  "test_failure_log": "Error: Module not found: crypto-utils...",
  "insert_position": "before",
  "new_phase_name": "Setup Dependencies"
}
```

**Scope Drift Trigger Context:**
```json
{
  "revision_type": "update_tasks",
  "current_phase": 3,
  "reason": "Migration script required before data model changes",
  "suggested_action": "Add migration task before schema changes",
  "task_operations": [
    {"action": "insert", "position": 2, "task": "Create database migration script"}
  ]
}
```

### 3.5. Update Debug Resolution (if tests pass for previously-failed phase)
**Check if this phase was previously debugged:**

**Step 1: Check for Debugging Notes**
- Read current phase section in plan
- Look for "#### Debugging Notes" subsection
- Check if it contains "Resolution: Pending"

**Step 2: Update Resolution**
- If debugging notes exist and tests now pass:
  - Use Edit tool to update: `Resolution: Pending` → `Resolution: Applied`
  - Add git commit hash line (will be added after commit)
  - This marks that the debugging led to a successful fix

**Step 3: Add Fix Commit Hash (after git commit)**
- After git commit succeeds
- If resolution was updated: Add commit hash to debugging notes
- Format: `Fix Applied In: [commit-hash]`

**Example:**
```markdown
#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase failed with null pointer
- **Debug Report**: [../reports/026_debug.md](../reports/026_debug.md)
- **Root Cause**: Missing null check
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

### 4. Git Commit
Create a structured commit:
```
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 5. Plan Update (After Git Commit Succeeds)
**Incremental plan updates after each phase:**

**Step 1: Mark Phase Tasks Complete**

Use the Edit tool to mark tasks as complete in the appropriate file:
- **Level 0**: Update tasks in main plan file
- **Level 1**: If phase is expanded, update tasks in phase file; otherwise update in main plan
- **Level 2**: If stage is expanded, update tasks in stage file; otherwise in phase file

**Approach**:
- Use Edit tool to change completed tasks: `- [ ]` → `- [x]`
- Check if phase/stage is expanded using progressive utilities
- Update in appropriate location based on expansion status

**Step 2: Add Phase Completion Marker**

Add completion marker to phase heading:
- **Level 0**: Add `[COMPLETED]` to phase heading in main plan
- **Level 1**: If phase is expanded, add marker to phase file; otherwise to main plan
- **Level 2**: Mark appropriate stage files and phase overview as complete

Use Edit tool to change:
`### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`

**Step 3: Verify Plan Updated**

Check that tasks are properly marked by reading the updated file and verifying all phase tasks show `[x]`.

**Step 4: Add/Update Implementation Progress Section**
- Use Edit tool to add or update "## Implementation Progress" section
- Place after metadata, before overview
- Include:
  - Last completed phase number and name
  - Completion date
  - Git commit hash
  - Resume instructions: `/implement <plan-file> <next-phase-number>`

**Example Implementation Progress Section:**
```markdown
## Implementation Progress

- **Last Completed Phase**: Phase 2: Core Implementation
- **Date**: 2025-10-03
- **Commit**: abc1234
- **Status**: In Progress (2/5 phases complete)
- **Resume**: `/implement specs/plans/018.md 3`
```

### 5.5. Collapse Opportunity Detection

After completing a phase and committing changes, evaluate if an expanded phase can be collapsed back to the main plan file using agent-based judgment.

**Trigger Conditions:**

Only check phases that meet BOTH criteria:
1. **Phase is expanded** (in a separate file, not inline)
2. **Phase is completed** (all tasks marked [x])

**Detection Logic:**

```bash
# Check if phase is expanded and completed
IS_PHASE_EXPANDED=$(.claude/lib/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
IS_PHASE_COMPLETED=$(grep -q "\[COMPLETED\]" "$PHASE_FILE" && echo "true" || echo "false")

if [ "$IS_PHASE_EXPANDED" = "true" ] && [ "$IS_PHASE_COMPLETED" = "true" ]; then
  # Evaluate collapse opportunity
fi
```

**Evaluation Approach:**

The primary agent (executing `/implement`) has the completed phase in context. I'll make an informed judgment about whether this phase is simple enough to collapse back to the main plan file.

**Evaluation Criteria:**

I'll consider:
- **Completion status**: All tasks are done (verified)
- **Simplicity**: Number of tasks and their individual complexity
- **Dependencies**: Whether tasks have minimal interdependencies
- **Value vs simplicity**: Does the separate file provide organizational value, or is it unnecessary fragmentation
- **Conceptual importance**: Is there a reason to keep it separate even if simple (e.g., represents distinct implementation stage)

**Evaluation Process:**

```
Read /home/benjamin/.config/.claude/prompts/evaluate-phase-collapse.md

Phase [N]: [Phase Name] [COMPLETED]

This phase is expanded (in separate file) and all tasks are complete.

Tasks completed:
[task list with [x] markers]

Follow the evaluation criteria and provide recommendation.
```

**If Collapse Recommended:**

Display formatted recommendation:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COLLAPSE OPPORTUNITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase [N]: [Phase Name] [COMPLETED]

Rationale:
  [Agent's 2-3 sentence rationale based on understanding completed work]

Recommendation:
  This simple phase can be collapsed back into the main plan file.

Command:
  /collapse phase <plan-path> [N]

Note: Collapsing is optional and non-destructive. The phase can be
re-expanded later if needed. Consider collapsing after all phases are
complete for best assessment of overall plan structure.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If No Collapse Recommended:**

Continue silently. No message needed for phases that should remain expanded.

**Not Eligible for Collapse:**

If phase is not expanded OR not completed, skip evaluation silently. No message needed.

**Non-Blocking:**

This check is purely informative. The user can choose to:
- Collapse now using the recommended command
- Wait until all phases are complete for better overall assessment
- Keep the phase expanded for organizational clarity
- Ignore the recommendation entirely

**Timing Considerations:**

- **After each phase**: Provides early feedback on simple phases
- **After plan completion**: Better for holistic assessment of structure
- **User preference**: Some users prefer to collapse incrementally, others prefer to wait

**Nuanced Decisions:**

The agent can make judgment calls that simple heuristics cannot:
- Keep a simple phase expanded if it's conceptually important
- Recommend collapse despite moderate complexity if work was straightforward
- Consider the phase in context of overall plan structure
- Balance simplicity vs documentation clarity

### 6. Incremental Summary Generation
**Create or update partial summary after each phase:**

**Step 1: Determine Summary Path**
- Extract specs directory from plan metadata
- Summary path: `[specs-dir]/summaries/NNN_partial.md`
- Number matches plan number

**Step 2: Create or Update Partial Summary**
- If first phase: Use Write tool to create new partial summary
- If subsequent phase: Use Edit tool to update existing partial summary
- Include:
  - Status: "in_progress"
  - Phases completed: "M/N"
  - Last completed phase name and date
  - Last git commit hash
  - Resume instructions

**Partial Summary Template:**
```markdown
# Implementation Summary: [Feature Name] (PARTIAL)

## Metadata
- **Date Started**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Summary Number**: [NNN]
- **Plan**: [Link to plan file]
- **Status**: in_progress
- **Phases Completed**: M/N

## Progress

### Last Completed Phase
- **Phase**: Phase M: [Phase Name]
- **Completed**: [YYYY-MM-DD]
- **Commit**: [hash]

### Phases Summary
- [x] Phase 1: [Name] - Completed [date]
- [x] Phase 2: [Name] - Completed [date]
- [ ] Phase 3: [Name] - Pending
- [ ] Phase 4: [Name] - Pending

## Resume Instructions
To continue this implementation:
```
/implement [plan-path] M+1
```

Auto-resume is enabled by default when calling /implement without arguments.

## Implementation Notes
[Brief notes about progress, challenges, or decisions made]
```

### 7. Before Starting Next Phase
**Defensive check before proceeding:**

**Step 1: Read Current Plan State**
- Use Read tool to read plan file
- Find previous phase heading

**Step 2: Verify Previous Phase Complete**
- Check that previous phase has `[COMPLETED]` marker
- Check that previous phase tasks are `[x]`

**Step 3: Mark Complete if Missing (Defensive)**
- If previous phase not marked but commit exists: Mark it now
- Log warning about inconsistency
- This ensures plan stays consistent even if previous update failed

## Test Detection Patterns

I'll look for and run:
- Commands containing `:lua.*test`
- Commands with `:Test`
- Standard test commands: `npm test`, `pytest`, `make test`
- Project-specific test commands based on configuration files

## Resuming Implementation

If we need to stop and resume later, you can use:
```
/implement <plan-file> <phase-number>
```

This will start from the specified phase number.

## Error Handling and Rollback

### Test Failures
If tests fail or issues arise:
1. I'll show the error details
2. We'll fix the issues together
3. Re-run tests before proceeding
4. Only move forward when tests pass

### Phase Failure Handling
**What happens when a phase fails:**

**Don't Mark Phase Complete:**
- If phase tests fail: Do NOT mark tasks as `[x]`
- Do NOT add `[COMPLETED]` marker to phase heading
- Do NOT update partial summary with this phase
- Do NOT create git commit

**Preserve Partial Work:**
- Keep code changes in working directory
- Previous phases remain marked complete
- Partial summary reflects only successful phases
- User can debug, fix, and retry the phase

**Retry Failed Phase:**
```
# After fixing issues
/implement <plan-file> <failed-phase-number>
```

**Partial Summary Always Accurate:**
- Partial summary only includes successfully completed phases
- "Phases Completed: M/N" reflects actual progress
- Resume instructions point to first incomplete phase
- Status remains "in_progress" until all phases complete

### Git Commit Failure Handling
If git commit fails after marking phase complete:
- Log error with details
- Preserve partial work (don't rollback code changes)
- Partial summary already reflects completed phase
- Manual intervention required to resolve git issues

## Summary Generation

After completing all phases, I'll:

### 1. Extract Specs Directory from Plan
- Read the plan file
- Extract "Specs Directory" from plan metadata
- This is where the summary will be created (same directory as plan)

### 2. Create Summary Directory
- Location: `[specs-dir]/summaries/` (from plan metadata)
- Create if it doesn't exist

### 3. Finalize Summary File
**Convert partial summary to final summary:**

**Step 1: Check for Partial Summary**
- Look for `[specs-dir]/summaries/NNN_partial.md`
- If exists: This is a resumed or interrupted implementation

**Step 2: Finalize Partial Summary**
- Use Bash tool to rename: `NNN_partial.md` → `NNN_implementation_summary.md`
- Use Edit tool to update the summary:
  - Change title: Remove "(PARTIAL)"
  - Update status: `in_progress` → `complete`
  - Update "Phases Completed": `M/N` → `N/N`
  - Add completion date
  - Remove "Resume Instructions" section
  - Add final "Lessons Learned" section

**Step 3: Or Create New Summary (if no partial)**
- If no partial summary exists: Use Write tool to create new summary
- Format: `NNN_implementation_summary.md`
- Number matches the plan number
- Location: `[specs-dir]/summaries/NNN_implementation_summary.md`
- Contains:
  - Implementation overview
  - Plan executed with link
  - Reports referenced (if any)
  - Key changes made
  - Test results
  - Lessons learned

### 4. Update SPECS.md Registry
- Increment "Summaries" count for this project
- Update "Last Updated" date
- Use Edit tool to update SPECS.md

### 5. Create Bidirectional Cross-References
**Add backward links from plan and reports to summary:**

**Step 1: Update Implementation Plan**
- Use Edit tool to append "## Implementation Summary" section to plan file:
  ```markdown
  ## Implementation Summary
  - **Status**: Complete
  - **Date**: [YYYY-MM-DD]
  - **Summary**: [link to specs/summaries/NNN_implementation_summary.md]
  ```
- Place at end of plan file

**Step 2: Update Research Reports (if any)**
- Extract research report paths from plan metadata
- For each report:
  - Use Edit tool to append "## Implementation Status" section:
    ```markdown
    ## Implementation Status
    - **Status**: Implemented
    - **Date**: [YYYY-MM-DD]
    - **Plan**: [link to specs/plans/NNN.md]
    - **Summary**: [link to specs/summaries/NNN_implementation_summary.md]
    ```
  - Place at end of report file

**Step 3: Verify Bidirectional Links**
- Use Read tool to verify each file was updated
- Check that plan has "Implementation Summary" section
- Check that each report (if any) has "Implementation Status" section
- If verification fails: Log warning but continue (don't block)

**Edge Cases:**
- If plan/report file not writable: Log warning, continue
- If file already has implementation section: Update existing with Edit tool, don't duplicate
- If no research reports: Skip Step 2

### Summary Format
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Summary Number**: [NNN]
- **Plan**: [Link to plan file]
- **Research Reports**: [Links to reports used]
- **Phases Completed**: [N/N]

## Implementation Overview
[Brief description of what was implemented]

## Key Changes
- [Major change 1]
- [Major change 2]

## Test Results
[Summary of test outcomes]

## Report Integration
[How research informed implementation]

## Lessons Learned
[Insights from implementation]
```

## Finding the Implementation Plan

### Auto-Detection Logic (when no arguments provided):
```bash
# 1. Find all plans (both files and directories), sorted by modification time
# - Level 0 plans: specs/plans/NNN_*.md
# - Level 1/2 plans: specs/plans/NNN_*/NNN_*.md
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" -exec ls -t {} + 2>/dev/null

# 2. For each plan, use progressive parser to check status:
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# 3. Select the first incomplete plan
```

### If no plan file provided:
I'll search for the most recent incomplete implementation plan by:
1. Looking in all `specs/plans/` directories for both files and directories
2. Sorting by modification time (most recent first)
3. Detecting structure level using `parse-adaptive-plan.sh detect_structure_level`
4. Checking plan status by reading phase completion markers
5. Selecting the first incomplete plan found
6. Determining the first incomplete phase to resume from

### If a plan file or directory is provided:
I'll use the specified plan directly and:
1. Detect structure level (0, 1, or 2) using parsing utility
2. Read appropriate plan file based on expansion status
3. Check completion status using `[COMPLETED]` markers
4. Find first incomplete phase (if any)
5. Resume from that phase or start from phase 1

### Plan Status Detection:
Check for completion markers in appropriate files:

- **Complete Plan**: All phases have `[COMPLETED]` marker
- **Incomplete Phase**: Phase lacks `[COMPLETED]` marker or has unchecked tasks
- **Level 0**: Check phase headings and task checkboxes in main plan file
- **Level 1**: Check completion markers in expanded phase files and main plan
- **Level 2**: Check completion across stage files, phase files, and main plan

## Integration with Other Commands

### Standards Flow
This command is part of the standards enforcement pipeline:

1. `/report` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan metadata
3. `/implement` - **Applies standards during code generation** (← YOU ARE HERE)
4. `/test` - Verifies implementation using standards-defined test commands
5. `/document` - Creates documentation following standards format
6. `/refactor` - Validates code against standards

### How /implement Uses Standards

#### From /plan
- Reads captured standards file path from plan metadata
- Uses plan's documented test commands and coding style

#### Applied During Implementation
- **Code generation**: Follows Code Standards (indentation, naming, error handling)
- **Test execution**: Uses Testing Protocols (test commands, patterns)
- **Documentation**: Creates docs per Documentation Policy

#### Verified Before Commit
- Standards compliance checked before marking phase complete
- Commit message notes which standards were applied

### Example Flow
```
User runs: /plan "Add authentication"
  ↓
/plan discovers CLAUDE.md:
  - Code Standards: snake_case, 2 spaces, pcall
  - Testing: :TestSuite
  ↓
Plan metadata captures: Standards File: CLAUDE.md
  ↓
User runs: /implement auth_plan.md
  ↓
/implement discovers CLAUDE.md + reads plan:
  - Confirms standards
  - Applies during generation
  - Tests with :TestSuite
  - Verifies compliance
  ↓
Generated code follows standards automatically
```

## Agent Usage

This command does not directly invoke specialized agents. Instead, it executes implementation directly using its own tools (Read, Edit, Write, Bash, TodoWrite).

### Potential Agent Integration (Future Enhancement)
While `/implement` currently works autonomously, it could potentially delegate to specialized agents:

- **code-writer**: For complex code generation tasks
  - Would receive plan context and phase requirements
  - Could apply standards more intelligently
  - Would use TodoWrite for task tracking

- **test-specialist**: For test execution and analysis
  - Could provide more detailed test failure diagnostics
  - Would categorize errors more effectively
  - Could suggest fixes for common test failures

- **code-reviewer**: For standards compliance checking
  - Optional pre-commit validation
  - Could run after each phase before marking complete
  - Would provide structured feedback on standards violations

### Current Design Rationale
`/implement` executes directly without agent delegation because:
1. **Performance**: Avoids agent invocation overhead for simple implementations
2. **Context**: Maintains full implementation context across all phases
3. **Control**: Direct execution provides more predictable behavior
4. **Simplicity**: Easier to debug and reason about

For complex, multi-phase implementations requiring specialized expertise, use `/orchestrate` instead, which fully leverages the agent system.

## Checkpoint Detection and Resume

Before starting implementation, I'll check for existing checkpoints that might indicate an interrupted implementation.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent implement checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh implement 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

If a checkpoint exists for this plan, I'll present interactive options:

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

### Step 3: Resume Implementation State (if user chooses resume)

If user selects resume:
1. Load plan_path from checkpoint
2. Restore current_phase, completed_phases
3. Skip to next incomplete phase
4. Continue implementation from that point

### Step 4: Save Checkpoints After Each Phase

After each phase completes successfully (after git commit):

```bash
# Build checkpoint state
STATE_JSON=$(cat <<EOF
{
  "workflow_description": "Implement [plan-name]",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "total_phases": $TOTAL_PHASES,
  "completed_phases": [$COMPLETED_PHASES_ARRAY],
  "status": "in_progress",
  "tests_passing": true
}
EOF
)

# Save checkpoint
PROJECT_NAME=$(basename "$PLAN_PATH" .md | sed 's/^[0-9]*_//')
.claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON"
```

### Step 5: Cleanup on Completion

On successful implementation completion:
```bash
# Delete checkpoint file
rm .claude/checkpoints/implement_${PROJECT_NAME}_*.json
```

On implementation failure:
```bash
# Update checkpoint with error info, archive to failed/
STATE_JSON=$(cat <<EOF
{
  "status": "failed",
  "last_error": "$ERROR_MESSAGE",
  "failed_phase": $CURRENT_PHASE
}
EOF
)
.claude/lib/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON"
mv .claude/checkpoints/implement_${PROJECT_NAME}_*.json .claude/checkpoints/failed/
```

Let me start by finding your implementation plan.
