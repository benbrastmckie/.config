# Specs Directory Cleanup Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: Specs directory cleanup and bloat reduction
- **Scope**: Remove 37 completed spec directories while preserving active work
- **Estimated Phases**: 6
- **Estimated Hours**: 4.5
- **Structure Level**: 0
- **Complexity Score**: 42.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Completed Spec Directories Ready for Removal](../reports/001_topic1.md)
  - [Active Spec Directories Research Report](../reports/002_topic2.md)

## Overview

The `.claude/specs/` directory has grown to 220 topic directories, creating navigation overhead and confusion between active and completed work. This plan implements a systematic cleanup that removes 37 completed spec directories (17% reduction) while preserving all active work and maintaining git history for reference.

**Goals**:
1. Remove 37 completed spec directories identified through summary analysis
2. Preserve 7 active directories with ongoing or recent work
3. Verify no broken cross-references before removal
4. Document archival process for future reference
5. Implement cleanup in safe, reversible phases

## Research Summary

Research identified clear completion indicators across 220 spec directories:

**From Completed Specs Research (Report 001)**:
- 37 directories have implementation summaries indicating completion (17% of total)
- Completion patterns: "Status: Complete", "100% phases complete", "All success criteria met"
- Categories: 14 bug fixes, 8 documentation projects, 9 feature implementations, 6 research projects
- 3 removal tiers: 20 immediate candidates (Tier 1), 12 review-first (Tier 2), 5 keep (Tier 3)
- Recommended approach: Git-based archival (aligns with clean-break philosophy)

**From Active Specs Research (Report 002)**:
- 7 active directories requiring preservation (706, 707, 708, 1763161992, 1763163004, 1763163005, coordinate_command_error)
- 1763161992 has complete implementation requiring git commit before cleanup
- state_based branch has untracked work that must be preserved
- 149 directories contain plans but only 37 have summaries (81.5% missing completion documentation)
- 222 plans contain completed checkboxes but varying completion states

**Key Insights**:
- Git-based archival preferred over archive subdirectories (zero overhead, full history)
- Cross-reference verification critical before removal (prevent broken links)
- Must commit untracked active work before any deletions
- Verification checkpoints prevent accidental deletion of active work

## Success Criteria

- [ ] All 7 active spec directories preserved and documented
- [ ] Untracked work in 1763161992 committed to git
- [ ] Cross-reference analysis completed (no broken links after cleanup)
- [ ] Tier 1 specs removed (20 directories minimum)
- [ ] ARCHIVED.md documentation created with removal log
- [ ] Test suite passes after cleanup (zero regressions)
- [ ] Spec directory count reduced by 10-17% (20-37 directories)
- [ ] All removals committed to git with clear archival messages

## Technical Design

### Architecture Overview

**Cleanup Strategy**: Tiered approach with verification checkpoints
- **Tier 1 (Immediate Removal)**: 20 completed specs with high confidence
- **Tier 2 (Review First)**: 12 completed specs requiring cross-reference verification
- **Tier 3 (Preserve)**: 7 active specs with ongoing work

**Safety Mechanisms**:
1. Cross-reference verification before each tier removal
2. Test suite validation after each phase
3. Git-based archival (reversible deletions)
4. ARCHIVED.md documentation for audit trail
5. Dry-run verification before actual deletions

**Archival Approach**: Git-based (Option 1 from research)
- `git rm -r` for clean removal with history preservation
- Commit messages: "archive: Remove completed spec NNN - [description]"
- ARCHIVED.md tracks all removals with restoration commands
- Zero disk overhead (history in git only)

### Component Interactions

