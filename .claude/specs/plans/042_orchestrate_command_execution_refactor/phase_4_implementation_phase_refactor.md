# Phase 4: Implementation Phase Refactor

## Metadata
- **Phase Number**: 4
- **Parent Plan**: 042_orchestrate_command_execution_refactor.md
- **Dependencies**: Phase 3 (Planning Phase Refactor)
- **Complexity**: High (8/10)
- **Estimated Hours**: 6-8
- **Status**: PENDING
- **Line Range**: 594-844 in orchestrate.md

## Objective

Transform the Implementation Phase from passive documentation into execution-driven instructions with explicit code-writer agent invocation. This phase is architecturally critical because it introduces **conditional branching logic** based on test results, determining whether the workflow proceeds to documentation (success) or enters the debugging loop (failure).

The refactored phase must:
1. Explicitly invoke the code-writer agent using the Task tool
2. Parse and extract test status from agent output (passing or failing)
3. Implement clear if/else branching based on test results
4. Save appropriate checkpoints for both success and failure paths
5. Prepare context for the next phase (documentation or debugging)

## Context and Background

### Why This Phase is Critical

The Implementation Phase is the **decision point** in the orchestration workflow. Unlike the previous phases (research and planning) that always flow sequentially, this phase must:

1. **Execute complex code generation**: Invoke /implement command which runs multi-phase plan execution
2. **Validate implementation quality**: Extract test results to determine implementation success
3. **Branch workflow execution**: Route to documentation (success) or debugging (failure)
4. **Preserve partial progress**: Save checkpoints that enable resumption from this point

**Architectural Significance**: This is the first phase where workflow routing depends on execution outcomes rather than sequential progression. The branching logic introduced here determines whether the workflow completes successfully or requires debugging intervention.

### Current State Problems

**Lines 594-844 Issues**:
- Uses passive voice: "I'll extract", "For each phase", "I'll monitor"
- No explicit Task tool invocation for code-writer agent
- Test status extraction described but not implemented
- Branching logic documented in YAML but not executable
- Checkpoint creation referenced externally instead of inline
- Extended timeout (600000ms) mentioned but not in executable context

### Transformation Requirements

**From Documentation**:
```markdown
#### Step 3: Invoke Implementation Agent

**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Execute implementation plan..."
```
```

**To Execution**:
```markdown
#### Step 3: Invoke Implementation Agent

**EXECUTE NOW: Invoke Code-Writer Agent**

USE the Task tool to invoke the code-writer agent NOW:

Task tool invocation:
- subagent_type: general-purpose
- description: "Execute implementation plan [plan_number] using code-writer protocol"
- timeout: 600000
- prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/code-writer.md

    [Complete inline prompt with all context]

After invoking, WAIT for agent completion.
```

## Detailed Implementation Steps

### Step 1: Prepare Implementation Context

**Current Location**: Lines 594-606

**Objective**: Extract plan path and metadata from planning phase output to prepare for implementation agent invocation.

**Refactor Instructions**:

1. **Change heading to imperative**: "Step 1: Prepare Implementation Context" → "Step 1: Extract Implementation Context"

2. **Convert passive YAML to active instructions**:

**BEFORE**:
```yaml
implementation_context:
  plan_path: "specs/plans/NNN_feature_name.md"
  plan_number: NNN
  phase_count: N
  complexity: "Low|Medium|High"
```

**AFTER**:
```markdown
**EXECUTE NOW: Extract Context from Planning Phase**

From the planning phase checkpoint (saved in Step 5 of Planning Phase), EXTRACT:

1. **Plan File Path**:
   - Variable: plan_path
   - Example: "specs/plans/042_user_authentication.md"
   - Source: planning_phase_checkpoint.outputs.plan_path

2. **Plan Metadata**:
   - Plan number: Extract from filename (NNN prefix)
   - Phase count: Read from plan file metadata
   - Complexity level: Read from plan metadata or estimate

3. **Store in workflow_state**:
   ```yaml
   workflow_state.implementation_context:
     plan_path: "[extracted_path]"
     plan_number: "[NNN]"
     phase_count: "[N]"
     complexity: "[Low|Medium|High]"
   ```

**Context Extraction Commands**:
```bash
# Extract plan path from checkpoint
PLAN_PATH=$(jq -r '.outputs.plan_path' < checkpoint_plan_ready.json)

# Extract plan number from filename
PLAN_NUMBER=$(basename "$PLAN_PATH" | grep -oP '^\d+')

# Read phase count from plan file
PHASE_COUNT=$(grep -c "^### Phase" "$PLAN_PATH")

# Read complexity from metadata
COMPLEXITY=$(grep "^- \*\*Complexity\*\*:" "$PLAN_PATH" | cut -d: -f2 | tr -d ' ')
```

**Verification Checklist**:
- [ ] Plan path extracted and validated (file exists)
- [ ] Plan number parsed correctly (3-digit format)
- [ ] Phase count matches plan structure
- [ ] Complexity level identified or defaulted
```

3. **Remove execution strategy section** (Lines 607-619): This is implementation detail that should be handled by code-writer agent, not orchestrator

4. **Add validation step**:
```markdown
**Validation**:
- Verify plan file exists: Use Read tool to check plan_path
- Verify plan is complete: Check for all required sections (phases, tasks, testing)
- If validation fails: Report error and halt workflow
```

### Step 2: Generate Implementation Agent Prompt

**Current Location**: Lines 621-711

**Objective**: Create complete, self-contained prompt for code-writer agent that includes all context and instructions.

**Refactor Instructions**:

1. **Replace entire section** (Lines 621-711) with imperative prompt generation:

```markdown
### Step 2: Build Implementation Agent Prompt

**EXECUTE NOW: Construct Code-Writer Prompt**

BUILD the complete prompt for the code-writer agent using this template:

**Prompt Template** (use verbatim, substituting bracketed variables):

