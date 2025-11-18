# Standards Compliance Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Standards Compliance for Semantic Topic Directory Slugs
- **Report Type**: best practices

## Executive Summary

The .claude/docs/ directory contains comprehensive standards for code development, directory organization, agent architecture, and error handling that must be followed when implementing the LLM-based topic directory slug feature. Key requirements include: using Haiku model for deterministic classification tasks, following the behavioral injection pattern for agent invocations, implementing three-tier validation fallbacks, adhering to naming conventions (lowercase snake_case), and providing comprehensive error handling with structured messages.

## Findings

### 1. Model Selection Standards for Classification Tasks

**Location**: `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md:17-36`

The Model Selection Guide explicitly recommends Haiku for classification tasks:

**Haiku 4.5 Use Cases** (lines 19-25):
- Template-based text generation
- Rule-based analysis (pattern matching, standards checking)
- Data parsing and aggregation (JSON parsing)
- Classification tasks requiring <5 seconds response time

**Characteristics for Haiku** (lines 27-32):
- Clear, deterministic algorithms
- Limited decision-making required
- Output format well-defined
- Validation rules explicit
- High-frequency invocation patterns

The existing workflow-classifier agent already uses `model: haiku` (line 4 of workflow-classifier.md), confirming this is the correct model tier for semantic slug generation.

### 2. Code Standards for Bash and Agents

**Location**: `/home/benjamin/.config/.claude/docs/reference/code-standards.md:1-84`

Key standards to follow:

**General Principles** (lines 5-10):
- 2 spaces indentation
- ~100 character line length
- snake_case for variables/functions
- Error handling with structured messages (WHICH/WHAT/WHERE)
- UTF-8 only, no emojis

**Shell Script Standards** (lines 16):
- Follow ShellCheck recommendations
- Use `bash -e` for error handling

**Command and Agent Architecture Standards** (lines 17-29):
- Templates must be complete and copy-paste ready
- Behavioral Injection pattern for agent invocations
- Verification and Fallback pattern for file creation
- Robustness patterns for reliable command development

### 3. Directory Organization Standards

**Location**: `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md:1-276`

The implementation should follow these placement rules:

**lib/ - Sourced Function Libraries** (lines 51-77):
- Reusable bash functions sourced by commands
- Stateless, pure functions (no side effects)
- General-purpose, used by multiple callers
- Unit testable independently
- Naming: kebab-case (e.g., `topic-slug-utils.sh`)

The new validation function for `topic_directory_slug` should be added to `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` since it's already the home for `validate_and_generate_filename_slugs()`.

### 4. Hierarchical Agent Architecture Standards

**Location**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md:1447-1506`

The behavioral injection pattern requires:

**Pattern Flow** (lines 1484-1529):
1. Commands pre-calculate topic-based paths
2. Commands load agent behavioral prompts
3. Commands inject complete context into agent invocation
4. Agents create artifacts at provided paths
5. Commands verify artifacts and extract metadata only

For the topic directory slug feature:
- The coordinate command will invoke workflow-classifier
- The classifier returns JSON including `topic_directory_slug`
- The command validates and uses the slug for path creation

**Anti-Pattern to Avoid** (lines 1531-1557):
- Agents should NOT invoke slash commands for artifact creation
- Loss of path control, context bloat, recursion risk

### 5. Validation Patterns Already in Use

**Location**: `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:186-226`

The existing validation pattern for filename slugs:

```bash
local slug_regex='^[a-z0-9_]{1,50}$'

