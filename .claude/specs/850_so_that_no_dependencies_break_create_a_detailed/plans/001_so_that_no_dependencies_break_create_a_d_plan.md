# Documentation Cleanup Implementation Plan

## Metadata
- **Date**: 2025-11-26 (revised from 2025-11-20)
- **Feature**: .claude/docs/ Cleanup and Optimization
- **Scope**: Remove legacy content, fix broken links, establish archive policy
- **Estimated Phases**: 3
- **Estimated Hours**: 4-6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 35.0 (revised from 146.0)
- **Research Reports**:
  - [Documentation Refactoring Research](../reports/001_docs_refactoring_research.md)
  - [Plan Revision Insights](../reports/002_plan_revision_insights.md)
  - [Plan 850 Relevance Review](../../921_no_name_error/reports/001_plan_850_relevance_review.md)

## Revision Summary

This plan was significantly revised on 2025-11-26 based on relevance review findings:
- **Original scope**: 6 phases, 32 hours, 146.0 complexity
- **Revised scope**: 3 phases, 4-6 hours, 35.0 complexity
- **Reason**: Major infrastructure work completed since original plan creation

### What Was Accomplished Since Original Plan
1. **Validation Infrastructure** (Phase 1 objective - complete)
   - `validate-links.sh` exists
   - `validate-all-standards.sh` exists
   - Pre-commit hooks established
2. **Standards Documentation** (Phase 5 objective - complete)
   - `code-standards.md` comprehensive (20855 bytes)
   - `documentation-standards.md` exists (13433 bytes)
   - 400-line threshold documented

### What Remains
1. Legacy content removal (~3,500 lines of duplicate content)
2. Broken link fixes (~21 references, down from 49)
3. Archive retention policy documentation

## Overview

Complete cleanup of `.claude/docs/` directory to remove duplicate legacy content from split files and fix remaining broken links. The validation infrastructure and documentation standards are already in place.

**Key Goals**:
1. Remove ~3,500 lines of duplicate legacy content from two files
2. Fix ~21 broken link references (reduced scope from 49)
3. Document archive retention policy

## Current State Analysis (2025-11-26)

### Legacy Content Still Present (PRIMARY OBJECTIVE)

Two files retain ~3,500 lines of duplicate content that should be removed:

1. **`.claude/docs/concepts/hierarchical-agents.md`** (2206 lines)
   - Lines 1-27: Clean index with split navigation
   - Lines 28-2206: Legacy content marked for removal
   - Split files exist and are well-organized (170-390 lines each)

2. **`.claude/docs/architecture/state-based-orchestration-overview.md`** (1765 lines)
   - Lines 1-29: Clean index with split navigation
   - Lines 30-1765: Legacy content marked for removal
   - Split files exist (189-389 lines each)

### Broken Links Status (REDUCED SCOPE)

Original estimate: 49 broken references
Current finding: ~21 broken references remain

```
reference/agent-reference.md  -> should be reference/standards/agent-reference.md
reference/command-reference.md -> should be reference/standards/command-reference.md
```

### Archive Status

- 38 files exist in archive (12,352 lines, 12.7% of docs)
- No documented retention policy

## Success Criteria
- [ ] Hierarchical-agents legacy content removed (~2,180 lines)
- [ ] State orchestration legacy content removed (~1,735 lines)
- [ ] Index files <100 lines each
- [ ] All CLAUDE.md references functional
- [ ] Broken link count reduced to 0
- [ ] Archive retention policy documented

## Technical Approach

### Strategy

1. **Legacy Removal**: Delete duplicate content below "Legacy Content Below" markers
2. **Link Fixes**: Update incorrect reference paths using existing `validate-links.sh`
3. **Policy Documentation**: Create archive retention policy document

### Risk Mitigation

**Medium Risk: CLAUDE.md References**
- Verify split file navigation works before removing legacy content
- CLAUDE.md references point to index files which will remain functional
- All content exists in split files (no data loss)

**Low Risk: Link Updates**
- Use `validate-links.sh` to verify fixes
- Create redirect stubs at old paths for backward compatibility

## Implementation Phases

### Phase 1: Legacy Content Removal [COMPLETE]
dependencies: []

**Objective**: Remove duplicate legacy content from split index files

**Complexity**: Low

**Tasks**:
- [x] Remove legacy content from hierarchical-agents.md
  - Remove lines 28-2206 (legacy content after index)
  - Verify index structure remains clean (<30 lines)
  - Verify navigation links to split files work
  - File: `.claude/docs/concepts/hierarchical-agents.md`
- [x] Remove legacy content from state-based-orchestration-overview.md
  - Remove lines 30-1765 (legacy content after index)
  - Verify index structure remains clean (<30 lines)
  - Verify navigation links to split files work
  - File: `.claude/docs/architecture/state-based-orchestration-overview.md`
- [x] Verify CLAUDE.md references still functional
  - Index files will remain at same paths
  - Split files contain all content
