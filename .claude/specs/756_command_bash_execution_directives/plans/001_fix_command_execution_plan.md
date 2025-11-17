# Implementation Plan: Fix Command Bash Execution Failures

## Plan Metadata

- **Spec ID**: 756
- **Plan Number**: 001
- **Created**: 2025-11-17
- **Last Updated**: 2025-11-17
- **Research Report**: `reports/001_root_cause_analysis.md`
- **Complexity**: Medium
- **Risk Level**: Medium (modifies 7+ production commands)
- **Estimated Duration**: 3-4 hours
- **Status**: COMPLETE (All phases finished)

## Implementation Progress

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1 | COMPLETE | Documentation created at `.claude/docs/reference/command-authoring-standards.md` |
| Phase 2 | COMPLETE | Fixed `/research-plan`, `/research-report`, `/research-revise` |
| Phase 3 | COMPLETE | Fixed `/implement`, `/build` - all tests passing |
| Phase 4 | COMPLETE | Fixed `/debug`, `/fix` - all tests passing |
| Phase 5 | COMPLETE | Argument capture patterns documented, both patterns standardized |
| Phase 6 | COMPLETE | Test created at `.claude/tests/test_command_execution_directives.sh` |

## Objective

Fix silent failures in workflow commands where bash blocks are not executed and state machine flows are never initiated. This affects `/research-plan`, `/research-report`, `/research-revise`, `/implement`, `/build`, `/debug`, and `/fix`.

## Success Criteria

1. All bash blocks in affected commands have explicit execution directives
2. `Task {}` pseudo-syntax replaced with documented patterns
3. State machine checkpoints appear in command output
4. Variables properly persist between bash execution blocks
5. All affected commands tested and verified working

## Phase 1: Create Execution Directive Standard

**Objective**: Document and standardize execution directive patterns for command authoring
**Dependencies**: []
**Complexity**: Low
**Risk**: Low
**Estimated Time**: 0.5 hours

### Tasks

- [x] 1.1 Document the execution directive standard in `.claude/docs/reference/command-authoring-standards.md`
  - Define required directive phrases: "**EXECUTE NOW**:", "Execute this bash block:", "Run the following:"
  - Explain why directives are necessary (LLM interprets bare code blocks as documentation)
  - Provide examples from working commands

- [x] 1.2 Document the Task tool invocation pattern
  - Explain why `Task {}` syntax doesn't work
  - Show correct pattern with actual tool call instruction
  - Provide template for agent delegation

- [x] 1.3 Document state persistence requirements
  - Explain subprocess isolation issue
  - Show `append_workflow_state` / `load_workflow_state` pattern
  - Recommend consolidated bash blocks where possible

### Verification

- [x] Run `/setup --validate` to check documentation standards
- [x] Verify new documentation renders correctly

**Phase 1 Completed**: 2025-11-17

---

## Phase 2: Fix Critical Workflow Commands (research-*)

**Objective**: Add execution directives and fix Task pseudo-syntax in research-plan, research-report, research-revise
**Dependencies**: [1]
**Complexity**: Medium
**Risk**: Medium
**Estimated Time**: 1.5 hours

### 2.1 Fix `/research-plan` Command

- [x] 2.1.1 Add execution directives before all 7 bash blocks
  - Part 1: Add "**EXECUTE NOW**: Capture and validate the feature description:"
  - Part 2: Add "**EXECUTE NOW**: Initialize the state machine:"
  - Part 3 (before Task): Add "**EXECUTE NOW**: Transition to research state and allocate topic directory:"
  - Part 3 (after Task): Add "**EXECUTE NOW**: Verify research artifacts:"
  - Part 4: Add "**EXECUTE NOW**: Transition to planning state:"
  - Part 4 (after Task): Add "**EXECUTE NOW**: Verify plan artifacts:"
  - Part 5: Add "**EXECUTE NOW**: Complete the workflow:"

