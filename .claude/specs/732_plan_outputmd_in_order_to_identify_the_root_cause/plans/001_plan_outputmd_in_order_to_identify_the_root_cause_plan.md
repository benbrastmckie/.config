# Plan Command Library Detection and Path Resolution Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: Fix plan command SCRIPT_DIR path resolution failure
- **Scope**: Replace BASH_SOURCE-based library detection with inline CLAUDE_PROJECT_DIR bootstrap
- **Estimated Phases**: 5
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Plan Execution Failure Analysis](/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/001_topic1.md)
  - [State-Based Orchestration Architecture](/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/002_topic2.md)
  - [Refactor Plan Design](/home/benjamin/.config/.claude/specs/732_plan_outputmd_in_order_to_identify_the_root_cause/reports/003_topic3.md)

## Overview

The `/plan` command fails during Phase 0 initialization due to incorrect library path resolution. The current implementation uses `BASH_SOURCE[0]` to determine the script directory, but Claude Code's Bash tool executes bash blocks as separate subprocesses without preserving script metadata. This causes SCRIPT_DIR to resolve to the current working directory instead of the commands directory, resulting in an invalid library path (`/home/benjamin/.config/../lib/` instead of `/home/benjamin/.config/.claude/lib/`).

This refactor will replace the SCRIPT_DIR-based pattern with inline CLAUDE_PROJECT_DIR detection using git, eliminating the bootstrap paradox where we need `detect-project-dir.sh` to find the project directory but need the project directory to source `detect-project-dir.sh`.

## Research Summary

**From Failure Analysis Report (001)**:
- Root cause: BASH_SOURCE[0] returns empty in Claude Code's bash block execution context
- Failed path: `/home/benjamin/.config/../lib/detect-project-dir.sh`
- Expected path: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh`
- Missing component: `.claude/` directory prefix in the path
- 4 other commands use the same broken BASH_SOURCE pattern (collapse.md, implement.md, expand.md)

**From Architecture Report (002)**:
- State-based orchestration uses workflow-state-machine.sh and state-persistence.sh
- Libraries must be sourced in strict dependency order (15 defined standards)
- CLAUDE_PROJECT_DIR detection uses git rev-parse (67% faster than alternative methods: 6ms → 2ms)
- Standard 13 specifies git-based detection with fallback to current directory
- Subprocess isolation requires state files for variable persistence between bash blocks

**From Design Report (003)**:
- Spec 731 Phases 1-3 completed (Haiku classifier, explicit Task invocations) but Phase 4 incomplete
- SCRIPT_DIR issue was NOT addressed in spec 731 (wasn't identified as root cause)
- Solution: Inline git-based CLAUDE_PROJECT_DIR detection before any library sourcing
- Bootstrap pattern eliminates circular dependency
- 15 lines of inline code replaces fragile SCRIPT_DIR calculation

**Recommended Approach**:
Inline git-based CLAUDE_PROJECT_DIR detection directly in Phase 0, before sourcing any libraries. This eliminates the bootstrap paradox and works reliably in Claude Code's bash block execution model.

## Success Criteria

- [ ] CLAUDE_PROJECT_DIR detected successfully from any subdirectory within project
- [ ] All libraries sourced successfully using absolute paths
- [ ] No "No such file or directory" errors when sourcing libraries
- [ ] Plan command executes successfully from project root
- [ ] Plan command executes successfully from subdirectories (e.g., nvim/)
- [ ] Clear error message displayed when run from outside project
- [ ] No SCRIPT_DIR references remain in plan.md
- [ ] Standard 13 (CLAUDE_PROJECT_DIR detection) compliance maintained
- [ ] Standard 15 (library sourcing order) compliance maintained
- [ ] State-based orchestration patterns preserved
- [ ] Integration tests pass (simple feature, complex feature, with reports)
- [ ] Documentation updated to reflect architectural changes
- [ ] Zero regression in existing functionality

## Technical Design

### Architecture Overview

**Current (Broken) Flow**:
```
Phase 0 bash block:
  SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})  ← FAILS (BASH_SOURCE empty)
  source $SCRIPT_DIR/../lib/detect-project-dir.sh  ← PATH WRONG: /home/benjamin/.config/../lib/
  source other libraries  ← NEVER REACHED
