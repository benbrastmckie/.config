# Terminal Emulator Markdown Rendering Support

**Research Question**: Do modern terminal emulators (Kitty, WezTerm, Alacritty, Ghostty) support markdown rendering natively, and could this be leveraged by OpenCode?

## Findings

### Terminal Rendering Fundamentals

All modern terminal emulators operate on the same core principle:
- **Character Grid**: Display is a grid of monospaced characters (rows × columns)
- **ANSI Escape Codes**: Styling via escape sequences (colors, bold, underline)
- **Limited Rich Text**: No native HTML/markdown rendering engines

### Individual Terminal Capabilities

#### Kitty (Required by OpenCode for Kitty Provider)

**Relevant Features**:
- ✅ **Kitty Graphics Protocol**: Can display inline images
- ✅ **Unicode Support**: Full UTF-8 including box-drawing characters
- ✅ **Hyperlinks**: Clickable links via OSC 8
- ✅ **Styled Underlines**: Different underline styles and colors
- ❌ **Markdown Rendering**: No native markdown parser/renderer

**OpenCode Integration**:
- Requires remote control via socket (`allow_remote_control=yes`)
- Used for spawning/managing terminal instances
- No special markdown features utilized

#### WezTerm (Recommended)

**Relevant Features**:
- ✅ **iTerm2 Image Protocol**: Inline image display
- ✅ **Sixel Graphics**: Alternative image format
- ✅ **Hyperlinks**: Clickable URLs
- ✅ **Lua Configuration**: Programmable but no markdown engine
- ❌ **Markdown Rendering**: No native support

#### Alacritty (Minimalist)

**Relevant Features**:
- ✅ **GPU-Accelerated**: Fast rendering
- ✅ **Basic ANSI**: Colors, bold, italic
- ❌ **Graphics Protocol**: No inline images
- ❌ **Markdown Rendering**: Explicitly minimalist, no rich features

#### Ghostty (Newer, Linux/macOS)

**Relevant Features**:
- ✅ **Modern ANSI Support**
- ✅ **Kitty Graphics Compatible**
- ❌ **Markdown Rendering**: No native support (new project, focused on speed)

### Box-Drawing Characters for Tables

All terminals support **Unicode box-drawing characters** (U+2500–U+257F):

```
┌───────┬───────┐
│ Cell  │ Cell  │
├───────┼───────┤
│ Data  │ Data  │
└───────┴───────┘
```

**Relevance to OpenCode**:
- Could be used to render markdown tables as ASCII art
- Requires post-processing markdown → box-drawing conversion
- Not "true" markdown rendering, but visual improvement

### Hyperlink Support (OSC 8)

Most modern terminals support clickable links:
```
\033]8;;https://example.com\033\\Link Text\033]8;;\033\\
```

**Relevance to OpenCode**:
- Markdown links `[text](url)` could become clickable
- Requires OpenCode to parse markdown and emit OSC 8 codes
- No evidence this is currently implemented

## Markdown Rendering Tools for Terminals

### Existing CLI Tools

1. **glow** (https://github.com/charmbracelet/glow)
   - Renders markdown beautifully in terminals
   - Uses `glamour` library (Go)
   - **Key Features**:
     - Syntax-highlighted code blocks
     - Styled headers, lists, quotes
     - Box-drawing tables (limited)
     - Clickable links
   - **Limitation**: Still plain text, not rich HTML

2. **mdcat** (https://github.com/swsnr/mdcat)
   - Markdown viewer for terminals
   - Supports inline images (iTerm2, Kitty protocols)
   - **Key Features**:
     - Styled text (bold via ANSI)
     - Syntax highlighting
     - Image rendering (if terminal supports)
   - **Limitation**: External tool, not integrated

3. **rich** (Python library)
   - Can render markdown to terminal
   - Uses Unicode and ANSI colors
   - **Limitation**: Python-specific, not Rust

### Integration Challenges

For OpenCode to use these approaches:

1. **Architecture Change**: Would need markdown parser in Rust
2. **Performance**: Real-time parsing could slow down streaming responses
3. **Terminal Detection**: Need to detect terminal capabilities
4. **Backwards Compatibility**: Plain terminals would break

## Neovim-Specific Considerations

### Neovim Terminal Buffers

When running OpenCode inside Neovim via `:terminal`:
- Neovim emulates a terminal (using libvterm internally)
- Supports standard ANSI escape codes
- **Does NOT** have special markdown rendering
- Limited to what a normal terminal can display

### Potential Neovim Workaround

Neovim has **native markdown rendering** for buffers:
- Treesitter markdown parsing
- `render-markdown.nvim` plugin (floating windows)
- Concealment features (hiding syntax)

**Hypothetical Integration**:
1. Parse OpenCode output
2. Extract markdown blocks
3. Render in separate Neovim buffer with rich formatting
4. Display side-by-side or in floating window

**Challenges**:
- Complex synchronization
- Not the OpenCode TUI itself (separate view)
- Requires custom Neovim plugin (doesn't exist yet)

## Conclusions

1. **No Native Support**: No terminal emulator natively renders markdown as rich text
2. **Best-Effort Styling**: Tools like `glow` use Unicode + ANSI to approximate rendering
3. **OpenCode Gap**: OpenCode currently does NO markdown processing beyond raw text
4. **Feasible Improvements**:
   - ✅ Box-drawing tables (via Unicode)
   - ✅ Clickable links (via OSC 8)
   - ✅ Syntax-highlighted code blocks (already done?)
   - ❌ True bold/italic (ANSI only)
   - ❌ Proportional fonts
   - ❌ Nested layouts

5. **Neovim Opportunity**: A custom plugin could render markdown in separate buffers, but wouldn't affect the TUI itself

## Recommendations

1. **Short-term**: OpenCode could implement `glow`-style rendering (Rust markdown parser + ANSI/Unicode output)
2. **Medium-term**: Feature request for optional markdown processing in `opentui`
3. **Long-term**: Native Neovim frontend (not TUI-based) with full markdown support
4. **User Workaround**: Pipe output through `glow` or similar for viewing

## Sources
- Kitty Graphics Protocol Documentation
- WezTerm Image Protocol Docs
- `glow` GitHub Repository
- Neovim Terminal Documentation
- OSC 8 Hyperlink Specification

**Confidence Level**: High (85%) - Terminal capabilities are well-documented, but OpenCode's internal architecture is less transparent
**Date**: 2025-12-15
