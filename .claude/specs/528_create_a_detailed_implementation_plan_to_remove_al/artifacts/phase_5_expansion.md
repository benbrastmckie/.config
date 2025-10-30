# Phase 5 Expansion: Final Validation and Commit

## Metadata
- **Phase Number**: 5
- **Parent Plan**: 003_unified_compatibility_removal_plan.md
- **Complexity**: Very High (9/10) - Comprehensive validation and documentation
- **Estimated Duration**: 90-120 minutes
- **Risk Level**: Medium (complexity in coordination, not technical risk)
- **Dependencies**: Phases 1-4 must be complete
- **Rollback Strategy**: Single atomic commit enables clean `git revert`

## Objective

Complete the compatibility layer removal with comprehensive validation, documentation updates, and a single atomic commit. This phase ensures:

1. **Zero test failures** - All 77 tests must pass (100% requirement)
2. **Complete layer removal** - No references to any of the 4 compatibility layers
3. **Documentation currency** - All docs reflect canonical functions only
4. **Production readiness** - Clean-break philosophy fully implemented
5. **Rollback readiness** - Single commit enables instant revert if needed

**Success Criteria**: Production-ready codebase with all compatibility layers removed, comprehensive documentation updates, passing test suite, and fail-fast behavior validated.

## Implementation Strategy

This phase follows a **validate-document-commit** workflow:

1. **Validation First** - Verify all technical changes before documentation
2. **Comprehensive Documentation** - Update all 5 documentation categories systematically
3. **Git Workflow** - Single atomic commit with complete changeset
4. **Quality Assurance** - Final verification of all success criteria
5. **Fail-Fast Validation** - Confirm immediate errors for missing compatibility functions

**Time Allocation**:
- Stage 1 (Test Validation): 15-20 minutes
- Stage 2 (Reference Verification): 10-15 minutes
- Stage 3 (Documentation): 45-60 minutes
- Stage 4 (Git Workflow): 10-15 minutes
- Stage 5 (QA): 10-15 minutes

---

## Stage 1: Test Suite Validation

### 1.1: Pre-Check Environment

**Objective**: Ensure test environment is clean and ready.

**Tasks**:
- [ ] Verify current working directory: `pwd` (should be `/home/benjamin/.config`)
- [ ] Verify git status is clean except for planned changes:
  ```bash
  git status --short
  ```
- [ ] Check no background processes interfere with tests:
  ```bash
  ps aux | grep -E "(test|bash.*\.sh)" | grep -v grep
  ```
- [ ] Verify test runner is executable:
  ```bash
  ls -la .claude/tests/run_all_tests.sh
  ```

**Expected Output**: Clean working tree except for modified files from Phases 1-4, no conflicting processes, executable test runner.

### 1.2: Execute Full Test Suite

**Objective**: Run all 77 tests and capture complete results.

**Tasks**:
- [ ] Run full test suite with output capture:
  ```bash
  .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/phase5_test_results.log
  ```
- [ ] Wait for completion (estimated 3-5 minutes)
- [ ] Verify exit code is 0:
  ```bash
  echo "Exit code: $?"
  ```
- [ ] Count passing tests:
  ```bash
  grep -c "PASSED" /tmp/phase5_test_results.log
  ```

**Expected Output**: 77/77 tests PASSED, exit code 0.

### 1.3: Failure Analysis (If Any Failures)

**Objective**: If any test fails, diagnose and fix before proceeding.

**Tasks** (only if failures detected):
- [ ] Identify failing test files:
  ```bash
  grep "FAILED" /tmp/phase5_test_results.log
  ```
- [ ] For each failing test, extract failure details:
  ```bash
  grep -A 10 "FAILED" /tmp/phase5_test_results.log
  ```
- [ ] Determine failure category:
  - **Compatibility layer reference**: Function not found error → Check Phase 1-4 migrations
  - **Test infrastructure**: Path or setup issue → Check test environment
  - **Unrelated bug**: Pre-existing issue → Document and defer if not blocking

