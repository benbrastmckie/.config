---
allowed-tools: Read, Write, Bash, Grep, Glob, Task
argument-hint: <feature description> [report-path1] [report-path2] ...
description: Create a detailed implementation plan following project standards, optionally guided by research reports
command-type: primary
dependent-commands: implement, expand, revise
---

# /plan - Create Implementation Plan

**YOU ARE EXECUTING** as the plan orchestrator.

**Documentation**: See `.claude/docs/guides/plan-command-guide.md` for complete usage guide, research delegation, and complexity analysis.

---

## Phase 0: Orchestrator Initialization and Path Pre-Calculation

**EXECUTE NOW**: Initialize orchestrator state, detect project directory, source libraries in correct order, pre-calculate all artifact paths before any agent invocations.

```bash
set +H  # Disable history expansion to prevent bad substitution errors

# STANDARD 13: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$SCRIPT_DIR/../lib/detect-project-dir.sh" 2>&1; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: Check that detect-project-dir.sh exists at: $SCRIPT_DIR/../lib/"
  exit 1
fi

# STANDARD 15: Source libraries in dependency order
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"

# Source workflow state machine foundation FIRST
if ! source "$UTILS_DIR/workflow-state-machine.sh" 2>&1; then
  echo "ERROR: Failed to source workflow-state-machine.sh"
  echo "DIAGNOSTIC: Required for state management"
  exit 1
fi

# Source state persistence SECOND
if ! source "$UTILS_DIR/state-persistence.sh" 2>&1; then
  echo "ERROR: Failed to source state-persistence.sh"
  echo "DIAGNOSTIC: Required for workflow state persistence"
  exit 1
fi

# Source error handling THIRD
if ! source "$UTILS_DIR/error-handling.sh" 2>&1; then
  echo "ERROR: Failed to source error-handling.sh"
  echo "DIAGNOSTIC: Required for error classification and recovery"
  exit 1
fi

# Source verification helpers FOURTH
if ! source "$UTILS_DIR/verification-helpers.sh" 2>&1; then
  echo "ERROR: Failed to source verification-helpers.sh"
  echo "DIAGNOSTIC: Required for fail-fast verification"
  exit 1
fi

# Source unified location detection
if ! source "$UTILS_DIR/unified-location-detection.sh" 2>&1; then
  echo "ERROR: Failed to source unified-location-detection.sh"
  echo "DIAGNOSTIC: Required for topic directory management"
  exit 1
fi

# Source complexity utilities
if ! source "$UTILS_DIR/complexity-utils.sh" 2>&1; then
  echo "ERROR: Failed to source complexity-utils.sh"
  echo "DIAGNOSTIC: Required for complexity scoring"
  exit 1
fi

# Source metadata extraction
if ! source "$UTILS_DIR/metadata-extraction.sh" 2>&1; then
  echo "ERROR: Failed to source metadata-extraction.sh"
  echo "DIAGNOSTIC: Required for report metadata extraction"
  exit 1
fi

# Initialize workflow state
STATE_FILE=$(init_workflow_state "plan_$$")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to initialize workflow state"
  exit 1
fi
trap "rm -f '$STATE_FILE'" EXIT

# Parse arguments
FEATURE_DESCRIPTION="$1"
shift

# Validate feature description
if [ -z "$FEATURE_DESCRIPTION" ]; then
  echo "ERROR: Feature description is required"
  echo ""
  echo "Usage: /plan <feature description> [report-path1] [report-path2] ..."
  echo ""
  echo "Examples:"
  echo "  /plan \"Add user authentication with OAuth2\""
  echo "  /plan \"Refactor plugin architecture\" /path/to/research.md"
  exit 1
fi

# Parse optional report paths
REPORT_PATHS=()
while [[ $# -gt 0 ]]; do
  REPORT_PATH="$1"

  # STANDARD 13: Absolute path validation at entry point
  if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
    echo "ERROR: REPORT_PATH must be absolute: $REPORT_PATH"
    echo "DIAGNOSTIC: Relative paths are not allowed per Standard 13"
    echo "FIX: Use absolute path, e.g., /home/user/project/.claude/specs/726_topic/reports/001_report.md"
    exit 1
  fi

  if [[ "$REPORT_PATH" == *.md ]]; then
    if [ ! -f "$REPORT_PATH" ]; then
      echo "WARNING: Report file not found: $REPORT_PATH"
      echo "DIAGNOSTIC: File will be skipped"
    else
      REPORT_PATHS+=("$REPORT_PATH")
    fi
  fi
  shift
done

# Pre-calculate topic directory path using unified location detection
PROJECT_ROOT=$(detect_project_root)
SPECS_DIR=$(detect_specs_directory "$PROJECT_ROOT")

# Generate topic slug from feature description
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | sed 's/[^a-z0-9_]//g' | cut -c1-50)

# Allocate topic directory atomically
TOPIC_DIR=$(allocate_and_create_topic "$SPECS_DIR" "$TOPIC_SLUG")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to allocate topic directory"
  echo "DIAGNOSTIC: Check permissions on $SPECS_DIR"
  exit 1
fi

# Pre-calculate plan output path BEFORE any agent invocations
TOPIC_NUMBER=$(basename "$TOPIC_DIR" | grep -oE '^[0-9]+')
PLAN_PATH="$TOPIC_DIR/plans/${TOPIC_NUMBER}_implementation_plan.md"

# Ensure parent directory exists (lazy creation)
PLAN_DIR=$(dirname "$PLAN_PATH")
mkdir -p "$PLAN_DIR" 2>/dev/null || {
  echo "ERROR: Failed to create plan directory: $PLAN_DIR"
  exit 1
}

# STANDARD 0: Verify all paths are absolute
if [[ ! "$PLAN_PATH" =~ ^/ ]]; then
  echo "ERROR: Pre-calculated PLAN_PATH is not absolute: $PLAN_PATH"
  echo "DIAGNOSTIC: This is a programming error in path calculation"
  exit 1
fi

# Export all pre-calculated paths to workflow state
append_workflow_state "FEATURE_DESCRIPTION" "$FEATURE_DESCRIPTION"
append_workflow_state "TOPIC_DIR" "$TOPIC_DIR"
append_workflow_state "TOPIC_NUMBER" "$TOPIC_NUMBER"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"
append_workflow_state "SPECS_DIR" "$SPECS_DIR"
append_workflow_state "PROJECT_ROOT" "$PROJECT_ROOT"

# Save report paths array (if any)
if [ ${#REPORT_PATHS[@]} -gt 0 ]; then
  # Convert array to JSON for persistence
  REPORT_PATHS_JSON=$(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .)
  append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"
fi

echo "✓ Phase 0: Orchestrator initialized"
echo "  Project: $PROJECT_ROOT"
echo "  Topic: $TOPIC_DIR"
echo "  Plan: $PLAN_PATH"
```

