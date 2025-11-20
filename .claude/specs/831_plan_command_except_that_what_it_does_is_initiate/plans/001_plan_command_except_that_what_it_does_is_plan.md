# /repair Command Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Create /repair command using research-and-plan workflow pattern
- **Scope**: New orchestrator command for error analysis and fix planning
- **Estimated Phases**: 6
- **Estimated Hours**: 16
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 0
- **Complexity Score**: 62
- **Research Reports**:
  - [/errors Command Refactor Research](/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/reports/001_errors_command_refactor_research.md)
  - [/repair Command Revision Research](/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/reports/002_repair_command_revision_research.md)
  - [Standards Compliance Research](/home/benjamin/.config/.claude/specs/831_plan_command_except_that_what_it_does_is_initiate/reports/003_repair_revision_standards_compliance.md)

## Overview

This plan creates a NEW `/repair` command that:
1. Reads errors from `.claude/data/logs/errors.jsonl`
2. Invokes the repair-analyst agent to research error patterns and identify root causes
3. Creates structured error analysis reports in the specs directory
4. Passes analysis results to the plan-architect agent to create fix implementation plans
5. Follows the research-and-plan workflow pattern established by `/plan` command

The existing `/errors` command remains unchanged as a simple query utility. The `/repair` command provides systematic error resolution by grouping related errors, identifying patterns, and generating actionable implementation plans that conform to `.claude/docs/` standards.

## Research Summary

Key findings from the research reports:

- **Current /errors state**: Simple 160-line query utility with minimal tools (Bash, Read) - this will remain unchanged
- **Target pattern**: Follow `/plan` command's research-and-plan workflow with 3-block structure (setup, research verification, completion)
- **Agent design**: Create new `repair-analyst` agent following `research-specialist` pattern with 28+ completion criteria
- **Workflow scope**: Use `research-and-plan` scope which matches the exact workflow pattern (research errors, plan fixes)
- **Simplified arguments**: Only error filtering and complexity options needed
- **Clean-break approach**: Agent computes patterns inline with jq rather than adding library functions to minimize coupling
- **Standards compliance**: Requires execution directives, state persistence, agent registry update, proper documentation location

Recommended approach: Create new command with state machine workflow using repair-analyst agent for log analysis and plan-architect for fix planning. Agent performs pattern analysis inline rather than relying on new library functions.

## Success Criteria
- [ ] `/repair` command invokes repair-analyst agent for log analysis
- [ ] Error analysis reports created in `specs/{NNN_topic}/reports/` with proper structure
- [ ] Plan-architect generates fix implementation plans based on error analysis
- [ ] All command authoring standards followed (execution directives, state persistence, subprocess isolation)
- [ ] Agent registry updated with repair-analyst entry
- [ ] Tests pass for new workflow phases including behavioral compliance tests
- [ ] Documentation created in proper location (repair-command-guide.md)

## Technical Design

### Architecture Overview

The `/repair` command follows the established research-and-plan pattern from `/plan`:

```
/repair
    |
    v
[Block 1: Consolidated Setup]
    - Parse arguments (--since, --type, --command, --severity, --complexity)
    - Source libraries with output suppression
    - Initialize state machine with sm_init()
    - Transition to STATE_RESEARCH
    - Initialize workflow paths with research-and-plan scope
    - Persist state variables with append_workflow_state()
    |
    v
[Task: repair-analyst agent]
    - Read error logs from .claude/data/logs/errors.jsonl
    - Group errors by type, command, root cause (inline jq analysis)
    - Create analysis reports in specs/{NNN}/reports/
    - Return REPORT_CREATED signal
    |
    v
[Block 2: Research Verification and Planning Setup]
    - Load workflow state with load_workflow_state()
    - Verify research artifacts (directory exists, files exist, size check)
    - Transition to STATE_PLAN with sm_transition()
    - Prepare plan path with proper numbering
    - Collect research report paths for plan-architect
    |
    v
[Task: plan-architect agent]
    - Read error analysis reports
    - Create fix implementation plan
    - Return PLAN_CREATED signal
    |
    v
[Block 3: Plan Verification and Completion]
    - Verify plan artifacts (file exists, size check)
    - Transition to STATE_COMPLETE
    - Output summary and next steps
```

