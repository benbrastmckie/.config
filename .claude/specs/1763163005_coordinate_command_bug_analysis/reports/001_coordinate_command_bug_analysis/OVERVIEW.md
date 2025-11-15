# /coordinate Command Bug Analysis - Comprehensive Overview

## Metadata
- **Date**: 2025-11-14
- **Research Topic**: /coordinate command sm_init failure and workflow-classifier integration
- **Synthesizer**: research-synthesizer
- **Report Type**: Comprehensive overview synthesizing root cause, integration pattern, and standards compliance
- **Subtopic Reports**: 3 (root cause analysis, workflow-classifier integration, behavioral injection standards)
- **Priority**: Critical (P0) - Complete orchestration outage

---

## Executive Summary

The /coordinate command exhibits a **critical architectural synchronization failure** caused by an incomplete clean-break refactor. The `sm_init()` function signature was changed from 2 parameters to 5 parameters (commit `ce1d29a1`, 8 hours ago) to support agent-based workflow classification, but the /coordinate command was not updated to invoke the new workflow-classifier agent before calling `sm_init()`. This results in **100% failure rate** for all /coordinate invocations.

**Three-Dimensional Analysis**:

1. **Root Cause** (Report 001): Breaking change committed (library refactored) without updating callers (commands unchanged)
2. **Integration Pattern** (Report 002): Correct workflow-classifier agent invocation pattern documented with 4-step classification process
3. **Standards Compliance** (Report 003): /coordinate complies with Standards 0, 11, 14, 15 but missing workflow-llm-classifier.sh in REQUIRED_LIBS arrays

**Critical Findings**:

- **Timeline**: sm_init refactored 2025-11-14 16:35 (Phases 1-3 complete), commands NOT updated (Phases 4-5 incomplete)
- **Failure Mode**: /coordinate calls `sm_init("$DESC", "coordinate")` but function expects `sm_init("$DESC", "coordinate", "$TYPE", "$COMPLEXITY", "$TOPICS_JSON")`
- **Impact**: All 3 orchestration commands broken (/coordinate, /orchestrate, /supervise) - complete workflow orchestration outage
- **Fix Effort**: 4 hours (1h /coordinate + 2h other commands + 1h testing)
- **Prevention**: Atomic commit policy for breaking changes + integration tests

**Solution Architecture**:

1. Add Phase 0.1 to /coordinate: Invoke workflow-classifier agent via Task tool (Standard 11 imperative pattern)
2. Parse JSON classification response (workflow_type, research_complexity, research_topics)
3. Pass 5 parameters to refactored sm_init() function
4. Add workflow-llm-classifier.sh to REQUIRED_LIBS arrays (fixes library sourcing violation)
5. Maintain existing Standards 0, 11, 14, 15 compliance (no regressions)

---

## Multi-Dimensional Problem Analysis

### Dimension 1: Root Cause - Breaking Change Synchronization Failure

**Source**: Report 001 (Root Cause Analysis - SM Init Premature Invocation)

**What Changed**:

Commit `ce1d29a1` (2025-11-14 16:35) refactored `sm_init()` as part of Spec 1763161992 "LLM Classification Agent Integration":

**Old Signature** (2 parameters):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Internal classification (lines 345-410, 66 lines of code)
  classification_result=$(classify_workflow_comprehensive "$workflow_desc" ...)
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
  # ... etc
}
```

**New Signature** (5 parameters):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_type="$3"          # NEW - required
  local research_complexity="$4"    # NEW - required
  local research_topics_json="$5"   # NEW - required

  # Fail-fast parameter validation
  if [ -z "$workflow_type" ] || [ -z "$research_complexity" ] || [ -z "$research_topics_json" ]; then
    echo "ERROR: sm_init requires classification parameters" >&2
    echo "  IMPORTANT: Commands must invoke workflow-classifier agent BEFORE calling sm_init" >&2
    return 1
  fi

  # NO internal classification (66 lines deleted)
}
```

**Current /coordinate Invocation** (BROKEN):
```bash
# Line 167 - Only 2 parameters
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed..." 1
fi
```

**Why It Fails**:
- Parameters 3-5 are empty (`$workflow_type`, `$research_complexity`, `$research_topics_json`)
- Validation at line 352 detects missing parameters
- Function returns error code 1 with diagnostic message
- Error handler invoked, /coordinate terminates

**Architectural Rationale for Change**:

The refactor eliminates a **100% timeout failure rate** with file-based classification signaling:

- **Old Approach**: sm_init() invoked file-based LLM classifier internally
- **Problem**: File-based signaling suffered 100% timeout rate (Spec 704)
- **Solution**: Agent-based classification via Task tool (Spec 1763161992)
- **Trade-off**: Breaking change requiring command updates (Phases 4-5 incomplete)

**Project Philosophy Alignment**:

This follows the project's **clean-break, fail-fast philosophy**:

- No backward compatibility shims (no optional parameter defaults)
- No silent degradation (fail immediately with clear error message)
- Clear error message directs to solution: "Commands must invoke workflow-classifier agent BEFORE calling sm_init"
- Breaking changes committed incrementally (Phases 1-3 complete, Phases 4-5 incomplete)

**Blast Radius**:

- `/coordinate` - ❌ Broken (confirmed in Report 001)
- `/orchestrate` - ❌ Likely broken (same sm_init call pattern)
- `/supervise` - ❌ Likely broken (same sm_init call pattern)
- **Time Broken**: 8 hours since commit ce1d29a1
- **Failure Rate**: 100% (all invocations fail at sm_init)

### Dimension 2: Integration Pattern - Workflow-Classifier Agent

**Source**: Report 002 (Workflow-Classifier Agent Integration Pattern)

**Agent Behavioral File**: `.claude/agents/workflow-classifier.md` (530 lines)

**Agent Configuration**:
```yaml
allowed-tools: None
description: Fast semantic workflow classification for orchestration commands
model: haiku
model-justification: Classification is fast, deterministic task requiring <5s response time
fallback-model: sonnet-4.5
```

**Classification Process** (4 Required Steps):

#### Step 1: Receive and Verify Workflow Description
- **MANDATORY INPUTS**: Workflow Description, Command Name
- **CHECKPOINT**: Must have both inputs before proceeding
- Failure to verify inputs violates agent behavioral contract

#### Step 2: Perform Semantic Classification

**Workflow Type Classification** (5 categories):
- `research-only`: User wants to learn/understand (no plans or code)
- `research-and-plan`: Research to inform NEW plan creation
- `research-and-revise`: Research to update EXISTING plan
- `full-implementation`: Complete workflow (research → plan → implement → test → debug → document)
- `debug-only`: Root cause analysis and bug fixing

**Critical Semantic Analysis Rules**:
- Quoted keywords indicate TOPIC not INTENT ("research the 'implement' command" → research-only, not full-implementation)
- Negations mean NOT doing X ("don't revise" → NOT research-and-revise)
- Ambiguous descriptions require context analysis
- Multiple phases classify as highest scope

**Research Complexity** (4 levels):
- 1 (Simple): Single narrow topic
- 2 (Medium): 2 related topics
- 3 (Complex): 3 topics, multiple integration points
- 4 (Very Complex): 4 topics, extensive architectural scope
- **RULE**: Topic count MUST EXACTLY MATCH complexity score

**Research Topics Structure**:
```json
{
  "short_name": "Topic name (3-8 words)",
  "detailed_description": "What to research and why (50-500 characters)",
  "filename_slug": "topic_name_slug",
  "research_focus": "Key questions to answer (50-300 characters)"
}
```

**Validation Rules**:
- `detailed_description`: 50-500 characters (STRICT)
- `filename_slug`: `^[a-z0-9_]{1,50}$` (lowercase, numbers, underscores only)
- `research_focus`: 50-300 characters

#### Step 3: Validate Classification

**Validation Checklist** (5 categories, 14 criteria):
1. **Workflow Type**: Valid enum, reflects PRIMARY INTENT
2. **Research Complexity**: Integer 1-4, matches scope
3. **Research Topics**: Count matches complexity, all required fields, length validation, slug validation
4. **Confidence**: Float 0.0-1.0
5. **Reasoning**: Brief explanation (1-3 sentences)

#### Step 4: Return Classification Result

**Output Format**:
```
CLASSIFICATION_COMPLETE: {
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Authentication Patterns",
      "detailed_description": "Analyze current authentication implementation patterns and security considerations for user login workflows...",
      "filename_slug": "authentication_patterns",
      "research_focus": "How is authentication currently handled? What security patterns are used?..."
    },
    {
      "short_name": "OAuth Integration Architecture",
      "detailed_description": "Research OAuth 2.0 provider integration patterns, token management, and session handling...",
      "filename_slug": "oauth_integration_architecture",
      "research_focus": "How to integrate OAuth providers? What token storage patterns are recommended?..."
    }
  ],
  "reasoning": "Description indicates research to inform plan creation for new OAuth authentication implementation."
}
```

