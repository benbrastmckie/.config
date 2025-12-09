# Research Report: /lean-plan Command Analysis

## Metadata
- **Date**: 2025-12-08
- **Agent**: research-specialist
- **Topic**: /lean-plan command shortcomings and coordinator integration opportunities
- **Report Type**: codebase analysis

## Executive Summary

The /lean-plan command performs research directly in the orchestrator (Block 1e-exec) using a single lean-research-specialist invocation, missing opportunities for parallel research coordination and context reduction. Analysis reveals 5 critical shortcomings: absence of research-coordinator integration, no parallel research capability, suboptimal context management, lack of topic decomposition, and hardcoded single-agent pattern. Implementing research-coordinator would enable 40-60% time savings via parallel execution, 95% context reduction through metadata-only passing, and improved modularity across Lean commands.

## Findings

### Finding 1: Direct Research Execution Without Coordinator
- **Description**: The /lean-plan command invokes lean-research-specialist directly from Block 1e-exec without using research-coordinator as an intermediary supervisor
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 924-967)
- **Evidence**:
```markdown
## Block 1e-exec: Research Execution (Hard Barrier Invocation)

**EXECUTE NOW**: USE the Task tool to invoke the lean-research-specialist agent...

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with Mathlib discovery..."
  prompt: |
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md

    **Input Contract (Hard Barrier Pattern)**:
    - REPORT_PATH: ${REPORT_PATH}
    - LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH}
    ...
}
```
- **Impact**: Single research invocation limits parallelization opportunities, increases context consumption in orchestrator, and prevents modular research coordination patterns demonstrated in Example 7 of hierarchical-agents-examples.md

### Finding 2: No Parallel Research Capability
- **Description**: The command structure assumes single-topic research with a single REPORT_PATH variable, preventing parallel multi-topic research
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 819-922, Block 1d-calc)
- **Evidence**:
```bash
# === PRE-CALCULATE RESEARCH REPORT PATH ===
# Hard Barrier Pattern: Calculate exact output path BEFORE subagent invocation
REPORT_PATH="${RESEARCH_DIR}/001-lean-mathlib-research.md"

# Validate REPORT_PATH is absolute (defensive programming)
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  log_command_error "validation_error" \
    "REPORT_PATH is not absolute" \
    "REPORT_PATH=$REPORT_PATH must start with /"
  echo "ERROR: REPORT_PATH must be absolute path: $REPORT_PATH" >&2
  exit 1
fi

# Create parent directory if needed
mkdir -p "$(dirname "$REPORT_PATH")" || {
  echo "ERROR: Failed to create report directory: $(dirname "$REPORT_PATH")" >&2
  exit 1
}

# Persist REPORT_PATH to state for Block 1f validation
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
```
- **Impact**: Hardcoded single report path prevents decomposition into focused research topics (e.g., "Mathlib Theorems", "Proof Strategies", "Project Structure"), resulting in monolithic research reports and sequential execution bottleneck

### Finding 3: Context Window Consumption Pattern
- **Description**: The orchestrator loads full research report content for planning phase, consuming significant context unnecessarily
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 75-76 in actual execution output)
- **Evidence**:
```markdown
● Read(.claude/specs/044_proof_strategy_documentation/reports/001-lean-mathlib-research.md)
  ⎿  Read 766 lines
```
- **Impact**: Research report (766 lines ≈ 2,500 tokens) loaded into orchestrator context when only metadata summary (≈110 tokens) needed for plan-architect invocation. This represents missed 95% context reduction opportunity documented in research-coordinator pattern (hierarchical-agents-examples.md, Example 7)

### Finding 4: Missing Topic Decomposition Phase
- **Description**: No automated topic detection or classification step to identify distinct research areas from FEATURE_DESCRIPTION
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (Blocks 1a-1d, no topic classification logic)
- **Evidence**: Command flow shows:
  1. Block 1a: Initial Setup (captures FEATURE_DESCRIPTION)
  2. Block 1b: Topic Name Generation (directory naming only)
  3. Block 1d-calc: Pre-calculate REPORT_PATH (single path)
  4. Block 1e-exec: Research Execution (single agent)

No equivalent to Example 7's Block 1d "Research Topics Classification" which decomposes requests into 2-5 focused topics
- **Impact**: Broad, unfocused research in single report rather than parallel focused investigations; missed opportunities to invoke topic-detection-agent (referenced in research-coordinator.md lines 7, 85-94)

