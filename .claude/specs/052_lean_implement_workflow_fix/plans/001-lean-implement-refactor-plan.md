# /lean-implement Hard Barrier Refactor Implementation Plan

## Metadata
- **Date**: 2025-12-04
- **Feature**: Refactor /lean-implement to use hard barrier pattern for mandatory coordinator delegation
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-12 hours
- **Complexity Score**: 65.0
- **Structure Level**: 0
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Delegation Analysis Report](../reports/001-lean-implement-delegation-analysis.md)

## Overview

The `/lean-implement` command currently exhibits delegation failures where the primary agent performs implementation work directly instead of delegating to coordinators (lean-coordinator, implementer-coordinator). This violates the hierarchical agent architecture and causes context exhaustion, inconsistent behavior, and missing parallel execution benefits.

**Root Cause**: Block 1b contains conditional Task invocations without verification enforcement. The agent can bypass delegation and work directly.

**Solution**: Implement the hard barrier pattern proven in `/implement` and `/lean-build`:
- Block 1b: Mandatory coordinator invocation (single Task per phase type)
- Block 1c: Hard barrier verification (summary file existence check)
- Enhanced routing: Read `implementer:` field from plan phases
- Progress tracking: Forward checkbox-utils instructions to coordinators

## Research Summary

Key findings from delegation analysis research:

**Hard Barrier Pattern (from /implement and /lean-build)**:
- Block 1b: Single mandatory Task invocation (no conditionals)
- Block 1c: Verification checkpoint that FAILS if summary not created
- Architectural enforcement through runtime validation, not prose instructions

**Current /lean-implement Failures**:
- No verification block prevents delegation bypass
- Conditional "If X then invoke Y" logic allows agent to skip Task invocation
- No summary existence check means bypass goes undetected

**Routing Enhancement**:
- Read explicit `implementer:` field from plan phases (Tier 1)
- Fallback to `lean_file:` detection (Tier 2)
- Eliminates fragile keyword heuristics

**Infrastructure Reuse**:
- State persistence (append_workflow_state, load_workflow_state)
- Error logging (log_command_error, parse_subagent_error)
- Checkbox utilities (add_in_progress_marker, mark_phase_complete)
- All required libraries already available

## Success Criteria

- [ ] Block 1b restructured with hard barrier pattern
- [ ] Block 1c verification enforces summary existence (≥100 bytes)
- [ ] Routing reads `implementer:` field from plan phases
- [ ] Progress tracking integrated (checkbox-utils forwarded to coordinators)
- [ ] All test cases pass (pure lean, pure software, hybrid, iteration, failure)
- [ ] Error logging integrated (TASK_ERROR parsing, agent_error context)

## Technical Design

### Block Architecture Changes

**Block 1a-classify** (Enhanced Routing):
- Add Tier 1 discovery: Read `implementer:` field from phase content
- Keep Tier 2 discovery: Fallback to `lean_file:` detection
- Validate routing map has valid phase types ("lean" or "software")
- Add routing map field: `phase_num:phase_type:lean_file:implementer`

**Block 1b** (Hard Barrier - Coordinator Invocation):
- **REMOVE**: Entire "COORDINATOR INVOCATION DECISION" conditional section
- **ADD**: Bash block that reads routing map and determines coordinator name
- **ADD**: Separate Task invocations for lean-coordinator and implementer-coordinator
- **ADD**: Block heading marker `[HARD BARRIER]`
- **Pattern**:
  ```bash
  # Read routing map
  PHASE_TYPE=$(get_current_phase_type "$ROUTING_MAP_FILE" "$CURRENT_PHASE")

  # Determine coordinator
  if [ "$PHASE_TYPE" = "lean" ]; then
    COORDINATOR_NAME="lean-coordinator"
  else
    COORDINATOR_NAME="implementer-coordinator"
  fi

  # Persist for verification
  append_workflow_state "COORDINATOR_NAME" "$COORDINATOR_NAME"
  ```

**Block 1c** (Hard Barrier - Verification):
- **ADD**: Summary file existence check (mandatory)
- **ADD**: File size validation (≥100 bytes)
- **ADD**: Enhanced diagnostics (alternate location search)
- **ADD**: Coordinator name in error messages
- **ADD**: Error signal parsing (`TASK_ERROR:` from coordinator output)
- **Pattern**:
  ```bash
  # HARD BARRIER: Summary file MUST exist
  LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f -mmin -10 2>/dev/null | sort | tail -1)

  if [ -z "$LATEST_SUMMARY" ] || [ ! -f "$LATEST_SUMMARY" ]; then
    echo "❌ HARD BARRIER FAILED - Summary not created by $COORDINATOR_NAME" >&2
    log_command_error ...
    exit 1
  fi
  ```

