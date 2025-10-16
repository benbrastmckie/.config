# Phase 3: Planning Phase Refactor - Detailed Specification

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 042_orchestrate_command_execution_refactor.md
- **Dependencies**: Phase 2 (completed)
- **Complexity**: Medium (6/10)
- **Estimated Hours**: 4-5
- **Status**: COMPLETED (100% - 7 of 7 steps done)
- **Target Lines**: 879-1102 of orchestrate.md (~223 lines)
- **Last Updated**: 2025-10-12

## Overview

Transform the Planning Phase from passive documentation to execution-driven instructions with explicit plan-architect agent invocation. This phase is simpler than Research Phase because it involves a single sequential agent invocation rather than parallel execution.

**Current State Analysis** (lines 879-1102):
- Step 1 (lines 881-910): Prepare Planning Context - Descriptive YAML examples
- Step 2 (lines 911-1014): Generate Planning Agent Prompt - Complete inline template (already good)
- Step 3 (lines 1016-1043): Invoke Planning Agent - Has YAML example, needs imperative invocation
- Step 4 (lines 1044-1065): Extract Plan Path and Validation - Basic validation checklist
- Step 5 (lines 1066-1088): Save Planning Checkpoint - Has YAML example, needs inline bash
- Step 6 (lines 1089-1101): Planning Phase Completion - Simple output example

**Key Differences from Research Phase**:
- Single agent (plan-architect) vs multiple parallel agents
- Sequential execution only (no parallelization complexity)
- Shorter workflow (6 steps vs 9 steps in research)
- Less complex monitoring (single agent vs tracking multiple)
- Simpler context preparation (research reports already created)

## Transformation Goals

### Primary Objectives
1. Convert all passive voice to imperative commands
2. Add EXECUTE NOW blocks with explicit tool invocations
3. Inline checkpoint utility usage (replace YAML examples with bash)
4. Enhance validation checklist with verification commands
5. Add complete example showing planning phase execution

### Transformation Pattern (from Phase 2)
- **Passive**: "Extract necessary context from previous phases"
- **Active**: "EXTRACT necessary context from completed research phase"
- **Imperative**: "**EXECUTE NOW**: EXTRACT context from workflow_state.research_reports array"

## Implementation Steps

### Step 1: "Prepare Planning Context" Transformation
**Current** (lines 881-910): Describes context structure with YAML examples
**Target**: Imperative extraction instructions with explicit data access

**Transformations Needed**:
1. Change "Extract necessary context" → "EXTRACT necessary context"
2. Add EXECUTE NOW block with 4-step algorithm
3. Convert YAML examples to imperative extraction commands
4. Add context validation checklist
5. Specify exact data sources (workflow_state.research_reports, user request)

**Complexity**: Low (2/10)
**Lines**: ~30 lines → ~50 lines (add EXECUTE NOW block, validation)

### Step 2: "Generate Planning Agent Prompt" Transformation
**Current** (lines 911-1014): Complete inline prompt template (already well-structured)
**Target**: Minimal changes - add EXECUTE NOW emphasis

**Transformations Needed**:
1. Add EXECUTE NOW block at the beginning
2. Add placeholder substitution instructions (similar to Step 3 in Phase 2)
3. Add prompt verification checklist
4. Keep existing template (already comprehensive)

**Complexity**: Very Low (1/10)
**Lines**: ~103 lines → ~120 lines (add execution emphasis)

**Note**: This step is already mostly imperative with a good inline template. Main work is adding explicit EXECUTE NOW framing.

### Step 3: "Invoke Planning Agent" Transformation
**Current** (lines 1016-1043): YAML example of Task tool invocation, monitoring section
**Target**: Explicit imperative Task tool invocation with JSON structure

**Transformations Needed**:
1. Change YAML example to JSON Task tool structure (consistent with Phase 2)
2. Add "**EXECUTE NOW**: USE the Task tool with these exact parameters"
3. Emphasize single agent execution (vs parallel in research)
4. Keep monitoring section (already good)
5. Add invocation verification checklist

**Complexity**: Low (3/10)
**Lines**: ~28 lines → ~45 lines (add imperative framing, verification)

### Step 4: "Extract Plan Path and Validation" Transformation
**Current** (lines 1044-1065): Path extraction description with basic checklist
**Target**: Explicit extraction algorithm with verification commands

**Transformations Needed**:
1. Add EXECUTE NOW block with 4-step extraction algorithm
2. Add bash verification commands (similar to Phase 2 Step 4)
3. Enhance validation checklist with file structure checks
4. Add retry logic for validation failures
5. Add example plan path extraction

**Complexity**: Medium (4/10)
**Lines**: ~22 lines → ~50 lines (add algorithm, commands, examples)

### Step 5: "Save Planning Checkpoint" Transformation
**Current** (lines 1066-1088): YAML checkpoint examples
**Target**: Inline bash script using checkpoint utilities

**Transformations Needed**:
1. Add EXECUTE NOW block
2. Replace YAML examples with bash script (like Phase 2 Step 5)
3. Inline complete checkpoint utility usage
4. Add checkpoint field explanations
5. Add benefits section (resumability, state preservation)

