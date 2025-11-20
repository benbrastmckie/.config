# Guides Directory Systematic Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Systematic refactor of .claude/docs/guides/ directory
- **Scope**: Archive unused files, clean split file legacy content, create subdirectory organization, update all references
- **Estimated Phases**: 5
- **Estimated Hours**: 11
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 262.5
- **Research Reports**:
  - [Guides Inventory and Usage](../reports/001_guides_inventory_and_usage.md)
  - [Content Overlap Analysis](../reports/002_content_overlap_analysis.md)
  - [Categorization and Organization](../reports/003_categorization_and_organization.md)
  - [Research Overview](../reports/OVERVIEW.md)

## Overview

The `.claude/docs/guides/` directory has become bloated with 78 files in a flat structure. This refactor systematically:
1. Archives 12 unused/redirect stub files
2. Cleans legacy content from 4 split documentation hub files (~4800 lines)
3. Creates 5 logical subdirectories (commands/, development/, orchestration/, patterns/, templates/)
4. Moves 55+ active files to appropriate subdirectories
5. Updates ~195 references throughout the codebase

The goal is improved discoverability, reduced redundancy, and easier maintenance while preserving all active functionality.

## Research Summary

Key findings from research reports:

**From Guides Inventory Analysis (001)**:
- 78 total files with significant bloat from split documentation
- 10 high-usage guides (orchestration-best-practices, agent-development, command-development) with 10+ references
- 12 files identified for archiving (redirect stubs and unused content)
- 7 split documentation families with legacy content duplication

**From Content Overlap Analysis (002)**:
- Agent development family: ~2000 duplicate lines
- Command patterns family: ~1400 duplicate lines
- Execution enforcement family: ~1400 duplicate lines
- Total estimated redundancy: ~5800 lines
- 12 redirect stub files providing no unique content

**From Categorization and Organization (003)**:
- Proposed 5-subdirectory structure: commands/, development/, orchestration/, patterns/, templates/
- ~195 reference updates required across codebase
- Estimated effort: 8-13 hours total
- Risk mitigation through phased approach with validation

Recommended approach: Full refactor with phased execution, starting with low-risk archiving and progressing to higher-risk reference updates.

## Success Criteria

- [ ] All 12 identified files archived to `.claude/docs/archive/guides/`
- [ ] 4 split file hub files cleaned of legacy content (agent-development-guide.md, command-patterns.md, execution-enforcement-guide.md, command-development-index.md)
- [ ] 5 subdirectories created with README.md index files
- [ ] All active guide files moved to appropriate subdirectories
- [ ] All ~195 references updated to new paths
- [ ] No broken links in main documentation files (CLAUDE.md, docs/README.md, guides/README.md)
- [ ] Total guides directory file count reduced from 78 to ~55 active files
- [ ] Validation script confirms all links resolve correctly

## Technical Design

### Directory Structure After Refactor

```
.claude/docs/guides/
├── README.md                           # Updated index with new structure
├── commands/                           # Command-specific documentation (12 files)
│   ├── README.md
│   ├── build-command-guide.md
│   ├── debug-command-guide.md
│   ├── plan-command-guide.md
│   └── ... (9 more command guides)
├── development/                        # Creating commands and agents (15 files)
│   ├── README.md
│   ├── command-development/            # 5 files
│   └── agent-development/              # 6 files
├── orchestration/                      # Workflow orchestration (10 files)
│   ├── README.md
│   ├── orchestration-best-practices.md
│   └── ... (8 more orchestration guides)
├── patterns/                           # Reusable patterns (18 files)
│   ├── README.md
│   ├── command-patterns/               # 4 files
│   ├── execution-enforcement/          # 4 files
│   └── ... (standalone pattern guides)
├── templates/                          # File templates (3 files)
│   ├── README.md
│   └── _template-*.md files
└── archive/                            # Deprecated content (12+ files)
```

### Migration Strategy

1. **Backup First**: Create backup of current guides/ directory before any changes
2. **Archive Phase**: Move unused files without updating references (low risk)
3. **Clean Phase**: Remove legacy content from hub files (low risk)
4. **Structure Phase**: Create subdirectories and move files (medium risk)
5. **Update Phase**: Update all references with scripted approach (higher risk)
6. **Validate Phase**: Comprehensive link validation (verification)

### Reference Update Approach

Use scripted batch updates for consistency:
- Pattern: `guides/filename.md` → `guides/category/filename.md`
- Create sed/perl script for bulk path replacement
- Update one category at a time to minimize risk
- Validate links after each batch

