# Cleanup Shared Directory Unused Files - Implementation Plan

## Metadata
- **Date**: 2025-10-27
- **Feature**: Clean up /home/benjamin/.config/.claude/commands/shared/ directory by removing unused files and files only used by /orchestrate
- **Scope**: Remove orphaned files, relocate command-specific files, preserve truly shared resources
- **Estimated Phases**: 7
- **Estimated Hours**: 8-10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Shared Directory Analysis](../reports/001_shared_directory_analysis.md)
  - [Orchestrate Dependencies](../reports/002_orchestrate_dependencies.md)
  - [Usage Pattern Analysis](../reports/003_usage_patterns.md)

## Overview

This plan addresses the cleanup and reorganization of the `.claude/commands/shared/` directory, which currently contains 34 files (404KB) with significant redundancy and misuse of the "shared" designation. Research shows that 67% of files are orphaned or single-use, violating the shared resource pattern.

**Primary Goals**:
1. Remove 4 placeholder files (~24.6KB) with no content
2. Relocate 6 command-specific files (6,210 lines) to inline content or docs
3. Delete 22 orphaned files (5,142 lines) with no references
4. Preserve truly shared resources (agents/shared, active templates)
5. Update all command references to relocated content
6. Ensure no breaking changes to active commands

## Research Summary

Key findings from research reports:

**From Shared Directory Analysis (001)**:
- 34 total files analyzed (404KB)
- Only 11 files (32%) actively referenced by commands
- 4 placeholder files identified as immediate removal targets
- Largest files are command-specific, not truly shared

**From Orchestrate Dependencies (002)**:
- /orchestrate has only 2 direct dependencies on shared/
- orchestration-patterns.md (71KB) is the primary dependency
- orchestration-alternatives.md is orchestrate-specific
- 3 incorrect path references found (templates/ vs shared/)

**From Usage Pattern Analysis (003)**:
- 67% of files orphaned or single-use (22 files)
- Only 1 file (README.md) shows true shared usage pattern (4+ refs)
- 6 large files (6,210 lines) are command-specific
- Total cleanup opportunity: 10,616 lines (98.4% of content)

**Recommended Approach**:
- Phased removal: placeholders → orphans → command-specific → reorganize
- Preserve agents/shared/ (100% active usage)
- Test commands after each phase to prevent breakage

## Success Criteria

- [ ] All 4 placeholder files removed (~24.6KB freed)
- [ ] All 22 orphaned files removed (5,142 lines freed)
- [ ] 6 command-specific files relocated to inline or docs (6,210 lines)
- [ ] All command references updated to new locations
- [ ] No broken command functionality (all tests pass)
- [ ] Documentation updated to reflect new structure
- [ ] README.md updated with accurate file inventory
- [ ] Total reduction: 98%+ of commands/shared/ content relocated or removed

## Technical Design

### Directory Structure Changes

**Before**:
```
.claude/commands/shared/
├── README.md (74 lines)
├── orchestration-patterns.md (2,522 lines) [single-use]
├── workflow-phases.md (1,920 lines) [doc-only]
├── debug-structure.md (434 lines) [single-use]
├── refactor-structure.md (430 lines) [single-use]
├── report-structure.md (297 lines) [single-use]
├── [22 orphaned files] (5,142 lines)
├── [4 placeholder files] (24.6KB)
└── [other files]
```

**After**:
```
.claude/commands/shared/
└── README.md (updated index)

.claude/commands/
├── orchestrate.md (includes patterns inline)
├── debug.md (includes structure inline)
├── refactor.md (includes structure inline)
└── research.md (includes structure inline)

.claude/docs/reference/
├── workflow-phases.md (moved from shared)
└── orchestration-patterns.md (if needed for reference)
```

### Relocation Strategy

**Phase-by-Phase Approach**:
1. **Placeholders** → Delete (no dependencies)
2. **Orphans** → Verify, then delete (low risk)
3. **Command-specific** → Inline or docs (update refs)
4. **Documentation-only** → Move to .claude/docs/
5. **Testing** → Verify all commands work
6. **Documentation** → Update READMEs and guides
7. **Validation** → Final verification and cleanup

### Dependency Management

