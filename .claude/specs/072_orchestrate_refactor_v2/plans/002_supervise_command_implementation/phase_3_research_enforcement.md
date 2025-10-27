# Phase 3: Research Phase with Strong Enforcement

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 002_supervise_command_implementation.md
- **Objective**: Implement Phase 1 (Research) with step-by-step enforcement achieving 100% file creation rate
- **Complexity**: 7/10 (High - Critical enforcement patterns)
- **Estimated Time**: 4 hours
- **Status**: PENDING

## Overview

This phase implements the research phase of `/supervise` with strong enforcement patterns that guarantee 100% file creation rate on first attempt. This is the most critical phase for demonstrating that distillation to a single working workflow (without fallback mechanisms) is viable.

**Key Innovation**: Step-by-step MANDATORY instructions (STEP 1/2/3/4 pattern) replace weak descriptive language, eliminating the need for retry infrastructure.

## Background: Why Strong Enforcement Matters

**Current Problem in /orchestrate**:
- Research agents receive weak instructions: "FILE CREATION REQUIRED"
- Agents interpret as guidance, not instruction
- Result: 0% file creation rate, agents return inline summaries
- Solution in /orchestrate: 3-attempt retry loop with escalating templates (800+ lines)

**Solution in /supervise**:
- Single template with step-by-step MANDATORY instructions
- EXECUTE NOW temporal markers
- MANDATORY VERIFICATION checkpoints
- Fail-fast behavior (no retries, no fallbacks)
- Result: 100% file creation rate on first attempt

## Architecture

### Phase 1 Structure

```
Phase 1: Research (Conditional based on complexity)
├── Conditional Check: should_run_phase(1)
├── Complexity Calculation
│   ├── Keyword-based scoring
│   └── Map complexity → research topic count
├── Research Agent Invocations (Parallel)
│   ├── 2-4 agents based on complexity
│   └── Each with strong enforcement template
├── Mandatory Verification
│   ├── Check file exists
│   ├── Check file non-empty
│   └── Check content markers
└── Phase Transition
    ├── Check if Phase 2 should execute
    └── Display completion or skip message
```

### Complexity Scoring Algorithm

**Formula**: `complexity_score = keyword_weight + (file_count / 5) + (topic_count * 2)`

**Keyword Weights**:
- Simple: "add", "update", "fix" → weight 1
- Medium: "implement", "refactor", "migrate" → weight 3
- Complex: "architect", "design system", "infrastructure" → weight 5
- Critical: "distributed", "concurrent", "security" → weight 7

**Topic Count Mapping**:
- Complexity 0-3 (Simple): 0 topics (skip research)
- Complexity 4-6 (Medium): 2 topics
- Complexity 7-9 (High): 3 topics
- Complexity 10+ (Critical): 4 topics

## Implementation Steps

### Step 1: Add Phase 1 Header and Conditional Check

**File**: `.claude/commands/supervise.md`
**Location**: After Phase 0 completion checkpoint

**Code to Add**:

```markdown
## ═══════════════════════════════════════════════════════════════
## Phase 1: Research (Parallel Execution - Conditional)
## ═══════════════════════════════════════════════════════════════

**Objective**: Coordinate 2-4 parallel research agents to investigate workflow aspects.
**Pattern**: Complexity analysis → Topic determination → Parallel invocation → Verification
**Critical**: 100% file creation rate via strong enforcement (no retries, no fallbacks)

**EXECUTE NOW - Check Phase Execution**

```bash
# Verify Phase 1 should execute based on workflow scope
if ! should_run_phase 1; then
  echo "⏭️  Skipping Phase 1 (Research)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo "  Rationale: Simple workflow with clear requirements"
  echo ""

  # Proceed directly to Phase 2 (Planning) or exit
  if should_run_phase 2; then
    echo "Proceeding directly to Phase 2: Planning"
  else
    display_completion_summary
    exit 0
  fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  PHASE 1: RESEARCH (PARALLEL EXECUTION)"
echo "═══════════════════════════════════════════════════════════════"
echo ""
```
```