**CRITICAL REQUIREMENTS**:
- Start with `CLASSIFICATION_COMPLETE:` signal (completion marker for parsing)
- Follow with valid JSON object (no markdown code blocks)
- NO additional commentary after JSON

**Edge Cases Documented** (Lines 251-403):
- Ambiguous workflow types (quoted keywords, negations)
- Empty/minimal descriptions (conservative classification)
- Multi-phase descriptions (classify as highest scope)

### Dimension 3: Standards Compliance - Behavioral Injection Pattern

**Source**: Report 003 (Behavioral Injection Standards Compliance Fix)

**Current /coordinate Compliance Status**:

| Standard | Status | Evidence |
|----------|--------|----------|
| **Standard 0** (Verification/Fallback) | ✅ COMPLIANT | Lines 151-154 (state ID verification), 174-186 (variable verification), 213-216 (persistence verification) |
| **Standard 11** (Imperative Agent Invocation) | ✅ COMPLIANT | Lines 490-511 (hierarchical supervision), 564-585 (research agent invocation) - All use "**EXECUTE NOW**: USE the Task tool" |
| **Standard 14** (Executable/Documentation Separation) | ✅ COMPLIANT | 1,084 lines < 1,200 orchestrator limit, cross-reference to guide file (line 14) |
| **Standard 15** (Library Sourcing Order) | ⚠️ PARTIAL | Correct order (lines 104-253) BUT missing workflow-llm-classifier.sh in REQUIRED_LIBS |

**Standard 11: Imperative Agent Invocation Pattern**

/coordinate already implements the correct pattern for agent invocations:

**Example from Lines 490-511** (Hierarchical Research Supervision):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-sub-supervisor:

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md

    **Workflow-Specific Context**:
    - Research Topics JSON: $RESEARCH_TOPICS_JSON
    - Report Directory: $RESEARCH_REPORTS_DIR
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **YOUR ROLE**: You are a SUPERVISOR coordinating 2-4 research agents.
    - Calculate report paths for each subtopic
    - Invoke research-specialist agents via Task tool
    - Aggregate metadata-only summaries (95% context reduction)

    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}
```

**Compliance Checklist**:
- ✅ Imperative instruction present (`**EXECUTE NOW**: USE the Task tool`)
- ✅ Behavioral file referenced explicitly (absolute path)
- ✅ No YAML code block wrappers (direct Task invocation)
- ✅ No "Example" prefixes (no documentation-only interpretation)
- ✅ Completion signals required in all prompts (`SUPERVISOR_COMPLETE:`, `REPORT_CREATED:`)
- ✅ No undermining disclaimers after imperative directives

**Standard 15: Library Sourcing Order**

/coordinate follows correct sourcing sequence:

```bash
# Line 104: State machine (FIRST)
source "${LIB_DIR}/workflow-state-machine.sh"

# Line 116: State persistence (SECOND)
source "${LIB_DIR}/state-persistence.sh"

# Lines 124, 132: Error handling and verification (EARLY - before checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Line 247: Additional libraries via source_required_libraries
source_required_libraries "${REQUIRED_LIBS[@]}"
```

**Problem**: workflow-llm-classifier.sh missing from REQUIRED_LIBS arrays

**Dependency Chain**:
1. sm_init (workflow-state-machine.sh) calls classify_workflow_comprehensive
2. classify_workflow_comprehensive (workflow-scope-detection.sh:48) is primary classifier
3. workflow-scope-detection.sh sources workflow-llm-classifier.sh (line 27)
4. workflow-detection.sh sources workflow-scope-detection.sh (line 21)
5. **ISSUE**: workflow-llm-classifier.sh not explicitly in REQUIRED_LIBS (transitive dependency)
6. **Standard 15 Requirement**: All dependencies must be explicit

---

## Integrated Solution Architecture

### Phase 0.1: Workflow Classification (NEW - INSERT BEFORE LINE 163)

**Location**: `.claude/commands/coordinate.md` (after line 138, before current sm_init call)

**Implementation**:

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

**Key Design Elements**:

1. **Standard 11 Compliance**: Imperative directive "**EXECUTE NOW**: USE the Task tool"
2. **Behavioral Injection**: Agent reads .claude/agents/workflow-classifier.md (530-line behavioral file)
3. **Context Injection**: Workflow description and command name passed as parameters
4. **Completion Signal**: "CLASSIFICATION_COMPLETE:" enables parsing
5. **Fail-Fast Verification**: Three checkpoints ensure all required fields parsed
6. **Export for sm_init**: Variables exported to parent shell for sm_init consumption

### Modified sm_init Call (LINE 167)

**Change FROM** (BROKEN - 2 parameters):
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

**Change TO** (FIXED - 5 parameters):
```bash
# CRITICAL: Call sm_init with pre-computed classification from Phase 0.1
# sm_init now requires classification parameters (Spec 1763161992 Phase 2)
# IMPORTANT: Do NOT use command substitution $() as it creates subshell that doesn't export to parent
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON" 2>&1
SM_INIT_EXIT_CODE=$?
if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
  handle_state_error "State machine initialization failed. Classification parameters: type=$WORKFLOW_TYPE, complexity=$RESEARCH_COMPLEXITY" 1
