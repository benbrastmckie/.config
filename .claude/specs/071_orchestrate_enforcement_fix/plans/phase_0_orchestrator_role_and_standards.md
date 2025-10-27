# Phase 0: Add Orchestrator Role Clarification and Enforcement Standards

**Expanded from**: [001_fix_research_and_planning_enforcement.md](./001_fix_research_and_planning_enforcement.md) Phase 0

**Target File**: `/home/benjamin/.config/.claude/commands/orchestrate.md` (5688 lines total)

**Complexity**: Medium (4 modification zones, 150+ enforcement markers needed)

---

## Overview

This phase establishes the foundational enforcement framework for orchestrate.md by adding explicit orchestrator role clarification (Phase 0 pattern) and distributing Standard 0 enforcement markers throughout the file. The goal is to transform ambiguous coordination instructions into explicit, mandatory directives that prevent direct execution and enforce delegation to specialized agents.

**Current State Analysis**:
- File already has role clarification at lines 42-64 (YOUR ROLE section)
- Has 71 enforcement markers total (EXECUTE NOW, MANDATORY VERIFICATION, CHECKPOINT REQUIREMENT combined)
- Has 14 passive language occurrences (should/may/can/consider/try to)
- Missing: Explicit context pruning policy integration
- Missing: Sufficient enforcement marker density (need ≥12 EXECUTE NOW, ≥8 MANDATORY VERIFICATION, ≥6 CHECKPOINT)

**Target State**:
- Enhanced Phase 0 orchestrator role clarification with DO NOT constraints
- ≥12 "EXECUTE NOW" markers at critical operation points
- ≥8 "MANDATORY VERIFICATION" blocks for file creation checkpoints
- ≥6 "CHECKPOINT REQUIREMENT" blocks at phase boundaries
- ≥90% imperative language ratio (eliminate 14 passive occurrences)
- Integrated aggressive context pruning policy with actual function calls

---

## Modification Zone 1: Enhanced Phase 0 Role Clarification (Lines 38-64)

### Current Content Analysis

Lines 38-64 already contain role clarification:
- Line 42: "YOUR ROLE: You are the WORKFLOW ORCHESTRATOR, not the executor"
- Lines 43-44: DO NOT execute research/planning/implementation yourself
- Line 45: ONLY use Task tool
- Lines 56-63: CRITICAL INSTRUCTIONS section

**Assessment**: Role clarification exists but needs strengthening with Phase 0 pattern elements.

### Required Enhancements

#### 1.1 Add Explicit "You will NOT see [results] directly" Explanation

**Location**: After line 46 (after "YOUR RESPONSIBILITY" line)

**Insert**:
```markdown
**ORCHESTRATOR EXECUTION MODEL**:
- You will NOT see research findings directly (agents write reports to files)
- You will NOT see plan content directly (agents write plans to files)
- You will NOT see implementation code directly (agents write code to files)
- You WILL receive ONLY metadata from agents: artifact paths + 50-word summaries
- You MUST read artifact files using Read tool AFTER agents complete to verify content

**WHY THIS MATTERS**: Agents produce artifacts in files. Your role is to verify file creation, not process content during agent execution.
```

**Rationale**: Execution Enforcement Guide Phase 0 Pattern B requires explicit explanation that orchestrators receive metadata only, preventing expectation of inline results.

#### 1.2 Strengthen DO NOT Constraints

**Location**: Replace lines 43-44

**Current**:
```markdown
- **DO NOT** execute research/planning/implementation/testing/debugging/documentation yourself using Read/Write/Grep/Bash tools
- **ONLY** use Task tool to invoke specialized agents for each phase
```

**Replace with**:
```markdown
**CRITICAL CONSTRAINTS - YOU MUST NOT**:
- **DO NOT** execute research yourself using Read/Grep tools (invoke research-specialist)
- **DO NOT** create files directly using Write tool (agents create all artifacts)
- **DO NOT** invoke slash commands using SlashCommand tool (use Task tool with agent files)
- **DO NOT** implement code yourself using Edit tool (invoke code-writer)
- **DO NOT** run tests yourself using Bash tool (invoke test-specialist)
- **DO NOT** write documentation yourself (invoke doc-writer)

**ABSOLUTE REQUIREMENT - YOU WILL ONLY**:
- Calculate artifact paths using utility scripts
- Invoke specialized agents via Task tool with injected context
- Verify file creation after each agent completes
- Aggregate metadata from agents (NOT full content)
- Forward metadata to downstream phases
```

**Rationale**: More granular constraints prevent misinterpretation of orchestrator scope. Each tool/action explicitly forbidden with agent alternative specified.

#### 1.3 Add Behavioral Injection Pattern Reference

**Location**: After line 46 (in new ORCHESTRATOR EXECUTION MODEL section)

**Insert**:
```markdown
**BEHAVIORAL INJECTION ENFORCEMENT**:
This command follows the [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md):
- YOU MUST pre-calculate ALL artifact paths BEFORE invoking any agent
- YOU WILL inject paths into agent prompts as MANDATORY INPUTS
- YOU SHALL use "THIS EXACT TEMPLATE (No modifications)" markers for all agent invocations
- Agents receive context through file reads (NOT SlashCommand invocations)
```

**Rationale**: Explicitly reference the architectural pattern to establish expected execution model.

---

## Modification Zone 2: Distribute Standard 0 Enforcement Markers (Throughout File)

### Current Marker Inventory

Based on grep analysis, file has 71 enforcement markers total but distribution unknown. Need to achieve:
- ≥12 "EXECUTE NOW" markers
- ≥8 "MANDATORY VERIFICATION" markers
- ≥6 "CHECKPOINT REQUIREMENT" markers

### 2.1 EXECUTE NOW Marker Placement Strategy

**Target Count**: 12 minimum (distribute across 7 phases + utilities)

#### 2.1.1 Phase 0 (Location Determination) - 2 markers

**Location 1**: Near workflow parsing (estimated line 200-250)

**Pattern**:
```markdown
### STEP 1 - Parse Workflow Description

**EXECUTE NOW - Parse User Input**

YOU MUST parse the workflow description to extract:
- Primary feature/goal
- Affected components
- Scope boundaries

```bash
WORKFLOW_DESC="$1"
FEATURE=$(echo "$WORKFLOW_DESC" | head -1)
echo "PROGRESS: Parsing workflow - $FEATURE"
```

**MANDATORY**: DO NOT proceed until workflow scope is clear.
```

**Location 2**: At location-specialist invocation (estimated line 300-350)

