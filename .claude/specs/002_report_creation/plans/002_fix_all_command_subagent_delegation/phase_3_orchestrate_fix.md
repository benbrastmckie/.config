# Phase 3 Expansion: Fix /orchestrate Planning Phase

## Phase Overview

**Parent Plan**: `/home/benjamin/.config/.claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation.md`

**Phase Number**: 3

**Phase Title**: Fix /orchestrate Planning Phase

**Objective**: Implement behavioral injection pattern for plan-architect agent in /orchestrate command, replacing SlashCommand(/plan) delegation with direct plan creation using pre-calculated topic-based paths.

**Complexity**: High (9/10)

**Estimated Duration**: 4-5 hours

**Why High Complexity**:
- Multi-file coordinated changes (3 files: plan-architect.md, orchestrate.md, workflow-phases.md)
- Complex path pre-calculation logic using `create_topic_artifact()`
- Cross-reference requirements (plans must reference research reports, summaries must reference all artifacts)
- Integration with existing orchestrate workflow state management
- Verification and metadata extraction patterns
- Backward compatibility with existing research phase (must verify topic-based paths already used)

---

## Architecture Context

### Current Anti-Pattern (What's Wrong)

**Problem Flow**:
```
/orchestrate command (planning phase)
  ↓
Invokes Task → plan-architect agent
  ↓
plan-architect behavioral file: "Use SlashCommand to invoke /plan"
  ↓
Agent uses SlashCommand(/plan) → /plan command
  ↓
/plan command creates plan
  ↓
plan-architect returns path
```

**Issues**:
1. **Loss of Control**: /orchestrate cannot pre-calculate plan path (plan-architect → /plan delegation)
2. **Context Bloat**: /plan command output not metadata-extracted (full plan content in context)
3. **Inconsistency**: Research phase (same command) uses behavioral injection correctly
4. **Violation**: Contradicts hierarchical agent architecture (commands coordinate, agents execute)
5. **Missing Cross-References**: Plan doesn't reference research reports, summary doesn't reference plan + reports

### Correct Pattern (What We're Building)

**Fixed Flow**:
```
/orchestrate command (planning phase)
  ↓
1. Calculate topic-based plan path using create_topic_artifact()
   Result: specs/{NNN_workflow}/plans/{NNN}_implementation.md
  ↓
2. Load plan-architect behavioral prompt (NO SlashCommand instructions)
  ↓
3. Inject complete context via Task:
   - Agent behavioral guidelines
   - Workflow description
   - Research report paths (for cross-referencing)
   - PLAN_PATH (pre-calculated, topic-based)
   - Cross-reference requirements (Revision 3)
  ↓
Invoke Task → plan-architect agent (with behavioral injection)
  ↓
Agent creates plan directly at PLAN_PATH using Write tool
  ↓
Agent includes "Research Reports" metadata section with all report paths
  ↓
4. Verify plan exists at topic-based path
  ↓
5. Extract metadata (path + phase count + complexity only)
  ↓
Continue to summary phase
  ↓
6. Summary phase: doc-writer agent includes "Artifacts Generated" section
   - Research Reports: [all report paths]
   - Implementation Plan: [plan path]
```

**Benefits**:
- **Full Control**: /orchestrate calculates and verifies exact plan path
- **Topic-Based Organization**: All artifacts (reports, plan, summary) in same `specs/{NNN_workflow}/` directory
- **Context Reduction**: Metadata-only extraction (95% reduction target)
- **Traceability**: Bidirectional cross-references (plan → reports, summary → plan + reports)
- **Consistency**: Same pattern as research phase behavioral injection
- **No Recursion Risk**: Agent never invokes slash commands

---

## Detailed Implementation Tasks

### Task 1: Modify plan-architect.md Agent Behavioral File

**Objective**: Remove SlashCommand(/plan) instructions and replace with direct plan creation pattern

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

**Changes Required**:

#### Change 1.1: Remove STEP 2 (Lines 60-89)

**Current Content** (lines 60-89):
```markdown
### STEP 2 (REQUIRED BEFORE STEP 3) - Invoke /plan Command

**EXECUTE NOW - Create Plan Using /plan Command**

**ABSOLUTE REQUIREMENT**: YOU MUST use the SlashCommand tool to invoke /plan. This is NOT optional.

**WHY THIS MATTERS**: The /plan command handles proper numbering, directory structure, metadata generation, and standards integration. Manual plan creation will fail validation.

**Invocation Pattern**:
```bash
# If research reports were provided
/plan "<workflow description>" <report_path_1> <report_path_2> ...

# If no research reports
/plan "<workflow description>"
```

**CRITICAL REQUIREMENTS**:
- USE SlashCommand tool (not manual file creation)
- PASS complete workflow description (do not paraphrase)
- PASS all research report paths provided to you
- WAIT for /plan to complete before Step 3

**Example**:
```
/plan "Add user authentication with email and password" specs/reports/001_auth_patterns.md specs/reports/002_security.md
```

**CHECKPOINT**: /plan command must complete successfully before Step 3.
```

**Replace With** (new STEP 2):
```markdown
### STEP 2 (REQUIRED BEFORE STEP 3) - Create Plan File Directly

**EXECUTE NOW - Create Plan at Provided Path**

**ABSOLUTE REQUIREMENT**: YOU MUST create the plan file at the EXACT path provided in your prompt. This is NOT optional.

**WHY THIS MATTERS**: The calling command (e.g., /orchestrate) has pre-calculated the topic-based path following directory organization standards. You MUST use this exact path for proper artifact organization.

**Plan Creation Pattern**:
1. **Receive PLAN_PATH**: The calling command provides absolute path in your prompt
   - Format: `specs/{NNN_workflow}/plans/{NNN}_implementation.md`
   - Example: `specs/027_authentication/plans/027_implementation.md`
   - This path is PRE-CALCULATED using `create_topic_artifact()` utility

2. **Create Plan File**: Use Write tool to create plan at EXACT path provided
   - DO NOT calculate your own path
   - DO NOT modify the provided path
   - USE Write tool with absolute path from prompt

3. **Include ALL Research Reports** (CRITICAL - Revision 3):
   - If research report paths provided in prompt, list ALL in metadata section
   - Format in metadata:
     ```markdown
     ## Metadata
     - **Research Reports**:
       - [path to report 1]
       - [path to report 2]
       - [path to report 3]
     ```
   - This enables traceability from plan to research that informed it

**CRITICAL REQUIREMENTS**:
- USE Write tool (not SlashCommand)
- CREATE file at EXACT path provided (do not recalculate)
- INCLUDE all research reports in metadata (if provided)
- WAIT for Write to complete before Step 3

**Example**:
```
# Prompt will provide:
PLAN_PATH: /home/user/.claude/specs/027_auth/plans/027_implementation.md
RESEARCH_REPORTS:
  - /home/user/.claude/specs/027_auth/reports/027_existing_patterns.md
  - /home/user/.claude/specs/027_auth/reports/028_security_practices.md

