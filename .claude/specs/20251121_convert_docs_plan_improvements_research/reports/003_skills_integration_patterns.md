# Skills Integration Patterns Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: How to integrate document-converter skill with /convert-docs command
- **Report Type**: codebase analysis

## Executive Summary

The document-converter skill already exists at `.claude/skills/document-converter/` with comprehensive conversion capabilities. The skill can enhance /convert-docs through autonomous invocation, Haiku model selection, and composition with other skills. Integration requires updating the skill to support Gemini API mode and ensuring the command properly delegates to the skill when available.

## Findings

### 1. Skill Structure

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 1-13)

The skill uses standard YAML frontmatter:

```yaml
---
name: document-converter
description: Convert between Markdown, DOCX, and PDF formats bidirectionally...
allowed-tools: Bash, Read, Glob, Write
dependencies:
  - pandoc>=2.0
  - python3>=3.8
  - markitdown (optional, recommended)
  - pymupdf4llm (optional, recommended)
model: haiku-4.5
model-justification: Orchestrates external conversion tools with minimal AI reasoning required
fallback-model: sonnet-4.5
---
```

**Key Observations**:
- Already specifies `haiku-4.5` as primary model (aligned with parallel execution recommendation)
- Dependencies clearly listed (can be extended for google-genai)
- Description includes trigger keywords for autonomous invocation

### 2. Skill Triggering Mechanism

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 207-226)

Skills auto-invoke when Claude detects relevant needs:

```markdown
### From Claude Code Agents

When working within agent contexts, the skill automatically triggers when Claude detects conversion needs:

User: "Extract text from these PDF reports"
- Skill auto-invokes: document-converter
- Converts PDFs to Markdown
- Returns structured text
```

**Trigger Keywords** (from description):
- "convert", "document", "PDF", "DOCX", "Markdown"
- "extract text", "word file", "format conversion"

### 3. Command-to-Skill Delegation

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 219-226)

The /convert-docs command delegates to the skill when available:

```markdown
### From Slash Commands

The `/convert-docs` command delegates to this skill when available:

/convert-docs ./documents ./output
- Checks skill availability
- Delegates to document-converter skill
- Falls back to script mode if skill unavailable
```

### 4. Tool Priority Matrix

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 43-69)

Current tool priority (before Gemini integration):

| Direction | Primary | Fallback |
|-----------|---------|----------|
| DOCX -> Markdown | MarkItDown (75-80%) | Pandoc (68%) |
| PDF -> Markdown | MarkItDown | PyMuPDF4LLM |
| Markdown -> DOCX | Pandoc (95%+) | - |
| Markdown -> PDF | Pandoc + Typst | Pandoc + XeLaTeX |

### 5. Skill Composition Pattern

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 228-234)

Skills can depend on other skills:

```yaml
# research-specialist skill
dependencies:
  - document-converter  # Auto-loads for PDF analysis
```

This enables hierarchical skill invocation.

### 6. Conversion Workflow

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 106-139)

The skill follows a 5-phase workflow:

1. **Phase 1: Tool Detection** - Check availability of tools
2. **Phase 2: File Discovery** - Scan and validate files
3. **Phase 3: Conversion Execution** - Apply timeouts, cascading fallbacks
4. **Phase 4: Validation** - Verify output, check broken links
5. **Phase 5: Reporting** - Generate conversion.log with statistics

### 7. Progress Streaming

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 98-104)

The skill emits progress markers:

```
[PROGRESS] Converting: file1.docx -> file1.md
[PROGRESS] Converting: file2.pdf -> file2.md (2/10)
[SUCCESS] Converted file1.docx -> file1.md
[FAILED] file3.pdf: Conversion timeout after 300s
```

### 8. Script Locations

