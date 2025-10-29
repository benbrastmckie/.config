# Document Converter Agent - Quick Start Guide

This guide shows you how to use the doc-converter agent to batch convert Word and PDF files to Markdown.

## Prerequisites

Make sure you have the required tools installed (already in your NixOS config):
- `pandoc` - For DOCX conversion
- `marker-pdf` - For PDF conversion

Verify installation:
```bash
which pandoc      # Should show: /nix/store/.../bin/pandoc
which marker_pdf  # Should show path to marker_pdf
```

## Usage Methods

### Method 1: Using the /convert-docs Command (Recommended)

The simplest way to convert documents:

```bash
# Convert documents in current directory
/convert-docs .

# Convert from specific directory
/convert-docs ~/Documents/Reports

# Specify output directory
/convert-docs ~/Documents/Reports ~/Documents/Markdown
```

### Method 2: Direct Agent Invocation

For more control, invoke the agent directly in your conversation:

```
Please use the doc-converter agent to convert all Word and PDF files
from ~/Documents/Research/ to markdown in ~/Documents/Markdown/.
```

The agent will:
1. Discover all DOCX and PDF files
2. Convert them using optimal tools
3. Extract images to organized directories
4. Validate conversions
5. Report detailed statistics

## Example Workflow

### Converting a Directory of Documents

**Your request**:
```
I have research papers (PDF) and notes (DOCX) in ~/Documents/Papers/.
Convert them all to markdown in ~/Documents/Markdown/.
```

**Agent response**:
```
I'll convert all documents from ~/Documents/Papers/ to Markdown.

PROGRESS: Discovering documents in ~/Documents/Papers/...
Found 8 DOCX files and 12 PDF files.

PROGRESS: Converting DOCX (1 of 8): research_notes.docx...
PROGRESS: Converting DOCX (2 of 8): project_summary.docx...
...
PROGRESS: Converting PDF (1 of 12): academic_paper_2024.pdf...
PROGRESS: Converting PDF (2 of 12): technical_report.pdf...
...
PROGRESS: Validating conversions...
PROGRESS: Conversion complete: 19 succeeded, 1 failed

Summary:
- DOCX conversions: 8 succeeded, 0 failed
- PDF conversions: 11 succeeded, 1 failed
- Total: 19 markdown files created
- Images extracted: 143 files

Failed conversions:
- encrypted_paper.pdf: Password-protected (needs manual unlock)

Output location: ~/Documents/Markdown/
Images location: ~/Documents/Markdown/images/

Recommendations:
- Spot-check 2-3 converted files for quality
- For encrypted_paper.pdf, unlock and re-run conversion
```

## Output Structure

After conversion, you'll have:

```
output_directory/
├── file1.md              # Converted markdown files
├── file2.md
├── file3.md
├── ...
├── images/               # Extracted images organized by source file
│   ├── file1/
│   │   ├── image1.png
│   │   └── image2.jpg
│   ├── file2/
│   │   └── diagram.png
│   └── ...
└── conversion.log        # Detailed conversion log
```

## Common Use Cases

### 1. Converting Legacy Documentation

**Scenario**: You have old Word docs you want to version control

```
Convert all DOCX files in ~/OldDocs/ to markdown in ~/NewDocs/markdown/.
Preserve all images and formatting.
```

### 2. Extracting Content from PDFs

**Scenario**: Research papers or reports you want as markdown

```
Convert all PDF files in ~/Research/papers/ to markdown.
These are academic papers with tables and figures.
Use high-quality conversion settings.
```

### 3. Batch Processing Mixed Documents

**Scenario**: Directory with both Word and PDF files

```
I have a mix of Word docs and PDFs in ~/Documents/Archive/.
Convert everything to markdown in ~/Documents/Converted/.
```

## Quality Checking

After conversion, the agent will report:

**Automatic Checks**:
- File sizes (warns if suspiciously small)
- Heading counts
- Table counts
- Image reference counts

**Manual Review** (recommended for important docs):
1. Open 2-3 converted files
2. Check headings hierarchy
3. Verify tables format correctly
4. Confirm images display properly
5. Test any links

## Troubleshooting

### "pandoc not found"

Your home-manager config should have installed it. If not:
```bash
cd ~/.dotfiles
home-manager switch
```

### "marker_pdf not found"

Make sure marker_pdf is in your home.nix:
```bash
cd ~/.dotfiles
home-manager switch
```

### PDF Conversion Fails

Common reasons:
- **Password-protected**: Unlock PDF first
- **Scanned PDF**: marker-pdf should handle, but quality varies
- **Corrupted file**: Try opening PDF manually to verify

Try alternative tools for difficult PDFs:
```bash
# Alternative: docling
pip install --user docling
python -c "from docling.document_converter import DocumentConverter; converter = DocumentConverter(); result = converter.convert('file.pdf'); print(result.document.export_to_markdown())" > output.md
```

### DOCX Conversion Issues

If Pandoc fails:
```bash
# Try simpler format
pandoc input.docx -t markdown -o output.md

# Or without media extraction
pandoc input.docx -t gfm -o output.md
```

## Advanced Usage

### Custom Conversion Script

The agent can generate standalone scripts for recurring conversions:

```
Generate a bash script for converting documents that I can run regularly.
Input: ~/Documents/Active/
Output: ~/Documents/Markdown/
```

The agent will create a reusable script with:
- Error handling
- Logging
- Statistics reporting
- Safe filename handling

### Filtering by Type

Convert only specific file types:

```
Convert only PDF files from ~/Research/, skip any DOCX files.
```

or

```
Convert only DOCX files from ~/Notes/, ignore PDFs.
```

## Tips for Best Results

1. **Organize before converting**: Clean up file names (remove special characters)
2. **Test with samples**: Try 2-3 files first to check quality
3. **Check file sizes**: Very large files (>100 pages) take longer
4. **Review output**: Spot-check conversions, especially tables and images
5. **Keep originals**: Never delete source files until you've verified conversions

## Performance Expectations

**Typical conversion times**:
- DOCX (Pandoc): 2-5 seconds per file
- PDF (marker-pdf): 5-15 seconds per file
- Large PDFs (50+ pages): 30-60 seconds per file

**Batch processing**:
- 10 files: ~1 minute
- 50 files: ~5-10 minutes
- 100+ files: ~15-30 minutes

## Integration with Neovim

You can invoke the agent directly from Neovim using the Claude Code integration:

1. Open command palette: `<leader>ac` (or `:ClaudeCommands`)
2. Search for "convert-docs"
3. Press Enter to execute

Or use the slash command directly:
```vim
:Claude /convert-docs ~/Documents/Papers ~/Documents/Markdown
```

## Further Reading

- [doc-converter.md](../../agents/doc-converter.md) - Full agent documentation
- [Document Conversion Research Report](../../specs/reports/037_document_conversion_to_markdown.md) - Detailed tool comparison
- [Pandoc Manual](https://pandoc.org/MANUAL.html) - Pandoc documentation
- [marker-pdf GitHub](https://github.com/datalab-to/marker) - marker-pdf documentation

## Questions?

If you need help:
1. Check the [doc-converter.md](../../agents/doc-converter.md) agent documentation
2. Review the research report for tool details
3. Ask the agent for clarification during conversion

The agent is designed to be helpful and provide detailed explanations of any issues encountered!
