# Documentation Reorganization Implementation Plan

## Metadata
- **Date**: 2025-10-17
- **Feature**: Reorganize .claude/docs/ directory into Diataxis-aligned subdirectories with comprehensive READMEs and cross-linking
- **Scope**: Restructure 27 documentation files into 4 subdirectories (reference/, guides/, concepts/, workflows/), create centralized data-management.md, standardize README templates, update all cross-references
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: .claude/specs/reports/053_docs_reorganization_structure_analysis.md

## Overview

Reorganize the `.claude/docs/` directory from a flat structure (27 files at root level) into a Diataxis-aligned subdirectory structure that improves discoverability by 40-45% (research-backed). The Diataxis framework organizes documentation by user need into four categories: Reference (lookup), Guides (how-to), Concepts (understanding), and Workflows (tutorials).

**Current State**:
- 27 documentation files in flat structure
- Logical categorization in README.md but no physical subdirectories
- 248 internal cross-reference links
- Heavy documentation of technical features but fragmented data/ directory documentation
- Missing centralized guide for data/ ecosystem

**Target State**:
- 4 subdirectories aligned with Diataxis framework (reference/, guides/, concepts/, workflows/)
- 28 files total (27 existing + 1 new data-management.md)
- Standardized README.md in each subdirectory with breadcrumb navigation
- All 248+ internal links updated to reflect new structure
- CLAUDE.md references updated
- Centralized data/ documentation

## Success Criteria

- [ ] All 27 existing files moved to appropriate Diataxis subdirectories
- [ ] New data-management.md created and integrated
- [ ] 4 subdirectory READMEs created with standardized template
- [ ] Main docs/README.md updated with new structure
- [ ] All 248+ internal links updated and validated
- [ ] CLAUDE.md references updated to new paths
- [ ] archive/ redirect links updated
- [ ] No broken documentation links
- [ ] Link validation script created for future maintenance

## Technical Design

### Diataxis-Aligned Structure

```
docs/
├── README.md                     # Updated central index
├── reference/                    # Information-oriented (5 files)
│   ├── README.md
│   ├── command-reference.md
│   ├── agent-reference.md
│   ├── claude-md-section-schema.md
│   ├── command_architecture_standards.md
│   └── phase_dependencies.md
├── guides/                       # Task-focused how-to (11 files)
│   ├── README.md
│   ├── creating-commands.md
│   ├── creating-agents.md
│   ├── using-agents.md
│   ├── standards-integration.md
│   ├── command-patterns.md
│   ├── command-examples.md
│   ├── logging-patterns.md
│   ├── setup-command-guide.md
│   ├── efficiency-guide.md
│   ├── error-enhancement.md
│   └── data-management.md        # NEW
├── concepts/                     # Understanding-oriented (4 files)
│   ├── README.md
│   ├── hierarchical_agents.md
│   ├── writing-standards.md
│   ├── directory-protocols.md
│   └── development-workflow.md
├── workflows/                    # Learning-oriented tutorials (7 files)
│   ├── README.md
│   ├── orchestration-guide.md
│   ├── adaptive-planning-guide.md
│   ├── checkpoint_template_guide.md
│   ├── template-system-guide.md
│   ├── spec_updater_guide.md
│   ├── tts-integration-guide.md
│   └── conversion-guide.md
└── archive/                      # Historical (update redirects)
    ├── README.md
    ├── topic_based_organization.md → ../concepts/directory-protocols.md
    ├── artifact_organization.md    → ../concepts/directory-protocols.md
    ├── development-philosophy.md   → ../concepts/writing-standards.md
    └── timeless_writing_guide.md   → ../concepts/writing-standards.md
```

