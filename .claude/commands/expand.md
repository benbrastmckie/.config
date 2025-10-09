---
allowed-tools: Read, Write, Edit, Bash, Glob, Task
argument-hint: <path> OR [phase|stage] <path> <number>
description: Expand phases/stages automatically or expand a specific phase/stage into detailed file
command-type: workflow
---

# Expand Phase or Stage to Separate File

I'll expand phases or stages from inline content to detailed separate files, creating the progressive planning structure.

## Modes

### Auto-Analysis Mode
Automatically analyze all phases/stages and expand those deemed sufficiently complex by the complexity_estimator agent.

```bash
# Analyze and expand complex phases automatically
/expand <plan-path>
```

### Explicit Mode
Expand a specific phase or stage by number.

```bash
# Expand specific phase (Level 0 → 1)
/expand phase <plan-path> <phase-num>

# Expand specific stage (Level 1 → 2)
/expand stage <phase-path> <stage-num>
```

## Types

- **phase**: Expand a phase from main plan to separate file (Level 0 → 1)
- **stage**: Expand a stage from phase file to separate file (Level 1 → 2)

## Expand Phase

### Arguments
- `$2` (required): Path to plan file or directory (e.g., `specs/plans/025_feature.md`)
- `$3` (required): Phase number to expand (e.g., `3`)

### Objective

Transform a brief 30-50 line phase outline into a detailed 300-500+ line implementation specification with:
- **Concrete implementation details**, not generic guidance
- **Specific code examples and patterns** for the actual tasks
- **Detailed testing specifications** with actual test cases
- **Architecture and design decisions** specific to this phase
- **Error handling patterns** for the specific scenarios
- **Performance considerations** relevant to the work

### Phase Expansion Process

#### 1. Analyze Current Structure

```bash
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"

# Check if plan is a file or directory
if [[ -d "$plan_path" ]]; then
  # Level 1 - already expanded
  plan_file="$plan_path/$(basename "$plan_path").md"
  structure_level=1
elif [[ -f "$plan_path" ]]; then
  # Level 0 - single file
  plan_file="$plan_path"
  structure_level=0
fi
```

#### 2. Extract Phase Content

Read the specified phase from the main plan using `parse-adaptive-plan.sh` utilities:
- Phase heading and title
- Objective
- Complexity
- Scope
- All task checkboxes
- Any existing implementation notes

#### 3. Complexity Detection

Analyze the phase to determine if agent-assisted research is needed:

```bash
# Count tasks
task_count=$(echo "$phase_content" | grep -c "^- \[ \]")

# Extract file references
file_refs=$(echo "$phase_content" | grep -oE "[a-zA-Z0-9_/.-]+\.(md|sh|lua|js|py|ts)" | sort -u)
file_count=$(echo "$file_refs" | wc -l)

# Complex if: >5 tasks OR >10 files OR contains "consolidate/refactor/migrate"
```

**Complex phases** (>5 tasks, >10 files, or refactor keywords):
- Use `Task` tool with `general-purpose` agent for research
- Agent reads referenced files and synthesizes detailed specification
- Target: 300-500+ lines with concrete examples

**Simple phases** (<5 tasks, <10 files):
- Expand directly with detailed task breakdown
- Target: 200-300 lines with specific guidance

#### 4. Create File Structure

**If Level 0 (single file):**
```bash
# Create plan directory
plan_dir="${plan_file%.md}"
mkdir -p "$plan_dir"

# Move main plan into directory
mv "$plan_file" "$plan_dir/$(basename "$plan_file")"
```

**Create phase file:**
```bash
phase_file="$plan_dir/phase_${phase_num}_${phase_name}.md"
# Write expanded content to phase file
```

#### 5. Update Metadata

**Main plan metadata:**
- Update `Structure Level: 1`
- Update `Expanded Phases: [phase_num]` (append to list)

**Phase file metadata:**
- Add `Phase Number: N`
- Add `Parent Plan: <main-plan-file>`
- Add `Objective: <from original>`
- Add `Complexity: <High|Medium|Low>`
- Add `Status: PENDING`

**Replace inline phase with summary:**
```markdown
### Phase N: <Name> (<Complexity>)
**Objective**: <brief objective>
**Status**: PENDING

**Summary**: <1-2 line summary>

For detailed tasks and implementation, see [Phase N Details](phase_N_name.md)
```

## Expand Stage

### Arguments
- `$2` (required): Path to phase file or directory (e.g., `specs/plans/025_feature/phase_2_impl.md`)
- `$3` (required): Stage number to expand (e.g., `1`)

### Objective

Progressive stage expansion: Extract stage content from phase file to dedicated stage file, optionally using agent research for complex stages (200-400 line specifications), and update three-way metadata (stage → phase → main plan).

### Stage Expansion Process

#### 1. Analyze Current Structure

