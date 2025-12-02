#!/usr/bin/env bash
# standards-extraction.sh - Extract CLAUDE.md standards sections for plan creation
#
# PURPOSE:
#   Provides utilities for extracting standards sections from CLAUDE.md files
#   and formatting them for injection into plan-architect agent prompts.
#
# USAGE:
#   source /path/to/standards-extraction.sh
#
#   # Extract single section
#   content=$(extract_claude_section "code_standards")
#
#   # Extract all planning-relevant sections
#   standards=$(extract_planning_standards)
#
#   # Format for agent prompt injection
#   formatted=$(format_standards_for_prompt)
#
# FUNCTIONS:
#   extract_claude_section(section_name) - Extract named section from CLAUDE.md
#   extract_planning_standards() - Extract all planning-relevant sections
#   format_standards_for_prompt() - Format sections for prompt injection
#
# PLANNING-RELEVANT SECTIONS:
#   - code_standards: Informs Technical Design phase requirements
#   - testing_protocols: Shapes Testing Strategy section
#   - documentation_policy: Guides Documentation Requirements
#   - error_logging: Ensures error handling integration in phases
#   - clean_break_development: Influences refactoring approach
#   - directory_organization: Validates file placement in tasks
#   - plan_metadata_standard: Ensures uniform plan metadata structure
#
# DEPENDENCIES:
#   - awk (standard Unix utility)
#   - error-handling.sh (for error logging)
#   - state-persistence.sh (for state tracking)
#
# ERROR HANDLING:
#   - Graceful degradation if CLAUDE.md not found
#   - Returns empty string for missing sections (no fatal errors)
#   - Logs errors to stderr for debugging

# ═══════════════════════════════════════════════════════════════════════════
# THREE-TIER SOURCING PATTERN (MANDATORY)
# ═══════════════════════════════════════════════════════════════════════════

# Tier 1: Core libraries (fail-fast if missing)
source "${CLAUDE_LIB:-/home/benjamin/.config/.claude/lib}/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}

source "${CLAUDE_LIB:-/home/benjamin/.config/.claude/lib}/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}

# ═══════════════════════════════════════════════════════════════════════════
# CORE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

# extract_claude_section - Extract single named section from CLAUDE.md
#
# USAGE:
#   content=$(extract_claude_section "section_name")
#
# ARGUMENTS:
#   $1 - section_name: Name of section to extract (e.g., "code_standards")
#
# RETURNS:
#   Section content (without markers) on stdout
#   Empty string if section not found
#
# BEHAVIOR:
#   - Searches upward from PWD for CLAUDE.md file
#   - Uses awk to extract content between <!-- SECTION: name --> markers
#   - Strips leading/trailing whitespace
#   - Returns empty string (not error) if section missing
extract_claude_section() {
  local section_name="$1"

  if [ -z "$section_name" ]; then
    echo "ERROR: extract_claude_section requires section_name argument" >&2
    return 1
  fi

  # Find CLAUDE.md by searching upward from current directory
  local claude_md=""
  local search_dir="$PWD"

  while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/CLAUDE.md" ]; then
      claude_md="$search_dir/CLAUDE.md"
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  if [ -z "$claude_md" ]; then
    echo "WARNING: CLAUDE.md not found, standards extraction skipped" >&2
    return 0  # Graceful degradation
  fi

  # Extract section content using awk
  # Pattern: <!-- SECTION: name --> ... <!-- END_SECTION: name -->
  awk -v section="$section_name" '
    /<!-- SECTION:/ {
      if ($0 ~ "<!-- SECTION: " section " -->") {
        in_section = 1
        next
      }
    }
    /<!-- END_SECTION:/ {
      if (in_section && $0 ~ "<!-- END_SECTION: " section " -->") {
        in_section = 0
        exit
      }
    }
    in_section {
      print
    }
  ' "$claude_md"
}

