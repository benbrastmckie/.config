# Practical Workarounds and Solutions for Markdown Rendering

**Research Question**: What are the practical solutions and workarounds users can implement today to get better markdown rendering from OpenCode?

## Immediate Workarounds (No Code Changes)

### 1. Copy to Markdown Preview

**Method**: Export conversation and view in markdown-aware editor

**Steps**:
```bash
# In OpenCode TUI
/export

# This opens EDITOR with markdown content
# Your EDITOR is set to: code --wait (VS Code)
# VS Code has native markdown preview (Ctrl+Shift+V)
```

**Pros**:
- ✅ Works immediately
- ✅ Full markdown rendering (tables, formatting, etc.)
- ✅ Can edit and reference later

**Cons**:
- ❌ Not real-time (must export after each response)
- ❌ Loses interactive flow
- ❌ Extra manual step

**Verdict**: Good for reviewing final outputs, not ongoing conversation

### 2. Use OpenCode Web/Desktop App

**Method**: Switch to graphical OpenCode interface

**Options**:
- **Desktop App**: Electron-based GUI (per docs)
- **Browser**: `opencode web` (per documentation)

**Expected Rendering**: Likely uses HTML/CSS for proper markdown display

**Steps**:
```bash
# Check if web mode available
opencode web
```

**Pros**:
- ✅ Proper markdown rendering (HTML-based)
- ✅ Tables, formatting, images (if supported)
- ✅ Official supported method

**Cons**:
- ❌ Loses terminal workflow
- ❌ Can't integrate with Neovim as smoothly
- ❌ May not have same keybinds/features as TUI

**Verdict**: Best for markdown-heavy work, but defeats purpose of TUI integration

### 3. Pipe Responses Through Markdown Renderer

**Method**: Intercept output and render with `glow` or similar

**Conceptual Flow**:
```
OpenCode → Extract Response → glow → Display
```

**Challenge**: OpenCode.nvim doesn't expose raw response text easily

**Possible Hack** (untested):
```bash
# Create wrapper script that captures output
#!/bin/bash
opencode "$@" | tee >(glow)

# Use in Neovim
# vim.g.opencode_opts.provider.terminal.cmd = "./opencode-wrapper.sh"
```

**Pros**:
- ✅ Keeps terminal workflow
- ✅ Better rendering (glow uses box-drawing)

**Cons**:
- ❌ Fragile (relies on output parsing)
- ❌ May break interactive features (input prompts)
- ❌ Not tested/supported

**Verdict**: Experimental, worth trying for specific use cases

## Medium-Term Solutions (Neovim Plugin Modifications)

### 4. Add Preview Window to opencode.nvim

**Approach**: Capture responses and display in separate buffer with markdown rendering

**Implementation Sketch**:

```lua
-- New feature for opencode.nvim
vim.g.opencode_opts = {
  preview = {
    enabled = true,
    window = {
      position = "right",
      width = 0.50,
    },
    renderer = "render-markdown.nvim",  -- Or treesitter-based
  },
}

-- Hook into OpencodeEvent
vim.api.nvim_create_autocmd("User", {
  pattern = "OpencodeEvent:session.message",
  callback = function(args)
    local response = args.data.content  -- Hypothetical
    -- Render markdown in preview window
    require("opencode.preview").update(response)
  end,
})
```

**Requirements**:
- Access to full response text (may need OpenCode API call)
- Markdown parser (Treesitter or external)
- Rendering plugin (e.g., `render-markdown.nvim`, `markdown-preview.nvim`)

**Pros**:
- ✅ Integrated experience
- ✅ Real-time updates
- ✅ Keeps TUI for interaction

**Cons**:
- ❌ Requires plugin development
- ❌ Needs upstream support for response access
- ❌ Extra complexity

**Feasibility**: Moderate (would need community contribution)

### 5. Use Alternative Plugin (sudo-tee/opencode.nvim)

**Method**: Switch to native Neovim frontend instead of TUI

**Status**: Mentioned in NickvanDyke README but not researched

**Expected Benefits**:
- Native Neovim buffers (not terminal)
- Could use `render-markdown.nvim` directly
- Full control over rendering

**Unknown**:
- Feature parity with official TUI
- Maintenance status
- Configuration complexity

**Action Item**: Research `sudo-tee/opencode.nvim` separately

## Long-Term Solutions (OpenCode Upstream Changes)

### 6. Feature Request: TUI Markdown Rendering

**Approach**: Request opentui to add markdown processing

