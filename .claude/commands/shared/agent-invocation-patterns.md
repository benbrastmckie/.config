# Agent Invocation Patterns

This template provides standard patterns for invoking agents using the Task tool in commands and orchestration workflows.

## Basic Task Tool Invocation

```
Task {
  subagent_type: "general-purpose"
  description: "[Brief description of task in 5-10 words]"
  prompt: |
    Read and follow the behavioral guidelines from:
    [absolute-path-to-agent.md]

    You are acting as a [Agent Name] with the tools and constraints
    defined in that file.

    [Task-specific context and requirements]
}
```

## Common Agent Invocation Examples

### Research Specialist

```
Task {
  subagent_type: "general-purpose"
  description: "Research [specific topic] patterns and best practices"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist.

    Research Topic: [Topic name]
    Focus Area: [Specific aspect]
    Project Standards: CLAUDE.md

    Investigation:
    1. Codebase Analysis
       - Search for existing implementations
       - Identify patterns and conventions
       - Note relevant file locations

    2. Best Practices Research
       - Industry standards (2025)
       - Framework-specific recommendations
       - Trade-offs and considerations

    Output: Max 150-word summary with:
    - Key findings
    - Existing patterns
    - Recommendations
    - File references
}
```

### Plan Architect

```
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for [feature]"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    You are acting as a Plan Architect.

    Feature: [Feature description]
    Research Reports: [List of report paths]
    Project Standards: CLAUDE.md

    Requirements:
    - Synthesize research findings
    - Create structured implementation plan
    - Define phases with tasks
    - Estimate complexity and time
    - Identify dependencies

    Output: Implementation plan in topic-based structure
}
```

### Code Writer

```
Task {
  subagent_type: "general-purpose"
  description: "Implement Phase [N]: [Phase name]"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer.

    Phase: [N] - [Phase name]
    Plan: [Plan path]
    Standards: CLAUDE.md

    Tasks:
    [List of tasks from phase]

    Requirements:
    - Implement all tasks in phase
    - Follow project standards
    - Write clean, tested code
    - Emit PROGRESS markers

    Output: Implementation complete + files modified
}
```

### Debug Specialist

```
Task {
  subagent_type: "general-purpose"
  description: "Investigate [issue description]"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist.

    Issue: [Issue description]
    Phase: [Phase number if applicable]
    Test Failures: [Test output]

    Investigation Required:
    1. Root cause analysis
    2. Evidence gathering
    3. Proposed solutions with pros/cons
    4. Testing strategy

    Output: Debug report in topic-based structure
}
```

### Spec Updater

```
Task {
  subagent_type: "general-purpose"
  description: "Update cross-references for [artifact]"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/spec-updater.md

    You are acting as a Spec Updater Agent.

    Context:
    - Artifact: [Artifact path]
    - Topic directory: [Topic dir]
    - Operation: [report_creation|plan_creation|debug_creation|summary_creation]

    Tasks:
    1. Update cross-references
    2. Link artifacts bidirectionally
    3. Verify topic structure
    4. Check gitignore compliance

    Output: Cross-reference status + files modified
}
```

### Test Specialist

```
Task {
  subagent_type: "general-purpose"
  description: "Run tests for Phase [N]"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/test-specialist.md

    You are acting as a Test Specialist.

    Phase: [N] - [Phase name]
    Test Commands: [From CLAUDE.md or phase]
    Coverage Target: [Percentage]

    Tasks:
    1. Execute tests
    2. Analyze failures
    3. Check coverage
    4. Report results

    Output: Test results + coverage data
}
```

### Doc Writer

```
Task {
  subagent_type: "general-purpose"
  description: "Update documentation for [changes]"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer.

    Changes: [Description of changes]
    Files Modified: [List of files]
    Documentation Standards: CLAUDE.md

    Tasks:
    1. Update relevant documentation
    2. Follow timeless writing standards
    3. No historical commentary
    4. Update examples and references

    Output: Documentation updated + files modified
}
```

## Parallel Agent Invocations

For parallel execution (multiple agents in same message):

```
# Research Phase - Multiple specialists in parallel
Task { /* Research Specialist 1 - Topic A */ }
Task { /* Research Specialist 2 - Topic B */ }
Task { /* Research Specialist 3 - Topic C */ }
```

## Sequential Agent Invocations

For dependent operations (separate messages):

```
# Message 1: Research
Task { /* Research Specialist */ }

# Wait for completion, then Message 2: Planning
Task { /* Plan Architect using research results */ }
```

## Agent Response Patterns

### Successful Agent Response

```
✓ [Agent Task] Complete
Files Modified: [N]
Key Changes:
- [Change 1]
- [Change 2]
Details: [path-to-artifact]
```

### Failed Agent Response

```
✗ [Agent Task] Failed
Error: [Brief description]
Recovery: [Suggested next steps]
Details: [path-to-error-log]
```

## Best Practices

### Prompt Construction
- Be specific and concise
- Provide necessary context only
- Include relevant file paths
- Reference project standards
- Set clear expectations

### Output Expectations
- Agents should return minimal summaries
- Details stored in artifact files
- Always provide file paths
- Use standardized response patterns

### Error Handling
- Agents should report errors clearly
- Suggest recovery actions
- Continue when possible
- Escalate to user when necessary

### Context Management
- Keep prompts under 500 tokens
- Reference external files for details
- Avoid repeating information
- Use relative paths when possible

## Integration with Output Patterns

Agents should follow the output patterns defined in `.claude/templates/output-patterns.md`:

- Use ✓/✗ prefixes for success/failure
- Emit PROGRESS markers for long operations
- Provide absolute paths to artifacts
- Keep summaries to 1-2 lines

## Common Mistakes to Avoid

### DON'T
- Repeat full agent guidelines in prompt
- Include unnecessary context
- Use verbose prompts (>500 tokens)
- Forget to specify output format
- Omit file paths in responses

### DO
- Reference agent file path
- Provide task-specific context
- Set clear output expectations
- Request minimal summaries
- Use standardized patterns

## Notes

- All agent paths should be absolute (e.g., `/home/benjamin/.config/.claude/agents/agent-name.md`)
- Agents have access to tools defined in their agent file
- Task tool enforces agent constraints automatically
- Use `subagent_type: "general-purpose"` for all agents
- Keep description under 10 words for clarity
