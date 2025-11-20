# Remaining Broken References Fix Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix remaining broken guide references from 816 implementation
- **Scope**: Update 8 broken references across 3 files
- **Estimated Phases**: 2
- **Estimated Hours**: 0.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Complexity Score**: 16
- **Structure Level**: 0
- **Research Reports**:
  - [001_remaining_references_analysis.md](../reports/001_remaining_references_analysis.md)
  - [OVERVIEW.md](../reports/OVERVIEW.md)

## Overview

After implementing plan 816 (broken cross-references fix), verification shows 152 old-style references remain. Research analysis reveals that only **8 references actually require fixing** across 3 files. The remaining references are in:
- Backup directories (31 - historical artifacts, ignore)
- Placeholder examples (4 - documentation patterns, ignore)
- Data/archive directories (expected, ignore)

This plan addresses the 8 broken references that need correction.

## Research Summary

From research report 001_remaining_references_analysis.md:

1. **Files needing fixes**: 3 files contain broken references
2. **Total fixes needed**: 8 path updates
3. **Estimated effort**: ~10 minutes
4. **Categories to ignore**: Backup directories (31), placeholder examples (4)

**Specific findings**:
- `commands/setup.md`: 2 references to old `guides/setup-command-guide.md` path
- `docs/concepts/patterns/executable-documentation-separation.md`: 5 references to old paths
- `docs/guides/development/model-selection-guide.md`: 1 reference missing subdirectory

## Success Criteria
- [ ] All 8 broken references updated to correct new paths
- [ ] No new broken links introduced
- [ ] Grep verification shows 0 broken references in target files
- [ ] All updated paths point to existing files

## Technical Design

### Fix Strategy
Use targeted Edit operations with exact string matching to update each broken reference to its correct new path.

### Path Mappings

| File | Old Path | New Path |
|------|----------|----------|
| commands/setup.md | `guides/setup-command-guide.md` | `guides/commands/setup-command-guide.md` |
| executable-documentation-separation.md | `guides/orchestrate-command-guide.md` | `guides/commands/build-command-guide.md` |
| model-selection-guide.md | `guides/model-rollback-guide.md` | `guides/development/model-rollback-guide.md` |

## Implementation Phases

### Phase 1: Fix Broken References [COMPLETE]
dependencies: []

**Objective**: Update all 8 broken references to correct paths

**Complexity**: Low

Tasks:
- [x] Fix setup.md line 13: Update `.claude/docs/guides/setup-command-guide.md` to `.claude/docs/guides/commands/setup-command-guide.md`
- [x] Fix setup.md line 311: Update `.claude/docs/guides/setup-command-guide.md` to `.claude/docs/guides/commands/setup-command-guide.md`
- [x] Fix executable-documentation-separation.md: Update `guides/orchestrate-command-guide.md` references to `guides/commands/build-command-guide.md` (the orchestrate guide was renamed to build-command-guide)
- [x] Fix executable-documentation-separation.md: Update placeholder examples to use valid current paths or generic placeholder format
- [x] Fix model-selection-guide.md line 347: Update `guides/model-rollback-guide.md` to `guides/development/model-rollback-guide.md`

**Edit Instructions**:

1. **File**: `/home/benjamin/.config/.claude/commands/setup.md`
   - Old: `**Documentation**: See \`.claude/docs/guides/setup-command-guide.md\``
   - New: `**Documentation**: See \`.claude/docs/guides/commands/setup-command-guide.md\``

   - Old: `**Troubleshooting**: See \`.claude/docs/guides/setup-command-guide.md\``
   - New: `**Troubleshooting**: See \`.claude/docs/guides/commands/setup-command-guide.md\``

2. **File**: `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md`
   - Find and replace all `guides/orchestrate-command-guide.md` with `guides/commands/build-command-guide.md`
   - For placeholder examples using non-existent guides like `implement-command-guide.md` or `command-command-guide.md`, update to use generic placeholder format `guides/commands/<command-name>-command-guide.md`

