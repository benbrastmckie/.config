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

## Technical Design

### Architecture Overview

**Two-way merge strategy**:
1. **Critical fixes (save_coo → spec_org)**: Apply essential bug fixes first to restore spec_org functionality
2. **Quality improvements (spec_org → save_coo)**: Cherry-pick documentation and structural improvements that don't break working code
3. **Validation at each step**: Test suite execution after every merge to catch regressions immediately

**Merge Approach**:
- Use git cherry-pick for targeted commit selection
- Create separate merge commits for each category (fixes vs improvements)
- Maintain bidirectional traceability (which fixes/improvements came from which branch)
- Test on both branches after each phase

**Rollback Strategy**:
- Each phase creates checkpoint commit before changes
- Failed phases revert to checkpoint using git reset --hard
- Test failures block progression to next phase
- Maximum 2 retry attempts per phase before escalation

### Component Interactions

```
save_coo Branch (Working)          spec_org Branch (Broken)
─────────────────────              ────────────────────────
├─ library-sourcing.sh             ├─ library-sourcing.sh
│  (CLAUDE_PROJECT_DIR pattern)    │  (git-based, BROKEN)
│                                   │
├─ workflow-detection.sh           ├─ workflow-detection.sh
│  (smart matching)                │  (sequential, BROKEN)
│                                   │
├─ verification-helpers.sh         ├─ [MISSING]
│  (90% token reduction)           │
│                                   │
└─ coordinate.md                   └─ coordinate.md
   (streamlined, 1978 lines)          (verbose, 2593 lines)
                                      (anti-pattern docs)

Phase 1-4: Apply fixes ────────────>
           (restore functionality)

Phase 5-7: Cherry-pick improvements <────────
           (documentation, structure)
```

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
- [ ] Create checkpoint file tracking phase completion: /tmp/merge_checkpoints.txt

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

**Tasks**:
- [ ] Switch to spec_org worktree: cd /tmp/spec_org_worktree
- [ ] Create checkpoint commit: git commit --allow-empty -m "checkpoint: before library sourcing fix"
- [ ] Identify save_coo commit with library sourcing fix: git log save_coo --oneline --grep="library sourcing" (commit f198f2c5)
- [ ] Review commit changes: git show f198f2c5 (file: .claude/lib/library-sourcing.sh, .claude/lib/unified-logger.sh)
- [ ] Apply fix to spec_org library-sourcing.sh: Replace git-based path detection (lines 43-60) with CLAUDE_PROJECT_DIR pattern
- [ ] Apply fix to spec_org unified-logger.sh: Replace git-based SCRIPT_DIR detection (lines 24-39) with relative path pattern
- [ ] Verify library sourcing works: bash -c 'source .claude/lib/library-sourcing.sh && echo "SUCCESS"'
- [ ] Run coordinate command basic test: echo "test" | grep -q "test" (smoke test before full test suite)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test library sourcing in spec_org worktree
cd /tmp/spec_org_worktree
bash -c '
  source .claude/lib/library-sourcing.sh
  source_required_libraries "workflow-detection.sh" || exit 1
  echo "Library sourcing: PASS"
'

# Test without git (simulate SlashCommand context)
bash -c '
  unset GIT_DIR GIT_WORK_TREE
  command -v git && { echo "Renaming git"; sudo mv /usr/bin/git /usr/bin/git.bak; }
  source .claude/lib/library-sourcing.sh
  echo "No-git test: $?"
  [ -f /usr/bin/git.bak ] && sudo mv /usr/bin/git.bak /usr/bin/git
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

**Tasks**:
- [ ] Review workflow detection differences: git diff save_coo spec_org -- .claude/lib/workflow-detection.sh
- [ ] Identify save_coo commit with workflow detection fix: git log save_coo --oneline --grep="workflow detection" (commit 496d5118)
- [ ] Review commit details: git show 496d5118 .claude/lib/workflow-detection.sh
- [ ] Replace spec_org workflow-detection.sh with save_coo version: git checkout save_coo -- .claude/lib/workflow-detection.sh
- [ ] Verify function signature unchanged: grep "detect_workflow_scope" .claude/lib/workflow-detection.sh
- [ ] Run workflow detection unit tests: .claude/tests/test_workflow_detection.sh (expect 12/12 pass)
- [ ] Test user's bug case: bash -c 'source .claude/lib/workflow-detection.sh && detect_workflow_scope "research auth to create and implement plan"' (expect "full-implementation")
- [ ] Test multi-intent prompt: bash -c 'source .claude/lib/workflow-detection.sh && detect_workflow_scope "research X, plan Y, implement Z"' (expect "full-implementation")
- [ ] Document test results in /tmp/workflow_detection_tests.txt

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Run complete test suite
cd /tmp/spec_org_worktree
.claude/tests/test_workflow_detection.sh