### Component Interactions

1. **repair-analyst agent** -> reads error logs, performs inline jq pattern analysis, creates analysis reports
2. **plan-architect agent** -> reads reports, creates fix plans
3. **workflow-state-machine.sh** -> manages phase transitions
4. **state-persistence.sh** -> persists state across blocks
5. **error-handling.sh** -> provides existing query_errors() function (no modifications)
6. **agent-registry.json** -> tracks agent metrics

### Key Design Decisions

1. **Use `research-and-plan` workflow scope** - Matches the exact pattern (research errors -> plan fixes), terminal state is `plan`
2. **New command** - Create fresh /repair rather than modifying /errors
3. **Agent naming** - repair-analyst follows naming convention and is distinct from debug-analyst (different purpose)
4. **Inline pattern analysis** - Agent computes patterns with jq queries rather than adding library functions (clean-break, minimal coupling)
5. **3-block structure** - Setup, verification, completion (matches /plan exactly)
6. **Execution directives required** - All bash blocks have `**EXECUTE NOW**:` directive

## Implementation Phases

### Phase 1: Create repair-analyst Agent [COMPLETE]
dependencies: []

**Objective**: Create specialized agent for error log analysis and root cause detection

**Complexity**: High

Tasks:
- [x] Create `/home/benjamin/.config/.claude/agents/repair-analyst.md` following research-specialist pattern
- [x] Add frontmatter with:
  - allowed-tools: Read, Write, Grep, Glob, Bash
  - model: sonnet-4.5
  - model-justification: Complex log analysis, pattern detection, root cause grouping with 28+ completion criteria
  - fallback-model: sonnet-4.5
- [x] Implement 4-step execution process:
  - STEP 1: Verify output path accessible
  - STEP 2: Create report file first (empty placeholder)
  - STEP 3: Perform error analysis
  - STEP 4: Verify completion and return signal
- [x] Add inline jq pattern analysis capabilities:
  - Read JSONL error logs
  - Group errors by type using jq
  - Group errors by command using jq
  - Calculate frequencies and distributions
  - Identify correlated errors and root causes
- [x] Define report structure template:
  - Metadata (Date, Agent, Error Count, Time Range)
  - Executive Summary
  - Error Patterns (frequency, commands affected, root cause, proposed fix)
  - Root Cause Analysis
  - Recommendations
  - References
- [x] Add progress streaming markers (PROGRESS: prefix)
- [x] Create 28+ completion criteria checklist matching research-specialist pattern
- [x] Add verification commands for report validation
- [x] Include imperative language throughout (Execute, Return, Verify)
- [x] Add CHECKPOINT requirements after each step

Testing:
```bash
# Verify agent file created with proper structure
test -f "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
grep -q "allowed-tools:" "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
grep -q "COMPLETION CRITERIA" "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
grep -q "STEP 1" "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
grep -q "STEP 2" "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
grep -q "STEP 3" "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
grep -q "STEP 4" "${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md"
```

**Expected Duration**: 4 hours

### Phase 2: Create /repair Command Structure [COMPLETE]
dependencies: [1]

**Objective**: Create new multi-phase state machine workflow command following /plan pattern

**Complexity**: High

Tasks:
- [x] Create `/home/benjamin/.config/.claude/commands/repair.md` with proper frontmatter:
  ```yaml
  ---
  allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Write
  argument-hint: [--since TIME] [--type TYPE] [--command CMD] [--severity LEVEL] [--complexity 1-4]
  description: Research error patterns and create implementation plan to fix them
  command-type: primary
  dependent-agents:
    - repair-analyst
    - plan-architect
  library-requirements:
    - workflow-state-machine.sh: ">=2.0.0"
    - state-persistence.sh: ">=1.5.0"
  documentation: See .claude/docs/guides/commands/repair-command-guide.md for complete usage guide
  ---
  ```