### Routing Map Format

**Enhanced Format**:
```bash
# Current: phase_num:phase_type:lean_file
1:lean:/path/to/file.lean
2:software:none

# Enhanced: phase_num:phase_type:lean_file:implementer
1:lean:/path/to/file.lean:lean-coordinator
2:software:none:implementer-coordinator
```

**Tier 1 Discovery** (Phase Metadata):
```bash
# Read implementer field
IMPLEMENTER=$(echo "$phase_content" | grep -E "^implementer:" | sed 's/^implementer:[[:space:]]*//')

if [ -n "$IMPLEMENTER" ]; then
  case "$IMPLEMENTER" in
    lean|software)
      echo "$IMPLEMENTER"
      return 0
      ;;
  esac
fi
```

**Tier 2 Discovery** (Fallback):
```bash
# Check for lean_file metadata
if echo "$phase_content" | grep -qE "^lean_file:"; then
  echo "lean"
  return 0
fi
```

### Progress Tracking Integration

**Forward to Both Coordinators**:
```markdown
Progress Tracking Instructions:
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before starting phase: add_in_progress_marker '${PLAN_FILE}' ${CURRENT_PHASE}
- After completing phase: mark_phase_complete '${PLAN_FILE}' ${CURRENT_PHASE} && add_complete_marker '${PLAN_FILE}' ${CURRENT_PHASE}
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- Note: Progress tracking gracefully degrades if unavailable (non-fatal)
```

### Error Handling Integration

**Parse Coordinator Errors**:
```bash
# Parse coordinator output for error signal
COORDINATOR_ERROR=$(parse_subagent_error "$COORDINATOR_OUTPUT" "$COORDINATOR_NAME")

if [ -n "$COORDINATOR_ERROR" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Coordinator failed: $COORDINATOR_ERROR" \
    "bash_block_1c" \
    "$(jq -n --arg coord "$COORDINATOR_NAME" --arg phase "$CURRENT_PHASE" \
       '{coordinator: $coord, phase: $phase}')"
  exit 1
fi
```

## Implementation Phases

### Phase 1: Block 1b Restructure (Hard Barrier) [COMPLETE]
dependencies: []

**Objective**: Replace conditional Task invocations with hard barrier pattern

**Complexity**: Medium

**Tasks**:
- [x] Remove COORDINATOR_INVOCATION_DECISION section (lean-implement.md:672-773)
- [x] Add bash block to read routing map and determine coordinator (file: .claude/commands/lean-implement.md)
- [x] Add separate Task invocation for lean-coordinator (file: .claude/commands/lean-implement.md)
- [x] Add separate Task invocation for implementer-coordinator (file: .claude/commands/lean-implement.md)
- [x] Add `[HARD BARRIER]` block heading marker (file: .claude/commands/lean-implement.md)
- [x] Add coordinator name persistence to state (append_workflow_state "COORDINATOR_NAME")

**Testing**:
```bash
# Verify Block 1b structure
grep -A 20 "## Block 1b:" .claude/commands/lean-implement.md | grep -q "HARD BARRIER"
grep -c "Task {" .claude/commands/lean-implement.md  # Should be 2 (one per coordinator type)

# Verify state persistence
grep -q "append_workflow_state \"COORDINATOR_NAME\"" .claude/commands/lean-implement.md
```

**Expected Duration**: 2-3 hours

### Phase 2: Block 1c Verification Enhancement [COMPLETE]
dependencies: [1]

**Objective**: Add hard barrier verification that enforces coordinator delegation

**Complexity**: Medium

**Tasks**:
- [x] Add summary file existence check to Block 1c (file: .claude/commands/lean-implement.md:774-970)
- [x] Add file size validation (≥100 bytes) (file: .claude/commands/lean-implement.md)
- [x] Add enhanced diagnostics with alternate location search (file: .claude/commands/lean-implement.md)
- [x] Add coordinator name in error messages (use $COORDINATOR_NAME variable)
- [x] Add error signal parsing for TASK_ERROR (use parse_subagent_error)
- [x] Add error logging integration (log_command_error with agent_error type)

**Testing**:
```bash
# Verify hard barrier implementation
grep -A 30 "## Block 1c:" .claude/commands/lean-implement.md | grep -q "HARD BARRIER"

# Verify file size check
grep -q "SUMMARY_SIZE.*100" .claude/commands/lean-implement.md

# Verify error logging
grep -q "log_command_error" .claude/commands/lean-implement.md
grep -q "parse_subagent_error" .claude/commands/lean-implement.md
```