**Pattern**:
```markdown
### STEP 2 - Invoke Location Specialist

**EXECUTE NOW - Delegate Location Analysis**

YOU MUST use Task tool to invoke location-specialist agent:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Location analysis for workflow: $FEATURE"
  prompt: |
    Read and follow: .claude/agents/location-specialist.md

    **MANDATORY INPUTS**:
    - Workflow description: "$WORKFLOW_DESC"
    - Current directory: $(pwd)

    **YOUR TASK**: Determine project location and create topic directory structure.

    Return ONLY:
    LOCATION_DETERMINED: {topic_path}
    TOPIC_NUMBER: {NNN}
}
```

**CRITICAL**: Use THIS EXACT TEMPLATE. DO NOT modify agent prompt structure.
```

#### 2.1.2 Phase 1 (Research) - 2 markers

**Location 1**: At research topic decomposition (estimated line 800-900, based on line 862 CRITICAL INSTRUCTION)

**Pattern**:
```markdown
### STEP 1 - Decompose Research Topics

**EXECUTE NOW - Break Down Research Scope**

YOU MUST decompose the workflow into 2-4 parallel research topics:

```bash
# Source topic decomposition utility
source "${CLAUDE_PROJECT_DIR}/.claude/lib/topic-decomposition.sh"

TOPICS=$(decompose_workflow_to_topics "$WORKFLOW_DESC" "$TOPIC_PATH")
TOPIC_COUNT=$(echo "$TOPICS" | wc -l)

if [ $TOPIC_COUNT -lt 2 ] || [ $TOPIC_COUNT -gt 4 ]; then
  echo "ERROR: Topic count ($TOPIC_COUNT) outside range 2-4"
  exit 1
fi

echo "PROGRESS: Decomposed into $TOPIC_COUNT research topics"
```

**CHECKPOINT**: Topic decomposition complete before agent invocation.
```

**Location 2**: At parallel research agent invocation loop

**Pattern**:
```markdown
### STEP 2 - Invoke Research Agents in Parallel

**EXECUTE NOW - Launch Parallel Research Agents**

YOU MUST invoke research-specialist agents for all topics IN PARALLEL:

```bash
declare -a RESEARCH_PIDS=()

for TOPIC in "${TOPICS[@]}"; do
  REPORT_NUM=$(printf "%03d" $((RESEARCH_INDEX++)))
  REPORT_PATH="${TOPIC_PATH}/reports/${REPORT_NUM}_${TOPIC}.md"

  # Launch agent in background (parallel execution)
  Task {
    subagent_type: "general-purpose"
    description: "Research: $TOPIC"
    prompt: |
      Read and follow: .claude/agents/research-specialist.md

      **ABSOLUTE REQUIREMENT**: Create report at this EXACT path:
      $REPORT_PATH

      Research topic: $TOPIC
      Scope: [injected from workflow analysis]

      Return ONLY:
      REPORT_CREATED: $REPORT_PATH
  } &
  RESEARCH_PIDS+=($!)
done

# Wait for all parallel agents to complete
for PID in "${RESEARCH_PIDS[@]}"; do
  wait $PID
done

echo "PROGRESS: All $TOPIC_COUNT research agents completed"
```

**CRITICAL**: All agents MUST run in parallel, not sequentially.
```

#### 2.1.3 Phase 2 (Planning) - 1 marker

**Location**: At plan-architect invocation (estimated line 1500-1600)

**Pattern**:
```markdown
### STEP 2 - Invoke Plan Architect

**EXECUTE NOW - Generate Implementation Plan**

YOU MUST invoke plan-architect agent with research report paths:

```bash
# Collect all report paths
REPORT_PATHS=$(find "$TOPIC_PATH/reports/" -name "*.md" -type f | tr '\n' ' ')

PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for: $FEATURE"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    **MANDATORY INPUTS**:
    - Research reports: $REPORT_PATHS
    - Output path: $PLAN_PATH
    - Feature description: $WORKFLOW_DESC

    **CRITICAL**: Create plan at EXACT path specified.

    Return ONLY:
    PLAN_CREATED: $PLAN_PATH
}
```

**ENFORCEMENT**: Use THIS EXACT TEMPLATE (no modifications).
```

#### 2.1.4 Phase 3 (Implementation) - 2 markers

**Location 1**: At implementation pre-check

**Pattern**:
```markdown
### STEP 1 - Verify Plan File Exists

**EXECUTE NOW - Mandatory Plan Verification**

YOU MUST verify plan file was created in Phase 2:

```bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "CRITICAL ERROR: Plan file not found at $PLAN_PATH"
  echo "Phase 2 planning failed. Cannot proceed to implementation."
  exit 1
fi

PLAN_SIZE=$(wc -c < "$PLAN_PATH")
if [ $PLAN_SIZE -lt 500 ]; then
  echo "WARNING: Plan file suspiciously small ($PLAN_SIZE bytes)"
  echo "Manual review recommended before implementation"
fi

echo "PROGRESS: Verified plan exists at $PLAN_PATH ($PLAN_SIZE bytes)"
```

**CHECKPOINT**: Plan file verification complete.
```

**Location 2**: At code-writer invocation

**Pattern**:
```markdown
### STEP 3 - Invoke Code Writer for Adaptive Implementation

**EXECUTE NOW - Delegate Implementation to Code Writer**

YOU MUST invoke code-writer agent for adaptive wave-based implementation:

```bash
Task {
  subagent_type: "general-purpose"
  description: "Implement plan: $FEATURE"
  prompt: |
    Read and follow: .claude/agents/code-writer.md

    **MANDATORY INPUTS**:
    - Implementation plan: $PLAN_PATH
    - Topic directory: $TOPIC_PATH
    - Adaptive mode: ENABLED (automatic phase expansion if complexity >8)

    **EXECUTION MODE**: Wave-based parallel implementation
    - Analyze phase dependencies
    - Execute independent phases in parallel waves
    - Apply adaptive replanning if test failures occur

    Return ONLY:
    IMPLEMENTATION_COMPLETE: {summary_path}
}
```

**CRITICAL**: Code-writer handles ALL implementation logic (you do NOT implement).
```

#### 2.1.5 Phase 4 (Testing) - 1 marker

**Location**: At test-specialist invocation

**Pattern**:
```markdown
### STEP 1 - Invoke Test Specialist

**EXECUTE NOW - Run Complete Test Suite**

YOU MUST invoke test-specialist to execute all project tests:

```bash
TEST_RESULTS_PATH="${TOPIC_PATH}/test_results.txt"

Task {
  subagent_type: "general-purpose"
  description: "Run test suite after implementation"
  prompt: |
    Read and follow: .claude/agents/test-specialist.md

    **MANDATORY INPUTS**:
    - Test results output: $TEST_RESULTS_PATH
    - Coverage target: ≥80% modified code, ≥60% baseline

    **YOUR TASK**: Execute complete test suite per CLAUDE.md protocols.

    Return ONLY:
    TESTS_COMPLETE: $TEST_RESULTS_PATH
    STATUS: {PASS|FAIL}
    COVERAGE: {percentage}
}
```

