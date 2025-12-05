# Research Report: /lean-plan Command Subagent Delegation Pattern Refactoring

## Metadata
- **Date**: 2025-12-04
- **Agent**: research-specialist
- **Topic**: Refactor /lean-plan to use proper subagent delegation pattern
- **Report Type**: Command refactoring analysis
- **Complexity**: 3

## Executive Summary

The /lean-plan command currently performs most work inline in the main conversation (74.2k tokens for Explore, many direct Read calls) instead of delegating to specialized subagents. This research analyzes the current implementation against the /create-plan reference pattern to identify required changes for adopting the Hard Barrier Pattern with proper subagent delegation. Key findings: lean-research-specialist and lean-plan-architect agents exist but are not invoked correctly; the command requires restructuring Block 1e (research) and Block 2 (planning) to use Task tool invocations with pre-calculated output paths.

## Current State Analysis

### /lean-plan Implementation Issues

**File**: `/home/benjamin/.config/.claude/commands/lean-plan.md`

**Problem Evidence from lean-plan-output.md**:
- Lines 75-103: Primary agent performs large Explore operation (74.2k tokens)
- Lines 44-104: Main conversation has extensive Read calls and research directly
- Lines 119-124: Only one brief Explore subagent call before main agent takes over
- Block 1e (lines 819-853): Uses inline Task invocation but agent does most work in main context

**Current Block 1e (Research Initiation)**:
```markdown
## Block 1e: Research Initiation

**EXECUTE NOW**: USE the Task tool to invoke the lean-research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with Mathlib discovery and proof pattern analysis"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md

    You are conducting Lean formalization research for: lean-plan workflow

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan (Lean specialization)
    - Lean Project Path: ${LEAN_PROJECT_PATH}
    ...
```

**Issue**: Block 1e does NOT pre-calculate the report path before Task invocation. It only passes `Output Directory` (directory, not file path), violating the Hard Barrier Pattern.

**Current Block 2 (Planning)**:
```markdown
## Block 2: Research Verification and Planning Setup

**EXECUTE NOW**: Verify research artifacts and prepare for planning:

```bash
# Large bash block (lines 859-1192)
# Verifies research, transitions state, prepares plan path
# THEN invokes lean-plan-architect inline
```

**EXECUTE NOW**: USE the Task tool to invoke the lean-plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan for ${FEATURE_DESCRIPTION}..."
  prompt: "
    ...
    **Output Path**: ${PLAN_PATH}
    ...
```

**Issue**: Block 2 calculates PLAN_PATH inline (line 1116-1118) but does NOT follow Hard Barrier Pattern - path calculation happens inside same block as Task invocation, not in separate pre-calculation block.

### /create-plan Reference Pattern (Correct Implementation)

**File**: `/home/benjamin/.config/.claude/commands/create-plan.md`

**Block 1b: Topic Name File Path Pre-Calculation** (lines 272-396):
```bash
# === PRE-CALCULATE TOPIC NAME FILE PATH ===
# CRITICAL: Calculate exact path BEFORE agent invocation (Hard Barrier Pattern)
# This path will be passed as literal text to the agent and validated after
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"

# Validate path is absolute
if [[ "$TOPIC_NAME_FILE" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error ...
  exit 1
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$TOPIC_NAME_FILE")" 2>/dev/null || true

# Persist for Block 1b-exec and Block 1c
append_workflow_state "TOPIC_NAME_FILE" "$TOPIC_NAME_FILE" || {
  echo "export TOPIC_NAME_FILE=\"$TOPIC_NAME_FILE\"" >> "$STATE_FILE"
}
```

**Block 1b-exec: Topic Name Generation (Hard Barrier Invocation)** (lines 398-429):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for semantic topic directory naming.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /create-plan command

    **Input Contract (Hard Barrier Pattern)**:
    - Output Path: ${TOPIC_NAME_FILE}
    - User Prompt: ${FEATURE_DESCRIPTION}
    - Command Name: /create-plan

    **CRITICAL**: You MUST write the topic name to the EXACT path specified above.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.
    ...
