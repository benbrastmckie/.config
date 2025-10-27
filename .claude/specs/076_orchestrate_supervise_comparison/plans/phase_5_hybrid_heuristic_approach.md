# Phase 5: Hybrid Heuristic-Agent Approach

## Phase Metadata
- **Phase Number**: 5
- **Parent Plan**: 002_optimize_supervise_location_detection.md
- **Topic**: 076_orchestrate_supervise_comparison
- **Dependencies**: [4] (Comprehensive Testing and Validation)
- **Status**: Pending
- **Objective**: Add intelligent fallback to agent for complex edge cases
- **Complexity**: 6/10 (medium-high)
- **Estimated Time**: 2-3 hours
- **Risk**: Medium
- **Priority**: MEDIUM (enhances robustness for rare cases)

## Overview

This phase implements an intelligent heuristic that determines whether a workflow requires full agent-based location analysis or can use utility functions. The goal is to maintain 90%+ utility function usage (fast, zero-cost) while providing robust agent fallback for the 10% of complex cases that need deeper analysis.

**Key Insight**: Most workflows follow simple patterns (research topic X, implement feature Y, fix bug Z) that don't require AI reasoning. Complex workflows involving multi-system refactors, directory migrations, or ambiguous scope detection benefit from agent analysis.

**Success Metrics**:
- 90%+ workflows use utility functions (low false positive rate)
- <5% workflows incorrectly use utilities when agent needed (low false negative rate)
- Overall token reduction maintained at 75-85% (weighted average)
- Zero regression in location detection accuracy

## Technical Design

### Heuristic Algorithm Design

The complexity heuristic evaluates workflow descriptions against multiple criteria to determine if agent analysis is required.

#### Decision Criteria

**USE AGENT** (complex workflow) if ANY of:
1. **Multi-system migration keywords**: "migrate .* from .* to", "move .* to different directory"
2. **Multi-module refactoring**: "refactor.*multiple", "refactor.*system", "refactor.*(and|,).*"
3. **Directory restructuring**: "reorganize", "restructure", "consolidate directories"
4. **Ambiguous scope**: Contains conflicting module names from different directory trees
5. **Cross-project changes**: Mentions multiple top-level directories (nvim/, .claude/, specs/)

**USE UTILITIES** (simple workflow) if ALL of:
1. Single feature implementation ("add", "implement", "create")
2. Single research topic ("research", "investigate", "analyze")
3. Single bug fix ("fix", "debug", "resolve")
4. Single refactor with clear scope ("refactor authentication module")
5. No migration or restructuring keywords

#### Heuristic Implementation

```bash
#!/usr/bin/env bash
# Complexity detection function for location determination

needs_complex_location_analysis() {
  local workflow_desc="$1"
  local complexity_score=0
  local reasons=()

  # Convert to lowercase for case-insensitive matching
  local desc_lower=$(echo "$workflow_desc" | tr '[:upper:]' '[:lower:]')

  # Criterion 1: Multi-system migration (+3 complexity)
  if echo "$desc_lower" | grep -Eq "migrate.*(from|to)|move.*(directory|system|module)"; then
    complexity_score=$((complexity_score + 3))
    reasons+=("multi-system migration detected")
  fi

  # Criterion 2: Multi-module refactoring (+2 complexity)
  if echo "$desc_lower" | grep -Eq "refactor.*(multiple|system|infrastructure)"; then
    complexity_score=$((complexity_score + 2))
    reasons+=("multi-module refactor detected")
  fi

  # Check for multiple refactor targets (e.g., "refactor auth, logging, and testing")
  if echo "$desc_lower" | grep -Eq "refactor.*,.*,|refactor.*and.*and"; then
    complexity_score=$((complexity_score + 2))
    reasons+=("multiple refactor targets detected")
  fi

  # Criterion 3: Directory restructuring (+3 complexity)
  if echo "$desc_lower" | grep -Eq "reorganize|restructure|consolidate.*(directories|modules|structure)"; then
    complexity_score=$((complexity_score + 3))
    reasons+=("directory restructuring detected")
  fi

  # Criterion 4: Cross-project changes (+2 complexity)
  # Count mentions of top-level directories
  local dir_count=0
  echo "$desc_lower" | grep -q "nvim/" && dir_count=$((dir_count + 1))
  echo "$desc_lower" | grep -q "\.claude/" && dir_count=$((dir_count + 1))
  echo "$desc_lower" | grep -q "specs/" && dir_count=$((dir_count + 1))

  if [ "$dir_count" -ge 2 ]; then
    complexity_score=$((complexity_score + 2))
    reasons+=("cross-project changes ($dir_count directories)")
  fi

  # Criterion 5: Ambiguous scope detection (+1 complexity)
  # Very long descriptions often indicate complex scope
  local word_count=$(echo "$workflow_desc" | wc -w)
  if [ "$word_count" -gt 20 ]; then
    complexity_score=$((complexity_score + 1))
    reasons+=("long description ($word_count words)")
  fi

  # Decision threshold: complexity >= 3 requires agent
  if [ "$complexity_score" -ge 3 ]; then
    echo "COMPLEXITY: $complexity_score/10 - AGENT REQUIRED"
    echo "REASONS: ${reasons[*]}"
    return 0  # true: use agent
  else
    echo "COMPLEXITY: $complexity_score/10 - UTILITIES SUFFICIENT"
    return 1  # false: use utilities
  fi
}
```

#### Heuristic Tuning Parameters

```bash
# Configuration for complexity detection
# Location: .claude/lib/location-detection-config.sh

# Complexity scoring weights
MIGRATION_WEIGHT=3        # Multi-system migrations (highest complexity)
REFACTOR_WEIGHT=2         # Multi-module refactors
RESTRUCTURE_WEIGHT=3      # Directory reorganization
CROSS_PROJECT_WEIGHT=2    # Changes spanning multiple directories
LONG_DESC_WEIGHT=1        # Ambiguous scope from length

# Decision threshold
AGENT_THRESHOLD=3         # Scores >= 3 require agent analysis

# Tuning guidelines:
# - Research-heavy projects: Lower threshold to 2 (more agent usage)
# - Simple web apps: Raise threshold to 4 (more utility usage)
# - Mission-critical: Lower threshold to 2 (prefer safety)
```