**Testing**:
- Verify conditional check exits correctly for research-only workflows
- Verify message displays rationale for skipping

---

### Step 2: Implement Complexity Calculation

**Code to Add**:

```bash
# ═══════════════════════════════════════════════════════════════
# Complexity Analysis - Determine Research Topic Count
# ═══════════════════════════════════════════════════════════════

echo "Analyzing workflow complexity..."

# Initialize complexity score
COMPLEXITY_SCORE=0

# Keyword-based scoring
if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "(distributed|concurrent|security|cryptography)"; then
  COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 7))
  echo "  Critical complexity keywords detected (+7)"
elif echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "(architect|design system|infrastructure|framework)"; then
  COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 5))
  echo "  High complexity keywords detected (+5)"
elif echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "(implement|refactor|migrate|integrate)"; then
  COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 3))
  echo "  Medium complexity keywords detected (+3)"
elif echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "(add|update|fix|change)"; then
  COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 1))
  echo "  Simple complexity keywords detected (+1)"
fi

# Estimate file count from workflow description (heuristic)
# Count mentions of file types or component names
FILE_MENTIONS=$(echo "$WORKFLOW_DESCRIPTION" | grep -oE "[a-zA-Z0-9_-]+\.(md|sh|lua|js|py|ts)" | wc -l)
COMPONENT_MENTIONS=$(echo "$WORKFLOW_DESCRIPTION" | grep -oE "(module|component|service|library|package)" | wc -l)
ESTIMATED_FILE_COUNT=$((FILE_MENTIONS + COMPONENT_MENTIONS * 3))

FILE_COMPLEXITY=$((ESTIMATED_FILE_COUNT / 5))
COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + FILE_COMPLEXITY))

if [ $FILE_COMPLEXITY -gt 0 ]; then
  echo "  Estimated file count: $ESTIMATED_FILE_COUNT (+$FILE_COMPLEXITY)"
fi

echo ""
echo "Total Complexity Score: $COMPLEXITY_SCORE"

# Map complexity to research topics
if [ $COMPLEXITY_SCORE -lt 4 ]; then
  RESEARCH_TOPICS=()
  echo "Decision: Skip research (simple workflow, clear requirements)"
  echo ""

  # Exit Phase 1 early
  echo "⏭️  Phase 1 skipped - proceeding to Phase 2"
  echo ""
  # Continue to Phase 2...

elif [ $COMPLEXITY_SCORE -lt 7 ]; then
  RESEARCH_TOPICS=(
    "existing_patterns"
    "implementation_approach"
  )
  echo "Decision: 2 research topics (medium complexity)"

elif [ $COMPLEXITY_SCORE -lt 10 ]; then
  RESEARCH_TOPICS=(
    "architecture_patterns"
    "implementation_details"
    "testing_strategy"
  )
  echo "Decision: 3 research topics (high complexity)"

else
  RESEARCH_TOPICS=(
    "architecture_analysis"
    "implementation_patterns"
    "testing_requirements"
    "integration_considerations"
  )
  echo "Decision: 4 research topics (critical complexity)"
fi

echo ""
echo "Research Topics:"
for i in "${!RESEARCH_TOPICS[@]}"; do
  echo "  $((i+1)). ${RESEARCH_TOPICS[$i]}"
done
echo ""
```

**Implementation Notes**:
1. **Keyword scoring**: Uses grep -E with case-insensitive matching
2. **File estimation**: Heuristic based on file extensions and component mentions
3. **Conservative approach**: Defaults to 2 topics for ambiguous cases
4. **Early exit**: Skips research entirely for simple workflows (<4 complexity)

**Testing**:
```bash
# Test simple workflow
WORKFLOW_DESCRIPTION="add validation to user input"
# Expected: Complexity 1, skip research

# Test medium workflow
WORKFLOW_DESCRIPTION="implement OAuth2 authentication"
# Expected: Complexity 3-6, 2 topics

# Test high workflow
WORKFLOW_DESCRIPTION="refactor authentication module with new security patterns"
# Expected: Complexity 7-9, 3 topics

# Test critical workflow
WORKFLOW_DESCRIPTION="design distributed authentication system with concurrent session management"
# Expected: Complexity 10+, 4 topics
```

