# Research Coordinator Agent Invocation Fix Implementation Plan

## Metadata

**Date**: 2025-12-09
**Feature**: Fix research-coordinator agent failure to invoke research-specialist agents due to pseudo-code pattern misinterpretation
**Status**: [COMPLETE]
**Estimated Hours**: 3-5 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Task Tool Invocation in Agent Behavior Research Report](/home/benjamin/.config/.claude/specs/037_research_coordinator_invocation_fix/reports/001-task-tool-agent-invocation.md)
- [Pseudo-Code Pattern Recognition and Interpretation Research Report](/home/benjamin/.config/.claude/specs/037_research_coordinator_invocation_fix/reports/002-pseudo-code-pattern-recognition.md)
- [Agent Error Handling and Fallback Mechanisms Research Report](/home/benjamin/.config/.claude/specs/037_research_coordinator_invocation_fix/reports/003-agent-error-handling-fallback.md)

## Problem Statement

The research-coordinator agent reads its behavioral file but interprets Task pseudo-code patterns as documentation rather than executable directives, resulting in empty reports directory and requiring manual fallback invocation. The agent has Task tool access but fails to recognize the invocation patterns in STEP 3 as executable instructions.

### Root Cause Analysis

Research findings identified three critical issues:

1. **Pseudo-Code Confusion** (Report 002): The research-coordinator.md behavioral file contains Task invocation patterns that look like examples rather than executable directives. While the patterns include "EXECUTE NOW" directives, they are embedded within documentation context that confuses the agent about whether to execute or merely read them.

2. **Missing Execution Context** (Report 001): The behavioral file mixes two audiences - agent execution instructions and command-author documentation examples. STEP 3 (lines 198-292) contains properly formatted Task invocations with imperative directives, but lacks clear markers distinguishing executable sections from documentation sections.

3. **Silent Failure Mode** (Report 003): When the agent fails to invoke research-specialist agents, there are no diagnostic logs or validation checkpoints to detect the failure. The workflow returns without creating reports, leaving an empty reports directory with no error messages.

### Impact Assessment

**Current State**:
- research-coordinator reads behavioral file successfully
- Agent recognizes STEP 3 contains Task patterns
- Agent interprets patterns as documentation to be understood, not executed
- No Task tool invocations occur
- Empty reports directory with no diagnostic output
- User must manually fall back to direct research-specialist invocation

**Severity**: HIGH - Breaks core parallel research orchestration functionality

## Success Criteria

- [ ] research-coordinator agent executes Task tool invocations in STEP 3 without confusion
- [ ] All research-specialist agents invoked for each topic in TOPICS array
- [ ] Reports directory populated with expected number of research reports
- [ ] Empty directory detection validates report creation before coordinator returns
- [ ] Diagnostic logging captures agent invocation status for debugging
- [ ] STEP 3.5 self-validation checkpoint ensures Task invocations occurred
- [ ] Integration tests verify end-to-end research coordination workflow

## Implementation Phases

### Phase 1: Add Execution Enforcement Markers to research-coordinator.md [COMPLETE]

**Objective**: Enhance STEP 3 with stronger execution enforcement language and self-validation checkpoints to eliminate interpretation ambiguity.

**Tasks**:

1. **Add Pre-Step Execution Directive**
   - Insert execution directive immediately before STEP 3 Task patterns
   - Use imperative language: "YOU MUST EXECUTE the following Task invocations"
   - Add warning: "DO NOT treat these as examples - they are executable directives"
   - Location: /home/benjamin/.config/.claude/agents/research-coordinator.md line 197 (before STEP 3)

2. **Strengthen Individual Task Directives**
   - Review each Task invocation pattern (lines 208-292)
   - Verify each has "EXECUTE NOW" directive preceding it
   - Add repetition for emphasis: "EXECUTE NOW - DO NOT SKIP"
   - Clarify variable interpolation: "Replace ${TOPICS[i]} with actual topic string"

3. **Enhance STEP 3.5 Self-Validation Checkpoint**
   - Strengthen verification language: "MANDATORY: Verify Task invocations before continuing"
   - Add fail-fast instruction: "If Task count != ${#TOPICS[@]}, STOP and re-execute STEP 3"
   - Add self-diagnostic questions requiring YES/NO answers
   - Location: Lines 298-318 (STEP 3.5)

4. **Add Visual Execution Markers**
   - Insert visual separator before STEP 3: `<!-- EXECUTION ZONE: Task Invocations Below -->`
   - Add inline markers for each Task: `<!-- EXECUTE THIS TASK -->`
   - Use bold/caps for emphasis: "**THIS IS NOT DOCUMENTATION - EXECUTE NOW**"