## Implementation Phases

### Phase 1: Backup and Archive [COMPLETE]
dependencies: []

**Objective**: Create backup and archive unused/redirect stub files to reduce clutter

**Complexity**: Low

Tasks:
- [x] Create backup of current guides/ directory to `.claude/backups/guides-refactor-$(date +%Y%m%d)/`
- [x] Create archive directory structure at `.claude/docs/archive/guides/`
- [x] Archive redirect stub files:
  - [x] Move `using-agents.md` to archive (file: .claude/docs/guides/using-agents.md)
  - [x] Move `command-examples.md` to archive (file: .claude/docs/guides/command-examples.md)
  - [x] Move `migration-validation.md` to archive (file: .claude/docs/guides/migration-validation.md)
  - [x] Move `testing-standards.md` to archive (file: .claude/docs/guides/testing-standards.md)
  - [x] Move `setup-modes.md` to archive (file: .claude/docs/guides/setup-modes.md)
  - [x] Move `orchestrate-command-index.md` to archive (file: .claude/docs/guides/orchestrate-command-index.md)
- [x] Archive unused/minimal content files:
  - [x] Move `git-recovery-guide.md` to archive (file: .claude/docs/guides/git-recovery-guide.md)
  - [x] Move `skills-vs-subagents-decision.md` to archive (file: .claude/docs/guides/skills-vs-subagents-decision.md)
  - [x] Move `atomic-allocation-migration.md` to archive (file: .claude/docs/guides/atomic-allocation-migration.md)
  - [x] Move `link-conventions-guide.md` to archive (file: .claude/docs/guides/link-conventions-guide.md)
  - [x] Move `supervise-guide.md` to archive (file: .claude/docs/guides/supervise-guide.md)
  - [x] Move `workflow-type-selection-guide.md` to archive (file: .claude/docs/guides/workflow-type-selection-guide.md)
- [x] Update any direct references to archived files (expected: minimal)

Testing:
```bash
# Verify backup created
ls -la ~/.config/.claude/backups/guides-refactor-*/

# Verify archived files moved
ls -la ~/.config/.claude/docs/archive/guides/

# Count files remaining in guides/
find ~/.config/.claude/docs/guides -maxdepth 1 -name "*.md" | wc -l
# Expected: 66 files (78 - 12 archived)
```

**Expected Duration**: 1.5 hours

---

### Phase 2: Clean Split File Legacy Content [COMPLETE]
dependencies: [1]

**Objective**: Remove legacy duplicated content from split documentation hub files, reducing ~4800 lines of redundancy

**Complexity**: Medium

Tasks:
- [x] Clean agent-development-guide.md (file: .claude/docs/guides/agent-development-guide.md):
  - [x] Keep lines 1-26 (navigation table and quick start)
  - [x] Remove lines 27-2178 (legacy content marked "Legacy Content Below")
  - [x] Add redirect notice to split files
  - [x] Expected reduction: ~2000 lines
- [x] Clean command-patterns.md (file: .claude/docs/guides/command-patterns.md):
  - [x] Keep lines 1-35 (navigation table)
  - [x] Remove remaining legacy content
  - [x] Add redirect notice to split files
  - [x] Expected reduction: ~1400 lines
- [x] Clean execution-enforcement-guide.md (file: .claude/docs/guides/execution-enforcement-guide.md):
  - [x] Identify legacy content section
  - [x] Keep navigation structure only
  - [x] Add redirect notice to split files
  - [x] Expected reduction: ~1400 lines
- [x] Audit command-development-index.md (file: .claude/docs/guides/command-development-index.md):
  - [x] Verify it only contains navigation
  - [x] Remove any duplicated content
- [x] Verify split files are complete and standalone:
  - [x] agent-development-fundamentals.md has complete "Creating Agents" content
  - [x] agent-development-patterns.md has complete "Invocation Patterns" content
  - [x] agent-development-testing.md has complete "Testing" content
  - [x] command-patterns-overview.md has complete "Pattern Index" content
  - [x] execution-enforcement-overview.md has complete "Introduction" content

Testing:
```bash
# Verify line count reductions
wc -l ~/.config/.claude/docs/guides/agent-development-guide.md
# Expected: <200 lines (down from 2178)

wc -l ~/.config/.claude/docs/guides/command-patterns.md
# Expected: <200 lines (down from 1519)

wc -l ~/.config/.claude/docs/guides/execution-enforcement-guide.md
# Expected: <200 lines (down from 1584)

# Verify split files still reference correctly
grep -l "agent-development-fundamentals" ~/.config/.claude/docs/guides/*.md
```

