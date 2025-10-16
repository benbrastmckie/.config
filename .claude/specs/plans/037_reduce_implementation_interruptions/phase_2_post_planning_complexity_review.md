# Phase 2: Post-Planning Complexity Review (Step 1.6) - Implementation Specification

## Metadata
- **Phase Number**: 2
- **Parent Plan**: 037_reduce_implementation_interruptions.md
- **Objective**: Add new Step 1.6 to /implement for post-planning, pre-implementation complexity review
- **Complexity**: High (score: 8)
- **Status**: PENDING
- **Estimated Lines**: 350-450 lines of documentation and implementation logic

## Overview

This phase implements a new Step 1.6 in the `/implement` command workflow that performs a comprehensive complexity evaluation of all phases in the plan using the `complexity_estimator` agent. This single post-planning review point replaces all reactive expansion/collapse checks, providing users with clear recommendations before implementation begins.

**Key Innovation**: Agent-based contextual analysis replaces all magic-number thresholds. The complexity_estimator evaluates phases holistically considering architectural significance, integration complexity, and implementation risk—not just task counts.

**Workflow Position**: Step 1.6 executes after agent selection (Step 1.5) but before the first implementation wave (Step 1.6 becomes the new Step 1.6, shifting subsequent steps).

## Implementation Steps

### Step 1: Locate Insertion Point in implement.md

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Target Location**: After Step 1.5 (Phase Complexity Analysis and Agent Selection, line 315-412), before Step 1.6 (Parallel Wave Execution, line 514-577)

**Verification**:
```bash
# Confirm Step 1.5 ends around line 412
grep -n "### 1.5. Phase Complexity Analysis" /home/benjamin/.config/.claude/commands/implement.md

# Confirm Step 1.6 starts around line 514
grep -n "### 1.6. Parallel Wave Execution" /home/benjamin/.config/.claude/commands/implement.md
```

**Action**: Insert new Step 1.6 after line 412, renumber existing Step 1.6 to Step 1.7.

### Step 2: Create Step 1.6 Documentation Header

**Insert After Line 412**:

```markdown
### 1.6. Post-Planning Complexity Review

After all phases have been analyzed for agent selection but before implementation begins, perform a comprehensive complexity evaluation of the entire plan using the complexity_estimator agent. This single review point replaces all reactive expansion/collapse checks.

**Purpose**: Identify phases that would benefit from expansion (for clarity) or collapse (for simplicity) before implementation work begins.

**Trigger**: Executes once per implementation run, after plan loading and before Phase 1 execution.

**Agent Used**: complexity_estimator.md (read-only analysis agent)
```

### Step 3: Implement Context Building for Agent Invocation

**Code Block 1: Extract Plan Context**

```bash
# Extract plan metadata for agent context
PLAN_OVERVIEW=$(grep -A 5 "^## Overview" "$PLAN_PATH" | tail -n +2 | sed '/^##/q' | sed '$d')
PLAN_GOALS=$(grep -A 10 "^## Success Criteria\|^## Goals" "$PLAN_PATH" | tail -n +2 | sed '/^##/q' | sed '$d')
PLAN_CONSTRAINTS=$(grep -A 5 "^## Constraints\|^## Technical Design" "$PLAN_PATH" | tail -n +2 | sed '/^##/q' | sed '$d')

# Detect current structure level
STRUCTURE_LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")

# Count total phases for iteration
TOTAL_PHASES=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
```

**Code Block 2: Build Phase Items Array**

```bash
# Build JSON array of all phases for analysis
PHASES_JSON="["
for phase_num in $(seq 1 $TOTAL_PHASES); do
  # Extract phase content using parse-adaptive-plan.sh
  PHASE_CONTENT=$(.claude/lib/parse-adaptive-plan.sh extract_phase "$PLAN_PATH" "$phase_num")

  # Extract phase name from heading
  PHASE_NAME=$(echo "$PHASE_CONTENT" | grep "^### Phase $phase_num" | sed "s/^### Phase $phase_num: //" | sed 's/ \[.*\]$//')

  # Escape content for JSON
  PHASE_CONTENT_ESCAPED=$(echo "$PHASE_CONTENT" | jq -Rs .)
  PHASE_NAME_ESCAPED=$(echo "$PHASE_NAME" | jq -Rs . | sed 's/^"//;s/"$//')

  # Build phase item
  PHASE_ITEM=$(cat <<EOF
{
  "item_id": "phase_${phase_num}",
  "item_name": "$PHASE_NAME_ESCAPED",
  "content": $PHASE_CONTENT_ESCAPED
}
EOF
)

  PHASES_JSON+="$PHASE_ITEM"

  # Add comma if not last phase
  if [ $phase_num -lt $TOTAL_PHASES ]; then
    PHASES_JSON+=","
  fi
done
PHASES_JSON+="]"
```

