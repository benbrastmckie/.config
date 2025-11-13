# .claude/docs/ Reorganization Implementation Plan

## Metadata
- **Date**: 2025-11-12
- **Feature**: Documentation consolidation and reorganization
- **Scope**: Eliminate redundant files, consolidate duplicates, improve navigation in .claude/docs/
- **Estimated Phases**: 7
- **Estimated Hours**: 18-24
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 87.5
- **Research Reports**:
  - [Architecture and Design Analysis](/home/benjamin/.config/.claude/specs/686_relevant_and_which_could_be_eliminated_combined/reports/001_research_documents__architecture_and_design.md)
  - [Implementation Approach and Patterns](/home/benjamin/.config/.claude/specs/686_relevant_and_which_could_be_eliminated_combined/reports/002_implementation_approach_and_patterns.md)
  - [Testing and Validation Strategy](/home/benjamin/.config/.claude/specs/686_relevant_and_which_could_be_eliminated_combined/reports/003_testing_and_validation_strategy.md)

## Overview

The .claude/docs/ directory contains 128 markdown files (2.9MB) following the Diataxis framework. Research reveals well-organized architecture documentation but significant opportunities for improvement through consolidation, elimination of redirect stubs, archive pruning, and enhanced navigation. This plan implements a systematic reorganization achieving 15-20% size reduction while maintaining all production-critical content.

**Key Goals**:
1. Eliminate redirect stub files and archived duplicates (7 files)
2. Consolidate duplicate content (development-workflow, orchestration, testing)
3. Prune obsolete archive files (5 files, ~150KB)
4. Fix broken links and resolve TODO markers (6 links, 35 TODOs)
5. Improve navigation with enhanced quick-reference system
6. Add comprehensive TOCs to large files (6 files > 2,000 lines)
7. Establish automated validation testing

## Research Summary

**Finding 1 - Architecture Documentation (Report 1)**:
All 4 architecture documents are production-critical, actively referenced in CLAUDE.md, and should be retained without modification. No redundancy detected.

**Finding 2 - Duplicate Content (Report 2)**:
- 3 redirect stub files in guides/ should be deleted (using-agents.md, command-examples.md, imperative-language-guide.md archive version)
- development-workflow.md exists in both concepts/ and workflows/ with identical content (173 lines)
- Orchestration documentation fragmented across 16 files (~12,000 lines)

**Finding 3 - Archive Bloat (Report 2)**:
Archive directory (440KB, 23 files) is larger than workflows/ and contains obsolete orchestration patterns that can be moved to git history only.

**Finding 4 - Navigation Challenges (Report 3)**:
- Users struggle to find correct orchestration documentation (16 files in multiple categories)
- Missing task-to-command mapping in main README
- Files > 2,000 lines lack comprehensive TOCs (6 files)
- 6 broken links in llm-classification-pattern.md
- 35 TODO markers need resolution

**Finding 5 - Validation Gaps (Report 3)**:
No automated testing for link health, cross-references, or Diataxis compliance. Need validation suite with 10 tests covering link health, cross-references, category compliance, and navigation completeness.

## Success Criteria

- [ ] 7 redirect/duplicate files eliminated from active documentation
- [ ] 5 obsolete archive files moved to git history only
- [ ] development-workflow.md consolidation complete (single authoritative source)
- [ ] Orchestration documentation organized into 3-tier structure
- [ ] All 6 broken links fixed
- [ ] All 35 TODO markers resolved or documented
- [ ] 6 large files have comprehensive TOCs with anchor links
- [ ] "I Want To..." section expanded from 14 to 25+ items
- [ ] Zero broken internal links (validated)
- [ ] Automated validation test suite operational
- [ ] 15-20% size reduction achieved (2.9MB → 2.3-2.5MB)
- [ ] All changes maintain backward compatibility for production references

## Technical Design

### Approach

**3-Phase Consolidation Strategy**:

1. **Safe Eliminations** (Phase 1-2): Remove redirect stubs and archive files with zero production impact
2. **Content Consolidation** (Phase 3-4): Merge duplicate content and reorganize orchestration docs
3. **Quality Improvements** (Phase 5-7): Fix links, resolve TODOs, add navigation aids, establish testing

