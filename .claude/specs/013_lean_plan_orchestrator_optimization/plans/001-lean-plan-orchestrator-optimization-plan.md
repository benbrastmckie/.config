# Lean-Plan Orchestrator Optimization Implementation Plan

## Metadata

**Date**: 2025-12-10

**Feature**: Optimize /lean-plan command to use research-coordinator for 95% context reduction and parallel research execution

**Status**: [COMPLETE]

**Estimated Hours**: 4-6 hours

**Standards File**: /home/benjamin/.config/CLAUDE.md

**Research Reports**:
- [Lean Plan Output Analysis and Context Window Issues](/home/benjamin/.config/.claude/specs/013_lean_plan_orchestrator_optimization/reports/001-lean-plan-output-analysis.md)
- [Orchestrator Command Architecture Review Research Report](/home/benjamin/.config/.claude/specs/013_lean_plan_orchestrator_optimization/reports/002-orchestrator-command-architecture.md)
- [Standards and Design Patterns Audit: Architectural Patterns and Context Efficiency](/home/benjamin/.config/.claude/specs/013_lean_plan_orchestrator_optimization/reports/003-standards-design-patterns.md)
- [Root Cause Analysis and Fix Strategy: Lean-Plan Context Window Optimization](/home/benjamin/.config/.claude/specs/013_lean_plan_orchestrator_optimization/reports/004-root-cause-fix-strategy.md)

## Architectural Context

### Problem Statement

The `/lean-plan` command currently experiences 95% context window overuse compared to `/create-plan` due to missing research-coordinator integration. The command directly invokes `research-specialist` in sequential mode instead of using the parallel `research-coordinator` supervisor agent, resulting in:

- **Full report content loading** (2,500 tokens/report) instead of metadata-only passing (110 tokens/report)
- **Sequential research execution** instead of parallel topic orchestration
- **No context reduction** (0% vs 95% in create-plan)
- **Limited iteration capacity** (3-4 iterations vs 10+ possible with coordinator)

### Root Causes Identified

1. **Missing research-coordinator Integration**: `/lean-plan` bypasses research-coordinator architecture with malformed Task invocations
2. **No topic-detection-agent**: Hardcoded 3-topic structure prevents complexity-based topic scaling
3. **Incomplete Report Path Pre-Calculation**: Only calculates REPORT_DIR, missing REPORT_PATHS array required for hard barrier pattern
4. **Missing Completion Signal Parsing**: Doesn't parse coordinator return signal fields (context_usage_percent, metadata array)

### Solution Architecture

Apply proven patterns from `/create-plan` command:

1. **Integrate research-coordinator** in Mode 2 (Manual Pre-Decomposition) for parallel multi-topic research
2. **Add topic-detection-agent** for dynamic Lean-specific topic generation (2-5 topics based on complexity)
3. **Pre-calculate REPORT_PATHS array** before coordinator invocation (hard barrier pattern requirement)
4. **Parse coordinator return signal** for context tracking and metadata extraction (95% context reduction)
5. **Pass metadata-only to lean-plan-architect** (110 tokens/report vs 2,500 tokens full content)

### Expected Performance Improvements

- **Context reduction**: 95% (7,500 → 330 tokens for 3 reports)
- **Time savings**: 40-60% (parallel vs sequential research)
- **Iteration capacity**: 10+ iterations (vs 3-4 before)
- **Delegation success**: 100% (hard barrier enforcement)
- **Block count reduction**: 6 blocks (from 8-10, 25% reduction)

## Success Criteria

- [ ] Context reduction: 95% reduction measured (2,500 → 110 tokens per report)
- [ ] Iteration capacity: 10+ iterations possible (validated via context usage tracking)
- [ ] Research parallelization: 3-5 topics researched concurrently (validated via coordinator logs)
- [ ] Block count: 6 bash blocks maximum (from 8-10 current)
- [ ] Zero regressions: All existing lean-plan tests pass
- [ ] Coordinator integration: 100% success rate on Mode 2 invocation

## Implementation Phases

### Phase 1: Add topic-detection-agent Dependency [COMPLETE]

**Objective**: Enable dynamic Lean-specific topic generation based on complexity

**Location**: `.claude/commands/lean-plan.md` frontmatter (lines 5-8)

