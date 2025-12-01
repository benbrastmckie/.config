# /research Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: Fix systematic errors in /research workflow
- **Scope**: Address library sourcing, agent protocol violations, state machine initialization, and error logging gaps
- **Estimated Phases**: 7
- **Estimated Hours**: 18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 165.0
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/984_repair_research_20251130_101553/reports/001-error-analysis-repair-research.md)

## Overview

The /research command exhibits systematic failures across multiple layers: library sourcing violations (72 execution errors, 50% of all errors), subagent protocol violations (8 agent errors), state machine initialization gaps (28 state errors), and error logging coverage gaps (50% capture rate). This plan addresses all identified root causes through targeted fixes to bash sourcing patterns, agent prompt syntax, state machine guards, and error logging infrastructure.

## Research Summary

Error analysis of 142 total errors (16 /research-specific) reveals:

**Critical Findings**:
- **Library Sourcing Order Violations**: Functions called before libraries sourced (exit code 127 errors)
- **Agent Protocol Violations**: Escaped bash syntax `\!` causing parse errors, missing output file validation
- **State Machine Gaps**: STATE_FILE not set before transitions, invalid transition attempts
- **Error Logging Coverage**: Only 50% of runtime errors captured in error log

**Recommended Approach**: Multi-phase repair strategy addressing root causes in priority order (Critical → High → Medium priority), with comprehensive testing after each phase to prevent regressions.

## Success Criteria
- [ ] All /research execution errors (exit code 127) eliminated
- [ ] Topic naming agent 100% success rate (no agent_no_output_file fallbacks)
- [ ] Zero STATE_FILE uninitialized errors
- [ ] Error logging coverage increased from 50% to >90%
- [ ] All pre-commit hook validators pass
- [ ] /research workflow completes successfully with sample input
- [ ] Regression test suite covers all fixed patterns

## Technical Design

### Architecture Overview

**Layered Repair Strategy**:
```
Layer 1: Library Sourcing Foundation
  ├─ Tier 1: error-handling.sh (fail-fast)
  ├─ Tier 2: state-persistence.sh, workflow-state-machine.sh
  └─ Tier 3: domain-specific libraries

Layer 2: Agent Protocol Compliance
  ├─ Syntax validation (remove escaped operators)
  ├─ Output file validation (hard barrier checks)
  └─ Enhanced fallback strategy (semantic slug generation)

Layer 3: State Machine Robustness
  ├─ Initialization guards (load_workflow_state at entry)
  ├─ Transition validation (defensive STATE_FILE checks)
  └─ Transition graph review (fix invalid paths)

Layer 4: Error Logging Coverage
  ├─ Syntax/parse error capture (stderr logging)
  ├─ Error handler scope fixes (remove `local` violations)
  └─ Agent validation logging
```

**Key Design Decisions**:
- **Sequential Phases**: Layer 1 must complete before Layer 2 (dependency on sourcing)
- **Defensive Programming**: Add validation checks before critical operations
- **Clean-Break Approach**: No backward compatibility wrappers, atomic fixes per layer
- **Test-Driven**: Comprehensive test suite after each phase to prevent regressions

### Component Interactions

```
/research command entry
    ↓
[Phase 1] Library sourcing (fail-fast handlers)
    ↓
[Phase 2] State machine initialization (load_workflow_state)
    ↓
[Phase 3] Agent invocation (syntax-validated prompts)
    ↓
[Phase 4] Output validation (hard barrier checks)
    ↓
[Phase 5] State transitions (guarded sm_transition calls)
    ↓
[Phase 6] Error logging (comprehensive stderr capture)
```

## Implementation Phases

### Phase 1: Fix Agent Prompt Syntax Errors [NOT STARTED]
dependencies: []

**Objective**: Remove escaped bash operators from repair-analyst agent prompt to unblock /repair workflow

**Complexity**: Low

Tasks:
- [ ] Read repair-analyst agent prompt file (file: /home/benjamin/.config/.claude/agents/repair-analyst.md)
- [ ] Locate conditional with escaped negation operator `\!` (around line 182 in generated prompts)
- [ ] Replace `if [[ \! "$REPORT_PATH" =~ ^/ ]]; then` with `if [[ ! "$REPORT_PATH" =~ ^/ ]]; then`
- [ ] Search for other escaped bash operators in agent prompts (glob: `.claude/agents/*.md`)
- [ ] Validate agent prompt syntax using bash -n on generated prompts
- [ ] Test repair-analyst agent invocation with sample error log

