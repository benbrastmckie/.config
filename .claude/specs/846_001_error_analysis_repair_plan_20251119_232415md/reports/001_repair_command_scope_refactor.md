# /repair Command Scope Refactor Research

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Refactor /repair command to focus exclusively on fixing errors
- **Report Type**: Research for plan creation
- **Research Complexity**: 3
- **Workflow**: research-and-plan

## Executive Summary

The /repair command currently creates plans that extend beyond error fixing into infrastructure improvements (test/production segregation, log rotation, metadata enhancement). Analysis shows the command should be refactored to focus exclusively on fixing the specific errors identified in error log analysis. The plan-architect agent should be configured to create error-fix-only plans, while the repair-analyst agent already provides appropriate error analysis. This refactor aligns /repair with the established command pattern where /errors queries logs, /repair creates fix plans, and infrastructure improvements are separate initiatives.

## Problem Statement

### Current Behavior

The /repair command generated a plan (001_error_analysis_repair_plan_20251119_232415.md) that included:
- Phase 1: Test/Production Error Segregation (infrastructure change)
- Phase 2: Error Log Cleanup Utility (new tool creation)
- Phase 3: Log Rotation Implementation (infrastructure enhancement)
- Phase 4: Enhanced Error Metadata (schema evolution)
- Phase 5: Testing and Documentation

**Location**: /home/benjamin/.config/.claude/specs/841_error_analysis_repair/plans/backups/001_error_analysis_repair_plan_20251119_232415.md

### Issue Analysis

The error analysis report identified 3 test-generated errors and made 4 recommendations:
1. Add Error Log Cleanup Utility (Priority: Medium)
2. Implement Error Log Rotation (Priority: Low)
3. Add Production vs Test Error Segregation (Priority: High)
4. Enhance Error Logging Metadata (Priority: Low)

**Problem**: These are infrastructure improvements, not error fixes. The actual errors analyzed were test artifacts (test_error_logging.sh), not production errors requiring fixes.

**Root Cause**: The plan-architect agent received analysis with infrastructure recommendations and created a plan implementing those recommendations rather than creating a plan to fix the actual errors.

### Expected Behavior

The /repair command should:
1. Analyze error logs to identify patterns and root causes
2. Create an implementation plan focused ONLY on fixing those errors
3. NOT create plans for infrastructure improvements (those belong in separate initiatives)

Example: If errors show "state persistence failures in /build command", the plan should fix state persistence logic, not implement log rotation.

## Current Architecture Analysis

### /repair Command Structure

**File**: /home/benjamin/.config/.claude/commands/repair.md

**Workflow Type**: research-and-plan (2-phase workflow)

**Phase 1: Research (Error Analysis)**
- Invokes repair-analyst agent
- Inputs: ERROR_FILTERS (since, type, command, severity)
- Output: Error analysis report in specs/{NNN_topic}/reports/
- Report includes: error patterns, root causes, recommendations

**Phase 2: Planning**
- Invokes plan-architect agent
- Inputs: ERROR_DESCRIPTION, research reports, complexity
- Output: Implementation plan in specs/{NNN_topic}/plans/
- Plan includes: phases, tasks, testing, documentation

### repair-analyst Agent Behavior

**File**: /home/benjamin/.config/.claude/agents/repair-analyst.md

**Primary Task**: Create error analysis report with patterns and root causes

**Report Structure**:
- Executive Summary (error count, common types, urgency)
- Error Patterns (frequency, commands affected, root cause hypothesis)
- Root Cause Analysis (underlying issues)
- Recommendations (prioritized fixes with effort estimates)

**Analysis Quality**: The repair-analyst correctly identifies error patterns and root causes. The issue is in the recommendations section where it suggests infrastructure improvements rather than focusing on fixing the identified errors.

### plan-architect Agent Behavior

**File**: /home/benjamin/.config/.claude/agents/plan-architect.md

**Primary Task**: Create implementation plans from research reports

**Planning Process**:
1. Analyze requirements and research reports
2. Calculate complexity score
3. Create plan file with phases
4. Include all research reports in metadata

**Issue**: The agent creates plans based on recommendations in research reports without filtering for scope (error fixes vs infrastructure improvements).

## Comparison with /plan Command

### /plan Command Pattern

**File**: /home/benjamin/.config/.claude/commands/plan.md

**Workflow Type**: research-and-plan (identical to /repair)

**Key Difference**:
- /plan receives a "feature description" from user (e.g., "implement user authentication")
- /repair receives error filters and generates description ("error analysis and repair")

**Agent Usage**:
- Phase 1: research-specialist (broad research)
- Phase 2: plan-architect (create implementation plan)

