# Haiku Integration Design Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Haiku Model Integration for Semantic Topic Directory Slugs
- **Report Type**: pattern recognition

## Executive Summary

The workflow-classifier agent already uses Haiku model for fast, deterministic classification tasks and is the ideal integration point for semantic topic directory slug generation. The design extends the existing JSON output schema with a `topic_directory_slug` field, adds validation constraints to Step 3, provides edge case examples for semantic slug generation, and implements a three-tier fallback mechanism for graceful degradation when LLM is unavailable. The solution requires minimal changes to the existing infrastructure.

## Findings

### 1. Existing Haiku Agent Invocation Pattern

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md:1-10`

The workflow-classifier agent frontmatter:

```yaml
---
allowed-tools: None
description: Classification-only agent for semantic workflow type analysis - returns structured JSON, does not persist state
model: haiku
model-justification: Classification is fast, deterministic task requiring <5s response time
fallback-model: sonnet-4.5
---
```

**Key characteristics**:
- No tool access (pure classification)
- Returns structured JSON
- Target response time: <5 seconds
- Automatic fallback to Sonnet if Haiku unavailable

This same pattern applies perfectly for topic directory slug generation.

### 2. Current JSON Output Schema

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md:219-240`

Current output format:

```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Authentication Patterns",
      "detailed_description": "Analyze current authentication...",
      "filename_slug": "authentication_patterns",
      "research_focus": "How is auth currently handled?..."
    }
  ],
  "reasoning": "Description indicates research to inform plan creation..."
}
```

The `filename_slug` field already demonstrates successful semantic slug generation by Haiku. The same capability should be extended to topic directories.

### 3. Prompt Template for topic_directory_slug

**Design**: Add to workflow-classifier agent's Step 2 output specification

```markdown
#### 4. Topic Directory Slug (REQUIRED)

Generate a semantic, descriptive slug for the topic directory that captures the core intent:

**Requirements**:
- Format: `^[a-z0-9_]{1,40}$` (lowercase, numbers, underscores, max 40 chars)
- Semantic: Must capture the core concept of the workflow
- Readable: Should be understandable at a glance
- Stable: Same description should produce same slug

**Examples**:

| Workflow Description | topic_directory_slug |
|---------------------|---------------------|
| "I see that in the project directories in claude specs the names are odd" | `specs_directory_naming_analysis` |
| "Research authentication patterns and create implementation plan" | `auth_patterns_implementation` |
| "Fix the token refresh bug in the authentication module" | `token_refresh_bug_fix` |
| "Add dark mode toggle to application settings" | `dark_mode_toggle_feature` |

**Anti-patterns**:
- WRONG: `i_see_that_in_the_project_directories` (truncated description)
- WRONG: `770_topic` (numeric prefix belongs to directory, not slug)
- WRONG: `workflow-analysis` (hyphens not allowed)
- CORRECT: `specs_directory_naming` (semantic, readable, valid format)
```

### 4. Integration with Step 3 Validation

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md:177-209`

Add validation checkpoint for topic_directory_slug:

```markdown
### STEP 3 (REQUIRED BEFORE STEP 4) - Validate Classification

**Validation Checklist**:

5. **Topic Directory Slug Validation**:
   - [ ] topic_directory_slug matches regex: `^[a-z0-9_]{1,40}$`
   - [ ] topic_directory_slug is semantic (not just truncated description)
   - [ ] topic_directory_slug captures core workflow intent
   - [ ] topic_directory_slug does not contain path separators
   - [ ] topic_directory_slug is ≤40 characters

**CHECKPOINT**: ALL validation criteria MUST pass before Step 4.
```

### 5. Updated Output Format

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md:213-240`

Update output format to include `topic_directory_slug`:

```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "topic_directory_slug": "auth_patterns_implementation",
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Authentication Patterns",
      "detailed_description": "Analyze current authentication implementation...",
      "filename_slug": "authentication_patterns",
      "research_focus": "How is auth currently handled?..."
    },
    {
      "short_name": "Session Management",
      "detailed_description": "Investigate session storage mechanisms...",
      "filename_slug": "session_management",
      "research_focus": "Where are sessions stored?..."
    }
  ],
  "reasoning": "Description indicates research to inform plan creation. Mentions 'create implementation plan' explicitly."
}
```

### 6. Edge Case Examples for Haiku

Add comprehensive edge case examples to guide the model:

**Edge Case 1: Long Verbose Description**

```
Description: "I'm trying to understand why the token refresh is failing after exactly one hour and I think it might be related to the JWT expiration settings in the authentication configuration"

topic_directory_slug: "jwt_token_refresh_investigation"

Reasoning: Extract core concepts (JWT, token, refresh), ignore verbose explanation
```

**Edge Case 2: Path-Heavy Description**

```
Description: "Research the /home/benjamin/.config/.claude/specs/ directory structure and naming conventions"

topic_directory_slug: "specs_directory_structure"

Reasoning: Extract meaningful path components (specs, directory), ignore file system paths
```

**Edge Case 3: Multiple Topics**

```
Description: "Research authentication patterns, session management, and token validation to create comprehensive security implementation plan"

topic_directory_slug: "security_implementation_research"

Reasoning: Identify overarching theme (security implementation), not enumerate all topics
```

**Edge Case 4: Action-Focused Description**

```
Description: "Fix the memory leak in the data processing pipeline that causes the server to crash after 2 hours"

topic_directory_slug: "data_pipeline_memory_leak"

Reasoning: Focus on the problem (memory leak, data pipeline), not the symptom (crash)
```

### 7. Fallback Mechanism Design

When LLM is unavailable or returns invalid slug, implement fallback chain:

**Tier 1: LLM-generated slug** (Primary)
- Use Haiku-generated `topic_directory_slug`
- Validate with regex `^[a-z0-9_]{1,40}$`
- If valid, use directly

