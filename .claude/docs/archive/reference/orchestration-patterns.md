# Orchestration Patterns Reference

This file contains reusable templates and patterns for multi-agent workflow orchestration. These patterns are referenced by `/orchestrate` and other coordination commands.

## Table of Contents

1. [Agent Prompt Templates](#agent-prompt-templates)
2. [Phase Coordination Patterns](#phase-coordination-patterns)
3. [Checkpoint Structure](#checkpoint-structure)
4. [Error Recovery Patterns](#error-recovery-patterns)
5. [Progress Streaming Patterns](#progress-streaming-patterns)

---

## Agent Prompt Templates

### Research Agent Prompt Template

Use this template for each research-specialist agent invocation. Substitute placeholders before invoking.

**Placeholders**:
- `[THINKING_MODE]`: Value from complexity analysis (think, think hard, think harder, or empty)
- `[TOPIC_TITLE]`: Research topic title (e.g., "Authentication Patterns in Codebase")
- `[USER_WORKFLOW]`: Original user workflow description (1 line)
- `[PROJECT_NAME]`: Generated project name slug
- `[TOPIC_SLUG]`: Generated topic slug
- `[SPECS_DIR]`: Path to specs directory
- `[ABSOLUTE_REPORT_PATH]`: ABSOLUTE path for report file (CRITICAL - must be absolute)
- `[COMPLEXITY_LEVEL]`: Simple|Medium|Complex|Critical
- `[SPECIFIC_REQUIREMENTS]`: What this agent should investigate

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Research Task: [TOPIC_TITLE]

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Topic Slug**: [TOPIC_SLUG]
- **Research Focus**: [SPECIFIC_REQUIREMENTS]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md
- **Complexity Level**: [COMPLEXITY_LEVEL]

## Objective
Investigate [SPECIFIC_REQUIREMENTS] to inform planning and implementation phases.

## Specs Directory Context
- **Specs Directory Detection**:
  1. Check .claude/SPECS.md for registered specs directories
  2. If no SPECS.md, use Glob to find existing specs/ directories
  3. Default to project root specs/ if none found
- **Report Location**: Create report in [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_report_name.md
- **Include in Metadata**: Add "Specs Directory" field to report metadata

## Research Requirements

[SPECIFIC_REQUIREMENTS - Agent should investigate these areas:]

### For "existing_patterns" Topics:
- Search codebase for related implementations using Grep/Glob
- Read relevant source files to understand current patterns
- Identify architectural decisions and design patterns used
- Document file locations with line number references
- Note any inconsistencies or technical debt

### For "best_practices" Topics:
- Use WebSearch to find 2025-current best practices
- Focus on authoritative sources (official docs, security guides)
- Compare industry standards with current implementation
- Identify gaps between best practices and current state
- Recommend specific improvements

### For "alternatives" Topics:
- Research 2-3 alternative implementation approaches
- Document pros/cons of each alternative
- Consider trade-offs (performance, complexity, maintainability)
- Recommend which alternative best fits this project
- Provide concrete examples from similar projects

### For "constraints" Topics:
- Identify technical limitations (platform, dependencies, performance)
- Document security considerations and requirements
- Note compatibility requirements (backwards compatibility, API contracts)
- Consider resource constraints (time, team expertise, infrastructure)
- Flag high-risk areas requiring careful design

## Report File Creation

You MUST create a research report file using the Write tool. Do NOT return only a summary.

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE report file path for you. You MUST use this exact path when creating the report file:

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns.md`

**DO NOT**:
- Recalculate the path yourself
- Use relative paths (e.g., `specs/reports/...`)
- Change the directory location
- Modify the report number

**DO**:
- Use the Write tool with the exact path provided above
- Create the report at the specified ABSOLUTE path
- Return this exact path in your REPORT_PATH: output

**Report Structure** (use this exact template):

```markdown
# [Report Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Specs Directory**: [SPECS_DIR]
- **Report Number**: NNN (within topic subdirectory)
- **Topic**: [TOPIC_SLUG]
- **Created By**: /orchestrate (research phase)
- **Workflow**: [USER_WORKFLOW]

## Implementation Status
- **Status**: Research Complete
- **Plan**: (will be added by plan-architect)
- **Implementation**: (will be added after implementation)
- **Date**: YYYY-MM-DD

## Research Focus
[Description of what this research investigated]

## Findings

### Current State Analysis
[Detailed findings from codebase analysis - include file references with line numbers]

### Industry Best Practices
[Findings from web research - include authoritative sources]

### Key Insights
[Important discoveries, patterns identified, issues found]

## Recommendations

### Primary Recommendation: [Approach Name]
**Description**: [What this approach entails]
**Pros**:
- [Advantage 1]
- [Advantage 2]
**Cons**:
- [Limitation 1]
**Suitability**: [Why this fits the project]

### Alternative Approach: [Approach Name]
[Secondary recommendation if applicable]

## Potential Challenges
- [Challenge 1 and mitigation strategy]
- [Challenge 2 and mitigation strategy]

## References
- [File: path/to/file.ext, lines X-Y - description]
- [URL: https://... - authoritative source]
- [Related code: path/to/related.ext]
```

## Expected Output

**Primary Output**: Report file path in this exact format:
```
REPORT_PATH: [ABSOLUTE_REPORT_PATH]
```

**CRITICAL**: This must be the exact ABSOLUTE path provided to you by the orchestrator. Do NOT output a relative path.

**Secondary Output**: Brief summary (1-2 sentences):
- What was researched
- Key finding or primary recommendation

**Example Output**:
```
REPORT_PATH: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_auth_patterns.md

Research investigated current authentication implementations in the codebase. Found
session-based auth using Redis with 30-minute TTL. Primary recommendation: Extend
existing session pattern rather than implementing OAuth from scratch.
```

## Success Criteria
- Report file created at correct path with correct number
- Report includes all required metadata fields
- Findings include specific file references with line numbers
- Recommendations are actionable and project-specific
- Report path returned in parseable format (REPORT_PATH: ...)
```

---

### Planning Agent Prompt Template

Template for plan-architect agent invocation during planning phase.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[USER_WORKFLOW]`: Original workflow description
- `[PROJECT_NAME]`: Generated project name
- `[RESEARCH_REPORTS]`: Array of absolute report paths from research phase
- `[PLAN_PATH]`: ABSOLUTE path for plan file
- `[COMPLEXITY_LEVEL]`: Workflow complexity level

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Planning Task: Create Implementation Plan

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Complexity Level**: [COMPLEXITY_LEVEL]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Research Reports Available

You have access to the following research reports created during the research phase:

[RESEARCH_REPORTS - List each report with its path and brief summary]

Example:
1. **Existing Patterns**: `/home/benjamin/.config/.claude/specs/reports/topic1/001_existing_patterns.md`
   - Current authentication uses session-based approach with Redis
2. **Security Practices**: `/home/benjamin/.config/.claude/specs/reports/topic2/002_security_practices.md`
   - Industry standards recommend JWT with refresh tokens

## Objective

Create a comprehensive implementation plan that:
1. Synthesizes findings from all research reports
2. Defines clear implementation phases with tasks
3. Follows project standards from CLAUDE.md
4. Includes testing and validation steps
5. Identifies risks and dependencies

## Plan Creation

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE plan file path for you. You MUST use this exact path:

**Plan Path**: [PLAN_PATH]

Example: `/home/benjamin/.config/.claude/specs/plans/042_user_authentication.md`

Use the Write tool to create the plan at this exact path.

## Plan Structure

Follow the standard implementation plan structure:

```markdown
# [Feature Name] Implementation Plan

## Metadata
- **Date**: YYYY-MM-DD
- **Plan Number**: NNN
- **Feature**: [Feature description]
- **Scope**: [Scope summary]
- **Estimated Phases**: N
- **Research Reports**:
  - [List all research report paths used]
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Overview

[Brief description of what will be implemented]

## Success Criteria

[Define what "done" looks like]

- [ ] Success criterion 1
- [ ] Success criterion 2

## Technical Design

### Design Principles

[Key principles guiding implementation]

### Architecture Decisions

[Major architectural decisions and rationale]

## Implementation Phases

### Phase 1: [Phase Name]

**Objective**: [What this phase accomplishes]

**Complexity**: Low|Medium|High
**Risk**: Low|Medium|High
**Dependencies**: [List dependencies]
**Estimated Time**: X-Y hours

#### Tasks

- [ ] Task 1
- [ ] Task 2

#### Testing

[How to test this phase]

#### Phase 1 Completion Criteria

- [ ] All tasks complete
- [ ] Tests passing
- [ ] Git commit created

### Phase 2: [Phase Name]

[Continue for each phase...]

## Testing Strategy

[Overall testing approach]

## Dependencies

[External and internal dependencies]

## Risk Assessment

[Risks and mitigation strategies]

## Success Metrics

[How to measure success]
```

## Expected Output

**Primary Output**: Plan file path in this exact format:
```
PLAN_PATH: [PLAN_PATH]
```

**Secondary Output**: Brief summary (2-3 sentences):
- What the plan covers
- Number of phases
- Estimated total time

## Success Criteria

- Plan file created at correct path
- Plan references all research reports
- Plan follows project standards
- All phases have clear tasks and success criteria
- Plan path returned in parseable format (PLAN_PATH: ...)
```

---

### Complexity Evaluation Integration

After the plan-architect creates the implementation plan, the orchestrator should evaluate plan complexity to determine if phases need expansion before implementation begins.

**Integration Point**: Between Planning Phase and Implementation Phase

**Purpose**:
- Analyze phase complexity using context-aware evaluation
- Recommend phase expansion for complex phases (complexity ≥7 or >10 tasks)
- Enable automatic `/expand` invocation based on complexity analysis
- Save complexity evaluation results in checkpoint for later reference

#### Hybrid Complexity Evaluation

The orchestrator uses a hybrid evaluation approach combining threshold-based and agent-based complexity scoring:

**Threshold-Based Scoring** (Fast, keyword-based):
- Function: `calculate_phase_complexity()` from `complexity-utils.sh`
- Speed: Instant
- Accuracy: ~70%
- Method: Keyword matching + task counting

**Agent-Based Scoring** (Slow, context-aware):
- Agent: `complexity-estimator` (`.claude/agents/complexity-estimator.md`)
- Speed: ~5-15 seconds per phase
- Accuracy: ~85-90%
- Method: Contextual analysis considering architectural impact, integration complexity, uncertainty

**Hybrid Evaluation** (Best of both):
- Function: `hybrid_complexity_evaluation()` from `complexity-utils.sh`
- Logic: Threshold first, then agent if score ≥7 or tasks ≥8
- Reconciliation: Confidence-based score merging

#### Integration Steps

**Step 1: Source Complexity Utilities**

```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/plan/complexity-utils.sh"
```

**Step 2: Evaluate Each Phase**

After plan creation, evaluate all phases:

```bash
# Read plan file
PLAN_PATH="/path/to/plan.md"

# Extract phases from plan
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH")

# Evaluate each phase
declare -a COMPLEXITY_RESULTS

for phase_num in $(seq 1 $PHASE_COUNT); do
  # Extract phase name
  PHASE_NAME=$(sed -n "/^### Phase $phase_num:/p" "$PLAN_PATH" | sed 's/^### Phase [0-9]*: //')

  # Extract task list for phase
  TASK_LIST=$(sed -n "/^### Phase $phase_num:/,/^### Phase/p" "$PLAN_PATH" | grep "^- \[ \]")

  # Run hybrid complexity evaluation
  COMPLEXITY_JSON=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_PATH")

  # Store result
  COMPLEXITY_RESULTS[$phase_num]="$COMPLEXITY_JSON"

  echo "PROGRESS: Phase $phase_num complexity evaluation complete"
done
```

**Step 3: Parse Evaluation Results**

```bash
# Parse complexity results
for phase_num in $(seq 1 $PHASE_COUNT); do
  RESULT="${COMPLEXITY_RESULTS[$phase_num]}"

  # Extract final score
  FINAL_SCORE=$(echo "$RESULT" | jq -r '.final_score')

  # Extract evaluation method (threshold, agent, hybrid, threshold_fallback)
  EVAL_METHOD=$(echo "$RESULT" | jq -r '.evaluation_method')

  # Check if expansion recommended
  if awk -v score="$FINAL_SCORE" 'BEGIN {exit !(score >= 8.0)}'; then
    echo "PROGRESS: Phase $phase_num (score: $FINAL_SCORE) - expansion recommended"
    PHASES_TO_EXPAND+=("$phase_num")
  else
    echo "PROGRESS: Phase $phase_num (score: $FINAL_SCORE) - no expansion needed"
  fi
done
```

**Step 4: Automatic Phase Expansion**

If any phases exceed complexity threshold, automatically expand them:

```bash
if [ ${#PHASES_TO_EXPAND[@]} -gt 0 ]; then
  echo "PROGRESS: Expanding ${#PHASES_TO_EXPAND[@]} complex phases..."

  for phase_num in "${PHASES_TO_EXPAND[@]}"; do
    # Invoke /expand command for each phase
    /expand "$PLAN_PATH" --phase "$phase_num" --auto-mode

    echo "PROGRESS: Phase $phase_num expanded to separate file"
  done

  # Update plan structure level
  PLAN_STRUCTURE_LEVEL=1  # Now Level 1 (phase files)
fi
```

**Step 5: Update Checkpoint with Complexity Results**

Add complexity evaluation results to checkpoint:

```json
{
  "checkpoint_type": "orchestrate",
  "current_phase": "complexity_evaluation",
  "completed_phases": ["analysis", "research", "planning"],

  "complexity_evaluation": {
    "evaluated_at": "2025-10-15T14:45:00",
    "plan_path": "/absolute/path/to/plan.md",
    "phase_evaluations": [
      {
        "phase_num": 1,
        "phase_name": "Foundation Setup",
        "final_score": 5.0,
        "evaluation_method": "threshold",
        "expansion_recommended": false
      },
      {
        "phase_num": 2,
        "phase_name": "Core Architecture Refactor",
        "final_score": 9.0,
        "evaluation_method": "agent",
        "agent_confidence": "high",
        "expansion_recommended": true,
        "expanded": true
      }
    ],
    "phases_expanded": [2, 4],
    "plan_structure_level": 1
  },

  "context_preservation": {
    "plan_path": "/absolute/path/to/plan.md",
    ...
  }
}
```

#### Error Handling

**Agent Invocation Failure**:
```bash
# If agent-based scoring fails, fallback to threshold
COMPLEXITY_JSON=$(hybrid_complexity_evaluation "$PHASE_NAME" "$TASK_LIST" "$PLAN_PATH")

EVAL_METHOD=$(echo "$COMPLEXITY_JSON" | jq -r '.evaluation_method')

if [ "$EVAL_METHOD" = "threshold_fallback" ]; then
  echo "⚠ Warning: Agent evaluation failed, using threshold scoring"
  AGENT_ERROR=$(echo "$COMPLEXITY_JSON" | jq -r '.agent_error')
  echo "Agent error: $AGENT_ERROR"
fi
```

**Parsing Failures**:
```bash
# Validate JSON structure
if ! echo "$COMPLEXITY_JSON" | jq empty 2>/dev/null; then
  echo "ERROR: Invalid complexity evaluation JSON"
  # Fallback: Use threshold scoring only
  THRESHOLD_SCORE=$(calculate_phase_complexity "$PHASE_NAME" "$TASK_LIST")
  COMPLEXITY_JSON=$(jq -n --argjson score "$THRESHOLD_SCORE" '{final_score:$score,evaluation_method:"threshold_fallback"}')
fi
```

#### Progress Markers

Use consistent progress markers for complexity evaluation:

```
PROGRESS: Starting Complexity Evaluation Phase
PROGRESS: Evaluating Phase 1/5 complexity...
PROGRESS: Phase 1 - score: 5.0 (threshold) - no expansion
PROGRESS: Evaluating Phase 2/5 complexity...
PROGRESS: Invoking complexity-estimator agent for Phase 2...
PROGRESS: Phase 2 - score: 9.0 (agent, high confidence) - expansion recommended
PROGRESS: Complexity Evaluation Phase complete - 2/5 phases need expansion
PROGRESS: Expanding complex phases...
PROGRESS: Phase 2 expanded to separate file
PROGRESS: Phase 4 expanded to separate file
PROGRESS: Expansion complete - plan structure now Level 1
```

#### Integration with /expand Command

When automatic expansion is triggered, the `/expand` command should be invoked in auto-mode:

```bash
# Invoke /expand with --auto-mode flag
/expand "$PLAN_PATH" --phase "$phase_num" --auto-mode
```

The `--auto-mode` flag (to be implemented in Phase 3, Task 3.3) enables:
- Non-interactive expansion
- JSON output for automation
- Validation feedback for orchestrator
- Preservation of spec updater checklist

#### Complexity Thresholds

The following thresholds control expansion decisions (from CLAUDE.md):

- **Expansion Threshold**: 8.0 (phases with complexity score ≥8 are expanded)
- **Task Count Threshold**: 10 (phases with >10 tasks are expanded regardless of score)
- **Agent Invocation Threshold**: 7.0 (agent invoked if threshold score ≥7 or tasks ≥8)

These thresholds can be adjusted in CLAUDE.md's "Adaptive Planning Configuration" section.

#### Performance Considerations

- **Threshold Evaluation**: <1 second per phase
- **Agent Evaluation**: 5-15 seconds per phase (only for complex phases)
- **Total Overhead**: ~30-60 seconds for typical 5-phase plan
- **Parallelization**: Not applicable (sequential evaluation required for context)

#### Integration with Spec Updater

After expansion, ensure spec updater checklist is preserved in expanded files:

```bash
# Verify spec updater checklist in expanded phase file
EXPANDED_PHASE_FILE="$PLAN_DIR/phase_${phase_num}_*.md"

if ! grep -q "Spec Updater Checklist" "$EXPANDED_PHASE_FILE"; then
  echo "⚠ Warning: Spec updater checklist missing in expanded phase"
  # Checklist should be preserved by /expand command
fi
```

---

### Plan Expansion Integration

After complexity evaluation completes, the orchestrator should coordinate automatic expansion of complex phases before implementation begins.

**Integration Point**: Between Complexity Evaluation Phase and Implementation Phase

**Purpose**:
- Automatically expand phases with complexity ≥8 or >10 tasks
- Coordinate parallel or sequential expansion based on dependencies
- Verify all expansions successful before proceeding to implementation
- Update plan structure level after expansions

#### Expansion Coordination Logic

**Step 1: Parse Complexity Evaluation Results**

Extract expansion recommendations from complexity evaluator output:

```bash
# Complexity evaluator returns JSON with phases_to_expand
COMPLEXITY_RESULTS=$(hybrid_complexity_evaluation "$PLAN_PATH")

# Extract phases that need expansion
PHASES_TO_EXPAND=$(echo "$COMPLEXITY_RESULTS" | jq -r '.expansion_plan.recommendations[] | select(.recommendation == "expand") | .phase_num')

# Check if can parallelize
CAN_PARALLELIZE=$(echo "$COMPLEXITY_RESULTS" | jq -r '.expansion_plan.can_parallelize')
```

**Step 2: Determine Expansion Strategy**

Based on `can_parallelize` flag:

```markdown
if CAN_PARALLELIZE == true:
  # Invoke all plan_expander agents in parallel (single message)
  for phase in PHASES_TO_EXPAND:
    Task(agent: plan_expander, phase: phase_num)

else:
  # Invoke plan_expander agents sequentially
  for phase in PHASES_TO_EXPAND:
    result = Task(agent: plan_expander, phase: phase_num)
    verify(result)
    if failed: break
```

**Step 3: Parallel Invocation Pattern**

When `can_parallelize: true`, invoke all agents in a SINGLE message:

```markdown
I'll expand 3 complex phases in parallel:

Task {
  subagent_type: "general-purpose"
  description: "Expand phase 2"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/plan-expander.md

          Task: Expand phase 2 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 2
          Phase Name: [PHASE_NAME]
          Complexity Score: 9.0

          Use SlashCommand tool to invoke:
          /expand phase [PLAN_PATH] 2

          Verify expansion results and return validation JSON."
}

Task {
  subagent_type: "general-purpose"
  description: "Expand phase 4"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/plan-expander.md

          Task: Expand phase 4 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 4
          Phase Name: [PHASE_NAME]
          Complexity Score: 8.5

          Use SlashCommand tool to invoke:
          /expand phase [PLAN_PATH] 4

          Verify expansion results and return validation JSON."
}

Task {
  subagent_type: "general-purpose"
  description: "Expand phase 5"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/plan-expander.md

          Task: Expand phase 5 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 5
          Phase Name: [PHASE_NAME]
          Complexity Score: 9.2

          Use SlashCommand tool to invoke:
          /expand phase [PLAN_PATH] 5

          Verify expansion results and return validation JSON."
}
```

**Critical**: All Task invocations MUST be in a single message for true parallel execution.

**Step 4: Sequential Invocation Pattern**

When `can_parallelize: false`, invoke agents one at a time:

```bash
# Expand phases sequentially
for phase_num in $PHASES_TO_EXPAND; do
  echo "PROGRESS: Expanding phase $phase_num..."

  # Invoke plan_expander agent
  EXPANSION_RESULT=$(invoke_plan_expander "$PLAN_PATH" "$phase_num")

  # Verify expansion succeeded
  EXPANSION_STATUS=$(echo "$EXPANSION_RESULT" | jq -r '.expansion_status')

  if [ "$EXPANSION_STATUS" != "success" ]; then
    echo "ERROR: Phase $phase_num expansion failed"
    ERROR_MESSAGE=$(echo "$EXPANSION_RESULT" | jq -r '.error_message')
    echo "Error: $ERROR_MESSAGE"

    # Save checkpoint and escalate
    save_checkpoint "orchestrate" "$WORKFLOW_STATE"
    exit 1
  fi

  echo "PROGRESS: Phase $phase_num expanded successfully"
done
```

**Step 5: Verify Expansion Results**

After all expansions complete (parallel or sequential), verify results:

```bash
# Collect expansion results
declare -a EXPANSION_RESULTS

for result in "${AGENT_OUTPUTS[@]}"; do
  EXPANSION_RESULTS+=("$result")
done

# Verify all expansions succeeded
TOTAL_EXPANSIONS=${#EXPANSION_RESULTS[@]}
SUCCESSFUL_EXPANSIONS=0

for result in "${EXPANSION_RESULTS[@]}"; do
  STATUS=$(echo "$result" | jq -r '.expansion_status')

  if [ "$STATUS" = "success" ]; then
    ((SUCCESSFUL_EXPANSIONS++))

    # Verify validation details
    FILE_EXISTS=$(echo "$result" | jq -r '.validation.file_exists')
    PARENT_UPDATED=$(echo "$result" | jq -r '.validation.parent_plan_updated')
    METADATA_CORRECT=$(echo "$result" | jq -r '.validation.metadata_correct')
    CHECKLIST_PRESERVED=$(echo "$result" | jq -r '.validation.spec_updater_checklist_preserved')

    if [ "$FILE_EXISTS" = "false" ] || [ "$PARENT_UPDATED" = "false" ] || \
       [ "$METADATA_CORRECT" = "false" ]; then
      echo "⚠ Warning: Validation issues detected in expansion"
      echo "  File exists: $FILE_EXISTS"
      echo "  Parent updated: $PARENT_UPDATED"
      echo "  Metadata correct: $METADATA_CORRECT"
    fi

    if [ "$CHECKLIST_PRESERVED" = "false" ]; then
      echo "⚠ Warning: Spec updater checklist not preserved in expanded phase"
    fi
  else
    echo "ERROR: Expansion failed - $(echo "$result" | jq -r '.error_message')"
  fi
done

# Summary
echo "PROGRESS: Expansion Phase complete - $SUCCESSFUL_EXPANSIONS/$TOTAL_EXPANSIONS phases expanded"

if [ $SUCCESSFUL_EXPANSIONS -ne $TOTAL_EXPANSIONS ]; then
  echo "ERROR: Some expansions failed - aborting workflow"
  save_checkpoint "orchestrate" "$WORKFLOW_STATE"
  exit 1
fi
```

**Step 6: Update Plan Structure Level**

After successful expansions, update checkpoint with new structure level:

```json
{
  "checkpoint_type": "orchestrate",
  "current_phase": "expansion",
  "completed_phases": ["analysis", "research", "planning", "complexity_evaluation"],

  "plan_structure": {
    "plan_path": "/absolute/path/to/plan.md",
    "structure_level": 1,
    "expanded_phases": [2, 4, 5],
    "expansion_completed_at": "2025-10-16T15:30:00"
  },

  "expansion_results": [
    {
      "phase_num": 2,
      "expanded_file": "/absolute/path/to/plan/phase_2_name.md",
      "expansion_status": "success"
    }
  ]
}
```

#### Error Handling

**Agent Invocation Failure**:
```bash
# Retry expansion with backoff
if ! retry_with_backoff invoke_plan_expander "$PLAN_PATH" "$phase_num"; then
  echo "ERROR: Plan expander agent invocation failed after retries"
  ERROR_TYPE=$(classify_error "$RESULT")
  format_error_report "$ERROR_TYPE" "$RESULT" "expansion"
  save_checkpoint_and_escalate
fi
```

**Validation Failures**:
```bash
# Check validation details
FILE_EXISTS=$(echo "$EXPANSION_RESULT" | jq -r '.validation.file_exists')

if [ "$FILE_EXISTS" = "false" ]; then
  echo "ERROR: Expanded file not created - expansion failed"

  # Try to find file at alternative location
  PHASE_NUM=$(echo "$EXPANSION_RESULT" | jq -r '.phase_num')
  PLAN_DIR=$(dirname "$PLAN_PATH")
  ALTERNATIVE_FILE=$(find "$PLAN_DIR" -name "phase_${PHASE_NUM}_*.md" -type f 2>/dev/null | head -1)

  if [ -n "$ALTERNATIVE_FILE" ]; then
    echo "Found expanded file at alternative location: $ALTERNATIVE_FILE"
  else
    echo "Expansion verification failed - file truly missing"
    save_checkpoint_and_escalate
  fi
fi
```

**Partial Expansion Failures**:
```bash
# If some expansions succeeded but others failed
if [ $SUCCESSFUL_EXPANSIONS -gt 0 ] && [ $SUCCESSFUL_EXPANSIONS -lt $TOTAL_EXPANSIONS ]; then
  echo "⚠ Warning: Partial expansion failure"
  echo "  Successful: $SUCCESSFUL_EXPANSIONS"
  echo "  Failed: $((TOTAL_EXPANSIONS - SUCCESSFUL_EXPANSIONS))"

  # Save partial progress in checkpoint
  save_checkpoint "orchestrate" "$WORKFLOW_STATE"

  # Ask user whether to:
  # 1. Retry failed expansions
  # 2. Proceed with successfully expanded phases
  # 3. Abort workflow
  escalate_to_user "partial_expansion_failure"
fi
```

#### Progress Markers

Use consistent progress markers for expansion phase:

```
PROGRESS: Starting Plan Expansion Phase
PROGRESS: Complexity evaluation identified 3 phases for expansion
PROGRESS: Expansion strategy: parallel (phases are independent)
PROGRESS: Invoking 3 plan_expander agents in parallel...
PROGRESS: Plan expander agent 1/3 completed (phase 2)
PROGRESS: Plan expander agent 2/3 completed (phase 4)
PROGRESS: Plan expander agent 3/3 completed (phase 5)
PROGRESS: Verifying expansion results...
PROGRESS: All 3 expansions verified successfully
PROGRESS: Plan structure updated - now Level 1
PROGRESS: Plan Expansion Phase complete - proceeding to implementation
```

#### Integration with /expand Command

The plan_expander agent uses the `/expand` command via SlashCommand tool. Ensure `/expand` supports:

**Auto-Mode Flag** (Task 3.3):
```bash
/expand phase <plan-path> <phase-num> --auto-mode
```

**Auto-mode behavior**:
- Non-interactive (no prompts)
- JSON output for automation
- Validation feedback included
- Preserves spec updater checklist

**JSON Output Format** (for agent parsing):
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

#### Checkpoint Integration

Save checkpoint after expansion phase:

```bash
# After all expansions complete
save_checkpoint "orchestrate" "$(create_checkpoint_json)"

# Checkpoint includes:
# - Completed expansion phase
# - Expansion results for each phase
# - Updated plan structure level
# - Expanded phase file paths
```

#### Performance Considerations

- **Parallel Expansion**: ~30-60 seconds per phase (concurrent)
- **Sequential Expansion**: ~30-60 seconds per phase (cumulative)
- **Parallel Savings**: Up to 60% for 3+ phases
- **Total Overhead**: ~1-3 minutes for typical 5-phase plan

#### Integration with Spec Updater

After expansion, verify spec updater checklist preserved:

```bash
# For each expanded phase file
EXPANDED_FILE="$PLAN_DIR/phase_${phase_num}_*.md"

if ! grep -q "## Spec Updater Checklist" "$EXPANDED_FILE"; then
  echo "⚠ Warning: Spec updater checklist missing in $EXPANDED_FILE"

  # Checklist should be preserved by /expand command
  # If missing, may indicate /expand bug or manual intervention needed
fi
```

---

### Wave-Based Parallelization Integration

After plan expansion completes, the orchestrator should analyze phase dependencies to enable parallel execution of independent phases during implementation.

**Integration Point**: Between Plan Expansion Phase and Implementation Phase

**Purpose**:
- Parse Dependencies metadata from phase headers
- Calculate execution waves using topological sorting (Kahn's algorithm)
- Execute independent phases in parallel within each wave
- Coordinate multiple code-writer agents for wave-based execution
- Verify all phases in wave complete before proceeding to next wave

#### Dependency Syntax

Phase dependencies are specified in phase metadata using the `Dependencies` field:

```markdown
### Phase 2: Database Schema Setup

**Dependencies**: [1]
**Risk**: Medium
**Estimated Time**: 2-3 hours
```

**Dependency Format**:
- `Dependencies: []` - No dependencies (independent phase)
- `Dependencies: [1]` - Depends on phase 1
- `Dependencies: [1, 2]` - Depends on phases 1 and 2
- `Dependencies: [1, 3, 5]` - Depends on multiple phases

**Rules**:
- Dependencies are phase numbers (integers)
- A phase can only depend on earlier phases (no forward dependencies)
- Circular dependencies are detected and rejected
- Self-dependencies are invalid

#### Dependency Analysis Integration

**Step 1: Source Dependency Analysis Utilities**

```bash
# Use lib/util/dependency-analyzer.sh instead
```

**Step 2: Validate Dependencies**

Before calculating waves, validate all dependency references:

```bash
# Validate dependencies in plan
if ! validate_dependencies "$PLAN_PATH"; then
  echo "ERROR: Invalid dependencies found in plan"
  echo "Fix dependency errors before proceeding"
  save_checkpoint_and_escalate
  exit 1
fi

# Check for circular dependencies
if ! detect_circular_dependencies "$PLAN_PATH"; then
  echo "ERROR: Circular dependencies detected in plan"
  echo "Plan has dependency cycles - cannot proceed"
  save_checkpoint_and_escalate
  exit 1
fi

echo "PROGRESS: Dependency validation complete - no issues found"
```

**Step 3: Calculate Execution Waves**

Use Kahn's algorithm to calculate execution waves:

```bash
# Calculate waves using topological sort
WAVES_JSON=$(calculate_execution_waves "$PLAN_PATH")

if [ $? -ne 0 ]; then
  echo "ERROR: Wave calculation failed"
  echo "$WAVES_JSON"
  save_checkpoint_and_escalate
  exit 1
fi

# Parse wave structure
WAVE_COUNT=$(echo "$WAVES_JSON" | jq 'length')
echo "PROGRESS: Calculated $WAVE_COUNT execution waves"

# Display wave structure
for wave_idx in $(seq 0 $((WAVE_COUNT - 1))); do
  WAVE_PHASES=$(echo "$WAVES_JSON" | jq -r ".[$wave_idx] | join(\", \")")
  echo "PROGRESS: Wave $((wave_idx + 1)): phases $WAVE_PHASES"
done
```

**Step 4: Wave-Based Implementation Loop**

Execute phases wave-by-wave, with parallel execution within each wave:

```bash
# Execute each wave
for wave_idx in $(seq 0 $((WAVE_COUNT - 1))); do
  WAVE_NUM=$((wave_idx + 1))
  WAVE_PHASES=$(echo "$WAVES_JSON" | jq -r ".[$wave_idx][]")
  PHASE_COUNT=$(echo "$WAVE_PHASES" | wc -w)

  echo "PROGRESS: Starting Wave $WAVE_NUM ($PHASE_COUNT phases)"

  if [ $PHASE_COUNT -eq 1 ]; then
    # Single phase - execute sequentially
    phase_num=$WAVE_PHASES
    echo "PROGRESS: Executing phase $phase_num..."

    # Invoke code-writer for single phase
    invoke_code_writer "$PLAN_PATH" "$phase_num"

    echo "PROGRESS: Phase $phase_num complete"
  else
    # Multiple phases - execute in parallel
    echo "PROGRESS: Executing $PHASE_COUNT phases in parallel..."

    # Invoke all code-writer agents in parallel (SINGLE MESSAGE)
    declare -a AGENT_PROMPTS
    for phase_num in $WAVE_PHASES; do
      AGENT_PROMPTS+=("$(create_code_writer_prompt "$PLAN_PATH" "$phase_num")")
    done

    # Parallel invocation (all Task calls in one message)
    invoke_parallel_code_writers "${AGENT_PROMPTS[@]}"

    echo "PROGRESS: All $PHASE_COUNT phases in wave complete"
  fi

  # Verify all phases in wave completed successfully
  for phase_num in $WAVE_PHASES; do
    if ! verify_phase_completion "$PLAN_PATH" "$phase_num"; then
      echo "ERROR: Phase $phase_num failed"
      save_checkpoint_and_escalate
      exit 1
    fi
  done

  echo "PROGRESS: Wave $WAVE_NUM complete - proceeding to next wave"
done

echo "PROGRESS: All waves complete - implementation finished"
```

#### Parallel Code-Writer Invocation Pattern

When a wave contains multiple independent phases, invoke all code-writer agents in a SINGLE message:

```markdown
I'll implement 3 independent phases in parallel (Wave 2):

Task {
  subagent_type: "general-purpose"
  description: "Implement phase 3"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/code-writer.md

          Task: Implement phase 3 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 3
          Phase Name: [PHASE_NAME]

          Use SlashCommand tool to invoke:
          /implement [PLAN_PATH] 3

          Mark phase complete and create git commit when done."
}

Task {
  subagent_type: "general-purpose"
  description: "Implement phase 4"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/code-writer.md

          Task: Implement phase 4 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 4
          Phase Name: [PHASE_NAME]

          Use SlashCommand tool to invoke:
          /implement [PLAN_PATH] 4

          Mark phase complete and create git commit when done."
}

Task {
  subagent_type: "general-purpose"
  description: "Implement phase 5"
  prompt: "Read and follow behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/code-writer.md

          Task: Implement phase 5 of implementation plan
          Plan Path: [ABSOLUTE_PLAN_PATH]
          Phase Number: 5
          Phase Name: [PHASE_NAME]

          Use SlashCommand tool to invoke:
          /implement [PLAN_PATH] 5

          Mark phase complete and create git commit when done."
}
```

**Critical**: All Task invocations MUST be in a single message for true parallel execution.

#### Sequential Fallback

If parallel execution fails or is not suitable, fall back to sequential execution:

```bash
# Sequential fallback
echo "⚠ Warning: Parallel execution not available - using sequential fallback"

for phase_num in $WAVE_PHASES; do
  echo "PROGRESS: Executing phase $phase_num sequentially..."
  invoke_code_writer "$PLAN_PATH" "$phase_num"
  verify_phase_completion "$PLAN_PATH" "$phase_num" || exit 1
done
```

#### Checkpoint Integration

Update checkpoint with wave execution state:

```json
{
  "checkpoint_type": "orchestrate",
  "current_phase": "implementation",
  "completed_phases": ["analysis", "research", "planning", "complexity_evaluation", "expansion"],

  "wave_execution": {
    "plan_path": "/absolute/path/to/plan.md",
    "total_waves": 3,
    "current_wave": 2,
    "completed_waves": [1],
    "wave_structure": [
      [1, 2],
      [3, 4, 5],
      [6]
    ],
    "phases_completed": [1, 2],
    "phases_in_progress": [3, 4, 5]
  }
}
```

#### Error Handling

**Phase Failure in Wave**:
```bash
# If any phase in wave fails, abort wave
for phase_num in $WAVE_PHASES; do
  if ! verify_phase_completion "$PLAN_PATH" "$phase_num"; then
    echo "ERROR: Phase $phase_num failed in Wave $WAVE_NUM"

    # Check which phases succeeded
    for p in $WAVE_PHASES; do
      if verify_phase_completion "$PLAN_PATH" "$p"; then
        echo "Phase $p: SUCCESS"
      else
        echo "Phase $p: FAILED"
      fi
    done

    # Save checkpoint with partial progress
    save_checkpoint "orchestrate" "$WORKFLOW_STATE"

    # Enter debugging loop for failed phase
    echo "PROGRESS: Entering debugging loop for phase $phase_num"
    enter_debugging_loop "$phase_num"
  fi
done
```

**Invalid Dependencies**:
```bash
# Validate dependencies before wave calculation
if ! validate_dependencies "$PLAN_PATH"; then
  INVALID_DEPS=$(parse_invalid_dependencies "$PLAN_PATH")
  echo "ERROR: Invalid dependencies detected:"
  echo "$INVALID_DEPS"
  echo ""
  echo "Fix these dependency errors in the plan before continuing"
  save_checkpoint_and_escalate
  exit 1
fi
```

**Circular Dependencies**:
```bash
# Detect circular dependencies
if detect_circular_dependencies "$PLAN_PATH"; then
  echo "No circular dependencies detected ✓"
else
  echo "ERROR: Circular dependency cycle detected"

  # calculate_execution_waves will identify phases in cycle
  CYCLE_INFO=$(calculate_execution_waves "$PLAN_PATH" 2>&1)
  echo "$CYCLE_INFO"

  echo "Break the dependency cycle before continuing"
  save_checkpoint_and_escalate
  exit 1
fi
```

#### Progress Markers

Use consistent progress markers for wave-based execution:

```
PROGRESS: Starting Dependency Analysis Phase
PROGRESS: Validating phase dependencies...
PROGRESS: All dependencies valid ✓
PROGRESS: Checking for circular dependencies...
PROGRESS: No circular dependencies detected ✓
PROGRESS: Calculating execution waves using topological sort...
PROGRESS: Calculated 3 execution waves
PROGRESS: Wave 1: phases 1, 2
PROGRESS: Wave 2: phases 3, 4, 5
PROGRESS: Wave 3: phase 6
PROGRESS: Starting Wave-Based Implementation
PROGRESS: Starting Wave 1 (2 phases)
PROGRESS: Executing phases 1, 2 in parallel...
PROGRESS: Phase 1 complete ✓
PROGRESS: Phase 2 complete ✓
PROGRESS: Wave 1 complete - proceeding to Wave 2
PROGRESS: Starting Wave 2 (3 phases)
PROGRESS: Executing phases 3, 4, 5 in parallel...
PROGRESS: Phase 3 complete ✓
PROGRESS: Phase 4 complete ✓
PROGRESS: Phase 5 complete ✓
PROGRESS: Wave 2 complete - proceeding to Wave 3
PROGRESS: Starting Wave 3 (1 phase)
PROGRESS: Executing phase 6...
PROGRESS: Phase 6 complete ✓
PROGRESS: Wave 3 complete
PROGRESS: All waves complete - implementation finished
```

#### Performance Metrics

Track wave-based parallelization effectiveness:

```json
{
  "performance_metrics": {
    "wave_execution": {
      "total_waves": 3,
      "total_phases": 6,
      "parallel_phases": 5,
      "sequential_phases": 1,
      "estimated_sequential_duration": 360,
      "actual_parallel_duration": 180,
      "time_savings_seconds": 180,
      "parallelization_effectiveness": 0.50
    }
  }
}
```

**Effectiveness Calculation**:
```
effectiveness = (sequential_time - parallel_time) / sequential_time
target: > 0.40 (40% time savings)
```

#### Integration with Plan Templates

Update plan templates to include Dependencies field:

**Phase Template Example**:
```markdown
### Phase N: [Phase Name]

**Objective**: [What this phase accomplishes]
**Dependencies**: [] or [1, 2, 3]
**Complexity**: Low|Medium|High
**Risk**: Low|Medium|High
**Estimated Time**: X-Y hours

#### Tasks

- [ ] Task 1
- [ ] Task 2
```

#### Documentation References

For dependency syntax and wave calculation details:
- Dependency Analysis: `lib/util/dependency-analyzer.sh`
- Phase Dependencies Guide: `.claude/docs/phase_dependencies.md` (to be created in Task 4.4)
- Plan Templates: `.claude/templates/*.yaml` (updated in Task 4.3)

---

### Implementation Agent Prompt Template

Template for code-writer agent invocation during implementation phase.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[PLAN_PATH]`: ABSOLUTE path to implementation plan
- `[STARTING_PHASE]`: Phase number to start from (for resume)

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Implementation Task: Execute Plan

## Context
- **Plan Path**: [PLAN_PATH]
- **Starting Phase**: [STARTING_PHASE]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Objective

Execute the implementation plan phase-by-phase with:
1. Automated testing after each phase
2. Git commits after successful phases
3. Checkpoint saves for resumability
4. Adaptive replanning if complexity exceeds estimates

## Implementation Protocol

Use the `/implement` command with the plan path:

```bash
/implement [PLAN_PATH] [STARTING_PHASE]
```

The `/implement` command will:
- Parse the plan file
- Execute each phase sequentially
- Run tests defined in phase tasks
- Update plan file with completion markers
- Create git commits after each phase
- Save checkpoints for resume capability

## Adaptive Planning Integration

If during implementation you discover:
- Phase complexity score >8
- More than 10 tasks in a phase
- Test failures indicating missing prerequisites

Then use `/revise --auto-mode` to update the plan structure before continuing.

## Expected Output

**Primary Output**: Implementation summary:
- Number of phases completed
- Tests status (passing/failing)
- Files modified
- Commits created

**If Tests Fail**: Return control to orchestrator for debugging loop entry.

## Success Criteria

- All planned phases executed
- Tests passing
- Git commits created for each phase
- Implementation complete or checkpoint saved for resume
```

---

### Debug Agent Prompt Template

Template for debug-specialist agent invocation during debugging loop.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[TEST_FAILURES]`: Description of test failures
- `[ITERATION]`: Current debug iteration (1-3)
- `[DEBUG_REPORT_PATH]`: ABSOLUTE path for debug report

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Debug Task: Investigate Test Failures

## Context
- **Iteration**: [ITERATION] of 3
- **Test Failures**: [TEST_FAILURES]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Objective

Investigate test failures and create a diagnostic report with:
1. Root cause analysis
2. Recommended fixes
3. Test cases to verify fixes
4. Prevention strategies

## Investigation Protocol

1. **Analyze Test Output**: Understand what tests are failing and why
2. **Search Codebase**: Use Grep/Glob to find relevant code
3. **Identify Root Cause**: Determine the underlying issue
4. **Recommend Fix**: Provide specific, actionable fix recommendations
5. **Create Debug Report**: Document findings at specified path

## Debug Report Creation

**CRITICAL: Use the Provided Absolute Path**:

**Debug Report Path**: [DEBUG_REPORT_PATH]

Example: `/home/benjamin/.config/debug/test_failures/001_auth_timeout.md`

## Debug Report Structure

```markdown
# Debug Report: [Issue Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Debug Iteration**: [ITERATION]
- **Created By**: /orchestrate (debugging phase)

## Problem Statement

[Clear description of test failures]

## Root Cause Analysis

### Investigation Steps
[What was investigated and how]

### Root Cause
[What is causing the failures]

### Supporting Evidence
[File references, line numbers, error messages]

## Recommended Fix

### Fix Description
[What needs to be changed]

### Implementation Steps
1. [Step 1]
2. [Step 2]

### Files to Modify
- `path/to/file.ext` (lines X-Y): [change description]

## Test Verification

### Test Cases
[How to verify the fix works]

### Expected Behavior After Fix
[What should happen after fix is applied]

## Prevention Strategy

[How to prevent this issue in the future]
```

## Expected Output

**Primary Output**: Debug report path:
```
DEBUG_REPORT_PATH: [DEBUG_REPORT_PATH]
```

**Secondary Output**: Fix recommendation summary (2-3 sentences)

## Success Criteria

- Root cause identified
- Fix recommendations are specific and actionable
- Debug report created at correct path
- Report includes file references with line numbers
```

---

### Documentation Agent Prompt Template

Template for doc-writer agent invocation during documentation phase.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[WORKFLOW_STATE]`: Complete workflow state with all phase results
- `[SUMMARY_PATH]`: ABSOLUTE path for workflow summary

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Documentation Task: Generate Workflow Summary

## Context
- **Workflow Completed**: [WORKFLOW_STATE.workflow_description]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Workflow Results

### Research Phase
- Reports Created: [List of report paths]
- Research Topics: [List of topics]

### Planning Phase
- Plan Created: [Plan path]
- Phases Defined: [Number]

### Implementation Phase
- Files Modified: [List]
- Tests Status: [Passing/Failing]
- Commits Created: [Number]

### Debugging Phase (if occurred)
- Debug Iterations: [Number]
- Debug Reports: [List of paths]

## Objective

Create a comprehensive workflow summary that:
1. Documents what was accomplished
2. Links all artifacts (reports, plan, code changes)
3. Provides performance metrics
4. Records lessons learned

## Workflow Summary Creation

**CRITICAL: Use the Provided Absolute Path**:

**Summary Path**: [SUMMARY_PATH]

Example: `/home/benjamin/.config/.claude/specs/summaries/042_implementation_summary.md`

## Summary Structure

```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: YYYY-MM-DD
- **Plan**: [Link to plan file]
- **Research Reports**: [Links to reports]
- **Phases Completed**: N/N

## Implementation Overview

[Brief description of what was implemented]

## Workflow Execution

### Research Phase
- Duration: X minutes
- Agents Invoked: N
- Reports Created:
  1. [Report path] - [Brief description]
  2. [Report path] - [Brief description]

### Planning Phase
- Duration: X minutes
- Plan Created: [Plan path]
- Phases Defined: N

### Implementation Phase
- Duration: X minutes
- Phases Completed: N/N
- Tests Status: Passing/Failing
- Files Modified:
  - [file path]
  - [file path]
- Commits: [Number]

### Debugging Phase
- Iterations: N/3
- Issues Resolved: [Description]
- Debug Reports:
  - [Debug report path]

### Documentation Phase
- Duration: X minutes
- Documentation Updated: [List]

## Key Changes

- [Major change 1]
- [Major change 2]

## Test Results

[Summary of test outcomes]

## Performance Metrics

- Total Duration: X minutes
- Research Parallelization Savings: X minutes
- Debug Iterations: N
- Agents Invoked: N
- Files Created: N

## Lessons Learned

[Insights from implementation]

## Cross-References

- Plan: [plan path]
- Reports: [list of report paths]
- Debug Reports: [list if any]
- Code Changes: [git commit hashes]
```

## Expected Output

**Primary Output**: Summary path:
```
SUMMARY_PATH: [SUMMARY_PATH]
```

**Secondary Output**: Brief summary (2-3 sentences)

## Success Criteria

- Summary file created at correct path
- All artifacts cross-referenced
- Performance metrics included
- Lessons learned documented
```

---

### Spec Updater Agent Integration

The spec-updater agent manages artifact placement in the topic-based directory structure. While most artifact creation is handled inline by other agents (research-specialist creates reports, plan-architect creates plans, doc-writer creates summaries), spec-updater ensures proper organization for complex scenarios.

**When to Use Spec-Updater**:
- **Direct Invocation**: When creating artifacts that need complex placement logic or cross-reference updates
- **Post-Migration**: When updating artifact paths after reorganization
- **Bulk Operations**: When moving or reorganizing multiple artifacts

**Topic-Based Structure Integration**:

All artifacts are now organized under topic directories:
```
specs/{NNN_topic}/
├── {NNN_topic}.md              # Main plan
├── reports/                     # Research reports
├── summaries/                   # Implementation summaries
├── debug/                       # Debug reports (COMMITTED to git)
├── scripts/                     # Investigation scripts (gitignored)
├── outputs/                     # Test outputs (gitignored)
└── artifacts/                   # Operation artifacts (gitignored)
```

**Debug Report Creation Pattern** (Updated for Topic-Based Structure):

When the debugging loop creates debug reports, they should be placed in the topic's debug/ subdirectory:

```markdown
# Calculate debug report path from plan path
PLAN_PATH="/home/benjamin/.config/specs/009_orchestration_enhancement/009_orchestration_enhancement.md"
TOPIC_DIR=$(dirname "$PLAN_PATH")
DEBUG_DIR="$TOPIC_DIR/debug"

# Ensure debug directory exists
mkdir -p "$DEBUG_DIR"

# Find next debug report number within topic
MAX_NUM=$(find "$DEBUG_DIR" -name "*.md" | sed 's/.*\/0*\([0-9]*\)_.*/\1/' | sort -n | tail -1)
NEXT_NUM=$(printf "%03d" $((MAX_NUM + 1)))

# Create debug report path
DEBUG_REPORT_PATH="$DEBUG_DIR/${NEXT_NUM}_issue_description.md"
```

**Debug Report Template**:

```markdown
# Debug Report: [Issue Description]

## Metadata
- **Date**: YYYY-MM-DD
- **Topic**: {NNN_topic_name}
- **Main Plan**: ../../{NNN_topic}.md
- **Phase**: Phase N
- **Iteration**: 1|2|3

## Issue Description
[What went wrong]

## Root Cause Analysis
[Why it happened]

## Fix Proposals
[Specific fixes with confidence levels]

## Resolution
[What was done, if resolved]
```

**Gitignore Compliance**:

Important distinction for artifact categories:
- **debug/**: COMMITTED to git (exception to gitignore, for issue tracking)
- **scripts/**, **outputs/**, **artifacts/**: GITIGNORED (temporary, ephemeral)
- **reports/**, **plans/**, **summaries/**: GITIGNORED (regenerable from code)

Verify gitignore rules:
```bash
# Debug file should be tracked
touch specs/{topic}/debug/test.md
git status specs/{topic}/debug/test.md  # Should show as untracked (not ignored)

# Scripts file should be gitignored
touch specs/{topic}/scripts/test.sh
git status specs/{topic}/scripts/test.sh  # Should show nothing (gitignored)
```

**Cross-Reference Updates**:

When creating artifacts, update cross-references:
1. Debug report → Main plan: `../../{NNN_topic}.md`
2. Summary → Main plan: `../{NNN_topic}.md`
3. Main plan → Reports: `reports/001_report.md`

**Agent Integration Examples**:

For debug report creation during debugging loop:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create debug report using spec-updater patterns"
  prompt: |
    Follow patterns from .claude/agents/spec-updater.md

    Create debug report for test failure in Phase 2.

    Topic: {topic_name} (extracted from plan path)
    Debug Directory: specs/{topic_name}/debug/
    Report Number: Find highest, use next (001, 002, etc.)

    Include metadata linking to:
    - Main plan: ../../{topic_name}.md
    - Phase: Phase 2
    - Iteration: 1

    Template: Follow debug report structure from spec-updater.md
}
```

**Path Calculation Guidelines**:

All artifact paths should be calculated from the topic:
- Extract topic name from plan path: `dirname $PLAN_PATH`
- Ensure subdirectories exist: `mkdir -p $TOPIC_DIR/{debug,scripts,outputs,artifacts}`
- Number artifacts within topic scope: Independent numbering per subdirectory
- Use absolute paths for agent invocations

**Spec-Updater Agent Reference**:
- Agent Definition: `.claude/agents/spec-updater.md`
- Behavioral Guidelines: Artifact creation, cross-reference maintenance, gitignore compliance
- Tools: Read, Write, Edit, Grep, Glob, Bash

---

### Plan Hierarchy Update Integration

The spec-updater agent is responsible for keeping plan hierarchies synchronized as implementation progresses. When plans are expanded using `/expand`, the parent/grandparent spec files must be updated to reflect completion status.

**Integration Points**:
- **`/implement` command**: After each phase completion (Step 5: Plan Update After Git Commit)
- **`/orchestrate` command**: In Documentation Phase after implementation completes

**When to Update**:
- After phase tasks are completed and tests pass
- After git commit is created for the phase
- Before checkpoint save (to ensure state consistency)
- For expanded plan hierarchies (Level 1 and Level 2 structures)

**Skip Conditions**:
- Level 0 plans (single file) - no hierarchy to update
- Plans not using progressive expansion (`/expand`)
- Implementation did not use `/implement` command

#### Plan Hierarchy Structure

Progressive plan structures require different update strategies:

**Level 0** (Single File):
- Format: `specs/{topic}/{topic}.md`
- Update: Direct checkbox updates in single file
- No hierarchy propagation needed

**Level 1** (Phase Expansion):
- Format: `specs/{topic}/{topic}/` directory with phase files
- Files: Main plan + `phase_N_name.md` files
- Update: Stage → Phase → Main plan propagation

**Level 2** (Stage Expansion):
- Format: Nested phase/stage directories
- Files: Main plan + phase directories + stage files
- Update: Stage → Phase → Main plan (3-level propagation)

#### Spec-Updater Invocation Pattern for /implement

After phase completion in `/implement` workflow:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after Phase N completion"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Update plan hierarchy checkboxes after Phase ${PHASE_NUM} completion.

    Plan: ${PLAN_PATH}
    Phase: ${PHASE_NUM}
    All tasks in this phase have been completed successfully.

    Steps:
    1. Source checkbox utilities: source .claude/lib/plan/checkbox-utils.sh
    2. Mark phase complete: mark_phase_complete "${PLAN_PATH}" ${PHASE_NUM}
    3. Verify consistency: verify_checkbox_consistency "${PLAN_PATH}" ${PHASE_NUM}
    4. Report: List all files updated (stage → phase → main plan)

    Expected output:
    - Confirmation of hierarchy update
    - List of updated files at each level
    - Verification that all levels are synchronized
}
```

**Timing**: Invoke after git commit succeeds, before checkpoint save

**Error Handling**:
- If hierarchy update fails: Log error and continue (non-critical for progress)
- User notified in checkpoint that manual sync may be needed
- Include hierarchy_updated: false in checkpoint data

#### Spec-Updater Invocation Pattern for /orchestrate

In Documentation Phase after implementation completes:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after workflow completion"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Update plan hierarchy for completed workflow.

    Plan: ${PLAN_PATH}
    All phases have been completed successfully.

    Steps:
    1. Source checkbox utilities: source .claude/lib/plan/checkbox-utils.sh
    2. Detect structure level: detect_structure_level "${PLAN_PATH}"
    3. For each completed phase: mark_phase_complete "${PLAN_PATH}" ${phase_num}
    4. Verify consistency: verify_checkbox_consistency "${PLAN_PATH}" (all phases)
    5. Report: List all files updated across hierarchy

    Expected output:
    - Confirmation of hierarchy update
    - List of all updated files (stage → phase → main plan)
    - Verification that all levels are synchronized
}
```

**Timing**: After implementation phase completes, before workflow summary generation

**Integration with Workflow Summary**:
Add hierarchy update confirmation to workflow summary:
```markdown
## Plan Hierarchy Status
- Structure Level: [0|1|2]
- All parent plans synchronized: [Yes|No]
- Files updated: [list of plan files updated]
```

#### Checkbox Utilities Integration

The spec-updater agent uses functions from `.claude/lib/plan/checkbox-utils.sh`:

**`mark_phase_complete(plan_path, phase_num)`**:
- Marks all tasks in a phase as complete `[x]`
- Handles Level 0/1/2 plan structures automatically
- Updates both expanded phase file and main plan

**`verify_checkbox_consistency(plan_path, phase_num)`**:
- Verifies checkbox states match across hierarchy levels
- Returns 0 if consistent, 1 if inconsistencies found
- Level 0 always returns 0 (no hierarchy)

**`propagate_checkbox_update(plan_path, phase_num, task_pattern, new_state)`**:
- Updates single checkbox across all hierarchy levels
- Uses fuzzy task matching for flexible updates
- Propagates: Stage → Phase → Main plan

#### Error Handling Patterns

**Hierarchy Update Failure**:
```bash
# After spec-updater agent invocation
if ! check_hierarchy_update_success; then
  warn "Hierarchy update failed - manual sync may be needed"

  # Update checkpoint with failure status
  CHECKPOINT_DATA=$(jq '.hierarchy_updated = false' <<< "$CHECKPOINT_DATA")

  # Continue workflow (non-critical failure)
  continue_workflow
fi
```

**Missing Utilities**:
```bash
# Verify checkbox-utils.sh available
if [ ! -f ".claude/lib/plan/checkbox-utils.sh" ]; then
  error "checkbox-utils.sh not found"
  error "Cannot update plan hierarchy"

  # Skip hierarchy update but continue
  skip_hierarchy_update
fi
```

**Validation Failures**:
```bash
# After verify_checkbox_consistency
if ! verify_checkbox_consistency "$PLAN_PATH" "$PHASE_NUM"; then
  warn "Checkbox inconsistency detected in plan hierarchy"
  warn "Main plan may not reflect phase completion status"

  # Log for manual review
  log_hierarchy_inconsistency "$PLAN_PATH" "$PHASE_NUM"
fi
```

#### Checkpoint Integration

Update checkpoint schema to track hierarchy update status:

```json
{
  "checkpoint_type": "implement",
  "current_phase": 3,
  "completed_phases": [1, 2, 3],

  "hierarchy_updated": true,
  "hierarchy_update_results": {
    "phase_3": {
      "updated_files": [
        "specs/042_auth/phase_3_testing.md",
        "specs/042_auth/042_auth.md"
      ],
      "structure_level": 1,
      "consistency_verified": true
    }
  }
}
```

#### Progress Markers

Use consistent progress markers for hierarchy updates:

```
PROGRESS: Phase 3 complete - updating plan hierarchy...
PROGRESS: Invoking spec-updater agent for hierarchy update
PROGRESS: Plan hierarchy updated successfully
PROGRESS: Files synchronized: phase_3_testing.md → 042_auth.md
PROGRESS: Saving checkpoint with hierarchy update status
```

#### Integration with Shared Utilities

**Dependencies**:
- `.claude/lib/plan/checkbox-utils.sh` - Core checkbox update functions
- `.claude/lib/plan/plan-core-bundle.sh` - Plan structure detection
- `.claude/agents/spec-updater.md` - Agent behavioral guidelines

**Utility Functions Used**:
- `detect_structure_level()` - Identify Level 0/1/2
- `get_plan_directory()` - Find plan directory
- `get_phase_file()` - Get expanded phase file path
- `mark_phase_complete()` - Mark all phase tasks complete
- `verify_checkbox_consistency()` - Validate synchronization

---

## Phase Coordination Patterns

### Research Phase (Parallel Execution)

**Pattern**: Launch multiple research agents concurrently, wait for all to complete, then proceed.

**Key Steps**:
1. Identify 2-4 research topics from workflow description
2. Calculate absolute report paths for each topic
3. Launch ALL research agents in a SINGLE MESSAGE (enables parallelization)
4. Monitor progress with PROGRESS: markers
5. Verify all report files created successfully
6. Proceed to planning phase

**Parallel Invocation Example**:
```
I'll launch 3 research agents in parallel:

[Task tool invocation #1 for existing_patterns]
[Task tool invocation #2 for security_practices]
[Task tool invocation #3 for framework_implementations]
```

**Critical Requirements**:
- All Task invocations must be in ONE message
- Use ABSOLUTE paths for report files
- Verify report files exist before proceeding
- Handle missing reports with retry logic

---

### Planning Phase (Sequential Execution)

**Pattern**: Invoke plan-architect agent to synthesize research into implementation plan.

**Key Steps**:
1. Collect all research report paths from research phase
2. Calculate absolute plan path
3. Invoke plan-architect agent with research reports as input
4. Verify plan file created successfully
5. Parse plan file to validate structure
6. Proceed to implementation phase

**Sequential Requirement**: Planning cannot start until ALL research complete.

---

### Implementation Phase (Adaptive Execution)

**Pattern**: Invoke code-writer agent with /implement command, handle adaptive replanning if needed.

**Key Steps**:
1. Invoke code-writer with plan path and starting phase
2. Monitor implementation progress
3. If tests fail: enter debugging loop (max 3 iterations)
4. If complexity exceeds estimates: adaptive replanning with /revise
5. If successful: proceed to documentation phase

**Adaptive Triggers**:
- Phase complexity >8: Auto-expand phase
- Test failures: Enter debugging loop
- Scope drift: Manual /revise invocation

---

### Debugging Loop (Conditional Execution)

**Pattern**: If implementation tests fail, enter iterative debug-fix loop (max 3 iterations).

**Key Steps**:
1. Detect test failures from implementation phase
2. Invoke debug-specialist agent with failure details
3. Apply recommended fixes via code-writer
4. Re-run tests
5. If tests pass: exit loop and proceed to documentation
6. If tests still fail: increment iteration counter
7. If iteration > 3: escalate to user

**Loop Control**:
- Max 3 iterations enforced
- User escalation if exhausted
- Checkpoint saved at each iteration

---

### Documentation Phase (Sequential Execution)

**Pattern**: Invoke doc-writer agent to create workflow summary and update project documentation.

**Key Steps**:
1. Collect complete workflow_state with all phase results
2. Calculate absolute summary path
3. Invoke doc-writer agent with workflow state
4. Verify summary file created
5. Workflow complete

**Sequential Requirement**: Documentation only runs after implementation fully complete.

---

## Checkpoint Structure

### Workflow Checkpoint Format

Checkpoints enable workflow resumption after interruption.

**Checkpoint File Location**:
```
.claude/checkpoints/orchestrate_[project_name]_[timestamp].json
```

**Checkpoint Structure**:
```json
{
  "checkpoint_type": "orchestrate",
  "created_at": "2025-10-12T14:30:22",
  "workflow_description": "[User's workflow description]",
  "workflow_type": "feature",
  "thinking_mode": "think hard",
  "current_phase": "implementation",
  "completed_phases": ["analysis", "research", "planning"],
  "project_name": "user_authentication_system",

  "context_preservation": {
    "research_reports": [
      "/absolute/path/to/report1.md",
      "/absolute/path/to/report2.md"
    ],
    "plan_path": "/absolute/path/to/plan.md",
    "implementation_status": {
      "tests_passing": false,
      "files_modified": ["file1.lua", "file2.lua"],
      "current_phase": 3,
      "total_phases": 5
    },
    "debug_reports": [],
    "documentation_paths": []
  },

  "execution_tracking": {
    "phase_start_times": {
      "analysis": "2025-10-12T14:30:00",
      "research": "2025-10-12T14:31:00",
      "planning": "2025-10-12T14:38:00",
      "implementation": "2025-10-12T14:45:00"
    },
    "phase_end_times": {
      "analysis": "2025-10-12T14:31:00",
      "research": "2025-10-12T14:38:00",
      "planning": "2025-10-12T14:45:00"
    },
    "agent_invocations": [
      {
        "agent_type": "research-specialist",
        "topic": "existing_patterns",
        "timestamp": "2025-10-12T14:31:00",
        "success": true,
        "report_path": "/absolute/path/to/report1.md"
      }
    ],
    "error_history": [],
    "debug_iteration": 0
  },

  "performance_metrics": {
    "total_duration_seconds": 900,
    "research_parallelization_savings": 120,
    "debug_iterations_used": 0,
    "agents_invoked": 4,
    "files_created": 7
  }
}
```

### Checkpoint Save Operations

**When to Save Checkpoints**:
- After research phase completes
- After planning phase completes
- After each implementation phase
- Before entering debugging loop
- After each debug iteration
- When workflow interrupted

**Checkpoint Save Function**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/workflow/checkpoint-utils.sh"

save_checkpoint "orchestrate" "$(create_checkpoint_json)"
```

### Checkpoint Resume Operations

**Resume Detection**:
```bash
# Check for existing checkpoint
if [ -f .claude/checkpoints/orchestrate_latest.checkpoint ]; then
  echo "Found existing orchestration checkpoint"
  echo "Resume workflow from [current_phase]? (y/n)"
fi
```

**Resume Logic**:
1. Load checkpoint JSON
2. Restore workflow_state from checkpoint
3. Skip completed phases
4. Resume from current_phase
5. Continue workflow normally

---

## Error Recovery Patterns

### Agent Invocation Failure Recovery

**Pattern**: Use retry_with_backoff for automatic recovery from transient failures.

**Implementation**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"

# Define agent invocation function
invoke_research_agent() {
  # Task tool invocation
  return $?
}

# Retry with exponential backoff
if retry_with_backoff invoke_research_agent "research_agent_1"; then
  echo "✓ Agent invocation successful"
else
  # All retries exhausted
  ERROR_TYPE=$(classify_error "$RESULT")
  format_error_report "$ERROR_TYPE" "$RESULT" "research"
  save_checkpoint_and_escalate
fi
```

**Retry Configuration**:
- Max attempts: 3
- Initial delay: 2s
- Backoff multiplier: 2x
- Max delay: 30s

---

### File Verification Failure Recovery

**Pattern**: Verify expected files created, retry if missing.

**Implementation**:
```bash
# After agent completes, verify report file
verify_report_file() {
  local report_path="$1"
  [ -f "$report_path" ] && [ -s "$report_path" ]
}

if ! retry_with_backoff "verify_report_file $EXPECTED_REPORT_PATH"; then
  # File missing after retries
  echo "ERROR: Expected report not created: $EXPECTED_REPORT_PATH"

  # Check if file exists at alternative location
  ALTERNATIVE_PATH=$(find .claude/specs -name "*${TOPIC_SLUG}*.md" -type f 2>/dev/null | head -1)

  if [ -n "$ALTERNATIVE_PATH" ]; then
    echo "Found report at alternative location: $ALTERNATIVE_PATH"
    echo "Using this path instead"
    EXPECTED_REPORT_PATH="$ALTERNATIVE_PATH"
  else
    # Truly missing - retry agent invocation
    echo "Retrying agent invocation..."
    retry_with_backoff invoke_research_agent
  fi
fi
```

---

### Test Failure Recovery

**Pattern**: Enter debugging loop for systematic test failure resolution.

**Implementation**:
```bash
# After implementation phase
if ! tests_passing; then
  DEBUG_ITERATION=0
  MAX_DEBUG_ITERATIONS=3

  while [ $DEBUG_ITERATION -lt $MAX_DEBUG_ITERATIONS ]; do
    DEBUG_ITERATION=$((DEBUG_ITERATION + 1))

    echo "PROGRESS: Entering debugging loop (iteration $DEBUG_ITERATION/$MAX_DEBUG_ITERATIONS)"

    # Invoke debug-specialist
    DEBUG_REPORT=$(invoke_debug_specialist "$TEST_FAILURES")

    # Apply recommended fix
    apply_fix "$DEBUG_REPORT"

    # Re-run tests
    if tests_passing; then
      echo "PROGRESS: Tests passing ✓ - debugging complete"
      break
    fi

    # Save checkpoint after each iteration
    save_checkpoint "orchestrate" "$WORKFLOW_STATE"
  done

  if [ $DEBUG_ITERATION -eq $MAX_DEBUG_ITERATIONS ] && ! tests_passing; then
    echo "ERROR: Debug iterations exhausted, tests still failing"
    save_checkpoint_and_escalate
  fi
fi
```

**Loop Control**:
- Max 3 iterations
- Checkpoint saved each iteration
- User escalation if exhausted

---

### Checkpoint Save Failure Recovery

**Pattern**: Gracefully degrade if checkpoint save fails (non-critical operation).

**Implementation**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/workflow/checkpoint-utils.sh"

if ! save_checkpoint "orchestrate" "$CHECKPOINT_DATA"; then
  # Save failed - warn but continue
  echo "⚠ Warning: Checkpoint save failed"
  echo "Workflow will continue, but resume may not be possible"

  # Log failure for debugging
  log_error "checkpoint_save_failed" "orchestrate" "$CURRENT_PHASE"

  # Continue execution (checkpoint is not critical)
fi
```

**Graceful Degradation**: Workflow continues even if checkpoint fails.

---

## Progress Streaming Patterns

### Progress Marker Format

Use `PROGRESS:` prefix for all progress messages:

```
PROGRESS: [phase] - [action_description]
```

### Phase Transition Progress Markers

```
PROGRESS: Starting Research Phase (parallel execution)
PROGRESS: Research Phase complete - 3 reports created
PROGRESS: Starting Planning Phase (sequential execution)
PROGRESS: Planning Phase complete - plan created
PROGRESS: Starting Implementation Phase (adaptive execution)
PROGRESS: Implementation Phase complete - tests passing
PROGRESS: Starting Documentation Phase (sequential execution)
PROGRESS: Documentation Phase complete - workflow summary generated
```

### Agent Invocation Progress Markers

```
PROGRESS: Invoking 3 research-specialist agents in parallel...
PROGRESS: Research agent 1/3 completed (existing_patterns)
PROGRESS: Research agent 2/3 completed (security_practices)
PROGRESS: Research agent 3/3 completed (framework_implementations)
```

### Debugging Loop Progress Markers

```
PROGRESS: Entering debugging loop (iteration 1/3)
PROGRESS: Invoking debug-specialist agent...
PROGRESS: Debug report created: debug/test_failures/001_auth_timeout.md
PROGRESS: Applying recommended fix via code-writer agent...
PROGRESS: Fix applied - running tests...
PROGRESS: Tests passing ✓ - debugging complete
```

### File Operation Progress Markers

```
PROGRESS: Saving research checkpoint...
PROGRESS: Checkpoint saved: .claude/checkpoints/orchestrate_user_auth_20251012_143022.json
PROGRESS: Verifying report files created...
PROGRESS: All 3 reports verified and readable
```

---

## Usage Notes

### Referencing This File

From `/orchestrate` command:
```markdown
For detailed agent prompt templates, see:
`.claude/templates/orchestration-patterns.md`
```

### Updating Templates

When updating templates:
1. Update this file with new template versions
2. Update `/orchestrate` to reference new templates if structure changes
3. Test templates with sample workflows
4. Document changes in git commit message

### Template Versioning

This file represents the current template standards. Historical templates are preserved in git history.

---

**Last Updated**: 2025-10-13
**Used By**: /orchestrate, /debug, /plan, /implement
**Related Files**:
- `.claude/commands/orchestrate.md`
- `.claude/lib/workflow/checkpoint-utils.sh`
- `.claude/lib/error-utils.sh`