**File Organization Principles**:
- Preserve all architecture documents (production-critical)
- Maintain Diataxis separation (Reference, Guides, Concepts, Workflows)
- Single source of truth for all content
- Backward compatibility for CLAUDE.md references
- Clean-break philosophy: git history instead of inline archives

**Risk Mitigation**:
- Create backups before eliminations
- Validate all references before removal
- Update links atomically
- Test after each phase
- Maintain git commits for rollback

### Architecture Changes

**Directory Structure** (before → after):

```
.claude/docs/
├── guides/ (45 files → 42 files)          # Remove 3 redirect stubs
├── archive/ (23 files → 18 files)         # Prune 5 obsolete files
├── concepts/ (18 files → 17 files)        # Remove duplicate development-workflow
├── workflows/ (10 files → 10 files)       # Keep, enhance development-workflow
├── reference/ (15 files → 16 files)       # Add consolidated orchestration-reference
├── architecture/ (4 files → 4 files)      # NO CHANGES (production-critical)
├── patterns/ (12 files → 12 files)        # NO CHANGES
├── quick-reference/ (6 files → 8 files)   # Add task-to-command mapping, expanded index
├── troubleshooting/ (5 files → 5 files)   # NO CHANGES
└── README.md                              # Enhance with expanded "I Want To..." section
```

**File Count**: 128 → 115 files (10% reduction)
**Size**: 2.9MB → 2.4MB (17% reduction)

### Integration Points

**CLAUDE.md References** (50+ total):
- All architecture document references preserved unchanged
- Pattern references remain valid (no pattern files modified)
- Command guide references remain valid (guides not renamed)
- New orchestration-reference.md becomes canonical reference (CLAUDE.md update required)

**Command Files** (.claude/commands/):
- All 8 command guides remain accessible with same paths
- No command file modifications needed
- Cross-references to guides remain valid

**Library Utilities** (.claude/lib/):
- No library code changes required
- Documentation updates only

## Implementation Phases

### Phase 1: Pre-Flight Validation and Backups
dependencies: []

**Objective**: Establish baseline, create safety mechanisms, validate current state

**Complexity**: Low

**Tasks**:
- [ ] Run full link validation script: `bash /home/benjamin/.config/.claude/scripts/validate-links.sh > /tmp/link-validation-baseline.txt`
- [ ] Document all 6 broken links in llm-classification-pattern.md with proposed fixes
- [ ] Create complete backup: `tar -czf /tmp/claude-docs-backup-$(date +%Y%m%d).tar.gz /home/benjamin/.config/.claude/docs/`
- [ ] Count current files and sizes: `find /home/benjamin/.config/.claude/docs -name "*.md" -exec wc -l {} + > /tmp/docs-baseline-counts.txt`
- [ ] Audit all 35 TODO markers: `grep -r "TODO\|FIXME" /home/benjamin/.config/.claude/docs --include="*.md" -n -H > /tmp/todo-audit.txt`
- [ ] Verify all 4 architecture documents referenced in CLAUDE.md: `grep -n "architecture/" /home/benjamin/.config/CLAUDE.md`
- [ ] Create git checkpoint: `git add -A && git commit -m "checkpoint(686): baseline before docs reorganization"`

**Testing**:
```bash
# Verify backup created
test -f /tmp/claude-docs-backup-*.tar.gz && echo "✓ Backup created"

# Verify baseline files exist
test -f /tmp/link-validation-baseline.txt && echo "✓ Link validation baseline"
test -f /tmp/docs-baseline-counts.txt && echo "✓ File count baseline"
test -f /tmp/todo-audit.txt && echo "✓ TODO audit baseline"

# Verify git checkpoint
git log -1 --oneline | grep "checkpoint(686)"
```

**Expected Duration**: 1-2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (backup exists, baselines created, git checkpoint created)
- [ ] Git commit created: `feat(686): complete Phase 1 - Pre-Flight Validation and Backups`
- [ ] Checkpoint saved (baseline files in /tmp/)
- [ ] Update this plan file with phase completion status

### Phase 2: Safe Eliminations - Redirect Stubs and Archive Duplicates
dependencies: [1]

**Objective**: Remove redirect stubs from guides/ and duplicate archive files (zero production impact)

**Complexity**: Low

