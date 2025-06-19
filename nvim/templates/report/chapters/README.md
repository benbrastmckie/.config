# Report Chapters

This directory contains individual chapter templates for multi-chapter documents. Each chapter can be compiled independently while integrating seamlessly with the main document structure.

## File Structure

```
chapters/
├── README.md           # This documentation
├── ch01/              # Chapter 1 template
│   └── ch01.tex       # Chapter 1 content
└── ch02/              # Chapter 2 template
    └── ch02.tex       # Chapter 2 content
```

## Chapter Organization

### ch01/
First chapter template demonstrating basic chapter structure and content organization.

**Contents:**
- `ch01.tex` - Complete chapter template with sample content

### ch02/
Second chapter template showing advanced features and cross-referencing.

**Contents:**
- `ch02.tex` - Advanced chapter template with examples

## Chapter Template Features

### Document Structure
Each chapter template includes:
- **Subfile integration**: Proper `\documentclass[../../Root.tex]{subfiles}` declaration
- **Chapter header**: Automatic chapter numbering and title formatting
- **Section organization**: Hierarchical section, subsection, subsubsection structure
- **Content examples**: Sample text, figures, tables, and mathematical content

### Cross-Referencing
- **Labels**: Proper label naming convention (`ch01:section`, `ch01:figure`, etc.)
- **References**: Examples of cross-references within and between chapters
- **Citations**: Bibliography reference examples using shared reference list
- **Numbering**: Coordinated numbering with main document

### Academic Content
- **Mathematical notation**: Equation examples with proper formatting
- **Figures and tables**: Professional figure and table templates
- **Theorem environments**: Definitions, theorems, proofs, and examples
- **Citations**: Academic reference and citation examples

## Usage Patterns

### Independent Development
Each chapter can be developed and compiled independently:
```bash
cd chapters/ch01/
pdflatex ch01.tex  # Fast compilation for editing
```

### Integration with Main Document
Chapters integrate automatically when compiling the main document:
```latex
% In Root.tex
\subfile{chapters/ch01/ch01}
\subfile{chapters/ch02/ch02}
```

### Chapter Workflow
1. **Copy template**: Use existing chapter as starting point
2. **Rename**: Update file names and chapter titles
3. **Edit content**: Replace sample content with actual material
4. **Test compilation**: Verify independent compilation works
5. **Integrate**: Add `\subfile{}` command to Root.tex

## Template Customization

### Content Areas
- **Introduction**: Chapter overview and objectives
- **Main content**: Core material organized in sections
- **Examples**: Illustrative examples and case studies
- **Conclusion**: Chapter summary and connections to other chapters

### Formatting Options
- **Section depth**: Adjust hierarchical organization
- **Mathematical content**: Customize theorem environments
- **Figure placement**: Optimize figure and table positioning
- **Bibliography**: Chapter-specific vs. document-wide references

## File Naming Convention

### Directory Structure
```
chapters/
├── ch01/
│   └── ch01.tex
├── ch02/
│   └── ch02.tex
└── chXX/
    └── chXX.tex
```

### Label Convention
- **Sections**: `ch01:intro`, `ch01:methods`, `ch01:results`
- **Figures**: `ch01:fig:diagram`, `ch01:fig:results`
- **Tables**: `ch01:tab:data`, `ch01:tab:comparison`
- **Equations**: `ch01:eq:main`, `ch01:eq:derivation`

## Integration Points

### With Main Document
- **Shared preamble**: Inherits all packages and settings from Root.tex
- **Consistent formatting**: Maintains document-wide style
- **Coordinated numbering**: Chapter, section, figure numbering
- **Bibliography**: References shared bibliography database

### With Development Workflow
- **Version control**: Each chapter is a separate file for clear history
- **Parallel development**: Multiple authors can work on different chapters
- **Review process**: Individual chapter review and approval
- **Compilation speed**: Fast iteration during chapter development

## Related Configuration
- [Root.tex](../Root.tex) - Main document template
- [templates/](../../README.md) - Template overview and keybindings
- [vimtex.lua](../../../lua/neotex/plugins/text/vimtex.lua) - LaTeX compilation setup

## Navigation

- [← Report Templates](../README.md)
- [← Templates](../../README.md)