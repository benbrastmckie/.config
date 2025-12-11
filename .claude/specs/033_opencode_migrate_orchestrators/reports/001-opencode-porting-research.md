---
report_type: best_practices
topic: "OpenCode Porting Best Practices and Tool Integration"
findings_count: 8
recommendations_count: 7
---

# OpenCode Porting Best Practices and Tool Integration Research Report

## Metadata
- **Date**: 2025-12-10
- **Agent**: research-specialist
- **Topic**: OpenCode Porting Best Practices and Tool Integration
- **Report Type**: best practices

## Executive Summary

OpenCode is an open-source AI coding agent for the terminal with agent/command/tool architecture comparable to Claude Code. Key porting differences include: agent definitions use markdown files with YAML frontmatter (not .md behavioral guidelines), commands use markdown templates with $ARGUMENTS placeholders (not bash blocks), and tool invocation uses AI SDK's streamText with TaskTool for subagent delegation (not Claude's Task tool pseudo-syntax). OpenCode provides equivalent file operations (read/write/edit/glob/grep) and supports bash execution with session state persistence via SQLite.

## Findings

### Finding 1: Agent Definition Format - Markdown Files with YAML Frontmatter
- **Description**: OpenCode agents use markdown files with YAML frontmatter configuration placed in `~/.config/opencode/agent/` (global) or `.opencode/agent/` (project-specific). Agent configuration includes mode (primary/subagent/all), model selection, temperature, maxSteps, tool access control, and permission system.
- **Location**: Reference documentation at https://opencode.ai/docs/agents/
- **Evidence**: Agent definition template:
```markdown
---
description: Agent purpose
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  write: false
  bash: false
permission:
  edit: deny
  bash:
    "git push": "ask"
    "*": "allow"
---
Your system prompt instructions here.
```
- **Impact**: Claude Code agents use behavioral markdown files (e.g., `.claude/agents/research-specialist.md` with 28 completion criteria) read as prompts. OpenCode separates configuration (YAML) from system prompt (markdown body). Porting requires splitting `.claude/agents/*.md` files into YAML frontmatter + prompt body, and mapping `allowed-tools` to OpenCode's `tools` and `permission` options.

