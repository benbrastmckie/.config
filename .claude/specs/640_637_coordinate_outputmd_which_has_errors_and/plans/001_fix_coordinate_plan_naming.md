# Fix /coordinate Plan Naming Regression - Implementation Plan

## Metadata
- **Date**: 2025-11-10
- **Feature**: Restore descriptive plan naming in /coordinate command
- **Scope**: Fix hardcoded plan path that causes generic "001_implementation.md" filenames
- **Structure Level**: 0
- **Complexity Score**: 18.0
- **Estimated Phases**: 5
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Plan Naming Implementation Analysis](../reports/001_plan_naming_implementation.md)
  - [Historical Naming Patterns Research](../reports/002_historical_naming_patterns.md)

## Overview

The /coordinate command currently creates plans with generic names like "001_implementation.md" instead of descriptive names like "001_fix_coordinate_plan_naming.md". This regression was introduced in commit 4534cef0 (Nov 7, 2025) during the state machine migration of /coordinate.

The root cause is a hardcoded path assignment in coordinate.md line 731 that overrides the correctly calculated PLAN_PATH exported by workflow-initialization.sh. The library already generates descriptive names using the sanitize_topic_name() algorithm, but coordinate.md ignores this exported value.

## Research Summary

Key findings from research reports:

**From Plan Naming Implementation Analysis**:
- Regression introduced in commit 4534cef0 during state machine migration
- Line 731 in coordinate.md hardcodes: `PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"`
- workflow-initialization.sh correctly calculates: `"${topic_path}/plans/001_${topic_name}_plan.md"` (line 259)
- PLAN_PATH is exported at line 297 but coordinate.md overrides it
- 8 specs created after Nov 7 have generic "001_implementation.md" filenames

**From Historical Naming Patterns Research**:
- Topic naming algorithm enhanced Nov 5, 2025 (commit ed69cacc)
- New algorithm extracts path components, removes stopwords, produces concise names
- Examples: "fix auth bug" → "001_fix_auth_bug_plan.md"
- Pattern documented in directory-protocols.md with best practices

**Recommended Approach**: Remove the hardcoded assignment and trust the PLAN_PATH value exported by workflow-initialization.sh, which already implements the correct descriptive naming pattern.

## Success Criteria
- [ ] Plans created by /coordinate use descriptive names (e.g., "001_fix_coordinate_plan_naming.md")
- [ ] No hardcoded "001_implementation.md" path in coordinate.md
- [ ] PLAN_PATH variable sourced from workflow-initialization.sh export
- [ ] State persistence correctly saves and loads PLAN_PATH across bash blocks
- [ ] Test suite verifies plan naming pattern
- [ ] Documentation updated with naming convention examples

## Technical Design

### Architecture Overview

The fix involves three components:

1. **coordinate.md** (Phase 1): Remove hardcoded PLAN_PATH assignment, add state persistence
2. **State Persistence** (Phase 2): Save PLAN_PATH to workflow state for cross-block availability
3. **Verification** (Phase 3): Test and validate descriptive naming works end-to-end

### State Management Pattern

**Current Flow** (Broken):
```
Bash Block 1 (lines 100-199):
  - initialize_workflow_paths() exports PLAN_PATH with descriptive name
  - State saved: WORKFLOW_ID, TOPIC_PATH (but not PLAN_PATH)

Bash Block 2 (lines 700-779):
  - load_workflow_state() restores WORKFLOW_ID, TOPIC_PATH
  - PLAN_PATH assignment OVERRIDES exported value: hardcoded "001_implementation.md"
  - Verification checks hardcoded path (fails to find descriptive name from agent)
```

**Fixed Flow**:
```
Bash Block 1 (lines 100-199):
  - initialize_workflow_paths() exports PLAN_PATH with descriptive name
  - State saved: WORKFLOW_ID, TOPIC_PATH, PLAN_PATH ← NEW

Bash Block 2 (lines 700-779):
  - load_workflow_state() restores WORKFLOW_ID, TOPIC_PATH, PLAN_PATH ← NEW
  - No hardcoded assignment - use value from state
  - Verification checks correct descriptive path
```

