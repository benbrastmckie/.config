# Phase 4 Expansion: Command Migration - Tier 1 Critical (/report)

## Expansion Metadata

- **Parent Plan**: 077_execution_enforcement_migration.md
- **Phase Number**: 4
- **Phase Title**: Command Migration - Tier 1 Critical (/report)
- **Complexity Score**: 8/10 (High)
- **Estimated Duration**: 8 hours (Week 3 - Day 1-2)
- **Expansion Date**: 2025-10-20
- **Expansion Reason**: Critical hierarchical multi-agent pattern execution requires detailed specification

---

## Phase Overview

### Objective

Migrate the `/report` command with Phase 0 role clarification to fix hierarchical pattern execution, achieving 100% file creation rate and restoring multi-agent research coordination.

### Critical Success Criteria

- [x] Phase 0 role clarification added with all 4 required elements
- [ ] Hierarchical multi-agent pattern executes correctly (Task tool invocations visible) - Integration testing pending
- [ ] 10/10 file creation tests pass (100% reliability) - Integration testing pending
- [x] Audit score ≥95/100 (achieved 95/100)
- [x] Existing /report functionality preserved (code patterns retained)
- [ ] Metadata-based context reduction verified (92-97% reduction maintained) - Integration testing pending
- [ ] Parallel agent execution verified (2-4 agents invoked simultaneously) - Integration testing pending

### Problem Statement

**Current Issue**: The `/report` command uses ambiguous opening language ("I'll research the specified topic") which Claude interprets as a directive to execute research directly using Read/Grep/Write tools instead of orchestrating research-specialist agents via the Task tool.

**Impact**:
- Hierarchical multi-agent pattern not executing (no Task invocations)
- Single monolithic report created instead of hierarchical structure (subtopics + overview)
- No parallelization (sequential execution, 40-60% slower)
- No metadata-based context reduction (95% context consumption vs 3-5% target)
- Variable file creation rates (60-80% instead of 100%)

**Root Cause**: Missing Phase 0 role clarification at command opening (lines 11-14 currently).

---

## Technical Context

### Hierarchical Multi-Agent Pattern

The `/report` command is designed to use a hierarchical multi-agent pattern:

```
User Request: /report "Complex Topic"
         ↓
  Topic Decomposition (2-4 subtopics)
         ↓
  ┌──────┴──────┬──────┬──────┐
  ↓             ↓      ↓      ↓
Agent 1      Agent 2  Agent 3  Agent 4  (parallel research-specialist agents)
  ↓             ↓      ↓      ↓
Report 1     Report 2  ...   Report N  (individual subtopic reports)
  └──────┬──────┴──────┴──────┘
         ↓
  research-synthesizer Agent
         ↓
   OVERVIEW.md (synthesis report)
         ↓
  spec-updater Agent (cross-references)
```

**Performance Characteristics**:
- **Parallelization**: 40-60% time savings vs sequential research
- **Context Reduction**: 92-97% reduction through metadata-only passing
- **Granularity**: Focused subtopic coverage with comprehensive synthesis
- **Scalability**: Handles 2-4 parallel agents without context exhaustion

### Current File Structure

**Command File**: `/home/benjamin/.config/.claude/commands/report.md`
**Total Lines**: ~514 lines
**Key Sections**:
- Lines 1-14: Opening and metadata
- Lines 15-64: Topic decomposition section
- Lines 65-132: Path pre-calculation section
- Lines 133-194: Agent invocation section
- Lines 195-244: Verification section
- Lines 245-380: Overview synthesis section
- Lines 381-514: Documentation and templates

### Existing Enforcement Patterns

**Already Present**:
- Pattern 1: Path pre-calculation (lines 87-132) - EXECUTE NOW block with absolute path calculation
- Pattern 2: Verification checkpoints (lines 118-142) - File existence verification with fallback
- Pattern 4: Checkpoint reporting (lines 134-141) - Progress checkpoint output

**Missing**:
- **Phase 0**: Role clarification (orchestrator vs executor)
- **Pattern 3**: Explicit fallback mechanisms for agent non-compliance
- **Agent Template Enforcement**: "THIS EXACT TEMPLATE" markers on Task invocations

---

## Detailed Implementation Tasks

### Task Group 4.1: Add Phase 0 Role Clarification (2 hours)

**Objective**: Replace ambiguous opening with explicit orchestrator role definition.

#### Task 4.1.1: Replace Opening Statement (Line 11)

**Current Content** (line 11):
```markdown
I'll research the specified topic and create a comprehensive report in the most appropriate location.
```

**New Content**:
```markdown
I'll orchestrate hierarchical research by delegating to specialized subagents who will investigate focused subtopics in parallel.
```

**Implementation**:
- Edit line 11 using Edit tool
- Preserve surrounding context (lines 9-14)
- Verify line replacement complete

**Verification**:
```bash
# Check opening statement changed
grep -n "orchestrate hierarchical research" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line 11 found with new text
```

---

#### Task 4.1.2: Add YOUR ROLE Section (After Line 11)

**Insert Location**: Between line 11 and current line 13 ("## Topic/Question")

**New Content**:
```markdown

**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.
```

**Implementation**:
- Use Edit tool to insert after line 11
- Add blank line before "## Topic/Question" for readability

**Line Reference**:
```
Line 11: I'll orchestrate hierarchical research...
Line 12: (blank line - NEW)
Line 13: **YOUR ROLE**: You are the ORCHESTRATOR, not the researcher. (NEW)
Line 14: (blank line - NEW)
Line 15: ## Topic/Question (previously line 13)
```