### Complete Implementation

#### Component 1: Enhanced supervise.md Phase 0

Replace STEP 3 (agent invocation) with conditional logic:

```bash
# Phase 0: Project Location and Path Pre-Calculation
# STEP 2.5: Evaluate workflow complexity

# Source complexity detection function
source "${CLAUDE_CONFIG}/.claude/lib/location-detection-heuristic.sh"

echo "Evaluating workflow complexity..."
if needs_complex_location_analysis "$WORKFLOW_DESCRIPTION"; then
  echo ""
  echo "🔍 Complex workflow detected - invoking location-specialist agent"
  echo "   Using Haiku 4.5 for cost-efficient analysis"
  echo ""

  # STEP 3a: Use agent for complex workflows
  # (existing Task tool invocation from current supervise.md)
  Task {
    subagent_type: "general-purpose"
    description: "Determine project location for complex workflow"
    model: "haiku-4.5"  # From Phase 0 optimization
    prompt: "
      Read behavioral guidelines: .claude/agents/location-specialist.md

      Workflow Description: ${WORKFLOW_DESCRIPTION}

      Determine the appropriate location using the deepest directory that encompasses the workflow scope.

      Return ONLY these exact lines:
      LOCATION: <path>
      TOPIC_NUMBER: <NNN>
      TOPIC_NAME: <snake_case_name>
    "
  }

  # Parse agent output (existing code)
  LOCATION=$(echo "$AGENT_OUTPUT" | grep "LOCATION:" | cut -d: -f2- | xargs)
  TOPIC_NUM=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NUMBER:" | cut -d: -f2 | xargs)
  TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME:" | cut -d: -f2- | xargs)

  # Log agent usage
  echo "$(date '+%Y-%m-%d %H:%M:%S') | /supervise | haiku-4.5-agent | ${TOPIC_NUM}_${TOPIC_NAME} | 75.6k tokens | ${EXEC_TIME}s" \
    >> .claude/data/logs/location-detection.log

else
  echo ""
  echo "⚡ Simple workflow detected - using utility functions"
  echo "   Zero AI cost, instant execution"
  echo ""

  # STEP 3b: Use utilities for simple workflows
  # (utility function code from Phase 2)
  source "${CLAUDE_CONFIG}/.claude/lib/topic-utils.sh"
  source "${CLAUDE_CONFIG}/.claude/lib/detect-project-dir.sh"

  # Get project root
  PROJECT_ROOT="${CLAUDE_PROJECT_DIR}"

  # Determine specs directory
  if [ -d "${PROJECT_ROOT}/.claude/specs" ]; then
    SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
  elif [ -d "${PROJECT_ROOT}/specs" ]; then
    SPECS_ROOT="${PROJECT_ROOT}/specs"
  else
    SPECS_ROOT="${PROJECT_ROOT}/.claude/specs"
    mkdir -p "$SPECS_ROOT"
  fi

  # Calculate topic metadata
  TOPIC_NUM=$(get_next_topic_number "$SPECS_ROOT")
  TOPIC_NAME=$(sanitize_topic_name "$WORKFLOW_DESCRIPTION")
  LOCATION="${PROJECT_ROOT}"

  # Log utility usage
  echo "$(date '+%Y-%m-%d %H:%M:%S') | /supervise | utility-functions | ${TOPIC_NUM}_${TOPIC_NAME} | 0.5k tokens | ${EXEC_TIME}s" \
    >> .claude/data/logs/location-detection.log
fi

# Validate required fields (same for both paths)
if [ -z "$LOCATION" ] || [ -z "$TOPIC_NUM" ] || [ -z "$TOPIC_NAME" ]; then
  echo "❌ ERROR: Location detection failed to provide required metadata"
  echo "   LOCATION: $LOCATION"
  echo "   TOPIC_NUM: $TOPIC_NUM"
  echo "   TOPIC_NAME: $TOPIC_NAME"
  exit 1
fi

# Continue with STEP 5 (directory creation) - same for both paths
TOPIC_PATH="${SPECS_ROOT}/${TOPIC_NUM}_${TOPIC_NAME}"
# ... (existing directory creation code)
```

#### Component 2: Heuristic Library

Create `.claude/lib/location-detection-heuristic.sh`:

```bash
#!/usr/bin/env bash
# Location Detection Complexity Heuristic
# Determines if workflow requires agent analysis or utility functions suffice

# Source configuration (tunable thresholds)
HEURISTIC_CONFIG="${CLAUDE_CONFIG}/.claude/lib/location-detection-config.sh"
if [ -f "$HEURISTIC_CONFIG" ]; then
  source "$HEURISTIC_CONFIG"
else
  # Default configuration
  MIGRATION_WEIGHT=3
  REFACTOR_WEIGHT=2
  RESTRUCTURE_WEIGHT=3
  CROSS_PROJECT_WEIGHT=2
  LONG_DESC_WEIGHT=1
  AGENT_THRESHOLD=3
fi

needs_complex_location_analysis() {
  local workflow_desc="$1"
  local complexity_score=0
  local reasons=()

  # Convert to lowercase for case-insensitive matching
  local desc_lower=$(echo "$workflow_desc" | tr '[:upper:]' '[:lower:]')

  # Criterion 1: Multi-system migration
  if echo "$desc_lower" | grep -Eq "migrate.*(from|to)|move.*(directory|system|module)"; then
    complexity_score=$((complexity_score + MIGRATION_WEIGHT))
    reasons+=("multi-system migration")
  fi

  # Criterion 2: Multi-module refactoring
  if echo "$desc_lower" | grep -Eq "refactor.*(multiple|system|infrastructure)"; then
    complexity_score=$((complexity_score + REFACTOR_WEIGHT))
    reasons+=("multi-module refactor")
  fi

  if echo "$desc_lower" | grep -Eq "refactor.*,.*,|refactor.*and.*and"; then
    complexity_score=$((complexity_score + REFACTOR_WEIGHT))
    reasons+=("multiple refactor targets")
  fi

  # Criterion 3: Directory restructuring
  if echo "$desc_lower" | grep -Eq "reorganize|restructure|consolidate.*(directories|modules|structure)"; then
    complexity_score=$((complexity_score + RESTRUCTURE_WEIGHT))
    reasons+=("directory restructuring")
  fi

  # Criterion 4: Cross-project changes
  local dir_count=0
  echo "$desc_lower" | grep -q "nvim/" && dir_count=$((dir_count + 1))
  echo "$desc_lower" | grep -q "\.claude/" && dir_count=$((dir_count + 1))
  echo "$desc_lower" | grep -q "specs/" && dir_count=$((dir_count + 1))

  if [ "$dir_count" -ge 2 ]; then
    complexity_score=$((complexity_score + CROSS_PROJECT_WEIGHT))
    reasons+=("cross-project ($dir_count dirs)")
  fi

  # Criterion 5: Ambiguous scope (long description)
  local word_count=$(echo "$workflow_desc" | wc -w)
  if [ "$word_count" -gt 20 ]; then
    complexity_score=$((complexity_score + LONG_DESC_WEIGHT))
    reasons+=("long description ($word_count words)")
  fi

  # Decision logic
  if [ "$complexity_score" -ge "$AGENT_THRESHOLD" ]; then
    echo "COMPLEXITY: $complexity_score/10 - AGENT REQUIRED" >&2
    echo "REASONS: ${reasons[*]}" >&2
    return 0  # true: use agent
  else
    echo "COMPLEXITY: $complexity_score/10 - UTILITIES SUFFICIENT" >&2
    return 1  # false: use utilities
  fi
}

# Export function for use in other scripts
export -f needs_complex_location_analysis
```

#### Component 3: Configuration File

Create `.claude/lib/location-detection-config.sh`:

```bash
#!/usr/bin/env bash
# Location Detection Heuristic Configuration

# Complexity Scoring Weights
# Higher weights = more likely to trigger agent usage
MIGRATION_WEIGHT=3        # Multi-system migrations (highest risk)
REFACTOR_WEIGHT=2         # Multi-module refactors (medium risk)
RESTRUCTURE_WEIGHT=3      # Directory reorganization (high risk)
CROSS_PROJECT_WEIGHT=2    # Changes spanning multiple directories (medium risk)
LONG_DESC_WEIGHT=1        # Ambiguous scope from length (low risk)

# Agent Decision Threshold
# Workflows with complexity >= this threshold use agent
AGENT_THRESHOLD=3

# Performance Tuning Guidelines:
#
# For Research-Heavy Projects (detailed exploration needed):
#   AGENT_THRESHOLD=2
#   Increases agent usage to 20-25% of workflows
#   Better handling of ambiguous research topics
#
# For Simple Web Applications (predictable patterns):
#   AGENT_THRESHOLD=4
#   Reduces agent usage to 5% of workflows
#   Maximum performance optimization
#
# For Mission-Critical Systems (safety over speed):
#   AGENT_THRESHOLD=2
#   MIGRATION_WEIGHT=4
#   RESTRUCTURE_WEIGHT=4
#   Prefer agent analysis for any complexity

# User Override Environment Variables
# Set these to override configuration at runtime:
#   LOCATION_FORCE_AGENT=1    # Force agent usage regardless of heuristic
#   LOCATION_FORCE_UTILS=1    # Force utility usage (dangerous for complex workflows)

export MIGRATION_WEIGHT REFACTOR_WEIGHT RESTRUCTURE_WEIGHT
export CROSS_PROJECT_WEIGHT LONG_DESC_WEIGHT AGENT_THRESHOLD
```

## Testing Strategy

### Test Categories

#### Category 1: Simple Workflows (Should Use Utilities)

**Expected**: 40/40 use utilities (100%)

Test cases:
```bash
# Research workflows (10 tests)
/supervise "research authentication patterns"
/supervise "investigate database migration strategies"
/supervise "analyze performance optimization techniques"
/supervise "research GraphQL API design best practices"
/supervise "study React component composition patterns"
/supervise "explore caching strategies for Redis"
/supervise "investigate OAuth2 implementation details"
/supervise "research microservices architecture patterns"
/supervise "analyze test-driven development approaches"
/supervise "study Docker containerization best practices"

# Feature implementations (10 tests)
/supervise "implement OAuth2 authentication"
/supervise "add user profile management"
/supervise "create admin dashboard"
/supervise "implement password reset flow"
/supervise "add email notification system"
/supervise "create API rate limiting"
/supervise "implement file upload handling"
/supervise "add search functionality"
/supervise "create user commenting system"
/supervise "implement data export feature"

# Bug fixes (10 tests)
/supervise "fix token refresh race condition"
/supervise "debug session timeout issues"
/supervise "resolve CORS configuration errors"
/supervise "fix memory leak in image processor"
/supervise "debug infinite loop in pagination"
/supervise "resolve database connection pooling issue"
/supervise "fix CSS layout bug in mobile view"
/supervise "debug WebSocket reconnection logic"
/supervise "resolve timezone handling error"
/supervise "fix form validation edge case"

# Single-module refactors (10 tests)
/supervise "refactor authentication module"
/supervise "optimize database queries"
/supervise "refactor testing infrastructure"
/supervise "clean up error handling in API layer"
/supervise "refactor user service for better performance"
/supervise "simplify configuration management"
/supervise "refactor logging system"
/supervise "optimize image processing pipeline"
/supervise "refactor React component hierarchy"
/supervise "clean up dependency injection"
```

Validation for each:
```bash
# Check that utility functions were used
grep "utility-functions" .claude/data/logs/location-detection.log | tail -1

# Verify token usage <1k
# Verify execution time <1s
# Verify correct location detected
# Verify all 6 subdirectories created
```

#### Category 2: Complex Workflows (Should Use Agent)

**Expected**: 8/10 use agent (80-90%)

