# Document Conversion Fidelity Improvement Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: LLM and Claude Code Best Practices for Document Conversion Fidelity
- **Report Type**: best practices
- **Complexity**: 3
- **Specs Directory**: /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices
- **Related Report**: /home/benjamin/.config/.claude/specs/892_convert_docs_validation_improvements/reports/001_convert_docs_validation_report.md

## Executive Summary

Research into LLM and Claude Code best practices reveals significant opportunities to improve the `/convert-docs` command fidelity from its current 82% (DOCX) and 34% (PDF) scores. The core problem identified in the existing validation report - loss of code blocks (30%), inline code (0%), blockquotes (0%), and horizontal rules (0%) - aligns with known limitations of tool-based conversion without LLM post-processing. Industry best practices point to hybrid approaches combining tool-based conversion with LLM refinement, specialized models like ReaderLM-v2 and Marker with `--use_llm`, and MCP server integration for seamless workflows. This report provides 12 specific improvement recommendations across three categories: LLM post-processing integration, alternative tools evaluation, and MCP server adoption.

## Findings

### 1. Current State Analysis

Based on the existing validation report (`001_convert_docs_validation_report.md`), the `/convert-docs` command demonstrates:

**Fidelity Metrics**:
| Category | DOCX Pipeline | PDF Pipeline |
|----------|---------------|--------------|
| Structure | 90% | 60% |
| Text Formatting | 80% | 10% |
| **Code Elements** | **30%** | 20% |
| Tables | 95% | 0% |
| Links | 95% | 50% |
| Special Characters | 100% | 60% |
| Math | 85% | 40% |
| **Overall** | **82%** | **34%** |

**Critical Gaps Identified** (from lines 398-404 of validation report):
- Code Blocks: 30% (fence markers lost, no syntax highlighting)
- Inline Code: 0% (backticks removed, becomes plain text)
- Block Quotes: 0% (`>` markers removed)
- Horizontal Rules: 0% (`---` removed completely)
- Definition Lists: 0% (`:` markers removed)

**Root Cause**: Tool-based converters (MarkItDown, Pandoc) are designed for "LLM-ready" content extraction, not round-trip fidelity. As stated in MarkItDown documentation: "not intended for perfect, high-fidelity conversions for human consumption."

### 2. LLM Post-Processing Best Practices

Research reveals two primary approaches to improving conversion fidelity with LLMs:

#### 2.1 Two-Pass Hybrid Approach

Industry best practice involves a two-pass system:
1. **Pass 1 (Tool-based)**: Use existing tools (MarkItDown, Pandoc) for structural extraction
2. **Pass 2 (LLM Refinement)**: Use LLM to repair lost formatting elements

**Key Reference**: SpecterOps technical writing workflow achieved "100%" style guide compliance by uploading explicit style guides and templates to the LLM.

**Evidence**: The SpecterOps case study documents how Claude 3.7 Sonnet successfully converted Word documents to Markdown when provided with:
- Explicit templates showing desired Markdown structure
- Style guide as an uploaded document
- Iterative feedback across multiple conversation turns

**Limitations Found**:
- LLMs may incorrectly guess programming languages for code blocks
- Some formatting edge cases require manual correction
- Statistical probability means outputs require human verification

#### 2.2 Prompt Engineering for Document Repair

Claude prompting best practices for document conversion:

**From Anthropic Documentation**:
- Use XML tags as "neon road signs" for structure
- Provide single high-quality example (reduces format errors by 60%)
- Match prompt formatting style to desired output style
- Use `<thinking>` tags for step-by-step processing

**Effective Prompt Template Pattern**:
```
<context>
You are a markdown formatting specialist. The following markdown was extracted
from a DOCX file and has lost certain formatting elements.
</context>

<original_elements_hint>
The original document contained:
- Code blocks with syntax highlighting (Python, Bash)
- Inline code for filenames and commands
- Block quotes for important notes
- Horizontal rules as section separators
</original_elements_hint>

<instructions>
1. Identify text that appears to be code (indented, technical syntax)
2. Wrap identified code in appropriate fenced code blocks with language hints
3. Identify inline technical terms that should have backticks
4. Restore blockquote markers for quoted content
5. Add horizontal rules between major sections
</instructions>

<input_markdown>
{converted_content}
</input_markdown>
```

