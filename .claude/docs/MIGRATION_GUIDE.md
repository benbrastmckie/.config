# Command Consolidation Migration Guide

This guide documents breaking changes from the agential system refinement (Plan 026).

## Overview

As part of the lean agential system refinement, several commands have been consolidated to reduce surface area while maintaining full functionality. This change creates a cleaner, more consistent command interface.

## Breaking Changes

### Removed Commands

The following commands have been removed in favor of unified interfaces:

1. `/cleanup` → `/setup --cleanup`
2. `/validate-setup` → `/setup --validate`
3. `/analyze-agents` → `/analyze agents`
4. `/analyze-patterns` → `/analyze patterns`

## Migration Instructions

### 1. Cleanup Operations

**Old command**:
```bash
/cleanup [project-directory]
/cleanup --dry-run [project-directory]
```

**New command**:
```bash
/setup --cleanup [project-directory]
/setup --cleanup --dry-run [project-directory]
```

**What changed**:
- Command renamed from `/cleanup` to `/setup --cleanup`
- All functionality preserved
- No behavioral changes

**Migration**:
- Simply replace `/cleanup` with `/setup --cleanup` in scripts or workflows
- All flags work identically (`--dry-run`, `--threshold`, etc.)

---

### 2. Validation Operations

**Old command**:
```bash
/validate-setup [project-directory]
```

**New command**:
```bash
/setup --validate [project-directory]
```

**What changed**:
- Command renamed from `/validate-setup` to `/setup --validate`
- All functionality preserved
- No behavioral changes

**Migration**:
- Simply replace `/validate-setup` with `/setup --validate`
- Same validation checks, same output format

---

### 3. Analysis Operations

**Old commands**:
```bash
/analyze-agents
/analyze-patterns [search-pattern]
```

**New command**:
```bash
/analyze agents
/analyze patterns [search-pattern]
/analyze all  # Analyze both
```

**What changed**:
- Commands consolidated into `/analyze [type]`
- Added type parameter: `agents`, `patterns`, or `all`
- All functionality preserved
- Added ability to analyze both types at once

**Migration**:

| Old Command | New Command | Notes |
|------------|-------------|-------|
| `/analyze-agents` | `/analyze agents` | Add space + type |
| `/analyze-patterns` | `/analyze patterns` | Add space + type |
| `/analyze-patterns auth` | `/analyze patterns auth` | Add space + type |
| N/A | `/analyze all` | New: analyze everything |

**Examples**:
```bash
# Before
/analyze-agents
/analyze-patterns feature

# After
/analyze agents
/analyze patterns feature

# New capability
/analyze all  # Analyze agents AND patterns
```

---

## Error Messages

Removed commands fail with clear error messages pointing to replacements:

```bash
$ /cleanup
Error: Command removed. Use: /setup --cleanup

$ /validate-setup
Error: Command removed. Use: /setup --validate

$ /analyze-agents
Error: Command removed. Use: /analyze agents

$ /analyze-patterns
Error: Command removed. Use: /analyze patterns
```

## Impact Assessment

### Low Impact (Simple Substitution)

Commands with no parameter changes:
- `/cleanup` → `/setup --cleanup` (just a prefix)
- `/validate-setup` → `/setup --validate` (just a prefix)

### Medium Impact (Syntax Change)

Commands requiring parameter adjustment:
- `/analyze-agents` → `/analyze agents` (add type parameter)
- `/analyze-patterns` → `/analyze patterns` (add type parameter)

## Rollback (Not Recommended)

If you must temporarily revert to old commands:

1. **Checkout previous commit**:
   ```bash
   git checkout [commit-before-consolidation]~1 -- .claude/commands/cleanup.md
   git checkout [commit-before-consolidation]~1 -- .claude/commands/validate-setup.md
   git checkout [commit-before-consolidation]~1 -- .claude/commands/analyze-agents.md
   git checkout [commit-before-consolidation]~1 -- .claude/commands/analyze-patterns.md
   ```

2. **Restore files manually** from backup

**Warning**: Rollback creates inconsistency. The unified commands provide better long-term maintainability.

## Benefits of Consolidation

### Reduced Command Count
- Before: 29 commands
- After: 26 commands
- Reduction: 10%

### Improved Consistency
- Related operations grouped under parent commands
- Clear command hierarchy (`/setup` for all setup-related tasks)
- Unified interface patterns

### Easier Discovery
- `/setup --help` shows all setup-related modes
- `/analyze --help` shows all analysis types
- Less to remember, clearer organization

### Cleaner Codebase
- Fewer command files to maintain
- Consolidated documentation
- Reduced duplication

## FAQ

**Q: Why consolidate commands?**
A: To create a leaner, more maintainable command interface. Related operations are now grouped logically.

**Q: Will my existing scripts break?**
A: Yes, if they use the removed commands. Update them using the migration table above.

**Q: Can I use both old and new syntax?**
A: No. This is a clean break. Old commands are completely removed.

**Q: What if I forget the new syntax?**
A: Error messages provide the correct replacement command.

**Q: Is functionality lost?**
A: No. All functionality is preserved in the new unified commands.

**Q: Why not keep backward compatibility?**
A: User preference for clean breaks over cruft. Wrappers would add complexity without providing value.

## Troubleshooting

### Problem: Command not found

```
Error: Command '/cleanup' not found
```

**Solution**: Use `/setup --cleanup` instead

### Problem: Wrong number of arguments

```
Error: /analyze requires a type parameter
```

**Solution**: Specify type: `/analyze agents` or `/analyze patterns`

### Problem: Flag not recognized

```
Error: Unknown flag '--dry-run' for /validate-setup
```

**Solution**: Use `/setup --cleanup --dry-run` (--dry-run only works with cleanup mode)

## Verification

To verify your migration:

1. **Search for old commands in scripts**:
   ```bash
   grep -r "cleanup" .
   grep -r "validate-setup" .
   grep -r "analyze-agents" .
   grep -r "analyze-patterns" .
   ```

2. **Test new commands**:
   ```bash
   /setup --cleanup --dry-run
   /setup --validate
   /analyze agents
   /analyze patterns
   ```

3. **Check documentation references**:
   ```bash
   grep -r "/cleanup" docs/
   grep -r "/validate-setup" docs/
   grep -r "/analyze-agents" docs/
   grep -r "/analyze-patterns" docs/
   ```

## Support

If you encounter issues with migration:

1. Check this guide for the correct replacement
2. Review error messages (they provide guidance)
3. Consult command documentation (`/setup --help`, `/analyze --help`)
4. Report issues with the migration guide itself

## Timeline

- **Plan Created**: 2025-10-06 (Plan 026)
- **Implementation**: Phase 2 - Command Consolidation
- **Effective Date**: [Commit date of Phase 2 completion]
- **Deprecation Period**: None (clean break)

## Related Documentation

- [Command Consolidation Plan](../specs/plans/026_agential_system_refinement.md#phase-2-command-consolidation)
- [Commands README](../commands/README.md)
- [Setup Command Documentation](../commands/setup.md)
- [Analyze Command Documentation](../commands/analyze.md)
