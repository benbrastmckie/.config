# Phase 3.4: Compliance and Cleanup - Pre-Phase 4 Standards Enforcement

## Metadata
- **Phase Number**: 3.4
- **Phase Name**: Compliance and Cleanup - Pre-Phase 4 Standards Enforcement
- **Parent Plan**: [080_orchestrate_enhancement.md](../080_orchestrate_enhancement.md)
- **Complexity Score**: 5/10 (Medium)
- **Expansion Reason**: Addresses critical blockers for Phase 4, requires careful standards enforcement and cruft removal
- **Dependencies**: depends_on: [phase_3]
- **Estimated Duration**: 2-4 hours
- **Risk Level**: Medium (standards compliance critical, cruft removal requires validation)
- **Priority**: HIGH (blocks Phase 4)
- **Analysis Report**: [phase_3_pre_phase_4_analysis.md](reports/phase_3_pre_phase_4_analysis.md)

## Objective

Address critical compliance issues and remove deprecated cruft from Phase 3 implementation to ensure Phase 4 (Plan Expansion) can proceed without blockers. Enhance agent enforcement standards, validate complexity output format compatibility, archive deprecated algorithm utilities, and establish orchestrate.md Phase 2.5 integration strategy.

This phase resolves **3 critical blockers** and **2 cleanup items** identified in the pre-Phase 4 analysis:

**Critical Blockers**:
1. complexity-estimator.md missing full imperative language enforcement (85/100 score, need 95+/100)
2. Complexity output format not validated for Phase 4 expansion-specialist compatibility
3. orchestrate.md Phase 2.5 integration strategy undefined (needed for Phase 4 Stage 0)

**Cleanup Items**:
4. ~2.2MB deprecated algorithm utilities and backup files (improve clarity, prevent confusion)
5. Historical markers in 51 files (deferred to later documentation pass)

## Overview

Phase 3 successfully implemented pure agent-based complexity assessment with perfect 1.0000 correlation, but the rapid architectural pivot from algorithm-based to agent-based approach left behind deprecated utilities and incomplete standards compliance. Before implementing Phase 4 (automated plan expansion), we must ensure:

1. **Agent Enforcement Standards**: complexity-estimator.md meets full Standard 0.5 requirements (imperative language, sequential dependencies)
2. **Output Format Compatibility**: Complexity YAML output validated for Phase 4 expansion-specialist consumption
3. **Integration Strategy**: orchestrate.md Phase 2.5 integration approach designed and documented
4. **Codebase Clarity**: Deprecated algorithm code archived, backup files removed, clean slate for Phase 4

This phase is **non-negotiable** - Phase 4 cannot proceed without addressing these issues, as they risk:
- Integration failures (output format mismatch)
- Standards drift (future agents copying weak enforcement patterns)
- Developer confusion (mixing deprecated and active utilities)
- Phase 4 scope creep (discovering Phase 2.5 integration missing mid-implementation)

## Success Criteria

### Critical Success Criteria (Must Complete)

- [ ] complexity-estimator.md scores 95+/100 on agent enforcement rubric
- [ ] Imperative language used consistently ("YOU MUST", "STEP N REQUIRED BEFORE N+1")
- [ ] Sequential step dependencies explicit in Execution Procedure
- [ ] Complexity output format validated with sample multi-phase plan
- [ ] Phase 4 expansion-specialist input requirements documented
- [ ] orchestrate.md Phase 2.5 integration strategy designed and documented in Phase 4 plan
- [ ] Deprecated algorithm utilities archived to `.claude/archive/complexity-algorithm/`
- [ ] All backup files removed (docs-backup-082, *.backup, test artifacts)
- [ ] Git verification: No uncommitted changes in backup files before removal

### Optional Success Criteria (Can Defer)

- [ ] Historical markers removed from Phase 3 files (can defer to documentation cleanup pass)
- [ ] Test suite updated (archive algorithm tests, keep agent tests)

### Testing Validation

- [ ] TESTING: Agent enforcement rubric scoring
  ```bash
  # Manual review against enforcement checklist
  # Target: 95+/100 score across all 10 categories
  ```

- [ ] TESTING: Complexity output format validation
  ```bash
  # Create test plan with 3-5 phases
  # Invoke complexity-estimator agent
  # Verify YAML structure matches Phase 4 expectations
  # Document batch vs individual invocation pattern
  ```

- [ ] TESTING: Archived files not referenced
  ```bash
  # Verify no active code references archived utilities
  grep -r "analyze-phase-complexity" .claude/commands/ .claude/agents/
  grep -r "complexity-utils" .claude/commands/ .claude/agents/
  # Expected: No matches (or only in archived files)
  ```

- [ ] TESTING: Backup files safely removed
  ```bash
  # Verify git history preserves previous states
  git log --oneline --all -- .claude/docs-backup-082/
  git log --oneline --all -- .claude/lib/*.backup
  # Verify no uncommitted changes lost
  git status --short
  ```

## Architecture

### Stage Overview

This phase consists of 5 sequential stages addressing compliance and cleanup:

```
Stage 1: Agent Enforcement Enhancement (30-45 min)
  ↓
Stage 2: Output Format Validation (45-60 min)
  ↓
Stage 3: Archive Deprecated Algorithm Utilities (20-30 min)
  ↓
Stage 4: Remove Backup Files and Test Artifacts (10-15 min)
  ↓
Stage 5: Phase 2.5 Integration Strategy Design (45-60 min)
```

**Total Estimated Time**: 2.5-4 hours

### Compliance Standards Reference

**Agent Enforcement Rubric** (Standard 0.5):

| Category | Target | Current (85/100) | After Phase 3.4 (95+/100) |
|----------|--------|------------------|---------------------------|
| Role Declaration | 10 | 8 | 10 (add "YOU MUST" to role) |
| Sequential Dependencies | 10 | 5 | 10 (add "STEP N REQUIRED BEFORE N+1") |
| File Creation Enforcement | 10 | N/A | N/A (read-only agent) |
| Imperative Language | 10 | 8 | 10 (strengthen all critical sections) |
| Completion Criteria | 10 | 10 | 10 (already strong) |
| Zero Passive Voice | 10 | 7 | 10 (remove "should/may" in error handling) |
| THIS EXACT TEMPLATE Markers | 10 | 10 | 10 (already strong) |
| Structural Annotations | 10 | 0 | 5 (add key [EXECUTION-CRITICAL] markers) |
| Verification Checkpoints | 10 | N/A | N/A (orchestrate.md responsibility) |
| Fallback Mechanisms | 10 | 7 | 9 (strengthen error handling) |

**Target Score**: 95/100 (9 applicable categories × 10 points, 2 N/A)

### Output Format Specification

**complexity-estimator.md Current Output**:
```yaml
complexity_assessment:
  phase_name: "Authentication System Migration"
  complexity_score: 10
  confidence: high
  reasoning: |
    [Natural language explanation]
  key_factors:
    - [Factor 1]
    - [Factor 2]
  comparable_to: "Example (10.0)"
  expansion_recommended: true
  expansion_reason: "[Reason]"
  edge_cases_detected: []
```

**Phase 4 Requirements** (to validate):
- Single phase assessment OR batch multi-phase assessment?
- expansion-specialist needs: phase_name, complexity_score, expansion_recommended
- Optional fields: reasoning, key_factors (for documentation)
- Batch format (if needed): Array of complexity_assessment objects

**Validation Approach**:
1. Create test plan: 3-5 phases with varying complexity (simple, medium, high)
2. Invoke complexity-estimator agent on test plan
3. Verify YAML structure parseable and complete
4. Document invocation pattern (individual vs batch)
5. Update Phase 4 expansion-specialist expectations

## Stage 1: Agent Enforcement Enhancement

### Objective
Enhance complexity-estimator.md to achieve 95+/100 on agent enforcement rubric by adding imperative language, sequential dependencies, and structural annotations.

### Tasks

#### Task 1.1: Enhance Role Declaration
- [ ] Read complexity-estimator.md Lines 1-39 (Role, Architectural Approach, Capabilities, Constraints)
- [ ] Rewrite Line 5 from passive to imperative:
  ```markdown
  Current: "Analyze implementation plan phases and assess complexity..."
  Updated: "YOU MUST analyze implementation plan phases and assess complexity..."
  ```
- [ ] Add imperative opening to Capabilities section (Line 18):
  ```markdown
  Add: "YOU WILL perform the following operations:"
  ```
- [ ] Verify role declaration now scores 10/10

#### Task 1.2: Add Sequential Dependencies to Execution Procedure
- [ ] Read Execution Procedure section (Lines 242-275)
- [ ] Rewrite each step to include sequential dependency markers:
  ```markdown
  Current: "Step 1: Read Phase Content"
  Updated: "STEP 1 (REQUIRED): YOU MUST read phase content BEFORE proceeding to Step 2"

  Current: "Step 2: Identify Comparable Calibration Example"
  Updated: "STEP 2 (DEPENDS ON STEP 1): YOU MUST identify comparable calibration example BEFORE proceeding to Step 3"
  ```
- [ ] Apply to all 6 steps in Execution Procedure
- [ ] Verify sequential dependencies now score 10/10

#### Task 1.3: Strengthen Imperative Language Consistency
- [ ] Review all "should/may/can" instances:
  ```bash
  grep -n "should\|may\|can" .claude/agents/complexity-estimator.md
  ```
- [ ] Replace with MUST/WILL/SHALL in critical sections:
  - Error Handling (Lines 276-305): "should assign" → "MUST assign"
  - Quality Checklist (Lines 307-318): "should verify" → "MUST verify"
- [ ] Verify zero passive voice in critical sections (score 10/10)

#### Task 1.4: Add Structural Annotations
- [ ] Add [EXECUTION-CRITICAL] markers to key sections:
  ```markdown
  Line 173: ## [EXECUTION-CRITICAL] Output Format
  Line 207: ## [EXECUTION-CRITICAL] Reasoning Chain Template
  Line 242: ## [EXECUTION-CRITICAL] Execution Procedure
  ```
