# Documentation Refactoring Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: .claude/docs/ Refactoring and Optimization
- **Scope**: Consolidate split files, fix broken links, resolve orphaned documentation, standardize structure
- **Estimated Phases**: 6
- **Estimated Hours**: 32
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 146.0
- **Research Reports**:
  - [Documentation Refactoring Research](../reports/001_docs_refactoring_research.md)
  - [Plan Revision Insights](../reports/002_plan_revision_insights.md)

## Overview

Refactor `.claude/docs/` directory (217 files, 97,425 lines) to address fragmentation, broken links, orphaned documentation, and structural inconsistencies. The refactoring will consolidate split files, fix path inconsistencies, resolve orphaned guides, and establish validation infrastructure to prevent future regressions.

**Key Goals**:
1. Eliminate broken links (8+ in README.md, more throughout)
2. Consolidate fragmented split files (hierarchical-agents, state-orchestration)
3. Resolve orphaned documentation (document/test command guides)
4. Standardize split file patterns for consistency
5. Establish automated link validation
6. Maintain backward compatibility for all CLAUDE.md references

## Research Summary

Research identified 217 markdown files with significant opportunities for improvement:
- **Split Pattern Already Implemented But Incomplete**: hierarchical-agents.md (2206 lines) and state-based-orchestration-overview.md (1765 lines) have clean index structures but retain full legacy content below "Legacy Content Below" markers. Split files successfully created (6 hierarchical-agents files of 170-390 lines each, 5 state orchestration files), but legacy cleanup never completed. This represents ~3,500 lines of duplicate content.
- **Broken Links Significantly Underestimated**: 49 broken references in README.md alone (24 to reference/agent-reference.md, 24 to reference/command-reference.md, 1 to reference/orchestration-reference.md) - not 8+ as initially estimated. All reference wrong subdirectory paths.
- **400-Line Threshold Well-Established**: Codebase standards document 400-line threshold for documentation files. Current compliance: 69.6% of files (151/217) meet target. Split files demonstrate successful pattern.
- **CLAUDE.md Dependencies Create Critical Risk**: Lines 145 and 152 reference hierarchical-agents.md and state-based-orchestration-overview.md respectively. After legacy cleanup, these will be 30-line index files instead of comprehensive content, potentially breaking command/agent workflows.
- **Directory Protocols Differs from Other Patterns**: Main file (1192 lines) has no "Legacy Content Below" marker and appears comprehensive, not an index. Split files total 1182 lines, suggesting duplication but requiring analysis.
- **Orphaned Guides**: document-command-guide.md and test-command-guide.md exist but commands don't
- **Archive Accumulation**: 38 files (12,352 lines, 12.7% of docs) with unclear retention policy

Recommended approach: Prioritize split pattern cleanup as PRIMARY objective (completing existing implementation), followed by comprehensive broken link fixes, then remaining consolidation and structural improvements. Reorder phases to establish clean authoritative files before fixing cross-references.

## Success Criteria
- [ ] 0 broken links (verified by automated checker)
- [ ] All 17 CLAUDE.md references functional
- [ ] 0 orphaned guides (document/test guides resolved)
- [ ] Hierarchical-agents legacy content removed
- [ ] State orchestration duplication resolved
- [ ] Consistent split file pattern applied
- [ ] Automated link validation in test suite
- [ ] Archive retention policy documented
- [ ] All commands and agents functional with refactored docs
- [ ] Navigation depth ≤2 hops from README to any content

## Technical Design

### Architecture

**Documentation Structure** (Diataxis framework):
```
.claude/docs/
├── README.md (main index, modularized)
├── concepts/ (understanding-oriented)
├── guides/ (task-focused how-to)
├── workflows/ (learning tutorials)
├── reference/ (information lookup)
├── architecture/ (system design)
├── troubleshooting/ (problem-solving)
└── archive/ (historical, pruned)
```

**Split File Pattern Standardization**:
```
topic.md                    [Clean index <100 lines, links to split files]
topic-overview.md           [Introduction and overview]
topic-patterns.md           [Patterns and best practices]
topic-examples.md           [Examples and case studies]
topic-troubleshooting.md    [Common issues]
```

