# Phase 0: CRITICAL - Remove Command-to-Command Invocations

## Metadata
- **Plan**: 080_orchestrate_enhancement.md
- **Phase Number**: 0
- **Phase Name**: CRITICAL - Remove Command-to-Command Invocations
- **Complexity**: 9/10
- **Priority**: CRITICAL - Must be completed before other phases
- **Estimated Duration**: 4-6 hours
- **Dependencies**: None (blocking phase for all others)

## Problem Statement

The current `/orchestrate` implementation violates the documented architectural pattern by using the `SlashCommand` tool to invoke `/plan`, `/implement`, `/debug`, and `/document` commands. This creates four critical failures:

### 1. Context Bloat
When `/orchestrate` calls `/plan` via `SlashCommand`, the entire `/plan` command prompt (3000+ tokens) expands inline, consuming valuable context window space unnecessarily.

### 2. Broken [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md)
The artifact path context calculated by location-specialist in Phase 0 cannot be injected into commands invoked via SlashCommand. The commands execute with their default behavior, creating artifacts in arbitrary locations instead of `specs/NNN_topic/`.

### 3. Lost Control
The orchestrator cannot:
- Customize plan structure requirements
- Inject topic number into plan metadata
- Control where debug reports are saved
- Ensure documentation updates reference the correct plan

### 4. Anti-Pattern Propagation
This sets a bad example for future command development, encouraging recursive command invocations instead of proper agent delegation.

### Evidence

From `TODO.md` Example 2, lines 332-340:
```markdown
Phase 2: Planning
- Agent invokes /plan slash command
```

Result: Planning phase doesn't receive artifact path context from location-specialist, creating plan in wrong location.

## Objective

Refactor `/orchestrate` to eliminate ALL `SlashCommand` tool invocations and replace with direct `Task` tool invocations to specialized subagents. This enables proper [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) and maintains orchestrator control.

## Architecture

### Current (Broken) Pattern

```
/orchestrate
 └─> SlashCommand("/plan [description]")
    └─> /plan expands entire command prompt (3000+ tokens)
       └─> /plan invokes plan-architect agent
          └─> plan-architect creates plan
             └─> NO artifact path context available
                └─> Plan saved to arbitrary location ❌
```

### Target (Correct) Pattern

```
/orchestrate
 ├─> Phase 0: location-specialist calculates artifact paths
 │   └─> Returns: {artifact_paths.plans}/NNN_plan.md
 │
 └─> Phase 2: Direct Task invocation
    └─> Task(plan-architect) with injected context
       └─> prompt includes: "Save plan to {artifact_paths.plans}/NNN_plan.md"
          └─> plan-architect creates plan at specified location ✓
```

## Implementation Stages

### Stage 1: Audit Current orchestrate.md Structure

**Objective**: Document all current SlashCommand invocations and understand their context requirements.

**Tasks**:

- [ ] **Search orchestrate.md for SlashCommand usage**
 ```bash
 cd /home/benjamin/.config
 grep -n "SlashCommand" .claude/commands/orchestrate.md > /tmp/slash_command_audit.txt
 grep -n "/plan\|/implement\|/debug\|/document" .claude/commands/orchestrate.md | grep -v "^#" >> /tmp/slash_command_audit.txt
 cat /tmp/slash_command_audit.txt
 ```

- [ ] **Document each SlashCommand instance**
 Create audit report in `/home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/artifacts/phase0_audit.md`:
 ```markdown
 # SlashCommand Audit Report

 ## Instance 1: /plan invocation
 - **Location**: Line ~1080-1110
 - **Phase**: Phase 2 (Planning)
 - **Current Implementation**: SlashCommand("/plan [description]")
 - **Purpose**: Generate implementation plan from research reports
 - **Context Required**: Research report paths, artifact save location
 - **Replacement Agent**: plan-architect.md

 ## Instance 2: /implement invocation
 - **Location**: Line ~1465-1500
 - **Phase**: Phase 3 (Implementation)
 - **Current Implementation**: SlashCommand("/implement [plan_path]")
 - **Purpose**: Execute plan phase-by-phase with testing
 - **Context Required**: Plan path, artifact paths for debug/outputs, git commit format
 - **Replacement Agent**: code-writer.md OR implementation-executor.md (new)

 ## Instance 3: /debug invocation
 - **Location**: Line ~1700-1750 (estimated)
 - **Phase**: Phase 4 (Debugging - conditional)
 - **Current Implementation**: SlashCommand("/debug [description] [plan-path]")
 - **Purpose**: Analyze test failures and create debug reports
 - **Context Required**: Test failure details, plan path, save debug to topic/debug/
 - **Replacement Agent**: debug-specialist.md

 ## Instance 4: /document invocation
 - **Location**: Line ~1900-1950 (estimated)
 - **Phase**: Phase 5 (Documentation)
 - **Current Implementation**: SlashCommand("/document [description]")
 - **Purpose**: Update documentation and create summary
 - **Context Required**: Modified files, plan path, summary save location
 - **Replacement Agent**: doc-writer.md
 ```

- [ ] **Analyze context requirements for each command**
 - What information does each command need?
 - What artifacts does each command create?
 - What metadata should be returned to orchestrator?

**Testing**:
```bash
# Verify audit report created
test -f /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement/artifacts/phase0_audit.md
echo "Audit report exists: $?"

# Count SlashCommand instances found
grep -c "SlashCommand" /home/benjamin/.config/.claude/commands/orchestrate.md
# Expected: 0-4 instances (depending on current state)
```

**Expected Outcomes**:
- Complete audit report documenting all 4 command invocations
- Understanding of context requirements for each replacement
- Clear mapping: command → replacement agent

---

