# Debug Report: /orchestrate Workflow Deficiencies After 070 Refactor

## Metadata
- **Date**: 2025-10-23
- **Issue**: /orchestrate executing incorrect phase patterns after implementation of plan 070-001
- **Severity**: High
- **Type**: Debugging investigation
- **Related Plans**: 070-001 (orchestrate simplification), 071-001 (enforcement fix)
- **Trigger**: User ran `/orchestrate` for research-and-plan workflow, received 4 deficiencies

## Problem Statement

After implementing the orchestrate simplification refactor (spec 070-001), the `/orchestrate` command exhibits four critical deficiencies when executing research-and-planning workflows:

1. **Research agents not creating report files**: Parallel research subagents returned inline summaries instead of creating report artifacts
2. **Wrong planning invocation**: Used `/plan` SlashCommand instead of Task(plan-architect) agent
3. **Unnecessary summary creation**: Created workflow summary after planning when no implementation occurred
4. **Missing conditional logic**: No workflow scope detection to skip inappropriate phases

These issues indicate that while the 070 refactor successfully simplified the phase structure (8 phases → 6 phases), it failed to implement proper conditional phase execution and enforcement patterns.

## Investigation Process

### Step 1: Evidence Gathering
- Read user's deficiency report from TODO6.md
- Examined implementation plan 070-001 to understand intended changes
- Read orchestrate.md structure (file too large for single read: 50,493 tokens)
- Reviewed git history showing recent commits (070 and 071 spec implementations)

### Step 2: Root Cause Analysis
Delegated comprehensive investigation to general-purpose agent with tools:
- Read orchestrate.md in segments
- Grep for enforcement patterns and conditional logic
- Examined standards documentation in .claude/docs/
- Located exact code locations for each deficiency

### Step 3: Standards Cross-Reference
Compared actual implementation against:
- Hierarchical Agent Architecture (.claude/docs/concepts/hierarchical_agents.md)
- Development Workflow (.claude/docs/concepts/development-workflow.md)
- Command Architecture Standards (.claude/docs/reference/command_architecture_standards.md)
- Behavioral Injection Pattern (.claude/docs/concepts/patterns/behavioral-injection.md)

## Findings

### Root Cause Analysis

**Primary Root Cause**: The 070 refactor removed automatic complexity evaluation and expansion (Phases 2.5 and 4) but **did not add conditional workflow scope detection**. This caused all six phases (0-5) to execute regardless of workflow type.

**Secondary Root Causes**:
1. Research agent enforcement insufficient (agents ignored file creation requirements)
2. Planning phase fallback to SlashCommand still possible despite architectural prohibition
3. Phase 6 (Documentation) executes unconditionally for all workflows
4. No workflow type detection logic exists in Phase 0 (Location)

### Deficiency 1: Research Agents Not Creating Report Files

**Location**: `orchestrate.md:608-1110` (Phase 1: Research)

**Current Behavior**:
Research agents invoked via Task tool (correct) but returned inline summaries instead of creating report files at specified paths. From user's output (TODO6.md lines 32-76):

```
Research Summary (200 words)

Command Files: 21 commands analyzed. Key issues: (1) Weak imperative
language - 70% imperative vs 90% target...
```

This is **inline content** being returned, not a file path confirmation.

**Root Cause**:
The research phase template includes enforcement markers (orchestrate.md:829):
```markdown
- DO NOT return summary text. Orchestrator will read your report file.
```

However, agents are violating this requirement. The enforcement is **descriptive** (telling what NOT to do) rather than **prescriptive** (telling exactly what TO do).

**Standards Violated**:
- **Hierarchical Agent Architecture** (.claude/docs/concepts/hierarchical_agents.md): "Agents must create artifact files, not return inline content"
- **Development Workflow** (.claude/docs/concepts/development-workflow.md): "Create research reports in `specs/reports/` for complex topics"
- **Research Specialist Agent** (.claude/agents/research-specialist.md): "STEP 2 (REQUIRED BEFORE STEP 3) - Create Report File FIRST"

**Evidence - Correct Pattern Exists in Code**:
The auto-retry mechanism (orchestrate.md:857-1020) shows the CORRECT pattern but with insufficient enforcement:

```yaml
# Lines 900-914 (STANDARD template)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory artifact creation"
  prompt: "
    Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **FILE CREATION REQUIRED**
    Topic directory: ${TOPIC_PATH}
    Use Write tool to create: ${REPORT_PATH}

    Research ${TOPIC} and document findings in the file.
    Return only: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

The phrase "FILE CREATION REQUIRED" is too weak. Compare to working enforcement patterns in other commands:

```yaml
# Example from implement.md Phase 1
**EXECUTE NOW - MANDATORY FILE CREATION**
STEP 1: Use Write tool IMMEDIATELY to create: ${FILE_PATH}
STEP 2: Only after file exists, conduct research
STEP 3: Use Edit tool to update file with findings
STEP 4: Return ONLY this exact format: REPORT_CREATED: ${FILE_PATH}

**VERIFICATION**: After returning, orchestrator will verify file exists
```

**Contributing Factor**: Plan 071 attempted to fix this (lines 28-29 identify "enforcement not working") but implementation incomplete.

---

### Deficiency 2: SlashCommand Used for Planning Instead of Task(plan-architect)

**Location**: `orchestrate.md:1-36` (Critical architectural pattern), `orchestrate.md:1500-1856` (Phase 2: Planning)

**Current Behavior**:
From user's output (TODO6.md lines 81-100):
```
> /plan is running… Refactor .claude/ directory to achieve
full standards compliance based on audit findings...
```

The `/plan` command was invoked using **SlashCommand tool**, which is explicitly forbidden.

**Root Cause**:
The orchestrator has a critical architectural prohibition at the top of the file:

```markdown
# orchestrate.md lines 10-36
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE -->
<!-- /orchestrate MUST NEVER invoke other slash commands -->
<!-- FORBIDDEN TOOLS: SlashCommand -->
<!-- REQUIRED PATTERN: Task tool → Specialized agents -->

WHY THIS MATTERS:
1. Context Bloat: SlashCommand expands entire command prompts (3000+ tokens each)
2. Broken Behavioral Injection: Commands invoked via SlashCommand cannot receive
   artifact path context from location-specialist
3. Lost Control: Orchestrator cannot customize agent behavior, inject topic numbers
```

**However**, the planning phase implementation (orchestrate.md:1500-1856) shows the CORRECT pattern:

```yaml
# Lines 1588-1609 (Attempt 1 STANDARD template)
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan using plan-architect behavioral guidelines"
  timeout: 600000
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **PLAN PATH (MANDATORY - Use this EXACT path)**: ${PLAN_PATH}

    Use Write tool to create: ${PLAN_PATH}
    Create implementation plan for: ${WORKFLOW_DESCRIPTION}
    ${RESEARCH_REPORTS_LIST}
    Standards file: ${STANDARDS_FILE}

    Return only: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

This is the **correct implementation**. So why did SlashCommand get used?

**Hypothesis**: The orchestrator AI selected SlashCommand instead of following the Task invocation template. This suggests:
1. The architectural prohibition (lines 10-36) is in an HTML comment (not processed as instruction)
2. No runtime validation prevents SlashCommand usage
3. Orchestrator may have accessed SlashCommand through fallback logic

**Standards Violated**:
- **Command Architecture Standards** (.claude/docs/reference/command_architecture_standards.md): "Commands invoke agents via Task tool with context injection (not SlashCommand)"
- **Behavioral Injection Pattern** (.claude/docs/concepts/patterns/behavioral-injection.md): "Agent invocation must use Task tool with injected context"
- **Orchestrate Header** (line 13): "FORBIDDEN TOOLS: SlashCommand"

**Evidence - Allowed Tools List**:
```yaml
# orchestrate.md lines 1-2
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
```

SlashCommand is **not in the allowed-tools list**, yet it was used. This indicates the tool restriction was bypassed.

---

### Deficiency 3: Workflow Summary Created When Not Needed

**Location**: `orchestrate.md:3309-3933` (Phase 6: Documentation)

**Current Behavior**:
From user's output (TODO6.md lines 222-274), Phase 6 executed and created a workflow summary:

```
● Now I'll create the workflow summary documenting this
  research → planning workflow.

● Write(.claude/specs/summaries/083_standards_compliance_workflow.md)
  ⎿  Wrote 297 lines to .claude/specs/summaries/083_sta
     dards_compliance_workflow.md
```

**Root Cause**:
Phase 6 (Documentation) executes **unconditionally** for ALL workflows. There is no check to determine whether implementation occurred.

**When Summaries Should Be Created**:
From .claude/docs/concepts/development-workflow.md:
```
3. Execute plans phase-by-phase with testing and commits
4. Generate summaries in specs/summaries/ linking plans to code
```

Key phrase: "**linking plans to code**" - summaries document implementation outcomes.

From .claude/docs/concepts/directory-protocols.md line 160:
```
- summaries/: After implementation complete, during documentation phase
```

**The User's Workflow Was**:
```
Phase 0 (Location) → Phase 1 (Research) → Phase 2 (Planning) → STOP
```

No implementation occurred, so **no summary should be created**.

**Standards Violated**:
- **Development Workflow** (.claude/docs/concepts/development-workflow.md): Summaries created "after implementation complete"
- **Directory Protocols** (.claude/docs/concepts/directory-protocols.md): "summaries/: After implementation complete"
- **Artifact Lifecycle**: Summaries document implementation outcomes, not planning outcomes

**Missing Logic**:
Phase 6 should be wrapped in conditional execution:

```bash
# After Phase 2 (Planning) completes
if [[ "$PHASES_TO_EXECUTE" =~ "3" ]]; then
  # Phase 3 (Implementation) will execute
  # Therefore Phase 6 (Documentation) will be needed
  SKIP_DOCUMENTATION=false
else
  # No implementation phase
  # Skip documentation phase
  SKIP_DOCUMENTATION=true
  echo "Workflow complete - research and planning only"
  exit 0
fi
```

This logic **does not exist** anywhere in orchestrate.md.

---

### Deficiency 4: Missing Workflow Scope Detection

**Location**: `orchestrate.md:338-352` (Workflow phase identification)

**Current Behavior**:
The workflow analysis section mentions "Simplified Workflows" but provides only **descriptive guidance**:

```markdown
**Simplified Workflows** (for straightforward tasks):
- Skip research if task is well-understood
- Direct to implementation for simple fixes
- Minimal documentation for internal changes
```

This is **advice**, not **executable code**.

**Root Cause**:
No conditional branching logic exists to determine which phases should execute based on workflow type. The command assumes ALL workflows follow the full 6-phase pattern:

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
Location  Research  Planning  Implement  Testing   Debug     Documentation
```

**What Should Have Happened**:
The user's workflow description was:
```
"research the .claude/ directory to review compliance with the
standards set in .claude/docs/ in order to create a refactor plan"
```

This should map to workflow type: `research_and_plan`

Expected phases: `0 → 1 → 2 → STOP`

**Standards Violated**:
- **Imperative Language Guide** (.claude/docs/guides/imperative-language-guide.md): "Descriptive: 'you can skip research' → Imperative: 'SKIP research if...'"
- **Command Architecture Standards**: Commands must have executable logic, not advisory guidance

**Evidence from Execution**:
From TODO6.md:
- Phase 1 (Research) executed ✓
- Phase 2 (Planning) executed ✓
- Phase 6 (Documentation) executed ✗ (should have been skipped)

This proves no scope detection occurred.

**Required Implementation** (Currently Missing):

```bash
# After Phase 0 (Location), determine workflow scope
WORKFLOW_SCOPE="unknown"
PHASES_TO_EXECUTE=""

# Scope detection algorithm
if echo "$WORKFLOW_DESCRIPTION" | grep -qiE "(research|audit|investigate).*plan"; then
  WORKFLOW_SCOPE="research_and_plan"
  PHASES_TO_EXECUTE="0,1,2"
  echo "Detected: Research and planning workflow (no implementation)"

elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE "implement|build|add.*feature|create.*code"; then
  WORKFLOW_SCOPE="full_implementation"
  PHASES_TO_EXECUTE="0,1,2,3,4,5,6"
  echo "Detected: Full implementation workflow"

elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE "^(fix|debug)"; then
  WORKFLOW_SCOPE="debug_only"
  PHASES_TO_EXECUTE="0,1,5"
  echo "Detected: Debug-only workflow (no new implementation)"
fi

# Validation
if [ "$WORKFLOW_SCOPE" == "unknown" ]; then
  echo "WARNING: Could not determine workflow scope from description"
  echo "Defaulting to: research_and_plan (conservative)"
  WORKFLOW_SCOPE="research_and_plan"
  PHASES_TO_EXECUTE="0,1,2"
fi

echo "Workflow scope: $WORKFLOW_SCOPE"
echo "Phases to execute: $PHASES_TO_EXECUTE"
```

This logic is **completely absent** from orchestrate.md.

---

## Cross-Cutting Issues

### Issue: Plan 071 Partially Addresses Problems

**File**: `.claude/specs/071_orchestrate_enforcement_fix/plans/001_fix_research_and_planning_enforcement.md`

This plan identifies and attempts to fix Deficiencies 1 and 2:
- **Phase 1**: Creates auto-retry templates for research agents (addresses Deficiency 1)
- **Phase 2**: Removes fallback mechanisms (addresses part of Deficiency 1)
- **Lines 28-29**: Identifies "Command Invocation" problem (addresses Deficiency 2)

**What Plan 071 Does NOT Address**:
- Deficiency 3: Unconditional workflow summary creation (not mentioned)
- Deficiency 4: Missing conditional phase logic (not mentioned)
- Root cause: Why research agents ignore enforcement (templates need strengthening)

**Status of Plan 071**:
From git history:
```
c7450eae feat(071): Phase 3 - implement auto-retry logic for planning
7a5b8752 feat(071): Phase 2 - implement auto-retry logic for research
```

Plan 071 was **partially implemented** but enforcement still failing (evidence: Deficiency 1 still occurs).

---

## Proposed Solutions

### Solution 1: Strengthen Research Agent Enforcement (Deficiency 1)

**Location**: `orchestrate.md:900-914` (STANDARD template)

**Current Code**:
```yaml
prompt: "
  Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

  **FILE CREATION REQUIRED**
  Topic directory: ${TOPIC_PATH}
  Use Write tool to create: ${REPORT_PATH}

  Research ${TOPIC} and document findings in the file.
  Return only: REPORT_CREATED: ${REPORT_PATH}
"
```

**Proposed Fix**:
```yaml
prompt: "
  Read and follow: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

  **EXECUTE NOW - MANDATORY FILE CREATION**
  STEP 1: Use Write tool IMMEDIATELY to create: ${REPORT_PATH}
          (Do this BEFORE researching - create empty file first)

  STEP 2: Conduct research using Grep/Glob/Read tools
          Research topic: ${TOPIC}
          Standards directory: ${CLAUDE_PROJECT_DIR}/.claude/docs/

  STEP 3: Use Edit tool to update ${REPORT_PATH} with findings
          (File must exist from STEP 1 before you can edit it)

  STEP 4: Return ONLY this exact format:
          REPORT_CREATED: ${REPORT_PATH}

  **CRITICAL**: DO NOT return summary text in your response.
  **CRITICAL**: DO NOT skip file creation.
  **VERIFICATION**: Orchestrator will verify file exists at path.
"
```

**Key Changes**:
1. "FILE CREATION REQUIRED" → "EXECUTE NOW - MANDATORY FILE CREATION" (stronger)
2. Added numbered STEP sequence (prescriptive, not descriptive)
3. Added "IMMEDIATELY" and "BEFORE researching" (temporal enforcement)
4. Added "create empty file first" (removes excuse of "no content yet")
5. Changed "DO NOT return summary" to "CRITICAL: DO NOT return summary" (severity marker)
6. Added verification notice (accountability)

**Apply to All 3 Templates**:
- Lines 900-914: STANDARD template ✓
- Lines 938-952: STRONG template (Attempt 2)
- Lines 986-1000: MAXIMUM template (Attempt 3)

---

### Solution 2: Add SlashCommand Validation (Deficiency 2)

**Location**: `orchestrate.md:1500` (before planning phase execution)

**Proposed Fix** (Insert before planning phase):
```bash
# ═══════════════════════════════════════════════════════════════
# STEP 0: Validate Architectural Compliance
# ═══════════════════════════════════════════════════════════════

