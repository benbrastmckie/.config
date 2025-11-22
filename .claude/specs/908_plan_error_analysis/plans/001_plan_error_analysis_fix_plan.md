# Plan Command Error Fixes Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Fix /plan command errors identified in error analysis
- **Scope**: Error handling improvements, test isolation, LLM classification validation
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 45.0 (fix=3 + 10 tasks/2 + 8 files*3 + 3 integrations*5)
- **Research Reports**:
  - [Error Analysis Report](../reports/001_error_report.md)
  - [Plan Error Report](../reports/001_plan_error_report.md)
  - [Plan Revision Insights](../reports/001_plan_revision_insights.md)

## Overview

This plan addresses the five key error categories identified in the `/plan` command error analysis:

1. **Test errors polluting production logs** (31.8%) - Test agent validation errors logged to production
2. **Benign bashrc sourcing errors** (22.7%) - System initialization failures that are not actionable
3. **Topic naming agent failures** (13.6%) - Agent output file not created
4. **Library function not found** (13.6%) - `append_workflow_state` exit code 127
5. **Research topics parsing issues** (9.1%) - Empty/missing `research_topics` array

**Partial Progress**: During the /plan command execution that created this plan, two runtime fixes were applied to `workflow-initialization.sh` that address error category #5 (9.1% of errors). The remaining 90.9% of errors (categories #1-#4) still require implementation.

## Runtime Fixes Applied

The following fixes were applied during the /plan command execution and partially address Phase 5:

### Fix 1: Fallback Slug Output Format Correction
**Location**: `.claude/lib/workflow/workflow-initialization.sh` lines 185-194

**Original Code** (caused eval errors):
```bash
# Output the fallback slugs
printf '%s\n' "${fallback_slugs[@]}"
return 0
```

**Fixed Code**:
```bash
# Output bash array declaration for eval by caller (matches line 266 format)
local slugs_str
slugs_str=$(printf '"%s" ' "${fallback_slugs[@]}")
echo "slugs=($slugs_str)"
return 0
```

**Problem Addressed**: The original code printed each fallback slug on its own line. When the caller used `eval "$slugs_declaration"`, these bare lines were interpreted as commands, resulting in "command not found" errors.

### Fix 2: Stderr/Stdout Separation for Eval Safety
**Location**: `.claude/lib/workflow/workflow-initialization.sh` lines 641-643

**Original Code**:
```bash
if slugs_declaration=$(validate_and_generate_filename_slugs "$classification_result" "$research_complexity" 2>&1); then
```

**Fixed Code**:
```bash
# NOTE: Only capture stdout for eval - stderr warnings pass through without eval
if slugs_declaration=$(validate_and_generate_filename_slugs "$classification_result" "$research_complexity"); then
```

**Problem Addressed**: The `2>&1` redirect captured stderr warnings along with stdout, causing warning messages to be included in the `slugs_declaration` variable and subsequently eval'd as shell commands.

**Status**: These fixes are currently uncommitted. Phase 5 includes a task to commit them.

## Research Summary

Key findings from the error analysis report:

1. **Test Agent Errors**: 7 errors (31.8%) from `test-agent` validation in `validate_agent_output` function - test errors should not appear in production logs
2. **Bashrc Sourcing**: 5 errors (22.7%) from `. /etc/bashrc` exit code 127 - these are benign system initialization errors in Claude Code environment
3. **Topic Naming Failures**: 3 errors (13.6%) with `fallback_reason=agent_no_output_file` - topic naming Haiku agent fails to write output
4. **Function Not Found**: 3 errors (13.6%) for `append_workflow_state` at line 319 - library sourcing issue in some bash blocks
5. **Research Topics**: 2 errors (9.1%) where LLM returns `topic_directory_slug` but `research_topics` is empty array

Recommended approach: Fix issues in priority order starting with test isolation (highest volume), then bashrc filtering, topic naming robustness, library sourcing verification, and LLM validation improvements.

## Success Criteria
- [ ] Test errors logged to separate test log file, not production errors.jsonl
- [ ] Bashrc sourcing errors (exit 127 for bashrc commands) filtered from logging
- [ ] Topic naming agent has improved timeout handling and validation
- [ ] All /plan command bash blocks have pre-flight function validation
- [ ] LLM classification validates `research_topics` array before use
- [ ] Error rate for /plan command reduced by >50% in subsequent analysis

## Technical Design

### Architecture Overview

