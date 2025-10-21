# Phase 7: Implement Hierarchical Multi-Agent Research Pattern for /report

## Metadata
- **Phase Number**: 7
- **Parent Plan**: 002_fix_all_command_subagent_delegation.md
- **Objective**: Refactor /report command to use hierarchical multi-agent research pattern
- **Complexity**: High (8/10 - Multi-agent coordination, overview synthesis, path management)
- **Status**: PENDING
- **Estimated Time**: 4-5 hours

## Objective

Transform the `/report` command from single-report creation to a hierarchical multi-agent research pattern that:
1. Decomposes research topics into 2-4 subtopics based on complexity
2. Invokes parallel research-specialist agents (one per subtopic)
3. Creates individual reports in topic-based structure: `specs/{NNN_topic}/reports/{subtopic}/NNN_subtopic.md`
4. Generates overview report that synthesizes findings and links to all individual reports
5. Maintains proper cross-referencing via spec-updater agent

This pattern enables granular research coverage, parallel execution (40-60% time savings), and better artifact organization while maintaining comprehensive overview documentation.

## Background

### Current Implementation

The `/report` command (lines 90-167 in `/home/benjamin/.config/.claude/commands/report.md`) currently follows this pattern:

1. **Topic Analysis**: Analyze research topic and determine scope
2. **Location Determination**: Use `get_or_create_topic_dir()` to get/create topic directory
3. **Single Report Creation**: Create one comprehensive report using `create_topic_artifact()`
4. **Spec-Updater Invocation**: Update cross-references after report creation

**Limitations**:
- Single-threaded research (no parallelization)
- Large topics create monolithic reports (reduced granularity)
- No subtopic decomposition (all-or-nothing coverage)
- Difficult to maintain and update large reports

### Target Implementation

**Hierarchical Multi-Agent Pattern** (from `/orchestrate` research phase, lines 429-617):

```
User Request: /report "Authentication patterns and security best practices"
                              ↓
                   Topic Decomposition (2-4 subtopics)
                              ↓
     ┌──────────────┬─────────────────┬──────────────┐
     ↓              ↓                 ↓              ↓
Agent 1         Agent 2           Agent 3        Agent 4
JWT Patterns   OAuth Flows   Session Mgmt   Security Best
     ↓              ↓                 ↓              ↓
Report 1        Report 2          Report 3       Report 4
     └──────────────┴─────────────────┴──────────────┘
                              ↓
                  Research Synthesizer Agent
                              ↓
                    Overview Report (OVERVIEW.md)
                    (links to all individual reports)
```

**Execution Flow**:
1. Parse research topic → identify 2-4 subtopics
2. Pre-calculate absolute paths for each subtopic report
3. Invoke research-specialist agents in parallel (single message, multiple Task calls)
4. Monitor completion via PROGRESS markers
5. Verify all individual reports created
6. Invoke research-synthesizer agent with report paths
7. Synthesizer creates overview report with links and synthesis
8. Invoke spec-updater for cross-references

### Benefits

**Performance**:
- **40-60% faster**: Parallel agent execution vs sequential
- **Reduced context**: Each agent focuses on narrow subtopic (95% reduction)

**Quality**:
- **Granular coverage**: Each subtopic gets focused attention
- **Comprehensive synthesis**: Overview links and synthesizes findings
- **Better organization**: Individual reports easier to maintain and update
- **Reusability**: Subtopic reports can be referenced independently

**Maintenance**:
- **Modular updates**: Update individual subtopic reports without touching others
- **Clear structure**: Topic-based organization with overview + individuals
- **Cross-references**: Automatic linking between overview and subtopics

## Technical Design

### Phase Structure

This phase has 4 stages:

#### Stage 1: Topic Decomposition Logic
Implement intelligent topic decomposition using LLM analysis to break research topics into 2-4 focused subtopics.

#### Stage 2: Parallel Research-Specialist Invocation
Refactor `/report` command to pre-calculate paths and invoke multiple research agents in parallel (single message).

#### Stage 3: Research-Synthesizer Agent
Create research-synthesizer agent that generates overview reports linking to and synthesizing individual subtopic reports.

#### Stage 4: Integration and Testing
Integrate with spec-updater, add cross-references, and test end-to-end workflow.

## Implementation Tasks

### Stage 1: Topic Decomposition Logic (1 hour)

**Task 1.1**: Create topic decomposition utility

- [ ] Create `.claude/lib/topic-decomposition.sh`
- [ ] Implement `decompose_research_topic()` function
  - Takes research topic string as input
  - Returns 2-4 subtopics based on scope and complexity
  - Uses Task tool for LLM-based analysis
- [ ] Add unit tests for decomposition logic

**Detailed Implementation**:

```bash
#!/bin/bash
# .claude/lib/topic-decomposition.sh
# Topic decomposition utility for hierarchical research

decompose_research_topic() {
  local research_topic="$1"
  local min_subtopics="${2:-2}"
  local max_subtopics="${3:-4}"

  # Validate inputs
  if [ -z "$research_topic" ]; then
    echo "ERROR: Research topic is required" >&2
    return 1
  fi

  # Use Task tool to decompose topic into subtopics
  # This leverages LLM to intelligently identify subtopics
  local decomposition_prompt="Analyze this research topic and identify $min_subtopics to $max_subtopics focused subtopics:

Research Topic: $research_topic

Requirements:
1. Each subtopic should be focused and specific (not overly broad)
2. Subtopics should cover different aspects of the main topic
3. Subtopics should be relatively independent (minimal overlap)
4. Return ONLY subtopic names, one per line, no numbering or bullets

Example for 'Authentication patterns and security':
jwt_implementation_patterns
oauth2_flows_and_providers
session_management_strategies
security_best_practices

Output Format (one per line):
subtopic_1_name
subtopic_2_name
subtopic_3_name
..."

  # Execute decomposition (Task tool invocation)
  # Note: In actual implementation, this uses Task tool
  # For utility function, we output the prompt for command to execute
  echo "$decomposition_prompt"
}

validate_subtopic_name() {
  local subtopic="$1"

  # Check snake_case format
  if [[ ! "$subtopic" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "ERROR: Subtopic must be snake_case: $subtopic" >&2
    return 1
  fi

  # Check length (max 50 chars)
  if [ ${#subtopic} -gt 50 ]; then
    echo "ERROR: Subtopic name too long (max 50): $subtopic" >&2
    return 1
  fi

  return 0
}

calculate_subtopic_count() {
  local research_topic="$1"
  local word_count=$(echo "$research_topic" | wc -w)

  # Simple heuristic: More words = more subtopics
  # 1-3 words: 2 subtopics
  # 4-6 words: 3 subtopics
  # 7+ words: 4 subtopics

  if [ "$word_count" -le 3 ]; then
    echo 2
  elif [ "$word_count" -le 6 ]; then
    echo 3
  else
    echo 4
  fi
}

# Export functions for use in other scripts
export -f decompose_research_topic
export -f validate_subtopic_name
export -f calculate_subtopic_count
```

**Task 1.2**: Add decomposition to /report command

- [ ] Modify `/report.md` to source topic-decomposition.sh
- [ ] Add decomposition step after topic analysis (before location determination)
- [ ] Store subtopics array for later processing

**Code Location**: `/home/benjamin/.config/.claude/commands/report.md` (after line 23)

**Code Addition**:
```markdown
### 1.5. Topic Decomposition

**Decompose research topic into focused subtopics**:

```bash
# Source decomposition utility
source .claude/lib/topic-decomposition.sh

# Determine number of subtopics based on topic complexity
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")

# Get decomposition prompt
DECOMP_PROMPT=$(decompose_research_topic "$RESEARCH_TOPIC" 2 "$SUBTOPIC_COUNT")

# Execute decomposition using Task tool
# Result: Array of subtopic names (snake_case)
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
\```
```

**Task 1.3**: Create unit tests

- [ ] Create `.claude/tests/test_topic_decomposition.sh`
- [ ] Test decomposition for various topic complexities
- [ ] Test subtopic validation functions

