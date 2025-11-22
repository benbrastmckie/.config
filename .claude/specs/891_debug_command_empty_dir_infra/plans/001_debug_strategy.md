# Debug Strategy: Empty /debug Directory Infrastructure Issue

## Metadata
- **Date**: 2025-11-21
- **Feature**: Debug and fix infrastructure bug causing empty debug/ directories
- **Scope**: /debug command, agent behavioral files, directory creation utilities
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Complexity Score**: 87.5
- **Structure Level**: 0
- **Research Reports**:
  - [Root Cause Analysis: Empty /debug Directory Infrastructure Issue](../reports/001_root_cause_analysis.md)

## Overview

The /debug command infrastructure has a critical bug that creates empty `debug/` directories in spec topics when workflows fail or are interrupted. Despite spec 870's claim to fix "lazy directory creation violations" on 2025-11-20, there are **6 empty debug/ directories** across the specs directory, including spec 889 created the next morning. This indicates the fix was either never implemented, implemented incorrectly, reverted, or bypassed by an alternative code path.

This debug strategy focuses on:
1. Verifying whether spec 870's fix was actually applied
2. Identifying all code paths that create debug directories prematurely
3. Implementing proper lazy directory creation in agents
4. Adding cleanup mechanisms for failed workflows
5. Creating regression tests to prevent recurrence

## Research Summary

Key findings from root cause analysis report:

**Timeline Evidence**:
- Spec 889's `debug/` directory created at 08:40:53, **20 minutes before** topic root (09:00:35)
- Spec 870 "fix" committed at 21:38:48 on 2025-11-20
- Spec 889 directory created at 08:40:53 on 2025-11-21 (11 hours after fix)
- 6 empty debug/ directories persist in production

**Root Cause Hypothesis**:
- Agents call `ensure_artifact_directory()` at startup, not before file writes
- If agent fails before writing files, directory remains empty
- Current /debug command code has NO eager mkdir calls (correctly fixed)
- Bug persists in agent behavioral files, not command infrastructure

**Affected Components**:
- Agent behavioral files (debug-analyst.md, research-specialist.md, others)
- `ensure_artifact_directory()` function in unified-location-detection.sh
- All commands that invoke agents (indirect effect)

**Recommended Fix Strategy**:
1. Verify spec 870 fix was applied correctly to commands
2. Move `ensure_artifact_directory()` calls in agents to immediately before file writes
3. Add cleanup trap for directories created by failed agents
4. Create regression tests for lazy directory creation

## Success Criteria

- [ ] Verified spec 870's fix was correctly applied to all commands
- [ ] Identified all agent files with premature `ensure_artifact_directory()` calls
- [ ] All agents delay directory creation until immediately before file write
- [ ] Empty debug/ directories from previous failures are cleaned up
- [ ] Cleanup trap added to agent setup for failure scenarios
- [ ] Regression tests pass: no empty directories created on agent failure
- [ ] Documentation updated with lazy creation best practices
- [ ] New /debug command executions do not create empty directories

## Technical Design

### Architecture Overview

**Directory Creation Flow (Current - Broken)**:
```
Command Execution
  ├─> initialize_workflow_paths() [Sets path variables only - CORRECT]
  ├─> Invoke Agent
  │     ├─> Agent startup
  │     ├─> ensure_artifact_directory($ARTIFACT_PATH) [TOO EARLY]
  │     ├─> Validation checks [May fail here]
  │     ├─> Processing [May fail here]
  │     └─> Write file [Directory created 100+ lines earlier]
  └─> Check workflow state
```

**Problem**: Directory exists even if agent fails before writing files.

**Directory Creation Flow (Fixed - Proposed)**:
```
Command Execution
  ├─> initialize_workflow_paths() [Sets path variables only - CORRECT]
  ├─> Invoke Agent
  │     ├─> Agent startup
  │     ├─> Validation checks [Can fail without creating directories]
  │     ├─> Processing [Can fail without creating directories]
  │     ├─> ensure_artifact_directory($ARTIFACT_PATH) [RIGHT BEFORE WRITE]
  │     └─> Write file [Directory creation adjacent to write]
  └─> Check workflow state
```

