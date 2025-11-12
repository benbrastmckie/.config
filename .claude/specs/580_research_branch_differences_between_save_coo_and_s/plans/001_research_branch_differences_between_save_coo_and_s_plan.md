# Branch Merge and Evaluation Implementation Plan

## Metadata
- **Date**: 2025-11-04
- **Last Updated**: 2025-11-04 (after Plan 581 completion)
- **Feature**: Merge critical fixes from save_coo to spec_org and evaluate positive spec_org changes for save_coo
- **Scope**: Two-way branch reconciliation focusing on /coordinate command reliability and performance
- **Estimated Phases**: 9 (updated from 8)
- **Estimated Hours**: 14-17 (updated from 12-14)
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/580_research_branch_differences_between_save_coo_and_s/reports/001_coordinate_command_differences_research.md
  - /home/benjamin/.config/.claude/specs/580_research_branch_differences_between_save_coo_and_s/reports/002_library_infrastructure_differences_research.md
  - /home/benjamin/.config/.claude/specs/580_research_branch_differences_between_save_coo_and_s/reports/003_positive_spec_org_changes_research.md
- **Related Implementations**:
  - /home/benjamin/.config/.claude/specs/581_coordinate_command_performance_optimization/plans/001_coordinate_performance_optimization.md (COMPLETED 2025-11-04)

## Checkpoint Protocol

Track phase completion using `.claude/lib/checkpoint-580.sh`:

```bash
source .claude/lib/checkpoint-580.sh
record_phase_completion <phase_number> "<phase_name>"
```

All phases reference this protocol for completion tracking. Checkpoints saved to `/tmp/merge_checkpoints.txt`.

## Overview

This plan addresses the reconciliation of critical bug fixes and beneficial improvements between the save_coo and spec_org branches. The save_coo branch contains three essential bug fixes that make /coordinate functional (path detection, workflow detection, verification helpers), while spec_org contains valuable documentation and architectural improvements. The implementation follows a fail-fast, test-driven approach with rollback capability at each phase.

**Update (2025-11-04)**: Plan 581 was successfully implemented, adding significant performance optimizations to save_coo's /coordinate command (475-1010ms improvement, 15-30% faster). This plan has been revised to include these optimizations in the merge strategy, as they represent additional valuable improvements to carry forward to spec_org.

## Research Summary

**Critical Issues in spec_org** (from Report 2):
- Git-based library sourcing fails in SlashCommand context (requires git command, fails in worktrees)
- Sequential workflow detection causes false positives (returns "research-and-plan" instead of "full-implementation")
- Missing verification-helpers.sh causes verbose checkpoint patterns (90% token overhead)

**Essential Fixes in save_coo** (from Report 2):
- CLAUDE_PROJECT_DIR-based library sourcing with pwd fallback (works everywhere, zero git dependencies)
- Smart workflow detection algorithm preventing false positives (12/12 test pass rate)
- Concise verification helpers (90% token reduction at checkpoints)

**Positive Improvements in spec_org** (from Report 3):
- Orchestration anti-pattern documentation (94 lines, clear guidance with case studies)
- Enhanced error messages with fail-fast diagnostics
- Research topic generator utility (consolidates inline logic)
- Single-responsibility function refactoring in workflow-initialization.sh
- Comprehensive implementation documentation with rationale

**Performance Optimizations in save_coo** (from Plan 581, completed 2025-11-04):
- Phase 0 consolidation: Reduced execution time from 250-300ms to 100-150ms (60% improvement)
- Library sourcing optimization: Reduced redundant operations from 4-5 to 1-2 per workflow
- Conditional library loading: research-only 25-40% faster, research-and-plan 15-25% faster
- Silent debug output: Clean console by default (DEBUG=1 to enable)
- Phase transition helper: transition_to_phase() function eliminates duplicate markers
- Performance metrics: DEBUG_PERFORMANCE=1 for timing instrumentation
- Git commits: e508ec1d, 3090590c, 08159958, 01938154

## Success Criteria

- [ ] All critical save_coo fixes applied to spec_org branch
- [ ] /coordinate command functional in spec_org after fixes
- [ ] All 12 workflow detection tests passing in spec_org
- [ ] Performance optimizations (Plan 581) applied to spec_org
- [ ] spec_org /coordinate shows 15-30% performance improvement after optimizations
- [ ] Selected spec_org improvements applied to save_coo (without breaking functionality)
- [ ] Both branches tested and validated
- [ ] No regressions introduced in either branch
- [ ] Git history clean with atomic commits per phase
- [ ] Complete test coverage for merged changes

## Architectural Standards Compliance

This plan adheres to Claude Code architectural standards:

**Standard 0 (Execution Enforcement)**: ✓ Applied
- All critical phases (2-6) use imperative language (EXECUTE NOW, YOU MUST, MANDATORY)
- Tasks marked as REQUIRED BEFORE next steps
- MANDATORY VERIFICATION blocks explicitly non-optional
- All verification checkpoints include fail-fast error handling

**Standard 11 (Imperative Agent Invocation)**: N/A
- This plan uses direct execution, not agent delegation
- No Task tool invocations required

**Standard 12 (Structural vs Behavioral)**: N/A
- Plan is implementation artifact, not agent behavioral content

**Architectural Patterns Applied**:
- **Verification and Fallback**: All MANDATORY VERIFICATION blocks include explicit failure handling with diagnostics
- **Checkpoint Recovery**: Checkpoint commits before risky operations (Phases 2, 6)
- **Fail-Fast Testing**: Tests exit immediately on failure with CRITICAL messages
- **Context Clarity**: Each verification step includes diagnostic commands for troubleshooting

**Anti-Patterns Avoided**:
- ❌ No verification: All critical operations have MANDATORY VERIFICATION blocks
- ❌ Verification without fallback: All verifications include fail-fast error handling with diagnostic output
- ❌ Silent failures: All errors produce CRITICAL messages with actionable diagnostics
- ❌ Ambiguous success: All successful verifications produce ✓ Verified messages

**Verification Pattern Structure**:
```bash
# CRITICAL: [What MUST work]
if ! [test condition]; then
  echo "CRITICAL: [What failed]"
  echo "DIAGNOSTIC: [How to troubleshoot]"
  exit 1
fi
echo "✓ Verified: [What succeeded]"
```

**References**:
- [Command Architecture Standards](/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md)
- [Verification and Fallback Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md)
- [Checkpoint Recovery Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md)
- [Imperative Language Guide](/home/benjamin/.config/.claude/docs/guides/imperative-language-guide.md)

## Technical Design

### Architecture Overview

Two-way merge: (1) Apply critical fixes save_coo → spec_org, (2) Cherry-pick improvements spec_org → save_coo, (3) Validate both branches. Uses git cherry-pick with checkpoint commits for rollback capability.

## Implementation Phases

### Phase 1: Preparation and Environment Setup
dependencies: []

**Objective**: Establish safe testing environment with both branches accessible and baseline test results documented.

**Complexity**: Low

**Tasks**:
- [ ] Create git worktree for spec_org branch at /tmp/spec_org_worktree (file: .git/worktrees/spec_org)
- [ ] Verify current branch is save_coo with clean working directory (git status)
- [ ] Run workflow detection test suite on save_coo baseline: .claude/tests/test_workflow_detection.sh (expect 12/12 pass)
- [ ] Run workflow detection test suite on spec_org worktree: cd /tmp/spec_org_worktree && .claude/tests/test_workflow_detection.sh (expect failures)
- [ ] Document baseline test results in /tmp/baseline_test_results.txt
- [ ] Record phase completion: source .claude/lib/checkpoint-580.sh && record_phase_completion 1 "Preparation and Environment Setup"

**Testing**:
```bash
# Verify worktree creation
git worktree list | grep spec_org_worktree

# Verify test suite execution
.claude/tests/test_workflow_detection.sh
echo "save_coo tests: $?" >> /tmp/baseline_test_results.txt

cd /tmp/spec_org_worktree
.claude/tests/test_workflow_detection.sh
echo "spec_org tests: $?" >> /tmp/baseline_test_results.txt
```

**Expected Duration**: 30 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (test suite execution confirmed)
- [ ] Git commit created: `chore(580): Phase 1 - Environment setup for branch merge`
- [ ] Checkpoint saved: echo "Phase 1: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 2: Apply Critical Library Sourcing Fix to spec_org
dependencies: [1]

**Objective**: Replace git-based library sourcing with CLAUDE_PROJECT_DIR pattern in spec_org, restoring reliability.

**Complexity**: Medium

**EXECUTE NOW - Library Sourcing Fix Application**:

**STEP 1 (REQUIRED BEFORE STEP 2)**: Switch to spec_org worktree and create checkpoint
- [ ] YOU MUST switch to spec_org worktree: cd /tmp/spec_org_worktree
- [ ] MANDATORY: Create checkpoint commit: git commit --allow-empty -m "checkpoint: before library sourcing fix"

**STEP 2 (REQUIRED BEFORE STEP 3)**: Identify and review library sourcing fix
- [ ] EXECUTE: Identify save_coo commit: git log save_coo --oneline --grep="library sourcing" (commit f198f2c5)
- [ ] EXECUTE: Review commit changes: git show f198f2c5

**STEP 3 (REQUIRED BEFORE STEP 4)**: Apply library sourcing fixes
- [ ] YOU MUST apply fix to library-sourcing.sh: Replace git-based path detection (lines 43-60) with CLAUDE_PROJECT_DIR pattern
- [ ] YOU MUST apply fix to unified-logger.sh: Replace git-based SCRIPT_DIR detection (lines 24-39) with relative path pattern