- [x] Create Block 1: Consolidated Setup with **EXECUTE NOW** directive
  - Parse arguments from user invocation
  - Add --since flag for time filtering (ISO 8601 timestamp)
  - Add --type flag for error type filtering (state_error, validation_error, etc.)
  - Add --command flag for command filtering
  - Add --severity flag for filtering by error severity (low, medium, high, critical)
  - Add --complexity flag support (default: 2)
- [x] Add `set +H` at start of bash block (CRITICAL)
- [x] Source required libraries with output suppression:
  ```bash
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
    echo "ERROR: Failed to source unified-location-detection.sh" >&2
    exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-initialization.sh" >&2
    exit 1
  }
  ```
- [x] Initialize state machine:
  ```bash
  WORKFLOW_TYPE="research-and-plan"
  TERMINAL_STATE="plan"
  COMMAND_NAME="repair"
  WORKFLOW_ID="repair_$(date +%s)"
  STATE_ID_FILE="${HOME}/.claude/tmp/repair_state_id.txt"
  ```
- [x] Initialize state file with init_workflow_state()
- [x] Call sm_init() with return code verification
- [x] Transition to STATE_RESEARCH with sm_transition()
- [x] Initialize workflow paths using research-and-plan scope:
  ```bash
  initialize_workflow_paths "$ERROR_DESCRIPTION" "research-and-plan" "$RESEARCH_COMPLEXITY" ""
  ```
- [x] Create directories: RESEARCH_DIR, PLANS_DIR
- [x] Persist state variables with append_workflow_state():
  - CLAUDE_PROJECT_DIR
  - SPECS_DIR
  - RESEARCH_DIR
  - PLANS_DIR
  - TOPIC_PATH
  - TOPIC_NAME
  - TOPIC_NUM
  - ERROR_FILTERS (JSON with --since, --type, --command, --severity)
  - RESEARCH_COMPLEXITY
- [x] Single summary line output: `echo "Setup complete: $WORKFLOW_ID (research-and-plan, complexity: $RESEARCH_COMPLEXITY)"`

Testing:
```bash
# Test argument parsing
/repair --since 2025-11-19 --type state_error
/repair --complexity 3 --command /build
/repair --severity high
```

**Expected Duration**: 3 hours

### Phase 3: Integrate repair-analyst Agent Invocation [COMPLETE]
dependencies: [2]

**Objective**: Add Task invocation for repair-analyst agent with proper prompt construction

**Complexity**: Medium

