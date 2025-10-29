# .claude/docs/ Documentation Refactor Implementation Plan

## Metadata
- **Date**: 2025-10-28
- **Feature**: Documentation consolidation and clarity improvements for .claude/docs/
- **Scope**: Refactor 80 markdown files to eliminate 30-40% redundancy, improve usability, and align with Spec 508 best practices
- **Estimated Phases**: 7
- **Estimated Hours**: 24-28
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 58.0
- **Research Reports**:
  - [Current .claude/docs/ Structure Analysis](../reports/001_current_claude_docs_structure_analysis.md)
  - [Spec 508 Alignment Gap Analysis](../reports/002_spec_508_alignment_gap_analysis.md)
  - [Documentation Clarity and Usability Improvements](../reports/003_documentation_clarity_usability_improvements.md)
  - [Consolidation and Redundancy Elimination](../reports/004_consolidation_redundancy_elimination.md)

## Overview

This plan addresses comprehensive refactoring of the `.claude/docs/` directory to reduce redundancy (30-40% reduction target), improve usability (add quick-starts, examples, decision trees), and align with Spec 508 unified orchestration best practices. The documentation system currently contains 80 markdown files with significant overlap in troubleshooting (85%), orchestration (60%), and agent development (65%) content. The refactor will consolidate redundant content, extract missing Spec 508 patterns, enhance navigation, and maintain production-ready quality throughout.

## Research Summary

Analysis of four comprehensive research reports reveals:

**Current State** (Report 001):
- 80 files totaling 1.8MB across 9 Diataxis categories
- Strong architectural organization but high verbosity (10 files >1,000 lines)
- Excellent pattern coverage (8 documented patterns) but scattered guidance
- Only 30/80 files (37.5%) contain practical examples

**Spec 508 Alignment Gaps** (Report 002):
- Missing unified orchestration best practices guide consolidating 7-phase workflow
- Workflow scope detection pattern exists (library) but lacks documentation
- Five-layer context strategy documented separately, not synthesized
- Phase 0 optimization scattered across 3+ documents (85% token reduction metric buried)

**Clarity and Usability Issues** (Report 003):
- Excessive verbosity: 10 files exceed 1,000 lines (cognitive burden)
- Unclear entry points: 3+ navigation schemes create choice paralysis
- Insufficient quick-starts: Only 7/17 guides have "Getting Started" sections
- Missing common-case examples: Documentation emphasizes complex multi-agent patterns

**Redundancy Analysis** (Report 004):
- 85% content overlap across 4 troubleshooting guides (agent delegation)
- 60% overlap across 5 orchestration documentation files
- 65% overlap between agent development guides
- 8 files can be eliminated entirely through consolidation

**Recommended Approach**:
1. Consolidate high-overlap content (troubleshooting, orchestration, agent development)
2. Extract Spec 508 unified framework into dedicated guides
3. Add quick-start sections and common-case examples throughout
4. Improve navigation with breadcrumbs and "I Want To..." sections
5. Maintain production-ready quality while reducing cognitive burden

## Success Criteria

- [ ] Documentation size reduced by 30-40% (26,000-28,000 lines from ~40,000)
- [ ] 8 redundant files eliminated through consolidation
- [ ] All guides contain quick-start sections with working examples
- [ ] Unified orchestration best practices guide created (Spec 508 alignment)
- [ ] Workflow scope detection pattern documented
- [ ] Context budget management tutorial created
- [ ] Phase 0 optimization guide consolidated
- [ ] Navigation improved with breadcrumbs and task-based entry points
- [ ] Zero broken cross-references after consolidation
- [ ] All archived files contain redirect READMEs to new locations

## Technical Design

### Consolidation Strategy

**Priority 1 Merges** (Week 1):
1. **Troubleshooting Unification**: Merge 3 delegation guides → `agent-delegation-troubleshooting.md` (1,380 → 600 lines, 57% reduction)
2. **Orchestration Reference**: Consolidate 3 files → `orchestration-reference.md` (3,554 → 1,800 lines, 49% reduction)
3. **Agent Development**: Merge using-agents.md into agent-development-guide.md (2,019 → 1,500 lines, 26% reduction)

**Priority 2 Extractions** (Week 2):
1. **Orchestration Best Practices Guide**: NEW file synthesizing Spec 508 7-phase workflow (~1,200 lines)
2. **Workflow Scope Detection Pattern**: NEW file documenting workflow-detection.sh pattern (~600 lines)
3. **Context Budget Management Tutorial**: NEW file with layered architecture (~800 lines)
4. **Phase 0 Optimization Guide**: NEW file consolidating unified library breakthrough (~700 lines)