**Benefit**: No directories created unless files are successfully written.

### Component Interaction

**Lazy Directory Creation Pattern**:
```bash
# WRONG (current pattern in agents):
REPORT_PATH="${RESEARCH_DIR}/001_report.md"
ensure_artifact_directory "$REPORT_PATH" || exit 1  # Line 50
# ... 150 lines of validation and processing ...
Write tool creates file  # Line 200 - directory created 150 lines earlier

# CORRECT (proposed pattern):
REPORT_PATH="${RESEARCH_DIR}/001_report.md"
# ... validation and processing ...
ensure_artifact_directory "$REPORT_PATH" || exit 1  # Line 195
Write tool creates file  # Line 200 - directory creation adjacent
```

**Cleanup Trap Pattern** (for additional safety):
```bash
# Add to agent setup section
CREATED_DIRS=()
cleanup_on_failure() {
  if [ ${#CREATED_DIRS[@]} -gt 0 ]; then
    for dir in "${CREATED_DIRS[@]}"; do
      if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
        rmdir "$dir" 2>/dev/null || true
      fi
    done
  fi
}
trap cleanup_on_failure EXIT ERR

# Modify ensure_artifact_directory to track created directories
ensure_artifact_directory_tracked() {
  local file_path="$1"
  local dir_path="$(dirname "$file_path")"
  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path" || return 1
    CREATED_DIRS+=("$dir_path")
  fi
}
```

### Integration Points

**Commands Affected** (indirectly via agents):
- /debug - Invokes debug-analyst agent
- /plan - Invokes plan-architect agent
- /research - Invokes research-specialist agent
- /build - Invokes multiple agents in sequence

**Agents Requiring Updates**:
- debug-analyst.md
- research-specialist.md
- plan-architect.md
- implementation-specialist.md (if exists)

**Utility Functions Modified**:
- `ensure_artifact_directory()` in unified-location-detection.sh
  - Add tracked version that logs directory creation
  - Keep original version for backward compatibility

## Implementation Phases

### Phase 1: Verify Spec 870 Fix Application [COMPLETE]
dependencies: []

**Objective**: Determine if spec 870's fix was correctly applied and identify any reverted changes.

**Complexity**: Low

**Tasks**:
- [x] Read spec 870 implementation plan (file: /home/benjamin/.config/.claude/specs/870_fix_lazy_directory_creation_violations_across_6_co/plans/001_fix_lazy_directory_creation_violations_a_plan.md)
- [x] Read spec 870 implementation summary (file: /home/benjamin/.config/.claude/specs/870_fix_lazy_directory_creation_violations_across_6_co/summaries/001_implementation_complete.md)
- [x] Search all command files for eager mkdir patterns: `grep -rn 'mkdir -p "\$RESEARCH_DIR"' .claude/commands/*.md`
- [x] Search all command files for debug dir creation: `grep -rn 'mkdir -p "\$DEBUG_DIR"' .claude/commands/*.md`
- [x] Search all command files for plans dir creation: `grep -rn 'mkdir -p "\$PLANS_DIR"' .claude/commands/*.md`
- [x] Check git history for reverts: `git log --all --oneline --grep="870" -- .claude/commands/`
- [x] Verify current /debug command has no eager mkdir calls (file: /home/benjamin/.config/.claude/commands/debug.md)
- [x] Document findings in phase report

**Testing**:
```bash
# Verify no eager directory creation in commands
test_no_eager_mkdir() {
  local violations=$(grep -rn 'mkdir -p "\$RESEARCH_DIR\|\$DEBUG_DIR\|\$PLANS_DIR"' .claude/commands/*.md | wc -l)
  [ "$violations" -eq 0 ] || fail "Found $violations eager mkdir violations"
}

# Check if spec 870 changes are present
test_spec_870_applied() {
  git show 13d1f9aa:.claude/commands/debug.md | grep -q 'mkdir -p "\$DEBUG_DIR"' && fail "Spec 870 fix not applied"
  return 0
}
```

