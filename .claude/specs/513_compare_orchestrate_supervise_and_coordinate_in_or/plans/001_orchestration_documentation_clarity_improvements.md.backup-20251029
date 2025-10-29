# Orchestration Documentation Clarity Improvements

## Metadata
- **Date**: 2025-10-28
- **Feature**: Improve orchestration command documentation clarity
- **Scope**: .claude/docs/ documentation updates for /orchestrate, /supervise, and /coordinate
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/513_compare_orchestrate_supervise_and_coordinate_in_or/reports/001_compare_orchestrate_supervise_and_coordinate_in_or/OVERVIEW.md

## Overview

This plan improves the documentation in `.claude/docs/` to clearly communicate the differences between the three orchestration commands (/orchestrate, /supervise, /coordinate) while maintaining simplicity and avoiding redundancy. The research shows that all three commands should be retained as they serve distinct use cases despite 100% architectural compatibility.

**Key Insight**: /orchestrate is the heaviest (5,438 lines, PR automation + dashboards), /supervise is the lightest (1,939 lines, proven minimal reference), and /coordinate is the middle ground (2,500-3,000 lines, wave-based parallel execution).

## Success Criteria
- [ ] Clear command selection guidance added to appropriate locations
- [ ] Redundant or conflicting information removed
- [ ] Simple decision tree for users to choose the right command
- [ ] File size complexities accurately communicated
- [ ] Unique features of each command clearly documented
- [ ] CLAUDE.md orchestration section updated for clarity
- [ ] All documentation cross-references validated

## Technical Design

### Current State Analysis
1. **CLAUDE.md** (lines 360-373): Has basic command descriptions but lacks clear selection guidance
2. **orchestration-reference.md** (990 lines): Comprehensive but may contain outdated comparison data
3. **command-reference.md** (586 lines): Has individual command entries but no comparison
4. **orchestration-troubleshooting.md** (832 lines): Focuses on troubleshooting, mentions all three commands

### Documentation Strategy
**Core Principle**: Single source of truth for comparison → Reference it, don't duplicate

**Proposed Structure**:
1. **Quick Selection Guide** (NEW): `.claude/docs/quick-reference/orchestration-command-selection.md`
   - ~150-200 lines
   - Decision tree visual
   - Feature comparison matrix
   - Use case recommendations

2. **CLAUDE.md Updates**: Add cross-reference to selection guide, simplify inline descriptions

3. **orchestration-reference.md**: Add command comparison section at top, reference research findings

4. **command-reference.md**: Add "see also" links to selection guide for each orchestration command

### Avoiding Redundancy
- **Don't repeat** feature lists in multiple places
- **Do provide** contextualized links (e.g., "need PR automation? see /orchestrate in selection guide")
- **Extract** detailed comparisons to dedicated selection guide
- **Keep** CLAUDE.md minimal with link to detailed guide

## Implementation Phases

### Phase 1: Create Orchestration Command Selection Guide
**Objective**: Create new dedicated guide for command selection decisions
**Complexity**: Medium

Tasks:
- [ ] Create `.claude/docs/quick-reference/orchestration-command-selection.md`
- [ ] Add decision tree (ASCII art for terminal compatibility)
- [ ] Add feature comparison matrix (table format)
- [ ] Document file size differences (5,438 vs 1,939 vs 2,500-3,000 lines)
- [ ] Add use case recommendations from research report
- [ ] Include interoperability examples (switching commands mid-workflow)
- [ ] Reference research report findings

Testing:
```bash
# Verify file created and properly formatted
cat .claude/docs/quick-reference/orchestration-command-selection.md
wc -l .claude/docs/quick-reference/orchestration-command-selection.md  # Should be 150-250 lines
```

Expected: New file with clear decision tree, matrix, and recommendations

### Phase 2: Update CLAUDE.md Orchestration Section
**Objective**: Simplify CLAUDE.md and add cross-reference to selection guide
**Complexity**: Low

Tasks:
- [ ] Update lines 360-373 in CLAUDE.md (orchestration commands section)
- [ ] Clarify file size hierarchy (/orchestrate: 5,438 lines (heaviest), /coordinate: 2,500-3,000 lines (middle), /supervise: 1,939 lines (lightest))
- [ ] Add prominent link to orchestration command selection guide
- [ ] Remove redundant feature descriptions
- [ ] Keep one-line summary per command
- [ ] Ensure "three orchestration commands available" statement is clear