**Priority 3 Enhancements** (Week 3):
1. Add quick-start sections to all guides (50-150 lines per guide)
2. Add common-case examples to patterns catalog
3. Create decision trees for quick-reference/
4. Add breadcrumb navigation to major documents

### File Organization

**Files to Eliminate** (archive with redirects):
- `/troubleshooting/agent-delegation-failure.md` → Merged
- `/troubleshooting/agent-delegation-issues.md` → Merged
- `/troubleshooting/command-not-delegating-to-agents.md` → Merged
- `/reference/orchestration-commands-quick-reference.md` → Merged
- `/reference/orchestration-alternatives.md` → Merged
- `/reference/supervise-phases.md` → Merged into workflow-phases.md
- `/guides/using-agents.md` → Merged into agent-development-guide.md
- `/guides/command-examples.md` → Merged into command-development-guide.md

**Files to Create**:
- `/guides/orchestration-best-practices.md` - Spec 508 unified framework
- `/concepts/patterns/workflow-scope-detection.md` - Pattern documentation
- `/workflows/context-budget-management.md` - Tutorial
- `/guides/phase-0-optimization.md` - Consolidated guide
- `/troubleshooting/agent-delegation-troubleshooting.md` - Unified troubleshooting
- `/reference/orchestration-reference.md` - Consolidated reference

**Files to Significantly Update**:
- `/docs/README.md` - Add "I Want To..." quick navigation section
- `/reference/workflow-phases.md` - Absorb supervise-phases.md content
- `/guides/command-development-guide.md` - Add quick-start, absorb examples
- `/concepts/patterns/README.md` - Add pattern combinations section
- All major guides - Add quick-start sections

### Architecture Decisions

**Separation of Concerns**:
- **Reference**: Dry, factual, API-focused (orchestration-reference.md)
- **Guides**: Task-focused, how-to (orchestration-best-practices.md, phase-0-optimization.md)
- **Concepts**: Understanding-oriented (patterns remain separate)
- **Workflows**: Learning-oriented tutorials (context-budget-management.md)

**Cross-Reference Updates**:
- Automated link validation after each consolidation
- Redirect READMEs in archived files pointing to new locations
- Update all references in CLAUDE.md tagged sections

**Quality Preservation**:
- Maintain all technical accuracy during consolidation
- Preserve historical case studies (Specs 438, 495, 057)
- Keep performance metrics prominently featured
- No content loss - archive eliminated files

## Implementation Phases

### Phase 1: Troubleshooting Documentation Unification [COMPLETED]
dependencies: []

**Objective**: Consolidate 4 troubleshooting guides with 85% overlap into single unified guide with decision tree structure

**Complexity**: Medium

**Tasks**:
- [x] Create new `/troubleshooting/agent-delegation-troubleshooting.md` with decision tree structure
- [x] Extract unique content from `agent-delegation-failure.md` (root cause analysis)
- [x] Extract unique content from `agent-delegation-issues.md` (diagnostic procedures)
- [x] Extract unique content from `command-not-delegating-to-agents.md` (solution patterns)
- [x] Consolidate all bash diagnostic commands into single comprehensive set
- [x] Add "Quick Diagnosis" decision tree at top of unified guide
- [x] Update `orchestration-troubleshooting.md` to reference unified guide (not duplicate)
- [x] Create redirect READMEs in archived troubleshooting files
- [x] Update all cross-references in other documentation files
- [x] Validate no broken links with markdown link checker

**Testing**:
```bash
# Verify unified guide exists and has expected sections
test -f .claude/docs/troubleshooting/agent-delegation-troubleshooting.md
grep -q "## Quick Diagnosis" .claude/docs/troubleshooting/agent-delegation-troubleshooting.md

# Verify archived files have redirects
test -f .claude/docs/archive/troubleshooting/agent-delegation-failure.md
grep -q "See:" .claude/docs/archive/troubleshooting/agent-delegation-failure.md

# Validate links
find .claude/docs -name "*.md" -exec grep -l "agent-delegation" {} \; | xargs -I {} echo "Check: {}"
```

**Expected Duration**: 3-4 hours

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (unified guide created, redirects in place, no broken links)
- [x] Git commit created: `feat(509): Complete Phase 1 - Troubleshooting Documentation Unification`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

---

