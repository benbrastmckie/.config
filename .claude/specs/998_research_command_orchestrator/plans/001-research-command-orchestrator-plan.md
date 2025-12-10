# Implementation Plan: Research Command Orchestrator Optimization

## Metadata

**Date**: 2025-12-09 (Revised)
**Feature**: Optimize /research command using orchestrator pattern with coordinator agents for 95% context reduction
**Status**: [NOT STARTED]
**Estimated Hours**: 8-10 hours
**Standards File**: /home/benjamin/.config/CLAUDE.md
**Research Reports**:
- [Research Command Efficiency Analysis](../reports/001-research-command-efficiency-analysis.md)
- [Orchestrator Pattern Research](../reports/002-orchestrator-pattern-research.md)
- [Research Optimization Strategy](../reports/003-research-optimization-strategy.md)
- [Infrastructure Standards Integration](../reports/004-infrastructure-standards-integration.md)
- [Revision Analysis: /implement Patterns and .claude/docs/ Standards](../reports/revision-analysis-implement-research-standards.md)

## Overview

The /research command demonstrates significant architectural inefficiency with 9 separate bash blocks requiring repeated state restoration overhead (~495 lines of boilerplate), redundant topic decomposition logic, and all-or-nothing validation that contradicts the coordinator's partial success mode. While the command already integrates research-coordinator for multi-topic research, critical optimizations are needed: (1) consolidate bash blocks from 9 to 3, (2) implement brief summary parsing to trust coordinator validation, (3) align with partial success thresholds, (4) eliminate redundant validation logic, and (5) remove single-topic fallback path for consistency.

Research reveals the command achieves 95% context reduction when properly delegated but creates coordination complexity through hard barrier pattern overhead (3:1 block-to-delegation ratio). The optimization strategy focuses on refining edge cases, improving error recovery, and standardizing the orchestrator-coordinator-specialist hierarchy while maintaining full infrastructure compliance.

## Success Criteria

- [ ] Bash blocks reduced from 9 to 3 (Setup/Coordinate/Complete)
- [ ] Brief summary parsing implemented (trust coordinator validation)
- [ ] Partial success mode aligned (≥50% threshold)
- [ ] Redundant validation logic eliminated (70+ lines removed)
- [ ] Single-topic backward compatibility preserved (complexity < 3 bypass)
- [ ] State restoration overhead reduced by 60%+ (~350 lines)
- [ ] Error logging coverage ≥80% of exit points
- [ ] All validators passing (sourcing, suppression, conditionals)
- [ ] Coordinator metadata parsing integrated
- [ ] Console summary format standardized
- [ ] Return signal format specified and parsed (RESEARCH_COMPLETE)
- [ ] Three-tier library sourcing explicit in all blocks
- [ ] Non-interactive testing metadata in all test phases

## Technical Context

### Architecture Analysis

**Current State** (9-block architecture):
- Block 1a: Argument capture
- Block 1b: Topic name path pre-calculation
- Block 1b-exec: Topic naming agent invocation
- Block 1c: Hard barrier validation
- Block 1d-topics: Topic decomposition
- Block 1d: Report path pre-calculation
- Block 1d-exec: Research coordinator invocation
- Block 1e: Agent output validation
- Block 2: Completion summary

**Target State** (3-block architecture):
- Block 1: Setup (capture, validation, topic naming, decomposition, path calculation)
- Block 2: Coordination (coordinator invocation, brief summary parsing)
- Block 3: Completion (metadata aggregation, console summary)

**Key Inefficiencies Identified**:
1. Multi-block state restoration overhead: 55 lines × 9 blocks = 495 lines total
2. Hard barrier pattern complexity: 3:1 ratio (3 blocks per delegation)
3. Redundant topic decomposition: Command duplicates coordinator's STEP 1 logic
4. Context consumption during validation: Block 1e re-implements coordinator's STEP 4
5. Missing intermediate summary parsing: Ignores coordinator's success signal

### Infrastructure Integration Requirements

**State Persistence Pattern**:
- Three-tier library sourcing with fail-fast handlers
- Workflow state initialization in Block 1 only
- State loading with validation in Blocks 2-3
- Space-separated strings for array-like data (not JSON arrays)

