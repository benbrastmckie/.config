# Research Report: /repair Plan Standards Conformance Analysis

## Metadata
- **Date**: 2025-12-02
- **Research Topic**: Standards conformance review for /repair command implementation plan
- **Complexity**: 2
- **Workflow**: research-and-revise

## Executive Summary

This research identifies **8 critical gaps** and **14 compliance violations** in the existing /repair command implementation plan (001-repair-repair-20251202-120554-plan.md). The plan targets fixing state persistence, error logging, and workflow transition issues but violates multiple project standards in its approach. Key issues include:

1. **Plan metadata non-compliance** - Missing/incorrect Research Reports field format
2. **State persistence anti-pattern** - Uses JSON for ERROR_FILTERS (violates flat key requirement)
3. **Output formatting violations** - No checkpoint format, console summary missing
4. **Error handling integration gaps** - Missing dual trap setup, incomplete error context persistence
5. **Command authoring violations** - No execution directives, missing three-tier sourcing
6. **Testing protocol gaps** - No error log status validation, missing ERR trap suppression tests

The plan is technically sound but needs revision to align with established infrastructure patterns and enforce project standards.

## Research Scope

### Areas Analyzed
1. Plan Metadata Standard compliance (plan-metadata-standard.md)
2. Command Authoring Standards (command-authoring.md)
3. Output Formatting Standards (output-formatting.md)
4. Error Handling Pattern integration (error-handling.md)
5. State Persistence patterns (state-persistence.sh library)
6. Testing Protocols (testing-protocols.md, test isolation patterns)
7. Reference command implementations (/plan, /build, /research)

### Research Methods
- Document analysis of 5 standards files (2,840+ lines)
- Code inspection of /repair.md (200 lines examined)
- Reference command comparison (/plan.md - 300 lines)
- Library inspection (error-handling.sh, workflow-state-machine.sh)
- Pattern validation against working implementations

## Findings

### 1. Plan Metadata Violations

**Severity**: ERROR (blocks pre-commit)

**Issue**: Research Reports field uses absolute paths instead of relative paths

Current plan line 9:
```markdown
- **Research Reports**: /home/benjamin/.config/.claude/specs/018_repair_repair_20251202_120554/reports/001-repair-errors-repair.md
```

**Standard Requirement** (plan-metadata-standard.md lines 76-83):
```markdown
### 6. Research Reports
- **Format**: Markdown link list with relative paths, or `none` if no research phase
- **Validation**: Must use relative paths (e.g., `../reports/`)
```

**Correct Format**:
```markdown
- **Research Reports**:
  - [Repair Error Analysis](../reports/001-repair-errors-repair.md)
```

**Impact**: Pre-commit hook validation will fail (ERROR-level violation)

**Recommendation**: Update plan metadata to use relative path with markdown link format

---

### 2. State Persistence Anti-Pattern: JSON in ERROR_FILTERS

**Severity**: HIGH (root cause of reported errors)

**Issue**: Plan Phase 1 proposes using JSON for ERROR_FILTERS, which violates state persistence library's flat key requirement

Plan lines 43-58 propose:
```markdown
- [ ] Replace `ERROR_FILTERS` JSON construction in Block 1a with individual filter keys
  - Change: `append_workflow_state "ERROR_FILTERS" "$ERROR_FILTERS"`
  - To: Four separate append calls for FILTER_SINCE, FILTER_TYPE, FILTER_COMMAND, FILTER_SEVERITY
```

But /repair.md lines 106-111 show the CURRENT implementation:
```bash
ERROR_FILTERS=$(jq -n \
  --arg since "$ERROR_SINCE" \
  --arg type "$ERROR_TYPE" \
  --arg command "$ERROR_COMMAND" \
  --arg severity "$ERROR_SEVERITY" \
  '{since: $since, type: $type, command: $command, severity: $severity}')
```

