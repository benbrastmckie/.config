# Workflow Type Selection Guide

**Version**: 1.0.0
**Last Updated**: 2025-11-17

## Overview

This guide helps you choose the right orchestrator command for your workflow needs. The `.claude/` system provides both dedicated workflow commands (optimized for specific tasks) and a comprehensive orchestrator (`/coordinate`) that handles all workflow types.

## Quick Decision Matrix

| Your Goal | Recommended Command | Alternative |
|-----------|---------------------|-------------|
| Research a topic (no implementation) | `/research` | `/coordinate` |
| Research + create new plan | `/plan` | `/coordinate` |
| Research + revise existing plan | `/revise` | `/coordinate` |
| Build from existing plan | `/build` | `/coordinate` or `/implement` |
| Debug/investigate issues | `/debug` | `/coordinate` or `/debug` |
| Full workflow (research → plan → implement) | `/coordinate` | Chain commands |

## Command Comparison

### Dedicated Commands vs /coordinate

**Dedicated Commands** (Optimized):
- ✅ **5-10s faster** (skip workflow classification)
- ✅ **Clearer intent** (command name = workflow type)
- ✅ **Simpler interface** (fewer arguments)
- ❌ **Less flexible** (fixed workflow sequence)

**/coordinate** (Comprehensive):
- ✅ **Most flexible** (handles all workflow types)
- ✅ **Single command** (learn once, use everywhere)
- ✅ **Auto-classification** (determines workflow from description)
- ❌ **5-10s overhead** (workflow-classifier agent invocation)

## Detailed Command Reference

### 1. /research - Research-Only Workflow

**Use When**:
- Investigating a topic before deciding on implementation
- Gathering information for documentation
- Exploring unfamiliar codebase areas
- Answering "how does X work?" questions

**Workflow**: `research → complete`

**Syntax**:
```bash
/research "<topic-description>" [--complexity 1-4]
```

**Examples**:
```bash
# Basic research (complexity 2, default)
/research "authentication patterns in codebase"

# Comprehensive research (complexity 4)
/research "API architecture and data flow --complexity 4"
```

**Outputs**:
- Research reports: `.claude/specs/NNN_topic/reports/*.md`

**When to Use /coordinate Instead**:
- You want to create a plan immediately after research
- You need full implementation workflow

---

### 2. /plan - Research + New Plan Creation

**Use When**:
- Starting a new feature from scratch
- Need research before planning implementation
- Want comprehensive investigation → structured plan

**Workflow**: `research → plan → complete`

**Syntax**:
```bash
/plan "<feature-description>" [--complexity 1-4]
```

**Examples**:
```bash
# Standard research + planning (complexity 3, default)
/plan "implement user authentication with JWT tokens"

# Thorough research before planning
/plan "add real-time notifications system --complexity 4"
```

**Outputs**:
- Research reports: `.claude/specs/NNN_topic/reports/*.md`
- Implementation plan: `.claude/specs/NNN_topic/plans/001_*.md`

**When to Use /coordinate Instead**:
- You want to implement immediately after planning
- You need the full workflow (research → plan → implement → test)

---

### 3. /revise - Research + Plan Revision

**Use When**:
- Have existing plan that needs updates based on new insights
- Requirements changed after initial planning
- Need to incorporate new research findings into plan

**Workflow**: `research → plan_revision → complete`

**Syntax**:
```bash
/revise "revise plan at <plan-path> based on <new-insights>" [--complexity 1-4]
```

**Examples**:
```bash
# Basic revision research (complexity 2, default)
/revise "revise plan at .claude/specs/123_auth/plans/001_plan.md based on new security requirements"

# Thorough revision research
/revise "revise plan at ./plans/api.md incorporating GraphQL findings --complexity 3"
```

**Outputs**:
- Research reports: `<specs-dir>/reports/*.md`
- Revised plan: `<plan-path>` (original backed up to `<plan-path>/backups/`)
- Backup: `<plans-dir>/backups/<plan-name>_TIMESTAMP.md`

**When to Use /coordinate Instead**:
- You want to implement the revised plan immediately
- You need full workflow after revision

---

### 4. /build - Build from Existing Plan

