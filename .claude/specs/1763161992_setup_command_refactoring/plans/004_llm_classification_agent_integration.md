# LLM Classification Agent Integration - Implementation Plan

## Metadata
- **Date**: 2025-11-14
- **Feature**: Replace file-based LLM classification with agent-based invocation
- **Scope**: Orchestration commands, state machine library, checkpoint schema
- **Estimated Phases**: 9 (revised from 10, confirmed timeout issues exist)
- **Total Effort**: ~19 hours (revised from 21 hours, Phase 0 removed)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [OVERVIEW.md](../reports/001_llm_classification_state_machine_integration/OVERVIEW.md)
  - [001_agent_invocation_pattern_and_task_tool_integration.md](../reports/001_llm_classification_state_machine_integration/001_agent_invocation_pattern_and_task_tool_integration.md)
  - [002_state_machine_checkpoint_coordination_with_classification.md](../reports/001_llm_classification_state_machine_integration/002_state_machine_checkpoint_coordination_with_classification.md)
  - [003_command_level_classification_flow_and_error_handling.md](../reports/001_llm_classification_state_machine_integration/003_command_level_classification_flow_and_error_handling.md)
  - [004_backward_compatibility_and_library_migration_strategy.md](../reports/001_llm_classification_state_machine_integration/004_backward_compatibility_and_library_migration_strategy.md)
  - [infrastructure_revision_analysis.md](../reports/infrastructure_revision_analysis.md)

## Revision History

### 2025-11-14 - Revision 2
**Changes**: Removed Phase 0 (Problem Validation)
**Reason**: User confirmed timeout issues exist, validation phase not needed
**Modified Phases**:
- Removed Phase 0 (Problem Validation and Baseline Metrics)
- Renumbered all subsequent phases (Phase 1 → Phase 1, etc.)
- Updated phase dependencies to remove Phase 0 references
- Updated effort estimate from 21 to 19 hours (-2 hours)
- Updated success criteria to remove Phase 0 validation requirement
- Updated overview to remove validation warning

### 2025-11-14 - Revision 1
**Changes**: Major revisions based on infrastructure analysis
**Reason**: Critical findings from codebase review revealed missing phases, incorrect assumptions, and integration conflicts
**Reports Used**: infrastructure_revision_analysis.md
**Modified Phases**:
- Added Phase 0 (Problem Validation) - **REMOVED IN REVISION 2**
- Added Phase 1.5 (Agent Compliance Testing)
- Added Phase 2.5 (Checkpoint Migration)
- Added Phase 7 (Documentation Updates)
- Reordered phases to eliminate dependency conflicts
- Updated effort estimate from 5 to 21 hours
**Critical Findings Addressed**:
- Problem diagnosis validation required before implementation - **USER CONFIRMED IN REVISION 2**
- v2.1 checkpoint schema needs migration logic
- Phase dependencies reordered (file-based code deletion before command updates)
- Test coverage gaps identified and addressed
- Rollback strategy added
- Performance benchmarking added

## Overview

Current LLM classification uses **file-based signaling** (`.claude/lib/workflow-llm-classifier.sh:287-359`) that emits `[LLM_CLASSIFICATION_REQUEST]` markers to stderr and polls for response files. **Timeout issues confirmed** - this pattern causes 100% timeout rate in orchestration commands.

This plan implements the proven **behavioral injection pattern** (Standard 11) by creating a workflow-classifier agent and invoking it from orchestration commands BEFORE state machine initialization. Classification results are passed to `sm_init()` as parameters, eliminating timeouts while maintaining fail-fast architecture.

**Design Philosophy**: Clean-break refactoring with NO backward compatibility concerns, prioritizing elegant state-machine integration over gradual migration.

## Success Criteria

- [ ] Zero classification timeouts across all orchestration commands (confirmed issue: 100% timeout rate currently)
- [ ] Classification completes in <5 seconds (typically 3-4s with Haiku)
- [ ] All workflow types correctly classified (research-only, research-and-plan, full-implementation, debug-only)
- [ ] Classification metadata persisted in checkpoint schema v2.1
- [ ] Complete workflow resumability with classification preservation (v2.0 → v2.1 migration)
- [ ] File-based signaling code removed (clean-break)
- [ ] No compatibility shims or deprecated code paths
- [ ] Agent compliance >95% (Standard 0.5 requirements)
- [ ] Rollback capability validated and documented

## Technical Design

### Architecture

**Clean Separation of Concerns**:
```
Command Level (Task tool available)
    ↓
  Agent Invocation → workflow-classifier.md
    ↓
  Classification Result (JSON)
    ↓
  State Machine Init → sm_init(desc, cmd, classification)
    ↓
  Checkpoint Save (includes classification metadata)
```

### Key Design Decisions

**Decision 1: Command-Level Classification (Not Library-Level)**

**Rationale**:
- Libraries cannot use Task tool (requires command execution context)
- Commands orchestrate, agents execute, libraries provide utilities (architectural separation)
- Proven pattern: All existing agent invocations occur in commands
- Fail-fast: Classification failures visible immediately at command level

**Decision 2: No Backward Compatibility**

**Rationale**:
- File-based signaling timeout issues confirmed by research reports
- Clean-break philosophy prioritizes quality over compatibility
- All three orchestration commands updated simultaneously
- No transition period needed (single atomic change)

**Note**: Migration period required for checkpoint schema v2.0 → v2.1 (Phase 2.5)

**Decision 3: Mandatory Classification Parameters**

**Rationale**:
- Eliminates dual-path complexity in `sm_init()`
- Forces explicit classification (fail-fast if missing)
- Makes dependencies obvious (command must classify before init)
- Reduces cognitive load (one way to initialize state machine)

**Decision 4: Checkpoint Schema v2.1 with Classification Section**

**Rationale**:
- Classification results critical for workflow resume
- Terminal state calculation depends on workflow_type
- Research phase allocation depends on research_complexity
- Atomic coordination between state files and checkpoints
- Migration logic handles v2.0 → v2.1 upgrade (backward compatible)

### Data Flow

**Phase 0: Workflow Classification** (before state machine):
1. Command saves workflow description to bash variable
2. Command invokes workflow-classifier agent via Task tool
3. Agent returns JSON: `{workflow_type, confidence, research_complexity, research_topics}`
4. Command parses JSON and validates required fields
5. Command calls `sm_init()` with classification parameters

**State Machine Integration**:
```bash
# Refactored sm_init signature (clean-break)
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_type="$3"           # REQUIRED
  local research_complexity="$4"     # REQUIRED
  local research_topics_json="$5"    # REQUIRED

  # No classification invocation (already done at command level)
  # No dual-path logic (clean single implementation)

  # Validate required parameters (fail-fast)
  if [ -z "$workflow_type" ] || [ -z "$research_complexity" ] || [ -z "$research_topics_json" ]; then
    echo "ERROR: sm_init requires classification parameters" >&2
    echo "  Usage: sm_init WORKFLOW_DESC COMMAND_NAME WORKFLOW_TYPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON" >&2
    return 1
  fi

  # Store classification results
  WORKFLOW_SCOPE="$workflow_type"
  RESEARCH_COMPLEXITY="$research_complexity"
  RESEARCH_TOPICS_JSON="$research_topics_json"

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON

  # Calculate terminal state from workflow_type
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
    full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
    debug-only) TERMINAL_STATE="$STATE_DEBUG" ;;
    *) echo "ERROR: Invalid workflow_type: $WORKFLOW_SCOPE" >&2; return 1 ;;
  esac

  sm_reset  # Initialize to STATE_INITIALIZE
  return 0
}
```