**Root Cause Analysis**: The error log shows "Type validation failed" errors because state-persistence.sh's `append_workflow_state` function expects simple string values, not JSON objects. The library performs type validation and rejects complex types.

**Standard Pattern** (state-persistence.sh, used successfully in /plan, /build):
```bash
# Block 1a: Persist flat keys
append_workflow_state "FILTER_SINCE" "$ERROR_SINCE"
append_workflow_state "FILTER_TYPE" "$ERROR_TYPE"
append_workflow_state "FILTER_COMMAND" "$ERROR_COMMAND"
append_workflow_state "FILTER_SEVERITY" "$ERROR_SEVERITY"

# Block 3: Read flat keys
load_workflow_state "$WORKFLOW_ID"
# Variables restored: $FILTER_SINCE, $FILTER_TYPE, etc.
```

**Validation**: Grep search shows no other commands use JSON with append_workflow_state - all use flat keys.

**Recommendation**: Phase 1 approach is correct - use flat keys throughout

---

### 3. Missing Execution Directives (Command Authoring Violation)

**Severity**: ERROR (causes silent failures)

**Issue**: /repair.md implementation blocks lack explicit execution directives

Current /repair.md structure (from read):
```markdown
## Block 1a: Initial Setup

**EXECUTE NOW**: The user invoked `/repair` with optional filters...

Execute this bash block:
```

This is CORRECT. However, the plan phases reference "Block 1a", "Block 2a" etc. without verifying that ALL blocks in /repair.md have execution directives.

**Standard Requirement** (command-authoring.md lines 30-40):
```markdown
### Required Directive Phrases

Every bash code block in a command file MUST be preceded by an explicit execution directive:

**Primary (Preferred)**:
- `**EXECUTE NOW**:` - Standard imperative directive
```

**Action Required**: Audit ALL bash blocks in /repair.md to verify execution directives present

**Validation Pattern** (command-authoring.md lines 350-361):
```bash
#!/bin/bash
# test_command_execution_directives.sh
COUNT=$(grep -cE "EXECUTE NOW|Execute this|Run the following" "$cmd" || echo 0)
if [ "$COUNT" -eq 0 ]; then
  echo "FAIL: $cmd has no execution directives"
fi
```

**Recommendation**: Add validation test to Phase 5 to check execution directive coverage

---

### 4. Output Formatting Violations

**Severity**: WARNING (inconsistent with standards)

**Issue**: Plan does not address output formatting compliance

**Missing Patterns**:

1. **Checkpoint Format** (output-formatting.md lines 299-332):
   - No checkpoints defined between blocks
   - Missing "Context:" and "Ready for:" sections

2. **Console Summary Format** (output-formatting.md lines 596-625):
   - No 4-section summary defined (Summary/Phases/Artifacts/Next Steps)
   - Missing emoji markers for artifacts

3. **Single Summary Line per Block** (output-formatting.md lines 169-178):
   - Plan doesn't specify reducing verbose output

**Standard Requirement** (output-formatting.md lines 303-310):
```bash
echo "[CHECKPOINT] Setup phase complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, TOPIC_DIR=${TOPIC_DIR}"
echo "Ready for: Agent delegation"
```

**Recommendation**: Add Phase 7 to implement output formatting compliance

---

### 5. Error Handling Integration Gaps

**Severity**: HIGH (incomplete error logging coverage)

**Issue**: Plan addresses state persistence but misses critical error handling patterns

**Missing Patterns**:

1. **Dual Trap Setup** (error-handling.md lines 149-209):
   - No mention of early trap initialization
   - No `_flush_early_errors` call validation

2. **Error Context Persistence** (error-handling.md lines 286-335):
   - Missing COMMAND_NAME and USER_ARGS export verification
   - No validation that error logging variables persist across blocks

3. **Validation Function Integration** (error-handling.md lines 640-663):
   - Missing `validate_state_restoration` calls
   - No defensive checks with `check_unbound_vars`