**Code Block 3: Build Complete Context JSON**

```bash
# Build complete context for complexity_estimator agent
AGENT_CONTEXT=$(cat <<EOF
{
  "parent_plan_context": {
    "overview": $(echo "$PLAN_OVERVIEW" | jq -Rs .),
    "goals": $(echo "$PLAN_GOALS" | jq -Rs .),
    "constraints": $(echo "$PLAN_CONSTRAINTS" | jq -Rs .)
  },
  "current_structure_level": $STRUCTURE_LEVEL,
  "items_to_analyze": $PHASES_JSON
}
EOF
)
```

**Example Context Output**:
```json
{
  "parent_plan_context": {
    "overview": "Implement OAuth2 authentication system with session management",
    "goals": "Secure user authentication, token refresh, session persistence",
    "constraints": "Must integrate with existing auth middleware"
  },
  "current_structure_level": 0,
  "items_to_analyze": [
    {
      "item_id": "phase_1",
      "item_name": "Setup OAuth Provider Configuration",
      "content": "### Phase 1: Setup OAuth Provider Configuration\n\n- [ ] Configure OAuth2 provider settings\n- [ ] Create environment variables\n- [ ] Setup redirect URLs"
    }
  ]
}
```

### Step 4: Invoke complexity_estimator Agent via Task Tool

**Progress Marker**:
```bash
echo "PROGRESS: Evaluating plan complexity for all phases..."
```

**Agent Invocation**:

```yaml
Use the Task tool to invoke the complexity_estimator agent:

Task {
  subagent_type: "general-purpose"
  description: "Analyze plan complexity for expansion/collapse recommendations"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/complexity_estimator.md

    You are acting as a Complexity Estimator with the tools and constraints
    defined in that file (Read, Grep, Glob only - no modifications).

    Analysis Task: Expansion Analysis

    Parent Plan Context:
      Overview: {PLAN_OVERVIEW}
      Goals: {PLAN_GOALS}
      Constraints: {PLAN_CONSTRAINTS}

    Current Structure Level: {STRUCTURE_LEVEL}

    Items to Analyze:
    {PHASES_JSON formatted as readable list}

    For each phase, analyze complexity considering:
    - Architectural significance (does it establish core patterns?)
    - Integration complexity (how many modules affected?)
    - Implementation uncertainty (is the path clear?)
    - Risk and criticality (impact of failure)
    - Testing requirements (extent of testing needed)

    Provide JSON output with this exact structure:
    [
      {
        "item_id": "phase_N",
        "item_name": "Phase Name",
        "complexity_level": <1-10 integer>,
        "reasoning": "<detailed 2-3 sentence rationale>",
        "recommendation": "<expand|skip>",
        "confidence": "<low|medium|high>"
      }
    ]

    Output only valid JSON array. No additional text.
}
```

**Invocation Metadata**:
- **Timeout**: 60 seconds (agent analysis typically takes 20-40 seconds)
- **Retry**: None (fallback to skip if agent fails)
- **Tools Available to Agent**: Read, Grep, Glob (read-only)

### Step 5: Parse and Validate Agent Response

**Code Block 1: Extract JSON Response**

```bash
# Capture agent response
AGENT_RESPONSE=$(task_output_from_previous_step)

# Validate JSON format
if ! echo "$AGENT_RESPONSE" | jq empty 2>/dev/null; then
  echo "Warning: complexity_estimator returned invalid JSON. Skipping complexity review."
  log_complexity_check "all_phases" "0" "agent_error" "0"
  # Continue to implementation without review
  return 0
fi

# Parse recommendations array
RECOMMENDATIONS=$(echo "$AGENT_RESPONSE" | jq -c '.[]')
RECOMMENDATION_COUNT=$(echo "$AGENT_RESPONSE" | jq '. | length')

echo "Received $RECOMMENDATION_COUNT phase evaluations from complexity_estimator"
```

**Code Block 2: Validate Response Schema**

