---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: [plan-file] [starting-phase]
description: Execute implementation plan with automated testing and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list-plans, update-plan, list-summaries, revise, debug, document
---

# Execute Implementation Plan

I'll help you systematically implement the plan file with automated testing and commits at each phase.

## Plan Information
- **Plan file**: $1 (or I'll find the most recent incomplete plan)
- **Starting phase**: $2 (default: resume from last incomplete phase or 1)

## Auto-Resume Feature
If no plan file is provided, I will:
1. Search for the most recently modified implementation plan
2. Check if it has incomplete phases or tasks
3. Resume from the first incomplete phase
4. If all recent plans are complete, show a list to choose from

## Process

Let me first locate the implementation plan:

1. **Parse the plan** to identify:
   - Phases and tasks
   - Referenced research reports (if any)
   - Standards file path
2. **Check for research reports**:
   - Extract report paths from plan metadata
   - Note reports for summary generation
3. **For each phase**:
   - Display the phase name and tasks
   - Implement the required changes
   - Run tests to verify the implementation
   - Update the plan file with completion markers
   - Create a git commit with a structured message
   - Move to the next phase
4. **After all phases complete**:
   - Generate implementation summary
   - Update referenced reports if needed
   - Link plan and reports in summary

## Phase Execution Protocol

For each phase, I will:

### 1. Display Phase Information
Show the current phase number, name, and all tasks that need to be completed.

### 2. Implementation
Create or modify the necessary files according to the plan specifications.

### 3. Testing
Run tests by:
- Looking for test commands in the phase tasks
- Checking for common test patterns (npm test, pytest, make test)
- Running language-specific test commands based on project type

### 4. Plan Update
- Mark completed tasks with `[x]` instead of `[ ]`
- Add `[COMPLETED]` marker to the phase heading
- Save the updated plan file

### 5. Git Commit
Create a structured commit:
```
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Test Detection Patterns

I'll look for and run:
- Commands containing `:lua.*test`
- Commands with `:Test`
- Standard test commands: `npm test`, `pytest`, `make test`
- Project-specific test commands based on configuration files

## Resuming Implementation

If we need to stop and resume later, you can use:
```
/implement <plan-file> <phase-number>
```

This will start from the specified phase number.

## Error Handling

If tests fail or issues arise:
1. I'll show the error details
2. We'll fix the issues together
3. Re-run tests before proceeding
4. Only move forward when tests pass

## Summary Generation

After completing all phases, I'll:

### 1. Create Summary Directory
- Location: Same directory as the plan, in `specs/summaries/`
- Create if it doesn't exist

### 2. Generate Summary File
- Format: `NNN_implementation_summary.md`
- Number matches the plan number
- Contains:
  - Implementation overview
  - Plan executed with link
  - Reports referenced (if any)
  - Key changes made
  - Test results
  - Lessons learned

### 3. Update Reports (if referenced)
If the plan referenced research reports:
- Add implementation notes to each report
- Cross-reference the summary
- Note which recommendations were implemented

### Summary Format
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Plan**: [Link to plan file]
- **Research Reports**: [Links to reports used]
- **Phases Completed**: [N/N]

## Implementation Overview
[Brief description of what was implemented]

## Key Changes
- [Major change 1]
- [Major change 2]

## Test Results
[Summary of test outcomes]

## Report Integration
[How research informed implementation]

## Lessons Learned
[Insights from implementation]
```

## Finding the Implementation Plan

### Auto-Detection Logic (when no arguments provided):
```bash
# 1. Find all plan files, sorted by modification time
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null

# 2. For each plan, check for incomplete markers:
# - Look for unchecked tasks: "- [ ]"
# - Look for phases without [COMPLETED] marker
# - Skip plans marked with "IMPLEMENTATION COMPLETE"

# 3. Select the first incomplete plan
```

### If no plan file provided:
I'll search for the most recent incomplete implementation plan by:
1. Looking in all `specs/plans/` directories
2. Sorting by modification time (most recent first)
3. Checking each plan for:
   - Unchecked tasks `- [ ]`
   - Phases without `[COMPLETED]` marker
   - Absence of `IMPLEMENTATION COMPLETE` header
4. Selecting the first incomplete plan found
5. Determining the first incomplete phase to resume from

### If a plan file is provided:
I'll use the specified plan file directly and:
1. Check its completion status
2. Find the first incomplete phase (if any)
3. Resume from that phase or start from phase 1

### Plan Status Detection Patterns:
- **Complete Plan**: Contains `## ✅ IMPLEMENTATION COMPLETE` or all phases marked `[COMPLETED]`
- **Incomplete Phase**: Phase heading without `[COMPLETED]` marker
- **Incomplete Task**: Checklist item with `- [ ]` instead of `- [x]`

Let me start by finding your implementation plan.
