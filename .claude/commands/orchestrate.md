---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential]
description: Coordinate subagents through end-to-end development workflows
command-type: primary
dependent-commands: report, plan, implement, debug, test, document
---

# Multi-Agent Workflow Orchestration

I'll coordinate multiple specialized subagents through a complete development workflow, from research to documentation, while preserving context and enabling intelligent parallelization.

## Workflow Analysis

Let me first analyze your workflow description to identify the natural phases and requirements.

### Step 1: Parse Workflow Description

I'll extract:
- **Core Feature/Task**: What needs to be accomplished
- **Workflow Type**: Feature development, refactoring, debugging, or investigation
- **Complexity Indicators**: Keywords suggesting scope and approach
- **Parallelization Hints**: Tasks that can run concurrently

### Step 2: Identify Workflow Phases

Based on the description, I'll determine which phases are needed:

**Standard Development Workflow**:
1. **Research Phase** (Parallel): Investigate patterns, best practices, alternatives
2. **Planning Phase** (Sequential): Synthesize findings into structured plan
3. **Implementation Phase** (Adaptive): Execute plan with testing
4. **Debugging Loop** (Conditional): Fix failures if tests don't pass
5. **Documentation Phase** (Sequential): Update docs and generate summary

**Simplified Workflows** (for straightforward tasks):
- Skip research if task is well-understood
- Direct to implementation for simple fixes
- Minimal documentation for internal changes

### Step 3: Initialize Workflow State

I'll create minimal orchestrator state:

```yaml
workflow_state:
  workflow_description: "[User's request]"
  workflow_type: "feature|refactor|debug|investigation"
  current_phase: "research|planning|implementation|debugging|documentation"
  completed_phases: []

checkpoints:
  research_complete: null
  plan_ready: null
  implementation_complete: null
  tests_passing: null
  workflow_complete: null

context_preservation:
  research_summary: ""  # Max 200 words
  plan_path: ""
  implementation_status:
    tests_passing: false
    files_modified: []
  documentation_paths: []

error_history: []
performance_metrics:
  phase_times: {}
  parallel_effectiveness: 0
```

## Phase Coordination

### Research Phase (Parallel Execution)

#### Step 1: Identify Research Topics

I'll analyze the workflow description to extract 2-4 focused research topics:

**Topic Extraction Logic**:
- **Existing Patterns**: "How is [feature/component] currently implemented?"
- **Best Practices**: "What are industry standards for [technology/approach]?"
- **Alternatives**: "What alternative approaches exist for [problem]?"
- **Technical Constraints**: "What limitations or requirements should we consider?"

**Complexity-Based Research Strategy**:
```yaml
Simple Workflows (skip research):
  - Keywords: "fix", "update", "small change"
  - Action: Skip directly to planning phase

Medium Workflows (focused research):
  - Keywords: "add", "improve", "refactor"
  - Topics: 2-3 focused areas
  - Example: existing patterns + best practices

Complex Workflows (comprehensive research):
  - Keywords: "implement", "redesign", "architecture"
  - Topics: 3-4 comprehensive areas
  - Example: patterns + practices + alternatives + constraints
```

#### Step 2: Launch Parallel Research Agents

For each identified research topic, I'll create a focused research task and invoke agents in parallel:

**Parallel Execution Pattern**:
```markdown
Use Task tool to invoke multiple research-specialist subagents simultaneously:

Agent 1 - Codebase Patterns:
  subagent_type: research-specialist
  Prompt: "Search the codebase for existing implementations of [feature/concept].
          Analyze patterns, architectures, and conventions currently in use.
          Summarize findings in max 150 words."

Agent 2 - Best Practices Research:
  subagent_type: research-specialist
  Prompt: "Research industry best practices for [technology/approach].
          Use web search to find current standards (2025).
          Summarize key recommendations in max 150 words."

Agent 3 - Alternative Approaches:
  subagent_type: research-specialist
  Prompt: "Investigate alternative approaches to [problem/feature].
          Compare trade-offs, complexity, and fit with project.
          Summarize options in max 150 words."
```

**Critical Context Preservation Rule**:
- Each research agent receives ONLY its specific research focus
- NO orchestration routing logic in agent prompts
- NO information about other parallel agents
- Complete task description with success criteria
- Reference to CLAUDE.md for project standards

#### Step 3: Research Agent Prompt Template

```markdown
# Research Task: [Specific Topic]

## Context
- **Workflow**: [User's original request - brief 1 line summary]
- **Research Focus**: [This agent's specific investigation area]
- **Project Standards**: Reference CLAUDE.md at /home/benjamin/.config/CLAUDE.md

## Objective
Investigate [specific topic] to inform the planning and implementation phases of this workflow.

## Requirements

### Investigation Scope
- [Specific requirement 1]
- [Specific requirement 2]
- [Specific requirement 3]

### Research Methods
- **Codebase Search**: Use Grep/Glob to find existing patterns
- **Documentation Review**: Read relevant files and docs
- **Web Research**: Use WebSearch for industry standards (if applicable)
- **Analysis**: Evaluate findings for relevance and applicability

## Expected Output

Provide a concise summary (max 150 words) structured as:

**Findings Summary**
- Existing patterns found (if any)
- Recommended approaches
- Potential challenges or constraints
- Key insights for planning

## Success Criteria
- Findings are actionable and specific
- Recommendations align with project standards
- Challenges are clearly identified
- Summary is concise and focused

## Error Handling
- If search yields no results: State "No existing patterns found" and recommend research-based approach
- If access errors occur: Work with available tools and note limitations
- If topic is unclear: Make reasonable assumptions and document them
```

#### Step 4: Aggregate and Synthesize Research (Minimal Context)

After all parallel research agents complete:

**Aggregation Process**:
1. **Collect Results**: Gather summaries from all research agents (each ≤150 words)
2. **Synthesize Findings**: Create unified summary combining key insights
3. **Minimize Context**: Reduce to max 200 words total
4. **Extract Actionables**: Identify specific recommendations for planning

**Synthesis Template**:
```markdown
Research Summary (max 200 words):

Existing Patterns:
- [Key pattern 1 from codebase research]
- [Key pattern 2 from codebase research]

Best Practices:
- [Key recommendation 1 from best practices research]
- [Key recommendation 2 from best practices research]

Recommended Approach:
- [Synthesized recommendation based on all research]
- [Alternative if primary approach has constraints]

Key Constraints:
- [Important limitation 1]
- [Important limitation 2]

Actionable Insights:
- [Specific insight 1 for planning]
- [Specific insight 2 for planning]
```

