# Phase 3: Add "EXECUTE NOW" Blocks Throughout /orchestrate

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 001_fix_artifact_management_and_delegation.md
- **Objective**: Convert documentation-style command to imperative execution instructions
- **Complexity**: High
- **Status**: PENDING
- **Estimated Time**: 4-5 hours
- **Files Modified**:
  - `.claude/commands/orchestrate.md` (all major phase sections)

## Overview

This phase transforms `/orchestrate` from a documentation-style description into an actionable execution script. Currently, the command reads like a reference manual ("agents can do X", "consider doing Y") when it should be a sequence of imperative commands ("DO X now", "EXECUTE Y immediately").

**Problem**: AI assistants reading the command file don't know WHEN to execute vs when to simply acknowledge. This causes:
- Phases being skipped or only partially executed
- Uncertainty about what's required vs optional
- Incomplete artifact chains (research done but plan not created, etc.)

**Solution**: Add explicit "EXECUTE NOW" blocks with:
- Clear imperative commands ("DO this", "EXECUTE that")
- Inline tool invocation examples
- Verification checklists after each phase
- Failure conditions and escalation criteria

## Execution Pattern Template

Each phase section will follow this structure:

```markdown
### Phase N: [Phase Name]

[Descriptive context - keep existing overview, ~2-3 paragraphs]

**EXECUTE NOW - [Action Name]**:

[Imperative instruction, 1-2 sentences describing what to do now]

[Numbered step-by-step actions]:
1. [Specific action with tool name]
2. [Next action]
3. [Verification step]

[Inline code example or tool invocation]:
\`\`\`bash
# Executable example
command --with-flags
\`\`\`

OR

\`\`\`markdown
Task {
  subagent_type: "general-purpose"
  description: "Short description"
  prompt: "Detailed instructions..."
}
\`\`\`

**Verification Checklist**:
- [ ] [Expected outcome 1]
- [ ] [Expected outcome 2]
- [ ] [Ready for next phase condition]

If any checkbox unchecked, STOP and complete missing steps before proceeding.

---

[Next section...]
```

## Implementation Tasks

### Task 1: Review Entire /orchestrate Command File

**Objective**: Identify all sections that need "EXECUTE NOW" blocks

**Actions**:
1. Read `.claude/commands/orchestrate.md` completely
2. Mark all descriptive sections (phases, setup, utilities)
3. Identify decision points (conditionals, loops, error handling)
4. Map out execution flow (linear vs branching)

**Expected Findings**:
- ~7 major phases (research, planning, implementation, debugging, documentation, etc.)
- ~10-15 utility sections (path calculation, metadata extraction, etc.)
- ~5 decision points (skip debugging, retry logic, etc.)

**Deliverable**: Annotated copy of orchestrate.md with insertion points marked

---

### Task 2: Add "EXECUTE NOW" Block to Research Phase

**Location**: `.claude/commands/orchestrate.md` (after line ~420, research phase description)

**Current Structure** (approximate):
```markdown
### Phase 1: Research Phase

The research phase analyzes the codebase to gather context. Research agents
explore relevant patterns and identify integration points...

[More description]
```

