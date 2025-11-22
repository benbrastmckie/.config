# Lightweight Tools & Installation Analysis for /convert-docs Improvements

## Report Metadata

- **Date**: 2025-11-21
- **Purpose**: Evaluate installation complexity of proposed tools and identify lightweight alternatives
- **Context**: User concern about avoiding local LLMs and complex installations
- **Related Plan**: `001_convert_docs_fidelity_llm_practices_plan.md`

---

## Executive Summary

After reviewing the implementation plan and researching alternatives, I've identified **two significant concerns** and **multiple lightweight alternatives** that can achieve similar fidelity improvements without complex installations.

### Key Findings

| Concern Level | Item | Issue | Recommendation |
|---------------|------|-------|----------------|
| **HIGH** | Marker with `--use_llm` (Phase 4) | Requires GPU (5GB VRAM), PyTorch, Gemini API | Replace with cloud MCP services |
| **LOW** | ReaderLM-v2 | Correctly listed as "Out of Scope" | No action needed |
| **NONE** | LLM Post-Processing (Phase 2) | Uses Claude API (cloud-based) | Safe to implement |
| **NONE** | MarkItDown | Already pip-installable, no GPU | Already in use |

**Bottom Line**: The plan is mostly safe. The only significant concern is **Phase 4 (Marker integration)**, which can be replaced with cloud-based MCP services for similar or better results.

---

## Detailed Concern Analysis

### 1. Phase 4: Marker Integration - HIGH CONCERN

**What the plan proposes**:
```
Phase 4: Enhanced PDF Pipeline with Marker Integration
- Add Marker tool detection
- Use marker_single document.pdf --use_llm --output_format markdown
- Requires Gemini API key for LLM mode
```

**Installation Requirements** (from PyPI and GitHub):
- Python 3.10+
- PyTorch (significant dependency)
- 5GB VRAM per worker at peak (3.5GB average)
- Surya OCR library
- Texify and Tabled libraries
- For `--use_llm` mode: Gemini API key

**Why this is concerning**:
1. PyTorch is a ~2GB download with complex CUDA dependencies
2. GPU requirement (5GB VRAM) excludes many systems
3. Without GPU, processing is significantly slower
4. Gemini API adds another external dependency
5. Multiple ML model downloads required on first run

**Recommendation**: Replace Phase 4 with cloud-based MCP services (see Alternatives section)

### 2. ReaderLM-v2 - NO CONCERN (Already Out of Scope)

The plan correctly identifies ReaderLM-v2 as "Out of Scope":
```
Future Enhancements (Out of Scope):
- [ ] ReaderLM-v2 integration (requires GPU or API access)
```

**ReaderLM-v2 Requirements**:
- 1.5B parameter model
- Requires T4 GPU minimum (8GB VRAM)
- Recommended: RTX 3090/4090 for production
- CC BY-NC 4.0 license (non-commercial only)

**Status**: No action needed - this is correctly excluded.

### 3. LLM Post-Processing (Phase 2) - NO CONCERN

**What the plan proposes**:
```
Phase 2: LLM Post-Processing Layer
- Uses Claude Haiku for cost-effective processing
- call_claude_api() wrapper
```

**Why this is safe**:
- Claude API is cloud-based (no local installation)
- Haiku model is cost-effective (~$0.25/million input tokens)
- You're already using Claude Code (API access established)
- No GPU or complex dependencies required

**Status**: Safe to implement as planned.

### 4. MarkItDown - NO CONCERN

**Current status**: Already installed and working in your system.

**Installation**: `pip install 'markitdown[all]'`
- Pure Python, no GPU required
- Handles PDF, DOCX, PPTX, images, HTML, audio
- 82K+ GitHub stars, actively maintained by Microsoft

**Status**: Continue using as primary tool.

---

## Lightweight Alternatives to Marker

### Option A: MarkItDown MCP Server (Recommended)

**Installation Complexity**: LOW

Three deployment options:

#### A1. Local Installation (pip)
```bash
pip install markitdown-mcp-server
# Run with:
uvx markitdown-mcp-server
```

**Pros**:
- Same MarkItDown library you already use
- No GPU required
- Simple pip install
- MCP protocol for Claude Code integration

