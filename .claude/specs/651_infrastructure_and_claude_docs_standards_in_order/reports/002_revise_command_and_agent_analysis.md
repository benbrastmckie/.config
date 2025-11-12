# /revise Command and Revision Specialist Agent Analysis

## Metadata
- **Date**: 2025-11-10
- **Agent**: research-specialist
- **Topic**: /revise command implementation, revision specialist agent patterns, /coordinate integration
- **Report Type**: codebase analysis, pattern recognition
- **Complexity Level**: 2

## Executive Summary

The /revise command implements a comprehensive plan/report revision system with dual operation modes (interactive and automated), but does NOT delegate to a specialized revision agent. Instead, /revise executes revision logic directly using Read/Edit/Write tools. This creates an integration opportunity: a revision-specialist agent could be created and invoked from /coordinate's planning phase to handle adaptive replanning, following the established behavioral injection pattern used by research-specialist and plan-architect agents.

## Findings

### 1. /revise Command Architecture

**File**: `.claude/commands/revise.md` (776 lines)

**Key Characteristics**:
- **Direct execution model**: Executes revision operations itself using Read/Edit/Write/Bash tools
- **Dual operation modes**: Interactive (user-driven) and auto-mode (triggered by /implement)
- **No agent delegation**: Unlike /plan, /research, /debug which delegate to specialists
- **Allowed tools**: Read, Write, Edit, Glob, Grep, Task, MultiEdit, TodoWrite, SlashCommand

**Operation Flow** (lines 21-776):

```markdown
STEP 1: Parse arguments and determine mode (interactive vs auto-mode)
  - Interactive: /revise "<revision-details>" [context-paths...]
  - Auto-mode: /revise <plan-path> --auto-mode --context '{JSON}'

STEP 2: Detect and validate artifact (plan or report)
  - Auto-detect from conversation context or explicit path
  - Determine artifact type (plan vs report)
  - Detect plan structure level (L0/L1/L2)

STEP 3: Load research context (optional)
  - Load research report paths if provided
  - Make content available for revision decisions

STEP 4: Create backup (MANDATORY)
  - Backup directory: <artifact-dir>/backups/
  - Timestamped filename: <artifact>_YYYYMMDD_HHMMSS.md
  - Verification checkpoint enforced

STEP 5: Execute revision
  - Auto-mode revision types:
    * expand_phase: Invoke /expand command (line 320-338)
    * add_phase: Insert new phase structure (line 340-368)
    * update_tasks: Modify task lists (line 370-397)
    * collapse_phase: Invoke /collapse command (line 399-416)
  - Interactive mode: Parse natural language, apply edits

STEP 6: Add revision history
  - Update "Revision History" section in artifact
  - Record date, revision type, reason

STEP 7: Verify and return response
  - Auto-mode: Return JSON
  - Interactive: Return text summary
```

**Integration Points with /implement** (lines 736-753):

```markdown
When /implement detects:
- High complexity: Invokes /revise --auto-mode with revision_type=expand_phase
- Test failures: Invokes /revise --auto-mode with revision_type=add_phase
- Scope drift: Invokes /revise --auto-mode with revision_type=update_tasks
```

### 2. Behavioral Injection Pattern Analysis

**Pattern Definition** (`.claude/docs/concepts/patterns/behavioral-injection.md`):

Commands inject context into agents via file reads instead of executing work directly. This enables:
- Clear role separation (orchestrator vs executor)
- Hierarchical multi-agent patterns
- 95% context reduction through metadata-only passing
- Parallel execution of independent agents

**Current /revise Implementation**: Violates behavioral injection pattern

**Evidence**:
- Lines 21-30: /revise acts as EXECUTOR, not orchestrator
- Lines 447-481: Direct use of Read/Edit/Write tools for revision work
- No Task tool invocation to revision-specialist agent
- No metadata extraction or context reduction

**Comparison with /plan Command** (`.claude/commands/plan.md` reference):

```markdown
/plan Command (CORRECT PATTERN):
- Orchestrator role: Calculates paths, validates inputs
- Agent delegation: Invokes plan-architect via Task tool
- Context injection: Passes research reports, standards file
- Metadata return: Receives "PLAN_CREATED: <path>" + metadata

/revise Command (PATTERN VIOLATION):
- Executor role: Performs revision directly
- No agent delegation: Uses Edit tool directly
- No context injection: N/A (not delegating)
- Full response: Returns complete revision details
```

### 3. Agent Invocation Pattern from /coordinate

**File**: `.claude/commands/coordinate.md` (lines 732-760)

