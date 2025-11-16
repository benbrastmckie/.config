# CLAUDE.md Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-16
- **Feature**: CLAUDE.md context optimization and documentation quality improvement
- **Agent**: cleanup-plan-architect
- **Research Reports**:
  - CLAUDE.md Analysis: /home/benjamin/.config/.claude/specs/723_optimize_claudemd_structure/reports/001_claude_md_analysis.md
  - Docs Structure Analysis: /home/benjamin/.config/.claude/specs/723_optimize_claudemd_structure/reports/002_docs_structure_analysis.md
  - Bloat Analysis: /home/benjamin/.config/.claude/specs/723_optimize_claudemd_structure/reports/003_bloat_analysis.md
  - Accuracy Analysis: /home/benjamin/.config/.claude/specs/723_optimize_claudemd_structure/reports/004_accuracy_analysis.md
- **Scope**: Fix critical accuracy errors, reduce CLAUDE.md bloat via link-only conversions, prevent new bloat
- **Estimated Phases**: 5 phases (1 critical error fix + 1 bloat reduction + 1 quality enhancement + 1 validation + 1 final verification)
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Overview

This plan optimizes CLAUDE.md and improves documentation quality through a three-priority approach: (1) fix critical accuracy errors FIRST, (2) reduce CLAUDE.md bloat SECOND, (3) enhance documentation quality THIRD.

**CRITICAL FINDING**: CLAUDE.md is already well-optimized (364 lines, no bloated sections >80 lines), but contains 1 broken link and 9 verbose sections with duplicate content. All verbose sections already have comprehensive documentation files in .claude/docs/. The optimization is pure **deletion** (link-only conversions) with ZERO new file creation and ZERO file merges.

**Priority 1: Critical Accuracy Errors** (1 error)
- Fix broken link to fail-fast policy analysis report (CLAUDE.md:120)

**Priority 2: CLAUDE.md Bloat Reduction** (169 lines saved)
- Convert 9 verbose sections to link-only format (4-line pattern)
- NO new files created (all targets exist)
- NO file merges (prevents bloat in already-bloated .claude/docs/ files)
- Pure deletion operation with ZERO bloat risk

**Priority 3: Quality Enhancements** (Optional)
- Fix relative path format in directory-organization.md
- Create archive/guides/README.md for 100% README coverage

**Bloat Prevention Strategy**:
- ZERO new files created (all documentation exists)
- ZERO file modifications except CLAUDE.md (prevents merge bloat)
- Size validation after every conversion (must = 4 lines)
- Rollback triggers if any file >400 lines created (SHOULD NOT HAPPEN)

**Target Metrics**:
- CLAUDE.md: 364 lines → ~195 lines (46% reduction)
- Broken links: 1 → 0 (100% fix rate)
- Link-only sections: 4/13 → 13/13 (100% optimal)
- New bloat: 0 files >400 lines created

## Implementation Phases

### Phase 0: Baseline Audit and Critical Error Fix

**Objective**: Record baseline state, create backup, and fix critical broken link BEFORE any optimization

**Complexity**: Low

**Tasks**:
- [ ] Create baseline snapshot:
  ```bash
  mkdir -p /home/benjamin/.config/.claude/tmp/baselines
  wc -l /home/benjamin/.config/CLAUDE.md > /home/benjamin/.config/.claude/tmp/baselines/claude-md-baseline.txt
  echo "Baseline size: $(cat /home/benjamin/.config/.claude/tmp/baselines/claude-md-baseline.txt)"
  ```
- [ ] Document all 16 SECTION markers and their current sizes
- [ ] Verify all 13 target documentation files exist
- [ ] Create backup: /home/benjamin/.config/.claude/tmp/backups/CLAUDE.md.20251116-$(date +%H%M%S)
- [ ] **FIX CRITICAL BROKEN LINK** (Priority 1 - MUST BE FIRST):
  - File: /home/benjamin/.config/CLAUDE.md, line ~120
  - Error: References `.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md` (does not exist)
  - Action: Remove sentence "See [Fail-Fast Policy Analysis](.claude/specs/634_001_coordinate_improvementsmd_implements/reports/001_fail_fast_policy_analysis.md) for complete taxonomy."
  - Rationale: Fail-fast philosophy already documented in writing-standards.md (no content loss)

