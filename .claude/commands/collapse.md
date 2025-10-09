---
allowed-tools: Read, Write, Edit, Bash, Task
argument-hint: <path> OR [phase|stage] <path> <number>
description: Collapse expanded phases/stages automatically or collapse specific phase/stage back into parent
command-type: workflow
---

# Collapse Phase or Stage to Parent File

I'll merge expanded phases or stages back into their parent files and clean up directory structure, either automatically based on complexity analysis or for specific items.

## Modes

### Auto-Analysis Mode (New)
Automatically analyze all expanded phases/stages and collapse those deemed sufficiently simple by the complexity_estimator agent.

```bash
# Analyze and collapse simple expanded phases automatically
/collapse <plan-path>
```

### Explicit Mode (Original)
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

#### 1. Analyze Current Structure

```bash
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/home/benjamin/.config}"
source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-adaptive-plan.sh"

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

**Validation**:
- [ ] Plan path resolves to valid directory
- [ ] Structure Level is 1 (phase expansion exists)
- [ ] Main plan file exists and is readable

#### 2. Validate Collapse Operation

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

#### 3. Read Phase Content

```bash
# Read expanded phase content
phase_content=$(cat "$phase_file")

# Extract components
phase_title=$(grep "^# " "$phase_file" | head -1 | sed 's/^# //')
phase_objective=$(grep "^**Objective" "$phase_file" | head -1 | sed 's/\*\*Objective\*\*: //')
phase_status=$(grep "^**Status" "$phase_file" | head -1 | sed 's/\*\*Status\*\*: //')
```

#### 4. Merge Content into Main Plan

```bash
# Find phase section in main plan
# Replace summary link with full expanded content
# Preserve heading, update status if changed

# Use Edit tool to replace phase summary with full content
```

#### 5. Update Metadata

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

#### 6. Delete Phase File

```bash
# Delete expanded phase file
rm "$phase_file"
echo "Deleted: $phase_file"
```

#### 7. Convert to Level 0 (If Last Phase)

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

#### 1. Analyze Current Structure

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

#### 2. Validate Collapse Operation

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

**Validation**:
- [ ] Stage file exists and is unique

#### 3. Read Stage Content

```bash
# Read expanded stage content
stage_content=$(cat "$stage_file")

# Extract components
stage_title=$(grep "^# " "$stage_file" | head -1 | sed 's/^# //')
stage_objective=$(grep "^**Objective" "$stage_file" | head -1)
stage_status=$(grep "^**Status" "$stage_file" | head -1)
```

#### 4. Merge Content into Phase File

```bash
# Find stage section in phase file
# Replace summary link with full expanded content
# Preserve heading, update status if changed
```

#### 5. Update Three-Way Metadata

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

#### 6. Delete Stage File

```bash
# Delete expanded stage file
rm "$stage_file"
echo "Deleted: $stage_file"
```

#### 7. Convert to Level 1 (If Last Stage)

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

if [[ "$structure_level" == "0" ]]; then
  echo "Plan has no expansions to collapse"
  exit 0
fi
```

#### Phase 2: Analyze Stages First (Level 2 → 1)

If structure level is 2, collapse stages before phases:

```
For each phase with expanded stages:
  Use Task tool to invoke complexity_estimator agent for stage collapse analysis

Task {
  subagent_type: "general-purpose"
  description: "Analyze stage complexity for collapse decisions"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/complexity_estimator.md

          You are acting as a Complexity Estimator.

          Analysis Task: Collapse Analysis

          [Include phase context and master plan context]
          [Include all expanded stage contents]

          For each stage, provide JSON output with:
          - item_id, item_name, complexity_level (1-10)
          - reasoning (context-aware)
          - recommendation (collapse or keep)
          - confidence (low/medium/high)

          Output: JSON array only"
}

Parse agent response and collapse stages recommended for collapse
```

#### Phase 3: Analyze Phases (Level 1 → 0)

After all stages collapsed, analyze expanded phases:

```
Use Task tool to invoke complexity_estimator agent for phase collapse analysis

Task {
  subagent_type: "general-purpose"
  description: "Analyze phase complexity for collapse decisions"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/complexity_estimator.md

          You are acting as a Complexity Estimator.

          Analysis Task: Collapse Analysis

          [Include plan context]
          [Include all expanded phase contents]

          For each phase, assess if it's simple enough to collapse back inline
          now that implementation may be complete. Recommend 'collapse' if
          complexity ≤4, 'keep' if complexity ≥5.

          Output: JSON array only"
}

Parse agent response and collapse phases recommended for collapse
Skip phases that have expanded stages (must collapse stages first)
```

#### Phase 4: Generate Summary Report

```bash
# Use generate_analysis_report from auto-analysis-utils.sh
generate_analysis_report "collapse" "$agent_response" "$PLAN_PATH"
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

Let me collapse the requested phase or stage.
