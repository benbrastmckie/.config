# CLAUDE.md Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: CLAUDE.md context optimization and bloat prevention
- **Agent**: cleanup-plan-architect
- **Research Reports**:
  - CLAUDE.md Analysis: `/home/benjamin/.config/.claude/specs/711_optimize_claudemd_structure/reports/001_claude_md_analysis.md`
  - Docs Structure Analysis: `/home/benjamin/.config/.claude/specs/711_optimize_claudemd_structure/reports/002_docs_structure_analysis.md`
  - Bloat Analysis: `/home/benjamin/.config/.claude/specs/711_optimize_claudemd_structure/reports/003_bloat_analysis.md`
- **Scope**: Extract 4 bloated sections from CLAUDE.md, prevent documentation bloat through size validation, exclude .claude/docs/ cleanup (deferred)
- **Estimated Phases**: 8 phases
- **Complexity**: Medium-High
- **Standards File**: `/home/benjamin/.config/CLAUDE.md`

## Overview

This plan optimizes CLAUDE.md by extracting 4 bloated sections (total 437 lines) to appropriate locations in .claude/docs/. The optimization reduces CLAUDE.md from 964 lines to ~527 lines (a 45.3% reduction) while maintaining all functionality through summary links and implementing comprehensive bloat prevention measures.

**Extraction Strategy**:
- 2 sections CREATE new files in .claude/docs/ (code-standards.md, directory-organization.md)
- 1 section MERGES with existing file (hierarchical_agents.md) with bloat validation
- 1 section UPDATES with link-only strategy (state-based-orchestration-overview.md - NO merge due to existing 2,000+ line file)

**Target Documentation Locations**:
- .claude/docs/reference/: code-standards.md (84 lines extraction)
- .claude/docs/concepts/: directory-organization.md (231 lines extraction)
- .claude/docs/concepts/: hierarchical_agents.md (93 lines merge with pre-validation)
- .claude/docs/architecture/: state-based-orchestration-overview.md (link-only, no merge)

**Bloat Prevention Strategy**:
- Pre-extraction size checks for all target files
- Post-extraction size validation (<400 line threshold)
- Conditional merge logic with rollback triggers
- Final comprehensive bloat audit
- Automated rollback procedures if thresholds exceeded

**Out of Scope** (Deferred to Future Sprints):
- command-development-guide.md 4-way split (3,980 lines CRITICAL)
- state-based-orchestration-overview.md 6-way split (2,000+ lines CRITICAL)
- Command guide 2-way splits (567, 512, 487 lines)
- Note: These are documented in bloat analysis report but excluded from this optimization plan to maintain focus on CLAUDE.md extraction

## Implementation Phases

### Phase 1: Backup and Baseline Preparation

**Objective**: Protect against failures with backup, directory setup, and baseline metrics

**Complexity**: Low

**Bloat Risk**: N/A (infrastructure phase)

**Tasks**:
- [ ] Create baseline size inventory for bloat tracking
- [ ] Create backup: .claude/backups/CLAUDE.md.[YYYYMMDD]-[HHMMSS]
- [ ] Verify .claude/docs/reference/ exists (create if needed)
- [ ] Verify .claude/docs/concepts/ exists (create if needed)
- [ ] Verify target files don't exist (code-standards.md, directory-organization.md)
- [ ] Record baseline sizes of merge target files (hierarchical_agents.md, state-based-orchestration-overview.md)

**Testing**:
```bash
# Record baseline sizes
echo "=== BASELINE SIZES ===" > /tmp/bloat_baseline.txt
wc -l /home/benjamin/.config/CLAUDE.md >> /tmp/bloat_baseline.txt
wc -l /home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md >> /tmp/bloat_baseline.txt 2>&1 || echo "hierarchical_agents.md: not found"
wc -l /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md >> /tmp/bloat_baseline.txt 2>&1 || echo "state-based-orchestration-overview.md: not found"

cat /tmp/bloat_baseline.txt

# Verify backup created
BACKUP_FILE="/home/benjamin/.config/.claude/backups/CLAUDE.md.$(date +%Y%m%d-%H%M%S)"
test -f "$BACKUP_FILE" && echo "✓ Backup exists" || echo "✗ Backup missing"

# Verify directories exist
for dir in concepts reference; do
  test -d "/home/benjamin/.config/.claude/docs/$dir" && echo "✓ $dir/ exists" || echo "✗ $dir/ missing"
done

# Verify target files don't exist (for new file creations)
test ! -f /home/benjamin/.config/.claude/docs/reference/code-standards.md || \
  { echo "ERROR: code-standards.md already exists!"; exit 1; }
test ! -f /home/benjamin/.config/.claude/docs/concepts/directory-organization.md || \
  { echo "ERROR: directory-organization.md already exists!"; exit 1; }

echo "✓ Verified: Target files don't exist (safe to create)"
```

