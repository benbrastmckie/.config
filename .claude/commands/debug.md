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

```bash
# Parse issue description and context reports
ISSUE_DESCRIPTION="$1"
CONTEXT_REPORTS=()
shift
while [[ $# -gt 0 ]]; do
  [[ "$1" == *.md ]] && CONTEXT_REPORTS+=("$1")
  shift
done

# Determine specs directory and report location
SPECS_DIR=$(find . -type d -name "specs" | head -1)
[ -z "$SPECS_DIR" ] && SPECS_DIR="./specs"

# Find next debug report number
NEXT_NUMBER=$(find "$SPECS_DIR" -path "*/debug/*.md" | 
              sed 's/.*\/\([0-9]\{3\}\)_debug.*/\1/' | sort -n | tail -1 | 
              awk '{printf "%03d\n", $1+1}')
[ -z "$NEXT_NUMBER" ] && NEXT_NUMBER="001"

# Determine topic directory (use existing or create new)
TOPIC_DIR=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9]*" | sort | tail -1)
mkdir -p "$TOPIC_DIR/debug"

REPORT_PATH="$TOPIC_DIR/debug/${NEXT_NUMBER}_debug.md"
```

## Phase 1: Initial Investigation

```bash
echo "PROGRESS: Investigating issue: $ISSUE_DESCRIPTION"

# Read context reports if provided
for report in "${CONTEXT_REPORTS[@]}"; do
  echo "PROGRESS: Loading context from $report"
  # Extract relevant findings
done

# Identify potential root causes
POTENTIAL_CAUSES=$(analyze_issue "$ISSUE_DESCRIPTION")
```

## Phase 2: Evidence Collection

```bash
# Search for relevant code
RELEVANT_FILES=$(grep -r -l "$ERROR_PATTERN" . --include="*.lua" --include="*.sh" --include="*.md" 2>/dev/null)

# Check recent changes
RECENT_CHANGES=$(git log --oneline --since="1 week ago" -- $RELEVANT_FILES 2>/dev/null)

# Examine error logs
ERROR_LOGS=$(find . -name "*.log" -mtime -7 -exec grep -l "$ERROR_PATTERN" {} \; 2>/dev/null)
```

## Phase 3: Parallel Hypothesis Investigation (Complex Issues)

```bash
# Check if issue is complex (requires parallel investigation)
COMPLEXITY_SCORE=$(calculate_issue_complexity "$ISSUE_DESCRIPTION" "$POTENTIAL_CAUSES")

if [ "$COMPLEXITY_SCORE" -ge 6 ]; then
  echo "PROGRESS: Complex issue - invoking parallel debug analysts"
  # Invoke 2-3 debug-analyst agents in parallel via Task tool
  # Each investigates different hypothesis
  # Aggregate findings via forward_message pattern
fi
```

## Phase 4: Root Cause Analysis

```bash
# Analyze collected evidence
ROOT_CAUSE=$(determine_root_cause "$POTENTIAL_CAUSES" "$EVIDENCE")

# Verify root cause with additional checks
VERIFICATION=$(verify_root_cause "$ROOT_CAUSE")
```

## Phase 5: Create Debug Report

```bash
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

## Phase 6: Update Registry and Cross-References

```bash
# Invoke spec-updater agent to update registry
# Fallback: Direct registry update if agent fails

# Add cross-references to related reports
for report in "${CONTEXT_REPORTS[@]}"; do
  echo "## Related Debug Report" >> "$report"
  echo "- [$NEXT_NUMBER] $ISSUE_DESCRIPTION - $REPORT_PATH" >> "$report"
done

echo "INVESTIGATION_COMPLETE"
echo "REPORT: $REPORT_PATH"
echo "ROOT_CAUSE: $ROOT_CAUSE"
```

---

**Troubleshooting**: See guide for investigation techniques, parallel hypothesis testing, and report creation patterns.
