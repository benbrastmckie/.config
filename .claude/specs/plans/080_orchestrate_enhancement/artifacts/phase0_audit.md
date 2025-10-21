# SlashCommand Audit Report

## Audit Date
2025-10-21

## Executive Summary

**Finding**: The `/orchestrate` command does NOT use the `SlashCommand` tool directly, but it DOES instruct subagents to invoke slash commands (`/implement`) in their prompts. This violates the documented Behavioral Injection Pattern and causes the same problems as direct SlashCommand usage.

**Critical Instance Found**: 1 instance
**Command-to-Command Invocations**: 1 (`/implement` in line 1493)
**Architectural Pattern Compliance**: ❌ FAIL

## Instance Analysis

### Instance 1: /implement invocation
- **Location**: Line 1493
- **Phase**: Phase 3 (Implementation)
- **Current Implementation**:
  ```json
  {
    "subagent_type": "general-purpose",
    "description": "Execute implementation plan NNN using code-writer",
    "timeout": 600000,
    "prompt": "Read: .claude/agents/code-writer.md\n\n/implement [plan_path]"
  }
  ```
- **Problem**: The prompt instructs the code-writer agent to invoke `/implement` slash command
- **Purpose**: Execute plan phase-by-phase with testing
- **Context Required**:
  - Plan path
  - Artifact paths for debug/outputs
  - Git commit format
  - Topic directory context
- **Replacement Strategy**: Replace agent prompt with direct implementation instructions following code-writer behavioral guidelines, injecting artifact paths
- **Replacement Agent**: code-writer.md (enhanced with behavioral injection)

### Planning Phase Analysis
- **Location**: Lines 1140-1178
- **Phase**: Phase 2 (Planning)
- **Current Implementation**: ✅ CORRECT
  ```yaml
  Task {
    subagent_type: "general-purpose"
    description: "Create implementation plan using plan-architect behavioral guidelines"
    timeout: 600000
    prompt: "
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

      You are acting as a Plan Architect Agent.
      ...
      **CRITICAL REQUIREMENTS**:
      1. CREATE plan file at EXACT path above using Write tool (not SlashCommand)
      ...
    "
  }
  ```
- **Status**: Already uses correct pattern - behavioral injection with explicit artifact path
- **Action Required**: None (already compliant)

### Debugging Phase Analysis
- **Search Result**: No /debug command invocations found
- **Status**: Phase appears to not exist yet or uses correct pattern
- **Action Required**: Verify debugging phase implementation when encountered

### Documentation Phase Analysis
- **Search Result**: No /document command invocations found
- **Status**: Phase appears to not exist yet or uses correct pattern
- **Action Required**: Verify documentation phase implementation when encountered

## Context Requirements Analysis

### What information does /implement need?
From the current implementation prompt analysis:
1. **Plan file path** - Absolute path to the implementation plan
2. **Artifact directory context** - Where to save debug reports, test outputs, generated scripts
3. **Topic directory** - For organizing all artifacts (`${WORKFLOW_TOPIC_DIR}`)
4. **Topic number** - For git commit messages (`feat(NNN): ...`)
5. **Testing protocols** - From CLAUDE.md, discovered at runtime
6. **Git commit format** - Standardized format for phase commits

### What artifacts does /implement create?
1. **Modified source files** - Actual implementation code
2. **Debug reports** (if issues occur) - Should go to `${WORKFLOW_TOPIC_DIR}/debug/`
3. **Test outputs** - Should go to `${WORKFLOW_TOPIC_DIR}/outputs/`
4. **Temporary scripts** - Should go to `${WORKFLOW_TOPIC_DIR}/scripts/`
5. **Plan updates** - Progress markers and task checkboxes in plan file
6. **Git commits** - One per phase completion
7. **Checkpoints** - If context window constrained

### What metadata MUST be returned to orchestrator?
From verification code analysis (lines 1499-1542):
1. **IMPLEMENTATION_STATUS**: complete|partial|failed
2. **TESTS_PASSING**: true|false
3. **PHASES_COMPLETED**: "N/N" format
4. **FILES_MODIFIED**: Array of file paths
5. **GIT_COMMITS**: Array of commit hashes
6. **CHECKPOINT_PATH**: Path if checkpoint created, "none" otherwise
7. **FAILURE_REASON**: If failed, brief description
8. **FAILED_TESTS**: If tests failed, list of test names
9. **TEST_OUTPUT_PATH**: Path to test failure output

## Recommended Replacements

### Instance 1: /implement → code-writer with behavioral injection

**Remove** (line 1493):
```json
"prompt": "Read: .claude/agents/code-writer.md\n\n/implement [plan_path]"
```

**Replace with**:
```yaml
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
```

## Implementation Strategy

1. **Stage 2: Not Required** - Planning phase already uses correct pattern
2. **Stage 3: REQUIRED** - Replace /implement invocation with behavioral injection
3. **Stage 4: Verify** - Check if debugging phase exists and uses correct pattern
4. **Stage 5: Verify** - Check if documentation phase exists and uses correct pattern
5. **Stage 6: Required** - Add validation script regardless of findings above

## Success Criteria

After refactoring:
- [ ] Zero instances of `/plan`, `/implement`, `/debug`, `/document` in Task prompts
- [ ] All agent prompts include behavioral guidelines reference
- [ ] All agent prompts include explicit artifact path injection
- [ ] All agent prompts include RETURN FORMAT specification
- [ ] Validation script passes with 0 violations

## Risk Assessment

**Low Risk Refactoring**:
- Planning phase already compliant - no changes needed
- Implementation phase has single clear violation - straightforward fix
- Debugging/documentation phases appear not to violate pattern

**Testing Requirements**:
- Verify refactored implementation phase creates artifacts in correct locations
- Verify plan updates work correctly
- Verify git commits use correct format with topic number
- Verify checkpoint creation works

## Conclusion

The audit reveals that `/orchestrate` is **partially compliant** with the Behavioral Injection Pattern:

**✅ Compliant**:
- Planning phase (lines 1140-1178): Uses Task tool with behavioral injection

**❌ Non-Compliant**:
- Implementation phase (line 1493): Instructs agent to invoke `/implement` command

**🔍 Needs Verification**:
- Debugging phase: No violations found in search, but may not be fully implemented
- Documentation phase: No violations found in search, but may not be fully implemented

**Recommended Action**: Proceed with Stage 3 to fix implementation phase, then verify and potentially implement debugging/documentation phases if missing.