```
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/code-writer.md

You are acting as a Code Writer Agent with the tools and constraints
defined in that file.

# Implementation Task: Execute Implementation Plan

## Context

### Implementation Plan
Plan file: [plan_path]
Plan number: [plan_number]
Total phases: [phase_count]
Complexity: [complexity]

Read the complete plan to understand:
- All implementation phases
- Specific tasks for each phase
- Testing requirements per phase
- Success criteria

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

Apply these standards during code generation:
- Indentation: 2 spaces, expandtab
- Naming: snake_case for variables/functions
- Error handling: Use pcall for Lua, try-catch for others
- Line length: ~100 characters soft limit
- Documentation: Comment non-obvious logic

## Objective

Execute the implementation plan phase by phase using the /implement command.

## Requirements

### Execution Approach

Use the /implement command to execute the plan:

```bash
/implement [plan_path]
```

The /implement command will:
- Parse plan and identify all phases with dependencies
- Execute phases in dependency order (parallel where possible)
- Run tests after each phase
- Create git commit for each completed phase
- Handle errors with automatic retry (max 3 attempts)
- Update plan with completion markers

### Phase-by-Phase Execution

For each phase, /implement will:
1. Display phase name and tasks
2. Implement all tasks in phase following project standards
3. Run phase-specific tests
4. Validate all tests pass
5. Create structured git commit
6. Save checkpoint before next phase

### Testing Requirements

**CRITICAL**: Tests must run after EACH phase, not just at the end.

- Run tests after completing each phase
- Tests must pass before proceeding to next phase
- If tests fail: STOP and report (do not continue to next phase)
- Test commands: Use commands specified in plan or project CLAUDE.md

### Error Handling

- Automatic retry for transient errors (max 3 attempts per operation)
- If tests fail: DO NOT proceed to next phase
- Report test failures with detailed error messages and file locations
- Preserve all completed work even if later phase fails
- Save checkpoint at failure point for debugging

## Expected Output

**SUCCESS CASE** - All Phases Complete:
```
TESTS_PASSING: true
PHASES_COMPLETED: [N]/[N]
FILES_MODIFIED: [file1.ext, file2.ext, ...]
GIT_COMMITS: [hash1, hash2, ...]
IMPLEMENTATION_STATUS: success
```

**FAILURE CASE** - Tests Failed:
```
TESTS_PASSING: false
PHASES_COMPLETED: [M]/[N]
FAILED_PHASE: [N]
ERROR_MESSAGE: [Test failure details with file locations]
FILES_MODIFIED: [files changed before failure]
IMPLEMENTATION_STATUS: failed
```

## Output Format Requirements

**REQUIRED**: Structure your final output to include these exact markers so the orchestrator can parse results:

1. Test status line: `TESTS_PASSING: true` or `TESTS_PASSING: false`
2. Phases completed line: `PHASES_COMPLETED: M/N`
3. If failed, include: `FAILED_PHASE: N` and `ERROR_MESSAGE: [details]`
4. File changes line: `FILES_MODIFIED: [array of file paths]`
5. Git commits line: `GIT_COMMITS: [array of commit hashes]`

## Success Criteria

- All plan phases executed successfully (N/N)
- All tests passing after final phase
- Code follows project standards (verified before each commit)
- Git commits created for each phase with structured messages
- No merge conflicts or build errors
- Implementation status clearly indicated

## Error Handling

- **Timeout errors**: Retry with extended timeout (up to 600000ms)
- **Test failures**: STOP immediately, report phase and error details
- **Tool access errors**: Retry with available tools (Read/Write/Edit fallback)
- **Persistent errors**: Report for debugging (do not skip or ignore)
```

**Variable Substitution**:
Replace these variables from workflow_state:
- [plan_path]: workflow_state.implementation_context.plan_path
- [plan_number]: workflow_state.implementation_context.plan_number
- [phase_count]: workflow_state.implementation_context.phase_count
- [complexity]: workflow_state.implementation_context.complexity

**Store Prompt**:
```yaml
workflow_state.implementation_prompt: "[generated_prompt]"
```
```

2. **Remove old prompt section entirely** - no external references, everything inline

### Step 3: Invoke Implementation Agent

**Current Location**: Lines 713-736

**Objective**: Execute Task tool invocation with extended timeout and proper behavioral injection.

**Refactor Instructions**:

Replace lines 713-736 with:

```markdown
### Step 3: Invoke Code-Writer Agent for Implementation

**EXECUTE NOW: USE Task Tool to Invoke Code-Writer Agent**

Invoke the code-writer agent NOW using the Task tool with these exact parameters:

**Task Tool Invocation** (execute this call):

```json
{
  "subagent_type": "general-purpose",
  "description": "Execute implementation plan [plan_number] using code-writer protocol",
  "timeout": 600000,
  "prompt": "[workflow_state.implementation_prompt from Step 2]"
}
```

**Timeout Justification**: 600000ms (10 minutes) allows for:
- Multi-phase implementation (4-8 phases typical)
- Test execution after each phase
- Git commit creation per phase
- Automatic error retry (up to 3 attempts)
- Complex implementations with many files

**Invocation Instructions**:
1. USE the Task tool (not SlashCommand or Bash)
2. SET subagent_type to "general-purpose"
3. SET timeout to 600000 (not default 120000)
4. PASS complete prompt from Step 2 verbatim
5. WAIT for agent completion (do not proceed to Step 4 until done)

**While Waiting for Agent**:

Monitor agent output for PROGRESS markers:
- `PROGRESS: Implementing Phase N: [phase name]...`
- `PROGRESS: Running tests for Phase N...`
- `PROGRESS: Creating git commit for Phase N...`
- `PROGRESS: All tests passing, proceeding to Phase N+1...`

Display progress updates to user in real-time for transparency.

**After Agent Completes**:
Store complete agent output for parsing in Step 4:
```yaml
workflow_state.implementation_output: "[agent_output]"
```

**Verification Checklist**:
- [ ] Task tool invoked (not just described)
- [ ] Timeout set to 600000ms (extended for complex implementations)
- [ ] Agent type set to "general-purpose"
- [ ] Complete prompt passed to agent
- [ ] Agent output captured for status extraction
```

### Step 4: Extract Implementation Status and Test Results

**Current Location**: Lines 738-764

**Objective**: Parse agent output to determine if implementation succeeded (all tests passing) or failed (tests failed).

**Refactor Instructions**:

Replace lines 738-764 with:

```markdown
### Step 4: Parse Implementation Results and Test Status

**EXECUTE NOW: Extract Status from Agent Output**

