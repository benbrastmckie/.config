# Enhanced Topic Generation Guide

**Path**: docs → guides → enhanced-topic-generation-guide.md

Complete guide to LLM-generated research topics with detailed descriptions, filename slugs, and research focus areas for streamlined agent prompt creation.

## Overview

The Enhanced Topic Generation feature (Spec 688) transforms LLM classification from returning simple topic names to returning rich, structured research topics that include:

1. **short_name**: Brief topic identifier (backward compatible)
2. **detailed_description**: Comprehensive 150-250 word research context
3. **filename_slug**: Filesystem-safe lowercase slug for report filenames
4. **research_focus**: Specific questions and investigation areas

This enhancement eliminates the need for separate topic exploration phases and provides agents with ready-to-use context, reducing token consumption and improving research quality.

## Enhanced Response Structure

### Before (Simple Topics)

```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": [
    "Implementation architecture",
    "Integration patterns"
  ],
  "reasoning": "..."
}
```

**Problems**:
- Generic topic names lack context
- Agents must explore topics before researching
- Filenames generated from sanitized topic names (`implementation_architecture.md`)
- No guidance on what to investigate

### After (Enhanced Topics)

```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Implementation architecture",
      "detailed_description": "Analyze current implementation patterns, identify architectural decisions, evaluate scalability approaches, and document integration points with existing systems. This research will provide comprehensive understanding of the system design, module structure, and how components interact. Pay special attention to state management patterns and dependency injection approaches.",
      "filename_slug": "implementation_architecture",
      "research_focus": "Key questions: How is the current system architected? What patterns are used? What are the scalability considerations? Areas to investigate: module structure, dependency management, state handling, design patterns, integration points."
    },
    {
      "short_name": "Integration patterns",
      "detailed_description": "Research best practices for integrating new features with the existing codebase, identify common integration patterns used in the project, and analyze potential conflicts or compatibility issues that may arise during implementation. Document extension points, plugin architecture, and API design patterns that enable safe feature additions.",
      "filename_slug": "integration_patterns",
      "research_focus": "Key questions: How should new features integrate? What are the extension points? How do we maintain backward compatibility? Areas to investigate: API design, event handling, plugin architecture, versioning strategies, feature flags."
    }
  ],
  "reasoning": "..."
}
```

**Benefits**:
- Rich context eliminates exploration phase (30-40% time savings)
- Semantic filename slugs from start (eliminates post-research reconciliation)
- Clear research focus streamlines agent prompts
- Comprehensive descriptions reduce agent confusion

## Field Specifications

### short_name

**Type**: String (1-100 characters)

**Purpose**: Brief, human-readable topic identifier for backward compatibility

**Requirements**:
- Clear, concise topic label
- Used for RESEARCH_TOPICS_JSON backward compatibility
- Displayed in phase headers and logging

**Examples**:
- "Implementation architecture"
- "Security considerations"
- "Performance optimization"
- "Testing strategy"

### detailed_description

**Type**: String (150-500 characters)

**Purpose**: Comprehensive research context for agent prompts

**Requirements**:
- 150-500 characters (enforced by validation)
- Describes what to research and why
- Provides context and scope
- Mentions key areas of investigation
- Avoids imperative instructions (descriptive, not prescriptive)

**Validation**:
```bash
# Too short (<150 chars) - REJECTED
"Research authentication patterns."

# Too long (>500 chars) - REJECTED
"Research authentication patterns including... [600+ characters]"

# Correct (150-500 chars) - ACCEPTED
"Analyze authentication patterns in the codebase including OAuth2, JWT, and session-based approaches. Examine security implications, token management strategies, and integration with existing user management systems. Document best practices and identify potential vulnerabilities."
```

**Best Practices**:
- Start with action verb (Analyze, Research, Investigate, Document)
- Include context (why this research matters)
- Mention 2-3 specific areas to investigate
- Connect to broader project goals

### filename_slug

**Type**: String matching regex `^[a-z0-9_]{1,50}$`

**Purpose**: Filesystem-safe identifier for report filenames

**Requirements**:
- Lowercase letters only (`a-z`)
- Numbers allowed (`0-9`)
- Underscores allowed (`_`)
- Maximum 50 characters
- No spaces, hyphens, or special characters