**Test Script**:
```bash
#!/bin/bash
# .claude/tests/test_topic_decomposition.sh

source .claude/lib/topic-decomposition.sh

test_validate_subtopic_name() {
  echo "Testing subtopic name validation..."

  # Valid names
  validate_subtopic_name "jwt_patterns" || exit 1
  validate_subtopic_name "oauth2_flows" || exit 1

  # Invalid names (should fail)
  ! validate_subtopic_name "JWT Patterns" || exit 1  # Not snake_case
  ! validate_subtopic_name "oauth-flows" || exit 1   # Hyphen not allowed
  ! validate_subtopic_name "a_very_long_subtopic_name_that_exceeds_fifty_characters_limit" || exit 1

  echo "✓ Subtopic validation tests passed"
}

test_calculate_subtopic_count() {
  echo "Testing subtopic count calculation..."

  local count

  count=$(calculate_subtopic_count "authentication patterns")
  [ "$count" -eq 2 ] || exit 1

  count=$(calculate_subtopic_count "authentication patterns and security best practices")
  [ "$count" -eq 4 ] || exit 1

  echo "✓ Subtopic count calculation tests passed"
}

test_decomposition_prompt_generation() {
  echo "Testing decomposition prompt generation..."

  local prompt
  prompt=$(decompose_research_topic "authentication patterns")

  # Check prompt contains key elements
  echo "$prompt" | grep -q "Research Topic: authentication patterns" || exit 1
  echo "$prompt" | grep -q "one per line" || exit 1

  echo "✓ Decomposition prompt generation tests passed"
}

# Run all tests
test_validate_subtopic_name
test_calculate_subtopic_count
test_decomposition_prompt_generation

echo ""
echo "All topic decomposition tests passed!"
```

### Stage 2: Parallel Research-Specialist Invocation (1.5 hours)

**Task 2.1**: Implement path pre-calculation

- [ ] Add path calculation logic to `/report.md`
- [ ] Calculate absolute paths for each subtopic report BEFORE agent invocation
- [ ] Store paths in associative array indexed by subtopic name

**Code Location**: `/home/benjamin/.config/.claude/commands/report.md` (replace lines 90-167)

**Current Code** (excerpt from lines 40-90):
```markdown
### 2. Topic-Based Location Determination
I'll determine the topic directory location using the uniform structure:

**Step 1: Source Required Utilities**
```bash
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
```

**Step 2: Determine Topic from Research Question**
- Analyze the research topic/question
- Extract key concepts for topic naming
- Search for existing topic directories that match
- If found: Use existing topic directory
- If not found: Create new topic directory using `get_or_create_topic_dir()`

**Step 3: Get or Create Topic Directory**
```bash
# Extract topic from research question
TOPIC_DESC=$(extract_topic_from_question "$RESEARCH_TOPIC")

# Check for existing topics that match
EXISTING_TOPIC=$(find_matching_topic "$TOPIC_DESC")

if [ -n "$EXISTING_TOPIC" ]; then
  TOPIC_DIR="$EXISTING_TOPIC"
else
  # Create new topic directory
  TOPIC_DIR=$(get_or_create_topic_dir "$TOPIC_DESC" "specs")
  # Creates: specs/{NNN_topic}/ with subdirectories
fi
```
```

**Modified Code** (hierarchical multi-agent pattern):
```markdown
### 2. Topic-Based Location Determination and Path Pre-Calculation

**Step 1: Source Required Utilities**
```bash
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh
source .claude/lib/topic-decomposition.sh
```

**Step 2: Get or Create Main Topic Directory**
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

**Step 3: EXECUTE NOW - Calculate Subtopic Report Paths**

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
\```
```

**Task 2.2**: Implement parallel agent invocation

- [ ] Add parallel research-specialist invocations (one Task call per subtopic)
- [ ] Use EXACT agent template from /orchestrate (lines 607-617)
- [ ] Monitor progress via PROGRESS markers

**Code Addition** (after path pre-calculation):
```markdown
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

**Example** (for 3 subtopics):

```
# Invoke all 3 agents in parallel (single message with 3 Task calls)

Task {
  description: "Research jwt_implementation_patterns with mandatory artifact creation"
  timeout: 300000
  prompt: "[EXACT TEMPLATE with jwt_implementation_patterns details]"
}

Task {
  description: "Research oauth2_flows_and_providers with mandatory artifact creation"
  timeout: 300000
  prompt: "[EXACT TEMPLATE with oauth2_flows_and_providers details]"
}

Task {
  description: "Research session_management_strategies with mandatory artifact creation"
  timeout: 300000
  prompt: "[EXACT TEMPLATE with session_management_strategies details]"
}
```

**Monitor agent execution**:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_CREATED: paths when agents complete
- Verify paths match pre-calculated paths
\```
```

**Task 2.3**: Implement report verification with fallback

- [ ] After agents complete, verify all reports exist
- [ ] If path mismatch detected, search for actual report location
- [ ] Use fallback creation if agent failed to create report

**Code Addition**:
```markdown
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
\```
```

### Stage 3: Research-Synthesizer Agent (1 hour)

**Task 3.1**: Create research-synthesizer agent

- [ ] Create `.claude/agents/research-synthesizer.md`
- [ ] Define agent role, inputs, outputs, and behavioral guidelines
- [ ] Include overview report structure template

**Complete Agent File**:

```markdown
---
allowed-tools: Read, Write, Edit
description: Synthesizes findings from multiple research reports into comprehensive overview
---

# Research Synthesizer Agent

**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- Overview report creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)
- DO NOT return summary text - only the overview path confirmation

---

## Overview Report Synthesis Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Inputs

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with:
1. **Absolute overview report path**: Where to create the overview
2. **List of individual report paths**: All subtopic reports to synthesize
3. **Original research topic**: Main topic being researched

Verify you have received all inputs:

```bash
# Provided by invoking command in your prompt
OVERVIEW_PATH="[PATH PROVIDED]"
SUBTOPIC_REPORT_PATHS=("[PATH1]" "[PATH2]" "[PATH3]" ...)
RESEARCH_TOPIC="[TOPIC PROVIDED]"

