# Research Report: Hierarchical Agent Architecture Analysis

**Date**: 2025-12-08
**Topic**: Hierarchical Agent Architecture Analysis
**Research Specialist**: research-coordinator (manual completion)
**Status**: COMPLETED

## Executive Summary

Analysis of the /lean-plan command reveals that research-coordinator integration was already implemented using Mode 2 (Pre-Decomposed) pattern, but a critical syntax error in path validation (Block 1d-topics) prevents execution. The three-tier hierarchy is properly designed but fails at runtime due to escaped negation operator in bash conditional.

## Three-Tier Agent Hierarchy Architecture

### Tier 1: Orchestrator (/lean-plan command)

**Role**: Workflow coordination and state management

**Responsibilities**:
1. Parse user input and determine complexity
2. Auto-detect Lean project directory
3. Initialize workflow state
4. Decompose research topics (Block 1d-topics)
5. Pre-calculate report paths (Hard Barrier Pattern)
6. Invoke research-coordinator (Block 1e-exec)
7. Validate report existence (Block 1f - hard barrier)
8. Extract metadata from coordinator output (Block 1f-metadata)
9. Invoke lean-plan-architect with metadata-only (Block 2)
10. Finalize plan and update TODO.md

**Context Window Preservation**:
- Receives metadata-only from coordinator (~330 tokens for 3 reports)
- Does NOT receive full research reports (~7,500 tokens)
- Enables 10+ iteration workflows vs 3-4 iterations with full reports

### Tier 2: Coordinator (research-coordinator agent)

**Role**: Research orchestration and metadata aggregation

**Mode**: Mode 2 (Pre-Decomposed)
- Topics provided by orchestrator (skips decomposition)
- Report paths pre-calculated by orchestrator
- Parallel research execution
- Metadata-only return

**Responsibilities**:
1. Parse pre-calculated topics and paths
2. Invoke research-specialist for each topic in parallel
3. Monitor specialist completion
4. Validate all reports exist (hard barrier)
5. Extract metadata from each report
6. Aggregate metadata into JSON format
7. Return metadata-only to orchestrator

**Context Window Preservation**:
- Never passes full report content to orchestrator
- Extracts: path, title, findings_count, recommendations_count, status, brief_summary
- Achieves 95.6% token reduction per report

### Tier 3: Specialist (research-specialist agent)

**Role**: Deep research execution

**Responsibilities**:
1. Receive single research topic
2. Search codebase for relevant information
3. Analyze documentation and existing patterns
4. Create comprehensive research report
5. Write full report to pre-calculated path on disk
6. Return completion signal with path

**Context Window Preservation**:
- Full report stays on disk, never passed up the chain
- Only completion signal returned to coordinator
- Downstream consumers use Read tool to access full content selectively

## Lean-Specific Research Topics

The /lean-plan command uses Lean-specific topic classification:

1. **Mathlib Research**: Existing theorems, tactics, data structures relevant to feature
2. **Proof Strategies**: Proof patterns and tactic sequences for the theorem/feature
3. **Project Structure**: Lean 4 module organization and dependencies
4. **Style Guidelines**: Lean 4 coding standards and best practices (optional for complexity ≥4)

**Parallel Execution Benefit**: These topics are independent, enabling 40-60% time savings through parallel research.

## Current Implementation in /lean-plan

### Block 1d-topics: Research Topics Classification

**Purpose**: Decompose research request into Lean-specific topics and pre-calculate report paths

**Current Code** (lines ~900-940):
```bash
# Research Topics Classification
case $COMPLEXITY in
  1|2)
    RESEARCH_TOPICS=("Mathlib Research")
    ;;
  3)
    RESEARCH_TOPICS=("Mathlib Research" "Proof Strategies" "Project Structure")
    ;;
  4)
    RESEARCH_TOPICS=("Mathlib Research" "Proof Strategies" "Project Structure" "Style Guidelines")
    ;;
esac

# Report Path Pre-Calculation (Hard Barrier Pattern)
REPORT_PATHS=()
for i in "${!RESEARCH_TOPICS[@]}"; do
  TOPIC_NUM=$((i + 1))
  TOPIC_NUM_PADDED=$(printf "%03d" "$TOPIC_NUM")
  TOPIC_SLUG=$(echo "${RESEARCH_TOPICS[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  REPORT_FILE="$REPORT_DIR/${TOPIC_NUM_PADDED}-${TOPIC_SLUG}.md"

  # CRITICAL SYNTAX ERROR HERE (line ~230 of eval block)
  if [[ \! "$REPORT_FILE" =~ ^/ ]]; then
    log_command_error "validation_error" \
      "Report path is not absolute" \
      "REPORT_FILE=$REPORT_FILE must start with / for Hard Barrier Pattern"
    exit 1
  fi

  REPORT_PATHS+=("$REPORT_FILE")
done
```

