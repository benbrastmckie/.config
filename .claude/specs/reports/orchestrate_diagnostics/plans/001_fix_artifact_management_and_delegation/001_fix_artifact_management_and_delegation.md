# Fix /orchestrate Artifact Management and Subagent Delegation

## Metadata
- **Date**: 2025-10-17
- **Feature**: Fix critical artifact management failures in /orchestrate command
- **Scope**: Research agent prompts, planning phase delegation, command execution patterns
- **Estimated Phases**: 4
- **Structure Level**: 1 (Phases expanded)
- **Expanded Phases**: [1, 3]
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/.claude/specs/reports/orchestrate_diagnostics/001_critical_artifact_management_failures.md
- **Related Plans**:
  - 056_complete_topic_based_spec_organization.md (topic structure guidelines)
  - 062_orchestrate_validation_and_documentation.md (validation approach)

## Overview

This plan addresses CRITICAL failures in `/orchestrate` command's artifact management and subagent delegation patterns. Currently:

1. **Research agents don't create report files** - Return summaries inline (413k tokens consumed vs <600 chars target)
2. **Planning phase uses wrong delegation** - Orchestrator calls SlashCommand(/plan) instead of Task(plan-architect)
3. **Context preservation failed** - 0% reduction vs 92-97% target
4. **Artifacts missing** - No research reports created for cross-referencing

**Root Causes**:
- Research agent prompts missing explicit file creation instructions
- No absolute report paths calculated before agent invocation
- Planning phase skips agent delegation layer
- "EXECUTE NOW" imperative instructions missing throughout command

## Success Criteria
- [ ] Research agents create report files in specs/reports/{topic}/NNN_*.md
- [ ] Research agents return `REPORT_PATH: /absolute/path` + brief summary only
- [ ] Context usage <10k tokens for research phase (not 308k+)
- [ ] Planning phase delegates to plan-architect agent via Task tool
- [ ] All slash commands invoked BY agents, not BY orchestrator
- [ ] Complete artifact chain: reports → plan → implementation → summary
- [ ] Test suite validates artifact creation and delegation patterns

## Technical Design

### Delegation Hierarchy

**Correct Pattern**:
```
Orchestrator (/orchestrate)
  ├─ Task(research-specialist #1) → creates report file → returns REPORT_PATH
  ├─ Task(research-specialist #2) → creates report file → returns REPORT_PATH
  ├─ Task(research-specialist #3) → creates report file → returns REPORT_PATH
  ├─ Task(plan-architect)
  │   └─ plan-architect uses SlashCommand(/plan with report paths)
  │       → creates plan file → returns PLAN_PATH
  ├─ Task(code-writer)
  │   └─ code-writer uses SlashCommand(/implement with plan path)
  │       → executes phases → returns status + files modified
  ├─ Task(debug-specialist) [if tests fail]
  │   └─ creates debug report → returns DEBUG_REPORT_PATH
  └─ Task(doc-writer)
      └─ doc-writer uses SlashCommand(/document)
          → updates docs + creates summary → returns SUMMARY_PATH
```

**Current Broken Pattern**:
```
Orchestrator
  ├─ Task(research agents) → returns 150-word summaries (NO FILES)
  ├─ SlashCommand(/plan) [WRONG - no agent layer]
  └─ ...
```

### Report Path Calculation

**Before invoking research agents**, orchestrator must:
1. Identify research topics (2-4 topics)
2. For each topic:
   - Create topic directory: `specs/reports/{topic}/`
   - Find next number: `get_next_artifact_number()`
   - Construct absolute path: `/full/path/to/specs/reports/{topic}/NNN_topic_analysis.md`
3. Pass absolute path to each agent in prompt

### Research Agent Prompt Template

**Required Structure**:
```markdown
**CRITICAL: Create Report File**

You MUST create a research report file using the Write tool at this EXACT path:

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md

DO NOT:
- Return only a summary
- Use relative paths
- Calculate the path yourself

DO:
- Use Write tool with exact path above
- Create complete report (not abbreviated)
- Return: REPORT_PATH: [path]

[Rest of research requirements...]

## Expected Output

**Primary Output**:
```
REPORT_PATH: [ABSOLUTE_REPORT_PATH]
```

**Secondary Output**: Brief summary (1-2 sentences ONLY)
```

## Implementation Phases

### Phase 1: Fix Research Agent Prompts (High)
**Objective**: Update /orchestrate research phase to create report files with absolute paths
**Status**: PENDING

**Summary**: Implements pre-invocation report path calculation, explicit file creation instructions in agent prompts, post-completion verification of report files, and proper forward_message integration to achieve 97% context reduction.