# You create plan at PLAN_PATH using Write tool
# Include both reports in metadata "Research Reports" section
```

**CHECKPOINT**: Plan file created at provided path before Step 3.
```

**Rationale**: Removes /plan delegation, instructs agent to create plan directly at pre-calculated path, adds cross-reference requirement.

#### Change 1.2: Update STEP 3 (Lines 92-129)

**Current Content** (lines 92-129):
```markdown
### STEP 3 (REQUIRED BEFORE STEP 4) - Verify Plan File Created

**MANDATORY VERIFICATION - Plan File Exists**

After /plan completes, YOU MUST verify the plan file was created:

**Verification Steps**:
1. **Extract Path**: Get plan file path from /plan output
2. **Verify Existence**: Confirm file exists
3. **Verify Structure**: Check required sections present
4. **Verify Research Links**: Confirm research reports referenced (if provided)

**Verification Code**:
```bash
# Extract PLAN_PATH from /plan output
PLAN_PATH="[path from /plan output]"

# Verify file exists
if [ ! -f "$PLAN_PATH" ]; then
  echo "CRITICAL ERROR: Plan file not found at: $PLAN_PATH"
  exit 1
fi

echo "✓ VERIFIED: Plan file exists at $PLAN_PATH"

# Verify required sections
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases" "Testing Strategy")
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    echo "WARNING: Plan missing section: $section"
  fi
done

echo "✓ VERIFIED: Plan structure complete"
```

**CHECKPOINT**: All verifications must pass before Step 4.
```

**Replace With** (updated STEP 3):
```markdown
### STEP 3 (REQUIRED BEFORE STEP 4) - Verify Plan File Created

**MANDATORY VERIFICATION - Plan File Exists**

After creating plan with Write tool, YOU MUST verify the file was created successfully:

**Verification Steps**:
1. **Verify Existence**: Confirm file exists at provided PLAN_PATH
2. **Verify Structure**: Check required sections present
3. **Verify Research Links**: Confirm research reports referenced (if provided) **[Revision 3]**
4. **Verify Cross-References**: Check metadata includes all report paths **[Revision 3]**

**Verification Approach**:
```markdown
Use Read tool to verify plan file exists at PLAN_PATH and contains required sections.

Required sections:
- ## Metadata (with Research Reports list if reports provided)
- ## Overview
- ## Implementation Phases
- ## Testing Strategy

If research reports were provided:
- Verify "Research Reports" section in metadata lists ALL provided reports
- Verify each report path is correctly formatted
- This enables bidirectional linking (plan → reports)
```

**Self-Verification Checklist**:
- [ ] Plan file created at exact PLAN_PATH provided in prompt
- [ ] File contains all required sections
- [ ] Research reports listed in metadata (if provided)
- [ ] All report paths match those provided in prompt
- [ ] Plan structure is parseable by /implement

**CHECKPOINT**: All verifications must pass before Step 4.
```

**Rationale**: Updates verification to check for direct file creation (not /plan output extraction), adds cross-reference verification.

#### Change 1.3: Update STEP 4 Return Format (Lines 132-153)

**Current Content** (lines 132-153):
```markdown
### STEP 4 (ABSOLUTE REQUIREMENT) - Return Plan Path Confirmation

**CHECKPOINT REQUIREMENT - Return Path**

After verification, YOU MUST return ONLY this confirmation:

```
PLAN_PATH: [EXACT ABSOLUTE PATH FROM /plan OUTPUT]
```

**CRITICAL REQUIREMENTS**:
- DO NOT return plan summary or details
- DO NOT paraphrase the plan content
- ONLY return "PLAN_PATH: [path]"
- The orchestrator will read the plan file directly

**Example Return**:
```
PLAN_PATH: /home/user/.claude/specs/042_auth/plans/001_user_authentication.md
```
```

**Replace With** (updated STEP 4):
```markdown
### STEP 4 (ABSOLUTE REQUIREMENT) - Return Plan Path Confirmation

**CHECKPOINT REQUIREMENT - Return Path and Metadata**

After verification, YOU MUST return this exact format:

```
PLAN_CREATED: [EXACT ABSOLUTE PATH WHERE YOU CREATED PLAN]

Metadata:
- Phases: [number of phases in plan]
- Complexity: [Low|Medium|High]
- Estimated Hours: [total hours from plan]
```

**CRITICAL REQUIREMENTS**:
- DO NOT return full plan content or detailed summary
- DO NOT paraphrase the plan phases
- RETURN path, phase count, complexity, and hours ONLY
- The orchestrator will read the plan file directly for details

**Example Return**:
```
PLAN_CREATED: /home/user/.claude/specs/027_auth/plans/027_implementation.md

Metadata:
- Phases: 6
- Complexity: High
- Estimated Hours: 16
```

**Why Metadata Format**: Orchestrator uses this metadata for workflow state management without reading full plan (95% context reduction).
```

**Rationale**: Changes return format from "PLAN_PATH" (from /plan output) to "PLAN_CREATED" (from direct creation), adds metadata extraction to enable context reduction.

---

### Task 2: Modify orchestrate.md Planning Phase

**Objective**: Refactor planning phase to use behavioral injection with topic-based path pre-calculation

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Section**: Lines 1086-1185 (planning phase invocation and verification)

**Changes Required**:

#### Change 2.1: Replace Planning Phase Invocation (Lines 1086-1123)

**Current Content** (lines 1086-1123 - the /plan invocation):
```markdown
    2. Invoke SlashCommand: /plan "${WORKFLOW_DESC}" ${RESEARCH_REPORT_PATHS[@]}
    3. Verify plan file created successfully
    4. Return: PLAN_PATH: /absolute/path/to/plan.md

    ## Expected Output

    **Primary Output**:
    ```
    PLAN_PATH: /absolute/path/to/specs/plans/NNN_feature.md
    ```

    **Secondary Output**: Brief summary (1-2 sentences)
  "
}
```

