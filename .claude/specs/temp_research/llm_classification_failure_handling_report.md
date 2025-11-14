# LLM Classification Failure Handling - Research Report

## Metadata
- **Date**: 2025-11-13
- **Topic**: Alternative approaches for handling LLM classification failures
- **Scope**: Workflow system classification and user prompt integration

## Executive Summary

This report analyzes alternative approaches for handling LLM classification failures in the workflow system. Currently, when LLM classification fails (network issues, API errors), the system fails completely. The user proposes simplifying by prompting for workflow type choice when LLM fails, then passing this choice to the research sub-supervisor.

**Key Findings**:
1. Current system uses fail-fast approach with no fallback (intentional design per Spec 688 Phase 3)
2. LLM classification happens in `sm_init()` at line 360 of `workflow-state-machine.sh`
3. Workflow type is used to determine terminal state and select which states to execute
4. AskUserQuestion tool exists but is not currently used in any workflow commands
5. Simple user prompt fallback is significantly less complex than layered network detection

**Recommended Approach**: Interactive user prompt fallback (Option B below)

---

## 1. Current State Analysis

### 1.1 How Classification Works

**Classification Flow**:
```
/coordinate invoked
  ↓
sm_init() called (workflow-state-machine.sh:337)
  ↓
classify_workflow_comprehensive() (workflow-scope-detection.sh:49)
  ↓
[Mode: llm-only (default) or regex-only]
  ↓
classify_workflow_llm_comprehensive() (workflow-llm-classifier.sh:109)
  ↓
invoke_llm_classifier() (workflow-llm-classifier.sh:285)
  ↓
[Wait for AI response via file-based signaling]
  ↓
Returns JSON: {workflow_type, confidence, research_complexity, research_topics}
```

**Critical Variables Exported by sm_init()**:
- `WORKFLOW_SCOPE` (the workflow type: research-only, research-and-plan, research-and-revise, full-implementation, debug-only)
- `RESEARCH_COMPLEXITY` (integer 1-4, number of research topics)
- `RESEARCH_TOPICS_JSON` (array of topic objects with descriptions)

**File**: `.claude/lib/workflow-state-machine.sh` lines 337-477

### 1.2 Failure Points

**Where Classification Fails**:

1. **Network connectivity check** (workflow-llm-classifier.sh:256-273)
   - Pre-flight ping check to 8.8.8.8
   - Returns 1 if no network, prints WARNING

2. **LLM invocation timeout** (workflow-llm-classifier.sh:317-345)
   - Default 10-second timeout
   - Polls response file every 0.5s
   - Returns 1 on timeout

3. **API errors** (workflow-llm-classifier.sh:158-161)
   - LLM invocation failure
   - Calls `handle_llm_classification_failure()`
   - Returns 1

4. **Low confidence** (workflow-llm-classifier.sh:175-178)
   - Confidence < 0.7 threshold
   - Returns 1

**Current Error Handling** (workflow-llm-classifier.sh:532-583):
```bash
handle_llm_classification_failure() {
  local error_type="$1"
  local error_message="$2"
  local workflow_description="$3"

  # Prints structured error with suggestions:
  case "$error_type" in
    timeout|api_error|network)
      echo "  Alternative: Use regex-only mode for offline development"
      ;;
    low_confidence)
      echo "  Suggestion: Rephrase workflow description with more specific keywords"
      ;;
  esac

  return 1  # Always fail-fast
}
```

**Fail-Fast in sm_init()** (workflow-state-machine.sh:381-403):
```bash
if ! classification_result=$(classify_workflow_comprehensive "$workflow_desc" "$classification_workflow_id" 2>"$stderr_file"); then
  # Display captured stderr
  if [ -s "$stderr_file" ]; then
    cat "$stderr_file" >&2
  fi

  echo "CRITICAL ERROR: Comprehensive classification failed" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  1. Check network connection" >&2
  echo "  2. Increase timeout: export WORKFLOW_CLASSIFICATION_TIMEOUT=60" >&2
  echo "  3. Use offline mode: export WORKFLOW_CLASSIFICATION_MODE=regex-only" >&2
  return 1  # Fail-fast, no automatic fallback
fi
```

