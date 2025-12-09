# /implement Command Plan Completion Fix Implementation Plan

## Metadata

- **Date**: 2025-12-08
- **Feature**: Fix plan completion workflow in /implement command to update metadata status and success criteria
- **Status**: [COMPLETE]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/implement Command Plan Completion Fix Analysis](../reports/001-implement-plan-completion-fix-analysis.md)

## Success Criteria

- [x] Plan metadata Status field automatically updated to [COMPLETE] when all phases done
- [x] Success criteria checkboxes marked [x] after workflow completion
- [x] Block 1c properly parses agent return signal instead of using hardcoded values
- [x] Block 1d validates metadata consistency and auto-repairs discrepancies
- [x] Console summary derived from actual plan file state (not hardcoded)
- [x] All changes maintain backward compatibility with existing plans
- [x] Pre-commit validation passes for all modified files
- [x] Test coverage for new checkbox-utils.sh functions (mark_success_criteria_complete, verify_success_criteria_complete)

## Overview

The /implement command currently fails to properly complete plans after execution. Four distinct issues prevent proper plan closure: (1) metadata Status field remains [IN PROGRESS] despite complete phases, (2) success criteria checkboxes never get marked complete, (3) verification block uses hardcoded values instead of parsing agent output, and (4) console summary contradicts plan file state. This plan implements automated completion logic, agent output parsing, metadata validation, and plan-derived reporting to ensure consistent and accurate plan closure.

## Technical Context

### Current Behavior
- Block 1d has `update_plan_status()` logic but Block 2 (completion block) doesn't call it
- implementer-coordinator agent marks phase headings but ignores success criteria section
- Block 1c verification hardcodes `WORK_REMAINING` and other agent fields
- Block 2 console summary uses hardcoded phase counts instead of reading plan file

### Root Causes
1. **Missing status update in Block 2**: Completion block transitions state machine but doesn't update plan metadata
2. **No success criteria logic**: checkbox-utils.sh lacks functions for success criteria updates
3. **Bypassed agent parsing**: Block 1c uses pre-set variables instead of parsing Task output
4. **Hardcoded console summary**: Block 2 doesn't derive completion state from plan file

### Affected Files
- `.claude/commands/implement.md` (Blocks 1c, 1d, 2)
- `.claude/lib/plan/checkbox-utils.sh` (add success criteria functions)
- `.claude/agents/implementer-coordinator.md` (document return signal protocol)

## Phase 1: Add Success Criteria Functions to checkbox-utils.sh [COMPLETE]

**Objective**: Implement utility functions for marking and verifying success criteria completion.

**Tasks**:
- [x] Add `mark_success_criteria_complete()` function with AWK-based checkbox replacement
  - Extract Success Criteria section using `/^## Success Criteria/` pattern
  - Replace `- [ ]` with `- [x]` for all criteria
  - Use temp file pattern for atomic updates
- [x] Add `verify_success_criteria_complete()` function with completion check
  - Count unchecked criteria in Success Criteria section
  - Return 0 if all complete, 1 if incomplete
- [x] Export functions for use in commands
- [x] Add unit tests in `.claude/tests/plan/test-checkbox-utils.sh`
  - Test marking success criteria complete
  - Test verification with all complete
  - Test verification with some incomplete
  - Test handling of missing Success Criteria section

**Success Criteria**:
- [x] `mark_success_criteria_complete()` marks all criteria [x] without affecting phases
- [x] `verify_success_criteria_complete()` correctly detects completion state
- [x] Functions handle missing Success Criteria section gracefully
- [x] All unit tests pass

**Estimated Time**: 2-3 hours

## Phase 2: Update Block 1d with Success Criteria Validation [COMPLETE]

**Objective**: Add success criteria validation and update logic after phase marker recovery.

**Tasks**:
- [x] Add success criteria validation section after phase marker recovery (after line 1275)
- [x] Check if all phases complete using `check_all_phases_complete()`
- [x] Invoke `mark_success_criteria_complete()` if phases complete
- [x] Add checkpoint reporting for success criteria status
- [x] Handle graceful degradation if functions unavailable
- [x] Add error logging for validation failures

**Implementation Details**:
```bash
# === SUCCESS CRITERIA VALIDATION ===
echo ""
echo "=== Success Criteria Validation ==="
echo ""

# Check if all phases complete
if type check_all_phases_complete &>/dev/null && check_all_phases_complete "$PLAN_FILE"; then
  echo "All phases complete, validating success criteria..."

  # Attempt to mark success criteria complete
  if type mark_success_criteria_complete &>/dev/null; then
    mark_success_criteria_complete "$PLAN_FILE" 2>/dev/null && \
      echo "✓ Success criteria marked complete" || \
      echo "⚠ Could not update success criteria (non-fatal)"
  else
    echo "⚠ Success criteria update function not available"
  fi
else
  echo "Phases incomplete, skipping success criteria validation"
fi

echo ""
```

