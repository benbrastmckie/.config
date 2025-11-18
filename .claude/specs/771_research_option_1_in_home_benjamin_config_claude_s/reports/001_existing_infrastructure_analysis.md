# Existing Infrastructure Analysis Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Existing Infrastructure for Semantic Topic Directory Slugs
- **Report Type**: codebase analysis

## Executive Summary

The codebase already has a robust LLM-based filename slug generation system in the workflow-classifier agent (using Haiku model) that generates semantic `filename_slug` values for research report files. However, topic directory names still use the problematic `sanitize_topic_name()` function which truncates workflow descriptions to 50 characters without semantic awareness. Option 1 from the previous research report recommends extending the existing workflow-classifier agent to also generate a `topic_directory_slug` field, leveraging the existing infrastructure.

## Findings

### 1. Current filename_slug Generation Infrastructure

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md:143-154`

The workflow-classifier agent already generates semantic slugs for research report files:

```json
{
  "short_name": "Authentication Patterns",
  "detailed_description": "Analyze current authentication implementation...",
  "filename_slug": "authentication_patterns",
  "research_focus": "How is auth currently handled?..."
}
```

**Key validation rules** (lines 151-154):
- filename_slug: `^[a-z0-9_]{1,50}$` (lowercase, numbers, underscores only)
- 1-50 characters maximum
- No special characters or hyphens

The agent model is specified as `haiku` (line 4) with `fallback-model: sonnet-4.5` (line 6), demonstrating the existing pattern for fast, cost-effective classification tasks.

### 2. Three-Tier Fallback Validation System

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:126-234`

The `validate_and_generate_filename_slugs()` function implements a robust three-tier validation:

- **Tier 1 (lines 194-208)**: Use LLM-generated slug if valid regex match
- **Tier 2 (lines 210-213)**: Sanitize short_name as fallback
- **Tier 3 (lines 215-217)**: Use generic `topicN` if short_name empty

This pattern includes:
- Path separator injection protection (line 197)
- 255-byte filename limit check (line 201)
- Strategy logging via `log_slug_generation()` (lines 222-225)

### 3. Problematic Topic Directory Naming

**Location**: `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:356-368`

The `sanitize_topic_name()` function truncates without semantic awareness:

```bash
sanitize_topic_name() {
  local raw_name="$1"
  echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/^_*//;s/_*$//' | \
    sed 's/__*/_/g' | \
    cut -c1-50  # TRUNCATE without semantic awareness
}
```

**Problem examples**:
- Input: "I see that in the project directories in claude specs..."
- Output: `770_i_see_that_in_the_project_directories_in_claude_sp` (truncated mid-word)

### 4. Topic Directory Creation Flow

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:354-432`

The `initialize_workflow_paths()` function creates topic directories:

```bash
# Lines 358-360
topic_name=$(sanitize_topic_name "$workflow_description")
topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")
# Line 432
topic_path="${specs_root}/${topic_num}_${topic_name}"
```

**Gap identified**: The full workflow description is passed directly to `sanitize_topic_name()`, causing truncation. The LLM-generated `filename_slug` pattern is only applied to report files, not topic directories.

### 5. Commands That Create Topic Directories

Multiple commands call `initialize_workflow_paths()`:

- **coordinate.md**: `/home/benjamin/.config/.claude/commands/coordinate.md:483`
  - `initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"`

- **plan.md**: `/home/benjamin/.config/.claude/commands/plan.md:224`
  - Uses inline `TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | ... | cut -c1-50)` (same problem)

- **research.md**: Uses workflow-initialization.sh indirectly via orchestration flow

### 6. Integration Point for topic_directory_slug

The workflow-classifier agent is invoked during the `sm_init` state of the coordinate command's state machine. The classification result JSON is already passed to `initialize_workflow_paths()` as the fourth argument:

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:284`
```bash
local classification_result="${4:-}"  # JSON classification result for filename slugs
```

This means a new `topic_directory_slug` field would be naturally available during path initialization.

### 7. Idempotent Topic Number Management

**Location**: `/home/benjamin/.config/.claude/lib/topic-utils.sh:36-58`

The `get_or_create_topic_number()` function ensures idempotency:

```bash
# Check for existing topic with exact name match
existing=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_"${topic_name}" 2>/dev/null | head -1)
if [ -n "$existing" ]; then
  # Extract and return the existing topic number
  basename "$existing" | sed 's/^\([0-9][0-9][0-9]\)_.*/\1/'
else
  get_next_topic_number "$specs_root"
fi
```

This prevents topic number incrementing on repeated invocations, which would work seamlessly with semantic slugs.

## Recommendations

### 1. Add topic_directory_slug to workflow-classifier Agent

Extend the workflow-classifier agent output schema to include a `topic_directory_slug` field alongside existing `filename_slug` fields. The Haiku model already handles semantic slug generation effectively.

**Implementation location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

Add to output schema:
```json
{
  "workflow_type": "research-and-plan",
  "topic_directory_slug": "specs_directory_naming_analysis",
  "research_complexity": 2,
  "research_topics": [...]
}
```

### 2. Add Validation for topic_directory_slug

Extend the three-tier validation system to validate the new field:

**Implementation location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`

Add validation similar to `validate_and_generate_filename_slugs()`:
- Regex: `^[a-z0-9_]{1,40}$` (40 chars for topic directory readability)
- Fallback tiers: LLM slug -> extract_first_words() -> sanitize_topic_name()

### 3. Modify initialize_workflow_paths() to Use LLM Slug

Update the function to extract and use `topic_directory_slug` from classification result:

```bash
# Extract LLM-generated topic slug if available
local topic_slug=""
if [ -n "$classification_result" ]; then
  topic_slug=$(echo "$classification_result" | jq -r '.topic_directory_slug // empty')
fi

# Use LLM slug if valid, fallback to sanitize_topic_name
if [ -n "$topic_slug" ] && echo "$topic_slug" | grep -Eq '^[a-z0-9_]{1,40}$'; then
  topic_name="$topic_slug"
else
  topic_name=$(sanitize_topic_name "$workflow_description")
fi
```

### 4. Design Fallback Mechanisms

Implement graceful degradation when LLM is unavailable:
- Primary: LLM-generated `topic_directory_slug`
- Fallback 1: Extract first 3-4 significant words (stop-word removal)
- Fallback 2: Existing `sanitize_topic_name()` with improved truncation

## References

- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:1-539` - Workflow classification agent definition
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:126-234` - validate_and_generate_filename_slugs() function
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:280-692` - initialize_workflow_paths() function
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:356-368` - sanitize_topic_name() function
- `/home/benjamin/.config/.claude/lib/topic-utils.sh:36-58` - get_or_create_topic_number() idempotent function
- `/home/benjamin/.config/.claude/commands/coordinate.md:483` - Coordinate command initialization call
- `/home/benjamin/.config/.claude/specs/770_i_see_that_in_the_project_directories_in_claude_sp/reports/001_directory_naming_analysis.md` - Previous research report with Option 1 recommendation
