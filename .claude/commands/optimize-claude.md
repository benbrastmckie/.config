# /optimize-claude - CLAUDE.md Optimization Command

Analyzes CLAUDE.md and .claude/docs/ structure to generate an optimization plan using multi-stage agent workflow.

**Simple Usage** (no flags needed):
```bash
/optimize-claude
```

**Workflow**:
1. **Stage 1: Parallel Research** - 2 agents analyze CLAUDE.md and .claude/docs/
2. **Stage 2: Parallel Analysis** - 2 agents perform bloat and accuracy analysis
3. **Stage 3: Sequential Planning** - 1 agent generates optimization plan with bloat prevention and quality improvements
4. **Stage 4: Display Results** - Show plan location and next steps

---

## Phase 1: Path Allocation

```bash
set -euo pipefail

# Source unified location detection library
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/unified-location-detection.sh" || {
  echo "ERROR: Failed to source unified-location-detection.sh"
  exit 1
}

echo "=== /optimize-claude: CLAUDE.md Optimization Workflow ==="
echo ""

# Use unified location detection to allocate topic-based paths
LOCATION_JSON=$(perform_location_detection "optimize CLAUDE.md structure")

# Extract paths from JSON
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
SPECS_DIR=$(echo "$LOCATION_JSON" | jq -r '.specs_dir')
PROJECT_ROOT=$(echo "$LOCATION_JSON" | jq -r '.project_root')

# Verify paths allocated
[ -z "$TOPIC_PATH" ] && echo "ERROR: Failed to allocate topic path" && exit 1

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

[ ! -f "$CLAUDE_MD_PATH" ] && echo "ERROR: CLAUDE.md not found at $CLAUDE_MD_PATH" && exit 1
[ ! -d "$DOCS_DIR" ] && echo "ERROR: .claude/docs/ not found at $DOCS_DIR" && exit 1

echo "Research Stage: Analyzing CLAUDE.md and documentation..."
echo "  → Topic: $TOPIC_PATH"
echo "  → Analyzing CLAUDE.md structure (balanced threshold: 80 lines)"
echo "  → Analyzing .claude/docs/ organization"
echo ""
```

---

## Phase 2: Parallel Research Invocation

**EXECUTE NOW**: USE the Task tool to invoke research agents **in parallel** (single message, two Task blocks):

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
    - THRESHOLD: balanced

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

    **CRITICAL**: Create report file at EXACT path provided above.

    Expected Output:
    - Research report with directory tree, integration points, gap analysis
    - Completion signal: REPORT_CREATED: [exact absolute path]
  "
}
```

---

## Phase 3: Research Verification Checkpoint

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying research reports..."

if [ ! -f "$REPORT_PATH_1" ]; then
  echo "ERROR: Agent 1 (claude-md-analyzer) failed to create report: $REPORT_PATH_1"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

if [ ! -f "$REPORT_PATH_2" ]; then
  echo "ERROR: Agent 2 (docs-structure-analyzer) failed to create report: $REPORT_PATH_2"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ CLAUDE.md analysis: $REPORT_PATH_1"
echo "✓ Docs structure analysis: $REPORT_PATH_2"
echo ""
echo "Bloat Analysis Stage: Analyzing documentation bloat risks..."
echo ""
```

---

## Phase 4: Parallel Analysis Invocation (Bloat + Accuracy)

**EXECUTE NOW**: USE the Task tool to invoke BOTH analysis agents **in parallel** (single message, two Task blocks):

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

---

## Phase 5: Analysis Verification Checkpoint

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying analysis reports..."

if [ ! -f "$BLOAT_REPORT_PATH" ]; then
  echo "ERROR: Agent 3 (docs-bloat-analyzer) failed to create report: $BLOAT_REPORT_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

if [ ! -f "$ACCURACY_REPORT_PATH" ]; then
  echo "ERROR: Agent 4 (docs-accuracy-analyzer) failed to create report: $ACCURACY_REPORT_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ Bloat analysis: $BLOAT_REPORT_PATH"
echo "✓ Accuracy analysis: $ACCURACY_REPORT_PATH"
echo ""
echo "Planning Stage: Generating optimization plan with bloat prevention and quality improvements..."
echo ""
```

---

## Phase 6: Sequential Planning Invocation

**EXECUTE NOW**: USE the Task tool to invoke planning agent:

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

---

## Phase 7: Plan Verification Checkpoint

```bash
# VERIFICATION CHECKPOINT (MANDATORY)
echo ""
echo "Verifying implementation plan..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Agent 5 (cleanup-plan-architect) failed to create plan: $PLAN_PATH"
  echo "This is a critical failure. Check agent logs above."
  exit 1
fi

echo "✓ Implementation plan: $PLAN_PATH"
```

---

## Phase 8: Display Results

```bash
# Display results
echo ""
echo "=== Optimization Plan Generated ==="
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
echo "Next Steps:"
echo "  Review the plan and run: /implement $PLAN_PATH"
echo ""
```

---

## Notes

- **No flag parsing**: Simple invocation, no arguments needed
- **Hardcoded threshold**: Balanced (80 lines) for consistency
- **Lazy directory creation**: Agents create parent directories as needed
- **Fail-fast**: Verification checkpoints catch missing files immediately
- **Library integration**: Uses unified-location-detection.sh and optimize-claude-md.sh
- **Agent-based**: Delegates to specialized agents following behavioral injection pattern
