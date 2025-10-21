# .claude/docs/ Refactor Implementation Plan

## Metadata
- **Date**: 2025-10-21
- **Feature**: Refactor .claude/docs/ directory for improved manageability and usability
- **Scope**: Consolidate redundant documentation, improve CLAUDE.md integration, enhance discoverability
- **Estimated Phases**: 7
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (based on orchestrate research findings)
- **Target Outcome**: Consolidate redundant content, improve essential documentation discoverability via CLAUDE.md

## Overview

The `.claude/docs/` directory has grown to 65 files (1.3MB) with significant redundancy and poor discoverability. This refactor will consolidate overlapping content, improve CLAUDE.md integration, and create a unified navigation experience for agents working on `.claude/` refactoring.

### Current State
- **65 files** organized using Diataxis framework (concepts/, guides/, reference/, workflows/, examples/, troubleshooting/, archive/)
- **Guides bloated**: 22 files (34%) with 40-70% content overlap between pairs
- **Poor command integration**: Only 3 docs files referenced by commands (78% never used)
- **Low discoverability**: 26% (17/65) files referenced in CLAUDE.md
- **Significant duplication**: 5 migration guides (84K), overlapping command/agent authoring guides

### Target State
- **Consolidated content** with clear ownership and minimal redundancy
- **Merged overlapping guides** into comprehensive development documentation
- **Enhanced README.md**: Single-source navigation for agents working on .claude/ refactoring
- **Selective CLAUDE.md references**: Only essential documentation for navigation to further details
- **Clear Diataxis categorization**: Patterns catalog as authoritative source

## Success Criteria
- [ ] Redundant content consolidated where overlap exceeds 40%
- [ ] README.md serves as comprehensive navigation for agents working on .claude/ refactoring
- [ ] All existing CLAUDE.md references preserved and functional
- [ ] Essential documentation referenced in CLAUDE.md to enable navigation to further details
- [ ] Obsolete archive files removed
- [ ] Examples relocated inline to relevant guides where they improve clarity
- [ ] Patterns catalog established as single source of truth with cross-references from guides
- [ ] All internal documentation links functional (no broken references)
- [ ] All tests pass (documentation integrity validation)

## Technical Design

### Content Consolidation Strategy

**Merges (8 files → 4 files)**:
1. `creating-commands.md` + `command-authoring-guide.md` → `command-development-guide.md`
2. `creating-agents.md` + `agent-authoring-guide.md` → `agent-development-guide.md`
3. `hierarchical_agents.md` + `hierarchical-agent-workflow.md` → Enhanced `hierarchical_agents.md` (concepts/)
4. 5 migration guides → 2 consolidated guides:
   - `execution-enforcement-guide.md` (patterns + migration process)
   - `migration-testing.md` (testing/validation)

**Archive Pruning (2 files removed)**:
- `archive/specs_migration_guide.md` (migration complete, historical only)
- `archive/architecture.md` (Phase 7 specific, superseded by current concepts/)

**Example Relocation (3 files → inline)**:
- `examples/correct-agent-invocation.md` → `command-development-guide.md`
- `examples/behavioral-injection-workflow.md` → `workflows/orchestration-guide.md`
- `examples/reference-implementations.md` → `agent-development-guide.md`

### CLAUDE.md Enhancement Strategy

**Selective Essential References**:
Focus on documentation that enables agents to navigate to further details without cluttering CLAUDE.md.

- **Reference main index**: Link to `.claude/docs/README.md` as single navigation point
- **Quick Reference section**: Add `command-reference.md`, `agent-reference.md` for quick lookups
- **Essential guides only**: Reference `command-development-guide.md`, `agent-development-guide.md` for common workflows
- **Preserve existing references**: Maintain all current 17 references (patterns, concepts, workflows)

### README.md Navigation Enhancement

**Unified Navigation Structure**:
```markdown
## Quick Navigation for Agents

### Working on Commands?
→ Start: guides/command-development-guide.md
→ Patterns: concepts/patterns/behavioral-injection.md
→ Reference: reference/command-reference.md

### Working on Agents?
→ Start: guides/agent-development-guide.md
→ Architecture: concepts/hierarchical_agents.md
→ Reference: reference/agent-reference.md

### Refactoring .claude/?
→ Standards: reference/command_architecture_standards.md
→ Migration: guides/execution-enforcement-guide.md
→ Testing: guides/testing-patterns.md
```