### 1.3 How Workflow Type is Used

**Terminal State Determination** (workflow-state-machine.sh:443-464):
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"  # Stop after research
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"  # Stop after planning
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"  # Stop after revision
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"  # Run all phases
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"  # Stop after debug
    ;;
esac
```

**State Transitions** (coordinate.md uses `WORKFLOW_SCOPE` to determine next state):
- Research phase: Check if `WORKFLOW_SCOPE == "research-only"` → Complete
- Planning phase: Check if `WORKFLOW_SCOPE == "research-and-plan"` → Complete
- Implementation phase: Only runs if `WORKFLOW_SCOPE == "full-implementation"`

**Research Sub-Supervisor Invocation** (coordinate.md:488-505):
The research phase would need the workflow type to understand the workflow context. Currently this is passed implicitly via state machine configuration.

### 1.4 Current Fallback Mechanism

**Intentionally Removed** (Spec 688 Phase 3 - Clean-Break Approach):
- Hybrid mode deleted in favor of explicit mode selection
- No automatic fallback from llm-only to regex-only
- Fail-fast philosophy: errors should be visible and loud

**Available Manual Fallbacks**:
1. Set `WORKFLOW_CLASSIFICATION_MODE=regex-only` before invoking `/coordinate`
2. Increase timeout: `export WORKFLOW_CLASSIFICATION_TIMEOUT=60`
3. Fix network/API issues and retry

---

## 2. User Prompt Patterns Research

### 2.1 AskUserQuestion Tool Usage

**Tool Availability**: YES - Available in all contexts
**Current Usage**: NONE in workflow commands (0 occurrences in `.claude/commands/`)

**Tool Specification**:
```typescript
AskUserQuestion {
  questions: [
    {
      question: "Which library should we use for date formatting?",
      header: "Library",  // Short label (max 12 chars)
      options: [
        {
          label: "date-fns",
          description: "Modern JavaScript date utility library"
        },
        {
          label: "moment.js",
          description: "Legacy but comprehensive"
        }
      ],
      multiSelect: false  // Allow single or multiple selections
    }
  ]
}
```

**Tool Behavior**:
- Users can always select "Other" to provide custom text input
- Returns answers object: `{question_key: selected_value}`
- Synchronous blocking until user responds

### 2.2 Workflow Type Selection Pattern

**Valid Workflow Types** (from workflow-llm-classifier.sh:215-221):
```json
{
  "valid_scopes": [
    "research-only",
    "research-and-plan",
    "research-and-revise",
    "full-implementation",
    "debug-only"
  ]
}
```

**Semantic Descriptions** (for user-friendly labels):
| Workflow Type | User-Friendly Label | Description |
|---------------|---------------------|-------------|
| research-only | Research Only | Research topics without creating a plan |
| research-and-plan | Research + Plan | Research topics and create implementation plan |
| research-and-revise | Revise Plan | Research to revise existing implementation plan |
| full-implementation | Full Implementation | Research, plan, and execute implementation |
| debug-only | Debug Only | Debug and analyze issues without implementation |

### 2.3 Workflow Type → Research Mapping

**Research Complexity**:
- Currently determined by LLM (1-4 based on semantic analysis)
- Fallback heuristic in regex mode: keyword counting (workflow-scope-detection.sh:143-179)

**Research Topics**:
- LLM mode: Generates descriptive topics with detailed descriptions
- Regex mode: Generic topics ("Topic 1", "Topic 2", etc.)

**Integration Point**: Research sub-supervisor expects:
- `RESEARCH_COMPLEXITY` (integer 1-4)
- `RESEARCH_TOPICS_JSON` (array of topic objects)

**User-Provided Workflow Type Implications**:
If user selects workflow type but LLM failed, we lose:
- ❌ Semantic complexity analysis (LLM's 1-4 intelligence)
- ❌ Descriptive topic names (LLM's topic generation)

We could:
- ✅ Use heuristic fallback for complexity (keyword counting)
- ✅ Use generic topic names (acceptable fallback)
- ✅ Ask user for complexity as second question
- ✅ Infer research need from workflow type (research-only/research-and-plan always need research)

---

## 3. Implementation Complexity Evaluation

### 3.1 Option A: Layered Network Detection (Current Plan Phases 3-4)

**Components Required**:
1. Enhanced network detection library
2. Pre-flight connectivity checks at multiple layers
3. Automatic mode switching based on network state
4. State tracking for network availability

**Code Changes**:
- New library: `.claude/lib/network-detection.sh` (~150 lines)
- Modifications to `workflow-llm-classifier.sh` (add layered checks)
- Integration in `workflow-scope-detection.sh` (auto-mode switching)
- Tests: Network simulation, offline scenarios

**Complexity Estimate**:
- **High** (6-8 hours implementation)
- 4 files modified
- New test scenarios for network conditions
- Risk: False positives/negatives in network detection

**Pros**:
- Transparent to user (no prompt interruption)
- Intelligent automatic fallback

**Cons**:
- Added complexity (300+ lines total)
- Network detection is unreliable (ping might work but API fails)
- Doesn't solve API errors or low confidence issues
- Still fails on non-network LLM errors

### 3.2 Option B: User Prompt Fallback (Proposed Simplified Approach)

**Components Required**:
1. User prompt on classification failure
2. Default complexity heuristic when user provides type
3. Generic topic generation fallback

**Code Changes**:
```bash
# In workflow-state-machine.sh sm_init() around line 360
if ! classification_result=$(classify_workflow_comprehensive ...); then
  # Capture error details
  echo "LLM classification unavailable (network/API error)"

  # Prompt user for workflow type
  WORKFLOW_SCOPE=$(prompt_user_for_workflow_type "$workflow_desc")

  # Use heuristic fallback for complexity and topics
  RESEARCH_COMPLEXITY=$(infer_complexity_from_keywords "$workflow_desc")
  RESEARCH_TOPICS_JSON=$(generate_generic_topics "$RESEARCH_COMPLEXITY")

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  return 0
fi
```

**New Function** (add to workflow-state-machine.sh):
```bash
prompt_user_for_workflow_type() {
  local workflow_desc="$1"

  # Use AskUserQuestion tool via Claude
  # (This is pseudo-code - actual implementation would use Task tool)
  read -p "Select workflow type (1=research-only, 2=research-and-plan, 3=revise, 4=full-impl, 5=debug): " choice

  case "$choice" in
    1) echo "research-only" ;;
    2) echo "research-and-plan" ;;
    3) echo "research-and-revise" ;;
    4) echo "full-implementation" ;;
    5) echo "debug-only" ;;
    *) echo "research-and-plan" ;;  # Safe default
  esac
}
```

**Complexity Estimate**:
- **Low** (2-3 hours implementation)
- 1 file modified (workflow-state-machine.sh)
- Reuse existing heuristic functions
- Minimal test scenarios

**Pros**:
- Simple, explicit, user-controlled
- Works for ALL classification failure types (network, API, low confidence)
- Leverages existing fallback functions (already tested)
- User sees and understands the failure

**Cons**:
- Interrupts workflow for user input
- User must understand workflow types
- No descriptive topic names (generic fallback)

### 3.3 Option C: Hybrid - Simple Network Check + User Prompt

**Components Required**:
1. Fast network check (ping only, ~10 lines)
2. User prompt on ANY failure (network, API, confidence)
3. Heuristic fallback for complexity/topics

**Code Changes**:
```bash
# In workflow-llm-classifier.sh before invoke_llm_classifier()
if ! quick_network_check; then
  echo "WARNING: No network detected, skipping LLM classification"
  return 1  # Signal to use user prompt
