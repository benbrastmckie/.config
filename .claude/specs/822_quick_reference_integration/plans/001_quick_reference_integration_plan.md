# Quick Reference Integration Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Quick Reference Directory Integration
- **Scope**: Reorganize quick-reference/ directory into reference/decision-trees/ subdirectory
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 41
- **Research Reports**:
  - [Quick Reference Integration Analysis](/home/benjamin/.config/.claude/specs/822_quick_reference_integration/reports/001_quick_reference_integration_analysis.md)

## Overview

This plan implements Option A from the research analysis: moving the `quick-reference/` directory into `reference/decision-trees/` to create a consistent organizational structure. The quick-reference content consists of 6 decision flowchart files (2,145 lines) that provide rapid decision-making support for development tasks. By integrating these into the refactored reference/ directory structure as a dedicated subdirectory, we maintain content cohesion while aligning with the existing 5-subdirectory pattern.

## Research Summary

Key findings from the integration analysis report:

- **Content Purpose**: Quick-reference files are exclusively decision-oriented visual flowcharts (ASCII trees), distinct from the information-lookup documentation in reference/ subdirectories
- **Directory Structure**: Reference/ has 5 subdirectories (architecture, library-api, standards, templates, workflows); adding decision-trees/ creates consistent 6th subdirectory
- **Cross-References**: 15-20 file locations require path updates from `quick-reference/` to `reference/decision-trees/`
- **Diataxis Alignment**: Decision flowcharts are "Reference" content per the framework, so moving them into reference/ is semantically correct
- **Recommended Approach**: Option A (move as subdirectory) preserves content cohesion and fits established patterns

## Success Criteria

- [ ] All 6 quick-reference files moved to reference/decision-trees/ with git history preserved
- [ ] README.md files updated for decision-trees/, reference/, and docs/
- [ ] All cross-references updated (CLAUDE.md, docs/README.md, and other referencing files)
- [ ] Link validation passes with no broken links to quick-reference paths
- [ ] Reference directory maintains consistent subdirectory organization pattern

## Technical Design

### Directory Structure Changes

**Before:**
```
.claude/docs/
├── quick-reference/        (standalone sibling)
│   ├── README.md
│   └── *.md (6 files)
└── reference/
    ├── architecture/
    ├── library-api/
    ├── standards/
    ├── templates/
    └── workflows/
```

**After:**
```
.claude/docs/
└── reference/
    ├── architecture/
    ├── decision-trees/     ← NEW LOCATION
    │   ├── README.md
    │   └── *.md (6 files)
    ├── library-api/
    ├── standards/
    ├── templates/
    └── workflows/
```

### File Move Strategy

Use `git mv` for all file moves to preserve version history:
- Source: `/home/benjamin/.config/.claude/docs/quick-reference/`
- Destination: `/home/benjamin/.config/.claude/docs/reference/decision-trees/`

### Path Update Pattern

All references will change from:
- `quick-reference/filename.md` → `reference/decision-trees/filename.md`
- `.claude/docs/quick-reference/` → `.claude/docs/reference/decision-trees/`

## Implementation Phases

### Phase 1: Create Directory and Move Files [NOT STARTED]
dependencies: []

**Objective**: Create the decision-trees subdirectory and move all quick-reference files with git history preservation

**Complexity**: Low

Tasks:
- [ ] Create decision-trees directory: `/home/benjamin/.config/.claude/docs/reference/decision-trees/`
- [ ] Move README.md: `git mv .claude/docs/quick-reference/README.md .claude/docs/reference/decision-trees/`
- [ ] Move agent-selection-flowchart.md: `git mv .claude/docs/quick-reference/agent-selection-flowchart.md .claude/docs/reference/decision-trees/`
- [ ] Move command-vs-agent-flowchart.md: `git mv .claude/docs/quick-reference/command-vs-agent-flowchart.md .claude/docs/reference/decision-trees/`
- [ ] Move error-handling-flowchart.md: `git mv .claude/docs/quick-reference/error-handling-flowchart.md .claude/docs/reference/decision-trees/`
- [ ] Move executable-vs-guide-content.md: `git mv .claude/docs/quick-reference/executable-vs-guide-content.md .claude/docs/reference/decision-trees/`
- [ ] Move step-pattern-classification-flowchart.md: `git mv .claude/docs/quick-reference/step-pattern-classification-flowchart.md .claude/docs/reference/decision-trees/`
- [ ] Move template-usage-decision-tree.md: `git mv .claude/docs/quick-reference/template-usage-decision-tree.md .claude/docs/reference/decision-trees/`
- [ ] Remove empty quick-reference directory

Testing:
```bash
# Verify files moved correctly
ls -la /home/benjamin/.config/.claude/docs/reference/decision-trees/
# Expect: README.md + 6 flowchart files

# Verify old directory removed
test -d /home/benjamin/.config/.claude/docs/quick-reference && echo "ERROR: Old directory still exists" || echo "OK: Old directory removed"

# Verify git tracking
git status --short | grep -E "^R" | wc -l
# Expect: 7 (all files show as renamed)
```

**Expected Duration**: 0.5 hours

### Phase 2: Update README Files [NOT STARTED]
dependencies: [1]

**Objective**: Update README files to reflect new directory structure and navigation

**Complexity**: Medium

