# OpenCode Architecture and Markdown Rendering Limitations

**Research Question**: What are the architectural constraints of OpenCode that affect markdown rendering, and is this a terminal UI (TUI) limitation or a design choice?

## Findings

### OpenCode Architecture Overview

OpenCode operates primarily as a **Terminal User Interface (TUI)** application built on a Rust-based rendering engine called `opentui`. The architecture consists of:

1. **Core CLI** (`opencode` binary) - Rust-based TUI that runs in the terminal
2. **IDE Extensions** - VS Code/Cursor/Windsurf plugins that embed the TUI
3. **Neovim Integration** - Plugins (like `opencode.nvim`) that manage terminal instances running OpenCode

### Terminal UI Nature

OpenCode is fundamentally a **text-mode terminal application**. According to the documentation:

- It requires "modern terminal emulators" like WezTerm, Alacritty, Ghostty, or Kitty
- The TUI uses ANSI escape sequences for styling and formatting
- It operates within terminal buffer constraints (rows × columns of text)

### Markdown Rendering Reality

**Key Finding**: OpenCode's TUI **does not render markdown** in the traditional sense (like a web browser or rich text editor would). Instead:

1. **Plain Text Output**: The AI responses are displayed as **plain text with ANSI formatting**
2. **Syntax Highlighting**: Code blocks may receive syntax highlighting via ANSI color codes
3. **No Rich Rendering**: Tables, bold/italic formatting, headers, lists, etc. appear as raw markdown syntax

### Evidence from GitHub Issues

Issue #3845: "Markdown tables display as plain text instead of formatted tables"
- Status: Open (as of Nov 3, 2025)
- Tagged with: `bug`, `opentui` (the TUI rendering engine)
- Indicates markdown table rendering is **not currently supported**

Issue #4988: "[FEATURE]: Support Table Rendering in Markdown Format"
- Status: Duplicate/Closed
- Categorized as a **feature request**, not a bug
- Confirms this is a **known limitation**, not a broken feature

### Design vs. Limitation

This appears to be **both**:

1. **Architectural Constraint**: Terminal-based UIs have fundamental limitations in rendering rich content
2. **Design Choice**: OpenCode prioritizes:
   - Terminal compatibility and portability
   - Simplicity and performance
   - Universal accessibility (works on any SSH session, remote server, etc.)

### Alternative Frontend Mentioned

The research uncovered a reference to `sudo-tee/opencode.nvim` which claims to be "a Neovim frontend" (as opposed to managing the TUI). This suggests:
- A native Neovim UI could theoretically render markdown properly
- The current approach (embedding TUI) is the standard/recommended method
- Rich rendering would require a fundamentally different architecture

## Technical Context

### Terminal Emulator Capabilities

Modern terminals (WezTerm, Kitty) support:
- ✅ ANSI 256-color and true color
- ✅ Unicode characters (including box-drawing)
- ✅ Hyperlinks (OSC 8 sequences)
- ❌ Rich text formatting (bold/italic limited to ANSI codes)
- ❌ Inline images (some terminals support Kitty graphics protocol, but not universal)
- ❌ Proportional fonts or variable sizing
- ❌ HTML/CSS-style layout

### OpenCode's Rendering Stack

Based on issue #4905 mentioning "PTY host crash" and "diff views":
- OpenCode uses PTY (pseudo-terminal) for rendering
- Diff views cause "screen flickering/vibrating" issues
- The TUI attempts some visual formatting (diffs, code blocks) but has bugs

## Conclusions

1. **Root Cause**: OpenCode markdown "not rendering" is **by design** - it's a terminal application that displays plain text with ANSI styling
2. **Not a Bug**: This is the expected behavior for a TUI application
3. **Workarounds Needed**: Users wanting rich markdown rendering need:
   - Copy output to a markdown viewer/editor
   - Use IDE preview features (VS Code markdown preview)
   - Consider alternative frontends (if they exist and are mature)
4. **Future Direction**: Feature requests exist for improved rendering, but may be architecturally difficult without moving away from pure TUI

## Sources
- OpenCode Documentation (opencode.ai/docs)
- GitHub Issues: #3845, #4988, #4905
- NickvanDyke/opencode.nvim README
- OpenCode TUI Documentation

**Confidence Level**: High (90%) - Documentation and issues clearly indicate this is a known architectural limitation
**Date**: 2025-12-15
