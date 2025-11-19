---
command-type: primary
dependent-commands: list-reports, report
description: Investigate issues and create diagnostic report without code changes
argument-hint: <issue-description> [report-path1] [report-path2] ...
allowed-tools: Read, Bash, Grep, Glob, WebSearch, WebFetch, TodoWrite, Task
---

# /debug - Investigate and Create Diagnostic Report

**YOU ARE EXECUTING** as the debug investigator.

**Documentation**: See `.claude/docs/guides/debug-command-guide.md` for complete investigation techniques, parallel hypothesis testing, and report structure.

---

## Phase 0: Parse Arguments and Setup

**EXECUTE NOW**: Parse arguments, detect project directory, source libraries, and initialize debug investigation:

```bash
set +H  # CRITICAL: Disable history expansion

# Standard 13: Project Directory Detection
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  # Find project root by searching for .claude directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
  # Fallback to current directory
  if [ -z "$CLAUDE_PROJECT_DIR" ]; then
    CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
export CLAUDE_PROJECT_DIR

# Standard 15: Library Sourcing Order
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source core libraries in dependency order
if [ -f "${LIB_DIR}/error-handling.sh" ]; then
  source "${LIB_DIR}/error-handling.sh"
fi

if [ -f "${LIB_DIR}/verification-helpers.sh" ]; then
  source "${LIB_DIR}/verification-helpers.sh"
fi

# Source debug-specific utilities
if [ -f "${LIB_DIR}/debug-utils.sh" ]; then
  source "${LIB_DIR}/debug-utils.sh"
else
  echo "ERROR: debug-utils.sh not found at ${LIB_DIR}/debug-utils.sh"
  exit 1
fi

if [ -f "${LIB_DIR}/unified-location-detection.sh" ]; then
  source "${LIB_DIR}/unified-location-detection.sh"
fi

# Parse issue description and context reports
ISSUE_DESCRIPTION="$1"
CONTEXT_REPORTS=()
shift
while [[ $# -gt 0 ]]; do
  [[ "$1" == *.md ]] && CONTEXT_REPORTS+=("$1")
  shift
done

# Determine specs directory and report location
SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs"
if [ ! -d "$SPECS_DIR" ]; then
  SPECS_DIR=$(find "$CLAUDE_PROJECT_DIR" -type d -name "specs" | head -1)
  [ -z "$SPECS_DIR" ] && SPECS_DIR="${CLAUDE_PROJECT_DIR}/specs"
fi

# Find next debug report number
NEXT_NUMBER=$(find "$SPECS_DIR" -path "*/debug/*.md" 2>/dev/null |
              sed 's/.*\/\([0-9]\{3\}\)_debug.*/\1/' | sort -n | tail -1 |
              awk '{printf "%03d\n", $1+1}')
[ -z "$NEXT_NUMBER" ] && NEXT_NUMBER="001"

# Determine topic directory (use existing or create new)
TOPIC_DIR=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | sort | tail -1)
if [ -z "$TOPIC_DIR" ]; then
  echo "ERROR: No topic directory found in $SPECS_DIR"
  echo "Create one first with /plan or /research"
  exit 1
fi

if ! mkdir -p "$TOPIC_DIR/debug"; then
  echo "ERROR: Failed to create debug directory at $TOPIC_DIR/debug"
  exit 1
fi

REPORT_PATH="$TOPIC_DIR/debug/${NEXT_NUMBER}_debug.md"

echo "PROGRESS: Debug investigation initialized"
echo "  Project: $CLAUDE_PROJECT_DIR"
echo "  Topic: $TOPIC_DIR"
echo "  Report: $REPORT_PATH"
```

## Phase 1: Initial Investigation

**EXECUTE NOW**: Perform initial investigation and identify potential causes:

```bash
set +H  # CRITICAL: Disable history expansion
echo "PROGRESS: Investigating issue: $ISSUE_DESCRIPTION"

# Read context reports if provided
CONTEXT_FINDINGS=""
for report in "${CONTEXT_REPORTS[@]}"; do
  if [ -f "$report" ]; then
    echo "PROGRESS: Loading context from $report"
    # Extract relevant findings from report
    CONTEXT_FINDINGS="${CONTEXT_FINDINGS}$(head -100 "$report")\n"
  else
    echo "WARNING: Context report not found: $report"
  fi
done

# Standard 16: Return code verification for critical function
if ! POTENTIAL_CAUSES=$(analyze_issue "$ISSUE_DESCRIPTION"); then
  echo "ERROR: analyze_issue function failed"
  exit 1
fi

echo "PROGRESS: Identified potential causes"
echo "$POTENTIAL_CAUSES"
```