**Tier 2: Extract significant words** (Fallback)
```bash
extract_significant_words() {
  local raw="$1"
  local stopwords="the a an and or but to for of in on at by with from as is are was were be been being have has had do does did will would should could may might must can about"

  echo "$raw" | \
    tr '[:upper:]' '[:lower:]' | \
    tr -cs 'a-z0-9' ' ' | \
    awk -v stop="$stopwords" '
      BEGIN { split(stop, arr, " "); for(i in arr) stops[arr[i]]=1 }
      {
        for(i=1; i<=NF && count<4; i++) {
          if(!stops[$i] && length($i)>2) {
            printf "%s_", $i
            count++
          }
        }
      }
    ' | \
    sed 's/_$//' | \
    cut -c1-40
}
```

**Tier 3: Sanitize fallback** (Ultimate)
- Use existing `sanitize_topic_name()` with improved truncation
- Last resort when all else fails

### 8. Cost Analysis

**Haiku Cost**: $0.003 per 1K tokens

**Estimated tokens per invocation**:
- Input (prompt + description): ~500 tokens
- Output (JSON response): ~300 tokens
- Total: ~800 tokens per classification

**Cost per workflow**: $0.003 * 0.8 = **$0.0024**

**Comparison**:
- Current sanitize_topic_name(): $0 (no LLM)
- Haiku semantic slug: $0.0024 per workflow
- Value: Semantic, readable directory names worth the minimal cost

## Recommendations

### 1. Extend workflow-classifier Agent Output Schema

Add `topic_directory_slug` field to the JSON output schema:

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

Add after line 134 (before research_topics):

```markdown
#### 4. Topic Directory Slug (REQUIRED)

Generate a semantic, descriptive slug for the topic directory:

**Format**: `^[a-z0-9_]{1,40}$`
- Lowercase letters, numbers, underscores only
- Maximum 40 characters for readability
- No path separators or special characters

**Semantic Requirements**:
- Captures core concept of the workflow
- Readable and understandable at a glance
- Stable: same description produces same slug
```

### 2. Add Validation Checkpoint

Add to Step 3 validation checklist:

```markdown
5. **Topic Directory Slug Validation**:
   - [ ] topic_directory_slug matches regex: `^[a-z0-9_]{1,40}$`
   - [ ] topic_directory_slug is semantic (not truncated)
   - [ ] topic_directory_slug ≤40 characters
   - [ ] No path separators in slug
```

### 3. Add Edge Case Examples

Include at least 4 edge case examples demonstrating:
- Long verbose descriptions
- Path-heavy descriptions
- Multiple topics
- Action-focused descriptions

### 4. Implement validate_topic_directory_slug() Function

Add to `/home/benjamin/.config/.claude/lib/workflow-initialization.sh`:

```bash
# validate_topic_directory_slug: Extract and validate topic directory slug
#
# Arguments:
#   $1 - classification_result: JSON with topic_directory_slug field
#   $2 - workflow_description: Original description for fallback
#
# Output:
#   Validated slug on stdout
#
# Returns:
#   0 on success
#
validate_topic_directory_slug() {
  local classification_result="$1"
  local workflow_description="$2"
  local slug_regex='^[a-z0-9_]{1,40}$'
  local strategy=""
  local final_slug=""

  # Tier 1: Extract and validate LLM slug
  if [ -n "$classification_result" ]; then
    local topic_slug
    topic_slug=$(echo "$classification_result" | jq -r '.topic_directory_slug // empty')

    if [ -n "$topic_slug" ] && echo "$topic_slug" | grep -Eq "$slug_regex"; then
      # Security check for path separators
      if ! echo "$topic_slug" | grep -q '/'; then
        strategy="llm"
        final_slug="$topic_slug"
      fi
    fi
  fi

  # Tier 2: Extract significant words
  if [ -z "$final_slug" ] && [ -n "$workflow_description" ]; then
    strategy="extract"
    final_slug=$(extract_significant_words "$workflow_description")
  fi

  # Tier 3: Sanitize fallback
  if [ -z "$final_slug" ]; then
    strategy="sanitize"
    final_slug=$(sanitize_topic_name "$workflow_description")
  fi

  # Log strategy for debugging
  if declare -f log_topic_slug_generation >/dev/null 2>&1; then
    log_topic_slug_generation "INFO" "$strategy" "$final_slug"
  fi

  echo "$final_slug"
}
```

### 5. Update initialize_workflow_paths() Integration

Modify the function to use the new validation:

```bash
# In initialize_workflow_paths(), around line 358:
local topic_name
if [ -n "$classification_result" ]; then
  topic_name=$(validate_topic_directory_slug "$classification_result" "$workflow_description")
else
  topic_name=$(sanitize_topic_name "$workflow_description")
fi
topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")
```

### 6. Ensure Backward Compatibility

For commands that don't use workflow-classifier (e.g., plan.md with inline sanitization):
- Keep `sanitize_topic_name()` as default behavior
- Semantic slugs only apply when classification_result is provided
- No breaking changes to existing workflows

## References

- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:1-10` - Agent frontmatter with Haiku model
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:134-172` - Research topics output specification
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:177-209` - Step 3 validation checklist
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:213-240` - Output format specification
- `/home/benjamin/.config/.claude/agents/workflow-classifier.md:251-402` - Edge case examples
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:354-432` - initialize_workflow_paths() function
- `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md:17-36` - Haiku model selection criteria
- `/home/benjamin/.config/.claude/lib/topic-utils.sh:78-141` - sanitize_topic_name() with stopword removal

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_research_option_1_in_home_benjamin_confi_plan.md](../plans/001_research_option_1_in_home_benjamin_confi_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