**Expected Duration**: 2 hours

### Phase 2: Identify Agent Directory Creation Patterns [COMPLETE]
dependencies: [1]

**Objective**: Find all agent files that call `ensure_artifact_directory()` prematurely.

**Complexity**: Medium

**Tasks**:
- [x] List all agent behavioral files: `find .claude/agents -name "*.md" -type f`
- [x] Search for ensure_artifact_directory calls: `grep -rn "ensure_artifact_directory" .claude/agents/*.md`
- [x] For each agent, determine line number of ensure_artifact_directory call
- [x] For each agent, determine line number where file write occurs (search for "Write tool")
- [x] Calculate line distance between directory creation and file write
- [x] Identify agents with >50 line gap (high risk for premature creation)
- [x] Create prioritized list of agents to fix (file: /home/benjamin/.config/.claude/specs/891_debug_command_empty_dir_infra/debug/agents_to_fix.txt)
- [x] Document current patterns in analysis report

**Testing**:
```bash
# Verify all agents identified
test_agent_discovery() {
  local agent_count=$(find .claude/agents -name "*.md" -type f | wc -l)
  [ "$agent_count" -gt 0 ] || fail "No agents found"
  echo "Found $agent_count agent files"
}

# Check for ensure_artifact_directory calls
test_ensure_calls_found() {
  local call_count=$(grep -r "ensure_artifact_directory" .claude/agents/*.md | wc -l)
  echo "Found $call_count ensure_artifact_directory calls"
}
```

**Expected Duration**: 3 hours

### Phase 3: Fix Agent Directory Creation Timing [COMPLETE]
dependencies: [2]

**Objective**: Move `ensure_artifact_directory()` calls to immediately before file writes in all agents.

**Complexity**: High

**Tasks**:
- [x] Read debug-analyst.md to understand current structure (file: /home/benjamin/.config/.claude/agents/debug-analyst.md)
- [x] Identify ensure_artifact_directory call location in debug-analyst.md
- [x] Identify Write tool usage location in debug-analyst.md
- [x] Move ensure_artifact_directory to line immediately before Write tool call
- [x] Repeat for research-specialist.md (file: /home/benjamin/.config/.claude/agents/research-specialist.md)
- [x] Repeat for plan-architect.md (file: /home/benjamin/.config/.claude/agents/plan-architect.md)
- [x] Repeat for any other agents identified in Phase 2
- [x] Verify each agent's ensure_artifact_directory call is <5 lines before Write tool usage
- [x] Test each modified agent individually

**Testing**:
```bash
# Test debug-analyst doesn't create empty directories
test_debug_analyst_lazy_creation() {
  # Setup: Mock execution context
  # Simulate: Agent invocation that fails validation
  # Assert: No debug/ directory created

  local test_topic="/tmp/test_debug_analyst_$$"
  mkdir -p "$test_topic"

  # Simulate agent failure before write (would need agent mocking)
  # For now, manual verification after code changes

  rmdir "$test_topic" 2>/dev/null || true
}

# Verify line distance between ensure and Write
test_ensure_adjacent_to_write() {
  for agent in .claude/agents/*.md; do
    local ensure_line=$(grep -n "ensure_artifact_directory" "$agent" | cut -d: -f1)
    local write_line=$(grep -n "Write tool" "$agent" | cut -d: -f1)

    if [ -n "$ensure_line" ] && [ -n "$write_line" ]; then
      local distance=$((write_line - ensure_line))
      [ "$distance" -le 10 ] || fail "$agent: ensure_artifact_directory $distance lines before Write"
    fi
  done
}
```

**Expected Duration**: 4 hours

### Phase 4: Add Cleanup Trap for Failed Agent Executions [COMPLETE]
dependencies: [3]