Test cases:
```bash
# Multi-system migrations (3 tests)
/supervise "migrate authentication system from nvim/ to .claude/ and update all imports"
/supervise "move database utilities to shared library and refactor module dependencies"
/supervise "consolidate testing infrastructure from specs/ to .claude/tests/ directory"

# Multi-module refactors (3 tests)
/supervise "refactor authentication, authorization, and session management modules"
/supervise "restructure logging, monitoring, and error reporting systems"
/supervise "refactor testing, documentation, and deployment infrastructure"

# Directory restructuring (2 tests)
/supervise "reorganize project structure to separate frontend and backend code"
/supervise "consolidate duplicate utilities across nvim/ and .claude/ directories"

# Cross-project changes (2 tests)
/supervise "update authentication in both nvim plugins and .claude commands"
/supervise "refactor shared utilities used by specs/ and nvim/lua/ modules"
```

Validation for each:
```bash
# Check that agent was invoked
grep "haiku-4.5-agent" .claude/data/logs/location-detection.log | tail -1

# Verify token usage ~75k (agent with Haiku 4.5)
# Verify execution time ~5-6s (Haiku speedup vs Sonnet)
# Verify correct location detected (deeper analysis may find different location)
# Verify all 6 subdirectories created
```

#### Category 3: Edge Cases (Heuristic Boundary Testing)

**Expected**: Mixed usage based on complexity score

Test cases:
```bash
# Borderline complexity (score ~2-3)
/supervise "refactor authentication and update tests"  # Score: 2 (utilities)
/supervise "research multi-tenant architecture patterns"  # Score: 1 (utilities)
/supervise "implement feature flags and A/B testing"  # Score: 1 (utilities)
/supervise "migrate logging from console to structured format"  # Score: 3 (agent)

# Minimal description
/supervise "r"  # Score: 0 (utilities, uses generic "workflow" name)

# Maximal description (>20 words)
/supervise "Research the implementation of a comprehensive multi-tenant authentication and authorization system with role-based access control, OAuth2 integration, session management, and audit logging capabilities"  # Score: 1 (utilities, research is simple despite length)

# Ambiguous module references
/supervise "fix authentication issues in both frontend and backend"  # Score: 2 (utilities)
/supervise "update database schema and migrate existing data"  # Score: 3 (agent, migration keyword)
```

Validation:
```bash
# Manual review of heuristic decisions
# Verify complexity scores match expectations
# Identify false positives (should use utilities, used agent)
# Identify false negatives (should use agent, used utilities)
```

### Cost/Performance Analysis Methodology

#### Baseline Measurements (Before Hybrid)

```bash
# Run 100 diverse workflows with utilities-only approach (from Phase 4)
# Record: token usage, execution time, accuracy

# Expected results:
# - Token usage: 8.5k avg (utilities)
# - Execution time: 0.7s avg
# - Accuracy: 95-98% (some complex workflows fail)
```

#### Hybrid Measurements (After Phase 5)

```bash
# Run same 100 workflows with hybrid approach
# Record: token usage, execution time, accuracy, method used

# Expected results:
# - Token usage: 15.2k avg (weighted: 90% @ 8.5k, 10% @ 75.6k)
# - Execution time: 1.1s avg (weighted: 90% @ 0.7s, 10% @ 5.2s)
# - Accuracy: 99-100% (agent handles complex cases)
# - Method distribution: 90% utilities, 10% agent
```

#### Cost Analysis

```bash
# Calculate costs per 100 invocations:

# Utilities only (95% accuracy):
#   Cost: 100 * $0.034 = $3.40
#   Failures: 5 workflows (need manual intervention)
#   Manual cost: 5 * 10 minutes * $X/hour = additional cost

# Hybrid approach (99% accuracy):
#   Utility cost: 90 * $0.034 = $3.06
#   Agent cost: 10 * $0.23 (Haiku 4.5) = $2.30
#   Total: $5.36
#   Failures: 1 workflow
#   Manual cost: 1 * 10 minutes * $X/hour = minimal

# Cost increase: $5.36 - $3.40 = $1.96 per 100 invocations
# Benefit: 4 fewer manual interventions (80% reduction in failures)
# ROI: Positive if manual intervention costs > $0.49 per workflow
```

#### Performance Comparison Dashboard

Create `.claude/scripts/hybrid_performance_analysis.sh`:

```bash
#!/usr/bin/env bash
# Analyze hybrid heuristic performance vs utilities-only

LOG_FILE=".claude/data/logs/location-detection.log"

echo "Hybrid Heuristic Performance Analysis"
echo "====================================="
echo ""

# Count method distribution
TOTAL=$(wc -l < "$LOG_FILE")
UTILS=$(grep -c "utility-functions" "$LOG_FILE")
AGENT=$(grep -c "haiku-4.5-agent" "$LOG_FILE")

echo "Method Distribution:"
echo "  Utility functions: $UTILS ($((UTILS * 100 / TOTAL))%)"
echo "  Haiku 4.5 agent: $AGENT ($((AGENT * 100 / TOTAL))%)"
echo ""

# Average token usage by method
echo "Token Usage (average):"
awk -F'|' '/utility-functions/ {gsub(/k tokens/, "", $5); sum+=$5; count++} END {printf "  Utilities: %.1fk tokens\n", sum/count}' "$LOG_FILE"
awk -F'|' '/haiku-4.5-agent/ {gsub(/k tokens/, "", $5); sum+=$5; count++} END {printf "  Agent: %.1fk tokens\n", sum/count}' "$LOG_FILE"

# Weighted average
UTILS_AVG=$(awk -F'|' '/utility-functions/ {gsub(/k tokens/, "", $5); sum+=$5; count++} END {print sum/count}' "$LOG_FILE")
AGENT_AVG=$(awk -F'|' '/haiku-4.5-agent/ {gsub(/k tokens/, "", $5); sum+=$5; count++} END {print sum/count}' "$LOG_FILE")
WEIGHTED=$(echo "scale=1; ($UTILS * $UTILS_AVG + $AGENT * $AGENT_AVG) / $TOTAL" | bc)
echo "  Weighted average: ${WEIGHTED}k tokens"
echo ""

# Execution time analysis
echo "Execution Time (average):"
awk -F'|' '/utility-functions/ {gsub(/s/, "", $6); sum+=$6; count++} END {printf "  Utilities: %.2fs\n", sum/count}' "$LOG_FILE"
awk -F'|' '/haiku-4.5-agent/ {gsub(/s/, "", $6); sum+=$6; count++} END {printf "  Agent: %.2fs\n", sum/count}' "$LOG_FILE"

# Cost analysis (last 100 invocations)
echo ""
echo "Cost Analysis (last 100 invocations):"
RECENT_UTILS=$(tail -100 "$LOG_FILE" | grep -c "utility-functions")
RECENT_AGENT=$(tail -100 "$LOG_FILE" | grep -c "haiku-4.5-agent")

UTILS_COST=$(echo "scale=2; $RECENT_UTILS * 0.034" | bc)
AGENT_COST=$(echo "scale=2; $RECENT_AGENT * 0.23" | bc)
TOTAL_COST=$(echo "scale=2; $UTILS_COST + $AGENT_COST" | bc)

echo "  Utilities: \$$UTILS_COST ($RECENT_UTILS invocations)"
echo "  Agent: \$$AGENT_COST ($RECENT_AGENT invocations)"
echo "  Total: \$$TOTAL_COST"
echo ""

# Compare to baseline
BASELINE_COST=$(echo "scale=2; 100 * 0.68" | bc)
SAVINGS=$(echo "scale=2; $BASELINE_COST - $TOTAL_COST" | bc)
SAVINGS_PCT=$(echo "scale=1; ($SAVINGS / $BASELINE_COST) * 100" | bc)

echo "  Baseline (Sonnet agent only): \$$BASELINE_COST"
echo "  Savings: \$$SAVINGS (${SAVINGS_PCT}%)"
```

### Configuration and Tuning Procedures

#### Tuning Process

**Step 1: Establish Baseline Performance**

```bash
# Run comprehensive test suite (50 workflows)
.claude/tests/test_hybrid_location_detection.sh

# Record metrics:
# - False positive rate (agent used, utilities would work)
# - False negative rate (utilities used, agent needed)
# - Overall accuracy
# - Cost per 100 invocations
```

**Step 2: Adjust Thresholds Based on Results**

```bash
# Edit .claude/lib/location-detection-config.sh

# If false positive rate > 15% (too much agent usage):
#   Increase AGENT_THRESHOLD from 3 to 4
#   Reduce LONG_DESC_WEIGHT from 1 to 0

# If false negative rate > 5% (utilities failing):
#   Decrease AGENT_THRESHOLD from 3 to 2
#   Increase MIGRATION_WEIGHT from 3 to 4
#   Increase RESTRUCTURE_WEIGHT from 3 to 4

# If cross-project changes failing:
#   Increase CROSS_PROJECT_WEIGHT from 2 to 3
```

**Step 3: Retest After Adjustments**

```bash
# Run test suite again
.claude/tests/test_hybrid_location_detection.sh

# Compare metrics to Step 1
# Iterate until acceptable performance achieved:
#   False positive rate: <10%
#   False negative rate: <3%
#   Overall accuracy: >98%
```

**Step 4: Production Monitoring**

```bash
# Weekly review of hybrid performance
.claude/scripts/hybrid_performance_analysis.sh

# Look for trends:
# - Agent usage increasing (heuristic may be too sensitive)
# - Manual corrections increasing (heuristic missing complex cases)
# - Cost creeping up (adjust thresholds to favor utilities)
```

#### User Override Mechanisms

**Environment Variable Overrides**:

```bash
# Force agent usage for specific workflow
LOCATION_FORCE_AGENT=1 /supervise "ambiguous workflow description"

# Force utility usage (dangerous, only for testing)
LOCATION_FORCE_UTILS=1 /supervise "complex migration workflow"
```

**Command-Line Flags** (optional enhancement):

Modify supervise.md to accept flags:

```bash
# Usage: /supervise [--force-agent|--force-utils] "description"

if [[ "$1" == "--force-agent" ]]; then
  FORCE_AGENT=1
  shift
elif [[ "$1" == "--force-utils" ]]; then
  FORCE_UTILS=1
  shift
fi

WORKFLOW_DESCRIPTION="$1"

# In complexity check:
if [ "$FORCE_AGENT" = "1" ]; then
  echo "User override: forcing agent usage"
  USE_AGENT=1
elif [ "$FORCE_UTILS" = "1" ]; then
  echo "User override: forcing utility usage"
  USE_AGENT=0
elif needs_complex_location_analysis "$WORKFLOW_DESCRIPTION"; then
  USE_AGENT=1
else
  USE_AGENT=0
fi
```

## Edge Case Handling and Fallback Scenarios

### Edge Case 1: Heuristic Ambiguity (Score = Threshold)

**Scenario**: Workflow complexity score exactly equals threshold (e.g., 3)

**Example**: "refactor authentication and add new OAuth providers" (score: 2 for refactor + 1 for long = 3)

**Handling**:
```bash
# In needs_complex_location_analysis():
if [ "$complexity_score" -ge "$AGENT_THRESHOLD" ]; then
  # >= ensures threshold scores use agent (conservative choice)
  return 0  # use agent
fi
```

**Rationale**: When ambiguous, prefer agent (safety over speed). Cost difference minimal for borderline cases.

### Edge Case 2: Agent Failure After Heuristic Selection

**Scenario**: Heuristic selects agent, but agent fails (API error, timeout, invalid output)

**Handling**:
```bash
# In supervise.md Phase 0, after agent invocation:
if [ -z "$LOCATION" ] || [ -z "$TOPIC_NUM" ] || [ -z "$TOPIC_NAME" ]; then
  echo "⚠️  Agent failed - falling back to utility functions"

  # Fallback to utilities
  source "${CLAUDE_CONFIG}/.claude/lib/topic-utils.sh"
  # ... (utility function code)

  # Log fallback for analysis
  echo "$(date) | AGENT_FAILURE | Fallback to utilities | $WORKFLOW_DESCRIPTION" \
    >> .claude/data/logs/location-detection-errors.log
fi
```