**Use When**:
- Have existing plan ready to implement
- Resuming interrupted implementation
- Want to execute specific phase of existing plan

**Workflow**: `implement → test → [debug OR document] → complete`

**Syntax**:
```bash
/build [plan-file] [starting-phase] [--dry-run]
```

**Examples**:
```bash
# Auto-resume from most recent plan (default)
/build

# Build specific plan from beginning
/build .claude/specs/123_auth/plans/001_implementation.md

# Resume from phase 3
/build .claude/specs/123_auth/plans/001_implementation.md 3

# Preview execution plan (dry-run)
/build --dry-run
```

**Outputs**:
- Implementation commits (git)
- Test results
- Debug analysis (if tests fail)
- Updated documentation (if tests pass)

**When to Use /coordinate Instead**:
- You need research/planning first
- You want the full workflow from scratch

**When to Use /implement Instead**:
- You prefer `/implement` interface (same functionality)
- You're familiar with existing `/implement` patterns

---

### 5. /debug - Debug-Focused Workflow

**Use When**:
- Investigating bugs or errors
- Root cause analysis needed
- Want systematic debugging approach

**Workflow**: `research → plan (debug strategy) → debug → complete`

**Syntax**:
```bash
/debug "<issue-description>" [--complexity 1-4]
```

**Examples**:
```bash
# Basic debugging (complexity 2, default)
/debug "authentication timeout errors in production"

# Complex debugging investigation
/debug "intermittent database connection failures --complexity 3"

# Performance issue
/debug "API endpoint latency exceeds 2s on POST /api/users"
```

**Outputs**:
- Debug research: `.claude/specs/NNN_issue/reports/*.md`
- Debug strategy: `.claude/specs/NNN_issue/plans/001_debug_strategy.md`
- Debug analysis: `.claude/specs/NNN_issue/debug/*.log`

**When to Use /coordinate Instead**:
- You want full implementation after debugging
- You need comprehensive workflow

**When to Use /debug Instead**:
- You prefer existing `/debug` command interface
- You have specific debug context to provide

---

### 6. /coordinate - Comprehensive Orchestrator

**Use When**:
- Unsure which workflow type you need
- Want automatic workflow classification
- Need maximum flexibility
- Prefer single command for all workflows

**Workflow**: Auto-detected from description

**Syntax**:
```bash
/coordinate "<workflow-description>"
```

**Examples**:
```bash
# Auto-classifies as research-and-plan
/coordinate "implement user authentication with JWT"

# Auto-classifies as research-only
/coordinate "investigate API architecture patterns"

# Auto-classifies as debug-only
/coordinate "fix authentication timeout errors"
```

**Outputs**: Varies by detected workflow type

**Trade-offs**:
- ⏱️ **5-10s slower** (workflow classification overhead)
- 🎯 **Most flexible** (handles any workflow)
- 📚 **Single interface** (easier to learn)

---

## Workflow Type Characteristics

### Research-Only (`/research`)
**Terminal State**: research
**Phases**: Research → Complete
**Default Complexity**: 2
**Best For**: Exploration, investigation, documentation

### Research-and-Plan (`/plan`)
**Terminal State**: plan
**Phases**: Research → Plan → Complete
**Default Complexity**: 3
**Best For**: New features requiring investigation first

### Research-and-Revise (`/revise`)
**Terminal State**: plan
**Phases**: Research → Plan Revision → Complete
**Default Complexity**: 2
**Best For**: Plan updates based on new findings

### Build (`/build`)
**Terminal State**: complete
**Phases**: Implement → Test → [Debug OR Document] → Complete
**Default Complexity**: N/A (no research)
**Best For**: Executing existing plans

### Debug-Only (`/debug`)
**Terminal State**: debug
**Phases**: Research → Plan (Strategy) → Debug → Complete
**Default Complexity**: 2
**Best For**: Bug investigation and root cause analysis

---

## Complexity Levels

All commands with research phases support `--complexity` flag:

| Level | Topics | Duration | Agents | Use When |
|-------|--------|----------|--------|----------|
| 1 | 1-2 | ~5 min | research-specialist | Quick lookup |
| 2 | 2-3 | ~10 min | research-specialist | Standard investigation (default) |
| 3 | 3-4 | ~15 min | research-specialist | Comprehensive research |
| 4 | 4+ | ~20+ min | research-sub-supervisor | Hierarchical (multiple sub-agents) |

