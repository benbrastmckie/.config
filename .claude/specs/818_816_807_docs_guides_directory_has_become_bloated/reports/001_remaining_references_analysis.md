# Remaining Old-Style Guide References Analysis

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Analysis of remaining old-style guide references after 816 implementation
- **Report Type**: codebase analysis

## Executive Summary

After analyzing all 45 remaining old-style guide references (from the initial 152 count claim), I found that only **7 references actually require fixing**. The majority fall into categories that should be ignored: 20 are in backup directories (expected), 11 are in data/archive directories (historical artifacts), and 4 are placeholder patterns in documentation examples. The 7 broken references are concentrated in 3 files: 2 in `commands/setup.md` and 5 in `docs/concepts/patterns/executable-documentation-separation.md`.

## Findings

### Category Breakdown

| Category | Count | Status |
|----------|-------|--------|
| Needs Fix | 7 | **ACTION REQUIRED** |
| Backup/Archive (Ignore) | 31 | Historical artifacts |
| Placeholder Examples (Ignore) | 4 | Documentation patterns |
| Valid References | 3 | Correct new paths |
| **Total** | 45 | |

---

### 1. References That Need Fixing (7 total)

#### File: `/home/benjamin/.config/.claude/commands/setup.md` (2 references)

| Line | Old Path | New Path |
|------|----------|----------|
| 1 | `.claude/docs/guides/setup-command-guide.md` | `.claude/docs/guides/commands/setup-command-guide.md` |
| 2 | `.claude/docs/guides/setup-command-guide.md` | `.claude/docs/guides/commands/setup-command-guide.md` |

**Specific text to fix**:
- `**Documentation**: See \`.claude/docs/guides/setup-command-guide.md\``
  → Should be: `**Documentation**: See \`.claude/docs/guides/commands/setup-command-guide.md\``
- `**Troubleshooting**: See \`.claude/docs/guides/setup-command-guide.md\``
  → Should be: `**Troubleshooting**: See \`.claude/docs/guides/commands/setup-command-guide.md\``

#### File: `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` (5 references)

These are example patterns showing what documentation SHOULD look like, but they use old paths:

| Line | Old Path | New Path |
|------|----------|----------|
| 1 | `.claude/docs/guides/orchestrate-command-guide.md` | `.claude/docs/guides/commands/build-command-guide.md` (renamed) |
| 2 | `.claude/docs/guides/orchestrate-command-guide.md` | `.claude/docs/guides/commands/build-command-guide.md` |
| 3 | `.claude/docs/guides/implement-command-guide.md` | (placeholder - mark as generic example) |
| 4 | `.claude/docs/guides/command-command-guide.md` | (placeholder - mark as generic example) |

**Note**: Lines 3-4 appear to be intentional placeholder examples showing the naming pattern. They should either:
- Be updated to use generic placeholder format like `commands/command-name-command-guide.md`
- Or be replaced with real command examples that exist

---

### 2. Backup/Archive References to Ignore (31 total)

These are in backup directories and represent historical state before refactoring:

**Location: `/home/benjamin/.config/.claude/backups/guides-refactor-20251119/guides/`**

| File | Count | Reason to Ignore |
|------|-------|------------------|
| `agent-development-guide.md` | 2 | Backup of original file |
| `link-conventions-guide.md` | 10 | Backup showing examples |
| `command-development-fundamentals.md` | 2 | Backup of original file |
| `model-selection-guide.md` | 1 | Backup of original file |
| `creating-orchestrator-commands.md` | 1 | Backup of original file |

**Location: `/home/benjamin/.config/.claude/data/602_*/`**

| File | Count | Reason to Ignore |
|------|-------|------------------|
| `001_state_based_orchestrator_refactor.md` | 11 | Historical plan artifact |
| `coordinate_subprocess_isolation_fix_plan.md` | 2 | Historical report artifact |

**Location: `/home/benjamin/.config/.claude/data/model_optimization_*.md`**

| File | Count | Reason to Ignore |
|------|-------|------------------|
| `model_optimization_integration_results.md` | 1 | Historical data file |
| `model_optimization_summary.md` | 6 | Historical data file |

---

### 3. Placeholder Examples to Ignore (4 total)

These are in agent behavioral files showing example output patterns:

**Location: `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md`**

| Reference | Purpose |
|-----------|---------|
| `guides/coordinate-command-guide.md` | Example analysis output |
| `guides/testing-guide.md` | Example bloat analysis |
| `guides/orchestration-guide.md` | Example bloat analysis |

**Location: `/home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md`**

| Reference | Purpose |
|-----------|---------|
| `guides/test-guide.md` | Example accuracy finding |
| `guides/setup.md` | Example accuracy finding |

These are demonstrating what the agent's output would look like and are not actual links.

---

### 4. Valid References (3 total)

**Location: `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md`**

```
See complete procedure in `.claude/docs/guides/model-rollback-guide.md`
```

**Status**: This is ALMOST correct. The file exists at `.claude/docs/guides/development/model-rollback-guide.md`, but the reference omits the `development/` subdirectory.

**Fix required**: Yes, this needs updating:
- Old: `.claude/docs/guides/model-rollback-guide.md`
- New: `.claude/docs/guides/development/model-rollback-guide.md`

**Updated count**: This brings the "Needs Fix" total to **8 references**.

---

## Recommendations

### 1. Fix the 8 Broken References (High Priority)

**Files to modify**:
1. `/home/benjamin/.config/.claude/commands/setup.md` (2 fixes)
2. `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` (5 fixes)
3. `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md` (1 fix)

**Total effort**: ~10 minutes of work

### 2. Consider Cleaning Up Historical Artifacts (Low Priority)

The `data/` directory contains old plan artifacts with outdated references. These could be:
- Moved to a more explicit archive location
- Kept as-is (they're not actively used)
- Deleted if no longer needed

### 3. Update Agent Example Output (Optional)

The `docs-bloat-analyzer.md` and `docs-accuracy-analyzer.md` agent files contain example output with old paths. While these don't break anything (they're examples), updating them to show current paths would improve documentation accuracy.

### 4. Implement Link Validation CI (Future)

As noted in the previous implementation summary, consider adding automated link checking to catch broken references during development.

---

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/setup.md` - Line numbers 1-2 (approx)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` - Multiple locations
- `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md` - Line containing rollback reference
- `/home/benjamin/.config/.claude/backups/guides-refactor-20251119/guides/*.md` - All files
- `/home/benjamin/.config/.claude/data/602_*/plans/*.md` - Plan artifacts
- `/home/benjamin/.config/.claude/data/602_*/reports/*.md` - Report artifacts
- `/home/benjamin/.config/.claude/data/model_optimization_*.md` - Data files
- `/home/benjamin/.config/.claude/agents/docs-bloat-analyzer.md` - Agent behavioral file
- `/home/benjamin/.config/.claude/agents/docs-accuracy-analyzer.md` - Agent behavioral file

### Directory Structure Reference

```
.claude/docs/guides/
├── commands/           # Command-specific guides
├── development/        # Development guides (agent, command, model)
│   ├── agent-development/
│   └── command-development/
├── orchestration/      # Orchestration and state machine guides
├── patterns/           # Pattern and best practice guides
│   ├── command-patterns/
│   └── execution-enforcement/
└── templates/          # Template files
```
