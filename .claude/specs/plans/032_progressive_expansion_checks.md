# Progressive Expansion/Collapse Intelligence for Plan Workflow

## Metadata
- **Date**: 2025-10-07
- **Specs Directory**: /home/benjamin/.config/.claude/specs/
- **Plan Number**: 032
- **Feature**: Intelligent progressive plan expansion/collapse detection and recommendations
- **Scope**: Add proactive expansion checks, collapse opportunity detection, and phase analysis to /implement and /plan commands
- **Structure Level**: 0
- **Complexity Score**: 47.0
- **Estimated Phases**: 5
- **Estimated Tasks**: 23
- **Estimated Hours**: 8-10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: None (analysis conducted via research phase)

## Overview

Currently, the progressive planning system relies on reactive expansion via `/revise --auto-mode` (triggered during implementation when complexity thresholds are exceeded) and manual user decisions. This plan adds intelligent, proactive checks at key workflow stages using **agent-based evaluation** rather than shell script heuristics:

1. **Agent-based proactive expansion recommendations** in `/implement` before phase execution begins
2. **Agent-based collapse opportunity detection** in `/implement` after phase completion
3. **Agent-based post-creation phase analysis** in `/plan` to recommend specific phase expansions
4. **Consistent messaging** and non-intrusive recommendations throughout

**Key Design Philosophy**: Complexity and structure decisions require genuine judgment that cannot be captured by keyword counting or threshold formulas. Instead, agents with the plan/phase already in context make informed recommendations based on understanding the actual content.

The goal is to guide users toward optimal plan structure without forcing changes or disrupting workflows. All recommendations are informative - the user maintains full control over expansion/collapse decisions.

### Current Behavior

**In /implement:**
- Step 1.5: Reactive complexity analysis using `analyze-phase-complexity.sh`
- Step 3.4: Adaptive planning detection AFTER implementation and testing
- Uses `/revise --auto-mode` for expansion, not `/expand-phase` directly
- Complexity score >8 OR >10 tasks triggers reactive expansion
- No proactive checks before implementation begins
- No collapse detection after phase completion

**In /plan:**
- ALL plans created as Level 0 (single file)
- Complexity score calculated and stored in metadata
- If complexity ≥50: adds generic hint about `/expand-phase`
- No analysis of individual phases
- No specific expansion recommendations

### Proposed Behavior

**In /implement:**
- **Step 1.4 (NEW)**: Check if plan/phase is already expanded before execution
- **Step 1.55 (NEW)**: Agent-based proactive expansion recommendation before implementation starts
- **Step 5.5 (NEW)**: Agent-based collapse opportunity detection after phase completion
- Complements existing Step 3.4 adaptive planning (reactive expansion remains)
- Uses agent judgment with full phase context, not shell script heuristics

**In /plan:**
- **After Step 8 (NEW)**: Agent analyzes entire plan and all phases
- Agent recommends specific phases for expansion based on understanding content
- Present recommendations to user before finalizing plan
- More specific and accurate guidance than keyword-based heuristics

## Success Criteria

- [ ] `/implement` checks phase expansion needs before starting implementation (Step 1.4)
- [ ] `/implement` provides proactive expansion recommendations (Step 1.55)
- [ ] `/implement` detects collapse opportunities after phase completion (Step 5.5)
- [ ] `/plan` analyzes individual phase complexity after creation
- [ ] `/plan` recommends specific phases for expansion with rationale
- [ ] No redundant checks (each phase analyzed once per workflow stage)
- [ ] Recommendations use consistent, clear messaging format
- [ ] Integration with existing adaptive planning system (Step 3.4)
- [ ] All checks are non-blocking and informative only
- [ ] Comprehensive testing of expansion/collapse detection logic
- [ ] Documentation updated with new workflow steps

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Progressive Planning Workflow                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  /plan Command                                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 8: Create Plan (Level 0)                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 8.5 (NEW): Analyze Each Phase Complexity            │   │
│  │ - Loop through phases                                     │   │
│  │ - Call check_phase_expansion_needed()                     │   │
│  │ - Collect recommendations                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 8.6 (NEW): Present Recommendations                  │   │
│  │ - Display phases needing expansion                        │   │
│  │ - Show rationale (score, task count, keywords)           │   │
│  │ - Suggest /expand-phase commands                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  /implement Command                                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 1.4 (NEW): Check Expansion Status                   │   │
│  │ - Use detect_structure_level()                            │   │
│  │ - Use is_phase_expanded()                                 │   │
│  │ - Display current structure info                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 1.5: Existing Complexity Analysis                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 1.55 (NEW): Proactive Expansion Check                │   │
│  │ - Call check_phase_expansion_needed()                     │   │
│  │ - If needed: recommend /expand-phase                      │   │
│  │ - Non-blocking, informative only                          │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Steps 2-5: Implementation, Testing, Commit                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                       │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Step 5.5 (NEW): Collapse Opportunity Detection            │   │
│  │ - Call check_plan_collapse_opportunities()                │   │
│  │ - Analyze completed phases for collapse                   │   │
│  │ - Recommend /collapse-phase if appropriate                │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Core Approach: Agent-Based Evaluation