**Error Logging Pattern**:
- Dual trap setup (early + late)
- Agent error parsing via parse_subagent_error()
- 80%+ coverage target for log_command_error calls
- Error type classification: validation_error, state_error, agent_error, file_error

**Command Authoring Compliance**:
- Execution directives on all bash blocks and Task invocations
- No naked Task blocks without `**EXECUTE NOW**`
- Exit code capture pattern (no `if !` conditionals)
- Single summary line per block (not multiple progress messages)

**Hierarchical Agent Integration**:
- Orchestrator (command) → Supervisor (research-coordinator) → Workers (research-specialist)
- Metadata-only context passing (110 tokens per report vs 2,500 tokens full content)
- Hard barrier pattern: pre-calculate paths → invoke agent → validate artifacts
- Behavioral injection via Task prompt (single source of truth)

## Implementation Phases

### Phase 1: Block Consolidation and State Optimization [NOT STARTED]

**Objective**: Reduce bash blocks from 9 to 3 by consolidating state restoration and combining hard barrier validation checkpoints.

**Tasks**:
- [ ] Merge Block 1a (argument capture) and Block 1b (topic name pre-calculation) into single Block 1
- [ ] Combine Block 1b-exec (topic naming) and Block 1c (validation) into Block 1 continuation
- [ ] Integrate Block 1d-topics (decomposition) into Block 1 after topic naming
- [ ] Consolidate Block 1d (report path calculation) into Block 1 final section
- [ ] Extract state restoration pattern into single initialization (lines 23-77)
- [ ] Remove duplicate library sourcing from consolidated blocks
- [ ] Validate state persistence between new Block 1 and Block 2
- [ ] Update state file variable exports to use space-separated format

**Validation**:
- State variables persist correctly across Block 1 → Block 2 boundary
- TOPICS_LIST and REPORT_PATHS_LIST restored without errors
- CLAUDE_PROJECT_DIR detection occurs once (not per block)
- Library sourcing uses three-tier pattern with fail-fast handlers

**Success Criteria**:
- [ ] Block 1 completes setup, topic naming, decomposition, path calculation
- [ ] State restoration overhead reduced from 495 lines to ~55 lines
- [ ] All Tier 1 libraries sourced with fail-fast handlers
- [ ] No PATH MISMATCH errors from CLAUDE_PROJECT_DIR usage

**Files Modified**:
- `.claude/commands/research.md` (consolidate blocks)

---

### Phase 2: Brief Summary Parsing Implementation [NOT STARTED]

**Objective**: Implement coordinator metadata parsing pattern to trust coordinator validation instead of re-implementing all validation checks.

**Return Signal Format** (per /implement command pattern):
```
RESEARCH_COMPLETE: {REPORT_COUNT}
reports: [{"path": "...", "title": "...", "findings_count": N, "recommendations_count": N}, ...]
total_findings: {N}
total_recommendations: {N}
```

**Tasks**:
- [ ] Remove Block 1e (70+ lines of validation logic)
- [ ] Add coordinator metadata parsing in new Block 2
- [ ] Extract RESEARCH_COMPLETE signal from coordinator output using grep pattern
- [ ] Parse JSON metadata array (reports created, findings count, recommendations count)
- [ ] Implement defensive parsing with fallback for malformed JSON
- [ ] Validate metadata extraction against expected report count
- [ ] Log coordinator errors via parse_subagent_error() integration
- [ ] Persist metadata to state for Block 3 consumption
- [ ] Specify 110 tokens per report metadata target (96% reduction)

**Return Signal Parsing Pattern** (from /implement):
```bash
RESEARCH_COMPLETE=$(grep "^RESEARCH_COMPLETE:" "$COORDINATOR_OUTPUT" | sed 's/^RESEARCH_COMPLETE:[[:space:]]*//')
REPORTS_JSON=$(grep "^reports:" "$COORDINATOR_OUTPUT" | sed 's/^reports:[[:space:]]*//')
TOTAL_FINDINGS=$(grep "^total_findings:" "$COORDINATOR_OUTPUT" | sed 's/^total_findings:[[:space:]]*//')
```

**Validation**:
- Coordinator success signal parsed correctly (RESEARCH_COMPLETE: N)
- Metadata JSON extracted without parsing errors
- Fallback handling for missing or malformed metadata
- Agent errors logged with full ERROR_CONTEXT details

