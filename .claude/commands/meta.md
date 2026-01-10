---
description: Interactive system builder for agent architectures
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), Task, TodoWrite, WebSearch
argument-hint: [DOMAIN] | --analyze | --generate
model: claude-opus-4-5-20251101
---

# /meta Command

Interactive system builder for creating agent architectures, commands, and skills.

**IMPORTANT**: This command creates TASKS with PLANS. It does NOT directly implement anything.

## Arguments

- No args: Start interactive interview
- `DOMAIN` - Direct domain specification
- `--analyze` - Analyze existing .claude/ structure
- `--generate` - Generate from previous interview

## Constraints

**FORBIDDEN**: This command ONLY creates tasks and plans. Never:
- Directly create commands, skills, rules, or context files
- Directly modify CLAUDE.md or ARCHITECTURE.md
- Implement any work
- Write any code or configuration files outside .claude/specs/

**REQUIRED**: All work must be tracked via:
- Tasks in TODO.md and state.json
- Plans in .claude/specs/{N}_{SLUG}/plans/

## Modes

### Interactive Mode (Default)

Multi-stage interview process to design agent system.

#### Stage 1: Domain Discovery

```
What domain will this system support?
Examples: "API development", "data pipeline", "game engine", "ML workflow"

Domain: {user_input}
```

#### Stage 2: Use Case Gathering

```
What are the main use cases?
1. {use_case_1}
2. {use_case_2}
3. {use_case_3}
(Enter blank line when done)
```

#### Stage 3: Workflow Analysis

```
For each use case, what's the typical workflow?

Use case: {use_case_1}
Steps:
1. {step}
2. {step}
...
```

#### Stage 4: Tool Requirements

```
What tools/integrations are needed?
- [ ] Web search
- [ ] File operations
- [ ] Git operations
- [ ] External APIs
- [ ] Build tools
- [ ] Testing frameworks
- [ ] Custom MCP servers

Selected: {tools}
```

#### Stage 5: Complexity Assessment

```
System complexity:
- Simple: 2-3 commands, 1-2 skills
- Medium: 4-6 commands, 3-5 skills
- Complex: 7+ commands, 6+ skills

Assessment: {level}
```

#### Stage 6: Architecture Design

Based on interview, propose architecture:

```
Proposed Architecture:

Commands:
1. /{command1} - {description}
2. /{command2} - {description}
...

Skills:
1. {skill1} - {when invoked}
2. {skill2} - {when invoked}
...

Rules:
1. {rule1}.md - {scope}
...

Context Files:
1. {context1}.md - {purpose}
...

Documentation Updates:
1. CLAUDE.md - {changes needed}
2. ARCHITECTURE.md - {changes needed}

Total tasks to create: {N}

Proceed with task creation? (y/n)
```

#### Stage 7: Task Creation

**For each component identified in Stage 6, create a task with a plan.**

##### 7.1 Read Current State

```bash
# Get next task number
jq '.next_project_number' .claude/specs/state.json
```

##### 7.2 Create Tasks Sequentially

For each component (command, skill, rule, context file, doc update):

**A. Create task directory:**
```bash
mkdir -p .claude/specs/{N}_{SLUG}/plans/
```

**B. Update state.json** (add to active_projects):
```json
{
  "project_number": {N},
  "project_name": "{slug}",
  "status": "planned",
  "language": "meta",
  "priority": "{high|medium|low}",
  "created": "{ISO_DATE}",
  "last_updated": "{ISO_DATE}"
}
```

**C. Update TODO.md** (add entry under appropriate priority):
```markdown
### {N}. {Title}
- **Effort**: {estimate}
- **Status**: [PLANNED]
- **Priority**: {High|Medium|Low}
- **Language**: meta
- **Created**: {ISO_DATE}
- **Plan**: [implementation-001.md](.claude/specs/{N}_{SLUG}/plans/implementation-001.md)

**Description**: {detailed description of component to create}

**Files to Create/Modify**:
- {target file path}
```

**D. Create plan artifact** at `.claude/specs/{N}_{SLUG}/plans/implementation-001.md`:
```markdown
# Implementation Plan: Task #{N}

**Task**: {title}
**Version**: 001
**Created**: {ISO_DATE}
**Language**: meta

## Overview

{Description of what to create and why}

## Phases

### Phase 1: Create {Component Type}

**Estimated effort**: {hours}
**Status**: [NOT STARTED]

**Objectives**:
1. Create {component} following project standards
2. Integrate with existing system

**Files to create/modify**:
- `{target_path}` - {description}

**Steps**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Verification**:
- File exists and has valid frontmatter
- No syntax errors
- Integrates with existing components

## Success Criteria

- [ ] {Component} created at correct path
- [ ] Follows project conventions
- [ ] Documented in CLAUDE.md if applicable
```

**E. Increment next_project_number** in state.json

