# Coordinate Command Archival Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Archive coordinate command and exclusive dependencies
- **Scope**: Archive /coordinate command with all dependencies used exclusively by coordinate, update references in shared files, cleanup temporary/checkpoint files
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 132.5
- **Research Reports**:
  - [Coordinate Dependencies Report](/home/benjamin/.config/.claude/specs/799_coordinate_command_all_its_dependencies_order/reports/001_coordinate_dependencies.md)

## Overview

Archive the /coordinate command and all its exclusive dependencies to simplify the codebase while preserving shared infrastructure used by other commands (build, plan, debug, research, revise). This archival maintains code history by moving files to an archive directory rather than deleting them.

### Goals
1. Remove coordinate command from active use
2. Preserve shared libraries (workflow-state-machine.sh, state-persistence.sh, error-handling.sh, workflow-initialization.sh)
3. Archive exclusive libraries (context-pruning.sh, dependency-analyzer.sh, unified-logger.sh, verification-helpers.sh, library-sourcing.sh)
4. Archive exclusive agents (workflow-classifier.md, implementer-coordinator.md, revision-specialist.md)
5. Update all files that reference archived components
6. Clean up temporary and checkpoint files

## Research Summary

Based on the coordinate dependencies report:

- **Shared infrastructure** (MUST preserve): 4 libraries (workflow-state-machine.sh, state-persistence.sh, error-handling.sh, workflow-initialization.sh) and 3 agents (research-specialist.md, research-sub-supervisor.md, plan-architect.md) are used by multiple commands
- **Exclusive components** (CAN archive): 5 libraries, 3 agents, 9 documentation files, 10+ test files, 1 script
- **High-risk item**: unified-logger.sh is used by 8 other libraries - requires careful dependency analysis before archiving
- **Cleanup targets**: 15+ checkpoint files and 50+ temporary workflow files

Recommended approach: Create archive structure first, update dependent files to remove references, then move files in dependency order (tests first, command last).

## Success Criteria
- [ ] Archive directory structure created at `.claude/archive/coordinate/`
- [ ] All exclusive libraries moved to archive (5 files)
- [ ] All exclusive agents moved to archive (3 files)
- [ ] All coordinate documentation moved to archive (9 files)
- [ ] All coordinate tests moved to archive (10+ files)
- [ ] Coordinate command file moved to archive
- [ ] All shared files updated to remove coordinate references
- [ ] No broken imports/sources in remaining codebase
- [ ] Other commands (build, plan, debug, research, revise) work correctly after archival
- [ ] Temporary and checkpoint files cleaned up
- [ ] Documentation (command-reference.md, agent-reference.md) updated

## Technical Design

### Archive Directory Structure
```
.claude/archive/
└── coordinate/
    ├── README.md           # Explains what was archived and why
    ├── commands/
    │   └── coordinate.md
    ├── agents/
    │   ├── workflow-classifier.md
    │   ├── implementer-coordinator.md
    │   └── revision-specialist.md
    ├── lib/
    │   ├── context-pruning.sh
    │   ├── dependency-analyzer.sh
    │   ├── unified-logger.sh
    │   ├── verification-helpers.sh
    │   └── library-sourcing.sh
    ├── docs/
    │   ├── architecture/
    │   │   ├── coordinate-state-management.md
    │   │   ├── coordinate-state-management-overview.md
    │   │   ├── coordinate-state-management-states.md
    │   │   ├── coordinate-state-management-examples.md
    │   │   └── coordinate-state-management-transitions.md
    │   └── guides/
    │       ├── coordinate-command-index.md
    │       ├── coordinate-architecture.md
    │       ├── coordinate-usage-guide.md
    │       └── coordinate-troubleshooting.md
    ├── tests/
    │   ├── test_coordinate_basic.sh
    │   ├── test_coordinate_all.sh
    │   ├── test_coordinate_state_variables.sh
    │   ├── test_coordinate_exit_trap_timing.sh
    │   ├── test_coordinate_bash_block_fixes_integration.sh
    │   ├── test_coordinate_verification.sh
    │   ├── verify_coordinate_standard11.sh
    │   ├── test_coordinate_delegation.sh.bak
    │   ├── test_coordinate_standards.sh
    │   ├── test_coordinate_waves.sh
    │   ├── test_verification_helpers.sh
    │   └── test_library_sourcing_order.sh
    └── scripts/
        └── analyze-coordinate-performance.sh
```

### Dependency Analysis for unified-logger.sh

The unified-logger.sh library requires special handling due to widespread use:

**Files that source unified-logger.sh**:
1. workflow-initialization.sh
2. workflow-llm-classifier.sh
3. workflow-scope-detection.sh
4. metadata-extraction.sh
5. artifact-creation.sh
6. artifact-registry.sh

**Decision**: Extract essential functions (like rotate_log_file) to a minimal utility before archiving, OR update dependent files to remove the sourcing if those functions are no longer needed.

### Update Order Strategy