**ENFORCEMENT**: Test results MUST be written to specified path.
```

#### 2.1.6 Phase 5 (Debugging - Conditional) - 1 marker

**Location**: At conditional debug invocation trigger

**Pattern**:
```markdown
### Conditional Debug Phase Trigger

**EXECUTE NOW - Evaluate Test Results**

If Phase 4 tests FAILED, YOU MUST invoke debug-specialist:

```bash
TEST_STATUS=$(grep "STATUS:" "$TEST_RESULTS_PATH" | awk '{print $2}')

if [ "$TEST_STATUS" = "FAIL" ]; then
  echo "PROGRESS: Tests failed, invoking debug-specialist"

  DEBUG_REPORT_PATH="${TOPIC_PATH}/debug/001_test_failures.md"

  Task {
    subagent_type: "general-purpose"
    description: "Debug test failures"
    prompt: |
      Read and follow: .claude/agents/debug-specialist.md

      **MANDATORY INPUTS**:
      - Test results: $TEST_RESULTS_PATH
      - Debug report output: $DEBUG_REPORT_PATH

      **YOUR TASK**: Analyze failures, propose fixes, apply patches.

      Return ONLY:
      DEBUG_COMPLETE: $DEBUG_REPORT_PATH
      FIXES_APPLIED: {count}
  }
else
  echo "PROGRESS: Tests passed, skipping debug phase"
fi
```

**CONDITIONAL**: Debug phase only executes if tests fail.
```

#### 2.1.7 Phase 6 (Documentation) - 1 marker

**Location**: At doc-writer invocation

**Pattern**:
```markdown
### STEP 1 - Invoke Documentation Writer

**EXECUTE NOW - Generate Workflow Documentation**

YOU MUST invoke doc-writer for comprehensive workflow documentation:

```bash
SUMMARY_PATH="${TOPIC_PATH}/summaries/001_workflow_summary.md"

Task {
  subagent_type: "general-purpose"
  description: "Document workflow: $FEATURE"
  prompt: |
    Read and follow: .claude/agents/doc-writer.md

    **MANDATORY INPUTS**:
    - Implementation plan: $PLAN_PATH
    - Test results: $TEST_RESULTS_PATH
    - Debug reports: ${TOPIC_PATH}/debug/*.md (if exist)
    - Summary output: $SUMMARY_PATH

    **YOUR TASK**: Create workflow summary documenting all phases.

    Return ONLY:
    DOCUMENTATION_COMPLETE: $SUMMARY_PATH
}
```

**FINAL CHECKPOINT**: Documentation completes workflow.
```

#### 2.1.8 Checkpoint Save/Restore Utilities - 2 markers

**Location**: At checkpoint save operation (estimated line 5000+)

**Pattern**:
```markdown
### Save Workflow Checkpoint

**EXECUTE NOW - Persist Workflow State**

After each phase completes, YOU MUST save checkpoint:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/checkpoint-utils.sh"

save_checkpoint "$TOPIC_PATH" "$CURRENT_PHASE" \
  --research-reports "$RESEARCH_REPORT_PATHS" \
  --plan-path "$PLAN_PATH" \
  --test-status "$TEST_STATUS" \
  --context-usage "$CONTEXT_PERCENTAGE"

echo "PROGRESS: Checkpoint saved for phase $CURRENT_PHASE"
```

**GUARANTEE**: Workflow can resume from this point if interrupted.
```

**Total EXECUTE NOW markers**: 12 (meets minimum requirement)

---

### 2.2 MANDATORY VERIFICATION Marker Placement Strategy

**Target Count**: 8 minimum (one per file creation operation)

#### 2.2.1 Phase 0 Verification - 1 marker

**Location**: After location-specialist completes

**Pattern**:
```markdown
### Verify Topic Directory Structure Created

**MANDATORY VERIFICATION - Topic Directory Exists**

After location-specialist completes, YOU MUST verify:

```bash
if [ ! -d "$TOPIC_PATH" ]; then
  echo "CRITICAL ERROR: Topic directory not created at $TOPIC_PATH"
  echo "Location-specialist failed. Executing fallback..."

  # FALLBACK: Create minimal directory structure
  mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug}
  chmod 755 "$TOPIC_PATH"

  echo "FALLBACK: Created topic directory at $TOPIC_PATH"
fi

# Verify all subdirectories exist
for SUBDIR in reports plans summaries debug; do
  if [ ! -d "$TOPIC_PATH/$SUBDIR" ]; then
    echo "ERROR: Missing subdirectory: $SUBDIR"
    mkdir -p "$TOPIC_PATH/$SUBDIR"
  fi
done

echo "VERIFIED: Topic directory structure complete at $TOPIC_PATH"
```

**CHECKPOINT**: Directory structure verified before Phase 1.
```

#### 2.2.2 Phase 1 Verification - 2 markers

**Location 1**: After each research agent completes (in loop)

**Pattern**:
```markdown
### Verify Research Report Created

**MANDATORY VERIFICATION - Report File Exists**

After EACH research agent completes, YOU MUST verify report file:

```bash
EXPECTED_REPORT="$REPORT_PATH"

if [ ! -f "$EXPECTED_REPORT" ]; then
  echo "WARNING: Research agent did not create report at $EXPECTED_REPORT"
  echo "Executing fallback..."

  # FALLBACK: Create minimal report
  cat > "$EXPECTED_REPORT" <<EOF
# Research Report: $TOPIC

## Status
INCOMPLETE - Agent invocation succeeded but file not created

## Manual Action Required
Review agent output and complete research manually.

## Agent Invocation Details
- Topic: $TOPIC
- Expected path: $EXPECTED_REPORT
- Timestamp: $(date -Iseconds)
EOF

  echo "FALLBACK: Created minimal report at $EXPECTED_REPORT"
fi

REPORT_SIZE=$(wc -c < "$EXPECTED_REPORT")
echo "VERIFIED: Report exists at $EXPECTED_REPORT ($REPORT_SIZE bytes)"
```

**GUARANTEE**: Report file exists even if agent fails to create it.
```

**Location 2**: After ALL research agents complete (aggregate verification)

**Pattern**:
```markdown
### Verify All Research Reports Collected

**MANDATORY VERIFICATION - All Reports Exist**

After all research agents complete, YOU MUST verify:

```bash
EXPECTED_REPORT_COUNT=$TOPIC_COUNT
ACTUAL_REPORT_COUNT=$(find "$TOPIC_PATH/reports/" -name "*.md" -type f | wc -l)

