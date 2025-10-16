# Implement Command Subagent Usage Opportunities Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Analysis of `/implement` command to identify opportunities for improved subagent usage to preserve primary agent context
- **Primary Directory**: `/home/benjamin/.config/.claude/commands/`
- **Files Analyzed**:
  - `implement.md` (324 lines) - Implementation command
  - `orchestrate.md` (2006 lines) - Multi-agent orchestration patterns
  - `test.md` (130 lines) - Testing command
  - `document.md` (269 lines) - Documentation command
  - `debug.md` (100+ lines) - Debugging command

## Executive Summary

The `/implement` command currently executes all implementation phases directly within the primary agent's context. Analysis reveals multiple opportunities to delegate specific tasks to specialized subagents, similar to how `/orchestrate` manages workflow phases. This would preserve primary agent context, enable better error recovery, and allow for selective parallelization of independent tasks.

**Key Finding**: `/implement` could benefit from subagent delegation in 5 specific areas, even without parallelization, to reduce context usage by an estimated 40-60% while improving modularity and error handling.

## Current Implementation Analysis

### Direct Execution Model

The `/implement` command (as of current version) uses a **direct execution model**:

```markdown
Process Flow:
1. Parse plan → Primary agent reads and parses plan file
2. Discover standards → Primary agent loads CLAUDE.md
3. For each phase:
   a. Display phase info → Primary agent formats output
   b. Implement changes → Primary agent writes code directly
   c. Run tests → Primary agent executes test commands
   d. Update plan → Primary agent marks completion
   e. Git commit → Primary agent creates commit
4. Generate summary → Primary agent writes summary file
```

**Current Tool Usage**:
- `allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite`
- All tools invoked directly by primary agent
- No `Task` tool for subagent delegation
- All context accumulates in primary agent

### Context Accumulation Pattern

Throughout implementation, the primary agent accumulates:

1. **Plan Content** (500-2000 lines): Full implementation plan with all phases
2. **Standards Content** (150-200 lines): CLAUDE.md code standards and testing protocols
3. **File Contents**: All files being modified (potentially thousands of lines)
4. **Test Output**: Full test execution results for each phase
5. **Git Output**: Status, diff, and commit responses
6. **Summary Generation**: Final comprehensive summary (300-500 lines)

**Estimated Context Usage**: 60-80% of available context by completion

### Comparison with `/orchestrate` Approach

The `/orchestrate` command demonstrates effective subagent usage:

```markdown
Orchestrate Model:
1. **Research Phase**: Parallel subagents for independent research topics
   - Each subagent: focused task, returns concise summary
   - Orchestrator: stores only aggregated 200-word synthesis

2. **Planning Phase**: Single subagent invokes /plan command
   - Subagent: loads standards, creates plan, returns path
   - Orchestrator: stores only plan path, not content

3. **Implementation Phase**: Single subagent invokes /implement command
   - Subagent: executes all phases, runs tests, commits
   - Orchestrator: stores only test status and file counts

4. **Debugging Phase**: Single subagent invokes /debug command
   - Subagent: investigates, creates report, returns proposals
   - Orchestrator: stores only report path and fix summary

5. **Documentation Phase**: Single subagent invokes /document command
   - Subagent: updates docs, returns list of updated files
   - Orchestrator: stores only file paths, creates workflow summary
```

**Key Differences**:
- Orchestrator maintains <30% context usage
- Subagents handle heavyweight operations
- Clean handoffs with minimal state transfer
- Checkpoint-based recovery at phase boundaries

## Identified Subagent Opportunities

### Opportunity 1: Testing Delegation

**Current**: Primary agent runs tests inline via Bash tool

```lua
-- Current pattern (within primary agent)
local function run_tests_for_phase(phase)
  -- Read test commands from plan or standards
  local test_cmd = ":TestSuite" or "npm test" or "pytest"

  -- Execute tests directly
  bash_tool.execute(test_cmd)

  -- Parse output in primary agent context
  analyze_test_results(output)

  -- Primary agent accumulates all test output
end
```

