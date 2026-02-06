# Security and Permissions Reference

**Purpose**: Security patterns, permission gates, and best practices for the .opencode/ agent system

**Last Updated**: 2026-02-05 (migrated from architecture.md)

---

## Approval Gates

The system implements explicit approval gates for sensitive operations:

| Operation    | Permission | Behavior                          |
| ------------ | ---------- | --------------------------------- |
| **edit**     | `ask`      | Prompt before file modifications  |
| **bash**     | `ask`      | Prompt before shell commands      |
| **webfetch** | `allow`    | Automatically fetch documentation |

### Permission Configuration

Permissions are configured in `opencode.json`:

```json
{
  "permission": {
    "edit": "ask",
    "bash": "ask",
    "webfetch": "allow"
  }
}
```

Available permission levels:

- `allow` - Execute without prompting
- `ask` - Always prompt for approval
- `deny` - Never allow (blocks operation)

---

## Tool Access by Agent

Different agent types have different tool permissions based on their responsibilities:

| Agent                     | Write | Edit | Bash | Web | Task |
| ------------------------- | ----- | ---- | ---- | --- | ---- |
| **build**                 | ✓     | ✓    | ✓    | ✓   | ✓    |
| **plan**                  | ✗     | ✗    | ✗    | ✗   | ✗    |
| **web-research**          | ✗     | ✗    | ✗    | ✓   | ✓    |
| **web-implementation**    | ✓     | ✓    | ✓    | ✗   | ✓    |
| **neovim-research**       | ✗     | ✗    | ✗    | ✓   | ✓    |
| **neovim-implementation** | ✓     | ✓    | ✓    | ✗   | ✓    |
| **code-reviewer**         | ✗     | ✗    | ✗    | ✗   | ✗    |
| **general-research**      | ✗     | ✗    | ✗    | ✓   | ✓    |

### Tool Permission Rationale

- **Write agents** (build, implementation agents): Full tool access for code changes
- **Read-only agents** (plan, code-reviewer): No destructive tools to prevent accidental changes
- **Research agents**: Web access for documentation, no write access
- **Build agent**: Full orchestration capabilities including task delegation

---

## MCP Integration

### Astro Docs MCP Server

Enables direct access to Astro framework documentation:

```json
{
  "mcp": {
    "astro-docs": {
      "type": "stdio",
      "command": "npx",
      "args": ["@astrojs/mcp-server@latest"],
      "enabled": true
    }
  }
}
```

### Available MCP Servers

| Server         | Type  | Purpose                           |
| -------------- | ----- | --------------------------------- |
| **astro-docs** | stdio | Astro framework documentation     |
| **context7**   | stdio | Upstash Context7 for library docs |
| **playwright** | stdio | Browser automation (headless)     |

---

## Best Practices

### Context Loading

- Use `{file:path}` references in agent configs for precise context injection
- Keep context files under 200 lines (MVI principle)
- Load only what's needed for the specific task
- Cache frequently-used context in sessions/

### Agent Design

- Single responsibility: Each agent has one focused purpose
- Subagent delegation: Use specialized agents for specific tasks
- Clear tool permissions: Define exactly which tools each agent can use
- Editable behavior: Agents as markdown files allow customization without lock-in

### Command Design

- Use `$ARGUMENTS` for user input in command templates
- Keep templates concise and focused
- Document expected behavior in command descriptions
- Route to appropriate skills based on task language

### Workflow Safety

- Always request approval before destructive operations
- Verify builds before marking tasks complete
- Create summaries for completed work
- Use session IDs for traceability
- Implement two-phase commits for state updates (state.json first, TODO.md second)

### Error Prevention

- Validate task exists before operations
- Check status allows requested operation
- Rollback state changes on failure
- Never write files before user approval (in plan mode)

---

## Configuration Schema

### Agent Markdown Format

```markdown
---
description: Agent description for UI display
mode: subagent
temperature: 0.3
tools:
  read: true
  write: true
  edit: true
  bash: true
---

# Agent Name

Agent instructions here...
```

### opencode.json Structure

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "<your-preferred-model>",
  "default_agent": "build",
  "agent": {
    "build": {
      "mode": "primary",
      "prompt": "build-prompt.txt"
    },
    "plan": {
      "mode": "primary",
      "tools": {
        "write": false,
        "edit": false,
        "bash": false
      }
    }
  },
  "command": {
    "task": {
      "template": "Create task: $ARGUMENTS"
    }
  },
  "permission": {
    "edit": "ask",
    "bash": "ask"
  }
}
```

---

## Security Checklist

When configuring agents and permissions:

- [ ] Destructive tools (write, edit, bash) set to `ask` for user-facing agents
- [ ] Read-only agents have all destructive tools disabled
- [ ] MCP servers only enabled when needed
- [ ] Agent permissions match their responsibilities
- [ ] Sensitive operations require explicit approval
- [ ] No hardcoded credentials in agent files
- [ ] State management uses atomic updates with rollback capability

---

## References

- [OpenCode Documentation](https://opencode.ai/docs/)
- [OpenCode Agents](https://opencode.ai/docs/agents/)
- [OpenCode Config](https://opencode.ai/docs/config/)
- [Permission Configuration Guide](../guides/permission-configuration.md)

---

**Note**: This document was migrated from architecture.md (2026-02-05) and updated to reflect current system architecture.