### Phase 2: Orchestration Reference Consolidation [COMPLETED]
dependencies: [1]

**Objective**: Merge 3 orchestration reference files into single authoritative source, reducing 3,554 lines to 1,800 lines (49% reduction)

**Complexity**: Medium

**Tasks**:
- [x] Create new `/reference/orchestration-reference.md` with 5 sections (quick reference, command comparison, pattern library, performance metrics, alternative patterns)
- [x] Migrate command syntax from `orchestration-commands-quick-reference.md` → Section 1
- [x] Migrate when-to-use guidance from `orchestration-alternatives.md` → Section 5
- [x] Consolidate agent invocation templates from `orchestration-patterns.md` → Section 3
- [x] Extract performance metrics from all 3 files → Section 4 (unified table)
- [x] Add table of contents to orchestration-reference.md (file will be ~1,800 lines)
- [x] Update references in `hierarchical_agents.md` to point to new unified file
- [x] Update references in all workflow guides to orchestration-reference.md
- [x] Archive eliminated files with redirect READMEs
- [x] Validate no broken cross-references

**Testing**:
```bash
# Verify new unified reference exists with all sections
test -f .claude/docs/reference/orchestration-reference.md
grep -q "## Section 1: Command Quick Reference" .claude/docs/reference/orchestration-reference.md
grep -q "## Section 5: Alternative Patterns" .claude/docs/reference/orchestration-reference.md

# Verify performance metrics table present
grep -q "40-60% time savings" .claude/docs/reference/orchestration-reference.md

# Verify archived files
test -f .claude/docs/archive/reference/orchestration-commands-quick-reference.md

# Link validation
grep -r "orchestration-commands-quick-reference" .claude/docs/ && echo "ERROR: Old links remain" || echo "PASS: Links updated"
```

**Expected Duration**: 4-5 hours

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (unified reference created, all sections present, links updated)
- [x] Git commit created: `feat(509): Complete Phase 2 - Orchestration Reference Consolidation`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

---

### Phase 3: Agent Development Guide Consolidation [COMPLETED]
dependencies: [2]

**Objective**: Merge using-agents.md into agent-development-guide.md for complete agent lifecycle coverage (create → invoke → optimize)

**Complexity**: Low

**Status**: COMPLETED - Successfully consolidated in fresh session with available context

**Tasks**:
- [x] Analyze content overlap between agent-development-guide.md and using-agents.md (65% overlap identified)
- [x] Restructure agent-development-guide.md with 4 parts: Creating Agents, Invoking Agents, Context Architecture, Advanced Patterns
- [x] Migrate invocation patterns from using-agents.md → Part 2 of agent-development-guide.md
- [x] Migrate context architecture from using-agents.md → Part 3 (consolidate duplicated 5-layer content)
- [x] Add cross-references to behavioral-injection.md pattern for advanced details
- [x] Update behavioral-injection.md to reference agent-development-guide.md for implementation (reduce duplication)
- [x] Archive using-agents.md with redirect README
- [x] Update all references from using-agents.md to agent-development-guide.md (7 files updated)
- [x] Add quick-start section to top of agent-development-guide.md (10-minute first agent example)

**Testing**:
```bash
# Verify consolidated guide has all parts
grep -q "# Part 1: Creating Agents" .claude/docs/guides/agent-development-guide.md  # PASS
grep -q "# Part 2: Invoking Agents" .claude/docs/guides/agent-development-guide.md  # PASS
grep -q "# Part 3: Context Architecture" .claude/docs/guides/agent-development-guide.md  # PASS
grep -q "# Part 4: Advanced Patterns" .claude/docs/guides/agent-development-guide.md  # PASS

# Verify quick-start section present
grep -q "## Quick Start:" .claude/docs/guides/agent-development-guide.md  # PASS

# Verify archived file
test -f .claude/docs/archive/guides/using-agents.md  # PASS

# Link validation
grep -r "using-agents.md" .claude/docs/ | grep -v archive && echo "ERROR: Old links" || echo "PASS"  # PASS
```

**Expected Duration**: 3-4 hours (Actual: ~2.5 hours)

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (4-part structure, quick-start added, links updated)
- [x] Git commit created: `feat(509): Complete Phase 3 - Agent Development Guide Consolidation`
- [x] Checkpoint saved (if complex phase) - N/A (low complexity)
- [x] Update this plan file with phase completion status

---

### Phase 4: Spec 508 Best Practices Extraction [COMPLETED]
dependencies: [2]

