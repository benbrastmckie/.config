# Implementation Plan: .claude/ Documentation Refactor

## Metadata
- **Date**: 2025-10-21
- **Feature**: Complete documentation refactor for .claude/ directory (excluding .claude/docs/)
- **Scope**: Fix broken links, update counts, improve cross-linking, standardize README structure
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: User-provided research findings

## Overview

Complete refactor of all README.md files in .claude/ directory to ensure accuracy, consistency, and proper cross-referencing. Based on comprehensive audit findings identifying broken links, count mismatches, cross-linking gaps, and structural inconsistencies.

### Research Findings Summary

**Coverage**: 18 READMEs covering all major subdirectories

**Critical Issues Identified**:
1. **Broken Links** (6 missing files):
   - template-system-guide.md
   - architecture.md
   - creating-commands.md
   - checkpoints/README.md
   - command-standards-flow.md

2. **Count Mismatches** (3 major discrepancies):
   - Commands: Claims 25 → Actual 21
   - lib: Claims 30 → Actual 58
   - shared docs: Claims 9 → Actual 19

3. **Missing Documentation**:
   - Individual command/agent files lack inline docs
   - Wrapper files documented but consolidated versions exist

4. **Cross-Linking Gaps**:
   - lib/templates READMEs missing parent links
   - commands/shared/README.md not linked from commands/README.md

**Organization Issues**:
- Inconsistent section ordering/TOC depth
- Mixed navigation placement (top vs bottom)
- Varying styles (tutorial vs reference)
- Missing standard sections

## Success Criteria

- [ ] All broken links resolved (removed or targets created)
- [ ] All file/directory counts accurate
- [ ] Bidirectional cross-references established
- [ ] Consistent README structure across all subdirectories
- [ ] All subdirectories have complete README files
- [ ] Duplicate .claude/.claude/ directory investigated and resolved
- [ ] Navigation links validate successfully

## Technical Design

### 3-Tier README Standardization

**Tier 1: Overview READMEs** (.claude/README.md)
- Purpose and capabilities summary
- High-level directory structure
- Quick start examples
- Navigation to tier 2 READMEs

**Tier 2: Domain READMEs** (commands/, agents/, lib/, etc.)
- Detailed subdirectory documentation
- Complete file inventories
- Usage examples and patterns
- Links to tier 1 (parent) and tier 3 (children)