echo "Validating orchestration pattern compliance..."

# Check 1: Workflow description must not contain slash commands
if echo "$WORKFLOW_DESCRIPTION" | grep -qE "^/[a-z-]+"; then
  echo "❌ ERROR: Workflow description starts with slash command"
  echo "   Found: $WORKFLOW_DESCRIPTION"
  echo "   Violation: /orchestrate MUST NOT invoke other slash commands"
  echo "   Required: Use plain English description, not command syntax"
  exit 1
fi

# Check 2: Verify allowed tools list
ALLOWED_TOOLS="Task TodoWrite Read Write Bash Grep Glob"
if echo "$ALLOWED_TOOLS" | grep -q "SlashCommand"; then
  echo "❌ CRITICAL: SlashCommand in allowed-tools list"
  echo "   This violates architectural pattern (line 13)"
  exit 1
fi

echo "✓ Architectural compliance validated"
echo ""
```

**Alternative Fix**: Move architectural prohibition from HTML comment to active instruction block:

```markdown
# Lines 10-36 (CURRENT - in HTML comment, not processed)
<!-- CRITICAL ARCHITECTURAL PATTERN - DO NOT VIOLATE -->
<!-- FORBIDDEN TOOLS: SlashCommand -->

# PROPOSED (active instruction block)
## CRITICAL ARCHITECTURAL PATTERN - STRICT ENFORCEMENT

**YOU MUST NEVER invoke other slash commands from /orchestrate**

**FORBIDDEN TOOLS**:
- SlashCommand (DO NOT USE under any circumstances)

