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

## Adaptive Plan Support

This command updates all three plan structure tiers:
- **Tier 1**: Update single `.md` file
- **Tier 2**: Update overview and/or phase files
- **Tier 3**: Update overview, phase overviews, and/or stage files

Tier detection uses `parse-adaptive-plan.sh detect_tier`.

## Update Process

### 1. Plan Analysis (Tier-Aware)
```bash
# Detect plan tier
TIER=$(.claude/utils/parse-adaptive-plan.sh detect_tier "$PLAN_PATH")

# Get plan overview (works for all tiers)
OVERVIEW=$(.claude/utils/parse-adaptive-plan.sh get_overview "$PLAN_PATH")

# Read plan structure
PHASES=$(.claude/utils/parse-adaptive-plan.sh list_phases "$PLAN_PATH")
```

I'll analyze the existing plan to understand:
- **Plan tier**: T1, T2, or T3
- **Current structure**: Files/directories involved
- **Phases and tasks**: Using parsing utility
- **Completion status**: Per-phase status check
- **Technical design**: From overview file
- **Original scope**: From metadata

### 2. Update Assessment
I'll determine what needs updating:
- New requirements to incorporate
- Scope adjustments needed
- Technical approach changes
- Additional phases or tasks
- **Tier migration needed**: If complexity increases significantly
- Testing strategy modifications

### 3. Standards Compliance
I'll ensure updates follow:
- Project coding standards (CLAUDE.md)
- Tier-appropriate plan structure
- Phase numbering conventions
- Task checkbox format
- Cross-reference integrity (Tier 2/3)

### 4. Plan Updates (Tier-Specific)

**Tier 1 (Single File)**:
- Update single `.md` file with Edit tool
- Add new phases/tasks inline
- Update metadata if complexity changes
- Consider tier migration if plan grows too large

**Tier 2 (Phase Directory)**:
- Update overview file for structural changes
- Add/modify phase files as needed
- Create new `phase_N_name.md` for new phases
- Update cross-references in overview
- Maintain links between overview and phase files

**Tier 3 (Hierarchical Tree)**:
- Update main overview for high-level changes
- Add/modify phase directories as needed
- Create new stage files within phases
- Update phase overviews with stage links
- Maintain complete cross-reference hierarchy

### 5. Tier Migration Support
If complexity increases beyond current tier threshold:
- **T1 → T2**: Convert to phase-directory structure
- **T2 → T3**: Add phase subdirectories with stage files
- Preserve all content and completion status
- Update all cross-references
- Note migration in update history

### 5. Version Tracking
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