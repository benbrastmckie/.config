# Agent Invocation Pattern and Task Tool Integration Research Report

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Agent Invocation Pattern and Task Tool Integration
- **Report Type**: Codebase analysis and pattern recognition
- **Synthesis**: [OVERVIEW.md](OVERVIEW.md) - LLM Classification State Machine Integration Overview
- **Related Subtopics**: [002_state_machine_checkpoint_coordination_with_classification.md](002_state_machine_checkpoint_coordination_with_classification.md), [003_command_level_classification_flow_and_error_handling.md](003_command_level_classification_flow_and_error_handling.md), [004_backward_compatibility_and_library_migration_strategy.md](004_backward_compatibility_and_library_migration_strategy.md)

## Executive Summary

The current LLM classification system uses a **file-based signaling pattern** that polls for an external handler that doesn't exist, causing inevitable 10-second timeouts. This pattern originates from `.claude/lib/workflow-llm-classifier.sh` which writes request files and emits `[LLM_CLASSIFICATION_REQUEST]` markers to stderr, expecting an external process to respond. The solution is to replace this with **proper Task tool agent invocation** following the established behavioral injection pattern used successfully by orchestration commands like `/coordinate`. This involves creating a classification agent and invoking it directly from commands rather than polling for file responses from libraries.

## Findings

### Current File-Based Signaling Pattern

#### Implementation Location

**File**: `.claude/lib/workflow-llm-classifier.sh` (lines 287-359)

**Function**: `invoke_llm_classifier()`

The current implementation follows this broken workflow:

1. **Write request file** (line 324):
   ```bash
   request_file="${HOME}/.claude/tmp/llm_request_${workflow_id}.json"
   response_file="${HOME}/.claude/tmp/llm_response_${workflow_id}.json"
   echo "$llm_input" > "$request_file"
   ```

2. **Emit signal to stderr** (line 327):
   ```bash
   echo "[LLM_CLASSIFICATION_REQUEST] Please process request at: $request_file → $response_file" >&2
   ```

3. **Poll for response file** (lines 330-353):
   ```bash
   local iterations=$((WORKFLOW_CLASSIFICATION_TIMEOUT * 2))  # Check every 0.5s
   local count=0
   while [ $count -lt $iterations ]; do
     if [ -f "$response_file" ]; then
       response=$(cat "$response_file")
       echo "$response"
       return 0
     fi
     sleep 0.5
     count=$((count + 1))
   done
   ```

4. **Timeout after 10 seconds** (lines 356-358):
   ```bash
   log_classification_error "invoke_llm_classifier" "timeout after ${WORKFLOW_CLASSIFICATION_TIMEOUT}s"
   return 1
   ```

#### Why This Pattern Fails

**Root Cause**: The pattern assumes an **external handler** monitors stderr for `[LLM_CLASSIFICATION_REQUEST]` signals, reads request files, performs classification, and writes response files. **No such handler exists** in the Claude Code framework.

**Evidence**:
- `.claude/specs/1763161992_setup_command_refactoring/plans/003_llm_classification_timeout_solutions.md` (lines 19-26): Documents that Claude sees the stderr marker but has no mechanism to intercept it, read request files, or write response files
- The pattern is **caller-blocking**: bash blocks execution waiting for a file that will never arrive
- No error occurs until timeout (10 seconds of wasted execution time)

#### Where This Pattern Is Used

**Primary Call Site**: `.claude/lib/workflow-state-machine.sh` (lines 334-399)

**Function**: `sm_init()` - State machine initialization

```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Lines 349-380: Invoke comprehensive classification
  if classification_result=$(classify_workflow_comprehensive "$workflow_desc" "$classification_workflow_id" 2>"$classification_stderr_file"); then
    WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
    RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
    RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')
    export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  else
    # Fail-fast: No automatic fallback (line 389)
    echo "CRITICAL ERROR: Comprehensive classification failed" >&2
    return 1
  fi
}
```