- [ ] Add [INLINE-REQUIRED] to YAML template (Line 175):
  ```markdown
  Line 175: You MUST return output in this exact YAML structure [INLINE-REQUIRED]:
  ```
- [ ] Verify structural annotations score 5/10 (added to key sections)

#### Task 1.5: Strengthen Fallback Mechanisms
- [ ] Review Error Handling section (Lines 276-305)
- [ ] Add explicit MUST language to all error scenarios:
  ```markdown
  Current: "If phase content is too minimal to assess:"
  Updated: "YOU MUST handle insufficient information as follows:"
  ```
- [ ] Add fallback severity markers:
  ```markdown
  - Insufficient information: LOW severity, default score 5, proceed
  - Collapsed phase: MEDIUM severity, semantic analysis, flag for expansion
  - Invalid YAML input: HIGH severity, return error structure, halt
  ```
- [ ] Verify fallback mechanisms score 9/10

#### Task 1.6: Verify Enforcement Score
- [ ] Review updated agent against rubric checklist
- [ ] Score each category (1-10 points)
- [ ] Verify total score ≥95/100
- [ ] Document score in Phase 3.4 completion notes

### Expected Outputs
- ✅ complexity-estimator.md updated with imperative language
- ✅ Enforcement rubric score: 95+/100
- ✅ All MUST/WILL/SHALL language consistent
- ✅ Sequential dependencies explicit
- ✅ Structural annotations added

### Success Criteria
- [ ] Role declaration uses "YOU MUST" (10/10)
- [ ] Execution Procedure has "STEP N REQUIRED BEFORE N+1" (10/10)
- [ ] Zero "should/may/can" in critical sections (10/10)
- [ ] Structural annotations present (5/10 minimum)
- [ ] Error handling uses "MUST" language (9/10 minimum)
- [ ] Total enforcement score ≥95/100

---

## Stage 2: Output Format Validation

### Objective
Validate complexity-estimator output format is compatible with Phase 4 expansion-specialist requirements through testing with sample multi-phase plan.

### Tasks

#### Task 2.1: Create Test Plan
- [ ] Create test plan: `.claude/tests/fixtures/complexity/test_multi_phase_plan.md`
- [ ] Include 5 phases with varying complexity:
  1. Simple phase: "Update README documentation" (3 tasks, 2 files) - Expected: 2-3
  2. Medium phase: "Add logging utility" (8 tasks, 4 files) - Expected: 5-6
  3. Medium-high phase: "Implement user profile management" (15 tasks, 8 files) - Expected: 7-8
  4. High phase: "Authentication system migration" (20 tasks, 12 files, security) - Expected: 9-10
  5. Very high phase: "Parallel execution orchestration" (30+ tasks, 20+ files) - Expected: 12+
- [ ] Follow standard plan format (metadata, overview, phases with tasks)

#### Task 2.2: Test Individual Phase Assessment
- [ ] Invoke complexity-estimator agent on Phase 1 only
- [ ] Verify YAML output structure matches expected format
- [ ] Extract: phase_name, complexity_score, expansion_recommended
- [ ] Verify reasoning and key_factors present
- [ ] Document successful individual assessment pattern

#### Task 2.3: Test Batch Assessment (If Needed)
- [ ] Determine if expansion-specialist needs batch processing
- [ ] If yes: Modify complexity-estimator to accept array of phases
- [ ] If no: Document orchestrator must invoke agent per-phase and aggregate
- [ ] Test chosen approach with all 5 phases
- [ ] Verify output format consistent across phases

#### Task 2.4: Validate Expansion Recommendations
- [ ] Review complexity scores for 5 test phases
- [ ] Verify expansion_recommended = true for phases with score >8.0
- [ ] Verify expansion_recommended = false for phases with score ≤8.0
- [ ] Check threshold logic: (score > threshold) OR (task_count > 10)
- [ ] Document threshold evaluation pattern

#### Task 2.5: Document Phase 4 Integration Requirements
- [ ] Create documentation: `phase_4_plan_expansion.md` (prepend to existing if file exists)
- [ ] Document complexity-estimator output format
- [ ] Document expansion-specialist input expectations
- [ ] Specify invocation pattern: individual per-phase OR batch multi-phase
- [ ] Provide example YAML for Phase 4 agent prompt template
- [ ] Cross-reference with complexity-estimator.md Output Format section

#### Task 2.6: Performance Testing
- [ ] Test complexity-estimator performance on 5-phase plan
- [ ] Measure: Time per phase assessment (target: <3 seconds each)
- [ ] Measure: Consistency across multiple runs (target: ±0.5 points)
- [ ] Verify performance targets met
- [ ] Document performance metrics in validation results

### Expected Outputs
- ✅ Test plan created with 5 varying-complexity phases
- ✅ Complexity output format validated for all phases
- ✅ Invocation pattern documented (individual vs batch)
- ✅ Phase 4 integration requirements documented
- ✅ Performance verified (<3s per phase, ±0.5 consistency)

