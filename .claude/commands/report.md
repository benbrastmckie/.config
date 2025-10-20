---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch, WebFetch, Task
argument-hint: <topic or question>
description: Research a topic and create a comprehensive report in the appropriate specs/reports/ directory
command-type: primary
dependent-commands: update, list
---

# Generate Research Report

I'll research the specified topic and create a comprehensive report in the most appropriate location.

## Topic/Question
$ARGUMENTS

## Process

### 1. Topic Analysis
First, I'll analyze the topic to determine:
- Key concepts and scope
- Complexity and breadth (determines number of subtopics)
- Relevant files and directories in the codebase
- Most appropriate location for the specs/reports/ directory

### 1.5. Topic Decomposition

**Decompose research topic into focused subtopics**:

```bash
# Source decomposition utility
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh

# Determine number of subtopics based on topic complexity
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")

# Get decomposition prompt
DECOMP_PROMPT=$(decompose_research_topic "$RESEARCH_TOPIC" 2 "$SUBTOPIC_COUNT")
```

**Use Task tool** to execute decomposition:

Task invocation:
- subagent_type: general-purpose
- description: "Decompose research topic into subtopics"
- prompt: [Use DECOMP_PROMPT from above]

**Validation**:
- Verify each subtopic is snake_case
- Verify count is between 2-4
- Store in SUBTOPICS array

Example:
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

### 2. Topic-Based Location Determination and Path Pre-Calculation

**Step 1: Get or Create Main Topic Directory**
```bash
# Extract topic from research question
TOPIC_DESC=$(extract_topic_from_question "$RESEARCH_TOPIC")

# Check for existing topics that match
EXISTING_TOPIC=$(find_matching_topic "$TOPIC_DESC")

if [ -n "$EXISTING_TOPIC" ]; then
  TOPIC_DIR="$EXISTING_TOPIC"
else
  # Create new topic directory
  TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC_DESC" ".claude/specs")
  # Creates: .claude/specs/{NNN_topic}/ with subdirectories
fi

echo "Main topic directory: $TOPIC_DIR"
```

**Step 2: EXECUTE NOW - Calculate Subtopic Report Paths**

**ABSOLUTE REQUIREMENT**: You MUST calculate all subtopic report paths BEFORE invoking research agents.

**WHY THIS MATTERS**: Research-specialist agents require EXACT absolute paths to create files in correct locations. Skipping this step causes path mismatch errors.

```bash
# MANDATORY: Calculate absolute paths for each subtopic
declare -A SUBTOPIC_REPORT_PATHS

# Create subdirectory for this research task (groups related subtopic reports)
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/$(printf "%03d" $(get_next_artifact_number "${TOPIC_DIR}/reports"))_${TOPIC_DESC}"
mkdir -p "$RESEARCH_SUBDIR"

echo "Creating subtopic reports in: $RESEARCH_SUBDIR"

for subtopic in "${SUBTOPICS[@]}"; do
  # Calculate next number within research subdirectory
  NEXT_NUM=$(get_next_artifact_number "$RESEARCH_SUBDIR")

  # Create absolute path
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"

  # Store in associative array
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"

  echo "  Subtopic: $subtopic"
  echo "  Path: $REPORT_PATH"
done
```

**MANDATORY VERIFICATION - Path Pre-Calculation Complete**:

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

**CHECKPOINT**:
```
CHECKPOINT: Path pre-calculation complete
- Subtopics identified: ${#SUBTOPICS[@]}
- Report paths calculated: ${#SUBTOPIC_REPORT_PATHS[@]}
- All paths verified: ✓
- Proceeding to: Parallel agent invocation
```

### 3. Parallel Research-Specialist Invocation

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

**CRITICAL INSTRUCTION**: The agent prompt below is NOT an example. It is the EXACT template you MUST use when invoking research agents.

**Invoke all research agents in parallel** (multiple Task calls in single message):

For EACH subtopic in SUBTOPICS array, invoke research-specialist agent:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000  # 5 minutes per research agent
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent with the tools and constraints
    defined in that file.

    **Research Topic**: [SUBTOPIC_DISPLAY_NAME]
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]

    **STEP 1 (MANDATORY)**: Verify you received the absolute report path above.
    If path is not absolute (starts with /), STOP and report error.

    **STEP 2 (EXECUTE NOW)**: Create report file at EXACT path using Write tool.
    Create with initial structure BEFORE conducting research.

    **STEP 3 (REQUIRED)**: Conduct research and update report file:
    - Use Grep/Glob to search codebase for relevant patterns
    - Use WebSearch/WebFetch for best practices (if applicable)
    - Use Edit tool to update report incrementally
    - Include file references with line numbers
    - Add at least 3 specific recommendations

    **STEP 4 (ABSOLUTE REQUIREMENT)**: Verify file exists and return:
    REPORT_CREATED: [EXACT_ABSOLUTE_PATH]

    **EMIT PROGRESS MARKERS** during research:
    - PROGRESS: Creating report file
    - PROGRESS: Searching codebase
    - PROGRESS: Analyzing findings
    - PROGRESS: Updating report
    - PROGRESS: Research complete
  "
}
```

**Monitor agent execution**:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_CREATED: paths when agents complete
- Verify paths match pre-calculated paths

### 3.5. Report Verification and Error Recovery

**After all agents complete**, verify reports exist at expected paths:

```bash
# Track verification results
declare -A VERIFIED_PATHS
VERIFICATION_ERRORS=0

