---
allowed-tools: Read, Write, Bash, Grep, Glob, WebSearch
argument-hint: <feature description> [report-path1] [report-path2] ...
description: Create a detailed implementation plan following project standards, optionally guided by research reports
command-type: primary
dependent-commands: list-reports, update-plan, revise
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

### 2. Requirements Analysis
I'll analyze the feature requirements to determine:
- Core functionality needed
- Technical scope and boundaries
- Affected components and modules
- Dependencies and prerequisites
- Alignment with report recommendations (if applicable)

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

### 8. Plan Creation
The plan will be saved as:
- Path: `[relevant-dir]/specs/plans/NNN_feature_name.md`
- Feature name converted to lowercase with underscores
- Comprehensive yet actionable content
- Clear phase boundaries for `/implement` command compatibility

## Output Format

```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Plan Number**: [NNN]
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Estimated Phases**: [Number]
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
- **Purpose**: Generate structured, phased implementation plans
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Invocation**: Single agent after research (if any) completes
- **Output**: Complete implementation plan in specs/plans/

### Two-Stage Planning Process

#### Stage 1: Research (for complex features)
```yaml
# Optional: If feature requires codebase analysis or best practices research
Task {
  subagent_type: "research-specialist"
  description: "Research [aspect] for [feature]"
  prompt: "
    Analyze existing [component] implementations in codebase.
    Research industry best practices for [technology].
    Summarize findings in max 150 words.
  "
}
```

#### Stage 2: Plan Generation
```yaml
Task {
  subagent_type: "plan-architect"
  description: "Create implementation plan for [feature]"
  prompt: "
    **Thinking Mode**: [think|think hard|think harder] (based on feature complexity)

    Plan Task: Create plan for [feature]

    Context:
    - Feature description: [user input]
    - Research findings: [if stage 1 completed]
    - Project standards: CLAUDE.md
    - Report paths: [if provided]
    - Complexity Level: [Simple|Medium|Complex|Critical]

    Requirements:
    - Multi-phase structure with specific tasks
    - Testing strategy for each phase
    - /implement compatibility (checkbox format)
    - Standards integration from CLAUDE.md

    Complexity Analysis:
    - Simple features: 1-2 phases, single file/component
    - Medium features: 3-4 phases, multiple components
    - Complex features: 5+ phases, architecture changes
    - Critical features: Multiple risks, security/breaking changes

    Output:
    - Plan file at specs/plans/NNN_[feature].md
    - Plan summary with phase count and complexity
  "
}
```

### Agent Benefits
- **Informed Planning**: Research findings incorporated into plan design
- **Structured Output**: Consistent plan format across all features
- **Standards Compliance**: Automatic reference to project conventions
- **Phased Approach**: Natural breakdown into testable, committable phases
- **Reusable Plans**: Plans serve as documentation and implementation guides

### Workflow Integration
1. User invokes `/plan` with feature description and optional reports
2. If complex: Command delegates research to `research-specialist` agent(s)
3. Command delegates planning to `plan-architect` agent with research findings
4. Agent generates plan following project standards
5. Command returns plan path for use with `/implement`

For simple plans, the command can execute directly without agents. For complex features (especially in `/orchestrate` workflows), agents provide systematic research and planning.

Let me analyze your feature requirements and create a comprehensive implementation plan.
