# Phase 5: Debugging Loop Refactor

## Metadata
- **Phase Number**: 5
- **Parent Plan**: 042_orchestrate_command_execution_refactor.md
- **Dependencies**: Phase 4 (Implementation Phase Refactor)
- **Complexity**: HIGHEST (10/10)
- **Estimated Hours**: 6-8
- **Status**: PENDING
- **Lines**: 845-1136 of orchestrate.md (291 lines)

## Objective

Transform the debugging loop from passive documentation into an execution-driven iterative control structure that:
- **Explicitly invokes** debug-specialist and code-writer agents using Task tool
- **Enforces** strict 3-iteration limit to prevent infinite loops
- **Manages** iteration state and debug history across attempts
- **Escalates** to user with actionable message when limit exceeded
- **Creates** persistent debug report files for issue tracking
- **Coordinates** dual-agent handoff (diagnosis → fix application)

This is the most complex phase due to iteration control logic, dual-agent coordination, state management across loop iterations, and multiple exit conditions (success, escalation, continued iteration).

## Context and Background

### Why This Is The Most Complex Phase

1. **Iteration Control Logic**: Unlike other phases (single agent invocation), debugging requires loop management with counter tracking, limit enforcement, and conditional branching
2. **Dual-Agent Coordination**: Two different agents must work together - debug-specialist investigates and creates report, code-writer reads report and applies fix
3. **State Accumulation**: Each iteration builds on previous attempts - error messages, fixes tried, debug reports created must be tracked
4. **Multiple Exit Conditions**: Loop can exit via success (tests pass), escalation (3 iterations reached), or agent failure (requires error handling)
5. **History Context**: Iteration 2 and 3 must know what was tried in previous iterations to avoid repeating failed solutions

### Current Problem (Documentation-Only)

The current debugging section (lines 845-1136) **describes** how debugging should work but doesn't **instruct** execution:

```markdown
CURRENT (Passive):
"For test failure handling patterns, see [Test Failure Handling]..."
"This phase engages ONLY when implementation reports test failures."
"I'll invoke debug-specialist agent..."

NEEDED (Active):
**EXECUTE NOW**: IF tests_passing == false, ENTER debugging loop.

USE the Task tool to invoke debug-specialist agent:
[actual Task tool syntax here]
```

### Integration Points

- **Entry**: Triggered by Phase 4 (Implementation) when tests_passing == false
- **Exit Success**: Proceeds to Phase 6 (Documentation) when tests pass
- **Exit Escalation**: Presents user with options when 3 iterations exhausted
- **File Creation**: Debug reports created in `debug/{topic}/NNN_*.md` (NOT gitignored, unlike specs/)

## Architecture: Debugging Loop Control Flow

### State Management

```yaml
workflow_state:
  debug_iteration: 0              # Current iteration (0-3)
  debug_topic_slug: ""            # Topic for debug report directory
  debug_reports: []               # Array of debug report paths
  debug_history: []               # History of attempts
    - iteration: N
      report_path: "debug/topic/NNN_*.md"
      fix_attempted: "Brief summary"
      result: "Still failing" | "Tests passing"
      new_errors: ["error messages"]
  implementation_status:
    tests_passing: false          # Updated each iteration
    test_output: ""               # Latest test results
    error_messages: []            # Latest errors
```

### Loop Logic (High-Level)

```
ENTRY CONDITIONS:
- tests_passing == false (from Phase 4)
- debug_iteration == 0 (not yet started)

LOOP (while tests_failing AND debug_iteration < 3):
  1. Increment debug_iteration
  2. Generate debug topic slug (if first iteration)
  3. INVOKE debug-specialist agent → create debug report
  4. Extract debug report path and recommendations
  5. INVOKE code-writer agent → apply recommended fix
  6. RUN tests again
  7. UPDATE workflow_state with results

  IF tests_passing:
    SAVE checkpoint(success)
    EXIT loop → Proceed to Phase 6 (Documentation)
  ELIF debug_iteration >= 3:
    SAVE checkpoint(escalation)
    EXIT loop → ESCALATE to user
  ELSE:
    ADD attempt to debug_history
    CONTINUE loop (next iteration)

EXIT CONDITIONS:
- Success: tests_passing == true
- Escalation: debug_iteration >= 3 AND tests_passing == false
- Error: agent failure (handled by error recovery)
```

### Decision Tree

```
┌─────────────────────────────┐
│ Phase 4: Implementation     │
│ tests_passing == false      │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ ENTER Debugging Loop        │
│ debug_iteration = 0         │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│ Iteration 1                 │
│ debug_iteration++           │
│ Generate topic slug         │
│ Invoke debug-specialist     │
│ Invoke code-writer          │
│ Run tests                   │
└──────────┬──────────────────┘
           │
           ▼
      ┌────────┐
      │ Tests  │
      │ Pass?  │
      └────┬───┘
           │
    ┌──────┴──────┐
    │             │
   YES            NO
    │             │
    ▼             ▼
┌───────┐   ┌────────────┐
│SUCCESS│   │Iteration 2 │
│→ Doc  │   │debug++     │
│Phase  │   │Add history │
└───────┘   │Retry loop  │
            └─────┬──────┘
                  │
                  ▼
            ┌────────┐
            │ Tests  │
            │ Pass?  │
            └────┬───┘
                 │
          ┌──────┴──────┐
          │             │
         YES            NO
          │             │
          ▼             ▼
      ┌───────┐   ┌────────────┐
      │SUCCESS│   │Iteration 3 │
      │→ Doc  │   │debug++     │
      │Phase  │   │Add history │
      └───────┘   │Retry loop  │
                  └─────┬──────┘
                        │
                        ▼
                  ┌────────┐
                  │ Tests  │
                  │ Pass?  │
                  └────┬───┘
                       │
                ┌──────┴──────┐
                │             │
               YES            NO
                │             │
                ▼             ▼
            ┌───────┐   ┌──────────┐
            │SUCCESS│   │ESCALATION│
            │→ Doc  │   │→ User    │
            │Phase  │   │Options   │
            └───────┘   └──────────┘
```

