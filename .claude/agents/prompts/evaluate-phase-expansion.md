# Phase Expansion Evaluation Prompt

## Purpose
This prompt template guides agent evaluation of whether a phase should be expanded to a separate file.

## Context
You have a phase from an implementation plan in your context. Your task is to evaluate whether this phase would benefit from expansion to a separate file for better organization and clarity.

## Evaluation Criteria

Consider the following factors when making your judgment:

### Task Complexity
- How many tasks are in the phase?
- Are the tasks straightforward or complex?
- Do tasks have intricate interdependencies?
- Would individual tasks benefit from detailed breakdowns?

### Scope and Breadth
- How many files or modules does the phase touch?
- Does the phase span multiple subsystems or domains?
- Are there multiple distinct areas of work?
- Would the work benefit from parallel execution?

### Interrelationships
- Do tasks have complex dependencies on each other?
- Are there sequential constraints that complicate planning?
- Would seeing tasks in isolation help clarity?

### Clarity vs Detail Tradeoff
- Would a separate file make the phase easier to understand?
- Or would expansion create unnecessary fragmentation?
- Does the phase form a cohesive unit that's better kept inline?
- Would expansion help or hinder implementation?

## Important Notes

- **Make judgment based on understanding, not keyword counting**
- **Consider the actual complexity, not just metrics**
- **Borderline cases require nuanced decision-making**
- **Balance between organization and simplicity**

## Output Format

Provide your evaluation in the following structured format:

```
RECOMMENDATION: [YES or NO]

RATIONALE: [2-3 sentences explaining your reasoning based on the criteria above]

COMMAND: [If YES: /expand-phase <plan> <phase-num>]
```

## Examples

### Example 1: Complex Phase (Recommend YES)

```
RECOMMENDATION: YES

RATIONALE: This phase contains 15 tasks spanning database schema changes, API endpoint modifications, and frontend component updates. The tasks involve multiple subsystems and would benefit from detailed organization in a separate file. The interdependencies between backend and frontend changes warrant explicit documentation.

COMMAND: /expand-phase <plan> 3
```

### Example 2: Simple Phase (Recommend NO)

```
RECOMMENDATION: NO

RATIONALE: This phase contains 4 straightforward tasks that are closely related and form a cohesive unit. All tasks involve updating documentation files in a single directory. Keeping these tasks inline maintains simplicity without sacrificing clarity.

COMMAND: N/A
```

### Example 3: Borderline Case (Nuanced Decision)

```
RECOMMENDATION: NO

RATIONALE: While this phase has 8 tasks, they follow a repetitive pattern of updating similar configuration files. Despite the task count, the work is straightforward and doesn't have complex dependencies. The repetitive nature makes it easy to understand inline, and expansion would create unnecessary fragmentation.

COMMAND: N/A
```

## Integration Pattern

This prompt is used by commands like `/implement` and `/plan` when evaluating phases:

```yaml
**EXECUTE NOW**: USE the Task tool to invoke the evaluator.

Task {
  subagent_type: "general-purpose"
  prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-expansion.md

          Phase [N]: [Phase Name]

          Tasks:
          [task list]

          Follow the evaluation criteria and provide your recommendation."
}
```

The agent has the full phase context and makes an informed judgment call.