**Scope Control**: User provides explicit feature scope in description. Agent creates plan for that specific feature.

### Scope Control Mechanism

In /plan command:
```bash
FEATURE_DESCRIPTION="implement user authentication with JWT tokens"
# plan-architect creates plan for this specific feature
```

In /repair command:
```bash
ERROR_DESCRIPTION="error analysis and repair"
# Too vague - doesn't constrain plan-architect to error fixing only
```

**Root Cause Identified**: ERROR_DESCRIPTION is generic and doesn't communicate the constraint that the plan should ONLY fix errors, not improve infrastructure.

## Proposed Solution

### Solution 1: Refactor plan-architect Invocation (Recommended)

**Change**: Modify how /repair invokes plan-architect to explicitly constrain scope to error fixing.

**Implementation**:

1. **Update ERROR_DESCRIPTION Generation** (repair.md Block 1)
   - Current: `ERROR_DESCRIPTION="error analysis and repair"`
   - Proposed: `ERROR_DESCRIPTION="fix errors identified in error analysis"`

2. **Add Scope Constraint to plan-architect Prompt** (repair.md Block 2)
   - Add explicit instruction in Task prompt:
   ```
   **CRITICAL SCOPE CONSTRAINT**:
   Create an implementation plan that FIXES THE ERRORS identified in the analysis reports.
   DO NOT create plans for infrastructure improvements, new tools, or enhancements.
   ONLY plan fixes for the actual errors found in the error log.

   If the error analysis found no actionable production errors (only test artifacts),
   create a minimal plan that documents this finding and recommends running /repair
   with filters to target specific error types or time ranges.
   ```

3. **Filter Recommendations in repair-analyst** (repair-analyst.md Step 3)
   - Modify recommendations section guidance to separate:
     - "Error Fixes" (MUST include, Priority: High)
     - "Infrastructure Improvements" (optional, note these should be separate initiatives)

**Advantages**:
- Minimal code changes (prompt modifications only)
- Clear scope boundaries for agents
- Preserves agent reusability (plan-architect still general-purpose)
- Aligns with /plan pattern (explicit scope in description)

**Disadvantages**:
- Relies on agent instruction following
- May need iteration to get prompting right

### Solution 2: Create Dedicated repair-plan-architect Agent

**Change**: Create a specialized agent that only creates error-fix plans.

**Implementation**:

1. **Create New Agent**: .claude/agents/repair-plan-architect.md
   - Fork from plan-architect.md
   - Hardcode scope constraint: "plans ONLY fix errors, no infrastructure"
   - Add error-specific planning patterns

2. **Update /repair Command**: Use repair-plan-architect instead of plan-architect

**Advantages**:
- Enforces scope at agent level
- Can add error-specific planning patterns
- Clear separation of concerns

**Disadvantages**:
- Code duplication (new agent similar to plan-architect)
- Maintenance burden (two similar agents)
- Reduces agent reusability

### Solution 3: Two-Step Filtering (Research + Scope Filter)

**Change**: Add intermediate step between research and planning to filter recommendations.

**Implementation**:

1. **Add Block 2.5 to /repair Command**:
   - Read research report
   - Parse recommendations
   - Filter out infrastructure recommendations
   - Create filtered recommendations JSON
   - Pass to plan-architect

2. **Update plan-architect Invocation**:
   - Include filtered recommendations in context
   - Instruct to plan ONLY filtered items

**Advantages**:
- Explicit filtering with transparency
- Can log what was filtered and why
- Preserves agent generality

**Disadvantages**:
- More complex workflow (additional processing step)
- Requires parsing recommendation structure
- Brittle if recommendation format changes

## Recommendation Analysis

### Recommended Approach: Solution 1 (Refactor Invocation)

**Justification**:
1. **Minimal Changes**: Only prompt modifications, no new files
2. **Aligns with Existing Pattern**: /plan uses description to constrain scope
3. **Preserves Agent Reusability**: No specialized agents needed
4. **Clear Intent**: Explicit scope constraint in prompt
5. **Fast Implementation**: Can be done in single phase

**Implementation Complexity**: Low (30 minutes)

**Risk**: Agent may not follow instructions perfectly, may need prompt iteration

**Mitigation**: Add verification in Block 3 to check plan content aligns with scope

### Alternative: Solution 2 (Dedicated Agent)

**When to Use**: If Solution 1 fails after 2-3 prompt iterations

**Justification**: If prompting doesn't reliably constrain scope, a specialized agent provides enforcement at the agent level.

**Implementation Complexity**: Medium (1-2 hours)

## Detailed Implementation Design (Solution 1)

### Change 1: Update ERROR_DESCRIPTION Logic

