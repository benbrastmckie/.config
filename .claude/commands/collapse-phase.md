# Collapse Phase Command

Merge an expanded phase file back into the main plan and clean up directory structure if this was the last expanded phase.

## Usage

```bash
/collapse-phase <plan-path> <phase-num>
```

## Arguments

- `plan-path`: Path to the plan directory (e.g., `specs/plans/025_feature/`)
- `phase-num`: The phase number to collapse (e.g., `2`)

## Description

This command reverses phase expansion by:

1. **Reading Phase File Content**: Extracts full content from expanded phase file
2. **Merging into Main Plan**: Replaces summary in main plan with full phase content
3. **Deleting Phase File**: Removes the phase file after successful merge
4. **Checking Last Phase**: Determines if this was the last expanded phase
5. **Directory Cleanup**: If last phase, moves main plan back to root and deletes directory
6. **Updating Metadata**: Updates Structure Level and Expanded Phases metadata

## Progressive Collapse Workflow

### Level 1 → Level 1 (Collapse Non-Last Phase)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
├── phase_2_implementation.md       # Phase to collapse
└── phase_5_deployment.md           # Another expanded phase
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Phase 2 content merged back
└── phase_5_deployment.md           # Unchanged
```

### Level 1 → Level 0 (Collapse Last Phase)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
└── phase_2_implementation.md       # Last expanded phase
```

**After:**
```
specs/plans/025_feature.md          # Main plan moved to root, all content inline
```

## Content Merging

The command merges the following from the phase file:

1. **Phase heading**: Restored from phase file
2. **Objective**: Full objective text
3. **Complexity**: If present
4. **Tasks**: All task checkboxes with preserved completion status
5. **Testing**: Test commands
6. **Expected Outcomes**: Outcome descriptions
7. **Status markers**: Preserved [PENDING], [IN_PROGRESS], [COMPLETED]

## Main Plan Update

After merging, the phase section in the main plan is restored to full content:

```markdown
### Phase N: Name
**Objective**: [Full objective text]
**Complexity**: [If present]

Tasks:
- [x] Completed task
- [ ] Pending task

Testing:
[Test commands]

Expected Outcomes:
[Full outcomes]
```

## Metadata Updates

### Main Plan Metadata (Non-Last Phase)

```markdown
## Metadata
- **Structure Level**: 1
- **Expanded Phases**: [5]  # Phase 2 removed
```

### Main Plan Metadata (Last Phase)

```markdown
## Metadata
- **Structure Level**: 0
# Expanded Phases removed
```

## Directory Cleanup

When collapsing the last expanded phase:

1. **Move main plan**: From `specs/plans/025_feature/025_feature.md` to `specs/plans/025_feature.md`
2. **Delete directory**: Remove `specs/plans/025_feature/`
3. **Update paths**: Adjust any relative paths in metadata

## Validation Checks

Before collapse, the command verifies:
- Plan directory exists
- Phase file exists and is readable
- Phase number is valid
- No stage expansions in the phase (must collapse stages first)

After collapse, the command verifies:
- Content successfully merged
- Phase file deleted
- Metadata updated correctly
- If last phase, directory cleaned up

## Error Handling

- **Plan not found**: Error with path guidance
- **Phase file not found**: Error listing available phases
- **Phase has expanded stages**: Error, must collapse stages first
- **Merge failure**: Error with backup information
- **Delete failure**: Warning, manual cleanup may be needed

## Examples

### Collapse Phase 2 (Not Last Phase)

```bash
/collapse-phase specs/plans/025_feature/ 2
```

**Output:**
```
Collapsing Phase 2 from plan: 025_feature/
  - Reading phase file: phase_2_implementation.md
  - Merging content into main plan
  - Removing phase file
  - Updating metadata: Expanded Phases = [5]
  - Directory retained (other expanded phases exist)

✓ Phase 2 collapsed successfully
  Main plan: specs/plans/025_feature/025_feature.md
```

### Collapse Phase 5 (Last Phase)

```bash
/collapse-phase specs/plans/025_feature/ 5
```

**Output:**
```
Collapsing Phase 5 from plan: 025_feature/
  - Reading phase file: phase_5_deployment.md
  - Merging content into main plan
  - Removing phase file
  - This was the LAST expanded phase (Level 1 → 0)
  - Moving main plan to root: 025_feature.md
  - Deleting empty directory: 025_feature/
  - Updating metadata: Structure Level = 0

✓ Phase 5 collapsed successfully
  Main plan: specs/plans/025_feature.md
```

## Safety Features

- **Content preservation**: All tasks and completion status preserved
- **Backup recommendation**: Consider backing up before collapse
- **Validation**: Multiple checks ensure data integrity
- **Atomic operations**: Uses temp files to prevent partial failures
- **Idempotent**: Safe to retry if operation fails partway

## Integration with Other Commands

### Used By
- User: Manual collapse when expansion no longer needed
- `/implement`: Could suggest collapse after phase completion

### Uses
- `parse-adaptive-plan.sh`: Structure detection and content merging
- Progressive planning utilities: Metadata management

### Complementary Commands
- `/expand-phase`: Opposite operation
- `/collapse-stage`: Must collapse stages before collapsing phase
- `/list-plans`: Show expansion status

## Standards Applied

Following CLAUDE.md Code Standards:
- **Error Handling**: Comprehensive validation and error messages
- **Documentation**: Clear operation description
- **File Operations**: Safe atomic operations with temp files

## Notes

- Phase files must not have expanded stages (Level 2) before collapse
- Collapsing a phase does NOT mark it as complete
- Task completion status is preserved during collapse
- Main plan structure is restored exactly as it was before expansion
- Collapse is fully reversible via `/expand-phase`