**Rationale**:
- **reference/**: Quick lookup materials (commands, agents, schemas, standards)
- **guides/**: Problem-solving how-tos (creating, using, patterns, optimization)
- **concepts/**: System understanding (architecture, philosophy, principles)
- **workflows/**: Step-by-step tutorials (orchestration, planning, integration)

### README Template Structure

All subdirectory READMEs will follow this template:

```markdown
# [Category Name]

## Purpose
[1-2 sentence description]

## Navigation
- [← Documentation Index](../README.md)
- [Related Category](../other-category/) (if applicable)

## Documents in This Section
### [Document Name](document-name.md)
**Purpose**: [Description]
**Use Cases**: [Bullet list]

## Quick Start
[Common tasks/journeys]

## Related Documentation
[Cross-links to other categories]
```

### Link Update Strategy

**Internal Links** (docs/ → docs/):
- Update relative links: `[text](file.md)` → `[text](../category/file.md)`
- Update cross-category links: `guides/` → `concepts/`
- Update archive/ redirects to new paths

**External Links** (other directories → docs/):
- CLAUDE.md section references
- Command file documentation links
- Agent file documentation links

**Validation**:
- Create link validation script
- Verify all links resolve before finalizing

## Implementation Phases

### Phase 1: Foundation Setup
**Objective**: Create subdirectory structure and prepare for migration
**Complexity**: Low
**Dependencies**: None

Tasks:
- [ ] Create subdirectories: `.claude/docs/reference/`, `.claude/docs/guides/`, `.claude/docs/concepts/`, `.claude/docs/workflows/`
- [ ] Verify subdirectory creation with `ls -la .claude/docs/`
- [ ] Create placeholder README.md in each subdirectory (minimal content for now)
- [ ] Create `.claude/templates/readme-template.md` for standardization

Testing:
```bash
# Verify directory structure
ls -la .claude/docs/
test -d .claude/docs/reference && echo "reference/ exists"
test -d .claude/docs/guides && echo "guides/ exists"
test -d .claude/docs/concepts && echo "concepts/ exists"
test -d .claude/docs/workflows && echo "workflows/ exists"
test -f .claude/templates/readme-template.md && echo "README template exists"
```

Validation:
- All 4 subdirectories exist
- Template file created
- No errors during directory creation

### Phase 2: File Migration to Subdirectories
**Objective**: Move all 27 files to appropriate Diataxis subdirectories
**Complexity**: Medium
**Dependencies**: Phase 1 complete

Tasks:
- [ ] Move reference files (5 files):
  - `git mv .claude/docs/command-reference.md .claude/docs/reference/`
  - `git mv .claude/docs/agent-reference.md .claude/docs/reference/`
  - `git mv .claude/docs/claude-md-section-schema.md .claude/docs/reference/`
  - `git mv .claude/docs/command_architecture_standards.md .claude/docs/reference/`
  - `git mv .claude/docs/phase_dependencies.md .claude/docs/reference/`
- [ ] Move guides files (10 files):
  - `git mv .claude/docs/creating-commands.md .claude/docs/guides/`
  - `git mv .claude/docs/creating-agents.md .claude/docs/guides/`
  - `git mv .claude/docs/using-agents.md .claude/docs/guides/`
  - `git mv .claude/docs/standards-integration.md .claude/docs/guides/`
  - `git mv .claude/docs/command-patterns.md .claude/docs/guides/`
  - `git mv .claude/docs/command-examples.md .claude/docs/guides/`
  - `git mv .claude/docs/logging-patterns.md .claude/docs/guides/`
  - `git mv .claude/docs/setup-command-guide.md .claude/docs/guides/`
  - `git mv .claude/docs/efficiency-guide.md .claude/docs/guides/`
  - `git mv .claude/docs/error-enhancement-guide.md .claude/docs/guides/`
- [ ] Move concepts files (4 files):
  - `git mv .claude/docs/hierarchical_agents.md .claude/docs/concepts/`
  - `git mv .claude/docs/writing-standards.md .claude/docs/concepts/`
  - `git mv .claude/docs/directory-protocols.md .claude/docs/concepts/`
  - `git mv .claude/docs/development-workflow.md .claude/docs/concepts/`
- [ ] Move workflows files (7 files):
  - `git mv .claude/docs/orchestration-guide.md .claude/docs/workflows/`
  - `git mv .claude/docs/adaptive-planning-guide.md .claude/docs/workflows/`
  - `git mv .claude/docs/checkpoint_template_guide.md .claude/docs/workflows/`
  - `git mv .claude/docs/template-system-guide.md .claude/docs/workflows/`
  - `git mv .claude/docs/spec_updater_guide.md .claude/docs/workflows/`
  - `git mv .claude/docs/tts-integration-guide.md .claude/docs/workflows/`
  - `git mv .claude/docs/conversion-guide.md .claude/docs/workflows/`
- [ ] Verify all 27 files moved successfully

Testing:
```bash
# Verify file counts
echo "reference/: $(ls .claude/docs/reference/*.md 2>/dev/null | wc -l) files (expected: 5)"
echo "guides/: $(ls .claude/docs/guides/*.md 2>/dev/null | grep -v README | wc -l) files (expected: 10)"
echo "concepts/: $(ls .claude/docs/concepts/*.md 2>/dev/null | grep -v README | wc -l) files (expected: 4)"
echo "workflows/: $(ls .claude/docs/workflows/*.md 2>/dev/null | grep -v README | wc -l) files (expected: 7)"

# Verify root docs/ only has README.md and archive/
ls .claude/docs/*.md 2>/dev/null | grep -v README.md && echo "ERROR: Files still in root" || echo "SUCCESS: Only README.md in root"
```

Validation:
- reference/: 5 files
- guides/: 10 files (data-management.md will be added in Phase 3)
- concepts/: 4 files
- workflows/: 7 files
- Root docs/ contains only README.md and archive/

### Phase 3: Create Data Management Guide
**Objective**: Create comprehensive centralized data/ directory documentation
**Complexity**: Medium
**Dependencies**: Phase 2 complete

Tasks:
- [ ] Create `.claude/docs/guides/data-management.md` with structure:
  - Purpose and overview of data/ directory
  - Checkpoints section (purpose, usage, auto-resume, file format, troubleshooting)
  - Logs section (all 8 log files: hook-debug.log, tts.log, adaptive-planning.log, approval-decisions.log, phase-handoffs.log, supervision-tree.log, subagent-outputs.log)
  - Metrics section (JSONL format, usage, analysis)
  - Registry section (artifact metadata, agent registry, integration patterns)
  - Integration workflows table (commands/hooks → data/ files)
  - Maintenance procedures
- [ ] Link to existing data/ subdirectory READMEs
- [ ] Add cross-references from hierarchical_agents.md, orchestration-guide.md, adaptive-planning-guide.md

Testing:
```bash
# Verify file created
test -f .claude/docs/guides/data-management.md && echo "data-management.md created"

# Check content completeness (basic checks)
grep -q "## Checkpoints" .claude/docs/guides/data-management.md && echo "✓ Checkpoints section"
grep -q "## Logs" .claude/docs/guides/data-management.md && echo "✓ Logs section"
grep -q "## Metrics" .claude/docs/guides/data-management.md && echo "✓ Metrics section"
grep -q "## Registry" .claude/docs/guides/data-management.md && echo "✓ Registry section"
grep -q "approval-decisions.log" .claude/docs/guides/data-management.md && echo "✓ Advanced logs documented"
```

Validation:
- File created at .claude/docs/guides/data-management.md
- All 8 log files documented
- Integration workflows table present
- Cross-references added to related guides

### Phase 4: Update Internal Documentation Links
**Objective**: Update all internal links within docs/ files to reflect new subdirectory structure
**Complexity**: High
**Dependencies**: Phase 2, Phase 3 complete

Tasks:
- [ ] Update links in reference/ files (5 files):
  - Update relative links to other docs files
  - Update links to use `../{category}/{file}.md` format
- [ ] Update links in guides/ files (11 files):
  - Update relative links to other docs files
  - Update cross-category links to reference/, concepts/, workflows/
- [ ] Update links in concepts/ files (4 files):
  - Update relative links to other docs files
  - Add links to new data-management.md where appropriate
- [ ] Update links in workflows/ files (7 files):
  - Update relative links to other docs files
  - Update links to data-management.md
- [ ] Update archive/ redirect messages:
  - Update topic_based_organization.md → `../concepts/directory-protocols.md`
  - Update artifact_organization.md → `../concepts/directory-protocols.md`
  - Update development-philosophy.md → `../concepts/writing-standards.md`
  - Update timeless_writing_guide.md → `../concepts/writing-standards.md`

Testing:
```bash
# Create link inventory and check for broken links
# This will be done via link validation script created in Phase 6

# Quick check: ensure no links still point to flat structure
grep -r '\[.*\](.*\.md)' .claude/docs/reference/ | grep -v '\.\.\/' | grep -v 'README.md' && echo "ERROR: Non-relative links in reference/" || echo "✓ reference/ links updated"
grep -r '\[.*\](.*\.md)' .claude/docs/guides/ | grep -v '\.\.\/' | grep -v 'README.md' && echo "ERROR: Non-relative links in guides/" || echo "✓ guides/ links updated"
grep -r '\[.*\](.*\.md)' .claude/docs/concepts/ | grep -v '\.\.\/' | grep -v 'README.md' && echo "ERROR: Non-relative links in concepts/" || echo "✓ concepts/ links updated"
grep -r '\[.*\](.*\.md)' .claude/docs/workflows/ | grep -v '\.\.\/' | grep -v 'README.md' && echo "ERROR: Non-relative links in workflows/" || echo "✓ workflows/ links updated"
```

Validation:
- All internal links use `../{category}/{file}.md` format
- No broken links within docs/ directory
- archive/ redirects point to new locations
- Cross-category links work correctly

### Phase 5: Create Subdirectory READMEs and Update Main Index
**Objective**: Create comprehensive READMEs using standardized template and update main docs/README.md
**Complexity**: Medium
**Dependencies**: Phase 4 complete

Tasks:
- [ ] Create `.claude/docs/reference/README.md`:
  - Apply standard template
  - List all 5 reference documents with descriptions
  - Add breadcrumb navigation
  - Include quick start for lookup tasks
- [ ] Create `.claude/docs/guides/README.md`:
  - Apply standard template
  - List all 11 how-to guides with descriptions
  - Add breadcrumb navigation
  - Include quick start for common development tasks
- [ ] Create `.claude/docs/concepts/README.md`:
  - Apply standard template
  - List all 4 conceptual documents with descriptions
  - Add breadcrumb navigation
  - Include quick start for understanding system architecture
- [ ] Create `.claude/docs/workflows/README.md`:
  - Apply standard template
  - List all 7 workflow tutorials with descriptions
  - Add breadcrumb navigation
  - Include quick start for common user journeys
- [ ] Update main `.claude/docs/README.md`:
  - Update directory structure section to show new subdirectories
  - Update all file references to new paths (e.g., `reference/command-reference.md`)
  - Add visual directory tree with Unicode box-drawing
  - Update "Quick Start by Role" section with new paths
  - Update all navigation sections

Testing:
```bash
# Verify all READMEs created
test -f .claude/docs/reference/README.md && echo "✓ reference/README.md"
test -f .claude/docs/guides/README.md && echo "✓ guides/README.md"
test -f .claude/docs/concepts/README.md && echo "✓ concepts/README.md"
test -f .claude/docs/workflows/README.md && echo "✓ workflows/README.md"

# Verify main README updated
grep -q "reference/" .claude/docs/README.md && echo "✓ Main README references subdirectories"
grep -q "guides/" .claude/docs/README.md && echo "✓ Main README includes guides/"
grep -q "concepts/" .claude/docs/README.md && echo "✓ Main README includes concepts/"
grep -q "workflows/" .claude/docs/README.md && echo "✓ Main README includes workflows/"
```

Validation:
- All 4 subdirectory READMEs created with standard template
- Main docs/README.md updated with new structure
- Breadcrumb navigation present in all READMEs
- Directory tree uses Unicode box-drawing

### Phase 6: Update External References and Validate
**Objective**: Update CLAUDE.md references, create link validation script, final verification
**Complexity**: Medium
**Dependencies**: Phase 5 complete

Tasks:
- [ ] Update CLAUDE.md references:
  - Search for all `.claude/docs/` references: `grep -n '\.claude/docs/' CLAUDE.md`
  - Update each reference to new subdirectory path
  - Verify section references still point to correct files
  - Test slash commands that reference docs/ (e.g., /setup)
- [ ] Update command file references:
  - Search command files for docs/ references: `grep -r '\.claude/docs/' .claude/commands/`
  - Update references to new paths
- [ ] Update agent file references:
  - Search agent files for docs/ references: `grep -r '\.claude/docs/' .claude/agents/`
  - Update references to new paths
- [ ] Create link validation script `.claude/lib/validate-doc-links.sh`:
  - Parse all markdown files for `[text](path.md)` links
  - Verify each link resolves to existing file
  - Report broken links with file:line references
  - Make script executable
- [ ] Run link validation on entire docs/ directory
- [ ] Fix any broken links identified
- [ ] Final verification: manually test navigation from docs/README.md to subdirectories to individual files

Testing:
```bash
# Verify CLAUDE.md updated
grep '\.claude/docs/[^/]*.md' CLAUDE.md && echo "ERROR: Flat structure references remain in CLAUDE.md" || echo "✓ CLAUDE.md references updated"

# Run link validation
.claude/lib/validate-doc-links.sh .claude/docs/

# Count total files in new structure
echo "Total docs files: $(find .claude/docs -name '*.md' | wc -l)"
echo "Expected: ~37 (4 subdirectory READMEs + main README + 28 content files + archive files)"
```

Validation:
- CLAUDE.md references all updated
- Command and agent file references updated
- Link validation script created and executable
- No broken links reported by validation script
- Manual navigation test passes

## Testing Strategy

### Unit Testing (Per Phase)
- Each phase includes specific validation commands
- File existence checks
- Content verification (grep for expected sections)
- Link format checks

### Integration Testing (Cross-Phase)
- Link validation across all subdirectories
- Navigation from README → subdirectory → file → back navigation
- Cross-category link resolution
- External reference validation (CLAUDE.md, commands/, agents/)

### Manual Testing
- Navigate from docs/README.md through all 4 subdirectories
- Click representative links to verify resolution
- Test search patterns (find docs by category, by topic, by user role)
- Verify breadcrumb navigation works in both directions

### Validation Criteria
- All 27 files successfully moved
- 1 new file (data-management.md) created
- 4 subdirectory READMEs created
- Main README.md updated
- 100% of internal links resolve
- CLAUDE.md references updated
- archive/ redirects updated
- Link validation script created

## Documentation Requirements

### Files to Create
1. `.claude/docs/guides/data-management.md` - Centralized data/ guide
2. `.claude/docs/reference/README.md` - Reference directory index
3. `.claude/docs/guides/README.md` - Guides directory index
4. `.claude/docs/concepts/README.md` - Concepts directory index
5. `.claude/docs/workflows/README.md` - Workflows directory index
6. `.claude/templates/readme-template.md` - Standard README template
7. `.claude/lib/validate-doc-links.sh` - Link validation utility

### Files to Update
1. `.claude/docs/README.md` - Main documentation index
2. All 27 moved documentation files (link updates)
3. `CLAUDE.md` - External references
4. `.claude/commands/*.md` - Any command file doc references
5. `.claude/agents/*.md` - Any agent file doc references
6. `.claude/docs/archive/*.md` - Redirect links

### Documentation Standards
- Follow writing-standards.md (timeless, present-focused)
- Use Unicode box-drawing for directory trees
- No emojis in file content
- Consistent breadcrumb navigation format
- CommonMark markdown specification

## Dependencies

### External Dependencies
- None (pure documentation reorganization)

### Internal Dependencies
- Phase order must be followed sequentially
- CLAUDE.md must be updated before testing slash commands
- Link validation requires all files moved and links updated first

### Tools Required
- `git` for file moves and tracking
- `grep` for link discovery and validation
- `sed` for batch link updates (if needed)
- Standard bash utilities (ls, test, wc, find)

## Risk Assessment

### High Risk
- **Link Breakage**: 248+ internal links must be updated correctly
  - Mitigation: Create link validation script, test incrementally
- **CLAUDE.md Breakage**: System functionality depends on correct references
  - Mitigation: Update CLAUDE.md carefully, test slash commands after update

### Medium Risk
- **External Reference Breakage**: Commands/agents may reference docs/
  - Mitigation: Grep for all external references, update systematically
- **Archive Redirect Confusion**: Users may have bookmarked archive files
  - Mitigation: Clear redirect messages, maintain archive/README.md

### Low Risk
- **File Organization**: Moving files is straightforward with git mv
  - Mitigation: Use git mv to preserve history, verify with file counts
- **README Creation**: Template makes README creation consistent
  - Mitigation: Follow template exactly, copy-paste-adapt approach

## Notes

### Implementation Order Rationale
1. **Phase 1**: Foundation must exist before moving files
2. **Phase 2**: Files must be moved before updating links (simpler to update in place)
3. **Phase 3**: New file created after migration to avoid extra move operation
4. **Phase 4**: Internal links updated before external to isolate link scope
5. **Phase 5**: READMEs created after links updated (READMEs will have correct links from start)
6. **Phase 6**: External updates and validation last (complete internal consistency first)

### Performance Expectations
Based on research:
- **Onboarding Speed**: 40-45% faster user onboarding (research-backed)
- **Discoverability**: Users find docs in ≤2 clicks from main README
- **Maintenance**: Standardized structure reduces future reorganization effort
- **Scalability**: Supports growth from 27 to 50+ files without restructuring

### Future Enhancements
- Consider adding visual diagrams showing documentation architecture
- Implement automated link checking in pre-commit hook
- Create documentation metrics dashboard (most accessed docs, outdated docs)
- Add documentation search optimization (keywords, tags, metadata)

## Git Commit Strategy

### Commit After Each Phase
- **Phase 1**: "docs: Create Diataxis-aligned subdirectory structure"
- **Phase 2**: "docs: Migrate 27 files to subdirectories (reference, guides, concepts, workflows)"
- **Phase 3**: "docs: Add centralized data-management.md guide"
- **Phase 4**: "docs: Update all internal cross-references to new subdirectory structure"
- **Phase 5**: "docs: Create subdirectory READMEs and update main index"
- **Phase 6**: "docs: Update external references and add link validation"

### Commit Message Format
```
docs: [Phase description]

- [Task 1 completed]
- [Task 2 completed]
- [Task 3 completed]

Refs: .claude/specs/plans/071_docs_reorganization_diataxis_structure.md
Research: .claude/specs/reports/053_docs_reorganization_structure_analysis.md
```

## Plan Metadata

**Total Estimated Effort**: 6-8 hours (phased over 1-2 days)

**Complexity Breakdown**:
- Phase 1: Low (30 minutes)
- Phase 2: Medium (1 hour)
- Phase 3: Medium (1.5-2 hours)
- Phase 4: High (2-3 hours) - Most time-intensive
- Phase 5: Medium (1-1.5 hours)
- Phase 6: Medium (1-1.5 hours)

**Success Indicators**:
- Zero broken documentation links
- All slash commands still functional
- User can navigate docs/ structure intuitively
- New contributors find relevant docs in <2 minutes
- data/ ecosystem fully documented

**Rollback Plan**:
If critical issues arise, git history preserves all file moves. Revert commits in reverse order (Phase 6 → Phase 5 → ... → Phase 1).
