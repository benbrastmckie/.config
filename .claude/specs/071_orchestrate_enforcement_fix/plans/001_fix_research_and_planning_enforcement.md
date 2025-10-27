# /orchestrate Research and Planning Enforcement Fix - Implementation Plan

## Metadata
- **Date**: 2025-10-22 (Revised: 2025-10-23)
- **Feature**: Remove fallbacks from /orchestrate - enforce strict subagent-only operation with auto-recovery and Standard 0 compliance
- **Scope**: Remove command fallbacks, add auto-retry recovery, ensure ONLY subagents create reports and plans, implement Standard 0 enforcement markers and Phase 0 orchestrator role clarification
- **Estimated Phases**: 6 (Phase 0 added in Revision 3)
- **Structure Level**: 1
- **Expanded Phases**: [0]
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Context**: TODO2.md issue report, strict subagent enforcement with auto-recovery requirement, Plan 002 improvement suggestions for standards compliance
- **Plan Number**: 071-001
- **Related Plans**: 002_orchestrate_improvement_suggestions.md (Plan 070-002)

## Overview

This plan removes all fallback mechanisms from `/orchestrate` to enforce strict subagent-only operation. The command will ONLY invoke subagents to create reports and plans, and will NEVER call commands or create artifacts directly.

**Design Philosophy**:
- **Pure Subagent Orchestration**: /orchestrate is a coordinator, not an executor
- **Auto-Recovery**: If subagent fails, retry with escalating enforcement (no orchestrator fallback)
- **No Command Invocation**: NEVER call /report, /plan, or any slash commands
- **Agent Responsibility**: Subagents are fully responsible for artifact creation
- **Degraded Continuation**: Workflow continues with partial results if some topics fail after retries

**Current Problems**:

1. **Fallback Mechanisms**: Orchestrator creates files when agents fail (lines 995-1143)
2. **Command Invocation**: Documentation suggests /plan command may be used (line 1516)
3. **Mixed Responsibility**: Both agents and orchestrator can create artifacts

**Target State**:

1. **Research Phase**: ONLY research subagents create report files
   - Agents receive pre-calculated paths via context injection
   - Agents use Write tool to create reports
   - Agents return: `REPORT_CREATED: /path/to/report.md`
   - **Auto-Retry**: If agent fails, retry up to 3 times with escalating enforcement
   - **Degraded Continuation**: If all retries fail, continue workflow with partial results

2. **Planning Phase**: ONLY plan-architect subagent creates plan file
   - Agent receives pre-calculated path via context injection
   - Agent uses Write tool to create plan
   - Agent returns: `PLAN_CREATED: /path/to/plan.md`
   - **Auto-Retry**: If agent fails, retry up to 3 times with escalating enforcement
   - **Critical Failure**: Workflow terminates if planning fails (need at least one report)

3. **No Orchestrator Fallbacks**: Orchestrator NEVER creates files
   - Only subagents create files (even on retry)
   - Retry uses different/stronger agent prompts
   - If all retries fail, topic is skipped (not created by orchestrator)
   - Workflow summary shows successful and failed topics

## Success Criteria

### Core Functionality (Original Plan 071)
- [ ] All fallback mechanisms removed from orchestrate.md (no orchestrator file creation)
- [ ] Auto-retry mechanism implemented with 3 attempts per subagent
- [ ] Multiple agent template variations created (standard, ultra-explicit, step-by-step)
- [ ] Research phase continues with partial results if some topics fail
- [ ] Planning phase retries up to 3 times, fails workflow only if all attempts fail
- [ ] Workflow summary reports successful and failed topics
- [ ] Research agents return ONLY file path confirmations (no summaries)
- [ ] Planning phase uses ONLY Task(plan-architect) (NEVER SlashCommand)
- [ ] No command invocations anywhere in orchestrate.md
- [ ] Test: /orchestrate retries failing subagents (verify 3 attempts)
- [ ] Test: /orchestrate continues with partial results when some topics fail
- [ ] Test: /orchestrate terminates only if planning fails after retries or no reports created

### Standards Compliance (Plan 002 Enhancements)
- [ ] **Phase 0 Orchestrator Role**: Explicit orchestrator role clarification added at beginning
  - [ ] "YOUR ROLE" declaration present
  - [ ] "CRITICAL INSTRUCTIONS" section with DO NOT directives
  - [ ] "ONLY" directives for coordination-only behavior
  - [ ] "You will NOT see [results] directly" explanation
- [ ] **Standard 0 Enforcement Markers**: Minimum pattern counts met
  - [ ] ≥12 "EXECUTE NOW" markers for critical operations
  - [ ] ≥8 "MANDATORY VERIFICATION" blocks for file operations
  - [ ] ≥6 "CHECKPOINT REQUIREMENT" blocks at phase boundaries
  - [ ] "CRITICAL INSTRUCTION", "ABSOLUTE REQUIREMENT" used for key steps