**Context Minimization Strategy**:
- Store ONLY the synthesized summary, not individual research outputs
- Focus on actionable insights, not exhaustive details
- Reference specific files/patterns by path, not content
- Keep orchestrator context <30% of normal usage

#### Step 5: Save Research Checkpoint

**Checkpoint Data Structure**:
```yaml
checkpoint_research_complete:
  phase_name: "research"
  completion_time: [timestamp]
  outputs:
    research_summary: "[200 word synthesis]"
    topics_investigated: ["topic1", "topic2", "topic3"]
    parallel_agents_used: 3
    status: "success"
  next_phase: "planning"
  performance:
    research_time: "[duration in seconds]"
    parallel_effectiveness: "[time saved vs sequential]"
```

**Checkpoint Storage**:
- Save checkpoint to workflow state (in orchestrator memory)
- Mark research phase as completed
- Enable recovery if workflow interrupts before planning

#### Step 6: Context Preservation Validation

Before proceeding to planning:

**Validation Checks**:
- [ ] Research summary ≤200 words
- [ ] No full research outputs stored in orchestrator context
- [ ] Only file paths referenced, not file contents
- [ ] Actionable insights clearly identified
- [ ] Checkpoint saved successfully

**If validation fails**: Compress summary further or escalate to user

#### Research Phase Execution Example

```markdown
User Request: "Add user authentication with email and password"

Identified Research Topics:
1. Existing auth patterns in codebase
2. Security best practices for auth (2025)
3. Framework-specific auth implementations

Parallel Agent Invocations:
[Agent 1 - Codebase] → Finds: "No existing auth, uses session management in user.lua"
[Agent 2 - Security] → Finds: "Bcrypt for passwords, JWT for sessions, 2FA recommended"
[Agent 3 - Framework] → Finds: "Lua has lua-resty-jwt, examples in nginx configs"

Synthesized Summary (180 words):
"Codebase currently has session management in nvim/lua/neotex/user.lua but no
authentication system. Industry best practices (2025) recommend bcrypt for password
hashing, JWT tokens for session management, and optional 2FA for enhanced security.

Lua ecosystem provides lua-resty-jwt for token handling. Recommended approach:
Implement authentication module following existing session management patterns,
use bcrypt for password storage, JWT for auth tokens.

Key constraints: Neovim environment may limit some libraries; focus on pure Lua
solutions. Alternative: Delegate auth to external service if complexity warrants.

Actionable insights: Build on user.lua patterns, create auth/ subdirectory, implement
login/logout/verify functions, integrate with existing session system, add migration
for user credentials table, implement password reset flow, consider rate limiting."

Checkpoint Saved: research_complete
Next Phase: planning
```

### Planning Phase (Sequential Execution)

#### Step 1: Prepare Planning Context

Extract necessary context from previous phases:

**From Research Phase** (if completed):
```yaml
research_context:
  summary: "[200 word research summary]"
  key_insights: "[3-5 actionable insights]"
  recommended_approach: "[Synthesized recommendation]"
```

**From User Request**:
```yaml
user_context:
  workflow_description: "[Original request]"
  feature_name: "[Extracted feature/task name]"
  workflow_type: "feature|refactor|debug|investigation"
```

**Context Injection Strategy**:
- Provide research summary if available
- Include user's original request for context
- Reference CLAUDE.md for project standards
- NO orchestration details or phase routing logic

#### Step 2: Generate Planning Agent Prompt

```markdown
# Planning Task: Create Implementation Plan for [Feature Name]

## Context

### User Request
[Original workflow description]

### Research Findings
[If research phase completed, include 200-word summary]
[If no research, state: "Direct implementation - no prior research"]

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

## Objective
Create a comprehensive, phased implementation plan for [feature/task] that:
- Synthesizes research findings into actionable steps
- Defines clear implementation phases with tasks
- Establishes testing strategy for each phase
- Follows project coding standards and conventions

## Requirements

### Plan Structure
Use the /plan command to generate a structured implementation plan:

```bash
/plan [feature description] [research-report-path-if-exists]
```

The plan should include:
- Metadata (date, feature, scope, standards file, research reports)
- Overview and success criteria
- Technical design decisions
- Implementation phases with specific tasks
- Testing strategy
- Documentation requirements
- Risk assessment

### Task Specificity
Each task should:
- Reference specific files to create/modify
- Include line number ranges where applicable
- Specify testing requirements
- Define validation criteria

### Context from Research
[If research completed]
Incorporate these key findings:
- [Insight 1]
- [Insight 2]
- [Insight 3]

Recommended approach: [From research synthesis]

## Expected Output

**Primary Output**: Path to generated implementation plan
- Format: `specs/plans/NNN_feature_name.md`
- Location: Most appropriate directory in project structure

**Secondary Output**: Brief summary of plan
- Number of phases
- Estimated complexity
- Key technical decisions

## Success Criteria
- Plan follows project standards (CLAUDE.md)
- Phases are well-defined and testable
- Tasks are specific and actionable
- Testing strategy is comprehensive
- Plan integrates research recommendations

## Error Handling
- If /plan command fails: Report error and provide manual planning guidance
- If standards unclear: Make reasonable assumptions following best practices
- If research conflicts: Document trade-offs and chosen approach
```

#### Step 3: Invoke Planning Agent

**Task Tool Invocation**:
```yaml
subagent_type: plan-architect
description: "Create implementation plan for [feature]"
prompt: "[Generated planning prompt from Step 2]"
```

**Execution Details**:
- Single agent (sequential execution)
- Full access to project files for analysis
- Can invoke /plan slash command
- Returns plan file path and summary

#### Step 4: Extract Plan Path and Validation

**Path Extraction**:
```markdown
From planning agent output, extract:
- Plan file path: specs/plans/NNN_*.md
- Plan number: NNN
- Phase count: N phases
- Complexity estimate: Low|Medium|High
```

**Validation Checks**:
- [ ] Plan file exists and is readable
- [ ] Plan follows standard format (metadata, phases, tasks)
- [ ] Plan references research reports (if applicable)
- [ ] Plan includes testing strategy
- [ ] Tasks are specific with file references

**If validation fails**:
- Retry planning with clarifications
- If retry fails: Escalate to user with error details

#### Step 5: Save Planning Checkpoint

**Checkpoint Data**:
```yaml
checkpoint_plan_ready:
  phase_name: "planning"
  completion_time: [timestamp]
  outputs:
    plan_path: "specs/plans/NNN_feature_name.md"
    plan_number: NNN
    phase_count: N
    complexity: "Low|Medium|High"
    status: "success"
  next_phase: "implementation"
  performance:
    planning_time: "[duration in seconds]"
```

