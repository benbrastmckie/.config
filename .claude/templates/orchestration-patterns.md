# Orchestration Patterns Reference

This file contains reusable templates and patterns for multi-agent workflow orchestration. These patterns are referenced by `/orchestrate` and other coordination commands.

## Table of Contents

1. [Agent Prompt Templates](#agent-prompt-templates)
2. [Phase Coordination Patterns](#phase-coordination-patterns)
3. [Checkpoint Structure](#checkpoint-structure)
4. [Error Recovery Patterns](#error-recovery-patterns)
5. [Progress Streaming Patterns](#progress-streaming-patterns)

---

## Agent Prompt Templates

### Research Agent Prompt Template

Use this template for each research-specialist agent invocation. Substitute placeholders before invoking.

**Placeholders**:
- `[THINKING_MODE]`: Value from complexity analysis (think, think hard, think harder, or empty)
- `[TOPIC_TITLE]`: Research topic title (e.g., "Authentication Patterns in Codebase")
- `[USER_WORKFLOW]`: Original user workflow description (1 line)
- `[PROJECT_NAME]`: Generated project name slug
- `[TOPIC_SLUG]`: Generated topic slug
- `[SPECS_DIR]`: Path to specs directory
- `[ABSOLUTE_REPORT_PATH]`: ABSOLUTE path for report file (CRITICAL - must be absolute)
- `[COMPLEXITY_LEVEL]`: Simple|Medium|Complex|Critical
- `[SPECIFIC_REQUIREMENTS]`: What this agent should investigate

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Research Task: [TOPIC_TITLE]

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Topic Slug**: [TOPIC_SLUG]
- **Research Focus**: [SPECIFIC_REQUIREMENTS]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md
- **Complexity Level**: [COMPLEXITY_LEVEL]

## Objective
Investigate [SPECIFIC_REQUIREMENTS] to inform planning and implementation phases.

## Specs Directory Context
- **Specs Directory Detection**:
  1. Check .claude/SPECS.md for registered specs directories
  2. If no SPECS.md, use Glob to find existing specs/ directories
  3. Default to project root specs/ if none found
- **Report Location**: Create report in [SPECS_DIR]/reports/[TOPIC_SLUG]/NNN_report_name.md
- **Include in Metadata**: Add "Specs Directory" field to report metadata

## Research Requirements

[SPECIFIC_REQUIREMENTS - Agent should investigate these areas:]

### For "existing_patterns" Topics:
- Search codebase for related implementations using Grep/Glob
- Read relevant source files to understand current patterns
- Identify architectural decisions and design patterns used
- Document file locations with line number references
- Note any inconsistencies or technical debt

### For "best_practices" Topics:
- Use WebSearch to find 2025-current best practices
- Focus on authoritative sources (official docs, security guides)
- Compare industry standards with current implementation
- Identify gaps between best practices and current state
- Recommend specific improvements

### For "alternatives" Topics:
- Research 2-3 alternative implementation approaches
- Document pros/cons of each alternative
- Consider trade-offs (performance, complexity, maintainability)
- Recommend which alternative best fits this project
- Provide concrete examples from similar projects

### For "constraints" Topics:
- Identify technical limitations (platform, dependencies, performance)
- Document security considerations and requirements
- Note compatibility requirements (backwards compatibility, API contracts)
- Consider resource constraints (time, team expertise, infrastructure)
- Flag high-risk areas requiring careful design

## Report File Creation

You MUST create a research report file using the Write tool. Do NOT return only a summary.

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE report file path for you. You MUST use this exact path when creating the report file:

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns.md`

**DO NOT**:
- Recalculate the path yourself
- Use relative paths (e.g., `specs/reports/...`)
- Change the directory location
- Modify the report number

**DO**:
- Use the Write tool with the exact path provided above
- Create the report at the specified ABSOLUTE path
- Return this exact path in your REPORT_PATH: output

**Report Structure** (use this exact template):

```markdown
# [Report Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Specs Directory**: [SPECS_DIR]
- **Report Number**: NNN (within topic subdirectory)
- **Topic**: [TOPIC_SLUG]
- **Created By**: /orchestrate (research phase)
- **Workflow**: [USER_WORKFLOW]

## Implementation Status
- **Status**: Research Complete
- **Plan**: (will be added by plan-architect)
- **Implementation**: (will be added after implementation)
- **Date**: YYYY-MM-DD

## Research Focus
[Description of what this research investigated]

## Findings

### Current State Analysis
[Detailed findings from codebase analysis - include file references with line numbers]

### Industry Best Practices
[Findings from web research - include authoritative sources]

### Key Insights
[Important discoveries, patterns identified, issues found]

## Recommendations

### Primary Recommendation: [Approach Name]
**Description**: [What this approach entails]
**Pros**:
- [Advantage 1]
- [Advantage 2]
**Cons**:
- [Limitation 1]
**Suitability**: [Why this fits the project]

### Alternative Approach: [Approach Name]
[Secondary recommendation if applicable]

## Potential Challenges
- [Challenge 1 and mitigation strategy]
- [Challenge 2 and mitigation strategy]

## References
- [File: path/to/file.ext, lines X-Y - description]
- [URL: https://... - authoritative source]
- [Related code: path/to/related.ext]
```

## Expected Output

**Primary Output**: Report file path in this exact format:
```
REPORT_PATH: [ABSOLUTE_REPORT_PATH]
```

**CRITICAL**: This must be the exact ABSOLUTE path provided to you by the orchestrator. Do NOT output a relative path.

**Secondary Output**: Brief summary (1-2 sentences):
- What was researched
- Key finding or primary recommendation

**Example Output**:
```
REPORT_PATH: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_auth_patterns.md

Research investigated current authentication implementations in the codebase. Found
session-based auth using Redis with 30-minute TTL. Primary recommendation: Extend
existing session pattern rather than implementing OAuth from scratch.
```

## Success Criteria
- Report file created at correct path with correct number
- Report includes all required metadata fields
- Findings include specific file references with line numbers
- Recommendations are actionable and project-specific
- Report path returned in parseable format (REPORT_PATH: ...)
```

---

### Planning Agent Prompt Template

Template for plan-architect agent invocation during planning phase.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[USER_WORKFLOW]`: Original workflow description
- `[PROJECT_NAME]`: Generated project name
- `[RESEARCH_REPORTS]`: Array of absolute report paths from research phase
- `[PLAN_PATH]`: ABSOLUTE path for plan file
- `[COMPLEXITY_LEVEL]`: Workflow complexity level

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Planning Task: Create Implementation Plan

## Context
- **Workflow**: [USER_WORKFLOW]
- **Project Name**: [PROJECT_NAME]
- **Complexity Level**: [COMPLEXITY_LEVEL]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Research Reports Available

You have access to the following research reports created during the research phase:

[RESEARCH_REPORTS - List each report with its path and brief summary]

Example:
1. **Existing Patterns**: `/home/benjamin/.config/.claude/specs/reports/topic1/001_existing_patterns.md`
   - Current authentication uses session-based approach with Redis
2. **Security Practices**: `/home/benjamin/.config/.claude/specs/reports/topic2/002_security_practices.md`
   - Industry standards recommend JWT with refresh tokens

## Objective

Create a comprehensive implementation plan that:
1. Synthesizes findings from all research reports
2. Defines clear implementation phases with tasks
3. Follows project standards from CLAUDE.md
4. Includes testing and validation steps
5. Identifies risks and dependencies

## Plan Creation

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE plan file path for you. You MUST use this exact path:

**Plan Path**: [PLAN_PATH]

Example: `/home/benjamin/.config/.claude/specs/plans/042_user_authentication.md`

Use the Write tool to create the plan at this exact path.

## Plan Structure

Follow the standard implementation plan structure:

```markdown
# [Feature Name] Implementation Plan

## Metadata
- **Date**: YYYY-MM-DD
- **Plan Number**: NNN
- **Feature**: [Feature description]
- **Scope**: [Scope summary]
- **Estimated Phases**: N
- **Research Reports**:
  - [List all research report paths used]
- **Standards File**: /home/benjamin/.config/CLAUDE.md

## Overview

[Brief description of what will be implemented]

## Success Criteria

[Define what "done" looks like]

- [ ] Success criterion 1
- [ ] Success criterion 2

## Technical Design

### Design Principles

[Key principles guiding implementation]

### Architecture Decisions

[Major architectural decisions and rationale]

## Implementation Phases

### Phase 1: [Phase Name]

**Objective**: [What this phase accomplishes]

**Complexity**: Low|Medium|High
**Risk**: Low|Medium|High
**Dependencies**: [List dependencies]
**Estimated Time**: X-Y hours

#### Tasks

- [ ] Task 1
- [ ] Task 2

#### Testing

[How to test this phase]

#### Phase 1 Completion Criteria

- [ ] All tasks complete
- [ ] Tests passing
- [ ] Git commit created

### Phase 2: [Phase Name]

[Continue for each phase...]

## Testing Strategy

[Overall testing approach]

## Dependencies

[External and internal dependencies]

## Risk Assessment

[Risks and mitigation strategies]

## Success Metrics

[How to measure success]
```

## Expected Output

**Primary Output**: Plan file path in this exact format:
```
PLAN_PATH: [PLAN_PATH]
```

**Secondary Output**: Brief summary (2-3 sentences):
- What the plan covers
- Number of phases
- Estimated total time

## Success Criteria

- Plan file created at correct path
- Plan references all research reports
- Plan follows project standards
- All phases have clear tasks and success criteria
- Plan path returned in parseable format (PLAN_PATH: ...)
```

---

### Implementation Agent Prompt Template

Template for code-writer agent invocation during implementation phase.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[PLAN_PATH]`: ABSOLUTE path to implementation plan
- `[STARTING_PHASE]`: Phase number to start from (for resume)

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Implementation Task: Execute Plan

## Context
- **Plan Path**: [PLAN_PATH]
- **Starting Phase**: [STARTING_PHASE]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Objective

Execute the implementation plan phase-by-phase with:
1. Automated testing after each phase
2. Git commits after successful phases
3. Checkpoint saves for resumability
4. Adaptive replanning if complexity exceeds estimates

## Implementation Protocol

Use the `/implement` command with the plan path:

```bash
/implement [PLAN_PATH] [STARTING_PHASE]
```

The `/implement` command will:
- Parse the plan file
- Execute each phase sequentially
- Run tests defined in phase tasks
- Update plan file with completion markers
- Create git commits after each phase
- Save checkpoints for resume capability

## Adaptive Planning Integration

If during implementation you discover:
- Phase complexity score >8
- More than 10 tasks in a phase
- Test failures indicating missing prerequisites

Then use `/revise --auto-mode` to update the plan structure before continuing.

## Expected Output

**Primary Output**: Implementation summary:
- Number of phases completed
- Tests status (passing/failing)
- Files modified
- Commits created

**If Tests Fail**: Return control to orchestrator for debugging loop entry.

## Success Criteria

- All planned phases executed
- Tests passing
- Git commits created for each phase
- Implementation complete or checkpoint saved for resume
```

---

### Debug Agent Prompt Template

Template for debug-specialist agent invocation during debugging loop.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[TEST_FAILURES]`: Description of test failures
- `[ITERATION]`: Current debug iteration (1-3)
- `[DEBUG_REPORT_PATH]`: ABSOLUTE path for debug report

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Debug Task: Investigate Test Failures

## Context
- **Iteration**: [ITERATION] of 3
- **Test Failures**: [TEST_FAILURES]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Objective

Investigate test failures and create a diagnostic report with:
1. Root cause analysis
2. Recommended fixes
3. Test cases to verify fixes
4. Prevention strategies

## Investigation Protocol

1. **Analyze Test Output**: Understand what tests are failing and why
2. **Search Codebase**: Use Grep/Glob to find relevant code
3. **Identify Root Cause**: Determine the underlying issue
4. **Recommend Fix**: Provide specific, actionable fix recommendations
5. **Create Debug Report**: Document findings at specified path

## Debug Report Creation

**CRITICAL: Use the Provided Absolute Path**:

**Debug Report Path**: [DEBUG_REPORT_PATH]

Example: `/home/benjamin/.config/debug/test_failures/001_auth_timeout.md`

## Debug Report Structure

```markdown
# Debug Report: [Issue Title]

## Metadata
- **Date**: YYYY-MM-DD
- **Debug Iteration**: [ITERATION]
- **Created By**: /orchestrate (debugging phase)

## Problem Statement

[Clear description of test failures]

## Root Cause Analysis

### Investigation Steps
[What was investigated and how]

### Root Cause
[What is causing the failures]

### Supporting Evidence
[File references, line numbers, error messages]

## Recommended Fix

### Fix Description
[What needs to be changed]

### Implementation Steps
1. [Step 1]
2. [Step 2]

### Files to Modify
- `path/to/file.ext` (lines X-Y): [change description]

## Test Verification

### Test Cases
[How to verify the fix works]

### Expected Behavior After Fix
[What should happen after fix is applied]

## Prevention Strategy

[How to prevent this issue in the future]
```

## Expected Output

**Primary Output**: Debug report path:
```
DEBUG_REPORT_PATH: [DEBUG_REPORT_PATH]
```

**Secondary Output**: Fix recommendation summary (2-3 sentences)

## Success Criteria

- Root cause identified
- Fix recommendations are specific and actionable
- Debug report created at correct path
- Report includes file references with line numbers
```

---

### Documentation Agent Prompt Template

Template for doc-writer agent invocation during documentation phase.

**Placeholders**:
- `[THINKING_MODE]`: Complexity-based thinking mode
- `[WORKFLOW_STATE]`: Complete workflow state with all phase results
- `[SUMMARY_PATH]`: ABSOLUTE path for workflow summary

**Template**:

```markdown
**Thinking Mode**: [THINKING_MODE]

# Documentation Task: Generate Workflow Summary

## Context
- **Workflow Completed**: [WORKFLOW_STATE.workflow_description]
- **Project Standards**: /home/benjamin/.config/CLAUDE.md

## Workflow Results

### Research Phase
- Reports Created: [List of report paths]
- Research Topics: [List of topics]

### Planning Phase
- Plan Created: [Plan path]
- Phases Defined: [Number]

### Implementation Phase
- Files Modified: [List]
- Tests Status: [Passing/Failing]
- Commits Created: [Number]

### Debugging Phase (if occurred)
- Debug Iterations: [Number]
- Debug Reports: [List of paths]

## Objective

Create a comprehensive workflow summary that:
1. Documents what was accomplished
2. Links all artifacts (reports, plan, code changes)
3. Provides performance metrics
4. Records lessons learned

## Workflow Summary Creation

**CRITICAL: Use the Provided Absolute Path**:

**Summary Path**: [SUMMARY_PATH]

Example: `/home/benjamin/.config/.claude/specs/summaries/042_implementation_summary.md`

## Summary Structure

```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: YYYY-MM-DD
- **Plan**: [Link to plan file]
- **Research Reports**: [Links to reports]
- **Phases Completed**: N/N

## Implementation Overview

[Brief description of what was implemented]

## Workflow Execution

### Research Phase
- Duration: X minutes
- Agents Invoked: N
- Reports Created:
  1. [Report path] - [Brief description]
  2. [Report path] - [Brief description]

### Planning Phase
- Duration: X minutes
- Plan Created: [Plan path]
- Phases Defined: N

### Implementation Phase
- Duration: X minutes
- Phases Completed: N/N
- Tests Status: Passing/Failing
- Files Modified:
  - [file path]
  - [file path]
- Commits: [Number]

### Debugging Phase
- Iterations: N/3
- Issues Resolved: [Description]
- Debug Reports:
  - [Debug report path]

### Documentation Phase
- Duration: X minutes
- Documentation Updated: [List]

## Key Changes

- [Major change 1]
- [Major change 2]

## Test Results

[Summary of test outcomes]

## Performance Metrics

- Total Duration: X minutes
- Research Parallelization Savings: X minutes
- Debug Iterations: N
- Agents Invoked: N
- Files Created: N

## Lessons Learned

[Insights from implementation]

## Cross-References

- Plan: [plan path]
- Reports: [list of report paths]
- Debug Reports: [list if any]
- Code Changes: [git commit hashes]
```

## Expected Output

**Primary Output**: Summary path:
```
SUMMARY_PATH: [SUMMARY_PATH]
```

**Secondary Output**: Brief summary (2-3 sentences)

## Success Criteria

- Summary file created at correct path
- All artifacts cross-referenced
- Performance metrics included
- Lessons learned documented
```

---

## Phase Coordination Patterns

### Research Phase (Parallel Execution)

**Pattern**: Launch multiple research agents concurrently, wait for all to complete, then proceed.

**Key Steps**:
1. Identify 2-4 research topics from workflow description
2. Calculate absolute report paths for each topic
3. Launch ALL research agents in a SINGLE MESSAGE (enables parallelization)
4. Monitor progress with PROGRESS: markers
5. Verify all report files created successfully
6. Proceed to planning phase

**Parallel Invocation Example**:
```
I'll launch 3 research agents in parallel:

[Task tool invocation #1 for existing_patterns]
[Task tool invocation #2 for security_practices]
[Task tool invocation #3 for framework_implementations]
```

**Critical Requirements**:
- All Task invocations must be in ONE message
- Use ABSOLUTE paths for report files
- Verify report files exist before proceeding
- Handle missing reports with retry logic

---

### Planning Phase (Sequential Execution)

**Pattern**: Invoke plan-architect agent to synthesize research into implementation plan.

**Key Steps**:
1. Collect all research report paths from research phase
2. Calculate absolute plan path
3. Invoke plan-architect agent with research reports as input
4. Verify plan file created successfully
5. Parse plan file to validate structure
6. Proceed to implementation phase

**Sequential Requirement**: Planning cannot start until ALL research complete.

---

### Implementation Phase (Adaptive Execution)

**Pattern**: Invoke code-writer agent with /implement command, handle adaptive replanning if needed.

**Key Steps**:
1. Invoke code-writer with plan path and starting phase
2. Monitor implementation progress
3. If tests fail: enter debugging loop (max 3 iterations)
4. If complexity exceeds estimates: adaptive replanning with /revise
5. If successful: proceed to documentation phase

**Adaptive Triggers**:
- Phase complexity >8: Auto-expand phase
- Test failures: Enter debugging loop
- Scope drift: Manual /revise invocation

---

### Debugging Loop (Conditional Execution)

**Pattern**: If implementation tests fail, enter iterative debug-fix loop (max 3 iterations).

**Key Steps**:
1. Detect test failures from implementation phase
2. Invoke debug-specialist agent with failure details
3. Apply recommended fixes via code-writer
4. Re-run tests
5. If tests pass: exit loop and proceed to documentation
6. If tests still fail: increment iteration counter
7. If iteration > 3: escalate to user

**Loop Control**:
- Max 3 iterations enforced
- User escalation if exhausted
- Checkpoint saved at each iteration

---

### Documentation Phase (Sequential Execution)

**Pattern**: Invoke doc-writer agent to create workflow summary and update project documentation.

**Key Steps**:
1. Collect complete workflow_state with all phase results
2. Calculate absolute summary path
3. Invoke doc-writer agent with workflow state
4. Verify summary file created
5. Workflow complete

**Sequential Requirement**: Documentation only runs after implementation fully complete.

---

## Checkpoint Structure

### Workflow Checkpoint Format

Checkpoints enable workflow resumption after interruption.

**Checkpoint File Location**:
```
.claude/checkpoints/orchestrate_[project_name]_[timestamp].json
```

**Checkpoint Structure**:
```json
{
  "checkpoint_type": "orchestrate",
  "created_at": "2025-10-12T14:30:22",
  "workflow_description": "[User's workflow description]",
  "workflow_type": "feature",
  "thinking_mode": "think hard",
  "current_phase": "implementation",
  "completed_phases": ["analysis", "research", "planning"],
  "project_name": "user_authentication_system",

  "context_preservation": {
    "research_reports": [
      "/absolute/path/to/report1.md",
      "/absolute/path/to/report2.md"
    ],
    "plan_path": "/absolute/path/to/plan.md",
    "implementation_status": {
      "tests_passing": false,
      "files_modified": ["file1.lua", "file2.lua"],
      "current_phase": 3,
      "total_phases": 5
    },
    "debug_reports": [],
    "documentation_paths": []
  },

  "execution_tracking": {
    "phase_start_times": {
      "analysis": "2025-10-12T14:30:00",
      "research": "2025-10-12T14:31:00",
      "planning": "2025-10-12T14:38:00",
      "implementation": "2025-10-12T14:45:00"
    },
    "phase_end_times": {
      "analysis": "2025-10-12T14:31:00",
      "research": "2025-10-12T14:38:00",
      "planning": "2025-10-12T14:45:00"
    },
    "agent_invocations": [
      {
        "agent_type": "research-specialist",
        "topic": "existing_patterns",
        "timestamp": "2025-10-12T14:31:00",
        "success": true,
        "report_path": "/absolute/path/to/report1.md"
      }
    ],
    "error_history": [],
    "debug_iteration": 0
  },

  "performance_metrics": {
    "total_duration_seconds": 900,
    "research_parallelization_savings": 120,
    "debug_iterations_used": 0,
    "agents_invoked": 4,
    "files_created": 7
  }
}
```

### Checkpoint Save Operations

**When to Save Checkpoints**:
- After research phase completes
- After planning phase completes
- After each implementation phase
- Before entering debugging loop
- After each debug iteration
- When workflow interrupted

**Checkpoint Save Function**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

save_checkpoint "orchestrate" "$(create_checkpoint_json)"
```

### Checkpoint Resume Operations

**Resume Detection**:
```bash
# Check for existing checkpoint
if [ -f .claude/checkpoints/orchestrate_latest.checkpoint ]; then
  echo "Found existing orchestration checkpoint"
  echo "Resume workflow from [current_phase]? (y/n)"
fi
```

**Resume Logic**:
1. Load checkpoint JSON
2. Restore workflow_state from checkpoint
3. Skip completed phases
4. Resume from current_phase
5. Continue workflow normally

---

## Error Recovery Patterns

### Agent Invocation Failure Recovery

**Pattern**: Use retry_with_backoff for automatic recovery from transient failures.

**Implementation**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/error-utils.sh"

# Define agent invocation function
invoke_research_agent() {
  # Task tool invocation
  return $?
}

# Retry with exponential backoff
if retry_with_backoff invoke_research_agent "research_agent_1"; then
  echo "✓ Agent invocation successful"
else
  # All retries exhausted
  ERROR_TYPE=$(classify_error "$RESULT")
  format_error_report "$ERROR_TYPE" "$RESULT" "research"
  save_checkpoint_and_escalate
fi
```

**Retry Configuration**:
- Max attempts: 3
- Initial delay: 2s
- Backoff multiplier: 2x
- Max delay: 30s

---

### File Verification Failure Recovery

**Pattern**: Verify expected files created, retry if missing.

**Implementation**:
```bash
# After agent completes, verify report file
verify_report_file() {
  local report_path="$1"
  [ -f "$report_path" ] && [ -s "$report_path" ]
}

if ! retry_with_backoff "verify_report_file $EXPECTED_REPORT_PATH"; then
  # File missing after retries
  echo "ERROR: Expected report not created: $EXPECTED_REPORT_PATH"

  # Check if file exists at alternative location
  ALTERNATIVE_PATH=$(find .claude/specs -name "*${TOPIC_SLUG}*.md" -type f 2>/dev/null | head -1)

  if [ -n "$ALTERNATIVE_PATH" ]; then
    echo "Found report at alternative location: $ALTERNATIVE_PATH"
    echo "Using this path instead"
    EXPECTED_REPORT_PATH="$ALTERNATIVE_PATH"
  else
    # Truly missing - retry agent invocation
    echo "Retrying agent invocation..."
    retry_with_backoff invoke_research_agent
  fi
fi
```

---

### Test Failure Recovery

**Pattern**: Enter debugging loop for systematic test failure resolution.

**Implementation**:
```bash
# After implementation phase
if ! tests_passing; then
  DEBUG_ITERATION=0
  MAX_DEBUG_ITERATIONS=3

  while [ $DEBUG_ITERATION -lt $MAX_DEBUG_ITERATIONS ]; do
    DEBUG_ITERATION=$((DEBUG_ITERATION + 1))

    echo "PROGRESS: Entering debugging loop (iteration $DEBUG_ITERATION/$MAX_DEBUG_ITERATIONS)"

    # Invoke debug-specialist
    DEBUG_REPORT=$(invoke_debug_specialist "$TEST_FAILURES")

    # Apply recommended fix
    apply_fix "$DEBUG_REPORT"

    # Re-run tests
    if tests_passing; then
      echo "PROGRESS: Tests passing ✓ - debugging complete"
      break
    fi

    # Save checkpoint after each iteration
    save_checkpoint "orchestrate" "$WORKFLOW_STATE"
  done

  if [ $DEBUG_ITERATION -eq $MAX_DEBUG_ITERATIONS ] && ! tests_passing; then
    echo "ERROR: Debug iterations exhausted, tests still failing"
    save_checkpoint_and_escalate
  fi
fi
```

**Loop Control**:
- Max 3 iterations
- Checkpoint saved each iteration
- User escalation if exhausted

---

### Checkpoint Save Failure Recovery

**Pattern**: Gracefully degrade if checkpoint save fails (non-critical operation).

**Implementation**:
```bash
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkpoint-utils.sh"

if ! save_checkpoint "orchestrate" "$CHECKPOINT_DATA"; then
  # Save failed - warn but continue
  echo "⚠ Warning: Checkpoint save failed"
  echo "Workflow will continue, but resume may not be possible"

  # Log failure for debugging
  log_error "checkpoint_save_failed" "orchestrate" "$CURRENT_PHASE"

  # Continue execution (checkpoint is not critical)
fi
```

**Graceful Degradation**: Workflow continues even if checkpoint fails.

---

## Progress Streaming Patterns

### Progress Marker Format

Use `PROGRESS:` prefix for all progress messages:

```
PROGRESS: [phase] - [action_description]
```

### Phase Transition Progress Markers

```
PROGRESS: Starting Research Phase (parallel execution)
PROGRESS: Research Phase complete - 3 reports created
PROGRESS: Starting Planning Phase (sequential execution)
PROGRESS: Planning Phase complete - plan created
PROGRESS: Starting Implementation Phase (adaptive execution)
PROGRESS: Implementation Phase complete - tests passing
PROGRESS: Starting Documentation Phase (sequential execution)
PROGRESS: Documentation Phase complete - workflow summary generated
```

### Agent Invocation Progress Markers

```
PROGRESS: Invoking 3 research-specialist agents in parallel...
PROGRESS: Research agent 1/3 completed (existing_patterns)
PROGRESS: Research agent 2/3 completed (security_practices)
PROGRESS: Research agent 3/3 completed (framework_implementations)
```

### Debugging Loop Progress Markers

```
PROGRESS: Entering debugging loop (iteration 1/3)
PROGRESS: Invoking debug-specialist agent...
PROGRESS: Debug report created: debug/test_failures/001_auth_timeout.md
PROGRESS: Applying recommended fix via code-writer agent...
PROGRESS: Fix applied - running tests...
PROGRESS: Tests passing ✓ - debugging complete
```

### File Operation Progress Markers

```
PROGRESS: Saving research checkpoint...
PROGRESS: Checkpoint saved: .claude/checkpoints/orchestrate_user_auth_20251012_143022.json
PROGRESS: Verifying report files created...
PROGRESS: All 3 reports verified and readable
```

---

## Usage Notes

### Referencing This File

From `/orchestrate` command:
```markdown
For detailed agent prompt templates, see:
`.claude/templates/orchestration-patterns.md`
```

### Updating Templates

When updating templates:
1. Update this file with new template versions
2. Update `/orchestrate` to reference new templates if structure changes
3. Test templates with sample workflows
4. Document changes in git commit message

### Template Versioning

This file represents the current template standards. Historical templates are preserved in git history.

---

**Last Updated**: 2025-10-13
**Used By**: /orchestrate, /debug, /plan, /implement
**Related Files**:
- `.claude/commands/orchestrate.md`
- `.claude/lib/checkpoint-utils.sh`
- `.claude/lib/error-utils.sh`
