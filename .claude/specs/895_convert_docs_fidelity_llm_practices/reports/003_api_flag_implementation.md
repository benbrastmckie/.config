# API Flag Implementation Pattern Research Report

## Metadata
- **Date**: 2025-11-21
- **Agent**: research-specialist
- **Topic**: --no-api flag design pattern for optional API usage
- **Report Type**: pattern recognition
- **Related Plan**: /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md

## Executive Summary

Research into existing flag patterns in the .claude/ system reveals consistent use of `--dry-run` and `--parallel` flags with boolean parsing. The proposed `--no-api` flag follows a "negative flag" pattern (disabling rather than enabling) which aligns with the principle of making the best behavior the default. The implementation should support both flag and environment variable (`CONVERT_DOCS_OFFLINE=true`) for flexibility. The existing argument parsing pattern in convert-core.sh (lines 1229-1267) provides a clean template for adding the new flag.

## Findings

### 1. Existing Flag Patterns in .claude/ System

**convert-core.sh:1229-1267** - Main argument parsing loop:
```bash
# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --detect-tools)
      detect_tools
      show_tool_detection
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --parallel)
      PARALLEL_MODE=true
      if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
        PARALLEL_WORKERS="$2"
        shift 2
      else
        # Auto-detect optimal worker count
        # ...
        shift
      fi
      ;;
    *)
      # Positional arguments
      ;;
  esac
done
```

**Key Patterns Observed**:
1. Boolean flags set variables to `true`
2. Optional arguments checked with `${2:-}` pattern
3. `shift` used to advance argument pointer
4. Case-insensitive matching not used (lowercase flags only)

### 2. Environment Variable Patterns

**convert-core.sh:69-73** - Timeout multiplier pattern:
```bash
# Timeout multiplier (can be overridden by environment variable)
TIMEOUT_MULTIPLIER="${TIMEOUT_MULTIPLIER:-1.0}"

# Resource management configuration
MAX_DISK_USAGE_GB="${MAX_DISK_USAGE_GB:-}"  # No limit by default
MIN_FREE_SPACE_MB=100  # Minimum free space required (MB)
```

**Key Pattern**: `${VAR:-default}` for optional environment variable with fallback.

### 3. Negative Flag Design Pattern

The `--no-api` flag follows a "negative flag" pattern:
- **Default behavior**: API enabled (when key available)
- **Flag behavior**: API disabled

This is preferred over `--api` because:
1. Best behavior (API) is default - no action needed for optimal path
2. Users opt-out consciously when needed (offline, testing)
3. Follows Unix convention (`--no-verify`, `--no-cache`, etc.)

### 4. Proposed Flag Implementation

**Flag Names** (support multiple):
- `--no-api` (primary, recommended)
- `--offline` (alias, intuitive)

**Environment Variable**:
- `CONVERT_DOCS_OFFLINE=true` (for CI/CD and scripting)

**Implementation Pattern**:
```bash
# Initialize flags at top of main_conversion()
OFFLINE_FLAG=false

# Parse in argument loop
--no-api|--offline)
  OFFLINE_FLAG=true
  shift
  ;;

# Environment variable fallback
OFFLINE_FLAG="${CONVERT_DOCS_OFFLINE:-$OFFLINE_FLAG}"
```

### 5. Mode Detection Function

Based on existing patterns, the mode detection should be:

```bash
#
# detect_conversion_mode - Determine API vs offline conversion mode
#
# Returns: "gemini" or "offline"
#
# Mode selection priority:
#   1. --no-api flag (explicit offline request)
#   2. CONVERT_DOCS_OFFLINE=true environment variable
#   3. GEMINI_API_KEY present + API connectivity
#   4. Fallback to offline
#
detect_conversion_mode() {
  # Check for explicit offline flag
  if [[ "$OFFLINE_FLAG" == "true" ]]; then
    echo "offline"
    return 0
  fi

  # Check environment variable
  if [[ "${CONVERT_DOCS_OFFLINE:-false}" == "true" ]]; then
    echo "offline"
    return 0
  fi

  # Check for Gemini API availability
  if [[ -n "${GEMINI_API_KEY:-}" ]]; then
    if test_gemini_api; then
      echo "gemini"
      return 0
    fi
  fi

  # Default to offline
  echo "offline"
}
```