### 3. Specialized Conversion Tools Research

#### 3.1 Marker with LLM Mode

**Tool**: `marker-pdf` (datalab-to/marker)
**Key Feature**: `--use_llm` flag for enhanced accuracy

**Capabilities**:
- Merges tables across pages
- Handles inline math correctly
- Formats tables properly
- Extracts values from forms
- Supports code blocks in output

**Integration Pattern**:
```bash
marker_single document.pdf --use_llm --output_format markdown
```

**Benchmark Results**: "use_llm mode offers higher accuracy than marker or gemini alone"

**License Consideration**: Modified AI Pubs Open Rail-M license (free for research, personal use, startups under $2M)

#### 3.2 ReaderLM-v2

**Model**: 1.5B parameter specialized LLM for HTML-to-Markdown
**Developer**: Jina AI

**Key Capabilities**:
- Superior handling of code fences, nested lists, tables, and LaTeX equations
- 512K token context window
- 29 language support
- Outperforms GPT-4o by 15-20% on markdown extraction benchmarks

**Benchmark Metrics**:
- ROUGE-L: 0.84
- Jaro-Winkler: 0.82
- Levenshtein distance: 0.22 (lower is better)

**Integration Approach**: Can be used as intermediate converter for HTML-based document formats or as post-processor for existing conversions.

**Availability**: Public on Hugging Face

#### 3.3 MinerU

**Tool**: opendatalab/MinerU
**Focus**: PDF to LLM-ready markdown/JSON

**Capabilities**:
- Removes headers, footers, footnotes, page numbers
- Preserves heading, paragraph, and list structure
- Outputs text in human-readable order
- Handles single-column, multi-column, and complex layouts

**Known Limitation**: "code blocks are not yet supported in the layout model"

### 4. MCP Server Integration Research

#### 4.1 MarkItDown-MCP Server

**Official Microsoft Integration**: `markitdown-mcp`

**Features**:
- Single tool: `convert_to_markdown`
- Supports http:, https:, file:, and data: URIs
- STDIO and SSE transport options
- Direct Claude Desktop integration

**Limitations**:
- PDFs converted to plain text only (not markdown)
- No built-in OCR for scanned PDFs
- Limited legacy format support (.doc, .ppt not supported)
- 100MB file size limit (50MB for optimal performance)

#### 4.2 Nutrient DWS MCP Server

**Developer**: Nutrient (formerly PSPDFKit)

**Capabilities**:
- PDF to HTML conversion (preserves layout)
- PDF to Markdown conversion (clean structured text)
- PDF/UA generation (accessibility compliance)
- Natural language command interface

**Integration with Claude Code**:
- Direct MCP connection via API key
- Batch processing via natural language requests
- Automatic file management and output organization

**Use Case Example**: "Twenty minutes from PDF folder to working web app"

#### 4.3 Other Relevant MCP Servers

- **Dumpling AI**: Document conversion APIs
- **Markdownify**: Multi-format to Markdown conversion
- **Google Drive MCP**: Auto-converts Docs, Sheets, Slides

### 5. Markdown Repair Patterns

Research identifies common patterns for fixing tool-generated markdown:

#### 5.1 Code Block Detection Heuristics

**Pattern**: Detect code-like content and wrap in fences