**Key Changes**:
- Add absolute path calculation before agent invocation (using `get_next_artifact_number()`)
- Update agent prompt template with "CRITICAL: Create Report File" instructions
- Add report file verification checkpoint (existence, non-empty, REPORT_PATH parsing)
- Ensure metadata extraction operates on FILES not inline summaries

**Success Criteria**:
- Research agents create report files at absolute paths
- Context usage <10k tokens (not 308k+)
- 97% context reduction achieved

For detailed implementation tasks, testing specifications, and validation checklists, see [Phase 1 Details](phase_1_fix_research_agent_prompts.md)

### Phase 2: Fix Planning Phase Delegation
**Objective**: Change planning phase to delegate to plan-architect agent instead of direct /plan invocation
**Complexity**: Medium

Tasks:
- [ ] Read current /orchestrate planning phase (.claude/commands/orchestrate.md:612-727)
- [ ] Remove direct SlashCommand(/plan) invocation
- [ ] Add plan-architect agent delegation
  - [ ] Create Task tool invocation with general-purpose subagent_type
  - [ ] Reference plan-architect.md behavioral guidelines
  - [ ] Pass workflow description, thinking mode, CLAUDE.md path
  - [ ] Pass research report PATHS (not summaries) as array
  - [ ] Instruct agent to use Read tool for report content
  - [ ] Agent internally calls SlashCommand(/plan) with report paths
- [ ] Update plan-architect prompt template
  ```markdown
  Read and follow: .claude/agents/plan-architect.md

  ## Planning Task

  ### Context
  - Workflow: [description]
  - Thinking Mode: [mode]
  - Standards: /home/benjamin/.config/CLAUDE.md

  ### Research Reports Available
  [For each report path]
  - [path]

  Use Read tool to access report content.

  ### Your Task
  1. Read all research reports
  2. Invoke SlashCommand: /plan "[description]" [report_path1] [report_path2]
  3. Verify plan file created
  4. Return: PLAN_PATH: /absolute/path/to/plan.md

  ## Expected Output
  PLAN_PATH: [path]
  Brief summary (1-2 sentences)
  ```
- [ ] Add plan file verification
  - [ ] Parse PLAN_PATH from agent output
  - [ ] Verify file exists
  - [ ] Verify plan references research reports (grep for report filenames)
  - [ ] Store plan path for implementation phase

Testing:
```bash
# Execute /orchestrate with research phase
/orchestrate "Medium complexity feature"

# Monitor for correct delegation
# Should see: Task(plan-architect) NOT SlashCommand(/plan)

# Verify plan file created
PLAN=$(find .claude/specs/plans -name "[0-9][0-9][0-9]_*.md" -mmin -5)
[ -f "$PLAN" ] || echo "FAIL: Plan file not created"

# Verify plan references reports
REPORT_COUNT=$(grep -c "specs/reports/" "$PLAN" || echo 0)
[ $REPORT_COUNT -ge 2 ] || echo "FAIL: Plan doesn't reference reports"
```

Validation:
- Orchestrator invokes plan-architect via Task tool
- plan-architect internally calls /plan via SlashCommand
- Plan file created with proper cross-references
- No direct SlashCommand(/plan) by orchestrator

### Phase 3: Add "EXECUTE NOW" Blocks Throughout /orchestrate (High)
**Objective**: Convert documentation-style command to imperative execution instructions
**Status**: PENDING

**Summary**: Transforms /orchestrate from documentation-style descriptions into actionable execution scripts by adding "EXECUTE NOW" blocks, inline tool invocation examples, verification checklists, and explicit failure handling for all major phases.

**Key Changes**:
- Add ≥15 "EXECUTE NOW" blocks across all phases (research, planning, implementation, debugging, documentation)
- Include copy-paste ready code examples (bash utilities, Task tool invocations, SlashCommand patterns)
- Add verification checklists after each execution block
- Document failure conditions and escalation criteria
- Add phase transition logging and decision point branching logic

**Success Criteria**:
- All major phases have explicit execution instructions
- Command structure is action-oriented (not descriptive)
- AI assistants know exactly when to execute vs acknowledge

For detailed implementation tasks, execution patterns, inline examples, and testing specifications, see [Phase 3 Details](phase_3_add_execute_now_blocks.md)

### Phase 4: Create Test Suite and Validation
**Objective**: Build comprehensive tests to prevent regression
**Complexity**: Medium