**Invoked by**:
- `/coordinate` command (line 167): `sm_init "$SAVED_WORKFLOW_DESC" "coordinate"`
- `/orchestrate` command (similar pattern)
- `/supervise` command (similar pattern)

All orchestration commands depend on this broken pattern in their state machine initialization.

### Behavioral Injection Pattern for Agent Invocation

#### How Commands Currently Invoke Agents Successfully

Commands like `/coordinate` successfully invoke agents using the **Task tool with behavioral injection pattern**.

**Example**: Research agent invocation from `.claude/commands/coordinate.md` (lines 566-585)

```markdown
**EXECUTE NOW**: USE the Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_1
    - Report Path: $AGENT_REPORT_PATH_1
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

#### Key Characteristics of Working Pattern

1. **Imperative Execution Directive**: `**EXECUTE NOW**: USE the Task tool` (line 564)
2. **Behavioral File Reference**: Points to `.claude/agents/research-specialist.md`
3. **Context Injection**: Provides workflow-specific parameters (paths, complexity, standards)
4. **No Code Fence Wrappers**: Task invocation is NOT wrapped in ` ```yaml ` blocks (would prevent execution)
5. **Explicit Return Format**: Expects structured response like `REPORT_CREATED: /path/to/file`

**Documentation**: `.claude/docs/concepts/patterns/behavioral-injection.md` defines this pattern comprehensively:
- Lines 40-107: Core mechanism explanation
- Lines 262-323: Anti-pattern warnings (inline template duplication, documentation-only YAML blocks)
- Lines 676-840: Case studies from Spec 495 and Spec 057

#### Why This Pattern Works

**Synchronous Execution**: The Task tool invocation blocks until the agent completes and returns, eliminating the need for file polling.

**Standard 11 (Imperative Agent Invocation)**: Documented in `.claude/docs/reference/command_architecture_standards.md` (lines 334-414):
- Imperative instructions prevent documentation-only interpretation
- No code block wrappers around Task invocations
- Direct reference to agent behavioral files
- Explicit completion signals for verification

### Integration Points for Task Tool Replacement

#### Architectural Constraint: Library vs Command Context

**Critical Limitation**: The current classification is invoked from **library functions** (`sm_init()` in `workflow-state-machine.sh`), which **cannot use the Task tool**.

**Why Libraries Can't Use Task Tool**:
- Libraries are sourced bash code with no access to Claude's tool invocation context
- Task tool requires being in a command execution context (`.claude/commands/*.md`)
- Libraries can only use bash primitives (functions, variables, file I/O)

**Evidence**: All existing agent invocations occur in **commands**, not libraries:
- `.claude/commands/coordinate.md` (lines 490-585): Research agent invocations
- `.claude/commands/orchestrate.md` (similar patterns)
- No libraries invoke agents via Task tool

#### Two Architectural Options

**Option 1: Move Classification to Command Level (Recommended)**

**Architecture**:
```
/coordinate command
  ↓
[Phase 0 Bash Block 1: Invoke classification agent via Task tool]
  ↓
[Get classification result JSON]
  ↓
[Phase 0 Bash Block 2: Call sm_init_with_result(scope, complexity, topics)]
  ↓
[Continue with research phase...]
```

**Changes Required**:
1. Create `.claude/agents/workflow-classifier.md` - Specialization of existing classification logic
2. Update orchestration commands to invoke classifier agent BEFORE sm_init()
3. Refactor `sm_init()` to accept classification results as parameters instead of performing classification
4. Remove file-based signaling from `workflow-llm-classifier.sh`

**Pros**:
- Follows established behavioral injection pattern
- No framework changes required
- Clean separation: commands orchestrate, agents execute, libraries provide utilities
- Testable in isolation

**Cons**:
- Requires updating all orchestration commands (`/coordinate`, `/orchestrate`, `/supervise`)
- Increases command file size slightly (adds agent invocation block)

**Option 2: Framework-Level Interception (Not Recommended)**

**Architecture**:
```
bash library → emit [CLASSIFICATION_REQUEST] → Claude Code framework intercepts → invokes agent → writes response → bash continues
```

