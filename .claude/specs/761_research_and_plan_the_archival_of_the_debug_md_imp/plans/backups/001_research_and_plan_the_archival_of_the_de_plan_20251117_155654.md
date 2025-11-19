# Command Archival Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Archive debug.md, implement.md, plan.md, research.md, and revise.md commands
- **Scope**: Archive 5 commands and their exclusive infrastructure (18 files total)
- **Estimated Phases**: 6
- **Estimated Hours**: 8-10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 84
- **Research Reports**:
  - [Command Archival Analysis](../reports/001_command_archival_analysis.md)

## Overview

This plan archives the 5 specified commands (debug.md, implement.md, plan.md, research.md, revise.md) along with their exclusive infrastructure components. The research analysis identified 18 files that are EXCLUSIVELY used by these commands and can be safely archived without breaking other commands (build.md, fix.md, coordinate.md, research-plan.md, research-revise.md, research-report.md).

**Key Constraint**: Most infrastructure is SHARED with other commands and MUST NOT be archived. Only 2 agents, 1 library, 5 documentation files, and 4 test files are exclusive to the target commands.

## Research Summary

Key findings from the archival analysis report:

- **18 files total** can be safely archived (5 commands, 2 agents, 1 library, 5 docs, 4 tests)
- **25+ shared components** MUST be preserved (agents, libraries used by build.md, fix.md, coordinate.md, etc.)
- The `adaptive-planning-logger.sh` library mentioned in research does NOT exist
- Critical shared infrastructure includes: debug-analyst.md, plan-architect.md, research-specialist.md, and most lib/ files
- Test files for revise.md test the revision-specialist agent which is used by coordinate.md, so they remain

Recommended approach: Phased archival with verification after each phase to catch issues early.

## Success Criteria

- [ ] Archive directory structure created at `.claude/archive/legacy-workflow-commands/`
- [ ] All 5 command files moved to archive
- [ ] All 2 exclusive agent files moved to archive
- [ ] All 1 exclusive library file moved to archive
- [ ] All 5 exclusive documentation files moved to archive
- [ ] All 4 exclusive test files moved to archive
- [ ] Stub files created in original locations for backward compatibility
- [ ] All remaining commands function correctly (build.md, fix.md, coordinate.md, etc.)
- [ ] Test suite passes after archival
- [ ] Documentation updated to reflect archived status
- [ ] Rollback script created and tested
- [ ] Archive manifest created documenting all archived files

## Technical Design

### Archive Directory Structure

```
.claude/archive/legacy-workflow-commands/
├── README.md              # Archive documentation
├── MANIFEST.md            # List of all archived files with dates
├── commands/              # Archived command files
│   ├── debug.md
│   ├── implement.md
│   ├── plan.md
│   ├── research.md
│   └── revise.md
├── agents/                # Archived agent files
│   ├── code-writer.md
│   └── implementation-executor.md
├── lib/                   # Archived library files
│   └── validate-plan.sh
├── docs/                  # Archived documentation
│   ├── debug-command-guide.md
│   ├── implement-command-guide.md
│   ├── plan-command-guide.md
│   ├── research-command-guide.md
│   └── revise-command-guide.md
└── tests/                 # Archived test files
    ├── test_auto_debug_integration.sh
    ├── test_plan_command.sh
    ├── test_adaptive_planning.sh
    └── e2e_implement_plan_execution.sh
```

### Stub File Pattern

Each archived command will have a stub in its original location:

```markdown
# /command - ARCHIVED

This command has been archived to `.claude/archive/legacy-workflow-commands/commands/command.md`.

**Archived Date**: 2025-11-17
**Reason**: Command superseded by newer workflows

## Alternatives
- Use `/coordinate` for orchestrated workflows
- Use `/fix` for debugging workflows
- Use `/research-plan` for research+planning workflows

## Recovery
To restore this command, run:
\`\`\`bash
.claude/archive/legacy-workflow-commands/rollback.sh command
\`\`\`
```

### Rollback Strategy

A rollback script will be created that can:
1. Restore individual files from archive
2. Restore entire categories (commands, agents, etc.)
3. Restore all archived files at once
4. Remove stub files when restoring

## Implementation Phases

### Phase 1: Pre-Archival Verification and Setup
dependencies: []

**Objective**: Verify all files exist and create archive directory structure
**Complexity**: Low
**Estimated Time**: 30 minutes