**Resolution Strategy**:
- Compatibility layer failures: Return to relevant phase and complete migration
- Test infrastructure: Fix test setup, re-run
- Unrelated bugs: Document in plan notes, evaluate criticality

**Critical Requirement**: **All 77 tests must pass before proceeding to Stage 2**. No exceptions.

### 1.4: Test Stability Check

**Objective**: Confirm tests are stable, not flaky.

**Tasks**:
- [ ] Run test suite a second time:
  ```bash
  .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/phase5_test_results_run2.log
  ```
- [ ] Compare results between runs:
  ```bash
  diff /tmp/phase5_test_results.log /tmp/phase5_test_results_run2.log
  ```
- [ ] Verify identical pass/fail status for all tests

**Expected Outcome**: Identical results across both runs (confirms stability).

---

## Stage 2: Reference Verification

### 2.1: Verify Artifact Operations Removal

**Objective**: Confirm no references to `artifact-operations.sh` or its functions remain.

**Tasks**:
- [ ] Search for shim file references:
  ```bash
  grep -r "artifact-operations" .claude/ 2>/dev/null | grep -v ".git" | grep -v "Binary file"
  ```
- [ ] Search for specific function references:
  ```bash
  grep -rE "^[[:space:]]*[a-z_]+_artifact" .claude/ 2>/dev/null | grep -v ".git" | grep -v "# "
  ```
- [ ] Check for source/dot-import of shim:
  ```bash
  grep -rE "(source|\.) .*/artifact-operations\.sh" .claude/ 2>/dev/null | grep -v ".git"
  ```

**Expected Output**: Zero matches (all references migrated to `spec-updater-agent.sh` in Phase 1).

**If Matches Found**:
- Document file path and line number
- Return to Phase 1 and complete migration for missed reference
- Re-run Stage 1 tests after fix

### 2.2: Verify Error Handling Aliases Removal

**Objective**: Confirm no references to deprecated error handling aliases remain.

**Tasks**:
- [ ] Search for `detect_specific_error_type`:
  ```bash
  grep -r "detect_specific_error_type" .claude/ 2>/dev/null | grep -v ".git" | grep -v "^#"
  ```
- [ ] Search for `extract_error_location`:
  ```bash
  grep -r "extract_error_location" .claude/ 2>/dev/null | grep -v ".git" | grep -v "^#"
  ```
- [ ] Search for `suggest_recovery_actions`:
  ```bash
  grep -r "suggest_recovery_actions" .claude/ 2>/dev/null | grep -v ".git" | grep -v "^#"
  ```
- [ ] Verify canonical functions are used instead:
  ```bash
  grep -rE "(detect_error_type|extract_file_and_line|suggest_recovery)" .claude/ 2>/dev/null | wc -l
  ```

**Expected Output**: Zero alias matches, multiple canonical function matches.

**If Matches Found**:
- Document file path and line number
- Return to Phase 2 and complete migration for missed reference
- Re-run Stage 1 tests after fix

### 2.3: Verify Logging Wrapper Removal

**Objective**: Confirm no references to deprecated logging wrappers remain.

**Tasks**:
- [ ] Search for `rotate_log_if_needed`:
  ```bash
  grep -r "rotate_log_if_needed" .claude/ 2>/dev/null | grep -v ".git" | grep -v "^#"
  ```
- [ ] Search for `rotate_conversion_log_if_needed`:
  ```bash
  grep -r "rotate_conversion_log_if_needed" .claude/ 2>/dev/null | grep -v ".git" | grep -v "^#"
  ```
- [ ] Verify canonical function is used instead:
  ```bash
  grep -r "rotate_log_file" .claude/ 2>/dev/null | wc -l
  ```

**Expected Output**: Zero wrapper matches, multiple `rotate_log_file` matches.

**If Matches Found**:
- Document file path and line number
- Return to Phase 3 and complete migration for missed reference
- Re-run Stage 1 tests after fix

### 2.4: Verify Location Context Function Removal

**Objective**: Confirm `generate_legacy_location_context` is completely removed.

**Tasks**:
- [ ] Search for function definition:
  ```bash
  grep -r "generate_legacy_location_context" .claude/ 2>/dev/null | grep -v ".git"
  ```