**Tier 3: Infrastructure READMEs** (commands/shared/, agents/shared/, data/*, etc.)
- Specific subsystem documentation
- File-by-file descriptions
- Links to tier 2 (parent)

### Standard README Sections

All READMEs will include (in this order):
1. **Title and Purpose** - Clear, concise role description
2. **Table of Contents** (if >5 sections)
3. **Overview/Summary** - Key capabilities and features
4. **Structure/Organization** - Directory/file layout
5. **Documentation** - Individual file/module descriptions
6. **Usage Examples** (where applicable)
7. **Integration** - How it connects to other parts
8. **Navigation** - Links to parent and child READMEs

### Link Resolution Strategy

**Broken Links Resolution**:
- Remove links to non-existent files in .claude/docs/
- Update references to reflect actual documentation structure
- Consolidate redundant documentation where appropriate

**Count Accuracy**:
- Validate counts with actual file listings
- Use scripted verification where possible
- Document count methodology (e.g., "active files", "non-wrapper files")

## Implementation Phases

### Phase 1: Investigation and Validation [COMPLETED]
**Objective**: Identify all issues, validate research findings, establish baseline
**Complexity**: Low

Tasks:
- [x] Investigate duplicate .claude/.claude/ directory
  - Check if symlink, nested directory, or artifact
  - Document findings and removal plan
- [x] Validate all 6 broken links identified in research
  - Confirm files do not exist
  - Check if moved/renamed vs never created
  - Document which links to remove vs redirect
- [x] Count verification for all major directories
  - commands/: Verify actual count (research: 21 vs claimed 25) = 21 ✓
  - lib/: Verify actual count (research: 58 vs claimed 30) = 58 ✓
  - commands/shared/: Verify actual count (research: 19 vs claimed 9) = 19 ✓
  - agents/: Verify agent count = 20
  - templates/: Verify template count = 24
- [x] Create validation script for future count accuracy
  - Script location: .claude/scripts/validate-readme-counts.sh
  - Validates counts in all READMEs against actual directories
  - Returns list of mismatches

Testing:
```bash
# Verify broken links
grep -r "docs/template-system-guide.md" .claude/
grep -r "docs/architecture.md" .claude/
grep -r "docs/creating-commands.md" .claude/
grep -r "checkpoints/README.md" .claude/
grep -r "docs/command-standards-flow.md" .claude/

# Count validation
ls -1 .claude/commands/*.md | wc -l
ls -1 .claude/lib/*.sh | wc -l
ls -1 .claude/commands/shared/*.md | wc -l

# Check duplicate directory
ls -la .claude/.claude/ 2>/dev/null || echo "Does not exist"
file .claude/.claude 2>/dev/null
```

Validation:
- All broken links documented with resolution plan
- All count mismatches verified
- Duplicate directory status determined
- Validation script functional

---

### Phase 2: Critical Fixes (Broken Links and Counts) [COMPLETED]
**Objective**: Fix all broken links and update counts to accurate values
**Complexity**: Medium

Tasks:
- [x] Fix broken links in .claude/README.md
  - Remove or redirect: docs/template-system-guide.md reference ✓
  - Remove or redirect: docs/architecture.md reference ✓
  - Update checkpoints/README.md reference (if moved to data/checkpoints/) ✓
- [x] Fix broken links in .claude/commands/README.md
  - Remove or redirect: docs/creating-commands.md reference ✓
  - Remove or redirect: docs/command-standards-flow.md reference ✓
  - Update architecture.md reference ✓
- [x] Update command count in .claude/commands/README.md
  - Update "Current Command Count: 25" to actual count (21) ✓
  - Document methodology (e.g., "21 active commands + 1 deprecated") ✓
  - Verify with: ls -1 .claude/commands/*.md | wc -l ✓
- [x] Update lib count in .claude/lib/README.md
  - Update "30 modular utility libraries" to actual count (58) ✓
  - Break down by category if needed (not needed)
  - Verify with: ls -1 .claude/lib/*.sh | wc -l ✓
- [x] Update shared docs count in .claude/commands/README.md
  - Verified actual count is 19, matches research findings ✓
  - No update needed (list shows 9 specific files, not a total count claim)
  - Verify with: ls -1 .claude/commands/shared/*.md | wc -l ✓
- [x] Remove duplicate .claude/.claude/ directory if confirmed as artifact
  - Backup contents if any ✓ (backed up to /tmp)
  - Remove directory ✓
  - Verify no references remain in docs ✓

Testing:
```bash
# Verify no broken links remain
.claude/scripts/validate-readme-counts.sh

# Verify counts are accurate
diff <(grep -o "Current Command Count: [0-9]*" .claude/commands/README.md) \
     <(echo "Current Command Count: $(ls -1 .claude/commands/*.md | wc -l)")

# Verify duplicate directory removed
[ ! -d .claude/.claude ] && echo "PASS" || echo "FAIL"
```

Validation:
- No broken links in any README
- All counts match actual file listings
- Duplicate directory removed
- All links validate successfully

---

### Phase 3: Cross-Reference Enhancement
**Objective**: Establish bidirectional cross-references throughout documentation
**Complexity**: Medium

Tasks:
- [ ] Add parent links to .claude/lib/README.md
  - Add "Navigation" section if missing
  - Link to parent: [← .claude/](../README.md)
- [ ] Add parent links to .claude/templates/README.md
  - Add "Navigation" section if missing
  - Link to parent: [← .claude/](../README.md)
- [ ] Link commands/shared/README.md from commands/README.md
  - Add to "Shared Documentation Files Created" section
  - Format: [commands/shared/README.md](shared/README.md) - Shared documentation index
- [ ] Establish bidirectional links for all tier 2 ↔ tier 3 READMEs
  - agents/ ↔ agents/shared/
  - agents/ ↔ agents/prompts/
  - data/ ↔ data/checkpoints/, data/logs/, data/metrics/, data/registry/
  - specs/ ↔ specs/artifacts/
- [ ] Add cross-references between related subsystems
  - commands/README.md → agents/README.md (agents used by commands)
  - agents/README.md → commands/README.md (commands that invoke agents)
  - lib/README.md → commands/README.md (commands using utilities)
  - templates/README.md → commands/README.md (/plan-from-template command)
- [ ] Verify all "See Also" sections are comprehensive
  - Check each README for "See Also" or "Related" section
  - Add missing cross-references
  - Ensure logical grouping

Testing:
```bash
# Verify bidirectional links
# Check that parent links exist in child READMEs
grep -l "← .claude/" .claude/*/README.md

# Verify cross-references
grep -A5 "See Also" .claude/README.md
grep -A5 "Navigation" .claude/commands/README.md

# Validate all markdown links
find .claude -name "README.md" -not -path "*/docs/*" -exec \
  markdown-link-check {} \; 2>&1 | grep -E "(✖|FILE)"
```

Validation:
- All tier 2 READMEs link to tier 1 parent
- All tier 3 READMEs link to tier 2 parent
- commands/shared/ linked from commands/README.md
- All related subsystems cross-referenced
- No broken internal links

---

### Phase 4: Structural Standardization
**Objective**: Standardize README structure across all 18 README files
**Complexity**: High

Tasks:
- [ ] Standardize .claude/README.md (tier 1)
  - Sections: Purpose, Directory Structure, Directory Roles, Core Capabilities, Configuration, Quick Reference, Navigation
  - Move all role descriptions to "Directory Roles" section (already done)
  - Ensure consistent formatting
- [ ] Standardize tier 2 READMEs (8 files)
  - commands/README.md: Purpose, Available Commands, Command Types, Standards Discovery, Best Practices, Navigation
  - agents/README.md: Purpose, Available Agents, Agent Types, Invocation Patterns, Navigation
  - lib/README.md: Purpose, Module Organization, Core Modules, Dependencies, Usage Guidelines, Navigation
  - templates/README.md: Purpose, Template Categories, Template Structure, Usage, Navigation
  - hooks/README.md: Purpose, Available Hooks, Hook Events, Configuration, Navigation
  - specs/README.md: Purpose, Directory Structure, Artifact Types, Workflow, Navigation
  - tests/README.md: Purpose, Test Categories, Running Tests, Coverage, Navigation
  - tts/README.md: Purpose, Components, Configuration, Usage, Navigation
- [ ] Standardize tier 3 READMEs (9 files)
  - commands/shared/README.md: Purpose, Shared Files, Usage, Navigation
  - agents/shared/README.md: Purpose, Protocols, Usage, Navigation
  - agents/prompts/README.md: Purpose, Prompt Templates, Usage, Navigation
  - data/README.md: Purpose, Subdirectories, Data Lifecycle, Navigation
  - data/checkpoints/README.md: Purpose, Checkpoint Schema, Usage, Navigation
  - data/logs/README.md: Purpose, Log Types, Rotation, Navigation
  - data/metrics/README.md: Purpose, Metrics Format, Analysis, Navigation
  - data/registry/README.md: Purpose, Registry Schema, Operations, Navigation
  - specs/artifacts/README.md: Purpose, Artifact Types, Lifecycle, Navigation
- [ ] Ensure consistent navigation placement
  - All READMEs: Navigation section at bottom (after main content)
  - Format: Parent link, Related links, Child links
- [ ] Standardize section ordering across all READMEs
  - 1. Title and Purpose
  - 2. Overview/Recent Changes (if applicable)
  - 3. Main Content (structure varies by tier)
  - 4. Usage/Integration (if applicable)
  - 5. Navigation (always last)
- [ ] Add TOC to READMEs with >5 major sections
  - .claude/README.md (already has TOC via Directory Structure)
  - commands/README.md (needs TOC)
  - lib/README.md (already has TOC)
  - specs/README.md (may need TOC)

Testing:
```bash
# Verify section presence
for readme in .claude/README.md .claude/*/README.md; do
  echo "Checking $readme"
  grep -q "## Purpose" "$readme" || echo "  Missing: Purpose"
  grep -q "## Navigation" "$readme" || echo "  Missing: Navigation"
done

# Verify navigation section placement (should be last)
for readme in $(find .claude -name "README.md" -not -path "*/docs/*"); do
  LAST_SECTION=$(grep "^## " "$readme" | tail -1)
  echo "$readme: $LAST_SECTION"
done | grep -v "## Navigation"
```

Validation:
- All READMEs follow tier-appropriate structure
- All READMEs have Purpose and Navigation sections
- Navigation sections consistently at bottom
- TOCs added where needed
- Consistent section ordering

---

### Phase 5: Final Validation and Documentation
**Objective**: Validate all changes and update master documentation
**Complexity**: Low

Tasks:
- [ ] Run comprehensive validation checks
  - Execute .claude/scripts/validate-readme-counts.sh
  - Check all markdown links
  - Verify no TODO or FIXME markers remain
- [ ] Update CLAUDE.md if needed
  - Verify documentation_policy section is current
  - Add reference to validation script if helpful
- [ ] Create documentation summary
  - File: .claude/specs/summaries/079_docs_refactor_summary.md
  - Document all changes made
  - List all READMEs updated (18 files)
  - Record validation script location
- [ ] Verify Neovim picker integration still works
  - Test: <leader>ac in Neovim
  - Verify all categories load correctly
  - Check README previews render properly
- [ ] Create before/after comparison
  - Document count fixes (3 major corrections)
  - Document broken link removals (6 links fixed)
  - Document cross-reference additions (~15-20 new links)
  - Document structural improvements (18 READMEs standardized)

Testing:
```bash
# Comprehensive validation
.claude/scripts/validate-readme-counts.sh > /tmp/validation_results.txt
cat /tmp/validation_results.txt

# Link validation
find .claude -name "README.md" -not -path "*/docs/*" | while read f; do
  echo "Validating $f"
  # Check for broken internal links (basic check)
  grep -o "\[.*\](.*\.md)" "$f" | while read link; do
    target=$(echo "$link" | sed 's/.*(\(.*\))/\1/')
    dir=$(dirname "$f")
    [ -f "$dir/$target" ] || echo "BROKEN: $f -> $target"
  done
done

# Check for incomplete sections
grep -r "TODO\|FIXME\|XXX" .claude/*/README.md .claude/README.md

# Verify navigation section exists in all
find .claude -name "README.md" -not -path "*/docs/*" -exec \
  sh -c 'grep -q "## Navigation" "$1" || echo "Missing navigation: $1"' _ {} \;
```

Validation:
- Validation script passes with 0 errors
- No broken links
- No TODO/FIXME markers
- All READMEs have Navigation section
- Summary document created
- Neovim picker functional

---

## Testing Strategy

### Automated Validation

**Script**: .claude/scripts/validate-readme-counts.sh
- Checks all count claims against actual file counts
- Validates all internal links
- Reports mismatches and broken references

**Usage**:
```bash
# Run validation
.claude/scripts/validate-readme-counts.sh

# Expected output (after fixes):
# ✓ commands/README.md: Count accurate (21 files)
# ✓ lib/README.md: Count accurate (58 files)
# ✓ All internal links valid
# ✓ All README files have Navigation section
```

### Manual Validation

**Navigation Test**:
- Start at .claude/README.md
- Follow links through all tiers
- Verify can reach all READMEs via links alone
- Verify can navigate back to root from any README

**Consistency Test**:
- Compare section ordering across similar READMEs
- Verify tier 2 READMEs have similar structure
- Verify tier 3 READMEs have similar structure

### Integration Test

**Neovim Picker**:
- Open picker with `<leader>ac`
- Navigate through all categories
- Verify README previews load correctly
- Test cross-references by following links in preview

## Documentation Requirements

### Files to Create

1. **.claude/scripts/validate-readme-counts.sh**
   - Automated validation script
   - Checks counts, links, required sections
   - Exits 0 on success, 1 on failure

2. **.claude/specs/summaries/079_docs_refactor_summary.md**
   - Implementation summary
   - Before/after statistics
   - List of all changes

### Files to Update

All 18 existing README files in .claude/ (excluding .claude/docs/):
1. .claude/README.md
2. .claude/agents/README.md
3. .claude/agents/prompts/README.md
4. .claude/agents/shared/README.md
5. .claude/commands/README.md
6. .claude/commands/shared/README.md
7. .claude/data/README.md
8. .claude/data/checkpoints/README.md
9. .claude/data/logs/README.md
10. .claude/data/metrics/README.md
11. .claude/data/registry/README.md
12. .claude/examples/README.md
13. .claude/hooks/README.md
14. .claude/lib/README.md
15. .claude/scripts/README.md
16. .claude/specs/README.md
17. .claude/specs/artifacts/README.md
18. .claude/templates/README.md
19. .claude/tests/README.md
20. .claude/tts/README.md
21. .claude/utils/README.md

## Dependencies

### External Dependencies
- None (pure documentation work)

### Internal Dependencies
- Requires accurate file/directory listings
- Validation script requires bash, grep, find

## Risk Assessment

### Low Risk
- Pure documentation changes
- No code modifications
- No breaking changes to functionality
- Easy to revert via git

### Potential Issues

**Risk**: Over-standardization removes unique value from individual READMEs
**Mitigation**: Preserve domain-specific content while standardizing structure only

**Risk**: Validation script may have false positives
**Mitigation**: Manual review of validation results, iterative script refinement

**Risk**: Count methodology may vary (e.g., include vs exclude deprecated files)
**Mitigation**: Document count methodology clearly in each README

## Notes

### Research Report Integration

This plan incorporates findings from user-provided research:
- 6 broken links identified and documented for removal
- 3 count mismatches verified and corrected
- Cross-linking gaps addressed in Phase 3
- Structural inconsistencies resolved in Phase 4

### 3-Tier Architecture

The standardization follows a clear hierarchy:
- **Tier 1** (.claude/README.md): High-level overview
- **Tier 2** (domain READMEs): Detailed subdirectory docs
- **Tier 3** (infrastructure READMEs): Specific subsystem docs

This ensures navigation clarity and appropriate detail at each level.

### Validation Script

The validation script created in Phase 1 becomes a permanent tool for maintaining documentation accuracy. Future README updates can be validated automatically.

### Backward Compatibility

All changes maintain backward compatibility:
- Broken links removed don't affect functionality
- Count updates reflect reality, don't change behavior
- Structural standardization preserves all information