## Detailed Implementation Steps

### Step 1: Initialize Debugging Loop

**Location**: Lines 845-850 (replace section header)

**Current Text**:
```markdown
### Debugging Loop (Conditional - Only if Tests Fail)

For test failure handling patterns, see [Test Failure Handling](../docs/command-patterns.md#pattern-test-failure-handling).

This phase engages ONLY when implementation reports test failures. Maximum 3 debugging iterations before escalating to user.
```

**Refactored Text**:
```markdown
### Debugging Loop (Conditional - Only if Tests Fail)

**ENTRY CONDITIONS**:
```yaml
if workflow_state.implementation_status.tests_passing == false:
  ENTER debugging loop
else:
  SKIP to Phase 6 (Documentation)
```

**EXECUTE NOW: Initialize Debugging State**

Before first iteration, initialize debugging state:

```yaml
workflow_state.debug_iteration = 0
workflow_state.debug_topic_slug = ""      # Generated in Step 2
workflow_state.debug_reports = []         # Populated each iteration
workflow_state.debug_history = []         # Tracks all attempts
```

**Iteration Limit**: Maximum 3 debugging iterations. After 3 failures, escalate to user with actionable options.

**Loop Strategy**: Each iteration follows this sequence:
1. Generate debug topic slug (iteration 1 only)
2. Invoke debug-specialist → create report file
3. Extract report path and recommendations
4. Invoke code-writer → apply fix from report
5. Run tests again
6. Evaluate results → continue, succeed, or escalate
```

### Step 2: Generate Debug Topic Slug

**Location**: Lines 851-871 (refactor Step 1)

**Current Text** (passive description):
```markdown
#### Step 1: Generate Debug Topic Slug

Before invoking debug-specialist, create a topic slug for the debug report:

**Topic Slug Generation**:
```
1. Use failed phase number: "phase{N}_failures"
...
```

**Refactored Text** (imperative execution):
```markdown
#### Step 1: Generate Debug Topic Slug (First Iteration Only)

**EXECUTE NOW: Generate Topic Slug**

IF debug_iteration == 1 AND debug_topic_slug is empty:

ANALYZE the test failure error messages to categorize the issue type.

**Topic Slug Algorithm**:

1. **Phase-Based** (default): Use failed phase number from implementation
   - Format: `phase{N}_failures`
   - Example: Phase 1 failed → `phase1_failures`

2. **Error-Type-Based** (preferred if pattern clear):
   - Integration failures → `integration_issues`
   - Timeout errors → `test_timeout`
   - Configuration errors → `config_errors`
   - Missing dependencies → `dependency_missing`
   - Syntax/compilation → `syntax_errors`

3. **Slug Rules**:
   - Lowercase with underscores
   - Concise (2-3 words max)
   - Descriptive of root issue type

**EXECUTE: Create Slug**

```bash
# Example slug generation logic
if error_message contains "timeout":
  debug_topic_slug = "test_timeout"
elif error_message contains "config":
  debug_topic_slug = "config_errors"
elif error_message contains "integration":
  debug_topic_slug = "integration_issues"
elif error_message contains "dependency" or "module not found":
  debug_topic_slug = "dependency_missing"
else:
  # Default: use failed phase number
  debug_topic_slug = "phase{failed_phase_number}_failures"
```

**Store in workflow_state**:
```yaml
workflow_state.debug_topic_slug = "[generated_slug]"
```

**Examples**:
- Integration test failure → `integration_issues`
- Phase 1 config loading error → `phase1_failures` or `config_errors`
- Test timeout in Phase 3 → `test_timeout`
```

### Step 3: Invoke Debug Specialist Agent

**Location**: Lines 877-928 (refactor Step 2)

**Current Text** (example YAML, not execution):
```markdown
#### Step 2: Invoke Debug Specialist Agent with File Creation

**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Create debug report for test failures using debug-specialist protocol"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/debug-specialist.md
  ...
```

**Refactored Text** (explicit execution instruction):
```markdown
#### Step 2: Invoke Debug Specialist Agent with File Creation

**EXECUTE NOW: USE the Task tool to invoke debug-specialist agent**

This agent will:
- Investigate test failure root cause
- Analyze error messages and code context
- Create persistent debug report file
- Propose 2-3 solution options
- Recommend best fix approach