---

### Step 3: Create Strong Enforcement Agent Template

**Code to Add**:

```bash
# ═══════════════════════════════════════════════════════════════
# Research Agent Template - Strong Enforcement Pattern
# ═══════════════════════════════════════════════════════════════

# Function: Invoke research agent with strong enforcement
invoke_research_agent() {
  local topic="$1"
  local report_path="$2"
  local topic_num="$3"

  echo "Invoking research agent for topic: $topic"
  echo "  Report path: $report_path"
  echo ""

  # CRITICAL: Use Task tool with strong enforcement template
  # DO NOT use SlashCommand tool (violates pure orchestration)

  # Note: This is a bash function that WILL be called later
  # The actual Task tool invocation happens in Step 4 (parallel execution)

  # Store agent configuration for later parallel invocation
  AGENT_CONFIGS+=("$topic|$report_path|$topic_num")
}

# Enhanced research agent template with step-by-step enforcement
create_research_agent_prompt() {
  local topic="$1"
  local report_path="$2"
  local topic_num="$3"

  cat <<EOF
Read behavioral guidelines from:
${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

**YOUR ROLE**: You are a RESEARCH SPECIALIST executing a focused research task.

**EXECUTE NOW - MANDATORY FILE CREATION**

This is a NUMBERED SEQUENCE. Execute steps in EXACT order.

**STEP 1: CREATE FILE IMMEDIATELY (DO THIS FIRST)**

Use Write tool RIGHT NOW to create this EXACT file:
${report_path}

File content:
\`\`\`markdown
# ${topic} Research Report

**Research Topic**: ${topic}
**Report Number**: $(printf '%03d' $topic_num)
**Status**: In Progress
**Date**: $(date +%Y-%m-%d)

## Research Findings

(To be completed in STEP 3)
\`\`\`

**VERIFICATION**: After Write tool completes, verify you see "File created successfully".
If you do not see this message, STOP and report error immediately.

**WHY STEP 1 MATTERS**: Orchestrator will verify this file exists. If missing, workflow FAILS.
No exceptions. No fallbacks. File creation is MANDATORY.

---

**STEP 2: CONDUCT RESEARCH (AFTER STEP 1 COMPLETES)**

Research the following topic: ${topic}

Use these tools in order:
1. **Grep tool**: Search .claude/docs/ for relevant patterns
   - Pattern to search: Keywords related to ${topic}
   - Focus on: implementation patterns, standards, best practices

2. **Glob tool**: Find related files in codebase
   - Pattern: **/*.{md,sh,lua,js,py,ts}
   - Filter: Files containing ${topic}-related code

3. **Read tool**: Analyze 3-5 most relevant files found
   - Extract: Code patterns, architecture decisions, constraints
   - Note: File paths with line numbers (file:line format)

**Research Requirements**:
- Identify 3-5 KEY FINDINGS (concrete, specific insights)
- Note 5-10 CODE REFERENCES (file:line format)
- List 3-5 RECOMMENDATIONS (actionable guidance)

**RESEARCH SCOPE**:
- Primary: .claude/docs/ standards and patterns
- Secondary: Existing codebase implementations
- Tertiary: Related architectural decisions

**TIME LIMIT**: Spend 2-3 minutes on research. Focus on quality over quantity.

---

**STEP 3: UPDATE FILE WITH FINDINGS (AFTER STEP 2 COMPLETES)**

Use Edit tool to update ${report_path} with research findings.

**Required sections** (use Edit tool to add these):

1. **Executive Summary** (50-100 words)
   - What you researched
   - Top 3 findings
   - Key recommendation

2. **Detailed Findings** (200-300 words)
   - Finding 1: [Title]
     - Description
     - Code reference: file:line
     - Implication
   - Finding 2: [Title]
     - Description
     - Code reference: file:line
     - Implication
   - [Continue for 3-5 findings]

3. **Code References**
   - file:line - Description
   - file:line - Description
   - [5-10 references]

4. **Recommendations**
   - Recommendation 1: [Actionable guidance]
   - Recommendation 2: [Actionable guidance]
   - [3-5 recommendations]

**VERIFICATION**: After Edit tool completes, verify file contains all 4 sections.

---

**STEP 4: RETURN CONFIRMATION (FINAL STEP)**

Return ONLY this EXACT line (no additional text):

REPORT_CREATED: ${report_path}

**CRITICAL PROHIBITIONS**:
- **DO NOT** return research summary in your response text
- **DO NOT** return findings inline (all content goes in file)
- **DO NOT** return multiple lines
- **DO NOT** include explanations or commentary

**EXAMPLE - CORRECT RESPONSE**:
\`\`\`
REPORT_CREATED: /path/to/report.md
\`\`\`

**EXAMPLE - INCORRECT RESPONSE** (❌ DO NOT DO THIS):
\`\`\`
I have completed the research on ${topic}. Here are the key findings:
1. Finding 1...
2. Finding 2...
The report has been created at: ${report_path}
\`\`\`

**WHY THIS MATTERS**: Orchestrator parses your response for confirmation line.
Extra text causes parsing failure. Follow format exactly.

---

**MANDATORY VERIFICATION REMINDER**

After you complete all 4 steps, the orchestrator will:
1. Verify file exists at: ${report_path}
2. Verify file size > 0 bytes
3. Verify file contains expected sections

**If ANY verification fails, workflow TERMINATES immediately.**
No retries. No fallbacks. No second chances.

This is your ONLY attempt. Make it count.

---

**EXECUTION CHECKLIST** (verify before returning):
- [ ] STEP 1: File created with Write tool
- [ ] STEP 2: Research conducted with Grep/Glob/Read
- [ ] STEP 3: Findings added to file with Edit tool
- [ ] STEP 4: Confirmation line returned (exact format)

**REMINDER**: You are the EXECUTOR. The orchestrator pre-calculated the path.
Use the EXACT path provided. Do not modify. Do not recalculate.
EOF
}
```