### Stage 2: Replace /plan with plan-architect Agent

**Objective**: Replace `SlashCommand("/plan")` with direct `Task` tool invocation to plan-architect agent with injected artifact context.

**Background**:

The `/plan` command uses the plan-architect agent internally, but wraps it in command-level logic. By invoking plan-architect directly, we gain full control over prompt construction and can inject behavioral context.

**Implementation Details**:

**Current Code (to remove)**:
```markdown
## Phase 2: Planning

YOU MUST invoke the /plan command to generate a structured implementation plan.

Task {
 subagent_type: "general-purpose"
 prompt: |
  Read: .claude/agents/plan-architect.md

  /plan [workflow_description]
}
```

**Replacement Code (to add)**:
```markdown
## Phase 2: Planning

YOU MUST invoke the plan-architect agent DIRECTLY (NOT via /plan command) to generate a structured implementation plan with artifact path injection.

**CRITICAL**: DO NOT use SlashCommand tool. Use Task tool with explicit [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md).

Task {
 subagent_type: "general-purpose"
 description: "Generate implementation plan with artifact organization"
 prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/plan-architect.md

  You are acting as a Plan Architect Agent.

  FEATURE REQUEST:
  ${workflow_description}

  RESEARCH CONTEXT:
  Research reports have been created with key findings:
  ${research_report_paths}

  ARTIFACT ORGANIZATION (CRITICAL - ABSOLUTE REQUIREMENT):
  You MUST save the implementation plan to this EXACT location:
  ${artifact_paths.plans}/${topic_number}_${plan_name}.md

  Path breakdown:
  - Topic directory: ${WORKFLOW_TOPIC_DIR}
  - Plans subdirectory: ${artifact_paths.plans}
  - Topic number: ${topic_number} (e.g., "027")
  - Plan name: ${plan_name} (e.g., "user_authentication")

  PLAN REQUIREMENTS:
  - Multi-phase structure with checkbox tasks
  - Testing strategy per phase (use project testing protocols)
  - Complexity metadata for each phase
  - Dependency metadata (depends_on: [phase_X]) for wave execution
  - Git commit reminders after each phase
  - Compatible with /implement command structure
  - Follow standards from: /home/benjamin/.config/CLAUDE.md

  PLAN METADATA (include in plan file):
  ```yaml
  ## Metadata
  - **Date**: $(date +%Y-%m-%d)
  - **Topic**: ${topic_number}_${topic_name}
  - **Feature**: ${workflow_description}
  - **Research Reports**: [${research_report_paths}]
  - **Complexity**: To be evaluated after creation
  - **Structure Level**: 0 (inline phases)
  ```

  After creating the plan file, YOU MUST verify it exists and return:
  PLAN_CREATED: ${artifact_paths.plans}/${topic_number}_${plan_name}.md
  PLAN_PHASES: N
  PLAN_COMPLEXITY: [brief assessment]
}
```

**Tasks**:

- [ ] **Locate /plan invocation in orchestrate.md**
 ```bash
 grep -n "SlashCommand.*plan\|/plan" .claude/commands/orchestrate.md | head -20
 ```

- [ ] **Extract artifact path variables from Phase 0 (location-specialist)**
 Ensure Phase 0 has populated:
 - `${WORKFLOW_TOPIC_DIR}` - Full path to specs/NNN_topic/
 - `${artifact_paths.plans}` - Full path to plans/ subdirectory
 - `${topic_number}` - Zero-padded number (e.g., "027")
 - `${topic_name}` - Sanitized topic name (e.g., "user_authentication")

- [ ] **Update orchestrate.md Phase 2 section**
 - Remove SlashCommand invocation
 - Add Task tool invocation with template above
 - Substitute all ${variable} references with actual workflow state variables
 - Add verification logic after plan creation

- [ ] **Add plan file verification**
 ```markdown
 ## Phase 2 Verification

 After plan-architect completes, YOU MUST verify plan file exists:

 EXPECTED_PLAN_PATH="${artifact_paths.plans}/${topic_number}_${plan_name}.md"

 if [[ ! -f "$EXPECTED_PLAN_PATH" ]]; then
  echo "ERROR: Plan file not created at expected location"
  echo "Expected: $EXPECTED_PLAN_PATH"
  echo "Agent may have created plan elsewhere - search and move:"

  # Search for recently created plan files
  find specs/ -name "*.md" -mmin -5 -type f

  # Fallback: Create minimal plan template
  # (Only if absolutely necessary - prefer agent retry)
 fi
 ```

- [ ] **Extract plan metadata for workflow state**
 ```markdown
 ## Phase 2 [Metadata Extraction Pattern](../../../docs/concepts/patterns/metadata-extraction.md)

 Extract plan metadata from agent response (NOT full plan content):
 - Plan path: ${EXPECTED_PLAN_PATH}
 - Plan phases: [parse from agent response or read plan file]
 - Plan complexity: [agent's brief assessment]

 Store in workflow state for Phase 3 (Implementation).
 DO NOT include full plan content in orchestrator context.
 ```

**Testing**:
```bash
# Unit test: Direct plan-architect invocation
# Create test workflow directory
mkdir -p /tmp/orchestrate_test/specs/001_test/plans

# Test plan-architect agent directly
# (Simulated - actual test would invoke via Task tool)
echo "Testing plan-architect with artifact injection..."

# Expected: Plan created at /tmp/orchestrate_test/specs/001_test/plans/001_test_plan.md

# Integration test: Verify orchestrate Phase 2 uses Task not SlashCommand
grep -A 20 "Phase 2: Planning" .claude/commands/orchestrate.md | grep -q "SlashCommand"
if [ $? -eq 0 ]; then
 echo "FAIL: Phase 2 still uses SlashCommand"
 exit 1
else
 echo "PASS: Phase 2 uses Task tool"
fi

# Verify artifact path injection present
grep -A 20 "Phase 2: Planning" .claude/commands/orchestrate.md | grep -q "artifact_paths.plans"
if [ $? -eq 0 ]; then
 echo "PASS: Artifact path injection present"
else
 echo "FAIL: Artifact path injection missing"
 exit 1
fi
```