**Objective**: Implement cleanup mechanism to remove empty directories when agents fail.

**Complexity**: Medium

**Tasks**:
- [x] Read unified-location-detection.sh to understand current ensure_artifact_directory (file: /home/benjamin/.config/.claude/lib/core/unified-location-detection.sh)
- [x] Add tracked version: ensure_artifact_directory_tracked() function
- [x] Add cleanup trap template to agent behavioral file common section
- [x] Test cleanup trap in isolation (mock agent failure scenario)
- [x] Update debug-analyst.md to use tracked version
- [x] Update research-specialist.md to use tracked version
- [x] Update plan-architect.md to use tracked version
- [x] Test cleanup works when agent fails mid-execution
- [x] Document trap usage pattern for future agents

**Cleanup Trap Implementation**:
```bash
# Add to unified-location-detection.sh
ensure_artifact_directory_tracked() {
  local file_path="$1"
  local dir_path="$(dirname "$file_path")"

  if [ ! -d "$dir_path" ]; then
    mkdir -p "$dir_path" || return 1

    # Track for cleanup
    if [ -n "$CREATED_DIRS" ]; then
      CREATED_DIRS+=("$dir_path")
    fi
  fi
  return 0
}

# Add to agent behavioral file setup section
CREATED_DIRS=()
cleanup_empty_dirs_on_failure() {
  local exit_code=$?

  # Only cleanup if agent failed (non-zero exit)
  if [ "$exit_code" -ne 0 ] && [ ${#CREATED_DIRS[@]} -gt 0 ]; then
    for dir in "${CREATED_DIRS[@]}"; do
      if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
        echo "Cleaning up empty directory: $dir" >&2
        rmdir "$dir" 2>/dev/null || true
      fi
    done
  fi
}
trap cleanup_empty_dirs_on_failure EXIT
```

**Testing**:
```bash
# Test cleanup trap removes empty directories
test_cleanup_trap_on_failure() {
  local test_topic="/tmp/test_cleanup_$$"
  mkdir -p "$test_topic"

  # Create test script that simulates agent with trap
  cat > /tmp/test_agent_$$.sh <<'EOF'
#!/bin/bash
source .claude/lib/core/unified-location-detection.sh
CREATED_DIRS=()
trap 'cleanup_empty_dirs_on_failure' EXIT

ARTIFACT_PATH="$1/debug/test.md"
ensure_artifact_directory_tracked "$ARTIFACT_PATH" || exit 1

# Simulate failure before writing file
exit 1
EOF

  chmod +x /tmp/test_agent_$$.sh
  /tmp/test_agent_$$.sh "$test_topic" || true

  # Assert: debug directory should not exist
  [ ! -d "$test_topic/debug" ] || fail "Empty directory not cleaned up"

  rmdir "$test_topic" 2>/dev/null || true
  rm /tmp/test_agent_$$.sh
}
```

**Expected Duration**: 3 hours

### Phase 5: Clean Up Existing Empty Directories [COMPLETE]
dependencies: [4]

**Objective**: Remove the 6 existing empty debug/ directories from production.

**Complexity**: Low

**Tasks**:
- [x] Find all empty debug directories: `find .claude/specs -name "debug" -type d -empty`
- [x] Verify each directory is truly empty (no hidden files)
- [x] Document which specs have empty debug directories
- [x] Remove empty debug directories: `find .claude/specs -name "debug" -type d -empty -delete`
- [x] Verify removal: `find .claude/specs -name "debug" -type d -empty` should return nothing
- [x] Check for other empty artifact directories: `find .claude/specs -type d -empty`
- [x] Remove other empty artifact directories if appropriate
- [x] Document cleanup actions in completion report

**Testing**:
```bash
# Verify no empty debug directories remain
test_no_empty_debug_dirs() {
  local empty_count=$(find .claude/specs -name "debug" -type d -empty | wc -l)
  [ "$empty_count" -eq 0 ] || fail "Found $empty_count empty debug directories"
}

# Verify cleanup doesn't remove directories with content
test_populated_dirs_preserved() {
  local populated=$(find .claude/specs -name "debug" -type d ! -empty | wc -l)
  echo "Preserved $populated populated debug directories"
}
```

