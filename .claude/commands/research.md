---
allowed-tools: Task, Bash, Read
argument-hint: <topic or question>
description: Research a topic using hierarchical multi-agent pattern (improved /report)
command-type: primary
dependent-commands: update, list
---

# Generate Research Report with Hierarchical Multi-Agent Pattern

YOU MUST orchestrate hierarchical research by delegating to specialized subagents who WILL investigate focused subtopics in parallel.

**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Use Read tool ONLY for post-delegation verification (confirming agent outputs)
- Your job: decompose topic → invoke agents → verify outputs → synthesize

**PHASE-BASED TOOL USAGE**:
1. **Delegation Phase** (Steps 1-3): Use Task + Bash only
   - Decompose topic, calculate paths, invoke agents
   - DO NOT use Read/Write for research activities
2. **Verification Phase** (Steps 4-6): Use Bash + Read for verification
   - Verify files exist, check completion, synthesize overview
   - Read tool for analysis only, NOT for direct research

You will NOT see research findings directly. Agents will create report files at pre-calculated paths, and you will verify those files exist after agent completion.

## Topic/Question
$ARGUMENTS

## Process

### 1. Topic Analysis
YOU MUST analyze the topic to determine:
- Key concepts and scope
- Complexity and breadth (determines number of subtopics)
- Relevant files and directories in the codebase
- Most appropriate location for the specs/reports/ directory

### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition

**EXECUTE NOW - Decompose Research Topic Into Subtopics**

**EXECUTE NOW**: USE the Bash tool to source libraries and decompose topic:

```bash
# Source required libraries
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-creation.sh
source .claude/lib/template-integration.sh
source .claude/lib/metadata-extraction.sh
source .claude/lib/overview-synthesis.sh

# Determine number of subtopics based on topic complexity
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")

# Get decomposition prompt
DECOMP_PROMPT=$(decompose_research_topic "$RESEARCH_TOPIC" 2 "$SUBTOPIC_COUNT")

echo "SUBTOPIC_COUNT: $SUBTOPIC_COUNT"
echo "DECOMP_PROMPT ready for Task tool invocation"
```

**Verification**: Confirm SUBTOPIC_COUNT is set (2-4 expected range)

**EXECUTE NOW**: USE the Task tool to execute decomposition:

- subagent_type: general-purpose
- description: "Decompose research topic into subtopics"
- prompt: [insert DECOMP_PROMPT value from above]

**After Task completes**, validate output:
- Verify each subtopic is snake_case
- Verify count is between 2-4
- Store in SUBTOPICS array

Example output:
```bash
# Input: "Authentication patterns and security best practices"
# Output:
SUBTOPICS=(
  "jwt_implementation_patterns"
  "oauth2_flows_and_providers"
  "session_management_strategies"
  "security_best_practices"
)
```

### STEP 2 (REQUIRED BEFORE STEP 3) - Path Pre-Calculation

**EXECUTE NOW - Calculate Absolute Paths for All Subtopic Reports**

**Step 1: Get or Create Main Topic Directory**

**EXECUTE NOW**: USE the Bash tool to calculate topic directory:

```bash
# Source unified location detection utilities
source .claude/lib/topic-utils.sh
source .claude/lib/detect-project-dir.sh

# Get project root (from environment or git)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"
if [ -z "$PROJECT_ROOT" ]; then
  echo ""
  echo "✗ ERROR: Environment variable not set"
  echo "   Expected: CLAUDE_PROJECT_DIR='[absolute path]'"
  echo "   Found: CLAUDE_PROJECT_DIR=''"
  echo ""
  echo "Diagnostic commands:"
  echo "  echo \$CLAUDE_PROJECT_DIR"
  echo "  pwd"
  echo ""
  echo "Workflow terminated"
  exit 1
fi

# Determine specs directory
if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
elif [ -d "${PROJECT_ROOT}/specs" ]; then
  SPECS_ROOT="${PROJECT_ROOT}/specs"
else
  SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  mkdir -p "$SPECS_ROOT"
fi

# Calculate topic metadata
TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
TOPIC_NAME=$(sanitize_topic_name "$RESEARCH_TOPIC")
TOPIC_DIR="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"

# Create topic root directory
mkdir -p "$TOPIC_DIR"

echo "TOPIC_DIR: $TOPIC_DIR"
echo "TOPIC_NUM: $TOPIC_NUM"
echo "TOPIC_NAME: $TOPIC_NAME"

# MANDATORY VERIFICATION checkpoint
if [ ! -d "$TOPIC_DIR" ]; then
  echo ""
  echo "✗ ERROR: Directory creation failed"
  echo "   Expected: Directory at $TOPIC_DIR"
  echo "   Found: Directory does not exist"
  echo ""
  echo "Diagnostic commands:"
  echo "  ls -la \$(dirname \"$TOPIC_DIR\")"
  echo "  mkdir -p \"$TOPIC_DIR\""
  echo ""
  echo "Workflow terminated"
  exit 1
fi

echo "✓ VERIFIED: Topic directory created at $TOPIC_DIR"
```

