# Command Rename Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Rename /fix to /debug, /research-plan to /plan, /research-report to /research, /research-revise to /revise
- **Scope**: Uniform command renaming across .claude/ directory (excluding archive/)
- **Estimated Phases**: 6
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 135
- **Research Reports**:
  - [Command Rename Research](../reports/001_command_rename_research.md)

## Overview

This plan implements a uniform rename of four workflow commands to shorter, more intuitive names following the project's clean-break approach. The renaming eliminates the redundant "research-" prefix pattern and aligns command names with their primary purpose.

**Rename Mapping:**
- `/fix` -> `/debug`
- `/research-plan` -> `/plan`
- `/research-report` -> `/research`
- `/research-revise` -> `/revise`

## Research Summary

Key findings from the command rename research:
- **4 command definition files** require renaming in `/home/benjamin/.config/.claude/commands/`
- **4 guide files** require renaming in `/home/benjamin/.config/.claude/docs/guides/`
- **20+ documentation files** contain references requiring updates
- **6 test files** contain command references in assertions and arrays
- **Critical conflict**: Archived legacy commands exist with target names but are clearly marked as archived in `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/`
- **Spec artifacts** (~100+ references) should NOT be modified as they are historical records

Recommended approach: Phased implementation starting with command files, then guides, documentation, tests, and finally archive README updates.

## Success Criteria

- [ ] All 4 command files renamed and functional
- [ ] All 4 guide files renamed and cross-references updated
- [ ] All documentation files updated with new command names
- [ ] All test files updated and passing
- [ ] Archive README updated to clarify naming change
- [ ] No orphaned references to old command names in active documentation
- [ ] Commands invocable with new names (e.g., `/debug`, `/plan`, `/research`, `/revise`)

## Technical Design

### Architecture Overview

The command system uses markdown files in `.claude/commands/` that are discovered by Claude Code. Each command has:
1. A definition file (`commands/*.md`) with frontmatter and implementation
2. A guide file (`docs/guides/*-command-guide.md`) with usage documentation
3. References throughout documentation files

### Rename Strategy

**Clean-Break Approach:**
- No backward compatibility aliases
- No redirects from old names to new names
- Old names simply cease to exist
- Documentation clearly states the rename

**File Operations:**
- Use `git mv` for renames to preserve history
- Update file contents after rename
- Update all cross-references in other files

### Exclusions

The following directories are explicitly excluded:
- `archive/` - Contains legacy commands (read-only, but README updated)
- `specs/` - Historical records should not be modified

## Implementation Phases

### Phase 1: Command Definition File Renames
dependencies: []

**Objective**: Rename core command files and update their internal content

**Complexity**: Medium

Tasks:
- [ ] Rename `/home/benjamin/.config/.claude/commands/fix.md` to `debug.md` (using git mv)
- [ ] Update header in `debug.md` from `# /fix` to `# /debug`
- [ ] Update all internal references in `debug.md` from `/fix` to `/debug`
- [ ] Rename `/home/benjamin/.config/.claude/commands/research-plan.md` to `plan.md` (using git mv)
- [ ] Update header in `plan.md` from `# /research-plan` to `# /plan`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update all internal references in `plan.md` from `/research-plan` to `/plan`
- [ ] Rename `/home/benjamin/.config/.claude/commands/research-report.md` to `research.md` (using git mv)
- [ ] Update header in `research.md` from `# /research-report` to `# /research`
- [ ] Update all internal references in `research.md` from `/research-report` to `/research`
- [ ] Rename `/home/benjamin/.config/.claude/commands/research-revise.md` to `revise.md` (using git mv)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update header in `revise.md` from `# /research-revise` to `# /revise`
- [ ] Update all internal references in `revise.md` from `/research-revise` to `/revise`
- [ ] Update cross-references between renamed commands (e.g., `/plan` references to `/revise`)

Testing:
```bash
# Verify files renamed correctly
ls -la /home/benjamin/.config/.claude/commands/{debug,plan,research,revise}.md

# Verify old files removed
! test -f /home/benjamin/.config/.claude/commands/fix.md
! test -f /home/benjamin/.config/.claude/commands/research-plan.md
! test -f /home/benjamin/.config/.claude/commands/research-report.md
! test -f /home/benjamin/.config/.claude/commands/research-revise.md

# Verify headers updated
grep -l "^# /debug" /home/benjamin/.config/.claude/commands/debug.md
grep -l "^# /plan" /home/benjamin/.config/.claude/commands/plan.md
grep -l "^# /research$" /home/benjamin/.config/.claude/commands/research.md
grep -l "^# /revise" /home/benjamin/.config/.claude/commands/revise.md
```