### Phase 2: Extract "Code Standards" Section

**Objective**: Move 84-line section to reference/ documentation

**Complexity**: Low

**Bloat Risk**: LOW (new file, well below threshold)

**Tasks**:
- [ ] Extract lines from Code Standards section in CLAUDE.md (section: code_standards)
- [ ] CREATE `/home/benjamin/.config/.claude/docs/reference/code-standards.md` with full content
- [ ] Add frontmatter and navigation to new file
- [ ] **Post-creation size check**: Verify file ≤400 lines
- [ ] Replace CLAUDE.md lines with summary:
  ```markdown
  ## Code Standards
  [Used by: /implement, /refactor, /plan]

  See [Code Standards](.claude/docs/reference/code-standards.md) for complete development standards.

  **Summary**: Project follows 2-space indentation, snake_case for variables/functions, PascalCase for modules, 100-char line length, UTF-8 encoding (no emojis), and language-specific standards for Lua, Markdown, and Shell. All commands/agents follow executable/documentation separation pattern with imperative language (MUST/WILL/SHALL). See full standards for internal link conventions and architectural requirements.
  ```
- [ ] Validate link resolves: `.claude/docs/reference/code-standards.md`
- [ ] Check cross-references in `.claude/commands/` still work

**Testing**:
```bash
# Verify file created
test -f /home/benjamin/.config/.claude/docs/reference/code-standards.md

# Verify size within threshold (400 lines)
FILE_SIZE=$(wc -l < /home/benjamin/.config/.claude/docs/reference/code-standards.md)
echo "code-standards.md: $FILE_SIZE lines"

if (( FILE_SIZE > 400 )); then
  echo "BLOAT ALERT: code-standards.md exceeds 400 lines ($FILE_SIZE)"
  exit 1
elif (( FILE_SIZE > 100 )); then
  echo "WARNING: code-standards.md larger than expected ($FILE_SIZE lines, expected ~84)"
fi

echo "✓ PASSED: code-standards.md within threshold"

# Verify link in CLAUDE.md
grep -q "code-standards.md" /home/benjamin/.config/CLAUDE.md

# Verify summary exists
grep -q "^## Code Standards" /home/benjamin/.config/CLAUDE.md
grep -q "**Summary**:" /home/benjamin/.config/CLAUDE.md
```

**Rollback** (if bloat threshold exceeded):
```bash
# Restore previous version
git checkout HEAD -- /home/benjamin/.config/CLAUDE.md
rm -f /home/benjamin/.config/.claude/docs/reference/code-standards.md

echo "ROLLBACK COMPLETE: code-standards extraction reverted"
```

### Phase 3: Extract "Directory Organization Standards" Section

**Objective**: Move 231-line section to concepts/ documentation

**Complexity**: Medium (largest extraction, complex content)

**Bloat Risk**: LOW (new file, well below threshold at 231 lines)

**Tasks**:
- [ ] Extract lines from Directory Organization Standards section in CLAUDE.md (section: directory_organization)
- [ ] CREATE `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` with full content
- [ ] **Post-creation size check**: Verify file ≤400 lines
- [ ] Add frontmatter and navigation to new file
- [ ] Replace CLAUDE.md lines with summary:
  ```markdown
  ## Directory Organization Standards
  [Used by: /implement, /plan, /refactor, all development commands]

  See [Directory Organization](.claude/docs/concepts/directory-organization.md) for complete file placement guidelines.

  **Summary**: Files organized by purpose: scripts/ (standalone CLI tools), lib/ (sourced functions), commands/ (slash commands), agents/ (AI assistants), docs/ (guides/concepts/reference), utils/ (specialized helpers). Use decision matrix to determine correct location. All directories require README.md. Follow kebab-case naming for bash scripts.
  ```
- [ ] Validate link resolves: `.claude/docs/concepts/directory-organization.md`
- [ ] Check cross-references in `.claude/commands/` still work