fi

# In workflow-state-machine.sh sm_init()
if ! classification_result=$(classify_workflow_comprehensive ...); then
  # Determine if network issue or other failure
  if ! quick_network_check; then
    echo "Network unavailable - switching to offline mode"
    # Auto-fallback to regex mode
    export WORKFLOW_CLASSIFICATION_MODE=regex-only
    classification_result=$(classify_workflow_comprehensive "$workflow_desc")
  else
    # API error or low confidence - prompt user
    WORKFLOW_SCOPE=$(prompt_user_for_workflow_type "$workflow_desc")
    RESEARCH_COMPLEXITY=$(infer_complexity_from_keywords "$workflow_desc")
    RESEARCH_TOPICS_JSON=$(generate_generic_topics "$RESEARCH_COMPLEXITY")
    export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  fi
  return 0
fi
```

**Complexity Estimate**:
- **Medium** (3-4 hours implementation)
- 2 files modified
- Combines best of both approaches

**Pros**:
- Fast network check (no false positives)
- Auto-fallback for obvious offline case
- User prompt for ambiguous failures
- Still simple

**Cons**:
- Slightly more complex than Option B
- Two codepaths (network vs non-network)

---

## 4. Recommended Approaches (Ranked)

### Approach 1: Interactive User Prompt Fallback (Recommended)

**Implementation**:

**Location**: `workflow-state-machine.sh` in `sm_init()` function

**Changes**:
1. Wrap classification call in error handler
2. On failure, invoke AskUserQuestion via markdown injection
3. Use heuristic fallback for complexity/topics
4. Export user-selected workflow type

**Detailed Changes**:

**File**: `.claude/lib/workflow-state-machine.sh`

**Around line 359-403** (sm_init classification block):
```bash
# Perform comprehensive workflow classification
local classification_stderr_file="${HOME}/.claude/tmp/classification_stderr_$$.tmp"
mkdir -p "${HOME}/.claude/tmp"