**Claude Code Integration**:
```bash
claude mcp add-json "markitdown" '{"command":"uvx","args":["markitdown-mcp-server"]}'
```

#### A2. Docker Installation
```bash
docker pull markitdown-mcp:latest
```

**Claude Desktop Config**:
```json
{
  "mcpServers": {
    "markitdown": {
      "command": "docker",
      "args": ["run", "--rm", "-i", "markitdown-mcp:latest"]
    }
  }
}
```

#### A3. Apify Cloud (Zero Installation)

**Installation Complexity**: NONE

- Cloud-hosted on Apify platform
- No local Python, no Docker required
- Pay-as-you-go or free tier available
- Connect via OAuth URL: `https://mcp.apify.com`

**Note**: Claude Desktop doesn't support remote MCP servers, but Claude.ai web and VS Code do.

**Best For**: Users who want zero local installation for PDF processing.

---

### Option B: Nutrient DWS MCP Server (Recommended for PDF Quality)

**Installation Complexity**: LOW (npm/npx based)

**Requirements**:
- Node.js (brew install node or Windows installer)
- Nutrient DWS API key (free tier: 200 credits/month)

**Claude Code Integration**:
```bash
claude mcp add-json "nutrient-dws" '{"command":"npx","args":["-y","@nutrient-sdk/dws-mcp-server"],"env":{"NUTRIENT_DWS_API_KEY":"YOUR_API_KEY"}}'
```

**Capabilities**:
- PDF to Markdown conversion
- PDF to HTML conversion
- PDF/UA accessibility conversion
- OCR support
- Document merging and editing

**Pros**:
- Cloud-based processing (no local GPU)
- High-quality PDF parsing
- Free tier available (200 credits/month)
- Simple npm/npx installation
- Actively maintained (v0.0.4 released 2025)

**Cons**:
- Requires API key signup at nutrient.io/api
- Currently supports macOS and Windows (Linux support pending)

**Best For**: Users who need high-fidelity PDF conversion without local ML models.

---

### Option C: Enhanced pypandoc Wrapper

**Installation Complexity**: LOW

```bash
pip install pypandoc
# Pandoc must be installed separately via system package manager
```

**Already Installed?**: Check with `pandoc --version`

**Capabilities**:
- Bidirectional conversion (MD ↔ DOCX, PDF, HTML, LaTeX, EPUB)
- No GPU required
- Mature, well-tested (Pandoc is the gold standard)

**Limitation**: Pandoc alone won't improve the fidelity issues (code fences, inline code) - those require LLM post-processing.

**Best For**: Markdown-to-DOCX/PDF direction (already working well at 95%+).

---

### Option D: md2docx-python (Simple Bidirectional)

**Installation Complexity**: VERY LOW

```bash
pip install md2docx-python
```

**Capabilities**:
- Markdown to DOCX conversion
- DOCX to Markdown conversion
- Supports headings, bold, italic, lists, code blocks, tables

**Released**: March 2025

**Best For**: Simple bidirectional conversion without complex dependencies.

---

## Revised Phase 4 Recommendation

Replace the current Phase 4 (Marker Integration) with this lightweight alternative:

### Phase 4 (Revised): MCP-Based PDF Enhancement

**Objective**: Integrate cloud-based MCP services for improved PDF conversion without local GPU requirements.

**Tasks**:
- [ ] Add Nutrient DWS MCP server detection to `/convert-docs`
- [ ] Implement `--mcp-pdf` flag for MCP-based PDF conversion
- [ ] Add MarkItDown MCP server as alternative option
- [ ] Create fallback chain: Nutrient DWS → MarkItDown MCP → MarkItDown CLI → PyMuPDF4LLM
- [ ] Document API key setup for Nutrient DWS (free tier available)
- [ ] Add MCP server health checking

**Benefits**:
- No GPU required
- Cloud-based processing handles complex PDFs
- Free tier available for testing
- Simple npm/pip installation
- Better accuracy than local-only tools on complex PDFs

**Trade-offs**:
- Requires API key signup (free tier available)
- Network dependency for processing
- Per-document costs for high volume (beyond free tier)

---

## Tool Comparison Matrix