### Finding 2: Command Syntax - Template-Based with Special Placeholders
- **Description**: OpenCode commands use markdown files in `~/.config/opencode/command/` or `.opencode/command/` with YAML frontmatter. Commands support argument passing ($ARGUMENTS, $1-$9), bash injection (!command), and file inclusion (@filename). Commands invoke agents via the `agent` config option or `subtask` option for subagent invocation.
- **Location**: Reference documentation at https://opencode.ai/docs/commands/ and configuration details at https://opencode.ai/docs/config/
- **Evidence**: Command definition template:
```yaml
---
description: Brief command description
agent: optional-agent-name
model: optional-model-override
subtask: false
---
Your prompt template here with $ARGUMENTS and @filename references
```
- **Impact**: Claude Code commands use multi-block bash execution with hard barrier pattern (Block 1: Setup, Block 2: Agent Invocation, Block 3: Verification). OpenCode commands are single markdown templates with no bash orchestration. Porting requires either: (1) converting complex command bash logic into JavaScript/TypeScript extensions, (2) implementing orchestration within agent prompts, or (3) using bash tool within prompts for state management (less reliable than Claude's bash blocks).

### Finding 3: Subagent Invocation - TaskTool with Isolated Sessions
- **Description**: OpenCode implements hierarchical agent coordination through a `TaskTool` (available via `task` in tools list) that creates isolated sessions for subagents. Each invocation is stateless with independent context windows. Primary agents can invoke subagents using @general mentions or through task tool calls. The system uses AI SDK's streamText with maxRetries and stopWhen conditions for agentic loops.
- **Location**: Technical implementation analysis at https://cefboud.com/posts/coding-agents-internals-opencode-deepdive/
- **Evidence**: Task delegation pattern description:
> "The agent's outputs should generally be trusted...Each agent invocation is stateless. You will not be able to send additional messages to the agent"
and technical implementation:
> "maxRetries: 3, activeTools: Object.keys(tools), stopWhen: async ({ steps }) => steps.length >= 1000"
- **Impact**: Claude Code's Task tool uses pseudo-syntax (`Task { subagent_type: "general-purpose", prompt: "..." }`) parsed by orchestrators. OpenCode's TaskTool is a native AI SDK tool with JSON schema. Porting requires: (1) migrating hard barrier pattern (Setup/Invoke/Verify blocks) into prompt instructions since bash orchestration is unavailable, (2) implementing metadata-only passing via prompt engineering rather than bash variable persistence, (3) testing stateless subagent design against Claude's context-aware delegation.

### Finding 4: File System Tools - Complete Equivalents Available
- **Description**: OpenCode provides read, write, edit, multiedit, glob, grep, and list tools with capabilities equivalent to Claude Code's Read, Write, Edit, Glob, and Grep tools. The glob tool searches files using patterns like `**/*.js` sorted by modification time. The grep tool supports content search with regex. File operations support permission control via the `permission.external_directory` option for safety.
- **Location**: Reference documentation at https://opencode.ai/docs/tools/ and https://opencode.ai/docs/permissions/
- **Evidence**: Available file tools documented:
> "OpenCode built-in tools include bash command execution, file operations (read, write, edit, multiedit), code search (grep, glob), LSP operations (diagnostics, hover), and web interactions (webfetch, websearch)"
Permission configuration:
```json
{
  "tools": { "write": "ask", "edit": "ask", "bash": "allow" },
  "permission": { "external_directory": "ask" }
}
```
- **Impact**: File operation tools have 1:1 mapping from Claude Code to OpenCode. The 43 bash libraries in `.claude/lib/` that implement state persistence, error handling, and workflow orchestration cannot be directly ported because OpenCode commands lack multi-block bash execution capability. Alternative: implement core library functions in JavaScript/TypeScript as OpenCode extensions or MCP tools.

### Finding 5: State Persistence - SQLite Session Management vs Bash State Files
- **Description**: OpenCode uses SQLite-based session storage with event-driven pub-sub architecture for state persistence. Sessions maintain ordered message sequences, execution state metadata, and relationships. State updates use editor pattern for atomic modifications with exclusive locks. This contrasts with Claude Code's GitHub Actions-style bash state files (`.claude/lib/core/state-persistence.sh` with `init_workflow_state()`, `load_workflow_state()`, `append_workflow_state()`).
- **Location**: Architecture documentation at https://deepwiki.com/sst/opencode/2.1-session-lifecycle-and-state (DeepWiki analysis)
- **Evidence**: Session state description:
> "Session Management is the core state container system in OpenCode that tracks user interactions, AI responses, and execution context across a conversation. Each session maintains an ordered sequence of messages, execution state, metadata, and relationships to other sessions."
And atomic update pattern:
> "Updates use an editor pattern to modify session state atomically. All updates automatically set time.updated and publish Session.Event.Updated. The storage layer ensures atomic writes with exclusive locks."
- **Impact**: Claude Code's state-persistence.sh enables cross-block variable passing in bash-based orchestration (WORKFLOW_ID, STATE variables persist). OpenCode's session-based state is managed at the platform level (not user-accessible bash). Porting requires either: (1) embedding state management in agent prompts using conversation context, (2) implementing external state store accessed via MCP tools, or (3) redesigning workflows to be stateless with metadata passed in prompts.

### Finding 6: Model Selection Mapping - Anthropic Model Equivalents
- **Description**: OpenCode supports multiple AI providers including Anthropic Claude models via the `model` configuration option. Model specification uses provider/model format (e.g., `anthropic/claude-sonnet-4-20250514`, `anthropic/claude-haiku-4-20250514`, `anthropic/claude-opus-4-5`). OpenCode also supports `small_model` configuration for lightweight tasks like title generation, which automatically falls back to main model if unavailable.
- **Location**: Reference documentation at https://opencode.ai/docs/config/ and model selection at https://opencode.ai/docs/agents/
- **Evidence**: Model configuration in agents:
```yaml
model: anthropic/claude-sonnet-4-20250514
temperature: 0.3
```
And small_model fallback documented:
> "The system tries to use a cheaper model if one is available from your provider, otherwise it falls back to your main model."
- **Impact**: Claude Code agents specify model preferences in frontmatter (e.g., `model: sonnet-4.5`, `model: opus-4.1`, `model: haiku-4.5`). OpenCode requires full provider/model string format. Mapping: `sonnet-4.5` → `anthropic/claude-sonnet-4-20250514`, `opus-4.1` → `anthropic/claude-opus-4-5`, `haiku-4.5` → `anthropic/claude-haiku-4-20250514`. The 19 Claude Code agents use model-appropriate task delegation (haiku for lightweight, sonnet for specialists, opus for architects)—this pattern is directly portable.

### Finding 7: Project Configuration - AGENTS.md vs CLAUDE.md
- **Description**: OpenCode uses `AGENTS.md` files for project-specific instructions that customize LLM behavior. Global rules go in `~/.config/opencode/AGENTS.md`, project rules in project root `AGENTS.md`. Both are combined when present. This is OpenCode's equivalent to Claude Code's `CLAUDE.md` standards file or Cursor's rules files.
- **Location**: Reference documentation at https://opencode.ai/docs/rules/
- **Evidence**: Documentation states:
> "You can provide custom instructions to opencode by creating an AGENTS.md file. This is similar to CLAUDE.md or Cursor's rules. It contains instructions that will be included in the LLM's context to customize its behavior for your specific project. You can also have global rules in a ~/.config/opencode/AGENTS.md file. If you have both global and project-specific rules, opencode will combine them together."
- **Impact**: Claude Code's `CLAUDE.md` serves as central configuration index with 15+ standards sections (directory protocols, testing protocols, code standards, hierarchical agent architecture). OpenCode's `AGENTS.md` has equivalent purpose but different structure. Porting requires: (1) converting CLAUDE.md section references into AGENTS.md instructions, (2) determining what should be global (~/.config/opencode/AGENTS.md) vs project-specific, (3) adapting standards that reference bash-specific patterns (three-tier sourcing, state persistence) to JavaScript/TypeScript patterns.

### Finding 8: MCP Integration - Extensibility Beyond Built-in Tools
- **Description**: OpenCode implements Model Context Protocol (MCP) for extending agent capabilities through external tools. MCP servers connect via Stdio or SSE (Server-Sent Events) and are configured in the `mcpServers` section of configuration. OpenCode automatically handles OAuth authentication for remote MCP servers. MCP tools follow OpenCode's standard security model with permission checking, tool execution hooks, and graceful degradation if servers are unavailable.
- **Location**: Reference documentation at https://opencode.ai/docs/mcp-servers/ and technical details at https://deepwiki.com/sst/opencode/5.5-mcp-integration
- **Evidence**: MCP configuration example:
```json
{
  "mcpServers": {
    "server-name": {
      "type": "remote",
      "url": "https://mcp-server.example.com",
      "headers": { "Authorization": "Bearer token" }
    }
  }
}
```
And capability description:
> "MCP enables extending OpenCode's agent without modifying core code through custom file systems (cloud storage, version control), external APIs (web services, databases), domain-specific tools, and development tools (build systems, test runners, or deployment pipelines)."
- **Impact**: Claude Code does not have MCP integration; extensibility comes from bash libraries (43 files) and custom commands. OpenCode's MCP support provides an alternative extensibility path. Porting strategy: implement `.claude/lib/` library functions as MCP tools (e.g., state-persistence.sh → state-management MCP server, error-handling.sh → error-logging MCP server). This enables preserving core functionality while adapting to OpenCode's architecture.

## Recommendations

1. **Implement Core Libraries as MCP Tools (Priority: High)**: Convert the 43 bash libraries in `.claude/lib/` into JavaScript/TypeScript MCP servers that OpenCode agents can invoke. Start with Priority 1 libraries from the porting guide: state-persistence.sh → state-management MCP tool, error-handling.sh → error-logging MCP tool, and workflow-state-machine.sh → workflow-orchestration MCP tool. This preserves core functionality while adapting to OpenCode's architecture. Reference Finding 8 (MCP Integration) and Finding 5 (State Persistence). Estimated effort: 2-3 weeks for core libraries, 4-6 weeks for complete migration.

2. **Adopt Prompt-Based Orchestration Pattern (Priority: High)**: Redesign the hard barrier subagent delegation pattern (Setup/Invoke/Verify bash blocks) into prompt-based orchestration instructions embedded in agent definitions. Use OpenCode's TaskTool for subagent invocation with metadata-only passing implemented through structured JSON in prompts rather than bash variable persistence. Test stateless subagent design with wave-based parallelization to ensure 40-60% time savings are preserved. Reference Finding 3 (Subagent Invocation) and Finding 2 (Command Syntax). Implementation approach: create agent prompt templates that enforce verification checkpoints through instruction rather than bash barriers.

3. **Split Agent Files into YAML + Prompt Structure (Priority: Medium)**: Systematically convert the 19 Claude Code agent files from unified markdown (with 28 completion criteria in behavioral guidelines) into OpenCode's separated format: YAML frontmatter for configuration (mode, model, tools, permissions) + markdown body for system prompt. Map `allowed-tools` to `tools`/`permission` options, convert model specifications (`sonnet-4.5` → `anthropic/claude-sonnet-4-20250514`), and set appropriate `mode` (primary/subagent/all) based on agent role. Reference Finding 1 (Agent Format) and Finding 6 (Model Selection). Create conversion script to automate this transformation.

4. **Migrate CLAUDE.md Standards to AGENTS.md (Priority: Medium)**: Convert the central CLAUDE.md configuration index (15+ standards sections) into OpenCode's AGENTS.md format. Place global standards in `~/.config/opencode/AGENTS.md` (code standards, directory organization, error logging) and project-specific standards in project root AGENTS.md (testing protocols, plan metadata, adaptive planning). Replace bash-specific patterns (three-tier sourcing, state-persistence.sh integration) with equivalent JavaScript/TypeScript or MCP-based patterns. Reference Finding 7 (Project Configuration). Test that combined global + project rules preserve standards enforcement.

5. **Convert Commands to Template-Based or Agent-Driven Architecture (Priority: Low)**: Evaluate the 16 slash commands to determine porting strategy: (a) simple commands (like `/errors`, `/todo`) can become markdown templates with $ARGUMENTS and !bash injection, (b) complex orchestrators (like `/create-plan`, `/implement`) should become specialized agents with orchestration logic in prompts or JavaScript extensions, (c) utility commands (like `/expand`, `/collapse`) may be better as MCP tools. Start with `/research` as simplest orchestrator, then `/create-plan` as most complex. Reference Finding 2 (Command Syntax) and Finding 4 (File Tools). Prioritize maintaining the three-tier hierarchy (Commands → Coordinators → Specialists).

6. **Implement Metadata-Only Passing via JSON in Prompts (Priority: Medium-High)**: Preserve the 92-97% context reduction achieved by metadata-only passing by embedding structured JSON metadata in agent prompts rather than using bash variable persistence. Design JSON schemas for artifact metadata (reports, plans, test results) that agents include in TaskTool invocations. Test context reduction metrics to ensure performance parity with Claude Code's bash-based approach. Reference Finding 3 (Subagent Invocation) and architectural patterns from `/home/benjamin/.config/.claude/docs/reference/standards/artifact-metadata-standard.md` (lines 1-150). Validate with real-world research-coordinator and implementer-coordinator workflows.

7. **Build OpenCode Extensions for Wave-Based Parallel Execution (Priority: Medium)**: The 40-60% time savings from wave-based parallelization depend on dependency analysis and topological sorting (Kahn's algorithm) implemented in bash libraries. Port this logic into a JavaScript/TypeScript OpenCode extension or MCP tool that agents can invoke. Extension should parse plan files, analyze phase dependencies, calculate waves, and coordinate parallel TaskTool invocations. Reference `/home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md` for implementation details. Test with multi-phase plans to validate time savings preservation.

## References

### .claude/ Architecture Documentation (Analyzed)
- [/home/benjamin/.config/.claude/docs/port_to_opencode.md] (lines 1-636) - Complete porting guide with architecture summary, component catalog, and porting priorities
- [/home/benjamin/.config/.claude/agents/research-specialist.md] (lines 1-908) - Research specialist agent behavioral guidelines with 28 completion criteria
- [/home/benjamin/.config/CLAUDE.md] (lines 1-800+) - Central configuration index with 15+ standards sections

### OpenCode Official Documentation (Web Sources)
- [https://opencode.ai/docs/] - Official OpenCode documentation index
- [https://opencode.ai/docs/agents/] - Agent definition format, YAML frontmatter, mode configuration, tool access control
- [https://opencode.ai/docs/commands/] - Custom command syntax, markdown templates, argument passing, bash injection
- [https://opencode.ai/docs/config/] - Configuration structure, model selection, tool access control, agent configuration
- [https://opencode.ai/docs/tools/] - Built-in tools (read, write, edit, glob, grep, bash, task, webfetch, websearch)
- [https://opencode.ai/docs/permissions/] - Permission system for tool access control
- [https://opencode.ai/docs/rules/] - AGENTS.md project configuration files
- [https://opencode.ai/docs/mcp-servers/] - Model Context Protocol integration for external tools

### Technical Implementation Analysis
- [https://cefboud.com/posts/coding-agents-internals-opencode-deepdive/] - OpenCode agent orchestration, TaskTool implementation, context management, LSP integration
- [https://deepwiki.com/sst/opencode/2.1-session-lifecycle-and-state] - Session management, SQLite state persistence, atomic update patterns

### Comparison and Migration Resources
- [https://www.andreagrandi.it/posts/comparing-claude-code-vs-opencode-testing-different-models/] - Claude Code vs OpenCode performance comparison
- [https://github.com/SpillwaveSolutions/architect-agent/blob/main/references/claude_vs_opencode_comparison.md] - Architectural comparison and agent invocation patterns
- [https://apidog.com/blog/opencode/] - OpenCode overview and use cases
- [https://danielmiessler.com/blog/opencode-vs-claude-code] - Feature comparison and selection criteria

### GitHub Repositories
- [https://github.com/sst/opencode] - Official OpenCode repository
- [https://github.com/opencode-ai/opencode] - Alternative OpenCode implementation
