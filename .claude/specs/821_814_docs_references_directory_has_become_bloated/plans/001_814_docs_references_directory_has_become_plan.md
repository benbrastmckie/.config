# Fix Broken References After Reference Directory Refactoring

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix broken cross-references from reference directory refactoring (814)
- **Scope**: Update 23 broken references across 16 active files in .claude/ system
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 31.5
- **Research Reports**:
  - [Broken References Verification](/home/benjamin/.config/.claude/specs/821_814_docs_references_directory_has_become_bloated/reports/001_broken_references_verification.md)

## Executive Summary

The reference directory refactoring (814) successfully reorganized 38 flat files into 5 logical subdirectories but left 23 broken references across 16 active files. This plan systematically fixes all broken links in commands, agents, tests, library, guides, and concepts directories to restore documentation integrity.

## Research Summary

Key findings from the broken references verification report:

- **23 broken references** identified across **16 active files**
- **Main categories**:
  - Commands README (3 references)
  - Agent files (3 references)
  - Test files (3 references)
  - Library files (1 reference)
  - Guide files (11 references)
  - Concepts files (2 references)
- **Migration mapping** established for old to new paths
- **Deleted files** need special handling (library-api.md, command_architecture_standards.md, workflow-phases.md were deleted as monolithic redundant files)

## Success Criteria
- [ ] All 23 broken references corrected with new paths
- [ ] No broken links remain when running validate-links.sh
- [ ] All updated files maintain proper markdown formatting
- [ ] Cross-references resolve to existing files in new directory structure

## Technical Design

### Reference Migration Patterns

The refactoring established these new paths:

| Old Pattern | New Path |
|------------|----------|
| `reference/code-standards.md` | `reference/standards/code-standards.md` |
| `reference/testing-protocols.md` | `reference/standards/testing-protocols.md` |
| `reference/test-isolation-standards.md` | `reference/standards/test-isolation.md` |
| `reference/output-formatting-standards.md` | `reference/standards/output-formatting.md` |
| `reference/command-reference.md` | `reference/standards/command-reference.md` |
| `reference/agent-reference.md` | `reference/standards/agent-reference.md` |
| `reference/adaptive-planning-config.md` | `reference/standards/adaptive-planning.md` |
| `reference/orchestration-reference.md` | `reference/workflows/orchestration-reference.md` |
| `reference/phase_dependencies.md` | `reference/workflows/phase-dependencies.md` |

### Deleted File Handling

Files that were deleted require context-specific replacements:
- **library-api.md** -> `library-api/` subdirectory (specific file depends on context)
- **command_architecture_standards.md** -> `architecture/` subdirectory
- **orchestration-patterns.md** -> `workflows/` subdirectory

## Implementation Phases

### Phase 1: Fix Commands and Agents References [COMPLETE]
dependencies: []

**Objective**: Update broken references in commands README and agent files

**Complexity**: Low

Tasks:
- [x] Update `/home/benjamin/.config/.claude/commands/README.md`:
  - Line 610: `../docs/reference/code-standards.md` -> `../docs/reference/standards/code-standards.md`
  - Line 611: `../docs/reference/testing-protocols.md` -> `../docs/reference/standards/testing-protocols.md`
  - Line 612: `../docs/reference/output-formatting-standards.md` -> `../docs/reference/standards/output-formatting.md`
- [x] Update `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md`:
  - Line 488: `../docs/reference/library-api.md#state-persistence` -> `../docs/reference/library-api/persistence.md`
  - Line 489: `../docs/reference/library-api.md#metadata-extraction` -> `../docs/reference/library-api/utilities.md`
- [x] Update `/home/benjamin/.config/.claude/agents/claude-md-analyzer.md`:
  - Line 377: `.claude/docs/reference/code-standards.md` -> `.claude/docs/reference/standards/code-standards.md`

Testing:
```bash
# Verify all updated paths resolve
grep -n "docs/reference/[a-z-]*\.md" /home/benjamin/.config/.claude/commands/README.md
grep -n "docs/reference/[a-z-]*\.md" /home/benjamin/.config/.claude/agents/research-sub-supervisor.md
grep -n "docs/reference/[a-z-]*\.md" /home/benjamin/.config/.claude/agents/claude-md-analyzer.md
```

**Expected Duration**: 30 minutes

### Phase 2: Fix Tests and Library References [COMPLETE]
dependencies: []

**Objective**: Update broken references in test files and library files

**Complexity**: Low

Tasks:
- [x] Update `/home/benjamin/.config/.claude/tests/run_all_tests.sh`:
  - Line 146: `.claude/docs/reference/test-isolation-standards.md` -> `.claude/docs/reference/standards/test-isolation.md`
