# Complete Archival Discrepancies Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Complete archival of legacy workflow commands documentation
- **Scope**: Fix 2 remaining discrepancies in commands/README.md and command-reference.md using clean-break approach
- **Estimated Phases**: 4
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 16.5
- **Research Reports**:
  - [Archival Completion Research](../reports/001_archival_completion_research.md)
  - [Clean-Break Revision Research](../reports/002_clean_break_revision_research.md)

## Overview

The archival of 5 legacy workflow commands (debug.md, implement.md, plan.md, research.md, revise.md) is functionally complete. Two documentation discrepancies require remediation using the clean-break approach:

1. **commands/README.md** - Still documents archived commands as active (HIGH priority)
2. **command-reference.md agent section** - References phantom agents that were never created (MEDIUM priority)

This plan follows the project's clean-break philosophy from writing-standards.md: documentation should describe only the current state as if archived features never existed. No "ARCHIVED" markers, no migration notes, no historical commentary - complete removal only.

## Research Summary

Key findings from the research reports:

**From archival completion research**:
- commands/README.md documents 19 commands when only 12 are active
- 5 archived command sections need removal: /implement, /plan, /debug, /research, /revise
- command-reference.md has phantom agent references (code-writer, test-specialist, doc-writer) that were never implemented

**From clean-break revision research**:
- Project's writing-standards.md requires complete removal, not archival marking
- "ARCHIVED" markers, "Replacement" notes, and archive location references are banned
- Documentation should read as if only the 12 active commands ever existed
- Historical commentary sections with dates should also be removed

## Success Criteria

- [ ] commands/README.md command count updated from 19 to 12
- [ ] commands/README.md /implement section completely removed
- [ ] commands/README.md /plan section completely removed
- [ ] commands/README.md /debug section completely removed
- [ ] commands/README.md /research section completely removed
- [ ] commands/README.md /revise section completely removed
- [ ] commands/README.md Navigation section contains no links to archived commands
- [ ] command-reference.md agent section has no phantom agent references (code-writer, test-specialist, doc-writer removed)
- [ ] No remaining references to archived commands anywhere in documentation
- [ ] Documentation reads as if only the 12 active commands exist

## Technical Design

### Approach
Apply clean-break removal pattern following writing-standards.md:
- Completely remove archived command sections (no "ARCHIVED" markers)
- Remove phantom agent references entirely (no replacement references)
- Update counts to reflect actual state
- Remove all navigation links to archived commands

### Clean-Break Pattern
For each archived command, the entire section is deleted. No trace remains:
- No heading
- No replacement notes
- No archive location references
- No migration guidance

### Agent Section Updates
Remove phantom agent entries (code-writer, test-specialist, doc-writer) entirely from command-reference.md. These agents were never created, so their references should not exist in documentation.

## Implementation Phases

### Phase 1: Update commands/README.md Command Count
dependencies: []

**Objective**: Update the command count to reflect only active commands

**Complexity**: Low

**Tasks**:
- [ ] Read commands/README.md current content
- [ ] Update line 5: Change "19 active commands" to "12 active commands"
- [ ] Verify the count matches actual active commands in directory

**Testing**:
```bash
# Verify command count is now 12
grep -n "active commands" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 15 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(764): complete Phase 1 - Update Command Count`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Remove Archived Command Sections from commands/README.md
dependencies: [1]

**Objective**: Completely remove all 5 archived command sections and their navigation links

**Complexity**: Medium

**Tasks**:
- [ ] Remove /implement section (lines 137-149) entirely
  - Delete complete section from heading to next command
  - Leave no trace of this command in the file
- [ ] Remove /plan section (lines 152-165) entirely
  - Delete complete section from heading to next command
  - Leave no trace of this command in the file
- [ ] Remove /research section (lines 186-206) entirely
  - Delete complete section from heading to next command
  - Leave no trace of this command in the file
- [ ] Remove /debug section (lines 237-248) entirely
  - Delete complete section from heading to next command
  - Leave no trace of this command in the file
- [ ] Remove /revise section (lines 325-337) entirely
  - Delete complete section from heading to next command
  - Leave no trace of this command in the file

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update Navigation section to remove archived command links
  - Remove: debug.md, implement.md, plan.md, research.md, revise.md
  - Ensure remaining links are accurate
- [ ] Update Command Types sections to remove archived commands from all lists
  - Remove /implement, /plan, /research from workflow command lists
  - Remove /debug from debugging command lists
  - Remove /revise from revision command lists

**Testing**:
```bash
# Verify archived command sections are completely absent
for cmd in implement plan debug research revise; do
  if grep -q "^#### /$cmd$" /home/benjamin/.config/.claude/commands/README.md; then
    echo "ERROR: /$cmd section still exists"
    exit 1
  fi
done

# Verify no archived command links in Navigation
grep -A30 "## Navigation" /home/benjamin/.config/.claude/commands/README.md | grep -E "(debug\.md|implement\.md|plan\.md|research\.md|revise\.md)"
# Expected: 0 matches
```

