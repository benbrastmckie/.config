# Commands TODO.md Update Integration Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Systematic TODO.md update integration across all commands
- **Status**: [COMPLETE]
- **Estimated Hours**: 3-5 hours
- **Complexity Score**: 42.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Commands TODO.md Update Integration Research](../reports/001-commands-todo-update-integration.md)

## Overview

Research reveals that 8 of 9 artifact-creating commands already implement TODO.md updates using the `trigger_todo_update()` helper function. However, the user's perception that "none of the commands update TODO.md" indicates a visibility and reliability issue rather than missing integration. Two previous implementation attempts (specs 991 and 997) have addressed this feature, with spec 997 fixing a broken pattern where 5 commands were attempting to execute markdown files directly.

**Current State**:
- 8 commands integrated: /plan, /research, /repair, /debug, /errors, /revise, /build, /implement
- 1 missing: /test (no TODO.md integration)
- Updates are silent (suppressed with `>/dev/null 2>&1`)
- Non-blocking design (failures don't propagate to user)
- Integration guide exists but has outdated examples

**Root Issues**:
1. Silent execution makes updates invisible to users
2. Non-blocking design means failures go unnoticed
3. Integration guide shows outdated patterns
4. /test command lacks integration despite having TEST_COMPLETE signal
5. No systematic verification that updates are working

## Research Summary

Key findings from research report:

**Infrastructure Status**:
- Complete TODO.md update system exists with `trigger_todo_update()` helper
- Integration guide documents 7 commands (517 lines)
- Two previous fix attempts (specs 991, 997) indicate recurring issues
- Spec 997 fixed broken pattern where commands tried to execute `.claude/commands/todo.md` as bash script

**Implementation Pattern**:
- All integrated commands source `todo-functions.sh`
- Call `trigger_todo_update("reason")` after artifact creation
- Updates are silent (`>/dev/null 2>&1`) per Output Formatting Standards
- Non-blocking design (`|| true` pattern, always returns 0)

**Visibility Problem**:
- Only output is single line: `✓ Updated TODO.md (reason)`
- Warning messages suppressed by output redirection
- Users may miss brief success message
- No verification that TODO.md actually changed

**Recommended Approach**:
1. Add /test command integration (only missing command)
2. Enhance update visibility without violating output standards
3. Update integration guide with correct patterns
4. Add verification/testing infrastructure
5. Document reliability improvement recommendations

## Success Criteria

- [ ] /test command integrates TODO.md updates using `trigger_todo_update()`
- [ ] Integration guide updated with correct patterns (no markdown file execution)
- [ ] Integration guide includes /test command in patterns table
- [ ] Update visibility enhanced with clearer console output
- [ ] Verification commands added for testing integration reliability
- [ ] Documentation updated to reflect two previous implementation attempts
- [ ] All 9 artifact-creating commands have consistent integration patterns
- [ ] Testing infrastructure validates TODO.md updates after command execution

## Technical Design

### Architecture Overview

The plan addresses both the missing /test integration and the broader visibility/reliability issues:

```
┌─────────────────────────────────────────────────────────────┐
│ Command Execution                                           │
├─────────────────────────────────────────────────────────────┤
│ 1. Execute command logic (create/modify artifacts)         │
│ 2. Emit signal (PLAN_CREATED, REPORT_CREATED, etc.)        │
│ 3. Source todo-functions.sh (fail-fast if missing)         │
│ 4. Call trigger_todo_update("descriptive reason")          │
│    ├─ Delegates to /todo for full scan                     │
│    ├─ Suppresses /todo output (2>/dev/null)                │
│    └─ Returns 0 (non-blocking, warning on failure)         │
│ 5. Display enhanced checkpoint message                     │
│    └─ Format: "✓ Updated TODO.md (reason)"                 │
└─────────────────────────────────────────────────────────────┘
```

### /test Command Integration Pattern

Add TODO.md update after successful test completion (all tests passed, coverage threshold met):

**Location**: After Block 4 loop termination on SUCCESS condition (after line ~418)

**Pattern**:
```bash
# === UPDATE TODO.md ===
# Source todo-functions.sh for trigger_todo_update()
source "${CLAUDE_PROJECT_DIR}/.claude/lib/todo/todo-functions.sh" 2>/dev/null || {
  echo "WARNING: Failed to source todo-functions.sh for TODO.md update" >&2
}

# Trigger TODO.md update (non-blocking)
if type trigger_todo_update &>/dev/null; then
  trigger_todo_update "test phase completed with ${COVERAGE}% coverage"
fi
```

**Conditional Logic**:
- Only trigger on SUCCESS terminal state (all tests passed AND coverage met)
- Do NOT trigger on STUCK or MAX_ITERATIONS states
- Include coverage metric in reason string for traceability

### Visibility Enhancement Strategy

**Problem**: Silent updates make integration invisible
**Solution**: Enhance checkpoint output without violating Output Formatting Standards

**Option 1: Enhanced Single-Line Output** (RECOMMENDED):
```bash
echo "✓ TODO.md updated: $reason"
```

**Option 2: Formatted Block** (if more visibility needed):
```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ TODO.md updated: $reason"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

**Trade-offs**:
- Option 1: Minimal change, standards-compliant, sufficient visibility
- Option 2: High visibility, but may violate "single line checkpoint" standard

**Recommendation**: Use Option 1 (enhanced single-line) to maintain standards compliance while improving visibility.

### Integration Guide Updates

**Files to Update**:
- `/home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md`

**Changes Required**:
1. Fix Pattern A example (lines 29-37): Replace `.claude/commands/todo.md` execution with `trigger_todo_update()` call
2. Add Pattern H: /test command integration (after Pattern G)
3. Update scope table (line 11-22) to include /test
4. Document historical context (two previous attempts: specs 991, 997)
5. Update troubleshooting section with common failure modes

### Standards Compliance

**Code Standards**:
- Three-tier sourcing pattern: Source `todo-functions.sh` with fail-fast handler
- Non-blocking design: `trigger_todo_update()` always returns 0
- Error resilience: Warning on failure, no command blocking

**Output Formatting Standards**:
- Single checkpoint line per operation: `✓ Updated TODO.md (reason)`
- Suppress /todo output: `>/dev/null 2>&1` in `trigger_todo_update()`
- No interim output during TODO.md update

**Testing Protocols**:
- Integration tests verify TODO.md contains expected entries
- Graceful degradation tests ensure commands succeed even if /todo fails

### Verification Infrastructure

Add verification commands for testing integration reliability:

**Command 1: Verify TODO.md Update After Command**
```bash
# Test /plan updates TODO.md
BEFORE_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
/plan "test feature for verification"
AFTER_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
[ "$BEFORE_HASH" != "$AFTER_HASH" ] && echo "✓ TODO.md updated" || echo "✗ TODO.md unchanged"
```

**Command 2: Verify Entry Presence**
```bash
# Verify specific entry appears in TODO.md
/plan "integration test feature"
grep -q "integration test feature" .claude/TODO.md && echo "✓ Entry found" || echo "✗ Entry missing"
```

**Command 3: Verify Section Placement**
```bash
# Verify entry in correct section (Not Started for new plans)
/plan "section placement test"
awk '/## Not Started/,/## Backlog/' .claude/TODO.md | grep -q "section placement test" && echo "✓ Correct section" || echo "✗ Wrong section"
```

## Implementation Phases

### Phase 1: Add /test Command Integration [COMPLETE]
dependencies: []

**Objective**: Integrate TODO.md updates into /test command using standardized pattern

**Complexity**: Low

**Tasks**:
- [x] Read /test command implementation (commands/test.md)
- [x] Identify SUCCESS terminal state location (after Block 4 loop exit)
- [x] Add todo-functions.sh sourcing with fail-fast handler
- [x] Add `trigger_todo_update("test phase completed with ${COVERAGE}% coverage")` call
- [x] Verify conditional logic (only on SUCCESS, not STUCK/MAX_ITERATIONS)
- [x] Test integration with sample test plan
- [x] Verify TODO.md contains test completion entry

**Testing**:
```bash
# Test /test updates TODO.md on successful completion
TEST_PLAN=".claude/specs/test_integration/plans/001-test.md"
BEFORE_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
/test "$TEST_PLAN" --coverage-threshold=80
AFTER_HASH=$(md5sum .claude/TODO.md | cut -d' ' -f1)
[ "$BEFORE_HASH" != "$AFTER_HASH" ] && echo "✓ TODO.md updated" || echo "✗ TODO.md unchanged"

# Verify entry includes coverage metric
grep -q "test phase completed with.*coverage" .claude/TODO.md
```

**Expected Duration**: 1 hour

### Phase 2: Enhance Update Visibility [COMPLETE]
dependencies: [1]

**Objective**: Improve visibility of TODO.md updates while maintaining Output Formatting Standards compliance

**Complexity**: Low

**Tasks**:
- [x] Review Output Formatting Standards for checkpoint format requirements
- [x] Update `trigger_todo_update()` in todo-functions.sh (lines 1120-1132)
- [x] Change success message format: `echo "✓ TODO.md updated: $reason"`
- [x] Verify all 9 commands use consistent checkpoint format
- [x] Test visibility improvement with multiple commands
- [x] Document rationale for enhanced format in code comments

**Testing**:
```bash
# Verify enhanced checkpoint format appears
/plan "visibility test" | grep -q "✓ TODO.md updated: plan created"
/research "visibility research" | grep -q "✓ TODO.md updated: research report created"
/test "test_plan.md" | grep -q "✓ TODO.md updated: test phase completed"
```

**Expected Duration**: 1 hour

### Phase 3: Update Integration Guide [COMPLETE]
dependencies: [1, 2]

**Objective**: Correct outdated patterns in integration guide and document complete command coverage

**Complexity**: Low

**Tasks**:
- [x] Read integration guide (docs/guides/development/command-todo-integration-guide.md)
- [x] Fix Pattern A (lines 29-37): Replace broken `.claude/commands/todo.md` execution with `trigger_todo_update()` pattern
- [x] Add Pattern H: /test command integration example
- [x] Update scope table (lines 11-22) to include /test command
- [x] Add "Historical Context" section documenting specs 991 and 997
- [x] Update troubleshooting section with common failure modes
- [x] Verify all 8 patterns use correct `trigger_todo_update()` syntax
- [x] Review anti-patterns section for completeness

**Testing**:
```bash
# Verify integration guide has correct patterns
grep -q "trigger_todo_update" .claude/docs/guides/development/command-todo-integration-guide.md

# Verify /test documented
grep -q "/test" .claude/docs/guides/development/command-todo-integration-guide.md

# Verify no references to executing markdown files
! grep -q "bash -c.*todo.md" .claude/docs/guides/development/command-todo-integration-guide.md
```

**Expected Duration**: 1.5 hours

### Phase 4: Add Verification Infrastructure [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Create testing utilities to systematically verify TODO.md integration reliability

**Complexity**: Medium

**Tasks**:
- [x] Create verification script: `.claude/scripts/verify-todo-integration.sh`
- [x] Implement hash-based update detection (before/after command execution)
- [x] Implement entry presence verification (grep-based)
- [x] Implement section placement verification (awk-based)
- [x] Add test for all 9 commands (plan, research, repair, debug, errors, revise, build, implement, test)
- [x] Document verification script usage in integration guide
- [x] Add verification to integration test suite (.claude/tests/integration/)
- [x] Create smoke test for quick validation

**Script Structure**:
```bash
#!/bin/bash
# verify-todo-integration.sh
# Purpose: Systematically verify TODO.md updates after command execution

verify_command_updates_todo() {
  local command="$1"
  local test_args="$2"

  BEFORE=$(md5sum .claude/TODO.md | cut -d' ' -f1)
  eval "$command $test_args" >/dev/null 2>&1
  AFTER=$(md5sum .claude/TODO.md | cut -d' ' -f1)

  if [ "$BEFORE" != "$AFTER" ]; then
    echo "✓ $command updates TODO.md"
    return 0
  else
    echo "✗ $command does NOT update TODO.md"
    return 1
  fi
}

# Test all 9 commands
verify_command_updates_todo "/plan" "\"test feature\""
verify_command_updates_todo "/research" "\"test research\""
# ... etc for all commands
```

**Testing**:
```bash
# Run verification script
bash .claude/scripts/verify-todo-integration.sh

# Expected output: 9/9 commands pass verification
```

**Expected Duration**: 1.5 hours

### Phase 5: Documentation and Validation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Complete documentation updates and validate all changes against standards

**Complexity**: Low

**Tasks**:
- [x] Update command-specific documentation for /test (add TODO.md update note)
- [x] Update Command Reference to reflect all 9 commands have TODO.md integration
- [x] Add "TODO.md Integration" subsection to Command Authoring Standards
- [x] Document recommended verification approach for new commands
- [x] Run all verification scripts to ensure no regressions
- [x] Validate against Output Formatting Standards compliance
- [x] Validate against Command Authoring Standards compliance
- [x] Create summary document for future reference

**Testing**:
```bash
# Validate standards compliance
bash .claude/scripts/validate-all-standards.sh --all

# Run full verification suite
bash .claude/scripts/verify-todo-integration.sh

# Check documentation for completeness
grep -r "trigger_todo_update" .claude/docs/ | wc -l  # Should find multiple references
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Test `trigger_todo_update()` function in isolation
- Verify non-blocking behavior (returns 0 on failure)
- Test warning message output on /todo failure

### Integration Testing
- Verify each of 9 commands updates TODO.md after execution
- Test hash-based change detection (before/after comparison)
- Verify entries appear in correct TODO.md sections
- Test graceful degradation (commands succeed even if /todo fails)

### Regression Testing
- Ensure no existing commands broke during changes
- Verify output format remains standards-compliant
- Test checkpoint message format consistency

### Verification Commands
```bash
# Comprehensive integration test
bash .claude/scripts/verify-todo-integration.sh

# Individual command test
/plan "integration test feature"
grep -q "integration test feature" .claude/TODO.md && echo "PASS" || echo "FAIL"

# Section placement test
awk '/## Not Started/,/## Backlog/' .claude/TODO.md | grep -q "integration test feature"

# Graceful degradation test
mv .claude/commands/todo.md .claude/commands/todo.md.bak
/plan "degradation test" && echo "PASS: Command succeeded despite /todo unavailable"
mv .claude/commands/todo.md.bak .claude/commands/todo.md
```

### Coverage Requirements
- All 9 artifact-creating commands tested
- Both success and failure paths validated
- Documentation accuracy verified

## Documentation Requirements

### Files to Update
1. `/home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md`
   - Fix Pattern A example (broken markdown execution)
   - Add Pattern H for /test command
   - Update scope table to include /test
   - Add historical context section (specs 991, 997)
   - Update troubleshooting with common failure modes

2. `/home/benjamin/.config/.claude/commands/test.md`
   - Add note about automatic TODO.md updates after successful completion
   - Document conditional logic (only on SUCCESS state)

3. `/home/benjamin/.config/.claude/docs/reference/standards/command-reference.md`
   - Update /test command description to note TODO.md integration
   - Verify all 9 commands documented with TODO.md integration

4. `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md`
   - Add "TODO.md Integration" subsection with pattern template
   - Reference integration guide for complete examples

### New Documentation
1. Verification script documentation in integration guide
2. Summary document capturing lessons from three implementation attempts

## Dependencies

### External Dependencies
- Existing `trigger_todo_update()` function in todo-functions.sh (lines 1112-1132)
- /todo command functionality (must be invokable)
- Integration guide existence (command-todo-integration-guide.md)

### Internal Dependencies
- Phase 2 depends on Phase 1 (need /test integrated before visibility enhancement)
- Phase 3 depends on Phases 1-2 (documentation reflects actual implementation)
- Phase 4 depends on Phases 1-3 (verification tests actual implementation)
- Phase 5 depends on all previous phases (final validation)

### Standards Dependencies
- Output Formatting Standards (single-line checkpoints, output suppression)
- Command Authoring Standards (block consolidation, error handling)
- TODO Organization Standards (section hierarchy, entry format)
- Code Standards (three-tier sourcing pattern, non-blocking design)

## Risk Assessment

### Low Risk
- Adding /test integration (follows established pattern)
- Enhancing visibility (minimal change to output format)
- Documentation updates (no code changes)

### Medium Risk
- Verification infrastructure (new scripts, testing approach)
- Integration guide corrections (ensuring accuracy of all patterns)

### Mitigation Strategies
1. Test /test integration thoroughly before declaring complete
2. Validate enhanced output format against Output Formatting Standards
3. Review integration guide updates with previous implementation specs (991, 997)
4. Add verification scripts to integration test suite for ongoing validation
5. Document all changes for future troubleshooting

## Notes

### Historical Context
This is the third attempt to ensure systematic TODO.md updates across commands:

1. **Spec 991** (Commands TODO.md Tracking Refactor): Added integration to 3 commands (/repair, /errors, /debug) using `trigger_todo_update()` pattern
2. **Spec 997** (TODO.md Update Pattern Fix): Fixed broken pattern in 5 commands (/plan, /build, /implement, /revise, /research) that were trying to execute markdown files as bash scripts
3. **This Plan (Spec 015)**: Adds missing /test integration, enhances visibility, and creates verification infrastructure to prevent future regressions

### User Perception Issue
The user's observation that "none of the commands update TODO.md" is partially incorrect - 8/9 commands already implement updates. The perception likely stems from:
- Silent execution (suppressed output makes updates invisible)
- Non-blocking design (failures don't propagate to user awareness)
- Timing issues (TODO.md may not refresh in editor immediately)

This plan addresses the root cause (visibility/reliability) while completing the missing /test integration.

### Future Recommendations
1. Consider adding `--verbose` flag to commands for debugging TODO.md updates
2. Add pre-commit hook validating `trigger_todo_update()` usage patterns
3. Create integration test suite for ongoing verification
4. Document expected TODO.md update behavior in command test suites
5. Consider adding TODO.md entry count to console summary (before/after comparison)