```

**Block 1c: Hard Barrier Validation** (lines 431-539):
```bash
# === HARD BARRIER VALIDATION ===
# Validate TOPIC_NAME_FILE is set (from Block 1b)
if [ -z "${TOPIC_NAME_FILE:-}" ]; then
  log_command_error ...
  exit 1
fi

echo "Expected topic name file: $TOPIC_NAME_FILE"

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (10 bytes)
if ! validate_agent_artifact "$TOPIC_NAME_FILE" 10 "topic name"; then
  # Error already logged by validate_agent_artifact
  echo "ERROR: HARD BARRIER FAILED - Topic naming agent validation failed" >&2
  ...
```

**Block 1d: Research Initiation** (lines 849-875):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are conducting research for: plan workflow

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Directory: ${RESEARCH_DIR}
    - Workflow Type: research-and-plan
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), read it for complete context.

    Execute research according to behavioral guidelines and return completion signal:
    REPORT_CREATED: [path to created report]
  "
}
```

**Note**: /create-plan Block 1d also does NOT follow Hard Barrier Pattern for research-specialist! It passes `Output Directory` instead of pre-calculated report path. This is a discrepancy in the reference implementation itself.

**Block 2: Research Verification and Planning Setup** (lines 877-1199):
- Lines 1063-1113: Verifies research artifacts in bash block
- Lines 1135-1150: Pre-calculates PLAN_PATH within same bash block
- Lines 1201-1265: Separate Task invocation block for plan-architect

**Observation**: /create-plan also doesn't fully separate path pre-calculation from Task invocation for planning phase. The PLAN_PATH is calculated in Block 2 bash (lines 1135-1150), then immediately used in Task prompt (lines 1201-1265).

### Existing Agent Infrastructure

**lean-research-specialist.md** (`/home/benjamin/.config/.claude/agents/lean-research-specialist.md`):

**Lines 24-62 (STEP 1)**: Agent expects absolute report path
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with:
1. An absolute report path (pre-calculated by orchestrator)
2. Lean project path (for local theorem search)
3. Feature description (formalization goal)
4. Research complexity level (1-4)

Verify you have received these inputs:

```bash
# These values are provided by the invoking command in your prompt
# Example: REPORT_PATH="/home/user/.claude/specs/067_topic/reports/001_mathlib.md"
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"
LEAN_PROJECT_PATH="[PATH PROVIDED IN YOUR PROMPT]"
FEATURE_DESCRIPTION="[DESCRIPTION PROVIDED IN YOUR PROMPT]"
RESEARCH_COMPLEXITY="[LEVEL PROVIDED IN YOUR PROMPT]"
```

**CHECKPOINT**: YOU MUST have absolute paths and Lean project before proceeding to Step 2.
```

**Issue**: lean-research-specialist.md expects `REPORT_PATH` (absolute file path), but /lean-plan Block 1e provides `Output Directory` (directory only).

**lean-plan-architect.md** (`/home/benjamin/.config/.claude/agents/lean-plan-architect.md`):

**Lines 108-205 (STEP 2)**: Agent expects pre-calculated PLAN_PATH
```markdown
### STEP 2 (REQUIRED BEFORE STEP 3) - Create Plan File Directly

**EXECUTE NOW - Create Lean Plan at Provided Path**

**ABSOLUTE REQUIREMENT**: YOU MUST create the plan file at the EXACT path provided in your prompt. This is NOT optional.

**WHY THIS MATTERS**: The calling command (/lean-plan) has pre-calculated the topic-based path following directory organization standards. You MUST use this exact path for proper artifact organization.

**Plan Creation Pattern**:
1. **Receive PLAN_PATH**: The calling command provides absolute path in your prompt
   - Format: `specs/{NNN_topic}/plans/{NNN}_plan.md`
   - Example: `specs/067_group_homomorphism/plans/001-group-homomorphism-plan.md`

2. **Create Plan File**: Use Write tool to create plan at EXACT path provided
   - DO NOT calculate your own path
   - DO NOT modify the provided path
   - USE Write tool with absolute path from prompt
