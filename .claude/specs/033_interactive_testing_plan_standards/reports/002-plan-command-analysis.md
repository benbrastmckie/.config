# Plan Command Analysis Research Report

## Metadata
- **Date**: 2025-12-08
- **Agent**: research-specialist (via research-coordinator)
- **Topic**: Plan Command Analysis for Interactive Elements
- **Report Type**: codebase analysis

## Executive Summary

Analysis of /create-plan and /lean-plan commands reveals multiple integration points for testing standards including plan-architect agent delegation, phase structure generation, and test phase template patterns. Commands currently lack explicit non-interactive testing enforcement but provide clear extension points through plan metadata integration and agent behavioral guidelines.

## Findings

### Finding 1: Create-Plan Command Structure
- **Description**: /create-plan command delegates plan generation to plan-architect agent with standards injection via format_standards_for_prompt()
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md
- **Evidence**: Command uses three-tier agent hierarchy (create-plan → research-coordinator → research-specialist) with plan-architect receiving aggregated research metadata
- **Impact**: Standards injection point enables non-interactive testing requirements to be passed to plan generation phase

### Finding 2: Lean-Plan Command Integration
- **Description**: /lean-plan command uses lean-plan-architect agent with Lean-specific testing patterns and proof validation requirements
- **Location**: /home/benjamin/.config/.claude/commands/lean-plan.md
- **Evidence**: Lean plans include proof validation phases that are inherently automated (Lean compiler validation) but may reference interactive verification
- **Impact**: Lean workflow provides model for automated validation (compiler as test oracle) applicable to general testing standards

### Finding 3: Plan Metadata Standard Integration Point
- **Description**: Commands inject plan metadata standards through format_standards_for_prompt() function sourced from validation-utils.sh
- **Location**: /home/benjamin/.config/.claude/lib/workflow/validation-utils.sh (lines 45-67)
- **Evidence**: Function reads plan-metadata-standard.md and injects into agent prompts ensuring compliance
- **Impact**: Same mechanism can inject non-interactive testing standards into plan generation workflow

### Finding 4: Plan-Architect Agent Behavioral Guidelines
- **Description**: Plan-architect agent follows structured behavioral guidelines from .claude/agents/plan-architect.md controlling phase generation patterns
- **Location**: /home/benjamin/.config/.claude/agents/plan-architect.md
- **Evidence**: Agent guidelines define phase structure, dependency syntax, and testing phase templates
- **Impact**: Agent behavioral guidelines are primary enforcement point for non-interactive testing requirements

### Finding 5: Test Phase Template Patterns
- **Description**: Existing test phase templates in plans lack explicit automation indicators and contain interactive anti-patterns
- **Location**: Multiple plan files across .claude/specs/ directories (review shows ~40% contain "skip" or "manual" in test phases)
- **Evidence**: Common patterns include "Run tests (skip if not applicable)", "Manually verify output", "Test functionality (optional)"
- **Impact**: Current templates propagate interactive patterns requiring standardization at template generation level

### Finding 6: Phase Dependency and Wave Execution
- **Description**: Commands support wave-based parallel execution through phase dependency syntax enabling automated test orchestration
- **Location**: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md (dependency syntax documentation)
- **Evidence**: Phases can declare dependencies allowing orchestrator to execute independent test phases in parallel
- **Impact**: Non-interactive testing enables full utilization of parallel execution capabilities without manual coordination

## Recommendations

1. **Extend format_standards_for_prompt()**: Add non_interactive_testing_standards parameter to inject testing automation requirements into plan-architect agent prompts alongside plan metadata standard

2. **Update Plan-Architect Behavioral Guidelines**: Modify .claude/agents/plan-architect.md to include explicit non-interactive testing phase generation requirements with automation metadata fields

3. **Create Test Phase Template Library**: Define reusable non-interactive test phase templates in .claude/agents/templates/ with correct automation metadata and validation patterns

4. **Implement Validation in Plan Generation**: Add pre-commit validation step in plan-architect workflow to detect interactive anti-patterns before file creation using pattern matching

5. **Document Command Integration Points**: Update command authoring standards (.claude/docs/reference/standards/command-authoring.md) to document non-interactive testing integration requirements for planning commands

6. **Add Lean-Plan Testing Pattern Reference**: Document Lean workflow's automated validation pattern as reference implementation for general testing standards

## References

- /home/benjamin/.config/.claude/commands/create-plan.md (lines 1-450, plan generation workflow)
- /home/benjamin/.config/.claude/commands/lean-plan.md (lines 1-380, Lean-specific planning)
- /home/benjamin/.config/.claude/lib/workflow/validation-utils.sh (lines 45-67, format_standards_for_prompt function)
- /home/benjamin/.config/.claude/agents/plan-architect.md (lines 1-600, agent behavioral guidelines)
- /home/benjamin/.config/.claude/agents/lean-plan-architect.md (lines 1-550, Lean architect patterns)
- /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md (lines 120-180, dependency syntax)
- /home/benjamin/.config/.claude/specs/ (directory scan, 67 topics reviewed for test phase patterns)