**File**: /home/benjamin/.config/.claude/commands/repair.md

**Location**: Block 1, lines 89-96

**Current Code**:
```bash
ERROR_DESCRIPTION="error analysis and repair"
if [ -n "$ERROR_TYPE" ]; then
  ERROR_DESCRIPTION="$ERROR_TYPE errors repair"
elif [ -n "$ERROR_COMMAND" ]; then
  ERROR_DESCRIPTION="$ERROR_COMMAND errors repair"
fi
```

**Proposed Code**:
```bash
ERROR_DESCRIPTION="fix errors identified in error log analysis"
if [ -n "$ERROR_TYPE" ]; then
  ERROR_DESCRIPTION="fix $ERROR_TYPE errors"
elif [ -n "$ERROR_COMMAND" ]; then
  ERROR_DESCRIPTION="fix errors in $ERROR_COMMAND command"
elif [ -n "$ERROR_SEVERITY" ]; then
  ERROR_DESCRIPTION="fix $ERROR_SEVERITY severity errors"
fi
```

**Rationale**: "fix errors" clearly communicates the scope is error fixing, not infrastructure improvement.

### Change 2: Add Scope Constraint to plan-architect Prompt

**File**: /home/benjamin/.config/.claude/commands/repair.md

**Location**: Block 2, Task invocation (lines 310-331)

**Current Prompt**:
```
You are creating an implementation plan for: repair workflow

**Workflow-Specific Context**:
- Feature Description: ${ERROR_DESCRIPTION}
- Output Path: ${PLAN_PATH}
- Research Reports: ${REPORT_PATHS_JSON}
- Workflow Type: research-and-plan
- Operation Mode: new plan creation

Execute planning according to behavioral guidelines and return completion signal:
PLAN_CREATED: ${PLAN_PATH}
```

**Proposed Prompt**:
```
You are creating an implementation plan for: repair workflow

**Workflow-Specific Context**:
- Feature Description: ${ERROR_DESCRIPTION}
- Output Path: ${PLAN_PATH}
- Research Reports: ${REPORT_PATHS_JSON}
- Workflow Type: research-and-plan
- Operation Mode: new plan creation

**CRITICAL SCOPE CONSTRAINT**:
This plan must ONLY fix the errors identified in the error analysis reports.
DO NOT create plans for:
- Infrastructure improvements (log rotation, cleanup utilities)
- Error logging enhancements (new metadata fields, test/prod segregation)
- New tool creation (unless directly fixing an error)
- Schema evolution or configuration changes (unless directly fixing an error)

ONLY create phases and tasks that:
- Fix the root causes identified in the error analysis
- Address the specific error patterns found in the error log
- Resolve issues causing the logged errors

If the error analysis found no actionable production errors (only test artifacts),
create a minimal plan documenting this finding and suggest:
1. Running /errors to query recent production errors
2. Using /repair with filters (--type, --command, --since) to target specific errors
3. Using /debug for individual error investigation

Execute planning according to behavioral guidelines and return completion signal:
PLAN_CREATED: ${PLAN_PATH}
```

**Rationale**: Explicit negative constraints (DO NOT) and positive constraints (ONLY) clearly define scope boundaries. Special case handling for "no actionable errors" prevents empty plans.

### Change 3: Update repair-analyst Recommendations Guidance

**File**: /home/benjamin/.config/.claude/agents/repair-analyst.md

**Location**: Step 3, Report Sections (lines 167-193)

**Current Guidance**:
```markdown
4. **Recommendations** (minimum 3):
   - Specific, actionable fixes
   - Priority order (high/medium/low)
   - Estimated effort (low/medium/high)
   - Dependencies (if any)
```

**Proposed Guidance**:
```markdown
4. **Recommendations**:

   **Primary Section: Error Fixes** (minimum 1, HIGH PRIORITY):
   - Specific fixes for root causes identified
   - Address actual errors found in the log
   - Priority: HIGH (these are the primary purpose)
   - Estimated effort (low/medium/high)
   - Dependencies (if any)

   **Secondary Section: Infrastructure Improvements** (optional, LOW PRIORITY):
   - Improvements to prevent similar errors in future
   - Enhancements to error logging or analysis
   - Note: These should be separate initiatives (use /plan for these)
   - Priority: LOW (out of scope for /repair, documented for awareness)

   **Special Case: No Actionable Errors Found**:
   If all errors are test artifacts or already resolved:
   - Document this finding clearly
   - Recommend using /errors to explore recent logs
   - Suggest filtering strategies (--type, --command, --since)
   - Note that no fix plan is needed
```