```bash
# Validate each recommendation has required fields
VALID=true
while IFS= read -r rec; do
  # Check required fields exist
  ITEM_ID=$(echo "$rec" | jq -r '.item_id // empty')
  COMPLEXITY=$(echo "$rec" | jq -r '.complexity_level // empty')
  RECOMMENDATION=$(echo "$rec" | jq -r '.recommendation // empty')
  CONFIDENCE=$(echo "$rec" | jq -r '.confidence // empty')

  if [ -z "$ITEM_ID" ] || [ -z "$COMPLEXITY" ] || [ -z "$RECOMMENDATION" ] || [ -z "$CONFIDENCE" ]; then
    echo "Warning: Invalid recommendation format for $ITEM_ID. Skipping."
    VALID=false
    break
  fi

  # Validate complexity_level is 1-10
  if [ "$COMPLEXITY" -lt 1 ] || [ "$COMPLEXITY" -gt 10 ]; then
    echo "Warning: Invalid complexity_level $COMPLEXITY for $ITEM_ID. Must be 1-10."
    VALID=false
    break
  fi

  # Validate recommendation is expand or skip
  if [ "$RECOMMENDATION" != "expand" ] && [ "$RECOMMENDATION" != "skip" ]; then
    echo "Warning: Invalid recommendation '$RECOMMENDATION' for $ITEM_ID. Must be expand or skip."
    VALID=false
    break
  fi

  # Validate confidence level
  if [ "$CONFIDENCE" != "low" ] && [ "$CONFIDENCE" != "medium" ] && [ "$CONFIDENCE" != "high" ]; then
    echo "Warning: Invalid confidence '$CONFIDENCE' for $ITEM_ID. Must be low, medium, or high."
    VALID=false
    break
  fi
done <<< "$RECOMMENDATIONS"

if [ "$VALID" = false ]; then
  echo "Agent response validation failed. Skipping complexity review."
  return 0
fi
```

### Step 6: Read careful_mode Configuration

**Code Block 1: Extract careful_mode from CLAUDE.md**

```bash
# Read careful_mode setting from CLAUDE.md
CLAUDE_MD="/home/benjamin/.config/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
  # Check for careful_mode configuration
  CAREFUL_MODE=$(grep "^careful_mode:" "$CLAUDE_MD" | awk '{print $2}' | tr -d '[:space:]')

  # Default to true if not found (conservative)
  if [ -z "$CAREFUL_MODE" ]; then
    CAREFUL_MODE="true"
    echo "Note: careful_mode not found in CLAUDE.md, defaulting to true (conservative)"
  fi
else
  # CLAUDE.md not found, default to conservative
  CAREFUL_MODE="true"
  echo "Note: CLAUDE.md not found, defaulting to careful_mode=true"
fi

echo "Careful mode: $CAREFUL_MODE"
```

**Code Block 2: Filter Recommendations Based on careful_mode**

```bash
# Filter recommendations based on careful_mode setting
FILTERED_RECOMMENDATIONS=""

if [ "$CAREFUL_MODE" = "true" ]; then
  # Careful mode: show all recommendations
  FILTERED_RECOMMENDATIONS="$RECOMMENDATIONS"
  FILTER_REASON="careful_mode=true (showing all recommendations)"
else
  # Streamlined mode: only show high-confidence recommendations
  while IFS= read -r rec; do
    CONFIDENCE=$(echo "$rec" | jq -r '.confidence')
    if [ "$CONFIDENCE" = "high" ]; then
      FILTERED_RECOMMENDATIONS+="$rec"$'\n'
    fi
  done <<< "$RECOMMENDATIONS"

  FILTER_REASON="careful_mode=false (showing only high-confidence recommendations)"
fi

# Count filtered recommendations
FILTERED_COUNT=$(echo "$FILTERED_RECOMMENDATIONS" | grep -c "item_id" || echo "0")

echo "Filtered to $FILTERED_COUNT recommendations ($FILTER_REASON)"
```

### Step 7: Display Recommendations (if any)

**Code Block 1: Silent Proceed if No Recommendations**

```bash
# If no recommendations after filtering, proceed silently
if [ "$FILTERED_COUNT" -eq 0 ]; then
  echo "No complexity recommendations to display. Proceeding to implementation."

  # Log to adaptive-planning.log
  log_complexity_check "all_phases" "0" "no_recommendations" "$TOTAL_PHASES"

  # Continue to implementation (skip to next step)
  return 0
fi
```