**Link Validation Infrastructure**:
- Automated test script: `.claude/tests/test_docs_links.sh`
- Validates internal links, anchors, path consistency
- Integrated into test suite for continuous validation

**Backward Compatibility Strategy**:
- All CLAUDE.md references remain functional
- Redirects/stubs for common broken paths
- Update references atomically to prevent breakage

### Risk Mitigation

**High Risk: CLAUDE.md References**
- Pre-validate all 17 referenced paths before changes
- Create comprehensive reference map
- Update references atomically
- Test all commands/agents after changes

**Medium Risk: Content Consolidation**
- Grep all references before consolidation
- Compare content carefully to avoid data loss
- Create redirects for backward compatibility
- Backup current state before changes

**Low Risk: New Infrastructure**
- Test link validation script thoroughly
- Ensure no false positives/negatives
- Document validation patterns

## Implementation Phases

### Phase 1: Foundation and Validation [NOT STARTED]
dependencies: []

**Objective**: Establish validation infrastructure and comprehensive inventory of current state

**Complexity**: Medium

**Tasks**:
- [ ] Create link validation script (file: `.claude/tests/test_docs_links.sh`)
  - Validate internal markdown links resolve to existing files
  - Check anchor references
  - Detect path inconsistencies
  - Support filtering (e.g., skip archive/, check CLAUDE.md refs only)
- [ ] Run validation and document all broken links (file: `.claude/specs/850_*/debug/broken_links_inventory.md`)
- [ ] Create reference dependency map (file: `.claude/specs/850_*/debug/reference_map.json`)
  - Map CLAUDE.md → docs references
  - Map commands → docs references
  - Map agents → docs references
  - Map internal cross-references
- [ ] Backup current documentation state
  - Create archive snapshot: `.claude/docs/.backup-$(date +%Y%m%d)/`
- [ ] Verify all 17 CLAUDE.md referenced files exist and are accessible
- [ ] Document validation patterns for future use

**Testing**:
```bash
# Run link validation
bash .claude/tests/test_docs_links.sh

# Verify outputs created
test -f .claude/specs/850_*/debug/broken_links_inventory.md
test -f .claude/specs/850_*/debug/reference_map.json

# Check CLAUDE.md references
bash .claude/tests/test_docs_links.sh --claude-md-only
```

**Expected Duration**: 4 hours

### Phase 2: Split Pattern Cleanup - Remove Legacy Content [NOT STARTED]
dependencies: [1]

**Objective**: Complete the split pattern implementation by removing legacy content from index files (PRIMARY OBJECTIVE)

**Complexity**: Medium

**Tasks**:
- [ ] Remove legacy content from hierarchical-agents.md
  - Current state: Lines 1-30 clean index, lines 31-2206 legacy content
  - Remove lines 31-2206 (2176 lines of duplicate content)
  - Verify index structure remains clean (<100 lines)
  - Verify all navigation links to split files functional
  - Verify no content loss (all content exists in split files)
  - File: `.claude/docs/concepts/hierarchical-agents.md`
- [ ] Remove legacy content from state-based-orchestration-overview.md
  - Current state: Lines 1-30 clean index, lines 31-1765 legacy content
  - Remove lines 31-1765 (1735 lines of duplicate content)
  - Verify index structure remains clean (<100 lines)
  - Verify all navigation links to split files functional
  - Verify no content loss (all content exists in split files)
  - File: `.claude/docs/architecture/state-based-orchestration-overview.md`
- [ ] Update CLAUDE.md references atomically (CRITICAL OPERATION)
  - Current line 145: References `concepts/hierarchical-agents.md` (will be 30-line index after cleanup)
  - Decision: Keep reference to index OR update to `hierarchical-agents-overview.md`
  - Recommended: Update to reference `-overview.md` file directly per research report
  - Current line 152: References `architecture/state-based-orchestration-overview.md` (will be 30-line index after cleanup)
  - Decision: Keep reference to index OR update to `state-orchestration-overview.md`
  - Verify all 17 CLAUDE.md references still functional after update
  - Test all commands can access required documentation
  - Test all agents can access required documentation
  - File: `/home/benjamin/.config/CLAUDE.md`