Testing:
```bash
# Verify CLAUDE.md section updated
grep -A 20 "Orchestration:" CLAUDE.md
# Check line count didn't bloat
wc -l CLAUDE.md
```

Expected: Simplified section with clear link to detailed selection guide

### Phase 3: Enhance orchestration-reference.md
**Objective**: Add command comparison section and update outdated information
**Complexity**: Medium

Tasks:
- [ ] Read current orchestration-reference.md in full
- [ ] Add "Command Selection" section near top (after Quick Reference)
- [ ] Include simplified comparison matrix
- [ ] Link to detailed selection guide for full decision tree
- [ ] Update any file size references to match research (5,438 / 2,500-3,000 / 1,939)
- [ ] Verify wave-based execution is only mentioned for /coordinate (not /orchestrate)
- [ ] Add note that /supervise lacks wave-based execution (sequential only)
- [ ] Ensure PR automation is clearly /orchestrate-only feature

Testing:
```bash
# Verify updates made
grep -n "Command Selection\|5,438\|1,939\|2,500-3,000" .claude/docs/reference/orchestration-reference.md
# Check file size didn't grow excessively
wc -l .claude/docs/reference/orchestration-reference.md  # Should stay around 1000-1100 lines
```

Expected: Enhanced reference with accurate comparisons and selection guidance

### Phase 4: Update Individual Command Entries
**Objective**: Add cross-references in command-reference.md
**Complexity**: Low

Tasks:
- [ ] Update /orchestrate entry in command-reference.md
  - Add "Heaviest (5,438 lines), includes PR automation and dashboards"
  - Link to selection guide
- [ ] Update /coordinate entry in command-reference.md
  - Add "Middle ground (2,500-3,000 lines), wave-based parallel execution"
  - Link to selection guide
- [ ] Update /supervise entry in command-reference.md (if exists)
  - Add "Lightest (1,939 lines), proven minimal reference"
  - Link to selection guide
  - Add links to supervise-guide.md and supervise-phases.md
- [ ] Verify "Use Case" fields mention appropriate scenarios

Testing:
```bash
# Verify all three commands have selection guide links
grep -A 10 "^### /orchestrate\|^### /coordinate\|^### /supervise" .claude/docs/reference/command-reference.md | grep "selection"
```

Expected: All three orchestration commands reference the selection guide

### Phase 5: Documentation Validation and Cleanup
**Objective**: Ensure consistency and remove redundant content
**Complexity**: Low

Tasks:
- [ ] Search for redundant feature comparisons in other docs
  ```bash
  grep -r "orchestrate.*coordinate.*supervise" .claude/docs/ --include="*.md"
  ```
- [ ] Check for outdated file size references
  ```bash
  grep -r "5438\|2500\|3000\|1939" .claude/docs/ --include="*.md"
  ```
- [ ] Validate all cross-reference links work
- [ ] Ensure no documentation contradicts research findings
- [ ] Update orchestration-troubleshooting.md if it contains comparison info (should defer to selection guide)
- [ ] Verify README files in docs/ subdirectories link to selection guide if mentioning orchestration

Testing:
```bash
# Comprehensive validation
.claude/tests/test_orchestration_commands.sh  # If exists
# Manual link checking
grep -r "\[.*\](.*orchestration.*selection" .claude/docs/ --include="*.md"
# Verify no "TODO" or incomplete sections
grep -i "TODO\|FIXME\|TBD" .claude/docs/**/orchestr*.md .claude/docs/quick-reference/orchestration-command-selection.md
```

Expected: Clean, consistent documentation with no redundancy or broken links

## Testing Strategy

### Per-Phase Testing
Each phase includes specific validation commands to verify changes are correct and complete.

### Integration Testing
After all phases complete:

```bash
# 1. Verify new selection guide exists and is properly sized
test -f .claude/docs/quick-reference/orchestration-command-selection.md
wc -l .claude/docs/quick-reference/orchestration-command-selection.md  # 150-250 lines

# 2. Verify CLAUDE.md references selection guide
grep "orchestration.*selection" CLAUDE.md

# 3. Check no file grew excessively
wc -l .claude/docs/reference/orchestration-reference.md  # ~1000-1100 lines
wc -l .claude/docs/reference/command-reference.md  # ~600-650 lines
wc -l CLAUDE.md  # Should not increase significantly

# 4. Validate file size consistency across docs
grep -r "5,438\|5438" .claude/docs/ --include="*.md"  # All should say 5,438 lines for /orchestrate
grep -r "1,939\|1939" .claude/docs/ --include="*.md"  # All should say 1,939 lines for /supervise
grep -r "2,500\|2500\|3,000\|3000" .claude/docs/ --include="*.md"  # All should say 2,500-3,000 for /coordinate

# 5. Check for redundancy
# Should find comparison content primarily in selection guide, not scattered
grep -l "orchestrate.*coordinate.*supervise" .claude/docs/**/*.md | wc -l  # Should be small number
```

