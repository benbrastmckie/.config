---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: <path> OR [phase|stage] <path> <number>
description: Collapse expanded phases/stages automatically or collapse specific phase/stage back into parent
command-type: workflow
---

# Collapse Phase or Stage to Parent File

**YOU MUST orchestrate phase/stage collapse by delegating to specialized collapse agents.**

**YOUR ROLE**: You are the COLLAPSE ORCHESTRATOR with conditional execution.
- **Auto-Analysis Mode**: ONLY use Task tool to invoke complexity-estimator and plan-structure-manager (operation=collapse) agents
- **Explicit Mode**: Use plan-structure-manager agent (operation=collapse) for complex collapses, direct execution for simple collapses
- **DO NOT** analyze complexity yourself - delegate to complexity-estimator agent
- **YOUR RESPONSIBILITY**: Coordinate agents, verify content preservation, update parent metadata

**EXECUTION MODES**:
- **Auto-Analysis Mode** (`/collapse <path>`): Invoke complexity-estimator agent to identify phases ≤5 complexity, then invoke plan-structure-manager (operation=collapse) for each
- **Explicit Mode** (`/collapse phase <path> <num>`): Invoke plan-structure-manager agent (operation=collapse) for target phase/stage

**CRITICAL INSTRUCTIONS**:
- Execute all steps in EXACT sequential order
- DO NOT skip complexity analysis (auto-analysis mode)
- DO NOT skip agent invocation for content-heavy phases
- DO NOT skip content preservation verification
- DO NOT skip metadata updates
- DO NOT delete expanded files until content verified in parent
- Fallback mechanisms ensure 100% content preservation

## Modes

### Auto-Analysis Mode
Automatically analyze all expanded phases/stages and collapse those deemed sufficiently simple by the complexity_estimator agent.

```bash
# Analyze and collapse simple expanded phases automatically
/collapse <plan-path>
```

### Explicit Mode
Collapse a specific phase or stage by number.

```bash
# Collapse specific phase (Level 1 → 0)
/collapse phase <plan-path> <phase-num>

# Collapse specific stage (Level 2 → 1)
/collapse stage <phase-path> <stage-num>
```

## Types

- **phase**: Collapse expanded phase back into main plan (Level 1 → 0)
- **stage**: Collapse expanded stage back into phase file (Level 2 → 1)

## Collapse Phase

### Arguments
- `$2` (required): Path to plan directory or file (e.g., `specs/plans/025_feature/`)
- `$3` (required): Phase number to collapse (e.g., `2`)

### Objective

Reverse phase expansion by merging expanded phase content back into the main plan, maintaining all task completion status, and cleaning up the directory structure if this was the last expanded phase.

**Operations**:
- Merge phase content back to main plan
- Delete phase file after successful merge
- Update metadata (Structure Level, Expanded Phases)
- Clean up directory if last phase (Level 1 → Level 0)
- Preserve all content and completion status

### Phase Collapse Process

**EXECUTE NOW**: Follow these steps in EXACT sequential order.

#### STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Current Structure

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Source consolidated planning utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-core-bundle.sh"

# Normalize plan path (handle both directory and file paths)
if [[ -f "$plan_path" ]] && [[ "$plan_path" == *.md ]]; then
  # User provided file path - extract directory
  plan_dir=$(dirname "$plan_path")
  plan_base=$(basename "$plan_path" .md)

  # Check if directory exists
  if [[ -d "$plan_dir/$plan_base" ]]; then
    plan_path="$plan_dir/$plan_base"
  else
    error "Plan has not been expanded (no directory found)"
  fi
elif [[ -d "$plan_path" ]]; then
  # Directory provided - OK
  plan_base=$(basename "$plan_path")
else
  error "Invalid plan path: $plan_path"
fi

# Detect structure level
structure_level=$(detect_structure_level "$plan_path")

if [[ "$structure_level" != "1" ]]; then
  error "Plan must be Level 1 (phase expansion) to collapse phases. Current level: $structure_level"
fi

