# nvim/docs Directory Refactor and Documentation Enhancement Plan

## Metadata
- **Date**: 2025-11-05
- **Feature**: nvim/docs Directory Refactor with Cross-Reference Tracking
- **Scope**: Reorganize nvim/docs directory, create comprehensive README.md, track all cross-references, implement cross-linking strategies
- **Estimated Phases**: 6
- **Estimated Hours**: 14
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 87.0
- **Research Reports**:
  - [Directory Structure and Organization Research](../reports/001_directory_structure_and_organization_research.md)
  - [Cross-References to nvim/docs Files Research](../reports/002_cross_references_to_nvim_docs_files_research.md)
  - [Documentation Organization Patterns and Cross-Linking Strategies Research](../reports/003_documentation_organization_patterns_and_cross_linking_strategies_research.md)

## Overview

This plan refactors the /home/benjamin/.config/nvim/docs/ directory to improve organization, documentation quality, and cross-reference management. The refactor maintains the current flat structure (recommended by research) while enhancing navigation, fixing broken references, filling documentation gaps, and implementing sophisticated cross-linking strategies from the .claude/docs/ pattern.

**Goals**:
1. Fix all broken GUIDELINES.md references (6 locations identified)
2. Create comprehensive README.md documenting directory contents
3. Implement consistent navigation patterns across all documentation
4. Add task-based "I Want To..." navigation following .claude/docs/ pattern
5. Establish authoritative source declarations to prevent duplication
6. Fill high-priority documentation gaps (troubleshooting, LSP configuration)
7. Track and validate all 500+ cross-references to nvim/docs/

## Research Summary

Based on three comprehensive research reports:

### Directory Structure Findings (Report 1)
- Current structure: 19 markdown files (9,496 lines) in flat organization
- Natural categorization: Setup (5 files), Standards (3 files), Reference (5 files), Features (4 files), Navigation (2 files)
- **Recommendation**: Keep flat structure at current scale (19 files well within 25-30 threshold)
- Missing critical documentation: TROUBLESHOOTING.md, LSP_CONFIGURATION.md, plugin guides
- 327+ cross-references throughout repository create high reorganization cost

### Cross-Reference Analysis (Report 2)
- 500+ total references across 53 files
- Most referenced: INSTALLATION.md (71), CODE_STANDARDS.md (39), ADVANCED_SETUP.md (29)
- **Broken references**: GUIDELINES.md referenced in 6 locations but does not exist
- Three reference patterns: root-relative (60%), parent-relative (30%), absolute display (10%)
- No Lua code references (documentation is reference material only)

### Organization Patterns (Report 3)
- Multi-layered documentation architecture across repository
- .claude/docs/ uses Diataxis framework (reference/guides/concepts/workflows/)
- Consistent navigation pattern: Navigation + Related Documentation sections in 41 files
- Authoritative Source principle prevents content duplication across 171+ documentation files
- Task-based "I Want To..." navigation reduces discovery time by 40-60%

**Recommended approach based on research**:
1. Maintain flat structure with enhanced navigation
2. Fix broken GUIDELINES.md references → CODE_STANDARDS.md
3. Implement .claude/docs/ navigation patterns for consistency
4. Add task-based navigation following "I Want To..." pattern
5. Create TROUBLESHOOTING.md and LSP_CONFIGURATION.md (high-priority gaps)
6. Establish authoritative source declarations

## Success Criteria
- [ ] All 6 broken GUIDELINES.md references fixed and validated
- [ ] Comprehensive README.md created documenting all 19 files with task-based navigation
- [ ] Navigation and Related Documentation sections added to all 18 documentation files
- [ ] Authoritative source declarations added to CODE_STANDARDS.md, ARCHITECTURE.md, MAPPINGS.md
- [ ] TROUBLESHOOTING.md created consolidating scattered troubleshooting content
- [ ] LSP_CONFIGURATION.md created documenting language server configuration
- [ ] All 500+ cross-references validated with automated script
- [ ] Link validation script created and tested
- [ ] All documentation follows present-state focus standard (no historical markers)
- [ ] Tree notation standardized using Unicode box-drawing characters

## Technical Design

### Architecture Overview

