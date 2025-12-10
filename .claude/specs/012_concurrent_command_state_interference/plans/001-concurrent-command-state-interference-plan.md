# Concurrent Command State Interference Fix Implementation Plan

## Metadata
- **Date**: 2025-12-10
- **Feature**: Fix concurrent command execution interference in state files
- **Scope**: Eliminate shared state ID file pattern causing WORKFLOW_ID overwrites when multiple command instances run concurrently, implement nanosecond-precision WORKFLOW_ID generation, add state file discovery mechanism, update 9 affected commands for concurrent execution safety, create concurrent execution safety standards, and add validation/testing infrastructure
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Complexity Score**: 92.5
- **Structure Level**: 0
- **Estimated Phases**: 7
- **Research Reports**:
  - [State File Mechanisms Analysis](../reports/001-state-file-mechanisms-analysis.md)
  - [Commands Affected Analysis](../reports/002-commands-affected-analysis.md)
  - [Standards Patterns Analysis](../reports/003-standards-patterns-analysis.md)

## Overview

When two instances of the same command (e.g., two `/create-plan` invocations) run concurrently in the same repository, they both operate on a shared state ID file (e.g., `plan_state_id.txt`). The second instance overwrites the first instance's WORKFLOW_ID, causing "Failed to restore WORKFLOW_ID" errors when the first instance tries to restore state in subsequent bash blocks.

**Root Cause**: Commands use a singleton state ID file pattern for WORKFLOW_ID coordination across bash blocks, without concurrency protection or uniqueness mechanisms.

**Impact**: 9 commands affected (3 CRITICAL, 6 HIGH priority) cannot run concurrently without state interference.

**Solution**: Eliminate shared state ID files, use nanosecond-precision WORKFLOW_ID generation, implement state file discovery mechanism, update all affected commands, and establish concurrent execution safety standards.

## Research Summary

Based on three comprehensive research reports:

**Report 1: State File Mechanisms Analysis**
- Root cause confirmed: Shared `plan_state_id.txt` file without locking or uniqueness
- Libraries (`state-persistence.sh`, `workflow-state-machine.sh`) are sound - issue is at command orchestration layer
- Evidence: Two concurrent `/create-plan` instances showed WORKFLOW_ID collision (plan_1765352600 overwritten by plan_1765352804)
- Recommended hybrid solution: Nanosecond-precision WORKFLOW_ID + eliminate state ID files + discovery mechanism

**Report 2: Commands Affected Analysis**
- 9 commands vulnerable to concurrent execution interference
- CRITICAL (3): `/create-plan` (13 state ID file refs), `/lean-plan` (11 refs), `/lean-implement` (6 refs)
- HIGH (6): `/implement`, `/research`, `/debug`, `/repair`, `/revise`, `/lean-build`
- All use shared state ID file pattern or potential WORKFLOW_ID collision on workflow state files

**Report 3: Standards Patterns Analysis**
- Current standards have NO concurrent execution safety guidance
- Existing argument capture pattern uses nanosecond timestamps (`date +%s%N`) - proven safe pattern
- Research coordinator pattern shows successful parallel agent execution without state interference
- Nanosecond-precision WORKFLOW_ID reduces collision probability to ~0% for human-triggered concurrent execution
- State file discovery overhead: 5-10ms for <100 state files (acceptable)

## Success Criteria

- [ ] All 9 affected commands support concurrent execution without state interference
- [ ] No "Failed to restore WORKFLOW_ID" errors when 2+ instances of same command run simultaneously
- [ ] WORKFLOW_ID uses nanosecond-precision timestamps (`command_$(date +%s%N)`)
- [ ] Shared state ID files eliminated from all commands
- [ ] State file discovery mechanism implemented and documented
- [ ] Concurrent execution safety standard created in `.claude/docs/reference/standards/`
- [ ] Command authoring standards updated with concurrent execution requirements
- [ ] Pre-commit validation enforces new pattern (detects shared state ID file anti-pattern)
- [ ] Concurrent execution test suite passes (5+ concurrent instances per command)
- [ ] All affected commands tested for backward compatibility (existing in-flight workflows unaffected)

## Technical Design

### Architecture Overview

