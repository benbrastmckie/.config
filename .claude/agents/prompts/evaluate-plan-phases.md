# Plan Holistic Phase Analysis Prompt

## Purpose
This prompt template guides agent analysis of an entire implementation plan to identify which phases (if any) would benefit from expansion to separate files.

## Context
You have just created an implementation plan with multiple phases. Your task is to review the entire plan holistically and identify which phases would benefit from expansion to separate files.

## Evaluation Approach

### Holistic Analysis
- Read the entire plan to understand the overall structure
- See how phases relate to each other
- Identify phases that form distinct units of work
- Consider the plan's overall complexity and organization

### Per-Phase Assessment
For each phase, consider:
- Task count and individual task complexity
- Scope and breadth (files, modules, subsystems touched)
- Interrelationships between tasks within the phase
- Potential for parallel work or staged execution
- Clarity vs overwhelming detail tradeoff

### Relationship Considerations
- Do some phases build on others in ways that suggest separation?
- Would expanding certain phases create better conceptual boundaries?
- Are there natural breakpoints where expansion makes sense?
- Would some phases benefit from detailed planning while others stay inline?

## Important Notes

- **Analyze the plan as a whole, not just individual phases**
- **Consider phase relationships and dependencies**
- **Make judgment calls based on understanding actual complexity**
- **Not all plans need phase expansion**
- **Expansion should improve clarity, not fragment unnecessarily**

## Output Format

Provide your analysis in the following structured format:

### If No Expansion Needed

```
RECOMMENDATION: NO EXPANSION NEEDED

RATIONALE: [2-3 sentences explaining why the plan works well as Level 0]
```

### If Expansion Recommended

```
RECOMMENDATION: YES - EXPAND PHASES

PHASES: [comma-separated phase numbers, e.g., "2, 4, 7"]

PHASE DETAILS:

Phase [N]: [Phase Name]
RATIONALE: [Why this phase benefits from expansion]
COMMAND: /expand-phase <plan> [N]

Phase [M]: [Phase Name]
RATIONALE: [Why this phase benefits from expansion]
COMMAND: /expand-phase <plan> [M]

[Continue for each recommended phase]
```

## Examples

### Example 1: No Expansion Needed

```
RECOMMENDATION: NO EXPANSION NEEDED

RATIONALE: This 4-phase plan has well-balanced phases with 3-5 tasks each. All phases are straightforward and form cohesive units that work well inline. The plan's overall complexity is moderate and doesn't warrant expansion at this stage. Phases can be expanded during implementation if needed.
```

### Example 2: Selective Expansion

```
RECOMMENDATION: YES - EXPAND PHASES

PHASES: 3, 5

PHASE DETAILS:

Phase 3: Refactor Core Architecture
RATIONALE: This phase contains 14 tasks spanning multiple subsystems with complex interdependencies. It touches 20+ files across database, API, and service layers. Expansion would allow better organization and parallel task planning.
COMMAND: /expand-phase <plan> 3

Phase 5: Integration Testing Suite
RATIONALE: This phase has 11 tasks involving test setup, multiple test categories, and CI/CD integration. The scope is broad enough to benefit from detailed breakdown in a separate file. Other phases can remain inline.
COMMAND: /expand-phase <plan> 5
```

### Example 3: High-Complexity Plan

```
RECOMMENDATION: YES - EXPAND PHASES

PHASES: 2, 3, 4, 6

PHASE DETAILS:

Phase 2: Database Migration
RATIONALE: Contains 9 tasks with schema changes, data migration scripts, and rollback procedures. Complex enough to warrant separate file for detailed planning.
COMMAND: /expand-phase <plan> 2

Phase 3: API Redesign
RATIONALE: 12 tasks touching authentication, authorization, and multiple endpoint families. Scope and complexity justify expansion.
COMMAND: /expand-phase <plan> 3

Phase 4: Frontend Refactor
RATIONALE: 15 tasks across component architecture, state management, and routing. Significant scope with opportunities for parallel work.
COMMAND: /expand-phase <plan> 4

Phase 6: Performance Optimization
RATIONALE: 10 tasks covering profiling, caching, query optimization, and load testing. Detailed work that benefits from organized breakdown.
COMMAND: /expand-phase <plan> 6

NOTE: Phases 1, 5, 7 are appropriately scoped and can remain inline.
```

### Example 4: Borderline Case

```
RECOMMENDATION: YES - EXPAND PHASES

PHASES: 4

PHASE DETAILS:

Phase 4: Integration Layer Implementation
RATIONALE: While this phase has only 8 tasks, each task is complex and involves different external systems (payment gateway, email service, analytics). The variety of integrations and distinct setup procedures justify expansion for better organization. Other phases are simpler and work well inline.
COMMAND: /expand-phase <plan> 4
```

## Integration Pattern

This prompt is used by `/plan` after creating a new implementation plan:

```yaml
# Primary agent already has plan in context (just created it)
# Inline evaluation, no separate agent invocation needed

prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md

        You just created this implementation plan with [N] phases.

        [Full plan content]

        Follow the holistic analysis approach and identify which phases (if any)
        would benefit from expansion to separate files.

        Provide your recommendation in the structured format."
```

The agent sees the entire plan context and makes informed recommendations about overall structure.

## Special Considerations

### Progressive Philosophy
- All plans start at Level 0 (single file)
- Expansion is optional and user-controlled
- Plans can be expanded during implementation if complexity emerges
- Initial expansion recommendations are guidance, not requirements

### Balance
- Too much expansion: Fragmentation, harder to see big picture
- Too little expansion: Overwhelming detail, hard to navigate complex phases
- Optimal: Expand phases that truly need it, keep simple phases inline

### User Control
- Recommendations are informative only
- User decides whether to expand immediately or during implementation
- `/expand-phase` can be used at any time
- Structure evolves based on actual needs
