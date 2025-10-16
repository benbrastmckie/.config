# Phase 5: Expansion/Collapse Command Consolidation (High Risk)

## Metadata
- **Phase Number**: 5
- **Parent Plan**: 033_claude_directory_consolidation.md
- **Objective**: Merge 4 commands (expand-phase, expand-stage, collapse-phase, collapse-stage) into 2 (/expand, /collapse)
- **Complexity**: High
- **Status**: COMPLETED

## Overview

This phase consolidates 4 expansion/collapse commands into 2 unified commands with type parameters. This is the highest-risk consolidation due to the complexity of progressive planning operations and the critical importance of these commands in the workflow.

**Impact:**
- Consolidates 3,565 lines across 4 commands into 2 commands
- Reduces command count by 2 (4 → 2)
- Simplifies user interface (/expand [phase|stage] vs separate commands)
- Maintains all functionality (Level 0→1→2 and reverse)
- Critical for progressive planning system

**Commands Being Consolidated:**
- expand-phase.md (1,112 lines)
- expand-stage.md (1,081 lines)
- collapse-phase.md (603 lines)
- collapse-stage.md (769 lines)

## Tasks

### Analysis Phase
- [ ] Analyze expansion commands for shared logic (.claude/commands/expand-phase.md:1-1112, expand-stage.md:1-1081)
- [ ] Analyze collapse commands for shared logic (.claude/commands/collapse-phase.md:1-603, collapse-stage.md:1-769)

### Create Unified Expand Command
- [ ] Create .claude/commands/expand.md with /expand [phase|stage] syntax
- [ ] Extract shared structure detection logic (detect_structure_level function)
- [ ] Extract shared metadata management (update plan metadata)
- [ ] Extract shared directory/file creation (phase_N_name.md, stage_M_name.md)
- [ ] Extract shared content migration (move inline content to files)
- [ ] Implement phase expansion (Level 0 → 1)
- [ ] Implement stage expansion (Level 1 → 2)

### Create Unified Collapse Command
- [ ] Create .claude/commands/collapse.md with /collapse [phase|stage] syntax
- [ ] Extract shared validation logic (verify completion, check structure)
- [ ] Extract shared content merging (inline expanded content)
- [ ] Extract shared cleanup (delete directories/files)
- [ ] Implement phase collapse (Level 1 → 0)
- [ ] Implement stage collapse (Level 2 → 1)

### Testing and Validation
- [ ] Test /expand phase (Level 0 → 1 with all metadata sync)
- [ ] Test /expand stage (Level 1 → 2 with all metadata sync)
- [ ] Test /collapse phase (Level 1 → 0 with content preservation)
- [ ] Test /collapse stage (Level 2 → 1 with content preservation)
- [ ] Test git integration (verify commits, file tracking)

### Cleanup
- [ ] Delete old commands (git rm .claude/commands/expand-phase.md expand-stage.md collapse-phase.md collapse-stage.md)

## Testing

### Phase Expansion Testing (Level 0 → 1)
```bash
# Test expansion
/expand phase .claude/specs/plans/001_test.md 2
```

**Expected:**
- Creates plan directory: `001_test/`
- Moves main plan: `001_test/001_test.md`
- Creates phase file: `001_test/phase_2_implementation.md`
- Updates metadata: Structure Level = 1, Expanded Phases = [2]
- Main plan shows summary with link

### Stage Expansion Testing (Level 1 → 2)
```bash
/expand stage .claude/specs/plans/001_test/phase_2_implementation.md 1
```

**Expected:**
- Creates phase directory: `phase_2_implementation/`
- Moves phase overview: `phase_2_implementation/phase_2_overview.md`
- Creates stage file: `phase_2_implementation/stage_1_setup.md`
- Updates metadata appropriately

### Phase Collapse Testing (Level 1 → 0)
```bash
/collapse phase .claude/specs/plans/001_test.md 2
```

**Expected:**
- Inlines phase content from `phase_2_implementation.md` into main plan
- Deletes phase file
- Updates metadata: Removes 2 from Expanded Phases
- If no expanded phases remain, converts directory back to single file

