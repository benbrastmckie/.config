# nvim/docs Directory Refactoring Implementation Plan

## Metadata
- **Date**: 2025-11-04
- **Feature**: Refactor nvim/docs directory with Diataxis organization, cross-linking, and minimal repetition
- **Scope**: Reorganize 18 documentation files into structured categories with comprehensive README.md
- **Estimated Phases**: 6
- **Estimated Hours**: 16-20
- **Structure Level**: 0
- **Complexity Score**: 62.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Current Structure and Content](../reports/001_current_structure_and_content.md)
  - [External References Analysis](../reports/002_external_references.md)
  - [Organization Best Practices](../reports/003_organization_best_practices.md)

## Overview

This plan refactors the `/home/benjamin/.config/nvim/docs/` directory to improve organization, discoverability, and maintainability while minimizing content repetition. The refactoring adopts Diataxis framework principles (Reference, Guides, Concepts, Workflows), implements comprehensive cross-linking, tracks all external references (48 files with 132+ references), and creates a central README.md with multi-layered navigation.

**Goals**:
1. Reorganize 18 documentation files into 4 Diataxis categories
2. Create comprehensive README.md with task-based, role-based, and category-based navigation
3. Update all external references (48 files) to new structure
4. Implement single-source-of-truth declarations to prevent duplication
5. Add subdirectory READMs with consistent structure
6. Enhance cross-document linking with "See Also" sections

## Research Summary

Based on three comprehensive research reports:

**Current Structure** (Report 001):
- 18 markdown files (9,496 lines) covering installation, standards, reference, and features
- Strengths: comprehensive coverage, present-state philosophy, multiple installation approaches
- Issues: potential repetition across 3 installation guides, large file size (CLAUDE_CODE_INSTALL.md: 1,681 lines), tool naming confusion (OpenCode vs Claude Code)

**External References** (Report 002):
- 48 files contain references to nvim/docs/ across repository (132+ total references)
- Most referenced: INSTALLATION.md (37 refs), CODE_STANDARDS.md (29 refs), MAPPINGS.md (21 refs)
- Three reference patterns: root-relative, parent-relative, absolute paths
- High integration quality with hub-and-spoke navigation structure

**Best Practices** (Report 003):
- `.claude/docs/` provides excellent template with Diataxis framework implementation
- Key patterns: "I Want To..." navigation, hierarchical READMEs, single-source-of-truth declarations
- Repetition minimization strategies: metadata-based organization, link-heavy writing, layered documentation
- Archive strategy for superseded documentation

## Success Criteria

- [ ] All 18 documentation files organized into reference/, guides/, concepts/, workflows/ subdirectories
- [ ] New README.md implements task-based ("I Want To..."), role-based, and category-based navigation
- [ ] All 48 external referencing files updated with correct paths
- [ ] Four subdirectory READMEs created following `.claude/docs/concepts/README.md` pattern
- [ ] All documents include "See Also" sections with 3-5 related document links
- [ ] Single-source-of-truth declarations added to authoritative documents (CODE_STANDARDS.md, DOCUMENTATION_STANDARDS.md, etc.)
- [ ] No broken links (verified with link checker)
- [ ] Documentation standards compliance (present-state focus, no temporal markers, UTF-8 without emojis)

## Technical Design

### Directory Structure

**Before** (flat structure):
```
nvim/docs/
├── README.md (193 lines)
├── INSTALLATION.md
├── CLAUDE_CODE_INSTALL.md
├── MIGRATION_GUIDE.md
├── ADVANCED_SETUP.md
├── CLAUDE_CODE_QUICK_REF.md
├── KEYBOARD_PROTOCOL_SETUP.md
├── JUMP_LIST_TESTING_CHECKLIST.md
├── CODE_STANDARDS.md
├── DOCUMENTATION_STANDARDS.md
├── ARCHITECTURE.md
├── MAPPINGS.md
├── GLOSSARY.md
├── FORMAL_VERIFICATION.md
├── AI_TOOLING.md
├── RESEARCH_TOOLING.md
├── NIX_WORKFLOWS.md
├── NOTIFICATIONS.md
└── templates/
```