**Expected Outcomes**:
- SlashCommand("/plan") removed from orchestrate.md
- Task tool invocation with plan-architect agent replaces it
- Artifact path context injected into plan-architect prompt
- Plan verification ensures file created at correct location
- Plan metadata extracted (path + brief assessment only, not full content)

**Error Handling**:

```markdown
## Plan Creation Failure Handling

If plan-architect fails to create plan file:

1. **Retry once** with more explicit instructions
2. **Search for misplaced plan**: `find specs/ -name "*.md" -mmin -5`
3. **Move misplaced plan** to correct location if found
4. **Create minimal plan template** as last resort:
  ```bash
  cat > "${EXPECTED_PLAN_PATH}" <<'EOF'
  # Implementation Plan: ${feature_name}

  ## Metadata
  - **Date**: $(date +%Y-%m-%d)
  - **Topic**: ${topic_number}_${topic_name}
  - **Status**: Template - Needs manual completion

  ## Phase 1: Setup
  - [ ] Task 1
  - [ ] Task 2

  ## Testing
  - [ ] Run test suite
  EOF
  ```
5. **Alert user** if template used (plan needs manual review)

**Never proceed to Phase 3 without a plan file.**
```

---

### Stage 3: Replace /implement with implementation-executor Agent

**Objective**: Replace `SlashCommand("/implement")` with direct `Task` tool invocation to implementation-executor agent (or enhanced code-writer agent).

**Background**:

The `/implement` command is complex, handling phase-by-phase execution, testing, checkpoints, and plan updates. We need to preserve all this functionality while removing the command wrapper.

**Agent Choice Decision**:

Two options:
1. **Use existing code-writer agent** with enhanced prompt for plan execution
2. **Create new implementation-executor agent** specifically for orchestrate workflows

**Recommendation**: Use code-writer agent with enhanced [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) (simpler, reuses existing agent).

**Implementation Details**:

**Current Code (to remove)**:
```markdown
## Phase 3: Implementation

YOU MUST invoke the /implement command to execute the plan.

Task {
 subagent_type: "general-purpose"
 prompt: |
  Read: .claude/agents/code-writer.md

  /implement ${PLAN_PATH}
}
```

**Replacement Code (to add)**:
```markdown
## Phase 3: Implementation

YOU MUST invoke the code-writer agent DIRECTLY (NOT via /implement command) to execute the plan phase-by-phase with artifact organization.

**CRITICAL**: DO NOT use SlashCommand tool. Use Task tool with explicit [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md).

Task {
 subagent_type: "general-purpose"
 description: "Execute implementation plan with testing and progress tracking"
 timeout: 600000 # 10 minutes for complex implementations
 prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/code-writer.md

  You are acting as a Code Writer Agent for plan execution.

  IMPLEMENTATION PLAN:
  Read the complete implementation plan from:
  ${PLAN_PATH}

  EXECUTION REQUIREMENTS:
  1. **Phase-by-Phase Execution**: Execute each phase sequentially
  2. **Task Completion**: Complete all tasks in each phase before proceeding
  3. **Testing After Each Phase**: Run test suite after completing each phase
  4. **Progress Updates**: Update plan file with task checkboxes [x] after completion
  5. **Git Commits**: Create git commit after each phase completion
  6. **Checkpoint Creation**: Save checkpoint if context window constrained

  ARTIFACT ORGANIZATION (CRITICAL):
  - **Debug Reports**: Save any debugging artifacts to ${WORKFLOW_TOPIC_DIR}/debug/
  - **Test Outputs**: Save test results to ${WORKFLOW_TOPIC_DIR}/outputs/
  - **Generated Scripts**: Save temporary scripts to ${WORKFLOW_TOPIC_DIR}/scripts/
  - **Plan Updates**: Update ${PLAN_PATH} with progress markers

  TESTING PROTOCOL:
  - Discover test command from CLAUDE.md testing protocols
  - Run full test suite after each phase
  - If tests fail: Report failures and STOP (debugging phase will handle)
  - If tests pass: Continue to next phase

  GIT COMMIT FORMAT:
  After each phase completion, create commit with format:
  feat(${topic_number}): complete Phase N - [Phase Name]

  Example: feat(027): complete Phase 2 - Backend Implementation

  PROGRESS REPORTING:
  Update plan file ${PLAN_PATH} after each task/phase:
  - Mark completed tasks: - [x] Task description
  - Update phase status: **Status**: Completed
  - Preserve all formatting and metadata

  CHECKPOINT MANAGEMENT:
  If context window exceeds 80% capacity:
  1. Create checkpoint: .claude/data/checkpoints/${topic_number}_phase_N.json
  2. Update plan with partial progress
  3. Return checkpoint path for resumption

  RETURN FORMAT:
  After implementation completes (or checkpoint created):

  IMPLEMENTATION_STATUS: [complete|partial|failed]
  TESTS_PASSING: [true|false]
  PHASES_COMPLETED: N
  FILES_MODIFIED: [list of file paths]
  COMMIT_HASHES: [list of git commit hashes]
  CHECKPOINT_PATH: [path if checkpoint created, else "none"]
  FAILURE_REASON: [if failed, brief description]

  If tests fail, include:
  FAILED_TESTS: [list of failed test names]
  TEST_OUTPUT_PATH: ${WORKFLOW_TOPIC_DIR}/outputs/test_failures.txt
}
```