**Task Tool Invocation** (execute this now):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create debug report for test failures using debug-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist Agent with the tools and constraints
    defined in that file.

    Create Debug Report File for Implementation Test Failures:

    ## Context
    - **Workflow**: "[workflow_state.workflow_description]"
    - **Project**: [project_name]
    - **Failed Phase**: Phase [failed_phase_number] - [phase_name]
    - **Topic Slug**: [workflow_state.debug_topic_slug]
    - **Iteration**: [workflow_state.debug_iteration] of 3

    ## Test Failures
    [workflow_state.implementation_status.test_output]

    ## Error Details
    - **Error messages**:
      [workflow_state.implementation_status.error_messages]

    - **Modified files**:
      [workflow_state.implementation_status.files_modified]

    - **Plan reference**: [workflow_state.plan_path]

    [IF debug_iteration > 1:]
    ## Previous Debug Attempts
    [FOR each attempt in workflow_state.debug_history:]
    ### Iteration [attempt.iteration]
    - **Report**: [attempt.report_path]
    - **Fix attempted**: [attempt.fix_attempted]
    - **Result**: [attempt.result]
    - **New errors**: [attempt.new_errors]

    ## Investigation Requirements
    - Analyze test failure patterns and root cause
    - Review relevant code and configurations
    - Consider previous debug attempts (if iteration > 1)
    - Identify why previous fixes didn't work (if applicable)
    - Propose 2-3 solutions with tradeoffs
    - Recommend the most likely solution to succeed

    ## Debug Report Creation Instructions
    1. USE Glob to find existing reports: `debug/[debug_topic_slug]/[0-9][0-9][0-9]_*.md`
    2. DETERMINE next report number (NNN format, incremental)
    3. CREATE report file using Write tool:
       Path: `debug/[debug_topic_slug]/NNN_[descriptive_name].md`
    4. INCLUDE all required metadata fields (see agent file, lines 256-346)
    5. RETURN file path in parseable format

    ## Expected Output Format

    **Primary Output** (required):
    ```
    DEBUG_REPORT_PATH: debug/[topic]/NNN_descriptive_name.md
    ```

    **Secondary Output** (required):
    Brief summary (1-2 sentences):
    - Root cause: [What is causing the failure]
    - Recommended fix: Option [N] - [Brief description]

    Example:
    ```
    DEBUG_REPORT_PATH: debug/phase1_failures/001_config_initialization.md

    Root cause: Config file not initialized before first test runs.
    Recommended fix: Option 2 - Add config initialization in test setup hook
    ```
}
```

**WAIT for agent completion before proceeding.**
```

### Step 4: Extract Debug Report Path and Recommendations

**Location**: Lines 930-953 (refactor Step 3)

**Current Text** (descriptive):
```markdown
#### Step 3: Extract Debug Report Path and Recommendations

**Path Extraction**:
```markdown
From debug-specialist agent output, extract:
- Debug report path: DEBUG_REPORT_PATH: debug/{topic}/NNN_*.md
...
```

**Refactored Text** (imperative extraction):
```markdown
#### Step 3: Extract Debug Report Path and Recommendations

**EXECUTE NOW: Parse Debug Specialist Output**

From the debug-specialist agent output, EXTRACT the following information:

**Required Extraction**:

1. **Debug Report Path**:
   - Pattern: `DEBUG_REPORT_PATH: debug/{topic}/NNN_*.md`
   - Example: `DEBUG_REPORT_PATH: debug/phase1_failures/001_config_initialization.md`
   - Store in: `debug_report_path` variable

2. **Root Cause Summary**:
   - Pattern: After "Root cause:" line
   - Extract: Brief 1-2 sentence description
   - Store in: `root_cause` variable

3. **Recommended Fix**:
   - Pattern: After "Recommended fix:" line
   - Extract: Which option number and brief description
   - Store in: `recommended_fix` variable

**EXECUTE: Validation Checklist**

Before proceeding, verify:
- [ ] Debug report file exists at extracted path
- [ ] File contains all required metadata sections
- [ ] Root cause clearly identified
- [ ] 2-3 solution options proposed with tradeoffs
- [ ] Recommended solution explicitly specified
- [ ] File follows debug report structure (see debug-specialist.md lines 256-346)

**IF validation fails**:
- RETRY debug-specialist invocation with clarifying instructions
- Maximum 2 retries before escalating to user

**EXECUTE: Store in Workflow State**

```yaml
workflow_state.debug_reports.append(debug_report_path)

# Example state after extraction:
workflow_state:
  debug_reports: [
    "debug/phase1_failures/001_config_initialization.md"
  ]
```

**Example Parsed Output**:
```
debug_report_path = "debug/phase1_failures/001_config_initialization.md"
root_cause = "Config file not initialized before first test runs"
recommended_fix = "Option 2 - Add config initialization in test setup hook"
```
```

### Step 5: Invoke Code Writer for Fix Application

**Location**: Lines 955-991 (refactor Step 4)

**Current Text** (example YAML):
```markdown
#### Step 4: Apply Recommended Fix

Invoke code-writer agent with fix proposals from debug report:

**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Apply debug fixes from report using code-writer protocol"
...
```

**Refactored Text** (explicit execution):
```markdown
#### Step 4: Apply Recommended Fix Using Code Writer Agent

**EXECUTE NOW: USE the Task tool to invoke code-writer agent**

This agent will:
- Read the debug report created in Step 3
- Understand the root cause and proposed solutions
- Implement the recommended solution
- Apply changes to affected files
- Prepare code for testing (but NOT run tests yet)

