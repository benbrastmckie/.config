# Collapse Stage Command

Merge an expanded stage file back into the phase file and clean up phase directory if this was the last expanded stage.

## Usage

```bash
/collapse-stage <phase-path> <stage-num>
```

## Arguments

- `phase-path`: Path to the phase directory (e.g., `specs/plans/025_feature/phase_2_impl/`)
- `stage-num`: The stage number to collapse (e.g., `1`)

## Description

This command reverses stage expansion by:

1. **Reading Stage File Content**: Extracts full content from expanded stage file
2. **Merging into Phase File**: Replaces summary in phase file with full stage content
3. **Deleting Stage File**: Removes the stage file after successful merge
4. **Checking Last Stage**: Determines if this was the last expanded stage
5. **Directory Cleanup**: If last stage, moves phase file back to parent and deletes directory
6. **Updating Metadata**: Updates Expanded Stages in both phase file and main plan

## Progressive Collapse Workflow

### Level 2 → Level 2 (Collapse Non-Last Stage)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Phase file
    ├── stage_1_backend.md          # Stage to collapse
    └── stage_2_frontend.md         # Another expanded stage
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Metadata updated
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Stage 1 content merged back
    └── stage_2_frontend.md         # Unchanged
```

### Level 2 → Level 1 (Collapse Last Stage)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Phase file
    └── stage_1_backend.md          # Last expanded stage
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Metadata updated
└── phase_2_implementation.md       # Moved to parent, all content inline
```

## Content Merging

The command merges the following from the stage file:

1. **Stage heading**: Restored from stage file
2. **Objective**: If present
3. **Tasks**: All task checkboxes with preserved completion status
4. **Dependencies**: If present
5. **Status markers**: Preserved [PENDING], [IN_PROGRESS], [COMPLETED]

## Phase File Update

After merging, the stage section in the phase file is restored to full content:

```markdown
#### Stage N: Name
**Objective**: [Full objective text]

Tasks:
- [x] Completed task
- [ ] Pending task
```

## Metadata Updates

### Phase File Metadata (Non-Last Stage)

```markdown
## Metadata
- **Phase Number**: 2
- **Parent Plan**: 025_feature.md
- **Expanded Stages**: [2]  # Stage 1 removed
```

### Phase File Metadata (Last Stage)

```markdown
## Metadata
- **Phase Number**: 2
- **Parent Plan**: 025_feature.md
# Expanded Stages removed
```

### Main Plan Metadata Update

The main plan's Expanded Stages dict is also updated:

**Non-Last Stage:**
```markdown
- **Expanded Stages**: {2: [2], 5: [1]}  # Stage 1 of phase 2 removed
```

**Last Stage of Phase:**
```markdown
- **Expanded Stages**: {5: [1]}  # Phase 2 entry removed entirely
```

## Directory Cleanup

When collapsing the last expanded stage:

1. **Move phase file**: From `phase_2_implementation/phase_2_implementation.md` to `phase_2_implementation.md`
2. **Delete directory**: Remove `phase_2_implementation/`
3. **Update paths**: Adjust metadata references

## Validation Checks

Before collapse, the command verifies:
- Phase directory exists
- Stage file exists and is readable
- Stage number is valid

After collapse, the command verifies:
- Content successfully merged
- Stage file deleted
- Metadata updated in both phase and main plan
- If last stage, directory cleaned up

## Error Handling

- **Phase not found**: Error with path guidance
- **Stage file not found**: Error listing available stages
- **Merge failure**: Error with backup information
- **Delete failure**: Warning, manual cleanup may be needed

## Examples

### Collapse Stage 1 (Not Last Stage)

```bash
/collapse-stage specs/plans/025_feature/phase_2_implementation/ 1
```

**Output:**
```
Collapsing Stage 1 from phase: phase_2_implementation/
  - Reading stage file: stage_1_backend.md
  - Merging content into phase file
  - Removing stage file
  - Updating phase metadata: Expanded Stages = [2]
  - Updating main plan metadata: Expanded Stages = {2: [2], 5: [1]}
  - Phase directory retained (other expanded stages exist)

✓ Stage 1 collapsed successfully
  Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md
```

### Collapse Stage 2 (Last Stage)

```bash
/collapse-stage specs/plans/025_feature/phase_2_implementation/ 2
```

**Output:**
```
Collapsing Stage 2 from phase: phase_2_implementation/
  - Reading stage file: stage_2_frontend.md
  - Merging content into phase file
  - Removing stage file
  - This was the LAST expanded stage (Level 2 → 1)
  - Moving phase file to parent: phase_2_implementation.md
  - Deleting empty directory: phase_2_implementation/
  - Updating phase metadata: removed Expanded Stages
  - Updating main plan metadata: removed phase 2 from Expanded Stages

✓ Stage 2 collapsed successfully
  Phase file: specs/plans/025_feature/phase_2_implementation.md
```

## Safety Features

- **Content preservation**: All tasks and completion status preserved
- **Backup recommendation**: Consider backing up before collapse
- **Validation**: Multiple checks ensure data integrity
- **Atomic operations**: Uses temp files to prevent partial failures
- **Idempotent**: Safe to retry if operation fails partway

## Integration with Other Commands

### Used By
- User: Manual collapse when stage expansion no longer needed
- `/collapse-phase`: Requires all stages collapsed first

### Uses
- `parse-adaptive-plan.sh`: Structure detection and content merging
- Progressive planning utilities: Metadata management

### Complementary Commands
- `/expand-stage`: Opposite operation
- `/collapse-phase`: Used after collapsing all stages
- `/list-plans`: Show expansion status

## Standards Applied

Following CLAUDE.md Code Standards:
- **Error Handling**: Comprehensive validation and error messages
- **Documentation**: Clear operation description
- **File Operations**: Safe atomic operations with temp files

## Notes

- Stage files are merged back maintaining original format
- Collapsing a stage does NOT mark it as complete
- Task completion status is preserved during collapse
- Phase file structure is restored exactly as it was before stage expansion
- Collapse is fully reversible via `/expand-stage`
- Must collapse all stages before collapsing the phase itself