5. **Add Completion Verification Instruction**
   - After last Task pattern, add explicit checkpoint: "VERIFY: Did you invoke ${#TOPICS[@]} Task tools?"
   - Add consequence warning: "Failure to execute = empty reports directory = workflow failure"

**Expected Outcome**: Behavioral file contains unambiguous execution markers that eliminate documentation vs execution confusion.

**Verification**:
- Read updated research-coordinator.md
- Count imperative directives in STEP 3 (should be ≥1 per topic)
- Verify STEP 3.5 contains mandatory verification checkpoint
- Confirm visual execution markers present

---

### Phase 2: Implement Empty Directory Validation in STEP 4 [COMPLETE]

**Objective**: Add fail-fast validation checkpoint that detects empty reports directory and logs diagnostic errors before coordinator returns.

**Tasks**:

1. **Add Pre-Validation Report Count Check**
   - Before STEP 4 artifact validation, count expected reports
   - Location: /home/benjamin/.config/.claude/agents/research-coordinator.md STEP 4 (after line 320)
   - Add bash snippet:
     ```bash
     EXPECTED_REPORTS=${#REPORT_PATHS[@]}
     CREATED_REPORTS=$(ls "$REPORT_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)

     if [ "$CREATED_REPORTS" -eq 0 ]; then
       echo "CRITICAL ERROR: Reports directory is empty - no reports created" >&2
       echo "Expected: $EXPECTED_REPORTS reports" >&2
       echo "This indicates Task tool invocations did not execute in STEP 3" >&2
       exit 1
     fi
     ```

2. **Add Expected vs Actual Count Comparison**
   - Compare EXPECTED_REPORTS to CREATED_REPORTS
   - Log mismatch: "WARNING: Created $CREATED_REPORTS reports, expected $EXPECTED_REPORTS"
   - Add diagnostic hint: "Check STEP 3 Task invocation execution"

3. **Add Individual Report Path Validation** (keep existing logic)
   - Iterate through REPORT_PATHS array validating file existence
   - Log specific missing reports with absolute paths
   - Fail-fast if any reports missing (existing logic at lines 331-350)

4. **Add Size Validation Enhancement**
   - Increase minimum report size from 500 bytes to 1000 bytes
   - Too-small reports indicate incomplete research
   - Log warning for undersized reports with actual byte count

5. **Add Diagnostic Error Context**
   - On validation failure, output structured diagnostic information
   - Include: topic count, expected paths, created count, missing paths
   - Format for easy parsing by parent command error handling

**Expected Outcome**: STEP 4 reliably detects empty directory failures and provides diagnostic information for debugging.

**Verification**:
- Read updated STEP 4 validation logic
- Confirm early-exit check for empty directory (count = 0)
- Verify diagnostic error messages include actionable hints
- Test with intentionally empty directory (manual test scenario)

---

### Phase 3: Add Agent Invocation Logging and Diagnostics [COMPLETE]

**Objective**: Implement logging at Task invocation points to record which agents were invoked, with what parameters, and whether invocation succeeded.

**Tasks**:

1. **Add Invocation Logging in STEP 3**
   - After each "EXECUTE NOW" directive, add logging instruction for agent
   - Location: Between imperative directive and Task block
   - Add instruction: "Log this invocation: echo 'Invoking research-specialist for topic: ${TOPICS[i]}'"
   - Record timestamp, topic index, topic name, report path

2. **Add Post-Invocation Checkpoint**
   - After each Task block completes, add verification instruction
   - Instruction: "Verify Task tool returned response (check for REPORT_CREATED signal)"
   - Log success/failure per invocation
   - Format: "Task invocation [i]: SUCCESS/FAILED - Signal: REPORT_CREATED: path" or "No signal received"

3. **Add STEP 3 Summary Logging**
   - At end of STEP 3 (before STEP 3.5), add summary instruction
   - Count successful Task invocations vs expected
   - Log summary: "STEP 3 Complete: Invoked X/Y research-specialist agents"
   - Flag discrepancy if X != Y

4. **Integrate with Error Handling Protocol**
   - Add error context output for failed invocations
   - Format per error return protocol (lines 550-596)
   - Include: error_type (agent_error), message, details (topic, index, report_path)
   - Use structured JSON format for parent command parsing

5. **Add Invocation Trace for Debugging**
   - Add instruction to save invocation trace to temporary file
   - Location: $REPORT_DIR/.invocation-trace.log
   - Include: timestamp, topic, path, Task parameters, response signal
   - Auto-delete on successful completion, preserve on failure