Tasks:
- [ ] Update decision-trees/README.md header **Path** field to reflect new location
- [ ] Update decision-trees/README.md parent navigation link to point to `../README.md`
- [ ] Update reference/README.md to include decision-trees/ in subdirectory listing (file: `/home/benjamin/.config/.claude/docs/reference/README.md`)
- [ ] Add "Decision Trees" section to reference/README.md describing the subdirectory (similar to architecture, standards sections)
- [ ] Update reference/README.md cross-references section that previously linked to quick-reference
- [ ] Update docs/README.md reference to quick-reference (file: `/home/benjamin/.config/.claude/docs/README.md`)
- [ ] Update any internal file path headers in moved files (e.g., `**Path**: .claude/docs/quick-reference/` → `**Path**: .claude/docs/reference/decision-trees/`)

Testing:
```bash
# Verify README updates
grep -l "decision-trees" /home/benjamin/.config/.claude/docs/reference/README.md
# Expect: match found

# Check for stale quick-reference references in README files
grep "quick-reference" /home/benjamin/.config/.claude/docs/reference/README.md /home/benjamin/.config/.claude/docs/README.md
# Expect: no matches

# Verify navigation links work
grep -E "^\[.+\]\(\.\./README\.md\)" /home/benjamin/.config/.claude/docs/reference/decision-trees/README.md
# Expect: parent link found
```

**Expected Duration**: 1 hour

### Phase 3: Update Cross-References [NOT STARTED]
dependencies: [1]

**Objective**: Update all files that reference the quick-reference directory

**Complexity**: Medium

Tasks:
- [ ] Update CLAUDE.md quick_reference section link (file: `/home/benjamin/.config/CLAUDE.md`, line ~155)
- [ ] Update docs/reference/architecture/template-vs-behavioral.md references (lines 161, 463)
- [ ] Update docs/concepts/patterns/executable-documentation-separation.md references (lines 758, 783)
- [ ] Update docs/guides/development/command-development/command-development-troubleshooting.md references (lines 651, 678, 750)
- [ ] Update docs/guides/patterns/refactoring-methodology.md if it references quick-reference
- [ ] Update docs/guides/commands/setup-command-guide.md if it references quick-reference
- [ ] Update docs/reference/workflows/orchestration-reference.md if it references quick-reference
- [ ] Search for and update any remaining `quick-reference` path references in .claude/docs/

Testing:
```bash
# Comprehensive search for stale references
grep -r "quick-reference" /home/benjamin/.config/.claude/docs/ --include="*.md"
# Expect: 0 matches (or only in moved files' internal content, not paths)

# Verify CLAUDE.md updated
grep "reference/decision-trees" /home/benjamin/.config/CLAUDE.md
# Expect: match found

# Check moved files still have correct internal references
head -20 /home/benjamin/.config/.claude/docs/reference/decision-trees/*.md | grep -c "Path:"
# Expect: 6-7 (each file has path header)
```

**Expected Duration**: 1 hour

### Phase 4: Validation and Cleanup [NOT STARTED]
dependencies: [2, 3]

**Objective**: Verify all links work and no broken references remain

**Complexity**: Low

Tasks:
- [ ] Run link validation script: `/home/benjamin/.config/.claude/scripts/validate-links.sh`
- [ ] Search entire .config directory for any remaining `quick-reference` path references
- [ ] Verify all decision-trees files are accessible via their new paths
- [ ] Check git status shows clean state (no untracked files, all moves tracked)
- [ ] Test navigation from reference/README.md to decision-trees subdirectory
- [ ] Confirm docs/README.md correctly links to new location

Testing:
```bash
# Run link validation
cd /home/benjamin/.config && .claude/scripts/validate-links.sh
# Expect: no broken links related to quick-reference

# Final check for stale references (broader search)
grep -r "quick-reference" /home/benjamin/.config --include="*.md" | grep -v "specs/822" | grep -v ".git"
# Expect: 0 matches outside this spec directory

# Verify decision-trees accessible
for file in /home/benjamin/.config/.claude/docs/reference/decision-trees/*.md; do
  test -f "$file" && echo "OK: $(basename $file)" || echo "ERROR: $file missing"
done
# Expect: all files OK

# Git status clean
git status --short | wc -l
# Expect: only expected changes (renamed files, updated refs)
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
- Verify each file moved correctly with git history preserved (`git log --follow`)
- Check each README has correct structure and navigation

### Integration Testing
- Run full link validation to catch broken references
- Verify CLAUDE.md section references resolve correctly
- Test that decision trees are discoverable from reference/README.md

### Validation Approach
1. **File Presence**: Confirm all 7 files exist in decision-trees/
2. **Git History**: Verify `git log --follow` works for moved files
3. **Link Integrity**: All internal and external links resolve
4. **Reference Updates**: No stale `quick-reference` paths remain

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/docs/reference/decision-trees/README.md` - Update path header and navigation
- `/home/benjamin/.config/.claude/docs/reference/README.md` - Add decision-trees section
- `/home/benjamin/.config/.claude/docs/README.md` - Update quick-reference location

### Documentation Standards
- Follow existing README patterns in reference/ subdirectories
- Use relative links for internal navigation
- Include purpose statement and file listing in decision-trees/README.md

## Dependencies

### Prerequisites
- Git repository in clean state (no uncommitted changes in affected files)
- Access to `/home/benjamin/.config/.claude/scripts/validate-links.sh` for validation

### External Dependencies
- None (internal reorganization only)

### Risk Mitigation
- Use `git mv` for all moves to preserve history
- Update all references before committing
- Run validation before finalizing
