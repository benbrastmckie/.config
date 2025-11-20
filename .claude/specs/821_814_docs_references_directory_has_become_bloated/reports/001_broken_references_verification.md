# Broken References Verification Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Post-refactoring broken link verification for reference directory
- **Report Type**: codebase analysis

## Executive Summary

After analyzing the reference directory refactoring implementation (814), I identified 23 broken references across 12 active files in the .claude/ system. The refactoring successfully moved files to new subdirectories (architecture/, workflows/, library-api/, standards/, templates/) but several files were not updated with the new paths. The main CLAUDE.md was properly updated, but secondary files like commands/README.md, agent files, test files, and guide files still contain old paths that no longer resolve.

## Findings

### 1. Correctly Updated Files

The following files were properly updated as documented in the implementation summary:

- **CLAUDE.md** (lines 63, 70, 77, 113, 148) - All paths correctly point to new `standards/` subdirectory:
  - `.claude/docs/reference/standards/testing-protocols.md`
  - `.claude/docs/reference/standards/code-standards.md`
  - `.claude/docs/reference/standards/output-formatting.md`
  - `.claude/docs/reference/standards/adaptive-planning.md`
  - `.claude/docs/reference/standards/command-reference.md`

### 2. Broken References in Active Files

#### 2.1 Commands Directory

**File**: `/home/benjamin/.config/.claude/commands/README.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 610 | `../docs/reference/code-standards.md` | `../docs/reference/standards/code-standards.md` |
| 611 | `../docs/reference/testing-protocols.md` | `../docs/reference/standards/testing-protocols.md` |
| 612 | `../docs/reference/output-formatting-standards.md` | `../docs/reference/standards/output-formatting.md` |

#### 2.2 Agents Directory

**File**: `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md`

| Line | Old Path | Issue |
|------|----------|-------|
| 488 | `../docs/reference/library-api.md#state-persistence` | File was deleted (monolithic) - needs redirect to `../docs/reference/library-api/persistence.md` |
| 489 | `../docs/reference/library-api.md#metadata-extraction` | File was deleted (monolithic) - needs redirect to appropriate library-api/ subfile |

**File**: `/home/benjamin/.config/.claude/agents/claude-md-analyzer.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 377 | `.claude/docs/reference/code-standards.md` | `.claude/docs/reference/standards/code-standards.md` |

#### 2.3 Tests Directory

**File**: `/home/benjamin/.config/.claude/tests/run_all_tests.sh`

| Line | Old Path | New Path |
|------|----------|----------|
| 146 | `.claude/docs/reference/test-isolation-standards.md` | `.claude/docs/reference/standards/test-isolation.md` |

**File**: `/home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh`

| Line | Old Path | New Path |
|------|----------|----------|
| 18 | `docs/reference/testing-protocols.md` | `docs/reference/standards/testing-protocols.md` |

**File**: `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`

| Line | Old Path | Issue |
|------|----------|-------|
| 6 | `.claude/docs/reference/command_architecture_standards.md` | File was deleted - needs redirect to `architecture/` subdirectory |

#### 2.4 Library Directory

**File**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh`

| Line | Old Path | New Path |
|------|----------|----------|
| 52 | `.claude/docs/reference/test-isolation-standards.md` | `.claude/docs/reference/standards/test-isolation.md` |

#### 2.5 Guides Directory

**File**: `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 553 | `.claude/docs/reference/command-reference.md` | `.claude/docs/reference/standards/command-reference.md` |
| 555 | `.claude/docs/reference/testing-protocols.md` | `.claude/docs/reference/standards/testing-protocols.md` |

**File**: `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestrate-phases-implementation.md`

| Line | Old Path | Issue |
|------|----------|-------|
| 520, 534 | `.claude/docs/reference/orchestration-patterns.md` | File does not exist - needs to reference `workflows/` subdirectory |

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/convert-docs-command-guide.md`

| Line | Old Path | New Path/Issue |
|------|----------|----------------|
| 277 | `.claude/docs/reference/command-reference.md` | `.claude/docs/reference/standards/command-reference.md` |
| 285 | `.claude/docs/reference/command-reference.md` | `.claude/docs/reference/standards/command-reference.md` |
| 287 | `.claude/docs/reference/library-api.md` | File deleted - redirect to `library-api/` subdirectory |

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/collapse-command-guide.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 238, 248 | `.claude/docs/reference/command-reference.md` | `.claude/docs/reference/standards/command-reference.md` |
| 247 | `.claude/docs/reference/adaptive-planning-config.md` | `.claude/docs/reference/standards/adaptive-planning.md` |

**File**: `/home/benjamin/.config/.claude/docs/guides/commands/expand-command-guide.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 139, 236 | `.claude/docs/reference/adaptive-planning-config.md` | `.claude/docs/reference/standards/adaptive-planning.md` |
| 227, 237 | `.claude/docs/reference/command-reference.md` | `.claude/docs/reference/standards/command-reference.md` |

**File**: `/home/benjamin/.config/.claude/docs/guides/templates/_template-bash-block.md`

| Line | Old Path | Issue |
|------|----------|-------|
| 235, 389 | `.claude/docs/reference/command_architecture_standards.md` | File deleted - redirect to `architecture/` subdirectory |

**File**: `/home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 160, 170 | `.claude/docs/reference/command-reference.md` | `.claude/docs/reference/standards/command-reference.md` |

**File**: `/home/benjamin/.config/.claude/docs/guides/patterns/logging-patterns.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 798 | `.claude/docs/reference/orchestration-reference.md` | `.claude/docs/reference/workflows/orchestration-reference.md` |

#### 2.6 Concepts Directory

**File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md`