**Code Block 2: Display Summary Box with Unicode Borders**

```bash
# Display formatted recommendation summary
cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN COMPLEXITY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

echo ""
echo "The complexity_estimator agent has analyzed all phases and identified"
echo "the following recommendations for improving plan organization:"
echo ""

# Display each recommendation with formatting
ITEM_NUM=1
while IFS= read -r rec; do
  ITEM_ID=$(echo "$rec" | jq -r '.item_id')
  ITEM_NAME=$(echo "$rec" | jq -r '.item_name')
  COMPLEXITY=$(echo "$rec" | jq -r '.complexity_level')
  REASONING=$(echo "$rec" | jq -r '.reasoning')
  RECOMMENDATION=$(echo "$rec" | jq -r '.recommendation')
  CONFIDENCE=$(echo "$rec" | jq -r '.confidence')

  echo "[$ITEM_NUM] $ITEM_NAME ($ITEM_ID)"
  echo "    Complexity: $COMPLEXITY/10 | Recommendation: $RECOMMENDATION | Confidence: $CONFIDENCE"
  echo ""
  echo "    Rationale:"
  # Wrap reasoning text at 80 characters with indentation
  echo "$REASONING" | fold -s -w 76 | sed 's/^/      /'
  echo ""

  ITEM_NUM=$((ITEM_NUM + 1))
done <<< "$FILTERED_RECOMMENDATIONS"

cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
```

**Example Display Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLAN COMPLEXITY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The complexity_estimator agent has analyzed all phases and identified
the following recommendations for improving plan organization:

[1] Core State Management Refactor (phase_2)
    Complexity: 9/10 | Recommendation: expand | Confidence: high

    Rationale:
      Critical architectural change affecting multiple modules. Requires
      careful design of state management patterns, high integration
      complexity with auth and session systems, significant testing needs
      including concurrency testing. Implementation uncertainty around
      optimal state persistence approach.

[2] API Endpoint Updates (phase_4)
    Complexity: 7/10 | Recommendation: expand | Confidence: medium

    Rationale:
      Moderate complexity with multiple endpoint changes across different
      controllers. Clear implementation path but touches many files.
      Standard testing requirements but careful coordination needed.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 8: Present User Options

**Code Block: User Interaction Prompt**

```bash
echo ""
echo "Options:"
echo "  (a)pply all recommendations - Execute all recommended expansions/collapses"
echo "  (s)elect specific - Choose which recommendations to apply"
echo "  (c)ontinue without changes - Proceed with plan as-is"
echo ""
read -p "Your choice [a/s/c]: " CHOICE

case "$CHOICE" in
  a|A)
    ACTION="apply_all"
    echo "Applying all recommendations..."
    ;;
  s|S)
    ACTION="select_specific"
    echo "Select specific recommendations..."
    ;;
  c|C)
    ACTION="continue"
    echo "Continuing without changes..."
    ;;
  *)
    echo "Invalid choice. Defaulting to continue without changes."
    ACTION="continue"
    ;;
esac
```

### Step 9: Handle User Selection - Apply All

**Code Block: Apply All Recommendations**