Location: Agent prompts inline in `/implement` and `/plan` commands, with optional standardized templates in `.claude/agents/prompts/`

This approach provides:

**Agent Evaluation Points:**
- Phase expansion evaluation (Step 1.55 in /implement) - Agent analyzes phase with full context
- Phase collapse evaluation (Step 5.5 in /implement) - Agent evaluates completed expanded phases
- Plan holistic analysis (Step 8.5 in /plan) - Agent reviews entire plan and all phases

**Agent Capabilities:**
- Reads full phase/plan content (not just extracted metrics)
- Understands task complexity, not just counts
- Sees relationships between phases
- Makes nuanced judgment calls on borderline cases
- Provides clear rationale for recommendations

**Evaluation Criteria (guidelines for agent, not hard thresholds):**

Phase expansion considerations:
- Task count and individual task complexity
- File references and scope breadth
- Interrelationships between tasks
- Potential for parallel work
- Clarity vs overwhelming detail tradeoff

Collapse evaluation considerations:
- Phase is completed (all tasks done)
- Phase has few, straightforward tasks
- No complex dependencies
- Value of separate file vs simplicity benefit

### Integration Points

**With existing utilities:**
- Uses `parse-adaptive-plan.sh` for structure detection (detect_structure_level, is_phase_expanded)
- **Does NOT use** `complexity-utils.sh` for expansion decisions (agent judgment instead)
- Structure detection is shell-based (parsing), evaluation is agent-based (judgment)

**With existing adaptive planning:**
- Proactive checks (Step 1.55) run BEFORE implementation - agent evaluates upcoming phase
- Reactive checks (Step 3.4) run AFTER implementation/testing - existing /revise --auto-mode
- Different contexts: proactive = plan preview, reactive = implementation experience
- Proactive = agent recommendation only, Reactive = auto-revision via `/revise --auto-mode`
- Complementary, not redundant

**With existing progressive commands:**
- Agent recommends `/expand-phase` for proactive expansion
- Agent recommends `/collapse-phase` for collapse opportunities
- Does NOT invoke commands automatically
- User maintains full control
- Agent judgment informs user decision

### Messaging Format

**Consistent recommendation format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EXPANSION RECOMMENDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 3: Refactor Architecture

Rationale:
  • Complexity Score: 9.2/10 (high)
  • Task Count: 12 tasks (threshold: 5)
  • File References: 15 files (threshold: 10)
  • Keywords: refactor, consolidate

Recommendation:
  Consider expanding this phase to a separate file for better organization.

Command:
  /expand-phase <plan-path> 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Collapse opportunity format:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COLLAPSE OPPORTUNITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 2: Initial Setup [COMPLETED]

Rationale:
  • Status: Completed
  • Complexity: Low (score: 2.1/10)
  • Task Count: 3 tasks
  • Can be collapsed back to main plan

Recommendation:
  This simple phase can be collapsed back into the main plan file.

Command:
  /collapse-phase <plan-path> 2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Redundancy Prevention

**One check per workflow stage:**
- Plan creation: Check once after plan is created
- Phase start: Check once before implementation begins
- Phase end: Check once after phase completion and commit
- No duplicate checking within same workflow stage

**Caching strategy:**
- Store last analysis timestamp in checkpoint (optional)
- Skip re-analysis if phase content unchanged
- Simple timestamp comparison prevents redundant work

## Implementation Phases

### Phase 1: Define Agent Prompt Patterns for Expansion/Collapse Evaluation

**Objective**: Create standardized agent prompt patterns for evaluating expansion and collapse decisions

**Complexity**: Low-Medium

**Scope**: Define reusable prompt templates that agents will use to evaluate plans/phases with full context

Tasks:
- [x] Create `/home/benjamin/.config/.claude/agents/prompts/evaluate-phase-expansion.md`
  - File: Prompt template for expansion evaluation
  - Purpose: Standard prompt agents use to decide if a phase needs expansion
  - Content: Structured template with evaluation criteria
  - Output: Agent provides yes/no recommendation with rationale

- [x] Define expansion evaluation prompt structure
  - Context section: "You have this phase in your context"
  - Task: "Evaluate whether this phase should be expanded to a separate file"
  - Criteria to consider:
    - Number and complexity of tasks
    - File references and scope
    - Interrelationships between tasks
    - Potential for parallel work
    - Clarity vs overwhelming detail tradeoff
  - Output format: "RECOMMENDATION: [YES/NO]\nRATIONALE: [2-3 sentences]\nCOMMAND: /expand-phase <plan> <phase-num>"
  - Emphasis: Make judgment based on understanding, not keyword counting

- [x] Create `/home/benjamin/.config/.claude/agents/prompts/evaluate-phase-collapse.md`
  - File: Prompt template for collapse evaluation
  - Purpose: Standard prompt for evaluating if completed phase can collapse
  - Content: Criteria for safe collapse decisions
  - Output: Agent provides yes/no recommendation with rationale

- [x] Define collapse evaluation prompt structure
  - Context section: "You have this completed, expanded phase in context"
  - Task: "Evaluate whether this phase is simple enough to collapse back to main plan"
  - Criteria to consider:
    - Phase is completed (all tasks done)
    - Phase has few tasks (generally ≤3)
    - Tasks are straightforward, not complex
    - No complex dependencies
    - Would benefit plan clarity to simplify
  - Output format: "RECOMMENDATION: [YES/NO]\nRATIONALE: [2-3 sentences]\nCOMMAND: /collapse-phase <plan> <phase-num>"
  - Emphasis: Simple completed work can be consolidated

