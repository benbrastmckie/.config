# Research-Coordinator Early Return Fix - Implementation Plan

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix research-coordinator agent skipping Task invocations in STEP 3
- **Scope**: Refactor research-coordinator.md STEP 3 to use concrete Bash-generated Task invocations, add pre-execution validation barriers, and implement mandatory error return protocol to prevent silent failures
- **Status**: [COMPLETE]
- **Estimated Hours**: 6-8 hours
- **Complexity Score**: 85.0
- **Structure Level**: 0
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinator Early Return Root Cause](../reports/001-coordinator-early-return-root-cause.md)

## Overview

The research-coordinator agent is failing to invoke research-specialist agents in STEP 3, returning prematurely after 11 tool uses instead of executing the required Task invocations. This causes empty reports directories, forces expensive fallback behavior in primary agents (5.3x cost multiplier), and degrades context efficiency from 95% reduction to 0-50%.

Root cause analysis reveals that STEP 3 instructions use placeholder syntax `(use TOPICS[0])` and conditional patterns `if TOPICS array length > 1` that the agent model interprets as "documentation templates" rather than "executable directives." The agent skips all Task invocations, bypasses self-validation checkpoints, and returns without error signals.

This plan implements the critical fixes identified in the root cause analysis: refactoring STEP 3 to use Bash-generated concrete Task invocations, adding pre-execution validation barriers (STEP 2.5), enforcing invocation trace validation, implementing mandatory error return protocol, and adding integration tests to prevent regression.

## Research Summary

The root cause analysis report (001-coordinator-early-return-root-cause.md) provides comprehensive evidence from the failed workflow execution:

**Key Findings**:
1. **Primary Root Cause**: Ambiguous execution context in STEP 3 - placeholder syntax and conditional language signal "documentation" not "execution"
2. **Tool Usage Pattern**: Coordinator used only 11 tools (expected 14+), confirming it completed STEP 1-2 but skipped STEP 3 Task invocations
3. **Missing Artifacts**: No invocation trace file created, empty reports directory after coordinator return
4. **Silent Failure**: No TASK_ERROR signal returned to primary agent, forcing heuristic detection via empty directory check
5. **Cost Impact**: 5.3x cost multiplier (160k tokens vs 30k) due to fallback invocation pattern
6. **Context Degradation**: 95% context reduction benefit lost, partial report creation (2/3 reports from fallback)

**Validated Recommendations** (7 total):
- **Recommendation 1** (CRITICAL): Refactor STEP 3 to Bash loop generating concrete Task invocations
- **Recommendation 2** (HIGH): Add STEP 2.5 pre-execution validation barrier with invocation plan file
- **Recommendation 3** (MEDIUM): Enforce invocation trace file validation in STEP 4
- **Recommendation 4** (HIGH): Add mandatory error return protocol with trap handler
- **Recommendation 5** (MEDIUM): Split agent execution from command-author reference documentation
- **Recommendation 6** (LOW): Add explicit completion signal to workflow
- **Recommendation 7** (MEDIUM): Create integration test for coordinator workflow

**Implementation Priority**: Phase 1 addresses Recommendations 1 and 4 (critical path), Phase 2 addresses Recommendations 2 and 3 (validation barriers), Phase 3 addresses Recommendations 5-7 (quality improvements).

## Success Criteria

- [ ] Research-coordinator invokes research-specialist for ALL topics in TOPICS array (100% invocation rate)
- [ ] Invocation trace file created and validated in STEP 4 before report validation
- [ ] Empty directory detected and returns TASK_ERROR with structured error context (not silent failure)
- [ ] Primary agent receives RESEARCH_COORDINATOR_COMPLETE signal on successful completion
- [ ] Integration test passes with 3/3 reports created for 3-topic scenario
- [ ] No fallback invocation needed by primary agent (coordinator completes successfully)
- [ ] Manual test with /create-plan complexity 3 produces complete reports without fallback
- [ ] Validation scripts confirm STEP 3 refactor eliminates placeholder ambiguity

## Technical Design

### Architecture Changes

**Current Architecture** (broken):
```
research-coordinator STEP 3:
├─ Reads Task invocation "templates" with placeholders
├─ Interprets as documentation (not executable directives)
├─ Skips Task tool invocations
├─ Proceeds to STEP 4 validation
└─ Returns without error (silent failure or late detection)
```

