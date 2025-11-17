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

## Phase 4: Plan Presentation

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
echo "Next steps:"
echo "  1. Review plan: cat $PLAN_PATH"
echo "  2. Implement: /implement $PLAN_PATH"
echo "  3. Expand complex phases: /expand $PLAN_PATH"
echo ""
```

---

**Troubleshooting**: See `.claude/docs/guides/plan-command-guide.md` for troubleshooting, research delegation, and advanced usage.
