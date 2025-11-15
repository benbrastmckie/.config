# CLAUDE.md Optimization Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: CLAUDE.md context optimization
- **Agent**: cleanup-plan-architect
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/706_optimize_claudemd_structure/reports/001_claude_md_analysis.md
  - /home/benjamin/.config/.claude/specs/706_optimize_claudemd_structure/reports/002_docs_structure_analysis.md
- **Scope**: Extract bloated sections to .claude/docs/, update summaries, verify links
- **Estimated Phases**: 6 (Backup → 4 Extractions → Verification)
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Overview

This plan optimizes CLAUDE.md by extracting 4 bloated sections (total 516 lines) to appropriate locations in .claude/docs/. The optimization reduces CLAUDE.md from 964 lines to approximately 527 lines (a 45.3% reduction) while maintaining all functionality through summary links.

**Extraction Strategy**:
- 4 sections CREATE new files in .claude/docs/
- 0 sections MERGE with existing files
- 4 sections UPDATE with summary + link pattern

**Target Documentation Locations**:
- .claude/docs/reference/: code-standards.md (83 lines extracted)
- .claude/docs/concepts/: directory-organization.md (231 lines extracted)
- .claude/docs/concepts/: hierarchical-agents.md (93 lines extracted)
- .claude/docs/architecture/: state-based-orchestration summary reduction (108 lines → 15 lines)

**Total Line Reduction**: ~437 lines (45.3% reduction)

## Implementation Phases

### Phase 1: Backup and Preparation

**Objective**: Protect against failures with backup and directory setup

**Complexity**: Low

**Tasks**:
- [ ] Create backup: .claude/backups/CLAUDE.md.[YYYYMMDD]-[HHMMSS]
- [ ] Verify .claude/docs/reference/ exists (create if needed)
- [ ] Verify .claude/docs/concepts/ exists (create if needed)
- [ ] Verify .claude/docs/architecture/ exists (create if needed)
- [ ] Create stub files for new documents (prevents broken links during extraction)

**Testing**:
```bash
# Verify backup created
BACKUP_FILE=$(ls -t .claude/backups/CLAUDE.md.* 2>/dev/null | head -1)
test -f "$BACKUP_FILE" && echo "✓ Backup exists: $BACKUP_FILE" || echo "✗ Backup missing"

# Verify directories exist
for dir in concepts reference architecture; do
  test -d ".claude/docs/$dir" && echo "✓ $dir/ exists" || echo "✗ $dir/ missing"
done
```

### Phase 2: Extract "Code Standards" Section

**Objective**: Move 84-line section to reference documentation

**Complexity**: Low

**Tasks**:
- [ ] Extract lines 100-183 from CLAUDE.md (code_standards section)
- [ ] CREATE .claude/docs/reference/code-standards.md with full content
- [ ] Add frontmatter (metadata, date, purpose) to code-standards.md
- [ ] Add navigation links to parent README and related guides
- [ ] Replace CLAUDE.md lines 100-183 with summary:
  ```markdown
  ## Code Standards
  [Used by: /implement, /refactor, /plan]

  See [Code Standards](.claude/docs/reference/code-standards.md) for complete guidelines.

  **Summary**: General principles (2-space indentation, 100-char lines, snake_case), language-specific standards (Lua, Markdown, Shell), command architecture standards, and development guides.
  ```
- [ ] Validate link resolves: .claude/docs/reference/code-standards.md
- [ ] Check cross-references in .claude/commands/ still work

**Testing**:
```bash
# Verify file created
test -f .claude/docs/reference/code-standards.md && echo "✓ File created" || echo "✗ File missing"

# Verify link in CLAUDE.md
grep -q "code-standards.md" CLAUDE.md && echo "✓ Link exists" || echo "✗ Link missing"

# Verify summary exists
grep -q "^## Code Standards" CLAUDE.md && echo "✓ Section header exists" || echo "✗ Header missing"
grep -q "^\*\*Summary\*\*:" CLAUDE.md && echo "✓ Summary exists" || echo "✗ Summary missing"

# Check file size reduction
wc -l CLAUDE.md
```

### Phase 3: Extract "Directory Organization Standards" Section

**Objective**: Move 231-line section to concepts documentation (largest extraction)

**Complexity**: Medium

**Tasks**:
- [ ] Extract lines 185-467 from CLAUDE.md (directory_organization section)
- [ ] CREATE .claude/docs/concepts/directory-organization.md with full content
- [ ] Add frontmatter (metadata, date, purpose) to directory-organization.md
- [ ] Include directory structure diagram, decision matrix, anti-patterns
- [ ] Add navigation links to related concepts (directory-protocols, writing-standards)
- [ ] Replace CLAUDE.md lines 185-467 with summary:
  ```markdown
  ## Directory Organization Standards
  [Used by: /implement, /plan, /refactor, all development commands]

  See [Directory Organization Standards](.claude/docs/concepts/directory-organization.md) for complete guidelines.

  **Summary**: Clear directory organization prevents file misplacement. Each directory (scripts/, lib/, commands/, agents/, docs/, utils/) has specific purpose. Includes decision matrix, file placement rules, and anti-patterns.
  ```