**After** (Diataxis structure):
```
nvim/docs/
├── README.md (comprehensive navigation hub, ~300 lines)
├── reference/
│   ├── README.md (category overview)
│   ├── MAPPINGS.md (keybinding reference)
│   ├── GLOSSARY.md (technical terms)
│   └── CLAUDE_CODE_QUICK_REF.md (prompt reference)
├── guides/
│   ├── README.md (category overview)
│   ├── INSTALLATION.md (manual setup)
│   ├── MIGRATION_GUIDE.md (existing config migration)
│   ├── ADVANCED_SETUP.md (optional features)
│   ├── KEYBOARD_PROTOCOL_SETUP.md (terminal config)
│   └── JUMP_LIST_TESTING_CHECKLIST.md (testing procedures)
├── concepts/
│   ├── README.md (category overview)
│   ├── ARCHITECTURE.md (system design)
│   ├── CODE_STANDARDS.md (Lua conventions)
│   ├── DOCUMENTATION_STANDARDS.md (writing guidelines)
│   ├── FORMAL_VERIFICATION.md (Lean 4 integration)
│   ├── AI_TOOLING.md (AI workflows)
│   ├── RESEARCH_TOOLING.md (academic writing)
│   ├── NIX_WORKFLOWS.md (NixOS integration)
│   └── NOTIFICATIONS.md (notification system)
├── workflows/
│   ├── README.md (category overview)
│   └── CLAUDE_CODE_INSTALL.md (AI-assisted installation tutorial)
└── templates/
```

### File Categorization Rationale

**Reference** (quick lookup, information-oriented):
- MAPPINGS.md: Keybinding reference table
- GLOSSARY.md: Term definitions
- CLAUDE_CODE_QUICK_REF.md: Prompt syntax reference

**Guides** (how-to, task-oriented):
- INSTALLATION.md: Step-by-step manual setup
- MIGRATION_GUIDE.md: How to migrate existing config
- ADVANCED_SETUP.md: How to enable optional features
- KEYBOARD_PROTOCOL_SETUP.md: How to configure terminal protocols
- JUMP_LIST_TESTING_CHECKLIST.md: How to test jump list navigation

**Concepts** (understanding-oriented):
- ARCHITECTURE.md: How the system works
- CODE_STANDARDS.md: Why code is structured this way
- DOCUMENTATION_STANDARDS.md: Philosophy behind documentation
- FORMAL_VERIFICATION.md: Lean 4 integration concepts
- AI_TOOLING.md: AI workflow patterns
- RESEARCH_TOOLING.md: Academic writing architecture
- NIX_WORKFLOWS.md: NixOS integration concepts
- NOTIFICATIONS.md: Notification system design

**Workflows** (learning-oriented, step-by-step):
- CLAUDE_CODE_INSTALL.md: Complete AI-assisted installation tutorial

### Navigation Enhancements

**Main README.md** will include:
1. **Purpose Statement**: Brief Diataxis explanation with framework link
2. **I Want To...** Section: 10 common tasks with direct links
3. **Quick Start by Role**: Audience-specific paths (new users, existing users, developers)
4. **Browse by Category**: Four categories with descriptions and key documents
5. **Documentation Catalog**: Comprehensive table with purpose + use cases
6. **Directory Structure**: Visual tree with file counts
7. **Related Documentation**: Links to parent README, CLAUDE.md, other directories

**Subdirectory READMEs** will include:
1. **Purpose**: Category explanation
2. **Navigation**: Parent/sibling links
3. **Documents in This Section**: Each with purpose + use cases + "See Also" links
4. **Quick Start**: Learning path for category
5. **Directory Structure**: Visual tree
6. **Related Documentation**: Cross-category links

### Reference Update Strategy

**48 files with references require updates**:

1. **Root Documentation** (3 files, 25 references):
   - `/home/benjamin/.config/README.md` (15 refs)
   - `/home/benjamin/.config/CLAUDE.md` (4 refs)
   - `/home/benjamin/.config/docs/README.md` (6 refs)

2. **Platform-Specific Docs** (4 files, 8 references):
   - `docs/platform/*.md` (2 refs each)

3. **Common Procedures** (4 files, 18 references):
   - `docs/common/prerequisites.md` (10 refs)
   - `docs/common/*.md` (others)

4. **Claude Code System** (8+ files, 24 references):
   - `.claude/README.md`, `.claude/docs/README.md`, etc.

