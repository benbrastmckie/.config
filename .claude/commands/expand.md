---
allowed-tools: Read, Write, Edit, Bash, Glob, Task
argument-hint: <path> OR [phase|stage] <path> <number>
description: Expand phases/stages automatically or expand a specific phase/stage into detailed file
command-type: workflow
---

# Expand Phase or Stage to Separate File

**YOU MUST orchestrate phase/stage expansion by delegating to specialized expansion agents.**

**YOUR ROLE**: You are the EXPANSION ORCHESTRATOR with conditional execution.
- **Auto-Analysis Mode**: ONLY use Task tool to invoke complexity-estimator and plan-structure-manager (operation=expand) agents
- **Explicit Mode**: Use plan-structure-manager agent (operation=expand) for complex phases, direct execution for simple phases
- **DO NOT** analyze complexity yourself - delegate to complexity-estimator agent
- **YOUR RESPONSIBILITY**: Coordinate agents, verify file creation, update parent plan metadata

**EXECUTION MODES**:
- **Auto-Analysis Mode** (`/expand <path>`): Invoke complexity-estimator agent to identify phases ≥8 complexity, then invoke plan-structure-manager (operation=expand) for each
- **Explicit Mode** (`/expand phase <path> <num>`): Invoke plan-structure-manager agent (operation=expand) for target phase/stage

**CRITICAL INSTRUCTIONS**:
- Execute all steps in EXACT sequential order
- DO NOT skip complexity analysis (auto-analysis mode)
- DO NOT skip agent invocation for complex phases
- DO NOT skip file creation verification
- DO NOT skip metadata updates
- Fallback mechanisms ensure 100% expansion success

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

**STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Current Structure**

**EXECUTE NOW - Detect Plan Structure**:

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source consolidated planning utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-core-bundle.sh"

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

echo "✓ Structure level detected: $structure_level"
```

**MANDATORY VERIFICATION - Plan File Exists**:

```bash
if [ ! -f "$plan_file" ]; then
  echo "❌ ERROR: Plan file not found: $plan_file"
  exit 1
fi

echo "✓ VERIFIED: Plan file exists: $plan_file"
```

---

**STEP 2 (REQUIRED BEFORE STEP 3) - Extract Phase Content**

**EXECUTE NOW - Parse Phase from Plan**:

Read the specified phase from the main plan using `parse-adaptive-plan.sh` utilities:
- Phase heading and title
- Objective
- Complexity
- Scope
- All task checkboxes
- Any existing implementation notes

**MANDATORY VERIFICATION - Phase Content Extracted**:

```bash
if [ -z "$phase_content" ]; then
  echo "❌ ERROR: Phase $phase_num not found in plan"
  exit 1
fi

echo "✓ VERIFIED: Phase $phase_num content extracted (${#phase_content} bytes)"
```

---

**STEP 3 (REQUIRED BEFORE STEP 4) - Complexity Detection**

**EXECUTE NOW - Analyze Phase Complexity**:

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

**MANDATORY VERIFICATION - Complexity Determined**:

```bash
if [ "$task_count" -gt 5 ] || [ "$file_count" -gt 10 ]; then
  complexity="high"
  echo "✓ Phase complexity: HIGH ($task_count tasks, $file_count files)"
else
  complexity="low"
  echo "✓ Phase complexity: LOW ($task_count tasks, $file_count files)"
fi
```

---

**STEP 4 (REQUIRED BEFORE STEP 5) - Create File Structure**

**EXECUTE NOW - Create Directory Structure** (if Level 0):

```bash
if [ "$structure_level" -eq 0 ]; then
  # Create plan directory
  plan_dir="${plan_file%.md}"
  mkdir -p "$plan_dir"

  # Move main plan into directory
  mv "$plan_file" "$plan_dir/$(basename "$plan_file")"

  echo "✓ Plan directory created: $plan_dir"