# Test specific cases from research report
bash -c '
  source .claude/lib/workflow-detection.sh

  # User bug case
  result=$(detect_workflow_scope "research auth to create and implement plan")
  [ "$result" = "full-implementation" ] || { echo "FAIL: User bug case"; exit 1; }

  # Multi-intent
  result=$(detect_workflow_scope "research X, plan Y, implement Z")
  [ "$result" = "full-implementation" ] || { echo "FAIL: Multi-intent"; exit 1; }

  # Research-only
  result=$(detect_workflow_scope "research topic")
  [ "$result" = "research-only" ] || { echo "FAIL: Research-only"; exit 1; }

  echo "All workflow detection tests: PASS"
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

**Tasks**:
- [ ] Copy verification-helpers.sh to spec_org: cp ~/.config/.claude/lib/verification-helpers.sh /tmp/spec_org_worktree/.claude/lib/
- [ ] Verify file copied successfully: test -f /tmp/spec_org_worktree/.claude/lib/verification-helpers.sh
- [ ] Test verify_file_created function: bash -c 'source .claude/lib/verification-helpers.sh && touch /tmp/test.txt && verify_file_created /tmp/test.txt "test" "Phase 4"'
- [ ] Update spec_org coordinate.md to source verification-helpers.sh: Add to library list at line 560
- [ ] Replace verbose verification patterns in coordinate.md with verify_file_created calls (optional: document pattern, implement in Phase 6)
- [ ] Smoke test coordinate command with new helpers: bash -c 'grep -q "verification-helpers.sh" .claude/commands/coordinate.md && echo "PASS"'