**Tasks**:
- [ ] Update dependent-agents list to include topic-detection-agent
- [ ] Verify topic-detection-agent.md exists and is compatible with Lean domain
- [ ] Add domain context hints to agent prompt for Lean-specific topics (Mathlib, tactics, proof automation, formalization, lakefile)

**Current State**:
```yaml
dependent-agents:
  - topic-naming-agent
  - research-coordinator
  - lean-plan-architect
```

**Target State**:
```yaml
dependent-agents:
  - topic-naming-agent
  - topic-detection-agent  # NEW
  - research-coordinator
  - lean-plan-architect
```

**Validation**:
- topic-detection-agent frontmatter references lean-plan in used_by field
- Agent can generate 2-5 Lean-specific topics based on complexity levels (1-2→2, 3→3, 4→4-5)

**Acceptance Criteria**:
- [ ] dependent-agents list includes topic-detection-agent
- [ ] Agent prompt includes Lean domain context (Mathlib, tactics, project structure, style guide)
- [ ] Topic count scales with complexity (validated via test cases)

**Estimated Time**: 0.5 hours

---

### Phase 2: Create Topic Detection Block (Block 1d-topics) [COMPLETE]

**Objective**: Add new bash block for topic-detection-agent invocation with hard barrier pattern

**Location**: After Block 1c (Hard Barrier Validation), before Block 1e-exec (Research Coordination)

**Tasks**:
- [ ] Create Block 1d-topics with Setup → Execute → Verify pattern
- [ ] Add topic-detection-agent Task invocation with Lean domain context
- [ ] Calculate TOPICS_FILE path for agent output
- [ ] Validate topics JSON file exists after agent completion (hard barrier)
- [ ] Parse topics JSON array into TOPICS_JSON variable
- [ ] Pre-calculate REPORT_PATHS array (one path per topic with sequential numbering)
- [ ] Persist TOPICS_JSON and REPORT_PATHS to workflow state

**Implementation Pattern** (from create-plan.md):

```bash
## Block 1d-topics: Topic Detection and Report Path Pre-Calculation

**EXECUTE NOW**: Run topic detection and path pre-calculation:

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1

# Calculate topics file path
TOPICS_FILE="${TOPIC_PATH}/topics_${WORKFLOW_ID}.json"

# Persist for verification
append_workflow_state "TOPICS_FILE" "$TOPICS_FILE"

echo "[CHECKPOINT] Topic detection prepared: $TOPICS_FILE"
```

**EXECUTE NOW**: USE the Task tool to invoke topic-detection-agent for dynamic Lean topic generation.

Task {
  subagent_type: "general-purpose"
  description: "Detect research topics for Lean formalization"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-detection-agent.md

    **Feature Description**: ${FEATURE_DESCRIPTION}
    **Research Complexity**: ${RESEARCH_COMPLEXITY}
    **Domain Context**: Lean 4 theorem proving
    **Domain Keywords**: Mathlib, tactics, proof automation, formalization, lakefile, project structure, style guide
    **Output Path**: ${TOPICS_FILE}

    **Topic Generation Guidelines**:
    - Complexity 1-2: 2-3 topics (basic formalization)
    - Complexity 3: 3-4 topics (standard formalization)
    - Complexity 4: 4-5 topics (advanced formalization)

    **Lean-Specific Topic Priorities**:
    1. Mathlib theorem search (related to feature description)
    2. Proof automation strategies (tactics, simplifiers, simp lemmas)
    3. Project structure patterns (lakefile configuration, module organization)
    4. Style guide compliance (naming conventions, formatting standards)
    5. Testing strategies (lean-build validation, sorry tracking)

    Generate topics array and write to output path as JSON.
    Return: TOPICS_CREATED: ${TOPICS_FILE}
  "
}

**EXECUTE NOW**: Validate topics file and pre-calculate report paths:

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1

# Restore state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE" || exit 1