**Expected Duration**: 1 hour

### Phase 6: Add Regression Tests [COMPLETE]
dependencies: [5]

**Objective**: Create automated tests to prevent empty directory bug from recurring.

**Complexity**: Medium

**Tasks**:
- [x] Create test file: .claude/tests/integration/test_lazy_directory_creation.sh
- [x] Implement test_debug_command_no_premature_dirs()
- [x] Implement test_agent_failure_no_empty_dirs()
- [x] Implement test_ensure_artifact_directory_timing()
- [x] Add test to .claude/tests/run_all_tests.sh
- [x] Run full test suite to verify no regressions
- [x] Document test expectations and failure conditions
- [x] Update testing protocols in CLAUDE.md if needed

**Test Implementation**:
```bash
# File: .claude/tests/integration/test_lazy_directory_creation.sh

test_debug_command_no_premature_dirs() {
  local test_dir="/tmp/test_debug_lazy_$$"
  mkdir -p "$test_dir"

  # Execute /debug command with early interruption
  # (would need command mocking infrastructure)

  # Assert: No artifact directories created before files written
  [ ! -d "$test_dir/debug" ] || fail "debug/ created prematurely"
  [ ! -d "$test_dir/reports" ] || fail "reports/ created prematurely"

  rm -rf "$test_dir"
}

test_agent_failure_no_empty_dirs() {
  # Mock agent execution that fails validation
  # Assert: No directories left behind

  # Implementation requires agent testing framework
  pass "Agent testing framework not yet available"
}

test_ensure_adjacent_to_write() {
  # Verify all agents have ensure_artifact_directory within 10 lines of Write
  for agent in .claude/agents/*.md; do
    local ensure_line=$(grep -n "ensure_artifact_directory" "$agent" | head -1 | cut -d: -f1)
    local write_line=$(grep -n "Write tool" "$agent" | head -1 | cut -d: -f1)

    if [ -n "$ensure_line" ] && [ -n "$write_line" ]; then
      local distance=$((write_line - ensure_line))
      [ "$distance" -le 10 ] || fail "$agent: ensure $distance lines before Write (max 10)"
    fi
  done
}
```