**Rationale**: Separates error fixes (in scope) from infrastructure improvements (out of scope). Provides guidance for "no errors" scenario.

### Change 4: Add Plan Scope Verification

**File**: /home/benjamin/.config/.claude/commands/repair.md

**Location**: Block 3, after plan verification (add new check after line 380)

**New Verification Code**:
```bash
# === VERIFY PLAN SCOPE (ERROR FIXES ONLY) ===
echo "Verifying plan scope..."

# Check if plan contains infrastructure keywords that suggest scope creep
INFRA_KEYWORDS="rotation|cleanup utility|metadata enhancement|segregation|new tool|schema evolution"
if grep -Ei "$INFRA_KEYWORDS" "$PLAN_PATH" | grep -v "fix\|repair\|resolve" > /dev/null; then
  echo "WARNING: Plan may include infrastructure improvements beyond error fixing"
  echo "Review plan to ensure focus is on fixing identified errors"
fi

# Check if plan phases address error fixing
if ! grep -Ei "fix|repair|resolve" "$PLAN_PATH" > /dev/null; then
  echo "WARNING: Plan does not appear to focus on fixing errors"
  echo "Review plan to ensure it addresses root causes from analysis"
fi

echo "Plan scope verification complete"
```

**Rationale**: Post-creation verification catches scope creep. Warnings alert user to review plan if it diverges from error-fixing focus.

## Implementation Plan Structure

### Phase 1: Update /repair Command Scope Constraints
**Complexity**: Low
**Tasks**:
- Update ERROR_DESCRIPTION generation logic in Block 1
- Add CRITICAL SCOPE CONSTRAINT to plan-architect prompt in Block 2
- Add plan scope verification in Block 3
- Update /repair command documentation with scope clarification

### Phase 2: Update repair-analyst Recommendations Guidance
**Complexity**: Low
**Tasks**:
- Update Step 3 recommendations section with Error Fixes vs Infrastructure separation
- Add special case guidance for "no actionable errors"
- Update report structure template
- Update completion criteria for recommendations section

### Phase 3: Update Documentation
**Complexity**: Low
**Tasks**:
- Update repair-command-guide.md with scope clarification
- Add examples showing error-fix-only plans
- Add troubleshooting section for "plan includes infrastructure"
- Update command description in commands/README.md

### Phase 4: Testing and Validation
**Complexity**: Low
**Tasks**:
- Test /repair with real production errors
- Verify plan focuses on error fixes only
- Test with test-artifact-only errors (should get "no actionable errors" plan)
- Test with filtered errors (--type, --command, --since)
- Validate scope verification warnings work correctly

## Success Criteria

### Primary Criteria
- [ ] /repair with production errors creates plans that ONLY fix those errors
- [ ] /repair with test artifacts creates minimal plan noting no actionable errors
- [ ] Plans do NOT include infrastructure improvements (rotation, cleanup, metadata)
- [ ] Plans DO include fixes for root causes identified in analysis

### Validation Criteria
- [ ] ERROR_DESCRIPTION clearly states "fix errors" intent
- [ ] plan-architect prompt includes explicit scope constraints
- [ ] repair-analyst recommendations separate fixes from infrastructure
- [ ] Scope verification catches infrastructure keywords in plans

### Documentation Criteria
- [ ] Command guide clarifies /repair scope is error fixing only
- [ ] Examples show error-fix-only plans
- [ ] Troubleshooting covers "plan too broad" scenario

## References

### Analyzed Files
- /home/benjamin/.config/.claude/specs/841_error_analysis_repair/plans/backups/001_error_analysis_repair_plan_20251119_232415.md (problematic plan)
- /home/benjamin/.config/.claude/specs/841_error_analysis_repair/reports/001_error_analysis.md (analysis that led to plan)
- /home/benjamin/.config/.claude/commands/repair.md (current command implementation)
- /home/benjamin/.config/.claude/agents/repair-analyst.md (error analysis agent)
- /home/benjamin/.config/.claude/agents/plan-architect.md (planning agent)
- /home/benjamin/.config/.claude/commands/plan.md (comparison pattern)

### Key Insights
- repair-analyst recommendations mixed error fixes with infrastructure (lines 89-131 of error_analysis.md)
- plan-architect implemented all recommendations without scope filtering (plan lines 110-380)
- /plan command provides explicit scope through user description (plan.md line 42)
- /repair uses generic description "error analysis and repair" (repair.md line 91)

### Standards References
- Command development patterns: .claude/docs/guides/development/command-development/command-development-fundamentals.md
- Workflow patterns: .claude/docs/architecture/state-based-orchestration-overview.md
- Agent behavioral injection: .claude/docs/concepts/patterns/behavioral-injection.md