- [ ] **Imperative Language**: ≥90% imperative ratio (validated via audit script)
  - [ ] All "should" → "MUST" transformations complete
  - [ ] All "can" → "WILL" transformations complete
  - [ ] All "may" → "SHALL" transformations complete
  - [ ] All "consider" → "MUST" transformations complete
  - [ ] All "try to" → "WILL" transformations complete
  - [ ] Zero weak language remaining (validated)
- [ ] **Context Pruning Policy**: <20% context usage target
  - [ ] Pruning after research phase implemented
  - [ ] Pruning after planning phase implemented
  - [ ] Metadata extraction + pruning for 92-97% reduction
- [ ] **Audit Validation**: Standards compliance verified
  - [ ] Audit score ≥95/100 (execution enforcement)
  - [ ] Imperative ratio ≥90% (language strength)
  - [ ] File creation rate 100% (10/10 test trials)
  - [ ] Pattern counts validated (12 EXECUTE NOW, 8 MANDATORY, 6 CHECKPOINT)
  - [ ] Weak language count = 0

## Technical Design

### Auto-Recovery Strategy Overview

The orchestrator uses a **retry-with-escalation** approach:

1. **Attempt 1**: Standard enforcement template
2. **Attempt 2**: Ultra-explicit enforcement template (more verbose, numbered steps)
3. **Attempt 3**: Step-by-step verification template (agent must verify after each step)

Each retry uses a **different subagent invocation** with progressively stronger enforcement, NOT the same prompt.

### Phase 1: Create Agent Template Variations

**Three Template Variations** (one file, different sections):

**1. Standard Template** (baseline enforcement):
```markdown
**RESEARCH AGENT INVOCATION - STANDARD**

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} - file creation MANDATORY"
  prompt: "
    **FILE CREATION REQUIRED**

    Use Write tool to create: ${REPORT_PATHS[$TOPIC]}

    Research ${TOPIC} and document findings in the file.

    Return only: REPORT_CREATED: ${REPORT_PATHS[$TOPIC]}
  "
}
```

**2. Ultra-Explicit Template** (enhanced enforcement):
```markdown
**RESEARCH AGENT INVOCATION - ULTRA-EXPLICIT**

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} - RETRY with ultra-explicit enforcement"
  prompt: "
    **CRITICAL: You MUST create a file. This is NON-NEGOTIABLE.**

    **STEP 1 - CREATE FILE NOW**
    Use the Write tool RIGHT NOW with this exact path:
    ${REPORT_PATHS[$TOPIC]}

    **STEP 2 - RESEARCH**
    Research ${TOPIC} thoroughly and document in the file.

    **STEP 3 - RETURN CONFIRMATION ONLY**
    Return ONLY this text: REPORT_CREATED: ${REPORT_PATHS[$TOPIC]}

    **PROHIBITED**: Do NOT return summaries or findings in your response.
  "
}
```

**3. Step-by-Step Verification Template** (maximum enforcement):
```markdown
**RESEARCH AGENT INVOCATION - STEP-BY-STEP**

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} - FINAL RETRY with step verification"
  prompt: "
    **EXECUTE IMMEDIATELY: File creation is your PRIMARY and ONLY deliverable**

    **ACTION 1: CREATE THE FILE**
    Use Write tool NOW: ${REPORT_PATHS[$TOPIC]}
    Initial content: '# Research Report: ${TOPIC}'

    **ACTION 2: VERIFY FILE CREATED**
    Use Read tool to confirm file exists: ${REPORT_PATHS[$TOPIC]}

    **ACTION 3: CONDUCT RESEARCH**
    Research ${TOPIC} using Grep/Glob/Read tools

    **ACTION 4: UPDATE FILE**
    Use Edit tool to add findings to ${REPORT_PATHS[$TOPIC]}

    **ACTION 5: FINAL VERIFICATION**
    Use Read tool to verify content exists

    **ACTION 6: RETURN CONFIRMATION**
    Return ONLY: REPORT_CREATED: ${REPORT_PATHS[$TOPIC]}

    **CRITICAL**: If you skip any action, you will fail. Each action is MANDATORY.
  "
}
```

### Phase 2: Implement Auto-Retry Logic