Tasks:
- [x] Create Task invocation for repair-analyst agent after Block 1 (NO code block wrapper)
- [x] Add **EXECUTE NOW** directive: `**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst agent.`
- [x] Construct prompt with required elements:
  - Behavioral file path: `${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md`
  - Workflow-Specific Context:
    - Error Filters: ${ERROR_FILTERS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan
  - Imperative instruction: `Execute error analysis according to behavioral guidelines`
  - Required completion signal: `Return: REPORT_CREATED: [path to created report]`
- [x] Use subagent_type: "general-purpose" (not specialized name)

Example Task structure:
```
**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Analyze error logs and create report with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/repair-analyst.md

    You are conducting error analysis for: repair workflow

    **Workflow-Specific Context**:
    - Error Filters: ${ERROR_FILTERS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan

    Execute error analysis according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}
```

Testing:
```bash
# Verify Task invocation syntax in command (no code block wrapper)
grep -A 15 "Task {" "${CLAUDE_PROJECT_DIR}/.claude/commands/repair.md" | head -20
# Should NOT show ```yaml or ``` around Task
```

**Expected Duration**: 2 hours

### Phase 4: Add Research Verification and Planning Phase [COMPLETE]
dependencies: [3]

**Objective**: Create Block 2 for research verification and plan-architect invocation, Block 3 for completion

**Complexity**: Medium

Tasks:
- [x] Create Block 2: Research Verification and Planning Setup
  - Add **EXECUTE NOW** directive
  - Add `set +H` at start
  - Load WORKFLOW_ID from STATE_ID_FILE
  - Re-source libraries (subprocess isolation)
  - Load workflow state with load_workflow_state()
  - Verify research artifacts:
    ```bash
    if [ ! -d "$RESEARCH_DIR" ]; then
      echo "ERROR: Research phase failed to create reports directory" >&2
      exit 1
    fi
    if [ -z "$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null)" ]; then
      echo "ERROR: Research phase failed to create report files" >&2
      exit 1
    fi
    UNDERSIZED_FILES=$(find "$RESEARCH_DIR" -name '*.md' -type f -size -100c 2>/dev/null)
    if [ -n "$UNDERSIZED_FILES" ]; then
      echo "ERROR: Research report(s) too small (< 100 bytes)" >&2
      exit 1
    fi
    ```
  - Transition to STATE_PLAN with sm_transition()
  - Prepare plan path with proper numbering
  - Collect research report paths:
    ```bash
    REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
    REPORT_PATHS_JSON=$(echo "$REPORT_PATHS" | jq -R . | jq -s .)
    ```
  - Persist PLAN_PATH and REPORT_PATHS_JSON
  - Single summary line: `echo "Plan will be created at: $PLAN_PATH"`

- [x] Create Task invocation for plan-architect agent (NO code block wrapper)
  - Add **EXECUTE NOW** directive
  - Pass research reports JSON
  - Pass feature description (error fix summary)
  - Pass plan path
  - Required completion signal: `PLAN_CREATED: ${PLAN_PATH}`

- [x] Create Block 3: Plan Verification and Completion
  - Add **EXECUTE NOW** directive
  - Add `set +H` at start
  - Load workflow state
  - Verify plan artifacts:
    ```bash
    if [ ! -f "$PLAN_PATH" ]; then
      echo "ERROR: Planning phase failed to create plan file" >&2
      exit 1
    fi
    FILE_SIZE=$(wc -c < "$PLAN_PATH")
    if [ "$FILE_SIZE" -lt 500 ]; then
      echo "ERROR: Plan file too small ($FILE_SIZE bytes)" >&2
      exit 1
    fi
    ```
  - Transition to STATE_COMPLETE
  - Call save_completed_states_to_state()
  - Output summary and next steps:
    ```bash
    echo "=== Error Analysis and Planning Complete ==="
    echo ""
    echo "Workflow Type: research-and-plan"
    echo "Specs Directory: $SPECS_DIR"
    echo "Error Analysis Reports: $REPORT_COUNT reports in $RESEARCH_DIR"
    echo "Fix Implementation Plan: $PLAN_PATH"
    echo ""
    echo "Next Steps:"
    echo "- Review plan: cat $PLAN_PATH"
    echo "- Implement fixes: /build $PLAN_PATH"
    ```

Testing:
```bash
# Test full workflow execution
/repair --since 2025-11-19 --complexity 2
# Verify artifacts created
ls -la "${CLAUDE_PROJECT_DIR}/.claude/specs/*/reports/"
ls -la "${CLAUDE_PROJECT_DIR}/.claude/specs/*/plans/"
```

**Expected Duration**: 3 hours

### Phase 5: Update Agent Registry and References [IN PROGRESS]
dependencies: [1]

**Objective**: Add repair-analyst to agent registry and update all references

**Complexity**: Low

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/agents/agent-registry.json`:
  ```json
  {
    "repair-analyst": {
      "type": "specialized",
      "description": "Specialized in error log analysis and root cause pattern detection",
      "category": "analysis",
      "tools": ["Read", "Write", "Grep", "Glob", "Bash"],
      "behavioral_file": ".claude/agents/repair-analyst.md",
      "model": "sonnet-4.5"
    }
  }
  ```
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md`:
  - Add repair-analyst to Agent Directory section (alphabetical order)
  - Add entry to Tool Access Matrix table
  - Update Agent Selection Guidelines section
- [ ] Update `/home/benjamin/.config/.claude/agents/README.md`:
  - Add repair-analyst to Available Agents section
  - Update Command-to-Agent Mapping section

Testing:
```bash
# Verify agent registry entry
jq '.["repair-analyst"]' "${CLAUDE_PROJECT_DIR}/.claude/agents/agent-registry.json"
# Verify agent-reference.md update
grep -q "repair-analyst" "${CLAUDE_PROJECT_DIR}/.claude/docs/reference/standards/agent-reference.md"
```

**Expected Duration**: 1 hour

### Phase 6: Documentation and Testing [NOT STARTED]
dependencies: [4, 5]

**Objective**: Create comprehensive documentation and tests following established patterns

**Complexity**: Medium

Tasks:
- [ ] Create `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md`:
  - Overview and purpose
  - Usage examples with all flags
  - Workflow phases explanation
  - Error filters documentation (--since, --type, --command, --severity)
  - Output directory structure
  - Integration with /errors command
  - Troubleshooting section

- [ ] Create test file: `/home/benjamin/.config/.claude/tests/test_repair_workflow.sh`
  - Test argument parsing (--since, --type, --command, --severity, --complexity)
  - Test workflow phase transitions
  - Test artifact creation verification
  - Test state persistence across blocks
  - Add behavioral compliance tests from testing-protocols.md:
    - File Creation Compliance test
    - Completion Signal Format test
    - STEP Structure Validation test
    - Imperative Language Validation test
    - Verification Checkpoints test
    - File Size Limits test

- [ ] Verify all command authoring standards compliance:
  - [ ] All bash blocks have `**EXECUTE NOW**:` directive
  - [ ] All bash blocks have `set +H` at start
  - [ ] All Task invocations have NO code block wrapper
  - [ ] All Task invocations have imperative instruction
  - [ ] All Task invocations require completion signals
  - [ ] All critical functions have return code verification
  - [ ] Library sourcing uses output suppression `2>/dev/null`
  - [ ] State persistence uses append_workflow_state()
  - [ ] Single summary line per block

Testing:
```bash
# Run test suite
bash "${CLAUDE_PROJECT_DIR}/.claude/tests/test_repair_workflow.sh"
# Verify documentation created
test -f "${CLAUDE_PROJECT_DIR}/.claude/docs/guides/commands/repair-command-guide.md"
# Verify agent reference updated
grep -q "repair-analyst" "${CLAUDE_PROJECT_DIR}/.claude/docs/reference/standards/agent-reference.md"
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Testing
- Test repair-analyst agent completion criteria compliance
- Test argument parsing in /repair command
- Test state persistence functions

### Integration Testing
- Test full workflow execution end-to-end
- Test state machine transitions (research -> plan -> complete)
- Test artifact creation and verification
- Test inter-block state preservation

### Behavioral Compliance Testing
- File Creation Compliance: Agent creates file at exact path specified
- Completion Signal Format: Returns `REPORT_CREATED: [path]` exactly
- STEP Structure Validation: All 4 steps present and numbered
- Imperative Language Validation: Uses Execute, Return, Verify throughout
- Verification Checkpoints: CHECKPOINTs after each step
- File Size Limits: Reports are >100 bytes, plans are >500 bytes

### Functional Testing
- Test error filtering by time, type, command, severity
- Test complexity levels affect research depth
- Test plan generation quality

### Test Commands
```bash
# Unit tests
bash "${CLAUDE_PROJECT_DIR}/.claude/tests/test_repair_workflow.sh"

# Integration test
/repair --since 2025-11-19 --complexity 2
ls -la "${CLAUDE_PROJECT_DIR}/.claude/specs/*/reports/"
ls -la "${CLAUDE_PROJECT_DIR}/.claude/specs/*/plans/"

# Functional tests
/repair --type state_error --complexity 3
/repair --command /build --severity high
```

## Documentation Requirements

### Files to Create
1. `/home/benjamin/.config/.claude/commands/repair.md`
   - Full command implementation with 3-block orchestrator workflow
   - Follows /plan command pattern exactly

2. `/home/benjamin/.config/.claude/agents/repair-analyst.md`
   - Full agent behavioral file following research-specialist pattern
   - 28+ completion criteria checklist

3. `/home/benjamin/.config/.claude/docs/guides/commands/repair-command-guide.md`
   - Comprehensive command guide following existing patterns
   - Usage examples, workflow explanation, troubleshooting

4. `/home/benjamin/.config/.claude/tests/test_repair_workflow.sh`
   - Comprehensive test suite including behavioral compliance tests

### Files to Update
1. `/home/benjamin/.config/.claude/docs/reference/standards/agent-reference.md`
   - Add repair-analyst agent entry
   - Update Tool Access Matrix

2. `/home/benjamin/.config/.claude/agents/README.md`
   - Add repair-analyst to agent listing

3. `/home/benjamin/.config/.claude/agents/agent-registry.json`
   - Add repair-analyst registry entry

## Dependencies

### External Dependencies
- `jq` command for JSON parsing (already used by error-handling.sh)

### Library Dependencies
- `workflow-state-machine.sh` >= 2.0.0
- `state-persistence.sh` >= 1.5.0
- `error-handling.sh` (existing, no modifications)
- `unified-location-detection.sh`
- `workflow-initialization.sh`
- `library-version-check.sh`

### Agent Dependencies
- `plan-architect.md` (existing)
- `repair-analyst.md` (to be created)

## Risk Mitigation

### Technical Risks
1. **Error log format changes** - Mitigation: Use inline jq queries that are resilient to field changes
2. **State machine complexity** - Mitigation: Follow established /plan command pattern exactly (proven pattern)
3. **Agent output parsing** - Mitigation: Use strict completion signal format (REPORT_CREATED, PLAN_CREATED)
4. **Subprocess isolation** - Mitigation: Explicit `set +H`, library re-sourcing, state file persistence

### Implementation Risks
1. **Missing execution directives** - Mitigation: Explicit checklist in Phase 6, validation tests
2. **Agent doesn't create file** - Mitigation: STEP 2 mandates file creation before analysis
3. **Context loss between blocks** - Mitigation: append_workflow_state() for all variables, load_workflow_state() in each block

## Notes

- Phase dependencies enable parallel execution: Phase 5 can run in parallel with Phases 2-4
- This plan uses Tier 1 (single file) structure at Level 0
- If complexity grows during implementation, use `/expand` to create phase directories
- The existing `/errors` command remains unchanged - it continues to serve as the query interface
- `/repair` complements `/errors` by adding automated analysis and fix planning capability
- Clean-break implementation: Agent computes patterns inline rather than modifying error-handling.sh

**Hint**: If phase complexity exceeds estimates, consider using `/expand-phase` to break down into stages.

## Compliance Checklist

Before implementation, verify plan addresses all research findings:

- [x] All 3 research reports listed in metadata
- [x] Phase dependency issue resolved (Phase 5 can run parallel with 2-4)
- [x] Agent computes patterns inline (no library modifications)
- [x] Execution directives specified for all blocks
- [x] State persistence patterns documented
- [x] Agent registry update included (Phase 5)
- [x] Documentation location follows convention (repair-command-guide.md)
- [x] Behavioral compliance tests included (Phase 6)
- [x] 3-block structure matches /plan exactly
- [x] research-and-plan workflow scope used
- [x] Clean-break implementation approach
