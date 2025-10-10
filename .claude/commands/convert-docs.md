# Convert Documents - Bidirectional Conversion

Convert between Markdown, Word (DOCX), and PDF formats using the doc-converter agent. Direction is automatically detected from file extensions.

## Usage

```bash
/convert-docs <input-directory> [output-directory]
```

## Parameters

- `input-directory` (required): Directory containing files to convert
  - `.docx` or `.pdf` files → Converts TO Markdown
  - `.md` files → Converts TO PDF and DOCX
- `output-directory` (optional): Where to save converted files (default: `./converted_output`)

## Examples

### Converting TO Markdown

```bash
# Convert DOCX/PDF to Markdown in current directory
/convert-docs .

# Convert documents from specific directory
/convert-docs ~/Documents/Reports

# Specify custom output directory
/convert-docs ~/Documents/Reports ~/Documents/Markdown
```

### Converting FROM Markdown

```bash
# Convert Markdown files to PDF and DOCX
/convert-docs ~/Documents/Markdown ~/Documents/PDFs

# Convert project documentation to distributable formats
/convert-docs ./docs ./docs-output

# Convert notes to Word/PDF
/convert-docs ~/notes/md ~/notes/formatted
```

## What It Does

The doc-converter agent provides bidirectional conversion:

### Converting TO Markdown
1. **Discover** all DOCX and PDF files in the input directory
2. **Convert** using optimal tools:
   - DOCX files → Pandoc (best quality for Word)
   - PDF files → marker-pdf (AI-powered PDF processing)
3. **Extract** images to organized directories
4. **Validate** conversion results and check quality
5. **Report** detailed statistics and any failures

### Converting FROM Markdown
1. **Discover** all Markdown (.md) files in the input directory
2. **Check PDF Engine** (Typst or XeLaTeX for PDF generation)
3. **Convert** to both formats using Pandoc:
   - Markdown → DOCX (excellent quality, 95%+ preservation)
   - Markdown → PDF (with Typst or XeLaTeX engine)
4. **Embed images** automatically from relative paths
5. **Validate** and report conversion results

## Output Structure

```
output_directory/
├── file1.md
├── file2.md
├── ...
├── images/
│   ├── file1/
│   │   ├── image1.png
│   │   └── image2.jpg
│   └── file2/
│       └── diagram.png
└── conversion.log
```

## Task

I need you to invoke the doc-converter agent to batch convert Word and PDF files to Markdown.

### Input Parameters

- **Input Directory**: `{arg1}` (or current directory if not specified)
- **Output Directory**: `{arg2}` (or `./markdown_output` if not specified)

### Agent Invocation

Use the Task tool to invoke a general-purpose agent with doc-converter behavioral guidelines:

```
Task {
  subagent_type: "general-purpose"
  description: "Convert documents to Markdown"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-converter.md

    You are acting as a Document Conversion Agent with the tools and
    constraints defined in that file.

    Convert documents with automatic direction detection:
    - Input directory: {input_directory}
    - Output directory: {output_directory}
    - Direction: Auto-detect from file extensions
      - .docx/.pdf files → Convert TO Markdown
      - .md files → Convert TO PDF and DOCX
    - Extract/embed images: Yes
    - Validate conversions: Yes
    - Generate conversion log: Yes

    Follow the conversion workflow defined in the agent guidelines:
    1. Discovery phase - Detect file types and conversion direction
    2. Conversion phase - Process with appropriate tools and direction
    3. Validation phase - Check output quality
    4. Reporting phase - Provide detailed statistics

    Use PROGRESS markers to provide real-time updates during batch conversion.

    After conversion completes, provide:
    - Conversion statistics (succeeded/failed by type)
    - List of any failed conversions with reasons
    - Location of output files and images
    - Quality warnings or recommendations
}
```

### Expected Output

The agent will provide:
- Real-time progress updates during conversion
- Detailed conversion statistics
- List of any failures with diagnostic information
- Paths to output files
- Quality validation results
- Next steps recommendations

### Error Handling

If tools are missing (pandoc, marker-pdf), the agent will:
- Report which tools are unavailable
- Skip conversions for unsupported formats
- Provide installation instructions

### Quality Assurance

The agent performs automatic validation:
- Check for suspiciously small output files
- Count headings and tables
- Verify image references
- Report any quality concerns