**Testing**:
```bash
# Verify file created
test -f /home/benjamin/.config/.claude/docs/concepts/directory-organization.md

# Verify size within threshold (400 lines)
FILE_SIZE=$(wc -l < /home/benjamin/.config/.claude/docs/concepts/directory-organization.md)
echo "directory-organization.md: $FILE_SIZE lines"

if (( FILE_SIZE > 400 )); then
  echo "BLOAT ALERT: directory-organization.md exceeds 400 lines ($FILE_SIZE)"
  exit 1
elif (( FILE_SIZE > 250 )); then
  echo "WARNING: directory-organization.md larger than expected ($FILE_SIZE lines, expected ~231)"
fi

echo "✓ PASSED: directory-organization.md within threshold"

# Verify link in CLAUDE.md
grep -q "directory-organization.md" /home/benjamin/.config/CLAUDE.md

# Verify summary exists
grep -q "^## Directory Organization Standards" /home/benjamin/.config/CLAUDE.md
grep -q "**Summary**:" /home/benjamin/.config/CLAUDE.md
```

**Rollback** (if bloat threshold exceeded):
```bash
# Restore previous version
git checkout HEAD -- /home/benjamin/.config/CLAUDE.md
rm -f /home/benjamin/.config/.claude/docs/concepts/directory-organization.md

echo "ROLLBACK COMPLETE: directory-organization extraction reverted"
```

### Phase 4: Conditional Merge "Hierarchical Agent Architecture" Section

**Objective**: Merge 93-line section to existing concepts/hierarchical_agents.md with bloat validation

**Complexity**: Medium (conditional merge with size validation)

**Bloat Risk**: MEDIUM (merge into existing file - requires pre-validation)

**Tasks**:
- [ ] **Size validation** (BEFORE merge):
  - Check current size of target file: `.claude/docs/concepts/hierarchical_agents.md`
  - Calculate extraction size: 93 lines
  - Project post-merge size: current + 93 = projected lines
  - **DECISION POINT**: If projected size >400 lines, SKIP merge and use cross-reference only
- [ ] **Branch A** (if projected <400 lines): Extract unique content from CLAUDE.md Hierarchical Agent Architecture section
- [ ] **Branch A**: MERGE unique content into `.claude/docs/concepts/hierarchical_agents.md`
- [ ] **Branch A**: Replace CLAUDE.md section with 5-10 line summary + link
- [ ] **Branch B** (if projected ≥400 lines): Keep CLAUDE.md section as-is
- [ ] **Branch B**: Add cross-reference at end of section: "See also: [Hierarchical Agent Architecture](.claude/docs/concepts/hierarchical_agents.md)"
- [ ] **Post-merge size check** (Branch A only):
  - Verify actual file size ≤400 lines
  - If >400 lines, trigger rollback and switch to Branch B
- [ ] Validate link resolves: `.claude/docs/concepts/hierarchical_agents.md`
- [ ] Check cross-references in `.claude/commands/` still work

**Testing**:
```bash
# STEP 1: Pre-merge size check
lines_before=$(wc -l < /home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md)
echo "hierarchical_agents.md (before merge): $lines_before lines"

# Calculate projected size
claude_content=93  # From CLAUDE.md
projected=$((lines_before + claude_content))
echo "Projected size after merge: $projected lines"

if (( projected > 400 )); then
  echo "DECISION: Skip merge (projected $projected lines exceeds threshold)"
  echo "ACTION: Add cross-reference only to CLAUDE.md"
  # Branch B execution
else
  echo "DECISION: Proceed with merge (projected $projected lines safe)"
  # Branch A execution

  # STEP 2: Post-merge size validation
  lines_after=$(wc -l < /home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md)
  echo "hierarchical_agents.md (after merge): $lines_after lines"

  if (( lines_after > 400 )); then
    echo "BLOAT ALERT: Merge created bloated file ($lines_after lines)"
    echo "Triggering rollback..."
    exit 1
  fi

  echo "✓ SAFE: Merge completed at $lines_after lines (below 400 threshold)"
fi

# Verify link in CLAUDE.md
grep -q "hierarchical_agents.md" /home/benjamin/.config/CLAUDE.md
```

**Rollback** (if bloat threshold exceeded):
```bash
# Restore previous version
git checkout HEAD -- /home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md
git checkout HEAD -- /home/benjamin/.config/CLAUDE.md

echo "ROLLBACK COMPLETE: Switching to Branch B (cross-reference only)"
# Manually add cross-reference to CLAUDE.md section
```