### Success Criteria
- [ ] Test plan includes 5 phases (simple to very high complexity)
- [ ] complexity-estimator produces valid YAML for all phases
- [ ] expansion_recommended logic correct (score >8.0 OR tasks >10)
- [ ] Invocation pattern documented for Phase 4
- [ ] Performance: <3 seconds per phase
- [ ] Consistency: ±0.5 points across multiple runs
- [ ] Phase 4 integration requirements documented in phase_4_plan_expansion.md

---

## Stage 3: Archive Deprecated Algorithm Utilities

### Objective
Archive deprecated algorithm utilities (~40KB) to `.claude/archive/complexity-algorithm/` to prevent confusion and preserve historical research value.

### Tasks

#### Task 3.1: Create Archive Directory Structure
- [ ] Create directory: `.claude/archive/complexity-algorithm/`
- [ ] Create subdirectories:
  - `.claude/archive/complexity-algorithm/lib/` (utilities)
  - `.claude/archive/complexity-algorithm/docs/` (documentation)
  - `.claude/archive/complexity-algorithm/tests/` (algorithm tests)
- [ ] Create README.md explaining archival:
  ```markdown
  # Complexity Algorithm Archive

  This directory contains the deprecated 5-factor algorithmic complexity scoring system
  implemented during Phase 3 Stages 6-7 (OLD). Archived on 2025-10-22 during Phase 3.4.

  ## Why Archived

  The algorithm achieved 0.7515 correlation with ground truth, but was superseded by
  pure agent-based assessment achieving 1.0000 perfect correlation.

  ## Contents

  - lib/: Algorithm implementation utilities
  - docs/: Formula specification and calibration reports
  - tests/: Algorithm validation tests

  ## Historical Value

  This research informed the few-shot calibration examples used in complexity-estimator.md.
  The ground truth dataset and calibration insights remain valuable for future work.
  ```

#### Task 3.2: Archive Utility Files
- [ ] Move (git mv) deprecated utilities:
  ```bash
  git mv .claude/lib/analyze-phase-complexity.sh .claude/archive/complexity-algorithm/lib/
  git mv .claude/lib/complexity-utils.sh .claude/archive/complexity-algorithm/lib/
  git mv .claude/lib/robust-scaling.sh .claude/archive/complexity-algorithm/lib/
  ```
- [ ] Verify complexity-thresholds.sh **NOT** moved (still active)
- [ ] Update moved files to add deprecation notice at top:
  ```bash
  # DEPRECATED: Moved to archive on 2025-10-22 (Phase 3.4)
  # Superseded by: .claude/agents/complexity-estimator.md (pure agent approach)
  # Reason: Agent-based assessment achieved 1.0000 vs 0.7515 correlation
  ```

#### Task 3.3: Archive Documentation Files
- [ ] Move (git mv) deprecated documentation:
  ```bash
  git mv .claude/docs/reference/complexity-formula-spec.md .claude/archive/complexity-algorithm/docs/
  git mv .claude/docs/reference/complexity-calibration-report.md .claude/archive/complexity-algorithm/docs/
  ```
- [ ] Update moved docs to add deprecation notice
- [ ] Verify no broken links in active documentation:
  ```bash
  grep -r "complexity-formula-spec" .claude/docs/ .claude/commands/ .claude/agents/
  grep -r "complexity-calibration-report" .claude/docs/ .claude/commands/ .claude/agents/
  ```
- [ ] Update any references to point to archive or remove if no longer relevant

#### Task 3.4: Archive Algorithm Tests
- [ ] Identify algorithm-specific tests:
  - test_complexity_basic.sh (algorithm implementation)
  - test_complexity_baseline.sh (algorithm baseline)
  - test_complexity_calibration.py (calibration scripts)
  - test_complexity_calibration_v2.py
  - test_hybrid_complexity.sh
- [ ] Move to archive:
  ```bash
  git mv .claude/tests/test_complexity_basic.sh .claude/archive/complexity-algorithm/tests/
  git mv .claude/tests/test_complexity_baseline.sh .claude/archive/complexity-algorithm/tests/
  git mv .claude/tests/test_complexity_calibration.py .claude/archive/complexity-algorithm/tests/
  git mv .claude/tests/test_complexity_calibration_v2.py .claude/archive/complexity-algorithm/tests/
  git mv .claude/tests/test_hybrid_complexity.sh .claude/archive/complexity-algorithm/tests/
  ```
- [ ] Keep agent tests (test_complexity_estimator.sh, test_agent_correlation.py)
- [ ] Update test suite documentation if needed

#### Task 3.5: Verify No Active References
- [ ] Search for references to archived files:
  ```bash
  grep -r "analyze-phase-complexity" .claude/{commands,agents,lib}/ --exclude-dir=archive
  grep -r "complexity-utils" .claude/{commands,agents,lib}/ --exclude-dir=archive
  ```
- [ ] Verify search returns no results (or only archive references)
- [ ] Test orchestrate.md still references complexity-thresholds.sh (active)
- [ ] Document archival in Phase 3.4 completion notes

#### Task 3.6: Create Git Commit
- [ ] Stage all archival changes:
  ```bash
  git add .claude/archive/complexity-algorithm/
  git add .claude/lib/
  git add .claude/docs/reference/
  git add .claude/tests/
  ```
