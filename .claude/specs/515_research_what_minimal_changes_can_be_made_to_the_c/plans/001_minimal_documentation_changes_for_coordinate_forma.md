# Minimal Documentation Changes for /coordinate Formatting Features

## Metadata

- **Date**: 2025-10-29
- **Feature**: Documentation updates reflecting Plan 002 formatting improvements
- **Scope**: Minimal changes to existing documentation only
- **Estimated Phases**: 3
- **Estimated Hours**: 4-5 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Analysis of Plan 002 Formatting Changes](../reports/001_analysis_of_plan_002_formatting_changes_and_their.md)
  - [Current Documentation Structure](../reports/002_current_documentation_structure_in_claudedocs_and_.md)
- **Structure Level**: 0
- **Complexity Score**: 35.5

## Overview

Plan 002 implemented significant formatting improvements to /coordinate command (50-60% context reduction). Following the spec 509 Diataxis reorganization (completed 2025-10-28), documentation is now structured into reference/, guides/, concepts/, and workflows/ directories. This plan implements MINIMAL changes to reflect Plan 002 formatting features: update orchestration-best-practices.md (guides/) with formatting section, remove historical language from key files, and consolidate scattered progress marker documentation. No new files created.

**Key Constraint**: Work with existing files in Diataxis structure, avoid creating new documentation, remove redundancy through consolidation not expansion.

**Note**: Spec 509 reorganization completed before this plan execution. All file paths now reflect Diataxis structure.

## Research Summary

Research identified three critical issues requiring minimal documentation changes:

1. **Formatting Changes** (Report 001): Plan 002 achieved 50-60% context reduction through library silence, concise verification (1-2 lines on success), standardized progress markers, and simplified completion summaries (53→8 lines). All changes are display-only with no functional modifications.

2. **Documentation Scatter** (Report 002): /coordinate features documented in 11 files with 60-70% overlap. Progress markers mentioned in 25+ files without single authoritative reference. Historical language in 85+ files creates confusion about current vs past state.

3. **Key Formatting Features** (Report 001): Workflow scope detection (71→10 lines), silent library operation (30+→0 lines), fail-fast verification with diagnostics, consistent PROGRESS markers, optional verbose mode (COORDINATE_VERBOSE=true).

**Recommended Approach**: Update orchestration-best-practices.md formatting section, remove historical language from 5 high-impact files, consolidate progress marker documentation into existing files (not new).

## Success Criteria

