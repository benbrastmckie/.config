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

### 2. Requirements Analysis and Complexity Evaluation
I'll analyze the feature requirements to determine:
- Core functionality needed
- Technical scope and boundaries
- Affected components and modules
- Dependencies and prerequisites
- Alignment with report recommendations (if applicable)

**Complexity Evaluation** (Adaptive Plan Structure):
- Use `.claude/utils/analyze-plan-requirements.sh` to estimate:
  - Task count
  - Phase count
  - Estimated hours
  - Dependency complexity
- Use `.claude/utils/calculate-plan-complexity.sh` to determine tier:
  - **Tier 1** (score <50): Single-file plan for simple features
  - **Tier 2** (score 50-200): Phase-directory plan for medium features
  - **Tier 3** (score ≥200): Hierarchical tree plan for complex features
- Display recommended tier to user with option to override

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

### 8. Adaptive Plan Creation

Based on complexity tier, create appropriate structure:

**Tier 1 (Single File)** - Score <50:
- Path: `specs/plans/NNN_feature_name.md`
- Single file with all phases and tasks
- Traditional format (existing behavior)

**Tier 2 (Phase Directory)** - Score 50-200:
- Create directory: `specs/plans/NNN_feature_name/`
- Create overview: `specs/plans/NNN_feature_name/NNN_feature_name.md`
  - Contains metadata, problem statement, solution approach, phase summaries
- Create phase files: `phase_1_name.md`, `phase_2_name.md`, etc.
  - Each contains detailed tasks, testing, expected outcomes for that phase
- Add cross-references between overview and phase files

**Tier 3 (Hierarchical Tree)** - Score ≥200:
- Create directory: `specs/plans/NNN_feature_name/`
- Create overview: `specs/plans/NNN_feature_name/NNN_feature_name.md`
  - Contains metadata, problem, solution, links to phase directories
- Create phase directories: `phase_1_name/`, `phase_2_name/`, etc.
- For each phase directory:
  - Create `phase_N_overview.md` with phase objectives and stage summaries
  - Create stage files: `stage_1_name.md`, `stage_2_name.md`, etc.
  - Each stage contains detailed tasks for that portion of the phase
- Implement complete cross-referencing hierarchy

**All tiers**:
- Feature name converted to lowercase with underscores
- Comprehensive yet actionable content
- Clear phase boundaries for `/implement` command compatibility
- Metadata includes Structure Tier and Complexity Score

## Output Format

### Tier 1 (Single File)
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Plan Number**: [NNN]
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Structure Tier**: 1
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

### Tier 2 (Phase Directory)

**Overview File** (`NNN_feature_name/NNN_feature_name.md`):
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Plan Number**: [NNN]
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Structure Tier**: 2
- **Complexity Score**: [N.N]
- **Estimated Phases**: [Number]
- **Estimated Tasks**: [Number]
- **Estimated Hours**: [Number]
- **Standards File**: [Path to CLAUDE.md if found]
- **Phase Files**:
  - [Phase 1: Foundation](phase_1_foundation.md)
  - [Phase 2: Implementation](phase_2_implementation.md)
  - ...

## Overview
[Feature description]

## Problem Statement
[What problem this solves]

## Solution Approach
[High-level solution]

## Phase Summaries

### Phase 1: Foundation
[Brief summary of phase objectives]

### Phase 2: Implementation
[Brief summary of phase objectives]

[... additional phase summaries ...]
```

**Phase Files** (`phase_N_name.md`):
```markdown
# Phase N: [Phase Name]

## Objective
[What this phase accomplishes]

## Complexity
[Low/Medium/High]

## Tasks

- [ ] Task 1 with details
- [ ] Task 2 with details
- [ ] Task 3 with details

## Testing

\```bash
# Test commands
\```

## Expected Outcomes

- Outcome 1
- Outcome 2
```

### Tier 3 (Hierarchical Tree)

**Main Overview** (`NNN_feature_name/NNN_feature_name.md`):
```markdown
# [Feature] Implementation Plan

## Metadata
- **Date**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Plan Number**: [NNN]
- **Feature**: [Feature name]
- **Scope**: [Brief scope description]
- **Structure Tier**: 3
- **Complexity Score**: [N.N]
- **Estimated Phases**: [Number]
- **Estimated Tasks**: [Number]
- **Estimated Hours**: [Number]
- **Standards File**: [Path to CLAUDE.md if found]
- **Phase Directories**:
  - [Phase 1: Foundation](phase_1_foundation/)
  - [Phase 2: Implementation](phase_2_implementation/)
  - ...

## Overview
[Feature description]

## Problem Statement
[Detailed problem]

## Solution Approach
[Detailed solution]

## Phase Summaries

### Phase 1: Foundation
[Brief summary with link to phase directory]

### Phase 2: Implementation
[Brief summary with link to phase directory]
```