Tasks:
- [ ] Create test file `.claude/tests/test_orchestrate_artifact_creation.sh`
- [ ] Implement test_research_creates_report_files()
  ```bash
  test_research_creates_report_files() {
    local workflow="Test simple feature"

    # Execute /orchestrate
    local output=$(/orchestrate "$workflow")

    # Verify reports created
    local report_count=$(find .claude/specs/reports -name "[0-9][0-9][0-9]_*.md" -mmin -2 | wc -l)
    [ $report_count -ge 2 ] || {
      echo "FAIL: Expected ≥2 reports, found $report_count"
      return 1
    }

    # Verify REPORT_PATH format in output
    echo "$output" | grep -q "REPORT_PATH: /" || {
      echo "FAIL: No REPORT_PATH found in output"
      return 1
    }

    return 0
  }
  ```
- [ ] Implement test_planning_delegates_to_agent()
  ```bash
  test_planning_delegates_to_agent() {
    local output=$(/orchestrate "Test feature")

    # Verify plan-architect agent invoked (not direct /plan)
    echo "$output" | grep -q "Task.*plan-architect" || {
      echo "FAIL: plan-architect not invoked via Task"
      return 1
    }

    # Verify no direct SlashCommand(/plan)
    echo "$output" | grep -q "SlashCommand.*plan" && {
      echo "FAIL: Direct /plan invocation found"
      return 1
    }

    return 0
  }
  ```
- [ ] Implement test_context_usage_under_threshold()
  ```bash
  test_context_usage_under_threshold() {
    local output=$(/orchestrate "Test feature")

    # Parse token usage from agent output
    local research_tokens=$(echo "$output" | grep "Done.*tokens" | awk '{sum+=$5} END {print sum}')

    # Verify <10k tokens (not 308k+)
    [ $research_tokens -lt 10000 ] || {
      echo "FAIL: Context usage too high: ${research_tokens}k tokens"
      return 1
    }

    return 0
  }
  ```
- [ ] Implement test_complete_artifact_chain()
  ```bash
  test_complete_artifact_chain() {
    /orchestrate "Complete test workflow"

    # Verify artifact chain
    local reports=$(find .claude/specs/reports -name "[0-9][0-9][0-9]_*.md" -mmin -5 | wc -l)
    local plans=$(find .claude/specs/plans -name "[0-9][0-9][0-9]_*.md" -mmin -5 | wc -l)
    local summaries=$(find .claude/specs/summaries -name "[0-9][0-9][0-9]_*.md" -mmin -5 | wc -l)

    [ $reports -ge 2 ] || return 1
    [ $plans -eq 1 ] || return 1
    [ $summaries -eq 1 ] || return 1

    # Verify cross-references
    local plan_file=$(find .claude/specs/plans -name "[0-9][0-9][0-9]_*.md" -mmin -5 | head -1)
    grep -q "Research Reports:" "$plan_file" || return 1

    return 0
  }
  ```
- [ ] Add test runner logic
  ```bash
  #!/bin/bash

  # Source utilities
  source .claude/lib/artifact-operations.sh

  # Run tests
  tests=(
    test_research_creates_report_files
    test_planning_delegates_to_agent
    test_context_usage_under_threshold
    test_complete_artifact_chain
  )

  passed=0
  failed=0

  for test in "${tests[@]}"; do
    echo "Running $test..."
    if $test; then
      echo "  PASS"
      ((passed++))
    else
      echo "  FAIL"
      ((failed++))
    fi
  done

  echo ""
  echo "Results: $passed passed, $failed failed"
  [ $failed -eq 0 ] && exit 0 || exit 1
  ```
- [ ] Add test suite to run_all_tests.sh (.claude/tests/run_all_tests.sh)
  ```bash
  # Add to test list
  echo "Running orchestrate artifact creation tests..."
  .claude/tests/test_orchestrate_artifact_creation.sh || exit 1
  ```
- [ ] Create validation script `.claude/lib/validate-orchestrate.sh`
  ```bash
  #!/bin/bash
  # Validate /orchestrate command structure

  COMMAND_FILE=".claude/commands/orchestrate.md"

  # Check for EXECUTE NOW blocks
  execute_count=$(grep -c "EXECUTE NOW" "$COMMAND_FILE")
  [ $execute_count -ge 15 ] || {
    echo "ERROR: Insufficient EXECUTE NOW blocks (found $execute_count, need ≥15)"
    exit 1
  }

  # Check for Task tool invocations (not SlashCommand for phases)
  task_research=$(grep -A 20 "Research Phase" "$COMMAND_FILE" | grep -c "Task tool")
  task_planning=$(grep -A 20 "Planning Phase" "$COMMAND_FILE" | grep -c "Task tool")

  [ $task_research -gt 0 ] || echo "WARNING: Research phase missing Task tool pattern"
  [ $task_planning -gt 0 ] || echo "WARNING: Planning phase missing Task tool pattern"

  # Check for verification checklists
  verify_count=$(grep -c "Verification Checklist" "$COMMAND_FILE")
  [ $verify_count -ge 5 ] || {
    echo "ERROR: Insufficient verification checklists (found $verify_count, need ≥5)"
    exit 1
  }

  echo "✓ All validations passed"
  exit 0
  ```