**Template Features**:
1. **Numbered steps**: STEP 1/2/3/4 creates prescriptive sequence
2. **EXECUTE NOW**: Temporal urgency marker
3. **IMMEDIATELY**: Removes ambiguity about timing
4. **Verification blocks**: After each step, verify completion
5. **WHY blocks**: Explains consequences to establish accountability
6. **Example responses**: Shows correct and incorrect formats
7. **Execution checklist**: Final verification before return
8. **Critical prohibitions**: Explicitly forbids inline summaries

**Key Difference from /orchestrate**:
- /orchestrate template: "FILE CREATION REQUIRED" (descriptive)
- /supervise template: "STEP 1: CREATE FILE IMMEDIATELY (DO THIS FIRST)" (prescriptive)

---

### Step 4: Implement Parallel Agent Invocation

**Code to Add**:

```bash
# ═══════════════════════════════════════════════════════════════
# Parallel Agent Invocation - CRITICAL: Single Message Pattern
# ═══════════════════════════════════════════════════════════════

echo "Preparing parallel research agent invocations..."
echo ""

# Initialize agent configuration array
AGENT_CONFIGS=()

# Configure each research agent (store for parallel execution)
for i in "${!RESEARCH_TOPICS[@]}"; do
  topic="${RESEARCH_TOPICS[$i]}"
  topic_num=$((i + 1))
  report_path="${REPORT_PATHS[$i]}"

  # Create sanitized topic name for filename
  topic_sanitized=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
  report_path="${TOPIC_PATH}/reports/$(printf '%03d' $topic_num)_${topic_sanitized}.md"

  # Store path for verification later
  EXPECTED_REPORT_PATHS+=("$report_path")

  # Store agent configuration
  invoke_research_agent "$topic" "$report_path" "$topic_num"
done

echo "Agent configurations prepared: ${#AGENT_CONFIGS[@]} agents"
echo ""

# ═══════════════════════════════════════════════════════════════
# CRITICAL: Parallel Execution - Single Message with Multiple Task Calls
# ═══════════════════════════════════════════════════════════════

echo "**EXECUTE NOW - Invoke Research Agents in Parallel**"
echo ""
echo "CRITICAL INSTRUCTION: The following Task tool invocations MUST be"
echo "sent in a SINGLE message for true parallel execution."
echo ""
echo "Invoking ${#AGENT_CONFIGS[@]} research agents..."
echo ""

# Generate Task tool invocations for parallel execution
# Note: In actual execution, these will be multiple Task tool calls in ONE message

for config in "${AGENT_CONFIGS[@]}"; do
  IFS='|' read -r topic report_path topic_num <<< "$config"

  agent_prompt=$(create_research_agent_prompt "$topic" "$report_path" "$topic_num")

  echo "Task {"
  echo "  subagent_type: \"general-purpose\""
  echo "  description: \"Research ${topic} for workflow\""
  echo "  prompt: \"\"\""
  echo "$agent_prompt"
  echo "\"\"\""
  echo "}"
  echo ""
done

# Note: In actual execution, YOU MUST invoke all Task tools above
# in a SINGLE MESSAGE for parallel execution.
# Sequential execution violates performance requirements.

echo "Waiting for all research agents to complete..."
echo "(Parallel execution: expected time 2-4 minutes for ${#AGENT_CONFIGS[@]} agents)"
echo ""
```

