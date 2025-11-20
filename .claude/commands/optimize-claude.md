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

## Block 1: Setup and Initialization

```bash
set -euo pipefail

# Project detection
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Parse arguments
THRESHOLD="balanced"  # Default threshold
DRY_RUN=false
ADDITIONAL_REPORTS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --aggressive)
      THRESHOLD="aggressive"
      shift
      ;;
    --balanced)
      THRESHOLD="balanced"
      shift
      ;;
    --conservative)
      THRESHOLD="conservative"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --file)
      ADDITIONAL_REPORTS+=("$2")
      shift 2
      ;;
    *)
      echo "ERROR: Unknown flag: $1" >&2
      echo "Usage: /optimize-claude [--threshold <aggressive|balanced|conservative>] [--dry-run] [--file <path>]" >&2
      exit 1
      ;;
  esac
done

# Source libraries with suppression
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh"
  exit 1
}

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

# Initialize error log and set workflow metadata
ensure_error_log_exists
COMMAND_NAME="/optimize-claude"
WORKFLOW_ID="optimize_claude_$(date +%s)"
USER_ARGS="$*"

# Validate threshold value
if [[ "$THRESHOLD" != "aggressive" && "$THRESHOLD" != "balanced" && "$THRESHOLD" != "conservative" ]]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "validation_error" \
    "Invalid threshold value: $THRESHOLD (must be aggressive|balanced|conservative)" "threshold_validation" \
    "{\"provided_threshold\": \"$THRESHOLD\", \"valid_values\": [\"aggressive\", \"balanced\", \"conservative\"]}"
  echo "ERROR: Invalid threshold value: $THRESHOLD" >&2
  echo "Valid values: aggressive, balanced, conservative" >&2
  exit 1
fi

# Validate additional report files
for report_file in "${ADDITIONAL_REPORTS[@]}"; do
  if [ ! -f "$report_file" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "file_error" \
      "Additional report file not found: $report_file" "file_validation" \
      "{\"report_file\": \"$report_file\"}"
    echo "ERROR: Report file not found: $report_file" >&2
    exit 1
  fi
done

# Use unified location detection to allocate topic-based paths
LOCATION_JSON=$(perform_location_detection "optimize CLAUDE.md structure")

# Extract paths from JSON
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
SPECS_DIR=$(echo "$LOCATION_JSON" | jq -r '.specs_dir')
PROJECT_ROOT=$(echo "$LOCATION_JSON" | jq -r '.project_root')

# Validate path allocation
if [ -z "$TOPIC_PATH" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" "state_error" \
    "Failed to allocate topic path from unified location detection" "path_allocation" \
    "{\"location_json\": $(echo "$LOCATION_JSON" | jq -c .)}"
  echo "ERROR: Failed to allocate topic path" && exit 1
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
CLAUDE_MD_PATH="${PROJECT_ROOT}/CLAUDE.md"
DOCS_DIR="${PROJECT_ROOT}/.claude/docs"

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
echo "Setup complete: Topic=$TOPIC_PATH | Workflow=$WORKFLOW_ID | Threshold=$THRESHOLD"
echo "=== /optimize-claude: CLAUDE.md Optimization Workflow ==="

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
  echo "Artifact Paths (will be created):"
  echo "  • Research Reports: $REPORTS_DIR"
  echo "  • Implementation Plans: $PLANS_DIR"
  echo ""
  echo "Estimated Execution Time: 3-5 minutes"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "To execute: /optimize-claude"
  exit 0
fi
```

---

## Block 2: Agent Execution with Inline Verification

**Stage 1: Parallel Research** - Invoke research agents and verify

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

echo "✓ Research complete: CLAUDE.md analysis and docs structure analyzed"
```

---

**Stage 2: Parallel Analysis** - Invoke analysis agents and verify

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

echo "✓ Analysis complete: Bloat and accuracy reports generated"
```

---

**Stage 3: Sequential Planning** - Invoke planning agent and verify

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

echo "✓ Planning complete: Implementation plan generated"
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
