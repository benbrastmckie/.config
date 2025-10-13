# Archived Documentation

This directory contains documentation files that were consolidated during the documentation refactoring project (Phases 2-5, October 2025).

## Why These Files Were Archived

As part of systematic documentation improvement, we consolidated 23 fragmented documentation files into 12-15 focused guides. These archived files represent the **original source material** that was merged into comprehensive replacement documents.

**Key Principle**: No content was lost. All information from these files was carefully merged into the new documentation structure.

## Archive Structure

```
archived/
├── README.md (this file)
├── phases_2_3/ (7 files from Phases 2-3)
│   ├── README.md
│   ├── parallel_execution_architecture.md
│   ├── parallel-execution-example.md
│   ├── parallel_operations_user_guide.md
│   ├── troubleshooting_parallel_operations.md
│   ├── command-standardization-checklist.md
│   ├── command-standards-flow.md
│   └── command-selection-guide.md
└── phase4_consolidation/ (4 files from Phase 4)
    ├── README.md
    ├── standards-integration-pattern.md
    ├── standards-integration-examples.md
    ├── adaptive-plan-structures.md
    └── checkpointing-guide.md
```

## Complete Consolidation Mapping

| Archived File | Consolidated Into | New File Purpose | Phase |
|--------------|-------------------|------------------|-------|
| **Parallel Execution (4 files)** | | | **2** |
| parallel_execution_architecture.md | orchestration-guide.md | Multi-agent workflows | 2 |
| parallel-execution-example.md | orchestration-guide.md | Examples | 2 |
| parallel_operations_user_guide.md | orchestration-guide.md | User workflows | 2 |
| troubleshooting_parallel_operations.md | orchestration-guide.md | Troubleshooting | 2 |
| **Command Documentation (3 files)** | | | **3** |
| command-standardization-checklist.md | creating-commands.md | Quality checklist | 3 |
| command-standards-flow.md | creating-commands.md | Standards discovery | 3 |
| command-selection-guide.md | creating-commands.md | Command decisions | 3 |
| [NEW] | command-reference.md | Command catalog | 3 |
| **Standards Documentation (2 files)** | | | **4** |
| standards-integration-pattern.md | standards-integration.md | Pattern & examples | 4 |
| standards-integration-examples.md | standards-integration.md | Integrated examples | 4 |
| **Adaptive Planning (2 files)** | | | **4** |
| adaptive-plan-structures.md | adaptive-planning-guide.md | Progressive levels | 4 |
| checkpointing-guide.md | adaptive-planning-guide.md | Checkpoint system | 4 |

## How to Find Information

If you previously referenced an archived file, use this guide to find the information in the new structure:

**Looking for parallel execution info?**
→ See [orchestration-guide.md](../orchestration-guide.md)

**Looking for command development?**
→ See [creating-commands.md](../creating-commands.md)

**Looking for command reference?**
→ See [command-reference.md](../command-reference.md)

**Looking for adaptive planning?**
→ See [adaptive-planning-guide.md](../adaptive-planning-guide.md)

**Looking for standards integration?**
→ See [standards-integration.md](../standards-integration.md)

## Why Consolidation Was Necessary

**Problems with Original Structure**:
- 23 separate files with significant overlap
- 4 files covering parallel execution with 60%+ redundant content
- 3 files covering command development with scattered information
- 2 files each for standards and adaptive planning with duplicate content
- Difficult navigation, unclear entry points
- Inconsistent terminology across related files

**Benefits of New Structure**:
- 12-15 focused guides, each with clear purpose
- Comprehensive coverage without redundancy
- Clear navigation by user role (new users, developers, contributors)
- Consistent terminology and cross-references
- Single source of truth for each topic

## Consolidation Statistics

### Overall Metrics
- **Starting files**: 23 markdown files
- **Ending files**: 12-15 active files
- **Files archived**: 11 files
- **Reduction**: 35-48% fewer files
- **Content deduplication**: ~30-40% reduction in redundant content
- **New files created**: 5 (orchestration-guide, creating-commands, command-reference, standards-integration, agent-reference)

### By Phase
- **Phase 2**: 4 files → 1 file (orchestration-guide.md)
- **Phase 3**: 3 files → 2 files (creating-commands.md + command-reference.md)
- **Phase 4**: 4 files → 2 files (standards-integration.md + adaptive-planning-guide.md)
- **Phase 5**: Cross-reference updates, README rewrite, archival, validation

## Accessing Archived Content

These files are preserved for:
- **Historical reference**: Understanding evolution of documentation
- **Content verification**: Confirming all original information was migrated
- **Git history**: Tracking changes and consolidation process
- **Rollback capability**: Can restore if needed

**Not for active use**: Do not link to archived files in new documentation or code.

## Rollback Instructions

If you need to restore the old documentation structure:

```bash
# Restore from archive
cd /home/benjamin/.config/.claude/docs
cp -r archived/phases_2_3/* ./
cp -r archived/phase4_consolidation/* ./

# Remove new files
rm orchestration-guide.md creating-commands.md command-reference.md
rm standards-integration.md adaptive-planning-guide.md agent-reference.md

# Restore old README
git checkout HEAD~5 -- README.md
```

**Warning**: This will break all updated cross-references. Only use for emergency rollback.

## Related Documentation

- [../README.md](../README.md) - Current documentation index
- [../orchestration-guide.md](../orchestration-guide.md) - Orchestration and workflows
- [../creating-commands.md](../creating-commands.md) - Command development
- [../command-reference.md](../command-reference.md) - Command catalog
- [../adaptive-planning-guide.md](../adaptive-planning-guide.md) - Adaptive planning
- [../standards-integration.md](../standards-integration.md) - Standards integration
- [../agent-reference.md](../agent-reference.md) - Agent catalog

## Archival Dates

- **Phases 2-3**: October 12, 2025 (Phase 5, Task 5)
- **Phase 4**: October 12, 2025 (Phase 4, final task)

## Plan Reference

- **Main Plan**: specs/plans/004_docs_refactoring/004_docs_refactoring.md
- **Phase 5 Details**: specs/plans/004_docs_refactoring/phase_5_update_readme_cross_references_and_cleanup.md
