# Workflow-Classifier Agent Integration Pattern

**Report Type**: Research Investigation
**Created**: 2025-11-14
**Scope**: Workflow-classifier agent invocation pattern for /coordinate command
**Status**: Complete
**Parent Report**: [Comprehensive Overview](OVERVIEW.md)

---

## Executive Summary

This report documents the correct pattern for integrating the workflow-classifier agent into orchestration commands before calling `sm_init()`. The current /coordinate command calls `sm_init()` without pre-computed classification, causing it to fail with unbound variable errors. The solution requires invoking the workflow-classifier agent via the Task tool in Phase 0, parsing the returned JSON classification, and passing those results to a refactored `sm_init()` function.

**Key Findings**:
1. **Broken Pattern**: Current /coordinate calls `sm_init()` expecting internal classification (deprecated since Spec 1763161992 Phase 2)
2. **Correct Pattern**: Commands must invoke workflow-classifier agent BEFORE `sm_init()`, then pass classification as parameters
3. **Agent Behavioral File**: `.claude/agents/workflow-classifier.md` defines complete 4-step classification process with validation
4. **Required Libraries**: `workflow-llm-classifier.sh` (parsing/validation only, NOT invocation), `workflow-state-machine.sh` (refactored sm_init)
5. **Output Format**: `CLASSIFICATION_COMPLETE: {JSON}` with workflow_type, confidence, research_complexity, research_topics

---

## Research Focus Areas

### 1. Workflow-Classifier Agent Behavioral File Analysis

**Location**: `/home/benjamin/.config/.claude/agents/workflow-classifier.md`

**Agent Configuration** (Lines 1-7):
```yaml
allowed-tools: None
description: Fast semantic workflow classification for orchestration commands
model: haiku
model-justification: Classification is fast, deterministic task requiring <5s response time
fallback-model: sonnet-4.5
```

**Classification Process** (4 Required Steps):

#### Step 1: Receive and Verify Workflow Description (Lines 24-35)
- **MANDATORY INPUTS**: Workflow Description, Command Name
- **CHECKPOINT**: Must have both inputs before proceeding to Step 2
- Failure to verify inputs violates agent behavioral contract

#### Step 2: Perform Semantic Classification (Lines 38-173)
- **Workflow Type Classification** (Lines 46-106):
  - `research-only`: User wants to learn/understand (no plans or code)
  - `research-and-plan`: Research to inform NEW plan creation
  - `research-and-revise`: Research to update EXISTING plan
  - `full-implementation`: Complete workflow (research → plan → implement → test → debug → document)
  - `debug-only`: Root cause analysis and bug fixing

- **CRITICAL SEMANTIC ANALYSIS RULES** (Lines 90-106):
  - Quoted keywords indicate TOPIC not INTENT ("research the 'implement' command" → research-only)
  - Negations mean NOT doing X ("don't revise" → NOT research-and-revise)
  - Ambiguous descriptions require context analysis
  - Multiple phases classify as highest scope

- **Research Complexity** (Lines 110-133):
  - 1 (Simple): Single narrow topic
  - 2 (Medium): 2 related topics
  - 3 (Complex): 3 topics, multiple integration points
  - 4 (Very Complex): 4 topics, extensive architectural scope
  - **RULE**: Topic count MUST EXACTLY MATCH complexity score

- **Research Topics Structure** (Lines 136-172):
  ```json
  {
    "short_name": "Topic name (3-8 words)",
    "detailed_description": "What to research and why (50-500 characters)",
    "filename_slug": "topic_name_slug",
    "research_focus": "Key questions to answer (50-300 characters)"
  }
  ```
  - **Validation Rules**:
    - `detailed_description`: 50-500 characters (STRICT)
    - `filename_slug`: `^[a-z0-9_]{1,50}$` (lowercase, numbers, underscores only)
    - `research_focus`: 50-300 characters

#### Step 3: Validate Classification (Lines 178-209)
**Validation Checklist** (5 categories, 14 criteria):
1. Workflow Type: Valid enum, reflects PRIMARY INTENT
2. Research Complexity: Integer 1-4, matches scope
3. Research Topics: Count matches complexity, all required fields, length validation, slug validation
4. Confidence: Float 0.0-1.0
5. Reasoning: Brief explanation (1-3 sentences)

