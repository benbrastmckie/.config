# Architecture Standards: Integration Patterns

**Related Documents**:
- [Overview](overview.md) - Standards index and fundamentals
- [Validation](validation.md) - Execution enforcement patterns
- [Dependencies](dependencies.md) - Content separation patterns

---

## Standard 11: Imperative Agent Invocation Pattern

### Requirement

All Task invocations MUST use imperative instructions that signal immediate execution.

### Problem Statement

Documentation-only YAML blocks create a 0% agent delegation rate because they appear as code examples rather than executable instructions. When Task invocations are wrapped in markdown code blocks (` ```yaml`) without preceding imperative instructions, Claude interprets them as syntax examples rather than actions to execute.

### Required Elements

Every agent invocation MUST include:

1. **Imperative Instruction**: Use explicit execution markers
   - `**EXECUTE NOW**: USE the Task tool to invoke...`
   - `**INVOKE AGENT**: Use the Task tool with...`
   - `**CRITICAL**: Immediately invoke...`

2. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`
   - Examples: `.claude/agents/research-specialist.md`, `.claude/agents/plan-architect.md`

3. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - CORRECT: `Task {` ... `}` (no fence)

4. **No "Example" Prefixes**: Remove documentation context
   - WRONG: "Example agent invocation:" or "The following shows..."
   - CORRECT: "**EXECUTE NOW**: USE the Task tool..."

5. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`
   - Purpose: Enables command-level verification of agent compliance

### Correct Pattern

```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication for Node.js APIs
    - Output Path: /home/benjamin/.config/.claude/specs/027_auth/reports/001_oauth_patterns.md
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: /home/benjamin/.config/.claude/specs/027_auth/reports/001_oauth_patterns.md
  "
}
```

### Anti-Pattern (Documentation-Only)

```markdown
INCORRECT - This will never execute:

Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

The code block wrapper prevents execution.
```

### Additional Requirement - No Undermining Disclaimers

Imperative directives MUST NOT be followed by disclaimers suggesting template usage or future generation.

**FORBIDDEN**:
```markdown
**EXECUTE NOW**: USE the Task tool...

Task {
  ...
}

**Note**: The actual implementation will generate N Task calls based on complexity.
```

The disclaimer contradicts the imperative directive, causing Claude to interpret the Task block as a template example rather than executable instruction.

**CORRECT**:
```markdown
**EXECUTE NOW**: USE the Task tool for each topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- prompt: |
    ...
```

Use "for each [item]" phrasing and `[insert value]` placeholders to indicate loops and substitution without undermining the imperative.

### Rationale

1. **Execution Clarity**: Imperative instructions make it explicit that this is an action to execute, not a reference example
2. **0% Delegation Prevention**: Removes ambiguity that causes Claude to skip agent invocations
3. **Behavioral Injection**: References agent behavioral files instead of duplicating guidelines inline
4. **Verification Enablement**: Completion signals allow command-level validation
5. **No Contradictions**: Clean imperatives without disclaimers prevent template assumption

### Enforcement

Detection pattern for documentation-only blocks:
```bash
# Find YAML blocks not preceded by imperative instructions
awk '/```yaml/{
  found=0
  for(i=NR-5; i<NR; i++) {
    if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
  }
  if(!found) print FILENAME":"NR": Documentation-only YAML block (violates Standard 11)"
} {lines[NR]=$0}' .claude/commands/*.md
```

Regression test requirements:
- Test 1: All agent invocations have imperative instruction within 5 lines
- Test 2: Zero YAML code blocks in agent invocation context (documentation examples excluded)
- Test 3: All agent invocations reference `.claude/agents/*.md` behavioral files
- Test 4: All agent invocations require completion signal in return value

### Historical Context

This standard was first applied after discovering a 0% agent delegation rate in the /supervise command (spec 438), then expanded to fix /coordinate and /research commands (spec 495) and improve /supervise error handling (spec 057).

**Spec 438** (2025-10-24): /supervise agent delegation fix
- Problem: 7 YAML blocks wrapped in markdown code fences
- Result: 0% delegation rate before fix, >90% after

**Spec 495** (2025-10-27): /coordinate and /research agent delegation failures
- Problem: 9 agent invocations in /coordinate, 3 in /research using documentation-only YAML pattern
- Result: 0% -> >90% delegation rate, 100% file creation reliability

**Spec 057** (2025-10-27): /supervise robustness improvements and fail-fast error handling
- Problem: Bootstrap fallback mechanisms hiding configuration errors
- Result: Removed 32 lines of fallback functions, enhanced 7 library sourcing error messages

### Performance Metrics

- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)
- Parallel execution: Enabled for independent operations
- Bootstrap reliability: 100% (fail-fast exposes configuration errors immediately)
- File creation verification: 100% reliability (70% -> 100% with MANDATORY VERIFICATION checkpoints)

---

## Related Standards

This document should be read in conjunction with:
- [Command Patterns](../guides/patterns/command-patterns/command-patterns-overview.md): Common execution patterns across commands
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md): Agent invocation and coordination patterns
- [Testing Protocols](testing-protocols.md): Validation and testing requirements
- [Documentation Standards](../../../CLAUDE.md#documentation-policy): General documentation guidelines
- [Bash Tool Limitations](../troubleshooting/bash-tool-limitations.md): Command substitution escaping and bash block size limits

---

## Related Documentation

- [Architecture Standards Overview](overview.md)
- [Validation Standards](validation.md)
- [Dependencies](dependencies.md)
- [Testing Standards](testing.md)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md#avoiding-documentation-only-patterns)
