# Command Frontmatter Template

This template defines the standard YAML frontmatter used across all `.claude/commands/*.md` files.

## Standard Tool Allowlist

All commands should reference this file for tool access declarations rather than duplicating the allowlist.

### Primary Commands (Full Tool Access)

For commands that coordinate workflows, create artifacts, or manage state:

```yaml
---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite, Task, SlashCommand
argument-hint: [command-specific-arguments]
description: [command-specific-description]
command-type: primary
dependent-commands: [list, of, dependent, commands]
---
```

**Tool Categories**:
- **File Operations**: Read, Edit, MultiEdit, Write
- **Search**: Grep, Glob
- **Execution**: Bash
- **State Management**: TodoWrite
- **Delegation**: Task, SlashCommand

**When to Use**: Commands like `/implement`, `/orchestrate`, `/plan`, `/debug` that need comprehensive tool access

### Analysis Commands (Read-Only + Search)

For commands that analyze without modifying:

```yaml
---
allowed-tools: Read, Bash, Grep, Glob, WebSearch, WebFetch
argument-hint: [command-specific-arguments]
description: [command-specific-description]
command-type: analysis
dependent-commands: [list, if, any]
---
```

**Tool Categories**:
- **Read-Only**: Read, Grep, Glob
- **External Research**: WebSearch, WebFetch
- **Query Execution**: Bash (read-only operations)

**When to Use**: Commands like `/analyze`, `/refactor` (analysis phase) that gather information without modification

### Utility Commands (Minimal Access)

For commands with focused, limited scope:

```yaml
---
allowed-tools: Read, Write, Bash
argument-hint: [command-specific-arguments]
description: [command-specific-description]
command-type: utility
dependent-commands: []
---
```

**Tool Categories**:
- **Basic I/O**: Read, Write
- **Execution**: Bash (for specific utility operations)

**When to Use**: Commands like `/list`, `/validate-setup` with narrow, well-defined operations

## Frontmatter Fields Reference

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `allowed-tools` | Comma-separated list of tool names | `Read, Write, Bash` |
| `argument-hint` | User-facing argument syntax | `<file> [options]` |
| `description` | One-line command description | `Execute implementation plan` |
| `command-type` | Command category | `primary \| analysis \| utility` |

### Optional Fields

| Field | Description | Example |
|-------|-------------|---------|
| `dependent-commands` | Commands this command may invoke | `list, update, revise` |
| `requires-auth` | If command needs authentication | `true` (rarely used) |
| `experimental` | Mark experimental features | `true` (rarely used) |

## Tool Descriptions

### File Operation Tools

- **Read**: Read file contents (supports line range, images, PDFs, Jupyter notebooks)
- **Edit**: Make exact string replacements in files (requires prior Read)
- **MultiEdit**: Perform multiple edits across files in one operation
- **Write**: Create new files or overwrite existing (requires prior Read for existing files)

### Search Tools

- **Grep**: Content search using ripgrep with regex support
- **Glob**: File pattern matching with glob patterns

### Execution Tools

- **Bash**: Execute shell commands with timeout support
  - Persistent shell session
  - Use for git, npm, docker, terminal operations
  - NOT for file operations (use dedicated tools instead)

### State Management Tools

- **TodoWrite**: Create and update task lists for progress tracking
  - Track implementation phases
  - Mark tasks complete as work progresses
  - Essential for transparency in multi-step operations

### Delegation Tools

- **Task**: Launch specialized subagents for complex operations
  - Invoke agents defined in `.claude/agents/`
  - Specify subagent_type and behavioral guidelines
  - Enable parallel execution for independent tasks

- **SlashCommand**: Execute other slash commands programmatically
  - Invoke commands defined in `.claude/commands/`
  - Enable command composition and workflows
  - Pass arguments and capture output

### Research Tools

- **WebSearch**: Search the web for current information
  - Access beyond knowledge cutoff
  - Domain filtering support
  - US-only availability

- **WebFetch**: Fetch and process web content
  - Retrieve specific URLs
  - AI-powered content extraction
  - HTML to markdown conversion

## Usage in Commands

### Referencing This Template

Instead of duplicating tool allowlists, commands should include a reference:

```markdown
## Tool Access

This command uses the standard tool allowlist for [primary|analysis|utility] commands.

See `.claude/templates/command-frontmatter.md` for tool descriptions and access patterns.

**Allowed Tools**: [list specific tools this command uses]
```

### Command-Specific Tool Restrictions

If a command needs a customized tool set (not matching standard categories):

```yaml
---
allowed-tools: Read, Write, Bash, Grep  # Custom subset
argument-hint: <custom-args>
description: Custom command with specific tool needs
command-type: custom
dependent-commands: []
---
```

**Document Why**: Explain in command file why custom toolset is needed

## Maintenance

### Adding New Tools

When new tools become available:
1. Update appropriate category in this template
2. Add tool description to "Tool Descriptions" section
3. Update commands that would benefit from new tool
4. Test tool access with sample command invocations

### Deprecating Tools

When tools are deprecated:
1. Mark as deprecated in "Tool Descriptions"
2. Document replacement tool
3. Update all command files using deprecated tool
4. Remove from standard allowlists after transition period

## Cross-References

- **Command Patterns**: `.claude/docs/command-patterns.md` - Best practices for tool usage
- **Agent Tool Access**: `.claude/templates/agent-tool-descriptions.md` - Tool access for agents
- **Error Handling**: `.claude/lib/error-handling.sh` - Tool access error recovery

## Notes

- Tool names are case-sensitive
- Tools must be comma-separated without extra whitespace
- Undeclared tools will cause command execution errors
- Agent tool access is separate from command tool access
- Tool access is enforced at runtime by Claude Code

---

*Template maintained by .claude system*
*For questions or updates, see `.claude/docs/command-architecture-standards.md`*
