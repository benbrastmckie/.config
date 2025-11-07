---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch
argument-hint: <feature description> [report-path1] [report-path2] ...
description: Create a detailed implementation plan following project standards, optionally guided by research reports
command-type: primary
dependent-commands: list, update, revise
---

# /plan - Create Implementation Plan

**YOU ARE EXECUTING** as the plan creator.

**Documentation**: See `.claude/docs/guides/plan-command-guide.md` for complete usage guide, research delegation, and complexity analysis.

---

## Phase 0: Parse Arguments and Pre-Analysis

```bash
# Parse feature description and report paths
FEATURE_DESCRIPTION="$1"
REPORT_PATHS=()
shift
while [[ $# -gt 0 ]]; do
  [[ "$1" == *.md ]] && REPORT_PATHS+=("$1")
  shift
done

# Load complexity utilities
source .claude/lib/complexity-utils.sh

# Analyze feature description
ANALYSIS=$(analyze_feature_description "$FEATURE_DESCRIPTION")
ESTIMATED_COMPLEXITY=$(echo "$ANALYSIS" | jq -r '.estimated_complexity')
SUGGESTED_PHASES=$(echo "$ANALYSIS" | jq -r '.suggested_phases')

echo "PROGRESS: Feature complexity estimated at $ESTIMATED_COMPLEXITY"
echo "PROGRESS: Suggested phases: $SUGGESTED_PHASES"
```

## Phase 0.5: Research Delegation (Conditional)

```bash
# Check if research delegation needed
REQUIRES_RESEARCH="false"
[ "$ESTIMATED_COMPLEXITY" -ge 7 ] && REQUIRES_RESEARCH="true"
[[ "$FEATURE_DESCRIPTION" =~ (integrate|migrate|refactor|architecture) ]] && REQUIRES_RESEARCH="true"

if [ "$REQUIRES_RESEARCH" = "true" ]; then
  echo "PROGRESS: Complex feature detected - invoking research agents"
  # Invoke research-specialist agents via Task tool
  # Use forward_message pattern for metadata extraction
  # Cache research reports for plan creation
fi
```

## Phase 1: Standards Discovery and Report Integration

```bash
# Discover CLAUDE.md
CLAUDE_MD=$(find . -name "CLAUDE.md" -type f | head -1)
[ -n "$CLAUDE_MD" ] && source .claude/lib/extract-standards.sh "$CLAUDE_MD"

# Integrate research reports (if provided)
if [ ${#REPORT_PATHS[@]} -gt 0 ]; then
  echo "PROGRESS: Integrating ${#REPORT_PATHS[@]} research reports"
  for report in "${REPORT_PATHS[@]}"; do
    # Extract key findings, recommendations
    # Update report implementation status
  done
fi
```

## Phase 2: Requirements Analysis and Complexity Evaluation

```bash
# Analyze requirements from feature description
REQUIREMENTS=$(extract_requirements "$FEATURE_DESCRIPTION")

# Calculate plan complexity
COMPLEXITY_SCORE=$(calculate_plan_complexity "$REQUIREMENTS" "$SUGGESTED_PHASES")
export COMPLEXITY_SCORE

echo "PROGRESS: Plan complexity: $COMPLEXITY_SCORE"
```

## Phase 3: Topic-Based Location Determination

```bash
# Determine specs directory location
SPECS_DIR=$(find . -type d -name "specs" | head -1)
[ -z "$SPECS_DIR" ] && SPECS_DIR="./specs"

# Find next available topic number
NEXT_NUMBER=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9]*" | 
              sed 's/.*\/\([0-9]\{3\}\).*/\1/' | sort -n | tail -1 | 
              awk '{printf "%03d\n", $1+1}')
[ -z "$NEXT_NUMBER" ] && NEXT_NUMBER="001"

# Create topic directory
TOPIC_SLUG=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | cut -c1-50)
TOPIC_DIR="$SPECS_DIR/${NEXT_NUMBER}_${TOPIC_SLUG}"
mkdir -p "$TOPIC_DIR/plans"
mkdir -p "$TOPIC_DIR/reports"
mkdir -p "$TOPIC_DIR/summaries"

PLAN_PATH="$TOPIC_DIR/plans/${NEXT_NUMBER}_implementation_plan.md"
```

## Phase 4: Plan Creation

```bash
# Create plan file using uniform structure
cat > "$PLAN_PATH" << 'EOF'
# Implementation Plan: <Feature Name>

## Metadata
- **Plan ID**: ${NEXT_NUMBER}
- **Date Created**: $(date +%Y-%m-%d)
- **Type**: [Architecture/Feature/Bugfix/Refactor]
- **Scope**: <Brief scope description>
- **Priority**: [HIGH/MEDIUM/LOW]
- **Complexity**: ${COMPLEXITY_SCORE}/10
- **Estimated Duration**: <N hours>
- **Standards File**: ${CLAUDE_MD}
- **Related Specs**: []
- **Structure Level**: 0 (Single-file)

## Executive Summary

### Problem Statement
<What problem does this solve?>

### Solution Overview
<High-level solution approach>

### Success Criteria
- [ ] <Criterion 1>
- [ ] <Criterion 2>

### Benefits
<Key benefits of implementing this>

---

## Implementation Phases

### Phase 1: <Phase Name>

**Objective**: <What this phase accomplishes>

**Dependencies**: None

**Complexity**: <N>/10

**Duration**: <N hours>

#### Tasks

- [ ] <Task 1>
- [ ] <Task 2>

#### Deliverables

1. <Deliverable 1>
2. <Deliverable 2>

#### Success Criteria

- [ ] <Criterion 1>
- [ ] <Criterion 2>

---

[Additional phases...]

---

## Rollback Strategy

[How to rollback if issues occur]

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| <Risk 1> | <Low/Medium/High> | <Low/Medium/High> | <How to mitigate> |

---

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| <Metric 1> | <Target> | <How to measure> |

---

## Completion Criteria

This plan is complete when:
1. <Criterion 1>
2. <Criterion 2>
EOF

echo "PROGRESS: Plan created at $PLAN_PATH"
```

## Phase 5: Plan Validation and Registration

```bash
# Validate plan structure
.claude/lib/validate-plan.sh "$PLAN_PATH"

# Update SPECS.md registry
if [ -f "$SPECS_DIR/SPECS.md" ]; then
  echo "- [${NEXT_NUMBER}] $FEATURE_DESCRIPTION - $PLAN_PATH" >> "$SPECS_DIR/SPECS.md"
fi

echo "PLAN_CREATED: $PLAN_PATH"
echo "COMPLEXITY: $COMPLEXITY_SCORE"
echo "PHASES: $SUGGESTED_PHASES"
```

---

**Troubleshooting**: See guide for research delegation patterns, complexity analysis, and template usage.