5. **Specifications** (15+ files, 40+ references):
   - Various `.claude/specs/*` research reports

6. **Neovim Project** (6 files):
   - `nvim/README.md`, `nvim/specs/*`, `nvim/lua/*`

**Update Pattern**:
```bash
# Old reference:
[Code Standards](nvim/docs/CODE_STANDARDS.md)

# New reference:
[Code Standards](nvim/docs/concepts/CODE_STANDARDS.md)
```

### Cross-Referencing Pattern

Each document will include "See Also" section with 3-5 related documents:

**Example for CODE_STANDARDS.md**:
```markdown
## See Also

- [Documentation Standards](DOCUMENTATION_STANDARDS.md) - Writing guidelines complementing code standards
- [Architecture](ARCHITECTURE.md) - System design principles informing code organization
- [Formal Verification](FORMAL_VERIFICATION.md) - Testing standards and verification approaches
- [Installation Guide](../guides/INSTALLATION.md) - Setup procedures using these standards
```

### Single-Source-of-Truth Declarations

Authoritative documents will include ownership declaration:

**Example for CODE_STANDARDS.md**:
```markdown
# Code Standards

**AUTHORITATIVE SOURCE**: This document is the single source of truth for Lua coding conventions in the Neovim configuration. Other documents should reference this guide rather than duplicating its content.
```

**Authoritative documents**:
- CODE_STANDARDS.md (Lua conventions)
- DOCUMENTATION_STANDARDS.md (writing guidelines)
- ARCHITECTURE.md (system design)
- MAPPINGS.md (keybindings)

## Implementation Phases

### Phase 1: Preparation and Analysis
dependencies: []

**Objective**: Verify current state, create detailed reference inventory, and prepare migration scripts

**Complexity**: Low

**Tasks**:
- [ ] Verify all 18 documentation files exist in `/home/benjamin/.config/nvim/docs/`
- [ ] Create reference inventory: list all 48 files with references and their line numbers
- [ ] Create backup of current nvim/docs/ directory structure
- [ ] Create migration script to update file paths in all referencing files
- [ ] Verify no uncommitted changes in nvim/docs/ (clean git state)

**Testing**:
```bash
# Verify file count and structure
cd /home/benjamin/.config/nvim/docs
find . -name "*.md" | wc -l  # Should be 18 (excluding templates/)

# Verify reference count
cd /home/benjamin/.config
grep -r "nvim/docs/" --include="*.md" | wc -l  # Should be 132+

# Check git status
git status nvim/docs/
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(586): complete Phase 1 - Preparation and Analysis`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Create Subdirectory Structure and READMEs
dependencies: [1]

**Objective**: Create four category subdirectories and comprehensive READMEs following `.claude/docs/` patterns

**Complexity**: Medium

**Tasks**:
- [ ] Create subdirectories: `reference/`, `guides/`, `concepts/`, `workflows/`
- [ ] Create `reference/README.md` following `.claude/docs/concepts/README.md` pattern (file: nvim/docs/reference/README.md)
- [ ] Create `guides/README.md` with task-oriented learning path (file: nvim/docs/guides/README.md)
- [ ] Create `concepts/README.md` with understanding-oriented navigation (file: nvim/docs/concepts/README.md)
- [ ] Create `workflows/README.md` with tutorial-focused structure (file: nvim/docs/workflows/README.md)
- [ ] Each README must include: Purpose, Navigation, Documents (with use cases), Quick Start, Directory Structure, Related Documentation
- [ ] Verify all four READMEs follow consistent structure pattern

**Testing**:
```bash
# Verify subdirectories created
cd /home/benjamin/.config/nvim/docs
ls -d */ | grep -E "reference|guides|concepts|workflows"  # Should list 4 directories

# Verify README structure
for dir in reference guides concepts workflows; do
  echo "Checking $dir/README.md..."
  grep -q "## Purpose" "$dir/README.md" || echo "Missing Purpose in $dir"
  grep -q "## Navigation" "$dir/README.md" || echo "Missing Navigation in $dir"
  grep -q "## Documents in This Section" "$dir/README.md" || echo "Missing Documents section in $dir"
done
```

