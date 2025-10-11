---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch
argument-hint: <feature description> [report-path1] [report-path2] ...
description: Create a detailed implementation plan following project standards, optionally guided by research reports
command-type: primary
dependent-commands: list, update, revise
---

# Create Implementation Plan

I'll create a comprehensive implementation plan for the specified feature or task, following project-specific coding standards and incorporating insights from any provided research reports.

## Feature/Task and Reports
- **Feature**: First argument before any .md paths
- **Research Reports**: Any paths to specs/reports/*.md files in arguments

I'll parse the arguments to separate the feature description from any report paths.

## Process

### 1. Report Integration (if provided)
If research reports are provided, I'll:
- Read and analyze each report
- Extract key findings and recommendations
- Identify technical constraints and patterns
- Use insights to inform the plan structure
- Reference reports in the plan metadata

### 1.5. Update Report Implementation Status
**After creating the plan, update referenced reports:**

**For each research report provided:**
- Use Edit tool to update "## Implementation Status" section
- Change: `Status: Research Complete` → `Status: Planning In Progress`
- Update: `Plan: None yet` → `Plan: [link to specs/plans/NNN.md]`
- Update date field

**Example update:**
```markdown
## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/018_spec_file_updates.md](../plans/018_spec_file_updates.md)
- **Implementation**: Not started
- **Date**: 2025-10-03
```

**Edge Cases:**
- If report lacks "Implementation Status" section: Use Edit tool to append section before updating
- If report already has a plan link: Update existing (report can inform multiple plans)

### 2. Requirements Analysis and Complexity Evaluation
I'll analyze the feature requirements to determine:
- Core functionality needed
- Technical scope and boundaries
- Affected components and modules
- Dependencies and prerequisites
- Alignment with report recommendations (if applicable)

**Complexity Evaluation** (Progressive Planning):
- Use `.claude/lib/analyze-plan-requirements.sh` to estimate:
  - Task count
  - Phase count
  - Estimated hours
  - Dependency complexity
- Use `.claude/lib/calculate-plan-complexity.sh` for informational scoring only
- **All plans start as single files (Level 0)** regardless of complexity
- If complexity score ≥50: Show hint about using `/expand phase` during implementation
- Complexity score stored in metadata for future reference

### 3. Location Determination and Registration
I'll determine the specs directory location using this process:

**Step 1: Check Report Metadata (if reports provided)**
- If research reports are provided as arguments:
  - Read the first report file
  - Extract "Specs Directory" from metadata section
  - Use this same specs directory for the plan

**Step 2: Detect Project Directory (if no reports)**
- Analyze the feature and identify components to be modified
- Find the deepest directory that encompasses all relevant content
- This becomes the "project directory" for this plan

**Step 3: Check SPECS.md Registry**
- Read `.claude/SPECS.md` to see if this project is already registered
- Look for a section matching the project directory path

**Step 4: Use Registered or Auto-Detect**
- If found in SPECS.md: Use the registered specs directory
- If not found: Auto-detect best location (project-dir/specs/) and register it

**Step 5: Register/Update in SPECS.md**
- If new project: Create new section in SPECS.md
- Update "Last Updated" date and increment "Plans" count
- Use Edit tool to update SPECS.md

### 4. Plan Numbering
I'll assign the plan number by:
- Checking existing plans in the target `specs/plans/` directory
- Finding the highest numbered plan (e.g., `002_*.md`)
- Using the next sequential number (e.g., `003`)
- Starting with `001` if no numbered plans exist
- Format: `NNN_feature_name.md` with three-digit numbering

### 5. Standards Discovery
For standards discovery process, see [Standards Discovery Patterns](../docs/command-patterns.md#standards-discovery-patterns).

**Plan-specific discovery:**
- Identify CLAUDE.md location for plan metadata
- Extract testing protocols for phase validation criteria
- Note coding standards for task descriptions

### 6. Plan Structure
The implementation plan will include:

#### Overview
- Feature description and objectives
- Success criteria and deliverables
- Risk assessment and mitigation strategies

#### Technical Design
- Architecture decisions
- Component interactions
- Data flow and state management
- API design (if applicable)

#### Implementation Phases
Each phase will include:
- Clear objectives and scope
- Specific tasks with checkboxes `- [ ]`
- Testing requirements
- Validation criteria
- Estimated complexity

#### Phase Format
```markdown
### Phase N: [Phase Name]
**Objective**: [What this phase accomplishes]
**Complexity**: [Low/Medium/High]

Tasks:
- [ ] Task description with file reference
- [ ] Another specific task
- [ ] Testing task

Testing:
- Test command or approach
- Expected outcomes
```

### 7. Standards Integration
Based on discovered standards, I'll ensure:
- Code style matches project conventions
- File organization follows existing patterns
- Testing approach aligns with project practices
- Documentation format is consistent
- Git commit message format is specified

### 8. Progressive Plan Creation

**All plans start as single files** (Structure Level 0):
- Path: `specs/plans/NNN_feature_name.md`
- Single file with all phases and tasks inline
- Feature name converted to lowercase with underscores
- Comprehensive yet actionable content
- Clear phase boundaries for `/implement` command compatibility
- Metadata includes Structure Level: 0 and Complexity Score

**Expansion happens during implementation**:
- Use `/expand phase <plan> <phase-num>` to extract complex phases to separate files (Level 0 → 1)
- Use `/expand stage <phase> <stage-num>` to extract complex stages to separate files (Level 1 → 2)
- Structure grows organically based on actual implementation needs, not predictions

### 8.5. Agent-Based Plan Phase Analysis

After creating the plan, I'll analyze the entire plan holistically to identify which phases (if any) would benefit from expansion to separate files.

**Analysis Approach:**

The primary agent (executing `/plan`) has just created the plan and has all phases in context. Rather than using a generic complexity threshold, I'll review the entire plan and make informed recommendations about which specific phases might benefit from expansion.

**Evaluation Criteria:**

I'll consider for each phase:
- **Task count and complexity**: Not just numbers, but actual complexity of work
- **Scope and breadth**: Files, modules, subsystems touched
- **Interrelationships**: Dependencies and connections between phases
- **Phase relationships**: How phases build on each other
- **Natural breakpoints**: Where expansion creates better conceptual boundaries

**Evaluation Process:**

```
Read /home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md

You just created this implementation plan with [N] phases.

[Full plan content]

Follow the holistic analysis approach and identify which phases (if any)
would benefit from expansion to separate files.

Provide your recommendation in the structured format.
```

**If Expansion Recommended:**

Display formatted analysis:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The following phases may benefit from expansion:

Phase [N]: [Phase Name]
Rationale: [Agent's reasoning based on understanding the phase]
Command: /expand phase <plan-path> [N]

Phase [M]: [Phase Name]
Rationale: [Agent's reasoning based on understanding the phase]
Command: /expand phase <plan-path> [M]

Note: Expansion is optional. You can expand now before starting
implementation, or expand during implementation using /expand phase
if phases prove too complex.

Overall Complexity Score: [X] (stored in plan metadata)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If No Expansion Recommended:**

Display brief note:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan structure: All phases are appropriately scoped for inline format.

[Agent's brief rationale - e.g., "All phases have 3-5 straightforward
tasks that work well together in the single-file format."]

Overall Complexity Score: [X] (stored in plan metadata)

Note: Phases can be expanded during implementation if needed using
/expand phase <plan-path> <phase-num>.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Analysis Benefits:**

- **Specific recommendations**: Not just "plan is complex," but "Phase 3 and Phase 5 need expansion"
- **Clear rationale**: Agent explains why each phase would benefit
- **Holistic view**: Agent sees how phases relate, not just individual metrics
- **Better judgment**: Understands actual complexity, not just task counts
- **Informed decisions**: User knows which phases to consider expanding

**Relationship to /implement Proactive Check:**

- **At plan creation**: Agent reviews entire plan holistically for structural recommendations
- **At implementation**: Agent re-evaluates specific phase before starting work
- **Different contexts**: Full plan view vs focused phase view
- **User flexibility**: Can expand at plan time, implementation time, or not at all

### 8.6. Present Recommendations

The agent-based analysis from Step 8.5 is presented immediately after plan creation, before final output. This helps users make informed decisions about plan structure before beginning implementation.

**Presentation Timing:**
- After plan file is written
- Before final "Plan created successfully" message
- Gives user opportunity to expand phases immediately if desired

**User Options After Analysis:**
1. **Expand now**: Use recommended `/expand phase` commands before starting implementation
2. **Expand during implementation**: Wait and expand if phases prove complex
3. **Keep inline**: Continue with Level 0 structure throughout implementation
4. **Selective expansion**: Expand some recommended phases but not others

This analysis replaces the generic complexity hint (≥50 threshold) with specific, informed recommendations based on actual plan content.

### 9. Post-Creation Automatic Complexity Evaluation

**IMPORTANT**: After the plan file is created and written, perform automatic complexity-based evaluation to determine if any phases should be auto-expanded.

This step runs **after** the agent-based holistic analysis (Step 8.5-8.6), providing a complementary threshold-based check.

#### Step 9.1: Source Complexity Utilities

```bash
# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/detect-project-dir.sh"

# Check if complexity utilities exist
if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh" ]; then
  echo "Note: Complexity utilities not found, skipping automatic evaluation"
  # Continue to output (section 10)
  exit 0
fi

source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"
```

#### Step 9.2: Read Configurable Thresholds from CLAUDE.md

Use the `read_threshold` function to read expansion thresholds with fallbacks:

```bash
# Helper function: read_threshold
# Reads threshold value from CLAUDE.md with fallback to default
read_threshold() {
  local threshold_name="$1"
  local default_value="$2"

  # Find CLAUDE.md (search upward from project directory)
  local claude_md=""
  local search_dir="$(pwd)"

  while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/CLAUDE.md" ]; then
      claude_md="$search_dir/CLAUDE.md"
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  # Check CLAUDE_PROJECT_DIR as fallback
  if [ -z "$claude_md" ] && [ -f "$CLAUDE_PROJECT_DIR/CLAUDE.md" ]; then
    claude_md="$CLAUDE_PROJECT_DIR/CLAUDE.md"
  fi

  # No CLAUDE.md found, use default
  if [ -z "$claude_md" ]; then
    echo "$default_value"
    return
  fi

  # Extract threshold value from pattern: - **Threshold Name**: value
  local threshold_value=$(grep -E "^\s*-\s+\*\*$threshold_name\*\*:" "$claude_md" | \
                          grep -oE '[0-9]+(\.[0-9]+)?' | head -1)

  # Validate threshold is numeric
  if ! [[ "$threshold_value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$default_value"
    return
  fi

  echo "$threshold_value"
}

# Read thresholds
EXPANSION_THRESHOLD=$(read_threshold "Expansion Threshold" "8.0")
TASK_COUNT_THRESHOLD=$(read_threshold "Task Count Threshold" "10")
```

#### Step 9.3: Evaluate Each Phase for Auto-Expansion

Parse the plan file and evaluate each phase:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AUTOMATIC COMPLEXITY EVALUATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Using thresholds:"
echo "  Expansion: $EXPANSION_THRESHOLD (complexity score)"
echo "  Task Count: $TASK_COUNT_THRESHOLD (tasks per phase)"
echo ""

# Parse total phases from plan
total_phases=$(grep -c "^### Phase [0-9]" "$plan_file" || echo "0")

if [ "$total_phases" -eq 0 ]; then
  echo "No phases found, skipping evaluation"
  echo ""
else
  echo "Evaluating $total_phases phases..."
  echo ""

  # Track expansions
  expanded_count=0
  expanded_phases=""

  # Evaluate each phase
  for phase_num in $(seq 1 "$total_phases"); do
    # Extract phase content (from "### Phase N:" to next "### Phase" or "## ")
    phase_content=$(sed -n "/^### Phase $phase_num:/,/^### Phase\|^## /p" "$plan_file" | sed '$d')
    phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num:" | \
                 sed 's/^### Phase [0-9]*: //' | sed 's/ *\[.*\]$//' | sed 's/ *\*\*Objective\*\*.*//')
    task_list=$(echo "$phase_content" | grep "^- \[ \]")

    # Calculate complexity
    complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list" 2>/dev/null || echo "0")
    task_count=$(echo "$task_list" | grep -c "^- \[ \]" || echo "0")

    # Decide if expansion needed
    should_expand=false
    expansion_reason=""

    # Use bc for float comparison if available
    if command -v bc &>/dev/null; then
      if (( $(echo "$complexity_score > $EXPANSION_THRESHOLD" | bc -l) )); then
        should_expand=true
        expansion_reason="complexity $complexity_score > threshold $EXPANSION_THRESHOLD"
      fi
    else
      # Fallback to integer comparison
      complexity_int=${complexity_score%.*}
      threshold_int=${EXPANSION_THRESHOLD%.*}
      if [ "$complexity_int" -gt "$threshold_int" ]; then
        should_expand=true
        expansion_reason="complexity $complexity_score > threshold $EXPANSION_THRESHOLD"
      fi
    fi

    if [ "$task_count" -gt "$TASK_COUNT_THRESHOLD" ]; then
      should_expand=true
      if [ -n "$expansion_reason" ]; then
        expansion_reason="$expansion_reason AND $task_count tasks > $TASK_COUNT_THRESHOLD"
      else
        expansion_reason="$task_count tasks > threshold $TASK_COUNT_THRESHOLD"
      fi
    fi

    # Auto-expand if threshold exceeded
    if [ "$should_expand" = "true" ]; then
      echo "Phase $phase_num: $phase_name"
      echo "  Complexity: $complexity_score | Tasks: $task_count"
      echo "  Reason: $expansion_reason"
      echo "  Action: Auto-expanding..."
      echo ""

      # Invoke /expand phase command
      "$CLAUDE_PROJECT_DIR/.claude/commands/expand" phase "$plan_file" "$phase_num"

      # Track expansion
      expanded_count=$((expanded_count + 1))
      expanded_phases="$expanded_phases $phase_num"

      # Update plan file path after first expansion (L0 → L1 transition)
      plan_base=$(basename "$plan_file" .md)
      if [[ -d "${plan_file%/*}/$plan_base" ]]; then
        plan_file="${plan_file%/*}/$plan_base/$plan_base.md"
      fi

      echo ""
    else
      echo "Phase $phase_num: $phase_name (complexity $complexity_score, $task_count tasks) - OK"
    fi
  done

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "EVALUATION COMPLETE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$expanded_count" -gt 0 ]; then
    echo "Auto-expanded $expanded_count phase(s):$expanded_phases"
    echo "Plan structure: Level 1 (phase-expanded)"
  else
    echo "Plan structure: Level 0 (all phases inline)"
  fi

  echo ""