```bash
if [ "$ACTION" = "apply_all" ]; then
  echo ""
  echo "Applying all $FILTERED_COUNT recommendations..."

  # Process each recommendation
  while IFS= read -r rec; do
    ITEM_ID=$(echo "$rec" | jq -r '.item_id')
    ITEM_NAME=$(echo "$rec" | jq -r '.item_name')
    RECOMMENDATION=$(echo "$rec" | jq -r '.recommendation')

    # Extract phase number from item_id
    PHASE_NUM=$(echo "$ITEM_ID" | sed 's/phase_//')

    if [ "$RECOMMENDATION" = "expand" ]; then
      echo "  → Expanding Phase $PHASE_NUM: $ITEM_NAME"

      # Invoke /expand command via SlashCommand tool
      EXPAND_RESULT=$(invoke_slash_command "/expand phase $PLAN_PATH $PHASE_NUM")

      # Check if expansion succeeded
      if echo "$EXPAND_RESULT" | grep -q "successfully expanded\|expansion complete"; then
        echo "    ✓ Phase $PHASE_NUM expanded successfully"

        # Log expansion
        log_complexity_check "$PHASE_NUM" "expand_applied" "user_approved" "apply_all"
      else
        echo "    ✗ Phase $PHASE_NUM expansion failed: $EXPAND_RESULT"

        # Log failure but continue
        log_complexity_check "$PHASE_NUM" "expand_failed" "user_approved" "apply_all"
      fi

    elif [ "$RECOMMENDATION" = "collapse" ]; then
      echo "  → Collapsing Phase $PHASE_NUM: $ITEM_NAME"

      # Invoke /collapse command via SlashCommand tool
      COLLAPSE_RESULT=$(invoke_slash_command "/collapse phase $PLAN_PATH $PHASE_NUM")

      # Check if collapse succeeded
      if echo "$COLLAPSE_RESULT" | grep -q "successfully collapsed\|collapse complete"; then
        echo "    ✓ Phase $PHASE_NUM collapsed successfully"

        # Log collapse
        log_complexity_check "$PHASE_NUM" "collapse_applied" "user_approved" "apply_all"
      else
        echo "    ✗ Phase $PHASE_NUM collapse failed: $COLLAPSE_RESULT"

        # Log failure but continue
        log_complexity_check "$PHASE_NUM" "collapse_failed" "user_approved" "apply_all"
      fi
    fi
  done <<< "$FILTERED_RECOMMENDATIONS"

  echo ""
  echo "All recommendations processed. Plan structure updated."

  # Reload plan if structure changed (Level 0 → 1 transition)
  PLAN_PATH=$(resolve_plan_path_after_expansion "$PLAN_PATH")
fi
```

### Step 10: Handle User Selection - Select Specific

**Code Block: Interactive Selection**

```bash
if [ "$ACTION" = "select_specific" ]; then
  echo ""
  echo "Enter recommendation numbers to apply (comma-separated, e.g., 1,3,5):"
  read -p "Numbers: " SELECTED_NUMS

  # Parse selected numbers
  IFS=',' read -ra NUMS <<< "$SELECTED_NUMS"

  # Apply selected recommendations
  for num in "${NUMS[@]}"; do
    # Trim whitespace
    num=$(echo "$num" | tr -d '[:space:]')

    # Validate number
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
      echo "  ✗ Invalid number: $num (skipping)"
      continue
    fi

    if [ "$num" -lt 1 ] || [ "$num" -gt "$FILTERED_COUNT" ]; then
      echo "  ✗ Number out of range: $num (skipping)"
      continue
    fi

    # Get recommendation by index (1-based)
    rec=$(echo "$FILTERED_RECOMMENDATIONS" | sed -n "${num}p")

    ITEM_ID=$(echo "$rec" | jq -r '.item_id')
    ITEM_NAME=$(echo "$rec" | jq -r '.item_name')
    RECOMMENDATION=$(echo "$rec" | jq -r '.recommendation')

    # Extract phase number
    PHASE_NUM=$(echo "$ITEM_ID" | sed 's/phase_//')

    if [ "$RECOMMENDATION" = "expand" ]; then
      echo "  → Expanding Phase $PHASE_NUM: $ITEM_NAME"

      EXPAND_RESULT=$(invoke_slash_command "/expand phase $PLAN_PATH $PHASE_NUM")

      if echo "$EXPAND_RESULT" | grep -q "successfully expanded\|expansion complete"; then
        echo "    ✓ Phase $PHASE_NUM expanded successfully"
        log_complexity_check "$PHASE_NUM" "expand_applied" "user_selected" "select_specific"
      else
        echo "    ✗ Phase $PHASE_NUM expansion failed"
        log_complexity_check "$PHASE_NUM" "expand_failed" "user_selected" "select_specific"
      fi

    elif [ "$RECOMMENDATION" = "collapse" ]; then
      echo "  → Collapsing Phase $PHASE_NUM: $ITEM_NAME"

      COLLAPSE_RESULT=$(invoke_slash_command "/collapse phase $PLAN_PATH $PHASE_NUM")

      if echo "$COLLAPSE_RESULT" | grep -q "successfully collapsed\|collapse complete"; then
        echo "    ✓ Phase $PHASE_NUM collapsed successfully"
        log_complexity_check "$PHASE_NUM" "collapse_applied" "user_selected" "select_specific"
      else
        echo "    ✗ Phase $PHASE_NUM collapse failed"
        log_complexity_check "$PHASE_NUM" "collapse_failed" "user_selected" "select_specific"
      fi
    fi
  done

  echo ""
  echo "Selected recommendations processed."

  # Reload plan if structure changed
  PLAN_PATH=$(resolve_plan_path_after_expansion "$PLAN_PATH")
fi
```

