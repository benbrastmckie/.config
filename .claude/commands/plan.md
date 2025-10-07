---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch
argument-hint: <feature description> [report-path1] [report-path2] ...
description: Create a detailed implementation plan following project standards, optionally guided by research reports
command-type: primary
dependent-commands: list, update, revise
---

# Create Implementation Plan

I'll create a comprehensive implementation plan for the specified feature or task, following project-specific coding standards and incorporating insights from any provided research reports.

## Feature/Task and Reports
- **Feature**: First argument before any .md paths
- **Research Reports**: Any paths to specs/reports/*.md files in arguments

I'll parse the arguments to separate the feature description from any report paths.

## Process

### 1. Report Integration (if provided)
If research reports are provided, I'll:
- Read and analyze each report
- Extract key findings and recommendations
- Identify technical constraints and patterns
- Use insights to inform the plan structure
- Reference reports in the plan metadata

### 1.5. Update Report Implementation Status
**After creating the plan, update referenced reports:**

**For each research report provided:**
- Use Edit tool to update "## Implementation Status" section
- Change: `Status: Research Complete` → `Status: Planning In Progress`
- Update: `Plan: None yet` → `Plan: [link to specs/plans/NNN.md]`
- Update date field

**Example update:**
```markdown
## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/018_spec_file_updates.md](../plans/018_spec_file_updates.md)
- **Implementation**: Not started
- **Date**: 2025-10-03
```

**Edge Cases:**
- If report lacks "Implementation Status" section: Use Edit tool to append section before updating
- If report already has a plan link: Update existing (report can inform multiple plans)

### 2. Requirements Analysis and Complexity Evaluation
I'll analyze the feature requirements to determine:
- Core functionality needed
- Technical scope and boundaries
- Affected components and modules
- Dependencies and prerequisites
- Alignment with report recommendations (if applicable)

**Complexity Evaluation** (Progressive Planning):
- Use `.claude/lib/analyze-plan-requirements.sh` to estimate:
  - Task count
  - Phase count
  - Estimated hours
  - Dependency complexity
- Use `.claude/lib/calculate-plan-complexity.sh` for informational scoring only
- **All plans start as single files (Level 0)** regardless of complexity
- If complexity score ≥50: Show hint about using `/expand phase` during implementation
- Complexity score stored in metadata for future reference

### 3. Location Determination and Registration
I'll determine the specs directory location using this process:

**Step 1: Check Report Metadata (if reports provided)**
- If research reports are provided as arguments:
  - Read the first report file
  - Extract "Specs Directory" from metadata section
  - Use this same specs directory for the plan

**Step 2: Detect Project Directory (if no reports)**
- Analyze the feature and identify components to be modified
- Find the deepest directory that encompasses all relevant content
- This becomes the "project directory" for this plan

**Step 3: Check SPECS.md Registry**
- Read `.claude/SPECS.md` to see if this project is already registered
- Look for a section matching the project directory path

**Step 4: Use Registered or Auto-Detect**
- If found in SPECS.md: Use the registered specs directory
- If not found: Auto-detect best location (project-dir/specs/) and register it

**Step 5: Register/Update in SPECS.md**
- If new project: Create new section in SPECS.md
- Update "Last Updated" date and increment "Plans" count
- Use Edit tool to update SPECS.md

### 4. Plan Numbering
I'll assign the plan number by:
- Checking existing plans in the target `specs/plans/` directory
- Finding the highest numbered plan (e.g., `002_*.md`)
- Using the next sequential number (e.g., `003`)
- Starting with `001` if no numbered plans exist
- Format: `NNN_feature_name.md` with three-digit numbering

### 5. Standards Discovery
I'll identify project-specific standards by:
- Looking for `CLAUDE.md` in the project directory
- Checking for `GUIDELINES.md` or similar documentation
- Analyzing existing code patterns and conventions
- Identifying testing approaches and requirements

### 6. Plan Structure
The implementation plan will include:

#### Overview
- Feature description and objectives
- Success criteria and deliverables
- Risk assessment and mitigation strategies

#### Technical Design
- Architecture decisions
- Component interactions
- Data flow and state management
- API design (if applicable)

#### Implementation Phases
Each phase will include:
- Clear objectives and scope
- Specific tasks with checkboxes `- [ ]`
- Testing requirements
- Validation criteria
- Estimated complexity

#### Phase Format
```markdown
### Phase N: [Phase Name]
**Objective**: [What this phase accomplishes]
**Complexity**: [Low/Medium/High]

Tasks:
- [ ] Task description with file reference
- [ ] Another specific task
- [ ] Testing task

Testing:
- Test command or approach
- Expected outcomes
```

### 7. Standards Integration
Based on discovered standards, I'll ensure:
- Code style matches project conventions
- File organization follows existing patterns
- Testing approach aligns with project practices
- Documentation format is consistent
- Git commit message format is specified

### 8. Progressive Plan Creation

**All plans start as single files** (Structure Level 0):
- Path: `specs/plans/NNN_feature_name.md`
- Single file with all phases and tasks inline
- Feature name converted to lowercase with underscores
- Comprehensive yet actionable content
- Clear phase boundaries for `/implement` command compatibility
- Metadata includes Structure Level: 0 and Complexity Score

**Expansion happens during implementation**:
- Use `/expand phase <plan> <phase-num>` to extract complex phases to separate files (Level 0 → 1)
- Use `/expand stage <phase> <stage-num>` to extract complex stages to separate files (Level 1 → 2)
- Structure grows organically based on actual implementation needs, not predictions

### 8.5. Agent-Based Plan Phase Analysis

After creating the plan, I'll analyze the entire plan holistically to identify which phases (if any) would benefit from expansion to separate files.

**Analysis Approach:**

The primary agent (executing `/plan`) has just created the plan and has all phases in context. Rather than using a generic complexity threshold, I'll review the entire plan and make informed recommendations about which specific phases might benefit from expansion.

**Evaluation Criteria:**

I'll consider for each phase:
- **Task count and complexity**: Not just numbers, but actual complexity of work
- **Scope and breadth**: Files, modules, subsystems touched
- **Interrelationships**: Dependencies and connections between phases
- **Phase relationships**: How phases build on each other
- **Natural breakpoints**: Where expansion creates better conceptual boundaries

**Evaluation Process:**

```
Read /home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md

You just created this implementation plan with [N] phases.

[Full plan content]

Follow the holistic analysis approach and identify which phases (if any)
would benefit from expansion to separate files.

Provide your recommendation in the structured format.
```

**If Expansion Recommended:**

Display formatted analysis:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The following phases may benefit from expansion:

Phase [N]: [Phase Name]
Rationale: [Agent's reasoning based on understanding the phase]
Command: /expand phase <plan-path> [N]

Phase [M]: [Phase Name]
Rationale: [Agent's reasoning based on understanding the phase]
Command: /expand phase <plan-path> [M]

Note: Expansion is optional. You can expand now before starting
implementation, or expand during implementation using /expand phase
if phases prove too complex.

Overall Complexity Score: [X] (stored in plan metadata)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If No Expansion Recommended:**

Display brief note:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE COMPLEXITY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan structure: All phases are appropriately scoped for inline format.

[Agent's brief rationale - e.g., "All phases have 3-5 straightforward
tasks that work well together in the single-file format."]

Overall Complexity Score: [X] (stored in plan metadata)

Note: Phases can be expanded during implementation if needed using
/expand phase <plan-path> <phase-num>.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Analysis Benefits:**

- **Specific recommendations**: Not just "plan is complex," but "Phase 3 and Phase 5 need expansion"
- **Clear rationale**: Agent explains why each phase would benefit
- **Holistic view**: Agent sees how phases relate, not just individual metrics
- **Better judgment**: Understands actual complexity, not just task counts
- **Informed decisions**: User knows which phases to consider expanding

**Relationship to /implement Proactive Check:**

- **At plan creation**: Agent reviews entire plan holistically for structural recommendations
- **At implementation**: Agent re-evaluates specific phase before starting work
- **Different contexts**: Full plan view vs focused phase view
- **User flexibility**: Can expand at plan time, implementation time, or not at all

### 8.6. Present Recommendations

The agent-based analysis from Step 8.5 is presented immediately after plan creation, before final output. This helps users make informed decisions about plan structure before beginning implementation.

**Presentation Timing:**
- After plan file is written
- Before final "Plan created successfully" message
- Gives user opportunity to expand phases immediately if desired

**User Options After Analysis:**
1. **Expand now**: Use recommended `/expand phase` commands before starting implementation
2. **Expand during implementation**: Wait and expand if phases prove complex
3. **Keep inline**: Continue with Level 0 structure throughout implementation
4. **Selective expansion**: Expand some recommended phases but not others

This analysis replaces the generic complexity hint (≥50 threshold) with specific, informed recommendations based on actual plan content.

## Output Format

### Single File Format (Structure Level 0)
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Plan Number**: [NNN]
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Structure Level**: 0
- **Complexity Score**: [N.N]
- **Estimated Phases**: [Number]
- **Estimated Tasks**: [Number]
- **Estimated Hours**: [Number]
- **Standards File**: [Path to CLAUDE.md if found]
- **Research Reports**: [List of report paths used, if any]

## Overview
[Feature description and goals]

## Success Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Technical Design
[Architecture and design decisions]

## Implementation Phases

### Phase 1: [Foundation/Setup]
**Objective**: [What this phase accomplishes]
**Complexity**: [Low/Medium/High]

Tasks:
- [ ] Specific task with file reference
- [ ] Another task

Testing:
```bash
# Test command
```

### Phase 2: [Core Implementation]
[Continue with subsequent phases...]

## Testing Strategy
[Overall testing approach]

## Documentation Requirements
[What documentation needs updating]

## Dependencies
[External dependencies or prerequisites]

## Related Artifacts
[If plan created from /orchestrate workflow with research artifacts:]
- [Existing Patterns](../artifacts/{project_name}/existing_patterns.md)
- [Best Practices](../artifacts/{project_name}/best_practices.md)
- [Alternative Approaches](../artifacts/{project_name}/alternatives.md)

[Otherwise: "No artifacts - direct implementation plan"]

## Notes
[Additional considerations or decisions]
```

## Agent Usage

This command can leverage specialized agents for research and planning:

### research-specialist Agent (Optional)
- **Purpose**: Analyze codebase and research best practices before planning
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **When Used**: For complex features requiring codebase analysis
- **Invocation**: One or more parallel agents for different research topics

### plan-architect Agent
- **Purpose**: Generate structured, phased implementation plans with progressive structure support
- **Tools**: Read, Write, Bash, Grep, Glob, WebSearch
- **Invocation**: Single agent after research (if any) completes
- **Output**: Complete implementation plan in specs/plans/ (always single-file Level 0)
- **Progressive-Aware**: Creates single-file plans with complexity hints for future expansion

### Two-Stage Planning Process

#### Stage 1: Research (for complex features)
```yaml
# Optional: If feature requires codebase analysis or best practices research
Task {
  subagent_type: "general-purpose"
  description: "Research [aspect] for [feature] using research-specialist protocol"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/research-specialist.md

          You are acting as a Research Specialist with the tools and constraints
          defined in that file.

          Analyze existing [component] implementations in codebase.
          Research industry best practices for [technology].
          Summarize findings in max 150 words.
  "
}
```

#### Stage 2: Plan Generation (Progressive)
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create progressive implementation plan for [feature] using plan-architect protocol"
  prompt: "Read and follow the behavioral guidelines from:
          /home/benjamin/.config/.claude/agents/plan-architect.md

          You are acting as a Plan Architect with the tools and constraints
          defined in that file.

          **Thinking Mode**: [think|think hard|think harder] (based on feature complexity)

          Plan Task: Create progressive plan for [feature]

          Context:
          - Feature description: [user input]
          - Research findings: [if stage 1 completed]
          - Project standards: CLAUDE.md at [path]
          - Report paths: [if provided]
          - Specs directory: [path/to/specs/]
          - Next plan number: [NNN]

          STEP 1: Evaluate Complexity (Informational Only)
          - Run: .claude/lib/analyze-plan-requirements.sh \"[feature description]\"
          - Run: .claude/lib/calculate-plan-complexity.sh [tasks] [phases] [hours] [deps]
          - Calculate complexity score for metadata
          - Note: Score is informational; all plans start as Level 0

          STEP 2: Create Single-File Plan (Structure Level 0)
          - Create: specs/plans/NNN_feature_name.md
          - Include all phases and tasks inline
          - Add Structure Level: 0 and Complexity Score to metadata
          - Add hint if complexity ≥50: \"Consider /expand phase during implementation\"

          STEP 3: Requirements
          - Use /implement-compatible checkbox format: - [ ]
          - Include testing strategy for each phase
          - Follow CLAUDE.md coding standards
          - Add estimated complexity for each phase
          - Include clear success criteria
          - Add clear phase boundaries for future expansion if needed

          STEP 4: Output Summary
          - Report complexity score (informational)
          - List phase count and task count
          - Provide path to plan file
          - If complexity ≥50: Mention expansion option
  "
}
```

### Agent Benefits
- **Progressive Structure**: Always starts simple (Level 0), grows as needed
- **Informed Planning**: Research findings incorporated into plan design
- **Structured Output**: Consistent single-file plan format across all features
- **Standards Compliance**: Automatic reference to project conventions
- **Phased Approach**: Natural breakdown into testable, committable phases
- **Scalable Organization**: Plans start simple, can expand during implementation
- **Reusable Plans**: Plans serve as documentation and implementation guides
- **Complexity Awareness**: Hints provided for high-complexity plans needing expansion

### Workflow Integration
1. User invokes `/plan` with feature description and optional reports
2. If complex: Command delegates research to `research-specialist` agent(s)
3. Command analyzes requirements and calculates complexity score (informational)
4. Command delegates planning to `plan-architect` agent with:
   - Research findings
   - Complexity metrics (for hint generation)
   - Project standards
5. Agent calculates complexity score for metadata
6. Agent generates single-file plan (Structure Level 0)
7. If complexity ≥50: Agent adds hint about expansion during implementation
8. Command returns plan path and summary for use with `/implement`

For simple plans, the command can execute directly without agents. For complex features (especially in `/orchestrate` workflows), agents provide systematic research and planning.

Let me analyze your feature requirements and create a comprehensive implementation plan.
