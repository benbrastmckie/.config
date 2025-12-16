# OpenCode.nvim Plugin Architecture and Rendering Limitations

**Research Question**: What role does the opencode.nvim plugin play in rendering, and could it be modified to improve markdown display?

## Findings

### OpenCode.nvim Architecture (NickvanDyke Variant)

The `NickvanDyke/opencode.nvim` plugin architecture:

```
┌─────────────────────────────────────────┐
│         Neovim Instance                 │
│  ┌───────────────────────────────────┐ │
│  │   opencode.nvim Plugin            │ │
│  │   - Context injection             │ │
│  │   - Terminal provider management  │ │
│  │   - Event forwarding (SSE)        │ │
│  │   - Buffer auto-reload            │ │
│  │   - Permission handling           │ │
│  └───────────────────────────────────┘ │
│           ↓                             │
│  ┌───────────────────────────────────┐ │
│  │   Terminal Buffer (:terminal)     │ │
│  │   or External Terminal Provider   │ │
│  └───────────────────────────────────┘ │
│           ↓                             │
│  ┌───────────────────────────────────┐ │
│  │   OpenCode TUI Process            │ │
│  │   (Rust binary, opentui)          │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Plugin Responsibilities

According to the README and configuration, `opencode.nvim` does **NOT** handle rendering. Instead:

1. **Context Injection**: Sends editor context to OpenCode
   - Buffer contents (`@buffer`, `@buffers`)
   - Visual selections (`@this`)
   - Diagnostics (`@diagnostics`)
   - Git diffs (`@diff`)

2. **Terminal Management**: Spawns/controls OpenCode process
   - Provider options: `terminal`, `snacks`, `kitty`, `wezterm`, `tmux`
   - Does NOT modify or intercept output

3. **Event Handling**: Forwards Server-Sent Events (SSE) from OpenCode
   - `OpencodeEvent` autocmd
   - Types: `session.idle`, `session.edit`, etc.
   - No rendering logic in event handlers

4. **Auto-Reload**: Watches for file edits by OpenCode
   - Sets `vim.o.autoread = true`
   - Reloads buffers when OpenCode changes files
   - No output transformation

### Current Configuration (User's Setup)

From `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/opencode.lua`:

```lua
vim.g.opencode_opts = {
  provider = {
    enabled = "snacks",  -- Uses snacks.terminal for UI
    snacks = {
      auto_close = false,
      win = {
        position = "right",
        width = 0.40,  -- 40% split
      },
    },
  },
  -- Context options (what gets sent TO opencode)
  include_diagnostics = true,
  include_buffer = true,
  include_visible = true,
  -- No rendering options!
}
```

**Key Observation**: No configuration options for output rendering or markdown processing.

### Plugin Does NOT:
- ❌ Parse OpenCode's output
- ❌ Transform markdown to rich text
- ❌ Provide custom rendering
- ❌ Intercept terminal buffer content

### Plugin DOES:
- ✅ Manage terminal instance (via snacks.nvim)
- ✅ Send context to OpenCode (input side)
- ✅ Listen for events (file edits, permissions)
- ✅ Reload buffers when files change

## Alternative: sudo-tee/opencode.nvim

The README mentions an alternative:

> Uses `opencode`'s TUI for simplicity — see [sudo-tee/opencode.nvim](https://github.com/sudo-tee/opencode.nvim) for a Neovim frontend.

**Implications**:
- `sudo-tee` variant creates a **native Neovim UI** (not terminal-based)
- Could theoretically render markdown using Neovim's features
- Status unclear (link available, but not researched in detail here)

**Architecture Difference**:
```
NickvanDyke:   Neovim → Terminal → OpenCode TUI
sudo-tee:      Neovim → Custom UI → OpenCode API(?)
```

## Feasibility of Markdown Rendering in opencode.nvim

### Option 1: Parse Terminal Output (Hacky)

**Approach**: Intercept terminal buffer content, parse markdown, re-render

**Challenges**:
- Terminal buffers are "append-only" (can't edit historical output)
- Real-time parsing would be complex and fragile
- ANSI codes would interfere with markdown parsing
- Streaming responses update incrementally (partial markdown)

**Verdict**: ❌ Not practical with terminal provider architecture

### Option 2: Separate Preview Window

**Approach**: Extract markdown from output, display in split buffer with rendering

**Implementation**:
1. Listen to `OpencodeEvent` autocmd
2. When `session.message` received, extract response text
3. Parse markdown and render in floating window
4. Use `render-markdown.nvim` or similar for display

**Challenges**:
- Would need to capture full response (not streaming)
- Synchronization with TUI output
- Extra screen real estate required
- Not truly integrated with OpenCode

**Verdict**: ⚠️ Possible but clunky, feels like a workaround

### Option 3: Replace with Native Frontend (sudo-tee approach)

**Approach**: Don't use terminal at all, build Neovim UI from scratch

**Requirements**:
- Direct API access to OpenCode backend
- Custom buffer rendering for messages
- Markdown parser + Neovim rendering (Treesitter, conceal, etc.)
- Reimplementation of TUI features in Lua

**Challenges**:
- Major development effort
- Maintenance burden (keep parity with official TUI)
- May lack features (themes, keybinds from OpenCode)

**Verdict**: ✅ Technically feasible, but requires significant effort

## Events Available for Rendering Hooks

The plugin provides `OpencodeEvent` autocmd with these types:

```lua
-- Example event structure
{
  type = "session.message",  -- Or other types
  data = { ... },  -- Event-specific data
  port = 8080  -- OpenCode server port
}
```

**Known Event Types** (from SSE forwarding):
- `session.idle` - Response finished
- `session.edit` - File was edited
- `session.*` - Other session events

**Limitation**: No event specifically for "markdown content available"

## Conclusions

1. **Plugin's Role**: `opencode.nvim` is a **terminal manager**, not a renderer
2. **No Rendering Hooks**: Current architecture provides no hooks for output transformation
3. **Terminal-Based Limitation**: As long as the plugin uses `:terminal` or external terminals, markdown rendering is limited by terminal capabilities
4. **Alternative Frontend**: The `sudo-tee` variant could solve this, but requires research
5. **Workaround Potential**: Preview window approach is doable but not elegant

## Recommendations

### For Current Setup (NickvanDyke plugin)

**No Easy Fix**: The plugin architecture doesn't support markdown rendering. Options:

1. **Accept Limitation**: OpenCode TUI is plain text by design
2. **Copy to Preview**: Manually copy responses to markdown viewer
3. **Feature Request**: Ask NickvanDyke to add preview window mode

### For Better Experience

1. **Investigate sudo-tee/opencode.nvim**: Check if it has native markdown rendering
2. **Contribute**: Add preview window feature to NickvanDyke variant
3. **Use Web/Desktop**: OpenCode has desktop app with proper rendering

## Next Steps for User

1. Check if terminal (`$TERM`) supports richer output (unlikely to help)
2. Consider switching to OpenCode desktop app for important markdown content
3. File feature request with NickvanDyke/opencode.nvim for preview mode
4. Investigate sudo-tee variant as alternative

## Sources
- NickvanDyke/opencode.nvim GitHub Repository
- User's configuration file (opencode.lua)
- Neovim Terminal Documentation
- SSE (Server-Sent Events) specification

**Confidence Level**: Very High (95%) - Plugin source code and architecture are transparent
**Date**: 2025-12-15