### Step 11: Handle User Selection - Continue Without Changes

**Code Block: Log and Proceed**

```bash
if [ "$ACTION" = "continue" ]; then
  echo ""
  echo "Continuing with plan as-is. Recommendations logged for reference."

  # Log user decision to skip recommendations
  while IFS= read -r rec; do
    ITEM_ID=$(echo "$rec" | jq -r '.item_id')
    PHASE_NUM=$(echo "$ITEM_ID" | sed 's/phase_//')
    RECOMMENDATION=$(echo "$rec" | jq -r '.recommendation')

    log_complexity_check "$PHASE_NUM" "$RECOMMENDATION" "user_declined" "continue"
  done <<< "$FILTERED_RECOMMENDATIONS"

  echo "Proceeding to implementation..."
fi
```

### Step 12: Logging Integration

**Log Entry Format**: All complexity evaluations are logged to `.claude/logs/adaptive-planning.log` using the `log_complexity_check` function from `adaptive-planning-logger.sh`.

**Log Function Signature**:
```bash
log_complexity_check "$PHASE_NUM" "$COMPLEXITY_SCORE" "$THRESHOLD" "$TASK_COUNT"
```

**Adapted Usage for Step 1.6**:
```bash
# Log format for agent-based evaluation
log_complexity_check "$PHASE_NUM" "$RECOMMENDATION" "$USER_ACTION" "$CONTEXT"

# Examples:
log_complexity_check "2" "expand_applied" "user_approved" "apply_all"
log_complexity_check "3" "expand_declined" "user_declined" "continue"
log_complexity_check "all_phases" "no_recommendations" "auto_proceed" "0"
log_complexity_check "4" "expand_failed" "user_selected" "command_error"
```

**Log Output Examples**:
```
[2025-10-10T14:32:18Z] INFO trigger_eval: Complexity review completed | data={"phases_analyzed": 5, "recommendations": 2, "user_action": "apply_all"}
[2025-10-10T14:32:19Z] INFO complexity_check: Phase 2 expand applied | data={"phase": 2, "recommendation": "expand", "action": "user_approved", "context": "apply_all"}
[2025-10-10T14:32:25Z] INFO complexity_check: Phase 4 expand applied | data={"phase": 4, "recommendation": "expand", "action": "user_approved", "context": "apply_all"}
```

### Step 13: Renumber Subsequent Steps

After inserting Step 1.6, renumber all following steps:

**Current Steps** → **New Steps**:
- Step 1.6 (Parallel Wave Execution) → Step 1.7
- Step 2 (Implementation) → Step 2 (unchanged)
- Step 3 (Testing) → Step 3 (unchanged)
- ... (all subsequent steps unchanged)

**Update References**:
```bash
# Find all references to "Step 1.6" after our new section
# Replace with "Step 1.7" throughout document
sed -i 's/### 1\.6\. Parallel Wave Execution/### 1.7. Parallel Wave Execution/g' implement.md
```

## Testing Specifications

### Test Case 1: Simple Plan with No Recommendations

**Setup**:
- Create minimal plan with 3 simple phases (complexity <7 each)
- All phases have <5 tasks
- No architectural changes

**Expected Behavior**:
1. Agent analyzes all phases
2. Returns all "skip" recommendations
3. No filtered recommendations (all below threshold)
4. Silent proceed to implementation
5. Log entry: "no_recommendations"

**Verification**:
```bash
# Check log
grep "no_recommendations" .claude/logs/adaptive-planning.log

# Verify no user prompt displayed
# Verify implementation starts immediately
```

### Test Case 2: Complex Plan with Expansion Recommendations

**Setup**:
- Create plan with 5 phases
- Phase 2: High complexity (9/10, architectural refactor)
- Phase 4: Medium-high complexity (7/10, multi-module integration)
- Phases 1,3,5: Simple (complexity <6)

**Expected Behavior**:
1. Agent analyzes all phases
2. Returns 2 "expand" recommendations (phases 2 and 4) with high confidence
3. Display summary box with 2 recommendations
4. Present user with options (a/s/c)

**Test Branches**:

**Branch A - Apply All**:
```bash
# User selects: a
# Expected: /expand invoked for phases 2 and 4
# Expected: Plan structure changes to Level 1
# Expected: Both expansions logged as "user_approved"
```

