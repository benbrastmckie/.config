# /create-plan Research Delegation Architecture Analysis

## Metadata
- **Date**: 2025-12-04
- **Agent**: research-specialist
- **Topic**: Refactoring /create-plan to use coordinator-based research delegation
- **Report Type**: Architecture analysis and pattern comparison

## Executive Summary

The `/create-plan` command currently performs research directly in the primary orchestrator (lines 51-98 in output) before invoking a single research-specialist subagent. This violates the hierarchical agent architecture documented in `.claude/docs/architecture/hierarchical-supervisor-coordination.md`. The `/research` command provides a correct reference implementation using the hard barrier pattern with path pre-calculation and verification blocks.

## Findings

### 1. Current /create-plan Behavior (Incorrect)

Examining the `/create-plan` command (`create-plan.md:849-875`) and its output (`create-plan-output.md:51-98`):

**Problem**: The primary orchestrator reads files and performs research directly before invoking Task:
```
● Read(.claude/agents/research-specialist.md)  ← Primary agent reading
● Read(.claude/output/lean-implement-output-2.md)  ← Primary agent reading
● Read(.claude/commands/implement.md)  ← Primary agent reading
● Read(.claude/commands/lean-build.md)  ← Primary agent reading
...
● Task(Research /lean-implement shortcomings...)  ← Finally delegates
```

**Impact**:
- 40-60% higher context usage in orchestrator
- No parallel research execution
- Single monolithic research report instead of topic-focused reports
- Violates hierarchical supervisor architecture

### 2. Correct Architecture from /research Command

The `/research` command (`research.md:834-867`) correctly implements the hard barrier pattern:

**Block 1d: Path Pre-Calculation** (`research.md:702-833`):
- Calculates `REPORT_PATH` before agent invocation
- Validates path is absolute
- Persists path for verification block

**Block 1d-exec: Research Specialist Invocation** (`research.md:834-867`):
```markdown
**HARD BARRIER - Research Specialist Invocation**

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "
    **Input Contract (Hard Barrier Pattern)**:
    - Report Path: ${REPORT_PATH}
    ...
    **CRITICAL**: You MUST create the report file at the EXACT path specified above.
  "
}
```

**Block 1e: Agent Output Validation** (`research.md:869-1016`):
- Hard barrier validation: workflow CANNOT proceed unless report exists
- File size check (minimum 100 bytes)
- Content validation (Findings section)

### 3. Research-Sub-Supervisor for Complex Research

For research with 4+ topics, the architecture uses `research-sub-supervisor.md`:

**Threshold Decision** (from `hierarchical-supervisor-coordination.md:676-682`):
| Supervisor Type | Flat Coordination | Hierarchical Coordination |
|----------------|-------------------|---------------------------|
| Research | < 4 topics | ≥ 4 topics |

**Research-Sub-Supervisor Pattern** (`research-sub-supervisor.md:126-219`):
1. Receives topics array from orchestrator
2. Invokes N research-specialist workers **in parallel** (single message, multiple Task calls)
3. Extracts metadata from each worker output
4. Aggregates into supervisor summary (95% context reduction)
5. Returns aggregated metadata ONLY

**Parallel Execution Pattern** (`research-sub-supervisor.md:131-132`):
```markdown
**CRITICAL**: Send a SINGLE message with multiple Task tool invocations for parallel execution.
```

### 4. Gap Analysis: /create-plan vs /research

| Aspect | /create-plan (Current) | /research (Correct) |
|--------|----------------------|-------------------|
| Path Pre-Calculation | Missing | Block 1d calculates REPORT_PATH |
| Hard Barrier Verification | Missing | Block 1e validates file exists |
| Research Delegation | Single Task after manual research | Mandatory Task with hard barrier |
| Parallel Execution | Not supported | research-sub-supervisor for 4+ topics |
| Topic Decomposition | None | Topics parsed to array |
| Context Reduction | None (full content in orchestrator) | 95% via metadata aggregation |

### 5. Required Infrastructure Components

**Existing Infrastructure (No Changes Needed)**:
1. `research-specialist.md` - Worker agent for single-topic research
2. `research-sub-supervisor.md` - Coordinator for 4+ topics
3. `hard-barrier-subagent-delegation.md` - Pattern documentation
4. `workflow-state-machine.sh` - State transitions
5. `state-persistence.sh` - Variable persistence across blocks
6. `validation-utils.sh` - `validate_agent_artifact()` function