**Context Update**:
- Store ONLY plan path, not plan content
- Mark planning phase as completed
- Prepare for implementation phase

#### Step 6: Planning Phase Completion

**Output to User** (brief status):
```markdown
✓ Planning Phase Complete

Plan created: specs/plans/NNN_feature_name.md
Phases: N
Complexity: Medium
Incorporating research from: [report paths if any]

Next: Implementation Phase
```

### Implementation Phase (Adaptive Execution)

#### Step 1: Prepare Implementation Context

**From Planning Phase**:
```yaml
implementation_context:
  plan_path: "specs/plans/NNN_feature_name.md"
  plan_number: NNN
  phase_count: N
  complexity: "Low|Medium|High"
```

**Execution Strategy**:
```yaml
strategy_selection:
  if complexity == "Low":
    approach: "direct_implementation"
    parallelization: false
  elif complexity == "Medium":
    approach: "phased_implementation"
    parallelization: "within_phases"
  else:  # High complexity
    approach: "incremental_phased"
    parallelization: "aggressive"
```

#### Step 2: Generate Implementation Agent Prompt

```markdown
# Implementation Task: Execute Implementation Plan

## Context

### Implementation Plan
Plan file: [plan_path]

Read the complete plan to understand:
- All implementation phases
- Specific tasks for each phase
- Testing requirements
- Success criteria

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

## Objective
Execute the implementation plan phase by phase, ensuring:
- All tasks completed as specified
- Tests pass after each phase
- Code follows project standards
- Git commits created per phase

## Requirements

### Execution Approach
Use the /implement command to execute the plan:

```bash
/implement [plan-file-path]
```

The implementation will:
- Parse plan and identify all phases
- Execute Phase 1 tasks
- Run tests specified in Phase 1
- Create git commit for Phase 1
- Repeat for all subsequent phases
- Handle errors with automatic retry

### Phase-by-Phase Execution
For each phase:
1. Display phase name and tasks
2. Implement all tasks in phase
3. Run phase-specific tests
4. Validate all tests pass
5. Create structured git commit
6. Save checkpoint before next phase

### Testing Requirements
- Run tests after EACH phase (not just at end)
- Tests must pass before proceeding to next phase
- If tests fail: Stop and report for debugging
- Test commands specified in plan or project standards

### Error Handling
- Automatic retry for transient errors (max 3 attempts)
- If tests fail: Do not proceed to next phase
- Report test failures with detailed error messages
- Preserve all completed work even if later phase fails

## Expected Output

**Primary Output**: Implementation results
- Tests passing: true|false
- Phases completed: N/M
- Files modified: [list of changed files]
- Git commits: [list of commit hashes]

**If Tests Fail**:
- Phase where failure occurred
- Test failure details
- Error messages
- Modified files up to failure point

## Success Criteria
- All plan phases executed successfully
- All tests passing
- Code follows project standards
- Git commits created for each phase
- No merge conflicts or build errors

## Error Handling
- Timeout errors: Retry with extended timeout
- Test failures: Stop and report (do not skip)
- Tool access errors: Retry with available tools
- If persistent errors: Escalate to debugging loop
```

#### Step 3: Invoke Implementation Agent

**Task Tool Invocation**:
```yaml
subagent_type: code-writer
description: "Execute implementation plan [plan_number]"
prompt: "[Generated implementation prompt from Step 2]"
timeout: 600000  # 10 minutes for complex implementations
```

**Monitoring**:
- Track implementation progress via agent updates
- Watch for test failure signals
- Monitor for error patterns

#### Step 4: Extract Implementation Status

**Status Extraction**:
```markdown
From implementation agent output, extract:

Success Case:
- tests_passing: true
- phases_completed: "N/N"
- files_modified: [file1.ext, file2.ext, ...]
- git_commits: [hash1, hash2, ...]
- implementation_status: "success"

Failure Case:
- tests_passing: false
- phases_completed: "M/N" (M < N)
- failed_phase: N
- error_message: "[Test failure details]"
- files_modified: [files changed before failure]
- implementation_status: "failed"
```

**Validation**:
- [ ] Implementation completed all phases OR reported specific failure
- [ ] Test status clearly indicated
- [ ] Modified files list available
- [ ] Error details provided if failed

#### Step 5: Conditional Branch - Test Status Check

```yaml
if tests_passing == true:
  next_phase: "documentation"
  save_checkpoint: "implementation_complete"
else:
  next_phase: "debugging"
  save_checkpoint: "implementation_incomplete"
  prepare_debug_context:
    - failed_phase: N
    - error_message: "[details]"
    - modified_files: [list]
    - plan_path: "[path]"
```

#### Step 6: Save Implementation Checkpoint

**Success Checkpoint**:
```yaml
checkpoint_implementation_complete:
  phase_name: "implementation"
  completion_time: [timestamp]
  outputs:
    tests_passing: true
    phases_completed: "N/N"
    files_modified: [list]
    git_commits: [list]
    status: "success"
  next_phase: "documentation"
  performance:
    implementation_time: "[duration]"
```

**Failure Checkpoint** (for debugging):
```yaml
checkpoint_implementation_incomplete:
  phase_name: "implementation"
  completion_time: [timestamp]
  outputs:
    tests_passing: false
    phases_completed: "M/N"
    failed_phase: N
    error_message: "[details]"
    files_modified: [list]
    status: "failed"
  next_phase: "debugging"
  debug_context:
    failure_details: "[error messages]"
    affected_files: [list]
    plan_reference: "[plan_path]"
```

#### Step 7: Implementation Phase Completion

**Success Output**:
```markdown
✓ Implementation Phase Complete

All phases executed: N/N
Tests passing: ✓
Files modified: M files
Git commits: N commits

Next: Documentation Phase
```

**Failure Output** (triggers debugging):
```markdown
⚠ Implementation Phase Incomplete

Phases completed: M/N
Failed at: Phase N
Tests passing: ✗

Error: [Test failure details]

Next: Debugging Loop
```

### Debugging Loop (Conditional - Only if Tests Fail)

This phase engages ONLY when implementation reports test failures. Maximum 3 debugging iterations before escalating to user.

#### Step 1: Prepare Debug Context

**From Implementation Failure**:
```yaml
debug_context:
  failed_phase: N
  error_message: "[Test failure details]"
  files_modified: [list of changed files]
  plan_path: "specs/plans/NNN_*.md"
  tests_attempted: "[Test command that failed]"
```

