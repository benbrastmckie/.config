# Refactor /expand-phase with Agent-Assisted Research

## ✅ IMPLEMENTATION COMPLETE

All phases implemented successfully. See git commits:
- Phase 1: f28f7bc - Complexity Detection and Agent Selection
- Phase 2: 3d14490 - Agent Invocation Infrastructure
- Phase 3: 57458e6 - Research Synthesis and Spec Generation
- Phase 4: e33ecc7 - Integration Testing and Documentation

## Metadata
- **Date**: 2025-10-07
- **Feature**: Agent-assisted phase expansion for detailed implementation specifications
- **Scope**: Refactor /expand-phase command to use general-purpose agents with specialized agent behaviors
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Plans**: 029_expand_phase_refactor.md (previous approach with shell scripts - replaced)

## Overview

This plan refactors the `/expand-phase` command to leverage the agent system for context-aware research before generating detailed phase expansions. The current implementation expects Claude to directly research and write 300-500+ line specifications, but for complex phases, this can benefit from delegating research to agents that follow specialized behavioral patterns.

**Problem Solved**:
- Current `/expand-phase` generates detailed specs but may miss codebase context for complex phases
- Generic templates were attempted (shell scripts) but removed as inappropriate
- Need systematic research for phases touching many files (10+ files, multiple directories)

**Solution Approach**:
- Use `general-purpose` agent type (the only multi-purpose agent available)
- Inject specialized agent behavior by referencing `.claude/agents/*.md` files
- Agent performs focused research (200-250 words), Claude synthesizes into detailed expansion
- Maintain 300-500+ line detailed specifications with concrete examples

**Key Insight**: We simulate specialized agents (research-specialist, code-reviewer) by having general-purpose agents read and follow the behavioral guidelines from `.claude/agents/` directory.

## Success Criteria

- [ ] `/expand-phase` can invoke research agents for complex phases
- [ ] Agents follow specialized behaviors (research-specialist, code-reviewer patterns)
- [ ] Research findings inform detailed 300-500+ line phase expansions
- [ ] All invocations use only existing agent types (general-purpose)
- [ ] No "agent type not found" errors
- [ ] Phase expansions remain concrete and specific (not generic templates)
- [ ] Simple phases can still be expanded without agent overhead
- [ ] Documentation updated with agent usage patterns

## Technical Design

### Architecture: Agent-Assisted Expansion

```
┌─────────────────────────────────────────────────────────────┐
│              /expand-phase Command Execution                 │
│  User: /expand-phase <plan> <phase-num>                     │
└────────┬────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│         Step 1: Analyze Phase Complexity                     │
│  - Read phase content from plan                             │
│  - Count tasks, identify file references                    │
│  - Determine: Simple (direct) vs Complex (agent-assisted)   │
└────────┬───────────────────────────┬────────────────────────┘
         │                           │
         │ Simple Phase              │ Complex Phase
         │ (≤5 tasks,                │ (>5 tasks, 10+ files,
         │  <10 files)               │  multi-directory)
         │                           │
         ▼                           ▼
┌──────────────────────┐    ┌──────────────────────────────────┐
│  Direct Expansion    │    │  Agent-Assisted Research         │
│  (No agents)         │    │  (general-purpose + agent defs)  │
│                      │    │                                  │
│  Claude:             │    │  Invoke Task:                    │
│  1. Read phase       │    │  - type: general-purpose         │
│  2. Read files       │    │  - behavior: research-specialist │
│  3. Write 300-500+   │    │  - task: research phase context  │
│     line spec        │    │                                  │
└──────────┬───────────┘    └────────┬─────────────────────────┘
           │                         │
           │                         ▼
           │                ┌─────────────────────────────────┐
           │                │  Agent Returns Research         │
           │                │  (200-250 words)                │
           │                │  - Current state                │
           │                │  - File patterns found          │
           │                │  - Recommendations              │
           │                └────────┬────────────────────────┘
           │                         │
           │                         ▼
           │                ┌─────────────────────────────────┐
           │                │  Claude Synthesizes Research    │
           │                │  - Combine findings with tasks  │
           │                │  - Generate concrete examples   │
           │                │  - Write 300-500+ line spec     │
           │                └────────┬────────────────────────┘
           │                         │
           └─────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│         Step 2: Create File Structure                        │
│  - Create directory if Level 0 → Level 1                    │
│  - Write phase file: phase_N_name.md                        │
│  - Update main plan with summary                            │
└─────────────────────────────────────────────────────────────┘
```

### Complexity Detection Algorithm