- [x] Update `/home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh`:
  - Line 18: `docs/reference/testing-protocols.md` -> `docs/reference/standards/testing-protocols.md`
- [x] Update `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`:
  - Line 6: `.claude/docs/reference/command_architecture_standards.md` -> `.claude/docs/reference/architecture/overview.md`
- [x] Update `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`:
  - Line 52: `.claude/docs/reference/test-isolation-standards.md` -> `.claude/docs/reference/standards/test-isolation.md`

Testing:
```bash
# Verify all updated paths resolve
grep -n "docs/reference/" /home/benjamin/.config/.claude/tests/run_all_tests.sh
grep -n "docs/reference/" /home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh
grep -n "docs/reference/" /home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh
grep -n "docs/reference/" /home/benjamin/.config/.claude/lib/unified-location-detection.sh
```

**Expected Duration**: 30 minutes

### Phase 3: Fix Guides Directory References [COMPLETE]
dependencies: []

**Objective**: Update broken references in guide files

**Complexity**: Medium

Tasks:
- [x] Update `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md`:
  - Line 553: `.claude/docs/reference/command-reference.md` -> `.claude/docs/reference/standards/command-reference.md`
  - Line 555: `.claude/docs/reference/testing-protocols.md` -> `.claude/docs/reference/standards/testing-protocols.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestrate-phases-implementation.md`:
  - Lines 520, 534: `.claude/docs/reference/orchestration-patterns.md` -> `.claude/docs/reference/workflows/orchestration-reference.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/commands/convert-docs-command-guide.md`:
  - Lines 277, 285: `.claude/docs/reference/command-reference.md` -> `.claude/docs/reference/standards/command-reference.md`
  - Line 287: `.claude/docs/reference/library-api.md` -> `.claude/docs/reference/library-api/overview.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/commands/collapse-command-guide.md`:
  - Lines 238, 248: `.claude/docs/reference/command-reference.md` -> `.claude/docs/reference/standards/command-reference.md`
  - Line 247: `.claude/docs/reference/adaptive-planning-config.md` -> `.claude/docs/reference/standards/adaptive-planning.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/commands/expand-command-guide.md`:
  - Lines 139, 236: `.claude/docs/reference/adaptive-planning-config.md` -> `.claude/docs/reference/standards/adaptive-planning.md`
  - Lines 227, 237: `.claude/docs/reference/command-reference.md` -> `.claude/docs/reference/standards/command-reference.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/templates/_template-bash-block.md`:
  - Lines 235, 389: `.claude/docs/reference/command_architecture_standards.md` -> `.claude/docs/reference/architecture/overview.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md`:
  - Lines 160, 170: `.claude/docs/reference/command-reference.md` -> `.claude/docs/reference/standards/command-reference.md`
- [x] Update `/home/benjamin/.config/.claude/docs/guides/patterns/logging-patterns.md`:
  - Line 798: `.claude/docs/reference/orchestration-reference.md` -> `.claude/docs/reference/workflows/orchestration-reference.md`

Testing:
```bash
# Verify all updated paths in guides directory
find /home/benjamin/.config/.claude/docs/guides -name "*.md" -exec grep -l "docs/reference/[a-z_-]*\.md" {} \;
```

**Expected Duration**: 1 hour

### Phase 4: Fix Concepts and Validation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Update remaining broken references and run full validation

**Complexity**: Low

Tasks:
- [x] Update `/home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md`:
  - Line 292: `.claude/docs/reference/phase_dependencies.md` -> `.claude/docs/reference/workflows/phase-dependencies.md`
- [x] Run full link validation script
- [x] Verify no broken references remain in active files
- [x] Update implementation summary (814) to document these additional fixes

Testing:
```bash
# Full validation
cd /home/benjamin/.config/.claude && bash scripts/validate-links.sh

# Check for any remaining old-style paths
grep -r "docs/reference/[a-z_-]*\.md" /home/benjamin/.config/.claude --include="*.md" --include="*.sh" | grep -v specs/ | grep -v "reference/standards/" | grep -v "reference/workflows/" | grep -v "reference/library-api/" | grep -v "reference/architecture/" | grep -v "reference/templates/"
```

**Expected Duration**: 1 hour

## Testing Strategy

### Per-Phase Validation
Each phase includes verification that updated paths resolve to existing files.

### Full System Validation
Phase 4 runs the project's link validation script to ensure no broken references remain.

### Exclusion Pattern
Files in `specs/` directory are historical artifacts and should not be updated. All grep commands exclude this directory.

## Documentation Requirements
- Update implementation summary (814) to note these additional files that required updates
- No new documentation files needed

## Dependencies
- Reference directory refactoring (814) must be complete
- New directory structure must exist (architecture/, workflows/, library-api/, standards/, templates/)
- All migrated files must be in their new locations
