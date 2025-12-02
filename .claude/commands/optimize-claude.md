# /optimize-claude - CLAUDE.md Optimization Command

**YOU ARE EXECUTING** as the CLAUDE.md optimization orchestrator.

**YOUR ROLE**: You MUST analyze CLAUDE.md structure and .claude/docs/ organization, then generate an actionable optimization plan. You WILL execute each phase in sequence without deviation.

Analyzes CLAUDE.md and .claude/docs/ structure to generate an optimization plan using multi-stage agent workflow.

**Simple Usage** (no flags needed):
```bash
/optimize-claude
```

**Advanced Usage** (with flags):
```bash
/optimize-claude [--threshold <aggressive|balanced|conservative>]
                 [--aggressive|--balanced|--conservative]
                 [--dry-run]
                 [--file <report-path>] ...
```

**Flags**:
- `--threshold <value>`: Set bloat detection threshold (aggressive=50, balanced=80, conservative=120 lines)
- `--aggressive`: Shorthand for `--threshold aggressive`
- `--balanced`: Shorthand for `--threshold balanced` (default)
- `--conservative`: Shorthand for `--threshold conservative`
- `--dry-run`: Preview workflow stages without execution
- `--file <path>`: Add additional report to research phase (can be used multiple times)

**Workflow**:
1. **Stage 1: Parallel Research** - 2 agents analyze CLAUDE.md and .claude/docs/
2. **Stage 2: Parallel Analysis** - 2 agents perform bloat and accuracy analysis
3. **Stage 3: Sequential Planning** - 1 agent generates optimization plan with bloat prevention and quality improvements
4. **Stage 4: Display Results** - Show plan location and next steps

---

## Block 1a: Capture User Description

**EXECUTE NOW**: Capture the user-provided description and flags.

Replace `YOUR_DESCRIPTION_HERE` with the actual user input:

```bash
set +H
# Setup
mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true
TEMP_FILE="${HOME}/.claude/tmp/optimize_claude_arg_$(date +%s%N).txt"

# Capture user description (Claude will substitute)
echo "YOUR_DESCRIPTION_HERE" > "$TEMP_FILE"
echo "$TEMP_FILE" > "${HOME}/.claude/tmp/optimize_claude_arg_path.txt"
echo "Description captured to $TEMP_FILE"
```

---

## Block 1b: Validate and Parse Arguments

**EXECUTE NOW**: Read captured description, parse flags, and validate:

```bash
set +H

# Project detection
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi

export CLAUDE_PROJECT_DIR

# Source libraries with suppression
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}

# Initialize error log and set workflow metadata
ensure_error_log_exists
COMMAND_NAME="/optimize-claude"
WORKFLOW_ID="optimize_claude_$(date +%s)"
export COMMAND_NAME WORKFLOW_ID

# Read captured description
PATH_FILE="${HOME}/.claude/tmp/optimize_claude_arg_path.txt"
if [ -f "$PATH_FILE" ]; then
  TEMP_FILE=$(cat "$PATH_FILE")
else
  TEMP_FILE="${HOME}/.claude/tmp/optimize_claude_arg.txt"  # Legacy fallback
fi

if [ -f "$TEMP_FILE" ]; then
  DESCRIPTION=$(cat "$TEMP_FILE")
else
  echo "ERROR: Argument file not found" >&2
  echo "Usage: /optimize-claude \"[description] [--threshold <profile>] [--dry-run] [--file <path>]\"" >&2
  exit 1
fi

# Use default if empty
if [ -z "$DESCRIPTION" ]; then
  DESCRIPTION="Optimize CLAUDE.md structure and documentation"
fi

# Parse flags from description
THRESHOLD="balanced"  # Default
DRY_RUN=false
ADDITIONAL_REPORTS=()

# Extract --threshold flag
if echo "$DESCRIPTION" | grep -qE '\--threshold\s+\w+'; then
  THRESHOLD=$(echo "$DESCRIPTION" | grep -oE '\--threshold\s+\w+' | awk '{print $2}')
  DESCRIPTION=$(echo "$DESCRIPTION" | sed -E 's/--threshold\s+\w+//g')
fi

# Extract shorthand threshold flags
if echo "$DESCRIPTION" | grep -q '\--aggressive'; then
  THRESHOLD="aggressive"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--aggressive//g')
fi
if echo "$DESCRIPTION" | grep -q '\--balanced'; then
  THRESHOLD="balanced"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--balanced//g')
fi
if echo "$DESCRIPTION" | grep -q '\--conservative'; then
  THRESHOLD="conservative"
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--conservative//g')
fi

# Extract --dry-run flag
if echo "$DESCRIPTION" | grep -q '\--dry-run'; then
  DRY_RUN=true
  DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/--dry-run//g')
fi

# Extract --file flags (repeatable)
while echo "$DESCRIPTION" | grep -qE '\--file\s+\S+'; do
  FILE_PATH=$(echo "$DESCRIPTION" | grep -oE '\--file\s+\S+' | head -1 | awk '{print $2}')
  ADDITIONAL_REPORTS+=("$FILE_PATH")
  DESCRIPTION=$(echo "$DESCRIPTION" | sed -E "s/--file\s+\S+//1")  # Remove first occurrence
done

# Clean whitespace
DESCRIPTION=$(echo "$DESCRIPTION" | xargs)

# Validate threshold
if [[ "$THRESHOLD" =~ ^(aggressive|balanced|conservative)$ ]]; then
  : # Valid threshold, continue
else
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$DESCRIPTION" "validation_error" \
    "Invalid threshold profile: $THRESHOLD" "argument_validation" \
    "{\"threshold\": \"$THRESHOLD\", \"valid_values\": [\"aggressive\", \"balanced\", \"conservative\"]}"
  echo "ERROR: Invalid threshold '$THRESHOLD'. Valid values: aggressive, balanced, conservative" >&2
  exit 1
fi

# Validate --file paths if provided
for report_path in "${ADDITIONAL_REPORTS[@]}"; do
  if [ ! -f "$report_path" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$DESCRIPTION" "file_error" \
      "Additional report file not found: $report_path" "argument_validation" \
      "{\"file_path\": \"$report_path\"}"
    echo "ERROR: Report file not found: $report_path" >&2
    exit 1
  fi
done

OPTIMIZATION_DESCRIPTION="$DESCRIPTION"
USER_ARGS="$DESCRIPTION"
export USER_ARGS

echo "[CHECKPOINT] Argument parsing complete"
echo "Context: WORKFLOW_ID=${WORKFLOW_ID}, THRESHOLD=${THRESHOLD}, DRY_RUN=${DRY_RUN}"
echo "Ready for: Topic naming agent invocation"
```

---

## Block 1c: Invoke Topic Naming Agent

**EXECUTE NOW**: USE the Task tool to invoke topic naming agent and initialize workflow paths:

```bash
set +H

# Re-source libraries for subprocess isolation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}

# Persist OPTIMIZATION_DESCRIPTION for topic naming agent
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAMING_INPUT_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_naming_input_${WORKFLOW_ID}.txt"
echo "$OPTIMIZATION_DESCRIPTION" > "$TOPIC_NAMING_INPUT_FILE"
export TOPIC_NAMING_INPUT_FILE

# Handle dry-run mode
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  DRY-RUN MODE: Workflow Preview"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Workflow Stages:"
  echo "  1. Research (2 agents in parallel)"
  echo "     • claude-md-analyzer: Analyze CLAUDE.md structure"
  echo "     • docs-structure-analyzer: Analyze .claude/docs/ organization"
  echo ""
  echo "  2. Analysis (2 agents in parallel)"
  echo "     • docs-bloat-analyzer: Identify documentation bloat (threshold: $THRESHOLD)"
  echo "     • docs-accuracy-analyzer: Evaluate documentation quality"
  echo ""
  echo "  3. Planning (1 agent sequential)"
  echo "     • cleanup-plan-architect: Generate optimization plan"
  echo ""
  echo "Configuration:"
  echo "  • Threshold: $THRESHOLD"
  case $THRESHOLD in
    aggressive) echo "    - Bloat detection: >50 lines" ;;
    balanced)   echo "    - Bloat detection: >80 lines" ;;
    conservative) echo "    - Bloat detection: >120 lines" ;;
  esac
  if [ ${#ADDITIONAL_REPORTS[@]} -gt 0 ]; then
    echo "  • Additional Reports: ${#ADDITIONAL_REPORTS[@]}"
    for report in "${ADDITIONAL_REPORTS[@]}"; do
      echo "    - $report"
    done
  fi
  echo ""
  echo "Estimated Execution Time: 3-5 minutes"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "To execute: /optimize-claude"
  exit 0
fi

echo "✓ Setup complete, ready for topic naming"
echo "=== /optimize-claude: CLAUDE.md Optimization Workflow ==="
```