| Tool | Installation | GPU Required | Cost | PDF Quality | DOCX Quality |
|------|-------------|--------------|------|-------------|--------------|
| **MarkItDown** (current) | `pip install` | No | Free | Good | Good |
| **MarkItDown MCP** | `pip install` or Docker | No | Free | Good | Good |
| **Apify Cloud** | None | No | Pay-as-you-go | Good | Good |
| **Nutrient DWS MCP** | `npx` | No | 200 free/month | Excellent | Excellent |
| **Marker** | Complex (PyTorch) | Yes (5GB) | Free | Excellent | N/A |
| **Marker --use_llm** | Complex + Gemini API | Yes (5GB) | API costs | Excellent+ | N/A |
| **pypandoc** | `pip install` + system | No | Free | Basic | Excellent |
| **Claude API (Haiku)** | None (cloud) | No | ~$0.25/1M tokens | N/A (post-process) | N/A |

---

## Recommended Implementation Strategy

### Immediate (Low Effort, High Impact)

1. **Keep Phase 2 as-is**: Claude Haiku post-processing (cloud-based, no local LLM)
2. **Keep Phase 3 as-is**: Fidelity scoring (pure bash, no dependencies)
3. **Modify Phase 4**: Replace Marker with Nutrient DWS MCP or MarkItDown MCP

### Setup Commands

**Option 1: Nutrient DWS MCP (Best PDF quality)**
```bash
# Get free API key at nutrient.io/api
claude mcp add-json "nutrient-dws" '{"command":"npx","args":["-y","@nutrient-sdk/dws-mcp-server"],"env":{"NUTRIENT_DWS_API_KEY":"YOUR_KEY"}}'
```

**Option 2: MarkItDown MCP (Zero API keys)**
```bash
pip install markitdown-mcp-server
claude mcp add-json "markitdown" '{"command":"uvx","args":["markitdown-mcp-server"]}'
```

### Phase Implementation Order (Revised)

1. **Phase 1**: Code Detection Heuristics (unchanged) - 3-4 hours
2. **Phase 2**: LLM Post-Processing with Claude API (unchanged) - 5-6 hours
3. **Phase 3**: Fidelity Scoring (unchanged) - 3-4 hours
4. **Phase 4 (REVISED)**: MCP-Based PDF Enhancement - 3-4 hours
5. **Phase 5**: Command and Skill Integration (minor updates) - 5-6 hours
6. **Phase 6**: Validation and Documentation (unchanged) - 4-5 hours

**Estimated Total**: 23-29 hours (slightly reduced from original 24-32 hours)

---

## Summary of Changes to Original Plan

| Phase | Original | Revised | Reason |
|-------|----------|---------|--------|
| 1 | Code Detection | No change | Pure bash, no dependencies |
| 2 | LLM Post-Processing | No change | Uses Claude API (cloud) |
| 3 | Fidelity Scoring | No change | Pure bash, no dependencies |
| 4 | Marker Integration | **MCP Services** | Avoid GPU/PyTorch requirements |
| 5 | Command Integration | Minor updates | Integrate MCP instead of Marker |
| 6 | Validation | No change | Testing infrastructure |

---

## Conclusion

The implementation plan is **mostly safe** for a user who wants to avoid local LLMs and complex installations. The key change needed is:

**Replace Phase 4 (Marker with GPU) with cloud-based MCP services (Nutrient DWS or MarkItDown MCP).**

This achieves similar or better results with:
- No GPU required
- Simple installation (npm/pip)
- Free tiers available
- Cloud processing handles complex documents

The LLM post-processing in Phase 2 is **not a concern** because it uses Claude API (Haiku model), which is cloud-based and already available through your Claude Code setup.

---

## Resources

### MCP Server Setup Guides

- **Nutrient DWS**: https://www.nutrient.io/blog/teaching-llms-to-read-pdfs/
- **MarkItDown MCP**: https://github.com/microsoft/markitdown
- **Apify Cloud**: https://apify.com/rector_labs/markitdown-mcp-server

### API Key Signups

- **Nutrient DWS**: https://nutrient.io/api (200 free credits/month)
- **Apify**: https://apify.com (free tier available)

### Documentation

- **Claude Code MCP**: https://docs.anthropic.com/claude/docs/claude-code-mcp
- **MCP Protocol**: https://modelcontextprotocol.io/