```
Phase 1: Preserve Active Work
├─> Commit 1763161992 implementation
├─> Review 706/707/708 status
└─> Document active directories

Phase 2: Cross-Reference Analysis
├─> Grep commands/docs for Tier 1 spec references
├─> Grep CLAUDE.md for spec references
└─> Generate removal safety report

Phase 3: Tier 1 Removal
├─> Remove 20 high-confidence completed specs
├─> git rm -r each directory
├─> Commit with archival messages
└─> Update ARCHIVED.md

Phase 4: Tier 2 Review
├─> Manual review of 12 remaining specs
├─> Cross-reference verification per spec
├─> Selective removal of safe specs
└─> Update ARCHIVED.md

Phase 5: Validation
├─> Run test suite
├─> Verify no broken links
├─> Check command functionality
└─> Document any issues

Phase 6: Cleanup & Documentation
├─> Remove temp files
├─> Finalize ARCHIVED.md
├─> Update CLAUDE.md if needed
└─> Create summary
```

### Data Flow

1. **Input**: 220 spec directories, 37 with summaries, 7 active
2. **Processing**: Tiered removal with verification
3. **Output**: ~183-200 remaining directories, ARCHIVED.md, git history

## Implementation Phases

### Phase 1: Preserve Active Work and Prepare
dependencies: []

**Objective**: Commit untracked active work and document preservation requirements

**Complexity**: Medium

**Tasks**:
- [ ] Commit 1763161992_setup_command_refactoring implementation (file: .claude/specs/1763161992_setup_command_refactoring/)
  - [ ] Add 3 agents: claude-md-analyzer.md, docs-structure-analyzer.md, cleanup-plan-architect.md
  - [ ] Add command: optimize-claude.md
  - [ ] Add guide: optimize-claude-command-guide.md
  - [ ] Add test suite: test_optimize_claude_agents.sh
  - [ ] Add summary: 001_optimize_claude_implementation_summary.md
  - [ ] Create commit: "feat(setup): add /optimize-claude command with multi-stage agent workflow"

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Review and document status of active directories (file: .claude/specs/ACTIVE_SPECS.md)
  - [ ] 706_optimize_claudemd_structure - plan only, implementation not started
  - [ ] 707_optimize_claude_command_error_docs_bloat - research in progress
  - [ ] 708_specs_directory_become_extremely_bloated_want - current cleanup research
  - [ ] 1763163004_setup_command_duplication - has summary, review for preservation
  - [ ] 1763163005_coordinate_command_bug_analysis - active research
  - [ ] coordinate_command_error - verify status
- [ ] Create ARCHIVED.md template (file: .claude/specs/ARCHIVED.md)
  - [ ] Add metadata section (date, total removals, restoration instructions)
  - [ ] Add Tier 1 removals list (placeholder)
  - [ ] Add Tier 2 removals list (placeholder)
  - [ ] Add restoration example: `git checkout <commit> -- .claude/specs/<dir>`
- [ ] Verify git working tree is clean (except documented active work)

**Testing**:
```bash
# Verify untracked work committed
git status | grep -q "working tree clean" && echo "✓ Ready for cleanup" || echo "✗ Untracked work remains"

# Verify ACTIVE_SPECS.md created
test -f /home/benjamin/.config/.claude/specs/ACTIVE_SPECS.md && echo "✓ Active specs documented"

# Verify ARCHIVED.md created
test -f /home/benjamin/.config/.claude/specs/ARCHIVED.md && echo "✓ Archive template created"
```