**Branch S - Select Specific**:
```bash
# User selects: s
# User enters: 1
# Expected: /expand invoked only for phase 2
# Expected: Phase 4 not expanded
# Expected: Only phase 2 logged as "user_selected"
```

**Branch C - Continue**:
```bash
# User selects: c
# Expected: No /expand invoked
# Expected: Both recommendations logged as "user_declined"
# Expected: Implementation proceeds with Level 0 plan
```

### Test Case 3: careful_mode=true vs false Behavior

**Setup**: Same complex plan from Test Case 2

**Subtest A - careful_mode=true**:
```yaml
# CLAUDE.md contains:
careful_mode: true
```

**Expected**:
- All recommendations displayed (including medium/low confidence)
- User sees all agent output
- Conservative approach

**Subtest B - careful_mode=false**:
```yaml
# CLAUDE.md contains:
careful_mode: false
```

**Expected**:
- Only high-confidence recommendations displayed
- Medium/low confidence filtered out
- Streamlined workflow

**Verification**:
```bash
# Check filter log
grep "careful_mode" .claude/logs/adaptive-planning.log
```

### Test Case 4: Agent Invocation Failure Handling

**Scenario A - Agent Timeout**:
- Mock agent taking >60 seconds
- Expected: Timeout, log warning, skip review, proceed to implementation

**Scenario B - Invalid JSON Response**:
- Mock agent returning malformed JSON
- Expected: JSON validation fails, log warning, skip review, proceed

**Scenario C - Missing Required Fields**:
- Mock agent returning JSON without "recommendation" field
- Expected: Schema validation fails, log warning, skip review

**Verification**:
```bash
# All scenarios should log agent_error
grep "agent_error" .claude/logs/adaptive-planning.log

# Implementation should proceed normally despite agent failure
# No user interruption for agent failures
```

### Test Case 5: User Input Validation

**Invalid Inputs**:
- User enters "x" instead of a/s/c → Default to "continue"
- User enters "1,2,abc" for selection → Skip "abc", apply 1,2
- User enters "1,10" when only 2 recommendations → Skip "10", apply 1

**Expected Behavior**:
- Graceful handling of all invalid inputs
- Informative error messages
- Safe defaults (continue without changes)

## Error Handling

### Agent Invocation Timeout

**Trigger**: complexity_estimator takes >60 seconds

**Handling**:
```bash
# Set timeout in Task invocation
timeout 60s invoke_agent complexity_estimator "$AGENT_CONTEXT"

if [ $? -eq 124 ]; then
  echo "Warning: Complexity analysis timed out. Skipping review."
  log_complexity_check "all_phases" "0" "agent_timeout" "0"
  return 0  # Proceed to implementation
fi
```

**User Impact**: None (silent fallback)

### Malformed JSON Response

**Trigger**: Agent returns non-JSON text

**Handling**:
```bash
if ! echo "$AGENT_RESPONSE" | jq empty 2>/dev/null; then
  echo "Warning: complexity_estimator returned invalid JSON. Skipping complexity review."
  log_complexity_check "all_phases" "0" "invalid_json" "0"
  return 0
fi
```

**User Impact**: None (silent fallback)

### Missing Required Fields

**Trigger**: JSON missing item_id, complexity_level, recommendation, or confidence

**Handling**: Already implemented in Step 5 validation (see Code Block 2)

**User Impact**: None (silent fallback)

### /expand or /collapse Command Failures

**Trigger**: SlashCommand invocation fails

**Handling**:
```bash
if echo "$EXPAND_RESULT" | grep -q "ERROR\|failed\|cannot"; then
  echo "    ✗ Phase $PHASE_NUM expansion failed: $EXPAND_RESULT"
  log_complexity_check "$PHASE_NUM" "expand_failed" "command_error" "apply_all"
  # Continue processing other recommendations
fi
```

**User Impact**: Error message displayed, other recommendations continue

### CLAUDE.md Configuration Missing careful_mode

**Trigger**: No careful_mode setting in CLAUDE.md

**Handling**:
```bash
if [ -z "$CAREFUL_MODE" ]; then
  CAREFUL_MODE="true"  # Default to conservative
  echo "Note: careful_mode not found in CLAUDE.md, defaulting to true (conservative)"
fi
```

**User Impact**: Conservative default applied, informative message

### Fallback Behavior Summary

**Principle**: Never block implementation due to complexity review failures

**All error scenarios**:
1. Log warning with specific error type
2. Log to adaptive-planning.log for debugging
3. Proceed to implementation without review
4. No user interruption or manual intervention required

