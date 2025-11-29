# Agent Prompts Directory

Evaluation prompt templates for agent-driven decision-making in plan management. These prompts provide structured guidance for agents when making nuanced judgments about plan structure and organization.

## Purpose

This directory contains prompt templates that guide specialized agents in making informed decisions about plan structure. Each prompt defines evaluation criteria, output formats, and integration patterns for specific decision points in the plan lifecycle.

**Key Functions**:
- Define evaluation criteria for agent decision-making
- Standardize agent output formats
- Provide examples of good judgment calls
- Document integration patterns with commands

**Design Philosophy**:
- **Judgment-Based**: Focus on understanding and context, not just metrics
- **Nuanced**: Support borderline cases and tradeoff analysis
- **Structured**: Consistent output format for parsing
- **Documented**: Include examples and integration patterns

## Module Documentation

### evaluate-plan-phases.md
**Purpose**: Guide holistic analysis of entire implementation plans to identify phases that would benefit from expansion

**Evaluation Approach**:
1. **Holistic Analysis**: Review entire plan to understand overall structure
2. **Per-Phase Assessment**: Evaluate task complexity, scope, and relationships
3. **Relationship Considerations**: Identify natural breakpoints and dependencies

**Evaluation Criteria**:
- Task count and individual task complexity
- Scope and breadth (files, modules, subsystems touched)
- Interrelationships between tasks within phases
- Potential for parallel work or staged execution
- Clarity vs overwhelming detail tradeoff

**Output Format**:
```
PHASES_TO_EXPAND: [list of phase numbers]

RATIONALE:
- Phase N: [explanation]
- Phase M: [explanation]

COMMANDS:
- /expand-phase <plan> N
- /expand-phase <plan> M
```

**Used By**:
- `/plan` - During initial plan creation
- `/implement` - Before starting implementation

**Integration Pattern**:
Commands invoke agents with full plan context and prompt reference. Agent makes informed decisions about which phases need expansion.

### evaluate-phase-expansion.md
**Purpose**: Evaluate whether a specific phase should be expanded to a separate file

**Evaluation Criteria**:
- **Task Complexity**: Number, intricacy, and interdependencies
- **Scope and Breadth**: Files/modules touched, multiple subsystems
- **Interrelationships**: Complex dependencies, sequential constraints
- **Clarity vs Detail**: Expansion helps or hinders understanding

**Decision Points**:
- Simple phases (3-5 tasks, straightforward): Keep inline
- Complex phases (10+ tasks, multiple subsystems): Expand
- Borderline cases (6-9 tasks): Nuanced judgment based on complexity

**Output Format**:
```
RECOMMENDATION: [YES or NO]

RATIONALE: [2-3 sentences explaining reasoning]

COMMAND: [If YES: /expand-phase <plan> <phase-num>]
```

**Used By**:
- `/implement` - During phase execution
- `/plan` - During plan creation
- Adaptive planning system

**Important Notes**:
- Make judgment based on understanding, not keyword counting
- Consider actual complexity, not just metrics
- Balance organization and simplicity
- Borderline cases require nuanced decision-making

### evaluate-phase-collapse.md
**Purpose**: Evaluate whether a completed expanded phase should be collapsed back to main plan file

**Evaluation Criteria**:
- **Completion Status**: Fully completed, complications during implementation
- **Simplicity Assessment**: Task count, straightforwardness, minimal dependencies
- **Value vs Simplicity**: Organizational value, conceptual importance
- **Structural Considerations**: Main plan length, consistency with other phases

**Decision Points**:
- Simple completed phases (3-5 tasks, no complications): Consider collapse
- Complex completed phases (10+ tasks, detailed notes): Keep expanded
- Conceptually important phases: Keep expanded regardless of simplicity
- Borderline cases: Evaluate implementation experience

**Output Format**:
```
RECOMMENDATION: [YES or NO]

RATIONALE: [2-3 sentences explaining reasoning]

COMMAND: [If YES: /collapse-phase <plan> <phase-num>]
```

**Used By**:
- `/implement` - After completing expanded phases
- `/collapse` - Manual collapse evaluation

**Important Notes**:
- Only completed phases considered for collapse
- Simple completed work can often be consolidated
- Conceptual clarity may outweigh simplicity concerns
- Collapse is non-destructive (can re-expand if needed)

## Usage Examples

### Plan Holistic Evaluation

```yaml
# /plan command invoking agent with evaluate-plan-phases.md
Task {
  subagent_type: "general-purpose"
  prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md

          Plan: specs/042_auth/plans/001_implementation.md

          Review all phases and identify which should be expanded.
          Follow the evaluation criteria and provide your recommendations."
}
```