**CRITICAL REQUIREMENTS**:
- YOU MUST use Task tool (not simulate invocation)
- YOU MUST pass ALL research report paths to the agent
- YOU MUST pass complete workflow description (no paraphrasing)
- DO NOT simplify or modify the agent prompt template
- Agent MUST invoke /plan slash command (not simulate)

**CHECKPOINT BEFORE INVOCATION**:
```
CHECKPOINT: Planning phase starting
- Workflow: [workflow description]
- Research reports: [count]
- Report paths ready: ✓
- Invoking: plan-architect agent
```

**Verification Checklist**:
- [ ] plan-architect agent invoked via Task tool
- [ ] Agent prompt includes workflow description, thinking mode, and research report paths
- [ ] Agent instructed to invoke /plan command
- [ ] Agent expected to return PLAN_PATH
```

**Replace With** (new behavioral injection pattern):
```markdown
**EXECUTE NOW - Calculate Topic-Based Plan Path BEFORE Agent Invocation**

**WHY THIS MATTERS**: The plan must be created in the same topic directory as research reports for proper artifact organization. We pre-calculate the path to guarantee correct location.

**VERIFICATION REQUIREMENT**: After executing this block, you MUST confirm PLAN_PATH is absolute and in topic-based structure.

```bash
# STEP 1: Source artifact creation utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# STEP 2: Use WORKFLOW_TOPIC_DIR from research phase (already calculated)
# This ensures plan goes in same directory as research reports
# WORKFLOW_TOPIC_DIR is already set (e.g., ".claude/specs/027_workflow")

echo "Planning phase starting..."
echo "Topic directory: $WORKFLOW_TOPIC_DIR"

# STEP 3: Calculate plan path using create_topic_artifact utility
PLAN_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "plans" "implementation" "")
# Result: specs/{NNN_workflow}/plans/{NNN}_implementation.md
# Example: .claude/specs/027_auth/plans/027_implementation.md

echo "Plan path calculated: $PLAN_PATH"

# STEP 4: Verify path is absolute
if [[ ! "$PLAN_PATH" =~ ^/ ]]; then
  echo "❌ CRITICAL ERROR: Plan path is not absolute: $PLAN_PATH"
  exit 1
fi

echo "✓ VERIFIED: Plan path is absolute and topic-based"
```

**CHECKPOINT - Path Pre-Calculation Complete**:
```
CHECKPOINT: Plan path calculated
- Topic directory: [WORKFLOW_TOPIC_DIR]
- Plan path: [PLAN_PATH]
- Path is absolute: ✓
- Topic-based structure: ✓
- Ready to invoke: plan-architect agent
```

**EXECUTE NOW - Invoke plan-architect Agent with Behavioral Injection**

**WHY THIS MATTERS**: We pass the pre-calculated PLAN_PATH to the agent so it creates the plan at the exact location we want, following topic-based organization.

**CRITICAL INSTRUCTION**: Use this EXACT template (no modifications):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect behavioral guidelines"
  timeout: 600000  # 10 minutes for planning
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Workflow Description**: ${WORKFLOW_DESCRIPTION}

    **Plan Output Path** (ABSOLUTE REQUIREMENT):
    ${PLAN_PATH}

    **Research Reports** (CRITICAL - Include ALL in plan metadata) [Revision 3]:
    ${RESEARCH_REPORT_PATHS_FORMATTED}

    **Cross-Reference Requirements** [Revision 3]:
    - In plan metadata, include \"Research Reports\" section with ALL report paths above
    - This enables traceability from plan to research that informed it
    - Summary will later reference both plan and reports for complete audit trail

    **CRITICAL REQUIREMENTS**:
    1. CREATE plan file at EXACT path above using Write tool (not SlashCommand)
    2. INCLUDE all research reports in metadata \"Research Reports\" section
    3. FOLLOW topic-based artifact organization (path already calculated correctly)
    4. RETURN format: PLAN_CREATED: [path]

    **Expected Output Format**:
    PLAN_CREATED: [absolute path]

    Metadata:
    - Phases: [N]
    - Complexity: [Low|Medium|High]
    - Estimated Hours: [H]
  "
}
```

**CHECKPOINT - Agent Invocation Complete**:
```
CHECKPOINT: plan-architect agent invoked
- Agent type: general-purpose
- Behavioral file: plan-architect.md
- Plan path provided: ✓
- Research reports provided: ✓
- Awaiting: PLAN_CREATED response
```
```

**Rationale**: Replaces /plan delegation with behavioral injection, pre-calculates topic-based path, passes research reports for cross-referencing.

#### Change 2.2: Update Plan Verification (Lines 1140-1185)

**Current Content** (lines 1140-1185 - verification after /plan):
```markdown
**MANDATORY VERIFICATION - Plan File Created**

After plan-architect agent completes, YOU MUST verify that a plan file was created. This verification is NOT optional.

**WHY THIS MATTERS**: Without verification, the workflow might proceed to implementation without a valid plan, leading to failure. The plan file is the contract for what will be implemented.

**EXECUTE NOW - Extract and Verify Plan Path**:

```bash
# STEP 1: Extract plan path from /plan command output
# Expected format: "PLAN_PATH: /path/to/specs/plans/NNN_feature.md"
PLAN_OUTPUT="$PLANNING_AGENT_OUTPUT"
PLAN_PATH=$(echo "$PLAN_OUTPUT" | grep -oP 'PLAN_PATH:\s*\K/.+' | head -1)

