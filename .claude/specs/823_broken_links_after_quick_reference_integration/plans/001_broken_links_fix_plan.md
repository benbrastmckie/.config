# Broken Links Fix Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Fix broken links after reference directory restructuring
- **Scope**: Update 102+ broken link references across ~50 files in .claude/docs/
- **Estimated Phases**: 5
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Complexity Score**: 165.5 (Tier 2)
- **Structure Level**: 0
- **Research Reports**:
  - [Link Validation Results](../reports/001_link_validation_results.md)
  - [Broken Link Analysis](../reports/002_broken_link_analysis.md)

## Overview

Following the quick-reference integration (spec 822) and reference directory restructuring (spec 767), the documentation contains 102+ broken link references. These fall into three categories:

1. **Category A (Critical)**: 80+ references to `command_architecture_standards.md` which was split and moved to `reference/architecture/` subdirectory
2. **Category B (Medium)**: ~10 references to `library-api-overview.md` which moved to `reference/library-api/overview.md`
3. **Category C (Medium)**: ~12 references to `phase_dependencies.md` which moved to `reference/workflows/phase-dependencies.md`

The quick-reference to decision-trees migration completed successfully with no broken links.

## Research Summary

Key findings from research reports:

1. **Category A Investigation** (from Report 002):
   - `command_architecture_standards.md` was intentionally SPLIT during spec 767
   - The stub file exists but references old intermediate paths (`architecture-standards-*.md`)
   - Split files were renamed during move to `architecture/` subdirectory
   - Main entry point should be `architecture/overview.md`
   - Affects 40+ unique files with 80+ total references

2. **Category B Analysis** (from Report 001):
   - Simple path change: `library-api-overview.md` → `library-api/overview.md`
   - Files within `library-api/` directory need relative path fixes
   - Files outside need full path updates

3. **Category C Analysis** (from Report 001 & 002):
   - Path AND filename change: `phase_dependencies.md` → `workflows/phase-dependencies.md`
   - Underscore to hyphen filename change

Recommended approach: Bulk sed replacements for B and C, targeted updates for A with stub file cleanup.

## Success Criteria

- [ ] All links in `/home/benjamin/.config/.claude/docs/` resolve correctly
- [ ] `validate-links-quick.sh` reports 0 broken links
- [ ] `validate-links.sh` full validation passes
- [ ] The stub `command_architecture_standards.md` is either removed or updated with correct paths
- [ ] Documentation index files (README.md files) are updated to reflect new structure
- [ ] No regression in existing valid links

## Technical Design

### Architecture Overview

The reference directory underwent a restructuring that moved files into subdirectories:

```
reference/
├── architecture/           # Split from command_architecture_standards.md
│   ├── overview.md        # Main entry point
│   ├── validation.md
│   ├── documentation.md
│   ├── integration.md
│   ├── dependencies.md
│   ├── error-handling.md
│   └── testing.md
├── library-api/            # Moved from reference/
│   ├── overview.md        # Was library-api-overview.md
│   ├── persistence.md
│   ├── state-machine.md
│   └── utilities.md
├── workflows/              # Moved from reference/
│   ├── phase-dependencies.md  # Was phase_dependencies.md
│   └── ...
└── ...
```

### Link Update Strategy

1. **Category A**: Replace `reference/command_architecture_standards.md` with `reference/architecture/overview.md`
2. **Category B**: Replace `reference/library-api-overview.md` with `reference/library-api/overview.md`
3. **Category C**: Replace `reference/phase_dependencies.md` with `reference/workflows/phase-dependencies.md`

Special handling required for:
- Anchor links (e.g., `#context-preservation-standards`) - may need mapping to new file locations
- Relative paths within subdirectories
- The stub file itself

## Implementation Phases

### Phase 1: Fix Library API Overview Links [COMPLETE]
dependencies: []

**Objective**: Update all references to `library-api-overview.md` to point to new location

**Complexity**: Low