**Expected Outcome**: Comprehensive logging captures agent invocation status, enabling post-mortem debugging of coordination failures.

**Verification**:
- Read updated STEP 3 with logging instructions
- Confirm logging occurs before and after each Task block
- Verify structured error format matches error return protocol
- Check invocation trace file specification

---

### Phase 4: Add Behavioral File Documentation Clarity [COMPLETE]

**Objective**: Restructure research-coordinator.md to clearly separate agent execution instructions from command-author reference documentation.

**Tasks**:

1. **Add Audience Markers to Frontmatter**
   - Add new frontmatter field: `target-audience: agent-execution`
   - Add comment in frontmatter: `# This file contains EXECUTABLE DIRECTIVES for the research-coordinator agent`
   - Location: /home/benjamin/.config/.claude/agents/research-coordinator.md lines 1-8

2. **Restructure File Sections with Clear Headers**
   - Rename section headers to emphasize execution context
   - STEP 1 → "STEP 1 (EXECUTE): Receive and Verify Research Topics"
   - STEP 2 → "STEP 2 (EXECUTE): Pre-Calculate Report Paths"
   - STEP 3 → "STEP 3 (EXECUTE MANDATORY): Invoke Parallel Research Workers"
   - Add "(EXECUTE)" suffix to all workflow step headers

3. **Move Example Invocations to Separate Documentation Section**
   - Create new section at end of file: "## Command-Author Reference (NOT FOR AGENT EXECUTION)"
   - Move input format examples (lines 40-77) to reference section
   - Add clear marker: "The following examples show how COMMANDS invoke this agent - they are NOT executable by this agent"

4. **Add Execution vs Documentation Markers**
   - Before each executable bash snippet, add: `<!-- AGENT: EXECUTE THIS BLOCK -->`
   - Before documentation examples, add: `<!-- DOCUMENTATION ONLY - DO NOT EXECUTE -->`
   - Use consistent marker vocabulary throughout file

5. **Add File Structure Overview**
   - Insert after frontmatter, before "Role" section
   - Add section: "## File Structure (Read This First)"
   - Explain: "This file contains EXECUTABLE WORKFLOW STEPS. Each STEP must be executed in order. Task invocations are MANDATORY, not optional."
   - Clarify pseudo-code syntax: "Task { ... } patterns are EXECUTABLE when preceded by EXECUTE NOW directive"

**Expected Outcome**: Behavioral file structure clearly distinguishes executable instructions from reference documentation, eliminating audience confusion.

**Verification**:
- Read updated research-coordinator.md frontmatter for audience field
- Verify all STEP headers include "(EXECUTE)" suffix
- Check reference section exists with clear "NOT FOR AGENT EXECUTION" warning
- Confirm execution markers present throughout

---

### Phase 5: Integration Testing and Validation [COMPLETE]

**Objective**: Validate that research-coordinator agent successfully invokes research-specialist agents end-to-end with all improvements integrated.

**Tasks**:

1. **Create Integration Test Script**
   - Location: /home/benjamin/.config/.claude/tests/integration/test-research-coordinator-invocation.sh
   - Test workflow: Invoke research-coordinator with 3 topics, verify 3 reports created
   - Setup: Create temporary topic directory with reports subdirectory
   - Invoke research-coordinator agent via Task tool with test topics
   - Validate: Count reports in directory matches expected count
   - Assert: All report files exist and are ≥1000 bytes
   - Cleanup: Remove temporary test directory

2. **Add Empty Directory Failure Test**
   - Test scenario: Research-coordinator with intentionally failing research-specialist
   - Mock research-specialist to return TASK_ERROR instead of REPORT_CREATED
   - Validate: Coordinator detects empty directory and exits with error
   - Assert: Diagnostic error message includes "Reports directory is empty"
   - Verify: Error context includes expected vs actual count

3. **Add Invocation Logging Test**
   - Test scenario: Research-coordinator invocation with logging enabled
   - Validate: Invocation trace file created in reports directory
   - Assert: Trace file contains entry for each topic
   - Verify: Each trace entry includes timestamp, topic, path, response signal
   - Check: Trace file deleted on successful completion

4. **Add STEP 3.5 Self-Validation Test**
   - Test scenario: Simulate agent skipping Task invocations in STEP 3
   - Expected: STEP 3.5 checkpoint detects missing invocations
   - Assert: Agent stops execution and returns to STEP 3
   - Verify: Self-diagnostic questions answered NO triggers re-execution

