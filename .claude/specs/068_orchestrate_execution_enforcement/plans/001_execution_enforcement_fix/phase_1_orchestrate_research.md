# Phase 1: Fix /orchestrate Research Phase - Detailed Implementation

## Metadata
- **Phase Number**: 1
- **Parent Plan**: 001_execution_enforcement_fix.md
- **Objective**: Guarantee research report file creation through execution enforcement
- **Dependencies**: []
- **Complexity**: High
- **Risk**: Medium (changes core orchestration flow)
- **Estimated Time**: 6-8 hours
- **Status**: PENDING

## Overview

This phase transforms the /orchestrate research phase from descriptive guidance to imperative enforcement, guaranteeing 100% file creation rate through explicit execution markers, verification checkpoints, and fallback mechanisms.

### Current State Analysis

The research phase (lines 480-730) has three main problems:

**Problem 1: Descriptive Path Calculation (lines 500-526)**
- Uses phrases like "First, create or find" (line 500)
- Says "Calculate absolute paths" (line 513) but doesn't enforce execution
- Missing "EXECUTE NOW" marker before code blocks

**Problem 2: Weak Agent Enforcement (lines 536-605)**
- Agent prompt template (lines 576-605) lacks "THIS EXACT TEMPLATE" marker
- Missing explicit "Do NOT simplify" warnings
- No verification that Claude used the exact template

**Problem 3: Optional-Sounding Verification (lines 638-729)**
- Says "verify that report files were created" (line 709) - sounds advisory
- Verification code lacks "MANDATORY" markers
- Fallback mechanism present but not enforced as guaranteed safety net

### Success Metrics

**Before (Current State)**:
- File creation rate: ~60-80% (varies by agent compliance)
- Claude may skip path pre-calculation
- Agent prompts may be simplified/paraphrased
- Verification may be treated as optional

**After (Target State)**:
- File creation rate: 100% guaranteed (via fallback)
- Path pre-calculation: Always executes
- Agent prompts: Used verbatim
- Verification: Always runs, fallback always triggers if needed

## Implementation Tasks

### Task 1: Read Current Implementation

**Objective**: Understand the exact current state before making changes.

**Action**: Read lines 480-730 of .claude/commands/orchestrate.md

**Expected Findings**:
- Path pre-calculation code block location
- Agent invocation template structure
- Verification checkpoint implementation
- Fallback mechanism current state

**Completion Criteria**: Can identify all 10 specific locations that need enforcement markers

---

### Task 2: Identify Descriptive Language Sections

**Objective**: Mark every location using guidance language instead of imperatives.

**Specific Locations to Mark**:

1. **Line 500**: "First, create or find the workflow topic directory"
   - Change to: "**EXECUTE NOW - Create Workflow Topic Directory**"

2. **Line 512-513**: "Calculate absolute paths for each topic"
   - Change to: "**EXECUTE NOW - Calculate Report Paths**"

3. **Line 528**: "Verification Checkpoint:"
   - Change to: "**MANDATORY VERIFICATION - Path Pre-Calculation**"

4. **Line 536**: "For each research agent, include..."
   - Change to: "**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**"

5. **Line 569**: "Complete Task Tool Invocation Example:"
   - Add: "**THIS IS NOT AN EXAMPLE - USE THIS EXACT CODE**"

6. **Line 607-637**: Parallel invocation guidance
   - Add "**CRITICAL REQUIREMENT**" markers

7. **Line 638**: "EXECUTE NOW - Parse REPORT_PATH from Agent Outputs"
   - Keep but strengthen with "**ABSOLUTE REQUIREMENT**"

8. **Line 699**: "Verification Checklist:"
   - Change to: "**MANDATORY VERIFICATION CHECKLIST**"

9. **Line 707**: "EXECUTE NOW - Verify Report File Creation"
   - Keep but add "**NON-OPTIONAL - This Step MUST Execute**"

10. **Line 714-729**: Fallback creation logic
    - Add: "**GUARANTEED SAFETY NET - Always Creates File**"

**Completion Criteria**: All 10 locations marked with specific change requirements

---

### Task 3: Add "EXECUTE NOW" Marker for Path Pre-Calculation

**Objective**: Make path pre-calculation mandatory and unambiguous.

**Current Code (lines 500-526)**:
```markdown
**Adapting Topics**:

```bash
# First, create or find the workflow topic directory
# This centralizes all artifacts (reports, plans, summaries) for this workflow
source "${CLAUDE_PROJECT_DIR}/.claude/lib/template-integration.sh"
...
```

**New Code (Enforcement Applied)**:
```markdown
**EXECUTE NOW - Calculate Report Paths BEFORE Agent Invocation**

YOU MUST execute this code block BEFORE invoking research agents. This is NOT optional guidance.

**WHY THIS MATTERS**: Agents need EXACT absolute paths to prevent path mismatch errors. If you skip this step, agents will create files in wrong locations or not at all.