**Target Architecture** (fixed):
```
research-coordinator STEP 3 (refactored):
├─ STEP 2.5: Pre-execution validation barrier
│  ├─ Calculate expected invocation count
│  ├─ Create .invocation-plan.txt (hard barrier artifact)
│  └─ Output invocation plan summary
├─ STEP 3: Bash-generated Task invocations
│  ├─ for loop iterates TOPICS array
│  ├─ Generates concrete Task invocations (no placeholders)
│  ├─ Creates .invocation-trace.log with INVOKED status
│  └─ Output unambiguous "EXECUTE NOW (Topic N)" directives
├─ STEP 4: Multi-layer validation
│  ├─ Validate .invocation-plan.txt exists (STEP 2.5 proof)
│  ├─ Validate .invocation-trace.log exists (STEP 3 proof)
│  ├─ Validate trace count == expected count
│  └─ Validate reports count == expected count
└─ Error handler: trap ERR → TASK_ERROR signal
```

### Component Changes

**File Modified**: `.claude/agents/research-coordinator.md`

**Section Changes**:
1. **STEP 2.5** (NEW): Pre-execution validation barrier with invocation plan file creation
2. **STEP 3** (REFACTORED): Replace placeholder Task blocks with Bash loop generating concrete invocations
3. **STEP 4** (ENHANCED): Add plan file validation, trace file validation, count validation
4. **Error Handling** (NEW): Add trap handler at workflow start for mandatory TASK_ERROR return
5. **STEP 6** (ENHANCED): Add explicit RESEARCH_COORDINATOR_COMPLETE signal
6. **Documentation Split** (NEW): Move command-author reference to separate guide file

**Key Design Decisions**:
- **Bash-generated invocations** eliminate placeholder ambiguity (agent cannot skip loop execution without skipping Bash script)
- **Invocation plan file** (.invocation-plan.txt) provides pre-execution commitment and STEP 4 validation artifact
- **Invocation trace file** (.invocation-trace.log) provides execution proof and post-mortem debugging capability
- **Error trap handler** prevents silent failures by catching all errors and returning structured TASK_ERROR
- **Multi-layer validation** creates defense-in-depth (plan file → trace file → report files)

### Integration Points

- **Primary agents** (/create-plan, /research, /lean-plan): No changes required (backward compatible)
- **research-specialist agent**: No changes required (invocation contract unchanged)
- **Error logging**: Error return protocol integrates with existing error-handling.sh pattern
- **Testing**: New integration test in `.claude/tests/integration/test-research-coordinator.sh`

### Standards Compliance

- **Code Standards**: Bash blocks use three-tier sourcing pattern (not applicable here - agent file)
- **Error Logging**: TASK_ERROR signal enables parse_subagent_error() parsing and errors.jsonl logging
- **Clean Break Development**: Refactor STEP 3 completely (no deprecated patterns)
- **Documentation Standards**: Split execution from reference, remove historical commentary
- **Non-Interactive Testing**: Integration test uses programmatic validation (exit codes, file counts)

## Implementation Phases

### Phase 1: Critical STEP 3 Refactor and Error Protocol [COMPLETE]
dependencies: []

**Objective**: Refactor STEP 3 to use Bash-generated concrete Task invocations and add mandatory error return protocol to fix primary root cause and prevent silent failures.

**Complexity**: High

**Tasks**:
- [x] Back up current research-coordinator.md to .backup file with timestamp
- [x] Replace STEP 3 (lines 219-409) with Bash loop pattern generating concrete Task invocations
  - [x] Add for loop: `for i in "${!TOPICS[@]}"; do`
  - [x] Generate Task invocation with concrete values (not placeholders): `$TOPIC`, `$REPORT_PATH`, `$CONTEXT`
  - [x] Use heredoc for Task prompt to ensure proper escaping: `cat <<EOF_TASK_INVOCATION`
  - [x] Create .invocation-trace.log during loop (coupled with invocation generation)
  - [x] Output "EXECUTE NOW (Topic N)" directive per iteration
- [x] Add error trap handler at STEP 1 start
  - [x] Add `set -e` and `set -u` for fail-fast behavior
  - [x] Add `trap 'handle_coordinator_error $? $LINENO' ERR`
  - [x] Implement handle_coordinator_error function with ERROR_CONTEXT and TASK_ERROR signal
  - [x] Include diagnostic context: topics_count, reports_created, trace_file existence
- [x] Remove all placeholder syntax from STEP 3 (search for `(use TOPICS[`, `(use REPORT_PATHS[`)
- [x] Remove conditional pattern language (`if TOPICS array length > 1`)
- [x] Verify refactored STEP 3 has no code fences around Task invocations

