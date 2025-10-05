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

## Adaptive Plan Support

This command lists all three plan structure tiers:
- **Tier 1 (T1)**: Single-file plans (`NNN_name.md`)
- **Tier 2 (T2)**: Phase-directory plans (`NNN_name/`)
- **Tier 3 (T3)**: Hierarchical tree plans (phase subdirectories)

Detection uses `parse-adaptive-plan.sh detect_tier` for accurate tier identification.

## Process

I'll search for all plans in `specs/plans/` directories and provide:

### 1. Plan Discovery (Tier-Aware)
```bash
# Find Tier 1 plans (single files)
find . -path "*/specs/plans/*.md" -type f -not -path "*/specs/plans/*/*"

# Find Tier 2/3 plans (directories with overview)
find . -path "*/specs/plans/*/*.md" -type f -name "*_*.md" | while read overview; do
  dirname "$overview"
done | sort -u

# For each plan, detect tier
TIER=$(.claude/utils/parse-adaptive-plan.sh detect_tier "$PLAN_PATH")
```

### 2. Plan Inventory (Enhanced)
For each plan, extract:
- **Location**: Full path (file or directory)
- **Plan number**: From filename/directory name
- **Plan title**: From plan heading
- **Tier**: T1, T2, or T3 indicator
- **Complexity score**: From metadata (if available)
- **Status**: Using `parse-adaptive-plan.sh get_status`
- **Phase count**: Total phases in plan
- **Completion**: N/M phases complete

### 3. Organization
- Group by specs directory (project-level grouping)
- Sort by plan number (chronological order)
- Show tier indicators: `[T1]`, `[T2]`, `[T3]`
- Show completion status: `✓` (complete), `⏳` (in-progress), `○` (pending)
- Highlight plans matching search pattern (if provided)

### 4. Summary Statistics
- Total plans by tier (T1: N, T2: M, T3: K)
- Plans by status (pending, in-progress, completed)
- Most recent plans (top 5)
- Average complexity by tier

### 5. Quick Access
For each plan, show:
- **Tier 1**: `/implement specs/plans/NNN_name.md`
- **Tier 2/3**: `/implement specs/plans/NNN_name/`
- Brief description from overview
- Phase count and complexity
- Tier-appropriate access path

Let me search for all implementation plans in your codebase.