```
Error Flow (Current):
  Test Execution → log_command_error() → errors.jsonl (polluted)
  Bashrc Source  → _log_bash_error()   → errors.jsonl (noisy)

Error Flow (Fixed):
  Test Execution → CLAUDE_TEST_MODE=1 → test-errors.jsonl (isolated)
  Bashrc Source  → _is_benign_bash_error() → (filtered, no log)
  Topic Naming   → validate_agent_output_with_retry() → (improved timeout)
  Block 2/3      → validate_library_functions() → (pre-flight check)
  Classification → validate_and_generate_filename_slugs() → (array validation)
```

### Key Components

1. **Test Log Routing**: `log_command_error()` detects `CLAUDE_TEST_MODE` or `test_*` workflow ID patterns
2. **Benign Error Filter**: `_is_benign_bash_error()` expanded to catch bashrc exit 127 patterns
3. **Agent Validation**: `validate_agent_output_with_retry()` timeout increased, retries improved
4. **Pre-flight Validation**: Add `validate_library_functions "state-persistence"` to all bash blocks
5. **JSON Array Validation**: `validate_and_generate_filename_slugs()` validates array before processing

## Implementation Phases

### Phase 1: Test Error Isolation [COMPLETE]
dependencies: []

**Objective**: Route test errors to separate log file to prevent production log pollution

**Complexity**: Low

Tasks:
- [x] Review current test detection logic in `log_command_error()` (file: .claude/lib/core/error-handling.sh, lines 434-448)
- [x] Add workflow_id pattern matching for `test_*` prefixed IDs
- [x] Verify `CLAUDE_TEST_MODE` environment variable detection works correctly
- [x] Update test scripts to set `CLAUDE_TEST_MODE=1` before running tests
- [x] Add test to verify test errors route to test-errors.jsonl (file: .claude/tests/unit/test_source_libraries_inline_error_logging.sh)

Testing:
```bash
# Verify test error routing
CLAUDE_TEST_MODE=1 bash -c 'source .claude/lib/core/error-handling.sh && log_command_error "/test" "test_123" "" "agent_error" "Test message" "test"'
# Check test log: cat .claude/tests/logs/test-errors.jsonl
# Verify not in: cat .claude/data/logs/errors.jsonl
```

**Expected Duration**: 1.5 hours

### Phase 2: Bashrc Sourcing Error Filter [COMPLETE]
dependencies: [1]

**Objective**: Filter benign bashrc/profile sourcing errors from production logs

**Complexity**: Low

Tasks:
- [x] Review current `_is_benign_bash_error()` implementation (file: .claude/lib/core/error-handling.sh, lines 1240-1309)
- [x] Verify bashrc exit 127 pattern already handled (it is - lines 1261-1266)
- [x] Add unit test case for `. /etc/bashrc` with exit code 127 if not present
- [x] Verify call stack filtering for errors originating from bashrc files (lines 1292-1306)
- [x] Test that `/etc/bashrc` sourcing errors in Claude Code environment are filtered

Testing:
```bash
# Run existing benign error filter tests
bash .claude/tests/unit/test_benign_error_filter.sh

# Verify specific pattern
source .claude/lib/core/error-handling.sh
if _is_benign_bash_error ". /etc/bashrc" 127; then
  echo "PASS: bashrc sourcing filtered"
else
  echo "FAIL: bashrc sourcing not filtered"
fi
```

**Expected Duration**: 1 hour

### Phase 3: Topic Naming Agent Robustness [COMPLETE]
dependencies: [1]

**Objective**: Improve topic naming agent timeout handling and output validation

**Complexity**: Medium

Tasks:
- [x] Review `validate_agent_output_with_retry()` implementation (file: .claude/lib/core/error-handling.sh, lines 1452-1509)
- [x] Increase base timeout from 5s to 10s for topic naming agent (file: .claude/commands/plan.md, line 343)
- [x] Add explicit output file path validation before agent invocation
- [x] Improve error context logging when agent fails (include agent prompt hash for debugging)
- [x] Update topic-naming-agent.md to emphasize output file creation requirement
- [x] Add diagnostic output showing agent state on failure

Testing:
```bash
# Test topic naming validation with extended timeout
WORKFLOW_ID="test_$$"
TOPIC_NAME_FILE="${HOME}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
touch "$TOPIC_NAME_FILE"
echo "valid_topic_name" > "$TOPIC_NAME_FILE"
source .claude/lib/core/error-handling.sh
validate_agent_output_with_retry "topic-naming-agent" "$TOPIC_NAME_FILE" "validate_topic_name_format" 10 3
echo "Exit code: $?"
```

**Expected Duration**: 2 hours

### Phase 4: Library Sourcing Pre-flight Checks [COMPLETE]
dependencies: [1, 2]

