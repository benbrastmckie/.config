# Document Conversion Guide

Quick-start guide for bidirectional document conversion: convert between Word/PDF and Markdown formats using the `/convert-docs` command.

## Table of Contents

- [Quick Start](#quick-start)
- [Example Patterns](#example-patterns)
- [Converting FROM Markdown](#converting-from-markdown)
- [What It Does](#what-it-does)
- [Tool Information](#tool-information)
- [Quality Expectations](#quality-expectations)

## Quick Start

The `/convert-docs` command provides bidirectional document conversion:

- **TO Markdown**: Convert Word documents (DOCX) and PDF files to Markdown format
- **FROM Markdown**: Convert Markdown files to PDF or DOCX format

The command automatically detects conversion direction based on file extensions in the input directory.

### Basic Syntax

```
/convert-docs <input-directory> [output-directory] [file-types]
```

**Parameters**:
- `input-directory` (required): Directory containing files to convert
- `output-directory` (optional): Where to save converted Markdown files (default: same as input)
- `file-types` (optional): Comma-separated list like `docx,pdf` (default: both)

### Simplest Usage

Convert all DOCX and PDF files in a directory:

```
/convert-docs ./my-documents
```

This converts all Word and PDF files in `./my-documents` and saves the Markdown files in the same directory.

## Example Patterns

### 1. Convert a Single Directory

Convert all documents in one location:

```
/convert-docs /home/benjamin/Documents/research
```

All DOCX and PDF files in the research directory will be converted to `.md` files in the same location.

### 2. Convert with Custom Output Location

Keep source files separate from converted files:

```
/convert-docs ./source-docs ./converted-markdown
```

Original files stay in `./source-docs`, converted Markdown files go to `./converted-markdown`.

### 3. Convert Only DOCX Files

Process only Word documents:

```
/convert-docs ./documents ./markdown docx
```

PDFs in the directory will be ignored. Only `.docx` files are converted.

### 4. Convert Only PDF Files

Process only PDF documents:

```
/convert-docs ./pdfs ./markdown pdf
```

Only `.pdf` files are converted. Word documents are ignored.

### 5. Batch Process Large Collections

Convert an entire document library:

```
/convert-docs /mnt/backup/company-docs /home/benjamin/markdown-archive
```

The command recursively processes all DOCX and PDF files in subdirectories, maintaining the directory structure in the output location.

## Converting FROM Markdown

The `/convert-docs` command supports reverse conversion: transforming Markdown files to PDF or DOCX formats.

### How Direction Detection Works

The command automatically detects conversion direction based on file extensions:

- **Input contains `.md` files**: Converts FROM Markdown TO PDF/DOCX
- **Input contains `.docx` or `.pdf` files**: Converts TO Markdown (standard direction)
- **Input contains both**: Command will ask for clarification

### Basic Markdown Conversion

Convert Markdown files to both PDF and DOCX:

```
/convert-docs ./markdown-docs ./output
```

By default, each `.md` file produces both a `.pdf` and `.docx` file in the output directory.

### Example Patterns for Markdown Conversion

#### 1. Convert Documentation to PDF

Convert technical documentation to PDF format:

```
/convert-docs ./docs ./pdf-output
```

All Markdown files in `./docs` are converted to PDF (and DOCX) in `./pdf-output`.

#### 2. Convert Notes to Word Format

Convert personal notes to Word documents:

```
/convert-docs ~/notes/markdown ~/notes/docx
```

Great for sharing Markdown notes with colleagues who prefer Word.

#### 3. Batch Convert Research Papers

Convert a collection of Markdown research papers:

```
/convert-docs ~/research/papers ~/research/formatted
```

Produces professional PDF and DOCX versions of your Markdown papers.

#### 4. Convert README to Document

Convert project documentation to distributable formats:

```
/convert-docs ./project-docs ./release-docs
```

Useful for creating user guides from Markdown documentation.

### PDF Engine Requirements

Converting Markdown to PDF requires a PDF engine. The command supports:

**Recommended: Typst**
- Modern, fast PDF engine
- Excellent Unicode support
- Better handling of emoji and special characters
- Installation:
  ```bash
  # NixOS (in configuration.nix)
  environment.systemPackages = [ pkgs.typst ];

  # Or via nix-env
  nix-env -iA nixpkgs.typst
  ```

**Alternative: XeLaTeX**
- Traditional LaTeX engine (likely already installed)
- Part of texlive-full package
- Good Unicode support
- Command checks for this automatically

The conversion agent will:
1. Check for Typst first (preferred)
2. Fall back to XeLaTeX if Typst unavailable
3. Warn if no PDF engine found

### Output Format Details

**Default behavior** (single Markdown file):
```
input: document.md
output: document.pdf, document.docx
```

**Batch processing** (multiple Markdown files):
```
input directory:
  ├── doc1.md
  ├── doc2.md
  └── doc3.md

output directory:
  ├── doc1.pdf
  ├── doc1.docx
  ├── doc2.pdf
  ├── doc2.docx
  ├── doc3.pdf
  └── doc3.docx
```

### Quality Preservation

**Markdown → DOCX**:
- Excellent quality (95%+ accuracy)
- Headings, lists, tables preserved perfectly
- Images embedded automatically (from relative paths)
- Text formatting (bold, italic, code) maintained
- Links converted to Word hyperlinks

**Markdown → PDF**:
- Good to excellent quality
- Depends on PDF engine (Typst recommended)
- Unicode and special characters handled well
- Tables and code blocks formatted cleanly
- Professional-looking output

### Common Use Cases

**1. Share Documentation with Non-Technical Users**
```
/convert-docs ./technical-docs ./user-docs
```
Convert Markdown technical docs to Word/PDF for stakeholders.

**2. Create Distributable Reports**
```
/convert-docs ./reports/markdown ./reports/final
```
Generate professional PDF reports from Markdown sources.

**3. Archive Version-Controlled Docs**
```
/convert-docs ./repo-docs ./archived-pdfs
```
Create point-in-time PDF snapshots of evolving Markdown documentation.

**4. Convert Blog Posts to Documents**
```
/convert-docs ~/blog/posts ~/blog/printable
```
Make printable/distributable versions of Markdown blog content.

### Limitations

Some Markdown features may not convert perfectly:

- **Custom HTML**: HTML blocks in Markdown may not convert to PDF/DOCX
- **Advanced Tables**: Complex table layouts may need adjustment
- **Code Syntax Highlighting**: Language-specific highlighting lost in conversion
- **Markdown Extensions**: Non-standard Markdown syntax may not be supported

### Tips for Best Results

**1. Use Standard Markdown**
Stick to CommonMark syntax for best compatibility across formats.

**2. Use Relative Image Paths**
```markdown
![Alt text](./images/diagram.png)
```
Pandoc will embed images automatically if paths are relative.

**3. Test with Sample Files**
Try converting a few files first to verify output quality before batch processing.

**4. Check PDF Engine**
Verify you have a PDF engine installed:
```bash
which typst    # Check for Typst
which xelatex  # Check for XeLaTeX
```

## What It Does

The `/convert-docs` command provides intelligent bidirectional document conversion through an automated agent system.

### How It Works

**Converting TO Markdown**:
1. **Scans Directory**: Finds all DOCX and PDF files in the input directory and subdirectories
2. **Selects Tools**: Automatically chooses the best conversion tool for each file type
3. **Converts Files**: Processes each file using specialized conversion tools
4. **Extracts Media**: Saves embedded images to an organized media directory
5. **Generates Markdown**: Creates clean, readable Markdown files with proper formatting

**Converting FROM Markdown**:
1. **Scans Directory**: Finds all Markdown (.md) files in the input directory
2. **Checks PDF Engine**: Verifies Typst or XeLaTeX is available for PDF generation
3. **Converts to DOCX**: Uses Pandoc to create Word documents from Markdown
4. **Converts to PDF**: Uses Pandoc with PDF engine to create PDF files
5. **Embeds Images**: Automatically embeds images from relative paths in output files

### What Gets Converted

The command preserves important document elements:

- **Headings**: Document structure with proper heading levels
- **Lists**: Ordered and unordered lists with nesting
- **Tables**: Converted to Markdown table format
- **Images**: Extracted to separate files and linked in Markdown
- **Links**: URL and cross-references maintained
- **Text Formatting**: Bold, italic, and other basic formatting
- **Code Blocks**: Programming code preserved with formatting

### Tools Used

The conversion agent uses specialized tools based on conversion direction:

**Converting TO Markdown**:

- **Pandoc** for Word Documents (DOCX):
  - Industry-standard document converter
  - 95%+ conversion accuracy for Word files
  - Excellent preservation of formatting and structure

- **marker_pdf** for PDF Files:
  - AI-powered PDF converter
  - Handles complex PDFs with tables and images
  - Works well with both text-based and scanned PDFs

**Converting FROM Markdown**:

- **Pandoc** for both DOCX and PDF output:
  - Universal document converter
  - Creates professional Word documents
  - Generates PDF via Typst or XeLaTeX engine
  - Excellent quality preservation (95%+ for DOCX)
  - Automatic image embedding

## Quality Expectations

### DOCX Conversion Quality

Word document conversion provides excellent results:

- Heading styles convert perfectly to Markdown headers
- Lists maintain hierarchy and formatting
- Tables convert to standard Markdown pipe tables
- Images are extracted and properly referenced
- Text formatting (bold, italic) preserved accurately

**Expected Accuracy**: 95%+ for documents using standard Word styles

### PDF Conversion Quality

PDF conversion quality depends on document complexity:

**Text-Based PDFs**:
- Clean text extraction
- Good structure preservation
- Reliable table conversion

**Scanned PDFs**:
- AI-powered OCR handles image-based text
- Tables and complex layouts processed intelligently
- Quality depends on scan quality and document complexity

**Expected Accuracy**: Good to excellent, with better results for well-formatted documents

### Common Limitations

Some elements may require manual review:

- Complex multi-level tables may need formatting adjustments
- Heavily formatted documents may lose some visual styling
- Scanned documents with poor image quality may have OCR errors
- Custom fonts and advanced typography are simplified

## Tool Information

### Pandoc: Universal Document Converter

**What Pandoc Does**:
Pandoc is a universal document converter that handles bidirectional conversion between Word, PDF, and Markdown formats. It reads document structures and converts between formats while preserving content and formatting.

**Why We Use It**:
- Industry-standard tool with proven reliability
- Excellent format preservation in both directions
- Handles complex document structures
- Actively maintained with extensive documentation
- Supports PDF generation via multiple engines

**Basic Functionality**:
- **To Markdown**: Converts DOCX files to multiple Markdown variants
- **From Markdown**: Generates DOCX and PDF from Markdown files
- Extracts and embeds images automatically
- Preserves document metadata and structure
- Supports customization through command-line options

**Learn More**:
- Repository: https://github.com/jgm/pandoc
- Manual: https://pandoc.org/MANUAL.html
- Official Site: https://pandoc.org/

**Installation** (if running manually):
```bash
# Ubuntu/Debian
sudo apt install pandoc

# macOS
brew install pandoc

# Arch Linux
sudo pacman -S pandoc
```

### marker_pdf: PDF Conversion

**What marker_pdf Does**:
marker_pdf is an AI-powered PDF converter that uses machine learning to understand document structure. It can handle complex PDFs including scanned documents, tables, images, and mixed content.

**Why We Use It**:
- AI-powered for intelligent structure recognition
- Handles both text-based and scanned PDFs
- Fast batch processing capabilities
- Extracts images with proper text flow
- Open-source and actively maintained

**Basic Functionality**:
- Converts PDF files to Markdown format
- OCR support for scanned documents
- Table structure detection and conversion
- Image extraction with text alignment
- Layout analysis for complex documents

**Performance Notes**:
- First run downloads ML model dependencies (may take a few minutes)
- Subsequent conversions are fast
- More complex PDFs take longer to process
- AI models improve accuracy over time

**Learn More**:
- Repository: https://github.com/datalab-to/marker
- Documentation: See repository README

**Installation** (if running manually):
```bash
pip install marker-pdf
```

### PDF Engines: Typst and XeLaTeX

**What PDF Engines Do**:
PDF engines are required for converting Markdown to PDF format. They take Markdown content (processed by Pandoc) and render it as a formatted PDF document.

**Supported Engines**:

**Typst (Recommended)**:
- Modern, fast PDF generation
- Excellent Unicode and emoji support
- Clean, professional output
- Better handling of complex characters
- Installation:
  ```bash
  # NixOS (configuration.nix)
  environment.systemPackages = [ pkgs.typst ];

  # Via nix-env
  nix-env -iA nixpkgs.typst

  # Other systems
  # See: https://github.com/typst/typst
  ```

**XeLaTeX (Traditional)**:
- Part of TeX Live distribution
- Widely available on most systems
- Good Unicode support
- Established, reliable
- Usually pre-installed via texlive-full

**Engine Selection**:
The conversion agent automatically:
1. Checks for Typst first (preferred for quality)
2. Falls back to XeLaTeX if available
3. Warns if no PDF engine found

**Why Typst is Preferred**:
- Faster processing
- Better handling of modern Unicode (emoji, symbols)
- Cleaner error messages
- More predictable formatting

## Tips for Best Results

### For Word Documents

1. **Use Built-in Styles**: Documents using Word's built-in heading styles (Heading 1, Heading 2, etc.) convert better than manually formatted headings
2. **Standard Tables**: Simple tables convert more reliably than complex merged-cell layouts
3. **Image Format**: Common image formats (JPEG, PNG) extract cleanly

### For PDF Files

1. **Text-Based PDFs**: PDFs created from Word or other digital sources convert better than scanned documents
2. **Clear Scans**: If converting scanned PDFs, higher resolution scans produce better OCR results
3. **Standard Layouts**: PDFs with standard paragraph and heading structure convert more accurately

### For Markdown Files

1. **Use Standard Syntax**: Stick to CommonMark or GitHub Flavored Markdown for best compatibility
2. **Relative Image Paths**: Use relative paths for images so Pandoc can embed them automatically
3. **Simple Tables**: Basic pipe tables convert better than complex HTML tables
4. **Test PDF Engine**: Verify Typst or XeLaTeX is installed before batch converting to PDF
5. **Avoid Custom HTML**: HTML blocks may not convert properly to DOCX/PDF

### General Recommendations

1. **Test First**: Try converting a few sample files before processing large batches
2. **Review Output**: Manually check a few converted files to ensure quality meets your needs
3. **Keep Originals**: The command doesn't delete source files, so you can re-convert with different settings if needed
4. **Directory Structure**: The command preserves subdirectory structure when converting multiple directories

## Troubleshooting

### Conversion Fails

If a conversion fails:
- Check that input files are valid DOCX or PDF files (not corrupted)
- Ensure you have write permissions in the output directory
- Try converting a single file to isolate the problem

### Poor Quality Output

If converted Markdown has issues:
- For DOCX: Check if the Word document uses custom styles or complex formatting
- For PDF: Scanned PDFs may need higher quality scans for better OCR
- Complex tables may need manual review and adjustment

### Missing Images

If images don't appear:
- Check the `media/` subdirectory in the output location
- Verify image links in the Markdown file point to the correct location
- Some embedded images may not extract if they're in unsupported formats

## Next Steps

After converting your documents:

1. **Review converted files** for accuracy
2. **Adjust links** if you move files to different directories
3. **Commit to version control** to track documentation changes
4. **Update cross-references** between documents if needed

For questions or issues with the `/convert-docs` command, consult your Claude Code documentation or the tool repositories linked above.