#### Step 4: Return Classification Result (Lines 213-248)
**Output Format**:
```
CLASSIFICATION_COMPLETE: {
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Authentication Patterns",
      "detailed_description": "Analyze current authentication implementation...",
      "filename_slug": "authentication_patterns",
      "research_focus": "How is auth currently handled?..."
    }
  ],
  "reasoning": "Description indicates research to inform plan creation..."
}
```

**CRITICAL REQUIREMENTS**:
- Start with `CLASSIFICATION_COMPLETE:` signal
- Follow with valid JSON object
- NO additional commentary

**Edge Cases Documented** (Lines 251-403):
- Ambiguous workflow types (quoted keywords, negations)
- Empty/minimal descriptions (conservative classification)
- Multi-phase descriptions (classify as highest scope)

---

### 2. Expected Input/Output Format

#### Input Format (Command to Agent)

Commands invoke workflow-classifier via Task tool with:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}
```

**Key Elements**:
1. **Behavioral File Reference**: Full absolute path to agent behavioral file
2. **Workflow Context**: Description + command name (both required)
3. **Completion Signal**: Explicit expected return format
4. **Timeout**: 30000ms (30 seconds) - classification should complete in <5s

#### Output Format (Agent to Command)

Agent returns text containing:
```
CLASSIFICATION_COMPLETE: {
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "...",
      "detailed_description": "...",
      "filename_slug": "...",
      "research_focus": "..."
    }
  ],
  "reasoning": "..."
}
```

Commands parse this using:
```bash
# Extract JSON after CLASSIFICATION_COMPLETE: signal
CLASSIFICATION_JSON=$(echo "$AGENT_OUTPUT" | grep -A 100 "CLASSIFICATION_COMPLETE:" | tail -n +2)

# Parse fields using jq
WORKFLOW_SCOPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity')
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_JSON" | jq -c '.research_topics')

# Verify parsing succeeded
if [ -z "$WORKFLOW_SCOPE" ] || [ -z "$RESEARCH_COMPLEXITY" ] || [ -z "$RESEARCH_TOPICS_JSON" ]; then
  handle_state_error "Failed to parse classification from agent" 1
fi
```

---

### 3. Successful Integration Examples

#### Example 1: Infrastructure Revision Analysis (Spec 1763161992)

**File**: `.claude/specs/1763161992_setup_command_refactoring/reports/infrastructure_revision_analysis.md`
**Lines**: 106-126

**Correct Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent.

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/workflow-classifier.md

    **Workflow Description**: ${WORKFLOW_DESC}
    Return: CLASSIFICATION_COMPLETE: {JSON}
  "
}
```

**Key Success Factor**: Imperative language ("EXECUTE NOW", "USE the Task tool") prevents documentation-only interpretation

#### Example 2: Agent Invocation Pattern Report (Spec 1763161992)

**File**: `.claude/specs/1763161992_setup_command_refactoring/reports/001_llm_classification_state_machine_integration/001_agent_invocation_pattern_and_task_tool_integration.md`
**Lines**: 326-366

**Complete Integration Pattern**:
```markdown
## Phase 0: Workflow Classification

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

**EXECUTE NOW**: Parse classification result and initialize state machine:

```bash
# Parse classification JSON from agent return
WORKFLOW_SCOPE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.workflow_type')
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_RESULT" | jq -r '.research_complexity')
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_RESULT" | jq -c '.research_topics')

# Initialize state machine with classification results
sm_init_with_classification "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"

# Verify state machine initialization
verify_state_variable "WORKFLOW_SCOPE" "State machine initialization" || exit 1
```
```

**Success Factors**:
1. Explicit "EXECUTE NOW" directives prevent skipping
2. Agent behavioral file reference (absolute path)
3. Workflow context injection (description + command name)
4. Parsing verification with error handling
5. State machine initialization with classification parameters

---

### 4. Behavioral Injection Pattern (Standard 11)

#### Pattern Definition

**Source**: `.claude/docs/concepts/patterns/behavioral-injection.md` (Lines 1-200)

**Core Principle**: Commands inject context into agents via file reads, NOT via SlashCommand tool invocations. This enables hierarchical multi-agent patterns and prevents direct execution.

**Two Critical Problems Solved**:
1. **Role Ambiguity**: Without explicit orchestrator role declaration, Claude interprets "I'll research" as "execute directly" instead of "delegate to agents"
2. **Context Bloat**: Command-to-command invocations nest full prompts, causing exponential context growth

**Implementation Structure**:

**Phase 0: Role Clarification** (Lines 43-62):
```markdown
## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:

1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself using Read/Grep/Write/Edit tools

YOU MUST NOT:
- Execute research directly (use research-specialist agent)
- Create plans directly (use planner-specialist agent)
- Implement code directly (use implementer agent)
- Write documentation directly (use doc-writer agent)
```

**Context Injection via File Content** (Lines 84-102):
- Inject paths, constraints, specifications into agent prompts
- Agent reads behavioral file + injected context
- No tool invocations between command and agent

**Performance Results**:
- 100% file creation rate (explicit path injection)
- <30% context usage (avoid nested command prompts)
- 95%+ context reduction via hierarchical supervision

#### Standard 11: Imperative Agent Invocation Pattern

**Source**: `.claude/docs/reference/command_architecture_standards.md` (Lines 200-275)

**Pattern Requirements** (Lines 79-99):
```markdown
**EXECUTE NOW - Calculate Report Paths**

Run this code block BEFORE invoking agents:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
WORKFLOW_TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" ".claude/specs")

declare -A REPORT_PATHS
for topic in "${TOPICS[@]}"; do
  REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "${topic}" "")
  REPORT_PATHS["$topic"]="$REPORT_PATH"
  echo "Pre-calculated path: $REPORT_PATH"
done
```

**Verification**: Confirm paths calculated for all topics before continuing.
```

**Anti-Pattern: Documentation-Only YAML Blocks**

❌ **WRONG** (Lines documented in behavioral-injection.md):
```yaml
# Documentation block describing agent invocation (Claude skips)
agent_invocation:
  tool: Task
  agent: workflow-classifier
  description: Classify workflow scope
```

✅ **CORRECT**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent.

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent"
  prompt: "..."
}
```

---

### 5. Required Libraries to Source

#### Library 1: workflow-llm-classifier.sh

**Location**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`

**Purpose**: Parsing and validation utilities (NOT agent invocation)

**Critical Functions**:

1. **`build_llm_classifier_input()`** (Lines 206-266):
   - Builds JSON payload for LLM classifier
   - NOT used for Task tool invocation (agent receives plain text prompt)
   - Could be adapted for prompt construction

2. **`parse_llm_classifier_response()`** (Lines 292-460):
   - Validates and parses LLM JSON response
   - Validates workflow_type enum
   - Validates research_complexity range (1-4)
   - Validates research_topics array structure
   - Validates detailed_description length (50-500 characters)
   - Validates filename_slug regex: `^[a-z0-9_]{1,50}$`
   - Returns validated JSON to stdout

3. **`handle_llm_classification_failure()`** (Lines 466-527):
   - Structured error handling for classification failures
   - Provides actionable suggestions based on error type
   - Error types: timeout, api_error, low_confidence, parse_error, invalid_mode, network

**REMOVED Functions** (Spec 1763161992 Phase 3, Lines 287-290):
- `invoke_llm_classifier()` - DELETED (100% timeout rate with file-based signaling)
- `cleanup_workflow_classification_files()` - DELETED (no temp files with agent-based approach)

**Usage Pattern** (NOT in commands, for reference only):
```bash
# Commands DO NOT call these functions directly
# Agent invocation via Task tool replaces invoke_llm_classifier()

# After agent returns classification, validate using:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-llm-classifier.sh"
if ! validated_json=$(parse_llm_classifier_response "$AGENT_OUTPUT" "comprehensive"); then
  handle_llm_classification_failure "parse_error" "Failed to parse agent response" "$WORKFLOW_DESC"
  exit 1
fi
```

#### Library 2: workflow-state-machine.sh

**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

**Purpose**: State machine abstraction for orchestration commands

**Critical Function: `sm_init()`** (Lines 334-399):

**BREAKING CHANGE** (Spec 1763161992 Phase 2, Lines 338-339):
> Classification now performed by invoking command BEFORE sm_init.
> sm_init accepts classification results as parameters (no internal classification).

**Function Signature** (Line 335):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_type="$3"
  local research_complexity="$4"
  local research_topics_json="$5"
}
```

**Parameter Validation** (Lines 352-364):
- Checks all 5 parameters provided
- Fails fast if missing: `ERROR: sm_init requires classification parameters`
- Error message directs to workflow-classifier agent (Lines 361-362):
  ```
  IMPORTANT: Commands must invoke workflow-classifier agent BEFORE calling sm_init
  See: .claude/agents/workflow-classifier.md
  ```

