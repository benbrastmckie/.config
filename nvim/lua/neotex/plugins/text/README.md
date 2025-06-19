# Text Format Plugins

This directory contains plugins that provide specialized support for various text formats and languages, with particular emphasis on academic writing, mathematical notation, and technical documentation.

## File Structure

```
text/
├── README.md           # This documentation
├── init.lua           # Text plugins loader
├── vimtex.lua         # LaTeX editing and compilation
├── markdown-preview.lua # Markdown live preview
├── lean.lua           # Lean theorem prover
└── jupyter/           # Jupyter notebook support
    ├── README.md      # Jupyter documentation
    ├── init.lua       # Main Jupyter configuration
    ├── autocommands.lua # Jupyter autocommands
    └── styling.lua    # Jupyter visual styling
```

## Core Modules

### Document Formats
- **[vimtex.lua](vimtex.lua)** - Comprehensive LaTeX editing and compilation support
- **[markdown-preview.lua](markdown-preview.lua)** - Live Markdown preview and export capabilities
- **[jupyter/](jupyter/README.md)** - Jupyter notebook editing and execution within Neovim

### Programming Languages
- **[lean.lua](lean.lua)** - Lean theorem prover integration and mathematical notation

These plugins provide enhanced editing, navigation, and visualization capabilities specific to different text formats and languages, offering a more tailored experience for working with specialized content types.

## Features

### LaTeX Features (vimtex.lua)
- **Document compilation**: Automatic compilation with latexmk and continuous preview
- **Navigation**: Table of contents, label jumping, and document structure
- **Citation management**: BibTeX integration with completion and formatting
- **Mathematical notation**: Enhanced math mode editing and symbol insertion
- **Multi-file projects**: Support for complex documents with proper cross-referencing
- **Template integration**: Seamless integration with document templates

### Jupyter Notebook Features (jupyter/)
- **Cell management**: Navigate, execute, and modify notebook cells
- **Kernel integration**: Connect to and manage Jupyter kernels
- **Rich output**: Display plots, HTML, and interactive content
- **Multi-language support**: Python, R, Julia, and other kernel languages
- **Visual enhancements**: Custom styling and appearance improvements

### Lean Features (lean.lua)
- **Interactive theorem proving**: Real-time proof state visualization
- **Mathematical Unicode**: Smart input for mathematical symbols
- **Language server**: Lean 4 LSP integration with error checking
- **Library access**: Integration with mathlib and custom libraries
- **Proof assistance**: Tactic completion and goal inspection

### Markdown Features (markdown-preview.lua)
- **Live preview**: Real-time HTML preview in browser
- **Mathematical support**: MathJax/KaTeX for mathematical notation
- **Export capabilities**: PDF, HTML, and other format generation
- **GitHub integration**: GitHub-flavored Markdown rendering
- **Custom themes**: CSS styling and appearance customization

## Plugin Analysis

To verify text format plugins are properly loaded and organized:

```vim
:luafile scripts/check_plugins.lua
```

This will show the TEXT category with plugins like vimtex.lua, markdown-preview.lua, lean.lua, and jupyter components. 

### LaTeX-Specific Debugging

For troubleshooting LaTeX citation completion issues:

```vim
:luafile scripts/debug_citations.lua
```

This script specifically diagnoses VimTeX and blink.cmp integration problems in LaTeX files.

See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation and the main [plugins README](../README.md#plugin-analysis-and-maintenance) for more details.

## Integration

### With Editor Core
- **Syntax highlighting**: Language-specific highlighting via Treesitter
- **Completion**: Text-aware completion with LSP integration
- **Templates**: Document template integration and management
- **File type detection**: Automatic configuration based on file extensions

### With Development Tools
- **Version control**: Git integration for document collaboration
- **Project management**: Multi-file project support and session management
- **Build systems**: Compilation and preview automation

## Related Modules

- **LSP Configuration**: Language servers → [lsp/](../lsp/)
- **Editor Enhancements**: Core editing → [editor/](../editor/)
- **Templates**: Document templates → [../../../templates/](../../../templates/)
- **Snippets**: Code snippets → [../../../snippets/](../../../snippets/)

## Navigation

- [Jupyter Integration →](jupyter/README.md)
- [Tools Plugins →](../tools/README.md)
- [Editor Plugins →](../editor/README.md)
- [LSP Configuration →](../lsp/README.md)
- [UI Plugins →](../ui/README.md)
- [AI Plugins →](../ai/README.md)
- [← Plugins Overview](../README.md)