---
allowed-tools: Read, Edit, MultiEdit, Bash, Grep, Glob, WebSearch
argument-hint: <report-path> [specific-sections]
description: Update an existing research report with new findings
command-type: dependent
parent-commands: report, implement
---

# Update Research Report

I'll update an existing report with new findings and current information.

## Report to Update
- **Path**: $1
- **Sections**: $2 (optional - specific sections to update)

## Update Process

### 1. Report Analysis
I'll first read the existing report to understand:
- Original scope and findings
- Report structure and sections
- Previous recommendations
- Last update date

### 2. Change Detection
I'll identify what has changed since the report was created:
- Modified files in the relevant area
- New implementations or features
- Resolved issues or completed recommendations
- Updated best practices or patterns

### 3. Research Updates
I'll conduct focused research on:
- Changes identified above
- New developments in the topic area
- Updated dependencies or requirements
- Current state vs. previous findings

### 4. Report Updates
I'll update the report by:
- Adding an "Updates" section with the current date
- Revising findings that have changed
- Adding new discoveries and insights
- Updating recommendations based on current state
- Preserving historical context where valuable

### 5. Version Tracking
Each update will include:
- Update timestamp
- Summary of changes
- Reason for update
- Files re-analyzed

## Update Format

Updates will be added as:

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

Let me read the existing report and begin the update process.