Tasks:
- [ ] Verify all 5 command files exist at expected paths
- [ ] Verify all 2 agent files exist at expected paths
- [ ] Verify validate-plan.sh library exists
- [ ] Verify all 5 documentation files exist
- [ ] Verify all 4 test files exist
- [ ] Create archive directory structure: `.claude/archive/legacy-workflow-commands/`
- [ ] Create subdirectories: commands/, agents/, lib/, docs/, tests/
- [ ] Run full test suite to establish baseline (capture current state)
- [ ] Create backup of all files to be archived

**Testing**:
```bash
# Verify archive directory created
test -d .claude/archive/legacy-workflow-commands/commands && echo "SUCCESS"
test -d .claude/archive/legacy-workflow-commands/agents && echo "SUCCESS"
test -d .claude/archive/legacy-workflow-commands/lib && echo "SUCCESS"
test -d .claude/archive/legacy-workflow-commands/docs && echo "SUCCESS"
test -d .claude/archive/legacy-workflow-commands/tests && echo "SUCCESS"

# Run baseline tests
.claude/tests/run_all_tests.sh
```

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(761): complete Phase 1 - Pre-Archival Verification and Setup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Archive Command Files
dependencies: [1]

**Objective**: Move all 5 command files to archive and create stubs
**Complexity**: Medium
**Estimated Time**: 1-2 hours

Tasks:
- [ ] Move debug.md to archive/legacy-workflow-commands/commands/
- [ ] Create stub file at .claude/commands/debug.md
- [ ] Move implement.md to archive/legacy-workflow-commands/commands/
- [ ] Create stub file at .claude/commands/implement.md
- [ ] Move plan.md to archive/legacy-workflow-commands/commands/
- [ ] Create stub file at .claude/commands/plan.md
- [ ] Move research.md to archive/legacy-workflow-commands/commands/
- [ ] Create stub file at .claude/commands/research.md
- [ ] Move revise.md to archive/legacy-workflow-commands/commands/
- [ ] Create stub file at .claude/commands/revise.md
- [ ] Verify all 5 commands are in archive
- [ ] Verify all 5 stubs are in original locations

**Testing**:
```bash
# Verify files moved
test -f .claude/archive/legacy-workflow-commands/commands/debug.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/commands/implement.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/commands/plan.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/commands/research.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/commands/revise.md && echo "SUCCESS"

# Verify stubs created
test -f .claude/commands/debug.md && grep -q "ARCHIVED" .claude/commands/debug.md && echo "SUCCESS"
test -f .claude/commands/implement.md && grep -q "ARCHIVED" .claude/commands/implement.md && echo "SUCCESS"
test -f .claude/commands/plan.md && grep -q "ARCHIVED" .claude/commands/plan.md && echo "SUCCESS"
test -f .claude/commands/research.md && grep -q "ARCHIVED" .claude/commands/research.md && echo "SUCCESS"
test -f .claude/commands/revise.md && grep -q "ARCHIVED" .claude/commands/revise.md && echo "SUCCESS"
```

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(761): complete Phase 2 - Archive Command Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Archive Agent and Library Files
dependencies: [2]

**Objective**: Move exclusive agents and libraries to archive
**Complexity**: Low
**Estimated Time**: 30-45 minutes

Tasks:
- [ ] Move code-writer.md to archive/legacy-workflow-commands/agents/
- [ ] Move implementation-executor.md to archive/legacy-workflow-commands/agents/
- [ ] Move validate-plan.sh to archive/legacy-workflow-commands/lib/
- [ ] Verify all agent files are in archive
- [ ] Verify library file is in archive
- [ ] Run coordinate.md workflow test to ensure shared agents still work
- [ ] Run build.md workflow test to ensure shared agents still work

**Testing**:
```bash
# Verify files moved
test -f .claude/archive/legacy-workflow-commands/agents/code-writer.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/agents/implementation-executor.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/lib/validate-plan.sh && echo "SUCCESS"

# Verify files removed from original locations
test ! -f .claude/agents/code-writer.md && echo "SUCCESS"
test ! -f .claude/agents/implementation-executor.md && echo "SUCCESS"
test ! -f .claude/lib/validate-plan.sh && echo "SUCCESS"
```

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(761): complete Phase 3 - Archive Agent and Library Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Archive Documentation and Test Files
dependencies: [3]

**Objective**: Move exclusive documentation and test files to archive
**Complexity**: Low
**Estimated Time**: 45 minutes