**Tasks**:

- [ ] **Locate /implement invocation in orchestrate.md**
 ```bash
 grep -n "SlashCommand.*implement\|/implement" .claude/commands/orchestrate.md | head -20
 ```

- [ ] **Update orchestrate.md Phase 3 section**
 - Remove SlashCommand invocation
 - Add Task tool invocation with enhanced code-writer prompt
 - Inject artifact paths from Phase 0
 - Inject plan path from Phase 2
 - Set extended timeout (10 minutes minimum)

- [ ] **Add implementation verification**
 ```markdown
 ## Phase 3 Verification

 After code-writer completes, YOU MUST parse return format:

 IMPLEMENTATION_STATUS=$(parse_agent_response "IMPLEMENTATION_STATUS")
 TESTS_PASSING=$(parse_agent_response "TESTS_PASSING")
 FILES_MODIFIED=$(parse_agent_response "FILES_MODIFIED")

 if [[ "$IMPLEMENTATION_STATUS" == "complete" && "$TESTS_PASSING" == "true" ]]; then
  echo "✓ Implementation Phase Complete - All tests passing"
  SKIP_DEBUGGING=true
  proceed_to_documentation
 elif [[ "$IMPLEMENTATION_STATUS" == "complete" && "$TESTS_PASSING" == "false" ]]; then
  echo "⚠ Implementation Complete - Tests failing"
  SKIP_DEBUGGING=false
  proceed_to_debugging
 elif [[ "$IMPLEMENTATION_STATUS" == "partial" ]]; then
  echo "⚠ Implementation Partial - Checkpoint created"
  CHECKPOINT_PATH=$(parse_agent_response "CHECKPOINT_PATH")
  echo "Resume with: /resume-implement $CHECKPOINT_PATH"
 else
  echo "✗ Implementation Failed"
  FAILURE_REASON=$(parse_agent_response "FAILURE_REASON")
  proceed_to_debugging # Debug implementation failure
 fi
 ```

- [ ] **Verify artifact organization**
 ```bash
 # Check debug reports in correct location
 if [ -d "${WORKFLOW_TOPIC_DIR}/debug" ]; then
  DEBUG_COUNT=$(ls -1 "${WORKFLOW_TOPIC_DIR}/debug" | wc -l)
  echo "Debug artifacts: $DEBUG_COUNT files"
 fi

 # Check test outputs
 if [ -f "${WORKFLOW_TOPIC_DIR}/outputs/test_failures.txt" ]; then
  echo "Test failure output captured"
 fi
 ```

**Testing**:
```bash
# Unit test: Verify Phase 3 no longer uses SlashCommand
grep -A 50 "Phase 3: Implementation" .claude/commands/orchestrate.md | grep -q "SlashCommand"
if [ $? -eq 0 ]; then
 echo "FAIL: Phase 3 still uses SlashCommand"
 exit 1
else
 echo "PASS: Phase 3 uses Task tool"
fi

# Verify artifact path injection
grep -A 50 "Phase 3: Implementation" .claude/commands/orchestrate.md | grep -q "WORKFLOW_TOPIC_DIR"
if [ $? -eq 0 ]; then
 echo "PASS: Artifact paths injected"
else
 echo "FAIL: No artifact path injection"
 exit 1
fi

# Verify timeout set for long implementations
grep -A 50 "Phase 3: Implementation" .claude/commands/orchestrate.md | grep -q "timeout:"
if [ $? -eq 0 ]; then
 echo "PASS: Timeout configured"
else
 echo "WARN: No explicit timeout (may use default)"
fi
```

**Expected Outcomes**:
- SlashCommand("/implement") removed from orchestrate.md
- Task tool invocation with code-writer agent replaces it
- Artifact paths for debug/outputs/scripts injected
- Plan path passed explicitly
- Implementation status parsed for conditional debugging
- Extended timeout prevents premature termination

**Error Handling**:

```markdown
## Implementation Failure Handling

If code-writer fails during implementation:

1. **Parse failure reason** from agent response
2. **Check for partial progress**: Look for checkpoint file
3. **Verify plan updates**: Check if any tasks marked complete
4. **Collect test output**: Check ${WORKFLOW_TOPIC_DIR}/outputs/
5. **Proceed to debugging**: Pass failure context to debug-specialist

**Never skip debugging when implementation fails.**
Debugging phase receives:
- FAILURE_REASON from implementation
- TEST_OUTPUT_PATH for analysis
- PLAN_PATH for intended behavior
- FILES_MODIFIED for code review
```

---

### Stage 4: Replace /debug with debug-specialist Agent

**Objective**: Replace `SlashCommand("/debug")` with direct `Task` tool invocation to debug-specialist agent with test failure context.

**Background**:

Debugging phase is conditional (only runs if tests fail). The debug-specialist needs failure details, test output, and plan context to identify root causes.

**Implementation Details**:

**Current Code (to remove)**:
```markdown
## Phase 4: Debugging (Conditional)

if [[ "$TESTS_PASSING" == "false" ]]; then
 Task {
  subagent_type: "general-purpose"
  prompt: |
   Read: .claude/agents/debug-specialist.md

   /debug "Test failures after implementation" ${PLAN_PATH}
 }
fi
```