### Content Ownership Model

**Single Source of Truth**:
- **Patterns**: `concepts/patterns/` catalog is authoritative
- **Command syntax**: `reference/command-reference.md` is authoritative
- **Agent syntax**: `reference/agent-reference.md` is authoritative
- **Architecture**: `concepts/hierarchical_agents.md` is authoritative

**Cross-Reference Pattern**:
```markdown
<!-- In guides/command-development-guide.md -->
For behavioral injection pattern details, see [Behavioral Injection](../concepts/patterns/behavioral-injection.md).

<!-- NOT: Duplicate the pattern explanation -->
```

## Implementation Phases

### Phase 1: Preparation and Backup [COMPLETED]
**Objective**: Create safety checkpoint before refactoring
**Complexity**: Low
**Dependencies**: None

Tasks:
- [x] Create backup of entire `.claude/docs/` directory to `.claude/docs-backup-082/`
- [x] Verify backup completeness (65 files, 1.4MB)
- [x] Create refactor working branch: `git checkout -b refactor/082-docs-consolidation` (using existing spec_org branch)
- [x] Document current CLAUDE.md references for preservation check (15 references documented)

Testing:
```bash
# Verify backup
diff -r .claude/docs/ .claude/docs-backup-082/
echo "Exit code should be 0: $?"

# Verify branch
git branch --show-current
```

**Expected Output**: Clean backup, new branch created, baseline documented

---

### Phase 2: Content Consolidation - Command and Agent Guides [COMPLETED]
**Objective**: Merge overlapping command and agent authoring guides
**Complexity**: Medium
**Dependencies**: Phase 1

Tasks:
- [x] Read `creating-commands.md` and `command-authoring-guide.md` in full
- [x] Identify unique content in each file (40-50% overlap)
- [x] Create consolidated `command-development-guide.md` with structure:
  - Overview (from creating-commands.md)
  - Behavioral injection section (from command-authoring-guide.md)
  - Agent invocation patterns (merged from both)
  - Testing and validation (merged from both)
  - Examples inline (from examples/correct-agent-invocation.md)
- [x] Read `creating-agents.md` and `agent-authoring-guide.md` in full
- [x] Create consolidated `agent-development-guide.md` with structure:
  - Agent file format (from creating-agents.md)
  - Responsibilities and boundaries (merged from both)
  - Integration patterns (from agent-authoring-guide.md)
  - Examples inline (from examples/reference-implementations.md)
- [x] Update `guides/README.md` to reflect new file names
- [x] Add cross-references to patterns catalog where applicable
- [x] Remove old files: `creating-commands.md`, `command-authoring-guide.md`, `creating-agents.md`, `agent-authoring-guide.md`
- [x] Remove relocated examples: `examples/correct-agent-invocation.md`, `examples/reference-implementations.md`

Testing:
```bash
# Verify new files exist
ls -lh .claude/docs/guides/command-development-guide.md
ls -lh .claude/docs/guides/agent-development-guide.md

# Verify old files removed
! ls .claude/docs/guides/creating-commands.md 2>/dev/null
! ls .claude/docs/guides/command-authoring-guide.md 2>/dev/null
! ls .claude/docs/guides/creating-agents.md 2>/dev/null
! ls .claude/docs/guides/agent-authoring-guide.md 2>/dev/null

# Verify examples relocated
! ls .claude/docs/examples/correct-agent-invocation.md 2>/dev/null
! ls .claude/docs/examples/reference-implementations.md 2>/dev/null

# Track file count
find .claude/docs/guides/ -name '*.md' | wc -l
```

**Expected Output**: 2 comprehensive development guides, 4 old guide files removed, 2 examples relocated

---

### Phase 3: Content Consolidation - Migration Guides
**Objective**: Consolidate 5 migration guides into 2 focused guides
**Complexity**: High
**Dependencies**: Phase 2

Tasks:
- [ ] Read all 5 migration guides:
  - `execution-enforcement-migration-guide.md` (33K)
  - `enforcement-patterns.md` (19K)
  - `migration-testing.md` (14K)
  - `migration-validation.md` (12K)
  - `audit-execution-enforcement.md` (6.2K)
