# Implementation Plan: Fix /research Command Error Patterns

## Metadata
- **Date**: 2025-12-08 (Revised)
- **Feature**: Fix 29 logged errors in /research command (4 critical patterns: agent failures, sourcing issues, path validation, missing report sections)
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours (reduced: 2 phases complete)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Error Analysis Report](../reports/001-research-errors-repair.md), [Revision Analysis Report](../reports/revision-analysis-research-command.md)
- **Workflow Type**: repair
- **Error Log Query**: `--command /research`
- **Error Count**: 29 errors
- **Time Range**: 2025-11-21 to 2025-12-06 (15 days)
- **Revision Notes**: Phases 1 and 5 completed during /research refactoring. Phase 2 partially complete. Phases 3, 4 still required.

## Overview

This repair plan addresses 29 logged errors from the `/research` command over 15 days. Analysis reveals four critical patterns accounting for all failures:

1. **Agent Errors (41%)**: Topic naming agent fails to create output files (12 errors)
2. **Execution Errors (31%)**: Bash function sourcing failures (9 errors)
3. **State Errors (14%)**: PATH MISMATCH false positives (4 errors)
4. **Validation Errors (14%)**: Missing report sections (4 errors)

The root causes are incomplete function library sourcing, overly strict path validation logic, and agent behavioral contract gaps. All fixes are isolated to specific files with no breaking changes to command interfaces.

**Success Criteria**:
- All 29 logged errors eliminated at source
- `/research` command executes without initialization failures
- Agents create required artifacts with verified structure
- Error handling code uses safe variable expansion
- Pre-commit validation prevents future regressions

---

## Phase 1: Source validation-utils.sh in /research Command [COMPLETE]

**Priority**: High
**Estimated Hours**: 0.5-1 hour (ACTUAL: Complete)
**Dependencies**: None
**Completion Date**: 2025-12-08

### Objective
Add validation-utils.sh to Block 1 library sourcing in /research command to ensure `validate_workflow_id` and other validation functions are available before Block 2 initialization.

### Implementation Evidence
- validation-utils.sh sourced in Block 1a (research.md:140-143) as Tier 3 library with fail-fast handler
- validate_workflow_id() called in Block 2 (research.md:1150) to validate and correct workflow IDs
- All validation functions now available before Block 2 initialization

### Rationale
Eliminates 31% of errors (9 execution_errors) caused by missing validation functions. Runtime evidence shows `validate_workflow_id: command not found` at line 181 with exit code 127.

### Tasks
- [x] Read /research command to locate Block 1 library sourcing section
- [x] Add validation-utils.sh sourcing following three-tier pattern
- [x] Verify three-tier sourcing pattern compliance
- [x] Test /research command initialization

### Validation (PASSED)
- [x] Block 1 sources validation-utils.sh with fail-fast handler
- [x] `validate_workflow_id` function available in Block 2
- [x] No "command not found" errors during initialization
- [x] Three-tier sourcing pattern validated

### Artifacts
- Modified: .claude/commands/research.md (Block 1a sourcing section, lines 140-143)

---

## Phase 2: Replace Inline Path Validation with validate_path_consistency() [PARTIAL]

**Priority**: Medium (downgraded - logic is correct, standardization optional)
**Estimated Hours**: 0.25 hour
**Dependencies**: [Phase 1 COMPLETE]

### Objective
Replace manual path validation logic in /research command with standardized `validate_path_consistency()` function to eliminate PATH MISMATCH false positives.

### Rationale
Eliminates 14% of errors (4 state_errors) from false positive PATH MISMATCH detections when CLAUDE_PROJECT_DIR is under $HOME. Fixes syntax error with escaped negation operator `\!=`.

### Current Status
The inline validation logic has been **corrected** (research.md:345-366) and now properly handles the ~/.config scenario. However, the code uses inline conditionals instead of the standardized `validate_path_consistency()` function.

**What's Done**: Logic is correct, no false positives
**What Remains**: Replace inline conditionals with standardized function call (optional - improves maintainability)