Testing:
```bash
# Validate agent prompt syntax
cd /home/benjamin/.config
grep -n '\\\!' .claude/agents/repair-analyst.md  # Should return no matches after fix

# Test agent invocation
bash .claude/commands/repair.md --since 1h 2>&1 | tee /tmp/repair_test.log
grep -i "syntax error" /tmp/repair_test.log && echo "FAIL: Syntax errors remain" || echo "PASS: No syntax errors"
```

**Expected Duration**: 1 hour

---

### Phase 2: Enforce Three-Tier Library Sourcing Pattern [NOT STARTED]
dependencies: [1]

**Objective**: Audit and fix bash block sourcing order across /research and related commands to eliminate execution errors

**Complexity**: High

Tasks:
- [ ] Audit /research command sourcing blocks (file: /home/benjamin/.config/.claude/commands/research.md)
- [ ] Ensure Tier 1 sourcing (error-handling.sh) comes first with fail-fast handler
- [ ] Ensure Tier 2 sourcing (state-persistence.sh, workflow-state-machine.sh) before function calls
- [ ] Add function existence validation before first use: `declare -f append_workflow_state >/dev/null || { echo "ERROR: state-persistence.sh not sourced"; exit 1; }`
- [ ] Apply same pattern to /plan, /build, /errors, /revise, /debug commands
- [ ] Add validation script to check sourcing order compliance (file: /home/benjamin/.config/.claude/scripts/validate-sourcing-order.sh)
- [ ] Update pre-commit hook to run sourcing order validator
- [ ] Run check-library-sourcing.sh validator on all fixed commands

Testing:
```bash
# Test sourcing order validator
cd /home/benjamin/.config
bash .claude/scripts/validate-all-standards.sh --sourcing
# Expected: No ERROR-level violations

# Test /research command with validation
bash .claude/commands/research.md "test topic" 2>&1 | grep -E "(command not found|exit code 127)" && echo "FAIL: Sourcing errors remain" || echo "PASS: No sourcing errors"
```

**Expected Duration**: 4 hours

---

### Phase 3: Add State Machine Initialization Guards [NOT STARTED]
dependencies: [2]

**Objective**: Add defensive checks to prevent state transitions before state machine initialization

**Complexity**: Medium

Tasks:
- [ ] Add load_workflow_state call to /research command entry point (after sourcing, before first transition)
- [ ] Add fail-fast handler for load_workflow_state: `load_workflow_state "$WORKFLOW_ID" "research" || { echo "ERROR: Failed to initialize state machine"; exit 1; }`
- [ ] Add defensive check to sm_transition function (file: /home/benjamin/.config/.claude/lib/core/workflow-state-machine.sh)
- [ ] Defensive check implementation: `[[ -z "$STATE_FILE" ]] && { log_command_error "state_error" "STATE_FILE not set" "sm_transition called before load_workflow_state"; return 1; }`
- [ ] Apply same pattern to /plan, /build, /revise, /debug commands
- [ ] Add test case for uninitialized state machine to test suite

Testing:
```bash
# Test state machine initialization guard
cd /home/benjamin/.config
# Simulate uninitialized state machine by skipping load_workflow_state
# Expected: sm_transition should log error and return 1

# Run full /research workflow
bash .claude/commands/research.md "test topic" 2>&1 | grep "STATE_FILE not set" && echo "FAIL: State initialization errors" || echo "PASS: State machine properly initialized"
```

**Expected Duration**: 2 hours

---

### Phase 4: Fix Topic Naming Agent Output Validation [NOT STARTED]
dependencies: [1]

**Objective**: Enhance subagent invocation to validate output file exists and improve fallback strategy

**Complexity**: Medium