**Complexity**: Medium (4/10)
**Lines**: ~23 lines → ~55 lines (inline bash, add explanations)

### Step 6: "Planning Phase Completion Message" - NEW STEP
**Current** (lines 1089-1101): Simple output example
**Target**: Comprehensive completion verification and status output

**Transformations Needed**:
1. Add EXECUTE NOW block for status output
2. Add success criteria verification checklist
3. Add detailed status output format
4. Add transition message to implementation phase
5. Add performance metrics (planning time)

**Complexity**: Low (2/10)
**Lines**: ~13 lines → ~40 lines (add verification, metrics)

### Step 7: "Complete Planning Phase Execution Example" - NEW STEP
**Current**: Does not exist
**Target**: End-to-end example showing full planning phase workflow

**Transformations Needed**:
1. Create complete workflow example (similar to Phase 2 Step 7)
2. Show all 6 steps with intermediate data
3. Include actual example plan file path and metadata
4. Show checkpoint contents
5. Show validation checklist completion
6. Demonstrate transition from research → planning → implementation

**Complexity**: Medium (5/10)
**Lines**: 0 lines → ~80 lines (new comprehensive example)

## Testing Requirements

### Unit Testing (Per Step)
Each transformation must maintain:
- Passive → active voice conversion verified
- EXECUTE NOW blocks functional and clear
- Task tool invocation syntactically correct
- Inline bash scripts executable
- Verification checklists complete

### Integration Testing (Full Planning Phase)
Test complete planning phase execution:
1. Use research reports from Phase 2 test outputs
2. Verify plan-architect agent invocation
3. Verify plan file created in correct location
4. Verify plan references all research reports
5. Verify checkpoint saved correctly

**Test Case Structure**:
```bash
test_planning_phase_execution() {
  # Prerequisites: Research phase completed with 3 reports
  RESEARCH_REPORTS=(
    "specs/reports/existing_patterns/001_test.md"
    "specs/reports/security_practices/001_test.md"
    "specs/reports/framework_implementations/001_test.md"
  )

  # Execute planning phase
  # (invoke orchestrate planning section)

  # Verify:
  # 1. Task tool invoked for plan-architect
  # 2. Plan file created: specs/plans/NNN_*.md
  # 3. Plan metadata references all 3 reports
  # 4. Plan includes phases and tasks
  # 5. Checkpoint saved: .claude/checkpoints/orchestrate_*.json
  # 6. Completion message displayed
}
```

### Validation Criteria
- [ ] Context extraction algorithm complete
- [ ] Planning agent invocation uses Task tool explicitly
- [ ] Plan file path extraction verified
- [ ] Checkpoint saved with correct structure
- [ ] All validation checklists functional
- [ ] Complete example demonstrates full workflow

## Implementation Plan

### Sequence (7 Steps Total)

**Step 1: Prepare Planning Context** (lines 881-943)
- Status: COMPLETED
- Complexity: Low
- Actual Lines: 62 lines (added EXECUTE NOW block with 5 steps, context validation checklist)

**Step 2: Generate Planning Agent Prompt** (lines 944-1078)
- Status: COMPLETED
- Complexity: Very Low
- Actual Lines: 135 lines (added EXECUTE NOW block, placeholder instructions, verification checklist)

**Step 3: Invoke Planning Agent** (lines 1080-1111)
- Status: COMPLETED
- Complexity: Low
- Actual Lines: 32 lines (changed YAML to JSON, added EXECUTE NOW emphasis, clarified single-agent execution)

**Step 4: Extract Plan Path and Validation** (lines 1113-1197)
- Status: COMPLETED
- Complexity: Medium
- Actual Lines: 85 lines (added 4-step extraction algorithm, bash validation commands, comprehensive checklist, error handling)

**Step 5: Save Planning Checkpoint** (lines 1199-1270)
- Status: COMPLETED
- Complexity: Medium
- Actual Lines: 72 lines (inlined bash checkpoint script, field explanations, benefits section)

**Step 6: Planning Phase Completion Message** (lines 1272-1325)
- Status: COMPLETED
- Complexity: Low
- Actual Lines: 54 lines (added success criteria verification, comprehensive completion message format, transition confirmation)

**Step 7: Complete Planning Phase Execution Example** (lines 1327-1494)
- Status: COMPLETED
- Complexity: Medium
- Actual Lines: 168 lines (complete end-to-end example with all 6 steps, intermediate data, validation checkpoints)

**Total Actual Lines**: 879-1494 (616 lines, +393 lines growth from original 223 lines)

## Success Criteria

### Transformation Quality
- [ ] All passive voice converted to imperative commands
- [ ] All EXECUTE NOW blocks include clear step-by-step instructions
- [ ] Task tool invocation uses explicit JSON structure
- [ ] Checkpoint utility usage inlined with bash scripts
- [ ] Validation checklists include verification commands
- [ ] Complete example shows full planning phase workflow

### Execution Readiness
- [ ] Instructions can be followed without external references
- [ ] All algorithms are explicit and step-by-step
- [ ] Verification commands are executable
- [ ] Error handling is specified for failures
- [ ] Success criteria are measurable