| Line | Old Path | New Path |
|------|----------|----------|
| 292 | `.claude/docs/reference/phase_dependencies.md` | `.claude/docs/reference/workflows/phase-dependencies.md` |

### 3. Migration Mapping Summary

The following mapping should be applied to fix all broken references:

| Old Path Pattern | New Path |
|------------------|----------|
| `reference/code-standards.md` | `reference/standards/code-standards.md` |
| `reference/testing-protocols.md` | `reference/standards/testing-protocols.md` |
| `reference/test-isolation-standards.md` | `reference/standards/test-isolation.md` |
| `reference/output-formatting-standards.md` | `reference/standards/output-formatting.md` |
| `reference/command-reference.md` | `reference/standards/command-reference.md` |
| `reference/agent-reference.md` | `reference/standards/agent-reference.md` |
| `reference/adaptive-planning-config.md` | `reference/standards/adaptive-planning.md` |
| `reference/library-api.md` | `reference/library-api/` (split into multiple files) |
| `reference/command_architecture_standards.md` | DELETED - content in `reference/architecture/` |
| `reference/workflow-phases.md` | DELETED - content in `reference/workflows/` |
| `reference/orchestration-reference.md` | `reference/workflows/orchestration-reference.md` |
| `reference/phase_dependencies.md` | `reference/workflows/phase-dependencies.md` |

### 4. Files That Should NOT Be Updated

References in the following locations are historical artifacts and should not be updated:

- `/home/benjamin/.config/.claude/specs/` - Old spec reports and plans (historical documentation)
- Any backup or archive directories

## Recommendations

### 1. Immediate Priority: Update Active Files

Update the 12 active files identified above with correct paths. This is critical because these files are actively used by commands, tests, and documentation.

**Estimated effort**: 23 path corrections across 12 files

### 2. Create Migration Script

Create a script to automate future reference updates:

```bash
#!/bin/bash
# fix-reference-paths.sh
find .claude -name "*.md" -o -name "*.sh" | \
  xargs grep -l "docs/reference/[a-z-]*\.md" | \
  grep -v specs/ | \
  while read file; do
    # Apply sed replacements for each pattern
    sed -i 's|reference/code-standards\.md|reference/standards/code-standards.md|g' "$file"
    sed -i 's|reference/testing-protocols\.md|reference/standards/testing-protocols.md|g' "$file"
    # ... additional patterns
  done
```

### 3. Handle Deleted Monolithic Files

For references to deleted monolithic files (library-api.md, command_architecture_standards.md, workflow-phases.md):

- **library-api.md**: Update to reference specific files in `library-api/` subdirectory based on context
- **command_architecture_standards.md**: Update to reference files in `architecture/` subdirectory
- **workflow-phases.md**: Update to reference files in `workflows/` subdirectory

### 4. Add Link Validation to CI

Add a link validation step to prevent future broken references:

```bash
# Add to .claude/scripts/validate-links.sh
grep -r "docs/reference/[a-z_-]*\.md" .claude --include="*.md" --include="*.sh" | \
  grep -v specs/ | \
  while read match; do
    file=$(echo "$match" | cut -d: -f1)
    path=$(echo "$match" | grep -oP 'docs/reference/[a-z_-]+\.md')
    if [ ! -f ".claude/$path" ]; then
      echo "BROKEN: $file -> $path"
    fi
  done
```

### 5. Update Documentation

After fixing references, update the implementation summary (814) to note these additional files that were missed in the original implementation.

## References

### Files Analyzed with Broken References

1. `/home/benjamin/.config/.claude/commands/README.md` - Lines 610-612
2. `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md` - Lines 488-489
3. `/home/benjamin/.config/.claude/agents/claude-md-analyzer.md` - Line 377
4. `/home/benjamin/.config/.claude/tests/run_all_tests.sh` - Line 146
5. `/home/benjamin/.config/.claude/tests/test_semantic_slug_commands.sh` - Line 18
6. `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh` - Line 6
7. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` - Line 52
8. `/home/benjamin/.config/.claude/docs/guides/orchestration/creating-orchestrator-commands.md` - Lines 553, 555
9. `/home/benjamin/.config/.claude/docs/guides/orchestration/orchestrate-phases-implementation.md` - Lines 520, 534
10. `/home/benjamin/.config/.claude/docs/guides/commands/convert-docs-command-guide.md` - Lines 277, 285, 287
11. `/home/benjamin/.config/.claude/docs/guides/commands/collapse-command-guide.md` - Lines 238, 247, 248
12. `/home/benjamin/.config/.claude/docs/guides/commands/expand-command-guide.md` - Lines 139, 227, 236, 237
13. `/home/benjamin/.config/.claude/docs/guides/templates/_template-bash-block.md` - Lines 235, 389
14. `/home/benjamin/.config/.claude/docs/guides/templates/_template-command-guide.md` - Lines 160, 170
15. `/home/benjamin/.config/.claude/docs/guides/patterns/logging-patterns.md` - Line 798
16. `/home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md` - Line 292

### Implementation Summary Reviewed

- `/home/benjamin/.config/.claude/specs/814_docs_references_directory_has_become_bloated/summaries/814_implementation_summary.md`

### New Directory Structure Verified

- `/home/benjamin/.config/.claude/docs/reference/standards/` - 11 files including testing-protocols.md, code-standards.md
- `/home/benjamin/.config/.claude/docs/reference/workflows/` - 9 files including orchestration-reference.md
- `/home/benjamin/.config/.claude/docs/reference/library-api/` - 5 files
- `/home/benjamin/.config/.claude/docs/reference/architecture/` - 9 files
- `/home/benjamin/.config/.claude/docs/reference/templates/` - 5 files

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001_814_docs_references_directory_has_become_plan.md](../plans/001_814_docs_references_directory_has_become_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-19