**Testing**:
```bash
# Verify baseline created
BASELINE_FILE="/home/benjamin/.config/.claude/tmp/baselines/claude-md-baseline.txt"
test -f "$BASELINE_FILE" && echo "✓ Baseline exists" || echo "✗ Baseline missing"

# Verify backup created
BACKUP_DIR="/home/benjamin/.config/.claude/tmp/backups"
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/CLAUDE.md.20251116-* 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 0 ]; then
  echo "✓ Backup created ($BACKUP_COUNT files)"
else
  echo "✗ No backup found"
fi

# Verify target files exist
TARGET_FILES=(
  "/home/benjamin/.config/.claude/docs/concepts/writing-standards.md"
  "/home/benjamin/.config/.claude/docs/troubleshooting/duplicate-commands.md"
  "/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md"
  "/home/benjamin/.config/.claude/docs/quick-reference/README.md"
  "/home/benjamin/.config/.claude/docs/concepts/development-workflow.md"
  "/home/benjamin/.config/.claude/docs/reference/command-reference.md"
  "/home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md"
  "/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md"
)

for file in "${TARGET_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ Target exists: $(basename $file)"
  else
    echo "✗ MISSING: $file"
    exit 1
  fi
done

# Verify broken link is FIXED
if grep -q "634_001_coordinate_improvementsmd_implements" /home/benjamin/.config/CLAUDE.md; then
  echo "✗ CRITICAL ERROR: Broken link still present"
  exit 1
else
  echo "✓ Broken link removed"
fi
```

**Success Criteria**:
- Baseline snapshot created
- Backup created in tmp/backups/
- All 8 target documentation files verified to exist
- **Broken link removed (critical error fixed)**

**Rollback Trigger**: If any target file missing (SHOULD NOT HAPPEN - all verified to exist)

---

### Phase 1: Critical Priority Reductions (4 sections, 142 lines saved)

**Objective**: Convert 4 highest-priority verbose sections to link-only format

**Complexity**: Low

**Bloat Risk**: ZERO (pure deletion, no file creation/merge)

**Tasks**:

- [ ] **Convert development_philosophy** (51 lines → 4 lines):
  - Current location: CLAUDE.md lines ~83-131
  - Target: `.claude/docs/concepts/writing-standards.md` (NOT modified)
  - Action: DELETE 47 lines of inline content, INSERT 4-line link format
  - Link text: "See [Writing Standards](.claude/docs/concepts/writing-standards.md) for complete development philosophy, clean-break approach, and documentation standards."
  - Verify: Section size = 4 lines (1 header + 1 metadata + 1 blank + 1 link)
  - Verify: Link target exists and is accessible
  - Verify: [Used by: /refactor, /implement, /plan, /document] metadata preserved

- [ ] **Convert configuration_portability** (41 lines → 4 lines):
  - Current location: CLAUDE.md lines ~216-258
  - Target: `.claude/docs/troubleshooting/duplicate-commands.md` (NOT modified)
  - Action: DELETE 37 lines of inline content, INSERT 4-line link format
  - Link text: "See [Duplicate Commands Troubleshooting](.claude/docs/troubleshooting/duplicate-commands.md) for command/agent/hook discovery hierarchy and configuration portability."
  - Verify: Section size = 4 lines
  - Verify: Link target exists
  - Verify: [Used by: all commands, project setup, troubleshooting] metadata preserved

- [ ] **Convert adaptive_planning** (34 lines → 4 lines):
  - Current location: CLAUDE.md lines ~133-168
  - Target: `.claude/docs/workflows/adaptive-planning-guide.md` (NOT modified)
  - Action: DELETE 30 lines of inline content, INSERT 4-line link format
  - Link text: "See [Adaptive Planning Guide](.claude/docs/workflows/adaptive-planning-guide.md) for intelligent plan revision capabilities, automatic triggers, and loop prevention."
  - Verify: Section size = 4 lines
  - Verify: Link target exists
  - Verify: [Used by: /implement] metadata preserved