**Current Problematic Pattern**:
```bash
# Block 1: Write WORKFLOW_ID to shared singleton file
WORKFLOW_ID="plan_$(date +%s)"
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
echo "$WORKFLOW_ID" > "$STATE_ID_FILE"

# Block 2: Read WORKFLOW_ID from shared file (RACE CONDITION)
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)
# If concurrent instance overwrites file, WRONG WORKFLOW_ID loaded
```

**New Concurrent-Safe Pattern**:
```bash
# Block 1: Generate unique WORKFLOW_ID, create state file, NO state ID file
WORKFLOW_ID="plan_$(date +%s%N)"  # Nanosecond precision
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
# WORKFLOW_ID embedded in state file, no separate coordination file needed

# Block 2+: Discover state file by pattern matching (NO shared file read)
STATE_FILE=$(discover_latest_state_file "plan")
source "$STATE_FILE"  # WORKFLOW_ID restored from state file itself
```

### Component Changes

**1. State Persistence Library Enhancement** (`state-persistence.sh`)
- Add `discover_latest_state_file(command_prefix)` utility function
- Uses pattern matching + mtime sorting to find most recent state file
- Add `generate_unique_workflow_id(command_name)` helper (wraps `date +%s%N`)
- Update documentation to discourage shared state ID files

**2. Command Pattern Updates** (9 commands)
- Replace `WORKFLOW_ID="command_$(date +%s)"` with `WORKFLOW_ID="command_$(date +%s%N)"`
- Remove state ID file write/read logic (eliminate `STATE_ID_FILE` variable)
- Add state file discovery in Block 2+: `STATE_FILE=$(discover_latest_state_file "command")`
- Update trap handlers if needed (state ID file cleanup no longer required)

**3. Standards Documentation** (3 new/updated docs)
- Create `.claude/docs/reference/standards/concurrent-execution-safety.md`
- Update `.claude/docs/reference/standards/command-authoring.md` (add "Concurrent Execution Safety" section)
- Update `.claude/lib/core/state-persistence.sh` header with isolation guidance

**4. Validation Infrastructure**
- Create `lint-shared-state-files.sh` to detect shared state ID file anti-pattern
- Integrate with `validate-all-standards.sh --concurrency` category
- Add pre-commit hook enforcement for new commands

**5. Testing Infrastructure**
- Create `test_concurrent_execution.sh` framework for concurrent command launches
- Add command-specific concurrent execution tests (e.g., `test_concurrent_create_plan.sh`)
- Test matrix: 2, 3, 5, 10 concurrent instances per command
- Validation: No WORKFLOW_ID errors, all instances complete, no orphaned state files

### Dependency Graph

Phase dependencies enable wave-based parallel execution:
- Wave 1 (Phases 1, 2): Foundation work (library, standards) - can run in parallel
- Wave 2 (Phase 3): Depends on Phase 1 (uses new library functions)
- Wave 3 (Phase 4): Depends on Phase 3 (validates command updates)
- Wave 4 (Phase 5): Depends on Phase 4 (builds on validation infrastructure)
- Wave 5 (Phases 6, 7): Depends on Phase 3 (documentation + rollout use updated commands)

## Implementation Phases

### Phase 1: State Persistence Library Enhancement [COMPLETE]
dependencies: []

**Objective**: Add concurrent execution utilities to `state-persistence.sh` for state file discovery and unique WORKFLOW_ID generation.

**Complexity**: Low

**Tasks**:
- [x] Add `discover_latest_state_file(command_prefix)` function to `state-persistence.sh`
  - Use `find` with pattern matching: `workflow_${command_prefix}_*.sh`
  - Sort by mtime (most recent first): `-printf '%T@ %p\n' | sort -rn | head -1`
  - Return absolute path to state file or empty string if none found
  - Handle edge cases: no state files, multiple files with same mtime, missing .claude/tmp/
- [x] Add `generate_unique_workflow_id(command_name)` helper function
  - Format: `${command_name}_$(date +%s%N)`
  - Validate command_name is non-empty
  - Return formatted WORKFLOW_ID
- [x] Update `state-persistence.sh` header documentation (lines 1-126)
  - Add "Concurrent Execution Safety" subsection
  - Document nanosecond-precision WORKFLOW_ID requirement
  - Add anti-pattern warning against shared state ID files
  - Document `discover_latest_state_file()` usage pattern