## Phase 2: Evidence Collection

**EXECUTE NOW**: Collect evidence from code, git history, and logs:

```bash
set +H  # CRITICAL: Disable history expansion

# Extract error pattern from issue description (first significant word)
ERROR_PATTERN=$(echo "$ISSUE_DESCRIPTION" | grep -o -E '\b[A-Za-z]{4,}\b' | head -1)
if [ -z "$ERROR_PATTERN" ]; then
  ERROR_PATTERN="error"
fi

echo "PROGRESS: Searching for pattern: $ERROR_PATTERN"

# Search for relevant code using debug-utils helper
RELEVANT_FILES=$(collect_file_evidence "$ERROR_PATTERN" "lua,sh,md,py,js,ts" 2>/dev/null || echo "")

if [ -n "$RELEVANT_FILES" ]; then
  echo "PROGRESS: Found $(echo "$RELEVANT_FILES" | wc -l | tr -d ' ') relevant files"

  # Check recent changes
  RECENT_CHANGES=$(collect_git_evidence "$RELEVANT_FILES" 7 2>/dev/null || echo "")
else
  echo "PROGRESS: No files matched pattern, searching broader"
  RELEVANT_FILES=""
  RECENT_CHANGES=""
fi

# Examine error logs
ERROR_LOGS=$(find "${CLAUDE_PROJECT_DIR}" -name "*.log" -mtime -7 -exec grep -l "$ERROR_PATTERN" {} \; 2>/dev/null | head -10)

# Aggregate evidence
EVIDENCE="${RELEVANT_FILES}\n${RECENT_CHANGES}\n${ERROR_LOGS}"

echo "PROGRESS: Evidence collection complete"
```

## Phase 3: Parallel Hypothesis Investigation (Complex Issues)

**EXECUTE NOW**: Evaluate complexity and invoke parallel analysts if needed:

```bash
set +H  # CRITICAL: Disable history expansion

# Standard 16: Return code verification for complexity calculation
if ! COMPLEXITY_SCORE=$(calculate_issue_complexity "$ISSUE_DESCRIPTION" "$POTENTIAL_CAUSES"); then
  echo "ERROR: calculate_issue_complexity function failed"
  COMPLEXITY_SCORE=5  # Default to medium complexity
fi

echo "PROGRESS: Issue complexity score: $COMPLEXITY_SCORE"

# Ensure tmp directory exists
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"

if [ "$COMPLEXITY_SCORE" -ge 6 ]; then
  echo "PROGRESS: Complex issue (score >= 6) - parallel investigation recommended"
  echo "NEEDS_PARALLEL=true" > "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
  echo "COMPLEXITY_SCORE=$COMPLEXITY_SCORE" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
  echo "ISSUE_DESCRIPTION=$ISSUE_DESCRIPTION" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
else
  echo "PROGRESS: Standard complexity (score < 6) - single analysis sufficient"
  echo "NEEDS_PARALLEL=false" > "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
  echo "COMPLEXITY_SCORE=$COMPLEXITY_SCORE" >> "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt"
fi
```

**EXECUTE NOW**: If NEEDS_PARALLEL=true, USE the Task tool to invoke parallel debug-analyst agents.

