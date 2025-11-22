# Simplified /convert-docs Architecture Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Simplified architecture with Gemini API default and API-free fallback
- **Report Type**: Architecture and tooling analysis
- **Workflow Type**: research-and-revise
- **Existing Plan**: 001_convert_docs_fidelity_llm_practices_plan.md

## Executive Summary

Research identifies a dramatically simplified architecture for /convert-docs that uses Gemini API by default with automatic fallback to simple, dependency-free tools. The key insight is that **all 6 conversion directions can be covered by just 2-3 pip-installable tools** without requiring GPU, PyTorch, or complex installation. The recommended architecture uses a single `--no-api` or `--offline` flag to bypass all API calls, with automatic fallback when API is unavailable. MarkItDown (pip install) handles DOCX/PDF to markdown, Pandoc (system package) handles markdown to DOCX/PDF, and pdf2docx (pip install) handles PDF to DOCX conversions.

## Findings

### 1. Current Codebase Analysis

The existing `/home/benjamin/.config/.claude/lib/convert/` directory contains:

| File | Purpose | Lines | Key Functions |
|------|---------|-------|---------------|
| `convert-core.sh:1-1353` | Main orchestration, tool detection, parallel processing | 1353 | `main_conversion()`, `detect_tools()`, `convert_file()` |
| `convert-docx.sh:1-79` | DOCX conversion utilities | 79 | `convert_docx()`, `convert_docx_pandoc()`, `convert_md_to_docx()` |
| `convert-pdf.sh:1-96` | PDF conversion utilities | 96 | `convert_pdf_markitdown()`, `convert_pdf_pymupdf()`, `convert_md_to_pdf()` |
| `convert-markdown.sh:1-84` | Markdown validation/analysis | 84 | `check_structure()`, `report_validation_warnings()` |

**Current Tool Detection** (convert-core.sh:108-133):
- MarkItDown: `command -v markitdown`
- Pandoc: `command -v pandoc`
- PyMuPDF4LLM: `python3 -c "import pymupdf4llm"`
- Typst: `command -v typst`
- XeLaTeX: `command -v xelatex`

**Current Fallback Chain** (convert-core.sh:848-1023):
- DOCX to MD: MarkItDown -> Pandoc
- PDF to MD: MarkItDown -> PyMuPDF4LLM
- MD to DOCX: Pandoc only
- MD to PDF: Pandoc + Typst/XeLaTeX

**Missing Conversion Directions** (not currently implemented):
- Word to PDF (`docx -> pdf`)
- PDF to Word (`pdf -> docx`)

### 2. Simple Tools for Each Conversion Direction

#### Direction 1: Markdown to PDF

| Tool | Installation | Dependencies | Notes |
|------|-------------|--------------|-------|
| **Pandoc + Typst** | `apt/brew install pandoc typst` | System packages | Best quality, requires LaTeX-free Typst |
| **mdpdf** | `pip install mdpdf` | Minimal | Bare-bones, PDF-base14 fonts only |
| **markdown-pdf** | `pip install markdown-pdf` | PyMuPDF | Uses markdown-it-py + PyMuPDF |
| Pandoc + XeLaTeX | System packages | TeX distribution | Heavy dependency (2GB+) |

**Recommendation**: Pandoc + Typst for quality, mdpdf as pip-only fallback

#### Direction 2: Markdown to Word (DOCX)

| Tool | Installation | Dependencies | Notes |
|------|-------------|--------------|-------|
| **Pandoc** | `apt/brew install pandoc` | System package | Best quality, well-maintained |
| **md2docx-python** | `pip install md2docx-python` | python-docx | Pure Python, bidirectional |
| **Markdown2docx** | `pip install Markdown2docx` | python-docx | Simple, Python-only |

**Recommendation**: Pandoc for quality, Markdown2docx as pip-only fallback

#### Direction 3: PDF to Markdown

| Tool | Installation | Dependencies | Notes |
|------|-------------|--------------|-------|
| **MarkItDown** | `pip install 'markitdown[all]'` | Optional extras | Microsoft, LLM-focused |
| **PyMuPDF4LLM** | `pip install pymupdf4llm` | PyMuPDF | Fast, structure-preserving |
| **Gemini API** | `pip install google-genai` | API key | Best quality for complex PDFs |

**Recommendation**: Gemini API for best results, MarkItDown/PyMuPDF4LLM as offline fallback

#### Direction 4: Word (DOCX) to Markdown

| Tool | Installation | Dependencies | Notes |
|------|-------------|--------------|-------|
| **MarkItDown** | `pip install 'markitdown[docx]'` | mammoth | Uses mammoth internally |
| **Pandoc** | `apt/brew install pandoc` | System package | GFM output, extracts media |
| **mammoth** | `pip install mammoth` | Minimal | Direct HTML/MD output |
| **docx2md** | `pip install docx2md` | python-docx | Simple CLI tool |

**Recommendation**: MarkItDown for consistency, Pandoc as system-level fallback

#### Direction 5: Word (DOCX) to PDF