**Iteration Tracking**:
```yaml
debug_iteration:
  current: 1|2|3
  max_iterations: 3
  previous_attempts: []  # Track what was tried
```

#### Step 2: Generate Debug Agent Prompt

```markdown
# Debug Task: Investigate Test Failures

## Context

### Test Failure Information
Failed Phase: Phase [N]
Error Message:
```
[Full error output from tests]
```

### Modified Files
Files changed during implementation:
- [file1.ext]
- [file2.ext]
- ...

### Implementation Plan
Plan reference: [plan_path]
Review the plan to understand intended behavior.

### Debug Iteration
Attempt: [1|2|3] of 3
Previous attempts: [If iteration > 1, list what was already tried]

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

## Objective
Investigate the test failures and create a diagnostic report with fix proposals.

**Critical**: This is investigation ONLY. Do NOT modify code in this task.

## Requirements

### Investigation Approach
Use the /debug command to perform root cause analysis:

```bash
/debug "[Brief description of failure]" [plan-path]
```

### Analysis Steps
1. **Reproduce the Issue**: Understand how to trigger the failure
2. **Identify Root Cause**: Determine why tests are failing
3. **Evaluate Impact**: Assess scope of the problem
4. **Propose Fixes**: Suggest specific code changes

### Focus Areas
- Logic errors in implementation
- Missing edge case handling
- Integration issues between components
- Test configuration problems
- Dependency issues

## Expected Output

**Primary Output**: Debug report path
- Format: specs/reports/NNN_debug_[issue].md
- Contains: Root cause analysis and fix proposals

**Secondary Output**: Fix summary
- Concise description of proposed fixes (max 100 words)
- Specific files to modify
- Confidence level: High|Medium|Low

## Success Criteria
- Root cause clearly identified
- Fix proposals are specific and actionable
- Proposals address the actual test failures
- Risk assessment included for each fix

## Error Handling
- If issue is unclear: Document assumptions and request clarification
- If multiple potential causes: Prioritize by likelihood
- If fix requires major refactoring: Note this and suggest iterative approach
```

#### Step 3: Invoke Debug Agent

**Task Tool Invocation**:
```yaml
subagent_type: debug-specialist
description: "Debug test failures from Phase [N]"
prompt: "[Generated debug prompt from Step 2]"
```

**Monitoring**:
- Track debug progress
- Watch for root cause identification
- Monitor for escalation signals

#### Step 4: Extract Debug Report and Fix Proposals

**Report Extraction**:
```markdown
From debug agent output, extract:
- debug_report_path: "specs/reports/NNN_debug_*.md"
- root_cause: "[Brief description]"
- fix_proposals: [
    {
      file: "path/to/file.ext",
      change: "[Specific modification]",
      confidence: "High|Medium|Low"
    },
    ...
  ]
- estimated_complexity: "Simple|Moderate|Complex"
```

**Validation**:
- [ ] Debug report created and accessible
- [ ] Root cause identified
- [ ] At least one fix proposal provided
- [ ] Fix proposals are specific and actionable

#### Step 5: Apply Fixes

**Fix Application Prompt**:
```markdown
# Fix Task: Apply Debug Recommendations

## Context

### Debug Report
Report: [debug_report_path]

### Root Cause
[Brief root cause description]

### Proposed Fixes
[List of specific fixes from debug report]

### Files to Modify
[List of files needing changes]

## Objective
Apply the proposed fixes to resolve test failures.

## Requirements

### Fix Application
For each proposed fix:
1. Read the affected file
2. Apply the specific change recommended
3. Ensure change follows project standards
4. Preserve existing functionality

### Testing
After applying ALL fixes:
- Run the same tests that previously failed
- Verify tests now pass
- Check for any new test failures

### Caution
- Apply ONLY the fixes from debug report
- Do NOT make additional "improvements"
- Preserve code style and conventions
- Test after ALL fixes applied (not incrementally)

## Expected Output

**Primary Output**: Fix results
- tests_passing: true|false
- fixes_applied: N
- files_modified: [list]
- test_output: "[Test results]"

**If Tests Still Fail**:
- Remaining errors: "[Error details]"
- Additional investigation needed: Yes|No

## Success Criteria
- All proposed fixes applied correctly
- Tests now passing
- No new test failures introduced
- Code follows project standards
```

**Task Tool Invocation**:
```yaml
subagent_type: code-writer
description: "Apply fixes for test failures"
prompt: "[Generated fix prompt]"
```

#### Step 6: Evaluate Fix Results

**Status Check**:
```yaml
fix_result:
  tests_passing: true|false
  fixes_applied: N
  files_modified: [list]
```

**Decision Logic**:
```yaml
if tests_passing == true:
  action: "proceed_to_documentation"
  save_checkpoint: "tests_passing"
  update_error_history:
    issue: "[Root cause]"
    resolution: "Fixed via debugging loop iteration [N]"

elif debug_iteration < 3:
  action: "retry_debugging"
  increment_iteration: true
  update_previous_attempts:
    - iteration: [N]
    - root_cause: "[What was found]"
    - fix_attempted: "[What was tried]"
    - result: "Tests still failing"

else:  # iteration == 3
  action: "escalate_to_user"
  reason: "Max debugging iterations reached"
  context:
    debug_reports: [list of all debug report paths]
    fixes_attempted: [summary of all attempts]
    current_error: "[Latest error message]"
```

#### Step 7: Iteration or Escalation

**If Retrying** (iteration < 3):
```markdown
⟳ Debugging Loop - Iteration [N+1]

Previous attempt unsuccessful.
Root cause identified: [previous root cause]
Fix applied: [previous fix]
Result: Tests still failing

New error: [current error message]

Refining analysis with additional context...
```

Return to Step 2 with updated context including previous attempts.

**If Escalating** (iteration == 3):
```markdown
⚠ Manual Intervention Required

Unable to resolve test failures after 3 debugging attempts.

Debug Reports Generated:
- [report 1 path]
- [report 2 path]
- [report 3 path]

Fixes Attempted:
1. [Attempt 1 summary]
2. [Attempt 2 summary]
3. [Attempt 3 summary]

Current Error:
```
[Latest test failure output]
```

**Options**:
1. Review debug reports and continue manually
2. Modify approach and resume debugging
3. Rollback to last successful checkpoint

Workflow paused. Please provide guidance.
```

#### Step 8: Save Debug Checkpoint