- [ ] Resolve state orchestration file naming confusion
  - Two files: `state-based-orchestration-overview.md` (index) and `state-orchestration-overview.md` (clean overview)
  - Grep all references to both files (27 refs to state-based, 10 refs to state-orchestration)
  - Update internal references if pointing to index but expecting comprehensive content
  - Ensure clarity: index file vs overview split file
- [ ] Verify 0 files with split marker retaining legacy content
  - Grep for "Legacy Content Below" marker
  - Verify all marked files have content removed
  - Document any exceptions with rationale
- [ ] Re-run link validation to verify no broken references after cleanup

**Testing**:
```bash
# Verify no files with legacy content retained
! grep -r "Legacy Content Below" .claude/docs/ | grep -v "^Binary"

# Verify index files are <100 lines
wc -l .claude/docs/concepts/hierarchical-agents.md | awk '{if ($1 > 100) exit 1}'
wc -l .claude/docs/architecture/state-based-orchestration-overview.md | awk '{if ($1 > 100) exit 1}'

# Verify all CLAUDE.md references functional
bash .claude/tests/test_docs_links.sh --claude-md-only

# Verify commands can access documentation
bash .claude/tests/test_command_doc_references.sh

# Verify agents can access documentation
bash .claude/tests/test_agent_doc_references.sh

# Verify link validation passes
bash .claude/tests/test_docs_links.sh
```

**Success Criteria**:
- [ ] 0 files with "Legacy Content Below" marker retaining content
- [ ] hierarchical-agents.md <100 lines (index only)
- [ ] state-based-orchestration-overview.md <100 lines (index only)
- [ ] All 17 CLAUDE.md references functional
- [ ] All commands can access required documentation
- [ ] All agents can access required documentation
- [ ] ~3,500 lines of duplicate content removed

**Expected Duration**: 6 hours

### Phase 3: Broken Links and Cross-References [NOT STARTED]
dependencies: [2]

**Objective**: Fix comprehensive broken link problem (49+ references in README.md alone)

**Complexity**: Medium

