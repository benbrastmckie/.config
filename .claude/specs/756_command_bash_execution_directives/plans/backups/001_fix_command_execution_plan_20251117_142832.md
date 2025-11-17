# Implementation Plan: Fix Command Bash Execution Failures

## Plan Metadata

- **Spec ID**: 756
- **Plan Number**: 001
- **Created**: 2025-11-17
- **Research Report**: `reports/001_root_cause_analysis.md`
- **Complexity**: Medium
- **Risk Level**: Medium (modifies 7+ production commands)
- **Estimated Duration**: 3-4 hours

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

- [ ] 1.1 Document the execution directive standard in `.claude/docs/reference/command-authoring-standards.md`
  - Define required directive phrases: "**EXECUTE NOW**:", "Execute this bash block:", "Run the following:"
  - Explain why directives are necessary (LLM interprets bare code blocks as documentation)
  - Provide examples from working commands

- [ ] 1.2 Document the Task tool invocation pattern
  - Explain why `Task {}` syntax doesn't work
  - Show correct pattern with actual tool call instruction
  - Provide template for agent delegation

- [ ] 1.3 Document state persistence requirements
  - Explain subprocess isolation issue
  - Show `append_workflow_state` / `load_workflow_state` pattern
  - Recommend consolidated bash blocks where possible

### Verification

- [ ] Run `/setup --validate` to check documentation standards
- [ ] Verify new documentation renders correctly

---

## Phase 2: Fix Critical Workflow Commands (research-*)

**Objective**: Add execution directives and fix Task pseudo-syntax in research-plan, research-report, research-revise
**Dependencies**: [1]
**Complexity**: Medium
**Risk**: Medium
**Estimated Time**: 1.5 hours

### 2.1 Fix `/research-plan` Command

- [ ] 2.1.1 Add execution directives before all 7 bash blocks
  - Part 1: Add "**EXECUTE NOW**: Capture and validate the feature description:"
  - Part 2: Add "**EXECUTE NOW**: Initialize the state machine:"
  - Part 3 (before Task): Add "**EXECUTE NOW**: Transition to research state and allocate topic directory:"
  - Part 3 (after Task): Add "**EXECUTE NOW**: Verify research artifacts:"
  - Part 4: Add "**EXECUTE NOW**: Transition to planning state:"
  - Part 4 (after Task): Add "**EXECUTE NOW**: Verify plan artifacts:"
  - Part 5: Add "**EXECUTE NOW**: Complete the workflow:"

- [ ] 2.1.2 Replace `Task {}` pseudo-syntax with proper pattern
  - Research agent delegation:
    ```markdown
    **INVOKE AGENT**: Use the Task tool with these parameters:
    - **subagent_type**: "general-purpose"
    - **description**: "Research: [topic]"
    - **prompt**: Read the prompt from the bash variables above

    Execute the research-specialist agent by invoking Task tool now.
    ```
  - Planning agent delegation: Similar pattern

- [ ] 2.1.3 Consolidate bash blocks where possible to reduce state persistence issues

### 2.2 Fix `/research-report` Command

- [ ] 2.2.1 Add execution directives before all 5 bash blocks
- [ ] 2.2.2 Replace `Task {}` pseudo-syntax (1 occurrence)
- [ ] 2.2.3 Verify state machine flow

### 2.3 Fix `/research-revise` Command

- [ ] 2.3.1 Add execution directives before all 7 bash blocks
- [ ] 2.3.2 Replace `Task {}` pseudo-syntax (2 occurrences)
- [ ] 2.3.3 Verify state machine flow

### Verification

- [ ] Test `/research-plan "test feature"` - verify checkpoints appear
- [ ] Test `/research-report "test topic"` - verify reports created
- [ ] Test `/research-revise "test revision"` - verify workflow completes
- [ ] Check for "State machine initialized" in all outputs

---

## Phase 3: Fix Implementation Commands

**Objective**: Add execution directives and fix comment-based pseudo-instructions in implement and build commands
**Dependencies**: [1]
**Complexity**: Medium
**Risk**: Medium
**Estimated Time**: 1 hour

### 3.1 Fix `/implement` Command

- [ ] 3.1.1 Add execution directives before all 3 bash blocks
- [ ] 3.1.2 Replace comment-based pseudo-instructions with proper patterns:
  - `# Invoke code-writer agent via Task tool` -> Proper Task invocation instruction
  - `# Invoke implementation-researcher agent via Task tool` -> Proper instruction
  - `# Invoke spec-updater agent via Task tool` -> Proper instruction
- [ ] 3.1.3 Consolidate Phase 0 and Phase 1 bash blocks if variable sharing needed

### 3.2 Fix `/build` Command

- [ ] 3.2.1 Add execution directives before all 9 bash blocks
- [ ] 3.2.2 Replace any comment-based pseudo-instructions
- [ ] 3.2.3 Ensure checkpoint outputs are visible

### Verification

- [ ] Test `/implement` with a simple plan file
- [ ] Test `/build` with a test plan
- [ ] Verify CHECKPOINT outputs appear

---

## Phase 4: Fix Debug/Fix Commands

**Objective**: Add execution directives and fix pseudo-instructions in debug and fix commands
**Dependencies**: [1]
**Complexity**: Medium
**Risk**: Low
**Estimated Time**: 0.75 hours

### 4.1 Fix `/debug` Command

- [ ] 4.1.1 Add execution directives before all 7 bash blocks
- [ ] 4.1.2 Replace any comment-based pseudo-instructions with proper patterns

### 4.2 Fix `/fix` Command

- [ ] 4.2.1 Add execution directives before all 10 bash blocks
- [ ] 4.2.2 Replace any comment-based pseudo-instructions with proper patterns

### Verification

- [ ] Test `/debug "test issue"` - verify debug report created
- [ ] Test `/fix "test bug"` - verify workflow completes

---

## Phase 5: Standardize Argument Capture Pattern

**Objective**: Evaluate and standardize argument capture patterns across all commands
**Dependencies**: [2, 3, 4]
**Complexity**: Low
**Risk**: Low
**Estimated Time**: 0.5 hours

### Tasks

- [ ] 5.1 Evaluate the two-step pattern from `/coordinate`
  - First block: Capture argument to temp file with user substitution
  - Second block: Read from temp file
  - Pros: Avoids `$1` issues with shell expansion
  - Cons: Requires explicit user substitution step

- [ ] 5.2 If two-step pattern preferred, update all fixed commands to use it
  - Add STEP 1/STEP 2 structure
  - Use timestamp-based temp files for concurrent safety

- [ ] 5.3 Alternative: Use direct `$ARGUMENTS` variable if available
  - Check if Claude Code provides arguments as environment variable
  - Document the standard approach

### Verification

- [ ] Test commands with complex arguments (quotes, special chars)
- [ ] Test concurrent command execution

---

## Phase 6: Add Command Validation Tests

**Objective**: Create automated tests to prevent regression of execution directive issues
**Dependencies**: [2, 3, 4]
**Complexity**: Low
**Risk**: Low
**Estimated Time**: 0.5 hours

### Tasks

- [ ] 6.1 Create test in `.claude/tests/test_command_execution_directives.sh`
  - Verify each affected command has execution directives
  - Count directive patterns per file
  - Fail if any command has 0 directives

- [ ] 6.2 Create test for Task pseudo-syntax
  - Grep for `Task {` pattern
  - Fail if any occurrences found in command files

- [ ] 6.3 Add tests to test suite

### Verification

- [ ] Run `./run_all_tests.sh` - all tests pass
- [ ] Intentionally break a command to verify test catches it

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
- Consider creating a command linter as part of Phase 6