- [ ] **Convert quick_reference** (32 lines → 4 lines):
  - Current location: CLAUDE.md lines ~273-308
  - Target: `.claude/docs/quick-reference/README.md` (NOT modified)
  - Action: DELETE 28 lines of inline content, INSERT 4-line link format
  - Link text: "See [Quick Reference](.claude/docs/quick-reference/README.md) for common tasks, setup utilities, command/agent references, and navigation links."
  - Verify: Section size = 4 lines
  - Verify: Link target exists
  - Verify: [Used by: all commands] metadata preserved

- [ ] **CHECKPOINT 1**: Verify cumulative reduction ~142 lines after 4 sections

**Testing**:
```bash
# Verify each section reduced to exactly 4 lines
SECTIONS=("development_philosophy" "configuration_portability" "adaptive_planning" "quick_reference")

for section in "${SECTIONS[@]}"; do
  # Extract section content between SECTION markers
  SECTION_SIZE=$(sed -n "/<!-- SECTION: $section -->/,/<!-- END_SECTION: $section -->/p" /home/benjamin/.config/CLAUDE.md | wc -l)

  # Should be exactly 6 lines: marker + header + metadata + blank + link + end marker
  # (4 content lines + 2 comment markers)
  if [ "$SECTION_SIZE" -eq 6 ]; then
    echo "✓ $section reduced to link-only (6 lines including markers)"
  else
    echo "✗ $section has $SECTION_SIZE lines (expected 6)"
    exit 1
  fi
done

# Verify no files modified except CLAUDE.md
MODIFIED_COUNT=$(git diff --name-only | grep -v "CLAUDE.md" | wc -l)
if [ "$MODIFIED_COUNT" -eq 0 ]; then
  echo "✓ Only CLAUDE.md modified (no file merges)"
else
  echo "✗ WARNING: Other files modified:"
  git diff --name-only | grep -v "CLAUDE.md"
fi

# Verify all links resolve
BROKEN_LINKS=$(grep -o '\.claude/docs/[^)]*\.md' /home/benjamin/.config/CLAUDE.md | while read link; do
  if [ ! -f "/home/benjamin/.config/$link" ]; then
    echo "$link"
  fi
done | wc -l)

if [ "$BROKEN_LINKS" -eq 0 ]; then
  echo "✓ All links resolve correctly"
else
  echo "✗ CRITICAL: $BROKEN_LINKS broken links found"
  exit 1
fi

# Verify metadata preserved
for section in "${SECTIONS[@]}"; do
  if grep -A 2 "<!-- SECTION: $section -->" /home/benjamin/.config/CLAUDE.md | grep -q "\[Used by:"; then
    echo "✓ $section metadata preserved"
  else
    echo "✗ $section metadata MISSING"
    exit 1
  fi
done
```

**Success Criteria**:
- 4 sections reduced to exactly 6 lines each (including SECTION markers)
- 0 files modified except CLAUDE.md
- 0 broken links introduced
- All [Used by: ...] metadata preserved
- Cumulative reduction ~142 lines

**Rollback Trigger**:
- Any section size ≠ 6 lines (including markers)
- Any broken links detected
- Any metadata lost

---

### Phase 2: Standard Priority Reductions (4 sections, 27 lines saved)

**Objective**: Convert 4 remaining verbose sections to link-only format

**Complexity**: Low

**Bloat Risk**: ZERO (pure deletion, no file creation/merge)

**Tasks**:

- [ ] **Convert development_workflow** (16 lines → 4 lines):
  - Current location: CLAUDE.md lines ~177-192
  - Target: `.claude/docs/concepts/development-workflow.md` (NOT modified)
  - Action: DELETE 12 lines of inline bullets, INSERT 4-line link format
  - Link text: "See [Development Workflow](.claude/docs/concepts/development-workflow.md) for complete workflow documentation with spec updater details."
  - Savings: 12 lines (75% reduction)