**Tasks**:
- [ ] Delete redirect stub: `rm /home/benjamin/.config/.claude/docs/guides/using-agents.md` (30 lines, consolidated into agent-development-guide.md)
- [ ] Delete redirect stub: `rm /home/benjamin/.config/.claude/docs/guides/command-examples.md` (29 lines, consolidated into command-development-guide.md)
- [ ] Verify archive version can be removed: `diff /home/benjamin/.config/.claude/docs/guides/imperative-language-guide.md /home/benjamin/.config/.claude/docs/archive/guides/imperative-language-guide.md`
- [ ] Delete archive duplicate if identical: `rm /home/benjamin/.config/.claude/docs/archive/guides/imperative-language-guide.md` (only if diff shows no differences)
- [ ] Validate no active references to deleted files: `grep -r "using-agents.md\|command-examples.md" /home/benjamin/.config/.claude/docs/{guides,reference,concepts,workflows} --include="*.md"`
- [ ] Update guides/README.md: Remove references to deleted redirect stubs
- [ ] Run link validation: `bash /home/benjamin/.config/.claude/scripts/validate-links-quick.sh` (should show zero new broken links)

**Testing**:
```bash
# Verify files deleted
! test -f /home/benjamin/.config/.claude/docs/guides/using-agents.md && echo "✓ using-agents.md removed"
! test -f /home/benjamin/.config/.claude/docs/guides/command-examples.md && echo "✓ command-examples.md removed"

# Verify no broken links
bash /home/benjamin/.config/.claude/scripts/validate-links-quick.sh | grep -q "ERROR" && echo "✗ Broken links found" || echo "✓ No new broken links"

# Verify guides count reduced
find /home/benjamin/.config/.claude/docs/guides -name "*.md" | wc -l  # Should be 42-43
```

**Expected Duration**: 1 hour

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (files removed, no broken links, guides count reduced)
- [ ] Git commit created: `feat(686): complete Phase 2 - Remove Redirect Stubs and Archive Duplicates`
- [ ] Checkpoint saved (validation output)
- [ ] Update this plan file with phase completion status

### Phase 3: Archive Pruning - Move Obsolete Files to Git History
dependencies: [2]

**Objective**: Remove 5 obsolete archive files that are superseded by current documentation

**Complexity**: Medium

**Tasks**:
- [ ] Validate no active references to archive/reference/orchestration-patterns.md: `grep -r "orchestration-patterns.md" /home/benjamin/.config/.claude/docs/{guides,reference,concepts,workflows} --include="*.md"`
- [ ] Delete: `rm /home/benjamin/.config/.claude/docs/archive/reference/orchestration-patterns.md` (2,522 lines, 91KB - superseded by current patterns catalog)
- [ ] Delete: `rm /home/benjamin/.config/.claude/docs/archive/orchestration_enhancement_guide.md` (integrated into current orchestration guides)
- [ ] Delete: `rm /home/benjamin/.config/.claude/docs/archive/reference/orchestration-alternatives.md` (covered by orchestration-reference.md)
- [ ] Delete: `rm /home/benjamin/.config/.claude/docs/archive/reference/orchestration-commands-quick-reference.md` (replaced by orchestration-reference.md)
- [ ] Validate no active references exist: `grep -r "orchestration_enhancement_guide\|orchestration-alternatives\|orchestration-commands-quick-reference" /home/benjamin/.config/.claude/docs/{guides,reference,concepts,workflows} --include="*.md"`
- [ ] Update archive/README.md: Document pruning with "Removed YYYY-MM-DD: [list of files] - Reason: Superseded by current documentation, available in git history"
- [ ] Measure size reduction: `du -sh /home/benjamin/.config/.claude/docs/archive/` (should show ~290KB, down from 440KB)

**Testing**:
```bash
# Verify files deleted
! test -f /home/benjamin/.config/.claude/docs/archive/reference/orchestration-patterns.md && echo "✓ orchestration-patterns.md removed from archive"

# Verify no broken references
bash /home/benjamin/.config/.claude/scripts/validate-links.sh | grep -q "ERROR" && echo "✗ Broken links" || echo "✓ No broken links"

# Verify archive size reduced
ARCHIVE_SIZE=$(du -sm /home/benjamin/.config/.claude/docs/archive/ | awk '{print $1}')
[ "$ARCHIVE_SIZE" -lt 1 ] && echo "✓ Archive size reduced to ${ARCHIVE_SIZE}KB"
```