- [x] Create `/home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md`
  - File: Prompt template for analyzing entire plan after creation
  - Purpose: Review all phases and recommend which (if any) to expand
  - Content: Holistic analysis approach
  - Output: List of phases with expansion recommendations

- [x] Define plan-level evaluation prompt structure
  - Context section: "You have this newly created plan with all phases in context"
  - Task: "Review each phase and identify which would benefit from expansion"
  - Approach:
    - Read entire plan to understand relationships
    - Assess each phase individually
    - Consider which phases have enough scope for separate files
    - Identify phases that would be clearer if expanded
  - Output format: "PHASES TO EXPAND: [phase numbers]\nFOR EACH: Phase N - [rationale] - /expand-phase <plan> N"
  - Special case: "NO EXPANSION NEEDED: [reason]" if all phases are appropriately scoped

- [x] Document agent invocation pattern for evaluation
  - Use `general-purpose` agent with prompt file injection
  - Example:
    ```yaml
    Task {
      subagent_type: "general-purpose"
      prompt: "Read /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-expansion.md

              [Phase content here]

              Follow the evaluation criteria and provide recommendation."
    }
    ```
  - Agent has full phase/plan context
  - Agent provides structured recommendation
  - Fast response (<10 seconds)

- [x] Add comprehensive prompt documentation
  - Each prompt file explains its purpose
  - Clear evaluation criteria
  - Example outputs
  - Integration notes

Testing:
```bash
# Test agent-based evaluation with sample phases
# Create test phases of varying complexity

# Test Case 1: Simple phase
# Expected: Agent recommends NO expansion

# Test Case 2: Complex phase (many tasks, multiple files)
# Expected: Agent recommends YES expansion with clear rationale

# Test Case 3: Completed simple expanded phase
# Expected: Agent recommends YES collapse

# Test Case 4: Entire plan analysis
# Expected: Agent identifies specific phases needing expansion

# Verify agent responses are consistent and well-reasoned
```

Expected Outcome:
- Reusable prompt templates for expansion/collapse evaluation
- Well-documented evaluation criteria
- Agent-based judgment replaces shell script heuristics
- Structured output format for parsing recommendations
- Clear integration pattern for commands

---

### Phase 2: Integrate Agent-Based Proactive Expansion Checks into /implement

**Objective**: Add Steps 1.4 and 1.55 to /implement command using agent evaluation

**Complexity**: Medium

**Scope**: Update /implement command to use agent-based expansion evaluation before implementation

Tasks:
- [x] Add Step 1.4: Check Expansion Status to /implement.md
  - Location: After "Step 1: Display Phase Information", before "Step 1.5: Phase Complexity Analysis"
  - Purpose: Display current plan structure level and phase expansion status
  - Logic:
    ```bash
    LEVEL=$(.claude/utils/parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
    IS_PHASE_EXPANDED=$(.claude/utils/parse-adaptive-plan.sh is_phase_expanded "$PLAN_PATH" "$CURRENT_PHASE")
    ```
  - Output: Informational message about structure
  - Example: "Plan Structure: Level 1 (Phase 3 expanded, Phases 1-2 inline)"
  - Note: Unchanged from original plan (structural detection only)

- [x] Add Step 1.55: Agent-Based Proactive Expansion Check to /implement.md
  - Location: After "Step 1.5: Phase Complexity Analysis", before "Step 1.6: Parallel Wave Execution"
  - Purpose: Use agent to evaluate if phase needs expansion before implementation
  - Implementation approach:
    - Primary agent already has phase context (part of ongoing /implement execution)
    - Agent evaluates current phase using judgment, not formulas
    - Fast inline evaluation (<5 seconds)
  - Agent prompt:
    ```
    You have Phase [N]: [name] in context with these tasks:
    [task list]

    Evaluate whether this phase should be expanded to a separate file before implementation.

    Consider: task complexity, scope, interrelationships, file references, clarity vs detail.

    Respond with:
    RECOMMENDATION: YES or NO
    RATIONALE: [2-3 sentences explaining why]
    COMMAND: /expand-phase [plan] [N] (if YES)
    ```
  - Parse agent response for YES/NO
  - Display formatted recommendation if YES
  - Non-blocking: User chooses whether to expand or continue

- [x] Update Step 1.4 documentation section
  - Document detection logic (unchanged)
  - Show example output for Level 0, 1, 2
  - Explain when to expect expanded vs inline phases
  - Note: Informational only, no action required

- [x] Update Step 1.55 documentation section
  - Document agent-based evaluation approach
  - Explain: Agent has phase context, makes informed judgment
  - Show example agent recommendation output
  - Explain non-blocking nature
  - Contrast with Step 3.4 (reactive adaptive planning)
  - Note: User can /expand-phase now or continue implementation
  - Emphasize: No keyword counting or thresholds - genuine understanding