**Updated Structure**:
```markdown
### Phase 1: Research Phase

The research phase analyzes the codebase to gather context. Research agents
explore relevant patterns and identify integration points...

---

**EXECUTE NOW - Calculate Report Paths**:

Before launching research agents, calculate absolute paths where reports will be created.

1. Identify research topics (2-4 topics from workflow description)
2. For each topic, calculate absolute report path using `get_next_artifact_number()`
3. Store paths in associative array for agent invocation
4. Create topic directories if missing

\`\`\`bash
# Source utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# Identify topics from workflow description
WORKFLOW="[user-provided workflow description]"
TOPICS=(
  "[inferred_topic_1]"
  "[inferred_topic_2]"
  "[inferred_topic_3]"
)

# Calculate absolute paths
declare -A REPORT_PATHS

for topic in "${TOPICS[@]}"; do
  TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/reports/${topic}"
  mkdir -p "$TOPIC_DIR"
  NEXT_NUM=$(get_next_artifact_number "$TOPIC_DIR")
  REPORT_PATHS["$topic"]="${TOPIC_DIR}/${NEXT_NUM}_analysis.md"
  echo "Topic: $topic → ${REPORT_PATHS[$topic]}"
done
\`\`\`

**Verification Checklist**:
- [ ] All topics identified (2-4 topics)
- [ ] Report paths are absolute (start with /)
- [ ] Directories created
- [ ] Paths stored in `REPORT_PATHS` array

If any checkbox unchecked, STOP and resolve before launching agents.

---

**EXECUTE NOW - Launch Research Agents in Parallel**:

Invoke all research agents concurrently using Task tool (single message, multiple calls).

1. For each topic, prepare Task tool invocation with:
   - Absolute report path in prompt
   - "CRITICAL: Create Report File" instructions
   - Expected output format: `REPORT_PATH: [path]`
2. Invoke ALL agents in SINGLE message (true parallelism)
3. Wait for all agents to complete

\`\`\`markdown
[Single message with multiple Task calls]

Task {
  subagent_type: "general-purpose"
  description: "Research [topic_1] with artifact creation"
  prompt: "
    **CRITICAL: Create Report File**
    **Report Path**: [REPORT_PATHS[topic_1]]

    [Research instructions...]

    **Expected Output**:
    REPORT_PATH: [path]
    [1-2 sentence summary]
  "
}

Task {
  subagent_type: "general-purpose"
  description: "Research [topic_2] with artifact creation"
  prompt: "[similar structure]"
}

Task {
  subagent_type: "general-purpose"
  description: "Research [topic_3] with artifact creation"
  prompt: "[similar structure]"
}
\`\`\`

**Verification Checklist**:
- [ ] All agents invoked in single message (parallel execution)
- [ ] Each prompt contains absolute report path
- [ ] Each prompt contains "CRITICAL: Create Report File"
- [ ] All agents completed (no timeouts/errors)

If any agent fails, investigate error and retry with corrected prompt.

---

**EXECUTE NOW - Verify Report Files Created**:

Check that all research agents created report files before proceeding to planning.

1. For each topic, verify file exists at expected path
2. Check file is non-empty (>100 bytes)
3. Search alternative locations if file missing
4. Parse REPORT_PATH from agent output
5. STOP if any report missing (hard failure)

\`\`\`bash
ALL_REPORTS_CREATED=true

for topic in "${!REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${REPORT_PATHS[$topic]}"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "❌ MISSING: $topic report not created"
    ALL_REPORTS_CREATED=false

    # Search alternative locations
    FOUND=$(find "${CLAUDE_PROJECT_DIR}/specs" -name "*${topic}*" -mmin -10)
    [ -n "$FOUND" ] && echo "⚠️  Found at: $FOUND"
  else
    FILE_SIZE=$(stat -c%s "$EXPECTED_PATH" 2>/dev/null)
    [ "$FILE_SIZE" -lt 100 ] && {
      echo "⚠️  WARNING: Report too small (${FILE_SIZE} bytes)"
      ALL_REPORTS_CREATED=false
    }
  fi
done

if [ "$ALL_REPORTS_CREATED" = false ]; then
  echo "❌ CRITICAL: Research phase incomplete. Cannot proceed."
  exit 1
fi

echo "✓ All research reports verified"
\`\`\`

**Verification Checklist**:
- [ ] All report files exist
- [ ] All files non-empty (>100 bytes)
- [ ] REPORT_PATH parsed from agent outputs
- [ ] Report paths stored for planning phase
- [ ] Execution STOPPED if reports missing

If verification fails, DO NOT proceed to planning. Resolve report issues first.

---

[Continue with planning phase...]
```

**Key Changes**:
1. Three distinct "EXECUTE NOW" blocks (path calculation, agent launch, verification)
2. Each block has executable code examples
3. Each block has verification checklist
4. Hard stop conditions clearly specified

---

### Task 3: Add "EXECUTE NOW" Block to Planning Phase

**Location**: `.claude/commands/orchestrate.md` (after line ~612, planning phase description)

**Implementation**:

```markdown
### Phase 2: Planning Phase

The planning phase creates an implementation plan using research findings...

[Keep existing description]

---

**EXECUTE NOW - Delegate Planning to plan-architect Agent**:

Invoke plan-architect agent to create implementation plan with research report integration.

1. Prepare report paths array (from research phase)
2. Invoke Task tool with plan-architect behavioral guidelines
3. Agent internally calls SlashCommand(/plan) with report paths
4. Wait for agent completion and plan file creation

\`\`\`markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with research integration"
  prompt: "
    Read and follow: .claude/agents/plan-architect.md

    ## Planning Task

    ### Context
    - Workflow: [user-provided description]
    - Thinking Mode: [sequential|parallel]
    - Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

    ### Research Reports Available
    [For each report path from research phase]
    - [REPORT_PATH_1]
    - [REPORT_PATH_2]
    - [REPORT_PATH_3]

    Use Read tool to access report content.

    ### Your Task
    1. Read all research reports
    2. Synthesize findings into plan context
    3. Invoke SlashCommand: /plan \"[description]\" [report_path1] [report_path2] [report_path3]
    4. Verify plan file created
    5. Return: PLAN_PATH: /absolute/path/to/plan.md

    ## Expected Output
    PLAN_PATH: [path]
    Brief summary (1-2 sentences)
  "
}
\`\`\`

**Verification Checklist**:
- [ ] plan-architect agent invoked (not direct /plan)
- [ ] All research report paths passed to agent
- [ ] Agent completed successfully
- [ ] PLAN_PATH returned in agent output

If agent fails, investigate error. DO NOT invoke /plan directly.

---

**EXECUTE NOW - Verify Plan File Created**:

Check that plan-architect created plan file with proper research cross-references.

1. Parse PLAN_PATH from agent output
2. Verify file exists at expected path
3. Verify plan references research reports (grep for report filenames)
4. Store plan path for implementation phase

\`\`\`bash
# Parse PLAN_PATH from agent output
PLAN_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'PLAN_PATH:\s*\K/.+' | head -1)

if [ -z "$PLAN_PATH" ]; then
  echo "❌ ERROR: Agent did not return PLAN_PATH"
  exit 1
fi

# Verify file exists
if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ ERROR: Plan file not created: $PLAN_PATH"
  exit 1
fi

# Verify plan references research reports
REPORT_REFS=$(grep -c "specs/reports/" "$PLAN_PATH" || echo 0)
if [ "$REPORT_REFS" -lt 2 ]; then
  echo "⚠️  WARNING: Plan doesn't reference research reports ($REPORT_REFS refs)"
fi

# Store for implementation phase
export PLAN_FILE="$PLAN_PATH"
echo "✓ Plan file verified: $PLAN_PATH"
\`\`\`

**Verification Checklist**:
- [ ] PLAN_PATH extracted from agent output
- [ ] Plan file exists
- [ ] Plan references ≥2 research reports
- [ ] Plan path stored for implementation

If plan file missing or invalid, retry plan-architect with corrected prompt.

---

[Continue with implementation phase...]
```