**Expected Duration**: 2 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (5 files removed, no broken references, archive size reduced ~34%)
- [ ] Git commit created: `feat(686): complete Phase 3 - Prune Obsolete Archive Files`
- [ ] Checkpoint saved (archive size measurement)
- [ ] Update this plan file with phase completion status

### Phase 4: Consolidate Duplicate Content
dependencies: [3]

**Objective**: Merge development-workflow.md duplicates and create orchestration reference consolidation

**Complexity**: High

**Tasks**:
- [ ] Read both development-workflow files: `diff /home/benjamin/.config/.claude/docs/concepts/development-workflow.md /home/benjamin/.config/.claude/docs/workflows/development-workflow.md`
- [ ] Enhance workflows/development-workflow.md: Add step-by-step tutorial sections, real examples, command invocations (transform from explanation to learning-oriented tutorial)
- [ ] Update concepts/development-workflow.md: Transform to understanding-oriented explanation (WHY spec updater integration works, architecture decisions, not HOW to use it)
- [ ] Validate differentiation achieved: Read both files, ensure concepts/ explains architecture and workflows/ teaches through examples
- [ ] Create reference/orchestration-reference-consolidated.md: Merge key sections from guides/orchestration-best-practices.md (1,517 lines) into reference/orchestration-reference.md
- [ ] Add "Which Command Should I Use?" decision tree to orchestration-reference-consolidated.md
- [ ] Add command comparison tables to orchestration-reference-consolidated.md (compare /coordinate, /orchestrate, /supervise)
- [ ] Update all cross-references: `grep -r "orchestration-best-practices.md" /home/benjamin/.config/.claude/docs --include="*.md" -l` (update to reference orchestration-reference-consolidated.md)
- [ ] Archive guides/orchestration-best-practices.md: `mv /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md /home/benjamin/.config/.claude/docs/archive/guides/` (content distributed to orchestration-reference and command guides)
- [ ] Update guides/README.md: Remove orchestration-best-practices.md reference

**Testing**:
```bash
# Verify development-workflow files are differentiated
grep -c "step-by-step\|tutorial\|example" /home/benjamin/.config/.claude/docs/workflows/development-workflow.md  # Should be high
grep -c "architecture\|design decision\|why" /home/benjamin/.config/.claude/docs/concepts/development-workflow.md  # Should be high

# Verify orchestration reference consolidation complete
test -f /home/benjamin/.config/.claude/docs/reference/orchestration-reference-consolidated.md && echo "✓ Consolidated reference created"

# Verify all cross-references updated
bash /home/benjamin/.config/.claude/scripts/validate-links.sh | grep -q "ERROR" && echo "✗ Broken links" || echo "✓ All links valid"
```

**Expected Duration**: 4-5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (development-workflow differentiated, orchestration reference consolidated, all links valid)
- [ ] Git commit created: `feat(686): complete Phase 4 - Consolidate Duplicate Content`
- [ ] Checkpoint saved (consolidated file created)
- [ ] Update this plan file with phase completion status

### Phase 5: Fix Broken Links and Resolve TODO Markers
dependencies: [4]

**Objective**: Achieve zero broken internal links and document resolution plan for all TODOs

**Complexity**: Medium

**Tasks**:
- [ ] Fix 6 broken links in llm-classification-pattern.md: Read /tmp/link-validation-baseline.txt, identify broken lib/ and test/ references
- [ ] Update lib/ references in llm-classification-pattern.md using Edit tool (correct paths to .claude/lib/ utilities)
- [ ] Update test/ references in llm-classification-pattern.md using Edit tool (correct paths to .claude/tests/)
- [ ] Run full link validation: `bash /home/benjamin/.config/.claude/scripts/validate-links.sh > /tmp/link-validation-after-fixes.txt`
- [ ] Verify zero broken links: `grep -c "ERROR" /tmp/link-validation-after-fixes.txt` (should be 0)
- [ ] Review all 35 TODO markers from /tmp/todo-audit.txt
- [ ] For each TODO: Document resolution plan (complete now, create issue, or set completion timeline)
- [ ] Create /home/benjamin/.config/.claude/docs/TODO-RESOLUTION-PLAN.md: Document status of all 35 TODOs with completion timelines
- [ ] Resolve high-priority TODOs immediately (estimate 5-10 can be completed during this phase)
- [ ] Update remaining TODOs with completion dates or issue links