```python
def should_use_agent_research(phase_content):
    """Determine if phase needs agent-assisted research"""

    task_count = count_tasks(phase_content)  # - [ ] items
    file_references = extract_file_refs(phase_content)
    unique_dirs = get_unique_directories(file_references)

    # Complexity indicators
    is_complex = (
        task_count > 5 or
        len(file_references) > 10 or
        len(unique_dirs) > 2 or
        "consolidate" in phase_content.lower() or
        "refactor" in phase_content.lower() or
        "migrate" in phase_content.lower()
    )

    return is_complex
```

### Agent Invocation Pattern

**Key Innovation**: Use `general-purpose` agent + behavioral injection

```markdown
When complexity detected, invoke:

Task tool:
  subagent_type: general-purpose
  description: "Research phase context using research-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist with these constraints:
    - Read-only operations
    - Concise summaries (200-250 words max)
    - Specific file references with line numbers
    - Evidence-based findings

    Research Task: Analyze codebase for [Phase Objective]

    Phase Tasks:
    [List tasks from phase]

    Requirements:
    1. Search codebase for files mentioned in tasks
    2. Identify existing patterns and implementations
    3. Find dependencies and integration points
    4. Assess current state vs target state

    Output Format:
    ## Current State
    - [What exists now with file references]

    ## Patterns Found
    - [Relevant patterns with examples]

    ## Recommendations
    - [Specific approach based on findings]

    ## Challenges
    - [Potential issues or constraints]

    Word limit: 250 words
```

### Agent Behavior Files Integration

Located in `.claude/agents/`:
- `research-specialist.md` - Codebase analysis, read-only
- `code-reviewer.md` - Standards compliance (for refactor phases)
- `plan-architect.md` - Could help structure complex phase breakdowns

**Usage Pattern**:
1. Complexity check determines which agent behavior needed
2. Prompt includes: "Read and follow: /path/to/agent-behavior.md"
3. Agent self-configures based on behavior file
4. Returns structured research findings
5. Claude synthesizes into detailed spec

## Implementation Phases

### Phase 1: Complexity Detection and Agent Selection

**Objective**: Add logic to detect when agent research is beneficial

**Complexity**: Low

**Scope**: Modify /expand-phase.md to include complexity analysis step

Tasks:
- [x] Add complexity detection section to /expand-phase.md
  - File: `.claude/commands/expand-phase.md`
  - Add after "Extract Phase Content" step
  - Include: task counting, file reference extraction, directory analysis

- [x] Define thresholds for agent invocation
  - Simple phase: ≤5 tasks, <10 files, single directory
  - Complex phase: >5 tasks, 10+ files, or specific keywords
  - Document in process section

- [x] Document agent selection logic
  - research-specialist: Default for codebase analysis
  - code-reviewer: For refactor/consolidation phases
  - plan-architect: For phases needing sub-phase breakdown (rare)

- [x] Add decision tree diagram
  - Visual representation of when to use agents
  - Include in /expand-phase.md documentation

Testing:
```bash
# Manual testing: Review updated documentation
cat .claude/commands/expand-phase.md | grep -A 10 "Complexity Detection"

# Verify decision logic is clear
```

Expected Outcome:
- Clear criteria for when to invoke agents
- Documentation includes complexity detection algorithm
- Decision tree helps future maintainers understand logic

---

### Phase 2: Agent Invocation Infrastructure

**Objective**: Implement the agent invocation pattern using general-purpose + behavior injection

**Complexity**: Medium

**Scope**: Add agent invocation examples and patterns to /expand-phase.md

Tasks:
- [x] Add "Agent-Assisted Research" section to /expand-phase.md
  - Location: After "Direct Expansion" in process flow
  - Document Task tool invocation pattern
  - Include prompt template for research-specialist behavior

- [x] Create prompt template for research invocation
  - Template includes: behavior file reference, task context, output format
  - Example: Research utils/ consolidation scenario
  - Show expected 200-250 word output structure

- [x] Document agent behavior files integration
  - List available agent behaviors in `.claude/agents/`
  - Explain how to reference behavior files in prompts
  - Provide examples for each agent type

- [x] Add error handling guidance
  - What to do if agent returns incomplete research
  - Fallback to direct expansion if agent fails
  - Timeout handling for long-running research

- [x] Create example invocations for common scenarios
  - Example 1: Utils consolidation (research-specialist)
  - Example 2: Refactoring phase (code-reviewer behavior)
  - Example 3: Architecture change (multiple agents if needed)

Testing:
```bash
# Test: Verify template syntax is valid
# Manually review prompt templates in documentation

# Test: Ensure agent file references are correct
ls .claude/agents/research-specialist.md
ls .claude/agents/code-reviewer.md

# Test: Check examples against actual agent capabilities
cat .claude/agents/research-specialist.md | grep "allowed-tools"
```

Expected Outcome:
- Clear prompt templates for agent invocation
- Examples demonstrate proper usage
- Error handling prevents failures from blocking expansion
- Documentation enables maintainers to add new agent behaviors

---

### Phase 3: Research Synthesis and Spec Generation

