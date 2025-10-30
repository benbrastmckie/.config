# Migration Strategy, Phasing, and Risk Mitigation for Shim Removal

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Migration strategy, phasing, and risk mitigation for shim removal
- **Report Type**: Best practices and migration planning
- **Complexity Level**: 4

## Executive Summary

This report presents a comprehensive migration strategy for removing all shims and compatibility layers from the Claude Code infrastructure. Analysis reveals a mature deprecation system already in place: the primary shim (artifact-operations.sh) follows industry best practices with a 60-day migration window, explicit timeline, and automated warnings. The recommended 5-phase migration strategy spans 12 weeks, progressing from low-risk removals (<5 references) to high-risk multi-dependency shims (10+ references). Key success factors include: test-first validation achieving 80%+ coverage before removal, incremental batch updates (10-20% at a time), 7-14 day verification periods between phases, and comprehensive rollback procedures via git history and backups. Risk mitigation centers on fail-fast detection (immediate errors vs silent failures), wave-based migration batches, and maintaining backward-compatibility shims during transition periods.

## Findings

### 1. Current Shim Landscape

#### 1.1 Active Shim Inventory

Based on analysis of `/home/benjamin/.config/.claude/lib/artifact-operations.sh` and related research reports:

**Primary Backward-Compatibility Shim:**
- **artifact-operations.sh** (57 lines, created 2025-10-29)
  - Purpose: Maintains API compatibility after splitting into artifact-creation.sh + artifact-registry.sh
  - Direct dependencies: 10 source statements across 5 commands
  - Test dependencies: 12 references across 7 test files
  - Documentation: 60+ specification files
  - Timeline: Created 2025-10-29, migration target 2025-12-01, removal 2026-01-01
  - Migration window: 60+ days

**Legacy Format Compatibility:**
- **unified-location-detection.sh** - `generate_legacy_location_context()` (lines 381-416)
  - Purpose: Converts JSON output to legacy YAML format
  - Active usage: 0 callers detected (unused legacy function)
  - Maintenance timeline: "2 release cycles, then deprecated"
  - Risk: Very low (unused code, safe to remove immediately)

**Function-Level Compatibility:**
- **error-handling.sh** - Function aliases (lines 733-765)
  - Purpose: Backward compatibility for /supervise command
  - Aliases: `detect_specific_error_type()`, `extract_error_location()`, `suggest_recovery_actions()`
  - Status: Active, no deprecation timeline
  - Type: Permanent compatibility layer (minimal overhead)

- **unified-logger.sh** - Rotation function wrappers (lines 96-105)
  - Purpose: Consolidates adaptive-planning-logger + conversion-logger
  - Functions: `rotate_log_if_needed()`, `rotate_conversion_log_if_needed()`
  - Status: Active consolidation (not a removal candidate)

**Documentation-Only:**
- **checkpoint-utils.sh** - Legacy storage location note (lines 5-11)
  - Purpose: Documents historical `.claude/checkpoints/` vs `.claude/data/checkpoints/`
  - Impact: None (comments only, no code changes needed)

#### 1.2 Shim Categorization

**Category 1: Temporary Migration Shims** (scheduled for removal)
- artifact-operations.sh (60-day migration window)
- unified-location-detection.sh legacy converter (unused, immediate removal candidate)

**Category 2: Permanent Compatibility Layers** (minimal overhead, keep indefinitely)
- error-handling.sh function aliases
- unified-logger.sh consolidation wrappers

**Category 3: Documentation-Only** (no code impact)
- checkpoint-utils.sh legacy location notes

### 2. Migration Strategy Framework

#### 2.1 Phased Migration Approach

Based on industry best practices and project patterns from `/home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md`:

**Phase 0: Pre-Migration Assessment** (Week 0, 4-6 hours)

**Actions:**
1. Audit all shims with usage counts and categorization
2. Establish test baseline (run full suite: `./run_all_tests.sh`)
3. Document current passing rate (e.g., 57/76 tests = 75%)
4. Create migration tracking document with timeline
5. Identify dependencies and migration order

**Deliverables:**
- Shim inventory spreadsheet (name, references, category, priority)
- Test baseline report (passing/failing, coverage %)
- Migration timeline with phase gates
- Dependency graph showing removal order

**Success Criteria:**
- All shims categorized by removal priority
- Test suite runs successfully (baseline established)
- Team aligned on migration approach

---

**Phase 1: Low-Risk Removals** (Weeks 1-2, 6-8 hours)

**Target:** Shims with <5 references, clear replacements, or zero usage

**Priority 1.1: Unused Legacy Functions**
- Remove `generate_legacy_location_context()` from unified-location-detection.sh
- References: 0 active callers
- Risk: Very low (dead code removal)
- Effort: 15 minutes (delete lines 381-416, run tests)

**Priority 1.2: Low-Usage Shims** (if any discovered)
- Target shims with 1-3 references
- Create migration tests first
- Update references in single batch
- Remove shim after verification

**Actions:**
1. Verify zero active callers via grep
2. Create removal tests (ensure main library still works)
3. Remove legacy code
4. Run full test suite
5. Monitor for 3-5 days
6. Archive removed code in `.claude/archive/`

**Deliverables:**
- Updated library files with legacy code removed
- Test suite passing at ≥baseline rate
- Archive of removed code for rollback