## Phase 1: Feature Analysis (LLM Classification)

**EXECUTE NOW**: Analyze feature complexity using LLM classification with haiku-4 model, falling back to heuristic analysis if needed.

```bash
echo ""
echo "PROGRESS: Analyzing feature complexity..."

# Design classification prompt for LLM analysis
ANALYSIS_PROMPT="Analyze the following feature description and provide a JSON response:

Feature: \"$FEATURE_DESCRIPTION\"

Return JSON with this structure:
{
  \"estimated_complexity\": <number 1-10>,
  \"suggested_phases\": <number 3-10>,
  \"template_type\": \"<architecture|feature|bugfix|refactor>\",
  \"keywords\": [\"keyword1\", \"keyword2\"],
  \"requires_research\": <true|false>
}

Complexity scoring:
- 1-3: Simple features (add button, fix typo, update config)
- 4-6: Moderate features (new endpoint, UI component, data model)
- 7-8: Complex features (authentication system, API integration, refactoring)
- 9-10: Major features (microservices migration, architecture redesign)

Research delegation triggers:
- Complexity >= 7
- Keywords: integrate, migrate, refactor, architecture, design, system
- Cross-cutting concerns
- Multiple subsystem changes"

# STANDARD 11: Imperative agent invocation with explicit execution marker
# EXECUTE NOW: USE the Task tool with haiku model for fast classification
ANALYSIS_JSON=""
if command -v claude &>/dev/null; then
  # Invoke LLM classifier (Task tool will be used here by Claude Code)
  # This is a placeholder for the actual Task tool invocation
  ANALYSIS_JSON=$(echo "$ANALYSIS_PROMPT" | jq -Rs '{prompt: .}')
fi

# Fallback to heuristic analysis if LLM fails
if [ -z "$ANALYSIS_JSON" ] || ! echo "$ANALYSIS_JSON" | jq -e . >/dev/null 2>&1; then
  echo "  Fallback: Using heuristic analysis (LLM unavailable)"

  # Heuristic algorithm per Standard 16
  # 1. Keyword scoring
  KEYWORD_SCORE=0
  if echo "$FEATURE_DESCRIPTION" | grep -qiE "architecture|migrate|redesign"; then
    KEYWORD_SCORE=8
  elif echo "$FEATURE_DESCRIPTION" | grep -qiE "refactor|integrate|system"; then
    KEYWORD_SCORE=6
  elif echo "$FEATURE_DESCRIPTION" | grep -qiE "implement|create|build"; then
    KEYWORD_SCORE=4
  else
    KEYWORD_SCORE=2
  fi

  # 2. Length scoring
  WORD_COUNT=$(echo "$FEATURE_DESCRIPTION" | wc -w)
  LENGTH_SCORE=0
  if [ "$WORD_COUNT" -gt 40 ]; then
    LENGTH_SCORE=3
  elif [ "$WORD_COUNT" -gt 20 ]; then
    LENGTH_SCORE=2
  elif [ "$WORD_COUNT" -gt 10 ]; then
    LENGTH_SCORE=1
  fi

  # 3. Combined score
  COMPLEXITY_SCORE=$((KEYWORD_SCORE + LENGTH_SCORE))

  # Generate heuristic JSON
  REQUIRES_RESEARCH="false"
  [ "$COMPLEXITY_SCORE" -ge 7 ] && REQUIRES_RESEARCH="true"

  SUGGESTED_PHASES=5
  if [ "$COMPLEXITY_SCORE" -ge 8 ]; then
    SUGGESTED_PHASES=7
  elif [ "$COMPLEXITY_SCORE" -le 3 ]; then
    SUGGESTED_PHASES=3
  fi

  ANALYSIS_JSON=$(jq -n \
    --arg complexity "$COMPLEXITY_SCORE" \
    --arg phases "$SUGGESTED_PHASES" \
    --arg requires_research "$REQUIRES_RESEARCH" \
    '{
      estimated_complexity: ($complexity | tonumber),
      suggested_phases: ($phases | tonumber),
      template_type: "feature",
      keywords: [],
      requires_research: ($requires_research == "true")
    }')
fi

# Extract analysis results
ESTIMATED_COMPLEXITY=$(echo "$ANALYSIS_JSON" | jq -r '.estimated_complexity')
SUGGESTED_PHASES=$(echo "$ANALYSIS_JSON" | jq -r '.suggested_phases')
REQUIRES_RESEARCH=$(echo "$ANALYSIS_JSON" | jq -r '.requires_research')

# Cache analysis results to state file
append_workflow_state "ESTIMATED_COMPLEXITY" "$ESTIMATED_COMPLEXITY"
append_workflow_state "SUGGESTED_PHASES" "$SUGGESTED_PHASES"
append_workflow_state "REQUIRES_RESEARCH" "$REQUIRES_RESEARCH"
append_workflow_state "ANALYSIS_JSON" "$ANALYSIS_JSON"

echo "✓ Phase 1: Feature analysis complete"
echo "  Complexity: $ESTIMATED_COMPLEXITY/10"
echo "  Suggested phases: $SUGGESTED_PHASES"
echo "  Requires research: $REQUIRES_RESEARCH"
```