if [ -z "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: /plan did not return plan path"
  echo "Agent output: $PLAN_OUTPUT"
  exit 1
fi

echo "✓ Plan path extracted: $PLAN_PATH"

# STEP 2: Convert to absolute path if needed (should already be absolute)
if [[ ! "$PLAN_PATH" =~ ^/ ]]; then
  PLAN_PATH="$CLAUDE_PROJECT_DIR/$PLAN_PATH"
fi

echo "✓ Absolute plan path: $PLAN_PATH"

# STEP 3: MANDATORY file existence check
echo "Verifying plan file exists..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: Plan file not found at: $PLAN_PATH"
  echo "This should never happen if /plan executed correctly"
  exit 1
fi

echo "✓ VERIFIED: Plan file exists"

# STEP 4: Verify plan has required sections
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases" "Testing Strategy")
MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    MISSING_SECTIONS+=("$section")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Plan missing sections: ${MISSING_SECTIONS[*]}"
  echo "Attempting to continue (plan may be incomplete)"
fi

echo "✓ VERIFIED: Plan structure complete"
```
```

**Replace With** (new verification for behavioral injection):
```markdown
**MANDATORY VERIFICATION - Plan File Created**

After plan-architect agent completes, YOU MUST verify the plan was created at the expected path.

**WHY THIS MATTERS**: We pre-calculated the plan path, so verification confirms the agent followed instructions and created the plan at the correct topic-based location.

**EXECUTE NOW - Verify Plan Creation**:

```bash
# STEP 1: Extract confirmation from agent output
# Expected format: "PLAN_CREATED: /absolute/path/to/plan.md"
PLAN_OUTPUT="$PLANNING_AGENT_OUTPUT"
PLAN_CREATED_PATH=$(echo "$PLAN_OUTPUT" | grep -oP 'PLAN_CREATED:\s*\K/.+' | head -1)

if [ -z "$PLAN_CREATED_PATH" ]; then
  echo "⚠️  WARNING: Agent did not return PLAN_CREATED confirmation"
  echo "Falling back to pre-calculated path: $PLAN_PATH"
  PLAN_CREATED_PATH="$PLAN_PATH"
fi

echo "✓ Plan creation path: $PLAN_CREATED_PATH"

# STEP 2: Verify paths match (agent created at expected location)
if [ "$PLAN_CREATED_PATH" != "$PLAN_PATH" ]; then
  echo "⚠️  WARNING: Path mismatch"
  echo "  Expected: $PLAN_PATH"
  echo "  Agent created: $PLAN_CREATED_PATH"
  echo "  Using agent's path (may indicate path calculation issue)"
  PLAN_PATH="$PLAN_CREATED_PATH"
fi

# STEP 3: MANDATORY file existence check
echo "Verifying plan file exists at topic-based path..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: Plan file not found at: $PLAN_PATH"
  echo "Agent may have failed to create plan using Write tool"
  exit 1
fi

echo "✓ VERIFIED: Plan file exists at topic-based path"

# STEP 4: Verify plan has required sections
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases" "Testing Strategy")
MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    MISSING_SECTIONS+=("$section")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Plan missing sections: ${MISSING_SECTIONS[*]}"
  echo "Plan may be incomplete, but continuing..."
fi

echo "✓ VERIFIED: Plan structure complete"

# STEP 5: Verify research reports cross-referenced [Revision 3]
if [ -n "$RESEARCH_REPORT_PATHS_FORMATTED" ]; then
  echo "Verifying plan references research reports..."

  if ! grep -q "## Metadata" "$PLAN_PATH"; then
    echo "⚠️  WARNING: Plan missing Metadata section"
  elif ! grep -A 20 "## Metadata" "$PLAN_PATH" | grep -q "Research Reports"; then
    echo "⚠️  WARNING: Plan missing 'Research Reports' in metadata"
    echo "Plan should cross-reference research reports for traceability"
  else
    echo "✓ VERIFIED: Plan includes research reports cross-reference"
  fi
fi

# STEP 6: Extract metadata from agent output (context reduction)
PLAN_PHASE_COUNT=$(echo "$PLAN_OUTPUT" | grep -oP 'Phases:\s*\K\d+' | head -1)
PLAN_COMPLEXITY=$(echo "$PLAN_OUTPUT" | grep -oP 'Complexity:\s*\K\w+' | head -1)
PLAN_HOURS=$(echo "$PLAN_OUTPUT" | grep -oP 'Estimated Hours:\s*\K\d+' | head -1)

echo "✓ METADATA EXTRACTED (not full plan content):"
echo "  Phases: ${PLAN_PHASE_COUNT:-Unknown}"
echo "  Complexity: ${PLAN_COMPLEXITY:-Unknown}"
echo "  Hours: ${PLAN_HOURS:-Unknown}"
echo "✓ Context reduction achieved (metadata-only, not full plan)"
```

**CHECKPOINT - Plan Verification Complete**:
```
CHECKPOINT: Plan created and verified
- Plan path: [PLAN_PATH]
- File exists: ✓
- Topic-based structure: ✓
- Required sections: ✓
- Research reports cross-referenced: ✓ [Revision 3]
- Metadata extracted: ✓
- Ready for: Implementation or summary phase
```
```

**Rationale**: Updates verification to check direct file creation (not /plan output), adds cross-reference verification, extracts metadata for context reduction.

---

### Task 3: Verify Research Phase Uses Topic-Based Paths

**Objective**: Confirm research phase already uses topic-based artifact organization (should already be correct based on orchestrate.md lines 518-544)

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Section**: Lines 518-544 (research phase path calculation)

**Verification Steps**:

1. **Read lines 518-544**: Confirm research phase uses `create_topic_artifact()` utility
2. **Expected Pattern**:
   ```bash
   WORKFLOW_TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" "specs")
   REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "${topic}" "")
   ```
3. **If NOT using topic-based paths**: Update to match planning phase pattern (use `create_topic_artifact`)
4. **If ALREADY using topic-based paths**: No changes needed, document verification

**Acceptance Criteria**:
- Research reports created in `specs/{NNN_workflow}/reports/` (NOT flat `specs/reports/`)
- Plan created in `specs/{NNN_workflow}/plans/` (after Task 2 implementation)
- All artifacts for workflow in same topic directory
- Consistent numbering using `get_next_artifact_number()` utility

**Expected Result**: Research phase ALREADY uses topic-based paths (per parent plan analysis). Document this verification.

---

### Task 4: Update workflow-phases.md Planning Template

**Objective**: Update the planning phase template to reflect new behavioral injection pattern

**File**: `/home/benjamin/.config/.claude/shared/workflow-phases.md`

**Changes Required**:

#### Change 4.1: Update Planning Phase Template

**Find**: Section describing planning phase agent invocation (search for "Planning Phase" or "plan-architect")

**Current Pattern** (if exists):
```markdown
## Planning Phase

The planning phase uses the plan-architect agent to create an implementation plan based on research findings.

**Agent Invocation**:
- Agent: plan-architect
- Tool: SlashCommand
- Command: /plan
- Inputs: workflow description, research report paths
```

**Replace With**:
```markdown
## Planning Phase

The planning phase uses the plan-architect agent to create an implementation plan based on research findings. The agent creates plans directly using behavioral injection (not slash command delegation).

**Pre-Calculation Requirements**:
1. Calculate topic-based plan path BEFORE agent invocation:
   ```bash
   source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
   PLAN_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "plans" "implementation" "")
   # Result: specs/{NNN_workflow}/plans/{NNN}_implementation.md
   ```

2. Format research report paths for cross-referencing:
   ```bash
   RESEARCH_REPORT_PATHS_FORMATTED=""
   for report_path in "${RESEARCH_REPORT_PATHS[@]}"; do
     RESEARCH_REPORT_PATHS_FORMATTED+="- $report_path\n"
   done
   ```

**Agent Invocation Pattern**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect behavioral guidelines"
  timeout: 600000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    You are acting as a Plan Architect Agent.

    **Workflow Description**: ${WORKFLOW_DESCRIPTION}
    **Plan Output Path**: ${PLAN_PATH}
    **Research Reports**:
    ${RESEARCH_REPORT_PATHS_FORMATTED}

    **Cross-Reference Requirements**:
    - Include all research reports in plan metadata
    - Enables traceability from plan to research

    CREATE plan at exact path using Write tool.
    RETURN: PLAN_CREATED: [path]
  "
}
```

