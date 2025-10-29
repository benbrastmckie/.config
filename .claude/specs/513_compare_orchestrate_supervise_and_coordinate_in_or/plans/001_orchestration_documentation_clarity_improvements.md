# Orchestration Documentation Clarity Improvements

## Metadata
- **Date**: 2025-10-28
- **Feature**: Improve orchestration command documentation clarity
- **Scope**: .claude/docs/ documentation updates for /orchestrate, /supervise, and /coordinate
- **Estimated Phases**: 4 (reduced from 5)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - /home/benjamin/.config/.claude/specs/513_compare_orchestrate_supervise_and_coordinate_in_or/reports/001_compare_orchestrate_supervise_and_coordinate_in_or/OVERVIEW.md
- **Aligned With**:
  - /home/benjamin/.config/.claude/specs/509_use_homebenjaminconfigclaudespecs508_research_best/plans/001_use_homebenjaminconfigclaudespecs508_research_best_plan.md (documentation refactor principles)

## Overview

This plan improves the documentation in `.claude/docs/` to clearly communicate the differences between the three orchestration commands (/orchestrate, /supervise, /coordinate) while maintaining simplicity and avoiding redundancy. The research shows that all three commands should be retained as they serve distinct use cases despite 100% architectural compatibility.

**Key Insight**: /orchestrate is the heaviest (5,438 lines, PR automation + dashboards), /supervise is the lightest (1,939 lines, proven minimal reference), and /coordinate is the middle ground (2,500-3,000 lines, wave-based parallel execution).

**IMPORTANT NOTE**: /orchestrate and /supervise are currently under active development and do not yet provide consistent, production-ready functionality. /coordinate is the stable, production-ready orchestration command. Documentation should clearly communicate this maturity difference to guide users toward /coordinate for reliable workflows.

## Success Criteria
- [ ] Clear command selection guidance added to appropriate locations
- [ ] Maturity status prominently displayed for each command (/coordinate = production-ready, others = in development)
- [ ] Redundant or conflicting information removed (target: eliminate redundancy in 3-5 files)
- [ ] Simple decision tree for users to choose the right command (default: /coordinate)
- [ ] File size complexities accurately communicated with maturity notes
- [ ] Unique features of each command clearly documented with stability warnings
- [ ] CLAUDE.md orchestration section updated for clarity with /coordinate as recommended default
- [ ] All documentation cross-references validated
- [ ] Selection guide integrated with orchestration-best-practices.md (created in Plan 509)
- [ ] Timeless documentation maintained (no historical markers or date references)
- [ ] All archived content includes redirect READMEs
- [ ] Clear guidance steering users to /coordinate for production use

## Technical Design

### Current State Analysis (Updated 2025-10-29)
1. **CLAUDE.md** (lines 360-373): Has basic command descriptions but lacks clear selection guidance
2. **orchestration-reference.md** (~990 lines): CONSOLIDATED in Plan 509 Phase 2 (originally ~1,800 lines in plan, actual result ~990)
3. **orchestration-best-practices.md** (1,113 lines): CREATED in Plan 509 Phase 4, documents unified 7-phase workflow but does NOT yet include command selection section
4. **command-reference.md** (~586 lines): Has individual command entries but no command comparison
5. **orchestration-troubleshooting.md** (~832 lines): Focuses on troubleshooting, mentions all three commands

**Impact of Plan 509 Refactor** (Completed):
- Phase 2 consolidated orchestration reference docs with significant size reduction
- Phase 4 created unified best practices guide (1,113 lines) with 7-phase workflow documentation
- Phase 5 added "I Want To..." navigation and decision trees throughout docs
- Phase 7 completed all validation and documentation updates
- **This plan (513) builds on those foundations**: No command selection section exists yet in any file

### Documentation Strategy
**Core Principle**: Single source of truth for comparison → Reference it, don't duplicate

**Proposed Structure** [REVISED 2025-10-29]:
1. **orchestration-best-practices.md Updates** (Phase 1): Add command selection section to existing unified guide
   - Current: 1,113 lines with 7-phase workflow documentation
   - Add: ~200-250 lines for command selection section
   - Content: **Maturity status**, decision tree (default: /coordinate), feature comparison matrix with maturity column, use case recommendations
   - Position: Early in document (after Overview, before detailed phase documentation)
   - Target: ~1,300-1,350 lines total
   - **Key message**: /coordinate is production-ready default; /orchestrate and /supervise are experimental