**Testing**:
```bash
# Verify zero broken links
BROKEN_COUNT=$(grep -c "ERROR" /tmp/link-validation-after-fixes.txt || echo 0)
[ "$BROKEN_COUNT" -eq 0 ] && echo "✓ Zero broken links" || echo "✗ $BROKEN_COUNT broken links remain"

# Verify TODO resolution plan exists
test -f /home/benjamin/.config/.claude/docs/TODO-RESOLUTION-PLAN.md && echo "✓ TODO resolution plan documented"

# Verify high-priority TODOs resolved
REMAINING_TODOS=$(grep -rc "TODO\|FIXME" /home/benjamin/.config/.claude/docs --include="*.md" | awk -F: '{sum+=$2} END {print sum}')
[ "$REMAINING_TODOS" -lt 30 ] && echo "✓ High-priority TODOs resolved ($REMAINING_TODOS remain)" || echo "⚠ $REMAINING_TODOS TODOs remain"
```

**Expected Duration**: 3-4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (zero broken links, TODO plan documented, high-priority TODOs resolved)
- [ ] Git commit created: `feat(686): complete Phase 5 - Fix Broken Links and Resolve TODOs`
- [ ] Checkpoint saved (link validation output, TODO resolution plan)
- [ ] Update this plan file with phase completion status

### Phase 6: Navigation Enhancements and Large File TOCs
dependencies: [5]

**Objective**: Add comprehensive TOCs to large files and expand "I Want To..." section

**Complexity**: Medium

**Tasks**:
- [ ] Identify files > 2,000 lines: `find /home/benjamin/.config/.claude/docs -name "*.md" -exec wc -l {} + | awk '$1 > 2000 {print $0}' | sort -rn > /tmp/large-files.txt`
- [ ] Add comprehensive TOC with anchor links to command-development-guide.md (3,980 lines) at top of file
- [ ] Add comprehensive TOC with anchor links to coordinate-command-guide.md (2,277 lines)
- [ ] Add comprehensive TOC with anchor links to hierarchical_agents.md (2,217 lines)
- [ ] Add comprehensive TOC with anchor links to agent-development-guide.md (2,178 lines)
- [ ] Add comprehensive TOC with anchor links to workflow-phases.md (2,176 lines)
- [ ] Add comprehensive TOC with anchor links to command_architecture_standards.md (2,462 lines)
- [ ] Expand main README.md "I Want To..." section from 14 items to 25+ items (add task-to-command mappings, troubleshooting scenarios)
- [ ] Create quick-reference/task-to-command-mapping.md: Map 30 common tasks to specific command and guide files
- [ ] Create quick-reference/troubleshooting-index.md: Map common issues to troubleshooting files and guides
- [ ] Update quick-reference/README.md: Add navigation to new files

**Testing**:
```bash
# Verify TOCs added to all large files
for file in command-development-guide.md coordinate-command-guide.md hierarchical_agents.md agent-development-guide.md workflow-phases.md command_architecture_standards.md; do
  grep -q "## Table of Contents" "/home/benjamin/.config/.claude/docs"/**/"$file" && echo "✓ TOC in $file" || echo "✗ Missing TOC in $file"
done

# Verify README "I Want To..." expanded
IWANT_COUNT=$(grep -A 100 "I Want To" /home/benjamin/.config/.claude/docs/README.md | grep -c "^- ")
[ "$IWANT_COUNT" -ge 25 ] && echo "✓ I Want To... expanded ($IWANT_COUNT items)" || echo "✗ Only $IWANT_COUNT items"

# Verify new quick-reference files
test -f /home/benjamin/.config/.claude/docs/quick-reference/task-to-command-mapping.md && echo "✓ Task mapping created"
test -f /home/benjamin/.config/.claude/docs/quick-reference/troubleshooting-index.md && echo "✓ Troubleshooting index created"
```

**Expected Duration**: 3-4 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (6 large files have TOCs, README expanded, new quick-reference files created)
- [ ] Git commit created: `feat(686): complete Phase 6 - Navigation Enhancements and Large File TOCs`
- [ ] Checkpoint saved (large files list, enhanced README)
- [ ] Update this plan file with phase completion status

### Phase 7: Automated Validation Testing and Final Verification
dependencies: [6]