**Syntax Error**: The `\!` negation operator is escaped, causing bash conditional to fail with:
```
conditional binary operator expected
syntax error near `"$REPORT_FILE"'
```

**Fix**: Change `[[ \! "$REPORT_FILE" =~ ^/ ]]` to `[[ ! "$REPORT_FILE" =~ ^/ ]]` (remove backslash)

### Block 1e-exec: Research Coordinator Invocation

**Purpose**: Invoke research-coordinator with pre-decomposed topics and paths

**Current Code** (lines ~940-1040):
```bash
# Research Coordinator Invocation (Mode 2: Pre-Decomposed)
RESEARCH_TOPICS_STRING=$(printf "%s " "${RESEARCH_TOPICS[@]}")
REPORT_PATHS_STRING=$(printf "%s " "${REPORT_PATHS[@]}")

COORDINATOR_TASK="
**Input Contract (Hard Barrier Pattern - Mode 2: Manual Pre-Decomposition)**:
- research_request: \"$FEATURE_DESCRIPTION\"
- research_complexity: $COMPLEXITY
- report_dir: $REPORT_DIR
- topic_path: $TOPIC_PATH
- topics: $RESEARCH_TOPICS_STRING
- report_paths: $REPORT_PATHS_STRING
- context:
    feature_description: \"$FEATURE_DESCRIPTION\"
    workflow_type: \"lean-research-and-plan\"
    original_prompt_file: \"none\"
    archived_prompt_file: \"none\"

Execute research coordination according to behavioral guidelines and return:
RESEARCH_COMPLETE: {REPORT_COUNT}
reports: [JSON array of report metadata]
total_findings: {N}
total_recommendations: {N}
"

RESEARCH_METADATA=$(claude --agent "$RESEARCH_COORDINATOR_AGENT" <<< "$COORDINATOR_TASK")
```

**Note**: This block never executes due to syntax error in Block 1d-topics.

### Block 1f: Hard Barrier Validation

**Purpose**: Validate all report paths exist, fail-fast if <50% success

**Current Code** (lines ~1040-1140):
```bash
# Hard Barrier Validation
MISSING_REPORTS=()
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$REPORT_PATH" ]]; then
    MISSING_REPORTS+=("$REPORT_PATH")
    log_command_error "validation_error" \
      "Report file not found" \
      "REPORT_PATH=$REPORT_PATH expected after coordinator completion"
  fi
done