fi
```

**Changes**:
- Added 3 classification parameters to sm_init call
- Updated error message to show classification parameters for debugging
- Removed obsolete reference to WORKFLOW_CLASSIFICATION_MODE (regex mode deleted in Phase 3)

### Library Dependency Fix (LINES 233, 236, 239, 242)

**Add workflow-llm-classifier.sh to all four REQUIRED_LIBS arrays**:

**Line 233** (research-only scope):
```bash
# BEFORE
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")

# AFTER
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "error-handling.sh")
```

**Line 236** (research-and-plan/revise scope):
```bash
# BEFORE
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")

# AFTER
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
```

**Line 239** (full-implementation scope):
```bash
# BEFORE
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")

# AFTER
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "dependency-analyzer.sh" "context-pruning.sh" "error-handling.sh")
```

**Line 242** (debug-only scope):
```bash
# BEFORE
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")

# AFTER
REQUIRED_LIBS=("workflow-detection.sh" "workflow-scope-detection.sh" "workflow-llm-classifier.sh" "unified-logger.sh" "unified-location-detection.sh" "overview-synthesis.sh" "metadata-extraction.sh" "checkpoint-utils.sh" "error-handling.sh")
```

**Rationale**: Transitive dependencies must be explicit per Standard 15. Even though workflow-llm-classifier.sh is sourced by workflow-scope-detection.sh, explicit inclusion in REQUIRED_LIBS ensures proper sourcing order and prevents "command not found" errors.

### Verification Checkpoints (LINES 174-188 - KEEP UNCHANGED)

**Existing verification already correct**:
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

**No changes needed**: Verification checkpoints already align with Standard 0 requirements.

---

## Error Handling and Troubleshooting

### Common Failure Modes

#### 1. Agent Does Not Return CLASSIFICATION_COMPLETE Signal

**Symptom**:
```bash
CLASSIFICATION_JSON=$(echo "$AGENT_RESPONSE" | grep -oP 'CLASSIFICATION_COMPLETE:\s*\K.*' | head -1)
# Returns empty string
```

**Root Causes**:
- Agent behavioral file not followed correctly
- Agent returned descriptive text instead of structured output
- Network timeout or API error
- Agent misinterpreted workflow description as conversational query

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
  echo "  4. Try running /coordinate again (transient network issue)" >&2
  exit 1
fi
```

#### 2. Invalid JSON in Classification Response

**Symptom**:
```
parse error: Invalid numeric literal at line 1, column 10
```

