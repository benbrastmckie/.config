# /subagents Command Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

## Metadata
- **Date**: 2025-09-29
- **Feature**: /subagents - Utility command for parallel task execution within /implement
- **Scope**: Create a utility command that /implement calls to parallelize suitable tasks
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.dotfiles/CLAUDE.md
- **Research Reports**: /home/benjamin/.dotfiles/specs/reports/002_claude_code_agent_best_practices.md

## Overview

Implement a `/subagents` utility command designed to be called by `/implement` when it encounters a phase with multiple independent tasks suitable for parallel execution. The command will analyze task dependencies, create optimized prompts for parallelizable tasks, execute them concurrently via subagents, and return consolidated results back to `/implement` for integration into the phase workflow.

## Success Criteria
- [ ] Command integrates seamlessly with /implement's phase execution flow
- [ ] Automatically identifies parallelizable vs dependent tasks
- [ ] Executes independent tasks in parallel for performance gains
- [ ] Returns structured results that /implement can process
- [ ] Maintains /implement's test and commit workflow
- [ ] Command marked as utility type with proper dependencies
- [ ] Clear criteria for when /implement should invoke /subagents
- [ ] Preserves phase context and plan tracking

## Technical Design

### Architecture
- **Command Location**: `.claude/commands/subagents.md`
- **Command Type**: utility (called by other commands)
- **Tool Requirements**: Task, SlashCommand, TodoWrite
- **Agent Type**: general-purpose (for implementation flexibility)
- **Integration**: Called via SlashCommand tool from /implement

### Integration with /implement
1. **Invocation Trigger**: /implement calls /subagents when a phase has 3+ independent tasks
2. **Context Passing**: Phase context, file paths, and standards passed as arguments
3. **Result Format**: Structured JSON or markdown with task completion status
4. **Error Handling**: Graceful fallback to sequential execution if needed

### Task Analysis Engine
- Detect task independence through keyword analysis ("Create", "Add", "Implement")
- Identify dependencies via phrases ("After", "Using", "Based on")
- Group related tasks that share file modifications
- Determine parallelization feasibility score

### Prompt Generation Strategy
- Include phase context and objectives
- Pass relevant file paths and standards
- Add specific success validation criteria
- Request structured output format
- Include rollback instructions for failures

### Result Integration
- Parse individual agent responses
- Validate task completion against criteria
- Format results for /implement consumption
- Update TodoWrite tracking in coordination with /implement
- Return control flow indicators

## Implementation Phases

### Phase 1: Command Structure and /implement Integration [COMPLETED]
**Objective**: Create the utility command with proper integration hooks for /implement
**Complexity**: Medium

Tasks:
- [x] Create `.claude/commands/subagents.md` with utility-type YAML frontmatter
- [x] Define argument structure for phase context and task list
- [x] Implement task dependency analyzer
- [x] Create parallelizability scorer (0-100)
- [x] Add /implement callback mechanism
- [x] Document invocation criteria for /implement

Testing:
```bash
# Test dependency detection algorithms
# Verify integration with SlashCommand tool
# Test with sample phase data from real plans
```

### Phase 2: Task Analysis and Prompt Generation [COMPLETED]
**Objective**: Build intelligent task analysis and prompt generation for parallel execution
**Complexity**: High

Tasks:
- [x] Implement keyword-based dependency detection
- [x] Create file conflict analyzer (tasks modifying same files)
- [x] Build task grouping algorithm for related work
- [x] Generate phase-aware prompts with context
- [x] Add success criteria based on task markers
- [x] Include rollback instructions in prompts

Testing:
```bash
# Test with various task patterns from existing plans
# Verify dependency detection accuracy
# Test file conflict detection
```

### Phase 3: Parallel Execution and Result Collection [COMPLETED]
**Objective**: Implement parallel agent orchestration with result aggregation
**Complexity**: High

Tasks:
- [x] Implement parallel Task tool invocation
- [x] Create result parser for agent responses
- [x] Build task completion validator
- [x] Add partial failure handling
- [x] Implement result formatting for /implement
- [x] Create fallback to sequential execution

Testing:
```bash
# Test parallel execution with 5+ tasks
# Verify result aggregation accuracy
# Test partial failure scenarios
# Measure performance improvements
```

### Phase 4: /implement Enhancement and Testing [COMPLETED]
**Objective**: Modify /implement to intelligently invoke /subagents
**Complexity**: Medium

Tasks:
- [x] Update /implement.md to add subagents to dependent-commands
- [x] Add task analysis logic to /implement phase execution
- [x] Implement threshold logic (3+ independent tasks)
- [x] Create seamless fallback for non-parallelizable phases
- [x] Add performance metrics logging
- [x] Document the integration in both commands

Testing:
```bash
# End-to-end test with real implementation plans
# Verify /implement correctly invokes /subagents
# Test fallback scenarios
# Measure overall performance improvements
```

## Testing Strategy

### Unit Testing
- Task dependency detection accuracy
- Parallelizability scoring algorithm
- Prompt generation with phase context
- Result parsing and validation

### Integration Testing
- /implement invocation of /subagents
- Parallel agent execution and monitoring
- Result integration back to /implement
- Fallback to sequential execution

### Performance Testing
- Measure speedup with parallel execution
- Resource usage with multiple agents
- Threshold optimization (3+ tasks)
- Overhead vs benefit analysis

## Documentation Requirements

### Command Documentation
- Document as utility command in subagents.md
- Explain integration with /implement
- Define parallelizability criteria
- Include performance metrics

### /implement Updates
- Add subagents to dependent-commands
- Document auto-parallelization feature
- Update phase execution documentation
- Add configuration options

## Dependencies

### Tools Required
- Task tool (for parallel agent execution)
- SlashCommand (for /implement to invoke this)
- TodoWrite (coordinated with /implement)

### Command Integration
- **Primary**: /implement (main invoker)
- **Secondary**: Could be used by /refactor for parallel analysis
- **Future**: /test-all could use for parallel test execution

## Notes

### Design Decisions
1. **Utility pattern**: Designed to be invoked by other commands, not users directly
2. **Smart detection**: Automatically identify parallelizable tasks
3. **Seamless integration**: Works within /implement's existing workflow
4. **Performance focused**: Only parallelize when beneficial (3+ tasks)
5. **Graceful fallback**: Sequential execution if parallelization fails

### Invocation Criteria for /implement
/implement should call /subagents when:
- Phase has 3+ tasks in checklist format
- Tasks don't have explicit dependencies
- Tasks modify different files or create new ones
- Phase complexity is marked as Medium or High
- Not in a critical phase (like Phase 1 setup)

### Future Enhancements
- Configuration options in CLAUDE.md for parallelization thresholds
- Learning from execution patterns to improve detection
- Support for explicit parallelization hints in plans
- Integration with other utility commands
- Performance profiling and optimization

### Risk Mitigation
- **Conservative detection**: Only parallelize when clearly safe
- **Result validation**: Ensure all tasks complete successfully
- **Context preservation**: Maintain phase and plan context
- **Resource limits**: Cap at 10 parallel agents
- **Clear logging**: Track what was parallelized and why