- [ ] **Convert project_commands** (11 lines → 4 lines):
  - Current location: CLAUDE.md lines ~260-271
  - Target: `.claude/docs/reference/command-reference.md` (NOT modified)
  - Action: DELETE 7 lines of inline summary, INSERT 4-line link format
  - Link text: "See [Command Reference](.claude/docs/reference/command-reference.md) for complete catalog of slash commands with syntax and examples."
  - Savings: 7 lines (64% reduction)

- [ ] **Convert hierarchical_agent_architecture** (8 lines → 4 lines):
  - Current location: CLAUDE.md lines ~194-203
  - Target: `.claude/docs/concepts/hierarchical_agents.md` (NOT modified)
  - Action: DELETE 4 lines of summary, INSERT 4-line link format
  - Link text: "See [Hierarchical Agent Architecture Guide](.claude/docs/concepts/hierarchical_agents.md) for complete patterns, utilities, templates, and troubleshooting."
  - Savings: 4 lines (50% reduction)

- [ ] **Convert state_based_orchestration** (8 lines → 4 lines):
  - Current location: CLAUDE.md lines ~205-214
  - Target: `.claude/docs/architecture/state-based-orchestration-overview.md` (NOT modified)
  - Action: DELETE 4 lines of summary, INSERT 4-line link format
  - Link text: "See [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md) for complete architecture, migration guide, and performance metrics."
  - Savings: 4 lines (50% reduction)

- [ ] **CHECKPOINT 2**: Verify cumulative reduction ~169 lines after 8 sections total

**Testing**:
```bash
# Verify each section reduced to exactly 6 lines (including markers)
SECTIONS=("development_workflow" "project_commands" "hierarchical_agent_architecture" "state_based_orchestration")

for section in "${SECTIONS[@]}"; do
  SECTION_SIZE=$(sed -n "/<!-- SECTION: $section -->/,/<!-- END_SECTION: $section -->/p" /home/benjamin/.config/CLAUDE.md | wc -l)

  if [ "$SECTION_SIZE" -eq 6 ]; then
    echo "✓ $section reduced to link-only (6 lines)"
  else
    echo "✗ $section has $SECTION_SIZE lines (expected 6)"
    exit 1
  fi
done

# Verify total CLAUDE.md size reduction
BASELINE_SIZE=$(cat /home/benjamin/.config/.claude/tmp/baselines/claude-md-baseline.txt | awk '{print $1}')
CURRENT_SIZE=$(wc -l < /home/benjamin/.config/CLAUDE.md)
REDUCTION=$((BASELINE_SIZE - CURRENT_SIZE))

if [ "$REDUCTION" -ge 160 ] && [ "$REDUCTION" -le 180 ]; then
  echo "✓ Total reduction: $REDUCTION lines (target: ~169 lines)"
else
  echo "✗ WARNING: Reduction $REDUCTION lines outside expected range (160-180)"
fi

# Verify still only CLAUDE.md modified
MODIFIED_COUNT=$(git diff --name-only | grep -v "CLAUDE.md" | wc -l)
if [ "$MODIFIED_COUNT" -eq 0 ]; then
  echo "✓ Still only CLAUDE.md modified"
else
  echo "✗ WARNING: Other files modified"
fi
```

**Success Criteria**:
- 4 additional sections reduced to 6 lines each
- Cumulative reduction ~169 lines (8 sections total)
- 0 files modified except CLAUDE.md
- 0 broken links
- All metadata preserved

**Rollback Trigger**: Same as Phase 1

---

### Phase 3: Quality Enhancements (Optional - Low Priority)

**Objective**: Fix minor formatting issues and improve documentation completeness

**Complexity**: Low

**Bloat Risk**: LOW (minimal file modifications)

**Tasks**:

- [ ] **Fix relative path format** (Medium Priority):
  - File: /home/benjamin/.config/.claude/docs/concepts/directory-organization.md, line ~47
  - Issue: Uses `.claude/scripts/README.md` (absolute format in relative context)
  - Action: Change to `../../scripts/README.md`
  - Impact: Improves link portability, follows relative path convention

- [ ] **Create archive/guides/README.md** (Low Priority):
  - File: /home/benjamin/.config/.claude/docs/archive/guides/README.md
  - Content: Minimal README listing archived guide files
  - Impact: Achieves 100% README coverage (currently 91.7%)
  - Size: ~10-15 lines (no bloat risk)

**Testing**:
```bash
# Verify relative path fixed
if grep -q "../../scripts/README.md" /home/benjamin/.config/.claude/docs/concepts/directory-organization.md; then
  echo "✓ Relative path corrected"
else
  echo "✗ Relative path not fixed"
fi

# Verify archive README created
if [ -f "/home/benjamin/.config/.claude/docs/archive/guides/README.md" ]; then
  README_SIZE=$(wc -l < /home/benjamin/.config/.claude/docs/archive/guides/README.md)
  if [ "$README_SIZE" -lt 50 ]; then
    echo "✓ Archive README created ($README_SIZE lines, no bloat)"
  else
    echo "✗ WARNING: Archive README too large ($README_SIZE lines)"
  fi
else
  echo "⚠ Archive README not created (optional task)"
fi

# Verify README coverage
README_COUNT=$(find /home/benjamin/.config/.claude/docs -type d -exec test -f {}/README.md \; -print | wc -l)
TOTAL_DIRS=$(find /home/benjamin/.config/.claude/docs -type d | wc -l)
COVERAGE=$(awk "BEGIN {printf \"%.1f\", ($README_COUNT / $TOTAL_DIRS) * 100}")
echo "README coverage: $COVERAGE% ($README_COUNT/$TOTAL_DIRS directories)"
```

**Success Criteria**:
- Relative path corrected in directory-organization.md
- Archive README created (optional)
- 100% README coverage achieved (optional)
- No new bloat introduced

**Rollback Trigger**: If archive README >50 lines (bloat concern)

---

### Phase 4: Comprehensive Validation

**Objective**: Verify all changes work correctly, no broken links, metadata intact, no new bloat

**Complexity**: Low

**Tasks**:

- [ ] Verify total CLAUDE.md size reduction (~169 lines, target ~195 lines final size)
- [ ] Verify all 16 SECTION markers still present with metadata
- [ ] Verify all 13 documentation links resolve correctly (0 broken links)
- [ ] Verify no files modified except CLAUDE.md (and optional Phase 3 files)
- [ ] Verify worktree header (lines 1-27) unchanged
- [ ] **Bloat prevention checks**:
  - Verify 0 new files created in .claude/docs/ (except optional archive README)
  - Verify 0 files >400 lines created during optimization
  - Verify all modified files still within size thresholds
  - Verify no merge operations occurred (CLAUDE.md deletion-only)
- [ ] Run git diff review for unexpected changes
- [ ] Test command discovery still works (/plan, /implement, /coordinate, etc.)

