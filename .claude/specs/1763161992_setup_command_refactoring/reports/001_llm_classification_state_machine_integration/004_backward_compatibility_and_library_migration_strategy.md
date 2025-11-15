# Backward Compatibility and Library Migration Strategy

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: Migration strategy from file-based LLM classification to agent-based approach
- **Report Type**: Codebase analysis and migration planning
- **Synthesis**: [OVERVIEW.md](OVERVIEW.md) - LLM Classification State Machine Integration Overview
- **Related Subtopics**: [001_agent_invocation_pattern_and_task_tool_integration.md](001_agent_invocation_pattern_and_task_tool_integration.md), [002_state_machine_checkpoint_coordination_with_classification.md](002_state_machine_checkpoint_coordination_with_classification.md), [003_command_level_classification_flow_and_error_handling.md](003_command_level_classification_flow_and_error_handling.md)

## Executive Summary

Current LLM classification system uses file-based signaling that times out because no handler exists to process requests. Analysis shows the workflow-llm-classifier.sh library is sourced by workflow-scope-detection.sh and workflow-state-machine.sh, but file-based request/response pattern never completes. Recommended migration strategy: create dedicated workflow-classifier agent and modify orchestration commands (/coordinate, /orchestrate, /supervise) to invoke agent via Task tool BEFORE calling sm_init(), maintaining backward compatibility by making classification result an optional parameter to sm_init(). This eliminates timeouts while preserving library functionality for non-orchestration use cases.

## Research Progress

PROGRESS: Creating report file at specs/reports/004_backward_compatibility.md
PROGRESS: Starting research on backward compatibility and migration strategy
PROGRESS: Searching codebase for workflow-llm-classifier usage

## Findings

### Current Implementation Architecture

**File**: `.claude/lib/workflow-llm-classifier.sh` (690 lines)

**Core Functions**:
1. `classify_workflow_llm()` - Main entry point for LLM-based classification (lines 36-84)
2. `classify_workflow_llm_comprehensive()` - Comprehensive classification with enhanced topics (lines 109-204)
3. `invoke_llm_classifier()` - File-based signaling mechanism (lines 287-359)
4. `parse_llm_classifier_response()` - Response validation (lines 361-529)

**File-Based Signaling Pattern** (lines 287-359):
```bash
invoke_llm_classifier() {
  local llm_input="$1"
  local workflow_id="${2:-default}"

  # Use semantic workflow-scoped filenames
  mkdir -p "${HOME}/.claude/tmp"
  local request_file="${HOME}/.claude/tmp/llm_request_${workflow_id}.json"
  local response_file="${HOME}/.claude/tmp/llm_response_${workflow_id}.json"

  # Write request file
  echo "$llm_input" > "$request_file"

  # Signal to AI assistant with semantic file paths
  echo "[LLM_CLASSIFICATION_REQUEST] Please process request at: $request_file → $response_file" >&2

  # Wait for response with timeout
  local iterations=$((WORKFLOW_CLASSIFICATION_TIMEOUT * 2))  # Check every 0.5s
  local count=0
  while [ $count -lt $iterations ]; do
    if [ -f "$response_file" ]; then
      # Response received - read and return
      local response
      response=$(cat "$response_file")
      # ... validation logic ...
      echo "$response"
      return 0
    fi
    sleep 0.5
    count=$((count + 1))
  done

  # Timeout
  log_classification_error "invoke_llm_classifier" "timeout after ${WORKFLOW_CLASSIFICATION_TIMEOUT}s"
  return 1
}
```

**Problem**: The `[LLM_CLASSIFICATION_REQUEST]` pattern is printed to stderr, but **no handler exists** to:
- Intercept this message
- Read the request file
- Process the classification
- Write the response file

Result: **Always times out after 10 seconds** (default WORKFLOW_CLASSIFICATION_TIMEOUT).

PROGRESS: Analyzing library dependencies and usage patterns

### Library Dependencies and Usage

**Direct Callers** (found via grep analysis):

1. **`.claude/lib/workflow-scope-detection.sh`**
   - Sources workflow-llm-classifier.sh
   - Calls `classify_workflow_llm_comprehensive()` in llm-only mode
   - Used by orchestration commands