**Success Criteria**:
- [ ] Block 1e validation logic removed (70+ lines eliminated)
- [ ] Coordinator metadata parsing functional in Block 2
- [ ] parse_subagent_error() integration complete
- [ ] Metadata persisted to state for downstream consumption
- [ ] Return signal format matches /implement pattern

**Files Modified**:
- `.claude/commands/research.md` (remove Block 1e, add parsing to Block 2)
- `.claude/agents/research-coordinator.md` (ensure return signal format documented)

---

### Phase 3: Partial Success Mode Alignment [NOT STARTED]

**Objective**: Align command validation with coordinator's documented partial success mode (≥50% threshold) to prevent waste of partial research results.

**Tasks**:
- [ ] Replace all-or-nothing validation with success percentage calculation
- [ ] Implement ≥50% threshold check with fail-fast on <50%
- [ ] Add warning output for 50-99% success rate scenarios
- [ ] Continue workflow with available reports when ≥50% threshold met
- [ ] Update error logging to distinguish total failure vs partial success
- [ ] Document partial success behavior in command docstring
- [ ] Add console summary section for partial completion warnings
- [ ] Test with simulated coordinator partial success scenarios

**Validation**:
- <50% success rate triggers exit 1 with error logging
- 50-99% success rate continues with warning message
- 100% success rate proceeds normally without warnings
- Partial reports accessible for downstream commands

**Success Criteria**:
- [ ] Partial success threshold implemented (≥50%)
- [ ] Warning messages display for partial completion
- [ ] Error logging distinguishes failure types
- [ ] Console summary reflects partial vs full completion

**Files Modified**:
- `.claude/commands/research.md` (update validation logic)

---

### Phase 4: Backward Compatibility and Logic Optimization [NOT STARTED]

**Objective**: Preserve backward compatibility for single-topic research while delegating multi-topic scenarios to research-coordinator Mode 1.

**Rationale**: Per revision analysis, /research must NOT break existing single-topic workflows. The plan previously proposed removing single-topic fallback, but this would break backward compatibility. Instead, maintain single-topic bypass for complexity < 3 scenarios.

**Tasks**:
- [ ] Preserve single-topic fallback path for complexity < 3
- [ ] Remove redundant topic decomposition logic that duplicates coordinator (~60 lines)
- [ ] Update coordinator invocation to use Mode 1 for complexity >= 3
- [ ] Simplify USE_MULTI_TOPIC conditional logic (binary decision: < 3 vs >= 3)
- [ ] Ensure TOPICS_ARRAY and TOPIC_COUNT calculated only for complexity >= 3
- [ ] Update coordinator contract to clarify Mode 1 invocation triggers
- [ ] Test single-topic research with direct research-specialist invocation
- [ ] Test multi-topic research with coordinator delegation

**Validation**:
- Single-topic research (complexity 1-2) bypasses coordinator correctly
- Multi-topic research (complexity 3-4) delegates to coordinator
- Backward compatible variable names preserved (REPORT_PATH singular for single-topic)
- Workflow type remains "research-only" (not changed to coordinator-specific type)

**Success Criteria**:
- [ ] Single-topic fallback path preserved for complexity < 3
- [ ] Duplicate decomposition logic removed (~60 lines)
- [ ] Coordinator Mode 1 used exclusively for complexity >= 3
- [ ] Backward compatibility validated with existing /research usage

**Files Modified**:
- `.claude/commands/research.md` (preserve fallback, remove duplicates)
- `.claude/agents/research-coordinator.md` (clarify Mode 1 triggers)

---

### Phase 5: Error Logging Coverage Enhancement [NOT STARTED]

**Objective**: Achieve ≥80% error logging coverage by adding log_command_error calls at all critical exit points.

**Tasks**:
- [ ] Audit all exit 1 statements in consolidated blocks
- [ ] Add log_command_error before state file validation failures
- [ ] Add log_command_error before topic naming agent failures
- [ ] Add log_command_error before coordinator invocation failures
- [ ] Add log_command_error before partial success threshold failures
- [ ] Implement dual trap setup (early + late) for bash errors
- [ ] Integrate parse_subagent_error() for coordinator errors
- [ ] Test error logging with simulated failures
- [ ] Verify errors.jsonl entries with correct error types

