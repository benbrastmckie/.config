# Complete Archival Discrepancies Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Complete archival of legacy workflow commands documentation
- **Scope**: Fix 2 remaining discrepancies in commands/README.md and command-reference.md
- **Estimated Phases**: 4
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 16.5
- **Research Reports**:
  - [Archival Completion Research](../reports/001_archival_completion_research.md)

## Overview

The archival of 5 legacy workflow commands (debug.md, implement.md, plan.md, research.md, revise.md) is functionally complete. Two documentation discrepancies require remediation:

1. **commands/README.md** - Still documents archived commands as active (HIGH priority)
2. **command-reference.md agent section** - References phantom agents that were never created (MEDIUM priority)

This plan focuses ONLY on completing the archival. Pre-existing systemic issues (agent registry phantom entries, broken links, shared directory emptiness, naming conventions, file size limits) are explicitly out of scope and should be addressed in separate plans.

## Research Summary

Key findings from the archival completion research report:

- **commands/README.md**: Documents 19 commands when only 12 are active; contains full documentation for 5 archived commands (/implement, /plan, /debug, /research, /revise)
- **command-reference.md**: Already correctly marks archived commands but has phantom agent references (code-writer, test-specialist, doc-writer) that were never implemented
- **Replacement Mappings**: /implement -> /build, /plan -> /research-plan, /debug -> /fix, /research -> /research-report, /revise -> /research-revise
- **Archive Location**: `.claude/archive/legacy-workflow-commands/commands/`

## Success Criteria

- [ ] commands/README.md command count updated from 19 to 12
- [ ] commands/README.md /implement section marked as ARCHIVED with /build replacement
- [ ] commands/README.md /plan section marked as ARCHIVED with /research-plan replacement
- [ ] commands/README.md /debug section marked as ARCHIVED with /fix replacement
- [ ] commands/README.md /research section marked as ARCHIVED with /research-report replacement
- [ ] commands/README.md /revise section marked as ARCHIVED with /research-revise replacement
- [ ] commands/README.md Navigation section updated to remove archived command links
- [ ] command-reference.md agent section updated to remove phantom agent references
- [ ] All changes maintain consistency with existing archived command documentation patterns

## Technical Design

### Approach
Apply consistent archival marking pattern across both files:
- Mark command sections with "ARCHIVED" status
- Add clear replacement command references
- Update counts and navigation to reflect current state
- Remove or update phantom agent references

### Pattern for Archived Command Sections
```markdown
#### /command-name - ARCHIVED
**Replacement**: Use `/replacement-command` instead

**Archive Location**: `.claude/archive/legacy-workflow-commands/commands/command-name.md`
```

### Agent Section Updates
Remove references to phantom agents (code-writer, test-specialist, doc-writer) from command-reference.md and update to reference actual agents used by current commands.

## Implementation Phases

### Phase 1: Update commands/README.md Command Count and Header
dependencies: []

**Objective**: Update the command count and clarify archival status in header

**Complexity**: Low

**Tasks**:
- [ ] Read commands/README.md current content (line 5)
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

### Phase 2: Mark Archived Commands in commands/README.md
dependencies: [1]

**Objective**: Convert 5 archived command sections to archived status with replacement references

**Complexity**: Medium

**Tasks**:
- [ ] Update /implement section (lines 137-149) to ARCHIVED format
  - Add "ARCHIVED" marker to heading
  - Replace full documentation with brief note pointing to /build
  - Add archive location reference
- [ ] Update /plan section (lines 152-165) to ARCHIVED format
  - Add "ARCHIVED" marker to heading
  - Replace full documentation with brief note pointing to /research-plan
  - Add archive location reference
- [ ] Update /research section (lines 186-206) to ARCHIVED format
  - Add "ARCHIVED" marker to heading
  - Replace full documentation with brief note pointing to /research-report
  - Add archive location reference
- [ ] Update /debug section (lines 237-248) to ARCHIVED format
  - Add "ARCHIVED" marker to heading
  - Replace full documentation with brief note pointing to /fix
  - Add archive location reference
- [ ] Update /revise section (lines 325-337) to ARCHIVED format
  - Add "ARCHIVED" marker to heading
  - Replace full documentation with brief note pointing to /research-revise
  - Add archive location reference

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update Navigation section (lines 783-804) to remove archived command links
  - Remove: debug.md, implement.md, plan.md, research.md, revise.md
  - Ensure remaining links are accurate
- [ ] Update Command Types section to move archived commands to separate "Archived" category