### Phase 5: Link-Only "State-Based Orchestration Architecture" Section

**Objective**: Replace 108-line section with summary + link (NO merge to avoid bloating existing 2,000+ line file)

**Complexity**: Low (link replacement only, no content extraction)

**Bloat Risk**: ZERO (using link-only strategy, no merge)

**Tasks**:
- [ ] Read CLAUDE.md State-Based Orchestration Architecture section
- [ ] Craft 5-10 line summary covering:
  - What: State machines with validated transitions for multi-phase workflows
  - Why: Explicit states, validated transitions, checkpoint management
  - When: 3+ phases, conditional transitions, checkpoint resume needed
- [ ] Replace entire CLAUDE.md section (108 lines) with summary + link to `.claude/docs/architecture/state-based-orchestration-overview.md`
- [ ] **VERIFY**: Target file size UNCHANGED (no merge occurred)
- [ ] Validate link resolves: `.claude/docs/architecture/state-based-orchestration-overview.md`
- [ ] Check cross-references in `.claude/commands/` still work

**Testing**:
```bash
# Record size before replacement
lines_before=$(wc -l < /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md)
echo "state-based-orchestration-overview.md (before): $lines_before lines"

# After CLAUDE.md section is replaced with link, verify file unchanged
lines_after=$(wc -l < /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md)
echo "state-based-orchestration-overview.md (after): $lines_after lines"

if (( lines_after != lines_before )); then
  echo "ERROR: File size changed! Link-only strategy violated."
  echo "Expected: $lines_before, Actual: $lines_after"
  exit 1
fi

echo "✓ VERIFIED: Link-only strategy maintained (no merge occurred)"

# Verify link in CLAUDE.md
grep -q "state-based-orchestration-overview.md" /home/benjamin/.config/CLAUDE.md

# Verify summary exists
grep -q "^## State-Based Orchestration Architecture" /home/benjamin/.config/CLAUDE.md
grep -q "**Summary**:" /home/benjamin/.config/CLAUDE.md || grep -q "See \[" /home/benjamin/.config/CLAUDE.md
```

**Rollback** (if file modified accidentally):
```bash
# Restore both files
git checkout HEAD -- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md
git checkout HEAD -- /home/benjamin/.config/CLAUDE.md

echo "ROLLBACK COMPLETE: state-based-orchestration link replacement reverted"
```

### Phase 6: Cross-Reference and Link Validation

**Objective**: Ensure all changes work correctly and no broken links

**Complexity**: Low

**Bloat Risk**: N/A (validation phase)

**Tasks**:
- [ ] Run `.claude/scripts/validate-links-quick.sh` (all links resolve)
- [ ] Verify all `[Used by: ...]` metadata tags intact in CLAUDE.md
- [ ] Update `.claude/docs/README.md` with links to newly created files
- [ ] Grep for broken section references in `.claude/commands/`
- [ ] Verify command discovery still works (commands can find standards)
- [ ] Check that new files have proper frontmatter and navigation
- [ ] If any validation fails: ROLLBACK using backup

**Testing**:
```bash
# Link validation
/home/benjamin/.config/.claude/scripts/validate-links-quick.sh || {
  echo "BROKEN LINKS DETECTED: Fix before continuing"
  exit 1
}

# Metadata preservation check
for section in code_standards directory_organization hierarchical_agent_architecture state_based_orchestration; do
  grep -q "\[Used by:.*\]" /home/benjamin/.config/CLAUDE.md || {
    echo "WARNING: Metadata missing for section: $section"
  }
done

# Command reference check
grep -r "code_standards\|directory_organization" /home/benjamin/.config/.claude/commands/ | grep -v ".md:.*http" || echo "No command references found (may be OK)"

echo "✓ PASSED: All validations successful"
```

### Phase 7: CLAUDE.md Size Reduction Verification

**Objective**: Confirm CLAUDE.md achieved target reduction without introducing new bloat

**Complexity**: Low

**Bloat Risk**: N/A (verification phase)

**Tasks**:
- [ ] Check CLAUDE.md size reduced to target (~527 lines, ±50 tolerance)
- [ ] **Bloat prevention checks**:
  - Verify no extracted files exceed 400 lines
  - Check that new files stayed within projected sizes
  - Validate no bloat introduced by merge operations
  - Verify state-based-orchestration file unchanged
