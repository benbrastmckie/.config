# Shared Command Documentation

## Status: Directory Archived

**Date**: 2025-10-27
**Action**: Cleanup completed as part of spec 496

This directory previously contained 37 files (400KB) of reusable documentation and template files. After comprehensive analysis and cleanup:

**Final State**: Empty (README.md only)

## What Happened

All files have been relocated to more appropriate locations:

### Command-Specific Templates → `.claude/docs/reference/`
- `orchestration-patterns.md` (70K) - Orchestration agent templates
- `orchestration-alternatives.md` (24K) - Orchestration workflow patterns
- `debug-structure.md` (11K) - Debug report template
- `refactor-structure.md` (12K) - Refactor report template
- `report-structure.md` (7.7K) - Research report template
- `workflow-phases.md` (60K) - Detailed phase descriptions

### Documentation Guides → `.claude/docs/guides/`
- **implementation-guide.md** - Phase execution + implementation workflows
- **revision-guide.md** - Revise auto-mode + revision types
- **setup-command-guide.md** - Setup modes + bloat detection + extraction strategies + standards analysis

### Removed Files
- **4 placeholder files** (empty stubs)
- **9 small orphaned files** (<100 lines, no references)
- **6 large orphaned files** (>100 lines, no active usage)

**Total cleanup**: 36 files removed or relocated (97% reduction)

## Why This Happened

Research showed:
- 67% of files were orphaned or single-use
- Only 1 file (README.md) showed true shared usage pattern (4+ refs)
- 6 large files (6,210 lines) were command-specific, not shared
- Most "shared" files were only used by one command

The shared/ pattern works well for `agents/shared/` (100% active usage) but was misused for command documentation.

## Where to Find Things Now

### For Command Templates
See `.claude/docs/reference/` for:
- Debug report structure
- Refactor report structure
- Research report structure
- Orchestration patterns and templates
- Workflow phase descriptions

### For Implementation Guides
See `.claude/docs/guides/` for:
- Implementation workflows
- Revision procedures
- Setup command operations

### For Agent Behavioral Guidelines
See `.claude/agents/shared/` (unchanged, 100% active usage)

## Lessons Learned

1. **Shared pattern requires 3+ active users** - Single-use files don't belong in shared/
2. **Command-specific ≠ shared** - Even if multiple commands exist, one-to-one files aren't shared
3. **Documentation belongs in docs/** - Not in commands/shared/
4. **Placeholder files accumulate** - Regular cleanup prevents bloat

## Future Guidelines

If considering adding files to shared/:
1. Verify at least 3 commands will reference it
2. Confirm it's truly shared content (not command-specific)
3. Consider `.claude/docs/` for documentation instead
4. Keep template files in `.claude/docs/reference/`

## Navigation

- [← Parent Directory](../README.md)
- [Command Reference Documentation](../../docs/reference/) - Template structures
- [Command Guides](../../docs/guides/) - Implementation guides
- [Agent Shared Guidelines](../../agents/shared/) - Active shared pattern