**Testing**:
```bash
# Validate placeholder removal
! grep -q "(use TOPICS\[" /home/benjamin/.config/.claude/agents/research-coordinator.md
! grep -q "(use REPORT_PATHS\[" /home/benjamin/.config/.claude/agents/research-coordinator.md

# Validate Bash loop pattern exists
grep -q "for i in \"\${!TOPICS\[@\]}\"; do" /home/benjamin/.config/.claude/agents/research-coordinator.md

# Validate error trap handler exists
grep -q "trap 'handle_coordinator_error" /home/benjamin/.config/.claude/agents/research-coordinator.md

# Validate TASK_ERROR signal in error handler
grep -q "TASK_ERROR:" /home/benjamin/.config/.claude/agents/research-coordinator.md
```

**Expected Duration**: 2-3 hours

---

### Phase 2: Pre-Execution Validation Barrier (STEP 2.5) [COMPLETE]
dependencies: [1]

**Objective**: Add STEP 2.5 pre-execution validation barrier that forces agent to declare invocation count and create invocation plan file before proceeding to STEP 3.

**Complexity**: Medium

**Tasks**:
- [x] Insert new STEP 2.5 section after STEP 2 (around line 215)
- [x] Add heading: `### STEP 2.5 (MANDATORY PRE-EXECUTION BARRIER): Invocation Planning`
- [x] Add Bash block calculating expected invocations: `EXPECTED_INVOCATIONS=${#TOPICS[@]}`
- [x] Create .invocation-plan.txt file with expected count and topic list
- [x] Output checkpoint message: "INVOCATION PLAN CREATED: $EXPECTED_INVOCATIONS Task invocations queued"
- [x] Add validation directive: "The invocation plan file MUST exist before proceeding to STEP 3"
- [x] Update STEP 4 validation to check .invocation-plan.txt existence before report validation
- [x] Add fail-fast check in STEP 4: exit 1 if plan file missing (proves STEP 2.5 skipped)

**Testing**:
```bash
# Validate STEP 2.5 section exists
grep -q "STEP 2.5 (MANDATORY PRE-EXECUTION BARRIER)" /home/benjamin/.config/.claude/agents/research-coordinator.md

# Validate invocation plan file creation in STEP 2.5
grep -A 10 "STEP 2.5" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q ".invocation-plan.txt"

# Validate STEP 4 checks for plan file
grep -A 30 "STEP 4" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q "invocation-plan.txt"
```

**Expected Duration**: 1-1.5 hours

---

### Phase 3: Invocation Trace Validation Enforcement [COMPLETE]
dependencies: [1, 2]

**Objective**: Make invocation trace file (.invocation-trace.log) mandatory and add validation in STEP 4 to detect Task invocation skipping.

**Complexity**: Low

**Tasks**:
- [x] Update STEP 4 validation (around line 489) to check .invocation-trace.log existence BEFORE checking reports
- [x] Add fail-fast check: exit 1 if trace file missing with diagnostic message
- [x] Add trace count validation: `TRACE_COUNT=$(grep -c "Status: INVOKED" "$TRACE_FILE")`
- [x] Validate trace count matches expected invocations: `[ "$TRACE_COUNT" -ne "$EXPECTED_INVOCATIONS" ] && exit 1`
- [x] Update diagnostic messages to reference both plan file and trace file for debugging
- [x] Ensure trace file cleanup happens only on successful completion (preserve on failure)

**Testing**:
```bash
# Validate trace file validation exists in STEP 4
grep -A 40 "STEP 4" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q ".invocation-trace.log"

# Validate trace count check
grep -A 40 "STEP 4" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q "grep -c \"Status: INVOKED\""

# Validate fail-fast on missing trace file
grep -A 40 "STEP 4" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q "exit 1"
```

**Expected Duration**: 1 hour

---

### Phase 4: Documentation Split and Completion Signal [COMPLETE]
dependencies: [1]

**Objective**: Split command-author reference documentation from agent execution file and add explicit completion signal for primary agent parsing.

**Complexity**: Low

**Tasks**:
- [x] Create new file: `.claude/docs/guides/agents/research-coordinator-integration-guide.md`
- [x] Move "Command-Author Reference" section (lines 857-901) from research-coordinator.md to integration guide
- [x] Add cross-reference in research-coordinator.md pointing to integration guide
- [x] Update STEP 6 (around line 550) to add explicit completion signal
- [x] Add RESEARCH_COORDINATOR_COMPLETE: SUCCESS signal to STEP 6 output
- [x] Include workflow metrics in completion signal: topics_processed, reports_created, context_reduction_pct, execution_time_seconds
- [x] Update integration guide with completion signal parsing example for command authors