**Replacement Code (to add)**:
```markdown
## Phase 4: Debugging (Conditional)

**ONLY EXECUTE if Phase 3 tests failed ($TESTS_PASSING == false)**

if [[ "$TESTS_PASSING" == "false" ]]; then
 YOU MUST invoke debug-specialist agent DIRECTLY (NOT via /debug command) with test failure context.

 **CRITICAL**: DO NOT use SlashCommand tool. Use Task tool with explicit [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md).

 Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures and create debug report"
  prompt: |
   Read and follow the behavioral guidelines from:
   /home/benjamin/.config/.claude/agents/debug-specialist.md

   You are acting as a Debug Specialist Agent.

   ISSUE DESCRIPTION:
   Implementation completed but ${FAILED_TEST_COUNT} tests are failing.

   TEST FAILURE CONTEXT:
   Failed tests: ${FAILED_TESTS[@]}
   Test output: ${TEST_OUTPUT_PATH}

   IMPLEMENTATION CONTEXT:
   Plan path: ${PLAN_PATH}
   Files modified: ${FILES_MODIFIED[@]}
   Last commit: ${LAST_COMMIT_HASH}

   ARTIFACT ORGANIZATION (CRITICAL):
   You MUST save debug report to:
   ${WORKFLOW_TOPIC_DIR}/debug/${topic_number}_debug_$(date +%Y%m%d_%H%M%S).md

   **IMPORTANT**: Debug reports are COMMITTED to git (not gitignored).
   This creates a permanent record of debugging sessions.

   DEBUGGING REQUIREMENTS:
   1. **Read test output**: Analyze ${TEST_OUTPUT_PATH} for failure details
   2. **Review implementation**: Read modified files to understand changes
   3. **Compare with plan**: Check if implementation matches plan intent
   4. **Identify root cause**: Determine why tests are failing
   5. **Propose fixes**: Suggest specific code changes to resolve failures
   6. **Create debug report**: Document findings and recommendations

   DEBUG REPORT STRUCTURE:
   ```markdown
   # Debug Report: ${topic_number} - Test Failures

   ## Summary
   [Brief overview of failures]

   ## Failed Tests Analysis
   [Detailed analysis of each failed test]

   ## Root Cause
   [Identified root cause of failures]

   ## Proposed Fixes
   [Specific code changes recommended]

   ## Testing Strategy
   [How to verify fixes work]
   ```

   RETURN FORMAT:
   DEBUG_REPORT_PATH: ${WORKFLOW_TOPIC_DIR}/debug/[filename].md
   ROOT_CAUSE: [brief description]
   FIX_CONFIDENCE: [high|medium|low]
   FIXES_PROPOSED: N
 }

 ## Debugging Loop (Max 3 iterations)

 After debug-specialist completes:
 1. Read proposed fixes from debug report
 2. Apply fixes (invoke code-writer again)
 3. Re-run tests
 4. If tests pass: Exit debugging loop, proceed to documentation
 5. If tests still fail: Increment iteration counter
 6. If iteration < 3: Repeat debugging with updated context
 7. If iteration >= 3: Alert user for manual intervention
else
 echo "✓ All tests passing - Skipping debugging phase"
fi
```

**Tasks**:

- [ ] **Locate /debug invocation in orchestrate.md**
 ```bash
 grep -n "SlashCommand.*debug\|/debug" .claude/commands/orchestrate.md | head -20
 ```

- [ ] **Update orchestrate.md Phase 4 section**
 - Remove SlashCommand invocation
 - Add conditional check: only run if tests failed
 - Add Task tool invocation with debug-specialist agent
 - Inject test failure context from Phase 3
 - Inject artifact path for debug reports

- [ ] **Add debug report verification**
 ```markdown
 ## Phase 4 Verification

 After debug-specialist completes, YOU MUST verify debug report created:

 DEBUG_REPORT_PATH=$(parse_agent_response "DEBUG_REPORT_PATH")

 if [[ ! -f "$DEBUG_REPORT_PATH" ]]; then
  echo "WARNING: Debug report not created at expected location"
  echo "Expected pattern: ${WORKFLOW_TOPIC_DIR}/debug/${topic_number}_debug_*.md"

  # Search for recently created debug reports
  find "${WORKFLOW_TOPIC_DIR}/debug" -name "*.md" -mmin -5
 fi

 # Extract fix proposals
 ROOT_CAUSE=$(parse_agent_response "ROOT_CAUSE")
 FIX_CONFIDENCE=$(parse_agent_response "FIX_CONFIDENCE")

 echo "Debug Analysis:"
 echo " Root Cause: $ROOT_CAUSE"
 echo " Fix Confidence: $FIX_CONFIDENCE"
 echo " Report: $DEBUG_REPORT_PATH"
 ```

- [ ] **Implement debugging loop**
 ```bash
 DEBUG_ITERATION=0
 MAX_DEBUG_ITERATIONS=3

 while [[ "$TESTS_PASSING" == "false" && $DEBUG_ITERATION -lt $MAX_DEBUG_ITERATIONS ]]; do
  DEBUG_ITERATION=$((DEBUG_ITERATION + 1))
  echo "Debugging Iteration $DEBUG_ITERATION / $MAX_DEBUG_ITERATIONS"

  # Invoke debug-specialist
  # ... (Task invocation above)

  # Apply proposed fixes (invoke code-writer again)
  # Re-run tests
  # Update $TESTS_PASSING
 done

 if [[ "$TESTS_PASSING" == "false" ]]; then
  echo "⚠ Tests still failing after $MAX_DEBUG_ITERATIONS iterations"
  echo "Manual intervention required"
  echo "Debug reports: ${WORKFLOW_TOPIC_DIR}/debug/"
 fi
 ```

