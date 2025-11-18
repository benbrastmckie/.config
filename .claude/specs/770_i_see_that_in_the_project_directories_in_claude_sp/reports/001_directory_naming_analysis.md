# Directory Naming Analysis Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Odd directory names in .claude/specs/ vs short descriptive names
- **Report Type**: codebase analysis

## Executive Summary

The "odd" directory names in `.claude/specs/` are caused by the `sanitize_topic_name()` function which simply truncates workflow descriptions to 50 characters after sanitization, resulting in long, truncated names like `770_i_see_that_in_the_project_directories_in_claude_sp`. While the system has LLM-generated `filename_slug` for research report files (limited to 50 chars, semantic), this capability is not applied to the parent topic directories. The /coordinate command uses the same approach as other commands, calling `sanitize_topic_name()` in `initialize_workflow_paths()`. Three alternative approaches are recommended: (1) LLM-generated topic directory slug, (2) first significant words extraction, or (3) manual --name parameter.

## Findings

### 1. Current Directory Name Examples (The Problem)

Examining `.claude/specs/` reveals truncated, non-descriptive directory names:

```
770_i_see_that_in_the_project_directories_in_claude_sp  # Truncated user input
769_research_alternative_solutions_for_claude_project_  # Truncated
768_research_build_errors_from_claude_build_output_md_  # Truncated
767_optimize_claudemd_structure  # Good - short enough
766_rename_fix_to_debug_research_plan_to_plan_research  # Truncated
746_command_compliance_assessment  # Good - naturally short
```

**Problem Pattern**: When workflow descriptions exceed 50 characters after sanitization, they get truncated mid-word, creating cryptic directory names.

### 2. Root Cause: sanitize_topic_name() Function

**Location**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:356-368`

```bash
sanitize_topic_name() {
  local raw_name="$1"

  echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \          # Convert to lowercase
    tr ' ' '_' | \                          # Spaces to underscores
    sed 's/[^a-z0-9_]//g' | \               # Remove special chars
    sed 's/^_*//;s/_*$//' | \               # Trim underscores
    sed 's/__*/_/g' | \                     # Collapse multiple underscores
    cut -c1-50                              # TRUNCATE to 50 chars
}
```

The function truncates at 50 characters without any semantic awareness, resulting in partial words.

### 3. How Topic Directories Are Created

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:355-432`

The `initialize_workflow_paths()` function calls `sanitize_topic_name()` with the full workflow description:

```bash
# Line 358-360
local topic_name
topic_name=$(sanitize_topic_name "$workflow_description")  # Full description passed
topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")

# Line 432
topic_path="${specs_root}/${topic_num}_${topic_name}"
```

**Key Insight**: The workflow description (which can be a full sentence or paragraph) is passed directly to `sanitize_topic_name()`, causing truncation.

### 4. How /coordinate Command Handles Naming

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:483`

The /coordinate command calls `initialize_workflow_paths()` with the full workflow description:

```bash
if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
```

**Result**: /coordinate uses the same problematic pattern as all other commands.

### 5. Existing LLM-Generated Slugs (For Report Files Only)

The system already has LLM-generated semantic slugs, but only for research report files, not topic directories:

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md:143-154`

