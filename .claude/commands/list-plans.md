---
allowed-tools: Bash, Glob, Read
argument-hint: [search-pattern]
description: List all implementation plans in the codebase using metadata-only reads
command-type: dependent
parent-commands: implement
---

# List Implementation Plans

I'll find and list all implementation plans across the codebase using optimized metadata-only reads for performance.

## Search Pattern
$1 (optional filter)

## Optimization Strategy

**Context Optimization**: This command uses `lib/artifact-utils.sh::get_plan_metadata()` for metadata-only reads instead of loading full plan files. This provides ~88% context reduction (estimated 1.5MB → 180KB for large codebases).

**Metadata Extraction**:
- Reads only first 50 lines of each plan (metadata section)
- Extracts: title, date, phase count, standards file
- Falls back to filename if metadata extraction fails

## Progressive Plan Support

This command lists all three structure levels:
- **Level 0 (L0)**: Single-file plans (`NNN_name.md`) - all phases inline
- **Level 1 (L1)**: Phase-expanded plans (`NNN_name/`) - some phases in separate files
- **Level 2 (L2)**: Stage-expanded plans - some phases have stage subdirectories

Detection uses `parse-adaptive-plan.sh detect_structure_level` for accurate level identification.

## Process

I'll search for all plans in `specs/plans/` directories using metadata-only reads and provide:

### 1. Plan Discovery (Level-Aware with Metadata Extraction)
```bash
# Source metadata extraction utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-utils.sh"

# Find Level 0 plans (single files not in directories)
find . -path "*/specs/plans/*.md" -type f -not -path "*/specs/plans/*/*"

# Find Level 1/2 plans (directories with main plan file)
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" | while read overview; do
  dirname "$overview"
done | sort -u

# For each plan, extract metadata (OPTIMIZED - reads only first 50 lines)
metadata=$(get_plan_metadata "$plan_path")
title=$(echo "$metadata" | jq -r '.title // "Unknown"')
date=$(echo "$metadata" | jq -r '.date // "N/A"')
phases=$(echo "$metadata" | jq -r '.phases // 0')

# Detect structure level (full read only for level detection)
LEVEL=$(.claude/utils/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
```

### 2. Plan Inventory (Enhanced)
For each plan, extract:
- **Location**: Full path (file or directory)
- **Plan number**: From filename/directory name
- **Plan title**: From plan heading
- **Level**: L0, L1, or L2 indicator
- **Expanded phases**: Which phases are expanded (for L1/L2)
- **Complexity score**: From metadata (if available)
- **Status**: Using `parse-adaptive-plan.sh get_status`
- **Phase count**: Total phases in plan
- **Completion**: N/M phases complete

### 3. Organization
- Group by specs directory (project-level grouping)
- Sort by plan number (chronological order)
- Show level indicators: `[L0]`, `[L1]`, `[L2]`
- For L1: Show expanded phases: `[L1] (P:2,5)` (phases 2 and 5 expanded)
- For L2: Show expanded stages: `[L2] (P:2[S:1,3])` (phase 2 has stages 1,3 expanded)
- Show completion status: `✓` (complete), `⏳` (in-progress), `○` (pending)
- Highlight plans matching search pattern (if provided)

### 4. Summary Statistics
- Total plans by level (L0: N, L1: M, L2: K)
- Plans by status (pending, in-progress, completed)
- Most recent plans (top 5)
- Average complexity by level
- Expansion statistics (% of plans expanded)

### 5. Quick Access
For each plan, show:
- **Level 0**: `/implement specs/plans/NNN_name.md`
- **Level 1/2**: `/implement specs/plans/NNN_name/`
- Brief description from overview
- Phase count and complexity
- Expansion status and hints

Let me search for all implementation plans in your codebase.