for ((i=0; i<research_complexity; i++)); do
  filename_slug=$(echo "$research_topics" | jq -r ".[$i].filename_slug // empty")

  # Tier 1: Validate LLM-generated slug
  if [ -n "$filename_slug" ] && echo "$filename_slug" | grep -Eq "$slug_regex"; then
    # Security checks
    if echo "$filename_slug" | grep -q '/'; then
      # Path separator injection - reject
      strategy="sanitize"
      final_slug=$(sanitize_topic_name "$short_name")
    elif [ ${#filename_slug} -gt 255 ]; then
      # Filesystem limit - truncate
      strategy="truncate"
      final_slug="${filename_slug:0:255}"
    else
      strategy="llm"
      final_slug="$filename_slug"
    fi
  # Tier 2: Sanitize short_name
  elif [ -n "$short_name" ]; then
    strategy="sanitize"
    final_slug=$(sanitize_topic_name "$short_name")
  # Tier 3: Generic fallback
  else
    strategy="generic"
    final_slug="topic$((i+1))"
  fi
done
```

This same pattern should be adapted for `topic_directory_slug` validation.

### 6. Error Handling Requirements

**Location**: `/home/benjamin/.config/.claude/docs/reference/code-standards.md:8`

Error handling must use structured messages with WHICH/WHAT/WHERE pattern:

```bash
echo "ERROR: validate_topic_directory_slug: topic_directory_slug invalid (expected ^[a-z0-9_]{1,40}$, got '$topic_slug')" >&2
return 1
```

**Additional error handling patterns** from `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:155-182`:
- Input validation with clear error messages
- Early return on validation failure
- Stderr for error output
- Consistent return codes (0 success, 1 failure)

### 7. Logging Standards

**Location**: `/home/benjamin/.config/.claude/lib/unified-logger.sh:753-801`

The `log_slug_generation()` function logs slug generation strategy:

```bash
log_slug_generation() {
  local level="$1"
  local topic_index="$2"
  local strategy="$3"   # llm|sanitize|generic|truncate
  local final_slug="$4"
  # ... logging implementation
}
```

The new topic directory slug feature should log similarly for debugging and monitoring.

### 8. Agent Frontmatter Requirements

**Location**: `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md:292-322`

Required agent frontmatter format:

```yaml
---
model: haiku
model-justification: "Classification is fast, deterministic task requiring <5s response time"
fallback-model: sonnet-4.5
---
```

The workflow-classifier agent already follows this format correctly.

## Recommendations

### 1. Follow Model Selection Standards

Use Haiku model for the topic directory slug generation as it:
- Is a classification/extraction task (deterministic)
- Requires <5 seconds response time
- Has well-defined output format (regex validation)
- Is invoked at high frequency (every workflow)

**Compliance**: Already compliant via existing workflow-classifier agent.

### 2. Implement Three-Tier Validation Following Existing Pattern

Create `validate_topic_directory_slug()` function mirroring `validate_and_generate_filename_slugs()`:

```bash
validate_topic_directory_slug() {
  local classification_result="$1"
  local topic_slug_regex='^[a-z0-9_]{1,40}$'  # 40 chars max for readability

  # Extract from classification result
  local topic_slug
  topic_slug=$(echo "$classification_result" | jq -r '.topic_directory_slug // empty')

  # Tier 1: Validate LLM slug
  if [ -n "$topic_slug" ] && echo "$topic_slug" | grep -Eq "$topic_slug_regex"; then
    # Security: check for path separators
    if echo "$topic_slug" | grep -q '/'; then
      strategy="fallback_extract"
    else
      strategy="llm"
      echo "$topic_slug"
      return 0
    fi
  fi

  # Tier 2: Extract first significant words
  local workflow_desc="${2:-}"
  if [ -n "$workflow_desc" ]; then
    strategy="extract"
    echo "$(extract_significant_words "$workflow_desc")"
    return 0
  fi

  # Tier 3: Sanitize fallback
  strategy="sanitize"
  echo "$(sanitize_topic_name "$workflow_desc")"
  return 0
}
```

### 3. Add Structured Error Handling

Follow WHICH/WHAT/WHERE pattern for all error messages:

```bash
if [ -z "$classification_result" ]; then
  echo "ERROR: validate_topic_directory_slug: classification_result required" >&2
  echo "  WHERE: workflow-initialization.sh, validate_topic_directory_slug()" >&2
  echo "  WHAT: Missing required parameter for slug extraction" >&2
  return 1
fi
```

### 4. Add Logging for Debugging

Extend `log_slug_generation()` or create `log_topic_slug_generation()`:

```bash
log_topic_slug_generation() {
  local strategy="$1"      # llm|extract|sanitize
  local final_slug="$2"
  local workflow_desc="$3"

  # Log to adaptive planning log for monitoring
  log_adaptive_planning "INFO" "Topic slug generated: strategy=$strategy, slug=$final_slug"
}
```

### 5. Ensure Idempotency Compliance

The `get_or_create_topic_number()` function already handles idempotency for topic directories. Ensure the new semantic slug integrates correctly:

```bash
# Semantic slug must be stable for same workflow description
# to enable idempotent topic number lookup
topic_name=$(validate_topic_directory_slug "$classification_result" "$workflow_description")
topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")
```

## References

- `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md:17-36` - Haiku model selection criteria
- `/home/benjamin/.config/.claude/docs/reference/code-standards.md:1-84` - General coding standards
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md:51-77` - lib/ directory standards
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents.md:1447-1529` - Behavioral injection pattern
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:186-226` - Existing validation pattern
- `/home/benjamin/.config/.claude/lib/unified-logger.sh:753-801` - Slug generation logging
- `/home/benjamin/.config/.claude/docs/guides/model-selection-guide.md:292-322` - Agent frontmatter requirements

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_research_option_1_in_home_benjamin_confi_plan.md](../plans/001_research_option_1_in_home_benjamin_confi_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
