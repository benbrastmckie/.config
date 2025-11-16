# Context Preservation and Metadata Passing Strategies Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Context preservation and metadata passing across commands
- **Report Type**: codebase analysis
- **Overview Report**: [Plan Command Refactor Research](OVERVIEW.md)
- **Related Reports**:
  - [Coordinate Command Architecture and Fragility Analysis](001_coordinate_command_architecture_and_fragility_analysis.md)
  - [Optimize-Claude Command Robustness Patterns](002_optimize_claude_command_robustness_patterns.md)
  - [Current Plan Command Implementation Review](003_current_plan_command_implementation_review.md)

## Executive Summary

Both coordinate and optimize-claude commands implement sophisticated context preservation strategies using file-based state persistence, metadata extraction, and aggressive context pruning. The coordinate command achieves 95% context reduction through hierarchical supervisor patterns, while optimize-claude uses pre-calculated artifact paths to pass minimal metadata to subagents. Key mechanisms include state-persistence.sh (GitHub Actions pattern), context-pruning.sh (95% reduction), and metadata-extraction.sh (50-word summaries).

## Findings

### 1. State Persistence Pattern (GitHub Actions Model)

**Implementation**: `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 1-393)

The coordinate command uses a GitHub Actions-inspired pattern for cross-bash-block state preservation:

**Core Functions**:
- `init_workflow_state()` - Creates state file, exports CLAUDE_PROJECT_DIR (70% performance improvement: 50ms → 15ms)
- `load_workflow_state()` - Sources state file in subsequent blocks with fail-fast validation
- `append_workflow_state()` - Appends key-value pairs following $GITHUB_OUTPUT pattern
- `save_json_checkpoint()` - Atomic writes using temp file + mv (5-10ms)
- `load_json_checkpoint()` - Loads structured metadata with graceful degradation

**Example from coordinate.md** (lines 167-184):
```bash
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
verify_state_variable "WORKFLOW_ID" || {
  handle_state_error "CRITICAL: WORKFLOW_ID not persisted to state" 1
}

append_workflow_state "WORKFLOW_DESCRIPTION" "$SAVED_WORKFLOW_DESC"
verify_state_variable "WORKFLOW_DESCRIPTION" || {
  handle_state_error "CRITICAL: WORKFLOW_DESCRIPTION not persisted to state" 1
}
```

**Key Insight**: Every critical state append is immediately verified with `verify_state_variable()` to enforce fail-fast error detection (Standard 0: Execution Enforcement).

**Performance Characteristics** (state-persistence.sh:43-47):
- CLAUDE_PROJECT_DIR detection: 50ms → 15ms (70% improvement via file caching)
- JSON checkpoint write: 5-10ms (atomic write guarantee)
- JSON checkpoint read: 2-5ms (cat + jq validation)
- Graceful degradation overhead: <1ms (file existence check)

### 2. Metadata Extraction and Reduction

**Implementation**: `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` (lines 1-655)

The optimize-claude command extracts minimal metadata from artifacts to pass to subagents:

**Metadata Functions**:
- `extract_report_metadata()` - Extracts title, 50-word summary, file paths, 3-5 recommendations (lines 13-87)
- `extract_plan_metadata()` - Extracts title, date, phase count, complexity, time estimate (lines 89-166)
- `extract_accuracy_metadata()` - Extracts error count, completeness percentage, key findings (lines 529-640)

**50-Word Summary Pattern** (metadata-extraction.sh:29-39):
```bash
# Extract 50-word summary from Executive Summary section or first paragraph
local summary=""
local exec_summary_section=$(get_report_section "$report_path" "Executive Summary" 2>/dev/null || echo "")

if [ -n "$exec_summary_section" ]; then
  # Extract first paragraph from executive summary (non-heading, non-empty lines)
  summary=$(echo "$exec_summary_section" | grep -v '^#' | grep -v '^$' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50 && i<=NF;i++) printf "%s ", $i}')
else
  # Fallback: first 50 words from content after title
  summary=$(head -200 "$report_path" | grep -v '^#' | grep -v '^-' | grep -v '^$' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50 && i<=NF;i++) printf "%s ", $i}')
fi
```

**Cache Pattern** (metadata-extraction.sh:295-315):
```bash
cache_metadata() {
  local artifact_path="${1:-}"
  local metadata_json="${2:-}"
  METADATA_CACHE["$artifact_path"]="$metadata_json"
  return 0
}