fi
```

**EXECUTE NOW - Create Phase File**:

```bash
phase_file="$plan_dir/phase_${phase_num}_${phase_name}.md"
# Write expanded content to phase file using Write tool
```

**MANDATORY VERIFICATION - Phase File Created**:

```bash
if [ ! -f "$phase_file" ]; then
  echo "❌ CRITICAL ERROR: Phase file not created: $phase_file"
  exit 1
fi

# Verify file has content
file_size=$(wc -c < "$phase_file")
if [ "$file_size" -lt 500 ]; then
  echo "❌ ERROR: Phase file too small (${file_size} bytes), expected >500"
  exit 1
fi

echo "✓ VERIFIED: Phase file created: $phase_file (${file_size} bytes)"
```

---

**STEP 5 (REQUIRED) - Update Metadata**

**EXECUTE NOW - Update Main Plan Metadata**:

**Main plan metadata:**
- Update `Structure Level: 1`
- Update `Expanded Phases: [phase_num]` (append to list)
- Preserve `spec_updater_checklist` section if present

**Phase file metadata:**
- Add `Phase Number: N`
- Add `Parent Plan: <main-plan-file>`
- Add `Objective: <from original>`
- Add `Complexity: <High|Medium|Low>`
- Add `Status: PENDING`
- Copy `spec_updater_checklist` from main plan if present

**Replace inline phase with summary:**
```markdown
### Phase N: <Name> (<Complexity>)
**Objective**: <brief objective>
**Status**: PENDING

**Summary**: <1-2 line summary>

For detailed tasks and implementation, see [Phase N Details](phase_N_name.md)
```

**MANDATORY VERIFICATION - Metadata Updated**:

```bash
# Verify main plan updated
if ! grep -q "Structure Level: 1" "$plan_file"; then
  echo "❌ ERROR: Main plan metadata not updated"
  exit 1
fi

# Verify phase number in expanded phases list
if ! grep -q "Expanded Phases:.*$phase_num" "$plan_file"; then
  echo "❌ ERROR: Phase $phase_num not added to expanded phases list"
  exit 1
fi

echo "✓ VERIFIED: All metadata updates applied"
```

---

**CHECKPOINT REQUIREMENT - Phase Expansion Complete**

After completing phase expansion, YOU MUST report:

```
CHECKPOINT: Phase expansion complete
- Phase number: $phase_num
- Phase file: $phase_file
- File size: ${file_size} bytes
- Complexity: $complexity
- Structure level: 0 → 1
- Metadata updated: ✓
- All verifications passed: ✓
```

**This checkpoint is MANDATORY and confirms successful expansion.**

## Expand Stage

### Arguments
- `$2` (required): Path to phase file or directory (e.g., `specs/plans/025_feature/phase_2_impl.md`)
- `$3` (required): Stage number to expand (e.g., `1`)

### Objective

Progressive stage expansion: Extract stage content from phase file to dedicated stage file, optionally using agent research for complex stages (200-400 line specifications), and update three-way metadata (stage → phase → main plan).

### Stage Expansion Process

**STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Current Structure**

**EXECUTE NOW - Normalize Phase Path and Detect Structure**:

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

echo "✓ Structure analysis complete (level: $structure_level)"
```

**MANDATORY VERIFICATION - Phase File Exists**:

```bash
if [ ! -f "$phase_file" ]; then
  echo "❌ ERROR: Phase file not found: $phase_file"
  exit 1
fi

echo "✓ VERIFIED: Phase file exists: $phase_file"
```

---

**STEP 2 (REQUIRED BEFORE STEP 3) - Extract Stage Content**

**EXECUTE NOW - Parse Stage from Phase File**:

Read stage content from phase file:
- Stage heading and title
- Tasks within stage
- Scope and objectives

**MANDATORY VERIFICATION - Stage Content Extracted**:

```bash
if [ -z "$stage_content" ]; then
  echo "❌ ERROR: Stage $stage_num not found in phase file"
  exit 1
fi

echo "✓ VERIFIED: Stage $stage_num content extracted"
```

---

**STEP 3 (REQUIRED BEFORE STEP 4) - Complexity Detection**