**Testing**:
```bash
# Verify final CLAUDE.md size
BASELINE_SIZE=$(cat /home/benjamin/.config/.claude/tmp/baselines/claude-md-baseline.txt | awk '{print $1}')
CURRENT_SIZE=$(wc -l < /home/benjamin/.config/CLAUDE.md)
FINAL_TARGET=195
REDUCTION=$((BASELINE_SIZE - CURRENT_SIZE))

echo "=== CLAUDE.md Size Verification ==="
echo "Baseline size: $BASELINE_SIZE lines"
echo "Current size: $CURRENT_SIZE lines"
echo "Reduction: $REDUCTION lines"
echo "Target final size: ~$FINAL_TARGET lines"

if [ "$CURRENT_SIZE" -ge 190 ] && [ "$CURRENT_SIZE" -le 200 ]; then
  echo "✓ Final size within target range ($CURRENT_SIZE lines)"
else
  echo "✗ WARNING: Final size $CURRENT_SIZE outside target range (190-200)"
fi

# Verify 16 SECTION markers present
SECTION_COUNT=$(grep -c "<!-- SECTION:" /home/benjamin/.config/CLAUDE.md)
if [ "$SECTION_COUNT" -eq 16 ]; then
  echo "✓ All 16 SECTION markers present"
else
  echo "✗ CRITICAL: Found $SECTION_COUNT SECTION markers (expected 16)"
  exit 1
fi

# Verify metadata completeness
METADATA_COUNT=$(grep -c "\[Used by:" /home/benjamin/.config/CLAUDE.md)
if [ "$METADATA_COUNT" -ge 13 ]; then
  echo "✓ All metadata tags present ($METADATA_COUNT found)"
else
  echo "✗ WARNING: Only $METADATA_COUNT metadata tags found"
fi

# Verify all documentation links resolve (0 broken links)
echo "=== Link Validation ==="
BROKEN_LINKS=0
while IFS= read -r link; do
  FULL_PATH="/home/benjamin/.config/$link"
  if [ ! -f "$FULL_PATH" ]; then
    echo "✗ BROKEN LINK: $link"
    BROKEN_LINKS=$((BROKEN_LINKS + 1))
  fi
done < <(grep -o '\.claude/docs/[^)]*\.md' /home/benjamin/.config/CLAUDE.md)

if [ "$BROKEN_LINKS" -eq 0 ]; then
  echo "✓ All documentation links resolve (0 broken links)"
else
  echo "✗ CRITICAL: $BROKEN_LINKS broken links found"
  exit 1
fi

# Verify no unexpected file modifications
echo "=== File Modification Check ==="
MODIFIED_FILES=$(git diff --name-only)
EXPECTED_MODS=$(echo "$MODIFIED_FILES" | grep -E "^CLAUDE.md$|^.claude/docs/concepts/directory-organization.md$|^.claude/docs/archive/guides/README.md$" | wc -l)
TOTAL_MODS=$(echo "$MODIFIED_FILES" | wc -l)

if [ "$TOTAL_MODS" -eq "$EXPECTED_MODS" ] || [ "$TOTAL_MODS" -le 3 ]; then
  echo "✓ Only expected files modified ($TOTAL_MODS files)"
  echo "$MODIFIED_FILES"
else
  echo "✗ WARNING: Unexpected file modifications"
  echo "$MODIFIED_FILES"
fi

# Bloat prevention verification
echo "=== Bloat Prevention Checks ==="

# Check for new bloated files (>400 lines)
NEW_BLOAT=0
for file in /home/benjamin/.config/.claude/docs/**/*.md; do
  if [ -f "$file" ]; then
    SIZE=$(wc -l < "$file" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 400 ] && echo "$MODIFIED_FILES" | grep -q "$(basename $file)"; then
      echo "⚠ BLOAT WARNING: $file is $SIZE lines (>400 threshold)"
      NEW_BLOAT=$((NEW_BLOAT + 1))
    fi
  fi
done

if [ "$NEW_BLOAT" -eq 0 ]; then
  echo "✓ No new bloat introduced (0 modified files >400 lines)"
else
  echo "✗ WARNING: $NEW_BLOAT files exceed bloat threshold"
fi

# Verify worktree header unchanged
HEADER_HASH_BEFORE=$(head -n 27 /home/benjamin/.config/.claude/tmp/backups/CLAUDE.md.20251116-* 2>/dev/null | head -n 1 | md5sum | cut -d' ' -f1)
HEADER_HASH_AFTER=$(head -n 27 /home/benjamin/.config/CLAUDE.md | md5sum | cut -d' ' -f1)

if [ "$HEADER_HASH_BEFORE" = "$HEADER_HASH_AFTER" ]; then
  echo "✓ Worktree header unchanged"
else
  echo "⚠ WARNING: Worktree header may have changed"
fi

# Test command discovery
echo "=== Command Discovery Test ==="
if command -v claude &>/dev/null; then
  claude /help | grep -q "/plan" && echo "✓ /plan command discovered" || echo "✗ /plan not found"
  claude /help | grep -q "/implement" && echo "✓ /implement command discovered" || echo "✗ /implement not found"
else
  echo "⚠ Claude CLI not available for command discovery test"
fi

echo ""
echo "=== Validation Summary ==="
echo "Final size: $CURRENT_SIZE lines (target: ~195)"
echo "Reduction: $REDUCTION lines (target: ~169)"
echo "Broken links: $BROKEN_LINKS (target: 0)"
echo "New bloat: $NEW_BLOAT files (target: 0)"
echo "Modified files: $TOTAL_MODS (expected: 1-3)"
```