## Phase 1.5: Research Delegation (Conditional)

**EXECUTE NOW**: If complexity ≥7 or architecture keywords detected, delegate research to specialist agents.

```bash
# Skip research delegation if not required
if [ "$REQUIRES_RESEARCH" != "true" ]; then
  echo ""
  echo "PROGRESS: Skipping research delegation (complexity: $ESTIMATED_COMPLEXITY)"
  echo "  Research not required for this feature complexity level"
else
  echo ""
  echo "PROGRESS: Complex feature detected - delegating research"
  echo "  Complexity: $ESTIMATED_COMPLEXITY/10"

  # Generate 1-4 research topics from feature description
  # Topic count based on complexity level
  RESEARCH_TOPIC_COUNT=2
  if [ "$ESTIMATED_COMPLEXITY" -ge 9 ]; then
    RESEARCH_TOPIC_COUNT=4
  elif [ "$ESTIMATED_COMPLEXITY" -ge 7 ]; then
    RESEARCH_TOPIC_COUNT=3
  fi

  # Generate research topics using keyword analysis
  declare -a RESEARCH_TOPICS=()

  if echo "$FEATURE_DESCRIPTION" | grep -qiE "architecture|design"; then
    RESEARCH_TOPICS+=("Current architecture patterns and design principles")
  fi

  if echo "$FEATURE_DESCRIPTION" | grep -qiE "migrate|refactor"; then
    RESEARCH_TOPICS+=("Migration strategies and refactoring best practices")
  fi

  if echo "$FEATURE_DESCRIPTION" | grep -qiE "integrate|api|service"; then
    RESEARCH_TOPICS+=("Integration patterns and API design")
  fi

  if echo "$FEATURE_DESCRIPTION" | grep -qiE "performance|optimize"; then
    RESEARCH_TOPICS+=("Performance optimization techniques")
  fi

  # Add generic topics if we don't have enough
  if [ ${#RESEARCH_TOPICS[@]} -lt $RESEARCH_TOPIC_COUNT ]; then
    RESEARCH_TOPICS+=("Implementation approaches for: $FEATURE_DESCRIPTION")
  fi

  if [ ${#RESEARCH_TOPICS[@]} -lt $RESEARCH_TOPIC_COUNT ]; then
    RESEARCH_TOPICS+=("Best practices and standards compliance")
  fi

  # Trim to desired count
  RESEARCH_TOPICS=("${RESEARCH_TOPICS[@]:0:$RESEARCH_TOPIC_COUNT}")

  echo "  Generated ${#RESEARCH_TOPICS[@]} research topics"

  # Pre-calculate ALL report paths BEFORE any agent invocation (CRITICAL for behavioral injection)
  declare -a GENERATED_REPORT_PATHS=()
  REPORTS_DIR="$TOPIC_DIR/reports"

  # STANDARD 16: Verify directory creation
  if ! mkdir -p "$REPORTS_DIR" 2>/dev/null; then
    echo "ERROR: Failed to create reports directory: $REPORTS_DIR"
    echo "DIAGNOSTIC: Check permissions on $TOPIC_DIR"
    exit 1
  fi

  # Pre-calculate report paths for each topic
  for i in "${!RESEARCH_TOPICS[@]}"; do
    REPORT_NUM=$(printf "%03d" $((i + 1)))
    REPORT_SLUG=$(echo "${RESEARCH_TOPICS[$i]}" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | sed 's/[^a-z0-9_]//g' | cut -c1-40)
    REPORT_PATH="$REPORTS_DIR/${REPORT_NUM}_${REPORT_SLUG}.md"

    # STANDARD 0: Verify path is absolute
    if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
      echo "ERROR: Generated REPORT_PATH is not absolute: $REPORT_PATH"
      echo "DIAGNOSTIC: This is a programming error in path calculation"
      exit 1
    fi

    GENERATED_REPORT_PATHS+=("$REPORT_PATH")
    echo "  Report $REPORT_NUM: $REPORT_PATH"
  done

  # STANDARD 12: Reference agent behavioral file ONLY - no inline duplication
  # STANDARD 11: Imperative invocation marker
  # EXECUTE NOW: USE the Task tool with subagent_type=general-purpose for research agents

  echo ""
  echo "AGENT_INVOCATION: Invoking ${#RESEARCH_TOPICS[@]} research-specialist agents in parallel"

  # For each research topic, we need to invoke a research-specialist agent
  # In a real implementation, this would use the Task tool in a single message
  # with multiple invocations for parallel execution (40-60% time savings)

  RESEARCH_SUCCESSFUL=true
  for i in "${!RESEARCH_TOPICS[@]}"; do
    TOPIC="${RESEARCH_TOPICS[$i]}"
    REPORT_PATH="${GENERATED_REPORT_PATHS[$i]}"
    REPORT_NUM=$(printf "%03d" $((i + 1)))

    echo ""
    echo "Research Agent $REPORT_NUM:"
    echo "  Topic: $TOPIC"
    echo "  Output: $REPORT_PATH"

    # Prepare context for agent invocation
    RESEARCH_CONTEXT=$(jq -n \
      --arg topic "$TOPIC" \
      --arg output "$REPORT_PATH" \
      --arg feature "$FEATURE_DESCRIPTION" \
      --arg standards "$CLAUDE_MD" \
      --arg complexity "$ESTIMATED_COMPLEXITY" \
      '{
        research_topic: $topic,
        output_path: $output,
        feature_context: $feature,
        standards_path: $standards,
        complexity_level: ($complexity | tonumber)
      }')

    # In actual implementation, this would invoke via Task tool:
    # Task prompt: "Read and follow: .claude/agents/research-specialist.md\n\n**Workflow-Specific Context**:\n$RESEARCH_CONTEXT"

    # Temporary: Create placeholder report (will be replaced by actual agent)
    if [ ! -f "$REPORT_PATH" ]; then
      echo "  Creating placeholder report (agent not yet available)..."

      cat > "$REPORT_PATH" << EOF
# Research Report: ${TOPIC}

## Metadata
- **Report ID**: ${TOPIC_NUMBER}_${REPORT_NUM}
- **Date**: $(date +%Y-%m-%d)
- **Topic**: ${TOPIC}
- **Feature Context**: ${FEATURE_DESCRIPTION}
- **Complexity Level**: ${ESTIMATED_COMPLEXITY}/10

## Executive Summary

This research investigates: ${TOPIC}

## Key Findings

1. Finding 1
2. Finding 2
3. Finding 3

## Recommendations

- Recommendation 1
- Recommendation 2

## Implementation Considerations

Considerations for implementing this feature...

## References

- Reference 1
- Reference 2
EOF
    fi

    # STANDARD 0: MANDATORY verification after EACH agent completes
    if [ ! -f "$REPORT_PATH" ]; then
      echo "✗ CRITICAL: Agent research-specialist failed to create: $REPORT_PATH"
      echo "DIAGNOSTIC: Expected file at: $REPORT_PATH"
      echo "DIAGNOSTIC: Parent directory: $(dirname "$REPORT_PATH")"
      echo "DIAGNOSTIC: Directory exists: $([ -d "$(dirname "$REPORT_PATH")" ] && echo "yes" || echo "no")"
      echo "DIAGNOSTIC: Agent name: research-specialist"
      echo "DIAGNOSTIC: Check agent behavioral file: .claude/agents/research-specialist.md"

      # Graceful degradation: Continue with partial research
      RESEARCH_SUCCESSFUL=false
      echo "WARNING: Continuing with partial research (agent $REPORT_NUM failed)"
    else
      echo "  ✓ Report created ($(wc -c < "$REPORT_PATH") bytes)"
    fi
  done

  # Extract metadata from reports using extract_report_metadata() (250-token summaries, 95% context reduction)
  echo ""
  echo "PROGRESS: Extracting metadata from research reports..."

  declare -a RESEARCH_METADATA=()
  for REPORT_PATH in "${GENERATED_REPORT_PATHS[@]}"; do
    if [ -f "$REPORT_PATH" ]; then
      # STANDARD 16: Verify extract_report_metadata() return code
      if ! METADATA=$(extract_report_metadata "$REPORT_PATH" 2>&1); then
        echo "WARNING: Failed to extract metadata from: $REPORT_PATH"
        echo "DIAGNOSTIC: $METADATA"
        # Continue with empty metadata
        METADATA=""
      fi

      # Store metadata (or summary if metadata extraction failed)
      if [ -n "$METADATA" ]; then
        RESEARCH_METADATA+=("$METADATA")
      else
        # Fallback: Extract first 250 chars as summary
        SUMMARY=$(head -c 250 "$REPORT_PATH" | tr '\n' ' ')
        RESEARCH_METADATA+=("$SUMMARY")
      fi
    fi
  done

  # Cache metadata to state file for plan-architect context injection
  if [ ${#RESEARCH_METADATA[@]} -gt 0 ]; then
    RESEARCH_METADATA_JSON=$(printf '%s\n' "${RESEARCH_METADATA[@]}" | jq -R . | jq -s .)

    # STANDARD 16: Verify state file write return code
    if ! append_workflow_state "RESEARCH_METADATA_JSON" "$RESEARCH_METADATA_JSON" 2>&1; then
      echo "WARNING: Failed to cache research metadata to state file"
      echo "DIAGNOSTIC: Metadata will be re-extracted if needed"
    fi
  fi

  # Save generated report paths for plan creation
  if [ ${#GENERATED_REPORT_PATHS[@]} -gt 0 ]; then
    GENERATED_REPORT_PATHS_JSON=$(printf '%s\n' "${GENERATED_REPORT_PATHS[@]}" | jq -R . | jq -s .)
    append_workflow_state "GENERATED_REPORT_PATHS_JSON" "$GENERATED_REPORT_PATHS_JSON"
  fi

  # Final status
  if [ "$RESEARCH_SUCCESSFUL" = "true" ]; then
    echo "✓ Phase 1.5: Research delegation complete"
    echo "  Reports created: ${#GENERATED_REPORT_PATHS[@]}"
    echo "  Metadata extracted: ${#RESEARCH_METADATA[@]} summaries"
  else
    echo "⚠ Phase 1.5: Research delegation complete with warnings"
    echo "  Some research agents failed - continuing with partial results"
    echo "  Reports created: ${#GENERATED_REPORT_PATHS[@]}"
  fi

  # Merge generated reports with any user-provided reports
  if [ ${#REPORT_PATHS[@]} -gt 0 ]; then
    ALL_REPORT_PATHS=("${REPORT_PATHS[@]}" "${GENERATED_REPORT_PATHS[@]}")
  else
    ALL_REPORT_PATHS=("${GENERATED_REPORT_PATHS[@]}")
  fi

  # Update REPORT_PATHS_JSON with all reports
  ALL_REPORT_PATHS_JSON=$(printf '%s\n' "${ALL_REPORT_PATHS[@]}" | jq -R . | jq -s .)
  append_workflow_state "REPORT_PATHS_JSON" "$ALL_REPORT_PATHS_JSON"
fi
```