**Testing**:
```bash
# Validate integration guide exists
test -f /home/benjamin/.config/.claude/docs/guides/agents/research-coordinator-integration-guide.md

# Validate command-author reference removed from agent file
! grep -q "Command-Author Reference" /home/benjamin/.config/.claude/agents/research-coordinator.md

# Validate completion signal added to STEP 6
grep -A 15 "STEP 6" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q "RESEARCH_COORDINATOR_COMPLETE: SUCCESS"

# Validate workflow metrics in completion signal
grep -A 20 "STEP 6" /home/benjamin/.config/.claude/agents/research-coordinator.md | grep -q "topics_processed"
```

**Expected Duration**: 1 hour

---

### Phase 5: Integration Test Development [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Create integration test validating coordinator invokes all research-specialist agents and produces complete reports without Task invocation skipping.

**Complexity**: Medium

**Tasks**:
- [x] Create test file: `.claude/tests/integration/test-research-coordinator.sh`
- [x] Implement test_coordinator_invokes_all_specialists function
- [x] Setup test environment with temporary report directory
- [x] Define test TOPICS array with 3 topics
- [x] Simulate coordinator invocation (requires Task tool test harness)
- [x] Validate 3 reports created: `REPORT_COUNT=$(ls "$TEST_REPORT_DIR"/[0-9][0-9][0-9]-*.md 2>/dev/null | wc -l)`
- [x] Assert REPORT_COUNT == 3
- [x] Validate .invocation-plan.txt exists
- [x] Validate .invocation-trace.log exists with 3 INVOKED entries
- [x] Add test cleanup (rm -rf test directory)
- [x] Integrate test into CI test suite (update test runner)

**Testing**:
```bash
# Run integration test
bash /home/benjamin/.config/.claude/tests/integration/test-research-coordinator.sh

# Validate test exits 0 on success
TEST_EXIT_CODE=$?
[ "$TEST_EXIT_CODE" -eq 0 ] || exit 1

# Validate test is discoverable by test runner
grep -q "test-research-coordinator.sh" /home/benjamin/.config/.claude/tests/run-all-tests.sh
```

**Expected Duration**: 2 hours

---

### Phase 6: Manual Validation and Documentation [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Perform manual end-to-end test with /create-plan complexity 3 to validate coordinator completes successfully without fallback, and update related documentation.

**Complexity**: Low

**Tasks**:
- [x] Run manual test: `/create-plan "Test feature for coordinator validation" --complexity 3`
- [x] Verify coordinator invokes all research-specialist agents (check create-plan-output.md)
- [x] Verify no fallback invocation by primary agent (no "invoking research-specialist directly" message)
- [x] Verify all reports created in reports/ directory (no empty directory)
- [x] Verify .invocation-plan.txt and .invocation-trace.log exist in reports/ directory
- [x] Verify RESEARCH_COORDINATOR_COMPLETE signal in output
- [x] Update research-coordinator-integration-guide.md with troubleshooting section
- [x] Add "Fixed Issues" section to integration guide documenting this bug and fix
- [x] Update hierarchical-agents-examples.md with research-coordinator reliability note
- [x] Update CHANGELOG.md or release notes with coordinator fix details

**Testing**:
```bash
# Manual test execution (requires user interaction)
# Expected output: RESEARCH_COORDINATOR_COMPLETE: SUCCESS
# Expected reports: 3 files in reports/ directory
# Expected artifacts: .invocation-plan.txt and .invocation-trace.log

# Validate documentation updates
test -f /home/benjamin/.config/.claude/docs/guides/agents/research-coordinator-integration-guide.md
grep -q "Troubleshooting" /home/benjamin/.config/.claude/docs/guides/agents/research-coordinator-integration-guide.md
grep -q "Fixed Issues" /home/benjamin/.config/.claude/docs/guides/agents/research-coordinator-integration-guide.md
```

**Expected Duration**: 1-2 hours

---

## Testing Strategy

### Unit Testing
- Validate placeholder syntax removed from research-coordinator.md (grep-based validation)
- Validate Bash loop pattern exists (grep -q "for i in")
- Validate error trap handler exists (grep -q "trap 'handle_coordinator_error")
- Validate STEP 2.5 section exists (grep -q "STEP 2.5")
- Validate STEP 4 validation layers (plan file, trace file, report count)

### Integration Testing
- Integration test: test-research-coordinator.sh validates 3/3 reports created for 3-topic scenario
- Test validates .invocation-plan.txt creation and expected invocation count
- Test validates .invocation-trace.log creation and trace entry count
- Test validates no silent failures (coordinator returns success or TASK_ERROR)