PARSE the agent output (workflow_state.implementation_output) to extract implementation results.

**Status Extraction Algorithm**:

```python
# Pseudo-code for status extraction

# 1. Extract test status
if "TESTS_PASSING: true" in agent_output:
    tests_passing = True
elif "TESTS_PASSING: false" in agent_output:
    tests_passing = False
else:
    # Fallback: search for test result indicators
    if "all tests pass" in agent_output.lower() or "✓ all passing" in agent_output.lower():
        tests_passing = True
    else:
        tests_passing = False

# 2. Extract phases completed
match = re.search(r'PHASES_COMPLETED: (\d+)/(\d+)', agent_output)
if match:
    completed = int(match.group(1))
    total = int(match.group(2))
else:
    # Fallback: count completed phase markers
    completed = agent_output.count('[COMPLETED]')
    total = workflow_state.implementation_context.phase_count

# 3. Extract file changes
match = re.search(r'FILES_MODIFIED: \[(.*?)\]', agent_output)
if match:
    files_modified = match.group(1).split(', ')
else:
    # Fallback: empty list
    files_modified = []

# 4. Extract git commits
match = re.search(r'GIT_COMMITS: \[(.*?)\]', agent_output)
if match:
    git_commits = match.group(1).split(', ')
else:
    git_commits = []

# 5. If tests failed, extract failure details
if not tests_passing:
    match = re.search(r'FAILED_PHASE: (\d+)', agent_output)
    failed_phase = int(match.group(1)) if match else None

    match = re.search(r'ERROR_MESSAGE: (.*?)(?:\n|$)', agent_output)
    error_message = match.group(1) if match else "Unknown error"
```

**Concrete Extraction Commands**:

```bash
# Extract test status
TESTS_PASSING=$(echo "$AGENT_OUTPUT" | grep -oP 'TESTS_PASSING: \K(true|false)' || echo "false")

# Extract phases completed
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep -oP 'PHASES_COMPLETED: \K\d+/\d+' || echo "0/0")

# Extract modified files
FILES_MODIFIED=$(echo "$AGENT_OUTPUT" | grep -oP 'FILES_MODIFIED: \[\K[^\]]+' || echo "")

# Extract git commits
GIT_COMMITS=$(echo "$AGENT_OUTPUT" | grep -oP 'GIT_COMMITS: \[\K[^\]]+' || echo "")

# If tests failed, extract failure details
if [ "$TESTS_PASSING" = "false" ]; then
    FAILED_PHASE=$(echo "$AGENT_OUTPUT" | grep -oP 'FAILED_PHASE: \K\d+' || echo "unknown")
    ERROR_MESSAGE=$(echo "$AGENT_OUTPUT" | grep -oP 'ERROR_MESSAGE: \K.*' || echo "Unknown error")
fi
```

**Store Results in Workflow State**:

```yaml
workflow_state.implementation_status:
  tests_passing: [true|false]
  phases_completed: "[M]/[N]"
  files_modified: [array]
  git_commits: [array]
  status: "success|failed"

# If failed:
workflow_state.implementation_failure:
  failed_phase: [N]
  error_message: "[details]"
  partial_completion: true
```

**Validation Checklist**:
- [ ] Test status clearly extracted (true or false, not ambiguous)
- [ ] Phase completion count matches plan structure
- [ ] If tests passing: files_modified and git_commits present
- [ ] If tests failing: failed_phase and error_message present
- [ ] Status stored for use in Step 5 conditional branching

**Error Handling**:
If status extraction fails (cannot determine test status):
- Log warning: "Could not parse implementation status from agent output"
- Default to: tests_passing = false (safe default, triggers debugging)
- Continue to Step 5 with failure status
```

### Step 5: Conditional Branch - Route Based on Test Status

**Current Location**: Lines 766-779

**Objective**: Implement explicit if/else branching logic to route workflow based on test results.

**Refactor Instructions**:

Replace lines 766-779 with:

```markdown
### Step 5: Evaluate Test Status and Determine Next Phase

**EXECUTE NOW: Branch Workflow Based on Test Results**

EVALUATE the test status extracted in Step 4 and ROUTE the workflow accordingly.

**Branching Decision Tree**:

```
READ workflow_state.implementation_status.tests_passing

IF tests_passing == true:
    ├─→ ROUTE: Documentation Phase (Phase 6)
    ├─→ CHECKPOINT: implementation_complete
    ├─→ STATUS: Implementation successful, all tests passing
    └─→ PROCEED to Step 6 (Save Success Checkpoint)

ELSE (tests_passing == false):
    ├─→ ROUTE: Debugging Loop (Phase 5)
    ├─→ CHECKPOINT: implementation_incomplete
    ├─→ STATUS: Implementation failed, debugging required
    ├─→ PREPARE: Debug context with error details
    └─→ PROCEED to Step 6 (Save Failure Checkpoint)
```

**Decision Implementation**:

```python
# Execute this branching logic

if workflow_state.implementation_status.tests_passing == True:
    # SUCCESS PATH
    next_phase = "documentation"
    checkpoint_type = "implementation_complete"
    workflow_status = "Tests passing, implementation successful"

    # Prepare documentation context
    documentation_context = {
        "plan_path": workflow_state.implementation_context.plan_path,
        "files_modified": workflow_state.implementation_status.files_modified,
        "git_commits": workflow_state.implementation_status.git_commits,
        "test_status": "all passing"
    }

else:
    # FAILURE PATH
    next_phase = "debugging"
    checkpoint_type = "implementation_incomplete"
    workflow_status = "Tests failing, debugging required"

    # Prepare debugging context
    debug_context = {
        "plan_path": workflow_state.implementation_context.plan_path,
        "failed_phase": workflow_state.implementation_failure.failed_phase,
        "error_message": workflow_state.implementation_failure.error_message,
        "files_modified": workflow_state.implementation_status.files_modified,
        "phases_completed": workflow_state.implementation_status.phases_completed
    }
```

**Context Preparation**:

**FOR SUCCESS PATH** (tests passing):
```yaml
workflow_state.next_phase: "documentation"
workflow_state.documentation_context:
  plan_path: "[path]"
  implementation_complete: true
  files_modified: [array]
  git_commits: [array]
  test_results: "all passing"
```