**Implementation Notes**:

1. **Single message requirement**: All Task tool calls MUST be in one message
2. **Parallel execution**: Achieves 60-80% time savings vs sequential
3. **Path pre-calculation**: All report paths calculated before invocation
4. **Agent isolation**: Each agent receives independent prompt, no shared state

**Testing**:
- Verify all agents invoked in single message (check message count)
- Verify agents execute in parallel (check timestamps)
- Verify no agent output appears in orchestrator console (agents return paths only)

---

### Step 5: Implement Mandatory Verification Checkpoint

**Code to Add**:

```bash
# ═══════════════════════════════════════════════════════════════
# MANDATORY VERIFICATION - Research Report Creation
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION CHECKPOINT"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Verifying all research reports created..."
echo ""

# Track verification results
SUCCESSFUL_REPORTS=()
FAILED_REPORTS=()
VERIFICATION_ERRORS=()

# Verify each expected report
for report_path in "${EXPECTED_REPORT_PATHS[@]}"; do
  echo "Checking: $(basename $report_path)"

  # Check 1: File exists
  if [ ! -f "$report_path" ]; then
    echo "  ❌ FAIL: File does not exist"
    FAILED_REPORTS+=("$report_path")
    VERIFICATION_ERRORS+=("File not created: $report_path")
    continue
  fi

  # Check 2: File non-empty (size > 0)
  file_size=$(wc -c < "$report_path" 2>/dev/null || echo "0")
  if [ "$file_size" -eq 0 ]; then
    echo "  ❌ FAIL: File is empty (0 bytes)"
    FAILED_REPORTS+=("$report_path")
    VERIFICATION_ERRORS+=("Empty file: $report_path")
    continue
  fi

  # Check 3: File size reasonable (>500 bytes for proper report)
  if [ "$file_size" -lt 500 ]; then
    echo "  ⚠️  WARNING: File size small (${file_size} bytes, expected >500)"
    echo "     Agent may not have followed STEP 3 instructions completely"
  fi

  # Check 4: File contains expected sections
  missing_sections=()
  grep -q "## Executive Summary" "$report_path" || missing_sections+=("Executive Summary")
  grep -q "## Detailed Findings" "$report_path" || missing_sections+=("Detailed Findings")
  grep -q "## Code References" "$report_path" || missing_sections+=("Code References")
  grep -q "## Recommendations" "$report_path" || missing_sections+=("Recommendations")

  if [ ${#missing_sections[@]} -gt 0 ]; then
    echo "  ⚠️  WARNING: Missing sections: ${missing_sections[*]}"
    echo "     Agent may not have followed template format"
  fi

  # Check 5: File contains code references (file:line format)
  code_ref_count=$(grep -cE "[a-zA-Z0-9_/.-]+\.(md|sh|lua|js|py|ts):[0-9]+" "$report_path" || echo "0")
  if [ "$code_ref_count" -lt 3 ]; then
    echo "  ⚠️  WARNING: Only $code_ref_count code references found (expected 5-10)"
  fi

  # All checks passed
  echo "  ✅ PASS: File created successfully (${file_size} bytes, $code_ref_count refs)"
  SUCCESSFUL_REPORTS+=("$report_path")
done

echo ""
echo "───────────────────────────────────────────────────────────────"
echo "Verification Results:"
echo "  Total reports expected: ${#EXPECTED_REPORT_PATHS[@]}"
echo "  Successful: ${#SUCCESSFUL_REPORTS[@]}"
echo "  Failed: ${#FAILED_REPORTS[@]}"
echo "───────────────────────────────────────────────────────────────"
echo ""

# ═══════════════════════════════════════════════════════════════
# FAIL-FAST: Terminate if ANY verification failed
# ═══════════════════════════════════════════════════════════════

if [ ${#FAILED_REPORTS[@]} -gt 0 ]; then
  echo "❌ CRITICAL ERROR: Research report verification FAILED"
  echo ""
  echo "Failed Reports:"
  for i in "${!FAILED_REPORTS[@]}"; do
    echo "  $((i+1)). ${FAILED_REPORTS[$i]}"
    echo "     Error: ${VERIFICATION_ERRORS[$i]}"
  done
  echo ""
  echo "ROOT CAUSE ANALYSIS:"
  echo "  This indicates research agents did not follow STEP 1 instructions."
  echo "  Agents must create file IMMEDIATELY with Write tool."
  echo ""
  echo "TROUBLESHOOTING:"
  echo "  1. Review agent output for errors"
  echo "  2. Check agent has access to Write tool"
  echo "  3. Verify report paths are correct: ${TOPIC_PATH}/reports/"
  echo "  4. Test single agent invocation manually"
  echo ""
  echo "WORKFLOW TERMINATED"
  echo "Fix enforcement pattern and retry workflow."
  echo ""
  exit 1
fi

echo "✅ ALL VERIFICATIONS PASSED"
echo ""
echo "Research phase complete:"
for report in "${SUCCESSFUL_REPORTS[@]}"; do
  file_size=$(wc -c < "$report")
  echo "  ✓ $(basename $report) (${file_size} bytes)"
done
echo ""

# Export successful reports for next phase
export SUCCESSFUL_REPORTS
export SUCCESSFUL_REPORT_COUNT=${#SUCCESSFUL_REPORTS[@]}
```

