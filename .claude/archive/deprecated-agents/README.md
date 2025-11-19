# Deprecated Agents Archive

## Purpose

This directory contains agent definitions that were archived because they exist only in documentation but are never invoked by any command in the codebase.

## Archived Date

2025-11-18

## Archived Agents

| Agent | Reason | Original Location |
|-------|--------|-------------------|
| github-specialist.md | Never invoked via Task tool | .claude/agents/ |
| metrics-specialist.md | Never invoked via Task tool | .claude/agents/ |
| implementation-researcher.md | Never invoked via Task tool | .claude/agents/ |
| research-synthesizer.md | Never invoked via Task tool | .claude/agents/ |
| implementation-sub-supervisor.md | Never invoked via Task tool | .claude/agents/ |
| testing-sub-supervisor.md | Never invoked via Task tool | .claude/agents/ |
| plan-structure-manager.md | Never invoked via Task tool | .claude/agents/ |
| revision-specialist.md | Never invoked via Task tool | .claude/agents/ |

## Analysis Reference

These agents were identified through comprehensive codebase analysis documented in:
- [Unused Agent Analysis Report](/home/benjamin/.config/.claude/specs/800_claude_agents_readmemd_to_help_identify_these/reports/001_unused_agent_analysis.md)

## Restoration

If any of these agents need to be restored:
1. Move the agent file back to `.claude/agents/`
2. Update `.claude/agents/README.md` to include the agent documentation
3. Add Task tool invocations in relevant commands

## Test Files

The `tests/` subdirectory contains test files that were associated with these archived agents and are no longer relevant.