**Research Phase with Retry**:
```bash
invoke_research_agent_with_retry() {
  local topic=$1
  local max_attempts=3
  local templates=("standard" "ultra_explicit" "step_by_step")

  for attempt in $(seq 1 $max_attempts); do
    template="${templates[$((attempt-1))]}"

    echo "Invoking research agent for '$topic' (attempt $attempt/$max_attempts, template: $template)"

    # Invoke appropriate template
    invoke_research_agent "$topic" "$template"

    # Check if file created
    if [ -f "${REPORT_PATHS[$topic]}" ]; then
      # Validate file has content
      if [ -s "${REPORT_PATHS[$topic]}" ]; then
        echo "✓ Success on attempt $attempt (template: $template)"
        return 0
      else
        echo "⚠️  File created but empty, retrying..."
        rm "${REPORT_PATHS[$topic]}"  # Clean up empty file
      fi
    else
      echo "⚠️  Attempt $attempt failed (file not created)"
    fi

    [ $attempt -lt $max_attempts ] && echo "Retrying with enhanced enforcement..."
  done

  echo "❌ All $max_attempts retry attempts failed for topic: $topic"
  return 1
}

# Main research loop with degraded continuation
SUCCESSFUL_REPORTS=()
FAILED_TOPICS=()

for topic in "${TOPICS[@]}"; do
  echo ""
  echo "=== Researching: $topic ==="

  if invoke_research_agent_with_retry "$topic"; then
    SUCCESSFUL_REPORTS+=("${REPORT_PATHS[$topic]}")
  else
    FAILED_TOPICS+=("$topic")
    echo "Continuing to next topic..."
  fi
done

# Check if we have at least one report
if [ ${#SUCCESSFUL_REPORTS[@]} -eq 0 ]; then
  echo ""
  echo "❌ CRITICAL: No research reports created - cannot proceed to planning"
  echo "All topics failed: ${TOPICS[@]}"
  exit 1
fi

# Show summary before planning
echo ""
echo "=== RESEARCH PHASE SUMMARY ==="
echo "Successful: ${#SUCCESSFUL_REPORTS[@]}/${#TOPICS[@]} topics"
if [ ${#FAILED_TOPICS[@]} -gt 0 ]; then
  echo "⚠️  Failed topics: ${FAILED_TOPICS[@]}"
  echo "Proceeding to planning with partial results..."
fi
```

### Phase 3: Planning Phase Auto-Retry

**Planning with Retry** (similar structure):
```bash
invoke_plan_architect_with_retry() {
  local max_attempts=3
  local templates=("standard" "ultra_explicit" "step_by_step")

  for attempt in $(seq 1 $max_attempts); do
    template="${templates[$((attempt-1))]}"

    echo "Invoking plan-architect (attempt $attempt/$max_attempts, template: $template)"

    invoke_plan_architect "$template"

    if [ -f "$PLAN_PATH" ] && [ -s "$PLAN_PATH" ]; then
      echo "✓ Plan created successfully on attempt $attempt"
      return 0
    fi

    echo "⚠️  Attempt $attempt failed"
    [ $attempt -lt $max_attempts ] && echo "Retrying..."
  done

  echo "❌ All planning attempts failed"
  return 1
}

# Invoke with error handling
if ! invoke_plan_architect_with_retry; then
  echo ""
  echo "❌ CRITICAL: Planning phase failed after $max_attempts attempts"
  echo "Cannot complete workflow without implementation plan"
  exit 1
fi
```

### Phase 4: Workflow Summary

**Final Summary** (always shown):
```bash
echo ""
echo "============================================"
echo "    /orchestrate WORKFLOW SUMMARY"
echo "============================================"
echo ""
echo "Research Phase:"
echo "  ✓ Successful: ${#SUCCESSFUL_REPORTS[@]} topics"
[ ${#FAILED_TOPICS[@]} -gt 0 ] && echo "  ❌ Failed: ${#FAILED_TOPICS[@]} topics"
echo ""
echo "Planning Phase:"
echo "  ✓ Plan created: $PLAN_PATH"
echo ""

if [ ${#FAILED_TOPICS[@]} -gt 0 ]; then
  echo "⚠️  WORKFLOW COMPLETED WITH WARNINGS"
  echo ""
  echo "Failed research topics:"
  for topic in "${FAILED_TOPICS[@]}"; do
    echo "  - $topic"
  done
  echo ""
  echo "Note: Plan was created with partial research results."
  echo "Consider re-running research for failed topics manually."
else
  echo "✓ WORKFLOW COMPLETED SUCCESSFULLY"
  echo "All research topics completed and plan created."
fi

echo ""
echo "Artifacts created:"
echo "  Plan: $PLAN_PATH"
echo "  Reports: ${#SUCCESSFUL_REPORTS[@]} files"
for report in "${SUCCESSFUL_REPORTS[@]}"; do
  echo "    - $report"
done
echo ""
```

## Implementation Phases

### Phase 0: Add Orchestrator Role Clarification and Enforcement Standards (High Complexity)
**Objective**: Add Phase 0 orchestrator role clarification and Standard 0 enforcement markers throughout orchestrate.md to ensure strict coordination-only behavior.

**Status**: PENDING

**Summary**: Comprehensive implementation of Standard 0 enforcement patterns including orchestrator role clarification, execution enforcement markers (≥12 EXECUTE NOW, ≥8 MANDATORY VERIFICATION, ≥6 CHECKPOINT), imperative language transformation (≥90% ratio), and aggressive context pruning policy (<20% usage target).

For detailed implementation steps, testing strategies, and code examples, see:
**[Phase 0 Details - Orchestrator Role and Standards](phase_0_orchestrator_role_and_standards.md)**

---

### Phase 1: Create Agent Template Variations [COMPLETED]
**Objective**: Create three template variations (standard, ultra-explicit, step-by-step) for auto-retry escalation.

**Complexity**: Low