### Manual Review Checklist
- [ ] Read selection guide - is decision tree clear?
- [ ] Read CLAUDE.md orchestration section - is it concise?
- [ ] Read orchestration-reference.md - does it link to selection guide?
- [ ] Check command-reference.md entries - do they cross-reference appropriately?
- [ ] Verify no contradictions between documents

## Documentation Requirements

### Files to Create
1. `.claude/docs/quick-reference/orchestration-command-selection.md` (~200 lines)
   - Decision tree
   - Feature comparison matrix
   - Use case recommendations
   - Interoperability examples

### Files to Update
1. `CLAUDE.md` (lines 360-373)
   - Simplify orchestration section
   - Add selection guide link
   - Clarify file size hierarchy

2. `.claude/docs/reference/orchestration-reference.md`
   - Add command selection section
   - Update file size references
   - Clarify unique features per command

3. `.claude/docs/reference/command-reference.md`
   - Update /orchestrate, /coordinate, /supervise entries
   - Add selection guide cross-references

4. Any other files with redundant comparison content (identified in Phase 5)

### Cross-References to Validate
- [ ] CLAUDE.md → orchestration-command-selection.md
- [ ] orchestration-reference.md → orchestration-command-selection.md
- [ ] command-reference.md → orchestration-command-selection.md
- [ ] Selection guide → research report (Spec 513)
- [ ] Selection guide → command files (.claude/commands/*.md)

## Dependencies

### Research Report
- **Path**: `.claude/specs/513_compare_orchestrate_supervise_and_coordinate_in_or/reports/001_compare_orchestrate_supervise_and_coordinate_in_or/OVERVIEW.md`
- **Key Findings**:
  - All three commands share 100% architectural compatibility
  - /orchestrate: 5,438 lines (PR automation, dashboards, metrics)
  - /supervise: 1,939 lines (minimal reference, external docs)
  - /coordinate: 2,500-3,000 lines (wave-based parallel, 40-60% time savings)
  - Recommendation: Retain all three commands

### Existing Documentation
- `.claude/docs/reference/orchestration-reference.md` (990 lines)
- `.claude/docs/reference/command-reference.md` (586 lines)
- `.claude/docs/guides/orchestration-troubleshooting.md` (832 lines)
- `.claude/docs/guides/supervise-guide.md` (usage guide for /supervise)
- `.claude/docs/reference/supervise-phases.md` (phase reference for /supervise)

### Standards
- Follow writing standards from `.claude/docs/concepts/writing-standards.md`
- No emojis in file content
- Use Unicode box-drawing for diagrams (terminal-compatible)
- Present-focused, timeless documentation (no "new" or historical markers)
- Clarity and coherence over backward compatibility

## Notes

### Key Principles
1. **Single Source of Truth**: Detailed comparison in selection guide, other docs link to it
2. **Simplicity**: CLAUDE.md stays concise, details in reference docs
3. **No Redundancy**: Don't repeat feature lists in multiple places
4. **Clear Hierarchy**: Heaviest → Middle → Lightest (5,438 → 2,500-3,000 → 1,939)
5. **Actionable Guidance**: Decision tree helps users choose quickly

### File Size Communication
Always present file sizes in this order and format:
- `/orchestrate`: 5,438 lines (heaviest)
- `/coordinate`: 2,500-3,000 lines (middle ground)
- `/supervise`: 1,939 lines (lightest)

### Unique Features to Highlight
- `/orchestrate only`: PR automation, interactive dashboards, comprehensive metrics
- `/supervise only`: Minimal reference, extensive external docs, proven compliance
- `/coordinate only`: Wave-based parallel execution (40-60% time savings), workflow auto-detection

### Risk Mitigation
- **Risk**: Making docs too long or complex
  - **Mitigation**: Strict line limits, extract to dedicated guide
- **Risk**: Introducing inconsistencies
  - **Mitigation**: Phase 5 validation catches contradictions
- **Risk**: Breaking existing workflows
  - **Mitigation**: Only documentation changes, no command modifications
