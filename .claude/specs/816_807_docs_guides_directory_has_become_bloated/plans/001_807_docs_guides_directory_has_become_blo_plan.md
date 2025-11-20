# Broken Cross-References Fix Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix broken cross-references from guides directory refactor
- **Scope**: Update ~150 broken links across ~50 files resulting from guides reorganization
- **Estimated Phases**: 7
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 168
- **Research Reports**:
  - [Broken References Inventory](/home/benjamin/.config/.claude/specs/816_807_docs_guides_directory_has_become_bloated/reports/001_broken_references_inventory.md)
  - [Reference Fix Mapping](/home/benjamin/.config/.claude/specs/816_807_docs_guides_directory_has_become_bloated/reports/002_reference_fix_mapping.md)
  - [Executive Overview](/home/benjamin/.config/.claude/specs/816_807_docs_guides_directory_has_become_bloated/reports/OVERVIEW.md)

## Overview

The guides directory refactor (spec 807) successfully reorganized `.claude/docs/guides/` from 77 files at root level to a hierarchical structure with 5 subdirectories (commands/, development/, orchestration/, patterns/, templates/). This created ~150 broken cross-references across ~50 files in the codebase. This plan provides a systematic approach to fix all broken references using sed batch replacements organized by destination subdirectory.

## Research Summary

Key findings from research:
- **150+ broken references** identified across the codebase
- **~50 files** require updates, with ~20 high-priority files
- Most affected file: `docs/README.md` with 45+ broken references
- Most commonly broken paths: `agent-development-guide.md` (30+) and `command-development-guide.md` (25+)
- **44 files moved** to new subdirectory locations
- **8 files archived** with suggested replacements (command-patterns, execution-enforcement, imperative-language guides)

Recommended approach: Execute sed replacements in phases by destination subdirectory, testing after each phase and committing for easy rollback.

## Success Criteria