**Validation**:
```bash
# Valid slugs
implementation_architecture    # PASS
security_oauth2_jwt           # PASS
performance_optimization_v2   # PASS

# Invalid slugs (rejected)
Implementation_Architecture   # FAIL: Uppercase
implementation-architecture   # FAIL: Hyphens
implementation architecture   # FAIL: Spaces
auth_patterns!                # FAIL: Special chars
this_is_a_very_long_filename_that_exceeds_fifty_characters  # FAIL: >50 chars
```

**Three-Tier Fallback**:
1. **LLM slug** (preferred): Use if validates against regex
2. **Sanitized short_name** (fallback): Convert short_name to lowercase, replace spaces with underscores
3. **Generic** (ultimate fallback): Use `topicN` if short_name is empty/invalid

**Example Fallback Flow**:
```bash
# Case 1: Valid LLM slug
filename_slug="implementation_architecture"  # PASS → Use LLM slug

# Case 2: Invalid LLM slug
filename_slug="Implementation-Architecture!"  # FAIL
short_name="Implementation architecture"
# Fallback: sanitize_topic_name() → "implementation_architecture"

# Case 3: Missing both
filename_slug=""
short_name=""
# Ultimate fallback: "topic1"
```

### research_focus

**Type**: String (50-300 characters recommended)

**Purpose**: Specific questions and investigation areas for agent guidance

**Requirements**:
- Starts with "Key questions:" section
- Includes "Areas to investigate:" section
- 3-5 specific questions
- 3-5 investigation areas
- Concrete, actionable guidance

**Format**:
```
Key questions: [Question 1]? [Question 2]? [Question 3]? Areas to investigate: [area1], [area2], [area3], [area4].
```

**Examples**:
```
Key questions: How is authentication currently implemented? What security measures are in place? How are tokens managed? Areas to investigate: OAuth2 implementation, JWT validation, session management, token refresh mechanisms, security audit logs.
```

**Best Practices**:
- Use question format for key questions (ends with `?`)
- Use comma-separated list for areas
- Be specific (not "security" but "OAuth2 token validation")
- Connect questions to areas

## Agent Prompt Streamlining

### Before: Multi-Step Topic Exploration

**Without Enhanced Topics** (3 steps):

1. **Classification**: Get topic name
```json
{"subtopics": ["Implementation architecture"]}
```

2. **Topic Exploration**: Agent explores what to research
```bash
# Agent prompt (200+ tokens)
Analyze the workflow description and determine:
- What specific aspects of implementation architecture to research
- Key areas to investigate
- Questions to answer
- Scope boundaries
```

3. **Research Execution**: Agent researches with context
```bash
# Agent prompt (300+ tokens including exploration results)
Research implementation architecture focusing on [exploration results]...
```

**Total**: 500+ tokens, 2 agent invocations

### After: Direct Research with Context

**With Enhanced Topics** (1 step):

1. **Classification + Context**: Get rich topic structure
```json
{
  "research_topics": [{
    "detailed_description": "Analyze current implementation patterns...",
    "research_focus": "Key questions: How is the system architected?..."
  }]
}
```

2. **Research Execution**: Agent researches immediately
```bash
# Agent prompt (250 tokens - context from LLM)
${detailed_description}

Focus your research on:
${research_focus}
```

**Total**: 250 tokens, 1 agent invocation

**Savings**: 50% token reduction, eliminates exploration phase

### Prompt Template Integration

**Command Integration Example** (from /coordinate):

```bash
# Extract enhanced topic details
topic_description=$(echo "$classification_result" | jq -r ".research_topics[$i].detailed_description")
topic_focus=$(echo "$classification_result" | jq -r ".research_topics[$i].research_focus")
topic_slug=$(echo "$classification_result" | jq -r ".research_topics[$i].filename_slug")

# Build streamlined agent prompt
cat > agent_prompt.md <<EOF
# Research Task: ${topic_slug}

## Context
${topic_description}

## Research Focus
${topic_focus}

## Deliverable
Create report at: specs/${topic_dir}/reports/$(printf "%03d" $((i+1)))_${topic_slug}.md
EOF

# Invoke research agent with context
invoke_research_agent agent_prompt.md
```

**Benefits**:
- Agent receives full context immediately
- No exploration phase needed
- Filename pre-calculated
- Research focus provides structure

## Validation and Error Handling

### Validation Rules

**research_topics Array**:
- Must be array type
- Length must match research_complexity exactly
- Each element must be object with required fields

**Field Validation**:
```bash
# detailed_description
length >= 50 && length <= 500

# filename_slug
slug =~ ^[a-z0-9_]{1,50}$

# research_focus
length > 0 && contains "Key questions:" && contains "Areas to investigate:"

# short_name
length > 0 && length <= 100
```