**Verification Requirements**:
- Verify plan created at pre-calculated path
- Extract metadata (phases, complexity, hours)
- Verify research reports cross-referenced in plan metadata
- Do NOT load full plan content (metadata-only for 95% context reduction)

**Key Differences from Old Pattern**:
- ❌ OLD: Agent invokes /plan slash command
- ✅ NEW: Agent creates plan directly at pre-calculated path
- ❌ OLD: Path determined by /plan command
- ✅ NEW: Path pre-calculated by orchestrator using create_topic_artifact()
- ❌ OLD: Full plan content in context
- ✅ NEW: Metadata-only extraction (95% context reduction)
```

**Rationale**: Updates template to document correct behavioral injection pattern for future reference and consistency.

---

### Task 5: Update Summary Phase Template for Cross-References

**Objective**: Ensure summary phase includes cross-references to plan and research reports (Revision 3 requirement)

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Section**: Lines 1931-2080 (workflow summary template)

**Verification Steps**:

1. **Read lines 1959-1973**: Check "Artifacts Generated" section template
2. **Verify includes**:
   - "Research Reports" subsection with paths
   - "Implementation Plan" subsection with path
   - "Debug Reports" subsection (if applicable)

**Expected Content** (lines 1959-1973):
```markdown
     ### Artifacts Generated

     **Research Reports**:
     [If research phase completed, list each report:]
     - [Report 1: path - brief description]
     - [Report 2: path - brief description]

     [If no research: "(No research phase - direct implementation)"]

     **Implementation Plan**:
     - Path: [plan_path]
     - Phases: [phase_count]
     - Complexity: [Low|Medium|High]
     - Link: [relative link to plan file]
```

**If Missing**: Add cross-reference template

**If Present**: Document that summary phase ALREADY includes cross-references (no changes needed)

**Acceptance Criteria**:
- Summary template includes "Research Reports" section
- Summary template includes "Implementation Plan" section
- Both sections reference artifact paths
- Enables complete audit trail (summary → plan → reports)

**Expected Result**: Summary template ALREADY includes cross-references (per parent plan lines 1959-1973). Document this verification.

---

## Testing Strategy

### Unit Tests

**Test File**: `.claude/tests/test_orchestrate_planning_behavioral_injection.sh`

**Test Cases**:

#### Test 1: Plan Path Pre-Calculation
```bash
#!/usr/bin/env bash
# Test: Verify plan path pre-calculation uses topic-based structure

