---
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
argument-hint: <workflow-description> [--parallel] [--sequential]
description: Coordinate subagents through end-to-end development workflows
command-type: orchestration
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
Use Task tool to invoke multiple general-purpose subagents simultaneously:

Agent 1 - Codebase Patterns:
  Prompt: "Search the codebase for existing implementations of [feature/concept].
          Analyze patterns, architectures, and conventions currently in use.
          Summarize findings in max 150 words."
  Tools: Read, Grep, Glob, Bash

Agent 2 - Best Practices Research:
  Prompt: "Research industry best practices for [technology/approach].
          Use web search to find current standards (2025).
          Summarize key recommendations in max 150 words."
  Tools: WebSearch, WebFetch, Read

Agent 3 - Alternative Approaches:
  Prompt: "Investigate alternative approaches to [problem/feature].
          Compare trade-offs, complexity, and fit with project.
          Summarize options in max 150 words."
  Tools: WebSearch, WebFetch, Read, Grep
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
subagent_type: general-purpose
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
subagent_type: general-purpose
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

If implementation reports test failures:

1. **Analyze Failures**:
   ```markdown
   Use the /debug command to investigate test failures.

   Context provided:
   - Test failure details
   - Modified files from implementation
   - Implementation plan reference
   ```

2. **Generate and Apply Fixes**:
   - Debug agent identifies root causes
   - Proposes fix strategies
   - Implementation agent applies fixes
   - Re-test

3. **Retry Loop** (max 3 iterations):
   - Iteration 1: Debug → Fix → Test
   - Iteration 2: Refined debug → Fix → Test
   - Iteration 3: Final attempt or escalate to user

4. **Save Checkpoint**: tests_passing

### Documentation Phase (Sequential Execution)

1. **Generate Documentation Prompt**:
   ```markdown
   Use the /document command to update all relevant documentation.

   Context provided:
   - All files modified during workflow
   - Implementation plan reference
   - Research reports (if any)
   ```

2. **Invoke Documentation Agent**:
   - Update affected documentation files
   - Cross-reference specs documents
   - Generate workflow summary

3. **Create Workflow Summary**:
   ```markdown
   Location: specs/summaries/NNN_workflow_summary.md

   Contents:
   - Workflow overview
   - Research reports used (with links)
   - Implementation plan executed (with link)
   - Key changes made
   - Test results
   - Performance metrics
   - Lessons learned
   ```

4. **Save Checkpoint**: workflow_complete

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

### Automatic Recovery (3 max retries)

**Timeout Errors**:
- Retry 1: Extend timeout by 50%
- Retry 2: Split task into smaller components
- Retry 3: Reassign to different agent configuration
- Escalate: Manual intervention

**Tool Access Errors**:
- Verify tool permissions
- Retry with reduced toolset
- Fallback to sequential execution
- Escalate after 2 failures

**Validation Failures**:
- Show detailed failure context
- Provide correction guidance
- Re-execute with fixes
- Track common patterns for learning

### Checkpoint Recovery

After each successful phase:
```yaml
Save Checkpoint:
  phase_name: "research|planning|implementation|debugging|documentation"
  completion_time: timestamp
  outputs:
    primary_output: "path or summary"
    status: "success|partial|failed"
  next_phase: "planning|implementation|documentation|complete"
```

On workflow interruption or failure:
- Restore from last successful checkpoint
- Preserve all completed work
- Resume from interruption point
- Maintain error history for learning

### Manual Intervention Points

Escalate to user when:
- Critical integration failures occur
- Tests fail after 3 debugging iterations
- Major architectural decisions needed
- User override of automatic recovery desired

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

This is an incremental implementation. Current phase completion:
- [x] Phase 1: Foundation and Command Structure
- [ ] Phase 2: Research Phase Coordination
- [ ] Phase 3: Planning and Implementation Phase Integration
- [ ] Phase 4: Error Recovery and Debugging Loop
- [ ] Phase 5: Documentation Phase and Workflow Completion

The command provides basic workflow coordination structure. Full functionality will be completed in subsequent phases.

Let me begin orchestrating your workflow based on the description provided.