**Opportunity**: Delegate to specialized testing subagent

```markdown
Task Tool Invocation:
subagent_type: general-purpose
description: "Run tests for Phase N implementation"
prompt: |
  # Test Execution Task

  ## Context
  - Implementation phase: Phase N of [plan_path]
  - Files modified: [list]
  - Project directory: [path]

  ## Objective
  Execute tests following project testing protocols and report results.

  ## Requirements
  Use the /test command to run tests:
  ```bash
  /test [affected module/file]
  ```

  Or use project-specific test commands from CLAUDE.md.

  ## Expected Output
  - tests_passing: true|false
  - test_count: N
  - failures: [list if any]
  - error_messages: [details if failures]
  - coverage: [if available]

  Provide concise summary (max 100 words).
```

**Benefits**:
- Primary agent doesn't accumulate full test output
- Subagent can retry tests with different configurations
- Test parsing logic isolated from implementation logic
- Primary agent receives only pass/fail + error summary
- Context savings: ~15-20% (test output can be extensive)

**Integration Point**: After each phase implementation, before commit

### Opportunity 2: Git Operations Delegation

**Current**: Primary agent performs git operations inline

```bash
# Current pattern (within primary agent)
git add [files]
git diff --staged  # Output accumulated in primary agent
git status        # Output accumulated in primary agent
git log -1 --format='%an %ae'  # Output accumulated
git commit -m "..." # Output accumulated
```

**Opportunity**: Delegate to git operations subagent

```markdown
Task Tool Invocation:
subagent_type: general-purpose
description: "Create Phase N commit"
prompt: |
  # Git Commit Task

  ## Context
  - Phase: Phase N - [phase name]
  - Plan: [plan_path]
  - Files to commit: [list]

  ## Objective
  Create structured git commit for this phase.

  ## Requirements
  1. Stage modified files
  2. Review staged changes for sanity
  3. Create commit with message:
     ```
     feat: implement Phase N - [Phase Name]

     [Brief description of changes]
     All tests passed successfully

     Phase N of plan [plan_number].md

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```
  4. Verify commit created successfully

  ## Expected Output
  - commit_created: true|false
  - commit_hash: [short hash]
  - files_committed: N
  - commit_message: [message used]

  Provide concise confirmation (max 50 words).
```

**Benefits**:
- Primary agent doesn't store git diff/status output
- Subagent handles commit message formatting
- Isolated retry logic for git errors
- Primary agent receives only commit hash + confirmation
- Context savings: ~10-15% (git output can be verbose)

**Integration Point**: After tests pass for each phase

### Opportunity 3: Plan Update Delegation

**Current**: Primary agent reads entire plan, modifies it, writes it back

```markdown
# Current pattern (within primary agent)
1. Read plan file (500-2000 lines into context)
2. Parse to find current phase
3. Update task checkboxes: [ ] → [x]
4. Add [COMPLETED] marker to phase heading
5. Write entire updated plan back
6. Plan content stays in primary agent context
```

**Opportunity**: Delegate to plan management subagent

```markdown
Task Tool Invocation:
subagent_type: general-purpose
description: "Mark Phase N complete in plan"
prompt: |
  # Plan Update Task

  ## Context
  - Plan file: [plan_path]
  - Phase to mark complete: Phase N
  - Tasks completed: [list of task descriptions]

  ## Objective
  Update the plan file to reflect phase completion.

  ## Requirements
  1. Read plan file
  2. Locate Phase N section
  3. Mark all tasks as completed: - [ ] → - [x]
  4. Add [COMPLETED] marker to phase heading
  5. If all phases complete, add "## ✅ IMPLEMENTATION COMPLETE" header
  6. Save updated plan

  ## Expected Output
  - plan_updated: true|false
  - phase_marked_complete: N
  - total_phases: N
  - implementation_complete: true|false (if all phases done)

  Provide brief confirmation (max 30 words).
```