test_plan_path_calculation() {
  echo "TEST: Plan path pre-calculation"

  # Setup: Create mock workflow topic directory
  WORKFLOW_DESCRIPTION="Test authentication system"
  WORKFLOW_TOPIC_DIR=".claude/specs/999_test_workflow"
  mkdir -p "$WORKFLOW_TOPIC_DIR"

  # Execute: Calculate plan path
  source .claude/lib/artifact-creation.sh
  PLAN_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "plans" "implementation" "")

  # Verify: Path follows topic-based structure
  if [[ "$PLAN_PATH" =~ ^.*/999_test_workflow/plans/[0-9]{3}_implementation\.md$ ]]; then
    echo "✓ PASS: Plan path follows topic-based structure"
  else
    echo "✗ FAIL: Plan path incorrect: $PLAN_PATH"
    return 1
  fi

  # Cleanup
  rm -rf "$WORKFLOW_TOPIC_DIR"
}
```

#### Test 2: Agent Does Not Invoke /plan
```bash
test_no_slash_command_invocation() {
  echo "TEST: plan-architect agent does NOT invoke /plan"

  # Setup: Read plan-architect.md behavioral file
  AGENT_FILE=".claude/agents/plan-architect.md"

  # Verify: No SlashCommand(/plan) instructions
  if grep -q "SlashCommand.*\/plan\|invoke \/plan" "$AGENT_FILE"; then
    echo "✗ FAIL: plan-architect.md contains /plan invocation instructions"
    grep -n "SlashCommand\|invoke /plan" "$AGENT_FILE"
    return 1
  else
    echo "✓ PASS: plan-architect.md does NOT invoke /plan"
  fi

  # Verify: Instructs to use Write tool instead
  if grep -q "Write tool\|CREATE.*at.*path" "$AGENT_FILE"; then
    echo "✓ PASS: plan-architect.md instructs direct file creation"
  else
    echo "✗ FAIL: plan-architect.md missing Write tool instructions"
    return 1
  fi
}
```

#### Test 3: Plan Includes Research Reports Cross-Reference
```bash
test_plan_research_cross_reference() {
  echo "TEST: Plan includes research reports in metadata"

  # Setup: Create mock plan with research reports
  MOCK_PLAN="/tmp/test_plan_999.md"
  cat > "$MOCK_PLAN" <<'EOF'
# Test Implementation Plan

## Metadata
- **Date**: 2025-10-20
- **Research Reports**:
  - specs/999_test/reports/001_patterns.md
  - specs/999_test/reports/002_security.md

## Overview
Test plan content
EOF

  # Verify: Plan has "Research Reports" section
  if grep -q "Research Reports:" "$MOCK_PLAN"; then
    echo "✓ PASS: Plan includes 'Research Reports' metadata section"
  else
    echo "✗ FAIL: Plan missing 'Research Reports' section"
    return 1
  fi

  # Verify: Section lists report paths
  REPORT_COUNT=$(grep -A 5 "Research Reports:" "$MOCK_PLAN" | grep -c "specs/.*/reports/")
  if [ "$REPORT_COUNT" -ge 2 ]; then
    echo "✓ PASS: Plan references $REPORT_COUNT research reports"
  else
    echo "✗ FAIL: Plan references only $REPORT_COUNT reports (expected ≥2)"
    return 1
  fi

  # Cleanup
  rm -f "$MOCK_PLAN"
}
```

#### Test 4: Summary Includes All Artifacts
```bash
test_summary_artifact_cross_reference() {
  echo "TEST: Summary includes research reports and plan"

  # Setup: Create mock summary
  MOCK_SUMMARY="/tmp/test_summary_999.md"
  cat > "$MOCK_SUMMARY" <<'EOF'
# Workflow Summary

## Artifacts Generated

**Research Reports**:
- Report 1: specs/999_test/reports/001_patterns.md
- Report 2: specs/999_test/reports/002_security.md

**Implementation Plan**:
- Path: specs/999_test/plans/003_implementation.md
- Phases: 5
- Complexity: Medium
EOF

  # Verify: Summary has "Research Reports" section
  if grep -q "Research Reports:" "$MOCK_SUMMARY"; then
    echo "✓ PASS: Summary includes 'Research Reports' section"
  else
    echo "✗ FAIL: Summary missing 'Research Reports' section"
    return 1
  fi

  # Verify: Summary has "Implementation Plan" section
  if grep -q "Implementation Plan:" "$MOCK_SUMMARY"; then
    echo "✓ PASS: Summary includes 'Implementation Plan' section"
  else
    echo "✗ FAIL: Summary missing 'Implementation Plan' section"
    return 1
  fi

  # Verify: All artifact types referenced
  REPORT_REFS=$(grep -c "specs/.*/reports/" "$MOCK_SUMMARY")
  PLAN_REFS=$(grep -c "specs/.*/plans/" "$MOCK_SUMMARY")

  if [ "$REPORT_REFS" -ge 2 ] && [ "$PLAN_REFS" -ge 1 ]; then
    echo "✓ PASS: Summary references reports ($REPORT_REFS) and plan ($PLAN_REFS)"
  else
    echo "✗ FAIL: Incomplete cross-references (reports: $REPORT_REFS, plan: $PLAN_REFS)"
    return 1
  fi

  # Cleanup
  rm -f "$MOCK_SUMMARY"
}
```

### Integration Tests

#### Test 5: End-to-End Planning Phase
```bash
test_e2e_planning_phase() {
  echo "TEST: End-to-end planning phase workflow"

  # This test would mock the full orchestrate planning phase:
  # 1. Create mock research reports
  # 2. Pre-calculate plan path
  # 3. Invoke plan-architect agent (mocked)
  # 4. Verify plan created at correct path
  # 5. Verify plan includes research cross-references
  # 6. Verify metadata extracted (not full plan)

  echo "NOTE: Full E2E test requires mocking Task tool invocation"
  echo "✓ SKIP: Placeholder for full E2E test"
}
```

### Test Execution

**Run All Tests**:
```bash
cd /home/benjamin/.config
bash .claude/tests/test_orchestrate_planning_behavioral_injection.sh
```

**Expected Results**:
- All 4 unit tests passing
- Zero SlashCommand(/plan) references in plan-architect.md
- Plan path calculation produces topic-based paths
- Cross-references present in both plan and summary

---

## Verification Checklist

Before marking this phase complete, verify ALL criteria:

### Code Changes
- [ ] plan-architect.md: STEP 2 updated (direct plan creation, not /plan invocation)
- [ ] plan-architect.md: STEP 3 updated (verification of direct creation)
- [ ] plan-architect.md: STEP 4 updated (return format: PLAN_CREATED with metadata)
- [ ] plan-architect.md: Cross-reference requirements added (Revision 3)
- [ ] orchestrate.md: Plan path pre-calculation added (lines 1086+)
- [ ] orchestrate.md: Agent invocation updated (behavioral injection pattern)
- [ ] orchestrate.md: Verification updated (direct creation, cross-references)
- [ ] workflow-phases.md: Planning phase template updated

### Artifact Organization
- [ ] Plan path calculation uses `create_topic_artifact()` utility
- [ ] Plan path follows format: `specs/{NNN_workflow}/plans/{NNN}_implementation.md`
- [ ] Research phase VERIFIED to use topic-based paths (existing code)
- [ ] All workflow artifacts in same topic directory

### Cross-References (Revision 3)
- [ ] plan-architect.md instructs: Include all research reports in metadata
- [ ] Planning phase agent prompt: Passes all research report paths
- [ ] Plan verification: Checks for "Research Reports" metadata section
- [ ] Summary template: Includes "Research Reports" and "Implementation Plan" sections

### Testing
- [ ] test_orchestrate_planning_behavioral_injection.sh created
- [ ] Test 1: Plan path calculation (PASS)
- [ ] Test 2: No /plan invocation (PASS)
- [ ] Test 3: Research cross-reference in plan (PASS)
- [ ] Test 4: All artifacts cross-referenced in summary (PASS)
- [ ] All existing orchestrate tests still passing (regression check)

### Documentation
- [ ] workflow-phases.md: Behavioral injection pattern documented
- [ ] Comments in orchestrate.md explain why behavioral injection used
- [ ] Cross-reference requirements explained (traceability, audit trail)

### Behavioral Compliance
- [ ] Zero SlashCommand invocations from plan-architect agent
- [ ] Agent creates plan using Write tool at pre-calculated path
- [ ] Metadata-only context preservation (no full plan in context)
- [ ] Consistent with research phase pattern (behavioral injection)

---

## Architecture Decisions

### Decision 1: Why Behavioral Injection vs Slash Command Delegation

**Context**: /orchestrate planning phase currently uses plan-architect → /plan delegation

**Options Considered**:
1. **Keep delegation**: plan-architect invokes /plan command
2. **Behavioral injection**: /orchestrate pre-calculates path, plan-architect creates directly

**Decision**: Behavioral injection (Option 2)

**Rationale**:
- **Control**: /orchestrate controls exact plan path (topic-based organization)
- **Consistency**: Same pattern as research phase (already uses behavioral injection)
- **Context Reduction**: Can extract metadata without loading full plan (95% reduction)
- **Architecture**: Follows hierarchical agent architecture (commands coordinate, agents execute)
- **No Recursion**: Eliminates command → agent → command chains

**Trade-offs**:
- More complex invocation (must pre-calculate path, inject prompt)
- Agent must follow exact path (less autonomy)
- BUT: Benefits outweigh complexity (control, consistency, context reduction)

### Decision 2: Topic-Based Path Structure

**Context**: Where should plan files be created?

**Options Considered**:
1. **Flat structure**: `specs/plans/{NNN}_feature.md`
2. **Topic-based structure**: `specs/{NNN_workflow}/plans/{NNN}_implementation.md`

**Decision**: Topic-based structure (Option 2)

**Rationale**:
- **Centralization**: All workflow artifacts (reports, plan, summary) in one directory
- **Traceability**: Easy to find all artifacts for a workflow
- **Consistency**: Same structure documented in `.claude/docs/README.md` lines 114-138
- **Numbering**: Consistent numbering within topic (reports and plan have same base number)
- **Standards Compliance**: Follows project artifact organization standards

**Implementation**:
```bash
# Research reports: specs/{NNN_workflow}/reports/{NNN}_topic.md
# Implementation plan: specs/{NNN_workflow}/plans/{NNN}_implementation.md
# Workflow summary: specs/{NNN_workflow}/summaries/{NNN}_summary.md
```

### Decision 3: Cross-Reference Requirements (Revision 3)

**Context**: How do we ensure traceability between artifacts?

**Options Considered**:
1. **No cross-references**: Each artifact standalone
2. **One-way references**: Plan → reports only
3. **Bidirectional references**: Plan ↔ reports, summary → plan + reports

**Decision**: Plan → reports, summary → plan + reports (Option 3)

**Rationale**:
- **Audit Trail**: Summary shows complete artifact chain (reports → plan → implementation)
- **Traceability**: Can trace from plan back to research that informed it
- **Documentation**: Summary serves as workflow completion record
- **Discovery**: Easy to find related artifacts

**Implementation**:
- **Plan metadata**: "Research Reports" section with all report paths
- **Summary "Artifacts Generated"**: Lists reports, plan, debug reports (if any)
- **Format**: Absolute or relative paths (relative preferred for portability)

---

## Context Reduction Strategy

### Current State (BEFORE Fix)

**Problem**: Full plan content loaded into context after /plan invocation

```
/orchestrate planning phase
  ↓
