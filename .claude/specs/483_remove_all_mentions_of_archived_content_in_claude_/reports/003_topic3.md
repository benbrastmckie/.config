# Archived Content Mentions in .claude/docs/ Research Report

## Metadata
- **Date**: 2025-10-26
- **Agent**: research-specialist
- **Topic**: Find all mentions of archived content within .claude/docs/ directory itself and other documentation files
- **Report Type**: codebase analysis

## Executive Summary

Comprehensive search of .claude/docs/ directory reveals archive-related content in three categories: (1) legitimate archive/ subdirectory index and historical documentation (6 files), (2) references to removed directories (utils/, examples/) in 8 documentation files, and (3) references to archived library files in reference documentation. The main README.md correctly documents the archive/ subdirectory structure. Most mentions are broken links to directories removed during the 2025-10-26 cleanup.

## Findings

### 1. Archive Directory Structure (Legitimate)

The .claude/docs/archive/ subdirectory exists as a proper archive for historical documentation:

**Files in archive/ subdirectory**:
- `/home/benjamin/.config/.claude/docs/archive/README.md` - Archive index with redirects
- `/home/benjamin/.config/.claude/docs/archive/artifact_organization.md` - Topic-based organization guide (archived)
- `/home/benjamin/.config/.claude/docs/archive/topic_based_organization.md` - Directory structure guide (archived)
- `/home/benjamin/.config/.claude/docs/archive/development-philosophy.md` - Development philosophy (archived)
- `/home/benjamin/.config/.claude/docs/archive/timeless_writing_guide.md` - Writing standards (archived)
- `/home/benjamin/.config/.claude/docs/archive/migration-guide-adaptive-plans.md` - Adaptive planning migration (archived)

**Documented in README.md:103-110**: Main README correctly lists these archived files with appropriate descriptions and redirects to current documentation.

### 2. Broken References to Removed Directories

Multiple documentation files reference directories that were removed during the 2025-10-26 cleanup:

**References to .claude/utils/ directory** (directory no longer exists):

1. `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md`:
   - Line 260: `.claude/utils/list-checkpoints.sh`
   - Line 261: `.claude/utils/list-checkpoints.sh orchestrate`
   - Line 273: `.claude/utils/cleanup-checkpoints.sh [days]`
   - Line 354: `.claude/utils/parse-adaptive-plan.sh`
   - Line 355: `.claude/utils/list-checkpoints.sh`
   - Line 356: `.claude/utils/cleanup-checkpoints.sh [days]`
   - Line 404: `.claude/utils/parse-adaptive-plan.sh detect_tier`
   - Line 410: `.claude/utils/parse-adaptive-plan.sh list_phases`
   - Line 417: `.claude/utils/parse-adaptive-plan.sh get_tasks`
   - Line 423: `.claude/utils/parse-adaptive-plan.sh mark_complete`

2. `/home/benjamin/.config/.claude/docs/guides/efficiency-guide.md`:
   - Line 103: `.claude/utils/analyze-phase-complexity.sh`
   - Line 107: `.claude/utils/analyze-phase-complexity.sh "Phase Name"`
   - Line 415: `.claude/utils/parse-phase-dependencies.sh`
   - Line 419: `.claude/utils/parse-phase-dependencies.sh plan_file.md`
   - Line 656: `.claude/utils/analyze-phase-complexity.sh`
   - Line 672: `.claude/utils/parse-phase-dependencies.sh plan.md`
   - Line 693: `.claude/utils/analyze-phase-complexity.sh`
   - Line 694: `.claude/utils/parse-phase-dependencies.sh`

3. `/home/benjamin/.config/.claude/docs/guides/data-management.md`:
   - Line 584: `.claude/utils/cleanup-data.sh`

4. `/home/benjamin/.config/.claude/docs/guides/error-enhancement-guide.md`:
   - Line 33: `.claude/utils/analyze-error.sh`
   - Line 271: `.claude/utils/analyze-error.sh`
   - Line 280: `.claude/utils/analyze-error.sh`
   - Line 283: `.claude/utils/analyze-error.sh`
   - Line 356: `.claude/utils/analyze-error.sh`
   - Line 409: `.claude/utils/analyze-error.sh`

5. `/home/benjamin/.config/.claude/docs/archive/migration-guide-adaptive-plans.md`:
   - Line 67: `.claude/utils/calculate-plan-complexity.sh`
   - Line 73: `.claude/utils/calculate-plan-complexity.sh`
   - Line 139: `.claude/utils/parse-adaptive-plan.sh detect_tier`
   - Line 143: `.claude/utils/parse-adaptive-plan.sh list_phases`

**References to .claude/examples/ directory** (directory no longer exists):

1. `/home/benjamin/.config/.claude/docs/troubleshooting/agent-delegation-issues.md`:
   - Line 10: `[Examples Directory](../examples/)`
   - Line 109: `[Correct Agent Invocation Examples](../examples/correct-agent-invocation.md)`
   - Line 207: `[Behavioral Injection Workflow](../examples/behavioral-injection-workflow.md)`
   - Line 407: `[Correct Agent Invocation: Anti-Patterns](../examples/correct-agent-invocation.md#anti-pattern-examples)`
   - Line 610: `.claude/docs/examples/`
   - Line 636: `[Behavioral Injection Workflow](../examples/behavioral-injection-workflow.md)`
   - Line 637: `[Correct Agent Invocation](../examples/correct-agent-invocation.md)`
   - Line 638: `[Reference Implementations](../examples/reference-implementations.md)`