**VERIFICATION REQUIREMENT**: After executing this block, you MUST confirm all paths are absolute and stored in REPORT_PATHS array.

```bash
# MANDATORY: Create workflow topic directory
# This centralizes all artifacts (reports, plans, summaries) for this workflow
source "${CLAUDE_PROJECT_DIR}/.claude/lib/template-integration.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

WORKFLOW_TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" ".claude/specs")
echo "Workflow topic directory: $WORKFLOW_TOPIC_DIR"

# Example topics (adapt based on workflow):
TOPICS=("existing_patterns" "best_practices" "integration_approaches")

# MANDATORY: Calculate absolute paths for each topic
declare -A REPORT_PATHS

for topic in "${TOPICS[@]}"; do
  # Use create_topic_artifact() to create report with proper numbering
  # This ensures topic-based organization: specs/{NNN_workflow}/reports/NNN_topic.md
  REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "${topic}" "")

  # Store in associative array
  REPORT_PATHS["$topic"]="$REPORT_PATH"

  echo "  Research Topic: $topic"
  echo "  Report Path: $REPORT_PATH"
done
```

**MANDATORY VERIFICATION - Path Pre-Calculation Complete**

After executing the path calculation block, YOU MUST verify:

```bash
# Verification: Check all paths are absolute
for topic in "${!REPORT_PATHS[@]}"; do
  if [[ ! "${REPORT_PATHS[$topic]}" =~ ^/ ]]; then
    echo "CRITICAL ERROR: Path for '$topic' is not absolute: ${REPORT_PATHS[$topic]}"
    exit 1
  fi
done

echo "✓ VERIFIED: All paths are absolute"
echo "✓ VERIFIED: ${#REPORT_PATHS[@]} report paths calculated"
echo "✓ VERIFIED: Ready to invoke research agents"
```

**CHECKPOINT REQUIREMENT**: Report completion before proceeding:
```
CHECKPOINT: Path pre-calculation complete
- Topics identified: ${#TOPICS[@]}
- Report paths calculated: ${#REPORT_PATHS[@]}
- All paths verified: ✓
- Proceeding to: Agent invocation
```
```

**Changes Made**:
1. Changed "**Adapting Topics**:" to "**EXECUTE NOW - Calculate Report Paths BEFORE Agent Invocation**"
2. Added "YOU MUST execute" imperative language
3. Added "**WHY THIS MATTERS**" explanation
4. Added "**VERIFICATION REQUIREMENT**" with code block
5. Added "MANDATORY" comments in bash code
6. Added "**MANDATORY VERIFICATION**" section with explicit checks
7. Added "**CHECKPOINT REQUIREMENT**" for progress reporting

**Testing**: Verify Claude executes path calculation before agent invocation

**Completion Criteria**:
- Path pre-calculation marked with "EXECUTE NOW"
- Verification checkpoint added
- Checkpoint reporting requirement added
- Comments explain WHY enforcement matters

---

### Task 4: Strengthen Agent Invocation with "THIS EXACT TEMPLATE"

**Objective**: Prevent Claude from simplifying or paraphrasing agent prompts.

**Current Code (lines 536-605)**:
```markdown
**Integration with Agent Invocation**:

For each research agent, include the calculated absolute path in the agent prompt:

```markdown
**ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**
...
```

**Complete Task Tool Invocation Example**:

```yaml
Task {
  subagent_type: "general-purpose"
  ...
}
```
```

**New Code (Enforcement Applied)**:
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

**CRITICAL INSTRUCTION**: The agent prompt below is NOT an example or suggestion. It is the EXACT template you MUST use when invoking research agents. Do NOT:
- Simplify the language
- Remove any "ABSOLUTE REQUIREMENT" markers
- Paraphrase the instructions
- Skip any sections
- Change the structure

**WHY THIS MATTERS**: Research agents need explicit enforcement markers to guarantee file creation. If you simplify this prompt, agents will treat file creation as optional, leading to 0% success rate.

**ENFORCEMENT CHECKPOINT**: Before invoking agents, confirm you will use this EXACT prompt template without modifications.

---

**EXACT AGENT PROMPT TEMPLATE** (Copy verbatim for EACH research agent):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [TOPIC] with mandatory artifact creation"
  timeout: 300000  # 5 minutes per research agent
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Creating the report file is NOT optional. It is your PRIMARY task. Follow these steps IN ORDER:

    **STEP 1: CREATE THE FILE** (Do this FIRST, before any research)
    Use the Write tool to create a report file at this EXACT path:
    **Report Path**: [INSERT ABSOLUTE PATH FROM REPORT_PATHS ARRAY HERE]

    **CRITICAL**: Use Write tool NOW. Do not wait until after research. Create the file FIRST with initial structure, then fill in findings.

    **STEP 2: CONDUCT RESEARCH**
    Analyze [SPECIFIC RESEARCH FOCUS FOR THIS TOPIC]:
    1. [Specific search pattern 1]
    2. [Specific analysis requirement 2]
    3. [Specific documentation requirement 3]
    4. [Specific recommendation requirement 4]

    Write your findings DIRECTLY into the report file created in Step 1.

    **STEP 3: RETURN CONFIRMATION**
    After completing Steps 1 and 2, return ONLY this confirmation (no summary):
    \`\`\`
    REPORT_CREATED: [SAME ABSOLUTE PATH FROM STEP 1]
    \`\`\`

    **CRITICAL REQUIREMENTS** (Non-Negotiable):
    - DO NOT return summary text. Orchestrator will read your report file.
    - DO NOT use relative paths or calculate paths yourself
    - DO NOT skip file creation - it is mandatory
    - DO NOT wait to create file - do it in STEP 1
    - Use Write tool with the EXACT path provided above
    - File MUST exist at specified path when you return
  "
}
```