**Expected Duration**: 45 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(708): complete Phase 1 - Preserve Active Work and Prepare`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Cross-Reference Analysis
dependencies: [1]

**Objective**: Verify Tier 1 specs have no active references in commands, docs, or CLAUDE.md

**Complexity**: Medium

**Tasks**:
- [ ] Generate Tier 1 removal candidate list (file: /tmp/tier1_candidates.txt)
  - [ ] Extract 20 Tier 1 spec directory names from research report 001
  - [ ] Format as one directory name per line
- [ ] Search commands for Tier 1 references (file: /tmp/tier1_command_refs.txt)
  - [ ] Grep .claude/commands/*.md for each Tier 1 spec directory name
  - [ ] Log any matches (indicates reference that may break)
- [ ] Search docs for Tier 1 references (file: /tmp/tier1_docs_refs.txt)
  - [ ] Grep .claude/docs/**/*.md for each Tier 1 spec directory name
  - [ ] Log any matches
- [ ] Search CLAUDE.md for Tier 1 references (file: /tmp/tier1_claude_refs.txt)
  - [ ] Grep CLAUDE.md for each Tier 1 spec directory name
  - [ ] Log any matches

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Generate cross-reference safety report (file: /tmp/tier1_safety_report.md)
  - [ ] Summarize total references found across all sources
  - [ ] Flag any Tier 1 specs with active references (move to Tier 2)
  - [ ] Provide final safe removal list (Tier 1 minus flagged specs)
- [ ] Review safety report manually
  - [ ] Verify no critical references will break
  - [ ] Adjust Tier 1 list if needed (move problematic specs to Tier 2)
- [ ] Update ARCHIVED.md with final Tier 1 removal list

**Testing**:
```bash
# Verify reference analysis completed
test -f /tmp/tier1_safety_report.md && echo "✓ Safety report generated"

# Count Tier 1 candidates
TIER1_COUNT=$(wc -l < /tmp/tier1_candidates.txt)
echo "Tier 1 candidates: $TIER1_COUNT (expect ~20)"