**Success Checkpoint** (tests now passing):
```yaml
checkpoint_tests_passing:
  phase_name: "debugging"
  completion_time: [timestamp]
  outputs:
    tests_passing: true
    debug_iterations: N
    debug_reports: [list of report paths]
    fixes_applied: [summary]
    status: "success"
  next_phase: "documentation"
  performance:
    debug_time: "[total debugging duration]"
    iterations_needed: N
```

**Escalation Checkpoint** (manual intervention needed):
```yaml
checkpoint_escalation:
  phase_name: "debugging"
  completion_time: [timestamp]
  outputs:
    tests_passing: false
    debug_iterations: 3
    debug_reports: [all report paths]
    fixes_attempted: [all attempts]
    current_error: "[latest error]"
    status: "escalated"
  next_phase: "manual_intervention"
  user_action_required: true
```

#### Debugging Loop Example

```markdown
Iteration 1:
- Debug: Found "undefined variable 'config' in auth.lua:42"
- Fix: Added config parameter to function signature
- Test: Still failing - "config.secret is nil"

Iteration 2:
- Debug: config.secret not initialized in test environment
- Fix: Added config initialization in test setup
- Test: Still failing - "JWT decode error"

Iteration 3:
- Debug: JWT library not available in test context
- Fix: Added jwt library mock for tests
- Test: ✓ All tests passing

Checkpoint Saved: tests_passing
Next Phase: documentation
```

### Documentation Phase (Sequential Execution)

This phase updates all relevant documentation and generates a comprehensive workflow summary.

#### Step 1: Prepare Documentation Context

**Gather All Workflow Artifacts**:
```yaml
documentation_context:
  files_modified: [list from implementation]
  plan_path: "specs/plans/NNN_*.md"
  research_reports: [list if research phase completed]
  debug_reports: [list if debugging occurred]
  test_results: "passing|fixed_after_debugging"
  workflow_description: "[Original user request]"
```

**Calculate Performance Metrics**:
```yaml
performance_summary:
  total_workflow_time: "[duration in minutes]"
  phase_breakdown:
    research: "[duration or 'skipped']"
    planning: "[duration]"
    implementation: "[duration]"
    debugging: "[duration or 'not_needed']"
    documentation: "[current phase]"

  parallelization_metrics:
    parallel_research_agents: N
    time_saved_estimate: "[% saved vs sequential]"

  error_recovery:
    total_errors: N
    auto_recovered: N
    manual_interventions: N
    recovery_success_rate: "N%"
```

#### Step 2: Generate Documentation Agent Prompt

```markdown
# Documentation Task: Update Documentation and Generate Workflow Summary

## Context

### Workflow Overview
Original request: [User's workflow description]
Workflow type: [feature|refactor|debug|investigation]

### Artifacts Generated
**Research Reports** (if any):
- [report_1_path]
- [report_2_path]

**Implementation Plan**:
- Path: [plan_path]
- Phases: N
- Complexity: [Low|Medium|High]

**Files Modified**:
[List of all files changed during workflow]

**Test Results**:
- Final status: [Passing|Fixed after debugging]
- Debug iterations: [N or "None"]

### Project Standards
Reference standards at: /home/benjamin/.config/CLAUDE.md

## Objective
Update all relevant documentation to reflect the changes made during this workflow
and generate a comprehensive workflow summary.

## Requirements

### Documentation Updates
Use the /document command to update affected documentation:

```bash
/document [brief description of changes]
```

The documentation agent will:
- Identify affected documentation files (READMEs, guides, specs)
- Update documentation to reflect new/changed functionality
- Ensure consistency across all documentation
- Follow project documentation standards

### Cross-Referencing
Ensure proper cross-references between:
- Research reports → Implementation plan
- Implementation plan → Workflow summary
- Modified code → Documentation updates
- All specs documents (reports, plans, summaries)

### Documentation Standards
- Follow CommonMark markdown specification
- Use Unicode box-drawing for diagrams (no ASCII art)
- No emojis in file content
- Maintain existing documentation structure
- Update modification dates

## Expected Output

**Primary Output**: Documentation paths
- Updated documentation files: [list]
- README updates: [list if any]
- Spec updates: [list if any]

**Secondary Output**: Summary preparation
- Key changes documented: Yes|No
- Cross-references verified: Yes|No
- Ready for workflow summary: Yes|No

## Success Criteria
- All affected documentation updated
- Cross-references accurate and complete
- Documentation follows project standards
- Changes are clear and comprehensive
```

#### Step 3: Invoke Documentation Agent

**Task Tool Invocation**:
```yaml
subagent_type: doc-writer
description: "Update documentation for workflow"
prompt: "[Generated documentation prompt from Step 2]"
```

**Monitoring**:
- Track documentation updates
- Verify cross-referencing
- Watch for completion signal

#### Step 4: Extract Documentation Results

**Results Extraction**:
```markdown
From documentation agent output, extract:
- updated_files: [list of documentation files modified]
- readme_updates: [list of README files updated]
- spec_updates: [list of spec files updated]
- cross_references_added: N
- documentation_complete: true|false
```

**Validation**:
- [ ] At least one documentation file updated
- [ ] Cross-references include all workflow artifacts
- [ ] Documentation follows project standards
- [ ] No broken links or invalid references

#### Step 5: Generate Workflow Summary

**Summary File Creation**:

**Location Determination**:
```yaml
summary_location:
  directory: "same as plan (specs/summaries/)"
  filename: "NNN_workflow_summary.md"
  number: "matches plan number"
```