### 6. API Connectivity Test Pattern

```bash
#
# test_gemini_api - Quick API connectivity test
#
# Returns: 0 if API is reachable, 1 otherwise
#
test_gemini_api() {
  # Check API key exists
  if [[ -z "${GEMINI_API_KEY:-}" ]]; then
    return 1
  fi

  # Quick Python test (cached result for performance)
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

### 7. Help Text Updates

**Proposed Help Section**:
```
OPTIONS:
  --no-api, --offline
      Disable API-based conversion and use only local tools.
      Equivalent to setting CONVERT_DOCS_OFFLINE=true.
      Useful for offline environments or when API quota is exhausted.

  --detect-tools
      Show available conversion tools and exit.

  --dry-run
      Show what would be converted without performing conversions.

  --parallel [N]
      Enable parallel processing with N workers (default: auto-detect).

ENVIRONMENT:
  GEMINI_API_KEY
      Google Gemini API key for enhanced PDF conversion.
      Get free key at: https://aistudio.google.com/

  CONVERT_DOCS_OFFLINE
      Set to 'true' to disable API usage (same as --no-api).
```

### 8. Integration with Tool Selection

The mode should affect PDF tool selection only (DOCX uses local tools regardless):

```bash
select_pdf_tool() {
  local mode
  mode=$(detect_conversion_mode)

  if [[ "$mode" == "gemini" ]]; then
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

### 9. Output Mode Indicator

Following the existing PROGRESS marker pattern (from convert-core.sh:98-104):

```bash
# Show mode at conversion start
echo "Conversion Mode: $(detect_conversion_mode)"
echo ""

# In progress output
echo "[PROGRESS] Converting: $basename (Mode: $mode, Tool: $tool)"
```

### 10. Backward Compatibility

The implementation must be backward compatible:
- No flag = same as before (best available tool)
- `--no-api` = force offline (new behavior, explicit opt-out)
- Environment variable = CI/CD compatible

## Recommendations

### 1. Use Negative Flag Pattern
Implement `--no-api` as the primary flag with `--offline` as an alias. This makes API usage the default (best behavior) and requires explicit opt-out.

### 2. Support Environment Variable
Add `CONVERT_DOCS_OFFLINE=true` for scripting and CI/CD environments where command-line flags are cumbersome.

### 3. Cache API Test Result
Test Gemini API connectivity once per invocation and cache the result to avoid repeated network calls:
```bash
_GEMINI_API_TESTED=""  # Cache variable
```

### 4. Clear Mode Indicator
Display conversion mode at start of processing and in each progress line for transparency.

### 5. Document in Help Text
Add clear documentation in `--help` output and command guide explaining:
- Default behavior (API when available)
- How to disable API
- How to get API key

### 6. Graceful Fallback
If API test fails, automatically fall back to offline mode without user intervention:
```bash
# API unavailable, using offline mode
if ! test_gemini_api; then
  echo "Note: Gemini API unavailable, using offline mode"
fi
```

## References

### Codebase Files (Analyzed)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:1229-1267 (argument parsing)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:69-73 (environment variables)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:108-133 (tool detection pattern)
- /home/benjamin/.config/.claude/lib/convert/convert-core.sh:190-203 (tool selection pattern)
- /home/benjamin/.config/.claude/scripts/validate-all-standards.sh:145-177 (parse_args function)
- /home/benjamin/.config/.claude/lib/util/optimize-claude-md.sh:208 (--dry-run pattern)

### Related Plan
- /home/benjamin/.config/.claude/specs/895_convert_docs_fidelity_llm_practices/plans/001_convert_docs_fidelity_llm_practices_plan.md:116-164 (Phase 1 specification)

### External Conventions
- GNU Long Options: https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html
- Unix --no-* flag convention (git, npm, etc.)

---

**Report Generated**: 2025-11-21
**Research Complexity**: 2 (Medium)
**Status**: Complete