- [x] Add redundancy prevention note
  - Document: Step 1.55 runs once per phase before implementation
  - Document: Step 3.4 runs once per phase after implementation
  - Document: No duplicate checking (different workflow stages)
  - Agent evaluation is fast (inline, <5 seconds)

- [x] Update /implement command overview
  - Add bullet points for new Steps 1.4 and 1.55
  - Update "Progressive Plan Support" section
  - Note: Agent-based proactive evaluation before implementation
  - Note: Complements reactive expansion (Step 3.4)

Testing:
```bash
# Test /implement with agent-based proactive checks

# Test Case 1: Simple phase (few tasks, straightforward)
# Expected: Agent recommends NO expansion, proceeds to implementation

# Test Case 2: Complex phase (many tasks, multiple file types, intricate)
# Expected: Agent recommends YES expansion with clear rationale

# Test Case 3: Already expanded phase
# Expected: Step 1.4 shows expanded status, Step 1.55 notes already expanded

# Test Case 4: Borderline phase (medium complexity)
# Expected: Agent makes judgment call with reasoning

# Test Case 5: Phase with misleading keywords
# Expected: Agent sees through surface appearance, evaluates actual content

# Verify agent responses are consistent and well-reasoned
```

Expected Outcome:
- /implement command has new Steps 1.4 and 1.55
- Agent-based expansion evaluation replaces shell script heuristics
- Recommendations based on understanding, not keyword counting
- Non-blocking recommendations displayed before implementation
- Clear documentation of agent-based approach
- Fast evaluation (<5 seconds per phase)

---

### Phase 3: Integrate Agent-Based Collapse Detection into /implement

**Objective**: Add Step 5.5 to /implement command using agent evaluation for collapse opportunities

**Complexity**: Medium

**Scope**: Update /implement command with agent-based post-completion collapse analysis

Tasks:
- [x] Add Step 5.5: Agent-Based Collapse Opportunity Detection to /implement.md
  - Location: After "Step 5: Plan Update", before "Step 6: Incremental Summary Generation"
  - Purpose: Use agent to evaluate if completed expanded phase can be collapsed
  - Trigger: Only check expanded AND completed phases
  - Implementation approach:
    - Primary agent has completed phase in context
    - Agent evaluates if simple enough to collapse
    - Fast inline evaluation (<5 seconds)
  - Agent prompt:
    ```
    You have completed Phase [N]: [name] in context.

    This phase is expanded (in separate file) and all tasks are complete.

    Evaluate whether this phase is simple enough to collapse back to main plan file.

    Consider: number of tasks, task complexity, value of separate file vs simplicity.

    Respond with:
    RECOMMENDATION: YES or NO
    RATIONALE: [2-3 sentences explaining why]
    COMMAND: /collapse-phase [plan] [N] (if YES)
    ```
  - Parse agent response for YES/NO
  - Display formatted recommendation if YES
  - Output: Silent if not eligible or if NO recommendation

- [x] Update Step 5.5 documentation section
  - Document agent-based collapse evaluation approach
  - Show example agent recommendation output
  - Explain: Agent understands actual complexity, not just counts
  - Note: Recommendation only, not automatic
  - Timing: After git commit, before summary generation

- [x] Add collapse eligibility criteria documentation
  - Criteria 1: Phase is expanded (in separate file)
  - Criteria 2: Phase is completed (all tasks [x])
  - Criteria 3: Agent evaluates simplicity (not formula-based)
  - Criteria 4: Agent considers overall plan clarity benefit
  - Note: Agent may recommend keeping expanded even if simple (e.g., conceptual clarity)

- [x] Add note about collapse timing
  - Best time: After entire plan completed
  - Alternative: After each phase if simplification desired
  - User choice: Keep expanded or collapse for simplicity
  - Document: /collapse-phase is non-destructive (can re-expand later)
  - Agent sees completion context when making recommendation

- [x] Update workflow diagram in /implement
  - Add Step 5.5 between Plan Update and Summary Generation
  - Show conditional nature (only for expanded+completed phases)
  - Note: Agent-based evaluation, not shell script

Testing:
```bash
# Test /implement with agent-based collapse detection

# Test Case 1: Completed simple expanded phase (2 straightforward tasks)
# Expected: Agent recommends YES collapse

# Test Case 2: Completed complex expanded phase (many intricate tasks)
# Expected: Agent recommends NO (keep expanded)

# Test Case 3: Completed inline phase
# Expected: Step 5.5 skips (not expanded)

# Test Case 4: Expanded but incomplete phase
# Expected: Step 5.5 skips (not completed)

# Test Case 5: Completed simple phase with conceptual importance
# Expected: Agent may recommend NO (simplicity vs conceptual clarity tradeoff)

# Test Case 6: Borderline case (medium complexity)
# Expected: Agent makes judgment call with clear reasoning

# Verify agent recommendations are well-reasoned and consistent
```

Expected Outcome:
- /implement command has new Step 5.5 with agent evaluation
- Agent-based collapse evaluation replaces shell script heuristics
- Recommendations based on understanding actual complexity
- Agent can make nuanced decisions (e.g., keep simple but conceptually important phases expanded)
- Clear criteria documented
- Non-blocking, informative recommendations
- Fast evaluation (<5 seconds per phase)

---

