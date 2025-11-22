# Standards Compliance Analysis for Error Logging Infrastructure Migration

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Standards compliance analysis for error logging infrastructure migration plan
- **Report Type**: codebase analysis
- **Related Plan**: /home/benjamin/.config/.claude/specs/896_error_logging_infrastructure_migration/plans/001_error_logging_infrastructure_plan.md

## Executive Summary

The existing error logging infrastructure migration plan demonstrates strong alignment with core error handling standards but requires several revisions to achieve full compliance with bash sourcing patterns, output formatting standards, and testing protocols. Key gaps include: (1) the plan's error logging integration pattern omits the mandatory fail-fast handler syntax for Tier 1 libraries, (2) the plan does not address pre-commit hook enforcement validation, and (3) testing strategy lacks behavioral compliance test patterns. The source-libraries-inline.sh enhancement approach is sound but needs error logging integration at function validation failures as documented.

## Findings

### 1. Error Handling Pattern Compliance

**Standard Reference**: .claude/docs/concepts/patterns/error-handling.md (lines 1-765)

**Areas of Compliance**:
- Plan correctly identifies `log_command_error()` as the centralized logging function (plan line 90)
- Plan uses correct error types: `dependency_error`, `state_error`, `validation_error` (plan lines 91, 171)
- Plan correctly identifies the JSONL schema and workflow metadata requirements (plan lines 126-149)
- Plan correctly references `ensure_error_log_exists`, `setup_bash_error_trap` (plan lines 127, 136)

