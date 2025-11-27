# Root Cause Analysis: /revise Missing Subagent Delegation

**Research Type**: Root Cause Analysis + Refactoring Plan
**Research Complexity**: 3
**Date**: 2025-11-26
**Status**: Complete

---

## Executive Summary

The `/revise` command currently performs all revision work in the primary orchestrator agent instead of delegating to specialized subagents. This violates the established hierarchical agent architecture used by other orchestrator commands (`/plan`, `/build`) and leads to context preservation issues, reduced modularity, and architectural inconsistency.

**Root Cause**: The `/revise` command lacks `Task` tool invocations entirely. All revision work (reading the plan, analyzing revision details, editing the plan file, updating revision history) is performed inline in the primary agent context.

**Impact**:
- Context exhaustion as plan complexity grows
- No agent specialization or reusability
- Architectural inconsistency with other orchestrators
- Difficult to test and maintain

**Recommended Solution**: Refactor `/revise` to use the established orchestrator pattern with dedicated subagents for research analysis and plan revision, following the patterns established in `/plan` and `/build`.

---

## Table of Contents

1. [Evidence Analysis](#evidence-analysis)
2. [Root Cause Identification](#root-cause-identification)
3. [Architecture Comparison](#architecture-comparison)
4. [Impact Assessment](#impact-assessment)
5. [Refactoring Requirements](#refactoring-requirements)
6. [Implementation Strategy](#implementation-strategy)
7. [Compliance Checklist](#compliance-checklist)

---

## Evidence Analysis

### 1. /revise Output Analysis

From the provided `/home/benjamin/.config/.claude/revise-output.md`, the command execution shows:

**Lines 12-89**: The primary agent directly performs research analysis:
```markdown
● I need to first read the existing plan to understand
  what revisions might be needed...

● Read(.claude/specs/851_001_buffer_opening_integration_plan...)
  ⎿  Read 923 lines

● Now I have a clear understanding of the existing plan.
   The user's concern is about ensuring the hook-based
  buffer opening:
  1. Does NOT add undo cost, overhead, or complexity
  2. Fails elegantly with no issues when running Claude
  Code outside Neovim
```

**Lines 90-220**: The primary agent directly performs plan editing:
```markdown
● Update(.claude/specs/851_001_buffer_opening_integration_pl...)
  ⎿  Updated .claude/specs/851_001_buffer_opening_integ...

● Update(.claude/specs/851_001_buffer_opening_integration_pl...)
  ⎿  Updated .claude/specs/851_001_buffer_opening_integ...
```

**Critical Finding**: No `Task` tool invocations observed. All work performed by the primary orchestrator agent.

### 2. /revise Command Structure Analysis

From `/home/benjamin/.config/.claude/commands/revise.md`:

**Lines 1-14**: Metadata shows dependent agents exist but aren't being used:
```yaml
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
```

**Lines 540-563**: Shows Task tool invocation for research-specialist (Block 4):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights..."
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
    ...
```

**Lines 816-839**: Shows Task tool invocation for plan-architect (Block 5):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan..."
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md
    ...
```

**Critical Finding**: The command file DEFINES subagent invocations but the actual execution (from revise-output.md) shows these Task invocations were never executed. The primary agent bypassed them entirely.

### 3. Comparison with /plan Command

From `/home/benjamin/.config/.claude/commands/plan.md`:

**Lines 577-601**: `/plan` properly delegates research:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
    ...
```

**Lines 864-889**: `/plan` properly delegates planning:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan..."
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md
    ...
```

**Critical Finding**: `/plan` uses identical subagent invocation pattern to what `/revise` DEFINES but doesn't EXECUTE.

### 4. Hierarchical Agent Architecture Standards

From `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md`:

**Lines 66-80**: Defined agent roles:
```markdown
| Role | Purpose | Tools | Invoked By |
|------|---------|-------|------------|
| **Orchestrator** | Coordinates workflow phases | All | User command |
| **Supervisor** | Coordinates parallel workers | Task | Orchestrator |
| **Specialist** | Executes specific tasks | Domain-specific | Supervisor |
```

**Lines 13-33**: Hierarchical supervision principle:
```
Orchestrator Command
    |
    +-- Research Supervisor
    |       +-- Research Agent 1
    |       +-- Research Agent 2
    |
    +-- Implementation Supervisor
            +-- Code Writer
```

**Critical Finding**: `/revise` should be an **Orchestrator** but is currently acting as a **Specialist**, violating the architecture.

---

## Root Cause Identification

### Primary Root Cause: Missing Task Tool Execution Enforcement

The `/revise` command file defines Task tool invocations with the `**EXECUTE NOW**:` directive, but there's no mechanism ensuring Claude actually executes these Task invocations instead of performing the work directly.

**Why This Happens**:

1. **Behavioral Freedom**: Claude agents have agency to choose their approach unless strictly constrained
2. **Shortcut Optimization**: The primary agent sees it can complete the task more "efficiently" by doing the work directly
3. **No Hard Barriers**: The `**EXECUTE NOW**:` directive is a suggestion, not a hard constraint
4. **Context Availability**: The primary agent has access to all tools (Read, Edit, etc.) needed to complete the work

### Contributing Factors

#### 1. Permissive Tool Access

From `/revise` metadata (lines 2):
```yaml
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob, Edit
```

**Problem**: By allowing `Read` and `Edit` tools, the primary agent CAN bypass subagents.

**Contrast with /build** (lines 2):
```yaml
allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob
```

**Note**: `/build` also allows `Read`, yet properly delegates. This suggests the issue is more about COMMAND STRUCTURE than tool permissions alone.

#### 2. Weak Delegation Directives

Current directive in `/revise` (line 541):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.
```

This is suggestive but not enforceable. The agent can interpret "now" as "eventually" or skip it if it finds a direct path.

#### 3. Lack of Explicit Barriers

`/plan` and `/build` have explicit bash blocks BETWEEN major phases that:
- Save state
- Verify artifacts
- Create hard context barriers

`/revise` attempts this but the barriers are weaker.

### Secondary Root Cause: Command Flow Structure

From analyzing the revise-output.md execution:

**Observed Flow**:
```
1. Read plan (primary agent)
2. Analyze revision needs (primary agent)
3. Edit plan multiple times (primary agent)
4. Return completion
```

**Expected Flow** (based on /plan pattern):
```
1. Bash block: Validate inputs, transition to research state
2. Task invocation: Research-specialist analyzes revision needs
3. Bash block: Verify research artifacts, transition to plan state
4. Task invocation: Plan-architect revises plan
5. Bash block: Verify plan updates, transition to complete
6. Completion summary
```

**Critical Difference**: `/revise` lacks the strong state transitions and verification checkpoints that force subagent delegation in `/plan` and `/build`.

---

## Architecture Comparison

### /plan Architecture (Reference Pattern)

```
┌─────────────────────────────────────────────────────────────┐
│ /plan Command (Orchestrator)                                │
├─────────────────────────────────────────────────────────────┤
│ Block 1a: State Initialization                              │
│   • Capture feature description                             │
│   • Initialize state machine                                │
│   • Transition to RESEARCH state                            │
│   • Persist variables                                       │
├─────────────────────────────────────────────────────────────┤
│ Block 1b: Topic Name Generation (Subagent)                  │
│   • Task: topic-naming-agent                                │
│   • Generates semantic directory name                       │
├─────────────────────────────────────────────────────────────┤
│ Block 1c: Topic Path Initialization                         │
│   • Validate agent output                                   │
│   • Initialize workflow paths                               │
│   • Persist paths                                           │
├─────────────────────────────────────────────────────────────┤
│ Block 1d: Research Initiation (Subagent)                    │
│   • Task: research-specialist                               │
│   • Creates research reports                                │
├─────────────────────────────────────────────────────────────┤
│ Block 2: Research Verification + Planning Setup             │
│   • Verify research artifacts exist                         │
│   • Transition to PLAN state                                │
│   • Prepare plan path                                       │
│   • Task: plan-architect (creates plan)                     │
├─────────────────────────────────────────────────────────────┤
│ Block 3: Plan Verification + Completion                     │
│   • Verify plan artifact exists                             │
│   • Transition to COMPLETE                                  │
│   • Display summary                                         │
└─────────────────────────────────────────────────────────────┘
```

**Key Characteristics**:
- 6 distinct blocks
- 3 subagent invocations (topic-naming, research-specialist, plan-architect)
- Hard state transitions between blocks
- Mandatory artifact verification after each subagent
- Clear separation: orchestrator coordinates, specialists execute

### /build Architecture (Reference Pattern)

```
┌─────────────────────────────────────────────────────────────┐
│ /build Command (Orchestrator)                               │
├─────────────────────────────────────────────────────────────┤
│ Block 1: Consolidated Setup                                 │
│   • Parse arguments                                         │
│   • Initialize state machine                                │
│   • Transition to IMPLEMENT                                 │
│   • Task: implementer-coordinator (executes phases)         │
├─────────────────────────────────────────────────────────────┤
│ Iteration Check: Work Remaining Assessment                  │
│   • Check context usage                                     │
│   • Check work remaining                                    │
│   • Prepare continuation if needed                          │
├─────────────────────────────────────────────────────────────┤
│ Phase Update: Mark Completed Phases                         │
│   • Update phase checkboxes                                 │
│   • Verify hierarchy sync                                   │
│   • Fallback: Task: spec-updater if needed                  │
├─────────────────────────────────────────────────────────────┤
│ Testing Phase                                               │
│   • Task: test-executor (runs tests)                        │
├─────────────────────────────────────────────────────────────┤
│ Block 2: Testing Results Verification                       │
│   • Parse test artifact                                     │
│   • Transition to TEST state                                │
│   • Determine next phase                                    │
├─────────────────────────────────────────────────────────────┤
│ Block 3: Conditional Debug or Documentation                 │
│   • If tests failed: Task: debug-analyst                    │
│   • If tests passed: transition to DOCUMENT                 │
├─────────────────────────────────────────────────────────────┤
│ Block 4: Completion                                         │
│   • Transition to COMPLETE                                  │
│   • Display summary                                         │
└─────────────────────────────────────────────────────────────┘
```

**Key Characteristics**:
- 7+ distinct blocks/phases
- 4+ subagent invocations (implementer-coordinator, spec-updater, test-executor, debug-analyst)
- Complex conditional branching
- Iteration support with continuation context
- Comprehensive verification at each phase

### /revise Current Architecture (Non-Compliant)

```
┌─────────────────────────────────────────────────────────────┐
│ /revise Command (Currently Acting as Monolithic Agent)      │
├─────────────────────────────────────────────────────────────┤
│ Block 1: Capture Revision Description                       │
│   • Store user input to temp file                           │
├─────────────────────────────────────────────────────────────┤
│ Block 2: Read and Validate                                  │
│   • Parse revision description                              │
│   • Extract plan path                                       │
│   • Validate flags (--complexity, --file, --dry-run)        │
├─────────────────────────────────────────────────────────────┤
│ Block 3: State Machine Initialization                       │
│   • Initialize workflow state                               │
│   • Transition to RESEARCH (but no enforcement)             │
├─────────────────────────────────────────────────────────────┤
│ Block 4: Research Phase (SUPPOSED TO DELEGATE)              │
│   • ❌ SHOULD Task: research-specialist                     │
│   • ✅ ACTUALLY: Primary agent reads/analyzes directly      │
├─────────────────────────────────────────────────────────────┤
│ Verification (supposed to happen, doesn't)                  │
│   • Should verify research artifacts                        │
│   • Currently skipped                                       │
├─────────────────────────────────────────────────────────────┤
│ Block 5: Plan Revision Phase (SUPPOSED TO DELEGATE)         │
│   • ❌ SHOULD Task: plan-architect                          │
│   • ✅ ACTUALLY: Primary agent edits directly               │
├─────────────────────────────────────────────────────────────┤
│ Verification (supposed to happen, doesn't)                  │
│   • Should verify plan updates                              │
│   • Currently skipped                                       │
├─────────────────────────────────────────────────────────────┤
│ Block 6: Completion                                         │
│   • Display summary                                         │
└─────────────────────────────────────────────────────────────┘
```

**Critical Issues**:
- ❌ Subagent invocations defined but not executed
- ❌ No hard context barriers enforcing delegation
- ❌ Primary agent has all tools needed to bypass subagents
- ❌ No mandatory verification checkpoints
- ❌ State transitions exist but don't enforce phase separation

---

## Impact Assessment

### 1. Context Preservation Impact

**Current Behavior**:
- Primary agent loads full plan content (923 lines in example)
- Primary agent performs multiple edits (5+ Edit invocations in example)
- Primary agent maintains all context throughout
- Estimated token usage: 15,000-25,000 tokens for medium plans

**Projected Behavior with Subagents**:
- Research-specialist: Operates in isolated context (5,000-8,000 tokens)
- Plan-architect: Operates in isolated context (8,000-12,000 tokens)
- Orchestrator: Only handles coordination (2,000-3,000 tokens)
- Context reduction: 40-60%

**Risk for Large Plans**:
- Plans with 2,000+ lines could exhaust context window
- Multiple revision iterations compound the problem
- No continuation mechanism currently exists

### 2. Architectural Consistency Impact

**Current State**: Inconsistency across orchestrator commands

| Command | Delegates Research | Delegates Planning | Delegates Implementation | Delegates Testing |
|---------|-------------------|-------------------|-------------------------|-------------------|
| /plan   | ✅ Yes             | ✅ Yes             | N/A                     | N/A               |
| /build  | N/A               | N/A               | ✅ Yes                   | ✅ Yes             |
| /revise | ❌ No              | ❌ No              | N/A                     | N/A               |

**Developer Confusion**:
- Inconsistent patterns make learning the system harder
- Unclear when to use subagents vs. inline work
- Violates principle of least surprise

### 3. Modularity and Reusability Impact

**Current State**:
- Revision logic embedded in `/revise` command
- Cannot reuse revision capabilities in other workflows
- Plan-architect agent exists but isn't properly integrated

**Ideal State** (with proper delegation):
- Plan-architect agent becomes reusable component
- Other commands can invoke plan revision via plan-architect
- Revision logic centralized in agent behavioral file

**Example Future Use Case**:
```markdown
# In /build command, if scope drift detected:
Task {
  description: "Revise plan for scope expansion"
  prompt: "
    Read and follow: .claude/agents/plan-architect.md
    Operation Mode: plan revision (scope expansion)
    ...
  "
}
```

### 4. Testing and Maintenance Impact

**Current Challenges**:
- Cannot test revision logic in isolation
- Changes to revision behavior require command file updates
- No agent-level test suite for revision capabilities

**With Proper Delegation**:
- Test plan-architect agent independently
- Command file changes don't affect revision logic
- Agent behavioral file becomes single source of truth for revision

---

## Refactoring Requirements

### 1. Preserve Existing Functionality

**Must Maintain**:
- ✅ Revision description parsing (--file, --complexity, --dry-run flags)
- ✅ Backup creation before modifications
- ✅ Revision history tracking
- ✅ State machine integration (research-and-revise workflow)
- ✅ Error logging integration
- ✅ Completion signal format (PLAN_REVISED)

**Must Not Break**:
- ✅ Integration with existing specs directory structure
- ✅ Compatibility with /build command (plan must remain valid)
- ✅ Git workflow (backups gitignored, plan modifications tracked)

### 2. Align with Orchestrator Pattern

**Required Changes**:

#### A. Hard Context Barriers

Add mandatory bash verification blocks between phases:

```bash
# After research-specialist invocation
echo "Verifying research artifacts..."
if [ ! -d "$RESEARCH_DIR" ]; then
  echo "ERROR: Research phase failed to create reports directory" >&2
  exit 1
fi
REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)
if [ "$REPORT_COUNT" -eq 0 ]; then
  echo "ERROR: Research phase failed to create report files" >&2
  exit 1
fi
```

#### B. Mandatory Subagent Invocations

Structure command to make subagent bypass impossible:

```markdown
## Block 4: Research Phase

**EXECUTE NOW**: The following bash block prepares research context.

```bash
# Pre-calculate paths
RESEARCH_DIR="${SPECS_DIR}/reports"
REVISION_TOPIC_SLUG=$(generate_slug "$REVISION_DETAILS")
```

**EXECUTE NOW**: Immediately after bash block, invoke research-specialist.

[Bash block completes → hard boundary]

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights..."
  ...
}

[Task returns → verification required before proceeding]

**EXECUTE NOW**: Verify research completion before proceeding.

```bash
# Verification (failure blocks progression)
if [ ! -f "$EXPECTED_REPORT_PATH" ]; then
  echo "CRITICAL: Research-specialist failed" >&2
  exit 1
fi
```
```

#### C. State Transition Enforcement

Use state machine transitions as hard gates:

```bash
# Transition to research state (blocks if invalid)
sm_transition "$STATE_RESEARCH" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: State transition to RESEARCH failed" >&2
  exit 1
fi

# ... research work ...

# Transition to plan state (blocks if research not complete)
sm_transition "$STATE_PLAN" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "ERROR: State transition to PLAN failed (research incomplete?)" >&2
  exit 1
fi
```

### 3. Conform to .claude/docs/ Standards

**Required Compliance**:

#### A. Error Logging (error-handling.md)

Every bash block must:
```bash
# Source error-handling library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
ensure_error_log_exists
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Log errors when they occur
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Research-specialist failed to create artifacts" \
    "bash_block_4" \
    "$(jq -n --arg dir "$RESEARCH_DIR" '{expected_dir: $dir}')"
fi
```

#### B. Code Standards (code-standards.md)

**Three-Tier Library Sourcing**:
```bash
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true
```

#### C. Output Formatting (output-formatting.md)

**Suppress Library Sourcing**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

**Consolidated Bash Blocks**: Target 2-3 blocks per phase (Setup/Execute/Cleanup)

**Console Summary Format**:
```bash
# Use standardized 4-section format
print_artifact_summary "Revise" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"
```

#### D. Hierarchical Agent Architecture (hierarchical-agents-overview.md)

**Metadata-Only Context Passing**:
```markdown
# In orchestrator (after research-specialist returns)
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_COUNT=$(echo "$REPORT_PATHS" | wc -l)

# Pass to plan-architect as metadata, not full content
Task {
  prompt: "
    Research Reports: ${REPORT_COUNT} files in ${RESEARCH_DIR}
    [DO NOT include full report content in prompt]
  "
}
```

**Single Source of Truth**: Reference agent behavioral files, don't duplicate:
```markdown
# WRONG
Task {
  prompt: "
    You are a plan revision specialist. Follow these steps:
    [50+ lines of behavioral instructions]
  "
}

# CORRECT
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    Operation Mode: plan revision
    [Workflow-specific context only]
  "
}
```

---

## Implementation Strategy

### Phase 1: Prepare Subagent Infrastructure

**Prerequisites** (Verify before starting):
1. ✅ `research-specialist.md` agent exists and is tested
2. ✅ `plan-architect.md` agent exists
3. ❓ Plan-architect supports "plan revision" operation mode
4. ❓ Research-specialist can handle "revision insights" research type

**Tasks**:
1. **Audit plan-architect.md** for revision mode support
   - Check if agent distinguishes "new plan creation" vs "plan revision"
   - Verify agent uses Edit tool (not Write) for revisions
   - Ensure agent preserves completed phases marked [COMPLETE]

2. **Enhance plan-architect.md** if needed
   - Add operation mode detection: "new plan creation" | "plan revision"
   - Add revision-specific instructions (backup verification, history updates)
   - Add completion signal variation: PLAN_CREATED vs PLAN_REVISED

3. **Create test fixtures** for revision scenarios
   - Small plan (5 phases, 500 lines)
   - Medium plan (10 phases, 1,000 lines)
   - Large plan (20 phases, 2,000 lines)
   - Plan with completed phases (test preservation)

### Phase 2: Refactor Command Structure

**Block-by-Block Refactoring**:

#### Block 1-3: No Major Changes
- ✅ Keep argument capture logic
- ✅ Keep validation logic
- ✅ Keep state machine initialization
- ⚠️ Add clearer state transition enforcement

#### Block 4: Research Phase - Major Refactoring

**Current** (lines 385-655):
```markdown
## Block 4: Research Phase Execution

**EXECUTE NOW**: Transition to research state and prepare research directory:

[Single bash block that transitions, prepares paths, invokes agent, and verifies]
```

**Refactored** (3 distinct blocks with hard barriers):

```markdown
## Block 4a: Research Phase Setup

**EXECUTE NOW**: Transition to research state and prepare research directory.

```bash
set +H  # CRITICAL: Disable history expansion
# ... sourcing libraries ...

# Transition to research state (hard gate)
sm_transition "$STATE_RESEARCH" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  log_command_error "state_error" "State transition to RESEARCH failed" ...
  echo "ERROR: Cannot proceed without valid state transition" >&2
  exit 1
fi

# Pre-calculate research paths
SPECS_DIR=$(dirname "$(dirname "$EXISTING_PLAN_PATH")")
RESEARCH_DIR="${SPECS_DIR}/reports"
REVISION_TOPIC_SLUG=$(echo "$REVISION_DETAILS" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | cut -c1-30)

# Persist for verification block
append_workflow_state "RESEARCH_DIR" "$RESEARCH_DIR"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "REVISION_TOPIC_SLUG" "$REVISION_TOPIC_SLUG"

echo "Research directory: $RESEARCH_DIR"
echo "Ready for research-specialist invocation"
```

## Block 4b: Research Execution

**CRITICAL**: The following Task invocation MUST complete before proceeding.
The verification block will FAIL if research-specialist does not create artifacts.

**EXECUTE NOW**: USE the Task tool to invoke research-specialist.

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: revise workflow

    **Workflow-Specific Context**:
    - Research Topic: Plan revision insights for: ${REVISION_DETAILS}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-revise
    - Existing Plan: ${EXISTING_PLAN_PATH}

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}

## Block 4c: Research Verification

**EXECUTE NOW**: Verify research artifacts were created (MANDATORY).

```bash
set +H  # CRITICAL: Disable history expansion
# ... sourcing libraries ...
# ... load workflow state ...

# MANDATORY VERIFICATION (fail-fast pattern)
echo "Verifying research artifacts..."

if [ ! -d "$RESEARCH_DIR" ]; then
  log_command_error "file_error" "Research phase failed to create reports directory" ...
  echo "ERROR: Research phase failed" >&2
  echo "EXPECTED: $RESEARCH_DIR" >&2
  exit 1
fi

REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' -type f -newer "$EXISTING_PLAN_PATH" 2>/dev/null | wc -l)
if [ "$REPORT_COUNT" -eq 0 ]; then
  log_command_error "validation_error" "Research phase created no reports" ...
  echo "ERROR: Research-specialist created no reports" >&2
  exit 1
fi

TOTAL_REPORT_COUNT=$(find "$RESEARCH_DIR" -name '*.md' 2>/dev/null | wc -l)

# CHECKPOINT REPORTING
echo ""
echo "CHECKPOINT: Research phase complete"
echo "- New reports: $REPORT_COUNT"
echo "- Total reports: $TOTAL_REPORT_COUNT"
echo "- All files verified: ✓"
echo "- Proceeding to: Plan revision phase"
echo ""

# Persist for next phase
append_workflow_state "REPORT_COUNT" "$REPORT_COUNT"
append_workflow_state "TOTAL_REPORT_COUNT" "$TOTAL_REPORT_COUNT"
save_completed_states_to_state
```
```

**Key Changes**:
- Split into 3 blocks (Setup → Execute → Verify)
- Hard context barrier between blocks (bash → Task → bash)
- Fail-fast verification with detailed error logging
- Checkpoint reporting for visibility
- Impossible to bypass research-specialist invocation

#### Block 5: Plan Revision Phase - Major Refactoring

**Similar 3-block pattern**:
- Block 5a: Plan Revision Setup (create backup, transition state)
- Block 5b: Plan Revision Execution (Task: plan-architect)
- Block 5c: Plan Revision Verification (verify plan updated, backup exists)

**Critical Addition** (in Block 5a):
```bash
# Create backup BEFORE invoking plan-architect
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(dirname "$EXISTING_PLAN_PATH")/backups"
BACKUP_FILENAME="$(basename "$EXISTING_PLAN_PATH" .md)_${TIMESTAMP}.md"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

mkdir -p "$BACKUP_DIR"
cp "$EXISTING_PLAN_PATH" "$BACKUP_PATH"

# FAIL-FAST BACKUP VERIFICATION
if [ ! -f "$BACKUP_PATH" ]; then
  echo "ERROR: Backup creation failed at $BACKUP_PATH" >&2
  exit 1
fi
FILE_SIZE=$(wc -c < "$BACKUP_PATH")
if [ "$FILE_SIZE" -lt 100 ]; then
  echo "ERROR: Backup file too small ($FILE_SIZE bytes)" >&2
  exit 1
fi

echo "✓ Backup created: $BACKUP_PATH"
append_workflow_state "BACKUP_PATH" "$BACKUP_PATH"
```

#### Block 6: Completion - Minor Refactoring

**Add**:
- Summary formatting using `print_artifact_summary`
- Clearer next steps for user
- State file cleanup

### Phase 3: Testing Strategy

**Unit Tests** (agent-level):
```bash
# Test plan-architect in revision mode
.claude/tests/agents/test_plan_architect_revision_mode.sh

# Test research-specialist for revision insights
.claude/tests/agents/test_research_specialist_revision.sh
```

**Integration Tests** (command-level):
```bash
# Test /revise with small plan
.claude/tests/commands/test_revise_small_plan.sh

# Test /revise with completed phases (verify preservation)
.claude/tests/commands/test_revise_preserve_completed.sh

# Test /revise with --file flag
.claude/tests/commands/test_revise_long_prompt.sh

# Test /revise error recovery (backup restoration)
.claude/tests/commands/test_revise_error_recovery.sh
```

**Regression Tests**:
```bash
# Verify existing /revise behavior preserved
# Compare before/after outputs for same inputs
.claude/tests/regression/test_revise_behavioral_compatibility.sh
```

### Phase 4: Documentation Updates

**Files Requiring Updates**:

1. `.claude/commands/revise.md`
   - Update command structure documentation
   - Add troubleshooting for subagent failures
   - Document new block structure

2. `.claude/agents/plan-architect.md`
   - Document operation mode: "plan revision"
   - Add revision-specific behavioral guidelines
   - Document completion signals (PLAN_REVISED vs PLAN_CREATED)

3. `.claude/docs/guides/commands/revise-command-guide.md`
   - Update workflow diagrams
   - Add subagent interaction examples
   - Document error recovery procedures

4. `.claude/docs/concepts/hierarchical-agents-examples.md`
   - Add /revise as hierarchical orchestrator example
   - Show research → planning delegation pattern

### Phase 5: Rollout Plan

**Step 1: Create Branch**
```bash
git checkout -b feature/revise-subagent-delegation
```

**Step 2: Implement Incrementally**
1. Update plan-architect.md (revision mode support)
2. Refactor /revise Block 4 (research phase)
3. Test research phase in isolation
4. Refactor /revise Block 5 (planning phase)
5. Test planning phase in isolation
6. Integration testing
7. Documentation updates

**Step 3: Validation Checkpoints**
- After each step, run test suite
- Manually test with real plans (small → medium → large)
- Verify error logging integration
- Check state machine transitions

**Step 4: Peer Review**
- Review agent behavioral files
- Review command structure changes
- Review test coverage

**Step 5: Merge**
```bash
# Ensure all tests pass
bash .claude/scripts/validate-all-standards.sh --all
pytest .claude/tests/

# Create PR
gh pr create --title "Refactor /revise for subagent delegation" \
  --body "Aligns /revise with hierarchical orchestrator pattern used by /plan and /build"
```

---

## Compliance Checklist

### Hierarchical Agent Architecture

- [ ] Orchestrator delegates to specialized agents (no inline work)
- [ ] Supervisor-worker pattern used where appropriate
- [ ] Metadata-only context passing (no full content between levels)
- [ ] Single source of truth (agent behavioral files referenced, not duplicated)
- [ ] Pre-calculation pattern used (paths calculated before subagent invocation)

### Code Standards

- [ ] Three-tier library sourcing in all bash blocks
- [ ] Fail-fast error handling with exit 1
- [ ] Error logging integration (log_command_error)
- [ ] Preprocessing-safe conditional patterns
- [ ] Output suppression (2>/dev/null while preserving errors)

### Output Formatting

- [ ] Library sourcing suppressed (2>/dev/null)
- [ ] Consolidated bash blocks (2-3 per phase)
- [ ] Single summary line per block
- [ ] Console summary uses 4-section format
- [ ] Comments describe WHAT, not WHY

### State-Based Orchestration

- [ ] State machine transitions used as hard gates
- [ ] State transitions verified with exit code checks
- [ ] Workflow state persisted across blocks
- [ ] State restoration validated before use
- [ ] Idempotent state transitions (safe retry/resume)

### Error Logging

- [ ] Error-handling library sourced in all blocks
- [ ] Bash error trap set up (setup_bash_error_trap)
- [ ] All failures logged with log_command_error
- [ ] Error types correctly categorized
- [ ] Error details provided as JSON

### Testing Protocols

- [ ] Unit tests for agents exist
- [ ] Integration tests for command exist
- [ ] Regression tests verify behavioral compatibility
- [ ] Test coverage > 80%
- [ ] Error paths tested

### Documentation Standards

- [ ] Command guide updated with new structure
- [ ] Agent behavioral files updated
- [ ] Examples added to hierarchical-agents-examples.md
- [ ] Troubleshooting section comprehensive
- [ ] No historical commentary in docs

---

## Appendix A: File Modification Checklist

### Files to Modify

1. **`.claude/commands/revise.md`** (Primary changes)
   - Restructure Block 4 (research phase) into 3 sub-blocks
   - Restructure Block 5 (planning phase) into 3 sub-blocks
   - Add verification checkpoints
   - Update error handling

2. **`.claude/agents/plan-architect.md`** (Enhancement)
   - Add operation mode detection
   - Add revision-specific guidelines
   - Update completion signals

3. **`.claude/agents/research-specialist.md`** (Minor updates)
   - Verify revision insights research type supported
   - Add examples for revision research

4. **`.claude/docs/guides/commands/revise-command-guide.md`** (Documentation)
   - Update workflow diagrams
   - Add subagent examples
   - Document error recovery

5. **`.claude/docs/concepts/hierarchical-agents-examples.md`** (Documentation)
   - Add /revise example

### Files to Create

1. **`.claude/tests/commands/test_revise_subagent_delegation.sh`**
   - Test research-specialist invocation
   - Test plan-architect invocation
   - Verify artifacts created

2. **`.claude/tests/agents/test_plan_architect_revision_mode.sh`**
   - Test revision mode specifically
   - Verify backup preservation
   - Verify Edit tool usage

### Files to Review (No Changes Expected)

1. `.claude/lib/core/error-handling.sh` (verify compliance)
2. `.claude/lib/workflow/workflow-state-machine.sh` (verify state transitions)
3. `.claude/lib/core/state-persistence.sh` (verify persistence patterns)

---

## Appendix B: Risk Mitigation

### Risk 1: Behavioral Regression

**Risk**: Refactored /revise behaves differently than original

**Mitigation**:
1. Comprehensive regression test suite
2. Side-by-side comparison testing (old vs new)
3. Feature flag for gradual rollout
4. Backup/rollback plan

**Rollback Procedure**:
```bash
git revert <refactor-commit>
git push origin main
# Notify users via changelog
```

### Risk 2: Subagent Failures

**Risk**: Research-specialist or plan-architect fail unpredictably

**Mitigation**:
1. Comprehensive agent testing before integration
2. Detailed error logging with recovery hints
3. Fallback mechanism (manual intervention documented)
4. Timeout handling (Task tool timeout parameter)

**Fallback Documentation**:
```markdown
If research-specialist fails:
1. Check error log: /errors --command /revise --type agent_error
2. Verify research directory exists: ls -la $RESEARCH_DIR
3. Manual workaround: Create research report manually, re-run /revise
```

### Risk 3: Context Exhaustion

**Risk**: Even with subagents, large plans exhaust context

**Mitigation**:
1. Plan-architect should handle plans of any size (iterative approach)
2. Document maximum recommended plan size
3. Add --max-size flag for validation
4. Future enhancement: chunked plan processing

**Size Limits** (recommended):
- Small plans: < 1,000 lines (safe)
- Medium plans: 1,000-2,000 lines (monitored)
- Large plans: > 2,000 lines (warning, suggest splitting)

### Risk 4: Integration Breakage

**Risk**: Changes break integration with /plan or /build

**Mitigation**:
1. Integration tests across all orchestrators
2. Shared agent testing (research-specialist, plan-architect)
3. Review agent contracts (input/output formats)
4. Staged rollout (test in isolation first)

---

## Appendix C: Success Metrics

### Quantitative Metrics

1. **Context Reduction**
   - Target: 40-60% reduction in orchestrator context usage
   - Measure: Token count before/after for same plan
   - Success: < 5,000 tokens for orchestrator on medium plan

2. **Execution Time**
   - Target: No significant regression (< 10% increase)
   - Measure: Time from invocation to completion
   - Success: Median execution time within 10% of baseline

3. **Reliability**
   - Target: 100% artifact creation success rate
   - Measure: Test suite pass rate
   - Success: 0 failures in 100 test runs

4. **Error Recovery**
   - Target: Clear error messages with recovery steps
   - Measure: User survey or manual review
   - Success: All errors include actionable recovery steps

### Qualitative Metrics

1. **Code Maintainability**
   - Clear separation of concerns (orchestrator vs specialists)
   - Agent behavioral files as single source of truth
   - Easy to add new revision types

2. **Developer Experience**
   - Consistent patterns across all orchestrators
   - Predictable behavior
   - Clear documentation

3. **Extensibility**
   - Easy to add new subagents
   - Easy to modify revision logic (agent file only)
   - Easy to integrate with future workflows

---

## Conclusion

The `/revise` command currently violates the hierarchical agent architecture by performing all work in the primary orchestrator agent instead of delegating to specialized subagents. This creates context preservation issues, architectural inconsistency, and maintainability challenges.

**Recommended Action**: Refactor `/revise` to match the orchestrator pattern established by `/plan` and `/build`, with mandatory subagent delegation enforced through hard context barriers (bash verification blocks between phases).

**Expected Benefits**:
- 40-60% reduction in orchestrator context usage
- Architectural consistency across all orchestrator commands
- Improved modularity and reusability
- Better testability and maintainability
- Compliance with .claude/docs/ standards

**Implementation Complexity**: Medium (3-5 days)
- Phase 1: Prepare subagent infrastructure (1 day)
- Phase 2: Refactor command structure (2 days)
- Phase 3: Testing (1 day)
- Phase 4: Documentation (1 day)

**Next Steps**: Create implementation plan in `.claude/specs/950_revise_refactor_subagent_delegation/plans/` using this research report as primary input.

---

**Report Metadata**:
- Report Path: /home/benjamin/.config/.claude/specs/950_revise_refactor_subagent_delegation/reports/001_revise_subagent_delegation_root_cause_analysis.md
- Lines: 1400+
- Sections: 9 major + 3 appendices
- References: 8 source files analyzed
- Completion Signal: REPORT_CREATED