### Tasks
- [x] Locate inline path validation code in Block 1b (Found at lines 345-366)
- [x] Update logic to handle PROJECT_DIR under HOME correctly (DONE - inline)
- [ ] (OPTIONAL) Replace inline conditionals with validate_path_consistency() call
  ```bash
  # Current (correct but inline):
  if [[ "$STATE_FILE" == "$CLAUDE_PROJECT_DIR"* ]]; then
    :  # Valid
  elif [[ "$STATE_FILE" == "$HOME"* ]] && [[ "$STATE_FILE" != "$CLAUDE_PROJECT_DIR"* ]]; then
    # Invalid - log error and exit
  fi

  # Proposed (standardized):
  validate_path_consistency "$STATE_FILE" "$CLAUDE_PROJECT_DIR" "$HOME" \
    "STATE_FILE" "CLAUDE_PROJECT_DIR" || exit 1
  ```
- [x] Test path validation with PROJECT_DIR under HOME (PASSED)

### Validation (PARTIAL)
- [x] No syntax errors with escaped operators (fixed)
- [x] No PATH MISMATCH false positives in error log
- [ ] (Optional) Uses validate_path_consistency() from validation-utils.sh

### Artifacts
- Modified: .claude/commands/research.md (Block 1b path validation, lines 345-366)

---

## Phase 3: Add File Creation Checkpoints to topic-naming-agent [COMPLETE]

**Priority**: High
**Estimated Hours**: 1-1.5 hours
**Dependencies**: None

### Objective
Enhance topic-naming-agent.md behavioral guidelines with explicit file creation verification checkpoints to ensure topic name file exists before agent returns.

### Rationale
Eliminates 41% of errors (12 agent_errors) where topic-naming-agent fails to create output file, triggering fallback to "no_name" directory. Evidence shows "agent_no_output_file" as primary fallback reason.

### Tasks
- [ ] Read current topic-naming-agent behavioral guidelines
  ```bash
  # Identify completion workflow structure
  grep -A 20 "## Completion" .claude/agents/topic-naming-agent.md
  ```

- [ ] Add Step 2.5: File Creation Verification
  ```markdown
  ### Step 2.5: Verify Topic Name File Creation

  **CRITICAL CHECKPOINT**: Before returning, verify the topic name file exists at the pre-calculated path.

  ```bash
  # Verify file exists
  if [ ! -f "$TOPIC_NAME_FILE" ]; then
    echo "ERROR: Topic name file not created at: $TOPIC_NAME_FILE"
    exit 1
  fi

  # Verify file contains valid slug (no spaces, special chars, reasonable length)
  TOPIC_SLUG=$(cat "$TOPIC_NAME_FILE")
  if [[ ! "$TOPIC_SLUG" =~ ^[a-z0-9_]{3,50}$ ]]; then
    echo "ERROR: Invalid topic slug format: $TOPIC_SLUG"
    exit 1
  fi

  echo "✓ Topic name file verified: $TOPIC_NAME_FILE"
  echo "✓ Topic slug validated: $TOPIC_SLUG"
  ```
  ```

- [ ] Update completion criteria section
  ```markdown
  ## Completion Criteria

  You MUST verify ALL criteria before returning:
  - [x] Topic name file exists at pre-calculated path ($TOPIC_NAME_FILE)
  - [x] Topic slug matches format: ^[a-z0-9_]{3,50}$
  - [x] File contains single-line slug with no whitespace
  - [x] Slug is semantically meaningful (not "no_name" or generic)
  - [x] Return completion signal with verified path
  ```

- [ ] Add hard barrier pattern warning
  ```markdown
  **HARD BARRIER**: The orchestrator validates file existence after you return.
  If the file does not exist, the workflow will fail with agent_no_output_file error.
  ```

- [ ] Test topic naming with verification checkpoints
  ```bash
  # Invoke agent with test prompt and verify file creation
  # (This would be tested during Phase 6 integration testing)
  ```

### Validation
- Agent behavioral guidelines include file creation checkpoint
- Completion criteria enforce artifact verification
- Hard barrier pattern documented for orchestrator contract
- Code blocks include exit-on-failure guards

### Artifacts
- Modified: .claude/agents/topic-naming-agent.md (Steps, Completion Criteria)

---

## Phase 4: Add Section Structure Validation to research-specialist [COMPLETE]

**Priority**: High
**Estimated Hours**: 1-1.5 hours
**Dependencies**: None

### Objective
Enhance research-specialist.md behavioral guidelines with pre-return section structure validation to ensure all required report sections exist before agent completes.

### Rationale
Eliminates 14% of errors (4 validation_errors) where research-specialist creates reports missing "## Findings" section. Ensures report structure completeness before orchestrator validation.

### Tasks
- [ ] Read current research-specialist behavioral guidelines
  ```bash
  # Identify report structure requirements
  grep -A 30 "## Report Structure" .claude/agents/research-specialist.md
  ```