**Plan-Architect Invocation Pattern**:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan guided by research reports"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: $WORKFLOW_DESCRIPTION
    - Plan Output Path: $PLAN_PATH (absolute, pre-calculated)
    - Research Reports: ${REPORT_PATHS[@]}
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Topic Directory: $TOPIC_PATH

    **CRITICAL**: Create plan file at EXACT path provided above.

    Execute plan creation following all guidelines in behavioral file.
    Return: PLAN_CREATED: $PLAN_PATH
  "
}
```

**Key Elements**:
1. **Imperative directive**: `**EXECUTE NOW**: USE the Task tool`
2. **Behavioral file reference**: `Read and follow ALL behavioral guidelines from: <agent-file>`
3. **Context injection**: Feature description, paths, research reports
4. **Path pre-calculation**: `$PLAN_PATH` calculated BEFORE agent invocation
5. **Completion signal**: `Return: PLAN_CREATED: $PLAN_PATH`
6. **Verification checkpoint**: Lines 795-845 verify file created

**Research-Specialist Invocation Pattern** (lines 369-402):

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research [topic name] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [actual topic name]
    - Report Path: [REPORT_PATHS[$i-1] for topic $i]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [RESEARCH_COMPLEXITY value]

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
  "
}
```

### 4. Existing Agent Architectures

**Research-Specialist Agent** (`.claude/agents/research-specialist.md`, 671 lines):

**STEP-based execution pattern**:
```markdown
STEP 1: Receive and verify report path
STEP 1.5: Ensure parent directory exists
STEP 2: Create report file FIRST (before research)
STEP 3: Conduct research and update report
STEP 4: Verify and return confirmation
```

**Completion criteria**: 28 criteria (100% compliance required)
**Return format**: `REPORT_CREATED: <absolute-path>`
**Tools allowed**: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash

**Plan-Architect Agent** (`.claude/agents/plan-architect.md`, 895 lines):

**STEP-based execution pattern**:
```markdown
STEP 1: Analyze requirements (research reports, complexity)
STEP 2: Create plan file at provided path
STEP 2.5: Inject progress tracking reminders
STEP 3: Verify plan file created
STEP 4: Return plan path confirmation
```

**Completion criteria**: 42 criteria (100% compliance required)
**Return format**: `PLAN_CREATED: <path> + metadata`
**Tools allowed**: Read, Write, Grep, Glob, WebSearch, Bash

**Plan-Structure-Manager Agent** (`.claude/agents/plan-structure-manager.md`, 200+ lines):

Handles expand/collapse operations for plans (what /revise currently delegates to /expand and /collapse commands).

**Key insight**: This agent could be invoked by a revision-specialist for structural changes.

### 5. Revision Specialist Agent Design Pattern

**Proposed Architecture** (based on existing agents):

```markdown
# Revision Specialist Agent

**File**: `.claude/agents/revision-specialist.md`

**Tools Allowed**: Read, Write, Edit, Bash, Task (for delegating to plan-structure-manager)

**Role**: Execute plan/report revisions with backup creation, revision history tracking, and structural modifications

**STEP 1: Receive and validate revision parameters**
- Artifact path (plan or report)
- Revision type (expand_phase, add_phase, update_tasks, collapse_phase, custom)
- Revision details or JSON context
- Research report paths (optional)

**STEP 2: Create backup FIRST**
- Backup directory: <artifact-dir>/backups/
- Timestamped filename
- Verification checkpoint

**STEP 3: Execute revision based on type**
- expand_phase: Delegate to plan-structure-manager agent
- add_phase: Insert new phase structure
- update_tasks: Modify task lists
- collapse_phase: Delegate to plan-structure-manager agent
- custom: Apply natural language edits

**STEP 4: Update revision history**
- Add entry to "Revision History" section
- Record date, type, reason

**STEP 5: Verify and return confirmation**
- Verify artifact modified successfully
- Return: REVISION_COMPLETED: <artifact-path>

**Completion Criteria**: 35+ criteria similar to research-specialist
```

**Delegation to Plan-Structure-Manager** (for structural changes):

```markdown
# Within revision-specialist agent behavioral file

If revision_type in [expand_phase, collapse_phase]:

Task {
  subagent_type: "general-purpose"
  description: "Execute plan structure operation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/plan-structure-manager.md

    **Operation Context**:
    - Operation: [expand|collapse]
    - Plan path: [absolute path]
    - Item to process: phase [N]
    - Complexity score: [calculated score]
    - Current structure level: [0|1|2]

    Execute structure operation following all guidelines.
    Return: OPERATION_COMPLETED: <artifact-path>
  "
}
```