**Task Tool Invocation** (execute this now):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Apply debug fixes from report using code-writer protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer Agent with the tools and constraints
    defined in that file.

    Apply fixes from debug report:

    ## Debug Report
    **Path**: [debug_report_path from Step 3]

    READ the report using the Read tool to understand:
    - Root cause of test failures (Analysis section)
    - Proposed solutions (Options 1-3 in Proposed Solutions section)
    - Recommended solution (Recommendation section)
    - Implementation steps (within recommended solution option)

    ## Task
    IMPLEMENT the recommended solution from the debug report.

    ## Requirements
    - Follow implementation steps from recommended solution option
    - Apply changes to affected files using Edit or Write tools
    - Follow project coding standards (reference: /home/benjamin/.config/CLAUDE.md)
    - Add comments explaining the fix where appropriate
    - DO NOT run tests yet (orchestrator will run tests in Step 5)

    ## Context for Implementation
    - **Iteration**: [workflow_state.debug_iteration] of 3
    - **Previous attempts**: [IF iteration > 1: summary of previous fixes]
    - **Files to modify**: [From debug report's recommended solution]

    ## Expected Output
    Provide a brief summary:
    - **Files modified**: [list of files changed]
    - **Changes made**: [brief description of what was fixed]
    - **Ready for testing**: true

    Example:
    ```
    Files modified:
    - tests/setup.lua
    - config/init.lua

    Changes made:
    - Added config initialization in test setup hook
    - Ensured config loads before first test runs

    Ready for testing: true
    ```
}
```

**WAIT for agent completion before proceeding to testing.**

**EXECUTE: Capture Fix Summary**

From code-writer output, extract:
- `files_modified`: List of files changed
- `fix_description`: Brief summary of changes
- Store for debug history in Step 7
```

### Step 6: Run Tests and Extract Results

**Location**: Lines 993-1012 (refactor Step 5)

**Current Text** (descriptive):
```markdown
#### Step 5: Run Tests Again

After applying fixes, run tests to validate:

```bash
# Run test command from plan or project standards
[test_command_from_plan]
...
```

**Refactored Text** (explicit execution):
```markdown
#### Step 5: Run Tests Again

**EXECUTE NOW: Run Tests to Validate Fix**

After code-writer applies the fix, run tests to determine if issue is resolved.

**Test Command Determination**:

1. **From Plan** (preferred): Check `workflow_state.plan_path` for test command
2. **From CLAUDE.md** (fallback): Check Testing Protocols section
3. **Default**: Use project-standard test command

**EXECUTE: Run Test Command**

```bash
# Execute test command via Bash tool
# Example commands (use appropriate for project):

# Claude Code project:
bash .claude/tests/run_all_tests.sh

# Python project:
pytest tests/

# JavaScript project:
npm test

# General:
[test_command from plan or CLAUDE.md]
```

**EXECUTE: Capture Test Results**

Parse test output to extract:

1. **Test Status**:
   ```yaml
   tests_passing: true | false
   ```

2. **Test Output** (if failing):
   ```yaml
   test_output: "[Full test output for next iteration context]"
   error_messages: [
     "Error 1 from output",
     "Error 2 from output"
   ]
   ```

3. **Success Indicators**:
   - All tests pass: `tests_passing = true`
   - Same errors: `tests_passing = false, errors unchanged`
   - New errors: `tests_passing = false, errors different`
   - Fewer errors: `tests_passing = false, progress = true`

**EXECUTE: Update Workflow State**

```yaml
workflow_state.implementation_status.tests_passing = [true|false]
workflow_state.implementation_status.test_output = "[latest output]"
workflow_state.implementation_status.error_messages = [extracted errors]
```

**Example Result**:
```yaml
# Success case:
tests_passing: true
test_output: "All 47 tests passed in 12.3s"

# Failure case:
tests_passing: false
test_output: "[Full output showing 3 failing tests]"
error_messages: [
  "test_auth: JWT decode error",
  "test_session: Token validation failed",
  "test_middleware: nil config.secret"
]
```
```

### Step 7: Iteration Control and Decision Logic

**Location**: Lines 1013-1039 (refactor Step 6)

**Current Text** (YAML pseudocode):
```markdown
#### Step 6: Decision Logic - Continue or Escalate

```yaml
if tests_passing:
  → Mark debug iteration successful
...
```

**Refactored Text** (explicit control flow):
```markdown
#### Step 6: Iteration Control and Decision Logic

**EXECUTE NOW: Evaluate Test Results and Determine Next Action**

Based on test results from Step 5, execute the appropriate branch:

```python
# Increment iteration counter (always)
workflow_state.debug_iteration += 1

# Decision tree (evaluate in this order):

IF tests_passing == true:
  # SUCCESS PATH
  EXECUTE: Branch 1 - Tests Passing (Success)

ELIF debug_iteration >= 3:
  # ESCALATION PATH (limit reached)
  EXECUTE: Branch 2 - Escalation to User

ELSE:
  # CONTINUE PATH (try again)
  EXECUTE: Branch 3 - Continue Debugging Loop
```

---

### Branch 1: Tests Passing (Success)

**Condition**: `tests_passing == true`

**EXECUTE: Success Actions**

1. **Mark debugging successful**:
   ```yaml
   workflow_state.debug_status = "resolved"
   workflow_state.debug_iterations_needed = debug_iteration
   ```

2. **Add resolution to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: debug_iteration,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Tests passing",
     resolution: "Success"
   })
   ```

3. **Update error history** (for tracking):
   ```yaml
   workflow_state.error_history.append({
     phase: "implementation",
     issue: root_cause,
     debug_reports: workflow_state.debug_reports,
     resolution: "Fixed in iteration {debug_iteration}",
     fix_applied: fix_description
   })
   ```