- [ ] Run comprehensive bloat audit on all modified files
- [ ] Generate bloat metrics report comparing before/after
- [ ] Document any files approaching threshold (350-400 lines)
- [ ] If CLAUDE.md reduction insufficient or new bloat detected: ROLLBACK

**Testing**:
```bash
# CLAUDE.md reduction verification
lines_after=$(wc -l < /home/benjamin/.config/CLAUDE.md)
target=527
tolerance=50  # Allow ±50 lines

echo "CLAUDE.md after extractions: $lines_after lines"
echo "Target: $target lines"

if (( lines_after > target + tolerance )); then
  echo "WARNING: CLAUDE.md larger than target ($lines_after > $((target + tolerance)))"
  echo "Review extractions for missed content"
elif (( lines_after < target - tolerance )); then
  echo "WARNING: CLAUDE.md smaller than target ($lines_after < $((target - tolerance)))"
  echo "Review summaries - may be too brief"
else
  echo "✓ PASSED: CLAUDE.md within target range"
fi

# No new bloated files created
echo "=== NEW FILE SIZE AUDIT ==="

for file in /home/benjamin/.config/.claude/docs/reference/code-standards.md \
            /home/benjamin/.config/.claude/docs/concepts/directory-organization.md; do
  if [[ -f "$file" ]]; then
    lines=$(wc -l < "$file")
    echo "$file: $lines lines"

    if (( lines > 400 )); then
      echo "BLOAT ALERT: $file exceeds threshold!"
      exit 1
    fi
  fi
done

echo "✓ PASSED: All new files below 400-line threshold"
```

### Phase 8: Final Verification and Bloat Audit

**Objective**: Comprehensive system validation and bloat documentation

**Complexity**: Low

**Bloat Risk**: N/A (final audit phase)

**Tasks**:
- [ ] Run `/setup --validate` (check CLAUDE.md structure)
- [ ] Run comprehensive bloat audit across all `.claude/docs/` files
- [ ] Generate final bloat metrics report
- [ ] Document bloated files requiring future splits (command-development-guide.md, state-based-orchestration-overview.md)
- [ ] Verify test commands still work (`/plan`, `/implement`, etc.)
- [ ] Create git commit with all changes
- [ ] Archive backup file after successful commit

**Testing**:
```bash
# Comprehensive validation
cd /home/benjamin/.config
/setup --validate || {
  echo "CLAUDE.md validation failed"
  exit 1
}

# Full bloat audit
echo "=== FINAL BLOAT AUDIT ==="
echo "Files exceeding 400-line threshold:"

find /home/benjamin/.config/.claude/docs -name "*.md" -type f ! -path "*/archive/*" | while read -r file; do
  lines=$(wc -l < "$file")
  if (( lines > 400 )); then
    bloat_factor=$(( (lines - 400) * 100 / 400 ))
    printf "%5d lines (+%3d%%) %s\n" "$lines" "$bloat_factor" "$file"
  fi
done

echo ""
echo "Files exceeding CRITICAL threshold (800 lines):"
find /home/benjamin/.config/.claude/docs -name "*.md" -type f ! -path "*/archive/*" | while read -r file; do
  lines=$(wc -l < "$file")
  if (( lines > 800 )); then
    printf "%5d lines (CRITICAL) %s\n" "$lines" "$file"
  fi
done

# Generate bloat metrics report
cat > /tmp/bloat_metrics.md <<EOF
# Bloat Metrics Report

## Before Optimization
- CLAUDE.md: 964 lines
- Bloated files (>400): 8 files identified in bloat analysis
- Critical files (>800): 2 files (command-development-guide.md, state-based-orchestration-overview.md)

## After Optimization
- CLAUDE.md: $(wc -l < /home/benjamin/.config/CLAUDE.md) lines
- New files created: 2 (code-standards.md, directory-organization.md)
- Files merged: 1 conditional (hierarchical_agents.md)
- Link-only updates: 1 (state-based-orchestration-overview.md)

## Reduction Achieved
- CLAUDE.md reduction: $((964 - $(wc -l < /home/benjamin/.config/CLAUDE.md))) lines ($(( (964 - $(wc -l < /home/benjamin/.config/CLAUDE.md)) * 100 / 964 ))%)
- Target met: $(if (( $(wc -l < /home/benjamin/.config/CLAUDE.md) <= 577 && $(wc -l < /home/benjamin/.config/CLAUDE.md) >= 477 )); then echo "YES"; else echo "NO"; fi)

## Future Work (Out of Scope - Deferred)
- command-development-guide.md: 3,980 lines (requires 4-way split)
- state-based-orchestration-overview.md: 2,000+ lines (requires 6-way split)
- Command guides: 3 files 400-600 lines (2-way splits recommended)
EOF

cat /tmp/bloat_metrics.md

# Test commands still work
echo "Testing command discovery..."
grep -q "code_standards" /home/benjamin/.config/CLAUDE.md && echo "✓ code_standards section found"
grep -q "directory_organization" /home/benjamin/.config/CLAUDE.md && echo "✓ directory_organization section found"

echo "✓ PASSED: Final verification complete"
```