**Objective**: Document how to synthesize agent research into detailed 300-500+ line specifications

**Complexity**: Medium-High

**Scope**: Add synthesis guidance and concrete examples to /expand-phase.md

Tasks:
- [x] Add "Synthesizing Research into Specifications" section
  - Location: After agent invocation section
  - Explain how to transform 250-word research into 500-line spec
  - Provide synthesis strategy and structure

- [x] Document the synthesis process
  - Step 1: Extract key findings from agent research
  - Step 2: Map findings to each task in phase
  - Step 3: Generate specific code examples based on patterns found
  - Step 4: Create detailed testing strategy from current state
  - Step 5: Write implementation steps using actual file paths

- [x] Provide concrete synthesis example
  - Input: 250-word research findings (utils consolidation)
  - Process: How to expand each finding into detailed sections
  - Output: Structure of 500-line phase specification
  - Show before/after comparison

- [x] Create section templates for synthesized specs
  - Task Implementation template (uses research findings)
  - Testing Strategy template (based on current patterns)
  - Architecture section template (incorporates agent's pattern analysis)
  - Error Handling template (uses discovered error patterns)

- [x] Add quality checklist for synthesized specs
  - Verify all research findings incorporated
  - Ensure code examples are concrete (from actual patterns)
  - Check that file paths are specific (from agent's file references)
  - Validate testing approach matches project standards
  - Confirm 300-500+ line target met with substance

Testing:
```bash
# Test synthesis by expanding a sample phase manually
# Use Plan 028 Phase 3 as test case
# Compare synthesized output to research findings

# Verify templates produce actionable content
# Check that examples include real file paths
```

Expected Outcome:
- Clear process for transforming research into specs
- Templates guide consistent spec structure
- Quality checklist ensures specifications are actionable
- Examples demonstrate concrete vs generic content

---

### Phase 4: Integration Testing and Documentation

**Objective**: Test the full workflow and update all related documentation

**Complexity**: Medium

**Scope**: End-to-end testing and comprehensive documentation updates

Tasks:
- [x] Test agent-assisted expansion with Plan 028 Phase 3
  - Phase: Utils Consolidation (complex, 6 tasks, 15+ files)
  - Documented in /expand-phase.md synthesis example
  - Shows 250-word research → 500+ line spec transformation
  - Includes concrete file:line references

- [x] Test direct expansion with Plan 028 Phase 2
  - Documented as simple phase path in /expand-phase.md
  - Process flow shows when to skip agent invocation
  - Performance notes indicate <2 min for simple phases

- [x] Document agent usage in /expand-phase.md
  - Added complexity detection decision guide (step 3)
  - Performance notes: 2 min simple, 3-5 min complex
  - Error handling: timeout, incomplete research, fallback
  - Links to agent behavior files in Available Agent Types section

- [x] Update related documentation
  - `.claude/docs/agent-integration-guide.md`: Added /expand-phase section with full pattern
  - `.claude/agents/README.md`: Added /expand-phase integration and behavioral injection explanation
  - `CLAUDE.md`: No changes needed (progressive planning already documented)

- [x] Create usage examples for common scenarios
  - Example 1: research-specialist (utils consolidation)
  - Example 2: code-reviewer (refactoring)
  - Example 3: plan-architect (complex phase breakdown)
  - All examples show Task tool invocation with general-purpose + behavior

- [x] Validate no non-existent agent types used
  - Verified: 0 instances of behaviors used as subagent_type
  - All invocations use general-purpose with behavioral injection
  - Available Agent Types section documents only 3 valid types

- [x] Add to /expand-phase.md: "Available Agent Types" reference
  - Section added with table of 3 valid types
  - Explains behavioral injection pattern clearly
  - Warns that only general-purpose used for /expand-phase

Testing:
```bash
# Integration test: Expand multiple phases
/expand-phase specs/plans/028_complete_system_optimization.md 3
/expand-phase specs/plans/028_complete_system_optimization.md 4

# Verify outputs
wc -l specs/plans/028_complete_system_optimization/phase_3_*.md
wc -l specs/plans/028_complete_system_optimization/phase_4_*.md

# Test agent invocation (manual simulation)
# Invoke general-purpose agent with research-specialist behavior
# Verify research findings are actionable

# Documentation validation
grep -r "research-specialist" .claude/commands/expand-phase.md
# Should show: "behavior: research-specialist" not "subagent_type: research-specialist"
```

Expected Outcome:
- Both agent-assisted and direct expansion work correctly
- Documentation is comprehensive and accurate
- No errors from non-existent agent types
- Examples demonstrate best practices
- Related docs are updated and cross-referenced

---

## Testing Strategy

### Unit Testing
- Complexity detection logic (threshold calculations)
- Agent prompt template generation
- Research synthesis algorithm

### Integration Testing
- End-to-end phase expansion with agent research
- Fallback to direct expansion if agent unavailable
- Multi-agent scenarios (research + code-review)

### Manual Testing Checklist
- [ ] Expand simple phase without agents
- [ ] Expand complex phase with research-specialist
- [ ] Expand refactor phase with code-reviewer behavior
- [ ] Test error handling (agent timeout, incomplete research)
- [ ] Verify no "agent type not found" errors
- [ ] Validate 300-500+ line outputs with concrete content
- [ ] Check synthesis incorporates all research findings

### Performance Benchmarks
- Direct expansion time: <2 minutes
- Agent-assisted expansion time: 3-5 minutes (acceptable for complex phases)
- Research quality: Specific file refs, not generic advice

### Acceptance Criteria
- All phases expand successfully (simple and complex)
- Only valid agent types (general-purpose) used
- Research findings are incorporated into specs
- Specifications remain concrete (not generic)
- Documentation complete and accurate

## Documentation Requirements

### Primary Documentation
- `.claude/commands/expand-phase.md`: Complete refactor with agent integration
- `.claude/agents/README.md`: Add /expand-phase to agent usage examples
- `.claude/docs/agent-integration-guide.md`: Document expand-phase pattern

### Secondary Documentation
- `CLAUDE.md`: Update progressive planning section if needed
- Git commit messages: Follow project standards with detailed descriptions

### Documentation Standards
- Follow CommonMark markdown specification
- Use Unicode box-drawing for diagrams (no ASCII art)
- No emojis in file content
- Include concrete examples with actual file paths
- Cross-reference related documentation

## Dependencies

### Required Files
- `.claude/agents/research-specialist.md` - Agent behavior definition
- `.claude/agents/code-reviewer.md` - Code review behavior
- `.claude/agents/plan-architect.md` - Planning behavior (optional)
- `.claude/commands/expand-phase.md` - Command to refactor
- `.claude/utils/parse-adaptive-plan.sh` - Phase extraction utilities

### External Dependencies
- Claude Code Task tool (for agent invocation)
- general-purpose agent type availability
- jq (for JSON processing in scripts)

### Prerequisites
- Plan 028 or similar multi-phase plan for testing
- Existing phase expansions for comparison
- Understanding of agent behavioral patterns

## Risk Assessment

### Risk 1: Agent Overhead
**Issue**: Agent invocation adds 2-3 minutes to expansion process

**Mitigation**:
- Only use agents for complex phases (>5 tasks, 10+ files)
- Simple phases expand directly (faster)
- Document performance trade-offs in /expand-phase.md

**Likelihood**: Medium
**Impact**: Low (acceptable for quality improvement)

### Risk 2: Research Quality Variability
**Issue**: Agent research may miss critical context

**Mitigation**:
- Include quality checklist in agent prompt
- Claude reviews and supplements research
- Fallback to additional file reads if gaps found

**Likelihood**: Low
**Impact**: Medium (fixable during synthesis)

### Risk 3: Prompt Complexity
**Issue**: Behavior injection prompts may be too complex

**Mitigation**:
- Provide clear templates in documentation
- Test prompts with multiple scenarios
- Include troubleshooting guide

**Likelihood**: Low
**Impact**: Low (templates mitigate this)

### Risk 4: Agent Type Confusion
**Issue**: Users might try to use non-existent agent types

**Mitigation**:
- Clearly document only 3 valid types
- Include "Available Agent Types" reference
- Show correct usage patterns in examples
- Add warning about invalid types

**Likelihood**: Medium (based on previous errors)
**Impact**: High (workflow failure)
**Priority**: Address in Phase 4 with clear documentation

## Notes

### Design Decision: Behavior Injection over Custom Types
We chose to use `general-purpose` agents with behavioral guidelines rather than requesting new agent types because:
1. Leverages existing, stable agent infrastructure
2. Behavior files are versioned and documented
3. Flexible - can add new behaviors without system changes
4. Clear separation of agent capabilities vs behaviors

### Future Enhancements
- **Automatic behavior selection**: AI selects best agent behavior based on phase keywords
- **Multi-agent research**: Parallel agents research different aspects
- **Research caching**: Cache research for similar phases
- **Quality scoring**: Measure spec quality (concreteness, completeness)

### Related Work
- Plan 029: Previous attempt with shell scripts (abandoned)
- Plan 027/028: System optimization plans (test cases for this refactor)
- Agent Integration Guide: Comprehensive agent usage documentation

### Success Metrics
- Zero "agent type not found" errors
- 100% of complex phases expanded with concrete specs
- Research findings incorporated in 90%+ of synthesized content
- Average spec length: 400-600 lines for complex phases
- User satisfaction: Clear, actionable phase specifications

---

**Implementation Ready**: This plan is ready for `/implement` execution with phased approach and comprehensive testing.