**Verification**:
```bash
head -20 /home/benjamin/.config/.claude/commands/report.md | grep -A 2 "YOUR ROLE"
# Expected: YOUR ROLE section visible
```

---

#### Task 4.1.3: Add CRITICAL INSTRUCTIONS Section (After YOUR ROLE)

**Insert Location**: Between YOUR ROLE section and "## Topic/Question"

**New Content**:
```markdown

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize

You will NOT see research findings directly. Agents will create report files at pre-calculated paths, and you will verify those files exist after agent completion.
```

**Implementation**:
- Insert 7 new lines after YOUR ROLE section
- Maintain proper markdown spacing

**Final Line Structure** (lines 11-22):
```
11: I'll orchestrate hierarchical research by delegating to specialized subagents...
12: (blank)
13: **YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.
14: (blank)
15: **CRITICAL INSTRUCTIONS**:
16: - DO NOT execute research yourself using Read/Grep/Write tools
17: - ONLY use Task tool to delegate research to research-specialist agents
18: - Your job: decompose topic → invoke agents → verify outputs → synthesize
19: (blank)
20: You will NOT see research findings directly. Agents will create report files
21: at pre-calculated paths, and you will verify those files exist after agent completion.
22: (blank)
23: ## Topic/Question (previously line 13)
```

**Verification**:
```bash
head -25 /home/benjamin/.config/.claude/commands/report.md | grep -B 3 -A 5 "CRITICAL INSTRUCTIONS"
# Expected: Full CRITICAL INSTRUCTIONS section visible with DO NOT and ONLY directives
```

**Why This Matters**:
- "DO NOT" directive prevents direct tool usage
- "ONLY" directive constrains to Task tool invocations
- Workflow description ("decompose → invoke → verify → synthesize") clarifies orchestration steps
- Explanation of indirect visibility ("You will NOT see research findings directly") sets correct expectations

---

### Task Group 4.2: Update Section Headers to STEP Format (1.5 hours)

**Objective**: Transform major sections to sequential step format with enforcement markers.

#### Task 4.2.1: Update Topic Decomposition Section (Line ~26 after Phase 0 insertion)

**Current Header** (approximately line 18, will shift to ~26 after Phase 0 additions):
```markdown
### 1.5. Topic Decomposition
```

**New Header**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition

**EXECUTE NOW - Decompose Research Topic Into Subtopics**
```

**Implementation**:
- Locate "### 1.5. Topic Decomposition" header
- Replace with new STEP format
- Add EXECUTE NOW marker as subheading

**Verification**:
```bash
grep -n "STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line number found
```

---

#### Task 4.2.2: Update Path Pre-Calculation Section (Line ~68 after insertions)

**Current Header** (approximately line 66, will shift):
```markdown
### 2. Topic-Based Location Determination and Path Pre-Calculation
```

**New Header**:
```markdown
### STEP 2 (REQUIRED BEFORE STEP 3) - Path Pre-Calculation

**EXECUTE NOW - Calculate Absolute Paths for All Subtopic Reports**
```

**Note**: This section already has EXECUTE NOW marker at line ~87. Update main header to match STEP format, preserve existing EXECUTE NOW subheader.

**Implementation**:
- Replace section header with STEP 2 format
- Verify existing "**EXECUTE NOW - Calculate Subtopic Report Paths**" subheader remains (currently line ~87)

**Verification**:
```bash
grep -n "STEP 2 (REQUIRED BEFORE STEP 3) - Path Pre-Calculation" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line number found
```

---

#### Task 4.2.3: Update Agent Invocation Section (Line ~143 after insertions)

**Current Header** (approximately line 143):
```markdown
### 3. Parallel Research-Specialist Invocation
```

**New Header**:
```markdown
### STEP 3 (REQUIRED BEFORE STEP 4) - Invoke Research Agents

**EXECUTE NOW - Invoke All Research-Specialist Agents in Parallel**
```

**Implementation**:
- Replace section header with STEP 3 format
- Add EXECUTE NOW subheading before existing content
- Preserve all existing agent invocation template content

**Verification**:
```bash
grep -n "STEP 3 (REQUIRED BEFORE STEP 4) - Invoke Research Agents" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line number found
```

---

#### Task 4.2.4: Update Verification Section (Line ~203 after insertions)

**Current Header** (approximately line 201):
```markdown
### 3.5. Report Verification and Error Recovery
```

**New Header**:
```markdown
### STEP 4 (REQUIRED BEFORE STEP 5) - Verify Report Creation

**MANDATORY VERIFICATION - All Subtopic Reports Must Exist**
```

**Implementation**:
- Replace section header with STEP 4 format
- Add MANDATORY VERIFICATION subheading
- Preserve existing verification bash code

**Verification**:
```bash
grep -n "STEP 4 (REQUIRED BEFORE STEP 5) - Verify Report Creation" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line number found
```

---

#### Task 4.2.5: Update Overview Synthesis Section (Line ~247 after insertions)

**Current Header** (approximately line 246):
```markdown
### 4. Overview Report Synthesis
```

**New Header**:
```markdown
### STEP 5 (REQUIRED BEFORE STEP 6) - Synthesize Overview Report

**EXECUTE NOW - Invoke Research-Synthesizer Agent**
```

**Implementation**:
- Replace section header with STEP 5 format
- Add EXECUTE NOW subheading before synthesis content

**Verification**:
```bash
grep -n "STEP 5 (REQUIRED BEFORE STEP 6) - Synthesize Overview Report" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line number found
```

---

#### Task 4.2.6: Update Spec-Updater Section (Line ~305 after insertions)

**Current Header** (approximately line 305):
```markdown
### 5. Spec-Updater Agent Invocation
```

**New Header**:
```markdown
### STEP 6 (ABSOLUTE REQUIREMENT) - Update Cross-References