**FOR FAILURE PATH** (tests failing):
```yaml
workflow_state.next_phase: "debugging"
workflow_state.debug_context:
  plan_path: "[path]"
  failed_phase: [N]
  error_message: "[details]"
  files_modified: [array]
  phases_completed: "[M]/[N]"
  iteration: 0
```

**Store Branch Decision**:
```yaml
workflow_state.implementation_branch:
  decision: "success|failure"
  next_phase: "documentation|debugging"
  timestamp: "[ISO 8601 timestamp]"
  reason: "[Test status explanation]"
```

**Verification Checklist**:
- [ ] Test status evaluated (not skipped)
- [ ] Branch decision made (success or failure path chosen)
- [ ] Context prepared for next phase
- [ ] Workflow state updated with next_phase
- [ ] If failure: debug_context includes all error details
```

### Step 6: Save Implementation Checkpoint

**Current Location**: Lines 781-816

**Objective**: Save checkpoint for both success and failure paths to enable resumption and provide audit trail.

**Refactor Instructions**:

Replace lines 781-816 with:

```markdown
### Step 6: Save Checkpoint for Implementation Phase

**EXECUTE NOW: Save Checkpoint Based on Branch Decision**

SAVE checkpoint using checkpoint-utils.sh based on the branch decision from Step 5.

**Checkpoint Creation**:

**IF SUCCESS PATH** (tests passing):

```bash
# Create success checkpoint
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outputs": {
    "tests_passing": true,
    "phases_completed": "${PHASES_COMPLETED}",
    "files_modified": [${FILES_MODIFIED}],
    "git_commits": [${GIT_COMMITS}],
    "status": "success"
  },
  "next_phase": "documentation",
  "branch_decision": "success",
  "performance": {
    "implementation_time": "${DURATION_SECONDS}s",
    "phases_executed": ${PHASE_COUNT}
  },
  "context_for_next_phase": {
    "plan_path": "${PLAN_PATH}",
    "files_modified": [${FILES_MODIFIED}],
    "git_commits": [${GIT_COMMITS}]
  }
}
EOF
)

# Save checkpoint
.claude/lib/save-checkpoint.sh orchestrate "implementation_complete" "$CHECKPOINT_DATA"
```

**IF FAILURE PATH** (tests failing):

```bash
# Create failure checkpoint
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "outputs": {
    "tests_passing": false,
    "phases_completed": "${PHASES_COMPLETED}",
    "failed_phase": ${FAILED_PHASE},
    "error_message": "${ERROR_MESSAGE}",
    "files_modified": [${FILES_MODIFIED}],
    "status": "failed"
  },
  "next_phase": "debugging",
  "branch_decision": "failure",
  "debug_context": {
    "plan_path": "${PLAN_PATH}",
    "failed_phase": ${FAILED_PHASE},
    "error_message": "${ERROR_MESSAGE}",
    "files_modified": [${FILES_MODIFIED}],
    "phases_completed": "${PHASES_COMPLETED}",
    "iteration": 0
  }
}
EOF
)

# Save checkpoint
.claude/lib/save-checkpoint.sh orchestrate "implementation_incomplete" "$CHECKPOINT_DATA"
```

**Checkpoint File Locations**:
- Success: `.claude/data/checkpoints/orchestrate_implementation_complete_[timestamp].json`
- Failure: `.claude/data/checkpoints/orchestrate_implementation_incomplete_[timestamp].json`

**Verification Checklist**:
- [ ] Checkpoint file created in .claude/data/checkpoints/
- [ ] Checkpoint contains all required fields (outputs, next_phase, context)
- [ ] If success: includes files_modified and git_commits
- [ ] If failure: includes failed_phase and error_message
- [ ] Checkpoint enables workflow resumption from this point
```

### Step 7: Display Implementation Phase Completion Message

**Current Location**: Lines 818-844

**Objective**: Provide clear user feedback based on success or failure path.

**Refactor Instructions**:

Replace lines 818-844 with:

```markdown
### Step 7: Output Implementation Phase Status

**EXECUTE NOW: Display Status Message to User**

DISPLAY appropriate completion message based on branch decision from Step 5.

**IF SUCCESS PATH** (tests passing):

```markdown
OUTPUT to user:

✓ Implementation Phase Complete

**Summary**:
- All phases executed: [N]/[N]
- Tests passing: ✓
- Files modified: [M] files
- Git commits: [N] commits

**Modified Files**:
[List each file from workflow_state.implementation_status.files_modified]

**Git Commits**:
[List each commit hash from workflow_state.implementation_status.git_commits]

**Next Phase**: Documentation (Phase 6)

The implementation succeeded. Proceeding to documentation phase to update
project documentation and generate workflow summary.
```

**IF FAILURE PATH** (tests failing):

```markdown
OUTPUT to user:

⚠ Implementation Phase Incomplete

**Summary**:
- Phases completed: [M]/[N]
- Failed at: Phase [N]
- Tests passing: ✗

**Failure Details**:
Phase [N] failed with error:
[error_message from workflow_state.implementation_failure.error_message]

**Partial Progress**:
Files modified before failure:
[List each file from workflow_state.implementation_status.files_modified]

**Next Phase**: Debugging Loop (Phase 5)

The implementation encountered test failures. Entering debugging loop to
investigate and fix issues. Maximum 3 debugging iterations before escalation.
```

**Implementation Instructions**:

```python
# Display message based on branch decision

if workflow_state.implementation_branch.decision == "success":
    print(f"""
✓ Implementation Phase Complete

**Summary**:
- All phases executed: {workflow_state.implementation_status.phases_completed}
- Tests passing: ✓
- Files modified: {len(workflow_state.implementation_status.files_modified)} files
- Git commits: {len(workflow_state.implementation_status.git_commits)} commits

**Modified Files**:
{format_file_list(workflow_state.implementation_status.files_modified)}

**Git Commits**:
{format_commit_list(workflow_state.implementation_status.git_commits)}

**Next Phase**: Documentation (Phase 6)
    """)

else:  # failure path
    print(f"""
⚠ Implementation Phase Incomplete

**Summary**:
- Phases completed: {workflow_state.implementation_status.phases_completed}
- Failed at: Phase {workflow_state.implementation_failure.failed_phase}
- Tests passing: ✗

**Failure Details**:
Phase {workflow_state.implementation_failure.failed_phase} failed with error:
{workflow_state.implementation_failure.error_message}

**Partial Progress**:
Files modified before failure:
{format_file_list(workflow_state.implementation_status.files_modified)}

**Next Phase**: Debugging Loop (Phase 5)
    """)
```