Testing:
```bash
# Run test suite
.claude/tests/test_orchestrate_artifact_creation.sh

# Run validation script
.claude/lib/validate-orchestrate.sh

# Verify all tests pass
[ $? -eq 0 ] || echo "FAIL: Tests or validation failed"
```

Validation:
- All 4 test cases pass
- Validation script reports no errors
- Tests run in CI/CD pipeline (if applicable)
- Test coverage ≥80% for artifact creation logic

## Testing Strategy

### Unit Tests (Command Structure)
- Test report path calculation logic
- Test agent prompt template generation
- Test artifact verification functions

### Integration Tests (Full Workflow)
- Test complete /orchestrate execution
- Verify all artifacts created in correct locations
- Verify cross-references between artifacts

### Regression Tests (Prevent Future Issues)
- Test that direct SlashCommand invocations don't reappear
- Test that research agents always create files
- Test context usage stays below threshold

## Documentation Requirements

### Files to Update
1. `.claude/commands/orchestrate.md` - Primary implementation (Phases 1-3)
2. `.claude/tests/test_orchestrate_artifact_creation.sh` - New test file (Phase 4)
3. `.claude/lib/validate-orchestrate.sh` - New validation script (Phase 4)
4. `.claude/tests/run_all_tests.sh` - Add new test suite (Phase 4)

### Documentation Updates
- Update CLAUDE.md with corrected context reduction metrics (after verification)
- Add note to hierarchical_agents.md about importance of file creation over summaries
- Document imperative command structure in command_architecture_standards.md

## Dependencies

### Internal Dependencies
- `.claude/lib/artifact-operations.sh` - `get_next_artifact_number()`
- `.claude/agents/research-specialist.md` - Agent behavioral guidelines
- `.claude/agents/plan-architect.md` - Agent behavioral guidelines
- `.claude/templates/orchestration-patterns.md` - Prompt templates (verify correctness)

### External Dependencies
- Bash 4.0+ (associative arrays for report paths)
- jq (for metadata parsing, if needed)
- find, grep (for artifact verification)

## Risk Assessment

### High-Risk Areas
- **Phase 1 (Research prompts)**: Risk of breaking existing (limited) functionality
  - Mitigation: Test with simple workflows first, validate each change
- **Phase 3 (Imperative structure)**: Risk of making command too rigid
  - Mitigation: Preserve descriptive context, add execution blocks alongside

### Medium-Risk Areas
- **Phase 2 (Planning delegation)**: Risk of plan creation failures
  - Mitigation: Extensive testing, fallback to direct /plan if agent fails
- **Phase 4 (Testing)**: Risk of tests being too brittle
  - Mitigation: Test for behaviors not exact outputs, allow timing variance

### Low-Risk Areas
- **Validation scripts**: New scripts, no breaking changes
- **Documentation**: Clarifications and improvements only

## Notes

### Research Integration

This plan directly addresses findings from `001_critical_artifact_management_failures.md`:

1. **Issue 1**: Research agents not creating files
   - **Fix**: Phase 1 adds explicit file creation instructions + absolute paths

2. **Issue 2**: Planning phase wrong delegation
   - **Fix**: Phase 2 changes to Task(plan-architect) pattern

3. **Issue 3**: Documentation-only structure
   - **Fix**: Phase 3 adds "EXECUTE NOW" imperative blocks

4. **Issue 4**: Missing report path calculation
   - **Fix**: Phase 1 adds path calculation before agent invocation

### Phased Approach Rationale

- **Phase 1**: Research fixes are most critical (highest context impact)
- **Phase 2**: Planning delegation depends on research working correctly
- **Phase 3**: Imperative structure is broad improvement across all phases
- **Phase 4**: Testing validates all prior phases work correctly

### Success Metrics

**Before Implementation**:
- Research phase context: 308k+ tokens
- Report files created: 0
- Direct /plan invocation: Yes
- Context reduction: 0%

**After Implementation**:
- Research phase context: <10k tokens (97% reduction)
- Report files created: 2-4 (100% success rate)
- Agent delegation: 100% compliance
- Context reduction: 92-97% (meeting target)

### Future Enhancements

After this plan completes:
- Apply same patterns to other commands (/report, /debug, /implement)
- Create command structure linter (validate EXECUTE NOW blocks)
- Add performance benchmarking for context reduction
- Create interactive debugging mode for workflow execution