**VARIABLES TO REPLACE** (These are the ONLY parts you modify):
- `[TOPIC]`: Replace with topic name (e.g., "authentication_patterns")
- `[INSERT ABSOLUTE PATH FROM REPORT_PATHS ARRAY HERE]`: Replace with `${REPORT_PATHS["topic_name"]}`
- `[SPECIFIC RESEARCH FOCUS FOR THIS TOPIC]`: Replace with topic-specific research requirements

**ENFORCEMENT VERIFICATION**: After replacing variables, confirm:
- [ ] All enforcement markers preserved ("ABSOLUTE REQUIREMENT", "CRITICAL", "STEP 1", etc.)
- [ ] No language simplified or paraphrased
- [ ] Structure identical to template
- [ ] Only specified variables replaced

---

**MANDATORY: Parallel Invocation Pattern**

To achieve true parallel execution (60-70% time savings), YOU MUST invoke ALL research agents in a SINGLE message with multiple Task tool calls:

**CORRECT PATTERN** (Required):
```
Message to Claude Code:
I'm invoking 3 research agents in parallel:

Task { [agent 1 with EXACT template above] }
Task { [agent 2 with EXACT template above] }
Task { [agent 3 with EXACT template above] }
```

**INCORRECT PATTERN** (Do NOT do this):
```
Message 1: Task { [agent 1] }
[wait for response]
Message 2: Task { [agent 2] }
[wait for response]
Message 3: Task { [agent 3] }
```

**VERIFICATION BEFORE INVOCATION**:
- [ ] All agent prompts use EXACT template
- [ ] All REPORT_PATHS replaced with absolute paths
- [ ] All Task calls in SINGLE message
- [ ] No enforcement markers removed
```

**Changes Made**:
1. Changed heading to "**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**"
2. Added "**CRITICAL INSTRUCTION**" with explicit "Do NOT" list
3. Added "**WHY THIS MATTERS**" explanation
4. Added "**ENFORCEMENT CHECKPOINT**" before invocation
5. Marked template as "**EXACT AGENT PROMPT TEMPLATE** (Copy verbatim)"
6. Added "**VARIABLES TO REPLACE**" section (only allowed modifications)
7. Added "**ENFORCEMENT VERIFICATION**" checklist
8. Strengthened parallel invocation section with "**MANDATORY**" marker
9. Added "**VERIFICATION BEFORE INVOCATION**" final checklist

**Testing**: Verify Claude uses exact template without simplification

**Completion Criteria**:
- Template marked as "THIS EXACT TEMPLATE"
- "Do NOT" list for forbidden modifications
- Verification checklist before invocation
- Parallel invocation marked as "MANDATORY"

---

### Task 5: Add "MANDATORY VERIFICATION" Checkpoint After Agent Completion

**Objective**: Ensure verification always executes and fallback always triggers.

**Current Code (lines 638-706)**:
```markdown
**EXECUTE NOW - Parse REPORT_PATH from Agent Outputs** (Step 3.5: After Agent Completion):

After research agents complete, extract REPORT_PATH from each agent's response:

[... verification code ...]

**Verification Checklist**:
- [ ] REPORT_CREATED extracted from each agent output
...
```

**New Code (Enforcement Applied)**:
```markdown
**MANDATORY VERIFICATION - Report File Creation** (NON-OPTIONAL - Execute Immediately After Agents Complete)

**ABSOLUTE REQUIREMENT**: This verification step MUST execute after research agents complete. This is NOT optional debugging - it is a MANDATORY checkpoint that guarantees 100% file creation rate.

**WHY THIS MATTERS**: Without this verification, ~20-40% of research runs result in missing report files. This checkpoint + fallback mechanism guarantees ALL reports exist regardless of agent compliance.

**EXECUTE NOW - Parse and Verify Report Paths**:

```bash
# STEP 1: Extract REPORT_CREATED confirmations from agent outputs
declare -A AGENT_REPORT_PATHS

for topic in "${!REPORT_PATHS[@]}"; do
  AGENT_OUTPUT="${RESEARCH_AGENT_OUTPUTS[$topic]}"  # From Task tool results
  EXPECTED_PATH="${REPORT_PATHS[$topic]}"

  echo "Processing topic: $topic"

  # Extract REPORT_CREATED line (format: "REPORT_CREATED: /absolute/path")
  EXTRACTED_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'REPORT_CREATED:\s*\K/.+' | head -1)

  if [ -z "$EXTRACTED_PATH" ]; then
    echo "  ⚠️  Agent did not return REPORT_CREATED confirmation"
  else
    echo "  ✓ Agent reported: $EXTRACTED_PATH"

    # Verify path matches expected
    if [ "$EXTRACTED_PATH" != "$EXPECTED_PATH" ]; then
      echo "  ⚠️  PATH MISMATCH DETECTED"
      echo "    Expected: $EXPECTED_PATH"
      echo "    Agent returned: $EXTRACTED_PATH"
    fi
  fi

  # STEP 2: MANDATORY file existence check
  echo "  Verifying file exists at: $EXPECTED_PATH"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "  ⚠️  FILE NOT FOUND - Triggering fallback mechanism"

    # STEP 3: GUARANTEED fallback creation
    echo "  Creating fallback report from agent output..."

    mkdir -p "$(dirname "$EXPECTED_PATH")"

    cat > "$EXPECTED_PATH" <<EOF
# ${topic} Research Report

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Agent**: research-specialist
- **Creation Method**: Fallback (agent did not create file directly)
- **Topic**: ${topic}

## Agent Output

$AGENT_OUTPUT

## Note

This report was created by the orchestrator's fallback mechanism because the research agent did not create the file directly. The agent output above contains the research findings.

## Recommendations

[Review agent output above for actionable recommendations]

EOF

    echo "  ✓ FALLBACK REPORT CREATED"

    # Verify fallback succeeded
    if [ ! -f "$EXPECTED_PATH" ]; then
      echo "  ❌ CRITICAL ERROR: Fallback creation failed"
      echo "  ❌ File still does not exist: $EXPECTED_PATH"
      exit 1
    fi

    echo "  ✓ VERIFIED: Fallback report exists"
  else
    echo "  ✓ VERIFIED: Report file exists"
  fi

  AGENT_REPORT_PATHS["$topic"]="$EXPECTED_PATH"
done

# STEP 4: Final verification - MUST have all reports
MISSING_COUNT=0
for topic in "${!REPORT_PATHS[@]}"; do
  if [ ! -f "${REPORT_PATHS[$topic]}" ]; then
    echo "❌ CRITICAL: Report missing for topic: $topic"
    ((MISSING_COUNT++))
  fi
done

if [ $MISSING_COUNT -gt 0 ]; then
  echo "❌ VERIFICATION FAILED: $MISSING_COUNT reports missing"
  echo "❌ This should be impossible due to fallback mechanism"
  exit 1
fi

echo "✓ VERIFICATION PASSED: All ${#REPORT_PATHS[@]} reports exist"

# Export for subsequent phases
export RESEARCH_REPORT_PATHS=("${AGENT_REPORT_PATHS[@]}")
```

**MANDATORY VERIFICATION CHECKLIST** (ALL must be ✓ before proceeding):

YOU MUST confirm ALL of these before moving to planning phase:

- [ ] Extracted REPORT_CREATED from each agent output (or noted absence)
- [ ] Checked file existence for EVERY expected report path
- [ ] Fallback report created for ANY missing file
- [ ] Verified fallback file exists (critical safety check)
- [ ] Path mismatch detection logged (if any occurred)
- [ ] Final count verification: ALL reports present
- [ ] NO missing reports (count = 0)
- [ ] Paths exported to RESEARCH_REPORT_PATHS

**CHECKPOINT REQUIREMENT**: Report verification completion:
```
CHECKPOINT: Report verification complete
- Reports expected: ${#REPORT_PATHS[@]}
- Reports verified: ${#AGENT_REPORT_PATHS[@]}
- Fallback creations: [count]
- All reports exist: ✓
- File creation rate: 100%
- Proceeding to: Planning phase
```