| Tool | Installation | Dependencies | Notes |
|------|-------------|--------------|-------|
| **Pandoc** | System package | + PDF engine | Route: DOCX -> MD -> PDF |
| **docx2pdf** | `pip install docx2pdf` | MS Word/LibreOffice | Requires external software |
| **Spire.Doc** | `pip install Spire.Doc` | Commercial | No LibreOffice needed |

**Recommendation**: Route through markdown (DOCX -> MD -> PDF via Pandoc)

#### Direction 6: PDF to Word (DOCX)

| Tool | Installation | Dependencies | Notes |
|------|-------------|--------------|-------|
| **pdf2docx** | `pip install pdf2docx` | PyMuPDF | Open source, no MS Office needed |
| **Gemini API** | `pip install google-genai` | API key | Route: PDF -> MD -> DOCX |
| **Spire.PDF** | `pip install Spire.PDF` | Commercial | $999+ for production |

**Recommendation**: pdf2docx for direct conversion, or route through markdown

### 3. Proposed Simplified Architecture

#### Flag-Based Workflow Control

```
/convert-docs [input] [output] [--no-api | --offline]

DEFAULT MODE (no flag):
  - Uses Gemini API where it improves quality
  - Automatic fallback to offline tools if API unavailable

OFFLINE MODE (--no-api or --offline flag):
  - Zero API calls
  - Uses only local tools (pip/system installed)
  - No network dependency
```

#### Unified Conversion Matrix

| From\To | Markdown | PDF | DOCX |
|---------|----------|-----|------|
| **Markdown** | - | Pandoc+Typst | Pandoc |
| **PDF** | Gemini API / MarkItDown | - | pdf2docx |
| **DOCX** | MarkItDown / Pandoc | via Markdown | - |

#### Automatic Fallback Chain

```
                    +--------------------+
                    | Check GEMINI_API_KEY |
                    +--------------------+
                            |
              +-------------+-------------+
              |                           |
        [API Available]            [No API / --offline]
              |                           |
              v                           v
    +------------------+       +------------------+
    | Gemini API Mode  |       | Offline Mode     |
    +------------------+       +------------------+
              |                           |
        [API Fails?]                      |
              |                           |
              +---------------------------+
                            |
                            v
              +---------------------------+
              | Local Tool Fallback       |
              | MarkItDown / PyMuPDF4LLM  |
              | Pandoc / pdf2docx         |
              +---------------------------+
```

### 4. Installation Requirements Comparison

#### Current Plan (from 001_convert_docs_fidelity_llm_practices_plan.md)
- 6 phases, 23-29 hours estimated
- LLM post-processing layer (complex)
- Fidelity scoring system (complex)
- Gemini API integration (Phase 4)
- Multiple prompt templates

#### Simplified Architecture
```bash
# Minimal offline installation (covers all 6 directions)
pip install markitdown pymupdf4llm pdf2docx

# System packages (for best quality)
apt install pandoc  # or brew install pandoc
apt install typst   # or brew install typst (optional, for MD->PDF)

# Optional: API for best quality
pip install google-genai
export GEMINI_API_KEY="your-key"
```

**Total pip packages**: 3-4
**System packages**: 1-2
**GPU required**: No
**PyTorch required**: No
**Complex installation**: No

### 5. Fidelity Trade-offs by Mode

#### Gemini API Mode (Default)
| Direction | Expected Fidelity | Notes |
|-----------|-------------------|-------|
| PDF -> Markdown | 85-95% | Gemini excels at complex layouts, tables |
| PDF -> DOCX | 75-85% | Via markdown intermediate |
| DOCX -> Markdown | 80-85% | MarkItDown (mammoth-based) |
| DOCX -> PDF | 90%+ | Via markdown route |
| Markdown -> PDF | 95%+ | Pandoc + Typst |
| Markdown -> DOCX | 95%+ | Pandoc |

#### Offline Mode (--no-api)
| Direction | Expected Fidelity | Notes |
|-----------|-------------------|-------|
| PDF -> Markdown | 60-75% | PyMuPDF4LLM/MarkItDown |
| PDF -> DOCX | 65-80% | pdf2docx library |
| DOCX -> Markdown | 75-82% | MarkItDown (current level) |
| DOCX -> PDF | 85-90% | Via markdown route |
| Markdown -> PDF | 95%+ | Pandoc + Typst |
| Markdown -> DOCX | 95%+ | Pandoc |

### 6. Gemini API Integration Details

**Free Tier Limits**:
- 60 requests per minute
- 1000 requests per day
- No credit card required

**Setup**:
```bash
pip install google-genai
# Get free API key from https://aistudio.google.com/
export GEMINI_API_KEY="your-key"
```

**Usage Pattern**:
```python
from google import genai

client = genai.Client()
sample_doc = client.files.upload(file=pdf_path, config={"mime_type": "application/pdf"})
response = client.models.generate_content(
    model="gemini-2.5-flash-lite",  # Cheapest option
    contents=[sample_doc, "Convert this document to markdown. Preserve all formatting."]
)
markdown_output = response.text
```

**Rate Limit Handling**:
- Exponential backoff on 429 errors
- Automatic fallback to offline tools after N failures

### 7. Existing Code Reuse Analysis