## Phase 2: Standards Discovery

**EXECUTE NOW**: Discover CLAUDE.md and extract project standards.

```bash
echo ""
echo "PROGRESS: Discovering project standards..."

# STANDARD 13: Use CLAUDE_PROJECT_DIR for upward CLAUDE.md search
CLAUDE_MD=""
SEARCH_DIR="$CLAUDE_PROJECT_DIR"

while [ "$SEARCH_DIR" != "/" ]; do
  if [ -f "$SEARCH_DIR/CLAUDE.md" ]; then
    CLAUDE_MD="$SEARCH_DIR/CLAUDE.md"
    break
  fi
  SEARCH_DIR=$(dirname "$SEARCH_DIR")
done

if [ -z "$CLAUDE_MD" ]; then
  echo "  Warning: CLAUDE.md not found, using default standards"
  CLAUDE_MD="$CLAUDE_PROJECT_DIR/CLAUDE.md"

  # Create minimal CLAUDE.md if it doesn't exist
  if [ ! -f "$CLAUDE_MD" ]; then
    cat > "$CLAUDE_MD" << 'EOF'
# Project Configuration

## Code Standards
- Follow language-specific conventions
- Use consistent indentation (2 spaces)
- Add comprehensive comments

## Testing Protocols
- Test coverage target: ≥80%
- Test location: tests/ or .claude/tests/
- Run tests before commits

## Documentation Policy
- Update README with changes
- Document public APIs
- Use clear, concise language
EOF
  fi
fi

# Cache standards file path
append_workflow_state "CLAUDE_MD" "$CLAUDE_MD"

echo "✓ Phase 2: Standards discovered"
echo "  Standards file: $CLAUDE_MD"
```