### Consistency with Phase 2
- [ ] Similar EXECUTE NOW block style
- [ ] Similar verification checklist format
- [ ] Similar example structure (Step 7)
- [ ] Similar inline utility usage (checkpoint bash)
- [ ] Similar imperative language throughout

## Risk Assessment

### Low Risks
- **Simpler than Phase 2**: Single agent vs parallel agents (easier to transform)
- **Template Already Good**: Step 2 prompt template mostly ready (minimal changes)
- **Clear Pattern**: Phase 2 established transformation patterns to follow

### Medium Risks
- **Checkpoint Integration**: Need to inline checkpoint utility correctly (mitigate: use Phase 2 as reference)
- **Validation Completeness**: Ensure plan file validation catches all issues (mitigate: comprehensive checklist)

### Mitigation Strategies
- Follow Phase 2 transformation patterns closely
- Test each step's bash scripts for executability
- Verify verification commands work as expected

## Notes

### Key Differences from Research Phase
1. **No Parallelization**: Single agent execution, simpler monitoring
2. **No Topic Slugs**: No need to generate slugs or multiple invocations
3. **Shorter Workflow**: 6 core steps vs 9 in research phase
4. **Less Context Complexity**: Research reports already exist, just pass paths

### Implementation Approach
1. Follow Phase 2 transformation patterns strictly
2. Reuse successful patterns (EXECUTE NOW blocks, bash inlining, examples)
3. Simplify where appropriate (no parallel complexity needed)
4. Maintain consistency in language and structure

### Estimated Effort
- **Step 1**: 30 minutes (context extraction)
- **Step 2**: 20 minutes (minimal changes to existing template)
- **Step 3**: 30 minutes (Task tool invocation)
- **Step 4**: 45 minutes (extraction algorithm and validation)
- **Step 5**: 45 minutes (checkpoint bash script)
- **Step 6**: 30 minutes (completion message)
- **Step 7**: 60 minutes (comprehensive example)

**Total**: ~4 hours for implementation + 1 hour for testing and plan updates = 5 hours

## Expected Outcomes

After Phase 3 completion:
- Planning phase fully executable with explicit Task tool invocations
- Plan-architect agent invocation clear and repeatable
- Checkpoint management inlined and functional
- Complete validation ensures plan quality
- End-to-end example demonstrates full workflow
- Ready to proceed to Phase 4 (Implementation Phase Refactor)

## Appendix: Before/After Examples

### Example 1: Context Preparation

**BEFORE** (Passive):
```markdown
#### Step 1: Prepare Planning Context

Extract necessary context from previous phases:

**From Research Phase** (if completed):
```yaml
research_context:
  report_paths: [...]
```

**AFTER** (Imperative):
```markdown
#### Step 1: Prepare Planning Context

EXTRACT necessary context from completed workflow phases.

**EXECUTE NOW**:

1. READ workflow_state.research_reports array (if research phase completed)
2. EXTRACT report file paths (do not read content)
3. VERIFY all report files exist and are readable
4. PREPARE context structure for planning agent
```

### Example 2: Agent Invocation

**BEFORE** (Descriptive YAML):
```yaml
**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Create implementation plan..."
prompt: "Read and follow..."
```

**AFTER** (Imperative Task Tool):
```markdown
#### Step 3: Invoke Planning Agent

**EXECUTE NOW**: USE the Task tool to invoke plan-architect agent.

```json
{
  "subagent_type": "general-purpose",
  "description": "Create implementation plan for [feature] using plan-architect protocol",
  "prompt": "Read and follow: .claude/agents/plan-architect.md\n\n[COMPLETE INLINED PROMPT]"
}
```

Send this Task invocation NOW. This is a single-agent execution (sequential, not parallel).
```

### Example 3: Checkpoint Saving

**BEFORE** (YAML Example):
```yaml
**Checkpoint Data**:
```yaml
checkpoint_plan_ready:
  phase_name: "planning"
  outputs:
    plan_path: "..."
```

**AFTER** (Inline Bash):
```markdown
#### Step 5: Save Planning Checkpoint

SAVE workflow checkpoint after planning phase completion.

**EXECUTE NOW**:

USE the checkpoint utility to save planning phase state:

```bash
# Source checkpoint utilities
source .claude/lib/checkpoint-utils.sh

# Prepare checkpoint data
CHECKPOINT_DATA=$(cat <<EOF
{
  "workflow_type": "orchestrate",
  "project_name": "${PROJECT_NAME}",
  "status": "plan_ready",
  "current_phase": "planning",
  "workflow_state": {
    "plan_path": "${PLAN_PATH}",
    "plan_number": "${PLAN_NUMBER}",
    "complexity": "${COMPLEXITY}"
  },
  "next_phase": "implementation"
}
EOF
)

# Save checkpoint
CHECKPOINT_PATH=$(save_checkpoint "orchestrate" "${PROJECT_NAME}" "$CHECKPOINT_DATA")
echo "Checkpoint saved: $CHECKPOINT_PATH"
```
```

These examples demonstrate the transformation approach from passive documentation to imperative execution instructions.