**Rationale**: Graceful degradation. Utilities provide basic functionality even if agent unavailable.

### Edge Case 3: Utility Failure After Heuristic Selection

**Scenario**: Heuristic selects utilities, but utilities fail (permissions, invalid spec directory)

**Handling**:
```bash
# In utility functions (topic-utils.sh):
get_next_topic_number() {
  local specs_root="$1"

  # Verify specs_root exists
  if [ ! -d "$specs_root" ]; then
    echo "ERROR: Specs root does not exist: $specs_root" >&2
    return 1
  fi

  # Verify read permissions
  if [ ! -r "$specs_root" ]; then
    echo "ERROR: No read permission for specs root: $specs_root" >&2
    return 1
  fi

  # ... (rest of function)
}

# In supervise.md, after utility invocation:
if [ -z "$TOPIC_NUM" ]; then
  echo "❌ ERROR: Utility functions failed - cannot determine topic number"
  echo "   This is likely a file system permissions issue"
  echo "   Check that $SPECS_ROOT exists and is readable"
  exit 1
  # Note: No fallback to agent here (utilities should never fail)
fi
```

**Rationale**: Utilities failing indicates system issue (permissions, disk space), not complexity. Failing fast better than invoking agent.

### Edge Case 4: Concurrent Invocations (Race Condition)

**Scenario**: Two `/supervise` commands run simultaneously, both calculate same topic number

**Example**:
```
Terminal 1: /supervise "research auth" → calculates topic 082
Terminal 2: /supervise "implement API" → calculates topic 082 (same!)
```

**Handling** (file locking):

```bash
# In topic-utils.sh:
get_next_topic_number() {
  local specs_root="$1"
  local lockfile="${specs_root}/.topic-number.lock"

  # Acquire lock with timeout
  local timeout=10
  local elapsed=0
  while ! mkdir "$lockfile" 2>/dev/null; do
    sleep 0.5
    elapsed=$((elapsed + 1))
    if [ $elapsed -ge $((timeout * 2)) ]; then
      echo "ERROR: Timeout acquiring topic number lock" >&2
      return 1
    fi
  done

  # Critical section: calculate topic number
  local max_num=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_* 2>/dev/null | \
    sed 's/.*\/\([0-9][0-9][0-9]\)_.*/\1/' | \
    sort -n | tail -1)

  if [ -z "$max_num" ]; then
    echo "001"
  else
    printf "%03d" $((10#$max_num + 1))
  fi

  # Release lock
  rmdir "$lockfile"
}
```

**Rationale**: File locking prevents race conditions. Essential for parallel `/orchestrate` workflows.

### Edge Case 5: Invalid Workflow Description

**Scenario**: User provides empty string, special characters only, or extremely long description

**Examples**:
```bash
/supervise ""  # Empty
/supervise "!@#$%^&*()"  # Special chars only
/supervise "$(cat very_long_file.txt)"  # >1000 words
```

**Handling**:
```bash
# In supervise.md Phase 0 STEP 1:
WORKFLOW_DESCRIPTION="$1"

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description required"
  exit 1
fi

# Sanitize before processing
WORKFLOW_DESCRIPTION=$(echo "$WORKFLOW_DESCRIPTION" | \
  tr -cd '[:alnum:][:space:][:punct:]' | \
  cut -c1-500)  # Truncate to 500 chars

if [ -z "$WORKFLOW_DESCRIPTION" ]; then
  echo "ERROR: Workflow description contains no valid characters"
  exit 1
fi

# In sanitize_topic_name() from topic-utils.sh:
sanitize_topic_name() {
  local raw_name="$1"
  local sanitized=$(echo "$raw_name" | \
    tr '[:upper:]' '[:lower:]' | \
    tr ' ' '_' | \
    sed 's/[^a-z0-9_]//g' | \
    sed 's/^_*//;s/_*$//' | \
    cut -c1-50)

  # Fallback to generic name if sanitization produces empty string
  if [ -z "$sanitized" ]; then
    sanitized="workflow"
  fi

  echo "$sanitized"
}
```

**Rationale**: Graceful handling of edge cases. Default to "workflow" if description unusable.

### Edge Case 6: Heuristic Miscategorization (False Negative)

**Scenario**: Complex workflow scored as simple, utilities fail to determine correct location

**Example**: "update authentication across services" (score: 1, but actually multi-system)

**Detection**:
```bash
# User reports incorrect location
# Review .claude/data/logs/location-detection.log
# Identify pattern in miscategorized workflows
```

**Recovery**:
```bash
# Immediate: User override
LOCATION_FORCE_AGENT=1 /supervise "update authentication across services"

# Long-term: Tune heuristic
# Add "across" keyword to cross-project detection:
if echo "$desc_lower" | grep -Eq "across.*(services|modules|systems)"; then
  complexity_score=$((complexity_score + CROSS_PROJECT_WEIGHT))
  reasons+=("cross-system keyword detected")
fi

# Update .claude/lib/location-detection-heuristic.sh
# Retest with updated heuristic
```

## Implementation Tasks

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 1: Heuristic Implementation (4 tasks)

- [ ] Create `.claude/lib/location-detection-heuristic.sh` with `needs_complex_location_analysis()` function
  - Implement 5 complexity criteria (migration, refactor, restructure, cross-project, length)
  - Add scoring algorithm with configurable weights
  - Add debug output showing complexity score and reasons
  - Include function export for use in other scripts
  - Test: Unit test with 20 diverse workflow descriptions

- [ ] Create `.claude/lib/location-detection-config.sh` configuration file
  - Define default weights (MIGRATION_WEIGHT=3, etc.)
  - Define default threshold (AGENT_THRESHOLD=3)
  - Add tuning guidelines in comments
  - Document environment variable overrides
  - Test: Source config and verify variables set

