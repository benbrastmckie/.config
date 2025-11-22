# Gemini API MCP Services for Document Conversion Research Report

## Metadata

- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Gemini API Cloud-Based MCP Services for Document Conversion
- **Report Type**: technology evaluation
- **Complexity**: 2 (Medium - focused web search and analysis)
- **Specs Directory**: /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices
- **Related Plan**: /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md

## Executive Summary

Research into Gemini API MCP services reveals multiple community-built MCP server implementations, but **no official Google-maintained MCP server** for Gemini API. The most promising option for PDF-to-markdown conversion is **CLDGeminiPDF-Analyzer**, which directly supports PDF file uploads to Gemini for analysis. However, critical limitations exist: most Gemini MCP servers explicitly do **not support local file uploads**, and the ones that do require Java 11+ and filesystem MCP server dependencies.

**Key Finding**: Gemini API natively supports PDF processing (up to 50MB/1000 pages) with excellent document understanding capabilities, but integrating this into Claude Code via MCP requires either:
1. A specialized MCP server like CLDGeminiPDF-Analyzer (complex setup)
2. Hosting PDFs on public URLs for URL-based analysis
3. Direct API integration (bypassing MCP)

**Recommendation**: The current plan's approach using **Nutrient DWS MCP + MarkItDown MCP** remains preferable for the /convert-docs use case due to simpler setup and direct markdown output. Gemini API via MCP is better suited for document analysis/Q&A rather than format conversion.

## 1. Available Gemini MCP Servers

### 1.1 Community MCP Server Implementations

| Server | Repository | File Upload Support | Key Features | Setup Complexity |
|--------|-----------|---------------------|--------------|------------------|
| **CLDGeminiPDF-Analyzer** | tfll37/CLDGeminiPDF-Analyzer | **Yes** (via filesystem MCP) | PDF analysis via Gemini, dual processing | High (Java 11+, filesystem MCP) |
| mcp-server-gemini | aliargun/mcp-server-gemini | No (images via vision only) | Text generation, embeddings, token counting | Low (npx) |
| mcp-gemini-server | bsmi021/mcp-gemini-server | **No** (explicit limitation) | URL-based multimedia, streaming | Medium (npm build) |
| gemini-mcp-server | vytautas-bunevicius/gemini-mcp-server | Limited | Gemini model access, standard MCP | Medium |
| jacob/gemini-cli-mcp | jacob/gemini-cli-mcp | No | OAuth auth, session persistence | Medium |

### 1.2 File Upload Limitations

**Critical Finding**: Most Gemini MCP servers explicitly **do not support** direct file uploads:

From `mcp-gemini-server` documentation:
> "This MCP Gemini Server does not support the following file upload operations: Local file uploads: Cannot upload files from your local filesystem to Gemini. Base64 encoded files: Cannot process base64-encoded image or video data. Binary file data: Cannot handle raw file bytes or binary data."

### 1.3 CLDGeminiPDF-Analyzer (Most Relevant for PDF Processing)

**Repository**: https://github.com/tfll37/CLDGeminiPDF-Analyzer

**Purpose**: MCP server enabling Claude Desktop to analyze PDF documents using Google's Gemini AI models.

**Key Features**:
- PDF analysis via Gemini models (2.5, 2.0, 1.5 series)
- Dual processing methods: direct PDF upload OR text extraction fallback
- Multi-model support including Gemma models
- Works with Claude Desktop

**Limitations**:
- Requires Filesystem MCP Server as dependency
- Does NOT support drag-and-drop files
- Version 1.0.0 only
- Returns Gemini analysis responses, **not markdown conversion**

## 2. Installation and Configuration

### 2.1 CLDGeminiPDF-Analyzer Setup

**Prerequisites**:
- Java 11 or higher
- Node.js (for filesystem MCP server)
- Gemini API key (free from Google AI Studio)

**Installation Steps**:

1. **Download or Build JAR**:
```bash
# Option A: Download pre-built
wget https://github.com/tfll37/CLDGeminiPDF-Analyzer/releases/download/v1.0.0/CLDGeminiPDF.v1.0.0.jar

# Option B: Build from source
git clone https://github.com/tfll37/CLDGeminiPDF-Analyzer.git
cd CLDGeminiPDF-Analyzer
mvn clean compile assembly:single
```

2. **Get Gemini API Key**:
```
Visit: https://aistudio.google.com/
Create API key (free)
```

3. **Configure Claude Desktop** (`~/.config/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-filesystem", "/path/to/documents"]
    },
    "gemini-pdf": {
      "command": "java",
      "args": ["-jar", "/path/to/CLDGeminiPDF.v1.0.0.jar"],
      "env": {
        "GEMINI_API_KEY": "your-api-key",
        "GEMINI_MODEL": "gemini-2.5-flash"
      }
    }
  }
}
```

### 2.2 mcp-server-gemini Setup (URL-based only)

**Installation**:
```bash
npx -y github:aliargun/mcp-server-gemini
```

**Configuration** (Claude Desktop/Cursor/Windsurf):
```json
{
  "mcpServers": {
    "gemini": {
      "command": "npx",
      "args": ["-y", "github:aliargun/mcp-server-gemini"],
      "env": {
        "GEMINI_API_KEY": "your-api-key"
      }
    }
  }
}
```

**Note**: This server only supports URL-based analysis, not local file uploads.

### 2.3 Alternative: Gemini API Direct Integration

For direct PDF processing without MCP, Gemini API supports:

```python
# Python example using google-genai SDK
import google.generativeai as genai

genai.configure(api_key="your-api-key")
model = genai.GenerativeModel("gemini-2.5-flash")

# Upload PDF via Files API
pdf_file = genai.upload_file("document.pdf")

# Process with prompt
response = model.generate_content([
    pdf_file,
    "Convert this PDF to well-formatted markdown"
])
print(response.text)
```

## 3. Pricing Analysis

### 3.1 Gemini API Pricing (as of November 2025)

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Context Window | Free Tier |
|-------|----------------------|------------------------|----------------|-----------|
| **Gemini 2.5 Flash** | $0.30 | $2.50 | 1M tokens | Yes (limited) |
| **Gemini 2.5 Flash-Lite** | $0.10 | $0.40 | 1M tokens | Yes (limited) |
| Gemini 2.5 Pro | $1.25 (<=200k) / $2.50 (>200k) | $10.00-$15.00 | 1M tokens | Yes (limited) |
| Gemini 3 Pro Preview | $2.00 (<=200k) / $4.00 (>200k) | $12.00-$18.00 | 1M tokens | Yes (limited) |
| Gemini 2.0 Flash | $0.10 | $0.40 | 1M tokens | Yes (limited) |

### 3.2 Free Tier Limits

- **Gemini CLI**: 60 requests/minute, 1,000 requests/day (personal Google account)
- **API Free Tier**: Available for all models with rate limits
- **Files API**: Free (files stored for 48 hours)

### 3.3 Cost Comparison for PDF Conversion

**Scenario**: Converting 50-page technical PDF (~100K tokens)

| Provider | Model | Estimated Cost |
|----------|-------|----------------|
| Gemini API | 2.5 Flash | ~$0.03 input + ~$0.25 output = **$0.28** |
| Gemini API | 2.5 Flash-Lite | ~$0.01 input + ~$0.04 output = **$0.05** |
| Nutrient DWS | Cloud | Free tier (200 credits/month) or ~$0.05/document |
| MarkItDown MCP | Local | **Free** (no API calls) |

### 3.4 Important Notes on Gemini 2.5 Pricing Changes

Recent pricing update unified thinking/non-thinking modes:
> "Google has unified everything under one price: $0.30 input and $2.50 output tokens per million. Even though Google lowered the thinking mode price from $3.50 to $2.50, anyone who doesn't need thinking still pays the premium."

## 4. Gemini API Document Processing Capabilities

### 4.1 Native PDF Support

Gemini models provide robust PDF processing:

- **File Size**: Up to 50MB or 1000 pages
- **Processing**: Native vision for layout understanding
- **Capabilities**:
  - Text, images, diagrams, charts, and tables analysis
  - Structured output extraction (JSON, markdown)
  - Content summarization and Q&A
  - Document transcription (to HTML/markdown) preserving layout
  - Multi-document processing in single request

### 4.2 Upload Methods

1. **Inline Data**: For PDFs < 20MB, base64 encode and include in request
2. **Files API**: For larger files, upload first and reference by URI
3. **URL-based**: Process PDFs from public URLs directly

### 4.3 Gemini 3 Improvements (2025)

- Granular `media_resolution` parameter (low/medium/high)
- Native text extraction from embedded PDF text
- **No token charges** for native PDF text extraction

### 4.4 Markdown Conversion Quality

**Practical Approach** (from research):
1. For each PDF page, create an image
2. Pass image to Gemini with conversion prompt
3. Combine markdown from all pages

**Prompt Example**:
```
Convert the contents of this page into Markdown format, paying attention to structure and formatting. Preserve:
- Headings hierarchy
- Code blocks with language hints
- Tables as markdown tables
- Lists (ordered and unordered)
- Inline code and technical terms
```

### 4.5 Quality Assessment

From research benchmarks:
- Gemini 2.5 Flash with `--use_llm` mode achieves higher accuracy than standalone tools
- Excellent handling of complex layouts, tables, and multi-column content
- Native understanding of document structure beyond OCR

## 5. Comparison: Gemini vs Nutrient DWS vs MarkItDown

### 5.1 Feature Comparison

| Feature | Gemini API (via MCP) | Nutrient DWS MCP | MarkItDown MCP |
|---------|---------------------|------------------|----------------|
| **Setup Complexity** | High | Low (npx) | Low (pip/uvx) |
| **API Key Required** | Yes (free tier) | Yes (200 free/month) | No |
| **Local File Support** | Limited* | Yes | Yes |
| **PDF Quality** | Excellent | Excellent | Good (pdfminer) |
| **Markdown Output** | Via prompting | Native | Native |
| **Offline Mode** | No | No | Yes |
| **GPU Required** | No | No | No |
| **Cost** | $0.05-0.28/doc | Free tier or ~$0.05 | Free |

*Via CLDGeminiPDF-Analyzer with filesystem MCP, otherwise URL-only

### 5.2 Quality Comparison for PDF-to-Markdown

| Aspect | Gemini API | Nutrient DWS | MarkItDown |
|--------|-----------|--------------|------------|
| Table Preservation | Excellent | Excellent | Limited |
| Code Block Detection | Good (via prompting) | Good | Poor |
| Layout Preservation | Excellent | Excellent | Basic |
| OCR Quality | Excellent (native) | Excellent | Requires optional deps |
| Complex Documents | Excellent | Excellent | Limited |
| Speed | Slower (API) | Medium | Fast |

### 5.3 Integration Complexity for /convert-docs

| Tool | Integration Steps | Estimated Hours |
|------|-------------------|-----------------|
| Nutrient DWS MCP | npm install, API key setup, MCP config | 2-3 |
| MarkItDown MCP | pip install, MCP config | 1-2 |
| Gemini via CLDGeminiPDF | Java install, filesystem MCP, JAR config, API key | 4-6 |
| Gemini via direct API | Python SDK, API wrapper functions | 3-4 |

## 6. Recommendations

### 6.1 Primary Recommendation: Maintain Current Plan

**Keep Nutrient DWS MCP + MarkItDown MCP** as the primary approach for /convert-docs because:

1. **Simpler Setup**: npm/pip install vs Java + multiple MCPs
2. **Direct Markdown Output**: No prompt engineering needed
3. **Better Tooling Fit**: Purpose-built for document conversion
4. **Cost Effective**: MarkItDown is free, Nutrient has free tier
5. **Offline Fallback**: MarkItDown CLI works without network

### 6.2 When to Consider Gemini MCP

Gemini API via MCP makes sense for:

1. **Document Analysis/Q&A**: Not pure conversion, but understanding
2. **Complex Multi-Document Workflows**: Leveraging 1M context window
3. **Existing Gemini Integration**: If already using Gemini elsewhere
4. **High-Fidelity Requirements**: Where prompting can customize output

### 6.3 Potential Future Enhancement

If Gemini integration becomes desirable:

1. **Short-term**: Add `--gemini` flag using direct API (not MCP)
   - Simpler than MCP setup
   - Full control over prompts and output
   - Cost: ~$0.05-0.28 per document

2. **Long-term**: Monitor for official Google Gemini MCP server
   - No official server exists yet
   - Community servers have significant limitations

### 6.4 Plan Revision Not Recommended

The research does **not** support revising the current plan to use Gemini MCP because:

| Factor | Gemini MCP | Current Plan (Nutrient DWS + MarkItDown) |
|--------|-----------|------------------------------------------|
| Setup Time | 4-6 hours | 2-3 hours |
| Reliability | Community maintained | Actively maintained |
| File Handling | Complex/limited | Native |
| Output Format | Requires prompting | Native markdown |
| Cost | Higher for large volumes | Free tier/cheap |
| Offline Support | None | MarkItDown CLI fallback |

## 7. Summary of Findings

### 7.1 Research Questions Answered

1. **Does a Gemini API MCP server exist?**
   - Yes, multiple community implementations exist
   - No official Google-maintained MCP server

2. **How is it installed/configured?**
   - Various methods (npx, pip, Java JAR)
   - Most require Gemini API key
   - CLDGeminiPDF requires additional filesystem MCP

3. **What are the costs?**
   - Free tier available (limited)
   - Gemini 2.5 Flash: $0.30/$2.50 per 1M tokens (in/out)
   - Gemini 2.5 Flash-Lite: $0.10/$0.40 per 1M tokens

4. **Does Gemini have PDF processing?**
   - Yes, excellent native PDF support (up to 50MB/1000 pages)
   - Native vision for layout understanding
   - Can transcribe to markdown via prompting

5. **Comparison with Nutrient DWS and MarkItDown?**
   - Quality: Gemini >= Nutrient DWS > MarkItDown
   - Setup: MarkItDown < Nutrient DWS < Gemini MCP
   - Cost: MarkItDown (free) < Nutrient DWS < Gemini

6. **Existing MCP servers for document processing?**
   - CLDGeminiPDF-Analyzer: Best option but complex setup
   - Most others don't support local file uploads

### 7.2 Final Verdict

**Do not replace Nutrient DWS + MarkItDown MCP with Gemini MCP** for the /convert-docs fidelity improvement plan. The current approach is:
- Simpler to implement
- More reliable for production use
- Better suited for format conversion (vs document analysis)
- More cost-effective at scale

If Gemini integration is desired in the future, consider **direct API integration** rather than MCP for better control and simpler setup.

## References

### MCP Server Repositories

- CLDGeminiPDF-Analyzer: https://github.com/tfll37/CLDGeminiPDF-Analyzer
- mcp-server-gemini (aliargun): https://github.com/aliargun/mcp-server-gemini
- mcp-gemini-server (bsmi021): https://github.com/bsmi021/mcp-gemini-server
- gemini-mcp-server (vytautas-bunevicius): https://github.com/vytautas-bunevicius/gemini-mcp-server
- Gemini CLI: https://github.com/google-gemini/gemini-cli

### Official Documentation

- Gemini API Pricing: https://ai.google.dev/gemini-api/docs/pricing
- Gemini Document Processing: https://ai.google.dev/gemini-api/docs/document-processing
- Gemini Models: https://ai.google.dev/gemini-api/docs/models
- MCP Servers with Gemini CLI: https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html

### Related Research

- Nutrient DWS MCP: https://github.com/PSPDFKit/nutrient-dws-mcp-server
- MarkItDown MCP: https://github.com/microsoft/markitdown
- Google Developers Blog - FastMCP: https://developers.googleblog.com/en/gemini-cli-fastmcp-simplifying-mcp-server-development/

---

**Report Generated**: 2025-11-21
**Research Complexity**: 2 (Medium)
**Status**: Complete