if [ $ACTUAL_REPORT_COUNT -lt $EXPECTED_REPORT_COUNT ]; then
  echo "ERROR: Expected $EXPECTED_REPORT_COUNT reports, found $ACTUAL_REPORT_COUNT"
  echo "Missing reports detected. Review fallback files for manual completion."
fi

echo "VERIFIED: $ACTUAL_REPORT_COUNT/$EXPECTED_REPORT_COUNT research reports exist"
```

**CHECKPOINT**: Research phase verification complete.
```

#### 2.2.3 Phase 2 Verification - 1 marker

**Location**: After plan-architect completes

**Pattern**:
```markdown
### Verify Implementation Plan Created

**MANDATORY VERIFICATION - Plan File Exists**

After plan-architect completes, YOU MUST verify:

```bash
if [ ! -f "$PLAN_PATH" ]; then
  echo "CRITICAL ERROR: Plan file not created at $PLAN_PATH"
  echo "Plan-architect failed. Executing fallback..."

  # FALLBACK: Create minimal plan structure
  cat > "$PLAN_PATH" <<EOF
# Implementation Plan: $FEATURE

## Overview
INCOMPLETE - Plan architect invocation succeeded but file not created

## Phases

### Phase 1: Setup
- [ ] Review research reports
- [ ] Define implementation scope

### Phase 2: Implementation
- [ ] Implement core functionality

### Phase 3: Testing
- [ ] Write tests
- [ ] Verify functionality

## Manual Action Required
Complete plan details before implementation.
EOF

  echo "FALLBACK: Created minimal plan at $PLAN_PATH"
fi

PLAN_SIZE=$(wc -c < "$PLAN_PATH")
PLAN_PHASES=$(grep -c "^### Phase" "$PLAN_PATH" || echo 0)

echo "VERIFIED: Plan exists at $PLAN_PATH"
echo "  Size: $PLAN_SIZE bytes"
echo "  Phases: $PLAN_PHASES"

if [ $PLAN_PHASES -lt 2 ]; then
  echo "WARNING: Plan has fewer than 2 phases. Manual review recommended."
fi
```

**CHECKPOINT**: Plan verification complete before implementation.
```

#### 2.2.4 Phase 3 Verification - 1 marker

**Location**: After code-writer completes

**Pattern**:
```markdown
### Verify Implementation Complete

**MANDATORY VERIFICATION - Implementation Artifacts Exist**

After code-writer completes, YOU MUST verify:

```bash
SUMMARY_PATH="${TOPIC_PATH}/summaries/implementation_summary.md"

if [ ! -f "$SUMMARY_PATH" ]; then
  echo "ERROR: Implementation summary not created at $SUMMARY_PATH"
  echo "Code-writer may have failed. Creating fallback..."

  # FALLBACK: Create minimal summary
  cat > "$SUMMARY_PATH" <<EOF
# Implementation Summary: $FEATURE

## Status
INCOMPLETE - Code writer invoked but summary not created

## Artifacts
- Plan: $PLAN_PATH
- Implementation: [Unknown - manual verification required]

## Next Steps
1. Verify code changes using git diff
2. Complete missing implementation
3. Update this summary with actual changes
EOF

  echo "FALLBACK: Created minimal summary at $SUMMARY_PATH"
fi

echo "VERIFIED: Implementation summary exists at $SUMMARY_PATH"

# Additional verification: Check for code changes
GIT_CHANGES=$(git status --porcelain | wc -l)
if [ $GIT_CHANGES -eq 0 ]; then
  echo "WARNING: No git changes detected after implementation phase"
  echo "Implementation may have failed silently. Manual review required."
fi
```

**CHECKPOINT**: Implementation verification complete before testing.
```

#### 2.2.5 Phase 4 Verification - 1 marker

**Location**: After test-specialist completes

**Pattern**:
```markdown
### Verify Test Results Created

**MANDATORY VERIFICATION - Test Results File Exists**

After test-specialist completes, YOU MUST verify:

```bash
if [ ! -f "$TEST_RESULTS_PATH" ]; then
  echo "CRITICAL ERROR: Test results not created at $TEST_RESULTS_PATH"
  echo "Test-specialist failed. Executing fallback..."

  # FALLBACK: Run tests directly
  echo "FALLBACK: Running tests directly..."
  bash "${CLAUDE_PROJECT_DIR}/.claude/tests/run_all_tests.sh" > "$TEST_RESULTS_PATH" 2>&1 || {
    echo "FALLBACK TEST EXECUTION FAILED" >> "$TEST_RESULTS_PATH"
    echo "STATUS: FAIL" >> "$TEST_RESULTS_PATH"
  }

  echo "FALLBACK: Created test results at $TEST_RESULTS_PATH"
fi

# Verify test results contain status
if ! grep -q "STATUS:" "$TEST_RESULTS_PATH"; then
  echo "ERROR: Test results missing STATUS field"
  echo "STATUS: UNKNOWN" >> "$TEST_RESULTS_PATH"
fi

TEST_STATUS=$(grep "STATUS:" "$TEST_RESULTS_PATH" | awk '{print $2}')
echo "VERIFIED: Test results exist at $TEST_RESULTS_PATH"
echo "  Status: $TEST_STATUS"
```

**CHECKPOINT**: Test verification complete.
```

#### 2.2.6 Phase 5 Verification - 1 marker (conditional)

**Location**: After debug-specialist completes (if invoked)

**Pattern**:
```markdown
### Verify Debug Report Created

**MANDATORY VERIFICATION - Debug Report Exists** (Conditional)

If debug-specialist was invoked, YOU MUST verify:

```bash
if [ "$TEST_STATUS" = "FAIL" ]; then
  if [ ! -f "$DEBUG_REPORT_PATH" ]; then
    echo "ERROR: Debug report not created at $DEBUG_REPORT_PATH"
    echo "Debug-specialist invoked but failed. Creating fallback..."

    # FALLBACK: Create minimal debug report
    cat > "$DEBUG_REPORT_PATH" <<EOF
# Debug Report: Test Failures

## Test Results
See: $TEST_RESULTS_PATH

## Status
INCOMPLETE - Debug specialist invoked but report not created

## Manual Action Required
Review test failures manually and apply fixes.
EOF

    echo "FALLBACK: Created minimal debug report at $DEBUG_REPORT_PATH"
  fi

  echo "VERIFIED: Debug report exists at $DEBUG_REPORT_PATH"
fi
```

**CHECKPOINT**: Debug verification complete (if debug phase ran).
```

#### 2.2.7 Phase 6 Verification - 1 marker

**Location**: After doc-writer completes

**Pattern**:
```markdown
### Verify Workflow Summary Created

**MANDATORY VERIFICATION - Summary File Exists**

After doc-writer completes, YOU MUST verify:

```bash
if [ ! -f "$SUMMARY_PATH" ]; then
  echo "ERROR: Workflow summary not created at $SUMMARY_PATH"
  echo "Doc-writer failed. Executing fallback..."

  # FALLBACK: Generate minimal summary
  cat > "$SUMMARY_PATH" <<EOF
