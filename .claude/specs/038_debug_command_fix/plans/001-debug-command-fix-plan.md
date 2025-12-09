# Implementation Plan: Fix /debug Command research-coordinator Agent Failures

## Metadata

- **Date**: 2025-12-09
- **Feature**: Fix research-coordinator agent Task invocation failures and enhance orchestrator validation patterns
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 12-16 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Research Report: Research-Coordinator Agent Execution Failure](../reports/001-research-coordinator-execution-failure.md)
  - [Research Report: Code Standards and Infrastructure Compliance](../reports/002-code-standards-compliance.md)
  - [Agent Enhancement and Error Handling Fix Strategy](../reports/003-agent-enhancement-fix-strategy.md)
- **Complexity Score**: 142 (Base: 7 [enhance] + Tasks/2: 20/2=10 + Files*3: 5*3=15 + Integrations*5: 22*5=110)
- **Structure Level**: Tier 2 (Phase Directory) - Medium complexity with 50-200 score range

## Overview

### Problem Statement

The /debug command fails when invoking research-coordinator agent due to pseudo-code Task invocation patterns in the agent's behavioral file. The agent interprets `Task { }` syntax as documentation rather than executable directives, resulting in zero Task tool invocations and empty reports directories.

**Evidence from Debug Output Analysis**:
- research-coordinator completed with 7 tool uses but no Task invocations
- Reports directory remained empty after coordinator execution
- "Error retrieving agent output" when orchestrator attempted to resume agent
- Orchestrator required fallback to manual research-specialist invocations (4 parallel calls)
- 47 seconds wasted execution time with no productive output

### Root Causes Identified

1. **Pseudo-Code Task Invocation Pattern** (Primary Issue)
   - research-coordinator.md uses `Task { }` syntax wrapped in code blocks
   - Bash variable interpolation syntax (`${VARIABLE}`) in agent behavioral file
   - Agent interprets patterns as documentation examples, not executable instructions
   - Violates Task Tool Invocation Standards from command-authoring.md

2. **Missing Hard Barrier Validation** (Secondary Issue)
   - Commands don't validate coordinator output signals before proceeding
   - No early detection of coordinator failures
   - Empty directory detected only after coordinator completes
   - No structured error logging for debugging

3. **Poor Agent Output Retrieval Error Handling** (Tertiary Issue)
   - "Error retrieving agent output" provides no context
   - No agent ID, error reason, or recovery strategy
   - No structured error logging for post-mortem analysis

### Solution Approach

This plan implements a three-phase fix strategy:
1. Update research-coordinator.md Task invocation patterns to use standards-compliant syntax
2. Add hard barrier output validation to orchestrator commands
3. Enhance error handling and logging for agent output retrieval failures

The fixes will be validated against existing standards and tested across multiple coordinator invocation scenarios.

## Implementation Phases

### Phase 1: Fix research-coordinator Task Invocation Patterns [COMPLETE]

**Objective**: Update research-coordinator.md STEP 3 to use standards-compliant Task invocation patterns that cannot be misinterpreted as documentation

**Dependencies**: None

**Estimated Hours**: 3-4 hours

**Success Criteria**:
- [x] All Task invocations use imperative directive pattern ("**EXECUTE NOW**: USE the Task tool...")
- [x] No code block wrappers around Task invocations
- [x] Bash variable syntax replaced with concrete examples and placeholders
- [x] Each topic invocation has explicit checkpoint verification
- [x] STEP 3.5 self-validation enhanced with mandatory checkpoints
- [x] Invocation trace logging implemented