Files must be updated in this order to avoid broken references:
1. Update library-sourcing.sh to remove coordinate-specific libraries
2. Update source-libraries-snippet.sh to remove coordinate references
3. Update dependent libraries that source unified-logger.sh
4. Update reference documentation
5. Archive files in dependency order

## Implementation Phases

### Phase 1: Pre-Archival Analysis and Backup [NOT STARTED]
dependencies: []

**Objective**: Verify all dependencies identified in research and create safety backup

**Complexity**: Low

Tasks:
- [ ] Create safety backup of .claude directory before any changes
- [ ] Verify all coordinate-exclusive files identified in research still exist
- [ ] Confirm unified-logger.sh dependencies - check which functions are actually used by dependent files
- [ ] Identify if any functions from unified-logger.sh need extraction to shared utility
- [ ] Document any additional files referencing coordinate that were missed in research
- [ ] Verify implementer-coordinator.md usage in build.md - confirm if archival is safe

Testing:
```bash
# Verify files exist
for f in .claude/lib/context-pruning.sh .claude/lib/dependency-analyzer.sh .claude/lib/unified-logger.sh .claude/lib/verification-helpers.sh .claude/lib/library-sourcing.sh; do
  test -f "$f" && echo "OK: $f" || echo "MISSING: $f"
done

# Check unified-logger.sh usage
grep -l "unified-logger.sh" .claude/lib/*.sh .claude/commands/*.md
```

**Expected Duration**: 2 hours

### Phase 2: Create Archive Structure and Update References [NOT STARTED]
dependencies: [1]

**Objective**: Create archive directory structure and update all files that reference coordinate-exclusive components

**Complexity**: High

Tasks:
- [ ] Create archive directory structure: `.claude/archive/coordinate/{commands,agents,lib,docs/architecture,docs/guides,tests,scripts}`
- [ ] Create archive README.md explaining archival reason and contents
- [ ] Update `.claude/lib/library-sourcing.sh` to remove context-pruning.sh, dependency-analyzer.sh, unified-logger.sh from library list
- [ ] Update `.claude/lib/source-libraries-snippet.sh` to remove coordinate-specific library references
- [ ] Update workflow-initialization.sh to remove unified-logger.sh sourcing (or extract needed functions)
- [ ] Update workflow-llm-classifier.sh to remove unified-logger.sh sourcing
- [ ] Update workflow-scope-detection.sh to remove unified-logger.sh sourcing
- [ ] Update metadata-extraction.sh to remove unified-logger.sh sourcing
- [ ] Update artifact-creation.sh to remove unified-logger.sh sourcing
- [ ] Update artifact-registry.sh to remove unified-logger.sh sourcing
- [ ] Update `.claude/docs/reference/command-reference.md` to remove /coordinate entry
- [ ] Update `.claude/docs/reference/agent-reference.md` to mark archived agents
- [ ] Update `.claude/agents/README.md` to remove coordinate-exclusive agents
- [ ] Update `.claude/lib/README.md` to remove coordinate-exclusive libraries
- [ ] Update any CLAUDE.md sections referencing coordinate command

Testing:
```bash
# Verify archive structure created
test -d .claude/archive/coordinate/commands && echo "OK: archive structure"

# Check for remaining coordinate references in updated files
grep -l "context-pruning.sh\|dependency-analyzer.sh\|unified-logger.sh" .claude/lib/*.sh | grep -v archive
```

**Expected Duration**: 4 hours

### Phase 3: Archive Files [NOT STARTED]
dependencies: [2]

**Objective**: Move all coordinate-exclusive files to archive directory

**Complexity**: Medium

Tasks:
- [ ] Archive test files: move all `.claude/tests/test_coordinate_*.sh` to archive/coordinate/tests/
- [ ] Archive test helper files: move test_verification_helpers.sh, test_library_sourcing_order.sh to archive
- [ ] Archive documentation: move `.claude/docs/architecture/coordinate-state-management*.md` to archive
- [ ] Archive documentation: move `.claude/docs/guides/coordinate-*.md` to archive
- [ ] Archive script: move `.claude/scripts/analyze-coordinate-performance.sh` to archive
- [ ] Archive agents: move workflow-classifier.md to archive/coordinate/agents/
- [ ] Archive agents: move implementer-coordinator.md to archive/coordinate/agents/
- [ ] Archive agents: move revision-specialist.md to archive/coordinate/agents/
- [ ] Archive libraries: move context-pruning.sh to archive/coordinate/lib/
- [ ] Archive libraries: move dependency-analyzer.sh to archive/coordinate/lib/
- [ ] Archive libraries: move unified-logger.sh to archive/coordinate/lib/
- [ ] Archive libraries: move verification-helpers.sh to archive/coordinate/lib/
- [ ] Archive libraries: move library-sourcing.sh to archive/coordinate/lib/
- [ ] Archive command: move `.claude/commands/coordinate.md` to archive/coordinate/commands/

Testing:
```bash
# Verify all files moved to archive
ls -la .claude/archive/coordinate/commands/coordinate.md
ls -la .claude/archive/coordinate/agents/*.md
ls -la .claude/archive/coordinate/lib/*.sh
ls -la .claude/archive/coordinate/tests/*.sh

# Verify original locations are empty
test ! -f .claude/commands/coordinate.md && echo "OK: command archived"
test ! -f .claude/lib/context-pruning.sh && echo "OK: libraries archived"
```