- [ ] Create commit:
  ```bash
  git commit -m "refactor(080): archive deprecated algorithm utilities - Phase 3.4 Stage 3

  Archive 5-factor complexity algorithm (Phase 3 OLD) superseded by pure agent approach.

  Archived:
  - lib: analyze-phase-complexity.sh, complexity-utils.sh, robust-scaling.sh (~40KB)
  - docs: complexity-formula-spec.md, complexity-calibration-report.md (~750KB)
  - tests: algorithm-specific test files (~5 files)

  Preserved:
  - lib/complexity-thresholds.sh (still active)
  - tests/test_complexity_estimator.sh (agent tests)

  Reason: Agent-based assessment achieved 1.0000 correlation vs 0.7515 with algorithm.
  Historical value: Research informed few-shot calibration examples.

  🤖 Generated with Claude Code
  Co-Authored-By: Claude <noreply@anthropic.com>"
  ```

### Expected Outputs
- ✅ Archive directory created with README
- ✅ 3 utility files archived (~40KB)
- ✅ 2 documentation files archived (~750KB)
- ✅ 5 algorithm test files archived
- ✅ complexity-thresholds.sh preserved (active)
- ✅ No broken references in active code
- ✅ Git commit created

### Success Criteria
- [ ] Archive directory structure created
- [ ] All deprecated utilities moved (analyze-phase-complexity.sh, complexity-utils.sh, robust-scaling.sh)
- [ ] complexity-thresholds.sh NOT moved (verified active)
- [ ] Deprecated documentation archived
- [ ] Algorithm tests archived
- [ ] No active code references archived files
- [ ] Git commit created with clear rationale

---

## Stage 4: Remove Backup Files and Test Artifacts

### Objective
Remove backup files (~1.5MB) and temporary test artifacts (~712KB) safely after verifying git history preservation.

### Tasks

#### Task 4.1: Verify Git Status Clean
- [ ] Check git status before removal:
  ```bash
  git status --short
  ```
- [ ] Verify no uncommitted changes in backup files
- [ ] Verify no untracked files in backup directories that should be committed
- [ ] If uncommitted changes exist: Review and commit OR discard intentionally

#### Task 4.2: Verify Git History Preservation
- [ ] Verify docs-backup-082 history preserved:
  ```bash
  git log --oneline --all -- .claude/docs-backup-082/ | head -20
  ```
- [ ] Verify *.backup files history preserved:
  ```bash
  for file in .claude/lib/*.backup; do
    echo "=== $file ==="
    git log --oneline --all -- "$file" | head -5
  done
  ```
- [ ] Confirm git history shows file creation and modifications
- [ ] Document: "Git history preserves previous states, safe to remove"

#### Task 4.3: Remove docs-backup-082 Directory
- [ ] Verify size before removal:
  ```bash
  du -sh .claude/docs-backup-082/
  # Expected: ~1.4MB, 65 files
  ```
- [ ] Remove directory:
  ```bash
  rm -rf .claude/docs-backup-082/
  ```
- [ ] Verify removal:
  ```bash
  ls .claude/docs-backup-082/ 2>&1 | grep "No such file"
  ```

#### Task 4.4: Remove .backup Files in lib/
- [ ] List backup files to remove:
  ```bash
  ls -lh .claude/lib/*.backup
  ```
- [ ] Remove backup files:
  ```bash
  rm .claude/lib/*.backup
  ```
- [ ] Verify removal:
  ```bash
  ls .claude/lib/*.backup 2>&1 | grep "No such file"
  ```

#### Task 4.5: Remove Plan Backup Files
- [ ] List plan backup files:
  ```bash
  find .claude/specs/plans -name "*.backup" -type f
  ```
- [ ] Remove plan backups:
  ```bash
  find .claude/specs/plans -name "*.backup" -type f -delete
  ```
- [ ] Verify removal:
  ```bash
  find .claude/specs/plans -name "*.backup" -type f | wc -l
  # Expected: 0
  ```

#### Task 4.6: Remove Test Artifacts
- [ ] List test artifact directories:
  ```bash
  ls -lhd .claude/lib/tmp/e2e_test_*
  ```
- [ ] Verify size:
  ```bash
  du -sh .claude/lib/tmp/e2e_test_* | awk '{sum+=$1} END {print sum " KB"}'
  ```
- [ ] Remove test artifacts:
  ```bash
  rm -rf .claude/lib/tmp/e2e_test_*
  ```
- [ ] Verify removal:
  ```bash
  ls .claude/lib/tmp/e2e_test_* 2>&1 | grep "No such file"
  ```

#### Task 4.7: Remove Empty Backup Directories
- [ ] Find empty backup directories:
  ```bash
  find .claude/specs -type d -name "backups" -empty
  ```
- [ ] Remove empty directories:
  ```bash
  find .claude/specs -type d -name "backups" -empty -delete
  ```
- [ ] Verify removal

#### Task 4.8: Calculate Total Space Reclaimed
- [ ] Calculate disk space reclaimed:
  ```bash
  # docs-backup-082: 1.4MB
  # *.backup files: ~50KB
  # Plan backups: ~10KB
  # Test artifacts: ~712KB
  # Total: ~2.2MB
  ```