**EXECUTE NOW - Invoke Spec-Updater for Cross-Reference Management**
```

**Implementation**:
- Replace section header with STEP 6 format
- Add EXECUTE NOW subheading
- Change from numeric "5." to "STEP 6" to maintain sequential enforcement

**Verification**:
```bash
grep -n "STEP 6 (ABSOLUTE REQUIREMENT) - Update Cross-References" /home/benjamin/.config/.claude/commands/report.md
# Expected: Line number found
```

---

### Task Group 4.3: Verify and Enhance Agent Invocations (2 hours)

**Objective**: Ensure all Task invocations have enforcement markers and behavioral injection.

#### Task 4.3.1: Audit Research-Specialist Invocations (Lines ~153-194)

**Current Content** (lines ~153-194 after insertions):
- Contains Task invocation template for research-specialist
- Has behavioral injection: "Read and follow: .claude/agents/research-specialist.md"
- Has ABSOLUTE REQUIREMENT marker
- Has step-by-step execution format

**Verification Checklist**:
- [ ] Line ~145: "**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**" marker present
- [ ] Line ~152: "**CRITICAL INSTRUCTION**" marker present
- [ ] Line ~159-162: Behavioral injection present
- [ ] Line ~169-172: STEP 1-4 format present with MANDATORY/EXECUTE NOW/REQUIRED markers
- [ ] Line ~184: "**EMIT PROGRESS MARKERS**" section present
- [ ] Line ~168: Explicit file path passing ("**Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]")

**Implementation**:
```bash
# Verify enforcement markers present
grep -n "AGENT INVOCATION - Use THIS EXACT TEMPLATE" /home/benjamin/.config/.claude/commands/report.md
grep -n "ABSOLUTE REQUIREMENT" /home/benjamin/.config/.claude/commands/report.md
grep -n "Read and follow the behavioral guidelines" /home/benjamin/.config/.claude/commands/report.md
```

**Enhancement Needed** (if not already present):
Add above line ~145 (before existing Task block):
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**
```

**Verification Command**:
```bash
sed -n '145,194p' /home/benjamin/.config/.claude/commands/report.md | grep -c "THIS EXACT TEMPLATE"
# Expected: 1 (marker present)
```

---

#### Task 4.3.2: Audit Research-Synthesizer Invocation (Lines ~265-297)

**Current Content** (lines ~265-297 after insertions):
- Contains Task invocation template for research-synthesizer
- Has behavioral injection
- Has ABSOLUTE REQUIREMENT marker
- Has STEP format

**Verification Checklist**:
- [ ] "**AGENT INVOCATION - Use THIS EXACT TEMPLATE**" marker present before Task block
- [ ] Behavioral injection: "Read and follow: .claude/agents/research-synthesizer.md"
- [ ] "**ABSOLUTE REQUIREMENT - Overview Creation is Your Primary Task**" present
- [ ] STEP 1-5 format with enforcement markers
- [ ] Explicit path passing for overview and subtopic reports
- [ ] "**EMIT PROGRESS MARKERS**" section present

**Enhancement Needed** (if missing):
Add before Task invocation (~line 262):
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**
```

**Verification Command**:
```bash
sed -n '262,297p' /home/benjamin/.config/.claude/commands/report.md | grep "THIS EXACT TEMPLATE"
# Expected: Marker found
```

---

#### Task 4.3.3: Audit Spec-Updater Invocation (Lines ~310-360)

**Current Content** (lines ~310-360 after insertions):
- Contains Task invocation for spec-updater
- Has behavioral injection
- Has task list format

**Verification Checklist**:
- [ ] "**AGENT INVOCATION - Use THIS EXACT TEMPLATE**" marker present
- [ ] Behavioral injection: "Read and follow: .claude/agents/spec-updater.md"
- [ ] Explicit context passing (overview path, subtopic paths, topic directory)
- [ ] Task checklist format (1-6) present
- [ ] Return format specified

**Enhancement Needed**:
1. Add "THIS EXACT TEMPLATE" marker before Task invocation
2. Add "**ABSOLUTE REQUIREMENT**" to agent prompt opening
3. Strengthen task language: "Tasks:" → "**REQUIRED TASKS (ALL MUST BE COMPLETED)**:"

**Implementation**:
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

Use the Task tool to invoke the spec-updater agent:

Task {
  subagent_type: "general-purpose"
  description: "Update cross-references for hierarchical research reports"
  prompt: "
    **ABSOLUTE REQUIREMENT - Cross-Reference Updates Are Mandatory**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Context:
    - Overview report created at: $OVERVIEW_PATH
    - Subtopic reports created at:
$(for path in "${SUBTOPIC_PATHS_ARRAY[@]}"; do echo "      - $path"; done)
    - Topic directory: $TOPIC_DIR
    - Related plan (if exists): [check topic's plans/ subdirectory]
    - Operation: hierarchical_report_creation

    **REQUIRED TASKS (ALL MUST BE COMPLETED)**:
    1. Check if a plan exists in the topic's plans/ subdirectory
    [... rest of tasks ...]
  "
}
```

**Verification Command**:
```bash
sed -n '310,360p' /home/benjamin/.config/.claude/commands/report.md | grep -c "ABSOLUTE REQUIREMENT"
# Expected: 1
```