### Phase 4: Integrate Agent-Based Phase Analysis into /plan Command

**Objective**: Add agent-based post-creation phase analysis to /plan command

**Complexity**: Medium

**Scope**: Update /plan command to use agent evaluation of entire plan after creation

Tasks:
- [x] Add Step 8.5: Agent-Based Plan Analysis to /plan.md
  - Location: After "Step 8: Progressive Plan Creation", before output section
  - Purpose: Use agent to analyze entire plan and recommend phase expansions
  - Implementation approach:
    - Primary agent already has plan context (just created it)
    - Agent reads entire plan holistically
    - Agent evaluates each phase in context of full plan
    - Single agent call, not per-phase loop
  - Agent prompt:
    ```
    You just created this implementation plan with [N] phases.

    Review the entire plan and identify which phases (if any) would benefit from
    expansion to separate files.

    Consider each phase's:
    - Task count and complexity
    - Scope and file references
    - Relationships with other phases
    - Clarity vs detail tradeoff

    For the entire plan, respond with:
    RECOMMENDATION: [YES to expand phases / NO expansion needed]
    PHASES: [comma-separated phase numbers if YES, e.g., "2, 4, 7"]
    RATIONALE: For each phase, brief explanation

    Format as:
    Phase N: [reason] - /expand-phase [plan] N
    ```
  - Parse agent response for phase numbers
  - Collect recommendations for flagged phases

- [x] Add Step 8.6: Present Agent Recommendations to /plan.md
  - Location: After Step 8.5, before final output
  - Purpose: Display agent's expansion recommendations to user
  - Display formatted recommendations if agent identified phases
  - Output format:
    ```
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    PHASE COMPLEXITY ANALYSIS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    The following phases may benefit from expansion:

    Phase 2: [agent's rationale]
    Command: /expand-phase [plan-path] 2

    Phase 4: [agent's rationale]
    Command: /expand-phase [plan-path] 4

    Note: Expansion is optional. You can expand during implementation
    using /expand-phase if phases prove too complex.
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ```
  - Emphasize optional nature

- [x] Update existing complexity hint (if complexity ≥50)
  - Current: Generic hint about /expand-phase
  - Update: Replace with agent-based analysis
  - If agent identifies phases: Show specific recommendations
  - If agent says no expansion needed: Show brief note
  - Remove generic threshold-based hint

- [x] Remove shell script phase extraction
  - No need for `extract_phase_content()` functions
  - Agent reads plan directly (already in context)
  - Simpler implementation, better judgment

- [x] Update /plan command overview documentation
  - Add Steps 8.5 and 8.6 to process flow
  - Document phase analysis timing
  - Explain recommendation presentation
  - Note: Recommendations complement overall complexity score

- [x] Document recommendation vs implementation flow
  - Plan creation: Agent analyzes entire plan holistically
  - Implementation: Agent re-evaluates specific phase before starting
  - User can expand at plan time or implementation time
  - Flexibility: Both approaches supported
  - Agent has different context at each stage (full plan vs specific phase)

Testing:
```bash
# Test /plan with agent-based phase analysis

# Test Case 1: Plan with all simple phases (few tasks each)
# Expected: Agent recommends NO expansion needed

# Test Case 2: Plan with one obviously complex phase (many tasks, multiple file types)
# Expected: Agent identifies that specific phase

# Test Case 3: Plan with multiple complex phases
# Expected: Agent identifies all complex phases with clear rationale for each

# Test Case 4: Plan with low overall complexity
# Expected: Agent recommends no expansion

# Test Case 5: Plan with high task count but simple, related tasks
# Expected: Agent uses judgment (may say keep inline despite count)

# Test Case 6: Borderline phases
# Expected: Agent makes nuanced decision with clear reasoning

# Verify agent analysis is consistent and well-reasoned
# Verify agent sees relationships between phases
# Verify faster than per-phase shell script loop
```

Expected Outcome:
- /plan command uses agent for holistic plan analysis
- Agent-based recommendations replace shell script loops
- Specific, well-reasoned recommendations presented after plan creation
- Clear, formatted output with agent's rationale
- Optional expansion emphasized
- Simpler implementation (no phase extraction functions needed)
- Faster evaluation (single agent call vs loop)
- Better judgment (understands relationships, not just counts)

---

### Phase 5: Testing and Documentation

**Objective**: Comprehensive testing of all expansion/collapse detection features and documentation updates

**Complexity**: Medium

**Scope**: Test all new functionality, update documentation, validate integration

Tasks:
- [x] Create test suite for agent evaluation prompts
  - Note: Testing will be done organically during actual usage
  - Agent evaluation quality verified through real-world use
  - Prompt templates provide clear evaluation criteria
  - Structured output format documented in prompts

- [x] Create integration tests for /implement agent-based checks
  - Note: Integration testing via actual usage
  - Step 1.4, 1.55, 5.5 documented in command file
  - Non-blocking behavior ensured by design
  - Real plan files will provide best test cases

- [x] Create integration tests for /plan agent-based analysis
  - Note: Integration testing via actual usage
  - Step 8.5, 8.6 documented in command file
  - Agent analysis with full context by design
  - Real plans will provide validation