### Error Messages

**Missing Field**:
```
ERROR: research_topics[0] missing required field 'detailed_description'
  Topic: Implementation architecture
  All topics must include: short_name, detailed_description, filename_slug, research_focus
```

**Invalid Length**:
```
ERROR: research_topics[1].detailed_description too short (45 chars, minimum 50)
  Topic: Integration patterns
  Suggestion: Provide more comprehensive description with context and investigation areas
```

**Invalid Slug**:
```
ERROR: research_topics[0].filename_slug contains invalid characters: "Implementation-Architecture"
  Must match: ^[a-z0-9_]{1,50}$
  Valid example: "implementation_architecture"
```

**Count Mismatch**:
```
ERROR: research_topics count (2) doesn't match research_complexity (3)
  Expected 3 topics, received 2
  LLM must generate exactly research_complexity topics
```

### Fallback Behavior

**LLM Slug Validation Failure**:
```bash
# Validate LLM slug
if ! echo "$filename_slug" | grep -qE '^[a-z0-9_]{1,50}$'; then
  # Fallback: Sanitize short_name
  log_slug_generation "WARN" "Invalid LLM slug, sanitizing short_name"
  filename_slug=$(sanitize_topic_name "$short_name")
fi

# Ultimate fallback
if [ -z "$filename_slug" ]; then
  log_slug_generation "ERROR" "Empty slug after sanitization, using generic fallback"
  filename_slug="topic${topic_index}"
fi
```

**Logging**:
- Strategy used: LLM slug vs sanitized vs generic
- Acceptance rate tracking (target >90%)
- Failure analysis for LLM prompt tuning

## LLM Prompt Engineering

### Prompt Structure

The LLM classifier receives structured instructions for generating enhanced topics:

```json
{
  "task": "classify_workflow",
  "workflow_description": "<user input>",
  "response_format": {
    "workflow_type": "string (research-only|research-and-plan|research-and-revise|full-implementation|debug-only)",
    "confidence": "number (0.0-1.0)",
    "research_complexity": "number (0-4, number of research topics needed)",
    "research_topics": [
      {
        "short_name": "string (brief topic identifier, 1-100 chars)",
        "detailed_description": "string (comprehensive research context, 150-500 chars, describes WHAT to research and WHY)",
        "filename_slug": "string (filesystem-safe lowercase slug, [a-z0-9_]{1,50}, for report filename)",
        "research_focus": "string (specific questions and investigation areas, format: 'Key questions: ...? Areas to investigate: ...')"
      }
    ],
    "reasoning": "string (explanation of classification decision)"
  }
}
```

### Key Instructions

1. **Array Length**: "research_topics array length MUST equal research_complexity exactly"
2. **Description Length**: "detailed_description must be 150-500 characters providing comprehensive research context"
3. **Slug Format**: "filename_slug must be lowercase alphanumeric + underscores only, max 50 chars"
4. **Focus Format**: "research_focus must include 'Key questions:' and 'Areas to investigate:' sections"

### Example Prompts and Responses

**Input**:
```
Workflow: "implement user authentication with OAuth2 and JWT"
```

**Expected Output**:
```json
{
  "workflow_type": "full-implementation",
  "confidence": 0.95,
  "research_complexity": 3,
  "research_topics": [
    {
      "short_name": "OAuth2 implementation patterns",
      "detailed_description": "Research OAuth2 authentication flow implementations in the codebase, analyze existing security measures and token management approaches, evaluate different OAuth2 grant types (authorization code, implicit, client credentials), and document integration points with user management systems. Identify libraries used and configuration patterns.",
      "filename_slug": "oauth2_implementation_patterns",
      "research_focus": "Key questions: Which OAuth2 grant types are currently supported? How are tokens stored and validated? What OAuth2 library is used? Areas to investigate: authorization flow implementation, token storage, refresh token handling, scope management, security configurations."
    },
    {
      "short_name": "JWT token management",
      "detailed_description": "Investigate JWT (JSON Web Token) usage for stateless authentication, analyze token structure and claims, examine signing algorithms and key management practices, and evaluate token expiration and refresh strategies. Document how JWTs integrate with OAuth2 flows and existing session management.",
      "filename_slug": "jwt_token_management",
      "research_focus": "Key questions: What signing algorithm is used for JWTs? How are refresh tokens managed? What claims are included in tokens? Areas to investigate: JWT library selection, signing key storage, token expiration policies, refresh token rotation, claims structure."
    },
    {
      "short_name": "Security considerations",
      "detailed_description": "Analyze security implications of OAuth2 and JWT implementation including CSRF protection, XSS vulnerabilities, token hijacking prevention, and secure storage practices. Review OWASP authentication guidelines and identify potential attack vectors. Document security testing requirements and mitigation strategies.",
      "filename_slug": "security_considerations",
      "research_focus": "Key questions: How are tokens protected from XSS attacks? What CSRF protection is implemented? How are tokens securely stored? Areas to investigate: OWASP authentication best practices, token storage security, HTTPS requirements, CORS configuration, rate limiting."
    }
  ],
  "reasoning": "Full implementation workflow requiring research into OAuth2 and JWT. Three research topics cover implementation patterns, token management, and security considerations."
}
```