```
nvim/docs/                           # Flat structure maintained (19 → 21 files after additions)
├── README.md                        # Enhanced navigation hub (NEW STRUCTURE)
│   ├── "I Want To..." navigation   # Task-based quick access
│   ├── Catalog table                # Current structure preserved
│   ├── Documentation by Task        # Enhanced grouping
│   ├── Authoritative Sources        # NEW: Single source of truth declarations
│   └── Cross-Reference Summary      # Enhanced with validation status
│
├── Installation & Setup (5 files)
│   └── [Enhanced with Navigation sections]
│
├── Development Standards (3 files)
│   └── [Enhanced with authoritative source declarations]
│
├── Reference Documentation (5 → 7 files)
│   ├── TROUBLESHOOTING.md          # NEW: Consolidated troubleshooting
│   ├── LSP_CONFIGURATION.md        # NEW: Language server configuration
│   └── [Enhanced with Navigation sections]
│
├── Feature Documentation (4 files)
│   └── [Enhanced with Navigation sections]
│
└── templates/
    └── [Future enhancement]
```

### Navigation Pattern Implementation

**Standard Navigation Section** (added to all 18 files):
```markdown
## Navigation

- [← Documentation Index](README.md)
- [Installation & Setup](#installation-setup) - Getting started guides
- [Development Standards](#development-standards) - Coding conventions and policies
- [Reference Documentation](#reference-documentation) - Quick lookup materials
- [Feature Documentation](#feature-documentation) - Feature-specific guides

## Related Documentation

**Installation**:
- [INSTALLATION.md](INSTALLATION.md) - Basic installation guide
- [CLAUDE_CODE_INSTALL.md](CLAUDE_CODE_INSTALL.md) - AI-assisted installation

**Standards**:
- [CODE_STANDARDS.md](CODE_STANDARDS.md) - Lua coding conventions
- [DOCUMENTATION_STANDARDS.md](DOCUMENTATION_STANDARDS.md) - Documentation policies

**Reference**:
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [MAPPINGS.md](MAPPINGS.md) - Keybinding reference
```

### Authoritative Source Strategy

Declare authoritative sources in README.md and respective files:

**CODE_STANDARDS.md**:
```markdown
> **AUTHORITATIVE SOURCE**: This document is the single source of truth for all Lua coding conventions, module structure, and development practices in this Neovim configuration. Guides and documentation should reference this document rather than duplicating its content.
```

**ARCHITECTURE.md**:
```markdown
> **AUTHORITATIVE SOURCE**: This document is the single source of truth for system design, plugin organization, initialization flow, and architectural decisions. Feature documentation should reference this document for architectural context.
```

**MAPPINGS.md**:
```markdown
> **AUTHORITATIVE SOURCE**: This document is the single source of truth for all keybinding references, shortcuts, and mapping documentation. Feature guides should reference this document for keybinding information.
```

### Reference Pattern Standardization

**Established Conventions** (documented in README.md):
1. **Root-level files** (README.md, CLAUDE.md): Use root-relative paths `nvim/docs/FILE.md`
2. **docs/ subdirectory**: Use parent-relative paths `../../nvim/docs/FILE.md`
3. **nvim/docs/ internal**: Use simple relative paths `FILE.md`
4. **.claude/ READMEs**: Use absolute display + relative link pattern

## Implementation Phases

### Phase 1: Fix Broken References
dependencies: []

**Objective**: Fix all 6 broken GUIDELINES.md references and validate changes
**Complexity**: Low
**Expected Duration**: 1 hour

Tasks:
- [ ] Update nvim/specs/plans/claude-session-enhancement.md: GUIDELINES.md → CODE_STANDARDS.md
- [ ] Update nvim/specs/summaries/019_preserve_claudemd_in_worktrees_summary.md: GUIDELINES.md → CODE_STANDARDS.md
- [ ] Update nvim/specs/reports/012_neovim_configuration_website_overview.md: GUIDELINES.md → CODE_STANDARDS.md
- [ ] Update .claude/specs/README.md: GUIDELINES.md → CODE_STANDARDS.md
- [ ] Update .claude/data/logs/README.md: GUIDELINES.md → CODE_STANDARDS.md
- [ ] Update .claude/data/metrics/README.md: GUIDELINES.md → CODE_STANDARDS.md
- [ ] Verify all 6 references now point to existing CODE_STANDARDS.md file