- [ ] Extract unique content from each guide (identify 60% overlap on enforcement patterns)
- [ ] Create `execution-enforcement-guide.md` (target 40K) with structure:
  - Standards 0 and 0.5 overview
  - Enforcement patterns (from enforcement-patterns.md)
  - Migration process (from execution-enforcement-migration-guide.md)
  - Validation techniques (from migration-validation.md)
  - Audit script usage (from audit-execution-enforcement.md)
- [ ] Update existing `migration-testing.md` to focus on testing only:
  - Remove duplicated enforcement pattern explanations
  - Add cross-references to execution-enforcement-guide.md
  - Keep testing procedures and validation checks
- [ ] Remove consolidated files:
  - `execution-enforcement-migration-guide.md`
  - `enforcement-patterns.md`
  - `migration-validation.md` (content merged)
  - `audit-execution-enforcement.md`
- [ ] Update `guides/README.md` to reflect consolidation

Testing:
```bash
# Verify new consolidated guide
ls -lh .claude/docs/guides/execution-enforcement-guide.md

# Verify old files removed
! ls .claude/docs/guides/execution-enforcement-migration-guide.md 2>/dev/null
! ls .claude/docs/guides/enforcement-patterns.md 2>/dev/null
! ls .claude/docs/guides/migration-validation.md 2>/dev/null
! ls .claude/docs/guides/audit-execution-enforcement.md 2>/dev/null

# Track content size
find .claude/docs/guides/ -name '*.md' -exec wc -c {} + | tail -1
```

**Expected Output**: 1 comprehensive enforcement guide, updated testing guide, 4 migration files removed

---

### Phase 4: Hierarchical Agents Consolidation
**Objective**: Merge hierarchical_agents.md with hierarchical-agent-workflow.md
**Complexity**: Medium
**Dependencies**: Phase 3

Tasks:
- [ ] Read `concepts/hierarchical_agents.md` (50K, architectural)
- [ ] Read `workflows/hierarchical-agent-workflow.md` (36K, tutorial)
- [ ] Identify 70% overlap on metadata extraction, forward message pattern
- [ ] Enhance `concepts/hierarchical_agents.md` with:
  - Keep architectural content (first)
  - Add "Tutorial Walkthrough" section at end (from workflow file)
  - Add inline examples from workflow file
  - Preserve all cross-references
- [ ] Update `concepts/README.md` to note tutorial section
- [ ] Update `workflows/README.md` to redirect to concepts/hierarchical_agents.md tutorial section
- [ ] Remove `workflows/hierarchical-agent-workflow.md`
- [ ] Update any cross-references in other files

Testing:
```bash
# Verify enhanced concepts file
ls -lh .claude/docs/concepts/hierarchical_agents.md
grep -i "tutorial" .claude/docs/concepts/hierarchical_agents.md

# Verify workflow file removed
! ls .claude/docs/workflows/hierarchical-agent-workflow.md 2>/dev/null

# Track workflows directory
find .claude/docs/workflows/ -name '*.md' | wc -l
```

**Expected Output**: Enhanced hierarchical_agents.md with tutorial section, 1 workflow file removed

---

### Phase 5: Archive Cleanup and Examples Relocation
**Objective**: Remove obsolete archive files and relocate remaining example inline
**Complexity**: Low
**Dependencies**: Phase 4

Tasks:
- [ ] Remove obsolete archive files:
  - `archive/specs_migration_guide.md` (topic-based structure now standard)
  - `archive/architecture.md` (Phase 7 specific, superseded)
- [ ] Update `archive/README.md` to note removals
- [ ] Relocate final example inline:
  - Read `examples/behavioral-injection-workflow.md` (13K)
  - Add content to `workflows/orchestration-guide.md` as "Behavioral Injection Example" section
  - Remove `examples/behavioral-injection-workflow.md`
- [ ] Remove empty `examples/` directory if no files remain
- [ ] Update main `README.md` to reflect archive and examples changes

Testing:
```bash
# Verify archive removals
! ls .claude/docs/archive/specs_migration_guide.md 2>/dev/null
! ls .claude/docs/archive/architecture.md 2>/dev/null

# Verify example relocated
grep -i "behavioral injection example" .claude/docs/workflows/orchestration-guide.md
! ls .claude/docs/examples/behavioral-injection-workflow.md 2>/dev/null

# Verify examples directory status
ls .claude/docs/examples/ 2>/dev/null || echo "Directory removed or empty"

# Track total file count
find .claude/docs/ -name '*.md' -type f | wc -l
```

