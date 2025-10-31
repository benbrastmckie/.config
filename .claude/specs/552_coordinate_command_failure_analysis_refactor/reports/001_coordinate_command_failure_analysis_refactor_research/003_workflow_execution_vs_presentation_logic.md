# Workflow Execution vs Presentation Logic Issues

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Workflow Execution vs Presentation Logic Issues
- **Report Type**: codebase analysis

## Executive Summary

The /coordinate command correctly detects workflow scope and sets phase execution gates, but stops execution after Phase 2 (Planning) for research-and-plan workflows as designed. The observed behavior is not a bug but intentional: research-and-plan workflows create reports and plans but do NOT execute implementation, displaying the plan to the user with instructions to run /implement separately. The confusion arises from the workflow name suggesting only planning when it actually stops before implementation.

## Findings

### 1. Workflow Scope Detection Works Correctly

**File**: /home/benjamin/.config/.claude/lib/workflow-detection.sh:46-84

The detect_workflow_scope() function correctly identifies four workflow patterns:

1. **research-only**: Keywords "research [topic]" without "plan" or "implement" → Phases 0,1
2. **research-and-plan**: Keywords "research...to create plan" → Phases 0,1,2 (STOPS HERE)
3. **full-implementation**: Keywords "implement", "build", "add feature" → Phases 0,1,2,3,4,6
4. **debug-only**: Keywords "fix [bug]", "debug [issue]" → Phases 0,1,5

**Evidence from coordinate_implement.md:24-29**:
```
Workflow: research-and-plan → Phases 0,1,2
```

The workflow was correctly detected as "research-and-plan" based on the user input.

### 2. Phase Execution Gates Function As Designed

**File**: /home/benjamin/.config/.claude/commands/coordinate.md:650-675

The phase execution mapping explicitly limits research-and-plan workflows:

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    SKIP_PHASES="3,4,5,6"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4"
    SKIP_PHASES=""  # Phase 5 conditional, Phase 6 always
    ;;
```

### 3. Workflow Completion Check After Phase 2 Stops Execution

**File**: /home/benjamin/.config/.claude/commands/coordinate.md:1187-1213

The critical section that stops execution:

```bash
### Workflow Completion Check (After Phase 2)

STEP 5: Check if workflow should continue to implementation

should_run_phase 3 || {
  emit_progress "Complete" "/coordinate workflow complete"
  echo ""
  echo "Workflow complete: $WORKFLOW_SCOPE"
  echo ""
  echo "Artifacts:"
  echo "  ✓ $SUCCESSFUL_REPORT_COUNT research reports"
  if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
    PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
    PLAN_EST=$(grep "Estimated Total Time:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")
    echo "  ✓ 1 implementation plan ($PHASE_COUNT phases, $PLAN_EST estimated)"
  fi
  echo ""
  echo "Next: /implement $PLAN_PATH"
  echo ""

  exit 0
}
```

**Key Logic**:
- `should_run_phase 3` checks if "3" is in PHASES_TO_EXECUTE
- For research-and-plan: PHASES_TO_EXECUTE="0,1,2" (does NOT include 3)
- Function returns 1 (false), triggering the exit block
- Displays summary and exits with code 0

### 4. should_run_phase() Implementation

**File**: /home/benjamin/.config/.claude/lib/workflow-detection.sh:102-111

```bash
should_run_phase() {
  local phase_num="$1"

  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}
```

Uses simple grep to check if phase number appears in comma-separated list.

### 5. Observed Behavior Matches Design Intent

**Evidence from coordinate_implement.md:145-186**:

The command executed exactly as designed:
1. Detected scope: "research-and-plan"
2. Executed Phases 0, 1, 2
3. Created 3 research reports + 1 plan
4. Displayed summary with "Next: /implement [plan-path]"
5. Stopped without executing implementation

**This is NOT a bug - it's the intended behavior documented in coordinate.md:169-173**:

```
2. **research-and-plan**: Phases 0-2 only (MOST COMMON)
   - Keywords: "research...to create plan", "analyze...for planning"
   - Use case: Research to inform planning
   - Creates research reports + implementation plan
   - No summary (no implementation)
```

### 6. Why This Might Seem Like a Bug

**Expectation vs Reality Gap**:

1. **User expectation**: "research...to create plan to...implement" suggests full workflow
2. **Actual behavior**: Stops after planning, requires separate /implement invocation
3. **Naming confusion**: "research-and-plan" doesn't communicate "stops before implementation"
4. **Documentation clarity**: The (MOST COMMON) annotation suggests this is normal, but users may expect automatic continuation

**Evidence**: The user's request in coordinate_implement.md:1-17 included both "create plan" AND "implement," but the workflow detection pattern only matched "research...to create plan" and stopped there.

### 7. Full-Implementation Pattern Would Continue

**File**: /home/benjamin/.config/.claude/commands/coordinate.md:175-179

If the user had used keywords like "implement" directly:

```
3. **full-implementation**: Phases 0-4, 6
   - Keywords: "implement", "build", "add feature"
   - Use case: Complete feature development
   - Phase 5 conditional on test failures
   - Creates all artifacts including summary