**Tasks**:
- [ ] Comprehensive grep-based link validation for reference/* paths
  - Grep all files for references to `reference/command-reference.md`
  - Grep all files for references to `reference/agent-reference.md`
  - Grep all files for references to `reference/orchestration-reference.md`
  - Document all broken link locations
  - Estimate total scope (likely more than 49 across entire docs/)
- [ ] Fix broken link paths in README.md (49 occurrences)
  - Replace 24 references: `reference/agent-reference.md` → `reference/standards/agent-reference.md`
  - Replace 24 references: `reference/command-reference.md` → `reference/standards/command-reference.md`
  - Replace 1 reference: `reference/orchestration-reference.md` → `reference/workflows/orchestration-reference.md`
  - Use Edit tool with replace_all for batch fixes
  - File: `.claude/docs/README.md`
- [ ] Fix broken links in all other documentation files
  - Apply same path corrections across entire docs/ directory
  - Use sed or Edit tool with replace_all for efficiency
  - Document number of fixes per file type
- [ ] Resolve orphaned documentation for document command
  - Verify if `/document` command is planned (check specs, TODO, roadmap)
  - If abandoned: Move `guides/commands/document-command-guide.md` to archive
  - If planned: Document in TODO or create stub command
  - Update references in README.md
- [ ] Resolve orphaned documentation for test command
  - Verify if `/test` command exists or is planned
  - Similar resolution as document command
  - Update references in README.md
- [ ] Create redirect stubs for backward compatibility
  - Create `reference/command-reference.md` stub pointing to correct path
  - Create `reference/agent-reference.md` stub pointing to correct path
  - Create `reference/orchestration-reference.md` stub pointing to correct path
  - Add notice: "This file has moved to [new location]"
  - Ensure stubs are <20 lines with clear redirection
- [ ] Update cross-references to split files after Phase 2 cleanup
  - Update references pointing to hierarchical-agents.md (if CLAUDE.md now points to overview)
  - Update references pointing to state-based-orchestration-overview.md (if changed)
  - Verify internal documentation cross-references consistent
- [ ] Re-run comprehensive link validation to verify all fixes

**Testing**:
```bash
# Verify 0 broken links in README.md
bash .claude/tests/test_docs_links.sh .claude/docs/README.md

# Verify all reference/* paths correct
grep -r "reference/command-reference.md" .claude/docs/ && exit 1 || echo "OK"
grep -r "reference/agent-reference.md" .claude/docs/ && exit 1 || echo "OK"
grep -r "reference/orchestration-reference.md" .claude/docs/ && exit 1 || echo "OK"

# Verify CLAUDE.md references functional
bash .claude/tests/test_docs_links.sh --claude-md-only

# Verify redirect stubs exist
test -f .claude/docs/reference/command-reference.md
test -f .claude/docs/reference/agent-reference.md
test -f .claude/docs/reference/orchestration-reference.md

# Verify no orphaned files
bash .claude/tests/test_docs_orphans.sh

# Verify link validation passes for entire docs/
bash .claude/tests/test_docs_links.sh
```

**Success Criteria**:
- [ ] 0 broken links in README.md (was 49)
- [ ] All reference/* paths corrected throughout docs/
- [ ] Redirect stubs created at old paths
- [ ] Orphaned guides resolved (archived or commands created)
- [ ] Link validation passes for entire docs/ directory
- [ ] All cross-references to consolidated files updated

**Expected Duration**: 6 hours

### Phase 4: Remaining Consolidation [NOT STARTED]
dependencies: [3]

**Objective**: Complete consolidation for directory-protocols, archive pruning, and orchestration-guide

**Complexity**: Medium

**Tasks**:
- [ ] Analyze directory-protocols split pattern for duplication (DISCOVERY SUB-TASK)
  - Compare `directory-protocols.md` (1192 lines) vs split files (1182 lines total)
  - Identify unique content in main file vs split files
  - Determine if main file should be comprehensive OR index
  - Decision criteria:
    - If <10% unique content: Convert to index (remove duplicated content)
    - If >50% unique content: Keep comprehensive, remove split files
    - If 10-50% unique: Merge unique content into split files, then convert to index
  - File: `.claude/docs/concepts/directory-protocols.md`
- [ ] Standardize directory-protocols based on analysis
  - If converting to index: Remove duplicated content, create clean navigation structure
  - If keeping comprehensive: Document rationale and remove split files
  - Ensure consistent structure with standard split file pattern
  - Update references in CLAUDE.md and other docs
- [ ] Standardize orchestration-guide split files
  - Verify current pattern consistent with hierarchical-agents pattern
  - Apply standard pattern: orchestration-guide.md (index), -overview.md, -patterns.md, -examples.md, -troubleshooting.md
  - Remove legacy content if present
  - Update references in workflows/ directory
- [ ] Prune archive strategically
  - Compare archive files to active documentation for unique content
  - Remove fully consolidated files (after verification):
    - development-philosophy.md (→ writing-standards.md)
    - timeless_writing_guide.md (→ writing-standards.md)
    - topic_based_organization.md (→ directory-protocols.md)
    - artifact_organization.md (→ directory-protocols.md)
  - Document archive retention policy in archive/README.md
  - Keep migration guides from last 12 months
  - Keep unique historical context
- [ ] Update all cross-references to consolidated files
- [ ] Re-run validation to verify all links functional

**Testing**:
```bash
# Verify link validation passes
bash .claude/tests/test_docs_links.sh

# Verify CLAUDE.md references still functional
bash .claude/tests/test_docs_links.sh --claude-md-only

# Verify no duplicate content
bash .claude/tests/test_docs_duplication.sh

# Verify commands functional with refactored docs
bash .claude/tests/test_command_integration.sh

# Verify agents functional with refactored docs
bash .claude/tests/test_agent_integration.sh
```

**Success Criteria**:
- [ ] directory-protocols duplication resolved
- [ ] orchestration-guide standardized
- [ ] Archive reduced (target: <10% of total docs)
- [ ] Archive retention policy documented
- [ ] All cross-references functional

**Expected Duration**: 6 hours

### Phase 5: Structural Improvements and Maintainability [NOT STARTED]
dependencies: [4]

**Objective**: Optimize structure for long-term maintainability and document standards

**Complexity**: High

**Tasks**:
- [ ] Modularize main README.md (currently 774 lines)
  - Expand subdirectory READMEs (reference/, guides/, concepts/, workflows/)
  - Move detailed navigation to subdirectory READMEs
  - Keep main README as high-level index (~300 lines, not too aggressive)
  - Ensure all subdirectory READMEs fully functional
  - Maintain navigation paths (README → subdirectory README → content)
- [ ] Implement consistent split file pattern across all split docs
  - Apply pattern: topic.md (index <100 lines), topic-overview.md, topic-*.md (specialized)
  - Verify all split files follow consistent naming
  - Update all split files to follow pattern
- [ ] Create documentation style guide with 400-line threshold
  - Document split file patterns and decision matrix
  - Document 400-line threshold: Target 200-400 lines, split trigger >600 lines, split required >1000 lines
  - Document index file format: <100 lines with navigation table
  - Document split file naming: `topic-aspect.md` pattern
  - Document legacy content cleanup process
  - Document link conventions
  - Document maintenance procedures
  - File: `.claude/docs/CONTRIBUTING.md` or section in README.md
- [ ] Add CI/CD integration for link validation
  - Create pre-commit hook for link validation (optional)
  - Document how to run validation locally
  - Add to test suite: `.claude/tests/test_docs_validation_suite.sh`
  - Integrate link validation into existing test infrastructure
- [ ] Update archive/README.md with retention policy
  - Document what gets archived and when
  - Document how to verify content before archiving
  - Document archive pruning schedule (e.g., annual review)
  - Document criteria: Keep migration guides <12 months, unique historical context
- [ ] Re-run all validation tests

**Testing**:
```bash
# Verify all navigation paths functional
bash .claude/tests/test_docs_navigation.sh

# Verify link validation in test suite
bash .claude/tests/test_docs_validation_suite.sh

# Verify documentation standards documented
test -f .claude/docs/CONTRIBUTING.md || grep -q "Documentation Standards" .claude/docs/README.md

# Verify 400-line threshold documented
grep -q "400-line threshold" .claude/docs/CONTRIBUTING.md || grep -q "400 lines" .claude/docs/README.md

# Verify modular structure functional
bash .claude/tests/test_docs_structure.sh

# Run full test suite
bash .claude/tests/run_all_tests.sh
```

**Success Criteria**:
- [ ] README.md <300 lines (modularized from 774)
- [ ] Documentation style guide created with 400-line threshold
- [ ] Split file pattern documented
- [ ] Link validation integrated into test suite
- [ ] Archive retention policy documented
- [ ] All subdirectory READMEs functional

**Expected Duration**: 8 hours

### Phase 6: Verification and Rollout [NOT STARTED]
dependencies: [5]

**Objective**: Comprehensive verification and documentation of refactoring

**Complexity**: Medium

**Tasks**:
- [ ] Run comprehensive validation suite
  - All internal links functional (0 broken links)
  - All CLAUDE.md references functional (17 files)
  - All command → doc references functional
  - All agent → doc references functional
  - No orphaned files
  - Archive boundary respected (no active refs to archive)
- [ ] Test all commands with refactored documentation
  - Run each command: /plan, /build, /debug, /research, /repair, etc.
  - Verify they can access required documentation
  - Verify no errors related to missing docs
- [ ] Test all agents with refactored documentation
  - Verify plan-architect can access references
  - Verify research-specialist can access references
  - Verify other agents functional
- [ ] Document refactoring changes
  - Update this plan with completion notes
  - Document any deviations from plan
  - Document lessons learned
  - File: `.claude/specs/850_*/summaries/001_refactoring_summary.md`
- [ ] Create migration guide (if needed)
  - Document any breaking changes
  - Document how to update bookmarks/references
  - Document new structure and navigation
- [ ] Measure success metrics
  - Count broken links: target 0
  - Count orphaned guides: target 0
  - Measure archive ratio: target <10%
  - Measure navigation depth: target ≤2 hops
  - Measure compliance with 400-line threshold
  - Document in summary
- [ ] Final validation and sign-off
  - Review all success criteria
  - Confirm all phases complete
  - Archive debug artifacts
  - Update CLAUDE.md if needed

**Testing**:
```bash
# Run full test suite
bash .claude/tests/run_all_tests.sh