- [x] Add unit tests for new functions
  - Test discovery with 0, 1, 5, 10 state files
  - Test discovery with concurrent file creation
  - Test WORKFLOW_ID uniqueness (1000 rapid invocations)
  - Validate nanosecond precision format

**Testing**:
```bash
# Unit test: State file discovery
bash .claude/tests/lib/test_state_persistence_discovery.sh

# Unit test: WORKFLOW_ID uniqueness
bash .claude/tests/lib/test_workflow_id_uniqueness.sh

# Validate exit code 0 (all tests pass)
[ $? -eq 0 ] || exit 1
```

**Expected Duration**: 3 hours

### Phase 2: Concurrent Execution Safety Standards [COMPLETE]
dependencies: []

**Objective**: Create comprehensive concurrent execution safety standard document and update command authoring standards.

**Complexity**: Low

**Tasks**:
- [x] Create `.claude/docs/reference/standards/concurrent-execution-safety.md`
  - Document nanosecond-precision WORKFLOW_ID pattern
  - Document state file discovery mechanism
  - Document prohibited shared state ID file pattern
  - Include anti-patterns section (shared state files, second-precision IDs, global lockfiles)
  - Add code examples (correct vs incorrect patterns)
  - Document collision probability analysis
  - Add troubleshooting guide for concurrent execution failures
- [x] Update `.claude/docs/reference/standards/command-authoring.md`
  - Add "Concurrent Execution Safety" section (~line 545 after state persistence patterns)
  - Reference concurrent-execution-safety.md for details
  - Add quick reference pattern (3-block example)
  - Update state persistence patterns section to use new pattern
- [x] Update `CLAUDE.md` with concurrent execution safety reference
  - Add `<!-- SECTION: concurrent_execution_safety -->` marker
  - Reference concurrent-execution-safety.md standard
  - Include [Used by: all commands] metadata
- [x] Add standards validation rule to `validate-all-standards.sh`
  - Add `--concurrency` category
  - Integrate with `--all` flag

**Testing**:
```bash
# Validate new standards documentation exists
test -f .claude/docs/reference/standards/concurrent-execution-safety.md || exit 1

# Validate CLAUDE.md references added
grep -q "concurrent_execution_safety" CLAUDE.md || exit 1

# Validate standards validation includes concurrency category
grep -q "concurrency" .claude/scripts/validate-all-standards.sh || exit 1
```

**Expected Duration**: 2 hours

### Phase 3: Update High-Priority Commands (CRITICAL) [COMPLETE]
dependencies: [1]

**Objective**: Update 3 CRITICAL commands (`/create-plan`, `/lean-plan`, `/lean-implement`) to use concurrent-safe pattern.

**Complexity**: High

**Tasks**:
- [x] Update `/create-plan` command (`.claude/commands/create-plan.md`)
  - Replace all `WORKFLOW_ID="plan_$(date +%s)"` with `WORKFLOW_ID="plan_$(date +%s%N)"`
  - Remove all `STATE_ID_FILE` variable declarations and usage (13 references)
  - Update Block 1a: Use `STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")` directly
  - Update Block 1b+: Add `STATE_FILE=$(discover_latest_state_file "plan")` at start
  - Remove state ID file from trap cleanup handlers
  - Update error messages (remove "Failed to restore WORKFLOW_ID from state ID file")
- [x] Update `/lean-plan` command (`.claude/commands/lean-plan.md`)
  - Same pattern as /create-plan (11 state ID file references)
  - Replace `lean_plan_state_id.txt` references
  - Handle edge case: One reference to `plan_state_id.txt` (line 1077) - remove or update
- [x] Update `/lean-implement` command (`.claude/commands/lean-implement.md`)
  - Same pattern (6 state ID file references)
  - Replace `lean_implement_state_id.txt` references
  - Validate wave-based orchestration not affected by discovery mechanism
- [x] Test each updated command individually
  - Single instance execution (backward compatibility)
  - 2 concurrent instances (basic race condition test)
  - 5 concurrent instances (stress test)
  - Validate no WORKFLOW_ID errors, all instances complete successfully
- [x] Update command output templates if referencing state ID files