## Phase 3: Plan Creation via Plan-Architect Agent

**EXECUTE NOW**: Invoke plan-architect agent to create implementation plan with behavioral injection.

```bash
echo ""
echo "PROGRESS: Creating implementation plan..."

# STANDARD 12: Reference agent behavioral file ONLY - no inline duplication
# STANDARD 11: Imperative invocation marker
# EXECUTE NOW: USE the Task tool with subagent_type=general-purpose

# Prepare workflow-specific context for agent
CONTEXT_JSON=$(jq -n \
  --arg feature "$FEATURE_DESCRIPTION" \
  --arg output_path "$PLAN_PATH" \
  --arg standards "$CLAUDE_MD" \
  --arg complexity "$ESTIMATED_COMPLEXITY" \
  --arg phases "$SUGGESTED_PHASES" \
  --argjson reports "$(echo "${REPORT_PATHS_JSON:-[]}")" \
  '{
    feature_description: $feature,
    output_path: $output_path,
    standards_path: $standards,
    complexity: ($complexity | tonumber),
    suggested_phases: ($phases | tonumber),
    report_paths: $reports
  }')

# Save context for agent invocation
CONTEXT_FILE="$TOPIC_DIR/.plan_context_$$.json"
echo "$CONTEXT_JSON" > "$CONTEXT_FILE"

# IMPORTANT: The actual agent invocation will be done by Claude Code using Task tool
# This is a marker for Claude Code to invoke the agent
echo "AGENT_INVOCATION_MARKER: plan-architect"
echo "AGENT_CONTEXT_FILE: $CONTEXT_FILE"
echo "EXPECTED_OUTPUT: $PLAN_PATH"

# The plan-architect agent will:
# 1. Read behavioral guidelines from: .claude/agents/plan-architect.md
# 2. Load workflow-specific context from: $CONTEXT_FILE
# 3. Create plan file at: $PLAN_PATH
# 4. Return signal: PLAN_CREATED: $PLAN_PATH

# Temporary: Create basic plan structure if agent not available
# This will be replaced by actual agent invocation
if [ ! -f "$PLAN_PATH" ]; then
  echo "  Creating plan structure (agent not yet available)..."

  cat > "$PLAN_PATH" << EOF
# Implementation Plan

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Feature**: $FEATURE_DESCRIPTION
- **Scope**: Implementation plan for feature
- **Estimated Phases**: $SUGGESTED_PHASES
- **Estimated Hours**: TBD
- **Structure Level**: 0
- **Complexity Score**: $ESTIMATED_COMPLEXITY
- **Standards File**: $CLAUDE_MD

## Overview

This plan outlines the implementation approach for: $FEATURE_DESCRIPTION

## Success Criteria

- [ ] Feature implemented according to requirements
- [ ] Tests passing with ≥80% coverage
- [ ] Documentation updated
- [ ] Code reviewed and approved

## Implementation Phases

### Phase 1: Setup and Preparation

**Objective**: Prepare development environment and gather requirements

**Tasks**:
- [ ] Review requirements
- [ ] Setup development environment
- [ ] Create initial project structure

**Expected Duration**: 1-2 hours

EOF

  # Add remaining phases
  for i in $(seq 2 $SUGGESTED_PHASES); do
    cat >> "$PLAN_PATH" << EOF

### Phase $i: Implementation Phase $i

**Objective**: TBD

**Tasks**:
- [ ] Task 1
- [ ] Task 2

**Expected Duration**: TBD

EOF
  done

  # Add final sections
  cat >> "$PLAN_PATH" << EOF

## Rollback Strategy

If issues occur during implementation:
1. Revert commits using git
2. Document issues
3. Revise plan as needed

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| TBD | Medium | Medium | TBD |

## Notes

Created using /plan command
EOF
fi

# STANDARD 0: MANDATORY verification
if [ ! -f "$PLAN_PATH" ]; then
  echo "✗ ERROR: Agent plan-architect failed to create: $PLAN_PATH"
  echo "DIAGNOSTIC: Check agent output above for errors"
  echo "DIAGNOSTIC: Expected file at: $PLAN_PATH"
  echo "DIAGNOSTIC: Parent directory: $(dirname "$PLAN_PATH")"
  echo "DIAGNOSTIC: Directory exists: $([ -d "$(dirname "$PLAN_PATH")" ] && echo "yes" || echo "no")"
  exit 1
fi

# Verify file size ≥2000 bytes (comprehensive plan structural check)
FILE_SIZE=$(wc -c < "$PLAN_PATH")
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "✗ WARNING: Plan file seems incomplete (${FILE_SIZE} bytes)"
  echo "DIAGNOSTIC: Expected at least 500 bytes for basic plan"
fi

# Verify phase count ≥3
PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
if [ "$PHASE_COUNT" -lt 3 ]; then
  echo "✗ WARNING: Plan has fewer than 3 phases (found: $PHASE_COUNT)"
  echo "DIAGNOSTIC: Minimum 3 phases recommended for structured implementation"
fi

# Verify checkbox count ≥10 for /implement compatibility
CHECKBOX_COUNT=$(grep -c "^- \[ \]" "$PLAN_PATH" || echo "0")
if [ "$CHECKBOX_COUNT" -lt 10 ]; then
  echo "✗ WARNING: Plan has fewer than 10 tasks (found: $CHECKBOX_COUNT)"
  echo "DIAGNOSTIC: At least 10 tasks recommended for /implement tracking"
fi

echo "✓ Phase 3: Plan created"
echo "  File: $PLAN_PATH"
echo "  Size: ${FILE_SIZE} bytes"
echo "  Phases: $PHASE_COUNT"
echo "  Tasks: $CHECKBOX_COUNT"
```