get_cached_metadata() {
  local artifact_path="${1:-}"
  echo "${METADATA_CACHE[$artifact_path]:-}"
}
```

### 3. Context Pruning (95% Reduction)

**Implementation**: `/home/benjamin/.config/.claude/lib/context-pruning.sh` (lines 1-454)

The coordinate command achieves 95% context reduction through aggressive pruning:

**Pruning Functions**:
- `prune_subagent_output()` - Clears full output, retains artifact paths + 50-word summary (lines 45-110)
- `prune_phase_metadata()` - Removes phase-specific metadata after completion (lines 138-167)
- `prune_workflow_metadata()` - Removes all workflow metadata after completion (lines 231-271)
- `apply_pruning_policy()` - Workflow-specific pruning rules (lines 384-436)

**Pruning Policy Example** (context-pruning.sh:400-416):
```bash
case "$workflow_type" in
  plan_creation)
    # After planning completes, prune research metadata (no longer needed)
    if [ "$phase_name" = "planning" ]; then
      prune_phase_metadata "research"
      echo "  Policy: Pruned research metadata after planning" >&2
    fi
    ;;

  orchestrate)
    # After implementation completes, prune research and planning metadata
    if [ "$phase_name" = "implementation" ]; then
      prune_phase_metadata "research"
      prune_phase_metadata "planning"
      echo "  Policy: Pruned research/planning metadata after implementation" >&2
    fi
    ;;
esac
```

**Context Reduction Target** (context-pruning.sh:373-374):
```bash
Target: <30% context usage
Status: $([ "$reduction" -ge 70 ] && echo "✓ Target met" || echo "⚠ Below target")
```

**Example from coordinate.md** (lines 996-998):
```bash
# metadata extraction enables context reduction by passing summaries instead of full reports
# Target: maintain <30% context usage throughout workflow
SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')
```

### 4. Subagent Communication Pattern

**optimize-claude Pattern** (optimize-claude.md:77-92):

Pre-calculated absolute paths passed to subagents:
```bash
Task {
  subagent_type: "general-purpose"
  description: "Analyze CLAUDE.md structure"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/claude-md-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_PATH: ${CLAUDE_MD_PATH}
    - REPORT_PATH: ${REPORT_PATH_1}
    - THRESHOLD: balanced

    **CRITICAL**: Create report file at EXACT path provided above.
  "
}
```

**coordinate Pattern** (coordinate.md:784-791):

Workflow-specific context passed via structured prompts:
```bash
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
  "
}
```

### 5. Verification Checkpoints

**Pattern**: Every critical operation followed by verification (Standard 0: Execution Enforcement)

**Example from coordinate.md** (lines 161-164):
```bash
# VERIFICATION CHECKPOINT: Verify state ID file created successfully
verify_file_created "$COORDINATE_STATE_ID_FILE" "State ID file" "Initialization" || {
  handle_state_error "CRITICAL: State ID file not created at $COORDINATE_STATE_ID_FILE" 1
}
```

**Example from state-persistence.sh** (lines 197-226):
```bash
if [ "$is_first_block" = "true" ]; then
  # Expected case: First bash block of workflow, state file doesn't exist yet
  # Gracefully initialize new state file
  init_workflow_state "$workflow_id" >/dev/null
  return 1
else
  # CRITICAL ERROR: Subsequent bash block, state file should exist but doesn't
  # This indicates state persistence failure - fail-fast to expose the issue
  echo "" >&2
  echo "❌ CRITICAL ERROR: Workflow state file not found" >&2
  echo "" >&2
  echo "Context:" >&2
  echo "  Expected state file: $state_file" >&2
  echo "  Workflow ID: $workflow_id" >&2
  echo "  Block type: Subsequent block (is_first_block=false)" >&2
  echo "" >&2
  echo "TROUBLESHOOTING:" >&2
  echo "  1. Check if first bash block called init_workflow_state()" >&2
  echo "  2. Verify state ID file exists: ${HOME}/.claude/tmp/coordinate_state_id.txt" >&2
  # ... more diagnostic info
  return 2  # Exit code 2 = configuration error
fi
```

### 6. Hierarchical Supervisor Pattern

**Implementation**: coordinate.md uses research-sub-supervisor agent for 4+ topics

**Example** (coordinate.md:702-718):
```bash
Task {
  subagent_type: "general-purpose"
  description: "Coordinate research across 4+ topics with 95% context reduction"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-sub-supervisor.md

    **Supervisor Inputs**:
    - Topics: [comma-separated list of $RESEARCH_COMPLEXITY topics]
    - Output directory: $TOPIC_PATH/reports
    - State file: $STATE_FILE
    - Supervisor ID: research_sub_supervisor_$(date +%s)

    **CRITICAL**: Invoke all research-specialist workers in parallel, aggregate metadata, save supervisor checkpoint.

    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}