local classification_result
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" "$classification_workflow_id" 2>"$classification_stderr_file"); then
  # LLM classification succeeded
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
  RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
  RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  rm -f "$classification_stderr_file"
else
  # LLM classification failed - prompt user for workflow type
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "LLM Workflow Classification Unavailable" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

  # Display error details
  if [ -s "$classification_stderr_file" ]; then
    echo "Error details:" >&2
    cat "$classification_stderr_file" >&2
    echo "" >&2
  fi

  echo "Fallback: Manual workflow type selection" >&2
  echo "Workflow description: $workflow_desc" >&2
  echo "" >&2

  # Signal to orchestrator to prompt user (via return code + state variable)
  export CLASSIFICATION_FAILED="true"
  export WORKFLOW_DESCRIPTION_FOR_PROMPT="$workflow_desc"
  rm -f "$classification_stderr_file"
  return 2  # Special return code: classification failed, user prompt needed
fi
```

**File**: `.claude/commands/coordinate.md`

**After line 170** (after sm_init call):
```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" 2>&1
SM_INIT_EXIT_CODE=$?

if [ $SM_INIT_EXIT_CODE -eq 2 ]; then
  # Special case: LLM classification failed, need user input
  echo "════════════════════════════════════════════════════════"
  echo "Workflow Type Selection Required"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "LLM-based classification is unavailable. Please select"
  echo "the workflow type manually:"
  echo ""

  # Save prompt request to state for bash block boundary
  append_workflow_state "USER_PROMPT_NEEDED" "true"
  append_workflow_state "PROMPT_TYPE" "workflow_type_selection"
fi
```

**After sm_init bash block** (new markdown section):
```markdown
**IF USER_PROMPT_NEEDED == "true"**:

USE the AskUserQuestion tool:

AskUserQuestion {
  questions: [
    {
      question: "LLM classification unavailable. Which workflow type matches your intent for: \"$WORKFLOW_DESCRIPTION_FOR_PROMPT\"?",
      header: "Workflow",
      multiSelect: false,
      options: [
        {
          label: "Research Only",
          description: "Research topics without creating a plan (no implementation)"
        },
        {
          label: "Research + Plan",
          description: "Research topics and create an implementation plan (no execution)"
        },
        {
          label: "Revise Plan",
          description: "Research to update/revise an existing implementation plan"
        },
        {
          label: "Full Implementation",
          description: "Research, plan, implement, test, and document (complete workflow)"
        },
        {
          label: "Debug Only",
          description: "Debug and analyze issues without creating new implementation"
        }
      ]
    }
  ]
}