---

## Block 1b: Topic Name Generation

**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent for generate a semantic directory name.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-naming-agent.md

    You are generating a topic directory name for: /optimize-claude command

    **Input**:
    - User Prompt: ${OPTIMIZATION_DESCRIPTION}
    - Command Name: /optimize-claude
    - OUTPUT_FILE_PATH: ${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt

    Execute topic naming according to behavioral guidelines:
    1. Generate semantic topic name from user prompt
    2. Validate format (^[a-z0-9_]{5,40}$)
    3. Write topic name to OUTPUT_FILE_PATH using Write tool
    4. Return completion signal: TOPIC_NAME_GENERATED: <generated_name>

    If you encounter an error, return:
    TASK_ERROR: <error_type> - <error_message>
  "
}

## Block 1c: Topic Path Initialization

**EXECUTE NOW**: Parse topic name from agent output and initialize workflow paths.

```bash
set +H  # CRITICAL: Disable history expansion

# Restore environment and workflow ID
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

export CLAUDE_PROJECT_DIR

# Restore WORKFLOW_ID from environment or temp file
if [ -z "$WORKFLOW_ID" ]; then
  WORKFLOW_ID="optimize_claude_$(date +%s)"
fi

COMMAND_NAME="/optimize-claude"
OPTIMIZATION_DESCRIPTION="Optimize CLAUDE.md structure and documentation"
USER_ARGS="$OPTIMIZATION_DESCRIPTION"
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

# Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# === READ TOPIC NAME FROM AGENT OUTPUT FILE ===
# CRITICAL: Use CLAUDE_PROJECT_DIR for consistent path
TOPIC_NAME_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/topic_name_${WORKFLOW_ID}.txt"
TOPIC_NAME=""
NAMING_STRATEGY="fallback"

# Check if agent wrote output file
if [ -f "$TOPIC_NAME_FILE" ]; then
  # Read topic name from file (agent writes only the name, one line)
  TOPIC_NAME=$(cat "$TOPIC_NAME_FILE" 2>/dev/null | tr -d '\n' | tr -d ' ')

  if [ -z "$TOPIC_NAME" ]; then
    # File exists but is empty - agent failed
    NAMING_STRATEGY="agent_empty_output"
  else
    # Validate topic name format (exit code capture pattern)
    echo "$TOPIC_NAME" | grep -Eq '^[a-z0-9_]{5,40}$'
    IS_VALID=$?
    if [ $IS_VALID -ne 0 ]; then
      # Invalid format - log and fall back
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Topic naming agent returned invalid format" \
        "bash_block_1c" \
        "$(jq -n --arg name "$TOPIC_NAME" '{invalid_name: $name}')"

      NAMING_STRATEGY="validation_failed"
      TOPIC_NAME=""
    else
      # Valid topic name from LLM
      NAMING_STRATEGY="llm_generated"
    fi
  fi
else
  # File doesn't exist - agent failed to write
  NAMING_STRATEGY="agent_no_output_file"
fi

# Generate timestamp-based fallback if agent failed
if [ -z "$TOPIC_NAME" ]; then
  TOPIC_NAME="optimize_claude_$(date +%Y%m%d_%H%M%S)"
  echo "NOTE: Using timestamp-based fallback name (agent failed: $NAMING_STRATEGY)"

  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Topic naming agent failed or returned invalid name - using timestamp fallback" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$OPTIMIZATION_DESCRIPTION" --arg strategy "$NAMING_STRATEGY" --arg fallback "$TOPIC_NAME" \
       '{feature: $desc, fallback_reason: $strategy, fallback_name: $fallback}')"
fi

# Clean up temp file
rm -f "$TOPIC_NAME_FILE" 2>/dev/null || true

# Create classification result JSON for initialize_workflow_paths
CLASSIFICATION_JSON=$(jq -n --arg slug "$TOPIC_NAME" '{topic_directory_slug: $slug}')

# Initialize workflow paths with LLM-generated name (or fallback)
initialize_workflow_paths "$OPTIMIZATION_DESCRIPTION" "research-and-plan" "1" "$CLASSIFICATION_JSON"
INIT_EXIT=$?
if [ $INIT_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to initialize workflow paths" \
    "bash_block_1c" \
    "$(jq -n --arg desc "$OPTIMIZATION_DESCRIPTION" '{feature: $desc}')"

  echo "ERROR: Failed to initialize workflow paths" >&2
  exit 1
fi

# Calculate artifact paths (directories created lazily by agents)
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
REPORT_PATH_1="${REPORTS_DIR}/001_claude_md_analysis.md"
REPORT_PATH_2="${REPORTS_DIR}/002_docs_structure_analysis.md"
BLOAT_REPORT_PATH="${REPORTS_DIR}/003_bloat_analysis.md"
ACCURACY_REPORT_PATH="${REPORTS_DIR}/004_accuracy_analysis.md"
PLAN_PATH="${PLANS_DIR}/001_optimization_plan.md"

# Set paths for analysis
CLAUDE_MD_PATH="${CLAUDE_PROJECT_DIR}/CLAUDE.md"
DOCS_DIR="${CLAUDE_PROJECT_DIR}/.claude/docs"
PROJECT_ROOT="$CLAUDE_PROJECT_DIR"

# Validate required paths exist
if [ ! -f "$CLAUDE_MD_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    "CLAUDE.md not found at expected path" "validation" \
    "{\"expected_path\": \"$CLAUDE_MD_PATH\"}"
  echo "ERROR: CLAUDE.md not found at $CLAUDE_MD_PATH" && exit 1
fi

if [ ! -d "$DOCS_DIR" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
    ".claude/docs/ directory not found" "validation" \
    "{\"expected_path\": \"$DOCS_DIR\"}"
  echo "ERROR: .claude/docs/ not found at $DOCS_DIR" && exit 1
fi

# Setup complete
echo "[CHECKPOINT] Topic path initialized"
echo "Context: TOPIC_PATH=${TOPIC_PATH}, WORKFLOW_ID=${WORKFLOW_ID}, THRESHOLD=${THRESHOLD}"
echo "Ready for: Stage 1 research agents"
```