```

This would set PHASES_TO_EXECUTE="0,1,2,3,4,6" and continue through implementation.

## Recommendations

### 1. Improve Workflow Scope Detection for Combined Workflows

**Issue**: User request "research...to create plan to implement" should trigger full-implementation, not research-and-plan.

**Recommendation**: Update detect_workflow_scope() to recognize compound patterns:

```bash
# Pattern 2.5: Research + Plan + Implement (combined workflow)
# Keywords: "research...to create plan...to implement"
if echo "$workflow_desc" | grep -Eiq "research.*(plan|planning).*(implement|build)"; then
  echo "full-implementation"
  return
fi
```

**Location**: /home/benjamin/.config/.claude/lib/workflow-detection.sh:58-64 (insert before existing research-and-plan pattern)

**Impact**: Users stating full intent in one command will get full workflow execution without manual /implement step.

### 2. Add Explicit Workflow Override Parameter

**Issue**: Ambiguous requests may be mis-classified.

**Recommendation**: Add optional --scope parameter:

```bash
/coordinate "research auth patterns to create plan" --scope=research-and-plan
/coordinate "research auth patterns to create plan" --scope=full-implementation
```

**Location**: /home/benjamin/.config/.claude/commands/coordinate.md:13-14 (add to syntax section)

**Implementation**: Parse --scope flag before detect_workflow_scope(), allow explicit override.

### 3. Improve Workflow Completion Message Clarity

**Issue**: "Workflow complete" message doesn't clearly indicate implementation was NOT executed.

**Recommendation**: Update display_brief_summary() for research-and-plan case:

```bash
research-and-plan)
  local report_count=${#REPORT_PATHS[@]}
  echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
  echo ""
  echo "⚠️  NOTE: Implementation was NOT executed (workflow: $WORKFLOW_SCOPE)"
  echo "To execute the implementation plan, run:"
  echo "  /implement $PLAN_PATH"
  ;;
```

**Location**: /home/benjamin/.config/.claude/commands/coordinate.md:584-587

**Impact**: Users will understand why implementation didn't occur and what to do next.

### 4. Document Workflow Pattern Decision Tree

**Issue**: Users cannot easily predict which pattern will be detected.

**Recommendation**: Add decision tree to command documentation:

```
## Workflow Pattern Detection Guide

Your command will be classified as:

1. **research-only** IF:
   - Starts with "research"
   - Does NOT contain "plan", "implement", or "build"
   - Example: "research API authentication patterns"

2. **research-and-plan** IF:
   - Contains "research/analyze/investigate"
   - Contains "to create plan" or "for planning"
   - Does NOT explicitly request implementation
   - Example: "research auth patterns to create refactor plan"

3. **full-implementation** IF:
   - Contains "implement", "build", or "add feature"
   - May or may not include research/planning steps
   - Example: "implement OAuth2 authentication"

4. **debug-only** IF:
   - Starts with "fix", "debug", or "troubleshoot"
   - Contains "bug", "issue", "error", or "failure"
   - Example: "fix token refresh bug in auth.js"

Use --scope flag to override auto-detection if needed.
```

**Location**: /home/benjamin/.config/.claude/commands/coordinate.md:26-33 (after Examples section)

### 5. Consider Renaming Workflow Scopes for Clarity

**Issue**: "research-and-plan" doesn't communicate "stops before implementation"

**Recommendation**: Consider renaming:
- research-and-plan → **plan-only** (or **research-plan-only**)
- full-implementation → **plan-and-implement**

**Alternative**: Keep names, but improve documentation to emphasize stopping points.

**Location**: Multiple files (workflow-detection.sh, coordinate.md)

**Impact**: Breaking change - requires updates across all orchestration commands.

## References

### Primary Evidence Files

1. /home/benjamin/.config/.claude/commands/coordinate.md:650-675 - Phase execution mapping
2. /home/benjamin/.config/.claude/commands/coordinate.md:1187-1213 - Workflow completion check after Phase 2
3. /home/benjamin/.config/.claude/lib/workflow-detection.sh:46-84 - Workflow scope detection patterns
4. /home/benjamin/.config/.claude/lib/workflow-detection.sh:102-111 - should_run_phase() implementation
5. /home/benjamin/.config/.claude/specs/coordinate_implement.md:24-29 - Observed workflow detection
6. /home/benjamin/.config/.claude/specs/coordinate_implement.md:145-186 - Observed completion behavior

### Supporting Documentation

7. /home/benjamin/.config/.claude/commands/coordinate.md:165-184 - Workflow scope type definitions
8. /home/benjamin/.config/.claude/commands/coordinate.md:571-602 - display_brief_summary() function
9. /home/benjamin/.config/.claude/commands/coordinate.md:411-434 - Workflow detection usage examples
