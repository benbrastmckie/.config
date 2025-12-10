# Research Report: Opencode CLI Integration with Neovim

**Date**: 2025-12-10
**Topic**: Opencode CLI Integration with Neovim
**Status**: COMPLETE

## Executive Summary

This report documents how the opencode CLI tool (v1.0.119) integrates with Neovim through multiple plugin implementations. The integration enables seamless AI-assisted development with context-aware prompts, session management, and bidirectional communication between the editor and the AI assistant. Three main integration approaches exist: direct CLI communication (NickvanDyke/opencode.nvim), embedded chat interface (sudo-tee/opencode.nvim), and tmux-based context passing (cousine/opencode-context.nvim).

## Research Findings

### 1. Opencode CLI Architecture

#### Installed Version
- **Version**: 1.0.119
- **Location**: `/run/current-system/sw/bin/opencode`
- **Status**: Active and functional

#### Core CLI Commands

The opencode CLI provides multiple modes of operation:

| Command | Purpose | Integration Method |
|---------|---------|-------------------|
| `opencode [project]` | Start TUI | Direct terminal |
| `opencode run [message..]` | Execute single prompt | Scripting, automation |
| `opencode serve` | Headless server | HTTP/SSE API |
| `opencode acp` | ACP server | JSON-RPC via stdio |
| `opencode attach <url>` | Connect to running server | Remote integration |

#### Communication Protocols

Opencode supports three primary communication protocols for editor integration:

1. **Server-Sent-Events (SSE)**: HTTP-based streaming for real-time updates
2. **Agent Client Protocol (ACP)**: JSON-RPC via stdio (standardized agent-editor protocol)
3. **Terminal-based**: Direct command execution via tmux/terminal emulation

### 2. Neovim Plugin Implementations

#### NickvanDyke/opencode.nvim (Most Popular - 804 stars)

**Integration Approach**: Auto-connects to running opencode instance or manages embedded instance

**Key Features**:
- **Provider-agnostic**: Supports snacks.terminal, kitty, wezterm, tmux, custom providers
- **SSE-based communication**: Connects to opencode's HTTP API on configurable ports
- **Context placeholder system**: Powerful template-based context injection
- **Event forwarding**: opencode SSE events become Neovim autocmds
- **Session management**: List, create, share, navigate sessions programmatically

**Context Placeholders**:

| Placeholder | Context Captured |
|-------------|------------------|
| `@this` | Visual selection or cursor position |
| `@buffer` | Current buffer contents |
| `@buffers` | All open buffers |
| `@visible` | Currently visible text |
| `@diagnostics` | LSP diagnostics in current buffer |
| `@quickfix` | Quickfix list entries |
| `@diff` | Git diff output |
| `@grapple` | Tags from grapple.nvim plugin |

**Command Execution Pattern**:

Commands follow the pattern `require("opencode").command("command.name")`:

```lua
-- Session management
require("opencode").command("session.list")
require("opencode").command("session.new")
require("opencode").command("session.share")

-- Navigation
require("opencode").command("session.page.up")
require("opencode").command("session.half.page.down")
require("opencode").command("session.first")
require("opencode").command("session.last")

-- Editing
require("opencode").command("session.undo")
require("opencode").command("session.redo")

-- Input control
require("opencode").command("prompt.submit")
require("opencode").command("prompt.clear")

-- Agent management
require("opencode").command("agent.cycle")
```

**Predefined Prompt Library**:

The plugin includes built-in prompts for common tasks:
- `explain` - Explain selected code
- `review` - Code review with suggestions
- `fix` - Fix errors or issues
- `optimize` - Performance optimization
- `test` - Generate unit tests
- `document` - Add documentation
- `implement` - Implement feature from description
- `diagnostics` - Analyze LSP diagnostics
- `diff` - Explain git diff

**Configuration Example**:

```lua
vim.g.opencode_opts = {
  provider = {
    enabled = "snacks.terminal", -- or "kitty", "wezterm", "tmux", "custom"
  },
  events = {
    reload = true, -- Auto-reload buffers when opencode edits files
  },
  prompts = {
    custom_prompt = "@this: Explain this code",
  },
}
```

**Workflow Example**:

```lua
-- Ask with context (submit immediately)
require("opencode").ask("@this: ", { submit = true })

-- Select from predefined actions
require("opencode").select()

-- Use named prompt template
require("opencode").prompt("@this")

-- Toggle opencode interface
require("opencode").toggle()
```

#### sudo-tee/opencode.nvim

**Integration Approach**: Embedded chat interface with persistent sessions

**Key Features**:
- **Workspace-tied sessions**: Persistent conversations linked to project directories
- **Dual context capture**: Current file and visual selections
- **Version requirement**: opencode CLI v0.6.3+
- **Timeline navigation**: Undo/redo/fork message capabilities
- **Interactive pickers**: File mention and slash command selection

**Commands Available** (30+ keymaps):
- UI toggles: open, close, zoom operations
- Input/output focus management
- File operations: diff viewing, reverting changes
- Session management: selection, renaming, timeline navigation
- Context management: file mentions, slash commands

**Context Capture**:

```lua
-- Default configuration enables:
{
  current_file = true,  -- Include file path and content
  selection = true,     -- Include selected text
}
```

**Session Management**:
- Select and load sessions via `<leader>os`
- Rename active sessions
- Navigate child sessions for branching conversations
- Timeline navigation with undo/redo/fork

#### cousine/opencode-context.nvim

**Integration Approach**: Tmux-based context passing to running CLI session

**Key Features**:
- **Direct tmux integration**: Sends keystrokes to opencode pane
- **Auto-detection**: Finds running opencode instances automatically
- **Placeholder system**: Similar to NickvanDyke implementation
- **Mode switching**: Toggle between planning and build mode
- **No subprocess management**: Works with existing opencode TUI

**Tmux Integration**:

The plugin communicates with opencode via `tmux send-keys` to detected opencode panes. Detection criteria:
1. Current command is "opencode"
2. Pane title contains "opencode"
3. Recent command history includes opencode

**Configuration**:

```lua
{
  tmux_target = nil, -- Auto-detect (default)
  -- OR
  tmux_target = "session:window.pane", -- Manual targeting
}
```

**Context Placeholders**:

| Placeholder | Context |
|-------------|---------|
| `@file` | Current file path (relative to CWD) |
| `@buffers` | All open buffer file paths |
| `@cursor` / `@here` | Current cursor position |
| `@selection` / `@range` | Visual selection content |
| `@diagnostics` | LSP diagnostics for current line |

**Commands**:
- `:OpencodeSend` - Interactive prompt with placeholder support
- `:OpencodeSwitchMode` - Toggle planning/build mode
- `:OpencodePrompt` - Persistent prompt interface

**Default Keybindings**:
- `<leader>oc` - Trigger OpencodeSend (normal and visual modes)
- `<leader>om` - Toggle opencode mode

**Workflow Pattern**:

1. Split tmux window: `Ctrl-b %` or `Ctrl-b "`
2. Launch `opencode` in one pane
3. Launch `nvim` in other pane
4. Press `<leader>oc` to open prompt
5. Enter prompt with placeholders: `"Fix this error: @diagnostics"`
6. View results immediately in opencode pane

### 3. Agent Client Protocol (ACP) Integration

#### What is ACP?

ACP is an open standard for communication between code editors and AI coding agents, analogous to Language Server Protocol (LSP) for language tools. Launched in August 2025 by Zed Editor with Google's Gemini CLI as the first reference implementation.

#### Opencode ACP Support

**Command**: `opencode acp`

**Communication Protocol**: JSON-RPC via stdio

**Architecture**: The ACP command creates a subprocess that bridges JSON-RPC requests to opencode's internal HTTP Server API and session management system.

#### Editor Configuration Examples

