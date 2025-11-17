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

**Documentation**: See `plan-command-guide.md` §3.1 "Phase 0: Orchestrator Initialization" for conceptual overview, path pre-calculation strategy, and state management details.

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
WORKFLOW_ID="plan_$$"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to initialize workflow state"
  exit 1
fi
trap "rm -f '$STATE_FILE'" EXIT

# Pattern 1: Fixed Semantic Filename (bash-block-execution-model.md:163-191)
# Save workflow ID to file for subsequent blocks using fixed location
PLAN_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
echo "$WORKFLOW_ID" > "$PLAN_STATE_ID_FILE"

# VERIFICATION CHECKPOINT: Verify state ID file created successfully
if [ ! -f "$PLAN_STATE_ID_FILE" ]; then
  echo "ERROR: State ID file not created at $PLAN_STATE_ID_FILE"
  exit 1
fi

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

# CRITICAL: Save feature description BEFORE any workflow state operations
# Libraries may pre-initialize variables which could overwrite parent values
SAVED_FEATURE_DESC="$FEATURE_DESCRIPTION"
export SAVED_FEATURE_DESC

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
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "PLAN_STATE_ID_FILE" "$PLAN_STATE_ID_FILE"
append_workflow_state "FEATURE_DESCRIPTION" "$SAVED_FEATURE_DESC"
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

## Phase 1: Feature Complexity Classification (Haiku Subagent)

**EXECUTE NOW**: USE the Task tool to invoke plan-complexity-classifier agent:

Task {
  subagent_type: "general-purpose"
  description: "Classify feature complexity for planning"
  model: "haiku"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-complexity-classifier.md

    **Feature-Specific Context**:
    - Feature Description: $SAVED_FEATURE_DESC
    - Command Name: plan

    **CRITICAL**: Return structured JSON classification.

    Execute classification following all guidelines in behavioral file.
    Return: CLASSIFICATION_COMPLETE: {JSON classification object}
  "
}

USE the Bash tool:

```bash
set +H  # Disable history expansion

# STATE RESTORATION PATTERN: Cross-bash-block state persistence
# Re-load workflow state (needed after Task invocation)

# Standard 13: CLAUDE_PROJECT_DIR detection
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Re-source required libraries
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# Load workflow state
PLAN_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$PLAN_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# FAIL-FAST VALIDATION: Classification must exist in state
if [ -z "${CLASSIFICATION_JSON:-}" ]; then
  echo "ERROR: plan-complexity-classifier agent did not save CLASSIFICATION_JSON to state"
  echo ""
  echo "Diagnostic:"
  echo "  - Agent was instructed to save classification via append_workflow_state"
  echo "  - Expected: append_workflow_state \"CLASSIFICATION_JSON\" \"\$CLASSIFICATION_JSON\""
  echo "  - Check agent's bash execution in previous response"
  echo "  - State file: $STATE_FILE (loaded via load_workflow_state)"
  echo ""
  echo "This is a critical bug. The workflow cannot proceed without classification data."
  exit 1
fi

# FAIL-FAST VALIDATION: JSON must be valid
echo "$CLASSIFICATION_JSON" | jq empty 2>/dev/null
JSON_VALID=$?
if [ $JSON_VALID -ne 0 ]; then
  echo "ERROR: Invalid JSON in CLASSIFICATION_JSON"
  echo ""
  echo "Diagnostic:"
  echo "  - Content: $CLASSIFICATION_JSON"
  echo "  - JSON validation failed"
  echo "  - Agent may have malformed the JSON output"
  echo ""
  echo "This is a critical bug. The workflow cannot proceed with invalid JSON."
  exit 1
fi

# Parse JSON fields using jq
RESEARCH_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.research_complexity' 2>/dev/null)
PLAN_COMPLEXITY=$(echo "$CLASSIFICATION_JSON" | jq -r '.plan_complexity' 2>/dev/null)
RESEARCH_TOPICS_JSON=$(echo "$CLASSIFICATION_JSON" | jq -c '.research_topics' 2>/dev/null)
PLAN_FILENAME_SLUG=$(echo "$CLASSIFICATION_JSON" | jq -r '.plan_filename_slug' 2>/dev/null)
CONFIDENCE=$(echo "$CLASSIFICATION_JSON" | jq -r '.confidence' 2>/dev/null)

# VERIFICATION CHECKPOINT: Verify all required fields extracted
if [ -z "$RESEARCH_COMPLEXITY" ] || [ "$RESEARCH_COMPLEXITY" = "null" ]; then
  echo "ERROR: research_complexity not found in classification JSON: $CLASSIFICATION_JSON"
  exit 1
fi

if [ -z "$PLAN_COMPLEXITY" ] || [ "$PLAN_COMPLEXITY" = "null" ]; then
  echo "ERROR: plan_complexity not found in classification JSON: $CLASSIFICATION_JSON"
  exit 1
fi

if [ -z "$RESEARCH_TOPICS_JSON" ] || [ "$RESEARCH_TOPICS_JSON" = "null" ]; then
  echo "ERROR: research_topics not found in classification JSON: $CLASSIFICATION_JSON"
  exit 1
fi

if [ -z "$PLAN_FILENAME_SLUG" ] || [ "$PLAN_FILENAME_SLUG" = "null" ]; then
  echo "ERROR: plan_filename_slug not found in classification JSON: $CLASSIFICATION_JSON"
  exit 1
fi

# Generate semantic report filenames from research topics (if any)
TOPIC_COUNT=$(echo "$RESEARCH_TOPICS_JSON" | jq 'length')

if [ "$TOPIC_COUNT" -gt 0 ]; then
  # Extract filename slugs from topics array
  REPORT_PATHS=()
  for i in $(seq 0 $((TOPIC_COUNT - 1))); do
    FILENAME_SLUG=$(echo "$RESEARCH_TOPICS_JSON" | jq -r ".[$i].filename_slug")
    REPORT_NUMBER=$(printf "%03d" $((i + 1)))
    REPORT_PATH="${TOPIC_DIR}/reports/${REPORT_NUMBER}_${FILENAME_SLUG}.md"
    REPORT_PATHS+=("$REPORT_PATH")
  done

  # Convert REPORT_PATHS array to JSON for state persistence
  REPORT_PATHS_JSON=$(printf '%s\n' "${REPORT_PATHS[@]}" | jq -R . | jq -s .)
  append_workflow_state "REPORT_PATHS_JSON" "$REPORT_PATHS_JSON"
fi

# Update PLAN_PATH with semantic filename slug
PLAN_PATH="${TOPIC_DIR}/plans/${TOPIC_NUMBER}_${PLAN_FILENAME_SLUG}.md"
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Export classification variables to state
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "PLAN_COMPLEXITY" "$PLAN_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
append_workflow_state "PLAN_FILENAME_SLUG" "$PLAN_FILENAME_SLUG"
append_workflow_state "CONFIDENCE" "$CONFIDENCE"

echo "✓ Phase 1: Feature complexity classification complete"
echo "  Research complexity: $RESEARCH_COMPLEXITY/3"
echo "  Plan complexity: $PLAN_COMPLEXITY/10"
echo "  Research topics: $TOPIC_COUNT"
echo "  Plan filename: ${PLAN_FILENAME_SLUG}.md"
echo "  Confidence: $CONFIDENCE"
```

## Phase 1.5: Research Delegation (Conditional)

**EXECUTE NOW**: If research_complexity > 0, delegate research to specialist agents using pre-calculated paths from Haiku classifier.

**Documentation**: See `plan-command-guide.md` §3.3 "Phase 1.5: Research Delegation" for agent invocation pattern and metadata extraction details.

```bash
set +H  # Disable history expansion

# STATE RESTORATION PATTERN: Re-load workflow state
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Load workflow state
PLAN_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$PLAN_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# Check if research is needed based on classifier output
TOPIC_COUNT=$(echo "$RESEARCH_TOPICS_JSON" | jq 'length')

if [ "$TOPIC_COUNT" -eq 0 ]; then
  echo ""
  echo "PROGRESS: Skipping research delegation (research_complexity: $RESEARCH_COMPLEXITY)"
  echo "  No research topics identified by classifier"
else
  echo ""
  echo "PROGRESS: Research delegation initiated"
  echo "  Research complexity: $RESEARCH_COMPLEXITY/3"
  echo "  Research topics: $TOPIC_COUNT"

  # Ensure reports directory exists
  REPORTS_DIR="$TOPIC_DIR/reports"
  if ! mkdir -p "$REPORTS_DIR" 2>/dev/null; then
    echo "ERROR: Failed to create reports directory: $REPORTS_DIR"
    exit 1
  fi

  # Reconstruct REPORT_PATHS array from state
  if [ -n "${REPORT_PATHS_JSON:-}" ]; then
    mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')
  else
    echo "ERROR: REPORT_PATHS_JSON not found in state"
    exit 1
  fi

  # Display report paths
  for i in "${!REPORT_PATHS[@]}"; do
    REPORT_NUM=$(printf "%03d" $((i + 1)))
    TOPIC_OBJ=$(echo "$RESEARCH_TOPICS_JSON" | jq -r ".[$i]")
    TOPIC_NAME=$(echo "$TOPIC_OBJ" | jq -r '.short_name')
    echo "  Report $REPORT_NUM: ${REPORT_PATHS[$i]}"
    echo "    Topic: $TOPIC_NAME"
  done

  echo ""
  echo "AGENT_INVOCATION: Ready to invoke $TOPIC_COUNT research-specialist agents"
fi
```