| Component | Can Reuse | Modifications Needed |
|-----------|-----------|---------------------|
| `convert-core.sh` structure | Yes | Add --no-api flag, Gemini detection |
| `convert-docx.sh` | Yes | No changes needed |
| `convert-pdf.sh` | Yes | Add Gemini function, pdf2docx |
| `convert-markdown.sh` | Yes | No changes needed |
| Tool detection logic | Yes | Add Gemini API detection |
| Fallback chains | Yes | Extend with Gemini -> offline |
| Timeout handling | Yes | No changes needed |
| Parallel processing | Yes | No changes needed |

## Recommendations

### Recommendation 1: Drastically Simplify Plan Architecture

Replace the current 6-phase, 23-29 hour plan with a 3-phase simplified approach:

**Phase 1: Add --no-api/--offline Flag (2-3 hours)**
- Parse new flag in convert-core.sh
- Set global OFFLINE_MODE variable
- Document flag in command help

**Phase 2: Gemini API Integration (3-4 hours)**
- Create convert-gemini.sh module
- Implement PDF-to-markdown via google-genai
- Add rate limiting and fallback logic
- Detect GEMINI_API_KEY availability

**Phase 3: Add Missing Conversions (2-3 hours)**
- Add pdf2docx for PDF -> DOCX direction
- Add DOCX -> PDF routing through markdown
- Update tool detection for new packages

**Total Estimated Time**: 7-10 hours (vs. 23-29 hours original)

### Recommendation 2: Eliminate Complex Components

**Remove from plan**:
- LLM post-processing layer (Phase 2 in original)
- Fidelity scoring system (Phase 3 in original)
- Prompt template system
- Code block detection heuristics

**Rationale**: These add complexity without proportional benefit. Gemini API already handles markdown formatting well. If fidelity needs improvement, add these incrementally later.

### Recommendation 3: Use Minimal Dependency Set

**Required (pip)**:
```bash
pip install markitdown pymupdf4llm pdf2docx google-genai
```

**Required (system)**:
```bash
# Ubuntu/Debian
apt install pandoc

# macOS
brew install pandoc
```

**Optional (better PDF output)**:
```bash
apt install typst  # or brew install typst
```

### Recommendation 4: Implement Clean Flag Interface

```bash
# Default: Use API where beneficial
/convert-docs input/ output/

# Offline: No API calls
/convert-docs input/ output/ --no-api
/convert-docs input/ output/ --offline

# Force Gemini for all PDF conversions
/convert-docs input/ output/ --gemini-pdf

# Environment variable alternative
CONVERT_DOCS_OFFLINE=true /convert-docs input/ output/
```

### Recommendation 5: Auto-Detection Strategy

```bash
detect_mode() {
  if [[ "$OFFLINE_FLAG" == "true" ]]; then
    MODE="offline"
  elif [[ -n "$GEMINI_API_KEY" ]]; then
    # Test API connectivity
    if test_gemini_api; then
      MODE="gemini"
    else
      MODE="offline"
      echo "Warning: Gemini API unavailable, using offline mode"
    fi
  else
    MODE="offline"
  fi
}
```

## References

### Codebase Files Analyzed
- `/home/benjamin/.config/.claude/lib/convert/convert-core.sh:1-1353` - Main orchestration module
- `/home/benjamin/.config/.claude/lib/convert/convert-docx.sh:1-79` - DOCX conversion functions
- `/home/benjamin/.config/.claude/lib/convert/convert-pdf.sh:1-96` - PDF conversion functions
- `/home/benjamin/.config/.claude/lib/convert/convert-markdown.sh:1-84` - Markdown utilities
- `/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md:1-685` - Existing plan

### External Sources
- Microsoft MarkItDown: https://github.com/microsoft/markitdown
- PyMuPDF4LLM: https://pypi.org/project/pymupdf4llm/
- pdf2docx: https://pypi.org/project/pdf2docx/
- Gemini API Document Processing: https://ai.google.dev/gemini-api/docs/document-processing
- google-genai SDK: https://pypi.org/project/google-genai/
- Pandoc: https://pandoc.org/
- Typst: https://typst.app/

### Tool Installation References
- MarkItDown: `pip install 'markitdown[all]'` or selective `pip install 'markitdown[docx,pdf]'`
- PyMuPDF4LLM: `pip install pymupdf4llm`
- pdf2docx: `pip install pdf2docx`
- google-genai: `pip install google-genai`
- Pandoc: System package manager (apt, brew, etc.)
- Typst: System package manager or https://typst.app/docs/guides/install/

## Summary Comparison

| Aspect | Original Plan | Simplified Architecture |
|--------|---------------|------------------------|
| Phases | 6 | 3 |
| Estimated Hours | 23-29 | 7-10 |
| New pip packages | 3+ | 4 (markitdown, pymupdf4llm, pdf2docx, google-genai) |
| System packages | Multiple | 1-2 (pandoc, optionally typst) |
| GPU required | No | No |
| Complex prompts | Yes | No |
| Fidelity scoring | Yes | No (defer to later) |
| All 6 directions | Partial | Yes |
| Offline support | Partial | Full |
| Flag interface | Multiple flags | Single --no-api flag |