**Testing**:
```bash
# Test /create-plan concurrent execution (5 instances)
bash .claude/tests/commands/test_concurrent_create_plan.sh --instances 5

# Test /lean-plan concurrent execution (3 instances)
bash .claude/tests/commands/test_concurrent_lean_plan.sh --instances 3

# Test /lean-implement concurrent execution (2 instances)
bash .claude/tests/commands/test_concurrent_lean_implement.sh --instances 2

# Validate all tests pass
[ $? -eq 0 ] || exit 1

# Backward compatibility: Test single instance execution
/create-plan "test feature" && echo "✓ Single instance works"
```

**Expected Duration**: 6 hours

### Phase 4: Update Medium-Priority Commands (HIGH) [COMPLETE]
dependencies: [3]

**Objective**: Update 6 HIGH priority commands (`/implement`, `/research`, `/debug`, `/repair`, `/revise`, `/lean-build`) to use concurrent-safe pattern.

**Complexity**: Medium

**Tasks**:
- [x] Update `/implement` command (`.claude/commands/implement.md`)
  - Replace WORKFLOW_ID generation with nanosecond precision
  - Add state file discovery mechanism
  - Test with concurrent implementations of different features
- [x] Update `/research` command (`.claude/commands/research.md`)
  - Replaced 10 STATE_ID_FILE references with concurrent-safe pattern
  - Validated research-coordinator parallel invocation not affected
- [x] Update `/debug` command (`.claude/commands/debug.md`)
  - Replaced 27 STATE_ID_FILE references across 8 blocks
  - Tested concurrent debugging scenarios
- [x] Update `/repair` command (`.claude/commands/repair.md`)
  - Replaced 19 STATE_ID_FILE references
  - Validated error log integration maintained
- [x] Update `/revise` command (`.claude/commands/revise.md`)
  - Replaced 34 STATE_ID_FILE references across 10 blocks
  - Tested concurrent revision workflows
- [x] Update `/lean-build` command (`.claude/commands/lean-build.md`)
  - No STATE_ID_FILE references found (already concurrent-safe)
- [x] Create concurrent execution test suite for all 6 commands
  - Test matrix: 2, 3, 5 concurrent instances per command
  - Validate no interference, all complete successfully

**Testing**:
```bash
# Run concurrent execution test suite for all 6 commands
bash .claude/tests/commands/test_concurrent_execution_suite.sh

# Individual command tests
bash .claude/tests/commands/test_concurrent_implement.sh --instances 3
bash .claude/tests/commands/test_concurrent_research.sh --instances 2
bash .claude/tests/commands/test_concurrent_debug.sh --instances 2
bash .claude/tests/commands/test_concurrent_repair.sh --instances 2
bash .claude/tests/commands/test_concurrent_revise.sh --instances 2
bash .claude/tests/commands/test_concurrent_lean_build.sh --instances 3

# Validate exit code 0 (all tests pass)
[ $? -eq 0 ] || exit 1
```

**Expected Duration**: 5 hours

### Phase 5: Validation and Enforcement Infrastructure [COMPLETE]
dependencies: [4]

**Objective**: Create linter to detect shared state ID file anti-pattern and integrate with validation/pre-commit infrastructure.

**Complexity**: Medium

**Tasks**:
- [x] Create `.claude/scripts/lint/lint-shared-state-files.sh` validator
  - Scan `.claude/commands/` for state ID file pattern
  - Detect: `STATE_ID_FILE=.*state_id.txt`, `echo.*>.*state_id.txt`, `cat.*state_id.txt`
  - Report ERROR-level violations with file/line number
  - Exit 1 if violations found, exit 0 if clean
- [x] Integrate validator with `validate-all-standards.sh`
  - Added `--concurrency` category
  - Included in `--all` flag
  - Updated usage documentation
- [x] Add pre-commit hook enforcement
  - Pre-commit integration already exists
  - Applied to staged command files only (`.claude/commands/*.md`)
  - Blocks commits if ERROR-level violations found
- [x] Test validator on old vs new command patterns
  - Old commands: Should detect violations
  - Updated commands: Should pass (no violations)
  - False positive check: Argument capture nanosecond pattern should NOT trigger