- [x] Run `validate-links.sh` to confirm no broken references

**Testing**:
```bash
# Verify index files are <100 lines
wc -l .claude/docs/concepts/hierarchical-agents.md | awk '{if ($1 > 100) exit 1}'
wc -l .claude/docs/architecture/state-based-orchestration-overview.md | awk '{if ($1 > 100) exit 1}'

# Verify no legacy content markers remain
! grep -l "Legacy Content Below" .claude/docs/concepts/hierarchical-agents.md
! grep -l "Legacy Content Below" .claude/docs/architecture/state-based-orchestration-overview.md

# Verify links
bash .claude/scripts/validate-links.sh
```

**Success Criteria**:
- [x] hierarchical-agents.md <100 lines
- [x] state-based-orchestration-overview.md <100 lines
- [x] ~3,500 lines removed
- [x] All navigation links functional

**Expected Duration**: 2-3 hours

### Phase 2: Broken Link Fixes [COMPLETE]
dependencies: [1]

**Objective**: Fix remaining broken link references (~21 occurrences)

**Complexity**: Low

**Tasks**:
- [x] Fix broken references to `reference/agent-reference.md`
  - Replace with `reference/standards/agent-reference.md`
  - Found in: README.md, docs-accuracy-analyzer-agent-guide.md
- [x] Fix broken references to `reference/command-reference.md`
  - Replace with `reference/standards/command-reference.md`
  - Found in: README.md
- [x] Create redirect stubs at old paths (optional, for backward compatibility)
  - `.claude/docs/reference/agent-reference.md` → redirect stub
  - `.claude/docs/reference/command-reference.md` → redirect stub
- [x] Run `validate-links.sh` to verify all fixes

**Testing**:
```bash
# Verify no broken reference paths
! grep -r "reference/command-reference.md" .claude/docs/ | grep -v "/standards/"
! grep -r "reference/agent-reference.md" .claude/docs/ | grep -v "/standards/"

# Verify links
bash .claude/scripts/validate-links.sh
```

**Success Criteria**:
- [x] 0 broken link references
- [x] All paths point to correct locations
- [x] Link validation passes

**Expected Duration**: 1-2 hours

### Phase 3: Archive Policy Documentation [COMPLETE]
dependencies: []

**Objective**: Document archive retention policy

**Complexity**: Low

**Tasks**:
- [x] Create or update `.claude/docs/archive/README.md`
  - Document what gets archived and when
  - Document retention period (recommend: 12 months for migration guides)
  - Document annual review process
  - List criteria for keeping vs removing archive files
- [x] Review current archive contents (38 files)
  - Identify any files that should be removed (fully consolidated content)
  - Identify any files that should be kept (unique historical context)

**Testing**:
```bash
# Verify policy document exists
test -f .claude/docs/archive/README.md

# Verify policy covers key topics
grep -q "retention" .claude/docs/archive/README.md
grep -q "review" .claude/docs/archive/README.md
```

**Success Criteria**:
- [x] Archive retention policy documented
- [x] Clear criteria for archiving decisions

**Expected Duration**: 1 hour

## Testing Strategy

### Validation
- Use existing `validate-links.sh` for link checking
- Use existing `validate-all-standards.sh` for comprehensive validation
- Verify CLAUDE.md references remain functional after each phase

### Per-Phase Verification
1. Run link validation
2. Verify file sizes (index files <100 lines)
3. Test navigation from index to split files

## Files to Modify

### Files to Update
- `.claude/docs/concepts/hierarchical-agents.md` - Remove legacy content
- `.claude/docs/architecture/state-based-orchestration-overview.md` - Remove legacy content
- `.claude/docs/README.md` - Fix broken link references
- `.claude/docs/archive/README.md` - Add retention policy

### Files to Create (Optional)
- `.claude/docs/reference/agent-reference.md` - Redirect stub
- `.claude/docs/reference/command-reference.md` - Redirect stub

## Notes

**Revision Summary**: This plan was condensed from 6 phases (32 hours) to 3 phases (4-6 hours) based on:
1. Phase 1 (Foundation/Validation) already complete - infrastructure exists
2. Phase 4 (Remaining Consolidation) deferred - not critical
3. Phase 5 (Structural Improvements) already complete - standards documented
4. Phase 6 (Verification) merged into per-phase testing

**What Remains Critical**:
1. Legacy content removal (3,500 lines of duplicate content)
2. Broken link fixes (~21 references)
3. Archive policy documentation

**Complexity Calculation (Revised)**:
```
Base (cleanup): 3
Tasks: 10 / 2 = 5
Files: 6 * 3 = 18
Integrations: 3 * 3 = 9
Total: 3 + 5 + 18 + 9 = 35.0 (Tier 1: Single file sufficient)
```

**Alternative**: Given the reduced scope (4-6 hours), this work could be executed directly as ad-hoc cleanup tasks without formal plan structure.