**Validation**:
- All exit 1 paths log errors before exiting
- Dual trap setup captures bash execution errors
- Agent errors parsed and logged with full context
- Error types correctly classified (validation_error, agent_error, file_error)

**Success Criteria**:
- [ ] Error logging coverage ≥80% of exit points
- [ ] Dual trap setup implemented (early + late)
- [ ] parse_subagent_error() integration complete
- [ ] Error log entries queryable via /errors command

**Files Modified**:
- `.claude/commands/research.md` (add error logging calls)

---

### Phase 6: Standards Compliance Validation [NOT STARTED]

**Objective**: Validate command passes all automated validators and enforces code quality standards.

**Tasks**:
- [ ] Run library sourcing validator: check-library-sourcing.sh
- [ ] Run error suppression validator: lint_error_suppression.sh
- [ ] Run bash conditionals validator: lint_bash_conditionals.sh
- [ ] Run all validators: validate-all-standards.sh --all
- [ ] Fix any ERROR-level violations blocking commits
- [ ] Review WARNING-level issues for informational context
- [ ] Validate no `if !` or `elif !` patterns remain
- [ ] Validate no error suppression on append_workflow_state
- [ ] Validate execution directives on all bash blocks and Task invocations
- [ ] Test pre-commit hook integration with staged changes

**Validation**:
- All ERROR-level validators pass without violations
- Pre-commit hook does not block staged changes
- No prohibited patterns detected in command file
- Execution directives present on all required blocks

**Success Criteria**:
- [ ] All validators passing (0 ERROR-level violations)
- [ ] Pre-commit hook integration validated
- [ ] No prohibited patterns remaining
- [ ] Code quality standards fully enforced

**Files Modified**:
- `.claude/commands/research.md` (fix violations)

---

### Phase 7: Console Summary Format Standardization [NOT STARTED]

**Objective**: Standardize console output format with 4-section structure (Summary/Topics/Artifacts/Next Steps) and emoji markers.

**Tasks**:
- [ ] Implement 4-section console summary format in Block 3
- [ ] Add Summary section (1-2 sentences on context reduction achieved)
- [ ] Add Topics Researched section (numbered list with findings counts)
- [ ] Add Artifacts Created section (report file paths and directory)
- [ ] Add Next Steps section (review, create-plan, query-errors commands)
- [ ] Include emoji markers for section headers (📋, 🔍, 📄, ➡️)
- [ ] Suppress interim output (single summary line per block)
- [ ] Test console output format with 1-topic and 4-topic scenarios
- [ ] Validate output matches standards in output-formatting.md

**Validation**:
- Console summary uses 4-section format consistently
- Emoji markers present and correctly positioned
- Interim output suppressed (no verbose progress messages)
- Summary reflects actual completion status (partial vs full)

**Success Criteria**:
- [ ] 4-section console summary implemented
- [ ] Emoji markers included per standards
- [ ] Interim output suppressed
- [ ] Format validated against output-formatting.md

**Files Modified**:
- `.claude/commands/research.md` (standardize Block 3 output)

---

### Phase 8: Documentation Updates [NOT STARTED]

**Objective**: Update command guide, standards sections, and agent documentation to reflect optimized architecture.

**Tasks**:
- [ ] Update research-command-guide.md with 3-block architecture
- [ ] Document brief summary parsing pattern in guide
- [ ] Document partial success mode behavior
- [ ] Add troubleshooting section for coordinator errors
- [ ] Update CLAUDE.md hierarchical_agent_architecture section
- [ ] Add /research to error_logging section "Used by" list
- [ ] Update research-coordinator.md to specify Mode 1 as primary
- [ ] Document invocation plan file lifecycle in coordinator
- [ ] Add performance metrics (95% context reduction, 40-60% time savings)
- [ ] Create migration notes for commands adopting coordinator pattern

**Validation**:
- All documentation reflects current implementation
- Guide includes working examples for 1-topic and multi-topic
- Standards sections reference /research as canonical implementation
- Coordinator documentation specifies Mode 1 as primary invocation