4. **SAVE checkpoint**:
   ```yaml
   checkpoint_tests_passing:
     phase_name: "debugging"
     completion_time: [timestamp]
     outputs:
       tests_passing: true
       debug_iterations: debug_iteration
       debug_reports: workflow_state.debug_reports
       issues_resolved: [root_cause]
       status: "success"
     next_phase: "documentation"
     performance:
       debugging_time: "[duration]"
       iterations_needed: debug_iteration
   ```

5. **PROCEED to Phase 6** (Documentation):
   ```markdown
   ✓ Debugging Phase Complete

   Tests passing: ✓
   Debug iterations: {debug_iteration}
   Issues resolved: {issues_count}
   Debug reports: {report_paths}

   Next: Documentation Phase
   ```

**EXIT debugging loop → Go to Phase 6**

---

### Branch 2: Escalation to User

**Condition**: `debug_iteration >= 3 AND tests_passing == false`

**EXECUTE: Escalation Actions**

1. **Mark debugging as escalated**:
   ```yaml
   workflow_state.debug_status = "escalated"
   workflow_state.debug_iterations_needed = 3
   ```

2. **Add final attempt to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: 3,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Still failing after 3 iterations",
     escalation_reason: "Maximum debugging iterations reached"
   })
   ```

3. **SAVE escalation checkpoint**:
   ```yaml
   checkpoint_escalation:
     phase_name: "debugging"
     completion_time: [timestamp]
     outputs:
       tests_passing: false
       debug_iterations: 3
       debug_reports: workflow_state.debug_reports
       unresolved_issues: workflow_state.implementation_status.error_messages
       status: "escalated"
     next_phase: "manual_intervention"
     user_options: ["continue", "retry", "rollback", "terminate"]
     debug_summary: |
       Attempted 3 debugging iterations. Tests still failing.

       Issues remaining:
       {list of error_messages}

       Debug reports created:
       {list of debug_report_paths with brief summaries}
   ```

4. **PRESENT escalation message to user** (see Step 8 for template)

**EXIT debugging loop → Wait for user decision**

---

### Branch 3: Continue Debugging Loop

**Condition**: `debug_iteration < 3 AND tests_passing == false`

**EXECUTE: Prepare for Next Iteration**

1. **Add current attempt to debug history**:
   ```yaml
   workflow_state.debug_history.append({
     iteration: debug_iteration,
     report_path: debug_report_path,
     fix_attempted: fix_description,
     result: "Still failing",
     new_errors: workflow_state.implementation_status.error_messages
   })
   ```

2. **Prepare context for next iteration**:
   - Keep `workflow_state.debug_topic_slug` (don't regenerate)
   - Keep `workflow_state.debug_reports` (accumulate)
   - Keep `workflow_state.debug_history` (accumulate)
   - Update `error_messages` with latest failures

3. **RETURN to Step 2** (Invoke Debug Specialist) with enriched context:
   - Next invocation will include debug_history
   - debug-specialist will see previous attempts
   - code-writer will know what was already tried

**CONTINUE debugging loop → Go to Step 2 (iteration {debug_iteration + 1})**

---

**Summary of Decision Logic**:

| Condition | Action | Next Phase |
|-----------|--------|------------|
| Tests passing | Save success checkpoint | Phase 6 (Documentation) |
| Iteration >= 3, tests failing | Save escalation checkpoint, present options | User Decision |
| Iteration < 3, tests failing | Add to history, continue loop | Step 2 (next iteration) |
```

### Step 8: User Escalation Message Template

**Location**: Lines 1040-1114 (refactor Steps 7-8, combine)

**Current Text** (separate steps for workflow state and checkpoint):
```markdown
#### Step 7: Update Workflow State with Debug Reports
...
#### Step 8: Save Debug Checkpoint
...
```

**Refactored Text** (combined with escalation template):
```markdown
#### Step 7: Update Workflow State (All Branches)

**EXECUTE: Update workflow_state (performed in all branches)**

Update workflow state based on debugging outcome:

```yaml
# State updated in Branch 1 (Success):
workflow_state.context_preservation.debug_reports: [
  {
    topic: "[debug_topic_slug]",
    path: "debug/{topic}/NNN_*.md",
    number: "NNN",
    iteration: N,
    resolved: true
  }
]

# State updated in Branch 2 (Escalation):
workflow_state.context_preservation.debug_reports: [
  {topic: "...", path: "...", resolved: false},
  {topic: "...", path: "...", resolved: false},
  {topic: "...", path: "...", resolved: false}
]

# State updated in Branch 3 (Continue):
workflow_state.debug_history: [
  {iteration: 1, result: "Still failing", ...},
  {iteration: 2, result: "Still failing", ...}
]
```

---

#### Step 8: User Escalation Message (Branch 2 Only)

**EXECUTE: Present Escalation Message (only if Branch 2 triggered)**

When `debug_iteration >= 3` and tests still failing, present this message to user:

```markdown
⚠️ **Debugging Loop: Maximum Iterations Reached**

**Status**: Escalation required after 3 debugging iterations

---

## Issue Summary

**Original Problem**:
[Root cause from first debug report]

**Tests Status**: Still failing after 3 fix attempts

**Unresolved Errors**:
{list each error from workflow_state.implementation_status.error_messages}

---

## Debugging Attempts

### Iteration 1
- **Debug Report**: {debug_reports[0]}
- **Fix Attempted**: {debug_history[0].fix_attempted}
- **Result**: {debug_history[0].result}
- **New Errors**: {debug_history[0].new_errors}

### Iteration 2
- **Debug Report**: {debug_reports[1]}
- **Fix Attempted**: {debug_history[1].fix_attempted}
- **Result**: {debug_history[1].result}
- **New Errors**: {debug_history[1].new_errors}