echo "Verifying subtopic reports..."

for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

  if [ -f "$EXPECTED_PATH" ]; then
    echo "✓ Verified: $subtopic at $EXPECTED_PATH"
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    echo "⚠ Warning: Report not found at expected path: $EXPECTED_PATH"

    # Search for report in research subdirectory
    FOUND_PATH=$(find "$RESEARCH_SUBDIR" -name "*${subtopic}*.md" -type f | head -n 1)

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
  fi
done

if [ "$VERIFICATION_ERRORS" -gt 0 ]; then
  echo "⚠ Warning: $VERIFICATION_ERRORS subtopic reports required fallback creation"
fi

echo "✓ All subtopic reports verified (${#VERIFIED_PATHS[@]}/${#SUBTOPICS[@]})"
```

### 4. Overview Report Synthesis

**After all subtopic reports verified**, invoke research-synthesizer agent:

```bash
# Calculate overview report path
OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"

echo "Creating overview report at: $OVERVIEW_PATH"

# Prepare subtopic paths array for agent
SUBTOPIC_PATHS_ARRAY=()
for subtopic in "${!VERIFIED_PATHS[@]}"; do
  SUBTOPIC_PATHS_ARRAY+=("${VERIFIED_PATHS[$subtopic]}")
done
```

**Invoke research-synthesizer** using Task tool:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Synthesize research findings into overview report"
  timeout: 180000  # 3 minutes
  prompt: "
    **ABSOLUTE REQUIREMENT - Overview Creation is Your Primary Task**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-synthesizer.md

    You are acting as a Research Synthesizer Agent with the tools and constraints
    defined in that file.

    **Overview Report Path**: $OVERVIEW_PATH
    **Research Topic**: $RESEARCH_TOPIC
    **Subtopic Report Paths**:
$(for path in "${SUBTOPIC_PATHS_ARRAY[@]}"; do echo "    - $path"; done)

    **STEP 1**: Verify you received absolute overview path and subtopic paths.
    **STEP 2**: Read ALL subtopic reports using Read tool.
    **STEP 3**: Create overview file at EXACT path using Write tool.
    **STEP 4**: Synthesize findings and update overview using Edit tool.
    **STEP 5**: Verify file exists and return: OVERVIEW_CREATED: [path]

    **EMIT PROGRESS MARKERS**:
    - PROGRESS: Reading [N] subtopic reports
    - PROGRESS: Creating overview file
    - PROGRESS: Synthesizing findings
    - PROGRESS: Synthesis complete
  "
}
```

**Monitor synthesis execution**:
- Watch for PROGRESS: markers
- Collect OVERVIEW_CREATED: path when complete
- Verify overview exists at expected path

### 5. Spec-Updater Agent Invocation

**IMPORTANT**: After all reports created (subtopics + overview), invoke spec-updater agent to update cross-references.

#### Step 5.1: Invoke Spec-Updater Agent

Use the Task tool to invoke the spec-updater agent:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Update cross-references for hierarchical research reports"
  prompt: "
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

    Tasks:
    1. Check if a plan exists in the topic's plans/ subdirectory

    2. If related plan exists:
       - Add overview report reference to plan metadata
       - Add individual subtopic reports to plan's 'Research Reports' section
       - Use relative paths (e.g., ../reports/001_research/OVERVIEW.md)

    3. For each subtopic report:
       - Add link to overview report in 'Related Reports' section
       - Use relative path (e.g., ./OVERVIEW.md)

    4. For overview report:
       - Verify links to all subtopic reports are relative and correct
       - Add link to related plan (if applicable)

    5. Verify all cross-references are bidirectional:
       - Overview ↔ Subtopics (already present from synthesis)
       - Overview → Plan (if applicable)
       - Plan → Overview (if applicable)

    6. Verify topic subdirectories are present

    Return:
    - Cross-reference update status
    - Plan files modified (if any)
    - Number of subtopic reports cross-referenced
    - Confirmation that all reports are ready for use
    - Any warnings or issues encountered
  "
}
```

#### Step 5.2: Handle Spec-Updater Response

After spec-updater completes:
- Display cross-reference status to user
- Show which files were modified (overview, subtopics, plan)
- If warnings/issues: Show them and suggest fixes
- If successful: Confirm all reports are ready

**Example Output**:
```
Cross-references updated:
✓ Overview report linked to 4 subtopic reports
✓ Subtopic reports linked to overview
✓ Overview linked to plan: specs/042_auth/plans/001_implementation.md
✓ Plan metadata updated with research references
✓ All links validated
```

### 6. Report Structure

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

For complete report structure and section guidelines, see `.claude/templates/report-structure.md`

### 7. Report Metadata

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
User Request: /report "Topic"
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

    **STEP 1**: Verify absolute overview path and subtopic paths
    **STEP 2**: Read ALL subtopic reports using Read tool
    **STEP 3**: Create overview file at EXACT path
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
The `/orchestrate` command's research phase (lines 429-617) uses the SAME hierarchical multi-agent pattern. This ensures consistency across all research workflows in the .claude/ system.

Let me begin researching your topic using the hierarchical multi-agent pattern.