### Manual Testing
- Run /create-plan with complexity 3 (triggers research-coordinator)
- Verify coordinator completes without primary agent fallback
- Verify all research reports created in reports/ directory
- Verify RESEARCH_COORDINATOR_COMPLETE signal in create-plan-output.md
- Verify .invocation-plan.txt and .invocation-trace.log artifacts present

### Validation Criteria
Fix is successful if:
- Research-coordinator invokes research-specialist for ALL topics in TOPICS array (100% invocation rate)
- Invocation trace file created and validated in STEP 4 before report validation
- Empty directory detected and returns TASK_ERROR with structured error context (not silent failure)
- Primary agent receives RESEARCH_COORDINATOR_COMPLETE signal on successful completion
- Integration test passes with 3/3 reports created
- No fallback invocation needed by primary agent
- Manual /create-plan test produces complete reports without fallback

## Documentation Requirements

### Files to Update
1. **research-coordinator.md** (primary changes):
   - STEP 3 refactor (Bash loop pattern)
   - STEP 2.5 addition (pre-execution barrier)
   - STEP 4 enhancement (multi-layer validation)
   - Error handler addition (trap and TASK_ERROR)
   - STEP 6 enhancement (completion signal)
   - Remove command-author reference section

2. **research-coordinator-integration-guide.md** (NEW):
   - Command invocation examples
   - Completion signal parsing
   - Troubleshooting section
   - Fixed issues section (this bug)

3. **hierarchical-agents-examples.md**:
   - Update Example 7 (research-coordinator pattern) with reliability note
   - Reference this fix in pattern description

4. **CHANGELOG.md** or release notes:
   - Document coordinator reliability fix
   - Note 5.3x cost reduction benefit

### Documentation Standards Compliance
- Remove all historical commentary (clean break approach)
- Use active voice and present tense
- Include code examples with proper syntax highlighting
- Cross-reference related documentation (hard barrier pattern, error handling)
- Follow markdown standards (no emojis in file content)

## Dependencies

### Prerequisites
- research-coordinator.md file exists at `.claude/agents/research-coordinator.md`
- Root cause analysis complete (001-coordinator-early-return-root-cause.md)
- No breaking changes to research-specialist agent contract

### External Dependencies
- None (changes isolated to research-coordinator agent)

### Integration Dependencies
- Primary agents (/create-plan, /research, /lean-plan) expect backward-compatible coordinator behavior
- Error logging infrastructure (error-handling.sh) must support TASK_ERROR signal parsing

### Rollback Plan
- Backup file created in Phase 1 enables instant rollback: `cp research-coordinator.md.backup research-coordinator.md`
- All changes confined to single agent file (research-coordinator.md)
- Integration test provides regression detection if rollback needed

## Risk Assessment

### High-Risk Items
- **Bash loop pattern adoption**: Agent must execute Bash script and then execute generated Task invocations (two-step process introduces new potential failure mode)
  - Mitigation: STEP 2.5 validation barrier ensures agent commits to invocation count before STEP 3
  - Mitigation: STEP 4 trace file validation detects if Bash ran but Task invocations skipped

### Medium-Risk Items
- **Integration test reliability**: Test requires Task tool simulation which may be complex to implement
  - Mitigation: Start with simplified test validating file artifacts only (plan file, trace file, reports)
  - Mitigation: Add full Task invocation test in later iteration if test harness available

### Low-Risk Items
- **Documentation split**: Moving command-author reference to separate file
  - Mitigation: Minimal risk, backward compatible (no behavior change)

### Unknown Risks
- **Agent model interpretation of Bash output**: Will agent reliably execute "EXECUTE NOW (Topic N)" directives output by Bash script?
  - Mitigation: Add explicit checkpoint messages after Bash script: "You MUST now execute each Task invocation above"
  - Mitigation: STEP 4 validation detects failure mode and returns TASK_ERROR

## Completion Checklist

- [ ] Phase 1 complete: STEP 3 refactored, error handler added, placeholders removed
- [ ] Phase 2 complete: STEP 2.5 pre-execution barrier added, plan file validated in STEP 4
- [ ] Phase 3 complete: Trace file validation enforced in STEP 4
- [ ] Phase 4 complete: Documentation split, completion signal added
- [ ] Phase 5 complete: Integration test passes with 3/3 reports
- [ ] Phase 6 complete: Manual test successful, documentation updated
- [ ] All tests passing (unit, integration, manual)
- [ ] Documentation updated (integration guide, examples, changelog)
- [ ] No regression in primary agent workflows (/create-plan, /research, /lean-plan)