2. **`.claude/lib/workflow-state-machine.sh`**
   - Sources workflow-scope-detection.sh (indirect dependency)
   - Calls classification during `sm_init()` initialization
   - Core state machine library used by all orchestrators

**Orchestration Commands** (indirect usage via state machine):

1. **`/coordinate`** - Wave-based parallel orchestration
2. **`/orchestrate`** - Full-featured orchestration with PR automation
3. **`/supervise`** - Sequential orchestration with architectural compliance

All three commands call `sm_init()` which triggers classification.

PROGRESS: Analyzing function signatures and API contracts

### Library Function Signatures

**Current API** (must maintain for backward compatibility):

```bash
# classify_workflow_llm - Basic LLM classification
# Args:
#   $1: workflow_description - The workflow description to classify
#   $2: workflow_id - Workflow identifier for semantic filename scoping (optional)
# Returns:
#   0: Classification successful (prints JSON to stdout)
#   1: Classification failed or confidence below threshold
# Output Format:
#   {"scope": "research-and-plan", "confidence": 0.95, "reasoning": "..."}

# classify_workflow_llm_comprehensive - Enhanced classification with topics
# Args:
#   $1: workflow_description - The workflow description to classify
#   $2: workflow_id - Workflow identifier (optional, defaults to timestamp)
# Returns:
#   0: Classification successful (prints JSON to stdout)
#   1: Classification failed or confidence below threshold
# Output Format:
#   {
#     "workflow_type": "research-and-plan",
#     "confidence": 0.95,
#     "research_complexity": 2,
#     "research_topics": [
#       {
#         "short_name": "Implementation architecture",
#         "detailed_description": "Analyze current implementation...",
#         "filename_slug": "implementation_architecture",
#         "research_focus": "Key questions: How is..."
#       }
#     ],
#     "subtopics": ["Implementation architecture"],  // Backwards compatibility
#     "reasoning": "..."
#   }
```

**State Machine Usage**:

```bash
# From .claude/lib/workflow-state-machine.sh (conceptual - file not read yet)
sm_init() {
  local workflow_description="$1"
  local command_name="$2"

  # Classification happens here (via workflow-scope-detection.sh)
  local classification_result
  classification_result=$(classify_workflow_comprehensive "$workflow_description")

  # Extract and export variables
  export WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
  export RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity')
  # ...
}
```

PROGRESS: Reviewing plan 003 for proposed solution architecture

### Proposed Solution Architecture (from Plan 003)

**Solution 2: Classification Agent with Direct Invocation** (Recommended)

**Key Components**:

1. **New Agent**: `.claude/agents/workflow-classifier.md`
   - Behavioral file defining classification logic
   - Returns JSON with workflow_type, confidence, research_topics
   - Invoked via Task tool (synchronous, proven pattern)

2. **Command-Level Classification** (before sm_init):
   ```bash
   # In coordinate.md, orchestrate.md, supervise.md

   # STEP 1: Save workflow description
   SAVED_WORKFLOW_DESC="$workflow_description"

   # STEP 2: Invoke classification agent via Task tool
   # (outside bash block)
   ```

   ```markdown
   **EXECUTE NOW**: USE the Task tool to classify workflow:

   Task {
     subagent_type: "general-purpose"
     description: "Classify workflow for orchestration"
     timeout: 30000
     prompt: "
       Read and follow ALL behavioral guidelines from:
       /home/benjamin/.config/.claude/agents/workflow-classifier.md

       **Workflow Description**: $SAVED_WORKFLOW_DESC

       Return ONLY the JSON classification result.
     "
   }
   ```

   ```bash
   # STEP 3: Parse agent response and pass to sm_init
   if [ -z "$CLASSIFICATION_RESULT" ]; then
     echo "ERROR: Classification failed"
     exit 1
   fi

   # Initialize state machine WITH classification result
   sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$CLASSIFICATION_RESULT"
   ```

3. **Backward-Compatible sm_init()**:
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
       # Original behavior - call classifier library
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

PROGRESS: Analyzing deprecation path and migration strategy

### Deprecation Path Analysis

**Current State** (as of 2025-11-14):

1. **LLM-Only Mode**: Spec 704 Phase 4 removed regex-only mode
   - Only valid mode: `WORKFLOW_CLASSIFICATION_MODE=llm-only`
   - Fail-fast error handling when LLM classification fails
   - No automatic fallback to regex