## Integration Notes

### Files Modified

**Primary**:
- `/home/benjamin/.config/.claude/commands/implement.md` - Insert Step 1.6 after line 412

**Dependencies Used**:
- `/home/benjamin/.config/.claude/agents/complexity_estimator.md` - Agent invocation
- `/home/benjamin/.config/.claude/lib/adaptive-planning-logger.sh` - Logging functions
- `/home/benjamin/.config/.claude/lib/parse-adaptive-plan.sh` - Plan parsing utilities
- `/home/benjamin/.config/CLAUDE.md` - careful_mode configuration

### SlashCommand Invocations

**Pattern**:
```bash
# Invoke /expand command
RESULT=$(invoke_slash_command "/expand phase $PLAN_PATH $PHASE_NUM")

# Invoke /collapse command
RESULT=$(invoke_slash_command "/collapse phase $PLAN_PATH $PHASE_NUM")
```

**Note**: SlashCommand tool usage assumes the implementation environment supports programmatic slash command invocation. If not available, fall back to displaying commands for manual execution.

### Plan Path Resolution

After expansion operations, the plan path may change (Level 0 → Level 1 transition):

```bash
# Helper function to resolve path after expansion
resolve_plan_path_after_expansion() {
  local current_path="$1"

  # If plan was file and is now directory
  if [[ -f "$current_path" ]]; then
    local plan_dir="${current_path%.md}"
    if [[ -d "$plan_dir" ]]; then
      # Expanded to Level 1
      echo "$plan_dir/$(basename "$current_path")"
    else
      # Still Level 0
      echo "$current_path"
    fi
  else
    # Already directory (Level 1 or 2)
    echo "$current_path"
  fi
}
```

## Completion Criteria

### Implementation Complete When:

- [ ] Step 1.6 documentation added after line 412 in implement.md
- [ ] Context building logic extracts plan overview, goals, constraints
- [ ] Phase array construction includes all phases with content
- [ ] Agent invocation uses Task tool with proper prompt structure
- [ ] JSON response parsing validates format and schema
- [ ] careful_mode configuration read from CLAUDE.md with fallback
- [ ] Recommendation filtering based on careful_mode setting
- [ ] Silent proceed when no recommendations after filtering
- [ ] Summary box displays with Unicode borders and formatted rationale
- [ ] User options presented (apply all, select specific, continue)
- [ ] Apply all: loops through recommendations, invokes /expand or /collapse
- [ ] Select specific: parses user input, applies only selected
- [ ] Continue: logs decision, proceeds without changes
- [ ] All complexity evaluations logged to adaptive-planning.log
- [ ] Progress marker emitted before agent invocation
- [ ] Subsequent steps renumbered (1.6 → 1.7)
- [ ] Error handling for all failure scenarios
- [ ] All test cases pass

### Testing Complete When:

- [ ] Test Case 1 verified (no recommendations, silent proceed)
- [ ] Test Case 2 verified (all branches: apply all, select, continue)
- [ ] Test Case 3 verified (careful_mode true vs false)
- [ ] Test Case 4 verified (agent failures: timeout, invalid JSON, schema)
- [ ] Test Case 5 verified (user input validation)
- [ ] Log entries correct for all scenarios
- [ ] No regressions in existing /implement functionality

## Implementation Notes

### Why Agent-Based Analysis?

The complexity_estimator agent provides **contextual intelligence** that simple thresholds cannot match:

- Evaluates architectural significance, not just task count
- Considers integration complexity across modules
- Assesses implementation uncertainty and risk
- Accounts for testing requirements

**Example**: A 3-task phase introducing a new state management pattern is more complex than a 10-task phase of simple CRUD operations. The agent recognizes this; thresholds do not.

### Why Post-Planning Review?

**Single review point** before implementation eliminates:
- Reactive interruptions during Phase N (Step 1.55 removed)
- Post-completion expansion triggers (Step 3.4 Trigger 1 removed)
- Automatic collapse checks (Step 5.5 removed)

**User benefit**: Clear plan structure established upfront, no surprises during implementation.

### Why careful_mode Configuration?

Different users have different workflow preferences:

- **careful_mode=true**: See all recommendations, approve each change (conservative)
- **careful_mode=false**: Only see high-confidence recommendations (streamlined)

**Rationale**: Experienced users can skip medium/low confidence suggestions while new users benefit from seeing all agent analysis.