**CRITICAL SUCCESS CRITERION**: File creation rate MUST be 100%. If ANY report is missing after fallback, the orchestration MUST NOT proceed.
```

**Changes Made**:
1. Changed heading to "**MANDATORY VERIFICATION**" with "(NON-OPTIONAL)" qualifier
2. Added "**ABSOLUTE REQUIREMENT**" explanation
3. Added "**WHY THIS MATTERS**" with statistics
4. Added step markers (STEP 1, 2, 3, 4) in verification code
5. Added explicit fallback trigger logging
6. Added fallback verification (verifies fallback itself succeeded)
7. Added critical error exit if fallback fails
8. Added final count verification with exit on failure
9. Changed "Verification Checklist" to "**MANDATORY VERIFICATION CHECKLIST**"
10. Added "YOU MUST confirm ALL" language
11. Added "**CHECKPOINT REQUIREMENT**" with file creation rate metric
12. Added "**CRITICAL SUCCESS CRITERION**" (100% or stop)

**Testing**:
1. Simulate agent non-compliance (no file created)
2. Verify fallback triggers automatically
3. Verify 100% file creation rate achieved
4. Verify orchestration stops if fallback fails

**Completion Criteria**:
- Verification marked "MANDATORY" and "NON-OPTIONAL"
- Fallback mechanism explicitly documented as "GUARANTEED"
- Verification checks fallback succeeded
- 100% file creation rate enforced
- Checkpoint reporting added

---

### Task 6: Add Metadata Extraction After Verification

**Objective**: Ensure metadata extraction happens after files are verified to exist.

**Current State**: No explicit metadata extraction step after verification.

**New Code**:

Add this section AFTER the verification checkpoint:

```markdown
---

**EXECUTE NOW - Extract Metadata from Research Reports** (After Verification Complete)

Now that ALL report files are guaranteed to exist (100% verified), extract metadata for context passing to planning phase.

**WHY THIS MATTERS**: Metadata extraction (title + 50-word summary) reduces context by 99% compared to passing full report content. This enables complex workflows to stay under 30% context usage.

**EXECUTE NOW - Metadata Extraction**:

```bash
# Source metadata extraction utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# Extract metadata from each verified report
declare -A REPORT_METADATA

for topic in "${!AGENT_REPORT_PATHS[@]}"; do
  REPORT_PATH="${AGENT_REPORT_PATHS[$topic]}"

  echo "Extracting metadata from: $REPORT_PATH"

  # Extract title, summary, key findings (NOT full content)
  METADATA=$(extract_report_metadata "$REPORT_PATH")

  # Store metadata (lightweight reference, not full content)
  REPORT_METADATA["$topic"]="$METADATA"

  echo "  ✓ Metadata extracted for: $topic"
done

echo "✓ Metadata extracted from ${#REPORT_METADATA[@]} reports"
```

**METADATA STRUCTURE** (What gets passed to planning phase):

For each report, pass ONLY:
- Report path (absolute reference)
- Title (1 line)
- Summary (max 50 words)
- Key findings (3-5 bullet points, ~30 words total)

**DO NOT PASS**: Full report content (this bloats context)