2. **CLAUDE.md Updates** (Phase 2): Add cross-reference to orchestration-best-practices.md command selection section
   - Simplify inline orchestration command descriptions
   - Add prominent link to command selection section
   - **Add maturity status** for each command with /coordinate as recommended default

3. **orchestration-reference.md Updates** (Phase 3): Ensure single cross-reference to command selection section
   - Current: ~990 lines (consolidated in Plan 509)
   - Add: Prominent link to orchestration-best-practices.md command selection section
   - Verify: No redundant comparison content remains

4. **command-reference.md Updates** (Phase 4): Add "see also" links to orchestration-best-practices.md command selection
   - Update /orchestrate, /coordinate, /supervise entries
   - Add file size information for each command
   - **Add maturity status** for each command entry

**Rationale**: Plan 509 created orchestration-best-practices.md as the comprehensive orchestration guide. Integrate command selection there (not in a separate file) for single source of truth. This follows Plan 509's consolidation principles. **Added consideration**: Clearly communicate that /coordinate is the production-ready default to prevent users from choosing unstable alternatives.

### Avoiding Redundancy
- **Don't repeat** feature lists in multiple places
- **Do provide** contextualized links (e.g., "need PR automation? see command selection in orchestration-best-practices.md")
- **Centralize** detailed comparisons in orchestration-best-practices.md command selection section
- **Keep** CLAUDE.md minimal with link to detailed command selection section

## Implementation Phases

### Phase 1: Add Command Selection to orchestration-best-practices.md [COMPLETED]
**Objective**: Integrate command selection guidance into existing unified orchestration guide
**Complexity**: Medium

**Rationale**: Plan 509 created orchestration-best-practices.md (currently 1,113 lines) as the authoritative orchestration guide. Adding command selection there creates a single comprehensive resource rather than fragmenting guidance across multiple files.

**Current State**: orchestration-best-practices.md exists at 1,113 lines and documents the unified 7-phase framework, but does not yet include command selection guidance.

Tasks:
- [x] Read orchestration-best-practices.md to understand current structure
- [x] Add "Command Selection" section early in document (after Overview, before detailed phase documentation)
- [x] Add maturity/stability section prominently at the top:
  - /coordinate: **Production-ready** - stable, tested, recommended for all workflows
  - /orchestrate: **In Development** - PR automation features being refined, may have inconsistent behavior
  - /supervise: **In Development** - minimal reference implementation being stabilized
- [x] Add decision tree (ASCII art using Unicode box-drawing for terminal compatibility)
  - Default recommendation: Use /coordinate unless you need specific experimental features
- [x] Add feature comparison matrix (markdown table format)
  - Include "Maturity Status" column
- [x] Document file size hierarchy clearly:
  - /orchestrate: 5,438 lines (heaviest, PR automation + dashboards, **in development**)
  - /coordinate: 2,500-3,000 lines (middle, wave-based parallel execution, **production-ready**)
  - /supervise: 1,939 lines (lightest, proven minimal reference, **in development**)
- [x] Add use case recommendations from Spec 513 research report
  - Emphasize /coordinate as default choice
  - Note /orchestrate and /supervise as experimental alternatives
- [x] Include interoperability note (commands are 100% architecturally compatible)
- [x] Reference Spec 513 research report OVERVIEW.md for detailed findings
- [x] Add navigation breadcrumb at top if not present

Testing:
```bash
# Verify section added to orchestration-best-practices.md
grep -q "Command Selection" .claude/docs/guides/orchestration-best-practices.md
grep -q "Decision Tree\|Feature Comparison" .claude/docs/guides/orchestration-best-practices.md

# Verify file size increased appropriately
wc -l .claude/docs/guides/orchestration-best-practices.md  # Should be ~1,300-1,350 lines (1,113 + 200-250)

# Verify no historical markers added
! grep -E "\(NEW\)|\(Updated.*\)|Recently|Previously" .claude/docs/guides/orchestration-best-practices.md

# Verify section is before Phase 0 details
grep -n "Command Selection\|Phase 0: Path Pre-Calculation" .claude/docs/guides/orchestration-best-practices.md | head -5
```