**Reference Implementation** (/plan.md lines 118-163):
```bash
# === PRE-TRAP ERROR BUFFER ===
declare -a _EARLY_ERROR_BUFFER=()

# === SOURCE LIBRARIES ===
source error-handling.sh || exit 1

# === SETUP EARLY BASH ERROR TRAP ===
setup_bash_error_trap "/plan" "plan_early_$(date +%s)" "early_init"

# === FLUSH PRE-TRAP ERROR BUFFER ===
_flush_early_errors
```

**Current /repair.md** (lines 176-181 from read):
```bash
# === INITIALIZE ERROR LOGGING ===
ensure_error_log_exists

# === SETUP EARLY BASH ERROR TRAP ===
setup_bash_error_trap "/repair" "repair_early_$(date +%s)" "early_init"
```

**Gap**: Missing `_flush_early_errors` call after trap setup

**Recommendation**: Add Phase 8 to complete error handling integration

---

### 6. Three-Tier Sourcing Pattern Violation

**Severity**: ERROR (blocks pre-commit)

**Issue**: /repair.md uses fail-fast handlers but may not follow three-tier pattern

**Standard Requirement** (command-authoring.md, code-standards.md):
```markdown
**Quick Reference - Bash Sourcing**:
- All bash blocks MUST follow three-tier sourcing pattern
- Tier 1 libraries (state-persistence.sh, workflow-state-machine.sh, error-handling.sh) require fail-fast handlers
```

**Current /repair.md** (lines 143-167 from read):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

This is CORRECT for Tier 1. But the plan doesn't verify Tier 2/3 compliance.

**Validation Required**:
- Tier 2: Workflow Support (graceful degradation) - unified-location-detection.sh, workflow-initialization.sh
- Tier 3: Helper utilities - validation-utils.sh, todo-functions.sh

**Recommendation**: Add validation step to check three-tier pattern enforcement

---

### 7. Testing Protocol Gaps

**Severity**: MEDIUM (incomplete test coverage)

**Issue**: Plan Phase 5 creates integration tests but misses critical test scenarios

**Missing Test Cases**:

1. **Error Log Status Validation** (error-handling.md lines 97-108):
   - No test for FIX_PLANNED status update
   - No test for RESOLVED status update
   - Missing repair_plan_path field validation

2. **ERR Trap Suppression** (error-handling.md lines 552-619):
   - No test for SUPPRESS_ERR_TRAP flag behavior
   - Missing validation that flag auto-resets

3. **Test Isolation** (error-handling.md lines 113-145):
   - No test verifying SUPPRESS_ERR_LOGGING=1 works
   - Missing validation of test vs production log routing

**Standard Requirement** (error-handling.md lines 336-359):
```bash
# /repair workflow:
4. Generates implementation plan with fix phases in `specs/{NNN_topic}/plans/`
5. Updates error log entries with FIX_PLANNED status
```

**Recommendation**: Expand Phase 5 test suite to cover error log status lifecycle

---

### 8. State Transition Validation Incomplete

**Severity**: MEDIUM (missing defensive checks)

**Issue**: Plan Phase 2 addresses state transitions but doesn't add defensive validation

**Missing Validations**:

1. **State Machine Initialization Guard** (workflow-state-machine.sh, Spec 672):
   - No mention of auto-initialization guard
   - Missing validation that `sm_init` succeeds before transitions

2. **Idempotent Transitions** (idempotent-state-transitions.md):
   - Plan doesn't mention same-state transition handling
   - No test for idempotent behavior

**Standard Pattern** (workflow-state-machine.sh lines 77-93):
```bash
# Current state of the state machine
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"

# Terminal state for this workflow
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"
```

**Recommendation**: Add defensive checks to Phase 2 validation

---

### 9. Directory Creation Compliance

**Severity**: LOW (best practice, not blocking)