- [ ] Document space savings in completion notes

#### Task 4.9: Create Git Commit
- [ ] Stage removals:
  ```bash
  git add -A
  ```
- [ ] Verify only deletions staged:
  ```bash
  git status --short | grep "^D"
  ```
- [ ] Create commit:
  ```bash
  git commit -m "chore(080): remove backup files and test artifacts - Phase 3.4 Stage 4

  Remove ~2.2MB of backup files and temporary test artifacts.

  Removed:
  - .claude/docs-backup-082/ (1.4MB, Plan 082 refactoring backup)
  - .claude/lib/*.backup (5 files, ~50KB)
  - .claude/specs/plans/*/*.backup (2 files, ~10KB)
  - .claude/lib/tmp/e2e_test_* (4 directories, ~712KB)
  - Empty backup directories

  Rationale: Git history preserves previous states, backups no longer needed.
  Verified: No uncommitted changes in removed files.

  🤖 Generated with Claude Code
  Co-Authored-By: Claude <noreply@anthropic.com>"
  ```

### Expected Outputs
- ✅ docs-backup-082 removed (1.4MB freed)
- ✅ All *.backup files removed (~60KB freed)
- ✅ Test artifacts removed (~712KB freed)
- ✅ Empty backup directories removed
- ✅ Total space reclaimed: ~2.2MB
- ✅ Git commit created

### Success Criteria
- [ ] Git status clean before removal
- [ ] Git history verified for all removed files
- [ ] docs-backup-082 removed
- [ ] All *.backup files removed
- [ ] Test artifacts (e2e_test_*) removed
- [ ] Empty backup directories removed
- [ ] Total ~2.2MB disk space reclaimed
- [ ] Git commit created documenting removals

---

## Stage 5: Phase 2.5 Integration Strategy Design

### Objective
Design orchestrate.md Phase 2.5 (Complexity Evaluation) integration approach and document requirements for Phase 4 Stage 0 implementation.

### Tasks

#### Task 5.1: Review Current orchestrate.md Structure
- [ ] Read orchestrate.md current phase structure:
  - Phase 0: Location (location-specialist)
  - Phase 1: Research (research-specialist × 2-4 parallel)
  - Phase 2: Planning (plan-architect)
  - Phase 3: Implementation (code-writer)
  - Phase 4: Testing (test-specialist)
  - Phase 5: Debugging (debug-specialist, conditional)
  - Phase 6: Documentation (doc-writer)
  - Phase 7: GitHub (github-specialist, conditional)
  - Phase 8: Summary (workflow summary generation)
- [ ] Identify insertion point: After Phase 2 (Planning), before Phase 3 (Implementation)

#### Task 5.2: Define Phase 2.5 Responsibilities
- [ ] Document Phase 2.5 scope:
  ```markdown
  Phase 2.5: Complexity Evaluation
  - Input: Level 0 plan path from Phase 2 (plan-architect)
  - Process: Invoke complexity-estimator for each phase in plan
  - Output: Complexity assessments (YAML) for all phases
  - Decision: Identify phases exceeding expansion threshold (>8.0 OR >10 tasks)
  - Handoff: Pass high-complexity phase list to Phase 2.6 (Expansion)
  ```
- [ ] Define success criteria for Phase 2.5
- [ ] Define error handling (agent failure, invalid YAML, threshold missing)

#### Task 5.3: Define Phase 2.6 Responsibilities
- [ ] Document Phase 2.6 scope:
  ```markdown
  Phase 2.6: Plan Expansion
  - Input: High-complexity phase list from Phase 2.5
  - Process: For each phase, invoke expansion-specialist (Phase 4 implementation)
  - Output: Expanded phase files (Level 1), updated parent plan
  - Recursive: Re-run Phase 2.5 on expanded phases (max 2 levels)
  - Handoff: Pass final expanded plan to Phase 3 (Implementation)
  ```
- [ ] Define recursion limits (max 2 levels: L0 → L1 → L2, stop)
- [ ] Define expansion triggering logic

#### Task 5.4: Design Agent Invocation Pattern
- [ ] Specify complexity-estimator invocation:
  ```yaml
  Option A (Individual Per-Phase):
    For each phase in Level 0 plan:
      - Invoke complexity-estimator with phase content
      - Collect YAML assessment
      - Aggregate assessments into single report

  Option B (Batch Multi-Phase):
    - Invoke complexity-estimator once with all phases
    - Receive array of YAML assessments
    - Parse and process batch results

  Recommended: Option A (Individual Per-Phase)
  Rationale: Simpler agent logic, better error isolation, consistent with research phase pattern
  ```
- [ ] Document invocation example (Task tool usage)
- [ ] Specify timeout: 10 seconds per phase (conservative)