**Expected Duration**: 2 hours

### Phase 3: Routing Enhancement (Tier 1 Discovery) [COMPLETE]
dependencies: []

**Objective**: Read explicit `implementer:` field from plan phases

**Complexity**: Low

**Tasks**:
- [x] Modify detect_phase_type() function to read implementer field (file: .claude/commands/lean-implement.md:429-461)
- [x] Add Tier 1: Check implementer field ("lean" or "software")
- [x] Add validation for invalid implementer values (warn and default to software)
- [x] Keep Tier 2: Fallback to lean_file detection
- [x] Add routing map validation for valid phase types
- [x] Update routing map format to include implementer field

**Testing**:
```bash
# Test Tier 1 discovery
PHASE_CONTENT="implementer: lean
lean_file: /path/to/file.lean"

RESULT=$(detect_phase_type "$PHASE_CONTENT" "1")
[ "$RESULT" = "lean" ] && echo "PASS" || echo "FAIL"

# Test Tier 2 fallback
PHASE_CONTENT="lean_file: /path/to/file.lean"
RESULT=$(detect_phase_type "$PHASE_CONTENT" "1")
[ "$RESULT" = "lean" ] && echo "PASS" || echo "FAIL"
```

**Expected Duration**: 1-2 hours

### Phase 4: Progress Tracking Integration [COMPLETE]
dependencies: []

**Objective**: Forward checkbox-utils instructions to both coordinators

**Complexity**: Low

**Tasks**:
- [x] Add progress tracking section to lean-coordinator Task prompt (file: .claude/commands/lean-implement.md:679-723)
- [x] Add progress tracking section to implementer-coordinator Task prompt (file: .claude/commands/lean-implement.md:727-772)
- [x] Include checkbox utilities sourcing instruction
- [x] Include add_in_progress_marker before phase start
- [x] Include mark_phase_complete and add_complete_marker after phase completion
- [x] Add graceful degradation note (non-fatal if unavailable)

**Testing**:
```bash
# Verify progress tracking in both Task prompts
grep -A 50 "Task {" .claude/commands/lean-implement.md | grep -c "Progress Tracking Instructions"
# Should output: 2 (one for each coordinator)

# Verify checkbox utilities sourcing
grep -q "source.*checkbox-utils.sh" .claude/commands/lean-implement.md
```

**Expected Duration**: 1 hour

### Phase 5: Integration Testing [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Test all scenarios and validate hard barrier enforcement

**Complexity**: High

**Tasks**:
- [x] Create test plan with 5 test cases (pure lean, pure software, hybrid, iteration, failure)
- [x] Test Case 1: Pure Lean plan (all phases lean type) (file: .claude/tests/commands/test_lean_implement_hard_barrier.sh)
- [x] Test Case 2: Pure software plan (all phases software type)
- [x] Test Case 3: Hybrid plan (mixed lean/software phases)
- [x] Test Case 4: Iteration test (large plan requiring continuation)
- [x] Test Case 5: Failure test (coordinator failure triggers hard barrier)
- [x] Verify summary existence check in all test cases
- [x] Verify error logging for failure cases
- [x] Document test results in phase completion summary

**Testing**:
```bash
# Run all test cases
bash .claude/tests/commands/test_lean_implement_hard_barrier.sh

# Expected output:
# ✓ Test Case 1: Pure Lean plan [PASS]
# ✓ Test Case 2: Pure software plan [PASS]
# ✓ Test Case 3: Hybrid plan [PASS]
# ✓ Test Case 4: Iteration test [PASS]
# ✓ Test Case 5: Failure test [PASS]
```

**Expected Duration**: 3-4 hours

### Phase 6: Documentation Updates [COMPLETE]
dependencies: [5]

**Objective**: Update command documentation with hard barrier pattern details

**Complexity**: Low

**Tasks**:
- [x] Update lean-implement.md with hard barrier explanation (file: .claude/commands/lean-implement.md)
- [x] Add troubleshooting section for delegation failures (file: .claude/docs/troubleshooting/lean-implement-delegation-errors.md)
- [x] Update lean-implement-command-guide.md with routing explanation (file: .claude/docs/guides/commands/lean-implement-command-guide.md)
- [x] Document `implementer:` field format in plan metadata standard
- [x] Add examples of hard barrier verification in command reference
- [x] Update command README with architecture changes

**Testing**:
```bash
# Verify documentation completeness
grep -q "hard barrier" .claude/commands/lean-implement.md
grep -q "HARD BARRIER" .claude/commands/lean-implement.md

# Verify troubleshooting section exists
[ -f .claude/docs/troubleshooting/lean-implement-delegation-errors.md ]

# Validate internal links
bash .claude/scripts/validate-links-quick.sh .claude/commands/lean-implement.md
```