Testing:
```bash
# Verify no GUIDELINES.md references remain
grep -r "nvim/docs/GUIDELINES\.md" --include="*.md" /home/benjamin/.config/ 2>/dev/null

# Expected: No results (all references fixed)
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(595): complete Phase 1 - Fix Broken References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Create Enhanced README.md
dependencies: [1]

**Objective**: Create comprehensive README.md with task-based navigation and authoritative source declarations
**Complexity**: Medium
**Expected Duration**: 2.5 hours

Tasks:
- [ ] Read current nvim/docs/README.md to preserve existing structure
- [ ] Create "I Want To..." task-based navigation section (8-10 common tasks)
- [ ] Add "Authoritative Sources" section declaring CODE_STANDARDS, ARCHITECTURE, MAPPINGS as canonical
- [ ] Enhance "Documentation by Task" section with more pathways
- [ ] Add "Quick Start by Role" section (New Users, Developers, Contributors, AI-Assisted Users)
- [ ] Update "Documentation Standards" section with reference pattern conventions
- [ ] Add "Cross-Reference Validation" section with link checking instructions
- [ ] Update catalog table with new files (TROUBLESHOOTING.md, LSP_CONFIGURATION.md placeholders)
- [ ] Add visual separators between categories for improved readability
- [ ] Preserve existing cross-reference summary and maintenance procedures

Testing:
```bash
# Verify README.md structure
grep -c "^## I Want To\.\.\." /home/benjamin/.config/nvim/docs/README.md
# Expected: 1 (section exists)

grep -c "^## Authoritative Sources" /home/benjamin/.config/nvim/docs/README.md
# Expected: 1 (section exists)