**Workflow Type Validation** (Lines 367-376):
- Valid types: `research-only`, `research-and-plan`, `research-and-revise`, `full-implementation`, `debug-only`
- Enum validation with clear error message

**Research Complexity Validation** (Lines 379-382):
- Must be integer 1-4
- Regex validation: `^[0-9]+$`

**Research Topics JSON Validation** (Lines 385-389):
- Must be valid JSON array
- Uses `jq -e 'type == "array"'`

**State Export** (Lines 391-399):
```bash
# Store validated classification parameters
WORKFLOW_SCOPE="$workflow_type"
RESEARCH_COMPLEXITY="$research_complexity"
RESEARCH_TOPICS_JSON="$research_topics_json"

export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
```

**Required Sourcing Pattern**:
```bash
# Source state machine library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

# Invoke workflow-classifier agent first
# (Task tool invocation here)

# Parse agent response
WORKFLOW_TYPE=$(echo "$AGENT_OUTPUT" | jq -r '.workflow_type')
RESEARCH_COMPLEXITY=$(echo "$AGENT_OUTPUT" | jq -r '.research_complexity')
RESEARCH_TOPICS_JSON=$(echo "$AGENT_OUTPUT" | jq -c '.research_topics')

# Initialize state machine with classification
sm_init "$WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"

# Verify exports succeeded
verify_state_variable "WORKFLOW_SCOPE" "State machine initialization" || exit 1
```

---

## Integration Sequence Diagram

```
Command File (.claude/commands/coordinate.md)
│
├─ Phase 0 (Part 2): State Machine Initialization
│  │
│  ├─ Source Libraries
│  │  ├─ workflow-state-machine.sh (provides sm_init function)
│  │  ├─ error-handling.sh (provides handle_state_error)
│  │  └─ verification-helpers.sh (provides verify_state_variable)
│  │
│  ├─ [NEW] Phase 0.1: Workflow Classification (ADD BEFORE sm_init)
│  │  │
│  │  ├─ Invoke workflow-classifier agent via Task tool
│  │  │  └─ Agent reads: .claude/agents/workflow-classifier.md
│  │  │     └─ Returns: CLASSIFICATION_COMPLETE: {JSON}
│  │  │
│  │  ├─ Parse agent response
│  │  │  ├─ Extract workflow_type
│  │  │  ├─ Extract research_complexity
│  │  │  └─ Extract research_topics (JSON array)
│  │  │
│  │  └─ Verify parsing succeeded (fail-fast if not)
│  │
│  ├─ [MODIFIED] Call sm_init with classification parameters
│  │  └─ sm_init "$WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"
│  │     │
│  │     ├─ Validate parameters (fail-fast)
│  │     ├─ Export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
│  │     └─ Calculate terminal state
│  │
│  └─ Verify state machine variables exported
│     ├─ verify_state_variable "WORKFLOW_SCOPE"
│     ├─ verify_state_variable "RESEARCH_COMPLEXITY"
│     └─ verify_state_variable "RESEARCH_TOPICS_JSON"
│
└─ Continue with remaining phases (research, plan, implement, etc.)
```

---

## Recommended Implementation Pattern

### Step 1: Add Phase 0.1 Classification Block

**Location**: `.claude/commands/coordinate.md` (INSERT AFTER LINE 138, BEFORE LINE 163)

**Content**:
```markdown
## Phase 0.1: Workflow Classification

**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow intent for orchestration"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md

    **Workflow-Specific Context**:
    - Workflow Description: $SAVED_WORKFLOW_DESC
    - Command Name: coordinate

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

**EXECUTE NOW**: Parse classification result from agent response:

```bash
# Extract JSON after CLASSIFICATION_COMPLETE: signal
CLASSIFICATION_JSON=$(echo "$AGENT_RESPONSE" | grep -oP 'CLASSIFICATION_COMPLETE:\s*\K.*' | head -1)

# Verify JSON extracted
if [ -z "$CLASSIFICATION_JSON" ]; then
  handle_state_error "Agent did not return CLASSIFICATION_COMPLETE signal. Agent output: $AGENT_RESPONSE" 1
fi

# Parse classification fields using jq
WORKFLOW_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type // empty')
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity // empty')
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_JSON" | jq -c '.research_topics // empty')

# Verification checkpoint (Standard 0: Execution Enforcement)
if [ -z "$WORKFLOW_TYPE" ]; then
  handle_state_error "Failed to parse workflow_type from classification JSON: $CLASSIFICATION_JSON" 1