**Objective**: Add pre-flight function validation to all /plan command bash blocks

**Complexity**: Medium

Tasks:
- [x] Review existing pre-flight validation pattern in Block 1a (file: .claude/commands/plan.md, lines 148-152)
- [x] Verify Block 1b has pre-flight validation after sourcing error-handling.sh (line 323-335) - ALREADY HAS IT
- [x] Verify Block 1c has pre-flight validation (lines 429-434) - ALREADY HAS IT
- [x] Verify Block 2 has pre-flight validation (lines 627-636) - ALREADY HAS IT
- [x] Verify Block 3 has pre-flight validation (lines 909-914) - ALREADY HAS IT
- [x] Add integration test that validates all blocks have function availability checks
- [x] Review if any blocks still reference `append_workflow_state` before sourcing state-persistence.sh

Testing:
```bash
# Run the existing plan command test suite
bash .claude/tests/unit/test_plan_command_fixes.sh

# Verify function availability pattern
grep -n "validate_library_functions\|declare -f append_workflow_state" .claude/commands/plan.md
```

**Expected Duration**: 1.5 hours

### Phase 5: LLM Classification Array Validation [COMPLETE]
dependencies: [1, 3]

**Objective**: Improve validation of LLM classification results before use

**Complexity**: Medium

**Partial Progress Note**: Two runtime fixes were applied during /plan execution that address the fallback slug output format and stderr/stdout separation issues. See "Runtime Fixes Applied" section above for details. Remaining tasks focus on committing these fixes and improving LLM prompt.

Tasks:
- [x] Review `validate_and_generate_filename_slugs()` (file: .claude/lib/workflow/workflow-initialization.sh, lines 150-195) - COMPLETED (runtime fix applied)
- [x] Verify empty array handling and fallback generation already works (lines 169-195) - COMPLETED (fixed fallback output format)
- [x] Fix stderr/stdout separation in caller to prevent eval errors (lines 641-643) - COMPLETED (runtime fix applied)
- [x] Commit runtime fixes to workflow-initialization.sh with descriptive message
- [x] Improve LLM classification prompt to always include `research_topics` array
- [x] Add validation that `topic_directory_slug` and `research_topics` are both present
- [x] Add test case for classification with `topic_directory_slug` but empty `research_topics`
- [x] Consider caching known-good classification results for common prompt patterns

Testing:
```bash
# Test classification validation with empty research_topics
source .claude/lib/workflow/workflow-initialization.sh
classification='{"topic_directory_slug": "test_topic", "research_topics": []}'
output=$(validate_and_generate_filename_slugs "$classification" 2)
echo "Output: $output"
# Should generate fallback slugs: slugs=("topic1" "topic2")

# Verify uncommitted changes
git diff .claude/lib/workflow/workflow-initialization.sh | head -50
```

**Expected Duration**: 2 hours (reduced from original - partial work complete)

## Testing Strategy

### Unit Tests
- Run existing test suites to verify no regressions
- Add new test cases for each fix
- Test edge cases for benign error filtering

### Integration Tests
- Run `/plan "test feature"` and verify error log entries
- Verify test errors route to test-errors.jsonl
- Verify bashrc errors are not logged

### Validation Commands
```bash
# Run all related tests
bash .claude/tests/unit/test_benign_error_filter.sh
bash .claude/tests/unit/test_plan_command_fixes.sh

# Verify error log after /plan execution
/errors --command /plan --limit 10

# Check error distribution
cat .claude/data/logs/errors.jsonl | jq -r '.error_type' | sort | uniq -c
```

## Documentation Requirements
- Update [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md) with test isolation details
- Update [Plan Command Troubleshooting](.claude/docs/troubleshooting/plan-command-errors.md) with new diagnostics
- Add test error routing documentation to error-handling.sh header comment

## Dependencies
- jq (JSON parsing in error-handling.sh)
- bash 4.0+ (associative arrays in state-persistence.sh)
- Haiku model availability for topic naming agent

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Test isolation breaks existing tests | Low | Medium | Run full test suite after changes |
| Benign filter too aggressive | Medium | Low | Conservative pattern matching, explicit bashrc paths only |
| Agent timeout still insufficient | Medium | Medium | Configurable timeout, exponential backoff |
| Function validation performance | Low | Low | Check is O(1) hash lookup |

## Rollback Plan
- All changes are additive/non-breaking
- If test isolation causes issues: revert `log_command_error()` changes
- If bashrc filter too aggressive: narrow `_is_benign_bash_error()` patterns
- Original error behavior preserved in non-test mode