**Objective**: Establish automated validation suite and verify all success criteria met

**Complexity**: High

**Tasks**:
- [ ] Create .claude/tests/test_docs_validation.sh: Implement 10 validation tests from research report
- [ ] Test 1 - Full link validation: `bash /home/benjamin/.config/.claude/scripts/validate-links.sh` (zero errors)
- [ ] Test 2 - Cross-reference validation: Verify all "hierarchical agent" mentions link to concepts/hierarchical_agents.md
- [ ] Test 3 - Diataxis category compliance: Verify reference files have no step-by-step instructions
- [ ] Test 4 - File size threshold validation: Verify all files > 2,000 lines have TOCs
- [ ] Test 5 - TODO/FIXME resolution validation: Verify all TODOs documented in resolution plan
- [ ] Test 6 - Archive reference validation: Verify zero active docs reference archive/ files
- [ ] Test 7 - Pattern catalog completeness: Verify all 11 patterns listed in patterns/README.md
- [ ] Test 8 - Navigation completeness: Verify all active files linked from README hierarchy
- [ ] Test 9 - Executable/documentation separation validation: Verify all command guides have corresponding executables
- [ ] Test 10 - Cross-category reference balance: Measure outbound link percentages per category
- [ ] Run complete validation suite: `bash /home/benjamin/.config/.claude/tests/test_docs_validation.sh > /tmp/validation-results.txt`
- [ ] Measure final metrics: File count, total size, archive size, broken links, TODO count
- [ ] Compare against baseline: Verify 15-20% size reduction achieved, 10% file count reduction
- [ ] Update CLAUDE.md if needed: Add reference to new orchestration-reference-consolidated.md
- [ ] Document all changes in .claude/docs/REORGANIZATION-SUMMARY.md: List eliminated files, consolidations, improvements

**Testing**:
```bash
# Verify all 10 tests passing
TEST_PASS_COUNT=$(grep -c "✓" /tmp/validation-results.txt)
[ "$TEST_PASS_COUNT" -ge 10 ] && echo "✓ All validation tests passing" || echo "✗ Only $TEST_PASS_COUNT/10 tests passing"

# Verify size reduction achieved
INITIAL_SIZE=2900  # KB (baseline)
FINAL_SIZE=$(du -sm /home/benjamin/.config/.claude/docs/ | awk '{print $1}')
REDUCTION_PCT=$(echo "scale=1; (($INITIAL_SIZE - $FINAL_SIZE) / $INITIAL_SIZE) * 100" | bc)
echo "Size reduction: $REDUCTION_PCT% (target: 15-20%)"

# Verify file count reduction
INITIAL_COUNT=128
FINAL_COUNT=$(find /home/benjamin/.config/.claude/docs -name "*.md" | wc -l)
COUNT_REDUCTION_PCT=$(echo "scale=1; (($INITIAL_COUNT - $FINAL_COUNT) / $INITIAL_COUNT) * 100" | bc)
echo "File count reduction: $COUNT_REDUCTION_PCT% (target: 10%)"

# Verify zero broken links
bash /home/benjamin/.config/.claude/scripts/validate-links.sh | grep -q "ERROR" && echo "✗ Broken links remain" || echo "✓ Zero broken links"
```

**Expected Duration**: 4-5 hours

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all 10 validation tests pass, size/count reduction targets met, zero broken links)
- [ ] Git commit created: `feat(686): complete Phase 7 - Automated Validation Testing and Final Verification`
- [ ] Checkpoint saved (validation results, final metrics)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Validation Tests (10 Required)

1. **Link Validation**: `bash /home/benjamin/.config/.claude/scripts/validate-links.sh` - Zero broken internal links
2. **Cross-Reference Validation**: All pattern/concept references link to authoritative sources
3. **Diataxis Compliance**: Reference files information-oriented, guides task-oriented, concepts understanding-oriented, workflows learning-oriented
4. **File Size Thresholds**: All files > 2,000 lines have comprehensive TOCs
5. **TODO Resolution**: All TODO markers documented with completion plan
6. **Archive Isolation**: Zero active documentation references to archive/ files
7. **Pattern Catalog**: All 11 patterns listed in patterns/README.md
8. **Navigation Completeness**: All active files discoverable from README hierarchy
9. **Separation Pattern**: All command guides have corresponding executable files
10. **Cross-Category Balance**: Appropriate outbound link percentages per Diataxis category