**Root Causes**:
- Agent returned malformed JSON
- JSON wrapped in markdown code blocks (` ```json`)
- Agent returned multiple JSON objects (first one incomplete)

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

**Symptom**:
```bash
WORKFLOW_TYPE=$(echo "$CLASSIFICATION_JSON" | jq -r '.workflow_type')
# Returns empty string or "null"
```

**Root Causes**:
- Agent returned partial classification
- Incorrect field names in JSON response
- Agent returned legacy format (pre-enhanced topic generation)

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
RESEARCH_COMPLEXITY=$(echo "$validated_json" | jq -r '.research_complexity')
RESEARCH_TOPICS_JSON=$(echo "$validated_json" | jq -c '.research_topics')
```

#### 4. sm_init Parameter Validation Failure

**Symptom**:
```
ERROR: sm_init requires classification parameters
  Missing parameters:
    - workflow_type
```

**Root Causes**:
- Classification parsing succeeded but empty values passed to sm_init
- Variables not exported from Phase 0.1 bash block
- Subprocess isolation prevented export propagation

**Recovery**: Add verification before sm_init call
```bash
# Verify all parameters have values
if [ -z "$WORKFLOW_TYPE" ] || [ -z "$RESEARCH_COMPLEXITY" ] || [ -z "$RESEARCH_TOPICS_JSON" ]; then
  echo "ERROR: Classification parsing produced empty values" >&2
  echo "  WORKFLOW_TYPE: ${WORKFLOW_TYPE:-EMPTY}" >&2
  echo "  RESEARCH_COMPLEXITY: ${RESEARCH_COMPLEXITY:-EMPTY}" >&2
  echo "  RESEARCH_TOPICS_JSON: ${RESEARCH_TOPICS_JSON:-EMPTY}" >&2
  echo "" >&2
  echo "Troubleshooting:" >&2
  echo "  1. Verify jq parsing succeeded (check for jq errors above)" >&2
  echo "  2. Check agent response format matches expected schema" >&2
  echo "  3. Ensure export statements executed successfully" >&2
  exit 1
fi
```

---

## Implementation Plan

### Phase 1: /coordinate Command Update (1 hour)

**Step 1.1: Backup Current File**
```bash
cp /home/benjamin/.config/.claude/commands/coordinate.md \
   /home/benjamin/.config/.claude/commands/coordinate.md.backup-$(date +%Y%m%d-%H%M%S)
```

**Step 1.2: Insert Phase 0.1 Classification Block**
- Location: After line 138, before line 163
- Content: Agent invocation + JSON parsing + verification (see "Integrated Solution Architecture" above)

**Step 1.3: Modify sm_init Call**
- Location: Line 167
- Change: Add 3 classification parameters
- Update error message: Show classification parameters for debugging

**Step 1.4: Update REQUIRED_LIBS Arrays**
- Locations: Lines 233, 236, 239, 242
- Change: Add "workflow-llm-classifier.sh" to each array

**Step 1.5: Test /coordinate Command**
```bash
# Test research-only
/coordinate "research authentication patterns"

# Test research-and-plan
/coordinate "implement user login with OAuth"

# Test full-implementation
/coordinate "refactor authentication system with new architecture"

# Test debug-only
/coordinate "debug session management race condition"
```

**Expected Results**:
- Workflow classification completes in <5s
- sm_init succeeds with all 5 parameters
- All WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON variables exported
- No "command not found" errors
- Command proceeds to research phase

### Phase 2: /orchestrate Command Update (1 hour)

**Apply same pattern**:
1. Insert Phase 0.1 before sm_init call
2. Modify sm_init call to pass 5 parameters
3. Add workflow-llm-classifier.sh to REQUIRED_LIBS
4. Test with all workflow scopes

### Phase 3: /supervise Command Update (1 hour)

**Apply same pattern**:
1. Insert Phase 0.1 before sm_init call
2. Modify sm_init call to pass 5 parameters
3. Add workflow-llm-classifier.sh to REQUIRED_LIBS
4. Test with all workflow scopes

### Phase 4: Integration Testing (1 hour)

**Test Matrix** (3 commands × 5 workflow types = 15 test cases):

| Command | research-only | research-and-plan | research-and-revise | full-implementation | debug-only |
|---------|---------------|-------------------|---------------------|---------------------|------------|
| /coordinate | ✓ | ✓ | ✓ | ✓ | ✓ |
| /orchestrate | ✓ | ✓ | ✓ | ✓ | ✓ |
| /supervise | ✓ | ✓ | ✓ | ✓ | ✓ |

**Validation Criteria**:
- Agent invocation succeeds (no Task tool errors)
- Classification JSON returned with CLASSIFICATION_COMPLETE signal
- All required fields present (workflow_type, research_complexity, research_topics)
- sm_init succeeds with 5-parameter signature
- State machine variables exported correctly
- Command proceeds to subsequent phases (research, plan, etc.)

**Regression Testing**:
- Verify Standards 0, 11, 14, 15 compliance maintained
- No new verification checkpoint failures
- Library sourcing order unchanged
- Agent delegation rate remains >90%

---

## Performance and Architecture Metrics

### Pre-Refactor (File-Based Classification)

- **Classification Time**: 10-30s (file-based signaling)
- **Timeout Rate**: 100% (file-based approach fundamentally broken)
- **Classification Location**: Internal to sm_init (66 lines of code)
- **Debuggability**: Poor (timeouts produced no diagnostic information)

### Post-Refactor (Agent-Based Classification)

- **Classification Time**: <5s target (Haiku model, direct Task invocation)
- **Timeout Rate**: 0% (agent-based approach eliminates file signaling)
- **Classification Location**: External Phase 0.1 (explicit agent invocation)
- **Debuggability**: Excellent (agent returns structured JSON, clear error messages)

### Code Metrics

**sm_init Function**:
- Lines removed: 66 (internal classification code deleted)
- Lines added: 40 (parameter validation)
- Net change: -26 lines (38% size reduction)

**/coordinate Command**:
- Lines added: ~60 (Phase 0.1 agent invocation + parsing + verification)
- Lines modified: 5 (sm_init call + error message + REQUIRED_LIBS arrays)
- Size impact: +6% (60/1084 lines)

**Overall System**:
- Library code reduction: 66 lines (sm_init simplification)
- Command code increase: 60 lines × 3 commands = 180 lines
- Net change: +114 lines (0.5% increase, 20,000+ total lines)
- **Trade-off**: Slight size increase for 100% reliability improvement

---

## Prevention Recommendations

### Short-Term (Immediate Actions)

**1. Integration Test Suite for Orchestration Commands**
```bash
# Create .claude/tests/test_orchestration_sm_init.sh
# Test all 3 commands with 5 workflow types (15 test cases)
# Verify sm_init parameter signature compatibility
# Run pre-commit to catch signature mismatches
```

**2. Document Breaking Changes in CHANGELOG**
```markdown
## [Unreleased]
### BREAKING CHANGES
- sm_init() now requires 5 parameters (was 2)
- Commands must invoke workflow-classifier agent before sm_init
- Migration: Add Phase 0.1 classification to all orchestration commands
- Affected commands: /coordinate, /orchestrate, /supervise
```

**3. Create Migration Checklist**
```markdown
## Breaking Change Checklist (for Library Authors)

Before committing breaking changes:
- [ ] Identify all callers of modified function
- [ ] Update all callers in same commit (atomic change)
- [ ] Add integration tests for new signature
- [ ] Document breaking change in commit message
- [ ] Update CHANGELOG with migration steps
- [ ] Consider backward-compatible transition period
```

### Long-Term (Architectural Improvements)

**1. Atomic Commit Policy**
- **Rule**: Breaking changes + all caller updates in single commit
- **Rationale**: Prevents incomplete migration states (current bug)
- **Exception**: Phased refactors allowed ONLY if callers still functional (backward-compatible transition)

**2. Pre-Commit Hook for Signature Mismatches**
```bash
# .git/hooks/pre-commit
# Detect function signature changes in .claude/lib/*.sh
# Scan .claude/commands/*.md for calls to modified functions
# Fail if caller count doesn't match updated caller count
```

**3. Contract Testing Between Libraries and Commands**
```bash
# .claude/tests/test_library_contracts.sh
# For each library function with external callers:
#   1. Extract function signature from library
#   2. Extract call signatures from all commands
#   3. Verify parameter counts match
#   4. Fail fast if mismatch detected
```

**4. Consider Backward-Compatible Transition Periods**

**Current Approach** (Clean-Break):
- Pros: Simple, clear, follows fail-fast philosophy
- Cons: Requires atomic updates, breaks if incomplete

**Alternative Approach** (Graceful Transition):
```bash
# sm_init with optional parameters (backward compatible)
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_type="${3:-}"
  local research_complexity="${4:-}"
  local research_topics_json="${5:-}"

  # If classification parameters missing, invoke agent internally (deprecated)
  if [ -z "$workflow_type" ]; then
    echo "WARNING: sm_init called without classification parameters (deprecated)" >&2
    echo "  Please update command to invoke workflow-classifier agent" >&2
    echo "  See: .claude/agents/workflow-classifier.md" >&2

    # Fallback to internal classification (DEPRECATED, will be removed)
    # ... internal classification code ...
  fi

  # Rest of function
}
```

**Recommendation**: Maintain clean-break approach for internal commands, but consider transition periods for public APIs or heavily-used functions (>10 callers).

---

## Historical Context and Evolution

### Classification System Evolution

**Phase 1: Regex-Only Classification** (Pre-Spec 704)
- Simple keyword matching ("research" → research-only)
- No semantic analysis (quoted keywords misclassified)
- 60-70% accuracy

**Phase 2: LLM Classification Introduction** (Spec 704)
- File-based signaling pattern
- Improved accuracy to 98%+
- **Problem**: 100% timeout rate (file signaling broken)

**Phase 3: Incremental Improvements** (Specs 700-704, 5 commits)
- Semantic filename scoping (14a268b6)
- Error visibility improvements (32e1a7d0)
- Fail-fast approach (56406289)
- Regex removal (2c182d4c)
- **Result**: File-based approach fundamentally broken, no recovery possible

**Phase 4: Agent-Based Classification** (Spec 1763161992, commit ce1d29a1)
- **Phases 1-3 Complete** (2025-11-14 16:35):
  - Phase 1: Created workflow-classifier agent (530 lines)
  - Phase 2: Refactored sm_init to accept pre-computed classification (5 parameters)
  - Phase 3: Deleted file-based classification code (66 lines removed)
- **Phases 4-5 Incomplete** (current bug):
  - Phase 4: Update /coordinate command ❌
  - Phase 5: Update /orchestrate and /supervise commands ❌

**Phase 5: This Fix** (Current Report)
- Complete Phases 4-5 (command updates)
- Add workflow-llm-classifier.sh to REQUIRED_LIBS
- Maintain Standards 0, 11, 14, 15 compliance

### Related Specifications

**Spec 438** (2025-10-24): /supervise agent delegation fix
- Established Standard 11 (Imperative Agent Invocation Pattern)
- Fixed meta-confusion loops via behavioral injection
- Achieved >90% agent delegation rate

**Spec 495** (2025-10-27): /coordinate and /research agent delegation fixes
- Applied Standard 11 to /coordinate and /research commands
- Eliminated placeholder file creation (Standard 0 compliance)
- 100% file creation reliability via explicit path injection

**Spec 497** (2025-10-27): Unified orchestration improvements
- Standardized orchestration patterns across /coordinate, /orchestrate, /supervise
- Hierarchical supervision for >4 topics (95% context reduction)
- Wave-based parallel execution (40-60% time savings)

**Spec 057** (2025-10-27): /supervise fail-fast error handling
- Removed bootstrap fallbacks (prohibited, hide errors)
- Added verification checkpoints (required, detect errors)
- Established fail-fast philosophy (detect errors, not mask them)

**Spec 616** (2025-11-07): /coordinate executable/documentation separation
- Migrated /coordinate to Standard 14 (two-file pattern)
- 54% size reduction (1,084 lines, within 1,200 orchestrator limit)
- Eliminated meta-confusion loops (0% vs 75% pre-migration)

**Spec 675** (2025-11-11): /coordinate library sourcing order fix
- Fixed Standard 15 compliance (sourcing order)
- Moved error-handling.sh and verification-helpers.sh to early sourcing
- Prevented premature function calls (bash block execution model)

**Spec 704** (2025-11-XX): LLM classification incremental improvements
- 5 commits improving file-based classification
- **Outcome**: Approach fundamentally broken (100% timeout rate)
- Led to agent-based solution in Spec 1763161992

**Spec 1763161992** (2025-11-14): LLM Classification State Machine Integration
- **THIS SPEC** - Agent-based classification replacing file-based approach
- Phases 1-3 complete (agent creation, sm_init refactor, file cleanup)
- Phases 4-5 incomplete (command updates) - **CURRENT BUG**

---

## References

### Primary Source Files

**Agent Behavioral Files**:
- `.claude/agents/workflow-classifier.md` (530 lines) - Complete 4-step classification process with validation

**Library Files**:
- `.claude/lib/workflow-state-machine.sh` (lines 334-399) - Refactored sm_init function with 5-parameter signature
- `.claude/lib/workflow-llm-classifier.sh` (25,003 bytes) - Parsing and validation utilities
- `.claude/lib/workflow-scope-detection.sh` (lines 26-27) - Sources workflow-llm-classifier.sh
- `.claude/lib/workflow-detection.sh` (lines 20-21) - Sources workflow-scope-detection.sh

**Command Files**:
- `.claude/commands/coordinate.md` (1,084 lines, 85,584 bytes) - Primary command requiring fix
- `.claude/commands/orchestrate.md` - Likely affected (same sm_init pattern)
- `.claude/commands/supervise.md` - Likely affected (same sm_init pattern)

**Documentation Files**:
- `.claude/docs/reference/command_architecture_standards.md`:
  - Standard 0 (lines 51-463): Execution Enforcement / Verification and Fallback Pattern
  - Standard 11 (lines 1173-1353): Imperative Agent Invocation Pattern
  - Standard 14 (lines 1535-1689): Executable/Documentation Separation
  - Standard 15 (lines 2277-2412): Library Sourcing Order
- `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-300): Behavioral injection pattern documentation
- `.claude/docs/concepts/patterns/verification-fallback.md` (lines 1-200): Verification and fallback pattern documentation
- `.claude/docs/guides/orchestration-best-practices.md`: Unified framework for Phase 0-7
- `.claude/docs/guides/orchestration-troubleshooting.md`: Debugging procedures for agent invocation

**Test Files**:
- `.claude/tests/test_workflow_classifier_agent.sh` (lines 356-368) - CLASSIFICATION_COMPLETE signal validation
- `.claude/tests/validate_executable_doc_separation.sh` - Standard 14 validation
- `.claude/tests/test_orchestration_commands.sh` - Standard 11 validation (can be extended)

### Related Commits

**Breaking Change Commit**:
- `ce1d29a1` (2025-11-14 16:35) - "feat(orchestration): Phases 1-3 - Agent-based classification foundation"

**Incremental Classification Improvements**:
- `2c182d4c` - Removed regex classification
- `56406289` - Removed auto-fallback
- `14a268b6` - Semantic filename persistence
- `32e1a7d0` - Error visibility improvements

**Standards Compliance Fixes**:
- `bf50ee10` - sm_init export persistence fix
- `6edf5a76` - Added sm_init return code verification

### Subtopic Research Reports

1. **[Report 001: Root Cause Analysis - SM Init Premature Invocation](001_root_cause_analysis_sm_init_premature_invocation.md)**
   - Breaking change timeline and git history
   - sm_init signature evolution (2 params → 5 params)
   - Clean-break philosophy justification
   - Blast radius assessment (all 3 orchestration commands)

2. **[Report 002: Workflow-Classifier Agent Integration Pattern](002_workflow_classifier_agent_integration_pattern.md)**
   - Agent behavioral file structure (4-step classification)
   - Expected input/output formats (CLASSIFICATION_COMPLETE signal)
   - Successful integration examples from other commands
   - Error handling and troubleshooting procedures

3. **[Report 003: Behavioral Injection Standards Compliance Fix](003_behavioral_injection_standards_compliance_fix.md)**
   - Standards 0, 11, 14, 15 compliance analysis
   - workflow-llm-classifier.sh dependency analysis
   - REQUIRED_LIBS array updates (4 locations)
   - Implementation guidance and testing procedures

---

## Conclusion

The /coordinate command failure represents a **critical but straightforward architectural synchronization issue**: the library was refactored (sm_init signature changed) without updating the callers (commands unchanged). This follows the project's clean-break philosophy but resulted in an incomplete migration (Phases 1-3 complete, Phases 4-5 incomplete).

**Root Cause Summary**:
- **Direct Cause**: /coordinate calls sm_init with 2 parameters, function requires 5 parameters
- **Architectural Cause**: Breaking change committed without atomic caller updates
- **Process Cause**: Phased implementation (Phases 1-3 done, Phases 4-5 pending)
- **Design Decision**: Clean-break philosophy (no backward compatibility shims)

**Solution Summary**:
1. Add Phase 0.1 to invoke workflow-classifier agent (Standard 11 imperative pattern)
2. Parse JSON classification response (workflow_type, research_complexity, research_topics)
3. Pass 5 parameters to sm_init (not 2)
4. Add workflow-llm-classifier.sh to REQUIRED_LIBS arrays (Standard 15 compliance)
5. Maintain Standards 0, 11, 14, 15 compliance (no regressions)

**Impact Summary**:
- **Fix Effort**: 4 hours (1h /coordinate + 2h other commands + 1h testing)
- **Code Changes**: ~60 lines per command (Phase 0.1 insertion)
- **Performance**: 100% timeout elimination, <5s classification time
- **Reliability**: 100% file creation maintained, fail-fast error detection

**Prevention Summary**:
- Establish atomic commit policy for breaking changes
- Add pre-commit hook for signature mismatch detection
- Create integration test suite for orchestration commands
- Document breaking changes in CHANGELOG with migration steps

**Standards Compliance**:
- ✅ Standard 0 (Verification/Fallback): Maintained via existing checkpoints
- ✅ Standard 11 (Imperative Agent Invocation): Phase 0.1 follows correct pattern
- ✅ Standard 14 (Executable/Documentation Separation): Size increase within limits
- ✅ Standard 15 (Library Sourcing Order): Fixed via REQUIRED_LIBS updates

**Next Steps**:
1. Apply this fix to /coordinate (Phase 1, 1 hour)
2. Apply same pattern to /orchestrate and /supervise (Phase 2-3, 2 hours)
3. Run integration tests (Phase 4, 1 hour)
4. Commit changes with comprehensive commit message
5. Update orchestration troubleshooting guide with classification debugging

**Priority**: **CRITICAL (P0)** - Complete orchestration outage affecting all multi-agent workflows. Fix should be applied immediately to restore /coordinate, /orchestrate, and /supervise functionality.