Expected: orchestration-best-practices.md enhanced with command selection section (~200-250 lines added), positioned before detailed phase documentation

### Phase 2: Update CLAUDE.md Orchestration Section [REVISED]
**Objective**: Simplify CLAUDE.md and add cross-reference to orchestration-best-practices.md
**Complexity**: Low

Tasks:
- [ ] Update lines 360-373 in CLAUDE.md (orchestration commands section)
- [ ] Add maturity status to each command:
  - /coordinate: Production-ready, recommended for all workflows
  - /orchestrate: In development, experimental PR automation features
  - /supervise: In development, minimal reference being stabilized
- [ ] Clarify file size hierarchy with maturity notes:
  - /orchestrate: 5,438 lines (heaviest, **in development**)
  - /coordinate: 2,500-3,000 lines (middle, **production-ready**)
  - /supervise: 1,939 lines (lightest, **in development**)
- [ ] Add prominent link to orchestration-best-practices.md command selection section
- [ ] Include clear recommendation: "Use /coordinate for reliable production workflows"
- [ ] Remove redundant feature descriptions
- [ ] Keep one-line summary per command with maturity status
- [ ] Ensure "three orchestration commands available" statement mentions /coordinate as production-ready default
- [ ] Follow timeless documentation principles from Plan 509 (no historical markers)

Testing:
```bash
# Verify CLAUDE.md section updated
grep -A 20 "Orchestration:" CLAUDE.md
grep -q "orchestration-best-practices.md" CLAUDE.md

# Check line count didn't bloat
wc -l CLAUDE.md

# Verify no historical markers added
! grep -E "\(NEW\)|\(Updated.*\)|Recently|Previously" CLAUDE.md
```

Expected: Simplified section with clear link to orchestration-best-practices.md, timeless language

### Phase 3: Update orchestration-reference.md Cross-References [REVISED]
**Objective**: Ensure orchestration-reference.md properly links to orchestration-best-practices.md command selection section
**Complexity**: Low

**Rationale**: orchestration-reference.md (consolidated in Plan 509 Phase 2 to 990 lines) should have a single prominent cross-reference to the command selection section in orchestration-best-practices.md, avoiding duplication.

**Current State**: orchestration-reference.md exists and has been consolidated, but needs to reference the new command selection section.

Tasks:
- [ ] Read orchestration-reference.md to find appropriate location for cross-reference
- [ ] Add prominent "Command Selection" section or note near the top linking to orchestration-best-practices.md
- [ ] Ensure no redundant command comparison content exists in orchestration-reference.md
- [ ] Validate unique features are clearly attributed to correct commands:
  - Wave-based execution: /coordinate only
  - PR automation: /orchestrate only
  - External documentation ecosystem: /supervise only
- [ ] Verify timeless language (no historical markers)

Testing:
```bash
# Verify orchestration-reference.md references command selection in best practices guide
grep -q "orchestration-best-practices.*[Cc]ommand.*[Ss]election\|[Cc]ommand.*[Ss]election.*orchestration-best-practices" .claude/docs/reference/orchestration-reference.md

# Ensure no redundant comparison content remains
! grep -i "decision tree\|comparison matrix\|which command to use" .claude/docs/reference/orchestration-reference.md || echo "WARNING: Possible duplication"

# Verify no historical markers
! grep -E "\(NEW\)|\(Updated.*\)|Recently|Previously" .claude/docs/reference/orchestration-reference.md

# Check file size didn't grow significantly
wc -l .claude/docs/reference/orchestration-reference.md  # Should remain ~990-1,010 lines
```

Expected: orchestration-reference.md has clear link to command selection section in orchestration-best-practices.md, no redundant comparison content, minimal size increase

### Phase 4: Update Individual Command Entries and Final Validation [REVISED]
**Objective**: Add cross-references in command-reference.md and validate all changes
**Complexity**: Low

**Note**: Phase 5 merged into Phase 4 to reduce total phases from 5 to 4

Tasks:
- [ ] Update /orchestrate entry in command-reference.md
  - Add "Heaviest (5,438 lines), includes PR automation and dashboards"
  - Add maturity status: "**Status**: In Development - experimental features, may have inconsistent behavior"
  - Link to orchestration-best-practices.md command selection section
