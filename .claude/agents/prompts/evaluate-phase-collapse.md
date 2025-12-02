# Phase Collapse Evaluation Prompt

## Purpose
This prompt template guides agent evaluation of whether a completed expanded phase should be collapsed back to the main plan file.

## Context
You have a completed, expanded phase (currently in a separate file) in your context. Your task is to evaluate whether this phase is simple enough to collapse back into the main plan file for better simplicity.

## Evaluation Criteria

Consider the following factors when making your judgment:

### Completion Status
- Is the phase fully completed (all tasks marked [x])?
- Were there any complications during implementation?
- Does the completed work reveal complexity that wasn't apparent initially?

### Simplicity Assessment
- How many tasks does the phase have?
- Are the tasks straightforward or complex?
- Does the phase have minimal dependencies?
- Would the work fit naturally inline without cluttering the main plan?

### Value vs Simplicity Tradeoff
- Does the separate file provide organizational value?
- Is there conceptual importance to keeping it separate?
- Would collapsing improve or hurt plan readability?
- Does the phase represent a distinct implementation stage worth highlighting?

### Structural Considerations
- Would collapsing create an overly long main plan file?
- Are other phases still expanded, creating inconsistency?
- Does the phase relate closely to inline phases?

## Important Notes

- **Only completed phases should be considered for collapse**
- **Simple completed work can often be consolidated**
- **Conceptual clarity may outweigh simplicity concerns**
- **Collapse is non-destructive (can re-expand if needed)**

## Output Format

Provide your evaluation in the following structured format:

```
RECOMMENDATION: [YES or NO]

RATIONALE: [2-3 sentences explaining your reasoning based on the criteria above]

COMMAND: [If YES: /collapse-phase <plan> <phase-num>]
```

## Examples

### Example 1: Simple Completed Phase (Recommend YES)

```
RECOMMENDATION: YES

RATIONALE: This completed phase contains only 3 straightforward tasks with no complex dependencies. All tasks were completed without complications and involve simple file updates. Collapsing this back to the main plan would simplify the overall structure without losing clarity.

COMMAND: /collapse-phase <plan> 2
```

### Example 2: Complex Completed Phase (Recommend NO)

```
RECOMMENDATION: NO

RATIONALE: While completed, this phase contains 12 intricate tasks with detailed implementation notes added during execution. The separate file provides valuable organization and makes it easier to reference the work done. Keeping it expanded maintains clarity despite completion.

COMMAND: N/A
```

### Example 3: Simple But Conceptually Important (Recommend NO)

```
RECOMMENDATION: NO

RATIONALE: This phase has only 4 simple tasks, but it represents a critical initialization stage that sets up the foundation for subsequent phases. The conceptual importance and clear separation from other work justifies keeping it in a separate file for documentation purposes.

COMMAND: N/A
```

### Example 4: Borderline Case (Nuanced Decision)

```
RECOMMENDATION: YES

RATIONALE: This phase has 5 tasks of moderate complexity, but implementation revealed they were more straightforward than anticipated. With all tasks completed and no complications encountered, the work can be effectively represented inline. This would reduce structural complexity while maintaining full information.

COMMAND: /collapse-phase <plan> 4
```

## Integration Pattern

This prompt is used by `/implement` when evaluating completed expanded phases:

```yaml
**EXECUTE NOW**: USE the Task tool to invoke the evaluator.

Task {
  subagent_type: "general-purpose"
  prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-collapse.md

          Phase [N]: [Phase Name] [COMPLETED]

          This phase is expanded (in separate file) and all tasks are complete.

          Tasks completed:
          [task list with [x] markers]

          Follow the evaluation criteria and provide your recommendation."
}
```

The agent has the full completed phase context and makes an informed judgment about whether collapse would improve plan simplicity.