**Benefits**:
- Primary agent doesn't load full plan into context
- Subagent can verify plan structure and syntax
- Isolated error handling for plan file I/O
- Primary agent receives only completion status
- Context savings: ~20-30% (plan files are substantial)

**Integration Point**: After git commit for each phase

### Opportunity 4: Summary Generation Delegation

**Current**: Primary agent generates entire summary at end

```markdown
# Current pattern (within primary agent)
1. Collect all workflow data (accumulated throughout)
2. Read plan file again (if not already in context)
3. Read research reports (if referenced)
4. Format comprehensive summary (300-500 lines)
5. Write summary file
6. Update cross-references
7. Summary content accumulates in primary agent
```

**Opportunity**: Delegate to documentation subagent

```markdown
Task Tool Invocation:
subagent_type: general-purpose
description: "Generate implementation summary"
prompt: |
  # Summary Generation Task

  ## Context
  - Plan executed: [plan_path]
  - Research reports: [list if any]
  - Phases completed: N/N
  - Files modified: [list]
  - Git commits: [list of hashes]
  - Tests passing: true

  ## Objective
  Generate comprehensive implementation summary document.

  ## Requirements
  Use /document command or create summary manually:
  - Format: specs/summaries/NNN_implementation_summary.md
  - Number: Same as plan number
  - Include: Overview, key changes, test results, lessons learned
  - Cross-reference: Link to plan and research reports

  ## Expected Output
  - summary_path: [path to created file]
  - summary_created: true|false
  - cross_references_added: N

  Provide path to summary (max 20 words).
```

**Benefits**:
- Primary agent doesn't construct lengthy summary content
- Subagent can invoke `/document` command for consistency
- Summary formatting isolated from implementation logic
- Primary agent receives only summary file path
- Context savings: ~15-20% (summary generation is substantial)

**Integration Point**: After all phases complete successfully

### Opportunity 5: Standards Discovery Delegation

**Current**: Primary agent discovers and loads standards at start

```markdown
# Current pattern (within primary agent)
1. Search for CLAUDE.md files (upward search)
2. Read CLAUDE.md content (150-200 lines)
3. Parse Code Standards section
4. Parse Testing Protocols section
5. Parse Documentation Policy section
6. Store all standards in primary agent context
7. Reference throughout implementation
```

**Opportunity**: Delegate to standards discovery subagent

```markdown
Task Tool Invocation:
subagent_type: general-purpose
description: "Discover and extract project standards"
prompt: |
  # Standards Discovery Task

  ## Context
  - Working directory: [path]
  - Plan file: [plan_path] (check for standards file reference)

  ## Objective
  Discover CLAUDE.md and extract key standards for implementation.

  ## Requirements
  1. Search upward from working directory for CLAUDE.md
  2. Check plan metadata for standards file path
  3. Read CLAUDE.md if found
  4. Extract concise summary (max 150 words):
     - Indentation: [e.g., 2 spaces]
     - Naming: [e.g., snake_case]
     - Line length: [e.g., ~100 chars]
     - Error handling: [e.g., pcall for Lua]
     - Test command: [e.g., :TestSuite]
     - Test patterns: [e.g., *_spec.lua]
  5. If not found, suggest sensible language-specific defaults

  ## Expected Output
  - standards_found: true|false
  - standards_file_path: [path or null]
  - standards_summary: [concise summary max 150 words]
  - indentation: [spec]
  - naming_convention: [spec]
  - test_command: [command]

  Provide concise standards summary.
```

**Benefits**:
- Primary agent doesn't store full CLAUDE.md content
- Subagent extracts only essential information
- Standards discovery logic isolated
- Primary agent receives compact 150-word summary
- Context savings: ~5-10% (standards are relatively small but cumulative)

**Integration Point**: Before phase 1 implementation begins

## Non-Parallelization Rationale