### Stage Collapse Testing (Level 2 → 1)
```bash
/collapse stage .claude/specs/plans/001_test/phase_2_implementation.md 1
```

**Expected:**
- Inlines stage content from `stage_1_setup.md` into phase file
- Deletes stage file and directory
- Updates phase metadata

### Git Integration Testing
```bash
# Verify git integration
git status
git log --oneline -5
```

**Expected:**
- All file moves tracked by git
- Commit messages are descriptive
- No orphaned files

## Shared Logic to Extract

### Structure Detection
```bash
# Shared function used by both expand and collapse
detect_structure_level() {
  local plan_path="$1"
  # Return 0, 1, or 2 based on directory structure
}
```

### Metadata Management
```bash
# Shared metadata update functions
update_structure_level() {
  local file="$1"
  local level="$2"
  # Update Structure Level in metadata
}

update_expanded_phases() {
  local file="$1"
  local phase_num="$2"
  # Add phase to Expanded Phases list
}

remove_expanded_phase() {
  local file="$1"
  local phase_num="$2"
  # Remove phase from Expanded Phases list
}
```

### Content Extraction/Merging
```bash
# Shared content manipulation
extract_phase_content() {
  local plan_file="$1"
  local phase_num="$2"
  # Extract phase section from plan
}

extract_stage_content() {
  local phase_file="$1"
  local stage_num="$2"
  # Extract stage section from phase
}

inline_content() {
  local target_file="$1"
  local section_num="$2"
  local content="$3"
  # Replace summary with full content
}
```

## Command Syntax

### New /expand Command
```bash
# Phase expansion (Level 0 → 1 or Level 1 → Level 1)
/expand phase <plan-path> <phase-num>

# Stage expansion (Level 1 → 2)
/expand stage <phase-path> <stage-num>
```

### New /collapse Command
```bash
# Phase collapse (Level 1 → 0)
/collapse phase <plan-path> <phase-num>

# Stage collapse (Level 2 → 1)
/collapse stage <phase-path> <stage-num>
```

## Expected Outcomes

After completing this phase:
- [ ] 4 commands reduced to 2 commands
- [ ] All progressive planning levels supported (0, 1, 2)
- [ ] All expansion/collapse operations work correctly
- [ ] Metadata synchronization maintains consistency
- [ ] Git integration tracks all file operations
- [ ] User experience simplified (consistent /expand and /collapse patterns)
- [ ] All existing expanded plans still work

## Dependencies

**Blocks:**
- None (can be done independently of other phases)

**Requires:**
- Phase 1: Utilities Consolidation (lib/ structure must be in place for shared functions)

**Related:**
- Uses lib/parse-adaptive-plan.sh for structure detection
- Uses lib/progressive-planning-utils.sh for metadata management

## Risk Mitigation

**High-Risk Areas:**
1. **Content Extraction**: Parsing phase/stage boundaries accurately
2. **Metadata Synchronization**: Keeping main plan, phase files, and stage files in sync
3. **Git Integration**: Tracking file moves and deletions correctly
4. **Backward Compatibility**: Ensuring existing expanded plans still work

**Mitigation Strategies:**
1. **Extensive Testing**: Test all Level transitions (0→1, 1→2, 2→1, 1→0)
2. **Backup Strategy**: Keep old commands until new commands fully validated
3. **Incremental Rollout**: Test with new plans before migrating existing plans
4. **Git History**: All changes reversible via git

## Notes

- This consolidation preserves 100% of functionality while simplifying interface
- The shared logic (structure detection, metadata management, content extraction) is already well-tested in existing commands
- Main challenge is ensuring type parameter (phase|stage) routes to correct implementation path
- Git integration is critical—all file moves must be tracked properly
- Old commands will be deleted only after thorough testing confirms new commands work

## Update Reminder

**When this phase is complete:**
1. Mark all tasks above as [x]
2. Update phase status to: `**Status**: COMPLETED`
3. Mark Phase 5 as [COMPLETED] in main plan: `033_claude_directory_consolidation.md`
4. Create git commit for phase completion
5. Verify no references to old command names remain in documentation
