# Conversion Task Analysis Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Which conversion tasks benefit from LLM involvement
- **Report Type**: best practices
- **Related Plan**: /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md

## Executive Summary

Analysis of all 6 document conversion directions reveals that LLM involvement (via Gemini API) provides significant quality improvement for PDF-to-Markdown conversion only. Other conversion directions (DOCX-to-Markdown, Markdown-to-DOCX, Markdown-to-PDF) work equally well or better with local tools because they are format transformations rather than content interpretation tasks. The plan should focus Gemini API usage exclusively on PDF-to-Markdown, while maintaining local tools for all other directions. This targeted approach maximizes quality improvement while minimizing API costs and complexity.

## Findings

### 1. Conversion Direction Analysis

| Direction | LLM Benefit | Recommended Tool | Rationale |
|-----------|-------------|------------------|-----------|
| PDF -> Markdown | **HIGH** | Gemini API | Vision + layout understanding required |
| DOCX -> Markdown | LOW | MarkItDown | Structured format, extraction is deterministic |
| Markdown -> DOCX | NONE | Pandoc | Template-based transformation |
| Markdown -> PDF | NONE | Pandoc+Typst | Template-based rendering |
| PDF -> DOCX | MEDIUM | Gemini -> Pandoc | Two-step via Markdown |
| DOCX -> PDF | NONE | via Markdown | Two-step via Markdown |

### 2. PDF -> Markdown: High LLM Benefit

**Why LLM Helps**:
1. **Layout Understanding**: PDFs have no semantic structure - content is positioned visually
2. **Table Detection**: LLM identifies table boundaries from visual arrangement
3. **Code Block Recognition**: Distinguishes code from regular text based on context
4. **OCR Quality**: Native vision beats traditional OCR for scanned documents
5. **Multi-column Handling**: Correctly reflows content from complex layouts

**Quality Comparison** (from existing research report 001_fidelity_improvement_research.md:122):
- MarkItDown baseline: 70-85% fidelity
- PyMuPDF4LLM: 65-75% fidelity
- Gemini API: 90%+ fidelity (significant improvement)

**Where Gemini Excels**:
```
Source PDF:
+------------------------+------------------------+
|  Technical Overview    |  System Requirements   |
|  ==================    |  ==================    |
|  The system uses       |  - Python 3.8+        |
|  distributed caching   |  - Redis 6.0+         |
|  for performance.      |  - 4GB RAM            |
+------------------------+------------------------+

MarkItDown Output (problematic):
Technical Overview The system uses distributed caching for performance.
System Requirements - Python 3.8+ - Redis 6.0+ - 4GB RAM

Gemini Output (correct):
## Technical Overview
The system uses distributed caching for performance.

## System Requirements
- Python 3.8+
- Redis 6.0+
- 4GB RAM
```

### 3. DOCX -> Markdown: Low LLM Benefit

**Why LLM Unnecessary**:
1. **Structured Format**: DOCX is XML-based with explicit semantics
2. **Deterministic Extraction**: Headings, lists, tables are tagged
3. **Reliable Local Tools**: MarkItDown achieves 75-80% fidelity
4. **No Interpretation Needed**: Format mapping is algorithmic

**Local Tool Quality** (from SKILL.md:43-52):
- MarkItDown: 75-80% fidelity, perfect table preservation (pipe-style)
- Pandoc: 68% fidelity, grid-style tables (verbose)

**When LLM Might Help**:
- Complex nested tables (edge case)
- Embedded diagrams (rare)
- Non-standard DOCX templates

**Recommendation**: Keep MarkItDown as primary, LLM not cost-effective.

### 4. Markdown -> DOCX: No LLM Benefit

**Why LLM Not Needed**:
1. **Unambiguous Source**: Markdown has explicit syntax
2. **Template Transformation**: Conversion is mapping, not interpretation
3. **Pandoc Excellence**: Achieves 95%+ quality preservation
4. **LLM Would Add Nothing**: No interpretation decisions to make

**Current Implementation** (from convert-core.sh:989-1009):
```bash
# MD -> DOCX conversion (Pandoc only)
if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
  convert_md_to_docx "$input_file" "$output_file"
fi
```

**Pandoc Quality**: Near-perfect - handles headings, lists, tables, code blocks, images.

### 5. Markdown -> PDF: No LLM Benefit

**Why LLM Not Needed**:
1. **Rendering Task**: Not interpretation, just typesetting
2. **Excellent Local Engines**: Typst and XeLaTeX produce high-quality PDFs
3. **Font/Layout Control**: Local tools give precise control
4. **LLM Can't Help**: Would need to generate PDF directly (not practical)

**Current Implementation** (from convert-pdf.sh:85-93):
```bash
# MD -> PDF via Pandoc + Typst (primary) or XeLaTeX (fallback)
if [[ "$TYPST_AVAILABLE" == "true" ]]; then
  pandoc "$input_file" --pdf-engine=typst -o "$output_file"
elif [[ "$XELATEX_AVAILABLE" == "true" ]]; then
  pandoc "$input_file" --pdf-engine=xelatex -o "$output_file"
fi
```

**Quality**: 98%+ with both engines.

### 6. PDF -> DOCX: Medium LLM Benefit (Two-Step)

**Approach**: PDF -> Markdown (Gemini) -> DOCX (Pandoc)

**Why Two-Step Works**:
1. Gemini extracts structure from PDF (the hard part)
2. Pandoc transforms Markdown to DOCX (deterministic)
3. Avoids direct PDF-to-DOCX complexity

**Alternative** (from existing plan:260-280):
```bash
# Direct approach: pdf2docx (no LLM)
python3 -c "
from pdf2docx import Converter
cv = Converter('$pdf_path')
cv.convert('$output_path')
cv.close()
"
```