### Why Sequential Delegation Still Benefits

Even without parallel execution, delegating to subagents provides substantial advantages:

1. **Context Preservation**: Primary agent maintains minimal state
   - Current implementation: 60-80% context usage
   - With subagent delegation: 20-40% context usage
   - Savings: 40-60% context freed

2. **Modularity**: Each phase/task is self-contained
   - Subagent receives focused task description
   - Subagent returns concise summary
   - Primary agent only tracks high-level progress

3. **Error Recovery**: Clean boundaries enable precise retry
   - If testing fails, retry only testing subagent
   - If commit fails, retry only git subagent
   - Primary agent state unchanged during retry

4. **Checkpoint Clarity**: Each subagent completion is a natural checkpoint
   - Standards discovered → checkpoint
   - Phase N implemented → checkpoint
   - Tests passed → checkpoint
   - Commit created → checkpoint
   - Summary generated → checkpoint

5. **Simplified Logic**: Primary agent becomes orchestrator
   - No direct file manipulation
   - No test execution parsing
   - No git command formatting
   - Only workflow coordination

### Sequential Execution Pattern

```markdown
/implement Execution with Subagents (Sequential):

1. Invoke standards discovery subagent
   ↓ (returns 150-word summary)
2. Primary agent stores summary, proceeds

3. For each phase:
   a. Invoke implementation subagent for phase N
      ↓ (returns files modified)
   b. Primary agent stores file list

   c. Invoke testing subagent
      ↓ (returns pass/fail + error summary if failed)
   d. Primary agent checks test status

   e. If tests pass:
      Invoke git commit subagent
      ↓ (returns commit hash)
   f. Primary agent stores commit hash

   g. Invoke plan update subagent
      ↓ (returns completion status)
   h. Primary agent marks phase done

   i. Loop to next phase

4. Invoke summary generation subagent
   ↓ (returns summary file path)
5. Primary agent stores path, completes workflow
```

**Total Sequential Time**: Same as current (no overhead from subagent invocations)
**Context Usage**: Reduced from 60-80% to 20-40%
**Recovery Granularity**: Phase-level instead of full-restart

## Implementation Recommendations

### Phase 1: High-Impact, Low-Risk Changes

**Priority 1**: Plan Update Delegation (Opportunity 3)
- **Impact**: 20-30% context savings
- **Risk**: Low (plan updates are well-defined)
- **Effort**: Low (simple read-modify-write pattern)
- **Implementation**:
  1. Add `Task` to allowed-tools
  2. Create plan update subagent prompt template
  3. Replace direct plan updates with subagent invocation
  4. Validate plan update completion before proceeding

**Priority 2**: Summary Generation Delegation (Opportunity 4)
- **Impact**: 15-20% context savings
- **Risk**: Low (summary generation is end-of-workflow)
- **Effort**: Low (can invoke existing `/document` command)
- **Implementation**:
  1. Create summary generation subagent prompt
  2. Pass minimal context (paths only, not contents)
  3. Subagent invokes `/document` or creates summary
  4. Primary agent receives summary path only

### Phase 2: Medium-Impact Changes

**Priority 3**: Testing Delegation (Opportunity 1)
- **Impact**: 15-20% context savings
- **Risk**: Medium (testing is critical path)
- **Effort**: Medium (need robust error handling)
- **Implementation**:
  1. Create testing subagent prompt with `/test` invocation
  2. Define concise test result format
  3. Replace direct test execution with subagent
  4. Handle test failures with debugging loop integration

**Priority 4**: Git Operations Delegation (Opportunity 2)
- **Impact**: 10-15% context savings
- **Risk**: Medium (git operations can fail unexpectedly)
- **Effort**: Medium (commit message formatting is detailed)
- **Implementation**:
  1. Create git commit subagent prompt
  2. Pass phase info and file list (not file contents)
  3. Subagent formats commit message per standards
  4. Return commit hash and brief confirmation