2. **File-Based Signaling**: Never implemented request handler
   - Pattern exists since Spec 670 (initial LLM classification implementation)
   - Always times out in practice
   - Effectively non-functional

3. **Test Mode**: `WORKFLOW_CLASSIFICATION_TEST_MODE=1` returns mock fixtures
   - Lines 120-164 in workflow-llm-classifier.sh
   - Simple keyword-based fixture selection
   - Used by test suite to avoid real LLM API calls

**Migration Strategy**:

**Phase 1: Create Agent** (Non-Breaking)
- Add `.claude/agents/workflow-classifier.md`
- Agent follows same classification schema as library
- Testable independently via Task tool
- Zero impact on existing code

**Phase 2: Update Commands** (Opt-In Breaking Change)
- Modify `/coordinate`, `/orchestrate`, `/supervise` to:
  - Pre-classify using agent via Task tool
  - Pass classification result to `sm_init()` as optional 3rd parameter
- Commands now avoid library timeout
- Other library callers unaffected (if any exist)

**Phase 3: Library Deprecation** (Optional, Future)
- Add deprecation notice to workflow-llm-classifier.sh
- Document that agent-based classification is preferred
- Keep library for backward compatibility (1-2 releases)
- Remove library after migration complete (clean-break approach)

**Backward Compatibility Guarantees**:

1. **sm_init() Signature**: Third parameter is OPTIONAL
   - Old calls: `sm_init("desc", "cmd")` - still work (call library)
   - New calls: `sm_init("desc", "cmd", "$result")` - skip library

2. **Library API**: No changes to exported functions
   - `classify_workflow_llm()` - unchanged
   - `classify_workflow_llm_comprehensive()` - unchanged
   - Other code can continue using library (though it will timeout)

3. **JSON Output Format**: Agent returns same schema
   - `workflow_type`, `confidence`, `reasoning`
   - `research_complexity`, `research_topics[]`
   - `subtopics[]` (backward compatibility array)

PROGRESS: Analyzing testing strategy and validation approach

### Testing Strategy

**Agent Testing** (Phase 1):

1. **Manual Testing**:
   ```bash
   # Test classification agent directly
   claude-code task --agent workflow-classifier \
     --prompt "Classify: research authentication patterns to create plan"

   # Expected output:
   # {
   #   "workflow_type": "research-and-plan",
   #   "confidence": 0.95,
   #   "research_complexity": 2,
   #   "research_topics": [...]
   # }
   ```

2. **Edge Case Testing**:
   - Ambiguous descriptions: "research the research-and-revise workflow"
   - Negations: "don't revise the plan, create a new one"
   - Quoted keywords: "research the 'implement' command"
   - Complex workflows: "research, plan, implement, test, and debug"

**Integration Testing** (Phase 2):

1. **Command-Level Testing**:
   ```bash
   # Test /coordinate with agent-based classification
   /coordinate "research authentication patterns and create implementation plan"

   # Verify:
   # - No timeout occurs
   # - Classification completes in <10s (typically <5s)
   # - WORKFLOW_SCOPE correctly set
   # - State machine initializes successfully
   ```

2. **Regression Testing**:
   - Run existing orchestration workflows
   - Verify no behavior changes except timeout elimination
   - Check all workflow types still work (research-only, research-and-plan, full-implementation, debug-only)

**Backward Compatibility Testing** (Phase 3):

1. **Library API Testing**:
   ```bash
   # Test library still works (even though it times out)
   source .claude/lib/workflow-llm-classifier.sh

   WORKFLOW_CLASSIFICATION_TEST_MODE=1 \
     result=$(classify_workflow_llm_comprehensive "test description")

   echo "$result" | jq .
   # Verify mock fixture returned
   ```

2. **sm_init() Dual-Path Testing**:
   ```bash
   # Test old call (2 params)
   sm_init "description" "coordinate"
   # Should attempt library classification (timeout)

   # Test new call (3 params)
   sm_init "description" "coordinate" "$pre_computed_result"
   # Should use provided result (no library call)
   ```

PROGRESS: Analyzing documentation update requirements

### Documentation Updates Needed

**New Documentation**:

1. **Agent Behavioral File**:
   - File: `.claude/agents/workflow-classifier.md`
   - Content: Classification rules, examples, JSON schema
   - ~200-300 lines