**Indicators**:
- Consistent indentation (4+ spaces)
- Programming keywords (def, function, class, import, etc.)
- Variable assignment patterns (= signs with identifiers)
- Shell-like commands (starting with $, #, or containing |, >)
- File paths (containing / or \)

**Approach**: Post-process with regex pattern matching plus LLM verification

#### 5.2 Inline Code Detection

**Pattern**: Detect technical terms and wrap in backticks

**Indicators**:
- File extensions (.py, .sh, .md, etc.)
- Command names (grep, find, ls, etc.)
- Variable names in camelCase or snake_case
- URLs and paths
- Config keys and values

#### 5.3 Blockquote Restoration

**Pattern**: Detect quoted content and add `>` markers

**Indicators**:
- Phrases starting with "Note:", "Important:", "Warning:"
- Content indented differently from surrounding text
- Content following attribution patterns ("According to...", "As stated in...")

### 6. Quality Assurance Approaches

#### 6.1 Structural Validation

Current implementation (`convert-markdown.sh`, lines 21-39):
```bash
check_structure() {
  # Counts headings (lines starting with #) and tables (lines starting with |)
  heading_count=$(grep -c '^#' "$md_file" 2>/dev/null || echo "0")
  table_count=$(grep -c '^\|' "$md_file" 2>/dev/null || echo "0")
  echo "$heading_count headings, $table_count tables"
}
```

**Enhancement Opportunity**: Add code block and blockquote counting

#### 6.2 Fidelity Scoring

**Proposed Metrics**:
- Structure preservation score (headings, lists, tables)
- Formatting preservation score (bold, italic, code)
- Content accuracy score (character-level comparison)
- Overall fidelity = weighted average

### 7. Architectural Options for Improvement

#### Option A: LLM Post-Processing Layer (Recommended)

**Architecture**:
```
Input Document
    ↓
Tool-Based Conversion (existing)
    ↓
LLM Post-Processing (new)
    ↓
Validated Output
```

**Implementation Complexity**: Medium
**Expected Fidelity Improvement**: +20-30%
**Resource Cost**: Moderate (LLM API calls)

#### Option B: Alternative Tool Integration

**Architecture**:
```
Input Document
    ↓
Tool Selection (enhanced)
    ├── Marker --use_llm (for PDF)
    ├── ReaderLM-v2 (for HTML sources)
    └── MarkItDown (for DOCX, current)
    ↓
Output
```

**Implementation Complexity**: Medium-High
**Expected Fidelity Improvement**: +15-25%
**Resource Cost**: Low (local tools) to Moderate (API-based)

#### Option C: MCP Server Integration

**Architecture**:
```
Claude Code Request
    ↓
MCP Protocol
    ├── MarkItDown-MCP
    ├── Nutrient DWS MCP
    └── Custom Conversion MCP
    ↓
Unified Output
```

**Implementation Complexity**: Low-Medium
**Expected Fidelity Improvement**: +10-20%
**Resource Cost**: Variable (depends on MCP server)

#### Option D: Hybrid Approach (Maximum Fidelity)

**Architecture**: Combine Options A + B + C

**Implementation Complexity**: High
**Expected Fidelity Improvement**: +30-40%
**Resource Cost**: High

## Recommendations

### Category 1: High-Priority Improvements (Immediate Impact)

#### Recommendation 1: Implement LLM Post-Processing for Critical Elements

**Description**: Add optional LLM post-processing pass to restore code blocks, inline code, and blockquotes

**Implementation Approach**:
1. Add `--llm-refine` flag to `/convert-docs` command
2. Create prompt template for markdown repair (see Section 2.2)
3. Use Claude Haiku for cost-effective processing
4. Apply only when fidelity-critical conversions requested

**Effort**: 4-6 hours
**Expected Impact**: +20-25% fidelity for code-heavy documents

#### Recommendation 2: Integrate Marker with `--use_llm` for PDF Pipeline

**Description**: Replace or supplement MarkItDown for PDF conversion with Marker's LLM-enhanced mode

**Implementation Approach**:
1. Add Marker as new PDF tool option in `convert-core.sh`
2. Update tool priority matrix: Marker (with LLM) > MarkItDown > PyMuPDF4LLM
3. Configure Gemini API key for LLM mode (or alternative backend)
4. Benchmark against current PDF pipeline (34% baseline)

**Effort**: 3-4 hours
**Expected Impact**: +15-20% PDF fidelity, especially for tables and complex layouts

#### Recommendation 3: Add Code Block Detection Heuristics

**Description**: Implement regex-based code block detection for post-processing without full LLM pass

**Implementation Approach**:
1. Create `detect_code_blocks()` function in `convert-markdown.sh`
2. Use pattern matching for common code indicators
3. Auto-wrap detected code in fenced blocks with language hints
4. Add validation step to check if code blocks present after conversion

**Effort**: 2-3 hours
**Expected Impact**: +10-15% code element fidelity

### Category 2: Medium-Priority Improvements (Enhanced Quality)

#### Recommendation 4: Evaluate ReaderLM-v2 for HTML-based Sources

**Description**: Add ReaderLM-v2 as optional high-quality converter for HTML-derived content

**Considerations**:
- 1.5B parameters requires local GPU or API access
- Best suited for HTML intermediary processing
- May require DOCX → HTML → Markdown pipeline adjustment

**Effort**: 6-8 hours (including model setup)
**Expected Impact**: +15-20% fidelity for HTML-derived content

#### Recommendation 5: Create Markdown Repair Prompt Templates

**Description**: Develop specialized prompt templates for different document types

**Templates Needed**:
- Technical documentation (code-heavy)
- Business documents (tables, lists)
- Academic papers (citations, math)
- Mixed content (general-purpose)

**Effort**: 3-4 hours
**Expected Impact**: +10-15% fidelity with template matching

#### Recommendation 6: Implement MCP Server Integration

**Description**: Add MarkItDown-MCP server support for seamless Claude Code integration

**Implementation Approach**:
1. Add MCP detection in skill/command
2. Configure connection via CLAUDE.md or environment
3. Use MCP for conversion when available
4. Fall back to local tools otherwise

**Effort**: 4-5 hours
**Expected Impact**: Better workflow integration, marginal fidelity improvement

#### Recommendation 7: Enhanced Structural Validation

**Description**: Extend validation to include code blocks, blockquotes, and other missing elements

**Implementation Approach**:
1. Update `check_structure()` in `convert-markdown.sh`
2. Add code block count: `grep -c '^\`\`\`' "$md_file"`
3. Add blockquote count: `grep -c '^>' "$md_file"`
4. Generate fidelity score comparing expected vs actual counts

**Effort**: 2 hours
**Expected Impact**: Better quality visibility, enables targeted improvements

### Category 3: Advanced Improvements (Future Enhancement)

#### Recommendation 8: Build Custom Markdown Repair MCP Server

**Description**: Create project-specific MCP server for markdown repair operations

**Components**:
- Code block detection and wrapping
- Inline code identification
- Blockquote restoration
- Language detection for syntax highlighting

**Effort**: 8-12 hours
**Expected Impact**: Full control over repair process, +25-30% potential fidelity

#### Recommendation 9: Implement Two-Pass Conversion Pipeline

**Description**: Architect full two-pass conversion system

**Pass 1**: Tool-based extraction (current implementation)
**Pass 2**: LLM refinement with document-type-specific prompts

**Architecture Changes**:
- Add pipeline orchestration layer
- Implement caching for intermediate results
- Add bypass option for speed-critical conversions

**Effort**: 12-16 hours
**Expected Impact**: Maximum fidelity improvement (+30-40%)

#### Recommendation 10: Add Fidelity Benchmarking Suite

**Description**: Create automated fidelity testing framework

**Components**:
- Reference document corpus (various types)
- Automated conversion testing
- Fidelity scoring metrics
- Regression detection

**Effort**: 8-10 hours
**Expected Impact**: Data-driven improvement tracking

#### Recommendation 11: Implement Document-Type Detection

**Description**: Automatically detect document type and apply appropriate conversion strategy

**Detection Categories**:
- Code documentation (use LLM post-processing)
- Business documents (standard conversion)
- Academic papers (enable math preservation)
- Mixed content (hybrid approach)

**Effort**: 4-6 hours
**Expected Impact**: Targeted optimization, +10-15% average fidelity

#### Recommendation 12: Add Prompt Chaining for Complex Documents

**Description**: Implement multi-step prompt chain for documents with varied content types

**Chain Steps**:
1. Document structure analysis
2. Section-by-section processing
3. Cross-section consistency validation
4. Final assembly and verification

**Effort**: 6-8 hours
**Expected Impact**: +20-25% for complex multi-section documents

## Implementation Roadmap

### Phase 1: Quick Wins (1-2 days)

1. Recommendation 3: Code block detection heuristics
2. Recommendation 7: Enhanced structural validation
3. Recommendation 5: Create initial prompt templates

### Phase 2: Core Improvements (1 week)

4. Recommendation 1: LLM post-processing layer
5. Recommendation 2: Marker integration for PDF
6. Recommendation 6: MCP server integration

### Phase 3: Advanced Features (2-4 weeks)

7. Recommendation 4: ReaderLM-v2 evaluation
8. Recommendation 9: Two-pass pipeline
9. Recommendation 10: Benchmarking suite
10. Recommendation 8: Custom MCP server (optional)

## References

### File References

- `/home/benjamin/.config/.claude/specs/892_convert_docs_validation_improvements/reports/001_convert_docs_validation_report.md` (lines 398-404, 387-426, 545-599)
- `/home/benjamin/.config/.claude/lib/convert/convert-core.sh` (lines 28-60, 108-133, 749-754)
- `/home/benjamin/.config/.claude/lib/convert/convert-docx.sh` (lines 30-78)
- `/home/benjamin/.config/.claude/lib/convert/convert-markdown.sh` (lines 21-39)
- `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 43-69, 140-158)
- `/home/benjamin/.config/.claude/commands/convert-docs.md` (lines 106-117)

### External References

- SpecterOps LLM Word-to-Markdown Blog: https://specterops.io/blog/2025/06/20/llmentary-my-dear-claude-prompt-engineering-an-llm-to-perform-word-to-markdown-conversion-for-templated-content/
- Anthropic Claude Prompting Best Practices: https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices
- Microsoft MarkItDown: https://github.com/microsoft/markitdown
- MarkItDown MCP Server: https://github.com/mcp/microsoft/markitdown
- Marker PDF Converter: https://github.com/datalab-to/marker
- ReaderLM-v2: https://jina.ai/models/ReaderLM-v2/
- MinerU: https://github.com/opendatalab/MinerU
- Nutrient DWS MCP Server: https://www.nutrient.io/blog/teaching-llms-to-read-pdfs/
- Model Context Protocol: https://modelcontextprotocol.io/specification/2025-06-18
- PyMuPDF4LLM: https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/

### Research Sources Consulted

- Real Python MarkItDown Tutorial
- Learn Claude Documentation (Converting Content into LLM Friendly Markdown)
- AWS Machine Learning Blog (Prompt Engineering with Claude 3)
- Medium Articles on LLM Markdown Generation
- GitHub Issues/Discussions on Markdown Formatting Problems

## Implementation Status

- **Status**: Planning Complete
- **Plan**: [001_convert_docs_fidelity_llm_practices_plan.md](../plans/001_convert_docs_fidelity_llm_practices_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-21

## Conclusion

The `/convert-docs` command has a solid foundation but faces inherent limitations in preserving code-specific markdown elements due to tool-based converter design philosophy. By implementing the recommended LLM post-processing layer (Recommendation 1) and enhanced tool integration (Recommendation 2), expected fidelity can improve from 82% to approximately 95% for DOCX and from 34% to approximately 55-60% for PDF. The hybrid approach of combining existing tools with targeted LLM refinement represents the optimal balance of implementation effort versus quality improvement.