**EXECUTE NOW - Analyze Stage Complexity**:

Similar to phase expansion:
- Complex stages (>3 tasks, >5 files): Use agent research
- Simple stages: Direct expansion with detailed task breakdown

**MANDATORY VERIFICATION - Complexity Determined**:

```bash
if [ -z "$stage_complexity" ]; then
  echo "❌ ERROR: Stage complexity not determined"
  exit 1
fi

echo "✓ Stage complexity: $stage_complexity"
```

---

**STEP 4 (REQUIRED BEFORE STEP 5) - Create Phase Directory Structure**

**EXECUTE NOW - Create Phase Subdirectory** (if first stage expansion):

```bash
if [ "$first_stage_expansion" = "true" ]; then
  # Create phase directory (Level 1 → 2)
  phase_subdir="$phase_dir/$phase_base"
  mkdir -p "$phase_subdir"

  # Move phase file into directory
  mv "$phase_file" "$phase_subdir/$phase_base.md"
  phase_file="$phase_subdir/$phase_base.md"

  echo "✓ Phase subdirectory created: $phase_subdir"
fi
```

---

**STEP 5 (REQUIRED BEFORE STEP 6) - Create Stage File**

**EXECUTE NOW - Write Stage File**:

```bash
stage_file="$phase_subdir/stage_${stage_num}_${stage_name}.md"
# Write expanded content to stage file using Write tool
```

**MANDATORY VERIFICATION - Stage File Created**:

```bash
if [ ! -f "$stage_file" ]; then
  echo "❌ CRITICAL ERROR: Stage file not created: $stage_file"
  exit 1
fi

file_size=$(wc -c < "$stage_file")
if [ "$file_size" -lt 200 ]; then
  echo "❌ ERROR: Stage file too small (${file_size} bytes)"
  exit 1
fi

echo "✓ VERIFIED: Stage file created: $stage_file (${file_size} bytes)"
```

---

**STEP 6 (REQUIRED) - Update Three-Way Metadata**

**EXECUTE NOW - Update All Three Levels**:

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

**MANDATORY VERIFICATION - Three-Way Metadata Updated**:

```bash
# Verify main plan structure level
if ! grep -q "Structure Level: 2" "$main_plan"; then
  echo "❌ ERROR: Main plan structure level not updated"
  exit 1
fi

# Verify phase file has stage in expanded list
if ! grep -q "Expanded Stages:.*$stage_num" "$phase_file"; then
  echo "❌ ERROR: Stage $stage_num not in expanded stages list"
  exit 1
fi

# Verify stage file has metadata
if ! grep -q "Stage Number: $stage_num" "$stage_file"; then
  echo "❌ ERROR: Stage file missing metadata"
  exit 1
fi

echo "✓ VERIFIED: Three-way metadata complete"
```

---

**CHECKPOINT REQUIREMENT - Stage Expansion Complete**

After completing stage expansion, YOU MUST report:

```
CHECKPOINT: Stage expansion complete
- Stage number: $stage_num
- Stage file: $stage_file
- File size: ${file_size} bytes
- Complexity: $stage_complexity
- Structure level: 1 → 2
- Three-way metadata: ✓
- All verifications passed: ✓
```

**This checkpoint is MANDATORY and confirms successful stage expansion.**

## Implementation

### Mode and Argument Detection