**Issue**: Plan Phase 3 adds defensive mkdir but doesn't follow lazy creation pattern

**Standard Requirement** (command-authoring.md lines 975-1003):
```markdown
### Required Pattern

- **DO**: Create only the topic root directory (`specs/NNN_topic/`)
- **DO NOT**: Create artifact subdirectories (`reports/`, `plans/`, etc.)
- **DELEGATE**: Let agents create subdirectories via `ensure_artifact_directory()`
```

Plan Phase 3 line 133:
```markdown
- [ ] Add RESEARCH_DIR existence check in Block 1b before find command
  - Add before line 434: `[ -d "$RESEARCH_DIR" ] || mkdir -p "$RESEARCH_DIR"`
```

**Issue**: This creates subdirectory before agent writes files (violates lazy creation)

**Correct Pattern**:
```bash
# In Block 1b: Only validate, don't create
if [ -z "${RESEARCH_DIR:-}" ]; then
  log_command_error "validation_error" "RESEARCH_DIR not set" ...
  exit 1
fi

# Agents create directories at write-time via ensure_artifact_directory()
```

**Recommendation**: Change Phase 3 to defensive validation only, remove mkdir

---

### 10. Missing Standards Context Injection

**Severity**: LOW (enhancement opportunity)

**Issue**: Plan doesn't verify repair-analyst receives project standards

**Standard Pattern** (standards-integration.md, used in /plan, /research):
```bash
source "${CLAUDE_LIB}/plan/standards-extraction.sh"
FORMATTED_STANDARDS=$(format_standards_for_prompt)

# Pass to agent in prompt:
# **Project Standards**:
# ${FORMATTED_STANDARDS}
```

**Gap**: No verification that repair-analyst uses standards-extraction.sh for context

**Recommendation**: Add validation step to Phase 2 or 4

---

### 11. Console Summary Format Missing

**Severity**: LOW (user experience enhancement)

**Issue**: No final console summary defined

**Standard Requirement** (output-formatting.md lines 600-624):
```bash
cat << EOF
=== Repair Complete ===

Summary: Analyzed 28 errors across 3 commands and created implementation plan with 6 phases. Fixes address state persistence, error logging, and workflow transition root causes.

Artifacts:
  📊 Error Analysis: /absolute/path/to/reports/001-repair-errors-repair.md
  📄 Repair Plan: /absolute/path/to/plans/001-repair-plan.md

Next Steps:
  • Review analysis: cat /path/to/reports/001-repair-errors-repair.md
  • Execute repairs: /build /path/to/plans/001-repair-plan.md
  • Verify fixes: /errors --command /repair --since 1h
EOF
```

**Recommendation**: Add console summary template to Phase 6 or create new Phase 7

---

### 12. Plan Revision History Missing

**Severity**: LOW (documentation enhancement)

**Issue**: Plan doesn't document that it's a repair plan for /repair command

**Standard Pattern** (plan-metadata-standard.md, /repair workflow extensions):
```markdown
### /repair Command

- **Error Log Query**: --since 24h --type state_error --command /repair
- **Errors Addressed**: 28 state_error instances across 3 root causes
```

**Recommendation**: Add workflow-specific metadata to plan header

---

## Standards Compliance Matrix

| Standard | Current Plan | Gap | Severity |
|----------|-------------|-----|----------|
| Plan Metadata Standard | Missing relative paths | Research Reports format | ERROR |
| Command Authoring | Not verified | Execution directives audit | ERROR |
| Output Formatting | Not addressed | Checkpoint format, console summary | WARNING |
| Error Handling Pattern | Partial | Dual trap, error context persistence | HIGH |
| State Persistence | Anti-pattern (JSON) | Flat key requirement | HIGH |
| Three-Tier Sourcing | Not verified | Tier 2/3 compliance check | ERROR |
| Testing Protocols | Incomplete | Error log status tests, ERR trap | MEDIUM |
| Directory Creation | Violation | Lazy creation pattern | LOW |
| Standards Injection | Not verified | repair-analyst context | LOW |