# Verify all success criteria
bash .claude/tests/test_refactoring_success_criteria.sh

# Generate metrics report
bash .claude/scripts/generate_docs_metrics.sh > .claude/specs/850_*/summaries/metrics.txt

# Verify commands functional
for cmd in /plan /build /debug /research /repair; do
  echo "Testing $cmd"
  # Test command can load without errors
done

# Verify 400-line compliance
find .claude/docs/ -name "*.md" ! -path "*/archive/*" -exec wc -l {} \; | awk '{if ($1 > 400) count++} END {print count " files exceed 400 lines"}'
```

**Success Criteria**:
- [ ] All plan-level success criteria met
- [ ] Comprehensive test suite passes
- [ ] Summary documentation created
- [ ] Migration guide created (if needed)
- [ ] Success metrics documented
- [ ] 400-line compliance measured and documented

**Expected Duration**: 2 hours

## Testing Strategy

### Pre-Change Validation
1. **Link Validation**: Run link checker, document baseline broken links
2. **Reference Mapping**: Map all dependencies (CLAUDE.md, commands, agents, internal)
3. **Command Testing**: Verify all commands functional with current docs
4. **Agent Testing**: Verify all agents can access referenced docs
5. **Backup**: Create full documentation backup

### Post-Change Validation (Per Phase)
1. **Link Validation**: All links resolve (0 broken links)
2. **CLAUDE.md Validation**: All 17 referenced files accessible
3. **Command Integration**: Commands still functional
4. **Agent Integration**: Agents can access needed docs
5. **Navigation Testing**: User can navigate from README to any topic
6. **Regression Testing**: Existing test suite passes

### Automated Test Suite
```bash
# .claude/tests/test_docs_validation_suite.sh
test_all_claude_md_references()     # Verify CLAUDE.md links
test_all_internal_links()           # Verify markdown links
test_command_doc_references()       # Verify command → doc links
test_agent_doc_references()         # Verify agent → doc links
test_no_orphaned_files()            # Verify all docs referenced
test_archive_boundary()             # Verify archive not in active refs
test_split_file_pattern()           # Verify consistent split pattern
test_navigation_depth()             # Verify ≤2 hops from README
```

### Integration Testing
- Test each command (`/plan`, `/build`, `/debug`, `/research`, `/repair`) with refactored docs
- Test each agent (plan-architect, research-specialist, etc.) can access references
- Verify CLAUDE.md sections resolve correctly
- Verify all `[Used by: ...]` metadata accurate

## Documentation Requirements

### Files to Create
- `.claude/tests/test_docs_links.sh` - Link validation script
- `.claude/tests/test_docs_validation_suite.sh` - Comprehensive validation suite
- `.claude/specs/850_*/debug/broken_links_inventory.md` - Broken links inventory
- `.claude/specs/850_*/debug/reference_map.json` - Reference dependency map
- `.claude/specs/850_*/summaries/001_refactoring_summary.md` - Refactoring summary
- `.claude/docs/CONTRIBUTING.md` - Documentation standards and patterns (or section in README.md)

### Files to Update
- `.claude/docs/README.md` - Fix broken links, modularize structure
- `.claude/docs/concepts/hierarchical-agents.md` - Remove legacy content, create clean index
- `.claude/docs/architecture/state-*-orchestration-overview.md` - Resolve duplication
- `.claude/docs/concepts/directory-protocols.md` - Standardize split pattern
- `.claude/docs/workflows/orchestration-guide.md` - Standardize split pattern
- `.claude/docs/archive/README.md` - Document retention policy
- Multiple files with path references (update broken links)

### Files to Archive
- `.claude/docs/guides/commands/document-command-guide.md` (if command abandoned)
- `.claude/docs/guides/commands/test-command-guide.md` (if command abandoned)
- `.claude/docs/archive/development-philosophy.md` (if fully consolidated)
- `.claude/docs/archive/timeless_writing_guide.md` (if fully consolidated)
- `.claude/docs/archive/topic_based_organization.md` (if fully consolidated)
- `.claude/docs/archive/artifact_organization.md` (if fully consolidated)

### Files to Create (Redirects)
- `.claude/docs/reference/command-reference.md` (redirect stub)
- `.claude/docs/reference/agent-reference.md` (redirect stub)
- `.claude/docs/reference/orchestration-reference.md` (redirect stub)

## Dependencies

### External Dependencies
- Bash 4.0+ (for test scripts)
- Standard Unix tools (grep, find, sed, awk)
- Git (for backup and version control)

### Internal Dependencies (Critical)
- CLAUDE.md must reference correct paths (17 references)
- Commands must be able to access documentation
- Agents must be able to access documentation
- All internal cross-references must remain functional

### Documentation Dependencies
- Diataxis framework knowledge (concepts, guides, reference, tutorials)
- Markdown link syntax and resolution
- Project directory structure conventions
- Split file pattern conventions

## Risk Assessment

### High Risk
- **CLAUDE.md Reference Breakage**: Could break all commands/agents
  - Mitigation: Pre-validate, test thoroughly, update atomically
- **Content Loss During Consolidation**: Could lose unique information
  - Mitigation: Compare carefully, backup before changes, verify content

### Medium Risk
- **Broken Links After Path Changes**: Could disrupt navigation
  - Mitigation: Use redirects, validate thoroughly, update references atomically
- **Orphaned Guide Resolution**: Might archive needed documentation
  - Mitigation: Verify command status carefully, check specs/TODO/roadmap

### Low Risk
- **Link Validation Script**: New infrastructure, limited impact
  - Mitigation: Test thoroughly, ensure no false positives
- **README Modularization**: Additive change, main README remains
  - Mitigation: Ensure subdirectory READMEs fully functional

## Notes

**Complexity Calculation**:
```
Base (refactor): 5
Tasks: 52 / 2 = 26
Files: 30 * 3 = 90
Integrations: 5 * 5 = 25
Total: 5 + 26 + 90 + 25 = 146.0 (Tier 2: Phase directory recommended)
```

**Progressive Planning**: This is Level 0 (single file). Given the high complexity score (146.0), consider using `/expand` during implementation if phases become too complex or require parallel execution.

**Plan Revision Rationale**: This plan was revised based on research report findings that identified:
1. Split pattern cleanup as PRIMARY objective (3,500 lines of duplicate content)
2. Broken link scope 6x larger than estimated (49 references in README.md alone)
3. CLAUDE.md reference updates as critical atomic operations
4. 400-line threshold as established standard requiring documentation
5. Need for phase reordering to establish clean authoritative files before fixing cross-references

**Phase Dependencies**: Phases are designed to be executed sequentially with clear dependencies:
- Phase 1 (validation) establishes baseline
- Phase 2 (split cleanup) completes existing implementation and creates clean authoritative files
- Phase 3 (broken links) fixes references to now-stable targets
- Phase 4 (remaining consolidation) handles directory-protocols and archive
- Phase 5 (structural) optimizes for maintainability with documented standards
- Phase 6 (verification) ensures comprehensive success

**Backward Compatibility**: Critical requirement - all CLAUDE.md references and existing links must remain functional. Use redirects and stubs to maintain compatibility during transition. Phase 2 includes explicit CLAUDE.md update verification.

**Archive Policy**: Establish clear retention policy (keep last 12 months, migration guides, unique content). Document in archive/README.md for future maintainers.

**Validation First**: Establishing validation infrastructure in Phase 1 enables safe refactoring in subsequent phases by providing continuous feedback on link integrity.

**400-Line Threshold**: Research confirms 400-line threshold is well-established standard (documented in code-standards.md). Current compliance: 69.6% (151/217 files). Phase 5 will document this threshold explicitly in style guide for future consistency.