**Objective**: Create unified orchestration best practices guide synthesizing Spec 508 7-phase workflow with all context preservation techniques

**Complexity**: High

**Tasks**:
- [x] Create `/guides/orchestration-best-practices.md` with complete 7-phase workflow structure
- [x] Document Phase 0: Path Pre-Calculation (unified-location-detection.sh, 85% reduction, 25x speedup)
- [x] Document Phase 1: Research (behavioral injection, metadata extraction, parallel invocation)
- [x] Document Phase 2: Planning (forward message pattern, plan-architect invocation)
- [x] Document Phase 3: Implementation (wave-based execution, 40-60% savings, dependency analysis)
- [x] Document Phase 4: Testing (conditional execution based on workflow scope)
- [x] Document Phase 5: Debugging (conditional, parallel investigations)
- [x] Document Phase 6: Documentation
- [x] Document Phase 7: Summary
- [x] Add context budget management section (21% total usage target)
- [x] Add library integration checklist (8 required libraries)
- [x] Add performance metrics table (before/after comparisons)
- [x] Create workflow scope detection pattern doc at `/concepts/patterns/workflow-scope-detection.md`
- [x] Create context budget tutorial at `/workflows/context-budget-management.md`
- [x] Create Phase 0 optimization guide at `/guides/phase-0-optimization.md`
- [x] Add cross-references between all 4 new documents
- [x] Update patterns/README.md to include workflow-scope-detection pattern
- [x] Update main docs/README.md with links to new guides

**Testing**:
```bash
# Verify all 4 new files created
test -f .claude/docs/guides/orchestration-best-practices.md
test -f .claude/docs/concepts/patterns/workflow-scope-detection.md
test -f .claude/docs/workflows/context-budget-management.md
test -f .claude/docs/guides/phase-0-optimization.md

# Verify all 7 phases documented
for i in {0..7}; do
  grep -q "Phase $i:" .claude/docs/guides/orchestration-best-practices.md || echo "Missing Phase $i"
done

# Verify performance metrics present
grep -q "85% token reduction" .claude/docs/guides/phase-0-optimization.md
grep -q "40-60% time savings" .claude/docs/guides/orchestration-best-practices.md
grep -q "21% total usage" .claude/docs/workflows/context-budget-management.md

# Verify cross-references
grep -q "workflow-scope-detection.md" .claude/docs/guides/orchestration-best-practices.md
```

**Expected Duration**: 6-8 hours

**Phase 4 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (all 4 files created, 7 phases documented, metrics present)
- [ ] Git commit created: `feat(509): Complete Phase 4 - Spec 508 Best Practices Extraction`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

---

### Phase 5: Quick-Start and Example Enhancements
dependencies: [3, 4]

**Objective**: Add quick-start sections and common-case examples to all major guides, improving onboarding from hours to minutes

**Complexity**: Medium

**Tasks**:
- [ ] Add "Quick Start: Your First Command" to command-development-guide.md (50-100 lines, working hello.md example)
- [ ] Add "Quick Start: Your First Agent" to agent-development-guide.md (already added in Phase 3, verify)
- [ ] Add "I Want To..." section to main docs/README.md with 10 common tasks
- [ ] Add "Basic Examples" section to patterns/README.md with 5 common-case examples (single agent, simple verification, structured metadata)
- [ ] Create decision tree in quick-reference/command-vs-agent-flowchart.md
- [ ] Create decision tree in quick-reference/agent-selection-flowchart.md
- [ ] Create decision tree in quick-reference/error-handling-flowchart.md
- [ ] Add breadcrumb navigation to all pattern files (8 files)
- [ ] Add breadcrumb navigation to all major guides (10 files)
- [ ] Add "Common Mistakes and Solutions" section to command-development-guide.md

**Testing**:
```bash
# Verify quick-start sections present
grep -q "## Quick Start:" .claude/docs/guides/command-development-guide.md
grep -q "## I Want To" .claude/docs/README.md

# Verify decision trees created
test -f .claude/docs/quick-reference/command-vs-agent-flowchart.md
test -f .claude/docs/quick-reference/agent-selection-flowchart.md
test -f .claude/docs/quick-reference/error-handling-flowchart.md

# Verify breadcrumbs in patterns
grep -q "**Path**:" .claude/docs/concepts/patterns/behavioral-injection.md

# Verify common mistakes section
grep -q "## Common Mistakes and Solutions" .claude/docs/guides/command-development-guide.md
```