**Summary Template**:
```markdown
# Workflow Summary: [Feature/Task Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Workflow Type**: [feature|refactor|debug|investigation]
- **Original Request**: [User's workflow description]
- **Total Duration**: [HH:MM:SS]

## Workflow Execution

### Phases Completed
- [x] Research (parallel) - [duration or "Skipped"]
- [x] Planning (sequential) - [duration]
- [x] Implementation (adaptive) - [duration]
- [x] Debugging (conditional) - [duration or "Not needed"]
- [x] Documentation (sequential) - [duration]

### Artifacts Generated

**Research Reports**:
[If research phase completed]
- [Report 1: path - brief description]
- [Report 2: path - brief description]

**Implementation Plan**:
- Path: [plan_path]
- Phases: N
- Complexity: [Low|Medium|High]
- Link: [relative link to plan file]

**Debug Reports**:
[If debugging occurred]
- [Debug report 1: path - issue addressed]

## Implementation Overview

### Key Changes
**Files Created**:
- [new_file_1.ext] - [brief purpose]
- [new_file_2.ext] - [brief purpose]

**Files Modified**:
- [modified_file_1.ext] - [changes made]
- [modified_file_2.ext] - [changes made]

**Files Deleted**:
- [deleted_file.ext] - [reason for deletion]

### Technical Decisions
[Key architectural or technical decisions made during workflow]
- Decision 1: [what and why]
- Decision 2: [what and why]

## Test Results

**Final Status**: ✓ All tests passing

[If debugging occurred]
**Debugging Summary**:
- Iterations required: N
- Issues resolved:
  1. [Issue 1 and fix]
  2. [Issue 2 and fix]

## Performance Metrics

### Workflow Efficiency
- Total workflow time: [HH:MM:SS]
- Estimated manual time: [HH:MM:SS]
- Time saved: [N%]

### Phase Breakdown
| Phase | Duration | Status |
|-------|----------|--------|
| Research | [time] | [Completed/Skipped] |
| Planning | [time] | Completed |
| Implementation | [time] | Completed |
| Debugging | [time] | [Completed/Not needed] |
| Documentation | [time] | Completed |

### Parallelization Effectiveness
- Research agents used: N
- Parallel vs sequential time: [N% faster]

### Error Recovery
- Total errors encountered: N
- Automatically recovered: N
- Manual interventions: N
- Recovery success rate: [N%]

## Cross-References

### Research Phase
[If applicable]
This workflow incorporated findings from:
- [Report 1 path and title]
- [Report 2 path and title]

### Planning Phase
Implementation followed the plan at:
- [Plan path and title]

### Related Documentation
Documentation updated includes:
- [Doc 1 path]
- [Doc 2 path]

## Lessons Learned

### What Worked Well
- [Success 1]
- [Success 2]

### Challenges Encountered
- [Challenge 1 and how it was resolved]
- [Challenge 2 and how it was resolved]

### Recommendations for Future
- [Recommendation 1]
- [Recommendation 2]

## Notes

[Any additional context, caveats, or important information about this workflow]

---

*Workflow orchestrated using /orchestrate command*
*For questions or issues, refer to the implementation plan and research reports linked above.*
```

#### Step 6: Create Summary File

**File Creation**:
```yaml
action: create_summary_file
location: "[plan_directory]/specs/summaries/NNN_workflow_summary.md"
content: "[Generated from template above]"
cross_references:
  - update_plan: add_summary_reference
  - update_reports: add_summary_reference
```

**Cross-Reference Updates**:
```markdown
Update related files to link back to summary:

In Implementation Plan (specs/plans/NNN_*.md):
Add at bottom:
## Implementation Summary
This plan was executed on [date]. See workflow summary:
- [Summary path and link]

In Research Reports (if any):
Add in relevant section:
### Implementation Reference
Findings from this report were incorporated into:
- [Plan path] - Implementation plan
- [Summary path] - Workflow execution summary
```

#### Step 7: Save Final Checkpoint

**Workflow Complete Checkpoint**:
```yaml
checkpoint_workflow_complete:
  phase_name: "documentation"
  completion_time: [timestamp]
  outputs:
    documentation_updated: [list of files]
    summary_created: "specs/summaries/NNN_*.md"
    cross_references: [count]
    status: "success"
  next_phase: "complete"

  final_metrics:
    total_workflow_time: "[duration]"
    phases_completed: [list]
    artifacts_generated: [count]
    files_modified: [count]
    error_recovery_success: "[%]"

  workflow_summary:
    research_reports: [list]
    implementation_plan: "[path]"
    workflow_summary: "[path]"
    tests_passing: true
```

#### Step 8: Workflow Completion Message

**Final Output to User**:
```markdown
✅ Workflow Complete

**Duration**: [HH:MM:SS]

**Artifacts Generated**:
[If research]
- Research reports: N ([paths])
- Implementation plan: [path]
- Workflow summary: [path]
- Documentation updates: N files

**Implementation Results**:
- Files modified: N
- Tests: ✓ All passing
[If debugging occurred]
- Issues resolved: N (after M debug iterations)

**Performance**:
- Time saved via parallelization: [N%]
- Error recovery: [N/M errors auto-recovered]

**Summary**: [summary_path]

Review the workflow summary for complete details, cross-references, and lessons learned.
```

#### Documentation Phase Example

```markdown
User Request: "Add user authentication with email and password"

Workflow Phases Completed:
✓ Research (3 parallel agents, 5min)
✓ Planning (created specs/plans/013_auth_implementation.md, 3min)
✓ Implementation (4 phases, all tests passing, 25min)
✓ Documentation (updated 3 files, created summary, 4min)

Total Duration: 37 minutes

Documentation Updated:
- nvim/README.md (added auth section)
- nvim/docs/ARCHITECTURE.md (added auth module diagram)
- nvim/lua/neotex/auth/README.md (created)

Workflow Summary Created:
- specs/summaries/013_auth_workflow_summary.md
- Cross-referenced: 2 research reports, 1 plan, 3 updated docs

Performance Metrics:
- Parallel research saved ~8 minutes (estimated)
- Zero errors, no debugging needed
- All cross-references verified

Checkpoint Saved: workflow_complete
Status: ✅ Success
```

## Context Management Strategy

### Orchestrator Context (Minimal - <30% usage)

I maintain only:
- Current workflow state (phase, completion status)
- Checkpoint data (success/failure per phase)
- High-level summaries (research: 200 words max)
- File paths (not content): plan path, modified files, doc paths
- Error history: what failed, what recovery action taken
- Performance metrics: phase times, parallel effectiveness

### Subagent Context (Comprehensive)

Each subagent receives:
- Complete task description with clear objective
- Necessary context from prior phases (summaries only)
- Project standards reference (CLAUDE.md)
- Explicit success criteria
- Expected output format
- Error handling guidance

**No routing logic or orchestration details passed to subagents.**

### Context Passing Protocol

```markdown
For each subagent invocation:
1. Extract minimal necessary context from prior phases
2. Structure as focused task description
3. Remove all orchestration routing logic
4. Include explicit success criteria
5. Specify exact output format
```

## Error Recovery Mechanism

### Error Classification

**Error Types**:
1. **Timeout Errors**: Agent execution exceeds time limits
2. **Tool Access Errors**: Permission or availability issues
3. **Validation Failures**: Output doesn't meet criteria
4. **Test Failures**: Code tests fail (handled by Debugging Loop)
5. **Integration Errors**: Command invocation failures
6. **Context Overflow**: Orchestrator context approaches limits

### Automatic Recovery Strategies

#### Timeout Errors

