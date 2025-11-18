# Clean-Break Revision Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Plan revision insights for clean-break archival approach
- **Report Type**: plan revision analysis

## Executive Summary

The existing plan (001_complete_archival_discrepancies_plan.md) uses an "archive-and-preserve" approach that contradicts the project's clean-break philosophy documented in writing-standards.md. The plan must be revised to REMOVE all references to archived commands rather than marking them as "ARCHIVED" with replacement notices. This aligns with the project's core value that documentation should describe only the current state as if archived features never existed.

## Findings

### Clean-Break Philosophy Analysis

The writing-standards.md file (lines 23-45) establishes clear guidelines for clean-break refactors:

1. **Prioritize coherence over compatibility** (line 25): Clean, well-designed refactors are preferred over maintaining backward compatibility
2. **No legacy burden** (line 27): Don't compromise current design to support old formats or deprecated patterns
3. **Migration is acceptable** (line 28): Breaking changes are acceptable when they improve system quality

### Documentation Standards Violations in Current Plan

The current plan violates multiple writing standards:

1. **Banned Temporal Markers** (lines 78-105 of writing-standards.md):
   - Plan proposes using "ARCHIVED" markers - this is explicitly banned
   - "(Deprecated)" and "(Legacy)" are listed as banned labels

2. **Banned Migration Language** (lines 140-166 of writing-standards.md):
   - Plan proposes "Replacement: Use `/replacement-command` instead" - this is migration language
   - "replaces the old" and "instead of the previous" are banned phrases

3. **Core Principle Violation** (lines 49-57 of writing-standards.md):
   - Documentation should read as if the current implementation always existed
   - No migration guides or compatibility documentation for refactors

### Specific Plan Sections Requiring Revision

#### Success Criteria (lines 35-43)
Current plan lists WRONG success criteria:
- "marked as ARCHIVED with /build replacement" - Should be: "removed from documentation"
- "Navigation section updated to remove archived command links" - Correct but incomplete

#### Technical Design Section (lines 47-63)
Current pattern is WRONG:
```markdown
#### /command-name - ARCHIVED
**Replacement**: Use `/replacement-command` instead
**Archive Location**: `.claude/archive/...`
```

Clean-break pattern should be: **Complete removal** - no section at all

#### Phase 2 Tasks (lines 96-134)
All tasks use wrong approach:
- "Add 'ARCHIVED' marker to heading" - Should be: "Remove entire section"
- "Replace full documentation with brief note pointing to /build" - Should be: "Delete section entirely"
- "Add archive location reference" - Should be: "No reference needed"

#### Testing Commands (lines 136-146)
Current tests verify wrong outcomes:
```bash
# Verify all 5 commands are marked ARCHIVED
grep -c "ARCHIVED" /home/benjamin/.config/.claude/commands/README.md
```

Should verify:
```bash
# Verify archived commands are completely absent
grep -E "/implement|/plan|/debug|/research|/revise" /home/benjamin/.config/.claude/commands/README.md
# Expected: 0 matches for these specific command sections
```

### commands/README.md Analysis

The current README.md has multiple clean-break violations that extend beyond the archived commands:

#### Historical Sections to Remove (lines 25-91)
The following sections violate clean-break philosophy entirely:
- "Command Cleanup (2025-11-15)" (lines 25-32) - Contains temporal markers and migration notes
- "Command Consolidation (2025-10-10)" (lines 34-41) - Contains deprecated notices and "Why" explanations
- "Command Consolidation (2025-10-06)" (lines 43-47) - Migration guidance
- "Shared Utilities Integration (2025-10-06)" (lines 49-55) - Temporal reference
- "Phase 7 Modularization (2025-10-15)" (lines 57-91) - Historical commentary with metrics

These sections should be entirely removed as they document changes rather than current state.

#### Command Sections to Remove
Based on grep analysis, these command sections must be completely removed:
- `/implement` (lines 137-149): Full section removal
- `/plan` (lines 153-165): Full section removal
- `/research` (lines 186-206): Full section removal
- `/debug` (lines 237-248): Full section removal
- `/revise` (lines 325-337): Full section removal

#### References to Update or Remove
Lines containing references to archived commands in examples/usage:
- Line 520: Remove /implement, /plan, /research from lists
- Line 524: Remove /debug from lists
- Line 528: Remove /revise from lists
- Lines 567-571: Remove mentions of /plan, /implement, /revise in structure descriptions
- Lines 816-870: Remove example workflows using archived commands

### What the Clean-Break Approach Requires

