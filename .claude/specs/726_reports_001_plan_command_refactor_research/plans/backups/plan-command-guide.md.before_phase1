# /plan Command - Complete Guide

**Executable**: `.claude/commands/plan.md`

**Quick Start**: Run `/plan "<feature description>" [report-path1] [report-path2]` - creates implementation plans guided by research reports.

---

## Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
3. [Research Delegation](#research-delegation)
4. [Complexity Analysis](#complexity-analysis)
5. [Standards Integration](#standards-integration)
6. [Plan Structure](#plan-structure)
7. [Troubleshooting](#troubleshooting)

---

## Overview

The `/plan` command creates comprehensive implementation plans following project standards, optionally incorporating insights from research reports.

### Key Capabilities

- **Feature complexity pre-analysis**: Estimates complexity and suggests structure before planning
- **Automatic research delegation**: Invokes research agents for complex features
- **Standards discovery**: Extracts and applies project standards from CLAUDE.md
- **Report integration**: Incorporates findings from research reports
- **Topic-based organization**: Creates organized spec directories with numbered topics
- **Metadata-rich plans**: Includes complexity scores, dependencies, success criteria

### When to Use

- Create implementation plans for new features
- Plan refactoring or architecture changes
- Document complex bug fixes requiring multiple phases
- Integrate research findings into actionable plans

---

## Usage

### Basic Syntax

```bash
/plan "<feature description>" [report-path1] [report-path2] ...
```

### Arguments

- **feature description** (required): Clear description of what to implement
- **report-path** (optional): Paths to research reports in `specs/reports/*.md`

### Examples

```bash
# Simple feature
/plan "Add user authentication with JWT"

# With research report
/plan "Migrate database to PostgreSQL" specs/042_db/reports/001_migration_analysis.md

# Multiple reports
/plan "Implement caching layer" \
  specs/050_cache/reports/001_redis_analysis.md \
  specs/050_cache/reports/002_performance_benchmarks.md
```

---

## Research Delegation

For complex features, the command automatically delegates research to specialized agents.

### Complexity Triggers

Research delegation activates when:
1. **Estimated complexity ≥7** (from feature description analysis)
2. **Keywords detected**: integrate, migrate, refactor, architecture
3. **Manual flag**: `--force-research`

### Research Workflow

```
┌─────────────────────────────────────────┐
│ Feature Description Analysis            │
│ → Complexity Score Calculated           │
└─────────────────────────────────────────┘
                 │
                 ▼
         Triggers Met?
         (complexity ≥7)
                 │
         ┌───────┴───────┐
         │               │
         ▼               ▼
        YES             NO
         │               │
         │               └──→ Skip to Phase 1
         │
         ▼
┌─────────────────────────────────────────┐
│ Invoke research-specialist agents       │
│ → 2-3 parallel research threads         │
│ → Create research reports                │
│ → Extract metadata                       │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Integrate research into plan            │
│ → Use findings for phase design          │
│ → Reference reports in metadata          │
└─────────────────────────────────────────┘
```

### Research Agent Invocation

When triggered, the command invokes research-specialist agents:

```
Task {
  subagent_type: "general-purpose"
  description: "Research <aspect> for <feature>"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md
    
    You are acting as a Research Specialist Agent.
    
    Research: <specific aspect>
    Feature: <feature description>
    Focus: <research focus area>
    
    Create report at: specs/{TOPIC_DIR}/reports/{NNN}_research.md
    Return metadata only (path + 50-word summary + key findings).
}
```

### Benefits of Research Delegation

- **95% context reduction**: Metadata-only passing (2000 tokens → 100 tokens)
- **Parallel research**: 2-3 simultaneous research threads
- **Comprehensive coverage**: Multiple aspects researched in parallel
- **Informed planning**: Research findings integrated into plan design

---

## Complexity Analysis

### Feature Description Complexity Pre-Analysis

Before creating the plan, analyzes the feature description to estimate complexity.

**Analysis Factors:**
- Keyword complexity weights (integrate: +2, migrate: +2, refactor: +1.5, architecture: +2)
- Scope indicators (multiple, across, all: +1 each)
- Uncertainty markers (maybe, possibly, consider: -0.5 each)
- Technical depth indicators (API, database, authentication, performance: +1 each)

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COMPLEXITY PRE-ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Estimated complexity: 7.5 (High)
Recommended structure: single-file (expand if needed)
Suggested phases: 5-7
Matching templates: database-migration, architecture-refactor

Recommendations:
- Consider using /plan-from-template for faster planning
- High complexity suggests research delegation
- All plans start as single-file regardless of complexity
- Use /expand phase during implementation if phases prove complex

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Plan Complexity Calculation

After requirements analysis, calculates final plan complexity:

```bash
COMPLEXITY_SCORE=$(calculate_plan_complexity "$REQUIREMENTS" "$PHASE_COUNT")
```

**Calculation Factors:**
- Base complexity from feature description
- Number of phases (more phases = higher complexity)
- Requirements breadth (number of distinct requirements)
- Integration points (dependencies on other systems)
- Risk factors (breaking changes, data migrations)

**Complexity Ranges:**
- **0-3**: Simple feature (1-3 phases, straightforward implementation)
- **4-6**: Medium feature (4-5 phases, some integration)
- **7-9**: Complex feature (6+ phases, significant integration)
- **10+**: Very complex (multi-system changes, architecture refactor)

---

## Standards Integration

### Standards Discovery

The command discovers and applies project standards from CLAUDE.md.

**Discovery Process:**
1. Search upward from working directory for CLAUDE.md
2. Check for subdirectory-specific CLAUDE.md files
3. Extract relevant sections: Code Standards, Testing Protocols, Documentation Policy
4. Capture standards file path in plan metadata

**Standards Sections Used:**
- **Code Standards**: Indentation, naming conventions, error handling patterns
- **Testing Protocols**: Test commands, coverage requirements, test patterns
- **Documentation Policy**: Documentation structure and requirements
- **Directory Protocols**: Spec directory organization, artifact lifecycle

### Standards Application in Plans

**Plan Metadata:**
```markdown
## Metadata
- **Standards File**: /path/to/CLAUDE.md
- **Code Standards**: 2-space indent, snake_case, pcall error handling
- **Testing**: :TestSuite, ≥80% coverage
- **Documentation**: README per directory, inline comments for complex logic
```

**Phase Tasks:**
```markdown
#### Tasks
- [ ] Implement feature following Code Standards (2-space indent, snake_case)
- [ ] Add tests per Testing Protocols (:TestSuite, ≥80% coverage)
- [ ] Create documentation per Documentation Policy (README, inline comments)
```

### Fallback Behavior

When CLAUDE.md not found:
1. Use sensible language-specific defaults
2. Note in plan metadata: "Standards File: Not found (using defaults)"
3. Suggest running `/setup` to create CLAUDE.md
4. Continue with reduced standards enforcement

---

## Plan Structure

### Uniform Plan Template

All plans follow a uniform structure regardless of complexity:

```markdown
# Implementation Plan: <Feature Name>

## Metadata
- **Plan ID**: NNN
- **Date Created**: YYYY-MM-DD
- **Type**: [Architecture/Feature/Bugfix/Refactor]
- **Scope**: Brief scope description
- **Priority**: [HIGH/MEDIUM/LOW]
- **Complexity**: N/10
- **Estimated Duration**: N hours
- **Standards File**: /path/to/CLAUDE.md
- **Related Specs**: []
- **Structure Level**: 0 (Single-file)

## Executive Summary

### Problem Statement
What problem does this solve?

### Solution Overview
High-level solution approach

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

### Benefits
Key benefits of implementing this

---

## Implementation Phases

### Phase N: Phase Name

**Objective**: What this phase accomplishes

**Dependencies**: [Phase numbers or "None"]

**Complexity**: N/10

**Duration**: N hours

#### Tasks

- [ ] Task 1
- [ ] Task 2

#### Deliverables

1. Deliverable 1
2. Deliverable 2

#### Success Criteria

- [ ] Criterion 1
- [ ] Criterion 2

---

## Rollback Strategy

How to rollback if issues occur

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Risk 1 | Low/Medium/High | Low/Medium/High | How to mitigate |

---

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Metric 1 | Target | How to measure |

---

## Completion Criteria

This plan is complete when:
1. Criterion 1
2. Criterion 2
```

### Topic-Based Organization

Plans are organized in topic-based directories:

```
specs/
├── 001_authentication/
│   ├── plans/
│   │   └── 001_implementation_plan.md
│   ├── reports/
│   │   └── 001_research.md
│   └── summaries/
│       └── 001_implementation_summary.md
├── 042_database_migration/
│   ├── plans/
│   │   └── 042_implementation_plan.md
│   └── reports/
│       ├── 042_migration_analysis.md
│       └── 042_performance_benchmarks.md
└── SPECS.md
```

### Progressive Plan Levels

Plans support three structure levels:

- **Level 0** (Single-file): All phases inline (default for all new plans)
- **Level 1** (Phase-expanded): Complex phases in separate files (created via `/expand phase`)
- **Level 2** (Stage-expanded): Stages in separate files (created via `/expand stage`)

**Note**: All plans start as Level 0 regardless of complexity. Use `/expand` during implementation if phases become too complex.

---

## Troubleshooting

### Command Not Creating Plan

**Symptom**: Command runs but no plan file created

**Diagnosis**: Check for errors in plan creation
```bash
# Verify specs directory exists
ls -la specs/

# Check permissions
ls -ld specs/
```

**Solutions:**
- Create specs directory: `mkdir -p specs/plans`
- Fix permissions: `chmod 755 specs`
- Check disk space: `df -h`

### Research Delegation Not Triggering

**Symptom**: Complex feature but no research agents invoked

**Diagnosis**: Check complexity score
```bash
source .claude/lib/complexity-utils.sh
ANALYSIS=$(analyze_feature_description "your feature description")
echo "$ANALYSIS" | jq
```

**Solutions:**
- Complexity < 7 → Not triggered (expected)
- Add complexity keywords: integrate, migrate, refactor, architecture
- Use manual flag: `/plan "feature" --force-research`

### Standards Not Discovered

**Symptom**: Plan created but no standards file referenced

**Diagnosis**: Check CLAUDE.md location
```bash
find . -name "CLAUDE.md" -type f
```

**Solutions:**
- Create CLAUDE.md: `/setup`
- Move CLAUDE.md to project root or parent directory
- Check file permissions: `ls -l CLAUDE.md`

### Plan Complexity Seems Wrong

**Symptom**: Complexity score doesn't match expectation

**Diagnosis**: Review complexity calculation
```bash
source .claude/lib/complexity-utils.sh
# Check feature description analysis
ANALYSIS=$(analyze_feature_description "your description")
echo "$ANALYSIS" | jq '.estimated_complexity'
```

**Solutions:**
- Add technical keywords to increase complexity (API, database, authentication)
- Remove uncertainty markers to increase confidence (maybe, possibly)
- Simplify feature description to reduce complexity
- Manual override in plan metadata after creation

---

## See Also

- [/implement Command Guide](implement-command-guide.md) - Executing implementation plans
- [/research Command Guide](research-command-guide.md) - Creating research reports
- [/expand Command Guide](expand-command-guide.md) - Expanding phases/stages
- [/plan-from-template Command](../commands/plan-from-template.md) - Template-based planning
- [Directory Protocols](../concepts/directory-protocols.md) - Spec directory organization
- [Command Development Guide](command-development-guide.md)