**Success Criteria:**
- All tests pass after removal
- No production errors for 3-5 days
- Library line count reduced (less maintenance burden)

---

**Phase 2: Medium-Risk Removals** (Weeks 3-6, 12-20 hours)

**Target:** artifact-operations.sh (primary backward-compatibility shim)

**References:** 10 commands, 12 tests, 60+ docs

**Migration Pattern:**
```bash
# OLD (DEPRECATED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# NEW (RECOMMENDED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"
```

**Sub-Phase 2.1: Test Migration** (Week 3, 2-3 hours)
- Update 7 test files to use split libraries
- Files: `test_report_multi_agent_pattern.sh`, `test_shared_utilities.sh`, `test_command_integration.sh`, `verify_phase7_baselines.sh`, `test_library_references.sh`
- Pattern: Update source statements and existence checks
- Validation: Run `./run_all_tests.sh` after updates

**Sub-Phase 2.2: Command Migration Batch 1** (Week 4, 3-5 hours)
- Update 2 commands: `/debug.md`, `/list.md`
- References: 4 total (debug: 2, list: 2)
- Test after each command update
- Monitor deprecation warnings (should stop for these commands)

**Sub-Phase 2.3: Command Migration Batch 2** (Week 5, 3-5 hours)
- Update 3 commands: `/orchestrate.md`, `/implement.md`, `/plan.md`
- References: 6 total (orchestrate: 1, implement: 2, plan: 3)
- Test after each command update
- Verify all deprecation warnings stopped

**Sub-Phase 2.4: Documentation Updates** (Week 5-6, 2-3 hours)
- Update migration guides in `/home/benjamin/.config/.claude/lib/README.md`
- Update command examples in `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
- Bulk find/replace in 60+ specification files
- Mark migration complete in artifact-operations.sh header

**Sub-Phase 2.5: Monitoring Period** (Week 6, passive)
- Monitor for missed references (check stderr logs)
- Ensure no deprecation warnings appearing
- Verify commands execute without errors
- Maintain shim during monitoring

**Deliverables:**
- 5 commands migrated to split libraries
- 7 test files updated
- 60+ documentation files updated
- Migration guide marked complete

**Success Criteria:**
- Zero deprecation warnings in logs
- All tests passing (≥baseline rate)
- No production errors during monitoring

---

**Phase 3: Shim Removal and Verification** (Weeks 7-8, 2-3 hours)

**Target:** Remove artifact-operations.sh after successful migration

**Actions:**
1. Verify 100% migration complete (grep for remaining references)
2. Final test suite run with shim present (baseline)
3. Delete `/home/benjamin/.config/.claude/lib/artifact-operations.sh`
4. Run full test suite without shim (compare to baseline)
5. Verify identical passing rate
6. Monitor production for 7-14 days
7. Archive shim file in `.claude/archive/lib/`

**Rollback Plan:**
- Git revert available (commit hash documented)
- Archived file can be restored if needed
- Rollback decision window: 7 days

**Deliverables:**
- Shim file removed from codebase
- Test suite passing without shim
- Archived shim file for rollback
- Git commit documenting removal

**Success Criteria:**
- Test passing rate unchanged (baseline maintained)
- No "file not found" errors in production
- Zero references to deprecated shim remain
- 7-14 days error-free operation

---

**Phase 4: High-Risk Assessment** (Weeks 9-10, 4-6 hours)

**Target:** Evaluate multi-dependency shims for permanent retention vs removal

**Candidates for Evaluation:**
- error-handling.sh function aliases (15+ command dependencies)
- unified-logger.sh consolidation (heavy usage across codebase)
- Proposed: base-utils.sh consolidation (deferred in Plan 519)

**Assessment Criteria:**
1. **Overhead:** How much maintenance burden does compatibility layer add?
2. **Risk:** What's the blast radius if removal causes issues?
3. **Value:** Does removing the shim improve code quality significantly?
4. **Alternatives:** Can we achieve benefits without removing compatibility?

**Decision Matrix:**

| Shim | Overhead | Risk | Value | Decision |
|------|----------|------|-------|----------|
| error-handling.sh aliases | Minimal (3 functions) | Medium (15+ commands) | Low (aliases are clear) | **RETAIN** as permanent |
| unified-logger.sh wrappers | Minimal (2 functions) | High (all orchestration) | Low (consolidation benefit) | **RETAIN** as permanent |
| base-utils.sh consolidation | Medium (3 new shims) | High (67+ sources) | Medium (simpler imports) | **DEFER** (not critical) |

**Actions:**
1. Document decision rationale for each shim
2. Mark permanent compatibility layers in code comments
3. Update CLAUDE.md to distinguish temporary vs permanent shims
4. Create policy for future shim creation

**Deliverables:**
- Shim retention policy document
- Updated code comments (PERMANENT vs TEMPORARY markers)
- CLAUDE.md section on compatibility layer philosophy

**Success Criteria:**
- Clear distinction between temporary and permanent compatibility
- Team consensus on retention decisions
- Policy prevents future shim proliferation

---

**Phase 5: Post-Migration Optimization** (Weeks 11-12, 2-4 hours)

**Target:** Cleanup and process improvements

**Actions:**
1. Remove archived shims after 30-day verification
2. Update template files with new canonical patterns
3. Create automated shim detection script
4. Document lessons learned
5. Update development guides with migration patterns

**Automation Script:** `.claude/scripts/detect-deprecated-shims.sh`
```bash
#!/usr/bin/env bash
# Scan for deprecated shims still in use
# Returns: List of commands/files with deprecated imports

