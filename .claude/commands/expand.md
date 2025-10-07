---
allowed-tools: Read, Write, Edit, Bash, Glob, Task
argument-hint: [phase|stage] <path> <number>
description: Expand a phase or stage into a detailed separate file
command-type: workflow
---

# Expand Phase or Stage to Separate File

I'll expand a phase or stage from inline content to a detailed separate file, creating the progressive planning structure.

## Syntax

```bash
# Expand phase (Level 0 → 1)
/expand phase <plan-path> <phase-num>

# Expand stage (Level 1 → 2)
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

### Type Detection

```bash
TYPE="$1"  # First argument: "phase" or "stage"
PATH="$2"  # Second argument: path to plan/phase
NUM="$3"   # Third argument: phase/stage number

if [[ "$TYPE" != "phase" && "$TYPE" != "stage" ]]; then
  echo "ERROR: First argument must be 'phase' or 'stage'"
  echo "Usage: /expand [phase|stage] <path> <number>"
  exit 1
fi

if [[ -z "$PATH" ]] || [[ -z "$NUM" ]]; then
  echo "ERROR: Path and number required"
  echo "Usage: /expand [phase|stage] <path> <number>"
  exit 1
fi
```

### Phase-Specific Implementation

```bash
if [[ "$TYPE" == "phase" ]]; then
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

### Expand phase
```bash
/expand phase specs/plans/025_feature.md 3
```

### Expand stage
```bash
/expand stage specs/plans/025_feature/phase_2_impl.md 1
```

### Expand phase in already-expanded plan
```bash
/expand phase specs/plans/025_feature/ 4
```

## Standards Applied

Following CLAUDE.md standards:
- **Progressive Support**: Full L0→L1→L2 awareness
- **Metadata Consistency**: All three levels synchronized
- **Agent Integration**: Complex expansions use research
- **Git Tracking**: All file operations tracked

Let me expand the requested phase or stage.