- [ ] Search for function calls:
  ```bash
  grep -rE "^[[:space:]]*generate_legacy_location_context" .claude/ 2>/dev/null | grep -v ".git"
  ```

**Expected Output**: Zero matches (function deleted in Phase 4).

**If Matches Found**:
- Document location
- Return to Phase 4 and complete deletion
- Re-run Stage 1 tests after fix

### 2.5: Verify File Deletions

**Objective**: Confirm all 4 compatibility files/sections are deleted.

**Tasks**:
- [ ] Verify `artifact-operations.sh` is deleted:
  ```bash
  ls -la .claude/lib/artifact-operations.sh 2>&1
  ```
- [ ] Verify error handling aliases section removed:
  ```bash
  grep -A 5 "# Backward Compatibility Aliases" .claude/lib/error-handling.sh
  ```
- [ ] Verify logging wrappers section removed:
  ```bash
  grep -A 5 "# Backward Compatibility Wrappers" .claude/lib/unified-logger.sh
  ```
- [ ] Verify `generate_legacy_location_context` removed:
  ```bash
  grep -A 3 "generate_legacy_location_context()" .claude/lib/unified-location-detection.sh
  ```

**Expected Output**: File not found error for artifact-operations.sh, zero grep matches for all sections.

**If Files/Sections Exist**:
- Document what remains
- Delete manually following clean-break philosophy
- Re-run Stage 1 tests after deletion

---

## Stage 3: Documentation Updates

### 3.1: Library Inline Documentation

#### 3.1.1: Update error-handling.sh

**Objective**: Remove compatibility alias documentation from inline comments.

**Tasks**:
- [ ] Open `.claude/lib/error-handling.sh` for editing
- [ ] Locate file header documentation (lines 1-30)
- [ ] Remove any mentions of deprecated aliases:
  - Remove `detect_specific_error_type` references
  - Remove `extract_error_location` references
  - Remove `suggest_recovery_actions` references
- [ ] Update function list to show only canonical functions:
  - `detect_error_type()`
  - `extract_file_and_line()`
  - `suggest_recovery()`
- [ ] Verify no "backward compatibility" or "deprecated" language remains
- [ ] Add note about clean-break migration date if appropriate
- [ ] Save file

**Verification**:
```bash
grep -i "backward\|compat\|alias\|deprecated" .claude/lib/error-handling.sh | grep -v "^#.*Clean-break"
```
Expected: Zero matches or only clean-break migration note.

#### 3.1.2: Update unified-logger.sh

**Objective**: Remove logging wrapper documentation from inline comments.

**Tasks**:
- [ ] Open `.claude/lib/unified-logger.sh` for editing
- [ ] Locate file header documentation (lines 1-40)
- [ ] Remove any mentions of deprecated wrappers:
  - Remove `rotate_log_if_needed` references
  - Remove `rotate_conversion_log_if_needed` references
- [ ] Update function list to show only canonical function:
  - `rotate_log_file()`
- [ ] Update usage examples to use only `rotate_log_file`
- [ ] Verify no "backward compatibility" or "wrapper" language remains
- [ ] Save file

**Verification**:
```bash
grep -i "wrapper\|compat\|deprecated\|_if_needed" .claude/lib/unified-logger.sh | grep -v "^#.*Clean-break"
```
Expected: Zero matches or only clean-break migration note.

#### 3.1.3: Update unified-location-detection.sh

**Objective**: Remove legacy location context documentation from inline comments.

**Tasks**:
- [ ] Open `.claude/lib/unified-location-detection.sh` for editing
- [ ] Locate file header documentation (lines 1-50)
- [ ] Remove any mentions of `generate_legacy_location_context`
- [ ] Update function list (if present) to exclude removed function
- [ ] Verify no "legacy" or "backward compatibility" language remains
- [ ] Save file

**Verification**:
```bash
grep -i "legacy\|compat\|deprecated" .claude/lib/unified-location-detection.sh | grep -v "^#.*Clean-break"
```
Expected: Zero matches or only clean-break migration note.

### 3.2: Library Directory README

