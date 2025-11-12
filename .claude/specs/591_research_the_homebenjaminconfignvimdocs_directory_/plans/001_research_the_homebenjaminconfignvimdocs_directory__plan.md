# nvim/docs/ Directory Refactoring and Documentation Plan

## Metadata
- **Date**: 2025-11-04
- **Feature**: Refactor nvim/docs/ directory with comprehensive documentation
- **Scope**: Organize documentation files, track cross-references, create README.md, minimize repetition
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None provided (research phase incomplete)
- **Structure Level**: 0
- **Complexity Score**: 87.0

## Overview

The nvim/docs/ directory contains 17 documentation files covering installation, architecture, code standards, mappings, AI tooling, research workflows, and more. This refactoring aims to:

1. Create a comprehensive README.md that catalogs all documentation with clear descriptions
2. Identify and catalog all cross-references to these files from elsewhere in the repository (43+ files reference nvim/docs/)
3. Reorganize content to minimize repetition and improve cross-linking
4. Ensure all links are valid and use consistent path formats
5. Align documentation with project documentation standards (DOCUMENTATION_STANDARDS.md)
6. Create well-organized, navigable documentation structure with proper hierarchy

The goal is a well-documented, easily navigable docs/ directory that serves as the central knowledge hub for the Neovim configuration.

## Success Criteria

- [ ] README.md created at nvim/docs/README.md with complete file catalog
- [ ] All 17 documentation files cataloged with descriptions and purpose
- [ ] Cross-reference inventory complete (all 43+ referring files documented)
- [ ] Link validation complete (all nvim/docs/ links verified working)
- [ ] Repetitive content identified and consolidated
- [ ] Documentation follows DOCUMENTATION_STANDARDS.md requirements
- [ ] Navigation links added to all docs files (parent/child/related)
- [ ] Test validation: all links accessible, no broken references
- [ ] Git commit created documenting the refactor

## Technical Design

### Architecture

The refactoring follows a systematic approach:

1. **Inventory Phase**: Catalog existing files and their purposes
2. **Reference Analysis**: Map all cross-references from repository to docs/
3. **Content Analysis**: Identify repetitive content across files
4. **README Creation**: Create comprehensive directory index
5. **Link Enhancement**: Add navigation links and improve cross-references
6. **Validation**: Verify all links work and structure is complete

### File Organization

Current structure (17 files):
```
nvim/docs/
├── ADVANCED_SETUP.md              (6,577 bytes)
├── AI_TOOLING.md                  (21,599 bytes)
├── ARCHITECTURE.md                (17,966 bytes)
├── CLAUDE_CODE_INSTALL.md         (44,426 bytes)
├── CLAUDE_CODE_QUICK_REF.md       (5,738 bytes)
├── CODE_STANDARDS.md              (28,233 bytes)
├── DOCUMENTATION_STANDARDS.md     (15,837 bytes)
├── FORMAL_VERIFICATION.md         (11,502 bytes)
├── GLOSSARY.md                    (5,048 bytes)
├── INSTALLATION.md                (11,087 bytes)
├── JUMP_LIST_TESTING_CHECKLIST.md (6,560 bytes)
├── KEYBOARD_PROTOCOL_SETUP.md     (6,863 bytes)
├── MAPPINGS.md                    (21,449 bytes)
├── MIGRATION_GUIDE.md             (25,975 bytes)
├── NIX_WORKFLOWS.md               (10,864 bytes)
├── NOTIFICATIONS.md               (18,372 bytes)
├── RESEARCH_TOOLING.md            (14,047 bytes)
└── templates/
    └── gitignore-template
```

### Cross-Reference Patterns

Based on grep analysis, references use multiple path formats:
- Absolute paths: `/home/benjamin/.config/nvim/docs/FILE.md`
- Repository-relative: `nvim/docs/FILE.md`
- Local-relative: `docs/FILE.md`, `../../nvim/docs/FILE.md`