**STEP 4 (MANDATORY VERIFICATION)**: Verify library sourcing functionality
- [ ] EXECUTE: Verify library sourcing: bash -c 'source .claude/lib/library-sourcing.sh && echo "SUCCESS"'
- [ ] EXECUTE: Run basic smoke test: echo "test" | grep -q "test"

**MANDATORY VERIFICATION - Library Sourcing**:
```bash
# CRITICAL: Library sourcing MUST work in all contexts
cd /tmp/spec_org_worktree

# Test 1: Basic library sourcing (REQUIRED)
if ! source .claude/lib/library-sourcing.sh; then
  echo "CRITICAL: library-sourcing.sh failed to load"
  echo "DIAGNOSTIC: Check CLAUDE_PROJECT_DIR is set or pwd is correct"
  exit 1
fi
echo "✓ Verified: library-sourcing.sh loads successfully"

# Test 2: Library function availability (REQUIRED)
if ! source_required_libraries "workflow-detection.sh"; then
  echo "CRITICAL: source_required_libraries() failed"
  echo "DIAGNOSTIC: Check workflow-detection.sh exists in .claude/lib/"
  exit 1
fi
echo "✓ Verified: source_required_libraries() functional"

# Test 3: Git-free execution (REQUIRED - validates SlashCommand context)
bash -c '
  unset GIT_DIR GIT_WORK_TREE
  if ! source .claude/lib/library-sourcing.sh 2>/dev/null; then
    echo "CRITICAL: Library sourcing requires git command"
    exit 1
  fi
  echo "✓ Verified: Library sourcing works without git"
'
```

**Expected Duration**: 1.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (library sourcing smoke tests)
- [ ] Git commit created: `fix(580): apply CLAUDE_PROJECT_DIR library sourcing to spec_org`
- [ ] Checkpoint saved: echo "Phase 2: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 3: Apply Workflow Detection Fix to spec_org
dependencies: [2]

**Objective**: Replace sequential workflow detection with smart matching algorithm, fixing false positive issues.

**Complexity**: High

**EXECUTE NOW - Workflow Detection Fix Application**:

**STEP 1 (REQUIRED BEFORE STEP 2)**: Review workflow detection differences
- [ ] EXECUTE: Review differences: git diff save_coo spec_org -- .claude/lib/workflow-detection.sh
- [ ] EXECUTE: Identify fix commit: git log save_coo --oneline --grep="workflow detection" (commit 496d5118)
- [ ] EXECUTE: Review commit details: git show 496d5118 .claude/lib/workflow-detection.sh

**STEP 2 (REQUIRED BEFORE STEP 3)**: Replace workflow detection file
- [ ] YOU MUST replace workflow-detection.sh: git checkout save_coo -- .claude/lib/workflow-detection.sh
- [ ] MANDATORY: Verify function signature: grep "detect_workflow_scope" .claude/lib/workflow-detection.sh

**STEP 3 (MANDATORY VERIFICATION)**: Run comprehensive workflow detection tests
- [ ] YOU MUST run unit tests: .claude/tests/test_workflow_detection.sh (REQUIRED: 12/12 pass)
- [ ] EXECUTE: Test user bug case: detect_workflow_scope "research auth to create and implement plan" (MUST return "full-implementation")
- [ ] EXECUTE: Test multi-intent: detect_workflow_scope "research X, plan Y, implement Z" (MUST return "full-implementation")
- [ ] MANDATORY: Document results in /tmp/workflow_detection_tests.txt