grep -rn "artifact-operations.sh" .claude/commands/ .claude/tests/ 2>/dev/null || echo "✓ No deprecated imports found"
```

**Deliverables:**
- Automated shim detection script
- Updated template files
- Migration lessons learned document
- Refactoring runbook for future splits

**Success Criteria:**
- Automated detection prevents regression
- Templates show current best practices
- Team has clear migration playbook

#### 2.2 Risk Mitigation Strategies

Based on `/home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md` and industry patterns:

**Strategy 1: Test-First Validation**

**Approach:**
- Create comprehensive tests BEFORE any shim removal
- Establish baseline (run tests with shim present)
- Achieve ≥80% coverage on modified code paths
- Use round-trip tests for data preservation

**Implementation:**
```bash
# Pre-removal baseline
./run_all_tests.sh > baseline.txt
BASELINE_PASS=$(grep "PASSED" baseline.txt | wc -l)

# Post-removal validation
./run_all_tests.sh > post_removal.txt
POST_PASS=$(grep "PASSED" post_removal.txt | wc -l)

# Compare
if [ "$POST_PASS" -lt "$BASELINE_PASS" ]; then
  echo "REGRESSION DETECTED: Rollback recommended"
  exit 1
fi
```

**Benefits:**
- Immediate detection of breaking changes
- Quantifiable success criteria
- Automated regression prevention

---

**Strategy 2: Incremental Batch Updates**

**Approach:**
- Migrate 10-20% of references at a time
- Run full test suite after each batch
- Monitor for regressions immediately
- Rollback individual batches if issues detected

**Implementation:**
- Batch 1: 2 commands (20% of 10 total)
- Test suite run → All pass → Proceed
- Batch 2: 2 commands (40% cumulative)
- Test suite run → Regression detected → Rollback Batch 2
- Fix issues → Retry Batch 2 → Proceed

**Benefits:**
- Limits blast radius of errors
- Enables precise root cause identification
- Maintains continuous system stability

---

**Strategy 3: Deprecation Warnings as Canary**

**Approach:**
- Shims emit warnings on first use (artifact-operations.sh pattern)
- Monitor stderr logs for warnings
- Warnings indicate incomplete migration
- Zero warnings = migration complete

**Implementation:**
```bash
# In shim file (artifact-operations.sh lines 52-56)
if [[ -z "${ARTIFACT_OPS_DEPRECATION_WARNING_SHOWN:-}" ]]; then
  echo "WARNING: artifact-operations.sh is deprecated..." >&2
  export ARTIFACT_OPS_DEPRECATION_WARNING_SHOWN=1
fi

# Monitoring during migration
./command.sh 2>&1 | grep "DEPRECATED" && echo "Migration incomplete"
```

**Benefits:**
- Passive monitoring (no active polling needed)
- Immediate visibility into migration status
- User-facing indicator for downstream consumers

---

**Strategy 4: Dual-Write Pattern During Transition**

**Approach:**
- Maintain backward-compatibility shim during migration
- Shim transparently sources new implementations
- Gradual migration with safety net
- Remove shim only after 100% migration verified

**Implementation:**
```bash
# Shim sources both split libraries (artifact-operations.sh lines 40-49)
source "$script_dir/artifact-creation.sh" || return 1
source "$script_dir/artifact-registry.sh" || return 1

# All original functions remain available
# Gradual migration from shim → direct imports
# No breaking changes during transition
```

**Benefits:**
- Zero-downtime migration
- Rollback capability at any point
- Gradual confidence building

---

**Strategy 5: Fail-Fast Detection**

**Approach:**
- Prefer immediate obvious errors over silent failures
- "File not found" on source statement is GOOD (immediate detection)
- Silent behavior changes are BAD (delayed detection)
- Shim removal causes fast failures (not silent degradation)

**Example:**
```bash
# Removing shim causes immediate error
source artifact-operations.sh
# bash: artifact-operations.sh: No such file or directory
# ✓ Failure detected immediately

# Silent failure would be worse
# (function calls succeed but produce wrong results)
```

**Benefits:**
- Issues detected in seconds (not days/weeks)
- Clear error messages guide fixes
- Reduces debugging time significantly

---

**Strategy 6: Verification Windows**

**Approach:**
- 3-5 days for low-risk removals
- 7-14 days for medium-risk removals
- 30+ days for high-risk removals
- Monitoring for production errors during window

**Implementation:**
- Remove shim on Monday
- Monitor stderr logs daily (grep for errors)
- Check command execution success rates
- Decision point at end of window (keep removal or rollback)

**Benefits:**
- Catches edge cases not covered by tests
- Real-world validation beyond synthetic tests
- Time for user reports to surface

#### 2.3 Rollback Planning

Based on `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md` and `/home/benjamin/.config/.claude/docs/guides/model-rollback-guide.md`:

**Rollback Mechanism 1: Git History**

**Primary rollback method** for all shim removals:

```bash
# Identify commit that removed shim
git log --oneline --all -- .claude/lib/artifact-operations.sh
# a1b2c3d Remove artifact-operations.sh after migration complete