Task {
  subagent_type: "general-purpose"
  description: "Parallel hypothesis investigation for complex issue"
  prompt: |
    Read state from ${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt

    If NEEDS_PARALLEL=true:
      Read and follow ALL behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

      Investigate multiple hypotheses in parallel for: $ISSUE_DESCRIPTION
      Each hypothesis MUST be investigated independently.
      Aggregate findings and identify most likely root cause.

    If NEEDS_PARALLEL=false:
      Skip parallel investigation, single analysis sufficient.
      Return: HYPOTHESIS_SKIPPED: Single analysis mode

    Return: HYPOTHESIS_COMPLETE: {findings_summary}
}

## Phase 4: Root Cause Analysis

**EXECUTE NOW**: Analyze evidence and determine root cause:

```bash
set +H  # CRITICAL: Disable history expansion

# Standard 16: Return code verification for root cause determination
if ! ROOT_CAUSE=$(determine_root_cause "$POTENTIAL_CAUSES" "$EVIDENCE"); then
  echo "ERROR: determine_root_cause function failed"
  ROOT_CAUSE="Unable to determine root cause - manual investigation required"
fi

echo "PROGRESS: Determined root cause: $ROOT_CAUSE"

# Standard 16: Return code verification for verification
if ! VERIFICATION=$(verify_root_cause "$ROOT_CAUSE"); then
  echo "WARNING: Root cause verification failed"
  VERIFICATION="Verification: UNABLE (verification function error)"
fi

echo "PROGRESS: $VERIFICATION"
```

## Phase 5: Create Debug Report

**EXECUTE NOW**: Generate comprehensive debug report:

```bash
set +H  # CRITICAL: Disable history expansion
cat > "$REPORT_PATH" << 'EOF'
# Debug Report: <Issue Title>

## Metadata
- **Report ID**: ${NEXT_NUMBER}
- **Date**: $(date +%Y-%m-%d)
- **Issue**: <Brief description>
- **Severity**: [CRITICAL/HIGH/MEDIUM/LOW]
- **Status**: Under Investigation
- **Related Files**: <List of files>
- **Context Reports**: <Links to reports used>

## Issue Description

<Detailed description of the problem>

## Investigation Summary

<High-level summary of investigation>

## Evidence Collected

### Code Analysis
<Findings from code analysis>

### Recent Changes
<Relevant git history>

### Error Patterns
<Error logs and patterns found>

## Root Cause Analysis

### Primary Root Cause
<Most likely cause with evidence>

### Contributing Factors
1. <Factor 1>
2. <Factor 2>

### Verification
<How root cause was verified>

## Proposed Solutions

### Solution 1 (Recommended)
**Description**: <Solution description>
**Implementation**: <Steps to implement>
**Pros**: <Benefits>
**Cons**: <Drawbacks>
**Risk**: [LOW/MEDIUM/HIGH]

### Solution 2 (Alternative)
[Same structure as Solution 1]

## Impact Assessment

- **Users Affected**: <Scope>
- **Systems Affected**: <Systems>
- **Data Impact**: <Data concerns>
- **Urgency**: [IMMEDIATE/HIGH/MEDIUM/LOW]

## Next Steps

1. <Step 1>
2. <Step 2>

## Prevention Recommendations

- <Recommendation 1>
- <Recommendation 2>

## References

- <Related issues>
- <Documentation links>
- <External resources>
EOF

echo "DEBUG_REPORT_CREATED: $REPORT_PATH"
```

**MANDATORY VERIFICATION CHECKPOINT**: Verify debug report was created:

```bash
set +H  # CRITICAL: Disable history expansion

# Standard 0: MANDATORY VERIFICATION after file creation
if ! verify_file_created "$REPORT_PATH" "Debug report" "Phase 5"; then
  echo "CRITICAL: Debug report verification failed"
  echo "Expected: $REPORT_PATH"
  ls -la "$(dirname "$REPORT_PATH")" 2>/dev/null || echo "Directory does not exist"
  exit 1
fi
echo " Debug report verified at $REPORT_PATH"
```

## Phase 6: Update Registry and Cross-References

**EXECUTE NOW**: Update registry and add cross-references to related reports:

```bash
set +H  # CRITICAL: Disable history expansion

# Add cross-references to related reports
CROSS_REF_COUNT=0
for report in "${CONTEXT_REPORTS[@]}"; do
  if [ -f "$report" ]; then
    echo "" >> "$report"
    echo "## Related Debug Report" >> "$report"
    echo "- [$NEXT_NUMBER] $ISSUE_DESCRIPTION - $REPORT_PATH" >> "$report"
    CROSS_REF_COUNT=$((CROSS_REF_COUNT + 1))
    echo "PROGRESS: Added cross-reference to $report"
  fi
done

echo ""
echo "==========================================="
echo "DEBUG INVESTIGATION COMPLETE"
echo "==========================================="
echo ""
echo "Report: $REPORT_PATH"
echo "Root Cause: $ROOT_CAUSE"
echo "Complexity Score: $COMPLEXITY_SCORE"
echo "Cross-references Added: $CROSS_REF_COUNT"
echo ""
echo "Next Steps:"
echo "  1. Review the debug report"
echo "  2. Use /fix to implement the solution"
echo "  3. Run tests to verify the fix"
echo ""

# Cleanup temp files
rm -f "${CLAUDE_PROJECT_DIR}/.claude/tmp/debug_state_$$.txt" 2>/dev/null

echo "INVESTIGATION_COMPLETE"
```

---

**Troubleshooting**: See guide for investigation techniques, parallel hypothesis testing, and report creation patterns.
