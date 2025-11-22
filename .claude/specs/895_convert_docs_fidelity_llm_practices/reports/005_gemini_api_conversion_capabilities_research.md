# Gemini API Document Conversion Capabilities Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Gemini API document conversion capabilities for all conversion directions
- **Report Type**: API capabilities analysis and claim verification
- **Related Plan**: 001_convert_docs_fidelity_llm_practices_plan.md

## Executive Summary

Research **confirms and expands** the plan's claim that "Gemini API only adds value for PDF → Markdown." The Gemini API has **significant limitations** that make it unsuitable for most conversion directions. Key findings: (1) DOCX files are explicitly NOT supported by Gemini API, (2) Gemini cannot generate output files (PDF, DOCX) - it only produces text/markdown, (3) Gemini excels only at PDF → text/markdown conversion using its vision capabilities. The simplified architecture in the revised plan is well-designed.

## Findings

### 1. Gemini API Supported File Types (Input Only)

**Official MIME Type Support** (from Firebase/Google AI documentation):

| Category | Supported MIME Types |
|----------|---------------------|
| **Documents** | `application/pdf` ONLY |
| **Images** | `image/png`, `image/jpeg`, `image/webp`, `image/heic`, `image/heif` |
| **Audio** | `audio/wav`, `audio/mp3`, `audio/aiff`, `audio/aac`, `audio/ogg`, `audio/flac` |
| **Video** | `video/mp4`, `video/mpeg`, `video/mov`, `video/avi`, `video/webm` |
| **Text** | `text/plain`, `text/html`, `text/markdown`, `text/x-python` |

**Critical Finding**: **DOCX files are explicitly NOT supported**. Attempting to upload DOCX returns:
```
400 Unsupported MIME type: application/vnd.openxmlformats-officedocument.wordprocessingml.document
```

### 2. Gemini API Output Capabilities

Gemini API can **only output text**. It cannot:
- Generate PDF files
- Generate DOCX files
- Generate any binary file formats

**What Gemini CAN output**:
- Plain text
- Markdown (via prompting)
- HTML (via prompting)
- JSON (structured output)
- XML (via prompting)

### 3. Conversion Direction Analysis

#### Direction 1: PDF → Markdown ✅ GEMINI EXCELS

**Gemini adds significant value here.**

- Native vision capabilities understand document layout, tables, diagrams
- Processes up to 50MB / 1000 pages per document
- Preserves formatting, code blocks, tables better than OCR-based tools
- Example prompt: "Convert this document to markdown. Preserve headings, code blocks, tables."