**Detection**:
- Agent doesn't return within expected timeframe
- Task tool reports timeout
- Progress indicators stall

**Recovery Sequence** (max 3 attempts):

**Retry 1: Extend Timeout**
```yaml
action: retry_with_extended_timeout
changes:
  - timeout: original_timeout * 1.5
  - same_agent: true
  - same_prompt: true
reasoning: "Transient slowness or complex task needs more time"
```

**Retry 2: Split Task**
```yaml
action: decompose_and_retry
changes:
  - split_into: smaller_components
  - execute: sequentially
  - timeout: original_timeout per component
reasoning: "Task too large for single execution"
```

**Retry 3: Alternative Agent**
```yaml
action: reassign_to_different_agent
changes:
  - agent_type: alternative_configuration
  - timeout: original_timeout * 2
  - simplified_prompt: true
reasoning: "Agent configuration may be issue"
```

**Escalation**: Manual intervention required

#### Tool Access Errors

**Detection**:
- "Tool not available" errors
- Permission denied messages
- File access failures

**Recovery Sequence** (max 2 attempts):

**Retry 1: Verify and Retry**
```yaml
action: verify_permissions_and_retry
checks:
  - file_permissions: check_and_report
  - tool_availability: verify_in_scope
  - retry_with: same_configuration
```

**Retry 2: Reduced Toolset**
```yaml
action: retry_with_fallback_tools
changes:
  - remove_failing_tool: true
  - use_alternatives: true
  - example: "WebSearch fails → use only local search"
```

**Escalation**: Report tool availability issues to user

#### Validation Failures

**Detection**:
- Output doesn't match expected format
- Required fields missing
- Invalid data in response

**Recovery Sequence** (max 3 attempts):

**Retry 1: Clarified Prompt**
```yaml
action: retry_with_clarification
changes:
  - add_explicit_format_spec: true
  - add_example_output: true
  - emphasize_requirements: true
```

**Retry 2: Simplified Requirements**
```yaml
action: retry_with_reduced_requirements
changes:
  - reduce_complexity: true
  - focus_on_essentials: true
  - accept_partial_success: true
```

**Retry 3: Manual Extraction**
```yaml
action: extract_manually
approach:
  - parse_unstructured_output: true
  - infer_missing_fields: true
  - validate_best_effort: true
```

**Escalation**: Accept partial results or report failure

#### Integration Errors

**Detection**:
- /command invocation fails
- SlashCommand tool errors
- Unexpected command output

**Recovery Sequence** (max 2 attempts):

**Retry 1: Direct Retry**
```yaml
action: immediate_retry
delay: 2_seconds
same_parameters: true
reasoning: "Transient command failure"
```

**Retry 2: Alternative Approach**
```yaml
action: workaround_execution
changes:
  - if_slash_command_fails: use_direct_implementation
  - example: "/plan fails → manually create plan"
```

**Escalation**: Report command ecosystem issue

#### Context Overflow Prevention

**Detection**:
- Orchestrator context approaching 30% threshold
- Large summaries or excessive state

**Recovery Actions**:

**Action 1: Context Compaction**
```yaml
action: compress_context
targets:
  - research_summary: reduce_to_key_points
  - error_history: keep_recent_only
  - file_lists: store_counts_not_names
```

**Action 2: Aggressive Summarization**
```yaml
action: extreme_summarization
approach:
  - research_summary: 100_words_max
  - keep_only: absolute_essentials
  - offload_to_files: detailed_data
```

**Action 3: Graceful Degradation**
```yaml
action: reduce_workflow_scope
changes:
  - skip_optional_phases: true
  - simplified_documentation: true
  - focus_on_core: true
```

### Checkpoint Recovery System

#### Checkpoint Creation

**After Each Successful Phase**:
```yaml
checkpoint:
  phase_name: "[current phase]"
  completion_time: "[ISO 8601 timestamp]"
  outputs:
    primary_output: "[path or concise summary]"
    secondary_outputs: [list]
    status: "success|partial|failed"
  next_phase: "[next phase name or 'complete']"
  context_snapshot:
    research_summary: "[if available]"
    plan_path: "[if available]"
    implementation_status: "[if available]"
  performance:
    phase_duration: "[seconds]"
    retry_count: N
```

**Checkpoint Storage**:
- Stored in orchestrator memory (minimal)
- Not persisted to disk (workflow is ephemeral)
- Used for in-session recovery only

#### Checkpoint Restoration

**On Workflow Interruption**:
```yaml
restoration_process:
  1_identify_last_checkpoint:
    - scan_completed_phases: true
    - find_highest_successful: true

  2_restore_context:
    - load_checkpoint_data: true
    - restore_workflow_state: true
    - preserve_error_history: true

  3_resume_execution:
    - start_from_next_phase: true
    - skip_completed_phases: true
    - maintain_continuity: true
```

**On Error Recovery**:
```yaml
rollback_process:
  if_phase_fails:
    - rollback_to: previous_successful_checkpoint
    - preserve_partial_work: true
    - log_failure: error_history

  resume_options:
    - retry_failed_phase: with_adjusted_parameters
    - skip_to_next: if_user_approves
    - manual_intervention: if_retry_exhausted
```

### Error History Tracking

**Purpose**: Learn from errors to improve future workflows

**Structure**:
```yaml
error_history:
  - timestamp: "[ISO 8601]"
    phase: "research|planning|implementation|debugging|documentation"
    error_type: "timeout|tool_access|validation|test_failure|integration"
    error_message: "[Brief description]"
    recovery_action: "[What was attempted]"
    recovery_result: "success|failed|escalated"
    lessons: "[Insights for future workflows]"
```

**Usage**:
- Track common error patterns
- Inform retry strategies
- Provide context for escalations
- Improve future orchestration

### Manual Intervention Points

#### When to Escalate

**Automatic Escalation Triggers**:
1. **Max retries exceeded** (3 attempts for most error types)
2. **Critical failures** (data loss, security issues)
3. **Debugging loop limit** (3 debugging iterations)
4. **Context overflow** (cannot compress further)
5. **Architectural decisions** (user input required)

#### Escalation Format

```markdown
⚠ Manual Intervention Required

**Issue**: [Brief description of problem]

**Phase**: [Current workflow phase]

**Attempts**: [Number of retry attempts made]

**Error History**:
[Chronological list of what was tried and results]

**Current State**:
- Completed phases: [list]
- Last successful checkpoint: [phase name]
- Partial work preserved: [yes/no]

**Options**:
1. Review detailed error logs and continue manually
2. Modify approach and resume from checkpoint
3. Rollback to last successful state
4. Terminate workflow

**Context Available**:
- [List of available checkpoints]
- [List of generated artifacts]
- [Error reports if available]

Please provide guidance on how to proceed.
```