Based on writing-standards.md analysis:

1. **Complete Section Removal**: Remove entire sections for /implement, /plan, /debug, /research, /revise from commands/README.md
2. **No Replacement Notes**: Do not add any "use X instead" guidance
3. **No Archive References**: Do not mention archive locations
4. **Remove Historical Commentary**: Delete all date-labeled sections (2025-10-06, 2025-10-10, 2025-10-15, 2025-11-15)
5. **Accurate Count**: Update command count to 12 (remains correct)
6. **Clean Navigation**: Remove archived command links from navigation section
7. **Update Examples**: Remove or replace examples that reference archived commands
8. **Present-Focus**: Documentation should describe only the 12 active commands as if they always existed

## Recommendations

### 1. Revise Plan Success Criteria

Replace all "mark as ARCHIVED" criteria with "remove from documentation":

**Before**:
```markdown
- [ ] commands/README.md /implement section marked as ARCHIVED with /build replacement
```

**After**:
```markdown
- [ ] commands/README.md /implement section completely removed
- [ ] No remaining references to /implement in any section
```

### 2. Restructure Phase 2 Tasks

Change from "archive-and-mark" to "clean removal" approach:

**Before**:
```markdown
- [ ] Update /implement section (lines 137-149) to ARCHIVED format
  - Add "ARCHIVED" marker to heading
  - Replace full documentation with brief note pointing to /build
  - Add archive location reference
```

**After**:
```markdown
- [ ] Remove /implement section (lines 137-149) entirely
  - Delete complete section from heading to next command
  - Remove any navigation links to this section
  - Update any cross-references in other sections
```

### 3. Add New Phase: Remove Historical Commentary

Add a phase to remove all date-labeled historical sections:

```markdown
### Phase 1.5: Remove Historical Commentary
dependencies: []

**Objective**: Remove all date-labeled historical commentary sections

**Tasks**:
- [ ] Remove "Command Cleanup (2025-11-15)" section (lines 25-32)
- [ ] Remove "Command Consolidation (2025-10-10)" section (lines 34-41)
- [ ] Remove "Command Consolidation (2025-10-06)" section (lines 43-47)
- [ ] Remove "Shared Utilities Integration (2025-10-06)" section (lines 49-55)
- [ ] Remove "Phase 7 Modularization (2025-10-15)" section (lines 57-91)
```

### 4. Revise Testing Strategy

Replace tests that verify ARCHIVED markers with tests that verify complete removal:

**Before**:
```bash
grep -c "ARCHIVED" /home/benjamin/.config/.claude/commands/README.md
```

**After**:
```bash
# Verify no archived command sections exist
for cmd in implement plan debug research revise; do
  if grep -q "^#### /$cmd$" /home/benjamin/.config/.claude/commands/README.md; then
    echo "ERROR: /$cmd section still exists"
    exit 1
  fi
done

# Verify no historical date markers
grep -c "2025-10-0\|2025-10-1\|2025-11-" /home/benjamin/.config/.claude/commands/README.md
# Expected: 0 (only metadata dates allowed)
```

### 5. Update Plan Overview

Change the plan's stated approach from archival marking to clean removal:

**Before**:
```markdown
This plan focuses ONLY on completing the archival.
```

**After**:
```markdown
This plan focuses on clean-break removal of archived command documentation following the project's timeless writing standards.
```

### 6. Consider Scope Expansion

The clean-break approach reveals that the README.md needs more extensive cleanup than originally scoped. Consider whether to:
- Expand the plan scope to include historical section removal
- Create a separate plan for README.md cleanup
- Combine into a single comprehensive documentation cleanup

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/specs/764_i_just_finished_implementing_home_benjamin_config_/plans/001_complete_archival_discrepancies_plan.md` (lines 1-287)
- `/home/benjamin/.config/.claude/docs/concepts/writing-standards.md` (lines 1-558)
- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-100, grep analysis of full file)

### Key Source Lines
- writing-standards.md:23-45 - Clean-break philosophy
- writing-standards.md:49-57 - Present-focused writing standards
- writing-standards.md:78-105 - Banned temporal markers
- writing-standards.md:140-166 - Banned migration language
- 001_complete_archival_discrepancies_plan.md:35-43 - Success criteria to revise
- 001_complete_archival_discrepancies_plan.md:47-63 - Technical design to change
- 001_complete_archival_discrepancies_plan.md:96-134 - Phase 2 tasks to revise
- commands/README.md:25-91 - Historical sections to remove
- commands/README.md:137-337 - Command sections to remove