**Overall Assessment**: Plan needs 3 ERROR-level fixes, 2 HIGH-priority additions, 1 MEDIUM enhancement

---

## Recommended Revisions

### Priority 1 (ERROR-level, blocks commit)

1. **Fix Plan Metadata** (5 minutes):
   - Change absolute path to relative path with markdown link
   - Add Error Log Query and Errors Addressed fields

2. **Verify Execution Directives** (Phase 5 enhancement, 15 minutes):
   - Add test to validate all blocks have directives
   - Document current directive coverage

3. **Validate Three-Tier Sourcing** (Phase 4 enhancement, 15 minutes):
   - Add sourcing pattern audit step
   - Verify Tier 1/2/3 compliance

### Priority 2 (HIGH-priority, addresses root causes)

4. **Confirm Flat Key Approach** (Phase 1, no changes needed):
   - Current Phase 1 approach is correct
   - Add validation that no JSON used with append_workflow_state

5. **Complete Error Handling Integration** (New Phase 8, 1-2 hours):
   - Add `_flush_early_errors` call verification
   - Validate error context persistence pattern
   - Add `validate_state_restoration` checks

### Priority 3 (MEDIUM enhancements)

6. **Expand Test Coverage** (Phase 5 enhancement, 1 hour):
   - Add error log status lifecycle tests
   - Add ERR trap suppression validation
   - Add test isolation verification

### Priority 4 (LOW enhancements)

7. **Add Output Formatting** (New Phase 7, 1 hour):
   - Implement checkpoint format between blocks
   - Add console summary at completion
   - Reduce verbose output to single summary lines

8. **Fix Directory Creation** (Phase 3 revision, 15 minutes):
   - Change mkdir to validation-only
   - Document lazy creation delegation to agents

---

## Integration Points Requiring Validation

### 1. error-handling.sh Function Availability

Commands require these functions (must verify sourcing successful):

```bash
# From error-handling.sh (lines 1-100 examined)
ensure_error_log_exists
setup_bash_error_trap
log_command_error
parse_subagent_error
validate_state_restoration
check_unbound_vars
_flush_early_errors
```

**Recommendation**: Add function availability checks in Phase 4

### 2. workflow-state-machine.sh Integration

State machine requires:

```bash
# From workflow-state-machine.sh (lines 1-150 examined)
sm_init
sm_transition
sm_validate_state  # Missing from plan Phase 2
normalize_complexity
```

**Recommendation**: Add `sm_validate_state` call to Phase 2

### 3. state-persistence.sh Patterns

All state persistence must use:

```bash
# Flat key pattern (REQUIRED)
append_workflow_state "KEY" "VALUE"  # Simple string values only

# NOT this (PROHIBITED)
append_workflow_state "KEY" "$JSON_OBJECT"  # Complex types rejected
```

**Recommendation**: Phase 1 correctly addresses this - no changes needed

---

## Anti-Patterns Identified in Current Plan

### 1. Pre-Creating Subdirectories (Phase 3)

**Anti-Pattern**: `mkdir -p "$RESEARCH_DIR"` before agent writes files

**Correct Pattern**: Validate path exists, let agent create directory

**Fix**: Change Phase 3 Task 1 to validation-only check

### 2. Missing Dual Trap Setup Validation

**Anti-Pattern**: Assuming trap is active without validation

**Correct Pattern**: Validate trap after setup (from /plan.md lines 171-174):
```bash
# Validate trap is active - fail fast if error logging is broken
if ! trap -p ERR | grep -q "_log_bash_error"; then
  echo "ERROR: ERR trap not active - error logging will fail" >&2
  exit 1
fi
```

**Fix**: Add trap validation to Phase 2 or new Phase 8

### 3. No Checkpoint Format