**MANDATORY VERIFICATION - Workflow Detection**:
```bash
# CRITICAL: All 12 workflow detection tests MUST pass
cd /tmp/spec_org_worktree

# Test 1: Complete test suite (REQUIRED: 12/12 pass)
if ! .claude/tests/test_workflow_detection.sh; then
  echo "CRITICAL: Workflow detection test suite failed"
  echo "DIAGNOSTIC: Run '.claude/tests/test_workflow_detection.sh' manually for details"
  exit 1
fi
echo "✓ Verified: 12/12 workflow detection tests passing"

# Test 2: User bug case (REQUIRED - validates fix)
bash -c '
  source .claude/lib/workflow-detection.sh
  result=$(detect_workflow_scope "research auth to create and implement plan")
  if [ "$result" != "full-implementation" ]; then
    echo "CRITICAL: User bug case failed (got: $result, expected: full-implementation)"
    exit 1
  fi
  echo "✓ Verified: User bug case fixed"
'

# Test 3: Multi-intent detection (REQUIRED)
bash -c '
  source .claude/lib/workflow-detection.sh
  result=$(detect_workflow_scope "research X, plan Y, implement Z")
  if [ "$result" != "full-implementation" ]; then
    echo "CRITICAL: Multi-intent detection failed (got: $result)"
    exit 1
  fi
  echo "✓ Verified: Multi-intent detection works"
'

# Test 4: Research-only detection (REQUIRED)
bash -c '
  source .claude/lib/workflow-detection.sh
  result=$(detect_workflow_scope "research topic")
  if [ "$result" != "research-only" ]; then
    echo "CRITICAL: Research-only detection failed (got: $result)"
    exit 1
  fi
  echo "✓ Verified: Research-only detection works"
'
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (12/12 workflow detection tests)
- [ ] Git commit created: `fix(580): apply smart workflow detection algorithm to spec_org`
- [ ] Checkpoint saved: echo "Phase 3: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 4: Add Verification Helpers to spec_org
dependencies: [3]

**Objective**: Copy verification-helpers.sh from save_coo to spec_org, enabling concise checkpoint patterns.

**Complexity**: Low

**EXECUTE NOW - Verification Helpers Integration**:

**STEP 1 (REQUIRED BEFORE STEP 2)**: Copy and verify verification helpers
- [ ] YOU MUST copy verification-helpers.sh: cp ~/.config/.claude/lib/verification-helpers.sh /tmp/spec_org_worktree/.claude/lib/
- [ ] MANDATORY: Verify file exists: test -f /tmp/spec_org_worktree/.claude/lib/verification-helpers.sh

**STEP 2 (MANDATORY VERIFICATION)**: Test verification helper functionality
- [ ] EXECUTE: Test verify_file_created function: bash -c 'source .claude/lib/verification-helpers.sh && touch /tmp/test.txt && verify_file_created /tmp/test.txt "test" "Phase 4"'

**STEP 3 (REQUIRED BEFORE COMPLETION)**: Integrate with coordinate command
- [ ] YOU MUST update coordinate.md: Add verification-helpers.sh to library list at line 560
- [ ] EXECUTE: Smoke test: grep -q "verification-helpers.sh" .claude/commands/coordinate.md && echo "PASS"

**MANDATORY VERIFICATION - Verification Helpers Library**:
```bash
# CRITICAL: Verification helper functions MUST be available and functional
cd /tmp/spec_org_worktree

# Test 1: Library loads successfully (REQUIRED)
if ! source .claude/lib/verification-helpers.sh; then
  echo "CRITICAL: verification-helpers.sh failed to load"
  echo "DIAGNOSTIC: Check file exists at .claude/lib/verification-helpers.sh"
  exit 1
fi
echo "✓ Verified: verification-helpers.sh loads successfully"

# Test 2: verify_file_created function exists (REQUIRED)
if ! command -v verify_file_created >/dev/null 2>&1; then
  echo "CRITICAL: verify_file_created function not available"
  echo "DIAGNOSTIC: Source verification-helpers.sh and check function definition"
  exit 1
fi
echo "✓ Verified: verify_file_created function available"

# Test 3: Success case (REQUIRED)
touch /tmp/test_success.txt
if ! verify_file_created /tmp/test_success.txt "test file" "Phase 4"; then
  echo "CRITICAL: verify_file_created failed on existing file"
  rm -f /tmp/test_success.txt
  exit 1
fi
echo "✓ Verified: Success case works"
rm /tmp/test_success.txt

# Test 4: Failure case (REQUIRED - validates diagnostic output)
if verify_file_created /tmp/nonexistent_file_12345.txt "missing file" "Phase 4" 2>/tmp/error.txt; then
  echo "CRITICAL: verify_file_created should fail on nonexistent file"
  rm -f /tmp/error.txt
  exit 1
fi
if ! grep -q "ERROR" /tmp/error.txt; then
  echo "CRITICAL: Error diagnostic not output for missing file"
  cat /tmp/error.txt
  rm -f /tmp/error.txt
  exit 1