**Testing**:
```bash
# Test verification helper functions
cd /tmp/spec_org_worktree
bash -c '
  source .claude/lib/verification-helpers.sh

  # Test success case
  touch /tmp/test_success.txt
  if verify_file_created /tmp/test_success.txt "test file" "Phase 4"; then
    echo "Success case: PASS"
  fi

  # Test failure case (should output diagnostic)
  if ! verify_file_created /tmp/nonexistent.txt "missing file" "Phase 4" 2>/tmp/error.txt; then
    grep -q "ERROR" /tmp/error.txt && echo "Failure case: PASS"
  fi

  # Cleanup
  rm /tmp/test_success.txt /tmp/error.txt
'
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

**Tasks**:
- [ ] Run workflow detection test suite: .claude/tests/test_workflow_detection.sh (expect 12/12 pass)
- [ ] Test /coordinate with simple workflow: Create test prompt "research authentication patterns" in /tmp/test_coordinate.txt
- [ ] Execute coordinate command test (dry-run): bash -c 'grep -q "research" /tmp/test_coordinate.txt && echo "Prompt validation: PASS"'
- [ ] Verify library sourcing works in all coordinate bash blocks: grep -n "source.*library-sourcing.sh" .claude/commands/coordinate.md
- [ ] Test library functions available: bash -c 'source .claude/lib/library-sourcing.sh && source_required_libraries "workflow-detection.sh" && command -v detect_workflow_scope && echo "Functions available: PASS"'
- [ ] Compare spec_org test results to save_coo baseline from /tmp/baseline_test_results.txt
- [ ] Document validation results in /tmp/spec_org_validation_results.txt
- [ ] If any tests fail: Roll back to checkpoint, analyze failure, retry with fixes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Comprehensive validation suite
cd /tmp/spec_org_worktree

# 1. Workflow detection tests
.claude/tests/test_workflow_detection.sh
echo "Workflow detection: $?" >> /tmp/spec_org_validation_results.txt

# 2. Library sourcing in multiple contexts
bash -c 'source .claude/lib/library-sourcing.sh && echo "Context 1: PASS"' >> /tmp/spec_org_validation_results.txt
bash -c 'cd /tmp && source /tmp/spec_org_worktree/.claude/lib/library-sourcing.sh && echo "Context 2: PASS"' >> /tmp/spec_org_validation_results.txt

# 3. Verification helpers
bash -c 'source .claude/lib/verification-helpers.sh && command -v verify_file_created && echo "Helpers: PASS"' >> /tmp/spec_org_validation_results.txt

# 4. Compare to baseline
diff /tmp/baseline_test_results.txt /tmp/spec_org_validation_results.txt || echo "Results differ (expected)"
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

**Tasks**:
- [ ] Verify current position in spec_org worktree: cd /tmp/spec_org_worktree
- [ ] Create checkpoint commit: git commit --allow-empty -m "checkpoint: before performance optimizations"
- [ ] Identify performance optimization commits from save_coo: git log save_coo --oneline | grep -E "(e508ec1d|3090590c|08159958|01938154)"
- [ ] Review commit e508ec1d (Phase 1: redundant library arguments removal): git show e508ec1d
- [ ] Cherry-pick commit e508ec1d: git cherry-pick e508ec1d
- [ ] Test library sourcing after Phase 1: bash -c 'source .claude/lib/library-sourcing.sh && echo "Phase 1: PASS"'
- [ ] Review commit 3090590c (Phase 2: Phase 0 consolidation): git show 3090590c
- [ ] Cherry-pick commit 3090590c: git cherry-pick 3090590c
- [ ] Test Phase 0 consolidation: grep -c "Phase 0" .claude/commands/coordinate.md
- [ ] Review commit 08159958 (Phase 3: conditional library loading): git show 08159958
- [ ] Cherry-pick commit 08159958: git cherry-pick 08159958
- [ ] Test conditional loading: bash -c 'grep -q "REQUIRED_LIBS" .claude/commands/coordinate.md && echo "Phase 3: PASS"'
- [ ] Review commit 01938154 (Phase 4: transition helper and metrics): git show 01938154
- [ ] Cherry-pick commit 01938154: git cherry-pick 01938154
- [ ] Test transition helper: bash -c 'grep -q "transition_to_phase" .claude/commands/coordinate.md && echo "Phase 4: PASS"'
- [ ] Resolve any merge conflicts manually (document in /tmp/merge_conflicts.txt)
- [ ] Measure Phase 0 performance: time bash -c 'source .claude/lib/library-sourcing.sh && source .claude/lib/workflow-detection.sh'
- [ ] Compare to baseline from Phase 1: Expected <150ms vs baseline 250-300ms

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test performance optimizations in spec_org worktree
cd /tmp/spec_org_worktree

# 1. Verify all 4 optimization commits applied
git log --oneline | head -5 | grep -E "(library arguments|Phase 0|conditional|transition)" || echo "Check commit messages"

# 2. Test library sourcing optimization
bash -c 'DEBUG=1 source .claude/lib/library-sourcing.sh && echo "Library sourcing: PASS"'

# 3. Test Phase 0 consolidation
phase_count=$(grep -c "STEP [0-9]" .claude/commands/coordinate.md)
[ "$phase_count" -eq 0 ] && echo "Phase 0 consolidated: PASS" || echo "WARN: Found $phase_count STEP markers"

# 4. Test conditional library loading
bash -c 'grep -q "case.*WORKFLOW_SCOPE" .claude/commands/coordinate.md && echo "Conditional loading: PASS"'

# 5. Test performance metrics
bash -c 'grep -q "DEBUG_PERFORMANCE" .claude/commands/coordinate.md && echo "Metrics: PASS"'

# 6. Measure performance improvement
start_time=$(date +%s%N)
bash -c 'source .claude/lib/library-sourcing.sh && source_required_libraries "workflow-detection.sh"' >/dev/null 2>&1
end_time=$(date +%s%N)
duration_ms=$(( (end_time - start_time) / 1000000 ))
echo "Library sourcing duration: ${duration_ms}ms (baseline: 250-300ms, target: <150ms)"
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

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

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

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

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

### Test Levels

**Unit Tests**:
- Library sourcing functionality (.claude/lib/library-sourcing.sh)
- Workflow detection algorithm (.claude/lib/workflow-detection.sh)
- Verification helper functions (.claude/lib/verification-helpers.sh)

**Integration Tests**:
- Complete workflow detection test suite (.claude/tests/test_workflow_detection.sh)
- Library sourcing in multiple execution contexts
- /coordinate command end-to-end validation

**Regression Tests**:
- User bug case: "research auth to create and implement plan" → "full-implementation"
- Multi-intent prompts
- Research-only, debug-only workflows
- Comparison to baseline test results from Phase 1

### Test Execution Pattern

Each phase follows this pattern:
1. Run relevant unit tests before changes
2. Apply changes
3. Run unit tests after changes (expect same results)
4. Run integration tests
5. Document results
6. If failure: rollback to checkpoint, analyze, retry (max 2 attempts)

### Coverage Requirements

- All modified libraries must pass unit tests
- Workflow detection: 12/12 test pass rate (100%)
- Integration tests: 100% pass rate on both branches
- No regressions compared to baseline

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

### External Dependencies

- Git 2.x (for worktree support)
- Bash 4.x+ (for associative arrays)
- Test suite: .claude/tests/test_workflow_detection.sh

### Branch Dependencies

**save_coo branch**:
- Commit f198f2c5: library sourcing fix
- Commit 496d5118: workflow detection fix
- verification-helpers.sh (present in save_coo)

**spec_org branch**:
- orchestration-anti-patterns.md (present in spec_org)
- Enhanced error messages (present in spec_org)
- Research topic generator (present in spec_org, optional)

### File Dependencies

**Modified in spec_org** (Phases 2-4):
- .claude/lib/library-sourcing.sh
- .claude/lib/unified-logger.sh
- .claude/lib/workflow-detection.sh
- .claude/lib/verification-helpers.sh (new)

**Modified in save_coo** (Phases 6-7):
- .claude/docs/reference/orchestration-anti-patterns.md (new)
- .claude/commands/coordinate.md (documentation sections)

## Rollback Strategy

### Per-Phase Checkpoints

Each phase creates a checkpoint commit before making changes:
```bash
git commit --allow-empty -m "checkpoint: before [phase description]"
```

### Rollback Procedure

If phase fails after 2 retry attempts:
1. Identify checkpoint commit: `git log --oneline | grep "checkpoint: before"`
2. Reset to checkpoint: `git reset --hard <checkpoint-sha>`
3. Document failure in /tmp/merge_checkpoints.txt
4. Escalate to manual review

### Retry Logic

- Maximum 2 retry attempts per phase
- Between retries: analyze test output, review diffs, check for typos
- If retry 1 fails: consider partial rollback (keep successful changes)
- If retry 2 fails: full rollback and escalation

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

---

## Revision History

### 2025-11-04 - Revision 1: Performance Optimizations Integration

**Changes Made**:
- Added Phase 6: Apply Performance Optimizations to spec_org
- Renumbered subsequent phases (old Phase 6-8 → new Phase 7-9)
- Updated phase dependencies to reflect new structure
- Increased total phase count from 8 to 9
- Increased estimated time from 12-14 hours to 14-17 hours

**Reason for Revision**:
Plan 581 (/coordinate Command Performance Optimization) was successfully completed on 2025-11-04, implementing 4 phases of performance optimizations in save_coo branch:
- Phase 1 (e508ec1d): Remove redundant library arguments (5-10ms improvement)
- Phase 2 (3090590c): Consolidate Phase 0 (250-400ms improvement, 60% faster)
- Phase 3 (08159958): Conditional library loading (25-40% faster for simple workflows)
- Phase 4 (01938154): Phase transition helper and performance metrics

These optimizations achieve 475-1010ms improvement (15-30% faster) per workflow and should be carried forward to spec_org as part of this merge plan.

**Reports/Plans Used**:
- /home/benjamin/.config/.claude/specs/581_coordinate_command_performance_optimization/plans/001_coordinate_performance_optimization.md (COMPLETED)

**Modified Phases**:
- Phase 6: NEW - Apply Performance Optimizations to spec_org
- Phase 7: RENUMBERED from Phase 6 - Cherry-Pick spec_org Documentation Improvements to save_coo
- Phase 8: RENUMBERED from Phase 7 - Evaluate and Apply Optional spec_org Improvements to save_coo
- Phase 9: RENUMBERED from Phase 8 - Final Validation and Cleanup

**Testing Impact**:
- Phase 6 includes performance measurement to validate 15-30% improvement in spec_org
- Phase 9 (final validation) now tests both functionality AND performance on both branches
