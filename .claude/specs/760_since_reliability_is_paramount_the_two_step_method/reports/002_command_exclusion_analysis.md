# Command Exclusion Analysis for Two-Step Pattern Migration

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Plan revision insights for excluding debug.md, implement.md, plan.md, research.md, and revise.md commands
- **Report Type**: codebase analysis

## Executive Summary

This report analyzes the impact of excluding 5 commands from the two-step argument pattern migration: debug.md, implement.md, plan.md, research.md, and revise.md. These are the most complex workflow orchestrator commands in the system. Of the original 13 commands requiring migration, 8 commands remain to be migrated. The exclusions are strategically sound as they focus the migration on simpler commands while deferring the highest-risk conversions. The library design remains valid and can still benefit the 8 remaining commands.

## Findings

### 1. Commands to Exclude from Migration (5 Commands)

The following 5 commands will be excluded from the two-step pattern migration:

| Command | File | Complexity | Reason for Exclusion |
|---------|------|------------|----------------------|
| `/debug` | debug.md:68 | Medium | Workflow orchestrator with multi-phase investigation and parallel hypothesis testing |
| `/implement` | implement.md:60-78 | High | Complex plan executor with 5+ flags, auto-resume, agent delegation |
| `/plan` | plan.md:128-170 | Medium | Primary planning orchestrator with Haiku classifier and research delegation |
| `/research` | research.md | Medium | Hierarchical multi-agent research orchestrator with 7+ steps |
| `/revise` | revise.md:29 | High | Supports both interactive and auto-mode with JSON context |

#### Detailed Exclusion Analysis

**1. debug.md**
- **Current Pattern**: Direct $1 capture at line 68: `ISSUE_DESCRIPTION="$1"`
- **Complexity Score**: Medium (multiple arguments + context reports)
- **Exclusion Rationale**: The debug command has 6 phases with bash blocks, parallel hypothesis investigation via Task tool, and state persistence. Converting this adds risk with limited benefit since it's already well-tested.

**2. implement.md**
- **Current Pattern**: Direct $1 capture at line 60 with complex flag parsing (lines 60-78)
- **Complexity Score**: High (multiple positional args + 5 flags: --dashboard, --dry-run, --create-pr, --report-scope-drift, --force-replan)
- **Exclusion Rationale**: The most critical workflow command. It has auto-resume from checkpoints, hybrid complexity evaluation, agent delegation patterns, and error recovery with tiered handling. Any regression here affects plan execution.

**3. plan.md**
- **Current Pattern**: Direct $1 capture at line 128: `FEATURE_DESCRIPTION="$1"` plus report paths array
- **Complexity Score**: Medium (primary argument + array of optional report paths)
- **Exclusion Rationale**: Primary entry point for plan creation with Haiku subagent classification (Phase 1), research delegation (Phase 1.5), and standards discovery (Phase 2). Complex state management via workflow-state-machine.sh integration.

**4. research.md**
- **Current Pattern**: Uses `$ARGUMENTS` template variable (not direct $1)
- **Complexity Score**: Medium (hierarchical orchestrator pattern)
- **Exclusion Rationale**: Different pattern - uses `$ARGUMENTS` template variable, not $1 capture. The command orchestrates research-specialist subagents in parallel with 7 steps and complex path pre-calculation.

**5. revise.md**
- **Current Pattern**: Direct argument parsing at lines 48-59 with mode detection
- **Complexity Score**: High (supports interactive and auto-mode with JSON context)
- **Exclusion Rationale**: Dual-mode command supporting both interactive revision and automated invocation from /implement. The auto-mode uses --context JSON which requires careful parsing.

### 2. Commands to Keep in Migration (8 Commands)

The following 8 commands will still be migrated to the two-step pattern:

| Command | File | Original Complexity | New Migration Complexity |
|---------|------|---------------------|--------------------------|
| `/fix` | fix.md:30 | Low | Low |
| `/research-report` | research-report.md:29 | Low | Low |
| `/research-plan` | research-plan.md:30 | Low | Low |
| `/research-revise` | research-revise.md:30 | Medium | Medium |
| `/expand` | expand.md | Medium | Medium |
| `/collapse` | collapse.md | Medium | Medium |
| `/setup` | setup.md:31 | Medium | Medium |
| `/convert-docs` | convert-docs.md | Medium | Medium |
| `/build` | build.md:70 | High | High |

**Note**: `/build` is retained because it has simpler execution flow than `/implement` despite similar flag structure.

### 3. Impact on Plan Phases

The original plan had 6 phases. With exclusions, the phases are modified as follows:

**Phase 1: Foundation - Library Creation**
- **Impact**: None - library design unchanged
- **Status**: Proceed as planned

**Phase 2: Testing - Library Test Suite**
- **Impact**: Reduced test cases needed for complex command patterns
- **Status**: Proceed as planned, reduce test cases for excluded patterns

**Phase 3: Simple Commands Migration**
- **Original Commands**: /fix, /research-report, /research-plan
- **Remaining Commands**: /fix, /research-report, /research-plan
- **Impact**: None - all simple commands retained
- **Status**: Proceed as planned

**Phase 4: Medium Commands Migration**
- **Original Commands**: /plan, /debug, /research-revise, /expand, /collapse, /convert-docs
- **Remaining Commands**: /research-revise, /expand, /collapse, /convert-docs
- **Commands Excluded**: /plan, /debug
- **Impact**: Phase reduced from 6 to 4 commands (33% reduction)
- **Status**: Reduced scope, lower risk

**Phase 5: Complex Commands Migration**
- **Original Commands**: /implement, /build, /revise, /setup
- **Remaining Commands**: /build, /setup
- **Commands Excluded**: /implement, /revise
- **Impact**: Phase reduced from 4 to 2 commands (50% reduction)
- **Status**: Significantly reduced scope and risk

