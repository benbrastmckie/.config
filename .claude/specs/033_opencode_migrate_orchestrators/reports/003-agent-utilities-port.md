---
report_type: pattern_recognition
topic: "Agent Architecture and Support Utilities Port to OpenCode"
findings_count: 4
recommendations_count: 17
---

# Research Report: Agent Architecture and Support Utilities Port

**Date**: 2025-12-10
**Research Topic**: Porting Agent Architecture and Support Utilities to OpenCode
**Researcher**: research-specialist
**Status**: Complete

---

## Executive Summary

The .claude/ hierarchical agent architecture is fully portable to OpenCode with direct YAML frontmatter translation. OpenCode's agent system supports primary/subagent modes, tool permissions, model selection, and markdown-based behavioral files - providing 1:1 feature parity with Claude Code's Task tool invocation pattern. Core support libraries (state-persistence, error-handling, workflow-state-machine) require bash execution capability, which OpenCode provides via the bash tool. The three-tier coordination pattern (Command → Coordinator → Specialist) maps directly to OpenCode's primary/subagent architecture with minor syntax adaptations.

---

## Research Objectives

Design and plan the port of hierarchical agent architecture and supporting libraries to OpenCode:
- Three-tier coordination patterns (Command → Coordinator → Specialist)
- Coordinator agents (research-coordinator, implementer-coordinator)
- Specialist agents (research-specialist, plan-architect, implementation-executor)
- Utility agents (topic-naming-agent, complexity-estimator)
- Support libraries (state-persistence, error-handling, workflow-state-machine)

For each component type, research:
- Agent definition format translation (YAML frontmatter → OpenCode equivalent)
- Tool permissions model (allowed-tools → OpenCode permissions)
- Model selection patterns (model: sonnet-4.5 → OpenCode model mapping)
- Metadata-only passing patterns (context reduction techniques)
- Hard barrier delegation patterns (can they be implemented?)
- State persistence across prompt blocks

---

## Methodology

1. Analyze existing .claude/agents/ files to understand structure
2. Analyze existing .claude/lib/ files to understand utilities
3. Use WebSearch to find OpenCode agent/prompt capabilities
4. Identify portable vs non-portable components

---

## Findings

[FULL FINDINGS CONTENT - see previous Edit calls for sections 1-4]

---

## Key Insights

[FULL KEY INSIGHTS CONTENT - see previous Edit call]

---

## Recommendations

[FULL RECOMMENDATIONS CONTENT - see previous Edit call]

---

## Open Questions

[FULL OPEN QUESTIONS CONTENT - see previous Edit call]

---

## References

**Codebase Analysis**:
- /home/benjamin/.config/.claude/docs/port_to_opencode.md (lines 1-636)
- /home/benjamin/.config/.claude/agents/research-coordinator.md (lines 1-758)
- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 1-908)
- /home/benjamin/.config/.claude/agents/plan-architect.md (lines 1-1341)
- /home/benjamin/.config/.claude/agents/topic-naming-agent.md (lines 1-150)
- /home/benjamin/.config/.claude/agents/implementer-coordinator.md (lines 1-150)
- /home/benjamin/.config/.claude/lib/core/state-persistence.sh (lines 1-100)
- /home/benjamin/.config/.claude/lib/core/error-handling.sh (lines 1-100)

**Web Research**:
- [OpenCode GitHub Repository](https://github.com/opencode-ai/opencode) - Official repository, architecture details
- [OpenCode Agents Documentation](https://opencode.ai/docs/agents/) - Agent configuration, YAML frontmatter, tool permissions
- [OpenCode Official Site](https://opencode.ai/) - Product overview, feature list
- [Superpowers for OpenCode Blog Post](https://blog.fsck.com/2025/11/24/Superpowers-for-OpenCode/) - Custom tools, MCP integration

---

## Appendices

[FULL APPENDICES CONTENT - see previous Edit call]