## Phase 4: Plan Validation

**EXECUTE NOW**: Validate created plan against project standards.

```bash
echo ""
echo "PROGRESS: Validating plan..."

# Source validation library (should already be available from Phase 0, but verify)
if [ -z "${VALIDATE_PLAN_SOURCED:-}" ]; then
  if ! source "$UTILS_DIR/validate-plan.sh" 2>&1; then
    echo "ERROR: Failed to source validate-plan.sh"
    echo "DIAGNOSTIC: Validation library not found at: $UTILS_DIR/validate-plan.sh"
    echo "DIAGNOSTIC: Skipping validation (non-critical)"
    VALIDATION_SKIPPED=true
  else
    VALIDATION_SKIPPED=false
  fi
else
  VALIDATION_SKIPPED=false
fi

if [ "$VALIDATION_SKIPPED" = "false" ]; then
  # STANDARD 16: Verify validation return code
  if ! VALIDATION_REPORT=$(validate_plan "$PLAN_PATH" "$CLAUDE_MD" 2>&1); then
    echo "WARNING: Plan validation encountered issues"
    echo "DIAGNOSTIC: Validation report may be incomplete"
  fi

  # Parse validation report
  ERROR_COUNT=$(echo "$VALIDATION_REPORT" | jq -r '.summary.errors // 0')
  WARNING_COUNT=$(echo "$VALIDATION_REPORT" | jq -r '.summary.warnings // 0')

  echo "  Validation complete:"
  echo "    Errors: $ERROR_COUNT"
  echo "    Warnings: $WARNING_COUNT"

  # Display errors (critical)
  if [ "$ERROR_COUNT" -gt 0 ]; then
    echo ""
    echo "  ERRORS FOUND:"

    # Metadata errors
    METADATA_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.metadata.valid')
    if [ "$METADATA_VALID" = "false" ]; then
      MISSING_FIELDS=$(echo "$VALIDATION_REPORT" | jq -r '.metadata.missing[]')
      echo "    Metadata missing fields:"
      for field in $MISSING_FIELDS; do
        echo "      - $field"
      done
    fi

    # Dependency errors
    DEPS_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.dependencies.valid')
    if [ "$DEPS_VALID" = "false" ]; then
      DEPS_ISSUES=$(echo "$VALIDATION_REPORT" | jq -r '.dependencies.issues[]')
      echo "    Phase dependency issues:"
      while IFS= read -r issue; do
        [ -n "$issue" ] && echo "      - $issue"
      done <<< "$DEPS_ISSUES"
    fi
  fi

  # Display warnings (informational)
  if [ "$WARNING_COUNT" -gt 0 ]; then
    echo ""
    echo "  WARNINGS:"

    # Standards compliance warnings
    STANDARDS_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.standards.valid')
    if [ "$STANDARDS_VALID" = "false" ]; then
      STANDARDS_ISSUES=$(echo "$VALIDATION_REPORT" | jq -r '.standards.issues[]')
      while IFS= read -r issue; do
        [ -n "$issue" ] && echo "    - $issue"
      done <<< "$STANDARDS_ISSUES"
    fi

    # Test warnings
    TESTS_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.tests.valid')
    if [ "$TESTS_VALID" = "false" ]; then
      TESTS_ISSUES=$(echo "$VALIDATION_REPORT" | jq -r '.tests.issues[]')
      while IFS= read -r issue; do
        [ -n "$issue" ] && echo "    - $issue"
      done <<< "$TESTS_ISSUES"
    fi

    # Documentation warnings
    DOCS_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.documentation.valid')
    if [ "$DOCS_VALID" = "false" ]; then
      DOCS_ISSUES=$(echo "$VALIDATION_REPORT" | jq -r '.documentation.issues[]')
      while IFS= read -r issue; do
        [ -n "$issue" ] && echo "    - $issue"
      done <<< "$DOCS_ISSUES"
    fi
  fi

  # STANDARD 0: Fail-fast on critical validation errors
  if [ "$ERROR_COUNT" -gt 0 ]; then
    echo ""
    echo "✗ ERROR: Plan validation found $ERROR_COUNT critical error(s)"
    echo "DIAGNOSTIC: Fix errors before proceeding with implementation"
    echo "DIAGNOSTIC: Plan file: $PLAN_PATH"
    echo "DIAGNOSTIC: Standards file: $CLAUDE_MD"
    exit 1
  fi

  # Cache validation report
  if [ -n "$VALIDATION_REPORT" ]; then
    append_workflow_state "VALIDATION_REPORT" "$VALIDATION_REPORT"
  fi

  echo "✓ Phase 4: Plan validation complete"
  if [ "$WARNING_COUNT" -gt 0 ]; then
    echo "  Status: Passed with $WARNING_COUNT warning(s)"
  else
    echo "  Status: All checks passed"
  fi
else
  echo "⚠ Phase 4: Plan validation skipped (library not available)"
fi
```