## Performance Metrics

### LLM Slug Acceptance Rate

**Target**: >90% of LLM-generated slugs pass validation

**Measurement**:
```bash
# From unified-logger.sh
log_slug_generation "INFO" "strategy=llm_slug" "topic=$short_name" "slug=$filename_slug"
log_slug_generation "WARN" "strategy=sanitized" "topic=$short_name" "slug=$sanitized_slug"
log_slug_generation "ERROR" "strategy=generic" "topic=$short_name" "slug=topic$i"

# Analysis
total=$(grep "log_slug_generation" adaptive-planning.log | wc -l)
llm_slugs=$(grep "strategy=llm_slug" adaptive-planning.log | wc -l)
acceptance_rate=$((llm_slugs * 100 / total))

if [ $acceptance_rate -lt 90 ]; then
  echo "WARNING: LLM slug acceptance rate ${acceptance_rate}% below 90% target"
  echo "Consider tuning LLM prompt for better slug generation"
fi
```

### Context Reduction

**Before**: ~500 tokens per research topic (exploration + research)
**After**: ~250 tokens per research topic (direct research)
**Reduction**: 50%

**Workflow Impact**:
- 3-topic research: 1500 → 750 tokens (750 saved)
- 4-topic research: 2000 → 1000 tokens (1000 saved)
- Enables more research topics within context budget

### Time Savings

**Eliminated Phases**:
1. Topic exploration (30-60 seconds per topic)
2. Filename reconciliation (15-30 seconds total)

**Workflow Improvement**:
- 3-topic research: 90-180 seconds saved
- 4-topic research: 120-240 seconds saved
- 30-40% overall time reduction

## Integration with Existing Commands

### /coordinate Integration

```bash
# Phase 0: Classification with enhanced topics
classification_result=$(sm_init "$workflow_description" "coordinate")

# Extract research_topics array
research_topics_json=$(echo "$classification_result" | jq -r '.research_topics')

# For each topic, extract enhanced fields
for i in $(seq 0 $((RESEARCH_COMPLEXITY - 1))); do
  short_name=$(echo "$research_topics_json" | jq -r ".[$i].short_name")
  detailed_desc=$(echo "$research_topics_json" | jq -r ".[$i].detailed_description")
  filename_slug=$(echo "$research_topics_json" | jq -r ".[$i].filename_slug")
  research_focus=$(echo "$research_topics_json" | jq -r ".[$i].research_focus")

  # Pre-calculate report path with semantic slug
  report_path="${topic_dir}/reports/$(printf "%03d" $((i+1)))_${filename_slug}.md"

  # Create streamlined agent prompt
  invoke_research_agent \
    --topic="$short_name" \
    --description="$detailed_desc" \
    --focus="$research_focus" \
    --output="$report_path"
done
```

### /research Integration

```bash
# Research command with enhanced topic generation
classify_and_research() {
  local description="$1"

  # Get enhanced classification
  local result=$(classify_workflow_comprehensive "$description")

  # Extract enhanced topics
  local topics=$(echo "$result" | jq -r '.research_topics')

  # Research each topic with full context
  echo "$topics" | jq -c '.[]' | while read topic; do
    detailed_desc=$(echo "$topic" | jq -r '.detailed_description')
    research_focus=$(echo "$topic" | jq -r '.research_focus')
    filename_slug=$(echo "$topic" | jq -r '.filename_slug')

    # Research with context (no exploration phase)
    research_agent \
      --context="$detailed_desc" \
      --focus="$research_focus" \
      --output="reports/${filename_slug}.md"
  done
}
```

## Backward Compatibility

### RESEARCH_TOPICS_JSON