fi
echo "✓ Verified: Failure case produces diagnostic"
rm /tmp/error.txt
```

**Expected Duration**: 1 hour

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (verification helper smoke tests)
- [ ] Git commit created: `feat(580): add verification-helpers.sh to spec_org`
- [ ] Checkpoint saved: echo "Phase 4: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 5: Validate spec_org /coordinate Functionality
dependencies: [4]

**Objective**: Comprehensive testing of spec_org /coordinate command after applying all critical fixes.

**Complexity**: Medium

**EXECUTE NOW - Comprehensive Validation**:

**STEP 1 (MANDATORY VERIFICATION)**: Run complete test suite
- [ ] YOU MUST run workflow detection tests: .claude/tests/test_workflow_detection.sh (REQUIRED: 12/12 pass)

**STEP 2 (REQUIRED BEFORE STEP 3)**: Test /coordinate functionality
- [ ] EXECUTE: Create test prompt: echo "research authentication patterns" > /tmp/test_coordinate.txt
- [ ] EXECUTE: Validate prompt: bash -c 'grep -q "research" /tmp/test_coordinate.txt && echo "PASS"'

**STEP 3 (MANDATORY VERIFICATION)**: Verify library integration
- [ ] YOU MUST verify library sourcing: grep -n "source.*library-sourcing.sh" .claude/commands/coordinate.md
- [ ] EXECUTE: Test function availability: source .claude/lib/library-sourcing.sh && command -v detect_workflow_scope

**STEP 4 (REQUIRED BEFORE COMPLETION)**: Compare and document results
- [ ] MANDATORY: Compare to baseline: diff /tmp/baseline_test_results.txt current results
- [ ] YOU MUST document validation: Save results to /tmp/spec_org_validation_results.txt
- [ ] IF TESTS FAIL: Roll back to checkpoint, analyze, retry


**MANDATORY VERIFICATION - Comprehensive Validation**:
```bash
# CRITICAL: All integrated fixes MUST work together
cd /tmp/spec_org_worktree

# Test 1: Workflow detection test suite (REQUIRED: 12/12 pass)
if ! .claude/tests/test_workflow_detection.sh; then
  echo "CRITICAL: Workflow detection test suite failed after integration"
  echo "DIAGNOSTIC: Run '.claude/tests/test_workflow_detection.sh' manually for details"
  exit 1
fi
echo "✓ Verified: 12/12 workflow detection tests passing"
echo "Workflow detection: PASS" >> /tmp/spec_org_validation_results.txt

# Test 2: Library sourcing in multiple contexts (REQUIRED)
if ! bash -c 'source .claude/lib/library-sourcing.sh' 2>/dev/null; then
  echo "CRITICAL: Library sourcing failed in context 1 (pwd context)"
  exit 1
fi
echo "✓ Verified: Library sourcing works in pwd context"
echo "Context 1: PASS" >> /tmp/spec_org_validation_results.txt

if ! bash -c 'cd /tmp && source /tmp/spec_org_worktree/.claude/lib/library-sourcing.sh' 2>/dev/null; then
  echo "CRITICAL: Library sourcing failed in context 2 (absolute path)"
  exit 1
fi
echo "✓ Verified: Library sourcing works with absolute paths"
echo "Context 2: PASS" >> /tmp/spec_org_validation_results.txt

# Test 3: Verification helpers available (REQUIRED)
if ! bash -c 'source .claude/lib/verification-helpers.sh && command -v verify_file_created' >/dev/null 2>&1; then
  echo "CRITICAL: Verification helpers not available after integration"
  exit 1
fi
echo "✓ Verified: Verification helpers integrated"
echo "Helpers: PASS" >> /tmp/spec_org_validation_results.txt

# Test 4: Compare to baseline (informational)
if diff /tmp/baseline_test_results.txt /tmp/spec_org_validation_results.txt >/dev/null 2>&1; then
  echo "INFO: Results match baseline (unexpected - spec_org should be improved)"
else
  echo "✓ Verified: Results differ from baseline (expected - fixes applied)"
fi
```

**Expected Duration**: 1.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all validation tests pass)
- [ ] Git commit created: `test(580): validate spec_org /coordinate after fixes`
- [ ] Checkpoint saved: echo "Phase 5: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 6: Apply Performance Optimizations to spec_org
dependencies: [5]

**Objective**: Cherry-pick performance optimization commits from save_coo (Plan 581) to spec_org to improve execution speed.

**Complexity**: Medium-High

**EXECUTE NOW - Performance Optimization Application**:

**STEP 1 (REQUIRED BEFORE STEP 2)**: Prepare for optimization cherry-picks
- [ ] EXECUTE: Navigate to spec_org: cd /tmp/spec_org_worktree
- [ ] MANDATORY: Create checkpoint: git commit --allow-empty -m "checkpoint: before performance optimizations"
- [ ] EXECUTE: Identify optimization commits: git log save_coo --oneline | grep -E "(e508ec1d|3090590c|08159958|01938154)"

**STEP 2 (REQUIRED BEFORE STEP 3)**: Apply all 4 performance optimizations in sequence
- [ ] YOU MUST review commit e508ec1d: git show e508ec1d
- [ ] YOU MUST cherry-pick e508ec1d: git cherry-pick e508ec1d
- [ ] YOU MUST review commit 3090590c: git show 3090590c
- [ ] YOU MUST cherry-pick 3090590c: git cherry-pick 3090590c
- [ ] YOU MUST review commit 08159958: git show 08159958
- [ ] YOU MUST cherry-pick 08159958: git cherry-pick 08159958
- [ ] YOU MUST review commit 01938154: git show 01938154
- [ ] YOU MUST cherry-pick 01938154: git cherry-pick 01938154
- [ ] IF CONFLICTS: Resolve manually and document in /tmp/merge_conflicts.txt

**STEP 3 (MANDATORY VERIFICATION)**: Measure performance improvement
- [ ] EXECUTE: Measure Phase 0 performance: time bash -c 'source .claude/lib/library-sourcing.sh && source .claude/lib/workflow-detection.sh'
- [ ] MANDATORY: Verify <150ms (baseline 250-300ms = 40-60% improvement)


**MANDATORY VERIFICATION - Performance Optimizations**:
```bash
# CRITICAL: Performance optimizations MUST be applied and functional
cd /tmp/spec_org_worktree

