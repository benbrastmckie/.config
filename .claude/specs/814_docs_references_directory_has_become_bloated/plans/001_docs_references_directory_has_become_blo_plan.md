# Reference Directory Refactoring Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Reference Directory Reorganization
- **Scope**: Reorganize 40 files (18,499 lines) in .claude/docs/reference/ into logical subdirectories, remove redundancy (6,161 lines), update all external references
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Complexity Score**: 157.5
- **Structure Level**: 0
- **Research Reports**:
  - [Reference Directory Refactoring Research](/home/benjamin/.config/.claude/specs/814_docs_references_directory_has_become_bloated/reports/001_reference_directory_refactoring_research.md)
  - [Clean-Break Plan Revision Analysis](/home/benjamin/.config/.claude/specs/814_docs_references_directory_has_become_bloated/reports/002_clean_break_plan_revision_analysis.md)

## Clean-Break Approach

This plan follows clean-break refactoring principles:
- **Direct moves**: Use `git mv` for atomic file relocation with history preservation
- **Immediate cleanup**: Delete redundant files in same phase as migration
- **No deprecation**: No deprecation notices, migration guides, or backward-compatibility paths
- **Git recovery**: Standard git operations (`git checkout`) provide rollback capability

## Overview

The `.claude/docs/reference/` directory has grown to 40 markdown files totaling 18,499 lines with significant bloat from redundant split files (workflow-phases and architecture-standards series), legacy monolithic documents that were split but never removed, and poor categorization. This plan implements a clean-break refactoring to organize references into 5 logical subdirectories (architecture, workflows, library-api, standards, templates), remove 6,161 lines of redundancy (33% reduction), and update all external references in a single coordinated pass.

## Research Summary

Key findings from the research reports:

1. **Redundancy Pattern**: Three monolithic documents were split but originals retained, causing 6,161 lines of duplication
   - `command_architecture_standards.md` (2,586 lines) - split into 8 `architecture-standards-*.md` files
   - `workflow-phases.md` (2,198 lines) - split into 7 `workflow-phases-*.md` files
   - `library-api.md` (1,377 lines) - split into 5 `library-api-*.md` files

2. **Natural Groupings**: Content clusters into 5 categories by usage and topic
   - Architecture Standards (9 files, 5,005 lines)
   - Workflow Documentation (9 files, 5,417 lines)
   - Library API Reference (5 files, 2,792 lines)
   - Core Standards (10 files, 3,653 lines)
   - Templates/Structures (4 files, 1,390 lines)

3. **Critical Links**: CLAUDE.md directly references 5 files requiring path updates

4. **Clean-Break Requirements**: Direct moves, immediate deletion of redundant files, coordinated single-pass link updates

## Success Criteria

- [ ] All files reorganized into 5 logical subdirectories
- [ ] Redundant monolithic documents deleted (3 files, 6,161 lines)
- [ ] Final file count: 34 files (37 files in subdirectories + 5 new READMEs - 3 deleted)
- [ ] Total line count reduced from 18,499 to ~12,500 lines (33% reduction)
- [ ] All external references updated in single coordinated pass
- [ ] Each subdirectory has comprehensive README.md
- [ ] No broken links after migration (verified by grep)
- [ ] No deprecation notices created anywhere
- [ ] All three redundant monolithic files deleted (not archived)
- [ ] Zero references to old file paths remain in codebase
- [ ] Git history preserved for all moved files via `git mv`

## Technical Design

### Directory Structure