```

**Metadata Aggregation** (coordinate.md:995-998):
```bash
# Load supervisor checkpoint to get aggregated metadata
# extract metadata from supervisor checkpoint (report paths for verification)
# metadata extraction enables context reduction by passing summaries instead of full reports
SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')
```

### 7. Common Pitfalls and Solutions

**Pitfall 1: Variable Overwriting**
- Problem: Libraries pre-initialize variables, overwriting parent values (coordinate.md:94-97)
- Solution: Save critical variables BEFORE sourcing libraries
```bash
# CRITICAL: Save workflow description BEFORE sourcing libraries
# Libraries pre-initialize WORKFLOW_DESCRIPTION="" which overwrites parent value
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC
```

**Pitfall 2: Missing State Verification**
- Problem: Silent failures when state not persisted (state-persistence.sh:204-226)
- Solution: Fail-fast validation with diagnostic messages
```bash
if [ "$is_first_block" = "false" ]; then
  # CRITICAL ERROR: Subsequent bash block, state file should exist but doesn't
  echo "❌ CRITICAL ERROR: Workflow state file not found" >&2
  # ... detailed troubleshooting guidance
  return 2
fi
```

**Pitfall 3: Stale Context Accumulation**
- Problem: Full subagent outputs accumulate, exceeding context limits
- Solution: Aggressive pruning with 95% reduction target (context-pruning.sh:373-374)
```bash
Target: <30% context usage
Status: $([ "$reduction" -ge 70 ] && echo "✓ Target met" || echo "⚠ Below target")
```

**Pitfall 4: Bash History Expansion Errors**
- Problem: `!` characters cause history expansion failures (coordinate.md:33, 52)
- Solution: Explicitly disable history expansion
```bash
set +H  # Disable history expansion to prevent bad substitution errors
```

## Recommendations

### 1. Adopt State Persistence Pattern

Use state-persistence.sh for all multi-bash-block commands:

```bash
# Block 1
STATE_FILE=$(init_workflow_state "plan_$$")
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
verify_state_variable "PLAN_PATH" || exit 1

# Block 2+
load_workflow_state "plan_$$" false  # Fail-fast if missing
# PLAN_PATH now available
```

**Benefits**:
- 70% faster than re-detection (50ms → 15ms for CLAUDE_PROJECT_DIR)
- Fail-fast error detection prevents silent data loss
- Graceful degradation with diagnostic messages

### 2. Implement Metadata Extraction

Extract minimal metadata from artifacts before passing to subagents:

```bash
# Extract 50-word summary + key recommendations
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")
SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')
RECOMMENDATIONS=$(echo "$REPORT_METADATA" | jq -r '.recommendations[]')

# Pass only metadata to next agent
Task {
  prompt: "
    Previous research summary: $SUMMARY
    Key recommendations: $RECOMMENDATIONS

    Create plan addressing these recommendations.
  "
}
```

**Benefits**:
- 95% context reduction vs passing full report
- Faster subagent processing
- Avoids context limit errors

### 3. Apply Context Pruning Policies

Define workflow-specific pruning policies:

```bash
# After planning completes, prune research metadata (no longer needed)
if [ "$phase_name" = "planning" ]; then
  prune_phase_metadata "research"
fi

# After implementation completes, prune research and planning metadata
if [ "$phase_name" = "implementation" ]; then
  prune_phase_metadata "research"
  prune_phase_metadata "planning"
fi
```

**Benefits**:
- Maintains <30% context usage throughout workflow
- Prevents context limit errors in long workflows
- Explicit lifecycle management

### 4. Use Verification Checkpoints

Add verification after every critical operation:

```bash
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
verify_state_variable "PLAN_PATH" || {
  handle_state_error "CRITICAL: PLAN_PATH not persisted to state" 1
}

verify_file_created "$PLAN_PATH" "Plan file" "Planning" || {
  handle_state_error "CRITICAL: Plan file not created at $PLAN_PATH" 1
}
```

**Benefits**:
- Fail-fast error detection (Standard 0: Execution Enforcement)
- Clear diagnostic messages for troubleshooting
- Prevents cascading failures

### 5. Pre-Calculate Artifact Paths

Calculate all artifact paths upfront in orchestrator, pass to subagents:

```bash
# Orchestrator calculates paths
REPORT_PATH_1="${REPORTS_DIR}/001_claude_md_analysis.md"
REPORT_PATH_2="${REPORTS_DIR}/002_docs_structure_analysis.md"

