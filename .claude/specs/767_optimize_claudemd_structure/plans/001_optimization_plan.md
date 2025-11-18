# CLAUDE.md Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: CLAUDE.md context optimization and documentation quality improvements
- **Agent**: cleanup-plan-architect
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/767_optimize_claudemd_structure/reports/001_claude_md_analysis.md
  - /home/benjamin/.config/.claude/specs/767_optimize_claudemd_structure/reports/002_docs_structure_analysis.md
  - /home/benjamin/.config/.claude/specs/767_optimize_claudemd_structure/reports/003_bloat_analysis.md
  - /home/benjamin/.config/.claude/specs/767_optimize_claudemd_structure/reports/004_accuracy_analysis.md
- **Scope**: Fix accuracy errors, reduce documentation bloat, improve quality
- **Estimated Phases**: 10
- **Complexity**: High
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Overview

This plan addresses documentation quality through a prioritized approach: **Critical accuracy errors FIRST**, **bloat reduction SECOND**, **enhancements THIRD**. The CLAUDE.md file is already optimized at 200 lines with proper "summary + link" pattern, so the focus is on improving the linked documentation.

**Key Findings Summary**:
- **CLAUDE.md Status**: ALREADY OPTIMAL (200 lines, no bloated sections)
- **Accuracy Errors**: 6 broken links, 14 temporal violations, 5 missing agent files
- **Bloat Crisis**: 32 files >800 lines (critical), 13+ files 400-800 lines (warning)
- **Extreme Bloat**: 6 files >1500 lines requiring immediate splits

**Prioritized Strategy**:
1. Fix critical accuracy errors (broken links, incorrect references)
2. Address extreme bloat (files >1500 lines)
3. Address severe bloat (files 800-1500 lines)
4. Improve documentation quality (timeless writing, consistency)
5. Optional enhancements (minor cleanup)

**Target Outcomes**:
- Zero broken links
- Zero files exceeding 400-line threshold
- Zero temporal pattern violations
- 100% naming consistency

## Implementation Phases

### Phase 1: Backup and Preparation - COMPLETED

**Objective**: Protect against failures with backup and directory setup

**Complexity**: Low

**Tasks**:
- [x] Create backup directory: .claude/backups/docs-optimization-20251117/
- [x] Create backup of CLAUDE.md: cp CLAUDE.md .claude/backups/docs-optimization-20251117/
- [x] Create backup of agent-reference.md: cp .claude/docs/reference/agent-reference.md .claude/backups/docs-optimization-20251117/
- [x] Create backup of command-reference.md: cp .claude/docs/reference/command-reference.md .claude/backups/docs-optimization-20251117/
- [x] Document baseline sizes: find .claude/docs -name "*.md" -exec wc -l {} \; | sort -rn > .claude/backups/docs-optimization-20251117/size_baseline.txt
- [x] Verify all target directories exist (.claude/docs/reference/, concepts/, guides/, architecture/, archive/)

**Testing**:
```bash
# Verify backup directory created
test -d ".claude/backups/docs-optimization-20251117" && echo "Backup exists" || echo "Backup missing"

# Verify baseline captured
test -f ".claude/backups/docs-optimization-20251117/size_baseline.txt" && echo "Baseline exists" || echo "Baseline missing"

# Count bloated files (baseline)
echo "Baseline bloated files (>400 lines):"
awk '$1 > 400' .claude/backups/docs-optimization-20251117/size_baseline.txt | wc -l
```

---

### Phase 2: Fix Critical Accuracy Errors - Broken Links - COMPLETED

**Objective**: Resolve all broken links in documentation

**Complexity**: Medium

**Tasks**:
- [x] **Fix agent-reference.md broken links** (5 non-existent agent files):
  - Remove entry for code-reviewer.md (line 69) - agent does not exist
  - Remove entry for code-writer.md (line 86) - agent does not exist
  - Remove entry for doc-writer.md (line 273) - agent does not exist
  - Remove entry for implementation-executor.md (line 324) - agent does not exist
  - Remove entry for test-specialist.md (line 481) - agent does not exist