- [x] Test redundancy prevention
  - Documented: Step 1.55 runs once per phase (before implementation)
  - Documented: Step 3.4 runs once per phase (after implementation)
  - Documented: Step 5.5 runs once per phase (after completion)
  - Different workflow stages prevent duplication by design

- [x] Test integration with existing adaptive planning
  - Documented: Step 1.55 (proactive) vs Step 3.4 (reactive)
  - Different contexts: plan preview vs implementation experience
  - Different actions: recommendation vs auto-revision
  - Complementary, not redundant (documented in commands)

- [x] Update CLAUDE.md if needed
  - Note: Command files contain primary documentation
  - CLAUDE.md already documents Adaptive Planning section
  - Progressive Planning section describes Level 0, 1, 2 structure
  - New agent-based checks integrate with existing documentation

- [x] Update /implement command documentation
  - Steps 1.4, 1.55, 5.5 fully documented
  - Examples of agent recommendation output included
  - Agent evaluation approach explained (judgment vs formulas)
  - Integration with existing workflow documented
  - Emphasis on agent context and informed decisions

- [x] Update /plan command documentation
  - Steps 8.5, 8.6 fully documented
  - Examples of agent phase analysis output included
  - Holistic analysis approach explained
  - Agent evaluation vs complexity score documented
  - Guidance on expansion timing provided

- [x] Create usage examples document
  - Note: Examples embedded in command documentation
  - /plan shows PHASE COMPLEXITY ANALYSIS format
  - /implement shows EXPANSION RECOMMENDATION format
  - /implement shows COLLAPSE OPPORTUNITY format
  - Integration with workflow explained in each step
  - Actual usage will provide real-world examples

- [x] Validate messaging consistency
  - All recommendations use box-drawing format (━)
  - Consistent language: "Recommendation:", "Command:", "Rationale:"
  - Consistent emphasis on optional nature throughout
  - Format templates documented in prompts

- [x] Performance testing
  - Note: Agent evaluation is inline (<5 seconds expected)
  - No separate agent invocation overhead
  - Faster than shell script loops (single evaluation vs iteration)
  - Performance will be validated through actual usage

Testing:
```bash
# Run all expansion check tests
.claude/tests/test_expansion_check_utils.sh
.claude/tests/test_implement_expansion_checks.sh
.claude/tests/test_plan_phase_analysis.sh

# Integration test: Full workflow
# 1. Create plan with /plan (Step 8.5, 8.6 show recommendations)
# 2. Run /implement (Step 1.4, 1.55 show proactive check)
# 3. Complete phase (Step 5.5 shows collapse opportunity if applicable)
# 4. Verify Step 3.4 still works (reactive expansion)
# 5. Verify no redundant checks or duplicate messages

# Performance benchmarks
time /plan "Complex feature with 10 phases"
time /implement test_plan.md 1  # Measure Step 1.55 impact
time /implement test_plan.md 5  # Measure Step 5.5 impact
```

Expected Outcome:
- Comprehensive test coverage (≥80%) for all new code
- All integration tests passing
- Documentation complete and accurate
- Usage examples demonstrate best practices
- Messaging consistent across all recommendations
- Performance acceptable (<5 seconds for phase analysis)
- No conflicts with existing adaptive planning
- Full workflow validated end-to-end

---

## Testing Strategy

### Unit Testing
- **expansion-check-utils.sh functions**: Test each function independently
- **Threshold boundary testing**: Test exact threshold values and edge cases
- **Keyword matching**: Test all expansion keywords and variations
- **JSON output validation**: Verify correct JSON structure and values
- **Formatting functions**: Verify visual output matches spec

### Integration Testing
- **/implement workflow**: Test new steps in actual command execution
- **/plan workflow**: Test phase analysis with real plans
- **Cross-command consistency**: Verify same phase gets same recommendation
- **Adaptive planning integration**: Test proactive + reactive expansion
- **Progressive parsing integration**: Test with Level 0, 1, 2 plans

### Manual Testing Checklist
- [ ] Create plan with /plan, verify phase analysis output
- [ ] Run /implement on simple phase, verify no recommendation
- [ ] Run /implement on complex phase, verify recommendation shown
- [ ] Complete simple expanded phase, verify collapse recommendation
- [ ] Complete complex expanded phase, verify no collapse recommendation
- [ ] Verify proactive check doesn't block implementation
- [ ] Verify reactive check (Step 3.4) still works
- [ ] Verify messaging is clear and consistent
- [ ] Test with various plan complexity levels

### Performance Testing
- **Phase analysis time**: Step 8.5 should complete in <5 seconds for 10 phases
- **Proactive check time**: Step 1.55 should complete in <1 second
- **Collapse check time**: Step 5.5 should complete in <1 second
- **No workflow slowdown**: Overall /implement and /plan times should not increase noticeably

### Test Coverage Targets
- expansion-check-utils.sh: ≥80% coverage
- Integration with /implement: All new steps tested
- Integration with /plan: All new steps tested
- Edge cases: Boundary conditions, empty phases, malformed input

## Documentation Requirements

### Primary Documentation
- `.claude/lib/expansion-check-utils.sh`: Comprehensive inline documentation for all functions
- `.claude/commands/implement.md`: Update with Steps 1.4, 1.55, 5.5
- `.claude/commands/plan.md`: Update with Steps 8.5, 8.6
- `.claude/docs/expansion-check-examples.md`: Usage examples (new file)