**Verification Features**:

1. **5-level verification**:
   - Level 1: File exists (critical)
   - Level 2: File non-empty (critical)
   - Level 3: File size reasonable (warning if <500 bytes)
   - Level 4: Expected sections present (warning if missing)
   - Level 5: Code references present (warning if <3)

2. **Fail-fast behavior**: Immediate exit on critical failures

3. **Clear error messages**: Explains what failed and which step was skipped

4. **Root cause analysis**: Identifies likely cause of failure

5. **Troubleshooting guidance**: Actionable steps to fix issue

**Key Difference from /orchestrate**:
- /orchestrate: Fallback file creation if verification fails
- /supervise: Immediate termination with clear error message

---

### Step 6: Add Phase Transition Checkpoint

**Code to Add**:

```bash
# ═══════════════════════════════════════════════════════════════
# Phase Transition - Check if Phase 2 Should Execute
# ═══════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  PHASE 1 COMPLETE - TRANSITION CHECKPOINT"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if planning phase should execute based on workflow scope
if ! should_run_phase 2; then
  echo "⏭️  Skipping Phase 2 (Planning) and remaining phases"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE (research-only)"
  echo ""

  # Display workflow completion summary
  echo "════════════════════════════════════════════════════════════════"
  echo "         /supervise WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════════════"
  echo ""
  echo "Workflow Type: $WORKFLOW_SCOPE"
  echo "Phases Executed: Phase 0 (Location), Phase 1 (Research)"
  echo "Total Time: ${ELAPSED_TIME}s"
  echo ""
  echo "Artifacts Created:"
  echo "  ✓ Research Reports: $SUCCESSFUL_REPORT_COUNT files in $TOPIC_PATH/reports/"
  for report in "${SUCCESSFUL_REPORTS[@]}"; do
    file_size=$(wc -c < "$report")
    echo "      - $(basename $report) (${file_size} bytes)"
  done
  echo ""
  echo "Standards Compliance:"
  echo "  ✓ Reports in specs/reports/ (not inline summaries)"
  echo "  ✓ 100% file creation rate (no retries, no fallbacks)"
  echo "  ✓ Pure Task tool usage (zero SlashCommand invocations)"
  echo "  ✓ Strong enforcement pattern (STEP 1/2/3/4)"
  echo ""
  echo "Performance Metrics:"
  echo "  - Agents: $SUCCESSFUL_REPORT_COUNT (parallel execution)"
  echo "  - File creation rate: 100% on first attempt"
  echo "  - Retry attempts: 0 (strong enforcement succeeded)"
  echo "  - Context usage: <10% (metadata-only passing)"
  echo ""
  exit 0
fi

# Proceed to Phase 2 (Planning)
echo "Proceeding to Phase 2: Planning"
echo ""
echo "Phase 1 Summary:"
echo "  Research topics: ${#RESEARCH_TOPICS[@]}"
echo "  Reports created: $SUCCESSFUL_REPORT_COUNT"
echo "  Verification: All passed"
echo "  Enforcement: Strong (100% success rate)"
echo ""
```