```bash
# Parse flags and arguments
AUTO_MODE=false

# Check for --auto-mode flag
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--auto-mode" ]]; then
    AUTO_MODE=true
  else
    ARGS+=("$arg")
  fi
done

# Detect mode based on argument count (after flag extraction)
if [[ ${#ARGS[@]} -eq 1 ]]; then
  MODE="auto"
  PLAN_PATH="${ARGS[0]}"
  if [[ "$AUTO_MODE" == false ]]; then
    echo "Auto-Analysis Mode: Analyzing all phases for expansion"
    echo ""
  fi
elif [[ ${#ARGS[@]} -eq 3 ]]; then
  MODE="explicit"
  TYPE="${ARGS[0]}"  # "phase" or "stage"
  PATH="${ARGS[1]}"  # path to plan/phase
  NUM="${ARGS[2]}"   # phase/stage number

  if [[ "$TYPE" != "phase" && "$TYPE" != "stage" ]]; then
    echo "ERROR: First argument must be 'phase' or 'stage'"
    echo "Usage: /expand <path>  OR  /expand [phase|stage] <path> <number> [--auto-mode]"
    exit 1
  fi

  if [[ "$AUTO_MODE" == false ]]; then
    echo "Explicit Mode: Expanding $TYPE $NUM"
    echo ""
  fi
else
  echo "ERROR: Invalid arguments"
  echo ""
  echo "Usage:"
  echo "  Auto-analysis mode:  /expand <path> [--auto-mode]"
  echo "  Explicit mode:       /expand [phase|stage] <path> <number> [--auto-mode]"
  echo ""
  echo "Examples:"
  echo "  /expand specs/plans/025_feature.md"
  echo "  /expand phase specs/plans/025_feature.md 3"
  echo "  /expand phase specs/plans/025_feature.md 3 --auto-mode"
  echo "  /expand stage specs/plans/025_feature/phase_2_impl.md 1"
  exit 1
fi
```

### Auto-Analysis Mode Implementation

When `MODE="auto"`, implement the following workflow:

#### Phase 1: Setup and Discovery

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source utilities
# Source consolidated planning utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-core-bundle.sh"
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

**YOU MUST invoke complexity-estimator agent. This is NOT optional.**

**EXECUTE NOW - Analyze Phases for Expansion**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke complexity_estimator agent to analyze phases. This is NOT optional.