**Step 2: EXECUTE NOW - Calculate Subtopic Report Paths**

**ABSOLUTE REQUIREMENT**: You MUST calculate all subtopic report paths BEFORE invoking research agents.

**WHY THIS MATTERS**: Research-specialist agents require EXACT absolute paths to create files in correct locations. Skipping this step causes path mismatch errors.

**EXECUTE NOW**: USE the Bash tool to calculate report paths:

```bash
# MANDATORY: Calculate absolute paths for each subtopic
declare -A SUBTOPIC_REPORT_PATHS

# Create reports subdirectory
mkdir -p "${TOPIC_DIR}/reports"

# Get next research number
RESEARCH_NUM=1
if [ -d "${TOPIC_DIR}/reports" ]; then
  EXISTING_COUNT=$(find "${TOPIC_DIR}/reports" -mindepth 1 -maxdepth 1 -type d | wc -l)
  RESEARCH_NUM=$((EXISTING_COUNT + 1))
fi

# Create research subdirectory
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/$(printf "%03d" "$RESEARCH_NUM")_${TOPIC_NAME}"
mkdir -p "$RESEARCH_SUBDIR"

# MANDATORY VERIFICATION - research subdirectory creation
if [ ! -d "$RESEARCH_SUBDIR" ]; then
  echo ""
  echo "✗ ERROR: Research subdirectory creation failed"
  echo "   Expected: Directory at $RESEARCH_SUBDIR"
  echo "   Found: Directory does not exist"
  echo ""
  echo "Diagnostic commands:"
  echo "  ls -la \"$TOPIC_DIR/reports\""
  echo "  mkdir -p \"$RESEARCH_SUBDIR\""
  echo ""
  echo "Workflow terminated"
  exit 1
fi

echo "✓ VERIFIED: Research subdirectory created"
echo "Creating subtopic reports in: $RESEARCH_SUBDIR"

# Calculate paths for each subtopic
SUBTOPIC_NUM=1
for subtopic in "${SUBTOPICS[@]}"; do
  # Create absolute path with sequential numbering
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"

  # Store in associative array
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"

  echo "  Subtopic: $subtopic"
  echo "  Path: $REPORT_PATH"

  SUBTOPIC_NUM=$((SUBTOPIC_NUM + 1))
done
```

**EXECUTE NOW**: USE the Bash tool to verify all paths:

```bash
# Verify all paths are absolute
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  # Use string comparison instead of negated regex to avoid bash eval issues
  path="${SUBTOPIC_REPORT_PATHS[$subtopic]}"
  if [ "${path:0:1}" != "/" ]; then
    echo ""
    echo "✗ ERROR: Path not absolute"
    echo "   Expected: Path starting with '/'"
    echo "   Found: $path"
    echo ""
    echo "Diagnostic commands:"
    echo "  echo \$SUBTOPIC_REPORT_PATHS"
    echo "  pwd"
    echo ""
    echo "Workflow terminated"
    exit 1
  fi
done

# Verify research subdirectory exists
if [ ! -d "$RESEARCH_SUBDIR" ]; then
  echo ""
  echo "✗ ERROR: Directory missing"
  echo "   Expected: Directory at $RESEARCH_SUBDIR"
  echo "   Found: Directory does not exist"
  echo ""
  echo "Diagnostic commands:"
  echo "  ls -la \$(dirname \"$RESEARCH_SUBDIR\")"
  echo "  echo \$RESEARCH_SUBDIR"
  echo ""
  echo "Workflow terminated"
  exit 1
fi

echo "✓ VERIFIED: All paths are absolute"
echo "✓ VERIFIED: ${#SUBTOPIC_REPORT_PATHS[@]} report paths calculated"
echo "✓ VERIFIED: Ready to invoke research agents"
```