**Expected Duration**: 4-5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (quick-starts added, decision trees created, breadcrumbs present)
- [ ] Git commit created: `feat(509): Complete Phase 5 - Quick-Start and Example Enhancements`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Additional Consolidations and Cleanup
dependencies: [1, 2, 3]

**Objective**: Complete medium-priority consolidations (command development, workflow phases, performance guides)

**Complexity**: Medium

**Tasks**:
- [ ] Consolidate command-examples.md into command-development-guide.md (examples integrated throughout)
- [ ] Merge supervise-phases.md into workflow-phases.md as Section 2 subsection
- [ ] Merge execution-enforcement-guide.md and imperative-language-guide.md (50% overlap)
- [ ] Merge performance-measurement.md and efficiency-guide.md into performance-optimization.md (60% overlap)
- [ ] Add table of contents to all files >800 lines (orchestration-reference.md, command-development-guide.md, agent-development-guide.md)
- [ ] Archive all eliminated files with redirect READMEs
- [ ] Update cross-references throughout documentation
- [ ] Run comprehensive link validation across all 70+ files
- [ ] Update all README.md navigation files with new structure

**Testing**:
```bash
# Verify consolidations complete
! test -f .claude/docs/guides/command-examples.md || echo "ERROR: File should be archived"
grep -q "supervise phases" .claude/docs/reference/workflow-phases.md

# Verify TOCs added to large files
grep -q "## Table of Contents" .claude/docs/reference/orchestration-reference.md
grep -q "## Table of Contents" .claude/docs/guides/command-development-guide.md

# Comprehensive link validation
find .claude/docs -name "*.md" -type f -exec grep -H '\[.*\](.*\.md)' {} \; | \
  while IFS=: read -r file link; do
    target=$(echo "$link" | sed -n 's/.*(\(.*\.md\)).*/\1/p')
    if [ ! -f "$(dirname "$file")/$target" ] && [ ! -f ".claude/docs/$target" ]; then
      echo "ERROR: Broken link in $file: $target"
    fi
  done
```

**Expected Duration**: 4-5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (consolidations complete, TOCs added, no broken links)
- [ ] Git commit created: `feat(509): Complete Phase 6 - Additional Consolidations and Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 7: Final Validation and Documentation
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Comprehensive validation of all changes, metrics verification, and update project documentation

**Complexity**: Low

**Tasks**:
- [ ] Run final link validation across entire .claude/docs/ directory
- [ ] Verify all 8 files eliminated have redirect READMEs in archive/
- [ ] Count total documentation lines (target: 26,000-28,000 from ~40,000)
- [ ] Verify all success criteria met (30-40% reduction, quick-starts, unified guide, patterns, etc.)
- [ ] Update CLAUDE.md hierarchical_agent_architecture section with references to new guides
- [ ] Update CLAUDE.md project_commands section with orchestration-best-practices.md reference
- [ ] Create migration guide documenting all file relocations and consolidations
- [ ] Update .claude/docs/README.md with complete new structure
- [ ] Create "What's New" section in docs/README.md highlighting major changes
- [ ] Run validation scripts (validate_docs_timeless.sh, link checker)
- [ ] Create completion summary documenting metrics (reduction %, files eliminated, new files created)

**Testing**:
```bash
# Verify file count reduced
BEFORE=80
AFTER=$(find .claude/docs -name "*.md" -type f | wc -l)
[ $AFTER -lt $BEFORE ] && echo "PASS: File count reduced ($BEFORE → $AFTER)" || echo "ERROR: File count increased"

# Verify line count reduction
TOTAL_LINES=$(find .claude/docs -name "*.md" -type f -exec wc -l {} + | tail -1 | awk '{print $1}')
[ $TOTAL_LINES -lt 30000 ] && echo "PASS: Line count reduced to $TOTAL_LINES" || echo "WARNING: Line count $TOTAL_LINES"

# Verify all success criteria files exist
test -f .claude/docs/guides/orchestration-best-practices.md
test -f .claude/docs/concepts/patterns/workflow-scope-detection.md
test -f .claude/docs/workflows/context-budget-management.md
test -f .claude/docs/guides/phase-0-optimization.md
test -f .claude/docs/troubleshooting/agent-delegation-troubleshooting.md

# Verify redirect READMEs
test -f .claude/docs/archive/troubleshooting/README.md
grep -q "Files in this directory have been archived" .claude/docs/archive/troubleshooting/README.md