#### Task 5.5: Design Verification Checkpoint
- [ ] Define MANDATORY VERIFICATION for Phase 2.5:
  ```markdown
  MANDATORY VERIFICATION: Complexity Evaluation Complete

  YOU MUST verify the following BEFORE proceeding to Phase 2.6:

  1. [ ] All phases in Level 0 plan assessed (count matches)
  2. [ ] All complexity-estimator outputs are valid YAML
  3. [ ] All required fields present (phase_name, complexity_score, expansion_recommended)
  4. [ ] At least one phase has complexity_score (not all default/error values)
  5. [ ] Expansion threshold logic applied correctly

  VERIFICATION COMMAND:
    # Count phases in plan
    PHASE_COUNT=$(grep -c "^### Phase" $PLAN_PATH)

    # Count YAML assessments received
    YAML_COUNT=$(echo "$COMPLEXITY_REPORTS" | grep -c "complexity_assessment:")

    # Verify counts match
    if [ "$PHASE_COUNT" -ne "$YAML_COUNT" ]; then
      echo "ERROR: Phase count ($PHASE_COUNT) != YAML count ($YAML_COUNT)"
      EXECUTE_FALLBACK
    fi

  FALLBACK MECHANISM:
    If verification fails:
    - Log warning with details
    - Use default threshold (expansion_threshold: 8.0)
    - Identify high-complexity phases by task count only (>10 tasks)
    - Proceed to Phase 2.6 with degraded expansion triggering
  ```
- [ ] Document fallback severity: MEDIUM (can proceed with degraded mode)

#### Task 5.6: Design Checkpoint Strategy
- [ ] Define checkpoint save after Phase 2.5:
  ```yaml
  checkpoint_complexity_evaluation_complete:
    phase_name: "complexity_evaluation"
    completion_time: [timestamp]
    outputs:
      complexity_reports: [list of YAML assessments]
      high_complexity_phases: [list of phase names exceeding threshold]
      expansion_needed: true/false
      status: "success"
    next_phase: "expansion" (if needed) OR "implementation" (if no expansion)
    performance:
      evaluation_time: [duration]
      phases_assessed: N
  ```
- [ ] Define checkpoint restoration if Phase 2.6 fails

#### Task 5.7: Document Phase Numbering Shift
- [ ] Document phase renumbering:
  ```markdown
  Before Phase 3.4:
    Phase 2: Planning
    Phase 3: Implementation
    Phase 4: Testing
    Phase 5: Debugging
    Phase 6: Documentation
    Phase 7: GitHub
    Phase 8: Summary

  After Phase 3.4 (with 2.5 and 2.6):
    Phase 2: Planning
    Phase 2.5: Complexity Evaluation (NEW)
    Phase 2.6: Plan Expansion (NEW)
    Phase 3: Implementation (unchanged)
    Phase 4: Testing (unchanged)
    Phase 5: Debugging (unchanged)
    Phase 6: Documentation (unchanged)
    Phase 7: GitHub (unchanged)
    Phase 8: Summary (unchanged)

  Note: Phase 3-8 retain original numbers, sub-phases inserted at 2.5 and 2.6
  ```

#### Task 5.8: Create Phase 4 Stage 0 Specification
- [ ] Update phase_4_plan_expansion.md (or create if missing)
- [ ] Add Stage 0 to Phase 4 plan:
  ```markdown
  ## Stage 0: Integrate Phase 2.5 Complexity Evaluation into orchestrate.md

  ### Objective
  Implement Phase 2.5 in orchestrate.md to invoke complexity-estimator and prepare
  high-complexity phase list for Phase 2.6 expansion.

  ### Tasks
  - [ ] Add Phase 2.5 section to orchestrate.md after Phase 2 (Planning)
  - [ ] Implement complexity-estimator agent invocation (individual per-phase pattern)
  - [ ] Add MANDATORY VERIFICATION checkpoint
  - [ ] Implement fallback mechanism (default threshold if agent fails)
  - [ ] Save checkpoint: complexity_evaluation_complete
  - [ ] Add conditional branching: If expansion_needed, proceed to Phase 2.6; else skip to Phase 3
  - [ ] Test Phase 2.5 integration with sample multi-phase plan
  - [ ] Verify checkpoint restoration works if Phase 2.6 fails

  ### Success Criteria
  - [ ] orchestrate.md invokes complexity-estimator for all phases
  - [ ] YAML assessments collected and validated
  - [ ] High-complexity phases identified (>8.0 OR >10 tasks)
  - [ ] Verification checkpoint implemented with fallback
  - [ ] Conditional flow to Phase 2.6 or Phase 3
  - [ ] End-to-end test passes

  ### Estimated Duration: 2-3 hours
  ```

#### Task 5.9: Document Context Management
- [ ] Specify context minimization for Phase 2.5:
  ```markdown
  Context Preservation Strategy:

  Orchestrator stores:
  - Complexity scores only (not full reasoning)
  - High-complexity phase names (not full YAML)
  - Expansion decision (boolean)

  Example:
    high_complexity_phases: ["Phase 2", "Phase 5"]
    expansion_needed: true

  NOT stored:
  - Full complexity_assessment YAML (600+ tokens each)
  - Reasoning text (natural language explanations)
  - Key factors lists

  Context reduction: 5 phases × 600 tokens = 3000 tokens → 100 tokens (97% reduction)
  ```