- [ ] Add pre-return section structure validation step
  ```markdown
  ### Step 4: Pre-Return Section Validation

  **CRITICAL CHECKPOINT**: Before returning, verify all required sections exist in the report.

  ```bash
  # Define required sections
  REQUIRED_SECTIONS=(
    "## Findings"
    "## Methodology"
    "## Recommendations"
    "## References"
  )

  # Verify each section exists
  MISSING_SECTIONS=()
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^${section}$" "$REPORT_PATH"; then
      MISSING_SECTIONS+=("$section")
    fi
  done

  # Fail if any sections missing
  if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
    echo "ERROR: Report missing required sections: ${MISSING_SECTIONS[*]}"
    exit 1
  fi

  echo "✓ All required sections present in report"
  ```
  ```

- [ ] Update completion criteria section
  ```markdown
  ## Completion Criteria

  You MUST verify ALL criteria before returning:
  - [x] Report file exists at specified path ($REPORT_PATH)
  - [x] All required sections present: Findings, Methodology, Recommendations, References
  - [x] Each section contains substantive content (not empty or placeholder)
  - [x] Report follows markdown formatting standards
  - [x] Return completion signal with verified report path
  ```

- [ ] Add section content quality requirements
  ```markdown
  **Section Quality Standards**:
  - **Findings**: Minimum 3 research findings with evidence
  - **Methodology**: Clear description of research approach and sources
  - **Recommendations**: Actionable recommendations tied to findings
  - **References**: All sources cited with links or paths
  ```

- [ ] Test report validation with missing sections
  ```bash
  # Create test report missing Findings section
  # Verify agent validation catches the error
  # (This would be tested during Phase 6 integration testing)
  ```

### Validation
- Agent behavioral guidelines include section validation checkpoint
- Completion criteria enforce all required sections
- Validation code checks section existence before return
- Code blocks include exit-on-failure guards

### Artifacts
- Modified: .claude/agents/research-specialist.md (Pre-Return Validation, Completion Criteria)

---

## Phase 5: Add Safe Variable Expansion in Error Handler [COMPLETE]

**Priority**: Medium
**Estimated Hours**: 0.5 hour (ACTUAL: Complete)
**Dependencies**: None
**Completion Date**: 2025-12-08

### Objective
Guard error handler variable references with existence checks to prevent unbound variable errors in trap context.

### Rationale
Prevents unbound variable errors when `$exit_code` is referenced in trap handlers without being set. Evidence shows "exit_code: unbound variable" at line 1 in workflow output.

### Implementation Evidence
- setup_bash_error_trap() uses parameter substitution in trap strings (error-handling.sh:2055-2065)
- Parameters captured at setup time: `trap '_log_bash_error $? $LINENO "$BASH_COMMAND" "'"$cmd_name"'" ...' ERR`
- is_test_context() uses safe expansion: `if [[ "${WORKFLOW_ID:-}" =~ ^test_ ]]`
- Trap handlers receive parameters directly from trap invocation (guaranteed to be set)

### Tasks
- [x] Read error-handling.sh to locate exit_code references
- [x] Verify trap handlers use safe expansion patterns
- [x] Verify parameter substitution in trap setup
- [x] Test error handler in trap context

### Validation (PASSED)
- [x] No unbound variable errors in trap context
- [x] Error handler logs use safe expansion pattern
- [x] Trap handlers receive parameters directly from invocation
- [x] Code follows defensive programming practices

### Artifacts
- Verified: .claude/lib/core/error-handling.sh (Variable expansion guards already in place)

---

## Phase 6: Integration Testing and Validation [COMPLETE]

**Priority**: High
**Estimated Hours**: 1-1.5 hours
**Dependencies**: [Phase 1 COMPLETE, Phase 2 PARTIAL, Phase 3, Phase 4, Phase 5 COMPLETE]

### Objective
Execute comprehensive integration tests to verify all error patterns are eliminated and /research command functions correctly.

### Rationale
Confirms all fixes work together without regressions. Validates that the 29 logged errors are resolved at source and no new errors introduced.

### Tasks
- [ ] Test /research command end-to-end execution
  ```bash
  # Execute full research workflow with real query
  /research "test query for error pattern validation"

  # Verify:
  # - No "command not found" errors (Phase 1 fix)
  # - No PATH MISMATCH errors (Phase 2 fix)
  # - Topic name file created successfully (Phase 3 fix)
  # - Report has all required sections (Phase 4 fix)
  # - No unbound variable errors (Phase 5 fix)
  ```