**Phase 6: Documentation Updates**
- **Impact**: Reduced examples needed, but still valuable
- **Status**: Proceed as planned, update examples to use retained commands

### 4. Library Design Impact

The `argument-capture.sh` library design remains valid but will serve fewer commands:

**Functions Still Required**:
- `capture_argument_part1()` - Still needed for 8 commands
- `capture_argument_part2()` - Still needed for 8 commands
- `cleanup_argument_files()` - Still needed

**Usage Pattern Remains Valid**:
- Simple commands will use basic pattern
- Medium commands will use pattern with array handling
- Build command will demonstrate complex flag handling

**Potential Simplification**:
- Library can potentially be simplified since most complex patterns (implement, plan, revise) are excluded
- May not need the most sophisticated error handling patterns

### 5. Risk Analysis with Exclusions

| Risk Factor | Original Risk | Risk with Exclusions |
|------------|---------------|---------------------|
| Regression in critical workflows | High | Low (excluded from migration) |
| Backward compatibility issues | Medium | Low (fewer commands affected) |
| User friction with new workflow | Medium | Low (fewer commands to learn) |
| Implementation time | 14-18 hours | 8-12 hours (estimated) |
| Testing complexity | High | Medium |

### 6. Commands Not in Original Migration (Baseline)

For reference, these commands were already not in the migration scope:

| Command | File | Reason Not in Scope |
|---------|------|---------------------|
| `/coordinate` | coordinate.md | Already uses two-step pattern (canonical reference) |
| `/research` | research.md | Uses $ARGUMENTS template, now explicitly excluded |
| `/optimize-claude` | optimize-claude.md | No user arguments |
| README.md | README.md | Not a command |

## Recommendations

### Recommendation 1: Update Plan Phases to Reflect Exclusions

Modify the implementation plan to:
- Remove /plan, /debug from Phase 4 task lists
- Remove /implement, /revise from Phase 5 task lists
- Update success criteria to reflect 8 commands instead of 13
- Revise time estimates downward (8-12 hours instead of 14-18)

**Priority**: P0 - Must be done before implementation begins

### Recommendation 2: Retain /build in Complex Commands Phase

Although /build has similar complexity to /implement, retain it because:
- It has simpler auto-resume logic
- Demonstrates complex flag handling pattern
- Lower risk if regression occurs (less critical than /implement)

**Priority**: P1 - Validate assumption during implementation

### Recommendation 3: Document Exclusion Rationale in Plan

Add a "Scope Exclusions" section to the plan explaining:
- Which commands are excluded and why
- Future migration potential (these commands can be migrated later)
- Current argument handling patterns remain stable

**Priority**: P1 - Helps future maintainers understand decisions

### Recommendation 4: Simplify Library for Reduced Scope

Consider simplifying the library since complex patterns are excluded:
- Remove or defer most sophisticated error handling
- Simplify concurrent execution handling
- Focus on patterns needed by the 8 retained commands

**Priority**: P2 - Optional optimization

### Recommendation 5: Create Migration Priority Matrix

Document the migration order for retained commands:

**Wave 1 (Low Risk)**: /fix, /research-report, /research-plan
**Wave 2 (Medium Risk)**: /research-revise, /expand, /collapse, /convert-docs
**Wave 3 (Higher Risk)**: /build, /setup

**Priority**: P1 - Guides implementation order

### Recommendation 6: Future Migration Path

Document that excluded commands can be migrated in a future effort:
- After the 8-command migration proves stable
- With lessons learned from simpler commands
- As part of a dedicated spec (e.g., "760_phase2_complex_command_migration")

**Priority**: P3 - For future planning

## Summary Table

| Category | Original Plan | After Exclusions |
|----------|---------------|------------------|
| Total commands to migrate | 13 | 8 |
| Phase 3 (Simple) | 3 commands | 3 commands |
| Phase 4 (Medium) | 6 commands | 4 commands |
| Phase 5 (Complex) | 4 commands | 2 commands |
| Estimated hours | 14-18 | 8-12 |
| Risk level | Medium-High | Low-Medium |

## References

### Analyzed Command Files

- `/home/benjamin/.config/.claude/commands/debug.md:68-74` - Medium complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/implement.md:60-78` - High complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/plan.md:128-170` - Medium complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/research.md` - Uses $ARGUMENTS, EXCLUDED
- `/home/benjamin/.config/.claude/commands/revise.md:29-41` - High complexity, EXCLUDED
- `/home/benjamin/.config/.claude/commands/fix.md:30-56` - Low complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/research-report.md:29-60` - Low complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/research-plan.md:30-61` - Low complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/research-revise.md:30-74` - Medium complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/expand.md:59-100` - Medium complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/collapse.md:80-100` - Medium complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/setup.md:31-61` - Medium complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/convert-docs.md` - Medium complexity, RETAINED
- `/home/benjamin/.config/.claude/commands/build.md:70-80` - High complexity, RETAINED

### Related Documentation

- `/home/benjamin/.config/.claude/specs/760_since_reliability_is_paramount_the_two_step_method/plans/001_since_reliability_is_paramount_the_two_s_plan.md` - Original implementation plan to be revised
- `/home/benjamin/.config/.claude/specs/760_since_reliability_is_paramount_the_two_step_method/reports/001_two_step_pattern_systematic_implementation.md` - Research report with 13-command scope
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md:365-443` - Current argument pattern documentation

### Canonical Reference

- `/home/benjamin/.config/.claude/commands/coordinate.md:18-92` - Two-step pattern implementation reference
