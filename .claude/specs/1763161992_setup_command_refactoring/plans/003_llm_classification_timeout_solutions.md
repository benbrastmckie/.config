# LLM Classification Timeout - Non-Regex Solutions

## Metadata
- **Created**: 2025-11-14
- **Topic**: Fix LLM classification timeout issues
- **Problem**: File-based signaling with no handler causes 10s timeouts
- **Constraint**: No regex pattern matching (too brittle)

## Problem Summary

The workflow classification system uses **file-based request/response signaling**:

1. Bash writes request JSON to `/tmp/llm_request_*.json`
2. Bash prints `[LLM_CLASSIFICATION_REQUEST]` to stderr
3. Bash polls for response file for 10 seconds
4. **No handler exists to process these requests**
5. Result: Always times out

### Why This Doesn't Work

When bash prints `[LLM_CLASSIFICATION_REQUEST]`, Claude (the AI assistant) sees it in command output but:
- Is not programmed to intercept this special message format
- Cannot automatically read request files from bash output
- Has no mechanism to write response files back
- This pattern assumes an external process/hook that doesn't exist

## Non-Regex Solutions

### Solution 1: Direct Claude Invocation via Task Tool

**Concept**: Instead of file-based signaling, directly invoke Claude classification as a synchronous task.

#### Architecture

**Current (Broken)**:
```
bash → write request.json → print [REQUEST] → poll for response.json → timeout
         ↓
      [nobody listening]
```

**Proposed**:
```
bash → invoke Task tool → Claude processes → returns JSON → bash continues
         ↓
      Direct synchronous call (works!)
```

#### Implementation

**File**: `.claude/lib/workflow-llm-classifier.sh`

**Replace** `invoke_llm_classifier()` function (lines 287-359) with:

```bash
# invoke_llm_classifier - Direct synchronous Claude invocation
# Args:
#   $1: llm_input - JSON input for classifier (workflow description + instructions)
# Returns:
#   0: Success (prints JSON response to stdout)
#   1: Error
# Note: This is a PLACEHOLDER - actual implementation requires Claude Code
#       to support bash→Claude communication or use a different mechanism
invoke_llm_classifier() {
  local llm_input="$1"
  local workflow_id="${2:-default}"

  # Extract workflow description from JSON input
  local workflow_desc
  workflow_desc=$(echo "$llm_input" | jq -r '.workflow_description')

  # CRITICAL: This requires Claude Code framework support
  # Option A: Use a dedicated classification agent
  # Option B: Use a special bash→Claude bridge
  # Option C: Make classification happen at command level (not library level)

  # For now, write request and trigger a special marker that Claude Code
  # framework can intercept
  mkdir -p "${HOME}/.claude/tmp"
  local request_file="${HOME}/.claude/tmp/llm_request_${workflow_id}.json"
  local response_file="${HOME}/.claude/tmp/llm_response_${workflow_id}.json"

  echo "$llm_input" > "$request_file"

  # PROPOSAL: Claude Code framework should detect this pattern and
  # automatically invoke classification via Task tool
  echo "CLAUDE_CODE_CLASSIFICATION_REQUEST:$request_file:$response_file" >&2

  # Wait for framework to process (shorter timeout since it's synchronous)
  local max_wait=5  # 5 seconds should be plenty for synchronous call
  local count=0
  while [ $count -lt $max_wait ]; do
    if [ -f "$response_file" ]; then
      cat "$response_file"
      return 0
    fi
    sleep 1
    count=$((count + 1))
  done

  echo "ERROR: Classification request timed out" >&2
  return 1
}
```

**Pros**:
- Synchronous (fast when it works)
- No external dependencies
- Clean architecture

**Cons**:
- Requires Claude Code framework support
- Framework must intercept `CLAUDE_CODE_CLASSIFICATION_REQUEST:` pattern
- Still uses files (but shorter timeout)

**Complexity**: High (requires framework changes)
**Reliability**: Very High (once implemented)

---

### Solution 2: Classification Agent with Direct Invocation

**Concept**: Create a specialized classification agent and invoke it directly from the command (not library).

#### Architecture

Move classification OUT of the library and INTO the command itself, where we can use the Task tool.

**Current Flow**:
```
/coordinate → workflow-state-machine.sh → sm_init() → classify_workflow_comprehensive() → TIMEOUT
                                            ↓
                                         (in library, can't use Task tool)
```

**Proposed Flow**:
```
/coordinate → [bash block 1: invoke classification agent via Task tool] → get result → sm_init_with_result()
                     ↓
                  (in command, can use Task tool!)
```

#### Implementation

**Step 1**: Create classification agent

**File**: `.claude/agents/workflow-classifier.md`

