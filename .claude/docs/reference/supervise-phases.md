# /supervise Phase Reference

## Overview

This document provides detailed documentation for each phase in the `/supervise` orchestration workflow. The command executes phases conditionally based on detected workflow scope.

## Phase Transition Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     Phase 0: Initialization                   │
│  • Detect workflow scope (research/plan/implement/debug)     │
│  • Calculate all artifact paths                              │
│  • Create topic directory structure                          │
└──────────────┬───────────────────────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────────────────────┐
│              Phase 1: Research (2-4 parallel agents)          │
│  • Invoke specialized research agents                        │
│  • Mandatory verification: Check files created               │
│  • Extract metadata for context reduction (95%)              │
└──────────────┬───────────────────────────────────────────────┘
               │
               ↓ (Conditional: research-and-plan or full-implementation)
┌──────────────────────────────────────────────────────────────┐
│              Phase 2: Planning (conditional)                  │
│  • Create implementation plan from research                  │
│  • Mandatory verification: Plan file exists                  │
│  • Auto-complexity evaluation for adaptive planning          │
└──────────────┬───────────────────────────────────────────────┘
               │
               ↓ (Conditional: full-implementation only)
┌──────────────────────────────────────────────────────────────┐
│          Phase 3: Implementation (conditional)                │
│  • Execute implementation plan phase-by-phase                │
│  • Checkpoint recovery between phases                        │
│  • Wave-based parallel execution (40-60% time savings)       │
└──────────────┬───────────────────────────────────────────────┘
               │
               ↓ (Conditional: full-implementation only)
┌──────────────────────────────────────────────────────────────┐
│              Phase 4: Testing (conditional)                   │
│  • Run project test suite per CLAUDE.md                      │
│  • Enhanced error reporting for failures                     │
│  • Triggers Phase 5 if tests fail                            │
└──────────────┬───────────────────────────────────────────────┘
               │
               ├→ (Tests Pass) → Phase 6
               │
               ↓ (Tests Fail) → Phase 5
┌──────────────────────────────────────────────────────────────┐
│         Phase 5: Debug (conditional on test failure)          │
│  • Root cause analysis with parallel agents                  │
│  • Create debug report with findings                         │
│  • Suggest fixes (does not auto-apply)                       │
└──────────────┬───────────────────────────────────────────────┘
               │
               ↓
┌──────────────────────────────────────────────────────────────┐
│       Phase 6: Documentation (conditional on implementation)  │
│  • Update relevant documentation                             │
│  • Create implementation summary                             │
│  • Link all artifacts (reports, plan, summary)               │
└──────────────────────────────────────────────────────────────┘
```

## Phase 0: Project Location and Path Pre-Calculation

### Objective

Establish topic directory structure and calculate all artifact paths before any agent invocations.

### Pattern

Utility-based location detection → directory creation → path export

### Key Features

- **Optimization**: Uses deterministic bash utilities (topic-utils.sh, detect-project-dir.sh) for 85-95% token reduction and 20x+ speedup compared to agent-based detection
- **Critical Requirement**: ALL paths MUST be calculated before Phase 1 begins
- **Checkpoint Resume**: Checks for existing checkpoint and auto-resumes from last completed phase

### Steps

**STEP 1**: Parse workflow description from command arguments
- Validate workflow description provided
- Check for existing checkpoint (auto-resume capability)
- Display resume information if checkpoint found

**STEP 2**: Detect workflow scope
- Analyze description to determine: research-only, research-and-plan, full-implementation, or debug-only
- Map scope to phase execution list
- Export scope and phase list for conditional execution

**STEP 3**: Initialize workflow paths using consolidated function
- Use workflow-initialization.sh library for unified path calculation
- Implements 3-step pattern: scope detection → path pre-calculation → directory creation
- Consolidates 225+ lines to ~10 lines

### Success Criteria

- Workflow scope correctly detected (4 possible scopes)
- All artifact paths calculated and exported
- Topic directory created
- Phase execution plan established
- Checkpoint resume working (if applicable)

## Phase 1: Research

### Objective

Invoke 2-4 specialized research agents in parallel to gather information on the workflow topic.

### Pattern

Parallel agent invocation → mandatory verification → metadata extraction

### Key Features

- **Parallelization**: 2-4 research agents run simultaneously (40-60% time savings)
- **Mandatory Verification**: Check that all agents create expected files
- **Metadata Extraction**: Extract title + 50-word summary for 95% context reduction
- **Partial Failure Handling**: Continue if ≥50% of agents succeed
- **Auto-Recovery**: Single retry for transient failures (timeouts, file locks)

### Agent Invocation Pattern

**CRITICAL**: Use Task tool with behavioral injection, NOT SlashCommand

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [subtopic]"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Report Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Research Topic: [specific subtopic]
    - Project Context: [path to CLAUDE.md]

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

### Verification Checkpoint

```bash
# Mandatory verification after all agents complete
for report_path in "${REPORT_PATHS[@]}"; do
  if [ ! -f "$report_path" ]; then
    # Enhanced error reporting with location and recovery suggestions
    echo "ERROR: Research agent failed to create expected file"
    echo "Expected: $report_path"
    suggest_recovery "missing_file" "$report_path"
    exit 1
  fi
