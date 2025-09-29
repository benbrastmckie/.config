---
allowed-tools: Bash, Glob, Read
argument-hint: [search-pattern]
description: List all implementation plans in the codebase
command-type: dependent
parent-commands: implement
---

# List Implementation Plans

I'll find and list all implementation plans across the codebase.

## Search Pattern
$1 (optional filter)

## Process

I'll search for all plans in `specs/plans/` directories and provide:

### 1. Plan Inventory
- Location of each plan
- Plan number and title
- Creation date
- Implementation status (if trackable)
- Number of phases

### 2. Organization
- Group by directory/module
- Sort by number (chronological order)
- Show completion status where available
- Highlight plans matching search pattern

### 3. Summary Statistics
- Total number of plans
- Plans by status (pending, in-progress, completed)
- Most recent plans
- Module coverage

### 4. Quick Access
For each plan, I'll show:
- Full path for easy access
- Brief description from overview
- Phase count and complexity
- `/implement` command to execute

Let me search for all implementation plans in your codebase.