**Changes Required**:
1. Modify Claude Code framework to intercept stderr markers
2. Implement automatic agent invocation from framework
3. Write response files back to bash

**Pros**:
- No command changes required
- Classification remains in library

**Cons**:
- Requires framework-level changes (high risk)
- Breaks architectural separation (framework shouldn't execute business logic)
- Adds complexity to framework maintenance
- Violates "commands orchestrate, libraries provide utilities" principle

## Recommendations

### Recommendation 1: Create Workflow Classification Agent (High Priority)

**Action**: Create `.claude/agents/workflow-classifier.md` following the pattern of `research-specialist.md`.

**Behavioral File Structure**:
```markdown
---
allowed-tools: None (pure logic agent)
model: haiku
description: Fast semantic workflow classification for orchestration commands
---

# Workflow Classifier Agent

**YOU MUST perform these exact steps**:

1. Receive workflow description via injected context
2. Analyze description semantically (not keyword matching)
3. Classify into workflow type (research-only, research-and-plan, research-and-revise, full-implementation, debug-only)
4. Determine research complexity (1-4 based on scope)
5. Generate descriptive research topic names (matching complexity count)
6. Return JSON: {"workflow_type": "...", "confidence": 0.0-1.0, "research_complexity": N, "research_topics": [...]}

**CRITICAL**: Focus on INTENT not keywords. Example: "research the research-and-revise workflow" is research-and-plan (intent: learn about workflow type), not research-and-revise (intent: revise a plan).
```

**Rationale**:
- Haiku model is sufficient for classification (fast, cost-effective)
- No tool access needed (pure analysis task)
- Structured JSON output enables easy parsing
- Follows existing agent patterns (testable, maintainable)

**Effort**: ~2 hours (create agent file, test basic invocations)

### Recommendation 2: Refactor sm_init() to Accept Classification Parameters (High Priority)

**Action**: Split `sm_init()` into two functions in `workflow-state-machine.sh`:

**Before** (lines 334-399):
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Performs classification internally (BROKEN - uses file polling)
  classification_result=$(classify_workflow_comprehensive "$workflow_desc")
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
  # ... rest of initialization
}
```

**After**:
```bash
# sm_init_with_classification: Initialize state machine with pre-classified results
# Args:
#   $1: workflow_desc - Workflow description string
#   $2: command_name - Command name (coordinate, orchestrate, supervise)
#   $3: workflow_scope - Pre-classified workflow type
#   $4: research_complexity - Pre-determined complexity (1-4)
#   $5: research_topics_json - JSON array of topic names
sm_init_with_classification() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_scope="$3"
  local research_complexity="$4"
  local research_topics_json="$5"

  # Store provided classification (no internal classification)
  WORKFLOW_DESCRIPTION="$workflow_desc"
  COMMAND_NAME="$command_name"
  WORKFLOW_SCOPE="$workflow_scope"
  RESEARCH_COMPLEXITY="$research_complexity"
  RESEARCH_TOPICS_JSON="$research_topics_json"

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON

  # Continue with state machine setup (terminal state calculation, etc.)
  sm_calculate_terminal_state
  sm_reset  # Reset to initialize state

  return 0
}
```

**Rationale**:
- Separates classification (command-level, uses Task tool) from state machine initialization (library-level, pure bash)
- Removes file-based polling dependency
- Maintains backward compatibility (keep old `sm_init()` as wrapper that fails with clear error)
- Testable: can inject mock classification results

**Effort**: ~1 hour (refactor function, update tests)

### Recommendation 3: Update Orchestration Commands to Invoke Classifier Agent (High Priority)

**Action**: Update `/coordinate`, `/orchestrate`, `/supervise` commands to invoke workflow-classifier agent in Phase 0.

**Pattern to Add** (before current sm_init call):

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

**Files to Update**:
1. `.claude/commands/coordinate.md` (insert after line 167, before current sm_init call)
2. `.claude/commands/orchestrate.md` (similar location)
3. `.claude/commands/supervise.md` (similar location)

**Rationale**:
- Follows proven behavioral injection pattern
- Eliminates file polling timeout
- Makes classification visible and debuggable
- Enables parallel classification if needed

**Effort**: ~2 hours (update 3 command files, test workflows)

### Recommendation 4: Remove File-Based Signaling Code (Medium Priority)

**Action**: After confirming Task tool approach works, remove obsolete file-based signaling from `workflow-llm-classifier.sh`.

**Functions to Deprecate**:
- `invoke_llm_classifier()` (lines 287-359) - Replace with clear error message
- Cleanup functions (lines 650-677) - No longer needed

**Keep**:
- `build_llm_classifier_input()` (lines 206-266) - Reuse for agent prompt construction
- `parse_llm_classifier_response()` (lines 361-529) - Reuse for agent response validation
- Error handling functions (lines 531-645) - Reuse for agent error handling

**Rationale**:
- Reduces maintenance burden
- Prevents accidental reintroduction of broken pattern
- Clarifies intended usage (classification via agent, not library polling)

**Effort**: ~1 hour (cleanup, update tests)

### Recommendation 5: Document Pattern in Standards (Low Priority)

**Action**: Add to `.claude/docs/reference/command_architecture_standards.md` a new standard:

**Standard 18: Classification via Agent Invocation**

Workflow classification MUST be performed at command level via Task tool agent invocation, NOT at library level via file polling. Libraries provide parsing/validation utilities but do not invoke agents directly.

**Rationale**:
- Prevents future regression to file-based polling
- Clarifies architectural boundary (commands orchestrate, libraries provide utilities)
- Provides clear guidance for new command development

**Effort**: ~30 minutes (documentation update)

## References

### Current Implementation Files

- `.claude/lib/workflow-llm-classifier.sh` (lines 1-690) - File-based signaling implementation
  - Lines 287-359: `invoke_llm_classifier()` - Broken polling function
  - Lines 327: `[LLM_CLASSIFICATION_REQUEST]` stderr marker emission
- `.claude/lib/workflow-scope-detection.sh` (lines 1-183) - Unified detection library
  - Lines 48-86: `classify_workflow_comprehensive()` - Calls LLM classifier
- `.claude/lib/workflow-state-machine.sh` (lines 1-850) - State machine library
  - Lines 334-399: `sm_init()` - Invokes classification during initialization
- `.claude/commands/coordinate.md` (lines 1-2800) - Primary orchestration command
  - Line 167: `sm_init()` invocation that triggers timeout
  - Lines 490-585: Working agent invocation examples (research-specialist)

### Pattern Documentation

- `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-1162) - Complete pattern guide
  - Lines 40-107: Core mechanism explanation
  - Lines 262-323: Anti-patterns (inline duplication, documentation-only YAML)
  - Lines 676-840: Case studies (Spec 495, Spec 057)
- `.claude/docs/reference/command_architecture_standards.md` (lines 1-100+) - Architecture standards
  - Standard 0: Execution enforcement (imperative language)
  - Standard 11: Imperative agent invocation pattern (lines referenced in behavioral-injection.md)

### Related Specifications

- `.claude/specs/1763161992_setup_command_refactoring/plans/003_llm_classification_timeout_solutions.md` (lines 1-150) - Analysis of timeout problem
  - Lines 19-26: Documents why file-based signaling doesn't work
  - Lines 29-118: Proposed Task tool solution (aligns with this report)
- Spec 495: `/coordinate` and `/research` agent delegation failures - Fixed via behavioral injection pattern
- Spec 057: `/supervise` robustness improvements - Removed fallback mechanisms, added fail-fast

### Agent Behavioral Files (Reference for Pattern)

- `.claude/agents/research-specialist.md` (lines 1-671) - Example agent structure
  - Lines 23-70: Step-by-step execution instructions
  - Lines 322-411: Completion criteria checklist (28 requirements)
- `.claude/agents/research-sub-supervisor.md` - Hierarchical supervisor pattern
- 20+ other agents in `.claude/agents/` following same pattern
