# Skills Integration Patterns Research Report

## Executive Summary

This research examines skills integration patterns in the Claude Code codebase. The system currently uses a behavioral injection pattern where agents are invoked via the Task tool with `subagent_type: "general-purpose"`, reading behavioral guidelines from `.claude/agents/*.md` files. This architecture provides clear separation between orchestration (commands) and execution (agents). Skills would extend this pattern with capability-specific modules invoked through similar mechanisms, but requiring registration, discovery, and context management systems. Key findings identify integration touchpoints in command files (.claude/commands/), agent behavioral files (.claude/agents/), and utility libraries (.claude/lib/).

## Current Agent Architecture

### Behavioral Injection Pattern

The codebase implements behavioral injection where commands pre-calculate paths, invoke agents via Task tool, and verify outputs (.claude/docs/concepts/patterns/behavioral-injection.md:1-352). Commands act as orchestrators calculating artifact locations, while agents execute work using Read/Write/Edit tools. This separation prevents role ambiguity and enables hierarchical multi-agent coordination.

### Agent Invocation Mechanism

Commands invoke agents using this pattern (.claude/commands/research.md:169-209):
- Load agent behavioral prompt from `.claude/agents/[agent-name].md`
- Inject task-specific context (paths, requirements, standards)
- Use Task tool with `subagent_type: "general-purpose"`
- Agents read behavioral guidelines and execute tasks
- Return metadata only (path + 50-word summary, not full content)

### Agent Registry System

The agent registry provides discovery and loading utilities (.claude/commands/example-with-agent.md:10-202):
- Agent files located in `.claude/agents/` (project) or `~/.config/.claude/agents/` (global)
- Frontmatter defines allowed-tools and description
- Registry functions: `get_agent()`, `list_agents()`, `validate_agent()`
- Caching for performance, project overrides global agents

## Skills Integration Touchpoints

### 1. Command Integration

Commands would invoke skills using similar patterns to agents (.claude/commands/research.md:169-209). Skills could be referenced in command behavioral prompts with:
- Skill discovery: List available skills matching task requirements
- Skill invocation: Task tool with skill-specific context injection
- Skill verification: Verify skill outputs meet acceptance criteria

### 2. Context Management

Skills must integrate with existing context reduction patterns (.claude/docs/concepts/patterns/context-management.md:1-290):
- Metadata-only returns (95-99% context reduction)
- Forward message pattern (no re-summarization)
- Layered context architecture (permanent, phase-scoped, metadata, transient)
- Checkpoint-based state storage
- Target: <30% context usage throughout workflows

### 3. Utility Library Integration

Skills would interact with existing utilities (.claude/lib/agent-loading-utils.sh:1-247):
- `load_agent_behavioral_prompt()` - Similar function for skills
- `get_next_artifact_number()` - Consistent NNN numbering
- `verify_artifact_or_recover()` - Path validation and recovery
- Context pruning utilities for skill outputs

## Skill Discovery and Registration

### Registration Requirements

Based on agent registration patterns (.claude/lib/agent-loading-utils.sh), skills would need:
- Skill definition files in `.claude/skills/` directory structure
- YAML frontmatter with metadata (name, description, capabilities, allowed-tools)
- Registration system similar to agent registry
- Discovery functions for capability-based search

### Discovery Patterns

Skills discovery would support (.claude/commands/example-with-agent.md:140-163):
- List all available skills: `list_skills()`
- Validate skill exists: `validate_skill(skill_name)`
- Get skill metadata: `get_skill_info(skill_name)`
- Get skill capabilities: `get_skill_capabilities(skill_name)`
- Search by capability: `find_skills_by_capability(capability_pattern)`

## Integration Examples

### Example 1: Command Invoking Skill

```markdown
### Step 2: Invoke PDF Conversion Skill

Task {
  subagent_type: "general-purpose"
  description: "Convert markdown to PDF using pdf-converter skill"
  prompt: "
    Read and follow skill guidelines from:
    /home/benjamin/.config/.claude/skills/pdf-converter.md

    Task: Convert markdown files to PDF format
    Input: specs/042_auth/reports/001_patterns.md
    Output: specs/042_auth/reports/001_patterns.pdf

    Requirements:
    - Preserve formatting and code blocks
    - Include table of contents
    - Apply project styling
  "
}
```

### Example 2: Hierarchical Skill Coordination

```markdown
# Multi-format conversion workflow
Task { # xlsx-reader skill extracts data }
Task { # data-transformer skill processes data }
Task { # pdf-generator skill creates report }
```

## Recommendations

1. **Create Skills Registry System**: Implement `.claude/lib/skills-registry.sh` mirroring agent-loading-utils.sh structure with skill discovery, validation, and capability-based search functions.

2. **Define Skills Directory Structure**: Establish `.claude/skills/` directory with subdirectories by capability domain (converters/, analyzers/, integrations/) and standardized frontmatter format.

3. **Integrate Context Management**: Skills must return metadata-only outputs compatible with existing context reduction patterns, using extract_skill_metadata() utilities.

4. **Implement Skill Invocation Pattern**: Extend behavioral injection pattern to support skills with Task tool invocations reading skill behavioral guidelines from `.claude/skills/*.md` files.

5. **Add Skill Verification Checkpoints**: Implement verification functions similar to verify_artifact_or_recover() for skill outputs with fallback recovery mechanisms.

## References

- Behavioral Injection Pattern: .claude/docs/concepts/patterns/behavioral-injection.md:1-352
- Agent Development Guide: .claude/docs/guides/agent-development-guide.md:1-884
- Using Agents Guide: .claude/docs/guides/using-agents.md:1-739
- Context Management Pattern: .claude/docs/concepts/patterns/context-management.md:1-290
- Agent Loading Utilities: .claude/lib/agent-loading-utils.sh:1-247
- Research Command Example: .claude/commands/research.md:169-209
- Example Agent Invocation: .claude/commands/example-with-agent.md:10-202