```

**New (Fixed) Flow**:
```
Phase 0 bash block:
  Inline git-based CLAUDE_PROJECT_DIR detection  ← WORKS (no dependency)
  UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"  ← ABSOLUTE PATH
  source $UTILS_DIR/workflow-state-machine.sh  ← WORKS
  source other libraries in dependency order  ← WORKS
  Initialize state, calculate paths, persist state  ← WORKS
```

### Key Design Decisions

1. **Inline Bootstrap vs Library**:
   - **Decision**: Inline CLAUDE_PROJECT_DIR detection in Phase 0 before any library sourcing
   - **Rationale**: Eliminates circular dependency, works in Claude Code subprocess context
   - **Trade-off**: 15 lines of inline code vs bootstrap complexity (acceptable for reliability gain)

2. **Keep detect-project-dir.sh Library**:
   - **Decision**: Preserve existing library for other commands
   - **Rationale**: Other commands may successfully use SCRIPT_DIR pattern; requires separate audit
   - **Scope**: Only plan.md receives inline bootstrap in this refactor

3. **Git-Based Detection with Directory Traversal Fallback**:
   - **Decision**: Primary detection via `git rev-parse --show-toplevel`, fallback to upward directory search for `.claude/`
   - **Rationale**: Git detection is fastest (2ms) and most reliable; fallback ensures non-git environments work
   - **Performance**: Aligns with state-based orchestration performance characteristics

4. **Error Handling Strategy**:
   - **Decision**: Fail-fast with clear diagnostics if CLAUDE_PROJECT_DIR cannot be detected
   - **Rationale**: Better to fail immediately with clear message than cascade into confusing library errors
   - **User Experience**: Clear error explains how to resolve (must run from within .claude/ project)

### Path Detection Algorithm

```bash
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# STANDARD 13: Validate CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree"
  echo "SOLUTION: Run /plan from within a directory containing .claude/ subdirectory"
  exit 1
fi

# Export for use by sourced libraries
export CLAUDE_PROJECT_DIR

# Calculate library path using absolute path
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
```

### Library Sourcing Order (Standard 15)

After CLAUDE_PROJECT_DIR detection, source libraries in strict dependency order:

1. **workflow-state-machine.sh** (provides state machine functions)
2. **state-persistence.sh** (provides state file functions)
3. **error-handling.sh** (provides error classification)
4. **verification-helpers.sh** (provides fail-fast verification)
5. **unified-location-detection.sh** (provides topic allocation)
6. **complexity-utils.sh** (provides complexity scoring)
7. **metadata-extraction.sh** (provides report parsing)

All sourcing statements use `$UTILS_DIR/library.sh` absolute paths.

### State Persistence Strategy

Continue using state-based orchestration patterns from architecture report:
- Initialize workflow state via `init_workflow_state()`
- Save workflow ID to fixed semantic filename for cross-block access
- Persist pre-calculated paths via `append_workflow_state()`
- Load state in subsequent blocks via `load_workflow_state()`

**Critical State Items** (from report 002):
- WORKFLOW_ID, PLAN_STATE_ID_FILE, FEATURE_DESCRIPTION
- TOPIC_DIR, TOPIC_NUMBER, PLAN_PATH
- SPECS_DIR, PROJECT_ROOT, REPORT_PATHS_JSON

### Standards Compliance Matrix

| Standard | Description | Current Status | After Refactor |
|----------|-------------|----------------|----------------|
| Standard 0 | Absolute paths only | ✗ BROKEN | ✓ COMPLIANT |
| Standard 11 | Imperative invocation | ✓ YES (731) | ✓ MAINTAINED |
| Standard 13 | CLAUDE_PROJECT_DIR detection | ✗ BROKEN | ✓ COMPLIANT |
| Standard 15 | Library sourcing order | ✗ BROKEN | ✓ COMPLIANT |
| State Machine | Explicit state names | ✓ YES | ✓ MAINTAINED |
| State Persistence | Selective file-based | ✓ YES | ✓ MAINTAINED |

## Implementation Phases

### Phase 1: Replace SCRIPT_DIR with Inline CLAUDE_PROJECT_DIR Bootstrap
dependencies: []

**Objective**: Eliminate SCRIPT_DIR-based library detection and replace with inline git-based CLAUDE_PROJECT_DIR detection

**Complexity**: Medium

**Tasks**:
- [x] Read current plan.md Phase 0 implementation (lines 18-238)
- [x] Remove SCRIPT_DIR calculation lines (lines 27-32)
- [x] Add inline CLAUDE_PROJECT_DIR git-based detection before library sourcing
- [x] Add directory traversal fallback for non-git environments
- [x] Add Standard 13 validation with clear error messages
- [x] Export CLAUDE_PROJECT_DIR for library access
- [x] Verify all library source statements use `$UTILS_DIR/` prefix
- [x] Verify Standard 0 compliance (all paths absolute)
- [x] Update Phase 0 documentation comment to reflect inline bootstrap

**Testing**:
```bash
# Test from project root
cd /home/benjamin/.config && /plan "test feature from root"