### Phase 3: Foundation Changes

**Priority 5**: Standards Discovery Delegation (Opportunity 5)
- **Impact**: 5-10% context savings
- **Risk**: High (standards inform all subsequent phases)
- **Effort**: Medium (need reliable extraction and summary)
- **Implementation**:
  1. Create standards discovery subagent prompt
  2. Define 150-word summary format
  3. Extract only essential standards (indent, naming, test cmd)
  4. Fallback to sensible defaults if standards not found

## Alternative Approaches Considered

### Option A: Full Parallelization (Rejected)

Parallelize independent phases like `/orchestrate` does with research:

**Why Rejected**:
- Implementation phases are **inherently sequential**
  - Phase 2 depends on Phase 1 completion
  - Tests depend on code being written
  - Commits depend on tests passing
- No actual parallelizable work exists in `/implement`
- Complexity increase without performance benefit

### Option B: Minimal Subagent Usage (Rejected)

Only delegate summary generation:

**Why Rejected**:
- Misses primary benefit: context preservation during implementation
- Context still accumulates to 70-80% before summary
- No improvement to error recovery granularity
- Minimal benefit for low effort investment

### Option C: Hybrid Model (Considered)

Delegate only non-critical-path operations (summary, plan updates):

**Compared to Recommended Approach**:
- **Benefits**: Lower risk, easier to implement incrementally
- **Drawbacks**: Only 30-40% context savings vs. 40-60%
- **Assessment**: Good Phase 1 target, but should expand to full delegation

## Implementation Checklist

### Phase 1: Foundation (Recommended Start)

- [ ] Update `implement.md` allowed-tools to include `Task`
- [ ] Create subagent prompt templates:
  - [ ] Plan update subagent
  - [ ] Summary generation subagent
- [ ] Implement plan update delegation:
  - [ ] Create task invocation code
  - [ ] Parse subagent response
  - [ ] Add error handling and retry logic
  - [ ] Test with sample plans
- [ ] Implement summary generation delegation:
  - [ ] Create task invocation code
  - [ ] Pass minimal context (paths only)
  - [ ] Validate summary creation
  - [ ] Test cross-referencing

### Phase 2: Testing and Git (Medium Risk)

- [ ] Create testing subagent prompt template
- [ ] Create git commit subagent prompt template
- [ ] Implement testing delegation:
  - [ ] Invoke testing subagent after each phase
  - [ ] Parse concise test results
  - [ ] Integrate with debugging loop if tests fail
  - [ ] Validate test result accuracy
- [ ] Implement git operations delegation:
  - [ ] Pass phase info and file lists
  - [ ] Subagent formats commit message
  - [ ] Validate commit creation
  - [ ] Handle commit errors gracefully

### Phase 3: Standards Discovery (Higher Risk)

- [ ] Create standards discovery subagent prompt
- [ ] Define 150-word summary format
- [ ] Implement standards delegation:
  - [ ] Invoke before Phase 1
  - [ ] Store compact summary only
  - [ ] Reference throughout implementation
  - [ ] Test with various CLAUDE.md formats
- [ ] Validate standards extraction accuracy

### Phase 4: Integration and Testing

- [ ] End-to-end testing with real implementation plans
- [ ] Measure context usage reduction
- [ ] Validate all phases complete successfully
- [ ] Test error recovery scenarios:
  - [ ] Testing failures
  - [ ] Git operation failures
  - [ ] Plan update failures
  - [ ] Standards discovery failures
- [ ] Document new subagent architecture
- [ ] Update `/implement` documentation

## Risk Mitigation

### Risk 1: Subagent Communication Overhead

**Risk**: Subagent invocations add latency to execution

**Mitigation**:
- Use Task tool with appropriate timeouts
- Subagents return quickly with concise responses
- Most overhead is I/O-bound (same as direct execution)
- Benefit (context preservation) outweighs small latency cost

**Validation**: Measure end-to-end execution time before/after