### Subprocess Isolation Considerations

Per bash-block-execution-model.md, each bash block runs in a separate subprocess. Exports don't persist across blocks. Solution: Use state-persistence.sh to serialize PLAN_PATH to workflow state file.

**Key Pattern**:
- Block 1: Calculate PLAN_PATH, save to state via append_workflow_state()
- Block 2: Load state via load_workflow_state(), PLAN_PATH restored from file
- No cross-block exports or shared memory assumptions

## Implementation Phases

### Phase 1: Remove Hardcoded Path and Add State Persistence [COMPLETED]
dependencies: []

**Objective**: Fix coordinate.md to use PLAN_PATH from workflow-initialization.sh and persist across bash blocks

**Complexity**: Low

**Tasks**:
- [x] Read coordinate.md lines 160-180 to verify initialize_workflow_paths() is called (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Add append_workflow_state for PLAN_PATH after line 173 (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Read coordinate.md line 731 to confirm current hardcoded assignment (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Remove line 731 hardcoded PLAN_PATH assignment (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Add diagnostic echo before verification to confirm PLAN_PATH value (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Verify PLAN_PATH is loaded from state in bash block 2 via load_workflow_state() (file: /home/benjamin/.config/.claude/commands/coordinate.md)

**Expected Changes**:
```bash
# Line 173 (after TOPIC_PATH state save) - ADD:
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Line 731 - REMOVE:
PLAN_PATH="${TOPIC_PATH}/plans/001_implementation.md"

# Line 730 (after emit_progress) - ADD for debugging:
echo "DEBUG: PLAN_PATH from state: $PLAN_PATH"
```

**Testing**:
```bash
# Manual test - run /coordinate and verify plan name
/coordinate "fix test bug"

# Expected plan path:
# .claude/specs/{NNN}_fix_test_bug/plans/001_fix_test_bug_plan.md

# Verify PLAN_PATH variable in output
grep "DEBUG: PLAN_PATH" <coordinate output>
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Manual test confirms descriptive plan name created
- [ ] DEBUG output shows correct PLAN_PATH variable value
- [ ] No hardcoded "001_implementation.md" in coordinate.md
- [ ] Git commit created: `feat(640): complete Phase 1 - Remove hardcoded plan path`

### Phase 2: Add Validation and Fallback Logic [COMPLETED]
dependencies: [1]

**Objective**: Add safety checks to ensure PLAN_PATH is always valid before verification

**Complexity**: Low

**Tasks**:
- [x] Add PLAN_PATH validation check after load_workflow_state() (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Create fallback calculation if PLAN_PATH empty (should never happen, but fail-fast) (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Add error message if PLAN_PATH doesn't contain TOPIC_NAME (file: /home/benjamin/.config/.claude/commands/coordinate.md)
- [x] Update verification error message to show expected vs actual paths (file: /home/benjamin/.config/.claude/commands/coordinate.md)

**Validation Logic**:
```bash
# After load_workflow_state (around line 722)
if [ -z "${PLAN_PATH:-}" ]; then
  echo "ERROR: PLAN_PATH not restored from workflow state"
  echo "This indicates a bug in state persistence"
  handle_state_error "PLAN_PATH missing from workflow state" 1
fi

# Verify PLAN_PATH contains topic name (sanity check)
if [[ ! "$PLAN_PATH" =~ $TOPIC_NAME ]]; then
  echo "WARNING: PLAN_PATH does not contain topic name"
  echo "  TOPIC_NAME: $TOPIC_NAME"
  echo "  PLAN_PATH: $PLAN_PATH"
  echo "This may indicate a naming regression"
fi
```

**Testing**:
```bash
# Test validation triggers
# Manually corrupt state file to test error handling
STATE_FILE="${HOME}/.claude/tmp/workflow_coordinate_$(date +%s).sh"
# Remove PLAN_PATH line from state file
sed -i '/^PLAN_PATH=/d' "$STATE_FILE"
# Re-run bash block 2 - should fail-fast with error
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Validation logic added and tested
- [ ] Error messages are clear and actionable
- [ ] Fail-fast behavior verified with corrupted state
- [ ] Git commit created: `feat(640): complete Phase 2 - Add plan path validation`

### Phase 3: Create Regression Test
dependencies: [1]

**Objective**: Add automated test to prevent future plan naming regressions

**Complexity**: Medium

**Tasks**:
- [ ] Create test function in test_orchestration_commands.sh (file: /home/benjamin/.config/.claude/tests/test_orchestration_commands.sh)
- [ ] Mock coordinate workflow execution through planning phase (file: /home/benjamin/.config/.claude/tests/test_orchestration_commands.sh)
- [ ] Assert plan filename contains workflow description keywords (file: /home/benjamin/.config/.claude/tests/test_orchestration_commands.sh)
- [ ] Assert plan filename is NOT "001_implementation.md" (file: /home/benjamin/.config/.claude/tests/test_orchestration_commands.sh)
- [ ] Test sanitize_topic_name() examples from research reports (file: /home/benjamin/.config/.claude/tests/test_orchestration_commands.sh)

**Test Implementation**:
```bash
test_coordinate_plan_naming() {
  echo "Testing coordinate plan naming pattern..."

  # Test workflow description
  WORKFLOW_DESC="fix authentication bug"

  # Expected sanitized name from topic-utils.sh algorithm
  EXPECTED_TOPIC="fix_authentication_bug"
  EXPECTED_PATTERN="001_${EXPECTED_TOPIC}_plan.md"

  # Call sanitize_topic_name() directly (source topic-utils.sh)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/topic-utils.sh"
  ACTUAL_TOPIC=$(sanitize_topic_name "$WORKFLOW_DESC")

  # Assert topic name matches expected pattern
  assert_equal "$ACTUAL_TOPIC" "$EXPECTED_TOPIC" "Topic name should be descriptive"

  # Verify plan path construction
  TOPIC_PATH=".claude/specs/999_${ACTUAL_TOPIC}"
  PLAN_PATH="${TOPIC_PATH}/plans/001_${ACTUAL_TOPIC}_plan.md"

  # Assert plan path contains topic name
  if [[ "$PLAN_PATH" =~ $EXPECTED_TOPIC ]]; then
    echo "  ✓ Plan path contains topic name"
  else
    echo "  ✗ Plan path missing topic name: $PLAN_PATH"
    return 1
  fi

  # Assert plan path is NOT generic
  if [[ "$PLAN_PATH" =~ "001_implementation.md" ]]; then
    echo "  ✗ Plan path uses generic name (regression detected)"
    return 1
  else
    echo "  ✓ Plan path is not generic"
  fi

  echo "  Test passed: Plan naming is descriptive"
  return 0
}
```

**Testing**:
```bash
# Run the new test
cd /home/benjamin/.config/.claude/tests
./test_orchestration_commands.sh

# Should see:
# Testing coordinate plan naming pattern...
#   ✓ Plan path contains topic name
#   ✓ Plan path is not generic
#   Test passed: Plan naming is descriptive
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Test added to test_orchestration_commands.sh
- [ ] Test passes with fixed coordinate.md
- [ ] Test would fail with old hardcoded path (verify regression detection)
- [ ] Git commit created: `test(640): complete Phase 3 - Add plan naming regression test`

### Phase 4: Update Documentation
dependencies: [1, 2]

**Objective**: Document the plan naming convention in coordinate command guide

**Complexity**: Low

**Tasks**:
- [ ] Read coordinate-command-guide.md to find appropriate section (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md)
- [ ] Add "Plan Naming Convention" section with algorithm description (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md)
- [ ] Include examples of descriptive vs generic names (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md)
- [ ] Cross-reference topic-utils.sh sanitize_topic_name() function (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md)
- [ ] Add note about state persistence of PLAN_PATH (file: /home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md)

**Documentation Content**:
```markdown
## Plan Naming Convention

Plans created by /coordinate follow a descriptive naming pattern:

**Format**: `{NNN}_{topic_name}_plan.md`

Where:
- **NNN**: Three-digit sequential number (001, 002, 003...)
- **topic_name**: Sanitized workflow description (via sanitize_topic_name())

**Sanitization Algorithm** (from topic-utils.sh):
1. Extract meaningful path components (last 2-3 segments)
2. Remove filler words ("research", "analyze", "the", "to", "for")
3. Filter stopwords (40+ common English words)
4. Convert to lowercase snake_case
5. Truncate to 50 characters preserving whole words

**Examples**:
- Workflow: "fix authentication bug" → Plan: `001_fix_authentication_bug_plan.md`
- Workflow: "implement user dashboard" → Plan: `002_implement_user_dashboard_plan.md`
- Workflow: "research /nvim/docs directory" → Plan: `003_nvim_docs_directory_plan.md`

**Why Descriptive Names**:
- Provides context at a glance without opening file
- Enables grep/find by feature keywords
- Maintains consistency with topic directory naming
- Improves repository navigation and discovery

**NEVER** use generic names like "001_implementation.md" - these provide no context and defeat the purpose of topic-based organization.

**Implementation Note**: PLAN_PATH is calculated by workflow-initialization.sh and persisted across bash blocks via state-persistence.sh. The /coordinate command trusts this calculated value rather than recalculating or hardcoding paths.
```

**Testing**:
```bash
# Verify documentation is accurate
cd /home/benjamin/.config/.claude/docs/guides
grep -A 10 "Plan Naming Convention" coordinate-command-guide.md

# Test examples match actual sanitize_topic_name() behavior
source /home/benjamin/.config/.claude/lib/topic-utils.sh
sanitize_topic_name "fix authentication bug"
# Should output: fix_authentication_bug
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Documentation section added to coordinate-command-guide.md
- [ ] Examples tested and verified against actual algorithm
- [ ] Cross-references to related files included
- [ ] Git commit created: `docs(640): complete Phase 4 - Document plan naming convention`

### Phase 5: End-to-End Validation
dependencies: [1, 2, 3, 4]

**Objective**: Verify the complete fix works in real /coordinate workflow

**Complexity**: Medium

**Tasks**:
- [ ] Run /coordinate with test workflow description (e.g., "fix example bug")
- [ ] Verify plan file created with descriptive name (not "001_implementation.md")
- [ ] Verify PLAN_PATH variable logged correctly in coordinate output
- [ ] Verify plan agent receives correct path in prompt
- [ ] Check state file contains PLAN_PATH with descriptive name
- [ ] Run full test suite to ensure no regressions
- [ ] Clean up test artifacts

**Test Workflow**:
```bash
# Full end-to-end test
/coordinate "fix example bug for testing plan naming"

# Expected behavior:
# 1. Topic created: .claude/specs/{NNN}_fix_example_bug_testing_plan_naming/
# 2. Plan created: {topic}/plans/001_fix_example_bug_testing_plan_naming_plan.md
# 3. DEBUG output shows correct PLAN_PATH
# 4. Verification checkpoint passes
# 5. Plan content matches workflow description

# Verify plan file exists with descriptive name
find .claude/specs -name "001_*_plan.md" -path "*/plans/*" | tail -1
# Should NOT find "001_implementation.md"
# Should find descriptive name matching workflow

# Check state file
LATEST_STATE=$(ls -t ~/.claude/tmp/workflow_coordinate_*.sh | head -1)
grep "PLAN_PATH=" "$LATEST_STATE"
# Should show: PLAN_PATH=".claude/specs/{NNN}_fix_example_bug.../plans/001_fix_example_bug..._plan.md"
```

**Validation Checklist**:
- [ ] Descriptive plan filename created
- [ ] PLAN_PATH variable correct in debug output
- [ ] State file contains correct PLAN_PATH
- [ ] Verification checkpoint passes
- [ ] No "001_implementation.md" files created
- [ ] Test suite passes (all tests)
- [ ] No error messages during execution

**Testing**:
```bash
# Run complete test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Verify test_orchestration_commands passes
./test_orchestration_commands.sh

# Specific test for plan naming
grep -A 20 "test_coordinate_plan_naming" test_orchestration_commands.sh
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] End-to-end test passes with descriptive naming
- [ ] No regressions in test suite (100% pass rate maintained)
- [ ] Test artifacts cleaned up
- [ ] Git commit created: `test(640): complete Phase 5 - End-to-end validation`

## Testing Strategy

### Unit Testing
- Test sanitize_topic_name() function with various inputs
- Test state persistence of PLAN_PATH variable
- Test validation logic for empty/missing PLAN_PATH

### Integration Testing
- Test /coordinate through planning phase with mock workflow
- Test PLAN_PATH flows from initialization through verification
- Test state loading/saving across bash block boundaries

### End-to-End Testing
- Run /coordinate with real workflow description
- Verify descriptive plan filename created
- Verify no generic "001_implementation.md" files

### Regression Prevention
- Automated test in test_orchestration_commands.sh
- Test would fail if hardcoded path re-introduced
- Test verifies plan name contains workflow keywords

## Documentation Requirements

Files to update:
1. **coordinate-command-guide.md**: Add "Plan Naming Convention" section with algorithm, examples, and rationale
2. **bash-block-execution-model.md**: Already documents state persistence pattern (verify PLAN_PATH example included)
3. **directory-protocols.md**: Already documents plan naming best practices (verify consistency)

No new documentation files needed - update existing guides.

## Dependencies

### External Dependencies
- None (all fixes within existing codebase)

### Library Dependencies
- workflow-initialization.sh (already exists, exports PLAN_PATH correctly)
- state-persistence.sh (already exists, needs PLAN_PATH added to state)
- topic-utils.sh (already exists, sanitize_topic_name() works correctly)
- verification-helpers.sh (already exists, verify_file_created() checks path)

### Prerequisites
- Understanding of bash subprocess isolation pattern
- Understanding of state-persistence.sh GitHub Actions pattern
- Familiarity with coordinate.md state machine architecture

## Risk Assessment

### Low Risk
- Fix is localized to coordinate.md (minimal surface area)
- Library functions already work correctly (no library changes needed)
- Regression test prevents future breakage
- State persistence pattern well-established

### Potential Issues
1. **State Corruption**: If PLAN_PATH not saved to state, bash block 2 will error (fail-fast behavior desired)
2. **Agent Mismatch**: Plan agent may create file at different path than coordinate expects (verification checkpoint will catch this)
3. **Naming Edge Cases**: sanitize_topic_name() may produce unexpected names for certain inputs (covered by existing tests)

### Mitigation Strategies
- Validation logic in Phase 2 catches missing PLAN_PATH early
- Verification checkpoint in coordinate.md fails-fast if file not found
- Diagnostic echo statements aid debugging
- Regression test prevents re-introduction of hardcoded path

## Notes

### Research Insights
- The regression was a side-effect of state machine migration (large refactor increased risk of variable assignment errors)
- workflow-initialization.sh already had correct implementation all along
- Only coordinate.md needed fixing (not a systemic issue across orchestrators)

### Design Decisions
- Trust library-calculated PLAN_PATH rather than recalculating in coordinate.md (single source of truth)
- Use state persistence for cross-block variable access (follows bash-block-execution-model.md patterns)
- Add validation rather than silent fallback (fail-fast philosophy from CLAUDE.md)
- Descriptive naming enables better repository navigation (aligns with directory-protocols.md)

### Future Considerations
- Consider adding PLAN_PATH to standard state persistence template for all orchestrators
- Consider adding assertion to workflow-initialization.sh that PLAN_PATH contains TOPIC_NAME (prevent silent regressions)
- Document this pattern in orchestration-best-practices.md (other commands may have similar issues)