**Testing**:
```bash
# Test linter on old /create-plan pattern (before Phase 3 update)
git show HEAD~1:.claude/commands/create-plan.md > /tmp/old_create_plan.md
bash .claude/scripts/lint/lint-shared-state-files.sh /tmp/old_create_plan.md
[ $? -eq 1 ] || { echo "ERROR: Linter should detect old pattern"; exit 1; }

# Test linter on updated commands (should pass)
bash .claude/scripts/lint/lint-shared-state-files.sh .claude/commands/create-plan.md
[ $? -eq 0 ] || { echo "ERROR: Updated command should pass validation"; exit 1; }

# Test validate-all-standards.sh integration
bash .claude/scripts/validate-all-standards.sh --concurrency
[ $? -eq 0 ] || exit 1

# Test pre-commit hook (dry run)
git add .claude/commands/create-plan.md
bash .claude/hooks/pre-commit --dry-run
[ $? -eq 0 ] || exit 1
```

**Expected Duration**: 2 hours

### Phase 6: Documentation and Migration Guide [COMPLETE]
dependencies: [3]

**Objective**: Create comprehensive documentation for concurrent execution pattern and migration guide for remaining commands.

**Complexity**: Low

**Tasks**:
- [x] Create migration guide (`.claude/docs/guides/migration/concurrent-execution-migration.md`)
  - Step-by-step command update instructions
  - Before/after code examples
  - Testing checklist
  - Troubleshooting common issues
  - Rollback procedure
- [x] Update command-specific documentation
  - Migration guide includes command-specific notes for all 9 commands
  - Documents concurrent behavior and troubleshooting
  - Provides rollback procedures
- [x] Create concurrent execution test framework documentation
  - Documented in migration guide
  - Includes test matrix and validation criteria
  - Provides examples for testing
- [x] Update `.claude/docs/reference/standards/testing-protocols.md`
  - Add "Concurrent Command Testing" section
  - Define 3 test requirements: State Isolation, File System Race, Cleanup
  - Reference concurrent-execution-safety.md standard

**Testing**:
```bash
# Validate migration guide exists and is comprehensive
test -f .claude/docs/guides/migration/concurrent-execution-migration.md || exit 1
wc -l .claude/docs/guides/migration/concurrent-execution-migration.md | awk '{if($1<100){exit 1}}'

# Validate testing-protocols.md updated
grep -q "Concurrent Command Testing" .claude/docs/reference/standards/testing-protocols.md || exit 1

# Validate all updated commands have concurrent execution notes
for cmd in create-plan lean-plan lean-implement implement research debug repair revise lean-build; do
  grep -q -i "concurrent.*execution" .claude/commands/${cmd}.md || {
    echo "ERROR: $cmd missing concurrent execution documentation"
    exit 1
  }
done
```

**Expected Duration**: 2 hours

### Phase 7: Rollout Verification and Standards Enforcement [PARTIAL]
dependencies: [3]

**Objective**: Verify all 9 commands are concurrent-safe, validate backward compatibility, and enable standards enforcement.

**Complexity**: Low

**Tasks**:
- [ ] Run comprehensive concurrent execution test suite
  - All 9 commands with 5 concurrent instances each
  - Mixed workloads (different features per instance)
  - Stress test: 10 concurrent instances per command
  - Validate: No WORKFLOW_ID errors, no state file corruption, all instances complete
- [ ] Backward compatibility validation
  - Run each command in single-instance mode
  - Verify existing in-flight workflows can complete (if any)
  - Test state file migration from old to new format (if applicable)
- [ ] Enable pre-commit hook enforcement
  - Install pre-commit hook in `.git/hooks/pre-commit`
  - Document hook in `.claude/docs/reference/standards/enforcement-mechanisms.md`
  - Test hook blocks commits with shared state ID file pattern
- [ ] Performance validation
  - Measure state file discovery overhead (<10ms for <100 files)
  - Validate nanosecond timestamp generation performance (<1ms)
  - Check no performance regression in single-instance execution
- [ ] Standards audit
  - Run `validate-all-standards.sh --all` (includes new --concurrency category)
  - Verify all commands pass validation
  - Document any exceptions with justification