**Testing**:
```bash
# Unit test: Verify Phase 4 no longer uses SlashCommand
grep -A 50 "Phase 4: Debugging" .claude/commands/orchestrate.md | grep -q "SlashCommand"
if [ $? -eq 0 ]; then
 echo "FAIL: Phase 4 still uses SlashCommand"
 exit 1
else
 echo "PASS: Phase 4 uses Task tool"
fi

# Verify conditional execution
grep -A 50 "Phase 4: Debugging" .claude/commands/orchestrate.md | grep -q "TESTS_PASSING.*false"
if [ $? -eq 0 ]; then
 echo "PASS: Conditional debugging present"
else
 echo "FAIL: No conditional check for debugging"
 exit 1
fi

# Verify debug report path injection
grep -A 50 "Phase 4: Debugging" .claude/commands/orchestrate.md | grep -q "WORKFLOW_TOPIC_DIR.*debug"
if [ $? -eq 0 ]; then
 echo "PASS: Debug report path injected"
else
 echo "FAIL: No debug report path injection"
 exit 1
fi
```

**Expected Outcomes**:
- SlashCommand("/debug") removed from orchestrate.md
- Task tool invocation with debug-specialist agent replaces it
- Conditional execution (only if tests fail)
- Test failure context injected into debug-specialist prompt
- Debug report saved to correct location (topic/debug/ - committed!)
- Debugging loop with max 3 iterations

---

### Stage 5: Replace /document with doc-writer Agent

**Objective**: Replace `SlashCommand("/document")` with direct `Task` tool invocation to doc-writer agent with workflow summary context.

**Background**:

Documentation phase updates project documentation and creates workflow summary. The doc-writer needs implementation summary, modified files, and plan reference.

**Implementation Details**:

**Current Code (to remove)**:
```markdown
## Phase 5: Documentation

Task {
 subagent_type: "general-purpose"
 prompt: |
  Read: .claude/agents/doc-writer.md

  /document "Update docs for workflow completion"
}
```

**Replacement Code (to add)**:
```markdown
## Phase 5: Documentation

YOU MUST invoke doc-writer agent DIRECTLY (NOT via /document command) to update documentation and create workflow summary.

**CRITICAL**: DO NOT use SlashCommand tool. Use Task tool with explicit [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md).

Task {
 subagent_type: "general-purpose"
 description: "Update documentation and create workflow summary"
 prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/doc-writer.md

  You are acting as a Documentation Writer Agent.

  WORKFLOW SUMMARY:
  Feature: ${workflow_description}
  Topic: ${topic_number}_${topic_name}
  Plan: ${PLAN_PATH}
  Research Reports: ${research_report_paths[@]}

  IMPLEMENTATION SUMMARY:
  Files Modified: ${FILES_MODIFIED[@]}
  Phases Completed: ${PHASES_COMPLETED}
  Tests Status: ${TESTS_PASSING}
  Commits Created: ${COMMIT_HASHES[@]}
  Debug Sessions: ${DEBUG_ITERATION} (if any)

  ARTIFACT ORGANIZATION (CRITICAL):
  You MUST save workflow summary to:
  ${WORKFLOW_TOPIC_DIR}/summaries/${topic_number}_${topic_name}_summary.md

  DOCUMENTATION REQUIREMENTS:
  1. **Update affected READMEs**: Add documentation for new features
  2. **Update guides**: If workflow created new patterns, document them
  3. **Create workflow summary**: Comprehensive summary of entire workflow
  4. **Add cross-references**: Link summary to plan, reports, and code

  WORKFLOW SUMMARY STRUCTURE:
  ```markdown
  # Workflow Summary: ${topic_number} - ${topic_name}

  ## Overview
  [Brief description of workflow and feature]

  ## Research Phase
  - Reports created: [links to research reports]
  - Key findings: [summary of research insights]

  ## Planning Phase
  - Plan created: [link to ${PLAN_PATH}]
  - Complexity: [from plan metadata]
  - Phases: ${PHASES_COMPLETED}

  ## Implementation Phase
  - Files modified: [list with brief descriptions]
  - Tests: ${TESTS_PASSING} (all passing | N failures)
  - Commits: [list of commit hashes with messages]

  ## Debugging Phase (if applicable)
  - Debug sessions: ${DEBUG_ITERATION}
  - Debug reports: [links to debug reports in topic/debug/]

  ## Documentation Updates
  - READMEs updated: [list]
  - Guides created/updated: [list]

  ## Artifacts Created
  - Research: ${WORKFLOW_TOPIC_DIR}/reports/
  - Plan: ${PLAN_PATH}
  - Debug: ${WORKFLOW_TOPIC_DIR}/debug/ (if any)
  - Summary: ${WORKFLOW_TOPIC_DIR}/summaries/

  ## Success Metrics
  - Workflow duration: [calculated]
  - Context usage: [percentage]
  - Artifacts organized: ✓
  ```

  RETURN FORMAT:
  SUMMARY_PATH: ${WORKFLOW_TOPIC_DIR}/summaries/[filename].md
  READMES_UPDATED: [list of README paths]
  GUIDES_UPDATED: [list of guide paths]
}
```

**Tasks**:

- [ ] **Locate /document invocation in orchestrate.md**
 ```bash
 grep -n "SlashCommand.*document\|/document" .claude/commands/orchestrate.md | head -20
 ```

- [ ] **Update orchestrate.md Phase 5 section**
 - Remove SlashCommand invocation
 - Add Task tool invocation with doc-writer agent
 - Inject workflow summary context from all previous phases
 - Inject artifact path for summary location

