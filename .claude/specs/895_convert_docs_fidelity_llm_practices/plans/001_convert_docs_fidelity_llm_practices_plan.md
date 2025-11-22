# /convert-docs Simplified Architecture Implementation Plan

## Metadata

- **Date**: 2025-11-21
- **Feature**: Simplified Document Conversion with Gemini API and Offline Fallback
- **Scope**: Flag-based workflow control, orchestrator standards compliance, parallel execution
- **Estimated Phases**: 6 (0-5)
- **Estimated Hours**: 12-16
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 55 (Tier 2 - moderate implementation with infrastructure alignment)
- **Parallel Potential**: Phases 2, 3, and 4 can run in parallel after Phase 1
- **Revision History**:
  - 2025-11-21: Initial plan creation (6 phases, 23-29 hours)
  - 2025-11-21: Phase 4 revised - replaced Marker/GPU with cloud-based MCP services
  - 2025-11-21: Phase 4 revised - replaced Nutrient DWS MCP with Gemini direct API
  - 2025-11-21: **MAJOR REVISION** - Simplified to 3 phases, removed complexity, added --no-api flag
  - 2025-11-21: **REVISION** - Added Phase 4 for Claude Code skills integration, updated research reports
  - 2025-11-21: **REVISION** - Simplified PDF->DOCX to use pdf2docx directly (not Gemini->Pandoc)
  - 2025-11-21: **REVISION** - Added Phase 0 (Infrastructure Alignment), Phase 5 (Parallel Conversion), expanded testing strategy, orchestrator standards compliance
  - 2025-11-21: **REVISION** - Phase 4 expanded with skills-authoring.md compliance (YAML validation, size constraints, STEP 0/3.5 delegation, compliance checklist)
- **Standards References**:
  - [Skills Authoring Standards](/.claude/docs/reference/standards/skills-authoring.md) - Skill creation compliance requirements
  - [Skills README](/.claude/skills/README.md) - Skills architecture and patterns
  - [Document Converter Skill Guide](/.claude/docs/guides/skills/document-converter-skill-guide.md) - Example implementation
- **Research Reports**:
  - [Gemini API PDF Conversion](/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/001_gemini_api_pdf_conversion.md) - google-genai SDK, gemini-2.5-flash-lite model
  - [Claude Code Skills Integration](/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/002_claude_code_skills_integration.md) - document-converter skill updates
  - [API Flag Implementation](/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/003_api_flag_implementation.md) - --no-api/--offline pattern
  - [Conversion Task Analysis](/home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/reports/004_conversion_task_analysis.md) - Gemini only benefits PDF conversions
  - [Haiku Parallel Subagents](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/001_haiku_parallel_subagents.md) - Wave-based parallel execution using Haiku
  - [Orchestrator Command Standards](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/002_orchestrator_command_standards.md) - Three-tier sourcing, error logging, console summary
  - [Skills Integration Patterns](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/003_skills_integration_patterns.md) - Skill delegation and availability checks
  - [Plan Improvement Recommendations](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/004_plan_improvement_recommendations.md) - Comprehensive plan revision guidance

## Overview

Simplified /convert-docs architecture with Gemini API as the default for PDF-to-Markdown conversion:

1. **Default Mode**: Gemini API for PDF-to-Markdown conversion (when GEMINI_API_KEY available)
2. **Offline Mode**: `--no-api` flag (or `--offline` alias) disables all API calls
3. **Automatic Fallback**: API failures or missing key automatically use local tools
4. **Complete Coverage**: All 6 conversion directions supported with local tools
5. **Claude Code Skills**: document-converter skill updated for autonomous invocation
6. **Orchestrator Standards**: Error logging, console summary, checkpoint support
7. **Parallel Execution**: Wave-based conversion for batch processing with Haiku subagents

**Design Philosophy**: Simple flag-based control. One flag (`--no-api`) changes everything. No complex configuration. No local LLMs, no GPU requirements, no PyTorch, no Marker.

**Key Insight from Research**: Gemini API only adds significant value for PDF-to-Markdown conversion. All other directions (including PDF-to-DOCX via pdf2docx) work equally well or better with local tools because they are format transformations, not content interpretation tasks.

## Conversion Matrix

| From -> To | Default Mode | Offline Mode (--no-api) | LLM Benefit |
|-----------|--------------|-------------------------|-------------|
| **PDF -> Markdown** | **Gemini API** | PyMuPDF4LLM -> MarkItDown | HIGH (+20-30% fidelity) |
| **PDF -> DOCX** | pdf2docx | pdf2docx | NONE (direct is better) |
| **DOCX -> Markdown** | MarkItDown | MarkItDown | LOW (already good) |
| **DOCX -> PDF** | via Markdown | via Markdown | NONE |
| **Markdown -> DOCX** | Pandoc | Pandoc | NONE (template transform) |
| **Markdown -> PDF** | Pandoc + Typst | Pandoc + Typst | NONE (rendering task) |

**Key Insight**: Gemini API only provides significant value for **PDF -> Markdown** conversion because PDFs lack semantic structure and require vision/layout understanding. For PDF -> DOCX, direct conversion via pdf2docx preserves images and layout better than a two-step Gemini -> Markdown -> Pandoc approach. All other formats have explicit structure that local tools handle deterministically.

## Architecture