3. **File**: `/home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md`
   - Old: `See complete procedure in \`.claude/docs/guides/model-rollback-guide.md\``
   - New: `See complete procedure in \`.claude/docs/guides/development/model-rollback-guide.md\``

Testing:
```bash
# Verify setup.md references are fixed
grep -n "guides/setup-command-guide\.md" /home/benjamin/.config/.claude/commands/setup.md && echo "FAIL: Still contains old path" || echo "PASS: setup.md fixed"

# Verify executable-documentation-separation.md references
grep -c "guides/orchestrate-command-guide\.md" /home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md && echo "FAIL: Still contains orchestrate ref" || echo "PASS: orchestrate refs fixed"

# Verify model-selection-guide.md reference
grep "guides/model-rollback-guide\.md" /home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md | grep -v "development/" && echo "FAIL: Missing development/ subdirectory" || echo "PASS: model-selection fixed"
```

**Expected Duration**: 0.25 hours

### Phase 2: Verification and Documentation [COMPLETE]
dependencies: [1]

**Objective**: Verify all fixes and document completion

**Complexity**: Low

Tasks:
- [x] Run comprehensive grep to confirm no broken references remain in target files
- [x] Verify all updated paths point to existing files
- [x] Create summary of changes made

Testing:
```bash
# Final verification - check all 3 files have no broken refs
echo "=== Verifying fixes ==="

# Check setup.md
if grep -q "guides/setup-command-guide\.md" /home/benjamin/.config/.claude/commands/setup.md; then
  echo "FAIL: setup.md still has old path"
else
  echo "PASS: setup.md"
fi

# Check executable-documentation-separation.md for old orchestrate refs
if grep -q "guides/orchestrate-command-guide\.md" /home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md; then
  echo "FAIL: executable-documentation-separation.md still has orchestrate ref"
else
  echo "PASS: executable-documentation-separation.md (orchestrate)"
fi

# Check model-selection-guide.md
if grep "guides/model-rollback-guide\.md" /home/benjamin/.config/.claude/docs/guides/development/model-selection-guide.md | grep -qv "development/"; then
  echo "FAIL: model-selection-guide.md missing development/"
else
  echo "PASS: model-selection-guide.md"
fi

# Verify target files exist
echo "=== Verifying target files exist ==="
[ -f /home/benjamin/.config/.claude/docs/guides/commands/setup-command-guide.md ] && echo "PASS: setup-command-guide.md exists" || echo "FAIL: setup-command-guide.md missing"
[ -f /home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md ] && echo "PASS: build-command-guide.md exists" || echo "FAIL: build-command-guide.md missing"
[ -f /home/benjamin/.config/.claude/docs/guides/development/model-rollback-guide.md ] && echo "PASS: model-rollback-guide.md exists" || echo "FAIL: model-rollback-guide.md missing"

echo "=== Verification complete ==="
```

**Expected Duration**: 0.25 hours

## Testing Strategy

### Per-Phase Testing
Each phase includes inline bash verification commands that:
1. Grep for old patterns that should no longer exist
2. Confirm new patterns are present
3. Verify target files exist

### Final Validation
- Run all verification commands from Phase 2
- All should report PASS
- No FAIL results allowed

## Documentation Requirements

No documentation updates needed beyond this plan - the fixes are internal link corrections that don't require external documentation.

## Dependencies

### Prerequisites
- Plan 816 must be complete (verified - summary reviewed)
- Target guide files must exist at new locations (will verify)

### External Dependencies
None - this is a pure edit operation

## Notes

### Files Intentionally Not Fixed
Per research findings, these categories are NOT addressed:
- **Backup directories** (31 refs): Historical artifacts in `.claude/backups/`
- **Placeholder examples** (4 refs): Intentional patterns in agent behavioral files showing example output
- **Data/archive directories**: Old plan/report artifacts

### Agent Example Outputs (Optional Future Work)
The `docs-bloat-analyzer.md` and `docs-accuracy-analyzer.md` agent files contain example output with old paths. While these don't break anything, updating them would improve documentation accuracy. This is deferred as low-priority optional work.
