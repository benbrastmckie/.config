# Command Documentation

This directory contains detailed guides for each slash command in the .claude system.

## Overview

These guides provide comprehensive documentation for using each command, including usage patterns, options, examples, and troubleshooting.

## Basic Usage Guide

Start with these minimal examples:

```bash
# Research-only workflow
/research "existing auth patterns"

# Complete implementation pipeline
/plan "add user auth"
/build
```

For detailed explanations, see the workflow patterns below.

### Workflow Pattern 1: Research-Only

Use `/research` when you need to investigate a topic without implementing changes. This is ideal for understanding existing patterns, evaluating options, or creating technical documentation.

**Syntax**:
```bash
/research "<topic>" [--complexity 1-4]
```

**Examples**:

```bash
# Basic research with default complexity (2)
/research "existing authentication patterns"

# Higher complexity for comprehensive analysis
/research "database migration strategies" --complexity 3

# Hierarchical topic research
/research "API versioning approaches and best practices"
```

**Output Structure**:
- Creates `specs/NNN_topic/reports/` directory with numbered research reports
- Reports are organized by subtopic (e.g., `001_subtopic.md`, `002_subtopic.md`)
- Includes an `OVERVIEW.md` summarizing findings across all reports

**Default Complexity**: 2 (expected duration: 5-15 minutes)

### Workflow Pattern 2: Plan-Build Pipeline

Use this pipeline for complete feature implementation. The flow is: plan -> (optional) revise -> (optional) expand -> build.

#### Step 1: /plan - Create Implementation Plan

Creates a research-backed implementation plan with phases and tasks.

**Syntax**:
```bash
/plan "<feature-description>" [--complexity 1-4]
```

**Examples**:

```bash
# Basic feature planning
/plan "add user authentication"

# Complex feature with higher complexity
/plan "implement real-time collaboration" --complexity 4
```

**Output**:
- Research reports in `specs/NNN_topic/reports/`
- Implementation plan in `specs/NNN_topic/plans/001_feature_plan.md`

**Default Complexity**: 3 (expected duration: 15-30 minutes)

#### Step 2: /revise - Refine Existing Plan (Optional)

Updates an existing plan based on new insights or requirements. Creates a backup before modifying.

**Syntax**:
```bash
/revise "<revision-description>" [--complexity 1-4]
```

**Examples**:

```bash
# Revise based on new requirements
/revise "add OAuth2 support to auth plan"

# Revise with path to specific plan
/revise "update error handling" --file /path/to/plan.md
```

**Behavior**:
- Creates backup in `plans/backups/` before modifying
- Preserves plan structure while updating content
- Can add new phases or modify existing ones

**Default Complexity**: 2 (expected duration: 10-20 minutes)

#### Step 3: /expand - Expand Phases (Optional)

Expands high-level phases into detailed task files for complex implementations.

**Syntax**:
```bash
# Auto-expand all phases
/expand /path/to/plan.md

# Expand specific phase
/expand phase /path/to/plan.md 3
```

**Examples**:

```bash
# Auto-expand phases based on complexity analysis
/expand /home/user/.claude/specs/027_auth/plans/001_auth_plan.md

# Expand only phase 3 for detailed breakdown
/expand phase /home/user/.claude/specs/027_auth/plans/001_auth_plan.md 3
```

**Structure Levels**:
- Level 0: All phases inline (default)
- Level 1: Phases in separate files (`plans/phase_N.md`)
- Level 2: Stages in separate files (`plans/phase_N/stage_M.md`)

#### Step 4: /build - Execute Implementation

Executes the implementation plan with wave-based parallel execution.

**Syntax**:
```bash
# Build from most recent plan
/build

# Build from specific plan
/build /path/to/plan.md

# Start from specific phase
/build /path/to/plan.md 3

# Dry run (show what would be executed)
/build /path/to/plan.md --dry-run
```

**Examples**:

```bash
# Execute the auth implementation plan
/build /home/user/.claude/specs/027_auth/plans/001_auth_plan.md

# Resume from phase 3 after fixing issues
/build /home/user/.claude/specs/027_auth/plans/001_auth_plan.md 3
```

