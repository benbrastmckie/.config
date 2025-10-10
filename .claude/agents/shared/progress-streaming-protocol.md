# Progress Streaming Protocol

This document defines the standard protocol for streaming progress updates during agent operations.

## Purpose

Progress streaming provides real-time visibility into long-running agent operations, helping users understand what the agent is doing and where it is in a multi-step workflow.

## When to Use

Emit progress markers during operations that:
- Take more than a few seconds
- Involve multiple distinct steps
- Read or write multiple files
- Run external commands (tests, builds, etc.)
- Process large amounts of data

## Progress Marker Format

### Basic Format

```
PROGRESS: <brief-message>
```

### Message Guidelines

**Be Specific**: Describe the current action
- Good: `PROGRESS: Reading 12 test files...`
- Bad: `PROGRESS: Working...`

**Be Concise**: Keep messages under 60 characters
- Good: `PROGRESS: Analyzing dependencies in package.json...`
- Bad: `PROGRESS: Now I am going to analyze the dependencies listed in the package.json file to understand the project structure...`

**Be Actionable**: Focus on what's happening now
- Good: `PROGRESS: Running test suite...`
- Bad: `PROGRESS: Tests will be run next...`

**Include Counts**: Quantify when possible
- Good: `PROGRESS: Processing file 3 of 8...`
- Bad: `PROGRESS: Processing files...`

## Standard Progress Milestones

Use these standard milestones across all agents for consistency:

### 1. Starting
```
PROGRESS: Starting [operation/task name]...
```
Example: `PROGRESS: Starting implementation of authentication module...`

### 2. Reading Context
```
PROGRESS: Reading [N] files for context...
```
Example: `PROGRESS: Reading 5 configuration files...`

### 3. Analyzing
```
PROGRESS: Analyzing [what is being analyzed]...
```
Example: `PROGRESS: Analyzing code structure and dependencies...`

### 4. Planning
```
PROGRESS: Planning [what is being planned]...
```
Example: `PROGRESS: Planning changes to 3 modules...`

### 5. Executing Main Work
```
PROGRESS: [Action] [target]...
```
Examples:
- `PROGRESS: Implementing user authentication...`
- `PROGRESS: Writing test cases for API endpoints...`
- `PROGRESS: Refactoring database queries...`

### 6. Running Tests/Validation
```
PROGRESS: Running [test type/validation]...
```
Example: `PROGRESS: Running integration tests...`

### 7. Verifying
```
PROGRESS: Verifying [what is being verified]...
```
Example: `PROGRESS: Verifying code quality and standards compliance...`

### 8. Completing
```
PROGRESS: [Operation] complete[, status/summary]
```
Examples:
- `PROGRESS: Implementation complete, all tests passing.`
- `PROGRESS: Analysis complete, found 3 optimization opportunities.`

## Progress Flow Example

Typical progress flow for a code implementation task:

```
PROGRESS: Starting implementation of user authentication...
PROGRESS: Reading auth module files...
PROGRESS: Analyzing existing authentication patterns...
PROGRESS: Planning changes to 3 files...
PROGRESS: Implementing LoginService class...
PROGRESS: Implementing password hashing utilities...
PROGRESS: Implementing session management...
PROGRESS: Writing unit tests...
PROGRESS: Running test suite...
PROGRESS: Verifying code quality and standards compliance...
PROGRESS: Implementation complete, all tests passing.
```

## When to Emit Progress

### Before Long-Running Operations

Emit progress immediately before operations that take >2 seconds:

```
PROGRESS: Reading 50 source files...
[Read tool calls...]

PROGRESS: Running full test suite...
[Bash tool for tests...]

PROGRESS: Analyzing 1000+ lines of code...
[Processing logic...]
```

### Between Major Steps

Emit progress between distinct workflow phases:

```
PROGRESS: Analysis complete, starting implementation...
[Switch from reading to writing...]

PROGRESS: Code changes complete, running tests...
[Switch from editing to testing...]
```

### Not Too Frequently

**Don't**: Emit progress for every tiny operation
```
❌ PROGRESS: Opening file 1...
❌ PROGRESS: Reading line 1...
❌ PROGRESS: Reading line 2...
```

**Do**: Batch related operations
```
✅ PROGRESS: Reading configuration files (1 of 5)...
✅ PROGRESS: Reading configuration files (5 of 5)...
```

## Agent-Specific Customization

While following this standard protocol, agents may add domain-specific milestones:

### Research Specialist
```
PROGRESS: Searching codebase for [pattern]...
PROGRESS: Analyzing [N] API references...
PROGRESS: Synthesizing findings into report...
```

### Code Writer
```
PROGRESS: Generating boilerplate for [component]...
PROGRESS: Applying coding standards...
PROGRESS: Formatting code with [formatter]...
```

### Test Specialist
```
PROGRESS: Discovering test files...
PROGRESS: Executing test suite ([N] tests)...
PROGRESS: Analyzing test failures ([N] failed)...
```

### Debug Specialist
```
PROGRESS: Reproducing issue...
PROGRESS: Isolating failure point...
PROGRESS: Analyzing stack trace...
```

## Integration with TodoWrite

When using TodoWrite for task tracking, emit progress alongside task updates:

```
[Update TodoWrite: mark task as in_progress]
PROGRESS: Implementing authentication module...
[Implementation work...]
PROGRESS: Authentication module complete.
[Update TodoWrite: mark task as completed]
```

## Error Scenarios

When errors occur, emit final progress with error context:

```
PROGRESS: Running tests...
[Tests fail]
PROGRESS: Tests failed (3 of 45 tests failing). See error details above.
```

Then either:
1. Continue with recovery/retry (emit new progress)
2. Escalate to user (stop with error report)

## Benefits

**For Users**:
- Understand what agent is doing
- Estimate time remaining
- Identify bottlenecks
- Detect when agent is stuck

**For Debugging**:
- Track where failures occur
- Understand agent decision flow
- Identify performance issues

**For Orchestration**:
- Monitor multi-agent workflows
- Coordinate agent handoffs
- Track overall progress

## Implementation Notes

Progress streaming is **output-based** - agents simply emit progress markers as regular text output. No special tool calls or APIs are required.

The orchestrating command or user interface can:
- Display progress in real-time
- Log progress for debugging
- Track time between milestones
- Generate progress bars or status indicators

## See Also

- [Error Handling Guidelines](error-handling-guidelines.md) - How to handle errors during operations
- [Agent README](../README.md) - Overview of agent architecture
