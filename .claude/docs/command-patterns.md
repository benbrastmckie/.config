# Command Implementation Patterns

This document provides reusable patterns and examples for implementing Claude Code commands. Commands should reference these patterns rather than duplicating documentation inline.

**Last Updated**: 2025-10-10

---

## Table of Contents

1. [Agent Invocation Patterns](#agent-invocation-patterns)
2. [Checkpoint Management Patterns](#checkpoint-management-patterns)
3. [Error Recovery Patterns](#error-recovery-patterns)
4. [Artifact Referencing Patterns](#artifact-referencing-patterns)
5. [Testing Integration Patterns](#testing-integration-patterns)
6. [Progress Streaming Patterns](#progress-streaming-patterns)
7. [Standards Discovery Patterns](#standards-discovery-patterns)
8. [Logger Initialization Pattern](#logger-initialization-pattern)
9. [Pull Request Creation Pattern](#pull-request-creation-pattern)
10. [Parallel Execution Safety Pattern](#parallel-execution-safety-pattern)

---

## Agent Invocation Patterns

Commands that coordinate specialized agents should use behavioral injection for clear role assignment and tool restrictions.

### Pattern: Single Agent with Behavioral Injection

Use when delegating a focused task to one specialized agent.

**Example: Invoke research-specialist agent**

```
Task tool invocation with:
  subagent_type: "general-purpose"
  description: "Research existing auth patterns in codebase"

Agent prompt should include:
  1. Behavioral guidelines reference
  2. Role assignment
  3. Task context and requirements
  4. Clear objective
  5. Expected output format
  6. Success criteria
```

**Template**:
```
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/[agent-name].md

You are acting as a [Agent Role] with the tools and constraints
defined in that file.

[Task-specific context]

## Objective
[Clear, focused objective]

## Requirements
- [Requirement 1]
- [Requirement 2]

## Expected Output
[Exact format specification]

## Success Criteria
- [Criterion 1]
- [Criterion 2]
```

### Pattern: Parallel Agent Invocation

Use when multiple independent research tasks can run concurrently.

**Key Principle**: Each agent receives ONLY its specific focus. NO orchestration routing logic in prompts.

**How to invoke parallel agents**:
- Send single message with multiple Task tool calls
- Each Task block gets independent context
- No cross-referencing between agents
- Agents run concurrently, not sequentially

**Example from /orchestrate**:
```
Three research agents launched in parallel:
- Agent 1: Research existing patterns in codebase
- Agent 2: Research industry best practices
- Agent 3: Research alternative approaches

Each receives:
- Behavioral guidelines reference
- Specific research focus (only theirs)
- Project standards reference
- Expected output format (concise summary)
```

### Pattern: Sequential Agent Chain

Use when one agent's output informs the next agent's task.

**Example flow**:
1. Research agent → produces findings
2. Planning agent → uses findings to create plan
3. Implementation agent → executes plan
4. Documentation agent → documents changes

**Critical**: Store only paths/references between phases, not full content.

---

## Checkpoint Management Patterns

Commands should save checkpoints after completing major operations to enable recovery from interruptions.

### Pattern: Save Checkpoint After Phase

Use checkpoint utilities to preserve state after each major operation.

**When to checkpoint**:
- After completing a major phase
- Before starting a risky operation
- After successful test runs
- When user interaction is required

**Example**:
```bash
# Save checkpoint after research phase
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$WORKFLOW_STATE_JSON"
```

**Checkpoint data structure**:
```yaml
checkpoint_name:
  phase_name: "[current phase]"
  completion_time: "[ISO 8601 timestamp]"
  outputs:
    primary_output: "[path or summary]"
    status: "success|partial|failed"
  next_phase: "[next phase name or 'complete']"
  performance:
    phase_duration: "[seconds]"
```

### Pattern: Resume from Checkpoint

Check for existing checkpoints at command start to enable workflow resumption.

**Steps**:
1. Check for checkpoint file
2. If found, offer resume options to user
3. Load checkpoint data if user chooses resume
4. Skip completed phases
5. Continue from next incomplete phase

**Example**:
```bash
# Load most recent checkpoint
CHECKPOINT=$(.claude/lib/load-checkpoint.sh orchestrate 2>/dev/null || echo "")

if [ -n "$CHECKPOINT" ]; then
  # Present resume options to user
  # Load workflow state
  # Skip to next phase
fi
```

### Pattern: Checkpoint Cleanup

Remove checkpoints after successful completion or archive on failure.

**On success**:
```bash
rm .claude/data/checkpoints/${COMMAND}_${PROJECT}_*.json
```

**On failure**:
```bash
mv .claude/data/checkpoints/${COMMAND}_${PROJECT}_*.json .claude/data/checkpoints/failed/
```

---

## Error Recovery Patterns

Commands should implement graceful error handling with automatic retry and user escalation.

### Pattern: Automatic Retry with Backoff

Retry transient failures before escalating to user.

**Standard retry sequence** (max 3 attempts):
1. **First retry**: Same operation with extended timeout
2. **Second retry**: Modified approach (simpler requirements)
3. **Third retry**: Alternative method or tool
4. **Escalation**: Report to user with context

**Example**:
```yaml
Retry 1: Extend Timeout
  - timeout: original_timeout * 1.5
  - same_parameters: true

Retry 2: Simplify Task
  - reduce_complexity: true
  - accept_partial_success: true

Retry 3: Alternative Approach
  - use_fallback_method: true
  - different_tools: true

Escalation: Report to User
  - attempts_made: 3
  - error_details: [full context]
  - user_action_required: true
```

### Pattern: Error Classification and Routing

Different error types require different recovery strategies.

**Error types**:
1. **Timeout errors**: Extend timeout or split task
2. **Tool access errors**: Verify permissions or use alternative tools
3. **Validation failures**: Clarify requirements or accept partial results
4. **Test failures**: Enter debugging loop (max 3 iterations)
5. **Integration errors**: Retry command or use workaround

**Example routing**:
```
if error_type == "timeout":
    retry_with_extended_timeout()
elif error_type == "validation":
    retry_with_clarified_prompt()
elif error_type == "test_failure":
    enter_debugging_loop()
else:
    escalate_to_user()
```

### Pattern: User Escalation Format

When automatic recovery fails, provide structured information for user intervention.

**Escalation message should include**:
- Clear problem description
- Current phase/context
- Number of retry attempts made
- Chronological error history
- Current state (checkpoints, artifacts)
- Available options for user

**Example**:
```markdown
⚠ Manual Intervention Required

Issue: [Brief problem description]
Phase: [Current workflow phase]
Attempts: [N retry attempts made]

Error History:
- Attempt 1: [What was tried] → [Result]
- Attempt 2: [What was tried] → [Result]
- Attempt 3: [What was tried] → [Result]

Current State:
- Completed phases: [list]
- Last checkpoint: [phase name]
- Generated artifacts: [paths]

Options:
1. Review errors and continue manually
2. Modify approach and retry
3. Rollback to checkpoint
4. Terminate workflow

Please provide guidance.
```

---

## Artifact Referencing Patterns

Commands should use pass-by-reference for artifacts to minimize context usage.

### Pattern: Artifact Storage and Registry

Store research outputs and reports as files, maintain registry with references.

**Benefits**:
- Reduces context usage (50-word reference vs 200-word content)
- Preserves full details for later access
- Enables selective reading by agents
- Supports bidirectional cross-referencing

**Example workflow**:
```
1. Agent produces research findings (150 words)
2. Save to artifact file: specs/artifacts/{project}/topic.md
3. Register in artifact_registry:
   - ID: research_001
   - Path: specs/artifacts/{project}/topic.md
   - Topic: [topic name]
4. Pass only reference to next agent (not full content)
5. Next agent uses Read tool if needed
```

**Artifact file format**:
```markdown
# [Artifact Title]

## Metadata
- Created: YYYY-MM-DD
- Workflow: [workflow description]
- Agent: [agent-name]
- Focus: [specific focus area]

## Findings
[Full content]

## Recommendations
[Key recommendations]
```

### Pattern: Artifact Reference List

Pass lightweight references to subsequent phases instead of full content.

**Reference format**:
```markdown
Available Research Artifacts:

1. **research_001** - Existing Patterns
   - Path: specs/artifacts/{project}/existing_patterns.md
   - Focus: Current implementation analysis
   - Key Finding: [One-sentence summary]

2. **research_002** - Best Practices
   - Path: specs/artifacts/{project}/best_practices.md
   - Focus: Industry standards (2025)
   - Key Finding: [One-sentence summary]

Total Context: ~50 words (vs 200+ for full summaries)
```

**Agent instruction**:
```
Use Read tool to access artifact content selectively.
Not all artifacts may be needed for your task.
```

### Pattern: Bidirectional Cross-References

Link artifacts to plans and summaries in both directions.

**After creating summary**:
1. Summary links to plan and reports (forward)
2. Update plan with summary reference (backward)
3. Update each report with summary reference (backward)

**Example: Update plan with summary reference**:
```markdown
## Implementation Summary
- Status: Complete
- Date: YYYY-MM-DD
- Summary: [link to specs/summaries/NNN_summary.md]
```

**Example: Update report with implementation status**:
```markdown
## Implementation Status
- Status: Implemented
- Date: YYYY-MM-DD
- Plan: [link to specs/plans/NNN_plan.md]
- Summary: [link to specs/summaries/NNN_summary.md]
```

---

## Testing Integration Patterns

Commands should discover test commands from CLAUDE.md and run tests at appropriate checkpoints.

### Pattern: Test Discovery from CLAUDE.md

Commands should check CLAUDE.md Testing Protocols section for test commands.

**Discovery priority**:
1. Project root CLAUDE.md
2. Subdirectory-specific CLAUDE.md
3. Language-specific defaults

**Example CLAUDE.md Testing Protocols**:
```markdown
## Testing Protocols

### Test Discovery
- Test Location: `.claude/tests/`
- Test Runner: `./run_all_tests.sh`
- Test Pattern: `test_*.sh`
- Coverage Target: ≥80% for new code

### Test Commands
- Full suite: `.claude/tests/run_all_tests.sh`
- Single test: `.claude/tests/test_specific.sh`
- Coverage: `coverage run && coverage report`
```

### Pattern: Phase-by-Phase Testing

Run tests after each implementation phase, not just at the end.

**Why test per phase**:
- Catch errors early
- Prevent compounding issues
- Enable safe rollback to last passing phase
- Maintain clean git history

**Example flow**:
```
Phase 1:
  - Implement tasks
  - Run phase tests
  - Verify tests pass
  - Create git commit
  - Save checkpoint

Phase 2:
  - Implement tasks
  - Run phase tests
  - [Tests fail] → Enter debugging loop
  - Fix issues
  - Re-run tests
  - [Tests pass] → Create git commit
  - Save checkpoint
```

### Pattern: Test Failure Handling

When tests fail, stop implementation and enter debugging loop.

**Do NOT**:
- Skip failing tests
- Continue to next phase
- Commit failing code

**DO**:
- Stop at failing phase
- Enter debugging loop (max 3 iterations)
- Fix root cause
- Re-run tests
- Only proceed when tests pass

**Example debugging loop**:
```
Iteration 1:
  - Investigate failure
  - Propose fix
  - Apply fix
  - Re-run tests

If still failing and iteration < 3:
  - Increment iteration
  - Retry with more context

If iteration == 3 and still failing:
  - Escalate to user
  - Provide debug reports
  - Request guidance
```

---

## Progress Streaming Patterns

Commands that invoke agents should display progress updates to users in real-time.

### Pattern: Progress Marker Detection

Agents emit `PROGRESS: <message>` markers during execution. Commands should detect and display these.

**Example agent progress markers**:
```
PROGRESS: Searching codebase for auth patterns...
PROGRESS: Found 15 files, analyzing...
PROGRESS: Generating implementation plan...
PROGRESS: Analyzing requirements...
PROGRESS: Designing 4 phases...
```

**Command responsibility**:
- Watch for `PROGRESS:` markers in agent output
- Extract message portion
- Display to user in real-time
- Track overall progress

### Pattern: TodoWrite Integration

Use TodoWrite tool to track multi-phase operations and update status.

**Initial todo list**:
```
- [ ] Research phase
- [ ] Planning phase
- [ ] Implementation phase
- [ ] Testing phase
- [ ] Documentation phase
```

**Update as phases complete**:
```
- [x] Research phase (completed)
- [x] Planning phase (completed)
- [ ] Implementation phase (in progress)
- [ ] Testing phase (pending)
- [ ] Documentation phase (pending)
```

**Benefits**:
- User visibility into progress
- Clear sense of completion percentage
- Easy to identify current phase
- Supports interruption and resumption

### Pattern: Phase Completion Messages

Provide structured completion messages after each major phase.

**Format**:
```markdown
✓ [Phase Name] Complete

Key outputs:
- [Output 1]
- [Output 2]

Next: [Next Phase Name]
```

**Example**:
```markdown
✓ Planning Phase Complete

Plan created: specs/plans/013_feature_name.md
Phases: 4
Complexity: Medium
Incorporating research from: 2 reports

Next: Implementation Phase
```

---

## Standards Discovery Patterns

Commands should discover and apply project standards from CLAUDE.md files.

### Pattern: Upward CLAUDE.md Search

Search for CLAUDE.md files starting from current directory and moving up.

**Search sequence**:
1. Current working directory: `./CLAUDE.md`
2. Parent directories: `../CLAUDE.md`, `../../CLAUDE.md`, etc.
3. Stop at repository root or when file found

**Example**:
```bash
# Search for CLAUDE.md
find_claude_md() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/CLAUDE.md" ]; then
      echo "$dir/CLAUDE.md"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}
```

### Pattern: Standards Section Extraction

Extract relevant sections from CLAUDE.md for command execution.

**Common sections**:
- `## Code Standards` - Indentation, naming, error handling
- `## Testing Protocols` - Test commands, patterns, coverage
- `## Documentation Policy` - README requirements, format
- `## Development Philosophy` - Project values and principles

**Example extraction**:
```bash
# Extract testing protocols from CLAUDE.md
grep -A 20 "## Testing Protocols" "$CLAUDE_MD_PATH"
```

### Pattern: Standards Application During Code Generation

Apply discovered standards when generating or modifying code.

**Standards to apply**:
1. **Indentation**: Match CLAUDE.md specification (e.g., 2 spaces)
2. **Line Length**: Keep within specified limit (e.g., ~100 chars)
3. **Naming**: Follow conventions (e.g., snake_case vs camelCase)
4. **Error Handling**: Use specified patterns (e.g., pcall for Lua)
5. **Module Organization**: Follow project structure

**Example code generation with standards**:
```lua
-- From CLAUDE.md:
-- Indentation: 2 spaces, expandtab
-- Naming: snake_case for variables/functions
-- Error Handling: Use pcall

local function process_user_data(user_id)  -- snake_case
  local status, result = pcall(function()  -- pcall pattern
    local data = database.query({          -- 2-space indent
      id = user_id,
      fields = {"name", "email"}
    })
    return data
  end)

  if not status then
    print("Error: " .. result)
    return nil
  end

  return result
end
```

### Pattern: Fallback Behavior

When CLAUDE.md is missing or incomplete, use sensible language-specific defaults.

**Fallback strategy**:
1. Check for CLAUDE.md (upward search)
2. If found, extract relevant sections
3. If not found or sections missing:
   - Apply language-specific defaults
   - Log warning about missing standards
   - Suggest creating CLAUDE.md with `/setup`
4. Continue with graceful degradation

**Example defaults by language**:
- **Python**: PEP 8 (4 spaces, snake_case, 79 char lines)
- **JavaScript**: 2 spaces, camelCase, 80 char lines
- **Lua**: 2 spaces, snake_case, ~100 char lines
- **Shell**: 2 spaces, snake_case, 80 char lines

---

## Logger Initialization Pattern

Commands that use adaptive planning should initialize logging infrastructure with proper fallbacks.

### Pattern: Standard Logger Setup

Source adaptive planning logger with no-op fallbacks when unavailable.

**When to use**:
- Commands implementing adaptive planning features
- Commands that log workflow decisions
- Commands needing audit trails

**Setup steps**:
1. Check if logger utility exists
2. Source logger with error handling
3. Initialize log directory if needed
4. Set log level based on environment
5. Provide no-op fallbacks for missing functions

**Example**:
```bash
# Logger initialization with fallbacks
LOGGER_PATH=".claude/lib/adaptive-planning-logger.sh"

if [ -f "$LOGGER_PATH" ]; then
  # Source logger utility
  source "$LOGGER_PATH" || {
    echo "Warning: Failed to load logger, continuing without logging"
    # Define no-op fallbacks
    log_info() { :; }
    log_warning() { :; }
    log_error() { echo "ERROR: $*" >&2; }
    log_adaptive_event() { :; }
  }
else
  # Logger not available, define no-op fallbacks
  log_info() { :; }
  log_warning() { :; }
  log_error() { echo "ERROR: $*" >&2; }
  log_adaptive_event() { :; }
fi

# Initialize log directory with permissions
LOG_DIR=".claude/logs"
if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR" 2>/dev/null || {
    echo "Warning: Could not create log directory"
  }
fi

# Set appropriate permissions
chmod 755 "$LOG_DIR" 2>/dev/null || true
```

**Log levels**:
- `log_info`: General information, progress updates
- `log_warning`: Non-critical issues, fallback usage
- `log_error`: Critical errors requiring attention
- `log_adaptive_event`: Adaptive planning decisions (triggers, replans)

**Best practices**:
- Always provide fallbacks for missing logger
- Never fail command due to logging issues
- Keep log_error functional even when logger unavailable
- Create log directory lazily (only when needed)
- Handle permissions errors gracefully

---

## Pull Request Creation Pattern

Commands should support optional GitHub PR creation with graceful degradation.

### Pattern: GitHub CLI PR Creation

Create pull requests using GitHub CLI with comprehensive error handling.

**When to use**:
- After completing implementation phases
- When code changes are ready for review
- Optional enhancement to workflow commands
- When `--create-pr` flag is provided

**Prerequisites**:
```bash
# Check GitHub CLI availability
if ! command -v gh &>/dev/null; then
  echo "GitHub CLI (gh) not found. Skipping PR creation."
  echo "Install: https://cli.github.com/"
  return 0
fi

# Check authentication
if ! gh auth status &>/dev/null; then
  echo "GitHub CLI not authenticated. Run: gh auth login"
  return 0
fi
```

**PR Creation workflow**:
```bash
# 1. Ensure branch is pushed
CURRENT_BRANCH=$(git branch --show-current)
if ! git ls-remote --heads origin "$CURRENT_BRANCH" &>/dev/null; then
  git push -u origin "$CURRENT_BRANCH" || {
    echo "Failed to push branch. PR creation aborted."
    return 1
  }
fi

# 2. Generate PR title and body
PR_TITLE="feat: ${FEATURE_NAME}"
PR_BODY=$(cat <<'EOF'
## Summary
${SUMMARY}

## Changes
${CHANGES_LIST}

## Test Plan
${TEST_PLAN}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)

# 3. Create PR using gh CLI
PR_URL=$(gh pr create \
  --title "$PR_TITLE" \
  --body "$PR_BODY" \
  --base main \
  2>&1)

# 4. Capture PR URL
if [ $? -eq 0 ]; then
  echo "Pull request created: $PR_URL"
  # Update summary with PR URL
  # Add to workflow state
else
  echo "Failed to create PR: $PR_URL"
  echo "You can create it manually with:"
  echo "  gh pr create --title \"$PR_TITLE\""
fi
```

**Graceful degradation**:
```bash
# If PR creation fails, provide manual instructions
create_pr_or_fallback() {
  if gh pr create "$@" 2>&1; then
    return 0
  else
    echo ""
    echo "PR creation failed. Manual steps:"
    echo "1. Push branch: git push -u origin $(git branch --show-current)"
    echo "2. Create PR: gh pr create --web"
    echo "   OR visit: https://github.com/${REPO}/compare/main...$(git branch --show-current)"
    return 1
  }
}
```

**PR body template**:
```markdown
## Summary
[Brief description of changes]

## Changes
- [Change 1]
- [Change 2]
- [Change 3]

## Test Plan
- [x] All tests passing
- [x] No linting errors
- [ ] Manual testing completed

## Related
- Plan: [link to implementation plan]
- Reports: [links to research reports]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Best practices**:
- Make PR creation optional (flag-controlled)
- Check prerequisites before attempting
- Provide clear manual fallback instructions
- Include links to plans and reports in PR body
- Never fail the main workflow if PR creation fails
- Capture PR URL for inclusion in summaries

---

## Parallel Execution Safety Pattern

Commands executing tasks in parallel must implement safety controls to prevent failures.

### Pattern: Controlled Parallel Execution

Execute independent tasks concurrently with fail-fast behavior and checkpointing.

**When to use**:
- Multiple independent phases can run simultaneously
- No data dependencies between tasks
- Significant time savings from parallelization
- Risk of cascading failures needs mitigation

**Safety controls**:
1. **Maximum parallelism limit**: Cap concurrent operations (typically 3)
2. **Fail-fast wave execution**: Stop wave on first failure
3. **Checkpoint between waves**: Save state after each wave completes
4. **Result aggregation**: Collect and validate all results before proceeding

**Example implementation**:
```bash
# Parallel execution with safety controls
MAX_PARALLEL=3
WAVE_SIZE=$MAX_PARALLEL

execute_parallel_phases() {
  local phases=("$@")
  local total=${#phases[@]}
  local wave_num=1
  local failed=0

  # Execute phases in waves
  for ((i=0; i<total; i+=WAVE_SIZE)); do
    echo "Wave $wave_num: Executing phases $((i+1))-$((i+WAVE_SIZE))..."

    # Start parallel execution for this wave
    local pids=()
    local wave_phases=()

    for ((j=0; j<WAVE_SIZE && i+j<total; j++)); do
      local phase="${phases[i+j]}"
      wave_phases+=("$phase")

      # Execute phase in background
      execute_phase "$phase" &
      pids+=($!)
    done

    # Wait for all processes in wave and check results
    for idx in "${!pids[@]}"; do
      local pid="${pids[idx]}"
      local phase="${wave_phases[idx]}"

      if wait "$pid"; then
        echo "✓ Phase $phase completed successfully"
      else
        echo "✗ Phase $phase failed"
        failed=1
        break  # Fail-fast: stop waiting for others in wave
      fi
    done

    # If any phase failed, stop execution
    if [ $failed -eq 1 ]; then
      echo "Wave $wave_num failed. Stopping execution."
      # Kill remaining processes
      for pid in "${pids[@]}"; do
        kill "$pid" 2>/dev/null || true
      done
      return 1
    fi

    # Save checkpoint after successful wave
    save_checkpoint "wave_${wave_num}" "${wave_phases[@]}"

    wave_num=$((wave_num + 1))
  done

  return 0
}
```

**Wave execution diagram**:
```
Wave 1: [Phase 1] [Phase 2] [Phase 3]  → All succeed → Checkpoint
        ↓          ↓          ↓
Wave 2: [Phase 4] [Phase 5] [Phase 6]  → Phase 5 fails → STOP
                   ✗
        Kill remaining processes
        Rollback to Wave 1 checkpoint
```

**Result aggregation**:
```bash
# Collect results from parallel execution
aggregate_results() {
  local result_files=("$@")
  local aggregated=""

  for result_file in "${result_files[@]}"; do
    if [ -f "$result_file" ]; then
      local content=$(cat "$result_file")
      aggregated="${aggregated}\n${content}"
    else
      echo "Warning: Result file missing: $result_file"
      return 1
    fi
  done

  echo -e "$aggregated"
}
```

**Checkpoint preservation**:
```bash
# Save checkpoint after each wave
save_wave_checkpoint() {
  local wave_num=$1
  shift
  local completed_phases=("$@")

  local checkpoint_data=$(cat <<EOF
{
  "wave": $wave_num,
  "completed_phases": $(printf '%s\n' "${completed_phases[@]}" | jq -R . | jq -s .),
  "timestamp": "$(date -Iseconds)",
  "status": "wave_complete"
}
EOF
)

  echo "$checkpoint_data" > ".claude/data/checkpoints/wave_${wave_num}.json"
}
```

**Best practices**:
- Limit parallelism to 3 concurrent operations (prevents resource exhaustion)
- Implement fail-fast behavior (stop on first failure)
- Save checkpoints between waves (enable recovery)
- Validate all results before proceeding
- Clean up background processes on failure
- Provide clear progress indicators for each wave
- Log wave execution for debugging

**When NOT to use**:
- Tasks have data dependencies
- Tasks must execute in specific order
- Shared resource contention is high
- Failure in one task requires others to complete

---

## Notes

### Pattern Usage

Commands should reference these patterns using relative links:

```markdown
For agent invocation examples, see [Agent Invocation Patterns](../docs/command-patterns.md#agent-invocation-patterns).
```

### Pattern Maintenance

This file is the single source of truth for common command patterns. When patterns evolve:

1. Update this file with new patterns
2. No need to update all commands immediately
3. Commands reference this file, so they get updates automatically
4. Document pattern version/date if breaking changes occur

### When to Extract vs Inline

**Extract to this file** when:
- Pattern appears in 3+ commands
- Pattern is >50 lines
- Pattern is complex and benefits from detailed explanation
- Pattern evolves frequently

**Keep inline in command** when:
- Pattern is command-specific
- Pattern is <20 lines
- Pattern is simple and self-explanatory
- Command needs unique variation of pattern

---

**Revision History**:
- 2025-10-10: Initial extraction from orchestrate.md, setup.md, implement.md during Phase 4 of Claude system optimization