Files with most references to nvim/docs/:
- README.md (root) - 16+ references
- docs/README.md - 3 references
- docs/platform/*.md - 8 references (4 platform files)
- docs/common/*.md - 8 references
- .claude/README.md - 1 reference
- Various spec reports and summaries

### Content Consolidation Strategy

Key areas with potential repetition:
1. Installation prerequisites (INSTALLATION.md, ADVANCED_SETUP.md, CLAUDE_CODE_INSTALL.md)
2. Code standards (CODE_STANDARDS.md, DOCUMENTATION_STANDARDS.md, CLAUDE.md in nvim/)
3. Mapping documentation (MAPPINGS.md, individual tool docs)
4. Architecture descriptions (ARCHITECTURE.md, various plugin docs)

Strategy: Create clear primary source for each topic, cross-reference from related docs

## Implementation Phases

### Phase 1: Inventory and Analysis
dependencies: []

**Objective**: Create complete inventory of docs/ files and cross-references

**Complexity**: Low

**Tasks**:
- [x] Read all 17 documentation files to understand content and purpose (file: /home/benjamin/.config/nvim/docs/*.md)
- [x] Create structured inventory with file size, purpose, and key topics for each file
- [x] Analyze cross-reference patterns from grep results (43+ files)
- [x] Document path format inconsistencies (absolute vs relative)
- [x] Create cross-reference matrix showing which files link to which docs

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify inventory completeness
grep -r "nvim/docs/" /home/benjamin/.config --include="*.md" | wc -l
# Should match documented reference count

# Check for broken links
for file in /home/benjamin/.config/nvim/docs/*.md; do
  echo "Checking $file"
  grep -o '\[.*\](.*\.md)' "$file" | sed 's/.*(\(.*\))/\1/'
done
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(591): complete Phase 1 - Inventory and Analysis`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 2: Content Analysis and Repetition Detection
dependencies: [1]

**Objective**: Identify repetitive content and consolidation opportunities

**Complexity**: Medium

**Tasks**:
- [x] Extract topics/sections from each documentation file
- [x] Identify content that appears in multiple files (prerequisites, setup steps, standards)
- [x] Document repetitive content with source locations
- [x] Create consolidation recommendations (which file should be primary source)
- [x] Identify missing cross-references (places that should link but don't)
- [x] Document inconsistencies in terminology or descriptions

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Check for common repeated sections
for keyword in "Prerequisites" "Installation" "Dependencies" "Setup"; do
  echo "=== $keyword ==="
  grep -l "$keyword" /home/benjamin/.config/nvim/docs/*.md
done

# Verify analysis document created
test -f /tmp/nvim_docs_content_analysis.md
```

**Expected Duration**: 2.5 hours

**Phase 2 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(591): complete Phase 2 - Content Analysis and Repetition Detection`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 3: Create Comprehensive README.md
dependencies: [1, 2]

**Objective**: Create nvim/docs/README.md as central documentation hub

**Complexity**: Medium

**Tasks**:
- [x] Design README structure (overview, file catalog, navigation, quick reference)
- [x] Write overview section explaining docs/ directory purpose
- [x] Create file catalog table with: filename, purpose, key topics, size
- [x] Organize files by category (Setup, Development, Workflows, Reference)
- [x] Add "Quick Start" section with most-used docs for new users
- [x] Add "Documentation Standards" section referencing DOCUMENTATION_STANDARDS.md
- [x] Add navigation links to parent (nvim/) and related directories
- [x] Include cross-reference summary (files that link here)
- [x] Add maintenance notes (how to update, link checking procedures)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify README exists and has required sections
test -f /home/benjamin/.config/nvim/docs/README.md

# Check for required sections
grep -q "## Overview" /home/benjamin/.config/nvim/docs/README.md
grep -q "## File Catalog" /home/benjamin/.config/nvim/docs/README.md
grep -q "## Navigation" /home/benjamin/.config/nvim/docs/README.md

# Verify all 17 files are cataloged
count=$(grep -c "\.md" /home/benjamin/.config/nvim/docs/README.md)
[ $count -ge 17 ]
```

**Expected Duration**: 2.5 hours

**Phase 3 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [x] Git commit created: `feat(591): complete Phase 3 - Create Comprehensive README.md`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

### Phase 4: Enhance Cross-Linking and Navigation
dependencies: [3]

**Objective**: Add navigation links to all docs files and improve cross-references

**Complexity**: High

**Tasks**:
- [ ] Add "Related Documentation" section to each docs file
- [ ] Add navigation footer to each file (Parent: nvim/, Index: docs/README.md)
- [ ] Standardize link format (use relative paths: ./FILE.md)
- [ ] Add cross-references where content is related but missing links
- [ ] Update INSTALLATION.md to reference CLAUDE_CODE_INSTALL.md and MIGRATION_GUIDE.md
- [ ] Update CODE_STANDARDS.md to reference DOCUMENTATION_STANDARDS.md
- [ ] Update AI_TOOLING.md to reference RESEARCH_TOOLING.md and FORMAL_VERIFICATION.md
- [ ] Ensure bidirectional linking (if A links to B, B should link to A where relevant)
- [ ] Add "See also" sections for related topics
- [ ] Update nvim/README.md to reference new docs/README.md

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify navigation sections added
for file in /home/benjamin/.config/nvim/docs/*.md; do
  if ! grep -q "Navigation\|Related Documentation" "$file"; then
    echo "Missing navigation in $file"
  fi
done

# Check bidirectional linking
# If INSTALLATION.md links to MIGRATION_GUIDE.md, verify reverse link exists
grep -q "INSTALLATION.md" /home/benjamin/.config/nvim/docs/MIGRATION_GUIDE.md
```

**Expected Duration**: 3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(591): complete Phase 4 - Enhance Cross-Linking and Navigation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Consolidate Repetitive Content
dependencies: [2, 4]

**Objective**: Reduce repetition by establishing primary sources and cross-references

**Complexity**: High

**Tasks**:
- [ ] Consolidate prerequisites: Make INSTALLATION.md primary source, reference from others
- [ ] Remove duplicate setup instructions from ADVANCED_SETUP.md, add cross-references
- [ ] Consolidate API key setup: Make AI_TOOLING.md primary source for AI configuration
- [ ] Remove duplicate mapping documentation: Ensure MAPPINGS.md is comprehensive, reference from tools
- [ ] Consolidate code standards: Ensure CODE_STANDARDS.md and DOCUMENTATION_STANDARDS.md don't duplicate
- [ ] Update files to reference primary sources instead of duplicating content
- [ ] Add clear "See [Primary Source](link)" for moved content
- [ ] Verify no information loss during consolidation

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Check reduction in file sizes (some files should be smaller)
du -b /home/benjamin/.config/nvim/docs/*.md > /tmp/sizes_after.txt
# Compare with sizes from Phase 1

# Verify cross-references exist where content was removed
grep -r "See \[" /home/benjamin/.config/nvim/docs/*.md | wc -l
# Should have multiple "See" references

# Ensure no broken links introduced
/home/benjamin/.config/.claude/lib/validate-links.sh /home/benjamin/.config/nvim/docs/
```

**Expected Duration**: 3 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(591): complete Phase 5 - Consolidate Repetitive Content`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Validation and Finalization
dependencies: [3, 4, 5]

**Objective**: Comprehensive validation and final adjustments

**Complexity**: Low

**Tasks**:
- [ ] Run link validation on all nvim/docs/ files
- [ ] Verify all cross-references from external files still work
- [ ] Check compliance with DOCUMENTATION_STANDARDS.md (present-state focus, no historical markers)
- [ ] Verify README.md is comprehensive and accurate
- [ ] Test navigation flow (can users find what they need?)
- [ ] Spell check all modified documentation files
- [ ] Review for consistent terminology and writing style
- [ ] Final review of cross-reference matrix (all important links present)
- [ ] Update nvim/CLAUDE.md to reference docs/README.md as documentation hub
- [ ] Create final git commit with comprehensive refactor summary

**Testing**:
```bash
# Comprehensive link validation
find /home/benjamin/.config/nvim/docs -name "*.md" -exec \
  grep -H -o '\[.*\](.*\.md)' {} \; | \
  sed 's/.*(\(.*\))/\1/' | \
  while read link; do
    test -f "/home/benjamin/.config/nvim/docs/$link" || echo "Broken: $link"
  done

# Verify external references still work
grep -r "nvim/docs/" /home/benjamin/.config --include="*.md" | \
  grep -o 'nvim/docs/[^)]*\.md' | sort -u | \
  while read ref; do
    test -f "/home/benjamin/.config/$ref" || echo "Broken external ref: $ref"
  done

# Check for documentation standard compliance
! grep -r "previously\|now supports\|(New)\|(Updated)" /home/benjamin/.config/nvim/docs/*.md

# Verify README completeness
grep -c "\.md" /home/benjamin/.config/nvim/docs/README.md
# Should be 17 (all docs files cataloged)
```

**Expected Duration**: 1 hour

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(591): complete Phase 6 - Validation and Finalization`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Link validation for all internal references
- Path format consistency checks
- Section presence validation (all files have navigation)

### Integration Testing
- External reference validation (all 43+ referencing files)
- Navigation flow testing (can traverse from README to specific docs)
- Cross-reference bidirectionality checks

### Validation Testing
- DOCUMENTATION_STANDARDS.md compliance
- No broken links or 404s
- Consistent terminology throughout
- No historical markers or temporal language

### Test Execution
```bash
# Run all validation tests
cd /home/benjamin/.config/nvim/docs

# 1. Internal link validation
for file in *.md; do
  echo "Validating $file"
  grep -o '\[.*\](.*\.md)' "$file" | sed 's/.*(\(.*\))/\1/' | \
    while read link; do
      test -f "$link" || echo "Broken link in $file: $link"
    done
done

# 2. External reference validation
cd /home/benjamin/.config
grep -r "nvim/docs/" --include="*.md" | \
  grep -o 'nvim/docs/[^)]*\.md' | sort -u | \
  while read ref; do
    test -f "$ref" || echo "Broken external reference: $ref"
  done

# 3. Standards compliance
cd /home/benjamin/.config/nvim/docs
! grep -r "previously\|now supports\|(New)\|(Updated)\|(Legacy)" *.md

# 4. README completeness
test -f README.md
grep -q "## File Catalog" README.md
[ $(grep -c "\.md" README.md) -ge 17 ]

echo "All tests passed!"
```

## Documentation Requirements

### Files to Create
- [ ] nvim/docs/README.md - Central documentation index and navigation hub

### Files to Update
- [ ] All 17 existing docs files - Add navigation sections and improve cross-links
- [ ] nvim/README.md - Reference new docs/README.md
- [ ] nvim/CLAUDE.md - Update documentation policy section if needed

### Documentation Standards
All documentation must follow DOCUMENTATION_STANDARDS.md:
- Present-state focus (no historical markers)
- Clear navigation links
- Consistent path formats (relative paths preferred)
- Comprehensive cross-referencing
- No repetitive content (use primary sources with cross-references)

## Dependencies

### External Dependencies
None - this is pure documentation refactoring

### Internal Dependencies
- Existing nvim/docs/ files (17 files)
- DOCUMENTATION_STANDARDS.md (reference for standards)
- Cross-reference analysis results

### Prerequisites
- Complete read access to repository for cross-reference analysis
- Grep tool for finding references
- Text editor for documentation updates

### Risk Mitigation
- **Risk**: Breaking external links during refactoring
  - **Mitigation**: Comprehensive external reference testing in Phase 6
- **Risk**: Loss of information during consolidation
  - **Mitigation**: Careful review before removing content, preserve in git history
- **Risk**: Inconsistent link formats causing broken references
  - **Mitigation**: Standardize on relative paths, validate all links
- **Risk**: README.md becoming too large or overwhelming
  - **Mitigation**: Use clear categorization and tables for scanability

## Notes

This refactoring enhances the documentation structure without changing technical content. The focus is on organization, navigation, and reducing repetition through smart cross-referencing.

Key principles:
1. **Single source of truth**: Each topic has one primary source
2. **Smart cross-referencing**: Related docs link to each other bidirectionally
3. **Clear navigation**: Every file has clear parent/index/related links
4. **Standards compliance**: All docs follow DOCUMENTATION_STANDARDS.md
5. **Maintainability**: Clear structure makes future updates easier

The result will be a well-organized, navigable documentation directory that serves as the central knowledge hub for the Neovim configuration.