Tasks:
- [x] Fix relative links within `library-api/` subdirectory files (file: /home/benjamin/.config/.claude/docs/reference/library-api/state-machine.md)
- [x] Fix relative links within `library-api/` subdirectory files (file: /home/benjamin/.config/.claude/docs/reference/library-api/utilities.md)
- [x] Fix relative links within `library-api/` subdirectory files (file: /home/benjamin/.config/.claude/docs/reference/library-api/persistence.md)
- [x] Fix external references to `reference/library-api-overview.md` (file: /home/benjamin/.config/.claude/docs/concepts/directory-protocols-overview.md lines 158, 189)
- [x] Verify all anchor links still resolve (e.g., `#allocate_and_create_topic`, `#ensure_artifact_directory`)

Testing:
```bash
# Verify no remaining references to old path
grep -r "library-api-overview" /home/benjamin/.config/.claude/docs --include="*.md" | grep -v "specs/"
# Expected: No results

# Verify new links exist
test -f /home/benjamin/.config/.claude/docs/reference/library-api/overview.md && echo "Target file exists"
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Fix Phase Dependencies Links [COMPLETE]
dependencies: []

**Objective**: Update all references to `phase_dependencies.md` to point to new location with correct filename

**Complexity**: Low

Tasks:
- [x] Update link in `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md` (line 476)
- [x] Update links in `/home/benjamin/.config/.claude/docs/workflows/README.md` (lines 51, 248)
- [x] Update links in `/home/benjamin/.config/.claude/docs/concepts/directory-protocols-overview.md` (line 358)
- [x] Update links in `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` (line 984)
- [x] Update links in `/home/benjamin/.config/.claude/docs/README.md` (lines 50, 362, 558)
- [x] Verify plain text mentions don't need updating (non-link references)

Testing:
```bash
# Verify no remaining references to old path
grep -r "phase_dependencies" /home/benjamin/.config/.claude/docs --include="*.md" | grep -v "specs/"
# Expected: No results (or only plain text mentions)

# Verify new file exists
test -f /home/benjamin/.config/.claude/docs/reference/workflows/phase-dependencies.md && echo "Target file exists"
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Fix Command Architecture Standards Links [COMPLETE]
dependencies: []

**Objective**: Update all 80+ references to `command_architecture_standards.md` to point to new `architecture/overview.md`

**Complexity**: Medium