**After user responds**, USE the Bash tool to process answer:

```bash
set +H
# Load workflow state
WORKFLOW_ID=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt")
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "$WORKFLOW_ID"

# Map user selection to workflow_type
case "$USER_ANSWER" in
  "Research Only") WORKFLOW_SCOPE="research-only" ;;
  "Research + Plan") WORKFLOW_SCOPE="research-and-plan" ;;
  "Revise Plan") WORKFLOW_SCOPE="research-and-revise" ;;
  "Full Implementation") WORKFLOW_SCOPE="full-implementation" ;;
  "Debug Only") WORKFLOW_SCOPE="debug-only" ;;
  *)
    # Handle "Other" or custom input
    echo "Custom workflow type entered: $USER_ANSWER"
    WORKFLOW_SCOPE="research-and-plan"  # Safe default
    ;;
esac

# Use heuristic fallback for complexity and topics
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-scope-detection.sh"
RESEARCH_COMPLEXITY=$(infer_complexity_from_keywords "$WORKFLOW_DESCRIPTION_FOR_PROMPT")
RESEARCH_TOPICS_JSON=$(generate_generic_topics "$RESEARCH_COMPLEXITY")

# Export and persist to state
export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
append_workflow_state "CLASSIFICATION_METHOD" "user_prompt_fallback"

echo "✓ User-selected workflow type: $WORKFLOW_SCOPE"
echo "✓ Heuristic complexity: $RESEARCH_COMPLEXITY"
echo "✓ Generic topics: $(echo "$RESEARCH_TOPICS_JSON" | jq -r 'length') topics"

# Clear prompt flag
append_workflow_state "USER_PROMPT_NEEDED" "false"

# Determine terminal state based on user selection
case "$WORKFLOW_SCOPE" in
  research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
  research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
  research-and-revise) TERMINAL_STATE="$STATE_PLAN" ;;
  full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
  debug-only) TERMINAL_STATE="$STATE_DEBUG" ;;
esac

append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"

# Initialize state machine state
CURRENT_STATE="$STATE_INITIALIZE"
append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"

echo "State machine initialized with user-provided workflow type"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Terminal State: $TERMINAL_STATE"
```

**Then continue with normal workflow** (transition to research phase)
```

**Pros**:
- ✅ Simplest implementation (1 file modified, ~100 lines added)
- ✅ Works for ALL failure types (network, API, confidence)
- ✅ User understands and controls the decision
- ✅ Reuses existing heuristic functions (already tested)
- ✅ Clear error visibility (fail-fast philosophy preserved)

**Cons**:
- ❌ Workflow interruption for user input
- ❌ User must understand workflow types (mitigated by good descriptions)
- ❌ No descriptive topic names (generic "Topic 1", "Topic 2")

**Testing Strategy**:
1. Unit test: `test_sm_init_classification_failure.sh`
   - Mock classification failure
   - Verify return code 2
   - Verify state variables set
2. Integration test: Manual `/coordinate` with network disabled
   - Verify user prompt appears
   - Test all 5 workflow type selections
   - Verify workflow executes correctly with fallback

---

### Approach 2: Hybrid Network Check + User Prompt

**Implementation**:

Same as Approach 1, but add quick network check to auto-fallback to regex mode if offline:

**Additional Function** (add to workflow-llm-classifier.sh):
```bash
# quick_network_check: Fast offline detection (ping only)
# Returns: 0 if online, 1 if offline
quick_network_check() {
  if command -v ping >/dev/null 2>&1; then
    timeout 1 ping -c 1 8.8.8.8 >/dev/null 2>&1
    return $?
  fi
  return 0  # Assume online if ping unavailable
}
```

**In sm_init() before classification**:
```bash
# Pre-flight network check for auto-fallback
if ! quick_network_check; then
  echo "Network offline detected - using regex-only mode" >&2
  export WORKFLOW_CLASSIFICATION_MODE=regex-only