**Verification Checklist**:
- [ ] Appropriate message displayed (success or failure)
- [ ] Message includes all relevant details (files, commits, errors)
- [ ] Next phase clearly indicated
- [ ] User understands what happened and what comes next
```

## Critical Decision Points

### Test Status Detection is Mandatory

**Why This Matters**: The entire workflow depends on accurately detecting whether implementation tests passed or failed. Incorrect detection leads to:
- **False Success**: Proceeding to documentation when tests actually failed (bugs ship to production)
- **False Failure**: Entering debugging loop when tests actually passed (wasted time, unnecessary iterations)

**Detection Strategy**:

1. **Primary Detection**: Explicit markers in agent output
   - `TESTS_PASSING: true` or `TESTS_PASSING: false`
   - Required in code-writer agent output format specification

2. **Fallback Detection**: Pattern matching in output text
   - Search for "all tests pass", "✓ passing", "tests successful"
   - Search for "test failed", "✗ failed", "error in test"

3. **Default Behavior**: If detection fails, assume failure
   - Reason: Safe default - better to debug unnecessarily than skip debugging
   - User can manually override if needed

**Validation**: After extraction, verify test status is unambiguous (true/false, not null/undefined)

### Conditional Branching Must Be Explicit

**Why This Matters**: This is the first workflow phase with non-sequential flow. The branching logic must be:
- **Explicit**: Clear if/else structure, not implicit routing
- **Auditable**: Branch decision logged in checkpoint
- **Reversible**: User can resume from either path

**Branching Implementation**:

```python
# CORRECT: Explicit branching with clear conditions
if tests_passing == True:
    route_to_documentation()
elif tests_passing == False:
    route_to_debugging()
else:
    # Ambiguous status - default to debugging
    route_to_debugging()
    log_warning("Test status ambiguous, defaulting to debugging")
```

**Not This**:
```python
# INCORRECT: Implicit routing based on variable presence
if error_message:
    route_to_debugging()
# What if error_message is set but tests passed? Bad routing!
```

### Extended Timeout Must Be Specified

**Why This Matters**: Implementation can take 5-10 minutes for complex plans with multiple phases. Default timeout (120000ms = 2 minutes) will cause premature timeout and workflow failure.

**Timeout Calculation**:
```
Typical implementation:
- 4-8 phases @ 30-90 seconds each = 120-720 seconds
- Tests @ 10-60 seconds per phase = 40-480 seconds
- Git commits @ 5-10 seconds each = 20-80 seconds
- Error retry buffer = 60-120 seconds
Total: 240-1400 seconds = 4-23 minutes

Timeout: 600000ms (10 minutes) provides safety margin
```

**Specification Location**: Must be in Task tool invocation parameters, not just documentation.

## Code Examples

### Example 1: Complete Task Tool Invocation

```json
{
  "subagent_type": "general-purpose",
  "description": "Execute implementation plan 042 using code-writer protocol",
  "timeout": 600000,
  "prompt": "Read and follow the behavioral guidelines from:\n/home/benjamin/.config/.claude/agents/code-writer.md\n\nYou are acting as a Code Writer Agent with the tools and constraints\ndefined in that file.\n\n# Implementation Task: Execute Implementation Plan\n\n## Context\n\n### Implementation Plan\nPlan file: specs/plans/042_orchestrate_command_execution_refactor.md\nPlan number: 042\nTotal phases: 8\nComplexity: High\n\nRead the complete plan to understand:\n- All implementation phases\n- Specific tasks for each phase\n- Testing requirements per phase\n- Success criteria\n\n### Project Standards\nReference standards at: /home/benjamin/.config/CLAUDE.md\n\nApply these standards during code generation:\n- Indentation: 2 spaces, expandtab\n- Naming: snake_case for variables/functions\n- Error handling: Use pcall for Lua, try-catch for others\n- Line length: ~100 characters soft limit\n- Documentation: Comment non-obvious logic\n\n## Objective\n\nExecute the implementation plan phase by phase using the /implement command.\n\n## Requirements\n\n### Execution Approach\n\nUse the /implement command to execute the plan:\n\n```bash\n/implement specs/plans/042_orchestrate_command_execution_refactor.md\n```\n\n[... rest of prompt template ...]\n\n## Expected Output\n\n**SUCCESS CASE** - All Phases Complete:\n```\nTESTS_PASSING: true\nPHASES_COMPLETED: 8/8\nFILES_MODIFIED: [orchestrate.md, test_orchestrate.sh]\nGIT_COMMITS: [abc123, def456, ghi789]\nIMPLEMENTATION_STATUS: success\n```\n\n**FAILURE CASE** - Tests Failed:\n```\nTESTS_PASSING: false\nPHASES_COMPLETED: 3/8\nFAILED_PHASE: 4\nERROR_MESSAGE: Test orchestrate_research_phase failed: Agent not invoked\nFILES_MODIFIED: [orchestrate.md]\nIMPLEMENTATION_STATUS: failed\n```\n"
}
```

### Example 2: Test Result Parsing

```bash
# Example agent output
AGENT_OUTPUT='
Implementation complete for Phase 1-3 of 8.

Phase 1: Research Phase Refactor - COMPLETED
Phase 2: Planning Phase Refactor - COMPLETED
Phase 3: Implementation Phase Refactor - FAILED

Test results for Phase 3:
Running tests/test_implementation_phase.sh...
FAIL: test_agent_invocation - Task tool not invoked
FAIL: test_status_extraction - No test status markers found

TESTS_PASSING: false
PHASES_COMPLETED: 2/8
FAILED_PHASE: 3
ERROR_MESSAGE: Phase 3 tests failed - Task tool not invoked in implementation step
FILES_MODIFIED: [.claude/commands/orchestrate.md]
GIT_COMMITS: []
IMPLEMENTATION_STATUS: failed
'