# Rollback using git revert
git revert a1b2c3d
git commit -m "Rollback: Restore artifact-operations.sh due to [issue]"

# Verify rollback
test -f .claude/lib/artifact-operations.sh && echo "✓ Shim restored"
./run_all_tests.sh  # Confirm tests pass
```

**Benefits:**
- Full version history preserved
- Atomic rollback (all-or-nothing)
- Git commit documents rollback reason
- Can revert the revert to re-remove later

**Rollback Window:** 30 days (standard verification period)

---

**Rollback Mechanism 2: Archived Backups**

**Secondary rollback method** via `.claude/archive/lib/`:

```bash
# Archive shim before removal (Phase 3)
mkdir -p .claude/archive/lib/
cp .claude/lib/artifact-operations.sh .claude/archive/lib/artifact-operations.sh.bak
echo "Archived on $(date)" >> .claude/archive/lib/artifact-operations.sh.bak

# Rollback from archive if git unavailable
cp .claude/archive/lib/artifact-operations.sh.bak .claude/lib/artifact-operations.sh
chmod +x .claude/lib/artifact-operations.sh
./run_all_tests.sh  # Verify functionality
```

**Benefits:**
- Independent of git (works if repo corrupted)
- Explicit backup location
- Timestamped for audit trail

**Retention Period:** 60 days (2x verification window)

---

**Rollback Mechanism 3: Emergency Fast Rollback**

**Fast rollback procedure** for critical production issues:

```bash
# Emergency rollback (skip validation initially)
git revert <commit-hash> --no-commit
git commit -m "EMERGENCY ROLLBACK: [brief reason]"
git push origin main

# Post-rollback validation (run after emergency)
./run_all_tests.sh
# Monitor production errors for 48 hours
```

**Triggers:**
- Production errors affecting users
- Cascading failures across multiple commands
- Data corruption risk
- Security vulnerability introduced

**Post-Rollback Actions:**
1. Immediate monitoring (error rates, command success)
2. Root cause analysis (why did removal cause issues?)
3. Fix underlying issues
4. Retry removal with additional safeguards

---

**Rollback Decision Criteria**

**ROLLBACK if:**
- Test passing rate drops >5% from baseline
- Production error rate increases significantly
- Cascading failures detected
- Critical commands fail
- Data loss or corruption risk

**KEEP REMOVAL if:**
- Test passing rate unchanged (≥baseline)
- No production errors during verification window
- All commands execute successfully
- User reports positive or neutral

**Decision Timeline:**
- Low-risk: 3-5 days monitoring → decide
- Medium-risk: 7-14 days monitoring → decide
- High-risk: 30+ days monitoring → decide

### 3. Testing Strategy

#### 3.1 Pre-Removal Test Requirements

Based on `/home/benjamin/.config/.claude/tests/README.md` (lines 176-230):

**Coverage Targets:**
- Modified Code (shim removal paths): ≥80% coverage
- Existing Code (unaffected paths): ≥60% baseline
- Critical Paths (replacement functionality): 100% coverage

**Test Categories for Shim Removal:**

**1. Unit Tests** - Individual function behavior
```bash
# Test split libraries independently
source .claude/lib/artifact-creation.sh
source .claude/lib/artifact-registry.sh