```markdown
# Workflow Classifier Agent

YOU ARE a workflow classification specialist.

Your task is to analyze workflow descriptions and classify them into categories.

## Input

You will receive a workflow description.

## Classification Schema

**Workflow Types** (scope):
- `research-only`: Pure research, no planning/implementation
- `research-and-plan`: Research + create implementation plan
- `research-and-revise`: Research + revise existing plan
- `full-implementation`: Complete workflow (research + plan + implement)
- `debug-only`: Investigate and debug issues

**Research Complexity** (1-4):
- 1: Single focused topic
- 2: Two related topics
- 3: Three interconnected topics
- 4+: Complex multi-topic investigation

**Research Topics**:
List of specific research areas (use descriptive names, not "Topic 1")

## Output Format

Return ONLY a JSON object (no markdown, no explanation):

```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "reasoning": "Brief explanation",
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Topic name",
      "detailed_description": "What to research",
      "filename_slug": "topic_name"
    }
  ]
}
```

## Examples

**Input**: "research authentication patterns to create implementation plan"
**Output**:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "reasoning": "Explicitly mentions research followed by planning",
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Authentication patterns",
      "detailed_description": "Common authentication patterns and best practices",
      "filename_slug": "authentication_patterns"
    },
    {
      "short_name": "Implementation approach",
      "detailed_description": "How to implement chosen authentication pattern",
      "filename_slug": "implementation_approach"
    }
  ]
}
```

**CRITICAL**: Always return valid JSON. No other text.
```

**Step 2**: Modify /coordinate command initialization

**File**: `.claude/commands/coordinate.md` (State Machine Initialization - Part 2)

**Replace** the sm_init call (around line 150-160) with:

```bash
# NEW: Direct classification via Task tool (instead of library timeout)
echo "Classifying workflow..."

# Invoke classification agent
CLASSIFICATION_RESULT=""  # Will be set by Task tool result

# EXECUTE NOW: USE the Task tool to classify workflow
```

Then add **after the bash block**:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow description"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/workflow-classifier.md

    **Workflow Description**: $SAVED_WORKFLOW_DESC

    Return ONLY the JSON classification result, nothing else.
  "
}
```

Then continue with another bash block:

```bash
# CLASSIFICATION_RESULT now contains the JSON from agent
# Parse and validate it
if [ -z "$CLASSIFICATION_RESULT" ]; then
  echo "ERROR: Classification agent returned empty result"
  exit 1
fi

# Validate JSON
if ! echo "$CLASSIFICATION_RESULT" | jq -e . >/dev/null 2>&1; then
  echo "ERROR: Classification agent returned invalid JSON"
  exit 1
fi

# Extract fields
export WORKFLOW_SCOPE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.workflow_type')
export RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_RESULT" | jq -r '.research_complexity')
export RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_RESULT" | jq -c '.research_topics')

# Validate extracted values
if [ -z "$WORKFLOW_SCOPE" ] || [ "$WORKFLOW_SCOPE" = "null" ]; then
  echo "ERROR: Failed to extract workflow_type from classification"
  exit 1
fi

echo "✓ Workflow classified: scope=$WORKFLOW_SCOPE, complexity=$RESEARCH_COMPLEXITY"

# Continue with normal initialization...
```

**Pros**:
- Uses existing Task tool mechanism (proven to work)
- Synchronous and fast
- Clean separation of concerns
- Agent can be reused/tested independently

**Cons**:
- Moves classification from library to command (more code in command)
- Requires updating all orchestration commands (/coordinate, /orchestrate, /supervise)
- Breaking change to library API

**Complexity**: Medium (agent creation + command updates)
**Reliability**: Very High (uses proven Task tool pattern)

---

### Solution 3: Hybrid - Library with Task Tool Bridge

**Concept**: Keep classification in library but make it invoke an agent internally.

#### Architecture

This is tricky because bash libraries can't directly use the Task tool. But we can:
1. Have the library write a special marker
2. Have the command detect the marker
3. Command invokes agent
4. Library reads result

**Current**:
```
Library: classify() → timeout
```

**Proposed**:
```
Library: classify() → write marker → return "PENDING"
Command: detect "PENDING" → invoke agent → write result
Library: classify() (second call) → read result → return
```

This is complex and fragile - **NOT RECOMMENDED**.

---

### Solution 4: Pre-Classification in Command

**Concept**: Do classification BEFORE calling library functions.

#### Architecture

**Current Flow**:
```
/coordinate → sm_init("description") → [library classifies] → TIMEOUT
```

**Proposed Flow**:
```
/coordinate → [classify via Task tool] → sm_init(description, classification_result) → [library uses provided result]
```