5. **Add Regression Test for Existing Functionality**
   - Test all existing research-coordinator use cases:
     - Mode 1: Automated decomposition (topics not provided)
     - Mode 2: Manual pre-decomposition (topics + report_paths provided)
   - Validate: Both modes work correctly with new improvements
   - Assert: No regressions in path calculation or metadata extraction
   - Verify: Output format unchanged (backward compatibility)

6. **Document Test Coverage**
   - Add test documentation: /home/benjamin/.config/.claude/tests/integration/test-research-coordinator-invocation.md
   - List all test scenarios and expected outcomes
   - Include manual test instructions for validation failures
   - Document edge cases: empty topics array, invalid report directory

**Expected Outcome**: Comprehensive integration tests validate research-coordinator invocation fixes work end-to-end with all edge cases covered.

**Verification**:
- Run test script: `bash /home/benjamin/.config/.claude/tests/integration/test-research-coordinator-invocation.sh`
- All tests pass (5 scenarios)
- No false positives or false negatives
- Test coverage includes normal path and failure modes

---

### Phase 6: Update Dependent Commands and Documentation [COMPLETE]

**Objective**: Update all commands that invoke research-coordinator to benefit from new diagnostic capabilities and ensure documentation reflects changes.

**Tasks**:

1. **Update /lean-plan Command**
   - Location: /home/benjamin/.config/.claude/commands/lean-plan.md
   - Add error handling for research-coordinator TASK_ERROR signals
   - Parse error context from coordinator using parse_subagent_error()
   - Log coordinator errors to errors.jsonl with workflow context
   - Add fallback instruction: On coordinator failure, fall back to sequential research-specialist invocation

2. **Update /create-plan Command** (if using research-coordinator)
   - Location: /home/benjamin/.config/.claude/commands/create-plan.md
   - Check if command uses research-coordinator (complexity ≥ 3)
   - If yes, apply same error handling pattern as /lean-plan
   - Add diagnostic logging for coordinator invocation status

3. **Update /research Command** (if exists)
   - Location: /home/benjamin/.config/.claude/commands/research.md (if exists)
   - Apply error handling and diagnostic logging patterns
   - Ensure command benefits from empty directory validation

4. **Update Hierarchical Agent Architecture Documentation**
   - Location: /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md
   - Find Example 7 (research-coordinator pattern)
   - Add section: "Troubleshooting Invocation Failures"
   - Document diagnostic error messages and their meanings
   - Add resolution steps for empty directory failures
   - Include invocation trace file interpretation guide

5. **Update Research Coordinator Migration Guide**
   - Location: /home/benjamin/.config/.claude/docs/guides/development/research-coordinator-migration-guide.md
   - Add section: "Validation and Diagnostics"
   - Document empty directory detection feature
   - Explain invocation logging and trace file usage
   - Add troubleshooting checklist for integration issues

6. **Update Command Authoring Standards**
   - Location: /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md
   - Add warning about pseudo-code pattern interpretation by agents
   - Clarify difference between command-author Task patterns vs agent-internal Task patterns
   - Add best practice: "Agent behavioral files should use stronger execution enforcement than command files"
   - Document audience marker pattern for agent behavioral files

**Expected Outcome**: All dependent commands benefit from improved diagnostics, and documentation guides users through troubleshooting research-coordinator invocation issues.

**Verification**:
- Grep for research-coordinator usage in commands directory
- Verify all dependent commands updated with error handling
- Read updated documentation sections for completeness
- Check cross-references between docs are accurate

---

## Risk Assessment

### Technical Risks

1. **Risk**: Agent continues to misinterpret Task patterns despite stronger directives
   - **Mitigation**: Add multiple redundant execution enforcement markers (Phase 1)
   - **Fallback**: Implement automatic fallback to sequential research-specialist invocation (Phase 6)
   - **Likelihood**: LOW (stronger directives + validation checkpoints should resolve)

2. **Risk**: Diagnostic logging impacts performance or creates large log files
   - **Mitigation**: Use lightweight logging (single line per invocation)
   - **Auto-cleanup**: Delete trace file on successful completion
   - **Likelihood**: LOW (logging overhead minimal for 2-5 topics)

3. **Risk**: Empty directory validation causes false positives in edge cases
   - **Mitigation**: Use count = 0 check (strict empty directory detection)
   - **Edge case handling**: Allow partial success mode (≥50% threshold) for agent failures
   - **Likelihood**: LOW (validation logic is conservative)

### Integration Risks