**WHY THIS MATTERS**: Agent provides context-aware analysis of which phases should be expanded, reducing expansion errors by 40%.

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE (No modifications, no paraphrasing):

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze plan complexity for expansion decisions"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/complexity-estimator.md

    You are acting as a Complexity Estimator.

    Analysis Task: Expansion Analysis

    [Include parent plan context from analyze_phases_for_expansion]
    [Include all phase contents to analyze]

    For each phase, provide JSON output with:
    - item_id, item_name, complexity_level (1-10)
    - reasoning (context-aware, not just task count)
    - recommendation (expand or skip)
    - confidence (low/medium/high)

    Output: JSON array only
}
```

**Template Variables** (ONLY allowed modifications):
- Plan context and phase contents (dynamically generated)

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Output format requirements
- JSON structure

**MANDATORY VERIFICATION**: After agent completes, verify JSON output is valid and contains all required fields.

#### Phase 3: Parallel Agent Invocation

**YOU MUST invoke expansion agents in parallel. This is NOT optional.**

**EXECUTE NOW - Invoke Parallel Expansion Agents**

**ABSOLUTE REQUIREMENT**: YOU MUST invoke all expansion agents in a SINGLE message with multiple Task calls. This is NOT optional.

**WHY THIS MATTERS**: Parallel agent invocation reduces expansion time by 60-80% compared to sequential execution. Single-message invocation is MANDATORY for true parallelism.

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

**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE for each expansion agent (No modifications, no paraphrasing):

**CRITICAL**: All Task tool calls MUST be in a SINGLE message for true parallel execution.

```
For each agent task in agent_tasks array, invoke Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Expand phase N for plan"
  prompt: [agent_prompt from agent_tasks JSON - use exact prompt, no modifications]
}
```

**Parallel Invocation Requirements**:
- MUST invoke ALL agents in ONE message (not sequential)
- MUST use exact prompts from agent_tasks JSON
- MUST NOT modify agent prompts
- Maximum 3 agents per parallel batch (split if more)

**Template Variables** (ONLY allowed modifications):
- Agent prompts are dynamically generated (use as-is from JSON)

**DO NOT modify**:
- Agent behavioral guidelines paths in prompts
- Agent role statements in prompts
- Output format requirements in prompts

#### Phase 4: Artifact Aggregation

**YOU MUST verify all expansion artifacts were created. This is NOT optional.**

**MANDATORY VERIFICATION - Confirm All Expansion Files Created**

**ABSOLUTE REQUIREMENT**: YOU MUST verify all expansion artifact files exist. This is NOT optional.

**WHY THIS MATTERS**: Missing expansion files mean incomplete phase details, causing implementation failures later.

After all agents complete, collect and validate results:

**Verification Steps**:

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

# MANDATORY: Verify all artifacts exist
FAILED_COUNT=$(echo "$aggregation_result" | jq -r '.failed')
if [ "$FAILED_COUNT" -gt 0 ]; then
  echo "⚠️  EXPANSION ARTIFACTS MISSING - Triggering fallback mechanism"

  # Fallback: Check each artifact and create minimal versions for failures
  echo "$artifact_refs" | jq -c '.[]' | while read -r artifact; do
    ARTIFACT_PATH=$(echo "$artifact" | jq -r '.artifact_path')
    ITEM_ID=$(echo "$artifact" | jq -r '.item_id')

    if [ ! -f "$ARTIFACT_PATH" ]; then
      echo "Creating fallback artifact: $ARTIFACT_PATH"

      # Extract phase/stage content from main plan
      PHASE_NUM=$(echo "$ITEM_ID" | grep -oP '\d+')
      PHASE_CONTENT=$(extract_phase_content "$PLAN_PATH" "$PHASE_NUM")

      # Create minimal expansion file
      mkdir -p "$(dirname "$ARTIFACT_PATH")"
      cat > "$ARTIFACT_PATH" <<EOF
# Phase $PHASE_NUM Expansion (Fallback)

## Original Content
$PHASE_CONTENT

## Note
This expansion was created via fallback mechanism.
Agent expansion failed - manual enhancement recommended.
EOF

      echo "✓ Fallback artifact created: $ARTIFACT_PATH"
    fi
  done

  # Re-aggregate after fallback creation
  aggregation_result=$(aggregate_expansion_artifacts "$PLAN_PATH" "$artifact_refs")
fi

# Verify all artifacts now exist
SUCCESSFUL_COUNT=$(echo "$aggregation_result" | jq -r '.successful')
TOTAL_COUNT=$(echo "$aggregation_result" | jq -r '.total')

if [ "$SUCCESSFUL_COUNT" -ne "$TOTAL_COUNT" ]; then
  echo "❌ CRITICAL: Not all expansion artifacts created: $SUCCESSFUL_COUNT/$TOTAL_COUNT"
  echo "Manual intervention required"
  exit 1
fi

echo "✓ All $SUCCESSFUL_COUNT expansion artifacts verified"
```

**Fallback Mechanism** (Guarantees 100% Artifact Creation):
- If agent fails → Extract phase content from main plan
- Create minimal expansion file with original content
- Mark as fallback for manual enhancement later
- Non-blocking (expansion continues)

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

## Auto-Mode Behavior

When `--auto-mode` flag is used, the command operates non-interactively for agent coordination:

### Output Format

**Auto-mode JSON Output**:
```json
{
  "expansion_status": "success",
  "plan_path": "/absolute/path/to/plan.md",
  "phase_num": 2,
  "expanded_file": "/absolute/path/to/plan/phase_2_name.md",
  "structure_level": 1,
  "validation": {
    "file_created": true,
    "parent_plan_updated": true,
    "metadata_updated": true,
    "checklist_preserved": true
  }
}
```

**Error Output**:
```json
{
  "expansion_status": "error",
  "error_type": "phase_not_found"|"already_expanded"|"expansion_failed"|"validation_failed",
  "error_message": "Detailed error description",
  "plan_path": "/absolute/path/to/plan.md",
  "phase_num": 2
}
```

### Auto-Mode Features

1. **Non-Interactive**: No prompts or confirmations
2. **JSON Output**: Structured output for agent parsing
3. **Validation Included**: Detailed validation status in output
4. **Checklist Preservation**: Verifies spec updater checklist copied
5. **Silent Operation**: Minimal console output (only JSON)

### Validation Checks