**EXECUTE NOW**: For each research topic (if TOPIC_COUNT > 0), USE the Task tool to invoke research-specialist agents:

This part requires Claude to dynamically generate Task invocations based on the research topics. Since markdown cannot contain loops, the invoking Claude instance must expand this section by:

1. Reading RESEARCH_TOPICS_JSON from state (already available from previous bash block)
2. For each topic in the array, create a Task invocation following this pattern:

```
Task {
  subagent_type: "general-purpose"
  description: "Research: <topic.short_name>"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Research Context**:
    - Research Topic: <topic.short_name>
    - Detailed Description: <topic.detailed_description>
    - Research Focus: <topic.research_focus>
    - Feature Context: $SAVED_FEATURE_DESC
    - Output Path: <REPORT_PATH from state>

    **CRITICAL**: Create research report file at EXACT path provided above.

    The path has been PRE-CALCULATED by the orchestrator.
    DO NOT modify the path. DO NOT create files elsewhere.

    Execute research following all guidelines in behavioral file.
  "
}
```

After all research agents complete, verify with bash:

```bash
set +H

# STATE RESTORATION
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  export CLAUDE_PROJECT_DIR
fi

LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"
source "${LIB_DIR}/state-persistence.sh"
source "${LIB_DIR}/metadata-extraction.sh"

# Load workflow state
PLAN_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$PLAN_STATE_ID_FILE")
load_workflow_state "$WORKFLOW_ID"

# VERIFICATION CHECKPOINT: Verify all reports created
TOPIC_COUNT=$(echo "$RESEARCH_TOPICS_JSON" | jq 'length')

if [ "$TOPIC_COUNT" -gt 0 ]; then
  mapfile -t REPORT_PATHS < <(echo "$REPORT_PATHS_JSON" | jq -r '.[]')

  RESEARCH_SUCCESSFUL=true
  for i in "${!REPORT_PATHS[@]}"; do
    REPORT_PATH="${REPORT_PATHS[$i]}"
    TOPIC_OBJ=$(echo "$RESEARCH_TOPICS_JSON" | jq -r ".[$i]")
    TOPIC_NAME=$(echo "$TOPIC_OBJ" | jq -r '.short_name')

    if [ ! -f "$REPORT_PATH" ]; then
      echo "✗ CRITICAL: research-specialist agent failed to create: $REPORT_PATH"
      echo "  Topic: $TOPIC_NAME"
      echo "  Expected path: $REPORT_PATH"
      echo "  Agent behavioral file: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md"
      RESEARCH_SUCCESSFUL=false
    else
      FILE_SIZE=$(wc -c < "$REPORT_PATH")
      echo "✓ Report $((i+1)) created: $FILE_SIZE bytes"
      echo "  Topic: $TOPIC_NAME"
      echo "  Path: $REPORT_PATH"
    fi
  done

  if [ "$RESEARCH_SUCCESSFUL" != "true" ]; then
    echo ""
    echo "ERROR: One or more research agents failed to create reports"
    echo "This is a critical failure. Cannot proceed without research data."
    exit 1
  fi

  # Extract metadata from reports (250-token summaries, 95% context reduction)
  echo ""
  echo "PROGRESS: Extracting metadata from research reports..."

  declare -a RESEARCH_METADATA=()
  for REPORT_PATH in "${REPORT_PATHS[@]}"; do
    if [ -f "$REPORT_PATH" ]; then
      if ! METADATA=$(extract_report_metadata "$REPORT_PATH" 2>&1); then
        echo "WARNING: Failed to extract metadata from: $REPORT_PATH"
        # Fallback to head summary
        METADATA=$(head -c 250 "$REPORT_PATH" | tr '\n' ' ')
      fi

      if [ -n "$METADATA" ]; then
        RESEARCH_METADATA+=("$METADATA")
      fi
    fi
  done

  # Cache metadata for plan-architect context injection
  if [ ${#RESEARCH_METADATA[@]} -gt 0 ]; then
    RESEARCH_METADATA_JSON=$(printf '%s\n' "${RESEARCH_METADATA[@]}" | jq -R . | jq -s .)
    append_workflow_state "RESEARCH_METADATA_JSON" "$RESEARCH_METADATA_JSON"
  fi

  echo "✓ Phase 1.5: Research delegation complete"
  echo "  Reports created: ${#REPORT_PATHS[@]}"
  echo "  Metadata extracted: ${#RESEARCH_METADATA[@]} summaries"
fi
```