**Critical Preservation**:
- All agents/shared/ files (100% active)
- agents/prompts/evaluate-*.md (programmatic usage)
- commands/shared/README.md (update, don't delete)

**Reference Updates Required**:
- orchestrate.md (2 shared/ references + 3 incorrect paths)
- debug.md (1 reference)
- refactor.md (1 reference)
- research.md (1 reference)
- document.md (1 README reference)
- plan-from-template.md (1 README reference)

## Implementation Phases

### Phase 0: Pre-Cleanup Validation
dependencies: []

**Objective**: Verify current state, create backup, establish baseline

**Complexity**: Low

**Tasks**:
- [x] Run full test suite to establish baseline: `/test-all` (46 passed, 26 failed - baseline)
- [x] Verify all commands execute without errors
- [x] Create backup of .claude/commands/shared/ directory
- [x] Document current file count and sizes (baseline metrics: 37 files, 400KB)
- [x] Verify git status is clean before starting

**Testing**:
```bash
# Baseline test suite
cd /home/benjamin/.config
/test-all

# Verify commands
.claude/commands/orchestrate.md --help
.claude/commands/debug.md --help
.claude/commands/refactor.md --help
.claude/commands/research.md --help

# Backup shared directory
cp -r .claude/commands/shared .claude/commands/shared.backup
```

**Expected Duration**: 0.5 hours

**Phase 0 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 0 - Pre-Cleanup Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 1: Remove Placeholder Files
dependencies: [0]

**Objective**: Delete 4 placeholder files with no content (immediate wins)

**Complexity**: Low

**Tasks**:
- [x] Remove orchestration-history.md (171 bytes) - placeholder
- [x] Remove orchestration-performance.md (175 bytes) - placeholder
- [x] Remove orchestration-troubleshooting.md (172 bytes) - placeholder
- [x] Remove complexity-evaluation-details.md - placeholder
- [x] Update shared/README.md to remove placeholder references
- [NOTE] orchestration-alternatives.md is NOT a placeholder (607 lines) - will be handled in Phase 4

**Testing**:
```bash
# Verify files deleted
test ! -f .claude/commands/shared/orchestration-alternatives.md
test ! -f .claude/commands/shared/orchestration-history.md
test ! -f .claude/commands/shared/orchestration-performance.md
test ! -f .claude/commands/shared/orchestration-troubleshooting.md

# Test orchestrate command still works
/orchestrate --help

# Run test suite
/test-all
```

**Expected Duration**: 1 hour

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 1 - Remove Placeholder Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Remove Small Orphaned Files
dependencies: [1]

**Objective**: Delete 15 small orphaned files (<100 lines, no references)

**Complexity**: Low

**Tasks**:
- [x] Remove readme-template.md (57 lines) - unused template
- [x] Remove orchestrate-examples.md (29 lines) - no references
- [x] Remove agent-coordination.md (26 lines) - stub file
- [x] Remove adaptive-planning.md (24 lines) - stub file
- [x] Remove testing-patterns.md (21 lines) - stub file
- [x] Remove progressive-structure.md (21 lines) - stub file
- [x] Remove error-recovery.md (21 lines) - stub file
- [x] Remove context-management.md (20 lines) - stub file
- [x] Remove error-handling.md (16 lines) - stub file
- [x] Update shared/README.md to remove references to deleted files
- [x] Document total lines removed (9 files removed)

**Testing**:
```bash
# Verify all small orphans deleted
for file in readme-template orchestrate-examples agent-coordination adaptive-planning testing-patterns progressive-structure error-recovery context-management error-handling; do
  test ! -f .claude/commands/shared/$file.md && echo "✓ $file deleted" || echo "✗ $file still exists"
done

# Run test suite
/test-all
```

**Expected Duration**: 0.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 2 - Remove Small Orphaned Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Remove Large Orphaned Files
dependencies: [2]

**Objective**: Delete 7 large orphaned files (>100 lines, verified no dependencies)

**Complexity**: Medium (requires verification before deletion)

**Tasks**:
- [x] Verify orchestrate-enhancements.md (592 lines) - no programmatic usage found
- [x] Remove orchestrate-enhancements.md
- [x] Verify agent-tool-descriptions.md (401 lines) - no active references
- [x] Remove agent-tool-descriptions.md
- [x] Verify agent-invocation-patterns.md (323 lines) - no shared/ references
- [x] Remove agent-invocation-patterns.md
- [x] Verify output-patterns.md (264 lines) - no references found
- [x] Remove output-patterns.md
- [x] Verify command-frontmatter.md (211 lines) - no enforcement found
- [x] Remove command-frontmatter.md
- [x] Verify audit-checklist.md (203 lines) - no audit process usage
- [x] Remove audit-checklist.md
- [x] Update shared/README.md to remove references to deleted files
- [x] Document total lines removed (6 large orphaned files, 1,994 lines)

**Testing**:
```bash
# Verify no hidden references before deletion
for file in orchestrate-enhancements agent-tool-descriptions agent-invocation-patterns output-patterns complexity-evaluation-details command-frontmatter audit-checklist; do
  echo "=== Checking $file ==="
  grep -r "$file" .claude/commands/ .claude/lib/ || echo "No references found"
done

# After deletion, run test suite
/test-all

# Test key commands
/plan --help
/implement --help
/orchestrate --help
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 3 - Remove Large Orphaned Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Relocate Command-Specific Files
dependencies: [3]

**Objective**: Move 6 command-specific files to inline content or .claude/docs/reference/

**Complexity**: High (requires updating command files and references)

**Tasks**:
- [ ] Read orchestration-patterns.md (2,522 lines) - largest file
- [ ] Decide: inline in orchestrate.md OR move to .claude/docs/reference/
- [ ] Update orchestrate.md with orchestration-patterns content (if inline)
- [ ] OR move orchestration-patterns.md to .claude/docs/reference/ (if docs)
- [ ] Update all references to orchestration-patterns.md (4 in orchestrate.md)
- [ ] Fix 3 incorrect path refs (templates/orchestration-patterns.md → correct path)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Read debug-structure.md (434 lines)
- [ ] Inline debug-structure content into debug.md command
- [ ] Update debug.md reference to inline content
- [ ] Remove debug-structure.md from shared/
- [ ] Read refactor-structure.md (430 lines)
- [ ] Inline refactor-structure content into refactor.md command
- [ ] Update refactor.md reference to inline content
- [ ] Remove refactor-structure.md from shared/

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Read report-structure.md (297 lines)
- [ ] Inline report-structure content into research.md command
- [ ] Update research.md reference to inline content
- [ ] Remove report-structure.md from shared/
- [ ] Document total lines relocated (6,210 lines)

**Testing**:
```bash
# Test each command after relocation
/orchestrate --help
/debug --help
/refactor --help
/research --help

# Verify no broken references
grep -r "shared/orchestration-patterns.md" .claude/commands/ && echo "WARNING: References still exist" || echo "✓ References updated"
grep -r "shared/debug-structure.md" .claude/commands/ && echo "WARNING: References still exist" || echo "✓ References updated"
grep -r "shared/refactor-structure.md" .claude/commands/ && echo "WARNING: References still exist" || echo "✓ References updated"
grep -r "shared/report-structure.md" .claude/commands/ && echo "WARNING: References still exist" || echo "✓ References updated"

# Run full test suite
/test-all
```

**Expected Duration**: 3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 4 - Relocate Command-Specific Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Reorganize Documentation Files
dependencies: [4]

**Objective**: Move 9 documentation-only files to .claude/docs/ structure

**Complexity**: Medium (requires creating new doc structure if needed)

**Tasks**:
- [ ] Verify .claude/docs/reference/ directory exists (create if needed)
- [ ] Move workflow-phases.md (1,920 lines) to .claude/docs/reference/
- [ ] Update references to workflow-phases.md (1 in shared/README.md)
- [ ] Move phase-execution.md (383 lines) to .claude/docs/guides/implementation-guide.md (append)
- [ ] Move implementation-workflow.md (152 lines) to .claude/docs/guides/implementation-guide.md (append)
- [ ] Verify .claude/docs/guides/ directory exists (create if needed)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Move revise-auto-mode.md (434 lines) to .claude/docs/guides/revision-guide.md (append)
- [ ] Move revision-types.md (109 lines) to .claude/docs/guides/revision-guide.md (append)
- [ ] Move extraction-strategies.md (296 lines) to .claude/docs/guides/setup-command-guide.md (append)
- [ ] Move standards-analysis.md (287 lines) to .claude/docs/guides/setup-command-guide.md (append)
- [ ] Move setup-modes.md (226 lines) to .claude/docs/guides/setup-command-guide.md (append)
- [ ] Move bloat-detection.md (155 lines) to .claude/docs/guides/setup-command-guide.md (append)
- [ ] Update all references to relocated documentation files
- [ ] Update shared/README.md to remove documentation file references
- [ ] Update .claude/docs/README.md to include new guide locations
- [ ] Document total lines reorganized (3,962 lines)

**Testing**:
```bash
# Verify documentation files moved
test -f .claude/docs/reference/workflow-phases.md && echo "✓ workflow-phases moved" || echo "✗ Move failed"
test -f .claude/docs/guides/implementation-guide.md && echo "✓ implementation-guide exists" || echo "✗ Guide missing"
test -f .claude/docs/guides/revision-guide.md && echo "✓ revision-guide exists" || echo "✗ Guide missing"
test -f .claude/docs/guides/setup-command-guide.md && echo "✓ setup-guide exists" || echo "✗ Guide missing"

# Verify original files removed
test ! -f .claude/commands/shared/workflow-phases.md && echo "✓ Original removed" || echo "✗ Original still exists"

# Run test suite
/test-all
```

**Expected Duration**: 2 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 5 - Reorganize Documentation Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Update Documentation and References
dependencies: [5]

**Objective**: Update all READMEs and cross-references to reflect new structure

**Complexity**: Medium

**Tasks**:
- [ ] Update .claude/commands/shared/README.md with new file inventory
- [ ] Remove references to deleted files from shared/README.md
- [ ] Add note about relocated files (where they moved)
- [ ] Update .claude/commands/README.md if it references shared/ files
- [ ] Update .claude/docs/README.md with new documentation structure
- [ ] Add links to new guide locations (implementation, revision, setup)
- [ ] Update CLAUDE.md if it references any relocated files
- [ ] Verify all cross-references are updated
- [ ] Check for broken links in documentation
- [ ] Update command development guide if it references shared/ templates

**Testing**:
```bash
# Find broken references
grep -r "commands/shared/" .claude/docs/ .claude/commands/ | grep -v ".backup" | grep -E "(orchestration-patterns|debug-structure|refactor-structure|report-structure|workflow-phases)" && echo "WARNING: Broken references found" || echo "✓ No broken references"

# Verify README accuracy
cat .claude/commands/shared/README.md | grep -E "(orchestration-patterns|debug-structure|refactor-structure|report-structure)" && echo "WARNING: Outdated README" || echo "✓ README updated"

# Run test suite
/test-all
```

**Expected Duration**: 1 hour

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 6 - Update Documentation and References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Final Validation and Cleanup
dependencies: [6]

**Objective**: Verify all changes, run comprehensive tests, document metrics

**Complexity**: Low

**Tasks**:
- [ ] Run full test suite: `/test-all`
- [ ] Test all commands that referenced shared/ files
- [ ] Verify agents/shared/ directory untouched (100% preserved)
- [ ] Verify agents/prompts/ evaluate-*.md files preserved
- [ ] Calculate metrics: files removed, lines relocated, space freed
- [ ] Compare against success criteria (98%+ cleanup achieved?)
- [ ] Remove .claude/commands/shared.backup directory (if all tests pass)
- [ ] Create summary document with before/after metrics
- [ ] Verify no broken command functionality
- [ ] Mark all success criteria as complete

**Testing**:
```bash
# Comprehensive command testing
/orchestrate --help
/coordinate --help
/supervise --help
/debug --help
/refactor --help
/research --help
/plan --help
/implement --help
/document --help

# Verify preserved directories
test -d .claude/agents/shared && echo "✓ agents/shared preserved" || echo "✗ agents/shared missing"
test -f .claude/agents/prompts/evaluate-plan-phases.md && echo "✓ prompts preserved" || echo "✗ prompts missing"

# Calculate metrics
echo "=== Cleanup Metrics ==="
echo "Files removed: $(find .claude/commands/shared.backup -name "*.md" | wc -l) → $(find .claude/commands/shared -name "*.md" | wc -l)"
du -sh .claude/commands/shared.backup .claude/commands/shared

# Full test suite
/test-all
```

**Expected Duration**: 1 hour

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(496): complete Phase 7 - Final Validation and Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Test Categories

1. **Baseline Testing** (Phase 0)
   - Establish pre-cleanup baseline
   - Document passing tests
   - Verify all commands executable

2. **Incremental Testing** (Phases 1-6)
   - Run `/test-all` after each phase
   - Test specific commands affected by phase changes
   - Verify no broken references after each removal/relocation

3. **Integration Testing** (Phase 7)
   - Comprehensive command testing
   - Cross-reference validation
   - End-to-end workflow testing

### Test Commands

```bash
# Full test suite (run after each phase)
cd /home/benjamin/.config
.claude/tests/run_all_tests.sh

# Specific command testing
/orchestrate --help
/debug --help
/refactor --help
/research --help

# Reference validation
grep -r "commands/shared/" .claude/ | grep -v ".backup"
```

### Coverage Requirements

- All commands must execute without errors
- No broken references to deleted files
- All relocated content accessible at new locations
- agents/shared/ and agents/prompts/ fully preserved
- Total cleanup: ≥98% of commands/shared/ content

## Documentation Requirements

### Files to Update

1. **.claude/commands/shared/README.md**
   - Remove references to deleted files
   - Update file inventory
   - Add relocation notes

2. **.claude/commands/README.md**
   - Update shared/ directory description
   - Note reorganization if referenced

3. **.claude/docs/README.md**
   - Add new guide locations
   - Update documentation index

4. **CLAUDE.md** (if applicable)
   - Verify no references to relocated files
   - Update if shared/ structure is documented

5. **Command Development Guide**
   - Update template references
   - Note new locations for patterns

### New Documentation

1. **Migration summary** (in Phase 7)
   - Before/after metrics
   - File relocation map
   - Breaking changes (if any)

2. **Updated READMEs**
   - New shared/ directory purpose
   - Preserved vs removed files
   - Cross-references to new locations

## Dependencies

### External Dependencies
- None (all changes internal to .claude/ directory)

### Command Dependencies
- /test-all (for validation)
- /orchestrate (affected by cleanup)
- /debug (affected by cleanup)
- /refactor (affected by cleanup)
- /research (affected by cleanup)

### Preservation Requirements
- **MUST preserve**: All agents/shared/ files (100% active usage)
- **MUST preserve**: agents/prompts/evaluate-*.md (programmatic usage)
- **MUST preserve**: commands/shared/README.md (update, don't delete)
- **MUST update**: All command references to relocated files

## Risk Mitigation

### High-Risk Areas

1. **orchestration-patterns.md relocation** (2,522 lines)
   - Risk: Breaking multiple orchestrate.md references
   - Mitigation: Test orchestrate command after relocation
   - Rollback: Restore from backup if tests fail

2. **Command-specific file inlining** (Phase 4)
   - Risk: Bloating command files with inline content
   - Mitigation: Consider docs/ location instead of inline
   - Rollback: Revert command changes, restore shared/ files

3. **Reference updates** (Phases 4-6)
   - Risk: Missing hidden references, broken links
   - Mitigation: Comprehensive grep for references before removal
   - Rollback: Git revert specific commits

### Mitigation Strategies

1. **Backup**: Create .claude/commands/shared.backup in Phase 0
2. **Incremental commits**: Commit after each phase (atomic changes)
3. **Testing**: Run /test-all after every phase
4. **Verification**: Grep for references before deleting files
5. **Rollback plan**: Git revert capability for each phase

## Notes

**Design Decisions**:
- Chose phased approach over big-bang to enable testing after each change
- Prioritized placeholder/orphan removal before relocation (low-risk first)
- Preserved agents/shared/ 100% (healthy shared pattern)
- Relocated command-specific files to reduce shared/ bloat

**Alternative Approaches Considered**:
- Inline all content vs docs/ relocation: Chose docs/ for large files
- Delete all vs selective preservation: Chose verification before deletion
- Single phase vs multi-phase: Chose multi-phase for risk reduction

**Future Enhancements**:
- Add automated tests for shared/ file usage patterns
- Create linting rule to prevent single-use files in shared/
- Establish shared/ acceptance criteria for new files