The workflow-classifier agent generates:
- `filename_slug`: Lowercase, 1-50 chars, semantic identifier like `authentication_patterns`

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:536-541`

```bash
# Report files use LLM-generated slugs
for i in $(seq 1 "$research_complexity"); do
  local slug="${validated_slugs[$slug_index]}"
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_${slug}.md")
done
```

**Gap**: The `filename_slug` pattern is only applied to report files, not to the parent topic directory.

### 6. Comparison: Good vs Bad Directory Names

**Good Names** (naturally short or manually specified):
- `746_command_compliance_assessment` (28 chars)
- `767_optimize_claudemd_structure` (30 chars)
- `752_debug_coordinate_workflow_classifier` (40 chars)

**Bad Names** (truncated):
- `770_i_see_that_in_the_project_directories_in_claude_sp` (53 chars, truncated)
- `764_i_just_finished_implementing_home_benjamin_config_` (54 chars, truncated)

### 7. Alternative Approach Found: plan.md TOPIC_SLUG

**Location**: `/home/benjamin/.config/.claude/commands/plan.md:224`

The /plan command has an inline sanitization that's identical to the library function:

```bash
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//' | cut -c1-50)
```

This duplicates the problem - full description truncated to 50 chars.

## Recommendations

### Option 1: LLM-Generated Topic Directory Slug (RECOMMENDED)

**Approach**: Have the workflow-classifier agent generate a `topic_directory_slug` alongside the existing `filename_slug` fields.

**Implementation**:
1. Add `topic_directory_slug` field to workflow-classifier.md output schema
2. Validate slug format: `^[a-z0-9_]{1,40}$` (40 chars for readability)
3. Use this slug in `initialize_workflow_paths()` instead of sanitized description

**Example**:
```json
{
  "workflow_type": "research-only",
  "topic_directory_slug": "specs_directory_naming_analysis",
  "research_complexity": 2,
  "research_topics": [...]
}
```

**Result**: `770_specs_directory_naming_analysis` instead of `770_i_see_that_in_the_project_directories_in_claude_sp`

**Pros**:
- Semantic, descriptive names
- Consistent with existing filename_slug pattern
- LLM can extract key concepts from long descriptions

**Cons**:
- Requires LLM call (already happening in /coordinate)
- Additional field to validate

### Option 2: Extract First N Significant Words

**Approach**: Extract first 3-5 significant words from description, ignoring stop words.

**Implementation**:
```bash
extract_topic_words() {
  local raw="$1"
  # Remove stop words (the, a, in, to, for, etc.)
  # Take first 4 words
  # Join with underscores
  # Limit to 40 chars
  echo "$raw" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/\b\(the\|a\|an\|in\|to\|for\|of\|and\|or\|is\|are\|was\|were\)\b//gi' | \
    tr -s ' ' | \
    awk '{for(i=1;i<=4 && i<=NF;i++) printf $i"_"; print ""}' | \
    sed 's/_$//' | \
    sed 's/[^a-z0-9_]//g' | \
    cut -c1-40
}
```

**Example**:
- Input: "I see that in the project directories in claude specs..."
- Output: `project_directories_claude_specs`

**Pros**:
- No LLM required
- Deterministic
- Faster than LLM approach

**Cons**:
- Less semantic than LLM
- Stop word list maintenance
- May not capture key concepts

### Option 3: Manual --name Parameter

**Approach**: Allow users to specify topic directory name via parameter.

**Implementation**:
```bash
# Usage: /coordinate --name "auth_patterns" "Research authentication patterns in detail"
TOPIC_NAME="${MANUAL_NAME:-$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")}"
```

**Pros**:
- Complete user control
- Guaranteed good names when used
- No additional processing

**Cons**:
- Requires user effort
- Often won't be used
- Doesn't solve automatic naming

### Option 4: Hybrid Approach (Best Balance)

**Approach**: Combine Option 1 and Option 3 - LLM generates slug by default, user can override.

**Implementation**:
1. LLM generates `topic_directory_slug` during classification
2. User can specify `--name` to override
3. Fallback to first-words extraction if LLM unavailable

**Decision Matrix**:
| Priority | Source | Condition |
|----------|--------|-----------|
| 1 | `--name` parameter | User specified |
| 2 | LLM `topic_directory_slug` | Classification succeeded |
| 3 | First 4 significant words | Fallback |

## Implementation Priority

1. **Quick Win**: Add `topic_directory_slug` to workflow-classifier.md (builds on existing infrastructure)
2. **Medium Effort**: Implement first-words extraction as fallback
3. **Optional**: Add `--name` parameter for user override

## References

- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:356-368` - sanitize_topic_name() function
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:355-432` - Topic directory creation flow
- `/home/benjamin/.config/.claude/commands/coordinate.md:483` - Coordinate calling initialize_workflow_paths()
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:143-154` - filename_slug specification
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:536-541` - Report file slug usage
- `/home/benjamin/.config/.claude/commands/plan.md:224` - Plan command TOPIC_SLUG
- `/home/benjamin/.config/.claude/docs/guides/enhanced-topic-generation-guide.md:1-150` - Enhanced topic generation documentation