## Phase 2: Standards Discovery

**EXECUTE NOW**: Discover CLAUDE.md and extract project standards.

**Documentation**: See `plan-command-guide.md` §3.4 "Phase 2: Standards Discovery" for discovery process, minimal CLAUDE.md template, and cache strategy.

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

**Documentation**: See `plan-command-guide.md` §3.5 "Phase 3: Plan Creation" for agent invocation pattern, workflow-specific context format, verification requirements, and error diagnostic templates.

```bash
echo ""
echo "PROGRESS: Creating implementation plan..."

# STANDARD 12: Reference agent behavioral file ONLY - no inline duplication
# STANDARD 11: Imperative invocation marker
# EXECUTE NOW: USE the Task tool with subagent_type=general-purpose

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

CONTEXT_FILE="$TOPIC_DIR/.plan_context_$$.json"
echo "$CONTEXT_JSON" > "$CONTEXT_FILE"

echo "AGENT_INVOCATION_MARKER: plan-architect"
echo "AGENT_CONTEXT_FILE: $CONTEXT_FILE"
echo "EXPECTED_OUTPUT: $PLAN_PATH"

# Temporary: Create basic plan structure if agent not available
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

# Verify file size ≥500 bytes
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

# Verify checkbox count ≥10
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

**Documentation**: See `plan-command-guide.md` §3.6 "Phase 4: Plan Validation" for validation checks, output format, fail-fast behavior, and graceful degradation strategy.

```bash
echo ""
echo "PROGRESS: Validating plan..."

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
  if ! VALIDATION_REPORT=$(validate_plan "$PLAN_PATH" "$CLAUDE_MD" 2>&1); then
    echo "WARNING: Plan validation encountered issues"
    echo "DIAGNOSTIC: Validation report may be incomplete"
  fi

  ERROR_COUNT=$(echo "$VALIDATION_REPORT" | jq -r '.summary.errors // 0')
  WARNING_COUNT=$(echo "$VALIDATION_REPORT" | jq -r '.summary.warnings // 0')

  echo "  Validation complete:"
  echo "    Errors: $ERROR_COUNT"
  echo "    Warnings: $WARNING_COUNT"

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

  if [ "$WARNING_COUNT" -gt 0 ]; then
    echo ""
    echo "  WARNINGS:"

    STANDARDS_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.standards.valid')
    if [ "$STANDARDS_VALID" = "false" ]; then
      STANDARDS_ISSUES=$(echo "$VALIDATION_REPORT" | jq -r '.standards.issues[]')
      while IFS= read -r issue; do
        [ -n "$issue" ] && echo "    - $issue"
      done <<< "$STANDARDS_ISSUES"
    fi

    TESTS_VALID=$(echo "$VALIDATION_REPORT" | jq -r '.tests.valid')
    if [ "$TESTS_VALID" = "false" ]; then
      TESTS_ISSUES=$(echo "$VALIDATION_REPORT" | jq -r '.tests.issues[]')
      while IFS= read -r issue; do
        [ -n "$issue" ] && echo "    - $issue"
      done <<< "$TESTS_ISSUES"
    fi

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

**Documentation**: See `plan-command-guide.md` §3.7 "Phase 5: Expansion Evaluation" for expansion triggers and recommendation format.

```bash
echo ""
echo "PROGRESS: Evaluating expansion requirements..."

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

**Documentation**: See `plan-command-guide.md` §3.8 "Phase 6: Plan Presentation" for output format and conditional elements.

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