# extract_planning_standards - Extract all planning-relevant sections
#
# USAGE:
#   standards=$(extract_planning_standards)
#
# RETURNS:
#   Multi-section content with section names as headers
#
# SECTIONS EXTRACTED:
#   1. code_standards
#   2. testing_protocols
#   3. documentation_policy
#   4. error_logging
#   5. clean_break_development
#   6. directory_organization
#   7. plan_metadata_standard
#
# OUTPUT FORMAT:
#   SECTION: code_standards
#   [content]
#
#   SECTION: testing_protocols
#   [content]
#   ...
extract_planning_standards() {
  local sections=(
    "code_standards"
    "testing_protocols"
    "documentation_policy"
    "error_logging"
    "clean_break_development"
    "directory_organization"
    "plan_metadata_standard"
  )

  local output=""
  local first=true

  for section in "${sections[@]}"; do
    local content
    content=$(extract_claude_section "$section")

    if [ -n "$content" ]; then
      if [ "$first" = true ]; then
        first=false
      else
        output+=$'\n\n'
      fi

      output+="SECTION: $section"
      output+=$'\n'
      output+="$content"
    fi
  done

  echo "$output"
}

# format_standards_for_prompt - Format extracted standards for agent prompt
#
# USAGE:
#   formatted=$(format_standards_for_prompt)
#
# RETURNS:
#   Formatted markdown with headers suitable for prompt injection
#
# OUTPUT FORMAT:
#   ### Code Standards
#   [content]
#
#   ### Testing Protocols
#   [content]
#   ...
#
# BEHAVIOR:
#   - Extracts all planning standards
#   - Converts "SECTION: name" to "### Title Case Name"
#   - Preserves content formatting
#   - Returns empty string if no standards found
format_standards_for_prompt() {
  local raw_standards
  raw_standards=$(extract_planning_standards)

  if [ -z "$raw_standards" ]; then
    return 0  # Graceful degradation
  fi

  # Convert section headers to markdown headers
  echo "$raw_standards" | awk '
    /^SECTION: / {
      # Extract section name
      section = $2

      # Convert to title case
      gsub(/_/, " ", section)
      title = toupper(substr(section, 1, 1)) substr(section, 2)

      # Handle multi-word titles
      while (match(title, / [a-z]/)) {
        pos = RSTART + 1
        title = substr(title, 1, pos-1) toupper(substr(title, pos, 1)) substr(title, pos+1)
      }

      print "### " title
      next
    }
    {
      print
    }
  '
}

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

# validate_standards_extraction - Test standards extraction functionality
#
# USAGE:
#   validate_standards_extraction
#
# RETURNS:
#   0 if validation passes, 1 if failures detected
#
# TESTS:
#   - CLAUDE.md file exists
#   - Can extract code_standards section
#   - Can extract all planning standards
#   - Formatted output has markdown headers
validate_standards_extraction() {
  echo "Validating standards extraction..." >&2

  local failures=0

  # Test 1: CLAUDE.md exists
  local search_dir="$PWD"
  local found=false

  while [ "$search_dir" != "/" ]; do
    if [ -f "$search_dir/CLAUDE.md" ]; then
      found=true
      echo "  ✓ CLAUDE.md found at $search_dir/CLAUDE.md" >&2
      break
    fi
    search_dir=$(dirname "$search_dir")
  done

  if [ "$found" = false ]; then
    echo "  ✗ CLAUDE.md not found (graceful degradation mode)" >&2
    ((failures++))
  fi

  # Test 2: Extract single section
  local code_standards
  code_standards=$(extract_claude_section "code_standards")

  if [ -n "$code_standards" ]; then
    echo "  ✓ code_standards section extracted (${#code_standards} bytes)" >&2
  else
    echo "  ✗ code_standards section empty or missing" >&2
    ((failures++))
  fi

  # Test 3: Extract all planning standards
  local all_standards
  all_standards=$(extract_planning_standards)

  if [ -n "$all_standards" ]; then
    local section_count
    section_count=$(echo "$all_standards" | grep -c "^SECTION:")
    echo "  ✓ All planning standards extracted ($section_count sections)" >&2
  else
    echo "  ✗ Planning standards extraction failed" >&2
    ((failures++))
  fi

  # Test 4: Format for prompt
  local formatted
  formatted=$(format_standards_for_prompt)

  if echo "$formatted" | grep -q "^###"; then
    local header_count
    header_count=$(echo "$formatted" | grep -c "^###")
    echo "  ✓ Standards formatted with markdown headers ($header_count headers)" >&2
  else
    echo "  ✗ Standards formatting failed (no markdown headers)" >&2
    ((failures++))
  fi

  if [ $failures -eq 0 ]; then
    echo "Validation PASSED" >&2
    return 0
  else
    echo "Validation FAILED ($failures failures)" >&2
    return 1
  fi
}