Tasks:
- [x] Bulk update references in main documentation index (file: /home/benjamin/.config/.claude/docs/README.md - 7 references)
- [x] Update references in concepts directory (files: directory-protocols-overview.md, directory-protocols.md, robustness-framework.md, hierarchical-agents.md, README.md)
- [x] Update references in workflows directory (files: orchestration-guide.md, orchestration-guide-overview.md, spec_updater_guide.md, checkpoint_template_guide.md)
- [x] Update references in troubleshooting directory (files: README.md, agent-delegation-troubleshooting.md, inline-template-duplication.md, bash-tool-limitations.md)
- [x] Update references in patterns directory (files: README.md, executable-documentation-separation.md, behavioral-injection.md, verification-fallback.md, defensive-programming.md, llm-classification-pattern.md)
- [x] Update references in guides directory (files: README.md, templates/README.md, patterns/*.md, commands/*.md, orchestration/*.md, development/*.md)
- [x] Update references in reference directory (files: standards/*.md, architecture/*.md, decision-trees/*.md)
- [x] Handle anchor link remapping (e.g., `#context-preservation-standards` -> check if anchor exists in overview.md or needs routing to specific file)
- [x] Verify Standard references (0, 0.5, 1-5, 11, 12-14, 15-16) map correctly to new split files

Testing:
```bash
# Verify no remaining references to old path
grep -r "command_architecture_standards" /home/benjamin/.config/.claude/docs --include="*.md" | grep -v "specs/"
# Expected: Only the stub file itself (if kept) or no results

# Verify main entry point exists
test -f /home/benjamin/.config/.claude/docs/reference/architecture/overview.md && echo "Target file exists"
```

**Expected Duration**: 1.5 hours

---

### Phase 4: Update or Remove Stub File [COMPLETE]
dependencies: [3]

**Objective**: Clean up the `command_architecture_standards.md` stub file that contains outdated redirect paths

**Complexity**: Low

Tasks:
- [x] Assess whether to keep or remove the stub file (file: /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md)
- [x] If keeping: Update redirect paths to correct new locations in `architecture/` subdirectory
- [x] If removing: Delete the stub file and ensure no references remain
- [x] Update reference/README.md to reflect final structure decision
- [x] Verify git status shows expected changes

Testing:
```bash
# If removed, verify file doesn't exist
test ! -f /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md && echo "Stub removed"

# If kept, verify redirects point to correct paths
grep "architecture/overview.md" /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md
```

**Expected Duration**: 0.5 hours

---

### Phase 5: Validation and Documentation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Run full validation and update index documentation to reflect new structure

**Complexity**: Medium

Tasks:
- [x] Run quick validation script (script: /home/benjamin/.config/.claude/scripts/validate-links-quick.sh)
- [x] Run full validation script (script: /home/benjamin/.config/.claude/scripts/validate-links.sh)
- [x] Fix any additional broken links discovered during validation
- [x] Update /home/benjamin/.config/.claude/docs/README.md file tree structure if needed
- [x] Update /home/benjamin/.config/.claude/docs/reference/README.md navigation guide
- [x] Verify all anchor links in decision-trees/flowcharts still work
- [x] Create summary of all changes made

Testing:
```bash
# Run quick validation
cd /home/benjamin/.config
bash .claude/scripts/validate-links-quick.sh
# Expected: 0 broken links

# Run full validation
bash .claude/scripts/validate-links.sh
# Expected: 0 broken links

# Verify no orphaned files
ls -la .claude/docs/reference/*.md | grep -v README
# Expected: Only README.md at top level (all others moved to subdirectories)
```

**Expected Duration**: 1 hour

## Testing Strategy

### Phase-Level Testing
Each phase includes specific test commands to verify:
1. Old paths no longer referenced (grep verification)
2. New target files exist (file existence check)
3. Links resolve correctly (manual spot-check of 2-3 files per category)

### Full Validation
After all phases complete:
1. Run `validate-links-quick.sh` for recent file check
2. Run `validate-links.sh` for comprehensive validation
3. Spot-check 5 critical files manually (README.md files, main guides)

### Regression Testing
Verify these valid patterns still work:
- Internal anchors (e.g., `#quick-reference`)
- Cross-directory links
- Relative paths within subdirectories

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/docs/README.md` - Update file tree to reflect new structure
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Update navigation to new subdirectory structure
- `/home/benjamin/.config/.claude/docs/reference/architecture/README.md` - Ensure index is complete

### Summary Document
Create implementation summary in `specs/823_*/summaries/` documenting:
- Total links fixed per category
- Files modified count
- Any special handling performed
- Validation results

## Dependencies

### External Dependencies
- Git repository state must be clean for accurate diff tracking
- Validation scripts must be functional

### Phase Dependencies
- Phases 1-3 can run in parallel (independent categories)
- Phase 4 depends on Phase 3 (stub cleanup after main links fixed)
- Phase 5 depends on all previous phases (validation after all fixes)

### Prerequisites
- Research reports completed and reviewed
- Understanding of spec 767 restructuring decisions
- Access to validation scripts

## Risks and Mitigations

### Risk 1: Anchor Links May Not Exist in New Files
**Mitigation**: Phase 3 includes task to verify anchor remapping. If anchors moved to different split files, update links to correct file.

### Risk 2: Bulk Sed May Over-Match
**Mitigation**: Use specific patterns with path prefixes, exclude specs/ directory, verify results with grep after.

### Risk 3: Hidden Broken Links in Less Common Files
**Mitigation**: Full validation script catches all .md files, not just common ones.