**Expected Output**: 2 archive files removed, 1 example relocated, examples/ directory removed or empty

---

### Phase 6: README.md and Cross-Reference Enhancement
**Objective**: Create unified navigation README and establish cross-reference network
**Complexity**: Medium
**Dependencies**: Phase 5

Tasks:
- [ ] Update `.claude/docs/README.md` with unified navigation:
  - Add "Quick Navigation for Agents" section
  - Create workflow-specific navigation (commands, agents, refactoring)
  - Update file counts to reflect consolidation
  - Add content ownership section (patterns as authoritative)
- [ ] Review all guides for pattern duplication
- [ ] Replace duplicated pattern explanations with cross-references:
  - Pattern: `See [Pattern Name](../concepts/patterns/pattern-name.md)`
  - Not: Full pattern explanation
- [ ] Update `concepts/patterns/README.md` to emphasize authoritative status
- [ ] Add "Cross-References" section to consolidated guides listing related docs
- [ ] Validate all internal links are functional

Testing:
```bash
# Verify README enhancements
grep -i "quick navigation for agents" .claude/docs/README.md
grep -i "content ownership" .claude/docs/README.md

# Check for cross-reference pattern adoption
grep -r "See \[.*\](.*patterns/.*)" .claude/docs/guides/ | wc -l

# Validate links (basic check)
find .claude/docs/ -name '*.md' -exec grep -l '\[.*\](.*\.md)' {} \; | wc -l
```

**Expected Output**: Enhanced README with agent navigation, cross-reference network established with patterns catalog

---

### Phase 7: CLAUDE.md Integration - Selective Essential References
**Objective**: Add only essential documentation references to enable navigation without clutter
**Complexity**: Low
**Dependencies**: Phase 6

Tasks:
- [ ] Read current CLAUDE.md documentation sections
- [ ] Add reference to main documentation index:
  - Add prominent link to `.claude/docs/README.md` in appropriate section
  - Position as primary navigation point for detailed documentation
- [ ] Enhance `quick_reference` section with essential lookups:
  - Add: `reference/command-reference.md` (command catalog)
  - Add: `reference/agent-reference.md` (agent catalog)
- [ ] Add essential development guides to appropriate sections:
  - `command-development-guide.md` (consolidated command authoring)
  - `agent-development-guide.md` (consolidated agent authoring)
- [ ] Preserve all 17 existing references (verify none broken)
- [ ] Verify links functional and appropriately placed

Testing:
```bash
# Verify main docs index referenced
grep -i '\.claude/docs/README\.md' CLAUDE.md

# Verify essential references added
grep -i 'command-reference\.md' CLAUDE.md
grep -i 'agent-reference\.md' CLAUDE.md
grep -i 'command-development-guide\.md' CLAUDE.md
grep -i 'agent-development-guide\.md' CLAUDE.md

# Verify old references preserved
grep -o '\.claude/docs/[^)]*\.md' CLAUDE.md | sort -u > /tmp/claude-refs-after.txt
# Manual verification that original 17 references still present

# Count total references (should be modest increase, not excessive)
grep -o '\.claude/docs/[^)]*\.md' CLAUDE.md | sort -u | wc -l
```

**Expected Output**: CLAUDE.md with essential references (main index + key lookups + development guides), all old references preserved, no clutter

---

## Testing Strategy

### Documentation Integrity Tests
```bash
# 1. File count tracking
find .claude/docs/ -name '*.md' -type f | wc -l
# Note: Count for comparison (started at 65)

# 2. Content size tracking
du -sh .claude/docs/
# Note: Size for comparison (started at 1.3MB)

# 3. Link validation (all internal links functional)
find .claude/docs/ -name '*.md' -exec grep -H '\[.*\](.*\.md)' {} \; > /tmp/links.txt
# Manual review or script to check each link target exists - must have 0 broken links

# 4. CLAUDE.md reference validation
grep -o '\.claude/docs/[^)]*\.md' CLAUDE.md | sort -u | wc -l
# Note: Count for comparison (started at 17, should be modest increase)

# 5. Guides directory validation
find .claude/docs/guides/ -name '*.md' | wc -l
# Note: Count for comparison (started at 22)

# 6. Archive directory validation
find .claude/docs/archive/ -name '*.md' | wc -l
# Note: Count for comparison (started at 9)

# 7. Examples directory status
! ls .claude/docs/examples/ 2>/dev/null
# Expected: Directory removed or empty after inline relocation

# 8. Cross-reference pattern adoption
grep -r "See \[.*\](.*patterns/.*)" .claude/docs/guides/ | wc -l
# Expected: Multiple cross-references to patterns catalog
```

