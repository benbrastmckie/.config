---
allowed-tools: Bash, Glob, Read
argument-hint: [search-pattern]
description: List all implementation summaries showing plans executed and reports used
command-type: dependent
parent-commands: implement
---

# List Implementation Summaries

I'll find and list all implementation summaries across the codebase, showing the connections between plans, implementations, and research reports.

## Search Pattern
$1 (optional filter)

## Process

I'll search for all summaries in `specs/summaries/` directories and provide:

### 1. Summary Inventory
- Location of each summary
- Feature implemented
- Plan executed (with link)
- Reports referenced (with links)
- Date completed
- Success metrics

### 2. Relationships
For each summary, I'll show:
- **Plan → Summary**: Which plan was executed
- **Reports → Plan**: Which reports informed the plan
- **Summary → Reports**: Which reports were updated

### 3. Statistics
- Total implementations completed
- Most referenced reports
- Implementation success rate
- Common patterns across summaries

### 4. Cross-References
- Plans without summaries (not yet implemented)
- Reports without implementations (research only)
- Summaries without reports (direct implementation)

Let me search for all implementation summaries in your codebase.