Tasks:
- [ ] Read /research command topic naming agent invocation block
- [ ] Add output file existence check after agent invocation
- [ ] Implementation: `if [[ ! -f "$TOPIC_OUTPUT_FILE" ]]; then log_command_error "agent_error" "Topic naming agent produced no output" "file=$TOPIC_OUTPUT_FILE"; fi`
- [ ] Enhance fallback to generate semantic slug from description (not generic "no_name_error")
- [ ] Semantic slug logic: `TOPIC_SLUG=$(echo "$description" | tr ' ' '_' | tr -cd '[:alnum:]_' | cut -c1-50 | tr '[:upper:]' '[:lower:]')`
- [ ] Update research-specialist agent prompt to document output file requirements (file: /home/benjamin/.config/.claude/agents/research-specialist.md)
- [ ] Add agent output file protocol to hard-barrier-subagent-delegation.md pattern doc
- [ ] Test topic naming with valid and invalid agent responses

Testing:
```bash
# Test topic naming fallback
cd /home/benjamin/.config
# Simulate agent failure by removing output file
bash .claude/commands/research.md "complex feature description" 2>&1 | tee /tmp/topic_test.log
grep "no_name_error" /tmp/topic_test.log && echo "FAIL: Still using generic fallback" || echo "PASS: Semantic slug generated"

# Test topic naming success path
bash .claude/commands/research.md "authentication feature" 2>&1 | grep -E "Topic: [0-9]{3}_[a-z_]+" && echo "PASS: Valid topic generated"
```

**Expected Duration**: 3 hours

---

### Phase 5: Expand Error Logging Coverage [NOT STARTED]
dependencies: [2, 3]

**Objective**: Add logging for bash syntax/parse errors not captured by trap handlers

**Complexity**: High

Tasks:
- [ ] Design stderr capture wrapper for bash blocks in commands
- [ ] Implementation: `STDERR_LOG="/tmp/bash_stderr_$$.log"; { bash_block_code; } 2> >(tee "$STDERR_LOG" >&2)`
- [ ] Add syntax error detection: `if grep -qE "(syntax error|parse error|binary operator expected)" "$STDERR_LOG"; then log_command_error "parse_error" "Bash syntax error detected" "$(cat "$STDERR_LOG")"; fi`
- [ ] Apply stderr capture to /research, /plan, /build commands
- [ ] Fix error handler to avoid `local` outside functions (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh)
- [ ] Add agent prompt validation logging to parse_subagent_error function
- [ ] Test with known syntax error cases (escaped operators, missing quotes)
- [ ] Verify error log contains all stderr errors

Testing:
```bash
# Test syntax error logging
cd /home/benjamin/.config
# Introduce intentional syntax error in test command
bash -c 'eval "if [[ \! -f /tmp/test ]]; then echo test; fi"' 2>&1 | tee /tmp/syntax_test.log
grep "syntax error" /tmp/syntax_test.log && echo "Syntax error detected"

# Check error log contains entry
jq -r 'select(.error_type == "parse_error") | .error_message' .claude/data/logs/errors.jsonl | tail -1
# Expected: "Bash syntax error detected"
```

**Expected Duration**: 4 hours

---

### Phase 6: Review State Machine Transition Graphs [NOT STARTED]
dependencies: [3]

**Objective**: Audit and fix invalid state transition attempts across /research workflow

**Complexity**: Medium

Tasks:
- [ ] Document allowed transition graph for "research" scope (file: /home/benjamin/.config/.claude/docs/reference/state-machines/research-transitions.md)
- [ ] Review /research state transitions in command file
- [ ] Identify and fix invalid transitions (e.g., initialize→plan should be initialize→research)
- [ ] Add transition validation test suite (file: /home/benjamin/.config/.claude/tests/lib/test_state_transitions_research.sh)
- [ ] Test cases: valid transitions succeed, invalid transitions logged and rejected
- [ ] Update workflow-state-machine.sh documentation with research scope transitions

Testing:
```bash
# Test invalid transition rejection
cd /home/benjamin/.config
bash .claude/tests/lib/test_state_transitions_research.sh
# Expected: All tests pass, invalid transitions rejected

# Run full /research workflow
bash .claude/commands/research.md "test topic" 2>&1 | grep "Invalid state transition" && echo "FAIL: Invalid transitions attempted" || echo "PASS: All transitions valid"
```

**Expected Duration**: 3 hours

---

### Phase 7: Update Error Log Status [NOT STARTED]
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED

**Complexity**: Low