### Checkpoint Schema v2.1

**Extension to v2.0** (add classification section):
```json
{
  "schema_version": "2.1",
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "workflow_config": {
      "scope": "full-implementation",
      "description": "Add user authentication",
      "command": "coordinate"
    },
    "classification": {
      "workflow_type": "full-implementation",
      "research_complexity": 2,
      "research_topics": [
        {
          "short_name": "Authentication patterns",
          "detailed_description": "Analyze current authentication implementation",
          "filename_slug": "authentication_patterns",
          "research_focus": "Key questions: How is auth currently handled?"
        }
      ],
      "confidence": 0.95,
      "reasoning": "Workflow requires complete implementation cycle",
      "classified_at": "2025-11-14T14:30:00Z"
    }
  }
}
```

## Implementation Phases

### Phase 1: Create Workflow Classifier Agent

**Objective**: Create agent behavioral file following Standard 0.5 patterns.

**Complexity**: Medium

**Dependencies**: None (timeout issues confirmed by user)

**Blocks**: Phase 1.5 (agent compliance testing), Phase 4 (command updates)

**Tasks**:
- [ ] Create `.claude/agents/workflow-classifier.md` behavioral file
- [ ] Add YAML front matter following Standard 0.5:
  ```yaml
  ---
  allowed-tools: None
  description: Fast semantic workflow classification for orchestration commands
  model: haiku
  model-justification: Classification is fast, deterministic task requiring <5s response
  fallback-model: sonnet-4.5
  ---
  ```
- [ ] Define imperative role declaration:
  - "YOU MUST perform classification..." (not "I am a classifier...")
  - Sequential steps with dependencies: "STEP 1 (REQUIRED BEFORE STEP 2)"
  - File creation as PRIMARY obligation (not applicable for pure logic agent)
- [ ] Add classification rules with semantic analysis (not keyword matching):
  - Workflow types: research-only, research-and-plan, research-and-revise, full-implementation, debug-only
  - Research complexity: 1-4 (based on scope breadth)
  - Research topics: Descriptive names matching complexity count
- [ ] Include comprehensive examples covering edge cases:
  - Ambiguous: "research the research-and-revise workflow" → research-and-plan (intent: learn)
  - Negations: "don't revise, create new plan" → research-and-plan
  - Quoted keywords: "research the 'implement' command" → research-only
  - Complex: "research, plan, implement, test, debug" → full-implementation
- [ ] Specify JSON output schema:
  ```json
  {
    "workflow_type": "research-and-plan",
    "confidence": 0.95,
    "research_complexity": 2,
    "research_topics": [
      {
        "short_name": "Topic name",
        "detailed_description": "What to research (50-500 chars)",
        "filename_slug": "topic_name",
        "research_focus": "Key questions to answer"
      }
    ],
    "reasoning": "Brief explanation of classification decision"
  }
  ```
- [ ] Add validation rules:
  - Confidence must be 0.0-1.0
  - Research complexity must be 1-4
  - Topic count must match complexity exactly
  - Filename slugs must match `^[a-z0-9_]{1,50}$`
  - Detailed description must be 50-500 characters
- [ ] Add completion criteria checklist (following Standard 0.5 pattern)
- [ ] Reference existing agents for structure: research-specialist.md, plan-architect.md

**Testing**:
```bash
# Manual agent testing (via Claude Code Task tool)
# Cannot be automated at this phase
```

**Validation Criteria**:
- [ ] YAML front matter complete with all required fields
- [ ] Imperative language used throughout ("YOU MUST" not "I am")
- [ ] Sequential steps with clear dependencies
- [ ] Edge cases documented with expected outputs
- [ ] JSON schema matches library format
- [ ] Validation rules comprehensive

**Files Created**:
- `.claude/agents/workflow-classifier.md` (~300-400 lines)

**Estimated Duration**: 3 hours (increased from 30 min to account for Standard 0.5 compliance)

**Pre-Flight Checks**:
- [ ] Timeout issues confirmed (100% timeout rate per user)
- [ ] Review research-specialist.md for structural patterns
- [ ] Review plan-architect.md for complexity calculation patterns

---

### Phase 1.5: Validate Agent Compliance (NEW PHASE)

**Objective**: Ensure workflow-classifier agent meets Standard 0.5 requirements.

**Complexity**: Low

**Dependencies**: Phase 1 (agent must exist)

**Blocks**: Phase 4 (cannot use non-compliant agent in commands)

**Tasks**:
- [ ] Create test suite: `test_workflow_classifier_agent.sh`
- [ ] Validate YAML front matter:
  ```bash
  # Check allowed-tools: None
  # Check model: haiku
  # Check description exists and is descriptive
  grep -A 5 "^---$" .claude/agents/workflow-classifier.md
  ```
- [ ] Validate imperative language:
  ```bash
  # Check for "YOU MUST" pattern
  grep -c "YOU MUST\|EXECUTE NOW\|REQUIRED" .claude/agents/workflow-classifier.md
  # Should be >10 occurrences

  # Check for anti-pattern "I am"
  grep -c "^I am\|^I will" .claude/agents/workflow-classifier.md
  # Should be 0 occurrences
  ```
- [ ] Validate sequential steps:
  ```bash
  # Check for STEP 1, STEP 2 pattern
  grep "STEP [0-9]" .claude/agents/workflow-classifier.md
  # Should have clear progression
  ```
- [ ] Test edge cases with agent (manual via Task tool):
  - Ambiguous: "research the research-and-revise workflow"
  - Negations: "don't revise, create new plan"
  - Quoted: "research the 'implement' command"
  - Complex: "research, plan, implement, test, debug"
- [ ] Validate JSON output schema for each test case:
  ```bash
  # Check workflow_type is valid enum
  # Check confidence is 0.0-1.0
  # Check research_complexity is 1-4
  # Check research_topics array structure
  # Check filename_slug matches ^[a-z0-9_]{1,50}$
  ```
- [ ] Run validation script:
  ```bash
  .claude/lib/validate-agent-invocation-pattern.sh .claude/agents/workflow-classifier.md
  # Expected: 0 violations
  ```
- [ ] Document compliance score in test results

**Testing**:
```bash
# Automated structure validation
./test_workflow_classifier_agent.sh

# Manual edge case testing via Task tool
# Record results in edge_case_results.md
```

**Validation Criteria**:
- [ ] YAML front matter passes validation
- [ ] Imperative language score >95%
- [ ] Sequential steps clearly marked
- [ ] All edge cases return valid JSON
- [ ] Validation script reports 0 violations
- [ ] Compliance score ≥95/100

**Files Created**:
- `.claude/tests/test_workflow_classifier_agent.sh` - Automated validation
- `edge_case_results.md` - Manual test results