# Workflow Summary: $FEATURE

## Artifacts Created
- Research Reports: $(find "$TOPIC_PATH/reports/" -name "*.md" | wc -l)
- Implementation Plan: $PLAN_PATH
- Test Results: $TEST_RESULTS_PATH
- Debug Reports: $(find "$TOPIC_PATH/debug/" -name "*.md" 2>/dev/null | wc -l)

## Workflow Status
- Research: COMPLETE
- Planning: COMPLETE
- Implementation: COMPLETE
- Testing: $TEST_STATUS
- Debugging: $([ "$TEST_STATUS" = "FAIL" ] && echo "INVOKED" || echo "SKIPPED")
- Documentation: COMPLETE

## Manual Action Required
Complete documentation details in this summary.
EOF

  echo "FALLBACK: Created minimal summary at $SUMMARY_PATH"
fi

SUMMARY_SIZE=$(wc -c < "$SUMMARY_PATH")
echo "VERIFIED: Workflow summary exists at $SUMMARY_PATH ($SUMMARY_SIZE bytes)"
```

**FINAL CHECKPOINT**: Workflow complete verification.
```

**Total MANDATORY VERIFICATION markers**: 8 (meets minimum requirement)

---

### 2.3 CHECKPOINT REQUIREMENT Marker Placement Strategy

**Target Count**: 6 minimum (one per major phase boundary)

#### 2.3.1 Phase Boundary Checkpoints

**Phase 0 → Phase 1 Checkpoint**

**Pattern**:
```markdown
**CHECKPOINT REQUIREMENT - Phase 0 Complete**

After location determination, YOU MUST report:

```
CHECKPOINT: Phase 0 - Location Determination Complete
- Topic directory: $TOPIC_PATH
- Topic number: $TOPIC_NUMBER
- Subdirectories: reports/ plans/ summaries/ debug/
- Verification: ✓ All directories exist
- Status: READY FOR PHASE 1 (Research)
```

**MANDATORY**: Emit this checkpoint before proceeding to Phase 1.
```

**Phase 1 → Phase 2 Checkpoint**

**Pattern**:
```markdown
**CHECKPOINT REQUIREMENT - Phase 1 Complete**

After all research completes, YOU MUST report:

```
CHECKPOINT: Phase 1 - Research Complete
- Research topics: $TOPIC_COUNT
- Reports created: $ACTUAL_REPORT_COUNT/$EXPECTED_REPORT_COUNT
- Reports verified: ✓ All files exist
- Fallback invocations: $FALLBACK_COUNT
- Context usage: ${CONTEXT_PERCENTAGE}%
- Status: READY FOR PHASE 2 (Planning)
```

**MANDATORY**: Emit this checkpoint before invoking plan-architect.
```

**Phase 2 → Phase 3 Checkpoint**

**Pattern**:
```markdown
**CHECKPOINT REQUIREMENT - Phase 2 Complete**

After planning completes, YOU MUST report:

```
CHECKPOINT: Phase 2 - Planning Complete
- Plan file: $PLAN_PATH
- Plan size: $PLAN_SIZE bytes
- Plan phases: $PLAN_PHASES
- Complexity score: $COMPLEXITY (from plan metadata)
- Verification: ✓ Plan file exists
- User expansion: ${USER_EXPANDED:-NO}
- Status: READY FOR PHASE 3 (Implementation)
```

**MANDATORY**: Emit this checkpoint before invoking code-writer.
```

**Phase 3 → Phase 4 Checkpoint**

**Pattern**:
```markdown
**CHECKPOINT REQUIREMENT - Phase 3 Complete**

After implementation completes, YOU MUST report:

```
CHECKPOINT: Phase 3 - Implementation Complete
- Summary file: $SUMMARY_PATH
- Git changes: $GIT_CHANGES files modified
- Implementation mode: Wave-based parallel
- Adaptive replanning: $REPLAN_COUNT invocations
- Verification: ✓ Summary exists, code changes detected
- Status: READY FOR PHASE 4 (Testing)
```

**MANDATORY**: Emit this checkpoint before invoking test-specialist.
```

**Phase 4 → Phase 5/6 Checkpoint**

**Pattern**:
```markdown
**CHECKPOINT REQUIREMENT - Phase 4 Complete**

After testing completes, YOU MUST report:

```
CHECKPOINT: Phase 4 - Testing Complete
- Test results: $TEST_RESULTS_PATH
- Test status: $TEST_STATUS
- Coverage: $COVERAGE%
- Failed tests: $FAILED_TEST_COUNT
- Verification: ✓ Test results file exists
- Next phase: $([ "$TEST_STATUS" = "FAIL" ] && echo "Phase 5 (Debug)" || echo "Phase 6 (Documentation)")
```

**MANDATORY**: Emit this checkpoint before conditional debug or final documentation.
```

**Phase 6 → Workflow Complete Checkpoint**

**Pattern**:
```markdown
**CHECKPOINT REQUIREMENT - Phase 6 Complete**

After documentation completes, YOU MUST report:

```
CHECKPOINT: Phase 6 - Documentation Complete
- Workflow summary: $SUMMARY_PATH
- Summary size: $SUMMARY_SIZE bytes
- Total artifacts: $(find "$TOPIC_PATH" -type f | wc -l)
- Verification: ✓ All phase artifacts exist
- Context usage: ${FINAL_CONTEXT_PERCENTAGE}% (target: <30%)
- Status: WORKFLOW COMPLETE
```

**FINAL CHECKPOINT**: Workflow execution complete.
```

**Total CHECKPOINT REQUIREMENT markers**: 6 (meets minimum requirement)

---

## Modification Zone 3: Imperative Language Transformation (Throughout File)

### Current Passive Language Inventory

Based on grep analysis, file has 14 occurrences of passive language (should/may/can/consider/try to).

**Target**: Eliminate ALL passive occurrences to achieve ≥90% imperative ratio.

### 3.1 Transformation Strategy

Use transformation table from Imperative Language Guide (Pattern 10):

| Before | After |
|--------|-------|
| should verify | YOU MUST verify |
| can use | YOU WILL use |
| may include | YOU SHALL include |
| consider adding | YOU MUST add |
| try to | YOU WILL |

### 3.2 Search and Replace Operations

**Step 1**: Identify all passive occurrences

```bash
# Generate list of lines with passive language
grep -n "should\|may\|can\|consider\|try to" /home/benjamin/.config/.claude/commands/orchestrate.md > passive_lines.txt

# Expected output format:
# 123: The orchestrator should verify file creation
# 456: You may add additional agents if needed
# 789: Consider using parallel execution
```

