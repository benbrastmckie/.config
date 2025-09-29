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

## Update Process

### 1. Plan Analysis
I'll first read the existing plan to understand:
- Current phases and tasks
- Completion status (checked vs unchecked tasks)
- Technical design decisions
- Original scope and objectives

### 2. Update Assessment
I'll determine what needs updating:
- New requirements to incorporate
- Scope adjustments needed
- Technical approach changes
- Additional phases or tasks
- Testing strategy modifications

### 3. Standards Compliance
I'll ensure updates follow:
- Project coding standards (CLAUDE.md)
- Existing plan format and structure
- Phase numbering conventions
- Task checkbox format

### 4. Plan Updates
I'll update the plan by:
- Adding new phases if needed
- Inserting tasks into existing phases
- Updating technical design sections
- Revising success criteria
- Adding update notes with timestamp

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