**Gaps Requiring Revision**:
1. **Plan lines 109-149 - Error Logging Integration Pattern**: The pattern shown uses simplified error handling:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
     echo "ERROR: Failed to source error-handling.sh" >&2
     exit 1
   }
   ```
   This is correct but the plan should explicitly note this is the MANDATORY fail-fast pattern per code-standards.md.

2. **Missing Agent Error Protocol**: The plan does not mention `parse_subagent_error()` integration despite expand.md and collapse.md using Task tool for agent invocations (error-handling.md lines 508-548). Plan should include guidance on logging TASK_ERROR signals from complexity-estimator agent invocations.

3. **Missing Test Environment Separation**: Plan does not address CLAUDE_TEST_MODE environment variable for test isolation (error-handling.md lines 106-131). Phase 1 tests should set this flag.

### 2. Bash Sourcing Pattern Compliance

**Standard Reference**: .claude/docs/reference/standards/code-standards.md (lines 34-86)

**Areas of Compliance**:
- Plan correctly identifies the three-tier pattern (plan lines 79-86)
- Plan correctly specifies fail-fast handlers for Tier 1 libraries (plan line 172-173)

**Gaps Requiring Revision**:
1. **Plan Phase 2 - expand.md/collapse.md Updates**: Both commands already have project directory bootstrap (expand.md lines 78-106, collapse.md lines 80-108) but lack the complete error handling integration. The plan correctly identifies this gap but should reference the specific line numbers:
   - expand.md: Add after line 106 (after `export CLAUDE_PROJECT_DIR`)
   - collapse.md: Add after line 108 (after `export CLAUDE_PROJECT_DIR`)

2. **Linter Validation Missing**: Plan does not mention running `.claude/scripts/lint/check-library-sourcing.sh` after modifications (code-standards.md lines 77-81). Phase 2 testing should validate linter compliance.

3. **Pre-commit Hook Validation**: Plan does not mention validating that modified commands pass pre-commit hooks (code-standards.md lines 323-358). This is critical since violations block commits.

### 3. Output Formatting Compliance

**Standard Reference**: .claude/docs/reference/standards/output-formatting.md (lines 1-652)

**Areas of Compliance**:
- Plan uses correct error suppression pattern for library sourcing (`2>/dev/null || { exit 1 }`) (plan line 121)

**Gaps Requiring Revision**:
1. **Verbose Error Output**: Plan line 139-148 shows log_command_error call signature. The plan should clarify that error messages to stderr should use WHICH/WHAT/WHERE structure per error enhancement guide (output-formatting.md lines 357-362).

2. **Single Summary Line Pattern**: Plan does not mention that setup blocks should emit only a single summary line (output-formatting.md lines 156-178). Error logging initialization should be silent except for failures.

3. **Console Summary for Phase 2**: expand.md and collapse.md have existing checkpoint reporting (expand.md lines 1097-1132, collapse.md lines 701-742). Plan should ensure error logging additions don't add verbose output during success path.

### 4. Existing Error Handling Infrastructure Analysis

**Standard Reference**: .claude/lib/core/error-handling.sh (lines 1-1460)

**Areas of Compliance**:
- Plan correctly identifies all required functions: `log_command_error`, `ensure_error_log_exists`, `setup_bash_error_trap` (plan lines 339-341)
- Plan correctly identifies error type constants (error-handling.sh lines 367-374)

**Integration Opportunities**:
1. **source-libraries-inline.sh Enhancement (Plan Phase 1)**:
   The current implementation at lines 81-89 only outputs to stderr:
   ```bash
   if ! type append_workflow_state &>/dev/null; then
     echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
     return 1
   }
   ```

   The plan correctly identifies this gap but should use conditional logging:
   ```bash
   if ! type append_workflow_state &>/dev/null; then
     echo "ERROR: append_workflow_state function not available" >&2
     # Log to centralized error log if available (error-handling.sh loaded first)
     if type log_command_error &>/dev/null; then
       log_command_error \
         "${COMMAND_NAME:-/unknown}" \
         "${WORKFLOW_ID:-unknown}" \
         "${USER_ARGS:-}" \
         "dependency_error" \
         "append_workflow_state function not available after sourcing state-persistence.sh" \
         "source_critical_libraries" \
         '{"function": "append_workflow_state", "library": "state-persistence.sh"}'
     fi
     return 1
   }
   ```

2. **validate_agent_output Integration**: error-handling.sh provides `validate_agent_output()` (lines 1343-1368) and `validate_agent_output_with_retry()` (lines 1373-1427). Plan Phase 2 should use these for verifying expand.md/collapse.md agent outputs.

### 5. Testing Protocol Compliance

**Standard Reference**: .claude/docs/reference/standards/testing-protocols.md (lines 1-325)

**Areas of Compliance**:
- Plan mentions unit tests for Phase 1 (plan lines 295-299)
- Plan mentions integration tests for Phase 2 (plan lines 309-312)

**Gaps Requiring Revision**:
1. **Test Isolation**: Plan does not set CLAUDE_TEST_MODE or CLAUDE_SPECS_ROOT for test isolation (testing-protocols.md lines 201-262). Tests may pollute production logs.

2. **Agent Behavioral Compliance Tests Missing**: Testing protocols require behavioral compliance validation (testing-protocols.md lines 40-198). Plan should include tests for:
   - Error logging integration follows mandatory pattern
   - Fail-fast handlers present on Tier 1 libraries
   - Error log entries have correct schema

3. **jq Filter Safety**: Plan Phase 2 testing uses jq for error log validation (plan lines 218-226). Should use explicit parentheses for pipe operations in boolean context per testing-protocols.md lines 264-325.

### 6. expand.md and collapse.md Analysis

**File References**:
- expand.md: .claude/commands/expand.md (1145 lines)
- collapse.md: .claude/commands/collapse.md (745 lines)

**Current State**:
- Both commands have CLAUDE_PROJECT_DIR bootstrap (correct)
- Both source plan-core-bundle.sh and auto-analysis-utils.sh
- Neither sources error-handling.sh
- Neither has error logging integration

**Specific Integration Points for Plan Revision**:

**expand.md**:
- Line 109: After sourcing plan-core-bundle.sh, add error-handling.sh sourcing
- Line 99-102: "ERROR: Failed to detect project directory" - add log_command_error
- Line 131: "ERROR: Plan file not found" - add log_command_error
- Line 157: "ERROR: Phase not found" - add log_command_error
- Line 231: "CRITICAL ERROR: Phase file not created" - add log_command_error
- Line 238: "ERROR: Phase file too small" - add log_command_error

**collapse.md**:
- Line 111: After sourcing plan-core-bundle.sh, add error-handling.sh sourcing
- Line 100-105: "ERROR: Failed to detect project directory" - add log_command_error
- Line 141: "error" calls (multiple) - add log_command_error before error function
- Line 147-149: "ERROR" checks - add log_command_error
- Line 337: "ERROR: Stage file not found" - add log_command_error

## Recommendations

### Recommendation 1: Add Explicit Fail-Fast Handler Documentation (HIGH PRIORITY)

**Update Plan Phase 1 and Phase 2** to explicitly state:

"All error-handling.sh sourcing MUST use the fail-fast pattern enforced by `check-library-sourcing.sh`. Bare `2>/dev/null` without `|| { exit 1 }` is prohibited and will fail pre-commit hooks."

Add validation step:
```bash
bash .claude/scripts/lint/check-library-sourcing.sh expand.md collapse.md
```

### Recommendation 2: Add Test Isolation Requirements (HIGH PRIORITY)

**Update Plan Phase 1 Testing Section** to include:

```bash
# Set test isolation flags
export CLAUDE_TEST_MODE=1
export CLAUDE_SPECS_ROOT="/tmp/test_error_logging_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_error_logging_$$"
mkdir -p "$CLAUDE_SPECS_ROOT/.claude/data/logs"
trap 'rm -rf "$CLAUDE_SPECS_ROOT"' EXIT
```

### Recommendation 3: Add Agent Error Protocol for expand.md/collapse.md (MEDIUM PRIORITY)

**Update Plan Phase 2** to include TASK_ERROR parsing after complexity-estimator agent invocations:

```bash
# After agent invocation in auto-analysis mode
error_json=$(parse_subagent_error "$agent_response")
if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$(echo "$error_json" | jq -r '.error_type')" \
    "Agent complexity-estimator failed: $(echo "$error_json" | jq -r '.message')" \
    "subagent_complexity-estimator" \
    "$(echo "$error_json" | jq -c '.context')"