**Zed** (`~/.config/zed/settings.json`):
```json
{
  "agent_servers": {
    "OpenCode": {
      "command": "opencode",
      "args": ["acp"]
    }
  }
}
```

**Avante.nvim** (Neovim):
```lua
{
  acp_providers = {
    ["opencode"] = {
      command = "opencode",
      args = { "acp" }
    }
  }
}
```

**CodeCompanion.nvim** (Neovim):
Designate opencode as the ACP agent for chat interactions in plugin setup.

#### ACP Features

**Supported Capabilities**:
- Built-in tools
- Custom slash commands
- MCP (Model Context Protocol) servers
- Project rules from `AGENTS.md`
- Custom formatters
- Permissions system

**Unsupported in ACP Mode**:
- `/undo` command
- `/redo` command

#### ACP Ecosystem

**Compatible Editors**:
- Zed
- Neovim (via Avante.nvim, CodeCompanion.nvim)
- Marimo
- JetBrains (coming soon - co-developing ACP)

**Compatible Agents**:
- Claude Code
- Codex CLI
- Gemini CLI
- Goose
- Opencode
- Stackpak
- VT Code
- Docker's cagent
- fast-agent
- Kimi CLI
- LLMling-Agent
- OpenHands
- Augment Code

#### ACP Benefits

1. **Unified Experience**: Same AI model, tools, and configuration across CLI and editor
2. **Editor-Native UI**: Prompts and responses render in editor's interface
3. **Context Awareness**: Agent operates on files open in editor
4. **Seamless Workflow**: No context switching between editor and terminal
5. **Agent Portability**: One protocol implementation works across all ACP-enabled editors

### 4. CLI Command Details

#### opencode run

**Purpose**: Execute single prompt with message

**Options**:
- `--command`: Command to run (use message for args)
- `-c, --continue`: Continue last session
- `-s, --session`: Session ID to continue
- `--share`: Share the session
- `-m, --model`: Model in format `provider/model`
- `--agent`: Agent to use
- `--format`: Output format (`default` or `json`)
- `-f, --file`: File(s) to attach to message
- `--title`: Session title
- `--attach`: Attach to running server (e.g., `http://localhost:4096`)
- `--port`: Port for local server

**Use Cases**:
- Scripting and automation
- CI/CD integration
- Quick one-off queries
- Batch processing

**Example**:
```bash
opencode run "Explain this code" -f main.go --format json
```

#### opencode serve

**Purpose**: Start headless server for HTTP/SSE API access

**Options**:
- `-p, --port`: Port to listen on (default: random)
- `--hostname`: Hostname to listen on (default: `127.0.0.1`)

**Use Cases**:
- Integration with custom tools
- Remote access to opencode
- Web-based interfaces
- Plugin communication (NickvanDyke/opencode.nvim)

#### opencode acp

**Purpose**: Start Agent Client Protocol server

**Options**:
- `--cwd`: Working directory (default: current directory)
- `--port`: Port to listen on (default: random)
- `--hostname`: Hostname to listen on (default: `127.0.0.1`)

**Use Cases**:
- Editor integration (Zed, Neovim, etc.)
- Standardized agent-editor communication
- IDE plugin development

### 5. LSP and Context Integration

#### LSP Diagnostics Integration

All three main Neovim plugins support LSP diagnostics as injectable context:

**NickvanDyke/opencode.nvim**: `@diagnostics` placeholder captures diagnostics for current buffer
**sudo-tee/opencode.nvim**: Diagnostics picker for interactive selection
**cousine/opencode-context.nvim**: `@diagnostics` placeholder for current line diagnostics

**Note**: Plugins leverage existing Neovim diagnostic data rather than implementing LSP-specific features directly.

#### Git Integration

**NickvanDyke/opencode.nvim** provides `@diff` placeholder for git diff output, enabling prompts like:
```lua
require("opencode").ask("@diff: Review these changes", { submit = true })
```

#### File Context

