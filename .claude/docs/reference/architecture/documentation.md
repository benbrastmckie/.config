# Architecture Standards: Core Documentation Standards

**Related Documents**:
- [Overview](overview.md) - Standards index and fundamentals
- [Validation](validation.md) - Execution enforcement patterns
- [Dependencies](dependencies.md) - Content separation patterns

---

## Standard 1: Executable Instructions Must Be Inline

### REQUIRED in Command Files

- Step-by-step execution procedures with numbered steps
- Tool invocation examples with actual parameter values
- Decision logic flowcharts with conditions and branches
- JSON/YAML structure specifications with all required fields
- Bash command examples with actual paths and flags
- Agent prompt templates (complete, not truncated)
- Critical warnings (e.g., "CRITICAL: Send ALL Task invocations in SINGLE message")
- Error recovery procedures with specific actions
- Checkpoint structure definitions with all fields
- Regex patterns for parsing results

### ALLOWED as External References

- Extended background context and rationale
- Additional examples beyond the core pattern
- Alternative approaches for advanced users
- Troubleshooting guides for edge cases
- Historical context and design decisions
- Related reading and deeper dives

---

## Standard 2: Reference Pattern

When referencing external files, use this pattern:

### CORRECT Pattern (Instructions first, reference after)

```markdown
### Research Phase Execution

**Step 1: Calculate Complexity Score**

Use this formula to determine thinking mode:
```
score = keywords("implement") x 3
      + keywords("security") x 4
      + estimated_files / 5
      + (research_topics - 1) x 2

Thinking Mode:
- 0-3: standard (no special mode)
- 4-6: "think" (moderate complexity)
- 7-9: "think hard" (high complexity)
- 10+: "think harder" (critical complexity)
```

**Step 2: Launch Parallel Research Agents**

**CRITICAL**: Send ALL Task tool invocations in SINGLE message block.

Example invocation pattern:
```yaml
# Task 1: Research existing patterns
Task {
  subagent_type: "general-purpose"
  description: "Research existing patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: [topic 1]
    Thinking mode: [mode from Step 1]
    Output path: /absolute/path/to/report1.md
}
```

**For Extended Examples**: See [Orchestration Patterns](orchestration-reference.md) for additional scenarios and troubleshooting.
```

### INCORRECT Pattern (Reference only, no inline instructions)

```markdown
### Research Phase Execution

The research phase coordinates multiple agents in parallel.

**See**: [Orchestration Patterns](orchestration-reference.md) for comprehensive execution details.

**Quick Reference**: Calculate complexity -> Launch agents -> Monitor execution
```

---

## Standard 3: Critical Information Density

### Minimum Required Density per command section

- **Overview**: Brief description (2-3 sentences)
- **Execution Steps**: Numbered steps with specific actions (5-10 steps typical)
- **Tool Patterns**: At least 1 complete example per tool type used
- **Decision Logic**: All branching conditions with specific thresholds
- **Error Handling**: Recovery procedures for each error type
- **Examples**: At least 1 complete end-to-end example

**Test**: Can Claude execute the command by reading only the command file? If NO, add more inline detail.

---

## Standard 4: Template Completeness

When providing templates (agent prompts, JSON structures, bash scripts):

### REQUIRED: Complete, copy-paste ready templates

```yaml
# Complete agent prompt template
Task {
  subagent_type: "general-purpose"
  description: "Update documentation using doc-writer protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent.

    ## Task: Update Documentation

    ### Context
    - Plan: ${PLAN_PATH}
    - Files Modified: ${FILES_LIST}
    - Tests: ${TEST_STATUS}

    ### Requirements
    1. Update README.md with new feature section
    2. Add usage examples
    3. Update CHANGELOG.md
    4. Create workflow summary at: ${SUMMARY_PATH}

    ### Output Format
    Return results as:
    ```
    DOCUMENTATION_COMPLETE: true
    FILES_UPDATED: [list]
    SUMMARY_CREATED: ${SUMMARY_PATH}
    ```
}
```

### FORBIDDEN: Truncated or incomplete templates

```yaml
# Incomplete template - DO NOT DO THIS
Task {
  subagent_type: "general-purpose"
  description: "Update documentation"
  prompt: |
    [See doc-writer agent definition for full prompt structure]

    Update documentation for: ${PLAN_PATH}
}
```

---

## Standard 5: Structural Annotations

Mark sections with usage annotations to guide future refactoring:

```markdown
## Process
[EXECUTION-CRITICAL: This section contains step-by-step procedures that Claude must see during command execution]

### Step 1: Initialize Workflow
[INLINE-REQUIRED: Bash commands and tool calls must remain inline]

```bash
source .claude/lib/workflow/checkpoint-utils.sh
CHECKPOINT=$(load_checkpoint "implement")
```

### Step 2: Parse Plan Structure
[INLINE-REQUIRED: Parsing logic with specific commands]

```bash
LEVEL=$(plan-core-bundle.sh detect_structure_level "$PLAN_PATH")
```
```

### Annotation Types

- `[EXECUTION-CRITICAL]`: Cannot be moved to external files
- `[INLINE-REQUIRED]`: Must stay inline for tool invocation
- `[REFERENCE-OK]`: Can be supplemented with external references
- `[EXAMPLE-ONLY]`: Can be moved to external files if core example remains

---

## Core Standards Summary

| Standard | Requirement | Key Pattern |
|----------|------------|-------------|
| 1 | Executable instructions inline | Steps, tools, decisions inline |
| 2 | Reference pattern | Instructions first, reference after |
| 3 | Information density | Complete examples per section |
| 4 | Template completeness | Copy-paste ready, not truncated |
| 5 | Structural annotations | Mark section criticality |

---

## Related Documentation

- [Architecture Standards Overview](overview.md)
- [Validation Standards](validation.md)
- [Testing Standards](testing.md)
- [Integration Patterns](integration.md)
