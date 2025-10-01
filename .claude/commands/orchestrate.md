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

If research is needed, I'll:

1. **Identify Research Topics**:
   - Analyze workflow description for key areas to investigate
   - Typically 2-4 focused research topics
   - Examples: existing patterns, best practices, alternative approaches, technical constraints

2. **Launch Parallel Research Agents**:
   ```markdown
   Task Tool Invocations (Parallel):
   - Agent 1: Investigate existing patterns in codebase
   - Agent 2: Research industry best practices
   - Agent 3: Analyze alternative approaches
   ```

3. **Synthesize Research** (Minimal Context):
   - Aggregate findings from all research agents
   - Create concise summary (max 200 words)
   - Store only summary, not full research outputs
   - Save checkpoint: research_complete

4. **Research Agent Prompt Template**:
   ```markdown
   # Research Task: [Specific Topic]

   ## Context
   - **Workflow**: [Brief description]
   - **Research Focus**: [Specific area to investigate]
   - **Project Standards**: /home/benjamin/.config/CLAUDE.md

   ## Objective
   Investigate [topic] to inform planning and implementation phases.

   ## Requirements
   - Search codebase for existing patterns
   - Research best practices (web search if needed)
   - Identify potential approaches

   ## Expected Output
   Concise findings summary (max 150 words) covering:
   - Existing patterns found
   - Recommended approaches
   - Potential challenges

   ## Success Criteria
   - Findings are actionable for planning
   - Recommendations are specific
   - Challenges are identified
   ```

### Planning Phase (Sequential Execution)

1. **Generate Planning Prompt**:
   ```markdown
   Use the /plan command to create a structured implementation plan.

   Context to provide:
   - Research findings summary (if research phase completed)
   - User's original workflow description
   - Project standards from CLAUDE.md

   The planning agent will:
   - Synthesize research into actionable plan
   - Define implementation phases and tasks
   - Establish testing strategy
   - Output: specs/plans/NNN_feature_name.md
   ```

2. **Invoke Planning Agent**:
   - Use Task tool with general-purpose subagent
   - Wrap /plan command with research context
   - Extract plan file path from output

3. **Save Checkpoint**: plan_ready
   - Store plan path only (not full plan content)
   - Mark planning phase complete

### Implementation Phase (Adaptive Execution)

1. **Generate Implementation Prompt**:
   ```markdown
   Use the /implement command to execute the implementation plan.

   The implementation will:
   - Execute plan phase by phase
   - Run tests after each phase
   - Create git commits with structured messages
   - Handle errors with automatic retry
   ```

2. **Invoke Implementation Agent**:
   - Use Task tool with general-purpose subagent
   - Provide plan file path
   - Monitor for test failures

3. **Extract Implementation Status**:
   - Tests passing: true/false
   - Modified files: list of changed files
   - Error messages if tests failed

4. **Save Checkpoint**: implementation_complete

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