**Tasks**:
- [x] Read `/home/benjamin/.config/.claude/commands/orchestrate.md` research agent section (lines 877-926)
- [x] Create three research agent template sections:
  - [x] **Standard Template**: Baseline enforcement (FILE CREATION REQUIRED)
  - [x] **Ultra-Explicit Template**: Enhanced enforcement (CRITICAL, STEP 1-3, PROHIBITED)
  - [x] **Step-by-Step Template**: Maximum enforcement (ACTION 1-6, must verify each step)
- [x] Create three plan-architect template sections:
  - [x] **Standard Template**: Baseline enforcement
  - [x] **Ultra-Explicit Template**: Enhanced enforcement
  - [x] **Step-by-Step Template**: Maximum enforcement
- [x] Add template selection logic (based on attempt number)
- [x] Document template escalation strategy

**Testing**:
```bash
# Verify three research templates exist
grep -q "RESEARCH AGENT INVOCATION - STANDARD" .claude/commands/orchestrate.md
grep -q "RESEARCH AGENT INVOCATION - ULTRA-EXPLICIT" .claude/commands/orchestrate.md
grep -q "RESEARCH AGENT INVOCATION - STEP-BY-STEP" .claude/commands/orchestrate.md

# Verify three planning templates exist
grep -q "PLAN-ARCHITECT INVOCATION - STANDARD" .claude/commands/orchestrate.md
grep -q "PLAN-ARCHITECT INVOCATION - ULTRA-EXPLICIT" .claude/commands/orchestrate.md
grep -q "PLAN-ARCHITECT INVOCATION - STEP-BY-STEP" .claude/commands/orchestrate.md
```

**Git Commit**: `feat(071): Phase 1 - create agent template variations for auto-retry escalation`

---

### Phase 2: Implement Auto-Retry Logic for Research [COMPLETED]
**Objective**: Add retry wrapper function that attempts up to 3 times with escalating template enforcement.

**Complexity**: Medium

**Tasks**:
- [x] Read current research agent invocation code in orchestrate.md
- [x] Create `invoke_research_agent_with_retry()` function:
  - [x] Accept topic parameter
  - [x] Loop 3 times (max_attempts=3)
  - [x] Select template based on attempt number (standard → ultra-explicit → step-by-step)
  - [x] Invoke research agent with selected template
  - [x] Check if file created with [ -f "$path" ]
  - [x] Validate file has content with [ -s "$path" ]
  - [x] Return 0 on success, 1 after all attempts fail
- [x] Update main research loop to use retry function
- [x] Track successful and failed topics in arrays
- [x] Add "Continuing to next topic..." message on failure
- [x] Add critical check: exit if NO reports created

**Testing**:
```bash
# Verify retry function exists
grep -q "invoke_research_agent_with_retry()" .claude/commands/orchestrate.md

# Verify 3 attempts
grep -A 20 "invoke_research_agent_with_retry" .claude/commands/orchestrate.md | grep -q "max_attempts=3"

# Verify template escalation
grep -A 20 "invoke_research_agent_with_retry" .claude/commands/orchestrate.md | grep -q "templates=(\"standard\" \"ultra_explicit\" \"step_by_step\")"

# Verify degraded continuation
grep -q "FAILED_TOPICS+=" .claude/commands/orchestrate.md
grep -q "Continuing to next topic" .claude/commands/orchestrate.md
```

**Git Commit**: `feat(071): Phase 2 - implement auto-retry logic for research with escalating enforcement`

---

### Phase 3: Implement Auto-Retry Logic for Planning [COMPLETED]
**Objective**: Add retry wrapper function for plan-architect with same 3-attempt strategy.

**Complexity**: Medium

**Tasks**:
- [x] Read current plan-architect invocation code in orchestrate.md
- [x] Create `invoke_plan_architect_with_retry()` function:
  - [x] Loop 3 times (max_attempts=3)
  - [x] Select template based on attempt (standard → ultra-explicit → step-by-step)
  - [x] Invoke plan-architect with selected template
  - [x] Check if plan file created and has content
  - [x] Return 0 on success, 1 after all attempts fail
- [x] Update planning phase to use retry function
- [x] Add critical failure check: exit if planning fails after all retries
- [x] Ensure planning only proceeds if at least one research report exists

**Testing**:
```bash
# Verify retry function exists
grep -q "invoke_plan_architect_with_retry()" .claude/commands/orchestrate.md

# Verify critical failure handling
grep -A 5 "invoke_plan_architect_with_retry" .claude/commands/orchestrate.md | grep -q "exit 1"

# Verify requires at least one report
grep -B 10 "invoke_plan_architect_with_retry" .claude/commands/orchestrate.md | grep -q "SUCCESSFUL_REPORTS\[@\]} -eq 0"
```

**Git Commit**: `feat(071): Phase 3 - implement auto-retry logic for planning with escalating enforcement`

---

### Phase 4: Add Workflow Summary Report [COMPLETED]
**Objective**: Display comprehensive summary showing successful/failed topics and all artifacts created.

**Complexity**: Low