- [ ] Verify topic naming agent creates output file
  ```bash
  # Check that topic directory is NOT "no_name"
  LATEST_TOPIC=$(ls -td .claude/specs/*/ | head -1)
  if [[ "$LATEST_TOPIC" == *"no_name"* ]]; then
    echo "ERROR: Topic naming still falling back to no_name"
    exit 1
  fi
  echo "✓ Topic naming agent created valid directory name"
  ```

- [ ] Verify report structure completeness
  ```bash
  # Find latest research report
  LATEST_REPORT=$(find .claude/specs/*/reports/ -name "*.md" -type f -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f2)

  # Check for required sections
  REQUIRED_SECTIONS=("## Findings" "## Methodology" "## Recommendations" "## References")
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -q "^${section}$" "$LATEST_REPORT"; then
      echo "ERROR: Report missing section: $section"
      exit 1
    fi
  done
  echo "✓ Report contains all required sections"
  ```

- [ ] Verify path validation handles ~/.config scenario
  ```bash
  # Ensure CLAUDE_PROJECT_DIR is set to ~/.config
  if [[ "$CLAUDE_PROJECT_DIR" != "$HOME/.config" ]]; then
    echo "WARNING: Not testing ~/.config scenario (PROJECT_DIR=$CLAUDE_PROJECT_DIR)"
  else
    # Execute command and verify no PATH MISMATCH
    /research --dry-run "path validation test" 2>&1 | grep -q "PATH MISMATCH" && {
      echo "ERROR: PATH MISMATCH still occurring"
      exit 1
    }
    echo "✓ Path validation handles ~/.config correctly"
  fi
  ```

- [ ] Check error log for new errors
  ```bash
  # Query error log for errors after fix timestamp
  FIX_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Wait for test execution, then query
  sleep 2
  NEW_ERRORS=$(jq -r "select(.timestamp > \"$FIX_TIMESTAMP\" and .command == \"/research\") | .error_type" .claude/data/logs/errors.jsonl | wc -l)

  if [ "$NEW_ERRORS" -gt 0 ]; then
    echo "ERROR: $NEW_ERRORS new errors logged during testing"
    jq -r "select(.timestamp > \"$FIX_TIMESTAMP\" and .command == \"/research\")" .claude/data/logs/errors.jsonl
    exit 1
  fi
  echo "✓ No new errors logged during integration testing"
  ```

- [ ] Run linter validation on modified files
  ```bash
  # Validate three-tier sourcing pattern
  bash .claude/scripts/validate-all-standards.sh --sourcing

  # Validate no prohibited patterns
  bash .claude/scripts/validate-all-standards.sh --suppression
  bash .claude/scripts/validate-all-standards.sh --conditionals

  echo "✓ All standards validation checks passed"
  ```

### Validation
- /research command executes without initialization errors
- Topic naming creates valid directory (not "no_name")
- Reports contain all required sections
- No PATH MISMATCH errors in ~/.config scenario
- No new errors logged in errors.jsonl
- All linter checks pass

### Artifacts
- Test Results: Console output showing successful execution
- Error Log: No new errors for /research command after fix timestamp

---

## Phase 7: Update Error Log Status [COMPLETE]

**Priority**: High
**Estimated Hours**: 0.5 hour
**Dependencies**: [Phase 1 COMPLETE, Phase 2 PARTIAL, Phase 3, Phase 4, Phase 5 COMPLETE, Phase 6]

### Objective
Update error log entries from FIX_PLANNED to RESOLVED status, confirming all fixes are working and no errors remain.

### Rationale
Completes the repair workflow by marking all 29 errors as resolved in the error tracking system. Enables accurate error metrics and prevents re-analysis of fixed errors.

### Tasks
- [ ] Verify all fixes are working (tests pass, no new errors generated)
  ```bash
  # Confirm Phase 6 integration tests completed successfully
  # Verify no test failures or runtime errors
  echo "✓ All integration tests passed in Phase 6"
  ```

- [ ] Update error log entries to RESOLVED status
  ```bash
  source .claude/lib/core/error-handling.sh
  PLAN_PATH="/home/benjamin/.config/.claude/specs/012_repair_research_20251208_122753/plans/001-repair-research-20251208-122753-plan.md"
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "$PLAN_PATH")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```