# Extraction commands
TESTS_PASSING=$(echo "$AGENT_OUTPUT" | grep -oP 'TESTS_PASSING: \K(true|false)')
# Result: "false"

PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep -oP 'PHASES_COMPLETED: \K\d+/\d+')
# Result: "2/8"

FAILED_PHASE=$(echo "$AGENT_OUTPUT" | grep -oP 'FAILED_PHASE: \K\d+')
# Result: "3"

ERROR_MESSAGE=$(echo "$AGENT_OUTPUT" | grep -oP 'ERROR_MESSAGE: \K.*')
# Result: "Phase 3 tests failed - Task tool not invoked in implementation step"

# Branch decision
if [ "$TESTS_PASSING" = "true" ]; then
    NEXT_PHASE="documentation"
else
    NEXT_PHASE="debugging"
fi
# Result: NEXT_PHASE="debugging"
```

### Example 3: Checkpoint Creation (Success)

```json
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "2025-10-12T14:32:18Z",
  "outputs": {
    "tests_passing": true,
    "phases_completed": "8/8",
    "files_modified": [
      ".claude/commands/orchestrate.md",
      ".claude/tests/test_orchestrate_refactor.sh",
      ".claude/docs/orchestrate-refactor-notes.md"
    ],
    "git_commits": [
      "a1b2c3d4",
      "e5f6g7h8",
      "i9j0k1l2"
    ],
    "status": "success"
  },
  "next_phase": "documentation",
  "branch_decision": "success",
  "performance": {
    "implementation_time": "487s",
    "phases_executed": 8
  },
  "context_for_next_phase": {
    "plan_path": "specs/plans/042_orchestrate_command_execution_refactor.md",
    "files_modified": [
      ".claude/commands/orchestrate.md",
      ".claude/tests/test_orchestrate_refactor.sh",
      ".claude/docs/orchestrate-refactor-notes.md"
    ],
    "git_commits": [
      "a1b2c3d4",
      "e5f6g7h8",
      "i9j0k1l2"
    ]
  }
}
```

### Example 4: Checkpoint Creation (Failure)

```json
{
  "workflow": "orchestrate",
  "phase_name": "implementation",
  "completion_time": "2025-10-12T14:18:42Z",
  "outputs": {
    "tests_passing": false,
    "phases_completed": "3/8",
    "failed_phase": 4,
    "error_message": "Phase 4 tests failed: Task tool invocation not found in Step 3",
    "files_modified": [
      ".claude/commands/orchestrate.md"
    ],
    "status": "failed"
  },
  "next_phase": "debugging",
  "branch_decision": "failure",
  "debug_context": {
    "plan_path": "specs/plans/042_orchestrate_command_execution_refactor.md",
    "failed_phase": 4,
    "error_message": "Phase 4 tests failed: Task tool invocation not found in Step 3",
    "files_modified": [
      ".claude/commands/orchestrate.md"
    ],
    "phases_completed": "3/8",
    "iteration": 0
  }
}
```

## Testing Specifications

### Test Case 1: Successful Implementation (All Tests Pass)

**Setup**:
- Use simple test plan: "Add hello world function"
- Plan has 2 phases, minimal complexity
- All tests expected to pass

**Execution**:
1. Run orchestrate command through Planning Phase (Phase 3)
2. Enter Implementation Phase (Phase 4)
3. Verify Task tool invoked for code-writer
4. Monitor agent execution
5. Capture agent output
6. Parse test status

**Expected Results**:
- `TESTS_PASSING: true`
- `PHASES_COMPLETED: 2/2`
- Branch decision: "success"
- Next phase: "documentation"
- Checkpoint saved: implementation_complete

**Verification Commands**:
```bash
# Verify Task tool was invoked
grep -q "Task tool invocation" implementation_phase.log

# Verify test status extracted correctly
grep -q "TESTS_PASSING: true" parsed_status.txt

# Verify checkpoint created
ls .claude/data/checkpoints/orchestrate_implementation_complete_*.json

# Verify workflow routes to documentation
grep -q '"next_phase": "documentation"' checkpoint.json
```

### Test Case 2: Failed Implementation (Tests Fail)

**Setup**:
- Use test plan with intentional error: "Add function with syntax error"
- Plan has 3 phases, moderate complexity
- Phase 2 expected to fail tests

**Execution**:
1. Run orchestrate command through Planning Phase
2. Enter Implementation Phase
3. Verify Task tool invoked for code-writer
4. Monitor agent execution (should fail at Phase 2)
5. Capture agent output with error
6. Parse test status

**Expected Results**:
- `TESTS_PASSING: false`
- `PHASES_COMPLETED: 1/3`
- `FAILED_PHASE: 2`
- `ERROR_MESSAGE: [specific error details]`
- Branch decision: "failure"
- Next phase: "debugging"
- Checkpoint saved: implementation_incomplete

**Verification Commands**:
```bash
# Verify test status extracted correctly
grep -q "TESTS_PASSING: false" parsed_status.txt

# Verify failed phase identified
grep -q "FAILED_PHASE: 2" parsed_status.txt

# Verify error message captured
grep -q "ERROR_MESSAGE:" parsed_status.txt

# Verify checkpoint created with debug context
jq '.debug_context.failed_phase' checkpoint.json | grep -q "2"

# Verify workflow routes to debugging
grep -q '"next_phase": "debugging"' checkpoint.json
```

### Test Case 3: Timeout Handling

**Setup**:
- Use complex test plan: "Refactor large module with 10 phases"
- Set artificially short timeout (60000ms) to force timeout
- Expect timeout error, not completion

**Execution**:
1. Run orchestrate command through Planning Phase
2. Enter Implementation Phase with short timeout
3. Verify Task tool invoked with wrong timeout
4. Wait for timeout error
5. Verify error handling

**Expected Results**:
- Timeout error caught
- Error message: "Agent timeout exceeded 60000ms"
- Workflow escalates to user for manual intervention
- Checkpoint saved with timeout error details

**Verification Commands**:
```bash
# Verify timeout occurred
grep -q "timeout" error.log

# Verify error escalation
grep -q "Manual intervention required" output.txt