Tasks:
- [ ] Move debug-command-guide.md to archive/legacy-workflow-commands/docs/
- [ ] Move implement-command-guide.md to archive/legacy-workflow-commands/docs/
- [ ] Move plan-command-guide.md to archive/legacy-workflow-commands/docs/
- [ ] Move research-command-guide.md to archive/legacy-workflow-commands/docs/
- [ ] Move revise-command-guide.md to archive/legacy-workflow-commands/docs/
- [ ] Move test_auto_debug_integration.sh to archive/legacy-workflow-commands/tests/
- [ ] Move test_plan_command.sh to archive/legacy-workflow-commands/tests/
- [ ] Move test_adaptive_planning.sh to archive/legacy-workflow-commands/tests/
- [ ] Move e2e_implement_plan_execution.sh to archive/legacy-workflow-commands/tests/
- [ ] Verify all documentation files are in archive
- [ ] Verify all test files are in archive

**Testing**:
```bash
# Verify doc files moved
test -f .claude/archive/legacy-workflow-commands/docs/debug-command-guide.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/docs/implement-command-guide.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/docs/plan-command-guide.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/docs/research-command-guide.md && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/docs/revise-command-guide.md && echo "SUCCESS"

# Verify test files moved
test -f .claude/archive/legacy-workflow-commands/tests/test_auto_debug_integration.sh && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/tests/test_plan_command.sh && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/tests/test_adaptive_planning.sh && echo "SUCCESS"
test -f .claude/archive/legacy-workflow-commands/tests/e2e_implement_plan_execution.sh && echo "SUCCESS"

# Verify files removed from original locations
test ! -f .claude/docs/guides/debug-command-guide.md && echo "SUCCESS"
test ! -f .claude/tests/test_auto_debug_integration.sh && echo "SUCCESS"
```

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(761): complete Phase 4 - Archive Documentation and Test Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Create Rollback and Documentation
dependencies: [4]

**Objective**: Create rollback script, manifest, and archive documentation
**Complexity**: Medium
**Estimated Time**: 1.5-2 hours

Tasks:
- [ ] Create rollback.sh script in archive directory
- [ ] Implement single-file restore function in rollback script
- [ ] Implement category restore function (commands, agents, lib, docs, tests)
- [ ] Implement full restore function
- [ ] Test rollback script with single file
- [ ] Test rollback script with category
- [ ] Test full restore and re-archive (end-to-end)
- [ ] Create MANIFEST.md listing all archived files with dates
- [ ] Create README.md explaining archive purpose and contents
- [ ] Update command-reference.md to mark commands as archived
- [ ] Update agents/README.md to note archived agents
- [ ] Update CLAUDE.md project_commands section if it references these commands

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test rollback script exists and is executable
test -x .claude/archive/legacy-workflow-commands/rollback.sh && echo "SUCCESS"

# Test single file restore
.claude/archive/legacy-workflow-commands/rollback.sh debug.md --dry-run
# Should show what would be restored

# Verify manifest exists
test -f .claude/archive/legacy-workflow-commands/MANIFEST.md && echo "SUCCESS"

# Verify README exists
test -f .claude/archive/legacy-workflow-commands/README.md && echo "SUCCESS"
```

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(761): complete Phase 5 - Create Rollback and Documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Final Verification and Cleanup
dependencies: [5]

**Objective**: Run full test suite and verify all remaining commands work
**Complexity**: Medium
**Estimated Time**: 1-2 hours

Tasks:
- [ ] Run full test suite (run_all_tests.sh)
- [ ] Test coordinate.md command with simple workflow
- [ ] Test build.md command with simple build
- [ ] Test fix.md command with simple fix
- [ ] Test research-plan.md command
- [ ] Test research-revise.md command
- [ ] Test research-report.md command
- [ ] Verify all shared agents still function
- [ ] Verify all shared libraries still function
- [ ] Document any issues found during testing
- [ ] Create final summary of archival

**Testing**:
```bash
# Run full test suite
.claude/tests/run_all_tests.sh

# Verify key shared agents exist
test -f .claude/agents/debug-analyst.md && echo "SUCCESS"
test -f .claude/agents/plan-architect.md && echo "SUCCESS"
test -f .claude/agents/research-specialist.md && echo "SUCCESS"
test -f .claude/agents/revision-specialist.md && echo "SUCCESS"