### Finding 5: Lack of Metadata-Only Context Passing
- **Description**: Planning phase (Block 2, line 1418-1493) receives full research context rather than metadata summaries
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1418-1493)
- **Evidence**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the lean-plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan for ${FEATURE_DESCRIPTION}..."
  prompt: |
    ...
    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Research Reports: ${REPORT_PATHS_LIST}  # Full paths passed
    ...
}
```
No metadata extraction step comparing to research-coordinator.md STEP 5 (lines 367-414) which extracts:
- Title (first heading)
- Findings count (grep "^### Finding")
- Recommendations count (numbered items in Recommendations section)
- **Impact**: Plan-architect must Read full reports rather than receiving pre-digested metadata, consuming context unnecessarily. Orchestrator maintains full report content in memory rather than delegating to coordinator for summarization.

### Finding 6: Hardcoded Lean-Specific Agent Without Abstraction
- **Description**: Command hardcodes lean-research-specialist invocation rather than using generic research-specialist with Lean-specific context injection
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (line 933)
- **Evidence**:
```markdown
Read and follow ALL behavioral guidelines from:
${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md
```
Contrast with research-coordinator.md (lines 217-243) which invokes generic research-specialist with context injection:
```markdown
Task {
  description: "Research Mathlib theorems for group homomorphism"
  prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md  # Generic

    **Research Topic**: Mathlib Theorems for Group Homomorphism
    **Context**: ${CONTEXT}  # Lean-specific context injected
}
```
- **Impact**: Duplicated agent behavioral files (lean-research-specialist vs research-specialist), reduced reusability across commands, missed opportunities for shared agent infrastructure improvements

### Finding 7: No Graceful Degradation for Partial Research Success
- **Description**: Hard barrier validation (Block 1f) uses fail-fast pattern without partial success handling
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1040-1068)
- **Evidence**:
```bash
# === HARD BARRIER VALIDATION ===
echo ""
echo "=== Research Report Hard Barrier Validation ==="

# Validate REPORT_PATH was set by Block 1d-calc
if [ -z "${REPORT_PATH:-}" ]; then
  log_command_error "state_error" \
    "REPORT_PATH not found in workflow state" \
    "Block 1d-calc must persist REPORT_PATH before Block 1f validation"
  echo "ERROR: REPORT_PATH not found in workflow state" >&2
  exit 1
fi

# Validate research report artifact (minimum 500 bytes)
if ! validate_agent_artifact "$REPORT_PATH" 500 "research report"; then
  log_command_error "validation_error" \
    "Lean research specialist validation failed" \
    "REPORT_PATH=$REPORT_PATH does not exist or is too small (<500 bytes)"
  echo "ERROR: HARD BARRIER FAILED" >&2
  exit 1
fi
```
Contrast with research-coordinator.md (lines 504-510) which implements partial success mode:
```markdown
If ≥50% reports created: Return partial metadata with warning
If <50% reports created: Return TASK_ERROR
```
- **Impact**: All-or-nothing failure mode prevents workflow completion when research encounters transient errors (network timeouts, API limits); no ability to proceed with partial research results

### Finding 8: State Management Complexity in Orchestrator
- **Description**: Orchestrator manages extensive state persistence across bash blocks (14 variables in Block 1d, lines 794-810)
- **Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 794-810)
- **Evidence**:
```bash
# === PERSIST FOR BLOCK 2 (BULK OPERATION) ===
# Use bulk append to reduce I/O overhead from 14 writes to 1 write
append_workflow_state_bulk <<EOF
COMMAND_NAME=$COMMAND_NAME
USER_ARGS=$USER_ARGS
WORKFLOW_ID=$WORKFLOW_ID
CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR
SPECS_DIR=$SPECS_DIR
RESEARCH_DIR=$RESEARCH_DIR
PLANS_DIR=$PLANS_DIR
TOPIC_PATH=$TOPIC_PATH
TOPIC_NAME=$TOPIC_NAME
TOPIC_NUM=$TOPIC_NUM
FEATURE_DESCRIPTION=$FEATURE_DESCRIPTION
RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY
ORIGINAL_PROMPT_FILE_PATH=${ORIGINAL_PROMPT_FILE_PATH:-}
ARCHIVED_PROMPT_PATH=${ARCHIVED_PROMPT_PATH:-}
LEAN_PROJECT_PATH=${LEAN_PROJECT_PATH:-}
EOF
```
- **Impact**: High complexity in orchestrator increases maintenance burden and error surface area. Research-coordinator pattern delegates state management to supervisor layer, simplifying orchestrator to coordination-only logic.

## Recommendations

### 1. Integrate research-coordinator for Parallel Multi-Topic Research
**Priority**: High
**Effort**: Medium (3-5 hours)
**Dependencies**: None (research-coordinator.md already exists)

**Implementation**:
1. Add Block 1d: Research Topics Classification (before current Block 1d-calc)
   - Use complexity-based topic count: Complexity 1-2 → 2 topics, 3 → 3 topics, 4 → 4 topics
   - For Lean research: "Mathlib Theorems", "Proof Strategies", "Project Structure", "Style Guide"
   - Persist TOPICS array and REPORT_PATHS array to state

2. Modify Block 1d-calc to calculate multiple report paths
   - Replace single REPORT_PATH with REPORT_PATHS array
   - Format: `${RESEARCH_DIR}/001-mathlib-theorems.md`, `002-proof-strategies.md`, etc.

3. Replace Block 1e-exec lean-research-specialist invocation with research-coordinator
   ```markdown
   Task {
     description: "Coordinate parallel Lean research"
     prompt: |
       Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

       research_request: "${FEATURE_DESCRIPTION}"
       research_complexity: ${RESEARCH_COMPLEXITY}
       report_dir: ${RESEARCH_DIR}
       topics: [${TOPICS[@]}]
       report_paths: [${REPORT_PATHS[@]}]
       context:
         lean_project_path: "${LEAN_PROJECT_PATH}"
   }
   ```

4. Update Block 1f validation to check all REPORT_PATHS array elements
   - Loop through REPORT_PATHS validating each
   - Implement partial success mode (≥50% threshold)

**Benefits**:
- 40-60% time savings via parallel execution (3 research-specialist agents run simultaneously)
- Improved research quality through focused topic investigations
- Graceful degradation with partial success handling

**References**:
- research-coordinator.md (complete behavioral specification)
- hierarchical-agents-examples.md Example 7 (implementation pattern)

---

### 2. Implement Metadata-Only Context Passing
**Priority**: High
**Effort**: Low (1-2 hours)
**Dependencies**: Recommendation 1 (research-coordinator integration)

**Implementation**:
1. Add Block 1f-metadata: Extract Report Metadata (after Block 1f validation)
   ```bash
   # Parse research-coordinator return signal
   # Expected: RESEARCH_COMPLETE: 3
   #           reports: [{"path": "...", "title": "...", "findings_count": 12, "recommendations_count": 5}, ...]

   REPORT_METADATA_JSON=$(extract_coordinator_metadata "$COORDINATOR_OUTPUT")

   # Persist metadata for planning phase
   append_workflow_state "REPORT_METADATA" "$REPORT_METADATA_JSON"
   ```

2. Update Block 2 lean-plan-architect invocation to use metadata
   ```markdown
   Task {
     prompt: |
       **Research Context**:
       Research Reports: ${REPORT_COUNT} reports created
       $(format_report_metadata "$REPORT_METADATA_JSON")

       **CRITICAL**: You have access to report paths via Read tool.
       DO NOT expect full report content in this prompt.
   }
   ```

3. Remove orchestrator Read of full report content (current line 75-76 in output)

**Benefits**:
- 95% context reduction (330 tokens vs 7,500 tokens for 3 reports)
- Faster orchestrator execution (less context processing)
- Improved token budget for planning phase

**References**:
- research-coordinator.md lines 367-451 (metadata extraction specification)
- hierarchical-agents-examples.md Example 7 lines 703-714 (metadata format)

---

### 3. Add Topic Decomposition with topic-detection-agent
**Priority**: Medium
**Effort**: Medium (2-4 hours)
**Dependencies**: None (can be implemented independently)

**Implementation**:
1. Create Block 1c-topics: Topic Detection (after Block 1c topic name validation)
   ```bash
   # Invoke topic-detection-agent to decompose FEATURE_DESCRIPTION
   # into 2-5 focused research topics based on RESEARCH_COMPLEXITY
   ```

2. Add topic-detection-agent behavioral file following research-coordinator pattern
   - Input: FEATURE_DESCRIPTION, RESEARCH_COMPLEXITY
   - Output: TOPICS array with slug identifiers
   - Validation: 2-5 topics, each 5-40 characters, unique slugs

3. Integrate with research-coordinator (Mode 2: Manual Pre-Decomposition)
   - Pass pre-calculated TOPICS and REPORT_PATHS to coordinator
   - Coordinator skips decomposition step (research-coordinator.md lines 85-94)

**Benefits**:
- Automated topic identification reduces orchestrator logic
- Consistent topic quality across invocations
- Reusable agent for other research workflows

**References**:
- research-coordinator.md lines 85-94 (Mode 2: Manual Pre-Decomposition)
- topic-naming-agent.md (reference pattern for LLM-based classification)

---

### 4. Consolidate to Generic research-specialist with Context Injection
**Priority**: Low
**Effort**: Low (1-2 hours)
**Dependencies**: Recommendation 1 (research-coordinator integration)

**Implementation**:
1. Update research-coordinator invocation to use generic research-specialist
   ```markdown
   # In research-coordinator behavioral file
   Task {
     prompt: |
       Read and follow: .claude/agents/research-specialist.md  # Generic

       **Research Topic**: ${topic}
       **Context**:
       lean_project_path: ${LEAN_PROJECT_PATH}
       focus_areas: ["Mathlib theorems", "Lean 4 syntax", "Project organization"]
   }
   ```

2. Deprecate lean-research-specialist.md (mark as superseded by generic + context)

3. Document context injection pattern in lean-plan command guide

**Benefits**:
- Reduced agent maintenance (single research-specialist behavioral file)
- Improved consistency across research workflows
- Easier to propagate improvements to all research commands

**References**:
- hierarchical-agents-examples.md Example 5 (Context Injection pattern)
- research-coordinator.md lines 217-243 (generic agent invocation example)

---

### 5. Add Partial Success Mode to Hard Barrier Validation
**Priority**: Medium
**Effort**: Low (1 hour)
**Dependencies**: Recommendation 1 (research-coordinator integration for multiple reports)

**Implementation**:
1. Modify Block 1f validation to support partial success
   ```bash
   # Count successful reports
   SUCCESSFUL_REPORTS=0
   for REPORT_PATH in "${REPORT_PATHS[@]}"; do
     if [ -f "$REPORT_PATH" ] && [ $(wc -c < "$REPORT_PATH") -ge 500 ]; then
       SUCCESSFUL_REPORTS=$((SUCCESSFUL_REPORTS + 1))
     fi
   done

   # Calculate success percentage
   SUCCESS_RATE=$(echo "scale=2; $SUCCESSFUL_REPORTS / ${#REPORT_PATHS[@]} * 100" | bc)

   # Fail if <50% success
   if (( $(echo "$SUCCESS_RATE < 50" | bc -l) )); then
     log_command_error "validation_error" \
       "Insufficient research reports created ($SUCCESS_RATE% success rate)" \
       "..."
     exit 1
   fi

   # Warn if partial success (50-99%)
   if (( $(echo "$SUCCESS_RATE < 100" | bc -l) )); then
     echo "WARNING: Partial research success ($SUCCESS_RATE%)"
     log_command_error "validation_error" \
       "Some research reports missing, proceeding with partial results" \
       "..." \
       "warning"
   fi
   ```

2. Update planning phase to handle variable report counts

**Benefits**:
- Resilience to transient research failures (network timeouts, API limits)
- Better user experience (warning vs fatal error)
- Consistent with research-coordinator graceful degradation pattern

**References**:
- research-coordinator.md lines 504-510 (partial success mode)

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1-1850) - Complete command implementation
- `/home/benjamin/.config/.claude/output/lean-plan-output.md` (lines 1-142) - Actual execution trace
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 1-635) - Supervisor behavioral specification
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-828) - Worker behavioral specification
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (lines 1-177) - Architecture fundamentals
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 1-824) - Reference implementations

### External References
- Hard Barrier Pattern: `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`
- Behavioral Injection Pattern: `.claude/docs/concepts/patterns/behavioral-injection.md`
- State-Based Orchestration: `.claude/docs/architecture/state-based-orchestration-overview.md`