```

**Observation**: lean-plan-architect.md correctly expects PLAN_PATH to be pre-calculated and provided.

**research-specialist.md** (`/home/benjamin/.config/.claude/agents/research-specialist.md`):

**Lines 24-51 (STEP 1)**: Generic research agent also expects absolute report path
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with an absolute report path. This path is **pre-calculated** by the orchestrator as part of the [Hard Barrier Pattern](...). Verify you have received it:

```bash
# This path is provided by the invoking command in your prompt
# Example: REPORT_PATH="/home/user/.claude/specs/067_topic/reports/001_patterns.md"
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"

# CRITICAL: Verify path is absolute
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: Path is not absolute: $REPORT_PATH"
  exit 1
fi

echo "VERIFIED: Absolute report path received: $REPORT_PATH"
```

**IMPORTANT FOR CALLING COMMANDS**: The `/research` command is the canonical example of proper invocation. Commands MUST:
1. Pre-calculate `REPORT_PATH` before Task invocation (Block 1d)
2. Pass `REPORT_PATH` in the Task prompt as a contract
3. Validate `REPORT_PATH` file exists after Task returns (Block 1e)
```

### Performance Benefits of Subagent Delegation

**From lean-plan-output.md analysis**:
- **Current context usage**: 74.2k tokens for Explore operation (lines 75-103)
- **Current pattern**: Main agent does Read, Grep, WebSearch directly
- **Result**: Heavy main conversation context, no parallelization opportunity

**Expected benefits with proper delegation**:
1. **Parallel execution**: Research and topic naming can run concurrently (not currently utilized)
2. **Reduced main context**: Subagents handle heavy lifting (research specialist does Read/Grep/WebSearch)
3. **Better error isolation**: Subagent failures don't pollute main context with 74k tokens
4. **Structured artifact creation**: Validated file outputs with predictable paths

## Comparison Matrix: /create-plan vs /lean-plan

| Aspect | /create-plan (Reference) | /lean-plan (Current) | Required Change |
|--------|--------------------------|----------------------|-----------------|
| **Block 1b structure** | Pre-calculate topic name path | Pre-calculate topic name path | ✓ Already correct |
| **Block 1b-exec** | Task invocation with TOPIC_NAME_FILE | Task invocation with TOPIC_NAME_FILE | ✓ Already correct |
| **Block 1c validation** | Hard barrier validation | Hard barrier validation | ✓ Already correct |
| **Block 1d structure** | NO pre-calculation (passes directory) | NO pre-calculation (passes directory) | ❌ Both need fix |
| **Block 1e/Block 1d research** | Task invocation (generic research-specialist) | Task invocation (lean-research-specialist) | ⚠️ Need report path |
| **Block 2 research verification** | Verify reports exist, count files | Verify reports exist, count files | ✓ Similar pattern |
| **Block 2 planning setup** | Calculate PLAN_PATH in same bash block | Calculate PLAN_PATH in same bash block | ⚠️ Should separate |
| **Block 2 planning invocation** | Task invocation (plan-architect) | Task invocation (lean-plan-architect) | ✓ Similar pattern |
| **Block 3 validation** | Verify plan exists, validate content | Verify plan exists, Lean-specific validation | ✓ Already correct |

### Key Discrepancies

1. **Report Path Pre-Calculation (Block 1d/1e)**:
   - Neither command pre-calculates report path
   - Both pass `Output Directory` instead of `REPORT_PATH`
   - Both agent behavioral files (research-specialist.md, lean-research-specialist.md) expect `REPORT_PATH`
   - **Impact**: Agents must calculate their own report paths, violating Hard Barrier Pattern

2. **Plan Path Pre-Calculation (Block 2)**:
   - /create-plan calculates PLAN_PATH in Block 2 bash (lines 1135-1150), then uses in Task prompt
   - /lean-plan calculates PLAN_PATH in Block 2 bash (lines 1116-1118), then uses in Task prompt
   - Both patterns inline but acceptable (path calculated before Task invocation)
   - **Impact**: Minimal - path is still pre-calculated, just not in separate block

3. **Research Agent Behavioral Expectations**:
   - research-specialist.md STEP 1: Expects `REPORT_PATH` (absolute file path)
   - lean-research-specialist.md STEP 1: Expects `REPORT_PATH` (absolute file path)
   - /create-plan Block 1d prompt: Provides `Output Directory` (directory only)
   - /lean-plan Block 1e prompt: Provides `Output Directory` (directory only)
   - **Impact**: Agents cannot validate absolute path contract, must derive filename themselves

