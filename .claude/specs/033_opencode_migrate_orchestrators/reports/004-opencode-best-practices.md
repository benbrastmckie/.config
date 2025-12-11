# Research Report: OpenCode Command and Agent Best Practices

## Metadata
- **Report ID**: 004-opencode-best-practices
- **Date**: 2025-12-11
- **Researcher**: research-specialist
- **Status**: Complete
- **Sources**: OpenCode Documentation (Commands, Agents)

## Executive Summary
OpenCode provides a flexible system for defining custom commands and agents using Markdown and JSON. The platform emphasizes a distinction between "Primary Agents" (general-purpose, tab-switchable) and "Subagents" (specialized, invoked via delegation). Best practices center on using Markdown for portability, strict permission scoping for safety, and leveraging context injection (`@file`, `!cmd`) to reduce prompt overhead.

## 1. Command Design Best Practices

### 1.1. Definition Format
*   **Use Markdown**: Prefer defining commands in `.opencode/command/*.md` over `opencode.json`. This keeps the prompt content readable and version-controllable.
*   **Frontmatter**: always include `description`, `agent`, and `model` (if specific capability is needed) in the YAML frontmatter.

### 1.2. Input Handling
*   **Arguments**: Use `$ARGUMENTS` for the full input string or `$1`, `$2`, etc. for positional arguments.
*   **Shell Injection**: Use `!command` to inject dynamic context (e.g., `!git status`). *Warning*: Ensure commands are read-only to avoid side effects during prompt construction.
*   **File Context**: Use `@filename` to inject file contents. This is more reliable than asking the agent to "read file X" in the prompt text.

### 1.3. Context Management
*   **Subtasks**: Use `subtask: true` in the command config (JSON) or agent config to run the command in a "child session". This prevents large outputs or context-heavy tasks from polluting the main chat history.

## 2. Agent Design Best Practices

### 2.1. Agent Types
*   **Primary Agents**: Use for broad, interactive roles (e.g., "Build", "Plan"). Configured with `mode: primary`.
*   **Subagents**: Use for specific, narrow tasks (e.g., "Security Auditor", "Docs Writer"). Configured with `mode: subagent`. These are invoked by primary agents or via `@mention`.

### 2.2. Permissions & Safety
*   **Principle of Least Privilege**: Explicitly disable tools the agent doesn't need.
    ```yaml
    tools:
      write: false
      edit: false
    ```
*   **Granular Bash Permissions**: Use glob patterns to allow specific commands while blocking others.
    ```yaml
    permission:
      bash:
        "git status": allow
        "git log": allow
        "*": deny
    ```
*   **Ask vs Allow**: Set destructive tools (like `edit` or `rm`) to `ask` for high-risk agents, or `allow` for trusted, low-risk subagents (e.g., a linter runner).

### 2.3. Model Selection
*   **Task-Specific Models**:
    *   Use faster/cheaper models (e.g., Claude Haiku, GPT-4o-mini) for simple logic or routing agents.
    *   Use reasoning-heavy models (e.g., Claude Sonnet, GPT-4o) for coding and complex planning.
*   **Inheritance**: If `model` is omitted in a subagent, it inherits the calling agent's model. This is useful for keeping the experience consistent.

### 2.4. Cost Control
*   **Max Steps**: Set `maxSteps` (e.g., 5-10) for agents to prevent infinite loops or excessive API usage during autonomous execution.

## 3. Directory Structure
*   **Project-Specific**: Store configs in `.opencode/command/` and `.opencode/agent/` to commit them with the repo.
*   **Global**: Store personal workflows in `~/.config/opencode/` (Linux/Mac).

## 4. Prompt Engineering for Agents
*   **Role Definition**: Start the prompt with "You are a [Role]."
*   **Constraint Checklist**: Explicitly list what the agent *cannot* do (e.g., "Do not modify code, only suggest changes").
*   **Structured Output**: If the agent needs to return data to a coordinator, specify a strict output format (e.g., "Return findings as a Markdown list").

## Conclusion
For the orchestration migration, we should define the `research-coordinator` and `research-specialist` as agents in `.opencode/agent/`. The `/research` command should be defined in `.opencode/command/research.md` and configured to route specifically to the coordinator agent. Using `subtask: true` (or relying on the subagent nature) will be crucial for keeping the main session clean.
