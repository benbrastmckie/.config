---
allowed-tools: Bash, Glob, Read
argument-hint: [search-pattern]
description: List all existing research reports in the codebase
command-type: dependent
parent-commands: plan, report
---

# List Research Reports

I'll find and list all research reports in the codebase.

## Search Pattern
$1 (optional filter)

## Process

I'll search for all reports in `specs/reports/` directories throughout the codebase and provide:

1. **Report Inventory**:
   - Location of each report
   - Report title and date
   - Topic/scope covered
   - File size and last modified date

2. **Organization**:
   - Group by directory/module
   - Sort by date (most recent first)
   - Highlight reports matching the search pattern

3. **Summary Statistics**:
   - Total number of reports
   - Coverage by module/area
   - Most recent reports
   - Largest/most comprehensive reports

Let me search for all existing reports in your codebase.