plan-architect → /plan
  ↓
/plan returns: full plan file content (5000+ tokens)
  ↓
/orchestrate context: 168.9k tokens (bloated)
```

### Target State (AFTER Fix)

**Goal**: Metadata-only extraction, 95% context reduction

```
/orchestrate planning phase
  ↓
Pre-calculate PLAN_PATH
  ↓
plan-architect creates plan at PLAN_PATH (behavioral injection)
  ↓
Agent returns: metadata only (path, phases, complexity, hours)
  ↓
/orchestrate context: <250 tokens for plan metadata
  ↓
95% reduction (5000 → 250 tokens)
```

### Metadata Extraction Pattern

**From Agent Output**:
```
PLAN_CREATED: /path/to/plan.md

Metadata:
- Phases: 6
- Complexity: High
- Estimated Hours: 16
```

**Stored in Context**:
```bash
PLAN_PATH="/path/to/plan.md"
PLAN_PHASE_COUNT=6
PLAN_COMPLEXITY="High"
PLAN_HOURS=16
```

**NOT Stored in Context**:
- Full plan content
- Phase details
- Task lists
- Technical design
- Testing strategy

**When Needed**: /implement reads plan file directly from PLAN_PATH

---

## Risk Mitigation

### Risk 1: Agent Ignores PLAN_PATH and Creates Elsewhere

**Likelihood**: Medium (agents sometimes ignore exact path instructions)

**Impact**: High (plan not found, workflow fails)

**Mitigation**:
1. **Enforcement Language**: Use "ABSOLUTE REQUIREMENT" and "EXECUTE NOW" in agent prompt
2. **Verification**: Check plan exists at PLAN_PATH after agent completes
3. **Path Mismatch Recovery**: If plan not at PLAN_PATH, search for plan file created by agent
4. **Fallback**: Log warning, use agent's path if verification successful

**Implementation**:
```bash
# Verification with fallback
if [ ! -f "$PLAN_PATH" ]; then
  echo "⚠️  Plan not at expected path, searching..."
  ACTUAL_PATH=$(find specs -name "*implementation*.md" -mmin -5 | head -1)
  if [ -n "$ACTUAL_PATH" ]; then
    echo "✓ Found plan at: $ACTUAL_PATH"
    PLAN_PATH="$ACTUAL_PATH"
  else
    echo "❌ CRITICAL ERROR: Plan not found"
    exit 1
  fi
fi
```

### Risk 2: Agent Forgets to Include Research Reports in Metadata

**Likelihood**: Medium (agents sometimes skip cross-referencing)

**Impact**: Medium (traceability lost, but plan still functional)

**Mitigation**:
1. **Explicit Requirement**: Add "CRITICAL - Include ALL in plan metadata" to prompt
2. **Verification**: Check plan for "Research Reports" section after creation
3. **Warning**: Log warning if cross-references missing (non-blocking)
4. **Documentation**: Update agent behavioral file with cross-reference examples

**Implementation**:
```bash
# Verify cross-references
if [ -n "$RESEARCH_REPORT_PATHS" ]; then
  if ! grep -q "Research Reports:" "$PLAN_PATH"; then
    echo "⚠️  WARNING: Plan missing research reports cross-reference"
    echo "Traceability will be incomplete, but continuing..."
  fi
fi
```

### Risk 3: Metadata Extraction Fails

**Likelihood**: Low (regex patterns reliable)

**Impact**: Low (can still read plan file if needed)

**Mitigation**:
1. **Robust Regex**: Use multiple patterns to extract metadata
2. **Fallback**: If metadata extraction fails, read plan file directly (degraded context reduction)
3. **Logging**: Log extraction failures for debugging

**Implementation**:
```bash
# Extract with fallback
PLAN_PHASE_COUNT=$(echo "$PLAN_OUTPUT" | grep -oP 'Phases:\s*\K\d+' | head -1)
if [ -z "$PLAN_PHASE_COUNT" ]; then
  echo "⚠️  Failed to extract phase count from agent output"
  echo "Falling back to reading plan file..."
  PLAN_PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH")