## Success Criteria

- [ ] CLAUDE.md reduced from 964 to 477-577 lines (target 527 ± 50, achieving 45.3% reduction)
- [ ] All 4 bloated sections extracted successfully:
  - [ ] Code Standards → reference/code-standards.md (84 lines)
  - [ ] Directory Organization → concepts/directory-organization.md (231 lines)
  - [ ] Hierarchical Agent Architecture → merged or cross-referenced (93 lines)
  - [ ] State-Based Orchestration → link-only replacement (108 lines)
- [ ] **Bloat prevention**: No extracted files exceed 400 lines (bloat threshold)
- [ ] **Bloat prevention**: All size validation tasks completed successfully (7 validation checkpoints)
- [ ] **Bloat prevention**: No new bloat introduced by merge operations
- [ ] **Bloat prevention**: Conditional merge logic executed correctly for hierarchical_agents.md
- [ ] **Bloat prevention**: Link-only strategy verified for state-based-orchestration-overview.md
- [ ] All internal links validate successfully (`.claude/scripts/validate-links-quick.sh` passes)
- [ ] All command metadata references intact (`[Used by: ...]` tags preserved)
- [ ] `/setup --validate` passes
- [ ] Backup created and restoration procedure documented
- [ ] Bloat metrics report generated documenting reduction achieved
- [ ] No test failures or regressions in command discovery

## Rollback Procedure

If any phase fails or validation errors occur:

```bash
# Restore from backup
BACKUP_FILE="/home/benjamin/.config/.claude/backups/CLAUDE.md.$(date +%Y%m%d-%H%M%S)"
# Note: Replace timestamp with actual backup file from Phase 1
cp "$BACKUP_FILE" /home/benjamin/.config/CLAUDE.md

# Verify restoration
wc -l /home/benjamin/.config/CLAUDE.md  # Should be 964 lines
cd /home/benjamin/.config && /setup --validate  # Should pass

# Remove incomplete extracted files (if created)
rm -f /home/benjamin/.config/.claude/docs/reference/code-standards.md
rm -f /home/benjamin/.config/.claude/docs/concepts/directory-organization.md

# Restore merged files (if modified)
git checkout HEAD -- /home/benjamin/.config/.claude/docs/concepts/hierarchical_agents.md

# Verify state-based-orchestration file unchanged (should always pass)
git diff /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md  # Should show no diff

echo "ROLLBACK COMPLETE"
```

**When to Rollback**:
- Any file creation exceeds 400-line threshold
- Hierarchical agents merge creates bloated file (>400 lines)
- State-based orchestration file modified (link-only strategy violated)
- Link validation fails in Phase 6
- CLAUDE.md reduction insufficient or excessive (outside 477-577 range)
- Command discovery stops working
- Tests fail after extraction

## Notes

**Bloat Prevention Strategy**: This plan implements comprehensive size validation at 7 checkpoints across all phases to prevent documentation bloat. Conditional logic ensures merge operations only proceed when safe, with automatic rollback if thresholds exceeded.

**Out of Scope - Deferred Work**: Analysis identified 2 critical bloated files in `.claude/docs/` requiring splits (command-development-guide.md at 3,980 lines, state-based-orchestration-overview.md at 2,000+ lines). These are documented in bloat analysis report but excluded from this plan to maintain focus on CLAUDE.md optimization. Recommend separate implementation plans for documentation cleanup.

**Risk Mitigation**: Phases 4-5 use conditional execution (Branch A/B logic) to handle merge scenarios safely. All phases include rollback procedures with specific commands. Comprehensive validation in Phases 6-8 ensures no breakage before final commit.