**VERIFICATION**:
- [ ] Metadata extracted from all ${#AGENT_REPORT_PATHS[@]} reports
- [ ] Each metadata block < 100 words
- [ ] Total metadata size < 1000 words (vs ~5000+ for full content)
- [ ] Report paths included (planning phase will read full content if needed)

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Metadata extraction complete
- Reports processed: ${#AGENT_REPORT_PATHS[@]}
- Metadata extracted: ${#REPORT_METADATA[@]}
- Total metadata size: ~[N] words (99% reduction vs full content)
- Context usage: <10% (research phase complete)
- Proceeding to: Planning phase with metadata
```
```

**Changes Made**:
1. Added new section "**EXECUTE NOW - Extract Metadata from Research Reports**"
2. Explained WHY metadata extraction matters (context reduction)
3. Provided specific extraction code using utilities
4. Documented metadata structure (what to pass)
5. Documented what NOT to pass (full content)
6. Added verification checklist for metadata
7. Added checkpoint requirement with context usage metric

**Completion Criteria**:
- Metadata extraction step added after verification
- Code provided for extraction
- Context reduction metrics documented
- Checkpoint reporting added

---

### Task 7: Add Checkpoint Reporting at End of Research Phase

**Objective**: Provide clear progress indicator when research phase completes.

**Current State**: No explicit "research phase complete" checkpoint.

**New Code**:

Add this section as the FINAL step of research phase:

```markdown
---

## Research Phase Complete

**CHECKPOINT REQUIREMENT - Report Research Phase Completion**

Before proceeding to planning phase, YOU MUST report this checkpoint:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Research Phase Complete
═══════════════════════════════════════════════════════

Phase Status: COMPLETE ✓

Research Execution:
- Topics researched: ${#TOPICS[@]}
- Research agents invoked: ${#TOPICS[@]}
- Parallel execution: ✓ (all agents in single message)
- Agent timeout: 5 minutes each
- Total research time: ~[N] minutes

File Creation (Critical Metric):
- Reports expected: ${#REPORT_PATHS[@]}
- Reports created by agents: [N]
- Reports created by fallback: [N]
- Total reports verified: ${#AGENT_REPORT_PATHS[@]}
- File creation rate: 100% ✓

Verification Results:
- Path pre-calculation: ✓ Executed
- Agent template compliance: ✓ Exact template used
- File existence checks: ✓ All passed
- Fallback mechanism: ✓ Triggered [N] times
- Metadata extraction: ✓ Complete

Context Management:
- Full report content: NOT passed to planning
- Metadata extracted: ✓ (titles + summaries only)
- Context usage: <10% (research phase)
- Context reduction: 99% (metadata vs full content)

Artifacts Created:
[List all report paths]

Next Phase: Planning
- Will receive: Report metadata (not full content)
- Will use: /plan command with report references
- Expected: Plan file created in ${#WORKFLOW_TOPIC_DIR}/plans/
═══════════════════════════════════════════════════════
```

**CRITICAL**: This checkpoint is MANDATORY. Do NOT proceed to planning phase without reporting it.

**WHY THIS MATTERS**: Checkpoints provide:
1. Clear progress indicators for user
2. Verification that all critical steps executed
3. Metrics for debugging (file creation rate, context usage)
4. Audit trail for workflow execution

---

**Proceeding to Planning Phase**

After reporting the checkpoint, proceed to planning phase with:
- Report metadata (NOT full content)
- Workflow description
- Topic directory path

The planning phase will read full report content if needed.
```

**Changes Made**:
1. Added "## Research Phase Complete" section
2. Added "**CHECKPOINT REQUIREMENT**" with mandatory reporting
3. Provided complete checkpoint template with all key metrics
4. Included critical success metrics (100% file creation, context usage)
5. Added "**CRITICAL**" note that checkpoint is mandatory
6. Added "**WHY THIS MATTERS**" explanation
7. Added transition section to planning phase

**Completion Criteria**:
- Checkpoint reporting requirement added
- Template provided with all metrics
- Marked as "MANDATORY"
- Transition to planning phase documented

---

### Task 8: Convert Descriptive Language to Imperative "YOU MUST"

**Objective**: Systematically replace all passive/descriptive language with direct imperatives.

**Conversion Patterns**:

| Current (Descriptive) | New (Imperative) |
|----------------------|------------------|
| "First, create or find" | "**EXECUTE NOW** - YOU MUST create" |
| "Calculate absolute paths" | "YOU MUST calculate absolute paths" |
| "For each research agent, include" | "For each research agent, YOU MUST include" |
| "Invoke ALL research agents" | "YOU MUST invoke ALL research agents" |
| "After research agents complete, extract" | "After research agents complete, YOU MUST extract" |
| "This verification step" | "This verification step MUST" |
| "Fallback report created if file missing" | "Fallback report WILL be created (guaranteed)" |
| "Report verification completion" | "YOU MUST report verification completion" |

**Systematic Replacement Process**:

1. Search for passive constructions:
   ```bash
   grep -n "is created\|are invoked\|should be\|will be\|can be" orchestrate.md | grep -A 2 -B 2 "48[0-9]\|49[0-9]\|50[0-9]"
   ```

2. Search for advisory language:
   ```bash
   grep -n "First,\|Then,\|Next,\|After.*complete,\|For each" orchestrate.md | grep -A 2 -B 2 "48[0-9]\|49[0-9]\|50[0-9]"
   ```

3. For each match, apply conversion pattern from table above

**Specific Replacements**:

- Line ~500: "First, create" → "**EXECUTE NOW** - YOU MUST create"
- Line ~507: "This centralizes" → "This WILL centralize (by executing the code above)"
- Line ~513: "Calculate absolute paths" → "YOU MUST calculate absolute paths"
- Line ~536: "For each research agent, include" → "For each research agent, YOU MUST include"
- Line ~569: "Complete Task Tool Invocation Example" → "**THIS EXACT TEMPLATE** (YOU MUST use verbatim)"
- Line ~607: "CRITICAL: Send ALL Task tool invocations" → "**MANDATORY**: YOU MUST send ALL Task tool invocations"
- Line ~638: "After research agents complete, extract" → "After research agents complete, YOU MUST extract"
- Line ~666: "Verify file exists" → "YOU MUST verify file exists"
- Line ~669: "Creating fallback report" → "YOU WILL create fallback report (guaranteed safety net)"
- Line ~699: "Verification Checklist" → "**MANDATORY VERIFICATION CHECKLIST** (ALL must be ✓)"

**Completion Criteria**:
- All passive voice converted to active imperatives
- All advisory language converted to requirements
- All "should/could" converted to "MUST/WILL"
- 0 remaining descriptive phrases in research phase

---

### Task 9: Add Inline Comments Explaining Why Enforcement Matters

**Objective**: Document rationale for enforcement patterns so future maintainers understand WHY each pattern is critical.

**Comment Locations and Content**:

Add these inline comments throughout the research phase:

**1. Before Path Pre-Calculation Block (line ~500)**:
```markdown
<!--
ENFORCEMENT RATIONALE: Path Pre-Calculation

WHY "EXECUTE NOW" instead of "First, create":
- Without "EXECUTE NOW", Claude interprets this as guidance, not requirement
- ~30% of runs skip path calculation when using descriptive language
- Skipping causes agents to create files in wrong locations (or not at all)
- Explicit "EXECUTE NOW" + verification checkpoint = 100% execution rate

BEFORE: "First, create..." (60-70% compliance)
AFTER: "**EXECUTE NOW** - YOU MUST create" (100% compliance)
-->
```

**2. Before Agent Invocation Template (line ~569)**:
```markdown
<!--
ENFORCEMENT RATIONALE: Agent Template Verbatim Usage

WHY "THIS EXACT TEMPLATE" instead of "Example":
- When prompt says "example", Claude paraphrases/simplifies 60-80% of time
- Simplified prompts remove enforcement markers ("ABSOLUTE REQUIREMENT", "STEP 1")
- Without enforcement markers, agents treat file creation as optional
- Result: 20-40% file creation rate with simplified prompts

WHY fallback mechanism isn't enough alone:
- We want agents to succeed (proper structure, metadata, content)
- Fallback creates minimal report from agent output (suboptimal)
- Exact template + fallback = high success + safety net

BEFORE: "Example:" (agents simplify, 20-40% file creation)
AFTER: "**THIS EXACT TEMPLATE (No modifications)**" (60-80% agent compliance + 100% with fallback)
-->
```

**3. Before Verification Block (line ~707)**:
```markdown
<!--
ENFORCEMENT RATIONALE: Mandatory Verification + Fallback

WHY "MANDATORY VERIFICATION" instead of "Verify that":
- Descriptive "verify that" sounds advisory, Claude may skip
- ~20% of runs skip verification when not marked mandatory
- Without verification, missing files go undetected
- Without fallback trigger, 0% success when agent doesn't comply

WHY fallback mechanism is "GUARANTEED":
- Primary path: Agent creates file (60-80% success with exact template)
- Fallback path: Orchestrator creates file from agent output (100% success)
- Combined: 100% file creation rate

BEFORE: "Verify that files were created" (80% execution, 0% fallback)
AFTER: "**MANDATORY VERIFICATION**" + fallback (100% execution, 100% creation)
-->
```

**4. Before Checkpoint Reporting (end of phase)**:
```markdown
<!--
ENFORCEMENT RATIONALE: Checkpoint Reporting

WHY checkpoint reporting is mandatory:
- Provides clear progress indicators (user knows phase complete)
- Documents critical metrics (file creation rate, context usage)
- Creates audit trail (debugging failed workflows)
- Confirms all enforcement patterns executed

Without checkpoints:
- User unsure if phase complete
- No metrics for debugging
- Silent failures possible

BEFORE: No checkpoint (unclear status)
AFTER: Mandatory checkpoint (clear status, metrics, audit trail)
-->
```

**Completion Criteria**:
- 4 inline rationale comments added
- Each comment explains WHY enforcement pattern matters
- Each comment shows before/after compliance rates
- Comments reference specific problems solved

---

### Task 10: Test Research Phase with Simulated Agent Non-Compliance

**Objective**: Verify enforcement patterns guarantee 100% file creation even when agents don't comply.

**Test Scenarios**:

**Test 1: Normal Execution (Agents Comply)**
```bash
# Scenario: All agents follow instructions and create files
# Expected:
# - Path pre-calculation executes
# - Agents use exact template
# - All files created by agents
# - Verification passes
# - 0 fallback creations
# - 100% file creation rate
# - Checkpoint reports success

# Validation:
# - All report files exist
# - File creation rate metric shows 100%
# - Checkpoint shows 0 fallback creations
```

**Test 2: Simulated Non-Compliance (Agents Return Text Only)**
```bash
# Scenario: Simulate agents that return research text but don't create files
# How to simulate:
# - Modify agent behavior to skip Write tool
# - Agent returns "REPORT_CREATED: [path]" but doesn't actually create file
#
# Expected:
# - Path pre-calculation executes
# - Agents invoked with exact template
# - Verification detects missing files
# - Fallback triggers for ALL missing files
# - Fallback creates files from agent output
# - Verification confirms fallback succeeded
# - 100% file creation rate (via fallback)
# - Checkpoint reports [N] fallback creations

# Validation:
# - All report files exist (created by fallback)
# - File creation rate metric shows 100%
# - Checkpoint shows [N] fallback creations
# - Fallback files contain agent output
```

**Test 3: Partial Compliance (Some Agents Comply, Some Don't)**
```bash
# Scenario: 2 agents create files, 1 agent doesn't
# Expected:
# - Path pre-calculation executes
# - All agents use exact template
# - Verification detects 1 missing file
# - Fallback triggers for 1 file only
# - Verification confirms all files exist
# - 100% file creation rate (2 agent + 1 fallback)
# - Checkpoint reports 1 fallback creation

# Validation:
# - All 3 report files exist
# - 2 files have proper structure (agent-created)
# - 1 file has fallback structure
# - File creation rate metric shows 100%
# - Checkpoint shows 1 fallback creation
```

**Test 4: Path Pre-Calculation Verification**
```bash
# Scenario: Verify path pre-calculation executes before agents
# Test method:
# - Add logging before agent invocation
# - Confirm REPORT_PATHS array populated
# - Confirm all paths are absolute

# Expected:
# - REPORT_PATHS array has [N] entries
# - All paths start with /
# - All paths passed to agent prompts
# - Agents receive absolute paths (not relative)

# Validation:
# - Log shows "✓ VERIFIED: All paths are absolute"
# - Log shows "✓ VERIFIED: [N] report paths calculated"
# - Agent prompts contain absolute paths
```

**Test 5: Metadata Extraction**
```bash
# Scenario: Verify metadata extraction reduces context
# Test method:
# - Measure full report content size
# - Measure extracted metadata size
# - Calculate reduction percentage

# Expected:
# - Full report content: ~1000-2000 words per report
# - Extracted metadata: ~80-100 words per report
# - Reduction: ~95-99%
# - Total metadata < 1000 words (vs 3000-6000 for full content)

# Validation:
# - Metadata extracted from all reports
# - Each metadata block < 100 words
# - Context reduction > 90%
# - Planning phase receives metadata only
```

**Test Execution Checklist**:
- [ ] Test 1 (Normal) - 100% file creation via agents
- [ ] Test 2 (Non-compliance) - 100% file creation via fallback
- [ ] Test 3 (Partial) - 100% file creation via mixed
- [ ] Test 4 (Path calc) - Pre-calculation verified
- [ ] Test 5 (Metadata) - Context reduction verified

**Success Criteria**:
- ALL tests achieve 100% file creation rate
- Fallback mechanism triggers when needed
- Verification always executes
- Checkpoint always reports
- No test fails

---

## Validation Checklist

Before marking Phase 1 complete, verify ALL of these:

### Execution Markers
- [ ] "EXECUTE NOW" added to path pre-calculation (line ~500)
- [ ] "THIS EXACT TEMPLATE" added to agent invocation (line ~569)
- [ ] "MANDATORY VERIFICATION" added after agent completion (line ~707)

### Imperative Language
- [ ] All "First, create" changed to "YOU MUST create"
- [ ] All "should" changed to "MUST"
- [ ] All "can be" changed to "WILL be"
- [ ] 0 remaining passive voice in research phase

### Verification Checkpoints
- [ ] Path pre-calculation verification added
- [ ] Agent template verification added
- [ ] File existence verification mandatory
- [ ] Fallback mechanism guaranteed

### Checkpoint Reporting
- [ ] Checkpoint requirement at end of research phase
- [ ] Checkpoint includes file creation rate
- [ ] Checkpoint includes context usage
- [ ] Checkpoint marks transition to planning

### Inline Documentation
- [ ] 4 rationale comments added
- [ ] Each comment explains WHY enforcement matters
- [ ] Each comment shows before/after metrics
- [ ] Comments aid future maintenance

### Testing
- [ ] All 5 test scenarios executed
- [ ] All tests achieve 100% file creation
- [ ] Fallback mechanism tested and working
- [ ] Metadata extraction tested and working

### File Updates
- [ ] .claude/commands/orchestrate.md updated (lines 480-730)
- [ ] All changes follow enforcement patterns from main plan
- [ ] No regressions introduced
- [ ] Backward compatibility maintained

## Success Metrics

**File Creation Rate**:
- Before: 60-80% (varies by agent compliance)
- After: 100% (guaranteed by fallback)
- Improvement: +20-40 percentage points

**Execution Compliance**:
- Path pre-calculation: 100% (vs ~70% before)
- Agent template usage: 100% exact (vs ~40% paraphrased before)
- Verification execution: 100% (vs ~80% before)
- Fallback triggering: 100% when needed (vs never before)

**Context Usage**:
- Full report passing: ~5000 words (before)
- Metadata passing: ~500 words (after)
- Reduction: 90% (enables complex workflows)

**Time Savings**:
- Parallel execution: 60-70% time savings vs sequential
- Maintained with enforcement (no degradation)

## Next Phase

After completing Phase 1 and validating all criteria:
- Proceed to Phase 2: Fix /orchestrate Other Phases
- Apply same enforcement patterns to planning, implementation, documentation phases
- Use Phase 1 as template for enforcement approach

---

**Phase 1 Status**: PENDING
**Last Updated**: 2025-10-19
**Parent Plan**: 001_execution_enforcement_fix.md
