---
allowed-tools: Read, Write, Grep, Glob, WebSearch, Task, TodoWrite
argument-hint: (no arguments - interactive wizard)
description: Interactive wizard that guides users through creating implementation plans with optional research integration
command-type: primary
dependent-commands: plan, report
---

# Interactive Plan Creation Wizard

I'll guide you through creating an implementation plan with an interactive, step-by-step wizard.

## Overview

This wizard provides a guided experience for planning:
- Lower barrier to entry for new users
- Intelligent suggestions for components and research
- Optional research agent integration
- Generates comprehensive implementation plan

## Wizard Flow

I'll walk you through 4-5 steps to gather requirements, then generate a plan.

## Process

### Step 1: Welcome and Feature Description

I'll display a welcome message and prompt for the feature description:

```
Plan Wizard - Interactive Plan Creation

This wizard will guide you through creating a comprehensive implementation plan.

Step 1: What would you like to implement?
Describe your feature or task in 1-2 sentences:
```

Wait for user to provide feature description. Store as the feature description for later steps.

### Step 2: Component Identification

I'll analyze the feature description and suggest likely affected components:

**Suggestion logic** (based on keywords in description):
- "auth/login/security" → auth, security, user
- "ui/interface/display" → ui, interface, display
- "test/spec" → tests, specs
- "doc/readme" → documentation
- "api/endpoint" → api, backend
- "performance/optimize" → performance, core

**Prompt format**:
```
Step 2: Which components will this affect?

Suggested components (based on your description):
- [component 1]
- [component 2]
- [component 3]

Enter components (comma-separated), or press Enter to use suggestions:
```

Wait for user input. If empty, use suggestions. Parse comma-separated list and store.

### Step 3: Complexity Assessment

I'll prompt for complexity level:

```
Step 3: What's the complexity level?

1. Simple    - Minor changes, single file, < 2 hours
2. Medium    - Multiple files, new functionality, 2-8 hours
3. Complex   - Architecture changes, multiple modules, 8-16 hours
4. Critical  - Major refactor, system-wide impact, > 16 hours

Select complexity (1-4):
```

Wait for user selection (1-4). Map to complexity level:
- 1 → simple (1-2 phases, research not recommended)
- 2 → medium (2-4 phases, research optional)
- 3 → complex (4-6 phases, research recommended)
- 4 → critical (6+ phases, research required)

### Step 4: Research Decision

I'll ask whether to conduct research first:

**Default recommendation based on complexity**:
- Simple → "not recommended" (default: n)
- Medium → "optional" (default: n)
- Complex/Critical → "recommended" (default: y)

**Prompt format**:
```
Step 4: Should I research first? ([recommendation])

Research will help identify:
- Existing patterns in the codebase
- Best practices and standards
- Alternative approaches
- Potential challenges

Conduct research before planning? (y/n) [default]:
```

Wait for user input. If yes, proceed to Step 5. If no, skip to Step 6.

### Step 5: Research Topic Identification (Conditional)

If research requested, I'll suggest research topics based on keywords:

**Topic suggestion logic**:
- "auth/security/login" → "Security best practices (2025)", "Existing auth patterns in codebase"
- "performance/optimize" → "Performance optimization techniques", "Profiling approaches"
- "ui/interface" → "UI/UX best practices", "Existing interface patterns"
- Always include: "Existing implementations of similar features", "Project coding standards"
- Limit to 3-4 most relevant topics

**Prompt format**:
```
Step 5: Research Topics

Based on your feature, I suggest researching:
1. [topic 1]
2. [topic 2]
3. [topic 3]

Options:
- Press Enter to proceed with these topics
- Edit topics (comma-separated list)
- Type 'skip' to skip research

Your choice:
```

Wait for user input. Handle three cases:
- Empty/Enter → use suggested topics
- Custom list → parse and use custom topics
- "skip" → cancel research, skip to Step 7

### Step 6: Execute Research (Conditional)

If research confirmed, I'll launch parallel research agents:

**Display message**:
```
Launching research agents...

[Agent 1/N] Researching: [topic 1]
[Agent 2/N] Researching: [topic 2]
...

This may take 30-60 seconds...
```

**For each research topic**, use Task tool with:
- `subagent_type`: "general-purpose"
- `description`: "Research [topic] for plan wizard"
- `prompt`:
  ```
  Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md

  Research Task: [topic]

  Context: User wants to implement: [feature description]
  Components: [component list]

  Requirements:
  - Search codebase for existing patterns
  - Research best practices (use WebSearch if needed)
  - Identify potential challenges
  - Max 150 words summary

  Output format:
  - Key findings (3-5 bullets)
  - Recommended approach
  - Potential challenges
  ```

**IMPORTANT**: Launch all research agents in **a single message** with multiple Task tool calls for parallel execution.

Collect the report paths or findings from each agent for Step 7.

### Step 7: Generate Implementation Plan

I'll now invoke the `/plan` command directly with all collected context:

**Display message**:
```
Generating implementation plan...

Feature: [feature description]
Components: [component list]
Complexity: [complexity level]
Research: [Yes/No + count if yes]
```

**Plan generation**: Use the `/plan` command slash command tool with:
- Feature description from Step 1
- If research was conducted: include report paths as additional arguments

The `/plan` command will:
- Create plan in specs/plans/ with next available number
- Include all wizard context in metadata
- Structure phases based on complexity level
- Incorporate research findings if provided

### Step 8: Display Results

I'll display a success message with the plan details:

```
Plan Created Successfully!

Plan: specs/plans/[NNN]_[feature_name].md
Phases: N
Complexity: [complexity level]
Research: [Yes (N reports) / No]

Next steps:
- Review the plan
- Implement: /implement specs/plans/[NNN]_[feature_name].md
- Modify: /revise "changes..." specs/plans/[NNN]_[feature_name].md

The wizard has completed!
```

## Error Handling

Common errors and recovery:
- **Invalid input**: Re-prompt with validation message and example (max 3 retries, then use defaults)
- **Research failures**: Report failed topics, ask "Continue with partial research?"
- **Plan generation failures**: Display error, suggest manual `/plan` command
- **Interruption**: Preserve research artifacts, suggest resuming with `/plan`

## Example Usage

```
/plan-wizard

→ Feature description: "Add OAuth2 authentication"
→ Components: auth, security, user (or customize)
→ Complexity: 3 (complex)
→ Research? y (recommended for complex)
→ Topics: [use suggestions or customize]
→ [Research agents launch in parallel...]
→ Plan created: specs/plans/NNN_oauth2_authentication.md
```

## Integration

**Workflow**: Wizard → `/plan` → (optional) `/revise` → `/implement`
**Research**: Uses research-specialist agents (parallel execution)
**Output**: Standard plans compatible with `/implement`, `/revise`

**When to use**:
- `/plan-wizard`: Guided experience, unsure of scope, want suggestions
- `/plan`: Know exactly what you need, have research ready
- `/plan-from-template`: Common pattern (CRUD, API, refactoring)
- `/orchestrate`: End-to-end automated workflow (research + plan + implement)

## References

- Related commands: `/plan`, `/plan-from-template`, `/orchestrate`, `/implement`
- Research agent: `.claude/agents/research-specialist.md`