- [ ] Make heuristic library executable and validate
  ```bash
  chmod +x .claude/lib/location-detection-heuristic.sh
  shellcheck .claude/lib/location-detection-heuristic.sh
  ```
  - Test: Run shellcheck, fix any warnings

- [ ] Unit test heuristic function with known complexity workflows
  ```bash
  source .claude/lib/location-detection-heuristic.sh

  # Simple workflow (should return 1 = utilities)
  needs_complex_location_analysis "research authentication patterns"
  echo "Exit code: $?"  # Expected: 1

  # Complex workflow (should return 0 = agent)
  needs_complex_location_analysis "migrate auth from nvim/ to .claude/"
  echo "Exit code: $?"  # Expected: 0
  ```
  - Test: Verify 10 simple workflows return 1, 10 complex workflows return 0

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 2: Supervise.md Integration (3 tasks)

- [ ] Back up current supervise.md
  ```bash
  cp .claude/commands/supervise.md .claude/commands/supervise.md.backup-phase5
  ```
  - Test: Verify backup exists and is readable

- [ ] Refactor supervise.md Phase 0 STEP 3 to add conditional logic
  - Add STEP 2.5: Source heuristic library and evaluate workflow complexity
  - Split STEP 3 into STEP 3a (agent path) and STEP 3b (utilities path)
  - Ensure same validation logic after both paths
  - Add logging for method selection (agent vs utilities)
  - Preserve all existing functionality from Phase 2 refactor
  - Test: Read refactored section, verify logic flow correct

- [ ] Add model metadata to agent invocation in STEP 3a
  ```yaml
  Task {
    model: "haiku-4.5"  # From Phase 0 optimization
    # ... rest of agent invocation
  }
  ```
  - Test: Verify YAML syntax valid

### Task Group 3: Comprehensive Testing (5 tasks)

- [ ] Create test suite: `.claude/tests/test_hybrid_location_detection.sh`
  - Test Category 1: 40 simple workflows (should use utilities)
  - Test Category 2: 10 complex workflows (should use agent)
  - Test Category 3: 10 edge cases (mixed expectations)
  - For each test: Verify method used, accuracy, token usage, execution time
  - Generate pass/fail report with statistics
  - Test: Run script, verify it executes without errors

- [ ] Run test suite and analyze results
  ```bash
  .claude/tests/test_hybrid_location_detection.sh > test_results.txt
  ```
  - Expected: >95% pass rate, <10% false positives, <5% false negatives
  - Document any unexpected failures for heuristic tuning
  - Test: Review test_results.txt, verify metrics in expected ranges

- [ ] Test agent fallback with complex workflows
  ```bash
  /supervise "migrate authentication from nvim/ to .claude/ and refactor imports"
  ```
  - Verify heuristic selects agent (complexity score >= 3)
  - Verify Haiku 4.5 model used (check logs)
  - Verify location detected correctly
  - Verify cost ~$0.23 (vs $0.68 Sonnet baseline)
  - Test: Run 5 complex workflows, verify all use agent

- [ ] Test utility path with simple workflows
  ```bash
  /supervise "research API authentication patterns"
  ```
  - Verify heuristic selects utilities (complexity score < 3)
  - Verify location detected correctly
  - Verify cost ~$0 (utilities have no AI cost)
  - Verify execution time <1s
  - Test: Run 10 simple workflows, verify all use utilities

- [ ] Validate cost savings maintained
  - Calculate weighted average: (90% * $0.034) + (10% * $0.23) = $0.054
  - Compare to Phase 0 baseline: $0.68 Sonnet → $0.054 hybrid = 92% reduction
  - Compare to Phase 2 utilities-only: $0.034 → $0.054 = 59% cost increase, but better accuracy
  - Verify overall ROI positive (fewer manual interventions offset cost increase)
  - Test: Run cost analysis dashboard, verify savings in expected range

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

### Task Group 4: Performance Monitoring (3 tasks)

- [ ] Create hybrid performance analysis dashboard
  - Create `.claude/scripts/hybrid_performance_analysis.sh`
  - Implement method distribution calculation (% utilities vs % agent)
  - Implement weighted average token usage
  - Implement cost analysis (last 100 invocations)
  - Compare to Sonnet baseline and show savings
  - Make executable: `chmod +x .claude/scripts/hybrid_performance_analysis.sh`
  - Test: Run dashboard with sample log data

- [ ] Enhance location-detection.log format
  - Add complexity score to log entries: `... | complexity:3 | method:agent | ...`
  - Add heuristic decision reasons: `... | reasons:migration,cross-project | ...`
  - Enables post-hoc analysis of heuristic accuracy
  - Test: Trigger one workflow, verify log entry format correct

- [ ] Create error logging for edge cases
  - Create `.claude/data/logs/location-detection-errors.log`
  - Log agent fallback events: `$(date) | AGENT_FAILURE | Fallback to utilities | <description>`
  - Log utility failures: `$(date) | UTILITY_FAILURE | <error message> | <description>`
  - Log heuristic override events: `$(date) | USER_OVERRIDE | force-agent | <description>`
  - Test: Simulate agent failure, verify error log entry created

### Task Group 5: Documentation (2 tasks)

- [ ] Document heuristic decision criteria in supervise.md header
  ```markdown
  ## Phase 0 Implementation Notes

  Location detection uses hybrid heuristic-agent approach:
  - 90%+ workflows use utility functions (instant, zero cost)
  - 10% complex workflows use Haiku 4.5 agent (5s, $0.23)

  Complexity criteria (agent used if score >= 3):
  - Multi-system migration: +3
  - Multi-module refactor: +2
  - Directory restructuring: +3
  - Cross-project changes: +2
  - Long description (>20 words): +1

  Configuration: .claude/lib/location-detection-config.sh
  Override: LOCATION_FORCE_AGENT=1 or LOCATION_FORCE_UTILS=1
  ```
  - Test: Read documentation, verify clarity and completeness

- [ ] Create heuristic tuning guide
  - Document in `.claude/docs/guides/location-detection-tuning.md`
  - Include baseline establishment process
  - Include threshold adjustment guidelines
  - Include production monitoring procedures
  - Include examples of tuning for different project types
  - Test: Review guide for completeness and actionability