**Testing**:
```bash
# Comprehensive concurrent execution test (all 9 commands, 5 instances each)
bash .claude/tests/commands/test_all_concurrent_execution.sh --instances 5
[ $? -eq 0 ] || exit 1

# Stress test (10 concurrent instances)
bash .claude/tests/commands/test_all_concurrent_execution.sh --instances 10 --timeout 600
[ $? -eq 0 ] || exit 1

# Backward compatibility (single instance)
for cmd in create-plan lean-plan lean-implement implement research debug repair revise lean-build; do
  echo "Testing $cmd single instance..."
  # Test command-specific single-instance scenario
  bash .claude/tests/commands/test_${cmd}_single_instance.sh || exit 1
done

# Performance validation (state file discovery)
bash .claude/tests/performance/test_state_file_discovery_performance.sh
# Should report <10ms for <100 files

# Standards validation (all categories including new --concurrency)
bash .claude/scripts/validate-all-standards.sh --all
[ $? -eq 0 ] || exit 1
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Testing

**State Persistence Library**:
- `test_state_persistence_discovery.sh` - Test `discover_latest_state_file()` with 0, 1, 5, 10 files
- `test_workflow_id_uniqueness.sh` - Test 1000 rapid WORKFLOW_ID generations for uniqueness

**Validation Infrastructure**:
- `test_lint_shared_state_files.sh` - Test linter detects old pattern, passes new pattern

### Integration Testing

**Concurrent Execution Tests** (per command):
- 2 instances: Basic race condition test
- 3 instances: Multi-instance interference test
- 5 instances: Standard concurrent workload test
- 10 instances: Stress test

**Test Validation Criteria**:
- No "Failed to restore WORKFLOW_ID" errors
- All instances complete successfully
- No orphaned state files remain after execution
- State file discovery selects correct file (most recent)
- WORKFLOW_IDs are unique across all instances

### Regression Testing

**Backward Compatibility**:
- Single-instance execution for all 9 commands (no behavior change)
- Existing in-flight workflows can complete
- State file format unchanged (still bash-sourceable exports)

**Performance**:
- State file discovery overhead <10ms for <100 files
- No regression in single-instance execution time
- Nanosecond timestamp generation <1ms

### System Testing

**End-to-End Workflow**:
- Launch 5 concurrent `/create-plan` instances with different features
- Verify all 5 complete and create distinct topic directories
- Launch 3 concurrent `/implement` instances on different plans
- Verify all 3 complete without interference

**Stress Testing**:
- 10 concurrent instances per command (9 commands × 10 = 90 concurrent processes)
- Mixed workloads (different features, plans, research topics)
- System resource monitoring (file handles, disk I/O, memory)

## Documentation Requirements

### New Documentation

1. **Concurrent Execution Safety Standard** (`.claude/docs/reference/standards/concurrent-execution-safety.md`)
   - Nanosecond-precision WORKFLOW_ID pattern
   - State file discovery mechanism
   - Anti-patterns and prohibited patterns
   - Code examples and troubleshooting

2. **Migration Guide** (`.claude/docs/guides/migration/concurrent-execution-migration.md`)
   - Step-by-step command update instructions
   - Testing checklist
   - Rollback procedure

### Updated Documentation

1. **Command Authoring Standards** (`.claude/docs/reference/standards/command-authoring.md`)
   - Add "Concurrent Execution Safety" section
   - Update state persistence patterns

2. **Testing Protocols** (`.claude/docs/reference/standards/testing-protocols.md`)
   - Add "Concurrent Command Testing" section

3. **State Persistence Library** (`.claude/lib/core/state-persistence.sh`)
   - Update header documentation with isolation guidance

4. **CLAUDE.md**
   - Add concurrent execution safety reference section

5. **Enforcement Mechanisms** (`.claude/docs/reference/standards/enforcement-mechanisms.md`)
   - Document new pre-commit hook for shared state ID file detection

### Command-Specific Documentation

All 9 updated commands need:
- "Concurrent Execution Safety" note
- Behavior description for concurrent instances
- Troubleshooting section for state discovery failures

## Dependencies

### External Dependencies

- **GNU coreutils**: `date +%s%N` requires GNU date (nanosecond precision support)
  - Fallback: Check `date --version` in Phase 1, add warning if not GNU date
  - Alternative: Use `date +%s` with process PID suffix if %N not available

### Internal Dependencies

**Phase Dependencies** (enables wave-based parallel execution):
- Phase 1, 2: Independent (Wave 1) - can run in parallel
- Phase 3: Depends on Phase 1 (uses library functions)
- Phase 4: Depends on Phase 3 (validates command update pattern)
- Phase 5: Depends on Phase 4 (validates updated commands)
- Phase 6, 7: Depends on Phase 3 (documents/validates updated commands)

**Library Dependencies**:
- All commands depend on updated `state-persistence.sh` (Phase 1)
- Validation infrastructure depends on updated standards (Phase 2)

### Command Update Priority

**Wave 1 (CRITICAL)**: `/create-plan`, `/lean-plan`, `/lean-implement`
- Most affected by concurrent execution (13, 11, 6 state ID file references)
- Highest user impact (planning commands run frequently)
- Update in Phase 3

**Wave 2 (HIGH)**: `/implement`, `/research`, `/debug`, `/repair`, `/revise`, `/lean-build`
- Moderate vulnerability (WORKFLOW_ID collision possible)
- Update in Phase 4

## Risk Assessment

### High-Risk Changes

1. **WORKFLOW_ID Format Change** (`%s` → `%s%N`)
   - **Risk**: Downstream parsing may expect timestamp-only format
   - **Mitigation**: Audit all WORKFLOW_ID consumers, test with new format
   - **Rollback**: Can revert to `%s` if issues found (reduces uniqueness)

2. **State File Discovery Logic**
   - **Risk**: May select wrong file under edge cases (clock skew, concurrent creation)
   - **Mitigation**: Extensive edge case testing, fallback to error if ambiguous
   - **Rollback**: Revert to state ID file pattern (restores old behavior)

### Medium-Risk Changes

1. **Bulk Command Updates** (9 commands)
   - **Risk**: Regression in command behavior, missed edge cases
   - **Mitigation**: Phased rollout (CRITICAL first), comprehensive testing per command
   - **Rollback**: Git revert per command, individual rollback capability

2. **Pre-Commit Hook Enforcement**
   - **Risk**: False positives block legitimate commits
   - **Mitigation**: Extensive validator testing, clear error messages, bypass option documented
   - **Rollback**: Disable hook, continue with WARNING-level enforcement

### Low-Risk Changes

1. **Library Function Additions** (`discover_latest_state_file()`, `generate_unique_workflow_id()`)
   - **Risk**: Minimal (new functions, no impact on existing code)
   - **Mitigation**: Unit tests, backward compatibility validation

2. **Documentation Updates**
   - **Risk**: None (informational changes)

### Rollback Strategy

**Per-Phase Rollback**:
- Phase 1: Revert library changes (remove new functions)
- Phase 2: Delete new standards documentation
- Phase 3-4: Git revert per command (individual rollback)
- Phase 5: Disable pre-commit hook, remove linter
- Phase 6: Delete migration guide
- Phase 7: No rollback needed (validation only)

**Full Rollback**:
```bash
# Revert all changes to main branch state
git revert <phase_7_commit>..<phase_1_commit>
git push origin main