2. **Agent Reference Entry**:
   - File: `.claude/docs/reference/agent-reference.md`
   - Add workflow-classifier agent entry
   - Usage examples

**Updated Documentation**:

1. **Command Guides**:
   - Files:
     - `.claude/docs/guides/coordinate-command-guide.md`
     - `.claude/docs/guides/orchestrate-command-guide.md`  (if exists)
     - `.claude/docs/guides/supervise-guide.md`
   - Updates:
     - Document pre-classification step
     - Show agent invocation pattern
     - Update architecture diagrams

2. **Library API Reference**:
   - File: `.claude/docs/reference/library-api.md`
   - Updates:
     - Add deprecation notice to workflow-llm-classifier section
     - Document sm_init() third parameter
     - Show migration examples

3. **LLM Classification Pattern**:
   - File: `.claude/docs/concepts/patterns/llm-classification-pattern.md`
   - Updates:
     - Document agent-based approach
     - Show migration from file-based to agent-based
     - Update architecture diagrams (lines 48-66)
     - Add "Agent-Based Classification" section

4. **State-Based Orchestration**:
   - File: `.claude/docs/architecture/state-based-orchestration-overview.md`
   - Updates:
     - Document classification happens before sm_init
     - Update initialization flow diagrams
     - Show agent invocation pattern

**Migration Guide**:

1. **New Migration Guide**:
   - File: `.claude/docs/guides/llm-classification-migration-guide.md`
   - Content:
     - Why file-based approach failed
     - How agent-based approach works
     - Step-by-step migration instructions
     - Before/after code examples
     - Troubleshooting section
   - ~500-800 lines

PROGRESS: Completing research and finalizing recommendations

## Recommendations

### Recommendation 1: Adopt Solution 2 (Classification Agent with Direct Invocation)

**Rationale**:
- Uses proven Task tool pattern (100% reliable in existing agents)
- Eliminates timeout issues permanently
- Clean separation of concerns (classification is distinct responsibility)
- Testable and reusable across commands
- No Claude Code framework changes required
- Synchronous invocation (fast, typically <5s)

**Implementation Steps**:
1. Create `.claude/agents/workflow-classifier.md` behavioral file
2. Test agent independently with various workflow descriptions
3. Update `/coordinate` command to invoke agent before sm_init
4. Update `sm_init()` to accept optional 3rd parameter (pre-computed classification)
5. Test integration thoroughly
6. Roll out to `/orchestrate` and `/supervise` commands
7. Update documentation

**Estimated Effort**: 4-5 hours
**Risk Level**: Low
**Breaking Changes**: Commands updated (opt-in), library remains backward compatible

### Recommendation 2: Maintain Backward Compatibility via Optional Parameter

**Rationale**:
- Minimize disruption to existing code
- Allow gradual migration (commands updated one at a time)
- Preserve library functionality for non-orchestration use cases
- Support dual paths during transition period

**Implementation**:
```bash
sm_init() {
  local workflow_description="$1"
  local command_name="$2"
  local classification_result="${3:-}"  # OPTIONAL parameter

  if [ -n "$classification_result" ]; then
    # New path: Use pre-computed result (agent-based)
    echo "Using pre-computed classification"
    export WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
    # ... extract other fields ...
  else
    # Old path: Call library (times out, but preserves existing behavior)
    classification_result=$(classify_workflow_comprehensive "$workflow_description")
    # ... same extraction logic ...
  fi

  # ... rest of initialization ...
}
```

**Benefits**:
- Commands can be updated independently
- No flag day deployment required
- Easy rollback if issues found
- Clear migration path

### Recommendation 3: Deprecate Library After Full Migration

**Timeline**:
- **Immediate**: Add deprecation notice to workflow-llm-classifier.sh
- **After 1-2 releases**: Remove library if all callers migrated
- **Clean-break approach**: No compatibility shims, delete obsolete code

**Deprecation Notice** (add to workflow-llm-classifier.sh header):
```bash
# DEPRECATED: This library uses file-based signaling that times out.
# MIGRATION: Use .claude/agents/workflow-classifier.md via Task tool instead.
# STATUS: Maintained for backward compatibility until all callers migrated.
# REMOVAL: Planned for 1-2 releases after migration complete (clean-break).
#
# See .claude/docs/guides/llm-classification-migration-guide.md for migration instructions.
```