## Specific Recommendations for Refactoring

### Recommendation 1: Add Block 1d-calc (Research Report Path Pre-Calculation)

**Insert new block between current Block 1d and Block 1e**:

**New Block 1d-calc** (Research Report Path Pre-Calculation):
```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE FROM BLOCK 1D ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1d" >&2
  exit 1
fi

# Restore workflow state file
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/lean-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PRE-CALCULATE RESEARCH REPORT FILE PATH ===
# CRITICAL: Calculate exact path BEFORE agent invocation (Hard Barrier Pattern)
# This path will be passed as literal text to the agent and validated after
REPORT_NUMBER="001"
REPORT_FILENAME="${REPORT_NUMBER}-lean-mathlib-research.md"
REPORT_PATH="${RESEARCH_DIR}/${REPORT_FILENAME}"

# Validate path is absolute
if [[ "$REPORT_PATH" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Calculated REPORT_PATH is not absolute" \
    "bash_block_1d_calc" \
    "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
  echo "ERROR: REPORT_PATH is not absolute: $REPORT_PATH" >&2
  exit 1
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$REPORT_PATH")" 2>/dev/null || true

# Persist for Block 1e and Block 1f
append_workflow_state "REPORT_PATH" "$REPORT_PATH" || {
  echo "export REPORT_PATH=\"$REPORT_PATH\"" >> "$STATE_FILE"
}

echo ""
echo "=== Research Report File Path Pre-Calculation ==="
echo "  Report Path: $REPORT_PATH"
echo "  Workflow ID: $WORKFLOW_ID"
echo ""
echo "Ready for lean-research-specialist invocation"
```

**Rename current Block 1e to Block 1e-exec** and update Task prompt:

**Block 1e-exec: Research Execution (Hard Barrier Invocation)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the lean-research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with Mathlib discovery and proof pattern analysis"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md

    You are conducting Lean formalization research for: lean-plan workflow

    **Input Contract (Hard Barrier Pattern)**:
    - REPORT_PATH: ${REPORT_PATH}
    - LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH}
    - FEATURE_DESCRIPTION: ${FEATURE_DESCRIPTION}
    - RESEARCH_COMPLEXITY: ${RESEARCH_COMPLEXITY}

    **CRITICAL**: You MUST write the research report to the EXACT path specified in REPORT_PATH.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Workflow Type: research-and-plan (Lean specialization)
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), read it for complete context.

    Execute Lean-specific research according to behavioral guidelines:
    1. Mathlib theorem discovery (WebSearch, grep local project)
    2. Proof pattern analysis (tactic sequences, common approaches)
    3. Project architecture review (module structure, naming conventions)
    4. Documentation survey (LEAN_STYLE_GUIDE.md if exists)
    5. Create comprehensive research report at REPORT_PATH

    Return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Add new Block 1f (Hard Barrier Validation for Research Report)**:

**Block 1f: Research Report Hard Barrier Validation**:
```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE FROM BLOCK 1E ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID" >&2
  exit 1
fi

# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/lean-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Source validation utilities for agent artifact validation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

echo ""
echo "=== Research Report Hard Barrier Validation ==="
echo ""

# === HARD BARRIER VALIDATION ===
# Validate REPORT_PATH is set (from Block 1d-calc)
if [ -z "${REPORT_PATH:-}" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "REPORT_PATH not restored from Block 1d-calc state" \
    "bash_block_1f" \
    "$(jq -n '{report_path: "missing"}')"
  echo "ERROR: REPORT_PATH not set - state restoration failed" >&2
  exit 1
fi

echo "Expected research report file: $REPORT_PATH"

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (500 bytes for research reports)
if ! validate_agent_artifact "$REPORT_PATH" 500 "research report"; then
  # Error already logged by validate_agent_artifact
  echo "ERROR: HARD BARRIER FAILED - Lean research specialist validation failed" >&2
  echo "" >&2
  echo "This indicates the lean-research-specialist did not create valid output." >&2
  echo "The workflow cannot proceed without research findings." >&2
  echo "" >&2
  echo "To retry: Re-run the /lean-plan command with the same arguments" >&2
  echo "" >&2
  exit 1
fi

echo "✓ Hard barrier passed - research report file validated"
echo ""
```