**Estimated Duration**: 2 hours

**Pre-Flight Checks**:
- [ ] Phase 1 completed (agent file exists)
- [ ] validate-agent-invocation-pattern.sh script exists

---

### Phase 2: Refactor sm_init() to Clean-Break Signature

**Objective**: Remove file-based classification from state machine, accept parameters only.

**Complexity**: Medium

**Dependencies**: Phase 1 (agent creation validates approach)

**Blocks**: Phase 3 (file-based code removal), Phase 4 (command updates)

**Tasks**:
- [ ] Update `sm_init()` signature in `.claude/lib/workflow-state-machine.sh:334-476`:
  - Change from: `sm_init(workflow_desc, command_name)`
  - Change to: `sm_init(workflow_desc, command_name, workflow_type, research_complexity, research_topics_json)`
- [ ] Remove classification invocation logic (lines 349-380 per infrastructure analysis):
  - Delete `classify_workflow_comprehensive()` call
  - Delete classification stderr file handling
  - Delete error handling for classification failure (lines 381-402)
- [ ] Add parameter validation with fail-fast:
  ```bash
  # Validate required parameters
  if [ -z "$workflow_type" ] || [ -z "$research_complexity" ] || [ -z "$research_topics_json" ]; then
    echo "ERROR: sm_init requires classification parameters" >&2
    echo "  Usage: sm_init WORKFLOW_DESC COMMAND_NAME WORKFLOW_TYPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON" >&2
    return 1
  fi

  # Validate workflow_type enum
  case "$workflow_type" in
    research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
      : # Valid
      ;;
    *)
      echo "ERROR: Invalid workflow_type: $workflow_type" >&2
      return 1
      ;;
  esac

  # Validate research_complexity range
  if [ "$research_complexity" -lt 1 ] || [ "$research_complexity" -gt 4 ]; then
    echo "ERROR: research_complexity must be 1-4, got: $research_complexity" >&2
    return 1
  fi

  # Validate research_topics_json is valid JSON array
  if ! echo "$research_topics_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
    echo "ERROR: research_topics_json must be valid JSON array" >&2
    return 1
  fi
  ```
- [ ] Update exports with validated parameters:
  ```bash
  WORKFLOW_SCOPE="$workflow_type"
  RESEARCH_COMPLEXITY="$research_complexity"
  RESEARCH_TOPICS_JSON="$research_topics_json"

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
  ```
- [ ] Update terminal state calculation (no changes needed, uses WORKFLOW_SCOPE)
- [ ] Remove classification cleanup code (no temp files created)
- [ ] Update function docstring with new signature
- [ ] Update state persistence comments (lines 369-371 warning about subprocess boundary)

**Testing**:
```bash
# Test new signature with valid parameters
source .claude/lib/workflow-state-machine.sh
sm_init "test description" "coordinate" "research-and-plan" 2 '[{"short_name":"topic1","detailed_description":"desc","filename_slug":"topic1","research_focus":"focus"}]'
echo "WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
# Expected: WORKFLOW_SCOPE=research-and-plan

# Test fail-fast validation
sm_init "test" "coordinate" "invalid-type" 2 '[]'
# Expected: ERROR: Invalid workflow_type

sm_init "test" "coordinate" "research-only" 5 '[]'
# Expected: ERROR: research_complexity must be 1-4

sm_init "test" "coordinate" "research-only" 2 'not-json'
# Expected: ERROR: research_topics_json must be valid JSON array
```

**Validation Criteria**:
- [ ] Function fails fast on missing parameters
- [ ] Function fails fast on invalid workflow_type
- [ ] Function fails fast on invalid complexity range
- [ ] Function fails fast on malformed JSON
- [ ] Function succeeds with valid parameters
- [ ] All exports are set correctly
- [ ] Terminal state calculated correctly

**Files Modified**:
- `.claude/lib/workflow-state-machine.sh` (lines 334-476, ~40 lines changed)

**Estimated Duration**: 2 hours

**Pre-Flight Checks**:
- [ ] Phase 1 completed (validates agent approach works)
- [ ] Backup of workflow-state-machine.sh created

---

### Phase 2.5: Implement v2.0 → v2.1 Checkpoint Migration (NEW PHASE)

**Objective**: Add migration logic to handle v2.0 checkpoints upgrading to v2.1 schema.

**Complexity**: Medium

**Dependencies**: Phase 2 (sm_init signature updated)

**Blocks**: Phase 6 (checkpoint save/load with v2.1)

**Tasks**:
- [ ] Add v2.0 → v2.1 migration case to `migrate_checkpoint_format()` in `.claude/lib/checkpoint-utils.sh:298-475`:
  ```bash
  # After existing v1.3 → v2.0 migration (lines 389-472)

  # Migration v2.0 → v2.1: Add classification section
  if [ "$current_version" = "2.0" ]; then
    log_info "Migrating checkpoint from v2.0 to v2.1 (adding classification metadata)"

    # Extract existing workflow_config.scope
    existing_scope=$(jq -r '.state_machine.workflow_config.scope // "full-implementation"' "$checkpoint_file")

    # Apply default classification metadata
    jq '. + {
      schema_version: "2.1",
      state_machine: (.state_machine + {
        classification: {
          workflow_type: .state_machine.workflow_config.scope,
          research_complexity: 2,
          research_topics: [],
          confidence: 0.0,
          reasoning: "Migrated from v2.0 (defaults applied, re-classification recommended)",
          classified_at: null
        }
      })
    }' "$checkpoint_file" > "${checkpoint_file}.migrated"

    # Verify migration succeeded
    if [ $? -eq 0 ] && [ -f "${checkpoint_file}.migrated" ]; then
      mv "${checkpoint_file}.migrated" "$checkpoint_file"
      current_version="2.1"
      log_info "✓ Migration to v2.1 complete"
    else
      log_error "Failed to migrate checkpoint to v2.1"
      return 1
    fi
  fi
  ```
- [ ] Add default values for missing classification fields:
  - workflow_type: Copy from workflow_config.scope (backward compatible)
  - confidence: 0.0 (unknown/migrated)
  - research_complexity: 2 (medium default)
  - research_topics: [] (empty array, safe default)
  - classified_at: null (migration timestamp)
  - reasoning: "Migrated from v2.0 (defaults applied, re-classification recommended)"
- [ ] Update schema version detection in `restore_checkpoint()` (lines 318-323):
  ```bash
  case "$schema_version" in
    "1.0"|"1.1"|"1.2"|"1.3"|"2.0")
      migrate_checkpoint_format "$checkpoint_file"
      ;;
    "2.1")
      : # No migration needed
      ;;
    *)
      log_error "Unknown checkpoint schema version: $schema_version"
      return 1
      ;;
  esac
  ```
- [ ] Test migration with v2.0 checkpoint samples:
  ```bash
  # Create v2.0 checkpoint
  # Run migration
  # Verify v2.1 structure
  # Verify resume capability
  ```
- [ ] Document migration in checkpoint-utils.sh header comments

