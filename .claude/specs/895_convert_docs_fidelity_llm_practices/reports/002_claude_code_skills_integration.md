# Claude Code Skills Integration Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: Skills system and document-converter skill integration
- **Report Type**: codebase analysis
- **Related Plan**: /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md

## Executive Summary

The document-converter skill provides an existing, well-architected foundation for the /convert-docs command. The skill uses a model-invoked architecture with progressive disclosure, supports autonomous detection of conversion needs, and integrates seamlessly with the command system. For the Gemini API enhancement, the skill's SKILL.md file can be extended to include API-based conversion while maintaining backward compatibility with offline tools. The skill already supports intelligent tool selection with fallback mechanisms - the same pattern should be applied to Gemini API integration.

## Findings

### 1. Existing Document-Converter Skill Architecture

**Location**: `/home/benjamin/.config/.claude/skills/document-converter/`

**Structure**:
```
.claude/skills/document-converter/
├── SKILL.md        # Core skill definition (lines 1-328)
├── reference.md    # Technical reference and API docs (lines 1-789)
├── examples.md     # Usage examples
├── scripts/        # Symlinks to lib/convert/
└── templates/      # Batch processing templates
```

**Key Characteristics** (from SKILL.md:1-13):
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

### 2. Skill Invocation Patterns

**Autonomous Invocation** (from skills/README.md:144-152):
Skills automatically trigger when Claude detects relevant needs:
```
User: "Convert the Word documents to markdown"
-> Claude detects conversion need
-> Loads document-converter skill
-> Executes conversion
-> Returns results
```

**Command Integration** (from SKILL.md:218-226):
```bash
# /convert-docs delegates to skill when available
/convert-docs ./documents ./output
-> Checks for document-converter skill
-> Delegates to skill if available
-> Falls back to script mode if skill unavailable
```

**Agent Integration** (from skills/README.md:175-182):
Agents can auto-load skills via `skills:` frontmatter field:
```yaml
---
name: doc-converter
skills: document-converter
---
```

### 3. Current Tool Selection Matrix

The skill implements intelligent tool selection with fallback (from SKILL.md:43-69):

| Source -> Target | Primary Tool | Fallback Tool | Fidelity |
|-----------------|--------------|---------------|----------|
| DOCX -> Markdown | MarkItDown | Pandoc | 75-80% |
| PDF -> Markdown | MarkItDown | PyMuPDF4LLM | 70-85% |
| Markdown -> DOCX | Pandoc | - | 95%+ |
| Markdown -> PDF | Pandoc+Typst | Pandoc+XeLaTeX | 98%+ |

### 4. Conversion Core Implementation

**Main Orchestration** (from convert-core.sh:1-20):
```bash
#!/usr/bin/env bash
# convert-core.sh - Document conversion orchestration
# Main orchestration module for document conversion. Handles tool detection,
# file discovery, validation, conversion dispatching, and reporting.
```

**Tool Detection Pattern** (from convert-core.sh:108-133):
```bash
detect_tools() {
  # MarkItDown
  if command -v markitdown &>/dev/null; then
    MARKITDOWN_AVAILABLE=true
  fi

  # Pandoc
  if command -v pandoc &>/dev/null; then
    PANDOC_AVAILABLE=true
  fi

  # PyMuPDF4LLM
  if python3 -c "import pymupdf4llm" 2>/dev/null; then
    PYMUPDF_AVAILABLE=true
  fi
  # ... more tools
}
```

**File Conversion Dispatch** (from convert-core.sh:848-920):
The `convert_file()` function handles dispatching with automatic fallback:
1. Try primary tool (e.g., MarkItDown)
2. On failure or timeout, try fallback tool
3. Log success/failure with tool used
4. Update counters for summary

### 5. Integration Points for Gemini API

**Where to Add Gemini Support**:

1. **Tool Detection** (convert-core.sh:~108):
   Add `GEMINI_AVAILABLE` flag based on `GEMINI_API_KEY` presence

