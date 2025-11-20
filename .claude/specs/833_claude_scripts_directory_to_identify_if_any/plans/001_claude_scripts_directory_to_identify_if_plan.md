# Unused Scripts Cleanup Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Remove unused scripts and clean up documentation references
- **Scope**: .claude/scripts/ directory and all documentation referencing removed scripts
- **Estimated Phases**: 4
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 60
- **Research Reports**:
  - [Unused Scripts Analysis](/home/benjamin/.config/.claude/specs/833_claude_scripts_directory_to_identify_if_any/reports/001_unused_scripts_analysis.md)

## Overview

This plan removes 5 unused or non-functional scripts from the `.claude/scripts/` directory and cleans up all references to these scripts (and phantom scripts that never existed) throughout the documentation. The goal is to reduce maintenance burden and eliminate confusion from stale references.

## Research Summary

Key findings from the unused scripts analysis:
- **5 scripts to remove**: fix-renamed-files.sh, rollback-link-fixes.sh, fix-duplicate-paths.sh, fix-absolute-to-relative.sh, update-template-references.sh
- **7 phantom scripts**: Scripts referenced in documentation but never existed (analyze-coordinate-performance.sh, context_metrics_dashboard.sh, validate-command-standards.sh, run-command-tests.sh, check-duplicate-commands.sh, view-events.sh, validate-plan-structure.sh)
- **8+ documentation files** require updates to remove stale references
- **validate-agent-behavioral-file.sh** needs better documentation integration

Recommended approach: Remove scripts first, then systematically clean documentation, update README.md last with accurate inventory.

## Success Criteria
- [ ] All 5 unused scripts deleted from .claude/scripts/
- [ ] No references to deleted scripts remain in documentation
- [ ] No references to phantom scripts remain in documentation
- [ ] scripts/README.md accurately reflects current script inventory
- [ ] validate-agent-behavioral-file.sh properly documented
- [ ] All documentation links remain valid after cleanup

## Technical Design

### Approach
1. **Script Deletion**: Remove 5 identified unused scripts directly
2. **Documentation Cleanup**: Edit each affected file to remove stale references
3. **README Rewrite**: Simplify scripts/README.md to reflect actual contents
4. **Validation**: Run link validation to ensure no broken references

### Files to Delete
- `.claude/scripts/update-template-references.sh` (non-functional - same source/destination)
- `.claude/scripts/fix-absolute-to-relative.sh` (legacy one-time migration)
- `.claude/scripts/fix-duplicate-paths.sh` (legacy one-time migration)
- `.claude/scripts/fix-renamed-files.sh` (legacy one-time migration)
- `.claude/scripts/rollback-link-fixes.sh` (companion to unused scripts)

### Documentation Files to Update
1. `.claude/scripts/README.md` - Major rewrite
2. `.claude/docs/concepts/directory-organization.md` - Remove script references
3. `.claude/docs/troubleshooting/broken-links-troubleshooting.md` - Remove fix script references
4. `.claude/docs/concepts/hierarchical-agents.md` - Remove context_metrics_dashboard.sh references
5. `.claude/docs/concepts/robustness-framework.md` - Remove validate-command-standards.sh, run-command-tests.sh
6. `.claude/docs/troubleshooting/duplicate-commands.md` - Remove check-duplicate-commands.sh
7. `.claude/docs/concepts/architectural-decision-framework.md` - Remove validate-plan-structure.sh
8. `.claude/README.md` - Remove context_metrics_dashboard.sh

## Implementation Phases

### Phase 1: Delete Unused Scripts [COMPLETE]
dependencies: []

**Objective**: Remove the 5 unused/non-functional scripts from the scripts directory

**Complexity**: Low

Tasks:
- [x] Delete `.claude/scripts/update-template-references.sh`
- [x] Delete `.claude/scripts/fix-absolute-to-relative.sh`
- [x] Delete `.claude/scripts/fix-duplicate-paths.sh`
- [x] Delete `.claude/scripts/fix-renamed-files.sh`
- [x] Delete `.claude/scripts/rollback-link-fixes.sh`
- [x] Verify scripts directory contains only 5 remaining files plus README.md

Testing:
```bash
# Verify only expected files remain
ls -la /home/benjamin/.config/.claude/scripts/
# Expected: validate-links.sh, validate-links-quick.sh, detect-empty-topics.sh,
#          validate-agent-behavioral-file.sh, markdown-link-check.json, README.md
```

**Expected Duration**: 0.5 hours

### Phase 2: Clean Documentation References to Deleted Scripts [COMPLETE]
dependencies: [1]

**Objective**: Remove all documentation references to the 5 deleted scripts

**Complexity**: Medium

Tasks:
- [x] Edit `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` - Remove references to fix-absolute-to-relative.sh and update-template-references.sh (lines 36-39)
- [x] Edit `/home/benjamin/.config/.claude/docs/troubleshooting/broken-links-troubleshooting.md` - Remove references to fix-duplicate-paths.sh and fix-renamed-files.sh (lines 104, 107)