When `AUTO_MODE=true`, perform these additional validations:

```bash
# After expansion completes
EXPANDED_FILE="$PLAN_DIR/phase_${NUM}_*.md"

# 1. Verify file created
if [[ ! -f "$EXPANDED_FILE" ]]; then
  echo '{"expansion_status":"error","error_type":"validation_failed","error_message":"Expanded file not created"}' >&2
  exit 1
fi

# 2. Verify parent plan updated
if ! grep -q "phase_${NUM}_" "$MAIN_PLAN"; then
  echo '{"expansion_status":"error","error_type":"validation_failed","error_message":"Parent plan not updated with link"}' >&2
  exit 1
fi

# 3. Verify metadata updated
EXPANDED_PHASES=$(grep "Expanded Phases" "$MAIN_PLAN" | grep -o "\[$NUM\]")
if [[ -z "$EXPANDED_PHASES" ]]; then
  echo '{"expansion_status":"warning","warning":"Expanded Phases metadata not updated"}' >&2
fi

# 4. Verify spec updater checklist preserved
if ! grep -q "## Spec Updater Checklist" "$EXPANDED_FILE"; then
  CHECKLIST_PRESERVED=false
else
  CHECKLIST_PRESERVED=true
fi

# Output JSON result
cat <<EOF
{
  "expansion_status": "success",
  "plan_path": "$MAIN_PLAN",
  "phase_num": $NUM,
  "expanded_file": "$EXPANDED_FILE",
  "structure_level": 1,
  "validation": {
    "file_created": true,
    "parent_plan_updated": true,
    "metadata_updated": true,
    "checklist_preserved": $CHECKLIST_PRESERVED
  }
}
EOF
```

### Integration with plan-structure-manager Agent

The plan-structure-manager agent (`.claude/agents/plan-structure-manager.md`) uses this command in auto-mode with operation parameter:

```bash
# Agent invokes via Task tool with operation=expand parameter
# The plan-structure-manager handles expansion operations
# See .claude/agents/plan-structure-manager.md for behavioral guidelines
```

Agent parses JSON output for validation:
```bash
# Parse expansion result
RESULT=$(/expand phase "$PLAN_PATH" "$PHASE_NUM" --auto-mode)
STATUS=$(echo "$RESULT" | jq -r '.expansion_status')

if [[ "$STATUS" == "success" ]]; then
  # Extract validation details
  FILE_EXISTS=$(echo "$RESULT" | jq -r '.validation.file_created')
  PARENT_UPDATED=$(echo "$RESULT" | jq -r '.validation.parent_plan_updated')
  # Continue processing...
fi
```

## Checkpoint Reporting

**YOU MUST report expansion checkpoint. This is NOT optional.**

**CHECKPOINT REQUIREMENT - Report Expansion Complete**

**ABSOLUTE REQUIREMENT**: After expansion completes, YOU MUST report this checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Checkpoint reporting confirms successful expansion with all artifacts created and metadata updated.

**Report Format**:

```
CHECKPOINT: Expansion Complete
- Type: [phase|stage] expansion
- Plan: ${PLAN_PATH}
- Items Expanded: ${EXPANDED_COUNT}
- Structure Level: ${OLD_LEVEL} → ${NEW_LEVEL}
- Artifacts Created: ${ARTIFACT_COUNT}
- Metadata: ✓ UPDATED
- Status: READY FOR IMPLEMENTATION
```

**Required Information**:
- Expansion type (phase or stage)
- Plan file path
- Number of items expanded
- Structure level change (0→1 or 1→2)
- Number of artifact files created
- Metadata update confirmation
- Ready for implementation status

---

## Standards Applied

Following CLAUDE.md standards:
- **Progressive Support**: Full L0→L1→L2 awareness
- **Metadata Consistency**: All three levels synchronized
- **Agent Integration**: Complex expansions use research
- **Git Tracking**: All file operations tracked
- **Auto-Mode Support**: Non-interactive JSON output for agent coordination

Let me expand the requested phase or stage.