# Verify checkpoint includes error details
jq '.error_details.type' checkpoint.json | grep -q "timeout"
```

### Test Case 4: Status Extraction Edge Cases

**Setup**:
- Mock agent output with ambiguous test status (no markers)
- Force fallback detection logic

**Test Scenarios**:
1. **No markers**: No "TESTS_PASSING:" in output
   - Expected: Parse output text for success indicators
   - Default: false if ambiguous

2. **Conflicting markers**: Both "tests pass" and "tests fail" in output
   - Expected: Use explicit marker over text search
   - Fallback: Most recent marker wins

3. **Malformed output**: Invalid JSON or missing sections
   - Expected: Graceful degradation with partial data
   - Default: tests_passing = false (safe default)

**Verification**:
```bash
# Test no markers
echo "$OUTPUT_NO_MARKERS" | ./extract_status.sh
# Verify: tests_passing=false (default)

# Test conflicting markers
echo "$OUTPUT_CONFLICTING" | ./extract_status.sh
# Verify: uses explicit marker

# Test malformed output
echo "$OUTPUT_MALFORMED" | ./extract_status.sh
# Verify: doesn't crash, returns safe defaults
```

## Error Handling

### Error Type 1: Task Tool Invocation Failure

**Scenario**: Task tool call fails (network error, tool unavailable, syntax error)

**Detection**: Exception or error return from Task tool call

**Handling**:
1. Log error details: `"Task tool invocation failed: [error message]"`
2. Retry with exponential backoff (1s, 2s, 4s delays)
3. Max 3 retry attempts
4. If all retries fail: Escalate to user with manual invocation option

**User Message**:
```
❌ Implementation Phase Error

Task tool invocation failed after 3 attempts:
[error message]

Manual intervention required. Options:
1. Fix error and retry implementation phase
2. Skip implementation and proceed to manual coding
3. Terminate workflow

Checkpoint saved at: .claude/data/checkpoints/orchestrate_implementation_error_[timestamp].json
```

### Error Type 2: Agent Timeout

**Scenario**: Code-writer agent exceeds 600000ms timeout

**Detection**: Task tool returns timeout error

**Handling**:
1. Log timeout: `"Agent timeout after 600000ms"`
2. Check for partial progress in agent output
3. Determine how many phases completed before timeout
4. Save checkpoint with partial progress
5. Offer user options: extend timeout and retry, or continue manually

**User Message**:
```
⏱ Implementation Phase Timeout

Code-writer agent exceeded 10-minute timeout.

Partial progress:
- Phases completed: [M]/[N]
- Last successful phase: Phase [M]
- Files modified: [list]

Options:
1. Retry with extended timeout (20 minutes)
2. Resume implementation from Phase [M+1] manually
3. Review progress and decide next steps

Checkpoint saved with partial progress.
```

### Error Type 3: Status Extraction Failure

**Scenario**: Cannot parse test status from agent output

**Detection**: Extraction commands return empty or ambiguous results

**Handling**:
1. Log warning: `"Could not parse test status from agent output"`
2. Log raw output for debugging
3. Apply safe default: tests_passing = false
4. Display agent output to user for manual verification
5. Route to debugging phase (safe path)

**User Message**:
```
⚠ Status Extraction Warning

Could not reliably determine test status from implementation output.

Defaulting to: tests_passing = false (safe default)

Agent output review:
[Display last 50 lines of agent output]

Proceeding to debugging phase. If tests actually passed, you can
manually skip debugging and proceed to documentation.
```

### Error Type 4: Checkpoint Save Failure

**Scenario**: Checkpoint file cannot be written (disk full, permission error)

**Detection**: write() or save-checkpoint.sh returns error

**Handling**:
1. Log error: `"Checkpoint save failed: [error]"`
2. Continue workflow without checkpoint (non-blocking)
3. Warn user: checkpoint unavailable for resumption
4. Store checkpoint data in memory for current session

**User Message**:
```
⚠ Checkpoint Save Warning

Could not save checkpoint to disk:
[error message]

Workflow will continue, but resumption from this point may not be possible.

Checkpoint data stored in memory for this session only.
```

### Error Type 5: Branch Decision Ambiguity

**Scenario**: Cannot determine whether to route to documentation or debugging

**Detection**: test_passing is null/undefined after extraction

**Handling**:
1. Log warning: `"Branch decision ambiguous, test status unclear"`
2. Apply safe default: Route to debugging (better to debug unnecessarily than skip debugging)
3. Display evidence to user: agent output, parsed values
4. Explain decision rationale

**User Message**:
```
⚠ Branch Decision: Debugging (Safe Default)

Test status could not be determined with confidence.

Parsed values:
- tests_passing: undefined
- phases_completed: [M]/[N]
- error_messages: [present/absent]