**Expected Duration**: 2 hours

---

### Phase 3: Create Subdirectory Structure [COMPLETE]
dependencies: [2]

**Objective**: Create the 5 logical subdirectories with README files and move all active guides to appropriate locations

**Complexity**: High

Tasks:
- [x] Create subdirectory structure:
  - [x] Create `.claude/docs/guides/commands/` directory
  - [x] Create `.claude/docs/guides/development/` directory
  - [x] Create `.claude/docs/guides/development/command-development/` subdirectory
  - [x] Create `.claude/docs/guides/development/agent-development/` subdirectory
  - [x] Create `.claude/docs/guides/orchestration/` directory
  - [x] Create `.claude/docs/guides/patterns/` directory
  - [x] Create `.claude/docs/guides/patterns/command-patterns/` subdirectory
  - [x] Create `.claude/docs/guides/patterns/execution-enforcement/` subdirectory
  - [x] Create `.claude/docs/guides/templates/` directory
- [x] Create README.md for each subdirectory with purpose and file index:
  - [x] commands/README.md - Command-specific documentation index
  - [x] development/README.md - Development guides index
  - [x] orchestration/README.md - Orchestration guides index
  - [x] patterns/README.md - Patterns guides index
  - [x] templates/README.md - Templates index
- [x] Move files to commands/ subdirectory (12 files):
  - [x] Move build-command-guide.md
  - [x] Move collapse-command-guide.md
  - [x] Move convert-docs-command-guide.md
  - [x] Move debug-command-guide.md
  - [x] Move document-command-guide.md
  - [x] Move expand-command-guide.md
  - [x] Move optimize-claude-command-guide.md
  - [x] Move plan-command-guide.md
  - [x] Move research-command-guide.md
  - [x] Move revise-command-guide.md
  - [x] Move setup-command-guide.md
  - [x] Move test-command-guide.md
- [x] Move files to development/command-development/ (5 files):
  - [x] Move command-development-fundamentals.md
  - [x] Move command-development-advanced-patterns.md
  - [x] Move command-development-examples-case-studies.md
  - [x] Move command-development-standards-integration.md
  - [x] Move command-development-troubleshooting.md
- [x] Move files to development/agent-development/ (6 files):
  - [x] Move agent-development-fundamentals.md
  - [x] Move agent-development-patterns.md
  - [x] Move agent-development-testing.md
  - [x] Move agent-development-troubleshooting.md
  - [x] Move agent-development-advanced.md
  - [x] Move agent-development-examples.md
- [x] Move additional development files:
  - [x] Move model-selection-guide.md to development/
  - [x] Move model-rollback-guide.md to development/
  - [x] Move using-utility-libraries.md to development/
- [x] Move files to orchestration/ (10 files):
  - [x] Move orchestration-best-practices.md
  - [x] Move orchestration-troubleshooting.md
  - [x] Move orchestrate-overview-architecture.md
  - [x] Move orchestrate-phases-implementation.md
  - [x] Move creating-orchestrator-commands.md
  - [x] Move state-machine-orchestrator-development.md
  - [x] Move state-machine-migration-guide.md
  - [x] Move hierarchical-supervisor-guide.md
  - [x] Move workflow-classification-guide.md
  - [x] Move state-variable-decision-guide.md
- [x] Move files to patterns/command-patterns/ (4 files):
  - [x] Move command-patterns-overview.md
  - [x] Move command-patterns-agents.md
  - [x] Move command-patterns-checkpoints.md
  - [x] Move command-patterns-integration.md
- [x] Move files to patterns/execution-enforcement/ (4 files):
  - [x] Move execution-enforcement-overview.md
  - [x] Move execution-enforcement-patterns.md
  - [x] Move execution-enforcement-migration.md
  - [x] Move execution-enforcement-validation.md
- [x] Move standalone pattern files to patterns/ (13 files):
  - [x] Move logging-patterns.md
  - [x] Move testing-patterns.md
  - [x] Move error-enhancement-guide.md
  - [x] Move data-management.md
  - [x] Move standards-integration.md
  - [x] Move refactoring-methodology.md
  - [x] Move performance-optimization.md
  - [x] Move phase-0-optimization.md
  - [x] Move implementation-guide.md
  - [x] Move revision-guide.md
  - [x] Move enhanced-topic-generation-guide.md
  - [x] Move docs-accuracy-analyzer-agent-guide.md
  - [x] Move revision-specialist-agent-guide.md