**Tasks**:
- [x] Create workflow summary section at end of orchestrate.md
- [x] Add summary header with visual separator
- [x] Report research phase results:
  - [x] Successful topic count
  - [x] Failed topic count (if any)
  - [x] List failed topics
- [x] Report planning phase results:
  - [x] Plan file path
- [x] Add overall status:
  - [x] "COMPLETED WITH WARNINGS" if failures exist
  - [x] "COMPLETED SUCCESSFULLY" if all succeeded
- [x] List all artifacts created (plan + reports)

**Testing**:
```bash
# Verify summary section exists
grep -q "WORKFLOW SUMMARY" .claude/commands/orchestrate.md

# Verify reports successful/failed counts
grep -q "Successful.*SUCCESSFUL_REPORTS" .claude/commands/orchestrate.md
grep -q "Failed.*FAILED_TOPICS" .claude/commands/orchestrate.md

# Verify artifact listing
grep -q "Artifacts created" .claude/commands/orchestrate.md
```

**Git Commit**: `feat(071): Phase 4 - add comprehensive workflow summary report`

---

### Phase 5: Remove All Fallback Mechanisms and Command Invocations [COMPLETED]
**Objective**: Audit and remove ALL orchestrator fallback file creation and slash command invocations.

**Complexity**: Medium

**Tasks**:
- [x] Search orchestrate.md for ALL instances of:
  - [x] Fallback file creation (`cat > "$PATH" <<EOF`)
  - [x] `SlashCommand("/report")`, `SlashCommand("/plan")`
  - [x] Any orchestrator Write/Edit tool usage (should only be in agents)
- [x] Remove fallback sections from verification checkpoints
- [x] Replace any command invocations with Task tool invocations
- [x] Add "Auto-Recovery Architecture" documentation section:
  - [x] Explain retry-with-escalation strategy
  - [x] Explain degraded continuation for research
  - [x] Explain critical failure for planning
  - [x] Explain no orchestrator fallbacks policy
- [x] Verify orchestrator ONLY coordinates (never creates files)

**Testing**:
```bash
# Verify NO fallbacks
! grep -q "cat > .* <<EOF" .claude/commands/orchestrate.md
! grep -q "Fallback: Create" .claude/commands/orchestrate.md

# Verify NO command invocations
! grep -q "SlashCommand" .claude/commands/orchestrate.md

# Verify architecture documentation
grep -q "Auto-Recovery Architecture" .claude/commands/orchestrate.md
grep -q "retry-with-escalation" .claude/commands/orchestrate.md
```

**Git Commit**: `refactor(071): Phase 5 - remove all fallbacks and command invocations, document auto-recovery`

---

## Testing Strategy

### Standards Compliance Validation

**Test Standards Enforcement** (using audit scripts):
```bash
#!/bin/bash
# Test Standard 0 enforcement compliance

ORCHESTRATE_FILE=".claude/commands/orchestrate.md"

echo "=== Standards Compliance Validation ==="

# Test 1: Execution enforcement audit
echo "Running execution enforcement audit..."
AUDIT_SCORE=$(.claude/lib/audit-execution-enforcement.sh "$ORCHESTRATE_FILE" | grep -oP 'Score: \K\d+')
if [ "$AUDIT_SCORE" -lt 95 ]; then
  echo "FAIL: Audit score $AUDIT_SCORE/100 (need ≥95)"
  exit 1
fi
echo "✓ Audit score: $AUDIT_SCORE/100 (≥95 required)"

# Test 2: Imperative language ratio
echo "Running imperative language audit..."
IMPERATIVE_RATIO=$(.claude/lib/audit-imperative-language.sh "$ORCHESTRATE_FILE" | grep -oP 'Imperative Ratio: \K\d+')
if [ "$IMPERATIVE_RATIO" -lt 90 ]; then
  echo "FAIL: Imperative ratio $IMPERATIVE_RATIO% (need ≥90%)"
  exit 1
fi
echo "✓ Imperative ratio: $IMPERATIVE_RATIO% (≥90% required)"

# Test 3: Pattern minimum counts
EXECUTE_NOW_COUNT=$(grep -c "EXECUTE NOW" "$ORCHESTRATE_FILE")
MANDATORY_COUNT=$(grep -c "MANDATORY VERIFICATION" "$ORCHESTRATE_FILE")
CHECKPOINT_COUNT=$(grep -c "CHECKPOINT REQUIREMENT" "$ORCHESTRATE_FILE")

if [ "$EXECUTE_NOW_COUNT" -lt 12 ]; then
  echo "FAIL: Only $EXECUTE_NOW_COUNT EXECUTE NOW markers (need ≥12)"
  exit 1
fi
echo "✓ EXECUTE NOW markers: $EXECUTE_NOW_COUNT (≥12 required)"

if [ "$MANDATORY_COUNT" -lt 8 ]; then
  echo "FAIL: Only $MANDATORY_COUNT MANDATORY VERIFICATION markers (need ≥8)"
  exit 1
fi
echo "✓ MANDATORY VERIFICATION markers: $MANDATORY_COUNT (≥8 required)"

if [ "$CHECKPOINT_COUNT" -lt 6 ]; then
  echo "FAIL: Only $CHECKPOINT_COUNT CHECKPOINT markers (need ≥6)"
  exit 1
fi
echo "✓ CHECKPOINT markers: $CHECKPOINT_COUNT (≥6 required)"

# Test 4: Weak language check
WEAK_LANGUAGE=$(grep -E '\b(should|may|can|consider|try to)\b' "$ORCHESTRATE_FILE" | wc -l)
if [ "$WEAK_LANGUAGE" -gt 0 ]; then
  echo "WARNING: Found $WEAK_LANGUAGE instances of weak language (should/may/can/consider/try)"
fi

# Test 5: File creation reliability (10 test trials)
echo "Running file creation reliability test (10 trials)..."
SUCCESS_COUNT=0
for i in $(seq 1 10); do
  # Test research agent invocation creates file
  # (Implementation-specific test - add actual test logic here)
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
done
if [ "$SUCCESS_COUNT" -lt 10 ]; then
  echo "FAIL: File creation rate ${SUCCESS_COUNT}/10 (need 10/10)"
  exit 1
fi
echo "✓ File creation rate: ${SUCCESS_COUNT}/10 (100% required)"

echo "=== All Standards Compliance Tests Passed ==="
```

