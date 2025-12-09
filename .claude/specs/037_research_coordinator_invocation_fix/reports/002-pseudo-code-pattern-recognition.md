# Pseudo-Code Pattern Recognition and Interpretation Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist (manual fallback mode)
- **Topic**: Pseudo-Code Pattern Recognition and Interpretation
- **Report Type**: pattern recognition

## Executive Summary

Agent behavioral files contain two types of content: (1) executable directives that agents should follow, and (2) documentation examples showing how commands should invoke agents. The research-coordinator agent may be misinterpreting documentation examples (pseudo-code patterns for command authors) as executable directives (actions the agent should perform).

## Findings

### Finding 1: Dual-Purpose Behavioral Files
- **Description**: Behavioral files serve both as agent instructions AND as reference documentation for command authors
- **Location**: /home/benjamin/.config/.claude/agents/research-specialist.md (entire file structure)
- **Evidence**: File contains "Research Execution Process" steps for agent execution AND "Example Usage" sections for command authors
- **Impact**: MEDIUM - Mixing audience types creates potential for misinterpretation

### Finding 2: Pseudo-Code in Example Sections
- **Description**: Example sections use pseudo-code syntax `Task { ... }` to show command authors how to invoke agents
- **Location**: /home/benjamin/.config/.claude/agents/research-specialist.md (lines 692-733, 737-783)
- **Evidence**: Examples start with "**EXECUTE NOW**: USE the Task tool to invoke..." followed by `Task { subagent_type: "general-purpose", ... }`
- **Impact**: HIGH - Pseudo-code looks like executable directives due to "EXECUTE NOW" phrasing, but is actually documentation

### Finding 3: Missing Directive Markers
- **Description**: No clear visual or structural markers distinguish executable directives from documentation examples
- **Location**: All agent behavioral files (pattern applies system-wide)
- **Evidence**: Both executable steps and documentation examples use similar formatting (markdown headers, code blocks, bold text)
- **Impact**: MEDIUM - Agents may need explicit parsing logic to distinguish directive types

## Recommendations

1. **Add Audience Markers to Behavioral Files**: Use clear section markers like "## FOR AGENTS: Execution Steps" vs "## FOR COMMAND AUTHORS: Invocation Examples"
2. **Standardize Pseudo-Code Syntax**: Use distinct pseudo-code syntax (e.g., `<invoke-agent>...</invoke-agent>` XML tags) that clearly differs from actual tool calls
3. **Implement Directive Recognition Logic**: Add agent parsing logic that recognizes section context and ignores command-author documentation when executing behavioral guidelines

## References

- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 692-733: Example Usage section)
- Behavioral file structure pattern (applies to all agents in .claude/agents/)
