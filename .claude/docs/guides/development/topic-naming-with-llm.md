# Topic Naming with LLM Guide

Complete guide to the LLM-based topic naming system for creating semantic directory names.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Agent Integration](#agent-integration)
- [Error Handling](#error-handling)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Prompt Engineering Tips](#prompt-engineering-tips)
- [Testing Guidelines](#testing-guidelines)
- [Cost Analysis](#cost-analysis)

## Overview

The topic naming system uses a Haiku LLM agent (topic-naming-agent) to generate semantic directory names from user prompts. The system analyzes natural language descriptions, extracts technical concepts, and creates readable snake_case directory names.

**Key Benefits**:
- Semantic understanding of user intent (AI-powered analysis)
- Automatic extraction of technical terms and concepts
- Consistent formatting (snake_case, 5-40 characters)
- Fast response time (<3 seconds average)
- Low cost ($0.003 per topic, ~$2.16/year)
- Clear failure visibility (`no_name_error` sentinel)
- Uniform naming across all 7 directory-creating commands

**System Components**:
1. **topic-naming-agent** - Haiku LLM agent for semantic analysis
2. **validate_topic_name_format()** - Format validation (^[a-z0-9_]{5,40}$)
3. **Error logging** - Centralized error tracking
4. **Monitoring scripts** - Failure detection and reporting
5. **Rename helper** - Manual correction for no_name directories

### Exception: /repair Command

The `/repair` command is the **only command** that does NOT use the LLM-based topic-naming-agent. Instead, it uses **timestamp-based naming** to ensure unique directory allocation for each repair run.

**Rationale**:
- Each repair run represents error analysis at a different point in time
- Historical tracking requires separate directories (no idempotent reuse)
- Timestamp uniqueness guarantees new allocation every time
- Zero latency (<10ms) vs 2-3 seconds for LLM invocation
- Zero failure rate vs ~2-5% LLM failure rate

**Naming Pattern**:
```bash
/repair                        → specs/962_repair_20251129_143022/
/repair --command /build       → specs/963_repair_build_20251129_143530/
/repair --type state_error     → specs/964_repair_state_error_20251129_143105/
```

See [Repair Command Guide](../commands/repair-command-guide.md#timestamp-based-spec-directory-naming) for complete details on timestamp-based naming implementation.

## Architecture

### Naming Workflow

```
┌──────────────────────────────────────────────────────────────┐
│ User Command: /plan "Fix JWT token expiration bug"           │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Command Layer (6 commands use topic-naming-agent):           │
│ /plan, /research, /debug, /optimize-claude,                  │
│ /errors, /setup                                              │
│ EXCEPTION: /repair uses timestamp-based naming (no LLM)      │
│ - Sources error-handling library                             │
│ - Invokes topic-naming-agent via Task tool (except /repair)  │
│ - Provides user prompt as context                            │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Topic Naming Agent (Haiku 4.5)                               │
│ - Semantic analysis (understands 5-15 word prompts)          │
│ - Extracts: technical terms, action verbs, domain concepts   │
│ - Formats: snake_case (5-40 chars)                           │
│ - Returns: TOPIC_NAME_GENERATED: jwt_token_expiration_fix    │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Command Validation & Fallback                                │
│ - Parse completion signal (TOPIC_NAME_GENERATED: name)       │
│ - Validate format: ^[a-z0-9_]{5,40}$                         │
│ - Success? → Use LLM name                                    │
│ - Failure? → Fallback to "no_name" + log error              │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Topic Allocation (allocate_and_create_topic)                 │
│ - Atomic topic number allocation                             │
│ - Creates: NNN_jwt_token_expiration_fix/ or NNN_no_name/    │
└──────────────────────────────────────────────────────────────┘
```

### Agent Behavioral Guidelines

The topic-naming-agent follows a 4-step workflow:

**STEP 1: Receive and Verify Prompt**
- Receives user's feature description from command
- Verifies prompt is not empty
- Returns error if no description provided

**STEP 2: Generate Semantic Topic Name**
- Analyzes semantic meaning (5-15 word understanding)
- Extracts technical terms, action verbs, domain concepts
- Removes filler words, planning meta-language
- Formats as snake_case (lowercase, underscores)
- Targets 5-40 character length

**STEP 3: Validate Format**
- Checks pattern: ^[a-z0-9_]{5,40}$
- Ensures no consecutive underscores
- Ensures alphanumeric start/end characters
- Returns validation_error if invalid

**STEP 4: Return Completion Signal**
- Returns: TOPIC_NAME_GENERATED: {name}
- Example: TOPIC_NAME_GENERATED: jwt_token_expiration_fix
- Command parses signal and validates format

## Agent Integration

### Standard Integration Pattern

All commands that create topic directories use this pattern:

```bash
#!/usr/bin/env bash
# Source required libraries
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || {
  echo "Error: Cannot load error-handling library"
  exit 1
}
source "$CLAUDE_LIB/plan/topic-utils.sh" 2>/dev/null || {
  echo "Error: Cannot load topic-utils library"
  exit 1
}

# Initialize error logging
ensure_error_log_exists

# Set command metadata
COMMAND_NAME="/plan"  # or /research, /debug, /optimize-claude
WORKFLOW_ID="workflow_$(date +%s)"
USER_ARGS="$*"

# Get user's feature description
USER_DESCRIPTION="$1"

# Invoke topic-naming-agent via Task tool
AGENT_OUTPUT=$(invoke_topic_naming_agent "$USER_DESCRIPTION")

# Parse completion signal
TOPIC_NAME=""
if echo "$AGENT_OUTPUT" | grep -q "TOPIC_NAME_GENERATED:"; then
  TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME_GENERATED:" | sed 's/TOPIC_NAME_GENERATED: *//')

  # Validate format
  if ! validate_topic_name_format "$TOPIC_NAME"; then
    # Validation failed: log and fallback
    log_command_error "validation_error" \
      "Topic name validation failed" \
      "name=$TOPIC_NAME,pattern=^[a-z0-9_]{5,40}$"
    TOPIC_NAME="no_name_error"
  fi
else
  # Agent failed to return completion signal
  log_command_error "agent_error" \
    "Topic naming agent failed to return completion signal" \
    "prompt=$USER_DESCRIPTION"
  TOPIC_NAME="no_name_error"
fi

# Handle timeout (if agent took >5s)
if [ -z "$TOPIC_NAME" ]; then
  log_command_error "timeout_error" \
    "Topic naming agent timeout" \
    "prompt=$USER_DESCRIPTION"
  TOPIC_NAME="no_name_error"
fi

# Atomically allocate topic directory
RESULT=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_NAME")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  exit 1
fi

# Extract topic number and path
TOPIC_NUMBER="${RESULT%|*}"
TOPIC_PATH="${RESULT#*|}"

echo "Created topic: ${TOPIC_NUMBER}_${TOPIC_NAME}"
```

### Command-Specific Integration

**All 7 Directory-Creating Commands**:
```markdown
# Commands using topic-naming-agent:
# /plan, /research, /debug, /optimize-claude, /errors, /setup, /repair

Source error-handling library and topic-utils.sh.
Initialize error log with ensure_error_log_exists.
Set COMMAND_NAME="/command", WORKFLOW_ID, USER_ARGS.

Invoke topic-naming-agent with user's feature description.
Parse TOPIC_NAME_GENERATED signal.
Validate format with validate_topic_name_format().
On failure: log error (agent_error, validation_error, timeout_error).
On failure: fall back to TOPIC_NAME="no_name_error".

Pass topic name to allocate_and_create_topic().
```

| Command | COMMAND_NAME | Notes |
|---------|--------------|-------|
| /plan | "/plan" | Creates implementation plans |
| /research | "/research" | Creates research reports |
| /debug | "/debug" | Creates debug analysis |
| /optimize-claude | "/optimize-claude" | Creates optimization analysis |
| /errors | "/errors" | Creates error analysis reports |
| /setup | "/setup" | Creates setup analysis (analyze mode only) |
| /repair | "/repair" | Creates error repair plans |

## Error Handling

### Failure Modes

**1. Agent Timeout (>5s response)**
```bash
# Log timeout error
log_command_error "timeout_error" \
  "Topic naming agent timeout" \
  "prompt=$USER_DESCRIPTION,duration=${ELAPSED_TIME}s"

# Fallback to no_name
TOPIC_NAME="no_name_error"
```

**2. API Error (Haiku unavailable)**
```bash
# Agent returns TASK_ERROR signal
if echo "$AGENT_OUTPUT" | grep -q "TASK_ERROR:"; then
  ERROR_MSG=$(echo "$AGENT_OUTPUT" | grep "TASK_ERROR:" | sed 's/TASK_ERROR: *//')

  # Log agent error
  log_command_error "agent_error" \
    "Topic naming agent returned error" \
    "error=$ERROR_MSG,prompt=$USER_DESCRIPTION"

  # Fallback to no_name
  TOPIC_NAME="no_name_error"
fi
```

**3. Validation Failure (invalid format)**
```bash
# Validate format: ^[a-z0-9_]{5,40}$
if ! validate_topic_name_format "$TOPIC_NAME"; then
  # Log validation error
  log_command_error "validation_error" \
    "Invalid topic name format" \
    "name=$TOPIC_NAME,pattern=^[a-z0-9_]{5,40}$"

  # Fallback to no_name
  TOPIC_NAME="no_name_error"
fi
```

**4. Empty Prompt (user provides no description)**
```bash
# Skip agent invocation, use no_name directly
if [ -z "$USER_DESCRIPTION" ]; then
  TOPIC_NAME="no_name_error"
  # No error logged (expected behavior)
fi
```

**5. No Completion Signal (agent returns unexpected output)**
```bash
# Check for completion signal
if ! echo "$AGENT_OUTPUT" | grep -q "TOPIC_NAME_GENERATED:"; then
  # Log parse error
  log_command_error "parse_error" \
    "Failed to parse agent output" \
    "output=${AGENT_OUTPUT:0:200}"

  # Fallback to no_name
  TOPIC_NAME="no_name_error"
fi
```

### Error Logging Integration

All failures are logged to centralized error log (`~/.claude/data/errors.jsonl`):

```json
{
  "timestamp": "2025-11-20T14:30:45Z",
  "command": "/plan",
  "workflow_id": "workflow_1732114245",
  "error_type": "agent_error",
  "message": "Topic naming agent timeout",
  "details": {
    "prompt": "Fix JWT token expiration bug causing login failures",
    "duration": "6.2s"
  }
}
```

**Querying Errors**:
```bash
# View recent naming failures
/errors --type agent_error --command /plan --since 1h

# View all naming errors (all types)
/errors --command /plan --since 1week --summary

# View specific error type
/errors --type validation_error --limit 10
```

## Monitoring and Troubleshooting

### Monitoring Script

Use `check_no_name_directories.sh` to monitor naming failures:

```bash
# Check for naming failures
.claude/scripts/check_no_name_directories.sh

# Output:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Topic Naming Agent Failure Monitor
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Specs Directory: /home/user/.config/.claude/specs
#
# [32m✓ No topic naming failures found[0m
#
# All topics have semantic names generated by the topic-naming-agent.
```

If failures exist:
```bash
# Output shows no_name_error directories:
# ⚠ Found 2 topic naming failures:
#
#   867_no_name_error  (created: 2025-11-20 14:30)
#   868_no_name_error  (created: 2025-11-20 15:15)
#
# To investigate failures:
#   /errors --type agent_error --command /plan
#
# To rename manually:
#   .claude/scripts/rename_no_name_directory.sh specs/867_no_name_error jwt_token_fix
```

### Manual Rename Helper

Rename `no_name_error` directories with semantic names:

```bash
# Rename a no_name_error directory
.claude/scripts/rename_no_name_directory.sh \
  /home/user/.config/.claude/specs/867_no_name_error \
  jwt_token_expiration_fix

# Script validates:
# - Source directory exists and ends with _no_name_error
# - New name matches format (^[a-z0-9_]{5,40}$)
# - Target directory doesn't exist
# - Prompts for confirmation before rename
```

### Troubleshooting Common Issues

**Issue: High no_name_error failure rate (>5%)**

Causes:
- Agent timeout (Haiku API latency)
- Validation failures (agent returning invalid format)
- Empty prompts (user not providing descriptions)

Investigation:
```bash
# Check error types
/errors --command /plan --since 1week --summary

# View specific failures
/errors --type timeout_error --limit 10
/errors --type validation_error --limit 10
```

Solutions:
- Timeout: Increase timeout threshold (currently 5s)
- Validation: Review agent behavioral guidelines
- Empty prompts: Add prompt validation in commands

**Issue: Agent returns generic names**

Causes:
- User prompt too vague ("fix bug", "update code")
- Prompt lacks technical context

Solutions:
- Use specific technical terms in prompts
- Include component/feature names
- Provide context about what's being changed

**Issue: Agent returns invalid format**

Causes:
- Agent returns uppercase letters
- Agent includes special characters
- Agent returns name too short (<5 chars) or too long (>40 chars)

Investigation:
```bash
# View validation failures
/errors --type validation_error --limit 10 | grep "name="
```

Solutions:
- Review agent behavioral guidelines (STEP 3 validation)
- Update agent prompt if systematic validation failures
- Add examples of valid/invalid names to agent guidelines

## Prompt Engineering Tips

### Good User Prompts

Provide clear, specific technical descriptions:

**Good Examples**:
| User Prompt | Generated Name | Why Good |
|-------------|----------------|----------|
| "Fix JWT token expiration bug in auth middleware" | `jwt_token_expiration_fix` | Specific technical terms |
| "Implement OAuth2 authentication with SSO support" | `oauth2_auth_sso_implementation` | Clear feature description |
| "Refactor state machine transitions in build command" | `state_machine_transitions_refactor` | Specific component + action |
| "Add rate limiting to API gateway endpoints" | `api_gateway_rate_limiting` | Clear feature + location |
| "Research database connection pooling strategies" | `database_connection_pooling` | Specific technical topic |

**What Makes These Good**:
- Include technical terms (JWT, OAuth2, state machine, rate limiting)
- Specify components (auth middleware, API gateway, build command)
- Clear action verbs (fix, implement, refactor, add, research)
- No filler words ("carefully", "please", "I want to")

### Poor User Prompts

Avoid vague, generic descriptions:

**Poor Examples**:
| User Prompt | Generated Name | Problem |
|-------------|----------------|---------|
| "Fix bug" | `no_name` | Too vague, no context |
| "Update code" | `code_update` | Generic, not descriptive |
| "Improve performance" | `improve_performance` | No specifics about what |
| "Please carefully research authentication" | `authentication_research` | Filler words ("please", "carefully") |
| "" (empty) | `no_name` | No prompt provided |

**What Makes These Poor**:
- Too generic ("bug", "code", "performance")
- No technical context or component names
- Filler words that don't add meaning
- Empty or minimal descriptions

### Prompt Best Practices

**Include**:
- Technical terms: JWT, OAuth, async, database, API, state machine
- Component names: auth middleware, build command, API gateway
- Action verbs: fix, implement, refactor, add, optimize
- Context: bug causing X, feature for Y, migration from Z

**Avoid**:
- Filler words: carefully, please, very, really, just
- Planning meta-language: create plan, research and implement
- Generic terms: thing, stuff, code, file, update

**Examples**:

❌ "carefully research and create plan to implement authentication"
✓ "implement JWT authentication with refresh tokens"

❌ "fix the bug in the code"
✓ "fix race condition in topic allocation function"

❌ "update the configuration file"
✓ "migrate OAuth config from JSON to environment variables"

## Testing Guidelines

### Unit Testing

Test agent invocation and format validation:

```bash
# Run agent unit tests
.claude/tests/test_topic_naming_agent.sh

# Tests:
# - Completion signal parsing (TOPIC_NAME_GENERATED:)
# - Format validation (^[a-z0-9_]{5,40}$)
# - Valid name examples (28 tests)
# - Error signal parsing (TASK_ERROR:)
```

### Fallback Testing

Test failure modes and fallback behavior:

```bash
# Run fallback tests
.claude/tests/test_topic_naming_fallback.sh

# Tests:
# - Agent timeout → no_name fallback
# - Validation failure → no_name fallback
# - Empty prompt → no_name fallback
# - Agent error → no_name fallback
# - Error logging integration (35 tests)
```

### Integration Testing

Test end-to-end command integration:

```bash
# Run integration tests
.claude/tests/test_topic_naming_integration.sh

# Tests:
# - /plan command integration
# - /research command integration
# - /debug command integration
# - /optimize-claude command integration
# - Error logging across all commands (22 tests)
```

### Manual Testing

Test with real commands:

```bash
# Test /plan with good prompt
/plan "Implement JWT authentication with refresh tokens"
# Expected: Topic created with semantic name (e.g., 868_jwt_auth_refresh_tokens/)

# Test /plan with vague prompt
/plan "fix bug"
# Expected: 869_no_name/ created (or generic name like "bug_fix")

# Test /research with complex prompt
/research "Analyze OAuth2 authentication patterns for migration from basic auth"
# Expected: Topic created with semantic name (e.g., 870_oauth2_auth_migration/)

# Verify error logging
/errors --type agent_error --limit 5
# Should show any naming failures with details
```

## Cost Analysis

### Per-Topic Cost

**LLM Usage**:
- Agent prompt: ~800 tokens (behavioral guidelines)
- User description: ~100-200 tokens (feature description)
- Output: ~50 tokens (topic name + signal)
- **Total**: ~1,000 tokens per invocation

**Haiku 4.5 Pricing**:
- Input: $0.0003/1K tokens
- Output: $0.0015/1K tokens
- **Per topic**: ~$0.003

### Annual Projections

**Active Development** (10-15 topics/week):
- Weekly topics: ~12
- Monthly topics: ~60
- Annual topics: ~720
- **Annual cost**: 720 × $0.003 = **$2.16/year**

**Heavy Development** (20-25 topics/week):
- Weekly topics: ~22
- Monthly topics: ~100
- Annual topics: ~1,200
- **Annual cost**: 1,200 × $0.003 = **$3.60/year**

### Cost vs Maintenance Comparison

**LLM System**:
- Annual LLM cost: $2.16/year
- Maintenance: ~0.5 hours/month × $50/hour = $25/month = $300/year
- **Total**: $302.16/year

**Previous Rule-Based System**:
- Annual LLM cost: $0
- Maintenance: ~3.5 hours/month × $50/hour = $175/month = $2,100/year
- **Total**: $2,100/year

**Net Savings**: $2,100 - $302 = **$1,798/year** (85.6% reduction)

### Cost Monitoring

Monitor actual costs:

```bash
# Count topics created in last month
ls -1d .claude/specs/[0-9][0-9][0-9]_* | \
  xargs stat --format='%Y %n' | \
  awk -v cutoff="$(date -d '30 days ago' +%s)" '$1 > cutoff' | \
  wc -l

# Calculate monthly cost
# (topic_count) × $0.003 = monthly cost

# Example: 60 topics/month
# 60 × $0.003 = $0.18/month = $2.16/year
```

## Related Documentation

- **[Directory Protocols](../../concepts/directory-protocols.md)** - Topic-based artifact organization
- **[Error Handling Pattern](../../concepts/patterns/error-handling.md)** - Centralized error logging
- **[Topic Naming Agent](.claude/agents/topic-naming-agent.md)** - Agent behavioral guidelines
- **[Topic Utils Library](.claude/lib/plan/topic-utils.sh)** - Topic directory utilities