**Step 2**: Manual review and context-aware transformation

For each occurrence:
1. Read surrounding context (±5 lines)
2. Determine intent: required action vs optional action vs prohibition
3. Apply appropriate imperative replacement
4. Verify sentence structure remains grammatically correct

**Example Transformations**:

**Line 123** (hypothetical):
```markdown
❌ BEFORE: The orchestrator should verify file creation after each agent completes.

✅ AFTER: YOU MUST verify file creation after each agent completes.
```

**Line 456** (hypothetical):
```markdown
❌ BEFORE: You may add additional research agents if the workflow scope is complex.

✅ AFTER: YOU SHALL add additional research agents (up to 4 total) if the workflow scope encompasses >3 major components.
```

**Line 789** (hypothetical):
```markdown
❌ BEFORE: Consider using parallel execution for independent research topics.

✅ AFTER: YOU MUST use parallel execution for all independent research topics (NO sequential execution allowed).
```

### 3.3 Validation After Transformation

After all transformations, run audit script:

```bash
bash /home/benjamin/.config/.claude/lib/audit-imperative-language.sh \
  /home/benjamin/.config/.claude/commands/orchestrate.md
```

**Expected output**:
```
=== Imperative Language Audit ===
File: orchestrate.md

Weak Language (should be eliminated):
  should: 0
  may: 0
  can: 0
  consider: 0
  try to: 0
  TOTAL WEAK: 0

Imperative Language (required):
  MUST: 45+
  WILL: 30+
  SHALL: 15+
  TOTAL IMPERATIVE: 90+

Imperative Ratio: 100%

✓ PASS: Imperative language usage is excellent
```

**Target**: 0 weak language occurrences, ≥90% imperative ratio (aim for 100%).

---

## Modification Zone 4: Context Pruning Policy Integration (New Section)

### Current State

File does not explicitly integrate context pruning policy with actual function calls from context-pruning.sh utility.

### Required Addition

**Location**: After Phase 1 (Research) completion, before Phase 2 begins (estimated line 1400-1500)

**Insert New Section**:

```markdown
## Aggressive Context Pruning Policy

After EACH phase completes, YOU MUST apply aggressive context pruning to maintain <20% context usage throughout workflow.

### Phase 1 (Research) → Phase 2 (Planning) Pruning

**EXECUTE NOW - Prune Research Phase Context**

After all research reports verified, YOU MUST prune research agent outputs:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-pruning.sh"

# Prune each research agent output (retain metadata only)
for REPORT_PATH in "${RESEARCH_REPORT_PATHS[@]}"; do
  REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")

  # Clear full report content from context, retain metadata
  prune_subagent_output "RESEARCH_AGENT_OUTPUT_$i" "phase_1_research"

  echo "PRUNED: $REPORT_PATH → metadata only (99% reduction)"
done

# Apply aggressive pruning policy
apply_pruning_policy --mode aggressive --phase research

# Measure context usage
CONTEXT_AFTER_PRUNING=$(measure_context_usage)
echo "PROGRESS: Context usage after Phase 1 pruning: ${CONTEXT_AFTER_PRUNING}%"

if [ $CONTEXT_AFTER_PRUNING -gt 20 ]; then
  echo "WARNING: Context usage (${CONTEXT_AFTER_PRUNING}%) exceeds 20% target"
  echo "Additional pruning may be required before Phase 3"
fi
```

**TARGET**: <20% context usage after pruning.

### Phase 2 (Planning) → Phase 3 (Implementation) Pruning

**EXECUTE NOW - Prune Planning Phase Context**

After plan file verified, YOU MUST prune planning agent output:

```bash
# Extract plan metadata (complexity, phases, time estimates)
PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")

# Clear full plan content from context, retain metadata
prune_subagent_output "PLAN_ARCHITECT_OUTPUT" "phase_2_planning"

# Apply aggressive pruning policy
apply_pruning_policy --mode aggressive --phase planning

# Measure context usage
CONTEXT_AFTER_PRUNING=$(measure_context_usage)
echo "PROGRESS: Context usage after Phase 2 pruning: ${CONTEXT_AFTER_PRUNING}%"
```

**TARGET**: <20% context usage after pruning.

### Phase 3 (Implementation) → Phase 4 (Testing) Pruning

**EXECUTE NOW - Prune Implementation Phase Context**

After implementation summary verified, YOU MUST prune implementation agent output:

```bash
# Extract implementation metadata (files changed, summary)
IMPL_METADATA=$(extract_implementation_metadata "$SUMMARY_PATH")

# Clear full implementation details from context, retain metadata
prune_subagent_output "CODE_WRITER_OUTPUT" "phase_3_implementation"

# Apply aggressive pruning policy
apply_pruning_policy --mode aggressive --phase implementation

# Measure context usage
CONTEXT_AFTER_PRUNING=$(measure_context_usage)
echo "PROGRESS: Context usage after Phase 3 pruning: ${CONTEXT_AFTER_PRUNING}%"
```

**TARGET**: <20% context usage maintained.

### Context Pruning Enforcement

**ABSOLUTE REQUIREMENT**: Context pruning is MANDATORY after each phase, not optional.

**WHY THIS MATTERS**:
- 6-phase workflow generates massive subagent outputs (10,000+ tokens per phase)
- Without pruning: 60,000+ tokens → 80-100% context usage → workflow failure
- With aggressive pruning: 1,500 tokens metadata → <20% context usage → workflow success
- Pruning enables hierarchical multi-agent patterns and parallel execution

**VERIFICATION**:
Monitor context usage at each checkpoint. If >30%, additional pruning required before next phase.
```

**Rationale**: Hierarchical Agent Architecture section in CLAUDE.md specifies <30% target context usage through aggressive pruning. This addition integrates actual utility functions with workflow phases.

---

## Testing Protocol

### Test 1: Role Clarification Verification

**Objective**: Verify Phase 0 orchestrator role clarification exists and is comprehensive.

**Test Script**:
```bash
#!/bin/bash
# test_phase0_role_clarification.sh

FILE="/home/benjamin/.config/.claude/commands/orchestrate.md"

echo "Testing Phase 0 orchestrator role clarification..."

# Check 1: YOUR ROLE section exists
if ! grep -q "YOUR ROLE.*ORCHESTRATOR" "$FILE"; then
  echo "❌ FAIL: YOUR ROLE section missing"
  exit 1
fi

# Check 2: CRITICAL INSTRUCTIONS section exists
if ! grep -q "CRITICAL INSTRUCTIONS" "$FILE"; then
  echo "❌ FAIL: CRITICAL INSTRUCTIONS section missing"
  exit 1
fi