# Test 1: Verify all 4 optimization commits applied (REQUIRED)
commit_count=$(git log --oneline | head -5 | grep -E "(library arguments|Phase 0|conditional|transition)" | wc -l)
if [ "$commit_count" -lt 4 ]; then
  echo "CRITICAL: Not all 4 optimization commits applied (found: $commit_count)"
  echo "DIAGNOSTIC: Run 'git log --oneline | head -10' to check commit history"
  exit 1
fi
echo "✓ Verified: All 4 optimization commits applied"

# Test 2: Library sourcing works with optimizations (REQUIRED)
if ! bash -c 'source .claude/lib/library-sourcing.sh' >/dev/null 2>&1; then
  echo "CRITICAL: Library sourcing broken after performance optimizations"
  echo "DIAGNOSTIC: Run 'bash -c \"DEBUG=1 source .claude/lib/library-sourcing.sh\"' for details"
  exit 1
fi
echo "✓ Verified: Library sourcing functional after optimizations"

# Test 3: Phase 0 consolidation applied (REQUIRED)
if grep -q "^STEP [0-9]" .claude/commands/coordinate.md; then
  echo "CRITICAL: Phase 0 not consolidated (found STEP markers)"
  exit 1
fi
echo "✓ Verified: Phase 0 consolidation applied"

# Test 4: Conditional library loading implemented (REQUIRED)
if ! grep -q "case.*WORKFLOW_SCOPE" .claude/commands/coordinate.md; then
  echo "CRITICAL: Conditional library loading not implemented"
  exit 1
fi
echo "✓ Verified: Conditional library loading implemented"

# Test 5: Performance metrics available (REQUIRED)
if ! grep -q "DEBUG_PERFORMANCE" .claude/commands/coordinate.md; then
  echo "CRITICAL: Performance metrics not available"
  exit 1
fi
echo "✓ Verified: Performance metrics available"

# Test 6: Measure performance improvement (REQUIRED: <150ms)
start_time=$(date +%s%N)
if ! bash -c 'source .claude/lib/library-sourcing.sh && source_required_libraries "workflow-detection.sh"' >/dev/null 2>&1; then
  echo "CRITICAL: Library sourcing failed during performance measurement"
  exit 1
fi
end_time=$(date +%s%N)
duration_ms=$(( (end_time - start_time) / 1000000 ))
if [ "$duration_ms" -gt 150 ]; then
  echo "WARNING: Performance target not met (${duration_ms}ms > 150ms target)"
  echo "INFO: Baseline was 250-300ms, so ${duration_ms}ms is still an improvement"
else
  echo "✓ Verified: Performance target met (${duration_ms}ms < 150ms)"
fi
echo "Library sourcing duration: ${duration_ms}ms"
```

**Expected Duration**: 2.5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all optimization smoke tests)
- [ ] Git commits created (4 cherry-picks): e508ec1d, 3090590c, 08159958, 01938154
- [ ] Checkpoint saved: echo "Phase 6: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 7: Cherry-Pick spec_org Documentation Improvements to save_coo
dependencies: [6]

**Objective**: Apply valuable documentation and structural improvements from spec_org to save_coo without breaking functionality.

**Complexity**: Medium

**Tasks**:
- [ ] Switch back to save_coo branch: cd ~/.config && git checkout save_coo
- [ ] Create checkpoint commit: git commit --allow-empty -m "checkpoint: before spec_org improvements"
- [ ] Copy orchestration anti-pattern documentation: cp /tmp/spec_org_worktree/.claude/docs/reference/orchestration-anti-patterns.md .claude/docs/reference/
- [ ] Verify documentation file exists: test -f .claude/docs/reference/orchestration-anti-patterns.md
- [ ] Update coordinate.md to reference anti-pattern documentation: Add reference at appropriate location (lines 35-50)
- [ ] Add recursive invocation prevention warnings to coordinate.md: Insert from spec_org lines 35-44
- [ ] Add role clarification section to coordinate.md: Insert from spec_org lines 47-65
- [ ] Verify coordinate.md still parses correctly: bash -c 'grep -q "CRITICAL" .claude/commands/coordinate.md && echo "PASS"'
- [ ] Test coordinate command not broken: bash -c 'grep -c "Phase [0-9]" .claude/commands/coordinate.md' (expect >6)


**Testing**:
```bash
# Verify documentation improvements don't break functionality
cd ~/.config