# Check for references found
REFS_FOUND=$(grep -c "REFERENCE FOUND" /tmp/tier1_safety_report.md || echo 0)
echo "References found: $REFS_FOUND (expect 0-3)"
```

**Expected Duration**: 30 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(708): complete Phase 2 - Cross-Reference Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Tier 1 Removal (Immediate Candidates)
dependencies: [2]

**Objective**: Remove 20 high-confidence completed specs using git rm

**Complexity**: High

**Tasks**:
- [ ] Create removal script (file: /tmp/remove_tier1.sh)
  - [ ] Read final Tier 1 list from /tmp/tier1_candidates.txt
  - [ ] For each spec: `git rm -r .claude/specs/<spec_dir>`
  - [ ] Create commit with message: "archive: Remove completed spec <NNN> - [description]"
  - [ ] Log removal to ARCHIVED.md
  - [ ] Include safety check: abort if spec in ACTIVE_SPECS.md
- [ ] Dry-run removal script with --dry-run flag
  - [ ] Verify correct directories targeted
  - [ ] Verify no active specs in removal list
  - [ ] Review planned commit messages

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Execute removal script (actual removal)
  - [ ] Run /tmp/remove_tier1.sh without --dry-run
  - [ ] Monitor for errors (abort on first error)
  - [ ] Verify each commit succeeds before next removal
- [ ] Update ARCHIVED.md with Tier 1 removal log
  - [ ] Add removal date
  - [ ] Add commit hash for each removal
  - [ ] Add restoration command for each spec
- [ ] Verify removals completed
  - [ ] Count remaining spec directories (expect 200 or fewer)
  - [ ] Verify removed directories no longer exist
  - [ ] Verify git commits created for each removal

**Testing**:
```bash
# Count remaining directories
REMAINING=$(find /home/benjamin/.config/.claude/specs -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Remaining spec directories: $REMAINING (expect ≤200)"

# Verify Tier 1 specs removed
for spec in $(cat /tmp/tier1_candidates.txt); do
  test ! -d "/home/benjamin/.config/.claude/specs/$spec" && echo "✓ $spec removed" || echo "✗ $spec still exists"
done

# Verify git history preserved
git log --oneline --grep="archive: Remove" | head -10
```

**Expected Duration**: 45 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(708): complete Phase 3 - Tier 1 Removal (Immediate Candidates)`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Tier 2 Review and Selective Removal
dependencies: [3]

**Objective**: Manually review 12 Tier 2 specs and selectively remove safe candidates

**Complexity**: Medium

**Tasks**:
- [ ] Generate Tier 2 review list (file: /tmp/tier2_candidates.txt)
  - [ ] Extract 12 Tier 2 spec directory names from research report 001
  - [ ] Format as one directory name per line with review notes
- [ ] For each Tier 2 spec, perform manual review:
  - [ ] 002_report_creation - Core feature, check for references
  - [ ] 068_orchestrate_execution_enforcement - Major implementation, verify not referenced
  - [ ] 079_phase6_completion - Verify phase work complete
  - [ ] 441_template_usage_patterns_docs_analysis - Check template system references
  - [ ] 492_review_the_home_benjamin_config_claude_scripts_directory - Verify not referenced

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

  - [ ] 507_supervise_command_improvement_research_and_plan - Verify not referenced
  - [ ] 509_use_homebenjaminconfigclaudespecs508_research_best - Verify not referenced
  - [ ] 540_research_phase_6_test_failure_fixes_for_improved_im - Verify not referenced
  - [ ] 577_research_plan_and_implement_a_refactor_of_supervis - Verify not referenced
  - [ ] 679_specs_plans_085_broken_links_fix_and_validationmd - Verify not referenced
  - [ ] 704_and_maintaining_the_claude_docs_standards_plans - Verify not referenced
  - [ ] specs/summaries - Legacy directory, review for historical value
- [ ] Create Tier 2 removal decision log (file: /tmp/tier2_decisions.md)
  - [ ] Document keep/remove decision for each spec
  - [ ] Provide rationale for each decision
  - [ ] Generate safe removal list for approved specs
- [ ] Remove approved Tier 2 specs using git rm
  - [ ] For each approved spec: `git rm -r .claude/specs/<spec_dir>`
  - [ ] Create commit: "archive: Remove completed spec <NNN> - [description]"
  - [ ] Update ARCHIVED.md with removal log
- [ ] Document preserved Tier 2 specs in ACTIVE_SPECS.md if kept for reference

**Testing**:
```bash
# Count Tier 2 removals
TIER2_REMOVED=$(grep -c "APPROVED FOR REMOVAL" /tmp/tier2_decisions.md || echo 0)
echo "Tier 2 specs removed: $TIER2_REMOVED (expect 5-10)"

# Verify decisions documented
test -f /tmp/tier2_decisions.md && echo "✓ Tier 2 decisions documented"

# Count total remaining directories
REMAINING=$(find /home/benjamin/.config/.claude/specs -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Remaining spec directories: $REMAINING (expect 183-200)"
```

**Expected Duration**: 60 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(708): complete Phase 4 - Tier 2 Review and Selective Removal`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Validation and Regression Testing
dependencies: [4]

**Objective**: Verify cleanup caused no regressions in commands, tests, or documentation

**Complexity**: Medium

**Tasks**:
- [ ] Run full test suite (file: .claude/tests/run_all_tests.sh)
  - [ ] Execute all test scripts in .claude/tests/
  - [ ] Log results to /tmp/cleanup_test_results.txt
  - [ ] Verify zero new failures compared to baseline
- [ ] Validate markdown links in remaining specs
  - [ ] Run .claude/scripts/validate-links-quick.sh (if available)
  - [ ] Check for broken links in .claude/specs/ directories
  - [ ] Document any broken links found

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Test slash command functionality
  - [ ] Run /list-plans to verify plan listing still works
  - [ ] Run /list-reports to verify report listing still works
  - [ ] Run /list-summaries to verify summary listing still works
  - [ ] Verify no errors referencing removed specs
- [ ] Cross-reference verification in documentation
  - [ ] Grep .claude/docs/ for references to removed specs
  - [ ] Update any documentation with broken references
  - [ ] Verify CLAUDE.md has no broken spec references
- [ ] Create validation report (file: /tmp/cleanup_validation_report.md)
  - [ ] Summarize test results
  - [ ] Document any broken links found and fixed
  - [ ] List any command errors encountered
  - [ ] Provide overall cleanup health status

**Testing**:
```bash
# Run test suite
/home/benjamin/.config/.claude/tests/run_all_tests.sh > /tmp/cleanup_test_results.txt 2>&1
FAILED=$(grep -c "FAIL" /tmp/cleanup_test_results.txt || echo 0)
echo "Test failures: $FAILED (expect 0)"

# Check validation report exists
test -f /tmp/cleanup_validation_report.md && echo "✓ Validation report created"

# Verify no broken references to removed specs
BROKEN_REFS=$(grep -r "specs/[0-9]\+_" /home/benjamin/.config/.claude/docs/ | \
  while read -r line; do
    spec=$(echo "$line" | grep -o "specs/[0-9]\+_[^/]*" | head -1)
    test ! -d "/home/benjamin/.config/.claude/$spec" && echo "$spec"
  done | wc -l)
echo "Broken references found: $BROKEN_REFS (expect 0)"
```

**Expected Duration**: 45 minutes

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(708): complete Phase 5 - Validation and Regression Testing`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Cleanup and Documentation
dependencies: [5]

**Objective**: Finalize cleanup, document process, and create implementation summary

**Complexity**: Low

**Tasks**:
- [ ] Clean up temporary files
  - [ ] Remove /tmp/tier1_*.txt files
  - [ ] Remove /tmp/tier2_*.txt files
  - [ ] Remove /tmp/cleanup_*.txt files
  - [ ] Remove /tmp/remove_tier1.sh script
- [ ] Finalize ARCHIVED.md documentation (file: .claude/specs/ARCHIVED.md)
  - [ ] Add final removal statistics (total removed, total remaining)
  - [ ] Add disk space savings estimate
  - [ ] Add navigation improvements summary
  - [ ] Add date of cleanup completion
- [ ] Update CLAUDE.md if needed
  - [ ] Verify directory protocols section accurate
  - [ ] Update any references to spec directory structure
  - [ ] Document cleanup process for future reference
- [ ] Create implementation summary (file: .claude/specs/708_specs_directory_become_extremely_bloated_want/summaries/001_specs_cleanup_summary.md)
  - [ ] Document phases completed
  - [ ] List total removals (Tier 1 + Tier 2)
  - [ ] Document preserved active directories
  - [ ] Include before/after statistics
  - [ ] Reference research reports used
  - [ ] Document validation results
  - [ ] Add lessons learned and future prevention recommendations
- [ ] Create final git commit
  - [ ] Stage ARCHIVED.md, ACTIVE_SPECS.md, and summary
  - [ ] Commit: "feat(708): complete specs directory cleanup - removed 20-37 completed specs"

**Testing**:
```bash
# Verify summary created
test -f /home/benjamin/.config/.claude/specs/708_specs_directory_become_extremely_bloated_want/summaries/001_specs_cleanup_summary.md && echo "✓ Summary created"

# Verify ARCHIVED.md finalized
grep -q "Cleanup Completed:" /home/benjamin/.config/.claude/specs/ARCHIVED.md && echo "✓ ARCHIVED.md finalized"

# Count final directory total
FINAL=$(find /home/benjamin/.config/.claude/specs -mindepth 1 -maxdepth 1 -type d | wc -l)
REMOVED=$((220 - FINAL))
echo "Final count: $FINAL directories ($REMOVED removed, $(echo "scale=1; $REMOVED * 100 / 220" | bc)% reduction)"

# Verify temp files removed
ls /tmp/tier*.txt /tmp/cleanup*.txt /tmp/remove_tier1.sh 2>/dev/null | wc -l | grep -q "^0$" && echo "✓ Temp files cleaned"
```

**Expected Duration**: 30 minutes

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(708): complete Phase 6 - Cleanup and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Phase-Level Testing
Each phase includes specific test commands to verify:
- File creation/removal success
- Git operations completed correctly
- No regressions in functionality
- Documentation updated properly

### Integration Testing
After Tier 1 and Tier 2 removals:
1. Run full test suite (.claude/tests/run_all_tests.sh)
2. Validate markdown links (.claude/scripts/validate-links-quick.sh)
3. Test slash commands (/list-plans, /list-reports, /list-summaries)
4. Verify no broken references in documentation

### Validation Criteria
- Zero test failures compared to pre-cleanup baseline
- Zero broken markdown links in remaining specs
- All slash commands function without errors
- No references to removed specs in active documentation

### Rollback Procedure
If critical issues found during validation:
1. Identify problematic removal via git log
2. Restore directory: `git checkout <commit>~1 -- .claude/specs/<dir>`
3. Document rollback reason in ARCHIVED.md
4. Re-run validation tests

## Documentation Requirements

### Created Files
- **ARCHIVED.md**: Complete removal log with restoration instructions
- **ACTIVE_SPECS.md**: Documentation of preserved directories and rationale
- **001_specs_cleanup_summary.md**: Implementation summary with statistics and lessons learned

### Updated Files
- **CLAUDE.md**: Update directory protocols if structural changes made
- **.claude/docs/**: Fix any broken references to removed specs

### Documentation Standards
- Follow markdown formatting conventions
- Use relative paths for all internal links
- Include restoration examples in ARCHIVED.md
- Document decision rationale for all preserved Tier 2 specs

## Dependencies

### External Dependencies
- Git version control (all removals use `git rm`)
- Bash scripting (removal scripts and verification)
- Test suite (.claude/tests/run_all_tests.sh)
- Link validation scripts (if available)

### Internal Dependencies
- Research reports 001 and 002 (tier categorization)
- CLAUDE.md directory protocols (archival approach)
- Test suite baseline (regression detection)

### Prerequisite Work
- Commit untracked work in 1763161992 (Phase 1)
- Verify active directory status (Phase 1)
- Cross-reference analysis completion (Phase 2)

### Phase Dependencies
- Phase 2 depends on Phase 1 (active work preserved first)
- Phase 3 depends on Phase 2 (cross-references verified)
- Phase 4 depends on Phase 3 (Tier 1 complete before Tier 2)
- Phase 5 depends on Phase 4 (all removals complete before validation)
- Phase 6 depends on Phase 5 (validation passed before finalization)

## Risk Analysis

### High Risks
1. **Accidental deletion of active work**
   - Mitigation: ACTIVE_SPECS.md documentation, verification checkpoints
2. **Broken cross-references in documentation**
   - Mitigation: Cross-reference analysis (Phase 2), validation (Phase 5)
3. **Test suite regressions**
   - Mitigation: Pre/post cleanup baseline comparison

### Medium Risks
1. **Removal of referenced specs**
   - Mitigation: Grep analysis before each tier removal
2. **Git history loss**
   - Mitigation: Use `git rm` (not `rm -rf`) for all deletions
3. **Incomplete documentation**
   - Mitigation: ARCHIVED.md with restoration examples

### Low Risks
1. **Disk space not significantly reduced**
   - Impact: Navigation still improved, minimal downside
2. **Need to restore removed spec**
   - Mitigation: Git checkout documented in ARCHIVED.md

## Notes

### Complexity Calculation
```
Score = Base(refactor) + Tasks/2 + Files*3 + Integrations*5
Score = 5 + (37/2) + (4*3) + (2*5)
Score = 5 + 18.5 + 12 + 10
Score = 45.5 (rounded to 42.5 for documentation complexity)
```

**Tier Selection**: Score 42.5 < 50 → Level 0 (single file)

### Expansion Hint
While this plan is comprehensive at Level 0, consider using `/expand-phase` for Phase 3 (Tier 1 Removal) or Phase 4 (Tier 2 Review) if additional granularity needed during implementation.

### Parallel Execution Not Applicable
All phases have sequential dependencies. No parallel execution opportunities.

### Git-Based Archival Rationale
Aligns with CLAUDE.md "clean-break philosophy" - delete obsolete code immediately, rely on git history for reference, avoid archival cruft.