- [ ] orchestration-best-practices.md documents all Plan 002 formatting features
- [ ] Historical language removed from 5 key files (coordinate.md, orchestration-best-practices.md, orchestration-guide.md, behavioral-injection.md, command_architecture_standards.md)
- [ ] Progress markers consolidated into single authoritative section (orchestration-best-practices.md)
- [ ] No new documentation files created
- [ ] All changes use present-tense timeless language (per writing-standards.md)
- [ ] Zero redundancy introduced (consolidate, don't duplicate)
- [ ] Navigation improved (clearer feature discovery without scatter)

## Technical Design

### Architecture: Consolidation Strategy

**Principle**: Update existing files to reflect current state, remove historical markers, avoid creating new files.

**Three-Phase Approach**:

1. **Phase 1**: Update orchestration-best-practices.md to document formatting features (add 1 section ~100 lines)
2. **Phase 2**: Remove historical language from 5 files (search-replace pattern, ~30-50 edits total)
3. **Phase 3**: Consolidate progress marker documentation (move scattered mentions to centralized section)

**Files Modified** (3 total, all paths updated for Diataxis structure):
- `.claude/docs/guides/orchestration-best-practices.md` (add formatting section, remove historical language)
- `.claude/commands/coordinate.md` (remove historical language, reference guides/orchestration-best-practices.md)
- `.claude/docs/workflows/orchestration-guide.md` (remove historical language)

**Files NOT Modified**:
- Pattern files in concepts/patterns/ (workflow-scope-detection.md, verification-fallback.md, parallel-execution.md, behavioral-injection.md) - already correct per Diataxis reorganization
- reference/command_architecture_standards.md - defer historical language cleanup (not critical for formatting features)

**Diataxis Structure** (post-spec 509):
- **reference/** - Quick lookup (command-reference.md, agent-reference.md, etc.)
- **guides/** - How-to guides (orchestration-best-practices.md, troubleshooting, etc.)
- **concepts/** - Explanations (patterns/, hierarchical_agents.md, etc.)
- **workflows/** - Tutorials (orchestration-guide.md, adaptive-planning-guide.md, etc.)

## Implementation Phases

### Phase 1: Document Formatting Features in orchestration-best-practices.md
dependencies: []

**Objective**: Add comprehensive formatting section to orchestration-best-practices.md documenting all Plan 002 features

**Complexity**: Medium (requires synthesis of 6 features from Report 001)

**Tasks**:
- [ ] Read orchestration-best-practices.md current structure (file: /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md)
- [ ] Identify insertion point (after Phase 0-7 descriptions in Diataxis structure, likely after Phase 7 section)
- [ ] Add "Output Formatting and Context Management" section (~100-120 lines) documenting:
  - [ ] Library silence architecture (libraries calculate, commands communicate)
  - [ ] Workflow scope detection format (✓/✗ phase indicators, 8-12 lines)
  - [ ] Concise verification pattern (1-2 lines on success, verbose on failure)
  - [ ] Fail-fast philosophy (no fallbacks, diagnostic output, >95% success via proper invocation)
  - [ ] Progress markers (PROGRESS: [Phase N] format, parseable by external tools)
  - [ ] Two-tier summary (8-line default, detailed via COORDINATE_VERBOSE=true)
  - [ ] Context reduction metrics (50-60% overall, specific reductions by component)
- [ ] Add cross-references to pattern files using Diataxis paths (../concepts/patterns/workflow-scope-detection.md, ../concepts/patterns/verification-fallback.md)
- [ ] Use present-tense timeless language throughout (no "new", "now", "previously")
- [ ] Verify no duplication with existing sections

**Testing**:
```bash
# Verify section added and formatted correctly
grep -A 30 "Output Formatting and Context Management" /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md

# Check for historical language
grep -i "previously\|now \|new " /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md

# Verify cross-references valid (Diataxis structure)
grep -o "\\.\\./concepts/patterns/.*\\.md" /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md | while read path; do
  full_path="/home/benjamin/.config/.claude/docs/guides/$path"
  test -f "$full_path" || echo "Broken link: $path"
done
```

**Expected Duration**: 2-3 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (formatting section added, no historical language, valid cross-references)
- [ ] Git commit created: `feat(515): complete Phase 1 - Document formatting features in orchestration-best-practices.md`
- [ ] Update this plan file with phase completion status

### Phase 2: Remove Historical Language from Key Files
dependencies: [1]

**Objective**: Convert historical/temporal language to timeless present-tense descriptions in 3 high-impact files (Diataxis structure)

**Complexity**: Low (search-replace pattern, minimal risk)

**Tasks**:
- [ ] Read writing-standards.md for conversion patterns (file: /home/benjamin/.config/.claude/docs/concepts/writing-standards.md)
- [ ] Apply conversions to guides/orchestration-best-practices.md:
  - [ ] Search for "previously X, now Y" → replace with "Y"
  - [ ] Search for "the new approach" → replace with "the approach"
  - [ ] Search for "recently added" → replace with "available"
  - [ ] Estimate ~12 conversions based on Report 002 findings (may be fewer post-spec 509)
- [ ] Apply conversions to workflows/orchestration-guide.md:
  - [ ] Same pattern as orchestration-best-practices.md
  - [ ] Estimate ~18 conversions based on Report 002 findings (may be fewer post-spec 509)
- [ ] Apply conversions to commands/coordinate.md:
  - [ ] Remove any remaining "Optimization Note" sections if present (historical commentary)
  - [ ] Convert remaining temporal markers (~8 instances, may be fewer post-spec 509)
- [ ] Verify no functional content removed (only temporal markers/historical commentary)

**Note**: Spec 509 may have already removed some historical language during Diataxis reorganization. Verify current state before applying changes.

**Testing**:
```bash
# Check for remaining historical language in modified files (Diataxis paths)
echo "Checking guides/orchestration-best-practices.md:"
grep -n "previously\|now \|new \|recently\|latest\|old " "/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md" || echo "  ✓ Clean"

echo "Checking workflows/orchestration-guide.md:"
grep -n "previously\|now \|new \|recently\|latest\|old " "/home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md" || echo "  ✓ Clean"

echo "Checking commands/coordinate.md:"
grep -n "previously\|now \|new \|recently\|latest\|old " "/home/benjamin/.config/.claude/commands/coordinate.md" || echo "  ✓ Clean"

# Verify no functional sections removed (compare line counts before/after)
wc -l /home/benjamin/.config/.claude/commands/coordinate.md  # Should be ~1891 lines (current post-spec 510)
```

**Expected Duration**: 1-2 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (no historical language, line counts reasonable)
- [ ] Git commit created: `feat(515): complete Phase 2 - Remove historical language from orchestration docs`
- [ ] Update this plan file with phase completion status

### Phase 3: Consolidate Progress Marker Documentation
dependencies: [1]

**Objective**: Move scattered progress marker documentation into single authoritative section in orchestration-best-practices.md

**Complexity**: Low (consolidation, not creation)

**Tasks**:
- [ ] Identify progress marker mentions across Diataxis structure:
  - [ ] commands/coordinate.md (verify if still contains inline progress marker documentation)
  - [ ] reference/orchestration-reference.md (check if progress tracking section exists in Diataxis structure)
  - [ ] agents/research-specialist.md (if exists, check agent requirements for progress markers)
  - [ ] guides/logging-patterns.md (check for standardized format examples)
- [ ] Extract common patterns and consolidate into guides/orchestration-best-practices.md "Progress Markers" subsection
- [ ] Document in orchestration-best-practices.md:
  - [ ] Format specification (PROGRESS: [Phase N] - description)
  - [ ] When to emit (phase boundaries, verification checkpoints, completion)
  - [ ] External parsing examples (grep, awk patterns)
  - [ ] Integration with monitoring tools
- [ ] Update commands/coordinate.md to reference ../docs/guides/orchestration-best-practices.md for progress marker details (replace inline documentation with cross-reference)
- [ ] Update other files to reference guides/orchestration-best-practices.md (replace detailed examples with cross-reference)
- [ ] Keep guides/logging-patterns.md general mention (different focus: general logging, not orchestration-specific)

**Note**: Verify file locations in Diataxis structure before making changes. Some files may have been moved, renamed, or consolidated during spec 509.

**Testing**:
```bash
# Verify progress marker section added to guides/orchestration-best-practices.md
grep -A 20 "Progress Markers" /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md

# Verify coordinate.md now references orchestration-best-practices.md for details
grep "orchestration-best-practices" /home/benjamin/.config/.claude/commands/coordinate.md

# Count remaining progress marker mentions across Diataxis structure (should be consolidated)
grep -r "PROGRESS:" /home/benjamin/.config/.claude/docs/ /home/benjamin/.config/.claude/commands/ /home/benjamin/.config/.claude/agents/ 2>/dev/null | wc -l
# Note: Count may differ from original 25+ due to spec 509 reorganization
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (progress marker section consolidated, cross-references added)
- [ ] Git commit created: `feat(515): complete Phase 3 - Consolidate progress marker documentation`
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Integration Test: Documentation Completeness

**Objective**: Verify all Plan 002 formatting features documented and discoverable

**Test Procedure**:
```bash
# Test 1: Search for each formatting feature in orchestration-best-practices.md
features=(
  "library silence"
  "workflow scope detection"
  "concise verification"
  "fail-fast"
  "progress markers"
  "two-tier summary"
  "context reduction"
)

for feature in "${features[@]}"; do
  echo "Checking feature: $feature"
  grep -i "$feature" /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md >/dev/null && \
    echo "  ✓ Found" || \
    echo "  ✗ MISSING"
done

# Test 2: Verify historical language removed from key files
echo "Checking for historical language:"
grep -r "previously\|now \|new \|recently" \
  /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md \
  /home/benjamin/.config/.claude/docs/workflows/orchestration-guide.md \
  /home/benjamin/.config/.claude/commands/coordinate.md \
  2>&1 | grep -v "Binary" || echo "  ✓ Clean"

# Test 3: Verify progress marker consolidation
echo "Progress marker mentions after consolidation:"
grep -r "emit_progress\|PROGRESS:" /home/benjamin/.config/.claude/docs/ | wc -l
# Expected: ~3-5 mentions (orchestration-best-practices.md + logging-patterns.md + minimal references)
```

**Success Criteria**:
- [ ] All 7 formatting features documented in orchestration-best-practices.md
- [ ] Zero historical language markers in 3 key files
- [ ] Progress marker mentions reduced from 25+ to <5

### Regression Test: Navigation and Cross-References

**Objective**: Verify documentation navigation improved and all links valid

**Test Procedure**:
```bash
# Test 1: Verify cross-references in orchestration-best-practices.md
echo "Validating cross-references:"
grep -o "\\[.*\\](.*/.*\\.md)" /home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md | \
  sed 's/.*(\(.*\))/\1/' | \
  while read path; do
    full_path="/home/benjamin/.config/.claude/docs/$(echo $path | sed 's|^\\.\\./||')"
    test -f "$full_path" && echo "  ✓ $path" || echo "  ✗ BROKEN: $path"
  done