**Required Changes to /create-plan**:
1. Add Block 1d: Report Path Pre-Calculation
2. Add Block 1d-exec: Research Initiation with hard barrier
3. Add Block 1e: Agent Output Validation
4. Add complexity-based routing to research-sub-supervisor
5. Update Block 2 to receive aggregated metadata

### 6. Topic Decomposition Strategy

For `/create-plan`, research topics should be derived from the feature description:

**Simple Features (< 4 topics)**: Direct research-specialist invocation
- Example: "Add dark mode toggle" → 1 topic

**Complex Features (≥ 4 topics)**: research-sub-supervisor invocation
- Example: "Implement user authentication" → 4+ topics:
  - Current authentication patterns
  - Security best practices
  - Session management approaches
  - Password handling standards

**Decomposition Source**:
- Use `--complexity` flag value as hint
- Complexity 1-2: Single research-specialist
- Complexity 3-4: Analyze prompt for topic extraction, use research-sub-supervisor

### 7. Report Summaries for Plan-Architect

After research completes (single or multiple reports), summaries should be passed to plan-architect:

**Current Approach** (`create-plan.md:1141-1143`):
```bash
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_LIST=$(echo "$REPORT_PATHS" | tr '\n' ' ')
```

**Recommended Enhancement**:
1. Extract executive summary (50-100 words) from each report
2. Pass summaries to plan-architect, not just paths
3. plan-architect can read full reports if needed

**Summary Extraction Pattern**:
```bash
extract_report_summary() {
  local report_path="$1"
  # Extract Executive Summary section (between ## Executive Summary and next ##)
  sed -n '/^## Executive Summary/,/^##/p' "$report_path" | head -10
}
```

## Recommendations

### Recommendation 1: Implement Hard Barrier Pattern

Add Block 1d (Path Pre-Calculation) and Block 1e (Verification) to `/create-plan`:

```markdown
## Block 1d: Report Path Pre-Calculation

```bash
REPORT_NUMBER=$(printf "%03d" 1)
REPORT_SLUG="research-findings"
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"
append_workflow_state "REPORT_PATH" "$REPORT_PATH"
```

## Block 1d-exec: Research Initiation

**EXECUTE NOW**: USE the Task tool to invoke research-specialist.

Task { ... prompt includes REPORT_PATH as contract ... }

## Block 1e: Agent Output Validation

```bash
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "agent_error" "research-specialist failed to create report"
  exit 1
fi
```
```

### Recommendation 2: Add Complexity-Based Routing

Route to research-sub-supervisor when complexity ≥ 3:

```bash
if [ "$RESEARCH_COMPLEXITY" -ge 3 ]; then
  # Invoke research-sub-supervisor for parallel multi-topic research
  RESEARCH_MODE="hierarchical"
else
  # Invoke research-specialist directly for simple research
  RESEARCH_MODE="flat"
fi
```

### Recommendation 3: Extract and Pass Report Summaries

After research phase, extract summaries for plan-architect:

```bash
# In Block 2, before plan-architect invocation
REPORT_SUMMARIES=""
for report in $(find "$RESEARCH_DIR" -name '*.md' | sort); do
  summary=$(sed -n '/^## Executive Summary/,/^##/p' "$report" | tail -n +2 | head -5)
  REPORT_SUMMARIES+="$(basename "$report"): $summary\n"
done
```

### Recommendation 4: Update research-sub-supervisor Integration

The `/create-plan` command should use research-sub-supervisor similarly to how it's documented:

**Inputs to research-sub-supervisor**:
- Topics array (derived from feature description)
- Output directory (RESEARCH_DIR)
- State file (STATE_FILE)

**Outputs from research-sub-supervisor**:
- Aggregated metadata JSON
- Report paths array
- Combined summary

## References

- `.claude/commands/create-plan.md:849-875` - Current research invocation (incorrect)
- `.claude/commands/research.md:702-1016` - Correct hard barrier implementation
- `.claude/agents/research-sub-supervisor.md:126-219` - Parallel worker invocation pattern
- `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md` - Pattern documentation
- `.claude/docs/architecture/hierarchical-supervisor-coordination.md:676-702` - Decision matrix
- `.claude/output/create-plan-output.md:51-98` - Evidence of incorrect behavior
