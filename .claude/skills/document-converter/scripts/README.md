# Document Converter Scripts

This directory contains conversion scripts for the document-converter skill. Scripts handle bidirectional conversion between Markdown, DOCX, and PDF formats.

## Scripts

Currently, this directory is empty as conversion logic is handled directly by the parent skill. Scripts may be added for:

- **markdown-to-docx.sh** - Convert Markdown files to DOCX format
- **docx-to-markdown.sh** - Extract Markdown from DOCX files
- **pdf-to-markdown.sh** - Extract text from PDF files
- **batch-conversion.sh** - Batch process multiple files

## Usage

Scripts in this directory are invoked by the document-converter skill agent. They can also be run directly:

```bash
# Example (when scripts exist)
bash .claude/skills/document-converter/scripts/markdown-to-docx.sh input.md output.docx
```

## Integration

Scripts integrate with:
- Pandoc for Markdown ↔ DOCX conversion
- PDF text extraction utilities
- Template system in ../templates/

## Navigation

[← Parent](../)