---

### Task Group 4.4: Verify Existing Patterns Retained (1.5 hours)

**Objective**: Ensure Phase 0 additions don't break existing enforcement patterns.

#### Task 4.4.1: Verify Pattern 1 - Path Pre-Calculation (Lines 87-132 after insertions)

**Location**: STEP 2 section (after Phase 0 and header updates)

**Expected Content**:
- Bash code block with "EXECUTE NOW" marker
- Absolute path calculation logic: `REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"`
- Associative array storage: `SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"`
- Path verification loop checking for leading `/`

**Verification**:
```bash
# Check EXECUTE NOW marker present
grep -n "EXECUTE NOW - Calculate" /home/benjamin/.config/.claude/commands/report.md

# Check absolute path calculation
grep -n 'REPORT_PATH=.*printf.*RESEARCH_SUBDIR' /home/benjamin/.config/.claude/commands/report.md

# Check path verification loop
grep -n 'if \[\[ ! ".*" =~ \^/ \]\]' /home/benjamin/.config/.claude/commands/report.md
```

**Success Criteria**:
- [ ] EXECUTE NOW marker present in STEP 2 section
- [ ] Absolute path calculation code intact
- [ ] Path verification loop intact
- [ ] Checkpoint output block present: "CHECKPOINT: Path pre-calculation complete"

---

#### Task 4.4.2: Verify Pattern 2 - Verification Checkpoints (Lines 118-142 after insertions)

**Location**: End of STEP 2 section, all of STEP 4 section

**Expected Content**:

**Checkpoint 1** (End of STEP 2 - Path Pre-Calculation):
```bash
# Verify all paths are absolute
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
    echo "CRITICAL ERROR: Path for '$subtopic' is not absolute: ${SUBTOPIC_REPORT_PATHS[$subtopic]}"
    exit 1
  fi
done

echo "✓ VERIFIED: All paths are absolute"
echo "✓ VERIFIED: ${#SUBTOPIC_REPORT_PATHS[@]} report paths calculated"
echo "✓ VERIFIED: Ready to invoke research agents"
```

**Checkpoint 2** (STEP 4 - Report Verification):
```bash
declare -A VERIFIED_PATHS
VERIFICATION_ERRORS=0

for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

  if [ -f "$EXPECTED_PATH" ]; then
    echo "✓ Verified: $subtopic at $EXPECTED_PATH"
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    echo "⚠ Warning: Report not found at expected path: $EXPECTED_PATH"
    # [fallback search logic]
  fi
done
```

**Verification**:
```bash
# Check first verification checkpoint
grep -A 10 "Verify all paths are absolute" /home/benjamin/.config/.claude/commands/report.md | grep "VERIFIED"

# Check second verification checkpoint
grep -A 20 "VERIFIED_PATHS" /home/benjamin/.config/.claude/commands/report.md | grep "✓ Verified"
```

**Success Criteria**:
- [ ] Path verification checkpoint present in STEP 2
- [ ] Report existence verification present in STEP 4
- [ ] Verification output includes "✓ VERIFIED" markers
- [ ] Error handling present for verification failures

---

#### Task 4.4.3: Add Pattern 3 - Fallback Mechanisms (If Missing)

**Location**: STEP 4 - Verification section

**Current State**: Partial fallback present (lines ~218-236) - searches alternate locations

**Enhancement Needed**: Add explicit fallback file creation if agent non-compliance

**Current Fallback** (lines ~218-236):
```bash
if [ -n "$FOUND_PATH" ]; then
  echo "  → Found at alternate location: $FOUND_PATH"
  VERIFIED_PATHS["$subtopic"]="$FOUND_PATH"
else
  echo "  → ERROR: Report not created by agent for: $subtopic"
  VERIFICATION_ERRORS=$((VERIFICATION_ERRORS + 1))

  # Fallback: Create minimal report from agent output
  # (Extract from agent response if available)
  echo "  → Creating fallback report..."
  # Implementation: Extract agent's research output and create report
fi
```

**Enhancement** - Replace comment with actual implementation:
```bash
else
  echo "  → ERROR: Report not created by agent for: $subtopic"
  VERIFICATION_ERRORS=$((VERIFICATION_ERRORS + 1))

  # Fallback: Create minimal report with placeholder content
  echo "  → Creating fallback report at: $EXPECTED_PATH"

  cat > "$EXPECTED_PATH" <<EOF
# ${subtopic//_/ } Research Report

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Status**: Fallback Creation (Agent Non-Compliance)
- **Topic**: $subtopic

## Note
This report was created by fallback mechanism due to agent non-compliance.
The research-specialist agent did not create this file as instructed.

## Placeholder Content
Research findings for ${subtopic//_/ } should be added manually.

EOF

  if [ -f "$EXPECTED_PATH" ]; then
    echo "  → ✓ Fallback report created successfully"
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    echo "  → ✗ CRITICAL: Fallback creation also failed"
    exit 1
  fi
fi
```

**Verification**:
```bash
# Check fallback implementation present
grep -A 20 "Fallback: Create minimal report" /home/benjamin/.config/.claude/commands/report.md
```

**Success Criteria**:
- [ ] Fallback file creation implemented (not just comment)
- [ ] Fallback uses heredoc to write placeholder report
- [ ] Fallback verification confirms file created
- [ ] Critical exit if fallback also fails

---

#### Task 4.4.4: Verify Pattern 4 - Checkpoint Reporting (Lines 134-141 after insertions)

**Location**: End of STEP 2 section