- [ ] **Add summary verification**
 ```markdown
 ## Phase 5 Verification

 After doc-writer completes, YOU MUST verify summary created:

 SUMMARY_PATH=$(parse_agent_response "SUMMARY_PATH")

 if [[ ! -f "$SUMMARY_PATH" ]]; then
  echo "WARNING: Workflow summary not created"
  echo "Expected: ${WORKFLOW_TOPIC_DIR}/summaries/${topic_number}_*_summary.md"

  # Create minimal summary as fallback
  cat > "${WORKFLOW_TOPIC_DIR}/summaries/${topic_number}_${topic_name}_summary.md" <<EOF
  # Workflow Summary: ${topic_number} - ${topic_name}

  ## Overview
  ${workflow_description}

  ## Artifacts
  - Plan: ${PLAN_PATH}
  - Files modified: ${FILES_MODIFIED[@]}
  EOF
 fi

 # Extract updated documentation
 READMES_UPDATED=$(parse_agent_response "READMES_UPDATED")

 echo "Documentation Phase Complete:"
 echo " Summary: $SUMMARY_PATH"
 echo " READMEs Updated: $READMES_UPDATED"
 ```

**Testing**:
```bash
# Unit test: Verify Phase 5 no longer uses SlashCommand
grep -A 50 "Phase 5: Documentation" .claude/commands/orchestrate.md | grep -q "SlashCommand"
if [ $? -eq 0 ]; then
 echo "FAIL: Phase 5 still uses SlashCommand"
 exit 1
else
 echo "PASS: Phase 5 uses Task tool"
fi

# Verify workflow summary path injection
grep -A 50 "Phase 5: Documentation" .claude/commands/orchestrate.md | grep -q "summaries"
if [ $? -eq 0 ]; then
 echo "PASS: Summary path injected"
else
 echo "FAIL: No summary path injection"
 exit 1
fi
```

**Expected Outcomes**:
- SlashCommand("/document") removed from orchestrate.md
- Task tool invocation with doc-writer agent replaces it
- Workflow summary context injected (files modified, commits, etc.)
- Summary saved to correct location (topic/summaries/)
- Documentation updates verified

---

### Stage 6: Update Documentation and Add Validation

**Objective**: Update orchestrate.md with "NO SLASHCOMMAND" policy documentation and create validation script to prevent regression.

**Tasks**:

- [ ] **Add architectural policy comment block**
 Add at top of orchestrate.md (after frontmatter):
 ```markdown
 <!-- ═══════════════════════════════════════════════════════════════ -->
 <!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE         -->
 <!-- ═══════════════════════════════════════════════════════════════ -->
 <!-- /orchestrate MUST NEVER invoke other slash commands      -->
 <!-- FORBIDDEN TOOLS: SlashCommand                  -->
 <!-- REQUIRED PATTERN: Task tool → Specialized agents        -->
 <!-- ═══════════════════════════════════════════════════════════════ -->
 <!--                                 -->
 <!-- WHY THIS MATTERS:                        -->
 <!-- 1. Context Bloat: SlashCommand expands entire command prompts  -->
 <!--  (3000+ tokens each), consuming valuable context window    -->
 <!-- 2. Broken [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md): Commands invoked via      -->
 <!--  SlashCommand cannot receive artifact path context from    -->
 <!--  location-specialist, breaking topic-based organization    -->
 <!-- 3. Lost Control: Orchestrator cannot customize agent behavior, -->
 <!--  inject topic numbers, or ensure artifacts in correct paths  -->
 <!-- 4. Anti-Pattern Propagation: Sets bad example for future    -->
 <!--  command development                      -->
 <!--                                 -->
 <!-- CORRECT PATTERN:                         -->
 <!--  /orchestrate → Task(plan-architect) with artifact context   -->
 <!--  NOT: /orchestrate → SlashCommand("/plan")           -->
 <!--                                 -->
 <!-- ENFORCEMENT:                           -->
 <!-- - Validation script: .claude/lib/validate-orchestrate-pattern.sh-->
 <!-- - Runs in test suite: Fails if SlashCommand detected      -->
 <!-- - Code review: Reject PRs violating this pattern        -->
 <!-- ═══════════════════════════════════════════════════════════════ -->
 ```

- [ ] **Add enforcement notes to each phase**
 For Phase 2, 3, 4, 5, add reminder:
 ```markdown
 **ARCHITECTURAL ENFORCEMENT**: DO NOT use SlashCommand tool. Use Task tool only.
 ```

- [ ] **Create validation script**
 Create `/home/benjamin/.config/.claude/lib/validate-orchestrate-pattern.sh`:
 ```bash
 #!/usr/bin/env bash
 # Validate /orchestrate follows architectural pattern
 # CRITICAL: Prevent command-to-command invocations

 set -euo pipefail

 SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 ORCHESTRATE_FILE="${SCRIPT_DIR}/../commands/orchestrate.md"

 echo "Validating /orchestrate architectural pattern..."

 # Check 1: No SlashCommand tool usage
 if grep -q "SlashCommand" "$ORCHESTRATE_FILE"; then
  echo "✗ FAIL: SlashCommand tool detected in orchestrate.md"
  echo ""
  echo "Violations found:"
  grep -n "SlashCommand" "$ORCHESTRATE_FILE"
  echo ""
  echo "ARCHITECTURAL VIOLATION: /orchestrate must NOT invoke other slash commands"
  echo "Use Task tool with direct agent invocations instead"
  exit 1
 else
  echo "✓ PASS: No SlashCommand usage detected"
 fi

 # Check 2: Task tool used for all agents
 TASK_COUNT=$(grep -c "Task {" "$ORCHESTRATE_FILE" || true)
 if [ "$TASK_COUNT" -lt 5 ]; then
  echo "✗ FAIL: Expected at least 5 Task tool invocations (research, plan, implement, debug, doc)"
  echo "Found: $TASK_COUNT"
  exit 1
 else
  echo "✓ PASS: Task tool usage detected ($TASK_COUNT invocations)"
 fi

 # Check 3: Artifact path injection present
 if ! grep -q "artifact_paths" "$ORCHESTRATE_FILE"; then
  echo "✗ FAIL: No artifact path injection detected"
  echo "Agents must receive artifact paths from location-specialist"
  exit 1
 else
  echo "✓ PASS: Artifact path injection present"
 fi

 # Check 4: No direct command names in Task prompts
 FORBIDDEN_PATTERNS=("/plan " "/implement " "/debug " "/document ")
 for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if grep "Task {" -A 20 "$ORCHESTRATE_FILE" | grep -q "$pattern"; then
   echo "✗ FAIL: Slash command '$pattern' found in Task prompt"
   echo "This may indicate command invocation instead of agent invocation"
   exit 1
  fi
 done
 echo "✓ PASS: No slash command invocations in Task prompts"

 echo ""
 echo "═══════════════════════════════════════════════════════════"
 echo "✓ ALL CHECKS PASSED - Architectural pattern validated"
 echo "═══════════════════════════════════════════════════════════"
 exit 0
 ```