# Test from subdirectory
cd /home/benjamin/.config/nvim && /plan "test feature from subdirectory"

# Test from outside project (should fail gracefully)
cd /tmp && /plan "test feature from outside" 2>&1 | grep "Failed to detect project"

# Verify libraries sourced successfully
cd /home/benjamin/.config && /plan "verify libraries" 2>&1 | grep "Phase 0: Orchestrator initialized"
```

**Expected Duration**: 1-2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(732): complete Phase 1 - Replace SCRIPT_DIR with inline CLAUDE_PROJECT_DIR bootstrap`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Audit Other Commands Using BASH_SOURCE Pattern
dependencies: [1]

**Objective**: Identify and document other commands affected by BASH_SOURCE path resolution issue

**Complexity**: Low

**Tasks**:
- [x] Search codebase for BASH_SOURCE pattern: `grep -r 'BASH_SOURCE\[0\]' .claude/commands/`
- [x] Document affected commands (collapse.md, implement.md, expand.md from report 001)
- [x] Test each affected command to verify if BASH_SOURCE issue impacts them
- [x] Create issue/spec for auditing and fixing other affected commands (separate from this spec)
- [x] Document BASH_SOURCE limitation in bash-block-execution-model.md
- [x] Add anti-pattern warning to command development guide

**Testing**:
```bash
# Quick test of potentially affected commands
cd /home/benjamin/.config && /expand --help 2>&1 | grep -i "error"
cd /home/benjamin/.config && /collapse --help 2>&1 | grep -i "error"
cd /home/benjamin/.config && /implement --help 2>&1 | grep -i "error"
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(732): complete Phase 2 - Audit other commands using BASH_SOURCE pattern`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Integration Testing
dependencies: [1]

**Objective**: Validate complete /plan workflow end-to-end with inline bootstrap

**Complexity**: High

**Tasks**:
- [ ] Test simple feature (no research): `/plan "add button to settings page"`
- [ ] Verify Haiku complexity classifier invoked (from spec 731 Phase 1)
- [ ] Verify complexity score calculated correctly
- [ ] Verify plan-architect agent invoked (from spec 731 Phase 3)
- [ ] Verify plan file created at expected path
- [ ] Test complex feature (with research): `/plan "implement distributed tracing system"`
- [ ] Verify research agents invoked when complexity ≥ threshold
- [ ] Verify research reports created before plan-architect invocation
- [ ] Verify plan includes all research reports in metadata
- [ ] Test with provided reports: `/plan "refactor auth" /path/to/auth_analysis.md`
- [ ] Verify provided reports included in plan metadata
- [ ] Verify plan-architect receives all report paths
- [ ] Test error paths: run from outside project, invalid feature description
- [ ] Verify clear diagnostic messages for all error conditions
- [ ] Verify no "command not found" errors
- [ ] Verify no "bad substitution" errors
- [ ] Verify state persistence works (STATE_FILE created and populated)
- [ ] Verify workflow resumption works if interrupted

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Integration test suite
cd /home/benjamin/.config

# Test 1: Simple feature
/plan "add dark mode toggle to settings" 2>&1 | tee /tmp/plan_test1.log
grep -q "✓ Phase 0: Orchestrator initialized" /tmp/plan_test1.log || echo "FAIL: Phase 0"
grep -q "PLAN_CREATED:" /tmp/plan_test1.log || echo "FAIL: Plan creation"

# Test 2: Complex feature (triggers research)
/plan "implement real-time collaboration with WebRTC" 2>&1 | tee /tmp/plan_test2.log
grep -q "research-specialist" /tmp/plan_test2.log || echo "FAIL: Research delegation"
grep -q "PLAN_CREATED:" /tmp/plan_test2.log || echo "FAIL: Plan creation"