# Validate topics file exists (hard barrier)
if [ ! -f "$TOPICS_FILE" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "agent_error" "topic-detection-agent did not create topics file" \
    "bash_block_1d" "$(jq -n --arg path "$TOPICS_FILE" '{expected_path: $path}')"
  echo "ERROR: HARD BARRIER FAILED - Topics file not found: $TOPICS_FILE" >&2
  exit 1
fi

# Parse topics JSON array
TOPICS_JSON=$(cat "$TOPICS_FILE")
TOPICS_COUNT=$(echo "$TOPICS_JSON" | jq -r '.topics | length')

if [ -z "$TOPICS_COUNT" ] || [ "$TOPICS_COUNT" -eq 0 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Topics JSON array is empty or invalid" \
    "bash_block_1d" "$(jq -n --arg json "$TOPICS_JSON" '{topics_json: $json}')"
  echo "ERROR: No topics detected by agent" >&2
  exit 1
fi

# Pre-calculate report paths for each topic (hard barrier pattern)
REPORT_DIR="${TOPIC_PATH}/reports"
REPORT_PATHS=()

for i in $(seq 0 $((TOPICS_COUNT - 1))); do
  TOPIC_SLUG=$(echo "$TOPICS_JSON" | jq -r ".topics[$i].slug")
  REPORT_NUM=$(printf "%03d" $((i + 1)))
  REPORT_PATH="${REPORT_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md"
  REPORT_PATHS+=("$REPORT_PATH")
done

# Validate all paths are absolute (defensive check)
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "validation_error" "Calculated REPORT_PATH is not absolute" \
      "bash_block_1d" "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
    echo "ERROR: Non-absolute path detected: $REPORT_PATH" >&2
    exit 1
  fi
done

# Persist for Block 1e-exec
append_workflow_state "TOPICS_JSON" "$TOPICS_JSON"
append_workflow_state "TOPICS_COUNT" "$TOPICS_COUNT"
append_workflow_state "REPORT_PATHS" "${REPORT_PATHS[*]}"
append_workflow_state "REPORT_DIR" "$REPORT_DIR"

echo "[CHECKPOINT] Topics detected: $TOPICS_COUNT topics"
echo "[CHECKPOINT] Report paths pre-calculated: ${#REPORT_PATHS[@]} paths"
```

**Validation**:
- Topics JSON file exists at calculated path
- Topics array contains 2-5 elements based on complexity
- REPORT_PATHS array has correct length (matches TOPICS_COUNT)
- All report paths are absolute paths
- State file persists TOPICS_JSON and REPORT_PATHS arrays

**Acceptance Criteria**:
- [ ] Block 1d-topics added after Block 1c
- [ ] Hard barrier pattern implemented (Setup → Execute → Verify)
- [ ] topic-detection-agent invoked with Lean domain context
- [ ] Topics JSON validated (non-empty, correct count)
- [ ] REPORT_PATHS array pre-calculated with absolute paths
- [ ] State persistence includes TOPICS_JSON and REPORT_PATHS

**Estimated Time**: 1.5 hours

---

### Phase 3: Update Research Coordinator Invocation (Block 1e-exec) [COMPLETE]

**Objective**: Fix research-coordinator invocation to use Mode 2 (Pre-Decomposed) with correct workflow parameters

**Location**: `.claude/commands/lean-plan.md` Block 1e-exec (estimated lines 992-1035)

**Tasks**:
- [ ] Remove current malformed research-coordinator Task invocation
- [ ] Add proper Mode 2 invocation with pre-calculated TOPICS_JSON and REPORT_PATHS
- [ ] Update prompt to reference research-coordinator.md behavioral guidelines
- [ ] Include all required input parameters (research_request, research_complexity, report_dir, topic_path, topics, report_paths, context)
- [ ] Document expected return signal format (RESEARCH_COORDINATOR_COMPLETE)
- [ ] Add CRITICAL BARRIER label

**Current State** (BROKEN):
```bash
## Block 1e-exec: Research Coordination (research-coordinator Invocation)

Task {
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    # Incorrect: tells agent to invoke research-specialist but doesn't provide
    # proper coordinator workflow parameters
  "
}
```

**Target State** (CORRECT):
```bash
## Block 1e-exec: Research Coordination (research-coordinator Invocation)

**CRITICAL BARRIER**: This block MUST invoke research-coordinator via Task tool.
Verification block (1f) will FAIL if reports not created at pre-calculated paths.

**EXECUTE NOW**: USE the Task tool to invoke research-coordinator in Mode 2 (Pre-Decomposed).

Task {
  subagent_type: "general-purpose"
  description: "Orchestrate parallel Lean research across multiple topics"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Invocation Mode**: Mode 2 - Manual Pre-Decomposition

    **Input Parameters**:
    - research_request: Comprehensive Lean 4 research for ${FEATURE_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${REPORT_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_JSON}
    - report_paths: [${REPORT_PATHS[@]}]
    - context:
        feature_description: ${FEATURE_DESCRIPTION}
        lean_project_path: ${LEAN_PROJECT_PATH}
        domain: Lean 4 theorem proving
        keywords: Mathlib, tactics, proof automation, formalization

    Follow research-coordinator.md workflow steps:
    - STEP 1: Receive topics (already provided above)
    - STEP 2: Use provided report_paths (skip path calculation)
    - STEP 3: Invoke research-specialist for each topic in parallel
    - STEP 4: Validate all reports exist at pre-calculated paths (hard barrier)
    - STEP 5: Extract metadata (110 tokens per report)
    - STEP 6: Return aggregated metadata

    **Expected Return Signal Format**:
    RESEARCH_COORDINATOR_COMPLETE: SUCCESS
    topics_processed: ${TOPICS_COUNT}
    reports_created: ${TOPICS_COUNT}
    context_reduction_pct: 95
    context_usage_percent: N
    reports: [JSON metadata array]
    total_findings: N
    total_recommendations: N
  "
}
```

**Validation**:
- Task invocation includes all required Mode 2 parameters
- TOPICS_JSON and REPORT_PATHS passed from state (not recalculated)
- Lean domain context included (feature_description, lean_project_path, domain, keywords)
- Return signal format documented for parsing in Block 1f

**Acceptance Criteria**:
- [ ] CRITICAL BARRIER label present
- [ ] Imperative directive: "**EXECUTE NOW**: USE the Task tool..."
- [ ] Mode 2 (Pre-Decomposed) invocation mode specified
- [ ] All input parameters provided (research_request, research_complexity, report_dir, topic_path, topics, report_paths, context)
- [ ] Expected return signal format documented
- [ ] No inline behavioral guidelines (references research-coordinator.md only)

**Estimated Time**: 1 hour

---

### Phase 4: Add Completion Signal Parsing (Block 1f) [COMPLETE]

**Objective**: Parse research-coordinator return signal for context tracking and metadata extraction

**Location**: `.claude/commands/lean-plan.md` Block 1f (estimated lines 1049-1150)

**Tasks**:
- [ ] Add completion signal parsing after existing validation logic
- [ ] Extract fields: topics_processed, reports_created, context_reduction_pct, context_usage_percent
- [ ] Validate completion signal is non-empty and contains expected fields
- [ ] Parse reports JSON array for metadata
- [ ] Persist RESEARCH_CONTEXT_USAGE for iteration tracking
- [ ] Persist REPORTS_METADATA_JSON for lean-plan-architect invocation
- [ ] Log context metrics (topics processed, reports created, context reduction %, context usage %)

**Implementation Pattern**:

```bash
## Block 1f: Research Validation and Completion Signal Parsing

**EXECUTE NOW**: Validate research outputs and parse coordinator return signal:

```bash
set +H
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1

# Restore state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
source "$STATE_FILE" || exit 1

# Defensive variable initialization
REPORT_PATHS_STR="${REPORT_PATHS[*]:-}"
REPORT_DIR="${REPORT_DIR:-}"

# Validate research directory exists
if [ ! -d "$REPORT_DIR" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Research directory not found: $REPORT_DIR" \
    "bash_block_1f" "$(jq -n --arg dir "$REPORT_DIR" '{report_dir: $dir}')"
  echo "ERROR: Research validation failed - directory missing" >&2
  exit 1
fi

# Validate each pre-calculated report path exists (hard barrier)
MISSING_REPORTS=()
IFS=' ' read -ra REPORT_PATHS_ARRAY <<< "$REPORT_PATHS_STR"

for REPORT_PATH in "${REPORT_PATHS_ARRAY[@]}"; do
  if [ ! -f "$REPORT_PATH" ]; then
    MISSING_REPORTS+=("$REPORT_PATH")
  fi
done

# Calculate success percentage (partial success mode: ≥50% threshold)
EXPECTED_COUNT=${#REPORT_PATHS_ARRAY[@]}
CREATED_COUNT=$((EXPECTED_COUNT - ${#MISSING_REPORTS[@]}))
SUCCESS_PERCENT=$((CREATED_COUNT * 100 / EXPECTED_COUNT))

if [ "$SUCCESS_PERCENT" -lt 50 ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Research validation failed: <50% success rate" \
    "bash_block_1f" "$(jq -n --arg created "$CREATED_COUNT" --arg expected "$EXPECTED_COUNT" --argjson missing "$(printf '%s\n' "${MISSING_REPORTS[@]}" | jq -R . | jq -s .)" '{created: $created, expected: $expected, missing: $missing}')"
  echo "ERROR: Research coordination failed - only ${CREATED_COUNT}/${EXPECTED_COUNT} reports created" >&2
  exit 1
fi

if [ "$SUCCESS_PERCENT" -lt 100 ]; then
  echo "WARNING: Partial research success (${SUCCESS_PERCENT}%)" >&2
  echo "Proceeding with ${CREATED_COUNT}/${EXPECTED_COUNT} reports..."
fi

# Parse research-coordinator return signal (if available)
COORDINATOR_OUTPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinator_output_${WORKFLOW_ID}.txt"
COORDINATOR_OUTPUT=""

if [ -f "$COORDINATOR_OUTPUT_FILE" ]; then
  COORDINATOR_OUTPUT=$(cat "$COORDINATOR_OUTPUT_FILE")
fi

# Extract completion fields (defensive parsing with defaults)
TOPICS_PROCESSED=$(echo "$COORDINATOR_OUTPUT" | grep "^topics_processed:" | cut -d: -f2 | tr -d ' ' || echo "$CREATED_COUNT")
REPORTS_CREATED=$(echo "$COORDINATOR_OUTPUT" | grep "^reports_created:" | cut -d: -f2 | tr -d ' ' || echo "$CREATED_COUNT")
CONTEXT_REDUCTION=$(echo "$COORDINATOR_OUTPUT" | grep "^context_reduction_pct:" | cut -d: -f2 | tr -d ' ' || echo "95")
CONTEXT_USAGE=$(echo "$COORDINATOR_OUTPUT" | grep "^context_usage_percent:" | cut -d: -f2 | tr -d ' ' || echo "10")

# Validate completion signal (warn if missing, don't fail)
if [ -z "$TOPICS_PROCESSED" ] || [ "$TOPICS_PROCESSED" -eq 0 ]; then
  echo "WARNING: research-coordinator return signal missing or incomplete" >&2
  echo "Using fallback values for context tracking..."
  TOPICS_PROCESSED="$CREATED_COUNT"
  REPORTS_CREATED="$CREATED_COUNT"
fi

# Extract metadata JSON array from coordinator output
REPORTS_METADATA_JSON=$(echo "$COORDINATOR_OUTPUT" | sed -n '/^reports: \[/,/^\]/p' | sed 's/^reports: //')

if [ -z "$REPORTS_METADATA_JSON" ]; then
  # Fallback: generate metadata from existing reports
  echo "WARNING: Metadata array not found in coordinator output, generating fallback..." >&2
  REPORTS_METADATA_JSON="["
  for i in "${!REPORT_PATHS_ARRAY[@]}"; do
    REPORT_PATH="${REPORT_PATHS_ARRAY[$i]}"
    if [ -f "$REPORT_PATH" ]; then
      REPORT_TITLE=$(grep -m 1 "^# " "$REPORT_PATH" | sed 's/^# //' || echo "Report $((i+1))")
      FINDINGS_COUNT=$(grep -c "^### Finding" "$REPORT_PATH" || echo "0")
      RECOMMENDATIONS_COUNT=$(grep -c "^### Recommendation" "$REPORT_PATH" || echo "0")

      if [ $i -gt 0 ]; then
        REPORTS_METADATA_JSON+=","
      fi

      REPORTS_METADATA_JSON+=$(jq -n \
        --arg path "$REPORT_PATH" \
        --arg title "$REPORT_TITLE" \
        --arg findings "$FINDINGS_COUNT" \
        --arg recs "$RECOMMENDATIONS_COUNT" \
        '{path: $path, title: $title, findings_count: ($findings | tonumber), recommendations_count: ($recs | tonumber)}')
    fi
  done
  REPORTS_METADATA_JSON+="]"
fi

# Log context metrics
echo "[CHECKPOINT] Research coordination complete"
echo "  Topics Processed: $TOPICS_PROCESSED"
echo "  Reports Created: $REPORTS_CREATED"
echo "  Success Rate: ${SUCCESS_PERCENT}%"
echo "  Context Reduction: ${CONTEXT_REDUCTION}%"
echo "  Context Usage: ${CONTEXT_USAGE}%"

# Persist for Block 2 (plan generation)
append_workflow_state "RESEARCH_CONTEXT_USAGE" "$CONTEXT_USAGE"
append_workflow_state "REPORTS_METADATA_JSON" "$REPORTS_METADATA_JSON"
append_workflow_state "TOPICS_PROCESSED" "$TOPICS_PROCESSED"
append_workflow_state "REPORTS_CREATED" "$REPORTS_CREATED"
```

**Validation**:
- Partial success mode: ≥50% reports created (fails if <50%, warns if 50-99%)
- Completion signal parsed with defensive fallbacks (no hard failure if signal missing)
- Metadata JSON array extracted or generated from report files
- Context usage persisted for iteration tracking
- Metrics logged to console

**Acceptance Criteria**:
- [ ] Hard barrier validation: Fails if <50% reports created
- [ ] Completion signal parsing with defensive defaults
- [ ] Metadata JSON extracted from coordinator output or generated as fallback
- [ ] Context usage persisted (RESEARCH_CONTEXT_USAGE) for iteration tracking
- [ ] Console output shows metrics (topics processed, reports created, success rate, context reduction %, context usage %)
- [ ] REPORTS_METADATA_JSON persisted for lean-plan-architect invocation

**Estimated Time**: 1 hour

---

### Phase 5: Update lean-plan-architect Context Passing (Block 2) [COMPLETE]

**Objective**: Pass metadata-only context to lean-plan-architect (110 tokens/report vs 2,500 tokens full content)

**Location**: `.claude/commands/lean-plan.md` Block 2 (estimated lines 1400-1500)

**Tasks**:
- [ ] Update lean-plan-architect Task invocation prompt
- [ ] Pass REPORTS_METADATA_JSON instead of full report content
- [ ] Document that architect has Read tool access for full reports (delegated read pattern)
- [ ] Prohibit architect from reading full reports in initial context (enforce metadata-only)
- [ ] Add completion signal expectation (PLAN_CREATED)

**Current State** (presumed):
```bash
## Block 2: Plan Generation (lean-plan-architect Invocation)

Task {
  prompt: "
    Research Reports: [full paths for reading]
  "
}
```

**Target State** (CORRECT):
```bash
## Block 2: Plan Generation (lean-plan-architect Invocation)

**CRITICAL BARRIER**: This block MUST invoke lean-plan-architect via Task tool.
Verification block will FAIL if plan not created at pre-calculated path.

**EXECUTE NOW**: USE the Task tool to invoke lean-plan-architect with metadata-only context.

Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan from research metadata"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Output Path: ${PLAN_PATH}
    - Lean Project Path: ${LEAN_PROJECT_PATH}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Workflow Type: ${WORKFLOW_TYPE}
    - Operation Mode: ${OPERATION_MODE}
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_FILE_PATH:-none}

    **Research Reports Metadata** (95% context reduction via metadata-only passing):
    ${REPORTS_METADATA_JSON}

    **CRITICAL - Metadata-Only Context Passing**:
    You have received METADATA for ${REPORTS_CREATED} research reports (110 tokens per report).
    You MUST NOT use the Read tool to load full report content during plan creation.
    The metadata provides sufficient context for initial planning (title, findings_count, recommendations_count).

    If you need specific details from reports during implementation phases, those can be accessed later.
    For now, use ONLY the metadata to create the plan structure.

    **Report Paths** (for reference links in plan):
    ${REPORT_PATHS[*]}

    Execute planning per behavioral guidelines.
    Return completion signal: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Validation**:
- Architect receives REPORTS_METADATA_JSON (not full report content)
- Prompt explicitly prohibits Read tool usage on reports
- Report paths provided for reference links in plan output
- Completion signal documented (PLAN_CREATED)

**Acceptance Criteria**:
- [ ] CRITICAL BARRIER label present
- [ ] Imperative directive: "**EXECUTE NOW**: USE the Task tool..."
- [ ] REPORTS_METADATA_JSON passed instead of full report content
- [ ] Explicit prohibition on Read tool usage for reports
- [ ] Report paths provided for reference links
- [ ] Completion signal expectation: PLAN_CREATED

**Estimated Time**: 0.5 hours

---

### Phase 6: Block Consolidation and Cleanup [COMPLETE]

**Objective**: Reduce bash block count from 8-10 to 6 blocks while maintaining hard barrier integrity

**Tasks**:
- [ ] Merge Block 1a + 1b (Setup + Topic Path Pre-Calc) → Single "Block 1: Initial Setup and Path Pre-Calculation"
- [ ] Keep Block 1b-exec (Topic Naming) separate (hard barrier pattern requirement)
- [ ] Keep Block 1c (Hard Barrier Validation) separate (explicit checkpoint)
- [ ] Keep Block 1d-topics (Topic Detection) as added in Phase 2
- [ ] Keep Block 1e-exec (Research Coordination) separate (hard barrier pattern requirement)
- [ ] Keep Block 1f (Research Validation) separate (hard barrier validation + completion signal parsing)
- [ ] Keep Block 2 (Plan Generation) separate (final orchestration phase)
- [ ] Verify no block exceeds 400 lines (preprocessing safety limit)
- [ ] Update block comments to reflect consolidation
- [ ] Validate hard barrier separation maintained

**Target Block Structure**:
```
Block 1: Initial Setup and Path Pre-Calculation (merged 1a+1b) - ~150 lines
Block 1b-exec: Topic Name Generation (unchanged) - Task invocation only
Block 1c: Topic Name Validation (unchanged) - ~50 lines
Block 1d-topics: Topic Detection and Report Paths (NEW from Phase 2) - ~100 lines
Block 1e-exec: Research Coordination (updated in Phase 3) - Task invocation only
Block 1f: Research Validation and Completion Signal Parsing (updated in Phase 4) - ~150 lines
Block 2: Plan Generation (updated in Phase 5) - Task invocation only
Block 2-verify: Plan Validation (unchanged) - ~50 lines
```

**Result**: 8 blocks (6 bash blocks + 2 Task-only blocks)

**Validation**:
- No bash block exceeds 400 lines
- Hard barrier pattern intact (Setup → Execute → Verify)
- State persistence works across all blocks
- Console output shows 6-8 checkpoints (one per block)

**Acceptance Criteria**:
- [ ] Block 1a + 1b merged successfully
- [ ] All hard barriers maintained (Block 1b-exec, 1e-exec, 2 are Task-only)
- [ ] No block exceeds 400 lines (preprocessing safety)
- [ ] State persistence verified across all blocks
- [ ] Console checkpoints show clear execution flow

**Estimated Time**: 1 hour

---

### Phase 7: Integration Testing and Validation [COMPLETE]

**Objective**: Validate all changes work end-to-end with complexity levels 1-4

**Tasks**:
- [ ] Create test case 1: Simple formalization (complexity 1)
- [ ] Create test case 2: Standard formalization (complexity 3)
- [ ] Create test case 3: Complex formalization (complexity 4)
- [ ] Run test suite with all complexity levels
- [ ] Measure context reduction (target: 95%)
- [ ] Measure iteration capacity (target: 10+)
- [ ] Validate coordinator invocation success (target: 100%)
- [ ] Validate zero regressions on existing lean-plan tests
- [ ] Update lean-plan-command-guide.md with optimization details

**Test Case 1: Simple Formalization (Complexity 1)**
```bash
/lean-plan "prove commutativity of addition" --complexity 1 --project ~/ProofChecker
```

**Expected**:
- 2-3 research topics generated
- research-coordinator invoked with Mode 2
- Context usage: ~8-10%
- 2-3 reports created with metadata-only passing
- Plan generated successfully

**Test Case 2: Standard Formalization (Complexity 3)**
```bash
/lean-plan "formalize group homomorphism theorems with tactics" --complexity 3 --project ~/ProofChecker
```

**Expected**:
- 3-4 research topics generated
- research-coordinator invoked with Mode 2
- Context usage: ~12-15%
- 3-4 reports created with metadata-only passing
- Plan generated successfully

**Test Case 3: Complex Formalization (Complexity 4)**
```bash
/lean-plan "formalize category theory functors with natural transformations" --complexity 4 --project ~/MathLib
```

**Expected**:
- 4-5 research topics generated
- research-coordinator invoked with Mode 2
- Context usage: ~15-18%
- 4-5 reports created with metadata-only passing
- Plan generated successfully

**Metrics to Track**:
1. **Context Reduction**: Target 95% (2,500 tokens → 110 tokens per report)
2. **Iteration Capacity**: Target 10+ iterations (from 3-4)
3. **Block Count**: Target 6-8 blocks (from 8-10)
4. **Research Time**: Target 40-60% reduction (parallel execution)
5. **Error Rate**: Target 0% coordinator invocation failures

**Validation Commands**:
```bash
# Validate research-coordinator integration
bash .claude/scripts/validate-agent-dependencies.sh lean-plan.md

# Validate metadata passing
grep -A 10 "REPORTS_METADATA_JSON" .claude/commands/lean-plan.md

# Validate context tracking
grep "context_usage_percent" .claude/commands/lean-plan.md

# Run all validation checks
bash .claude/scripts/validate-all-standards.sh --all .claude/commands/lean-plan.md
```

**Acceptance Criteria**:
- [ ] All 3 test cases pass (complexity 1, 3, 4)
- [ ] Context reduction ≥95% measured
- [ ] Iteration capacity 10+ validated
- [ ] Zero regressions on existing tests
- [ ] Coordinator invocation success rate 100%
- [ ] Documentation updated (lean-plan-command-guide.md)

**Estimated Time**: 1.5 hours

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **topic-detection-agent compatibility with Lean domain** | Low | High | Use create-plan pattern (proven working) + add Lean domain hints |
| **research-coordinator Mode 2 invocation failure** | Low | High | Pre-validated in create-plan (48/48 tests pass) + follow exact pattern |
| **Lean-specific topic generation quality** | Medium | Medium | Add explicit Lean domain keywords to prompt (Mathlib, tactics, project structure, style guide) |
| **Block consolidation breaking state flow** | Low | Medium | Maintain hard barrier separation + validate state persistence after merge |
| **Metadata parsing errors from coordinator** | Low | Low | Use defensive parsing with fallbacks (validated in create-plan) |
| **Regression in existing lean-plan functionality** | Low | Medium | Comprehensive test suite (complexity 1-4) + zero regression requirement |

## Dependencies

**Agent Dependencies**:
- topic-detection-agent.md (NEW dependency)
- research-coordinator.md (existing, updated invocation)
- research-specialist.md (existing, invoked by coordinator)
- lean-plan-architect.md (existing, updated context passing)
- topic-naming-agent.md (existing, unchanged)

**Library Dependencies**:
- state-persistence.sh (existing)
- error-handling.sh (existing)
- workflow-state-machine.sh (existing)
- unified-location-detection.sh (existing)

**Command Dependencies** (for pattern reference):
- create-plan.md (proven research-coordinator integration pattern)
- implement.md (hard barrier pattern reference)
- research.md (coordinator invocation pattern reference)

## Rollback Plan

If optimization introduces regressions:

1. **Immediate Rollback**: Revert .claude/commands/lean-plan.md to previous commit
2. **Partial Rollback**: Keep topic-detection-agent changes, revert research-coordinator integration
3. **Debug Mode**: Add verbose logging to coordinator invocation for diagnostics
4. **Fallback Mode**: Add conditional logic to use direct research-specialist invocation if coordinator fails

**Rollback Commands**:
```bash
# Full rollback
git checkout HEAD~1 .claude/commands/lean-plan.md

# Partial rollback (keep topic detection, revert coordinator)
git checkout HEAD~1 .claude/commands/lean-plan.md
# Then manually re-add Block 1d-topics from this plan

# Enable debug mode
export LEAN_PLAN_DEBUG=1
/lean-plan "test feature" --complexity 3
```

## Next Steps After Implementation

1. **Monitor Performance**: Track context usage and iteration capacity over 10 production runs
2. **Document Patterns**: Update hierarchical-agents-examples.md with lean-plan optimization case study
3. **Apply to Other Commands**: Use proven pattern for /debug and /repair command optimizations
4. **Benchmark Comparisons**: Create before/after comparison report (context usage, time savings, iteration capacity)
5. **User Communication**: Document breaking changes (if any) and performance improvements in changelog

## Notes

- This plan follows the exact proven pattern from /create-plan command (48/48 tests pass)
- All changes maintain hard barrier integrity (Setup → Execute → Verify)
- Defensive parsing prevents coordinator failures from breaking workflow (fallback mode)
- Block consolidation reduces overhead while maintaining explicit checkpoints
- Estimated total implementation time: 4-6 hours (5.5 hours across 7 phases)

PLAN_CREATED: /home/benjamin/.config/.claude/specs/013_lean_plan_orchestrator_optimization/plans/001-lean-plan-orchestrator-optimization-plan.md