---

### Task 4: Add "EXECUTE NOW" Block to Implementation Phase

**Location**: `.claude/commands/orchestrate.md` (after line ~728, implementation phase description)

**Implementation**:

```markdown
### Phase 3: Implementation Phase

The implementation phase executes the plan phase-by-phase with automated testing...

[Keep existing description]

---

**EXECUTE NOW - Delegate Implementation to code-writer Agent**:

Invoke code-writer agent to execute implementation plan with /implement command.

1. Pass plan path from planning phase
2. Set timeout to 600000ms (10 minutes) for long-running implementations
3. Agent internally calls SlashCommand(/implement) with plan path
4. Wait for agent completion and implementation status

\`\`\`markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan phase-by-phase"
  timeout: 600000
  prompt: "
    Read and follow: .claude/agents/code-writer.md

    ## Implementation Task

    ### Plan File
    ${PLAN_FILE}

    ### Your Task
    1. Read the implementation plan
    2. Invoke SlashCommand: /implement ${PLAN_FILE}
    3. Monitor phase-by-phase execution
    4. Report test results after each phase
    5. Return: Implementation status + files modified

    ## Expected Output
    - Implementation status: SUCCESS|PARTIAL|FAILED
    - Phases completed: N/M
    - Test results: PASS|FAIL (details)
    - Files modified: [list]
  "
}
\`\`\`

**Verification Checklist**:
- [ ] code-writer agent invoked (not direct /implement)
- [ ] Plan path passed correctly
- [ ] Timeout set to 600000ms (10 minutes)
- [ ] Agent completed successfully

If agent times out, check progress and resume from last completed phase.

---

**EXECUTE NOW - Parse Test Results**:

Extract test results from implementation agent output to determine if debugging needed.

1. Parse agent output for test status
2. Count passed/failed tests
3. Extract failure details (if any)
4. Decide if debugging phase required

\`\`\`bash
# Parse test status from agent output
TEST_STATUS=$(echo "$AGENT_OUTPUT" | grep -oP 'Test results:\s*\K\w+' | head -1)
PHASES_COMPLETED=$(echo "$AGENT_OUTPUT" | grep -oP 'Phases completed:\s*\K\d+' | head -1)
TOTAL_PHASES=$(echo "$AGENT_OUTPUT" | grep -oP 'Phases completed:\s*\d+/\K\d+' | head -1)

echo "Implementation Results:"
echo "  Status: $TEST_STATUS"
echo "  Phases: $PHASES_COMPLETED/$TOTAL_PHASES"

# Check if debugging needed
DEBUGGING_REQUIRED=false

if [ "$TEST_STATUS" = "FAIL" ]; then
  DEBUGGING_REQUIRED=true
  echo "  ⚠️  Tests failed - debugging required"

  # Extract failure details
  FAILURE_DETAILS=$(echo "$AGENT_OUTPUT" | sed -n '/Test failures:/,/Files modified:/p')
  echo "$FAILURE_DETAILS"
fi

if [ "$PHASES_COMPLETED" -lt "$TOTAL_PHASES" ]; then
  echo "  ⚠️  Incomplete implementation - $((TOTAL_PHASES - PHASES_COMPLETED)) phases remaining"
fi

export DEBUGGING_REQUIRED
export TEST_FAILURES="$FAILURE_DETAILS"
\`\`\`

**Verification Checklist**:
- [ ] Test status parsed (PASS/FAIL)
- [ ] Phase completion tracked
- [ ] Failure details extracted (if any)
- [ ] Debugging decision made

If tests failed, proceed to debugging phase. If tests passed, skip to documentation.

---

[Continue with debugging phase...]
```

---

### Task 5: Add "EXECUTE NOW" Block to Debugging Loop

**Location**: `.claude/commands/orchestrate.md` (after line ~1000, debugging phase description)

**Implementation**:

```markdown
### Phase 4: Debugging Loop (Conditional)

The debugging phase is invoked only if tests fail during implementation...

[Keep existing description]

---

**EXECUTE NOW - Check If Debugging Required**:

Decide whether to invoke debugging based on test results from implementation.

1. Check `DEBUGGING_REQUIRED` flag from implementation phase
2. If false, skip debugging and proceed to documentation
3. If true, continue to debug-specialist invocation

\`\`\`bash
if [ "$DEBUGGING_REQUIRED" = false ]; then
  echo "✓ All tests passed - skipping debugging phase"
  # Jump to documentation phase
else
  echo "⚠️  Debugging required - invoking debug-specialist"
  # Continue to debug-specialist invocation
fi
\`\`\`

**Verification Checklist**:
- [ ] `DEBUGGING_REQUIRED` flag checked
- [ ] Decision logged (skip vs invoke)

Proceed based on decision.

---

**EXECUTE NOW - Invoke debug-specialist Agent** (if debugging required):

Launch debug-specialist to investigate test failures and propose fixes.

1. Pass test failure details from implementation
2. Pass plan file for context
3. Agent creates debug report with root cause analysis
4. Agent proposes fixes

\`\`\`markdown
Task {
  subagent_type: "general-purpose"
  description: "Debug test failures and propose fixes"
  prompt: "
    Read and follow: .claude/agents/debug-specialist.md

    ## Debugging Task

    ### Context
    - Plan: ${PLAN_FILE}
    - Implementation status: Tests FAILED

    ### Test Failures
    ${TEST_FAILURES}

    ### Your Task
    1. Analyze test failure patterns
    2. Investigate root causes (read relevant files)
    3. Create debug report at: specs/debug/[NNN]_test_failures.md
    4. Propose fixes for each failure
    5. Return: DEBUG_REPORT_PATH: [path]

    ## Expected Output
    DEBUG_REPORT_PATH: [path]
    Brief summary of root cause (1-2 sentences)
  "
}
\`\`\`

**Verification Checklist**:
- [ ] debug-specialist invoked with failure details
- [ ] Agent completed successfully
- [ ] DEBUG_REPORT_PATH returned

If agent fails, manually investigate failures.

---

**EXECUTE NOW - Apply Debug Fixes**:

Review debug-specialist recommendations and apply fixes.

1. Read debug report
2. Review proposed fixes
3. Apply fixes to implementation
4. Re-run tests (/implement --resume)
5. Iterate if tests still fail (max 3 iterations)

\`\`\`bash
# Iteration counter
DEBUG_ITERATION=0
MAX_DEBUG_ITERATIONS=3

while [ "$DEBUGGING_REQUIRED" = true ] && [ "$DEBUG_ITERATION" -lt "$MAX_DEBUG_ITERATIONS" ]; do
  ((DEBUG_ITERATION++))

  echo "Debug iteration $DEBUG_ITERATION/$MAX_DEBUG_ITERATIONS"

  # Apply fixes from debug report
  # [Implementation of fix application]

  # Re-run tests
  TEST_RESULT=$(/implement --resume --test-only)

  # Check if tests now pass
  if echo "$TEST_RESULT" | grep -q "All tests passed"; then
    DEBUGGING_REQUIRED=false
    echo "✓ Tests passed after fixes"
  else
    echo "⚠️  Tests still failing, re-invoking debug-specialist"
    # Continue loop
  fi
done

if [ "$DEBUGGING_REQUIRED" = true ]; then
  echo "❌ ERROR: Tests still failing after $MAX_DEBUG_ITERATIONS iterations"
  echo "Manual intervention required"
  exit 1
fi
\`\`\`

**Verification Checklist**:
- [ ] Debug fixes applied
- [ ] Tests re-run
- [ ] Iteration limit enforced (max 3)
- [ ] Manual escalation if limit exceeded

If tests pass, proceed to documentation. If limit exceeded, escalate to user.

---

[Continue with documentation phase...]
```

---

### Task 6: Add "EXECUTE NOW" Block to Documentation Phase

**Location**: `.claude/commands/orchestrate.md` (after line ~1465, documentation phase description)

**Implementation**:

```markdown
### Phase 5: Documentation Phase

The documentation phase updates relevant documentation based on implementation changes...

[Keep existing description]

---

**EXECUTE NOW - Delegate Documentation to doc-writer Agent**:

Invoke doc-writer agent to update documentation and create workflow summary.

1. Pass implementation details (files modified, features added)
2. Pass plan and report references
3. Agent updates relevant documentation files
4. Agent creates workflow summary in specs/summaries/

\`\`\`markdown
Task {
  subagent_type: "general-purpose"
  description: "Update documentation and create workflow summary"
  prompt: "
    Read and follow: .claude/agents/doc-writer.md

    ## Documentation Task

    ### Context
    - Plan: ${PLAN_FILE}
    - Research reports: [list REPORT_PATHS]
    - Implementation complete: [files modified]

    ### Your Task
    1. Invoke SlashCommand: /document \"[change description]\" --scope auto
    2. Create workflow summary at: specs/summaries/[NNN]_workflow_summary.md
    3. Include: Overview, artifacts created, metrics, lessons learned
    4. Return: SUMMARY_PATH: [path]

    ## Expected Output
    SUMMARY_PATH: [path]
    Brief summary (1-2 sentences)
  "
}
\`\`\`

**Verification Checklist**:
- [ ] doc-writer agent invoked
- [ ] Documentation updates completed
- [ ] Workflow summary created
- [ ] SUMMARY_PATH returned

If agent fails, manually create workflow summary.

---

**EXECUTE NOW - Verify Workflow Summary Created**:

Check that workflow summary exists and contains all required sections.

1. Parse SUMMARY_PATH from agent output
2. Verify file exists
3. Verify required sections present (Overview, Artifacts, Metrics, Lessons)
4. Report final artifact chain

\`\`\`bash
# Parse SUMMARY_PATH
SUMMARY_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'SUMMARY_PATH:\s*\K/.+' | head -1)

if [ ! -f "$SUMMARY_PATH" ]; then
  echo "❌ ERROR: Workflow summary not created"
  exit 1
fi

# Verify required sections
REQUIRED_SECTIONS=("Overview" "Artifacts" "Metrics" "Lessons")
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$SUMMARY_PATH"; then
    echo "⚠️  WARNING: Missing section: $section"
  fi
done

# Report complete artifact chain
echo ""
echo "✓ /orchestrate workflow complete!"
echo ""
echo "Artifacts Created:"
echo "  Research reports:"
for path in "${!REPORT_PATHS[@]}"; do
  echo "    - ${REPORT_PATHS[$path]}"
done
echo "  Implementation plan: ${PLAN_FILE}"
echo "  Workflow summary: ${SUMMARY_PATH}"
echo ""
\`\`\`

**Verification Checklist**:
- [ ] Workflow summary exists
- [ ] All required sections present
- [ ] Complete artifact chain verified
- [ ] Results reported to user

/orchestrate workflow complete.
```

---

### Task 7: Add Verification Checklists After Each Phase

**Pattern**: After every "EXECUTE NOW" block, add verification checklist

**Template**:
```markdown
**Verification Checklist**:
- [ ] [Expected outcome 1]
- [ ] [Expected outcome 2]
- [ ] [Expected outcome 3]
- [ ] [Ready for next phase]

If any checkbox unchecked, STOP and complete missing steps before proceeding.
```

**Examples by Phase**:

**Research Phase**:
```markdown
**Verification Checklist**:
- [ ] All report files created at expected paths
- [ ] All reports non-empty (>100 bytes)
- [ ] REPORT_PATH parsed from agent outputs
- [ ] Context usage <10k tokens (not 308k+)
- [ ] Ready to proceed to planning

If any checkbox unchecked, STOP and resolve research issues first.
```

**Planning Phase**:
```markdown
**Verification Checklist**:
- [ ] Plan file created
- [ ] Plan references ≥2 research reports
- [ ] Plan has ≥3 phases
- [ ] PLAN_PATH stored for implementation
- [ ] Ready to proceed to implementation

If any checkbox unchecked, STOP and resolve planning issues first.
```

**Implementation Phase**:
```markdown
**Verification Checklist**:
- [ ] All phases executed
- [ ] Tests run (passed or failed)
- [ ] Test results parsed
- [ ] Debugging decision made
- [ ] Ready to proceed to debugging OR documentation

If implementation incomplete, DO NOT proceed.
```

**Debugging Phase**:
```markdown
**Verification Checklist**:
- [ ] Debug report created
- [ ] Root causes identified
- [ ] Fixes proposed and applied
- [ ] Tests re-run after fixes
- [ ] Tests now passing OR iteration limit reached
- [ ] Ready to proceed to documentation

If tests still failing after 3 iterations, escalate to user.
```

**Documentation Phase**:
```markdown
**Verification Checklist**:
- [ ] Documentation updated
- [ ] Workflow summary created
- [ ] Summary contains all required sections
- [ ] Complete artifact chain verified
- [ ] Workflow complete

If workflow summary missing, manually create before completing.
```

---

### Task 8: Add Failure Conditions and Escalation Criteria

**Objective**: Specify when to stop, retry, or escalate

**Pattern**: After each verification checklist, add failure handling

**Template**:
```markdown
**If Verification Fails**:
- **Stop condition**: [What indicates this phase cannot continue]
- **Retry logic**: [When to retry automatically, max attempts]
- **Escalation**: [When to ask user for help]

Example:
- Stop if report files don't exist after agent completion
- Retry agent once if timeout occurs
- Escalate if agent fails twice with different errors
```

**Examples**:

**Research Phase Failure Handling**:
```markdown
**If Report Verification Fails**:
- **Stop**: If ≥1 report file missing after agent completion
- **Retry**: Re-invoke agent with corrected prompt (max 1 retry per agent)
- **Search**: Check alternative locations (specs/reports/*/) for misplaced files
- **Escalate**: If retry fails, ask user to manually verify research requirements

DO NOT proceed to planning if reports missing.
```