# 1. Check anti-pattern doc exists
test -f .claude/docs/reference/orchestration-anti-patterns.md || { echo "FAIL: Missing doc"; exit 1; }

# 2. Verify coordinate.md references it
grep -q "orchestration-anti-patterns" .claude/commands/coordinate.md || { echo "FAIL: No reference"; exit 1; }

# 3. Smoke test coordinate command structure
phase_count=$(grep -c "^### Phase [0-9]" .claude/commands/coordinate.md)
[ "$phase_count" -ge 6 ] || { echo "FAIL: Phase count $phase_count"; exit 1; }

echo "Documentation improvements: PASS"
```

**Expected Duration**: 1.5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (documentation smoke tests)
- [ ] Git commit created: `docs(580): add orchestration anti-patterns and execution clarifications`
- [ ] Checkpoint saved: echo "Phase 6: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 8: Evaluate and Apply Optional spec_org Improvements to save_coo
dependencies: [7]

**Objective**: Selectively apply non-critical spec_org improvements that enhance maintainability without breaking functionality.

**Complexity**: Low

**Tasks**:
- [ ] Review research topic generator utility: cat /tmp/spec_org_worktree/.claude/lib/research-topic-generator.sh
- [ ] Evaluate if save_coo needs research-topic-generator.sh: Compare inline topic generation in save_coo coordinate.md
- [ ] Decision: Skip research-topic-generator.sh if save_coo handles topics differently (document rationale)
- [ ] Review single-responsibility function refactoring in workflow-initialization.sh: diff ~/.config/.claude/lib/workflow-initialization.sh /tmp/spec_org_worktree/.claude/lib/workflow-initialization.sh
- [ ] Decision: Skip workflow-initialization.sh refactor to avoid breaking working save_coo implementation (document rationale)
- [ ] Review interruption/resume documentation: grep -A20 "Interruption" /tmp/spec_org_worktree/.claude/commands/coordinate.md
- [ ] Add interruption safety documentation to save_coo coordinate.md: Insert section documenting checkpoint behavior and safe interruption
- [ ] Document skipped improvements and rationale in /tmp/skipped_improvements.txt

**Testing**:
```bash
# Verify optional improvements don't break functionality
cd ~/.config

# 1. Test coordinate command still works
bash -c 'grep -q "^### Phase [0-9]" .claude/commands/coordinate.md && echo "Structure: PASS"'

# 2. Verify interruption docs added
grep -q "Interruption" .claude/commands/coordinate.md || echo "No interruption docs (optional)"

# 3. Check library still works
bash -c 'source .claude/lib/workflow-initialization.sh && command -v initialize_workflow_paths && echo "Init functions: PASS"'

# 4. Document skipped items
cat /tmp/skipped_improvements.txt
```

**Expected Duration**: 1 hour

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (functionality preserved)
- [ ] Git commit created: `docs(580): add interruption safety documentation`
- [ ] Checkpoint saved: echo "Phase 7: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

### Phase 9: Final Validation and Cleanup
dependencies: [8]

**Objective**: Comprehensive testing of both branches, cleanup of temporary files, and documentation of merge results.

**Complexity**: Medium

**Tasks**:
- [ ] Run complete test suite on save_coo: .claude/tests/test_workflow_detection.sh (expect 12/12 pass)
- [ ] Run complete test suite on spec_org: cd /tmp/spec_org_worktree && .claude/tests/test_workflow_detection.sh (expect 12/12 pass)
- [ ] Compare test results: diff /tmp/baseline_test_results.txt /tmp/spec_org_validation_results.txt
- [ ] Test /coordinate command on save_coo: Create integration test with "research auth to create and implement plan"
- [ ] Test /coordinate command on spec_org: Same integration test in worktree
- [ ] Verify no regressions in either branch: Review /tmp/merge_checkpoints.txt
- [ ] Document merge summary in /tmp/merge_summary.txt (files changed, commits created, test results)
- [ ] Clean up temporary files: rm /tmp/baseline_test_results.txt /tmp/spec_org_validation_results.txt /tmp/merge_checkpoints.txt /tmp/test_coordinate.txt /tmp/skipped_improvements.txt
- [ ] Remove spec_org worktree: git worktree remove /tmp/spec_org_worktree
- [ ] Create final summary commit on save_coo: git commit --allow-empty -m "chore(580): branch merge complete - summary in merge_summary.txt"


**Testing**:
```bash
# Final comprehensive validation
cd ~/.config

# 1. save_coo test suite
.claude/tests/test_workflow_detection.sh
save_coo_result=$?

# 2. spec_org test suite
cd /tmp/spec_org_worktree
.claude/tests/test_workflow_detection.sh
spec_org_result=$?