**Expected Duration**: 1.5 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(766): complete Phase 1 - Command Definition File Renames`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Guide File Renames
dependencies: [1]

**Objective**: Rename guide documentation files and update their content

**Complexity**: Medium

Tasks:
- [ ] Rename `/home/benjamin/.config/.claude/docs/guides/fix-command-guide.md` to `debug-command-guide.md`
- [ ] Update all internal references in `debug-command-guide.md` from `/fix` to `/debug`
- [ ] Update title and headers in `debug-command-guide.md`
- [ ] Rename `/home/benjamin/.config/.claude/docs/guides/research-plan-command-guide.md` to `plan-command-guide.md`
- [ ] Update all internal references in `plan-command-guide.md` from `/research-plan` to `/plan`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update title and headers in `plan-command-guide.md`
- [ ] Rename `/home/benjamin/.config/.claude/docs/guides/research-report-command-guide.md` to `research-command-guide.md`
- [ ] Update all internal references in `research-command-guide.md` from `/research-report` to `/research`
- [ ] Update title and headers in `research-command-guide.md`
- [ ] Rename `/home/benjamin/.config/.claude/docs/guides/research-revise-command-guide.md` to `revise-command-guide.md`
- [ ] Update all internal references in `revise-command-guide.md` from `/research-revise` to `/revise`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update title and headers in `revise-command-guide.md`
- [ ] Update cross-references between guide files

Testing:
```bash
# Verify guide files renamed
ls -la /home/benjamin/.config/.claude/docs/guides/{debug,plan,research,revise}-command-guide.md

# Verify old files removed
! test -f /home/benjamin/.config/.claude/docs/guides/fix-command-guide.md
! test -f /home/benjamin/.config/.claude/docs/guides/research-plan-command-guide.md
! test -f /home/benjamin/.config/.claude/docs/guides/research-report-command-guide.md
! test -f /home/benjamin/.config/.claude/docs/guides/research-revise-command-guide.md
```

**Expected Duration**: 1 hour

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(766): complete Phase 2 - Guide File Renames`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Core Documentation Updates
dependencies: [1, 2]

**Objective**: Update command references in core documentation files

**Complexity**: High

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/command-reference.md`:
  - Replace all `/fix` with `/debug`
  - Replace all `/research-plan` with `/plan`
  - Replace all `/research-report` with `/research`
  - Replace all `/research-revise` with `/revise`
  - Update section headings (e.g., `### /fix` to `### /debug`)
  - Update guide file links to new filenames
- [ ] Update `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`:
  - Line 130-132: Update command listings
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md`:
  - Line 456: Update reference commands list
- [ ] Update `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`:
  - Line 403: Update any command references

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Update `/home/benjamin/.config/.claude/commands/README.md`:
  - Line 80: Update /research-plan reference
  - Lines 350, 354, 358: Update command category lists
  - Lines 397, 400: Update command descriptions
  - Lines 456, 469: Update [Used by:] metadata
  - Lines 647-698: Update usage examples
- [ ] Update `/home/benjamin/.config/.claude/agents/workflow-classifier.md`:
  - Line 82: Update "debug/fix" pattern reference

Testing:
```bash
# Verify no old command names remain in active documentation
grep -r "/fix\b" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v archive || echo "No /fix references found"
grep -r "/research-plan\b" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v archive || echo "No /research-plan references found"
grep -r "/research-report\b" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v archive || echo "No /research-report references found"
grep -r "/research-revise\b" /home/benjamin/.config/.claude/docs/ --include="*.md" | grep -v archive || echo "No /research-revise references found"
```

**Expected Duration**: 2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(766): complete Phase 3 - Core Documentation Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Test File Updates
dependencies: [1]

**Objective**: Update test files with new command names and file paths

**Complexity**: Medium

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/tests/test_compliance_remediation_phase7.sh`:
  - Lines 20-23: Update command file paths array from old names to new names
- [ ] Rename `/home/benjamin/.config/.claude/tests/test_subprocess_isolation_research_plan.sh` to `test_subprocess_isolation_plan.sh`
- [ ] Update content of `test_subprocess_isolation_plan.sh`:
  - Line 3: Update filename in echo statement
  - Line 36: Update command references
- [ ] Update `/home/benjamin/.config/.claude/tests/test_command_topic_allocation.sh`:
  - Lines 53-150: Update multiple arrays with command filenames

Testing:
```bash
# Run updated tests
cd /home/benjamin/.config/.claude/tests

# Verify test file renamed
test -f test_subprocess_isolation_plan.sh
! test -f test_subprocess_isolation_research_plan.sh

# Run test suite if available
# Note: Specific test commands depend on project test runner
```