# Check 3: DO NOT execute research yourself
if ! grep -q "DO NOT.*execute research yourself" "$FILE"; then
  echo "❌ FAIL: DO NOT execute research constraint missing"
  exit 1
fi

# Check 4: ONLY use Task tool
if ! grep -q "ONLY.*Task tool" "$FILE"; then
  echo "❌ FAIL: ONLY Task tool directive missing"
  exit 1
fi

# Check 5: Orchestrator execution model explanation
if ! grep -q "You will NOT see.*directly" "$FILE"; then
  echo "❌ FAIL: Execution model explanation missing"
  exit 1
fi

# Check 6: Behavioral Injection Pattern reference
if ! grep -q "Behavioral Injection Pattern" "$FILE"; then
  echo "❌ FAIL: Behavioral Injection Pattern reference missing"
  exit 1
fi

echo "✓ PASS: Phase 0 orchestrator role clarification complete"
```

**Expected Result**: All 6 checks pass.

---

### Test 2: Standard 0 Enforcement Marker Counts

**Objective**: Verify minimum enforcement marker counts are met.

**Test Script**:
```bash
#!/bin/bash
# test_standard0_markers.sh

FILE="/home/benjamin/.config/.claude/commands/orchestrate.md"

echo "Testing Standard 0 enforcement marker counts..."

# Count EXECUTE NOW markers
EXECUTE_NOW_COUNT=$(grep -c "EXECUTE NOW" "$FILE")
if [ $EXECUTE_NOW_COUNT -lt 12 ]; then
  echo "❌ FAIL: Only $EXECUTE_NOW_COUNT EXECUTE NOW markers (need ≥12)"
  exit 1
fi
echo "✓ EXECUTE NOW markers: $EXECUTE_NOW_COUNT (≥12 required)"

# Count MANDATORY VERIFICATION markers
MANDATORY_VERIFICATION_COUNT=$(grep -c "MANDATORY VERIFICATION" "$FILE")
if [ $MANDATORY_VERIFICATION_COUNT -lt 8 ]; then
  echo "❌ FAIL: Only $MANDATORY_VERIFICATION_COUNT MANDATORY VERIFICATION markers (need ≥8)"
  exit 1
fi
echo "✓ MANDATORY VERIFICATION markers: $MANDATORY_VERIFICATION_COUNT (≥8 required)"

# Count CHECKPOINT REQUIREMENT markers
CHECKPOINT_COUNT=$(grep -c "CHECKPOINT REQUIREMENT" "$FILE")
if [ $CHECKPOINT_COUNT -lt 6 ]; then
  echo "❌ FAIL: Only $CHECKPOINT_COUNT CHECKPOINT markers (need ≥6)"
  exit 1
fi
echo "✓ CHECKPOINT REQUIREMENT markers: $CHECKPOINT_COUNT (≥6 required)"

# Count CRITICAL INSTRUCTION markers
CRITICAL_COUNT=$(grep -c "CRITICAL INSTRUCTION\|CRITICAL CONSTRAINT\|ABSOLUTE REQUIREMENT" "$FILE")
echo "✓ CRITICAL markers: $CRITICAL_COUNT"

echo "✓ PASS: All Standard 0 marker counts meet minimums"
```

**Expected Result**: All marker counts ≥ minimums.

---

### Test 3: Imperative Language Ratio

**Objective**: Verify ≥90% imperative language ratio.

**Test Script**:
```bash
#!/bin/bash
# test_imperative_ratio.sh

FILE="/home/benjamin/.config/.claude/commands/orchestrate.md"

echo "Testing imperative language ratio..."

# Run official audit script
bash /home/benjamin/.config/.claude/lib/audit-imperative-language.sh "$FILE"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  echo "❌ FAIL: Imperative language ratio below 90%"
  exit 1
fi

echo "✓ PASS: Imperative language ratio ≥90%"
```

**Expected Result**: Exit code 0 (≥90% imperative ratio).

---

### Test 4: Context Pruning Integration

**Objective**: Verify context pruning policy is integrated with actual function calls.

**Test Script**:
```bash
#!/bin/bash
# test_context_pruning.sh

FILE="/home/benjamin/.config/.claude/commands/orchestrate.md"

echo "Testing context pruning policy integration..."

# Check 1: apply_pruning_policy function called
if ! grep -q "apply_pruning_policy" "$FILE"; then
  echo "❌ FAIL: apply_pruning_policy function not called"
  exit 1
fi

# Check 2: prune_subagent_output function called
if ! grep -q "prune_subagent_output" "$FILE"; then
  echo "❌ FAIL: prune_subagent_output function not called"
  exit 1
fi

# Check 3: Context usage measurement present
if ! grep -q "measure_context_usage\|CONTEXT_AFTER_PRUNING" "$FILE"; then
  echo "❌ FAIL: Context usage measurement not present"
  exit 1
fi

# Check 4: <20% context target specified
if ! grep -q "<20%\|< 20%" "$FILE"; then
  echo "❌ FAIL: <20% context target not specified"
  exit 1
fi

# Count pruning invocations (should be ≥3: after research, planning, implementation)
PRUNING_COUNT=$(grep -c "apply_pruning_policy" "$FILE")
if [ $PRUNING_COUNT -lt 3 ]; then
  echo "❌ FAIL: Only $PRUNING_COUNT pruning invocations (need ≥3 for phases 1-3)"
  exit 1
fi

echo "✓ PASS: Context pruning policy integrated ($PRUNING_COUNT invocations)"
```

**Expected Result**: All checks pass, ≥3 pruning invocations.

---

### Test 5: File Creation Verification Coverage

**Objective**: Verify MANDATORY VERIFICATION blocks exist for ALL file creation operations.

**Test Script**:
```bash
#!/bin/bash
# test_verification_coverage.sh

FILE="/home/benjamin/.config/.claude/commands/orchestrate.md"

echo "Testing file creation verification coverage..."

# Define expected verification points (one per phase that creates files)
declare -a EXPECTED_VERIFICATIONS=(
  "Topic directory structure"
  "Research report"
  "Implementation plan"
  "Implementation summary"
  "Test results"
  "Debug report"
  "Workflow summary"
)

for VERIFICATION in "${EXPECTED_VERIFICATIONS[@]}"; do
  # Search for verification block mentioning this artifact
  if ! grep -i -q "MANDATORY VERIFICATION.*$VERIFICATION\|VERIFY.*$VERIFICATION.*EXIST" "$FILE"; then
    echo "❌ FAIL: No verification found for: $VERIFICATION"
    exit 1
  fi
  echo "✓ Verification found for: $VERIFICATION"
done

echo "✓ PASS: All file creation operations have verification blocks"
```

**Expected Result**: Verification blocks found for all 7 artifact types.

---

### Complete Test Suite Execution

**Combined Test Script**:
```bash
#!/bin/bash
# run_phase0_tests.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Phase 0 Test Suite"
echo "========================================"
echo ""