```
.claude/docs/reference/
├── README.md                           # Updated master index
├── architecture/                        # Architecture Standards (8 files)
│   ├── README.md
│   ├── overview.md
│   ├── validation.md
│   ├── documentation.md
│   ├── integration.md
│   ├── dependencies.md
│   ├── error-handling.md
│   ├── testing.md
│   └── template-vs-behavioral.md
├── workflows/                           # Workflow Documentation (8 files)
│   ├── README.md
│   ├── phases-overview.md
│   ├── phases-research.md
│   ├── phases-planning.md
│   ├── phases-implementation.md
│   ├── phases-testing.md
│   ├── phases-documentation.md
│   ├── orchestration-reference.md
│   └── phase-dependencies.md
├── library-api/                         # Library API Reference (4 files)
│   ├── README.md
│   ├── overview.md
│   ├── state-machine.md
│   ├── persistence.md
│   └── utilities.md
├── standards/                           # Core Standards (10 files)
│   ├── README.md
│   ├── command-reference.md
│   ├── agent-reference.md
│   ├── testing-protocols.md
│   ├── code-standards.md
│   ├── output-formatting.md
│   ├── command-authoring.md
│   ├── claude-md-schema.md
│   ├── test-isolation.md
│   ├── adaptive-planning.md
│   └── plan-progress.md
└── templates/                           # Templates & Structures (4 files)
    ├── README.md
    ├── debug-structure.md
    ├── refactor-structure.md
    ├── report-structure.md
    └── backup-policy.md
```

### Migration Approach

1. **Git mv for history preservation**: Use `git mv` for all file moves
2. **Atomic subdirectory creation**: Create all directories and placeholder READMEs first
3. **Direct deletion**: Remove redundant files immediately after migration
4. **Single-pass link updates**: Update all references in one coordinated phase
5. **End-state verification**: Verify final state, not intermediate states

### Naming Conventions

- Subdirectory names: lowercase singular nouns (e.g., `standards/`)
- File names: Remove redundant prefixes (e.g., `architecture-standards-validation.md` → `validation.md`)
- Hyphenated lowercase for all filenames

## Implementation Phases

### Phase 1: Create Subdirectory Structure [COMPLETE]
dependencies: []

**Objective**: Create the 5 subdirectory structure with placeholder READMEs

**Complexity**: Low

Tasks:
- [x] Create `.claude/docs/reference/architecture/` directory
- [x] Create `.claude/docs/reference/workflows/` directory
- [x] Create `.claude/docs/reference/library-api/` directory
- [x] Create `.claude/docs/reference/standards/` directory
- [x] Create `.claude/docs/reference/templates/` directory
- [x] Create placeholder README.md in each subdirectory with basic structure