**Planning Phase Failure Handling**:
```markdown
**If Plan Creation Fails**:
- **Stop**: If plan-architect agent returns error or timeout
- **Retry**: Re-invoke with extended timeout (max 1 retry)
- **Fallback**: Direct /plan invocation as last resort (log this as degraded mode)
- **Escalate**: If direct /plan also fails, ask user to clarify requirements

DO NOT proceed to implementation without valid plan file.
```

**Implementation Phase Failure Handling**:
```markdown
**If Implementation Fails**:
- **Partial Success**: If some phases complete, store checkpoint
- **Resume**: Support --resume flag to continue from checkpoint
- **Timeout**: If agent times out, check progress and resume
- **Escalate**: If <50% phases complete, ask user if scope too large

Partial implementation is acceptable if checkpointed correctly.
```

**Debugging Phase Failure Handling**:
```markdown
**If Debugging Fails to Fix Tests**:
- **Iteration Limit**: Max 3 debug iterations (prevents infinite loop)
- **Escalate**: After 3 iterations, provide debug report to user
- **Manual Fix**: User can fix manually and re-run /orchestrate --resume
- **Threshold**: If >50% tests still failing after 3 iterations, stop

Manual intervention required after iteration limit.
```

---

### Task 9: Add Inline Tool Invocation Examples Throughout

**Objective**: Provide copy-paste ready examples for every tool use

**Examples to Add**:

**Bash Utilities**:
```bash
# Source utilities (at beginning of each phase)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/detect-project-dir.sh"
```

**Task Tool Invocation**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Brief description (5-10 words)"
  timeout: 120000  # Optional, milliseconds (default: 120s, max: 600s)
  prompt: "
    [Agent instructions]
  "
}
```

**SlashCommand Invocation** (by agents, not orchestrator):
```markdown
SlashCommand {
  command: "/plan \"Feature description\" path/to/report1.md path/to/report2.md"
}

SlashCommand {
  command: "/implement path/to/plan.md --starting-phase 3"
}

SlashCommand {
  command: "/document \"Implementation complete\" --scope auto"
}
```

**Metadata Extraction**:
```bash
# Extract report metadata (forward_message pattern)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

METADATA=$(extract_report_metadata "/path/to/report.md")
TITLE=$(echo "$METADATA" | jq -r '.title')
SUMMARY=$(echo "$METADATA" | jq -r '.summary')  # ~50 words
```

**Parallel Agent Invocation**:
```markdown
# CORRECT: Single message, multiple Task calls (parallel)
Task {...}
Task {...}
Task {...}

# WRONG: Sequential invocations (not parallel)
Task {...}
[wait for result]
Task {...}
[wait for result]
```

---

### Task 10: Document Decision Points and Branching Logic

**Objective**: Make conditional logic explicit

**Examples**:

**Debugging Decision**:
```markdown
**Decision Point: Skip or Invoke Debugging?**

\`\`\`bash
if [ "$TEST_STATUS" = "PASS" ] || [ "$DEBUGGING_REQUIRED" = false ]; then
  echo "→ Tests passed, skipping debugging phase"
  # Jump to Phase 5: Documentation
else
  echo "→ Tests failed, invoking debugging phase"
  # Continue to Phase 4: Debugging
fi
\`\`\`

**Criteria**:
- Skip debugging if: All tests passed
- Invoke debugging if: Any test failed OR implementation incomplete
```

**Thinking Mode Decision**:
```markdown
**Decision Point: Sequential or Parallel Thinking?**

\`\`\`bash
THINKING_MODE="sequential"  # Default

# Check workflow for parallelizable phases
if echo "$WORKFLOW" | grep -qiE "parallel|concurrent|independent"; then
  THINKING_MODE="parallel"
  echo "→ Parallel thinking mode enabled"
fi
\`\`\`

**Criteria**:
- Parallel: If workflow mentions parallel execution or has independent phases
- Sequential: Default for most workflows
```

---

### Task 11: Add "Continue from Here" Markers

**Objective**: Help AI know where to resume after each phase

**Pattern**:
```markdown
---

### Phase N Complete

✓ Phase N: [Name] complete

**Artifacts Created**:
- [List files created in this phase]

**Next Phase**: Phase N+1: [Name]

---

### Phase N+1: [Name]

[Continue with next phase...]
```

**Rationale**:
- Clear phase boundaries
- Explicit "next phase" pointer
- Artifact list for reference

---

### Task 12: Validate "EXECUTE NOW" Block Coverage

**Objective**: Ensure no major section is missing execution instructions

**Validation Script**:
```bash
#!/bin/bash
# Validate EXECUTE NOW block coverage in orchestrate.md

COMMAND_FILE=".claude/commands/orchestrate.md"

# Count total phases
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$COMMAND_FILE")

# Count EXECUTE NOW blocks
EXECUTE_BLOCKS=$(grep -c "EXECUTE NOW" "$COMMAND_FILE")

# Count verification checklists
VERIFY_CHECKLISTS=$(grep -c "Verification Checklist" "$COMMAND_FILE")

echo "Coverage Analysis:"
echo "  Total phases: $TOTAL_PHASES"
echo "  EXECUTE NOW blocks: $EXECUTE_BLOCKS"
echo "  Verification checklists: $VERIFY_CHECKLISTS"
echo ""

# Expected: At least 15 EXECUTE NOW blocks (3 per major phase x 5 phases)
if [ "$EXECUTE_BLOCKS" -lt 15 ]; then
  echo "❌ FAIL: Insufficient EXECUTE NOW blocks (need ≥15)"
  exit 1
fi

# Expected: At least 5 verification checklists (1 per major phase)
if [ "$VERIFY_CHECKLISTS" -lt 5 ]; then
  echo "❌ FAIL: Insufficient verification checklists (need ≥5)"
  exit 1
fi

echo "✓ PASS: Coverage requirements met"
exit 0
```