**Expected Duration**: 1 hour

## Testing Strategy

### Test Coverage Requirements

**Unit Tests**:
- detect_phase_type() function (Tier 1 and Tier 2 discovery)
- Routing map parsing and validation
- Summary file existence check logic
- Error signal parsing (TASK_ERROR format)

**Integration Tests**:
- Pure lean plan execution (all phases route to lean-coordinator)
- Pure software plan execution (all phases route to implementer-coordinator)
- Hybrid plan execution (correct routing for each phase type)
- Iteration loop with continuation context
- Coordinator failure triggering hard barrier

**Verification Tests**:
- Hard barrier FAILS when summary not created
- Hard barrier FAILS when summary too small (<100 bytes)
- Error logging captures coordinator failures
- Progress tracking updates plan markers

### Test Execution

```bash
# Run unit tests
bash .claude/tests/unit/test_lean_implement_routing.sh

# Run integration tests
bash .claude/tests/commands/test_lean_implement_hard_barrier.sh

# Run failure scenario tests
bash .claude/tests/commands/test_lean_implement_failure_cases.sh

# Verify error logging
/errors --command /lean-implement --since 1h --summary
```

### Coverage Targets

- Block 1a-classify: 100% (routing logic critical)
- Block 1b: 100% (hard barrier invocation)
- Block 1c: 100% (verification checkpoint)
- Error handling: 95% (edge cases documented)

## Documentation Requirements

### Command Documentation

**Update lean-implement.md**:
- Add "Hard Barrier Pattern" section explaining Block 1b and 1c architecture
- Document `implementer:` field format for plan phases
- Add troubleshooting section for common delegation failures

**Update lean-implement-command-guide.md**:
- Explain routing logic (Tier 1 → Tier 2 discovery)
- Provide examples of plan phase metadata
- Document error messages and troubleshooting steps

**Create lean-implement-delegation-errors.md**:
- Document "HARD BARRIER FAILED" error messages
- Provide diagnostic steps for summary file issues
- Explain coordinator failure scenarios

### Standards Updates

**No CLAUDE.md changes required** - the hard barrier pattern is already documented in the hierarchical agent architecture section. This implementation applies existing patterns to /lean-implement.

## Dependencies

### External Dependencies
- lean-lsp-mcp MCP server (already required by /lean-build)
- Lean 4 project with lakefile.toml or lakefile.lean

### Library Dependencies
- error-handling.sh >=1.0.0 (log_command_error, parse_subagent_error)
- state-persistence.sh >=1.6.0 (append_workflow_state, load_workflow_state)
- workflow-state-machine.sh >=2.0.0 (sm_init, sm_transition)
- checkbox-utils.sh (add_in_progress_marker, mark_phase_complete)

### Agent Dependencies
- lean-coordinator.md (invoked for lean phases)
- implementer-coordinator.md (invoked for software phases)

All dependencies already available - no new libraries or agents required.

## Risk Assessment

### Low Risk
- Block 1a-classify enhancement (additive change, backward compatible)
- Progress tracking integration (graceful degradation if unavailable)
- Documentation updates (non-breaking)

### Medium Risk
- Block 1b restructure (requires careful state management, but pattern proven in /implement)
- Block 1c verification (must ensure summary path discovery works across both coordinators)

### Mitigation Strategies
- Test with small plans first (1-2 phases)
- Verify state persistence across blocks before full integration
- Add enhanced diagnostics for summary file discovery failures
- Document rollback procedure (restore lean-implement.md from git)

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Block 1b Restructure | 2-3 hours | None |
| Phase 2: Block 1c Verification | 2 hours | Phase 1 |
| Phase 3: Routing Enhancement | 1-2 hours | None |
| Phase 4: Progress Tracking | 1 hour | None |
| Phase 5: Integration Testing | 3-4 hours | Phases 1-4 |
| Phase 6: Documentation | 1 hour | Phase 5 |

**Total Estimated Time**: 10-13 hours (target: 8-12 hours)

**Critical Path**: Phase 1 → Phase 2 → Phase 5 → Phase 6

**Parallel Work**: Phases 3 and 4 can be done independently of Phase 1

## Completion Signals

- `PLAN_CREATED`: /home/benjamin/.config/.claude/specs/052_lean_implement_workflow_fix/plans/001-lean-implement-refactor-plan.md
- All phases marked [COMPLETE]
- Integration tests pass (5/5 test cases)
- Hard barrier verification enforces delegation in production use