- [x] Move template files to templates/ (3 files):
  - [x] Move _template-bash-block.md
  - [x] Move _template-command-guide.md
  - [x] Move _template-executable-command.md
- [x] Archive cleaned hub files:
  - [x] Move agent-development-guide.md to archive/ (now just navigation)
  - [x] Move command-patterns.md to archive/ (now just navigation)
  - [x] Move execution-enforcement-guide.md to archive/ (now just navigation)
  - [x] Move command-development-index.md to archive/ (now just navigation)

Testing:
```bash
# Verify subdirectory structure
tree ~/.config/.claude/docs/guides/ -d

# Count files per subdirectory
for dir in commands development orchestration patterns templates; do
  echo "$dir: $(find ~/.config/.claude/docs/guides/$dir -name "*.md" | wc -l) files"
done

# Verify no files left in root guides/ (except README.md)
find ~/.config/.claude/docs/guides -maxdepth 1 -name "*.md" -not -name "README.md"
# Expected: empty output
```

**Expected Duration**: 3 hours

---

### Phase 4: Update All References [COMPLETE]
dependencies: [3]

**Objective**: Update all ~195 references throughout the codebase to use new paths

**Complexity**: High

Tasks:
- [x] Generate reference inventory:
  - [x] Create list of all old paths to new paths mappings
  - [x] Identify all files containing guide references using grep
  - [x] Categorize by source directory (docs/, commands/, agents/, CLAUDE.md)
- [x] Update references in primary documentation files:
  - [x] Update `.claude/CLAUDE.md` guide references
  - [x] Update `.claude/docs/README.md` guide links
  - [x] Update `.claude/docs/guides/README.md` to reflect new structure entirely
- [x] Update references in docs/reference/ (estimated 30 updates):
  - [x] Update command-reference.md
  - [x] Update agent-reference.md
  - [x] Update orchestration-reference.md
  - [x] Update other reference files
- [x] Update references in docs/concepts/ (estimated 20 updates):
  - [x] Update directory-protocols.md
  - [x] Update hierarchical-agents.md
  - [x] Update other concept files
- [x] Update references in docs/troubleshooting/ (estimated 15 updates):
  - [x] Update all troubleshooting guides with new paths
- [x] Update references in commands/ directory (estimated 40 updates):
  - [x] Update build.md
  - [x] Update plan.md
  - [x] Update debug.md
  - [x] Update research.md
  - [x] Update revise.md
  - [x] Update setup.md
  - [x] Update other command files
- [x] Update references in agents/ directory (estimated 30 updates):
  - [x] Update plan-architect.md
  - [x] Update research-specialist.md
  - [x] Update implementer-coordinator.md
  - [x] Update debug-analyst.md
  - [x] Update other agent files
- [x] Update internal references within moved guide files (estimated 60 updates):
  - [x] Update cross-references between command guides
  - [x] Update cross-references between development guides
  - [x] Update cross-references between orchestration guides
  - [x] Update cross-references between pattern guides
- [x] Fix any obsolete /coordinate command references:
  - [x] Replace with /build or /plan as appropriate
  - [x] Files affected: orchestration-troubleshooting.md, hierarchical-supervisor-guide.md

Testing:
```bash
# Search for any remaining old paths
grep -r "guides/command-development-" ~/.config/.claude --include="*.md" | grep -v "archive"
# Expected: empty output

grep -r "guides/agent-development-" ~/.config/.claude --include="*.md" | grep -v "archive" | grep -v "guides/development"
# Expected: empty output

# Validate links in key files
# Check CLAUDE.md links
grep -o '\[.*\](guides/[^)]*\.md)' ~/.config/CLAUDE.md | while read link; do
  path=$(echo "$link" | grep -o 'guides/[^)]*\.md')
  [ -f ~/.config/.claude/docs/$path ] || echo "Broken: $path"
done
```

**Expected Duration**: 3 hours

---

### Phase 5: Validation and Documentation [COMPLETE]
dependencies: [4]

**Objective**: Comprehensive validation of all links and update documentation to reflect new structure

**Complexity**: Medium

Tasks:
- [x] Create and run link validation script:
  - [x] Scan all .md files in .claude/ for guide links
  - [x] Verify each link target exists
  - [x] Generate report of broken links
  - [x] Fix any broken links identified