```
                              /convert-docs <input> <output> [--no-api] [--parallel]
                                              |
                                              v
                                    +------------------+
                                    |  Parse Arguments |
                                    |  Detect Tools    |
                                    +--------+---------+
                                             |
                              +--------------+---------------+
                              |                              |
                       [--no-api set]               [--no-api not set]
                              |                              |
                              v                              v
                    +-----------------+           +-----------------+
                    |  OFFLINE MODE   |           |  DEFAULT MODE   |
                    |  (local only)   |           | (API if avail)  |
                    +--------+--------+           +--------+--------+
                             |                             |
                             |                   +---------+---------+
                             |                   | GEMINI_API_KEY?   |
                             |                   +---------+---------+
                             |                      Yes    |    No
                             |                        |    |
                             |                        v    |
                             |                +----------+ |
                             |                |API Ready | |
                             |                +----+-----+ |
                             |                     |       |
                             +---------------------+-------+
                                              |
                                              v
                                    +-----------------+
                                    | Route by Format |
                                    +--------+--------+
                                             |
                     +-----------+-----------+------------+------------+
                     |           |           |            |            |
                     v           v           v            v            v
              +----------+ +----------+ +----------+ +----------+ +----------+
              | PDF->MD  | | PDF->DOCX| | DOCX->MD | | MD->DOCX | | MD->PDF  |
              +----+-----+ +----+-----+ +----+-----+ +----+-----+ +----+-----+
                   |            |            |            |            |
                   v            v            v            v            v
            +-----------+ +---------+ +----------+ +---------+ +-----------+
            | API Ready?| | pdf2docx| |MarkItDown| | Pandoc  | |Pandoc+Typst|
            +-----+-----+ | (always)| | (always) | |(always) | |  (always)  |
               Yes| No    +---------+ +----------+ +---------+ +-----------+
                  |  |
                  v  v
           +---------------+
           | Gemini API    |--[fails]--+
           | (PDF -> MD)   |           |
           +---------------+           |
                                       v
                              +----------------+
                              | Local Fallback |
                              | 1. PyMuPDF4LLM |
                              | 2. MarkItDown  |
                              +----------------+
```

### Parallel Conversion Architecture

For batch conversions with 4+ files:

```
                    /convert-docs <input> <output> --parallel
                            |
                            v
                   +------------------+
                   |  File Discovery  |
                   |  Group by Type   |
                   +--------+---------+
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
        +----------+  +----------+  +----------+
        |  Wave 1  |  |  Wave 2  |  |  Wave 3  |
        | PDF->MD  |  | DOCX->MD |  | MD->PDF  |
        | (4 files)|  | (2 files)|  | (1 file) |
        +----------+  +----------+  +----------+
              |             |             |
              +-------------+-------------+
                            v
                   +------------------+
                   | Collect Results  |
                   | Generate Summary |
                   +------------------+
```

**Wave Execution**:
- Each wave contains files of same conversion type
- All files in wave convert in parallel (Task subagents with Haiku model)
- Wave N+1 starts after Wave N completes
- Target: 30-40% time savings for typical batches

**Flow Summary**:
1. Parse `--no-api` flag and detect available tools
2. Route based on source/target format
3. **PDF -> Markdown only**: Try Gemini API if available, fallback to PyMuPDF4LLM -> MarkItDown
4. **All other conversions**: Use local tools directly (no API benefit)
5. **Parallel mode**: Group files by conversion type, dispatch in waves

## Success Criteria

### Core Functionality
- [ ] Single `--no-api` flag disables all API calls
- [ ] All 6 conversion directions work in both modes
- [ ] Gemini API used by default for PDF -> Markdown (when available)
- [ ] Automatic fallback when API unavailable or fails
- [ ] No GPU, PyTorch, or complex installation required
- [ ] All existing tests pass (backward compatibility)
- [ ] Documentation updated with new flag

### Orchestrator Standards Compliance (NEW)
- [ ] Error logging integrated (/errors --command /convert-docs shows failures)
- [ ] Console summary uses standard format (print_artifact_summary)
- [ ] Three-tier library sourcing pattern implemented
- [ ] YAML frontmatter with library-requirements added

### Skill Integration (NEW)
- [ ] Skill delegation works when skill present
- [ ] Skill availability check with fallback behavior
- [ ] SKILL.md updated with Gemini mode and dependencies