done
```

### Success Criteria

- All research agents invoked in parallel
- File creation rate: 100% (with single retry for transient failures)
- Metadata extracted from all reports (95% context reduction)
- Partial failure handling: ≥50% success threshold
- Progress markers emitted at phase transitions

## Phase 2: Planning (Conditional)

### Objective

Create implementation plan based on research findings.

### Pattern

Metadata-based planning → mandatory verification → complexity evaluation

### Execution Condition

Runs only for: research-and-plan, full-implementation workflows

### Key Features

- **Metadata-Based Context**: Uses extracted metadata (250 tokens) instead of full reports (5,000 tokens)
- **Adaptive Planning**: Auto-evaluates plan complexity (expansion threshold: 8.0)
- **Mandatory Verification**: Check that plan file created
- **Complexity Tracking**: Log complexity score for adaptive replanning

### Agent Invocation Pattern

```yaml
Task {
  subagent_type: "Plan"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [array of report metadata]
    - Project Standards: [path to CLAUDE.md]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

### Success Criteria

- Plan agent invoked with metadata context (not full reports)
- Plan file created and verified
- Complexity score calculated
- Auto-expansion triggered if complexity > 8.0
- Ready for /implement execution

## Phase 3: Implementation (Conditional)

### Objective

Execute implementation plan phase-by-phase with checkpoint recovery.

### Pattern

Wave-based parallel execution → checkpoint after each phase → testing between phases

### Execution Condition

Runs only for: full-implementation workflows

### Key Features

- **Wave-Based Execution**: Parallel implementation of independent phases (40-60% time savings)
- **Checkpoint Recovery**: Save state after each phase, resume on failure
- **Adaptive Replanning**: Automatic plan revision if complexity/failures detected
- **Phase Dependencies**: Respect phase dependencies for correct execution order

### Agent Invocation Pattern

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Implement Phase N"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/implementation-executor.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH}
    - Phase Number: ${PHASE_NUM}
    - Phase Name: ${PHASE_NAME}
    - Working Directory: [project root]

    Execute implementation following all guidelines in behavioral file.
    Return: PHASE_COMPLETED: ${PHASE_NUM}
  "
}
```

### Success Criteria

- All plan phases executed in wave-based parallel manner
- Checkpoints saved after each phase
- Adaptive replanning triggered if needed (max 2 replans per phase)
- All tests passed before marking phase complete
- Implementation summary created

## Phase 4: Testing (Conditional)

### Objective

Run project test suite according to CLAUDE.md testing protocols.

### Pattern

Test discovery → test execution → enhanced error reporting

### Execution Condition

Runs only for: full-implementation workflows

### Key Features

- **Standards-Based**: Uses test commands from CLAUDE.md
- **Enhanced Error Reporting**: Extract error location, categorize error type
- **Conditional Debug**: Triggers Phase 5 if tests fail
- **Auto-Recovery**: Single retry for transient test failures

### Test Execution Pattern

```bash
# Discover test command from CLAUDE.md
TEST_COMMAND=$(discover_test_command)

# Execute with enhanced error reporting
if ! retry_with_backoff 1 1000 $TEST_COMMAND; then
  # Extract error details
  ERROR_TYPE=$(detect_error_type "$TEST_OUTPUT")
  ERROR_LOCATION=$(extract_location "$TEST_OUTPUT")

  # Generate recovery suggestions
  suggest_recovery "$ERROR_TYPE" "$TEST_OUTPUT"

  # Trigger Phase 5 (Debug)
  TRIGGER_DEBUG=true
  emit_progress "4" "Tests failed - triggering debug phase"
else
  emit_progress "4" "All tests passed"