**Testing**:
```bash
# Verify all 5 commands are marked ARCHIVED
grep -c "ARCHIVED" /home/benjamin/.config/.claude/commands/README.md

# Verify replacement commands are mentioned
grep -E "(Use.*\/build|Use.*\/research-plan|Use.*\/fix|Use.*\/research-report|Use.*\/research-revise)" /home/benjamin/.config/.claude/commands/README.md

# Verify archived command links removed from Navigation
grep -A30 "## Navigation" /home/benjamin/.config/.claude/commands/README.md | grep -E "(debug\.md|implement\.md|plan\.md|research\.md|revise\.md)"
```

**Expected Duration**: 45 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(764): complete Phase 2 - Mark Archived Commands in README`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Update command-reference.md Agent Section
dependencies: [1]

**Objective**: Remove phantom agent references from agent section

**Complexity**: Low

**Tasks**:
- [ ] Read command-reference.md agent section (lines 600-647)
- [ ] Update code-writer section (lines 614-618)
  - Remove or update to reference actual agent: implementer-coordinator
  - Update associated commands to /build
- [ ] Update test-specialist section (lines 619-624)
  - Remove or update references since this agent doesn't exist
  - Note that testing is handled by testing-sub-supervisor
- [ ] Update doc-writer section (lines 630-633)
  - Keep section but update command references to reflect current usage
  - Remove /coordinate reference if doc-writer is not actually used
- [ ] Verify consistency with actual agents in agents/ directory

**Testing**:
```bash
# Verify no phantom agent references remain
grep -E "(code-writer|test-specialist)" /home/benjamin/.config/.claude/docs/reference/command-reference.md

# Verify agent references align with actual agents
ls /home/benjamin/.config/.claude/agents/*.md | xargs -I {} basename {} .md
```

**Expected Duration**: 30 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(764): complete Phase 3 - Update Agent Section`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Final Verification and Cleanup
dependencies: [2, 3]

**Objective**: Verify all discrepancies resolved and documentation is consistent

**Complexity**: Low

**Tasks**:
- [ ] Verify commands/README.md command count is 12
- [ ] Verify all 5 archived commands have consistent ARCHIVED format
- [ ] Verify all replacement command references are correct
- [ ] Verify Navigation section has no archived command links
- [ ] Verify command-reference.md agent section has no phantom references
- [ ] Cross-check with docs/reference/command-reference.md for consistency
- [ ] Update research report Implementation Status section

**Testing**:
```bash
# Final verification commands
echo "=== Command Count ==="
grep "active commands" /home/benjamin/.config/.claude/commands/README.md

echo "=== Archived Commands ==="
grep -c "ARCHIVED" /home/benjamin/.config/.claude/commands/README.md

echo "=== Replacement References ==="
grep -c "Use.*instead" /home/benjamin/.config/.claude/commands/README.md

echo "=== Phantom Agents ==="
grep -E "(code-writer|test-specialist)" /home/benjamin/.config/.claude/docs/reference/command-reference.md | wc -l

echo "=== Navigation Check ==="
grep -A30 "## Navigation" /home/benjamin/.config/.claude/commands/README.md | grep -c -E "(debug\.md|implement\.md|plan\.md|research\.md|revise\.md)"
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
- Use grep to verify pattern matches across updated files
- Cross-reference with command-reference.md for consistency
- Ensure no orphaned links in Navigation section
- Confirm all replacement command references are valid

### Success Metrics
- Command count shows 12 (not 19)
- 5 ARCHIVED markers present in commands/README.md
- 0 phantom agent references in command-reference.md
- 0 archived command links in Navigation section

## Documentation Requirements

### Files to Update
1. `/home/benjamin/.config/.claude/commands/README.md`
   - Command count
   - 5 archived command sections
   - Navigation section

2. `/home/benjamin/.config/.claude/docs/reference/command-reference.md`
   - Agent section (lines 600-647)

### No New Documentation
This plan does not create new documentation files - it only updates existing files to reflect the completed archival.

## Dependencies

### Prerequisites
- Research report completed: `../reports/001_archival_completion_research.md`
- Archived commands already moved to `.claude/archive/legacy-workflow-commands/commands/`
- Replacement commands (/build, /fix, /research-plan, /research-report, /research-revise) already active

### Out of Scope
The following pre-existing issues are explicitly NOT addressed by this plan:
- Agent registry phantom entries (6 phantom agents in agent-registry.json)
- Broken links to command-development-guide.md (82+ files)
- Shared directory emptiness (documented but not created files)
- Naming convention violations (validate_executable_doc_separation.sh)
- File size limit violations (widespread issue)

These should be addressed in separate, dedicated plans.