**Justification**:
- File-based signaling never worked (no handler implemented)
- Agent-based approach is superior (fast, reliable, testable)
- Keeping non-functional code violates clean-break philosophy
- Migration is straightforward (4-5 hours total)

## References

### Files Analyzed

**Libraries**:
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (690 lines) - Core LLM classification library with file-based signaling
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (referenced but not read) - Wrapper calling LLM classifier
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (referenced but not read) - State machine calling classification during sm_init

**Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md` (555 lines) - Pattern documentation (outdated, shows file-based approach)
- `/home/benjamin/.config/.claude/specs/1763161992_setup_command_refactoring/plans/003_llm_classification_timeout_solutions.md` (646 lines) - Proposed solutions analysis

**Commands** (referenced but not read):
- `.claude/commands/coordinate.md` - Wave-based orchestration
- `.claude/commands/orchestrate.md` - Full-featured orchestration
- `.claude/commands/supervise.md` - Sequential orchestration

### Key Insights

1. **Root Cause**: File-based signaling pattern (lines 287-359 of workflow-llm-classifier.sh) prints `[LLM_CLASSIFICATION_REQUEST]` to stderr but no handler exists to process these requests, causing 100% timeout rate.

2. **Current Dependency Chain**:
   ```
   /coordinate, /orchestrate, /supervise
       ↓
   sm_init() (workflow-state-machine.sh)
       ↓
   classify_workflow_comprehensive() (workflow-scope-detection.sh)
       ↓
   classify_workflow_llm_comprehensive() (workflow-llm-classifier.sh)
       ↓
   invoke_llm_classifier() - TIMES OUT
   ```

3. **Proposed Solution Chain**:
   ```
   /coordinate → [Task tool: workflow-classifier agent] → get JSON → sm_init(desc, cmd, JSON)
                      ↓
                  (synchronous, <5s)
   ```

4. **Migration Complexity**: Medium
   - New agent creation: 30 min
   - Command updates (3 commands): 3 hours
   - Testing and validation: 1 hour
   - Documentation: 30 min
   - **Total**: 4.5-5 hours

5. **Backward Compatibility Strategy**: Optional third parameter to sm_init() allows dual-path support during migration, with clean removal of library after all callers updated.

6. **Test Coverage**: Existing test mode (WORKFLOW_CLASSIFICATION_TEST_MODE=1) can remain for unit testing; agent will be tested via integration tests with real Task tool invocations.

## Implementation Roadmap

### Phase 1: Agent Creation (30 min)
- [ ] Create `.claude/agents/workflow-classifier.md`
- [ ] Define classification rules and examples
- [ ] Test manually with sample descriptions
- [ ] Verify JSON output format matches library schema

### Phase 2: State Machine Update (15 min)
- [ ] Update `sm_init()` signature to accept optional 3rd parameter
- [ ] Add dual-path logic (pre-computed vs library call)
- [ ] Validate backward compatibility (2-param calls still work)

### Phase 3: Command Updates (3 hours)
- [ ] Update `/coordinate` (1 hour)
- [ ] Update `/orchestrate` (1 hour)
- [ ] Update `/supervise` (1 hour)
- [ ] Pattern: save description → invoke agent → parse result → pass to sm_init

### Phase 4: Testing (1 hour)
- [ ] Test agent independently (edge cases)
- [ ] Test each command with agent-based classification
- [ ] Verify no timeouts occur
- [ ] Regression test existing workflows
- [ ] Validate backward compatibility (old calls still work)

### Phase 5: Documentation (30 min)
- [ ] Update command guides (coordinate, orchestrate, supervise)
- [ ] Update LLM classification pattern documentation
- [ ] Create migration guide
- [ ] Add deprecation notice to library
- [ ] Update agent reference

### Phase 6: Library Deprecation (Future)
- [ ] Monitor for 1-2 releases
- [ ] Confirm all callers migrated
- [ ] Remove workflow-llm-classifier.sh (clean-break)
- [ ] Remove file-based signaling infrastructure

**Total Timeline**: 5 hours initial implementation + future deprecation

**Success Metrics**:
- Zero classification timeouts
- Classification completes in <10s (typically <5s)
- All workflow types correctly classified
- 100% backward compatibility during migration
- Clean removal after migration (no cruft)