**Source**: `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 240-246)

The skill relies on conversion scripts:

- **Core orchestration**: `.claude/lib/convert/convert-core.sh`
- **DOCX functions**: `.claude/lib/convert/convert-docx.sh`
- **PDF functions**: `.claude/lib/convert/convert-pdf.sh`
- **Markdown utilities**: `.claude/lib/convert/convert-markdown.sh`

## Application to /convert-docs Plan

### Required Skill Updates for Gemini Integration

Based on the existing plan (Phase 4), the skill needs:

1. **Updated Dependencies Section**:
```yaml
dependencies:
  - pandoc>=2.0
  - python3>=3.8
  - markitdown (optional, recommended)
  - pymupdf4llm (optional, recommended)
  - pdf2docx (optional, for PDF->DOCX)
  - google-genai (optional, for enhanced PDF conversion)
```

2. **Updated Tool Priority Matrix**:
```markdown
### PDF -> Markdown
1. **Gemini API** (primary, if GEMINI_API_KEY set) - 90%+ fidelity
   - Excellent table and layout handling
   - Native OCR for scanned documents
   - Requires internet connection
2. **PyMuPDF4LLM** (primary fallback) - 70-85% fidelity
3. **MarkItDown** (secondary fallback) - 65-75% fidelity
```

3. **New "Conversion Modes" Section**:
```markdown
## Conversion Modes

### Default Mode (API)
When GEMINI_API_KEY is set, PDF conversions use Gemini API for
significantly improved quality. Other conversions use local tools.

### Offline Mode
Use --no-api flag or set CONVERT_DOCS_OFFLINE=true to disable
all API calls. All conversions use local tools only.
```

### Skill Invocation from Parallel Coordinator

For parallel conversion with Haiku subagents, the skill can be invoked:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Convert PDF to Markdown using document-converter skill"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md

    **Conversion Task**:
    - Input: /path/to/document.pdf
    - Output: /path/to/output/document.md
    - Mode: gemini  # or offline
    - Direction: PDF -> Markdown

    Execute conversion following skill guidelines.
    Return: CONVERSION_COMPLETE: /path/to/output/document.md
}
```

## Recommendations

### Recommendation 1: Update SKILL.md with Gemini Support

Add to dependencies section:
```yaml
- google-genai (optional, for enhanced PDF conversion)
```

Add new section documenting API vs offline modes with environment variable.

### Recommendation 2: Add Conversion Mode Detection to Skill

The skill should detect and report conversion mode:

```bash
# In skill initialization
if [[ -n "${GEMINI_API_KEY:-}" ]] && [[ "${CONVERT_DOCS_OFFLINE:-false}" != "true" ]]; then
  CONVERSION_MODE="gemini"
else
  CONVERSION_MODE="offline"
fi
echo "[INFO] Conversion mode: $CONVERSION_MODE"
```

### Recommendation 3: Enhance Progress Markers for Mode Indication

Update progress markers to show mode:

```
[PROGRESS] Converting: file1.pdf -> file1.md (mode: gemini)
[PROGRESS] Converting: file2.pdf -> file2.md (mode: offline, 2/10)
```

### Recommendation 4: Document Skill-Command Integration

Update `/convert-docs` command guide to explain:
1. When skill is used vs direct script execution
2. How to force skill invocation: "Use document-converter skill to convert..."
3. Fallback behavior when skill unavailable

### Recommendation 5: Add Skill Availability Check

In /convert-docs command, before parallel dispatch:

```bash
# Check if skill is available for delegation
SKILL_PATH="${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md"
if [ -f "$SKILL_PATH" ]; then
  SKILL_AVAILABLE=true
  echo "[INFO] Using document-converter skill for conversions"
else
  SKILL_AVAILABLE=false
  echo "[INFO] Skill not found, using direct script execution"
fi
```

## References

- `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` (lines 1-13, 43-69, 98-104, 106-139, 207-226, 228-234, 240-246)
- `/home/benjamin/.config/.claude/skills/document-converter/reference.md` (skill reference documentation)
- `/home/benjamin/.config/.claude/skills/document-converter/examples.md` (usage examples)
- `/home/benjamin/.config/.claude/skills/document-converter/templates/batch-conversion.sh` (batch processing template)
- `/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md` (lines 488-558 - Phase 4 skill integration)