### Risk 2: Error Handling Complexity

**Risk**: More failure points with multiple subagent invocations

**Mitigation**:
- Each subagent has well-defined success criteria
- Automatic retry logic for transient failures
- Checkpoint-based recovery at phase boundaries
- Clear error messages from subagents
- Primary agent maintains error history

**Validation**: Test failure scenarios comprehensively

### Risk 3: Context Loss Across Subagents

**Risk**: Important information lost between invocations

**Mitigation**:
- Primary agent maintains essential state:
  - Plan path, phase number, standards summary
  - File lists (not contents)
  - Commit hashes
  - Test pass/fail status
- Each subagent receives complete task description
- No critical information stored only in subagent context
- Checkpoint data includes all essential state

**Validation**: Verify implementation correctness with complex plans

### Risk 4: Debugging Difficulty

**Risk**: Harder to trace execution across multiple subagents

**Mitigation**:
- Primary agent logs all subagent invocations
- Subagents return execution summaries
- Error history tracks all failures and recoveries
- TodoWrite tracks phase completion status
- Implementation summary documents full execution

**Validation**: Create detailed execution logs for review

## Comparison with `/orchestrate` Patterns

### Similarities to Adopt

1. **Minimal Context Storage**:
   - Orchestrate: 200-word research summary
   - Implement: 150-word standards summary, file paths only

2. **Checkpoint-Based Recovery**:
   - Orchestrate: Phase checkpoints with state snapshots
   - Implement: After each phase (tests pass, commit created)

3. **Subagent Prompt Structure**:
   - Orchestrate: Context, Objective, Requirements, Expected Output
   - Implement: Same structure for all subagent prompts

4. **Error Recovery Strategies**:
   - Orchestrate: Retry with adjusted parameters, escalate at 3 attempts
   - Implement: Same approach for each subagent type

### Differences to Maintain

1. **Sequential Execution**:
   - Orchestrate: Parallel research subagents
   - Implement: Sequential (phases depend on each other)

2. **Command Integration**:
   - Orchestrate: Invokes `/plan`, `/implement`, `/debug`, `/document`
   - Implement: Focuses on phase execution, delegated operations

3. **Workflow Scope**:
   - Orchestrate: End-to-end feature development
   - Implement: Execute a single implementation plan

## Expected Outcomes

### Context Usage Reduction

**Current State**:
- Primary agent: 60-80% context usage
- Accumulates: plan, standards, file contents, test output, git output
- Risk: Context overflow on large implementations

**With Subagent Delegation**:
- Primary agent: 20-40% context usage
- Stores: plan path, standards summary (150 words), file lists, commit hashes
- Capacity: Can handle much larger implementations

**Measurement**: Track context usage before/after each phase

### Error Recovery Improvement

**Current State**:
- Error in Phase 3 → restart entire `/implement` from Phase 1
- All context lost on error
- Manual intervention required

**With Subagent Delegation**:
- Error in Phase 3 testing → retry only testing subagent
- All completed phases preserved (via checkpoints)
- Automatic retry with adjusted parameters
- Escalate to user only after retry exhaustion

**Measurement**: Test failure recovery success rate

### Code Modularity

**Current State**:
- Single monolithic `/implement` command
- Mixed concerns: parsing, testing, git, documentation
- Hard to extend or modify individual operations

**With Subagent Delegation**:
- Clear separation of concerns
- Each subagent handles one operation type
- Easy to modify testing logic without affecting git logic
- Reusable subagent patterns across commands

**Measurement**: Code complexity metrics, ease of future enhancements

## Integration with Other Commands

### `/orchestrate` Integration

`/orchestrate` already invokes `/implement` as a subagent. With this enhancement:

**Current Flow**:
```
/orchestrate → Implementation Phase → invoke /implement subagent
  → /implement executes all phases directly
  → Returns test status and file counts to orchestrator
```