#### 3.2.1: Update .claude/lib/README.md

**Objective**: Remove compatibility layer references and update library inventory.

**Tasks**:
- [ ] Open `.claude/lib/README.md` for editing
- [ ] Locate "Library Inventory" or "Files" section
- [ ] Remove `artifact-operations.sh` entry completely
- [ ] Update `error-handling.sh` entry:
  - Remove alias function names
  - Show only canonical functions
- [ ] Update `unified-logger.sh` entry:
  - Remove wrapper function names
  - Show only canonical function
- [ ] Update `unified-location-detection.sh` entry:
  - Remove `generate_legacy_location_context`
- [ ] Search for "compatibility" or "migration" sections:
  - Remove any compatibility layer migration guides
  - Remove any deprecation notices
- [ ] Update any usage examples to use canonical functions
- [ ] Verify table of contents (if present) is accurate
- [ ] Save file

**Verification**:
```bash
grep -E "artifact-operations|detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed|generate_legacy_location_context" .claude/lib/README.md
```
Expected: Zero matches.

### 3.3: Standards Documentation

#### 3.3.1: Update library-api.md

**Objective**: Remove all compatibility function references from API documentation.

**Tasks**:
- [ ] Open `.claude/docs/reference/library-api.md` for editing
- [ ] Search for each compatibility function:
  - `artifact-operations.sh` functions (all 10+)
  - Error handling aliases (3 functions)
  - Logging wrappers (2 functions)
  - `generate_legacy_location_context` (1 function)
- [ ] For each found reference:
  - Remove function signature documentation
  - Remove usage examples
  - Remove any "see also" cross-references
- [ ] Update "Available Libraries" section:
  - Remove `artifact-operations.sh` entry
  - Update counts for modified libraries
- [ ] Update any code examples to use canonical functions
- [ ] Search for "compatibility" or "deprecated" sections and remove
- [ ] Verify all remaining function references are canonical
- [ ] Save file

**Verification**:
```bash
grep -E "artifact-operations|detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed|generate_legacy_location_context" .claude/docs/reference/library-api.md
```
Expected: Zero matches.

#### 3.3.2: Update command-development-guide.md

**Objective**: Update command development examples to use canonical functions.

**Tasks**:
- [ ] Open `.claude/docs/guides/command-development-guide.md` for editing
- [ ] Search for code examples using compatibility functions
- [ ] Update error handling examples:
  - Replace `detect_specific_error_type` → `detect_error_type`
  - Replace `extract_error_location` → `extract_file_and_line`
  - Replace `suggest_recovery_actions` → `suggest_recovery`
- [ ] Update logging examples:
  - Replace `rotate_log_if_needed` → `rotate_log_file`
  - Replace `rotate_conversion_log_if_needed` → `rotate_log_file`
- [ ] Remove any references to `artifact-operations.sh`:
  - Update to use `spec-updater-agent.sh` instead
- [ ] Verify no "deprecated" or "compatibility" warnings remain
- [ ] Save file

**Verification**:
```bash
grep -E "artifact-operations|detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed" .claude/docs/guides/command-development-guide.md
```
Expected: Zero matches.

#### 3.3.3: Update agent-development-guide.md

**Objective**: Update agent development examples to use canonical functions.

**Tasks**:
- [ ] Open `.claude/docs/guides/agent-development-guide.md` for editing
- [ ] Search for code examples using compatibility functions
- [ ] Update error handling examples (same replacements as command-development-guide.md)
- [ ] Update logging examples (same replacements as command-development-guide.md)
- [ ] Remove any references to `artifact-operations.sh`
- [ ] Verify no "deprecated" or "compatibility" warnings remain
- [ ] Save file

**Verification**:
```bash
grep -E "artifact-operations|detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed" .claude/docs/guides/agent-development-guide.md
```
Expected: Zero matches.

### 3.4: Directory READMEs

#### 3.4.1: Identify All Directory READMEs

**Objective**: Create comprehensive list of README files to update.

**Tasks**:
- [ ] Find all README.md files in .claude/ directory:
  ```bash
  find .claude/ -name "README.md" -type f > /tmp/phase5_readme_list.txt
  ```