##### 7.3 Priority Assignment

| Component Type | Default Priority |
|----------------|------------------|
| CLAUDE.md update | High |
| ARCHITECTURE.md update | High |
| Commands | High |
| Skills | Medium |
| Rules | Medium |
| Context files | Low |

##### 7.4 Task Ordering

Create tasks in this order (dependencies flow downward):
1. Documentation updates (CLAUDE.md, ARCHITECTURE.md)
2. Rules (define standards before implementing)
3. Skills (core functionality)
4. Commands (user-facing, depend on skills)
5. Context files (reference material)

#### Stage 8: Git Commit

```bash
git add .claude/specs/
git commit -m "meta: create {N} tasks for {domain} system"
```

#### Stage 9: Summary Output

```
Meta system builder complete.

Created {N} tasks with implementation plans:

High Priority:
- Task #{N1}: {title}
  Plan: .claude/specs/{N1}_{SLUG}/plans/implementation-001.md

- Task #{N2}: {title}
  Plan: .claude/specs/{N2}_{SLUG}/plans/implementation-001.md

Medium Priority:
- Task #{N3}: {title}
  Plan: .claude/specs/{N3}_{SLUG}/plans/implementation-001.md

Low Priority:
- Task #{N4}: {title}
  Plan: .claude/specs/{N4}_{SLUG}/plans/implementation-001.md

Next steps:
1. Review tasks in TODO.md
2. Review plans in .claude/specs/
3. Execute: /implement {N1} (start with highest priority)
4. Continue through task list
```

### Analyze Mode (--analyze)

Examine existing .claude/ structure:

```
Current .claude/ Structure:

Commands ({N}):
- /{command1} - {description}
- /{command2} - {description}

Skills ({N}):
- {skill1} - {description}
- {skill2} - {description}

Rules ({N}):
- {rule1}.md - {paths}

Context:
- core/: {N} files
- project/: {N} files

Settings:
- Permissions: {N} allow, {N} deny
- Hooks: {N} configured

Recommendations:
1. {suggestion}
2. {suggestion}
```

### Generate Mode (--generate)

Re-run task creation from last interview session stored in memory.

## Component Templates

These templates guide plan creation. The actual files are created during /implement.

### Command Task Description Template

```
Create /{command} command for {purpose}.

The command should:
- {Capability 1}
- {Capability 2}

Arguments:
- {arg1} - {description}

Tools needed: {tool list}

Target file: .claude/commands/{command}.md
```

### Skill Task Description Template

```
Create {skill-name} skill for {purpose}.

The skill should:
- {Capability 1}
- {Capability 2}

Trigger conditions:
- {When to invoke}

Tools needed: {tool list}

Target file: .claude/skills/{skill-name}/SKILL.md
```

### Rule Task Description Template

```
Create {rule}.md rule for {purpose}.

The rule should define:
- {Standard 1}
- {Standard 2}

Applies to: {glob pattern}

Target file: .claude/rules/{rule}.md
```

### Context File Task Description Template

```
Create {context}.md context file for {purpose}.

The file should document:
- {Topic 1}
- {Topic 2}

Target file: .claude/context/project/{domain}/{context}.md
```

## Example Execution

User runs: `/meta "Python/Z3 semantic theory development"`

Output after Stage 9:
```
Meta system builder complete.

Created 8 tasks with implementation plans:

High Priority:
- Task #350: Update CLAUDE.md for ModelChecker Python/Z3 focus
  Plan: .claude/specs/350_update_claude_md_modelchecker/plans/implementation-001.md

- Task #351: Update ARCHITECTURE.md for Python/Z3 system
  Plan: .claude/specs/351_update_architecture_python_z3/plans/implementation-001.md

Medium Priority:
- Task #352: Create skill-python-research for Z3 API research
  Plan: .claude/specs/352_create_skill_python_research/plans/implementation-001.md

- Task #353: Create skill-theory-implementation for TDD workflow
  Plan: .claude/specs/353_create_skill_theory_implementation/plans/implementation-001.md

- Task #354: Update skill-orchestrator for Python routing
  Plan: .claude/specs/354_update_skill_orchestrator_python/plans/implementation-001.md

- Task #355: Create python-z3.md rule for development patterns
  Plan: .claude/specs/355_create_python_z3_rule/plans/implementation-001.md

Low Priority:
- Task #356: Create modelchecker/architecture.md context
  Plan: .claude/specs/356_create_modelchecker_architecture_context/plans/implementation-001.md

- Task #357: Create modelchecker/z3-patterns.md context
  Plan: .claude/specs/357_create_modelchecker_z3_patterns_context/plans/implementation-001.md

Next steps:
1. Review tasks in TODO.md
2. Review plans in .claude/specs/
3. Execute: /implement 350 (start with highest priority)
4. Continue through task list
```