### Iteration 3
- **Debug Report**: {debug_reports[2]}
- **Fix Attempted**: {debug_history[2].fix_attempted}
- **Result**: {debug_history[2].result}
- **New Errors**: {debug_history[2].new_errors}

---

## Your Options

I've reached the maximum automated debugging iterations (3). Here are your options:

**Option 1: Manual Investigation**
- Review the 3 debug reports created:
  - {debug_reports[0]}
  - {debug_reports[1]}
  - {debug_reports[2]}
- Manually investigate and fix the issue
- Resume workflow after fixing: Use checkpoint_escalation to resume

**Option 2: Retry with Guidance**
- Provide additional context or hints about the issue
- I'll retry debugging with your guidance
- Command: `/orchestrate resume --with-context "your guidance"`

**Option 3: Alternative Approach**
- Rollback to last successful phase (Phase 4: Implementation complete)
- Try a different implementation approach
- Command: `/orchestrate rollback phase4`

**Option 4: Skip Debugging**
- Proceed to documentation phase despite failing tests
- Mark tests as "known issues" in documentation
- Command: `/orchestrate continue --skip-tests`

**Option 5: Terminate Workflow**
- End workflow here, preserve all work completed
- Checkpoints saved: research, planning, implementation, debugging attempts
- Command: `/orchestrate terminate`

---

## Checkpoint Saved

A checkpoint has been saved at:
- **Checkpoint ID**: `checkpoint_escalation`
- **Phase**: debugging (incomplete)
- **Resume Command**: `/orchestrate resume`

All debug reports, implementation work, and history are preserved.

---

## Recommended Next Steps

1. **Investigate manually**: Start with the most recent debug report ({debug_reports[2]})
2. **Check for patterns**: Do all 3 attempts share a common issue?
3. **Review test configuration**: Are tests themselves correct?
4. **Consider scope**: Is this issue within original workflow scope?

**What would you like to do?** [Respond with option number or custom action]
```

**PAUSE workflow and WAIT for user input.**
```

## Debugging Loop Code Examples

### Example 1: Single Iteration Success

```yaml
# Scenario: Fix works on first try

Iteration 1:
  debug_iteration: 1
  debug_topic_slug: "phase1_failures"

  Step 2: debug-specialist creates:
    - Report: debug/phase1_failures/001_config_initialization.md
    - Root cause: "Config not initialized before tests"
    - Recommended: "Option 2 - Add init in test setup"

  Step 3: Extract:
    - debug_report_path = "debug/phase1_failures/001_config_initialization.md"

  Step 4: code-writer applies:
    - Modified: tests/setup.lua
    - Added: config.init() call in setup function

  Step 5: Run tests:
    - Result: All 47 tests pass
    - tests_passing = true

  Step 6: Branch 1 (Success):
    - Save checkpoint(success)
    - debug_iterations_needed = 1
    - EXIT loop → Phase 6 (Documentation)

Outcome: ✓ Success in 1 iteration
```

### Example 2: Two Iteration Success

```yaml
# Scenario: First fix incomplete, second fix succeeds

Iteration 1:
  debug_iteration: 1
  debug_topic_slug: "integration_issues"

  Step 2: debug-specialist creates:
    - Report: debug/integration_issues/001_auth_token_missing.md
    - Root cause: "Auth token not passed to middleware"
    - Recommended: "Option 1 - Add token to request context"

  Step 4: code-writer applies:
    - Modified: middleware/auth.lua
    - Added: token extraction from headers

  Step 5: Run tests:
    - Result: 2 tests still failing
    - Error: "config.secret is nil"
    - tests_passing = false

  Step 6: Branch 3 (Continue):
    - Add to debug_history[0]
    - CONTINUE to Iteration 2

Iteration 2:
  debug_iteration: 2
  debug_topic_slug: "integration_issues" (reuse)

  Step 2: debug-specialist creates (with history):
    - Report: debug/integration_issues/002_secret_initialization.md
    - Context: "Previous fix addressed token extraction, but config.secret still nil"
    - Root cause: "Secret not loaded in test environment"
    - Recommended: "Option 2 - Mock secret in test config"

  Step 4: code-writer applies:
    - Modified: tests/config_mock.lua
    - Added: config.secret = "test-secret-key"

  Step 5: Run tests:
    - Result: All tests pass
    - tests_passing = true

  Step 6: Branch 1 (Success):
    - Save checkpoint(success)
    - debug_iterations_needed = 2
    - EXIT loop → Phase 6 (Documentation)

Outcome: ✓ Success in 2 iterations
```

### Example 3: Three Iteration Escalation

```yaml
# Scenario: Issue proves too complex for automated debugging

Iteration 1:
  debug_topic_slug: "test_timeout"
  Report: debug/test_timeout/001_async_hang.md
  Fix: Added timeout wrapper
  Result: Still hangs (different line)

Iteration 2:
  Report: debug/test_timeout/002_promise_deadlock.md
  Fix: Fixed promise resolution order
  Result: New error - "coroutine error"

Iteration 3:
  debug_iteration: 3
  Report: debug/test_timeout/003_coroutine_state.md
  Fix: Added coroutine state cleanup
  Result: Still failing - "coroutine in wrong state"
  tests_passing = false

Step 6: Branch 2 (Escalation):
  debug_iteration >= 3 AND tests_passing == false
  SAVE checkpoint(escalation)
  PRESENT escalation message with 3 reports
  PAUSE workflow
  WAIT for user decision

Outcome: ⚠️ Escalated to user after 3 iterations
```