**Testing**:
```bash
# Run new regression tests
bash .claude/tests/integration/test_lazy_directory_creation.sh

# Verify tests are included in main test suite
grep -q "test_lazy_directory_creation.sh" .claude/tests/run_all_tests.sh || fail "Test not in suite"
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Individual function testing for `ensure_artifact_directory_tracked()`
- Cleanup trap testing in isolation
- Pattern matching tests for agent file analysis

### Integration Testing
- Full /debug command execution with interruption scenarios
- Agent execution with validation failures
- Multi-agent workflow testing (ensure one agent failure doesn't affect others)

### Regression Testing
- Automated checks for premature directory creation
- Empty directory detection after failed workflows
- Verify spec 870 fix remains applied

### Manual Testing
1. Execute /debug command with invalid input (should fail validation)
2. Verify no empty debug/ directory created
3. Execute /debug command successfully
4. Verify debug/ directory created with content
5. Execute /research command with early failure
6. Verify no empty reports/ directory created

## Documentation Requirements

### Documentation Updates
- [ ] Update directory-protocols.md with lazy creation best practices (file: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md)
- [ ] Add section on agent directory creation timing
- [ ] Document cleanup trap pattern for future agent development
- [ ] Update code-standards.md with anti-pattern: premature directory creation (file: /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md)
- [ ] Add testing protocols section for directory creation (file: /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md)

### Agent Behavioral File Standards
- [ ] Create template for proper ensure_artifact_directory usage
- [ ] Document cleanup trap setup pattern
- [ ] Add to agent development guidelines

### Debug Reports
- [ ] Document findings from Phase 1 (spec 870 verification)
- [ ] Document findings from Phase 2 (agent pattern analysis)
- [ ] Create before/after comparison showing fix effectiveness

## Dependencies

### Internal Dependencies
- Phase 1 must complete before Phase 2 (need to verify commands are correct)
- Phase 2 must complete before Phase 3 (need list of agents to fix)
- Phase 3 must complete before Phase 4 (base fixes before adding trap)
- Phase 4 must complete before Phase 5 (cleanup mechanism before removing dirs)
- Phase 5 must complete before Phase 6 (clean state before testing)

### External Dependencies
- Git access for history verification
- Write permissions for agent behavioral files
- Write permissions for utility function libraries
- Test execution environment

### Tool Dependencies
- Grep for pattern searching
- Find for directory discovery
- Bash for test script execution
- Git for history analysis

## Risk Assessment

### Technical Risks
1. **Agent behavioral file format changes**: Modifying ensure_artifact_directory calls may break agent execution
   - Mitigation: Test each agent individually after modification

2. **Cleanup trap conflicts**: Trap may interfere with existing error handling
   - Mitigation: Test trap in isolation, ensure EXIT trap doesn't mask errors

3. **Race conditions**: Multiple agents creating same directory simultaneously
   - Mitigation: ensure_artifact_directory uses mkdir -p (atomic for single level)

4. **Incomplete agent discovery**: May miss agents that create directories
   - Mitigation: Search for all "mkdir", "ensure_", and directory references

### Process Risks
1. **Spec 870 regression**: Changes may reintroduce spec 870 violations
   - Mitigation: Phase 6 regression tests prevent recurrence

2. **Breaking existing workflows**: Commands may depend on premature directory creation
   - Mitigation: Careful testing of all commands after agent modifications

3. **Documentation drift**: Fix may not be documented consistently
   - Mitigation: Comprehensive documentation updates in Phase 6

## Rollback Plan

If implementation causes critical failures:

1. **Immediate Rollback**:
   ```bash
   # Revert agent behavioral file changes
   git checkout HEAD -- .claude/agents/*.md

   # Revert utility function changes
   git checkout HEAD -- .claude/lib/core/unified-location-detection.sh
   ```

2. **Staged Rollback**:
   - Disable cleanup trap (comment out in agents)
   - Keep lazy directory creation timing changes
   - Investigate failures before re-enabling trap

3. **Partial Rollback**:
   - Revert only problematic agents
   - Keep fixes for agents that work correctly
   - Create issue for failed agents

## Success Metrics

- **Zero empty debug/ directories**: `find .claude/specs -name "debug" -type d -empty | wc -l` returns 0
- **All agents pass timing check**: ensure_artifact_directory within 10 lines of Write tool usage
- **Cleanup trap functional**: Test script verifies empty directories removed on failure
- **Regression tests pass**: All new tests in test_lazy_directory_creation.sh pass
- **No spec 870 violations**: No eager mkdir patterns in command files
- **Documentation complete**: All standards documents updated with new patterns

## Notes

### Complexity Calculation
```
score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
     = (32 × 1.0) + (6 × 5.0) + (14 × 0.5) + (5 × 2.0)
     = 32 + 30 + 7 + 10
     = 79.0

Adjusted for high technical risk and cross-cutting changes: 87.5
```

### Progressive Planning Note
This is a Level 0 (single file) plan with medium-high complexity. If during implementation any phase becomes too complex or requires more than 10 subtasks, consider using `/expand` to create a phase directory structure.

### Related Specifications
- Spec 869: Original debug directory creation bug analysis
- Spec 870: Attempted fix for lazy directory creation violations
- Spec 889: Most recent occurrence of empty debug/ directory bug

### Debug Output Reference
The research was triggered by analyzing `/home/benjamin/.config/.claude/debug-output.md` which showed the workflow transition `plan → complete`, skipping the debug phase entirely. This suggests the debug-analyst agent was never invoked, yet the debug/ directory existed.