**Run After Implementation**:
```bash
.claude/lib/validate-orchestrate.sh
```

---

### Task 13: Update Descriptive Sections to Reference Execution Blocks

**Objective**: Link descriptions to execution instructions

**Pattern**:
```markdown
### Phase N: [Name]

[Descriptive overview]

**Implementation**: See "EXECUTE NOW" blocks below for step-by-step execution.

---

**EXECUTE NOW - [Action]**:
[Execution instructions]
```

**Rationale**:
- Descriptions provide context ("why")
- EXECUTE NOW blocks provide actions ("what" and "how")
- Clear separation between explanation and execution

---

### Task 14: Add Phase Transition Logging

**Objective**: Make phase transitions visible for debugging

**Pattern**:
```bash
echo ""
echo "============================================"
echo "Phase N: [Name]"
echo "============================================"
echo ""

# Phase execution...

echo ""
echo "Phase N complete ✓"
echo ""
```

**Benefits**:
- Clear phase boundaries in logs
- Easy to identify which phase failed
- Audit trail for workflow execution

---

### Task 15: Create Comprehensive Example Workflow

**Objective**: Provide end-to-end example showing all "EXECUTE NOW" blocks in action

**Location**: Add to end of orchestrate.md as "Example Execution" section

**Content**:
```markdown
## Example Execution

This example shows how /orchestrate executes for a typical workflow.

**Workflow**: "Add user authentication with OAuth integration"

### Execution Trace

\`\`\`
→ Phase 1: Research Phase

EXECUTE NOW - Calculate Report Paths:
  Topic: oauth_patterns → /claude/specs/reports/oauth_patterns/001_analysis.md
  Topic: session_management → /claude/specs/reports/session_management/002_analysis.md
  ✓ Paths calculated

EXECUTE NOW - Launch Research Agents:
  [Task tool invocations for both topics in single message]
  ✓ Agents completed

EXECUTE NOW - Verify Reports:
  ✓ oauth_patterns report created (5432 bytes)
  ✓ session_management report created (6218 bytes)
  ✓ All reports verified

Phase 1 complete ✓

---

→ Phase 2: Planning Phase

EXECUTE NOW - Delegate to plan-architect:
  [Task tool invocation]
  ✓ Agent completed
  PLAN_PATH: /claude/specs/plans/042_oauth_auth.md

EXECUTE NOW - Verify Plan:
  ✓ Plan file exists
  ✓ References 2 research reports
  ✓ Plan has 6 phases

Phase 2 complete ✓

---

→ Phase 3: Implementation Phase

EXECUTE NOW - Delegate to code-writer:
  [Task tool invocation with 600s timeout]
  ✓ Agent completed
  Phases: 6/6 complete
  Tests: PASS

EXECUTE NOW - Parse Test Results:
  Test status: PASS
  Debugging required: false
  → Skipping debugging phase

Phase 3 complete ✓

---

→ Phase 4: Debugging Phase (SKIPPED)

Tests passed - skipping debugging

---

→ Phase 5: Documentation Phase

EXECUTE NOW - Delegate to doc-writer:
  [Task tool invocation]
  ✓ Agent completed
  SUMMARY_PATH: /claude/specs/summaries/042_oauth_summary.md

EXECUTE NOW - Verify Summary:
  ✓ Summary file exists
  ✓ All required sections present

Phase 5 complete ✓

---

✓ /orchestrate workflow complete!

Artifacts Created:
  Research reports:
    - /claude/specs/reports/oauth_patterns/001_analysis.md
    - /claude/specs/reports/session_management/002_analysis.md
  Implementation plan:
    - /claude/specs/plans/042_oauth_auth.md
  Workflow summary:
    - /claude/specs/summaries/042_oauth_summary.md

Total time: ~15 minutes
Context usage: 28k tokens (vs 450k+ without hierarchical agents)
\`\`\`
```

---

## Testing Specification

### Test Case 1: EXECUTE NOW Block Presence

```bash
test_execute_now_coverage() {
  local execute_count=$(grep -c "EXECUTE NOW" .claude/commands/orchestrate.md)

  if [ $execute_count -ge 15 ]; then
    echo "PASS: Found $execute_count EXECUTE NOW blocks (≥15)"
    return 0
  else
    echo "FAIL: Found $execute_count EXECUTE NOW blocks (need ≥15)"
    return 1
  fi
}
```

### Test Case 2: Verification Checklist Presence