2. `/home/benjamin/.config/.claude/docs/guides/setup-command-guide.md`:
   - Line 302: `.claude/examples/setup/`

3. `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`:
   - Line 868: `[Correct Agent Invocation Examples](../examples/correct-agent-invocation.md)`

### 3. References to Archived Library Files

`/home/benjamin/.config/.claude/docs/reference/library-api.md`:
- Line 787: `artifact-operations-legacy.sh` - Legacy artifact operations
- Line 789: `migrate-specs-utils.sh` - Specs directory migration

These files were mentioned in the CLAUDE.md cleanup notes as archived.

### 4. Archive-Related Patterns (Legitimate Usage)

The following are legitimate uses of the word "archive" in the context of data management (not references to .claude/archive/):

**Data archival operations** (legitimate usage):
- `/home/benjamin/.config/.claude/docs/guides/data-management.md`: Lines 278-281, 425-427, 591-593, 608-609 - Log and metrics archival procedures
- `/home/benjamin/.config/.claude/docs/workflows/checkpoint_template_guide.md`: Lines 146, 720, 727 - Checkpoint retention and template archival policies
- `/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md`: Lines 141, 186 - Checkpoint archival operations

### 5. References to /report Command

`/home/benjamin/.config/.claude/docs/README.md`:
- Line 136: Reference to `/report` command (archived, replaced by `/research`)

### 6. Miscellaneous Archive References

**Example file paths** (not actual references):
- Multiple files contain example paths like `specs/042_auth/reports/001_jwt_patterns.md` or `./reports` which use "reports" as a directory name but are not references to archived content.

## Recommendations

### 1. Update References to Removed utils/ Directory

All references to `.claude/utils/` scripts should be updated to reflect the current location of these utilities. Based on the cleanup notes, functionality was moved to `.claude/lib/`. Recommended actions:

- Replace `.claude/utils/list-checkpoints.sh` with appropriate lib/ equivalent or remove if functionality is deprecated
- Replace `.claude/utils/parse-adaptive-plan.sh` with lib/plan-core-bundle.sh functions
- Replace `.claude/utils/analyze-phase-complexity.sh` with lib/complexity-utils.sh
- Replace `.claude/utils/parse-phase-dependencies.sh` with current implementation path
- Replace `.claude/utils/cleanup-checkpoints.sh` with lib/checkpoint-utils.sh equivalents
- Replace `.claude/utils/cleanup-data.sh` with appropriate lib/ function
- Replace `.claude/utils/analyze-error.sh` with lib/error-handling.sh equivalents

**Files requiring updates**: 5 files (adaptive-planning-guide.md, efficiency-guide.md, data-management.md, error-enhancement-guide.md, migration-guide-adaptive-plans.md)

### 2. Update References to Removed examples/ Directory

All references to `.claude/examples/` or `.claude/docs/examples/` should be removed or replaced with current documentation:

- Remove or redirect links to `examples/correct-agent-invocation.md`
- Remove or redirect links to `examples/behavioral-injection-workflow.md`
- Remove or redirect links to `examples/reference-implementations.md`
- Remove or redirect links to `examples/setup/`

Consider replacing these references with:
- Links to `concepts/patterns/behavioral-injection.md` for injection patterns
- Links to `guides/command-development-guide.md` for command examples
- Links to `workflows/orchestration-guide.md` for workflow examples

**Files requiring updates**: 3 files (agent-delegation-issues.md, setup-command-guide.md, command-development-guide.md)

### 3. Update Library API Reference

Update `/home/benjamin/.config/.claude/docs/reference/library-api.md` to:
- Mark `artifact-operations-legacy.sh` and `migrate-specs-utils.sh` as archived
- Add note indicating these files are in `.claude/archive/lib/` (if that's the location)
- Or remove entirely if no longer relevant

### 4. Update /report Command Reference

Update `/home/benjamin/.config/.claude/docs/README.md` line 136:
- Change "**`/report`**: Research with parallel subagents" to "**`/research`**: Research with parallel subagents"
- Or add note: "(replaced by `/research`)"

### 5. Keep Archive Directory Documentation

The archive/ subdirectory documentation in README.md (lines 103-110) is correct and should be preserved as-is. This provides proper navigation to historical documentation.

### 6. Create Migration Guide Section

Consider adding a section to archive/README.md that documents the utils/ → lib/ migration and examples/ removal, helping users understand where functionality was moved.

## References

**Files analyzed**:
- `/home/benjamin/.config/.claude/docs/README.md` (lines 103-110, 136)
- `/home/benjamin/.config/.claude/docs/archive/README.md` (complete file)
- `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md` (lines 260-423)
- `/home/benjamin/.config/.claude/docs/guides/efficiency-guide.md` (lines 103-694)
- `/home/benjamin/.config/.claude/docs/guides/data-management.md` (lines 278-609)
- `/home/benjamin/.config/.claude/docs/guides/error-enhancement-guide.md` (lines 33-409)
- `/home/benjamin/.config/.claude/docs/troubleshooting/agent-delegation-issues.md` (lines 10-638)
- `/home/benjamin/.config/.claude/docs/guides/setup-command-guide.md` (line 302)
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (line 868)
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` (lines 787-789)
- `/home/benjamin/.config/.claude/docs/archive/migration-guide-adaptive-plans.md` (lines 67-143)
- `/home/benjamin/.config/.claude/docs/workflows/checkpoint_template_guide.md` (lines 146, 720, 727)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md` (lines 141, 186)

**Total documentation files**: 65 markdown files in .claude/docs/
**Files with archive references**: 12 files (excluding legitimate data archival usage)