- [ ] Update /coordinate entry in command-reference.md
  - Add "Middle ground (2,500-3,000 lines), wave-based parallel execution"
  - Add maturity status: "**Status**: Production-Ready - stable, tested, recommended for all workflows"
  - Mark as default/recommended choice
  - Link to orchestration-best-practices.md command selection section
- [ ] Update /supervise entry in command-reference.md (if exists)
  - Add "Lightest (1,939 lines), proven minimal reference"
  - Add maturity status: "**Status**: In Development - minimal reference being stabilized"
  - Link to orchestration-best-practices.md command selection section
  - Verify links to supervise-guide.md still work
- [ ] Verify "Use Case" fields emphasize /coordinate as default, others as experimental
- [ ] Search for redundant feature comparisons in other docs and remove/update
- [ ] Validate all cross-reference links work
- [ ] Ensure no documentation contradicts maturity status or research findings
- [ ] Update orchestration-troubleshooting.md if it contains comparison info (defer to best practices guide)
- [ ] Run timeless documentation validation (no historical markers)

Testing:
```bash
# Verify all three commands have best practices guide links
grep -A 10 "^### /orchestrate\|^### /coordinate\|^### /supervise" .claude/docs/reference/command-reference.md | grep "orchestration-best-practices"

# Comprehensive validation
grep -r "orchestration.*selection" .claude/docs/ --include="*.md" | grep -v archive

# Verify no historical language
! grep -rE "\(NEW\)|\(Updated\)|Recently added|Previously" .claude/docs/guides/orchestration-best-practices.md .claude/docs/reference/command-reference.md CLAUDE.md

# Verify file size consistency
grep -r "5,438\|5438" .claude/docs/ --include="*.md" | grep -v archive
grep -r "1,939\|1939" .claude/docs/ --include="*.md" | grep -v archive

# Check for broken links
find .claude/docs -name "*.md" -type f -exec grep -l "orchestration-command-selection.md" {} \; && echo "ERROR: Old selection guide references remain"
```

Expected: All three orchestration commands reference orchestration-best-practices.md, no broken links, timeless language throughout

**[PHASE 5 REMOVED]**: Merged into Phase 4 to consolidate validation tasks and reduce total phases from 5 to 4

## Testing Strategy

### Per-Phase Testing
Each phase includes specific validation commands to verify changes are correct and complete.

### Integration Testing
After all phases complete:

```bash
# 1. Verify command selection section exists in orchestration-best-practices.md
grep -q "Command Selection" .claude/docs/guides/orchestration-best-practices.md
wc -l .claude/docs/guides/orchestration-best-practices.md  # Should be ~1,300-1,350 lines

# 2. Verify CLAUDE.md references orchestration-best-practices.md
grep -q "orchestration-best-practices" CLAUDE.md

# 3. Check no file grew excessively
wc -l .claude/docs/reference/orchestration-reference.md  # Should remain ~990-1,010 lines
wc -l .claude/docs/reference/command-reference.md  # Should be ~600-650 lines
wc -l CLAUDE.md  # Should not increase significantly

# 4. Validate file size consistency across docs
grep -r "5,438\|5438" .claude/docs/ --include="*.md" | grep -v archive  # All should say 5,438 lines for /orchestrate
grep -r "1,939\|1939" .claude/docs/ --include="*.md" | grep -v archive  # All should say 1,939 lines for /supervise
grep -r "2,500\|2500\|3,000\|3000" .claude/docs/ --include="*.md" | grep -v archive  # All should say 2,500-3,000 for /coordinate

# 5. Check for redundancy
# Should find comparison content primarily in orchestration-best-practices.md, not scattered
grep -l "orchestrate.*coordinate.*supervise" .claude/docs/**/*.md | wc -l  # Should be small number (2-3 files max)

# 6. Verify all cross-references work
grep -r "orchestration-best-practices.md" .claude/docs/ --include="*.md" CLAUDE.md

# 7. Verify no historical markers added
! grep -rE "\(NEW\)|\(Updated.*\)|Recently|Previously" .claude/docs/guides/orchestration-best-practices.md .claude/docs/reference/command-reference.md CLAUDE.md
```