### Recommendation 2: Update lean-research-specialist.md Agent Behavioral File

**No changes needed** - agent already expects REPORT_PATH in STEP 1.

**Verification**: Lines 24-62 show agent expects:
```bash
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"
LEAN_PROJECT_PATH="[PATH PROVIDED IN YOUR PROMPT]"
FEATURE_DESCRIPTION="[DESCRIPTION PROVIDED IN YOUR PROMPT]"
RESEARCH_COMPLEXITY="[LEVEL PROVIDED IN YOUR PROMPT]"
```

Agent behavioral file is already correct.

### Recommendation 3: Separate Plan Path Pre-Calculation (Optional Enhancement)

**Current Block 2** (lines 859-1192) combines:
1. Research verification
2. State transition to PLAN
3. Plan path calculation
4. lean-plan-architect Task invocation

**Optional refactoring** (for consistency with Hard Barrier Pattern):

**Block 2a: Research Verification and State Transition**:
```bash
# Research verification, state transition to PLAN
# (lines 859-1115 from current Block 2)
```

**Block 2b: Plan Path Pre-Calculation**:
```bash
# === PREPARE PLAN PATH ===
PLAN_NUMBER="001"
PLAN_FILENAME="${PLAN_NUMBER}-$(echo "$TOPIC_NAME" | tr '_' '-' | cut -c1-40)-plan.md"
PLAN_PATH="${PLANS_DIR}/${PLAN_FILENAME}"

# Validate path is absolute
if [[ "$PLAN_PATH" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error ...
  exit 1
fi

# Collect research report paths
REPORT_PATHS=$(find "$RESEARCH_DIR" -name '*.md' -type f | sort)
REPORT_PATHS_LIST=$(echo "$REPORT_PATHS" | tr '\n' ' ')

# Persist for Block 2c
append_workflow_state_bulk <<EOF
PLAN_PATH=$PLAN_PATH
REPORT_PATHS_LIST=$REPORT_PATHS_LIST
EOF

echo "Plan will be created at: $PLAN_PATH"
echo "Using $REPORT_COUNT research reports"
```

**Block 2c-exec: Planning Execution (Hard Barrier Invocation)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the lean-plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan for ${FEATURE_DESCRIPTION} with theorem-level granularity"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-plan-architect.md

    You are creating a Lean formalization implementation plan for: lean-plan workflow

    **Input Contract (Hard Barrier Pattern)**:
    - PLAN_PATH: ${PLAN_PATH}
    - FEATURE_DESCRIPTION: ${FEATURE_DESCRIPTION}
    - RESEARCH_REPORTS: ${REPORT_PATHS_LIST}
    - LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH}

    **CRITICAL**: You MUST write the implementation plan to the EXACT path specified in PLAN_PATH.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    **Workflow-Specific Context**:
    - Output Path: ${PLAN_PATH}
    - Research Reports: ${REPORT_PATHS_LIST}
    - Workflow Type: research-and-plan (Lean specialization)
    - Operation Mode: new plan creation
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    **Lean Project Standards**:
    ${LEAN_STYLE_GUIDE}

    ... (rest of prompt)

    Execute Lean planning according to behavioral guidelines and return completion signal:
    PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Note**: This refactoring is optional since the current pattern (calculate path in bash, then use in Task prompt) is acceptable. However, separating into distinct blocks improves clarity and consistency with Hard Barrier Pattern.

### Recommendation 4: Add Plan Hard Barrier Validation Block (Optional)

**Add Block 2d (Plan Hard Barrier Validation)** before current Block 3:

```bash
set +H  # CRITICAL: Disable history expansion

# === RESTORE STATE ===
# (Similar pattern to Block 1f)

echo ""
echo "=== Plan File Hard Barrier Validation ==="
echo ""

# === HARD BARRIER VALIDATION ===
# Validate PLAN_PATH is set (from Block 2b)
if [ -z "${PLAN_PATH:-}" ]; then
  log_command_error ...
  exit 1
fi

echo "Expected plan file: $PLAN_PATH"

# HARD BARRIER: Validate agent artifact using validation-utils.sh
# validate_agent_artifact checks file existence and minimum size (500 bytes for plans)
if ! validate_agent_artifact "$PLAN_PATH" 500 "implementation plan"; then
  echo "ERROR: HARD BARRIER FAILED - Lean plan architect validation failed" >&2
  exit 1
fi

echo "✓ Hard barrier passed - plan file validated"
echo ""
```

**Then current Block 3 focuses on Lean-specific validation and completion** (Lean theorem count, goal specifications, metadata fields).

## Code Examples

### Example 1: Block 1d-calc Implementation

**File**: `/home/benjamin/.config/.claude/commands/lean-plan.md`
**Location**: Insert after current Block 1d (line 817), before current Block 1e (line 819)

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# === RESTORE STATE FROM BLOCK 1D ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE" 2>/dev/null)

if [ -z "$WORKFLOW_ID" ]; then
  echo "ERROR: Failed to restore WORKFLOW_ID from Block 1d" >&2
  exit 1
fi

# Restore workflow state file
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi

COMMAND_NAME="/lean-plan"
USER_ARGS="${FEATURE_DESCRIPTION:-}"
export COMMAND_NAME USER_ARGS

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === PRE-CALCULATE RESEARCH REPORT FILE PATH ===
# CRITICAL: Calculate exact path BEFORE agent invocation (Hard Barrier Pattern)
# This path will be passed as literal text to the agent and validated after
REPORT_NUMBER="001"
REPORT_FILENAME="${REPORT_NUMBER}-lean-mathlib-research.md"
REPORT_PATH="${RESEARCH_DIR}/${REPORT_FILENAME}"

# Validate path is absolute
if [[ "$REPORT_PATH" =~ ^/ ]]; then
  : # Path is absolute, continue
else
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Calculated REPORT_PATH is not absolute" \
    "bash_block_1d_calc" \
    "$(jq -n --arg path "$REPORT_PATH" '{report_path: $path}')"
  echo "ERROR: REPORT_PATH is not absolute: $REPORT_PATH" >&2
  exit 1
fi

# Ensure parent directory exists
mkdir -p "$(dirname "$REPORT_PATH")" 2>/dev/null || true

# Persist for Block 1e-exec and Block 1f
append_workflow_state "REPORT_PATH" "$REPORT_PATH" || {
  echo "export REPORT_PATH=\"$REPORT_PATH\"" >> "$STATE_FILE"
}

echo ""
echo "=== Research Report File Path Pre-Calculation ==="
echo "  Report Path: $REPORT_PATH"
echo "  Workflow ID: $WORKFLOW_ID"
echo ""
echo "Ready for lean-research-specialist invocation"
```

### Example 2: Block 1e-exec Task Invocation Update

**File**: `/home/benjamin/.config/.claude/commands/lean-plan.md`
**Location**: Replace current Block 1e (lines 819-853)

```markdown
## Block 1e-exec: Research Execution (Hard Barrier Invocation)