**Expected Duration**: 2 hours

### Phase 4: Cleanup Temporary and Checkpoint Files [NOT STARTED]
dependencies: [3]

**Objective**: Remove temporary workflow files and outdated checkpoint files

**Complexity**: Low

Tasks:
- [ ] Remove checkpoint files: `.claude/data/checkpoints/coordinate_phase_*.json`
- [ ] Remove temporary workflow files: `.claude/tmp/workflow_coordinate_*.sh`
- [ ] Remove temporary description files: `.claude/tmp/coordinate_workflow_desc*.txt`
- [ ] Verify .gitignore already excludes these directories (no update needed if so)
- [ ] Document files removed in archive README.md

Testing:
```bash
# Verify checkpoint files removed
ls .claude/data/checkpoints/coordinate_*.json 2>/dev/null && echo "FAIL: checkpoint files remain" || echo "OK: checkpoints cleaned"

# Verify tmp files removed
ls .claude/tmp/workflow_coordinate_*.sh 2>/dev/null && echo "FAIL: tmp files remain" || echo "OK: tmp cleaned"
```

**Expected Duration**: 1 hour

### Phase 5: Validation and Documentation [NOT STARTED]
dependencies: [4]

**Objective**: Verify archival success and update documentation

**Complexity**: Medium

Tasks:
- [ ] Test /build command functionality
- [ ] Test /plan command functionality
- [ ] Test /debug command functionality
- [ ] Test /research command functionality
- [ ] Test /revise command functionality
- [ ] Verify no broken shell script sources (grep for archived library paths)
- [ ] Verify no broken documentation links to archived files
- [ ] Update archive README.md with complete inventory
- [ ] Create summary of what was archived and any behavioral changes
- [ ] Run any existing test suites for remaining commands

Testing:
```bash
# Check for broken references
grep -r "coordinate.md\|context-pruning.sh\|dependency-analyzer.sh\|unified-logger.sh\|verification-helpers.sh\|library-sourcing.sh" .claude --include="*.sh" --include="*.md" | grep -v archive | grep -v "^Binary"

# Verify remaining commands are functional (manual testing recommended)
echo "Manual testing required for: /build, /plan, /debug, /research, /revise"
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Testing
- Verify each file move operation completes successfully
- Check that no source/reference errors occur after each phase

### Integration Testing
- Run remaining test suites after archival
- Execute each of the 5 remaining commands with simple test inputs
- Verify agent invocations work correctly

### Regression Testing
- Compare behavior of build, plan, debug, research, revise before and after archival
- Ensure no unexpected behavioral changes

### Manual Verification
- Review archive directory for completeness
- Spot-check documentation updates
- Verify command help text updated

## Documentation Requirements

### Files to Update
1. `.claude/docs/reference/command-reference.md` - Remove /coordinate entry
2. `.claude/docs/reference/agent-reference.md` - Mark 3 agents as archived
3. `.claude/agents/README.md` - Remove archived agent entries
4. `.claude/lib/README.md` - Remove archived library entries
5. `.claude/archive/coordinate/README.md` - Create comprehensive archive documentation

### Archive README Content
- Date and reason for archival
- Complete file inventory
- Dependencies that were preserved vs archived
- Instructions for restoration if needed
- Summary of related cleanup (checkpoints, tmp files)

## Dependencies

### Prerequisites
- Git repository is clean (all changes committed before archival)
- Backup of .claude directory exists
- Write access to all directories involved

### External Dependencies
- None

### Internal Dependencies
- Remaining commands (build, plan, debug, research, revise) must continue functioning
- Shared libraries must remain intact and functional
- CLAUDE.md must be updated to reflect removed command

## Risk Assessment

### High Risk
- **unified-logger.sh archival**: 8 dependent files need updates. Mitigation: Update all dependents before archiving
- **implementer-coordinator.md**: May be used by build.md. Mitigation: Verify usage before archiving

### Medium Risk
- **library-sourcing.sh removal**: Changes how libraries are loaded. Mitigation: Update dependents to source libraries directly
- **Broken documentation links**: Archive paths may break existing links. Mitigation: Search and update all references

### Low Risk
- **Test file archival**: Self-contained, no external dependencies
- **Documentation archival**: Informational only, no functional impact
- **Checkpoint/tmp cleanup**: Generated files, easily regenerated

## Rollback Plan

If issues are discovered after archival:

1. **Immediate rollback**: Restore from pre-archival backup
2. **Selective restoration**: Move specific files back from archive directory
3. **Reference update**: Revert changes to shared files using git

All archived files are preserved in `.claude/archive/coordinate/` for potential restoration.

## Notes

- This plan follows the progressive planning approach (Level 0 single file structure)
- Phase dependencies enable sequential execution to maintain reference integrity
- The archive approach preserves code history while removing active components
- Consider adding a deprecation notice period before full archival in production environments