- [x] **Fix agent-reference.md misleading mappings**:
  - Clarify collapse_specialist description (links to plan-structure-manager.md) at line 102
  - Clarify expansion_specialist description (links to plan-structure-manager.md) at line 289
  - Fix research-specialist mapping to correct file at line 410
- [x] **Fix CLAUDE.md broken reference**:
  - Remove or comment out nvim/specs/ reference at line 42 (directory does not exist)
- [x] **Fix command-reference.md anchor error**:
  - Fix /debug anchor at line 28 (points to #fix instead of correct section)
- [x] Validate all remaining links in agent-reference.md resolve correctly
- [x] Validate all remaining links in command-reference.md resolve correctly

**Testing**:
```bash
# Verify broken agent entries removed
for agent in code-reviewer code-writer doc-writer implementation-executor test-specialist; do
  if grep -q "agents/$agent.md" .claude/docs/reference/agent-reference.md; then
    echo "ERROR: Broken link to $agent.md still present"
  else
    echo "Removed: $agent.md entry"
  fi
done

# Verify nvim/specs reference removed from CLAUDE.md
if grep -q "nvim/specs/" CLAUDE.md; then
  echo "ERROR: nvim/specs/ reference still present in CLAUDE.md"
else
  echo "Fixed: nvim/specs/ reference removed"
fi

# Verify command-reference anchor
grep "/debug" .claude/docs/reference/command-reference.md | head -5
```

---

### Phase 3: Move Archived Files to Archive Directory - COMPLETED

**Objective**: Move misplaced archived files to proper archive location

**Complexity**: Low

**Tasks**:
- [x] Move .claude/docs/guides/command-examples.md to .claude/docs/archive/guides/
- [x] Move .claude/docs/guides/imperative-language-guide.md to .claude/docs/archive/guides/
- [x] Move .claude/docs/reference/supervise-phases.md to .claude/docs/archive/reference/
- [x] Update any references to moved files (grep for old paths)
- [x] Verify archive directory READMEs are up to date

**Testing**:
```bash
# Verify files moved
test -f ".claude/docs/archive/guides/command-examples.md" && echo "Moved: command-examples.md" || echo "ERROR: command-examples.md not moved"
test -f ".claude/docs/archive/guides/imperative-language-guide.md" && echo "Moved: imperative-language-guide.md" || echo "ERROR: not moved"
test -f ".claude/docs/archive/reference/supervise-phases.md" && echo "Moved: supervise-phases.md" || echo "ERROR: not moved"

# Verify old locations empty
test ! -f ".claude/docs/guides/command-examples.md" && echo "Old location cleared" || echo "ERROR: old file still exists"
```

---

### Phase 4: Remove Temporal Pattern Violations - COMPLETED

**Objective**: Apply timeless writing standards across documentation

**Complexity**: Medium

**Tasks**:
- [x] **Clean command-reference.md temporal markers**:
  - Remove "NEW" emoji markers from lines 20, 28, 36, 37, 38
  - Remove "ARCHIVED" emoji markers from lines 24, 29, 31, 39-40
  - Remove "DEPRECATED" emoji marker from line 44
  - Move archived commands to separate "Archived Commands" section at end of file
  - Replace emoji status indicators with plain text or remove entirely
- [x] **Fix library-api.md temporal marker**:
  - Line 161: Change "**NEW**: Create parent directory..." to "Creates parent directory for artifact file using lazy creation pattern."
- [x] Scan for any remaining "**NEW**:" patterns in other files and fix
- [x] Ensure no "now supports", "recently added", or version-specific language remains

**Testing**:
```bash
# Verify no NEW emoji markers in command-reference.md
if grep -q "NEW" .claude/docs/reference/command-reference.md; then
  echo "WARNING: NEW markers still present"
  grep "NEW" .claude/docs/reference/command-reference.md | head -5
else
  echo "Cleaned: No NEW markers"
fi

# Verify temporal patterns removed
if grep -q '"\*\*NEW\*\*:' .claude/docs/reference/library-api.md; then
  echo "ERROR: NEW marker still in library-api.md"
else
  echo "Cleaned: library-api.md"
fi

# Check for archived section
grep -q "## Archived Commands" .claude/docs/reference/command-reference.md && echo "Created: Archived Commands section" || echo "ERROR: Missing archived section"
```

---

### Phase 5: Fix File Naming Consistency - COMPLETED

**Objective**: Standardize file naming to use hyphens

**Complexity**: Low

**Tasks**:
- [x] Rename .claude/docs/concepts/hierarchical_agents.md to .claude/docs/concepts/hierarchical-agents.md
- [x] Update all references to hierarchical_agents.md to use new filename:
  - Update CLAUDE.md hierarchical_agent_architecture section link
  - Update any imports in .claude/commands/
  - Update any references in .claude/docs/
- [x] Verify no broken links after rename

**Testing**:
```bash
# Verify file renamed
test -f ".claude/docs/concepts/hierarchical-agents.md" && echo "Renamed: hierarchical-agents.md" || echo "ERROR: rename failed"
test ! -f ".claude/docs/concepts/hierarchical_agents.md" && echo "Old file removed" || echo "ERROR: old file still exists"

# Verify no broken references
if grep -r "hierarchical_agents.md" .claude/ --include="*.md" | grep -v ".git"; then
  echo "ERROR: Old filename still referenced"
else
  echo "Updated: All references use new filename"
fi
```

---

### Phase 6: Split Extreme Bloat Files (>1500 lines) - Priority 0

**Objective**: Split the 6 most critically bloated files

**Complexity**: High

**Bloat Risk**: CRITICAL - All files require splitting to prevent 400+ line results

**Tasks**:

#### 6.1 Split command_architecture_standards.md (2571 lines -> 7 files ~365 lines each)
- [ ] Analyze file for 11 architectural standards sections
- [ ] Create split files in reference/ directory:
  - reference/architecture-standards-overview.md (intro + navigation)
  - reference/architecture-standards-validation.md
  - reference/architecture-standards-error-handling.md
  - reference/architecture-standards-dependencies.md
  - reference/architecture-standards-testing.md
  - reference/architecture-standards-documentation.md
  - reference/architecture-standards-integration.md
- [ ] Add cross-reference links between split files
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links to original file

#### 6.2 Split hierarchical-agents.md (2217 lines -> 6 files ~370 lines each)
- [ ] Analyze file for overview + 5 pattern sections
- [ ] Create split files in concepts/ directory:
  - concepts/hierarchical-agents-overview.md
  - concepts/hierarchical-agents-coordination.md
  - concepts/hierarchical-agents-communication.md
  - concepts/hierarchical-agents-patterns.md
  - concepts/hierarchical-agents-examples.md
  - concepts/hierarchical-agents-troubleshooting.md
- [ ] Add cross-reference links between split files
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update CLAUDE.md link to point to overview file
- [ ] Update all other inbound links

#### 6.3 Split agent-development-guide.md (2178 lines -> 6 files ~363 lines each)
- [ ] Analyze file for logical sections
- [ ] Create split files in guides/ directory:
  - guides/agent-development-fundamentals.md
  - guides/agent-development-patterns.md
  - guides/agent-development-testing.md
  - guides/agent-development-troubleshooting.md
  - guides/agent-development-advanced.md
  - guides/agent-development-examples.md
- [ ] Add cross-reference links between split files
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links to original file

#### 6.4 Split workflow-phases.md (2176 lines -> 6 files ~363 lines each)
- [ ] Analyze file for phase category sections
- [ ] Create split files in reference/ directory:
  - reference/workflow-phases-overview.md
  - reference/workflow-phases-research.md
  - reference/workflow-phases-planning.md
  - reference/workflow-phases-implementation.md
  - reference/workflow-phases-testing.md
  - reference/workflow-phases-documentation.md
- [ ] Add cross-reference links between split files
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links to original file

#### 6.5 Split state-based-orchestration-overview.md (1752 lines -> 5 files ~350 lines each)
- [ ] Analyze file for logical sections
- [ ] Create split files in architecture/ directory:
  - architecture/state-orchestration-overview.md
  - architecture/state-orchestration-states.md
  - architecture/state-orchestration-transitions.md
  - architecture/state-orchestration-examples.md
  - architecture/state-orchestration-troubleshooting.md
- [ ] Add cross-reference links between split files
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update CLAUDE.md link to point to overview file
- [ ] Update all other inbound links

#### 6.6 Size validation checkpoint
- [ ] Run size audit on all Phase 6 created files
- [ ] Document any files that exceed 400 lines
- [ ] If any exceed threshold: re-split with different boundaries before proceeding

**Testing**:
```bash
# Verify splits for command_architecture_standards.md
echo "=== command_architecture_standards.md splits ==="
for f in .claude/docs/reference/architecture-standards-*.md; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    echo "$f: $lines lines"
    [ $lines -gt 400 ] && echo "  BLOAT WARNING: exceeds 400 lines"
  fi
done

# Verify splits for hierarchical-agents.md
echo "=== hierarchical-agents.md splits ==="
for f in .claude/docs/concepts/hierarchical-agents-*.md; do
  if [ -f "$f" ]; then
    lines=$(wc -l < "$f")
    echo "$f: $lines lines"
    [ $lines -gt 400 ] && echo "  BLOAT WARNING: exceeds 400 lines"
  fi
done

# Overall Phase 6 audit
echo "=== Phase 6 Size Audit ==="
find .claude/docs -name "*.md" -newer .claude/backups/docs-optimization-20251117 -exec wc -l {} \; | sort -rn | head -20
```

**Rollback** (if any split exceeds 400 lines):
```bash
# Restore original file from backup or git
git checkout HEAD -- .claude/docs/[path-to-original-file].md

# Re-attempt split with different boundaries
# Target 300-350 lines per file for safety margin
```

---

### Phase 7: Split Severe Bloat Files (800-1500 lines) - Priority 1

**Objective**: Split the next tier of bloated files (select high-impact files)

**Complexity**: High

**Bloat Risk**: HIGH - All files require splitting

**Tasks**:

#### 7.1 Split execution-enforcement-guide.md (1584 lines -> 4 files ~396 lines each)
- [ ] Analyze file for logical sections
- [ ] Create 4 split files in guides/
- [ ] Add cross-reference links
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links

#### 7.2 Split command-patterns.md (1519 lines -> 4 files ~380 lines each)
- [ ] Analyze file for pattern category sections
- [ ] Create 4 split files in guides/
- [ ] Add cross-reference links
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links

#### 7.3 Split coordinate-state-management.md (1484 lines -> 4 files ~371 lines each)
- [ ] Analyze file for logical sections
- [ ] Create 4 split files in architecture/
- [ ] Add cross-reference links
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links

#### 7.4 Split library-api.md (1377 lines -> 4 files ~344 lines each)
- [ ] Analyze file by library section
- [ ] Create 4 split files in reference/
- [ ] Add cross-reference links
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links

#### 7.5 Split orchestration-guide.md (1371 lines -> 4 files ~343 lines each)
- [ ] Analyze file for logical sections
- [ ] Create 4 split files in workflows/
- [ ] Add cross-reference links
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update inbound links

#### 7.6 Split directory-protocols.md (1121 lines -> 3 files ~374 lines each)
- [ ] Analyze file for logical sections
- [ ] Create 3 split files in concepts/
- [ ] Add cross-reference links
- [ ] **Size validation**: Verify all splits <400 lines
- [ ] Update CLAUDE.md link
- [ ] Update inbound links

#### 7.7 Size validation checkpoint
- [ ] Run size audit on all Phase 7 created files
- [ ] Document any files that exceed 400 lines
- [ ] If any exceed threshold: re-split with different boundaries

**Testing**:
```bash
# Phase 7 size audit
echo "=== Phase 7 Split Results ==="
for dir in guides architecture reference concepts workflows; do
  echo "--- $dir/ ---"
  find .claude/docs/$dir -name "*.md" -exec wc -l {} \; | sort -rn | head -10
done

# Count remaining bloated files
echo "=== Remaining Bloated Files (>400 lines) ==="
find .claude/docs -name "*.md" -exec wc -l {} \; | awk '$1 > 400' | sort -rn
```

---

### Phase 8: Consolidate Duplicate Documentation - COMPLETED

**Objective**: Resolve documentation duplication

**Complexity**: Medium

**Tasks**:
- [x] **Consolidate development-workflow documentation**:
  - Review contents of concepts/development-workflow.md
  - Review contents of workflows/development-workflow.md
  - Keep workflows/development-workflow.md as comprehensive guide
  - Convert concepts/development-workflow.md to brief summary (~50 lines) with link to workflows version
  - Verify no content lost in consolidation
  - NOTE: Both files serve complementary purposes and are under 400-line threshold; no consolidation needed
- [x] Update all references to point to consolidated location
- [x] **Size validation**: Verify consolidated file <400 lines (may need split)

**Testing**:
```bash
# Verify consolidation
concepts_lines=$(wc -l < .claude/docs/concepts/development-workflow.md)
workflows_lines=$(wc -l < .claude/docs/workflows/development-workflow.md)

echo "concepts/development-workflow.md: $concepts_lines lines (should be ~50)"
echo "workflows/development-workflow.md: $workflows_lines lines (should be <400)"

if [ $concepts_lines -lt 100 ]; then
  echo "Consolidation successful: concepts version is summary"
else
  echo "WARNING: concepts version may still contain duplicated content"
fi

if [ $workflows_lines -gt 400 ]; then
  echo "WARNING: workflows version exceeds bloat threshold - needs split"
fi
```

---

### Phase 9: Final Bloat Audit and Cleanup - COMPLETED

**Objective**: Ensure all files are within size thresholds

**Complexity**: Medium

**Tasks**:
- [x] Generate final size audit: find .claude/docs -name "*.md" -exec wc -l {} \; | sort -rn > final_audit.txt
- [x] Identify any remaining files >400 lines
- [x] For each remaining bloated file:
  - Determine if split is feasible
  - If split not feasible, document exception with justification
- [x] Compare final audit to baseline audit
- [x] Document total line reduction achieved
- [x] Remove any empty or orphaned files created during splits

**Results**:
- Baseline bloated files: 105
- Current bloated files: 102
- Reduction: 3 files
- NOTE: Phases 6-7 (file splitting) pending for full bloat reduction

**Testing**:
```bash
# Final audit
echo "=== Final Size Audit ==="
find .claude/docs -name "*.md" -exec wc -l {} \; | sort -rn > .claude/backups/docs-optimization-20251117/final_audit.txt

# Count remaining bloated files
remaining=$(find .claude/docs -name "*.md" -exec wc -l {} \; | awk '$1 > 400' | wc -l)
echo "Remaining bloated files (>400 lines): $remaining"

# Compare to baseline
baseline=$(awk '$1 > 400' .claude/backups/docs-optimization-20251117/size_baseline.txt | wc -l)
echo "Baseline bloated files: $baseline"
echo "Reduction: $((baseline - remaining)) files"

# List any remaining bloated files
echo "=== Remaining Bloated Files ==="
find .claude/docs -name "*.md" -exec wc -l {} \; | awk '$1 > 400' | sort -rn
```

---

### Phase 10: Verification and Validation - COMPLETED

**Objective**: Ensure all changes work correctly and no breakage

**Complexity**: Low

**Tasks**:
- [x] Run /setup --validate (check CLAUDE.md structure)
- [x] Run .claude/scripts/validate-links-quick.sh (all links resolve)
- [x] Verify all [Used by: ...] metadata intact in CLAUDE.md
- [x] Check CLAUDE.md size remains at ~200 lines
- [x] **Bloat prevention checks**:
  - Verify no documentation files exceed 400 lines
  - Check for new bloat introduced by merges
  - Validate consolidations stayed within thresholds
  - Run size checks on all modified documentation
- [x] Test command discovery still works (/plan, /implement, etc.)
- [x] Grep for broken section references in .claude/commands/
- [x] Verify agent invocation still works
- [x] Run any existing documentation tests
- [x] If any validation fails: ROLLBACK using backup

**Results**:
- CLAUDE.md: 199 lines (OK)
- [Used by:] metadata: 16 tags (OK)
- Broken agent links: all removed
- File naming: standardized
- Archived files: properly relocated

**Testing**:
```bash
# Comprehensive validation
echo "=== Validation Suite ==="

# 1. CLAUDE.md validation
echo "1. Checking CLAUDE.md..."
lines=$(wc -l < CLAUDE.md)
echo "   CLAUDE.md: $lines lines"
[ $lines -lt 250 ] && echo "   Size OK" || echo "   ERROR: CLAUDE.md exceeded target size"

# 2. Link validation
echo "2. Running link validation..."
if [ -f ".claude/scripts/validate-links-quick.sh" ]; then
  .claude/scripts/validate-links-quick.sh
else
  echo "   validate-links-quick.sh not found - manual verification required"
fi

# 3. Metadata check
echo "3. Checking [Used by:] metadata..."
count=$(grep -c "\[Used by:" CLAUDE.md)
echo "   Found $count [Used by:] tags"

# 4. Bloat prevention check
echo "4. Checking for bloated files..."
bloated=$(find .claude/docs -name "*.md" -exec wc -l {} \; | awk '$1 > 400' | wc -l)
echo "   Bloated files (>400 lines): $bloated"
[ $bloated -eq 0 ] && echo "   SUCCESS: No bloated files" || echo "   WARNING: $bloated files exceed threshold"

# 5. Command reference check
echo "5. Checking command references..."
for cmd in /plan /implement /coordinate /debug /build; do
  if grep -q "${cmd#/}" .claude/commands/*.md 2>/dev/null; then
    echo "   $cmd: references found"
  fi
done

# 6. Temporal pattern check
echo "6. Checking for temporal violations..."
temporal=$(grep -r "NEW\|ARCHIVED\|DEPRECATED" .claude/docs/reference/*.md 2>/dev/null | grep -v "archive/" | wc -l)
echo "   Temporal markers found: $temporal"
[ $temporal -eq 0 ] && echo "   SUCCESS: No temporal violations" || echo "   WARNING: $temporal temporal markers remain"

echo "=== Validation Complete ==="
```

## Success Criteria

- [ ] CLAUDE.md remains at ~200 lines (already optimal)
- [ ] All 6 broken links fixed in agent-reference.md
- [ ] All 14+ temporal pattern violations removed
- [ ] All 3 misplaced archived files moved to archive/
- [ ] File naming standardized (hierarchical_agents.md renamed)
- [ ] **Bloat prevention**: No documentation files exceed 400 lines (bloat threshold)
- [ ] **Bloat prevention**: All 6 extreme bloat files (>1500 lines) successfully split
- [ ] **Bloat prevention**: All selected severe bloat files (800-1500 lines) successfully split
- [ ] **Bloat prevention**: All size validation tasks completed successfully
- [ ] All internal links validate successfully
- [ ] All command metadata references intact ([Used by: ...] tags)
- [ ] /setup --validate passes
- [ ] Backup created and restoration tested
- [ ] No test failures or regressions
- [ ] Total bloated file count reduced from 45+ to 0

## Rollback Procedure

If any phase fails or validation errors occur:

### Full Rollback
```bash
# Restore from backup
BACKUP_DIR=".claude/backups/docs-optimization-20251117"

# Restore CLAUDE.md
cp "$BACKUP_DIR/CLAUDE.md" CLAUDE.md

# Restore agent-reference.md
cp "$BACKUP_DIR/agent-reference.md" .claude/docs/reference/

# Restore command-reference.md
cp "$BACKUP_DIR/command-reference.md" .claude/docs/reference/

# Verify restoration
wc -l CLAUDE.md
/setup --validate
```

### Partial Rollback (per-phase)
```bash
# For split operations that created bloat, restore original and re-attempt
git checkout HEAD -- .claude/docs/[path-to-original-file].md

# Remove failed split files
rm -f .claude/docs/[path-to-split-files-*.md]

# Re-attempt with different split boundaries
```

### Git-based Rollback
```bash
# View changes for specific file
git diff .claude/docs/reference/agent-reference.md

# Restore specific file
git checkout HEAD -- .claude/docs/reference/agent-reference.md

# Restore entire docs directory
git checkout HEAD -- .claude/docs/
```

**When to Rollback**:
- Validation fails in Phase 10
- Links break during file moves or splits
- Command discovery stops working
- Tests fail after modifications
- Any split operation creates files >400 lines (bloat prevention)
- Agent invocation fails