**Success Criteria**:
- [ ] Success criteria marked complete when all phases done
- [ ] Validation skipped when phases incomplete
- [ ] Non-fatal errors don't break workflow
- [ ] Checkpoint reporting shows validation status

**Estimated Time**: 1-2 hours

## Phase 3: Add Plan Consistency Validation to Block 1d [COMPLETE]

**Objective**: Validate metadata status matches phase completion and auto-repair inconsistencies.

**Tasks**:
- [x] Add consistency validation section after success criteria validation
- [x] Compare metadata Status field with phase completion state
- [x] Auto-repair metadata if all phases complete but metadata shows [IN PROGRESS]
- [x] Log warning if metadata shows [COMPLETE] but phases incomplete (don't auto-repair)
- [x] Add error logging for detected inconsistencies
- [x] Test with various inconsistency scenarios

**Implementation Details**:
```bash
# === PLAN CONSISTENCY VALIDATION ===
echo ""
echo "=== Plan Consistency Validation ==="
echo ""

# Validate metadata status matches phase completion
if type check_all_phases_complete &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    # All phases complete, metadata should be COMPLETE
    METADATA_STATUS=$(grep "^- \*\*Status\*\*:" "$PLAN_FILE" | grep -oE "\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]" || echo "[UNKNOWN]")

    if [ "$METADATA_STATUS" != "[COMPLETE]" ]; then
      echo "⚠ Inconsistency detected: All phases COMPLETE but metadata shows $METADATA_STATUS"

      # Auto-repair: Update metadata to match phase state
      if type update_plan_status &>/dev/null; then
        echo "Auto-repairing: Updating metadata status to COMPLETE..."
        update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
          echo "✓ Metadata status updated to [COMPLETE]" || \
          echo "✗ Failed to update metadata status"
      fi
    else
      echo "✓ Metadata status consistent with phase completion"
    fi
  else
    # Some phases incomplete
    METADATA_STATUS=$(grep "^- \*\*Status\*\*:" "$PLAN_FILE" | grep -oE "\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]" || echo "[UNKNOWN]")

    if [ "$METADATA_STATUS" = "[COMPLETE]" ]; then
      echo "⚠ Inconsistency detected: Phases incomplete but metadata shows COMPLETE"
      echo "This indicates manual metadata modification or state corruption"

      # Log error but don't auto-repair
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Plan metadata shows COMPLETE but phases remain incomplete" \
        "bash_block_1d_consistency" \
        "$(jq -n --arg status "$METADATA_STATUS" --argjson phases "$PHASES_WITH_MARKER" --argjson total "$TOTAL_PHASES" \
           '{metadata_status: $status, complete_phases: $phases, total_phases: $total}')"
    else
      echo "✓ Metadata status consistent with incomplete phases"
    fi
  fi
else
  echo "⚠ Consistency validation skipped (check_all_phases_complete function unavailable)"
fi

echo ""
```

**Success Criteria**:
- [ ] Auto-repair updates metadata when phases complete
- [ ] Warning logged when metadata [COMPLETE] but phases incomplete
- [ ] Validation works with both consistent and inconsistent plans
- [ ] Error logging captures inconsistency details

**Estimated Time**: 2-3 hours

## Phase 4: Implement Agent Output Parsing in Block 1c [COMPLETE]

**Objective**: Replace hardcoded verification values with proper parsing of implementer-coordinator return signal.

**Tasks**:
- [x] Design agent output capture mechanism (temp file or structured output parsing)
- [x] Replace hardcoded variable initialization (lines 792-803) with parsing logic
- [x] Parse all required fields: work_remaining, context_exhausted, summary_path, context_usage_percent, checkpoint_path, requires_continuation, stuck_detected
- [x] Add defensive validation for missing or malformed fields
- [x] Log parsing errors using `log_command_error()`
- [x] Implement fallback to legacy detection if parsing fails
- [x] Test with mock agent output containing all fields
- [x] Test with missing fields (should emit warnings and use defaults)

**Implementation Details**:
```bash
# === PARSE AGENT RETURN SIGNAL ===
# Assuming agent output captured to $AGENT_OUTPUT_FILE

if [ -f "$AGENT_OUTPUT_FILE" ]; then
  # Parse structured return signal
  WORK_REMAINING=$(grep "^work_remaining:" "$AGENT_OUTPUT_FILE" | sed 's/work_remaining:[[:space:]]*//' | head -1 || echo "")
  CONTEXT_EXHAUSTED=$(grep "^context_exhausted:" "$AGENT_OUTPUT_FILE" | sed 's/context_exhausted:[[:space:]]*//' | head -1 || echo "false")
  SUMMARY_PATH=$(grep "^summary_path:" "$AGENT_OUTPUT_FILE" | sed 's/summary_path:[[:space:]]*//' | head -1 || echo "")
  CONTEXT_USAGE_PERCENT=$(grep "^context_usage_percent:" "$AGENT_OUTPUT_FILE" | sed 's/context_usage_percent:[[:space:]]*//' | sed 's/%//' | head -1 || echo "0")
  CHECKPOINT_PATH=$(grep "^checkpoint_path:" "$AGENT_OUTPUT_FILE" | sed 's/checkpoint_path:[[:space:]]*//' | head -1 || echo "")
  REQUIRES_CONTINUATION=$(grep "^requires_continuation:" "$AGENT_OUTPUT_FILE" | sed 's/requires_continuation:[[:space:]]*//' | head -1 || echo "false")
  STUCK_DETECTED=$(grep "^stuck_detected:" "$AGENT_OUTPUT_FILE" | sed 's/stuck_detected:[[:space:]]*//' | head -1 || echo "false")

  # Defensive: Log if any field missing
  [ -z "$WORK_REMAINING" ] && echo "WARNING: Agent output missing work_remaining field" >&2
  [ -z "$SUMMARY_PATH" ] && echo "WARNING: Agent output missing summary_path field" >&2
else
  echo "ERROR: Agent output file not found: $AGENT_OUTPUT_FILE" >&2

  # Fallback to legacy detection
  echo "Falling back to legacy summary detection..." >&2
  WORK_REMAINING=""
  REQUIRES_CONTINUATION="false"
fi

# === VALIDATE AGENT RETURN SIGNAL ===
PARSING_ERRORS=0

if [ -z "$SUMMARY_PATH" ] || [ ! -f "$SUMMARY_PATH" ]; then
  echo "ERROR: Agent return missing valid summary_path" >&2
  ((PARSING_ERRORS++))
fi

if ! [[ "$CONTEXT_USAGE_PERCENT" =~ ^[0-9]+$ ]]; then
  echo "WARNING: Agent return context_usage_percent invalid format: '$CONTEXT_USAGE_PERCENT'" >&2
  CONTEXT_USAGE_PERCENT=0
fi

if [ "$REQUIRES_CONTINUATION" != "true" ] && [ "$REQUIRES_CONTINUATION" != "false" ]; then
  echo "WARNING: Agent return requires_continuation invalid format: '$REQUIRES_CONTINUATION'" >&2
  REQUIRES_CONTINUATION="false"
fi

if [ $PARSING_ERRORS -gt 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "implementer-coordinator return signal parsing failed" \
    "bash_block_1c" \
    "$(jq -n --argjson errors "$PARSING_ERRORS" '{parsing_errors: $errors}')"
fi
```

**Success Criteria**:
- [ ] All agent return fields parsed from output
- [ ] Warnings emitted for missing fields
- [ ] Invalid field formats handled with safe defaults
- [ ] Parsing errors logged to error log
- [ ] Fallback mechanism works when agent output missing

**Estimated Time**: 3-4 hours

## Phase 5: Enhance Block 2 Completion Logic [COMPLETE]

**Objective**: Add metadata status update and plan-derived console summary to completion block.

**Tasks**:
- [x] Add `update_plan_status()` call after state transition to COMPLETE (after line 1430)
- [x] Source checkbox-utils.sh in Block 2 (add to Tier 3 sourcing)
- [x] Add defensive check to only update if all phases complete
- [x] Derive console summary from actual plan file state
  - Count total phases and complete phases from plan file
  - Extract phase names and statuses dynamically
  - Build summary text based on actual completion
- [x] Replace hardcoded phase counts with plan-derived values
- [x] Add checkpoint reporting for status update
- [x] Test with full completion scenario
- [x] Test with partial completion scenario (context exhaustion)

**Implementation Details**:
```bash
# === UPDATE METADATA STATUS ===
# Source checkbox-utils.sh if not already available
if ! type update_plan_status &>/dev/null; then
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
fi

# Update plan metadata status to COMPLETE if all phases done
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null && \
      echo "Plan metadata status updated to [COMPLETE]"
  fi
fi

# === CONSOLE SUMMARY (PLAN-DERIVED) ===
# Determine actual completion state from plan file
TOTAL_PHASES=$(grep -E -c "^##+ Phase [0-9]" "$PLAN_FILE" 2>/dev/null || echo "0")
COMPLETE_PHASES=$(grep -E -c "^##+ Phase [0-9].*\[COMPLETE\]" "$PLAN_FILE" 2>/dev/null || echo "0")

# Build summary text based on actual completion
if [ "$COMPLETE_PHASES" -eq "$TOTAL_PHASES" ]; then
  SUMMARY_TEXT="Completed implementation of all $TOTAL_PHASES phases. Tests are written but NOT executed. Run /test to execute test suite."
  COMPLETION_STATUS="complete"
else
  SUMMARY_TEXT="Completed implementation of $COMPLETE_PHASES/$TOTAL_PHASES phases. Remaining work: ${WORK_REMAINING:-unknown}. Run /test to execute tests for completed phases."
  COMPLETION_STATUS="partial"
fi

# Build phases section with actual markers from plan
PHASES=""
for phase_num in $(seq 1 "$TOTAL_PHASES"); do
  PHASE_HEADING=$(grep -E "^##+ Phase ${phase_num}:" "$PLAN_FILE" | head -1)
  PHASE_STATUS=$(echo "$PHASE_HEADING" | grep -oE "\[(NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)\]" || echo "[UNKNOWN]")
  PHASE_NAME=$(echo "$PHASE_HEADING" | sed -E 's/^##+ Phase [0-9]+: ([^[]+).*/\1/' | sed 's/[[:space:]]*$//')

  PHASES="${PHASES}  • Phase $phase_num: $PHASE_NAME $PHASE_STATUS
"
done
```

**Success Criteria**:
- [ ] Metadata status updated to [COMPLETE] when all phases done
- [ ] Console summary shows actual phase completion counts
- [ ] Phase list derived from plan file headings
- [ ] Summary distinguishes full vs partial completion
- [ ] Checkpoint reporting confirms status update

**Estimated Time**: 2-3 hours

## Phase 6: Testing and Validation [COMPLETE]

**Objective**: Comprehensive testing of all completion workflow improvements.

**Tasks**:
- [x] Create test plan file with 4 phases and 8 success criteria
- [x] Test full completion workflow (all phases)
  - Verify metadata updated to [COMPLETE]
  - Verify all success criteria marked [x]
  - Verify console summary matches plan state
- [x] Test partial completion workflow (context exhaustion)
  - Verify metadata remains [IN PROGRESS]
  - Verify success criteria remain unchecked
  - Verify console summary shows X/Y phases
- [x] Test consistency validation auto-repair
  - Manually create inconsistent plan (phases [COMPLETE], metadata [IN PROGRESS])
  - Run Block 1d and verify auto-repair
- [x] Test agent output parsing with mock data
  - Create mock agent output file with all fields
  - Verify Block 1c parses correctly
  - Test with missing fields
- [x] Run pre-commit validation on all modified files
- [x] Verify backward compatibility with existing plans

**Success Criteria**:
- [x] All test scenarios pass
- [x] Pre-commit validation passes
- [x] No regressions in existing workflows
- [x] Error logging captures all failure modes

**Estimated Time**: 2-3 hours

## Dependencies

**Phase Dependencies**:
- Phase 2 depends on Phase 1 (requires success criteria functions)
- Phase 3 is independent (can run in parallel with Phase 2)
- Phase 4 is independent (can run in parallel with Phases 2-3)
- Phase 5 depends on Phase 1 (needs checkbox-utils.sh functions)
- Phase 6 depends on all previous phases (integration testing)

**Execution Order**:
1. Wave 1: Phase 1 (foundation - success criteria functions)
2. Wave 2: Phases 2, 3, 4 (parallel - independent improvements)
3. Wave 3: Phase 5 (requires Phase 1 completion)
4. Wave 4: Phase 6 (integration testing)

## Risk Assessment

**High Risk**:
- Agent output parsing mechanism may require changes to Task tool invocation pattern
- Existing plans with legacy formats may need migration logic

**Medium Risk**:
- Consistency validation auto-repair could overwrite intentional manual edits
- Success criteria function may not handle all plan format variations

**Low Risk**:
- Checkpoint reporting changes are informational only
- Console summary changes are visual-only improvements

**Mitigation**:
- Test with diverse plan formats (h2 vs h3 headings, inline vs expanded)
- Add defensive checks for missing Success Criteria section
- Log all auto-repairs for audit trail
- Implement dry-run testing before production use

## Next Steps After Implementation

1. Update `.claude/docs/guides/commands/implement-command-guide.md` with completion workflow details
2. Add completion workflow diagram to documentation
3. Update `.claude/docs/reference/standards/plan-metadata-standard.md` if metadata behavior changes
4. Run `/todo` to update TODO.md with implementation status
5. Create follow-up issue for agent return signal standardization across all coordinators