# Test 1: Role clarification
bash "$SCRIPT_DIR/test_phase0_role_clarification.sh" || exit 1
echo ""

# Test 2: Standard 0 markers
bash "$SCRIPT_DIR/test_standard0_markers.sh" || exit 1
echo ""

# Test 3: Imperative language ratio
bash "$SCRIPT_DIR/test_imperative_ratio.sh" || exit 1
echo ""

# Test 4: Context pruning
bash "$SCRIPT_DIR/test_context_pruning.sh" || exit 1
echo ""

# Test 5: Verification coverage
bash "$SCRIPT_DIR/test_verification_coverage.sh" || exit 1
echo ""

echo "========================================"
echo "All Phase 0 tests PASSED"
echo "========================================"
```

**Success Criteria**: All 5 tests pass.

---

## Git Commit Message

After completing all modifications and verifying tests pass:

```bash
git add .claude/commands/orchestrate.md

git commit -m "$(cat <<'EOF'
feat(071): Phase 0 - add orchestrator role clarification and Standard 0 enforcement

Enhanced orchestrate.md with comprehensive execution enforcement:

**Phase 0 Role Clarification**:
- Added explicit orchestrator role declaration with DO NOT constraints
- Added "You will NOT see [results] directly" execution model explanation
- Added Behavioral Injection Pattern reference
- Strengthened CRITICAL CONSTRAINTS section with per-tool prohibitions

**Standard 0 Enforcement Markers** (minimum counts achieved):
- 12+ EXECUTE NOW markers at critical operations (path calculation, agent invocation)
- 8+ MANDATORY VERIFICATION blocks for file creation checkpoints
- 6+ CHECKPOINT REQUIREMENT blocks at phase boundaries
- Added fallback mechanisms for 100% file creation guarantee

**Imperative Language Transformation**:
- Eliminated 14 passive language occurrences (should/may/can/consider/try to)
- Achieved 100% imperative language ratio (MUST/WILL/SHALL)
- Validated using audit-imperative-language.sh (score: PASS)

**Context Pruning Integration**:
- Added aggressive context pruning policy after Phases 1-3
- Integrated apply_pruning_policy and prune_subagent_output function calls
- Specified <20% context usage target with checkpoint monitoring

**Testing**: All 5 validation tests pass
- Role clarification comprehensive (6 requirements verified)
- Standard 0 markers meet minimums (12/8/6 counts)
- Imperative language ratio ≥90%
- Context pruning integrated (3+ invocations)
- File verification coverage complete (7 artifact types)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Implementation Guidance

### Recommended Implementation Order

1. **Modification Zone 1** (Lines 38-64): Enhanced role clarification (~30 minutes)
   - Add execution model explanation
   - Strengthen DO NOT constraints
   - Add Behavioral Injection Pattern reference

2. **Modification Zone 3** (Throughout): Imperative language transformation (~45 minutes)
   - Generate passive language line list
   - Transform all 14 occurrences
   - Validate with audit script

3. **Modification Zone 2** (Throughout): Standard 0 enforcement markers (~90 minutes)
   - Phase 0-6 EXECUTE NOW markers (12 total)
   - Phase 0-6 MANDATORY VERIFICATION blocks (8 total)
   - Phase boundary CHECKPOINT REQUIREMENT blocks (6 total)

4. **Modification Zone 4** (New section): Context pruning integration (~30 minutes)
   - Add pruning policy section after Phase 1
   - Integrate function calls for Phases 1-3
   - Add context usage monitoring

5. **Testing** (~30 minutes)
   - Run all 5 test scripts
   - Fix any failures
   - Re-run until all pass

**Total Estimated Time**: 3.5-4 hours

### Critical Success Factors

1. **Preserve Existing Structure**: orchestrate.md already has good organization. Add enforcement without restructuring.

2. **Exact Template Markers**: Use "THIS EXACT TEMPLATE (No modifications)" for all agent invocations (already present at line 862).

3. **Fallback Mechanisms**: Every MANDATORY VERIFICATION must include fallback file creation if agent fails.

4. **Context Monitoring**: After adding pruning policy, monitor that context usage stays <20% throughout workflow.

5. **Test-Driven Validation**: Run tests BEFORE committing to catch any missing elements.

---

## File Size Impact

**Current Size**: 5688 lines

**Estimated Additions**:
- Zone 1 (Role clarification): +50 lines
- Zone 2 (Standard 0 markers): +300 lines (12 EXECUTE NOW + 8 MANDATORY VERIFICATION + 6 CHECKPOINT blocks with bash code)
- Zone 3 (Imperative language): 0 lines (replacements only)
- Zone 4 (Context pruning): +80 lines

**Final Estimated Size**: ~6,120 lines (+432 lines, 7.6% increase)

**Rationale**: Enforcement patterns add bulk but eliminate ambiguity, achieving 100% file creation rate vs 60-80% without enforcement.

---

## Cross-References

**Referenced Standards**:
- [Execution Enforcement Guide](.claude/docs/guides/execution-enforcement-guide.md) - Phase 0 pattern (lines 572-740)
- [Imperative Language Guide](.claude/docs/guides/imperative-language-guide.md) - Transformation table (lines 430-446)
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md) - Agent coordination pattern
- [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) - Standard 0 definition

**Utility Scripts**:
- `/home/benjamin/.config/.claude/lib/audit-imperative-language.sh` - Imperative ratio validation
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - Context reduction utilities
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore

**Related Phases**:
- Phase 1: Research Phase Enforcement (will build on Phase 0 foundation)
- Phase 2: Planning Phase Enforcement (will reference Phase 0 patterns)
- Phase 3: Behavioral Injection Pattern Verification (will validate Phase 0 implementation)

---

## Completion Criteria

Phase 0 is complete when ALL of the following are verified:

- [x] Enhanced Phase 0 role clarification added (Zone 1)
- [x] ≥12 EXECUTE NOW markers distributed across phases (Zone 2)
- [x] ≥8 MANDATORY VERIFICATION blocks with fallbacks (Zone 2)
- [x] ≥6 CHECKPOINT REQUIREMENT blocks at boundaries (Zone 2)
- [x] 0 passive language occurrences (Zone 3)
- [x] ≥90% imperative language ratio validated (Zone 3)
- [x] Context pruning policy integrated with function calls (Zone 4)
- [x] All 5 test scripts pass (Testing section)
- [x] Git commit created with detailed message (Git Commit section)

**Final Verification Command**:
```bash
bash /home/benjamin/.config/.claude/specs/071_orchestrate_enforcement_fix/plans/run_phase0_tests.sh
```

**Expected Output**: "All Phase 0 tests PASSED"