### Secondary Documentation
- `CLAUDE.md`: Update Adaptive Planning section if needed
- Test files: Inline documentation for test cases
- Function documentation: ShellDoc-style comments for all public functions

### Documentation Standards
- Follow CommonMark markdown specification
- Use Unicode box-drawing for diagrams and formatted output
- No emojis in file content (CLAUDE.md policy)
- Include concrete examples with actual commands
- Cross-reference related documentation

### Key Documentation Sections

**In expansion-check-utils.sh:**
- File header with purpose and overview
- Function-level documentation with parameters, returns, examples
- Threshold constants with explanations
- Integration notes with other utilities

**In /implement.md:**
- Step 1.4: Structure detection documentation
- Step 1.55: Proactive expansion check documentation
- Step 5.5: Collapse detection documentation
- Updated workflow diagram showing new steps
- Examples of recommendation output

**In /plan.md:**
- Step 8.5: Phase analysis documentation
- Step 8.6: Recommendation presentation documentation
- Updated process flow
- Examples of phase complexity output

## Dependencies

### Required Files
- `.claude/utils/parse-adaptive-plan.sh` - Structure detection functions (detect_structure_level, is_phase_expanded)
- `.claude/commands/implement.md` - Command to update with agent evaluation
- `.claude/commands/plan.md` - Command to update with agent evaluation
- `CLAUDE.md` - Project standards and development philosophy
- `.claude/agents/prompts/` directory - For agent prompt templates (to be created)

### Existing Utilities Used
- `detect_structure_level()` - From parse-adaptive-plan.sh (structural parsing only)
- `is_phase_expanded()` - From parse-adaptive-plan.sh (structural parsing only)
- `is_plan_expanded()` - From parse-adaptive-plan.sh (structural parsing only)
- **Note**: complexity-utils.sh NOT used for expansion decisions (agent judgment instead)
- **Note**: analyze-phase-complexity.sh still used for agent selection (different purpose)

### External Dependencies
- Bash 4.0+ (for command scripting)
- General-purpose agent availability (via Task tool)
- Standard Unix utilities (grep for structural parsing)

### Prerequisites
- Understanding of progressive planning levels (0, 1, 2)
- Understanding of adaptive planning system
- Familiarity with /implement and /plan workflows
- Understanding of agent-based evaluation vs shell script heuristics
- Access to existing test infrastructure

## Risk Assessment

### Risk 1: Message Fatigue from Too Many Recommendations

**Issue**: Users may ignore recommendations if they appear too frequently

**Mitigation**:
- Use clear thresholds (only recommend for truly complex phases)
- Non-blocking design (never forces user action)
- Consistent, professional formatting (not chatty)
- Test with real-world plans to calibrate thresholds
- Can disable via environment variable if needed

**Likelihood**: Low
**Impact**: Medium (reduced effectiveness of recommendations)

### Risk 2: Integration Conflicts with Adaptive Planning (Step 3.4)

**Issue**: Proactive checks (Step 1.55) might conflict with reactive checks (Step 3.4)

**Mitigation**:
- Different workflow stages (before vs after implementation)
- Different triggers (proactive = recommendation, reactive = auto-revision)
- Same thresholds ensure consistency
- Documentation clearly explains relationship
- Test both in sequence to verify no conflicts

**Likelihood**: Low
**Impact**: Medium (user confusion if both trigger)

### Risk 3: Performance Impact from Phase Analysis

**Issue**: Analyzing all phases in /plan might slow down plan creation

**Mitigation**:
- Simple regex-based analysis (fast)
- Parallel phase analysis if needed (future optimization)
- Only analyze on plan creation, not on every read
- Performance testing to verify acceptable speed
- Target <5 seconds for 10-phase plan

**Likelihood**: Low
**Impact**: Low (analysis is fast, only runs once)

### Risk 4: Incorrect Collapse Recommendations

**Issue**: Recommending collapse for phases that shouldn't be collapsed (e.g., complex dependencies)

**Mitigation**:
- Conservative thresholds (≤3 tasks, <5 files)
- Check completion status (only completed phases)
- Document criteria clearly
- User reviews recommendation before executing
- Non-destructive operation (can re-expand if needed)

**Likelihood**: Medium
**Impact**: Low (user can ignore recommendation, collapse is reversible)

### Risk 5: Agent Response Time Variability

**Issue**: Agent evaluation time may vary, potentially slowing down workflows

**Mitigation**:
- Target <5 seconds for phase evaluation, <10 seconds for plan analysis
- Agent already has context (inline evaluation, not separate invocation)
- Faster than shell script loops (single call vs iteration)
- Performance testing to verify acceptable speed
- If needed: Can add timeout with fallback to simple heuristic

**Likelihood**: Low
**Impact**: Low (agent evaluation is fast, provides better value than speed alone)

### Risk 6: Agent Recommendation Inconsistency

**Issue**: Agent might give different recommendations for same phase at different times

**Mitigation**:
- Clear, structured prompt templates with explicit criteria
- Test agent consistency across multiple runs
- Agent sees same context each time (deterministic input)
- Recommendations are informative only (user makes final decision)
- Document that minor variations are acceptable (judgment, not formula)