**Implementation Ideas**:
- Parse markdown in real-time
- Convert to ANSI + Unicode (like `glow`)
- Render tables with box-drawing characters
- Style headers, lists, etc.

**Precedent**: Tools that do this:
- `glow` - Full markdown renderer for terminal
- `rich` (Python) - Markdown to terminal
- `mdcat` - Simple markdown viewer

**Example Output** (from `glow`):
```
  ╔════════════════════════════════════╗
  ║         MARKDOWN HEADER            ║
  ╚════════════════════════════════════╝

  • Bullet point one
  • Bullet point two

  ┌─────────┬─────────┐
  │ Header  │ Header  │
  ├─────────┼─────────┤
  │ Cell    │ Cell    │
  └─────────┴─────────┘
```

**Pros**:
- ✅ Benefits all users (TUI, IDE, CLI)
- ✅ Terminal-friendly
- ✅ Proper solution

**Cons**:
- ❌ Requires OpenCode maintainer buy-in
- ❌ Non-trivial development effort
- ❌ May impact performance (real-time parsing)

**GitHub Issue**: #3845 and #4988 already track this

**Recommendation**: Upvote existing issues, contribute if able

### 7. Configuration Option for Markdown Processing

**Ideal Feature**:
```json
// opencode.json
{
  "tui": {
    "markdown_rendering": {
      "enabled": true,
      "mode": "styled",  // or "raw"
      "tables": "box-drawing",  // Unicode tables
      "code_blocks": "highlighted",
      "links": "clickable"  // OSC 8 hyperlinks
    }
  }
}
```

**Status**: Does not exist (as of research)

**Feature Request**: Could be proposed to OpenCode project

## Recommended Action Plan

### For User (Immediate)

1. **Try `/export` Workflow**:
   - Use `/export` to view responses in VS Code
   - Set up a keybind for quick export
   - Good for long responses with tables

2. **Test Web Mode** (if available):
   ```bash
   opencode web
   ```
   - Check if markdown renders properly
   - Use for markdown-heavy tasks

3. **Accept TUI Limitations**:
   - Understand this is "working as intended"
   - Focus on content over presentation for interactive work

### For Community Contribution

1. **Upvote GitHub Issues**:
   - #3845 (Markdown tables)
   - #4988 (Table rendering feature)

2. **Consider Preview Plugin**:
   - Fork `NickvanDyke/opencode.nvim`
   - Add optional preview window mode
   - Submit PR if successful

3. **Research Alternative**:
   - Check `sudo-tee/opencode.nvim` capabilities
   - Compare features and rendering

### For OpenCode Project (Wishlist)

1. **Add Markdown Rendering**:
   - Integrate library like `pulldown-cmark` (Rust)
   - Convert to ANSI + Unicode
   - Make optional via config

2. **Provide Response API**:
   - Allow plugins to access raw response text
   - Enable custom rendering downstream

3. **Document Workarounds**:
   - Official guide for markdown viewing
   - Best practices for output handling

## Example: Preview Window Proof-of-Concept

**Pseudocode** for opencode.nvim extension:

```lua
local M = {}

function M.setup_preview()
  -- Create floating window for markdown
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = math.floor(vim.o.columns * 0.4),
    height = vim.o.lines - 4,
    col = math.floor(vim.o.columns * 0.6),
    row = 1,
    style = 'minimal',
    border = 'rounded'
  })

  -- Listen for OpenCode responses
  vim.api.nvim_create_autocmd("User", {
    pattern = "OpencodeEvent:*",
    callback = function(args)
      if args.data.event.type:match("message") then
        -- Extract markdown content (would need API)
        local content = get_latest_response()  -- TODO: implement
        
        -- Render with render-markdown.nvim
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))
        vim.bo[buf].filetype = 'markdown'  -- Triggers rendering
      end
    end
  })
end

return M
```

**Blockers**:
- Need access to raw response text from OpenCode
- Currently no clean API for this

## Conclusions

1. **No Perfect Solution**: All workarounds have trade-offs
2. **Best Current Option**: `/export` to VS Code for finished responses
3. **Most Promising**: Preview window plugin (needs development)
4. **Ideal Future**: Upstream TUI markdown rendering

## Sources
- OpenCode Documentation (TUI commands)
- NickvanDyke/opencode.nvim Architecture
- glow (Markdown renderer)
- render-markdown.nvim (Neovim plugin)
- GitHub Issues #3845, #4988

**Confidence Level**: High (85%) - Workarounds are practical, but preview plugin needs validation
**Date**: 2025-12-15