fi
```

#### Step 9.4: Update Plan Path for Final Output

After auto-expansion (if any), ensure the final plan path points to the correct location:

```bash
# Final plan path (may have changed from L0 → L1)
FINAL_PLAN_PATH="$plan_file"
```

**Benefits of Automatic Evaluation:**

- **Proactive Structure**: Plans are optimally structured before `/implement` begins
- **No Workflow Interruption**: Eliminates mid-implementation pauses for expansion
- **Configurable**: Project-specific thresholds in CLAUDE.md
- **Fallback Defaults**: Works without configuration (8.0 expansion, 10 task count)
- **Complementary**: Works alongside agent-based holistic analysis (Step 8.5)

**Relationship to Agent-Based Analysis:**

- **Step 8.5-8.6**: Holistic review with rationale-based recommendations
- **Step 9**: Automatic threshold-based evaluation with auto-expansion
- **Together**: Informed recommendations + automatic structure optimization

## Output Format

### Single File Format (Structure Level 0)
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Plan Number**: [NNN]
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Structure Level**: 0
- **Complexity Score**: [N.N]
- **Estimated Phases**: [Number]
- **Estimated Tasks**: [Number]
- **Estimated Hours**: [Number]
- **Standards File**: [Path to CLAUDE.md if found]
- **Research Reports**: [List of report paths used, if any]

## Overview
[Feature description and goals]

## Success Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Technical Design
[Architecture and design decisions]

## Implementation Phases

### Phase 1: [Foundation/Setup]
**Objective**: [What this phase accomplishes]
**Complexity**: [Low/Medium/High]

Tasks:
- [ ] Specific task with file reference
- [ ] Another task

Testing:
```bash
# Test command
```

### Phase 2: [Core Implementation]
[Continue with subsequent phases...]

## Testing Strategy
[Overall testing approach]

## Documentation Requirements
[What documentation needs updating]

## Dependencies
[External dependencies or prerequisites]

## Related Artifacts
[If plan created from /orchestrate workflow with research artifacts:]
- [Existing Patterns](../artifacts/{project_name}/existing_patterns.md)
- [Best Practices](../artifacts/{project_name}/best_practices.md)
- [Alternative Approaches](../artifacts/{project_name}/alternatives.md)

[Otherwise: "No artifacts - direct implementation plan"]

## Notes
[Additional considerations or decisions]
```

## Agent Usage

For agent invocation patterns, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns).

**Plan-specific agents:**

| Agent | Purpose | When Used |
|-------|---------|-----------|
| research-specialist | Analyze codebase and research best practices | Complex features requiring analysis |
| plan-architect | Generate structured implementation plans | All planning workflows |

**Two-Stage Process:**
1. **Research** (optional): Parallel research-specialist agents for different topics
2. **Planning**: Single plan-architect agent creates Level 0 plan

**Key Behaviors:**
- Always creates single-file Level 0 plans
- Includes complexity score in metadata (informational)
- Adds expansion hints if complexity ≥50
- Follows project standards from CLAUDE.md
- Uses /implement-compatible checkbox format

Let me analyze your feature requirements and create a comprehensive implementation plan.