- [ ] Validate link resolves: .claude/docs/concepts/directory-organization.md
- [ ] Check cross-references in .claude/commands/ still work
- [ ] Update .claude/docs/concepts/README.md to include new file

**Testing**:
```bash
# Verify file created
test -f .claude/docs/concepts/directory-organization.md && echo "✓ File created" || echo "✗ File missing"

# Verify link in CLAUDE.md
grep -q "directory-organization.md" CLAUDE.md && echo "✓ Link exists" || echo "✗ Link missing"

# Verify summary exists
grep -q "^## Directory Organization Standards" CLAUDE.md && echo "✓ Section header exists" || echo "✗ Header missing"

# Verify substantial file size
FILE_SIZE=$(wc -l < .claude/docs/concepts/directory-organization.md)
test "$FILE_SIZE" -gt 200 && echo "✓ File has substantial content ($FILE_SIZE lines)" || echo "✗ File too small"

# Check CLAUDE.md size reduction
wc -l CLAUDE.md
```

### Phase 4: Extract "Hierarchical Agent Architecture" Section

**Objective**: Move 93-line section to concepts documentation

**Complexity**: Low

**Tasks**:
- [ ] Extract lines 612-704 from CLAUDE.md (hierarchical_agent_architecture section)
- [ ] CREATE .claude/docs/concepts/hierarchical-agents.md with full content (note: file referenced but doesn't exist)
- [ ] Add frontmatter (metadata, date, purpose) to hierarchical-agents.md
- [ ] Include overview, key features, context reduction metrics, utilities, agent templates
- [ ] Add navigation links to related patterns (metadata-extraction, forward-message, hierarchical-supervision)
- [ ] Replace CLAUDE.md lines 612-704 with summary:
  ```markdown
  ## Hierarchical Agent Architecture
  [Used by: /orchestrate, /implement, /plan, /debug]

  See [Hierarchical Agent Architecture](.claude/docs/concepts/hierarchical-agents.md) for complete documentation.

  **Summary**: Multi-level agent coordination system minimizing context consumption through metadata-based passing (99% reduction). Enables recursive supervision, parallel execution (60-80% time savings), and <30% context usage throughout workflows.
  ```
- [ ] Validate link resolves: .claude/docs/concepts/hierarchical-agents.md
- [ ] Check cross-references in .claude/commands/ still work
- [ ] Update .claude/docs/concepts/README.md to include new file

**Testing**:
```bash
# Verify file created
test -f .claude/docs/concepts/hierarchical-agents.md && echo "✓ File created" || echo "✗ File missing"

# Verify link in CLAUDE.md
grep -q "hierarchical-agents.md" CLAUDE.md && echo "✓ Link exists" || echo "✗ Link missing"

# Verify summary exists
grep -q "^## Hierarchical Agent Architecture" CLAUDE.md && echo "✓ Section header exists" || echo "✗ Header missing"

# Check file size
FILE_SIZE=$(wc -l < .claude/docs/concepts/hierarchical-agents.md)
test "$FILE_SIZE" -gt 80 && echo "✓ File has substantial content ($FILE_SIZE lines)" || echo "✗ File too small"

# Check CLAUDE.md size reduction
wc -l CLAUDE.md
```

### Phase 5: Reduce "State-Based Orchestration Architecture" Section

**Objective**: Replace 108-line section with summary + link to existing comprehensive doc

**Complexity**: Low

**Tasks**:
- [ ] Verify .claude/docs/architecture/state-based-orchestration-overview.md exists (comprehensive 2,000+ line doc)
- [ ] Replace CLAUDE.md lines 706-813 with summary:
  ```markdown
  ## State-Based Orchestration Architecture
  [Used by: /coordinate, /orchestrate, /supervise, custom orchestrators]

  See [State-Based Orchestration Overview](.claude/docs/architecture/state-based-orchestration-overview.md) for complete architecture reference.

  **Summary**: State machines with validated transitions manage multi-phase workflows. Replaces implicit phase numbers with named states (initialize, research, plan, implement, test, debug, document, complete). Achieved 48.9% code reduction, 67% performance improvement, 95.6% context reduction via hierarchical supervisors.
  ```
- [ ] Validate link resolves: .claude/docs/architecture/state-based-orchestration-overview.md
- [ ] Check cross-references in .claude/commands/ still work

**Testing**:
```bash
# Verify comprehensive doc exists
test -f .claude/docs/architecture/state-based-orchestration-overview.md && echo "✓ Comprehensive doc exists" || echo "✗ Doc missing"

# Verify link in CLAUDE.md
grep -q "state-based-orchestration-overview.md" CLAUDE.md && echo "✓ Link exists" || echo "✗ Link missing"

# Verify summary exists
grep -q "^## State-Based Orchestration Architecture" CLAUDE.md && echo "✓ Section header exists" || echo "✗ Header missing"

# Verify section is now concise
SECTION_SIZE=$(sed -n '/^## State-Based Orchestration Architecture/,/^## /p' CLAUDE.md | wc -l)
test "$SECTION_SIZE" -lt 20 && echo "✓ Section reduced to summary ($SECTION_SIZE lines)" || echo "✗ Section still too large"

# Check CLAUDE.md size reduction
wc -l CLAUDE.md
```

### Phase 6: Verification and Validation

**Objective**: Ensure all changes work correctly and no breakage

**Complexity**: Low

**Tasks**:
- [ ] Run .claude/scripts/validate-links-quick.sh (all links resolve)
- [ ] Verify all [Used by: ...] metadata intact in CLAUDE.md
- [ ] Check CLAUDE.md size reduced to target (~527 lines)
- [ ] Verify all new files have proper frontmatter and navigation
- [ ] Grep for broken section references in .claude/commands/
- [ ] Test command discovery still works (/plan, /implement, /test, /orchestrate)
- [ ] Verify .claude/docs/concepts/README.md includes new files
- [ ] Run /setup --validate (if available) to check CLAUDE.md structure
- [ ] If any validation fails: ROLLBACK using backup from Phase 1

**Testing**:
```bash
# Comprehensive validation
.claude/scripts/validate-links-quick.sh || echo "WARNING: Link validation failed"

# Check CLAUDE.md size
CURRENT_SIZE=$(wc -l < CLAUDE.md)
TARGET_SIZE=527
VARIANCE=$((CURRENT_SIZE - TARGET_SIZE))
if [ "$VARIANCE" -lt 50 ] && [ "$VARIANCE" -gt -50 ]; then
  echo "✓ CLAUDE.md size within target range: $CURRENT_SIZE lines (target: $TARGET_SIZE)"
else
  echo "✗ CLAUDE.md size outside target range: $CURRENT_SIZE lines (target: $TARGET_SIZE)"
fi

# Check all new files exist
for file in \
  .claude/docs/reference/code-standards.md \
  .claude/docs/concepts/directory-organization.md \
  .claude/docs/concepts/hierarchical-agents.md; do
  test -f "$file" && echo "✓ $file exists" || echo "✗ $file missing"
done

# Check metadata preserved
grep -q "\[Used by:" CLAUDE.md && echo "✓ Metadata tags preserved" || echo "✗ Metadata missing"

# Check command references
grep -r "code_standards\|directory_organization\|hierarchical_agent" .claude/commands/ | grep -v ".md:.*http" || echo "✓ No broken inline references in commands"

# If failures detected, rollback:
# BACKUP_FILE=$(ls -t .claude/backups/CLAUDE.md.* 2>/dev/null | head -1)
# cp "$BACKUP_FILE" CLAUDE.md
# echo "ROLLBACK EXECUTED: Restored from $BACKUP_FILE"
```

## Success Criteria

- [ ] CLAUDE.md reduced from 964 to ~527 lines (45.3% reduction)
- [ ] All 4 bloated sections extracted to appropriate .claude/docs/ locations
- [ ] 3 new files created: code-standards.md, directory-organization.md, hierarchical-agents.md
- [ ] 1 section reduced to summary: state-based-orchestration (108 lines → 15 lines)
- [ ] All internal links validate successfully (.claude/scripts/validate-links-quick.sh passes)
- [ ] All command metadata references intact ([Used by: ...] tags preserved)
- [ ] Backup created and accessible for rollback if needed
- [ ] No test failures or command discovery regressions
- [ ] All new files have proper frontmatter and navigation links
- [ ] .claude/docs/concepts/README.md updated to include new files

## Rollback Procedure

If any phase fails or validation errors occur:

```bash
# Restore from backup
BACKUP_FILE=$(ls -t .claude/backups/CLAUDE.md.* 2>/dev/null | head -1)
if [ -f "$BACKUP_FILE" ]; then
  cp "$BACKUP_FILE" CLAUDE.md
  echo "✓ ROLLBACK COMPLETE: Restored from $BACKUP_FILE"
else
  echo "✗ ERROR: No backup file found"
  exit 1
fi

# Verify restoration
RESTORED_SIZE=$(wc -l < CLAUDE.md)
if [ "$RESTORED_SIZE" -eq 964 ]; then
  echo "✓ CLAUDE.md restored to original size (964 lines)"
else
  echo "⚠ WARNING: CLAUDE.md size is $RESTORED_SIZE lines (expected 964)"
fi

# Optionally remove incomplete extracted files
read -p "Remove incomplete extracted files? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -f .claude/docs/reference/code-standards.md
  rm -f .claude/docs/concepts/directory-organization.md
  rm -f .claude/docs/concepts/hierarchical-agents.md
  echo "✓ Incomplete files removed"
fi
```

**When to Rollback**:
- Validation fails in Phase 6 (link validation or metadata checks)
- Links break during extraction (commands can't find referenced sections)
- Command discovery stops working (/plan, /implement, etc. can't find standards)
- CLAUDE.md size exceeds expected range (>600 lines or <450 lines)
- Manual intervention required due to unexpected issues