### 6. /coordinate Integration Points

**Current /coordinate Planning Phase** (lines 687-760):

```markdown
STATE_PLANNING:
  - Path calculation: $PLAN_PATH = "$TOPIC_PATH/plans/<NNN>_implementation.md"
  - Agent invocation: plan-architect
  - Inputs: Research reports, workflow description, standards file
  - Outputs: PLAN_CREATED confirmation, plan file
```

**Proposed Revision Integration** (new state or sub-state):

**Option 1: Add STATE_REVISING** (new state after planning):

```markdown
STATE_REVISING (triggered by complexity analysis):
  - Condition: Plan complexity score >8.0 OR phase count >10
  - Path: Same as plan path (in-place revision)
  - Agent invocation: revision-specialist
  - Inputs: Plan path, revision type (expand_phase), research reports
  - Outputs: REVISION_COMPLETED confirmation
  - Transition: Back to STATE_PLANNING or forward to STATE_IMPLEMENTING
```

**Option 2: Integrate into STATE_IMPLEMENTING** (adaptive replanning):

```markdown
STATE_IMPLEMENTING:
  - Wave execution with complexity monitoring
  - If complexity spike detected: Transition to revision sub-state
  - Invoke revision-specialist with revision_type from complexity analysis
  - Return to wave execution after revision
```

**Integration Pattern** (following behavioral injection):

```markdown
# Within /coordinate command

**EXECUTE NOW**: USE the Task tool to invoke the revision-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on complexity analysis"
  timeout: 180000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/revision-specialist.md

    **Workflow-Specific Context**:
    - Artifact Path: $PLAN_PATH (absolute, pre-calculated)
    - Revision Type: expand_phase
    - Phase Number: 3
    - Reason: Complexity score 9.2 exceeds threshold 8.0
    - Research Reports: ${REPORT_PATHS[@]}
    - Backup Required: true

    **CRITICAL**: Create backup before any modifications.

    Execute revision following all guidelines in behavioral file.
    Return: REVISION_COMPLETED: $PLAN_PATH
  "
}

# Verification checkpoint (MANDATORY)
if [[ ! -f "$PLAN_PATH" ]]; then
  echo "❌ CRITICAL: Revision artifact verification failed"
  echo "   Expected: $PLAN_PATH"
  echo "TROUBLESHOOTING:"
  echo "1. Review revision-specialist agent: .claude/agents/revision-specialist.md"
  echo "2. Check agent invocation parameters above"
  echo "3. Verify backup creation and revision logic"
  handle_state_error "Revision specialist failed to complete operation" 1
fi

echo "✓ Plan revision completed: $PLAN_PATH"
```

### 7. Existing Revision Patterns in Codebase

**Spec 070 - Orchestrate Refactor Revision Summary** (`.claude/specs/070_orchestrate_refactor/plans/001_orchestrate_simplification_REVISION_SUMMARY.md`):

Shows revision workflow for large refactors:
- Research phase produces diagnostic reports
- Planning phase creates initial plan
- Revision phase expands complex phases
- Implementation phase executes wave-based work

**Phase 7 Revision Validation** (`.claude/specs/plans/045_claude_directory_optimization/phase_7_directory_modularization/phase_7_revision_validation.md`):

Validation criteria for revisions:
- Backup creation mandatory
- Revision history updated
- Cross-references maintained
- Structure level consistency

## Recommendations

### 1. Create Revision-Specialist Agent (Priority: HIGH)

**Rationale**: Aligns /revise with behavioral injection pattern, enables /coordinate integration

**Implementation**:
- Create `.claude/agents/revision-specialist.md` following research-specialist template
- Implement STEP 1-5 execution pattern
- Define 35+ completion criteria
- Support all revision types from /revise command
- Delegate to plan-structure-manager for expand/collapse operations

**Acceptance Criteria**:
- Agent file <400 lines (lean execution script)
- 100% file creation reliability (backup + revision)
- Return format: `REVISION_COMPLETED: <artifact-path>`
- All revision types supported (expand_phase, add_phase, update_tasks, collapse_phase, custom)

### 2. Refactor /revise Command to Use Revision-Specialist (Priority: MEDIUM)

**Rationale**: Converts /revise from executor to orchestrator, improves maintainability

**Implementation**:
- Replace STEP 5 (execute revision) with Task tool invocation
- Move revision logic from command to agent behavioral file
- Keep backup creation and path calculation in command (Phase 0)
- Maintain dual operation modes (interactive + auto-mode)