# Partial Success Mode (≥50% threshold)
TOTAL_REPORTS=${#REPORT_PATHS[@]}
MISSING_COUNT=${#MISSING_REPORTS[@]}
SUCCESS_COUNT=$((TOTAL_REPORTS - MISSING_COUNT))
SUCCESS_RATE=$((SUCCESS_COUNT * 100 / TOTAL_REPORTS))

if (( SUCCESS_RATE < 50 )); then
  log_command_error "validation_error" \
    "Hard barrier failed: <50% reports created" \
    "SUCCESS_RATE=${SUCCESS_RATE}% (${SUCCESS_COUNT}/${TOTAL_REPORTS})"
  exit 1
fi
```

**Note**: Same error logging signature issue as Block 1d-topics.

### Block 1f-metadata: Metadata Extraction

**Purpose**: Extract metadata from coordinator output for downstream consumption

**Current Code** (lines ~1140-1200):
```bash
# Extract metadata from coordinator output
REPORT_COUNT=$(echo "$RESEARCH_METADATA" | grep -oP 'RESEARCH_COMPLETE: \K\d+')
REPORT_METADATA_JSON=$(echo "$RESEARCH_METADATA" | sed -n '/reports: \[/,/\]/p' | sed '1d;$d')

# Format metadata for plan-architect
FORMATTED_METADATA=""
for REPORT_PATH in "${REPORT_PATHS[@]}"; do
  REPORT_TITLE=$(grep -m1 '^# ' "$REPORT_PATH" | sed 's/^# //')
  FINDINGS_COUNT=$(grep -c '^### ' "$REPORT_PATH" || echo 0)
  RECOMMENDATIONS_COUNT=$(grep -c '^\*\*Recommendation' "$REPORT_PATH" || echo 0)

  FORMATTED_METADATA+="- [$REPORT_TITLE]($REPORT_PATH) - $FINDINGS_COUNT findings, $RECOMMENDATIONS_COUNT recommendations\n"
done
```

### Block 2: Plan-Architect Invocation

**Purpose**: Create Lean implementation plan using metadata-only input

**Current Code** (lines ~1200-1400):
```bash
# Plan-Architect Invocation
PLAN_ARCHITECT_TASK="
**Planning Request**:
Feature: $FEATURE_DESCRIPTION
Complexity: $COMPLEXITY
Lean Project: $PROJECT_DIR

**Research Reports Available**:
$FORMATTED_METADATA

**Instruction**: Metadata summaries provided above. Use Read tool to access full report content when detailed findings or recommendations are needed for plan design.

Create comprehensive Lean implementation plan with phases, stages, and dependencies.
"

PLAN_CONTENT=$(claude --agent "$LEAN_PLAN_ARCHITECT_AGENT" <<< "$PLAN_ARCHITECT_TASK")
```

**Context Window Preservation**: Plan-architect receives ~330 tokens of metadata instead of ~7,500 tokens of full reports.

## Performance Metrics

### Token Usage (3 Research Reports)

| Approach | Tokens | Context % | Max Iterations |
|----------|--------|-----------|----------------|
| Full Report Passing | ~7,500 | 15-20% | 3-4 |
| Metadata-Only Passing | ~330 | 0.6% | 10+ |
| **Reduction** | **95.6%** | **19.4% → 0.6%** | **3x improvement** |

### Time Savings (Parallel Execution)

| Approach | Time | Notes |
|----------|------|-------|
| Serial Research | 3 topics × 3 min = 9 min | Sequential specialist invocations |
| Parallel Research | max(3 min) + 30s = 3.5 min | Coordinator parallel orchestration |
| **Savings** | **61%** | (9 - 3.5) / 9 = 61% |

## Critical Issue: Syntax Error in Path Validation

### Error Location

**File**: `.claude/commands/lean-plan.md`
**Block**: 1d-topics
**Line**: ~230 of eval block (approximately line 920 of markdown file)

### Error Details

**Current Code**:
```bash
if [[ \! "$REPORT_FILE" =~ ^/ ]]; then
```

**Bash Error**:
```
/run/current-system/sw/bin/bash: eval: line 230: conditional binary operator expected
/run/current-system/sw/bin/bash: eval: line 230: syntax error near `"$REPORT_FILE"'
```

**Root Cause**: The negation operator `!` is escaped as `\!`, which bash interprets as a literal backslash-exclamation string instead of a logical negation.

**Fix**:
```bash
if [[ ! "$REPORT_FILE" =~ ^/ ]]; then
```

### Impact

This syntax error prevents:
1. Block 1d-topics from completing (exit 1 on error)
2. Block 1e-exec from ever executing (coordinator never invoked)
3. Entire research-coordinator integration from functioning
4. Three-tier hierarchy from operating as designed

## Research-Coordinator Integration Pattern

### Mode 2: Pre-Decomposed (Implemented in /lean-plan)

**Characteristics**:
1. **Topics**: Pre-decomposed by orchestrator, not by coordinator
2. **Paths**: Pre-calculated by orchestrator (Hard Barrier Pattern)
3. **Coordinator Role**: Skip decomposition, execute parallel research, aggregate metadata
4. **Return Value**: Metadata-only JSON, not full reports

**Benefits**:
- Orchestrator controls topic granularity
- Hard barrier enforcement at orchestrator level
- Metadata-only passing preserves orchestrator context window
- Parallel execution at coordinator level

**Contrast with Mode 1 (Auto-Decomposition)**:
- Mode 1: Coordinator decomposes research_request into topics
- Mode 2: Orchestrator provides pre-decomposed topics
- Mode 1: Used when orchestrator wants coordinator to determine topic granularity
- Mode 2: Used when orchestrator has domain-specific topic structure (e.g., Lean research)

## Recommendations

### CRITICAL (Blocking)

1. **Fix Path Validation Syntax Error**
   - Change `[[ \! "$REPORT_FILE" =~ ^/ ]]` to `[[ ! "$REPORT_FILE" =~ ^/ ]]`
   - Location: Block 1d-topics, line ~920
   - Impact: Unblocks entire research-coordinator integration

2. **Fix Error Logging Signatures** (See Report 002)
   - Update all `log_command_error` calls to 7-parameter signature
   - Add parameters to `setup_bash_error_trap` call
   - Impact: Enables proper error tracking

### HIGH

3. **Update Documentation**
   - Update `research-invocation-standards.md` to reflect /lean-plan integration status
   - Change from "NOT INTEGRATED" to "INTEGRATED (Mode 2: Pre-Decomposed)"

### MEDIUM

4. **Test Integration After Fixes**
   - Run `/lean-plan` with complexity 3 feature
   - Monitor parallel research execution
   - Verify metadata-only passing
   - Measure context window usage

### LOW

5. **Consider lean-research-specialist Agent**
   - Create Lean-specific research specialist with Mathlib expertise
   - Replace general research-specialist in coordinator invocation
   - Benefits: Deeper Mathlib integration, better proof tactic suggestions

## References

- Research Coordinator Agent: `.claude/agents/research-coordinator.md`
- Lean-Plan Command: `.claude/commands/lean-plan.md`
- Hierarchical Agent Architecture: `.claude/docs/concepts/hierarchical-agents-overview.md`
- Hard Barrier Pattern: `.claude/docs/concepts/hierarchical-agents-examples.md` (Example 7)
- Error Output: `/home/benjamin/.config/.claude/output/lean-plan-output.md` (lines 38-41)