Testing:
```bash
# Verify directory structure exists
for dir in architecture workflows library-api standards templates; do
  test -d /home/benjamin/.config/.claude/docs/reference/$dir && echo "$dir/ exists" || echo "ERROR: $dir/ missing"
done
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Migrate Architecture Files [COMPLETE]
dependencies: [1]

**Objective**: Move architecture files to new subdirectory and delete redundant monolithic file

**Complexity**: Medium

Tasks:
- [x] git mv `architecture-standards-overview.md` → `architecture/overview.md`
- [x] git mv `architecture-standards-validation.md` → `architecture/validation.md`
- [x] git mv `architecture-standards-documentation.md` → `architecture/documentation.md`
- [x] git mv `architecture-standards-integration.md` → `architecture/integration.md`
- [x] git mv `architecture-standards-dependencies.md` → `architecture/dependencies.md`
- [x] git mv `architecture-standards-error-handling.md` → `architecture/error-handling.md`
- [x] git mv `architecture-standards-testing.md` → `architecture/testing.md`
- [x] git mv `template-vs-behavioral-distinction.md` → `architecture/template-vs-behavioral.md`
- [x] Delete redundant `command_architecture_standards.md` (git rm)
- [x] Update internal cross-references within moved files to use new relative paths

Testing:
```bash
# Verify files in new location and old files gone
ls /home/benjamin/.config/.claude/docs/reference/architecture/*.md | wc -l
test ! -f /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md && echo "Monolithic deleted" || echo "ERROR: Monolithic still exists"
```

**Expected Duration**: 1.5 hours

---

### Phase 3: Migrate Workflow and Library API Files [COMPLETE]
dependencies: [1]

**Objective**: Move workflow and library API files to new subdirectories and delete redundant monolithic files

**Complexity**: Medium

Tasks:
- [x] git mv `workflow-phases-overview.md` → `workflows/phases-overview.md`
- [x] git mv `workflow-phases-research.md` → `workflows/phases-research.md`
- [x] git mv `workflow-phases-planning.md` → `workflows/phases-planning.md`
- [x] git mv `workflow-phases-implementation.md` → `workflows/phases-implementation.md`
- [x] git mv `workflow-phases-testing.md` → `workflows/phases-testing.md`
- [x] git mv `workflow-phases-documentation.md` → `workflows/phases-documentation.md`
- [x] git mv `orchestration-reference.md` → `workflows/orchestration-reference.md`
- [x] git mv `phase_dependencies.md` → `workflows/phase-dependencies.md`
- [x] git mv `library-api-overview.md` → `library-api/overview.md`
- [x] git mv `library-api-state-machine.md` → `library-api/state-machine.md`
- [x] git mv `library-api-persistence.md` → `library-api/persistence.md`
- [x] git mv `library-api-utilities.md` → `library-api/utilities.md`
- [x] Delete redundant `workflow-phases.md` (git rm)
- [x] Delete redundant `library-api.md` (git rm)
- [x] Update internal cross-references within moved files

Testing:
```bash
# Verify workflow and library-api migrations
ls /home/benjamin/.config/.claude/docs/reference/workflows/*.md | wc -l
ls /home/benjamin/.config/.claude/docs/reference/library-api/*.md | wc -l
test ! -f /home/benjamin/.config/.claude/docs/reference/workflow-phases.md && echo "workflow-phases.md deleted"
test ! -f /home/benjamin/.config/.claude/docs/reference/library-api.md && echo "library-api.md deleted"
```

**Expected Duration**: 1.5 hours

---

### Phase 4: Migrate Standards and Templates Files [COMPLETE]
dependencies: [1]

**Objective**: Move core standards and template files to new subdirectories

**Complexity**: Medium

Tasks:
- [x] git mv `command-reference.md` → `standards/command-reference.md`
- [x] git mv `agent-reference.md` → `standards/agent-reference.md`
- [x] git mv `testing-protocols.md` → `standards/testing-protocols.md`
- [x] git mv `code-standards.md` → `standards/code-standards.md`
- [x] git mv `output-formatting-standards.md` → `standards/output-formatting.md`
- [x] git mv `command-authoring-standards.md` → `standards/command-authoring.md`
- [x] git mv `claude-md-section-schema.md` → `standards/claude-md-schema.md`
- [x] git mv `test-isolation-standards.md` → `standards/test-isolation.md`
- [x] git mv `adaptive-planning-config.md` → `standards/adaptive-planning.md`
- [x] git mv `plan-progress-tracking.md` → `standards/plan-progress.md`
- [x] git mv `debug-structure.md` → `templates/debug-structure.md`
- [x] git mv `refactor-structure.md` → `templates/refactor-structure.md`
- [x] git mv `report-structure.md` → `templates/report-structure.md`
- [x] git mv `backup-retention-policy.md` → `templates/backup-policy.md`

Testing:
```bash
# Verify standards and templates migrations
ls /home/benjamin/.config/.claude/docs/reference/standards/*.md | wc -l
ls /home/benjamin/.config/.claude/docs/reference/templates/*.md | wc -l
```

**Expected Duration**: 1.5 hours

---

### Phase 5: Update References and Complete READMEs [COMPLETE]
dependencies: [2, 3, 4]

**Objective**: Update all external references in single coordinated pass, complete subdirectory READMEs, verify migration

**Complexity**: High

Tasks:
- [x] Update CLAUDE.md references (5 links):
  - `.claude/docs/reference/testing-protocols.md` → `.claude/docs/reference/standards/testing-protocols.md`
  - `.claude/docs/reference/code-standards.md` → `.claude/docs/reference/standards/code-standards.md`
  - `.claude/docs/reference/output-formatting-standards.md` → `.claude/docs/reference/standards/output-formatting.md`
  - `.claude/docs/reference/adaptive-planning-config.md` → `.claude/docs/reference/standards/adaptive-planning.md`
  - `.claude/docs/reference/command-reference.md` → `.claude/docs/reference/standards/command-reference.md`
- [x] Update test file references in `.claude/tests/`
- [x] Update guide file references in `.claude/docs/guides/*.md`
- [x] Update workflow file references in `.claude/docs/workflows/*.md`
- [x] Update concept file references in `.claude/docs/concepts/*.md`
- [x] Update library file references in `.claude/lib/*.sh`
- [x] Update agent file references in `.claude/agents/*.md`
- [x] Complete `architecture/README.md` with purpose, inventory, and navigation
- [x] Complete `workflows/README.md` with purpose, inventory, and navigation
- [x] Complete `library-api/README.md` with purpose, inventory, and navigation
- [x] Complete `standards/README.md` with purpose, inventory, and navigation
- [x] Complete `templates/README.md` with purpose, inventory, and navigation
- [x] Update main `reference/README.md` with new structure and subdirectory links
- [x] Run final verification to confirm zero broken links

Testing:
```bash
# Final verification - all old paths should be gone
cd /home/benjamin/.config
grep -r "docs/reference/workflow-phases\.md" .claude/ && echo "ERROR: Old reference" || echo "OK: workflow-phases.md"
grep -r "docs/reference/library-api\.md" .claude/ && echo "ERROR: Old reference" || echo "OK: library-api.md"
grep -r "docs/reference/command_architecture_standards\.md" .claude/ && echo "ERROR: Old reference" || echo "OK: command_architecture"
grep -r "docs/reference/architecture-standards-" .claude/ && echo "ERROR: Old prefix" || echo "OK: architecture-standards-"
grep -r "docs/reference/workflow-phases-" .claude/ && echo "ERROR: Old prefix" || echo "OK: workflow-phases-"
grep -r "docs/reference/library-api-" .claude/ && echo "ERROR: Old prefix" || echo "OK: library-api-"

# Verify file counts
echo "Total files in reference/: $(find .claude/docs/reference -name '*.md' | wc -l)"
echo "Expected: 39 files (34 migrated + 5 READMEs)"
```

**Expected Duration**: 3 hours

## Testing Strategy

### End-State Verification
- Grep-based verification that no old paths are referenced anywhere
- Verify new paths resolve correctly
- Single comprehensive verification pass after all phases complete

### Test Suite Validation
- Run `.claude/tests/run_all_tests.sh` after Phase 5
- Ensure command standards compliance test passes

### File Count Verification
```bash
cd /home/benjamin/.config/.claude/docs/reference
echo "Total files: $(find . -name '*.md' | wc -l)"
echo "Total lines: $(find . -name '*.md' -exec wc -l {} \; | awk '{sum+=$1} END {print sum}')"
for dir in architecture workflows library-api standards templates; do
  echo "$dir: $(ls $dir/*.md 2>/dev/null | wc -l) files"
done
```

## Documentation Requirements

### Files to Create
- 5 subdirectory README.md files with inventory tables
- 1 updated main reference/README.md with new structure

### Files to Update
- CLAUDE.md (5 reference path updates)
- All guide files with reference links
- All test files with reference links
- All workflow and concept files with reference links

### Documentation Standards
- Use CommonMark specification
- Include navigation links in each README
- Provide document inventory tables with descriptions
- No emojis in content

## Dependencies

### Prerequisites
- Git repository in clean state for `git mv` operations
- Write access to all directories

### External Dependencies
- Test suite must be functional before final verification
- CLAUDE.md must be editable

### Recovery
Standard git operations apply - `git checkout` restores any file to previous state.
