# Shared Agent Protocols

This directory contains protocol documentation shared across all agents to reduce duplication and ensure consistency.

## Purpose

Agent protocols define standard patterns for common operations:
- **Progress streaming**: How agents report progress during operations
- **Error handling**: How agents handle and recover from errors

By extracting these protocols to shared documentation, we:
- Reduce code duplication (~200 LOC saved across 6+ agents)
- Ensure consistent behavior across all agents
- Make it easier to update protocols globally
- Simplify agent creation (reference protocols instead of copying code)

## Available Protocols

### [Progress Streaming Protocol](progress-streaming-protocol.md)

Defines how agents emit progress updates during long-running operations.

**Key Concepts**:
- Standard progress marker format: `PROGRESS: <message>`
- When to emit progress (before long operations, between major steps)
- Standard milestones (Starting, Reading, Analyzing, Planning, Executing, Testing, Verifying, Completing)
- Message guidelines (specific, concise, actionable, quantified)

**Used By**: code-writer, plan-architect, research-specialist, test-specialist, and others

**Example**:
```
PROGRESS: Starting implementation of authentication module...
PROGRESS: Reading 5 source files...
PROGRESS: Implementing LoginService class...
PROGRESS: Running tests...
PROGRESS: Implementation complete, all tests passing.
```

### [Error Handling Guidelines](error-handling-guidelines.md)

Defines how agents classify, handle, and recover from errors.

**Key Concepts**:
- Error classification (transient, permanent, fatal)
- Retry strategies (exponential backoff, retry limits)
- Fallback approaches (simpler edits, language defaults, graceful degradation)
- Error reporting format

**Used By**: code-writer, code-reviewer, research-specialist, test-specialist, and others

**Example**:
```bash
# Retry with exponential backoff for transient errors
for attempt in 1 2 3; do
  if write_file; then break; fi
  sleep $(( 500 * (2 ** (attempt - 1)) ))ms
done

# Fall back to simpler approach
if ! complex_edit; then
  simple_edit
fi
```

## Using Shared Protocols in Agents

### In Agent Markdown Files

Instead of duplicating protocol content, agents reference the shared documentation:

```markdown
## Protocols

### Progress Streaming
See [Progress Streaming Protocol](shared/progress-streaming-protocol.md) for standard progress reporting guidelines.

**Agent-Specific Milestones**:
- PROGRESS: Discovering test files...
- PROGRESS: Executing test suite...
- PROGRESS: Analyzing test results...

### Error Handling
See [Error Handling Guidelines](shared/error-handling-guidelines.md) for standard error handling patterns.

**Agent-Specific Handling**:
- Test Execution Timeouts: Increase timeout and retry once
- Flaky Tests: Run 2-3 times, report intermittent failures
```

This approach:
- Keeps agents concise and focused on specialization
- Ensures all agents follow the same base protocols
- Allows agent-specific customizations where needed

### Agent Structure Template

Standard agent file structure with protocol references:

```markdown
# Agent Name

[Agent description]

## Core Capabilities

- [Capability 1]
- [Capability 2]
- [Capability 3]

## Protocols

### Progress Streaming
See [Progress Streaming Protocol](shared/progress-streaming-protocol.md).

[Optional: Agent-specific progress milestones]

### Error Handling
See [Error Handling Guidelines](shared/error-handling-guidelines.md).

[Optional: Agent-specific error handling]

## Specialization

[Unique agent-specific logic, tools, workflows]

## Example Usage

[Examples of agent invocation]
```

## Benefits

### Reduced Duplication

**Before refactoring**:
- Progress streaming: ~40 lines × 4 agents = 160 lines
- Error handling: ~50 lines × 4 agents = 200 lines
- Total: ~360 lines duplicated

**After refactoring**:
- Shared protocols: ~200 lines (progress + error handling)
- References in agents: ~10 lines × 6 agents = 60 lines
- Total: ~260 lines
- **Savings**: ~100 lines (28% reduction)

Plus easier maintenance - update once, apply everywhere.

### Consistency

All agents now follow identical base protocols:
- Same progress marker format
- Same retry strategies
- Same error classification
- Same reporting structure

### Easier Onboarding

New agent creation is simpler:
1. Copy agent template
2. Reference shared protocols
3. Add agent-specific specialization
4. Done - protocols inherited automatically

## Maintenance

### Updating Protocols

To update a protocol:
1. Edit the protocol document (e.g., `progress-streaming-protocol.md`)
2. Changes automatically apply to all agents that reference it
3. No need to update individual agent files

### Adding New Protocols

To add a new shared protocol:
1. Create protocol document in this directory
2. Add entry to this README
3. Reference from relevant agents

### Agent-Specific Customizations

Agents can extend protocols with domain-specific details:

```markdown
### Progress Streaming
See [Progress Streaming Protocol](shared/progress-streaming-protocol.md).

**Test Specialist-Specific Milestones**:
- PROGRESS: Discovering test files (N found)...
- PROGRESS: Executing test suite (N/M tests)...
- PROGRESS: Analyzing failures (N failed)...
```

## History

**Created**: 2025-10-06 (Plan 026, Phase 3)
**Purpose**: Reduce agent duplication, standardize patterns
**Impact**: ~100 LOC reduction, improved consistency

## Navigation

- [← Parent Directory](../README.md) - Overview of all agents
- [Agent Registry](../agent-registry.json) - Agent metadata and performance tracking
- [Command Documentation](../../commands/README.md) - Commands that invoke agents