- [ ] Review list for completeness:
  ```bash
  cat /tmp/phase5_readme_list.txt
  ```
- [ ] Expected files (minimum):
  - `.claude/README.md`
  - `.claude/lib/README.md` (already updated in 3.2)
  - `.claude/docs/README.md`
  - `.claude/commands/README.md`
  - `.claude/agents/README.md`
  - `.claude/tests/README.md`

#### 3.4.2: Update Each README Systematically

**Objective**: Remove compatibility references from all directory READMEs.

**Process for Each README**:
- [ ] Open README for editing
- [ ] Search for compatibility function references:
  ```bash
  grep -E "artifact-operations|detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed|generate_legacy_location_context" [readme-path]
  ```
- [ ] For each match found:
  - Replace with canonical function name
  - Update surrounding context if needed
  - Remove "deprecated" warnings
- [ ] Verify no compatibility references remain
- [ ] Save file

**Batch Verification**:
```bash
while read readme; do
  echo "Checking: $readme"
  grep -E "artifact-operations|detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed|generate_legacy_location_context" "$readme"
done < /tmp/phase5_readme_list.txt
```
Expected: Zero matches across all files.

### 3.5: Documentation Completeness Check

**Objective**: Final verification that all documentation is updated.

**Tasks**:
- [ ] Run comprehensive grep across all documentation:
  ```bash
  grep -r "artifact-operations" .claude/docs/ .claude/lib/README.md .claude/README.md 2>/dev/null | grep -v ".git"
  ```
- [ ] Check for any remaining compatibility function references:
  ```bash
  grep -rE "detect_specific_error_type|extract_error_location|suggest_recovery_actions|rotate_log_if_needed|rotate_conversion_log_if_needed|generate_legacy_location_context" .claude/docs/ .claude/lib/ .claude/commands/ .claude/agents/ 2>/dev/null | grep -v ".git" | grep -v "^#.*migration"
  ```
- [ ] Check for "backward compatibility" language:
  ```bash
  grep -ri "backward.*compat" .claude/docs/ .claude/lib/README.md 2>/dev/null | grep -v ".git"
  ```
- [ ] Verify all documentation uses present-tense, clean language (no historical markers)

**Expected Outcome**: Zero matches for compatibility layers, present-tense documentation throughout.

---

## Stage 4: Git Workflow

### 4.1: Review Complete Changeset

**Objective**: Verify all changes are intentional and complete.

**Tasks**:
- [ ] Generate full diff:
  ```bash
  git diff > /tmp/phase5_full_diff.txt
  ```
- [ ] Review diff size:
  ```bash
  wc -l /tmp/phase5_full_diff.txt
  ```
- [ ] Review diff by category:
  - **File deletions**: Should see `artifact-operations.sh` deleted
  - **Function removals**: Should see compatibility sections removed from 3 files
  - **Function usage updates**: Should see canonical functions used throughout
  - **Documentation updates**: Should see compatibility references removed

**Checklist Review**:
- [ ] All 4 compatibility layers removed (files/sections deleted)
- [ ] All ~328 function references updated to canonical names
- [ ] All documentation updated (no compatibility references)
- [ ] No unintended changes (verify with `git diff --stat`)
- [ ] No leftover debugging code or comments

### 4.2: Stage All Changes

**Objective**: Prepare all changes for single atomic commit.

**Tasks**:
- [ ] Stage all modified files:
  ```bash
  git add -A
  ```
- [ ] Verify staging with status:
  ```bash
  git status
  ```
- [ ] Expected changes:
  - Deleted: `.claude/lib/artifact-operations.sh`
  - Modified: `.claude/lib/error-handling.sh` (aliases removed)
  - Modified: `.claude/lib/unified-logger.sh` (wrappers removed)
  - Modified: `.claude/lib/unified-location-detection.sh` (legacy function removed)
  - Modified: ~50+ files (function reference updates)
  - Modified: ~10+ documentation files

**Verification**:
```bash
git diff --cached --stat
```
Expected: All changed files staged, no unstaged changes.