# Verify functions available
type create_topic_artifact || fail "Function not found"
type register_artifact || fail "Function not found"
type query_artifacts || fail "Function not found"
```

**2. Integration Tests** - End-to-end command workflows
```bash
# Test commands with split libraries (no shim)
/plan "Test feature"  # Should create plan successfully
/implement specs/plans/001_test.md  # Should execute without errors
/list plans  # Should query artifacts correctly
```

**3. Round-Trip Tests** - Data preservation
```bash
# Verify artifact creation → registration → query roundtrip
ARTIFACT=$(create_topic_artifact "test" "plan")
register_artifact "$ARTIFACT" "completed"
RESULT=$(query_artifacts "test" "plan")
[ "$RESULT" = "$ARTIFACT" ] || fail "Roundtrip failed"
```

**4. Regression Tests** - Legacy format compatibility
```bash
# Ensure existing plans/reports still loadable
for plan in specs/*/plans/*.md; do
  parse_plan_file "$plan" || fail "Regression: $plan"
done
```

**5. Edge Case Tests** - Boundary conditions
```bash
# Test with missing dependencies
rm .claude/lib/artifact-registry.sh  # Simulate missing file
source .claude/lib/artifact-creation.sh && fail "Should detect missing dep"
```

#### 3.2 Test Execution Strategy

**Baseline Establishment** (before any changes):
```bash
# Run full test suite
cd .claude/tests
./run_all_tests.sh > baseline_report.txt

# Capture metrics
TOTAL_TESTS=$(grep -c "test_" baseline_report.txt)
PASSED_TESTS=$(grep -c "PASSED" baseline_report.txt)
BASELINE_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo "Baseline: $PASSED_TESTS/$TOTAL_TESTS ($BASELINE_RATE%)"
```

**Incremental Validation** (after each migration batch):
```bash
# Update 2 commands
edit_command "debug.md"  # Update source statements
edit_command "list.md"

# Run full test suite
./run_all_tests.sh > batch1_report.txt

# Compare to baseline
BATCH1_PASS=$(grep -c "PASSED" batch1_report.txt)
if [ "$BATCH1_PASS" -lt "$PASSED_TESTS" ]; then
  echo "REGRESSION: Rollback batch 1"
  git revert HEAD
else
  echo "✓ Batch 1 validated ($BATCH1_PASS/$TOTAL_TESTS)"
fi
```

**Post-Removal Validation** (after shim deletion):
```bash
# Delete shim
rm .claude/lib/artifact-operations.sh

# Run full test suite
./run_all_tests.sh > post_removal_report.txt

# Verify identical passing rate
POST_PASS=$(grep -c "PASSED" post_removal_report.txt)
if [ "$POST_PASS" != "$PASSED_TESTS" ]; then
  echo "FAILURE: Restore shim from archive"
  cp .claude/archive/lib/artifact-operations.sh.bak .claude/lib/artifact-operations.sh
else
  echo "✓ Removal validated ($POST_PASS/$TOTAL_TESTS)"
fi
```

**Continuous Monitoring** (during verification window):
```bash
# Daily test runs during 7-14 day window
for day in {1..14}; do
  ./run_all_tests.sh > "day${day}_report.txt"
  PASS=$(grep -c "PASSED" "day${day}_report.txt")
  echo "Day $day: $PASS/$TOTAL_TESTS"

  # Alert if degradation
  if [ "$PASS" -lt "$BASELINE_RATE" ]; then
    echo "WARNING: Test passing rate declined on day $day"
  fi
done
```

#### 3.3 Test Suite Enhancements

**New Test Files Required:**

**1. test_shim_migration.sh** - Migration-specific validation
```bash
#!/usr/bin/env bash
# Test shim removal migration

test_split_libraries_work_independently() {
  # Verify split libraries function without shim
  source .claude/lib/artifact-creation.sh || fail "Creation lib failed"
  source .claude/lib/artifact-registry.sh || fail "Registry lib failed"

  # Test core functions
  create_topic_artifact "test" "plan" || fail "Create failed"
  pass "Split libraries work independently"
}

test_shim_sources_split_libraries() {
  # Verify shim transparently delegates
  source .claude/lib/artifact-operations.sh || fail "Shim failed"

  type create_topic_artifact &>/dev/null || fail "Creation function missing"
  type register_artifact &>/dev/null || fail "Registry function missing"

  pass "Shim provides all functions"
}

test_deprecation_warning_emitted() {
  # Verify warning appears on first use
  OUTPUT=$(source .claude/lib/artifact-operations.sh 2>&1)
  echo "$OUTPUT" | grep -q "DEPRECATED" || fail "No deprecation warning"

  pass "Deprecation warning emitted"
}
```

**2. test_rollback_procedures.sh** - Rollback mechanism validation
```bash
#!/usr/bin/env bash
# Test rollback mechanisms work correctly

test_archive_rollback() {
  # Simulate removal and archive
  cp .claude/lib/artifact-operations.sh /tmp/backup.sh
  rm .claude/lib/artifact-operations.sh

  # Verify missing
  [ ! -f .claude/lib/artifact-operations.sh ] || fail "Still exists"

  # Rollback from archive
  cp /tmp/backup.sh .claude/lib/artifact-operations.sh

  # Verify restored
  source .claude/lib/artifact-operations.sh || fail "Rollback failed"
  pass "Archive rollback successful"
}

test_git_revert_rollback() {
  # Requires git repo (skip if not available)
  git rev-parse --is-inside-work-tree &>/dev/null || skip "Not in git repo"

  # Create test commit removing file
  cp .claude/lib/artifact-operations.sh /tmp/backup.sh
  git rm .claude/lib/artifact-operations.sh
  git commit -m "Test: Remove shim"

  # Revert commit
  git revert HEAD --no-commit
  git commit -m "Test: Rollback removal"

  # Verify file restored
  [ -f .claude/lib/artifact-operations.sh ] || fail "Git revert failed"
  pass "Git revert rollback successful"

  # Cleanup
  git reset --hard HEAD~2  # Remove test commits
}
```

### 4. User Communication Plan

#### 4.1 Communication Channels

**Internal Team Communication:**
- **CLAUDE.md updates** - Document migration status and timeline
- **CHANGELOG.md** - Record deprecations and removals
- **Command README** - Update examples with new patterns
- **Deprecation warnings** - Stderr output during command execution

**Downstream User Communication** (if applicable):
- **Migration guide** - Step-by-step upgrade instructions
- **Announcement** - Email/Slack notification before removal
- **Support window** - Assistance during migration period

#### 4.2 Documentation Updates

**Phase 2 (Migration): Update Usage Examples**

Files to update with new canonical patterns:
1. `/home/benjamin/.config/.claude/lib/README.md` (lines 408-437)
2. `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (line 1055)
3. Template files in `.claude/commands/templates/`
4. 60+ specification files with code examples

**Pattern:**
```bash
# OLD (DEPRECATED)
source .claude/lib/artifact-operations.sh

# NEW (RECOMMENDED)
source .claude/lib/artifact-creation.sh  # For create_* functions
source .claude/lib/artifact-registry.sh  # For query_* functions
```

**Phase 3 (Removal): Remove Historical Markers**

After shim removal, update documentation following timeless writing standards (from `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` lines 49-87):

**Remove:**
- Historical markers: "(New)", "(Old)", "(Deprecated)"
- Temporal references: "Previously", "Now", "Updated"
- Migration notices in main documentation

**Keep:**
- CHANGELOG.md entries (historical record)
- Migration guides (transitional documentation)
- Present-focused implementation docs

**Example Update:**
```markdown
<!-- BEFORE (temporal) -->
The artifact-operations.sh library was split into artifact-creation.sh
and artifact-registry.sh. Previously, all functions were in one file.

<!-- AFTER (timeless) -->
Artifact operations are split across two libraries:
- artifact-creation.sh: Functions for creating new artifacts
- artifact-registry.sh: Functions for tracking and querying artifacts
```

#### 4.3 CHANGELOG Entries

**For Deprecation Announcement (Phase 2 start):**
```markdown
## [Unreleased]

### Deprecated
- `artifact-operations.sh` - Split into artifact-creation.sh and artifact-registry.sh
  - **Migration deadline**: 2025-12-01
  - **Removal date**: 2026-01-01
  - **Migration guide**: See .claude/lib/README.md section on artifact operations
  - **Affected commands**: /debug, /orchestrate, /implement, /plan, /list (10 references)
  - **Action required**: Update source statements to use split libraries

### Added
- `artifact-creation.sh` - Functions for creating new artifacts (extracted from artifact-operations.sh)
- `artifact-registry.sh` - Functions for tracking and querying artifacts (extracted from artifact-operations.sh)
```

**For Removal Completion (Phase 3 end):**
```markdown
## [1.2.0] - 2026-01-15

### Removed
- `artifact-operations.sh` - Backward-compatibility shim removed after successful migration
  - All commands updated to use artifact-creation.sh and artifact-registry.sh directly
  - Migration completed 2025-12-01, removal after 30-day verification period
  - Archived in .claude/archive/lib/ for historical reference

### Changed
- All commands now source artifact-creation.sh and artifact-registry.sh directly (no shim)
- Documentation updated to reflect current implementation (historical markers removed)
```

### 5. Success Criteria and Metrics

#### 5.1 Phase-Specific Success Criteria

**Phase 0 (Pre-Migration Assessment):**
- ✅ All shims inventoried with categorization
- ✅ Test baseline established (e.g., 57/76 = 75%)
- ✅ Migration timeline documented and approved
- ✅ Dependency graph created

**Phase 1 (Low-Risk Removals):**
- ✅ Unused legacy functions removed (e.g., `generate_legacy_location_context()`)
- ✅ Test passing rate ≥baseline (75%)
- ✅ No production errors for 3-5 days
- ✅ Removed code archived

**Phase 2 (Medium-Risk Removals):**
- ✅ 100% of command references migrated (10/10)
- ✅ 100% of test references migrated (12/12)
- ✅ Documentation updated (60+ files)
- ✅ Zero deprecation warnings in logs
- ✅ Test passing rate ≥baseline

**Phase 3 (Shim Removal):**
- ✅ artifact-operations.sh deleted from codebase
- ✅ Test passing rate unchanged (baseline maintained)
- ✅ Zero "file not found" errors
- ✅ 7-14 days error-free operation
- ✅ Shim archived for rollback

**Phase 4 (High-Risk Assessment):**
- ✅ Retention decisions documented with rationale
- ✅ Permanent compatibility layers marked clearly
- ✅ CLAUDE.md updated with policy

**Phase 5 (Post-Migration Optimization):**
- ✅ Automated shim detection script created
- ✅ Template files updated with new patterns
- ✅ Lessons learned documented

#### 5.2 Quantitative Metrics

**Test Coverage:**
- Modified code coverage: ≥80%
- Existing code coverage: ≥60% baseline
- Critical path coverage: 100%

**Migration Completeness:**
- Command reference updates: 10/10 (100%)
- Test reference updates: 12/12 (100%)
- Documentation updates: 60+/60+ (100%)

**Quality Metrics:**
- Test passing rate: ≥baseline (75%+)
- Production error rate: No increase
- Deprecation warnings: Zero (after migration)

**Timeline Metrics:**
- Phase 0: ≤1 week
- Phase 1: 2 weeks
- Phase 2: 4 weeks
- Phase 3: 2 weeks
- Phase 4: 2 weeks
- Phase 5: 2 weeks
- **Total: 12-13 weeks**

#### 5.3 Verification Checklist

Before marking migration complete, verify ALL criteria:

**Code Verification:**
- [ ] All deprecated imports removed (grep returns zero results)
- [ ] Split libraries work independently (test suite passes)
- [ ] Rollback procedures tested and documented
- [ ] Archive backups created and accessible

**Testing Verification:**
- [ ] Full test suite passing at ≥baseline rate
- [ ] New migration tests passing (100%)
- [ ] Round-trip tests validating data preservation
- [ ] Edge case tests covering error conditions

**Documentation Verification:**
- [ ] CHANGELOG entries added (deprecation + removal)
- [ ] Migration guide updated and marked complete
- [ ] Code examples updated with new patterns
- [ ] Historical markers removed from main docs

**Production Verification:**
- [ ] Commands execute without errors
- [ ] No deprecation warnings in logs
- [ ] Error rates unchanged from baseline
- [ ] Verification window completed (7-14 days)

**Team Verification:**
- [ ] Migration announcement sent
- [ ] Team aligned on retention decisions
- [ ] Lessons learned documented
- [ ] Runbook created for future migrations

## Recommendations

### Recommendation 1: Follow 5-Phase Migration Strategy (Priority: HIGH)

Implement the phased approach detailed in Findings section 2.1:
- **Phase 0**: Pre-migration assessment (Week 0)
- **Phase 1**: Low-risk removals (Weeks 1-2)
- **Phase 2**: Medium-risk removals - artifact-operations.sh (Weeks 3-6)
- **Phase 3**: Shim removal and verification (Weeks 7-8)
- **Phase 4**: High-risk assessment and retention decisions (Weeks 9-10)
- **Phase 5**: Post-migration optimization (Weeks 11-12)

**Timeline:** 12-13 weeks total

**Effort:** 30-45 hours total across all phases

**Benefits:**
- Reduces risk through incremental approach
- Maintains system stability throughout migration
- Enables learning and adjustment between phases
- Provides multiple rollback points

### Recommendation 2: Achieve ≥80% Test Coverage Before Removal (Priority: HIGH)

Create comprehensive test suite covering:
- Split library functionality (unit tests)
- Command workflows (integration tests)
- Data preservation (round-trip tests)
- Legacy compatibility (regression tests)
- Error handling (edge case tests)

**Implementation:**
- Create `test_shim_migration.sh` with 15+ test cases
- Create `test_rollback_procedures.sh` with 8+ test cases
- Expand existing integration tests to cover split libraries
- Achieve baseline: 57/76 → target: 65+/76 (85%+)

**Benefits:**
- Detects breaking changes immediately
- Quantifies migration success
- Prevents regressions
- Builds confidence for removal

### Recommendation 3: Use Incremental Batch Updates (10-20% at a time) (Priority: HIGH)

Migrate references in small batches with full test runs between batches:
- **Batch 1**: 2 commands (debug, list) = 20% of 10 total
- **Batch 2**: 3 commands (orchestrate, implement, plan) = 50% cumulative
- **Batch 3**: Tests + documentation = 100% complete

**Pattern:**
1. Update 10-20% of references
2. Run full test suite
3. Monitor for regressions
4. Rollback batch if issues detected
5. Fix issues and retry
6. Proceed to next batch

**Benefits:**
- Limits blast radius of errors
- Enables precise root cause identification
- Maintains rollback granularity
- Reduces stress on team

### Recommendation 4: Maintain 7-14 Day Verification Windows (Priority: MEDIUM)

After each major change, monitor production for verification period:
- **Low-risk removals**: 3-5 days
- **Medium-risk removals**: 7-14 days
- **High-risk removals**: 30+ days

**Monitoring Actions:**
- Daily test suite runs
- Stderr log review (grep for errors/warnings)
- Command success rate tracking
- User feedback collection

**Decision Criteria:**
- Rollback if: Test passing rate drops >5%, production errors increase, cascading failures
- Keep if: Tests unchanged, no production errors, user feedback positive/neutral

**Benefits:**
- Catches edge cases not covered by tests
- Provides real-world validation
- Allows time for user reports
- Reduces risk of premature removal

### Recommendation 5: Implement Dual Rollback Mechanisms (Priority: HIGH)

Maintain two independent rollback methods:

**Primary: Git History**
```bash
git revert <commit-hash>
git commit -m "Rollback: Restore [shim] due to [issue]"
```

**Secondary: Archived Backups**
```bash
cp .claude/archive/lib/[shim].bak .claude/lib/[shim]
```

**Rollback Window:**
- Git: Indefinite (full history preserved)
- Archive: 60 days (2x verification window)

**Testing:**
- Test both rollback mechanisms during Phase 1
- Document rollback procedures in runbook
- Practice emergency rollback (dry run)

**Benefits:**
- Redundancy if git unavailable
- Fast rollback for emergencies
- Documented procedures reduce stress
- Team confidence in safety net

### Recommendation 6: Distinguish Temporary vs Permanent Compatibility Layers (Priority: MEDIUM)

Update code comments and documentation to clearly mark:

**Temporary (scheduled for removal):**
```bash
# TEMPORARY SHIM - Remove after migration (target: 2026-01-01)
# Migration guide: .claude/lib/README.md section X
```

**Permanent (minimal overhead, retain indefinitely):**
```bash
# PERMANENT COMPATIBILITY LAYER
# Provides backward compatibility for /supervise command
# Overhead: Minimal (3 function aliases)
```

**Update CLAUDE.md:**
Add section distinguishing temporary shims from permanent compatibility layers:
- Temporary: Created during migrations, removed after completion
- Permanent: Minimal overhead, provides lasting value, retained indefinitely
- Policy: New shims must document category and removal timeline

**Benefits:**
- Prevents confusion about shim purpose
- Clarifies maintenance expectations
- Prevents accidental removal of permanent layers
- Guides future shim creation decisions

### Recommendation 7: Create Automated Shim Detection Script (Priority: LOW)

Implement `.claude/scripts/detect-deprecated-shims.sh`:

```bash
#!/usr/bin/env bash
# Detect deprecated shims still in use

echo "Scanning for deprecated imports..."

# Check artifact-operations.sh
ARTIFACT_REFS=$(grep -rn "artifact-operations.sh" .claude/commands/ .claude/tests/ 2>/dev/null | wc -l)
if [ "$ARTIFACT_REFS" -gt 0 ]; then
  echo "⚠ artifact-operations.sh: $ARTIFACT_REFS references found"
  echo "  Migration deadline: 2025-12-01"
  echo "  Removal date: 2026-01-01"
else
  echo "✓ artifact-operations.sh: No deprecated imports"
fi

# Check for other deprecated patterns
# Add additional checks as new shims are deprecated

echo "Scan complete."
```

**Integration:**
- Run as part of CI/CD pipeline
- Fail builds if shim past removal date still in use
- Generate migration progress reports

**Benefits:**
- Prevents regression (reintroduction of deprecated imports)
- Tracks migration progress automatically
- Reminds team of upcoming removal dates
- No manual tracking needed

### Recommendation 8: Document Lessons Learned (Priority: MEDIUM)

After migration completion, create `.claude/docs/guides/shim-migration-lessons-learned.md`:

**Capture:**
- What went well (successes to repeat)
- What went poorly (pitfalls to avoid)
- Unexpected challenges (edge cases discovered)
- Time estimates vs actuals (improve future planning)
- Rollback triggers (when did we need to rollback?)

**Share:**
- Team retrospective on migration process
- Update refactoring runbook with insights
- Improve migration procedures for next time

**Benefits:**
- Institutional knowledge preservation
- Continuous process improvement
- Faster future migrations
- Reduced risk on subsequent refactors

## References

### Primary Research Sources

1. `/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/reports/001_shim_inventory_and_categorization_research.md` - Complete shim inventory with 5 active shims categorized
2. `/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/reports/002_shim_dependencies_and_impact_analysis_research.md` - Dependency analysis showing 77+ command references and 12 test dependencies
3. `/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/reports/003_shim_removal_strategy_and_best_practices_research.md` - Best practices including 30-90 day windows, test-first validation, rollback procedures

### Shim Implementation Files

4. `/home/benjamin/.config/.claude/lib/artifact-operations.sh:1-57` - Exemplary backward-compatibility shim with deprecation timeline, transparent delegation, and single warning per process
5. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:381-416` - Legacy YAML format converter (unused, safe to remove)
6. `/home/benjamin/.config/.claude/lib/error-handling.sh:733-765` - Function aliases for backward compatibility
7. `/home/benjamin/.config/.claude/lib/unified-logger.sh:96-105` - Logger consolidation wrappers
8. `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:5-11` - Legacy storage location documentation

### Migration Documentation

9. `/home/benjamin/.config/.claude/lib/README.md:408-436` - Migration guide for artifact-operations.sh split
10. `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:1055` - Developer guide with migration examples
11. `/home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md:1-814` - Comprehensive refactoring process with pre-assessment, testing, validation
12. `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md:1-558` - Development philosophy prioritizing clean breaks, timeless documentation

### Rollback and Testing

13. `/home/benjamin/.config/.claude/docs/reference/backup-retention-policy.md:1-230` - Backup strategies, retention guidelines, rollback procedures
14. `/home/benjamin/.config/.claude/docs/guides/model-rollback-guide.md:96-135` - Rollback process pattern with verification and monitoring
15. `/home/benjamin/.config/.claude/tests/README.md:1-150` - Test suite structure, coverage requirements (≥80% modified code, ≥60% baseline)

### Split Library Files

16. `/home/benjamin/.config/.claude/lib/artifact-creation.sh` - Extracted creation functions from artifact-operations.sh
17. `/home/benjamin/.config/.claude/lib/artifact-registry.sh` - Extracted registry functions from artifact-operations.sh

### Commands Requiring Migration

18. `/home/benjamin/.config/.claude/commands/debug.md:203,381` - 2 source statements
19. `/home/benjamin/.config/.claude/commands/orchestrate.md:609` - 1 source statement
20. `/home/benjamin/.config/.claude/commands/implement.md:965,1098` - 2 source statements
21. `/home/benjamin/.config/.claude/commands/plan.md:144,464,548` - 3 source statements
22. `/home/benjamin/.config/.claude/commands/list.md:62,101` - 2 source statements

### Commands Already Migrated (Examples)

23. `/home/benjamin/.config/.claude/commands/research.md:52` - Uses artifact-creation.sh directly
24. `/home/benjamin/.config/.claude/commands/coordinate.md:661` - Uses artifact-creation.sh directly

### Test Files Requiring Updates

25. `/home/benjamin/.config/.claude/tests/test_report_multi_agent_pattern.sh:10` - Source with fallback
26. `/home/benjamin/.config/.claude/tests/test_shared_utilities.sh:344` - Test description
27. `/home/benjamin/.config/.claude/tests/test_command_integration.sh:612,684,705` - Existence checks
28. `/home/benjamin/.config/.claude/tests/verify_phase7_baselines.sh:91` - Line count validation
29. `/home/benjamin/.config/.claude/tests/test_library_references.sh:56` - Standalone library list