**Recommendation**: Start with default complexity, increase if results insufficient.

---

## Command Chaining Workflows

You can chain dedicated commands for custom workflows:

### Research → Plan → Implement
```bash
# Step 1: Research
/research "user authentication patterns"

# Step 2: Plan (after reviewing research)
/plan "implement JWT authentication"

# Step 3: Implement (after reviewing plan)
/build .claude/specs/123_auth/plans/001_implementation.md
```

### Plan → Revise → Implement
```bash
# Step 1: Create initial plan
/plan "add GraphQL API"

# Step 2: Revise plan with new insights
/revise "revise plan at .claude/specs/456_graphql/plans/001_plan.md based on Apollo Server findings"

# Step 3: Implement revised plan
/build .claude/specs/456_graphql/plans/001_plan.md
```

### Debug → Fix → Test
```bash
# Step 1: Debug investigation
/debug "API timeout errors on /users endpoint"

# Step 2: Apply fixes from debug analysis
# (manual code changes)

# Step 3: Re-run tests
/build <plan-path> 2  # Resume from test phase
```

---

## Migration from /coordinate

If you're currently using `/coordinate`, here's how to migrate:

### Scenario 1: Research-Only
**Before**:
```bash
/coordinate "investigate authentication patterns"
```

**After**:
```bash
/research "authentication patterns"
```

**Benefits**: 5-10s faster (no workflow classification)

### Scenario 2: Research + Plan
**Before**:
```bash
/coordinate "implement user authentication with JWT"
```

**After**:
```bash
/plan "implement user authentication with JWT"
```

**Benefits**: Explicit intent, slightly faster

### Scenario 3: Implementation Only
**Before**:
```bash
/coordinate "implement features in existing plan at <path>"
```

**After**:
```bash
/build <plan-path>
```

**Benefits**: Auto-resume, clearer interface

---

## Best Practices

### 1. Choose the Right Abstraction Level
- **Dedicated commands**: When you know the workflow type
- **/coordinate**: When workflow type unclear or learning system

### 2. Use Complexity Appropriately
- Start with defaults (complexity 2-3)
- Increase for unfamiliar topics or complex systems
- Complexity 4 uses hierarchical supervision (slower but more thorough)

### 3. Leverage Auto-Resume
```bash
# /build automatically finds most recent plan
/build

# Saves typing plan paths repeatedly
```

### 4. Chain Commands for Custom Workflows
- More control than single comprehensive command
- Review intermediate outputs before proceeding
- Easier to debug workflow issues

### 5. Use Dry-Run for Preview
```bash
# Preview /build execution without running
/build --dry-run

# See phase structure and dependencies
```

---

## Troubleshooting

### "No plan file found"
**Problem**: `/build` can't find plan to implement
**Solution**: Create plan first with `/plan` or `/plan`

### "Workflow classification taking too long"
**Problem**: `/coordinate` classification overhead
**Solution**: Use dedicated command (e.g., `/plan` instead of `/coordinate`)

### "Plan path extraction failed"
**Problem**: `/revise` can't parse plan path
**Solution**: Ensure path format correct:
```bash
# ✓ Correct
/revise "revise plan at ./path/to/plan.md based on findings"

# ✗ Incorrect
/revise "revise my plan using new findings"
```

### "Tests failing in /build"
**Problem**: Implementation has test failures
**Solution**: `/build` automatically transitions to debug phase
```bash
# Review debug analysis from /build output
# Apply fixes
# Re-run from test phase
/build <plan-path> 2
```

---

## Summary

**Use dedicated commands** (`/research`, `/plan`, `/revise`, `/build`, `/debug`) when:
- You know the workflow type you need
- You want 5-10s faster execution
- You prefer explicit, clear command names

**Use /coordinate** when:
- Unsure which workflow type needed
- Learning the system
- Want maximum flexibility
- Prefer single command interface

All commands share the same underlying infrastructure (state machine, agent delegation, verification checkpoints) - the difference is primarily in interface and workflow classification latency.