### 4.3: Create Atomic Commit

**Objective**: Commit all changes with descriptive message following clean-break philosophy.

**Tasks**:
- [ ] Copy commit message template:
  ```bash
  cat > /tmp/phase5_commit_msg.txt << 'EOF'
refactor: Remove all compatibility layers (clean-break migration)

Remove 4 compatibility layers following clean-break philosophy:
- artifact-operations.sh shim (135 refs → spec-updater-agent.sh)
- error-handling.sh aliases (171 refs → canonical functions)
- unified-logger.sh wrappers (22 refs → rotate_log_file)
- generate_legacy_location_context() (0 refs, unused)

Total: 328 references updated, 4 layers deleted

Philosophy:
- Fail-fast: Missing functions produce immediate errors
- No deprecation: All changes in single commit
- Git history only: No archive files
- Production ready: Tests passing (77/77)

Test results: 77/77 PASSED
Rollback: git revert [commit-hash]
EOF
  ```
- [ ] Create commit:
  ```bash
  git commit -F /tmp/phase5_commit_msg.txt
  ```
- [ ] Capture commit hash:
  ```bash
  git log -1 --format="%H" > /tmp/phase5_commit_hash.txt
  echo "Commit hash: $(cat /tmp/phase5_commit_hash.txt)"
  ```

**Expected Outcome**: Single commit containing all compatibility layer removal changes.

### 4.4: Post-Commit Verification

**Objective**: Verify commit is complete and correct.

**Tasks**:
- [ ] Verify commit exists:
  ```bash
  git log -1 --oneline
  ```
- [ ] Verify all changes included:
  ```bash
  git diff HEAD~1 --stat
  ```
- [ ] Verify working tree is clean:
  ```bash
  git status
  ```
- [ ] Run tests post-commit:
  ```bash
  .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/phase5_post_commit_tests.log
  ```
- [ ] Verify 77/77 tests still pass

**Expected Outcome**: Clean working tree, all changes committed, tests passing.

### 4.5: Document Rollback Procedure

**Objective**: Create clear rollback instructions for emergency use.

**Tasks**:
- [ ] Create rollback guide:
  ```bash
  cat > /tmp/phase5_rollback_instructions.txt << EOF
# Rollback Instructions for Compatibility Layer Removal

## Immediate Rollback
If critical issues discovered, revert immediately:

\`\`\`bash
git revert $(cat /tmp/phase5_commit_hash.txt)
\`\`\`

This will restore all 4 compatibility layers and revert all 328 reference updates.

## Verification After Rollback
1. Run tests: .claude/tests/run_all_tests.sh
2. Verify compatibility functions restored: grep -r "artifact-operations" .claude/
3. Verify all references work: [run affected commands]

## Commit Hash
$(cat /tmp/phase5_commit_hash.txt)
EOF
  cat /tmp/phase5_rollback_instructions.txt
  ```

**Note**: Keep `/tmp/phase5_rollback_instructions.txt` available for 24-48 hours post-deployment.

---

## Stage 5: Quality Assurance

### 5.1: Code Cleanliness Verification

**Objective**: Confirm codebase is clean with no leftover artifacts.

**Tasks**:
- [ ] Verify no compatibility layer file remains:
  ```bash
  ls -la .claude/lib/artifact-operations.sh 2>&1 | grep "No such file"
  ```
- [ ] Verify no commented-out compatibility code:
  ```bash
  grep -r "#.*detect_specific_error_type\|#.*rotate_log_if_needed" .claude/ 2>/dev/null | wc -l
  ```
- [ ] Verify no temporary files or backup files:
  ```bash
  find .claude/ -name "*.bak" -o -name "*.tmp" -o -name "*~"
  ```
- [ ] Verify no debug output or TODO comments related to migration:
  ```bash
  grep -ri "TODO.*compat\|TODO.*migration\|DEBUG.*compat" .claude/ 2>/dev/null | grep -v ".git"
  ```

**Expected Outcome**: Zero matches, clean codebase.

### 5.2: Test Stability Confirmation

**Objective**: Confirm tests are stable post-commit.