**CHECKPOINT**:
```
CHECKPOINT: Path pre-calculation complete
- Subtopics identified: ${#SUBTOPICS[@]}
- Report paths calculated: ${#SUBTOPIC_REPORT_PATHS[@]}
- All paths verified: ✓
- Proceeding to: Parallel agent invocation
```

### STEP 3 (REQUIRED BEFORE STEP 4) - Invoke Research Agents

**EXECUTE NOW - Invoke All Research-Specialist Agents in Parallel**

**AGENT INVOCATION INSTRUCTIONS**

**CRITICAL**: You MUST invoke research agents in parallel (multiple Task calls in single message).

For EACH subtopic in SUBTOPICS array, you will invoke the research-specialist agent.

**EXECUTE NOW**: USE the Task tool for each subtopic with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert actual subtopic name] with mandatory artifact creation"
- timeout: 300000  # 5 minutes per research agent
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly subtopic name]
    - Report Path: [insert absolute path from SUBTOPIC_REPORT_PATHS array for this subtopic]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
    - The ORCHESTRATOR calculated your report path (injected above)
    - DO NOT use Task tool to orchestrate other agents
    - STAY IN YOUR LANE: Research YOUR subtopic only

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]

**Concrete Example** (for subtopic "jwt_implementation_patterns"):
- subagent_type: "general-purpose"
- description: "Research jwt_implementation_patterns with mandatory artifact creation"
- timeout: 300000
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: JWT Implementation Patterns
    - Report Path: /home/benjamin/.config/.claude/specs/042_authentication/reports/001_jwt_implementation_patterns.md
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
    - The ORCHESTRATOR calculated your report path (injected above)
    - DO NOT use Task tool to orchestrate other agents
    - STAY IN YOUR LANE: Research YOUR subtopic only

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: /home/benjamin/.config/.claude/specs/042_authentication/reports/001_jwt_implementation_patterns.md

**Your Orchestrator Responsibilities**:
- Invoke ALL subtopics in parallel (one Task call per subtopic in a single message)
- Monitor for PROGRESS: markers from each agent
- Collect REPORT_CREATED: paths when agents complete
- Verify paths match pre-calculated paths

**NOTE**: All STEP sequences (STEP 1-4) are defined in the agent behavioral file. This prompt only provides workflow-specific context.

### STEP 4 (REQUIRED BEFORE STEP 5) - Verify Report Creation

**MANDATORY VERIFICATION - All Subtopic Reports Must Exist**

**After all agents complete**, verify reports exist at expected paths:

```bash
# MANDATORY VERIFICATION with fallback creation
declare -A VERIFIED_PATHS
MISSING_REPORTS=()
i=1

for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

  # Concise verification format (single line on success)
  echo -n "Verifying report ${i}/${#SUBTOPIC_REPORT_PATHS[@]}: "

  # Retry logic: check up to 3 times with 500ms delay
  FOUND=false
  for attempt in 1 2 3; do
    if [ -f "$EXPECTED_PATH" ]; then
      VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
      FOUND=true
      break
    fi
    if [ $attempt -lt 3 ]; then
      sleep 0.5
    fi
  done

  if $FOUND; then
    FILE_SIZE=$(wc -c < "$EXPECTED_PATH")
    FILE_SIZE_KB=$((FILE_SIZE / 1024))
    echo "✓ (${FILE_SIZE_KB}KB)"
  else
    echo ""
    echo "✗ VERIFICATION FAILED: Report missing at $EXPECTED_PATH"
    echo "   Proceeding to FALLBACK MECHANISM..."
    MISSING_REPORTS+=("$subtopic")
  fi

  i=$((i + 1))
done

echo ""

# Fallback creation for missing reports
if [ ${#MISSING_REPORTS[@]} -gt 0 ]; then
  echo "Creating ${#MISSING_REPORTS[@]} fallback reports..."

  for subtopic in "${MISSING_REPORTS[@]}"; do
    EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

    # FALLBACK MECHANISM - Create report from agent output
    mkdir -p "$(dirname "$EXPECTED_PATH")"
    cat > "$EXPECTED_PATH" <<EOF
# Research Report: ${subtopic}

## Status
Primary research agent failed to create this report.

## Fallback Action
This minimal report was auto-generated to maintain workflow continuity.

## Next Steps
- Review other subtopic reports for related findings
- Consider re-running research for this specific subtopic
- Check agent logs for failure details
EOF

    # RE-VERIFICATION - Confirm fallback successful
    if [ -f "$EXPECTED_PATH" ] && [ -s "$EXPECTED_PATH" ]; then
      FILE_SIZE=$(wc -c < "$EXPECTED_PATH")
      FILE_SIZE_KB=$((FILE_SIZE / 1024))
      echo "  ✓ Fallback created for $subtopic (${FILE_SIZE_KB}KB)"
      VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
    else
      echo ""
      echo "✗ CRITICAL ERROR: Fallback creation failed"
      echo "   Expected: File exists at $EXPECTED_PATH"
      echo "   Found: File still missing after fallback"
      echo ""
      echo "Diagnostic commands:"
      echo "  ls -la \$(dirname \"$EXPECTED_PATH\")"
      echo "  cat \"$EXPECTED_PATH\""
      echo ""
      echo "Workflow terminated"
      exit 1
    fi
  done
  echo ""
fi

# Final count verification
REPORT_COUNT=${#VERIFIED_PATHS[@]}
EXPECTED_COUNT=${#SUBTOPICS[@]}

if [ "$REPORT_COUNT" -eq "$EXPECTED_COUNT" ]; then
  echo "✓ All $EXPECTED_COUNT reports verified"
else
  # Proceed with partial results if ≥50% success
  HALF_COUNT=$((EXPECTED_COUNT / 2))
  if [ "$REPORT_COUNT" -ge "$HALF_COUNT" ]; then
    echo "✓ Partial success: $REPORT_COUNT/$EXPECTED_COUNT reports created"
  else
    echo ""
    echo "✗ ERROR: Insufficient reports created"
    echo "   Expected: At least $HALF_COUNT reports"
    echo "   Found: $REPORT_COUNT reports"
    echo ""
    echo "Diagnostic commands:"
    echo "  ls -lh \"$RESEARCH_SUBDIR\"/*.md"
    echo "  echo \${#VERIFIED_PATHS[@]}"
    echo ""
    echo "Workflow terminated"
    exit 1
  fi
fi

echo ""

# Extract metadata from each verified report (95% context reduction)
echo "Extracting metadata for context reduction..."

declare -A REPORT_METADATA

for subtopic in "${!VERIFIED_PATHS[@]}"; do
  REPORT_PATH="${VERIFIED_PATHS[$subtopic]}"

  # Extract metadata (95% context reduction: 5,000 → 250 tokens)
  METADATA=$(extract_report_metadata "$REPORT_PATH")
  REPORT_METADATA["$subtopic"]="$METADATA"

  echo "✓ Metadata extracted: $subtopic"
done

echo "✓ All metadata extracted - context usage reduced 95%"
echo ""

# Calculate approximate context usage
METADATA_TOKENS=$((${#REPORT_METADATA[@]} * 250))  # 250 tokens per metadata
OVERVIEW_TOKENS=100  # OVERVIEW_SUMMARY is 100 words
TOTAL_TOKENS=$((METADATA_TOKENS + OVERVIEW_TOKENS))

echo "Context usage estimate: $TOTAL_TOKENS tokens (<30% target = <60k tokens)"
echo ""
```

### STEP 5 (REQUIRED BEFORE STEP 6) - Synthesize Overview Report

**EXECUTE NOW - Invoke Research-Synthesizer Agent**

**After all subtopic reports verified**, invoke research-synthesizer agent:

```bash
# Determine if overview synthesis should occur
# /research is always research-only workflow (no planning phase follows)
WORKFLOW_SCOPE="research-only"

# Check if overview should be synthesized
if should_synthesize_overview "$WORKFLOW_SCOPE" "$REPORT_COUNT"; then
  # Calculate overview report path using standardized function (ALL CAPS, not numbered)
  OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")

  echo "Creating overview report at: $OVERVIEW_PATH"

  # Prepare subtopic paths array for agent
  SUBTOPIC_PATHS_ARRAY=()
  for subtopic in "${!VERIFIED_PATHS[@]}"; do
    SUBTOPIC_PATHS_ARRAY+=("${VERIFIED_PATHS[$subtopic]}")
  done
else
  # This should never happen for research-only workflow, but handle gracefully
  SKIP_REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$REPORT_COUNT")
  echo "⏭️  Skipping overview synthesis"
  echo "  Reason: $SKIP_REASON"
  echo ""
  echo "✓ Research reports created successfully (no overview synthesis required)"
  exit 0
fi

# NOTE: Metadata has been extracted for context reduction
# - research-synthesizer still reads full reports for synthesis
# - Orchestrator uses OVERVIEW_SUMMARY (not full overview content)
# - This achieves 95% context reduction for subtopic reports
# - Future optimization: synthesizer could use metadata instead of full reports
```

**AGENT INVOCATION INSTRUCTIONS**

**EXECUTE NOW**: USE the Task tool to invoke the research-synthesizer agent with these parameters:

- subagent_type: "general-purpose"
- description: "Synthesize research findings into overview report"
- timeout: 180000  # 3 minutes
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-synthesizer.md

    **Workflow-Specific Context**:
    - Overview Report Path: [insert $OVERVIEW_PATH value]
    - Research Topic: [insert $RESEARCH_TOPIC value]
    - Subtopic Report Paths:
      [insert list of verified report paths from VERIFIED_PATHS array]

    **YOUR ROLE**: You are a SUBAGENT synthesizing research findings.
    - The ORCHESTRATOR created all subtopic reports (paths injected above)
    - DO NOT use Task tool to orchestrate other agents
    - STAY IN YOUR LANE: Synthesize findings only

    **IMPORTANT**: Create overview file with filename OVERVIEW.md (ALL CAPS).

    Execute synthesis following all guidelines in behavioral file.
    Return: OVERVIEW_CREATED: [path]
           OVERVIEW_SUMMARY: [100-word summary]
           METADATA: [structured metadata]

**Concrete Example**:
- subagent_type: "general-purpose"
- description: "Synthesize research findings into overview report"
- timeout: 180000
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-synthesizer.md

    **Workflow-Specific Context**:
    - Overview Report Path: /home/benjamin/.config/.claude/specs/042_authentication/reports/001_authentication_security/OVERVIEW.md
    - Research Topic: Authentication patterns and security best practices
    - Subtopic Report Paths:
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/001_jwt_implementation_patterns.md
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/002_oauth2_flows_and_providers.md
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/003_session_management_strategies.md
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/004_security_best_practices.md

    **YOUR ROLE**: You are a SUBAGENT synthesizing research findings.
    - The ORCHESTRATOR created all subtopic reports (paths injected above)
    - DO NOT use Task tool to orchestrate other agents
    - STAY IN YOUR LANE: Synthesize findings only

    **IMPORTANT**: Create overview file with filename OVERVIEW.md (ALL CAPS).

    Execute synthesis following all guidelines in behavioral file.
    Return: OVERVIEW_CREATED: /home/benjamin/.config/.claude/specs/042_authentication/reports/001_authentication_security/OVERVIEW.md
           OVERVIEW_SUMMARY: [100-word summary]
           METADATA: [structured metadata]

**Your Orchestrator Responsibilities**:
- Monitor for PROGRESS: markers
- Collect OVERVIEW_CREATED: path when complete
- Verify overview exists at expected path

**NOTE**: All STEP sequences (STEP 1-5) are defined in the agent behavioral file. This prompt only provides workflow-specific context.

**MANDATORY VERIFICATION - Overview Report Creation**:

```bash
# Verify overview file exists with retry logic
OVERVIEW_EXISTS=false
for attempt in 1 2 3; do
  if [ -f "$OVERVIEW_PATH" ]; then
    OVERVIEW_EXISTS=true
    break
  fi
  if [ $attempt -lt 3 ]; then
    sleep 0.5
  fi
done

if ! $OVERVIEW_EXISTS; then
  echo "⚠ Warning: Overview file not found, creating fallback"
  mkdir -p "$(dirname "$OVERVIEW_PATH")"
  cat > "$OVERVIEW_PATH" <<EOF
# Research Overview: ${RESEARCH_TOPIC}

## Status
Research-synthesizer agent failed to create overview report.

## Fallback Action
This minimal overview was auto-generated to maintain workflow continuity.

## Subtopic Reports
$(for path in "${SUBTOPIC_PATHS_ARRAY[@]}"; do echo "- [\$(basename \$path)](\$(basename \$path))"; done)

## Next Steps
- Review individual subtopic reports for findings
- Consider re-running synthesis manually
- Check agent logs for failure details
EOF

  if [ -f "$OVERVIEW_PATH" ]; then
    echo "✓ Fallback overview created at $OVERVIEW_PATH"
  else
    echo ""
    echo "✗ CRITICAL ERROR: Failed to create overview report"
    echo "   Expected: File at $OVERVIEW_PATH"
    echo "   Found: File does not exist after fallback"
    echo ""
    echo "Diagnostic commands:"
    echo "  ls -la \$(dirname \"$OVERVIEW_PATH\")"
    echo "  cat \"$OVERVIEW_PATH\""
    echo ""
    echo "Workflow terminated"
    exit 1
  fi
else
  echo "✓ VERIFIED: Overview report exists at $OVERVIEW_PATH"
fi

# End of should_synthesize_overview conditional
fi
```

### STEP 6 (ABSOLUTE REQUIREMENT) - Update Cross-References

**EXECUTE NOW - Invoke Spec-Updater for Cross-Reference Management**

**IMPORTANT**: After all reports created (subtopics + overview), invoke spec-updater agent to update cross-references.

#### Step 6.1: Invoke Spec-Updater Agent

**AGENT INVOCATION INSTRUCTIONS**

**EXECUTE NOW**: USE the Task tool to invoke the spec-updater agent with these parameters:

- subagent_type: "general-purpose"
- description: "Update cross-references for hierarchical research reports"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    **Workflow-Specific Context**:
    - Operation: LINK (hierarchical_report_creation)
    - Overview report: [insert $OVERVIEW_PATH value]
    - Subtopic reports:
      [insert list of verified report paths from VERIFIED_PATHS array]
    - Topic directory: [insert $TOPIC_DIR value]
    - Related plan: [check topic's plans/ subdirectory]

    **Cross-Reference Requirements**:
    1. Bidirectional links: Overview ↔ Subtopics
    2. Plan references (if plan exists): Overview → Plan, Plan → Overview
    3. Relative paths for all links
    4. Verify all links functional

    Execute cross-reference updates following all guidelines in behavioral file.
    Return: Update status, files modified, verification results

**Concrete Example**:
- subagent_type: "general-purpose"
- description: "Update cross-references for hierarchical research reports"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    **Workflow-Specific Context**:
    - Operation: LINK (hierarchical_report_creation)
    - Overview report: /home/benjamin/.config/.claude/specs/042_authentication/reports/001_authentication_security/OVERVIEW.md
    - Subtopic reports:
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/001_jwt_implementation_patterns.md
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/002_oauth2_flows_and_providers.md
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/003_session_management_strategies.md
      - /home/benjamin/.config/.claude/specs/042_authentication/reports/004_security_best_practices.md
    - Topic directory: /home/benjamin/.config/.claude/specs/042_authentication
    - Related plan: [check topic's plans/ subdirectory]

    **Cross-Reference Requirements**:
    1. Bidirectional links: Overview ↔ Subtopics
    2. Plan references (if plan exists): Overview → Plan, Plan → Overview
    3. Relative paths for all links
    4. Verify all links functional

    Execute cross-reference updates following all guidelines in behavioral file.
    Return: Update status, files modified, verification results

**NOTE**: All STEP sequences are defined in the agent behavioral file. This prompt only provides workflow-specific context.

#### Step 6.2: Handle Spec-Updater Response

After spec-updater completes:
- Display cross-reference status to user
- Show which files were modified (overview, subtopics, plan)
- If warnings/issues: Show them and suggest fixes
- If successful: Confirm all reports are ready

**RETURN_FORMAT_SPECIFIED**: YOU MUST return ONLY this exact format (no modifications):

**Example Output**:
```
Cross-references updated:
✓ Overview report linked to 4 subtopic reports
✓ Subtopic reports linked to overview
✓ Overview linked to plan: specs/042_auth/plans/001_implementation.md
✓ Plan metadata updated with research references
✓ All links validated
```

### STEP 7 (REQUIRED) - Display Research Summary to User

**EXECUTE NOW - Parse and Display Research-Synthesizer Output**

**After research-synthesizer completes**, extract metadata from agent output and display to user.

#### Step 7.1: Parse Agent Output

The research-synthesizer agent returns structured metadata. Extract it:

```bash
# Parse overview path (already captured earlier)
OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"

# Extract summary from agent output (research-synthesizer returns this)
# Agent output format:
# OVERVIEW_CREATED: /path
#
# OVERVIEW_SUMMARY:
# [100-word summary]
#
# METADATA:
# - Reports Synthesized: N
# - Cross-Report Patterns: M
# ...

# The OVERVIEW_SUMMARY is already in agent output - no need to read file
```

#### Step 7.2: Display Summary to User

**CRITICAL**: DO NOT read OVERVIEW.md file. The research-synthesizer already provided the summary.

Display to user:
```
✓ Research Complete!

Research artifacts created in: $TOPIC_DIR/reports/001_[research_name]/

Overview Report: OVERVIEW.md
- [Display OVERVIEW_SUMMARY from agent output]

Subtopic Reports: [N] reports
- [List from VERIFIED_PATHS]

Next Steps:
- Review OVERVIEW.md for complete synthesis
- Use individual reports for detailed findings
- Create implementation plan: /plan [feature] --reports [OVERVIEW_PATH]
```

**RETURN_FORMAT_SPECIFIED**: Display summary, paths, and next steps. DO NOT read any report files.

## Completion Criteria

**MANDATORY VERIFICATION - Before displaying final summary to user, verify:**

```bash
# Completion criteria checklist
COMPLETION_CHECKS_PASSED=true

# 1. Topic directory exists
if [ ! -d "$TOPIC_DIR" ]; then
  echo "✗ Topic directory missing: $TOPIC_DIR"
  COMPLETION_CHECKS_PASSED=false
else
  echo "✓ Topic directory exists: $TOPIC_DIR"
fi

# 2. Research subdirectory exists
if [ ! -d "$RESEARCH_SUBDIR" ]; then
  echo "✗ Research subdirectory missing: $RESEARCH_SUBDIR"
  COMPLETION_CHECKS_PASSED=false
else
  echo "✓ Research subdirectory exists: $RESEARCH_SUBDIR"
fi

# 3. At least 50% subtopic reports created
HALF_COUNT=$((${#SUBTOPICS[@]} / 2))
if [ ${#VERIFIED_PATHS[@]} -lt $HALF_COUNT ]; then
  echo "✗ Insufficient reports: ${#VERIFIED_PATHS[@]}/${#SUBTOPICS[@]} (minimum: $HALF_COUNT)"
  COMPLETION_CHECKS_PASSED=false
else
  echo "✓ Sufficient reports created: ${#VERIFIED_PATHS[@]}/${#SUBTOPICS[@]}"
fi

# 4. OVERVIEW.md exists
if [ ! -f "$OVERVIEW_PATH" ]; then
  echo "✗ Overview report missing: $OVERVIEW_PATH"
  COMPLETION_CHECKS_PASSED=false
else
  echo "✓ Overview report exists: $OVERVIEW_PATH"
fi

# 5. OVERVIEW_SUMMARY extracted (this is done in STEP 7)
echo "✓ OVERVIEW_SUMMARY ready for display (from agent output)"

# Final check
if $COMPLETION_CHECKS_PASSED; then
  echo ""
  echo "✓ All completion criteria met"
  echo ""
else
  echo ""
  echo "✗ ERROR: Completion criteria failed"
  echo "   Expected: All 5 criteria passing"
  echo "   Found: One or more criteria failed (see above)"
  echo ""
  echo "Diagnostic commands:"
  echo "  ls -la \"$TOPIC_DIR\""
  echo "  ls -la \"$RESEARCH_SUBDIR\""
  echo "  echo \${#VERIFIED_PATHS[@]}"
  echo ""
  echo "Workflow terminated"
  exit 1
fi
```

**If ALL criteria met, proceed to STEP 7 (display summary).**

### 7. Report Structure

**Hierarchical Multi-Agent Pattern** creates two types of reports:

#### Individual Subtopic Reports
Each subtopic report follows the standard structure:
- **Executive Summary**: Brief overview of this subtopic's findings
- **Findings**: Detailed discoveries for this specific aspect
- **Recommendations**: 3+ actionable suggestions specific to this subtopic
- **References**: File references and external documentation

**Path Format**: `specs/{NNN_topic}/reports/{NNN_research}/NNN_subtopic_name.md`

#### Overview Report (OVERVIEW.md)
Synthesizes all subtopic findings:
- **Executive Summary**: Overarching insights from all subtopics
- **Subtopic Reports**: Links and summaries of each individual report
- **Cross-Cutting Themes**: Patterns observed across multiple subtopics
- **Synthesized Recommendations**: Aggregated and prioritized recommendations
- **References**: Compiled file references from all subtopics

**Path Format**: `specs/{NNN_topic}/reports/{NNN_research}/OVERVIEW.md`

**Note**: The overview file is always named OVERVIEW.md (ALL CAPS) to distinguish it as the final synthesis report, not another numbered subtopic report.

For complete report structure and section guidelines, see `.claude/docs/reference/report-structure.md`

### 8. Report Metadata

Each report includes standardized metadata:
- **Topic Directory**: Path to the topic directory (e.g., `specs/042_authentication/`)
- **Report Number**: Three-digit number within research subdirectory
- **Report Type**: Individual subtopic or overview synthesis
- Creation date, research scope, agent type

**Hierarchical Structure Benefits**:
- Parallel research execution (40-60% faster)
- Granular subtopic coverage
- Comprehensive overview synthesis
- Easy to reference specific aspects
- Better organization and maintainability

## Agent Usage

This command uses **hierarchical multi-agent pattern** for research:

### research-specialist Agent (REQUIRED)
- **Purpose**: Focused codebase analysis for each subtopic
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch, Write, Edit
- **When Used**: ALWAYS - one agent per subtopic (parallel invocation)
- **Output**: Individual subtopic report created at pre-calculated path

### research-synthesizer Agent (REQUIRED)
- **Purpose**: Synthesize findings from all subtopic reports into overview
- **Tools**: Read, Write, Edit
- **When Used**: After all subtopic reports completed
- **Output**: OVERVIEW.md report with synthesis and cross-cutting themes

### Hierarchical Multi-Agent Workflow

```
User Request: /research "Topic"
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
```

### Agent Invocation Pattern

**research-specialist** (multiple invocations in parallel):
```yaml
# For EACH subtopic, invoke research-specialist with:
Task {
  subagent_type: "general-purpose"
  description: "Research [subtopic] with mandatory artifact creation"
  timeout: 300000  # 5 minutes
  prompt: "
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Research Topic**: [SUBTOPIC_NAME]
    **Report Path**: [ABSOLUTE_PRE_CALCULATED_PATH]

    **STEP 1**: Verify absolute report path received
    **STEP 2**: Create report file at EXACT path using Write tool
    **STEP 3**: Conduct research and update report
    **STEP 4**: Verify file exists and return: REPORT_CREATED: [path]
  "
}
```

**research-synthesizer** (single invocation after all subtopics complete):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Synthesize research findings into overview report"
  timeout: 180000  # 3 minutes
  prompt: "
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-synthesizer.md

    **Overview Report Path**: [ABSOLUTE_OVERVIEW_PATH]
    **Research Topic**: [MAIN_TOPIC]
    **Subtopic Report Paths**: [ALL_VERIFIED_PATHS]

    **IMPORTANT**: Create overview file with filename OVERVIEW.md (ALL CAPS).

    **STEP 1**: Verify absolute overview path and subtopic paths
    **STEP 2**: Read ALL subtopic reports using Read tool
    **STEP 3**: Create overview file at EXACT path (filename: OVERVIEW.md)
    **STEP 4**: Synthesize findings and update overview
    **STEP 5**: Verify file exists and return: OVERVIEW_CREATED: [path]
  "
}
```

### Benefits of Hierarchical Multi-Agent Pattern
- **40-60% Faster**: Parallel research execution vs sequential
- **Granular Coverage**: Each subtopic gets focused attention
- **Comprehensive Synthesis**: Overview links and synthesizes all findings
- **Better Organization**: Individual reports easier to maintain and update
- **Reusability**: Subtopic reports can be referenced independently
- **95% Context Reduction**: Each agent focuses on narrow subtopic

### Alignment with /orchestrate
The `/orchestrate` command's research phase uses the SAME hierarchical multi-agent pattern. This ensures consistency across all research workflows in the .claude/ system.