### Unit Tests

**Test Research Agent Template**:
```bash
#!/bin/bash
# Test enhanced research agent template

ORCHESTRATE_FILE=".claude/commands/orchestrate.md"

echo "=== Research Agent Template Test ==="

# Test 1: EXECUTE NOW present
grep -A 50 "AGENT INVOCATION" "$ORCHESTRATE_FILE" | grep -q "EXECUTE NOW" || {
  echo "FAIL: EXECUTE NOW marker missing"
  exit 1
}
echo "✓ EXECUTE NOW marker present"

# Test 2: YOU MUST imperative
grep -A 50 "AGENT INVOCATION" "$ORCHESTRATE_FILE" | grep -q "YOU MUST" || {
  echo "FAIL: YOU MUST imperative missing"
  exit 1
}
echo "✓ YOU MUST imperative present"

# Test 3: Step 4 verification
grep -A 50 "AGENT INVOCATION" "$ORCHESTRATE_FILE" | grep -q "STEP 4: RETURN CONFIRMATION ONLY" || {
  echo "FAIL: Step 4 verification missing"
  exit 1
}
echo "✓ Step 4 verification present"

# Test 4: ENFORCEMENT warning
grep -A 60 "AGENT INVOCATION" "$ORCHESTRATE_FILE" | grep -q "ENFORCEMENT" || {
  echo "FAIL: ENFORCEMENT warning missing"
  exit 1
}
echo "✓ ENFORCEMENT warning present"

echo "=== All Template Tests Passed ==="
```

**Test Verification Checkpoint**:
```bash
#!/bin/bash
# Test enhanced verification checkpoint

ORCHESTRATE_FILE=".claude/commands/orchestrate.md"

echo "=== Verification Checkpoint Test ==="

# Test 1: YOU MUST execute
grep -A 100 "MANDATORY VERIFICATION" "$ORCHESTRATE_FILE" | grep -q "YOU MUST execute" || {
  echo "FAIL: YOU MUST execute missing"
  exit 1
}
echo "✓ YOU MUST execute present"

# Test 2: File size check
grep -A 100 "MANDATORY VERIFICATION" "$ORCHESTRATE_FILE" | grep -q "File size" || {
  echo "FAIL: File size validation missing"
  exit 1
}
echo "✓ File size validation present"

# Test 3: Fallback preserved
grep -A 100 "MANDATORY VERIFICATION" "$ORCHESTRATE_FILE" | grep -q "FALLBACK" || {
  echo "FAIL: Fallback mechanism missing"
  exit 1
}
echo "✓ Fallback mechanism present"

echo "=== All Verification Tests Passed ==="
```

### Integration Tests

**Test 1: End-to-End /orchestrate Execution**
```bash
# Execute /orchestrate with test workflow
/orchestrate "Research testing best practices for Lua and create implementation plan"

# Expected behavior:
# 1. Research agents create report files (not just return summaries)
# 2. Verification checkpoint confirms files exist
# 3. Planning agent uses Task tool (not SlashCommand)
# 4. Plan created successfully
# 5. All artifacts exist at expected paths

# Verification:
# - Check research reports exist in specs/*/reports/
# - Check plan exists in specs/*/plans/
# - Check no SlashCommand("/plan") in logs
# - Check agents returned REPORT_CREATED confirmations
```

**Test 2: Fallback Mechanism**
```bash
# Simulate agent non-compliance (agent returns summary instead of creating file)
# This tests fallback creates file from agent output

# Expected behavior:
# 1. Agent returns summary (doesn't create file)
# 2. Verification detects missing file
# 3. Fallback creates file from agent output
# 4. Workflow continues successfully
# 5. Final result: report file exists (via fallback)
```

### Manual Validation

