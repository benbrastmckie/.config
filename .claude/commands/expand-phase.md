# Expand Phase Command

Expand a phase from inline content in the main plan to a separate file, creating directory structure as needed.

## Usage

```bash
/expand-phase <plan-path> <phase-num>
```

## Arguments

- `plan-path`: Path to the plan file or directory (e.g., `specs/plans/025_feature.md` or `specs/plans/025_feature/`)
- `phase-num`: The phase number to expand (e.g., `2`)

## Description

This command implements the progressive expansion workflow by:

1. **Detecting Structure Level**: Determines if this is the first phase expansion (Level 0 → 1)
2. **Creating Directory Structure**: If first expansion, creates plan directory and moves main plan into it
3. **Extracting Phase Content**: Parses the phase section from the main plan
4. **Creating Phase File**: Writes extracted content to `phase_N_name.md`
5. **Revising Main Plan**: Replaces phase content with summary and link to phase file
6. **Updating Metadata**: Updates Structure Level and Expanded Phases metadata
7. **Adding Update Reminder**: Adds reminder to phase file about marking completion in main plan

## Progressive Expansion Workflow

### Level 0 → Level 1 (First Phase Expansion)

**Before:**
```
specs/plans/025_feature.md          # Single file with all phases inline
```

**After:**
```
specs/plans/025_feature/            # Directory created
├── 025_feature.md                  # Main plan moved here, phase content replaced with summary
└── phase_2_implementation.md       # Extracted phase with full content
```

### Level 1 → Level 1 (Subsequent Phase Expansion)

**Before:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan
└── phase_2_implementation.md       # Already expanded
```

**After:**
```
specs/plans/025_feature/
├── 025_feature.md                  # Main plan, another phase replaced with summary
├── phase_2_implementation.md       # Unchanged
└── phase_5_deployment.md           # Newly extracted phase
```

## Phase Content Enhancement

The command doesn't just extract - it **enhances** phase content from 30-50 lines to 80-150 lines:

### Content Extraction

First, extracts the following from the main plan:

1. **Phase heading**: `### Phase N: Name`
2. **Objective**: The objective/description
3. **Complexity**: If present
4. **Tasks**: All task checkboxes
5. **Testing**: Test commands and expectations
6. **Expected Outcomes**: Outcome descriptions
7. **Dependencies**: If listed
8. **Status markers**: [PENDING], [IN_PROGRESS], [COMPLETED]

### Content Enhancement

Then, adds comprehensive implementation guidance:

1. **Expanded Objective** (3-5 paragraphs)
   - Context and background
   - Success criteria
   - Critical path analysis

2. **Implementation Guidance**
   - Detailed step-by-step instructions for each task
   - Approach patterns (audit, create, test, refactor)
   - Verification steps

3. **Complexity Analysis**
   - Calculated complexity score
   - Recommendations based on score
   - Stage expansion suggestion

4. **Edge Cases** (4-6 scenarios)
   - Input validation
   - Error conditions
   - Boundary conditions
   - Performance considerations (if complex)

5. **Cross-References**
   - Links to related phases
   - Parent plan reference

### Example Enhancement

**Before (30 lines)**:
```markdown
### Phase 3: Database Setup
**Objective**: Set up database schema
**Complexity**: Medium

#### Tasks
- [ ] Create schema
- [ ] Set up connections
- [ ] Add migrations
```

**After (120 lines)**:
```markdown
### Phase 3: Database Setup

## Metadata
- **Phase Number**: 3
- **Parent Plan**: project.md

**Objective**: Set up database schema
**Complexity**: Medium

[...original tasks...]

---

## Implementation Guidance

**Context**: This phase involves 3 major tasks focusing on implementation.
Success criteria: All tasks completed, tests passing, code meets standards.

### Detailed Steps

#### Step 1: Create schema
**Approach**:
1. Design component structure
2. Implement core functionality
3. Add error handling

**Verification**:
- Verify changes work as expected
- Run relevant tests

[...more steps...]

## Edge Cases and Error Handling
[4-6 scenarios with examples]

## Cross-References
[Links to related phases]

## Stage Expansion Recommendation
**Recommendation**: No
**Reason**: Manageable complexity (score: 6.9)
```

## Main Plan Revision

After extraction, the phase section in the main plan is replaced with:

```markdown
### Phase N: Name
**Objective**: [Brief objective]
**Status**: [PENDING]

For detailed tasks and implementation, see [Phase N Details](phase_N_name.md)
```

## Metadata Updates

### Main Plan Metadata

```markdown
## Metadata
- **Structure Level**: 1
- **Expanded Phases**: [2, 5]
- **Stage Expansion Candidates**: [3]  # Added if phase complexity >8 or tasks >10
```

### Phase File Metadata

```markdown
## Metadata
- **Phase Number**: 2
- **Parent Plan**: 025_feature.md

## Stage Expansion Recommendation
**Recommendation**: Yes|No
**Reason**: High complexity (score: 9.2, tasks: 12)
```

## Update Reminder

Each phase file receives:

```markdown
## Update Reminder
When phase complete, mark Phase 2 as [COMPLETED] in main plan: `025_feature.md`
```

## Validation Checks

Before expansion, the command verifies:
- Plan file exists
- Phase number is valid
- Phase is not already expanded
- Phase content can be parsed