**Expected Content**:
```bash
**CHECKPOINT**:
```
CHECKPOINT: Path pre-calculation complete
- Subtopics identified: ${#SUBTOPICS[@]}
- Report paths calculated: ${#SUBTOPIC_REPORT_PATHS[@]}
- All paths verified: ✓
- Proceeding to: Parallel agent invocation
```
```

**Verification**:
```bash
# Check checkpoint block present
grep -B 2 -A 6 "CHECKPOINT: Path pre-calculation complete" /home/benjamin/.config/.claude/commands/report.md
```

**Success Criteria**:
- [ ] CHECKPOINT block present with proper formatting
- [ ] Checkpoint includes quantitative metrics (subtopic count, path count)
- [ ] Checkpoint includes verification confirmation
- [ ] Checkpoint indicates next step

---

### Task Group 4.5: Testing and Validation (2 hours)

**Objective**: Verify migration achieves 100% file creation rate and correct hierarchical execution.

#### Task 4.5.1: File Creation Rate Test (30 minutes)

**Test Procedure**:
```bash
#!/bin/bash
# test_report_file_creation.sh

SUCCESS_COUNT=0
TOTAL_TESTS=10

for i in {1..10}; do
  echo "Test $i: Running /report command..."

  # Run report command with test topic
  TOPIC="Test topic $i: code organization patterns and best practices"

  # Capture output
  OUTPUT=$(/report "$TOPIC" 2>&1)

  # Check for hierarchical structure creation
  # Expected: specs/{NNN_topic}/reports/{NNN_research}/
  # With: multiple subtopic reports + OVERVIEW.md

  # Find most recent topic directory
  LATEST_TOPIC=$(ls -td /home/benjamin/.config/.claude/specs/[0-9][0-9][0-9]_* 2>/dev/null | head -1)

  if [ -z "$LATEST_TOPIC" ]; then
    echo "  ✗ No topic directory created"
    continue
  fi

  # Find reports subdirectory
  REPORTS_DIR="$LATEST_TOPIC/reports"

  if [ ! -d "$REPORTS_DIR" ]; then
    echo "  ✗ No reports directory created"
    continue
  fi

  # Find research subdirectory (latest numbered directory)
  RESEARCH_DIR=$(ls -td "$REPORTS_DIR"/[0-9][0-9][0-9]_* 2>/dev/null | head -1)

  if [ -z "$RESEARCH_DIR" ]; then
    echo "  ✗ No research subdirectory created"
    continue
  fi

  # Count subtopic reports
  SUBTOPIC_COUNT=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]_*.md 2>/dev/null | grep -v OVERVIEW | wc -l)

  # Check for OVERVIEW.md
  if [ ! -f "$RESEARCH_DIR/OVERVIEW.md" ]; then
    echo "  ✗ OVERVIEW.md not created"
    continue
  fi

  # Verify hierarchical structure
  if [ "$SUBTOPIC_COUNT" -ge 2 ]; then
    echo "  ✓ Test $i passed: $SUBTOPIC_COUNT subtopic reports + OVERVIEW.md"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ✗ Insufficient subtopic reports: $SUBTOPIC_COUNT (expected ≥2)"
  fi
done

echo ""
echo "File Creation Rate: $SUCCESS_COUNT/$TOTAL_TESTS"

if [ "$SUCCESS_COUNT" -eq "$TOTAL_TESTS" ]; then
  echo "✓ SUCCESS: 100% file creation rate achieved"
  exit 0
else
  echo "✗ FAILURE: File creation rate below 100%"
  exit 1
fi
```

**Success Criteria**:
- [ ] 10/10 tests create hierarchical report structures
- [ ] Each test creates ≥2 subtopic reports
- [ ] Each test creates OVERVIEW.md
- [ ] Files created at correct paths (specs/{NNN}/reports/{NNN}/)

---

#### Task 4.5.2: Hierarchical Pattern Execution Test (30 minutes)

**Test Procedure**:
```bash
# Test that Task tool is used (not direct Read/Grep/Write)

# Run report command with detailed output logging
/report "Comprehensive analysis of authentication best practices in 2025" > /tmp/report_test_output.txt 2>&1

# Check for Task tool invocations
TASK_COUNT=$(grep -c "Task {" /tmp/report_test_output.txt)

echo "Task tool invocations detected: $TASK_COUNT"

if [ "$TASK_COUNT" -ge 3 ]; then
  echo "✓ Hierarchical pattern executing (≥3 Task invocations detected)"
else
  echo "✗ Hierarchical pattern NOT executing (expected ≥3, found $TASK_COUNT)"
  echo ""
  echo "Checking for direct tool usage (should be absent):"
  grep -E "(Read tool|Grep tool|Write tool)" /tmp/report_test_output.txt | head -5
fi

# Check that multiple subtopic reports were created
LATEST_TOPIC=$(ls -td /home/benjamin/.config/.claude/specs/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
RESEARCH_DIR=$(ls -td "$LATEST_TOPIC/reports"/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
SUBTOPIC_COUNT=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]_*.md 2>/dev/null | grep -v OVERVIEW | wc -l)

echo "Subtopic reports created: $SUBTOPIC_COUNT"

if [ "$SUBTOPIC_COUNT" -ge 3 ]; then
  echo "✓ Parallel agent execution confirmed (≥3 subtopic reports)"
else
  echo "⚠ Warning: Fewer subtopics than expected ($SUBTOPIC_COUNT)"
fi
```

**Success Criteria**:
- [ ] Task tool invocations visible in output (≥3)
- [ ] No direct Read/Grep/Write usage for research tasks
- [ ] Multiple subtopic reports created (≥3 for complex topic)
- [ ] OVERVIEW.md created after subtopic reports

---

#### Task 4.5.3: Audit Score Verification (15 minutes)

**Test Procedure**:
```bash
# Run audit script on migrated command
/home/benjamin/.config/.claude/lib/audit-execution-enforcement.sh \
  /home/benjamin/.config/.claude/commands/report.md > /tmp/report_audit.txt

# Extract score
SCORE=$(grep "^Score:" /tmp/report_audit.txt | awk '{print $2}' | cut -d'/' -f1)

echo "Audit Score: $SCORE/100"

if [ "$SCORE" -ge 95 ]; then
  echo "✓ Audit score meets target (≥95/100)"
else
  echo "✗ Audit score below target: $SCORE/100"
  echo ""
  echo "Missing patterns:"
  grep "Missing:" /tmp/report_audit.txt
fi
```

**Success Criteria**:
- [ ] Audit score ≥95/100
- [ ] All Phase 0 elements detected by audit
- [ ] All Pattern 1-4 elements detected
- [ ] All agent invocation templates detected

---

#### Task 4.5.4: Metadata Context Reduction Test (30 minutes)

**Test Procedure**:
```bash
# Test that metadata extraction works correctly

# Run report command
/report "Database migration strategies and version control patterns"

# Find created reports
LATEST_TOPIC=$(ls -td /home/benjamin/.config/.claude/specs/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
RESEARCH_DIR=$(ls -td "$LATEST_TOPIC/reports"/[0-9][0-9][0-9]_* 2>/dev/null | head -1)

# Test metadata extraction on each subtopic report
for report in "$RESEARCH_DIR"/[0-9][0-9][0-9]_*.md; do
  if [ "$report" == "$RESEARCH_DIR/OVERVIEW.md" ]; then
    continue
  fi

  echo "Testing metadata extraction: $(basename "$report")"

  # Use metadata extraction utility
  METADATA=$(source /home/benjamin/.config/.claude/lib/metadata-extraction.sh && \
             extract_report_metadata "$report")

  # Check JSON structure
  TITLE=$(echo "$METADATA" | jq -r '.title')
  SUMMARY=$(echo "$METADATA" | jq -r '.summary')
  SUMMARY_WORD_COUNT=$(echo "$SUMMARY" | wc -w)

  echo "  Title: $TITLE"
  echo "  Summary word count: $SUMMARY_WORD_COUNT"

  if [ "$SUMMARY_WORD_COUNT" -le 50 ]; then
    echo "  ✓ Summary within 50-word limit"
  else
    echo "  ✗ Summary exceeds 50 words: $SUMMARY_WORD_COUNT"
  fi
done

# Calculate context reduction
FULL_SIZE=$(du -sb "$RESEARCH_DIR"/*.md | awk '{sum+=$1} END {print sum}')
METADATA_SIZE=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]_*.md | while read f; do
  source /home/benjamin/.config/.claude/lib/metadata-extraction.sh
  extract_report_metadata "$f" | wc -c
done | awk '{sum+=$1} END {print sum}')

REDUCTION_PCT=$(echo "scale=2; (1 - $METADATA_SIZE / $FULL_SIZE) * 100" | bc)

echo ""
echo "Context Reduction Analysis:"
echo "  Full content size: $FULL_SIZE bytes"
echo "  Metadata-only size: $METADATA_SIZE bytes"
echo "  Reduction: ${REDUCTION_PCT}%"

if (( $(echo "$REDUCTION_PCT >= 92" | bc -l) )); then
  echo "  ✓ Context reduction meets target (≥92%)"
else
  echo "  ✗ Context reduction below target: ${REDUCTION_PCT}%"
fi
```

**Success Criteria**:
- [ ] Metadata extraction works for all subtopic reports
- [ ] Summaries are ≤50 words each
- [ ] Context reduction ≥92%
- [ ] JSON structure valid for all extractions

---

#### Task 4.5.5: Regression Testing (30 minutes)

**Test Procedure**:
```bash
# Test existing /report usage patterns still work

# Test 1: Simple topic (should still work)
/report "Error handling patterns in Lua"

# Verify report created (may be single report or hierarchical, both acceptable)
LATEST_TOPIC=$(ls -td /home/benjamin/.config/.claude/specs/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
if [ -d "$LATEST_TOPIC/reports" ]; then
  echo "✓ Test 1: Simple topic report created"
else
  echo "✗ Test 1: Report directory not created"
fi

# Test 2: Complex topic with multiple aspects
/report "Neovim plugin development: LSP integration, treesitter configuration, and custom UI components"

# Verify hierarchical structure
LATEST_TOPIC=$(ls -td /home/benjamin/.config/.claude/specs/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
RESEARCH_DIR=$(ls -td "$LATEST_TOPIC/reports"/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
SUBTOPIC_COUNT=$(ls "$RESEARCH_DIR"/[0-9][0-9][0-9]_*.md 2>/dev/null | grep -v OVERVIEW | wc -l)

if [ "$SUBTOPIC_COUNT" -ge 3 ] && [ -f "$RESEARCH_DIR/OVERVIEW.md" ]; then
  echo "✓ Test 2: Complex topic hierarchical structure created"
else
  echo "✗ Test 2: Hierarchical structure incomplete"
fi

# Test 3: Verify cross-references work
if [ -f "$RESEARCH_DIR/OVERVIEW.md" ]; then
  # Check OVERVIEW.md links to subtopic reports
  LINK_COUNT=$(grep -c '\[.*\](./[0-9][0-9][0-9]_.*\.md)' "$RESEARCH_DIR/OVERVIEW.md")

  if [ "$LINK_COUNT" -ge 3 ]; then
    echo "✓ Test 3: Cross-references in OVERVIEW.md"
  else
    echo "⚠ Test 3: Incomplete cross-references ($LINK_COUNT links)"
  fi
fi

# Test 4: Run existing test suite (if exists)
if [ -f "/home/benjamin/.config/.claude/tests/test_report_command.sh" ]; then
  bash /home/benjamin/.config/.claude/tests/test_report_command.sh
  if [ $? -eq 0 ]; then
    echo "✓ Test 4: Existing test suite passes"
  else
    echo "✗ Test 4: Existing test suite failures"
  fi
fi
```

**Success Criteria**:
- [ ] Simple topics still work (backward compatibility)
- [ ] Complex topics create hierarchical structures
- [ ] Cross-references present in OVERVIEW.md
- [ ] Existing test suite passes (if present)
- [ ] No breaking changes to command interface

---

## Rollback Procedures

### If Migration Breaks Functionality

**Scenario**: Tests fail after migration, functionality broken.

**Rollback Steps**:

1. **Identify Failure Point** (5 minutes):
```bash
# Check which test failed
bash /home/benjamin/.config/.claude/specs/artifacts/077_execution_enforcement_migration/phase_4_test_results.log

# Common failure points:
# - Phase 0 insertion broke section numbering
# - STEP format broke bash code parsing
# - Agent invocation template changes broke Task invocations
```

2. **Revert Changes** (10 minutes):
```bash
# Option A: Git revert (if changes committed)
cd /home/benjamin/.config
git log --oneline | head -5  # Find commit hash
git revert <commit-hash>

# Option B: Restore from backup (if backup created before migration)
cp /home/benjamin/.config/.claude/commands/report.md.backup \
   /home/benjamin/.config/.claude/commands/report.md
```

3. **Verify Restoration** (5 minutes):
```bash
# Re-run basic test
/report "Test rollback functionality"

# Check output
LATEST_TOPIC=$(ls -td /home/benjamin/.config/.claude/specs/[0-9][0-9][0-9]_* 2>/dev/null | head -1)
ls -la "$LATEST_TOPIC/reports"

# If files created, rollback successful
```

4. **Analyze Failure** (15 minutes):
```bash
# Compare original vs migrated
diff /home/benjamin/.config/.claude/commands/report.md.backup \
     /home/benjamin/.config/.claude/commands/report.md > /tmp/migration_diff.txt

# Review diff for breaking changes
less /tmp/migration_diff.txt

# Document issue
cat > /home/benjamin/.config/.claude/specs/artifacts/077_execution_enforcement_migration/phase_4_rollback_reason.md <<EOF
# Phase 4 Rollback Analysis

## Failure Type
[Describe what broke]

## Root Cause
[What change caused the failure]

## Fix Required
[What needs to be done differently]
EOF
```

---

### Partial Rollback Options

**Scenario**: Some changes work, others don't.

**Selective Rollback**:

1. **Keep Phase 0** (if working), revert other changes:
   - Phase 0 is critical and standalone
   - Can function without STEP format changes

2. **Keep STEP format** (if working), revert agent template changes:
   - STEP format improves clarity
   - Agent templates can be enhanced separately

3. **Keep Pattern 3 fallback**, revert enforcement markers:
   - Fallback mechanism adds reliability
   - Can exist without "THIS EXACT TEMPLATE" markers

**Implementation**:
```bash
# Manual selective revert using Edit tool
# Example: Keep Phase 0, revert STEP format

# Restore original section headers
grep -n "^### [0-9]" /home/benjamin/.config/.claude/commands/report.md.backup

# Replace STEP headers with original numbering
# (Use Edit tool for each section)
```

---

## Post-Migration Deliverables

### Required Artifacts

1. **Migration Log** (`phase_4_migration_log.md`):
```markdown
# Phase 4 Migration Log

## Execution Summary
- **Start Time**: [timestamp]
- **End Time**: [timestamp]
- **Duration**: [hours]
- **Migrator**: [name/system]

## Changes Applied
- [ ] Phase 0 role clarification (lines 11-22)
- [ ] STEP format headers (6 sections updated)
- [ ] Agent invocation enhancements (3 templates updated)
- [ ] Pattern 3 fallback implementation (lines 230-250)

## Test Results
- File creation rate: X/10
- Audit score: XX/100 (up from baseline YY/100)
- Hierarchical pattern: [PASS/FAIL]
- Regression tests: [PASS/FAIL]

## Issues Encountered
[List any issues and resolutions]

## Rollback Status
[Not needed | Partial rollback | Full rollback]
```

2. **Test Results** (`phase_4_test_results.log`):
```bash
# Save all test output
bash test_report_file_creation.sh > phase_4_test_results.log 2>&1
bash test_hierarchical_pattern.sh >> phase_4_test_results.log 2>&1
bash test_audit_score.sh >> phase_4_test_results.log 2>&1
```

3. **Audit Report** (`phase_4_audit_report.txt`):
```bash
/home/benjamin/.config/.claude/lib/audit-execution-enforcement.sh \
  /home/benjamin/.config/.claude/commands/report.md > phase_4_audit_report.txt
```

4. **Migration Tracking Update** (`077_migration_tracking.csv`):
```csv
Command,Baseline_Score,Post_Migration_Score,File_Creation_Before,File_Creation_After,Migration_Date,Status
/report,XX/100,YY/100,X/10,10/10,2025-10-20,COMPLETE
```

---

## Success Criteria Validation

### Checklist

- [ ] **Phase 0 Complete**: All 4 elements added (orchestrate statement, YOUR ROLE, CRITICAL INSTRUCTIONS, indirect visibility explanation)
- [ ] **STEP Format Complete**: All 6 major sections use STEP N (REQUIRED BEFORE STEP N+1) format
- [ ] **Agent Templates Enhanced**: All 3 agent invocations have "THIS EXACT TEMPLATE" markers
- [ ] **Pattern 3 Implemented**: Fallback file creation implemented (not just comment)
- [ ] **File Creation Rate**: 10/10 tests pass (100%)
- [ ] **Audit Score**: ≥95/100
- [ ] **Hierarchical Execution**: Task invocations visible in output
- [ ] **Context Reduction**: ≥92% reduction verified
- [ ] **Zero Regressions**: Existing tests pass
- [ ] **Documentation Updated**: Migration log, test results, audit report created

---

## Time Allocation Breakdown

| Task Group | Task | Estimated Time | Cumulative |
|------------|------|----------------|------------|
| 4.1 | Add Phase 0 Role Clarification | 2 hours | 2h |
| 4.1.1 | Replace opening statement | 20 min | - |
| 4.1.2 | Add YOUR ROLE section | 30 min | - |
| 4.1.3 | Add CRITICAL INSTRUCTIONS | 1h 10min | - |
| 4.2 | Update Section Headers to STEP Format | 1.5 hours | 3.5h |
| 4.2.1-6 | 6 section header updates | 15 min each | - |
| 4.3 | Verify and Enhance Agent Invocations | 2 hours | 5.5h |
| 4.3.1-3 | 3 agent invocation audits | 40 min each | - |
| 4.4 | Verify Existing Patterns Retained | 1.5 hours | 7h |
| 4.4.1-4 | 4 pattern verifications | 20-25 min each | - |
| 4.5 | Testing and Validation | 2 hours | 9h |
| 4.5.1-5 | 5 test procedures | 15-30 min each | - |
| **Buffer** | Unexpected issues, refinement | 1 hour | **10h** |

**Total Estimated**: 8 hours (with 1h buffer → 9-10h realistic)

---

## Dependencies

### Prerequisites
- [ ] Phase 1 complete (baseline measurement infrastructure in place)
- [ ] Phase 2 complete (research-specialist agent already migrated to Standard 0.5)
- [ ] Audit script functional: `.claude/lib/audit-execution-enforcement.sh`
- [ ] Metadata extraction utility functional: `.claude/lib/metadata-extraction.sh`

### Blocking Dependencies
None - /report command can be migrated independently.

### Downstream Impact
- **Phase 5** (/plan migration): Will reference this migration as example
- **Phase 7** (/orchestrate migration): Uses same hierarchical pattern, will follow this approach
- **Agent migrations**: Research-synthesizer agent may need alignment with updated /report patterns

---

## Risk Mitigation

### High-Risk Elements

**Risk 1**: Phase 0 insertion breaks section numbering in subsequent content
- **Mitigation**: Use Edit tool carefully, verify line numbers after each insertion
- **Validation**: Re-run command after each major change
- **Rollback**: Keep line-by-line backup of changes

**Risk 2**: STEP format breaks bash code block parsing
- **Mitigation**: Test each STEP section individually after header change
- **Validation**: Check bash code blocks still execute correctly
- **Rollback**: Restore original headers if parsing fails

**Risk 3**: Agent invocation template changes break Task tool
- **Mitigation**: Follow exact YAML format from working examples
- **Validation**: Test each agent invocation separately
- **Rollback**: Restore original Task blocks from backup

---

## Notes

### Key Success Factors

1. **Phase 0 is Critical**: This is the newest pattern and addresses the root cause. Invest time here.
2. **Test Incrementally**: Don't wait until end. Test after each task group.
3. **Preserve Existing Logic**: Only add enforcement, don't change orchestration logic.
4. **Use Reference Model**: research-specialist.md is already compliant (95/100). Study its patterns.

### Lessons from Similar Migrations

From /orchestrate Phase 7 research delegation migration:
- Phase 0 addition increased Task invocations from 0% to 100%
- STEP format improved execution sequence compliance by 60%
- "THIS EXACT TEMPLATE" markers increased agent adherence by 40%
- Fallback mechanisms prevented 100% of zero-file scenarios

### Common Pitfalls to Avoid

1. **Incomplete Phase 0**: Don't just add "I'll orchestrate" without full 4-element structure
2. **Inconsistent STEP numbering**: Verify STEP 1 → 2 → 3 sequence correct
3. **Missing EXECUTE NOW markers**: Each bash block needs explicit execution marker
4. **Weak agent prompts**: Every Task prompt needs "ABSOLUTE REQUIREMENT" language

---

## Expansion Summary

**Total Lines in Expansion**: ~1450 lines
**Specification Depth**: Level 2 (detailed task breakdown with code examples)
**Implementation Ready**: Yes - all line numbers, code blocks, and verification commands provided

**Expansion provides**:
- Exact Phase 0 language additions with line references
- Detailed hierarchical multi-agent pattern preservation strategy
- Explicit metadata-based context passing verification steps
- 92-97% context reduction validation procedures
- 5 comprehensive testing scenarios with bash scripts
- Complete rollback procedures with selective revert options

This expansion transforms the 24-task outline into a 300-500 line implementation specification suitable for execution by /implement command or manual implementation.