#### Task 5.10: Create Integration Design Document
- [ ] Create document: `artifacts/phase_2_5_integration_design.md`
- [ ] Include all decisions from Tasks 5.1-5.9
- [ ] Provide orchestrate.md pseudo-code for Phase 2.5
- [ ] Cross-reference with complexity-estimator.md
- [ ] Link from Phase 4 plan as prerequisite reading

### Expected Outputs
- ✅ Phase 2.5 scope and responsibilities defined
- ✅ Agent invocation pattern specified (individual per-phase)
- ✅ Verification checkpoint designed with fallback
- ✅ Checkpoint strategy defined
- ✅ Phase numbering documented
- ✅ Phase 4 Stage 0 specification created
- ✅ Context management strategy documented
- ✅ Integration design document created

### Success Criteria
- [ ] Phase 2.5 integration approach fully designed
- [ ] Agent invocation pattern specified (Task tool usage)
- [ ] MANDATORY VERIFICATION checkpoint defined
- [ ] Fallback mechanism defined (default threshold)
- [ ] Checkpoint save/restore strategy documented
- [ ] Phase 4 Stage 0 added to phase_4_plan_expansion.md
- [ ] Integration design document created in artifacts/
- [ ] Context minimization strategy documented (97% reduction)

---

## Phase Completion Checklist

- [ ] All 5 stages completed and marked [x]
- [ ] All critical success criteria met
- [ ] Testing validation commands executed
- [ ] Git commits created for Stages 3-4
- [ ] Phase 3.4 completion documented in main plan
- [ ] Phase 4 unblocked (all dependencies resolved)

### Stage Completion Summary

**Stage 1: Agent Enforcement Enhancement**
- [ ] complexity-estimator.md enforcement score: ___/100 (target: ≥95)
- [ ] Imperative language consistent
- [ ] Sequential dependencies added
- [ ] Structural annotations added

**Stage 2: Output Format Validation**
- [ ] Test plan created with 5 phases
- [ ] Output format validated for all phases
- [ ] Invocation pattern documented
- [ ] Phase 4 integration requirements documented
- [ ] Performance verified (<3s per phase)

**Stage 3: Archive Deprecated Utilities**
- [ ] Archive directory created
- [ ] 3 utility files archived
- [ ] 2 documentation files archived
- [ ] 5 test files archived
- [ ] complexity-thresholds.sh preserved
- [ ] Git commit: [commit hash]

**Stage 4: Remove Backup Files**
- [ ] Git history verified
- [ ] docs-backup-082 removed (1.4MB)
- [ ] *.backup files removed (~60KB)
- [ ] Test artifacts removed (~712KB)
- [ ] Total space reclaimed: ~2.2MB
- [ ] Git commit: [commit hash]

**Stage 5: Phase 2.5 Integration Design**
- [ ] Phase 2.5 scope defined
- [ ] Verification checkpoint designed
- [ ] Phase 4 Stage 0 specification created
- [ ] Integration design document created
- [ ] Context management strategy documented

### Update Main Plan

After completing Phase 3.4:

- [ ] Update 080_orchestrate_enhancement.md:
  ```markdown
  ### Phase 3.4: Compliance and Cleanup - Pre-Phase 4 Standards Enforcement [COMPLETED]
  **Status**: COMPLETED ✓
  **Completion Date**: [YYYY-MM-DD]
  **Duration**: [actual hours]
  **Commits**: [commit hashes from Stages 3-4]

  **Summary**: All critical blockers resolved. complexity-estimator.md enforcement score: 95+/100.
  Output format validated. ~2.2MB cruft archived/removed. Phase 2.5 integration designed for
  Phase 4 Stage 0. Phase 4 ready to proceed.
  ```

- [ ] Mark Phase 3.4 checkbox: `- [x] Phase 3.4: Compliance and Cleanup`

### Git Commit - Phase Completion

```bash
git commit -m "docs(080): complete Phase 3.4 - Compliance and Cleanup

Phase 3.4 preparation complete, Phase 4 unblocked.

Completed:
- Stage 1: Agent enforcement enhancement (95+/100 score)
- Stage 2: Output format validation (5-phase test plan)
- Stage 3: Archived deprecated utilities (commits: [hash])
- Stage 4: Removed backup files (commits: [hash])
- Stage 5: Phase 2.5 integration strategy designed

Results:
- complexity-estimator.md: 85/100 → 95+/100 enforcement score
- Complexity output format validated for Phase 4
- ~2.2MB cruft archived/removed (clarity improved)
- Phase 4 Stage 0 specification created
- Phase 4 ready to proceed

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## References

- [Phase 3 Plan](phase_3_complexity_evaluation.md)
- [Phase 3 Pre-Phase 4 Analysis Report](reports/phase_3_pre_phase_4_analysis.md)
- [080 Main Plan](080_orchestrate_enhancement.md)
- [complexity-estimator Agent](../../../agents/complexity-estimator.md)
- [orchestrate Command](../../../commands/orchestrate.md)
- [Command Architecture Standards](../../../docs/reference/command_architecture_standards.md)
- [Agent Development Guide](../../../docs/guides/agent-development-guide.md)
- [Writing Standards](../../../docs/concepts/writing-standards.md)