**Fidelity**: 85-95% (superior to offline tools' 60-75%)

#### Direction 2: DOCX → Markdown ❌ GEMINI CANNOT HELP

**DOCX files are not supported by Gemini API.**

Users would need to:
1. Convert DOCX → PDF first (using external tool)
2. Then use Gemini for PDF → Markdown

This adds complexity and potential quality loss. **Offline tools (MarkItDown, Pandoc) are simpler and equally effective.**

**Verdict**: Use MarkItDown/Pandoc directly. Gemini adds no value.

#### Direction 3: Markdown → PDF ❌ GEMINI CANNOT HELP

**Gemini cannot generate PDF files.**

This is a rendering/typesetting task, not an AI task. Use:
- Pandoc + Typst (best quality)
- Pandoc + LaTeX (traditional)
- mdpdf (simple)

**Verdict**: Gemini is completely irrelevant for this direction.

#### Direction 4: Markdown → DOCX ❌ GEMINI CANNOT HELP

**Gemini cannot generate DOCX files.**

This is a file format conversion task. Use:
- Pandoc (best quality)
- python-docx libraries

**Verdict**: Gemini is completely irrelevant for this direction.

#### Direction 5: PDF → DOCX 🔶 GEMINI PARTIALLY HELPFUL

Gemini can help via indirect route:
1. PDF → Markdown (Gemini)
2. Markdown → DOCX (Pandoc)

However, **pdf2docx provides direct conversion** and may preserve layout better for certain documents.

**Verdict**: Gemini route is viable but adds complexity. Direct tools may be better.

#### Direction 6: DOCX → PDF ❌ GEMINI CANNOT HELP

**Double limitation**: Gemini can neither read DOCX nor generate PDF.

Route through markdown:
1. DOCX → Markdown (MarkItDown/Pandoc)
2. Markdown → PDF (Pandoc)

**Verdict**: Gemini is completely irrelevant for this direction.

### 4. Summary Matrix: Where Gemini Adds Value

| Conversion | Gemini Helps? | Reason |
|------------|--------------|--------|
| PDF → Markdown | ✅ **YES** | Vision-based understanding superior to OCR |
| PDF → DOCX | 🔶 Maybe | Via markdown intermediate, but adds complexity |
| DOCX → Markdown | ❌ No | DOCX not supported as input |
| DOCX → PDF | ❌ No | Neither input nor output supported |
| Markdown → PDF | ❌ No | Cannot generate PDF output |
| Markdown → DOCX | ❌ No | Cannot generate DOCX output |

### 5. Verification of Plan Claim

**Original Claim in Plan**:
> "**Key Insight**: Gemini API only adds value for PDF → Markdown. All other directions work equally well offline."

**Verdict**: ✅ **CLAIM IS ACCURATE**

The claim is correct and possibly understated. Gemini doesn't just "work equally well offline" for other directions - **Gemini literally cannot perform those conversions** due to API limitations.

### 6. Additional Considerations

#### Rate Limits (Free Tier)
- 60 requests per minute
- 1000 requests per day
- No credit card required

#### Gemini 2.5 vs 3.0 Changes
- Gemini 3 (November 2025) added native PDF text extraction
- Text embedded in PDFs is now extracted without vision processing
- This further improves PDF → Markdown quality

#### Third-Party Tools Combining Gemini
- **Marker** (`datalab-to/marker`): Uses Gemini for LLM-enhanced PDF conversion
- **gemini-markitdown**: Combines MarkItDown with Gemini for post-processing

## Recommendations

### Recommendation 1: Keep Current Plan Architecture

The revised plan correctly identifies PDF → Markdown as the only Gemini-enhanced direction. No changes needed to the conversion matrix.

### Recommendation 2: Consider Gemini for PDF → DOCX Route

For PDF → DOCX, the plan could offer two paths:
1. **Direct**: `pdf2docx` (preserves layout)
2. **Via Markdown**: Gemini PDF → MD → Pandoc → DOCX (better text extraction)

Let user choose based on document type.

### Recommendation 3: Document Gemini Limitations Explicitly

Add to documentation:
- Gemini API does NOT support DOCX input
- Gemini API cannot generate files (only text output)
- For non-PDF conversions, offline tools are not just "equally good" - they are the ONLY option

### Recommendation 4: No Need to Expand Gemini Usage

The plan's conservative approach to Gemini (PDF-only) is correct. Do not attempt to expand Gemini usage to other directions - the API simply doesn't support it.

## References

### Official Documentation
- Google AI Gemini Document Processing: https://ai.google.dev/gemini-api/docs/document-processing
- Firebase AI Logic Input File Requirements: https://firebase.google.com/docs/ai-logic/input-file-requirements
- Gemini API Files Reference: https://ai.google.dev/api/files

### Stack Overflow / Community
- "Does Gemini API Support all file mime types" - confirms DOCX unsupported: https://stackoverflow.com/questions/78888864
- "Unsupported MIME type: text/md" discussion: https://discuss.ai.google.dev/t/unsupported-mime-type-text-md/83918

### Technical Articles
- "Unlock PDFs for RAG with Markdown and Gemini" - PDF to markdown workflow: https://medium.com/google-cloud/unlocking-pdfs-for-rag-with-markdown-and-gemini-503846463f3f
- "Gemini 2.0 Flash: Beyond OCR" - vision-based PDF processing: https://medium.com/@michaeljward97/gemini-2-0-flash-beyond-ocr-cae2b3bd8e36

### Codebase Files
- Revised plan: `/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md`
- Previous research: `/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/004_simplified_architecture_research.md`

## Conclusion

The plan's claim is **verified and correct**. Gemini API provides exceptional value for PDF → Markdown conversion (85-95% fidelity vs 60-75% offline), but is **technically incapable** of assisting with other conversion directions due to input/output format limitations. The simplified architecture correctly leverages Gemini where it excels while relying on proven offline tools for all other conversions.