grep -c "^## Quick Start by Role" /home/benjamin/.config/nvim/docs/README.md
# Expected: 1 (section exists)
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(595): complete Phase 2 - Create Enhanced README.md`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Add Navigation Sections to Existing Documentation
dependencies: [2]

**Objective**: Add consistent Navigation and Related Documentation sections to all 18 existing documentation files
**Complexity**: Medium
**Expected Duration**: 3 hours

Tasks:
- [ ] Add Navigation section to INSTALLATION.md (file: /home/benjamin/.config/nvim/docs/INSTALLATION.md)
- [ ] Add Navigation section to CLAUDE_CODE_INSTALL.md
- [ ] Add Navigation section to MIGRATION_GUIDE.md
- [ ] Add Navigation section to ADVANCED_SETUP.md
- [ ] Add Navigation section to KEYBOARD_PROTOCOL_SETUP.md
- [ ] Add Navigation + authoritative declaration to CODE_STANDARDS.md
- [ ] Add Navigation + authoritative declaration to DOCUMENTATION_STANDARDS.md
- [ ] Add Navigation section to FORMAL_VERIFICATION.md
- [ ] Add Navigation + authoritative declaration to ARCHITECTURE.md
- [ ] Add Navigation + authoritative declaration to MAPPINGS.md

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Add Navigation section to GLOSSARY.md
- [ ] Add Navigation section to CLAUDE_CODE_QUICK_REF.md
- [ ] Add Navigation section to JUMP_LIST_TESTING_CHECKLIST.md
- [ ] Add Navigation section to AI_TOOLING.md
- [ ] Add Navigation section to RESEARCH_TOOLING.md
- [ ] Add Navigation section to NIX_WORKFLOWS.md
- [ ] Add Navigation section to NOTIFICATIONS.md
- [ ] Add Related Documentation sections to all 18 files with bidirectional cross-references
- [ ] Verify navigation sections follow standard pattern from design specification

Testing:
```bash
# Count files with Navigation sections
grep -l "^## Navigation$" /home/benjamin/.config/nvim/docs/*.md | wc -l
# Expected: 18 (all documentation files)

# Count files with Related Documentation sections
grep -l "^## Related Documentation$" /home/benjamin/.config/nvim/docs/*.md | wc -l
# Expected: 18 (all documentation files)

# Verify authoritative declarations
grep -c "AUTHORITATIVE SOURCE" /home/benjamin/.config/nvim/docs/CODE_STANDARDS.md
# Expected: 1
grep -c "AUTHORITATIVE SOURCE" /home/benjamin/.config/nvim/docs/ARCHITECTURE.md
# Expected: 1
grep -c "AUTHORITATIVE SOURCE" /home/benjamin/.config/nvim/docs/MAPPINGS.md
# Expected: 1
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(595): complete Phase 3 - Add Navigation Sections`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Create High-Priority Documentation Files
dependencies: [3]

**Objective**: Create TROUBLESHOOTING.md and LSP_CONFIGURATION.md to fill identified documentation gaps
**Complexity**: Medium
**Expected Duration**: 3 hours

Tasks:
- [ ] Extract troubleshooting content from INSTALLATION.md (common issues section)
- [ ] Extract troubleshooting content from CLAUDE_CODE_INSTALL.md (AI workflow troubleshooting)
- [ ] Extract troubleshooting content from ADVANCED_SETUP.md (advanced feature issues)
- [ ] Create TROUBLESHOOTING.md with consolidated troubleshooting content (file: /home/benjamin/.config/nvim/docs/TROUBLESHOOTING.md)
- [ ] Add Navigation and Related Documentation sections to TROUBLESHOOTING.md
- [ ] Organize TROUBLESHOOTING.md by category (Installation, Plugins, LSP, Performance, AI Tools)
- [ ] Create LSP_CONFIGURATION.md documenting language server setup (file: /home/benjamin/.config/nvim/docs/LSP_CONFIGURATION.md)
- [ ] Document LSP configuration for major languages (Lua, Python, JavaScript/TypeScript, Rust, Go)
- [ ] Add LSP troubleshooting section referencing TROUBLESHOOTING.md
- [ ] Add Navigation and Related Documentation sections to LSP_CONFIGURATION.md
- [ ] Update README.md catalog table with TROUBLESHOOTING.md and LSP_CONFIGURATION.md entries
- [ ] Update cross-references in existing files to point to new consolidated troubleshooting content

Testing:
```bash
# Verify new files created
test -f /home/benjamin/.config/nvim/docs/TROUBLESHOOTING.md && echo "✓ TROUBLESHOOTING.md exists"
test -f /home/benjamin/.config/nvim/docs/LSP_CONFIGURATION.md && echo "✓ LSP_CONFIGURATION.md exists"

# Verify minimum content size (comprehensive documentation)
FILE_SIZE=$(wc -c < /home/benjamin/.config/nvim/docs/TROUBLESHOOTING.md)
[ "$FILE_SIZE" -ge 2000 ] && echo "✓ TROUBLESHOOTING.md is comprehensive ($FILE_SIZE bytes)"

FILE_SIZE=$(wc -c < /home/benjamin/.config/nvim/docs/LSP_CONFIGURATION.md)
[ "$FILE_SIZE" -ge 1500 ] && echo "✓ LSP_CONFIGURATION.md is comprehensive ($FILE_SIZE bytes)"

# Verify Navigation sections
grep -q "^## Navigation$" /home/benjamin/.config/nvim/docs/TROUBLESHOOTING.md && echo "✓ TROUBLESHOOTING.md has Navigation"
grep -q "^## Navigation$" /home/benjamin/.config/nvim/docs/LSP_CONFIGURATION.md && echo "✓ LSP_CONFIGURATION.md has Navigation"
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(595): complete Phase 4 - Create High-Priority Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Implement Link Validation
dependencies: [4]

**Objective**: Create automated link validation script and validate all 500+ cross-references
**Complexity**: Medium
**Expected Duration**: 2.5 hours

Tasks:
- [ ] Create validate-nvim-docs-links.sh script (file: /home/benjamin/.config/.claude/scripts/validate-nvim-docs-links.sh)
- [ ] Implement markdown link extraction logic using grep and sed
- [ ] Implement path resolution for root-relative, parent-relative, and absolute paths
- [ ] Implement file existence checking for all nvim/docs/ references
- [ ] Add broken link reporting with file and line number information
- [ ] Test script against known valid references (INSTALLATION.md, CODE_STANDARDS.md)
- [ ] Test script against fixed GUIDELINES.md references (should pass)
- [ ] Run script against entire repository to validate all 500+ cross-references
- [ ] Document script usage in README.md "Cross-Reference Validation" section
- [ ] Add script to pre-commit hook recommendations (optional, document in README)
- [ ] Create summary report of validation results

Testing:
```bash
# Verify script created
test -f /home/benjamin/.config/.claude/scripts/validate-nvim-docs-links.sh && echo "✓ Script exists"

# Verify script is executable
test -x /home/benjamin/.config/.claude/scripts/validate-nvim-docs-links.sh && echo "✓ Script is executable"

# Run validation script
/home/benjamin/.config/.claude/scripts/validate-nvim-docs-links.sh
# Expected: Exit code 0 (all links valid), 0 broken links reported
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(595): complete Phase 5 - Implement Link Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Final Validation and Documentation
dependencies: [5]

**Objective**: Validate all changes, ensure standards compliance, and update project documentation
**Complexity**: Low
**Expected Duration**: 2 hours

Tasks:
- [ ] Run link validation script and verify zero broken links
- [ ] Verify all files follow present-state focus standard (no "New", "Updated", "previously" markers)
- [ ] Check tree notation consistency across all documentation using Unicode box-drawing
- [ ] Verify all Navigation sections follow standard pattern
- [ ] Verify all authoritative source declarations present and correct
- [ ] Test "I Want To..." navigation links in README.md
- [ ] Update root CLAUDE.md if needed to reference new documentation structure
- [ ] Update nvim/CLAUDE.md to reference TROUBLESHOOTING.md and LSP_CONFIGURATION.md
- [ ] Create implementation summary documenting changes and validation results
- [ ] Run final comprehensive validation pass

Testing:
```bash
# Final validation suite
echo "=== Final Validation Suite ==="

# 1. Link validation
/home/benjamin/.config/.claude/scripts/validate-nvim-docs-links.sh
# Expected: 0 broken links

# 2. Present-state compliance (no historical markers)
grep -r "previously\|now supports\|recently added\|(New)\|(Updated)" /home/benjamin/.config/nvim/docs/*.md
# Expected: No results

# 3. Navigation section count
NAV_COUNT=$(grep -l "^## Navigation$" /home/benjamin/.config/nvim/docs/*.md | wc -l)
echo "Navigation sections: $NAV_COUNT/20" # 18 original + 2 new files
[ "$NAV_COUNT" -eq 20 ] && echo "✓ All files have Navigation sections"

# 4. Authoritative source declarations
AUTH_COUNT=$(grep -c "AUTHORITATIVE SOURCE" /home/benjamin/.config/nvim/docs/*.md)
echo "Authoritative declarations: $AUTH_COUNT"
[ "$AUTH_COUNT" -eq 3 ] && echo "✓ All authoritative sources declared"

# 5. File count verification
FILE_COUNT=$(ls -1 /home/benjamin/.config/nvim/docs/*.md | wc -l)
echo "Documentation files: $FILE_COUNT"
[ "$FILE_COUNT" -eq 21 ] && echo "✓ Correct file count (19 + 2 new)"

echo "=== Validation Complete ==="
```

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(595): complete Phase 6 - Final Validation and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Each phase includes specific validation tests for changes made
- Link validation script tested against known valid and invalid references
- Navigation section structure validated with grep pattern matching
- File existence checks for all new documentation files

### Integration Testing
- Cross-reference validation across entire repository (500+ references)
- Navigation flow testing (click through all "I Want To..." links)
- Authoritative source reference validation (no content duplication)
- README.md catalog table completeness check

### Validation Testing
- Present-state focus standard compliance (no historical markers)
- Tree notation consistency (Unicode box-drawing characters)
- Reference pattern consistency (root-relative, parent-relative, absolute)
- Standards compliance with DOCUMENTATION_STANDARDS.md

### Automated Testing
- Link validation script run during Phase 5 and Phase 6
- Pre-commit hook integration recommended (documented in README)
- File count and structure validation in final validation suite

## Documentation Requirements

### New Documentation Files
1. **TROUBLESHOOTING.md**:
   - Consolidate troubleshooting content from INSTALLATION.md, CLAUDE_CODE_INSTALL.md, ADVANCED_SETUP.md
   - Organize by category (Installation, Plugins, LSP, Performance, AI Tools)
   - Include Navigation and Related Documentation sections
   - Reference from README.md and installation guides

2. **LSP_CONFIGURATION.md**:
   - Document language server setup for major languages (Lua, Python, JS/TS, Rust, Go)
   - Include configuration examples and troubleshooting
   - Add Navigation and Related Documentation sections
   - Reference from README.md and ARCHITECTURE.md

3. **README.md Enhancements**:
   - Add "I Want To..." task-based navigation (8-10 tasks)
   - Add "Authoritative Sources" section
   - Add "Quick Start by Role" section
   - Update catalog table with new files
   - Add "Cross-Reference Validation" section

### Updated Documentation Files
All 18 existing documentation files receive:
- Navigation section (standard pattern)
- Related Documentation section (bidirectional cross-references)
- Authoritative source declarations (CODE_STANDARDS.md, ARCHITECTURE.md, MAPPINGS.md)
- Updated cross-references to TROUBLESHOOTING.md (remove inline troubleshooting content)

### Project Documentation Updates
- Root CLAUDE.md: Update references to new documentation structure
- nvim/CLAUDE.md: Add references to TROUBLESHOOTING.md and LSP_CONFIGURATION.md
- Implementation summary: Document all changes and validation results

## Dependencies

### External Dependencies
None - all changes are documentation-only

### Internal Prerequisites
- Research reports must be read and understood before implementation
- DOCUMENTATION_STANDARDS.md must be referenced for present-state focus compliance
- CODE_STANDARDS.md must be referenced for tree notation (Unicode box-drawing characters)

### File Dependencies
- Phase 1 must complete before Phase 2 (broken references fixed before README enhancement)
- Phase 2 must complete before Phase 3 (README structure defines navigation pattern)
- Phase 3 must complete before Phase 4 (navigation pattern established before new files)
- Phase 4 must complete before Phase 5 (all files created before validation)
- Phase 5 must complete before Phase 6 (validation script created before final validation)

### Tool Dependencies
- Bash (for link validation script)
- grep, sed (for markdown link extraction and validation)
- Git (for commits after each phase)

## Risk Management

### Technical Risks

**Risk 1: Breaking Existing Links During Refactor**
- **Mitigation**: Maintain flat structure (no file moves), only add content
- **Fallback**: Link validation script detects any issues before final commit

**Risk 2: Content Duplication During Consolidation**
- **Mitigation**: Follow authoritative source principle, reference not duplicate
- **Fallback**: Remove duplicated sections if identified during validation

**Risk 3: Incomplete Troubleshooting Consolidation**
- **Mitigation**: Systematic extraction from all installation files
- **Fallback**: Iterative improvement - add more content in follow-up if needed

### Process Risks

**Risk 1: Standards Compliance Violations**
- **Mitigation**: Test for historical markers in Phase 6 validation
- **Fallback**: Manual review and correction before final commit

**Risk 2: Link Validation Script False Positives**
- **Mitigation**: Test script against known valid/invalid references
- **Fallback**: Manual verification of flagged links

### Timeline Risks

**Risk 1: Phase 3 Taking Longer Than Estimated**
- **Mitigation**: Navigation sections follow simple template pattern
- **Fallback**: Extend phase duration if needed, 18 files can be processed systematically

**Risk 2: TROUBLESHOOTING.md Scope Creep**
- **Mitigation**: Focus on consolidation, not creation of new troubleshooting content
- **Fallback**: Create basic structure, iterate in future enhancements

## Notes

**Complexity Score Calculation**:
```
score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
score = (61 × 1.0) + (6 × 5.0) + (14 × 0.5) + (5 × 2.0)
score = 61 + 30 + 7 + 10 = 108.0
```

**Note**: Complexity score of 108.0 suggests this plan might benefit from expansion using `/expand-phase` during implementation, particularly for Phase 3 (18 files to update) and Phase 4 (creating new comprehensive documentation). However, starting with Level 0 structure allows for organic growth during implementation.

**Progressive Planning**: This plan follows the progressive planning approach:
- Level 0 (current): Single file with all phases inline
- If complexity proves higher during implementation, use `/expand phase 3` or `/expand phase 4`
- Phase dependencies support parallel execution where possible

**Standards Alignment**:
- Follows present-state focus standard (DOCUMENTATION_STANDARDS.md)
- Uses Unicode box-drawing for tree diagrams (nvim/CLAUDE.md:435-458)
- Implements authoritative source principle (.claude/docs/concepts/patterns/README.md:1-4)
- Uses task-based navigation pattern (.claude/docs/README.md:16-59)
- Follows reference pattern conventions (root-relative, parent-relative, absolute)