# Pass exact paths to subagents
Task {
  prompt: "
    **Input Paths** (ABSOLUTE):
    - REPORT_PATH: ${REPORT_PATH_1}

    **CRITICAL**: Create report file at EXACT path provided above.
  "
}
```

**Benefits**:
- Eliminates path calculation overhead in subagents
- Ensures consistent naming across workflow
- Enables lazy directory creation (subagents create parent dirs as needed)

### 6. Implement Hierarchical Supervision

For 4+ parallel subagents, use supervisor pattern:

```bash
Task {
  description: "Coordinate research across 4+ topics with 95% context reduction"
  prompt: "
    **Supervisor Inputs**:
    - Topics: [topic1, topic2, topic3, topic4]
    - Output directory: $TOPIC_PATH/reports

    **CRITICAL**: Invoke all research-specialist workers in parallel, aggregate metadata, save supervisor checkpoint.

    Return: SUPERVISOR_COMPLETE: {supervisor_id, aggregated_metadata}
  "
}

# Load aggregated metadata
SUPERVISOR_CHECKPOINT=$(load_json_checkpoint "supervisor_metadata")
SUPERVISOR_REPORTS=$(echo "$SUPERVISOR_CHECKPOINT" | jq -r '.aggregated_metadata.reports_created[]')
```

**Benefits**:
- 95% context reduction (metadata aggregation instead of full outputs)
- Scalable to N subagents without context explosion
- Clear separation of concerns

### 7. Avoid Common Pitfalls

**Save critical variables before sourcing libraries**:
```bash
# CRITICAL: Save workflow description BEFORE sourcing libraries
SAVED_WORKFLOW_DESC="$WORKFLOW_DESCRIPTION"
export SAVED_WORKFLOW_DESC
source "${LIB_DIR}/workflow-state-machine.sh"
```

**Disable history expansion**:
```bash
set +H  # Disable history expansion to prevent bad substitution errors
```

**Use fail-fast validation mode**:
```bash
# First block: Graceful initialization
load_workflow_state "plan_$$" true

# Subsequent blocks: Fail-fast if missing
load_workflow_state "plan_$$" false
```

## References

### Primary Implementation Files

- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - GitHub Actions-style state persistence (lines 1-393)
  - `init_workflow_state()` (lines 117-144)
  - `load_workflow_state()` with fail-fast validation (lines 187-229)
  - `append_workflow_state()` (lines 254-269)
  - `save_json_checkpoint()` atomic writes (lines 292-310)
  - `load_json_checkpoint()` graceful degradation (lines 331-347)

- `/home/benjamin/.config/.claude/lib/context-pruning.sh` - 95% context reduction (lines 1-454)
  - `prune_subagent_output()` (lines 45-110)
  - `prune_phase_metadata()` (lines 138-167)
  - `apply_pruning_policy()` workflow-specific rules (lines 384-436)
  - `report_context_savings()` metrics (lines 347-378)

- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Minimal metadata extraction (lines 1-655)
  - `extract_report_metadata()` 50-word summaries (lines 13-87)
  - `extract_plan_metadata()` (lines 89-166)
  - `extract_accuracy_metadata()` (lines 529-640)
  - Cache functions (lines 295-320)

- `/home/benjamin/.config/.claude/commands/coordinate.md` - State machine orchestration (lines 1-2452)
  - State persistence pattern (lines 167-184)
  - Verification checkpoints (lines 161-164, 168-169, 173-174, 179-180)
  - Variable saving before library sourcing (lines 94-97)
  - Hierarchical supervisor invocation (lines 702-718)
  - Metadata aggregation (lines 995-998)

- `/home/benjamin/.config/.claude/commands/optimize-claude.md` - Multi-stage workflow (lines 1-326)
  - Pre-calculated artifact paths (lines 44-51)
  - Subagent path injection (lines 77-92, 155-173, 181-198)
  - Verification checkpoints (lines 124-141, 212-230)

- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` - Checkpoint management (lines 1-1046)
  - `save_checkpoint()` with schema versioning (lines 58-186)
  - `restore_checkpoint()` (lines 188-244)
  - `migrate_checkpoint_format()` (lines 294-515)
  - Context preservation fields (lines 139-143)

### Supporting Files

- `/home/benjamin/.config/.claude/lib/verification-helpers.sh` - Verification utilities
- `/home/benjamin/.config/.claude/lib/error-handling.sh` - Error handling functions
