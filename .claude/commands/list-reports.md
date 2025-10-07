---
allowed-tools: Bash, Glob, Read
argument-hint: [search-pattern]
description: List all existing research reports using metadata-only reads
command-type: dependent
parent-commands: plan, report
---

# List Research Reports

I'll find and list all research reports in the codebase using optimized metadata-only reads for performance.

## Search Pattern
$1 (optional filter)

## Optimization Strategy

**Context Optimization**: This command uses `lib/artifact-utils.sh::get_report_metadata()` for metadata-only reads instead of loading full report files. This provides ~85-90% context reduction for discovery operations.

**Metadata Extraction**:
- Reads only first 100 lines of each report (metadata and summary section)
- Extracts: title, date, research questions count, key findings
- Falls back to filename if metadata extraction fails

## Implementation

```bash
# Source metadata extraction utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"

# Find all reports
for report in specs/reports/*.md; do
  # Extract metadata (OPTIMIZED - reads only first 100 lines)
  metadata=$(get_report_metadata "$report")
  title=$(echo "$metadata" | jq -r '.title // "Unknown"')
  date=$(echo "$metadata" | jq -r '.date // "N/A"')
  questions=$(echo "$metadata" | jq -r '.research_questions // 0')

  # Display report info
  echo "[$date] $title ($questions research questions)"
  echo "  Path: $report"
done
```

## Process

I'll search for all reports in `specs/reports/` directories using metadata-only reads and provide:

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