1. **Research Agent Behavior**:
   - Execute /orchestrate with simple research workflow
   - Watch research agent outputs
   - Verify agents use Write tool to create files
   - Verify agents return "REPORT_CREATED: /path" confirmations
   - Verify NO summaries in agent outputs

2. **Fail-Fast Verification**:
   - Execute /orchestrate
   - Watch verification checkpoint execution
   - If agent complies: Verify success messages
   - If agent fails: Verify workflow terminates with clear error
   - Verify NO fallback file creation occurs
   - Verify error message includes troubleshooting steps

3. **Planning Phase (Subagent-Only)**:
   - Execute /orchestrate through planning
   - Verify Task tool invocation (not SlashCommand)
   - Verify NO "/plan is running..." message
   - Verify plan-architect agent uses Write tool
   - Verify plan created by agent (not orchestrator)

## Documentation Requirements

### Update Files

1. **orchestrate.md**:
   - Lines 877-926: Enhanced research agent template
   - Lines 995-1143: Enhanced verification checkpoint
   - Line 1516: Fixed planning documentation
   - Lines 1576-1582: Added planning implementation details

2. **TODO2.md**:
   - Mark as resolved
   - Link to this implementation plan
   - Note verification+fallback pattern now more visible

3. **CHANGELOG** (if exists):
   - Document enforcement enhancements
   - Document documentation fixes
   - Note improved research agent compliance

## Dependencies

### Internal Dependencies
- `.claude/commands/orchestrate.md` - File being modified
- `.claude/agents/plan-architect.md` - Referenced for planning clarification
- `.claude/docs/concepts/patterns/verification-fallback.md` - Pattern reference

### External Dependencies
None

### Breaking Changes
None - these are enhancements and documentation fixes that maintain backward compatibility.

## Migration Guide

No migration required. Changes are:
1. **Enhancements**: Stronger enforcement of existing patterns
2. **Documentation**: Clarification of existing behavior

Users will see:
- More reliable research agent file creation (higher compliance rate)
- Better visibility into verification process (echo statements)
- Clearer understanding of planning phase architecture (documentation fix)

## Notes

### Design Rationale

**Why Remove Fallbacks?**
Fallbacks hide failures and create mixed responsibility:
1. **Clarity**: Single responsibility - subagents create files, orchestrator verifies
2. **Debugging**: Immediate failure reveals subagent issues, not masked by fallback
3. **Simplicity**: No dual-path logic (primary + fallback)
4. **Expectations**: User expects /orchestrate to coordinate agents, not execute work

**Why Fail-Fast?**
Explicit failures are better than silent workarounds:
1. **Visibility**: User sees exactly what failed and why
2. **Reliability**: No hidden compensations that might mask deeper issues
3. **Maintainability**: Simpler code with single execution path
4. **Trust**: User knows artifacts are agent-created, not orchestrator-created

**Why No Command Invocations?**
/orchestrate is a coordinator, not a meta-command:
1. **Architecture**: Behavioral injection pattern (Task tool) vs command delegation (SlashCommand)
2. **Control**: Direct agent invocation allows precise context injection
3. **Flexibility**: Agents can use tools directly without command overhead
4. **Clarity**: Clear separation - commands for user, agents for orchestrator

### Breaking Changes

**User-Visible Changes**:
1. **Retry Behavior**: /orchestrate now retries failed subagents up to 3 times
   - **Before**: Fallback would create files immediately on first failure
   - **After**: 3 retry attempts with escalating enforcement, then skip topic
   - **Impact**: Slower execution if retries needed (~3x for failed topics)
   - **Benefit**: Higher success rate through template variation

2. **Partial Results**: Workflow continues even if some research topics fail
   - **Before**: Workflow succeeded 100% (via fallback)
   - **After**: Workflow shows partial success (e.g., "3/5 topics succeeded")
   - **Impact**: Plan may be incomplete if many topics fail
   - **Benefit**: Get some value even with failures

3. **Planning Critical**: Workflow terminates only if planning fails after all retries
   - **Before**: Planning always succeeded (via fallback)
   - **After**: Workflow fails if all 3 planning attempts fail
   - **Mitigation**: Requires at least 1 research report to exist

4. **Workflow Summary**: New detailed summary at end
   - Shows successful/failed topics
   - Lists all artifacts created
   - Clear warnings if partial results

### Migration Strategy

**For Existing Workflows**:
1. **No Breaking Changes**: Auto-retry is transparent to user
2. **Slower on Failures**: Workflows may take longer if retries needed
3. **Monitor Summary**: Check workflow summary for failed topics
4. **Partial Results**: Plan created with available research (not all topics)

**Expected Behavior**:
- **First run**: May see retry messages, some topics may fail
- **Template effectiveness**: Each retry attempt uses stronger enforcement
- **Success rate**: Estimated 70-90% per topic (higher than 20-40% without retries)
- **Overall completion**: Most workflows complete with partial or full results