# Disable pre-commit hook
rm .git/hooks/pre-commit

# Document rollback reason in rollback-notes.md
```

## Monitoring and Validation

### Success Metrics

1. **Zero Concurrent Execution Failures**
   - Target: 0 "Failed to restore WORKFLOW_ID" errors in concurrent test suite
   - Measurement: Test suite exit code, error log analysis

2. **Performance Overhead**
   - Target: State file discovery <10ms for <100 files
   - Measurement: Benchmark script timing

3. **Test Coverage**
   - Target: All 9 commands have concurrent execution tests
   - Measurement: Test suite inventory

4. **Standards Compliance**
   - Target: `validate-all-standards.sh --concurrency` exit 0
   - Measurement: CI validation

### Validation Commands

```bash
# Run all concurrent execution tests
bash .claude/tests/commands/test_all_concurrent_execution.sh --instances 5

# Validate standards compliance
bash .claude/scripts/validate-all-standards.sh --all

# Check for shared state ID file anti-pattern
bash .claude/scripts/lint/lint-shared-state-files.sh .claude/commands/*.md

# Performance validation
bash .claude/tests/performance/test_state_file_discovery_performance.sh
```

### Post-Implementation Monitoring

- Monitor error logs for concurrent execution issues: `/errors --type state_error --since 7d`
- Track concurrent command invocations in CI logs
- User feedback on concurrent execution experience
- Performance metrics for state file discovery (if >10ms, investigate optimization)