### Parallel Execution (NEW)
- [ ] Parallel conversion achieves 30%+ time savings for 4+ files
- [ ] Failure isolation (failed file doesn't block others)
- [ ] Progress collection and aggregation works correctly

## Installation Requirements

### Minimal (Offline Mode Only)
```bash
# Python packages (required for PDF/DOCX conversion)
pip install markitdown pymupdf4llm pdf2docx

# System packages
apt install pandoc  # or: brew install pandoc (macOS)
```

### Full (Default Mode with Gemini API)
```bash
# Python packages (minimal + google-genai)
pip install markitdown pymupdf4llm pdf2docx google-genai

# System packages
apt install pandoc           # Required for most conversions
apt install typst            # Optional: better PDF output than xelatex

# Gemini API key (free tier available)
export GEMINI_API_KEY="your-free-api-key"
```

**Getting Gemini API Key** (Free - No Credit Card Required):
1. Visit https://aistudio.google.com/
2. Sign in with Google account
3. Create API key from the dashboard
4. Free tier limits: 60 requests/min, 1000 requests/day
5. Cost per document: ~$0.003 with gemini-2.5-flash-lite

**NOT Required** (Explicitly Avoided):
- PyTorch or any deep learning frameworks
- Marker or other local LLM tools
- GPU drivers or CUDA
- Local LLM models
- Complex MCP server integrations

## Implementation Phases

### Phase 0: Infrastructure Alignment [NOT STARTED]
dependencies: []

**Objective**: Align /convert-docs with orchestrator command standards for consistency with /build, /plan, /debug

**Complexity**: Low

**Pattern References**:
- [Orchestrator Command Standards Report](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/002_orchestrator_command_standards.md)
- [Skills Integration Patterns Report](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/003_skills_integration_patterns.md)

Tasks:
- [ ] Add YAML frontmatter to `/home/benjamin/.config/.claude/commands/convert-docs.md`:
  ```yaml
  ---
  allowed-tools: Task, Bash, Read, Write
  argument-hint: <input-dir> <output-dir> [--no-api] [--parallel]
  description: Convert documents between Markdown, DOCX, and PDF formats
  command-type: primary
  dependent-agents:
    - document-converter (skill)
  library-requirements:
    - error-handling.sh: ">=1.0.0"
  documentation: See .claude/docs/guides/commands/convert-docs-command-guide.md
  ---
  ```
- [ ] Add three-tier library sourcing pattern to `convert-core.sh`:
  ```bash
  # Tier 1: Critical Foundation (fail-fast required)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to source error-handling.sh" >&2
    exit 1
  }

  # Tier 2: Conversion Support (critical for conversion)
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" 2>/dev/null || {
    echo "ERROR: Failed to source convert-core.sh" >&2
    exit 1
  }
  ```
- [ ] Integrate error logging in convert-core.sh:
  ```bash
  ensure_error_log_exists
  COMMAND_NAME="/convert-docs"
  USER_ARGS="$INPUT_DIR $OUTPUT_DIR"
  WORKFLOW_ID="convert_$(date +%s)"
  export COMMAND_NAME USER_ARGS WORKFLOW_ID
  setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
  ```
- [ ] Add console summary formatting using `print_artifact_summary()`:
  ```bash
  source "${CLAUDE_LIB}/core/summary-formatting.sh" 2>/dev/null || exit 1

  SUMMARY_TEXT="Converted $SUCCESS_COUNT of $TOTAL_COUNT documents in ${CONVERSION_MODE} mode."
  ARTIFACTS="  - Output: $OUTPUT_DIR ($SUCCESS_COUNT files)"
  NEXT_STEPS="  - Review: ls -lh $OUTPUT_DIR\n  - Check log: cat $OUTPUT_DIR/conversion.log"

  print_artifact_summary "Convert" "$SUMMARY_TEXT" "" "$ARTIFACTS" "$NEXT_STEPS"
  ```
- [ ] Add skill availability check with delegation logic:
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

Testing:
```bash
# Test error logging integration
/convert-docs test/ output/ --no-api
/errors --command /convert-docs --limit 5
# Should show any logged errors

# Test console summary format
/convert-docs test/ output/
# Should show 4-section summary format (Summary/Artifacts/Next Steps)

# Test library sourcing
bash -x .claude/lib/convert/convert-core.sh 2>&1 | head -20
# Should show sourcing of error-handling.sh
```

**Expected Duration**: 2-3 hours

---

### Phase 1: Flag and Mode Detection [NOT STARTED]
dependencies: [0]

**Objective**: Add --no-api flag and automatic mode detection with environment variable support

**Complexity**: Low

Tasks:
- [ ] Add `--no-api` (primary) and `--offline` (alias) flag parsing to `convert-core.sh`
  - Location: /home/benjamin/.config/.claude/lib/convert/convert-core.sh (lines ~1229-1267)
  - Follow existing `--dry-run` and `--parallel` patterns
- [ ] Implement `detect_conversion_mode()` function in convert-core.sh:
  ```bash
  detect_conversion_mode() {
    # Priority 1: Explicit --no-api flag
    if [[ "$OFFLINE_FLAG" == "true" ]]; then
      echo "offline"
      return 0
    fi

    # Priority 2: Environment variable
    if [[ "${CONVERT_DOCS_OFFLINE:-false}" == "true" ]]; then
      echo "offline"
      return 0
    fi

    # Priority 3: Check for Gemini API availability
    if [[ -n "${GEMINI_API_KEY:-}" ]] && test_gemini_api; then
      echo "gemini"
      return 0
    fi

    # Default: offline mode
    echo "offline"
  }
  ```
- [ ] Implement `test_gemini_api()` connectivity check with result caching:
  ```bash
  test_gemini_api() {
    # Return cached result if available
    if [[ -n "${_GEMINI_API_TESTED:-}" ]]; then
      return "$_GEMINI_API_TESTED"
    fi

    # Test API connectivity
    if python3 -c "from google import genai; genai.Client()" 2>/dev/null; then
      _GEMINI_API_TESTED=0
      return 0
    else
      _GEMINI_API_TESTED=1
      return 1
    fi
  }
  ```
- [ ] Add `CONVERT_DOCS_OFFLINE=true` environment variable support
- [ ] Update help text in convert-core.sh with new options:
  - `--no-api, --offline`: Disable API-based conversion
  - `CONVERT_DOCS_OFFLINE`: Environment variable equivalent
  - `GEMINI_API_KEY`: Required for default (API) mode
- [ ] Add mode indicator to conversion output header (e.g., "Conversion Mode: gemini")

Testing:
```bash
# Test flag parsing
/convert-docs input/ output/ --no-api
# Should show: "Conversion Mode: offline"

# Test alias
/convert-docs input/ output/ --offline
# Should show: "Conversion Mode: offline"

# Test environment variable
CONVERT_DOCS_OFFLINE=true /convert-docs input/ output/
# Should show: "Conversion Mode: offline"

# Test auto-detection without API key
unset GEMINI_API_KEY
/convert-docs input/ output/
# Should show: "Conversion Mode: offline"

# Test with API key
export GEMINI_API_KEY="your-key"
/convert-docs input/ output/
# Should show: "Conversion Mode: gemini" (or offline if key invalid)
```

**Expected Duration**: 2-3 hours

---

### Phase 2: Gemini API Integration [NOT STARTED]
dependencies: [1]

**Objective**: Integrate Gemini API for PDF-to-Markdown conversions with automatic fallback to local tools

**Complexity**: Medium

Tasks:
- [ ] Create `convert_gemini.py` Python helper in `/home/benjamin/.config/.claude/lib/convert/`:
  ```python
  #!/usr/bin/env python3
  """Gemini API PDF to Markdown converter for /convert-docs.

  Uses google-genai SDK with gemini-2.5-flash-lite model.
  Free tier: 60 req/min, 1000 req/day.
  """

  import sys
  import os

  def convert_pdf_to_markdown(pdf_path: str) -> str:
      """Convert PDF to markdown using Gemini API."""
      try:
          from google import genai
      except ImportError:
          print("Error: google-genai not installed. Run: pip install google-genai", file=sys.stderr)
          sys.exit(1)

      # Initialize client (uses GEMINI_API_KEY env var automatically)
      try:
          client = genai.Client()
      except Exception as e:
          print(f"Error: Failed to initialize Gemini client: {e}", file=sys.stderr)
          sys.exit(1)

      # Upload and convert
      try:
          file = client.files.upload(file=pdf_path)
          response = client.models.generate_content(
              model="gemini-2.5-flash-lite",
              contents=[
                  file,
                  "Convert this PDF to well-formatted markdown. Preserve: "
                  "heading hierarchy (# ## ###), "
                  "code blocks with language hints (```python, ```bash), "
                  "tables as markdown tables using | separators, "
                  "ordered and unordered lists, "
                  "bold, italic, and inline code formatting."
              ]
          )
          return response.text
      except Exception as e:
          print(f"Error: Gemini conversion failed: {e}", file=sys.stderr)
          sys.exit(1)

  if __name__ == "__main__":
      if len(sys.argv) != 2:
          print("Usage: convert_gemini.py <pdf_path>", file=sys.stderr)
          sys.exit(1)

      if not os.path.exists(sys.argv[1]):
          print(f"Error: File not found: {sys.argv[1]}", file=sys.stderr)
          sys.exit(1)

      print(convert_pdf_to_markdown(sys.argv[1]))
  ```
- [ ] Create `convert-gemini.sh` shell wrapper in `/home/benjamin/.config/.claude/lib/convert/`:
  ```bash
  #!/usr/bin/env bash
  # convert-gemini.sh - Gemini API PDF conversion wrapper

  convert_pdf_gemini() {
    local pdf_path="$1"
    local output_path="$2"

    # Check API key
    if [[ -z "${GEMINI_API_KEY:-}" ]]; then
      return 1
    fi

    # Call Python helper with timeout (120s for large PDFs)
    timeout 120 python3 "$CLAUDE_LIB/convert/convert_gemini.py" "$pdf_path" > "$output_path" 2>/dev/null
    return $?
  }
  ```
- [ ] Add rate limit handling with exponential backoff:
  ```python
  import time

  def convert_with_retry(pdf_path, max_retries=3):
      for attempt in range(max_retries):
          try:
              return convert_pdf_to_markdown(pdf_path)
          except Exception as e:
              if '429' in str(e):  # Rate limited
                  wait = 2 ** attempt  # 1, 2, 4 seconds
                  time.sleep(wait)
              else:
                  raise
      return None  # Signal fallback to offline conversion
  ```
- [ ] Update `convert_pdf()` in convert-pdf.sh to use Gemini when mode is "gemini":
  ```bash
  convert_pdf() {
    local pdf_path="$1"
    local output_path="$2"
    local mode
    mode=$(detect_conversion_mode)

    if [[ "$mode" == "gemini" ]]; then
      if convert_pdf_gemini "$pdf_path" "$output_path"; then
        return 0
      fi
      # Fallback to local tools on failure
      echo "Note: Gemini API failed, using offline mode"
    fi

    # Offline conversion (PyMuPDF4LLM preferred for better structure preservation)
    convert_pdf_pymupdf "$pdf_path" "$output_path" || \
      convert_pdf_markitdown "$pdf_path" "$output_path"
  }
  ```
- [ ] Source convert-gemini.sh in convert-core.sh when gemini mode detected

Testing:
```bash
# Test Python helper directly
export GEMINI_API_KEY="your-key"
python3 .claude/lib/convert/convert_gemini.py /tmp/test.pdf > /tmp/output.md
cat /tmp/output.md

# Test shell wrapper
source .claude/lib/convert/convert-gemini.sh
convert_pdf_gemini /tmp/test.pdf /tmp/output.md && cat /tmp/output.md

# Test fallback on API failure
GEMINI_API_KEY="invalid-key" /convert-docs test.pdf output/
# Should fall back to PyMuPDF4LLM, then MarkItDown

# Test rate limit handling (mock 429)
# Integration test with actual rate limiting
```

**Expected Duration**: 3-4 hours

---

### Phase 3: Missing Conversion Directions [NOT STARTED]
dependencies: [1]

**Objective**: Complete the conversion matrix by adding PDF-to-DOCX and DOCX-to-PDF paths

**Complexity**: Low-Medium

Tasks:
- [ ] Add pdf2docx tool detection in convert-core.sh:
  ```bash
  # In detect_tools()
  if python3 -c "import pdf2docx" 2>/dev/null; then
    PDF2DOCX_AVAILABLE=true
  fi
  ```
- [ ] Add pdf2docx integration to `convert-pdf.sh`:
  ```bash
  convert_pdf_to_docx() {
    local pdf_path="$1"
    local output_path="$2"

    # Check for pdf2docx
    if [[ "${PDF2DOCX_AVAILABLE:-false}" != "true" ]]; then
      log_conversion_error "pdf2docx not installed. Run: pip install pdf2docx"
      return 1
    fi

    python3 -c "
  from pdf2docx import Converter
  cv = Converter('$pdf_path')
  cv.convert('$output_path')
  cv.close()
  " 2>/dev/null
  }
  ```
- [ ] Implement DOCX-to-PDF routing through markdown pipeline:
  ```bash
  convert_docx_to_pdf() {
    local docx_path="$1"
    local output_path="$2"
    local temp_md="/tmp/convert_$$_temp.md"

    # Step 1: DOCX -> Markdown (using existing function)
    convert_docx_to_md "$docx_path" "$temp_md" || return 1

    # Step 2: Markdown -> PDF (using existing function)
    convert_md_to_pdf "$temp_md" "$output_path" || return 1

    rm -f "$temp_md"
  }
  ```
- [ ] Update `convert_file()` dispatch logic in convert-core.sh for new directions:
  - PDF + --to docx -> convert_pdf_to_docx()
  - DOCX + --to pdf -> convert_docx_to_pdf()
- [ ] Add conversion direction summary to help output and --detect-tools

Testing:
```bash
# Test PDF -> DOCX (uses pdf2docx in both modes - direct conversion is better than Gemini->Pandoc)
/convert-docs test.pdf output/ --to docx

# Test DOCX -> PDF (two-step via markdown)
/convert-docs test.docx output/ --to pdf

# Test full matrix offline
/convert-docs mixed_docs/ output/ --no-api
# Should convert all file types using local tools only

# Test tool detection includes pdf2docx
/convert-docs --detect-tools
# Should show: pdf2docx: available (or not available)
```

**Expected Duration**: 2-3 hours

---

### Phase 4: Claude Code Skills Integration [NOT STARTED]
dependencies: [1, 2]

**Objective**: Update document-converter skill to support Gemini API mode following skills-authoring standards

**Complexity**: Low-Medium

**Standards References**:
- [Skills Authoring Standards](/.claude/docs/reference/standards/skills-authoring.md) - Compliance requirements
- [Skills README](/.claude/skills/README.md) - Skills architecture and patterns
- [Document Converter Skill Guide](/.claude/docs/guides/skills/document-converter-skill-guide.md) - Example implementation

#### 4.1 SKILL.md Content Updates

Tasks:
- [ ] Update YAML frontmatter in `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md`:
  ```yaml
  ---
  name: document-converter
  description: Convert between Markdown, DOCX, and PDF formats bidirectionally. Handles text extraction from PDF/DOCX, markdown to document conversion. Use --no-api for offline mode.
  allowed-tools: Bash, Read, Glob, Write
  dependencies:
    - pandoc>=2.0
    - python3>=3.8
    - markitdown (optional, recommended)
    - pymupdf4llm (optional, recommended)
    - pdf2docx (optional, for PDF->DOCX)
    - google-genai (optional, for enhanced PDF conversion)
  model: haiku-4.5
  model-justification: Orchestrates external conversion tools with minimal AI reasoning required
  fallback-model: sonnet-4.5
  ---
  ```
- [ ] Update Tool Priority Matrix in SKILL.md (around lines 43-69):
  ```markdown
  ### PDF -> Markdown
  1. **Gemini API** (primary, if GEMINI_API_KEY set) - 90%+ fidelity
     - Excellent table and layout handling
     - Native OCR for scanned documents
     - Requires internet connection
  2. **PyMuPDF4LLM** (primary fallback) - 70-85% fidelity
     - Better structure preservation (headings, tables, URLs)
     - Zero configuration required
  3. **MarkItDown** (secondary fallback) - 65-75% fidelity
     - Plain text extraction, simpler but less accurate
  ```
- [ ] Add "Conversion Modes" section to SKILL.md:
  ```markdown
  ## Conversion Modes

  ### Default Mode (API)
  When GEMINI_API_KEY is set, PDF conversions use Gemini API for
  significantly improved quality. Other conversions use local tools.

  ### Offline Mode
  Use --no-api flag or set CONVERT_DOCS_OFFLINE=true to disable
  all API calls. All conversions use local tools only.
  ```

#### 4.2 Skills Standards Compliance Validation

Tasks:
- [ ] Verify SKILL.md size constraint (< 500 lines per skills-authoring.md):
  ```bash
  LINES=$(wc -l < .claude/skills/document-converter/SKILL.md)
  if [ "$LINES" -ge 500 ]; then
    echo "ERROR: SKILL.md exceeds 500 lines ($LINES)"
    exit 1
  fi
  echo "Size OK: $LINES lines"
  ```
- [ ] Validate YAML frontmatter syntax:
  ```bash
  python3 -c "import yaml; yaml.safe_load(open('.claude/skills/document-converter/SKILL.md').read().split('---')[1])"
  ```
- [ ] Verify name field matches directory name:
  ```bash
  NAME=$(grep "^name:" .claude/skills/document-converter/SKILL.md | awk '{print $2}')
  DIR_NAME="document-converter"
  [ "$NAME" = "$DIR_NAME" ] && echo "Name OK" || echo "ERROR: name mismatch"
  ```
- [ ] Verify description length (<= 200 characters):
  ```bash
  DESC=$(grep "^description:" .claude/skills/document-converter/SKILL.md | cut -d: -f2-)
  LEN=${#DESC}
  [ "$LEN" -le 200 ] && echo "Description OK: $LEN chars" || echo "ERROR: >200 chars"
  ```
- [ ] Verify description includes trigger keywords (convert, PDF, DOCX, Markdown, document, extraction)

#### 4.3 Command Delegation Pattern (STEP 0 / STEP 3.5)

Tasks:
- [ ] Add STEP 0 skill availability check to `/convert-docs` command:
  ```bash
  # STEP 0: Check for skill availability
  SKILL_AVAILABLE=false
  if [ -d ".claude/skills/document-converter" ] && [ -f ".claude/skills/document-converter/SKILL.md" ]; then
    SKILL_AVAILABLE=true
    echo "[INFO] Skill document-converter available"
  fi
  ```
- [ ] Add STEP 3.5 skill delegation to `/convert-docs` command:
  ```markdown
  **STEP 3.5**: Delegate to skill if available (between mode detection and script mode)

  If $SKILL_AVAILABLE is true, delegate conversion to skill via natural language:
  "Use the document-converter skill to convert files from $INPUT_DIR to $OUTPUT_DIR"

  Otherwise, fall back to script mode.
  ```

#### 4.4 Documentation Updates

Tasks:
- [ ] Update `/home/benjamin/.config/.claude/skills/document-converter/reference.md`:
  - Add Gemini API configuration section
  - Update quality comparison matrix with Gemini results
  - Add troubleshooting for API failures
- [ ] Update `/home/benjamin/.config/.claude/docs/guides/commands/convert-docs-command-guide.md`:
  - Add --no-api flag documentation
  - Add GEMINI_API_KEY setup instructions
  - Add conversion mode examples
  - Document skill delegation pattern (STEP 0, STEP 3.5)
- [ ] Update `/home/benjamin/.config/.claude/docs/guides/skills/document-converter-skill-guide.md`:
  - Add Gemini API integration section
  - Document offline mode usage
  - Update architecture diagram with API path

#### 4.5 Compliance Checklist Verification

Before completing Phase 4, verify all items:

**Structure**:
- [ ] Skill directory exists at `.claude/skills/document-converter/`
- [ ] SKILL.md file exists with valid YAML frontmatter
- [ ] SKILL.md is under 500 lines
- [ ] reference.md and examples.md exist for detailed docs

**Frontmatter**:
- [ ] `name` field matches directory name (document-converter)
- [ ] `description` field is <= 200 characters
- [ ] `description` includes trigger keywords (convert, PDF, DOCX, Markdown)
- [ ] `allowed-tools` field lists permitted tools
- [ ] `model` has corresponding `fallback-model`

**Integration**:
- [ ] `/convert-docs` command includes STEP 0 availability check
- [ ] `/convert-docs` command includes STEP 3.5 delegation
- [ ] Skill listed in skills/README.md
- [ ] No emojis in documentation
- [ ] CommonMark compliance

Testing:
```bash
# Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('.claude/skills/document-converter/SKILL.md').read().split('---')[1])"

# Check line count (must be < 500)
wc -l .claude/skills/document-converter/SKILL.md

# Verify skill loads correctly
# In Claude Code chat:
# "Convert this PDF to markdown" -> should use skill autonomously

# Verify skill documentation is accurate
cat .claude/skills/document-converter/SKILL.md | grep -A5 "Gemini"
# Should show Gemini as primary for PDF->Markdown

# Verify dependencies section updated
grep -A10 "dependencies:" .claude/skills/document-converter/SKILL.md
# Should include google-genai

# Test discoverability with these prompts:
# 1. "Convert this PDF to markdown" (should trigger)
# 2. "Extract text from document" (should trigger)
# 3. "Analyze code quality" (should NOT trigger)
```

**Expected Duration**: 2-3 hours

---

### Phase 5: Parallel Conversion Support [NOT STARTED]
dependencies: [0, 2]

**Objective**: Enable wave-based parallel file conversion using Haiku subagents for batch processing

**Complexity**: Medium

**Pattern References**:
- [Haiku Parallel Subagents Report](/home/benjamin/.config/.claude/specs/20251121_convert_docs_plan_improvements_research/reports/001_haiku_parallel_subagents.md)

Tasks:
- [ ] Create conversion-coordinator agent at `.claude/agents/conversion-coordinator.md`:
  ```yaml
  ---
  model: haiku-4.5
  model-justification: Orchestrates conversion tasks with deterministic dispatch, mechanical subagent coordination
  fallback-model: sonnet-4.5
  ---
  ```
- [ ] Implement batch file grouping by conversion direction:
  ```bash
  group_files_by_conversion() {
    local input_dir="$1"
    local -n pdf_to_md=$2
    local -n docx_to_md=$3
    local -n md_to_pdf=$4

    while IFS= read -r -d '' file; do
      case "${file##*.}" in
        pdf) pdf_to_md+=("$file") ;;
        docx) docx_to_md+=("$file") ;;
        md) md_to_pdf+=("$file") ;;
      esac
    done < <(find "$input_dir" -type f \( -name "*.pdf" -o -name "*.docx" -o -name "*.md" \) -print0)
  }
  ```
- [ ] Add parallel Task invocation pattern for concurrent conversions:
  ```markdown
  **EXECUTE NOW**: USE the Task tool to invoke document-converter for each file in parallel:

  Task {
    subagent_type: "general-purpose"
    model: "haiku"
    description: "Convert file1.pdf to Markdown"
    prompt: |
      Read and follow behavioral guidelines from:
      ${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md

      Convert: /path/to/file1.pdf
      Output: /path/to/output/file1.md
      Mode: ${CONVERSION_MODE}

      Return: CONVERSION_COMPLETE: /path/to/output/file1.md
  }

  Task {
    subagent_type: "general-purpose"
    model: "haiku"
    description: "Convert file2.pdf to Markdown"
    ...
  }
  ```
- [ ] Implement progress collection and aggregation:
  ```bash
  # Verify all conversions completed
  collect_conversion_results() {
    local -n results=$1
    local success=0
    local failed=0

    for result in "${results[@]}"; do
      if [[ "$result" == *"CONVERSION_COMPLETE"* ]]; then
        ((success++))
      else
        ((failed++))
      fi
    done

    echo "Completed: $success, Failed: $failed"
  }
  ```
- [ ] Add failure isolation (failed conversion doesn't block others):
  ```bash
  # In wave execution loop
  for file in "${wave_files[@]}"; do
    if ! convert_file "$file" "$output_dir"; then
      failed_files+=("$file")
      log_conversion_error "$file" "Conversion failed, continuing with other files"
      # Continue with other files - don't exit
    fi
  done
  ```
- [ ] Add `--parallel` flag to convert-core.sh:
  ```bash
  if [[ "$PARALLEL_FLAG" == "true" ]] && [ "${#input_files[@]}" -ge 4 ]; then
    echo "[INFO] Parallel mode enabled for ${#input_files[@]} files"
    convert_parallel "${input_files[@]}"
  else
    convert_sequential "${input_files[@]}"
  fi
  ```

Testing:
```bash
# Test parallel conversion (4 files)
/convert-docs test/parallel/ output/ --parallel
# Should complete in <2x single file time

# Test failure isolation
# Place 1 corrupt file in test/isolation/
/convert-docs test/isolation/ output/ --parallel
# Should complete other files successfully

# Test wave grouping
/convert-docs mixed/ output/ --parallel --dry-run
# Should show wave grouping by conversion type

# Test sequential fallback (< 4 files)
/convert-docs test/small/ output/ --parallel
# Should fall back to sequential for small batches
```

**Expected Duration**: 3-4 hours

---

## Testing Strategy

### Unit Tests
- Flag parsing tests (`--no-api`, `--offline`, `--parallel`, environment variables)
- Mode detection tests (`detect_conversion_mode()`, `test_gemini_api()`)
- Tool availability checks (pdf2docx, google-genai)
- Individual conversion function tests (Gemini helper, fallback chain)

### Integration Tests
- Full conversion matrix (all 6 directions) in both modes
- API fallback scenarios (invalid key, rate limit, network failure)
- Concurrent conversions with parallel mode
- Skill autonomous invocation

### Infrastructure Tests (NEW)
- [ ] Error logging writes to errors.jsonl correctly:
  ```bash
  /convert-docs nonexistent/ output/ 2>/dev/null || true
  /errors --command /convert-docs --limit 1
  # Should show the logged error
  ```
- [ ] Console summary follows 4-section format:
  ```bash
  /convert-docs test/ output/ | tail -20
  # Should show Summary/Artifacts/Next Steps sections
  ```
- [ ] Skill delegation activates when skill present:
  ```bash
  # Test skill trigger in Claude Code chat
  # "Convert this PDF to markdown"
  # Should show skill invocation in output
  ```
- [ ] Three-tier library sourcing works correctly:
  ```bash
  bash -x .claude/lib/convert/convert-core.sh 2>&1 | grep "source"
  # Should show error-handling.sh sourced first
  ```

### Parallel Conversion Tests (NEW)
- [ ] Wave grouping by conversion type:
  ```bash
  # Create test files
  mkdir -p test/parallel
  touch test/parallel/{a,b,c,d}.pdf test/parallel/{e,f}.docx
  /convert-docs test/parallel/ output/ --parallel --dry-run
  # Should show: Wave 1: PDF->MD (4 files), Wave 2: DOCX->MD (2 files)
  ```
- [ ] Failure isolation (failed file doesn't propagate):
  ```bash
  mkdir -p test/isolation
  cp valid.pdf test/isolation/
  echo "corrupt" > test/isolation/corrupt.pdf
  /convert-docs test/isolation/ output/ --parallel
  # Should complete valid.pdf successfully despite corrupt.pdf failure
  ```
- [ ] Time savings measurement:
  ```bash
  time /convert-docs test/4files/ output/
  time /convert-docs test/4files/ output/ --parallel
  # Parallel should be at least 30% faster
  ```

### Test Commands
```bash
# Run all conversion tests
bash .claude/tests/convert/run-all-tests.sh

# Test specific conversion direction
bash .claude/tests/convert/test-conversion.sh pdf markdown

# Test offline mode
CONVERT_DOCS_OFFLINE=true bash .claude/tests/convert/test-conversion.sh pdf markdown

# Test Gemini mode (requires API key)
export GEMINI_API_KEY="your-key"
bash .claude/tests/convert/test-conversion.sh pdf markdown
# Should show "Conversion Mode: gemini"

# Test mode switching
/convert-docs test.pdf output/          # Uses Gemini if key set
/convert-docs test.pdf output/ --no-api # Forces offline mode

# Test parallel mode
/convert-docs test/batch/ output/ --parallel
```

## Documentation Updates

Files to update (handled in Phases 0 and 4):
- [ ] `/home/benjamin/.config/.claude/commands/convert-docs.md` - Add YAML frontmatter, --no-api/--offline/--parallel flags
- [ ] `/home/benjamin/.config/.claude/skills/document-converter/SKILL.md` - Update dependencies, modes, tool matrix
- [ ] `/home/benjamin/.config/.claude/skills/document-converter/reference.md` - Add Gemini section
- [ ] `/home/benjamin/.config/.claude/docs/guides/commands/convert-docs-command-guide.md` - Add mode examples, API setup, parallel mode

## Dependencies

### Python Packages (pip install)
| Package | Purpose | Required |
|---------|---------|----------|
| `pymupdf4llm` | PDF-to-markdown (primary offline) | Yes (best structure preservation) |
| `markitdown` | Document-to-markdown (secondary fallback) | Yes (DOCX, fallback for PDF) |
| `pdf2docx` | PDF-to-DOCX conversion | Yes (PDF->DOCX) |
| `google-genai` | Gemini API client | Optional (default mode) |

### System Packages
| Package | Purpose | Required |
|---------|---------|----------|
| `pandoc` | Document format conversion | Yes (all conversions) |
| `typst` | Modern typesetting engine | Optional (better PDF output) |

### Environment Variables
| Variable | Purpose | Default |
|----------|---------|---------|
| `GEMINI_API_KEY` | Gemini API key for PDF conversion | None (offline mode) |
| `CONVERT_DOCS_OFFLINE` | Force offline mode | false |

**Explicitly NOT Required**:
- PyTorch or any deep learning frameworks
- Marker or other local LLM tools
- GPU drivers or CUDA
- Local LLM models (Llama, Mistral, etc.)
- Complex MCP server integrations

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gemini API rate limiting | Medium | Low | Automatic fallback to offline |
| pdf2docx quality varies | Low | Medium | Document known limitations |
| Network unavailable | Low | None | Offline mode always works |
| Parallel execution context limits | Low | Medium | Batch size limit of 4-8 files per wave |

## Removed from Original Plan

The following components were **intentionally removed** to maintain simplicity:

1. **Local LLMs (Marker, etc.)** - Require PyTorch, GPU, complex installation
2. **LLM Post-Processing Layer** - Gemini API handles formatting natively
3. **Fidelity Scoring System** - Adds complexity without clear user benefit
4. **Prompt Template System** - Single prompt is sufficient for quality output
5. **Code Block Detection Heuristics** - Gemini handles code detection well
6. **Multiple MCP Server Integrations** - Direct API is simpler and more reliable
7. **Complex Configuration Options** - Single --no-api flag is sufficient

**Design Principle**: Keep it simple. One flag changes everything. No complex configuration.

These can be added later as separate enhancements if user demand warrants.

## Summary

| Aspect | Before (Original) | After (Current Revision) |
|--------|-------------------|--------------------------|
| Phases | 4 | 6 (0-5) |
| Hours | 8-12 | 12-16 |
| Flags | One (--no-api) | Three (--no-api, --offline, --parallel) |
| Complexity | Low | Moderate (orchestrator standards) |
| Conversion directions | 6 | 6 (complete matrix) |
| Offline support | Complete | Complete |
| Error logging | None | Integrated with /errors |
| Console summary | None | Standard 4-section format |
| Parallel execution | None | Wave-based with Haiku |
| Skill integration | Partial | Complete with delegation |
| Standards compliance | None | Full orchestrator standards |

## Research Summary

Key findings incorporated from research reports:

1. **Gemini API PDF Conversion** (Report 001): Use `google-genai` SDK with `gemini-2.5-flash-lite` model. Free tier: 60 req/min, 1000 req/day. Cost: ~$0.003 per document.

2. **Claude Code Skills Integration** (Report 002): document-converter skill already exists and provides autonomous invocation. Update SKILL.md to document Gemini mode and new dependencies.

3. **API Flag Implementation** (Report 003): Use `--no-api` (primary) and `--offline` (alias) flags. Support `CONVERT_DOCS_OFFLINE=true` environment variable. Cache API connectivity test for performance.

4. **Conversion Task Analysis** (Report 004): Gemini API only benefits PDF-to-Markdown conversion (HIGH: +20-30% fidelity). Other directions work equally well with local tools because they are format transformations, not content interpretation.

5. **Haiku Parallel Subagents** (Report 005): Wave-based execution using multiple Task calls with Haiku model for mechanical coordination. Target 30-40% time savings for batch conversions. Maximum wave size of 4-8 files for context management.

6. **Orchestrator Command Standards** (Report 006): Follow 5-section structure, three-tier library sourcing, error logging integration, console summary formatting. Ensures consistency with /build, /plan, /debug commands.

7. **Skills Integration Patterns** (Report 007): Add skill availability check before conversion, implement delegation logic when skill present, document trigger keywords for autonomous invocation.

8. **Plan Improvement Recommendations** (Report 008): Add Phase 0 for infrastructure alignment, expand testing strategy for infrastructure and parallel tests, update success criteria for standards compliance.

---

**Plan Generated**: 2025-11-21
**Plan Revised**: 2025-11-21 (Phase 0, parallel execution, orchestrator standards, expanded testing)
**Plan Architect**: Claude (plan-architect agent)
**Complexity Level**: 55 (Tier 2 - moderate implementation with infrastructure alignment)
**Status**: [NOT STARTED]
