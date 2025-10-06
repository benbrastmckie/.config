# Expand Stage Command

Expand a stage from inline content in a phase file to a separate file, creating phase directory structure as needed.

## Usage

```bash
/expand-stage <phase-path> <stage-num>
```

## Arguments

- `phase-path`: Path to the phase file or directory (e.g., `specs/plans/025_feature/phase_2_impl.md` or `specs/plans/025_feature/phase_2_impl/`)
- `stage-num`: The stage number to expand (e.g., `1`)

## Description

This command implements stage-level progressive expansion by:

1. **Detecting Phase Level**: Determines if this is the first stage expansion (Level 1 → 2)
2. **Creating Phase Directory**: If first expansion, creates phase directory and moves phase file into it
3. **Extracting Stage Content**: Parses the stage section from the phase file
4. **Creating Stage File**: Writes extracted content to `stage_N_name.md`
5. **Revising Phase File**: Replaces stage content with summary and link to stage file
6. **Updating Metadata**: Updates Expanded Stages in both phase and main plan
7. **Adding Update Reminder**: Adds reminder to stage file about marking completion in phase file

## Progressive Expansion Workflow

### Level 1 → Level 2 (First Stage Expansion)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
└── phase_2_implementation.md       # Phase with all stages inline
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan, metadata updated
└── phase_2_implementation/         # Phase directory created
    ├── phase_2_implementation.md   # Phase file moved here, stage content replaced with summary
    └── stage_1_backend.md          # Extracted stage with full content
```

### Level 2 → Level 2 (Subsequent Stage Expansion)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md
└── phase_2_implementation/
    ├── phase_2_implementation.md
    └── stage_1_backend.md          # Already expanded
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Metadata updated
└── phase_2_implementation/
    ├── phase_2_implementation.md   # Another stage replaced with summary
    ├── stage_1_backend.md          # Unchanged
    └── stage_2_frontend.md         # Newly extracted stage
```

## Stage Content Extraction

The command extracts the following from the phase file:

1. **Stage heading**: `#### Stage N: Name`
2. **Objective**: If present
3. **Tasks**: All task checkboxes
4. **Dependencies**: If listed
5. **Status markers**: [PENDING], [IN_PROGRESS], [COMPLETED]

## Phase File Revision

After extraction, the stage section in the phase file is replaced with:

```markdown
#### Stage N: Name
**Objective**: [Brief objective]

For detailed tasks, see [Stage N Details](stage_N_name.md)
```

## Metadata Updates

### Phase File Metadata

```markdown
## Metadata
- **Phase Number**: 2
- **Parent Plan**: 025_feature.md
- **Expanded Stages**: [1, 2]
```

### Stage File Metadata

```markdown
## Metadata
- **Stage Number**: 1
- **Parent Phase**: phase_2_implementation.md
```

### Main Plan Metadata Update

The main plan's metadata is also updated:

```markdown
- **Expanded Stages**: {2: [1, 2], 5: [1]}
```

## Update Reminder

Each stage file receives:

```markdown
## Update Reminder
When stage complete, mark Stage 1 as [COMPLETED] in phase file: `phase_2_implementation.md`
```

## Validation Checks

Before expansion, the command verifies:
- Phase file exists
- Stage number is valid
- Stage is not already expanded
- Stage content can be parsed

After expansion, the command verifies:
- Phase directory created correctly
- Stage file written successfully
- Phase file updated correctly
- Metadata is consistent in phase and main plan

## Error Handling

- **Phase not found**: Error with path guidance
- **Invalid stage number**: Error listing valid stages
- **Already expanded**: Warning, no action taken
- **Parse failure**: Error with content that failed to parse
- **Write failure**: Error with file system issue

## Examples

### Expand Stage 1 from Phase File

```bash
/expand-stage specs/plans/025_feature/phase_2_implementation.md 1
```

**Output:**
```
Expanding Stage 1 from phase: phase_2_implementation.md
  - This is the FIRST stage expansion in this phase (Level 1 → 2)
  - Creating phase directory: phase_2_implementation/
  - Moving phase file to directory
  - Extracting Stage 1: Backend
  - Creating stage file: stage_1_backend.md
  - Revising phase file to summary
  - Updating phase metadata: Expanded Stages = [1]
  - Updating main plan metadata: Expanded Stages = {2: [1]}
  - Adding update reminder to stage file

✓ Stage 1 expanded successfully
  Phase file: specs/plans/025_feature/phase_2_implementation/phase_2_implementation.md
  Stage file: specs/plans/025_feature/phase_2_implementation/stage_1_backend.md
```

### Expand Stage 2 from Phase Directory

```bash
/expand-stage specs/plans/025_feature/phase_2_implementation/ 2
```

**Output:**
```
Expanding Stage 2 from phase: phase_2_implementation/
  - Current phase level: 2
  - Extracting Stage 2: Frontend
  - Creating stage file: stage_2_frontend.md
  - Revising phase file to summary
  - Updating phase metadata: Expanded Stages = [1, 2]
  - Updating main plan metadata: Expanded Stages = {2: [1, 2]}
  - Adding update reminder to stage file

✓ Stage 2 expanded successfully
  Stage file: specs/plans/025_feature/phase_2_implementation/stage_2_frontend.md
```

## Implementation

Uses the parsing utilities and implements stage expansion logic following progressive planning design.

## Integration with Other Commands

### Used By
- `/implement`: Suggests stage expansion when stage proves complex during implementation
- `/expand-phase`: Often followed by stage expansion for detailed phases

### Uses
- `parse-adaptive-plan.sh`: Structure detection and content extraction
- Progressive planning utilities: Metadata management

### Complementary Commands
- `/expand-phase`: Precursor to stage expansion
- `/collapse-stage`: Reverse the expansion
- `/list-plans`: Show expansion status

## Standards Applied

Following CLAUDE.md Code Standards:
- **Indentation**: 2 spaces in generated markdown
- **Line length**: ~100 characters
- **Error Handling**: Validation checks before operations
- **Documentation**: Clear comments in implementation

## Notes

- Stage files are named `stage_N_name.md` where name is derived from stage heading
- Original task completion status is preserved during extraction
- Phase file becomes a summary/index after first stage expansion
- Expansion is reversible via `/collapse-stage`
- Multiple stages can be expanded independently
- Main plan metadata tracks which phases have stage expansions