- [ ] All links in docs/README.md resolve correctly
- [ ] All links in docs/reference/*.md files resolve correctly
- [ ] All internal guide cross-references within guides/ work
- [ ] No broken links remain in docs/workflows/*.md and docs/concepts/*.md
- [ ] Agent and command README references work
- [ ] Zero broken links reported by manual verification of key navigation paths

## Technical Design

### Approach
Use sed-based batch replacements to update references systematically. Files are organized by source directory and target subdirectory for efficient processing.

### Key Transformations
1. `guides/X.md` → `guides/development/X.md` (development guides)
2. `guides/X.md` → `guides/patterns/X.md` (pattern guides)
3. `guides/X.md` → `guides/orchestration/X.md` (orchestration guides)
4. `guides/X.md` → `guides/commands/X.md` (command guides)
5. `guides/_template-X.md` → `guides/templates/_template-X.md` (templates)
6. Split files (agent-development, command-development, command-patterns, execution-enforcement) → new primary entry points

### File Groups to Process
- **docs/reference/**: 16 files (highest priority)
- **docs/workflows/**: 7 files
- **docs/concepts/**: 3 files
- **docs/guides/**: 15+ internal cross-references
- **agents/**: 3 files
- **commands/templates/**: 1 file
- **docs/architecture/**: 1 file

## Implementation Phases

### Phase 1: High-Priority Reference Files - Development Guides [COMPLETE]
dependencies: []

**Objective**: Fix references to development guides in the most critical documentation files

**Complexity**: Medium

Tasks:
- [x] Update agent-development-guide.md references to new path (file: multiple in docs/reference/)
  ```bash
  # Run from /home/benjamin/.config/.claude
  find docs/reference docs/workflows docs/concepts agents commands -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/agent-development-guide\.md|guides/development/agent-development/agent-development-fundamentals.md|g' {} +
  ```
- [x] Update command-development-guide.md references to new path (file: multiple in docs/)
  ```bash
  find docs/reference docs/workflows docs/concepts agents commands -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/command-development-guide\.md|guides/development/command-development/command-development-fundamentals.md|g' {} +
  ```
- [x] Update model-selection-guide.md reference (file: docs/reference/code-standards.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/model-selection-guide\.md|guides/development/model-selection-guide.md|g' {} +
  ```
- [x] Update using-utility-libraries.md references (file: multiple in docs/reference/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/using-utility-libraries\.md|guides/development/using-utility-libraries.md|g' {} +
  ```
- [x] Update command-development-fundamentals.md reference (file: docs/reference/command-authoring-standards.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/command-development-fundamentals\.md|guides/development/command-development/command-development-fundamentals.md|g' {} +
  ```

Testing:
```bash
# Verify no remaining old paths in processed files
grep -r "guides/agent-development-guide\.md" docs/reference docs/workflows docs/concepts agents commands --include="*.md" | grep -v archive | grep -v backups
grep -r "guides/command-development-guide\.md" docs/reference docs/workflows docs/concepts agents commands --include="*.md" | grep -v archive | grep -v backups
# Should return no results
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Pattern Guides [COMPLETE]
dependencies: [1]

**Objective**: Fix references to pattern guides across the codebase

**Complexity**: Medium

Tasks:
- [x] Update error-enhancement-guide.md references (file: multiple in docs/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/error-enhancement-guide\.md|guides/patterns/error-enhancement-guide.md|g' {} +
  ```
- [x] Update data-management.md reference (file: docs/workflows/README.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/data-management\.md|guides/patterns/data-management.md|g' {} +
  ```
- [x] Update performance-optimization.md references (file: multiple in docs/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/performance-optimization\.md|guides/patterns/performance-optimization.md|g' {} +
  ```
- [x] Update logging-patterns.md references (file: docs/README.md, output-formatting-standards.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/logging-patterns\.md|guides/patterns/logging-patterns.md|g' {} +
  ```
- [x] Update standards-integration.md references (file: multiple in docs/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/standards-integration\.md|guides/patterns/standards-integration.md|g' {} +
  ```
- [x] Update phase-0-optimization.md references (file: docs/workflows/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/phase-0-optimization\.md|guides/patterns/phase-0-optimization.md|g' {} +
  ```
- [x] Update docs-accuracy-analyzer-agent-guide.md reference (file: agents/docs-accuracy-analyzer.md)
  ```bash
  find agents -name "*.md" -type f -exec sed -i 's|guides/docs-accuracy-analyzer-agent-guide\.md|guides/patterns/docs-accuracy-analyzer-agent-guide.md|g' {} +
  ```

Testing:
```bash
# Verify no remaining old paths
grep -r "guides/error-enhancement-guide\.md\|guides/performance-optimization\.md\|guides/standards-integration\.md" docs agents --include="*.md" | grep -v archive | grep -v backups
# Should return no results
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Orchestration and Command Guides [COMPLETE]
dependencies: [1]

**Objective**: Fix references to orchestration guides and command-specific guides

**Complexity**: Low

Tasks:
- [x] Update orchestration-best-practices.md references (file: docs/architecture/, docs/workflows/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/orchestration-best-practices\.md|guides/orchestration/orchestration-best-practices.md|g' {} +
  ```
- [x] Update orchestration-troubleshooting.md references (file: docs/reference/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/orchestration-troubleshooting\.md|guides/orchestration/orchestration-troubleshooting.md|g' {} +
  ```
- [x] Update build-command-guide.md reference (file: docs/reference/plan-progress-tracking.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/build-command-guide\.md|guides/commands/build-command-guide.md|g' {} +
  ```
- [x] Update test-command-guide.md references (file: docs/reference/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/test-command-guide\.md|guides/commands/test-command-guide.md|g' {} +
  ```
- [x] Update document-command-guide.md reference (file: docs/reference/command-reference.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/document-command-guide\.md|guides/commands/document-command-guide.md|g' {} +
  ```

Testing:
```bash
# Verify no remaining old paths
grep -r "guides/orchestration-best-practices\.md\|guides/build-command-guide\.md\|guides/test-command-guide\.md" docs --include="*.md" | grep -v archive | grep -v backups
# Should return no results
```

**Expected Duration**: 0.25 hours

---

### Phase 4: Template Files [COMPLETE]
dependencies: [1]

**Objective**: Fix references to template files that moved to templates/ subdirectory

**Complexity**: Low

Tasks:
- [x] Update _template-executable-command.md reference (file: docs/reference/code-standards.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/_template-executable-command\.md|guides/templates/_template-executable-command.md|g' {} +
  ```
- [x] Update _template-command-guide.md reference (file: docs/reference/code-standards.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/_template-command-guide\.md|guides/templates/_template-command-guide.md|g' {} +
  ```
- [x] Update _template-bash-block.md reference (file: docs/reference/output-formatting-standards.md)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/_template-bash-block\.md|guides/templates/_template-bash-block.md|g' {} +
  ```

Testing:
```bash
# Verify no remaining old paths
grep -r "guides/_template-" docs --include="*.md" | grep -v archive | grep -v backups | grep -v "guides/templates/"
# Should return no results
```

**Expected Duration**: 0.25 hours

---

### Phase 5: Archived File Replacements [COMPLETE]
dependencies: [2, 3]

**Objective**: Update references to files that were split/archived to their new primary locations

**Complexity**: Medium

Tasks:
- [x] Update command-patterns.md references to command-patterns-overview.md (file: multiple in docs/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/command-patterns\.md|guides/patterns/command-patterns/command-patterns-overview.md|g' {} +
  ```
- [x] Update execution-enforcement-guide.md references (file: docs/guides/patterns/)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/execution-enforcement-guide\.md|guides/patterns/execution-enforcement/execution-enforcement-overview.md|g' {} +
  ```
- [x] Update workflow-type-selection-guide.md references (file: if any remain)
  ```bash
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/workflow-type-selection-guide\.md|guides/orchestration/workflow-classification-guide.md|g' {} +
  ```
- [x] Update imperative-language-guide.md references (file: docs/guides/orchestration/)
  ```bash
  # imperative-language was merged into execution-enforcement, redirect there
  find docs -name "*.md" -type f ! -path "*/archive/*" ! -path "*/backups/*" -exec sed -i 's|guides/imperative-language-guide\.md|guides/patterns/execution-enforcement/execution-enforcement-overview.md|g' {} +
  ```
- [x] Update deprecated library-api.md references in guides path (file: docs/concepts/robustness-framework.md)
  ```bash
  find docs/concepts -name "*.md" -type f -exec sed -i 's|guides/library-api\.md|reference/library-api.md|g' {} +
  ```

Testing:
```bash
# Verify no remaining old paths for archived files
grep -r "guides/command-patterns\.md\|guides/execution-enforcement-guide\.md\|guides/imperative-language-guide\.md" docs --include="*.md" | grep -v archive | grep -v backups
# Should return no results
```

**Expected Duration**: 0.5 hours

---

### Phase 6: Internal Guide Cross-References [COMPLETE]
dependencies: [1, 2, 3, 4, 5]

**Objective**: Fix relative path references within the guides directory itself

**Complexity**: Medium

Tasks:
- [x] Fix references in orchestration subdirectory guides (file: docs/guides/orchestration/*.md)
  ```bash
  # From orchestration/ to development/
  sed -i 's|\./agent-development-guide\.md|../development/agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/orchestration/*.md
  sed -i 's|\./command-development-guide\.md|../development/command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/orchestration/*.md
  sed -i 's|\./imperative-language-guide\.md|../patterns/execution-enforcement/execution-enforcement-overview.md|g' /home/benjamin/.config/.claude/docs/guides/orchestration/*.md
  ```
- [x] Fix references in patterns subdirectory guides (file: docs/guides/patterns/*.md)
  ```bash
  # Update relative paths in patterns/
  sed -i 's|execution-enforcement-guide\.md|execution-enforcement/execution-enforcement-overview.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/migration-testing.md
  sed -i 's|execution-enforcement-guide\.md|execution-enforcement/execution-enforcement-overview.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md
  sed -i 's|command-development-guide\.md|../development/command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md
  sed -i 's|agent-development-guide\.md|../development/agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/refactoring-methodology.md
  sed -i 's|\./command-development-guide\.md|../development/command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/performance-optimization.md
  sed -i 's|\./agent-development-guide\.md|../development/agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/performance-optimization.md
  sed -i 's|command-development-guide\.md|../development/command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/standards-integration.md
  sed -i 's|\./coordinate-command-guide\.md|../commands/build-command-guide.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/revision-specialist-agent-guide.md
  sed -i 's|workflow-classification-guide\.md|../orchestration/workflow-classification-guide.md|g' /home/benjamin/.config/.claude/docs/guides/patterns/enhanced-topic-generation-guide.md
  ```
- [x] Fix references in development subdirectory guides (file: docs/guides/development/*.md)
  ```bash
  sed -i 's|command-development-guide\.md|command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/development/using-utility-libraries.md
  sed -i 's|agent-development-guide\.md|agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md
  sed -i 's|agent-development-guide\.md|agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/development/model-rollback-guide.md
  ```
- [x] Fix references in development/command-development subdirectory (file: docs/guides/development/command-development/*.md)
  ```bash
  sed -i 's|imperative-language-guide\.md|../../patterns/execution-enforcement/execution-enforcement-overview.md|g' /home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md
  sed -i 's|agent-development-guide\.md|../agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md
  sed -i 's|execution-enforcement-guide\.md|../../patterns/execution-enforcement/execution-enforcement-overview.md|g' /home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-troubleshooting.md
  ```
- [x] Fix references in templates subdirectory (file: docs/guides/templates/*.md)
  ```bash
  sed -i 's|\./command-development-guide\.md|../development/command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md
  sed -i 's|\./related-guide\.md|../README.md|g' /home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md
  ```

Testing:
```bash
# Verify internal cross-references are fixed
grep -r "agent-development-guide\.md\|command-development-guide\.md\|imperative-language-guide\.md" /home/benjamin/.config/.claude/docs/guides --include="*.md" | grep -v "fundamentals\.md" | grep -v "agent-development/" | grep -v "command-development/"
# Should return minimal or no results
```

**Expected Duration**: 0.5 hours

---

### Phase 7: Verification and Cleanup [COMPLETE]
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Verify all references are fixed and document any remaining issues

**Complexity**: Low

Tasks:
- [x] Run comprehensive grep check for remaining old paths
  ```bash
  # Check for any remaining old guide paths
  cd /home/benjamin/.config/.claude
  grep -r "guides/agent-development-guide\.md\|guides/command-development-guide\.md\|guides/command-patterns\.md\|guides/execution-enforcement-guide\.md\|guides/error-enhancement-guide\.md\|guides/performance-optimization\.md\|guides/standards-integration\.md" docs agents commands --include="*.md" | grep -v archive | grep -v backups
  ```
- [x] Verify key navigation paths work (manually check links in docs/README.md)
- [x] Check for any remaining broken paths not covered by sed commands
  ```bash
  # Look for any guide references that might have been missed
  grep -r "guides/[a-z-]*\.md" docs agents commands --include="*.md" | grep -v archive | grep -v backups | grep -v "guides/commands/\|guides/development/\|guides/orchestration/\|guides/patterns/\|guides/templates/"
  ```
- [x] Update CHANGELOG.md historical references (optional - these are historical records)
  ```bash
  # These reference old names, update to current equivalents
  sed -i 's|guides/command-authoring-guide\.md|guides/development/command-development/command-development-fundamentals.md|g' /home/benjamin/.config/.claude/CHANGELOG.md
  sed -i 's|guides/agent-authoring-guide\.md|guides/development/agent-development/agent-development-fundamentals.md|g' /home/benjamin/.config/.claude/CHANGELOG.md
  ```
- [x] Document any remaining issues in summary

Testing:
```bash
# Final verification - should return no results
grep -r "guides/[a-z_-]*\.md" /home/benjamin/.config/.claude/docs --include="*.md" | grep -v archive | grep -v backups | grep -v "guides/commands/\|guides/development/\|guides/orchestration/\|guides/patterns/\|guides/templates/" | wc -l
# Target: 0 results
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Per-Phase Testing
- After each phase, run the specific grep verification commands provided
- Ensure no old paths remain for the files updated in that phase
- Verify file modifications with `git diff` to confirm changes look correct

### Integration Testing
- After all phases complete, run comprehensive grep check
- Manually navigate through docs/README.md to verify key links work
- Spot-check random files in docs/reference/ for correct references

### Success Metrics
- Zero old guide paths found in active documentation (excluding archive/backups)
- All links in docs/README.md resolve to valid files
- Internal guide navigation works correctly

## Documentation Requirements

- Update guides refactor summary with completion status (file: /home/benjamin/.config/.claude/specs/807_docs_guides_directory_has_become_bloated/summaries/001_guides_refactor_summary.md)
- Update Known Issues section to reflect fixed state

## Dependencies

### Prerequisites
- Guide refactor (spec 807) must be complete
- No active editing of affected files during execution
- Backup exists at `.claude/backups/guides-refactor-20251119/`

### External Dependencies
- sed command available (standard Unix utility)
- grep command available (standard Unix utility)
- find command available (standard Unix utility)

## Rollback Procedure

If issues discovered:
1. Use git to revert changes: `git checkout -- docs/ agents/ commands/`
2. Review specific problematic files
3. Apply fixes manually for complex cases
4. Re-run affected phase

## Notes

- **Skip spec files**: References in spec files are historical records and don't need updating
- **Skip backup files**: Never modify backup copies
- **Archive files**: Lower priority, fix only if needed
- **Commit after phases**: Consider committing after each major phase for easier rollback
- **Path variations**: Some files use relative paths (`../guides/`) vs absolute paths (`.claude/docs/guides/`) - sed commands handle both patterns