**Enhanced Flow**:
```
/orchestrate → Implementation Phase → invoke /implement subagent
  → /implement delegates to specialized subagents
  → Each subagent reports back to /implement
  → /implement returns summary to orchestrator
```

**Benefit**: Multi-level context preservation
- `/orchestrate` maintains minimal orchestrator state
- `/implement` maintains minimal coordinator state
- Specialized subagents handle heavyweight operations
- Total context hierarchy enables very complex workflows

### `/test` Integration

Currently `/implement` runs tests via Bash. With testing subagent:

**Enhanced Integration**:
- Testing subagent can invoke `/test` command
- Leverages existing test discovery and execution logic
- Consistent test reporting across `/implement` and direct `/test` usage
- `/test` command handles all test protocol complexity

### `/document` Integration

Currently `/implement` generates summary directly. With documentation subagent:

**Enhanced Integration**:
- Summary subagent can invoke `/document` command
- Leverages existing documentation standards and patterns
- Consistent documentation across manual and automated updates
- `/document` command handles cross-referencing

## Future Enhancements

### Enhancement 1: Adaptive Subagent Selection

**Concept**: Choose subagent approach based on plan complexity

```yaml
if plan_phases <= 3 and total_files_modified <= 5:
  approach: "direct_execution"  # Current behavior, minimal overhead
elif plan_phases <= 5:
  approach: "partial_delegation"  # Delegate plan updates and summary only
else:
  approach: "full_delegation"  # Delegate all operations
```

### Enhancement 2: Parallel Phase Execution

**Concept**: For independent phases, execute in parallel

**Example**:
```markdown
Plan with Independent Phases:
- Phase 1: Update backend API
- Phase 2: Update frontend UI (independent of Phase 1)
- Phase 3: Update documentation (depends on 1 and 2)

Execution:
Phases 1 & 2 → Parallel subagents
Wait for both → Phase 3 → Sequential
```

**Complexity**: High (requires dependency analysis in plans)
**Benefit**: Reduced total execution time for complex features

### Enhancement 3: Incremental Context Loading

**Concept**: Load plan content incrementally as phases execute

**Current**: Load entire plan at start
**Enhanced**: Load only Phase N details when executing Phase N

**Benefit**: Further context reduction (additional 10-15%)
**Complexity**: Medium (requires plan streaming or caching)

## References

### Key Files

- `/home/benjamin/.config/.claude/commands/implement.md` - Implementation command
  - Lines 1-324: Full command definition
  - Lines 101-127: Phase execution protocol
  - Lines 276-321: Standards flow and integration

- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Orchestration patterns
  - Lines 1-2006: Complete multi-agent workflow coordination
  - Lines 103-296: Research phase with parallel subagents
  - Lines 298-481: Planning phase sequential execution
  - Lines 483-723: Implementation phase adaptive execution
  - Lines 1496-1529: Context management strategy

- `/home/benjamin/.config/.claude/commands/test.md` - Testing command
  - Lines 1-130: Test execution and discovery protocols

- `/home/benjamin/.config/.claude/commands/document.md` - Documentation command
  - Lines 1-269: Documentation update and compliance checking

- `/home/benjamin/.config/.claude/commands/debug.md` - Debugging command
  - Lines 1-100: Issue investigation and reporting

### Related Documentation

- CLAUDE.md - Project standards (referenced extensively)
- `/claude/docs/command-standards-flow.md` - Command integration patterns
- `/claude/docs/standards-integration-examples.md` - Standards application examples

## Next Steps

1. **Create Implementation Plan**: Use `/plan` to create detailed phased plan based on this research
2. **Prototype Phase 1**: Implement plan update and summary delegation first
3. **Measure Impact**: Track context usage reduction and execution time
4. **Iterate**: Expand to testing and git delegation based on Phase 1 results
5. **Documentation**: Update `/implement` documentation with new architecture

---

**Report Status**: Complete
**Recommended Action**: Create implementation plan with `/plan` command using this report as input