#### Implementation

**Step 1**: Update `sm_init()` signature

**File**: `.claude/lib/workflow-state-machine.sh`

**Change** `sm_init()` to accept pre-computed classification:

```bash
# sm_init - Initialize state machine with workflow classification
# Args:
#   $1: workflow_description
#   $2: command_name (coordinate, orchestrate, etc.)
#   $3: classification_result (OPTIONAL - pre-computed JSON classification)
sm_init() {
  local workflow_description="$1"
  local command_name="$2"
  local classification_result="${3:-}"  # Optional pre-computed result

  if [ -n "$classification_result" ]; then
    # Use provided classification (skip LLM call)
    echo "Using pre-computed classification"

    # Extract and export fields
    export WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
    export RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity')
    export RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.research_topics')

    # Validate
    if [ -z "$WORKFLOW_SCOPE" ]; then
      echo "ERROR: Invalid pre-computed classification" >&2
      return 1
    fi
  else
    # Original behavior - call classifier
    local classification_result
    if ! classification_result=$(classify_workflow_comprehensive "$workflow_description"); then
      echo "ERROR: Workflow classification failed" >&2
      return 1
    fi

    export WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
    export RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity')
    export RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.research_topics')
  fi

  # ... rest of sm_init logic ...
}
```

**Step 2**: Update /coordinate to pre-classify

**In coordinate.md**, add classification BEFORE sm_init call:

```bash
# Pre-classify workflow using Task tool (avoids library timeout)
echo "Classifying workflow description..."

# Save classification request for agent
CLASSIFICATION_REQUEST=$(cat <<EOF
{
  "workflow_description": "$SAVED_WORKFLOW_DESC",
  "valid_scopes": ["research-only", "research-and-plan", "research-and-revise", "full-implementation", "debug-only"]
}
EOF
)

# Write to temp file for agent to read
CLASSIFICATION_REQUEST_FILE="${HOME}/.claude/tmp/classify_request_${WORKFLOW_ID}.txt"
echo "$SAVED_WORKFLOW_DESC" > "$CLASSIFICATION_REQUEST_FILE"

echo "CLASSIFICATION_REQUEST_FILE=$CLASSIFICATION_REQUEST_FILE"
```

**Then add Task invocation** (outside bash block):

```markdown
**EXECUTE NOW**: USE the Task tool to classify workflow:

Task {
  subagent_type: "general-purpose"
  description: "Classify workflow for orchestration"
  timeout: 30000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/workflow-classifier.md

    **Workflow Description**:
    $(cat $CLASSIFICATION_REQUEST_FILE)

    Classify this workflow and return ONLY the JSON result.

    Return format:
    CLASSIFICATION_RESULT: {\"workflow_type\": \"...\", \"confidence\": 0.95, ...}
  "
}
```

**Then continue in bash**:

```bash
# Parse agent response (should have CLASSIFICATION_RESULT: prefix)
# Extract JSON and pass to sm_init

if [ -z "$CLASSIFICATION_RESULT" ]; then
  echo "ERROR: Classification failed"
  exit 1
fi

# Initialize state machine WITH classification result
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$CLASSIFICATION_RESULT"
```

**Pros**:
- Backward compatible (optional parameter)
- Commands can choose to pre-classify or use library default
- Library stays functional for non-orchestration use cases
- Gradual migration path

**Cons**:
- Requires creating classification agent
- More code in commands
- Need to update multiple commands

**Complexity**: Medium
**Reliability**: Very High

---

## Recommended Solution

### Solution 2: Classification Agent with Direct Invocation

**Why**:
1. **Uses proven patterns**: Task tool is reliable and works
2. **Clean architecture**: Classification is a distinct concern, deserves its own agent
3. **Testable**: Agent can be tested independently
4. **Reusable**: Other commands can use same agent
5. **No framework changes**: Works with current Claude Code
6. **Fast**: Synchronous invocation, typically <5 seconds

**Migration Strategy**:
1. Create workflow-classifier.md agent (30 min)
2. Update /coordinate command to use agent (1 hour)
3. Test with various workflow descriptions (30 min)
4. Update other orchestration commands (/orchestrate, /supervise) (1 hour each)
5. Optional: Keep library classification as fallback for non-agent environments

**Total Effort**: ~4 hours
**Risk**: Low (uses existing proven patterns)
**Benefit**: Eliminates all timeout issues permanently

---

## Alternative: Solution 4 (Pre-Classification)

**Why as alternative**:
- Backward compatible
- Gradual migration
- Library remains functional

**When to choose**:
- If you want minimal breaking changes
- If other code depends on current library API
- If you want to support both agent and non-agent modes