**Tasks**:
- [x] **Task 1.1**: Read research-coordinator.md STEP 3 (lines 219-369) to understand current pattern
- [x] **Task 1.2**: Identify all Task invocation blocks requiring updates (currently lines 239-346)
- [x] **Task 1.3**: Replace pseudo-code Task patterns with standards-compliant syntax
  - Remove code block wrappers (``` fences)
  - Add imperative directives before each Task block
  - Inline logging output (no separate code blocks)
  - Replace ${VARIABLE} with descriptive placeholders
- [x] **Task 1.4**: Enhance STEP 3.5 self-validation checkpoint
  - Add mandatory verification questions
  - Add fail-fast instructions for mismatch
  - Add explicit Task invocation count verification
- [x] **Task 1.5**: Implement invocation trace file logging
  - Add bash implementation for trace file creation
  - Log each Task invocation with timestamp and topic
  - Preserve trace on failure for debugging
- [x] **Task 1.6**: Update documentation comments to clarify execution requirements
- [x] **Task 1.7**: Run validation: `bash .claude/scripts/lint-task-invocation-pattern.sh .claude/agents/research-coordinator.md`
- [x] **Task 1.8**: Commit changes with descriptive commit message

**Implementation Notes**:
- Follow standards-compliant pattern from command-authoring.md lines 99-294
- Reference successful implementer-coordinator.md pattern (lines 258-297) as guide
- Ensure each topic invocation (0 through 4) has explicit Task block
- Add per-topic checkpoints: "Did you just use the Task tool for topic N?"

**Validation**:
```bash
# Verify Task invocation patterns comply with standards
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/agents/research-coordinator.md

# Expected: No ERROR-level violations
# Expected: All Task blocks have imperative directives
```

---

### Phase 2: Add Hard Barrier Coordinator Output Validation [COMPLETE]

**Objective**: Implement coordinator output signal validation in orchestrator commands to detect failures before hard barrier file checks

**Dependencies**: None (can run in parallel with Phase 1)

**Estimated Hours**: 4-5 hours

**Success Criteria**:
- [x] create-plan.md has new validation block after coordinator invocation
- [x] lean-plan.md has coordinator output validation (if using research-coordinator)
- [x] Validation checks for RESEARCH_COMPLETE signal presence
- [x] Validation extracts and verifies report count
- [x] Structured error logging integrated for coordinator failures
- [x] Actionable diagnostics point to research-coordinator.md STEP 3
- [x] Early-exit prevents wasted hard barrier validation time

**Tasks**:
- [x] **Task 2.1**: Read create-plan.md Block 1e-exec and 1f to understand current flow
- [x] **Task 2.2**: Insert new Block 1e-validate between 1e-exec and 1f
  - Add state restoration and library sourcing
  - Implement RESEARCH_COMPLETE signal detection
  - Extract report count from signal
  - Add error logging for missing/invalid signals
  - Add actionable diagnostics for coordinator failures
- [x] **Task 2.3**: Update create-plan.md Block 1f hard barrier validation
  - Remove duplicate coordinator failure logic
  - Focus on file existence/size validation only
  - Reference 1e-validate for coordinator-specific checks
- [x] **Task 2.4**: Apply similar validation to lean-plan.md (if applicable)
- [x] **Task 2.5**: Test validation catches coordinator failures early
- [x] **Task 2.6**: Verify error logging creates errors.jsonl entries
- [x] **Task 2.7**: Commit changes with descriptive commit message

**Implementation Notes**:
- Follow hard barrier pattern from lean-implement.md lines 891-939
- Use parse_subagent_error for explicit error signals
- Use log_command_error for centralized error logging
- Provide recovery hints in error messages

**Validation**:
```bash
# Test coordinator output validation
# Method: Temporarily break research-coordinator RESEARCH_COMPLETE signal
# Expected: Block 1e-validate catches missing signal and exits with error
# Expected: errors.jsonl contains structured error entry
```

---

### Phase 3: Enhance Agent Output Retrieval Error Handling [COMPLETE]

**Objective**: Improve error handling for agent output retrieval failures with structured logging and context

**Dependencies**: Phase 2 (uses similar error logging patterns)

**Estimated Hours**: 2-3 hours

**Success Criteria**:
- [x] Commands capture and detect agent output retrieval errors
- [x] Errors logged with agent ID, agent name, and workflow context
- [x] Error messages are actionable with recovery strategies
- [x] Fallback strategies documented and implemented
- [x] errors.jsonl entries enable /errors query and /repair analysis

**Tasks**:
- [x] **Task 3.1**: Identify all commands invoking research-coordinator
  - create-plan.md
  - lean-plan.md
  - research.md (if direct invocation exists)
- [x] **Task 3.2**: Add agent output retrieval error detection pattern
  - Check for "error retrieving" or "failed to retrieve" patterns
  - Extract agent ID from error messages
  - Log structured error with full context
- [x] **Task 3.3**: Implement graceful recovery strategies
  - Fall back to direct research-specialist invocations
  - Log coordinator failure for post-mortem
  - Continue workflow with fallback results
- [x] **Task 3.4**: Update error-handling.sh if new error patterns needed
- [x] **Task 3.5**: Test error handling with simulated retrieval failures
- [x] **Task 3.6**: Verify errors queryable via /errors command
- [x] **Task 3.7**: Commit changes with descriptive commit message

**Implementation Notes**:
- Use standardized error types: `agent_error` for coordinator failures
- Include agent metadata in error details (JSON format)
- Provide recovery instructions in error messages
- Log before attempting fallback strategy

**Validation**:
```bash
# Query errors after test failures
/errors --command /create-plan --type agent_error --limit 5

# Expected: Errors show agent ID, context, and recovery strategy
# Expected: Errors have sufficient detail for debugging
```

---

### Phase 4: Test Fixed research-coordinator Across Workflows [NOT STARTED]

**Objective**: Validate research-coordinator fixes work across all invocation scenarios

**Dependencies**: Phase 1 (coordinator fixes), Phase 2 (validation), Phase 3 (error handling)

**Estimated Hours**: 2-3 hours

**Success Criteria**:
- [ ] Test Case 1 (single topic) passes: coordinator invokes 1 Task
- [ ] Test Case 2 (multi-topic) passes: coordinator invokes 3-4 Tasks
- [ ] Test Case 3 (pre-decomposed) passes: coordinator uses provided paths
- [ ] No empty reports directories
- [ ] No "Error retrieving agent output" messages
- [ ] RESEARCH_COMPLETE signals include correct report counts
- [ ] All coordinator invocations create expected research reports

**Tasks**:
- [ ] **Task 4.1**: Run Test Case 1 - Single Topic Research
  - Command: `/create-plan "OAuth2 authentication best practices" --complexity 1`
  - Verify: 1 research report created
  - Verify: RESEARCH_COMPLETE: 1 signal returned
  - Verify: No coordinator failures or fallbacks
- [ ] **Task 4.2**: Run Test Case 2 - Multi-Topic Research
  - Command: `/create-plan "Mathlib theorems, proof automation, project structure for Lean 4" --complexity 3`
  - Verify: 3-4 research reports created
  - Verify: RESEARCH_COMPLETE: N signal returned (N = 3 or 4)
  - Verify: No empty reports directory errors
- [ ] **Task 4.3**: Run Test Case 3 - Pre-Decomposed Topics (if mode supported)
  - Test with pre-calculated topics and report paths
  - Verify: Coordinator uses exact paths provided
  - Verify: Reports created at specified locations
- [ ] **Task 4.4**: Verify invocation trace files created
  - Check reports directories for `.invocation-trace.log` files
  - Verify: Trace logs show all Task invocations with timestamps
- [ ] **Task 4.5**: Test coordinator failure scenario
  - Temporarily break coordinator STEP 3
  - Verify: Block 1e-validate catches failure early
  - Verify: Error logged to errors.jsonl
  - Restore coordinator after test
- [ ] **Task 4.6**: Document test results and any issues found

**Test Case Details**:

**Test Case 1: Single-Topic Research (Minimal)**
```yaml
Input:
  research_request: "OAuth2 authentication best practices"
  research_complexity: 1

Expected:
  - Reports directory: 1 file (001-oauth2-authentication.md)
  - File size: > 1000 bytes
  - Signal: RESEARCH_COMPLETE: 1
  - No coordinator failures
```

**Test Case 2: Multi-Topic Research (Typical)**
```yaml
Input:
  research_request: "Mathlib theorems, proof automation, project structure"
  research_complexity: 3

Expected:
  - Reports directory: 3-4 files
  - All files > 1000 bytes
  - Signal: RESEARCH_COMPLETE: N (N = 3 or 4)
  - No empty directory errors
  - No agent output retrieval errors
```

**Test Case 3: Coordinator Failure Detection**
```yaml
Input:
  Temporarily remove RESEARCH_COMPLETE signal from research-coordinator.md
  Run /create-plan with any complexity

Expected:
  - Block 1e-validate detects missing signal
  - Error logged: "research-coordinator failed - no RESEARCH_COMPLETE signal"
  - Workflow exits with actionable diagnostic
  - errors.jsonl contains entry with context
```

**Validation**:
```bash
# After all test cases
/errors --command /create-plan --since 1h --summary

# Expected: No agent_error entries for research-coordinator
# Expected: All test runs completed successfully
```

---

### Phase 5: Apply Patterns to Other Coordinator Agents [COMPLETE]

**Objective**: Replicate Task invocation fixes and validation patterns to other coordinator agents for consistency

**Dependencies**: Phase 1-4 (validated patterns)

**Estimated Hours**: 2-3 hours

**Success Criteria**:
- [x] implementer-coordinator.md reviewed for similar issues
- [x] Any pseudo-code Task patterns converted to standards-compliant syntax
- [x] Coordinator output validation patterns documented
- [x] All coordinators use consistent Task invocation approach
- [x] Pre-commit hooks enforce Task invocation standards

**Tasks**:
- [x] **Task 5.1**: Audit all coordinator agents for Task invocation patterns
  - implementer-coordinator.md
  - lean-coordinator.md (if exists)
  - Any other agents with Task invocations
- [x] **Task 5.2**: Identify pseudo-code patterns or standards violations
- [x] **Task 5.3**: Apply research-coordinator fixes to similar patterns
- [x] **Task 5.4**: Verify coordinator output validation consistent across commands
- [x] **Task 5.5**: Update command-authoring.md with coordinator-specific examples
  - Add research-coordinator example
  - Document agent behavioral file Task patterns
  - Reference hierarchical-agents-examples.md
- [x] **Task 5.6**: Run linter on all updated agent files
- [x] **Task 5.7**: Commit documentation and agent updates

**Implementation Notes**:
- Follow same standards-compliant pattern used for research-coordinator
- Document patterns in command-authoring.md for future reference
- Ensure consistency across all coordinator agents

**Validation**:
```bash
# Validate all agent behavioral files
find .claude/agents -name "*coordinator*.md" -exec \
  bash .claude/scripts/lint-task-invocation-pattern.sh {} \;

# Expected: No ERROR-level violations across all coordinators
```

---

### Phase 6: Documentation and Preventive Measures [COMPLETE]

**Objective**: Document fixes, update standards, and create preventive measures to avoid regression

**Dependencies**: Phase 1-5 (all fixes implemented and validated)

**Estimated Hours**: 1-2 hours

**Success Criteria**:
- [x] Troubleshooting guide documents coordinator failure patterns
- [x] Standards documentation includes coordinator-specific Task patterns
- [x] Linter enforcement prevents future pseudo-code Task patterns
- [x] Pre-commit hook integration validated
- [x] All changes documented in relevant guides

**Tasks**:
- [x] **Task 6.1**: Create troubleshooting guide for coordinator failures
  - Document symptoms: empty reports directory, "Error retrieving agent output"
  - Document root causes: pseudo-code Task patterns, missing validation
  - Document fixes: standards-compliant patterns, hard barrier validation
  - Location: `.claude/docs/troubleshooting/coordinator-agent-failures.md`
- [x] **Task 6.2**: Update command-authoring.md with coordinator examples
  - Add research-coordinator Task invocation pattern
  - Cross-reference hard-barrier-subagent-delegation.md
  - Document agent behavioral file requirements
- [x] **Task 6.3**: Enhance lint-task-invocation-pattern.sh (if needed)
  - Add detection for code block wrappers around Task invocations
  - Add detection for Bash variable syntax in Task prompts
  - Add detection for instructional text without Task invocation
- [x] **Task 6.4**: Verify pre-commit hook runs linter on agent files
- [x] **Task 6.5**: Update hierarchical-agents-examples.md Example 7
  - Document research-coordinator fixes
  - Add "Common Pitfalls" section
  - Reference troubleshooting guide
- [x] **Task 6.6**: Create summary of changes for project changelog
- [x] **Task 6.7**: Commit all documentation updates

**Documentation Files to Update**:
- `.claude/docs/troubleshooting/coordinator-agent-failures.md` (new)
- `.claude/docs/reference/standards/command-authoring.md` (Task invocation examples)
- `.claude/docs/concepts/hierarchical-agents-examples.md` (Example 7 updates)
- `.claude/docs/guides/commands/create-plan-guide.md` (if exists)
- `.claude/docs/guides/commands/debug-guide.md` (if exists)

**Validation**:
```bash
# Verify all internal links valid
bash .claude/scripts/validators/validate-links-quick.sh

# Verify documentation follows standards
bash .claude/scripts/validators/validate-readmes.sh .claude/docs/

# Expected: No broken links, all READMEs compliant
```

---

## Testing Strategy

### Automated Testing

**Non-Interactive Test Automation**:
All test phases use non-interactive validation methods compliant with non-interactive testing standards:

1. **Phase 1 Tests**: Linter validation (exit code verification)
2. **Phase 2 Tests**: Signal detection verification (grep pattern matching)
3. **Phase 3 Tests**: Error log validation (JSON parsing)
4. **Phase 4 Tests**: File existence and content validation (programmatic checks)

**Test Automation Metadata**:
```yaml
automation_type: automated
validation_method: programmatic
skip_allowed: false
artifact_outputs:
  - errors.jsonl (structured error logs)
  - .invocation-trace.log (coordinator execution traces)
  - test-results.json (test case outcomes)
```

### Integration Testing

**Test Scenarios**:
1. Single-topic research (complexity 1)
2. Multi-topic research (complexity 3)
3. Coordinator failure detection
4. Agent output retrieval error handling
5. Fallback strategy execution

**Test Artifacts**:
- Test reports in `.claude/specs/038_debug_command_fix/test-results/`
- Error logs in `.claude/data/errors.jsonl`
- Invocation traces in topic reports directories

### Validation Commands

```bash
# Validate all fixes
bash .claude/scripts/validate-all-standards.sh --sourcing
bash .claude/scripts/validate-all-standards.sh --links
bash .claude/scripts/lint-task-invocation-pattern.sh .claude/agents/research-coordinator.md

# Query errors after testing
/errors --command /create-plan --since 1h --type agent_error
/errors --command /create-plan --since 1h --summary

# Verify no regressions
/create-plan "test feature for validation" --complexity 3
```

## Dependencies and Integration Points

### Standards Compliance

**Code Standards**:
- Three-tier library sourcing pattern (Tier 1: error-handling.sh required)
- Task tool invocation patterns (imperative directives)
- Error logging integration (log_command_error)
- Hard barrier subagent delegation pattern

**Testing Standards**:
- Non-interactive testing (automated validation methods)
- Programmatic validation (exit codes, file checks, JSON parsing)
- No manual verification steps

**Documentation Standards**:
- README.md requirements (active development directories)
- Internal link validation
- Cross-reference maintenance

### Integration Points

**Commands Updated**:
- `/create-plan` - Add coordinator output validation
- `/lean-plan` - Add coordinator output validation (if applicable)
- `/debug` - Root cause addressed (research-coordinator fixes)

**Agents Updated**:
- `research-coordinator.md` - Fix Task invocation patterns
- Other `*-coordinator.md` agents - Apply consistent patterns

**Libraries Used**:
- `error-handling.sh` - Centralized error logging
- `unified-location-detection.sh` - Lazy directory creation
- `validation-utils.sh` - Artifact validation functions

### External Dependencies

**Tools Required**:
- bash (library sourcing, validation scripts)
- jq (JSON error log formatting)
- grep (signal detection, pattern matching)

**Validation Scripts**:
- `lint-task-invocation-pattern.sh`
- `validate-links-quick.sh`
- `validate-readmes.sh`
- `validate-all-standards.sh`

## Risk Assessment

### High Risk Areas

1. **Breaking Existing Coordinator Behavior**
   - Risk: Changes to research-coordinator.md could break existing workflows
   - Mitigation: Thorough testing with multiple test cases before deployment
   - Rollback: Git revert available, behavioral file changes isolated

2. **Validation Block Performance Impact**
   - Risk: Additional validation blocks increase command execution time
   - Mitigation: Validation blocks are fail-fast (quick signal checks)
   - Acceptance: <1 second additional overhead acceptable for error prevention

3. **Documentation Drift**
   - Risk: Documentation updates may fall out of sync with implementation
   - Mitigation: Update docs in same phase as implementation
   - Verification: Link validation enforced by pre-commit hooks

### Medium Risk Areas

1. **Test Coverage Gaps**
   - Risk: Edge cases not covered by test scenarios
   - Mitigation: Test single-topic, multi-topic, and failure scenarios
   - Monitoring: Use /errors to track real-world failures post-deployment

2. **Linter False Positives**
   - Risk: Enhanced linter may flag legitimate Task patterns
   - Mitigation: Review linter logic carefully, test on existing files first
   - Fallback: Linter produces warnings only, doesn't block execution

### Low Risk Areas

1. **Agent Output Retrieval Error Handling**
   - Risk: Structured error logging may not capture all error types
   - Mitigation: Start with known error patterns, expand based on real-world data
   - Impact: Minimal - improves debugging, doesn't affect functionality

## Rollback Plan

### Rollback Triggers

Initiate rollback if:
- Research-coordinator fails in production after deployment
- Validation blocks cause workflow failures
- Error logging creates excessive noise
- Pre-commit hooks block legitimate changes

### Rollback Procedure

1. **Immediate Revert**:
   ```bash
   git revert <commit-hash>  # Revert research-coordinator.md changes
   git revert <commit-hash>  # Revert create-plan.md changes
   git push origin master
   ```

2. **Selective Rollback** (if only one phase problematic):
   - Phase 1 rollback: Revert research-coordinator.md only
   - Phase 2 rollback: Revert validation blocks only
   - Phase 3 rollback: Revert error handling enhancements only

3. **Verification After Rollback**:
   ```bash
   /create-plan "rollback test" --complexity 3
   # Verify: Command completes successfully
   # Verify: No new errors in errors.jsonl
   ```

4. **Post-Rollback Analysis**:
   - Query errors: `/errors --since 1h --summary`
   - Identify root cause of rollback trigger
   - Plan fixes in separate branch
   - Re-test before re-deployment

## Success Metrics

### Quantitative Metrics

1. **Coordinator Success Rate**: 100% (no empty reports directories)
2. **Task Invocation Count**: Matches topic count (e.g., 4 topics = 4 Task invocations)
3. **Error Retrieval Failures**: 0 (no "Error retrieving agent output" messages)
4. **Fallback Invocations**: 0 (no manual research-specialist fallbacks needed)
5. **Wasted Execution Time**: 0 seconds (no coordinator execution without output)

### Qualitative Metrics

1. **Error Messages Are Actionable**: Errors point to specific fixes (e.g., "Review research-coordinator.md STEP 3")
2. **Debugging Is Streamlined**: errors.jsonl entries provide sufficient context for root cause analysis
3. **Standards Are Enforced**: Linter prevents future pseudo-code Task patterns
4. **Documentation Is Complete**: Troubleshooting guide covers common failure modes

### Validation Criteria

- [ ] All test cases pass without fallbacks
- [ ] Linter validation passes on all agent files
- [ ] Error logs contain no agent_error entries for coordinators
- [ ] Documentation links validate without errors
- [ ] Pre-commit hooks enforce standards without false positives

## Notes

### Related Issues

- research-coordinator agent execution failure (root cause analysis in report 001)
- Pseudo-code Task invocation patterns (standards violation documented in report 002)
- Missing hard barrier validation (pattern gap documented in report 003)

### Future Enhancements

1. **Coordinator Health Monitoring**
   - Add metrics tracking for coordinator success rates
   - Alert on repeated failures or fallback patterns
   - Dashboard for coordinator performance

2. **Enhanced Self-Validation**
   - Add more aggressive self-validation checkpoints in coordinators
   - Implement hard stop if Task invocation count mismatch detected
   - Add explicit "I just used the Task tool" confirmation prompts

3. **Behavioral File Linting**
   - Create dedicated linter for agent behavioral files
   - Detect pseudo-code patterns before deployment
   - Validate compliance with agent authoring standards

### References

- [Task Tool Invocation Patterns](../../.claude/docs/reference/standards/command-authoring.md#task-tool-invocation-patterns)
- [Hard Barrier Subagent Delegation](../../.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- [Hierarchical Agents Examples](../../.claude/docs/concepts/hierarchical-agents-examples.md#example-7-research-coordinator)
- [Error Handling Pattern](../../.claude/docs/concepts/patterns/error-handling.md)
- [Non-Interactive Testing Standard](../../.claude/docs/reference/standards/non-interactive-testing-standard.md)