**Success Criteria**:
- [ ] Command guide updated with 3-block architecture
- [ ] CLAUDE.md sections updated
- [ ] Coordinator documentation enhanced
- [ ] Performance metrics documented

**Files Modified**:
- `.claude/docs/guides/commands/research-command-guide.md`
- `/home/benjamin/.config/CLAUDE.md`
- `.claude/agents/research-coordinator.md`

---

## Testing Strategy

### Non-Interactive Testing Requirements

All test phases MUST include automation metadata per non-interactive-testing-standard.md:
- `automation_type: automated`
- `validation_method: programmatic`
- `skip_allowed: false`
- `artifact_outputs: [list of test artifacts]`

### Unit Tests

**Test File**: `.claude/tests/commands/test_research_coordinator.sh`

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: [test_results.json, coverage_report.json]

**Test Cases**:
1. Block consolidation preserves state variables across boundaries
2. Coordinator metadata parsing handles well-formed JSON
3. Coordinator metadata parsing handles malformed JSON gracefully
4. Partial success threshold calculation (25%, 50%, 75%, 100%)
5. Error logging coverage for all exit paths
6. Single-topic bypass for complexity < 3
7. Mode 1 invocation with multi-topic research (complexity 3-4)
8. Return signal parsing matches expected format

**Validation Method**: Programmatic assertions on state files and error logs

---

### Integration Tests

**Test File**: `.claude/tests/integration/test_research_e2e.sh`

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: [integration_results.json, report_files.txt]

**Test Cases**:
1. End-to-end 3-topic research with full success
2. End-to-end 3-topic research with partial success (2/3 reports)
3. End-to-end research with coordinator failure
4. Hard barrier enforcement (missing report detection)
5. Console summary format validation (4-section structure)
6. Error logging integration via /errors query
7. State persistence across multi-block workflow
8. Single-topic backward compatibility (complexity 2)

**Validation Method**: Output file inspection and errors.jsonl verification

---

### Performance Tests

**Test File**: `.claude/tests/performance/test_research_performance.sh`

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: [performance_metrics.json]

**Test Cases**:
1. Context reduction measurement (baseline vs coordinator)
2. State restoration overhead (9-block vs 3-block architecture)
3. Parallel execution time savings (sequential vs parallel)
4. Memory usage profile for multi-topic research

**Expected Results**:
- Context reduction: ≥95% (7,500 → 330 tokens for 3 reports)
- State overhead reduction: ≥60% (495 → ~55 lines)
- Time savings: 40-60% (parallel vs sequential)
- Memory usage: No significant increase with coordinator pattern

---

## Dependencies

### Required Files
- `.claude/lib/core/state-persistence.sh` - State management functions
- `.claude/lib/core/error-handling.sh` - Error logging integration
- `.claude/lib/workflow/validation-utils.sh` - Validation helpers
- `.claude/agents/research-coordinator.md` - Coordinator behavioral file
- `.claude/agents/research-specialist.md` - Specialist behavioral file

### Standards References
- [Command Authoring Standards](../../docs/reference/standards/command-authoring.md) - Task invocation patterns, subprocess isolation, state persistence
- [Error Handling Pattern](../../docs/concepts/patterns/error-handling.md) - Error logging integration
- [Hierarchical Agents Overview](../../docs/concepts/hierarchical-agents-overview.md) - Coordinator patterns
- [Hierarchical Agents Examples](../../docs/concepts/hierarchical-agents-examples.md) - Example 7 (research-coordinator), Example 8 (implementer-coordinator)
- [Output Formatting Standards](../../docs/reference/standards/output-formatting.md) - Console summary format
- [Code Quality Enforcement](../../docs/reference/standards/enforcement-mechanisms.md) - Validators and pre-commit hooks
- [Non-Interactive Testing Standard](../../docs/reference/standards/non-interactive-testing-standard.md) - Test automation metadata

### External Dependencies
- jq (JSON parsing for coordinator metadata)
- bash 4.0+ (associative arrays for state management)

---

## Risks and Mitigations

### Risk 1: State Persistence Breaks Between Consolidated Blocks
**Likelihood**: Medium
**Impact**: High
**Mitigation**: Incremental consolidation with state validation after each merge; rollback capability if variables don't restore