# Test 3: With existing reports
REPORT_PATH=$(find .claude/specs -name "*report*.md" -type f | head -1)
/plan "implement feature X" "$REPORT_PATH" 2>&1 | tee /tmp/plan_test3.log
grep -q "PLAN_CREATED:" /tmp/plan_test3.log || echo "FAIL: Plan creation"

# Test 4: Error handling
cd /tmp && /plan "test outside project" 2>&1 | grep "Failed to detect project"

echo "✓ All integration tests complete"
```

**Expected Duration**: 2-3 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(732): complete Phase 3 - Integration testing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Documentation Updates
dependencies: [1, 3]

**Objective**: Update documentation to reflect inline bootstrap pattern and BASH_SOURCE limitation

**Complexity**: Medium

**Tasks**:
- [ ] Create or update `.claude/docs/guides/plan-command-guide.md`:
  - [ ] Add §2.5 "CLAUDE_PROJECT_DIR Bootstrap Pattern"
  - [ ] Update §3.1 "Phase 0: Orchestrator Initialization" with inline detection details
  - [ ] Document why SCRIPT_DIR pattern doesn't work in Claude Code
  - [ ] Add troubleshooting section for library path errors
- [ ] Update `.claude/docs/concepts/bash-block-execution-model.md`:
  - [ ] Add BASH_SOURCE[0] limitation documentation
  - [ ] Add anti-pattern section warning against SCRIPT_DIR usage
  - [ ] Recommend inline CLAUDE_PROJECT_DIR detection pattern
  - [ ] Include code examples for correct bootstrap pattern
- [ ] Update `.claude/docs/reference/command-reference.md`:
  - [ ] Verify /plan entry accuracy
  - [ ] Update examples if needed
- [ ] Update CLAUDE.md if architectural changes warrant it
- [ ] Review all documentation for consistency and clarity
- [ ] Remove any historical commentary (per development philosophy)

**Expected Duration**: 1-2 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(732): complete Phase 4 - Documentation updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Complete Spec 731 Phase 4 and Validation
dependencies: [1, 2, 3, 4]

**Objective**: Complete remaining tasks from spec 731 and perform final validation

**Complexity**: Medium

**Tasks**:
- [ ] Review spec 731 Phase 4 task list (lines 281-319 of spec 731 plan)
- [ ] Verify Haiku complexity classifier integration stable (731 Phase 1)
- [ ] Verify explicit Task invocations for research delegation working (731 Phase 2)
- [ ] Verify explicit Task invocation for plan-architect working (731 Phase 3)
- [ ] Run regression tests to ensure no existing functionality broken
- [ ] Verify Standards 0, 11, 13, 15 compliance across all phases
- [ ] Verify state-based orchestration patterns maintained
- [ ] Test backward compatibility with existing /plan usage patterns
- [ ] Review git diff for unintended changes
- [ ] Update spec 731 plan file to mark Phase 4 complete
- [ ] Create summary document linking specs 731 and 732
- [ ] Mark this spec (732) as complete

**Testing**:
```bash
# Regression test suite
cd /home/benjamin/.config

# Verify backward compatibility
/plan "simple test feature"
/plan "complex test feature requiring research"

# Verify standards compliance
# (Standards verification performed during integration testing Phase 3)

# Verify state persistence
STATE_FILE=$(/plan "state test" 2>&1 | grep -oP 'STATE_FILE=\K.*')
test -f "$STATE_FILE" && echo "✓ State file created" || echo "✗ State file missing"