Routing to debugging phase as a precaution. If implementation actually
succeeded, you can manually skip debugging after reviewing the output.
```

## Success Criteria

### Primary Criteria (Must Have)

1. **Task Tool Invocation Verified**:
   - [ ] Task tool explicitly invoked (not just documented)
   - [ ] Invocation uses correct parameters (subagent_type, timeout, prompt)
   - [ ] Timeout set to 600000ms (10 minutes)
   - [ ] Agent type set to "general-purpose"

2. **Test Status Extraction Works**:
   - [ ] Test status extracted from agent output (true/false)
   - [ ] Extraction handles both success and failure cases
   - [ ] Fallback detection works if markers missing
   - [ ] Edge cases handled (ambiguous, malformed output)

3. **Conditional Branching Implemented**:
   - [ ] Explicit if/else logic based on test status
   - [ ] Success path routes to documentation phase
   - [ ] Failure path routes to debugging phase
   - [ ] Branch decision logged in checkpoint

4. **Checkpoints Saved Correctly**:
   - [ ] Success checkpoint includes all outputs (files, commits)
   - [ ] Failure checkpoint includes debug context (error, phase)
   - [ ] Checkpoints enable workflow resumption
   - [ ] Checkpoints stored in correct location

5. **User Feedback Clear**:
   - [ ] Success message displays files, commits, next phase
   - [ ] Failure message displays error, partial progress, next steps
   - [ ] Messages accurate for both paths
   - [ ] User understands what happened and what to do next

### Secondary Criteria (Should Have)

6. **Error Handling Robust**:
   - [ ] Task tool invocation failures handled with retry
   - [ ] Timeout errors handled with partial progress preservation
   - [ ] Status extraction failures handled with safe defaults
   - [ ] All errors provide clear user messages

7. **Performance Adequate**:
   - [ ] Extended timeout prevents premature timeout
   - [ ] Execution completes within reasonable time (< 15 minutes for typical plans)
   - [ ] Progress markers provide real-time feedback
   - [ ] No unnecessary delays or blocking operations

8. **Code Quality High**:
   - [ ] All passive voice converted to imperative
   - [ ] EXECUTE NOW blocks present for all major operations
   - [ ] Inline content complete (no external references for critical operations)
   - [ ] Verification checklists present and functional

### Tertiary Criteria (Nice to Have)

9. **Documentation Complete**:
   - [ ] All steps documented with clear instructions
   - [ ] Examples provided for key operations
   - [ ] Edge cases documented
   - [ ] Troubleshooting guidance included

10. **Testing Comprehensive**:
    - [ ] All test cases pass (success, failure, timeout, edge cases)
    - [ ] Test coverage ≥80% for implementation phase
    - [ ] Test automation enables regression testing
    - [ ] Test results validate all success criteria

## Notes

### Extended Timeout Rationale

**Why 600000ms (10 minutes)?**

Typical implementation plans have 4-8 phases. Each phase involves:
- Reading plan and extracting tasks: ~10 seconds
- Implementing code changes: 30-120 seconds per phase
- Running tests: 10-60 seconds per phase
- Creating git commit: 5-10 seconds per phase

**Calculation for 8-phase plan**:
```
8 phases × 120 seconds (implementation) = 960 seconds
8 phases × 60 seconds (tests) = 480 seconds
8 phases × 10 seconds (commits) = 80 seconds
Overhead (parsing, validation, error handling) = 100 seconds
Total = 1620 seconds = 27 minutes worst case

With parallelization and optimizations: ~8-12 minutes typical
Extended timeout of 10 minutes covers typical case + safety margin
```

**Alternative approach**: Dynamic timeout based on phase count
```python
# Calculate timeout dynamically
timeout_ms = min(600000, max(180000, plan.phase_count * 75000))
# 75 seconds per phase, min 3 minutes, max 10 minutes
```

### Test Framework Integration

The Implementation Phase relies on project test frameworks specified in CLAUDE.md. The /implement command (invoked by code-writer agent) must:

1. **Discover test commands**: Read from plan or CLAUDE.md
2. **Execute tests**: Run after each phase completion
3. **Parse results**: Determine pass/fail status
4. **Report results**: Provide structured output with markers

**Test Command Examples**:
- Lua/Neovim: `:TestSuite` or `nvim --headless -c "PlenaryBustedDirectory tests/" -c "qa!"`
- Python: `pytest tests/` or `python -m unittest discover`
- JavaScript: `npm test` or `jest tests/`
- Bash: `.claude/tests/run_all_tests.sh`

**Test Result Parsing**:
```bash
# Example test output
TEST_OUTPUT=$(run_tests)

# Parse for success indicators
if echo "$TEST_OUTPUT" | grep -qE "all tests passed|OK|SUCCESS"; then
    TESTS_PASSING="true"
elif echo "$TEST_OUTPUT" | grep -qE "FAILED|ERROR|test failed"; then
    TESTS_PASSING="false"
else
    # Ambiguous - check exit code
    if [ $? -eq 0 ]; then
        TESTS_PASSING="true"
    else
        TESTS_PASSING="false"
    fi
fi
```

### Workflow State Management

The Implementation Phase is the most state-intensive phase, managing:

**Input State** (from Planning Phase):
- Plan path and metadata
- Research report paths (for context)
- Project standards reference

**Execution State** (during implementation):
- Current phase being implemented
- Phases completed so far
- Files modified
- Git commits created
- Test status per phase

**Output State** (for next phase):
- Final test status (pass/fail)
- All modified files
- All git commits
- Error details (if failed)
- Debug context (if routing to debugging)

**State Transitions**:
```
Planning Phase → Implementation Phase:
  - Load: plan_path, plan_metadata
  - Store: implementation_context

Implementation Phase → Documentation Phase (success):
  - Load: tests_passing=true, files_modified, git_commits
  - Store: documentation_context

Implementation Phase → Debugging Phase (failure):
  - Load: tests_passing=false, failed_phase, error_message
  - Store: debug_context, iteration=0
```

### Agent Coordination Pattern

This phase demonstrates the **behavioral injection pattern** for agent coordination:

1. **Behavioral Guidelines**: Agent reads its own behavior file (code-writer.md)
2. **Task-Specific Instructions**: Orchestrator provides complete task context
3. **Tool Access**: Agent has tools needed for task (Read, Write, Edit, Bash, TodoWrite)
4. **Output Format**: Agent follows structured output format for result parsing
5. **No Routing Logic**: Agent focuses on its task, orchestrator handles workflow routing

This pattern ensures:
- Agent specialization (code-writer only writes code)
- Orchestrator coordination (orchestrate handles workflow logic)
- Clean separation of concerns
- Testable, modular architecture

### Complexity Justification

**Phase Complexity: 8/10 (High)**

Factors contributing to high complexity:

1. **Multiple transformation types**:
   - Passive → active voice conversion (7 steps)
   - Documentation → execution conversion
   - External references → inline content
   - Examples → executable instructions

2. **Critical branching logic**:
   - First conditional phase in workflow
   - Branch decision affects all subsequent phases
   - Error-prone test status parsing

3. **State management complexity**:
   - Large workflow state (implementation_context, implementation_status, implementation_failure)
   - Context preparation for two different next phases
   - Checkpoint creation for success and failure paths

4. **Testing requirements**:
   - Multiple test cases (success, failure, timeout, edge cases)
   - Test status parsing validation
   - End-to-end workflow validation

5. **Risk factors**:
   - High-impact phase (determines workflow success)
   - Complex error handling (timeout, parsing failure, invocation failure)
   - Dependency on external agent behavior

**Estimated Time**: 6-8 hours accounts for:
- Careful refactoring of 250 lines
- Testing all branching paths
- Validating status extraction
- Error handling implementation
- End-to-end integration testing