## Success Criteria

### Accuracy Metrics
- [ ] Heuristic correctly identifies complex workflows: >90% accuracy (manual review of 20 test cases)
- [ ] False positive rate (agent used unnecessarily): <10%
- [ ] False negative rate (utilities used when agent needed): <3%
- [ ] Overall location detection accuracy: 99-100% (vs 95-98% utilities-only)

### Performance Metrics
- [ ] 90%+ of workflows use utility functions (zero AI cost, <1s execution)
- [ ] <10% of workflows use agent (Haiku 4.5, ~$0.23 cost, ~5s execution)
- [ ] Weighted average token usage: 12-15k tokens (vs 75.6k baseline)
- [ ] Weighted average cost per invocation: <$0.06 (vs $0.68 baseline)
- [ ] Overall token reduction: 75-85% (vs Sonnet baseline)

### Quality Metrics
- [ ] Zero regression in location detection accuracy vs Phase 4
- [ ] All 6 subdirectories created correctly in 100% of tests
- [ ] Absolute paths provided in location context (100%)
- [ ] Concurrent invocations handled without race conditions

### Monitoring Metrics
- [ ] location-detection.log captures complexity scores and reasons
- [ ] location-detection-errors.log captures all edge cases and fallbacks
- [ ] Hybrid performance dashboard generates actionable insights
- [ ] Weekly monitoring process established and documented

## Rollback Plan

### Trigger Conditions

Rollback to utilities-only (Phase 2) if ANY of:
1. False negative rate exceeds 5% (utilities failing on complex workflows)
2. Agent usage exceeds 20% (heuristic too sensitive)
3. Overall accuracy drops below 97% (hybrid worse than utilities-only)
4. Cost exceeds $0.10 per invocation (agent overuse)

### Rollback Procedure

**Step 1**: Revert supervise.md to Phase 2 state
```bash
cp .claude/commands/supervise.md.backup-phase2 .claude/commands/supervise.md
```

**Step 2**: Keep heuristic library for future tuning
```bash
# Don't delete, just stop using
mv .claude/lib/location-detection-heuristic.sh \
   .claude/lib/location-detection-heuristic.sh.disabled
```

**Step 3**: Document rollback reason
```bash
echo "$(date) | ROLLBACK | Phase 5 → Phase 2 | Reason: <specific issue>" \
  >> .claude/data/logs/location-detection-changes.log
```

**Step 4**: Analyze root cause
- Review test failures to identify heuristic weaknesses
- Determine if tuning would fix issue or fundamental flaw
- Update heuristic criteria based on findings

**Step 5**: Optional re-deployment after fixes
- Update heuristic with improved criteria
- Retest with comprehensive test suite
- Re-apply Phase 5 changes if >95% pass rate achieved

## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run full test suite**: `.claude/tests/test_hybrid_location_detection.sh`
  - Verify all tests passing
  - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
  - Format: `feat(076): complete Phase 5 - Hybrid Heuristic Approach`
  - Include files modified in this phase
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp
- [ ] **Run hybrid performance analysis**: `.claude/scripts/hybrid_performance_analysis.sh`
  - Document baseline metrics for future comparison
  - Archive results to `.claude/specs/076_orchestrate_supervise_comparison/artifacts/phase5_metrics.txt`

## Notes

### Design Decisions

**Why Threshold of 3?**
- Testing shows 90% of workflows score 0-2 (simple patterns)
- Scores >= 3 indicate genuine complexity (migrations, restructuring)
- Lower threshold (2) would increase agent usage to 20-25% (unnecessary cost)
- Higher threshold (4) would miss some complex cases (false negatives)

**Why Haiku 4.5 for Agent Fallback?**
- Location detection is read-only analysis (no code generation)
- Haiku 4.5 sufficient quality for file system analysis
- 67% cost reduction vs Sonnet 4.5 ($0.23 vs $0.68)
- 4-5x speed improvement (5s vs 25s)
- If quality issues detected, fallback-model: sonnet-4.5 activates

**Why File Locking for Concurrent Invocations?**
- Parallel `/orchestrate` workflows may run simultaneously
- Without locking, both calculate same topic number → collision
- File locking (mkdir atomic operation) prevents race conditions
- Timeout prevents deadlock if lock never released (10s default)

### Future Enhancements

**Machine Learning Heuristic** (deferred):
- Train classifier on historical workflows (500+ examples)
- Features: workflow description, keyword frequencies, length, punctuation
- Labels: complex (agent needed) vs simple (utilities sufficient)
- Advantages: Higher accuracy (98-99%), adaptive learning
- Challenges: Requires training data, model maintenance, scikit-learn dependency
- Recommendation: Implement after 6-12 months production data collected

**User Feedback Loop** (optional):
- Add confirmation prompt: "Complex workflow detected. Use agent? [Y/n]"
- Track user overrides (accepted vs rejected)
- Refine heuristic based on user feedback patterns
- Advantages: Transparent decision-making, user control
- Challenges: Interrupts workflow, requires UI changes
- Recommendation: Implement if user complaints about heuristic accuracy

**Adaptive Thresholds** (optional):
- Monitor false positive/negative rates weekly
- Auto-adjust AGENT_THRESHOLD to maintain targets (FP <10%, FN <3%)
- Log threshold changes for audit trail
- Advantages: Self-tuning system, minimal manual intervention
- Challenges: Risk of oscillation, hard to debug
- Recommendation: Implement after stable heuristic validated (3+ months)

### Integration with System-Wide Optimization

This hybrid approach serves as prototype for system-wide optimization (Phase 6 of parent plan):
- Proves heuristic pattern viable for location detection
- Demonstrates cost/accuracy tradeoffs measurable
- Provides template for /orchestrate, /report, /plan commands
- Validates monitoring infrastructure sufficient for production

If Phase 5 achieves >95% success rate and 75-85% token reduction, Phase 6 SHALL adopt hybrid pattern across all commands.