# Identify main plan file
main_plan="$plan_path/$plan_base.md"
[[ ! -f "$main_plan" ]] && error "Main plan file not found: $main_plan"
```

**MANDATORY VERIFICATION - Structure Validated**:
```bash
[[ ! -d "$plan_path" ]] && echo "❌ ERROR: Plan path invalid" && exit 1
[[ "$structure_level" != "1" ]] && echo "❌ ERROR: Must be Level 1" && exit 1
[[ ! -f "$main_plan" ]] && echo "❌ ERROR: Main plan not found" && exit 1
echo "✓ VERIFIED: Structure valid for collapse"
```

#### STEP 2 (REQUIRED BEFORE STEP 3) - Validate Collapse Operation

```bash
# Construct phase file path
phase_file="$plan_path/phase_${phase_num}_*.md"
phase_files=($(ls $phase_file 2>/dev/null))

if [[ ${#phase_files[@]} -eq 0 ]]; then
  error "Phase $phase_num not found in $plan_path/"
elif [[ ${#phase_files[@]} -gt 1 ]]; then
  error "Multiple phase $phase_num files found (ambiguous)"
fi

phase_file="${phase_files[0]}"
phase_name=$(basename "$phase_file" .md)

echo "Found phase file: $phase_name.md"

# Check if phase has expanded stages (Level 2)
phase_dir="$plan_path/$phase_name"
if [[ -d "$phase_dir" ]]; then
  error "Phase $phase_num has expanded stages. Collapse stages first with /collapse stage"
fi
```

**Validation**:
- [ ] Phase file exists and is unique
- [ ] Phase has no expanded stages

#### STEP 3 (REQUIRED BEFORE STEP 4) - Read Phase Content

```bash
# Read expanded phase content
phase_content=$(cat "$phase_file")

# Extract components
phase_title=$(grep "^# " "$phase_file" | head -1 | sed 's/^# //')
phase_objective=$(grep "^**Objective" "$phase_file" | head -1 | sed 's/\*\*Objective\*\*: //')
phase_status=$(grep "^**Status" "$phase_file" | head -1 | sed 's/\*\*Status\*\*: //')
```

#### STEP 4 (REQUIRED BEFORE STEP 5) - Merge Content into Main Plan

```bash
# Find phase section in main plan
# Replace summary link with full expanded content
# Preserve heading, update status if changed

# Use Edit tool to replace phase summary with full content
```

#### STEP 5 (REQUIRED BEFORE STEP 6) - Update Metadata

**Remove from Expanded Phases list:**
```bash
# Update Expanded Phases metadata
# If this was the last expanded phase, prepare for Level 0 conversion
```

**Check if last expanded phase:**
```bash
remaining_expanded=$(grep "Expanded Phases:" "$main_plan" | sed 's/.*\[//' | sed 's/\]//' | tr ',' ' ')
remaining_count=$(echo "$remaining_expanded" | wc -w)

if [[ $remaining_count -eq 0 ]]; then
  convert_to_level_0=true
else
  convert_to_level_0=false
fi
```

#### STEP 6 (REQUIRED BEFORE STEP 7) - Delete Phase File

```bash
# Delete expanded phase file
rm "$phase_file"
echo "Deleted: $phase_file"
```

#### STEP 7 (FINAL STEP) - Convert to Level 0 (If Last Phase)

```bash
if [[ $convert_to_level_0 == true ]]; then
  # Move main plan back to parent directory
  parent_dir=$(dirname "$plan_path")
  mv "$main_plan" "$parent_dir/$plan_base.md"

  # Remove plan directory
  rmdir "$plan_path"

  # Update metadata: Structure Level = 0
  echo "Converted plan back to Level 0 (single file)"
fi
```

## Collapse Stage

### Arguments
- `$2` (required): Path to phase directory or file (e.g., `specs/plans/025_feature/phase_2_impl/`)
- `$3` (required): Stage number to collapse (e.g., `1`)

### Objective

Reverse stage expansion by merging expanded stage content back into the phase file, maintaining all task completion status, updating three-way metadata (stage → phase → main plan), and cleaning up the directory structure if this was the last expanded stage.

**Operations**:
- Merge stage content back to phase file
- Delete stage file after successful merge
- Update three-way metadata (phase file + main plan)
- Clean up directory if last stage (Level 2 → Level 1)
- Preserve all content and completion status

### Stage Collapse Process

**EXECUTE NOW**: Follow these steps in EXACT sequential order.

#### STEP 1 (REQUIRED BEFORE STEP 2) - Analyze Current Structure

```bash
# Normalize phase path (handle both directory and file paths)
if [[ -f "$phase_path" ]] && [[ "$phase_path" == *.md ]]; then
  # User provided file path - extract directory
  phase_dir=$(dirname "$phase_path")
  phase_base=$(basename "$phase_path" .md)

  # Check if phase directory exists
  if [[ -d "$phase_dir/$phase_base" ]]; then
    phase_path="$phase_dir/$phase_base"
  else
    error "Phase has not been expanded (no directory found)"
  fi
elif [[ -d "$phase_path" ]]; then
  # Directory provided - OK
  phase_base=$(basename "$phase_path")
else
  error "Invalid phase path: $phase_path"
fi

# Detect parent plan directory
plan_dir=$(dirname "$phase_path")
plan_base=$(basename "$plan_dir")

# Check if plan is at root or in subdirectory
if [[ -f "$plan_dir/$plan_base.md" ]]; then
  # Plan is Level 1 or Level 2
  main_plan="$plan_dir/$plan_base.md"
else
  error "Cannot locate main plan file for: $plan_dir"
fi

# Identify phase file
phase_file="$phase_path/$phase_base.md"
[[ ! -f "$phase_file" ]] && error "Phase file not found: $phase_file"

# Extract phase number
phase_num=$(echo "$phase_base" | grep -oP 'phase_\K\d+' | head -1)
```

**Validation**:
- [ ] Phase path resolves to valid directory
- [ ] Phase file exists and is readable
- [ ] Main plan file exists
- [ ] Phase number extracted correctly

#### STEP 2 (REQUIRED BEFORE STEP 3) - Validate Collapse Operation

```bash
# Construct stage file path
stage_file="$phase_path/stage_${stage_num}_*.md"
stage_files=($(ls $stage_file 2>/dev/null))

if [[ ${#stage_files[@]} -eq 0 ]]; then
  error "Stage $stage_num not found in $phase_path/"
elif [[ ${#stage_files[@]} -gt 1 ]]; then
  error "Multiple stage $stage_num files found (ambiguous)"
fi

stage_file="${stage_files[0]}"
stage_name=$(basename "$stage_file" .md)

echo "Found stage file: $stage_name.md"
```

**MANDATORY VERIFICATION - Stage File Validated**:
```bash
[[ ! -f "$stage_file" ]] && echo "❌ ERROR: Stage file not found" && exit 1
echo "✓ VERIFIED: Stage file exists: $stage_file"
```

#### STEP 3 (REQUIRED BEFORE STEP 4) - Read Stage Content

```bash
# Read expanded stage content
stage_content=$(cat "$stage_file")

# Extract components
stage_title=$(grep "^# " "$stage_file" | head -1 | sed 's/^# //')
stage_objective=$(grep "^**Objective" "$stage_file" | head -1)
stage_status=$(grep "^**Status" "$stage_file" | head -1)
```

#### STEP 4 (REQUIRED BEFORE STEP 5) - Merge Content into Phase File

```bash
# Find stage section in phase file
# Replace summary link with full expanded content
# Preserve heading, update status if changed
```

#### STEP 5 (REQUIRED BEFORE STEP 6) - Update Three-Way Metadata

**Phase file:**
- Remove stage from `Expanded Stages` list
- Check if last expanded stage

**Main plan:**
- Update `Structure Level: 1` if this was the last stage

```bash
# Check if last expanded stage
remaining_expanded=$(grep "Expanded Stages:" "$phase_file" | sed 's/.*\[//' | sed 's/\]//' | tr ',' ' ')
remaining_count=$(echo "$remaining_expanded" | wc -w)

if [[ $remaining_count -eq 0 ]]; then
  convert_to_level_1=true
else
  convert_to_level_1=false
fi
```

#### STEP 6 (REQUIRED BEFORE STEP 7) - Delete Stage File

**CRITICAL**: DO NOT delete stage file until content verified in parent.

```bash
# Delete expanded stage file
rm "$stage_file"
echo "Deleted: $stage_file"
```

#### STEP 7 (FINAL STEP) - Convert to Level 1 (If Last Stage)

```bash
if [[ $convert_to_level_1 == true ]]; then
  # Move phase file back to parent directory
  parent_dir=$(dirname "$phase_path")
  mv "$phase_file" "$parent_dir/$phase_base.md"

  # Remove phase directory
  rmdir "$phase_path"

  # Update main plan metadata: Structure Level = 1
  echo "Converted phase back to Level 1 (no stage expansion)"
fi
```

## Implementation

### Mode and Argument Detection

```bash
# Detect mode based on argument count
if [[ $# -eq 1 ]]; then
  MODE="auto"
  PLAN_PATH="$1"
  echo "Auto-Analysis Mode: Analyzing expanded phases/stages for collapse"
  echo ""
elif [[ $# -eq 3 ]]; then
  MODE="explicit"
  TYPE="$1"  # "phase" or "stage"
  PATH="$2"  # path to plan/phase
  NUM="$3"   # phase/stage number

  if [[ "$TYPE" != "phase" && "$TYPE" != "stage" ]]; then
    echo "ERROR: First argument must be 'phase' or 'stage'"
    echo "Usage: /collapse <path>  OR  /collapse [phase|stage] <path> <number>"
    exit 1
  fi

  echo "Explicit Mode: Collapsing $TYPE $NUM"
  echo ""
else
  echo "ERROR: Invalid arguments"
  echo ""
  echo "Usage:"
  echo "  Auto-analysis mode:  /collapse <path>"
  echo "  Explicit mode:       /collapse [phase|stage] <path> <number>"
  echo ""
  echo "Examples:"
  echo "  /collapse specs/plans/025_feature/"
  echo "  /collapse phase specs/plans/025_feature/ 2"
  echo "  /collapse stage specs/plans/025_feature/phase_2_impl/ 1"
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

if [[ "$structure_level" == "0" ]]; then
  echo "Plan has no expansions to collapse"
  exit 0
fi
```

#### Phase 2: Invoke Complexity Estimator (Batch Analysis)

Use complexity_estimator for batch analysis (same pattern as /expand):

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze plan complexity for collapse decisions"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/complexity-estimator.md

          You are acting as a Complexity Estimator.

          Analysis Task: Collapse Analysis

          [Include plan context from analyze_phases_for_collapse]
          [Include all expanded phase/stage contents to analyze]

          For each expanded item, provide JSON output with:
          - item_id, item_name, complexity_level (1-10)
          - reasoning (context-aware, assess if simple enough to collapse)
          - recommendation (collapse or keep)
          - confidence (low/medium/high)

          Output: JSON array only"
}
```

#### Phase 3: Parallel Agent Invocation

Use parallel execution functions from auto-analysis-utils.sh:

```bash
# Prepare parallel agent invocations
agent_tasks=$(invoke_collapse_agents_parallel "$PLAN_PATH" "$agent_response")

# agent_tasks is JSON array like:
# [
#   {
#     "item_id": "phase_2",
#     "artifact_path": "specs/artifacts/025_feature/collapse_2.md",
#     "agent_prompt": "Read and follow the behavioral guidelines from:..."
#   }
# ]
```

**Invoke Task tool in parallel for all agents:**

```
For each agent task, invoke Task tool concurrently (single message, multiple Task calls):

Task {
  subagent_type: "general-purpose"
  description: "Collapse phase/stage N for plan"
  prompt: [agent_prompt from agent_tasks JSON]
}
```

**Critical**: All Task tool calls must be in a single response for true parallel execution.

**Collapse Order**: If structure level is 2, stages are processed first, then phases.

#### Phase 4: Artifact Aggregation

After all agents complete, collect and validate results:

```bash
# Load artifact references (paths only, not content)
artifact_refs=$(echo "$agent_tasks" | jq -c '[.[] | {item_id, artifact_path}]')

# Aggregate artifacts (lightweight summary, ~50 words per operation)
aggregation_result=$(aggregate_collapse_artifacts "$PLAN_PATH" "$artifact_refs")

# aggregation_result contains:
# {
#   "total": 3,
#   "successful": 3,
#   "failed": 0,
#   "artifacts": [
#     {"item_id": "phase_2", "status": "success", "files_modified": 2},
#     ...
#   ]
# }
```

**Context reduction**: Artifact-based aggregation uses ~50 words per operation vs 200+ for full content (60-80% reduction).

#### Phase 5: Metadata Coordination

Update plan metadata sequentially after all parallel operations complete:

```bash
# Coordinate metadata updates (sequential, after parallel ops)
# Handles three-way metadata (stage → phase → plan) and Structure Level transitions (2→1→0)
coordinate_collapse_metadata_updates "$PLAN_PATH" "$aggregation_result"

# Updates:
# - Remove collapsed items from Expanded Phases/Stages lists
# - Structure Level transitions: 2→1 or 1→0
# - Uses checkpoint for rollback capability
```

#### Phase 6: Generate Summary Report

```bash
# Use generate_analysis_report from auto-analysis-utils.sh
generate_analysis_report "collapse" "$agent_response" "$PLAN_PATH"

# Display aggregation results
echo ""
echo "Parallel Execution Summary:"
echo "  Total operations: $(echo "$aggregation_result" | jq '.total')"
echo "  Successful: $(echo "$aggregation_result" | jq '.successful')"
echo "  Failed: $(echo "$aggregation_result" | jq '.failed')"
```

### Phase-Specific Implementation

```bash
if [[ "$TYPE" == "phase" ]]; then
  # Validate structure level
  # Find and validate phase file
  # Read phase content
  # Merge into main plan
  # Update metadata
  # Delete phase file
  # Convert to Level 0 if last phase
fi
```

### Stage-Specific Implementation

```bash
if [[ "$TYPE" == "stage" ]]; then
  # Validate phase structure
  # Find and validate stage file
  # Read stage content
  # Merge into phase file
  # Update three-way metadata
  # Delete stage file
  # Convert to Level 1 if last stage
fi
```

## Examples

### Auto-Analysis Mode

```bash
# Analyze all expanded phases/stages and collapse simple ones automatically
/collapse specs/plans/025_feature/

# Agent will analyze each expanded item and recommend collapse based on:
# - Current complexity (may be simpler after implementation)
# - Content volume
# - Whether detail still warrants separate file
```

**Expected latency**: 20-40 seconds for agent complexity analysis

**Collapse order**: Stages first (Level 2→1), then phases (Level 1→0)

### Explicit Mode

```bash
# Collapse specific phase
/collapse phase specs/plans/025_feature/ 2

# Collapse specific stage
/collapse stage specs/plans/025_feature/phase_2_impl/ 1

# Collapse last phase (converts to Level 0)
/collapse phase specs/plans/025_feature/ 3
# → Converts plan back to single file
```

## Standards Applied

Following CLAUDE.md standards:
- **Progressive Support**: Full L2→L1→L0 awareness
- **Metadata Consistency**: All levels synchronized
- **Content Preservation**: All completion status maintained
- **Git Tracking**: All file operations tracked

## Final Verification and Reporting

### File Creation Enforcement

**CRITICAL**: Verify content was merged into parent file BEFORE deleting expanded file.

This verification is already performed in Steps 4-6, ensuring:
- Expanded content successfully merged into parent
- Parent file updated with new content
- Metadata synchronized across all levels
- ONLY THEN: Expanded file deleted

### CHECKPOINT REQUIREMENT - Collapse Operation Complete

**YOU MUST report collapse status**:

```
CHECKPOINT: Collapse Operation Complete
- Type: [phase|stage]
- Target: [phase_N or stage_N]
- Parent Plan: [main plan path]
- Structure Level: [0|1|2] (after collapse)
- Files Deleted: [expanded file path]
- Content Preserved: YES
- Status: SUCCESS
```

### Return Format Specification

**CRITICAL**: YOU MUST return ONLY the following format:

```
✓ Collapse Complete

Type: [phase|stage]
Target: [phase_N_name or stage_N_name]
Parent: [parent file path]
Structure Level: [0|1|2]

Collapsed: [expanded file path]
Content: Preserved in parent
Metadata: Updated

Next Steps:
- Review parent file for correctness
- Verify all completion status preserved
- Continue implementation if needed
```

**EXECUTE NOW**: Collapse the requested phase or stage.