All plugins capture file-level context:
- Current buffer content
- All open buffers
- Visual selections
- Cursor position
- Visible text (viewport content)

### 6. Workflow Patterns

#### Pattern 1: Embedded Terminal Workflow (NickvanDyke/opencode.nvim)

**Setup**:
```lua
vim.g.opencode_opts = {
  provider = { enabled = "snacks.terminal" },
}
```

**Workflow**:
1. Plugin auto-starts opencode in embedded terminal
2. Use placeholder-based prompts for context injection
3. View responses in terminal split
4. Continue session with persistent context

**Best For**: Users who want tight integration without leaving Neovim

#### Pattern 2: Persistent Session Workflow (sudo-tee/opencode.nvim)

**Setup**:
```lua
-- Enable in lazy.nvim
{
  "sudo-tee/opencode.nvim",
  config = function()
    require("opencode").setup({
      current_file = true,
      selection = true,
    })
  end
}
```

**Workflow**:
1. Open workspace-specific session
2. Interact via embedded chat interface
3. Use timeline navigation for conversation branching
4. Sessions persist across Neovim restarts

**Best For**: Long-running conversations tied to projects

#### Pattern 3: Tmux Split Workflow (cousine/opencode-context.nvim)

**Setup**:
```lua
{
  "cousine/opencode-context.nvim",
  config = function()
    require("opencode-context").setup({
      tmux_target = nil, -- Auto-detect
    })
  end
}
```

**Workflow**:
1. Run `opencode` in dedicated tmux pane
2. Edit code in Neovim pane
3. Press `<leader>oc` to send context-enriched prompts
4. View results in opencode pane without switching focus

**Best For**: Users who prefer traditional TUI with side-by-side layout

#### Pattern 4: ACP Integration Workflow

**Setup** (Avante.nvim):
```lua
{
  acp_providers = {
    ["opencode"] = {
      command = "opencode",
      args = { "acp" }
    }
  }
}
```

**Workflow**:
1. Editor spawns `opencode acp` subprocess
2. Use editor's native AI chat interface
3. opencode operates on editor's file context
4. Responses render in editor UI

**Best For**: Users wanting native editor UI with opencode backend

#### Pattern 5: Headless Server Workflow

**Setup**:
```bash
opencode serve --port 4096
```

**Workflow**:
1. Start persistent opencode server
2. Multiple clients connect via HTTP
3. Share sessions across tools
4. Use SSE for real-time updates

**Best For**: Multi-client scenarios, remote development

### 7. Best Practices

#### CLI + Editor Workflow Best Practices

1. **Choose Integration Based on Use Case**:
   - Quick iterations: Embedded terminal (NickvanDyke)
   - Long conversations: Persistent sessions (sudo-tee)
   - Visual separation: Tmux split (cousine)
   - Native editor UI: ACP integration

2. **Context Management**:
   - Use specific placeholders (`@this`, `@selection`) for targeted prompts
   - Leverage `@diagnostics` for error fixing
   - Use `@diff` for code review workflows
   - Combine multiple placeholders: `"@this: Fix based on @diagnostics"`

3. **Session Organization**:
   - Use session titles for easy identification
   - Leverage session sharing for collaboration
   - Branch conversations for exploring alternatives
   - Export sessions for documentation: `opencode export [sessionID]`

4. **Performance Optimization**:
   - Use `opencode serve` for persistent server to avoid startup overhead
   - Configure appropriate terminal provider based on system
   - Enable auto-reload for file changes (`events.reload = true`)

5. **Version Compatibility**:
   - NickvanDyke/opencode.nvim: Uses "undocumented, likely unstable API"
   - sudo-tee/opencode.nvim: Requires opencode CLI v0.6.3+
   - ACP integration: Version-agnostic (protocol-based)

6. **Troubleshooting**:
   - Check opencode process: `ps aux | grep opencode`
   - Verify port availability for `serve` mode
   - Validate tmux target for tmux-based plugins
   - Review `:messages` in Neovim for plugin errors