**Success Criteria**:
- [ ] CLAUDE.md size: 190-200 lines (target ~195)
- [ ] Reduction: 160-180 lines (target ~169)
- [ ] Broken links: 0
- [ ] SECTION markers: 16 present
- [ ] Metadata tags: 13+ present
- [ ] New bloat: 0 files >400 lines
- [ ] Modified files: ≤3 (CLAUDE.md + optional Phase 3 files)
- [ ] Command discovery: working

**Rollback Trigger**:
- Any broken links found
- Final size outside 190-200 range
- Any SECTION markers lost
- Any metadata lost
- Any new bloat introduced

---

### Phase 5: Git Commit and Completion

**Objective**: Commit changes with descriptive message and verify success

**Complexity**: Low

**Tasks**:

- [ ] Review git diff one final time
- [ ] Verify all validation checks passed
- [ ] Commit changes with atomic message
- [ ] Verify commit successful
- [ ] Document completion metrics

**Testing**:
```bash
# Final git diff review
echo "=== Final Git Diff Review ==="
git diff --stat

# Atomic commit (only if all validations passed)
if [ "$BROKEN_LINKS" -eq 0 ] && [ "$CURRENT_SIZE" -le 200 ]; then
  git add CLAUDE.md

  # Add optional Phase 3 files if modified
  git add .claude/docs/concepts/directory-organization.md 2>/dev/null || true
  git add .claude/docs/archive/guides/README.md 2>/dev/null || true

  git commit -m "docs(723): optimize CLAUDE.md structure and fix critical accuracy errors

- Fix broken link to fail-fast policy analysis report (critical error)
- Convert 8 verbose sections to link-only format (169 lines saved, 46% reduction)
- Fix relative path format in directory-organization.md
- Add archive/guides/README.md for 100% README coverage

Final size: $CURRENT_SIZE lines (was $BASELINE_SIZE)
Broken links: 0 (was 1)
Link-only sections: 13/13 (was 4/13)
README coverage: 100% (was 91.7%)

Zero new bloat introduced (deletion-only optimization).

Related: spec 723"

  echo "✓ Changes committed successfully"
else
  echo "✗ VALIDATION FAILED - NOT committing changes"
  echo "  Broken links: $BROKEN_LINKS (must be 0)"
  echo "  Final size: $CURRENT_SIZE (must be ≤200)"
  exit 1
fi

# Verify commit
git log -1 --oneline | grep "docs(723)" && echo "✓ Commit verified" || echo "✗ Commit not found"

# Document completion metrics
echo ""
echo "=== OPTIMIZATION COMPLETE ==="
echo "Baseline size: $BASELINE_SIZE lines"
echo "Final size: $CURRENT_SIZE lines"
echo "Reduction: $REDUCTION lines ($(awk "BEGIN {printf \"%.1f\", ($REDUCTION / $BASELINE_SIZE) * 100}")%)"
echo "Broken links fixed: 1 → 0"
echo "Link-only sections: 4/13 → 13/13"
echo "Files modified: $(git diff HEAD~1 --name-only | wc -l)"
echo "New bloat: 0 files >400 lines"
```