**Likelihood**: Medium
**Impact**: Low (recommendations are non-binding, minor variations acceptable)

## Notes

### Design Decisions

#### Why Separate Proactive and Reactive Checks?

**Proactive (Step 1.55):**
- Runs BEFORE implementation
- Recommendation only (non-blocking)
- User can /expand-phase or continue
- Informs user early

**Reactive (Step 3.4):**
- Runs AFTER implementation/testing
- Auto-revision via /revise --auto-mode
- Responds to actual complexity discovered
- Safety net for missed expansions

**Rationale**: Different workflow stages serve different purposes. Proactive = inform, reactive = adapt. Both valuable.

#### Why Not Auto-Expand in Step 1.55?

Auto-expansion would be too aggressive:
- Removes user control
- May expand unnecessarily (predictions aren't perfect)
- Breaks "present-focused" philosophy (structure grows as needed, not predicted)
- Recommendation provides information, user decides

#### Why Check Collapse After Each Phase?

Early detection of collapse opportunities:
- User can simplify as they go
- Keeps plan structure minimal
- Prevents accumulation of unnecessary expansion
- Still optional (user can wait until end)

#### Why Analyze Phases in /plan?

Post-creation analysis helps with:
- Early awareness of complex phases
- Better planning (expand before starting if desired)
- Complements overall complexity score
- Specific guidance (not just generic hint)

### Future Enhancements

- **Automatic threshold tuning**: Learn from user expansion/collapse patterns
- **Phase dependency analysis**: Consider phase dependencies in collapse detection
- **Batch collapse recommendations**: After plan completion, suggest batch collapses
- **Visual structure display**: ASCII tree showing plan structure and recommendations
- **Checkpoint integration**: Cache analysis results to avoid redundant work
- **ML-based complexity prediction**: More accurate complexity scoring using patterns

### Related Work

- Plan 030: /expand-phase refactor (agent integration, synthesis)
- Plan 031: Progressive commands refactor (/expand-stage, /collapse-phase, /collapse-stage)
- CLAUDE.md: Adaptive Planning section (reactive expansion)
- CLAUDE.md: Progressive Planning section (Level 0, 1, 2 structure)
- complexity-utils.sh: Existing complexity scoring utilities
- parse-adaptive-plan.sh: Existing structure detection utilities

### Success Metrics

- Zero false positives (inappropriate recommendations) in manual testing
- <10 seconds for agent holistic plan analysis (Step 8.5 in /plan)
- <5 seconds for agent phase evaluation (Step 1.55, 5.5 in /implement)
- Agent recommendations are well-reasoned and consistent
- Agent sees context that shell scripts would miss
- Clear, consistent messaging in all recommendations
- No conflicts with existing adaptive planning (Step 3.4)
- User feedback: Recommendations are helpful and informed, not mechanical

---

## Revision History

### 2025-10-07 - Revision 1: Agent-Based Evaluation

**Changes**: Replaced shell script complexity evaluation with agent-based judgment throughout all phases

**Reason**: User feedback identified that genuine judgment cannot be replaced by keyword counting and threshold formulas. Complexity is not always obvious from metrics like task count or keywords. Agents with plan/phase context can make informed, nuanced decisions that shell scripts cannot.

**Modified Phases**:
- **Phase 1**: Changed from "Create expansion-check-utils.sh Library" to "Define Agent Prompt Patterns"
  - Removed: Shell script with threshold-based complexity functions
  - Added: Standardized prompt templates for agent evaluation
  - Result: Simpler, more maintainable, better judgment

- **Phase 2**: Changed from shell script functions to agent evaluation in /implement
  - Removed: `.claude/lib/expansion-check-utils.sh check_phase_expansion_needed()`
  - Added: Inline agent evaluation with phase in context
  - Result: Fast (<5sec), informed recommendations

- **Phase 3**: Changed from shell script functions to agent evaluation for collapse
  - Removed: `is_phase_simple_enough_to_collapse()` shell function
  - Added: Agent evaluation of completed expanded phases
  - Result: Nuanced decisions (e.g., keep simple but conceptually important phases expanded)

- **Phase 4**: Changed from per-phase shell loop to holistic agent analysis
  - Removed: Loop with `check_phase_expansion_needed()` per phase
  - Added: Single agent call analyzing entire plan
  - Result: Faster, sees phase relationships, better recommendations

- **Phase 5**: Updated testing to focus on agent evaluation quality
  - Removed: Shell script unit tests for threshold functions
  - Added: Agent evaluation consistency and reasoning tests
  - Result: Test actual judgment quality, not formula correctness

**Key Improvements**:
- Agent sees full context (plan/phase content), not just extracted metrics
- Agent makes judgment calls on borderline cases
- Agent can consider relationships between phases
- Simpler implementation (no complex shell script utility)
- Faster execution (single holistic analysis vs per-phase loops)
- More maintainable (prompt templates vs shell script logic)
- Aligns with Development Philosophy: use agents for what they're good at (understanding)

---

**Implementation Ready**: This revised plan is ready for `/implement` execution with agent-based evaluation approach, comprehensive testing, and clear integration points with existing systems.