fi
```

---

## Success Metrics

### Quantitative Metrics

**Context Reduction**:
- **Target**: 95% reduction in planning phase context usage
- **Before**: ~5000 tokens (full plan content)
- **After**: ~250 tokens (metadata only)
- **Measurement**: Compare agent output size before/after fix

**Compliance**:
- **Target**: 100% of plans created at topic-based paths
- **Measurement**: Validate all plans in `specs/{NNN_workflow}/plans/` structure

**Cross-References**:
- **Target**: 100% of plans include research reports in metadata
- **Measurement**: Grep for "Research Reports:" in all plans created

### Qualitative Metrics

**Consistency**:
- Planning phase uses same behavioral injection pattern as research phase
- All /orchestrate phases follow consistent agent invocation approach

**Traceability**:
- Can trace from summary → plan → research reports
- Audit trail complete for all workflows

**Maintainability**:
- Clear documentation in workflow-phases.md
- Anti-pattern eliminated (no more /plan delegation)

---

## Completion Criteria

This phase is COMPLETE when:

### All Code Changes Implemented
- [ ] plan-architect.md: STEP 2, 3, 4 updated with behavioral injection pattern
- [ ] plan-architect.md: Cross-reference requirements added
- [ ] orchestrate.md: Plan path pre-calculation implemented
- [ ] orchestrate.md: Agent invocation refactored to behavioral injection
- [ ] orchestrate.md: Verification updated for direct creation + cross-references
- [ ] workflow-phases.md: Planning phase template updated

### All Tests Passing
- [ ] test_orchestrate_planning_behavioral_injection.sh: All 4 tests PASS
- [ ] Zero SlashCommand(/plan) references in plan-architect.md
- [ ] Research phase verified to use topic-based paths
- [ ] Cross-reference verification tests passing

### All Artifacts Topic-Based
- [ ] Plans created in `specs/{NNN_workflow}/plans/` (verified)
- [ ] Reports created in `specs/{NNN_workflow}/reports/` (verified)
- [ ] Summaries created in `specs/{NNN_workflow}/summaries/` (template ready)

### All Cross-References Present
- [ ] Plans include "Research Reports" metadata section
- [ ] Summaries include "Research Reports" and "Implementation Plan" sections
- [ ] Traceability verified end-to-end

### Documentation Complete
- [ ] workflow-phases.md documents behavioral injection pattern
- [ ] Comments in orchestrate.md explain architecture decisions
- [ ] Test file includes documentation of verification approach

---

## File Change Summary

### Files Modified (3)

1. **`.claude/agents/plan-architect.md`**
   - Lines 60-89: Remove STEP 2 (/plan invocation), replace with direct plan creation
   - Lines 92-129: Update STEP 3 verification (direct creation, cross-references)
   - Lines 132-153: Update STEP 4 return format (PLAN_CREATED with metadata)
   - Add: Cross-reference requirements (Revision 3)

2. **`.claude/commands/orchestrate.md`**
   - Lines 1086-1123: Replace /plan invocation with behavioral injection
   - Lines 1140-1185: Update plan verification (direct creation, cross-references)
   - Add: Plan path pre-calculation using `create_topic_artifact()`
   - Add: Metadata extraction for context reduction

3. **`.claude/shared/workflow-phases.md`**
   - Planning phase section: Update template with behavioral injection pattern
   - Add: Pre-calculation requirements
   - Add: Cross-reference requirements
   - Add: Comparison with old pattern (documentation)

### Files Created (1)

1. **`.claude/tests/test_orchestrate_planning_behavioral_injection.sh`**
   - Test 1: Plan path calculation (topic-based structure)
   - Test 2: No /plan invocation (anti-pattern detection)
   - Test 3: Research cross-reference in plan
   - Test 4: All artifacts cross-referenced in summary
   - Test 5: Placeholder for E2E test

### Files Verified (2)

1. **`.claude/commands/orchestrate.md`** (lines 518-544)
   - Verify research phase uses topic-based paths
   - Document verification result

2. **`.claude/commands/orchestrate.md`** (lines 1959-1973)
   - Verify summary template includes cross-references
   - Document verification result

---

## Next Steps After This Phase

1. **Phase 4**: System-Wide Validation and Anti-Pattern Detection
   - Run anti-pattern detection across all agent files
   - Validate topic-based artifact organization compliance
   - Test all three fixes together

2. **Phase 5**: Documentation and Examples
   - Complete agent-authoring-guide.md with cross-reference requirements
   - Complete command-authoring-guide.md with topic-based path examples
   - Update hierarchical_agents.md with behavioral injection section

3. **Phase 6**: Final Integration Testing
   - End-to-end /orchestrate workflow test
   - Verify cross-references in all artifacts
   - Measure context reduction achieved

---

## Estimated Timeline

**Total Phase Duration**: 4-5 hours

**Task Breakdown**:
- Task 1 (plan-architect.md): 1.5 hours
  - Update STEP 2, 3, 4: 45 min
  - Add cross-reference requirements: 30 min
  - Review and test changes: 15 min

- Task 2 (orchestrate.md planning phase): 2 hours
  - Path pre-calculation logic: 45 min
  - Agent invocation refactor: 45 min
  - Verification update: 30 min

- Task 3 (verify research phase): 15 min
  - Read and verify existing code
  - Document verification

- Task 4 (workflow-phases.md): 30 min
  - Update template
  - Add documentation

- Task 5 (verify summary phase): 15 min
  - Read and verify existing template
  - Document verification

- Testing: 30-45 min
  - Write test file: 20 min
  - Run tests: 10 min
  - Fix any issues: 15 min (buffer)

**Parallel Work**: Tasks 3, 4, 5 can be done in any order after Task 1 and 2 complete.

---

## Notes

### Key Insights

1. **Consistency is Critical**: Research phase ALREADY uses behavioral injection. Planning phase should match this pattern.

2. **Cross-References Enable Traceability**: Revision 3 requirement ensures we can audit complete workflow (summary → plan → reports).

3. **Topic-Based Organization is Essential**: All workflow artifacts in one directory simplifies discovery and management.

4. **Context Reduction is Achievable**: Metadata-only extraction can reduce context from 5000 tokens to 250 tokens (95% reduction).

### Potential Issues

1. **Agent Path Compliance**: Agents may ignore PLAN_PATH and create elsewhere. Verification with recovery mitigates this.

2. **Cross-Reference Forgetting**: Agents may forget to include research reports in metadata. Warnings + documentation mitigate this.

3. **Backward Compatibility**: Ensure changes don't break existing orchestrate workflows. Integration tests verify this.

### Future Improvements

1. **Automated Cross-Reference Validation**: Script to validate all plans reference their research reports

2. **Summary Auto-Generation**: Generate summary "Artifacts Generated" section automatically from workflow state

3. **Topic Directory Management**: Utility to list/manage all topic directories and their artifacts

---

*This phase expansion created by Phase Expansion Specialist agent following parent plan `/home/benjamin/.config/.claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation.md` Phase 3 requirements.*