### Risk 2: Coordinator Metadata Parsing Regression
**Likelihood**: Low
**Impact**: Medium
**Mitigation**: Defensive parsing with fallback to file validation if JSON malformed; comprehensive unit tests

### Risk 3: Partial Success Mode Introduces Ambiguity
**Likelihood**: Low
**Impact**: Medium
**Mitigation**: Clear warning messages for partial completion; document expected behavior in guide

### Risk 4: Validator Enforcement Blocks Legitimate Patterns
**Likelihood**: Low
**Impact**: Low
**Mitigation**: Review validator logic before enforcement; document bypass procedures for false positives

---

## Rollback Plan

### Phase-Level Rollback
Each phase is independently reversible via git:
1. Identify failing phase via test results
2. Revert commits for that phase: `git revert <phase_commit_range>`
3. Re-run validators to confirm stability
4. Document rollback reason in implementation summary

### Full Rollback to Current Architecture
If optimization proves unstable:
1. Revert all commits in this implementation
2. Restore original 9-block architecture
3. Document lessons learned for future optimization attempts
4. Keep research reports for future reference

---

## Performance Targets

### Context Efficiency
- Baseline: 7,500 tokens (3 reports × 2,500 tokens each)
- Target: 330 tokens (3 reports × 110 tokens metadata)
- Reduction: 95.6%

### State Management Overhead
- Baseline: 495 lines (55 lines × 9 blocks)
- Target: 165 lines (55 lines × 3 blocks)
- Reduction: 66.7%

### Time Savings
- Baseline: 120 seconds (4 topics sequential)
- Target: 48 seconds (4 topics parallel)
- Reduction: 60%

### Error Logging Coverage
- Target: ≥80% of exit 1 paths
- Measurement: Count log_command_error calls / total exit 1 statements

---

## Notes

### Design Decisions

1. **Why consolidate to 3 blocks instead of 2?**
   - Separation of concerns: Setup (Block 1) vs Execution (Block 2) vs Completion (Block 3)
   - State persistence boundary naturally falls between coordinator invocation and summary
   - Error isolation: Coordinator failures don't corrupt setup state

2. **Why trust coordinator validation instead of re-validating?**
   - Single source of truth principle: Coordinator is authority on report creation
   - Eliminates duplicate validation logic (~70 lines)
   - Brief summary parsing pattern proven in implementer-coordinator

3. **Why preserve single-topic backward compatibility?**
   - Per revision analysis: /research must NOT break existing single-topic workflows
   - Complexity < 3 bypasses coordinator for direct research-specialist invocation
   - Variable naming preserved: REPORT_PATH (singular) for single-topic, REPORT_PATHS (array) for multi-topic
   - Workflow type remains "research-only" for all complexity levels
   - Previous plan proposed removing single-topic path, but this would break backward compatibility

4. **Why implement partial success mode?**
   - Prevents waste of partial research results on transient failures
   - Aligns with coordinator's documented behavior (≥50% threshold)
   - Improves user experience for long-running multi-topic research

### Future Enhancements

1. **Wave-based research orchestration** (deferred to future work):
   - Support dependent research topics (e.g., "Research A before Research B")
   - Progress tracking for multi-wave research
   - Granular resume capability from failed wave

2. **LLM-based topic decomposition** (optional enhancement):
   - Replace heuristic splitting with semantic boundary detection
   - topic-decomposer-agent.md behavioral file
   - Improves decomposition quality for complex multi-clause requests

3. **Trace file optimization** (low priority):
   - Move trace files to .claude/tmp/ instead of reports directory
   - Document trace file format for debugging
   - Add timestamp to prevent conflicts on retry

---

## Completion Checklist

- [ ] All 8 phases completed without blocking errors
- [ ] All unit tests passing (100% pass rate)
- [ ] All integration tests passing (100% pass rate)
- [ ] Performance targets met (≥95% context reduction, ≥60% time savings)
- [ ] Error logging coverage ≥80%
- [ ] All validators passing (0 ERROR-level violations)
- [ ] Documentation updated (command guide, CLAUDE.md, agent docs)
- [ ] Console summary format standardized
- [ ] Pre-commit hook integration validated
- [ ] Implementation summary created with metrics

---

**Plan Status**: Ready for implementation with comprehensive research foundation and clear success criteria.