```bash
test_verification_checklists() {
  local checklist_count=$(grep -c "Verification Checklist" .claude/commands/orchestrate.md)

  if [ $checklist_count -ge 5 ]; then
    echo "PASS: Found $checklist_count checklists (≥5)"
    return 0
  else
    echo "FAIL: Found $checklist_count checklists (need ≥5)"
    return 1
  fi
}
```

### Test Case 3: Inline Examples Present

```bash
test_inline_examples() {
  local bash_examples=$(grep -c '```bash' .claude/commands/orchestrate.md)
  local task_examples=$(grep -c 'Task {' .claude/commands/orchestrate.md)

  if [ $bash_examples -ge 10 ] && [ $task_examples -ge 5 ]; then
    echo "PASS: Found $bash_examples bash examples, $task_examples Task examples"
    return 0
  else
    echo "FAIL: Insufficient examples (bash: $bash_examples, Task: $task_examples)"
    return 1
  fi
}
```

### Test Case 4: Failure Handling Documented

```bash
test_failure_handling() {
  local failure_sections=$(grep -c "If.*Fails" .claude/commands/orchestrate.md)

  if [ $failure_sections -ge 5 ]; then
    echo "PASS: Found $failure_sections failure handling sections (≥5)"
    return 0
  else
    echo "FAIL: Found $failure_sections failure sections (need ≥5)"
    return 1
  fi
}
```

### Integration Test: Execute /orchestrate with Updated Structure

```bash
test_orchestrate_execution() {
  echo "Integration Test: /orchestrate with EXECUTE NOW blocks"

  # Run /orchestrate with simple workflow
  WORKFLOW="Test simple CRUD feature"
  OUTPUT=$(/orchestrate "$WORKFLOW" 2>&1)

  # Check for phase execution markers
  echo "$OUTPUT" | grep -q "Phase 1: Research" || {
    echo "FAIL: Research phase not executed"
    return 1
  }

  echo "$OUTPUT" | grep -q "Phase 2: Planning" || {
    echo "FAIL: Planning phase not executed"
    return 1
  }

  echo "$OUTPUT" | grep -q "EXECUTE NOW" || {
    echo "FAIL: EXECUTE NOW blocks not being followed"
    return 1
  }

  # Check for verification checkpoints
  echo "$OUTPUT" | grep -q "Verification Checklist" || {
    echo "FAIL: Verification checklists not being used"
    return 1
  }

  echo "PASS: /orchestrate execution follows imperative structure"
  return 0
}
```

## Validation Checklist

After implementation, verify:

- [ ] All 5 major phases have ≥3 "EXECUTE NOW" blocks each (total ≥15)
- [ ] Each "EXECUTE NOW" block has inline code example
- [ ] Each phase has verification checklist
- [ ] Failure conditions documented for each phase
- [ ] Phase transitions are logged
- [ ] Decision points have explicit branching logic
- [ ] Tool invocation examples are executable (copy-paste ready)
- [ ] Example workflow execution trace provided
- [ ] Validation script passes (≥15 EXECUTE blocks, ≥5 checklists)
- [ ] Integration test shows phases being executed in order

## Success Metrics

**Before Implementation:**
- Command structure: Documentation-style descriptions
- Execution clarity: Ambiguous (AI unsure when to act)
- Phase completion: Inconsistent (phases skipped)
- Failure handling: Implicit (AI guesses what to do)

**After Implementation:**
- Command structure: Imperative execution instructions
- Execution clarity: Explicit "EXECUTE NOW" commands
- Phase completion: Consistent (verification enforced)
- Failure handling: Explicit (stop/retry/escalate documented)

## Dependencies

### No New Utilities Required
- All utilities already exist (artifact-operations.sh, etc.)
- Only orchestrate.md is modified

### Agent Compatibility
- Verify agents (research-specialist, plan-architect, code-writer, debug-specialist, doc-writer) are compatible with Task tool invocation patterns

## Risk Mitigation

**Risk**: Command becomes too rigid, loses flexibility
**Mitigation**:
- Keep descriptive context for "why" (understanding)
- Add "EXECUTE NOW" blocks for "what" and "how" (action)
- Decision points allow conditional branching

**Risk**: Too many verification checkpoints slow execution
**Mitigation**:
- Checkpoints prevent cascade failures (saves time overall)
- Fast checks (file existence, simple parsing)
- Only stop on critical failures (missing artifacts)

**Risk**: Examples become outdated as code evolves
**Mitigation**:
- Use generic examples (not specific to current code)
- Reference utilities by function name (not implementation)
- Test examples during validation

## Next Steps

After Phase 3 completes:
1. Run validation script (.claude/lib/validate-orchestrate.sh)
2. Run integration test (test_orchestrate_execution)
3. Execute /orchestrate with real workflow to verify behavior
4. Proceed to Phase 4 (Test Suite and Validation)

## Notes

- This phase has broadest scope (affects all of orchestrate.md)
- Most impactful for AI execution consistency
- Lays foundation for reliable agent coordination
- Pattern can be applied to other commands (/report, /debug, /implement)
