# Code Snippets

This directory contains custom code snippets for various file types to accelerate coding and document preparation.

## File Structure

```
snippets/
├── README.md           # This documentation
├── markdown.snippets  # Markdown document snippets
├── python.snippets    # Python development snippets
└── tex.snippets       # LaTeX document snippets
```

## Files

### markdown.snippets
Snippets for Markdown document creation and formatting.

**Common Snippets:**
- Document structure (headers, tables, lists)
- Academic writing elements (citations, footnotes)
- Code block templates
- Link and image insertion patterns
- LaTeX math notation within Markdown

### python.snippets
Python development snippets for common patterns and structures.

**Common Snippets:**
- Function and class definitions
- Control flow structures (if/else, loops)
- Exception handling patterns
- Testing frameworks (pytest, unittest)
- Documentation strings and type hints
- Import statement templates

### tex.snippets
LaTeX document preparation snippets for academic and professional writing.

**Common Snippets:**
- Document structure (sections, subsections)
- Mathematical environments (equations, theorems, proofs)
- Bibliography and citation patterns
- Figure and table templates
- Academic formatting (abstracts, acknowledgments)
- Beamer presentation elements

## Usage

Snippets are activated through the completion system:
1. Type snippet trigger text
2. Press `<Tab>` to expand
3. Use `<Tab>` and `<Shift-Tab>` to navigate placeholders
4. Press `<Esc>` to exit snippet mode

## Integration

Snippets integrate with:
- **LuaSnip**: Primary snippet engine
- **blink.cmp**: Completion system for snippet discovery
- **which-key**: Snippet-related keybindings under `<leader>s`

## Related Configuration
- [plugins/tools/luasnip.lua](../lua/neotex/plugins/tools/luasnip.lua) - Snippet engine configuration
- [plugins/lsp/blink-cmp.lua](../lua/neotex/plugins/lsp/blink-cmp.lua) - Completion integration
- [templates/](../templates/README.md) - Document templates

## Navigation

- [Templates →](../templates/README.md)
- [LSP Configuration →](../lua/neotex/plugins/lsp/README.md)
- [← Main Configuration](../README.md)