**Expected Duration**: 1 hour

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(766): complete Phase 4 - Test File Updates`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Archive Documentation Update
dependencies: [3]

**Objective**: Update archive README to clarify the naming change

**Complexity**: Low

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/archive/legacy-workflow-commands/README.md`:
  - Add note at top explaining the rename (date: 2025-11-17)
  - Clarify that archived `/debug`, `/plan`, `/research`, `/revise` are superseded by newly-renamed active commands
  - Update migration guidance to reference new command names
  - Lines 51-53: Update the replacement command references

Testing:
```bash
# Verify archive README updated
grep -l "2025-11-17" /home/benjamin/.config/.claude/archive/legacy-workflow-commands/README.md
grep -l "/plan" /home/benjamin/.config/.claude/archive/legacy-workflow-commands/README.md
```

**Expected Duration**: 0.5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(766): complete Phase 5 - Archive Documentation Update`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Verification and Final Cleanup
dependencies: [1, 2, 3, 4, 5]

**Objective**: Verify all renames complete and no orphaned references remain

**Complexity**: Low

Tasks:
- [ ] Run comprehensive grep to find any remaining old command references:
  ```bash
  grep -r --include="*.md" --include="*.sh" \
    -E "/fix\b|/research-plan\b|/research-report\b|/research-revise\b" \
    /home/benjamin/.config/.claude/ | grep -v archive | grep -v specs
  ```
- [ ] Fix any orphaned references found
- [ ] Test command invocation (manual verification):
  - Verify `/debug` command is accessible
  - Verify `/plan` command is accessible
  - Verify `/research` command is accessible
  - Verify `/revise` command is accessible
- [ ] Verify all markdown links resolve correctly (no broken links to renamed files)
- [ ] Update this plan with completion status

Testing:
```bash
# Final verification - should return no results
grep -r --include="*.md" --include="*.sh" \
  -E "/fix\b|/research-plan\b|/research-report\b|/research-revise\b" \
  /home/benjamin/.config/.claude/ | grep -v archive | grep -v specs

# Verify all renamed files exist
test -f /home/benjamin/.config/.claude/commands/debug.md
test -f /home/benjamin/.config/.claude/commands/plan.md
test -f /home/benjamin/.config/.claude/commands/research.md
test -f /home/benjamin/.config/.claude/commands/revise.md

echo "All verifications passed"
```

**Expected Duration**: 1 hour

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(766): complete Phase 6 - Verification and Final Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Per-Phase Testing

Each phase includes specific test commands that verify:
1. Files renamed correctly (existence checks)
2. Old files removed (non-existence checks)
3. Content updated (grep searches)
4. No orphaned references (negative grep searches)

### Integration Testing

After all phases complete:
1. Run all test files in `/home/benjamin/.config/.claude/tests/`
2. Manually invoke each renamed command to verify functionality
3. Check markdown link resolution

### Regression Prevention

The final verification phase performs comprehensive searching to ensure no references to old command names remain in active documentation.

## Documentation Requirements

The following documentation updates are included in the implementation phases:
- Command reference documentation (Phase 3)
- Command guides (Phase 2)
- Directory protocols (Phase 3)
- Commands README (Phase 3)
- Archive README (Phase 5)

No additional documentation creation is required - this is a rename operation.

## Dependencies

### Prerequisites
- Git available for `git mv` operations
- Write access to `.claude/` directory
- No pending changes in affected files

### External Dependencies
None - this is an internal refactoring operation.

### Phase Dependencies

**Parallel Execution Opportunities:**
- Phases 1 and 4 can run in parallel (both modify different file types)
- Phase 2 depends on Phase 1 (guide files reference command files)
- Phase 3 depends on Phases 1 and 2 (documentation references both)
- Phase 5 depends on Phase 3 (archive references documentation)
- Phase 6 depends on all prior phases (final verification)

**Wave Structure:**
- Wave 1: Phases 1, 4 (parallel)
- Wave 2: Phase 2
- Wave 3: Phase 3
- Wave 4: Phase 5
- Wave 5: Phase 6

## Risk Mitigation

### Identified Risks

1. **Orphaned References**: Some references may be missed
   - **Mitigation**: Comprehensive grep search in Phase 6

2. **Broken Links**: Markdown links to renamed files may break
   - **Mitigation**: Update all links in documentation phases

3. **Archive Confusion**: Users may confuse archived commands with active ones
   - **Mitigation**: Clear documentation in archive README

### Rollback Strategy

Following clean-break approach, no rollback is planned. If issues arise, git history preserves all changes and can be reverted if necessary.

## Notes

- **Complexity Score 135** suggests potential for phase expansion using `/expand` if implementation reveals additional complexity
- Spec artifacts in `specs/` directory are intentionally not modified as they are historical records
- Archive commands remain in place - only the README is updated to clarify the supersession