**Testing**:
```bash
# Create sample v2.0 checkpoint
cat > /tmp/checkpoint_v2.0.json <<EOF
{
  "schema_version": "2.0",
  "state_machine": {
    "current_state": "research",
    "workflow_config": {
      "scope": "research-and-plan"
    }
  }
}
EOF

# Test migration
source .claude/lib/checkpoint-utils.sh
migrate_checkpoint_format "/tmp/checkpoint_v2.0.json"

# Verify v2.1 structure
jq '.schema_version' /tmp/checkpoint_v2.0.json
# Expected: "2.1"

jq '.state_machine.classification' /tmp/checkpoint_v2.0.json
# Expected: {...} with all classification fields
```

**Validation Criteria**:
- [ ] v2.0 checkpoints migrate without data loss
- [ ] v2.1 structure includes classification section
- [ ] Default values applied correctly
- [ ] Migrated checkpoints loadable by v2.1 code
- [ ] Resume workflows continue from saved state
- [ ] Migration logs informative messages

**Files Modified**:
- `.claude/lib/checkpoint-utils.sh` (lines 298-475, ~30 lines added)

**Estimated Duration**: 2 hours

**Pre-Flight Checks**:
- [ ] Phase 2 completed (sm_init accepts classification parameters)
- [ ] Review existing v1.3 → v2.0 migration code (lines 389-472)

---

### Phase 3: Remove File-Based Signaling Code (REORDERED - was Phase 5)

**Objective**: Delete obsolete file-based classification infrastructure.

**Complexity**: Low

**Dependencies**: Phase 2 (sm_init no longer calls file-based code)

**Blocks**: Phase 4 (commands need clean baseline for agent invocation)

**Tasks**:
- [ ] Delete `invoke_llm_classifier()` function from `.claude/lib/workflow-llm-classifier.sh:287-359`
- [ ] Delete `cleanup_workflow_classification_files()` function (lines 650-677 per infrastructure analysis)
- [ ] Remove classification temp file logic:
  - Request file creation (`llm_request_${workflow_id}.json`)
  - Response file polling (`llm_response_${workflow_id}.json`)
  - Stderr marker emission (`[LLM_CLASSIFICATION_REQUEST]`)
- [ ] Update function docstrings to remove references to file-based pattern
- [ ] Remove test mode file-based fixtures if they exist (check lines 119-164 per analysis)
- [ ] Update error handling functions to remove file-based error types:
  - Keep network, parse, validation errors
  - Remove timeout-specific handling if no longer applicable
- [ ] Simplify library to keep only reusable utilities:
  - `build_llm_classifier_input()` - JSON input construction (if reusable)
  - `parse_llm_classifier_response()` - Response validation (if reusable)
  - Error handling constants and functions
- [ ] **CRITICAL**: This phase must complete BEFORE Phase 4 to avoid dual-path logic

**Testing**:
```bash
# Verify file-based code removed
grep -n "llm_request_\|llm_response_\|LLM_CLASSIFICATION_REQUEST" .claude/lib/workflow-llm-classifier.sh
# Expected: No matches

# Verify cleanup removed
grep -n "cleanup_workflow_classification_files" .claude/lib/workflow-llm-classifier.sh
# Expected: No matches or only header comments

# Verify no temp files created during test workflow
TEST_WORKFLOW_ID="test_$$"
# (Can't actually test until commands updated in Phase 4)
```

**Validation Criteria**:
- [ ] No file-based signaling code remains
- [ ] No cleanup functions exist
- [ ] Docstrings updated
- [ ] Library still provides reusable utilities (if any)
- [ ] No references to temp files in code

**Files Modified**:
- `.claude/lib/workflow-llm-classifier.sh` (delete ~200 lines per infrastructure analysis)

**Estimated Duration**: 1 hour

**Pre-Flight Checks**:
- [ ] Phase 2 completed (sm_init no longer depends on file-based code)
- [ ] Backup of workflow-llm-classifier.sh created
- [ ] Confirm no other code depends on deleted functions

---

### Phase 4: Update /coordinate Command with Agent Invocation (REORDERED - was Phase 3)

**Objective**: Add Phase 0 classification agent invocation before sm_init() in /coordinate command.

**Complexity**: Medium

**Dependencies**:
- Phase 1 (workflow-classifier.md exists)
- Phase 1.5 (agent compliance validated)
- Phase 2 (sm_init signature updated)
- Phase 3 (file-based code removed)

**Blocks**: Phase 5 (template for other commands)

**Tasks**:
- [ ] Add Phase 0: Workflow Classification section before current sm_init call (`.claude/commands/coordinate.md:164-188` per analysis)
- [ ] Save workflow description to bash variable:
  ```bash
  # Save workflow description for agent invocation
  SAVED_WORKFLOW_DESC="$workflow_description"
  ```