- [ ] **Make validation script executable**
 ```bash
 chmod +x /home/benjamin/.config/.claude/lib/validate-orchestrate-pattern.sh
 ```

- [ ] **Integrate into test suite**
 Add to `/home/benjamin/.config/.claude/tests/run_all_tests.sh`:
 ```bash
 # Architectural pattern validation
 echo "Running architectural pattern validation..."
 if bash "$PROJECT_ROOT/.claude/lib/validate-orchestrate-pattern.sh"; then
  echo "✓ Architectural patterns validated"
 else
  echo "✗ Architectural pattern violations detected"
  FAILED_TESTS=$((FAILED_TESTS + 1))
 fi
 ```

- [ ] **Add to CI/CD (if applicable)**
 Create `.github/workflows/validate-architecture.yml` or equivalent

**Testing**:
```bash
# Run validation script
bash /home/benjamin/.config/.claude/lib/validate-orchestrate-pattern.sh

# Expected output:
# ✓ PASS: No SlashCommand usage detected
# ✓ PASS: Task tool usage detected (N invocations)
# ✓ PASS: Artifact path injection present
# ✓ PASS: No slash command invocations in Task prompts
# ✓ ALL CHECKS PASSED

# Test failure detection (negative test)
# Temporarily add "SlashCommand" to orchestrate.md
echo "SlashCommand('/test')" >> /home/benjamin/.config/.claude/commands/orchestrate.md
bash /home/benjamin/.config/.claude/lib/validate-orchestrate-pattern.sh
# Expected: Exit code 1, failure message

# Restore orchestrate.md
git checkout /home/benjamin/.config/.claude/commands/orchestrate.md
```

**Expected Outcomes**:
- Prominent architectural policy documented at top of orchestrate.md
- Enforcement reminders in each phase section
- Validation script created and tested
- Validation integrated into test suite
- CI/CD checks prevent future violations (if applicable)

---

## Phase Completion Checklist

After completing all 6 stages:

- [ ] All 4 SlashCommand invocations removed from orchestrate.md
- [ ] All 4 phases (Planning, Implementation, Debugging, Documentation) use Task tool
- [ ] Artifact path context injected into all agent prompts
- [ ] Verification logic added for each phase (file existence checks)
- [ ] Validation script created and passing
- [ ] Validation script integrated into test suite
- [ ] Architectural policy documented prominently
- [ ] End-to-end test passes: `/orchestrate "Simple feature"` creates artifacts in correct locations

**Final Verification**:
```bash
# Comprehensive verification
cd /home/benjamin/.config

# 1. No SlashCommand usage
! grep -q "SlashCommand" .claude/commands/orchestrate.md
echo "SlashCommand check: $?"

# 2. Validation script passes
bash .claude/lib/validate-orchestrate-pattern.sh
echo "Validation script: $?"

# 3. End-to-end test
/orchestrate "Test feature for Phase 0 validation" --dry-run
# Verify: No SlashCommand usage in execution plan
# Verify: Task tool invocations shown for all phases
# Verify: Artifact paths shown in dry-run output

# 4. Artifact organization check
# (After real execution, not dry-run)
# Verify: Plan created in specs/NNN_topic/plans/
# Verify: No artifacts in arbitrary locations
```

## Success Metrics

- **SlashCommand Elimination**: 0 instances of SlashCommand tool in orchestrate.md
- **Task Tool Adoption**: 100% of agent invocations use Task tool
- **Artifact Organization**: 100% of artifacts in correct `specs/NNN_topic/` structure
- ** [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md)**: 100% of agents receive artifact path context
- **Validation**: Validation script passes with 0 failures
- **Regression Prevention**: Test suite prevents future violations

## Phase Completion

**Mark this phase complete with:**
```bash
# Update plan file
sed -i 's/\[ \] Phase 0:/\[x\] Phase 0:/' /home/benjamin/.config/.claude/specs/plans/080_orchestrate_enhancement.md

# Update parent plan (if exists)
# (Spec-updater will handle this)

# Create git commit
git add .claude/commands/orchestrate.md .claude/lib/validate-orchestrate-pattern.sh
git commit -m "feat(080): complete Phase 0 - Remove command-to-command invocations

- Remove SlashCommand usage from /orchestrate
- Replace /plan, /implement, /debug, /document with direct Task invocations
- Inject artifact path context from location-specialist
- Add validation script to prevent regression
- Document architectural policy prominently

Unblocks all subsequent phases by enabling [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**This phase MUST be completed before proceeding to Phase 1** because all subsequent enhancements (location-specialist, research-synthesizer, complexity-estimator, etc.) rely on [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) working correctly. If commands continue to call other commands via SlashCommand, artifact path context cannot be injected, and the entire orchestration enhancement will fail.