1. **Risk**: Changes break existing research-coordinator workflows
   - **Mitigation**: Comprehensive regression testing (Phase 5)
   - **Backward compatibility**: Output format unchanged
   - **Likelihood**: LOW (changes are additive, not breaking)

2. **Risk**: Dependent commands require updates not identified in Phase 6
   - **Mitigation**: Grep entire codebase for research-coordinator references
   - **Discovery**: Manual code review + integration test runs
   - **Likelihood**: MEDIUM (may be additional dependent commands)

## Dependencies

### Internal Dependencies
- Error handling library (error-handling.sh) for structured error logging
- Validation utils library (validation-utils.sh) for path validation functions
- research-specialist agent (dependent-agents field in frontmatter)

### External Dependencies
- Claude Code Task tool (agent invocation mechanism)
- Bash utilities (ls, wc, grep) for file validation
- Git for versioning behavioral file changes

### Workflow Dependencies
- Must complete Phase 1 before Phase 2 (validation depends on execution markers)
- Must complete Phases 1-4 before Phase 5 (integration testing requires all fixes)
- Phase 6 can run in parallel with Phase 5 after Phases 1-4 complete

## Testing Strategy

### Unit Testing
- Phase 2: Test empty directory validation logic in isolation
- Phase 3: Test logging instruction format and output
- Phase 4: Test behavioral file structure parsing

### Integration Testing
- Phase 5: End-to-end research-coordinator invocation with 3 topics
- Phase 5: Empty directory failure detection test
- Phase 5: Invocation logging and trace file creation test
- Phase 5: Regression tests for Mode 1 and Mode 2 invocation

### Manual Testing
- Invoke research-coordinator with real research topics via /lean-plan
- Verify reports directory populated correctly
- Inspect invocation trace file for debugging information
- Validate diagnostic error messages on intentional failures

### Validation Criteria
- All automated tests pass (5 scenarios in Phase 5)
- Manual testing confirms reports created for real workflows
- No regressions in existing research-coordinator functionality
- Diagnostic logging provides actionable debugging information

## Rollback Plan

### Rollback Triggers
- Integration tests fail with new behavioral file changes
- Agent continues to fail Task invocations despite improvements
- Dependent commands break due to output format changes
- Performance degradation from diagnostic logging

### Rollback Procedure
1. Revert research-coordinator.md to previous version (git checkout)
2. Remove empty directory validation from STEP 4
3. Remove invocation logging instructions from STEP 3
4. Revert dependent command changes (Phase 6)
5. Validate rollback with integration tests
6. Document rollback reason and failed approach

### Rollback Validation
- Integration tests pass with reverted behavioral file
- Research-coordinator invocation works via manual fallback
- No diagnostic error messages from empty directory validation
- Dependent commands function normally

## Success Metrics

### Functional Metrics
- research-coordinator successfully invokes research-specialist agents (100% success rate)
- Reports directory populated with expected number of reports (0% empty directory failures)
- STEP 3.5 self-validation checkpoint prevents silent failures (100% detection rate)
- Empty directory validation catches coordination failures before return (100% detection)

### Quality Metrics
- Integration test pass rate: 100% (5/5 scenarios)
- Regression test pass rate: 100% (both Mode 1 and Mode 2)
- Diagnostic error message clarity: User can identify failure cause from message alone
- Invocation trace file completeness: All topics logged with timestamps and signals

### Performance Metrics
- No degradation in parallel research execution time (still 40-60% faster than sequential)
- Logging overhead <100ms per invocation
- Trace file size <10KB for typical 3-5 topic workflow
- Validation checkpoint adds <500ms to total workflow time

## Notes

### Implementation Sequence
1. Start with Phase 1 (execution markers) - highest impact, lowest risk
2. Proceed to Phase 2 (empty directory validation) - fail-fast detection
3. Add Phase 3 (invocation logging) - diagnostic capabilities
4. Apply Phase 4 (documentation clarity) - long-term maintainability
5. Execute Phase 5 (integration testing) - validation and confidence
6. Complete Phase 6 (dependent updates) - ecosystem integration

### Future Enhancements
- Consider generalizing execution enforcement pattern to other coordinator agents
- Explore automatic fallback mode (sequential invocation) on parallel failure
- Add performance profiling for invocation overhead measurement
- Create visual dashboard for invocation trace analysis

### Related Issues
- Task tool invocation patterns in agent behavioral files (general pattern)
- Agent vs command audience confusion in behavioral file structure
- Silent failure modes in coordinator agents (applies to implementer-coordinator too)
- Diagnostic logging standardization across all agents