# Test 2: Verify pattern files still complete (not accidentally modified)
for pattern in workflow-scope-detection verification-fallback parallel-execution behavioral-injection; do
  lines=$(wc -l < "/home/benjamin/.config/.claude/docs/concepts/patterns/${pattern}.md")
  echo "$pattern.md: $lines lines"
  # Verify line count unchanged (pattern files should NOT be modified)
done
```

**Success Criteria**:
- [ ] All cross-references valid (no broken links)
- [ ] Pattern files unchanged (line counts match pre-implementation)
- [ ] Navigation clear (formatting features discoverable from orchestration-best-practices.md)

## Documentation Requirements

### Files Modified (Diataxis Structure)

1. **guides/orchestration-best-practices.md**:
   - Add "Output Formatting and Context Management" section (~100 lines)
   - Add "Progress Markers" subsection (~30 lines)
   - Remove historical language (~12 edits, may be fewer post-spec 509)
   - Add cross-references to pattern files using relative paths (../concepts/patterns/)

2. **commands/coordinate.md**:
   - Remove any remaining "Optimization Note" sections if present (historical commentary)
   - Convert temporal markers (~8 edits, may be fewer post-spec 509)
   - Add cross-reference to ../docs/guides/orchestration-best-practices.md for formatting details

3. **workflows/orchestration-guide.md**:
   - Convert temporal markers (~18 edits, may be fewer post-spec 509)
   - No structural changes

### Files NOT Created

- No new documentation files
- No new pattern files
- No new guide files
- Diataxis structure preserved (no new directories)

### Documentation Standards Applied

- Present-tense timeless language (per concepts/writing-standards.md)
- No historical commentary (per Development Philosophy section in CLAUDE.md)
- Cross-reference pattern files using Diataxis relative paths (don't duplicate content)
- Consolidate scattered mentions (reduce redundancy)
- Follow Diataxis framework (guides/ for how-to, concepts/ for explanations, workflows/ for tutorials)

## Dependencies

### External Dependencies

None (all changes to existing documentation)

### Internal Dependencies

- Plan 002 must be complete (formatting changes implemented in spec 510)
- Spec 509 Diataxis reorganization complete (affects all file paths)
- Research reports 001 and 002 provide authoritative feature list
- concepts/writing-standards.md defines conversion patterns for historical language

### File Dependencies

- guides/orchestration-best-practices.md exists in Diataxis structure and is editable
- Pattern files in concepts/patterns/ (workflow-scope-detection.md, verification-fallback.md) exist and are authoritative
- commands/coordinate.md exists (may have reduced historical commentary post-spec 509)
- workflows/orchestration-guide.md exists in Diataxis structure

## Constraints

### Hard Constraints

1. **No New Files**: Must work with existing documentation structure
2. **Minimal Changes**: Only update to reflect current state, no expansion
3. **Timeless Language**: All text must use present-tense (no temporal markers)
4. **Zero Redundancy**: Consolidate, don't duplicate information

### Soft Constraints

1. **Readability**: Changes should improve clarity and scannability
2. **Navigation**: Cross-references should be clear and complete
3. **Completeness**: All Plan 002 features must be documented somewhere

## Risk Assessment

### Risk 1: Accidentally Modifying Pattern Files

**Probability**: Low
**Impact**: Medium (would break single-source-of-truth principle)

**Mitigation**:
- Explicitly list pattern files as "DO NOT MODIFY" in each phase
- Verify pattern file line counts unchanged in regression tests
- Cross-reference pattern files, don't duplicate content

### Risk 2: Introducing New Redundancy

**Probability**: Medium
**Impact**: Low (defeats purpose of consolidation)

**Mitigation**:
- Before adding content to orchestration-best-practices.md, search for existing mentions
- Remove scattered mentions when consolidating (Phase 3)
- Verify progress marker mentions reduced (not increased) in testing

### Risk 3: Breaking Cross-References

**Probability**: Low
**Impact**: Medium (broken navigation)

**Mitigation**:
- Validate all cross-references after each phase
- Use relative paths (../patterns/file.md) for portability
- Test cross-reference resolution in regression tests

## Complexity Calculation

```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
      = (13 × 1.0) + (3 × 5.0) + (5 × 0.5) + (1 × 2.0)
      = 13 + 15 + 2.5 + 2
      = 32.5