**Expected Duration**: 3-4 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(586): complete Phase 2 - Create Subdirectory Structure and READMEs`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Move Files and Update Internal Links
dependencies: [2]

**Objective**: Move 18 documentation files to appropriate subdirectories and update all internal cross-references

**Complexity**: High

**Tasks**:
- [ ] Move reference files: `git mv MAPPINGS.md GLOSSARY.md CLAUDE_CODE_QUICK_REF.md reference/`
- [ ] Move guide files: `git mv INSTALLATION.md MIGRATION_GUIDE.md ADVANCED_SETUP.md KEYBOARD_PROTOCOL_SETUP.md JUMP_LIST_TESTING_CHECKLIST.md guides/`
- [ ] Move concept files: `git mv ARCHITECTURE.md CODE_STANDARDS.md DOCUMENTATION_STANDARDS.md FORMAL_VERIFICATION.md AI_TOOLING.md RESEARCH_TOOLING.md NIX_WORKFLOWS.md NOTIFICATIONS.md concepts/`
- [ ] Move workflow files: `git mv CLAUDE_CODE_INSTALL.md workflows/`
- [ ] Update all internal document links (within nvim/docs/) to use relative paths (e.g., `../concepts/ARCHITECTURE.md`)
- [ ] Add "See Also" sections to all 18 documents with 3-5 related document links
- [ ] Add single-source-of-truth declarations to CODE_STANDARDS.md, DOCUMENTATION_STANDARDS.md, ARCHITECTURE.md, MAPPINGS.md
- [ ] Verify no broken links within nvim/docs/ using grep for `](` patterns

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify file moves
cd /home/benjamin/.config/nvim/docs
test -f reference/MAPPINGS.md || echo "ERROR: MAPPINGS.md not moved"
test -f guides/INSTALLATION.md || echo "ERROR: INSTALLATION.md not moved"
test -f concepts/CODE_STANDARDS.md || echo "ERROR: CODE_STANDARDS.md not moved"
test -f workflows/CLAUDE_CODE_INSTALL.md || echo "ERROR: CLAUDE_CODE_INSTALL.md not moved"

# Verify no broken relative links within nvim/docs/
# Check for links to files that no longer exist in old locations
grep -r "](../INSTALLATION.md)" . && echo "WARNING: Old-style link found"
grep -r "](INSTALLATION.md)" . --exclude-dir=guides && echo "WARNING: Non-relative link found"

# Verify "See Also" sections exist
grep -l "## See Also" reference/*.md guides/*.md concepts/*.md workflows/*.md | wc -l  # Should be 18
```

**Expected Duration**: 4-5 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(586): complete Phase 3 - Move Files and Update Internal Links`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Update External References
dependencies: [3]

**Objective**: Update all 48 external files with references to nvim/docs/ files to use new subdirectory paths

**Complexity**: High

**Tasks**:
- [ ] Update root documentation (3 files): README.md, CLAUDE.md, docs/README.md
- [ ] Update platform-specific docs (4 files): docs/platform/arch.md, debian.md, macos.md, windows.md
- [ ] Update common procedures (4 files): docs/common/prerequisites.md, zotero-setup.md, terminal-setup.md, git-config.md
- [ ] Update Claude Code system (8 files): .claude/README.md, .claude/docs/README.md, .claude/commands/README.md, .claude/agents/README.md, .claude/hooks/README.md, .claude/lib/UTILS_README.md, .claude/tts/README.md, .claude/specs/README.md
- [ ] Update specifications (15+ files): Various .claude/specs/* research reports and implementation plans
- [ ] Update Neovim project files (6 files): nvim/README.md, nvim/lua/neotex/plugins/tools/snacks/dashboard.lua, nvim/specs/summaries/*.md
- [ ] Use migration script to automate path updates where possible
- [ ] Manually verify critical reference updates (CLAUDE.md standards references)
- [ ] Run comprehensive link checker across entire repository

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify no references to old paths remain
cd /home/benjamin/.config
grep -r "nvim/docs/INSTALLATION.md" --include="*.md" --exclude-dir=nvim/docs && echo "ERROR: Old reference found"
grep -r "nvim/docs/CODE_STANDARDS.md" --include="*.md" --exclude-dir=nvim/docs && echo "ERROR: Old reference found"

# Verify new references exist
grep -r "nvim/docs/guides/INSTALLATION.md" --include="*.md" | wc -l  # Should be ~37
grep -r "nvim/docs/concepts/CODE_STANDARDS.md" --include="*.md" | wc -l  # Should be ~29

# Test dashboard.lua reference update
grep -q "nvim/docs/reference/MAPPINGS.md" nvim/lua/neotex/plugins/tools/snacks/dashboard.lua || echo "ERROR: dashboard.lua not updated"

# Run link checker (if available)
find . -name "*.md" -exec grep -l "nvim/docs/" {} \; | xargs -I {} bash -c 'grep -o "\[.*\](nvim/docs/[^)]*)" {} | sed "s/.*](\(.*\))/\1/" | xargs -I @ test -f @ || echo "Broken link in {}"'
```

**Expected Duration**: 5-6 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(586): complete Phase 4 - Update External References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Create Comprehensive Main README.md
dependencies: [4]

**Objective**: Replace nvim/docs/README.md with comprehensive navigation hub following `.claude/docs/README.md` pattern

**Complexity**: Medium

**Tasks**:
- [ ] Backup existing README.md to README.md.old
- [ ] Create new README.md structure: Purpose, "I Want To...", Quick Start by Role, Browse by Category, Documentation Catalog, Directory Structure, Related Documentation (file: nvim/docs/README.md)
- [ ] Add "I Want To..." section with 10 common tasks (install, find keybinding, understand architecture, customize, migrate, troubleshoot, etc.)
- [ ] Add "Quick Start by Role" section with paths for: new users, existing users, developers, AI-assisted users
- [ ] Add "Browse by Category" section explaining reference/guides/concepts/workflows with key documents
- [ ] Create comprehensive documentation catalog table with: file name, purpose, use cases (3-5 per document)
- [ ] Add visual directory structure tree with file counts per category
- [ ] Add related documentation links to parent README, CLAUDE.md, other directories
- [ ] Include cross-reference summary ("Referenced by 48+ files across repository")

**Testing**:
```bash
# Verify README structure
cd /home/benjamin/.config/nvim/docs
grep -q "## I Want To..." README.md || echo "ERROR: Missing 'I Want To' section"
grep -q "## Quick Start by Role" README.md || echo "ERROR: Missing role-based navigation"
grep -q "## Browse by Category" README.md || echo "ERROR: Missing category navigation"
grep -q "## Documentation Catalog" README.md || echo "ERROR: Missing catalog"

# Verify comprehensive coverage
# Should reference all 18 documents
grep -o "\[.*\.md\]" README.md | sort -u | wc -l  # Should be 18

# Verify file size (should be ~300 lines for comprehensive navigation)
wc -l README.md  # Should be 250-350 lines
```

**Expected Duration**: 3-4 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(586): complete Phase 5 - Create Comprehensive Main README.md`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Verification and Documentation
dependencies: [5]

**Objective**: Comprehensive testing, link verification, and update implementation summary

**Complexity**: Low

**Tasks**:
- [ ] Run comprehensive link checker across entire repository (verify no broken links)
- [ ] Verify all 4 subdirectory READMEs have consistent structure
- [ ] Verify all 18 documents have "See Also" sections
- [ ] Verify single-source-of-truth declarations present in 4 authoritative documents
- [ ] Test navigation paths: follow 10 "I Want To..." tasks from main README to ensure smooth user experience
- [ ] Verify documentation standards compliance: no temporal markers, present-state focus, UTF-8 without emojis
- [ ] Update implementation summary in .claude/specs/586_*/summaries/ with migration details
- [ ] Remove README.md.old backup file
- [ ] Create migration guide for future documentation refactoring (optional)

**Testing**:
```bash
# Comprehensive link verification
cd /home/benjamin/.config
# Check all markdown files for broken links to nvim/docs/
find . -name "*.md" | while read file; do
  grep -o "](nvim/docs/[^)]*)" "$file" | sed 's/](\(.*\))/\1/' | while read link; do
    test -f "$link" || echo "BROKEN LINK in $file: $link"
  done
done

# Verify no old-style references remain
grep -r "nvim/docs/INSTALLATION.md" --include="*.md" && echo "ERROR: Old reference found" || echo "✓ No old references"
grep -r "nvim/docs/CODE_STANDARDS.md" --include="*.md" && echo "ERROR: Old reference found" || echo "✓ No old references"

# Verify new structure complete
cd /home/benjamin/.config/nvim/docs
test -f README.md || echo "ERROR: Main README missing"
test -f reference/README.md || echo "ERROR: reference/README missing"
test -f guides/README.md || echo "ERROR: guides/README missing"
test -f concepts/README.md || echo "ERROR: concepts/README missing"
test -f workflows/README.md || echo "ERROR: workflows/README missing"

# Count moved files
find reference guides concepts workflows -name "*.md" ! -name "README.md" | wc -l  # Should be 18

# Run test suite (if applicable)
cd /home/benjamin/.config
.claude/tests/run_all_tests.sh
```

**Expected Duration**: 2 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(586): complete Phase 6 - Verification and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- File existence verification for all 18 moved files
- Link syntax validation (grep patterns for broken links)
- README structure validation (required sections present)

### Integration Testing
- Cross-document link verification (all "See Also" links valid)
- External reference verification (48 files updated correctly)
- Navigation path testing (follow user journeys from README)

### Regression Testing
- Verify no broken links introduced
- Verify all external references still resolve
- Verify runtime references (dashboard.lua) still work

### Test Automation
```bash
#!/bin/bash
# test_docs_refactor.sh

echo "Testing nvim/docs refactoring..."

# Test 1: Verify subdirectories exist
test -d nvim/docs/reference || exit 1
test -d nvim/docs/guides || exit 1
test -d nvim/docs/concepts || exit 1
test -d nvim/docs/workflows || exit 1

# Test 2: Verify all 18 files moved
file_count=$(find nvim/docs/{reference,guides,concepts,workflows} -name "*.md" ! -name "README.md" | wc -l)
[ "$file_count" -eq 18 ] || { echo "Expected 18 files, found $file_count"; exit 1; }

# Test 3: Verify no old-style references
grep -r "nvim/docs/INSTALLATION.md" --include="*.md" --exclude-dir=nvim/docs && exit 1
grep -r "nvim/docs/CODE_STANDARDS.md" --include="*.md" --exclude-dir=nvim/docs && exit 1

# Test 4: Verify README structure
grep -q "## I Want To..." nvim/docs/README.md || exit 1
grep -q "## Quick Start by Role" nvim/docs/README.md || exit 1
grep -q "## Browse by Category" nvim/docs/README.md || exit 1

echo "✓ All tests passed"
```

### Coverage Requirements
- **File Move Coverage**: 100% (all 18 files in correct subdirectories)
- **Reference Update Coverage**: 100% (all 48 external files updated)
- **Link Validity Coverage**: 100% (no broken links)
- **README Completeness**: 100% (all required sections present)

## Documentation Requirements

### Files to Update
1. **nvim/docs/README.md**: Replace with comprehensive navigation hub (~300 lines)
2. **nvim/docs/reference/README.md**: Create new subdirectory overview
3. **nvim/docs/guides/README.md**: Create new subdirectory overview
4. **nvim/docs/concepts/README.md**: Create new subdirectory overview
5. **nvim/docs/workflows/README.md**: Create new subdirectory overview
6. **All 18 documentation files**: Add "See Also" sections
7. **4 authoritative documents**: Add single-source-of-truth declarations
8. **48 external files**: Update references to new paths

### Documentation Standards Compliance
- **Present-State Focus**: Describe new structure without historical commentary (no "previously flat structure" language)
- **Clean-Break Refactoring**: Move files completely, don't leave aliases or redirects
- **Timeless Writing**: New structure described as if it always existed
- **No Temporal Markers**: No "(New)", "(Updated)", "(Reorganized)" markers
- **UTF-8 Without Emojis**: Text indicators only (NOTE:, WARNING:, IMPORTANT:)
- **Unicode Box-Drawing**: Use ┌─┐│└┘ for directory trees

### Cross-Reference Updates
- Update CLAUDE.md references to CODE_STANDARDS.md and DOCUMENTATION_STANDARDS.md (lines 40-41)
- Update nvim/CLAUDE.md references if any (search and update)
- Update all .claude/ README files referencing nvim/docs/
- Update specifications and research reports with old references

## Dependencies

### External Dependencies
- None (pure documentation refactoring)

### Internal Dependencies
- Git for file moves and tracking changes
- Text editors for markdown updates
- Bash for migration scripts and testing

### Reference Tracking
- Research Report 001: File inventory and content analysis
- Research Report 002: Complete list of 48 external referencing files
- Research Report 003: Diataxis patterns from .claude/docs/

### Prerequisite Knowledge
- Diataxis framework (4 content categories)
- Project documentation standards (present-state focus, clean-break philosophy)
- Markdown link syntax (relative paths, anchors)
- Git file move operations (preserves history)

## Risk Mitigation

### Risk 1: Broken External Links
**Mitigation**:
- Create migration script to automate path updates
- Test with comprehensive link checker
- Phase updates (internal first, then external)

### Risk 2: Incomplete Reference Tracking
**Mitigation**:
- Use Research Report 002 inventory (48 files identified)
- Run grep across entire repository to catch missed references
- Test all critical paths (CLAUDE.md, dashboard.lua)

### Risk 3: Large File Size (CLAUDE_CODE_INSTALL.md)
**Mitigation**:
- Keep as single workflow tutorial (1,681 lines acceptable for step-by-step guide)
- Consider splitting in future if user feedback indicates navigation difficulty
- Add comprehensive table of contents with anchors

### Risk 4: Navigation Disruption During Migration
**Mitigation**:
- Complete file moves and internal link updates in single atomic commit
- Update external references in separate commit (allows rollback if needed)
- Test navigation paths before finalizing

## Notes

### Design Decisions

**Decision 1: Adopt Diataxis Framework**
- **Rationale**: Proven pattern in .claude/docs/ with excellent discoverability and minimal repetition
- **Alternative Considered**: Keep flat structure with improved README
- **Why Chosen**: Category-based organization naturally separates content types and reduces duplication

**Decision 2: Move Files Rather Than Alias**
- **Rationale**: Consistent with clean-break refactoring philosophy
- **Alternative Considered**: Create redirects or symbolic links
- **Why Chosen**: Clean structure prevents navigation confusion; git preserves history

**Decision 3: Single CLAUDE_CODE_INSTALL.md in workflows/**
- **Rationale**: Step-by-step tutorial benefits from linear reading (1,681 lines acceptable for workflow)
- **Alternative Considered**: Split into phases/ subdirectory
- **Why Chosen**: Keeps tutorial cohesive; can split later if needed based on user feedback

**Decision 4: Keep templates/ Subdirectory at Root Level**
- **Rationale**: Templates are resources, not documentation content
- **Alternative Considered**: Move to reference/ or create separate resources/
- **Why Chosen**: Current location aligns with purpose (templates are used by workflows, not documentation content)

### Future Enhancements

1. **Archive Subdirectory**: Create nvim/docs/archive/ for superseded documentation (when needed)
2. **Templates Expansion**: Document LaTeX templates referenced in RESEARCH_TOOLING.md
3. **Tool Naming Cleanup**: Clarify OpenCode vs Claude Code references in AI_TOOLING.md
4. **Automated Link Checking**: Add CI/CD pipeline for broken link detection
5. **Reference Map Generation**: Automate creation of external reference reports

### Maintenance Guidelines

- **Adding New Documents**: Categorize as reference/guide/concept/workflow, add to subdirectory README
- **Updating References**: Update both document content and relevant README catalog entries
- **Deprecating Content**: Move to archive/ subdirectory with redirect in archive README
- **Link Verification**: Run periodic link checks (quarterly recommended)

---

**Plan Created**: 2025-11-04
**Complexity Calculation**:
- Base (refactor): 5
- Tasks: 42 / 2 = 21
- Files: 18 (to move) + 48 (to update) = 66 * 3 = 198 ... adjusted to 20 (weighting major files)
- Integrations: 4 (subdirectory creation, navigation enhancement, reference tracking, standards compliance) * 5 = 20
- **Total Score**: 5 + 21 + 20 + 16 = 62.0

**Note on Complexity**: Score of 62.0 suggests this plan could benefit from `/expand` during implementation if any phase proves more complex than estimated. The high number of external references (48 files) is the primary complexity driver.