**Tasks**:
- [ ] Run test suite third time:
  ```bash
  .claude/tests/run_all_tests.sh 2>&1 | tee /tmp/phase5_test_results_run3.log
  ```
- [ ] Compare with previous runs:
  ```bash
  diff /tmp/phase5_test_results_run2.log /tmp/phase5_test_results_run3.log
  ```
- [ ] Verify consistent pass rate: 77/77

**Expected Outcome**: Identical results, no flakiness.

### 5.3: Documentation Currency Check

**Objective**: Verify all documentation reflects current state.

**Tasks**:
- [ ] Spot-check 3-5 command files for canonical function usage:
  ```bash
  for cmd in implement plan coordinate test setup; do
    echo "Checking /claude/commands/$cmd.md..."
    grep -E "detect_specific_error_type|rotate_log_if_needed" .claude/commands/$cmd.md
  done
  ```
- [ ] Spot-check 2-3 agent files:
  ```bash
  for agent in spec-updater-agent implementation-researcher debug-analyst; do
    echo "Checking .claude/agents/$agent.md..."
    grep -E "artifact-operations|detect_specific_error_type" .claude/agents/$agent.md
  done
  ```
- [ ] Verify library-api.md accuracy:
  ```bash
  grep "artifact-operations" .claude/docs/reference/library-api.md
  ```

**Expected Outcome**: Zero compatibility references, all canonical functions used.

### 5.4: Fail-Fast Behavior Validation

**Objective**: Confirm compatibility layer absence produces immediate errors (not silent failures).

**Tasks**:
- [ ] Test missing `artifact-operations.sh` produces error:
  ```bash
  bash -c "source .claude/lib/artifact-operations.sh 2>&1" | grep -i "no such file"
  ```
- [ ] Test missing alias function produces error:
  ```bash
  bash -c "source .claude/lib/error-handling.sh; detect_specific_error_type 2>&1" | grep -i "command not found"
  ```
- [ ] Test missing wrapper function produces error:
  ```bash
  bash -c "source .claude/lib/unified-logger.sh; rotate_log_if_needed 2>&1" | grep -i "command not found"
  ```

**Expected Outcome**: All produce immediate "command not found" or "No such file" errors (fail-fast confirmed).

### 5.5: Rollback Readiness Confirmation

**Objective**: Verify rollback procedure is documented and tested.

**Tasks**:
- [ ] Verify rollback instructions exist:
  ```bash
  cat /tmp/phase5_rollback_instructions.txt
  ```
- [ ] Verify commit hash is recorded:
  ```bash
  cat /tmp/phase5_commit_hash.txt
  ```
- [ ] (Optional) Test rollback in separate worktree:
  ```bash
  # Create test worktree
  git worktree add /tmp/rollback-test HEAD
  cd /tmp/rollback-test

  # Perform rollback
  git revert $(cat /tmp/phase5_commit_hash.txt)

  # Verify compatibility layers restored
  ls -la .claude/lib/artifact-operations.sh
  grep "detect_specific_error_type" .claude/lib/error-handling.sh

  # Cleanup
  cd -
  git worktree remove /tmp/rollback-test
  ```

**Expected Outcome**: Rollback procedure documented, optionally tested and confirmed working.

---

## Troubleshooting

### Test Failures

**Symptom**: One or more tests fail in Stage 1.

**Common Causes**:
1. **Incomplete migration**: Compatibility function still referenced
2. **Syntax error**: Typo introduced during migration
3. **Path issue**: Test can't find updated function
4. **Unrelated bug**: Pre-existing issue exposed

**Resolution**:
1. Identify failing test file and function
2. Review test output for specific error
3. If "command not found" error:
   - Grep for compatibility function in failing test
   - Update to canonical function
   - Re-run test
4. If syntax error:
   - Review recent edits in relevant file
   - Fix syntax issue
   - Re-run test
5. If unrelated bug:
   - Document in plan notes
   - Evaluate if blocking (usually not)
   - Defer to separate fix if non-critical

### Documentation Gaps

**Symptom**: Compatibility references found in Stage 3 verification.