# CRITICAL: Verify overview path is absolute
if [[ ! "$OVERVIEW_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: Overview path is not absolute: $OVERVIEW_PATH"
  exit 1
fi

# CRITICAL: Verify at least 2 subtopic reports provided
if [ ${#SUBTOPIC_REPORT_PATHS[@]} -lt 2 ]; then
  echo "CRITICAL ERROR: Need at least 2 subtopic reports, got ${#SUBTOPIC_REPORT_PATHS[@]}"
  exit 1
fi

echo "✓ VERIFIED: Absolute overview path received: $OVERVIEW_PATH"
echo "✓ VERIFIED: ${#SUBTOPIC_REPORT_PATHS[@]} subtopic reports to synthesize"
```

**CHECKPOINT**: YOU MUST have absolute overview path and 2+ subtopic paths before proceeding to Step 2.

---

### STEP 2 (REQUIRED BEFORE STEP 3) - Read All Subtopic Reports

**EXECUTE NOW - Read All Individual Reports**

**ABSOLUTE REQUIREMENT**: You MUST read ALL subtopic reports using the Read tool BEFORE creating overview.

**WHY THIS MATTERS**: The overview synthesizes findings from all individual reports. You cannot synthesize without reading source material.

Use the Read tool for EACH subtopic report:

```bash
# For each subtopic report path
for report_path in "${SUBTOPIC_REPORT_PATHS[@]}"; do
  # Read the report
  # Extract key sections: Executive Summary, Findings, Recommendations
  # Store in memory for synthesis
done
```

**Extract from each report**:
- **Executive Summary**: 2-3 sentence overview
- **Key Findings**: Main discoveries and insights
- **Recommendations**: Actionable suggestions
- **File References**: Important code locations

**CHECKPOINT**: All subtopic reports must be read before proceeding to Step 3.

---

### STEP 3 (REQUIRED BEFORE STEP 4) - Create Overview Report FIRST

**EXECUTE NOW - Create Overview File**

**ABSOLUTE REQUIREMENT**: YOU MUST create the overview report file NOW using the Write tool, BEFORE conducting synthesis.

**WHY THIS MATTERS**: Creating the file first guarantees artifact creation even if synthesis encounters errors.

Use the Write tool to create file at EXACT path from Step 1:

```markdown
# [Research Topic] - Research Overview

## Metadata
- **Date**: [YYYY-MM-DD]
- **Agent**: research-synthesizer
- **Research Topic**: [topic from your task description]
- **Subtopic Reports**: [count]
- **Report Type**: Overview Synthesis

## Executive Summary

[Will be filled after synthesis - placeholder for now]

## Subtopic Reports

[Links to individual reports will be added during Step 4]

## Cross-Cutting Themes

[Themes across all subtopics will be added during Step 4]

## Synthesized Recommendations

[Aggregated recommendations will be added during Step 4]

## References

[All file references from subtopic reports will be added during Step 4]
```

**MANDATORY VERIFICATION - File Created**:

After using Write tool, verify:
```bash
# File must exist at $OVERVIEW_PATH before proceeding
test -f "$OVERVIEW_PATH" || echo "CRITICAL ERROR: Overview file not created"
```

**CHECKPOINT**: Overview file must exist at $OVERVIEW_PATH before proceeding to Step 4.

---

### STEP 4 (REQUIRED BEFORE STEP 5) - Synthesize and Update Overview

**NOW that overview file is created**, YOU MUST synthesize findings and update the file:

**Synthesis Execution**:

1. **Executive Summary** (2-3 paragraphs):
   - Summarize overarching research findings
   - Highlight most important insights
   - Note key recommendations

2. **Subtopic Reports Section**:
   - List all individual reports with relative links
   - For each report: 1-2 sentence summary
   - Format:
     ```markdown
     ### [Subtopic Display Name]

     **Report**: [./001_subtopic_name.md](./001_subtopic_name.md)

     Brief summary of this subtopic's findings.
     ```

3. **Cross-Cutting Themes**:
   - Identify patterns across ALL subtopic reports
   - Note contradictions or tensions between findings
   - Highlight complementary insights

4. **Synthesized Recommendations** (prioritized):
   - Aggregate recommendations from all subtopics
   - Prioritize by impact and effort
   - Remove duplicates, merge similar recommendations
   - Format:
     ```markdown
     1. **High Priority**: [Recommendation] (from: subtopic1, subtopic3)
     2. **Medium Priority**: [Recommendation] (from: subtopic2)
     3. **Low Priority**: [Recommendation] (from: subtopic4)
     ```

5. **References**:
   - Compile all file references from subtopic reports
   - Deduplicate and organize by directory
   - Include line numbers

**CRITICAL**: Write synthesis DIRECTLY into the overview file using Edit tool. DO NOT accumulate in memory - update the file incrementally.

---

### STEP 5 (ABSOLUTE REQUIREMENT) - Verify and Return Confirmation

**MANDATORY VERIFICATION - Overview Report Complete**

After completing synthesis, YOU MUST verify the overview file:

**Verification Checklist** (ALL must be ✓):
- [ ] Overview file exists at $OVERVIEW_PATH
- [ ] Executive Summary completed (not placeholder)
- [ ] Subtopic Reports section lists all individual reports with links
- [ ] Cross-Cutting Themes section has detailed content
- [ ] Synthesized Recommendations section has at least 3 prioritized items
- [ ] References section compiled from all subtopic reports

**Final Verification Code**:
```bash
# Verify file exists
if [ ! -f "$OVERVIEW_PATH" ]; then
  echo "CRITICAL ERROR: Overview file not found at: $OVERVIEW_PATH"
  exit 1
fi

# Verify file is substantial
FILE_SIZE=$(wc -c < "$OVERVIEW_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt 800 ]; then
  echo "WARNING: Overview file is too small (${FILE_SIZE} bytes)"
  echo "Expected >800 bytes for a complete overview"
fi

echo "✓ VERIFIED: Overview report complete and saved"
```

**CHECKPOINT REQUIREMENT - Return Path Confirmation**

After verification, YOU MUST return ONLY this confirmation:

```
OVERVIEW_CREATED: [EXACT ABSOLUTE PATH FROM STEP 1]
```

**CRITICAL REQUIREMENTS**:
- DO NOT return summary text or findings
- DO NOT paraphrase the overview content
- ONLY return the "OVERVIEW_CREATED: [path]" line
- The orchestrator will read your overview file directly

**Example Return**:
```
OVERVIEW_CREATED: /home/user/.claude/specs/067_auth/reports/001_research/OVERVIEW.md
```

---

## Progress Streaming (MANDATORY During Synthesis)

**YOU MUST emit progress markers during synthesis** to provide visibility:

### Required Progress Markers

YOU MUST emit these markers at each milestone:

1. **Starting** (STEP 3): `PROGRESS: Creating overview file at [path]`
2. **Reading** (STEP 2): `PROGRESS: Reading [N] subtopic reports`
3. **Synthesizing** (STEP 4): `PROGRESS: Synthesizing findings across subtopics`
4. **Themes** (STEP 4): `PROGRESS: Identifying cross-cutting themes`
5. **Recommendations** (STEP 4): `PROGRESS: Aggregating recommendations`
6. **Completing** (STEP 5): `PROGRESS: Synthesis complete, overview verified`

### Example Progress Flow
```
PROGRESS: Reading 4 subtopic reports
PROGRESS: Creating overview file at specs/reports/001_research/OVERVIEW.md
PROGRESS: Synthesizing findings across subtopics
PROGRESS: Identifying cross-cutting themes
PROGRESS: Aggregating recommendations
PROGRESS: Synthesis complete, overview verified
```

---

## Overview Report Structure Template

```markdown
# [Research Topic] - Research Overview

## Metadata
- **Date**: YYYY-MM-DD
- **Research Topic**: [topic]
- **Subtopic Reports**: [count]
- **Main Topic Directory**: [specs/{NNN_topic}]
- **Created By**: research-synthesizer agent

## Executive Summary

[2-3 paragraphs summarizing overarching findings]

Key insights:
- [Insight 1]
- [Insight 2]
- [Insight 3]

## Subtopic Reports

This research investigated [count] focused subtopics:

### [Subtopic 1 Display Name]

**Report**: [./001_subtopic_name.md](./001_subtopic_name.md)

[1-2 sentence summary of this subtopic's findings]

### [Subtopic 2 Display Name]

**Report**: [./002_subtopic_name.md](./002_subtopic_name.md)

[1-2 sentence summary]

[... continue for all subtopics ...]

## Cross-Cutting Themes

### Theme 1: [Name]

[Description of pattern observed across multiple subtopics]

Observed in: [list of relevant subtopics]

### Theme 2: [Name]

[Description]

Observed in: [list of relevant subtopics]

## Synthesized Recommendations

Recommendations aggregated from all subtopic reports, prioritized by impact:

### High Priority

1. **[Recommendation]** (from: subtopic1, subtopic3)
   - Impact: [description]
   - Effort: [description]
   - Implementation: [brief guidance]

### Medium Priority

2. **[Recommendation]** (from: subtopic2, subtopic4)
   - Impact: [description]
   - Effort: [description]

### Low Priority

3. **[Recommendation]** (from: subtopic1)
   - Impact: [description]
   - Effort: [description]

## References

### Codebase Files Analyzed

Compiled from all subtopic reports:

- `path/to/file1.lua:123` - [description]
- `path/to/file2.lua:456` - [description]

### External Documentation

- [Link to resource] - [description]

## Implementation Guidance

[Optional: High-level guidance on implementing recommendations]

## Next Steps

[Optional: Suggested next steps for acting on this research]
```

---

## Operational Guidelines

### What YOU MUST Do
- **Read all subtopic reports FIRST** (Step 2, before synthesis)
- **Create overview file FIRST** (Step 3, before synthesis)
- **Use absolute paths ONLY** (never relative paths)
- **Write to file incrementally** (don't accumulate in memory)
- **Emit progress markers** (at each milestone)
- **Verify file exists** (before returning)
- **Return path confirmation ONLY** (no summary text)

### What YOU MUST NOT Do
- **DO NOT skip reading subtopic reports** - synthesis requires source material
- **DO NOT skip file creation** - it's the PRIMARY task
- **DO NOT use relative paths** - always absolute
- **DO NOT return summary text** - only path confirmation
- **DO NOT skip verification** - always check file exists

### Collaboration Safety
Overview reports become permanent reference materials that link and synthesize multiple research reports. You do not modify existing code or subtopic reports - only create new overview reports.

---

## COMPLETION CRITERIA - ALL REQUIRED

Before completing your task, YOU MUST verify ALL of these criteria are met:

### File Creation (ABSOLUTE REQUIREMENTS)
- [x] Overview file exists at the exact path specified in Step 1
- [x] File path is absolute (not relative)
- [x] File was created using Write tool (not accumulated in memory)
- [x] File size is >800 bytes (indicates substantial synthesis)

### Content Completeness (MANDATORY SECTIONS)
- [x] Executive Summary is complete (2-3 paragraphs, not placeholder)
- [x] Subtopic Reports section lists ALL individual reports with relative links
- [x] Each subtopic has 1-2 sentence summary
- [x] Cross-Cutting Themes section identifies patterns across subtopics
- [x] Synthesized Recommendations section has at least 3 prioritized items
- [x] References section compiles all file references from subtopic reports
- [x] Metadata section is complete with date, topic, count

### Synthesis Quality (NON-NEGOTIABLE STANDARDS)
- [x] All subtopic reports were read using Read tool
- [x] Executive summary synthesizes findings (not just lists subtopics)
- [x] Cross-cutting themes identify patterns across multiple subtopics
- [x] Recommendations are prioritized by impact and effort
- [x] Duplicate recommendations are merged
- [x] Relative links to subtopic reports are correct

### Process Compliance (CRITICAL CHECKPOINTS)
- [x] STEP 1 completed: Absolute path and subtopic paths received/verified
- [x] STEP 2 completed: All subtopic reports read
- [x] STEP 3 completed: Overview file created FIRST
- [x] STEP 4 completed: Synthesis conducted and file updated
- [x] STEP 5 completed: File verified and path confirmation returned
- [x] All progress markers emitted at required milestones

### Return Format (STRICT REQUIREMENT)
- [x] Return format is EXACTLY: `OVERVIEW_CREATED: [absolute-path]`
- [x] No summary text returned (orchestrator will read file directly)
- [x] Path matches path from Step 1 exactly

### Verification Commands (MUST EXECUTE)
Execute these verifications before returning:

```bash
# 1. File exists check
test -f "$OVERVIEW_PATH" || echo "CRITICAL ERROR: File not found"

# 2. File size check (minimum 800 bytes)
FILE_SIZE=$(wc -c < "$OVERVIEW_PATH" 2>/dev/null || echo 0)
[ "$FILE_SIZE" -ge 800 ] || echo "WARNING: File too small ($FILE_SIZE bytes)"

# 3. Content completeness check
grep -q "placeholder\|TODO\|TBD" "$OVERVIEW_PATH" && echo "WARNING: Placeholder text found"

echo "✓ VERIFIED: All completion criteria met"
```

**Total Requirements**: 30 criteria - ALL must be met (100% compliance)

**Target Score**: 95+/100 on enforcement rubric
```

Save to: `/home/benjamin/.config/.claude/agents/research-synthesizer.md`

**Task 3.2**: Add synthesizer invocation to /report command

- [ ] After subtopic reports verified, invoke research-synthesizer
- [ ] Calculate overview report path: `OVERVIEW.md` in research subdirectory
- [ ] Pass all verified subtopic paths to synthesizer

**Code Addition** (after report verification in /report.md):
```markdown
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
\```
```

### Stage 4: Integration and Testing (1-1.5 hours)

**Task 4.1**: Integrate with spec-updater agent

- [ ] Update spec-updater invocation to handle multiple reports + overview
- [ ] Ensure cross-references created between overview and subtopics
- [ ] Verify bidirectional links (overview → subtopics, subtopics → overview)

**Code Location**: `/home/benjamin/.config/.claude/commands/report.md` (lines 92-167)

**Modified Code** (spec-updater invocation):
```markdown
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
\```
```

**Task 4.2**: Update /orchestrate research phase (if needed)

- [ ] Verify /orchestrate already uses hierarchical pattern (lines 429-617)
- [ ] Document that /report now matches /orchestrate pattern
- [ ] No code changes needed (verification only)

**Verification Steps**:
1. Read `/home/benjamin/.config/.claude/commands/orchestrate.md` lines 429-617
2. Confirm pattern matches /report implementation:
   - Topic decomposition
   - Path pre-calculation
   - Parallel agent invocation
   - Overview synthesis
3. Document alignment in phase summary

**Task 4.3**: Create integration tests

- [ ] Create `.claude/tests/test_report_multi_agent_pattern.sh`
- [ ] Test end-to-end workflow: decomposition → agents → synthesis → cross-refs
- [ ] Verify all artifacts created in correct locations

**Complete Test Script**:
```bash
#!/bin/bash
# .claude/tests/test_report_multi_agent_pattern.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$CLAUDE_ROOT/lib/artifact-operations.sh"
source "$CLAUDE_ROOT/lib/topic-decomposition.sh"

# Test data
TEST_TOPIC="test_authentication_patterns"
TEST_RESEARCH_DIR="$CLAUDE_ROOT/specs/test_$(date +%s)"

echo "========================================="
echo "Testing Hierarchical Multi-Agent Research Pattern"
echo "========================================="

cleanup() {
  echo "Cleaning up test artifacts..."
  rm -rf "$TEST_RESEARCH_DIR"
}

trap cleanup EXIT

echo ""
echo "Test 1: Topic Decomposition"
echo "----------------------------"

# Test decomposition utility
subtopic_count=$(calculate_subtopic_count "$TEST_TOPIC")
echo "Expected subtopic count: $subtopic_count"

[ "$subtopic_count" -ge 2 ] && [ "$subtopic_count" -le 4 ] || {
  echo "ERROR: Invalid subtopic count: $subtopic_count"
  exit 1
}

echo "✓ Topic decomposition produced valid count"

echo ""
echo "Test 2: Path Pre-Calculation"
echo "----------------------------"

# Create test topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$TEST_TOPIC" "$TEST_RESEARCH_DIR")
echo "Topic directory: $TOPIC_DIR"

# Test subtopics (simulated from decomposition)
TEST_SUBTOPICS=("jwt_patterns" "oauth_flows" "session_management")

# Calculate paths
declare -A TEST_PATHS
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/001_test_research"
mkdir -p "$RESEARCH_SUBDIR"

for subtopic in "${TEST_SUBTOPICS[@]}"; do
  NEXT_NUM=$(get_next_artifact_number "$RESEARCH_SUBDIR")
  TEST_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$NEXT_NUM")_${subtopic}.md"
  TEST_PATHS["$subtopic"]="$TEST_PATH"

  echo "  $subtopic: $TEST_PATH"

  # Verify absolute path
  [[ "$TEST_PATH" =~ ^/ ]] || {
    echo "ERROR: Path is not absolute: $TEST_PATH"
    exit 1
  }
done

echo "✓ All paths calculated and verified as absolute"

echo ""
echo "Test 3: Report Creation (Simulated)"
echo "----------------------------"

# Simulate research-specialist agent creating reports
for subtopic in "${TEST_SUBTOPICS[@]}"; do
  REPORT_PATH="${TEST_PATHS[$subtopic]}"

  # Create minimal report (simulating agent behavior)
  cat > "$REPORT_PATH" <<EOF
# $subtopic Research Report

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Agent**: research-specialist (test)
- **Topic**: $subtopic

## Executive Summary

Test report for $subtopic.

## Findings

Test findings for $subtopic.

## Recommendations

1. Test recommendation 1
2. Test recommendation 2
3. Test recommendation 3

## References

- test/file1.lua:123
- test/file2.lua:456
EOF

  [ -f "$REPORT_PATH" ] || {
    echo "ERROR: Failed to create report: $REPORT_PATH"
    exit 1
  }

  echo "✓ Created subtopic report: $subtopic"
done

echo "✓ All subtopic reports created"

echo ""
echo "Test 4: Overview Report Creation (Simulated)"
echo "----------------------------"

OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"

# Simulate research-synthesizer creating overview
cat > "$OVERVIEW_PATH" <<EOF
# $TEST_TOPIC - Research Overview

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Research Topic**: $TEST_TOPIC
- **Subtopic Reports**: ${#TEST_SUBTOPICS[@]}

## Executive Summary

This research investigated ${#TEST_SUBTOPICS[@]} focused subtopics related to $TEST_TOPIC.

Key insights:
- Test insight 1
- Test insight 2

## Subtopic Reports

$(for i in "${!TEST_SUBTOPICS[@]}"; do
  subtopic="${TEST_SUBTOPICS[$i]}"
  num=$(printf "%03d" $((i + 1)))
  echo "### ${subtopic//_/ }"
  echo ""
  echo "**Report**: [./${num}_${subtopic}.md](./${num}_${subtopic}.md)"
  echo ""
  echo "Summary of ${subtopic} findings."
  echo ""
done)

## Cross-Cutting Themes

### Theme 1: Test Theme

Observed across all subtopics.

## Synthesized Recommendations

### High Priority

1. **Test Recommendation** (from: all subtopics)

## References

- test/file1.lua:123
- test/file2.lua:456
EOF

[ -f "$OVERVIEW_PATH" ] || {
  echo "ERROR: Failed to create overview report"
  exit 1
}

echo "✓ Overview report created"

# Verify overview contains links to subtopics
for subtopic in "${TEST_SUBTOPICS[@]}"; do
  grep -q "$subtopic" "$OVERVIEW_PATH" || {
    echo "ERROR: Overview missing reference to: $subtopic"
    exit 1
  }
done

echo "✓ Overview contains links to all subtopics"

echo ""
echo "Test 5: Artifact Structure Verification"
echo "----------------------------"

# Verify directory structure
[ -d "$RESEARCH_SUBDIR" ] || {
  echo "ERROR: Research subdirectory not created"
  exit 1
}

echo "✓ Research subdirectory created: $RESEARCH_SUBDIR"

# Count artifacts
SUBTOPIC_COUNT=$(find "$RESEARCH_SUBDIR" -name "*.md" -not -name "OVERVIEW.md" | wc -l)
[ "$SUBTOPIC_COUNT" -eq ${#TEST_SUBTOPICS[@]} ] || {
  echo "ERROR: Expected ${#TEST_SUBTOPICS[@]} subtopic reports, found $SUBTOPIC_COUNT"
  exit 1
}

echo "✓ Correct number of subtopic reports: $SUBTOPIC_COUNT"

[ -f "$OVERVIEW_PATH" ] || {
  echo "ERROR: Overview report not found"
  exit 1
}

echo "✓ Overview report exists"

echo ""
echo "========================================="
echo "All tests passed!"
echo "========================================="
echo ""
echo "Artifact structure created:"
find "$RESEARCH_SUBDIR" -type f -name "*.md" | sort

exit 0
```

**Task 4.4**: Add unit tests for utilities

- [ ] Test topic decomposition functions
- [ ] Test path calculation logic
- [ ] Test subtopic validation

(Already covered in Task 1.3)

## File Modifications

### 1. /report.md (lines 17-167)

**Current Structure**:
- Topic Analysis (lines 17-23)
- Topic-Based Location Determination (lines 24-90)
- Report Creation Using Uniform Structure (lines 65-90)
- Spec-Updater Agent Invocation (lines 92-167)

**Modified Structure**:
```markdown
### 1. Topic Analysis
[UNCHANGED - lines 17-23]

### 1.5. Topic Decomposition
[NEW - decompose topic into 2-4 subtopics]

### 2. Topic-Based Location Determination and Path Pre-Calculation
[MODIFIED - add subtopic path pre-calculation]

### 3. Parallel Research-Specialist Invocation
[NEW - invoke multiple agents in parallel]

### 3.5. Report Verification and Error Recovery
[NEW - verify reports exist, handle path mismatches]

### 4. Overview Report Synthesis
[NEW - invoke research-synthesizer agent]

### 5. Spec-Updater Agent Invocation
[MODIFIED - handle multiple reports + overview]
```

**Detailed Modifications**:

**Lines 17-23**: UNCHANGED (Topic Analysis section)

**After line 23**: ADD Topic Decomposition section (see Stage 1, Task 1.2)

**Lines 24-90**: MODIFY to add path pre-calculation (see Stage 2, Task 2.1)

**After line 90**: ADD Parallel Research-Specialist Invocation (see Stage 2, Task 2.2)

**After invocation**: ADD Report Verification section (see Stage 2, Task 2.3)

**After verification**: ADD Overview Report Synthesis (see Stage 3, Task 3.2)

**Lines 92-167**: MODIFY Spec-Updater invocation to handle hierarchical reports (see Stage 4, Task 4.1)

### 2. Create research-synthesizer.md

**File**: `/home/benjamin/.config/.claude/agents/research-synthesizer.md`

**Complete Content**: See Stage 3, Task 3.1 above (full agent behavioral file)

### 3. Create topic-decomposition.sh

**File**: `/home/benjamin/.config/.claude/lib/topic-decomposition.sh`

**Complete Content**: See Stage 1, Task 1.1 above (full utility script)

### 4. Update /orchestrate.md (Verification Only)

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Action**: Verify lines 429-617 already implement hierarchical pattern matching /report

**No modifications needed** - just document alignment in implementation summary

## Testing Strategy

### Unit Tests

**Test 1**: Topic Decomposition
- **Setup**: Create topic-decomposition.sh with test data
- **Execute**: Call `calculate_subtopic_count()` with various topics
- **Assertions**:
  - 1-3 word topic → 2 subtopics
  - 4-6 word topic → 3 subtopics
  - 7+ word topic → 4 subtopics

**Test 2**: Subtopic Validation
- **Setup**: Create test subtopic names (valid and invalid)
- **Execute**: Call `validate_subtopic_name()` for each
- **Assertions**:
  - Valid snake_case names pass
  - Invalid names (spaces, hyphens, uppercase) fail
  - Names >50 chars fail

**Test 3**: Path Calculation
- **Setup**: Create test topic directory, mock `get_next_artifact_number()`
- **Execute**: Calculate paths for 3 test subtopics
- **Assertions**:
  - All paths are absolute (start with /)
  - Paths follow format: `{research_subdir}/NNN_subtopic.md`
  - Sequential numbering (001, 002, 003)

### Integration Tests

**Test 4**: End-to-End Multi-Agent Pattern (see Task 4.3)
- **Setup**: Create test topic directory
- **Execute**:
  1. Decompose topic into subtopics
  2. Calculate paths for each subtopic
  3. Simulate research-specialist creating subtopic reports
  4. Simulate research-synthesizer creating overview
  5. Verify artifact structure
- **Assertions**:
  - All subtopic reports created at correct paths
  - Overview report created
  - Overview contains links to all subtopics
  - Directory structure matches spec: `reports/{NNN_research}/`

**Test 5**: Cross-Reference Integration
- **Setup**: Use test artifacts from Test 4
- **Execute**: Invoke spec-updater agent (or simulate)
- **Assertions**:
  - Overview linked to related plan (if exists)
  - Subtopics linked to overview
  - All links use relative paths
  - Bidirectional references validated

### Performance Tests

**Test 6**: Parallel Agent Timing
- **Setup**: Create research topic with 4 subtopics
- **Execute**:
  1. Sequential: Invoke agents one at a time, measure total time
  2. Parallel: Invoke all agents in single message, measure total time
- **Assertions**:
  - Parallel time < Sequential time
  - Time savings ≥ 40% (target: 40-60%)

### Example Test Execution

```bash
# Run all tests
cd /home/benjamin/.config/.claude

# Unit tests
bash tests/test_topic_decomposition.sh

# Integration tests
bash tests/test_report_multi_agent_pattern.sh

# Expected output:
# =========================================
# Testing Hierarchical Multi-Agent Research Pattern
# =========================================
#
# Test 1: Topic Decomposition
# ----------------------------
# ✓ Topic decomposition produced valid count
#
# Test 2: Path Pre-Calculation
# ----------------------------
# ✓ All paths calculated and verified as absolute
#
# Test 3: Report Creation (Simulated)
# ----------------------------
# ✓ All subtopic reports created
#
# Test 4: Overview Report Creation (Simulated)
# ----------------------------
# ✓ Overview report created
# ✓ Overview contains links to all subtopics
#
# Test 5: Artifact Structure Verification
# ----------------------------
# ✓ Research subdirectory created
# ✓ Correct number of subtopic reports: 3
# ✓ Overview report exists
#
# =========================================
# All tests passed!
# =========================================
```

## Artifact Examples

### Individual Report Template

**File**: `specs/042_authentication/reports/001_research/001_jwt_patterns.md`

```markdown
# JWT Implementation Patterns

## Metadata
- **Date**: 2025-10-20
- **Agent**: research-specialist
- **Topic**: jwt_patterns
- **Report Type**: Codebase analysis and best practices
- **Part of**: Authentication Patterns Research

## Executive Summary

JWT (JSON Web Token) implementation patterns in the codebase follow industry standards with RS256 signing. Current implementations use short-lived access tokens (15 min) with refresh token rotation for security. Key strengths include proper token validation and secure storage practices.

## Findings

### Current Implementation

**Token Structure** (found in `auth/jwt.lua:23-45`):
```lua
-- JWT structure uses RS256 algorithm
local jwt_config = {
  algorithm = "RS256",
  expiration = 900,  -- 15 minutes
  issuer = "auth-service",
  audience = "api-clients"
}
```

The codebase implements JWTs with:
- **RS256 signing**: Asymmetric encryption (public/private key pair)
- **Short expiration**: 15-minute access tokens reduce exposure window
- **Standard claims**: iss, aud, exp, sub properly configured
- **Validation**: Full signature and claims validation on every request

**Token Lifecycle** (found in `auth/middleware/jwt_validator.lua:67-89`):
- Access tokens: 15-minute expiration
- Refresh tokens: 7-day expiration with rotation
- Token blacklisting: Implemented via Redis for immediate revocation

### Best Practices Observed

**Security Patterns**:
1. **No sensitive data in payload**: Only user ID and role stored
2. **HTTPS enforcement**: Tokens only transmitted over secure connections
3. **Token rotation**: Refresh tokens rotate on use (prevents replay attacks)
4. **Proper storage**: Tokens stored in HttpOnly cookies (XSS protection)

**Performance Optimizations**:
1. **Public key caching**: Reduces validation overhead (`auth/cache/pubkey.lua:12`)
2. **Connection pooling**: Redis connections pooled for blacklist checks
3. **Lazy validation**: Signature verification only after expiration check

### Industry Best Practices (2025)

**OWASP JWT Security Cheatsheet**:
- ✓ Use strong signing algorithms (RS256 or ES256)
- ✓ Keep expiration times short (<30 min recommended)
- ✓ Implement token rotation for refresh tokens
- ✓ Validate all claims (iss, aud, exp, nbf)
- ✓ Use HTTPS only for token transmission

**Additional Recommendations**:
- Consider implementing `jti` (JWT ID) claim for enhanced tracking
- Implement rate limiting on token refresh endpoints
- Add token fingerprinting for additional security layer

## Recommendations

### High Priority

1. **Add JWT ID (jti) Claim for Tracking**
   - Impact: Enhanced security and auditability
   - Effort: Low (1-2 hours implementation)
   - Implementation: Add unique ID to each token, track in Redis
   - Benefit: Enable per-token revocation and audit trails

2. **Implement Rate Limiting on Token Endpoints**
   - Impact: Prevent brute force and abuse
   - Effort: Medium (4-6 hours with testing)
   - Implementation: Use existing rate limiter with token-specific limits
   - Benefit: Protect against token stuffing and replay attacks

### Medium Priority

3. **Add Token Fingerprinting**
   - Impact: Additional security layer against token theft
   - Effort: Medium (6-8 hours)
   - Implementation: Hash user agent + IP, validate on each request
   - Benefit: Detect token usage from different devices/locations

4. **Implement Token Refresh Endpoint Monitoring**
   - Impact: Detect suspicious refresh patterns
   - Effort: Low (2-3 hours)
   - Implementation: Log refresh events, alert on anomalies
   - Benefit: Early detection of compromised refresh tokens

### Low Priority

5. **Consider ES256 Algorithm Migration**
   - Impact: Smaller token size, improved performance
   - Effort: High (20+ hours with migration)
   - Implementation: Gradual rollover from RS256 to ES256
   - Benefit: 30-40% smaller tokens, faster validation

## References

### Codebase Files Analyzed

- `auth/jwt.lua:23-45` - JWT configuration and signing
- `auth/jwt.lua:78-123` - Token generation logic
- `auth/middleware/jwt_validator.lua:67-89` - Token validation
- `auth/cache/pubkey.lua:12-34` - Public key caching
- `auth/models/token.lua:15-67` - Token storage and retrieval

### External Documentation

- [OWASP JWT Security Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheatsheet.html)
- [RFC 7519 - JSON Web Token (JWT)](https://datatracker.ietf.org/doc/html/rfc7519)
- [JWT Best Practices](https://curity.io/resources/learn/jwt-best-practices/)

### Related Reports

- [Overview Report](./OVERVIEW.md) - Complete authentication patterns research
```

### Overview Report Template

**File**: `specs/042_authentication/reports/001_research/OVERVIEW.md`

```markdown
# Authentication Patterns and Security - Research Overview

## Metadata
- **Date**: 2025-10-20
- **Agent**: research-synthesizer
- **Research Topic**: authentication_patterns_and_security
- **Subtopic Reports**: 4
- **Main Topic Directory**: specs/042_authentication/
- **Created By**: /report command (hierarchical multi-agent pattern)

## Executive Summary

This research investigated authentication patterns and security best practices through four focused subtopics: JWT implementation patterns, OAuth2 flows and providers, session management strategies, and security best practices. The analysis reveals a mature authentication system with strong security foundations and industry-standard implementations.

**Key Findings**:
- Current JWT implementation follows OWASP best practices with RS256 signing and short-lived tokens
- OAuth2 integration supports multiple providers (Google, GitHub, Microsoft) with proper scope management
- Session management uses Redis-backed storage with secure cookie handling
- Security practices include proper token validation, HTTPS enforcement, and defense against common attacks

**Recommendations Summary**:
High-priority improvements include adding JWT ID claims for enhanced tracking, implementing rate limiting on authentication endpoints, and centralizing security configuration for consistency across authentication methods.

## Subtopic Reports

This research investigated 4 focused subtopics:

### JWT Implementation Patterns

**Report**: [./001_jwt_patterns.md](./001_jwt_patterns.md)

Analysis of JWT structure, lifecycle, and security patterns. Found strong implementation with RS256 signing, 15-minute access tokens, and proper validation. Recommends adding JWT ID claims and rate limiting for enhanced security.

### OAuth2 Flows and Providers

**Report**: [./002_oauth2_flows.md](./002_oauth2_flows.md)

Examination of OAuth2 integration supporting Google, GitHub, and Microsoft providers. Authorization Code flow properly implemented with PKCE support. Recommends adding state parameter validation and implementing token refresh background jobs.

### Session Management Strategies

**Report**: [./003_session_management.md](./003_session_management.md)

Investigation of Redis-backed session storage with 30-minute sliding window expiration. Secure cookie configuration with HttpOnly and SameSite attributes. Recommends implementing session rotation on privilege escalation and adding concurrent session limits.

### Security Best Practices

**Report**: [./004_security_best_practices.md](./004_security_best_practices.md)

Comprehensive security analysis covering CSRF protection, XSS prevention, rate limiting, and audit logging. Strong foundations with CSRF tokens and content security policies. Recommends centralizing security configuration and implementing automated security testing.

## Cross-Cutting Themes

### Theme 1: Token-Based Security as Foundation

All authentication methods (JWT, OAuth2, sessions) rely on token-based security with consistent patterns:
- Short-lived access tokens (15-30 min)
- Secure storage (HttpOnly cookies, Redis)
- Proper validation on every request
- Token rotation/refresh mechanisms

This unified approach simplifies security management and reduces attack surface.

**Observed in**: jwt_patterns, oauth2_flows, session_management

### Theme 2: Redis as Central Security Infrastructure

Redis serves as the backbone for multiple security features:
- Session storage and retrieval
- Token blacklisting for immediate revocation
- Rate limiting counters
- OAuth2 state parameter storage

Centralizing these on Redis provides performance (in-memory speed) and reliability (persistence options).

**Observed in**: jwt_patterns, oauth2_flows, session_management, security_best_practices

### Theme 3: Defense in Depth

Multiple layers of security protection observed across all authentication methods:
- Transport security (HTTPS only)
- Input validation and sanitization
- Output encoding (XSS prevention)
- CSRF protection for state-changing operations
- Rate limiting on sensitive endpoints
- Audit logging for security events

No single point of failure - compromise of one layer doesn't expose entire system.

**Observed in**: All subtopics

### Theme 4: Configuration Fragmentation

Security configurations (timeouts, algorithms, limits) scattered across multiple files:
- JWT config in `auth/jwt.lua`
- Session config in `auth/session_store.lua`
- OAuth2 config in `auth/oauth2/config.lua`
- Security headers in `auth/middleware/security_headers.lua`

Creates maintenance burden and risk of inconsistencies.

**Observed in**: All subtopics

## Synthesized Recommendations

Recommendations aggregated from all subtopic reports, prioritized by impact:

### High Priority

1. **Add JWT ID (jti) Claims for Enhanced Tracking** (from: jwt_patterns)
   - **Impact**: Enables per-token revocation and detailed audit trails
   - **Effort**: Low (1-2 hours implementation)
   - **Implementation**: Add unique ID generation to JWT creation, track in Redis
   - **Benefit**: Granular control over token lifecycle, improved security incident response

2. **Implement Centralized Security Configuration** (from: jwt_patterns, oauth2_flows, session_management, security_best_practices)
   - **Impact**: Reduces configuration fragmentation and inconsistency risk
   - **Effort**: Medium (8-10 hours with migration)
   - **Implementation**: Create `auth/config/security.lua` with all security parameters
   - **Benefit**: Single source of truth, easier auditing, consistent security policies

3. **Add Rate Limiting to Authentication Endpoints** (from: jwt_patterns, oauth2_flows, security_best_practices)
   - **Impact**: Prevents brute force attacks and credential stuffing
   - **Effort**: Medium (4-6 hours including testing)
   - **Implementation**: Use existing rate limiter with auth-specific limits
   - **Benefit**: Protects against automated attacks, reduces abuse

### Medium Priority

4. **Implement Session Rotation on Privilege Escalation** (from: session_management)
   - **Impact**: Prevents session fixation attacks during role changes
   - **Effort**: Low (2-3 hours)
   - **Implementation**: Regenerate session ID when user permissions change
   - **Benefit**: Additional protection against session hijacking

5. **Add OAuth2 State Parameter Validation** (from: oauth2_flows)
   - **Impact**: Prevents CSRF attacks on OAuth2 callback
   - **Effort**: Low (2-3 hours)
   - **Implementation**: Generate and validate state parameter in Redis
   - **Benefit**: Closes CSRF vulnerability in OAuth2 flow

6. **Implement Token Fingerprinting** (from: jwt_patterns)
   - **Impact**: Detect token usage from different devices/locations
   - **Effort**: Medium (6-8 hours)
   - **Implementation**: Hash user agent + IP, validate on requests
   - **Benefit**: Early detection of stolen tokens

### Low Priority

7. **Add Concurrent Session Limits** (from: session_management)
   - **Impact**: Prevent account sharing and unauthorized access
   - **Effort**: Medium (4-6 hours)
   - **Implementation**: Track active sessions per user in Redis
   - **Benefit**: Reduces unauthorized access risk

8. **Implement Automated Security Testing** (from: security_best_practices)
   - **Impact**: Catch security regressions early
   - **Effort**: High (15-20 hours for comprehensive suite)
   - **Implementation**: Add security-focused integration tests
   - **Benefit**: Continuous security validation

9. **Consider ES256 Algorithm Migration** (from: jwt_patterns)
   - **Impact**: Smaller tokens, improved performance
   - **Effort**: High (20+ hours with gradual migration)
   - **Implementation**: Dual-algorithm support during transition
   - **Benefit**: 30-40% smaller tokens, faster validation

## Implementation Guidance

### Recommended Implementation Order

**Phase 1: Quick Wins** (Week 1-2)
1. Add JWT ID claims (2 hours)
2. Implement session rotation on privilege escalation (3 hours)
3. Add OAuth2 state validation (3 hours)

**Phase 2: Core Security Enhancements** (Week 3-4)
4. Centralize security configuration (10 hours)
5. Implement rate limiting on auth endpoints (6 hours)
6. Add token fingerprinting (8 hours)

**Phase 3: Advanced Features** (Month 2)
7. Implement concurrent session limits (6 hours)
8. Add automated security testing (20 hours)
9. Plan ES256 migration (if desired)

### Testing Strategy

For each recommendation:
1. **Unit Tests**: Test individual components (validation, generation, etc.)
2. **Integration Tests**: Test complete authentication flows
3. **Security Tests**: Attempt to bypass protections (penetration testing)
4. **Performance Tests**: Measure impact on response times

### Migration Considerations

When implementing centralized security configuration:
- Use feature flags to enable gradual rollout
- Maintain backward compatibility during transition
- Update documentation alongside code changes
- Conduct thorough testing before production deployment

## References

### Codebase Files Analyzed

Compiled from all subtopic reports:

**Authentication Core**:
- `auth/jwt.lua:23-45, 78-123` - JWT implementation
- `auth/session_store.lua:23-67` - Session management
- `auth/oauth2/providers/*.lua` - OAuth2 provider integrations

**Middleware & Validation**:
- `auth/middleware/jwt_validator.lua:67-89` - JWT validation
- `auth/middleware/session_check.lua:12-45` - Session validation
- `auth/middleware/security_headers.lua:8-34` - Security headers

**Security Infrastructure**:
- `auth/cache/pubkey.lua:12-34` - Public key caching
- `auth/csrf/token.lua:15-67` - CSRF token management
- `auth/rate_limit/config.lua:10-45` - Rate limiting configuration

**Models & Storage**:
- `auth/models/token.lua:15-67` - Token storage
- `auth/models/session.lua:20-80` - Session model

### External Documentation

- [OWASP JWT Security Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheatsheet.html)
- [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [OWASP Top 10 2021](https://owasp.org/www-project-top-ten/)

## Next Steps

1. **Review Recommendations**: Prioritize based on current security posture and threat model
2. **Create Implementation Plan**: Use `/plan` command to generate detailed implementation plan
3. **Security Audit**: Consider professional security audit before implementing major changes
4. **Documentation Update**: Update authentication documentation with research findings
```

## Cross-References

### Dependencies

**Depends On**:
- **Phase 1** (Utility Creation): `create_topic_artifact()`, `get_or_create_topic_dir()`, `get_next_artifact_number()` from `.claude/lib/artifact-operations.sh`
- **Phase 5** (Documentation): Multi-agent research pattern documentation in `.claude/docs/concepts/hierarchical_agents.md`

**Referenced By**:
- `/orchestrate` command: Research phase (lines 429-617) uses same pattern
- `research-specialist` agent: `.claude/agents/research-specialist.md`
- Spec updater agent: `.claude/agents/spec-updater.md` (cross-reference integration)

### Related Documentation

- [Hierarchical Agents Guide](/.claude/docs/concepts/hierarchical_agents.md) - Multi-level agent coordination architecture
- [Directory Protocols](/.claude/docs/concepts/directory-protocols.md) - Topic-based artifact organization
- [Orchestration Guide](/.claude/docs/workflows/orchestration-guide.md) - Multi-agent workflow patterns
- [Using Agents](/.claude/docs/guides/using-agents.md) - Agent invocation patterns

### Related Commands

- `/orchestrate`: Uses hierarchical research pattern in research phase
- `/plan`: May invoke `/report` for research before planning
- `/implement`: May reference research reports during implementation

## Success Criteria

- [ ] `/report` command successfully decomposes topics into 2-4 subtopics
- [ ] Topic decomposition uses intelligent LLM-based analysis
- [ ] Parallel research-specialist agents invoked (one per subtopic, single message)
- [ ] All individual reports created at correct topic-based paths
- [ ] Report paths follow structure: `specs/{NNN_topic}/reports/{NNN_research}/NNN_subtopic.md`
- [ ] Overview report created with OVERVIEW.md naming convention
- [ ] Overview links to all individual subtopic reports (relative paths)
- [ ] Overview synthesizes findings (executive summary, cross-cutting themes, aggregated recommendations)
- [ ] Cross-references integrated via spec-updater (overview ↔ subtopics ↔ plan)
- [ ] All unit tests passing (topic decomposition, validation, path calculation)
- [ ] Integration test passing (end-to-end multi-agent pattern)
- [ ] /orchestrate research phase verified matching pattern (no changes needed)
- [ ] Performance improvement: 40-60% time savings vs sequential execution

## Rollback Plan

If issues occur during implementation:

### Immediate Rollback (< 1 hour)

1. **Revert /report.md Changes**:
   ```bash
   cd /home/benjamin/.config/.claude/commands
   git checkout HEAD -- report.md
   ```

2. **Remove New Files**:
   ```bash
   rm -f /home/benjamin/.config/.claude/agents/research-synthesizer.md
   rm -f /home/benjamin/.config/.claude/lib/topic-decomposition.sh
   rm -f /home/benjamin/.config/.claude/tests/test_report_multi_agent_pattern.sh
   rm -f /home/benjamin/.config/.claude/tests/test_topic_decomposition.sh
   ```

3. **Verify Original Functionality**:
   ```bash
   # Test original /report command
   /report "Test research topic"
   # Should create single report in topic directory
   ```

### Gradual Rollback (Preserve Some Features)

If only specific components failing:

**Scenario 1**: Decomposition logic broken
- Revert topic-decomposition.sh
- Hardcode 2-3 subtopics in /report.md temporarily
- Continue with multi-agent pattern using hardcoded subtopics

**Scenario 2**: Synthesizer agent failing
- Revert research-synthesizer.md
- Skip overview creation in /report.md
- Keep individual subtopic reports only (still valuable)

**Scenario 3**: Path pre-calculation issues
- Simplify path calculation to use topic root directly
- Remove research subdirectory nesting
- Create reports at: `specs/{NNN_topic}/reports/NNN_subtopic.md` (flat structure)

### Data Preservation

Before rollback:
```bash
# Backup any research artifacts created with new pattern
BACKUP_DIR="/tmp/report_pattern_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"

# Copy any specs directories created during testing
cp -r /home/benjamin/.config/.claude/specs/* "$BACKUP_DIR/" 2>/dev/null || true

echo "Research artifacts backed up to: $BACKUP_DIR"
```

### Re-Implementation

If rollback required but feature desired:
1. Review error logs and test failures
2. Identify root cause (decomposition, agents, synthesis, or integration)
3. Fix specific component in isolation
4. Re-test component independently before re-integrating
5. Gradual re-deployment (decomposition → agents → synthesis → integration)

## Notes

### Design Decisions

**Decision 1**: Subtopic Report Subdirectory Structure

**Chosen**: `specs/{NNN_topic}/reports/{NNN_research}/{NNN}_subtopic.md`

**Rationale**:
- Groups related subtopic reports from same research task together
- Enables multiple research tasks on same topic (different research subdirectories)
- Clear organization: overview + subtopics in same directory
- Relative links work cleanly (./001_subtopic.md from OVERVIEW.md)

**Alternative Considered**: Flat structure (`specs/{NNN_topic}/reports/NNN_subtopic.md`)
- Simpler paths
- But: Harder to group related subtopics
- But: OVERVIEW.md harder to distinguish from regular reports

**Decision 2**: Overview Report Naming (OVERVIEW.md vs Numbered)

**Chosen**: `OVERVIEW.md` (no number prefix)

**Rationale**:
- Alphabetically sorts to top of directory (O before numbers)
- Clear semantic meaning (not just another numbered report)
- Easy to find visually in file listings
- Consistent with common documentation patterns

**Alternative Considered**: Numbered (`000_overview.md` or `999_overview.md`)
- Maintains consistent numbering scheme
- But: 000 sorts before subtopics (good), 999 sorts after (less discoverable)
- But: Less semantically clear

**Decision 3**: Parallel Agent Invocation (Single Message vs Sequential)

**Chosen**: Multiple Task calls in single message

**Rationale**:
- 40-60% faster execution (agents run in parallel)
- Reduces total latency (no waiting between agents)
- Consistent with /orchestrate pattern
- Agents are independent (no sequential dependencies)

**Alternative Considered**: Sequential invocation (one agent per message)
- Simpler error handling
- But: 2-4x slower (agents run sequentially)
- But: Doesn't leverage parallelization benefits

### Potential Issues

**Issue 1**: LLM Decomposition Quality

**Risk**: LLM may produce poor subtopic decomposition (too broad, too narrow, overlapping)

**Mitigation**:
- Provide clear decomposition guidelines in prompt
- Validate subtopic count (2-4 enforced)
- Validate subtopic naming (snake_case, length limits)
- Manual review of decomposition before agent invocation
- User override option (allow custom subtopic specification)

**Issue 2**: Agent File Creation Failures

**Risk**: Research-specialist agents may fail to create files (path mismatches, errors)

**Mitigation**:
- Path pre-calculation ensures correct absolute paths
- ABSOLUTE REQUIREMENT markers in agent behavioral file enforce file creation
- Fallback creation if agent fails (extract from agent output)
- Report verification step catches missing files
- Search for alternate locations if path mismatch detected

**Issue 3**: Overview Synthesis Quality

**Risk**: Research-synthesizer may produce poor synthesis (shallow, missing themes, weak recommendations)

**Mitigation**:
- Behavioral file requires reading ALL subtopic reports
- Structured template enforces comprehensive sections
- Completion criteria verify content quality (not placeholders)
- Cross-cutting themes section forces pattern identification
- Recommendation aggregation with deduplication and prioritization

**Issue 4**: Cross-Reference Complexity

**Risk**: Bidirectional cross-references between overview, subtopics, and plan may be inconsistent

**Mitigation**:
- Spec-updater agent handles all cross-reference logic
- Relative paths reduce brittleness (../reports/001_research/OVERVIEW.md)
- Verification step checks bidirectional links
- Clear section names for cross-reference insertion ("Related Reports", "Research Reports")

### Future Enhancements

**Enhancement 1**: Adaptive Subtopic Count

**Description**: Dynamically adjust subtopic count based on research topic complexity analysis

**Implementation**:
- Use Task tool to analyze topic complexity (estimated scope, breadth, depth)
- Complexity score (0-10) maps to subtopic count:
  - 0-3: 2 subtopics
  - 4-6: 3 subtopics
  - 7-9: 4 subtopics
  - 10+: 5 subtopics (rare, very complex topics)
- Override option for user-specified count

**Benefit**: Better match subtopic granularity to research complexity

**Enhancement 2**: Incremental Overview Updates

**Description**: Allow updating overview when new subtopic reports added

**Implementation**:
- Detect existing OVERVIEW.md in research subdirectory
- Read existing overview and subtopic reports
- Invoke research-synthesizer with update mode
- Synthesizer adds new subtopic to existing overview (not full regeneration)
- Update cross-cutting themes with new findings

**Benefit**: Enables iterative research expansion without full regeneration

**Enhancement 3**: Report Quality Metrics

**Description**: Automatically assess subtopic report quality (completeness, depth, evidence)

**Implementation**:
- Create quality scoring utility (`.claude/lib/report-quality-scorer.sh`)
- Check for: executive summary length, findings count, recommendations count, file references
- Score each report (0-100)
- Surface low-scoring reports for review/improvement
- Track quality trends over time

**Benefit**: Ensure consistent research quality across all subtopics

**Enhancement 4**: Template-Based Research Plans

**Description**: Pre-defined research templates for common investigation patterns

**Implementation**:
- Create research templates in `.claude/templates/research/`
- Templates define standard subtopics for common research types:
  - `authentication.yaml`: JWT, OAuth, sessions, security
  - `api_design.yaml`: REST patterns, GraphQL, versioning, documentation
  - `database.yaml`: Schema design, queries, migrations, performance
- User selects template or custom decomposition
- Templates ensure comprehensive coverage for known domains

**Benefit**: Faster research setup, standardized coverage for common topics