**Purpose**: Maintain compatibility with existing code expecting simple topic names

**Implementation**:
```bash
# Extract short_name values for backward compatibility
RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -r '[.research_topics[].short_name]')

# Results in traditional format:
# ["Implementation architecture", "Integration patterns"]
```

**Usage**:
```bash
# Old code still works
for topic in $(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]'); do
  echo "Topic: $topic"
done

# New code uses enhanced structure
research_topics=$(echo "$classification_result" | jq -r '.research_topics')
```

## Best Practices

### 1. Descriptive, Not Prescriptive

**Wrong** (imperative instructions):
```
"Research authentication. Check OAuth2 implementation. Look at JWT validation. Review security measures."
```

**Correct** (descriptive context):
```
"Analysis of authentication patterns including OAuth2 implementation approaches, JWT validation strategies, and security measures. This research provides comprehensive understanding of authentication architecture and identifies best practices for token management."
```

### 2. Provide Context and Scope

**Wrong** (no context):
```
"Implementation architecture of the system."
```

**Correct** (with context):
```
"Analyze current implementation patterns, identify architectural decisions, evaluate scalability approaches, and document integration points with existing systems. This research will provide comprehensive understanding of system design and module structure."
```

### 3. Specific Investigation Areas

**Wrong** (vague areas):
```
"Key questions: How does it work? Areas to investigate: implementation, testing."
```

**Correct** (specific areas):
```
"Key questions: How is the current system architected? What patterns are used? What are the scalability considerations? Areas to investigate: module structure, dependency management, state handling, design patterns, integration points."
```

### 4. Semantic Filename Slugs

**Wrong** (generic/non-descriptive):
```
filename_slug: "topic1"
filename_slug: "impl"
filename_slug: "research_item"
```

**Correct** (semantic):
```
filename_slug: "oauth2_implementation"
filename_slug: "jwt_token_validation"
filename_slug: "security_audit_requirements"
```

## Troubleshooting

### Issue: LLM Slug Acceptance Rate <90%

**Symptoms**: Frequent fallback to sanitized short_name

**Diagnosis**:
```bash
grep "strategy=sanitized" .claude/data/logs/adaptive-planning.log | head -10
```

**Solutions**:
1. Review failed slugs for patterns (uppercase, hyphens, special chars)
2. Enhance LLM prompt with examples of valid slugs
3. Add slug validation feedback to LLM prompt
4. Consider adjusting slug regex if requirements too strict

### Issue: description Validation Failures

**Symptoms**: "detailed_description too short" errors

**Diagnosis**:
```bash
# Check LLM responses
grep "detailed_description too short" workflow-classification.log
```

**Solutions**:
1. Emphasize 150-500 character requirement in LLM prompt
2. Provide examples of good descriptions
3. Add character count guidance ("aim for ~250 characters")

### Issue: research_focus Missing Sections

**Symptoms**: Missing "Key questions:" or "Areas to investigate:"

**Diagnosis**:
```bash
# Validate research_focus format
if ! echo "$research_focus" | grep -q "Key questions:"; then
  echo "ERROR: Missing 'Key questions:' section"
fi
```

**Solutions**:
1. Make format requirements explicit in LLM prompt
2. Provide format template in prompt
3. Add validation feedback to error message

## References

### Implementation Files
- [workflow-llm-classifier.sh](../../lib/workflow/workflow-llm-classifier.sh) - Enhanced topic parsing
- [workflow-initialization.sh](../../lib/workflow/workflow-initialization.sh) - Filename slug validation
- [unified-logger.sh](../../lib/core/unified-logger.sh) - Slug generation logging

### Testing Files
- [test_topic_filename_generation.sh](../../../tests/test_topic_filename_generation.sh) - Enhanced topic tests

### Related Documentation
- [LLM Classification Pattern](../concepts/patterns/llm-classification-pattern.md) - Overall classification pattern
- [Workflow Classification Guide](../orchestration/workflow-classification-guide.md) - 2-mode system guide
- [Implementation Plan](../../specs/688_687_how_exactly_workflow_identified_coordinate/plans/001_fallback_removal_llm_enhancements.md) - Complete implementation history

## Changelog

### 2025-11-13: Initial Documentation

**Created**: Comprehensive guide for enhanced topic generation feature (Spec 688, Phase 1-2)

**Coverage**:
- Enhanced response structure and field specifications
- Validation rules and error handling
- Agent prompt streamlining and integration
- Performance metrics and best practices
- Troubleshooting and references
