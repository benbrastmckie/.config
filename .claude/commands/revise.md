---
command-type: primary
dependent-commands: list-plans, list-reports
description: Revise the most recently discussed plan with user-provided changes (no implementation)
argument-hint: <revision-details> [report-path1] [report-path2] ...
allowed-tools: Read, Write, Edit, Glob, Grep, Task, MultiEdit, TodoWrite
---

# /revise Command

Revises the most recently discussed implementation plan according to user-provided details, optionally incorporating insights from research reports. **This command only modifies the plan file - it does not implement any changes.**

## Usage

```
/revise <revision-details> [report-path1] [report-path2] ...
```

### Arguments

- `<revision-details>` (required): Description of changes to make to the plan
- `[report-path1] [report-path2] ...` (optional): Paths to research reports to guide the revision

## Examples

### Basic Revision
```
/revise "Add error handling phases and update testing approach"
```

### Revision with Reports
```
/revise "Incorporate security best practices" specs/reports/001_security_analysis.md
```

### Multiple Reports
```
/revise "Update based on performance findings" specs/reports/002_performance.md specs/reports/003_optimization.md
```

## Important Notes

### What This Command Does
- **Modifies the plan file** with your requested changes
- **Preserves completion status** of already-executed phases
- **Adds revision history** to track changes
- **Creates a backup** of the original plan
- **Updates phase details** based on your revision requirements

### What This Command Does NOT Do
- **Does NOT execute any code changes**
- **Does NOT run tests**
- **Does NOT create commits**
- **Does NOT implement the plan**

To implement the revised plan after revision, use `/implement [plan-file]`

## Process

1. **Plan Discovery**
   - Identifies the most recent plan mentioned in the current conversation
   - Searches conversation history for plan file references (e.g., `001_plan_feature.md`)
   - Falls back to the most recently modified plan if none mentioned
   - Looks in `specs/plans/` directory
   - Identifies plans by `*_plan_*.md` or `*_*_plan.md` patterns

2. **Report Integration** (if provided)
   - Reads specified research reports
   - Extracts relevant recommendations and findings
   - Incorporates insights into revision strategy

3. **Revision Application**
   - Preserves plan metadata and structure
   - Updates phases based on revision details
   - Maintains completion status where appropriate
   - Adds revision notes with timestamp

4. **Documentation**
   - Adds revision history section if not present
   - Documents what changed and why
   - References any reports used for guidance

## Plan Structure Preservation

The command maintains:
- Original metadata (date, feature, scope)
- Phase numbering and dependencies
- Completion markers for executed phases
- Success criteria and risk assessments

## Revision History Format

Adds a section like:
```markdown
## Revision History

### [Date] - Revision 1
**Changes**: Description of what was revised
**Reason**: Why the revision was needed
**Reports Used**: List of reports that guided the revision
**Modified Phases**: List of phases that were updated
```

## Error Handling

- **No Plans Found**: Suggests creating a plan first with `/plan`
- **Invalid Report Paths**: Lists which reports couldn't be found
- **Malformed Plan**: Preserves original and creates backup before revision

## Integration with Other Commands

- Use `/list-plans` to see all available plans before choosing one to revise
- Use `/list-reports` to find relevant research reports for guidance
- After revision, use `/implement` to execute the updated plan

## Best Practices

1. **Be Specific**: Provide clear revision details for what should change in the plan
2. **Use Reports**: Reference research reports for evidence-based revisions
3. **Preserve Progress**: Don't remove completion markers for already-executed phases
4. **Document Changes**: The revision history helps track plan evolution
5. **Review Before Implementation**: After revising, review the plan before using `/implement`
6. **Keep Revisions Focused**: Make targeted changes rather than rewriting entire plans

## Notes

- **Plan-only operation**: This command ONLY modifies the plan document, no code changes
- **Conversation-aware**: Prioritizes plans mentioned in the current conversation
- **Backup creation**: Always creates a backup of the original plan before revision
- **Implementation-ready**: Maintains compatibility with `/implement` command
- **Section preservation**: Preserves any custom sections added to the plan
- **Audit trail**: Revision details become part of the plan's permanent history
- **No auto-implementation**: You must explicitly run `/implement` after revising if you want to execute the plan