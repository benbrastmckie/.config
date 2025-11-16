---
allowed-tools: Bash, Glob, Read
argument-hint: [plans|reports|summaries|all] [--recent N] [--incomplete] [search-pattern]
description: List implementation artifacts (plans, reports, summaries) using metadata-only reads
command-type: utility
---

# List Implementation Artifacts

I'll find and list implementation artifacts across the codebase using optimized metadata-only reads for performance.

## Syntax

```bash
/list [type] [options] [search-pattern]
```

## Types

- **plans**: List implementation plans (all structure levels: L0, L1, L2)
- **reports**: List research reports
- **summaries**: List implementation summaries
- **all**: List all artifact types (default if no type specified)

## Options

- **--recent N**: Show only N most recent items (default: all)
- **--incomplete**: Filter to incomplete plans only (plans type only)
- **search-pattern**: Optional filter string for matching artifact names

## Optimization Strategy

**Context Optimization**: Uses `lib/artifact-creation.sh` and `lib/artifact-registry.sh` metadata extraction functions for metadata-only reads:
- Plans: ~88% context reduction (1.5MB → 180KB estimated)
- Reports: ~85-90% context reduction
- Summaries: Reads only metadata sections

**Metadata Extraction**:
- Plans: First 50 lines (metadata section)
- Reports: First 100 lines (metadata + summary)
- Summaries: First 100 lines (metadata + overview)

## Progressive Plan Support (Plans Type)

Lists all three structure levels:
- **Level 0 (L0)**: Single-file plans (`NNN_name.md`) - all phases inline
- **Level 1 (L1)**: Phase-expanded plans (`NNN_name/`) - some phases in separate files
- **Level 2 (L2)**: Stage-expanded plans - some phases have stage subdirectories

Detection uses `parse-adaptive-plan.sh detect_structure_level` for accurate level identification.

## Implementation

### List Plans

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-registry.sh"

# Find Level 0 plans (single files not in directories)
find . -path "*/specs/plans/*.md" -type f -not -path "*/specs/plans/*/*"

# Find Level 1/2 plans (directories with main plan file)
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" | while read overview; do
  dirname "$overview"
done | sort -u

# For each plan, extract metadata
metadata=$(get_plan_metadata "$plan_path")
title=$(echo "$metadata" | jq -r '.title // "Unknown"')
date=$(echo "$metadata" | jq -r '.date // "N/A"')
phases=$(echo "$metadata" | jq -r '.phases // 0')

# Detect structure level
LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Check status
STATUS=$(.claude/lib/parse-adaptive-plan.sh get_status "$PLAN_PATH")
```

**Output Format (Plans)**:
```
[L0] 001_feature_name           ○ 5 phases   2025-10-07
[L1] 025_another_feature (P:2,5) ⏳ 8 phases   2025-10-06
[L2] 033_complex (P:1[S:2,3])   ✓ 6 phases   2025-10-05

Indicators:
  Level: [L0] single-file, [L1] phase-expanded, [L2] stage-expanded
  Status: ✓ complete, ⏳ in-progress, ○ pending
  Expansion: (P:2,5) = phases 2,5 expanded; [S:2,3] = stages 2,3 expanded
```

### List Reports

```bash
# Source utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-creation.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-registry.sh"

# Find all reports
for report in specs/reports/*.md; do
  # Extract metadata
  metadata=$(get_report_metadata "$report")
  title=$(echo "$metadata" | jq -r '.title // "Unknown"')
  date=$(echo "$metadata" | jq -r '.date // "N/A"')
  questions=$(echo "$metadata" | jq -r '.research_questions // 0')

  # Display report info
  echo "[$date] $title ($questions research questions)"
  echo "  Path: $report"
done
```

**Output Format (Reports)**:
```
[2025-10-07] Consolidation Opportunities Analysis (5 findings)
  Path: specs/reports/025_consolidation_opportunities.md
  Topics: lib/ vs utils/ duplication, command consolidation, directory reduction

[2025-10-06] System Optimization Patterns (8 patterns)
  Path: specs/reports/024_optimization_patterns.md
  Topics: performance, caching, progressive loading
```

### List Summaries

```bash
# Find all summaries
for summary in specs/summaries/*.md; do
  # Extract metadata
  title=$(grep "^# " "$summary" | head -1 | sed 's/^# //')
  date=$(grep "Date Completed:" "$summary" | sed 's/.*: //')
  plan=$(grep "Plan:" "$summary" | sed 's/.*: //')

  echo "[$date] $title"
  echo "  Plan: $plan"
  echo "  Path: $summary"
done
```

**Output Format (Summaries)**:
```
[2025-10-05] Dark Mode Implementation
  Plan: specs/plans/007_dark_mode_implementation.md
  Tests: All passed
  Path: specs/summaries/007_implementation_summary.md
```

### List All

When type is `all`, displays all three artifact types in separate sections with summary statistics.

## Process

### 1. Artifact Discovery (Type-Specific)

**Plans**:
- Find Level 0 plans: `*.md` files in specs/plans/
- Find Level 1/2 plans: directories in specs/plans/
- Extract metadata: title, date, phases, complexity
- Detect structure level and expansion status
- Check completion status

**Reports**:
- Find all files in specs/reports/
- Extract metadata: title, date, research questions
- Check implementation status (linked plans)

**Summaries**:
- Find all files in specs/summaries/
- Extract metadata: title, date, plan executed
- Check report references

### 2. Filtering

**--recent N**: Sort by date, limit to N most recent
**--incomplete**: Filter plans without [COMPLETED] markers
**search-pattern**: Case-insensitive match on titles/filenames

### 3. Organization

- Group by specs directory (project-level grouping)
- Sort by artifact number (chronological order)
- Highlight matching items (if search pattern provided)
- Show expansion status (plans only)
- Display completion indicators

### 4. Summary Statistics

**Plans**:
- Total plans by level (L0: N, L1: M, L2: K)
- Plans by status (pending, in-progress, completed)
- Expansion rate (% of plans expanded)
- Average complexity by level

**Reports**:
- Total reports
- Coverage by topic/module
- Reports with implementations
- Reports without implementations

**Summaries**:
- Total implementations completed
- Success rate
- Average implementation time

**All**:
- Combined statistics across all types
- Cross-references (reports → plans → summaries)

### 5. Quick Access

For each artifact, show relevant commands:

**Plans**: `/implement <path>`
**Reports**: `/plan <feature> <report-path>`
**Summaries**: Read for lessons learned

## Examples

### List all plans
```bash
/list plans
```

### List recent reports
```bash
/list reports --recent 5
```

### List incomplete plans
```bash
/list plans --incomplete
```

### Search for specific artifact
```bash
/list all "optimization"
```

### List recent plans with pattern
```bash
/list plans --recent 10 "refactor"
```

## Standards Applied

Following CLAUDE.md standards:
- **Performance**: Metadata-only reads for efficiency
- **Organization**: Grouped by directory, sorted chronologically
- **Progressive Support**: Full L0/L1/L2 plan awareness
- **Output**: Clean, scannable format with indicators

Let me search for and list the requested artifacts in your codebase.