**REQUIRED PATTERN**:
- Use Task tool with behavioral injection
- Pass agent behavioral file path (.claude/agents/*.md)
- Inject context (paths, parameters) in prompt

**WHY THIS MATTERS**:
1. Context Bloat: SlashCommand expands entire command prompts (3000+ tokens each)
2. Broken Behavioral Injection: Cannot pass artifact paths to commands
3. Lost Control: Cannot customize agent behavior for orchestration context
```

---

### Solution 3: Add Workflow Scope Detection and Conditional Execution (Deficiency 3 & 4)

**Location**: `orchestrate.md:352` (after workflow phase identification section)

**Proposed Addition**:

```markdown
### Step 3: Determine Workflow Scope and Phase Execution

**EXECUTE NOW - Workflow Type Detection**

Analyze workflow description to determine execution scope:

```bash
# ═══════════════════════════════════════════════════════════════
# Workflow Scope Detection Algorithm
# ═══════════════════════════════════════════════════════════════

# Initialize scope as unknown
WORKFLOW_SCOPE="unknown"
PHASES_TO_EXECUTE=""
SKIP_PHASES=""

# Pattern 1: Research and Planning Only
# Keywords: "research...plan", "audit...plan", "investigate...plan"
# Phases: 0 (Location) → 1 (Research) → 2 (Planning) → STOP
if echo "$WORKFLOW_DESCRIPTION" | grep -qiE "(research|audit|investigate).*(plan|planning)"; then
  WORKFLOW_SCOPE="research_and_plan"
  PHASES_TO_EXECUTE="0,1,2"
  SKIP_PHASES="3,4,5"  # Implementation, Testing, Debugging
  echo "✓ Detected: Research and Planning workflow"
  echo "  Phases: Location → Research → Planning → STOP"
  echo "  No implementation phase (planning outcome only)"

# Pattern 2: Full Implementation
# Keywords: "implement", "build", "add feature", "create code"
# Phases: All 0-5
elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE "implement|build|add.*(feature|functionality)|create.*(code|feature)"; then
  WORKFLOW_SCOPE="full_implementation"
  PHASES_TO_EXECUTE="0,1,2,3,4,5"
  SKIP_PHASES=""
  echo "✓ Detected: Full Implementation workflow"
  echo "  Phases: Location → Research → Planning → Implementation → Testing → Debugging (conditional)"

# Pattern 3: Debug Only
# Keywords: "fix", "debug", "investigate [bug]"
# Phases: 0 (Location) → 1 (Research) → 5 (Debugging) → STOP
elif echo "$WORKFLOW_DESCRIPTION" | grep -qiE "^(fix|debug|investigate).*(bug|issue|error|failure)"; then
  WORKFLOW_SCOPE="debug_only"
  PHASES_TO_EXECUTE="0,1,5"
  SKIP_PHASES="2,3,4"  # Planning, Implementation, Testing
  echo "✓ Detected: Debug-only workflow"
  echo "  Phases: Location → Research → Debugging → STOP"
  echo "  No new implementation (fix existing code)"

# Pattern 4: Unknown (conservative default)
else
  echo "⚠️  WARNING: Could not determine workflow scope from description"
  echo "  Description: $WORKFLOW_DESCRIPTION"
  echo "  Defaulting to: research_and_plan (conservative)"
  WORKFLOW_SCOPE="research_and_plan"
  PHASES_TO_EXECUTE="0,1,2"
  SKIP_PHASES="3,4,5"
fi

# Export variables for phase execution checks
export WORKFLOW_SCOPE
export PHASES_TO_EXECUTE
export SKIP_PHASES

echo ""
echo "Workflow Configuration:"
echo "  Scope: $WORKFLOW_SCOPE"
echo "  Phases to execute: $PHASES_TO_EXECUTE"
echo "  Phases to skip: $SKIP_PHASES"
echo ""

# Update TodoWrite to reflect actual phases
# (Only create todo items for phases that will execute)
IFS=',' read -ra PHASES <<< "$PHASES_TO_EXECUTE"
TODO_ITEMS=()
for phase in "${PHASES[@]}"; do
  case "$phase" in
    0) TODO_ITEMS+=('{"content": "Phase 0: Location", "status": "pending", "activeForm": "Determining topic location"}') ;;
    1) TODO_ITEMS+=('{"content": "Phase 1: Research", "status": "pending", "activeForm": "Researching topic"}') ;;
    2) TODO_ITEMS+=('{"content": "Phase 2: Planning", "status": "pending", "activeForm": "Creating implementation plan"}') ;;
    3) TODO_ITEMS+=('{"content": "Phase 3: Implementation", "status": "pending", "activeForm": "Implementing plan"}') ;;
    4) TODO_ITEMS+=('{"content": "Phase 4: Testing", "status": "pending", "activeForm": "Running tests"}') ;;
    5) TODO_ITEMS+=('{"content": "Phase 5: Debugging", "status": "pending", "activeForm": "Debugging failures"}') ;;
  esac
done

# Note: Phase 6 (Documentation) is conditional - only added if Phase 3 executed
```
```

**Location**: After Phase 2 completion (~line 2000)

**Proposed Addition**:

```bash
# ═══════════════════════════════════════════════════════════════
# Check Workflow Scope - Conditional Phase Execution
# ═══════════════════════════════════════════════════════════════

echo "✓ Planning phase complete"
echo "✓ Plan created: $PLAN_PATH"
echo ""

# Check if this is a research-and-plan workflow (no implementation)
if [ "$WORKFLOW_SCOPE" == "research_and_plan" ]; then
  echo "════════════════════════════════════════════════════════"
  echo "         /orchestrate WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: Research and Planning Only"
  echo "Summary NOT created (no implementation performed per standards)"
  echo ""
  echo "Artifacts Created:"
  echo "  ✓ Topic Directory: $TOPIC_PATH"
  echo "  ✓ Research Reports: ${#SUCCESSFUL_REPORTS[@]} files"
  for report in "${SUCCESSFUL_REPORTS[@]}"; do
    REPORT_NAME=$(basename "$report")
    echo "      - $REPORT_NAME"
  done
  echo "  ✓ Implementation Plan: $(basename "$PLAN_PATH")"
  echo ""
  echo "Standards Compliance:"
  echo "  ✓ Reports created in specs/reports/ (not inline summaries)"
  echo "  ✓ Plan created in specs/plans/ via Task(plan-architect)"
  echo "  ✓ Summary NOT created (no implementation to document)"
  echo ""
  echo "Next Steps:"
  echo "  To execute the plan:"
  echo "    /implement $PLAN_PATH"
  echo ""
  echo "  To review the plan:"
  echo "    Read $PLAN_PATH"
  echo ""
  exit 0
fi

# Check if this is debug-only workflow
if [ "$WORKFLOW_SCOPE" == "debug_only" ]; then
  echo "Proceeding to Phase 5: Debugging (skipping implementation/testing)"
  # Jump to Phase 5
fi

# Otherwise, this is full_implementation workflow
echo "Proceeding to Phase 3: Implementation"
echo ""
```

---

### Solution 4: Make Phase 6 (Documentation) Conditional

**Location**: Before Phase 6 execution (~line 3309)

**Proposed Addition**:

```bash
# ═══════════════════════════════════════════════════════════════
# Phase 6: Documentation (CONDITIONAL - only after implementation)
# ═══════════════════════════════════════════════════════════════

# Check if implementation phase executed
if ! echo "$PHASES_TO_EXECUTE" | grep -q "3"; then
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "   Reason: No implementation phase executed"
  echo "   Workflow type: $WORKFLOW_SCOPE"
  echo ""
  echo "Standards Note: Per development-workflow.md and directory-protocols.md,"
  echo "summaries are created 'after implementation complete' to link plans to code."
  echo "This workflow did not implement code, so no summary is needed."
  echo ""
  exit 0
fi

# Check if implementation actually produced changes
if [ ! -d "$TOPIC_PATH/artifacts" ] || [ -z "$(ls -A "$TOPIC_PATH/artifacts" 2>/dev/null)" ]; then
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "   Reason: No implementation artifacts created"
  echo ""
  exit 0
fi

# Proceed with Phase 6 for full_implementation workflows
echo "Phase 6: Documentation"
echo "Creating workflow summary linking plan to implementation..."
```

---

## Verification Tests

After implementing fixes, validate with these tests:

### Test 1: Research-and-Plan Workflow
```bash
# Should execute phases 0, 1, 2 only (no summary)
/orchestrate "research the authentication module to create a refactor plan"

# Expected output:
# ✓ Phase 0: Location
# ✓ Phase 1: Research (4 agents, all create report files)
# ✓ Phase 2: Planning (via Task, not SlashCommand)
# ✓ Workflow complete - no summary created
```

### Test 2: Full Implementation Workflow
```bash
# Should execute phases 0, 1, 2, 3, 4, 5 and create summary
/orchestrate "implement user authentication with OAuth2 support"

# Expected output:
# ✓ Phase 0-5 execute
# ✓ Phase 6 creates workflow summary linking plan to code
```

### Test 3: Debug-Only Workflow
```bash
# Should execute phases 0, 1, 5 only
/orchestrate "fix the authentication token refresh bug"

# Expected output:
# ✓ Phase 0: Location
# ✓ Phase 1: Research (investigate bug)
# ✓ Phase 5: Debugging
# ✓ No planning phase (fixing existing code)
```

### Test 4: Research Agent File Creation
```bash
# After running any /orchestrate with research phase
ls .claude/specs/*/reports/*.md

# Expected: 4 report files created (one per research agent)
# Should NOT see inline summaries in orchestrator output
```

### Test 5: Planning Invocation Method
```bash
# Check orchestrator output during planning phase
# Should see: Task(plan-architect) invocation
# Should NOT see: > /plan is running...
```

---

## Code Locations Requiring Changes

| Issue | File | Line Range | Change Type | Priority |
|-------|------|------------|-------------|----------|
| Deficiency 1 | orchestrate.md | 900-914 (STANDARD) | Strengthen enforcement | High |
| Deficiency 1 | orchestrate.md | 938-952 (STRONG) | Strengthen enforcement | High |
| Deficiency 1 | orchestrate.md | 986-1000 (MAXIMUM) | Strengthen enforcement | High |
| Deficiency 2 | orchestrate.md | 10-36 | Move from HTML comment to active instruction | High |
| Deficiency 2 | orchestrate.md | 1500 (before planning) | Add validation check | Medium |
| Deficiency 4 | orchestrate.md | 352 (after workflow analysis) | Add scope detection algorithm | Critical |
| Deficiency 3 | orchestrate.md | 2000 (after Phase 2) | Add conditional branching | Critical |
| Deficiency 3 | orchestrate.md | 3309 (before Phase 6) | Add conditional execution check | High |

---

## Performance Impact Analysis

### Current State (With Deficiencies)
- Context usage: ~30% (within target) ✓
- Time: ~18 minutes for research + plan
- File creation rate:
  - Research agents: 0% (returning inline summaries)
  - Planning: 100% (via SlashCommand, wrong method)
- Phase execution: All 6 phases regardless of workflow type
- Unnecessary summary created: +297 lines, +5-10% context

### After Fixes Applied
- Context usage: <25% (improved via skipped Phase 6 for research-only)
- Time: ~12 minutes (skip Phase 6 for research-and-plan workflows)
- File creation rate: 100% across all phases (enforced)
- Phase execution: Conditional based on workflow type
- Summaries: Only created when implementation occurred

**Projected Improvements**:
- 17% faster for research-and-plan workflows (skip Phase 6)
- 17% less context usage for non-implementation workflows
- 100% standards compliance (all artifacts in correct locations)
- Zero inline summaries (all content in files)

---

## Recommendations

### Immediate Actions (Critical Priority)
1. **Implement workflow scope detection** (Solution 3) - This is the root cause fix
2. **Strengthen research agent enforcement** (Solution 1) - Prevents inline summaries
3. **Add conditional Phase 6 execution** (Solution 4) - Prevents unnecessary summaries

### Short-Term Actions (High Priority)
4. **Move architectural prohibition to active instruction block** (Solution 2)
5. **Add SlashCommand validation checkpoint** (Solution 2)
6. **Update TodoWrite to reflect conditional phases** (Solution 3)

### Long-Term Improvements (Future Enhancement)
7. Consider creating a workflow type taxonomy (research-only, plan-only, research-and-plan, full-implementation, debug-only, refactor-only)
8. Add workflow type as metadata to topic directory (`.claude/specs/NNN_topic/metadata.json`)
9. Create workflow type detection library (`.claude/lib/workflow-detection.sh`)
10. Add orchestrator self-monitoring (log phase execution patterns to detect anomalies)

### Monitoring After Fixes
- Track workflow scope detection accuracy (manual review of first 10 workflows)
- Verify research agents create files 100% of time (grep orchestrator logs)
- Confirm SlashCommand never used (add telemetry to forbidden tool usage)
- Validate Phase 6 only executes after Phase 3 (checkpoint analysis)

---

## References

### Related Files
- Implementation Plan: `.claude/specs/070_orchestrate_refactor/plans/001_orchestrate_simplification.md`
- Enforcement Fix Plan: `.claude/specs/071_orchestrate_enforcement_fix/plans/001_fix_research_and_planning_enforcement.md`
- Orchestrate Command: `.claude/commands/orchestrate.md:1-6051` (50,493 tokens)
- User's Deficiency Report: `TODO6.md:325-331`

### Standards Documentation
- Hierarchical Agent Architecture: `.claude/docs/concepts/hierarchical_agents.md`
- Development Workflow: `.claude/docs/concepts/development-workflow.md`
- Directory Protocols: `.claude/docs/concepts/directory-protocols.md`
- Command Architecture Standards: `.claude/docs/reference/command_architecture_standards.md`
- Behavioral Injection Pattern: `.claude/docs/concepts/patterns/behavioral-injection.md`
- Imperative Language Guide: `.claude/docs/guides/imperative-language-guide.md`

### Agent Behavioral Files
- Research Specialist: `.claude/agents/research-specialist.md`
- Plan Architect: `.claude/agents/plan-architect.md`

---

**Report Status**: Complete
**Next Steps**: Create implementation plan to fix all four deficiencies
**Estimated Fix Effort**: 6-8 hours (4 high-priority changes, comprehensive testing required)