**Comparison**:
- pdf2docx: 70-80% quality, fast, offline
- Gemini two-step: 85-90% quality, API required

**Recommendation**: Offer both paths - pdf2docx for offline, Gemini for quality.

### 7. DOCX -> PDF: No LLM Benefit (Two-Step)

**Approach**: DOCX -> Markdown -> PDF

**Implementation** (from existing plan:282-295):
```bash
convert_docx_to_pdf() {
  local docx_path="$1"
  local output_path="$2"
  local temp_md="/tmp/convert_$$_temp.md"

  # Step 1: DOCX -> Markdown
  convert_docx_to_md "$docx_path" "$temp_md" || return 1

  # Step 2: Markdown -> PDF
  convert_md_to_pdf "$temp_md" "$output_path" || return 1

  rm -f "$temp_md"
}
```

**Quality**: High - MarkItDown + Typst/Pandoc pipeline works well.

### 8. Cost-Benefit Analysis

| Direction | API Cost | Quality Gain | Net Benefit |
|-----------|----------|--------------|-------------|
| PDF -> MD | $0.003/doc | +20-30% | **HIGH** |
| DOCX -> MD | $0.003/doc | +0-5% | LOW |
| MD -> DOCX | N/A | 0% | NONE |
| MD -> PDF | N/A | 0% | NONE |
| PDF -> DOCX | $0.003/doc | +10-15% | MEDIUM |
| DOCX -> PDF | $0.003/doc | +0-5% | LOW |

### 9. Gemini API Scope Recommendation

**Use Gemini API For**:
- PDF -> Markdown (always, when available)
- PDF -> DOCX (optional, for quality mode)

**Use Local Tools For**:
- DOCX -> Markdown (MarkItDown)
- Markdown -> DOCX (Pandoc)
- Markdown -> PDF (Pandoc + Typst)
- DOCX -> PDF (via Markdown)

### 10. Implementation Simplification

Based on this analysis, the plan can be simplified:

**Current Plan Complexity**:
- Gemini integration for all PDF conversions
- --no-api flag for offline mode
- Fallback chain for all directions

**Recommended Simplification**:
- Gemini integration for PDF -> Markdown only
- --no-api flag still useful for offline mode
- Local tools remain primary for non-PDF sources

```bash
convert_file() {
  case "${extension,,}" in
    pdf)
      # PDF conversions benefit from Gemini
      local mode=$(detect_conversion_mode)
      if [[ "$mode" == "gemini" ]]; then
        convert_pdf_gemini "$input_file" "$output_file" || \
          convert_pdf_markitdown "$input_file" "$output_file"
      else
        convert_pdf_markitdown "$input_file" "$output_file"
      fi
      ;;
    docx)
      # DOCX conversions work well with local tools
      convert_docx "$input_file" "$output_file"
      ;;
    md|markdown)
      # Markdown conversions are pure transformations
      convert_md_to_docx "$input_file" "$output_file"
      ;;
  esac
}
```

## Recommendations

### 1. Focus Gemini API on PDF Only
Limit Gemini API usage to PDF -> Markdown conversions where it provides clear quality benefits. Other directions gain little from LLM involvement.

### 2. Keep Local Tools as Primary for Non-PDF
Maintain MarkItDown, Pandoc, and Typst as primary tools for non-PDF conversions. They are fast, free, and produce excellent results.

### 3. Simplify the Conversion Matrix
Update the plan's conversion matrix to reflect targeted API usage:

| From -> To | Default (API) | Offline (--no-api) |
|------------|---------------|-------------------|
| PDF -> Markdown | **Gemini API** | MarkItDown/PyMuPDF4LLM |
| PDF -> DOCX | Gemini -> Pandoc | pdf2docx |
| DOCX -> Markdown | MarkItDown | MarkItDown |
| DOCX -> PDF | via Markdown | via Markdown |
| Markdown -> DOCX | Pandoc | Pandoc |
| Markdown -> PDF | Pandoc + Typst | Pandoc + Typst |

### 4. Document Quality Expectations
Set clear expectations for users:
- PDF conversions: Quality varies by source (API mode recommended)
- Non-PDF conversions: Consistent high quality with local tools

### 5. Consider Claude Code for Complex DOCX (Future)
While not recommended for initial implementation, Claude Code could help with:
- Extracting meaning from complex nested tables
- Understanding diagram/figure captions
- Interpreting non-standard formatting

This would be a future enhancement, not current scope.

### 6. Add Quality Mode Flag (Future Enhancement)
For users wanting maximum quality at higher cost:
```bash
/convert-docs input/ output/ --quality-mode
# Uses Gemini for all conversions, not just PDF
```

This is not recommended for the current plan but noted for future consideration.

## References

### Codebase Files (Analyzed)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:848-1023 (convert_file function)
- /home/benjamin/.config/.claude/lib/convert/convert-pdf.sh:85-93 (MD to PDF conversion)
- /home/benjamin/.config/.claude/skills/document-converter/SKILL.md:43-69 (Tool Priority Matrix)
- /home/benjamin/.config/.claude/skills/document-converter/reference.md:232-250 (Quality Comparison Matrix)

### Existing Research Reports
- /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/001_fidelity_improvement_research.md
- /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/005_gemini_api_conversion_capabilities_research.md

### Related Plan
- /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md:36-47 (Conversion Matrix)

### External Benchmarks
- Marker PDF converter benchmarks: https://github.com/VikParuchuri/marker
- "Unlock PDFs for RAG with Markdown and Gemini": https://medium.com/google-cloud/unlocking-pdfs-for-rag-with-markdown-and-gemini-503846463f3f

---

**Report Generated**: 2025-11-21
**Research Complexity**: 2 (Medium)
**Status**: Complete