fi

if [ -z "$RESEARCH_COMPLEXITY" ]; then
  handle_state_error "Failed to parse research_complexity from classification JSON: $CLASSIFICATION_JSON" 1
fi

if [ -z "$RESEARCH_TOPICS_JSON" ] || [ "$RESEARCH_TOPICS_JSON" = "null" ]; then
  handle_state_error "Failed to parse research_topics from classification JSON: $CLASSIFICATION_JSON" 1
fi

echo "✓ Classification parsed: type=$WORKFLOW_TYPE, complexity=$RESEARCH_COMPLEXITY"

# Export for sm_init consumption
export WORKFLOW_TYPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
```
```

### Step 2: Modify sm_init Call

**Location**: `.claude/commands/coordinate.md` (LINE 167)

**Change FROM**:
```bash
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
# Do NOT use command substitution $() as it creates subshell that doesn't export to parent
# WORKAROUND: Use exit code capture instead of bare '!' to avoid bash history expansion (Spec 700, Report 1)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed (workflow classification error). Check network connection or use WORKFLOW_CLASSIFICATION_MODE=regex-only for offline development." 1
fi
```

**Change TO**:
```bash
# CRITICAL: Call sm_init with pre-computed classification from Phase 0.1
# sm_init now requires classification parameters (Spec 1763161992 Phase 2)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed. Classification parameters: type=$WORKFLOW_TYPE, complexity=$RESEARCH_COMPLEXITY" 1
fi
```

### Step 3: Verification Checkpoints

**Location**: `.claude/commands/coordinate.md` (LINES 174-188, MODIFY)

**Keep existing verification** (already correct):
```bash
# VERIFICATION CHECKPOINT: Verify critical variables exported by sm_init
# Standard 0 (Execution Enforcement): Critical state initialization must be verified
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported by sm_init despite successful return code" 1
fi

if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY not exported by sm_init despite successful return code" 1
fi

if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_TOPICS_JSON not exported by sm_init despite successful return code" 1
fi

echo "✓ State machine variables verified: WORKFLOW_SCOPE=$WORKFLOW_SCOPE, RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY"
```

---

## Error Handling and Troubleshooting

### Common Failure Modes

#### 1. Agent Does Not Return CLASSIFICATION_COMPLETE Signal

**Symptom**: Bash error on line parsing classification
```
CLASSIFICATION_JSON=$(echo "$AGENT_RESPONSE" | grep -oP 'CLASSIFICATION_COMPLETE:\s*\K.*' | head -1)
# Returns empty string
```

**Root Cause**: Agent behavioral file not followed correctly, or agent returned descriptive text instead of structured output

**Recovery**:
```bash
if [ -z "$CLASSIFICATION_JSON" ]; then
  echo "ERROR: Agent did not return CLASSIFICATION_COMPLETE signal" >&2
  echo "Agent output: $AGENT_RESPONSE" >&2
  echo "" >&2
  echo "Troubleshooting:" >&2
  echo "  1. Verify agent behavioral file exists: ${CLAUDE_PROJECT_DIR}/.claude/agents/workflow-classifier.md" >&2
  echo "  2. Check agent response for errors (network, timeout, API issues)" >&2
  echo "  3. Ensure workflow description is valid and not empty" >&2
  exit 1
fi
```

#### 2. Invalid JSON in Classification Response

**Symptom**: jq parse error
```
parse error: Invalid numeric literal at line 1, column 10
```

**Root Cause**: Agent returned malformed JSON or JSON wrapped in markdown code blocks

**Recovery**:
```bash
# Attempt to extract JSON from markdown code blocks
if ! echo "$CLASSIFICATION_JSON" | jq -e . >/dev/null 2>&1; then
  # Try extracting from ```json blocks
  CLASSIFICATION_JSON=$(echo "$CLASSIFICATION_JSON" | sed -n '/```json/,/```/p' | sed '1d;$d')

  # Retry validation
  if ! echo "$CLASSIFICATION_JSON" | jq -e . >/dev/null 2>&1; then
    echo "ERROR: Invalid JSON in classification response" >&2
    echo "Raw response: $CLASSIFICATION_JSON" >&2
    exit 1
  fi