echo "✓ All regression tests passed"
```

**Expected Duration**: 1 hour

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(732): complete Phase 5 - Complete spec 731 Phase 4 and final validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Test CLAUDE_PROJECT_DIR detection from various directories (root, subdirectories, outside project)
- Test git-based detection vs directory traversal fallback
- Test error handling for invalid project directories
- Test library sourcing with absolute paths
- Test state file creation and persistence

### Integration Testing
- Test complete /plan workflow for simple features
- Test complete /plan workflow for complex features (with research delegation)
- Test /plan with provided research reports
- Test error paths and diagnostic messages
- Test state persistence and workflow resumption

### Regression Testing
- Verify no breakage of existing /plan functionality
- Verify backward compatibility with current usage patterns
- Verify Standards 0, 11, 13, 15 compliance
- Verify state-based orchestration patterns maintained

### Performance Testing
- Measure CLAUDE_PROJECT_DIR detection time (should be ≤2ms for git-based)
- Measure library sourcing overhead (should be ≤10ms total)
- Compare performance before and after refactor (should show no regression)

## Documentation Requirements

### Files to Create/Update
1. `.claude/docs/guides/plan-command-guide.md` - Add bootstrap pattern section, update Phase 0 documentation
2. `.claude/docs/concepts/bash-block-execution-model.md` - Document BASH_SOURCE limitation, add anti-pattern warning
3. `.claude/docs/reference/command-reference.md` - Verify /plan entry accuracy
4. This plan file (732) - Update with phase completion status
5. Spec 731 plan file - Mark Phase 4 complete after integration

### Documentation Standards
- Follow CommonMark specification
- No emojis in file content
- Include code examples with syntax highlighting
- Use clear, concise language
- No historical commentary
- Update examples to match current implementation

## Dependencies

### External Dependencies
- **git**: Required for CLAUDE_PROJECT_DIR detection (primary method)
- **jq**: Required for JSON processing in state persistence
- **bash**: Version 4.0+ for associative arrays

### Internal Library Dependencies
All libraries sourced in dependency order (Standard 15):
1. workflow-state-machine.sh
2. state-persistence.sh
3. error-handling.sh
4. verification-helpers.sh
5. unified-location-detection.sh
6. complexity-utils.sh
7. metadata-extraction.sh

### Spec Dependencies
- **Spec 731**: Haiku classifier, explicit Task invocations (Phases 1-3 complete, Phase 4 incomplete)
- **Spec 732** (this spec): Path resolution fix, documentation updates

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Inline bootstrap breaks on non-git projects | Low | Medium | Directory traversal fallback included in design |
| Library dependencies have undocumented order requirements | Low | High | Thorough testing, verification checkpoints, review sourcing order |
| State persistence fails after path change | Low | Critical | Integration tests validate state file operations |
| Spec 731 changes conflict with path fix | Low | Medium | Review spec 731 commits before applying fix |
| Documentation becomes out of sync | Medium | Medium | Complete Phase 4 documentation tasks before marking complete |
| Breaking changes for existing /plan users | Low | High | Maintain backward compatibility, extensive testing |
| Other commands also broken by BASH_SOURCE issue | High | High | Phase 2 audit identifies scope, creates follow-up spec |

## Performance Characteristics

### Expected Performance Metrics
- **CLAUDE_PROJECT_DIR detection**: ≤2ms (git-based, per state-based orchestration docs)
- **Library sourcing overhead**: ≤10ms total (7 libraries)
- **State file initialization**: ~6ms (includes git rev-parse)
- **Total Phase 0 overhead**: ~20ms (acceptable for initialization phase)

### Performance Comparison
- **Before (when working)**: ~18ms Phase 0
- **After refactor**: ~20ms Phase 0 (2ms increase acceptable)
- **Improvement**: 100% reliability (currently fails 100% of time)

## Success Metrics

### Functional Metrics
- ✓ CLAUDE_PROJECT_DIR detected 100% in git projects
- ✓ CLAUDE_PROJECT_DIR detected ≥95% in non-git projects (via fallback)
- ✓ Zero "No such file or directory" errors for library sourcing
- ✓ Zero "command not found" errors for library functions
- ✓ Zero "bad substitution" errors
- ✓ 100% agent invocation success rate (Haiku classifier, research, plan-architect)
- ✓ 100% plan file creation at expected paths

### Quality Metrics
- ✓ 100% standards compliance (Standards 0, 11, 13, 15)
- ✓ 100% state-based orchestration pattern compliance
- ✓ ≥80% test coverage (per CLAUDE.md testing protocols)
- ✓ Clear diagnostic messages for all failure modes
- ✓ Documentation complete and accurate

### Project Impact
- ✓ /plan command functional again (currently completely broken)
- ✓ Establishes reliable bootstrap pattern for other commands
- ✓ Identifies scope of BASH_SOURCE issue across codebase
- ✓ Completes spec 731 Phase 4 (integration testing and documentation)