**Before/After Comparison**:

```markdown
# Before (lines 447-481)
STEP 5: Execute revision (direct Edit tool usage)
  - Commands performs revision work itself
  - 150+ lines of revision logic inline

# After
STEP 5: Invoke revision-specialist agent
  - Command delegates to agent via Task tool
  - Agent behavioral file contains revision logic
  - Command orchestrates: path calculation, backup, agent invocation, verification
```

**Benefits**:
- 70% reduction in command file size (776 → ~250 lines)
- Single source of truth for revision logic (agent behavioral file)
- Testable agent isolation (can test revision-specialist independently)
- Consistent with other commands (/plan, /research, /debug)

### 3. Integrate Revision-Specialist into /coordinate (Priority: MEDIUM)

**Rationale**: Enables adaptive replanning during coordination workflows

**Implementation**:
- Add STATE_REVISING to state machine (after planning, before implementing)
- Trigger conditions: Complexity score >8.0, phase count >10, research findings suggest complexity
- Invoke revision-specialist with context from planning phase
- Update plan path after revision (if structure changed)

**State Machine Transition**:

```
STATE_PLANNING → STATE_REVISING (conditional) → STATE_IMPLEMENTING
                      ↓
                 (if no revision needed, skip directly to implementing)
```

**Invocation Pattern**:

```markdown
# Complexity analysis after plan creation
PLAN_COMPLEXITY=$(calculate_plan_complexity "$PLAN_PATH")

if (( $(echo "$PLAN_COMPLEXITY > 8.0" | bc -l) )); then
  echo "Plan complexity ($PLAN_COMPLEXITY) exceeds threshold (8.0)"
  echo "Triggering adaptive revision..."

  transition_state "STATE_REVISING"

  # Invoke revision-specialist
  # (Task tool invocation following behavioral injection pattern)
fi
```

### 4. Create Revision-Specialist Command Guide (Priority: LOW)

**Rationale**: Complete documentation following executable/documentation separation pattern

**Implementation**:
- Create `.claude/docs/guides/revision-specialist-agent-guide.md`
- Document all revision types with examples
- Provide troubleshooting guide for common issues
- Include integration examples (how to invoke from commands)

**Sections**:
- Agent overview and capabilities
- Revision type reference (expand_phase, add_phase, update_tasks, collapse_phase, custom)
- Backup and recovery procedures
- Integration with /coordinate and /implement
- Troubleshooting common failures

### 5. Add Revision Validation to Orchestration Tests (Priority: MEDIUM)

**Rationale**: Ensure revision-specialist reliability and prevent regressions

**Implementation**:
- Create `.claude/tests/test_revision_specialist.sh`
- Test all revision types
- Verify backup creation
- Validate revision history updates
- Check completion signal format

**Test Cases**:
- expand_phase: Verify phase file created, parent updated with marker
- add_phase: Verify new phase inserted, numbering adjusted
- update_tasks: Verify task list modified, checkboxes preserved
- collapse_phase: Verify content merged, file deleted
- backup_creation: Verify timestamped backup in backups/ directory
- revision_history: Verify entry added with date and reason

## References

### Command Files
- `.claude/commands/revise.md` (lines 1-776) - Current /revise implementation
- `.claude/commands/coordinate.md` (lines 732-760, 369-402) - Agent invocation patterns
- `.claude/commands/plan.md` - Comparison reference for behavioral injection

### Agent Files
- `.claude/agents/research-specialist.md` (lines 1-671) - STEP-based agent template
- `.claude/agents/plan-architect.md` (lines 1-895) - Complex agent with completion criteria
- `.claude/agents/plan-structure-manager.md` (lines 1-200) - Structural operation agent

### Pattern Documentation
- `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-1162) - Complete pattern reference
- `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 264-323) - Anti-pattern: Inline template duplication
- `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 495-840) - Case studies (Spec 495, 057)

### Related Specifications
- `.claude/specs/070_orchestrate_refactor/plans/001_orchestrate_simplification_REVISION_SUMMARY.md` - Revision workflow example
- `.claude/specs/plans/045_claude_directory_optimization/phase_7_directory_modularization/phase_7_revision_validation.md` - Validation criteria
- `.claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation/phase_6_integration_testing.md` - Testing patterns

### State Machine Documentation
- `.claude/lib/workflow-state-machine.sh` - State transitions and error handling
- `.claude/docs/architecture/state-based-orchestration-overview.md` - State machine architecture
- `.claude/docs/guides/state-machine-orchestrator-development.md` - Creating new states