**Phase Overview** (`phase_N_name/phase_N_overview.md`):
```markdown
# Phase N: [Phase Name] Overview

## Objective
[What this phase accomplishes]

## Complexity
[High/Very High]

## Stages

- [Stage 1: Setup](stage_1_setup.md)
- [Stage 2: Core](stage_2_core.md)
- [Stage 3: Integration](stage_3_integration.md)

## Success Criteria

- Criteria 1
- Criteria 2

[← Back to Plan Overview](../NNN_feature_name.md)
```

**Stage Files** (`phase_N_name/stage_M_name.md`):
```markdown
# Stage M: [Stage Name]

## Tasks

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Testing

\```bash
# Test commands
\```

## Expected Outcomes

- Outcome 1
- Outcome 2

[← Back to Phase N Overview](phase_N_overview.md)
```

## Agent Usage

This command can leverage specialized agents for research and planning:

### research-specialist Agent (Optional)
- **Purpose**: Analyze codebase and research best practices before planning
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **When Used**: For complex features requiring codebase analysis
- **Invocation**: One or more parallel agents for different research topics

### plan-architect Agent
- **Purpose**: Generate structured, phased implementation plans with adaptive tier selection
- **Tools**: Read, Write, Bash, Grep, Glob, WebSearch
- **Invocation**: Single agent after research (if any) completes
- **Output**: Complete implementation plan in specs/plans/ (Tier 1/2/3 based on complexity)
- **Tier-Aware**: Automatically creates appropriate structure (single-file, phase-directory, or hierarchical)

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

#### Stage 2: Plan Generation (Tier-Aware)
```yaml
Task {
  subagent_type: "plan-architect"
  description: "Create adaptive implementation plan for [feature]"
  prompt: "
    **Thinking Mode**: [think|think hard|think harder] (based on feature complexity)

    Plan Task: Create adaptive plan for [feature]

    Context:
    - Feature description: [user input]
    - Research findings: [if stage 1 completed]
    - Project standards: CLAUDE.md at [path]
    - Report paths: [if provided]
    - Specs directory: [path/to/specs/]
    - Next plan number: [NNN]

    STEP 1: Evaluate Complexity
    - Run: .claude/utils/analyze-plan-requirements.sh \"[feature description]\"
    - Run: .claude/utils/calculate-plan-complexity.sh [tasks] [phases] [hours] [deps]
    - Determine recommended tier (1, 2, or 3)
    - Note: User can override tier if needed

    STEP 2: Create Plan Structure Based on Tier

    **Tier 1 (Complexity Score <50)**: Single-file plan
    - Create: specs/plans/NNN_feature_name.md
    - Include all phases and tasks in one file
    - Add Structure Tier: 1 and Complexity Score to metadata

    **Tier 2 (Complexity Score 50-200)**: Phase-directory plan
    - Create directory: specs/plans/NNN_feature_name/
    - Create overview: NNN_feature_name.md (metadata, problem, solution, phase summaries)
    - Create phase files: phase_1_name.md, phase_2_name.md, etc.
    - Add cross-references between files
    - Add Structure Tier: 2 and Complexity Score to metadata

    **Tier 3 (Complexity Score ≥200)**: Hierarchical tree plan
    - Create directory: specs/plans/NNN_feature_name/
    - Create overview: NNN_feature_name.md (links to phase directories)
    - Create phase directories: phase_1_name/, phase_2_name/, etc.
    - For each phase: create overview and stage files
    - Add complete cross-referencing hierarchy
    - Add Structure Tier: 3 and Complexity Score to metadata

    STEP 3: Requirements
    - Use /implement-compatible checkbox format: - [ ]
    - Include testing strategy for each phase/stage
    - Follow CLAUDE.md coding standards
    - Add estimated complexity for each phase
    - Include clear success criteria

    STEP 4: Output Summary
    - Report tier selected and complexity score
    - List phase count and structure created
    - Provide path to plan (file or directory)
  "
}
```

### Agent Benefits
- **Adaptive Structure**: Automatically selects appropriate tier (1/2/3) based on complexity
- **Informed Planning**: Research findings incorporated into plan design
- **Structured Output**: Consistent plan format across all features and tiers
- **Standards Compliance**: Automatic reference to project conventions
- **Phased Approach**: Natural breakdown into testable, committable phases
- **Scalable Organization**: Simple plans stay simple, complex plans get hierarchical structure
- **Reusable Plans**: Plans serve as documentation and implementation guides

### Workflow Integration
1. User invokes `/plan` with feature description and optional reports
2. If complex: Command delegates research to `research-specialist` agent(s)
3. Command analyzes requirements and calculates complexity score
4. Command delegates planning to `plan-architect` agent with:
   - Research findings
   - Complexity metrics and recommended tier
   - Project standards
5. Agent evaluates complexity and selects tier (1, 2, or 3)
6. Agent generates plan structure appropriate for selected tier
7. Command returns plan path (file or directory) and summary for use with `/implement`

For simple plans, the command can execute directly without agents. For complex features (especially in `/orchestrate` workflows), agents provide systematic research and planning.

Let me analyze your feature requirements and create a comprehensive implementation plan.