Agent reads prompt, analyzes entire plan, and returns structured recommendation for which phases to expand.

### Phase Expansion Evaluation

```yaml
# /implement evaluating specific phase
Task {
  subagent_type: "general-purpose"
  prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-expansion.md

          Phase 3: Database Schema Updates

          Tasks:
          - [ ] Create users table with auth fields
          - [ ] Create sessions table for token tracking
          - [ ] Create auth_providers table
          - [ ] Add foreign key constraints
          - [ ] Create migration scripts
          - [ ] Update schema documentation
          - [ ] Add database indexes
          - [ ] Create rollback procedures

          Follow the evaluation criteria and provide your recommendation."
}
```

Agent evaluates complexity, provides YES/NO recommendation with rationale.

### Phase Collapse Evaluation

```yaml
# /implement evaluating completed expanded phase
Task {
  subagent_type: "general-purpose"
  prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-collapse.md

          Phase 2: Initial Setup [COMPLETED]

          This phase is expanded (in separate file) and all tasks are complete.

          Tasks completed:
          - [x] Install dependencies
          - [x] Create configuration files
          - [x] Set up directory structure

          Follow the evaluation criteria and provide your recommendation."
}
```

Agent evaluates simplicity vs value tradeoff, recommends collapse or keep expanded.

## Integration Points

### Command Integration
These prompts are used by:
- **`/plan`**: Holistic plan evaluation during creation
- **`/implement`**: Phase expansion/collapse decisions during execution
- **`/expand`**: Explicit expansion with evaluation
- **`/collapse`**: Explicit collapse with evaluation

### Adaptive Planning System
Prompts support adaptive planning capabilities:
- **Complexity Detection**: Automatic expansion triggers
- **Simplification**: Post-completion collapse evaluation
- **Quality Control**: Nuanced judgment instead of hard thresholds

### Agent System
Integration with hierarchical agent architecture:
- **Subagent Delegation**: Commands delegate evaluation to general-purpose agents
- **Structured Output**: Consistent format for parsing and action
- **Context Passing**: Full plan/phase context provided to agents

## Decision-Making Philosophy

### Judgment Over Metrics
Prompts emphasize:
- **Understanding**: Read and comprehend the actual work
- **Context**: Consider project-specific needs
- **Nuance**: Support borderline cases with thoughtful analysis
- **Flexibility**: Avoid rigid thresholds in favor of informed judgment

### Evaluation Criteria
Criteria are:
- **Multi-Dimensional**: Task count, complexity, scope, relationships
- **Balanced**: Consider tradeoffs (clarity vs simplicity)
- **Practical**: Focus on what helps implementation
- **Documented**: Explain reasoning for transparency

### Examples as Guidance
Each prompt includes:
- **Clear YES Cases**: Obvious expansion/collapse scenarios
- **Clear NO Cases**: Situations where action is inappropriate
- **Borderline Cases**: Nuanced decisions with detailed rationale
- **Reasoning Transparency**: Show how criteria lead to conclusions

## Output Format Standards

### Structured Format
All prompts produce parseable output:
```
RECOMMENDATION: [YES or NO]
RATIONALE: [explanation]
COMMAND: [action to take if YES]
```

### Parsing Integration
Commands parse agent output:
1. Extract `RECOMMENDATION` line
2. Check for YES/NO
3. If YES, extract and execute `COMMAND`
4. Log `RATIONALE` for audit trail

### Error Handling
If agent output doesn't match format:
- Fallback to heuristic-based decision
- Log warning about format mismatch
- Request user clarification if critical

## Evolution and Maintenance

### Template Updates
When updating prompts:
- Maintain output format for parsing compatibility
- Add examples for new edge cases
- Document criteria changes in prompt
- Test with real plans to verify quality

### New Prompts
When adding evaluation prompts:
- Follow established structure (Purpose, Criteria, Format, Examples)
- Define clear, parseable output format
- Include 3-4 examples (YES, NO, borderline)
- Document integration pattern
- Update this README with new prompt

### Quality Metrics
Evaluate prompt effectiveness:
- Agent recommendation quality (measured by user overrides)
- Parsing success rate (structured output conformance)
- Edge case handling (borderline case quality)
- Integration success (command workflow smoothness)

## Navigation

- [← Parent Directory](../README.md)
- [Related: Commands](../../commands/README.md)
- [Related: Adaptive Planning](../../docs/concepts/adaptive-planning.md)