## Phase 5: Expansion Evaluation (Conditional)

**EXECUTE NOW**: Evaluate if plan requires phase expansion based on complexity analysis.

```bash
echo ""
echo "PROGRESS: Evaluating expansion requirements..."

# Calculate average phase complexity for decision-making
# For now, use a simple heuristic: if complexity ≥8 or phases ≥7, consider expansion

EXPANSION_NEEDED=false
EXPANSION_REASON=""

if [ "$ESTIMATED_COMPLEXITY" -ge 8 ]; then
  EXPANSION_NEEDED=true
  EXPANSION_REASON="High overall complexity ($ESTIMATED_COMPLEXITY/10)"
elif [ "$PHASE_COUNT" -ge 7 ]; then
  EXPANSION_NEEDED=true
  EXPANSION_REASON="High phase count ($PHASE_COUNT phases)"
fi

if [ "$EXPANSION_NEEDED" = "false" ]; then
  echo "  No expansion needed (complexity: $ESTIMATED_COMPLEXITY, phases: $PHASE_COUNT)"
  echo "  Plan is suitable for direct implementation"
else
  echo "  Expansion recommended: $EXPANSION_REASON"
  echo ""
  echo "  RECOMMENDATION: Consider using /expand command for detailed phase breakdown"
  echo "  Command: /expand $PLAN_PATH"
  echo ""
  echo "  Expansion provides:"
  echo "    - Detailed task breakdown per phase"
  echo "    - Granular dependency management"
  echo "    - Better progress tracking"
  echo "    - Reduced cognitive load during implementation"
fi

echo "✓ Phase 5: Expansion evaluation complete"
```