#### User Response Handling

After escalation, workflow pauses awaiting user input:

**User Options**:
- `continue`: Resume with manual fixes
- `retry [phase]`: Retry specific phase
- `rollback [phase]`: Return to checkpoint
- `terminate`: End workflow gracefully
- `debug`: Enter manual debugging mode

**Workflow State Preservation**:
- All checkpoints maintained
- Error history available
- Partial work preserved
- Context accessible for review

## Performance Monitoring

### Metrics Collection

Track throughout workflow:
- **Phase Execution Times**: Time per phase
- **Parallelization Effectiveness**: Actual vs potential time savings
- **Error Rates**: Failures per phase
- **Context Window Utilization**: Orchestrator context usage
- **Recovery Success**: Automatic vs manual interventions

### Optimization Recommendations

After workflow completion, suggest:
- Which phases could benefit from parallelization
- Bottleneck phases for optimization
- Checkpoint placement improvements
- Context management refinements

## Execution Flow

### Initial Workflow Processing

When invoked with `<workflow-description>`:

1. **Parse and Classify**:
   - Extract feature/task description
   - Determine workflow type
   - Identify complexity level
   - Check for parallel/sequential flags

2. **Initialize TodoWrite**:
   ```markdown
   Create todo list with identified phases:
   - [ ] Research phase (if needed)
   - [ ] Planning phase
   - [ ] Implementation phase
   - [ ] Debugging loop (conditional)
   - [ ] Documentation phase
   ```

3. **Execute Phases Sequentially**:
   - Research (parallel subagents) → synthesize
   - Planning (single subagent) → extract plan path
   - Implementation (single subagent) → check tests
   - Debugging (conditional loop) → ensure tests pass
   - Documentation (single subagent) → generate summary

4. **Update TodoWrite** after each phase completion

5. **Generate Final Summary**:
   - Workflow completion report
   - Performance metrics
   - Cross-references to all generated documents

## Usage Examples

### Example 1: Feature Development
```
/orchestrate Add user authentication with email and password
```
Expected flow:
- Research: auth patterns, security best practices
- Planning: structured multi-phase plan
- Implementation: backend + frontend + tests
- Documentation: API docs, user guide

### Example 2: Bug Investigation and Fix
```
/orchestrate Fix the command picker synchronization issue
```
Expected flow:
- Research: analyze current implementation, find issue
- Planning: fix strategy with validation
- Implementation: apply fix
- Debugging: ensure tests pass
- Documentation: issue report and fix notes

### Example 3: Refactoring
```
/orchestrate Refactor the specs directory structure for better organization
```
Expected flow:
- Research: current structure, best practices
- Planning: incremental refactoring approach
- Implementation: gradual restructuring with tests
- Documentation: architectural updates

## Notes

### Architecture Principles

**Supervisor Pattern** (LangChain 2025):
- Centralized coordination with minimal state
- Specialized subagents with focused tasks
- Context isolation prevents cross-contamination
- Forward message pattern avoids paraphrasing errors

**Context Preservation**:
- Orchestrator: <30% context usage (state, checkpoints, summaries only)
- Subagents: Comprehensive context for their specific task
- No routing logic passed to workers
- Structured handoffs with explicit success criteria

**Error Recovery**:
- Multi-level detection (timeout, tool access, validation)
- Automatic retry with adjusted parameters
- Checkpoint-based rollback and resume
- Graceful degradation to sequential execution

### When to Use /orchestrate

**Use /orchestrate for**:
- Complex multi-phase workflows (≥3 phases)
- Features requiring research + planning + implementation
- Tasks benefiting from parallel execution
- Workflows needing systematic error recovery

**Use individual commands for**:
- Simple single-phase tasks
- Direct implementation without planning
- Quick documentation updates
- Straightforward bug fixes

### Implementation Status

**Full implementation complete!** All phases have been implemented:

- [x] Phase 1: Foundation and Command Structure
- [x] Phase 2: Research Phase Coordination
- [x] Phase 3: Planning and Implementation Phase Integration
- [x] Phase 4: Error Recovery and Debugging Loop
- [x] Phase 5: Documentation Phase and Workflow Completion

The /orchestrate command provides comprehensive multi-agent workflow coordination with:
- Parallel research execution with context minimization
- Seamless integration with /plan, /implement, /debug, /document commands
- Robust error recovery with automatic retry strategies
- Intelligent debugging loop with 3-iteration limit
- Complete documentation generation with cross-referencing
- Checkpoint-based recovery system
- Performance metrics tracking

Ready to orchestrate end-to-end development workflows!

## Agent Usage

This command uses specialized agents for each workflow phase:

### Research Phase
- **Agent**: `research-specialist` (multiple instances in parallel)
- **Purpose**: Codebase analysis, best practices research, alternative approaches
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **Invocation**: 2-4 parallel agents depending on workflow complexity

### Planning Phase
- **Agent**: `plan-architect`
- **Purpose**: Generate structured implementation plans from research findings
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Invocation**: Single agent, sequential execution

### Implementation Phase
- **Agent**: `code-writer`
- **Purpose**: Execute implementation plans phase by phase with testing
- **Tools**: Read, Write, Edit, Bash, TodoWrite
- **Invocation**: Single agent with extended timeout for complex implementations

### Debugging Loop (Conditional)
- **Investigation**: `debug-specialist`
  - Purpose: Root cause analysis and diagnostic reporting
  - Tools: Read, Bash, Grep, Glob, WebSearch
- **Fix Application**: `code-writer`
  - Purpose: Apply proposed fixes from debug reports
  - Tools: Read, Write, Edit, Bash, TodoWrite
- **Invocation**: Up to 3 debugging iterations before escalation

### Documentation Phase
- **Agent**: `doc-writer`
- **Purpose**: Update documentation and generate workflow summaries
- **Tools**: Read, Write, Edit, Grep, Glob
- **Invocation**: Single agent, sequential execution

### Agent Integration Benefits
- **Specialized Expertise**: Each agent optimized for its specific task
- **Tool Restrictions**: Security through limited tool access per agent
- **Parallel Execution**: Research-specialist agents run concurrently
- **Context Isolation**: Agents receive only relevant context for their phase
- **Clear Responsibilities**: No ambiguity about which agent handles what

Let me begin orchestrating your workflow based on the description provided.