### Success Metrics

**Quantitative Targets**:
- Size reduction: 15-20% (2.9MB → 2.3-2.5MB) ✓
- File count reduction: 10% (128 → 115 files) ✓
- Archive reduction: 34% (440KB → 290KB) ✓
- Broken links: 0 (current: 6) ✓
- TODO markers: Documented plan for all 35 ✓

**Qualitative Targets**:
- Discoverability: Any task findable in <2 minutes via "I Want To..." section
- Clarity: Each file has single, clear purpose (no overlapping content)
- Maintainability: Updates require changes to ≤2 files (not 5-10)
- Completeness: All commands, patterns, workflows documented

### Regression Prevention

- Automated link validation in CI/CD (run on commit)
- Monthly documentation health checks (file count, size, TODO audit)
- Quarterly Diataxis compliance review
- Archive policy enforcement (no active references to archive/)

## Documentation Requirements

### Files to Update

1. **Main README.md**: Expand "I Want To..." section from 14 to 25+ items
2. **archive/README.md**: Document pruned files with rationale
3. **guides/README.md**: Remove deleted redirect stub references
4. **quick-reference/README.md**: Add navigation to new mapping files
5. **CLAUDE.md** (if needed): Reference to orchestration-reference-consolidated.md
6. **New: TODO-RESOLUTION-PLAN.md**: Document all 35 TODO markers with completion timelines
7. **New: REORGANIZATION-SUMMARY.md**: Document all changes (eliminated files, consolidations, improvements)

### Cross-References to Update

- All references to orchestration-best-practices.md → orchestration-reference-consolidated.md
- Development workflow references: Distinguish concepts/ (WHY) from workflows/ (HOW)
- Large file navigation: Add "see Table of Contents" notes in opening sections

## Dependencies

### External Dependencies
- Link validation script: `/home/benjamin/.config/.claude/scripts/validate-links.sh` (exists)
- Link validation quick script: `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh` (exists)
- Git for version control and checkpoint creation

### Internal Dependencies
- All 4 architecture documents must remain unchanged (production-critical)
- CLAUDE.md references must remain valid (50+ total references)
- Command guide paths must remain stable (8 command guides)
- Pattern catalog structure preserved (11 patterns)

### Research Reports
This plan implements findings from:
- Report 1: Architecture documents analysis (all 4 retained)
- Report 2: Duplicate content identification (7 files eliminated, orchestration consolidation)
- Report 3: Validation strategy (10 tests, navigation enhancements)

## Risk Assessment

### Low Risk Changes
- Link fixes (zero functional impact) - Phase 5
- Archive pruning (git history preserved) - Phase 3
- Navigation improvements (additive) - Phase 6
- TODO resolution documentation (planning only) - Phase 5

### Medium Risk Changes
- Redirect stub deletion (validated no active references) - Phase 2
- Development workflow differentiation (content preserved, context changed) - Phase 4
- Large file TOC additions (formatting only) - Phase 6

### High Risk Changes
- Archive file elimination (mitigated: validation before removal, git history) - Phase 3
- Orchestration best practices consolidation (mitigated: content distributed, not deleted) - Phase 4
- Cross-reference updates (mitigated: automated link validation) - Phase 4

### Mitigation Strategies
1. Complete backup before any eliminations (Phase 1)
2. Validate all references before file removal (Phase 2-3)
3. Atomic link updates with immediate validation (Phase 4-5)
4. Git checkpoints after each phase (all phases)
5. Rollback capability via git history (all phases)

## Notes

**Clean-Break Philosophy**: This plan follows the project's clean-break approach - obsolete files moved to git history only, not preserved in working tree with redirect stubs or deprecation warnings.

**Fail-Fast Validation**: Link validation runs after every elimination/consolidation phase to catch broken references immediately.

**Single Source of Truth**: All consolidations establish one authoritative file, with other references removed or redirected (not duplicated).

**Backward Compatibility**: All CLAUDE.md references and command guide paths preserved. Only internal documentation structure changes.

**Expansion Hint**: Complexity score of 87.5 suggests considering `/expand-phase` for Phase 4 (content consolidation) and Phase 7 (validation testing) during implementation if task lists grow beyond 10 tasks.