Adjusted Score (documentation overhead): 32.5 × 1.1 = 35.75
```

**Complexity Band**: Medium (50-200 range, but on lower end)
**Structure Level**: 0 (single file plan, appropriate for scope)

**Note**: Complexity score suggests expansion, but per constraints, maintaining Level 0 structure. If implementation reveals higher complexity than estimated, consider using `/expand-phase` during execution.

## Implementation Notes

### Phase Sequencing

- **Phase 1 first**: Establish authoritative formatting documentation before consolidation
- **Phase 2 parallel with Phase 1**: Can remove historical language while adding formatting section
- **Phase 3 after Phase 1**: Requires authoritative section to exist before consolidating references

### Tools and Techniques

- **Search-Replace**: Use Edit tool for historical language conversions
- **Read-Analyze-Write**: For adding new sections to orchestration-best-practices.md
- **Grep-Validate**: For testing cross-references and detecting remaining issues

### Quality Checks

- After each phase: Run grep checks for historical language
- After Phase 1: Verify all 7 features documented
- After Phase 3: Verify progress marker mentions reduced
- Final: Run complete regression test suite

## Revision History

### 2025-10-29 - Revision 1: Diataxis Structure Update

**Changes**: Updated all file paths and references to reflect spec 509 Diataxis reorganization
**Reason**: Spec 509 reorganized documentation into reference/, guides/, concepts/, workflows/ structure between plan creation and execution
**Modified Sections**:
- Overview: Added note about Diataxis structure and spec 509 completion
- Technical Design: Updated file paths to Diataxis structure
- All phases: Updated file paths and added verification notes about post-spec 509 state
- Testing: Updated grep patterns for Diataxis paths
- Documentation Requirements: Updated file paths and added Diataxis framework note
- Dependencies: Added spec 509 as dependency

**Impact**: Plan now correctly references current documentation structure. Historical language removal may find fewer instances than originally estimated since spec 509 may have already cleaned some temporal markers.

### 2025-10-29 - Initial Plan Creation

**Context**: Created by plan-architect agent based on research reports 001 and 002
**Constraints Applied**: Minimal changes, no new files, timeless language, zero redundancy
**Approach**: Consolidate into existing orchestration-best-practices.md, remove historical language, cross-reference pattern files