2. **Tool Selection** (convert-core.sh:190-203):
   Add Gemini as primary PDF converter when available:
   ```bash
   select_pdf_tool() {
     if [[ "$GEMINI_AVAILABLE" == "true" ]]; then
       echo "gemini"
     elif [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
       echo "markitdown"
     elif [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
       echo "pymupdf"
     else
       echo "none"
     fi
   }
   ```

3. **Conversion Dispatch** (convert-core.sh:920-980):
   Add Gemini conversion path in PDF case block

### 6. Skill vs Direct Implementation

**Skill Advantages**:
- Autonomous invocation in chat contexts
- Progressive disclosure (token efficient)
- Composable with other skills
- Agent integration via `skills:` field

**Direct Script Advantages**:
- Simpler for command-line usage
- No skill discovery overhead
- Direct tool control

**Recommendation**: Keep both paths - skill for chat/agent contexts, direct script for command invocation with skill delegation.

### 7. Dependency Management

Current dependencies (from SKILL.md:6-9):
```yaml
dependencies:
  - pandoc>=2.0
  - python3>=3.8
  - markitdown (optional, recommended)
  - pymupdf4llm (optional, recommended)
```

**Proposed Addition**:
```yaml
dependencies:
  - pandoc>=2.0
  - python3>=3.8
  - markitdown (optional, recommended)
  - pymupdf4llm (optional, recommended)
  - google-genai (optional, for API mode)
```

### 8. SKILL.md Update Pattern

To add Gemini support, update the Tool Priority Matrix section (SKILL.md:43-69):

```markdown
### PDF -> Markdown
1. **Gemini API** (primary, if GEMINI_API_KEY set) - 90%+ fidelity
   - Excellent table and layout handling
   - Native OCR for scanned documents
   - Requires internet connection
2. **MarkItDown** (fallback) - Best for offline
   - Consistent quality across document types
   - Easy to configure
3. **PyMuPDF4LLM** (fallback) - Fast alternative
   - Zero configuration required
   - Perfect Unicode preservation
```

## Recommendations

### 1. Extend Skill Definition for Gemini
Update SKILL.md to document Gemini API as primary PDF converter while maintaining backward compatibility with offline tools.

### 2. Add google-genai to Optional Dependencies
```yaml
dependencies:
  - google-genai (optional, for enhanced PDF conversion)
```

### 3. Keep Skill/Script Dual Path
- Skill handles autonomous invocation
- Script handles direct command invocation
- `/convert-docs` checks skill availability first

### 4. Update Skill Guide
Add documentation for Gemini mode to `/home/benjamin/.config/.claude/docs/guides/skills/document-converter-skill-guide.md`

### 5. Maintain Offline Fallback Chain
Preserve the existing fallback chain:
```
Gemini API -> MarkItDown -> PyMuPDF4LLM -> Pandoc
```

### 6. Add Mode Indicator to Skill Output
Include conversion mode in progress output:
```
[PROGRESS] Converting: file.pdf -> file.md (Mode: gemini)
[PROGRESS] Converting: file.pdf -> file.md (Mode: offline/markitdown)
```

## References

### Skill Files (Analyzed)
- /home/benjamin/.config/.claude/skills/document-converter/SKILL.md:1-328
- /home/benjamin/.config/.claude/skills/document-converter/reference.md:1-789
- /home/benjamin/.config/.claude/skills/README.md:1-333

### Implementation Files (Analyzed)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:1-1353
- /home/benjamin/.config/.claude/lib/convert/convert-pdf.sh (referenced)
- /home/benjamin/.config/.claude/lib/convert/convert-docx.sh (referenced)

### Guide Files (Analyzed)
- /home/benjamin/.config/.claude/docs/guides/skills/document-converter-skill-guide.md:1-635

### External Documentation
- Claude Code Skills Guide: https://code.claude.com/docs/en/skills.md
- Skills Best Practices: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

---

**Report Generated**: 2025-11-21
**Research Complexity**: 2 (Medium)
**Status**: Complete