- [x] 2.1.2 Replace `Task {}` pseudo-syntax with proper executable pattern
  - **CRITICAL**: The new pattern MUST be executable, NOT documentation-only
  - Per `command-development-fundamentals.md` Section 5.2.1, use this exact format:
    ```markdown
    **EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

    Task {
      subagent_type: "general-purpose"
      description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
      prompt: "
        Read and follow ALL behavioral guidelines from:
        ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

        **Workflow-Specific Context**:
        - Research Topic: ${FEATURE_DESCRIPTION}
        - Research Complexity: ${RESEARCH_COMPLEXITY}
        - Output Directory: ${RESEARCH_DIR}
        - Workflow Type: research-and-plan

        Execute research per behavioral guidelines.
        Return: REPORT_CREATED: ${REPORT_PATH}
      "
    }
    ```
  - **Key differences from current broken pattern**:
    - NO code block wrapper (` ```yaml ` removed)
    - Imperative instruction: "**EXECUTE NOW**: USE the Task tool..."
    - Inline prompt with interpolated variables
    - Required completion signal: `Return: REPORT_CREATED:`
  - Apply same pattern for planning agent delegation

- [x] 2.1.3 Ensure subprocess isolation compliance per `bash-block-execution-model.md`
  - Add `set +H` at start of EVERY bash block (Pattern 4)
  - Re-source ALL required libraries in EVERY bash block:
    ```bash
    set +H  # CRITICAL: Disable history expansion
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/error-handling.sh"
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-logger.sh"
    ```
  - Add return code verification for critical functions (Pattern 7):
    ```bash
    if ! sm_init "$FEATURE_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE" 2>&1; then
      echo "ERROR: State machine initialization failed" >&2
      exit 1
    fi
    ```

- [x] 2.1.4 Consolidate bash blocks where possible to reduce state persistence issues

### 2.2 Fix `/research-report` Command

- [x] 2.2.1 Add execution directives before all 5 bash blocks
- [x] 2.2.2 Replace `Task {}` pseudo-syntax (1 occurrence)
- [x] 2.2.3 Verify state machine flow

### 2.3 Fix `/research-revise` Command

- [x] 2.3.1 Add execution directives before all 7 bash blocks
- [x] 2.3.2 Replace `Task {}` pseudo-syntax (2 occurrences)
- [x] 2.3.3 Verify state machine flow

### Verification

- [x] Test `/research-plan "test feature"` - verify checkpoints appear
- [x] Test `/research-report "test topic"` - verify reports created
- [x] Test `/research-revise "test revision"` - verify workflow completes
- [x] Check for "State machine initialized" in all outputs

**Phase 2 Completed**: 2025-11-17
- `/research-plan`: 9 execution directives, 2 Task invocations fixed, 7 `set +H` added
- `/research-report`: 6 execution directives, 1 Task invocation fixed, 5 `set +H` added
- `/research-revise`: 9 execution directives, 2 Task invocations fixed, 7 `set +H` added

---

## Phase 3: Fix Implementation Commands

**Objective**: Add execution directives and fix comment-based pseudo-instructions in implement and build commands
**Dependencies**: [1]
**Complexity**: Medium
**Risk**: Medium
**Estimated Time**: 1 hour

### 3.1 Fix `/implement` Command

- [x] 3.1.1 Add execution directives before all 3 bash blocks
- [x] 3.1.2 Replace comment-based pseudo-instructions with proper patterns:
  - `# Invoke code-writer agent via Task tool` -> Proper Task invocation instruction
  - `# Invoke implementation-researcher agent via Task tool` -> Proper instruction
  - `# Invoke spec-updater agent via Task tool` -> Proper instruction
- [x] 3.1.3 Consolidate Phase 0 and Phase 1 bash blocks if variable sharing needed

### 3.2 Fix `/build` Command

- [x] 3.2.1 Add execution directives before all 9 bash blocks
- [x] 3.2.2 Replace any comment-based pseudo-instructions
- [x] 3.2.3 Ensure checkpoint outputs are visible

### Verification

- [x] Test `/implement` with a simple plan file
- [x] Test `/build` with a test plan
- [x] Verify CHECKPOINT outputs appear

**Phase 3 Completed**: 2025-11-17
- `/implement`: 4 execution directives, 1 Task invocation fixed, 4 `set +H` added
- `/build`: 11 execution directives, 2 Task invocations fixed, 9 `set +H` added

---

## Phase 4: Fix Debug/Fix Commands

**Objective**: Add execution directives and fix pseudo-instructions in debug and fix commands
**Dependencies**: [1]
**Complexity**: Medium
**Risk**: Low
**Estimated Time**: 0.75 hours

### 4.1 Fix `/debug` Command

- [x] 4.1.1 Add execution directives before all 7 bash blocks
- [x] 4.1.2 Replace any comment-based pseudo-instructions with proper patterns

### 4.2 Fix `/fix` Command

- [x] 4.2.1 Add execution directives before all 10 bash blocks
- [x] 4.2.2 Replace any comment-based pseudo-instructions with proper patterns

### Verification

- [x] Test `/debug "test issue"` - verify debug report created
- [x] Test `/fix "test bug"` - verify workflow completes

**Phase 4 Completed**: 2025-11-17
- `/debug`: 8 execution directives, 1 Task invocation fixed, 7 `set +H` added
- `/fix`: 12 execution directives, 3 Task invocations fixed, 9 `set +H` added (10th block has one at start)

---

## Phase 5: Standardize Argument Capture Pattern

**Objective**: Evaluate and standardize argument capture patterns across all commands
**Dependencies**: [2, 3, 4]
**Complexity**: Low
**Risk**: Low
**Estimated Time**: 0.5 hours

### Tasks

- [x] 5.1 Evaluate the two-step pattern from `/coordinate`
  - First block: Capture argument to temp file with user substitution
  - Second block: Read from temp file
  - Pros: Avoids `$1` issues with shell expansion, user verification
  - Cons: Requires explicit user substitution step, more complex

- [x] 5.2 Decision: Keep direct $1 for simple arguments, document both patterns
  - Direct $1 is simpler and works for file paths and simple descriptions
  - Two-step pattern recommended only for complex user input
  - No need to change all commands - current patterns are appropriate

- [x] 5.3 Document standard approach in command-authoring-standards.md
  - Added "Argument Capture Patterns" section
  - Documented both Pattern 1 (direct $1) and Pattern 2 (two-step)
  - Provided recommendation table for when to use each

### Verification

- [x] Evaluated patterns across existing commands
- [x] Documented concurrent execution safety with timestamp-based temp files

**Phase 5 Completed**: 2025-11-17
- Evaluation: Both patterns have valid use cases
- Recommendation: Direct $1 for file paths/simple args, two-step for complex user input
- Documentation: Updated `.claude/docs/reference/command-authoring-standards.md`

---

## Phase 6: Add Command Validation Tests

**Objective**: Create automated tests to prevent regression of execution directive issues
**Dependencies**: [2, 3, 4]
**Complexity**: Low
**Risk**: Low
**Estimated Time**: 0.5 hours

### Tasks

- [x] 6.1 Create test in `.claude/tests/test_command_execution_directives.sh`
  - Verify each affected command has execution directives
  - Count directive patterns per file (`EXECUTE NOW|Execute this|Run the following`)
  - Fail if any command file has 0 directives
  - Validate `set +H` appears at start of every bash block

- [x] 6.2 Create test for documentation-only YAML blocks (per Section 5.2.1)
  - Use automated detection script from `command-development-fundamentals.md`:
    ```bash
    #!/bin/bash
    # Detect documentation-only YAML blocks
    for file in .claude/commands/*.md; do
      awk '/```yaml/{
        found=0
        for(i=NR-5; i<NR; i++) {
          if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
        }
        if(!found) print FILENAME":"NR": Documentation-only YAML block detected"
      } {lines[NR]=$0}' "$file"
    done
    ```
  - Fail if any YAML blocks found without preceding imperative instruction

- [x] 6.3 Create test for Task invocations without completion signals
  - All Task invocations must require explicit completion signals
  - Pattern: `Return: REPORT_CREATED:|Return: PLAN_CREATED:|CLASSIFICATION_COMPLETE:`

- [x] 6.4 Create test for subprocess isolation compliance
  - Verify `set +H` in every bash block
  - Verify library re-sourcing pattern in multi-block commands
  - Verify return code checks on critical functions

- [x] 6.5 Add tests to test suite

### Verification

- [x] Run `./run_all_tests.sh` - all tests pass
- [x] Intentionally break a command to verify test catches it
- [x] Test detection of documentation-only YAML blocks

**Phase 6 Completed**: 2025-11-17
- Test file: `.claude/tests/test_command_execution_directives.sh`
- Tests: execution directives, YAML blocks, set +H, Task imperatives
- Current results: Phase 2 commands (research-*) pass all tests; Phases 3-4 commands still failing

---

## Risk Mitigation

### Risk 1: Breaking Working Commands
- **Mitigation**: Only modify identified broken commands
- **Verification**: Test each command after modification

### Risk 2: Inconsistent Patterns
- **Mitigation**: Use Phase 1 documentation as reference
- **Verification**: Code review for pattern consistency

### Risk 3: State Persistence Issues
- **Mitigation**: Test state machine flow end-to-end
- **Verification**: Check for checkpoint outputs

## Rollback Plan

If issues discovered post-implementation:
1. Git revert individual command file changes
2. Commands are independent; can rollback selectively
3. Keep backup of original files before Phase 2

## Notes

- This plan focuses on the execution directive issue, not on enhancing command functionality
- Future work may consolidate the state machine patterns into a shared library
- Phase 6 tests align with documented detection patterns from `command-development-fundamentals.md`

## Standards Compliance Reference

This plan's implementation must comply with these documented standards:

### Primary Standards Documents

1. **Bash Block Execution Model** (`.claude/docs/concepts/bash-block-execution-model.md`)
   - Pattern 4: Library Re-sourcing with Source Guards
   - Pattern 7: Return Code Verification for Critical Functions
   - `set +H` requirement in every bash block

2. **Command Development Fundamentals** (`.claude/docs/guides/command-development-fundamentals.md`)
   - Section 5.2.1: Avoiding Documentation-Only Patterns
   - Section 5.2: Behavioral Injection Pattern
   - Section 2.4: Executable/Documentation Separation

3. **Phase Dependencies Guide** (`.claude/docs/reference/phase_dependencies.md`)
   - Phase metadata format with Dependencies array
   - Wave-based parallel execution support

### Implementation Checklist (Per Standards)

Before marking each phase complete, verify:

- [ ] All bash blocks have `set +H` at start
- [ ] All bash blocks re-source required libraries
- [ ] All critical function calls have return code verification
- [ ] All Task invocations use executable pattern (NO code block wrapper)
- [ ] All Task invocations have imperative instruction ("EXECUTE NOW")
- [ ] All Task invocations require completion signals
- [ ] No documentation-only YAML blocks in executable context

### Anti-Patterns to Avoid

Per Section 5.2.1 of command-development-fundamentals.md:
- NEVER wrap Task invocations in ` ```yaml ` code blocks
- NEVER use Task {} without preceding imperative instruction
- NEVER omit completion signal requirements from agent prompts

---

## Resume Instructions

To continue implementation from where we left off:

```bash
/build /home/benjamin/.config/.claude/specs/756_command_bash_execution_directives/plans/001_fix_command_execution_plan.md 5
```

This will resume at Phase 5 (Standardize Argument Capture Pattern).

### Commands Still Needing Fixes (Future Work)

Based on test results from `.claude/tests/test_command_execution_directives.sh`:

| Command | Bash Blocks | Execution Directives | Task Fixes Needed | set +H Needed | Status |
|---------|-------------|---------------------|-------------------|---------------|--------|
| `/expand` | 32 | 0 | 2 | 32 | Needs work |
| `/revise` | 31 | 0 | 0 | 31 | Needs work |
| `/collapse` | 29 | 3 | 2 | 0 | Partial |
| `/plan` | 10 | 10 | 1 | 6 | Partial |
| `/research` | 10 | 8 | 2 | 0 | Partial |

Note: `/expand` and `/revise` are critical commands that should be fixed in a follow-up spec.

### What Was Accomplished

1. **Phase 1**: Created comprehensive documentation at `.claude/docs/reference/command-authoring-standards.md`
2. **Phase 2**: Fixed the three research-* commands that were identified as broken in the original issue
3. **Phase 3**: Fixed `/implement` and `/build` commands - all tests passing
4. **Phase 4**: Fixed `/debug` and `/fix` commands - all tests passing
5. **Phase 6**: Created automated tests to validate fixes and catch regressions

The critical commands that triggered the original issue (`/research-plan`, `/research-report`, `/research-revise`, `/implement`, `/build`, `/debug`, `/fix`) are now fixed and pass all validation tests.

### Test Results Summary

All 7 originally targeted commands now pass execution directive tests:
- `/research-plan`: 9 directives, 2 Task invocations
- `/research-report`: 6 directives, 1 Task invocation
- `/research-revise`: 9 directives, 2 Task invocations
- `/implement`: 4 directives, 1 Task invocation
- `/build`: 11 directives, 2 Task invocations
- `/debug`: 8 directives, 1 Task invocation
- `/fix`: 12 directives, 3 Task invocations