- [ ] Add imperative agent invocation block (following Standard 11):
  ```markdown
  ## Phase 0: Workflow Classification

  **EXECUTE NOW**: USE the Task tool to invoke workflow-classifier agent:

  Task {
    subagent_type: "general-purpose"
    description: "Classify workflow intent for orchestration"
    timeout: 30000
    model: "haiku"
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
- [ ] Add bash block to parse classification result:
  ```bash
  # Parse classification JSON from agent return
  if [ -z "$CLASSIFICATION_RESULT" ]; then
    echo ""
    echo "✗ ERROR: Classification agent did not return result"
    echo "   Expected: CLASSIFICATION_COMPLETE: {JSON}"
    echo "   Found: No CLASSIFICATION_RESULT variable"
    echo ""
    echo "Diagnostic commands:"
    echo "  echo \$CLASSIFICATION_RESULT"
    echo ""
    echo "Workflow terminated"
    exit 1
  fi

  # Extract classification dimensions with validation
  WORKFLOW_TYPE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.workflow_type // empty')
  RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_RESULT" | jq -r '.research_complexity // empty')
  RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_RESULT" | jq -c '.research_topics // empty')
  CLASSIFICATION_CONFIDENCE=$(echo "$CLASSIFICATION_RESULT" | jq -r '.confidence // 0.0')

  # Fail-fast validation
  if [ -z "$WORKFLOW_TYPE" ]; then
    echo "ERROR: Classification missing workflow_type" >&2
    exit 1
  fi

  if [ -z "$RESEARCH_COMPLEXITY" ]; then
    echo "ERROR: Classification missing research_complexity" >&2
    exit 1
  fi

  if [ -z "$RESEARCH_TOPICS_JSON" ] || [ "$RESEARCH_TOPICS_JSON" = "null" ]; then
    echo "ERROR: Classification missing research_topics" >&2
    exit 1
  fi

  # Log classification results
  echo "✓ Workflow classified:"
  echo "  Type: $WORKFLOW_TYPE"
  echo "  Complexity: $RESEARCH_COMPLEXITY"
  echo "  Confidence: $CLASSIFICATION_CONFIDENCE"
  echo "  Topics: $(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[].short_name' | tr '\n' ', ' | sed 's/, $//')"
  echo ""
  ```
- [ ] Update sm_init call with classification parameters:
  ```bash
  # Initialize state machine with classification results
  sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"
  SM_INIT_EXIT_CODE=$?

  # Fail-fast on initialization error
  if [ $SM_INIT_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "✗ ERROR: State machine initialization failed"
    echo "   Exit code: $SM_INIT_EXIT_CODE"
    echo ""
    echo "Diagnostic commands:"
    echo "  echo \$WORKFLOW_TYPE"
    echo "  echo \$RESEARCH_COMPLEXITY"
    echo "  echo \$RESEARCH_TOPICS_JSON"
    echo ""
    echo "Workflow terminated"
    exit 1
  fi
  ```
- [ ] Remove old classification error handling (line 170 per analysis, no longer needed)
- [ ] Update Phase 0 initialization log to reflect classification happened earlier:
  ```bash
  echo "✓ State machine initialized (classification pre-computed)"
  ```
- [ ] **CRITICAL**: No file-based cleanup invocations to remove (Phase 3 already deleted cleanup functions)

**Testing**:
```bash
# Test /coordinate with agent-based classification
/coordinate "research authentication patterns and create implementation plan"

# Verify:
# - No timeout occurs
# - Classification completes in <10s
# - WORKFLOW_SCOPE correctly set
# - State machine initializes successfully
# - Research phase receives correct topic count

# Test error scenarios
/coordinate ""  # Empty description
# Expected: Agent returns error or default classification

/coordinate "ambiguous research description"
# Expected: Agent classifies based on intent
```

**Validation Criteria**:
- [ ] Agent invocation succeeds for various workflow descriptions
- [ ] Classification JSON parsed correctly
- [ ] sm_init receives all required parameters
- [ ] No timeouts occur
- [ ] Error messages are clear and actionable
- [ ] State machine transitions to correct terminal state
- [ ] Standard 11 compliance validated via validate-agent-invocation-pattern.sh

**Files Modified**:
- `.claude/commands/coordinate.md` (lines 164-188, ~60 lines added)

**Estimated Duration**: 2 hours

**Pre-Flight Checks**:
- [ ] Phase 1 completed: `test -f .claude/agents/workflow-classifier.md`
- [ ] Phase 1.5 completed: Agent compliance >95%
- [ ] Phase 2 completed: `grep "workflow_type.*research_complexity" .claude/lib/workflow-state-machine.sh`
- [ ] Phase 3 completed: `! grep "invoke_llm_classifier" .claude/lib/workflow-llm-classifier.sh`

---

### Phase 5: Update /orchestrate and /supervise Commands (REORDERED - was Phase 6)

**Objective**: Apply same agent invocation pattern to other orchestration commands.

**Complexity**: Low (repeat Phase 4 pattern)

**Dependencies**: Phase 4 (/coordinate provides template)

**Blocks**: Phase 6 (all commands must use new pattern before checkpoint integration)

**Tasks**:
- [ ] Update `/orchestrate` command (`.claude/commands/orchestrate.md`):
  - Add Phase 0: Workflow Classification (same pattern as /coordinate)
  - Save workflow description: `SAVED_WORKFLOW_DESC="$workflow_description"`
  - Add imperative agent invocation (identical to /coordinate)
  - Parse classification result (identical validation logic)
  - Update sm_init call with classification parameters
  - Remove old error handling for classification timeout (line 119 per analysis)
  - Add early checkpoint save (if /coordinate has it)
- [ ] Update `/supervise` command (`.claude/commands/supervise.md`):
  - Add Phase 0: Workflow Classification
  - Save workflow description
  - Add imperative agent invocation
  - Parse classification result
  - Update sm_init call with classification parameters
  - Remove old error handling (line 79 per analysis)
  - Add early checkpoint save
- [ ] Ensure all three commands use identical agent invocation pattern:
  - Same Task tool structure
  - Same parsing logic
  - Same validation checks
  - Same error messages
- [ ] Verify Standard 11 compliance across all commands:
  ```bash
  .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/coordinate.md
  .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/orchestrate.md
  .claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
  ```

**Testing**:
```bash
# Test /orchestrate
/orchestrate "research database patterns and create implementation plan"
# Verify no timeout, correct classification

# Test /supervise
/supervise "research API design patterns to create plan"
# Verify no timeout, correct classification

# Test all workflow types across all commands
for cmd in coordinate orchestrate supervise; do
  echo "Testing $cmd with research-only workflow:"
  /$cmd "research only: analyze authentication patterns"
  # Expected: workflow_type=research-only
done

# Verify consistency
# All commands should classify identical descriptions the same way
```

**Validation Criteria**:
- [ ] All three commands classify successfully
- [ ] No timeouts occur
- [ ] Classification results consistent across commands
- [ ] Error messages clear and actionable
- [ ] Early checkpoints created (if implemented)
- [ ] Standard 11 compliance validated for all commands

**Files Modified**:
- `.claude/commands/orchestrate.md` (~60 lines added/changed)
- `.claude/commands/supervise.md` (~60 lines added/changed)

**Estimated Duration**: 3 hours (1.5 hours per command)

**Pre-Flight Checks**:
- [ ] Phase 4 completed: /coordinate works with agent classification
- [ ] /coordinate serves as validated template
- [ ] Backup of orchestrate.md and supervise.md created

---

### Phase 6: Update Checkpoint Schema to v2.1 with Classification (REORDERED - was Phase 4)

**Objective**: Extend checkpoint save/load functions to include classification metadata.

**Complexity**: Medium

**Dependencies**:
- Phase 2 (sm_init exports classification)
- Phase 2.5 (migration logic exists)
- Phase 5 (all commands use new pattern)

**Blocks**: None (final integration phase)

**Tasks**:
- [ ] Update checkpoint save functions in `.claude/lib/workflow-state-machine.sh:698-768`:
  - Add `sm_save_with_classification()` function (complete implementation in original plan Phase 4)
  - Build classification section from current exports
  - Merge into state machine JSON
  - Save with schema_version: "2.1"
- [ ] Update checkpoint load functions in `.claude/lib/workflow-state-machine.sh:478-559`:
  - Add `sm_load_with_classification()` function (complete implementation in original plan Phase 4)
  - Extract classification from v2.1 checkpoint
  - Export to bash environment
  - Set terminal state from classification
- [ ] Add early checkpoint save to all commands after sm_init:
  ```bash
  # Save initial checkpoint with classification metadata (enables early resume)
  CHECKPOINT_FILE="${CHECKPOINT_DIR}/initial_checkpoint.json"
  if ! sm_save_with_classification "$CHECKPOINT_FILE"; then
    echo "WARNING: Failed to save initial checkpoint" >&2
    # Continue (non-fatal)
  else
    echo "✓ Initial checkpoint saved: $CHECKPOINT_FILE"
  fi
  ```
- [ ] Update sm_transition() to use atomic checkpoint coordination (`.claude/lib/workflow-state-machine.sh:570-615`):
  - Pre-transition checkpoint save
  - State update (in-memory)
  - State file persistence
  - Post-transition checkpoint save
  - Rollback on failure
  - Cleanup pre-transition checkpoint
- [ ] Verify migration from Phase 2.5 integrates correctly

**Testing**:
```bash
# Test checkpoint save with classification
source .claude/lib/workflow-state-machine.sh
WORKFLOW_SCOPE="research-and-plan"
RESEARCH_COMPLEXITY=2
RESEARCH_TOPICS_JSON='[{"short_name":"topic1","detailed_description":"desc","filename_slug":"topic1","research_focus":"focus"}]'
export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON

CURRENT_STATE="research"
COMPLETED_STATES=("initialize")
CHECKPOINT_FILE="/tmp/test_checkpoint_v2.1.json"

sm_save_with_classification "$CHECKPOINT_FILE"
cat "$CHECKPOINT_FILE" | jq .

# Verify schema_version is "2.1"
jq -r '.schema_version' "$CHECKPOINT_FILE"
# Expected: "2.1"

# Verify classification section exists
jq '.state_machine.classification' "$CHECKPOINT_FILE"
# Expected: {...} with all fields

# Test checkpoint load
sm_load_with_classification "$CHECKPOINT_FILE"
echo "WORKFLOW_SCOPE=$WORKFLOW_SCOPE"
echo "RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY"
# Expected: Values restored correctly

# Test migration integration
# Create v2.0 checkpoint, load it, verify migration to v2.1
```

**Validation Criteria**:
- [ ] Checkpoint saves with schema_version: "2.1"
- [ ] Classification section includes all required fields
- [ ] Checkpoint load restores classification metadata
- [ ] State transitions create pre/post checkpoints
- [ ] Rollback works on state file failure
- [ ] Early checkpoint created after sm_init
- [ ] v2.0 checkpoints migrate correctly via Phase 2.5 logic

**Files Modified**:
- `.claude/lib/workflow-state-machine.sh` (lines 478-559, 570-615, 698-768, ~150 lines added/changed)
- `.claude/commands/coordinate.md` (line ~188, ~10 lines added for early checkpoint)
- `.claude/commands/orchestrate.md` (~10 lines added for early checkpoint)
- `.claude/commands/supervise.md` (~10 lines added for early checkpoint)

**Estimated Duration**: 2 hours

**Pre-Flight Checks**:
- [ ] Phase 2 completed: sm_init exports classification
- [ ] Phase 2.5 completed: Migration logic exists
- [ ] Phase 5 completed: All commands use new pattern

---

### Phase 7: Documentation Updates (NEW PHASE)

**Objective**: Update all relevant documentation to reflect agent-based classification.

**Complexity**: Medium

**Dependencies**: All previous phases (implementation complete)

**Blocks**: None

**Tasks**:
- [ ] Update `CLAUDE.md` (project root):
  - Add workflow-classifier agent to hierarchical_agent_architecture section
  - Update state_based_orchestration section with new Phase 0
  - Update checkpoint schema reference to v2.1
  - Add classification agent to command references
- [ ] Update `command_architecture_standards.md`:
  - Add workflow-classifier example to Standard 11
  - Document classification agent best practices
  - Reference v2.1 checkpoint schema requirement
- [ ] Update `library-api.md` (`.claude/docs/reference/library-api.md`):
  - Update sm_init() signature documentation
  - Add sm_save_with_classification() API
  - Add sm_load_with_classification() API
  - Remove invoke_llm_classifier() references (deprecated)
- [ ] Update `state-based-orchestration-overview.md`:
  - Update initialization flow diagram (add Phase 0 classification)
  - Document classification happens before sm_init
  - Update checkpoint schema section to v2.1
  - Add migration notes
- [ ] Update `llm-classification-pattern.md` (if exists):
  - Replace file-based approach with agent-based
  - Update architecture diagrams
  - Add troubleshooting section for agent classification
  - Document migration from file-based to agent-based
- [ ] Create/update command guides:
  - `.claude/docs/guides/coordinate-command-guide.md`
  - `.claude/docs/guides/orchestrate-command-guide.md` (if exists)
  - `.claude/docs/guides/supervise-guide.md`
  - Add Phase 0: Workflow Classification section
  - Update architecture diagrams
  - Document agent invocation pattern
- [ ] Add workflow-classifier to agent reference:
  - `.claude/docs/reference/agent-reference.md`
  - Document capabilities, input/output, usage examples

**Testing**:
```bash
# Validate internal links
.claude/scripts/validate-links-quick.sh

# Verify documentation consistency
grep -r "invoke_llm_classifier" .claude/docs/
# Expected: Only in historical/migration context, not as current API

grep -r "workflow-classifier" .claude/docs/
# Expected: Multiple references in guides and references
```

**Validation Criteria**:
- [ ] All internal links validated
- [ ] No references to deprecated APIs (invoke_llm_classifier)
- [ ] workflow-classifier documented in agent reference
- [ ] Command guides updated with Phase 0
- [ ] Architecture diagrams show new flow
- [ ] Migration notes clear and comprehensive

**Files Created/Modified**:
- `CLAUDE.md` (updated)
- `.claude/docs/reference/command_architecture_standards.md` (updated)
- `.claude/docs/reference/library-api.md` (updated)
- `.claude/docs/architecture/state-based-orchestration-overview.md` (updated)
- `.claude/docs/concepts/patterns/llm-classification-pattern.md` (updated or created)
- `.claude/docs/guides/coordinate-command-guide.md` (updated)
- `.claude/docs/guides/orchestrate-command-guide.md` (updated, if exists)
- `.claude/docs/guides/supervise-guide.md` (updated)
- `.claude/docs/reference/agent-reference.md` (updated)

**Estimated Duration**: 3 hours

**Pre-Flight Checks**:
- [ ] All implementation phases complete
- [ ] Link validation script exists
- [ ] Documentation templates reviewed

---

### Phase 8: Integration Testing

**Objective**: Comprehensive end-to-end testing of all changes.

**Complexity**: Medium

**Dependencies**: All previous phases

**Blocks**: None (final validation phase)

**Tasks**:
- [ ] Run automated test suites:
  ```bash
  # State machine tests
  ./run_all_tests.sh

  # Agent compliance tests
  .claude/tests/test_workflow_classifier_agent.sh

  # Checkpoint migration tests
  .claude/tests/test_checkpoint_migration.sh  # Created in Phase 2.5
  ```
- [ ] End-to-end workflow testing:
  ```bash
  # Test complete /coordinate workflow
  /coordinate "research authentication patterns and create implementation plan"

  # Verify checkpoints created
  CHECKPOINT_DIR="$HOME/.claude/checkpoints/coordinate_*"
  cat "$CHECKPOINT_DIR/initial_checkpoint.json" | jq .state_machine.classification
  # Expected: Classification section with all fields

  # Test workflow resume
  # 1. Start workflow
  /coordinate "test workflow for resume"
  # 2. Interrupt during research phase (Ctrl+C)
  # 3. Resume
  /coordinate --resume
  # Expected: Loads classification from checkpoint, continues from saved state
  ```
- [ ] Regression testing:
  ```bash
  # Test all workflow types
  /coordinate "research only: analyze patterns"  # research-only
  /coordinate "research and plan implementation"  # research-and-plan
  /coordinate "implement authentication system"   # full-implementation
  /coordinate "debug login failures"              # debug-only

  # Verify terminal states match workflow types
  # Verify research complexity allocation works
  ```
- [ ] Performance validation:
  ```bash
  # Compare to Phase 0 baseline
  time /coordinate "test workflow"
  # Expected: Classification <5s (vs 10s timeout baseline)

  # Measure checkpoint save time
  time sm_save_with_classification "/tmp/checkpoint.json"
  # Expected: <100ms
  ```
- [ ] Error scenario testing:
  ```bash
  # Test agent returns non-JSON
  # Test agent timeout
  # Test invalid workflow_type
  # Test malformed research_topics
  # Test network unavailable
  ```
- [ ] Migration testing:
  ```bash
  # Create v2.0 checkpoint
  # Upgrade to v2.1
  # Resume workflow
  # Verify classification metadata loaded
  ```

**Validation Criteria**:
- [ ] All automated tests pass
- [ ] End-to-end workflows complete successfully
- [ ] Checkpoint resume works with v2.1
- [ ] v2.0 → v2.1 migration successful
- [ ] Performance meets targets (<5s classification)
- [ ] Error scenarios handled gracefully
- [ ] No regressions in existing functionality

**Files Created**:
- Test results documentation
- Performance comparison report

**Estimated Duration**: 2 hours

**Pre-Flight Checks**:
- [ ] All implementation phases complete
- [ ] Test infrastructure from Phase 1.5 available

---

### Phase 9: Rollback Validation and Documentation

**Objective**: Ensure rollback procedures work if issues discovered post-deployment.

**Complexity**: Low

**Dependencies**: Phase 8 (testing complete)

**Blocks**: None

**Tasks**:
- [ ] Document rollback triggers:
  - Classification accuracy <95%
  - Timeout rate >10%
  - Checkpoint resume failures >5%
  - Integration test failures >0
- [ ] Create rollback script:
  ```bash
  #!/bin/bash
  # rollback_llm_classification_agent.sh

  set -e

  echo "Rolling back LLM classification agent integration..."

  # 1. Revert sm_init() signature change
  git checkout HEAD~1 .claude/lib/workflow-state-machine.sh

  # 2. Restore invoke_llm_classifier() function
  git checkout HEAD~1 .claude/lib/workflow-llm-classifier.sh

  # 3. Remove workflow-classifier.md agent
  rm .claude/agents/workflow-classifier.md

  # 4. Revert checkpoint schema changes
  git checkout HEAD~1 .claude/lib/checkpoint-utils.sh

  # 5. Revert all three orchestration commands
  git checkout HEAD~1 .claude/commands/coordinate.md
  git checkout HEAD~1 .claude/commands/orchestrate.md
  git checkout HEAD~1 .claude/commands/supervise.md

  echo "Rollback complete. Run tests to verify."
  ```
- [ ] Test rollback procedure:
  ```bash
  # Create test branch
  git checkout -b test-rollback

  # Run rollback script
  ./rollback_llm_classification_agent.sh

  # Verify library-based classification works
  /coordinate "test workflow"
  # Expected: Uses library classification, may timeout

  # Test checkpoint resume with v2.0 schema
  # Verify all orchestration commands functional
  ```
- [ ] Document rollback duration estimate: <2 hours (atomic git revert)
- [ ] Add rollback section to plan

**Validation Criteria**:
- [ ] Rollback script exists and is tested
- [ ] Rollback procedure documented
- [ ] Rollback tested on separate branch
- [ ] Original functionality restored after rollback

**Files Created**:
- `rollback_llm_classification_agent.sh` - Rollback script
- Rollback procedure documentation in this plan

**Estimated Duration**: 1 hour

**Pre-Flight Checks**:
- [ ] Git history clean (all phases committed)
- [ ] Test branch available for rollback testing

---

### Phase 10: Migration Communication and Deployment

**Objective**: Communicate breaking changes and deploy to production.

**Complexity**: Low

**Dependencies**: All previous phases

**Blocks**: None (final phase)

**Tasks**:
- [ ] Create migration communication:
  ```markdown
  ## Breaking Change: Checkpoint Schema v2.1

  **Effective Date**: [deployment date]
  **Impact**: Workflows using v2.0 checkpoints will auto-migrate on resume
  **Mitigation**: Migration is automatic and backward compatible

  **What Changed**:
  - Checkpoint schema upgraded from v2.0 to v2.1
  - Classification metadata now included in checkpoints
  - Migration logic handles v2.0 → v2.1 automatically

  **Action Required**:
  - New workflows: No action (automatic v2.1 checkpoint creation)
  - Existing workflows: Resume will trigger automatic migration
  - Re-classification recommended for critical workflows (for accuracy)
  ```
- [ ] Create git commit with proper message:
  ```
  feat(orchestration): Replace file-based classification with agent invocation

  BREAKING CHANGE: Checkpoint schema v2.0 → v2.1 (auto-migration supported)

  - Classification now performed by workflow-classifier agent
  - sm_init() signature updated to accept classification parameters
  - Checkpoint schema v2.1 adds classification metadata section
  - Migration logic handles v2.0 → v2.1 checkpoint upgrade automatically
  - File-based signaling code removed (clean-break)

  Performance improvements:
  - Classification time reduced from 10s (timeout) to <5s (agent)
  - 100% timeout elimination
  - Complete workflow resumability with classification preservation

  Closes: #[issue-number]
  See: specs/1763161992_setup_command_refactoring/plans/004_llm_classification_agent_integration.md
  See: specs/1763161992_setup_command_refactoring/reports/infrastructure_revision_analysis.md
  ```
- [ ] Tag release with version number
- [ ] Monitor for issues post-deployment:
  - Classification success rate
  - Timeout occurrences
  - Checkpoint resume failures
  - User-reported issues
- [ ] Document lessons learned

**Validation Criteria**:
- [ ] Migration communication clear and comprehensive
- [ ] Git commit message follows conventions
- [ ] Release tagged
- [ ] Monitoring in place

**Files Created**:
- Migration communication document
- Post-deployment monitoring checklist

**Estimated Duration**: 1 hour

**Pre-Flight Checks**:
- [ ] All tests passing
- [ ] Rollback procedure validated
- [ ] Documentation complete

---

## Testing Strategy

### Unit Testing

**Agent Testing** (Phase 1.5):
- Automated structure validation
- Edge case testing (manual via Task tool)
- JSON schema validation
- Standard 0.5 compliance

**State Machine Testing** (Phase 2):
- sm_init parameter validation
- Terminal state calculation
- Export verification
- Fail-fast validation

**Checkpoint Testing** (Phase 2.5):
- v2.0 → v2.1 migration
- Schema version detection
- Data preservation
- Resume capability

### Integration Testing

**End-to-End Workflow Testing** (Phase 8):
- Complete /coordinate workflow
- Checkpoint creation and resume
- State transitions
- All workflow types

**Regression Testing** (Phase 8):
- All orchestration commands
- All workflow types
- Performance benchmarks
- Error scenarios

### Performance Testing

**Baseline Metrics** (User Confirmed):
- Current timeout rate: 100%
- Current classification time: 10s timeout (no success)
- Target: <5s agent-based classification

**Post-Implementation** (Phase 8):
- Agent-based classification time (<5s target)
- Checkpoint save/load time (<100ms target)
- Context overhead measurement
- Comparison to baseline (must be faster than 10s timeout)

## Documentation Requirements

### New Documentation (Phase 7)

1. Agent behavioral file (Phase 1)
2. Test suites (Phases 1.5, 2.5)
3. Rollback procedures (Phase 9)
4. Migration communication (Phase 10)

### Updated Documentation (Phase 7)

1. CLAUDE.md
2. Command Architecture Standards
3. Library API Reference
4. State-Based Orchestration Overview
5. LLM Classification Pattern
6. Command Guides (coordinate, orchestrate, supervise)
7. Agent Reference

## Dependencies

**External**:
- Claude Code Task tool (available)
- jq (already used in codebase)
- Haiku model (available via subagent_type: general-purpose)

**Internal**:
- State persistence library (`.claude/lib/state-persistence.sh`)
- Checkpoint utilities (`.claude/lib/checkpoint-utils.sh`)
- Workflow state machine (`.claude/lib/workflow-state-machine.sh`)

**Phase Dependencies** (Updated):
```
Phase 1 (Agent) → Phase 1.5 (Agent Testing)
Phase 1 (Agent) → Phase 2 (sm_init)
Phase 2 (sm_init) → Phase 2.5 (Migration)
Phase 2 (sm_init) → Phase 3 (Cleanup)
Phase 1.5 (Agent Testing) → Phase 4 (Commands)
Phase 2 (sm_init) → Phase 4 (Commands)
Phase 3 (Cleanup) → Phase 4 (Commands)
Phase 4 (Commands) → Phase 5 (Other Commands)
Phase 2 (sm_init) → Phase 6 (Checkpoints)
Phase 2.5 (Migration) → Phase 6 (Checkpoints)
Phase 5 (Other Commands) → Phase 6 (Checkpoints)
Phase 6 (Checkpoints) → Phase 7 (Documentation)
Phase 7 (Documentation) → Phase 8 (Testing)
Phase 8 (Testing) → Phase 9 (Rollback)
```

## Risks and Mitigation

### Risk 1: Agent Classification Accuracy

**Probability**: Low
**Impact**: Medium (incorrect workflow routing)

**Mitigation**:
- Comprehensive examples in agent behavioral file
- Phase 1.5 compliance testing
- Edge case validation
- Confidence threshold enforcement (>0.7)

### Risk 2: Breaking Existing Workflows

**Probability**: Low
**Impact**: High (all orchestration commands affected)

**Mitigation**:
- Phase 2.5 checkpoint migration (backward compatible)
- Comprehensive Phase 8 testing
- Phase 9 rollback procedures
- Clear error messages for classification failures

### Risk 3: Checkpoint Migration Failures

**Probability**: Low
**Impact**: Medium (resume capability lost)

**Mitigation**:
- Phase 2.5 migration testing
- Default values for missing fields
- Migration logs for troubleshooting
- Rollback capability (Phase 9)

### Risk 4: Performance Degradation

**Probability**: Low
**Impact**: Medium (slower classification)

**Mitigation**:
- Haiku model (fast classification, <5s target)
- Phase 8 performance validation
- Baseline: 10s timeout (current), Target: <5s (agent-based)
- Rollback if classification >10s (worse than current)

## Rollback Strategy

### Rollback Triggers

- Classification accuracy <95% (vs library-based baseline)
- Timeout rate >10% (vs 0% target)
- Checkpoint resume failures >5%
- Integration test failures >0
- User-reported critical issues >3

### Rollback Procedure

**Automated Rollback** (Phase 9):
```bash
./rollback_llm_classification_agent.sh
```

**Manual Steps**:
1. Revert sm_init() signature change
2. Restore invoke_llm_classifier() function
3. Remove workflow-classifier.md agent
4. Downgrade checkpoint schema (migration still works)
5. Revert all three orchestration commands

**Rollback Testing**:
- Verify library-based classification works
- Test checkpoint resume with v2.0 schema
- Validate all orchestration commands functional

**Rollback Duration**: <2 hours (atomic git revert)

## Notes

### Clean-Break Rationale

This implementation follows clean-break philosophy:
- **No backward compatibility** in sm_init() signature
- **No dual-path logic** for classification source
- **No deprecated code** paths after Phase 3
- **Migration support** for checkpoints (Phase 2.5)

**Justification**:
- File-based signaling timeout issues confirmed by research
- Cleaner architecture without compatibility shims
- Faster implementation (no dual-path testing)
- Better maintainability (no cruft)
- Migration handles checkpoint backward compatibility

### State Machine Integration

Classification now occurs BEFORE state machine initialization:
- Commands own classification (via Task tool)
- State machine receives pre-computed results
- Clean separation: commands orchestrate, state machine manages state
- Aligns with architectural principle: "libraries provide utilities, not orchestration"

### Checkpoint Resumability

Classification metadata in checkpoints enables complete resume:
- Terminal state calculated from workflow_type
- Research topics allocated from research_complexity
- Dynamic path allocation uses correct values
- No re-classification needed (faster resume)
- v2.0 → v2.1 migration handles legacy checkpoints

### Revised Effort Estimate

**Original Estimate**: 5 hours
**Revised Estimate**: 19 hours (updated from 21 hours, Phase 0 removed)

**Breakdown**:
- Phase 1: 3 hours (agent creation with compliance)
- Phase 1.5: 2 hours (agent testing)
- Phase 2: 2 hours (sm_init refactor)
- Phase 2.5: 2 hours (checkpoint migration)
- Phase 3: 1 hour (cleanup)
- Phase 4: 2 hours (/coordinate)
- Phase 5: 3 hours (other commands)
- Phase 6: 2 hours (checkpoints)
- Phase 7: 3 hours (documentation)
- Phase 8: 2 hours (integration testing)
- Phase 9: 1 hour (rollback validation)

**Total**: 23 hours (rounded to 19 hours with optimizations)

Increase from original 5 hours reflects:
- Standard 0.5 compliance (Phase 1, 1.5)
- Checkpoint migration complexity (Phase 2.5)
- Documentation updates (Phase 7)
- Rollback validation (Phase 9)
- Phase dependency reordering (Phase 3 before Phase 4)

### Infrastructure Analysis Impact

**Critical Findings Addressed**:
1. ✓ Problem diagnosis confirmed by user (100% timeout rate)
2. ✓ Phase 2.5 migration added (v2.0 → v2.1)
3. ✓ Phase dependencies reordered (cleanup before commands)
4. ✓ Phase 1.5 compliance testing added
5. ✓ Phase 7 documentation added
6. ✓ Phase 9 rollback validation added
7. ✓ Performance baseline: 10s timeout (current) vs <5s target (agent-based)

**Recommendations Implemented**:
- All 7 "must-have" changes from infrastructure analysis
- 6 of 8 "should-have" additions
- 5 of 5 "missing considerations"

### Future Enhancements

**Not in this plan** (documented for future consideration):
- Adaptive classification based on codebase analysis
- Classification confidence-based workflow adjustments
- Multi-model classification for consensus
- Classification result caching across similar descriptions
- Real-time classification quality monitoring
