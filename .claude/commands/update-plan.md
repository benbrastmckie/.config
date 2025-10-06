---
allowed-tools: Read, Edit, MultiEdit, Bash, Grep
argument-hint: <plan-path> [reason-for-update]
description: Update an existing implementation plan with new requirements or adjustments
command-type: dependent
parent-commands: plan, implement
---

# Update Implementation Plan

I'll update an existing implementation plan with new requirements or modifications.

## Plan to Update
- **Path**: $1
- **Reason**: $2

## Progressive Plan Support

This command updates all three progressive structure levels:
- **Level 0**: Update single `.md` file
- **Level 1**: Update main plan and/or expanded phase files
- **Level 2**: Update main plan, phase files, and/or stage files

Structure detection uses `parse-adaptive-plan.sh detect_structure_level`.

## Update Process

### 1. Plan Analysis
```bash
# Detect plan structure level
LEVEL=$(.claude/utils/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Check for expanded phases
EXPANDED_PHASES=$(.claude/utils/parse-adaptive-plan.sh list_expanded_phases "$PLAN_PATH")
```

I'll analyze the existing plan to understand:
- **Plan structure level**: L0, L1, or L2
- **Current structure**: Files/directories involved
- **Expanded phases/stages**: Which are in separate files
- **Completion status**: Per-phase status check
- **Technical design**: From appropriate file(s)
- **Original scope**: From metadata

### 2. Update Assessment
I'll determine what needs updating:
- New requirements to incorporate
- Scope adjustments needed
- Technical approach changes
- Additional phases or tasks
- **Expansion needed**: If phase complexity increases significantly
- Testing strategy modifications

### 3. Standards Compliance
I'll ensure updates follow:
- Project coding standards (CLAUDE.md)
- Progressive structure conventions
- Phase numbering conventions
- Task checkbox format
- Cross-reference integrity

### 4. Plan Updates (Level-Aware)

**Level 0 (Single File)**:
- Update single `.md` file with Edit tool
- Add new phases/tasks inline
- Update metadata if complexity changes
- Consider using `/expand-phase` if a phase grows too large

**Level 1 (Phase-Expanded)**:
- If phase is expanded: Update phase file
- If phase is inline: Update main plan
- Add new phases to main plan initially
- Use `/expand-phase` for complex additions
- Maintain links between main plan and phase files

**Level 2 (Stage-Expanded)**:
- Update appropriate stage files or phase overview
- Add new stages to phase overview initially
- Use `/expand-stage` for complex stage additions
- Maintain complete cross-reference hierarchy

### 5. Expansion Recommendations
If complexity increases during update:
- Recommend `/expand-phase <plan> <phase-num>` for complex phases
- Recommend `/expand-stage <phase> <stage-num>` for complex stages
- Note in update history which phases might benefit from expansion

### 6. Version Tracking
Each update will include:
```markdown
## Update History

### [YYYY-MM-DD] - [Brief description]
- What changed
- Why it changed
- Impact on implementation
```

## Update Types

### Adding New Phase
- Insert at appropriate position
- Renumber subsequent phases if needed
- Maintain task checkbox format
- Include testing requirements

### Modifying Existing Phase
- Preserve completed task checkmarks
- Add new tasks with `- [ ]`
- Update complexity if needed
- Revise testing approach

### Scope Changes
- Update overview section
- Revise success criteria
- Adjust phase objectives
- Document reasoning

Let me read and update your implementation plan.