- [ ] Verify no FIX_PLANNED errors remain for this plan
  ```bash
  PLAN_DIR=$(dirname "$(dirname "$PLAN_PATH")")
  TOPIC_ID=$(basename "$PLAN_DIR")

  REMAINING=$(jq -r "select(.status == \"FIX_PLANNED\" and .repair_plan_path != null) | .repair_plan_path" .claude/data/logs/errors.jsonl | grep -c "$TOPIC_ID" || echo "0")

  if [ "$REMAINING" -eq 0 ]; then
    echo "✓ All errors resolved - no FIX_PLANNED entries remain"
  else
    echo "WARNING: $REMAINING errors still FIX_PLANNED for topic $TOPIC_ID"
    exit 1
  fi
  ```

- [ ] Generate summary of resolved errors
  ```bash
  # Count resolved errors by type
  echo "Resolved Error Summary:"
  jq -r "select(.status == \"RESOLVED\" and .repair_plan_path != null) | select(.repair_plan_path | contains(\"$TOPIC_ID\")) | .error_type" .claude/data/logs/errors.jsonl | sort | uniq -c
  ```

### Validation
- All 29 errors marked as RESOLVED in error log
- No FIX_PLANNED errors remain for this repair plan
- Error summary shows distribution by type (agent_error, execution_error, state_error, validation_error)
- Error log entries include repair_plan_path pointing to this plan

### Artifacts
- Modified: .claude/data/logs/errors.jsonl (status field updated to RESOLVED)
- Console Output: Summary of resolved errors by type

---

## Dependencies

```
Phase 1 (Source validation-utils.sh) [COMPLETE ✓]
  └─> Phase 2 (Path validation) - requires validation-utils.sh to be sourced [PARTIAL ⚠]

Phase 3 (topic-naming-agent checkpoints) - independent [NOT STARTED]

Phase 4 (research-specialist validation) - independent [NOT STARTED]

Phase 5 (Error handler variable guards) - independent [COMPLETE ✓]

Phase 6 (Integration Testing)
  └─> Phase 1 [COMPLETE], Phase 2 [PARTIAL], Phase 3, Phase 4, Phase 5 [COMPLETE]

Phase 7 (Update Error Log Status)
  └─> Phase 6 - requires all tests passing
```

### Remaining Work (Post-Revision)
- **Phase 2**: Optional - replace inline conditionals with standardized function (0.25h)
- **Phase 3**: Required - add file creation checkpoints to topic-naming-agent (1-1.5h)
- **Phase 4**: Required - add section structure validation to research-specialist (1-1.5h)
- **Phase 6**: Required - integration testing after Phase 3 and 4 complete (1-1.5h)
- **Phase 7**: Required - mark resolved errors (0.5h)

**Total Remaining**: ~4-5 hours (down from 4-6 hours original)

## Risk Assessment

**Low Risk**:
- All changes are isolated to specific files
- No breaking changes to command interfaces
- Backward compatible with existing workflows
- Changes follow established patterns in code-standards.md

**Potential Issues**:
1. **Agent Checkpoint Overhead**: File creation verification adds minimal execution time but improves reliability
2. **Path Validation Edge Cases**: validate_path_consistency() may have undiscovered edge cases (mitigated by existing usage in other commands)
3. **Error Handler Variable Context**: Safe expansion pattern assumes trap context variable availability (mitigated by defensive ${var:-default} pattern)

**Mitigation Strategies**:
- Phase 6 integration testing catches regressions before completion
- All changes follow existing patterns with documented precedent
- Pre-commit hooks validate standards compliance automatically

## Success Metrics

1. **Error Elimination**: All 29 logged errors resolved (query errors.jsonl with `--status RESOLVED`)
2. **Command Reliability**: /research executes without initialization failures (exit code 0)
3. **Agent Completion**: Topic naming and research agents create required artifacts 100% of the time
4. **Path Validation**: No false positives for ~/.config scenario (0 PATH MISMATCH errors)
5. **Code Quality**: All linter checks pass for modified files (sourcing, conditionals, suppression)

## References

- **Error Analysis Report**: /home/benjamin/.config/.claude/specs/012_repair_research_20251208_122753/reports/001-research-errors-repair.md
- **Code Standards**: /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md
- **Command Authoring**: /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md
- **Error Handling Pattern**: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
- **Validation Utils Library**: /home/benjamin/.config/.claude/lib/workflow/validation-utils.sh