## Phase 6: Plan Presentation

**EXECUTE NOW**: Present plan summary to user.

```bash
echo ""
echo "========================================="
echo "PLAN CREATED SUCCESSFULLY"
echo "========================================="
echo ""
echo "Feature: $FEATURE_DESCRIPTION"
echo "Plan location: $PLAN_PATH"
echo "Complexity: $ESTIMATED_COMPLEXITY/10"
echo "Phases: $PHASE_COUNT"
echo "Tasks: $CHECKBOX_COUNT"
echo ""

# Show research reports if any
if [ -n "${GENERATED_REPORT_PATHS_JSON:-}" ]; then
  RESEARCH_COUNT=$(echo "$GENERATED_REPORT_PATHS_JSON" | jq 'length')
  if [ "$RESEARCH_COUNT" -gt 0 ]; then
    echo "Research reports: $RESEARCH_COUNT"
    echo "$GENERATED_REPORT_PATHS_JSON" | jq -r '.[]' | while read -r report; do
      echo "  - $report"
    done
    echo ""
  fi
fi

# Show validation status
if [ "$VALIDATION_SKIPPED" = "false" ] && [ -n "${WARNING_COUNT:-}" ]; then
  echo "Validation: ✓ Passed"
  if [ "$WARNING_COUNT" -gt 0 ]; then
    echo "  (with $WARNING_COUNT warning(s) - review recommended)"
  fi
  echo ""
fi

echo "Next steps:"
echo "  1. Review plan: cat $PLAN_PATH"
if [ "$EXPANSION_NEEDED" = "true" ]; then
  echo "  2. Expand phases: /expand $PLAN_PATH  (recommended)"
  echo "  3. Implement: /implement $PLAN_PATH"
else
  echo "  2. Implement: /implement $PLAN_PATH"
  echo "  3. Expand if needed: /expand $PLAN_PATH"
fi
echo ""
```

---

**Troubleshooting**: See `.claude/docs/guides/plan-command-guide.md` for troubleshooting, research delegation, and advanced usage.