Testing:
```bash
# Search for references to deleted scripts
cd /home/benjamin/.config
grep -r "fix-renamed-files.sh\|rollback-link-fixes.sh\|fix-duplicate-paths.sh\|fix-absolute-to-relative.sh\|update-template-references.sh" .claude/ --include="*.md" || echo "No references found - success"
```

**Expected Duration**: 0.5 hours

### Phase 3: Clean Phantom Script References [COMPLETE]
dependencies: [1]

**Objective**: Remove all references to scripts that never existed

**Complexity**: Medium

Tasks:
- [x] Edit `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md` - Remove context_metrics_dashboard.sh references (lines 1082, 1087, 1207, 1243)
- [x] Edit `/home/benjamin/.config/.claude/docs/concepts/robustness-framework.md` - Remove validate-command-standards.sh and run-command-tests.sh references (lines 275, 278)
- [x] Edit `/home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md` - Remove check-duplicate-commands.sh reference (line 206)
- [x] Edit `/home/benjamin/.config/.claude/docs/concepts/architectural-decision-framework.md` - Remove validate-plan-structure.sh reference (line 60)
- [x] Edit `/home/benjamin/.config/.claude/README.md` - Remove context_metrics_dashboard.sh reference

Testing:
```bash
# Search for phantom script references
cd /home/benjamin/.config
grep -r "analyze-coordinate-performance.sh\|context_metrics_dashboard.sh\|validate-command-standards.sh\|run-command-tests.sh\|check-duplicate-commands.sh\|view-events.sh\|validate-plan-structure.sh" .claude/ --include="*.md" || echo "No phantom references found - success"
```

**Expected Duration**: 1.5 hours

### Phase 4: Update scripts/README.md and Validate [COMPLETE]
dependencies: [2, 3]

**Objective**: Rewrite scripts README to reflect current accurate inventory and validate all links

**Complexity**: Medium

Tasks:
- [x] Edit `/home/benjamin/.config/.claude/scripts/README.md` - Remove "Link Fixing" section (lines 59-85)
- [x] Edit `/home/benjamin/.config/.claude/scripts/README.md` - Remove analyze-coordinate-performance.sh from "Analysis and Metrics" section (lines 101-108)
- [x] Add documentation for validate-agent-behavioral-file.sh to README.md
- [x] Update script inventory table to show only 5 active scripts
- [x] Run link validation to confirm no broken references

Testing:
```bash
# Validate no broken links in scripts directory
/home/benjamin/.config/.claude/scripts/validate-links-quick.sh /home/benjamin/.config/.claude/scripts/

# Validate no references to removed scripts remain
cd /home/benjamin/.config
grep -r "\.claude/scripts/" .claude/ --include="*.md" | grep -v "validate-links\|detect-empty-topics\|validate-agent-behavioral\|markdown-link-check\|README" || echo "Only valid script references remain"
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Per-Phase Testing
Each phase includes specific grep-based validation to ensure removed references don't persist.

### Final Validation
1. Run `validate-links-quick.sh` on entire .claude/ directory to catch broken links
2. Grep for any remaining references to deleted or phantom scripts
3. Verify scripts/ directory contains exactly 6 files (5 scripts + README.md)

### Validation Commands
```bash
# Final comprehensive check
cd /home/benjamin/.config

# 1. Check scripts directory contents
ls -la .claude/scripts/ | wc -l  # Should be 8 (6 files + . + ..)

# 2. Search for all removed script names
grep -r "fix-renamed-files\|rollback-link-fixes\|fix-duplicate-paths\|fix-absolute-to-relative\|update-template-references\|analyze-coordinate-performance\|context_metrics_dashboard\|validate-command-standards\|run-command-tests\|check-duplicate-commands\|view-events\|validate-plan-structure" .claude/ --include="*.md" || echo "All stale references removed"

# 3. Validate links
.claude/scripts/validate-links-quick.sh .claude/
```

## Documentation Requirements

### Updates Required
- scripts/README.md - Major rewrite to reflect current inventory
- Inline documentation cleanup in 7+ files to remove stale references

### No New Documentation Needed
This is a cleanup/removal operation - no new documentation files are created.

## Dependencies

### Prerequisites
- None - this is a standalone cleanup operation

### External Dependencies
- None

### Potential Blockers
- Some documentation may have sections that need restructuring after removing script references (may require additional context removal beyond just the script mention)

## Notes

- **Complexity Score 60**: Suggests potential for phase expansion during implementation if needed
- If complexity increases during Phase 3 (phantom scripts span many code sections), consider using `/expand phase 3` to break into smaller tasks
- Phase 2 and Phase 3 can run in parallel as they modify different documentation files