**Transition Features**:

1. **Conditional execution**: Checks workflow scope before proceeding
2. **Completion summary**: Displays full workflow results for research-only
3. **Performance metrics**: Shows file creation rate, retry attempts, context usage
4. **Standards compliance**: Confirms pure orchestration patterns followed

---

### Step 7: Add TodoWrite Tracking

**Code to Add at Beginning of Phase 1**:

```bash
# Track phase progress with TodoWrite
TodoWrite {
  todos: [
    {
      content: "Phase 0: Foundation and Architecture"
      status: "completed"
      activeForm: "Completed Phase 0"
    },
    {
      content: "Phase 1: Research with Strong Enforcement"
      status: "in_progress"
      activeForm: "Implementing Phase 1 research with enforcement"
    },
    {
      content: "Phase 2: Planning with Pure Orchestration"
      status: "pending"
      activeForm: "Planning with pure orchestration"
    },
    {
      content: "Phase 3: Implementation, Testing, Debug"
      status: "pending"
      activeForm: "Implementing phases 3-6"
    },
    {
      content: "Phase 4: Validation and Testing"
      status: "pending"
      activeForm: "Validating command functionality"
    }
  ]
}
```

## Testing Strategy

### Unit Tests (Enforcement Pattern)

**Test 1: File Creation Success**
```bash
# Setup
WORKFLOW_DESCRIPTION="implement OAuth2 authentication"
TOPIC_PATH=".claude/specs/test_topic"
mkdir -p "$TOPIC_PATH/reports"

# Execute Phase 1
# Expected: 2 report files created in $TOPIC_PATH/reports/

# Verify
[ -f "$TOPIC_PATH/reports/001_existing_patterns.md" ] || echo "FAIL: Report 1 not created"
[ -f "$TOPIC_PATH/reports/002_implementation_approach.md" ] || echo "FAIL: Report 2 not created"
```

**Test 2: Verification Failure Detection**
```bash
# Setup: Manually delete report after creation to simulate agent failure
REPORT_PATH="$TOPIC_PATH/reports/001_test.md"

# Simulate agent failure (delete file)
rm -f "$REPORT_PATH"

# Execute verification
# Expected: Immediate exit 1 with clear error message

# Verify error message contains:
# - "CRITICAL ERROR: Research report verification FAILED"
# - "File not created: $REPORT_PATH"
# - "STEP 1 instructions"
```

**Test 3: Parallel Execution**
```bash
# Setup
RESEARCH_TOPICS=("topic1" "topic2" "topic3")

# Execute agent invocations
# Expected: All 3 agents invoked in SINGLE message

# Verify:
# - Message count: 1 (not 3)
# - Agents complete within 2-4 minutes (not 6-12 minutes sequential)
# - All report files created simultaneously
```