# 3. Comparison
cd ~/.config
echo "save_coo: $save_coo_result" > /tmp/merge_summary.txt
echo "spec_org: $spec_org_result" >> /tmp/merge_summary.txt

# 4. Integration test
bash -c '
  source .claude/lib/workflow-detection.sh
  result=$(detect_workflow_scope "research auth to create and implement plan")
  echo "Integration test result: $result" >> /tmp/merge_summary.txt
'

# 5. Verify both pass
[ "$save_coo_result" -eq 0 ] && [ "$spec_org_result" -eq 0 ] && echo "FINAL VALIDATION: PASS" >> /tmp/merge_summary.txt
```

**Expected Duration**: 1.5 hours

**Phase 9 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all final validation tests)
- [ ] Git commit created: `chore(580): Phase 9 - Final validation and cleanup`
- [ ] Checkpoint saved: echo "Phase 9: COMPLETE" >> /tmp/merge_checkpoints.txt
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

See [Testing Protocols](/home/benjamin/.config/CLAUDE.md#testing_protocols) for complete testing standards.

**Plan-Specific Requirements**:
- Workflow detection: 12/12 test pass rate (100%)
- Integration tests: 100% pass rate on both branches
- No regressions compared to baseline (documented in Phase 1)

## Documentation Requirements

### Files to Update

**During implementation**:
- /tmp/baseline_test_results.txt (Phase 1)
- /tmp/workflow_detection_tests.txt (Phase 3)
- /tmp/spec_org_validation_results.txt (Phase 5)
- /tmp/skipped_improvements.txt (Phase 7)
- /tmp/merge_summary.txt (Phase 8)

**After completion**:
- This plan file (mark all tasks [x])
- .claude/docs/reference/orchestration-anti-patterns.md (copied from spec_org)
- .claude/commands/coordinate.md (documentation improvements)

### Documentation Standards

- All test results documented with timestamps
- All decisions documented with rationale (especially skipped improvements)
- All commits follow conventional commit format
- Final summary includes file counts, test results, and lessons learned

## Dependencies

**External**: Git 2.x, Bash 4.x+, .claude/tests/test_workflow_detection.sh

**Branch-Specific**: save_coo (commits f198f2c5, 496d5118, verification-helpers.sh) → spec_org; spec_org (orchestration-anti-patterns.md) → save_coo

## Rollback Strategy

See [Checkpoint Recovery Pattern](/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md) for complete rollback procedures.

**Per-Phase**: Checkpoint commit before changes, git reset --hard on failure, max 2 retries before escalation.

## Risk Assessment

### High-Risk Areas

1. **Library sourcing changes** (Phase 2)
   - Risk: Breaking all bash blocks in /coordinate
   - Mitigation: Comprehensive smoke tests, multiple execution contexts
   - Rollback: Checkpoint commit before changes

2. **Workflow detection algorithm** (Phase 3)
   - Risk: False positives/negatives in workflow detection
   - Mitigation: 12-test suite validation, user bug case verification
   - Rollback: Checkpoint commit before changes

### Medium-Risk Areas

1. **Documentation updates** (Phase 6)
   - Risk: Breaking /coordinate command structure
   - Mitigation: Structural validation, phase count verification
   - Rollback: Checkpoint commit before changes

### Low-Risk Areas

1. **Verification helpers** (Phase 4)
   - Risk: Low (additive change, doesn't modify existing code)
   - Mitigation: Smoke tests only

2. **Optional improvements** (Phase 7)
   - Risk: Very low (documentation only)
   - Mitigation: Functionality preservation tests

## Success Metrics

### Functional Metrics

- [ ] spec_org /coordinate command functional after fixes (Phases 2-4)
- [ ] 12/12 workflow detection tests passing on both branches
- [ ] No regressions in save_coo after improvements (Phases 6-7)
- [ ] User bug case resolved on spec_org

### Quality Metrics

- [ ] 100% test pass rate on both branches
- [ ] All commits follow atomic commit pattern
- [ ] All phases completed without rollback
- [ ] Documentation improvements integrated without breaking functionality

### Performance Metrics

- [ ] No performance degradation in library sourcing (measure with `time bash -c 'source ...'`)
- [ ] No increase in /coordinate command execution time
- [ ] Test suite execution time unchanged

## Notes

- **Branch Strategy**: save_coo is working branch, spec_org is broken but has good documentation
- **Merge Direction**: Critical fixes (save_coo → spec_org), Documentation (spec_org → save_coo), Performance optimizations (save_coo → spec_org)
- **Testing Philosophy**: Fail-fast with comprehensive validation at each phase
- **Rollback Philosophy**: Checkpoint before every risky change, max 2 retries before escalation
- **Documentation Philosophy**: Document all decisions, especially skipped improvements