**Expected Duration**: 45 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(764): complete Phase 2 - Remove Archived Command Sections`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Remove Phantom Agent References from command-reference.md
dependencies: [1]

**Objective**: Remove phantom agent references that were never implemented

**Complexity**: Low

**Tasks**:
- [ ] Read command-reference.md agent section (lines 600-647)
- [ ] Remove code-writer section (lines 614-618) entirely
  - This agent was never created
  - Delete the entire section, leaving no trace
- [ ] Remove test-specialist section (lines 619-624) entirely
  - This agent was never created
  - Delete the entire section, leaving no trace
- [ ] Remove doc-writer section (lines 630-633) entirely
  - This agent was never created
  - Delete the entire section, leaving no trace
- [ ] Verify remaining agent references align with actual agents in agents/ directory

**Testing**:
```bash
# Verify phantom agent references are completely removed
grep -E "(code-writer|test-specialist|doc-writer)" /home/benjamin/.config/.claude/docs/reference/command-reference.md
# Expected: 0 matches

# List actual agents for verification
ls /home/benjamin/.config/.claude/agents/*.md | xargs -I {} basename {} .md
```

**Expected Duration**: 30 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(764): complete Phase 3 - Remove Phantom Agent References`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Final Verification and Cleanup
dependencies: [2, 3]

**Objective**: Verify all discrepancies resolved and documentation follows clean-break approach

**Complexity**: Low

**Tasks**:
- [ ] Verify commands/README.md command count is 12
- [ ] Verify all 5 archived command sections are completely absent
- [ ] Verify no references to archived commands remain in any section
- [ ] Verify Navigation section has no archived command links
- [ ] Verify command-reference.md has no phantom agent references
- [ ] Cross-check both files for consistency
- [ ] Update research report Implementation Status section

**Testing**:
```bash
# Final verification commands
echo "=== Command Count ==="
grep "active commands" /home/benjamin/.config/.claude/commands/README.md

echo "=== Archived Command Sections Check ==="
for cmd in implement plan debug research revise; do
  if grep -q "#### /$cmd" /home/benjamin/.config/.claude/commands/README.md; then
    echo "ERROR: /$cmd section found"
  else
    echo "OK: /$cmd section removed"
  fi
done

echo "=== Phantom Agents Check ==="
phantom_count=$(grep -c -E "(code-writer|test-specialist|doc-writer)" /home/benjamin/.config/.claude/docs/reference/command-reference.md || echo 0)
echo "Phantom agent references: $phantom_count (expected: 0)"

echo "=== Navigation Check ==="
nav_count=$(grep -A30 "## Navigation" /home/benjamin/.config/.claude/commands/README.md | grep -c -E "(debug\.md|implement\.md|plan\.md|research\.md|revise\.md)" || echo 0)
echo "Archived command links in Navigation: $nav_count (expected: 0)"
```

**Expected Duration**: 20 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(764): complete Phase 4 - Final Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Verification Approach
- Use grep to verify complete absence of archived content
- Verify no "ARCHIVED" markers exist (clean-break requirement)
- Ensure no replacement notes or migration guidance exists
- Cross-reference with command-reference.md for consistency

### Success Metrics
- Command count shows 12 (not 19)
- 0 archived command sections in commands/README.md
- 0 phantom agent references in command-reference.md
- 0 archived command links in Navigation section
- Documentation reads as if only active commands exist

## Documentation Requirements

### Files to Update
1. `/home/benjamin/.config/.claude/commands/README.md`
   - Command count (line 5)
   - Remove 5 archived command sections
   - Remove Navigation links to archived commands
   - Remove archived commands from Command Types lists

2. `/home/benjamin/.config/.claude/docs/reference/command-reference.md`
   - Remove phantom agent sections (code-writer, test-specialist, doc-writer)

### No New Documentation
This plan does not create new documentation files - it only removes outdated content from existing files to reflect the current state.

## Dependencies

### Prerequisites
- Research reports completed:
  - `../reports/001_archival_completion_research.md`
  - `../reports/002_clean_break_revision_research.md`
- Archived commands already moved to `.claude/archive/legacy-workflow-commands/commands/`
- Replacement commands (/build, /fix, /research-plan, /research-report, /research-revise) already active

### Out of Scope
The following pre-existing issues are explicitly NOT addressed by this plan:
- Agent registry phantom entries (6 phantom agents in agent-registry.json)
- Broken links to command-development-guide.md (82+ files)
- Shared directory emptiness (documented but not created files)
- Naming convention violations (validate_executable_doc_separation.sh)
- File size limit violations (widespread issue)
- Historical commentary sections in commands/README.md (dates like 2025-10-06, etc.)

These should be addressed in separate, dedicated plans.