fi
```

#### 3. Missing Required Fields in JSON

**Symptom**: jq returns `null` or empty string for required fields

**Root Cause**: Agent returned partial classification or incorrect field names

**Recovery**: Use `parse_llm_classifier_response()` from workflow-llm-classifier.sh for validation
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-llm-classifier.sh"

if ! validated_json=$(parse_llm_classifier_response "$CLASSIFICATION_JSON" "comprehensive"); then
  echo "ERROR: Classification JSON validation failed" >&2
  echo "JSON: $CLASSIFICATION_JSON" >&2
  exit 1
fi

# Use validated JSON for parsing
WORKFLOW_TYPE=$(echo "$validated_json" | jq -r '.workflow_type')
# etc.
```

#### 4. sm_init Parameter Validation Failure

**Symptom**: Error from sm_init
```
ERROR: sm_init requires classification parameters
  Missing parameters:
    - workflow_type
```

**Root Cause**: Classification parsing succeeded but empty values passed to sm_init

**Recovery**: Add verification before sm_init call
```bash
# Verify all parameters have values
if [ -z "$WORKFLOW_TYPE" ] || [ -z "$RESEARCH_COMPLEXITY" ] || [ -z "$RESEARCH_TOPICS_JSON" ]; then
  echo "ERROR: Classification parsing produced empty values" >&2
  echo "  WORKFLOW_TYPE: ${WORKFLOW_TYPE:-EMPTY}" >&2
  echo "  RESEARCH_COMPLEXITY: ${RESEARCH_COMPLEXITY:-EMPTY}" >&2
  echo "  RESEARCH_TOPICS_JSON: ${RESEARCH_TOPICS_JSON:-EMPTY}" >&2
  exit 1
fi
```

---

## References

### Primary Source Files

1. **Agent Behavioral File**:
   - Path: `/home/benjamin/.config/.claude/agents/workflow-classifier.md`
   - Lines: 1-530
   - Complete 4-step classification process with validation

2. **State Machine Library**:
   - Path: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`
   - Lines: 334-399 (sm_init function)
   - BREAKING CHANGE documentation (Line 338-339)

3. **LLM Classifier Library**:
   - Path: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`
   - Lines: 292-460 (parse_llm_classifier_response)
   - Lines: 466-527 (error handling)

4. **Behavioral Injection Pattern**:
   - Path: `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md`
   - Lines: 1-200 (pattern definition)

5. **Command Architecture Standards**:
   - Path: `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md`
   - Lines: 79-99 (Standard 0: Execution Enforcement)
   - Lines: 200-275 (Standard 11: Imperative Agent Invocation)

### Related Specifications

1. **Spec 1763161992**: Setup Command Refactoring
   - Phase 2: LLM Classification State Machine Integration
   - Phase 3: Agent-Based Classification (removed invoke_llm_classifier)
   - Reports documenting Task tool pattern

2. **Spec 495**: /coordinate and /research agent delegation failures
   - Fixed via behavioral injection pattern
   - Achieved >90% delegation rate

3. **Spec 057**: /supervise robustness improvements
   - Removed bootstrap fallbacks
   - Added fail-fast error handling

### Test Files

1. **Workflow Classifier Agent Tests**:
   - Path: `/home/benjamin/.config/.claude/tests/test_workflow_classifier_agent.sh`
   - Lines: 356-368 (CLASSIFICATION_COMPLETE signal validation)

### Documentation Files

1. **Orchestration Best Practices**:
   - Path: `/home/benjamin/.config/.claude/docs/guides/orchestration-best-practices.md`
   - Unified framework for Phase 0-7

2. **Orchestration Troubleshooting**:
   - Path: `/home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md`
   - Debugging procedures for agent invocation

---

## Conclusion

The workflow-classifier agent integration pattern requires:

1. **Phase 0.1 Addition**: Insert agent invocation block BEFORE sm_init call
2. **Agent Invocation**: Use Task tool with behavioral file reference and workflow context
3. **Response Parsing**: Extract CLASSIFICATION_COMPLETE JSON and parse fields
4. **Verification**: Fail-fast if parsing fails or fields missing
5. **sm_init Call**: Pass classification parameters to refactored sm_init function
6. **Export Verification**: Confirm WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON exported

This pattern eliminates the deprecated internal classification in sm_init, follows Standard 11 (Imperative Agent Invocation), and ensures 100% file creation reliability through explicit path pre-calculation enabled by classification.

**Next Steps**:
- Apply this pattern to /coordinate command (Phase 0.1 insertion)
- Verify all three orchestration commands (/coordinate, /orchestrate, /supervise) use consistent pattern
- Update command guide documentation with classification integration steps
