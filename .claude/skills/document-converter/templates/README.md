# Document Converter Templates

This directory contains Pandoc templates and batch conversion scripts for the document-converter skill.

## Templates

Templates customize the conversion output format:

- **batch-conversion.sh** - Batch process multiple files with conversion

Future templates may include:
- **default.docx** - Default DOCX template for Markdown conversion
- **report.docx** - Report-style DOCX template
- **minimal.docx** - Minimal styling DOCX template

## Template Structure

Pandoc templates use template syntax to control:
- Document structure (headers, footers, styles)
- Formatting defaults (fonts, margins, spacing)
- Metadata mapping (title, author, date)

## Usage

Templates are referenced during conversion:

```bash
# Example usage (when templates exist)
pandoc input.md -o output.docx --reference-doc=templates/default.docx
```

## Customization

To create custom templates:
1. Start with an existing DOCX file with desired styling
2. Save as reference template in this directory
3. Reference template during conversion with `--reference-doc` flag

## Navigation

[← Parent](../)