**Common Locations**:
1. Command files (`.claude/commands/*.md`)
2. Agent files (`.claude/agents/*.md`)
3. Pattern documentation (`.claude/docs/concepts/patterns/*.md`)
4. Directory READMEs (missed in find command)

**Resolution**:
1. Note file path and line number
2. Open file and locate reference
3. Replace with canonical function
4. Re-run verification grep
5. Add file to checklist if not already included

### Git Commit Issues

**Symptom**: Commit fails or produces unexpected results.

**Common Causes**:
1. **Untracked files**: New files not staged
2. **Merge conflicts**: Concurrent changes in another branch
3. **Pre-commit hooks**: Hook failure prevents commit
4. **Large diff**: Review timeout or performance issue

**Resolution**:
1. Check git status for untracked files: `git status`
2. Stage any missed files: `git add [file]`
3. If hooks fail: Review hook output, fix issues, retry
4. If large diff: Break into smaller commits (violates atomic commit principle - avoid if possible)

### Common Mistakes and Prevention

**Mistake 1**: Partial migration (some references missed)
- **Prevention**: Use comprehensive grep patterns in Stage 2
- **Fix**: Return to relevant phase, complete migration, re-test

**Mistake 2**: Documentation inconsistency (examples use old functions)
- **Prevention**: Systematic review of all docs in Stage 3
- **Fix**: Update missed documentation, re-verify

**Mistake 3**: Premature commit (before all verifications complete)
- **Prevention**: Follow stage order strictly, complete all checks
- **Fix**: `git reset --soft HEAD~1`, complete verifications, re-commit

**Mistake 4**: Lost rollback instructions
- **Prevention**: Save commit hash immediately after commit
- **Fix**: `git log --grep="compatibility layer"` to find commit

---

## Success Criteria

### Technical Criteria
- [ ] All 77 tests pass (100% requirement)
- [ ] Zero compatibility layer file/section references remain
- [ ] All 328 function references updated to canonical names
- [ ] All 4 compatibility files/sections deleted
- [ ] Working tree clean after commit

### Documentation Criteria
- [ ] All library inline documentation updated
- [ ] `.claude/lib/README.md` updated (no compatibility references)
- [ ] `.claude/docs/reference/library-api.md` updated (canonical functions only)
- [ ] All command and agent guides updated
- [ ] All directory READMEs updated
- [ ] Zero "backward compatibility" or "deprecated" language remains

### Git Criteria
- [ ] Single atomic commit created
- [ ] Commit message follows clean-break template
- [ ] Commit hash documented for rollback
- [ ] Post-commit tests pass (77/77)
- [ ] Rollback procedure documented

### Quality Criteria
- [ ] Fail-fast behavior validated (immediate errors for missing functions)
- [ ] Test stability confirmed (consistent results across 3 runs)
- [ ] Code cleanliness verified (no leftover artifacts)
- [ ] Documentation currency confirmed (spot-checks pass)
- [ ] Rollback readiness confirmed (procedure tested or documented)

### Production Readiness
- [ ] All phases (1-5) complete
- [ ] Implementation plan updated to "Complete" status
- [ ] Clean-break philosophy fully implemented
- [ ] System ready for production use
- [ ] Rollback available if needed (single commit revert)

---

## Final Notes

**Time Investment**: 90-120 minutes for comprehensive validation and documentation.

**Risk Level**: Medium complexity (coordination across many files) but low technical risk (tests provide safety net).

**Critical Path**: Stage 1 (tests) → Stage 2 (verification) → Stage 3 (documentation) → Stage 4 (commit) → Stage 5 (QA). Do not skip stages or reorder.

**Clean-Break Philosophy**: This phase embodies clean-break principles - immediate validation, comprehensive removal, fail-fast errors, single atomic commit, instant rollback capability.

**Post-Phase Actions**:
1. Update parent plan status to "Complete"
2. Archive temporary verification files (optional)
3. Monitor system for 24-48 hours post-deployment
4. Remove rollback instructions after confidence established

**Success Metric**: Production-ready codebase with zero compatibility layers, comprehensive documentation, passing tests, and rollback readiness.