**Rollback Plan** (if needed):
If auto-retry causes unacceptable delays or failures:
1. Reduce max_attempts from 3 to 2 (faster, but less recovery)
2. Keep only standard + ultra-explicit templates (skip step-by-step)
3. Add back minimal orchestrator fallback as last resort (after 3 agent attempts)

---

**Plan Status**: Ready for implementation
**Estimated Total Time**: 3-5 hours
**Risk Level**: Medium (removes safety net, but improves clarity)
**Success Probability**: High (clear objectives, testable outcomes)

## Revision History

### 2025-10-23 - Revision 3
**Changes**: Enhanced plan with Standard 0 compliance requirements and audit validation
**Reason**: Integrate Plan 002 improvement suggestions to align with `.claude/docs/` standards
**Reports Used**: `002_orchestrate_improvement_suggestions.md`
**Modified Phases**:
- **Added Phase 0**: Orchestrator role clarification and enforcement standards
  - Phase 0 orchestrator role clarification (YOUR ROLE, CRITICAL INSTRUCTIONS, ONLY directives)
  - Standard 0 enforcement markers (≥12 EXECUTE NOW, ≥8 MANDATORY VERIFICATION, ≥6 CHECKPOINT)
  - Imperative language transformation (≥90% ratio target)
  - Aggressive context pruning policy (<20% usage target)
- **Enhanced Testing Strategy**: Added standards compliance validation section
  - Execution enforcement audit (≥95/100 score)
  - Imperative language audit (≥90% ratio)
  - Pattern minimum counts validation
  - Weak language detection
  - File creation reliability test (10/10 trials)
- **Updated Success Criteria**: Added standards compliance subsection
  - Phase 0 orchestrator role requirements
  - Standard 0 enforcement marker requirements
  - Imperative language requirements
  - Context pruning policy requirements
  - Audit validation requirements

**Key Design Changes**:
- **Standard 0 Compliance**: Explicit enforcement markers throughout orchestrate.md
- **Phase 0 Requirement**: All orchestrator commands MUST include Phase 0 role clarification
- **Imperative Language**: Systematic transformation of passive language (should/can/may → MUST/WILL/SHALL)
- **Context Management**: Aggressive pruning for <20% context usage in workflows
- **Audit-Driven Validation**: Use `.claude/lib/audit-execution-enforcement.sh` and `.claude/lib/audit-imperative-language.sh` for compliance verification

**Documentation References**:
- Command Architecture Standards (Standard 0, Phase 0 Requirement)
- Imperative Language Guide (Pattern 10, transformation table)
- Execution Enforcement Guide (Phase 0 pattern, Direct Execution Blocks)
- Behavioral Injection Pattern (agent coordination)
- Context Management Pattern (pruning for orchestration workflows)
- Verification-Fallback Pattern (100% file creation guarantee)

**Note**: This revision does NOT add fallback mechanisms (user prefers predictable behavior). The auto-retry implementation from Revision 2 is maintained and enhanced with stronger enforcement.

### 2025-10-22 - Revision 2
**Changes**: Added auto-recovery strategy using retry-with-escalation instead of fail-fast
**Reason**: User accepts high failure rates but wants workflow to continue with partial results, not terminate
**Modified Phases**:
- Phase 1: Changed to "Create Agent Template Variations" (3 templates per agent type)
- Phase 2: Changed to "Implement Auto-Retry Logic for Research" (3 attempts with escalation)
- Phase 3: Changed to "Implement Auto-Retry Logic for Planning" (3 attempts with escalation)
- Phase 4: Added "Add Workflow Summary Report" (show successful/failed topics)
- Phase 5: Changed to "Remove Fallbacks and Commands" (combined audit phase)
**Key Design Changes**:
- **Auto-Recovery**: Retry up to 3 times with escalating template enforcement
- **Template Variations**: Standard → Ultra-Explicit → Step-by-Step (increasing verbosity)
- **Degraded Continuation**: Research phase continues with partial results
- **Critical Failure**: Planning phase fails only after all retries (need at least 1 report)
- **Workflow Summary**: Clear report of successful/failed topics and all artifacts
- **No Orchestrator Fallbacks**: Still strictly subagent-only (retries invoke new subagents)

### 2025-10-22 - Revision 1
**Changes**: Complete redesign from enhancement approach to strict subagent-only enforcement
**Reason**: User requirement to remove ALL fallbacks and command invocations, enforce pure subagent orchestration
**Modified Phases**:
- Phase 1: Changed from "enhance verification" to "remove fallback mechanisms"
- Phase 2: Changed from "enhance template" to "strict enforcement template with fail-fast"
- Phase 3: Changed from "fix documentation" to "enforce Task-only invocation, prohibit SlashCommand"
- Phase 4: Added new phase to audit and remove ALL command invocations
**Key Design Changes**:
- Removed all fallback file creation logic
- Replaced with fail-fast error handling (exit 1 on missing files)
- Added strict enforcement to agent templates (EXECUTE NOW, PROHIBITED ACTIONS)
- Prohibited ALL SlashCommand usage in orchestrate.md
- Emphasized pure coordinator role for /orchestrate (agents do ALL work)