fi
```

### Success Criteria

- Test command discovered from CLAUDE.md
- Tests executed with retry for transient failures
- Enhanced error reporting on failures (location, type, suggestions)
- Phase 5 triggered conditionally on test failure
- Progress markers emitted

## Phase 5: Debug (Conditional)

### Objective

Perform root cause analysis for test failures or reported bugs.

### Pattern

Parallel hypothesis testing → debug report generation → fix suggestions

### Execution Condition

Runs for:
- debug-only workflows
- full-implementation workflows with test failures

### Key Features

- **Parallel Analysis**: 2-3 debug agents investigate different hypotheses
- **Structured Output**: Debug report with findings, root cause, suggested fixes
- **Non-Destructive**: Suggests fixes but does not auto-apply
- **Integration**: Links to test failure output and implementation artifacts

### Agent Invocation Pattern

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Debug root cause analysis"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/debug-analyst.md

    **Workflow-Specific Context**:
    - Debug Report Path: ${DEBUG_REPORT_PATH} (absolute path, pre-calculated)
    - Error Description: ${ERROR_MSG}
    - Test Output: ${TEST_OUTPUT}
    - Implementation Files: [modified files]

    Execute debug analysis following all guidelines in behavioral file.
    Return: DEBUG_REPORT_CREATED: ${DEBUG_REPORT_PATH}
  "
}
```

### Success Criteria

- Debug agents invoked with error context
- Root cause analysis completed
- Debug report created with structured findings
- Fix suggestions provided (not auto-applied)
- Manual review required before applying fixes

## Phase 6: Documentation (Conditional)

### Objective

Update project documentation and create implementation summary.

### Pattern

Documentation agent → summary generation → artifact linking

### Execution Condition

Runs only for: full-implementation workflows (only if implementation occurred)

### Key Features

- **Selective Updates**: Only updates relevant documentation
- **Summary Generation**: Links all artifacts (reports, plan, implementation)
- **Cross-Referencing**: Updates reports with implementation notes
- **Standards-Based**: Follows documentation standards from CLAUDE.md

### Agent Invocation Pattern

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Update documentation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/documentation-specialist.md

    **Workflow-Specific Context**:
    - Summary Path: ${SUMMARY_PATH} (absolute path, pre-calculated)
    - Plan Path: ${PLAN_PATH}
    - Report Paths: [array of report paths]
    - Modified Files: [implementation changes]

    Execute documentation update following all guidelines in behavioral file.
    Return: SUMMARY_CREATED: ${SUMMARY_PATH}
  "
}
```

### Success Criteria

- Documentation updated per CLAUDE.md standards
- Implementation summary created
- All artifacts cross-referenced (reports ← summary → plan)
- Summary includes: implementation overview, test results, lessons learned
- Ready for review and potential PR creation

## Success Criteria (Workflow-Level)

### Architectural Excellence

- Pure orchestration: Zero SlashCommand tool invocations
- Phase 0 role clarification: Explicit orchestrator vs executor separation
- Workflow scope detection: Correctly identifies 4 workflow patterns
- Conditional phase execution: Skips inappropriate phases based on scope
- Single working path: No fallback file creation mechanisms
- Fail-fast behavior: Clear error messages, immediate termination on failure

### Enforcement Standards

- Imperative language ratio ≥95%: MUST/WILL/SHALL for all required actions
- Step-by-step enforcement: STEP 1/2/3 pattern in all agent templates
- Mandatory verification: Explicit checkpoints after every file operation
- 100% file creation rate with auto-recovery: Single retry for transient failures
- Minimal retry infrastructure: Single-retry strategy (not multi-attempt loops)

### Performance Targets

- File size: 2,000-2,500 lines (achieved)
- Context usage: <25% throughout workflow
- Time efficiency: 15-25% faster for non-implementation workflows
- Code coverage: ≥80% test coverage for scope detection logic
- Recovery rate: >95% for transient errors (timeouts, file locks)
- Performance overhead: <5% for recovery infrastructure
- Checkpoint resume: Seamless auto-resume from phase boundaries

### Auto-Recovery Features

- Transient error auto-recovery: Single retry for timeouts and file locks
- Permanent error fail-fast: Immediate termination with enhanced error reporting
- Error location extraction: Parse file:line from error messages
- Specific error type detection: Categorize into 4 types (timeout, syntax, dependency, unknown)
- Recovery suggestions: Context-specific actionable guidance on failures
- Partial research failure handling: ≥50% success threshold allows continuation
- Progress markers: PROGRESS: [Phase N] emitted at phase transitions
- Checkpoint save/resume: Phase-boundary checkpoints with auto-resume

### Deficiency Resolution

- Research agents create files on first attempt (vs inline summaries)
- Zero SlashCommand usage for planning/implementation (pure Task tool)
- Summaries only created when implementation occurs (not for research-only)

## Related Documentation

- [/supervise Usage Guide](../guides/supervise-guide.md) - Usage patterns and examples
- [Command Reference](command-reference.md) - All available commands
- [Orchestration Troubleshooting](../guides/orchestration-troubleshooting.md) - Advanced debugging
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation pattern
- [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md) - Auto-recovery pattern
- [Checkpoint Recovery Pattern](../concepts/patterns/checkpoint-recovery.md) - Resume capability