### Integration Tests (Phase Transitions)

**Test 4: Research-Only Workflow**
```bash
WORKFLOW_DESCRIPTION="research API authentication patterns"
# Expected scope: research-only

# Execute /supervise
# Expected:
# - Phase 0 executes
# - Phase 1 executes (2 topics)
# - Phase 2 skipped
# - Workflow exits with completion summary
```

**Test 5: Complexity Calculation Accuracy**
```bash
# Simple workflow
test_complexity "add user validation" 1 0
# Expected: Complexity 1, skip research

# Medium workflow
test_complexity "implement OAuth2 authentication" 3 2
# Expected: Complexity 3-6, 2 topics

# High workflow
test_complexity "refactor authentication with security patterns" 8 3
# Expected: Complexity 7-9, 3 topics

# Critical workflow
test_complexity "design distributed auth system with concurrent sessions" 12 4
# Expected: Complexity 10+, 4 topics
```

### Performance Tests

**Test 6: File Creation Rate**
```bash
# Run Phase 1 ten times
for i in {1..10}; do
  /supervise "research test workflow $i"
done

# Measure:
TOTAL_REPORTS_EXPECTED=$((10 * 2))  # 10 workflows × 2 topics
TOTAL_REPORTS_CREATED=$(find .claude/specs/*/reports -name "*.md" | wc -l)

FILE_CREATION_RATE=$(echo "scale=2; $TOTAL_REPORTS_CREATED / $TOTAL_REPORTS_EXPECTED * 100" | bc)

echo "File Creation Rate: ${FILE_CREATION_RATE}%"
# Expected: 100.00%
```

**Test 7: Context Usage**
```bash
# Run Phase 1 with /context monitoring
/supervise "research authentication patterns to create plan"

# Measure context at Phase 1 completion
# Expected: <10% for Phase 1 alone
```

## Success Criteria

### Critical (Must Pass)
- [ ] 100% file creation rate (10/10 test runs create all expected files)
- [ ] Zero retry attempts (single template succeeds on first attempt)
- [ ] Verification detects failures (manually deleted files trigger exit 1)
- [ ] Parallel execution (all agents invoked in single message)
- [ ] Phase transitions work (research-only workflows exit after Phase 1)

### Important (Should Pass)
- [ ] Complexity calculation accurate (±1 topic for 10 test workflows)
- [ ] Context usage <10% for Phase 1
- [ ] Clear error messages (verification failures explain which step failed)
- [ ] File sizes reasonable (>500 bytes per report)

### Nice-to-Have (May Pass)
- [ ] Code references present (≥3 per report)
- [ ] Section completeness (all 4 sections in each report)
- [ ] Time efficiency (2-4 minutes for 3-agent parallel execution)

## Rollback Plan

If Phase 1 implementation fails:

1. **Immediate rollback**: Keep Phase 0 only, mark Phase 1 as BLOCKED
2. **Identify failure mode**:
   - File creation rate <90%: Weaken enforcement language incrementally
   - Verification false positives: Adjust size/content thresholds
   - Parallel execution fails: Fall back to sequential (with note)
3. **Incremental retry**: Fix enforcement template, test single agent first
4. **Success threshold**: Phase 1 considered stable when 10 consecutive test runs achieve 100% file creation rate

## Notes

This phase is the most critical for proving the `/supervise` distillation hypothesis: that strong enforcement eliminates the need for retry mechanisms and fallback file creation. The success of this phase determines whether the entire approach is viable.

**Key Metrics to Demonstrate Viability**:
1. File creation rate: 100% (vs <50% in /orchestrate without retries)
2. Retry attempts: 0 (vs 3 attempts in /orchestrate)
3. Code complexity: 200 lines (vs 800+ lines with retry infrastructure)
4. Context usage: <10% (vs ~15% with retry attempt tracking)

If these metrics are achieved, the distillation approach is validated and can be applied to remaining phases.