## Testing Specifications

### Test Case 1: Single Iteration Success

**Setup**:
- Create implementation that fails tests with simple fixable issue
- Example: Missing import statement

**Expected Behavior**:
1. debug-specialist invoked once
2. Debug report created: `debug/phase1_failures/001_*.md`
3. code-writer applies fix
4. Tests pass after fix
5. Proceeds to documentation phase

**Validation**:
- [ ] `workflow_state.debug_iteration == 1`
- [ ] `workflow_state.debug_reports.length == 1`
- [ ] `workflow_state.debug_history.length == 1`
- [ ] `workflow_state.debug_history[0].result == "Tests passing"`
- [ ] Checkpoint `tests_passing` saved
- [ ] Phase 6 (Documentation) started

### Test Case 2: Two Iteration Success

**Setup**:
- Create implementation with cascading issues
- First fix resolves partial problem, reveals second issue

**Expected Behavior**:
1. Iteration 1: Fixes first issue, tests still fail
2. Iteration 2: Fixes second issue, tests pass
3. Proceeds to documentation phase

**Validation**:
- [ ] `workflow_state.debug_iteration == 2`
- [ ] `workflow_state.debug_reports.length == 2`
- [ ] `workflow_state.debug_history.length == 2`
- [ ] `workflow_state.debug_history[1].result == "Tests passing"`
- [ ] Second debug-specialist invocation received first attempt history
- [ ] Checkpoint `tests_passing` saved

### Test Case 3: Three Iteration Escalation

**Setup**:
- Create implementation with complex issue requiring manual investigation
- Each automated fix attempt fails or introduces new errors

**Expected Behavior**:
1. Iteration 1: Fix attempt, still failing
2. Iteration 2: Second fix attempt, still failing
3. Iteration 3: Third fix attempt, still failing
4. Escalation message presented with all 3 reports
5. Workflow paused

**Validation**:
- [ ] `workflow_state.debug_iteration == 3`
- [ ] `workflow_state.debug_reports.length == 3`
- [ ] `workflow_state.debug_history.length == 3`
- [ ] `workflow_state.debug_status == "escalated"`
- [ ] Checkpoint `escalation` saved
- [ ] Escalation message includes all 3 debug reports
- [ ] User options presented (5 options)
- [ ] Workflow paused (no automatic Phase 6)

### Test Case 4: Iteration Counter Enforcement

**Setup**:
- Mock scenario to verify counter increments correctly
- Verify loop cannot exceed 3 iterations

**Expected Behavior**:
1. Counter starts at 0
2. Increments to 1 after first iteration
3. Increments to 2 after second iteration
4. Increments to 3 after third iteration
5. Branch 2 triggered when `debug_iteration >= 3`
6. No 4th iteration possible

**Validation**:
- [ ] Counter never exceeds 3
- [ ] Escalation always triggers when counter == 3 and tests failing
- [ ] Counter cannot be bypassed or reset mid-loop

### Test Case 5: Debug History Context Passing

**Setup**:
- Verify subsequent iterations receive previous attempt context

**Expected Behavior**:
- Iteration 2 prompt includes Iteration 1 debug history
- Iteration 3 prompt includes Iteration 1 and 2 debug history
- debug-specialist can see what was already tried

**Validation**:
- [ ] Iteration 2 agent prompt contains `[IF debug_iteration > 1:]` section
- [ ] Previous attempt details passed in prompt
- [ ] Agent output references previous attempts

## Error Handling

### Agent Failure Within Loop

**Scenario**: debug-specialist or code-writer agent fails during iteration

**Handling**:
1. **Detect failure**: Agent returns error or times out
2. **Classify error type**:
   - Timeout: Extend timeout and retry (max 2 retries)
   - Tool access: Check permissions, retry with fallback tools
   - Validation failure: Request missing information