**Success Criteria**:
- [ ] Git commit successful
- [ ] Commit message follows project standards
- [ ] All files staged and committed
- [ ] Completion metrics documented
- [ ] No validation failures

**Rollback Trigger**: If commit fails (validation errors)

---

## Success Criteria

**CRITICAL PRIORITY (Must achieve 100%)**:
- [ ] 1 critical broken link fixed (fail-fast policy analysis reference removed)
- [ ] CLAUDE.md reduced from 364 to ~195 lines (46% reduction)
- [ ] All 8 verbose sections converted to link-only format (4-line pattern)
- [ ] 0 broken links in CLAUDE.md (was 1)
- [ ] 0 new files created in .claude/docs/ (except optional archive README)
- [ ] 0 files modified except CLAUDE.md (and optional Phase 3 files)
- [ ] 0 files >400 lines created during optimization (bloat prevention)
- [ ] All 16 SECTION markers preserved
- [ ] All [Used by: ...] metadata preserved

**HIGH PRIORITY (Quality improvements)**:
- [ ] Relative path format corrected in directory-organization.md
- [ ] Archive README created for 100% coverage (optional)
- [ ] All documentation links validate successfully
- [ ] Command discovery still works (/plan, /implement, etc.)

**VERIFICATION REQUIREMENTS**:
- [ ] All 55 validation tasks passed (from bloat report Section 3)
- [ ] Backup created and tested
- [ ] Git diff reviewed for unexpected changes
- [ ] No test failures or regressions

## Rollback Procedure

**WHEN TO ROLLBACK**:
- Any validation task fails
- Broken links detected during any phase
- Final size outside 190-200 line range
- Any SECTION metadata lost
- Any new bloat introduced (files >400 lines)
- Command discovery stops working

**ROLLBACK STEPS**:

```bash
# STEP 1: Identify backup file
BACKUP_DIR="/home/benjamin/.config/.claude/tmp/backups"
BACKUP_FILE=$(ls -t "$BACKUP_DIR"/CLAUDE.md.20251116-* 2>/dev/null | head -n 1)

if [ -z "$BACKUP_FILE" ]; then
  echo "CRITICAL ERROR: No backup found in $BACKUP_DIR"
  exit 1
fi

echo "Using backup: $BACKUP_FILE"

# STEP 2: Restore CLAUDE.md
cp "$BACKUP_FILE" /home/benjamin/.config/CLAUDE.md

# STEP 3: Verify restoration
RESTORED_SIZE=$(wc -l < /home/benjamin/.config/CLAUDE.md)
BASELINE_SIZE=$(cat /home/benjamin/.config/.claude/tmp/baselines/claude-md-baseline.txt | awk '{print $1}')

if [ "$RESTORED_SIZE" -eq "$BASELINE_SIZE" ]; then
  echo "✓ CLAUDE.md restored successfully ($RESTORED_SIZE lines)"
else
  echo "⚠ WARNING: Restored size ($RESTORED_SIZE) differs from baseline ($BASELINE_SIZE)"
fi

# STEP 4: Discard any incomplete Phase 3 changes
git checkout HEAD -- .claude/docs/concepts/directory-organization.md 2>/dev/null || true
git checkout HEAD -- .claude/docs/archive/guides/README.md 2>/dev/null || true

# STEP 5: Verify no staged changes
git diff --cached --exit-code && echo "✓ No staged changes" || echo "⚠ Staged changes remain"

# STEP 6: Clean working directory
git status --short

echo ""
echo "=== ROLLBACK COMPLETE ==="
echo "CLAUDE.md restored from: $BACKUP_FILE"
echo "Current size: $RESTORED_SIZE lines"
echo "Baseline size: $BASELINE_SIZE lines"
echo "Next steps: Review failure logs and retry optimization"
```

**POST-ROLLBACK VERIFICATION**:
- Verify CLAUDE.md matches baseline size
- Run validation to confirm restoration
- Document failure reason for retry
- Review which phase/task triggered rollback

**ESCALATION**:
If rollback fails or backup missing, escalate to user immediately with diagnostics.
