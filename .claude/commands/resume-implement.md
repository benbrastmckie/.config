---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: [plan-file] [phase-number]
description: Resume implementation from the most recent incomplete plan or a specific plan/phase
command-type: secondary
dependent-commands: implement, list-plans, update-plan
---

# Resume Implementation

I'll help you resume an incomplete implementation plan from where you left off.

## How It Works

### Without Arguments:
When you run `/resume-implement` with no arguments, I will:
1. **Find the most recent incomplete plan** by:
   - Searching all `specs/plans/` directories
   - Sorting by modification time (newest first)
   - Checking for incomplete markers
2. **Identify the resume point**:
   - Find the first phase without `[COMPLETED]`
   - Or find the first unchecked task `- [ ]`
3. **Continue implementation** from that point

### With Plan File Only:
`/resume-implement <plan-file>`
- Resume the specified plan from its first incomplete phase

### With Plan and Phase:
`/resume-implement <plan-file> <phase-number>`
- Resume the specified plan from the specified phase

## Detection Patterns

### Incomplete Plan Markers:
- Unchecked tasks: `- [ ]`
- Phases without `[COMPLETED]` suffix
- Absence of `## ✅ IMPLEMENTATION COMPLETE` header

### Complete Plan Markers:
- All tasks checked: `- [x]`
- All phases marked: `Phase N [COMPLETED]`
- Header contains: `## ✅ IMPLEMENTATION COMPLETE`

## Auto-Discovery Process

```bash
# Find most recent plans
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null | head -10

# Check each for incomplete status
grep -l "- \[ \]" <file>  # Has unchecked tasks
grep -L "IMPLEMENTATION COMPLETE" <file>  # Not marked complete
```

## Resume Behavior

When resuming, I will:
1. **Show plan status**:
   - Display completed phases
   - Show current phase to resume
   - List remaining tasks
2. **Continue from breakpoint**:
   - Skip completed phases/tasks
   - Start with first incomplete item
3. **Maintain continuity**:
   - Reference previous commits
   - Continue numbering sequence
   - Update summary if exists

## Example Usage

```bash
# Resume most recent incomplete plan
/resume-implement

# Resume specific plan from where it left off
/resume-implement specs/plans/feature-authentication.md

# Resume from specific phase
/resume-implement specs/plans/feature-authentication.md 3
```

## Relationship to /implement

This command is equivalent to:
- `/implement` (with no args) - Both auto-detect incomplete plans
- `/implement <plan>` - When plan has incomplete phases
- `/implement <plan> <phase>` - With explicit phase specification

The main difference is that `/resume-implement` is more explicit about continuing previous work, while `/implement` can be used for both new and resuming implementations.

Let me find and resume your incomplete implementation plan.