#### Model and Agent Configuration

**CLI Options**:
```bash
# Use specific model
opencode run -m anthropic/claude-3-opus "message"

# Use specific agent
opencode run --agent github "create PR"

# Continue last session
opencode run -c "follow-up message"
```

**Plugin Configuration**:
```lua
-- Configure default model via environment or CLI args
-- Plugins inherit opencode's model configuration
```

#### File Attachments

Attach files to prompts for context:
```bash
opencode run "Review this code" -f src/main.go -f tests/main_test.go
```

#### Statistics and Cost Tracking

Monitor token usage:
```bash
opencode stats
```

Useful for:
- Tracking API costs
- Understanding token consumption patterns
- Budget management

### 8. Integration Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                         Neovim Editor                           │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ NickvanDyke/    │  │ sudo-tee/       │  │ cousine/        ││
│  │ opencode.nvim   │  │ opencode.nvim   │  │ opencode-context││
│  │                 │  │                 │  │                 ││
│  │ SSE-based       │  │ Embedded chat   │  │ Tmux keystrokes ││
│  │ Auto-connect    │  │ Persistent      │  │ Auto-detect     ││
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘│
│           │                    │                    │         │
└───────────┼────────────────────┼────────────────────┼─────────┘
            │                    │                    │
            │                    │                    │
      ┌─────▼────────────────────▼────────────────────▼─────┐
      │                                                      │
      │                 opencode CLI (v1.0.119)             │
      │                                                      │
      │  ┌──────────┐  ┌──────────┐  ┌──────────┐         │
      │  │ TUI Mode │  │  Serve   │  │   ACP    │         │
      │  │(Terminal)│  │ (HTTP/   │  │(JSON-RPC)│         │
      │  │          │  │  SSE)    │  │          │         │
      │  └──────────┘  └──────────┘  └──────────┘         │
      │                                                      │
      │  ┌────────────────────────────────────────────────┐ │
      │  │  Core Features:                                │ │
      │  │  - Session management                          │ │
      │  │  - Multi-provider support (Anthropic, OpenAI) │ │
      │  │  - MCP server integration                      │ │
      │  │  - Agent system (GitHub, custom)               │ │
      │  │  - File operations & tool use                  │ │
      │  └────────────────────────────────────────────────┘ │
      └──────────────────────────────────────────────────────┘
                              │
                              │
                    ┌─────────▼──────────┐
                    │   AI Providers     │
                    │  - Anthropic       │
                    │  - OpenAI          │
                    │  - Custom          │
                    └────────────────────┘