**Workflow States**:
- Full implementation: Research, plan, implement, test, document
- Phase execution: Tracks progress through plan phases
- Creates git commits after successful phases

### Common Workflow Chains

#### Research -> Plan

Start with research to understand the problem space, then create an implementation plan:

```bash
# First, research existing patterns
/research "authentication best practices in Node.js"

# Then create a plan based on findings
/plan "implement JWT authentication"
```

#### Plan -> Build

Create a plan and immediately execute it:

```bash
# Create the implementation plan
/plan "add rate limiting to API"

# Execute the plan
/build
```

#### Build -> Revise -> Build (Debug Loop)

When implementation encounters issues, revise the plan and rebuild:

```bash
# Initial build attempt
/build /path/to/plan.md

# Build fails at phase 3 - revise the plan
/revise "fix database connection handling in phase 3"

# Resume building from phase 3
/build /path/to/plan.md 3
```

#### Full Pipeline Example

```bash
# 1. Research the domain
/research "OAuth2 implementation patterns"

# 2. Create initial plan
/plan "add OAuth2 authentication with Google and GitHub"

# 3. Expand complex phases (optional)
/expand /home/user/.claude/specs/042_oauth/plans/001_oauth_plan.md

# 4. Build the implementation
/build

# 5. If issues arise, revise and rebuild
/revise "add refresh token rotation"
/build
```

### Choosing Complexity Level

| Level | Description | Expected Duration | Use When |
|-------|-------------|-------------------|----------|
| 1 | Quick overview | 5-10 min | Simple queries, quick lookups |
| 2 | Standard analysis | 10-20 min | Most research tasks (default for /research, /revise) |
| 3 | Comprehensive | 20-45 min | Feature planning, detailed analysis (default for /plan) |
| 4 | Exhaustive | 45-90 min | Complex systems, multiple integration points |

**Guidelines**:
- Start with default complexity; increase if results are insufficient
- Higher complexity = more research topics and deeper analysis
- /debug always uses complexity appropriate to issue severity

## Command Guides

| Command | Guide | Description |
|---------|-------|-------------|
| /build | [build-command-guide.md](build-command-guide.md) | Full implementation workflow with wave-based execution |
| /collapse | [collapse-command-guide.md](collapse-command-guide.md) | Merge expanded phases back into parent plan |
| /convert-docs | [convert-docs-command-guide.md](convert-docs-command-guide.md) | Convert between document formats |
| /debug | [debug-command-guide.md](debug-command-guide.md) | Debug-focused workflow for root cause analysis |
| /document | [document-command-guide.md](document-command-guide.md) | Generate documentation |
| /errors | [errors-command-guide.md](errors-command-guide.md) | Query and analyze error logs from workflows |
| /expand | [expand-command-guide.md](expand-command-guide.md) | Expand phases into detailed task files |
| /optimize-claude | [optimize-claude-command-guide.md](optimize-claude-command-guide.md) | Optimize CLAUDE.md configuration |
| /plan | [plan-command-guide.md](plan-command-guide.md) | Research and create implementation plans |
| /research | [research-command-guide.md](research-command-guide.md) | Research-only workflow for reports |
| /revise | [revise-command-guide.md](revise-command-guide.md) | Revise existing plans with new insights |
| /setup | [setup-command-guide.md](setup-command-guide.md) | Project setup and configuration |
| /test | [test-command-guide.md](test-command-guide.md) | Test execution and validation |
| /todo | [todo-command-guide.md](todo-command-guide.md) | Scan specs and update TODO.md project status |

## Related Documentation

- [Command Reference](../../reference/standards/command-reference.md) - Quick reference for all commands
- [Command Development](../development/command-development/) - How to create commands
- [Orchestration Guides](../orchestration/) - Workflow orchestration patterns

## Navigation

- [← Parent Directory](../README.md)
- [Related: Development Guides](../development/README.md)
- [Related: Orchestration Guides](../orchestration/README.md)