### Regression Prevention Tests
```bash
# 9. Preserve all existing CLAUDE.md doc references
# Compare before/after lists
grep -o '\.claude/docs/[^)]*\.md' CLAUDE.md | sort > /tmp/claude-refs-after.txt
# Verify original 17 references all present in new 39

# 10. No broken relative links
# Use markdown link checker or manual validation
find .claude/docs/ -name '*.md' -exec markdown-link-check {} \;

# 11. All README files updated
find .claude/docs/ -name 'README.md' -exec grep -l "updated.*2025-10-21" {} \;
# Expected: All category README files have current date
```

### Content Quality Tests
```bash
# 12. Pattern catalog referenced as authoritative
grep -r "authoritative" .claude/docs/README.md
grep -r "single source of truth" .claude/docs/README.md

# 13. Unified navigation present
grep -i "quick navigation for agents" .claude/docs/README.md

# 14. No duplicate pattern explanations in guides
# Manual review: Check that guides reference patterns/, not duplicate content

# 15. All consolidation targets removed
! ls .claude/docs/guides/creating-commands.md 2>/dev/null
! ls .claude/docs/guides/command-authoring-guide.md 2>/dev/null
! ls .claude/docs/guides/creating-agents.md 2>/dev/null
! ls .claude/docs/guides/agent-authoring-guide.md 2>/dev/null
```

## Documentation Requirements

### Files to Update
- `.claude/docs/README.md` - Enhanced navigation, content ownership, updated file counts
- `.claude/docs/guides/README.md` - Updated guide list, merged files noted
- `.claude/docs/concepts/README.md` - Tutorial section note for hierarchical_agents.md
- `.claude/docs/workflows/README.md` - Redirect to hierarchical_agents.md tutorial
- `.claude/docs/archive/README.md` - Note removed obsolete files
- `.claude/docs/concepts/patterns/README.md` - Emphasize authoritative status
- `CLAUDE.md` - New sections (troubleshooting, learning_resources), enhanced existing sections

### Files to Create
- `.claude/docs/guides/command-development-guide.md` - Consolidated command authoring
- `.claude/docs/guides/agent-development-guide.md` - Consolidated agent authoring
- `.claude/docs/guides/execution-enforcement-guide.md` - Consolidated migration/enforcement guide

### Files to Remove
**Guides (6 files)**:
- `creating-commands.md` (merged → command-development-guide.md)
- `command-authoring-guide.md` (merged → command-development-guide.md)
- `creating-agents.md` (merged → agent-development-guide.md)
- `agent-authoring-guide.md` (merged → agent-development-guide.md)
- `execution-enforcement-migration-guide.md` (merged → execution-enforcement-guide.md)
- `enforcement-patterns.md` (merged → execution-enforcement-guide.md)
- `migration-validation.md` (merged → execution-enforcement-guide.md)
- `audit-execution-enforcement.md` (merged → execution-enforcement-guide.md)

**Workflows (1 file)**:
- `hierarchical-agent-workflow.md` (merged → concepts/hierarchical_agents.md)

**Examples (3 files)**:
- `correct-agent-invocation.md` (relocated inline → command-development-guide.md)
- `reference-implementations.md` (relocated inline → agent-development-guide.md)
- `behavioral-injection-workflow.md` (relocated inline → workflows/orchestration-guide.md)

**Archive (2 files)**:
- `specs_migration_guide.md` (obsolete)
- `architecture.md` (superseded)

**Total Removals**: 17 files

### Files to Enhance
- `concepts/hierarchical_agents.md` - Add tutorial walkthrough section
- `workflows/orchestration-guide.md` - Add behavioral injection example section
- `migration-testing.md` - Remove duplication, add cross-references

## Dependencies

