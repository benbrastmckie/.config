# Guides Directory Refactor Research Overview

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Systematic Refactor of .claude/docs/guides/
- **Report Type**: executive summary

## Executive Summary

Research confirms the `.claude/docs/guides/` directory requires systematic reorganization. The 78-file flat structure contains significant bloat: split documentation families retain ~5800 lines of duplicated legacy content, 12 redirect stub files provide no value, and related content is scattered without logical grouping. The proposed refactor reorganizes content into 5 subdirectories (commands/, development/, orchestration/, patterns/, templates/), archives unused files, and cleans split file legacy content. This reduces file count by ~30%, eliminates ~4800 lines of duplication, and improves discoverability. Estimated effort: 8-13 hours with ~195 reference updates required.

## Key Findings

### 1. Directory Bloat Sources

- **78 total files** in flat directory structure
- **Split file families** (4): Retain legacy content after splitting (agent-dev, command-patterns, execution-enforcement, command-dev)
- **Redirect stubs** (12): Files that only redirect to other content
- **Unused/minimal content** (6): git-recovery, supervise-guide, link-conventions, etc.

### 2. Usage Pattern Distribution

| Category | Files | Status |
|----------|-------|--------|
| High usage (10+ refs) | 10 | KEEP |
| Medium usage (5-9 refs) | 10 | KEEP |
| Low usage (2-4 refs) | 12 | REVIEW |
| Minimal usage (0-1 refs) | 12 | ARCHIVE |
| Split fragments | 18 | ORGANIZE |
| Templates | 3 | KEEP |

### 3. Content Overlap

- **Agent development family**: ~2000 duplicate lines
- **Command patterns family**: ~1400 duplicate lines
- **Execution enforcement family**: ~1400 duplicate lines
- **Redirect stubs**: ~300 minimal lines
- **Total estimated**: ~5800 lines of redundancy

### 4. Reorganization Impact

- **Files to archive**: 12 (redirect stubs and unused)
- **Files to reorganize**: 59 (into subdirectories)
- **Hub files to clean**: 4 (remove legacy content)
- **Reference updates**: ~195 path changes
- **Active file target**: ~55 files (down from 78)

## Report Index

### [001_guides_inventory_and_usage.md](001_guides_inventory_and_usage.md)

**Content**: Complete inventory of all 78 guide files with:
- File sizes and line counts
- Reference counts from codebase search
- Usage assessment (ACTIVE/REVIEW/ARCHIVE)
- Split file family documentation

**Key Tables**: High/Medium/Low usage guides, split documentation families, template files

---

### [002_content_overlap_analysis.md](002_content_overlap_analysis.md)

**Content**: Detailed redundancy analysis including:
- Split documentation family overlap (agent-dev, command-patterns, execution-enforcement)
- Redirect stub file inventory
- Topical overlap between independent files
- Obsolete coordinate command references

**Key Tables**: Quantified overlap summary by category

---

### [003_categorization_and_organization.md](003_categorization_and_organization.md)

**Content**: Proposed directory structure and migration plan:
- 5 subdirectory structure (commands/, development/, orchestration/, patterns/, templates/)
- Category definitions with inclusion criteria
- File-by-file categorization
- Migration impact analysis (~195 reference updates)
- 4-phase implementation plan with timelines

**Key Diagrams**: Proposed directory tree structure

## Implementation Priorities

### High Priority (Immediate value, low risk)

1. **Archive redirect stubs** (12 files)
   - Immediate: Cleaner directory
   - Risk: Low (minimal references)
   - Effort: 1-2 hours

2. **Clean split file legacy content** (4 hub files)
   - Immediate: ~4800 lines eliminated
   - Risk: Low (content exists in splits)
   - Effort: 1-2 hours

### Medium Priority (High value, medium risk)

3. **Create subdirectory structure** (5 directories)
   - Value: Logical grouping, discoverability
   - Risk: Medium (requires reference updates)
   - Effort: 2-3 hours

### Lower Priority (Comprehensive, higher risk)

4. **Update all references** (~195 updates)
   - Value: Complete migration
   - Risk: Higher (many files affected)
   - Effort: 3-4 hours

## Risk Mitigation

### Before Starting

1. Create backup of `.claude/docs/guides/`
2. Generate list of all guide references with grep
3. Create migration script for batch path updates

### During Migration

1. Update one subdirectory at a time
2. Test links after each batch
3. Commit after each phase

### After Completion

1. Validate all links in key files (README.md, CLAUDE.md)
2. Run documentation validation if available
3. Update guides/README.md index

## Recommended Approach

**Minimum Viable Refactor** (4-6 hours):
1. Archive 12 unused files
2. Clean 4 hub files of legacy content
3. Create subdirectories without moving files yet
4. Update guides/README.md with new structure

**Full Refactor** (8-13 hours):
- Includes all of above plus:
5. Move files to subdirectories
6. Update all ~195 references
7. Create subdirectory READMEs
8. Validation and testing

## References

- `/home/benjamin/.config/.claude/docs/guides/` - 78 files totaling ~1.3MB
- `/home/benjamin/.config/.claude/docs/guides/README.md` - Lines 1-372
- Report 001: Complete inventory with usage analysis
- Report 002: Overlap quantification (~5800 duplicate lines)
- Report 003: Proposed structure and migration plan