**Total Effort**: ~5 hours (similar to Solution 2 but more testing needed)
**Risk**: Medium (more complex due to dual paths)

---

## Implementation Plan for Solution 2

### Phase 1: Create Classification Agent (30 min)

1. Create `/home/benjamin/.config/.claude/agents/workflow-classifier.md`
2. Define clear classification rules
3. Add comprehensive examples
4. Test manually with sample descriptions

**Deliverable**: Working agent that returns valid JSON

### Phase 2: Update /coordinate Command (1 hour)

1. Backup current coordinate.md
2. Add classification invocation before sm_init
3. Remove sm_init call to classify_workflow_comprehensive
4. Pass pre-computed result to sm_init
5. Add error handling for failed classification

**Deliverable**: /coordinate works without timeouts

### Phase 3: Test and Validate (30 min)

1. Test with various workflow descriptions:
   - Research-only workflows
   - Research-and-plan workflows
   - Full implementation workflows
   - Edge cases (ambiguous descriptions)
2. Verify classification results are accurate
3. Verify no timeouts occur

**Deliverable**: Confidence in solution

### Phase 4: Update Other Commands (2 hours)

1. Update /orchestrate (1 hour)
2. Update /supervise (1 hour)
3. Consider updating /plan if it uses classification

**Deliverable**: All orchestration commands timeout-free

### Phase 5: Documentation (30 min)

1. Document new classification flow
2. Update command guides
3. Add troubleshooting section
4. Document agent usage

**Deliverable**: Complete documentation

---

## Timeline

**Total Time**: 4.5 hours

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Agent | 30 min | None |
| Phase 2: /coordinate | 1 hour | Phase 1 |
| Phase 3: Testing | 30 min | Phase 2 |
| Phase 4: Other cmds | 2 hours | Phase 3 |
| Phase 5: Docs | 30 min | Phase 4 |

---

## Files to Modify

### New Files
- `.claude/agents/workflow-classifier.md` - Classification agent

### Modified Files
- `.claude/commands/coordinate.md` - Pre-classification logic
- `.claude/commands/orchestrate.md` - Pre-classification logic
- `.claude/commands/supervise.md` - Pre-classification logic
- `.claude/docs/guides/coordinate-command-guide.md` - Update with new flow
- `.claude/lib/workflow-state-machine.sh` - Optional: Accept pre-computed classification

### Optional (for backward compatibility)
- Keep `.claude/lib/workflow-llm-classifier.sh` as-is for non-agent callers
- Add deprecation notice

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Agent returns invalid JSON | High | Low | Validation + fallback to error |
| Classification takes >30s | Medium | Very Low | Task tool timeout handles this |
| Breaking changes for other code | High | Medium | Make sm_init backward compatible |
| Agent misclassifies workflows | Medium | Low | Clear examples + testing |

---

## Success Criteria

- [ ] No classification timeouts occur
- [ ] Classification completes in <10 seconds (typically <5s)
- [ ] All workflow types correctly classified
- [ ] /coordinate, /orchestrate, /supervise all work
- [ ] Backward compatibility maintained (library still works)
- [ ] Documentation updated
- [ ] Tests pass

---

## Next Steps

1. **Review this document** - Choose preferred solution
2. **Create classification agent** - Start with Phase 1
3. **Test agent independently** - Verify it works
4. **Update one command** - Start with /coordinate
5. **Validate** - Ensure no regressions
6. **Roll out to other commands** - Complete migration

---

## Research Reports and Related Artifacts

- **Research Overview**: [../reports/001_llm_classification_state_machine_integration/OVERVIEW.md](../reports/001_llm_classification_state_machine_integration/OVERVIEW.md) - LLM Classification State Machine Integration comprehensive synthesis
  - **Subtopic 1**: [Agent Invocation Pattern and Task Tool Integration](../reports/001_llm_classification_state_machine_integration/001_agent_invocation_pattern_and_task_tool_integration.md)
  - **Subtopic 2**: [State Machine Checkpoint Coordination with Classification](../reports/001_llm_classification_state_machine_integration/002_state_machine_checkpoint_coordination_with_classification.md)
  - **Subtopic 3**: [Command-Level Classification Flow and Error Handling](../reports/001_llm_classification_state_machine_integration/003_command_level_classification_flow_and_error_handling.md)
  - **Subtopic 4**: [Backward Compatibility and Library Migration Strategy](../reports/001_llm_classification_state_machine_integration/004_backward_compatibility_and_library_migration_strategy.md)

---

**Status**: Awaiting decision on preferred solution
**Recommendation**: Solution 2 (Classification Agent)
**Estimated Effort**: 4.5 hours total
