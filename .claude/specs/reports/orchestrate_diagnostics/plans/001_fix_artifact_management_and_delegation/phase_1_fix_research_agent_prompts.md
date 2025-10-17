# Phase 1: Fix Research Agent Prompts

## Metadata
- **Phase Number**: 1
- **Parent Plan**: 001_fix_artifact_management_and_delegation.md
- **Objective**: Update /orchestrate research phase to create report files with absolute paths
- **Complexity**: High
- **Status**: PENDING
- **Estimated Time**: 3-4 hours
- **Files Modified**:
  - `.claude/commands/orchestrate.md` (research phase section)
  - `.claude/lib/artifact-operations.sh` (path calculation utilities)

## Overview

This phase addresses the critical failure where research agents return inline summaries instead of creating report files. Currently, research agents consume 413k tokens when they should use <600 characters (path reference). This phase implements:

1. **Pre-invocation path calculation** - Calculate absolute report paths BEFORE launching agents
2. **Explicit file creation instructions** - Add "CRITICAL: Create Report File" blocks to prompts
3. **Post-completion verification** - Check that all report files exist before proceeding
4. **Proper forward_message integration** - Ensure metadata extraction operates on FILES not summaries

## Root Cause Analysis

**Why research agents don't create files:**
1. No explicit path provided to agents (they don't know WHERE to write)
2. Prompt lacks imperative "EXECUTE NOW" file creation instructions
3. No verification step after agents complete
4. Agents default to returning summaries when file creation unclear

**Impact:**
- Research phase: 308k+ tokens consumed (vs <10k target)
- No report artifacts for cross-referencing in plan
- 0% context reduction achieved (vs 92-97% target)
- Planning phase cannot reference research findings

## Detailed Implementation Tasks

### Task 1: Read Current Research Phase Implementation

**File**: `.claude/commands/orchestrate.md` (lines 420-550)

```bash
# Read the current research phase section
sed -n '420,550p' .claude/commands/orchestrate.md > /tmp/research_phase_current.md

# Identify key components:
# - How research topics are identified
# - Agent prompt template location
# - Agent invocation pattern (parallel vs sequential)
# - Output handling (where summaries go)
```

**Expected Findings:**
- Research topics identified from workflow description
- Agents invoked via `Task` tool with `general-purpose` subagent_type
- Agent prompt template likely inline in orchestrate.md
- No report path calculation before invocation
- Agent output likely captured as text summaries

**Deliverable**: Understanding of current research phase flow and pain points

---

### Task 2: Add Report Path Calculation Before Agent Invocation

**Location**: `.claude/commands/orchestrate.md` (insert before line ~463, agent invocation)

**Implementation Pattern:**

```markdown
## Phase 1: Research Phase

[Keep existing description...]

**EXECUTE NOW - Calculate Report Paths**:

Before invoking research agents, calculate absolute report paths for all topics:

1. Identify research topics (2-4 topics from workflow description)
2. For each topic:
   - Create topic directory: `specs/reports/{topic}/`
   - Find next available number: `get_next_artifact_number()`
   - Construct absolute path: `/full/path/to/specs/reports/{topic}/NNN_analysis.md`
3. Store in associative array: `REPORT_PATHS[topic]=path`

**Bash Example**:

\`\`\`bash
# Source utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# Identify topics from workflow description
TOPICS=("existing_patterns" "integration_points" "error_handling")

# Calculate paths
declare -A REPORT_PATHS

for topic in "${TOPICS[@]}"; do
  # Create topic directory
  TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/reports/${topic}"
  mkdir -p "$TOPIC_DIR"

  # Get next artifact number
  NEXT_NUM=$(get_next_artifact_number "$TOPIC_DIR")

  # Construct absolute path
  REPORT_PATH="${TOPIC_DIR}/${NEXT_NUM}_analysis.md"

  # Store for agent invocation
  REPORT_PATHS["$topic"]="$REPORT_PATH"

  echo "  Topic: $topic → $REPORT_PATH"
done
\`\`\`

**Verification Checkpoint**:
- [ ] All topic directories created
- [ ] Report paths are ABSOLUTE (start with /)
- [ ] Paths are unique (no duplicates)
- [ ] Paths stored for agent prompts

If any checkpoint fails, STOP and resolve before proceeding.
```

**Integration Notes:**
- Use existing `get_next_artifact_number()` from artifact-operations.sh
- Ensure `CLAUDE_PROJECT_DIR` is set (detect-project-dir.sh)
- Use bash associative arrays (requires bash 4.0+)
- Log paths for debugging/audit trail

---

### Task 3: Update Research Agent Prompt Template

**Location**: `.claude/commands/orchestrate.md` (lines ~463-467, agent prompt template)

**Current Template** (approximate):
```markdown
Task tool invocation:
- subagent_type: general-purpose
- description: "Research {topic}"
- prompt: "Research {topic} and provide findings..."
```

**Updated Template**:
```markdown
**EXECUTE NOW - Launch Research Agent**:

For each topic, invoke Task tool with this prompt structure:

\`\`\`markdown
Task {
  subagent_type: "general-purpose"
  description: "Research {topic} with artifact creation"
  prompt: "
    **CRITICAL: Create Report File**

    You MUST create a research report file using the Write tool at this EXACT path:

    **Report Path**: {REPORT_PATHS[topic]}

    Example: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md

    DO NOT:
    - Return only a summary without creating the file
    - Use relative paths (e.g., 'specs/reports/...')
    - Calculate or modify the path yourself
    - Skip file creation and provide inline findings

    DO:
    - Use Write tool with the EXACT absolute path above
    - Create a complete, detailed report (not abbreviated)
    - Return only: REPORT_PATH: {absolute_path}
    - Include brief 1-2 sentence summary AFTER path

    ---

    ## Research Task: {topic}

    {Existing research requirements from current template}

    ---

    ## Expected Output Format

    **Primary Output** (required):
    \`\`\`
    REPORT_PATH: {REPORT_PATHS[topic]}
    \`\`\`

    **Secondary Output** (optional, 1-2 sentences only):
    Brief summary of key findings.
  "
}
\`\`\`
```

**Key Changes:**
1. Added "CRITICAL: Create Report File" section at top (impossible to miss)
2. Provided exact absolute path (no ambiguity)
3. Explicit DO/DO NOT lists (clear expectations)
4. Emphasized REPORT_PATH return format
5. De-emphasized summary (should be minimal)

**Rationale:**
- Agents need explicit paths before they can write files
- "CRITICAL" header grabs attention immediately
- DO/DO NOT lists prevent common mistakes
- Return format specification enables parsing

---

### Task 4: Add Report File Verification

**Location**: `.claude/commands/orchestrate.md` (insert after agent completion, ~line 530-545)

**Implementation**:

```markdown
**EXECUTE NOW - Verify Report Files Created**:

After ALL research agents complete, verify report files exist:

\`\`\`bash
# Verification checkpoint
ALL_REPORTS_CREATED=true

for topic in "${!REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${REPORT_PATHS[$topic]}"

  echo "Verifying report: $topic"
  echo "  Expected path: $EXPECTED_PATH"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "  ❌ MISSING - Report file not created"

    # Search alternative locations (agent may have misunderstood path)
    echo "  Searching alternative locations..."
    SEARCH_PATTERN="*${topic}*analysis*.md"
    FOUND=$(find "${CLAUDE_PROJECT_DIR}/specs" -name "$SEARCH_PATTERN" -mmin -10 2>/dev/null)

    if [ -n "$FOUND" ]; then
      echo "  ⚠️  Found report at unexpected location: $FOUND"
      echo "  Moving to correct location..."
      mv "$FOUND" "$EXPECTED_PATH"
    else
      echo "  ❌ CRITICAL: No report found for $topic"
      ALL_REPORTS_CREATED=false
    fi
  else
    # Verify file is non-empty
    FILE_SIZE=$(stat -c%s "$EXPECTED_PATH" 2>/dev/null || stat -f%z "$EXPECTED_PATH" 2>/dev/null)

    if [ "$FILE_SIZE" -lt 100 ]; then
      echo "  ⚠️  WARNING: Report file suspiciously small (${FILE_SIZE} bytes)"
      ALL_REPORTS_CREATED=false
    else
      echo "  ✓ Report created successfully (${FILE_SIZE} bytes)"
    fi
  fi
done

if [ "$ALL_REPORTS_CREATED" = false ]; then
  echo ""
  echo "❌ CRITICAL ERROR: Research phase incomplete"
  echo "   Not all report files created. Cannot proceed to planning."
  echo ""
  echo "Action required:"
  echo "  1. Review agent outputs for errors"
  echo "  2. Re-run failed research agents with corrected prompts"
  echo "  3. Manually create missing reports if needed"
  exit 1
fi

echo ""
echo "✓ All research reports verified. Proceeding to planning phase."
\`\`\`

**Verification Checklist**:
- [ ] All report files exist at expected paths
- [ ] All report files are non-empty (>100 bytes)
- [ ] Alternative locations searched if files missing
- [ ] Clear error messages if reports incomplete
- [ ] Execution STOPS if reports missing (no silent failures)

If any verification fails, orchestrator must NOT proceed to planning phase.
```

**Rationale:**
- Catch file creation failures immediately (fail fast)
- Search alternative locations (agents may misinterpret paths)
- Size check catches "stub" files (agents creating empty files)
- Hard stop prevents cascade failures (planning needs research files)

---

### Task 5: Parse REPORT_PATH from Agent Output

**Location**: `.claude/commands/orchestrate.md` (after agent completion, during output processing)

**Implementation**:

```markdown
**EXECUTE NOW - Extract Report Paths from Agent Output**:

Parse agent responses to extract REPORT_PATH for forward_message integration:

\`\`\`bash
# For each agent output
declare -A AGENT_REPORT_PATHS

for topic in "${!REPORT_PATHS[@]}"; do
  AGENT_OUTPUT="${RESEARCH_OUTPUTS[$topic]}"  # From Task tool result

  # Extract REPORT_PATH line
  EXTRACTED_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'REPORT_PATH:\s*\K/.+' | head -1)

  if [ -z "$EXTRACTED_PATH" ]; then
    echo "⚠️  WARNING: Agent for $topic did not return REPORT_PATH"
    echo "   Using pre-calculated path: ${REPORT_PATHS[$topic]}"
    EXTRACTED_PATH="${REPORT_PATHS[$topic]}"
  else
    echo "✓ Agent reported path: $EXTRACTED_PATH"

    # Verify extracted path matches expected
    if [ "$EXTRACTED_PATH" != "${REPORT_PATHS[$topic]}" ]; then
      echo "⚠️  WARNING: Path mismatch!"
      echo "   Expected: ${REPORT_PATHS[$topic]}"
      echo "   Agent returned: $EXTRACTED_PATH"

      # Use expected path (more reliable)
      EXTRACTED_PATH="${REPORT_PATHS[$topic]}"
    fi
  fi

  AGENT_REPORT_PATHS["$topic"]="$EXTRACTED_PATH"
done

# Store for planning phase
export RESEARCH_REPORT_PATHS=("${AGENT_REPORT_PATHS[@]}")
\`\`\`

**Edge Cases Handled:**
- Agent doesn't return REPORT_PATH → Use pre-calculated path
- Agent returns different path → Use expected path (prevent drift)
- Multiple REPORT_PATH lines → Use first occurrence
- Malformed output → Fallback to expected path

**Why Fallback is Safe:**
- We calculated paths BEFORE invocation
- File verification already confirmed existence
- Path mismatch is agent output error, not file error
```

---

### Task 6: Update forward_message Integration

**Location**: `.claude/commands/orchestrate.md` (lines ~543-609, forward_message section)

**Current Implementation**: Likely operates on inline summaries (incorrect)

**Updated Implementation**:

```markdown
**EXECUTE NOW - Extract Metadata from Report Files**:

Use forward_message pattern to extract metadata from report FILES (not agent summaries):

\`\`\`bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# Extract metadata from each report
declare -A REPORT_METADATA

for topic in "${!AGENT_REPORT_PATHS[@]}"; do
  REPORT_FILE="${AGENT_REPORT_PATHS[$topic]}"

  echo "Extracting metadata: $topic"
  echo "  Report file: $REPORT_FILE"

  # Use extract_report_metadata utility
  METADATA_JSON=$(extract_report_metadata "$REPORT_FILE")

  # Parse key fields
  TITLE=$(echo "$METADATA_JSON" | jq -r '.title')
  SUMMARY=$(echo "$METADATA_JSON" | jq -r '.summary')  # ~50 words
  KEY_FINDINGS=$(echo "$METADATA_JSON" | jq -r '.key_findings[]' | head -3)

  # Store lightweight metadata (NOT full report content)
  REPORT_METADATA["$topic"]=$(jq -n \
    --arg path "$REPORT_FILE" \
    --arg title "$TITLE" \
    --arg summary "$SUMMARY" \
    --argjson findings "$(echo "$KEY_FINDINGS" | jq -Rs 'split("\n")')" \
    '{
      path: $path,
      title: $title,
      summary: $summary,
      key_findings: $findings
    }')

  echo "  Metadata size: $(echo "${REPORT_METADATA[$topic]}" | wc -c) bytes"
done

# Calculate context reduction
TOTAL_REPORT_SIZE=$(find "${CLAUDE_PROJECT_DIR}/specs/reports" -name "[0-9][0-9][0-9]_*.md" -mmin -10 -exec wc -c {} + | tail -1 | awk '{print $1}')
TOTAL_METADATA_SIZE=$(echo "${REPORT_METADATA[@]}" | wc -c)
REDUCTION_PERCENT=$(awk -v full="$TOTAL_REPORT_SIZE" -v meta="$TOTAL_METADATA_SIZE" \
  'BEGIN {printf "%.1f", (1 - meta/full) * 100}')

echo ""
echo "Context Reduction Metrics:"
echo "  Full report size: ${TOTAL_REPORT_SIZE} bytes"
echo "  Metadata size: ${TOTAL_METADATA_SIZE} bytes"
echo "  Reduction: ${REDUCTION_PERCENT}%"
echo ""

# Verify target achieved
if awk -v r="$REDUCTION_PERCENT" 'BEGIN {exit !(r >= 92)}'; then
  echo "✓ Context reduction target achieved (≥92%)"
else
  echo "⚠️  WARNING: Context reduction below target (<92%)"
fi
\`\`\`

**Key Points:**
- Operates on FILES, not agent output summaries
- Uses existing `extract_report_metadata()` utility
- Extracts ~50-word summary (not full content)
- Calculates and reports context reduction metrics
- Verifies 92-97% reduction target achieved

**Context Reduction Target:**
- Before: 308k+ tokens (full reports in context)
- After: <10k tokens (metadata only, ~600 chars per report)
- Reduction: 97% (vs 0% currently)
```

---

### Task 7: Add Inline Code Examples

**Location**: Throughout research phase section in orchestrate.md

**Examples to Add:**

1. **Topic Extraction Example** (insert near beginning):
```bash
# Example: Extract research topics from workflow description
WORKFLOW="Add user authentication with OAuth and session management"

# Identify research topics
TOPICS=(
  "authentication_patterns"    # OAuth implementation patterns
  "session_management"          # Session storage and lifecycle
  "security_best_practices"     # Auth security considerations
)
```

2. **Task Tool Invocation Example** (insert with prompt template):
```markdown
**Example Task Tool Invocation**:

\`\`\`
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns with artifact creation"
  prompt: "
    **CRITICAL: Create Report File**

    **Report Path**: /home/benjamin/.config/.claude/specs/reports/authentication_patterns/001_analysis.md

    [... rest of prompt template ...]
  "
}
\`\`\`
```

3. **Parallel Invocation Pattern** (insert with agent launch section):
```markdown
**Launch All Research Agents in Parallel**:

IMPORTANT: Invoke all Task tool calls in a SINGLE message for true parallel execution.

\`\`\`
# Single message with multiple Task tool calls:
Task(research-specialist: authentication_patterns)
Task(research-specialist: session_management)
Task(research-specialist: security_best_practices)
\`\`\`

Do NOT invoke sequentially (this defeats parallelism).
```

---

## Testing Specification

### Test Environment Setup

```bash
# Create test workspace
TEST_DIR="/tmp/orchestrate_test_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Copy orchestrate command
cp "${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md" .

# Source required utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/detect-project-dir.sh"
```

### Test Case 1: Report Path Calculation

```bash
test_report_path_calculation() {
  echo "Test: Report path calculation"

  # Setup
  TOPICS=("test_topic_1" "test_topic_2")
  declare -A REPORT_PATHS

  # Execute path calculation logic
  for topic in "${TOPICS[@]}"; do
    TOPIC_DIR="${CLAUDE_PROJECT_DIR}/specs/reports/${topic}"
    mkdir -p "$TOPIC_DIR"

    NEXT_NUM=$(get_next_artifact_number "$TOPIC_DIR")
    REPORT_PATH="${TOPIC_DIR}/${NEXT_NUM}_analysis.md"
    REPORT_PATHS["$topic"]="$REPORT_PATH"
  done

  # Verify
  for topic in "${TOPICS[@]}"; do
    PATH="${REPORT_PATHS[$topic]}"

    # Check absolute path
    [[ "$PATH" == /* ]] || {
      echo "FAIL: Path is not absolute: $PATH"
      return 1
    }

    # Check numbering
    [[ "$PATH" =~ /[0-9]{3}_analysis\.md$ ]] || {
      echo "FAIL: Path doesn't match pattern: $PATH"
      return 1
    }
  done

  echo "PASS: All report paths valid"
  return 0
}
```

### Test Case 2: Agent Prompt Contains Critical Instructions

```bash
test_agent_prompt_structure() {
  echo "Test: Agent prompt contains critical file creation instructions"

  # Extract prompt template from orchestrate.md
  PROMPT_SECTION=$(sed -n '/CRITICAL: Create Report File/,/Expected Output/p' \
    .claude/commands/orchestrate.md)

  # Verify required components
  echo "$PROMPT_SECTION" | grep -q "CRITICAL: Create Report File" || {
    echo "FAIL: Missing 'CRITICAL' header"
    return 1
  }

  echo "$PROMPT_SECTION" | grep -q "Report Path:" || {
    echo "FAIL: Missing 'Report Path:' specification"
    return 1
  }

  echo "$PROMPT_SECTION" | grep -q "DO NOT:" || {
    echo "FAIL: Missing 'DO NOT' list"
    return 1
  }

  echo "$PROMPT_SECTION" | grep -q "REPORT_PATH:" || {
    echo "FAIL: Missing 'REPORT_PATH:' return format"
    return 1
  }

  echo "PASS: Prompt structure complete"
  return 0
}
```

### Test Case 3: Report File Verification Logic

```bash
test_report_verification() {
  echo "Test: Report file verification logic"

  # Setup test reports
  declare -A REPORT_PATHS
  REPORT_PATHS["topic1"]="/tmp/test_report_1.md"
  REPORT_PATHS["topic2"]="/tmp/test_report_2.md"

  # Create one report, leave one missing
  echo "Test report content (more than 100 bytes)" > "${REPORT_PATHS[topic1]}"

  # Run verification logic (extracted from orchestrate.md)
  ALL_REPORTS_CREATED=true

  for topic in "${!REPORT_PATHS[@]}"; do
    EXPECTED_PATH="${REPORT_PATHS[$topic]}"

    if [ ! -f "$EXPECTED_PATH" ]; then
      ALL_REPORTS_CREATED=false
    else
      FILE_SIZE=$(stat -c%s "$EXPECTED_PATH" 2>/dev/null || stat -f%z "$EXPECTED_PATH" 2>/dev/null)
      if [ "$FILE_SIZE" -lt 100 ]; then
        ALL_REPORTS_CREATED=false
      fi
    fi
  done

  # Verify correct failure detection
  if [ "$ALL_REPORTS_CREATED" = true ]; then
    echo "FAIL: Verification should have detected missing report"
    return 1
  fi

  echo "PASS: Verification correctly detects missing reports"
  return 0
}
```

### Test Case 4: REPORT_PATH Parsing from Agent Output

```bash
test_report_path_parsing() {
  echo "Test: REPORT_PATH parsing from agent output"

  # Mock agent output
  AGENT_OUTPUT="Research findings...

REPORT_PATH: /home/user/.claude/specs/reports/topic/001_analysis.md

Key findings: ..."

  # Parse REPORT_PATH
  EXTRACTED_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'REPORT_PATH:\s*\K/.+' | head -1)

  # Verify extraction
  EXPECTED="/home/user/.claude/specs/reports/topic/001_analysis.md"
  if [ "$EXTRACTED_PATH" = "$EXPECTED" ]; then
    echo "PASS: REPORT_PATH extracted correctly"
    return 0
  else
    echo "FAIL: Expected '$EXPECTED', got '$EXTRACTED_PATH'"
    return 1
  fi
}
```

### Test Case 5: Context Usage Measurement

```bash
test_context_usage_reduction() {
  echo "Test: Context usage reduction calculation"

  # Create mock reports
  REPORT_DIR="/tmp/test_reports"
  mkdir -p "$REPORT_DIR"

  # Generate 3 reports (~5000 bytes each)
  for i in 1 2 3; do
    head -c 5000 /dev/urandom | base64 > "$REPORT_DIR/00${i}_report.md"
  done

  # Calculate full size
  TOTAL_REPORT_SIZE=$(find "$REPORT_DIR" -name "*.md" -exec wc -c {} + | tail -1 | awk '{print $1}')

  # Simulate metadata extraction (~250 bytes per report)
  METADATA_SIZE=$((250 * 3))

  # Calculate reduction
  REDUCTION_PERCENT=$(awk -v full="$TOTAL_REPORT_SIZE" -v meta="$METADATA_SIZE" \
    'BEGIN {printf "%.1f", (1 - meta/full) * 100}')

  # Verify ≥92% reduction
  if awk -v r="$REDUCTION_PERCENT" 'BEGIN {exit !(r >= 92)}'; then
    echo "PASS: Context reduction ${REDUCTION_PERCENT}% (target: ≥92%)"
    return 0
  else
    echo "FAIL: Context reduction ${REDUCTION_PERCENT}% below 92% target"
    return 1
  fi
}
```

### Integration Test: Full Research Phase

```bash
test_full_research_phase() {
  echo "Integration Test: Full research phase execution"

  # This test requires actual /orchestrate execution
  # Run with simple workflow to minimize time

  WORKFLOW="Simple test feature with basic CRUD operations"

  # Execute /orchestrate (research phase only, stop before planning)
  /orchestrate "$WORKFLOW" --phase research-only

  # Verify reports created
  REPORTS=$(find "${CLAUDE_PROJECT_DIR}/specs/reports" -name "[0-9][0-9][0-9]_*.md" -mmin -2)
  COUNT=$(echo "$REPORTS" | wc -l)

  if [ $COUNT -ge 2 ]; then
    echo "PASS: Research phase created $COUNT reports"
  else
    echo "FAIL: Expected ≥2 reports, found $COUNT"
    return 1
  fi

  # Verify REPORT_PATH in files
  for report in $REPORTS; do
    if [ ! -s "$report" ]; then
      echo "FAIL: Report is empty: $report"
      return 1
    fi
  done

  # Verify context usage (would need orchestrator output capture)
  # Check orchestrator logs/output for token usage metrics

  echo "PASS: Full research phase integration test"
  return 0
}
```

## Validation Checklist

After implementation, verify:

- [ ] Research agents create report files at specified absolute paths
- [ ] Report files contain complete findings (not summaries)
- [ ] Agents return `REPORT_PATH: /absolute/path` format
- [ ] Orchestrator verifies all report files exist before planning
- [ ] Context usage <10k tokens for research phase (not 308k+)
- [ ] forward_message operates on report FILES not inline summaries
- [ ] Metadata extraction achieves 92-97% context reduction
- [ ] All test cases pass
- [ ] Inline code examples are present and executable
- [ ] Verification checkpoints prevent silent failures

## Success Metrics

**Before Implementation:**
- Research agents: Return inline summaries (no files)
- Context usage: 308k+ tokens
- Report artifacts: 0 files created
- Context reduction: 0%

**After Implementation:**
- Research agents: Create report files at absolute paths
- Context usage: <10k tokens (97% reduction)
- Report artifacts: 2-4 files per workflow
- Context reduction: 92-97% (target achieved)

## Dependencies

### Required Utilities
- `.claude/lib/artifact-operations.sh::get_next_artifact_number()`
- `.claude/lib/artifact-operations.sh::extract_report_metadata()`
- `.claude/lib/detect-project-dir.sh` (for CLAUDE_PROJECT_DIR)

### Required Tools
- bash 4.0+ (associative arrays)
- jq (JSON parsing)
- find, grep, stat (file verification)

### Agent Behavioral Guidelines
- `.claude/agents/research-specialist.md` (ensure compatible with file creation requirements)

## Risk Mitigation

**Risk**: Agents still don't create files despite explicit instructions
**Mitigation**:
- Verification step catches failures immediately
- Search alternative locations for misplaced files
- Clear error messages guide manual resolution
- Hard stop prevents cascade failures

**Risk**: Path calculation generates duplicate/conflicting paths
**Mitigation**:
- `get_next_artifact_number()` is atomic operation
- Paths calculated sequentially (not in parallel)
- Verification checks for path uniqueness

**Risk**: Context reduction target not achieved
**Mitigation**:
- Metrics calculated and reported explicitly
- Warning displayed if below 92% target
- Root cause investigation in logs

## Next Steps

After Phase 1 completes:
1. Verify all test cases pass
2. Run integration test with real workflow
3. Document context reduction metrics
4. Proceed to Phase 2 (Planning Phase Delegation)

## Notes

- This phase has highest impact on context usage (97% reduction potential)
- All subsequent phases depend on research artifacts existing
- File creation must be verified before orchestrator proceeds
- Agent behavioral guidelines may need updates for file creation emphasis