fi

# Attempt classification (will use regex mode if network offline)
if classification_result=$(classify_workflow_comprehensive ...); then
  # Success (either LLM or regex mode)
  ...
else
  # API error or low confidence - prompt user
  export CLASSIFICATION_FAILED="true"
  return 2
fi
```

**Pros**:
- ✅ Auto-fallback for obvious offline case (no user prompt)
- ✅ User prompt only for API/confidence failures
- ✅ Still simple (~50 additional lines vs Approach 1)

**Cons**:
- ⚠️ Two codepaths (slightly more complexity)
- ⚠️ Network check might give false positives

**Recommendation**: Use this if user finds prompts annoying for offline scenarios

---

### Approach 3: Layered Network Detection (Not Recommended)

**Why Not Recommended**:
- ❌ Much higher complexity (300+ lines, 4 files)
- ❌ Network detection unreliable (ping ≠ API access)
- ❌ Doesn't solve API errors or low confidence
- ❌ Hidden complexity vs explicit user choice
- ❌ 3x implementation time

**When to Use**:
- Only if user absolutely cannot tolerate workflow interruption
- Only for network failures (not API/confidence)

---

## 5. Integration with Research Sub-Supervisor

**Current Research Invocation** (coordinate.md:488-505):

The research sub-supervisor is invoked with these inputs:
- Topics: From `RESEARCH_TOPICS_JSON`
- Output directory: `$TOPIC_PATH/reports`
- State file: `$STATE_FILE`
- Supervisor ID: Generated

**Impact of User-Selected Workflow Type**:

1. **Topics will be generic** ("Topic 1", "Topic 2", etc.)
   - Research agents receive less context
   - But behavioral file provides instructions to analyze workflow description
   - Acceptable degradation

2. **Complexity might be inaccurate**
   - Heuristic keyword counting vs semantic LLM analysis
   - Could result in 2-3 agents instead of optimal 3-4
   - Still functional, just less optimized

3. **Workflow scope correctly passed**
   - Terminal state determination works normally
   - State transitions work normally
   - No changes needed to research sub-supervisor

**No Changes Required**: Research sub-supervisor already handles generic topics and variable complexity gracefully.

---

## 6. Changes Needed to Plan Phases 3-4

**Current Plan Phases 3-4** (from context):
- Phase 3: Layered network detection implementation
- Phase 4: Integration and testing

**Recommended Revision**:

**New Phase 3**: User Prompt Fallback Implementation
- Modify `sm_init()` to return code 2 on classification failure
- Add classification failure detection in coordinate.md
- Implement AskUserQuestion prompt block
- Add user answer processing bash block
- Wire up heuristic fallback functions

**New Phase 4**: Testing and Documentation
- Unit test for classification failure handling
- Integration test for user prompt workflow
- Update coordinate-command-guide.md with fallback behavior
- Document user prompt UX

**Removed Phases**:
- ❌ Network detection library
- ❌ Layered connectivity checks
- ❌ Auto-mode switching logic

**Estimated Time Savings**: 4-5 hours (vs layered approach)

---

## 7. Decision Matrix

| Criterion | Option A: Layered Network | Option B: User Prompt | Option C: Hybrid | Winner |
|-----------|--------------------------|----------------------|------------------|--------|
| **Implementation Complexity** | High (300+ lines, 4 files) | Low (100 lines, 1 file) | Medium (150 lines, 2 files) | **B** |
| **Implementation Time** | 6-8 hours | 2-3 hours | 3-4 hours | **B** |
| **Coverage (Failure Types)** | Network only | ALL failures | ALL failures | **B/C** |
| **Reliability** | Low (network ≠ API) | High (explicit) | Medium | **B** |
| **User Experience** | Seamless (no prompt) | Interruption for input | Mostly seamless | **A** |
| **Maintainability** | Low (complex) | High (simple) | Medium | **B** |
| **Fail-Fast Philosophy** | Violates (hidden fallback) | Preserves (user visible) | Partial | **B** |
| **Testing Complexity** | High (network mocking) | Low (straightforward) | Medium | **B** |
| **Risk** | High (false positives) | Low | Medium | **B** |

**Overall Recommendation**: **Option B** (Interactive User Prompt Fallback)

**Rationale**:
1. **Simplicity**: 70% less code than Option A
2. **Completeness**: Handles all failure types (network, API, confidence)
3. **Reliability**: No network detection false positives
4. **Philosophy Alignment**: Fail-fast with explicit user control
5. **Time Efficiency**: 3-5 hours saved vs Option A

**When to Choose Option C**:
- If user feedback indicates frequent offline usage
- If user finds prompts disruptive
- Trade-off: Small complexity increase for better offline UX

---

## 8. Conclusion

The current LLM classification system is intentionally fail-fast with no automatic fallback (clean-break design). When classification fails, the entire workflow terminates.

**Recommended Solution**: Interactive user prompt fallback (Option B)
- Add AskUserQuestion prompt on classification failure
- User selects workflow type from 5 options
- Use heuristic fallback for complexity/topics
- Continue workflow with user-provided type

**Implementation**:
- **Primary Change**: `workflow-state-machine.sh` sm_init() function
- **Secondary Change**: `coordinate.md` prompt injection after sm_init
- **Reuse**: Existing heuristic functions (no new libraries)
- **Effort**: 2-3 hours implementation + 1 hour testing

**Benefits**:
- ✅ 70% simpler than layered network detection
- ✅ Works for ALL classification failure types
- ✅ User controls and understands the decision
- ✅ Preserves fail-fast philosophy (error visible)
- ✅ No false positives or complex network logic

**Trade-offs**:
- ⚠️ Workflow interruption for user input
- ⚠️ Generic topic names (acceptable degradation)
- ⚠️ User must understand workflow types (mitigated by descriptions)

**Next Steps**:
1. Get user approval on Option B vs Option C
2. Revise plan phases 3-4 to implement user prompt approach
3. Update command architecture to handle return code 2
4. Test with all 5 workflow types
5. Document fallback behavior in command guide

---

## Appendix A: Code Locations

**Key Files**:
- `/.claude/lib/workflow-state-machine.sh` - sm_init() classification (line 337-477)
- `/.claude/lib/workflow-llm-classifier.sh` - LLM invocation (line 109-187)
- `/.claude/lib/workflow-scope-detection.sh` - Classification routing (line 49-99)
- `/.claude/commands/coordinate.md` - Orchestrator command (line 170+ sm_init call)

**Heuristic Fallback Functions** (already exist):
- `infer_complexity_from_keywords()` - workflow-scope-detection.sh:143-179
- `generate_generic_topics()` - workflow-scope-detection.sh:184-197

**State Machine Constants**:
- `STATE_INITIALIZE`, `STATE_RESEARCH`, `STATE_PLAN`, etc. - workflow-state-machine.sh:36-44
- Valid workflow types - workflow-llm-classifier.sh:215-221

---

## Appendix B: User Prompt UX Mockup

```
════════════════════════════════════════════════════════
Workflow Type Selection Required
════════════════════════════════════════════════════════

LLM-based classification is unavailable (network error).
Please select the workflow type manually:

Workflow description:
  "Research authentication patterns and create implementation plan"

❓ Which workflow type matches your intent?

  1. Research Only
     → Research topics without creating a plan (no implementation)

  2. Research + Plan
     → Research topics and create an implementation plan (no execution)

  3. Revise Plan
     → Research to update/revise an existing implementation plan

  4. Full Implementation
     → Research, plan, implement, test, and document (complete workflow)

  5. Debug Only
     → Debug and analyze issues without creating new implementation

Your selection: [User selects "2. Research + Plan"]

✓ User-selected workflow type: research-and-plan
✓ Heuristic complexity: 3 topics
✓ Generic topics: 3 topics

Proceeding with research phase...
```