### Manual Review Checklist
- [ ] Read command selection section in orchestration-best-practices.md - is decision tree clear?
- [ ] Read CLAUDE.md orchestration section - is it concise with proper link?
- [ ] Read orchestration-reference.md - does it link to command selection section?
- [ ] Check command-reference.md entries - do they cross-reference appropriately?
- [ ] Verify no contradictions between documents
- [ ] Confirm timeless language throughout (no historical markers)

## Documentation Requirements

### Files to Create [REVISED]
No new files - integrate content into existing orchestration-best-practices.md created in Plan 509

### Files to Update [REVISED]
1. `.claude/docs/guides/orchestration-best-practices.md` (created in Plan 509 Phase 4)
   - Add command selection section at top (~200 lines)
   - Include decision tree, comparison matrix, use case recommendations

2. `CLAUDE.md` (lines 360-373)
   - Simplify orchestration section
   - Add orchestration-best-practices.md link
   - Clarify file size hierarchy
   - Follow timeless documentation principles

3. `.claude/docs/reference/orchestration-reference.md`
   - Ensure single cross-reference to orchestration-best-practices.md
   - Remove any redundant comparison content
   - Clarify unique features per command

4. `.claude/docs/reference/command-reference.md`
   - Update /orchestrate, /coordinate, /supervise entries
   - Add orchestration-best-practices.md cross-references

5. Any other files with redundant comparison content (identified in Phase 4)