fi
```

### Recommendation 4: Use validate_agent_output Functions (MEDIUM PRIORITY)

**Update Plan Phase 2** to use existing validation functions for expansion/collapse artifact verification:

```bash
# Instead of manual file existence checks
validate_agent_output "complexity-estimator" "$ARTIFACT_PATH" 10
```

### Recommendation 5: Add Pre-commit Validation Step (HIGH PRIORITY)

**Add to Plan Phase 2 Testing Section**:

```bash
# Validate pre-commit compliance before merging
bash .claude/scripts/validate-all-standards.sh --sourcing --suppression --conditionals
```

### Recommendation 6: Clarify Output Suppression Requirements (LOW PRIORITY)

**Update Plan Technical Design** to note:
- Error logging initialization should be silent on success
- Only emit summary line after all setup complete
- Error messages should use WHICH/WHAT/WHERE structure for stderr output

## References

### Standards Documentation
- .claude/docs/concepts/patterns/error-handling.md:1-765 - Error handling pattern
- .claude/docs/reference/standards/code-standards.md:34-392 - Bash sourcing and code standards
- .claude/docs/reference/standards/output-formatting.md:1-652 - Output formatting standards
- .claude/docs/reference/standards/testing-protocols.md:1-325 - Testing protocols

### Implementation Files
- .claude/lib/core/error-handling.sh:1-1460 - Error handling library
- .claude/lib/core/source-libraries-inline.sh:1-130 - Library sourcing utility
- .claude/commands/expand.md:1-1145 - Expand command
- .claude/commands/collapse.md:1-745 - Collapse command

### Enforcement Tools
- .claude/scripts/lint/check-library-sourcing.sh - Bash sourcing linter
- .claude/scripts/validate-all-standards.sh - Unified validation script
- .claude/tests/utilities/lint_error_suppression.sh - Error suppression linter

### Existing Plan
- .claude/specs/896_error_logging_infrastructure_migration/plans/001_error_logging_infrastructure_plan.md:1-347 - Plan being reviewed