3. **Retry strategy**:
   - Same agent, same iteration (don't increment counter)
   - Maximum 2 retries per agent per iteration
   - If both retries fail: Count as iteration failure, add to history
4. **Escalation**:
   - After 2 agent retries, treat as iteration failure
   - Continue to next iteration or escalate if iteration >= 3

### Partial Fix Scenarios

**Scenario**: Fix improves situation but doesn't fully resolve

**Handling**:
1. **Detect progress**:
   - Compare error count: fewer errors than previous iteration
   - Compare error messages: different errors (made progress)
2. **Decision**:
   - If progress detected: Continue debugging (Branch 3)
   - Track progress in debug_history: `progress: true`
3. **Context passing**:
   - Next iteration knows: "previous fix helped, but incomplete"
   - debug-specialist builds on partial success

### Test Infrastructure Failure

**Scenario**: Tests fail to run (not test failure, but infrastructure issue)

**Handling**:
1. **Detect infrastructure failure**:
   - Test command not found
   - Test runner crashes
   - Syntax error in test files (not code under test)
2. **Response**:
   - DO NOT count as iteration
   - DO NOT invoke debug-specialist (not code issue)
   - ESCALATE immediately to user with infrastructure error details
3. **User options**:
   - Fix test infrastructure manually
   - Skip testing phase
   - Terminate workflow

### Loop State Corruption

**Scenario**: Workflow state becomes inconsistent (counter mismatch, missing data)

**Handling**:
1. **Detect corruption**:
   - Counter value impossible (negative, > 3)
   - Missing required fields (debug_reports empty but iteration > 0)
   - History length doesn't match counter
2. **Recovery**:
   - Attempt to reconstruct state from checkpoints
   - If reconstruction fails: ESCALATE to user
3. **Prevention**:
   - Validate state after each iteration
   - Checkpoint frequently
   - Include state validation checklist in Step 7

## Success Criteria

### Functional Requirements

- [ ] Debugging loop only triggers when `tests_passing == false`
- [ ] Loop enforces strict 3-iteration maximum
- [ ] Each iteration invokes debug-specialist and code-writer using Task tool
- [ ] Debug reports created in `debug/{topic}/NNN_*.md` format
- [ ] Iteration counter increments correctly (1 → 2 → 3)
- [ ] Branch 1 (success) proceeds to Phase 6 when tests pass
- [ ] Branch 2 (escalation) triggers when iteration >= 3 and tests failing
- [ ] Branch 3 (continue) returns to Step 2 when iteration < 3 and tests failing
- [ ] Debug history accumulated across iterations
- [ ] Previous attempts passed to subsequent iterations as context

### Non-Functional Requirements

- [ ] All passive voice converted to imperative
- [ ] EXECUTE NOW blocks added for each step
- [ ] Task tool invocations explicit and inline
- [ ] Verification checklists prevent skipping steps
- [ ] Escalation message clear and actionable
- [ ] Code examples demonstrate all 3 scenarios (1 iter, 2 iter, 3 iter)
- [ ] Error handling covers agent failures, partial fixes, infrastructure issues
- [ ] State management robust against corruption

### Integration Requirements

- [ ] Integrates with Phase 4 (Implementation) exit condition
- [ ] Integrates with Phase 6 (Documentation) entry condition
- [ ] Uses shared checkpoint utilities (`.claude/lib/checkpoint-utils.sh`)
- [ ] Uses shared error handling (`.claude/lib/error-utils.sh`)
- [ ] Compatible with existing debug-specialist and code-writer agents

### Testing Requirements

- [ ] Test Case 1: Single iteration success validated
- [ ] Test Case 2: Two iteration success validated
- [ ] Test Case 3: Three iteration escalation validated
- [ ] Test Case 4: Counter enforcement validated
- [ ] Test Case 5: History context passing validated

## Notes

### Why 3 Iterations?

**Rationale**: 3 iterations strikes balance between automation and pragmatism:
- **Iteration 1**: Address obvious issue identified by first diagnosis
- **Iteration 2**: Address cascading issue revealed by first fix
- **Iteration 3**: Attempt alternative approach if first two didn't work
- **Beyond 3**: Diminishing returns - manual investigation more effective

**Evidence**:
- Most test failures resolvable in 1-2 iterations (simple issues)
- Issues requiring >3 iterations typically need human insight
- Prevents runaway loops consuming excessive time/resources

### Escalation Best Practices

**What makes escalation effective**:
1. **Complete context**: All 3 debug reports available for review
2. **Clear history**: User can see what was tried and why it failed
3. **Actionable options**: 5 specific options, not just "figure it out"
4. **Preserved work**: Checkpoints enable resumption after manual fixes
5. **Respectful framing**: "Maximum iterations reached" not "failed"

### Common Debugging Patterns

**Pattern 1: Cascading Dependencies**
- Issue: Fix reveals new issue that was hidden
- Example: Fix import → reveals config issue → reveals test setup issue
- Strategy: Each iteration should make progress even if not fully resolving

**Pattern 2: Wrong Diagnosis**
- Issue: Initial diagnosis incorrect, fix doesn't help
- Example: Thought it was config issue, actually concurrency issue
- Strategy: Iteration 2 should reconsider root cause, not just iterate on wrong path

**Pattern 3: Test Flakiness**
- Issue: Tests pass/fail inconsistently
- Example: Race condition, timing-dependent behavior
- Strategy: Run tests multiple times, report flakiness in escalation

### Integration with Adaptive Planning

**Coordination point**: If debugging loop escalates (Branch 2), this may trigger adaptive replanning:
- Debug failures indicate implementation approach may need revision
- Escalation message could suggest: "Consider revising implementation plan"
- `/revise --auto-mode` could be invoked with debug report context

**Scope boundary**: Debugging loop fixes implementation issues, not plan deficiencies. If fundamental approach is wrong, that's adaptive planning territory.

### Performance Considerations

**Time per iteration**:
- debug-specialist: 1-3 minutes (investigation + report creation)
- code-writer: 1-2 minutes (fix application)
- Test execution: 0.5-5 minutes (project-dependent)
- **Total per iteration**: ~3-10 minutes

**Maximum debugging time**: 3 iterations × 10 minutes = 30 minutes worst case

**Optimization opportunities**:
- Parallel test execution (if tests support it)
- Cached test results (skip passing tests in iteration 2+)
- Incremental debugging (only test affected components)

### Documentation Cross-References

**This phase references**:
- `.claude/agents/debug-specialist.md` (lines 221-405) - Debug report creation
- `.claude/agents/code-writer.md` (lines 268-279) - Fix application
- `.claude/lib/checkpoint-utils.sh` - Checkpoint management
- Phase 4 (Implementation) - Entry condition and state handoff
- Phase 6 (Documentation) - Exit condition on success

**This phase is referenced by**:
- Phase 6 (Documentation) - Debug reports included in workflow summary
- Phase 8 (Integration Testing) - Test Case 3 and 4 validate debugging loop