### Cross-References to Validate [REVISED]
- [ ] CLAUDE.md → orchestration-best-practices.md (command selection section)
- [ ] orchestration-reference.md → orchestration-best-practices.md
- [ ] command-reference.md → orchestration-best-practices.md
- [ ] orchestration-best-practices.md → research report (Spec 513)
- [ ] orchestration-best-practices.md → command files (.claude/commands/*.md)

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

## Revision History

### 2025-10-29 - Revision 3: Add Maturity Status for Orchestration Commands

**Changes Made**:
- **Updated Overview**: Added IMPORTANT NOTE stating /orchestrate and /supervise are in development, /coordinate is production-ready
- **Updated Success Criteria**: Added maturity status display requirement and clear guidance steering users to /coordinate
- **Updated Documentation Strategy**: Added maturity status messaging throughout all planned updates
- **Updated Phase 1 tasks**: Added maturity/stability section as first task, updated decision tree to default to /coordinate, added maturity status column to feature comparison matrix
- **Updated Phase 2 tasks**: Added maturity status for each command, clear recommendation for /coordinate, updated CLAUDE.md text to mention /coordinate as production-ready default
- **Updated Phase 4 tasks**: Added maturity status to all command entries in command-reference.md, marked /coordinate as default/recommended choice
- **Updated Notes section**: Added maturity status to unique features highlights

**Reason**: /orchestrate and /supervise are currently under active development and do not provide consistent, production-ready functionality. Users should be clearly guided toward /coordinate as the stable, recommended orchestration command. Documentation must prominently communicate this maturity difference to prevent users from encountering unstable behavior in production workflows.

**Modified Phases**: All phases (1-4), Overview, Success Criteria, Documentation Strategy, Notes section

**Key Messaging**:
- /coordinate: **Production-ready** - stable, tested, recommended for all workflows
- /orchestrate: **In Development** - experimental PR automation features, may have inconsistent behavior
- /supervise: **In Development** - minimal reference implementation being stabilized

**Impact on Implementation**: Each phase now includes tasks to add maturity status indicators throughout documentation. Decision tree and recommendation text will default to /coordinate as the production-ready choice.

### 2025-10-29 - Revision 2: Update for Post-Plan-509 Reality

**Changes Made**:
- **Updated Phase 1**: Clarified current state of orchestration-best-practices.md (1,113 lines, not 1,200)
- **Updated Phase 1 testing**: Adjusted expected line count from ~1,400 to ~1,300-1,350 lines
- **Updated Phase 3**: Complete rewrite to focus on orchestration-reference.md cross-reference updates (not creation of new content)
- **Updated Phase 3 title**: Changed from "Link Selection Guide to orchestration-best-practices.md" to "Update orchestration-reference.md Cross-References"
- **Updated integration testing**: Removed references to non-existent `/quick-reference/orchestration-command-selection.md` file
- **Updated integration testing**: Changed to verify command selection section exists within orchestration-best-practices.md
- **Updated manual review checklist**: Changed "Read selection guide" to "Read command selection section in orchestration-best-practices.md"
- **Updated all validation commands**: Removed checks for separate selection guide file, added checks for section within best practices guide

**Reason**: Plan 509 has been completed, and the current state of documentation is now different from what was anticipated in Revision 1. The orchestration-best-practices.md file exists at 1,113 lines (not the ~1,200 estimated), and no command selection section has been added yet. This revision updates the plan to reflect the actual current state and ensures all references to creating a separate selection guide file have been replaced with references to adding a section within the existing orchestration-best-practices.md.

**Modified Phases**: Phases 1, 3, and integration testing

**Key Changes from Revision 1**:
1. Phase 1 now explicitly notes the current 1,113-line size of orchestration-best-practices.md
2. Phase 3 completely rewritten to focus on cross-reference updates in orchestration-reference.md rather than duplicating Phase 1's work
3. All testing sections updated to check for section within orchestration-best-practices.md, not separate file
4. Removed all references to `.claude/docs/quick-reference/orchestration-command-selection.md` (does not exist)

### 2025-10-28 - Revision 1: Align with Plan 509 Documentation Refactor

**Changes Made**:
- **Reduced phases from 5 to 4**: Merged Phase 5 validation tasks into Phase 4
- **Changed target from new file to existing file**: Instead of creating `.claude/docs/quick-reference/orchestration-command-selection.md`, integrate command selection into existing `orchestration-best-practices.md` (created in Plan 509 Phase 4)
- **Updated Phase 1**: "Create Orchestration Command Selection Guide" → "Add Command Selection to orchestration-best-practices.md"
- **Updated Phase 2**: Link to orchestration-best-practices.md instead of separate selection guide
- **Updated Phase 3**: Changed from "Enhance orchestration-reference.md" to "Link Selection Guide to orchestration-best-practices.md" with reduced scope
- **Updated Phase 4**: Merged Phase 5 validation tasks, renamed to "Update Individual Command Entries and Final Validation"
- **Added timeless documentation validation**: All phases now check for historical markers
- **Updated success criteria**: Added alignment with Plan 509, timeless documentation, redirect READMEs
- **Updated documentation requirements**: No new files to create, focus on enhancing orchestration-best-practices.md

**Reason**: Plan 509 Phase 4 already created orchestration-best-practices.md (~1,200 lines) as the comprehensive orchestration guide. Creating a separate selection guide would violate Plan 509's "single source of truth" principle that successfully eliminated 8 redundant files and achieved 30-40% documentation size reduction. By integrating command selection into the existing best practices guide, we follow the same consolidation strategy.

**Reports Used**:
- Plan 509 completion report (all 7 phases completed)
- Plan 509's consolidation principles (single source of truth, 30-40% reduction targets, archive-with-redirect pattern)

**Modified Phases**: All phases (1-4)

**Impact on Success Criteria**: Enhanced - now explicitly requires integration with orchestration-best-practices.md and timeless documentation compliance

**Key Alignment Points with Plan 509**:
1. **Single Source of Truth**: Integrate into orchestration-best-practices.md rather than create separate file
2. **Consolidation over Creation**: Enhance existing comprehensive guide rather than fragment
3. **Timeless Documentation**: No historical markers, present-focused language
4. **Archive Pattern**: If eliminating any files, use redirect READMEs
5. **Validation**: Comprehensive link validation and consistency checks

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
- `/orchestrate only`: PR automation, interactive dashboards, comprehensive metrics (**experimental, in development**)
- `/supervise only`: Minimal reference, extensive external docs, proven compliance (**in development, being stabilized**)
- `/coordinate only`: Wave-based parallel execution (40-60% time savings), workflow auto-detection (**production-ready, recommended**)

### Risk Mitigation
- **Risk**: Making docs too long or complex
  - **Mitigation**: Strict line limits, extract to dedicated guide
- **Risk**: Introducing inconsistencies
  - **Mitigation**: Phase 5 validation catches contradictions
- **Risk**: Breaking existing workflows
  - **Mitigation**: Only documentation changes, no command modifications