---

## Block 2: Agent Execution with Inline Verification

**Stage 1: Parallel Research** - Invoke research agents and verify

**EXECUTE NOW**: USE the Task tool to invoke the claude-md-analyzer agent for CLAUDE.md structure analysis.

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze CLAUDE.md structure"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/claude-md-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_PATH: ${CLAUDE_MD_PATH}
    - REPORT_PATH: ${REPORT_PATH_1}
    - THRESHOLD: ${THRESHOLD}

    **CRITICAL**: Create report file at EXACT path provided above.

    Expected Output:
    - Research report with section analysis, line counts, bloat flags
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}

**EXECUTE NOW**: USE the Task tool to invoke the docs-structure-analyzer agent for documentation structure analysis (second parallel task).

Task {
  subagent_type: "general-purpose"
  description: "Analyze .claude/docs/ structure"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-structure-analyzer.md

    **Input Paths** (ABSOLUTE):
    - DOCS_DIR: ${DOCS_DIR}
    - REPORT_PATH: ${REPORT_PATH_2}
    - PROJECT_DIR: ${PROJECT_ROOT}

    **Additional Context**:
    $(if [ ${#ADDITIONAL_REPORTS[@]} -gt 0 ]; then
      echo "Additional Reports for Analysis:"
      for report in "${ADDITIONAL_REPORTS[@]}"; do
        echo "- $report"
      done
      echo ""
      echo "Incorporate findings from these additional reports into your analysis."
    fi)

    **CRITICAL**: Create report file at EXACT path provided above.

    Expected Output:
    - Research report with directory tree, integration points, gap analysis
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}
```

**Inline Verification**: After agents return, execute this bash block:

```bash
# Verify research reports created
if [ ! -f "$REPORT_PATH_1" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
    "claude-md-analyzer agent failed to create report" "research_stage" \
    "{\"expected_report\": \"$REPORT_PATH_1\", \"agent\": \"claude-md-analyzer\"}"
  echo "ERROR: Agent 1 (claude-md-analyzer) failed to create report: $REPORT_PATH_1"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

if [ ! -f "$REPORT_PATH_2" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
    "docs-structure-analyzer agent failed to create report" "research_stage" \
    "{\"expected_report\": \"$REPORT_PATH_2\", \"agent\": \"docs-structure-analyzer\"}"
  echo "ERROR: Agent 2 (docs-structure-analyzer) failed to create report: $REPORT_PATH_2"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "[CHECKPOINT] Research complete (2 reports)"
echo "Context: CLAUDE_MD_REPORT=${CLAUDE_MD_REPORT}, DOCS_STRUCTURE_REPORT=${DOCS_STRUCTURE_REPORT}"
echo "Ready for: Analysis phase (bloat + accuracy)"
```

---

**Stage 2: Parallel Analysis** - Invoke analysis agents and verify

**EXECUTE NOW**: USE the Task tool to invoke the docs-bloat-analyzer agent for documentation bloat analysis.

```
Task {
  subagent_type: "general-purpose"
  description: "Analyze documentation bloat"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-bloat-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${BLOAT_REPORT_PATH}

    **CRITICAL**: Create bloat analysis report at EXACT path provided above.

    **Task**:
    1. Read both research reports
    2. Perform semantic bloat analysis (400 line threshold)
    3. Identify extraction risks and consolidation opportunities
    4. Generate bloat prevention guidance for planning agent

    Expected Output:
    - Bloat analysis report created at BLOAT_REPORT_PATH
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}

**EXECUTE NOW**: USE the Task tool to invoke the docs-accuracy-analyzer agent for documentation accuracy analysis.

Task {
  subagent_type: "general-purpose"
  description: "Analyze documentation accuracy and completeness"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/docs-accuracy-analyzer.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - ACCURACY_REPORT_PATH: ${ACCURACY_REPORT_PATH}

    **CRITICAL**: Create accuracy analysis report at EXACT path provided above.

    **Task**:
    1. Read both research reports
    2. Evaluate documentation quality across six dimensions (accuracy, completeness, consistency, timeliness, usability, clarity)
    3. Generate implementation-ready recommendations for quality improvements
    4. Provide specific file:line:correction entries for errors

    Expected Output:
    - Accuracy analysis report created at ACCURACY_REPORT_PATH
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}
```

**Inline Verification**: After agents return, execute this bash block:

```bash
# Verify analysis reports created
if [ ! -f "$BLOAT_REPORT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
    "docs-bloat-analyzer agent failed to create report" "analysis_stage" \
    "{\"expected_report\": \"$BLOAT_REPORT_PATH\", \"agent\": \"docs-bloat-analyzer\"}"
  echo "ERROR: Agent 3 (docs-bloat-analyzer) failed to create report: $BLOAT_REPORT_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

if [ ! -f "$ACCURACY_REPORT_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
    "docs-accuracy-analyzer agent failed to create report" "analysis_stage" \
    "{\"expected_report\": \"$ACCURACY_REPORT_PATH\", \"agent\": \"docs-accuracy-analyzer\"}"
  echo "ERROR: Agent 4 (docs-accuracy-analyzer) failed to create report: $ACCURACY_REPORT_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "[CHECKPOINT] Analysis complete (2 reports)"
echo "Context: BLOAT_REPORT=${BLOAT_REPORT_PATH}, ACCURACY_REPORT=${ACCURACY_REPORT_PATH}"
echo "Ready for: Planning phase (cleanup-plan-architect)"
```

---

**Stage 3: Sequential Planning** - Invoke planning agent and verify

**EXECUTE NOW**: USE the Task tool to invoke the cleanup-plan-architect agent for documentation cleanup planning.

```
Task {
  subagent_type: "general-purpose"
  description: "Generate optimization plan"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/cleanup-plan-architect.md

    **Input Paths** (ABSOLUTE):
    - CLAUDE_MD_REPORT_PATH: ${REPORT_PATH_1}
    - DOCS_REPORT_PATH: ${REPORT_PATH_2}
    - BLOAT_REPORT_PATH: ${BLOAT_REPORT_PATH}
    - ACCURACY_REPORT_PATH: ${ACCURACY_REPORT_PATH}
    - PLAN_PATH: ${PLAN_PATH}
    - PROJECT_DIR: ${PROJECT_ROOT}

    **CRITICAL**: Create plan file at EXACT path provided above.

    **Task**:
    1. Read all FOUR research reports (CLAUDE.md analysis, docs structure, bloat analysis, accuracy analysis)
    2. Synthesize findings with emphasis on bloat prevention AND quality improvements
    3. Prioritize: Critical accuracy errors FIRST, bloat reduction SECOND, enhancements THIRD
    4. Generate /implement-compatible plan with:
       - CLAUDE.md optimization phases
       - Documentation improvement phases (error fixes, gap filling, consistency improvements)
       - Bloat prevention tasks (size validation, post-merge checks)
       - Quality enhancement tasks (accuracy, completeness, consistency, timeliness, usability, clarity)
       - Verification and rollback procedures

    Expected Output:
    - Implementation plan file created at PLAN_PATH
    - Completion signal: PLAN_CREATED: [exact absolute path]
  "
}
```

**Inline Verification**: After agent returns, execute this bash block:

```bash
# Verify implementation plan created
if [ ! -f "$PLAN_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "agent_error" \
    "cleanup-plan-architect agent failed to create plan" "planning_stage" \
    "{\"expected_plan\": \"$PLAN_PATH\", \"agent\": \"cleanup-plan-architect\"}"
  echo "ERROR: Agent 5 (cleanup-plan-architect) failed to create plan: $PLAN_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "[CHECKPOINT] Planning complete (1 plan)"
echo "Context: OPTIMIZATION_PLAN=${PLAN_PATH}"
echo "Ready for: Results display and cleanup"
```

---

## Block 3: Results Display

```bash
# Display workflow results
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Optimization Plan Generated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Research Reports:"
echo "  • CLAUDE.md analysis: $REPORT_PATH_1"
echo "  • Docs structure analysis: $REPORT_PATH_2"
echo ""
echo "Analysis Reports:"
echo "  • Bloat analysis: $BLOAT_REPORT_PATH"
echo "  • Accuracy analysis: $ACCURACY_REPORT_PATH"
echo ""
echo "Implementation Plan:"
echo "  • $PLAN_PATH"
echo ""
echo "Workflow: $WORKFLOW_ID"
echo ""
echo "Next Steps:"
echo "  Review the plan and run: /implement $PLAN_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

---

## Notes

- **Flag parsing**: Supports threshold configuration, dry-run mode, and additional reports
- **Threshold profiles**:
  - aggressive: >50 lines (strict bloat detection)
  - balanced: >80 lines (default, recommended)
  - conservative: >120 lines (lenient, for complex domains)
- **Dry-run mode**: Preview workflow stages and configuration without execution
- **Additional reports**: Pass extra analysis reports with `--file` for enhanced context
- **Lazy directory creation**: Agents create parent directories as needed
- **Fail-fast**: Verification checkpoints catch missing files immediately
- **Library integration**: Uses unified-location-detection.sh and error-handling.sh
- **Agent-based**: Delegates to specialized agents following behavioral injection pattern