### Internal Dependencies
- All phases build sequentially (each depends on previous)
- Phase 6 (cross-references) requires Phases 2-5 consolidation complete
- Phase 7 (CLAUDE.md) requires Phase 6 navigation structure in place

### External Dependencies
- None (internal refactor only)

### Prerequisite Knowledge
- Diataxis framework organization (reference/guides/concepts/workflows)
- Current .claude/docs/ file inventory and categorization
- Behavioral injection pattern and patterns catalog
- CLAUDE.md section structure and metadata

## Risk Assessment

### High Risk Areas
1. **CLAUDE.md reference preservation**: Breaking existing references could disrupt command/agent workflows
   - **Mitigation**: Phase 1 documents baseline, Phase 7 validates all old references preserved
2. **Content loss during consolidation**: Merging 8 files risks losing unique content
   - **Mitigation**: Phase 1 creates full backup, each merge phase requires reading both files in full
3. **Broken internal links**: Consolidation could break cross-references in other files
   - **Mitigation**: Phase 6 validates all links, testing strategy includes link checker

### Medium Risk Areas
1. **Over-consolidation**: Merging too aggressively could create guides that are too large
   - **Mitigation**: Target sizes specified (40K max), clear section boundaries maintained
2. **Navigation confusion**: Changing file names could confuse users familiar with old structure
   - **Mitigation**: Phase 6 creates comprehensive navigation, READMEs note changes

### Low Risk Areas
1. **Archive cleanup**: Removing obsolete files is low-risk (historical only)
2. **Example relocation**: Moving examples inline improves discoverability
3. **File count reduction**: Fewer files generally improves maintainability

## Rollback Plan

If issues arise during refactoring:

1. **Full Rollback**:
   ```bash
   # Restore from backup
   rm -rf .claude/docs/
   cp -r .claude/docs-backup-082/ .claude/docs/
   git checkout main
   git branch -D refactor/082-docs-consolidation
   ```

2. **Partial Rollback** (by phase):
   ```bash
   # Revert specific phase
   git log --oneline  # Find commit before phase
   git revert <commit-hash>
   ```

3. **CLAUDE.md Restoration**:
   ```bash
   # If CLAUDE.md changes cause issues
   git checkout HEAD~1 CLAUDE.md
   ```

## Notes

### Content Ownership Principles
- **Patterns catalog** (`concepts/patterns/`) is single source of truth for architectural patterns
- **Reference files** (`reference/`) are authoritative for syntax and schemas
- **Guides** should cross-reference authoritative sources, not duplicate content
- **Workflows** provide step-by-step tutorials linking to concepts and guides

### Consolidation Guidelines
- Merge files only when overlap >40%
- Preserve all unique content
- Create clear section boundaries in consolidated files
- Add comprehensive table of contents to large files
- Cross-reference related documentation

### CLAUDE.md Integration Strategy
- Prioritize frequently-used documentation (workflows, troubleshooting, quick references)
- Add new sections for underrepresented categories (troubleshooting, learning resources)
- Use `[Used by: commands]` metadata to indicate discoverability
- Maintain existing section structure (don't break command parsing)

### Future Considerations
- Monitor file sizes post-refactor (flag any files >60K for potential splitting)
- Track CLAUDE.md reference usage to identify underutilized docs
- Consider periodic review of archive/ for further cleanup
- Evaluate command/agent usage patterns to optimize discoverability further

---

## Revision History

### 2025-10-21 - Revision 1
**Changes**:
- Removed explicit numeric targets from Success Criteria (file counts, size percentages, discoverability percentages)
- Changed CLAUDE.md integration approach from comprehensive (39 files, 60%+ coverage) to selective essential references
- Simplified Phase 7 to focus on adding main docs index reference plus key lookups only
- Updated all testing sections to use "Note: Count for comparison" instead of specific target numbers

**Reason**:
- Allow improvements to proceed as far as appropriate without artificial numeric constraints
- Avoid cluttering CLAUDE.md with excessive references; focus on essential navigation aids
- Enable flexible optimization based on actual consolidation results rather than predetermined targets

**Modified Phases**: Phase 7 (CLAUDE.md Integration), Success Criteria, Testing Strategy

---

**Next Steps**: Review this plan, then execute with `/implement /home/benjamin/.config/.claude/specs/plans/082_claude_docs_refactor.md`