Tasks:
- [ ] Verify all fixes are working (tests pass, no new errors generated)
- [ ] Update error log entries to RESOLVED status:
  ```bash
  source .claude/lib/core/error-handling.sh
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "${PLAN_PATH}")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```
- [ ] Verify no FIX_PLANNED errors remain for this plan:
  ```bash
  REMAINING=$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c "$(basename "$(dirname "$(dirname "${PLAN_PATH}")")" )" || echo "0")
  [ "$REMAINING" -eq 0 ] && echo "All errors resolved" || echo "WARNING: $REMAINING errors still FIX_PLANNED"
  ```

Testing:
```bash
# Verify error log status updates
cd /home/benjamin/.config
jq -r 'select(.repair_plan_path | contains("984_repair_research_20251130_101553")) | .status' .claude/data/logs/errors.jsonl | sort | uniq -c
# Expected: All entries show "RESOLVED"

# Verify no FIX_PLANNED errors remain
jq -r 'select(.status == "FIX_PLANNED" and (.repair_plan_path | contains("984_repair_research_20251130_101553")))' .claude/data/logs/errors.jsonl | wc -l
# Expected: 0
```

**Expected Duration**: 1 hour

---

## Testing Strategy

### Unit Tests
- Test library sourcing order validation (check-library-sourcing.sh)
- Test state machine initialization guards (sm_transition with uninitialized STATE_FILE)
- Test topic naming fallback logic (semantic slug generation)
- Test error logging for syntax errors (stderr capture)
- Test state transition validation (invalid transition rejection)

### Integration Tests
- End-to-end /research workflow test with sample input
- Combined test: library sourcing + state machine + agent invocation
- Error logging coverage test (compare runtime errors to logged errors)
- Pre-commit hook validation (all validators pass)

### Regression Tests
- Test all fixed patterns with previous failure cases
- Verify error count decreases after each phase
- Monitor error log for new error types introduced by fixes

### Test Environment
- Use test error log (errors_test.jsonl) to avoid polluting production log
- Create test workflow IDs (test_research_YYYYMMDD_HHMMSS)
- Clean up test artifacts after test runs

### Coverage Requirements
- 100% of identified error patterns must have test coverage
- All phases must pass integration tests before marking complete
- Regression test suite must cover all 7 root causes from analysis

## Documentation Requirements

### Updated Documentation
- [ ] Update Code Standards with sourcing pattern examples (file: /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md)
- [ ] Update Error Handling Pattern with stderr capture pattern (file: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)
- [ ] Create research-transitions.md state machine doc (file: /home/benjamin/.config/.claude/docs/reference/state-machines/research-transitions.md)
- [ ] Update hard-barrier-subagent-delegation.md with output file protocol (file: /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
- [ ] Update /research command guide with initialization requirements (file: /home/benjamin/.config/.claude/docs/guides/commands/research-command-guide.md)

### New Documentation
- [ ] Create Bash Sourcing Troubleshooting Guide (file: /home/benjamin/.config/.claude/docs/troubleshooting/bash-sourcing-errors.md)
- [ ] Create Error Logging Best Practices (file: /home/benjamin/.config/.claude/docs/guides/development/error-logging-best-practices.md)

## Dependencies

### External Dependencies
- jq (JSON parsing for error log queries)
- bash 4.0+ (associative arrays, process substitution)
- grep with PCRE support (syntax error detection patterns)

### Internal Dependencies
- error-handling.sh library (error logging functions)
- state-persistence.sh library (workflow state functions)
- workflow-state-machine.sh library (state transition validation)
- unified-location-detection.sh library (artifact directory creation)

### Phase Dependencies
Phase dependencies enable parallel execution when using /build:
- Phase 1 has no dependencies (can run first)
- Phase 2 depends on Phase 1 (sourcing fixes before state fixes)
- Phase 3 depends on Phase 2 (state machine after sourcing)
- Phase 4 depends on Phase 1 (agent fixes independent of state)
- Phase 5 depends on Phases 2 and 3 (error logging after sourcing and state)
- Phase 6 depends on Phase 3 (transition review after initialization guards)
- Phase 7 depends on all previous phases (final verification)

Parallel execution waves:
- Wave 1: Phase 1
- Wave 2: Phase 2, Phase 4 (parallel)
- Wave 3: Phase 3
- Wave 4: Phase 5, Phase 6 (parallel)
- Wave 5: Phase 7

See [Parallel Execution Example](.claude/docs/guides/workflows/parallel-execution-example.md) for wave-based execution details.