**EXECUTE NOW**: USE the Task tool to invoke the lean-research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with Mathlib discovery and proof pattern analysis"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md

    You are conducting Lean formalization research for: lean-plan workflow

    **Input Contract (Hard Barrier Pattern)**:
    - REPORT_PATH: ${REPORT_PATH}
    - LEAN_PROJECT_PATH: ${LEAN_PROJECT_PATH}
    - FEATURE_DESCRIPTION: ${FEATURE_DESCRIPTION}
    - RESEARCH_COMPLEXITY: ${RESEARCH_COMPLEXITY}

    **CRITICAL**: You MUST write the research report to the EXACT path specified in REPORT_PATH.
    The orchestrator has pre-calculated this path and will validate it exists after you return.
    Do NOT derive or calculate your own path.

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Workflow Type: research-and-plan (Lean specialization)
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}

    If an archived prompt file is provided (not 'none'), read it for complete context.

    Execute Lean-specific research according to behavioral guidelines:
    1. Mathlib theorem discovery (WebSearch, grep local project)
    2. Proof pattern analysis (tactic sequences, common approaches)
    3. Project architecture review (module structure, naming conventions)
    4. Documentation survey (LEAN_STYLE_GUIDE.md if exists)
    5. Create comprehensive research report at REPORT_PATH

    Return completion signal:
    REPORT_CREATED: ${REPORT_PATH}
  "
}
```

## Impact Analysis

### Performance Improvements

**Before** (current /lean-plan):
- Main conversation performs 74.2k token Explore operation
- Main conversation performs many Read calls directly
- Single-threaded sequential execution
- Heavy main context pollution

**After** (with subagent delegation):
- Main conversation delegates to lean-research-specialist (minimal tokens)
- Subagent performs Read/Grep/WebSearch in isolated context
- Potential for parallel execution (research + topic naming)
- Clean main context with validated artifacts

**Estimated time savings**:
- **Context reduction**: 74.2k tokens → ~5k tokens main context (93% reduction)
- **Parallel potential**: Research and topic naming can run concurrently (not currently utilized, but enabled)
- **Error isolation**: Subagent failures don't require full conversation replay

### Integration with Existing Infrastructure

**Agents already exist**:
- lean-research-specialist.md: Already expects REPORT_PATH contract
- lean-plan-architect.md: Already expects PLAN_PATH contract
- topic-naming-agent.md: Already correctly invoked in Block 1b-exec

**Commands requiring updates**:
- /lean-plan: Add Block 1d-calc, Block 1f (research report hard barrier)
- /lean-plan: Update Block 1e-exec Task prompt to pass REPORT_PATH
- /lean-plan: (Optional) Refactor Block 2 into 2a/2b/2c/2d for consistency

**Commands requiring similar fixes** (discovered during research):
- /create-plan: Also passes `Output Directory` instead of REPORT_PATH to research-specialist
- This is a systemic pattern issue, not /lean-plan specific

### Backward Compatibility

**Breaking changes**: None
- Existing lean-research-specialist.md agent already expects REPORT_PATH
- Existing lean-plan-architect.md agent already expects PLAN_PATH
- State file format unchanged
- Output artifact paths unchanged

**Migration path**: Direct replacement
- Replace Block 1e with Block 1d-calc + Block 1e-exec + Block 1f
- Update Task prompt to pass REPORT_PATH instead of Output Directory
- No user-facing changes to command invocation

## References

### Files Analyzed

**Command Files**:
- `/home/benjamin/.config/.claude/commands/lean-plan.md` (lines 1-1605) - Current implementation
- `/home/benjamin/.config/.claude/commands/create-plan.md` (lines 1-1586) - Reference pattern

**Agent Behavioral Files**:
- `/home/benjamin/.config/.claude/agents/lean-research-specialist.md` (lines 1-404) - Lean research agent
- `/home/benjamin/.config/.claude/agents/lean-plan-architect.md` (lines 1-532) - Lean planning agent
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-697) - Generic research agent
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-1282) - Generic planning agent

**Output Evidence**:
- `/home/benjamin/.config/.claude/output/lean-plan-output.md` (lines 1-196) - Performance evidence

**Key Findings**:
1. lean-research-specialist.md expects REPORT_PATH (absolute file path) but receives Output Directory (directory only)
2. lean-plan-architect.md correctly expects PLAN_PATH (absolute file path)
3. /create-plan has same issue with research-specialist invocation (passes directory instead of file path)
4. Both commands inline plan path calculation in Block 2 bash (acceptable but not ideal Hard Barrier Pattern)

### Pattern Documentation

**Hard Barrier Pattern**:
- Pre-calculate artifact paths BEFORE subagent invocation
- Pass absolute paths as explicit contracts in Task prompts
- Validate artifact existence AFTER subagent returns
- Prevents path mismatch issues and enables reliable artifact tracking

**Benefits**:
1. **Explicit contracts**: Subagent knows exactly where to write output
2. **Validation**: Orchestrator can detect missing artifacts immediately
3. **Error isolation**: Subagent path calculation errors don't propagate
4. **Parallelization**: Independent subagents can run concurrently
5. **Context reduction**: Heavy lifting happens in isolated subagent contexts

**Reference Implementation**: /create-plan Blocks 1b (pre-calculation) + 1b-exec (invocation) + 1c (validation)