After expansion, the command verifies:
- Directory structure created correctly
- Phase file written successfully
- Main plan updated correctly
- Metadata is consistent

## Error Handling

- **Plan not found**: Error with path guidance
- **Invalid phase number**: Error listing valid phases
- **Already expanded**: Warning, no action taken
- **Parse failure**: Error with content that failed to parse
- **Write failure**: Error with file system issue

## Examples

### Expand Phase 2 from Single File Plan

```bash
/expand-phase specs/plans/025_feature.md 2
```

**Output:**
```
Expanding Phase 2 from plan: 025_feature.md
  - This is the FIRST expansion (Level 0 → 1)
  - Creating directory: specs/plans/025_feature/
  - Moving main plan to directory
  - Extracting Phase 2: Implementation
  - Creating phase file: phase_2_implementation.md
  - Revising main plan to summary
  - Updating metadata: Structure Level = 1, Expanded Phases = [2]
  - Adding update reminder to phase file

✓ Phase 2 expanded successfully
  Main plan: specs/plans/025_feature/025_feature.md
  Phase file: specs/plans/025_feature/phase_2_implementation.md
```

### Expand Phase 5 from Directory Plan

```bash
/expand-phase specs/plans/025_feature/ 5
```

**Output:**
```
Expanding Phase 5 from plan: 025_feature/
  - Current level: 1
  - Extracting Phase 5: Deployment
  - Creating phase file: phase_5_deployment.md
  - Revising main plan to summary
  - Updating metadata: Expanded Phases = [2, 5]
  - Adding update reminder to phase file

✓ Phase 5 expanded successfully
  Phase file: specs/plans/025_feature/phase_5_deployment.md
```

## Implementation

I'll use the parsing utilities and implement the expansion logic following the progressive planning design:

```bash
#!/usr/bin/env bash

set -e

# Source parsing utilities
source "$(dirname "$0")/../utils/parse-adaptive-plan.sh"

# Parse arguments
plan_path="$1"
phase_num="$2"

if [[ -z "$plan_path" || -z "$phase_num" ]]; then
  echo "Usage: /expand-phase <plan-path> <phase-num>"
  exit 1
fi

# Normalize plan path
if [[ -d "$plan_path" ]]; then
  plan_file="$plan_path/$(basename "$plan_path").md"
else
  plan_file="$plan_path"
fi

# Validate plan exists
if [[ ! -f "$plan_file" ]]; then
  echo "Error: Plan file not found: $plan_file"
  exit 1
fi

# Detect structure level
current_level=$(detect_structure_level "$plan_file")

# Check if phase already expanded
if is_phase_expanded "$plan_path" "$phase_num"; then
  echo "Warning: Phase $phase_num is already expanded"
  exit 0
fi

# Extract phase content
phase_content=$(extract_phase_content "$plan_file" "$phase_num")
if [[ -z "$phase_content" ]]; then
  echo "Error: Could not extract Phase $phase_num from plan"
  exit 1
fi

# Determine if this is FIRST expansion (Level 0 → 1)
if [[ $current_level -eq 0 ]]; then
  echo "First expansion detected (Level 0 → 1)"

  # Create directory
  plan_dir="${plan_file%.md}"
  mkdir -p "$plan_dir"

  # Move main plan to directory
  mv "$plan_file" "$plan_dir/$(basename "$plan_file")"
  plan_file="$plan_dir/$(basename "$plan_file")"
fi

# Create phase file
phase_name=$(extract_phase_name "$plan_file" "$phase_num")
phase_file="$(dirname "$plan_file")/phase_${phase_num}_${phase_name}.md"

echo "$phase_content" > "$phase_file"

# Add metadata to phase file
add_phase_metadata "$phase_file" "$phase_num" "$(basename "$plan_file")"

# Add update reminder
add_update_reminder "$phase_file" "Phase $phase_num" "$(basename "$plan_file")"

# Revise main plan
revise_main_plan_for_phase "$plan_file" "$phase_num" "$(basename "$phase_file")"

# Update metadata
if [[ $current_level -eq 0 ]]; then
  update_structure_level "$plan_file" 1
fi
update_expanded_phases "$plan_file" "$phase_num"

echo "✓ Phase $phase_num expanded successfully"
echo "  Phase file: $phase_file"
```

## Integration with Other Commands

### Used By
- `/implement`: Suggests expansion when phase proves complex during implementation
- User: Manual expansion when planning reveals high complexity

### Uses
- `parse-adaptive-plan.sh`: Structure detection and content extraction
- Progressive planning utilities: Metadata management

### Complementary Commands
- `/expand-stage`: Further expand a phase into stages
- `/collapse-phase`: Reverse the expansion
- `/list-plans`: Show expansion status

## Standards Applied

Following CLAUDE.md Code Standards:
- **Indentation**: 2 spaces in generated markdown
- **Line length**: ~100 characters
- **Error Handling**: Validation checks before operations
- **Documentation**: Clear comments in implementation script

## Notes

- Phase files are named `phase_N_name.md` where name is derived from phase heading
- Original task completion status is preserved during extraction
- Main plan becomes a summary/index after first phase expansion
- Expansion is reversible via `/collapse-phase`
- Multiple phases can be expanded independently