# Verify key shared libraries exist
test -f .claude/lib/debug-utils.sh && echo "SUCCESS"
test -f .claude/lib/error-handling.sh && echo "SUCCESS"
test -f .claude/lib/unified-location-detection.sh && echo "SUCCESS"
test -f .claude/lib/checkpoint-utils.sh && echo "SUCCESS"
```

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(761): complete Phase 6 - Final Verification and Cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Per-Phase Testing
Each phase includes specific test commands to verify:
1. Files moved to correct locations
2. Files removed from original locations
3. Stub files created with correct content
4. No regression in remaining commands

### Integration Testing
After all phases complete:
1. Run full test suite
2. Test each remaining command (build, fix, coordinate, etc.)
3. Verify shared infrastructure works
4. Test rollback script functionality

### Rollback Testing
Test rollback script can:
1. Restore single files
2. Restore categories
3. Restore entire archive
4. Remove stub files correctly

## Documentation Requirements

### Files to Update
- `.claude/docs/reference/command-reference.md` - Mark 5 commands as archived
- `.claude/agents/README.md` - Note archived agents
- CLAUDE.md - Remove/update references to archived commands

### Files to Create
- `.claude/archive/legacy-workflow-commands/README.md` - Archive documentation
- `.claude/archive/legacy-workflow-commands/MANIFEST.md` - File inventory
- `.claude/archive/legacy-workflow-commands/rollback.sh` - Restore script

## Dependencies

### Prerequisites
- Git for version control
- Bash for shell scripts
- All 18 target files must exist before archival
- Test suite must pass before archival begins

### External Systems
- None (all operations are local file system operations)

### Post-Archival Dependencies
- Remaining commands must not reference archived files
- Test suite must not depend on archived test files

## Risk Assessment

### High Risk
- **Breaking shared infrastructure**: Mitigated by research report classifying shared vs exclusive components
- **Incomplete archival**: Mitigated by per-phase verification steps

### Medium Risk
- **Rollback fails**: Mitigated by testing rollback script before finalizing
- **Missing file**: Mitigated by Phase 1 verification of all files

### Low Risk
- **Stub file errors**: Easy to detect and fix
- **Documentation gaps**: Can be updated incrementally

## Rollback Procedure

### Immediate Rollback (Before Final Commit)
```bash
# Restore all files from archive
.claude/archive/legacy-workflow-commands/rollback.sh --all

# Remove archive directory
rm -rf .claude/archive/legacy-workflow-commands/
```

### Post-Commit Rollback
```bash
# Restore from archive (files still exist)
.claude/archive/legacy-workflow-commands/rollback.sh --all

# Git restore stub files if needed
git checkout -- .claude/commands/*.md
```

### Emergency Rollback
```bash
# Restore from git history
git stash
git checkout HEAD~6 -- .claude/commands/debug.md .claude/commands/implement.md ...

# Or use git revert
git revert HEAD~5..HEAD
```

## Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Pre-Archival Verification | 30 min | 30 min |
| Phase 2: Archive Commands | 1-2 hrs | 2.5 hrs |
| Phase 3: Archive Agents/Libraries | 30-45 min | 3.25 hrs |
| Phase 4: Archive Docs/Tests | 45 min | 4 hrs |
| Phase 5: Rollback/Documentation | 1.5-2 hrs | 6 hrs |
| Phase 6: Final Verification | 1-2 hrs | 8 hrs |

**Total Estimated Time**: 8-10 hours

## Notes

### Files NOT Being Archived (Shared Infrastructure)

The following are SHARED with other commands and MUST be preserved:

**Agents** (10+):
- debug-analyst.md, debug-specialist.md, plan-architect.md
- plan-complexity-classifier.md, research-specialist.md
- research-synthesizer.md, spec-updater.md, revision-specialist.md
- implementation-researcher.md, implementer-coordinator.md

**Libraries** (15+):
- debug-utils.sh, error-handling.sh, checkpoint-utils.sh
- complexity-utils.sh, state-persistence.sh
- workflow-state-machine.sh, verification-helpers.sh
- unified-location-detection.sh, metadata-extraction.sh
- topic-decomposition.sh, artifact-creation.sh
- template-integration.sh, overview-synthesis.sh
- topic-utils.sh, detect-project-dir.sh

### Research Report Correction

The research report listed `adaptive-planning-logger.sh` as exclusive to implement.md, but this file does NOT exist. The plan only includes `validate-plan.sh` as the exclusive library file.
