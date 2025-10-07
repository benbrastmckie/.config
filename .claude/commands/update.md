---
allowed-tools: Read, Edit, MultiEdit, Bash, Grep, Glob, WebSearch
argument-hint: [plan|report] <path> [reason-or-sections]
description: Update an existing implementation plan or research report
command-type: dependent
parent-commands: plan, report, implement
---

# Update Implementation Artifact

I'll update an existing implementation plan or research report with new requirements, modifications, or findings.

## Syntax

```bash
/update plan <plan-path> [reason-for-update]
/update report <report-path> [specific-sections]
```

## Types

- **plan**: Update implementation plan with new requirements or adjustments
- **report**: Update research report with new findings or current information

## Update Plan

### Plan to Update
- **Path**: $2 (second argument - plan path)
- **Reason**: $3 (optional - reason for update)

### Progressive Plan Support

Updates all three progressive structure levels:
- **Level 0**: Update single `.md` file
- **Level 1**: Update main plan and/or expanded phase files
- **Level 2**: Update main plan, phase files, and/or stage files

Structure detection uses `parse-adaptive-plan.sh detect_structure_level`.

### Plan Update Process

#### 1. Plan Analysis
```bash
# Detect plan structure level
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Check for expanded phases
EXPANDED_PHASES=$(.claude/lib/parse-adaptive-plan.sh list_expanded_phases "$PLAN_PATH")
```

Analyze the existing plan to understand:
- **Plan structure level**: L0, L1, or L2
- **Current structure**: Files/directories involved
- **Expanded phases/stages**: Which are in separate files
- **Completion status**: Per-phase status check
- **Technical design**: From appropriate file(s)
- **Original scope**: From metadata

#### 2. Update Assessment
Determine what needs updating:
- New requirements to incorporate
- Scope adjustments needed
- Technical approach changes
- Additional phases or tasks
- **Expansion needed**: If phase complexity increases significantly
- Testing strategy modifications

#### 3. Standards Compliance
Ensure updates follow:
- Project coding standards (CLAUDE.md)
- Progressive structure conventions
- Phase numbering conventions
- Task checkbox format
- Cross-reference integrity

#### 4. Plan Updates (Level-Aware)

**Level 0 (Single File)**:
- Update single `.md` file with Edit tool
- Add new phases/tasks inline
- Update metadata if complexity changes
- Consider using `/expand phase` if a phase grows too large

**Level 1 (Phase-Expanded)**:
- If phase is expanded: Update phase file
- If phase is inline: Update main plan
- Add new phases to main plan initially
- Use `/expand phase` for complex additions
- Maintain links between main plan and phase files

**Level 2 (Stage-Expanded)**:
- Update appropriate stage files or phase overview
- Add new stages to phase overview initially
- Use `/expand stage` for complex stage additions
- Maintain complete cross-reference hierarchy

#### 5. Expansion Recommendations
If complexity increases during update:
- Recommend `/expand phase <plan> <phase-num>` for complex phases
- Recommend `/expand stage <phase> <stage-num>` for complex stages
- Note in update history which phases might benefit from expansion

#### 6. Version Tracking (Plans)
Each update includes:
```markdown
## Update History

### [YYYY-MM-DD] - [Brief description]
- What changed
- Why it changed
- Impact on implementation
```

### Plan Update Types

**Adding New Phase**:
- Insert at appropriate position
- Renumber subsequent phases if needed
- Maintain task checkbox format
- Include testing requirements

**Modifying Existing Phase**:
- Preserve completed task checkmarks
- Add new tasks with `- [ ]`
- Update complexity if needed
- Revise testing approach

**Scope Changes**:
- Update overview section
- Revise success criteria
- Adjust phase objectives
- Document reasoning

## Update Report

### Report to Update
- **Path**: $2 (second argument - report path)
- **Sections**: $3 (optional - specific sections to update)

### Report Update Process

#### 1. Report Analysis
Read the existing report to understand:
- Original scope and findings
- Report structure and sections
- Previous recommendations
- Last update date

#### 2. Change Detection
Identify what has changed since the report was created:
- Modified files in the relevant area
- New implementations or features
- Resolved issues or completed recommendations
- Updated best practices or patterns

#### 3. Research Updates
Conduct focused research on:
- Changes identified above
- New developments in the topic area
- Updated dependencies or requirements
- Current state vs. previous findings

#### 4. Report Updates
Update the report by:
- Adding an "Updates" section with the current date
- Revising findings that have changed
- Adding new discoveries and insights
- Updating recommendations based on current state
- Preserving historical context where valuable

#### 5. Version Tracking (Reports)
Each update includes:
```markdown
## Updates

### [YYYY-MM-DD] Update
**Reason**: [Why the update was needed]
**Changes Analyzed**: [What was reviewed]

#### Key Changes
- [Change 1]
- [Change 2]

#### Revised Findings
[Updated analysis]

#### New Recommendations
[Based on current state]
```

## Shared Update Logic

### Metadata Update
Both plans and reports share metadata update patterns:
- Update "Last Modified" or "Date" field
- Increment version if tracked
- Update status if changed
- Preserve all other metadata fields

### Content Modification Workflow
1. Read existing artifact
2. Identify sections to modify
3. Apply changes with Edit tool
4. Preserve formatting and structure
5. Verify cross-references remain valid

## Implementation

### Type Detection
```bash
TYPE="$1"  # First argument: "plan" or "report"
PATH="$2"  # Second argument: path to artifact
ARG3="$3"  # Third argument: reason or sections

if [[ "$TYPE" != "plan" && "$TYPE" != "report" ]]; then
  echo "ERROR: First argument must be 'plan' or 'report'"
  echo "Usage: /update [plan|report] <path> [reason-or-sections]"
  exit 1
fi

if [[ -z "$PATH" ]]; then
  echo "ERROR: Path required"
  echo "Usage: /update [plan|report] <path> [reason-or-sections]"
  exit 1
fi
```

### Plan-Specific Implementation
```bash
if [[ "$TYPE" == "plan" ]]; then
  # Detect structure level
  LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PATH")

  # Read plan metadata
  source .claude/lib/artifact-utils.sh
  METADATA=$(get_plan_metadata "$PATH")

  # Apply plan updates...
fi
```

### Report-Specific Implementation
```bash
if [[ "$TYPE" == "report" ]]; then
  # Read report metadata
  source .claude/lib/artifact-utils.sh
  METADATA=$(get_report_metadata "$PATH")

  # Apply report updates...
fi
```

## Examples

### Update plan with new requirements
```bash
/update plan .claude/specs/plans/025_feature.md "Add authentication requirements"
```

### Update report with new findings
```bash
/update report .claude/specs/reports/010_security_analysis.md "Authentication section"
```

### Update expanded plan
```bash
/update plan .claude/specs/plans/033_consolidation/ "Revise Phase 4 scope"
```

## Standards Applied

Following CLAUDE.md standards:
- **Progressive Support**: Full L0/L1/L2 plan awareness
- **Metadata Preservation**: All metadata fields maintained
- **Cross-References**: Verify all links remain valid
- **Version Tracking**: Document all changes with timestamps

Let me update the requested artifact based on its type.
