# Springer Publisher Templates

This directory contains official Springer Nature journal and publication templates for academic submissions.

## File Structure

```
springer/
├── README.md           # This documentation
├── sn-article.tex     # Springer Nature article template
└── sn-jnl.cls         # Springer document class file
```

## Files

### sn-article.tex
Official Springer Nature journal article template for academic submissions.

**Features:**
- Publisher-compliant formatting and structure
- Multiple reference style options (numbered, authoryear, etc.)
- Structured abstract and keyword sections
- Author affiliation and ORCID support
- Journal-specific configuration options

**Key Sections:**
- Document class configuration with publisher options
- Author information and institutional affiliations
- Abstract and keyword formatting
- Main text structure with standard academic sections
- Bibliography and citation management
- Appendices and supplementary material support

### sn-jnl.cls
Springer Nature document class file providing the formatting foundation.

**Features:**
- Publisher-standard typography and layout
- Automated formatting for journal requirements
- Citation and reference style enforcement
- Figure and table formatting specifications
- Mathematical notation and equation formatting

## Template Usage

### Journal Submission
The Springer template is designed for direct submission to Springer journals:

1. **Configuration**: Select appropriate journal and reference style
2. **Content**: Fill in author information, abstract, and main content
3. **References**: Use provided bibliography style
4. **Compilation**: Standard LaTeX compilation process
5. **Submission**: Generated PDF meets publisher requirements

### Reference Styles
Multiple citation styles available:
- **Numbered**: `[1]` style references
- **Author-year**: (Smith, 2023) style citations
- **Custom**: Journal-specific formatting options

## Integration

### With Neovim LaTeX Workflow
- **Template Loading**: Available via `<leader>ts` keybinding
- **Compilation**: VimTeX integration for PDF generation
- **Citation Management**: BibTeX/Biber compatibility
- **Spell Checking**: Academic writing support

### With Academic Workflow
- **Bibliography**: Compatible with reference managers
- **Collaboration**: Version control friendly structure
- **Review**: Publisher-compliant formatting for peer review
- **Publication**: Direct submission to Springer journals

## Requirements

### LaTeX Packages
- Standard academic LaTeX distribution
- Publisher-specific packages (included in class file)
- Bibliography management (natbib or biblatex)
- Graphics and mathematical notation support

### External Dependencies
- Modern LaTeX distribution (TeXLive recommended)
- Bibliography processor (BibTeX/Biber)
- PDF viewer for preview and review

## Related Configuration
- [article.tex](../article.tex) - General academic template
- [vimtex.lua](../../lua/neotex/plugins/text/vimtex.lua) - LaTeX compilation setup
- [which-key.lua](../../lua/neotex/plugins/editor/which-key.lua) - Template keybindings

## Navigation

- [← Templates](../README.md)