# Run timeless writing validation
.claude/lib/validate_docs_timeless.sh .claude/docs/
```

**Expected Duration**: 2-3 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (all validations successful, metrics met)
- [ ] Git commit created: `feat(509): Complete Phase 7 - Final Validation and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- Individual file consolidations tested in isolation
- Link validation after each merge
- Redirect README verification for each archived file

### Integration Testing
- Cross-reference validation across all documentation
- Breadcrumb navigation verification
- CLAUDE.md section updates validated

### Regression Testing
- Existing guides maintain all technical accuracy
- Historical case studies preserved (Specs 438, 495, 057)
- Performance metrics remain accurate

### Validation Tools
```bash
# Link validation
find .claude/docs -name "*.md" -exec grep -l '\[.*\](.*\.md)' {} \; | \
  xargs -I {} .claude/tests/validate_links.sh {}

# Timeless writing compliance
.claude/lib/validate_docs_timeless.sh .claude/docs/

# Line count reduction verification
find .claude/docs -name "*.md" -exec wc -l {} + | tail -1
```

### Performance Validation
- Documentation size reduced by 30-40%
- 8 files eliminated through consolidation
- All quick-start sections functional
- All decision trees render correctly

## Documentation Requirements

### Files to Create
1. `/guides/orchestration-best-practices.md` - Spec 508 unified framework (~1,200 lines)
2. `/concepts/patterns/workflow-scope-detection.md` - Pattern documentation (~600 lines)
3. `/workflows/context-budget-management.md` - Tutorial (~800 lines)
4. `/guides/phase-0-optimization.md` - Consolidated guide (~700 lines)
5. `/troubleshooting/agent-delegation-troubleshooting.md` - Unified guide (~600 lines)
6. `/reference/orchestration-reference.md` - Consolidated reference (~1,800 lines)
7. `/quick-reference/command-vs-agent-flowchart.md` - Decision tree
8. `/quick-reference/agent-selection-flowchart.md` - Decision tree
9. `/quick-reference/error-handling-flowchart.md` - Decision tree

### Files to Archive (with redirect READMEs)
1. `/troubleshooting/agent-delegation-failure.md`
2. `/troubleshooting/agent-delegation-issues.md`
3. `/troubleshooting/command-not-delegating-to-agents.md`
4. `/reference/orchestration-commands-quick-reference.md`
5. `/reference/orchestration-alternatives.md`
6. `/reference/supervise-phases.md`
7. `/guides/using-agents.md`
8. `/guides/command-examples.md`

### Files to Significantly Update
1. `/docs/README.md` - Add "I Want To..." section, update structure
2. `/reference/workflow-phases.md` - Absorb supervise-phases.md
3. `/guides/command-development-guide.md` - Add quick-start, absorb examples, add TOC
4. `/guides/agent-development-guide.md` - Add quick-start, 4-part structure
5. `/concepts/patterns/README.md` - Add pattern combinations, basic examples
6. `/CLAUDE.md` - Update references to new guides
7. All pattern files (8 files) - Add breadcrumb navigation
8. All major guides (10 files) - Add breadcrumb navigation

## Dependencies

### Internal Dependencies
- Phase 2 depends on Phase 1 (troubleshooting consolidation informs orchestration reference)
- Phase 3 depends on Phase 2 (orchestration reference completed before agent guide merge)
- Phase 4 depends on Phase 2 (orchestration reference as foundation for best practices)
- Phase 5 depends on Phases 3-4 (guides consolidated before adding quick-starts)
- Phase 6 depends on Phases 1-3 (major consolidations before cleanup)
- Phase 7 depends on all phases (final validation)

### External Dependencies
- Research reports completed (all 4 reports available)
- No code changes required (documentation-only refactor)
- Git repository for commits and archiving

### Resource Dependencies
- Write tool access for creating new files
- Edit tool access for updating existing files
- Bash tool for validation scripts
- Read tool for analyzing existing content

## Risk Mitigation

### Risk: Broken Cross-References
**Mitigation**: Link validation after each phase, comprehensive validation in Phase 7

### Risk: Content Loss During Consolidation
**Mitigation**: Archive all eliminated files, no deletion, preserve historical content

### Risk: User Confusion During Transition
**Mitigation**: Redirect READMEs in all archived files, clear "What's New" section

### Risk: Documentation Drift
**Mitigation**: Update CLAUDE.md references, validate timeless writing standards

### Risk: Incomplete Consolidation
**Mitigation**: Detailed success criteria, comprehensive testing in Phase 7