```

**Communication Flow**:

1. **NickvanDyke/opencode.nvim**: Editor → HTTP/SSE API → opencode server → AI
2. **sudo-tee/opencode.nvim**: Editor → Embedded CLI → opencode process → AI
3. **cousine/opencode-context.nvim**: Editor → Tmux → opencode TUI → AI
4. **ACP Integration**: Editor → JSON-RPC → opencode acp → opencode core → AI

### 9. Feature Comparison Matrix

| Feature | NickvanDyke | sudo-tee | cousine | ACP |
|---------|-------------|----------|---------|-----|
| **Auto-connect** | Yes | No | Yes (tmux) | Yes |
| **Embedded terminal** | Yes | Yes | No | No |
| **Context placeholders** | 8+ types | 2 types | 5 types | Editor-dependent |
| **Session management** | Full | Full | Limited | Full |
| **SSE events** | Yes | No | No | No |
| **Tmux integration** | Via provider | No | Native | No |
| **Predefined prompts** | Yes | Limited | No | No |
| **Timeline navigation** | Yes | Yes | No | Yes |
| **Mode switching** | No | No | Yes | No |
| **LSP diagnostics** | Yes | Yes | Yes | Yes |
| **Git integration** | Yes | No | No | Editor-dependent |
| **Version requirement** | Any | v0.6.3+ | Any | Any |
| **API stability** | Unstable | Unstable | Stable (tmux) | Stable (protocol) |

## Implementation Recommendations

### For Users Already Running opencode CLI

**Recommended Approach**: cousine/opencode-context.nvim

**Rationale**:
- Works with existing opencode workflow
- No subprocess management overhead
- Stable integration via tmux
- Maintains visual separation between editor and AI assistant
- Minimal configuration required

**Setup**:
1. Ensure tmux is installed
2. Install plugin via lazy.nvim
3. Configure keybindings
4. Split tmux pane and run opencode

### For Tight Neovim Integration

**Recommended Approach**: NickvanDyke/opencode.nvim

**Rationale**:
- Most comprehensive feature set
- Powerful context placeholder system
- SSE event forwarding for automation
- Predefined prompt library
- Active development (804 stars)

**Considerations**:
- Relies on undocumented API (may break with updates)
- Requires snacks.nvim dependency
- More complex configuration

### For Native Editor UI Experience

**Recommended Approach**: ACP Integration (Avante.nvim or CodeCompanion.nvim)

**Rationale**:
- Standardized protocol (LSP equivalent for agents)
- Native editor UI
- Protocol stability guarantees
- Future-proof (JetBrains co-developing)
- Works across multiple editors

**Considerations**:
- Requires ACP-compatible editor plugin
- Some opencode features unsupported (`/undo`, `/redo`)

### For Project-Focused Workflows

**Recommended Approach**: sudo-tee/opencode.nvim

**Rationale**:
- Persistent workspace-tied sessions
- Timeline navigation for conversation branching
- Embedded chat interface
- Suitable for long-running conversations

**Considerations**:
- Version compatibility requirement (v0.6.3+)
- Less context capture flexibility than NickvanDyke

## Research Gaps and Future Investigation

1. **API Documentation**: opencode's API remains undocumented; official documentation would improve plugin stability
2. **Performance Metrics**: No benchmarks comparing integration methods
3. **MCP Integration**: Limited documentation on MCP server usage with Neovim plugins
4. **Custom Agent Development**: Workflow for creating and integrating custom agents
5. **Multi-User Scenarios**: Session sharing and collaboration patterns
6. **Security Considerations**: Authentication, permissions, sensitive data handling

## Conclusion

The opencode CLI provides multiple robust integration paths with Neovim, each optimized for different workflows. The SSE-based approach (NickvanDyke) offers the most features and flexibility, the tmux-based approach (cousine) provides the most stability for users with existing CLI workflows, and ACP integration offers the most future-proof standardized approach. The choice depends on user priorities: feature richness vs. stability vs. native UI vs. persistent sessions.

All approaches successfully enable context-aware AI assistance directly from the editor, with LSP diagnostics, git integration, and flexible prompt templating. The opencode CLI's multi-protocol support (SSE, ACP, direct execution) makes it highly adaptable to different development environments and preferences.

## Sources

- [NickvanDyke/opencode.nvim GitHub Repository](https://github.com/NickvanDyke/opencode.nvim)
- [sudo-tee/opencode.nvim GitHub Repository](https://github.com/sudo-tee/opencode.nvim)
- [cousine/opencode-context.nvim GitHub Repository](https://github.com/cousine/opencode-context.nvim)
- [ACP Support Documentation - opencode](https://opencode.ai/docs/acp/)
- [Agent Client Protocol (ACP) on Hacker News](https://news.ycombinator.com/item?id=45074147)
- [Intro to Agent Client Protocol (ACP) - Goose Blog](https://block.github.io/goose/blog/2025/10/24/intro-to-agent-client-protocol-acp/)
- [ACP Brings JetBrains on Board - Zed's Blog](https://zed.dev/blog/jetbrains-on-acp)
- [Agent Client Protocol: The LSP for AI Coding Agents - PromptLayer Blog](https://blog.promptlayer.com/agent-client-protocol-the-lsp-for-ai-coding-agents/)
- [Zed - Agent Client Protocol Overview](https://zed.dev/acp)