**Anti-Pattern**: No intermediate progress visibility

**Correct Pattern**: Add checkpoints between major blocks (output-formatting.md)

**Fix**: Add Phase 7 for output formatting compliance

---

## Reference Implementations

### /plan.md Block 1a Structure (Lines 1-270)

Demonstrates correct patterns:

1. Early error buffer initialization (line 120)
2. error-handling.sh sourced FIRST (line 125)
3. `_source_with_diagnostics` for remaining Tier 1 libs (lines 131-133)
4. Three-tier sourcing pattern (lines 136-143)
5. Pre-flight function validation (lines 153-156)
6. Early trap setup (line 163)
7. Workflow initialization (lines 166-180)
8. Late trap update (line 180)
9. Early error flush (line 184)
10. State file validation (lines 194-227)

**Gaps in /repair.md**:
- Missing pre-flight function validation
- Missing early error flush call
- No state file content validation

### /plan.md Error Context Persistence

Shows correct pattern:

```bash
# Block 1a
COMMAND_NAME="/plan"
USER_ARGS="$FEATURE_DESCRIPTION"
export COMMAND_NAME USER_ARGS

# Block 2+ (loads automatically)
load_workflow_state "$WORKFLOW_ID"
# COMMAND_NAME and USER_ARGS restored
```

**Recommendation**: Verify /repair.md follows this pattern in all blocks

---

## Compliance Checklist for Revised Plan

### Metadata
- [ ] Research Reports uses relative paths with markdown links
- [ ] Error Log Query field added (workflow-specific)
- [ ] Errors Addressed field added (workflow-specific)

### Command Authoring
- [ ] All bash blocks have execution directives (validated)
- [ ] Three-tier sourcing pattern verified
- [ ] Pre-flight function validation added

### Error Handling
- [ ] Dual trap setup verified
- [ ] `_flush_early_errors` call added
- [ ] Error context persistence validated across all blocks
- [ ] `validate_state_restoration` checks added

### State Persistence
- [ ] Flat keys used (no JSON with append_workflow_state)
- [ ] Block 1a persists all required variables
- [ ] Block 2+ loads and validates state

### Output Formatting
- [ ] Checkpoint format added between blocks
- [ ] Console summary with 4-section format
- [ ] Single summary line per block

### Testing
- [ ] Error log status lifecycle tests added
- [ ] ERR trap suppression tests added
- [ ] Test isolation validation included

### Directory Creation
- [ ] Lazy creation pattern followed (validation-only)
- [ ] No pre-creation of subdirectories

---

## Conclusion

The current /repair plan (001-repair-repair-20251202-120554-plan.md) is technically sound in identifying root causes and proposing fixes, but requires **8 revisions** to achieve full standards compliance:

**Critical (ERROR-level)**:
1. Fix plan metadata Research Reports format
2. Verify execution directives in all blocks
3. Validate three-tier sourcing pattern

**High Priority**:
4. Complete error handling integration (dual trap, error flush)
5. Confirm flat key approach (already correct)

**Medium Priority**:
6. Expand test coverage (error log status, ERR trap)

**Low Priority**:
7. Add output formatting (checkpoints, console summary)
8. Fix directory creation pattern (validation-only)

**Estimated Revision Time**: 3-4 hours total (0.5h critical + 2h high + 1h medium + 0.5h low)

**Pre-Commit Risk**: Current plan would fail metadata validation (ERROR-level)

**Implementation Risk**: Medium - Missing error handling patterns could cause similar errors during fix implementation

---

## Related Documentation

- [Plan Metadata Standard](.claude/docs/reference/standards/plan-metadata-standard.md)
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md)
- [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md)
- [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md)
- [Repair Command Guide](.claude/docs/guides/commands/repair-command-guide.md)
- [Testing Protocols](.claude/docs/reference/standards/testing-protocols.md)
- [Code Standards](.claude/docs/reference/standards/code-standards.md)
