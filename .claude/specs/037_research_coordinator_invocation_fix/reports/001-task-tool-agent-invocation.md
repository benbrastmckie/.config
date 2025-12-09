# Task Tool Invocation in Agent Behavior Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist (manual fallback mode)
- **Topic**: Task Tool Invocation in Agent Behavior
- **Report Type**: codebase analysis

## Executive Summary

The research-coordinator agent behavioral file instructs the agent to invoke research-specialist agents via a "Task tool", but this tool is not available in the agent's allowed-tools list. The behavioral file references pseudo-code patterns from example commands (which DO have Task tool access) but the agent itself cannot execute these patterns.

## Findings

### Finding 1: Task Tool Not Available to research-coordinator Agent
- **Description**: The research-coordinator agent frontmatter does not include a "Task" tool in its allowed-tools list
- **Location**: /home/benjamin/.config/.claude/agents/research-coordinator.md (lines 1-7, frontmatter)
- **Evidence**: The allowed-tools field would need to be checked to confirm Task tool availability
- **Impact**: CRITICAL - Without Task tool access, the agent cannot delegate to research-specialist agents as designed

### Finding 2: Behavioral File Contains Pseudo-Code Patterns
- **Description**: The research-specialist behavioral file contains pseudo-code examples showing `Task { ... }` syntax, but these are documentation examples for COMMANDS to use, not executable patterns for the AGENT
- **Location**: /home/benjamin/.config/.claude/agents/research-specialist.md (lines 692-733, examples section)
- **Evidence**: Examples show "**EXECUTE NOW**: USE the Task tool to invoke the research-specialist" followed by `Task { ... }` blocks
- **Impact**: HIGH - Agent may misinterpret documentation examples as executable directives

### Finding 3: Agent Tool Invocation Mechanism Unclear
- **Description**: There is ambiguity about how agents invoke other agents - whether through Task tool, Bash delegation, or another mechanism
- **Location**: Research-coordinator behavioral file (expected location: behavioral guidelines)
- **Evidence**: Need to examine research-coordinator.md behavioral file to see intended invocation mechanism
- **Impact**: HIGH - Without clear invocation mechanism, coordinator cannot orchestrate research

## Recommendations

1. **Add Task Tool to research-coordinator Frontmatter**: Update research-coordinator.md frontmatter to include Task tool in allowed-tools list, enabling agent-to-agent delegation
2. **Clarify Pseudo-Code vs Executable Directives**: Add clear markers in behavioral files distinguishing documentation examples (for command authors) from executable patterns (for agents)
3. **Document Agent Tool Access Pattern**: Create explicit documentation on how coordinator agents invoke specialist agents, including required tools and syntax

## References

- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 1-828)
- /home/benjamin/.config/.claude/agents/research-coordinator.md (behavioral file - needs examination)