```bash
# Normalize phase path (accept both file and directory)
if [[ -f "$phase_path" ]] && [[ "$phase_path" == *.md ]]; then
  phase_file="$phase_path"
  phase_dir=$(dirname "$phase_file")
  phase_base=$(basename "$phase_file" .md)
elif [[ -d "$phase_path" ]]; then
  phase_base=$(basename "$phase_path")
  phase_file="$phase_path/$phase_base.md"
  phase_dir="$phase_path"
fi

# Locate main plan
plan_dir=$(dirname "$phase_dir")
plan_base=$(basename "$plan_dir")

if [[ -f "$plan_dir/$plan_base.md" ]]; then
  main_plan="$plan_dir/$plan_base.md"
fi

# Extract phase number
phase_num=$(echo "$phase_base" | grep -oP 'phase_\K\d+' | head -1)

# Detect structure level
structure_level=$(detect_structure_level "$(dirname "$main_plan")")
```

#### 2. Extract Stage Content

Read stage content from phase file:
- Stage heading and title
- Tasks within stage
- Scope and objectives

#### 3. Complexity Detection

Similar to phase expansion:
- Complex stages (>3 tasks, >5 files): Use agent research
- Simple stages: Direct expansion with detailed task breakdown

#### 4. Create Phase Directory Structure

**If first stage expansion:**
```bash
# Create phase directory (Level 1 → 2)
phase_subdir="$phase_dir/$phase_base"
mkdir -p "$phase_subdir"

# Move phase file into directory
mv "$phase_file" "$phase_subdir/$phase_base.md"
phase_file="$phase_subdir/$phase_base.md"
```

#### 5. Create Stage File

```bash
stage_file="$phase_subdir/stage_${stage_num}_${stage_name}.md"
# Write expanded content to stage file
```

#### 6. Update Three-Way Metadata

**Main plan:**
- Update `Structure Level: 2` (if first stage expansion)

**Phase file:**
- Update `Expanded Stages: [stage_num]` (append to list)
- Replace inline stage with summary and link

**Stage file:**
- Add `Stage Number: N`
- Add `Parent Phase: phase_N_name.md`
- Add `Phase Number: N`
- Add `Objective: <from original>`
- Add `Status: PENDING`

## Implementation

### Mode and Argument Detection

```bash
# Detect mode based on argument count
if [[ $# -eq 1 ]]; then
  MODE="auto"
  PLAN_PATH="$1"
  echo "Auto-Analysis Mode: Analyzing all phases for expansion"
  echo ""
elif [[ $# -eq 3 ]]; then
  MODE="explicit"
  TYPE="$1"  # "phase" or "stage"
  PATH="$2"  # path to plan/phase
  NUM="$3"   # phase/stage number

  if [[ "$TYPE" != "phase" && "$TYPE" != "stage" ]]; then
    echo "ERROR: First argument must be 'phase' or 'stage'"
    echo "Usage: /expand <path>  OR  /expand [phase|stage] <path> <number>"
    exit 1
  fi

  echo "Explicit Mode: Expanding $TYPE $NUM"
  echo ""
else
  echo "ERROR: Invalid arguments"
  echo ""
  echo "Usage:"
  echo "  Auto-analysis mode:  /expand <path>"
  echo "  Explicit mode:       /expand [phase|stage] <path> <number>"
  echo ""
  echo "Examples:"
  echo "  /expand specs/plans/025_feature.md"
  echo "  /expand phase specs/plans/025_feature.md 3"
  echo "  /expand stage specs/plans/025_feature/phase_2_impl.md 1"
  exit 1
fi
```

### Auto-Analysis Mode Implementation

When `MODE="auto"`, implement the following workflow:

#### Phase 1: Setup and Discovery

```bash
# Source utilities
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"
source "$CLAUDE_PROJECT_DIR/.claude/lib/auto-analysis-utils.sh"

# Validate plan path
if [[ ! -f "$PLAN_PATH" ]] && [[ ! -d "$PLAN_PATH" ]]; then
  echo "ERROR: Plan not found: $PLAN_PATH"
  exit 1
fi

# Detect structure level
structure_level=$(detect_structure_level "$PLAN_PATH")
echo "Current structure level: $structure_level"
```

#### Phase 2: Invoke Complexity Estimator Agent

Since bash cannot directly invoke the Task tool, show prompt for agent invocation:

```
Use Task tool to invoke complexity_estimator agent:

Task {
  subagent_type: "general-purpose"
  description: "Analyze plan complexity for expansion decisions"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/complexity_estimator.md

          You are acting as a Complexity Estimator.

          Analysis Task: Expansion Analysis

          [Include parent plan context from analyze_phases_for_expansion]
          [Include all phase contents to analyze]

          For each phase, provide JSON output with:
          - item_id, item_name, complexity_level (1-10)
          - reasoning (context-aware, not just task count)
          - recommendation (expand or skip)
          - confidence (low/medium/high)

          Output: JSON array only"
}
```

#### Phase 3: Parallel Agent Invocation

Use parallel execution functions from auto-analysis-utils.sh:

```bash
# Prepare parallel agent invocations
agent_tasks=$(invoke_expansion_agents_parallel "$PLAN_PATH" "$agent_response")

# agent_tasks is JSON array like:
# [
#   {
#     "item_id": "phase_2",
#     "artifact_path": "specs/artifacts/025_feature/expansion_2.md",
#     "agent_prompt": "Read and follow the behavioral guidelines from:..."
#   }
# ]
```

**Invoke Task tool in parallel for all agents:**

```
For each agent task, invoke Task tool concurrently (single message, multiple Task calls):

Task {
  subagent_type: "general-purpose"
  description: "Expand phase N for plan"
  prompt: [agent_prompt from agent_tasks JSON]
}
```

**Critical**: All Task tool calls must be in a single response for true parallel execution.

#### Phase 4: Artifact Aggregation

After all agents complete, collect and validate results:

```bash
# Load artifact references (paths only, not content)
artifact_refs=$(echo "$agent_tasks" | jq -c '[.[] | {item_id, artifact_path}]')

# Aggregate artifacts (lightweight summary, ~50 words per operation)
aggregation_result=$(aggregate_expansion_artifacts "$PLAN_PATH" "$artifact_refs")

# aggregation_result contains:
# {
#   "total": 3,
#   "successful": 3,
#   "failed": 0,
#   "artifacts": [
#     {"item_id": "phase_2", "status": "success", "files_created": 2},
#     ...
#   ]
# }
```

**Context reduction**: Artifact-based aggregation uses ~50 words per operation vs 200+ for full content (60-80% reduction).

#### Phase 5: Metadata Coordination

Update plan metadata sequentially after all parallel operations complete:

```bash
# Coordinate metadata updates (sequential, after parallel ops)
coordinate_metadata_updates "$PLAN_PATH" "$aggregation_result"

# Updates:
# - Structure Level: 0 → 1
# - Expanded Phases: [2, 3, 5]
# - Uses checkpoint for rollback capability
```

#### Phase 6: Generate Summary Report

```bash
# Use generate_analysis_report from auto-analysis-utils.sh
generate_analysis_report "expand" "$agent_response" "$PLAN_PATH"

# Display aggregation results
echo ""
echo "Parallel Execution Summary:"
echo "  Total operations: $(echo "$aggregation_result" | jq '.total')"
echo "  Successful: $(echo "$aggregation_result" | jq '.successful')"
echo "  Failed: $(echo "$aggregation_result" | jq '.failed')"
```

### Phase-Specific Implementation (Explicit Mode)

```bash
if [[ "$MODE" == "explicit" ]] && [[ "$TYPE" == "phase" ]]; then
  # Detect plan structure
  source .claude/lib/parse-adaptive-plan.sh

  # Extract phase content
  phase_content=$(extract_phase "$PATH" "$NUM")

  # Analyze complexity
  # ... complexity detection logic ...

  # Create directory structure (if Level 0)
  # ... directory creation logic ...

  # Expand phase (with or without agent)
  if [[ $is_complex ]]; then
    # Use Task tool with general-purpose agent
  else
    # Direct expansion
  fi

  # Update metadata
  # ... metadata update logic ...
fi
```

### Stage-Specific Implementation

```bash
if [[ "$TYPE" == "stage" ]]; then
  # Locate phase and plan files
  # ... path resolution logic ...

  # Extract stage content
  stage_content=$(extract_stage "$PATH" "$NUM")

  # Analyze complexity
  # ... complexity detection logic ...

  # Create phase directory (if first stage)
  # ... directory creation logic ...

  # Expand stage (with or without agent)
  if [[ $is_complex ]]; then
    # Use Task tool with general-purpose agent
  else
    # Direct expansion
  fi

  # Update three-way metadata
  # ... metadata update logic ...
fi
```

## Agent Integration

For complex expansions, use the `Task` tool with behavioral injection:

```markdown
You are a specialized implementation planning agent. Analyze the provided phase/stage content and create a detailed 300-500 line implementation specification.

Include:
- Concrete implementation steps with code examples
- Specific testing specifications
- Architecture decisions
- Error handling patterns
- Performance considerations

Base your analysis on:
- [file references from phase/stage]
- [related codebase patterns]
```

## Examples

### Auto-Analysis Mode

```bash
# Analyze all phases and expand complex ones automatically
/expand specs/plans/025_feature.md

# Agent will analyze each phase and recommend expansion based on:
# - Architectural significance
# - Integration complexity
# - Implementation uncertainty
# - Risk and criticality
# - Testing requirements
```

**Expected latency**: 20-40 seconds for agent complexity analysis

### Explicit Mode

```bash
# Expand specific phase
/expand phase specs/plans/025_feature.md 3

# Expand specific stage
/expand stage specs/plans/025_feature/phase_2_impl.md 1

# Expand phase in already-expanded plan
/expand phase specs/plans/025_feature/ 4
```

## Standards Applied

Following CLAUDE.md standards:
- **Progressive Support**: Full L0→L1→L2 awareness
- **Metadata Consistency**: All three levels synchronized
- **Agent Integration**: Complex expansions use research
- **Git Tracking**: All file operations tracked

Let me expand the requested phase or stage.