- [x] Update guides/README.md with complete new structure:
  - [x] Update overview section with subdirectory structure
  - [x] Update file listings for each subdirectory
  - [x] Add navigation section for quick access
  - [x] Update file counts and descriptions
- [x] Validate search functionality:
  - [x] Test grep searches for common patterns still work
  - [x] Verify glob patterns for guide discovery work
- [x] Final verification checks:
  - [x] Count total files in guides/ (expected: ~55 active)
  - [x] Count archived files (expected: 16+)
  - [x] Verify no orphaned files in root guides/
  - [x] Verify all subdirectory READMEs complete
- [x] Document migration for future reference:
  - [x] Update docs/archive/guides/ with migration notice
  - [x] Note date and scope of refactor
- [x] Clean up backup if all validations pass:
  - [x] Keep backup for 1 week for rollback option
  - [x] Document backup location in archive notice

Testing:
```bash
# Final structure validation
echo "=== Guides Directory Structure ==="
tree ~/.config/.claude/docs/guides/ -d

echo "=== File Counts ==="
echo "Total active: $(find ~/.config/.claude/docs/guides -name "*.md" -not -path "*archive*" | wc -l)"
echo "Archived: $(find ~/.config/.claude/docs/archive/guides -name "*.md" | wc -l)"

echo "=== Subdirectory Counts ==="
for dir in commands development orchestration patterns templates; do
  echo "$dir: $(find ~/.config/.claude/docs/guides/$dir -name "*.md" | wc -l)"
done

# Comprehensive link validation
find ~/.config/.claude/docs -name "*.md" -exec grep -l "guides/" {} \; | while read file; do
  grep -o 'guides/[^)]*\.md' "$file" | while read link; do
    base=$(dirname "$file")
    [ -f "$base/../$link" ] || echo "Broken in $file: $link"
  done
done
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Approach

Testing follows a progressive validation approach with checks after each phase:

1. **Phase 1 (Archive)**: Verify backup creation, file counts after archiving
2. **Phase 2 (Clean)**: Verify line count reductions, split file completeness
3. **Phase 3 (Structure)**: Verify directory tree, file distribution
4. **Phase 4 (References)**: Verify no old paths remain, links resolve
5. **Phase 5 (Validation)**: Comprehensive link checking, final structure validation

### Key Validation Points

- **Backup Integrity**: Backup contains all 78 original files
- **Archive Completeness**: All 12+ identified files in archive
- **Structure Correctness**: 5 subdirectories with proper README files
- **Reference Accuracy**: Zero broken links in primary documentation
- **File Count Target**: ~55 active files (down from 78)

### Rollback Procedure

If issues discovered after Phase 4:
1. Check backup location: `.claude/backups/guides-refactor-YYYYMMDD/`
2. Remove current guides/ directory
3. Restore from backup: `cp -r backup/guides .claude/docs/guides`
4. Revert any reference updates in git

## Documentation Requirements

### Files to Update

1. **guides/README.md**: Complete rewrite with new structure navigation
2. **docs/README.md**: Update guide links section
3. **CLAUDE.md**: Verify all guide references use new paths
4. **Each subdirectory README.md**: Create with purpose, file index, cross-links

### Documentation Format

- Use clear headings for each subdirectory section
- Include file counts and brief descriptions
- Add cross-links between related sections
- Follow existing documentation style (no emojis, clear navigation)

## Dependencies

### Prerequisites

- Git working tree clean (or changes committed) before starting
- No active branches with pending guide edits
- Sufficient disk space for backup (~1.5MB)

### External Dependencies

None - this is an internal documentation refactor.

### Integration Points

- Commands that reference guides (build, plan, debug, research, revise, setup)
- Agents that reference guides (plan-architect, research-specialist, implementer)
- Main CLAUDE.md configuration file
- Documentation index at docs/README.md

## Risk Mitigation

### High-Risk Operations

1. **Phase 4 (Reference Updates)**: Many files affected
   - Mitigation: Script batch updates, validate after each batch
   - Rollback: Git revert of reference changes

2. **Phase 3 (File Moves)**: Many files relocated
   - Mitigation: Git mv to preserve history
   - Rollback: Restore from backup

### Contingency Plans

- **Broken Links Discovered**: Use backup to restore original, fix mapping
- **Performance Issues**: Phase 5 can validate incrementally if needed
- **Time Overrun**: Phase 3 and 4 can be split into sub-phases by subdirectory
